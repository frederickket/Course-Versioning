/**
 * @author      WDCi (Lean)
 * @date        May 2024
 * @group       Object Helper
 * @description 
 * @changehistory
 * ISS-001920 07-05-2024 Lean - new helper class
 */
global inherited sharing class CAV_Helper implements SObject_Helper {
    
    /**
     * @description Status - Active
     */
    public static final String STATUS_ACTIVE = 'Active';
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Contact_Availability__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Contact_Availability__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Contact_Availability__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Contact_Availability__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}