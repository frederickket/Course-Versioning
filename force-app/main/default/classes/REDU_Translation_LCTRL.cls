/**
 * @author      WDCi (Lean)
 * @date        Mar 2025
 * @group       Translation
 * @description Lightning controller for translation
 * @changehistory
 * ISS-002330 19-03-2025 name - new class
 * ISS-002495 17-09-2025 XW - move getTranslationFieldForName to UTIL class 
 */
public with sharing class REDU_Translation_LCTRL {

    /**
     * @description To search and return the translation field for name of an object based on the object prefix provided e.g., SUN = reduivy__Study_Unit__c
     * @param objectPrefixes List of object prefix
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getTranslationFieldForNameByObjPrefix(List<String> objectPrefixes){

        try {
            Map<String, Object> responseData = REDU_TranslationManager.getTranslationFieldForNameByObjPrefix(objectPrefixes);

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getTranslationInfo(String objectName, List<String> recordIds, List<String> fields, String language){
        try {
            
            Map<String, Object> responseData = REDU_TranslationManager.getTranslationInfo(objectName, recordIds, fields, language);

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));

        } catch (Exception exp) {
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}