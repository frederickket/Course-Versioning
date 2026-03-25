/**
 * @author      WDCi (Lean)
 * @date        July 2024
 * @group       Object Helper
 * @description Study Fee Matrix Item object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class SMI_Helper implements SObject_Helper {

    /**
     * @description Type - Per Credit
     */
    public static final String TYPE_PER_CREDIT = 'Per Credit';

    /**
     * @description Type - Per Study Unit
     */
    public static final String TYPE_PER_STUDY_UNIT = 'Per Study Unit';

    /**
     * @description Type - Per Academic Term
     */
    public static final String TYPE_PER_ACADEMIC_TERM = 'Per Academic Term';

    /**
     * @description Type - Per Academic Year
     */
    public static final String TYPE_PER_ACADEMIC_YEAR = 'Per Academic Year';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Fee_Matrix_Item__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Fee_Matrix_Item__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Fee_Matrix_Item__c.getName();
    }
    
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Fee_Matrix_Item__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}