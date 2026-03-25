/**
 * @author      WDCi (XW)
 * @date        Mar 2025
 * @group       Test
 * @description Test class for SOBJ_DeleteTranslationMap_EXE
 * @changehistory
 * ISS-002340 17-03-2025 XW - new class
 */
@IsTest
public inherited sharing class SOBJ_DeleteTranslationMap_TEST {

    private static final Integer RECORD_SIZE = 9;

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static final String SUN_PREFIX = 'BUS10';
    static final String SUN_WITHOUT_TLM_PREFIX = 'BUS20';

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
        	
            testFactory.initMasterData(ACC_Helper.getApiName());

            //Study Grade Setting
            testFactory.studyGradeSettings.put('PERCENTAGE_SCORE', REDU_TestData_UTIL.newStudyGradeSetting('PERCENTAGE_SCORE', testFactory.eduInst.Id, 'Percentage/Score', SGS_Helper.GRADING_SETTING_TYPE_PERCENTAGE_LETTER));
            testFactory.studyGradeSettings.put('PASS_FAIL', REDU_TestData_UTIL.newStudyGradeSetting('PASS_FAIL', testFactory.eduInst.Id, 'Pass/Fail', SGS_Helper.GRADING_SETTING_TYPE_PASSFAIL));
            REDU_SystemMode_UTIL.doInsert(testFactory.studyGradeSettings.values());

            //translation
            List<reduivy__Translation__c> tlnList = new List<reduivy__Translation__c>();
            for(Integer i = 0; i < RECORD_SIZE * 2; i++) {
                tlnList.add(new reduivy__Translation__c());
            }

            insert tlnList;

            //translation map
            List<reduivy__Translation_Map__c> tlmList = new List<reduivy__Translation_Map__c>();
            for(Integer i = 0; i < RECORD_SIZE * 2; i++) {
                reduivy__Translation_Map__c tlm = new reduivy__Translation_Map__c();
                tlm.reduivy__Translation_1__c = tlnList[i].Id;
                tlmList.add(tlm);
            }

            insert tlmList;

            //study unit
            List<reduivy__Study_Unit__c> studyUnitList = new List<reduivy__Study_Unit__c>();
            for(Integer i = 0; i < RECORD_SIZE * 2; i++) {
                reduivy__Study_Unit__c sun = null;
                if(Math.mod(i, 2) == 0) {
                    String sunName = SUN_PREFIX + String.valueOf(i + 1);
                    sun = REDU_TestData_UTIL.newStudyUnit(
                        sunName,
                        testFactory.eduInst.Id, 
                        testFactory.studyGradeSettings.get('PERCENTAGE_SCORE').Id, 
                        sunName, 
                        sunName, 
                        10, 
                        'Business, Management, and Marketing', 
                        '100', 
                        0.125, 
                        null
                    );
                    sun.reduivy__Translation_Map__c = tlmList[i].Id;
                } else {
                    String sunName = SUN_WITHOUT_TLM_PREFIX + String.valueOf(i + 1);
                    sun = REDU_TestData_UTIL.newStudyUnit(
                        sunName,
                        testFactory.eduInst.Id, 
                        testFactory.studyGradeSettings.get('PERCENTAGE_SCORE').Id, 
                        sunName, 
                        sunName, 
                        10, 
                        'Business, Management, and Marketing', 
                        '100', 
                        0.125, 
                        null
                    );
                }

                studyUnitList.add(sun);
            }

            insert studyUnitList;

            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(USR_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for delete study unit
     */
    @IsTest
    static void testForDeleteStudyUnitAsAdmin() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<reduivy__Study_Unit__c> sunListBeforeDelete = new List<reduivy__Study_Unit__c>();
        for(reduivy__Study_Unit__c sun : [SELECT Id, 
            reduivy__Translation_Map__c, 
            reduivy__Translation_Map__r.reduivy__Translation_1__c
            FROM reduivy__Study_Unit__c
            WHERE Name LIKE :(SUN_PREFIX + '%')]) {

            System.Assert.isNotNull(sun.reduivy__Translation_Map__c, 'Study unit Translation Map should not be empty!');
            System.Assert.isNotNull(sun.reduivy__Translation_Map__r.reduivy__Translation_1__c, 'Translation Record in Translation Map should not be empty!');
            sunListBeforeDelete.add(sun);
            
        }

        System.Assert.areEqual(RECORD_SIZE, sunListBeforeDelete.size(), 'Wrong record size!');
        
        Test.startTest();
        
		System.runAs(ADMIN_USER){
            delete sunListBeforeDelete;
		}

        List<reduivy__Study_Unit__c> sunListAfterDelete = [SELECT Id
            FROM reduivy__Study_Unit__c
            WHERE Id IN :sunListBeforeDelete
            AND Name LIKE :(SUN_PREFIX + '%')];

        List<reduivy__Translation_Map__c> tlmListAfterDelete = [SELECT Id FROM reduivy__Translation_Map__c];
        List<reduivy__Translation__c> tlnListAfterDelete = [SELECT Id FROM reduivy__Translation__c];

        System.Assert.areEqual(0, sunListAfterDelete.size(), 'Study Unit should be deleted!');
        System.Assert.areEqual(RECORD_SIZE, tlmListAfterDelete.size(), 'Translation Map should be deleted!');
        System.Assert.areEqual(RECORD_SIZE, tlnListAfterDelete.size(), 'Translation should be deleted!');
        
        Test.stopTest();
		
    }	

    /**
     * @description Test as admin for delete study unit without tlm linked
     */
    @IsTest
    static void testForDeleteStudyUnitWithoutTlmAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        List<reduivy__Study_Unit__c> sunListBeforeDelete = new List<reduivy__Study_Unit__c>();
        for(reduivy__Study_Unit__c sun : [SELECT Id, 
            reduivy__Translation_Map__c, 
            reduivy__Translation_Map__r.reduivy__Translation_1__c
            FROM reduivy__Study_Unit__c
            WHERE Name LIKE :(SUN_WITHOUT_TLM_PREFIX + '%')]) {

            System.Assert.isNull(sun.reduivy__Translation_Map__c, 'Study unit Translation Map should be empty!');
            sunListBeforeDelete.add(sun);
            
        }

        System.Assert.areEqual(RECORD_SIZE, sunListBeforeDelete.size(), 'Wrong record size!');
        
        Test.startTest();
        
		System.runAs(ADMIN_USER){
            delete sunListBeforeDelete;
		}

        List<reduivy__Study_Unit__c> sunListAfterDelete = [SELECT Id
            FROM reduivy__Study_Unit__c
            WHERE Id IN :sunListBeforeDelete 
            AND Name LIKE :(SUN_WITHOUT_TLM_PREFIX + '%')];

        List<reduivy__Translation_Map__c> tlmListAfterDelete = [SELECT Id FROM reduivy__Translation_Map__c];
        List<reduivy__Translation__c> tlnListAfterDelete = [SELECT Id FROM reduivy__Translation__c];

        System.Assert.areEqual(0, sunListAfterDelete.size(), 'Study Unit should be deleted!');
        System.Assert.areEqual(RECORD_SIZE * 2, tlmListAfterDelete.size(), 'Translation Map should not be deleted!');
        System.Assert.areEqual(RECORD_SIZE * 2, tlnListAfterDelete.size(), 'Translation should not be deleted!');
        
        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for delete study unit
     */
	@IsTest
    static void testForDeleteStudyUnitAsStudent() {

        //get the student record if you need one for testing using student.ContactId
		User studentUser = testFactory.getStudentUser();

        Test.startTest();

        List<reduivy__Study_Unit__c> sunListBeforeDelete = new List<reduivy__Study_Unit__c>();
        for(reduivy__Study_Unit__c sun : [SELECT Id, 
            reduivy__Translation_Map__c, 
            reduivy__Translation_Map__r.reduivy__Translation_1__c
            FROM reduivy__Study_Unit__c
            WHERE Name LIKE :(SUN_PREFIX + '%')]) {

            System.Assert.isNotNull(sun.reduivy__Translation_Map__c, 'Study unit Translation Map should not be empty!');
            System.Assert.isNotNull(sun.reduivy__Translation_Map__r.reduivy__Translation_1__c, 'Translation Record in Translation Map should not be empty!');
            sunListBeforeDelete.add(sun);
            
        }

        System.Assert.areEqual(RECORD_SIZE, sunListBeforeDelete.size(), 'Wrong record size!');
        
		System.runAs(studentUser){
            try {
                delete sunListBeforeDelete;
                System.Assert.fail('Study Unit should not be deleted!');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'), 'Wrong exception! Actual: ' + exp.getMessage());
            }
		}

        List<reduivy__Study_Unit__c> sunListAfterDelete = [SELECT Id
            FROM reduivy__Study_Unit__c
            WHERE Id IN :sunListBeforeDelete
            AND Name LIKE :(SUN_PREFIX + '%')];

        List<reduivy__Translation_Map__c> tlmListAfterDelete = [SELECT Id FROM reduivy__Translation_Map__c];
        List<reduivy__Translation__c> tlnListAfterDelete = [SELECT Id FROM reduivy__Translation__c];

        System.Assert.areEqual(RECORD_SIZE, sunListAfterDelete.size(), 'Study Unit should not be deleted!');
        System.Assert.areEqual(RECORD_SIZE * 2, tlmListAfterDelete.size(), 'Translation Map should not be deleted!');
        System.Assert.areEqual(RECORD_SIZE * 2, tlnListAfterDelete.size(), 'Translation should not be deleted!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for delete study unit
     */
	@IsTest
    static void testForDeleteStudyUnitWithoutTlmAsStudent() {

        //get the student record if you need one for testing using student.ContactId
		User studentUser = testFactory.getStudentUser();

        Test.startTest();

        List<reduivy__Study_Unit__c> sunListBeforeDelete = new List<reduivy__Study_Unit__c>();
        for(reduivy__Study_Unit__c sun : [SELECT Id, 
            reduivy__Translation_Map__c, 
            reduivy__Translation_Map__r.reduivy__Translation_1__c
            FROM reduivy__Study_Unit__c
            WHERE Name LIKE :(SUN_WITHOUT_TLM_PREFIX + '%')]) {

            System.Assert.isNull(sun.reduivy__Translation_Map__c, 'Study unit Translation Map should be empty!');
            sunListBeforeDelete.add(sun);
            
        }

        System.Assert.areEqual(RECORD_SIZE, sunListBeforeDelete.size(), 'Wrong record size!');
        
		System.runAs(studentUser){
            try {
                delete sunListBeforeDelete;
                System.Assert.fail('Study Unit should not be deleted!');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'), 'Wrong exception! Actual: ' + exp.getMessage());
            }
		}

        List<reduivy__Study_Unit__c> sunListAfterDelete = [SELECT Id
            FROM reduivy__Study_Unit__c
            WHERE Id IN :sunListBeforeDelete
            AND Name LIKE :(SUN_WITHOUT_TLM_PREFIX + '%')];

        List<reduivy__Translation_Map__c> tlmListAfterDelete = [SELECT Id FROM reduivy__Translation_Map__c];
        List<reduivy__Translation__c> tlnListAfterDelete = [SELECT Id FROM reduivy__Translation__c];

        System.Assert.areEqual(RECORD_SIZE, sunListAfterDelete.size(), 'Study Unit should not be deleted!');
        System.Assert.areEqual(RECORD_SIZE * 2, tlmListAfterDelete.size(), 'Translation Map should not be deleted!');
        System.Assert.areEqual(RECORD_SIZE * 2, tlnListAfterDelete.size(), 'Translation should not be deleted!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for delete study unit
     */
	@IsTest
    static void testForDeleteStudyUnitAsFaculty() {
		
        //get the faculty with allocation for testing, if you don't need the one with allocation, you can simplify the code to use testFactory.getReduFacultyUser()
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        List<reduivy__Study_Unit__c> sunListBeforeDelete = new List<reduivy__Study_Unit__c>();
        for(reduivy__Study_Unit__c sun : [SELECT Id, 
            reduivy__Translation_Map__c, 
            reduivy__Translation_Map__r.reduivy__Translation_1__c
            FROM reduivy__Study_Unit__c
            WHERE Name LIKE :(SUN_PREFIX + '%')]) {

            System.Assert.isNotNull(sun.reduivy__Translation_Map__c, 'Study unit Translation Map should not be empty!');
            System.Assert.isNotNull(sun.reduivy__Translation_Map__r.reduivy__Translation_1__c, 'Translation Record in Translation Map should not be empty!');
            sunListBeforeDelete.add(sun);
            
        }

        System.Assert.areEqual(RECORD_SIZE, sunListBeforeDelete.size(), 'Wrong record size!');
        
		System.runAs(FACULTY_USER){
            try {
                delete sunListBeforeDelete;
                System.Assert.fail('Study Unit should not be deleted!');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'), 'Wrong exception! Actual: ' + exp.getMessage());
            }
		}

        List<reduivy__Study_Unit__c> sunListAfterDelete = [SELECT Id
            FROM reduivy__Study_Unit__c
            WHERE Id IN :sunListBeforeDelete
            AND Name LIKE :(SUN_PREFIX + '%')];

        List<reduivy__Translation_Map__c> tlmListAfterDelete = [SELECT Id FROM reduivy__Translation_Map__c];
        List<reduivy__Translation__c> tlnListAfterDelete = [SELECT Id FROM reduivy__Translation__c];

        System.Assert.areEqual(RECORD_SIZE, sunListAfterDelete.size(), 'Study Unit should not be deleted!');
        System.Assert.areEqual(RECORD_SIZE * 2, tlmListAfterDelete.size(), 'Translation Map should not be deleted!');
        System.Assert.areEqual(RECORD_SIZE * 2, tlnListAfterDelete.size(), 'Translation should not be deleted!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for delete study unit
     */
	@IsTest
    static void testForDeleteStudyUnitWithoutTlmAsFaculty() {
		
        //get the faculty with allocation for testing, if you don't need the one with allocation, you can simplify the code to use testFactory.getReduFacultyUser()
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        List<reduivy__Study_Unit__c> sunListBeforeDelete = new List<reduivy__Study_Unit__c>();
        for(reduivy__Study_Unit__c sun : [SELECT Id, 
            reduivy__Translation_Map__c, 
            reduivy__Translation_Map__r.reduivy__Translation_1__c
            FROM reduivy__Study_Unit__c
            WHERE Name LIKE :(SUN_WITHOUT_TLM_PREFIX + '%')]) {

            System.Assert.isNull(sun.reduivy__Translation_Map__c, 'Study unit Translation Map should be empty!');
            sunListBeforeDelete.add(sun);
            
        }

        System.Assert.areEqual(RECORD_SIZE, sunListBeforeDelete.size(), 'Wrong record size!');
        
		System.runAs(FACULTY_USER){
            try {
                delete sunListBeforeDelete;
                System.Assert.fail('Study Unit should not be deleted!');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'), 'Wrong exception! Actual: ' + exp.getMessage());
            }
		}

        List<reduivy__Study_Unit__c> sunListAfterDelete = [SELECT Id
            FROM reduivy__Study_Unit__c
            WHERE Id IN :sunListBeforeDelete
            AND Name LIKE :(SUN_WITHOUT_TLM_PREFIX + '%')];

        List<reduivy__Translation_Map__c> tlmListAfterDelete = [SELECT Id FROM reduivy__Translation_Map__c];
        List<reduivy__Translation__c> tlnListAfterDelete = [SELECT Id FROM reduivy__Translation__c];

        System.Assert.areEqual(RECORD_SIZE, sunListAfterDelete.size(), 'Study Unit should not be deleted!');
        System.Assert.areEqual(RECORD_SIZE * 2, tlmListAfterDelete.size(), 'Translation Map should not be deleted!');
        System.Assert.areEqual(RECORD_SIZE * 2, tlnListAfterDelete.size(), 'Translation should not be deleted!');

        Test.stopTest();
		
    }
	
	
}