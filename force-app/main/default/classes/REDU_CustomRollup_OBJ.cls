/**
 * @author      WDCi (Jordan)
 * @date        Jan 2024
 * @group       Custom Rollup Engine
 * @description Custom rollup extension
 * @changehistory
 * ISS-001847 30-01-2024 Jordan - migrated CustomRollupExtension class from DevLib and renamed to REDU_CustomRollup_OBJ
 * ISS-001967 21-06-2024 Sueanne - update sum rollup to include decimal
 * ISS-002041 26-07-2024 Sueanne - update to execute rollup when lookup is updated for new and old map 
 * ISS-002453 19-06-2025 XW - validate rollup condition formula before querying parent records
 * ISS-001425 25-07-2025 XiRouh - Updated to check the rollup condition for both the old and new records
 * ISS-002587 18-08-2025 XiRouh - Removed the check for the parent field in the rollup filter fields
 */
public without sharing class REDU_CustomRollup_OBJ {

    /**
     * Rollup type
     */ 
    public final static string COUNT = 'COUNT';
    
    /**
     * Rollup type
     */ 
    public final static string MIN = 'MIN';
    
    /**
     * Rollup type
     */ 
    public final static string MAX = 'MAX';
    
    /**
     * Rollup type
     */ 
    public final static string SUM = 'SUM';

    /**
     * Field type - DATE
     */
    public final static String DATETYPE = 'DATE';
    
    /**
     * Field type - INTEGER
     */
    public final static String INTEGERTYPE = 'INTEGER';

    /**
     * Field type - DECIMAL
     */
    public final static String DECIMALTYPE = 'DECIMAL';
    
    /**
     * Field type - CURRENCY
     */
    public final static String CURRENCYTYPE = 'CURRENCY';

    /**
     * @description Is multi currency org
     */
    private final static Boolean IS_MULTICURRENCY_ORG = ORG_Helper.isMultiCurrenciesOrg();
    
    private Map<String, SObject> countMap = new Map<String, SObject>();
    private Map<String, SObject> sumMap = new Map<String, SObject>();
    private Map<String, SObject> minMap = new Map<String, SObject>();
    private Map<String, SObject> maxMap = new Map<String, SObject>();

    private List<SObject> objectList = new List<SObject>();
    private List<SObject> oldObjectList = new List<SObject>();
    
    private Map<Id, List<SObject>> parentChildsMap = new Map<Id, List<SObject>>();

    Map<String, List<reduivy__Custom_Rollup_Config__mdt>> rollupConfigsByParentObject = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();

    /**
     * This is the default constructor that holds the trigger context.
     * 
     * @param newSObjects This is the new object list, e.g, Trigger.new
     * @param oldSObjects This is the old object list, e.g, Trigger.old
     * @param rollupConfigsByParentObject Map of custom rollup configs grouped by parent object
     * 
     */
    public REDU_CustomRollup_OBJ(List<SObject> objectList, List<SObject> oldObjectList, Map<String, List<reduivy__Custom_Rollup_Config__mdt>> rollupConfigsByParentObject){
        this.rollupConfigsByParentObject = rollupConfigsByParentObject;
        this.objectList = objectList;
        this.oldObjectList = oldObjectList;
    }
    
    /**
     * This is the method that performs the roll up calculation.
     */
    public void doRollup(){
        
        Map<Id, SObject> objListToUpdate = new Map<Id, SObject>();

        if(rollupConfigsByParentObject != null && !rollupConfigsByParentObject.isEmpty()){
            
            Map<String, Decimal> conversionRate = new Map<String, Decimal>();
            //Handles multi-currency conversion
            if(IS_MULTICURRENCY_ORG){
                for(SObject currType : Database.query('SELECT IsoCode, ConversionRate FROM CurrencyType')){
                    conversionRate.put((String)currType.get('IsoCode'), (Decimal)currType.get('ConversionRate'));
                }
            }
            
            for (String parentObjType : rollupConfigsByParentObject.keySet()) {
                List<reduivy__Custom_Rollup_Config__mdt> rollupConfigs = rollupConfigsByParentObject.get(parentObjType);
                List<SObject> parentObjects = new List<SObject>();

                //Get parent Ids and parent fields
                Map<Id, SObject> oldMap = new Map<Id, SObject>(oldObjectList);
                Set<Id> parentIds = new Set<Id>();
                Set<String> parentFields = new Set<String>{'Id'};

                for(reduivy__Custom_Rollup_Config__mdt config : rollupConfigs) {
                    parentFields.add(config.reduivy__Master_Object_Field_Name__c);
                    
                    String formulaString = getCompleteFormula(config);
                    Boolean skipRollupCondition = String.isBlank(formulaString);

                    FormulaEval.FormulaInstance configRollupValidationFormula;
                    Set<String> referenceFields;

                    if(!skipRollupCondition) {

                        configRollupValidationFormula = Formula.builder().withReturnType(FormulaEval.FormulaReturnType.Boolean)
                                                        .withType(objectList.getSObjectType())
                                                        .withFormula(formulaString)
                                                        .build();
                                                        
                        referenceFields = configRollupValidationFormula.getReferencedFields();

                        //ISS-002587
                        for(String fieldName : referenceFields) {
                            if(fieldName.contains('.')) {
                                String exMsg = String.format(Label.Rollup_Conditions_Not_Allow_Relationship_Field_Error, new List<String>{fieldName});
                                
                                throw new REDU_ApplicationException(exMsg);
                            }
                        }
                    }                     

                    for(SObject sobj : objectList){
                        //skip the record if the value for the field to be rollup is unchanged
                        if(!skipRollupCondition) {
                            Boolean isExistingRecord = oldMap.containsKey(sobj.Id);
                            Boolean isNewRecordRollupConditionTrue = rollupConditionFormulaIsTrue(sobj, configRollupValidationFormula);
                            Boolean isExistingRecordRollupConditionTrue = isExistingRecord ? rollupConditionFormulaIsTrue(oldMap.get(sobj.Id), configRollupValidationFormula) : false;

                            if (
                                (
                                    isExistingRecord &&
                                    (
                                        !anyFieldValueIsChanged(oldMap.get(sobj.Id), sobj, config, referenceFields) ||
                                        (!isNewRecordRollupConditionTrue && !isExistingRecordRollupConditionTrue) //ISS-002536
                                    )
                                ) ||
                                (
                                    !isExistingRecord &&
                                    !isNewRecordRollupConditionTrue
                                )
                            ) {
                                continue;
                            }
                        }

                        if(sobj.get(config.reduivy__Parent_Relationship_Field__c) != null ){
                            Id parentId = (Id)sobj.get(config.reduivy__Parent_Relationship_Field__c);
                            parentIds.add(parentId);

                            //add the child to the parentChildsMap for error handling
                            if (parentChildsMap.containsKey(parentId)) {
                                parentChildsMap.get(parentId).add(sobj);
                            } else {
                                parentChildsMap.put(parentId, new List<SObject>{sobj});
                            }
                        }

                        if(oldMap.get(sobj.Id)?.get(config.reduivy__Parent_Relationship_Field__c) != null && sobj.get(config.reduivy__Parent_Relationship_Field__c) != oldMap.get(sobj.Id).get(config.reduivy__Parent_Relationship_Field__c)){
                            Id oldParentId = (Id)oldMap.get(sobj.Id).get(config.reduivy__Parent_Relationship_Field__c);
                            parentIds.add(oldParentId);

                            // add the child to the parentChildsMap for error handling
                            if (parentChildsMap.containsKey(oldParentId)) {
                                parentChildsMap.get(oldParentId).add(sobj);
                            } else {
                                parentChildsMap.put(oldParentId, new List<SObject>{sobj});
                            }
                        }
                    }
                }

                if(parentIds.isEmpty()) {
                    continue;
                }

                String parentFieldsString = String.join(parentFields, ', ');

                Map<String, Object> parentQueryBindParams = new Map<String, Object>();
                parentQueryBindParams.put('parentIds', parentIds);

                //Query parent objects
                String parentQuery = 'SELECT ' + parentFieldsString + ' FROM ' + parentObjType + ' WHERE Id IN: parentIds FOR UPDATE';
                parentObjects = (List<SObject>) Database.queryWithBinds(parentQuery, parentQueryBindParams, AccessLevel.SYSTEM_MODE);

                for(reduivy__Custom_Rollup_Config__mdt config : rollupConfigs) {

                    countMap = new Map<String, SObject>();
                    sumMap = new Map<String, SObject>();
                    minMap = new Map<String, SObject>();
                    maxMap = new Map<String, SObject>();
    
                    String currencyField = 'Currency';
                    String masterObjectField = config.reduivy__Master_Object_Field_Name__c;
                    String fieldType = config.reduivy__Field_Type__c;
    
                    if(!parentIds.isEmpty()){
                        prepareQueryResult(config, parentIds);
    
                        for(SObject sobj : parentObjects){
                            
                            Id currentId = (Id)sobj.get('Id');
                            
                            if(config.reduivy__Rollup_Type__c == COUNT){
                                if(countMap.containsKey(currentId)){
                                    sobj.put(masterObjectField, countMap.get(currentId).get('expr0'));
                                } else {
                                    sobj.put(masterObjectField, 0);
                                }
                                
                            } else if(config.reduivy__Rollup_Type__c == SUM){
                                if(sumMap.containsKey(currentId)){
                                    //Multi-currency
                                    if (fieldType == CURRENCYTYPE){
                                        if (IS_MULTICURRENCY_ORG && conversionRate.containsKey((String)sumMap.get(currentId).get(currencyField))){
                                            sobj.put(masterObjectField, (Decimal)sumMap.get(currentId).get('expr0') * conversionRate.get((String)sumMap.get(currentId).get(currencyField)));
                                        } else {
                                            sobj.put(masterObjectField, (Decimal)sumMap.get(currentId).get('expr0'));
                                        }
                                    } else if (fieldType == INTEGERTYPE) {
                                        sobj.put(masterObjectField, Integer.valueOf(sumMap.get(currentId).get('expr0')));
                                    } else {
                                        sobj.put(masterObjectField, sumMap.get(currentId).get('expr0'));
                                    }
                                } else {
                                    sobj.put(masterObjectField, 0);
                                    
                                }
                                
                            } else if(config.reduivy__Rollup_Type__c == MIN){
                                if(minMap.containsKey(currentId)){
                                    //Multi-currency
                                    if (fieldType == CURRENCYTYPE){
                                        if (IS_MULTICURRENCY_ORG && conversionRate.containsKey((String)minMap.get(currentId).get(currencyField))){
                                            sobj.put(masterObjectField, (Decimal)minMap.get(currentId).get('expr0') * conversionRate.get((String)minMap.get(currentId).get(currencyField)));
                                        } else {
                                            sobj.put(masterObjectField, (Decimal)minMap.get(currentId).get('expr0'));
                                        }
                                    } else if (fieldType == INTEGERTYPE) {
                                        sobj.put(masterObjectField, Integer.valueOf(minMap.get(currentId).get('expr0')));
                                    } else {
                                        sobj.put(masterObjectField, minMap.get(currentId).get('expr0'));
                                    }
                                } else {                            
                                    if (fieldType == DATETYPE) {
                                        sobj.put(masterObjectField, null); // Needed to handle the rollup of Date type
                                    } else if (fieldType == INTEGERTYPE || fieldType == CURRENCYTYPE || fieldType == DECIMALTYPE) {                                
                                        sobj.put(masterObjectField, 0);
                                    }                                
                                }
                                
                            } else if(config.reduivy__Rollup_Type__c == MAX){
                                if(maxMap.containsKey(currentId)){
                                    //Multi-currency
                                    if (fieldType == CURRENCYTYPE){
                                        if (IS_MULTICURRENCY_ORG && conversionRate.containsKey((String)maxMap.get(currentId).get(currencyField))){
                                            sobj.put(masterObjectField, (Decimal)maxMap.get(currentId).get('expr0') * conversionRate.get((String)maxMap.get(currentId).get(currencyField)));
                                        } else {
                                            sobj.put(masterObjectField, maxMap.get(currentId).get('expr0'));
                                        }
                                    } else if(fieldType == INTEGERTYPE) {
                                        sobj.put(masterObjectField, Integer.valueOf(maxMap.get(currentId).get('expr0')));
                                    } else {
                                        sobj.put(masterObjectField, maxMap.get(currentId).get('expr0'));
                                    }
                                } else {
                                    if (fieldType == DATETYPE) {
                                        sobj.put(masterObjectField, null);
                                    } else if (fieldType == INTEGERTYPE || fieldType == CURRENCYTYPE || fieldType == DECIMALTYPE) {
                                        sobj.put(masterObjectField, 0);
                                    }
                                }                        
                            }
                            
                            objListToUpdate.put(currentId, sobj);
                        }
                    }
                    
                    
                }
            }
            
            List<SObject> updateList = objListToUpdate.values();

            REDU_SystemMode_UTIL.doUpdate(updateList, parentChildsMap, 'Id', false);
        }
    }
    
    /*
     * This method will be invoked by doRollup() method to query the records based on filter conditions and populate the result into countMap, sumMap, minMap and maxMap
     * @param config    Lookup_Roolup_Configuration__c custom setting instance
     * @param parentIds A collection of parent record id
     */
    private void prepareQueryResult(reduivy__Custom_Rollup_Config__mdt config, Set<Id> parentIds){
        
        String condition = '';
    
        if (String.isNotBlank(config.reduivy__Filter_Logic__c)) {
            condition = String.format(config.reduivy__Filter_Logic__c, new List<String>{config.reduivy__Filter_Criteria_1__c, config.reduivy__Filter_Criteria_2__c, config.reduivy__Filter_Criteria_3__c, config.reduivy__Filter_Criteria_4__c, config.reduivy__Filter_Criteria_5__c});
        }

        REDU_Logging_UTIL.debug('REDU_CustomRollup_OBJ.prepareQueryResult.config', config);
        REDU_Logging_UTIL.debug('REDU_CustomRollup_OBJ.prepareQueryResult.parentIds', parentIds);
        REDU_Logging_UTIL.debug('REDU_CustomRollup_OBJ.prepareQueryResult.condition', condition);

        if(config.reduivy__Rollup_Type__c == COUNT){
            
            Map<String, Object> countBindMap = new Map<String, Object>();
            countBindMap.put('parentIds', parentIds);

            String countQuery = 'SELECT COUNT(Id), ' + config.reduivy__Parent_Relationship_Field__c + 
                ' FROM ' + config.reduivy__Child_Object_Name__c + 
                ' WHERE ' + config.reduivy__Parent_Relationship_Field__c + ' IN: parentIds ' + 
                (String.isNotBlank(condition) ? ' AND ' + condition : '') + 
                ' GROUP BY ' + config.reduivy__Parent_Relationship_Field__c;
            
            for(SObject sobj : Database.queryWithBinds(countQuery, countBindMap, AccessLevel.SYSTEM_MODE)) {
                String parentId = String.valueOf(sobj.get(config.reduivy__Parent_Relationship_Field__c));
                    
                countMap.put(parentId, sobj);
            }
            
            REDU_Logging_UTIL.debug('REDU_CustomRollup_OBJ.countMap', countMap);
        
        } else if(config.reduivy__Rollup_Type__c == MAX){
            
            Map<String, Object> maxBindMap = new Map<String, Object>();
            maxBindMap.put('parentIds', parentIds);

            String maxQuery = 'SELECT MAX(' + config.reduivy__Child_Object_Field_Name__c + '), ' + config.reduivy__Parent_Relationship_Field__c;

            //Multi-currency
            if (IS_MULTICURRENCY_ORG && config.reduivy__Field_Type__c == CURRENCYTYPE) {
                maxQuery += ', ' + config.reduivy__Parent_Relationship_Field__c.replace('__c', '__r') + '.CurrencyIsoCode Currency'; //Alliased to Currency due to __r issues
            }

            maxQuery +=  ' FROM ' + config.reduivy__Child_Object_Name__c + 
                ' WHERE ' + config.reduivy__Parent_Relationship_Field__c + ' IN: parentIds ' + 
                (String.isNotBlank(condition) ? ' AND ' + condition : '') + 
                ' GROUP BY ' + config.reduivy__Parent_Relationship_Field__c;
            
            if (IS_MULTICURRENCY_ORG && config.reduivy__Field_Type__c == CURRENCYTYPE) {
                maxQuery += ', ' + config.reduivy__Parent_Relationship_Field__c.replace('__c', '__r') + '.CurrencyIsoCode'; //add the field to group by
            }
            
            for(SObject sobj : Database.queryWithBinds(maxQuery, maxBindMap, AccessLevel.SYSTEM_MODE)) {
                String parentId = String.valueOf(sobj.get(config.reduivy__Parent_Relationship_Field__c));
                    
                maxMap.put(parentId, sobj);
            }
            
            REDU_Logging_UTIL.debug('REDU_CustomRollup_OBJ.maxMap', maxMap);
        
        } else if(config.reduivy__Rollup_Type__c == SUM){
            
            Map<String, Object> sumBindMap = new Map<String, Object>();
            sumBindMap.put('parentIds', parentIds);

            String sumQuery = 'SELECT SUM(' + config.reduivy__Child_Object_Field_Name__c + '), ' + config.reduivy__Parent_Relationship_Field__c;

            //Edited 7/8/2018 by CM - Multi-currency
            if (IS_MULTICURRENCY_ORG && config.reduivy__Field_Type__c == CURRENCYTYPE) {
                sumQuery += ', ' + config.reduivy__Parent_Relationship_Field__c.replace('__c', '__r') + '.CurrencyIsoCode Currency'; //Alliased to Currency due to __r issues
            }

            sumQuery += ' FROM ' + config.reduivy__Child_Object_Name__c + 
                ' WHERE ' + config.reduivy__Parent_Relationship_Field__c + ' IN: parentIds ' + 
                (String.isNotBlank(condition) ? ' AND ' + condition : '') + 
                ' GROUP BY ' + config.reduivy__Parent_Relationship_Field__c;
            
            if (IS_MULTICURRENCY_ORG && config.reduivy__Field_Type__c == CURRENCYTYPE) {
                sumQuery += ', ' + config.reduivy__Parent_Relationship_Field__c.replace('__c', '__r') + '.CurrencyIsoCode'; //add the field to group by
            }
            
            for(SObject sobj : Database.queryWithBinds(sumQuery, sumBindMap, AccessLevel.SYSTEM_MODE)) {
                String parentId = String.valueOf(sobj.get(config.reduivy__Parent_Relationship_Field__c));
                    
                sumMap.put(parentId, sobj);
            }
            
            REDU_Logging_UTIL.debug('REDU_CustomRollup_OBJ.sumMap', sumMap);
        
        } else if(config.reduivy__Rollup_Type__c == MIN){
            
            Map<String, Object> minBindMap = new Map<String, Object>();
            minBindMap.put('parentIds', parentIds);

            String minQuery = 'SELECT MIN(' + config.reduivy__Child_Object_Field_Name__c + '), ' + config.reduivy__Parent_Relationship_Field__c;
            
            //Multi-currency
            if (IS_MULTICURRENCY_ORG && config.reduivy__Field_Type__c == CURRENCYTYPE){
                minQuery += ', ' + config.reduivy__Parent_Relationship_Field__c.replace('__c', '__r') + '.CurrencyIsoCode Currency'; //Alliased to Currency due to __r issues
            }

            minQuery += ' FROM ' + config.reduivy__Child_Object_Name__c + 
                ' WHERE ' + config.reduivy__Parent_Relationship_Field__c + ' IN: parentIds ' + 
                (String.isNotBlank(condition) ? ' AND ' + condition : '') + 
                ' GROUP BY ' + config.reduivy__Parent_Relationship_Field__c;
            
            if (IS_MULTICURRENCY_ORG && config.reduivy__Field_Type__c == CURRENCYTYPE){
                minQuery += ', ' + config.reduivy__Parent_Relationship_Field__c.replace('__c', '__r') + '.CurrencyIsoCode'; //add the field to group by
            }
            
            for(SObject sobj : Database.queryWithBinds(minQuery, minBindMap, AccessLevel.SYSTEM_MODE)){
                String parentId = String.valueOf(sobj.get(config.reduivy__Parent_Relationship_Field__c));
                    
                minMap.put(parentId, sobj);
            }
            
            REDU_Logging_UTIL.debug('REDU_CustomRollup_OBJ.minMap', minMap);
        }
        
    }    

    /**
     * @description return true if the parent relationship is changed
     * @param  sobj   the child sobj record
     * @param  config custom rollup config
     * @return        Boolean
     */
    private Boolean anyFieldValueIsChanged(SObject oldSobj, SObject sobj, reduivy__Custom_Rollup_Config__mdt config, Set<String> referenceFields) {
        Boolean parentRelationshipFieldIsChanged = sobj.get(config.reduivy__Parent_Relationship_Field__c) != oldSobj.get(config.reduivy__Parent_Relationship_Field__c);
        Boolean childObjectFieldValueIsChanged = sobj.get(config.reduivy__Child_Object_Field_Name__c) != oldSobj.get(config.reduivy__Child_Object_Field_Name__c);

        if(parentRelationshipFieldIsChanged || childObjectFieldValueIsChanged) {
            return true;
        }

        for(String referenceField : referenceFields) {
            if(sobj.get(referenceField) != oldSobj.get(referenceField)) {
                return true;
            }
        }
        
        return false;
    }

    /** 
     * @description return true if the child object field value is changed
     * @param  sobj   the child sobj record
     * @param  config custom rollup config
     * @return        Boolean
     */
    private Boolean rollupConditionFormulaIsTrue(SObject sobj, FormulaEval.FormulaInstance rollupConditionFormula) {
        Boolean result = (Boolean) rollupConditionFormula.evaluate(sobj);
        return result;
    }

    /**
     * @description get the rollup condition formula
     * @param  config the custom rollup config metadata
     * @return        The rollup condition formula
     */
    private String getCompleteFormula(reduivy__Custom_Rollup_Config__mdt config) {
        String logic = config.reduivy__Rollup_Condition_Logic__c;
        if(String.isBlank(logic)) {
            return '';
        }

        return String.format(logic, new List<String> {
            config.reduivy__Rollup_Condition_Formula_1__c,
            config.reduivy__Rollup_Condition_Formula_2__c,
            config.reduivy__Rollup_Condition_Formula_3__c,
            config.reduivy__Rollup_Condition_Formula_4__c,
            config.reduivy__Rollup_Condition_Formula_5__c
        });
    }
}