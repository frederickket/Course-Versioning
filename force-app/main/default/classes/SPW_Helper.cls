/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Object Helper
 * @description Study Pathway object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class SPW_Helper implements SObject_Helper {
    
    /**
     * @description Status - Active
     */
    public static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Return object type
     * @return String
     */
    public static Schema.SObjectType getObjectType() {
        return SObjectType.reduivy__Study_Pathway__c.getSObjectType();
    }

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Pathway__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Pathway__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Pathway__c.getName();
    }
    
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Pathway__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}