/**
 * @author      WDCi (XW)
 * @date        Jan 2024
 * @group       Individual Score
 * @description Test class for ISC_DeleteScoreDetails_EXE
 * @changehistory
 * ISS-002636 07-10-2025 XW - new class
 */
@IsTest
public inherited sharing class ISC_DeleteScoreDetails_TEST {

    static String SRC_SCF = 'SCF_Application';
    static final String SRC_CON = 'sandydoe@redu.example';

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
        	
            testFactory.initMasterData(SCR_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initStudentData(ISD_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for deleting isc
     */
    @IsTest
    static void testForDeleteIscAsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();

        List<reduivy__Individual_Score__c> iscList = queryIsc();
        System.Assert.areNotEqual(0, iscList.size(), 'Individual Score should not be empty!');
        List<reduivy__Individual_Score_Detail__c> isdList = queryIsd();
        System.Assert.areNotEqual(0, isdList.size(), 'Individual Score Detail should not be empty!');

		System.runAs(ADMIN_USER){
            delete iscList;            
		}

        List<reduivy__Individual_Score__c> iscListAfterDelete = queryIsc();
        System.Assert.areEqual(0, iscListAfterDelete.size(), 'Individual Score should be deleted!');
        List<reduivy__Individual_Score_Detail__c> isdListAfterDelete = queryIsd();
        System.Assert.areEqual(0, isdListAfterDelete.size(), 'Individual Score Detail should be deleted!');


        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for deleting 100 isc
     */
    @IsTest
    static void testForDelete100IscAsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        Integer size = 100;
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        
        List<reduivy__Individual_Score__c> newIscList = new List<reduivy__Individual_Score__c>();
        reduivy__Study_Scoring_Config__c scf = queryScf();
        for(Integer i = 1; i <= 100; i++) {

            reduivy__Individual_Score__c newIsc = new reduivy__Individual_Score__c(
                reduivy__Study_Scoring_Config__c = scf.Id,
                reduivy__Contact__c = ipa.reduivy__Contact__c,
                reduivy__Status__c = ISC_Helper.STATUS_ACTIVE,
                reduivy__Individual_Program_Application__c = ipa.Id
            );
            
            newIscList.add(newIsc);
        }

        insert newIscList;

        List<reduivy__Individual_Score__c> iscList = queryIsc();
        System.Assert.areEqual(101, iscList.size(), 'Individual Score should not be empty!');
        List<reduivy__Individual_Score_Detail__c> isdList = queryIsd();
        System.Assert.areNotEqual(0, isdList.size(), 'Individual Score Detail should not be empty!');
        

		System.runAs(ADMIN_USER){
            delete iscList;            
		}

        List<reduivy__Individual_Score__c> iscListAfterDelete = queryIsc();
        System.Assert.areEqual(0, iscListAfterDelete.size(), 'Individual Score should be deleted!');
        List<reduivy__Individual_Score_Detail__c> isdListAfterDelete = queryIsd();
        System.Assert.areEqual(0, isdListAfterDelete.size(), 'Individual Score Detail should be deleted!');

        Test.stopTest();
		
    }

    
	
    /**
     * @description Test as faculty for deleting isc
     */
    @IsTest
    static void testForDeleteIscAsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();

        List<reduivy__Individual_Score__c> iscList = queryIsc();
        System.Assert.areNotEqual(0, iscList.size(), 'Individual Score should not be empty!');
        List<reduivy__Individual_Score_Detail__c> isdList = queryIsd();
        System.Assert.areNotEqual(0, isdList.size(), 'Individual Score Detail should not be empty!');

		System.runAs(FACULTY_USER){
            try{
                delete iscList;            
                System.Assert.fail('Should be failed because of faculty user!');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'), 'Should be failed with INSUFFICIENT_ACCESS_OR_READONLY! Actual: ' + exp.getMessage());
            }
		}

        List<reduivy__Individual_Score__c> iscListAfterDelete = queryIsc();
        System.Assert.areNotEqual(0, iscListAfterDelete.size(), 'Individual Score should not be deleted!');
        List<reduivy__Individual_Score_Detail__c> isdListAfterDelete = queryIsd();
        System.Assert.areNotEqual(0, isdListAfterDelete.size(), 'Individual Score Detail should not be deleted!');


        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for deleting isc
     */
    @IsTest
    static void testForDeleteIscAsStudent() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User studentUser = testFactory.getStudentUser();
        Test.startTest();

        List<reduivy__Individual_Score__c> iscList = queryIsc();
        System.Assert.areEqual(1, iscList.size(), 'Individual Score should not be empty!');
        List<reduivy__Individual_Score_Detail__c> isdList = queryIsd();
        System.Assert.areNotEqual(0, isdList.size(), 'Individual Score Detail should not be empty!');

        iscList[0].OwnerId = studentUser.Id;
        update iscList[0];

		System.runAs(studentUser){
            
            delete iscList;
		}

        List<reduivy__Individual_Score__c> iscListAfterDelete = queryIsc();
        System.Assert.areEqual(0, iscListAfterDelete.size(), 'Individual Score should be deleted!');
        List<reduivy__Individual_Score_Detail__c> isdListAfterDelete = queryIsd();
        System.Assert.areEqual(0, isdListAfterDelete.size(), 'Individual Score Detail should be deleted!');


        Test.stopTest();
		
    }

    static List<reduivy__Individual_Score__c> queryIsc() {
        return [
            SELECT Id
            FROM reduivy__Individual_Score__c
            WHERE reduivy__Study_Scoring_Config__r.reduivy__Sample_Record_Code__c = :SRC_SCF
            AND reduivy__Individual_Program_Application__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c = :SRC_CON
        ];
    }

    static List<reduivy__Individual_Score_Detail__c> queryIsd() {
        return [
            SELECT Id
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Study_Scoring_Config__r.reduivy__Sample_Record_Code__c = :SRC_SCF
            AND reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c = :SRC_CON
        ];
    }

    static reduivy__Study_Scoring_Config__c queryScf() {
        return [
            SELECT Id
            FROM reduivy__Study_Scoring_Config__c
            WHERE reduivy__Sample_Record_Code__c = :SRC_SCF
            LIMIT 1
        ];
    }
    
    static reduivy__Individual_Program_Application__c queryIpa() {
        return [
            SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Application__c WHERE reduivy__Sample_Record_Code__c = :SRC_CON
        ];
    }
	
}