/**
 * @author      WDCi (Lean)
 * @date        April 2024
 * @group       Object Helper
 * @description Study Session object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002050 17-09-2024 Sueanne - added methods to get status lists
 * ISS-002256 14-02-2025 XW - remove existing sevs which are out of new date range
 */
global inherited sharing class SSE_Helper implements SObject_Helper {

    /**
     * @description Status Type - Draft
     */
    public static final String STATUS_TYPE_DRAFT = 'Draft';

    /**
     * @description Status Type - Not Started
     */
    public static final String STATUS_TYPE_NOTSTARTED = 'Not_Started';

    /**
     * @description Status Type - Pre_enrollment_Opened
     */
    public static final String STATUS_TYPE_PREENROLLMENT_OPENED = 'Pre_enrollment_Opened';

    /**
     * @description Status Type - Enrollment_Opened
     */
    public static final String STATUS_TYPE_ENROLLMENT_OPENED = 'Enrollment_Opened';

    /**
     * @description Status Type - Enrollment_Closed
     */
    public static final String STATUS_TYPE_ENROLLMENT_CLOSED = 'Enrollment_Closed';

    /**
     * @description Status Type - Running_Enrollment_Opened
     */
    public static final String STATUS_TYPE_RUNNING_ENROLLMENT_OPENED = 'Running_Enrollment_Opened';

    /**
     * @description Status Type - Running
     */
    public static final String STATUS_TYPE_RUNNING = 'Running';

    /**
     * @description Status Type - Completed
     */
    public static final String STATUS_TYPE_COMPLETED = 'Completed';

    /**
     * @description Status Type - Cancelled
     */
    public static final String STATUS_TYPE_CANCELLED = 'Cancelled';
    
    /**
     * @description Study Event Generation Status - Generate
    */
    public static final String STUDY_EVENT_GEN_STATUS_DRAFT = 'Draft';

    /**
     * @description Study Event Generation Status - Generate
    */
    public static final String STUDY_EVENT_GEN_STATUS_GENERATE = 'Generate';

    /**
     * @description Study Event Generation Status - Generated
    */
    public static final String STUDY_EVENT_GEN_STATUS_GENERATED = 'Generated';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Session__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Session__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Session__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Session__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Return fields for cloning
     */
    public static Set<String> getFieldsForCloning(){
        //Set the exclude the dates and rollup fields so that it won’t inherit from the parent, and the calculated field will inherit from the term record's date
        Set<String> sseFieldsToExclude = new Set<String>{
            'reduivy__Start_Date__c',
            'reduivy__End_Date__c',
            'reduivy__Enrollment_Open_Date__c',
            'reduivy__Enrollment_Close_Date__c',
            'reduivy__Pre_enrollment_Open_Date__c',
            'reduivy__Status_Override__c',
            'reduivy__Booked_Places__c',
            'reduivy__Waitlist_Places__c',
            'reduivy__Study_Event_Generation_Status__c'
        };

        Set<String> sseFields = REDU_Metadata_UTIL.getObjectFieldsForCloning('reduivy__Study_Session__c', AccessType.CREATABLE);
        sseFields.removeAll(sseFieldsToExclude);

        return sseFields;
    }

    /**
     * @description List of reduivy__Study_Session_Status_Config__mdt
     */
    private static List<reduivy__Study_Session_Status_Config__mdt> statusConfigs;

    /**
     * @description Status configs metadata sorted according to Status field
     * @return List<reduivy__Study_Session_Status_Config__mdt>
     */
    public static List<reduivy__Study_Session_Status_Config__mdt> getStatusConfig(){

        if (statusConfigs == null) {
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Study_Session__c.fields.reduivy__Status_Override__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__Study_Session_Status_Config__mdt> configs = reduivy__Study_Session_Status_Config__mdt.getAll().values();
            List<reduivy__Study_Session_Status_Config__mdt> sortedConfigs = new List<reduivy__Study_Session_Status_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList) {
                if(ple.isActive()) {
                    for (reduivy__Study_Session_Status_Config__mdt config : configs) {
                        if (config.reduivy__Active__c && ple.getValue() == config.reduivy__Status__c) {
                            sortedConfigs.add(config);
                        }
                    }
                }
            }

            statusConfigs = sortedConfigs;
        }

        return statusConfigs;
    }

    /**
     * @description Draft statuses
     */
    private static List<String> draftStatuses;

    /**
     * @description Return a list of draft statuses
     * @return List<String>
     */
    public static List<String> getDraftStatuses() {

        if (draftStatuses == null) {
            draftStatuses = new List<String>();

            for (reduivy__Study_Session_Status_Config__mdt config : getStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_DRAFT) {
                    draftStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return draftStatuses;
    }

    /**
     * @description Not Started statuses
     */
    private static List<String> notStartedStatuses;

    /**
     * @description Return a list of not started statuses
     * @return List<String>
     */
    public static List<String> getNotStartedStatuses() {

        if (notStartedStatuses == null) {
            notStartedStatuses = new List<String>();

            for (reduivy__Study_Session_Status_Config__mdt config : getStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_NOTSTARTED) {
                    notStartedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return notStartedStatuses;
    }

    /**
     * @description Pre-enrollment Opened statuses
     */
    private static List<String> preEnrollmentOpenedStatuses;

    /**
     * @description Return a list of pre-enrollment opened statuses
     * @return List<String>
     */
    public static List<String> getPreEnrollmentOpenedStatuses() {

        if (preEnrollmentOpenedStatuses == null) {
            preEnrollmentOpenedStatuses = new List<String>();

            for (reduivy__Study_Session_Status_Config__mdt config : getStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_PREENROLLMENT_OPENED) {
                    preEnrollmentOpenedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return preEnrollmentOpenedStatuses;
    }

    /**
     * @description Enrollment Opened statuses
     */
    private static List<String> enrollmentOpenedStatuses;

    /**
     * @description Return a list of enrollment opened statuses
     * @return List<String>
     */
    public static List<String> getEnrollmentOpenedStatuses() {

        if (enrollmentOpenedStatuses == null) {
            enrollmentOpenedStatuses = new List<String>();

            for (reduivy__Study_Session_Status_Config__mdt config : getStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_ENROLLMENT_OPENED || config.reduivy__Type__c == STATUS_TYPE_RUNNING_ENROLLMENT_OPENED) {
                    enrollmentOpenedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return enrollmentOpenedStatuses;
    }

    /**
     * @description Enrollment Closed statuses
     */
    private static List<String> enrollmentClosedStatuses;

    /**
     * @description Return a list of enrollment closed statuses
     * @return List<String>
     */
    public static List<String> getEnrollmentClosedStatuses() {

        if (enrollmentClosedStatuses == null) {
            enrollmentClosedStatuses = new List<String>();

            for (reduivy__Study_Session_Status_Config__mdt config : getStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_ENROLLMENT_CLOSED) {
                    enrollmentClosedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return enrollmentClosedStatuses;
    }

    /**
     * @description Running statuses
     */
    private static List<String> runningStatuses;

    /**
     * @description Return a list of running with enrollment opened statuses
     * @return List<String>
     */
    public static List<String> getRunningStatuses() {

        if (runningStatuses == null) {
            runningStatuses = new List<String>();

            for (reduivy__Study_Session_Status_Config__mdt config : getStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_RUNNING || config.reduivy__Type__c == STATUS_TYPE_RUNNING_ENROLLMENT_OPENED) {
                    runningStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return runningStatuses;
    }

    /**
     * @description Completed statuses
     */
    private static List<String> completedStatuses;

    /**
     * @description Return a list of completed statuses
     * @return List<String>
     */
    public static List<String> getCompletedStatuses() {

        if (completedStatuses == null) {
            completedStatuses = new List<String>();

            for (reduivy__Study_Session_Status_Config__mdt config : getStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_COMPLETED) {
                    completedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return completedStatuses;
    }

    /**
     * @description Cancelled statuses
     */
    private static List<String> cancelledStatuses;

    /**
     * @description Return a list of cancelled statuses
     * @return List<String>
     */
    public static List<String> getCancelledStatuses() {

        if (cancelledStatuses == null) {
            cancelledStatuses = new List<String>();

            for (reduivy__Study_Session_Status_Config__mdt config : getStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_CANCELLED) {
                    cancelledStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return cancelledStatuses;
    }


    /**
     * @description create/update study event when user has updated the study session status to 'Generate Study Events'
     * @param studySessionTime Study Session Time
     * @param daysMultiplier Number of days to add to the start date (e.g.: weekly = 7, bi-weekly = 14, daily = 1, once-off = 0)
     * @param existingStudyEvents List of existing study events
     * @param accIdHolidayMap Map of account id (campus + related educational institution) to list of holidays
     * @return StudyEventInfo
     */
    public static StudyEventInfo generateStudyEvents(reduivy__Study_Session_Time__c studySessionTime, Integer daysMultiplier, List<reduivy__Study_Event__c> existingStudyEvents, Map<Id, List<reduivy__Holiday__c>> accIdHolidayMap) {

        List<reduivy__Study_Event__c> studyEventList = new List<reduivy__Study_Event__c>();

        Date startDate = getStartDate(studySessionTime);
        Integer numberDaysDue = startDate.daysBetween(studySessionTime.reduivy__End_Date_Calculated__c) + 1;
        Integer dividedDays = (daysMultiplier == 0 ? 0 : numberDaysDue/daysMultiplier);

        Map<String, reduivy__Study_Event__c> isoWeekToStudyEventMap = new Map<String, reduivy__Study_Event__c>(); //Weekly Map of year+week to Study Event
        Map<Date, reduivy__Study_Event__c> dateToStudyEventMap = new Map<Date, reduivy__Study_Event__c>(); //Daily Map of Date to Study Event
        reduivy__Study_Event__c existingOneOffStudyEvent;

        if (!existingStudyEvents.isEmpty()){

            //Weekly - map against ISO Week
            if (studySessionTime.reduivy__Recurrence__c == SST_Helper.RECURRENCE_WEEKLY){
                for (reduivy__Study_Event__c sev : existingStudyEvents){
                    if (sev.reduivy__ISO_Week__c != null){
                        String isoWeekKey = String.valueOf(sev.reduivy__ISO_Year__c) + String.valueOf(sev.reduivy__ISO_Week__c);
                        isoWeekToStudyEventMap.put(isoWeekKey, sev); 
                    }
                }
            //Daily - map against date
            } else if (studySessionTime.reduivy__Recurrence__c == SST_Helper.RECURRENCE_DAILY){
                for (reduivy__Study_Event__c sev : existingStudyEvents){
                    dateToStudyEventMap.put(sev.reduivy__Start_Date_Non_TZ__c, sev); 
                }
            //One off - replace the single booking
            } else if (studySessionTime.reduivy__Recurrence__c == SST_Helper.RECURRENCE_ONEOFF){
                existingOneOffStudyEvent = existingStudyEvents[0];
            }
        }
        Map<Id, reduivy__Study_Event__c> existingStudyEventsMap = new Map<Id, reduivy__Study_Event__c> (existingStudyEvents);

        //If start time is larger than end time, consider end time will be the next day
        integer nextDayTopper = studySessionTime.reduivy__Start_Time__c > studySessionTime.reduivy__End_Time__c ? 1 : 0;
        for (integer i = 0; i <= dividedDays; i++){

            reduivy__Study_Event__c studyEvent;
            Date currentStartDate = startDate.addDays(i * daysMultiplier);
            Date currentEndDate = currentStartDate.addDays(nextDayTopper);

            //Check we have not passed the end date
            if (currentStartDate > studySessionTime.reduivy__End_Date_Calculated__c) {
                break;
            }

            //Check for an existing study event
            if (!existingStudyEvents.isEmpty()){
                //Weekly - map against ISO Week
                if (studySessionTime.reduivy__Recurrence__c == SST_Helper.RECURRENCE_WEEKLY){
                    //Find ISO Week for our new booking that we've created
                    List<Integer> sevIsoInfo = REDU_Date_UTIL.getISOWeekNumberAndYear(currentStartDate);
                    String isoWeekKey = String.valueOf(sevIsoInfo[1]) + String.valueOf(sevIsoInfo[0]);
                    //Chcek map for existing key
                    if (isoWeekToStudyEventMap.containsKey(isoWeekKey)){
                        //Set booking to update, instead of insert
                        studyEvent = isoWeekToStudyEventMap.get(isoWeekKey);
                        existingStudyEventsMap.remove(studyEvent.Id);
                    }
                //Daily - map against date
                } else if (studySessionTime.reduivy__Recurrence__c == SST_Helper.RECURRENCE_DAILY){
                    //Check map for existing key
                    if (dateToStudyEventMap.containsKey(currentStartDate)){
                        //Set booking to update, instead of insert
                        studyEvent = dateToStudyEventMap.get(currentStartDate);
                        existingStudyEventsMap.remove(studyEvent.Id);
                    }
                //One off - replace the single booking
                } else if (studySessionTime.reduivy__Recurrence__c == SST_Helper.RECURRENCE_ONEOFF){
                    if (existingOneOffStudyEvent != null){
                        studyEvent = existingOneOffStudyEvent;
                        existingStudyEventsMap.remove(studyEvent.Id);
                    }
                }
            }

            //Create new study event if none found
            if(studyEvent == null){
                studyEvent = new reduivy__Study_Event__c();
                studyEvent.reduivy__Study_Session_Time__c = studySessionTime.Id;
            }

            Datetime tempStartDate = DateTime.newInstance(currentStartDate, Time.newInstance(0,0,0,0));
            studyEvent.Name = studySessionTime.reduivy__Study_Session__r.Name + ' (' + tempStartDate.format('EEEE') + ') - ' + currentStartDate.format();
            studyEvent.reduivy__Type__c = SEV_Helper.TYPE_STUDY_SESSION;
            studyEvent.reduivy__Timezone__c = studySessionTime.reduivy__Timezone__c;
            studyEvent.reduivy__Start_Date_Non_TZ__c = currentStartDate;
            studyEvent.reduivy__Start_Time_Non_TZ__c = studySessionTime.reduivy__Start_Time__c;
            studyEvent.reduivy__End_Date_Non_TZ__c = currentEndDate;
            studyEvent.reduivy__End_Time_Non_TZ__c = studySessionTime.reduivy__End_Time__c;
            studyEvent.reduivy__Status__c = SEV_Helper.STATUS_CONFIRMED;

            studyEventList.add(studyEvent);
        }

        List<reduivy__Study_Event__c> createStudyEventList = new List<reduivy__Study_Event__c>();
        List<reduivy__Study_Event__c> deleteStudyEventList = existingStudyEventsMap.values();
        if(!studySessionTime.reduivy__Ignore_Holidays__c){

            Set<Id> holidayParentIds = new Set<Id>();
            if (String.isNotBlank(studySessionTime.reduivy__Study_Session__r.reduivy__Study_Offering__r?.reduivy__Campus__c)) {
                holidayParentIds.add(studySessionTime.reduivy__Study_Session__r.reduivy__Study_Offering__r?.reduivy__Campus__c);
            }

            if (String.isNotBlank(studySessionTime.reduivy__Study_Session__r.reduivy__Study_Offering__r?.reduivy__Campus__r?.ParentId)) {
                holidayParentIds.add(studySessionTime.reduivy__Study_Session__r.reduivy__Study_Offering__r?.reduivy__Campus__r?.ParentId);
            }

            for(reduivy__Study_Event__c sev : studyEventList){

                if(!holidayParentIds.isEmpty()){

                    Boolean holidayMatched = false;
                    
                    for (Id parentId : holidayParentIds) {
                        if (accIdHolidayMap.containsKey(parentId)) {
                            for(reduivy__Holiday__c holiday : accIdHolidayMap.get(parentId)){
                                
                                if((sev.reduivy__Start_Date_Non_TZ__c <= holiday.reduivy__End_Date__c && sev.reduivy__End_Date_Non_TZ__c >= holiday.reduivy__Start_Date__c)){

                                    holidayMatched = true;
                                    break;
                                }
                            }
                        }

                        if (holidayMatched) {
                            break;
                        }
                    }

                    //If the event happens on holiday, delete or skip the creation.
                    if(sev.Id != null && holidayMatched){
                        deleteStudyEventList.add(sev);
                    }else if(!holidayMatched){
                        createStudyEventList.add(sev);
                    }
                }else{
                    createStudyEventList.add(sev);
                }
            }
        }else{
            createStudyEventList.addAll(studyEventList);
        }

        StudyEventInfo sei = new StudyEventInfo(createStudyEventList, deleteStudyEventList);
        return sei;
    }

    /**
     * @description Get the start date of session time based on settings
     * @param sst Session Time record with information needed to create the study event (reduivy__Study_Event__c)
     * @return Date
     */
    private static Date getStartDate(reduivy__Study_Session_Time__c sst){

        Date startDate;

        if (sst.reduivy__Update_Settings__c == SST_Helper.UPDATE_SETTING_AFTERCHANGEDATE){
            startDate = sst.reduivy__Change_Date__c.addDays(1);
        } else if (sst.reduivy__Update_Settings__c == SST_Helper.UPDATE_SETTING_AFTERTODAY){
            startDate = System.today().addDays(1);
        } else if (sst.reduivy__Update_Settings__c == SST_Helper.UPDATE_SETTING_FROMCHANGEDATE){
            startDate = sst.reduivy__Change_Date__c;
        } else if (sst.reduivy__Update_Settings__c == SST_Helper.UPDATE_SETTING_FROMTODAY){
            startDate = System.today();
        } else {
            startDate = sst.reduivy__Start_Date_Calculated__c;
        }

        startDate = sst.reduivy__Start_Date_Calculated__c > startDate ? sst.reduivy__Start_Date_Calculated__c : startDate;

        Time startTime = sst.reduivy__Start_Time__c;

        DateTime sstDateTime = DateTime.newInstance(startDate, startTime);
        DateTime returnDateTime = sstDateTime;
        String sessionTimeDay = sst.reduivy__Day_of_Week__c;
        
        //Day of stDateTime may not fall on Day_of_Week from session time. Go forward each day until it matches
        for (Integer i = 0; i <= 7; i++){

            //Day_of_Week may not have been set. in that case, just use the original date time.
            if (i == 7){
                returnDateTime = sstDateTime;
                break;
            }
            
            String dayString = returnDateTime.format('EEEE');
            
            if (sessionTimeDay == dayString){
                break;
            } else {
                returnDateTime = returnDateTime.addDays(1);
            }
            
        }

        //return startDate;
        return returnDateTime.date();
    }

    /**
    * @description Wrapper for returning info from createStudyEvents()
    */
    public class StudyEventInfo{

        /**
        * @description Bookings to Upsert
        */
        public List<reduivy__Study_Event__c> studyEventsToUpsert {get;set;}
        
        /**
        * @description Bookings to Delete
        */
        public List<reduivy__Study_Event__c> studyEventsToDelete {get;set;}

        public StudyEventInfo(List<reduivy__Study_Event__c> studyEventsToUpsert, List<reduivy__Study_Event__c> studyEventsToDelete){
            this.studyEventsToUpsert = studyEventsToUpsert;
            this.studyEventsToDelete = studyEventsToDelete;
        }
    }
	
}