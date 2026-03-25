/**
 * @author      WDCi (XW)
 * @date        July 2025
 * @group       Object Helper
 * @description Study Intake Group object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class SIG_Helper implements SObject_Helper {
    
    /**
     * @description Status - Draft
     */
    public static final String STATUS_DRAFT = 'Draft';

    /**
     * @description Status - Active
     */
    public static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Status - Archived
     */
    public static final String STATUS_ARCHIVED = 'Archived';

    /**
     * @description Student Group Type - Standard
     */
    public static final String STUDENT_GROUP_TYPE_STANDARD = 'Standard';
    
    /**
     * @description Student Group Type - Disabled
     */
    public static final String STUDENT_GROUP_TYPE_DISABLED = 'Disabled';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Intake_Group__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Intake_Group__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Intake_Group__c.getName();
    }
    
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Intake_Group__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}