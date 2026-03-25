/**
 * @author      WDCi (XW)
 * @date        May 2025
 * @group       Requirement
 * @description generate individual requirement set when the criteria meets
 * @changehistory
 * ISS-002128 30-05-2025 XW - new class
 * ISS-002588 19-08-2025 XW - Consider if related fields are changed before generating Individual Requirement Set for SObject
 * ISS-002633 07-01-2026 XW - Support referenced contact field in SRS contact field
 */

public inherited sharing class SOBJ_CreateIndividualRequirementSet_EXE extends REDU_TriggerExecutable {
    
    /**
     * @description AfterInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            validateCreation(newMap, oldMap, sobjResult);
        }
    }

    /**
     * @description AfterUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            validateCreation(newMap, oldMap, sobjResult);
        }
    }

    /**
     * @description validate the creation of individual requirement set
     * @param  sobjectList the parent record list
     * @param  sobjResult  the sobject result of the parent object
     */
    private static void validateCreation(Map<Id, SObject> sobjectMap, Map<Id, SObject> oldSobjectMap, Schema.DescribeSObjectResult sobjResult) {
        Map<Id, reduivy__Study_Requirement_Set__c> srsMap = new Map<Id, reduivy__Study_Requirement_Set__c>();
        Map<Id, FormulaEval.FormulaInstance> srsFormulaMap = new Map<Id, FormulaEval.FormulaInstance>();
        Set<String> formulaReferencedFieldsSet = new Set<String>();
        Set<String> contactFieldReferencedFieldsSet = new Set<String>();
        List<SObject> sObjectToEvaluateList = new List<SObject>();
        Map<Id, Set<Id>> sobjIdToSrsIdSetMap = new Map<Id, Set<Id>>();
        String irsObjectLookupField;
        Set<Id> srsIdSet = new Set<Id>();

        Set<String> srsFields = new Set<String> {
            'Id', 
            'Name',
            'reduivy__Status__c',
            'reduivy__Object__c',
            'reduivy__Description__c',
            'reduivy__Criteria__c',
            'reduivy__Contact_Field__c',
            'reduivy__Code__c'
        };
        srsFields.addAll(IRS_Helper.getSrsIrsCommonFields());

        String srsQuery = 'SELECT ' + String.join(srsFields, ', ') +
                         ' FROM ' + SRS_Helper.getApiName() +
                         ' WHERE reduivy__Status__c = :srsActive' +
                         ' AND reduivy__Object__c = :sobjName' +
                         ' AND reduivy__Requirement_Generation_Mode__c = :modeAuto';
        Map<String, Object> srsBindMap = new Map<String, Object> {
            'srsActive' => SRS_Helper.STATUS_ACTIVE,
            'sobjName' => sobjResult.getName(),
            'modeAuto' => SRS_Helper.REQUIREMENT_GENERATION_MODE_AUTO
        };

        for(reduivy__Study_Requirement_Set__c srs: (List<reduivy__Study_Requirement_Set__c>) Database.queryWithBinds(srsQuery, srsBindMap, AccessLevel.USER_MODE)) {
            if(String.isBlank(srs.reduivy__Criteria__c)) {
                continue;
            }
            srsIdSet.add(srs.Id);

            irsObjectLookupField = REDU_Metadata_UTIL.getObjectLookupField(IRS_Helper.getApiName(), srs.reduivy__Object__c);
            FormulaEval.FormulaInstance srsCriteriaFormula = Formula.builder()
                                                            .withReturnType(FormulaEval.FormulaReturnType.Boolean)
                                                            .withType(sobjResult.getSObjectType())
                                                            .withFormula(srs.reduivy__Criteria__c)
                                                            .build();

            formulaReferencedFieldsSet.addAll(srsCriteriaFormula.getReferencedFields());

            //add contact field to referencedFieldSet if the field is in parent record
            if(String.isNotBlank(srs.reduivy__Contact_Field__c)) {
                contactFieldReferencedFieldsSet.add(srs.reduivy__Contact_Field__c);
            }

            //build the formula builder, get the formula from reduivy__Criteria__c
            srsFormulaMap.put(srs.Id, srsCriteriaFormula);

            srsMap.put(srs.Id, srs);
        }

        //get neccesary parent value if found using getReferencedFields
        //also get the contact field if the contact field is in the parent record
        Boolean criteriaHasParentRecordReference = false;
        Boolean contactHasParentRecordReference = false;
        Map<Id, SObject> sobjMapForCreatingIrs;
        if(!formulaReferencedFieldsSet.isEmpty() || !contactFieldReferencedFieldsSet.isEmpty()) {
            Set<String> allReferencedFields = new Set<String>();

            for(String formulaReferencedField : formulaReferencedFieldsSet) {
                if(formulaReferencedField.contains('.')) {
                    allReferencedFields.addAll(formulaReferencedFieldsSet);
                    criteriaHasParentRecordReference = true;
                    break;
                }
            }

            for(String contactFieldReferencedField : contactFieldReferencedFieldsSet) {
                if(contactFieldReferencedField.contains('.')) {
                    allReferencedFields.addAll(contactFieldReferencedFieldsSet);
                    contactHasParentRecordReference = true;
                    break;
                }
            }

            if(!allReferencedFields.isEmpty()) {
                if(contactHasParentRecordReference) {
                    sobjMapForCreatingIrs = new Map<Id, SObject>();
                } else {   
                    sobjMapForCreatingIrs = sobjectMap;
                }

                String queryString = 'SELECT ' + String.join(allReferencedFields, ', ') + 
                                    ' FROM ' + sobjResult.getName() + 
                                    ' WHERE Id IN :sobjectList';

                Map<String, Object> bindMap = new Map<String, Object> {
                    'sobjectList' => sobjectMap.keySet()
                };

                for(SObject sobjWithParentRecord : Database.queryWithBinds(queryString, bindMap, AccessLevel.SYSTEM_MODE)) {
                    sObjectToEvaluateList.add(sobjWithParentRecord);

                    if(contactHasParentRecordReference) {
                        SObject clonedSObj = sobjectMap.get(sobjWithParentRecord.Id).clone(true, true);
                        
                        for(String contactFieldReferencedField : contactFieldReferencedFieldsSet) {
                            Id referencedContactId = (Id) REDU_SObject_UTIL.extractFieldValue(sobjWithParentRecord, contactFieldReferencedField);
                            REDU_SObject_UTIL.setFieldValue(clonedSObj, contactFieldReferencedField, referencedContactId);
                        }

                        sobjMapForCreatingIrs.put(clonedSObj.Id, clonedSObj);
                    }
                    
                }
            } else {
                sobjMapForCreatingIrs = sobjectMap;
                sObjectToEvaluateList = sobjectMap.values();
            }
        } 

        //evaluate the formula
        for(SObject sobjectToEvaluate : sObjectToEvaluateList) {
            for(Id srsId : srsFormulaMap.keySet()) {
                FormulaEval.FormulaInstance fi = srsFormulaMap.get(srsId);
                Boolean isValid = (Boolean)fi.evaluate(sobjectToEvaluate);
                Boolean wasValid = criteriaHasParentRecordReference || oldSobjectMap.isEmpty() ? false : (Boolean) fi.evaluate(oldSobjectMap.get(sobjectToEvaluate.Id));
                if(!wasValid && isValid) {
                    
                    if(!sobjIdToSrsIdSetMap.containsKey(sobjectToEvaluate.Id)) {
                        sobjIdToSrsIdSetMap.put(sobjectToEvaluate.Id, new Set<Id>());
                    }
                    sobjIdToSrsIdSetMap.get(sobjectToEvaluate.Id).add(srsId);
                }
            }
        }

        //check if the individual requirement set is created before
        if(!sobjIdToSrsIdSetMap.isEmpty()) {
            Map<Id, List<reduivy__Individual_Requirement_Set__c>> createdIrs = new Map<Id, List<reduivy__Individual_Requirement_Set__c>>();
            Map<String, Object> irsBindMap = new Map<String, Object>{
                'srsIdSet' => srsIdSet,
                'sobjectList' => sobjectMap.keySet()
            };

            String irsQuery = 'SELECT Id, reduivy__Study_Requirement_Set__c, ' + irsObjectLookupField  
                            + ' FROM reduivy__Individual_Requirement_Set__c '
                            + ' WHERE reduivy__Study_Requirement_Set__c IN :srsIdSet'
                            + ' AND ' + irsObjectLookupField + ' IN :sobjectList' ;

            for(reduivy__Individual_Requirement_Set__c irs : (List<reduivy__Individual_Requirement_Set__c>) Database.queryWithBinds(irsQuery, irsBindMap, AccessLevel.SYSTEM_MODE)){
                Id targetSObjectId = (Id)irs.get(irsObjectLookupField);
                if(String.isNotBlank(targetSObjectId) && sobjIdToSrsIdSetMap.containsKey(targetSObjectId)) {
                    sobjIdToSrsIdSetMap.get(targetSObjectId).remove(irs.reduivy__Study_Requirement_Set__c);
                }
            }
            
        }

        //group the validated sobject to create irs for them
        if(!sobjIdToSrsIdSetMap.isEmpty()) {
            createIrs(sobjectMap, sobjMapForCreatingIrs, sobjIdToSrsIdSetMap, srsMap, sobjResult, irsObjectLookupField);
        }

    }

    /**
     * @description create the individual requirement set
     * @param  sobjectMap           parent sobject record map
     * @param  sobjIdToSrsIdSetMap  sobject id to its related study requirement set id map
     * @param  srsMap               study requirement set map
     * @param  sobjResult           describe sobject result of the parent record
     * @param  irsObjectLookupField parent object lookup field name from individual requirement set
     */
    private static void createIrs(Map<Id, SObject> sobjectMap, Map<Id, SObject> sobjectMapForCreatingIrs, Map<Id, Set<Id>> sobjIdToSrsIdSetMap, Map<Id, reduivy__Study_Requirement_Set__c> srsMap, Schema.DescribeSObjectResult sobjResult, String irsObjectLookupField) {
        List<reduivy__Individual_Requirement_Set__c> irsListToInsert = new List<reduivy__Individual_Requirement_Set__c>();
        Boolean isMdRelationship = REDU_Metadata_UTIL.hasMasterDetailRelationship(sobjResult.getName());

        //create irs with following fields
        for(Id sobjectId : sobjIdToSrsIdSetMap.keySet()) {
            SObject sobj = sobjectMapForCreatingIrs.get(sobjectId);

            for(Id srsId : sobjIdToSrsIdSetMap.get(sobjectId)) {
                reduivy__Study_Requirement_Set__c srs = srsMap.get(srsId);
                Id ownerId = isMdRelationship ? UserInfo.getUserId() : (Id) sobj.get('OwnerId');
                reduivy__Individual_Requirement_Set__c irs = IRS_Helper.createIrs(srs, sobj, ownerId);

                irsListToInsert.add(irs);
                
            }
        }

        if(!irsListToInsert.isEmpty()) {
            REDU_Database_UTIL.doInsert(irsListToInsert, sobjectMap, irsObjectLookupField, false); 
        }

    }
}