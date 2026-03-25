/**
 * @author      WDCi (Lean)
 * @date        July 2024
 * @group       Object Helper
 * @description Study Fee Config object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class SFC_Helper implements SObject_Helper {

    /**
     * @description Type - Academic Program	
     */
    public static final String TYPE_ACADEMIC_PROGRAM = 'Academic Program';

    /**
     * @description Status - Active
     */
    public static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Fee_Config__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Fee_Config__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Fee_Config__c.getName();
    }
    
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Fee_Config__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}