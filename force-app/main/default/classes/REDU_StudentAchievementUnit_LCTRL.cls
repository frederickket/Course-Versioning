/**
 * @author      WDCi (XW)
 * @date        Jan 2026
 * @group       Student Achievement
 * @description 
 * @changehistory
 * ISS-002633 26-01-2026 XW - new class
 */

public with sharing class REDU_StudentAchievementUnit_LCTRL {

    /**
     * @description The description
     * @param param The description
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualAchievementUnit(String individualAchievementUnitId, List<String> additionalFields, String userMode, String unitTableFields, String language){

        try {
            Map<String, Object> responseData = new Map<String, Object>();

            if(String.isNotBlank(individualAchievementUnitId)) {

                if(String.isBlank(language)){
                    language = UserInfo.getLanguage();
                }
                Set<String> individualAchievementUnitFields = new Set<String>{'Id',
                    'Name',
                    'reduivy__Verification_Status__c',
                    'reduivy__Agreement_Recognition_Unit__r.Name',
                    'reduivy__Agreement_Recognition_Unit__r.reduivy__Unit_Code__c',
                    'reduivy__Individual_Achievement__c',
                    'reduivy__Individual_Achievement__r.reduivy__Verification_Status__c',
                    'reduivy__Individual_Achievement__r.Name'
                };

                if(additionalFields != null && !additionalFields.isEmpty()) {
                    individualAchievementUnitFields.addAll(additionalFields);
                }
                if(String.isNotBlank(unitTableFields)) {
                    individualAchievementUnitFields.addAll(unitTableFields.split(REDU_List_UTIL.DELIMITER));
                }

                Set<String> individualAchievementUnitReferencedFields = IAC_Helper.getIauReferencedFields();
                if(individualAchievementUnitReferencedFields != null && !individualAchievementUnitReferencedFields.isEmpty()) {
                    individualAchievementUnitFields.addAll(individualAchievementUnitReferencedFields);
                }

                Set<String> individualAchievementUnitQueryFields = new Set<String>();
                Schema.SObjectType individualAchievementUnitSObjectType = Schema.SObjectType.reduivy__Individual_Achievement_Unit__c.getSObjectType();
                
                for(String individualAchievementUnitField : individualAchievementUnitFields) {
                    Schema.DescribeFieldResult field = REDU_Datatable_UTIL.getFieldDescribe(individualAchievementUnitField, individualAchievementUnitSObjectType);
                    individualAchievementUnitQueryFields.add(individualAchievementUnitField);

                    if(field.getType() == Schema.DisplayType.REFERENCE) {
                        individualAchievementUnitQueryFields.add(REDU_Metadata_UTIL.getReferenceFieldForQuery(individualAchievementUnitField, true));
                    } else if(field.getType() == Schema.DisplayType.PICKLIST || field.getType() == Schema.DisplayType.MULTIPICKLIST) {
                        individualAchievementUnitQueryFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(individualAchievementUnitField));
                    }
                }
                
                String individualAchievementUnitQuery = 'SELECT ' + String.join(individualAchievementUnitQueryFields, ', ')
                            + ' FROM ' + IAU_Helper.getApiName()
                            + ' WHERE Id = :individualAchievementUnitId';

                Map<String, Object> individualAchievementUnitBindMap = new Map<String, Object>{
                    'individualAchievementUnitId' => individualAchievementUnitId
                };

                List<reduivy__Individual_Achievement_Unit__c> individualAchievementUnitList = new List<reduivy__Individual_Achievement_Unit__c>();
                Set<Id> individualAchievementUnitIdSet = new Set<Id>();

                REDU_Logging_UTIL.debug('individualAchievementUnitQuery', individualAchievementUnitQuery);
                for(reduivy__Individual_Achievement_Unit__c individualAchievementUnit : (List<reduivy__Individual_Achievement_Unit__c>) Database.queryWithBinds(individualAchievementUnitQuery, individualAchievementUnitBindMap, AccessLevel.USER_MODE))  {
                    individualAchievementUnitList.add(individualAchievementUnit);
                }

                List<REDU_RequirementChecklist_LCTRL.RequirementWrapper> irqWrapperList = getIndividualRequirement(individualAchievementUnitId, userMode);
                Set<Id> irqIdSet = new Set<Id>();
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper irqWrapper : irqWrapperList) {
                    irqIdSet.add(irqWrapper.irq.Id);
                }

                responseData.put('individualAchievementUnitRecord', individualAchievementUnitList.isEmpty() ? null : individualAchievementUnitList.get(0));
                responseData.put('irqWrapperList', getIndividualRequirement(individualAchievementUnitId, userMode));
                responseData.put(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM, REDU_TranslationManager.getTranslationInfo(IAU_Helper.getApiName(), individualAchievementUnitList, individualAchievementUnitFields, language));
                responseData.put('existingFiles', getExistingUploadedFiles(irqIdSet));
                responseData.put('unitTableFields', REDU_StudentAchievementUnitTable_LCTRL.getUnitTableFieldsInfo(unitTableFields));
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

    
    public static List<REDU_RequirementChecklist_LCTRL.RequirementWrapper> getIndividualRequirement(Id individualAchievementUnitId, String userMode) {
        String lookupFieldName = REDU_Metadata_UTIL.getObjectLookupField(IRS_Helper.getApiName(), IAU_Helper.getApiName());
        
        Set<String> irqFields = new Set<String> {
            'Id',
            'Name',
            'reduivy__Review_Status__c',
            'reduivy__Submission_Status__c',
            'reduivy__Individual_Requirement_Set__r.Id',
            'reduivy__Individual_Requirement_Set__r.Name',
            'reduivy__Individual_Requirement_Set__r.' + lookupFieldName
        };

        Set<String> userModeSet = new Set<String>{IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT};
        if(userMode == IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN) {
            userModeSet.add(IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY);
            userModeSet.add(IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN);
        }

        Map<String, Object> irqBindMap = new Map<String, Object> {
            'individualAchievementUnitId' => individualAchievementUnitId, 
            'userMode' => userModeSet
        };

        String irqQuery = 'SELECT ' + String.join(irqFields, ', ')
                       + ' FROM ' + IRQ_Helper.getApiName()
                       + ' WHERE reduivy__Individual_Requirement_Set__r.' + lookupFieldName + ' = :individualAchievementUnitId'
                       + ' AND reduivy__Requirement_Visibility__c IN :userMode'
                       + ' ORDER BY reduivy__Sequence__c';


        List<REDU_RequirementChecklist_LCTRL.RequirementWrapper> irqList = new List<REDU_RequirementChecklist_LCTRL.RequirementWrapper>();
        for(reduivy__Individual_Requirement__c irq : (List<reduivy__Individual_Requirement__c>) Database.queryWithBinds(irqQuery, irqBindMap, AccessLevel.USER_MODE)) {

            Map<String, Object> irqInfo = REDU_RequirementChecklist_LCTRL.getRequirementInfo(irq);
            String reviewStatusType = String.valueOf(irqInfo.get('reviewStatusType'));
            String submissionStatusType = String.valueOf(irqInfo.get('submissionStatusType'));

            REDU_RequirementChecklist_LCTRL.RequirementWrapper reqWrapper = new REDU_RequirementChecklist_LCTRL.RequirementWrapper(irq, reviewStatusType, submissionStatusType);

            irqList.add(reqWrapper);
        }

        return irqList;
    }
    
    /**
     * @description get the uploaded files of the records
     * @param recordId record ids
     * @return REDU_LightningResponse
     */
    public static Map<Id, List<ContentDocument>> getExistingUploadedFiles(Set<Id> recordIds){

        try {
            Map<Id, List<ContentDocument>> recordIdToCdMap = new Map<Id, List<ContentDocument>>();
            Set<String> insertedExistingFiles = new Set<String>();

            if(recordIds != null && !recordIds.isEmpty()) {
                Set<Id> contentDocumentIds = new Set<Id>();
                Map<Id, Set<Id>> cdIdToRecordIdMap = new Map<Id, Set<Id>>();
                for (ContentDocumentLink cdLink : [
                    SELECT Id, ContentDocumentId, LinkedEntityId, ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.LatestPublishedVersionId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId IN: recordIds
                    WITH USER_MODE
                ]) {
                    if (String.isNotBlank(cdLink.ContentDocumentId)) {

                        if(!recordIdToCdMap.containsKey(cdLink.LinkedEntityId)) {
                            recordIdToCdMap.put(cdLink.LinkedEntityId, new List<ContentDocument>());
                        }
                        recordIdToCdMap.get(cdLink.LinkedEntityId).add(cdLink.ContentDocument);
                    }
                }
            }
            return recordIdToCdMap;


        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}
