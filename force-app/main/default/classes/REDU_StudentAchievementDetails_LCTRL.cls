/**
 * @author      WDCi (XW)
 * @date        Dec 2025
 * @group       Student Achievement
 * @description 
 * @changehistory
 * ISS-002633 16-12-2025 XW - new class
 */

public with sharing class REDU_StudentAchievementDetails_LCTRL {

    /**
     * @description to get the individual achievement record based on its id
     * @param  individualAchievementId    individualAchievement id
     * @param  language language
     * @return          REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualAchievementRecord(String individualAchievementId, String language){

        try {

            Map<String, Object> responseData = new Map<String, Object>();
            if(String.isBlank(language)) {
                language = UserInfo.getLanguage();
            }
            if(String.isNotBlank(individualAchievementId)) {
                List<reduivy__Individual_Achievement__c> individualAchievementList;

                Set<String> individualAchievementFields = new Set<String> { 
                    'Id',
                    'Name',
                    'reduivy__Type__c',
                    'reduivy__Details__c',
                    'reduivy__Verification_Status__c',
                    'reduivy__Agreement__c',
                    'reduivy__Agreement__r.reduivy__Educational_Institution__c',
                    'reduivy__Agreement__r.reduivy__Educational_Institution__r.Name',
                    'reduivy__Agreement__r.reduivy__External_Educational_Institution__r.Name',
                    'reduivy__Department__c',
                    'reduivy__Department__r.Name',
                    'reduivy__Agreement_Recognition__c',
                    'reduivy__Agreement_Recognition__r.reduivy__Agreement__r.Name',
                    'reduivy__Agreement_Recognition__r.Name',
                    'reduivy__Submission_Date__c'
                };

                if(REDU_Metadata_UTIL.describeSObject(IAC_Helper.getApiName()).getRecordTypeInfos().size() > 1) {
                    individualAchievementFields.add('RecordTypeId');
                }

                individualAchievementFields.addAll(IAC_Helper.getIacReferencedFields());
                

                if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()) {
                    Map<String, Object> translationInfo = REDU_TranslationManager.getTranslationInfo(IAC_Helper.getApiName(), new Set<Id> {individualAchievementId}, individualAchievementFields, language);
                    individualAchievementList = (List<reduivy__Individual_Achievement__c>) translationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
                    responseData.put(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM, translationInfo);
                } else {
                    Set<String> individualAchievementQueryFields = new Set<String>();
                    
                    Schema.SObjectType rootSObjectType = REDU_Metadata_UTIL.getSObjectType(IAC_Helper.getApiName());
                    for (String field : individualAchievementFields) {
                        Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, rootSObjectType);
                        individualAchievementQueryFields.add(field);

                        if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                            String refField = REDU_Metadata_UTIL.getReferenceFieldForQuery(field, true);
                            individualAchievementQueryFields.add(refField);
                        } else if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                            individualAchievementQueryFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
                        }
                    }

                    String individualAchievementQuery = 'SELECT ' + String.join(individualAchievementQueryFields, ', ')
                                   + ' FROM ' + IAC_Helper.getApiName()
                                   + ' WHERE Id = :individualAchievementId'
                                   + ' LIMIT 1';
                    
                    Map<String, Object> individualAchievementBindMap = new Map<String, Object>{
                        'individualAchievementId' => individualAchievementId
                    };

                    individualAchievementList = new List<reduivy__Individual_Achievement__c>();

                    REDU_Logging_UTIL.debug('individualAchievementQuery', individualAchievementQuery);
                    for(reduivy__Individual_Achievement__c individualAchievement : (List<reduivy__Individual_Achievement__c>) Database.queryWithBinds(individualAchievementQuery, individualAchievementBindMap, AccessLevel.USER_MODE)) {
                        individualAchievementList.add(individualAchievement);
                    }

                }
                responseData.put('individualAchievementRecord', individualAchievementList.isEmpty() ? null : individualAchievementList[0]);
                responseData.put('externalEducationalInstitutionRecordTypeId', ACC_Helper.getExternalEducationalInstitutionRecordTypeId());
                responseData.put('departmentRecordTypeId', ACC_Helper.getDepartmentRecordTypeId());
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));

        } catch (QueryException qex) {
            REDU_Logging_UTIL.debug(qex);

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, false);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);

            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

}
