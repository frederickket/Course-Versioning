/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Object Helper
 * @description Study Offering object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001918 06/08/2024 CM - Added Grade By picklist values
 */
global inherited sharing class SOF_Helper implements SObject_Helper {
    
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
     * @description Grade By - Study Offering
     */
    public static final String GRADE_BY_STUDYOFFERING = 'Study Offering';

    /**
     * @description Grade By - Study Session
     */
    public static final String GRADE_BY_STUDYSESSION = 'Study Session';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Offering__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Offering__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Offering__c.getName();
    }
    
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Offering__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Return fields for cloning
     */
    public static Set<String> getFieldsForCloning(){
        //Set the exclude the dates and rollup fields so that it won’t inherit from the parent, and the calculated field will inherit from the term record's date
        Set<String> sofFieldsToExclude = new Set<String>{
            'reduivy__Pre_enrollment_Open_Date__c',
            'reduivy__Start_Date__c',
            'reduivy__End_Date__c',
            'reduivy__Census_Date__c',
            'reduivy__Enrollment_Open_Date__c',
            'reduivy__Enrollment_Close_Date__c',
            'reduivy__Status_Override__c',
            'reduivy__Booked_Places__c',
            'reduivy__Waitlist_Places__c'
        };

        Set<String> sofFields = REDU_Metadata_UTIL.getObjectFieldsForCloning('reduivy__Study_Offering__c', AccessType.CREATABLE);
        sofFields.removeAll(sofFieldsToExclude);

        return sofFields;
    }

    /**
     * @description List of reduivy__Study_Offering_Status_Config__mdt
     */
    private static List<reduivy__Study_Offering_Status_Config__mdt> statusConfigs;

    /**
     * @description Status configs metadata sorted according to Status field
     * @return List<reduivy__Study_Offering_Status_Config__mdt>
     */
    public static List<reduivy__Study_Offering_Status_Config__mdt> getStatusConfig(){

        if (statusConfigs == null) {
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Study_Offering__c.fields.reduivy__Status_Override__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__Study_Offering_Status_Config__mdt> configs = reduivy__Study_Offering_Status_Config__mdt.getAll().values();
            List<reduivy__Study_Offering_Status_Config__mdt> sortedConfigs = new List<reduivy__Study_Offering_Status_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList) {
                if(ple.isActive()) {
                    for (reduivy__Study_Offering_Status_Config__mdt config : configs) {
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

            for (reduivy__Study_Offering_Status_Config__mdt config : getStatusConfig()) {
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

            for (reduivy__Study_Offering_Status_Config__mdt config : getStatusConfig()) {
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

            for (reduivy__Study_Offering_Status_Config__mdt config : getStatusConfig()) {
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

            for (reduivy__Study_Offering_Status_Config__mdt config : getStatusConfig()) {
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

            for (reduivy__Study_Offering_Status_Config__mdt config : getStatusConfig()) {
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

            for (reduivy__Study_Offering_Status_Config__mdt config : getStatusConfig()) {
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

            for (reduivy__Study_Offering_Status_Config__mdt config : getStatusConfig()) {
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

            for (reduivy__Study_Offering_Status_Config__mdt config : getStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_CANCELLED) {
                    cancelledStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return cancelledStatuses;
    }

    /**
     * @description Return a list of positive statuses for listing
     * @return List<String>
     */
    public static List<String> getPositiveStatuses() {

        List<String> statuses = new List<String>();

        statuses.addAll(getNotStartedStatuses());
        statuses.addall(getPreEnrollmentOpenedStatuses());
        statuses.addAll(getEnrollmentOpenedStatuses());
        statuses.addAll(getEnrollmentClosedStatuses());
        statuses.addAll(getRunningStatuses());

        return statuses;
    }

    private static Map<Id, reduivy__Study_Offering__c> studyOfferingsMap;

    /**
     * @description Return a map of study offering for IEN trigger controller to reduce the number of soql
     * @param sofIds The set of study offering ids
     * @param useCachedData Use the cached data until if the record exists
     * @return Map<Id, reduivy__Study_Offering__c>
     */
    public static Map<Id, reduivy__Study_Offering__c> getStudyOfferings(Set<Id> sofIds, Boolean useCachedData) {

        if (studyOfferingsMap == null) {
            studyOfferingsMap = new Map<Id, reduivy__Study_Offering__c>();

        }

        if (!sofIds.isEmpty()) {
            Set<String> sofFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Start_Date__c',
                'reduivy__End_Date__c',
                'reduivy__Census_Date_Calculated__c',
                'reduivy__Delivery_Method__c',
                'reduivy__Scheduled_Duration__c',
                'reduivy__Scheduled_Duration_Unit__c',
                'reduivy__Start_Date_Calculated__c',
                'reduivy__End_Date_Calculated__c',
                'reduivy__Study_Grade_Setting__c',
                'reduivy__Study_Unit__c',
                'reduivy__Study_Unit__r.reduivy__Credits__c',
                'reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c',
                'reduivy__Study_Unit__r.reduivy__Default_EFTSL__c'
            };

            String sofSoql = 'SELECT ' + String.join(sofFields, ',') + 
                ' FROM reduivy__Study_Offering__c ' +
                ' WHERE Id IN: sofIds ';

            Set<Id> sofIdsForQuery = new Set<Id>();

            if (useCachedData) {
                for (Id sofId : sofIds) {
                    //we only query the record if it doesn't exist in the map
                    if (!studyOfferingsMap.containsKey(sofId)) {
                        sofIdsForQuery.add(sofId);
                    }
                }
            } else {
                sofIdsForQuery.addAll(sofIds);
            }

            if (!sofIdsForQuery.isEmpty()) {

                Map<String, Object> sofBindParams = new Map<String, Object>();
                sofBindParams.put('sofIds', sofIdsForQuery);
                
                for (reduivy__Study_Offering__c sof : (List<reduivy__Study_Offering__c>) Database.queryWithBinds(sofSoql, sofBindParams, AccessLevel.USER_MODE)) {
                    studyOfferingsMap.put(sof.Id, sof);
                }
            }
        }

        return studyOfferingsMap;
    }
}