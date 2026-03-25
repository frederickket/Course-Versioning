/**
 * @author      WDCi (XW)
 * @date        Dec 2025
 * @group       Object Helper
 * @description 
 * @changehistory
 * ISS-002633 09-12-2025 XW - new helper class
 */
global inherited sharing class ARU_Helper implements SObject_Helper {
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Agreement_Recognition_Unit__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Agreement_Recognition_Unit__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Agreement_Recognition_Unit__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Agreement_Recognition_Unit__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}