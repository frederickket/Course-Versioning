/**
 * @author      WDCi (XiRouh)
 * @date        July 2025
 * @group       
 * @description Test Class for IPA_ApplicationStatusChange_EXE
 * @changehistory
 * ISS-002487 22-07-2025 XiRouh - new class
 */
@IsTest
public with sharing class IPA_ApplicationStatusChange_TEST {
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String BIS_SPG_PROGRAM_CODE = 'BACBIS';

    static final String IPA_CREATE_IPE_STATUS = new List<String>(IPA_Helper.getCreateIpeStatusWithIpeEnrollmentStatus().keySet())[0];

    static final String IPA_DRAFT_STATUS = IPA_Helper.getDraftStatuses().get(0);

    static final String IPA_OFFER_DECLINED_STATUS = IPA_Helper.getOfferDeclinedStatuses().get(0);

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

            testFactory.initMasterData(SPU_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);

            Test.stopTest();
		}
    }

    /**
     * @description Test Change Status From Create Ipe To Non Create Ipe When Ipe Exists As Admin
     */
    @IsTest
    static void testChangeStatusFromCreateIpeToNonCreateIpeWhenIpeExistsAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_CREATE_IPE_STATUS,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        insert ipaToBeCreated;

        ipaToBeCreated[0].reduivy__Application_Status__c = IPA_DRAFT_STATUS;

        System.runAs(ADMIN_USER) {
            Test.startTest();
        
            try {
                update ipaToBeCreated;
                System.Assert.fail('Expected Fail with StatusChangeDisallowed error.');
            } catch (Exception e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.IPA_ApplicationStatusChange_EXE_StatusChangeDisallowed, new List<String>{IPE_Helper.getObjectPluralLabel(), IPA_Helper.getObjectLabel()});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error:' + e.getMessage());
            } 
            
            Test.stopTest();
        }
    }

    /**
     * @description Test Change Status From Create Ipe To Non Create Ipe When No Ipe Exists As Admin
     */
    @IsTest
    static void testChangeStatusFromCreateIpeToNonCreateIpeWhenNoIpeExistsAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_CREATE_IPE_STATUS,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        insert ipaToBeCreated;

        List<reduivy__Individual_Program_Enrollment__c> createdIpe = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Individual_Program_Application__c = :ipaToBeCreated[0].Id];
        delete createdIpe;

        ipaToBeCreated[0].reduivy__Application_Status__c = IPA_DRAFT_STATUS;

        System.runAs(ADMIN_USER) {
            Test.startTest();
        
            update ipaToBeCreated;
            
            Test.stopTest();
        }

        List<reduivy__Individual_Program_Application__c> ipaUpdated = [
            SELECT Id, reduivy__Application_Status__c 
            FROM reduivy__Individual_Program_Application__c 
            WHERE Id = :ipaToBeCreated[0].Id
        ];

        System.Assert.isTrue(!ipaUpdated.isEmpty(), 'IPA should exist');
        System.Assert.areEqual(IPA_DRAFT_STATUS, ipaUpdated[0].reduivy__Application_Status__c, 'IPA status should be set to Draft');
    }

    /**
     * @description Test Change Status From Non Create Ipe to Non Create IPE status As Admin
     */
    @IsTest
    static void testChangeStatusFromNonCreateIpeToNonCreateIpeStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_DRAFT_STATUS,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        insert ipaToBeCreated;

        ipaToBeCreated[0].reduivy__Application_Status__c = IPA_OFFER_DECLINED_STATUS;

        System.runAs(ADMIN_USER) {
            Test.startTest();
        
            update ipaToBeCreated;
            
            Test.stopTest();
        }

        List<reduivy__Individual_Program_Application__c> ipaUpdated = [
            SELECT Id, reduivy__Application_Status__c 
            FROM reduivy__Individual_Program_Application__c 
            WHERE Id = :ipaToBeCreated[0].Id
        ];

        System.Assert.isTrue(!ipaUpdated.isEmpty(), 'IPA should exist');
        System.Assert.areEqual(IPA_OFFER_DECLINED_STATUS, ipaUpdated[0].reduivy__Application_Status__c, 'IPA status should be set to Offer Declined Status');
    }

    /**
     * @description Test Change Status From Create Ipe To Non Create Ipe When Ipe Exists As Faculty
     */
    @IsTest
    static void testChangeStatusFromCreateIpeToNonCreateIpeWhenIpeExistsAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_CREATE_IPE_STATUS,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        insert ipaToBeCreated;

        ipaToBeCreated[0].reduivy__Application_Status__c = IPA_DRAFT_STATUS;

        System.runAs(FACULTY_USER) {
            Test.startTest();
        
            try {
                update ipaToBeCreated;
                System.Assert.fail('Expected Fail with StatusChangeDisallowed error.');
            } catch (Exception e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.IPA_ApplicationStatusChange_EXE_StatusChangeDisallowed, new List<String>{IPE_Helper.getObjectPluralLabel(), IPA_Helper.getObjectLabel()});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error:' + e.getMessage());
            } 
            
            Test.stopTest();
        }
    }

    /**
     * @description Test Change Status From Create Ipe To Non Create Ipe When No Ipe Exists As Faculty
     */
    @IsTest
    static void testChangeStatusFromCreateIpeToNonCreateIpeWhenNoIpeExistsAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_CREATE_IPE_STATUS,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        insert ipaToBeCreated;

        List<reduivy__Individual_Program_Enrollment__c> createdIpe = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Individual_Program_Application__c = :ipaToBeCreated[0].Id];
        delete createdIpe;

        ipaToBeCreated[0].reduivy__Application_Status__c = IPA_DRAFT_STATUS;

        System.runAs(FACULTY_USER) {
            Test.startTest();
        
            update ipaToBeCreated;
            
            Test.stopTest();
        }

        List<reduivy__Individual_Program_Application__c> ipaUpdated = [
            SELECT Id, reduivy__Application_Status__c 
            FROM reduivy__Individual_Program_Application__c 
            WHERE Id = :ipaToBeCreated[0].Id
        ];

        System.Assert.isTrue(!ipaUpdated.isEmpty(), 'IPA should exist');
        System.Assert.areEqual(IPA_DRAFT_STATUS, ipaUpdated[0].reduivy__Application_Status__c, 'IPA status should be set to Draft');
    }

    /**
     * @description Test Change Status From Non Create Ipe to Non Create IPE status As Faculty
     */
    @IsTest
    static void testChangeStatusFromNonCreateIpeToNonCreateIpeStatusAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_DRAFT_STATUS,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        insert ipaToBeCreated;

        ipaToBeCreated[0].reduivy__Application_Status__c = IPA_OFFER_DECLINED_STATUS;

        System.runAs(FACULTY_USER) {
            Test.startTest();
        
            update ipaToBeCreated;
            
            Test.stopTest();
        }

        List<reduivy__Individual_Program_Application__c> ipaUpdated = [
            SELECT Id, reduivy__Application_Status__c 
            FROM reduivy__Individual_Program_Application__c 
            WHERE Id = :ipaToBeCreated[0].Id
        ];

        System.Assert.isTrue(!ipaUpdated.isEmpty(), 'IPA should exist');
        System.Assert.areEqual(IPA_OFFER_DECLINED_STATUS, ipaUpdated[0].reduivy__Application_Status__c, 'IPA status should be set to Offer Declined Status');
    }

    /**
     * @description Test Change Status From Create Ipe To Non Create Ipe When Ipe Exists As Student
     */
    @IsTest
    static void testChangeStatusFromCreateIpeToNonCreateIpeWhenIpeExistsAsStudent() {

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContacts[0].Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_CREATE_IPE_STATUS,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        insert ipaToBeCreated;

        ipaToBeCreated[0].reduivy__Application_Status__c = IPA_DRAFT_STATUS;

        System.runAs(studentUser) {
            Test.startTest();
        
            try {
                update ipaToBeCreated;
                System.Assert.fail('Expected Fail with StatusChangeDisallowed error.');
            } catch (Exception e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.IPA_ApplicationStatusChange_EXE_StatusChangeDisallowed, new List<String>{IPE_Helper.getObjectPluralLabel(), IPA_Helper.getObjectLabel()});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error:' + e.getMessage());
            } 
            
            Test.stopTest();
        }
    }

    /**
     * @description Test Change Status From Create Ipe To Non Create Ipe When No Ipe Exists As Student
     */
    @IsTest
    static void testChangeStatusFromCreateIpeToNonCreateIpeWhenNoIpeExistsAsStudent() {

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContacts[0].Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_CREATE_IPE_STATUS,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        insert ipaToBeCreated;

        List<reduivy__Individual_Program_Enrollment__c> createdIpe = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Individual_Program_Application__c = :ipaToBeCreated[0].Id];
        delete createdIpe;

        ipaToBeCreated[0].reduivy__Application_Status__c = IPA_DRAFT_STATUS;

        System.runAs(studentUser) {
            Test.startTest();
        
            update ipaToBeCreated;
            
            Test.stopTest();
        }

        List<reduivy__Individual_Program_Application__c> ipaUpdated = [
            SELECT Id, reduivy__Application_Status__c 
            FROM reduivy__Individual_Program_Application__c 
            WHERE Id = :ipaToBeCreated[0].Id
        ];

        System.Assert.isTrue(!ipaUpdated.isEmpty(), 'IPA should exist');
        System.Assert.areEqual(IPA_DRAFT_STATUS, ipaUpdated[0].reduivy__Application_Status__c, 'IPA status should be set to Draft');
    }

    /**
     * @description Test Change Status From Non Create Ipe to Non Create IPE status As Student
     */
    @IsTest
    static void testChangeStatusFromNonCreateIpeToNonCreateIpeStatusAsStudent() {

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContacts[0].Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_DRAFT_STATUS,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        insert ipaToBeCreated;

        ipaToBeCreated[0].reduivy__Application_Status__c = IPA_OFFER_DECLINED_STATUS;

        System.runAs(studentUser) {
            Test.startTest();
        
            update ipaToBeCreated;
            
            Test.stopTest();
        }

        List<reduivy__Individual_Program_Application__c> ipaUpdated = [
            SELECT Id, reduivy__Application_Status__c 
            FROM reduivy__Individual_Program_Application__c 
            WHERE Id = :ipaToBeCreated[0].Id
        ];

        System.Assert.isTrue(!ipaUpdated.isEmpty(), 'IPA should exist');
        System.Assert.areEqual(IPA_OFFER_DECLINED_STATUS, ipaUpdated[0].reduivy__Application_Status__c, 'IPA status should be set to Offer Declined Status');
    }
}