/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Object Helper
 * @description Study Grade Setting object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class SGS_Helper implements SObject_Helper {

    /**
     * @description Status - Active
     */
    public static final String STATUS_ACTIVE = 'Active';
    
    /**
     * @description Study Grade Setting object Grading Setting Type picklist constants
     */
    public static final String GRADING_SETTING_TYPE_PASSFAIL = 'Pass/Fail';

    /**
     * @description Study Grade Setting object Grading Setting Type picklist constants
     */
    public static final String GRADING_SETTING_TYPE_PERCENTAGE_LETTER = 'Percentage/Letter';
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Grade_Setting__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Grade_Setting__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Grade_Setting__c.getName();
    }
	
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Grade_Setting__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}