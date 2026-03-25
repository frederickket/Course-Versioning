/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Object Helper
 * @description Agreement object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class AGR_Helper implements SObject_Helper {
    
    /**
     * @description Agreement Status - Active
     */
    public static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Agreement Type - External Unit Recognition
     */
    public static final String TYPE_EXTERNAL = 'External Unit Recognition';

    /**
     * @description Agreement Type - Internal Unit Recognition
     */
    public static final String TYPE_INTERNAL = 'Internal Unit Recognition';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Agreement__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Agreement__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Agreement__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Agreement__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
	
}