/**
 * @author      WDCi (Sueanne)
 * @date        Sept 2024
 * @group       Enrollment wizard
 * @description Controller to handle study session enrollment needed data
 * @changehistory
 * ISS-002050 17-09-2024 Sueanne - new class
 */
public with sharing class REDU_IpePathwayStudySessions_LCTRL {
    
    /**
     * @description Find the related study sessions
     * @param studyOfferingId
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudySessions(Id studyOfferingId){

        try{
            if(String.isBlank(studyOfferingId)){
                throw new REDU_ApplicationException(Label.Error_Contact_Admin);
            }

            String sseTranslationName = SSE_Helper.getTranslationFieldNameForName();

            Set<String> fieldsToQuery = new Set<String>{
                'Id', 
                'Name', 
                'reduivy__Start_Date_Calculated__c',
                sseTranslationName
            };

            String soqlQuery = 'SELECT ' + String.join(fieldsToQuery, ', ')
                            + ' FROM reduivy__Study_Session__c'
                            + ' WHERE reduivy__Study_Offering__c = :studyOfferingId';

            Map<String, Object> bindMap = new Map<String, Object>{
                'studyOfferingId' => studyOfferingId
            };
            //find study sessions
            List<reduivy__Study_Session__c> sseList = new List<reduivy__Study_Session__c>();
            for(reduivy__Study_Session__c sse : (List<reduivy__Study_Session__c>) Database.queryWithBinds(soqlQuery, bindMap, AccessLevel.USER_MODE)) {
                sseList.add(sse);
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(sseList));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}