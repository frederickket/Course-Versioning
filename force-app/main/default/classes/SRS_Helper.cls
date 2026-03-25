/**
 * @author      WDCi (XW)
 * @date        May 2025
 * @group       Object Helper
 * @description Helper class for Study Requirement Set
 * @changehistory
 * ISS-002128 30-05-2025 XW - new class
 */

global inherited sharing class SRS_Helper implements SObject_Helper {
    
    /**
     * @description Study Requirement Status - Draft
     */
    global static final String STATUS_DRAFT = 'Draft';

    /**
     * @description Study Requirement Status - Active
     */
    global static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Study Requirement Status - Archived
     */
    global static final String STATUS_ARCHIVED = 'Archived';

    /**
     * @description Individual Requirement Generation Mode - Auto
     */
    global static final String REQUIREMENT_GENERATION_MODE_AUTO = 'Auto';
    
    /**
     * @description Individual Requirement Generation Mode - Manual
     */
    global static final String REQUIREMENT_GENERATION_MODE_MANUAL = 'Manual';
    

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel(){
        return SObjectType.reduivy__Study_Requirement_Set__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel(){
        return SObjectType.reduivy__Study_Requirement_Set__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName(){
        return SObjectType.reduivy__Study_Requirement_Set__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Requirement_Set__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

}
