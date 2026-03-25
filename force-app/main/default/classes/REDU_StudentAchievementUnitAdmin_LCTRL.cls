/**
 * @author      WDCi (XW)
 * @date        Jan 2026
 * @group       
 * @description 
 * @changehistory
 * ISS-002633 09-01-2025 XW - new class
 */

public with sharing class REDU_StudentAchievementUnitAdmin_LCTRL {

    /**
     * @description get the agreement recognition unit that is linked to the individual achievement unit
     * @param  aruId    aruId agreement Recognition unit id
     * @param  language language the language used by the user
     * @return          REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getAgreementRecognitionUnit(String aruId, String language){

        try {

            Map<String, Object> responseData = new Map<String, Object>();
            if(String.isBlank(language)) {
                language = UserInfo.getLanguage();
            }
            if(String.isNotBlank(aruId)) {
                Set<String> aruFields = new Set<String> {
                    'Id',
                    'Name'
                };
                aruFields.add(ARU_Helper.getTranslationFieldNameForName());


                if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()) {   
                    Map<String, Object> translationInfo = REDU_TranslationManager.getTranslationInfo(ARU_Helper.getApiName(), new Set<Id> {aruId}, aruFields, language);
                    responseData.put(REDU_TranslationManager.RECORDS_PARAM, translationInfo.get(REDU_TranslationManager.RECORDS_PARAM));
                    responseData.put(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM, translationInfo);
                } else {
                    Map<String, Object> aruBindMap = new Map<String, Object> {
                        'aruId' => aruId
                    };
                    String aruSoql = 'SELECT ' + String.join(aruFields, ', ')
                                + ' FROM ' + ARU_Helper.getApiName()
                                + ' WHERE Id = :aruId';
                    List<reduivy__Agreement_Recognition_Unit__c> aruList = new List<reduivy__Agreement_Recognition_Unit__c>();
                    for(reduivy__Agreement_Recognition_Unit__c aru : (List<reduivy__Agreement_Recognition_Unit__c>) Database.queryWithBinds(aruSoql, aruBindMap, AccessLevel.USER_MODE)) {
                        aruList.add(aru);
                    }

                    responseData.put(REDU_TranslationManager.RECORDS_PARAM, aruList);
                }
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
    
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getExistingUploadedFiles(List<Id> recordIds){
        try {
            Map<Id, List<ContentDocument>> result = REDU_StudentAchievementUnit_LCTRL.getExistingUploadedFiles(new Set<Id>(recordIds));
            return new REDU_LightningResponse(true, 'success', JSON.serialize(result));
            
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);

            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualRequirementWrappers(String individualAchievementUnitId){
        try {
            Map<Id, REDU_RequirementChecklist_LCTRL.RequirementWrapper> irqWrapperMap = new Map<Id, REDU_RequirementChecklist_LCTRL.RequirementWrapper>();
            if(String.isNotBlank(individualAchievementUnitId)) {
                List<reduivy.REDU_RequirementChecklist_LCTRL.RequirementWrapper> irqWrapperList = REDU_StudentAchievementUnit_LCTRL.getIndividualRequirement(Id.valueOf(individualAchievementUnitId), IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN);

                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper irqWrapper : irqWrapperList) {
                    irqWrapperMap.put(irqWrapper.irq.Id, irqWrapper);
                }
            }
            return new REDU_LightningResponse(true, 'success', JSON.serialize(irqWrapperMap));

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
