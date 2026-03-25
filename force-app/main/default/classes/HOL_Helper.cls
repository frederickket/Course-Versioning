/**
 * @author      WDCi (Lean)
 * @date        April 2024
 * @group       Object Helper
 * @description Holiday object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class HOL_Helper implements SObject_Helper {
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Holiday__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Holiday__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Holiday__c.getName();
    }
	
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Holiday__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}