/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Object Helper
 * @description Study Plan Unit Requirement object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001979 15-07-2024 Sueanne - remove pre-req enrolled/completed option
 * ISS-002044 29-07-2024 Sueanne - added requirement type "Conflict"
 * ISS-002144 18-12-2024 XW - added requiremen type Pre-Requisite (Allow Bypass)
 * ISS-002226 06-01-2025 XW - renamed Conflict type to 'Enrolled or Completed'
 */
global inherited sharing class SPR_Helper implements SObject_Helper {
    
    /**
     * @description Requirement Type - Pre-Requisite
     */
    public static final String REQTYPE_PREREQ = 'Pre-Requisite';
    
    /**
     * @description Requirement Type - Pre-Requisite (Allow Bypass)
     */
    public static final String REQTYPE_PREREQ_BYPASS = 'Pre-Requisite (Allow Bypass)';
    
    /**
     * @description Requirement Type - Co-Requisite
     */
    public static final String REQTYPE_COREQ = 'Co-Requisite';

    /**
     * @description Requirement Type - Enrolled or Completed
     */
    public static final String REQTYPE_ENROLLED_COMPLETED = 'Enrolled or Completed';
    
    /**
     * @description Requirement Type - Credits
     */
    public static final String REQTYPE_CREDITS = 'Credits';
    
    /**
     * @description Requirement Type - Custom
     */
    public static final String REQTYPE_CUSTOM = 'Custom';
    
    /**
     * @description Requirement Type - Other
     */
    public static final String REQTYPE_OTHER = 'Other';
    
    /**
     * @description Field Matching Operator - Equals
     */
    public static final String FIELDMATCHINGOP_EQUALS = 'Equals';

    /**
     * @description Field Matching Operator - Does Not Equal
     */
    public static final String FIELDMATCHINGOP_DOESNOTEQUAL = 'Does Not Equal';
    
    /**
     * @description Field Matching Operator - Greater than
     */
    public static final String FIELDMATCHINGOP_GREATER = 'Greater than';
    
    /**
     * @description Field Matching Operator - Less Than
     */
    public static final String FIELDMATCHINGOP_LESS = 'Less Than';
    
    /**
     * @description Field Matching Operator - Greater Than or Equal
     */
    public static final String FIELDMATCHINGOP_GREATEROREQUAL = 'Greater Than or Equal';
    
    /**
     * @description Field Matching Operator - Less Than or Equal
     */
    public static final String FIELDMATCHINGOP_LESSOREQUAL = 'Less Than or Equal';
    
    /**
     * @description Field Matching Operator - Is Blank
     */
    public static final String FIELDMATCHINGOP_ISBLANK = 'Is Blank';
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Plan_Unit_Requirement__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Plan_Unit_Requirement__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Plan_Unit_Requirement__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Plan_Unit_Requirement__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}