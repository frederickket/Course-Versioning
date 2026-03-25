/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Object Helper
 * @description Study Plan Option object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002203 20-01-2025 Jordan - added Completion Requirement values
 */
global inherited sharing class SPO_Helper implements SObject_Helper {
    
    /**
     * @description Status - Active
     */
    public static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Completion Requirement - Mandatory
     */
    public static final String COMPLETION_REQUIREMENT_MANDATORY = 'Mandatory';

    /**
     * @description Completion Requirement - Optional
     */
    public static final String COMPLETION_REQUIREMENT_OPTIONAL = 'Optional';

    /**
     * @description Return object type
     * @return String
     */
    public static Schema.SObjectType getObjectType() {
        return SObjectType.reduivy__Study_Plan_Option__c.getSObjectType();
    }

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Plan_Option__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Plan_Option__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Plan_Option__c.getName();
    }
    
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Plan_Option__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}