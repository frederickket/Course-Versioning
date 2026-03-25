/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Test
 * @description Test class for REDU_AppSetting_UTIL
 * @changehistory
 * ISS-001816 18-12-2023 Lean - Added new util methods.
 * ISS-001978 25-07-2024 Xirouh - Added new util methods.
 * ISS-002784 28-01-2026 Lean - Make exclude gpa enabled by default
 */
@IsTest
public inherited sharing class REDU_AppSetting_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    @TestSetup
    static void makeData(){
        // Create settings
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(USR_Helper.getApiName(), true);
        }
    }

    /**
     * @description Test utility method
     */
    @IsTest
    static void testUtilMethods(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        System.runAs(ADMIN_USER){
            System.Assert.areEqual(true, REDU_AppSetting_UTIL.getOrgDefaultSetting().Name != null);

            REDU_Logging_UTIL.debug('REDU_AppSetting_UTIL.getSetting()', REDU_AppSetting_UTIL.getSetting());

            System.Assert.areEqual(true, REDU_AppSetting_UTIL.getSetting().Name != null);
            System.Assert.areEqual(true, REDU_AppSetting_UTIL.isDebugMode());
            System.Assert.areEqual(true, REDU_AppSetting_UTIL.isPreservePreEnrolmentWaitlistDate());
            System.Assert.areEqual(true, REDU_AppSetting_UTIL.isExcludeGpaForRepeatedUnit()); //ISS-002784
            System.Assert.areEqual(false, REDU_AppSetting_UTIL.isExternalPortalSyncEnabled());

            for (Profile profile : [SELECT Id, Name FROM Profile WHERE Name IN ('REDU - Student', 'REDU - Faculty')]) {
                if (profile.Name == 'REDU - Student') {
                    System.Assert.areEqual(profile.Id, REDU_AppSetting_UTIL.getStudentProfileId());
                } else {
                    System.Assert.areEqual(profile.Id, REDU_AppSetting_UTIL.getFacultyProfileId());
                }
            }

            for (PermissionSet permSet : [SELECT Id, Name FROM PermissionSet WHERE Name IN ('REDU_Student', 'REDU_Faculty', 'REDU_Student_Unmanaged', 'REDU_Faculty_Unmanaged')]) {
                if (permSet.Name == 'REDU_Student' || permSet.Name == 'REDU_Student_Unmanaged') {
                    System.Assert.areEqual(2, REDU_AppSetting_UTIL.getStudentPermissionSetIds().size());
                    System.Assert.isTrue(REDU_AppSetting_UTIL.getStudentPermissionSetIds().contains(permSet.Id));
                } else {
                    System.Assert.areEqual(2, REDU_AppSetting_UTIL.getFacultyPermissionSetIds().size());
                    System.Assert.isTrue(REDU_AppSetting_UTIL.getFacultyPermissionSetIds().contains(permSet.Id));
                }
            }

            System.Assert.areEqual('{LastName} Administrative Account', REDU_AppSetting_UTIL.getAdministrativeAccountNameFormat());
            System.Assert.isNotNull(REDU_AppSetting_UTIL.getDefaultOwnerId(), 'The default owner id should have populated.');
            System.Assert.isNotNull(REDU_AppSetting_UTIL.getIntegrationQueueBatchSize(), 'The integration queue batch size should have returned.');

            System.Assert.isFalse(REDU_AppSetting_UTIL.getIndividualAcademicProfileIdentifierMapping().isEmpty());
            System.Assert.areEqual('Academic Profile - {reduivy__Contact_Name__c} ({reduivy__Study_Program_Academic_Level__c})', REDU_AppSetting_UTIL.getIndividualAcademicProfileNameFormat());
            System.Assert.areEqual(IPF_Helper.PROFILE_GEN_TYPE_BYIPE, REDU_AppSetting_UTIL.getIndividualAcademicProfileGenerationType());

            System.Assert.areEqual('/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId={0}&contentId={1}', REDU_AppSetting_UTIL.getFileRenditionUrl());
        }
        
        Test.stopTest();

    }

}