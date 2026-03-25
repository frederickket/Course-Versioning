/**
 * @Author 		WDCi (Jordan)
 * @Date 		Nov 2024
 * @group 		Study Plan Cloning
 * @Description Study plan cloning wizard
 * @changehistory
 * ISS-002153 13-11-2024 Jordan - new class
 * ISS-002230 22-01-2025 XW - get picklist value label if field type is picklist
 * ISS-002495 23-09-2025 XW - support translation for long text field
 * ISS-002736 25-11-2025 XiRouh - added enableWrapText param
 */
public with sharing class REDU_SplStudyPlanCloning_LCTRL {

    @TestVisible private static boolean testQueueJob = false;
    
    /**
     * @description Get the study plan data
     * @param studyPlanId Study plan record id
     * @param studyPlanEditableDetailsFieldSetName Field set name
     * @param studyPathwayListingTableFieldSetName Field set name
     * @param studyPlanOptionListingTableFieldSetName Field set name
     */
	@AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudyPlanData(String studyPlanId, String studyPlanEditableDetailsFieldSetName, String studyPathwayListingTableFieldSetName, String studyPlanOptionListingTableFieldSetName, String language, Boolean enableWrapText){

        try {

            language = String.isBlank(language) ? UserInfo.getLanguage() : language;
            List<REDU_DynamicFieldValue_OBJ> studyPlanFsmList = REDU_Metadata_UTIL.getFieldSetMembers(
                'reduivy__Study_Plan__c',
                studyPlanEditableDetailsFieldSetName
            );

            reduivy__Study_Plan__c studyPlanRecord = queryStudyPlanData(studyPlanId, studyPlanFsmList);
            Map<String, Object> studyPathwayList = getRelatedStudyPathwayData(studyPlanId, studyPathwayListingTableFieldSetName, language, enableWrapText);
            Map<String, Object> studyPlanOptionList = getRelatedStudyPlanOptionData(studyPlanId, studyPlanOptionListingTableFieldSetName, language, enableWrapText);

            Map<String, Object> responseJSON = new Map<String, Object>();
            
            responseJSON.put('studyPlan', studyPlanRecord);
            REDU_Logging_UTIL.debug('studyPlan :: ', studyPlanRecord);
            
            responseJSON.put('studyPlanName', studyPlanRecord.Name);
            REDU_Logging_UTIL.debug('studyPlanName :: ', studyPlanRecord.Name);

            if(!studyPathwayList.isEmpty()){
                responseJSON.put('studyPathwayList', JSON.serialize(studyPathwayList));
                REDU_Logging_UTIL.debug('studyPathwayList :: ', JSON.serialize(studyPathwayList));
            } else {
                responseJSON.put('studyPathwayList', '');
                REDU_Logging_UTIL.debug('studyPathwayList :: ', '');
            }

            if(!studyPlanOptionList.isEmpty()){
                responseJSON.put('studyPlanOptionList', JSON.serialize(studyPlanOptionList));
                REDU_Logging_UTIL.debug('studyPlanOptionList :: ', JSON.serialize(studyPlanOptionList));
            } else {
                responseJSON.put('studyPlanOptionList', '');
                REDU_Logging_UTIL.debug('studyPlanOptionList :: ', '');
            }
            
            responseJSON.put('columns', studyPlanFsmList);
            REDU_Logging_UTIL.debug('columns :: ', studyPlanFsmList);

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseJSON));
            return response;

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Query the study plan record
     * @param studyPlanId Study plan record id
     * @param studyPlanFsmList Study plan field set members
     */
    private static reduivy__Study_Plan__c queryStudyPlanData(String studyPlanId , List<REDU_DynamicFieldValue_OBJ> studyPlanFsmList) {
        Set<String> studyPlanFields = new Set<String>{'Id'};

        for(REDU_DynamicFieldValue_OBJ field : studyPlanFsmList) {
            studyPlanFields.add(field.fieldName);
        }

        Map<String, Object> studyPlanBindParams = new Map<String, Object>{
            'studyPlanId' => studyPlanId
        };

        String studyPlanQuery = 'SELECT ' + String.join(studyPlanFields, ',') +
            ' FROM reduivy__Study_Plan__c ' +
            ' WHERE Id =: studyPlanId ';

        List<reduivy__Study_Plan__c> studyPlanList = (List<reduivy__Study_Plan__c>) Database.queryWithBinds(studyPlanQuery, studyPlanBindParams, AccessLevel.USER_MODE);
        
        if(!studyPlanList.isEmpty()) {
            return studyPlanList[0];
        } else {
            return null;
        }
    }

    /**
     * @description Get the related study pathway data of the current study plan
     * @param studyPlanId Study plan record id
     * @param studyPathwayListingTableFieldSetName Field set name
     */
    private static Map<String, Object> getRelatedStudyPathwayData(String studyPlanId, String studyPathwayListingTableFieldSetName, String language, Boolean enableWrapText) {
        Map<String, Object> responseJSON = new Map<String, Object>();
        
        language = String.isBlank(language) ? UserInfo.getLanguage() : language;
        
        List<REDU_DynamicFieldValue_OBJ> studyPathwayFsmList = REDU_Metadata_UTIL.getFieldSetMembers(
            'reduivy__Study_Pathway__c',
            studyPathwayListingTableFieldSetName
        );

        Set<String> studyPathwayFields = new Set<String>{'Id'};
        Set<String> studyPathwayNonRefFields = new Set<String>{'Id'};

        for(REDU_DynamicFieldValue_OBJ field : studyPathwayFsmList) {
            studyPathwayFields.add(field.fieldName);
            studyPathwayNonRefFields.add(field.fieldName);

            if(field.displayType == Schema.DisplayType.REFERENCE.name()) {
                studyPathwayFields.add(REDU_Metadata_UTIL.getReferenceFieldForQuery(field.fieldName, true));
            } else if(field.displayType == Schema.DisplayType.PICKLIST.name() || field.displayType == Schema.DisplayType.MULTIPICKLIST.name()) {
                studyPathwayNonRefFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field.fieldName));
            }
        }

        Map<String, Object> studyPathwayBindParams = new Map<String, Object>{
            'studyPlanId' => studyPlanId
        };

        String studyPathwayQuery = 'SELECT ' + String.join(studyPathwayFields, ',') +
            ' FROM reduivy__Study_Pathway__c ' +
            ' WHERE reduivy__Study_Plan__c =: studyPlanId ';

        List<reduivy__Study_Pathway__c> studyPathwayList = (List<reduivy__Study_Pathway__c>) Database.queryWithBinds(studyPathwayQuery, studyPathwayBindParams, AccessLevel.USER_MODE);

        if(!studyPathwayList.isEmpty()) {
            responseJSON.put(REDU_Datatable_UTIL.RECORDS_PARAM, studyPathwayList);
            
            JSONGenerator tableColumnMetadata = JSON.createGenerator(true);
            REDU_Datatable_UTIL.generateTableColMetadata(tableColumnMetadata, SPW_Helper.getObjectType(), String.join(studyPathwayNonRefFields, ';'), false, null, true, '_self', false, enableWrapText);
            responseJSON.put(REDU_Datatable_UTIL.COLUMNS_PARAM, JSON.deserializeUntyped(tableColumnMetadata.getAsString()));
            
            JSONGenerator tableFieldRefMetadata = JSON.createGenerator(true);
            REDU_Datatable_UTIL.generateRefLinksMetadata(tableFieldRefMetadata, SPW_Helper.getObjectType(), String.join(studyPathwayNonRefFields, ';'));
            responseJSON.put(REDU_Datatable_UTIL.REFLINKS_PARAM, JSON.deserializeUntyped(tableFieldRefMetadata.getAsString()));

            responseJSON.put(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM, REDU_TranslationManager.getTranslationInfo(SPW_Helper.getApiName(), studyPathwayList, studyPathwayNonRefFields, language));
        }

        return responseJSON;
    }

    /**
     * @description Get the related study plan option data of the current study plan
     * @param studyPlanId Study plan record id
     * @param studyPlanOptionListingTableFieldSetName Field set name
     */
    private static Map<String, Object> getRelatedStudyPlanOptionData(String studyPlanId, String studyPlanOptionListingTableFieldSetName, String language, Boolean enableWrapText) {
        Map<String, Object> responseJSON = new Map<String, Object>();
        
        List<REDU_DynamicFieldValue_OBJ> studyPlanOptionFsmList = REDU_Metadata_UTIL.getFieldSetMembers(
            'reduivy__Study_Plan_Option__c',
            studyPlanOptionListingTableFieldSetName
        );

        Set<String> studyPlanOptionFields = new Set<String>{'Id'};
        Set<String> studyPlanOptionNonRefFields = new Set<String>{'Id'};

        for(REDU_DynamicFieldValue_OBJ field : studyPlanOptionFsmList) {
            studyPlanOptionFields.add(field.fieldName);
            studyPlanOptionNonRefFields.add(field.fieldName);

            if(field.displayType == Schema.DisplayType.REFERENCE.name()) {
                studyPlanOptionFields.add(REDU_Metadata_UTIL.getReferenceFieldForQuery(field.fieldName, true));
            } else if(field.displayType == Schema.DisplayType.PICKLIST.name() || field.displayType == Schema.DisplayType.MULTIPICKLIST.name()) {
                studyPlanOptionFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field.fieldName));
            }
        }

        Map<String, Object> studyPlanOptionBindParams = new Map<String, Object>{
            'studyPlanId' => studyPlanId
        };

        String studyPlanOptionQuery = 'SELECT ' + String.join(studyPlanOptionFields, ',') +
            ' FROM reduivy__Study_Plan_Option__c ' +
            ' WHERE reduivy__Master_Study_Plan__c =: studyPlanId ';

        List<reduivy__Study_Plan_Option__c> studyPlanOptionList = (List<reduivy__Study_Plan_Option__c>) Database.queryWithBinds(studyPlanOptionQuery, studyPlanOptionBindParams, AccessLevel.USER_MODE);

        if(!studyPlanOptionList.isEmpty()) {
            responseJSON.put(REDU_Datatable_UTIL.RECORDS_PARAM, studyPlanOptionList);
            
            JSONGenerator tableColumnMetadata = JSON.createGenerator(true);
            REDU_Datatable_UTIL.generateTableColMetadata(tableColumnMetadata, SPO_Helper.getObjectType(), String.join(studyPlanOptionNonRefFields, ';'), false, null, true, '_self', false, enableWrapText);
            responseJSON.put(REDU_Datatable_UTIL.COLUMNS_PARAM, JSON.deserializeUntyped(tableColumnMetadata.getAsString()));
            
            JSONGenerator tableFieldRefMetadata = JSON.createGenerator(true);
            REDU_Datatable_UTIL.generateRefLinksMetadata(tableFieldRefMetadata, SPO_Helper.getObjectType(), String.join(studyPlanOptionNonRefFields, ';'));
            responseJSON.put(REDU_Datatable_UTIL.REFLINKS_PARAM, JSON.deserializeUntyped(tableFieldRefMetadata.getAsString()));

            responseJSON.put(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM, REDU_TranslationManager.getTranslationInfo(SPO_Helper.getApiName(), studyPlanOptionList, studyPlanOptionNonRefFields, language));
        }

        return responseJSON;
    }

    /**
     * @description Method to be called to insert clone data from study plan clone wizard
     * @param studyPlanId
     * @param studyPlanData
     * @param studyPathwayArray
     * @param studyPlanOptionArray
     * @param includeExistingStudyPlanUnitRequirements
     * @param cloneChildStudyPlans
     */
    @AuraEnabled(cacheable=false)
    public static REDU_LightningResponse insertStudyPlanCloneData(String studyPlanId, String studyPlanData, List<Id> studyPathwayArray, List<Id> studyPlanOptionArray, Boolean includeExistingStudyPlanUnitRequirements, Boolean cloneChildStudyPlans) {
        Savepoint sp = Database.setSavepoint();
        try {

            if(System.isFuture() || System.isBatch() || System.isQueueable() || (Test.isRunningTest() && !testQueueJob )){
                REDU_StudyPlanCloning_QUEUE queueJob = new REDU_StudyPlanCloning_QUEUE(studyPlanId, studyPlanData, studyPathwayArray, studyPlanOptionArray, includeExistingStudyPlanUnitRequirements, cloneChildStudyPlans);
                queueJob.cloneStudyPlan();
            }else{
                REDU_StudyPlanCloning_QUEUE queueJob = new REDU_StudyPlanCloning_QUEUE(studyPlanId, studyPlanData, studyPathwayArray, studyPlanOptionArray, includeExistingStudyPlanUnitRequirements, cloneChildStudyPlans);
                System.enqueueJob(queueJob);
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, REDU_LightningResponse.SUCCESS);
            return response;
        } catch (QueryException qex) {
            Database.rollback(sp);
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            Database.rollback(sp);
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}