/**
 * @author      WDCi (Lean)
 * @date        Jul 2025
 * @group       Object helper
 * @description The individual success plan helper
 * @changehistory
 * ISS-002551 22-07-2025 Lean - new class
 */
global inherited sharing class ISP_Helper implements SObject_Helper {
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Individual_Success_Plan__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Individual_Success_Plan__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Individual_Success_Plan__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Success_Plan__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

}