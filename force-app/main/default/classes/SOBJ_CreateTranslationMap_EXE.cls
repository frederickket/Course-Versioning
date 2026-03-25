/**
 * @author      WDCi (XW)
 * @date        Jan 2025
 * @group       Translation
 * @description Create translation map record and translation record before sobject is created
 * @changehistory
 * ISS-002230 03-02-2025 XW - create new class
 * ISS-002495 18-09-2025 XW - support translation for long text field
 */
public inherited sharing class SOBJ_CreateTranslationMap_EXE extends REDU_TriggerExecutable {

    private static final Set<String> FIELDS_DO_NOT_CLONE = new Set<String> {
        'reduivy__External_Id__c',
        'reduivy__UUID__c',
        'reduivy__Reference__c',
        'reduivy__Default__c',
        'reduivy__Sample_Record_Code__c'
    };

    /**
     * @description BeforeInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN) &&
            REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()
        ) {

            Map<String, Object> translationInfo = REDU_TranslationManager.getTranslationInfoForSObject(sobjResult);

            //track the api name for the translation map lookup field on the sobject
            String tlmFieldNameInSObject = (String) translationInfo.get(REDU_TranslationManager.TRANSLATION_MAP_FIELD_NAME);
            //track the api relationship name for the translation map lookup field on the sobject
            String tlmFieldRelationship = (String) translationInfo.get(REDU_TranslationManager.TRANSLATION_MAP_RELATIONSHIP_NAME);

            //track the translation field vs relationship api name in reduivy__Translation_Map__c object e.g., reduivy__Translation_1__c=reduivy__Translation_1__r
            //this is used to query the source records's translation if it is cloned
            Map<String, String> tlnFieldsNameAndRelationshipInTlm = (Map<String, String>) translationInfo.get(REDU_TranslationManager.TRANSLATION_FIELD_AND_RELATIONSHIP_IN_TLM);

            //track the formula field vs field to be translated in core object e.g., reduivy__Translated_Name__c=Name
            Map<String, String> formulaField_targetFieldToTranslate = (Map<String, String>) translationInfo.get(REDU_TranslationManager.TRANSLATION_FORMULA_FIELD_TO_SOURCE_FIELD);

            //track the translation field relationship api name vs field to be translated e.g., reduivy__Translation_1__r=Name
            //this is used to identify the source records's translation if it is cloned
            Map<String, String> tlnFieldRelationship_targetFieldToTranslate = (Map<String, String>) translationInfo.get(REDU_TranslationManager.TRANSLATION_FIELD_RELATIONSHIP_TO_SOURCE_FIELD);

            //track the translation field vs field to be translated e.g., reduivy__Translation_1__c=Name
            Map<String, String> tlnFieldsName_targetFieldToTranslate = (Map<String, String>) translationInfo.get(REDU_TranslationManager.TRANSLATION_FIELD_TO_SOURCE_FIELD);  

            //Stores the formula field that display the translation display field in Sobject
            List<REDU_TranslationManager.TranslationMapping> sobjTranslationFormulaFields = (List<REDU_TranslationManager.TranslationMapping>) translationInfo.get(REDU_TranslationManager.OBJ_TRANSLATION_FORMULA_FIELDS);

            //stores the source field/object and the tranlastion fields in translation map for the source field.
            List<REDU_TranslationManager.TranslationMapping> translationMappingWrapperList = (List<REDU_TranslationManager.TranslationMapping>) translationInfo.get(REDU_TranslationManager.OBJ_TRANSLATION_MAPPING_CONFIG_FIELDS);

            //if there is no Translation Map Field in Sobject, we will skip everything
            if(String.isBlank(tlmFieldNameInSObject)) {
                return;
            }

            REDU_Logging_UTIL.debugJsonString('translationMapFieldNameInObject', tlmFieldNameInSObject);
            REDU_Logging_UTIL.debugJsonString('translationMapFieldRelationshipInObject', tlmFieldRelationship);
            REDU_Logging_UTIL.debugJsonString('translationFieldAndRelationshipInTranslationMapObject', tlnFieldsNameAndRelationshipInTlm);
			REDU_Logging_UTIL.debugJsonString('objectTranslationFormulaFields', sobjTranslationFormulaFields);
            REDU_Logging_UTIL.debugJsonString('translationFormulaFieldToSourceField', formulaField_targetFieldToTranslate);
            REDU_Logging_UTIL.debugJsonString('translationFieldRelationshipToSourceField', tlnFieldRelationship_targetFieldToTranslate);
            REDU_Logging_UTIL.debugJsonString('translationFieldToSourceField', tlnFieldsName_targetFieldToTranslate);
            REDU_Logging_UTIL.debugJsonString('objectTranslationMappingConfigFields', translationMappingWrapperList);

            //get the source records for cloned records
            Map<Id, SObject> sourceRecordsMap = getCloneSourceRecords(newList, tlmFieldNameInSObject, tlmFieldRelationship, tlnFieldsNameAndRelationshipInTlm);
            
            REDU_Logging_UTIL.debugJsonString('sourceRecordsMap', sourceRecordsMap);
            boolean sourceRecordsMapIsEmpty = sourceRecordsMap.isEmpty();

            List<SObject> workingList = new List<SObject>();
            for(SObject obj : newList) {
                //add into working list if tlm is not linked, or the cloned records has the same tlm as the source record
                if(
                    obj.get(tlmFieldNameInSObject) == null ||
                    (
                        obj.isClone() && 
                        !sourceRecordsMapIsEmpty &&
                        sourceRecordsMap.get(obj.getCloneSourceId()) != null &&
                        sourceRecordsMap.get(obj.getCloneSourceId()).get(tlmFieldNameInSObject) == obj.get(tlmFieldNameInSObject)
                    )
                ) {
                    workingList.add(obj);
                }
                
            }
                
            //create cloned translation for cloned records
            Map<String, reduivy__Translation__c> sourceRecordsTranslations = getCloneSourceRecordsTranslations(sourceRecordsMap.values(), tlmFieldRelationship, tlnFieldsNameAndRelationshipInTlm, tlnFieldRelationship_targetFieldToTranslate );
            Map<Id, reduivy__Translation_Map__c> sourceRecordsTranslationMaps = getCloneSourceRecordsTranslationMaps(sourceRecordsMap.values(), tlmFieldRelationship);
            REDU_Logging_UTIL.debugJsonString('sourceRecordsTranslations', sourceRecordsTranslations);
            REDU_Logging_UTIL.debugJsonString('sourceRecordsTranslationMaps', sourceRecordsTranslationMaps);

            if(!tlnFieldsName_targetFieldToTranslate.isEmpty() && !workingList.isEmpty()) {                
                createTranslationMapAndTranslation(workingList, tlnFieldsName_targetFieldToTranslate, tlmFieldNameInSObject, sobjTranslationFormulaFields, formulaField_targetFieldToTranslate, sourceRecordsTranslations, sourceRecordsTranslationMaps, translationMappingWrapperList);
            }
        }
    }
	
    /**
     * @description create and link translation map and translation
     * @param  objList                              the object records list
     * @param  tlnFieldsName_targetFieldToTranslate Translation field mapping against core object
     * @param  tlmFieldNameInSObject                the tlm field name in sobject to be linked by translation map
     * @param  sobjTranslationFormulaFields         the formula field to display the translated value in sobj
     * @param  formulaField_targetFieldToTranslate  the field to be used in translation
     * @param  sourceRecordsTranslations            the translation record for cloned records
     * @param  sourceRecordsTranslationMaps         the translation map record for cloned records
     * @param  translationMappingWrapperList        list of the translation mapping wrapper 
     */
    private void createTranslationMapAndTranslation(List<SObject> objList, Map<String, String> tlnFieldsName_targetFieldToTranslate, String tlmFieldNameInSObject, List<REDU_TranslationManager.TranslationMapping> sobjTranslationFormulaFields, Map<String, String> formulaField_targetFieldToTranslate, Map<String, reduivy__Translation__c> sourceRecordsTranslations, Map<Id, reduivy__Translation_Map__c> sourceRecordsTranslationMaps, List<REDU_TranslationManager.TranslationMapping> translationMappingWrapperList) {

        List<Map<String, reduivy__Translation__c>> translationsBySobj = TLN_Helper.generateTranslationRecords(objList, sobjTranslationFormulaFields, formulaField_targetFieldToTranslate, sourceRecordsTranslations, translationMappingWrapperList);

        //insert tln
        if(!translationsBySobj.isEmpty()) {
            List<reduivy__Translation__c> translationInsertList = new List<reduivy__Translation__c>();
            for (Map<String, reduivy__Translation__c> translations : translationsBySobj) {
                translationInsertList.addAll(translations.values());
            }

            //we won't handle partial success here due to complexity of child records
            REDU_Database_UTIL.doInsert(translationInsertList);
        
            //insert tlm
            List<reduivy__Translation_Map__c> translationMapInsertList = TLM_Helper.generateTranslationMapRecords(objList, translationsBySobj, tlnFieldsName_targetFieldToTranslate, sourceRecordsTranslationMaps);
            
            if(!translationMapInsertList.isEmpty()) {
                REDU_Database_UTIL.doInsert(translationMapInsertList);
                
                Integer counter = 0;
                for(SObject sobj : objList) {
                    sobj.put(tlmFieldNameInSObject, translationMapInsertList.get(counter).Id);

                    counter ++;
                }
            }
        }
    }

    /**
     * @description get the source records of the cloned records
     * @param  newRecords           all the new records
     * @param  tlmFieldName         
     * @param  tlmFieldRelationship the relationship name of the tlm field in sobject (reduivy__Translation_Map__r)
     * @param  tlnFieldsNameAndRelationshipInTlm the relationship name of the tln field in tlm (reduivy__Translation_1__r)
     * @return                      Map of source record id and source record
     */
    private static Map<Id, SObject> getCloneSourceRecords(List<SObject> newRecords, String tlmFieldName, String tlmFieldRelationship, Map<String, String> tlnFieldsNameAndRelationshipInTlm) {
        Map<Id, SObject> sourceRecordsMap = new Map<Id, SObject>();
        Set<Id> sourceRecordsIds = new Set<Id>();

        //get the source id of the cloned record if any
        for(SObject newRecord : newRecords) {
            if(newRecord.isClone() && String.isNotBlank(newRecord.getCloneSourceId())) {
                sourceRecordsIds.add(newRecord.getCloneSourceId());
            } 
        }
        REDU_Logging_UTIL.debugJsonString('sourceRecordsIds', sourceRecordsIds);

        if(sourceRecordsIds.isEmpty()) {
            //if there is no any, return empty map
            return sourceRecordsMap;
        }

        //get the fields for reduivy__Translation__c
        Map<String, Schema.SObjectField> tlnFieldsMap = SObjectType.reduivy__Translation__c.fields.getMap();

        //compile a list of reduivy__Translation__c object fields to be queried for cloning
        Set<String> fieldsToQuery = new Set<String>();
        for(Schema.SObjectField field : tlnFieldsMap.values())  {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

            if(fieldDescribe.getName() == 'Id' ||
                fieldDescribe.getName() == 'Name' ||
                (fieldDescribe.isCustom() && !fieldDescribe.isCalculated() && !FIELDS_DO_NOT_CLONE.contains(fieldDescribe.getName()))
            ) {
                for(String tlnRelField : tlnFieldsNameAndRelationshipInTlm.values()) {
                    fieldsToQuery.add(getTranslationFieldPath(tlmFieldRelationship, tlnRelField, fieldDescribe.getName()));
                }
            }
        }

        //query all the language fields
        String sourceRecordSoql = 'SELECT ' + String.join(fieldsToQuery, ', ') 
        + ' FROM ' + newRecords.getSObjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getName()
        + ' WHERE Id IN :sourceRecordsId'
        + ' AND ' + tlmFieldName + ' != null';

        REDU_Logging_UTIL.debug('sourceRecordSoql', sourceRecordSoql);

        Map<String, Object> sourceRecordBindParams = new Map<String, Object>{
            'sourceRecordsId' => sourceRecordsIds
        };

        for(SObject sourceRecord : Database.queryWithBinds(sourceRecordSoql, sourceRecordBindParams, AccessLevel.USER_MODE)){
            sourceRecordsMap.put(sourceRecord.Id, sourceRecord);
        }

        return sourceRecordsMap;
    }

    /**
     * @description create cloned translation records to be linked to the cloned records in the helper class
     * @param  sourceRecords                                  The source records
     * @param  tlmRelField                                    Translation Map field relationship name used in sobject
     * @param  tlnFieldsNameAndRelationshipInTlm              Translation field relationship name used in translation map
     * @param  tlnFieldRelationship_targetFieldToTranslate map of tlnFieldRelationship name to target field to translate (e.g. 'reduivy__Translation_1__r' => 'Name')
     * @return                                                cloned translation records, key is the source record id and target field to translate (e.g. 'a0rBo00000OvM1XIAV_Name')
     */
    private static Map<String, reduivy__Translation__c> getCloneSourceRecordsTranslations(List<SObject> sourceRecords, String tlmRelField, Map<String, String> tlnFieldsNameAndRelationshipInTlm, Map<String, String> tlnFieldRelationship_targetFieldToTranslate) {
        Map<String, reduivy__Translation__c> sourceRecordsTranslation = new Map<String, reduivy__Translation__c>();

        for(SObject sobj : sourceRecords) {
            //if there is no translation map in source object field, we skip the source object
            reduivy__Translation_Map__c tlm = (reduivy__Translation_Map__c) sobj.getSObject(tlmRelField);
            if(tlm == null) {
                continue;
            }

            for(String tlnRelField : tlnFieldsNameAndRelationshipInTlm.values()) {

                reduivy__Translation__c tln = (reduivy__Translation__c) tlm.getSObject(tlnRelField);
                if(tln == null) {
                    continue;
                }

                String key = sobj.Id + '_' + tlnFieldRelationship_targetFieldToTranslate.get(tlnRelField);
                sourceRecordsTranslation.put(key, tln);
                
            }
        }

        return sourceRecordsTranslation;
    }

    /**
     * @description create cloned translation map records to be linked to the cloned records in the helper class
     * @param  sourceRecords The source records
     * @param  tlmRelField  Translation Map field relationship name used in sobject
     * @return               cloned translation map records, key is the source record id
     */ 
    private static Map<Id, reduivy__Translation_Map__c> getCloneSourceRecordsTranslationMaps(List<SObject> sourceRecords, String tlmRelField) {
        Map<Id, reduivy__Translation_Map__c> sourceRecordsTranslationMap = new Map<Id, reduivy__Translation_Map__c>();

        for(SObject sobj : sourceRecords) {
            //if there is no translation map in source object field, we skip the source object
            reduivy__Translation_Map__c tlm = (reduivy__Translation_Map__c) sobj.getSObject(tlmRelField);
            if(tlm == null) {
                continue;
            }

            sourceRecordsTranslationMap.put(sobj.Id, tlm);
        }

        return sourceRecordsTranslationMap;
    }

    /**
     * @description get the field path of the Translation field from the sobject to query it
     * @param  tlmFieldName the relationship name of the tlm field in sobject (reduivy__Translation_Map__r)
     * @param  tlnFieldPath the relationship name of the tln field in tlm (reduivy__Translation_1__r)
     * @param  fieldName    translation field name (reduivy__es__c)
     * @return              return joined translation field path (reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__es__c)
     */
    private static String getTranslationFieldPath(String tlmFieldName, String tlnFieldPath, String fieldName) {
        return tlmFieldName + '.' + tlnFieldPath + '.' + fieldName;
    }
}