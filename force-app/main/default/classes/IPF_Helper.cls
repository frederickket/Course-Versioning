/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Object Helper
 * @description Individual Academic Profile object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class IPF_Helper implements SObject_Helper {
    
    /**
     * @description Individual Academic Profile generation type = By Individual Program Enrollment
     */
    public static final String PROFILE_GEN_TYPE_BYIPE = 'By Individual Program Enrollment';

    /**
     * @description Individual Academic Profile generation type = By Identifier Mapping
     */
    public static final String PROFILE_GEN_TYPE_BYIDENTIFIERMAPPING = 'By Identifier Mapping';

    /**
     * @description Individual Academic Profile Status - Active
     */
    public static final String STATUS_ACTIVE = 'Active';
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Individual_Academic_Profile__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Individual_Academic_Profile__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Individual_Academic_Profile__c.getName();
    }
	
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Academic_Profile__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}