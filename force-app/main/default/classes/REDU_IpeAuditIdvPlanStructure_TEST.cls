/**
 * @author      WDCi (VTan)
 * @date        Oct 2023
 * @group       Test
 * @description Test class for REDU_IpeAuditIdvPlanStructure_LCTRL
 * @changehistory
 * ISS-001753 23-10-2023 VTan - New class
 * ISS-002736 25-11-2025 XiRouh - added enableWrapText param
 */
@isTest
public inherited sharing class REDU_IpeAuditIdvPlanStructure_TEST{

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String STUDY_UNIT = 'BUS101';

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
            
            testFactory.initMasterData(null);
            testFactory.initOfferingData(SOF_Helper.getApiName());
            testFactory.initStudentData(IPE_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpeAuditIdvPlanStructure_LCTRL
     */
    @isTest   
    static void testForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'Name;reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c;reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Attempted__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Earned__c;reduivy__Individual_Enrollment__r.reduivy__Grade_Result__c';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID LIMIT 5];

        Id ispUnitRTID = IPS_Helper.getUnitRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsUnitList = [SELECT Id, Name FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : ispUnitRTID LIMIT 5];

        System.runAs(ADMIN_USER){
            Test.startTest();
            
            for(reduivy__Individual_Plan_Structure__c ipsGroup : ipsGroupList){

                REDU_LightningResponse objResponse = REDU_IpeAuditIdvPlanStructure_LCTRL.getIdvPlanStructureChildren(ipsGroup.Id, ipsUnitFieldString, true, true, true, '_self', UserInfo.getLanguage(), true);
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');
            }

            for(reduivy__Individual_Plan_Structure__c ipsUnit : ipsUnitList){

                REDU_LightningResponse objResponse = REDU_IpeAuditIdvPlanStructure_LCTRL.setPrimaryIpsUnit(JSON.serialize(ipsUnit));
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as setup user for REDU_IpeAuditIdvPlanStructure_LCTRL
     */
    @isTest   
    static void testForSetupUser() {

        User setupUser = testFactory.getSetupUser();
        Boolean hasError = false;

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'Name;reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c;reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Attempted__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Earned__c;reduivy__Individual_Enrollment__r.reduivy__Grade_Result__c';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID];

        Test.startTest();
        try{
            System.runAs(setupUser){
                
                for(reduivy__Individual_Plan_Structure__c ipsGroup : ipsGroupList){

                    REDU_LightningResponse objResponse = REDU_IpeAuditIdvPlanStructure_LCTRL.getIdvPlanStructureChildren(ipsGroup.Id, ipsUnitFieldString, true, true, true, '_self', UserInfo.getLanguage(), true);
                    System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');
                }
            }
        } catch (Exception exp) {

            REDU_Logging_UTIL.debug('testForSetupUser', exp.getMessage());
            hasError = true;
        }
        Test.stopTest();

        System.Assert.areEqual(true, hasError, 'Setup user should not have access to RIO Education fields.');
        
    }

    /**
     * @description Test as student user for REDU_IpeAuditIdvPlanStructure_LCTRL
     */
    @isTest   
    static void testForStudentUser() {

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'Name;reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c;reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Attempted__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Earned__c;reduivy__Individual_Enrollment__r.reduivy__Grade_Result__c';
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID];

        System.runAs(studentUser){
            Test.startTest();
            
            for(reduivy__Individual_Plan_Structure__c ipsGroup : ipsGroupList){

                REDU_LightningResponse objResponse = REDU_IpeAuditIdvPlanStructure_LCTRL.getIdvPlanStructureChildren(ipsGroup.Id, ipsUnitFieldString, true, true, true, '_self', UserInfo.getLanguage(), true);
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty user for REDU_IpeAuditIdvPlanStructure_LCTRL
     */
    @isTest   
    static void testForFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'Name;reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c;reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Attempted__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Earned__c;reduivy__Individual_Enrollment__r.reduivy__Grade_Result__c';
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID];

        System.runAs(FACULTY_USER){
            
            Test.startTest();
            
            for(reduivy__Individual_Plan_Structure__c ipsGroup : ipsGroupList){

                REDU_LightningResponse objResponse = REDU_IpeAuditIdvPlanStructure_LCTRL.getIdvPlanStructureChildren(ipsGroup.Id, ipsUnitFieldString, true, true, true, '_self', UserInfo.getLanguage(), true);
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');
            }
            Test.stopTest();
        }
    }
}