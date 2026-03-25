/**
 * @author      WDCi (Jordan)
 * @date        Nov 2024
 * @group       Test
 * @description Test class for ISN_WithdrawalDate_EXE
 * @changehistory
 * ISS-002141 28-11-2024 Jordan - new class
 */
@IsTest
public inherited sharing class ISN_WithdrawalDate_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final List<String> ISN_OPEN_STATUSES = ISN_Helper.getOpenStatuses();
    static final List<String> ISN_IN_PROGRESS_STATUSES = ISN_Helper.getInProgressStatuses();
    static final List<String> ISN_WITHDRAWN_STATUSES = ISN_Helper.getWithdrawnStatuses();

    /**
     * @description Create settings and test data
     */
	@TestSetup
    static void makeData() {
		
		testFactory.setupDefaultSettings();
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {

            Test.startTest();

            testFactory.initMasterData(SPL_Helper.getApiName());
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initOfferingData(null);
            testFactory.initStudentData(ISN_Helper.getApiName(), true);

            //Create extra ISN for student
            reduivy__Individual_Enrollment__c ien = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Sample_Record_Code__c = 'sandydoe@redu.example_BUS102_CYT1_SYDNEY' LIMIT 1];
            reduivy__Study_Session__c studySession = [SELECT Id FROM reduivy__Study_Session__c WHERE reduivy__Sample_Record_Code__c = 'Lecture_BUS102_CYT1_SYDNEY' LIMIT 1];

            reduivy__Individual_Session_Enrollment__c newIsn = new reduivy__Individual_Session_Enrollment__c();
            newIsn.reduivy__Individual_Enrollment__c = ien.Id;
            newIsn.reduivy__Study_Session__c = studySession.Id; 
            newIsn.RecordTypeId = ISN_Helper.getStudentRecordTypeId();
            newIsn.reduivy__Enrollment_Status__c = 'Enrolled';
            insert newIsn;

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin to check the withdrawal date when updating individual session enrollment's enrollment status to 'Withdrawn' status
     */
    @IsTest
    static void testUpdateIsnToWithdrawnAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //Get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :ISN_WITHDRAWN_STATUSES
            AND reduivy__Withdrawal_Date__c = NULL
        ]);

        System.Assert.areEqual(false, isnMap.isEmpty(), 'Individual session enrollment records not found.');
        System.Assert.isTrue(isnMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        System.runAs(ADMIN_USER) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_WITHDRAWN_STATUSES[0];
            }
            
            REDU_Database_UTIL.doUpdate(isnMap.values());
        }

        //Verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today(), isn.reduivy__Withdrawal_Date__c, 'Withdrawal date should be today\'s date.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin to check the withdrawal date when updating individual session enrollment's enrollment status to 'In-Progress' status
     */
    @IsTest
    static void testUpdateIsnToInProgressAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //Get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :ISN_IN_PROGRESS_STATUSES
            AND reduivy__Withdrawal_Date__c = NULL
        ]);

        System.Assert.areEqual(false, isnMap.isEmpty(), 'Individual session enrollment records not found.');
        System.Assert.isTrue(isnMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        //Set individual session enrollments to 'Open' status
        for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
            isn.reduivy__Enrollment_Status__c = ISN_OPEN_STATUSES[0];
        }
        
        REDU_Database_UTIL.doUpdate(isnMap.values());

        System.runAs(ADMIN_USER) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_IN_PROGRESS_STATUSES[0];
            }
            
            REDU_Database_UTIL.doUpdate(isnMap.values());
        }

        //Verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNull(isn.reduivy__Withdrawal_Date__c, 'Withdrawal date should not be populated.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin to check the withdrawal date when updating individual session enrollment's enrollment status to 'Withdrawn' status when withdrawal date is already set
     */
    @IsTest
    static void testUpdateIsnToWithdrawnAsAdminWithdrawalDateSet() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //Get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :ISN_WITHDRAWN_STATUSES
        ]);

        System.Assert.areEqual(false, isnMap.isEmpty(), 'Individual session enrollment records not found.');
        System.Assert.isTrue(isnMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        System.runAs(ADMIN_USER) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_WITHDRAWN_STATUSES[0];
                isn.reduivy__Withdrawal_Date__c = System.today() - 7;
            }
            
            REDU_Database_UTIL.doUpdate(isnMap.values());
        }

        //Verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today() - 7, isn.reduivy__Withdrawal_Date__c, 'Withdrawal date should not be changed.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check the withdrawal date when updating individual session enrollment's enrollment status to 'Withdrawn' status
     */
    @IsTest
    static void testUpdateIsnToWithdrawnAsFaculty() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //Get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :ISN_WITHDRAWN_STATUSES
            AND reduivy__Withdrawal_Date__c = NULL
        ]);

        System.Assert.areEqual(false, isnMap.isEmpty(), 'Individual session enrollment records not found.');
        System.Assert.isTrue(isnMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        System.runAs(FACULTY_USER) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_WITHDRAWN_STATUSES[0];
            }
            
            REDU_Database_UTIL.doUpdate(isnMap.values());
        }

        //Verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today(), isn.reduivy__Withdrawal_Date__c, 'Withdrawal date should be today\'s date.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check the withdrawal date when updating individual session enrollment's enrollment status to 'In-Progress' status
     */
    @IsTest
    static void testUpdateIsnToInProgressAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //Get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :ISN_IN_PROGRESS_STATUSES
            AND reduivy__Withdrawal_Date__c = NULL
        ]);

        System.Assert.areEqual(false, isnMap.isEmpty(), 'Individual session enrollment records not found.');
        System.Assert.isTrue(isnMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        //Set individual session enrollments to 'Open' status
        for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
            isn.reduivy__Enrollment_Status__c = ISN_OPEN_STATUSES[0];
        }
        
        REDU_Database_UTIL.doUpdate(isnMap.values());

        System.runAs(FACULTY_USER) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_IN_PROGRESS_STATUSES[0];
            }
            
            REDU_Database_UTIL.doUpdate(isnMap.values());
        }

        //Verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNull(isn.reduivy__Withdrawal_Date__c, 'Withdrawal date should not be populated.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check the withdrawal date when updating individual session enrollment's enrollment status to 'Withdrawn' status when withdrawal date is already set
     */
    @IsTest
    static void testUpdateIsnToWithdrawnAsFacultyWithdrawalDateSet() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //Get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :ISN_WITHDRAWN_STATUSES
        ]);

        System.Assert.areEqual(false, isnMap.isEmpty(), 'Individual session enrollment records not found.');
        System.Assert.isTrue(isnMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        System.runAs(FACULTY_USER) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_WITHDRAWN_STATUSES[0];
                isn.reduivy__Withdrawal_Date__c = System.today() - 7;
            }
            
            REDU_Database_UTIL.doUpdate(isnMap.values());
        }

        //Verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today() - 7, isn.reduivy__Withdrawal_Date__c, 'Withdrawal date should not be changed.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student to check the waitlist date when updated individual session enrollment's enrollment status to 'Withdrawal' status (BeforeUpdate)
     */
    @IsTest
    static void testUpdateIsnToWithdrawnAsStudent() {
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        Contact student = studentContacts.get(0);

        User studentUser = [SELECT Id, ContactId, FirstName, LastName, Email
            FROM User 
            WHERE ContactId =: student.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            WITH SYSTEM_MODE
        ];

        Test.startTest();

        //Get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :ISN_WITHDRAWN_STATUSES
            AND reduivy__Withdrawal_Date__c = NULL
            AND reduivy__Individual_Enrollment__r.reduivy__Contact__c = :studentContacts[0].Id
        ]);

        System.Assert.areEqual(false, isnMap.isEmpty(), 'Individual session enrollment records not found.');
        System.Assert.isTrue(isnMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        System.runAs(studentUser) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_WITHDRAWN_STATUSES[0];
            }
            
            REDU_Database_UTIL.doUpdate(isnMap.values());
        }

        //Verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today(), isn.reduivy__Withdrawal_Date__c, 'Withdrawal date should be today\'s date.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student to check the withdrawal date when updating individual session enrollment's enrollment status to 'In-Progress' status
     */
    @IsTest
    static void testUpdateIsnToInProgressAsStudent() {
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        Contact student = studentContacts.get(0);

        User studentUser = [SELECT Id, ContactId, FirstName, LastName, Email
            FROM User 
            WHERE ContactId =: student.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            WITH SYSTEM_MODE
        ];

        Test.startTest();

        //Get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :ISN_IN_PROGRESS_STATUSES
            AND reduivy__Withdrawal_Date__c = NULL
            AND reduivy__Individual_Enrollment__r.reduivy__Contact__c = :studentContacts[0].Id
        ]);

        System.Assert.areEqual(false, isnMap.isEmpty(), 'Individual session enrollment records not found.');
        System.Assert.isTrue(isnMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        //Set individual session enrollments to 'Open' status
        for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
            isn.reduivy__Enrollment_Status__c = ISN_OPEN_STATUSES[0];
        }

        REDU_Database_UTIL.doUpdate(isnMap.values());

        System.runAs(studentUser) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_IN_PROGRESS_STATUSES[0];
            }
            
            REDU_Database_UTIL.doUpdate(isnMap.values());
        }

        //Verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNull(isn.reduivy__Withdrawal_Date__c, 'Withdrawal date should not be populated.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check the withdrawal date when updating individual session enrollment's enrollment status to 'Withdrawn' status when withdrawal date is already set
     */
    @IsTest
    static void testUpdateIsnToWithdrawnAsStudentWithdrawalDateSet() {
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        Contact student = studentContacts.get(0);

        User studentUser = [SELECT Id, ContactId, FirstName, LastName, Email
            FROM User 
            WHERE ContactId =: student.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            WITH SYSTEM_MODE
        ];

        Test.startTest();

        //Get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :ISN_WITHDRAWN_STATUSES
            AND reduivy__Withdrawal_Date__c = NULL
            AND reduivy__Individual_Enrollment__r.reduivy__Contact__c = :studentContacts[0].Id
        ]);

        System.Assert.areEqual(false, isnMap.isEmpty(), 'Individual session enrollment records not found.');
        System.Assert.isTrue(isnMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        System.runAs(studentUser) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_WITHDRAWN_STATUSES[0];
                isn.reduivy__Withdrawal_Date__c = System.today() - 7;
            }
            
            REDU_Database_UTIL.doUpdate(isnMap.values());
        }

        //Verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today() - 7, isn.reduivy__Withdrawal_Date__c, 'Withdrawal date should not be changed.');
        }

        Test.stopTest();
    }

}