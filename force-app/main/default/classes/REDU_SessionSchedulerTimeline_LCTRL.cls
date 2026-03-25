/**
 * @author      WDCi (Lean)
 * @date        Apr 2024
 * @group       Session Management
 * @description Study session scheduler
 * @changehistory
 * ISS-001920 23-04-2024 Lean - new class
 * ISS-002269 13-02-2025 XW - query filtered sev and compare them so that we can hide them in calendar
 */
public with sharing class REDU_SessionSchedulerTimeline_LCTRL {

    public static final String FACULTY = SER_Helper.RELATION_TYPE_FACULTY;
    public static final String FACILITY = SER_Helper.RELATION_TYPE_FACILITY;

    public static final String EVENTCHANGE_SINGLE = 'single';
    public static final String EVENTCHANGE_ALLTHISDAY = 'allthisday';
    public static final String EVENTCHANGE_THISWEEK = 'thisweek';
    public static final String EVENTCHANGE_TWOWEEKS = 'twoweeks';
    public static final String EVENTCHANGE_FOURWEEKS = 'fourweeks';
    public static final String EVENTCHANGE_FUTURE = 'future';

    public static final String CALEVENT_RESPONSEKEY_SEV = 'studyEvents';
    public static final String CALEVENT_RESPONSEKEY_FILTERED_SESSIONCLASS_IDS = 'filteredStudySessionIds';

    private static final Set<String> SER_FIELDS = new Set<String>{
        'Id',
        'Name',
        'reduivy__Allow_Conflict__c',
        'reduivy__Contact__c',
        'reduivy__Contact__r.Name',
        'reduivy__Facility__c',
        'reduivy__Facility__r.Name',
        'reduivy__Relation_Name__c',
        'reduivy__Relation_Type__c',
        'reduivy__Study_Event__c',
        'reduivy__Study_Event__r.Name',
        'reduivy__Event_Start_Datetime__c',
        'reduivy__Event_End_Datetime__c',
        'reduivy__Notes__c'
    };

    private static final Set<String> SEV_FIELDS = new Set<String>{
        'Id',
        'Name',
        'reduivy__Start__c',
        'reduivy__End__c',
        'reduivy__Start_Date_Non_TZ__c',
        'reduivy__Start_Time_Non_TZ__c',
        'reduivy__End_Date_Non_TZ__c',
        'reduivy__End_Time_Non_TZ__c',
        'reduivy__Type__c',
        'reduivy__Timezone__c',
        'reduivy__Study_Session_Time__c',
        'reduivy__Study_Session_Time__r.reduivy__Timezone__c',
        'reduivy__Study_Session_Time__r.reduivy__Study_Session__c',
        'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Background_Colour__c',
        'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Text_Colour__c',
        'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Required_Facility_Type__c',
        'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c',
        'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__c',
        'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__r.reduivy__Timezone__c',
        'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Background_Colour__c',
        'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Text_Colour__c'
    };

    /**
     * @description Get calender events to be shown on the calendar
     * @param  calendarResourceIds The resource id to be shown on the calendar
     * @param  fromDate            The start date of the calendar
     * @param  toDate              The end date of the calendar
     * @param  filterValueStr      String of filter value
     * @return                     return description
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getCalendarEvents(List<Id> calendarResourceIds, Datetime fromDate, Datetime toDate, String filterValueStr, String studySessionDefaultCriteria){
        
        try {
            REDU_Logging_UTIL.debug('calendarResourceIds', calendarResourceIds);
            REDU_Logging_UTIL.debug('fromDate', fromDate);
            REDU_Logging_UTIL.debug('toDate', toDate);
            REDU_Logging_UTIL.debug('fromDate', fromDate.format('yyyy MM dd HH mm ss z'));
            REDU_Logging_UTIL.debug('toDate', toDate.format('yyyy MM dd HH mm ss z'));
            REDU_Logging_UTIL.debug('filterValueStr', filterValueStr);

            REDU_SessionFilterValue_OBJ filterValue = (REDU_SessionFilterValue_OBJ) JSON.deserialize(filterValueStr, REDU_SessionFilterValue_OBJ.class);

            Map<String, Object> responseData = new Map<String, Object>{
                CALEVENT_RESPONSEKEY_SEV => new List<reduivy__Study_Event_Relation__c>(),
                CALEVENT_RESPONSEKEY_FILTERED_SESSIONCLASS_IDS => new Set<Id>()
            };

            if (calendarResourceIds == null || calendarResourceIds.isEmpty()) {
                //handle blank resource
                REDU_LightningResponse blankResponse = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));
                return blankResponse;

            } else {
                //handle request with valid resource

                Schema.SObjectType sobjectType = calendarResourceIds.get(0).getSObjectType();
                Boolean isContact = sobjectType == Schema.Contact.getSObjectType();

                String serSoql = 'SELECT ' + String.join(SER_FIELDS, ', ') +
                    ' FROM reduivy__Study_Event_Relation__c ' +
                    ' WHERE ' + (isContact ? ' reduivy__Contact__c ' : ' reduivy__Facility__c ' ) + ' IN: resourceIds ' +
                    ' AND reduivy__Event_Start_Datetime__c >=: fromDate ' +
                    ' AND reduivy__Event_Start_Datetime__c <: toDate ' +
                    ' AND reduivy__Study_Event__r.reduivy__Status__c =: sevStatus ';

                Map<String, Object> serBindParams = new Map<String, Object>();
                serBindParams.put('resourceIds', calendarResourceIds);
                serBindParams.put('fromDate', fromDate);
                serBindParams.put('toDate', toDate);
                serBindParams.put('sevStatus', SEV_Helper.STATUS_CONFIRMED);

                Set<Id> sevIds = new Set<Id>();
                for (reduivy__Study_Event_Relation__c ser : (List<reduivy__Study_Event_Relation__c>) Database.queryWithBinds(serSoql, serBindParams, AccessLevel.USER_MODE)) {
                    if (String.isNotBlank(ser.reduivy__Study_Event__c)) {
                        sevIds.add(ser.reduivy__Study_Event__c);
                    }
                }


                String sevSoql = 'SELECT ' + String.join(SEV_FIELDS, ', ') + ', ' +
                    ' (SELECT ' + String.join(SER_FIELDS, ', ') + ' FROM reduivy__Study_Event_Relations__r)' +
                    ' FROM reduivy__Study_Event__c' +
                    ' WHERE Id IN: sevIds ' +
                    ' AND reduivy__Status__c =: status ';

                Map<String, Object> sevBindParams = new Map<String, Object>();
                sevBindParams.put('sevIds', sevIds);
                sevBindParams.put('status', SEV_Helper.STATUS_CONFIRMED);

                List<reduivy__Study_Event__c> studyEvents = new List<reduivy__Study_Event__c>();
                for (reduivy__Study_Event__c sev : (List<reduivy__Study_Event__c>) Database.queryWithBinds(sevSoql, sevBindParams, AccessLevel.USER_MODE)) {
                    studyEvents.add(sev);
                }

                Set<Id> filteredStudySessionIds = new Set<Id>();

                for(reduivy__Study_Session__c session : REDU_SessionScheduler_UTIL.getStudySessionsByFilter(fromDate, toDate, filterValue, studySessionDefaultCriteria, null, null)){
                    filteredStudySessionIds.add(session.Id);
                }

                responseData.put(CALEVENT_RESPONSEKEY_SEV, studyEvents);
                responseData.put(CALEVENT_RESPONSEKEY_FILTERED_SESSIONCLASS_IDS, filteredStudySessionIds);

                REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));

                return response;
            }
            
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }


    /**
     * @description Get the preview session
     * @param  studySessionId  The study session id
     * @param  schedulingType  Facility or Faculty
     * @param  unallocatedOnly The preview session is All or unallocated only
     * @param  fromDate        Get the preview session from which date
     * @return                 REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse getSessionPreview(String studySessionId, String schedulingType, Boolean unallocatedOnly, Date fromDate){
        try {
            List<reduivy__Study_Event__c> studyEventList = new List<reduivy__Study_Event__c>();
            if(String.isNotBlank(studySessionId) && String.isNotBlank(schedulingType)){

                String targetRelationType = schedulingType.equalsIgnoreCase(SER_Helper.RELATION_TYPE_FACULTY) ? SER_Helper.RELATION_TYPE_FACULTY : SER_Helper.RELATION_TYPE_FACILITY;
                Map<String, Object> queryBind = new Map<String, Object>();
                
                String query = 'SELECT ' + String.join(SEV_FIELDS, ', ') + ','
                + ' (SELECT ' + String.join(SER_FIELDS, ', ') + ' FROM reduivy__Study_Event_Relations__r)'
                + ' FROM reduivy__Study_Event__c'
                + ' WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :studySessionId'
                + ' AND reduivy__Start_Date_Non_TZ__c >= :fromDate';
                
                queryBind.put('studySessionId', studySessionId);
                queryBind.put('fromDate', fromDate);
                
                if(unallocatedOnly){
                    query += ' AND Id NOT IN (select reduivy__study_event__c from reduivy__study_event_relation__c where reduivy__relation_type__c = :targetRelationType)';
                    queryBind.put('targetRelationType', targetRelationType);
                }
                
                
                studyEventList = Database.queryWithBinds(query, queryBind, AccessLevel.USER_MODE);
                
                
            }
                
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(studyEventList));
                
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description unallocate study event that has the same resource id within the given date range
     * @param  studySessionTimeIds  List of study session time id, semi colon seperated
     * @param  changeType           The date range of changing
     * @param  schedulingType       calendar view (facility or faculty)
     * @param  unallocatedOnly      preview unallocated only
     * @param  fromDate             the dragged event date
     * @param  modifiedEventIds     List of event id that have been modified, semi colon seperated
     * @return                      The parent study event id of the delete study event relation
     */
    @AuraEnabled
    public static REDU_LightningResponse unallocateStudyEvent(List<String> studySessionTimeIdsList, String eventChange, String schedulingType, String selectedSerString, String parentSevString, Integer weekStart){
        SavePoint sp = Database.setSavepoint();

        try {
            
            if(studySessionTimeIdsList.isEmpty() || String.isBlank(selectedSerString) || String.isBlank(parentSevString)) {
                return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(new List<reduivy__Study_Event_Relation__c>()));
            }

            reduivy__Study_Event_Relation__c selectedSer = (reduivy__Study_Event_Relation__c) JSON.deserialize(selectedSerString, reduivy__Study_Event_Relation__c.class);
            reduivy__Study_Event__c affectedStudyEvent = (reduivy__Study_Event__c) JSON.deserialize(parentSevString, reduivy__Study_Event__c.class);

            if(eventChange == EVENTCHANGE_SINGLE){
                REDU_SystemMode_UTIL.doDelete(new List<reduivy__Study_Event_Relation__c>{selectedSer});
                return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(selectedSer));

            } else {

                Map<String, Object> queryBind = new Map<String, Object>();
                String query = 'SELECT Id'
                    + ' FROM reduivy__Study_Event_Relation__c'
                    + ' WHERE reduivy__Study_Event__r.reduivy__Start__c >=: studyEventStart';

                queryBind.put('studyEventStart', affectedStudyEvent.reduivy__Start__c);

                if(schedulingType == FACILITY) {
                    query +=  ' AND reduivy__Facility__c =: facilityId ';
                    queryBind.put('facilityId', selectedSer.reduivy__Facility__c);

                }else if (schedulingType == FACULTY) {
                    query +=  ' AND reduivy__Contact__c =: contactId ';
                    queryBind.put('contactId', selectedSer.reduivy__Contact__c);

                }
                
                if(eventChange == EVENTCHANGE_ALLTHISDAY) {
                    query += (' AND reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c =: sessionId'
                        + ' AND reduivy__Study_Event__r.reduivy__Start_Date_Non_TZ__c = :startDateNonTZ');

                    queryBind.put('sessionId', affectedStudyEvent.reduivy__Study_Session_Time__r.reduivy__Study_Session__c);
                    queryBind.put('startDateNonTZ', affectedStudyEvent.reduivy__Start_Date_Non_TZ__c);
                    
                } else {
                    query += ' AND reduivy__Study_Event__r.reduivy__Study_Session_Time__c IN: studySessionTimeIdsList';
                    queryBind.put('studySessionTimeIdsList', studySessionTimeIdsList);

                    if(eventChange != EVENTCHANGE_FUTURE) {
                        Date toDate = getToDateExcluded(eventChange, affectedStudyEvent.reduivy__Start_Date_Non_TZ__c, weekStart);

                        query += ' AND reduivy__Study_Event__r.reduivy__Start_Date_Non_TZ__c <: toDate';
                        queryBind.put('toDate', toDate);
                    }
                    
                }

                List<reduivy__Study_Event_Relation__c> serToDelete = new List<reduivy__Study_Event_Relation__c>();
                for (reduivy__Study_Event_Relation__c ser : (List<reduivy__Study_Event_Relation__c>) Database.queryWithBinds(query, queryBind, AccessLevel.USER_MODE)) {
                    serToDelete.add(ser);
                }

                if(!serToDelete.isEmpty()){
                    REDU_SystemMode_UTIL.doDelete(serToDelete);
                }

                return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(serToDelete));
            }

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

    /**
     * @description Create new ser or update existing ser based on selected sst
     * @param  studySessionTimeIds      Id of study session time, semicolon seperated
     * @param  eventChange              Type of event change (eg: single, this week, next 2 weeks)
     * @param  schedulingType           Selected scheduling type (Faculty/Facility)
     * @param  ignoredStudyEventIds     Study Event Id that will be ignored (Allocated Preview Study Event)
     * @param  parentSevString the study event record that is affected
     * @param  weekStart                weekStart description
     * @param  unallocatedOnly          True if preview unllocated only
     * @param  oldResourceId            resource id before modified, null if unallocated
     * @param  newResourceId            resource id after modified
     * @return                          REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse allocateStudyEventRelation(List<String> studySessionTimeList, String eventChange, String schedulingType, List<String> ignoredStudyEventList, String parentSevString, Integer weekStart,Boolean unallocatedOnly, String oldResourceId, String newResourceId){
        SavePoint sp = Database.setSavepoint();

        try {
            Map<String, Object> responseData = new Map<String, Object>();

            if(String.isNotBlank(newResourceId)){
                reduivy__Study_Event__c affectedStudyEvent = (reduivy__Study_Event__c) JSON.deserialize(parentSevString, reduivy__Study_Event__c.class);
                
                String targetRelationType = schedulingType.equalsIgnoreCase(SER_Helper.RELATION_TYPE_FACULTY) ? SER_Helper.RELATION_TYPE_FACULTY : SER_Helper.RELATION_TYPE_FACILITY;
            
                Map<String, Object> queryBind = new Map<String, Object>();
                String query = 'SELECT Id, ' +
                    ' reduivy__Study_Session_Time__c, ' +
                    ' reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__c, ' +
                    ' reduivy__Study_Session_Time__r.reduivy__Study_Session__c, ' +
                    ' ( ' +
                    '   SELECT Id, Name, reduivy__Contact__c, reduivy__Facility__c, reduivy__Relation_Type__c ' +
                    '   FROM reduivy__Study_Event_Relations__r ' +
                    '   WHERE reduivy__Relation_Type__c = :schedulingType ' +
                    '   AND ' + (schedulingType == FACILITY ? 'reduivy__Facility__c' : 'reduivy__Contact__c') + ' IN :bothResourceId ' +
                    ' ) ' +
                    ' FROM reduivy__Study_Event__c ' +
                    ' WHERE reduivy__Start__c >= :studyEventStart ';
                            
                if(unallocatedOnly){ 
                    query += ' AND Id NOT IN :ignoredStudyEventList';
                    queryBind.put('ignoredStudyEventList', ignoredStudyEventList);
                }

                //get the study events that match the resource type if old resource id is not empty(update from other resource)
                //or study events that are unallocated (old resource is empty and unallocated only is true)
                if(String.isNotBlank(oldResourceId) || 
                    (String.isBlank(oldResourceId) && unallocatedOnly)
                ){

                    query +=  ' AND Id' + (String.isNotBlank(oldResourceId) ? '' : ' NOT') + ' IN ('
                            + ' SELECT reduivy__Study_Event__c' 
                            + ' FROM reduivy__Study_Event_Relation__c'
                            + ' WHERE reduivy__Relation_Type__c = :targetRelationType)';
                    queryBind.put('targetRelationType', targetRelationType);
                }

                queryBind.put('studyEventStart', affectedStudyEvent.reduivy__Start__c);
                queryBind.put('schedulingType', schedulingType);
                queryBind.put('bothResourceId', new List<String>{String.isBlank(oldResourceId) ? newResourceId : oldResourceId, newResourceId});

                REDU_Logging_UTIL.debug('studyEventStart', affectedStudyEvent.reduivy__Start__c);
                REDU_Logging_UTIL.debug('schedulingType', schedulingType);
                REDU_Logging_UTIL.debug('bothResourceId', new List<String>{String.isBlank(oldResourceId) ? newResourceId : oldResourceId, newResourceId});
                REDU_Logging_UTIL.debug('ignoredStudyEventList', ignoredStudyEventList);

                if(eventChange == EVENTCHANGE_SINGLE) {
                    query += ' AND Id = :studyEventId';
                    queryBind.put('studyEventId', affectedStudyEvent.Id);

                    REDU_Logging_UTIL.debug('studyEventId', affectedStudyEvent.Id);

                } else if(eventChange == EVENTCHANGE_ALLTHISDAY) {
                    query += (' AND reduivy__Start_Date_Non_TZ__c = :fromDate'
                        + ' AND reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :sessionId');
                        
                    queryBind.put('fromDate', affectedStudyEvent.reduivy__Start_Date_Non_TZ__c);
                    queryBind.put('sessionId', affectedStudyEvent.reduivy__Study_Session_Time__r.reduivy__Study_Session__c);

                    REDU_Logging_UTIL.debug('fromDate', affectedStudyEvent.reduivy__Start_Date_Non_TZ__c);
                    REDU_Logging_UTIL.debug('sessionId', affectedStudyEvent.reduivy__Study_Session_Time__r.reduivy__Study_Session__c);
                    
                } else {
                    query  += ' AND reduivy__Start__c >= :fromDate'
                        + ' AND reduivy__Study_Session_Time__c IN :studySessionTimeList';

                    queryBind.put('studySessionTimeList', studySessionTimeList);
                    queryBind.put('fromDate', affectedStudyEvent.reduivy__Start__c);

                    REDU_Logging_UTIL.debug('studySessionTimeList', studySessionTimeList);
                    REDU_Logging_UTIL.debug('fromDate', affectedStudyEvent.reduivy__Start_Date_Non_TZ__c);

                    if(eventChange != EVENTCHANGE_FUTURE) {        
                        Date toDate = getToDateExcluded(eventChange, affectedStudyEvent.reduivy__Start_Date_Non_TZ__c, weekStart);
                        query += ' AND reduivy__Start_Date_Non_TZ__c < :toDate';
                        queryBind.put('toDate',toDate);

                        REDU_Logging_UTIL.debug('toDate',toDate);
                    }
                }

                REDU_Logging_UTIL.debug('query', query);
                List<reduivy__Study_Event_Relation__c> serToUpsert = new List<reduivy__Study_Event_Relation__c>();
                Set<Id> notifyRecordUpdateAvailableId = new Set<Id>();

                List<reduivy__Study_Event__c> parentStudyEvents = new List<reduivy__Study_Event__c>();
                for (reduivy__Study_Event__c sev : (List<reduivy__Study_Event__c>) Database.queryWithBinds(query, queryBind, AccessLevel.USER_MODE)) {
                    parentStudyEvents.add(sev);
                }

                REDU_Logging_UTIL.debug('parentStudyEvents', parentStudyEvents);
                if(!parentStudyEvents.isEmpty()){
           
                    Map<Id, Id> studyEventToIsnMap;

                    if(schedulingType == FACULTY){
                        //Create or link IEN and ISN for faculty allocation
                        studyEventToIsnMap = SER_Helper.linkIenAndIsnRelationship(parentStudyEvents, newResourceId, null);
                    }

                    for(reduivy__Study_Event__c evt: parentStudyEvents){
                        if(!serIsDuplicated(schedulingType, evt.reduivy__Study_Event_Relations__r, newResourceId)){
                            
                            reduivy__Study_Event_Relation__c ser = new reduivy__Study_Event_Relation__c( 
                                reduivy__Study_Event__c = evt.Id
                            );
                            
                            for(reduivy__Study_Event_Relation__c existingSer : evt.reduivy__Study_Event_Relations__r){
                                if((schedulingType == FACILITY && existingSer.reduivy__Facility__c == oldResourceId) || 
                                    (schedulingType == FACULTY && existingSer.reduivy__Contact__c == oldResourceId && existingSer.reduivy__Relation_Type__c == FACULTY)
                                ) {
                                    ser.Id = existingSer.Id;
                                    notifyRecordUpdateAvailableId.add(existingSer.Id);
                                    break;
                                }
                            }
                            
                            if(schedulingType == FACILITY) {
                                ser.reduivy__Facility__c = newResourceId;
                            } else if(schedulingType == FACULTY) {
                                ser.reduivy__Contact__c = newResourceId;
                                ser.reduivy__Individual_Session_Enrollment__c = studyEventToIsnMap.get(evt.Id);
                            }

                            notifyRecordUpdateAvailableId.add(evt.Id);
                            notifyRecordUpdateAvailableId.add(evt.reduivy__Study_Session_Time__r.reduivy__Study_Session__c);
                            
                            serToUpsert.add(ser);
                        }
                    }      
                }

                if(!serToUpsert.isEmpty()) {
                    REDU_Database_UTIL.doUpsert(serToUpsert);
                }
    
                responseData.put('notifyRecordUpdateAvailableId', notifyRecordUpdateAvailableId);
                responseData.put('upsertedStudyEventRelation', serToUpsert);
            }
            
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));
            
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

    /**
     * @description Change ser time
     * @param  serId          The Id of affected ser
     * @param  schedulingType Scheduling type (Facility/Faculty)
     * @param  newStart       End date and time before modified
     * @param  newEnd         End date and time after modified
     * @param  oldResourceId  resource id before modified
     * @param  newResourceId  resource id after modified
     * @return                return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse changeStudyEventTime(String serId, String schedulingType, Datetime newStart, Datetime newEnd, String oldResourceId, String newResourceId){
        SavePoint sp = Database.setSavepoint();

        try{
            reduivy__Study_Event__c studyEventToUpdate = new reduivy__Study_Event__c();

            if(String.isNotBlank(oldResourceId) && String.isNotBlank(serId)){
                Set<String> serFields = new Set<String>{
                    'Id',
                    'Name',
                    'reduivy__Study_Event__c',
                    'reduivy__Study_Event__r.Name',
                    'reduivy__Study_Event__r.reduivy__Start__c',
                    'reduivy__Study_Event__r.reduivy__Start_Date_Non_TZ__c',
                    'reduivy__Study_Event__r.reduivy__Start_Time_Non_TZ__c',
                    'reduivy__Study_Event__r.reduivy__End__c',
                    'reduivy__Study_Event__r.reduivy__End_Date_Non_TZ__c',
                    'reduivy__Study_Event__r.reduivy__End_Time_Non_TZ__c',
                    'reduivy__Study_Event__r.reduivy__Timezone__c'
                };

                Map<String, Object> queryBind = new Map<String, Object>();
                String query = 'SELECT ' + String.join(serFields, ', ')
                    + ' FROM reduivy__Study_Event_Relation__c'
                    + ' WHERE ' + (schedulingType == FACILITY ? 'reduivy__Facility__c' : 'reduivy__Contact__c') + ' = :resourceId'
                    + ' AND Id =: serId';

                queryBind.put('resourceId', oldResourceId);
                queryBind.put('serId', serId);

                List<reduivy__Study_Event_Relation__c> studyEventRelationList = Database.queryWithBinds(query, queryBind, AccessLevel.USER_MODE);

                if(!studyEventRelationList.isEmpty()){
                    reduivy__Study_Event_Relation__c studyEventRelation = studyEventRelationList[0];
                    studyEventToUpdate.Id = studyEventRelation.reduivy__Study_Event__r.Id;

                    reduivy__Study_Event_Relation__c serToUpdate = new reduivy__Study_Event_Relation__c(
                        Id = studyEventRelation.Id
                    );

                    String eventTimezoneStr = studyEventRelation.reduivy__Study_Event__r.reduivy__Timezone__c;

                    studyEventToUpdate.reduivy__Start_Date_Non_TZ__c = studyEventRelation.reduivy__Study_Event__r.reduivy__Start_Date_Non_TZ__c;
                    studyEventToUpdate.reduivy__Start_Time_Non_TZ__c = studyEventRelation.reduivy__Study_Event__r.reduivy__Start_Time_Non_TZ__c;
                    studyEventToUpdate.reduivy__End_Date_Non_TZ__c = studyEventRelation.reduivy__Study_Event__r.reduivy__End_Date_Non_TZ__c;
                    studyEventToUpdate.reduivy__End_Time_Non_TZ__c = studyEventRelation.reduivy__Study_Event__r.reduivy__End_Time_Non_TZ__c;

                    REDU_Logging_UTIL.debug('startDateNonTzBefore',studyEventToUpdate.reduivy__Start_Date_Non_TZ__c);
                    REDU_Logging_UTIL.debug('startTimeNonTzBefore',studyEventToUpdate.reduivy__Start_Time_Non_TZ__c);    
                    REDU_Logging_UTIL.debug('endDateNonTzBefore',studyEventToUpdate.reduivy__End_Date_Non_TZ__c);
                    REDU_Logging_UTIL.debug('endTimeNonTzBefore',studyEventToUpdate.reduivy__End_Time_Non_TZ__c);
    
                    if( String.isBlank(eventTimezoneStr) || eventTimezoneStr == UserInfo.getTimeZone().getID()){
                        
                        studyEventToUpdate.reduivy__Start_Date_Non_TZ__c = newStart.date();
                        studyEventToUpdate.reduivy__Start_Time_Non_TZ__c = newStart.time();
                        studyEventToUpdate.reduivy__End_Date_Non_TZ__c = newEnd.date();
                        studyEventToUpdate.reduivy__End_Time_Non_TZ__c = newEnd.time();
                    } else {
 
                        Datetime startInEventTimezone = REDU_Date_UTIL.convertDateTime(newStart, eventTimezoneStr, UserInfo.getTimeZone().getID());
                        Datetime endInEventTimezone = REDU_Date_UTIL.convertDateTime(newEnd, eventTimezoneStr, UserInfo.getTimeZone().getID());

                        studyEventToUpdate.reduivy__Start_Date_Non_TZ__c = startInEventTimezone.date();
                        studyEventToUpdate.reduivy__Start_Time_Non_TZ__c = startInEventTimezone.time();
                        studyEventToUpdate.reduivy__End_Date_Non_TZ__c = endInEventTimezone.date();
                        studyEventToUpdate.reduivy__End_Time_Non_TZ__c = endInEventTimezone.time();

                    }

                    REDU_Logging_UTIL.debug('startDateNonTzAfter',studyEventToUpdate.reduivy__Start_Date_Non_TZ__c);
                    REDU_Logging_UTIL.debug('startTimeNonTzAfter',studyEventToUpdate.reduivy__Start_Time_Non_TZ__c);
                    REDU_Logging_UTIL.debug('endDateNonTzAfter',studyEventToUpdate.reduivy__End_Date_Non_TZ__c);
                    REDU_Logging_UTIL.debug('endTimeNonTzAfter',studyEventToUpdate.reduivy__End_Time_Non_TZ__c);
                    
                    REDU_Database_UTIL.doUpdate(new List<reduivy__Study_Event__c>{studyEventToUpdate});
                    
                    //update resource
                    if(String.isNotBlank(newResourceId) && oldResourceId != newResourceId){

                        if(schedulingType == FACILITY) {
                            serToUpdate.reduivy__Facility__c = newResourceId;

                        } else if (schedulingType == FACULTY){
                            serToUpdate.reduivy__Contact__c = newResourceId;

                            List<reduivy__Study_Event__c> updatedStudyEvent = new List<reduivy__Study_Event__c>();
                            for(reduivy__Study_Event__c sev : [
                                SELECT Id, Name,
                                reduivy__Study_Session_Time__c,
                                reduivy__Study_Session_Time__r.reduivy__Study_Session__c,
                                reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__c
                                FROM reduivy__Study_Event__c
                                WHERE Id = :studyEventToUpdate.Id
                                WITH USER_MODE
                                LIMIT 1
                            ]){
                                updatedStudyEvent.add(sev);
                            }

                            Map<Id, Id> studyEventToIsnIdMap = SER_Helper.linkIenAndIsnRelationship(updatedStudyEvent, newResourceId, null);
                            serToUpdate.reduivy__Individual_Session_Enrollment__c = studyEventToIsnIdMap.get(updatedStudyEvent[0].Id);
                        }

                        REDU_Database_UTIL.doUpdate(new List<reduivy__Study_Event_Relation__c>{ serToUpdate });
                    }
                }
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(studyEventToUpdate));

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




    /**
     * @description To check is ser duplicated
     * @param  schedulingType Scheduling Type (Facility/Faculty)
     * @param  sers           List of Ser
     * @param  resourceId     The resource id (contact id / facility)
     * @return                true if ser is duplicated
     */
    private static Boolean serIsDuplicated(String schedulingType, List<reduivy__Study_Event_Relation__c> sers, String resourceId) {
        for(reduivy__Study_Event_Relation__c existingSer : sers){
            if((schedulingType == FACULTY && existingSer.reduivy__Contact__c == resourceId) ||
               (schedulingType == FACILITY && existingSer.reduivy__Facility__c == resourceId)) {
                return true;
            }
        }

        return false;
    }

    /**
     * @description Get the range of date based on eventChange
     * @param  eventChange The type of event change (next 1/2/4 weeks)
     * @param  fromDate    The start date
     * @param  weekStart   The starting day of a week
     * @return             The end date of the range, is excluded 
     */
    private static Date getToDateExcluded(String eventChange, Date fromDate, Integer weekStart){
        
        Datetime latestToDate = Datetime.newInstance(fromDate, Time.newInstance(0, 0, 0, 0));
        Date firstDayOfWeekFromDate = Date.valueOf(fromDate);
        Integer dayOfFromDate = REDU_Date_UTIL.getDay(latestToDate, true);

        if(dayOfFromDate == REDU_Date_UTIL.SF_SUNDAY && weekStart != REDU_Date_UTIL.SF_SUNDAY) {
            firstDayOfWeekFromDate = firstDayOfWeekFromDate.addDays(-6);
        } else {
            firstDayOfWeekFromDate = firstDayOfWeekFromDate.toStartOfWeek();
        }

        Datetime tempDate = Datetime.newInstance(firstDayOfWeekFromDate, Time.newInstance(0, 0, 0, 0));
        Integer dayOfTempDate = REDU_Date_UTIL.getDay(tempDate, true);
        Integer distance = (dayOfTempDate == weekStart ? 0 : weekStart - dayOfTempDate);

        if(distance < 0){
            distance += 7;
        }

        firstDayOfWeekFromDate = firstDayOfWeekFromDate.addDays(distance);

        if(eventChange == EVENTCHANGE_THISWEEK){
            latestToDate = firstDayOfWeekFromDate.addDays(7);
        } else if(eventChange == EVENTCHANGE_TWOWEEKS) {
            latestToDate = firstDayOfWeekFromDate.addDays(14);
        } else if(eventChange == EVENTCHANGE_FOURWEEKS) {
            latestToDate = firstDayOfWeekFromDate.addDays(28);
        }


        return latestToDate.date();
    }

}
