/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Object Helper
 * @description Study Program object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class SPG_Helper implements SObject_Helper {
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Program__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Program__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Program__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Program__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Status Type - Draft
     */
    public static final String SPG_STATUS_DRAFT = 'Draft';

    /**
     * @description Status Type - Active
     */
    public static final String SPG_STATUS_ACTIVE = 'Active';

    /**
     * @description Status Type - Archived
     */
    public static final String SPG_STATUS_ARCHIVED = 'Archived';

    /**
     * @description Auto Unit Recognition Scope - None
     */
    public static final String AUTO_UNIT_RECOGNITION_SCOPE_NONE = 'None';

    /**
     * @description Auto Unit Recognition Scope - All Academic Profiles
     */
    public static final String AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES = 'All Academic Profiles';
}