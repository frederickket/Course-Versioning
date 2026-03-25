/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Object Helper
 * @description Helper class for Study Requirement
 * @changehistory
 * ISS-002128 05/06/2025 XW - new class
 */

global inherited sharing class SRQ_Helper implements SObject_Helper {
    
    /**
     * @description Requirement Visibility - Admin
     */
    global static final String REQUIREMENT_VISIBILITY_ADMIN = 'Admin';
    
    /**
     * @description Requirement Visibility - Faculty
     */
    global static final String REQUIREMENT_VISIBILITY_FACULTY = 'Faculty';
    
    /**
     * @description Requirement Visibility - Student
     */
    global static final String REQUIREMENT_VISIBILITY_STUDENT = 'Student';
    
    /**
     * @description Priority - High
     */
    global static final String PRIORITY_HIGH = 'High';
    
    /**
     * @description Priority - Normal
     */
    global static final String PRIORITY_NORMAL = 'Normal';
    
    /**
     * @description Priority - Low
     */
    global static final String PRIORITY_LOW = 'Low';

    /**
     * @description Requirement Type - File Upload
     */
    global static final String REQUIREMENT_TYPE_FILE_UPLOAD = 'File Upload';

    /**
     * @description Requirement Type - Action
     */
    global static final String REQUIREMENT_TYPE_ACTION = 'Action';

    /**
     * @description Requirement Type - Field Update
     */
    global static final String REQUIREMENT_TYPE_FIELD_UPDATE = 'Field Update';

    /**
     * @description Study Requirement Status - Draft
     */
    global static final String STATUS_DRAFT = 'Draft';

    /**
     * @description Study Requirement Status - Active
     */
    global static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Study Requirement Status - Archived
     */
    global static final String STATUS_ARCHIVED = 'Archived';
    
    /**
     * @description Link To Individual Achievement - Yes
     */
    global static final String LINK_TO_INDIVIDUAL_ACHIEVEMENT_YES = 'Yes';
    
    /**
     * @description Link To Individual Achievement - No
     */
    global static final String LINK_TO_INDIVIDUAL_ACHIEVEMENT_NO = 'No';
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel(){
        return SObjectType.reduivy__Study_Requirement__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel(){
        return SObjectType.reduivy__Study_Requirement__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName(){
        return SObjectType.reduivy__Study_Requirement__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Requirement__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

}
