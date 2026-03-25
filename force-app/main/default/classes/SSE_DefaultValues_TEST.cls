/**
 * @author      WDCi (Lean)
 * @date        Apr 2025
 * @group       Test
 * @description Test class for SSE_DefaultValues_EXE
 * @changehistory
 * ISS-002403 24-03-2025 Lean - new class
 */
@isTest
public inherited sharing class SSE_DefaultValues_TEST {
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
			testFactory.initOfferingData(SOF_Helper.getApiName());
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

            List<reduivy__Study_Offering__c> sofList = [SELECT Id, Name FROM reduivy__Study_Offering__c];
            
            System.Assert.isTrue(!sofList.isEmpty(), 'No study offering found for testing.');

            List<reduivy__Study_Session__c> sseToBeInserted = new List<reduivy__Study_Session__c>();
            List<reduivy__Study_Session_Time__c> sstToBeInserted = new List<reduivy__Study_Session_Time__c>();
            
            Integer counter = 0;
            for (reduivy__Study_Offering__c sof : sofList) {
                reduivy__Study_Session__c newSse = REDU_TestData_UTIL.newStudySession(sof.Name + '_' + counter, sof.Id, null, sof.Name + '_' + counter, 10, 10, 10, 'Tutorial', null, null);
                newSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;

                sseToBeInserted.add(newSse);

                counter ++;
            }

            //we use direct insert here instead of REDU_Database_UTIL to bypass the fls as Booked_Places__c and Waitlist_Places__c are not editable
            insert sseToBeInserted;

            List<reduivy__Study_Session__c> sseInsertedList = [SELECT reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Study_Event_Generation_Status__c FROM reduivy__Study_Session__c WHERE Id IN: sseToBeInserted];
            for (reduivy__Study_Session__c sse : sseInsertedList) {
                System.Assert.areEqual(0, sse.reduivy__Booked_Places__c, 'Booked Places should be 0');
                System.Assert.areEqual(0, sse.reduivy__Waitlist_Places__c, 'Waitlist Places should be 0');
                System.Assert.areEqual(SSE_Helper.STATUS_TYPE_DRAFT, sse.reduivy__Study_Event_Generation_Status__c, 'The value should be draft.');
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

            List<reduivy__Study_Offering__c> sofList = [SELECT Id, Name FROM reduivy__Study_Offering__c];

            System.Assert.isTrue(!sofList.isEmpty(), 'No study offering found for testing.');

            List<reduivy__Study_Session__c> sseToBeInserted = new List<reduivy__Study_Session__c>();
            List<reduivy__Study_Session_Time__c> sstToBeInserted = new List<reduivy__Study_Session_Time__c>();
            
            Integer counter = 0;
            for (reduivy__Study_Offering__c sof : sofList) {
                reduivy__Study_Session__c newSse = REDU_TestData_UTIL.newStudySession(sof.Name + '_' + counter, sof.Id, null, sof.Name + '_' + counter, 10, 10, 10, 'Tutorial', null, null);
                newSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;

                sseToBeInserted.add(newSse);

                counter ++;
            }

            try {
                REDU_Database_UTIL.doInsert(sseToBeInserted);
                System.Assert.fail('This should fail with object permission.');
            } catch (Exception exp) {
                System.Assert.areEqual('DML operation INSERT not allowed on reduivy__Study_Session__c', exp.getMessage(), 'Unexpected error: ' + exp.getMessage());
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

            List<reduivy__Study_Offering__c> sofList = [SELECT Id, Name FROM reduivy__Study_Offering__c];

            System.Assert.isTrue(!sofList.isEmpty(), 'No study offering found for testing.');

            List<reduivy__Study_Session__c> sseToBeInserted = new List<reduivy__Study_Session__c>();
            List<reduivy__Study_Session_Time__c> sstToBeInserted = new List<reduivy__Study_Session_Time__c>();
            
            Integer counter = 0;
            for (reduivy__Study_Offering__c sof : sofList) {
                reduivy__Study_Session__c newSse = REDU_TestData_UTIL.newStudySession(sof.Name + '_' + counter, sof.Id, null, sof.Name + '_' + counter, 10, 10, 10, 'Tutorial', null, null);
                newSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;

                sseToBeInserted.add(newSse);

                counter ++;
            }

            try {
                REDU_Database_UTIL.doInsert(sseToBeInserted);
                System.Assert.fail('This should fail with object permission.');
            } catch (Exception exp) {
                System.Assert.areEqual('DML operation INSERT not allowed on reduivy__Study_Session__c', exp.getMessage(), 'Unexpected error: ' + exp.getMessage());
            }

            Test.stopTest();
        }
    }
}