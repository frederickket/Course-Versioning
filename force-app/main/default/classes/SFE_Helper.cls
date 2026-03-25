/**
 * @author      WDCi (Lean)
 * @date        July 2024
 * @group       Object Helper
 * @description Study Fee object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class SFE_Helper implements SObject_Helper {

    /**
     * @description Item Type - Tuition
     */
    public static final String ITEM_TYPE_TUITION = 'Tuition';

    /**
     * @description Item Type - Miscellaneous
     */
    public static final String ITEM_TYPE_MISCELLANEOUS = 'Miscellaneous';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Fee__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Fee__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Fee__c.getName();
    }
    
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Fee__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}