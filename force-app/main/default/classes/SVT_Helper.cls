/**
 * @author      WDCi (Lean)
 * @date        July 2024
 * @group       Object Helper
 * @description Study Voucher Transaction object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002591 13-02-2026 XiRouh - Added helper methods for reduivy__Study_Voucher_Transaction_Status_Config__mdt
 */
global inherited sharing class SVT_Helper implements SObject_Helper {

    /**
     * @description Study Voucher Transaction object Status picklist constants
     */
    public static final String STATUS_DRAFT = 'Draft';

    /**
     * @description Study Voucher Transaction object Status picklist constants
     */
    public static final String STATUS_CONFIRMED = 'Confirmed';

    /**
     * @description Study Voucher Transaction object Status type picklist constants
     */
    public static final String STATUS_PENDING_COMFIRMATION = 'Pending Confirmation';
    
    /**
     * @description Study Voucher Transaction object Status picklist constants
     */
    public static final String STATUS_VOID = 'Void';

    /**
     * @description Study Voucher Transaction object Status type picklist constants
     */
    public static final String STATUS_TYPE_DRAFT = 'Draft';

    /**
     * @description Study Voucher Transaction object Status type picklist constants
     */
    public static final String STATUS_TYPE_CONFIRMED = 'Confirmed';

    /**
     * @description Study Voucher Transaction object Status type picklist constants
     */
    public static final String STATUS_TYPE_PENDING = 'Pending';
    
    /**
     * @description Study Voucher Transaction object Status type picklist constants
     */
    public static final String STATUS_TYPE_VOID = 'Void';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Voucher_Transaction__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Voucher_Transaction__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Voucher_Transaction__c.getName();
    }
    
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Voucher_Transaction__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description List of reduivy__Study_Voucher_Transaction_Status_Config__mdt
     */
    private static List<reduivy__Study_Voucher_Transaction_Status_Config__mdt> studyVoucherTransactionStatusConfigs;

    /**
     * @description Study Voucher Transaction Status configs metadata sorted according to Status field
     * @return List<reduivy__Study_Voucher_Transaction_Status_Config__mdt>
     */
    public static List<reduivy__Study_Voucher_Transaction_Status_Config__mdt> getStudyVoucherTransactionStatusConfigs(){

        if (studyVoucherTransactionStatusConfigs == null) {
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Study_Voucher_Transaction__c.fields.reduivy__Status__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__Study_Voucher_Transaction_Status_Config__mdt> configs = reduivy__Study_Voucher_Transaction_Status_Config__mdt.getAll().values();
            List<reduivy__Study_Voucher_Transaction_Status_Config__mdt> sortedConfigs = new List<reduivy__Study_Voucher_Transaction_Status_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList) {
                if(ple.isActive()) {
                    for (reduivy__Study_Voucher_Transaction_Status_Config__mdt config : configs) {
                        if (config.reduivy__Active__c && ple.getValue() == config.reduivy__Status__c) {
                            sortedConfigs.add(config);
                        }
                    }
                }
            }

            studyVoucherTransactionStatusConfigs = sortedConfigs;
        }

        return studyVoucherTransactionStatusConfigs;
    }

    /**
     * @description Draft statuses
     */
    private static List<String> draftStatuses;

    /*
     * @description Return a list of draft status
     * @return List<String>
     */
    public static List<String> getDraftStatuses() {

        if (draftStatuses == null) {
            draftStatuses = new List<String>();

            for (reduivy__Study_Voucher_Transaction_Status_Config__mdt config : getStudyVoucherTransactionStatusConfigs()) {
                if (config.reduivy__Type__c == STATUS_TYPE_DRAFT) {
                    draftStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return draftStatuses;
    }

    /**
     * @description Pending statuses
     */
    private static List<String> pendingStatuses;

    /*
     * @description Return a list of pending status
     * @return List<String>
     */
    public static List<String> getPendingStatuses() {

        if (pendingStatuses == null) {
            pendingStatuses = new List<String>();

            for (reduivy__Study_Voucher_Transaction_Status_Config__mdt config : getStudyVoucherTransactionStatusConfigs()) {
                if (config.reduivy__Type__c == STATUS_TYPE_PENDING) {
                    pendingStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return pendingStatuses;
    }

    /**
     * @description Confirmed statuses
     */
    private static List<String> confirmedStatuses;

    /*
     * @description Return a list of confirmed status
     * @return List<String>
     */
    public static List<String> getConfirmedStatuses() {

        if (confirmedStatuses == null) {
            confirmedStatuses = new List<String>();

            for (reduivy__Study_Voucher_Transaction_Status_Config__mdt config : getStudyVoucherTransactionStatusConfigs()) {
                if (config.reduivy__Type__c == STATUS_TYPE_CONFIRMED) {
                    confirmedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return confirmedStatuses;
    }

    /**
     * @description void statuses
     */
    private static List<String> voidStatuses;

    /*
     * @description Return a list of void status
     * @return List<String>
     */
    public static List<String> getVoidStatuses() {

        if (voidStatuses == null) {
            voidStatuses = new List<String>();

            for (reduivy__Study_Voucher_Transaction_Status_Config__mdt config : getStudyVoucherTransactionStatusConfigs()) {
                if (config.reduivy__Type__c == STATUS_TYPE_VOID) {
                    voidStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return voidStatuses;
    }
}