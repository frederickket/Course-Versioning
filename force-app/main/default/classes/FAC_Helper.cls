/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Object Helper
 * @description Facility object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class FAC_Helper implements SObject_Helper {
    
    /**
     * @description Facility Type - Building
     */
    public static final String FACTYPE_BUILDING = 'Building';

    /**
     * @description Facility Type - Classroom
     */
    public static final String FACTYPE_CLASSROOM = 'Classroom';

    /**
     * @description Facility Type - Lecture Hall
     */
    public static final String FACTYPE_LECHALL = 'Lecture Hall';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Facility__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Facility__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Facility__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Facility__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}