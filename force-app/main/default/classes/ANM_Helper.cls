/**
 * @author      WDCi (Lean)
 * @date        April 2024
 * @group       Object Helper
 * @description Announcement object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class ANM_Helper implements SObject_Helper {
    
    /**
     * @description Notification Channel Type - Notification
     */
    public static final String NCT_NOTIFICATION = 'Notification';

    /**
     * @description Notification Target Type - Named Page (Experience Cloud)
     */
    public static final String NTT_NAMED_PAGE_EXPERIENCE_CLOUD = 'Named Page (Experience Cloud)';

    /**
     * @description Notification Target Type - Named Page (Standard)
     */
    public static final String NTT_NAMED_PAGE_STANDARD = 'Named Page (Standard)';

    /**
     * @description Notification Target Type - Navigation Item Page
     */
    public static final String NTT_NAVIGATION_ITEM_PAGE = 'Navigation Item Page';

    /**
     * @description Notification Target Type - Record Page
     */
    public static final String NTT_RECORD_PAGE = 'Record Page';

    /**
     * @description Notification Target Type - Web Page
     */
    public static final String NTT_WEB_PAGE = 'Web Page';

    /**
     * @description Announcement Status - Archived
     */
    public static final String STATUS_ARCHIVED = 'Archived';

    /**
     * @description Announcement Status - Published
     */
    public static final String STATUS_PUBLISHED = 'Published';

    /**
     * @description Announcement Status - Send
     */
    public static final String STATUS_SEND = 'Send';

    /**
     * @description Announcement Status - Draft
     */
    public static final String STATUS_DRAFT = 'Draft';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Announcement__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Announcement__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Announcement__c.getName();
    }
	
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Announcement__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}