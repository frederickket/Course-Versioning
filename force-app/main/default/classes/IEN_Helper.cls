/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Object Helper
 * @description Individual Enrollment object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002231 25-03-2025 Lean - Added deferred status
 * ISS-002445 07-05-2025 XiRouh - Added getDeferredStatuses() to getRetryStatuses()
 * ISS-002448 07-05-2025 XiRouh - Added getIncreaseAttemptNumberStatuses()
 * ISS-002395 26-05-2025 XiRouh - Added sortStudentIenBasedOnPriority()
 * ISS-002486 10-06-2025 XiRouh - Added getCompletedFailStatuses() and getCompletedPassStatuses(). Updated getCompletedStatuses() to return both completed pass and completed fail statuses. Updated getNonEnrollableStatuses() to return only completed pass statuses instead of both types of completed statuses
 * ISS-002454 10-06-2025 XW - create getRollupStatusesByField and getRollupFieldsApiNameByStatus for configurable ien rollup field
 * ISS-002580 08-08-2025 XiRouh - Added getIncludeInFeeStatuses()
 * ISS-002743 15-12-2025 XiRouh - Updated sortStudentIenBasedOnPriority() to use IPF-based grouping instead of Contact-based grouping
 * ISS-002783 28-01-2026 Lean - Added shared method to identify best attempted ien
 * ISS-002513 09-02-2026 XiRouh - Added shared methods related to auto recognition cloning automation
 */
