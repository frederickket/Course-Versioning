/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Object Helper
 * @description Credit Transfer Application object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class CTA_Helper implements SObject_Helper {
    
    /**
     * @description Type - Incoming
     */
    public static final String TYPE_INCOMING = 'Incoming';

    /**
     * @description Type - Outgoing
     */
    public static final String TYPE_OUTGOING = 'Outgoing';

    /**
     * @description Status Type - Draft
     */
    public static final String STATUS_TYPE_DRAFT = 'Draft';

    /**
     * @description Status Type - Submitted
     */
    public static final String STATUS_TYPE_SUBMITTED = 'Submitted';

    /**
     * @description Status Type - Review
     */
    public static final String STATUS_TYPE_REVIEW = 'Review';

    /**
     * @description Status Type - Approved
     */
    public static final String STATUS_TYPE_APPROVED = 'Approved';

    /**
     * @description Status Type - Rejected
     */
    public static final String STATUS_TYPE_REJECTED = 'Rejected';

    /**
     * @description Status Type - Cancelled
     */
    public static final String STATUS_TYPE_CANCELLED = 'Cancelled';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Credit_Transfer_Application__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Credit_Transfer_Application__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Credit_Transfer_Application__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Credit_Transfer_Application__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description List of reduivy__Credit_Transfer_App_Status_Config__mdt
     */
    private static List<reduivy__Credit_Transfer_App_Status_Config__mdt> statusConfigs;

    /**
     * @description Status configs metadata sorted according to Status field
     * @return List<reduivy__Credit_Transfer_App_Status_Config__mdt>
     */
    public static List<reduivy__Credit_Transfer_App_Status_Config__mdt> getStatusConfig(){

        if (statusConfigs == null) {
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Credit_Transfer_Application__c.fields.reduivy__Status__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__Credit_Transfer_App_Status_Config__mdt> configs = reduivy__Credit_Transfer_App_Status_Config__mdt.getAll().values();
            List<reduivy__Credit_Transfer_App_Status_Config__mdt> sortedConfigs = new List<reduivy__Credit_Transfer_App_Status_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList) {
                if(ple.isActive()) {
                    for (reduivy__Credit_Transfer_App_Status_Config__mdt config : configs) {
                        if (config.reduivy__Active__c && ple.getValue() == config.reduivy__Status__c) {
                            sortedConfigs.add(config);
                        }
                    }
                }
            }

            statusConfigs = sortedConfigs;
        }

        return statusConfigs;
    }

    /**
     * @description Draft statuses
     */
    private static List<String> draftStatuses;

    /**
     * @description Return Draft statuses
     * @return List<String>
     */
    public static List<String> getDraftStatuses() {
        
        if (draftStatuses == null) {
            draftStatuses = new List<String>();

            for (reduivy__Credit_Transfer_App_Status_Config__mdt config : getStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_DRAFT) {
                    draftStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return draftStatuses;
    }

    /**
     * @description Submitted statuses
     */
    private static List<String> submittedStatuses;

    /**
     * @description Return Submitted statuses
     * @return List<String>
     */
    public static List<String> getSubmittedStatuses() {
        
        if (submittedStatuses == null) {
            submittedStatuses = new List<String>();

            for (reduivy__Credit_Transfer_App_Status_Config__mdt config : getStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_SUBMITTED) {
                    submittedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return submittedStatuses;
    }

    /**
     * @description Review statuses
     */
    private static List<String> reviewStatuses;

    /**
     * @description Return Review statuses
     * @return List<String>
     */
    public static List<String> getReviewStatuses() {
        
        if (reviewStatuses == null) {
            reviewStatuses = new List<String>();

            for (reduivy__Credit_Transfer_App_Status_Config__mdt config : getStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_REVIEW) {
                    reviewStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return reviewStatuses;
    }

    /**
     * @description Approved statuses
     */
    private static List<String> approvedStatuses;

    /**
     * @description Return Approved statuses
     * @return List<String>
     */
    public static List<String> getApprovedStatuses() {
        
        if (approvedStatuses == null) {
            approvedStatuses = new List<String>();

            for (reduivy__Credit_Transfer_App_Status_Config__mdt config : getStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_APPROVED) {
                    approvedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return approvedStatuses;
    }

    /**
     * @description Rejected statuses
     */
    private static List<String> rejectedStatuses;

    /**
     * @description Return Rejected statuses
     * @return List<String>
     */
    public static List<String> getRejectedStatuses() {
        
        if (rejectedStatuses == null) {
            rejectedStatuses = new List<String>();

            for (reduivy__Credit_Transfer_App_Status_Config__mdt config : getStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_REJECTED) {
                    rejectedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return rejectedStatuses;
    }

    /**
     * @description Cancelled statuses
     */
    private static List<String> cancelledStatuses;

    /**
     * @description Return Cancelled statuses
     * @return List<String>
     */
    public static List<String> getCancelledStatuses() {
        
        if (cancelledStatuses == null) {
            cancelledStatuses = new List<String>();

            for (reduivy__Credit_Transfer_App_Status_Config__mdt config : getStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_CANCELLED) {
                    cancelledStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return cancelledStatuses;
    }
	
}