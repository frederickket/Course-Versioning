/**
 * @author      WDCi (Jordan)
 * @date        Nov 2024
 * @group       Test
 * @description Test class for IEN_WithdrawalDate_EXE
 * @changehistory
 * ISS-002141 28-11-2024 Jordan - new class
 */
@IsTest
public inherited sharing class IEN_WithdrawalDate_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final List<String> IEN_OPEN_STATUSES = IEN_Helper.getOpenStatuses();
    static final List<String> IEN_IN_PROGRESS_STATUSES = IEN_Helper.getInProgressStatuses();
    static final List<String> IEN_WITHDRAWN_STATUSES = IEN_Helper.getWithdrawnStatuses();
    static final List<String> IEN_WITHDRAWN_FAIL_STATUSES = IEN_Helper.getWithdrawnFailStatuses();

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
            testFactory.initStudentData(IEN_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin to check the withdrawal date when updating individual enrollment's enrollment status to 'Withdrawn' status
     */
    @IsTest
    static void testUpdateIenToWithdrawnAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        //Get individual enrollments
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :IEN_WITHDRAWN_STATUSES
            AND reduivy__Withdrawal_Date__c = NULL
        ]);

        System.Assert.areEqual(false, ienMap.isEmpty(), 'Individual enrollment records not found.');
        System.Assert.isTrue(ienMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        System.runAs(ADMIN_USER) {
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_STATUSES[0];
            }

            REDU_Database_UTIL.doUpdate(ienMap.values());
        }

        //Verify result
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienMap.keySet()
        ]){
            System.Assert.isNotNull(ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today(), ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be today\'s date.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin to check the withdrawal date when updating individual enrollment's enrollment status to 'Withdrawn Fail' status
     */
    @IsTest
    static void testUpdateIenToWithdrawnFailAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        //Get individual enrollments
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :IEN_WITHDRAWN_FAIL_STATUSES
            AND reduivy__Withdrawal_Date__c = NULL
        ]);

        System.Assert.areEqual(false, ienMap.isEmpty(), 'individual enrollment records not found.');
        System.Assert.isTrue(ienMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        System.runAs(ADMIN_USER) {
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_FAIL_STATUSES[0];
            }

            REDU_Database_UTIL.doUpdate(ienMap.values());
        }

        //Verify result
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienMap.keySet()
        ]){
            System.Assert.isNotNull(ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today(), ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be today\'s date.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin to check the withdrawal date when updating individual enrollment's enrollment status to 'Withdrawn' status when withdrawal date is already set
     */
    @IsTest
    static void testUpdateIenToWithdrawnAsAdminWithdrawalDateSet() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        //Get individual enrollments
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :IEN_WITHDRAWN_STATUSES
        ]);

        System.Assert.areEqual(false, ienMap.isEmpty(), 'individual enrollment records not found.');
        System.Assert.isTrue(ienMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        System.runAs(ADMIN_USER) {
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_STATUSES[0];
                ien.reduivy__Withdrawal_Date__c = System.today() - 7;
            }

            REDU_Database_UTIL.doUpdate(ienMap.values());
        }

        //Verify result
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienMap.keySet()
        ]){
            System.Assert.isNotNull(ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today() - 7, ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should not be changed.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin to check the withdrawal date when updating individual enrollment's enrollment status to 'Withdrawn Fail' status when withdrawal date is already set
     */
    @IsTest
    static void testUpdateIenToWithdrawnFailAsAdminWithdrawalDateSet() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        //Get individual enrollments
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :IEN_WITHDRAWN_FAIL_STATUSES
        ]);

        System.Assert.areEqual(false, ienMap.isEmpty(), 'individual enrollment records not found.');
        System.Assert.isTrue(ienMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        System.runAs(ADMIN_USER) {
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_FAIL_STATUSES[0];
                ien.reduivy__Withdrawal_Date__c = System.today() - 7;
            }

            REDU_Database_UTIL.doUpdate(ienMap.values());
        }

        //Verify result
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienMap.keySet()
        ]){
            System.Assert.isNotNull(ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today() - 7, ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should not be changed.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin to check the withdrawal date when updating individual enrollment's enrollment status to 'In-Progress' status
     */
    @IsTest
    static void testUpdateIenToInProgressAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        //Get individual enrollments
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :IEN_IN_PROGRESS_STATUSES
            AND reduivy__Withdrawal_Date__c = NULL
        ]);

        System.Assert.areEqual(false, ienMap.isEmpty(), 'individual enrollment records not found.');
        System.Assert.isTrue(ienMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        //Set individual enrollments to 'Open' status
        for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
            ien.reduivy__Enrollment_Status__c = IEN_OPEN_STATUSES[0];
        }

        REDU_Database_UTIL.doUpdate(ienMap.values());

        System.runAs(ADMIN_USER) {
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_IN_PROGRESS_STATUSES[0];
            }

            REDU_Database_UTIL.doUpdate(ienMap.values());
        }

        //Verify result
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienMap.keySet()
        ]){
            System.Assert.isNull(ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should not be populated.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check the withdrawal date when updating individual enrollment's enrollment status to 'Withdrawn' status
     */
    @IsTest
    static void testUpdateIenToWithdrawnAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        //Get individual enrollments
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :IEN_WITHDRAWN_STATUSES
            AND reduivy__Withdrawal_Date__c = NULL
        ]);

        System.Assert.areEqual(false, ienMap.isEmpty(), 'individual enrollment records not found.');
        System.Assert.isTrue(ienMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        System.runAs(FACULTY_USER) {
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_STATUSES[0];
            }

            REDU_Database_UTIL.doUpdate(ienMap.values());
        }

        //Verify result
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienMap.keySet()
        ]){
            System.Assert.isNotNull(ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today(), ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be today\'s date.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check the withdrawal date when updating individual enrollment's enrollment status to 'Withdrawn Fail' status
     */
    @IsTest
    static void testUpdateIenToWithdrawnFailAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        //Get individual enrollments
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :IEN_WITHDRAWN_FAIL_STATUSES
            AND reduivy__Withdrawal_Date__c = NULL
        ]);

        System.Assert.areEqual(false, ienMap.isEmpty(), 'individual enrollment records not found.');
        System.Assert.isTrue(ienMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        System.runAs(FACULTY_USER) {
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_FAIL_STATUSES[0];
            }

            REDU_Database_UTIL.doUpdate(ienMap.values());
        }

        //Verify result
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienMap.keySet()
        ]){
            System.Assert.isNotNull(ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today(), ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be today\'s date.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check the withdrawal date when updating individual enrollment's enrollment status to 'Withdrawn' status when withdrawal date is already set
     */
    @IsTest
    static void testUpdateIenToWithdrawnAsFacultyWithdrawalDateSet() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        //Get individual enrollments
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :IEN_WITHDRAWN_STATUSES
        ]);

        System.Assert.areEqual(false, ienMap.isEmpty(), 'individual enrollment records not found.');
        System.Assert.isTrue(ienMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        System.runAs(FACULTY_USER) {
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_STATUSES[0];
                ien.reduivy__Withdrawal_Date__c = System.today() - 7;
            }

            REDU_Database_UTIL.doUpdate(ienMap.values());
        }

        //Verify result
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienMap.keySet()
        ]){
            System.Assert.isNotNull(ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today() - 7, ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should not be changed.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check the withdrawal date when updating individual enrollment's enrollment status to 'Withdrawn Fail' status when withdrawal date is already set
     */
    @IsTest
    static void testUpdateIenToWithdrawnFailAsFacultyWithdrawalDateSet() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        //Get individual enrollments
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :IEN_WITHDRAWN_FAIL_STATUSES
        ]);

        System.Assert.areEqual(false, ienMap.isEmpty(), 'individual enrollment records not found.');
        System.Assert.isTrue(ienMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        System.runAs(FACULTY_USER) {
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_FAIL_STATUSES[0];
                ien.reduivy__Withdrawal_Date__c = System.today() - 7;
            }

            REDU_Database_UTIL.doUpdate(ienMap.values());
        }

        //Verify result
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienMap.keySet()
        ]){
            System.Assert.isNotNull(ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today() - 7, ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should not be changed.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check the withdrawal date when updating individual enrollment's enrollment status to 'In-Progress' status
     */
    @IsTest
    static void testUpdateIenToInProgressAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        //Get individual enrollments
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :IEN_IN_PROGRESS_STATUSES
            AND reduivy__Withdrawal_Date__c = NULL
        ]);

        System.Assert.areEqual(false, ienMap.isEmpty(), 'individual enrollment records not found.');
        System.Assert.isTrue(ienMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        //Set individual enrollments to 'Open' status
        for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
            ien.reduivy__Enrollment_Status__c = IEN_OPEN_STATUSES[0];
        }

        REDU_Database_UTIL.doUpdate(ienMap.values());

        System.runAs(FACULTY_USER) {
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_IN_PROGRESS_STATUSES[0];
            }

            REDU_Database_UTIL.doUpdate(ienMap.values());
        }

        //Verify result
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienMap.keySet()
        ]){
            System.Assert.isNull(ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should not be populated.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student to check the waitlist date when updated individual enrollment's enrollment status to 'Withdrawn' status (BeforeUpdate)
     */
    @IsTest
    static void testUpdateIenToWithdrawnAsStudent() {

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

        //Get individual enrollments
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :IEN_WITHDRAWN_STATUSES
            AND reduivy__Withdrawal_Date__c = NULL
            AND reduivy__Contact__c = :studentContacts[0].Id
        ]);

        System.Assert.areEqual(false, ienMap.isEmpty(), 'individual enrollment records not found.');
        System.Assert.isTrue(ienMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        System.runAs(studentUser) {
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_STATUSES[0];
            }

            REDU_Database_UTIL.doUpdate(ienMap.values());
        }

        //Verify result
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienMap.keySet()
        ]){
            System.Assert.isNotNull(ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today(), ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be today\'s date.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student to check the waitlist date when updated individual enrollment's enrollment status to 'Withdrawn Fail' status (BeforeUpdate)
     */
    @IsTest
    static void testUpdateIenToWithdrawnFailAsStudent() {

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

        //Get individual enrollments
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :IEN_WITHDRAWN_FAIL_STATUSES
            AND reduivy__Withdrawal_Date__c = NULL
            AND reduivy__Contact__c = :studentContacts[0].Id
        ]);

        System.Assert.areEqual(false, ienMap.isEmpty(), 'individual enrollment records not found.');
        System.Assert.isTrue(ienMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        System.runAs(studentUser) {
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_FAIL_STATUSES[0];
            }

            REDU_Database_UTIL.doUpdate(ienMap.values());
        }

        //Verify result
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienMap.keySet()
        ]){
            System.Assert.isNotNull(ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today(), ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be today\'s date.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check the withdrawal date when updating individual enrollment's enrollment status to 'Withdrawn' status when withdrawal date is already set
     */
    @IsTest
    static void testUpdateIenToWithdrawnAsStudentWithdrawalDateSet() {

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

        //Get individual enrollments
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :IEN_WITHDRAWN_STATUSES
            AND reduivy__Contact__c = :studentContacts[0].Id
        ]);

        System.Assert.areEqual(false, ienMap.isEmpty(), 'individual enrollment records not found.');
        System.Assert.isTrue(ienMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        //Set withdrawal date
        for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
            ien.reduivy__Withdrawal_Date__c = System.today() - 7;
        }

        REDU_Database_UTIL.doUpdate(ienMap.values());

        System.runAs(studentUser) {
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_STATUSES[0];
            }

            REDU_Database_UTIL.doUpdate(ienMap.values());
        }

        //Verify result
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienMap.keySet()
        ]){
            System.Assert.isNotNull(ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today() - 7, ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should not be changed.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check the withdrawal date when updating individual enrollment's enrollment status to 'Withdrawn Fail' status when withdrawal date is already set
     */
    @IsTest
    static void testUpdateIenToWithdrawnFailAsStudentWithdrawalDateSet() {

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

        //Get individual enrollments
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :IEN_WITHDRAWN_FAIL_STATUSES
            AND reduivy__Contact__c = :studentContacts[0].Id
        ]);

        System.Assert.areEqual(false, ienMap.isEmpty(), 'individual enrollment records not found.');
        System.Assert.isTrue(ienMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        //Set withdrawal date
        for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
            ien.reduivy__Withdrawal_Date__c = System.today() - 7;
        }

        REDU_Database_UTIL.doUpdate(ienMap.values());

        System.runAs(studentUser) {
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_FAIL_STATUSES[0];
            }

            REDU_Database_UTIL.doUpdate(ienMap.values());
        }

        //Verify result
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienMap.keySet()
        ]){
            System.Assert.isNotNull(ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should be populated.');
            System.Assert.areEqual(System.today() - 7, ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should not be changed.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student to check the withdrawal date when updating individual enrollment's enrollment status to 'In-Progress' status
     */
    @IsTest
    static void testUpdateIenToInProgressAsStudent() {

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

        //Get individual enrollments
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :IEN_IN_PROGRESS_STATUSES
            AND reduivy__Withdrawal_Date__c = NULL
            AND reduivy__Contact__c = :studentContacts[0].Id
        ]);

        System.Assert.areEqual(false, ienMap.isEmpty(), 'individual enrollment records not found.');
        System.Assert.isTrue(ienMap.size() > 1, 'Should be more than one record for bulk testing purposes.');

        //Set individual enrollments to 'Open' status
        for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
            ien.reduivy__Enrollment_Status__c = IEN_OPEN_STATUSES[0];
        }

        REDU_Database_UTIL.doUpdate(ienMap.values());

        System.runAs(studentUser) {
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_IN_PROGRESS_STATUSES[0];
            }

            REDU_Database_UTIL.doUpdate(ienMap.values());
        }

        //Verify result
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Withdrawal_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienMap.keySet()
        ]){
            System.Assert.isNull(ien.reduivy__Withdrawal_Date__c, 'Withdrawal date should not be populated.');
        }

        Test.stopTest();
    }

}