global inherited sharing class IEN_Helper implements SObject_Helper {

    /**
     * @description Status Type - Open
     */
    global static final String STATUS_TYPE_OPEN = 'Open';

    /**
     * @description Status Type - Enrollment_Requested
     */
    global static final String STATUS_TYPE_ENROLLMENT_REQUESTED = 'Enrollment_Requested';

    /**

     * @description Status Type - In Progress
     */
    global static final String STATUS_TYPE_INPROGRESS = 'In_Progress';

    /**
     * @description Status Type - Completed
     */
    global static final String STATUS_TYPE_COMPLETED = 'Completed';

    /**
     * @description Status Type - Completed Fail
     */
    global static final String STATUS_TYPE_COMPLETED_FAIL = 'Completed_Fail';

    /**
     * @description Status Type - Waitlisted
     */
    global static final String STATUS_TYPE_WAITLISTED = 'Waitlisted';

    /**
     * @description Status Type - Dropped
     */
    global static final String STATUS_TYPE_DROPPED = 'Dropped';

    /**
     * @description Status Type - Deferred
     */
    global static final String STATUS_TYPE_DEFERRED = 'Deferred';

    /**
     * @description Status Type - Withdrawal_Requested
     */
    global static final String STATUS_TYPE_WITHDRAWN_REQUESTED = 'Withdrawal_Requested';

    /**
     * @description Status Type - Withdrawn
     */
    global static final String STATUS_TYPE_WITHDRAWN = 'Withdrawn';

    /**
     * @description Status Type - Withdrawn_Fail
     */
    global static final String STATUS_TYPE_WITHDRAWN_FAIL = 'Withdrawn_Fail';

    /**
     * @description Status Type - Non_Enrollable
     */
    global static final String STATUS_TYPE_NONENROLLABLE = 'Non_Enrollable';

    /**
     * @description Category - Required
     */
    global static final String CATEGORY_REQUIRED = 'Required';

    /**
     * @description Category - Optional
     */
    global static final String CATEGORY_OPTIONAL = 'Optional';

    /**
     * @description Grade Result Type - Pass
     */
    global static final String GRADE_RESULT_TYPE_PASS = 'Pass';

    /**
     * @description Grade Result Type - Fail
     */
    global static final String GRADE_RESULT_TYPE_FAIL = 'Fail';

    /**
     * @description Grade Result Type - RPL
     */
    global static final String GRADE_RESULT_TYPE_RPL = 'RPL';

    /**
     * @description Grade Result Type - Credit Transfer
     */
    global static final String GRADE_RESULT_TYPE_CREDITTRANSFER = 'Credit_Transfer';

    /**
     * @description Grade Result Type - Waive
     */
    global static final String GRADE_RESULT_TYPE_WAIVE = 'Waive';

    /**
     * @description Enrollment Type - Program
     */
    global static final String ENROLLMENT_TYPE_PROGRAM = 'Program';

    /**
     * @description Enrollment Type - Continuing Education
     */
    global static final String ENROLLMENT_TYPE_CONTINUINGEDUCATION = 'Continuing Education';

    /**i 
     * @description Attendance Requirement Met - Yes
     */
    global static final String ATTENDANCE_REQUIREMENT_MET_YES = 'Yes';

    /**
     * @description Attendance Requirement Met - No
     */
    global static final String ATTENDANCE_REQUIREMENT_MET_NO = 'No';

    /**
     * @description Credit Transfer Type - Auto Unit Recognition
     */
    global static final String CREDIT_TRANSFER_TYPE_AUTO_UNIT_RECOGNITION = 'Auto Unit Recognition';

    /**
     * @description Credit Transfer Type - Credit Transfer Application
     */
    global static final String CREDIT_TRANSFER_TYPE_CREDIT_TRANSFER_APPLICATION = 'Credit Transfer Application';

    /**
     * @description Grade Result Bypass Type - RPL, Credit Transfer, Waive
     */
    global static final Set<String> GRADE_RESULT_BYPASS_TYPES = new Set<String>{
        GRADE_RESULT_TYPE_RPL,
        GRADE_RESULT_TYPE_CREDITTRANSFER,
        GRADE_RESULT_TYPE_WAIVE
    };

    /**
     * @description Grade Release Status - Not Released
     */
    global static final String GRADE_RELEASE_STATUS_NOTRELEASED = 'Not Released';

    /**
     * @description Grade Release Status - Internal Release
     */
    global static final String GRADE_RELEASE_STATUS_INTERNALRELEASE = 'Internal Release';

    /**
     * @description Grade Release Status - Internal Audit
     */
    global static final String GRADE_RELEASE_STATUS_INTERNALAUDIT = 'Internal Audit';

    /**
     * @description Grade Release Status - Released
     */
    global static final String GRADE_RELEASE_STATUS_RELEASED = 'Released';

    /**
     * @description Enrollment Action - Enroll
     */
    global static final String ENROLLMENT_ACTION_ENROLL = 'Enroll';

    /**
     * @description Enrollment Action - EnrollRequested
     */
    global static final String ENROLLMENT_ACTION_ENROLLREQUESTED = 'EnrollRequested';

    /**
     * @description Enrollment Action - WithdrawEnrollRequested
     */
    global static final String ENROLLMENT_ACTION_WITHDRAWENROLLREQUESTED = 'WithdrawEnrollRequested';

    /**
     * @description Enrollment Action - Unenroll
     */
    global static final String ENROLLMENT_ACTION_UNENROLL = 'Unenroll';

    /**
     * @description Enrollment Action - Unenroll
     */
    global static final String ENROLLMENT_ACTION_UNENROLLREQUESTED = 'UnenrollRequested';

    /**
     * @description Enrollment Action - JoinWaitList
     */
    global static final String ENROLLMENT_ACTION_JOINWAITLIST = 'JoinWaitList';

    /**
     * @description Enrollment Action - WithdrawWaitList
     */
    global static final String ENROLLMENT_ACTION_WITHDRAWWAITLIST = 'WithdrawWaitList';
    
    /**
     * @description Study Session Enrollment Rules Status - Insufficient
     */ 
    global static final String SESSION_ENROLLMENT_RULE_STATUS_INSUFFICIENT = 'Insufficient';
    
    /**
     * @description Study Session Enrollment Rules Status - Sufficient
     */ 
    global static final String SESSION_ENROLLMENT_RULE_STATUS_SUFFICIENT = 'Sufficient';

    /**
     * @description Study Session Enrollment Rules Status - Over
     */ 
    global static final String SESSION_ENROLLMENT_RULE_STATUS_OVER = 'Over';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Individual_Enrollment__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Individual_Enrollment__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Individual_Enrollment__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Enrollment__c);

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
            rtMap = Schema.SObjectType.reduivy__Individual_Enrollment__c.getRecordtypeInfosByDeveloperName();
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
     * @description List of reduivy__IdvEn_Enrollment_Status_Config__mdt
     */
    private static List<reduivy__IdvEn_Enrollment_Status_Config__mdt> enrollmentStatusConfigs;

    /**
     * @description Enrollment status configs metadata sorted according to Enrollment Status field
     * @return List<reduivy__IdvEn_Enrollment_Status_Config__mdt>
     */
    public static List<reduivy__IdvEn_Enrollment_Status_Config__mdt> getEnrollmentStatusConfig(){

        if (enrollmentStatusConfigs == null) {
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Enrollment__c.fields.reduivy__Enrollment_Status__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__IdvEn_Enrollment_Status_Config__mdt> configs = reduivy__IdvEn_Enrollment_Status_Config__mdt.getAll().values();
            List<reduivy__IdvEn_Enrollment_Status_Config__mdt> sortedConfigs = new List<reduivy__IdvEn_Enrollment_Status_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList) {
                if(ple.isActive()) {
                    for (reduivy__IdvEn_Enrollment_Status_Config__mdt config : configs) {
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

            for (reduivy__IdvEn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
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

            for (reduivy__IdvEn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
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

            for (reduivy__IdvEn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_INPROGRESS) {
                    inProgressStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return inProgressStatuses;
    }

    /**
     * @description Completed Pass statuses
     */
    private static List<String> completedPassStatuses;

    /*
     * @description Return a list of completed pass enrollment status
     * @return List<String>
     */
    public static List<String> getCompletedPassStatuses() {

        if (completedPassStatuses == null) {
            completedPassStatuses = new List<String>();

            for (reduivy__IdvEn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_COMPLETED) {
                    completedPassStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return completedPassStatuses;
    }

    /**
     * @description Completed Fail statuses
     */
    private static List<String> completedFailStatuses;

    /*
     * @description Return a list of completed Fail enrollment status
     * @return List<String>
     */
    public static List<String> getCompletedFailStatuses() {

        if (completedFailStatuses == null) {
            completedFailStatuses = new List<String>();

            for (reduivy__IdvEn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_COMPLETED_FAIL) {
                    completedFailStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return completedFailStatuses;
    }

    /**
     * @description Return a list of completed statuses
     * @return List<String>
     */
    public static List<String> getCompletedStatuses() {
        
        List<String> statuses = new List<String>();

        statuses.addAll(getCompletedFailStatuses());
        statuses.addAll(getCompletedPassStatuses());

        return statuses;
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

            for (reduivy__IdvEn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
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

            for (reduivy__IdvEn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_DROPPED) {
                    droppedStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return droppedStatuses;
    }

    /**
     * @description Deferred statuses
     */
    private static List<String> deferredStatuses;

    /*
     * @description Return a list of deferred enrollment status
     * @return List<String>
     */
    public static List<String> getDeferredStatuses() {

        if (deferredStatuses == null) {
            deferredStatuses = new List<String>();

            for (reduivy__IdvEn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_DEFERRED) {
                    deferredStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return deferredStatuses;
    }

    /**
     * @description Withdrawal Requested statuses
     */
    private static List<String> withdrawalRequestedStatuses;

    /*
     * @description Return a list of withdrawn requested enrollment status
     * @return List<String>
     */
    public static List<String> getWithdrawalRequestedStatuses() {

        if (withdrawalRequestedStatuses == null) {
            withdrawalRequestedStatuses = new List<String>();

            for (reduivy__IdvEn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_WITHDRAWN_REQUESTED) {
                    withdrawalRequestedStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return withdrawalRequestedStatuses;
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

            for (reduivy__IdvEn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_WITHDRAWN) {
                    withdrawnStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return withdrawnStatuses;
    }

    /**
     * @description Withdrawn Fail statuses
     */
    private static List<String> withdrawnFailStatuses;

    /*
     * @description Return a list of withdrawn fail enrollment status
     * @return List<String>
     */
    public static List<String> getWithdrawnFailStatuses() {

        if (withdrawnFailStatuses == null) {
            withdrawnFailStatuses = new List<String>();

            for (reduivy__IdvEn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_WITHDRAWN_FAIL) {
                    withdrawnFailStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return withdrawnFailStatuses;
    }

    /**
     * @description Increase Attempt Number Statuses
     */
    private static List<String> increaseAttmptNumberStatuses;

    /*
     * @description Return a list of enrollment status that should increase the attempt number
     * @return List<String>
     */
    public static List<String> getIncreaseAttemptNumberStatuses() {

        if (increaseAttmptNumberStatuses == null) {
            increaseAttmptNumberStatuses = new List<String>();

            for (reduivy__IdvEn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (config.reduivy__Increase_Attempt_Number__c == true) {
                    increaseAttmptNumberStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return increaseAttmptNumberStatuses;
    }

    /**
     * @description Include In Fee Statuses
     */
    private static List<String> includeInFeeStatuses;

    /*
     * @description Return a list of enrollment status that should include in fee
     * @return List<String>
     */
    public static List<String> getIncludeInFeeStatuses() {

        if (includeInFeeStatuses == null) {
            includeInFeeStatuses = new List<String>();

            for (reduivy__IdvEn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (config.reduivy__Include_In_Fee__c == true) {
                    includeInFeeStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return includeInFeeStatuses;
    }


    /**
     * @description Status Priority Map
     */
    private static Map<String, Integer> statusPriorityMap;

    /*
     * @description Return a map of status
     * @return Map<String, Integer> 
     */
    public static Map<String, Integer> getStatusPriorityMap() {

        if (statusPriorityMap == null) {
            statusPriorityMap = new Map<String, Integer>();

            for (reduivy__IdvEn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if (String.isNotBlank(config.reduivy__Enrollment_Status__c) && config.reduivy__IPS_Assignment_Priority__c != null) {
                    String key = constructStatusKey(config.reduivy__Enrollment_Status__c, config.reduivy__Grade_Result__c);
                    statusPriorityMap.put(key, (Integer)config.reduivy__IPS_Assignment_Priority__c);
                }
            }
        }
        
        return statusPriorityMap;
    }

    /**
     * @description Construct the map key from enrollment status and grade result
     */
    public static String constructStatusKey(String enrollmentStatus, String gradeResult) {
        return enrollmentStatus + '__' + (String.isBlank(gradeResult) ? 'null' : gradeResult);
    }

    /**
     * @description Assigns the most suitable IEN for each IPF's study unit, based on the reassignment rules and prioritized according to the defined precedence
     * The following field is required: reduivy__Enrollment_Status__c, reduivy__Grade_Result__c, reduivy__Individual_Academic_Profile__c, reduivy__Target_Unit_Id__c
     * This method will only compare priority values. Other sorting criteria, such as the highest attempt number, dates, or any additional fields, should be handled in the query or by the method that calls this one.
     * @param  ienList Individual Enrollment Record List
     * @return  Map<Id, Map<Id, reduivy__Individual_Enrollment__c>> : Map<IPF Id, Map<Study Unit Id, reduivy__Individual_Enrollment__c>>
     */
    public static Map<Id, Map<Id, reduivy__Individual_Enrollment__c>> sortStudentIenBasedOnPriority(List<reduivy__Individual_Enrollment__c> ienList) {

        Map<Id, Map<Id, reduivy__Individual_Enrollment__c>> ipfIdWithIen = new Map<Id, Map<Id, reduivy__Individual_Enrollment__c>>();
        Map<String, Integer> statusPriorityMap = IEN_Helper.getStatusPriorityMap();

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Individual_Enrollment__c.reduivy__Attempt_Number__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsLast),
            new REDU_SObjectComparator.SortCriterion(reduivy__Individual_Enrollment__c.reduivy__Start_Date__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsLast),
            new REDU_SObjectComparator.SortCriterion(reduivy__Individual_Enrollment__c.reduivy__Enrollment_Date__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsLast),
            new REDU_SObjectComparator.SortCriterion(reduivy__Individual_Enrollment__c.CreatedDate, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsLast)
        };

        ienList.sort(new REDU_SObjectComparator(criteria));

        REDU_Logging_UTIL.debugJsonString('ienList.sort()', ienList);

        if(!ienList.isEmpty()) {
            for(reduivy__Individual_Enrollment__c ien : ienList) {
                Id ipfId = ien.reduivy__Individual_Academic_Profile__c;
                Id sunId = ien.reduivy__Target_Unit_Id__c;

                // Skip if IPF is not set
                if (String.isBlank(ipfId)) {
                    continue;
                }

                String priorityKey = constructStatusKey(ien.reduivy__Enrollment_Status__c, ien.reduivy__Grade_Result__c);

                if (!statusPriorityMap.containsKey(priorityKey)) {
                    continue;
                } //We will skip the ien if its status_grade result is not configured in the custom metadata

                Integer priority = statusPriorityMap.get(priorityKey);

                if (!ipfIdWithIen.containsKey(ipfId)) {
                    ipfIdWithIen.put(ipfId, new Map<Id, reduivy__Individual_Enrollment__c>());
                }

                Map<Id, reduivy__Individual_Enrollment__c> ienBySun = ipfIdWithIen.get(ipfId);

                //Compare and assign if needed
                if (!ienBySun.containsKey(sunId)) {
                    ienBySun.put(sunId, ien); //first IEN for this IPF+SUN
                } else {
                    reduivy__Individual_Enrollment__c existingIen = ienBySun.get(sunId);

                    String existingPriorityKey = constructStatusKey(existingIen.reduivy__Enrollment_Status__c, existingIen.reduivy__Grade_Result__c);
                        
                    Integer existingPriority = statusPriorityMap.get(existingPriorityKey);

                    if (priority < existingPriority) {
                        ienBySun.put(sunId, ien); 
                    }
                }
            }
        }

        return ipfIdWithIen;
    }

    /**
     * @description Return a list of non enrollable statuses
     * @return List<String>
     */
    public static List<String> getNonEnrollableStatuses() {
        
        List<String> statuses = new List<String>();

        statuses.addAll(getInProgressStatuses());
        statuses.addAll(getWithdrawalRequestedStatuses());
        statuses.addAll(getCompletedPassStatuses());

        return statuses;
    }

    /**
     * @description Return a list of statuses for retry
     * @return List<String>
     */
    public static List<String> getRetryStatuses() {

        List<String> statuses = new List<String>();

        statuses.addAll(getDroppedStatuses());
        statuses.addAll(getWithdrawnFailStatuses());
        statuses.addAll(getWithdrawnStatuses());
        statuses.addAll(getDeferredStatuses());

        return statuses;
    }

    /**
     * @description List of reduivy__Grade_Result_Config__mdt
     */
    private static List<reduivy__Grade_Result_Config__mdt> gradeResultConfigs;

    /**
     * @description Grade result configs metadata sorted according to Grade Result field
     * @return List<reduivy__Grade_Result_Config__mdt>
     */
    public static List<reduivy__Grade_Result_Config__mdt> getGradeResultConfig(){

        if (gradeResultConfigs == null) {
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Enrollment__c.fields.reduivy__Grade_Result__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__Grade_Result_Config__mdt> configs = reduivy__Grade_Result_Config__mdt.getAll().values();
            List<reduivy__Grade_Result_Config__mdt> sortedConfigs = new List<reduivy__Grade_Result_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList) {
                if(ple.isActive()) {
                    for (reduivy__Grade_Result_Config__mdt config : configs) {
                        if (config.reduivy__Active__c && ple.getValue() == config.reduivy__Grade_Result__c) {
                            sortedConfigs.add(config);
                        }
                    }
                }
            }

            gradeResultConfigs = sortedConfigs;
        }

        return gradeResultConfigs;
    }

    /**
     * @description Grade Result = Pass statuses
     */
    private static List<String> gradeResultPassStatuses;

    /*
     * @description Return a list of grade result pass status
     * @return List<String>
     */
    public static List<String> getGradeResultPassStatuses() {

        if (gradeResultPassStatuses == null) {
            gradeResultPassStatuses = new List<String>();

            for (reduivy__Grade_Result_Config__mdt config : getGradeResultConfig()) {
                if (config.reduivy__Type__c == GRADE_RESULT_TYPE_PASS) {
                    gradeResultPassStatuses.add(config.reduivy__Grade_Result__c);
                }
            }
        }

        return gradeResultPassStatuses;
    }

    /**
     * @description Grade Result = Fail statuses
     */
    private static List<String> gradeResultFailStatuses;

    /*
     * @description Return a list of grade result fail status
     * @return List<String>
     */
    public static List<String> getGradeResultFailStatuses() {

        if (gradeResultFailStatuses == null) {
            gradeResultFailStatuses = new List<String>();

            for (reduivy__Grade_Result_Config__mdt config : getGradeResultConfig()) {
                if (config.reduivy__Type__c == GRADE_RESULT_TYPE_FAIL) {
                    gradeResultFailStatuses.add(config.reduivy__Grade_Result__c);
                }
            }
        }

        return gradeResultFailStatuses;
    }

    /**
     * @description Grade Result = RPL statuses
     */
    private static List<String> gradeResultRplStatuses;

    /*
     * @description Return a list of grade result RPL status
     * @return List<String>
     */
    public static List<String> getGradeResultRplStatuses() {

        if (gradeResultRplStatuses == null) {
            gradeResultRplStatuses = new List<String>();

            for (reduivy__Grade_Result_Config__mdt config : getGradeResultConfig()) {
                if (config.reduivy__Type__c == GRADE_RESULT_TYPE_RPL) {
                    gradeResultRplStatuses.add(config.reduivy__Grade_Result__c);
                }
            }
        }

        return gradeResultRplStatuses;
    }

    /**
     * @description Grade Result = Credit Transfer statuses
     */
    private static List<String> gradeResultCreditTransferStatuses;

    /*
     * @description Return a list of grade result credit transfer status
     * @return List<String>
     */
    public static List<String> getGradeResultCreditTransferStatuses() {

        if (gradeResultCreditTransferStatuses == null) {
            gradeResultCreditTransferStatuses = new List<String>();

            for (reduivy__Grade_Result_Config__mdt config : getGradeResultConfig()) {
                if (config.reduivy__Type__c == GRADE_RESULT_TYPE_CREDITTRANSFER) {
                    gradeResultCreditTransferStatuses.add(config.reduivy__Grade_Result__c);
                }
            }
        }

        return gradeResultCreditTransferStatuses;
    }

    /**
     * @description Grade Result = Waive statuses
     */
    private static List<String> gradeResultWaiveStatuses;

    /*
     * @description Return a list of grade result waive status
     * @return List<String>
     */
    public static List<String> getGradeResultWaiveStatuses() {

        if (gradeResultWaiveStatuses == null) {
            gradeResultWaiveStatuses = new List<String>();

            for (reduivy__Grade_Result_Config__mdt config : getGradeResultConfig()) {
                if (config.reduivy__Type__c == GRADE_RESULT_TYPE_WAIVE) {
                    gradeResultWaiveStatuses.add(config.reduivy__Grade_Result__c);
                }
            }
        }

        return gradeResultWaiveStatuses;
    }

    /**
     * @description Grade Result = By pass type
     */
    private static List<String> gradeResultByPassStatuses;

    /*
     * @description Return a list of grade result bypass status
     * @return List<String>
     */
    public static List<String> getGradeResultBypassStatuses() {

        if (gradeResultByPassStatuses == null) {
            gradeResultByPassStatuses = new List<String>();

            for (reduivy__Grade_Result_Config__mdt config : getGradeResultConfig()) {
                if (GRADE_RESULT_BYPASS_TYPES.contains(config.reduivy__Type__c)) {
                    gradeResultByPassStatuses.add(config.reduivy__Grade_Result__c);
                }
            }
        }

        return gradeResultByPassStatuses;
    }

    /**
     * @description Grade result = positive type
     */
    private static List<String> gradeResultPositiveStatuses;

    /**
     * @description Return a list of positive grade result status e.g., Pass, RPL, Waive, Credit Transfer
     * @return List<String>
     */
    public static List<String> getGradeResultPositiveStatuses() {
        
        if (gradeResultPositiveStatuses == null) {
            gradeResultPositiveStatuses = new List<String>();
            gradeResultPositiveStatuses.addAll(getGradeResultBypassStatuses());
            gradeResultPositiveStatuses.addAll(getGradeResultPassStatuses());
        }

        return gradeResultPositiveStatuses;
    }

    /**
     * @description Return a list of grade release statuses that soft release e.g., for internal only
     * @return List<String>
     */
    public static List<String> getInternalGradeReleasedStatuses() {
        
        return new List<String>{GRADE_RELEASE_STATUS_INTERNALAUDIT, GRADE_RELEASE_STATUS_INTERNALRELEASE};
    }

    /**
     * @description Return a list of grade release statuses that final release e.g., for everyone including students
     * @return List<String>
     */
    public static List<String> getFinalGradeReleasedStatuses() {
        
        return new List<String>{GRADE_RELEASE_STATUS_RELEASED};
    }

    /**
     * @description Return a list of grade release statuses that are eligible for completion engine
     * @return List<String>
     */
    public static List<String> getGradeReleasedStatuses() {

        List<String> statuses = new List<String>();
        statuses.addAll(getInternalGradeReleasedStatuses());
        statuses.addAll(getFinalGradeReleasedStatuses());

        return statuses;
    }

    
    /**
     * @description link or create Ien for the study event and faculty <br>
     * The following field is required: reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__c
     * @param  parentStudyEvents affected study events
     * @param  contactId         Contact Id that will be assigned into
     * @return                   Map of Study event id and ien id
     */
    public static Map<Id, Id> linkIenRelationship(List<reduivy__Study_Event__c> parentStudyEvents, String contactId){

        Id facultyRecordTypeId = IEN_Helper.getFacultyRecordTypeId();
        String enrolledStatus = IEN_Helper.getInProgressStatuses().get(0);

        Map<Id, List<reduivy__Study_Event__c>> offeringToEventMap = new Map<Id, List<reduivy__Study_Event__c>>();
        Map<Id, Id> eventToIenMap = new Map<Id, Id>();
        
        //map sof and sev together
        for(reduivy__Study_Event__c evt: parentStudyEvents){
            if (String.isNotBlank(evt.reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__c)) {
                Id offeringId = evt.reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__c;

                //A study offering can have more than one study event
                if(offeringToEventMap.containsKey(offeringId)){
                    offeringToEventMap.get(offeringId).add(evt);
                } else {
                    offeringToEventMap.put(offeringId, new List<reduivy__Study_Event__c> {evt});
                }
            }
        }

        if (!offeringToEventMap.isEmpty()) {
            //Sof id will be removed if found
            Set<Id> studyOfferingWithoutIen = offeringToEventMap.keySet();
            List<reduivy__Study_Offering__c> existingSofList = [SELECT Id, (
                    SELECT Id, Name FROM reduivy__Individual_Enrollments__r
                    WHERE reduivy__Contact__c = :contactId
                    AND RecordTypeId = :facultyRecordTypeId
                    ORDER BY CreatedDate
                    LIMIT 1
                )
                FROM reduivy__Study_Offering__c
                WHERE Id IN :offeringToEventMap.keySet()
                WITH USER_MODE
            ];

            for(reduivy__Study_Offering__c offering: existingSofList){
                //Map sev id and ien id if found
                if(!offering.reduivy__Individual_Enrollments__r.isEmpty()){
                    Id ienId = offering.reduivy__Individual_Enrollments__r[0].Id;

                    for(reduivy__Study_Event__c event: offeringToEventMap.get(offering.Id)){
                        eventToIenMap.put(event.Id, ienId);
                    }

                    studyOfferingWithoutIen.remove(offering.Id);
                }
            }

            //create ien if ien is not found
            if(!studyOfferingWithoutIen.isEmpty()){
                List<reduivy__Individual_Enrollment__c> ienListToInsert = new List<reduivy__Individual_Enrollment__c>();
                for(Id offeringId: studyOfferingWithoutIen){
                    ienListToInsert.add( new reduivy__Individual_Enrollment__c(
                        reduivy__Contact__c = contactId,
                        reduivy__Study_Offering__c = offeringId,
                        RecordTypeId = facultyRecordTypeId,
                        reduivy__Enrollment_Status__c = enrolledStatus
                    ));
                }

                if(!ienListToInsert.isEmpty()){
                    REDU_Logging_UTIL.debug('ienListToInsert', ienListToInsert);
                    REDU_Database_UTIL.doInsert(ienListToInsert);

                    //Map sev id and new created ien id
                    for (reduivy__Individual_Enrollment__c insertedIen : ienListToInsert) {
                        for(reduivy__Study_Event__c studyEvent: offeringToEventMap.get(insertedIen.reduivy__Study_Offering__c)){
                            eventToIenMap.put(studyEvent.Id, insertedIen.Id);
                        }
                    }

                }
            }
        }

        return eventToIenMap;
    }

    
    /**
     * @description Include In Rollup statuses
     */
    private static Map<String, Set<String>> rollupStatusesByField;

    /**
     * @description 
     * @return   Map<Rollup_Field_API_Name, Set<IEN_statuses>>
     */
    global static Map<String, Set<String>> getRollupStatusesByField(){
        if(rollupStatusesByField == null){
            rollupStatusesByField = new Map<String, Set<String>>();

            for(reduivy__IdvEn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
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
     * @return   Map<IEN_statuses, Set<Rollup_Field_API_Name>>
     */
    global static Map<String, Set<String>> getRollupFieldsApiNameByStatus(){
        if(rollupFieldsApiNameByStatus == null){
            rollupFieldsApiNameByStatus = new Map<String, Set<String>>();

            for(reduivy__IdvEn_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()) {
                if(config.reduivy__Include_In_Rollup__c && String.isNotBlank(config.reduivy__Rollup_Field_API_Name__c)) {
                    List<String> rollupFieldList = config.reduivy__Rollup_Field_API_Name__c.split(REDU_List_UTIL.DELIMITER);
                    rollupFieldsApiNameByStatus.put(config.reduivy__Enrollment_Status__c, new Set<String>(rollupFieldList));
                }
            }
        }

        return rollupFieldsApiNameByStatus;
    }

    /**
     * @description List of reduivy__Auto_Unit_Recognition_Config__mdt
     */
    private static List<reduivy__Auto_Unit_Recognition_Config__mdt> autoUnitRecognitionConfigs;

    /**
     * @description Auto Unit Recognition configs metadata sorted according to Enrollment Status field
     * @return List<reduivy__Auto_Unit_Recognition_Config__mdt>
     */
    public static List<reduivy__Auto_Unit_Recognition_Config__mdt> getAutoUnitRecognitionConfig(){

        if (autoUnitRecognitionConfigs == null) {
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Enrollment__c.fields.reduivy__Enrollment_Status__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__Auto_Unit_Recognition_Config__mdt> configs = reduivy__Auto_Unit_Recognition_Config__mdt.getAll().values();
            List<reduivy__Auto_Unit_Recognition_Config__mdt> sortedConfigs = new List<reduivy__Auto_Unit_Recognition_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList) {
                if(ple.isActive()) {
                    for (reduivy__Auto_Unit_Recognition_Config__mdt config : configs) {
                        if (config.reduivy__Active__c && ple.getValue() == config.reduivy__Enrollment_Status__c) {
                            sortedConfigs.add(config);
                        }
                    }
                }
            }

            autoUnitRecognitionConfigs = sortedConfigs;
        }

        return autoUnitRecognitionConfigs;
    }

    /**
     * @description Unit Recognition Status Grade Map
     */
    private static Map<String, Set<String>> unitRecognitionStatusGradeMap;

    /**
     * @description Auto Unit Recognition Config Enrollment Status With Grade Result Map
     * @return Map<Enrollment Status, Set<Grade Result>>
     */
    public static Map<String, Set<String>> getUnitRecognitionStatusGradeMap(){
        if(unitRecognitionStatusGradeMap == null){
            unitRecognitionStatusGradeMap = new Map<String, Set<String>>();

            for(reduivy__Auto_Unit_Recognition_Config__mdt config : getAutoUnitRecognitionConfig()) {
                if(unitRecognitionStatusGradeMap.containsKey(config.reduivy__Enrollment_Status__c)) {
                    unitRecognitionStatusGradeMap.get(config.reduivy__Enrollment_Status__c).add(config.reduivy__Grade_Result__c);
                } else {
                    unitRecognitionStatusGradeMap.put(config.reduivy__Enrollment_Status__c, new Set<String>{config.reduivy__Grade_Result__c});
                }
            }
        }

        return unitRecognitionStatusGradeMap;
    }

    /**
     * @description Map of Auto Unit Recognition Config by Enrollment Status and Grade Result
     * Key format: "EnrollmentStatus_GradeResult"
     */
    private static Map<String, reduivy__Auto_Unit_Recognition_Config__mdt> statusGradeToConfigMap;

    /**
     * @description Get Auto Unit Recognition Config by Enrollment Status and Grade Result
     * @return Map<String, reduivy__Auto_Unit_Recognition_Config__mdt>
     */
    public static Map<String, reduivy__Auto_Unit_Recognition_Config__mdt> getStatusGradeToConfigMap(){
        if(statusGradeToConfigMap == null){
            statusGradeToConfigMap = new Map<String, reduivy__Auto_Unit_Recognition_Config__mdt>();

            for(reduivy__Auto_Unit_Recognition_Config__mdt config : getAutoUnitRecognitionConfig()) {
                String key = config.reduivy__Enrollment_Status__c + '_' + config.reduivy__Grade_Result__c;
                statusGradeToConfigMap.put(key, config);
            }
        }

        return statusGradeToConfigMap;
    }

    /**
     * @description List of all active Auto Unit Recognition Mappings
     */
    private static List<reduivy__Auto_Unit_Recognition_Mapping__mdt> autoUnitRecognitionMappings;

    /**
     * @description Get all active Auto Unit Recognition Mapping records
     * @return List<reduivy__Auto_Unit_Recognition_Mapping__mdt>
     */
    public static List<reduivy__Auto_Unit_Recognition_Mapping__mdt> getAutoUnitRecognitionMappings(){
        if(autoUnitRecognitionMappings == null){
            autoUnitRecognitionMappings = new List<reduivy__Auto_Unit_Recognition_Mapping__mdt>();

            for(reduivy__Auto_Unit_Recognition_Mapping__mdt mapping : reduivy__Auto_Unit_Recognition_Mapping__mdt.getAll().values()) {
                if(mapping.reduivy__Active__c) {
                    autoUnitRecognitionMappings.add(mapping);
                }
            }
        }

        return autoUnitRecognitionMappings;
    }

    /**
     * @description Map of Auto Unit Recognition Mappings grouped by Config Id
     * Key: Config Id, Value: List of Mapping records
     */
    private static Map<Id, List<reduivy__Auto_Unit_Recognition_Mapping__mdt>> configIdToMappingsMap;

    /**
     * @description Get Auto Unit Recognition Mappings grouped by Config Id
     * @return Map<Id, List<reduivy__Auto_Unit_Recognition_Mapping__mdt>>
     */
    public static Map<Id, List<reduivy__Auto_Unit_Recognition_Mapping__mdt>> getConfigIdToMappingsMap(){
        if(configIdToMappingsMap == null){
            configIdToMappingsMap = new Map<Id, List<reduivy__Auto_Unit_Recognition_Mapping__mdt>>();

            for(reduivy__Auto_Unit_Recognition_Mapping__mdt mapping : getAutoUnitRecognitionMappings()) {
                Id configId = mapping.reduivy__Auto_Unit_Recognition_Config__c;
                
                if(String.isNotBlank(configId)) {
                    if(!configIdToMappingsMap.containsKey(configId)) {
                        configIdToMappingsMap.put(configId, new List<reduivy__Auto_Unit_Recognition_Mapping__mdt>());
                    }
                    configIdToMappingsMap.get(configId).add(mapping);
                }
            }
        }

        return configIdToMappingsMap;
    }

    /**
     * @description Get Auto Unit Recognition Config for a specific Enrollment Status and Grade Result
     * @param enrollmentStatus Enrollment Status value
     * @param gradeResult Grade Result value
     * @return reduivy__Auto_Unit_Recognition_Config__mdt
     */
    public static reduivy__Auto_Unit_Recognition_Config__mdt getAutoUnitRecognitionConfigByStatusGrade(String enrollmentStatus, String gradeResult){
        String key = enrollmentStatus + '_' + gradeResult;
        return getStatusGradeToConfigMap().get(key);
    }

    /**
     * @description Get Auto Unit Recognition Mappings for a specific Config
     * @param configId Config Id
     * @return List<reduivy__Auto_Unit_Recognition_Mapping__mdt>
     */
    public static List<reduivy__Auto_Unit_Recognition_Mapping__mdt> getMappingsForConfig(Id configId){
        Map<Id, List<reduivy__Auto_Unit_Recognition_Mapping__mdt>> mappingMap = getConfigIdToMappingsMap();

        return mappingMap.containsKey(configId) ? mappingMap.get(configId) : new List<reduivy__Auto_Unit_Recognition_Mapping__mdt>();
    }

    /**
     * @description Create cloned IENs based on cloning requests
     * @param cloningRequestMap targetIpfId_studyUnitId, source IEN
     * @param sourceIensWithAllFields Map of source IEN IDs to fully queried IEN records
     * @param existingIenMap Map of existing non-enrollable IENs
     * @param statusGradeToMappingData Map of status_grade to mapping configuration
     * @param existingUpdateableIenToUpdate Map of request keys to List of existing updateable IEN IDs that should be updated
     * @return Map<String, List<reduivy__Individual_Enrollment__c>> Map of request key to list of cloned IENs (may include multiple if updating existing records)
     */
    public static Map<String, List<reduivy__Individual_Enrollment__c>> prepareClonedIens(
        Map<String, reduivy__Individual_Enrollment__c> cloningRequestMap, 
        Map<Id, reduivy__Individual_Enrollment__c> sourceIensWithAllFields, 
        Map<String, reduivy__Individual_Enrollment__c> existingIenMap, 
        Map<String, AutoRecognitionMappingConfig> statusGradeToMappingData,
        Map<String, List<Id>> existingUpdateableIenToUpdate
    ) {
        if(cloningRequestMap.isEmpty()) {
            return new Map<String, List<reduivy__Individual_Enrollment__c>>();
        }

        // Create cloned IENs - now returns List per request key
        Map<String, List<reduivy__Individual_Enrollment__c>> clonedIensMap = new Map<String, List<reduivy__Individual_Enrollment__c>>();

        for(String requestKey : cloningRequestMap.keySet()) {
            // Skip if non-enrollable IEN already exists + no existing updateable IENs to update
            if(existingIenMap.containsKey(requestKey) && (existingUpdateableIenToUpdate == null || (existingUpdateableIenToUpdate != null && !existingUpdateableIenToUpdate.containsKey(requestKey)))) {
                continue;
            }

            // Parse request key
            List<String> parts = requestKey.split('_');
            Id targetIpfId = (Id)parts[0];
            Id studyUnitId = (Id)parts[1];

            reduivy__Individual_Enrollment__c sourceIen = cloningRequestMap.get(requestKey);
            
            // Get fully queried source IEN
            reduivy__Individual_Enrollment__c sourceIenWithAllFields = sourceIensWithAllFields.containsKey(sourceIen.Id) ? sourceIensWithAllFields.get(sourceIen.Id) : null;

            if(sourceIenWithAllFields == null) {
                continue;
            }

            List<reduivy__Individual_Enrollment__c> clonedIensForKey = new List<reduivy__Individual_Enrollment__c>();

            // Check if there are existing updateable IENs to update
            if(existingUpdateableIenToUpdate != null && existingUpdateableIenToUpdate.containsKey(requestKey)) {
                List<Id> existingIenIds = existingUpdateableIenToUpdate.get(requestKey);
                
                // Create a cloned IEN for each existing updateable IEN
                for(Id existingIenId : existingIenIds) {
                    reduivy__Individual_Enrollment__c clonedIen = createClonedIen(
                        existingIenId,
                        targetIpfId,
                        studyUnitId,
                        sourceIenWithAllFields,
                        statusGradeToMappingData
                    );
                    
                    if(clonedIen != null) {
                        clonedIensForKey.add(clonedIen);
                    }
                }
            } else {
                // No existing IENs, create new one
                reduivy__Individual_Enrollment__c clonedIen = createClonedIen(
                    null,
                    targetIpfId,
                    studyUnitId,
                    sourceIenWithAllFields,
                    statusGradeToMappingData
                );
                
                if(clonedIen != null) {
                    clonedIensForKey.add(clonedIen);
                }
            }

            if(!clonedIensForKey.isEmpty()) {
                clonedIensMap.put(requestKey, clonedIensForKey);
            }
        }

        return clonedIensMap;
    }

    /**
     * @description Helper method to create a single cloned IEN
     * @param existingIenId If not null, this IEN will be updated; if null, a new IEN will be created
     * @param targetIpfId Target IPF ID
     * @param studyUnitId Study Unit ID
     * @param sourceIenWithAllFields Fully queried source IEN
     * @param statusGradeToMappingData Map of status_grade to mapping configuration
     * @return reduivy__Individual_Enrollment__c Cloned IEN ready for upsert
     */
    private static reduivy__Individual_Enrollment__c createClonedIen(
        Id existingIenId,
        Id targetIpfId,
        Id studyUnitId,
        reduivy__Individual_Enrollment__c sourceIenWithAllFields,
        Map<String, AutoRecognitionMappingConfig> statusGradeToMappingData
    ) {
        if(sourceIenWithAllFields == null) {
            return null;
        }

        // Create cloned IEN
        reduivy__Individual_Enrollment__c clonedIen = new reduivy__Individual_Enrollment__c();
        
        // If updating existing IEN, set its Id
        if(existingIenId != null) {
            clonedIen.Id = existingIenId;
        }
        
        // Set core fields
        clonedIen.reduivy__Individual_Academic_Profile__c = targetIpfId;
        clonedIen.reduivy__Credit_Transfer_Type__c = CREDIT_TRANSFER_TYPE_AUTO_UNIT_RECOGNITION;
        clonedIen.reduivy__Study_Unit__c = studyUnitId;
        clonedIen.reduivy__Contact__c = sourceIenWithAllFields.reduivy__Contact__c;
        clonedIen.reduivy__Credit_Transfer_Received__c = true;
        clonedIen.reduivy__Credit_Transfer_Historical_Value__c = JSON.serialize(sourceIenWithAllFields);
        clonedIen.reduivy__Credit_Transfer_Date__c = System.now();
        clonedIen.RecordTypeId = getStudentRecordTypeId();

        // Apply mappings using pre-processed data
        String statusGradeKey = sourceIenWithAllFields.reduivy__Enrollment_Status__c + '_' + sourceIenWithAllFields.reduivy__Grade_Result__c;
        AutoRecognitionMappingConfig mappingData = statusGradeToMappingData.get(statusGradeKey);

        if(mappingData != null && !mappingData.AutoRecognitionFieldMappings.isEmpty()) {
            for(AutoRecognitionFieldMapping processed : mappingData.AutoRecognitionFieldMappings) {

                String finalValue;

                if(processed.isStatic) {
                    // Static value - use directly
                    finalValue = processed.staticValue;
                } else {
                    // Dynamic value - merge fields from source IEN
                    Map<String, String> mergeFieldValues = new Map<String, String>();

                    for(String mergeFieldKey : processed.mergeFields.keySet()) {
                        String sourceFieldPath = processed.mergeFields.get(mergeFieldKey);
                        Object fieldValue = REDU_SObject_UTIL.extractFieldValue(sourceIenWithAllFields, sourceFieldPath);
                        mergeFieldValues.put(sourceFieldPath, fieldValue != null ? String.valueOf(fieldValue) : '');
                    }

                    finalValue = REDU_StringMerge_UTIL.mergeValues(mergeFieldValues, processed.staticValue);
                }

                setFieldValueOnClone(clonedIen, processed.targetFieldApiName, finalValue, processed.fieldDescribe);
            }
        }

        return clonedIen;
    }

    /**
     * @description Processed mapping instruction for efficient batch application
     */
    private class AutoRecognitionFieldMapping {
        public String targetFieldApiName;
        public String staticValue;
        public Map<String, String> mergeFields;
        public Schema.DescribeFieldResult fieldDescribe;
        public Boolean isStatic;

        public AutoRecognitionFieldMapping(String fieldApiName, Schema.DescribeFieldResult describe) {
            this.targetFieldApiName = fieldApiName;
            this.fieldDescribe = describe;
            this.isStatic = true;
        }
    }

    /**
     * @description Complete mapping data with fields to query and processed mappings ready to use
     */
    public class AutoRecognitionMappingConfig {
        public Set<String> fieldsToQuery;
        public List<AutoRecognitionFieldMapping> AutoRecognitionFieldMappings;

        public AutoRecognitionMappingConfig() {
            this.fieldsToQuery = new Set<String>();
            this.AutoRecognitionFieldMappings = new List<AutoRecognitionFieldMapping>();
        }
    }

    /**
     * @description Cache for processed mappings - done once per status_grade combination
     */
    private static Map<String, AutoRecognitionMappingConfig> statusGradeMappingCache = new Map<String, AutoRecognitionMappingConfig>();

    /**
     * @description Prepare and process field mappings grouped by status_grade combination
     * @param sourceIens List of source Individual Enrollment records. If empty, processes ALL configured mappings.
     * @return Map<String, AutoRecognitionMappingConfig> Map of "status_grade" key to complete mapping data
     */
    public static Map<String, AutoRecognitionMappingConfig> prepareAutoRecognitionFieldMappings(List<reduivy__Individual_Enrollment__c> sourceIens) {
        Map<String, AutoRecognitionMappingConfig> result = new Map<String, AutoRecognitionMappingConfig>();

        try{
            // Get unique status_grade combinations
            Set<String> statusGradeCombinations = new Set<String>();
            
            if(sourceIens == null || sourceIens.isEmpty()) {
                // If empty list passed, process ALL configured status_grade combinations
                Map<String, reduivy__Auto_Unit_Recognition_Config__mdt> allConfigs = getStatusGradeToConfigMap();
                statusGradeCombinations.addAll(allConfigs.keySet());
            } else {
                // Process only the status_grade combinations from the provided IENs
                for(reduivy__Individual_Enrollment__c sourceIen : sourceIens) {
                    String key = sourceIen.reduivy__Enrollment_Status__c + '_' + sourceIen.reduivy__Grade_Result__c;
                    statusGradeCombinations.add(key);
                }
            }

            // Compile pattern for all combinations
            Pattern fieldPattern = Pattern.compile(REDU_StringMerge_UTIL.MERGEFIELD_SYNTAX_REGEX);

            // Process each unique status_grade combination
            for(String statusGradeKey : statusGradeCombinations) {
                if(statusGradeMappingCache.containsKey(statusGradeKey)) {
                    result.put(statusGradeKey, statusGradeMappingCache.get(statusGradeKey));
                    continue;
                }

                List<String> parts = statusGradeKey.split('_');
                String status = parts[0];
                String grade = parts.size() > 1 ? parts[1] : null;

                // Get config for this status_grade combination
                reduivy__Auto_Unit_Recognition_Config__mdt config = getAutoUnitRecognitionConfigByStatusGrade(status, grade);

                if(config == null) {
                    AutoRecognitionMappingConfig emptyData = new AutoRecognitionMappingConfig();
                    statusGradeMappingCache.put(statusGradeKey, emptyData);
                    result.put(statusGradeKey, emptyData);
                    continue;
                }

                AutoRecognitionMappingConfig mappingData = new AutoRecognitionMappingConfig();
                List<reduivy__Auto_Unit_Recognition_Mapping__mdt> mappings = getMappingsForConfig(config.Id);

                for(reduivy__Auto_Unit_Recognition_Mapping__mdt mapping : mappings) {
                    String targetFieldApiName = mapping.reduivy__Target_Field_API_Name__c;
                    String targetValue = mapping.reduivy__Value__c;

                    if(String.isBlank(targetFieldApiName) || String.isBlank(targetValue)) {
                        continue;
                    }

                    Schema.DescribeFieldResult targetFieldDescribe = REDU_Metadata_UTIL.describeSObjectField(getApiName(), targetFieldApiName);

                    AutoRecognitionFieldMapping processed = new AutoRecognitionFieldMapping(targetFieldApiName, targetFieldDescribe);

                    // Check if value contains merge fields
                    if(targetValue.contains(REDU_StringMerge_UTIL.MERGEFIELD_PREFIX) && 
                    targetValue.contains(REDU_StringMerge_UTIL.MERGEFIELD_POSTFIX)) {
                        
                        // Extract merge fields using pre-compiled pattern
                        processed.mergeFields = REDU_StringMerge_UTIL.extractFieldNames(fieldPattern, targetValue);
                        processed.staticValue = targetValue; // Store template for later merging
                        processed.isStatic = false;

                        // Add fields to query set
                        for(String mergeFieldKey : processed.mergeFields.keySet()) {
                            String fieldPath = processed.mergeFields.get(mergeFieldKey);
                            mappingData.fieldsToQuery.add(fieldPath);
                        }
                    } else {
                        // Static value
                        processed.staticValue = targetValue;
                        processed.isStatic = true;
                    }

                    mappingData.AutoRecognitionFieldMappings.add(processed);
                }

                statusGradeMappingCache.put(statusGradeKey, mappingData);
                result.put(statusGradeKey, mappingData);
            }
        } catch(Exception e) {
            throw new REDU_ApplicationException(e.getMessage());        
        }

        return result;
    }

    /**
     * @description Set field value on cloned IEN based on field type
     * @param clonedIen The cloned IEN
     * @param fieldApiName Field API name
     * @param value String value to set
     * @param fieldDescribe Field describe result
     */
    private static void setFieldValueOnClone(
        reduivy__Individual_Enrollment__c clonedIen,
        String fieldApiName,
        String value,
        Schema.DescribeFieldResult fieldDescribe
    ) {
        if(String.isBlank(value)) {
            clonedIen.put(fieldApiName, null);
            return;
        }

        try {
            Schema.DisplayType fieldType = fieldDescribe.getType();

            switch on fieldType {
                when STRING, TEXTAREA, PICKLIST, MULTIPICKLIST, EMAIL, PHONE, URL, COMBOBOX {
                    clonedIen.put(fieldApiName, value);
                }
                when BOOLEAN {
                    clonedIen.put(fieldApiName, Boolean.valueOf(value));
                }
                when INTEGER {
                    clonedIen.put(fieldApiName, Integer.valueOf(value));
                }
                when DOUBLE, CURRENCY, PERCENT {
                    clonedIen.put(fieldApiName, Decimal.valueOf(value));
                }
                when DATE {
                    DateTime tempDateTime = DateTime.valueOf(value);

                    clonedIen.put(fieldApiName, tempDateTime.dateGmt());
                }
                when DATETIME {
                    DateTime tempDateTime = DateTime.valueOf(value);

                    clonedIen.put(fieldApiName, tempDateTime);
                }
                when REFERENCE {
                    if(value instanceof Id) {
                        clonedIen.put(fieldApiName, (Id)value);
                    } else {
                        clonedIen.put(fieldApiName, value);
                    }
                }
                when else {
                    clonedIen.put(fieldApiName, value);
                }
            }
        } catch(Exception e) {
            throw new REDU_ApplicationException(
                String.format(Label.Error_Setting_Field,
                    new List<String>{fieldApiName, e.getMessage()})
            );
        }
    }

    /**
     * @description Check if an Individual Enrollment has become recognizable
     * @param ienNew New individual enrollment
     * @param ienOld Old individual enrollment
     * @return Boolean True if enrollment has become recognizable
     */
    public static Boolean isRecognizable(reduivy__Individual_Enrollment__c ienNew, reduivy__Individual_Enrollment__c ienOld) {

        Boolean wasRecognizable = (ienOld != null && getUnitRecognitionStatusGradeMap().keySet().contains(ienOld.reduivy__Enrollment_Status__c) && getUnitRecognitionStatusGradeMap().get(ienOld.reduivy__Enrollment_Status__c).contains(ienOld.reduivy__Grade_Result__c));
        Boolean isRecognizable = (ienNew != null && getUnitRecognitionStatusGradeMap().keySet().contains(ienNew.reduivy__Enrollment_Status__c) && getUnitRecognitionStatusGradeMap().get(ienNew.reduivy__Enrollment_Status__c).contains(ienNew.reduivy__Grade_Result__c));

        return isRecognizable && !wasRecognizable;
    }
    
    /*
     * @description Identify best attempt ien
     * @param currentIen The current individual enrollment
     * @param bestIen The current best attempted individual enrollment
     * @return Boolean
     */
    public static Boolean isCurrentBetterAttempt(reduivy__Individual_Enrollment__c currentIen, reduivy__Individual_Enrollment__c bestIen) {
        Boolean isBetter = false;

        if (currentIen == null || currentIen.reduivy__Exclude_GPA_Calculation__c || currentIen.reduivy__Grade_Release_Status__c != IEN_Helper.GRADE_RELEASE_STATUS_RELEASED) {
            return isBetter;
        }

        //ISS-002783 changed to use quality points
        if (bestIen == null && currentIen.reduivy__Quality_Points__c != null) {
            //get the first released ien as the best attempt
            isBetter = true;
            
        } else if (bestIen != null) {
            
            // we will consider the quality points, credits earned, final grade and start date when finding the best attempt
            Decimal currentIenQP = currentIen.reduivy__Quality_Points__c ?? 0;
            Decimal bestIenQP = bestIen.reduivy__Quality_Points__c ?? 0;
            if (currentIenQP > bestIenQP) {
                isBetter = true;

            } else if (currentIenQP == bestIenQP) {

                Decimal currentIenCE = (currentIen?.reduivy__Exclude_Credits_Earned__c ? 0 : (currentIen?.reduivy__Credits_Earned__c ?? 0));
                Decimal bestIenCE = (bestIen?.reduivy__Exclude_Credits_Earned__c ? 0 : (bestIen?.reduivy__Credits_Earned__c ?? 0));

                Decimal currentIenNG = (currentIen?.reduivy__Final_Numerical_Grade__c ?? 0);
                Decimal bestIenNG = (bestIen?.reduivy__Final_Numerical_Grade__c ?? 0);

                Date currentIenSD = (currentIen?.reduivy__Start_Date__c ?? null);
                Date bestIenSD = (bestIen?.reduivy__Start_Date__c ?? null);

                if (currentIenCE > bestIenCE) {
                    // Fallback 1: Credits Earned (Success vs Failure)
                    isBetter = true;

                } else if (currentIenCE == bestIenCE) {
                    if (currentIenNG > bestIenNG) {
                        // Fallback 2: Numerical Grade (Mastery check)
                        isBetter = true;

                    } else if (currentIenNG == bestIenNG) {
                        if (currentIenSD >= bestIenSD) {
                            // Fallback 3: Recency (Default to newest)
                            isBetter = true;
                        }
                    }
                }
            }
        }

        return isBetter;
    }

    public static Boolean isCurrentHigherCreditsEarned(reduivy__Individual_Enrollment__c currentIen, reduivy__Individual_Enrollment__c bestIen) {

        Boolean isHigher = false;

        if (currentIen == null || currentIen.reduivy__Exclude_Credits_Earned__c|| currentIen.reduivy__Grade_Release_Status__c != IEN_Helper.GRADE_RELEASE_STATUS_RELEASED) {
            return isHigher;
        }

        if (currentIen.reduivy__Best_Attempt__c || (bestIen?.reduivy__Exclude_Credits_Earned__c ?? true)) {
            isHigher = true;
        } else if (bestIen == null && currentIen.reduivy__Credits_Earned__c != null) {
            //get the first released ien as the best attempt
            isHigher = true;
            
        } else if (bestIen != null) {
            Decimal currentIenCE = currentIen.reduivy__Credits_Earned__c ?? 0;
            Decimal bestIenCE = bestIen.reduivy__Credits_Earned__c ?? 0;

            if (currentIenCE > bestIenCE && !bestIen.reduivy__Best_Attempt__c) {
                isHigher = true;
            }
        }

        return isHigher;
    }
}