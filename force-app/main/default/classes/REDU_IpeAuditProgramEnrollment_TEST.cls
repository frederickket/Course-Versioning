/**
 * @author      WDCi (VTan)
 * @date        Oct 2023
 * @group       Test
 * @description Test class for REDU_IpeAuditProgramEnrollment_LCTRL
 * @changehistory
 * ISS-001753 23-10-2023 VTan - New class
 */
@isTest
public inherited sharing class REDU_IpeAuditProgramEnrollment_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Default method to setup required data for automated test
     */
    @TestSetup
    static void makeData(){

        // Create settings
		testFactory.setupDefaultSettings();
        
        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {

            Test.startTest();
            
            testFactory.initMasterData(SPL_Helper.getApiName());
            testFactory.initOfferingData(SOF_Helper.getApiName());
            testFactory.initStudentData(IPE_Helper.getApiName(), true);

            Test.stopTest();
        }

    }

    /**
     * @description Test as admin for REDU_IpeAuditProgramEnrollment_LCTRL
     */
    @isTest   
    static void testForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        System.runAs(ADMIN_USER){
            Test.startTest();
            
            REDU_LightningResponse objResponse = REDU_IpeAuditProgramEnrollment_LCTRL.getIdvPlanStructureParentGroups(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpeAuditProgramEnrollment_LCTRL');

            Test.stopTest();
        }
    }

    /**
     * @description Test as setup user for REDU_IpeAuditProgramEnrollment_LCTRL
     */
    @isTest   
    static void testForSetupUser() {

        User setupUser = testFactory.getSetupUser();
        Boolean hasError = false;

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        Test.startTest();
        try{
            System.runAs(setupUser){
                
                REDU_LightningResponse objResponse = REDU_IpeAuditProgramEnrollment_LCTRL.getIdvPlanStructureParentGroups(masterIPE.Id);
            }
        } catch (Exception exp) {

            REDU_Logging_UTIL.debug('testForSetupUser', exp.getMessage());
            hasError = true;
        }
        Test.stopTest();

        System.Assert.areEqual(true, hasError, 'Setup user should not have access to RIO Education fields.');
        
    }

    /**
     * @description Test as student user for REDU_IpeAuditProgramEnrollment_TEST
     */
    @isTest   
    static void testForStudentUser() {

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

        System.runAs(studentUser){
            Test.startTest();
            
            REDU_LightningResponse objResponse = REDU_IpeAuditProgramEnrollment_LCTRL.getIdvPlanStructureParentGroups(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpeAuditProgramEnrollment_LCTRL');
            
            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty user for REDU_IpeAuditProgramEnrollment_LCTRL
     */
    @isTest   
    static void testForFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        System.runAs(FACULTY_USER){
            
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpeAuditProgramEnrollment_LCTRL.getIdvPlanStructureParentGroups(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpeAuditProgramEnrollment_LCTRL');

            Test.stopTest();
        }
    }
}