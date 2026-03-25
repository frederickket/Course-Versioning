/**
 * @author      WDCi (XW)
 * @date        Dec 2025
 * @group       Object Helper
 * @description 
 * @changehistory
 * ISS-002633 08-12-2025 XW - new helper class
 */
global inherited sharing class IAU_Helper implements SObject_Helper {
    
    /**
     * @description Individual Achievement Verification Status Config Type Open
     */
    public static final String VERIFICATION_STATUS_TYPE_OPEN = 'Open';

    /**
     * @description Individual Achievement Verification Status Config Type Submitted
     */
    public static final String VERIFICATION_STATUS_TYPE_SUBMITTED = 'Submitted'; 

    /**
     * @description Individual Achievement Verification Status Config Type Review
     */
    public static final String VERIFICATION_STATUS_TYPE_REVIEW = 'Review'; 

    /**
     * @description Individual Achievement Verification Status Config Type Verified
     */
    public static final String VERIFICATION_STATUS_TYPE_VERIFIED = 'Verified'; 

    /**
     * @description Individual Achievement Verification Status Config Type Rejected
     */
    public static final String VERIFICATION_STATUS_TYPE_REJECTED = 'Rejected'; 

    /**
     * @description Individual Achievement Verification Status Config Type Cancelled
     */
    public static final String VERIFICATION_STATUS_TYPE_CANCELLED = 'Cancelled'; 

    /**
     * @description Individual Achievement Unit Verification Status Badge Type - success
     */
    public static final String VERIFICATION_STATUS_BADGE_TYPE_SUCCESS = 'success';

    /**
     * @description Individual Achievement Unit Verification Status Badge Type - error
     */
    public static final String VERIFICATION_STATUS_BADGE_TYPE_ERROR = 'error';

    /**
     * @description Individual Achievement Unit Verification Status Badge Type - warning
     */
    public static final String VERIFICATION_STATUS_BADGE_TYPE_WARNING = 'warning';

    /**
     * @description Individual Achievement Unit Verification Status Badge Type - base
     */
    public static final String VERIFICATION_STATUS_BADGE_TYPE_BASE = 'base';

    /**
     * @description Individual Achievement Unit Verification Status Badge Type - inverse
     */
    public static final String VERIFICATION_STATUS_BADGE_TYPE_INVERSE = 'inverse';

    /**
     * @description Individual Achievement Unit Verification Status Badge Type - lightest
     */
    public static final String VERIFICATION_STATUS_BADGE_TYPE_LIGHTEST = 'lightest';

    /**
     * @description Individual Achievement Verification Status locking mode = Locked
     */
    public static final String VERIFICATION_STATUS_LOCKING_MODE_LOCKED = 'Locked';

    /**
     * @description Individual Achievement Verification Status locking mode = Unlocked
     */
    public static final String VERIFICATION_STATUS_LOCKING_MODE_UNLOCKED = 'Unlocked';


    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Individual_Achievement_Unit__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Individual_Achievement_Unit__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Individual_Achievement_Unit__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Achievement_Unit__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }


    
    //=============================================reduivy__IdvAu_Verification_Status_Config__mdt===================================================
    
    /**
     * @description List of reduivy__IdvAu_Verification_Status_Config__mdt
     */
    private static List<reduivy__IdvAu_Verification_Status_Config__mdt> verificationStatusConfigs;

    /**
     * @description Submission status configs metadata sorted according to Submission Status field
     * @return List<reduivy__IdvAu_Verification_Status_Config__mdt>
     */
    public static List<reduivy__IdvAu_Verification_Status_Config__mdt> getVerificationStatusConfigs(){

        if (verificationStatusConfigs == null) {
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Achievement_Unit__c.fields.reduivy__Verification_Status__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__IdvAu_Verification_Status_Config__mdt> configs = reduivy__IdvAu_Verification_Status_Config__mdt.getAll().values();
            List<reduivy__IdvAu_Verification_Status_Config__mdt> sortedConfigs = new List<reduivy__IdvAu_Verification_Status_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList) {
                if(ple.isActive()) {
                    for (reduivy__IdvAu_Verification_Status_Config__mdt config : configs) {
                        if (config.reduivy__Active__c && ple.getValue() == config.reduivy__Verification_Status__c) {
                            sortedConfigs.add(config);
                        }
                    }
                }
            }

            verificationStatusConfigs = sortedConfigs;
        }

        return verificationStatusConfigs;
    }


    
    /**
     * @description Open Verification statuses
     */
    private static List<String> openVerificationStatuses;

    /*
     * @description Return a list of open Verification status
     * @return List<String>
     */
    public static List<String> getOpenVerificationStatuses() {

        if (openVerificationStatuses == null) {
            openVerificationStatuses = new List<String>();

            for (reduivy__IdvAu_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {
                if (config.reduivy__Type__c == VERIFICATION_STATUS_TYPE_OPEN) {
                    openVerificationStatuses.add(config.reduivy__Verification_Status__c);
                }
            }
        }

        return openVerificationStatuses;
    }

    /**
     * @description Submitted statuses
     */
    private static List<String> submittedVerificationStatuses;

    /*
     * @description Return a list of Submitted verification status
     * @return List<String>
     */
    public static List<String> getSubmittedVerificationStatuses() {

        if (submittedVerificationStatuses == null) {
            submittedVerificationStatuses = new List<String>();

            for (reduivy__IdvAu_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {
                if (config.reduivy__Type__c == VERIFICATION_STATUS_TYPE_SUBMITTED) {
                    submittedVerificationStatuses.add(config.reduivy__Verification_Status__c);
                }
            }
        }

        return submittedVerificationStatuses;
    }

    /**
     * @description Review verification statuses
     */
    private static List<String> reviewVerificationStatuses;

    /*
     * @description Return a list of review verification status
     * @return List<String>
     */
    public static List<String> getReviewVerificationStatuses() {

        if (reviewVerificationStatuses == null) {
            reviewVerificationStatuses = new List<String>();

            for (reduivy__IdvAu_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {
                if (config.reduivy__Type__c == VERIFICATION_STATUS_TYPE_REVIEW) {
                    reviewVerificationStatuses.add(config.reduivy__Verification_Status__c);
                }
            }
        }

        return reviewVerificationStatuses;
    }

    /**
     * @description Verified verification statuses
     */
    private static List<String> verifiedVerificationStatuses;

    /*
     * @description Return a list of Verified verification status
     * @return List<String>
     */
    public static List<String> getVerifiedVerificationStatuses() {

        if (verifiedVerificationStatuses == null) {
            verifiedVerificationStatuses = new List<String>();

            for (reduivy__IdvAu_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {
                if (config.reduivy__Type__c == VERIFICATION_STATUS_TYPE_VERIFIED) {
                    verifiedVerificationStatuses.add(config.reduivy__Verification_Status__c);
                }
            }
        }

        return verifiedVerificationStatuses;
    }

    /**
     * @description Rejected verification statuses
     */
    private static List<String> rejectedVerificationStatuses;

    /*
     * @description Return a list of Rejected verification status
     * @return List<String>
     */
    public static List<String> getRejectedVerificationStatuses() {

        if (rejectedVerificationStatuses == null) {
            rejectedVerificationStatuses = new List<String>();

            for (reduivy__IdvAu_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {
                if (config.reduivy__Type__c == VERIFICATION_STATUS_TYPE_REJECTED) {
                    rejectedVerificationStatuses.add(config.reduivy__Verification_Status__c);
                }
            }
        }

        return rejectedVerificationStatuses;
    }

    /**
     * @description Cancelled statuses
     */
    private static List<String> cancelledVerificationStatuses;

    /*
     * @description Return a list of cancelled Requested verification status
     * @return List<String>
     */
    public static List<String> getCancelledVerificationStatuses() {

        if (cancelledVerificationStatuses == null) {
            cancelledVerificationStatuses = new List<String>();

            for (reduivy__IdvAu_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {
                if (config.reduivy__Type__c == VERIFICATION_STATUS_TYPE_CANCELLED) {
                    cancelledVerificationStatuses.add(config.reduivy__Verification_Status__c);
                }
            }
        }

        return cancelledVerificationStatuses;
    }

    private static Map<String, String> verificationStatusesBadgeType;

    public static Map<String, String> getVerificationStatusesBadgeType() {
        if(verificationStatusesBadgeType == null) {
            verificationStatusesBadgeType = new Map<String, String>();

            for (reduivy__IdvAu_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {

                String badgeType = String.isNotBlank(config.reduivy__Badge_Type__c) ? config.reduivy__Badge_Type__c : VERIFICATION_STATUS_BADGE_TYPE_BASE;
                
                verificationStatusesBadgeType.put(config.reduivy__Verification_Status__c, badgeType);
            }
        }

        return verificationStatusesBadgeType;
    }

    private static List<String> lockedVerificationStatuses;

    public static List<String> getLockedVerificationStatuses() {
        
        if(lockedVerificationStatuses == null) {
            lockedVerificationStatuses = new List<String>();

            for (reduivy__IdvAu_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {
                if(config.reduivy__Locking_Mode__c == VERIFICATION_STATUS_LOCKING_MODE_LOCKED) {
                    lockedVerificationStatuses.add(config.reduivy__Verification_Status__c);
                }
            }
        }

        return lockedVerificationStatuses;
    }

    private static List<String> unlockedVerificationStatuses;

    public static List<String> getUnlockedVerificationStatuses() {
        
        if(unlockedVerificationStatuses == null) {
            unlockedVerificationStatuses = new List<String>();

            for (reduivy__IdvAu_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {
                if(
                    config.reduivy__Locking_Mode__c == VERIFICATION_STATUS_LOCKING_MODE_UNLOCKED || 
                    String.isBlank(config.reduivy__Locking_Mode__c)
                ) {
                    unlockedVerificationStatuses.add(config.reduivy__Verification_Status__c);
                }
            }
        }

        return unlockedVerificationStatuses;
    }

}