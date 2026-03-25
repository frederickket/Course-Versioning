/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Object Helper
 * @description Agreement Unit Equivalent object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class AUE_Helper implements SObject_Helper {
    
    /**
     * @description Agreement Unit Equivalent Status picklist constants
     */
    public static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Agreement Unit Equivalent Type - One to One
     */
    public static final String TYPE_ONETOONE = 'One to One';

    /**
     * @description Agreement Unit Equivalent Type - One to Many
     */
    public static final String TYPE_ONETOMANY = 'One to Many';

    /**
     * @description Agreement Unit Equivalent Type - Many to One
     */
    public static final String TYPE_MANYTOONE = 'Many to One';

    /**
     * @description Agreement Unit Equivalent Type - Manual Assignment
     */
    public static final String TYPE_MANUALASSIGNMENT = 'Manual Assignment';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Agreement_Unit_Equivalent__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Agreement_Unit_Equivalent__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Agreement_Unit_Equivalent__c.getName();
    }
	
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Agreement_Unit_Equivalent__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}