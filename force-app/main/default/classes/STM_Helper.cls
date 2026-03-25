/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Object Helper
 * @description Study Term object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001979 19-07-2024 Sueanne - added enrollment settings
 */
global inherited sharing class STM_Helper implements SObject_Helper {
    
    /**
     * @description Status - Active
     */
    public static final String STATUS_ACTIVE = 'Active';
    
    /**
     * @description Type - Semester
     */
    public static final String TYPE_SEMESTER = 'Semester';

    /**
     * @description Type - School Year
     */
    public static final String TYPE_SCHOOLYEAR = 'School Year';
    
    /**
     * @description Unit Enrollment Setting - Default
     */
    public static final String UNIT_ENROLLMENT_DEFAULT = 'Default';

    /**
     * @description Unit Enrollment Setting - Allow Enrolled Pre-requisite Units
     */
    public static final String UNIT_ENROLLMENT_ALLOW_PREREQUISITE = 'Allow Enrolled Pre-requisite Units';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Term__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Term__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Term__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Term__c);

        return String.isBlank(formulaFieldName) ? 'reduivy__Display_Name__c' : formulaFieldName;
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
            rtMap = Schema.SObjectType.reduivy__Study_Term__c.getRecordtypeInfosByDeveloperName();
        }

        return rtMap;
    }

    /**
     * @description Return Academic Year record type id
     * @return Id
     */
    global static Id getAcademicYearRecordTypeId() {
        return getRecordTypes().get('Academic_Year').getRecordTypeId();
    }

    /**
     * @description Return Academic Year record type UI label
     * @return String
     */
    global static String getAcademicYearRecordTypeLabel() {
        return getRecordTypes().get('Academic_Year').getName();
    }

    /**
     * @description Return Academic Term record type id
     * @return Id
     */
    global static Id getAcademicTermRecordTypeId() {
        return getRecordTypes().get('Academic_Term').getRecordTypeId();
    }

    /**
     * @description Return Academic Term record type UI label
     * @return String
     */
    global static String getAcademicTermRecordTypeLabel() {
        return getRecordTypes().get('Academic_Term').getName();
    }
}