/**
 * @author      WDCi (Lean)
 * @date        Feb 2024
 * @group       Object Helper
 * @description Study Funding object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class SFD_Helper implements SObject_Helper {

    /**
     * @description Study Funding Status picklist constants
     */
    public static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Study Funding Type picklist constants
     */
    public static final String TYPE_SCHOLARSHIP = 'Scholarship';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Funding__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Funding__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Funding__c.getName();
    }
	
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Funding__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}