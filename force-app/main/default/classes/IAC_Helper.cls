/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Object Helper
 * @description Individual Achievement object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002633 17-11-2026 XW - added methods to get idvac wizard config
 */
global inherited sharing class IAC_Helper implements SObject_Helper {
    /**
     * @description Individual Achievement object Completion Status picklist constants
     */
    public static final String COMPLETION_STATUS_AWARDED = 'Awarded';

    /**
     * @description Individual Achievement object Academic Level picklist constants
     */
    public static final String ACADEMIC_LEVEL_DIPLOMA = 'Diploma';

    /**
     * @description Individual Achievement object Verification Status picklist constants
     */
    public static final String VERIFICATION_STATUS_REVIEWING = 'Reviewing';

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
     * @description Individual Achievement Verification Status Badge Type - success
     */
    public static final String VERIFICATION_STATUS_BADGE_TYPE_SUCCESS = 'success';

    /**
     * @description Individual Achievement Verification Status Badge Type - error
     */
    public static final String VERIFICATION_STATUS_BADGE_TYPE_ERROR = 'error';

    /**
     * @description Individual Achievement Verification Status Badge Type - warning
     */
    public static final String VERIFICATION_STATUS_BADGE_TYPE_WARNING = 'warning';

    /**
     * @description Individual Achievement Verification Status Badge Type - base
     */
    public static final String VERIFICATION_STATUS_BADGE_TYPE_BASE = 'base';

    /**
     * @description Individual Achievement Verification Status Badge Type - inverse
     */
    public static final String VERIFICATION_STATUS_BADGE_TYPE_INVERSE = 'inverse';

    /**
     * @description Individual Achievement Verification Status Badge Type - lightest
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
     * @description Individual Achievement Type - 'Academic'
     */
    public static final String TYPE_ACADEMIC = 'Academic';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Individual_Achievement__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Individual_Achievement__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Individual_Achievement__c.getName();
    }
	
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Achievement__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    //=============================================reduivy__IdvAc_Verification_Status_Config__mdt===================================================
    
    /**
     * @description List of reduivy__IdvAc_Verification_Status_Config__mdt
     */
    private static List<reduivy__IdvAc_Verification_Status_Config__mdt> verificationStatusConfigs;

    /**
     * @description Verification status configs metadata sorted according to Verification Status field
     * @return List<reduivy__IdvAc_Verification_Status_Config__mdt>
     */
    public static List<reduivy__IdvAc_Verification_Status_Config__mdt> getVerificationStatusConfigs(){

        if (verificationStatusConfigs == null) {
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Achievement__c.fields.reduivy__Verification_Status__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__IdvAc_Verification_Status_Config__mdt> configs = reduivy__IdvAc_Verification_Status_Config__mdt.getAll().values();
            List<reduivy__IdvAc_Verification_Status_Config__mdt> sortedConfigs = new List<reduivy__IdvAc_Verification_Status_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList) {
                if(ple.isActive()) {
                    for (reduivy__IdvAc_Verification_Status_Config__mdt config : configs) {
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

            for (reduivy__IdvAc_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {
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

            for (reduivy__IdvAc_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {
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

            for (reduivy__IdvAc_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {
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

            for (reduivy__IdvAc_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {
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

            for (reduivy__IdvAc_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {
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

            for (reduivy__IdvAc_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {
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

            for (reduivy__IdvAc_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {

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

            for (reduivy__IdvAc_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {
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

            for (reduivy__IdvAc_Verification_Status_Config__mdt config : getVerificationStatusConfigs()) {
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

    //=============================================reduivy__Idv_Achievement_Wizard_Form_Config__mdt===================================================

    static List<IdvAcWizardFormWrapper> idvAchievementWizardFromList;

    public static List<IdvAcWizardFormWrapper> getIdvAchievementWizardFormList() {
        if (idvAchievementWizardFromList == null) {

            idvAchievementWizardFromList = new List<IdvAcWizardFormWrapper>();
            List<reduivy__Idv_Achievement_Wizard_Form_Config__mdt> configs = reduivy__Idv_Achievement_Wizard_Form_Config__mdt.getAll().values();

            for (reduivy__Idv_Achievement_Wizard_Form_Config__mdt config : configs) {
                if (config.reduivy__Active__c) {

                    IdvAcWizardSubgroup agreement = new IdvAcWizardSubgroup (
                        config.reduivy__Show_Agreement__c,
                        config.reduivy__Agreement_Label__c,
                        config.reduivy__Agreement_Required__c,
                        config.reduivy__Agreement_Fallback_Field__c,
                        true
                    );

                    IdvAcWizardSubgroup department = new IdvAcWizardSubgroup (
                        config.reduivy__Show_Department__c,
                        config.reduivy__Department_Label__c,
                        config.reduivy__Department_Required__c,
                        config.reduivy__Department_Fallback_Field__c,
                        true
                    );

                    IdvAcWizardSubgroup agreementRecognition = new IdvAcWizardSubgroup(
                        config.reduivy__Show_Agreement_Recognition__c,
                        config.reduivy__Agreement_Recognition_Label__c,
                        config.reduivy__Agreement_Recognition_Required__c,
                        config.reduivy__Agreement_Recognition_Fallback_Field__c,
                        true
                    );

                    IdvAcWizardSubgroup unitCode = new IdvAcWizardSubgroup(
                        config.reduivy__Show_Unit_Code_Field__c,
                        null,
                        null,
                        config.reduivy__Unit_Code_Fallback_Field__c,
                        false
                    );

                    IdvAcWizardSubgroup unitName = new IdvAcWizardSubgroup(
                        config.reduivy__Show_Unit_Name_Field__c,
                        null,
                        null,
                        config.reduivy__Unit_Name_Fallback_Field__c,
                        false
                    );

                    IdvAcWizardFormWrapper newWrapper = new IdvAcWizardFormWrapper (
                        config.Id,
                        config.reduivy__Wizard_Config__c,
                        config.reduivy__Composite_Key__c,
                        config.reduivy__Composite_Key_Value__c,
                        config.reduivy__Default__c,
                        config.reduivy__Additional_Info_Field_Set__c,
                        agreement,
                        department,
                        agreementRecognition,
                        config.reduivy__Show_Unit_Table__c,
                        config.reduivy__Unit_Required__c,
                        unitCode,
                        unitName,
                        config.reduivy__Unit_Additional_Info_Field_Set__c,
                        config.reduivy__Unit_Table_Fields__c
                    );

                    idvAchievementWizardFromList.add(newWrapper);
                }
            }
        }

        return idvAchievementWizardFromList;
    }

    static Map<String, List<IdvAcWizardFormWrapper>> idvAcWizardFormGroupByWizardConfigName;

    public static Map<String, List<IdvAcWizardFormWrapper>> getIdvAcWizardFormGroupByWizardConfigName() {
        if(idvAcWizardFormGroupByWizardConfigName == null) {
            idvAcWizardFormGroupByWizardConfigName = new Map<String, List<IdvAcWizardFormWrapper>>();
            
            Map<Id, reduivy__Wizard_Config__mdt> wizardConfigsMap = REDU_WizardConfigManager.getWizardConfigsMap();
            List<IdvAcWizardFormWrapper> wrapperList = getIdvAchievementWizardFormList();
            for(IdvAcWizardFormWrapper wrapper : wrapperList) {
                Id wizardConfigId = wrapper.wizardConfig;
                reduivy__Wizard_Config__mdt wizardConfig = wizardConfigsMap.get(wizardConfigId);
                String wizardConfigName = wizardConfig.DeveloperName;

                if(!idvAcWizardFormGroupByWizardConfigName.containsKey(wizardConfigName)) {
                    idvAcWizardFormGroupByWizardConfigName.put(wizardConfigName, new List<IdvAcWizardFormWrapper>());
                }
                idvAcWizardFormGroupByWizardConfigName.get(wizardConfigName).add(wrapper);
            }
        }

        return idvAcWizardFormGroupByWizardConfigName;
    }

    public class IdvAcWizardFormWrapper {
        public Id metadataId {get; set;}
        public Id wizardConfig {get; set;}
        public String compositeKey {get; set;}
        public String compositeKeyValue {get; set;}
        public Boolean isDefault {get; set;}
        public IdvAcWizardSubgroup agreement {get; set;}
        public IdvAcWizardSubgroup department {get; set;}
        public IdvAcWizardSubgroup agreementRecognition {get; set;}
        public String additionalInfoFieldSet {get; set;}
        public Boolean showUnitTable {get; set;}
        public Boolean unitRequired {get; set;}
        public IdvAcWizardSubgroup unitCode {get; set;}
        public IdvAcWizardSubgroup unitName {get; set;}
        public String unitAdditionalInfoFieldSet {get; set;}
        public String unitTableFields {get; set;}
        
        public IdvAcWizardFormWrapper(
            Id metadataId, Id wizardConfig, String compositeKey, String compositeKeyValue, Boolean isDefault, String additionalInfoFieldSet, 
            IdvAcWizardSubgroup agreement, IdvAcWizardSubgroup department, IdvAcWizardSubgroup agreementRecognition, 
            Boolean showUnitTable, Boolean unitRequired, IdvAcWizardSubgroup unitCode, IdvAcWizardSubgroup unitName, String unitAdditionalInfoFieldSet, String unitTableFields
        ) {
            this.metadataId = metadataId;
            this.wizardConfig = wizardConfig;
            this.compositeKey = compositeKey;
            this.compositeKeyValue = compositeKeyValue;
            this.isDefault = isDefault;
            this.agreement = agreement;
            this.department = department;
            this.agreementRecognition = agreementRecognition;
            this.additionalInfoFieldSet = additionalInfoFieldSet;
            this.showUnitTable = showUnitTable;
            this.unitRequired = unitRequired;
            this.unitCode = unitCode;
            this.unitName = unitName;
            this.unitAdditionalInfoFieldSet = unitAdditionalInfoFieldSet;
            this.unitTableFields = unitTableFields;

            iacReferencedFields.addAll(REDU_StringMerge_UTIL.extractFieldNames(null, compositeKey).values());

        }

        public Map<String, String> extractAllLabelsValue() {
            Set<String> fieldValueSet = new Set<String> {
                this.compositeKey, this.compositeKeyValue, 
                this.agreement.fallbackField, this.agreement.label, 
                this.department.fallbackField, this.department.label, 
                this.agreementRecognition.fallbackField, this.agreementRecognition.label, 
                this.additionalInfoFieldSet,
                this.unitCode.fallbackField, this.unitName.fallbackField, 
                this.unitAdditionalInfoFieldSet
            };

            Map<String, String> labelMap = new Map<String, String>();
            for(String fieldValue : fieldValueSet) {
                if(REDU_Label_UTIL.isLabelFormatted(fieldValue)) {
                    labelMap.put(fieldValue, REDU_Label_UTIL.getLabelValue(fieldValue));
                }
            }

            return labelMap;
        }

    }

    private class IdvAcWizardSubgroup {
        public Boolean showSubgroup {get; set;}
        public String label {get; set;}
        public Boolean isRequired {get; set;}
        public String fallbackField {get; set;}

        public IdvAcWizardSubgroup( Boolean showSubgroup, String label, Boolean isRequired, String fallbackField, Boolean isIac) {
            this.showSubgroup = showSubgroup;
            this.label = label;
            this.isRequired = isRequired;
            this.fallbackField = fallbackField;
            if(String.isNotBlank(fallbackField)) {
                if(isIac) {
                    iacReferencedFields.add(fallbackField);
                } else {
                    iauReferencedFields.add(fallbackField);
                }
            }
        }
    }

    static Set<String> iacReferencedFields = new Set<String>();
    static Set<String> iauReferencedFields = new Set<String>();

    public static Set<String> getIacReferencedFields() {
        if(idvAchievementWizardFromList == null) {
            getIdvAchievementWizardFormList();
        }

        return iacReferencedFields;
    }

    public static Set<String> getIauReferencedFields() {
        if(idvAchievementWizardFromList == null) {
            getIdvAchievementWizardFormList();
        }

        return iauReferencedFields;
    }
    


}