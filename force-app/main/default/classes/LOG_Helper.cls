/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Object Helper
 * @description Log object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class LOG_Helper implements SObject_Helper {
    
    /**
     * @description Type - Info
     */
    public static final String TYPE_INFO = 'Info';

    /**
     * @description Type - Warning
     */
    public static final String TYPE_WARNING = 'Warning';

    /**
     * @description Type - Error
     */
    public static final String TYPE_ERROR = 'Error';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Log__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Log__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Log__c.getName();
    }
    
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Log__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}