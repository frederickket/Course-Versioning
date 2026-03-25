/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Object Helper
 * @description Study Plan object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002542 14-07-2025 XiRouh - Added IEN_CREATION_MODE_REQUIRED_UNITS_ONLY and IEN_CREATION_MODE_NONE
 */
global inherited sharing class SPL_Helper implements SObject_Helper {
    
    /**
     * @description Fee Method - Program
     */
    public static final String FEEMETHOD_PROGRAM = 'Program';

    /**
     * @description Fee Method - Term
     */
    public static final String FEEMETHOD_TERM = 'Term';

    /**
     * @description Fee Method - Fixed Term
     */
    public static final String FEEMETHOD_FIXEDTERM = 'Fixed Term';

    /**
     * @description Fee Method - Unit
     */
    public static final String FEEMETHOD_UNIT = 'Unit';

    /**
     * @description Pay Upfront - Yes
     */
    public static final String PAYUPFRONT_YES = 'Yes';

    /**
     * @description Pay Upfront - No
     */
    public static final String PAYUPFRONT_No = 'No';

    /**
     * @description Status - Active
     */
    public static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Individual Enrollment Creation Mode - Required Units Only
     */
    public static final String IEN_CREATION_MODE_REQUIRED_UNITS_ONLY = 'Required Units Only';

    /**
     * @description Individual Enrollment Creation Mode - None
     */
    public static final String IEN_CREATION_MODE_NONE = 'None';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Plan__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Plan__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Plan__c.getName();
    }
    
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Plan__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}