/**
 * @author      WDCi (Lean)
 * @date        April 2024
 * @group       Object Helper
 * @description Individual Session Enrollment object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001918 01-08-2024 CM - Added getEnrollmentStatusConfig() and related status type getters, similar to IEN_Helper
 * ISS-002050 09-19-2024 Sueanne - Added enrollment actions
 * ISS-002455 09-06-2025 XW - created rollupFieldsApiNameByStatus and rollupStatusesByField
 * ISS-002670 11-04-2025 XW - populate faculty roles in faculty isn when creating isn in linkIsnRelationship
 */
global inherited sharing class ISN_Helper implements SObject_Helper {
    
    /**
     * @description Status Type - Open
     */
    public static final String STATUS_TYPE_OPEN = 'Open';

    /**
     * @description Status Type - Enrollment Requested
     */
    public static final String STATUS_TYPE_ENROLLMENT_REQUESTED = 'Enrollment_Requested';

    /**
     * @description Status Type - In Progress
     */
    public static final String STATUS_TYPE_INPROGRESS = 'In_Progress';

    /**
     * @description Status Type - Completed
     */
    public static final String STATUS_TYPE_COMPLETED = 'Completed';

    /**
     * @description Status Type - Waitlisted
     */
    public static final String STATUS_TYPE_WAITLISTED = 'Waitlisted';

    /**
     * @description Status Type - Dropped
     */
    public static final String STATUS_TYPE_DROPPED = 'Dropped';

    /**
     * @description Status Type - Withdrawn
     */
    public static final String STATUS_TYPE_WITHDRAWN = 'Withdrawn';

    /**
     * @description Enrollment Action - Enroll
     */
    public static final String ENROLLMENT_ACTION_ENROLL = 'Enroll';

    /**
     * @description Enrollment Action - EnrollRequested
     */
    public static final String ENROLLMENT_ACTION_ENROLLREQUESTED = 'EnrollRequested';

    /**
     * @description Enrollment Action - WithdrawEnrollRequested
     */
    public static final String ENROLLMENT_ACTION_WITHDRAWENROLLREQUESTED = 'WithdrawEnrollRequested';

    /**
     * @description Enrollment Action - Unenroll
     */
    public static final String ENROLLMENT_ACTION_UNENROLL = 'Unenroll';

    /**
     * @description Enrollment Action - Unenroll
     */
    public static final String ENROLLMENT_ACTION_UNENROLLREQUESTED = 'UnenrollRequested';

    /**
     * @description Enrollment Action - JoinWaitList
     */
    public static final String ENROLLMENT_ACTION_JOINWAITLIST = 'JoinWaitList';

    /**
     * @description Enrollment Action - WithdrawWaitList
     */
    public static final String ENROLLMENT_ACTION_WITHDRAWWAITLIST = 'WithdrawWaitList';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Individual_Session_Enrollment__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Individual_Session_Enrollment__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Individual_Session_Enrollment__c.getName();
    }
	
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Session_Enrollment__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description RecordTypeInfo map
     */
    private static Map<String, Schema.RecordTypeInfo> rtMap;

    /**
     * @description Return record type map by developername
     * @return Map<String, Schema.RecordTypeInfo>
     */
    global static Map<String, Schema.RecordTypeInfo> getRecordTypes() {
        if (rtMap == null) {
            rtMap = Schema.SObjectType.reduivy__Individual_Session_Enrollment__c.getRecordtypeInfosByDeveloperName();
        }

        return rtMap;
    }

    /**
     * @description Return student record type id
     * @return Id
     */
    global static Id getStudentRecordTypeId() {
        return getRecordTypes().get('Student').getRecordTypeId();
    }

    /**
     * @description Return student record type UI label
     * @return String
     */
    global static String getStudentRecordTypeLabel() {
        return getRecordTypes().get('Student').getName();
    }

    /**
     * @description Return faculty record type id
     * @return Id
     */
    global static Id getFacultyRecordTypeId() {
        return getRecordTypes().get('Faculty').getRecordTypeId();
    }

    /**
     * @description Return faculty record type UI label
     * @return String
     */
    global static String getFacultyRecordTypeLabel() {
        return getRecordTypes().get('Faculty').getName();
    }

    /**
     * @description List of reduivy__IdvSn_Enrollment_Status_Config__mdt
     */
    private static List<reduivy__IdvSn_Enrollment_Status_Config__mdt> enrollmentStatusConfigs;

    /**
     * @description Enrollment status configs metadata sorted according to Enrollment Status field
     * @return List<reduivy__IdvSn_Enrollment_Status_Config__mdt>
     */
    public static List<reduivy__IdvSn_Enrollment_Status_Config__mdt> getEnrollmentStatusConfig(){

        if (enrollmentStatusConfigs == null) {
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Session_Enrollment__c.fields.reduivy__Enrollment_Status__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__IdvSn_Enrollment_Status_Config__mdt> configs = reduivy__IdvSn_Enrollment_Status_Config__mdt.getAll().values();
            List<reduivy__IdvSn_Enrollment_Status_Config__mdt> sortedConfigs = new List<reduivy__IdvSn_Enrollment_Status_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList) {
                if(ple.isActive()) {
                    for (reduivy__IdvSn_Enrollment_Status_Config__mdt config : configs) {
                        if (config.reduivy__Active__c && ple.getValue() == config.reduivy__Enrollment_Status__c) {
                            sortedConfigs.add(config);
                        }
                    }
                }
            }

            enrollmentStatusConfigs = sortedConfigs;
        }

        return enrollmentStatusConfigs;
    }

    /**
     * @description Open statuses
     */
    private static List<String> openStatuses;

    /*
     * @description Return a list of open enrollment status
     * @return List<String>
     */
    public static List<String> getOpenStatuses() {

        if (openStatuses == null) {
            openStatuses = new List<String>();

            for (reduivy__IdvSn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_OPEN) {
                    openStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return openStatuses;
    }

    /**
     * @description Enrollment Requested statuses
     */
    private static List<String> enrollmentRequestedStatuses;

    /*
     * @description Return a list of enrollment requested enrollment status
     * @return List<String>
     */
    public static List<String> getEnrollmentRequestedStatuses() {

        if (enrollmentRequestedStatuses == null) {
            enrollmentRequestedStatuses = new List<String>();

            for (reduivy__IdvSn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_ENROLLMENT_REQUESTED) {
                    enrollmentRequestedStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return enrollmentRequestedStatuses;
    }
    
    /**
     * @description In Progress statuses
     */
    private static List<String> inProgressStatuses;

    /*
     * @description Return a list of in progress enrollment status
     * @return List<String>
     */
    public static List<String> getInProgressStatuses() {

        if (inProgressStatuses == null) {
            inProgressStatuses = new List<String>();

            for (reduivy__IdvSn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_INPROGRESS) {
                    inProgressStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return inProgressStatuses;
    }

    /**
     * @description Completed statuses
     */
    private static List<String> completedStatuses;

    /*
     * @description Return a list of completed enrollment status
     * @return List<String>
     */
    public static List<String> getCompletedStatuses() {

        if (completedStatuses == null) {
            completedStatuses = new List<String>();

            for (reduivy__IdvSn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_COMPLETED) {
                    completedStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return completedStatuses;
    }

    /**
     * @description Waitlisted statuses
     */
    private static List<String> waitlistedStatuses;

    /*
     * @description Return a list of waitlisted enrollment status
     * @return List<String>
     */
    public static List<String> getWaitlistedStatuses() {

        if (waitlistedStatuses == null) {
            waitlistedStatuses = new List<String>();

            for (reduivy__IdvSn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_WAITLISTED) {
                    waitlistedStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return waitlistedStatuses;
    }

    /**
     * @description Dropped statuses
     */
    private static List<String> droppedStatuses;

    /*
     * @description Return a list of dropped enrollment status
     * @return List<String>
     */
    public static List<String> getDroppedStatuses() {

        if (droppedStatuses == null) {
            droppedStatuses = new List<String>();

            for (reduivy__IdvSn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_DROPPED) {
                    droppedStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return droppedStatuses;
    }

    /**
     * @description Withdrawn statuses
     */
    private static List<String> withdrawnStatuses;

    /*
     * @description Return a list of withdrawn enrollment status
     * @return List<String>
     */
    public static List<String> getWithdrawnStatuses() {

        if (withdrawnStatuses == null) {
            withdrawnStatuses = new List<String>();

            for (reduivy__IdvSn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_WITHDRAWN) {
                    withdrawnStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return withdrawnStatuses;
    }

    /**
     * @description Include In Rollup statuses
     */
    private static Map<String, Set<String>> rollupStatusesByField;

    /**
     * @description 
     * @return   Map<Rollup_Field_API_Name, Set<ISN_statuses>>
     */
    global static Map<String, Set<String>> getRollupStatusesByField(){
        if(rollupStatusesByField == null){
            rollupStatusesByField = new Map<String, Set<String>>();

            for(reduivy__IdvSn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if(config.reduivy__Include_In_Rollup__c && String.isNotBlank(config.reduivy__Rollup_Field_API_Name__c)) {
                    List<String> rollupFieldList = config.reduivy__Rollup_Field_API_Name__c.split(REDU_List_UTIL.DELIMITER);
                    for(String field : rollupFieldList){
                        if(!rollupStatusesByField.containsKey(field)) {
                            rollupStatusesByField.put(field, new Set<String>());
                        }
                        rollupStatusesByField.get(field).add(config.reduivy__Enrollment_Status__c);
                    }
                }
            }
        }

        return rollupStatusesByField;
    }

    /**
     * @description Include In Rollup statuses
     */
    private static Map<String, Set<String>> rollupFieldsApiNameByStatus;

    /**
     * @description 
     * @return   Map<ISN_statuses, Set<Rollup_Field_API_Name>>
     */
    global static Map<String, Set<String>> getRollupFieldsApiNameByStatus(){
        if(rollupFieldsApiNameByStatus == null){
            rollupFieldsApiNameByStatus = new Map<String, Set<String>>();

            for(reduivy__IdvSn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if(config.reduivy__Include_In_Rollup__c && String.isNotBlank(config.reduivy__Rollup_Field_API_Name__c)) {
                    List<String> rollupFieldList = config.reduivy__Rollup_Field_API_Name__c.split(REDU_List_UTIL.DELIMITER);
                    rollupFieldsApiNameByStatus.put(config.reduivy__Enrollment_Status__c, new Set<String>(rollupFieldList));
                }
            }
        }

        return rollupFieldsApiNameByStatus;
    }



    /**
     * @description Return a map to match ien and isn enrollment statuses
     */
    private static Map<String, String> ienToIsnStatusMap;

    /**
     * @description Get map of individual session enrollment statuses
     * @return Map<String, String>
     */
    public static Map<String, String> getIenToIsnStatusMap() {
        
        if(ienToIsnStatusMap == null){

            Map<String, String> isnStatusMap = new Map<String, String>();
            List<reduivy__IdvEn_Enrollment_Status_Config__mdt> ienEnrollmentStatusConfigs = IEN_Helper.getEnrollmentStatusConfig();
    
            for (reduivy__IdvEn_Enrollment_Status_Config__mdt sc : ienEnrollmentStatusConfigs) {
    
                if (String.isNotBlank(sc.reduivy__Individual_Session_Enrollment_Status__c)) {
                    isnStatusMap.put(sc.reduivy__Enrollment_Status__c, sc.reduivy__Individual_Session_Enrollment_Status__c);
                }
            }

            ienToIsnStatusMap = isnStatusMap;
        }

        return ienToIsnStatusMap;
    }


    /**
     * @description link or create isn based on the given study event, ien id and contact id. <br>
     * The following field is required: reduivy__Study_Session_Time__r.reduivy__Study_Session__c
     * @param  eventToIenMap Map contains study event and ien id
     * @param  contactId     Faculty Id
     * @return               Map of study event and isn id
     */
    
     //TODO: map key changed from sev to id, need to introduce a new param / query for the sev
    public static Map<Id, Id> linkIsnRelationship(List<reduivy__Study_Event__c> sevList, Map<Id, Id> eventToIenMap, String contactId, List<String> facultyRoles) {

        Id facultyRecordTypeId = ISN_Helper.getFacultyRecordTypeId();
        String enrolledStatus = ISN_Helper.getInProgressStatuses().get(0);
        
        Map<Id, List<reduivy__Study_Event__c>> sessionToEventMap = new Map<Id, List<reduivy__Study_Event__c>>();
        Map<Id, Id> eventToIsnMap = new Map<Id, Id>();
        Map<Id, Id> sessionIdToIenMap = new Map<Id, Id>();

        for(reduivy__Study_Event__c evt: sevList){
            if (String.isNotBlank(evt.reduivy__Study_Session_Time__r.reduivy__Study_Session__c) && eventToIenMap.containsKey(evt.Id)) {
                Id studySessionId = evt.reduivy__Study_Session_Time__r.reduivy__Study_Session__c;

                if(sessionToEventMap.containsKey(studySessionId)) {
                    sessionToEventMap.get(studySessionId).add(evt);
                } else {
                    sessionToEventMap.put(studySessionId, new List<reduivy__Study_Event__c>{ evt });
                }

                sessionIdToIenMap.put(evt.reduivy__Study_Session_Time__r.reduivy__Study_Session__c, eventToIenMap.get(evt.Id));
            }
        }

        if (!sessionToEventMap.isEmpty()) {
            List<reduivy__Study_Session__c> studySessionForIsnNotFound = new List<reduivy__Study_Session__c>();
            Map<Id, List<reduivy__Study_Session__c>> sunIdToSseMap = new Map<Id, List<reduivy__Study_Session__c>>();
            Set<Id> studySessionIdSet = sessionToEventMap.keySet();
                
            for(reduivy__Study_Session__c studySession: [SELECT Id, 
                Name,
                reduivy__Study_Offering__r.reduivy__Study_Unit__c,
                (
                    SELECT Id FROM reduivy__Individual_Session_Enrollments__r
                    WHERE reduivy__Contact_Id__c =: contactId
                    AND RecordTypeId = :facultyRecordTypeId
                    ORDER BY CreatedDate
                    LIMIT 1
                )
                FROM reduivy__Study_Session__c
                WHERE Id IN :studySessionIdSet
                WITH USER_MODE
            ]){
                if(!studySession.reduivy__Individual_Session_Enrollments__r.isEmpty()){
                    Id isnId = studySession.reduivy__Individual_Session_Enrollments__r[0].Id;
                    
                    for(reduivy__Study_Event__c event: sessionToEventMap.get(studySession.Id)){
                        eventToIsnMap.put(event.Id, isnId);
                    }
                    
                } else {
                    studySessionForIsnNotFound.add(studySession);
                    if(!sunIdToSseMap.containsKey(studySession.reduivy__Study_Offering__r.reduivy__Study_Unit__c)) {
                        sunIdToSseMap.put(studySession.reduivy__Study_Offering__r.reduivy__Study_Unit__c, new List<reduivy__Study_Session__c>());
                    }
                    sunIdToSseMap.get(studySession.reduivy__Study_Offering__r.reduivy__Study_Unit__c).add(studySession);
                }
            }
        
            //create isn if isn is not found
            if(!studySessionForIsnNotFound.isEmpty()){
                //we query the qfa to populate the facultyRoles field
                Map<Id, reduivy__Qualified_Faculty__c> sseToQfaMap = new Map<Id, reduivy__Qualified_Faculty__c>();
                
                if(facultyRoles == null || facultyRoles.isEmpty()) {
                    for(reduivy__Qualified_Faculty__c qfa : [ SELECT Id,
                        reduivy__Faculty_Role__c
                        FROM reduivy__Qualified_Faculty__c
                        WHERE reduivy__Contact__c = :contactId
                        AND reduivy__Study_Unit__c IN :sunIdToSseMap.keySet()
                        WITH USER_MODE
                    ]) {
                        for(Id sunId : sunIdToSseMap.keySet()) {
                            for(reduivy__Study_Session__c sse : sunIdToSseMap.get(sunId)) {
                                sseToQfaMap.put(sse.Id, qfa);
                            }
                        }
                    }
                }
                
                List<reduivy__Individual_Session_Enrollment__c> isnListToInsert = new List<reduivy__Individual_Session_Enrollment__c>();
                for(reduivy__Study_Session__c studySession: studySessionForIsnNotFound){
                    
                    isnListToInsert.add( new reduivy__Individual_Session_Enrollment__c(
                        reduivy__Study_Session__c = studySession.Id,
                        reduivy__Individual_Enrollment__c = sessionIdToIenMap.get(studySession.Id),
                        RecordTypeId = facultyRecordTypeId,
                        reduivy__Enrollment_Status__c = enrolledStatus,
                        reduivy__Faculty_Role__c = (facultyRoles == null || facultyRoles.isEmpty()) ? sseToQfaMap.get(studySession.Id)?.reduivy__Faculty_Role__c : String.join(facultyRoles, ';')
                    ));
                }
                    
                if(!isnListToInsert.isEmpty()){
                    REDU_Logging_UTIL.debug('isnListToInsert', isnListToInsert);
                    REDU_Database_UTIL.doInsert(isnListToInsert);
                    
                    for(reduivy__Individual_Session_Enrollment__c insertedIsn : isnListToInsert){
                        for(reduivy__Study_Event__c studyEvent: sessionToEventMap.get(insertedIsn.reduivy__Study_Session__c)){
                            eventToIsnMap.put(studyEvent.Id, insertedIsn.Id);
                        }
                    }
                }
            }
        }

        return eventToIsnMap;
    }
    
}