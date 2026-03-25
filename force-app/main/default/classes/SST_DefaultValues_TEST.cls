/**
 * @author      WDCi (Lean)
 * @date        Apr 2025
 * @group       Test
 * @description Test class for SST_DefaultValues_EXE
 * @changehistory
 * ISS-002403 24-03-2025 Lean - new class
 */
@isTest
public inherited sharing class SST_DefaultValues_TEST {
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData() {
        
        // Create settings
		testFactory.setupDefaultSettings();
        
		// Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(SUN_Helper.getApiName());
			testFactory.initOfferingData(SSE_Helper.getApiName());
			testFactory.initStudentData(USR_Helper.getApiName(), true);

            Test.stopTest();
        }
    }
   
    /**
    * @description Test as an admin user that when a study offering is created, the Booked Places and Waitlisted Places should be set as 0
    */
    @isTest
    static void testDefaultValuesAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();

            List<reduivy__Study_Session__c> sseList = [SELECT Id, Name FROM reduivy__Study_Session__c];
            List<reduivy__Study_Session_Time__c> sstToBeInserted = new List<reduivy__Study_Session_Time__c>();
            
            Integer counter = 0;
            for (reduivy__Study_Session__c sse : sseList) {
                reduivy__Study_Session_Time__c newSst = REDU_TestData_UTIL.newStudySessionTime(sse.Name + '_' + counter, sse.Id, null, sse.Name + '_' + counter, null, SST_Helper.DAY_OF_WEEK_MONDAY, SST_Helper.RECURRENCE_WEEKLY, null, null, Time.newInstance(9, 0, 0, 0), Time.newInstance(11, 0, 0, 0));
                newSst.reduivy__Update_Action__c = SST_Helper.UPDATE_ACTION_RECREATE;
                newSst.reduivy__Historical_Recurrence__c = null;

                sstToBeInserted.add(newSst);

                counter ++;
            }

            //we use direct insert here instead of REDU_Database_UTIL to bypass the fls as Booked_Places__c and Waitlist_Places__c are not editable
            insert sstToBeInserted;

            List<reduivy__Study_Session_Time__c> sstInsertedList = [SELECT reduivy__Update_Action__c, reduivy__Update_Settings__c, reduivy__Historical_Recurrence__c FROM reduivy__Study_Session_Time__c WHERE Id IN: sstToBeInserted];
            for (reduivy__Study_Session_Time__c sst : sstInsertedList) {
                System.Assert.areEqual(SST_Helper.UPDATE_ACTION_UPSERT, sst.reduivy__Update_Action__c, 'This should be ' + SST_Helper.UPDATE_ACTION_UPSERT);
                System.Assert.areEqual(true, String.isBlank(sst.reduivy__Historical_Recurrence__c), 'The value should be blank.');
            }

            Test.stopTest();
        }
    }

    /**
    * @description Test as an faculty user that when a study offering is created, the Booked Places and Waitlisted Places should be set as 0
    */
    @isTest
    static void testDefaultValuesAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER) {
            Test.startTest();

            List<reduivy__Study_Session__c> sseList = [SELECT Id, Name FROM reduivy__Study_Session__c];
            List<reduivy__Study_Session_Time__c> sstToBeInserted = new List<reduivy__Study_Session_Time__c>();
            
            Integer counter = 0;
            for (reduivy__Study_Session__c sse : sseList) {
                reduivy__Study_Session_Time__c newSst = REDU_TestData_UTIL.newStudySessionTime(sse.Name + '_' + counter, sse.Id, null, sse.Name + '_' + counter, null, SST_Helper.DAY_OF_WEEK_MONDAY, SST_Helper.RECURRENCE_WEEKLY, null, null, Time.newInstance(9, 0, 0, 0), Time.newInstance(11, 0, 0, 0));
                newSst.reduivy__Update_Action__c = SST_Helper.UPDATE_ACTION_RECREATE;
                newSst.reduivy__Historical_Recurrence__c = null;

                sstToBeInserted.add(newSst);

                counter ++;
            }

            try {
                REDU_Database_UTIL.doInsert(sstToBeInserted);
                System.Assert.fail('This should fail with object permission.');
            } catch (Exception exp) {
                System.Assert.areEqual('DML operation INSERT not allowed on reduivy__Study_Session_Time__c', exp.getMessage(), 'Unexpected error: ' + exp.getMessage());
            }

            Test.stopTest();
        }
    }

    /**
    * @description Test as an student user that when a study offering is created, the Booked Places and Waitlisted Places should be set as 0
    */
    @isTest
    static void testDefaultValuesAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        System.runAs(reduStudent) {
            Test.startTest();

            List<reduivy__Study_Session__c> sseList = [SELECT Id, Name FROM reduivy__Study_Session__c];
            List<reduivy__Study_Session_Time__c> sstToBeInserted = new List<reduivy__Study_Session_Time__c>();
            
            Integer counter = 0;
            for (reduivy__Study_Session__c sse : sseList) {
                reduivy__Study_Session_Time__c newSst = REDU_TestData_UTIL.newStudySessionTime(sse.Name + '_' + counter, sse.Id, null, sse.Name + '_' + counter, null, SST_Helper.DAY_OF_WEEK_MONDAY, SST_Helper.RECURRENCE_WEEKLY, null, null, Time.newInstance(9, 0, 0, 0), Time.newInstance(11, 0, 0, 0));
                newSst.reduivy__Update_Action__c = SST_Helper.UPDATE_ACTION_RECREATE;
                newSst.reduivy__Historical_Recurrence__c = null;

                sstToBeInserted.add(newSst);

                counter ++;
            }

            try {
                REDU_Database_UTIL.doInsert(sstToBeInserted);
                System.Assert.fail('This should fail with object permission.');
            } catch (Exception exp) {
                System.Assert.areEqual('DML operation INSERT not allowed on reduivy__Study_Session_Time__c', exp.getMessage(), 'Unexpected error: ' + exp.getMessage());
            }

            Test.stopTest();
        }
    }
}