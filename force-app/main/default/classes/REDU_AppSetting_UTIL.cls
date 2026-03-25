/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Setting
 * @description App setting util
 * @changehistory
 * ISS-001813 23-11-2023 Lean - new default owner id
 * ISS-001816 18-12-2023 Lean - new academic profile methods
 * ISS-001858 19-03-2024 VTan - new license schedule job frequency
 * ISS-001920 11-06-2024 Lean - new notification type id
 * ISS-001978 24-07-2024 Xirouh - new Integration Queue batch size and Enable External Portal Sync Setting
 * ISS-002179 06-12-2024 XW - Functionality of getFaDisbursementBatchSize is moved to getApplyFABatchSize and getFaDisbursementBatchSize is reserved
 * ISS-002230 03-02-2025 XW - added new setting isRecordValueTranslationEnabled
 * ISS-002230 03-02-2025 XW - added new setting isUsingStudyIntakeGroup
 */
global inherited sharing class REDU_AppSetting_UTIL {
    
    /**
     * @description Static variable for reduivy__RIO_Education_Ivy_Settings__c
     */
    private static reduivy__RIO_Education_Ivy_Settings__c settingInstance;

    /**
     * @description Get the org default app settings
     * @return reduivy__RIO_Education_Ivy_Settings__c
     */
    global static reduivy__RIO_Education_Ivy_Settings__c getOrgDefaultSetting(){
        return reduivy__RIO_Education_Ivy_Settings__c.getOrgDefaults();
    }

    /**
     * @description Get the app settings based on current user context
     * @return reduivy__RIO_Education_Ivy_Settings__c
     */
    global static reduivy__RIO_Education_Ivy_Settings__c getSetting(){
        //In test, we will always get the latest settings to avoid caching issue after updating the setting in test class
        if(settingInstance == null || Test.isRunningTest()){
            settingInstance = reduivy__RIO_Education_Ivy_Settings__c.getInstance();
        }

        return settingInstance;
    }

    /**
     * @description App enabled
     * @return Boolean
     */
    global static Boolean isRioEducationEnabled() {
        return getSetting().reduivy__Enable_RIO_Education__c;
    }

    /**
     * @description Return Administrative account name format
     * @return String
     */
    global static String getAdministrativeAccountNameFormat() {
        return getSetting().reduivy__Administrative_Account_Name_Format__c;
    }

    /**
     * @description Debug mode checkbox
     * @return Boolean
     */
    global static Boolean isDebugMode() {
        return getSetting().reduivy__Debug_Mode__c;
    }

    /**
     * @descripton Return student user profile id
     * @return Id
     */
    global static Id getStudentProfileId() {
        String profileId = getSetting().reduivy__Student_Profile_Id__c;

        if (String.isNotBlank(profileId)) {
            return Id.valueOf(profileId);
        }
        
        return null;
    }

    /**
     * @description Return student permission id list
     * @return List<Id>
     */
    global static List<Id> getStudentPermissionSetIds() {
        List<Id> permissionSetIds = new List<Id>();

        String permissionSetStr = getSetting().reduivy__Student_Permission_Set_Ids__c;

        if (String.isNotBlank(permissionSetStr)) {
            for (String permSetId : permissionSetStr.split(REDU_List_UTIL.DELIMITER)) {
                if (String.isNotBlank(permSetId)) {
                    permissionSetIds.add(Id.valueOf(permSetId));
                }
            }
        }

        return permissionSetIds;
    }

    /**
     * @descripton Return faculty user profile id
     * @return Id
     */
    global static Id getFacultyProfileId() {
        String profileId = getSetting().reduivy__Faculty_Profile_Id__c;

        if (String.isNotBlank(profileId)) {
            return Id.valueOf(profileId);
        }
        
        return null;
    }

    /**
     * @description Return faculty permission id list
     * @return List<Id>
     */
    global static List<Id> getFacultyPermissionSetIds() {
        List<Id> permissionSetIds = new List<Id>();

        String permissionSetStr = getSetting().reduivy__Faculty_Permission_Set_Ids__c;

        if (String.isNotBlank(permissionSetStr)) {
            for (String permSetId : permissionSetStr.split(REDU_List_UTIL.DELIMITER)) {
                if (String.isNotBlank(permSetId)) {
                    permissionSetIds.add(Id.valueOf(permSetId));
                }
            }
        }

        return permissionSetIds;
    }

    /**
     * @description Return Preserve pre-enrollment waitlist date
     * @return Boolean
     */
    global static Boolean isPreservePreEnrolmentWaitlistDate() {
        return getSetting().reduivy__Preserve_pre_enrollment_waitlist_date__c;
    }

    /**
     * @description Return Default Owner Id
     * @return Id
     */
    global static Id getDefaultOwnerId() {
        String defaultOwnerId = getSetting().reduivy__Default_Owner_Id__c;

        if (String.isNotBlank(defaultOwnerId)) {
            return Id.valueOf(defaultOwnerId);
        }
        
        return null;
    }

    /**
     * @description Return individual academic profile identify mapping e.g, IPEField__c=IPF_Field__c;IPEField__c=IPF_Field__c;
     * @return Map<String, String> IPEField__c=IPEField__c
     */
    global static Map<String, String> getIndividualAcademicProfileIdentifierMapping() {
        Map<String, String> mapping = new Map<String, String>();

        String mappingRaw = getSetting().reduivy__Academic_Profile_Identifier_Mapping__c;

        if (String.isNotBlank(mappingRaw)) {
            //split IPEField___c=IPF_Field__c;IPEField___c=IPF_Field__c;
            for (String mapKey : mappingRaw.split(REDU_List_UTIL.DELIMITER)) {
                if (String.isNotBlank(mapKey)) {
                    //split IPEField___c=IPF_Field__c
                    List<String> mapInfo = mapKey.split('=');

                    if (mapInfo.size() == 2) {
                        mapping.put(mapInfo.get(0), mapInfo.get(1));
                    }
                }
            }
        }

        return mapping;
    }

    /**
     * @description Return the record name format for individual academic profile
     * @return String
     */
    global static String getIndividualAcademicProfileNameFormat() {
        return getSetting().reduivy__Academic_Profile_Name_Format__c;
    }

    /**
     * @description Return the license schedule job's frequency
     * @return String
     */
    global static String getLicenseScheduleJobFrequency() {
        if (String.isNotBlank(getSetting().reduivy__License_Schedule_Job_Frequency__c)) {
            return getSetting().reduivy__License_Schedule_Job_Frequency__c;
        }

        return '0 0 0 ? * SUN';
    }

    /**
     * @description Return the individual academic profile generation type, supported options are: By Individual Program Enrollment, By Identifier Mapping
     * @return String
     */
    global static String getIndividualAcademicProfileGenerationType() {
        String genType = getSetting().reduivy__Academic_Profile_Generation_Type__c;

        if (String.isBlank(genType)) {
            genType = 'By Individual Program Enrollment';
        }

        return genType;
    }

    /**
     * @description Return the exclude gpa calculation for repeated individual enrollment
     * @return Boolean
     */
    global static Boolean isExcludeGpaForRepeatedUnit() {
        return getSetting().reduivy__Exclude_GPA_For_Repeated_Unit__c;
    }

    /**
     * @description Return Academic Term Funding Disbursement Batch Size
     * @return Integer
     */
    global static Integer getFaDisbursementBatchSize() {

        if (getSetting().reduivy__Academic_Term_FA_Disbursement_Batch_Size__c != null && getSetting().reduivy__Academic_Term_FA_Disbursement_Batch_Size__c > 0) {
            return getSetting().reduivy__Academic_Term_FA_Disbursement_Batch_Size__c.intValue();
        }
        
        return 50;
    }

    /**
     * @description Return Academic Term Apply FA Batch Size
     * @return Integer
     */
    global static Integer getApplyFABatchSize(){
        if(getSetting().reduivy__Academic_Term_Apply_FA_Batch_Size__c != null && getSetting().reduivy__Academic_Term_Apply_FA_Batch_Size__c > 0){
            return getSetting().reduivy__Academic_Term_Apply_FA_Batch_Size__c.intValue();
        }

        return 50;
    }

    /**
     * @description Return Academic Term Funding Disbursement Batch Size
     * @return Integer
     */
    global static Integer getGenerateOrdersBatchSize() {

        Decimal batchSize = getSetting().reduivy__Academic_Term_Generate_Orders_Batch_Size__c;

        if (batchSize != null && batchSize > 0) {
            return batchSize.intValue();
        }
        
        return 50;
    }

    /* @description Return Notification Type Id
     * @return Id
     */
    global static Id getNotificationTypeId() {

        String nftId = getSetting().reduivy__Notification_Type_Id__c;

        if (String.isNotBlank(nftId)) {
            return Id.valueOf(nftId);
        }

        return null;
    }

    /**
     * @description Return Integration Queue batch size
     * @return Integer
     */
    global static Integer getIntegrationQueueBatchSize() {

        if (getSetting().reduivy__Integration_Queue_Batch_Size__c != null && getSetting().reduivy__Integration_Queue_Batch_Size__c > 0) {
            return getSetting().reduivy__Integration_Queue_Batch_Size__c.intValue();
        }
        
        return 5;
    }

    /**
     * @description Return External Portal Sync Setting
     * @return Boolean
     */
    global static Boolean isExternalPortalSyncEnabled() {
        return getSetting().reduivy__Enable_External_Portal_Sync__c;
    }

    /**
     * @description Return salesforce file rendition url
     * @return String
     */
    global static String getFileRenditionUrl() {

        String fileRenditionUrl = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId={0}&contentId={1}';

        if (String.isNotBlank(getSetting().reduivy__File_Rendition_Url__c)) {
            fileRenditionUrl = getSetting().reduivy__File_Rendition_Url__c;
        }

        if (ORG_Helper.isCommunity()) {
            return ORG_Helper.getCurrentCommunitySitePath() + fileRenditionUrl;
        }

        return fileRenditionUrl;
    }

    /**
     * @description return true if create translation map should be created when any record is created
     * @return   return description
     */
    global static Boolean isRecordValueTranslationEnabled() {
        return getSetting().reduivy__Enable_Record_Value_Translation__c;
    }

    /**
     * @description Return Maximum Sequence Number
     * @return Decimal
     */
    global static Decimal getMaximumSequenceNumber() {
        if (getSetting().reduivy__Maximum_Sequence_Number__c != null && getSetting().reduivy__Maximum_Sequence_Number__c > 0) {
            return getSetting().reduivy__Maximum_Sequence_Number__c.intValue();
        }
        
        return 500;
    }

    /**
     * @description return true if the study intake group object is used
     * @return   Boolean
     */
    global static Boolean isUsingStudyIntakeGroup() {
        return getSetting().reduivy__Use_Study_Intake_Group__c;
    }
}