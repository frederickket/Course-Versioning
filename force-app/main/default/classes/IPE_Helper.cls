/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Object Helper
 * @description Individual Program Enrollment object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001662 10-10-2023 dblack - added methods: getDraftStatuses(), getInProgressStatuses()
 * ISS-002203 16-01-2025 Jordan - added Completion Requirement values
 * ISS-002513 09-02-2026 XiRouh - Added validateIpfsWithMixedAutoUnitScopes()
 */
global inherited sharing class IPE_Helper implements SObject_Helper{

    /**
     * @description Status Type - Draft
     */
    public static final String STATUS_TYPE_DRAFT = 'Draft';

    /**
     * @description Status Type - In Progress
     */
    public static final String STATUS_TYPE_INPROGRESS = 'In_Progress';

    /**
     * @description Status Type - Completed
     */
    public static final String STATUS_TYPE_COMPLETED = 'Completed';

    /**
     * @description Status Type - Withdrawn
     */
    public static final String STATUS_TYPE_WITHDRAWN = 'Withdrawn';

    /**
     * @description Status Type - Deferred
     */
    public static final String STATUS_TYPE_DEFFERED = 'Deferred';

    /**
     * @description Status Type - Cancelled
     */
    public static final String STATUS_TYPE_CANCELLED = 'Cancelled';

    /**
     * @description Status Type - Preview
     */
    public static final String STATUS_TYPE_PREVIEW = 'Preview';

    /**
     * @description Study Pathway Mode - Custom
     */
    public static final String PATHWAYMODE_CUSTOM = 'Custom';

    /**
     * @description Study Pathway Mode - Default
     */

    public static final String PATHWAYMODE_DEFAULT = 'Default';

    /**
     * @description Completion Requirement - Mandatory
     */
    public static final String COMPLETION_REQUIREMENT_MANDATORY = 'Mandatory';

    /**
     * @description Completion Requirement - Optional
     */
    public static final String COMPLETION_REQUIREMENT_OPTIONAL = 'Optional';

    /**
     * @description Auto Enrollment - Auto
     */
    public static final String AUTO_ENROLLMENT_AUTO = 'Auto';

    /**
     * @description Auto Enrollment - Skipped
     */
    public static final String AUTO_ENROLLMENT_SKIPPED = 'Skipped';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel(){
        return SObjectType.reduivy__Individual_Program_Enrollment__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel(){
        return SObjectType.reduivy__Individual_Program_Enrollment__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName(){
        return SObjectType.reduivy__Individual_Program_Enrollment__c.getName();
    }
    
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Program_Enrollment__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description RecordTypeInfo map
     */
    private static Map<String, Schema.RecordTypeInfo> rtMap;

    /**
     * @description Return record type map by developername
     * @return Map<String, Schema.RecordTypeInfo>
     */
    global static Map<String, Schema.RecordTypeInfo> getRecordTypes(){
        if (rtMap == null){
            rtMap = Schema.SObjectType.reduivy__Individual_Program_Enrollment__c.getRecordtypeInfosByDeveloperName();
        }

        return rtMap;
    }

    /**
     * @description Return master enrollment record type id
     * @return Id
     */
    global static Id getMasterEnrollmentRecordTypeId(){
        return getRecordTypes().get('Master_Enrollment').getRecordTypeId();
    }

    /**
     * @description Return master enrollment record type UI label
     * @return String
     */
    global static String getMasterEnrollmentRecordTypeLabel(){
        return getRecordTypes().get('Master_Enrollment').getName();
    }

    /**
     * @description Return child enrollment record type id
     * @return Id
     */
    global static Id getChildEnrollmentRecordTypeId(){
        return getRecordTypes().get('Child_Enrollment').getRecordTypeId();
    }

    /**
     * @description Return child enrollment record type UI label
     * @return String
     */
    global static String getChildEnrollmentRecordTypeLabel(){
        return getRecordTypes().get('Child_Enrollment').getName();
    }

    /**
     * @description List of reduivy__IdvPe_Enrollment_Status_Config__mdt
     */
    private static List<reduivy__IdvPe_Enrollment_Status_Config__mdt> enrollmentStatusConfigs;
    /**
     * @description Enrollment status configs metadata sorted according to Enrollment Status field
     * @return List<reduivy__IdvPe_Enrollment_Status_Config__mdt>
     */
    public static List<reduivy__IdvPe_Enrollment_Status_Config__mdt> getEnrollmentStatusConfig(){

        if (enrollmentStatusConfigs == null){
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Program_Enrollment__c.fields.reduivy__Enrollment_Status__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__IdvPe_Enrollment_Status_Config__mdt> configs = reduivy__IdvPe_Enrollment_Status_Config__mdt.getAll().values();
            List<reduivy__IdvPe_Enrollment_Status_Config__mdt> sortedConfigs = new List<reduivy__IdvPe_Enrollment_Status_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList){
                if (ple.isActive()){
                    for (reduivy__IdvPe_Enrollment_Status_Config__mdt config : configs){
                        if (config.reduivy__Active__c && ple.getValue() == config.reduivy__Enrollment_Status__c){
                            sortedConfigs.add(config);
                        }
                    }
                }
            }

            enrollmentStatusConfigs = sortedConfigs;
        }

        return enrollmentStatusConfigs;
    }

    /**
     * @description Draft statuses
     */
    private static List<String> draftStatuses;

    /*
     * @description Return a list of draft enrollment status
     * @return List<String>
     */
    public static List<String> getDraftStatuses(){

        if (draftStatuses == null){
            draftStatuses = new List<String>();

            for (reduivy__IdvPe_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()){
                if (config.reduivy__Type__c == STATUS_TYPE_DRAFT){
                    draftStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return draftStatuses;
    }

    /**
     * @description In Progress statuses
     */
    private static List<String> inProgressStatuses;

    /*
     * @description Return a list of in progress enrollment status
     * @return List<String>
     */
    public static List<String> getInProgressStatuses(){

        if (inProgressStatuses == null){
            inProgressStatuses = new List<String>();

            for (reduivy__IdvPe_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()){
                if (config.reduivy__Type__c == STATUS_TYPE_INPROGRESS){
                    inProgressStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return inProgressStatuses;
    }

    /**
     * @description Completed statuses
     */
    private static List<String> completedStatuses;

    /*
     * @description Return a list of completed enrollment status
     * @return List<String>
     */
    public static List<String> getCompletedStatuses(){

        if (completedStatuses == null){
            completedStatuses = new List<String>();

            for (reduivy__IdvPe_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()){
                if (config.reduivy__Type__c == STATUS_TYPE_COMPLETED){
                    completedStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return completedStatuses;
    }

    /**
     * @description Preview statuses
     */
    private static List<String> previewStatuses;

    /*
     * @description Return a list of preview enrollment status
     * @return List<String>
     */
    public static List<String> getPreviewStatuses(){

        if (previewStatuses == null){
            previewStatuses = new List<String>();

            for (reduivy__IdvPe_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()){
                if (config.reduivy__Type__c == STATUS_TYPE_PREVIEW){
                    previewStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return previewStatuses;
    }

    /**
     * @description Withdrawn statuses
     */
    private static List<String> withdrawnStatuses;

    /*
     * @description Return a list of withdrawn status
     * @return List<String>
     */
    public static List<String> getWithdrawnStatuses(){

        if (withdrawnStatuses == null){
            withdrawnStatuses = new List<String>();

            for (reduivy__IdvPe_Enrollment_Status_Config__mdt config : getEnrollmentStatusConfig()){
                if (config.reduivy__Type__c == STATUS_TYPE_WITHDRAWN){
                    withdrawnStatuses.add(config.reduivy__Enrollment_Status__c);
                }
            }
        }

        return withdrawnStatuses;
    }

    /*
     * @description Return a list of positive enrollment status
     * @return List<String>
     */
    public static List<String> getPositiveStatuses(){

        List<String> statuses = new List<String>();
        statuses.addAll(getInProgressStatuses());
        statuses.addAll(getCompletedStatuses());

        return statuses;
    }

    /**
     * @description Get Individual Academic Profile Id from Individual Program Enrollment
     * @param ipeRecord
     * @return Id
     */
    public static Id getIpfId(reduivy__Individual_Program_Enrollment__c ipeRecord) {
        Id academicProfileId = String.isNotBlank(ipeRecord?.reduivy__Master_Enrollment__c) 
        ? ipeRecord?.reduivy__Master_Enrollment__r?.reduivy__Individual_Academic_Profile__c 
        : ipeRecord?.reduivy__Individual_Academic_Profile__c;
        
        return academicProfileId;
    }

    /**
     * @description Checks if a list of IPEs contains a mixture of auto unit recognition scopes.
     * @param ipfIdWithIpes <ipfId, List<IPE>>
     * @return Set<Id> ipfIdsWithMixedScopes
     */
    public static Set<Id> validateIpfsWithMixedAutoUnitScopes(Map<Id, List<reduivy__Individual_Program_Enrollment__c>> ipfIdWithIpes) {
        Set<Id> ipfIdsWithMixedScopes = new Set<Id>();
        
        if(!ipfIdWithIpes.isEmpty()) {
            for(Id ipfId : ipfIdWithIpes.keySet()) {
                Set<String> scopes = new Set<String>();
                for(reduivy__Individual_Program_Enrollment__c ipe : ipfIdWithIpes.get(ipfId)) {
                    if(String.isNotBlank(ipe.reduivy__Study_Program__c) && String.isNotBlank(ipe.reduivy__Study_Program__r?.reduivy__Auto_Unit_Recognition_Scope__c)) {
                        scopes.add(ipe.reduivy__Study_Program__r.reduivy__Auto_Unit_Recognition_Scope__c);
                    }
                }
                
                if(scopes.size() > 1) {
                    ipfIdsWithMixedScopes.add(ipfId);
                }
            }
        }

        return ipfIdsWithMixedScopes;
    }
}