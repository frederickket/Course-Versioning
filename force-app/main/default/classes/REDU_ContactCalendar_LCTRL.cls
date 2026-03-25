/**
 * @Author 		WDCi (Sueanne)
 * @Date 		Aug 2024
 * @group 		Student and Faculty Calendar
 * @Description To get the study event for display in calendar
 * @changehistory
 * ISS-001925 05-08-2024 Sueanne - new class
 * ISS-002050 13-09-2024 Sueanne - move the logic of getContactEvents() to CON_Helper
 * ISS-002330 25-03-2025 XW - return translation name field name when returning study events
 */

public with sharing class REDU_ContactCalendar_LCTRL {

    private static final String STUDY_EVENT_PARAM = 'studyEvents';
    private static final String TRANSLATION_NAME_PARAM = 'translationNames';

    /**
     * @description Get calendar events for the current user or contact
     * @param contactId Optional contact id
     * @param fromDate The from datetime
     * @param toDate The to datetime
     * @param enrollmentStatuses the individual session enrollment's enrollment status
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getCalendarEvents(String recordId, Datetime fromDate, Datetime toDate, List<String> enrollmentStatuses){
        
        try {
            List<reduivy__Study_Event__c> studyEvents = CON_Helper.getContactEvents(recordId, fromDate, toDate, enrollmentStatuses);

            Map<String, Object> responseMap = new Map<String, Object>();
            responseMap.put(STUDY_EVENT_PARAM, studyEvents);

            Map<String, String> translationNamesMap = new Map<String, String> {
                'SEV' => SEV_Helper.getTranslationFieldNameForName(),
                'FAC' => FAC_Helper.getTranslationFieldNameForName()
            };

            responseMap.put(TRANSLATION_NAME_PARAM, translationNamesMap);
            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseMap));

            return response;
            
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

}