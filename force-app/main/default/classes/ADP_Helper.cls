/**
 * @author      WDCi (Lean)
 * @date        Sept 2025
 * @group       Object Helper
 * @description Admission Path object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002497 24-09-2025 Lean - New admission option data model
 */
global inherited sharing class ADP_Helper implements SObject_Helper {
    
    /**
     * @description Status picklist constants
     */
    public static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Admission_Path__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Admission_Path__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Admission_Path__c.getName();
    }
	
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Admission_Path__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}