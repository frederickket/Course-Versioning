/**
 * @author      WDCi (XW)
 * @date        Jul 2025
 * @group       Object Helper
 * @description Study Scoring Config object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002506 16-07-2025 XW - new class
 */
global inherited sharing class SCF_Helper implements SObject_Helper {
    
    /**
     * @description Status - Active
     */
    global static String STATUS_ACTIVE = 'Active';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Scoring_Config__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Scoring_Config__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Scoring_Config__c.getName();
    }
	
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Scoring_Config__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}