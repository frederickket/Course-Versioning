/**
 * @author      WDCi (Sueanne)
 * @date        April 2024
 * @group       Study Pathway
 * @description Study pathway wizard
 * @changehistory
 * ISS-001917 02-04-2024 Sueanne - new class
 * ISS-002191 12-12-2024 XW - get communityInfo to generate url in js
 * ISS-002230 05-02-2025 XW - allow additional fields to be queried
 * ISS-002330 19-03-2025 XW - get translated study plan name if found
 */
public with sharing class REDU_StudyPathwayUnit_LCTRL {
    
    /**
     * @description get study pathway unit by its Id
     * @param studyPathwayUnitId 
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudyPathwayUnit(Id studyPathwayUnitId, List<String> additionalFields){
        reduivy__Study_Pathway_Unit__c spu = null;
        try{

            Set<String> fieldsToQuery = new Set<String> {
                'Id', 
                'reduivy__Applicable_Study_Plan__c', 
                'reduivy__Study_Pathway_Term__c', 
                'reduivy__Study_Unit__c', 
                'reduivy__Study_Unit__r.reduivy__Description__c', 
                'reduivy__Study_Unit__r.Name', 
                'reduivy__Number_of_Units_from_Group__c', 
                'reduivy__Study_Plan_Group__c',
                'reduivy__Study_Plan_Group__r.Name'
            };

            if(additionalFields != null && !additionalFields.isEmpty()) {
                fieldsToQuery.addAll(additionalFields);
            }
            String query = 'SELECT ' + String.join(fieldsToQuery, ', ') + ' FROM reduivy__Study_Pathway_Unit__c WHERE Id = :studyPathwayUnitId LIMIT 1';
            Map<String, Object> bindMap = new Map<String,Object> {
                'studyPathwayUnitId' => studyPathwayUnitId
            };
            spu = Database.queryWithBinds(query, bindMap, AccessLevel.USER_MODE);

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(spu));
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
     * @description get study unit by its Id
     * @param studyUnitId 
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudyUnit(Id studyUnitId){
        reduivy__Study_Unit__c studyUnit = null;
        try {
            studyUnit = [
                SELECT Id, Name, reduivy__Description__c
                FROM reduivy__Study_Unit__c
                WHERE Id = :studyUnitId
                WITH USER_MODE
                LIMIT 1
            ];
            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(studyUnit));
            return response;
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description get a map (contains required & optional study plan name) from study plan structure
     * @param studyPlanIdList 
     * @param studyUnitId
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudyPlanStructureList(List<Id> studyPlanIdList, Id studyUnitId){
        
        try {
            Set<String> requiredSp = new Set<String>();
            Set<String> optionalSp = new Set<String>();
            
            Set<String> fieldsToQuery = new Set<String> {
                'Id', 
                'Name', 
                'reduivy__Category__c', 
                'reduivy__Description__c', 
                'reduivy__Study_Plan__c', 
                'reduivy__Study_Plan__r.Name',
                'reduivy__Study_Unit__c'
            };

            String splTranslationNameFieldApiName = SPL_Helper.getTranslationFieldNameForName();

            String splTranslationNameFieldApiNameFromSps = 'reduivy__Study_Plan__r.' + splTranslationNameFieldApiName;
            fieldsToQuery.add(splTranslationNameFieldApiNameFromSps);
            
            String soqlQuery = 'SELECT ' + String.join(fieldsToQuery, ', ') 
                            + ' FROM ' + SPS_Helper.getApiName()
                            + ' WHERE reduivy__Study_Unit__c = :studyUnitId'
                            + ' AND reduivy__Study_Plan__c IN :studyPlanIdList'
                            + ' AND RecordTypeId =: unitRecordTypeId'
                            + ' ORDER BY ' + splTranslationNameFieldApiNameFromSps;

            Id unitRecordTypeId = SPS_Helper.getUnitRecordTypeId();
            Map<String, Object> bindMap = new Map<String, Object> {
                'studyUnitId' => studyUnitId,
                'studyPlanIdList' => studyPlanIdList,
                'unitRecordTypeId' => unitRecordTypeId
            };



            for (reduivy__Study_Plan_Structure__c sps: (List<reduivy__Study_Plan_Structure__c>) Database.queryWithBinds(soqlQuery, bindMap, AccessLevel.USER_MODE)) {
                if (sps.reduivy__Category__c == SPS_Helper.CATEGORY_REQUIRED) {
                    requiredSp.add((String) sps.reduivy__Study_Plan__r.get(splTranslationNameFieldApiName));
                } else {
                    optionalSp.add((String) sps.reduivy__Study_Plan__r.get(splTranslationNameFieldApiName));
                }
            }
            
            Map<String, Set<String>> responseData = new Map<String, Set<String>>();

            responseData.put('required', requiredSp);
            responseData.put('optional', optionalSp);
            
            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));
            return response;
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description gather the study pathway units that have same studyUnitId in same studyPathTermId
     * @param studyUnitId 
     * @param studyPathTermId
     * @param selectedDefaultSpList selected + default study plan id
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getRelatedSpuList(Id studyUnitId, Id studyPathTermId, List<Id> selectedDefaultSpList){
        try{
            Set<String> fieldsToQuery = new Set<String> {
                'Id', 
                'reduivy__Study_Unit__c', 
                'reduivy__Applicable_Study_Plan__c',
                'reduivy__Applicable_Study_Plan__r.Name'
            };
            
            String splTranslatedName = SPL_Helper.getTranslationFieldNameForName();
            fieldsToQuery.add('reduivy__Applicable_Study_Plan__r.' + splTranslatedName);
            
            String soqlQuery = 'SELECT ' + String.join(fieldsToQuery, ', ')
                            + ' FROM reduivy__Study_Pathway_Unit__c'
                            + ' WHERE reduivy__Study_Pathway_Term__c = :studyPathTermId'
                            + ' AND reduivy__Study_Unit__c = :studyUnitId'
                            + ' AND (reduivy__Applicable_Study_Plan__c IN :selectedDefaultSpList'
                            + ' OR reduivy__Applicable_Study_Plan__c = NULL)';
            Map<String, Object> bindMap = new Map<String, Object>{
                'studyPathTermId' => studyPathTermId,
                'studyUnitId' => studyUnitId,
                'selectedDefaultSpList' => selectedDefaultSpList
            };

            List<reduivy__Study_Pathway_Unit__c> spuList = new List<reduivy__Study_Pathway_Unit__c>();
            
            for(reduivy__Study_Pathway_Unit__c spu : (List<reduivy__Study_Pathway_Unit__c>) Database.queryWithBinds(soqlQuery, bindMap, AccessLevel.USER_MODE)) {
                spuList.add(spu);
            }
            
            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(spuList));
            return response;
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * ISS-002191
     * @description getCommunityInfo description
     * @return   return description
     */ 
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getCommunityInfo(){
        try {
            return new REDU_LightningResponse(true, 'success', JSON.serialize(ORG_Helper.getCommunityInfo()));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}