/**
 * @author      WDCi (Lean)
 * @date        April 2024
 * @group       Object Helper
 * @description Study Session Time object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class SST_Helper implements SObject_Helper {
     
  /**
     * @description Day of week - Monday
    */
    global static final String DAY_OF_WEEK_MONDAY = 'Monday';
    
    /**
     * @description Day of week - Tuesday
    */
    global static final String DAY_OF_WEEK_TUESDAY = 'Tuesday';
    
    /**
     * @description Day of week - Wednesday
    */
    global static final String DAY_OF_WEEK_WEDNESDAY = 'Wednesday';
    
    /**
     * @description Day of week - Thursday
    */
    global static final String DAY_OF_WEEK_THURSDAY = 'Thursday';
    
    /**
     * @description Day of week - Friday
    */
    global static final String DAY_OF_WEEK_FRIDAY = 'Friday';
    
    /**
     * @description Day of week - Saturday
    */
    global static final String DAY_OF_WEEK_SATURDAY = 'Saturday';
    
    /**
     * @description Day of week - Sunday
    */
    global static final String DAY_OF_WEEK_SUNDAY = 'Sunday';

    /**
     * @description Study Update Setting - Create/Update from today
    */
    global static final String UPDATE_SETTING_FROMTODAY = 'Create/Update from today';
        
    /**
     * @description Study Update Setting - Create/Update after today
    */
    global static final String UPDATE_SETTING_AFTERTODAY = 'Create/Update after today';
        
    /**
     * @description Study Update Setting - Create/Update from Change Date
    */
    global static final String UPDATE_SETTING_FROMCHANGEDATE = 'Create/Update from Change Date';
        
    /**
     * @description Study Session Time Update Setting - Create/Update after Change Date
    */
    global static final String UPDATE_SETTING_AFTERCHANGEDATE = 'Create/Update after Change Date';
    
    /**
     * @description Study Session Time Update Setting - Create/Update all
     */
    global static final String UPDATE_SETTING_ALL = 'Create/Update all'; 

    /**
     * @description Recurrence - Weekly
    */
    global static final String RECURRENCE_WEEKLY = 'Weekly';

    /**
     * @description Recurrence - Bi-Weekly
    */
    global static final String RECURRENCE_BIWEEKLY = 'Bi-Weekly';
    
    /**
     * @description Recurrence - One-off
    */
    global static final String RECURRENCE_ONEOFF = 'One-off';

    /**
     * @description Recurrence - Daily
    */
    global static final String RECURRENCE_DAILY = 'Daily';

    /**
     * @description Update Action - Daily
    */
    global static final String UPDATE_ACTION_RECREATE = 'Recreate';

    /**
     * @description Update Action - Upsert
    */
    global static final String UPDATE_ACTION_UPSERT = 'Upsert';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Session_Time__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Session_Time__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Session_Time__c.getName();
    }
	
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Session_Time__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Return fields for cloning
     */
    public static Set<String> getFieldsForCloning(){
        //Set the exclude the dates and rollup fields so that it won’t inherit from the parent, and the calculated field will inherit from the term record's date
        Set<String> sstFieldsToExclude = new Set<String>{
            'reduivy__Update_Action__c',
            'reduivy__Historical_Recurrence__c',
            'reduivy__Start_Date__c',
            'reduivy__End_Date__c'
        };

        Set<String> sstFields = REDU_Metadata_UTIL.getObjectFieldsForCloning('reduivy__Study_Session_Time__c', AccessType.CREATABLE);
        sstFields.removeAll(sstFieldsToExclude);

        return sstFields;
    }
}