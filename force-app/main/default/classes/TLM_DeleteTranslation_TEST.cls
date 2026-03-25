/**
 * @author      WDCi (XW)
 * @date        Mar 2025
 * @group       Test
 * @description Test class for TLM_DeleteTranslation_EXE
 * @changehistory
 * ISS-002340 19-03-2025 XW - new class
 */
@IsTest
public inherited sharing class TLM_DeleteTranslation_TEST {

    private static final Integer RECORD_SIZE = 10;
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

        Test.startTest();

        testFactory.initStudentData(USR_Helper.getApiName(), true);
        testFactory.initFacultyData(USR_Helper.getApiName(), true);

        List<reduivy__Translation__c> tlnList = new List<reduivy__Translation__c>();
        for(Integer i = 0; i < RECORD_SIZE; i++) {
            tlnList.add(new reduivy__Translation__c());
        }

        insert tlnList;

        List<reduivy__Translation_Map__c> tlmList = new List<reduivy__Translation_Map__c>();
        for(Integer i = 0; i < RECORD_SIZE; i++) {
            reduivy__Translation_Map__c tlm = new reduivy__Translation_Map__c();
            tlm.reduivy__Translation_1__c = tlnList[i].Id;
            tlmList.add(tlm);
        }

        insert tlmList;
        
        Test.stopTest();

    }
	
    /**
     * @description Test as admin for delete tlm
     */
    @IsTest
    static void testForDeleteTlmAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        List<reduivy__Translation_Map__c> tlmListBeforeDelete = new List<reduivy__Translation_Map__c>();
        for(reduivy__Translation_Map__c tlm : [SELECT Id, reduivy__Translation_1__c FROM reduivy__Translation_Map__c]){
            System.Assert.isNotNull(tlm.reduivy__Translation_1__c, 'Translation should be looked up from Translation Map!');
            tlmListBeforeDelete.add(tlm);
        }
        List<reduivy__Translation__c> tlnListBeforeDelete = [SELECT Id FROM reduivy__Translation__c];

        System.Assert.areEqual(RECORD_SIZE, tlmListBeforeDelete.size(), 'Wrong Translation Map size before deletion!');
        System.Assert.areEqual(RECORD_SIZE, tlnListBeforeDelete.size(), 'Wrong Translation size before deletion!');
        
		System.runAs(ADMIN_USER){
            delete tlmListBeforeDelete;
		}

        List<reduivy__Translation_Map__c> tlmListAfterDelete = [SELECT Id, reduivy__Translation_1__c FROM reduivy__Translation_Map__c WHERE Id IN :tlmListBeforeDelete];
        List<reduivy__Translation__c> tlnListAfterDelete = [SELECT Id FROM reduivy__Translation__c];

        System.Assert.areEqual(0, tlmListAfterDelete.size(), 'Translation Map should be deleted!');
        System.Assert.areEqual(0, tlnListAfterDelete.size(), 'Translation should be deleted!');
        

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for delete tlm
     */
	@IsTest
    static void testForDeleteTlmAsStudent() {

        //get the student record if you need one for testing using student.ContactId
		User studentUser = testFactory.getStudentUser();

        Test.startTest();

        List<reduivy__Translation_Map__c> tlmListBeforeDelete = new List<reduivy__Translation_Map__c>();
        for(reduivy__Translation_Map__c tlm : [SELECT Id, reduivy__Translation_1__c FROM reduivy__Translation_Map__c]){
            System.Assert.isNotNull(tlm.reduivy__Translation_1__c, 'Translation should be looked up from Translation Map!');
            tlmListBeforeDelete.add(tlm);
        }
        List<reduivy__Translation__c> tlnListBeforeDelete = [SELECT Id FROM reduivy__Translation__c];

        System.Assert.areEqual(RECORD_SIZE, tlmListBeforeDelete.size(), 'Wrong Translation Map size before deletion!');
        System.Assert.areEqual(RECORD_SIZE, tlnListBeforeDelete.size(), 'Wrong Translation size before deletion!');

        // TO DO: implement unit test run as student
		System.runAs(studentUser){
            try {
                delete tlmListBeforeDelete;
                System.Assert.fail('Translation Map should not be deleted!');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'), 'Wrong exception! Actual: ' + exp.getMessage());
            }
		}

        List<reduivy__Translation_Map__c> tlmListAfterDelete = [SELECT Id, reduivy__Translation_1__c FROM reduivy__Translation_Map__c WHERE Id IN :tlmListBeforeDelete];
        List<reduivy__Translation__c> tlnListAfterDelete = [SELECT Id FROM reduivy__Translation__c];

        System.Assert.areEqual(RECORD_SIZE, tlmListAfterDelete.size(), 'Translation Map should not be deleted!');
        System.Assert.areEqual(RECORD_SIZE, tlnListAfterDelete.size(), 'Translation should not be deleted!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for delete tlm
     */
	@IsTest
    static void testForDeleteTlmAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        

        Test.startTest();

        List<reduivy__Translation_Map__c> tlmListBeforeDelete = new List<reduivy__Translation_Map__c>();
        for(reduivy__Translation_Map__c tlm : [SELECT Id, reduivy__Translation_1__c FROM reduivy__Translation_Map__c]){
            System.Assert.isNotNull(tlm.reduivy__Translation_1__c, 'Translation should be looked up from Translation Map!');
            tlmListBeforeDelete.add(tlm);
        }
        List<reduivy__Translation__c> tlnListBeforeDelete = [SELECT Id FROM reduivy__Translation__c];

        System.Assert.areEqual(RECORD_SIZE, tlmListBeforeDelete.size(), 'Wrong Translation Map size before deletion!');
        System.Assert.areEqual(RECORD_SIZE, tlnListBeforeDelete.size(), 'Wrong Translation size before deletion!');

        // TO DO: implement unit test run as student
		System.runAs(FACULTY_USER){
            try {
                delete tlmListBeforeDelete;
                System.Assert.fail('Translation Map should not be deleted!');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'), 'Wrong exception! Actual: ' + exp.getMessage());
            }
		}

        List<reduivy__Translation_Map__c> tlmListAfterDelete = [SELECT Id, reduivy__Translation_1__c FROM reduivy__Translation_Map__c WHERE Id IN :tlmListBeforeDelete];
        List<reduivy__Translation__c> tlnListAfterDelete = [SELECT Id FROM reduivy__Translation__c];

        System.Assert.areEqual(RECORD_SIZE, tlmListAfterDelete.size(), 'Translation Map should not be deleted!');
        System.Assert.areEqual(RECORD_SIZE, tlnListAfterDelete.size(), 'Translation should not be deleted!');

        Test.stopTest();
		
    }
	
}