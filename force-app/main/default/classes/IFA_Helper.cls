/**
 * @author      WDCi (Lean)
 * @date        Feb 2024
 * @group       Object Helper
 * @description Individual Funding Allocation object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class IFA_Helper implements SObject_Helper {

    /**
     * @description Individual Funding Allocation Status - Active
     */
    public static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Individual Funding Allocation Status - Inactive
     */
    public static final String STATUS_INACTIVE = 'Inactive';

    /**
     * @description Individual Funding Allocation Status - Draft
     */
    public static final String STATUS_DRAFT = 'Draft';
    
    /**
     * @description Individual Funding Allocation Status - Cancelled
     */
    public static final String STATUS_CANCELLED = 'Cancelled';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Individual_Funding_Allocation__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Individual_Funding_Allocation__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Individual_Funding_Allocation__c.getName();
    }
	
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Funding_Allocation__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}