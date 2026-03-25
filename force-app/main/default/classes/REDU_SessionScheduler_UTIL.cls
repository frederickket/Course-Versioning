/**
 * @author      WDCi (XW)
 * @date        Feb 2025
 * @group       Session Management
 * @description Study session scheduler shared methods
 * @changehistory
 * ISS-002269 13-02-2025 XW - new shared method
 */
public inherited sharing class REDU_SessionScheduler_UTIL {
    
    /**
     * @description Return list of study sessions based on the filter criteria
     * @param fromDate
     * @param toDate
     * @param filterValue
     * @param defaultCriteria
     * @param sseAddonFields
     * @param studySessionGroupByFields
     */
    public static List<reduivy__Study_Session__c> getStudySessionsByFilter(Datetime fromDate, Datetime toDate, REDU_SessionFilterValue_OBJ filterValue, String defaultCriteria, List<String> sseAddonFields, List<String> studySessionGroupByFields) {
        
        REDU_Logging_UTIL.debugJsonString('filterValue', filterValue);

        String educationalInstitutionId = filterValue?.educationalInstitutionId;
        String campusId = filterValue?.campusId;
        String academicTermId = filterValue?.academicTermId;
        String studyUnitId = filterValue?.studyUnitId;
        String studyOfferingId = filterValue?.studyOfferingId;

        Set<String> sstFields = new Set<String>{
            'Id',
            'reduivy__Study_Session__c',
            'reduivy__Start_Date_Calculated__c',
            'reduivy__End_Date_Calculated__c'
        };

        Set<String> sstQueryBinders = new Set<String>();
        Map<String, Object> sstBindParams = new Map<String, Object>();
        //we will query the session based on timeline date range
        sstBindParams.put('sessionFromDate', fromDate.date());
        sstBindParams.put('sessionToDate', toDate.date());

        sstQueryBinders.add('reduivy__Start_Date_Calculated__c <: sessionToDate');
        sstQueryBinders.add('reduivy__End_Date_Calculated__c >=: sessionFromDate');

        //picklist filters
        if( String.isNotBlank(educationalInstitutionId) || String.isNotBlank(campusId) || String.isNotBlank(academicTermId) || String.isNotBlank(studyUnitId) || String.isNotBlank(studyOfferingId) ){
            
            if(String.isNotBlank(educationalInstitutionId)){
                sstBindParams.put('educationalInstitutionId', educationalInstitutionId);
                sstQueryBinders.add('reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__r.ParentId =: educationalInstitutionId');
            }

            if(String.isNotBlank(campusId)){
                sstBindParams.put('campusId', campusId);
                sstQueryBinders.add('reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__c =: campusId');
            }

            if(String.isNotBlank(academicTermId)){
                sstBindParams.put('academicTermId', academicTermId);
                sstQueryBinders.add('reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Academic_Term__c =: academicTermId');
            }

            if(String.isNotBlank(studyUnitId)){
                sstBindParams.put('studyUnitId', studyUnitId);
                sstQueryBinders.add('reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c =: studyUnitId');
            }

            if(String.isNotBlank(studyOfferingId)){
                sstBindParams.put('studyOfferingId', studyOfferingId);
                sstQueryBinders.add('reduivy__Study_Session__r.reduivy__Study_Offering__c =: studyOfferingId');
            }
        }

        String sstSoql = 'SELECT ' + String.join(sstFields, ', ') + 
            ' FROM reduivy__Study_Session_Time__c ';
        
        if (!sstQueryBinders.isEmpty()) {
            sstSoql += ' WHERE ' + String.join(sstQueryBinders, ' AND ');
        }
        
        Set<Id> sseIds = new Set<Id>();
        for (reduivy__Study_Session_Time__c sst : (List<reduivy__Study_Session_Time__c>) Database.queryWithBinds(sstSoql, sstBindParams, AccessLevel.USER_MODE)) {
            sseIds.add(sst.reduivy__Study_Session__c);
        }

        List<reduivy__Study_Session__c> sessions = new List<reduivy__Study_Session__c>();

        if (!sseIds.isEmpty()) {

            Set<String> sseFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Background_Colour__c',
                'reduivy__Text_Colour__c',
                'reduivy__Start_Date__c',
                'reduivy__End_Date__c',
                'reduivy__Required_Facility_Type__c',
                'reduivy__Status__c',
                'reduivy__Study_Event_Generation_Status__c',
                'reduivy__Study_Offering__c',
                'reduivy__Study_Offering__r.reduivy__Campus__c',
                'reduivy__Study_Offering__r.reduivy__Campus__r.ParentId'
            };

            if (sseAddonFields != null && !sseAddonFields.isEmpty()) {
                sseFields.addAll(sseAddonFields);
            }

            if (studySessionGroupByFields != null && !studySessionGroupByFields.isEmpty()) {
                sseFields.addAll(studySessionGroupByFields);

                for (String groupByField : studySessionGroupByFields) {
                    //get the display name if it is reference (lookup)
                    Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(groupByField, reduivy__Study_Session__c.sObjectType);
                    if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE){
                        sseFields.add(REDU_Metadata_UTIL.getReferenceFieldForQuery(groupByField, true));
                    }
                }
                
            }

            Set<String> addonPicklistLabelFields = new Set<String>();
            Schema.SObjectType rootSObjectType = reduivy__Study_Session__c.sObjectType;
            for(String field : sseFields) {
                Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, rootSObjectType);
                if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                    addonPicklistLabelFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
                }
            }

            sseFields.addAll(addonPicklistLabelFields);

            Map<String, Object> sessionBindParams = filterValue.getSessionBindParams();
            List<String> sessionQueryBinders = filterValue.getSessionQueryBinders();
            
            sessionBindParams.put('sseIds', sseIds);
            sessionQueryBinders.add('Id IN: sseIds');

            String sessionSoql = 'SELECT ' + String.join(sseFields, ', ') +
                ' FROM reduivy__Study_Session__c ';

            if (String.isNotBlank(defaultCriteria) || !sessionQueryBinders.isEmpty()) {
                sessionSoql += ' WHERE ';

                if (String.isNotBlank(defaultCriteria)) {
                    sessionQueryBinders.add(defaultCriteria);
                }

                if (!sessionQueryBinders.isEmpty()) {
                    sessionSoql += String.join(sessionQueryBinders, ' AND ');
                }
            }

            sessionSoql += ' ORDER BY reduivy__Study_Offering__r.reduivy__Study_Unit__r.Name, Name';

            REDU_Logging_UTIL.debug('sessionBindParams', sessionBindParams);
            REDU_Logging_UTIL.debug('sessionSoql', sessionSoql);

            for (reduivy__Study_Session__c session : (List<reduivy__Study_Session__c>) Database.queryWithBinds(sessionSoql, sessionBindParams, AccessLevel.USER_MODE)) {
                sessions.add(session);
            }
        }

        return sessions;
    }
}