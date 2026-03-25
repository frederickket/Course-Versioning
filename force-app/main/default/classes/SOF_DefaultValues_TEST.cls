/**
 * @author      WDCi (XiRouh)
 * @date        March 2025
 * @group       Test
 * @description Test class for SOF_DefaultValues_EXE
 * @changehistory
 * ISS-002200 24-03-2025 XiRouh - new class
 */
@isTest
public inherited sharing class SOF_DefaultValues_TEST {
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
			testFactory.initOfferingData(STM_Helper.getApiName());
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

            List<reduivy__Study_Unit__c> sunId = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 1];
            List<Account> campusId = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1];
            List<reduivy__Study_Term__c> stmId = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

            List<reduivy__Study_Offering__c> sofToBeInserted = new List<reduivy__Study_Offering__c>();
            sofToBeInserted.add(
                new reduivy__Study_Offering__c(
                    Name = 'Test SOF 1',
                    reduivy__Study_Unit__c = sunId[0].Id,
                    reduivy__Campus__c = campusId[0].Id,
                    reduivy__Academic_Term__c = stmId[0].Id,
                    reduivy__Capacity__c = 20,
                    reduivy__Booked_Places__c = 20,
                    reduivy__Waitlist_Places__c = 20
            ));

            //we use direct insert here instead of REDU_Database_UTIL to bypass the fls as Booked_Places__c and Waitlist_Places__c are not editable
            insert sofToBeInserted;

            List<reduivy__Study_Offering__c> sofAfterInsert = [SELECT reduivy__Booked_Places__c, reduivy__Waitlist_Places__c FROM reduivy__Study_Offering__c WHERE Id = :sofToBeInserted[0].Id];
            System.Assert.areEqual(0, sofAfterInsert[0].reduivy__Booked_Places__c, 'Booked Places should be 0');
            System.Assert.areEqual(0, sofAfterInsert[0].reduivy__Waitlist_Places__c, 'Waitlist Places should be 0');

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

            List<reduivy__Study_Unit__c> sunId = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 1];
            List<Account> campusId = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1];
            List<reduivy__Study_Term__c> stmId = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

            List<reduivy__Study_Offering__c> sofToBeInserted = new List<reduivy__Study_Offering__c>();
            sofToBeInserted.add(
                new reduivy__Study_Offering__c(
                    Name = 'Test SOF 1',
                    reduivy__Study_Unit__c = sunId[0].Id,
                    reduivy__Campus__c = campusId[0].Id,
                    reduivy__Academic_Term__c = stmId[0].Id,
                    reduivy__Capacity__c = 20,
                    reduivy__Booked_Places__c = 20,
                    reduivy__Waitlist_Places__c = 20
            ));

            try {
                REDU_Database_UTIL.doInsert(sofToBeInserted);
                System.Assert.fail('This should fail with object permission.');
            } catch (Exception exp) {
                System.Assert.areEqual('DML operation INSERT not allowed on reduivy__Study_Offering__c', exp.getMessage(), 'Unexpected error: ' + exp.getMessage());
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

        List<reduivy__Study_Unit__c> sunId = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 1];
        List<Account> campusId = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1];
        List<reduivy__Study_Term__c> stmId = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

        System.runAs(reduStudent) {
            Test.startTest();

            List<reduivy__Study_Offering__c> sofToBeInserted = new List<reduivy__Study_Offering__c>();
            sofToBeInserted.add(
                new reduivy__Study_Offering__c(
                    Name = 'Test SOF 1',
                    reduivy__Study_Unit__c = sunId[0].Id,
                    reduivy__Campus__c = campusId[0].Id,
                    reduivy__Academic_Term__c = stmId[0].Id,
                    reduivy__Capacity__c = 20,
                    reduivy__Booked_Places__c = 20,
                    reduivy__Waitlist_Places__c = 20
            ));

            try {
                REDU_Database_UTIL.doInsert(sofToBeInserted);
                System.Assert.fail('This should fail with object permission.');
            } catch (Exception exp) {
                System.Assert.areEqual('DML operation INSERT not allowed on reduivy__Study_Offering__c', exp.getMessage(), 'Unexpected error: ' + exp.getMessage());
            }

            Test.stopTest();
        }
    }
}