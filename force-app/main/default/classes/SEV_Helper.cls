/**
 * @author      WDCi (Lean)
 * @date        April 2024
 * @group       Object Helper
 * @description Study Event object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001922 14-06-2024 XW - added TYPE
 */
global inherited sharing class SEV_Helper implements SObject_Helper {
    
    /**
     * @description Type - Study Session
     */
    public static final String TYPE_STUDY_SESSION = 'Study Session';    

    /**
     * @description Type - Appointment
     */
    public static final String TYPE_APPOINTMENT = 'Appointment';

    /**
     * @description Status - New
     */
    public static final String STATUS_NEW = 'New';   


    /**
     * @description Status - Confirmed
     */
    public static final String STATUS_CONFIRMED = 'Confirmed';

    /**
     * @description Status - Cancelled
     */
    public static final String STATUS_CANCELLED = 'Cancelled';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Event__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Event__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Event__c.getName();
    }
	
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Event__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}