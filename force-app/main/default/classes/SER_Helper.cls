/**
 * @author      WDCi (Lean)
 * @date        April 2024
 * @group       Object Helper
 * @description Study Event Relation object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001922 14-06-2024 XW - added RESPONSE_STATUS_ACCEPTED
 * 
 */
global inherited sharing class SER_Helper implements SObject_Helper {
    
    /**
     * @description Response status - New
     */
    public static final String RESPONSE_STATUS_NEW = 'New';

    /**
     * @description Response status - Accepted
     */
    public static final String RESPONSE_STATUS_ACCEPTED = 'Accepted';

    /**
     * @description Response status - Declined
     */
    public static final String RESPONSE_STATUS_DECLINED = 'Declined';

    /**
     * @description Response Status - Rejected
     */
    global static String RESPONSE_STATUS_REJECTED = 'Rejected';
    
    /*
     * @description Attendance status - Unmarked
     */
    public static final String ATTENDANCE_STATUS_UNMARKED = 'Unmarked';

    /**
     * @description Attendance status - Attended
     */
    public static final String ATTENDANCE_STATUS_ATTENDED = 'Attended';

    /**
     * @description Attendance status - Late
     */
    public static final String ATTENDANCE_STATUS_LATE = 'Late';

    /**
     * @description Attendance status - Excused
     */
    public static final String ATTENDANCE_STATUS_EXCUSED = 'Excused';

    /**
     * @description Attendance status - Absent
     */
    global static String ATTENDANCE_STATUS_ABSENT = 'Absent';

    /**
     * @description Relation Type - Facility
     */
    global static String RELATION_TYPE_FACILITY = 'Facility';

    /**
     * @description Relation Type - Student
     */
    global static String RELATION_TYPE_STUDENT = CON_Helper.CONTACT_TYPE_STUDENT;

    /**
     * @description Relation Type - Faculty
     */
    global static String RELATION_TYPE_FACULTY = CON_Helper.CONTACT_TYPE_FACULTY;

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Event_Relation__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Event_Relation__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Event_Relation__c.getName();
    }
	
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Event_Relation__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Return a set of statuses that represents the attendance is marked
     * @return Set<String>
     */
    public static Set<String> getAttendanceMarkedStatuses() {

        return new Set<String>{ATTENDANCE_STATUS_ATTENDED, ATTENDANCE_STATUS_ABSENT, ATTENDANCE_STATUS_EXCUSED, ATTENDANCE_STATUS_LATE};
    }


    /**
     * @description Combination of link ien and link isn from IEN_Helper and ISN_Helper
     * @param  sevList   list of study event
     * @param  contactId The faculty contact id
     * @return           Map<Study event id, Individual Session Enrollment id>
     */
    public static Map<Id, Id> linkIenAndIsnRelationship(List<reduivy__Study_Event__c> sevList, String contactId, List<String> facultyRoles) {
        Map<Id, Id> sevToIenMap = IEN_Helper.linkIenRelationship(sevList, contactId);
        return ISN_Helper.linkIsnRelationship(sevList, sevToIenMap, contactId, facultyRoles);
    }

}