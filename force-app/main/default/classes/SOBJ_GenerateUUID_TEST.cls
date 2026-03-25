/**
 * @author      WDCi (XiRouh)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for SOBJ_GenerateUUID_EXE
 * @changehistory
 * ISS-002046 31-07-2024 XiRouh - new class
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@IsTest
public inherited sharing class SOBJ_GenerateUUID_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();

            Contact testCon = new Contact(LastName = 'Doe', reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT);

            insert testCon;

            reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c(
                reduivy__Contact__c = testCon.Id,
                reduivy__Academic_Level__c = 'Masters',
                reduivy__Status__c = 'Active'
            );

            insert ipf;

            User guestUser = new User(
                Username = 'guestuser@example.com',
                LastName = 'Guest',
                Email = 'guestuser@example.com',
                Alias = 'guest',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = REDU_AppSetting_UTIL.getStudentProfileId(),
                LanguageLocaleKey = 'en_US',
                ContactId = testCon.Id
            );

            insert guestUser;

            REDU_SystemMode_UTIL.doInsert(REDU_TestData_UTIL.newPermissionSetAssignment(guestUser.Id, new Set<String>{'REDU_Guest'}));

            Test.stopTest();
		}
    }

    /**
     * @description Test to generate uuid before the record is insert (Admin)
     */
    @IsTest
    static void testForAdminInsertRecord() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact testCon = [SELECT Id FROM Contact];

        reduivy__Individual_Academic_Profile__c ipf = [SELECT Id FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :testCon.Id];

        reduivy__Individual_Enrollment__c testIEN = new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = testCon.Id, 
                reduivy__Enrollment_Status__c = 'Enrolled',
                reduivy__Individual_Academic_Profile__c = ipf.Id
        );

        Test.startTest();
        System.runAs(ADMIN_USER) {

            insert testIEN;

            Test.stopTest();
        }

        reduivy__Individual_Enrollment__c result = [SELECT Id, reduivy__UUID__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :testCon.Id];

        System.assertNotEquals(null, result.reduivy__UUID__c, 'reduivy__UUID__c should not be null');
    }

    /**
     * @description Test to generate uuid before the record is update (Admin)
     */
    @IsTest
    static void testForAdminUpdateRecord() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact testCon = [SELECT Id FROM Contact];

        reduivy__Individual_Academic_Profile__c ipf = [SELECT Id FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :testCon.Id];

        reduivy__Individual_Enrollment__c testIEN = new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = testCon.Id, 
                reduivy__Enrollment_Status__c = 'Enrolled',
                reduivy__Individual_Academic_Profile__c = ipf.Id
        );

        //Mute trigger to not generate uuid when create contact
        REDU_TriggerController.muteAllTriggers();
        insert testIEN;
        REDU_TriggerController.unmuteAllTriggers();

        System.assertEquals(null, testIEN.reduivy__UUID__c, 'reduivy__UUID__c should be null at this point');

        Test.startTest();
        System.runAs(ADMIN_USER) {

            testIEN.reduivy__Enrollment_Status__c = 'Completed';
            update testIEN;
            Test.stopTest();
        }

        reduivy__Individual_Enrollment__c result = [SELECT Id, reduivy__UUID__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :testCon.Id];

        System.assertNotEquals(null, result.reduivy__UUID__c, 'reduivy__UUID__c should not be null');
    }

    /**
     * @description Test to generate uuid before the record is insert (Faculty)
     */
    @IsTest
    static void testForFacultyInsertRecord() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact testCon = [SELECT Id FROM Contact];

        reduivy__Individual_Academic_Profile__c ipf = [SELECT Id FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :testCon.Id];

        reduivy__Individual_Enrollment__c testIEN = new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = testCon.Id, 
                reduivy__Enrollment_Status__c = 'Enrolled',
                reduivy__Individual_Academic_Profile__c = ipf.Id
        );

        Test.startTest();
        System.runAs(FACULTY_USER) {

            insert testIEN;

            Test.stopTest();
        }

        reduivy__Individual_Enrollment__c result = [SELECT Id, reduivy__UUID__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :testCon.Id];

        System.assertNotEquals(null, result.reduivy__UUID__c, 'reduivy__UUID__c should not be null');
    }

    /**
     * @description Test to generate uuid before the record is update (Faculty)
     */
    @IsTest
    static void testForFacultyUpdateRecord() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact testCon = [SELECT Id FROM Contact];

        reduivy__Individual_Academic_Profile__c ipf = [SELECT Id FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :testCon.Id];

        reduivy__Individual_Enrollment__c testIEN = new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = testCon.Id, 
                reduivy__Enrollment_Status__c = 'Enrolled',
                reduivy__Individual_Academic_Profile__c = ipf.Id
        );

        //Mute trigger to not generate uuid when create contact
        REDU_TriggerController.muteAllTriggers();
        insert testIEN;
        REDU_TriggerController.unmuteAllTriggers();

        System.assertEquals(null, testIEN.reduivy__UUID__c, 'reduivy__UUID__c should be null at this point');

        Test.startTest();
        System.runAs(FACULTY_USER) {

            testIEN.reduivy__Enrollment_Status__c = 'Completed';
            update testIEN;

            Test.stopTest();
        }

        reduivy__Individual_Enrollment__c result = [SELECT Id, reduivy__UUID__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :testCon.Id];

        System.assertNotEquals(null, result.reduivy__UUID__c, 'reduivy__UUID__c should not be null');
    }

    /**
     * @description Test to generate uuid before the record is insert (Student)
     */
    @IsTest
    static void testForStudentInsertRecord() {

        Contact testCon = [
            SELECT Id 
            FROM Contact 
            LIMIT 1
        ];

        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :testCon.Id LIMIT 1
        ];

        reduivy__Individual_Academic_Profile__c ipf = [SELECT Id FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :testCon.Id];
	
        reduivy__Individual_Enrollment__c testIEN = new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = testCon.Id, 
                reduivy__Enrollment_Status__c = 'Enrolled',
                reduivy__Individual_Academic_Profile__c = ipf.Id
        );

        Test.startTest();
        System.runAs(studentUser) {

            insert testIEN;

            Test.stopTest();
        }

        reduivy__Individual_Enrollment__c result = [SELECT Id, reduivy__UUID__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :testCon.Id];

        System.assertNotEquals(null, result.reduivy__UUID__c, 'reduivy__UUID__c should not be null');
    }

    /**
     * @description Test to generate uuid before the record is update (Student)
     */
    @IsTest
    static void testForStudentUpdateRecord() {

        Contact testCon = [
            SELECT Id 
            FROM Contact 
            LIMIT 1
        ];

        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :testCon.Id LIMIT 1
        ];

        reduivy__Individual_Academic_Profile__c ipf = [SELECT Id FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :testCon.Id];

        reduivy__Individual_Enrollment__c testIEN = new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = testCon.Id, 
                reduivy__Enrollment_Status__c = 'Enrolled',
                reduivy__Individual_Academic_Profile__c = ipf.Id
        );
	
        //Mute trigger to not generate uuid when create contact
        REDU_TriggerController.muteAllTriggers();
        insert testIEN;
        REDU_TriggerController.unmuteAllTriggers();

        System.assertEquals(null, testIEN.reduivy__UUID__c, 'reduivy__UUID__c should be null at this point');

        testIEN.reduivy__Enrollment_Status__c = 'Withdrawn';

        Test.startTest();
        System.runAs(studentUser) {

            update testIEN;
                      
            Test.stopTest();
        }

        reduivy__Individual_Enrollment__c result = [SELECT Id, reduivy__UUID__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :testCon.Id];

        System.assertNotEquals(null, result.reduivy__UUID__c, 'reduivy__UUID__c should not be null');
    }

    /**
     * @description Test to generate uuid before the record is insert (Guest)
     */
    @IsTest
    static void testForGuestInsertRecord() {

        Contact testCon = [
            SELECT Id 
            FROM Contact 
            LIMIT 1
        ];

        User guestUser = [
            SELECT Id, ContactId
            FROM User
            WHERE ContactId = :testCon.Id
            LIMIT 1
        ];

        reduivy__Individual_Academic_Profile__c ipf = [SELECT Id FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :testCon.Id];
	
        reduivy__Individual_Enrollment__c testIEN = new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = testCon.Id, 
                reduivy__Enrollment_Status__c = 'Enrolled',
                reduivy__Individual_Academic_Profile__c = ipf.Id
        );

        Test.startTest();
        System.runAs(guestUser) {

            insert testIEN;

            Test.stopTest();
        }

        reduivy__Individual_Enrollment__c result = [SELECT Id, reduivy__UUID__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :testCon.Id];

        System.assertNotEquals(null, result.reduivy__UUID__c, 'reduivy__UUID__c should not be null');
    }

    /**
     * @description Test to generate uuid before the record is update (Guest)
     */
    @IsTest
    static void testForGuestUpdateRecord() {

        Contact testCon = [
            SELECT Id 
            FROM Contact 
            LIMIT 1
        ];

        User guestUser = [
            SELECT Id, ContactId
            FROM User
            WHERE ContactId = :testCon.Id
            LIMIT 1
        ];

        reduivy__Individual_Academic_Profile__c ipf = [SELECT Id FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :testCon.Id];

        reduivy__Individual_Enrollment__c testIEN = new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = testCon.Id, 
                reduivy__Enrollment_Status__c = 'Enrolled',
                reduivy__Individual_Academic_Profile__c = ipf.Id
        );
	
        //Mute trigger to not generate uuid when create contact
        REDU_TriggerController.muteAllTriggers();
        insert testIEN;
        REDU_TriggerController.unmuteAllTriggers();

        System.assertEquals(null, testIEN.reduivy__UUID__c, 'reduivy__UUID__c should be null at this point');

        testIEN.reduivy__Enrollment_Status__c = 'Withdrawn';

        Test.startTest();
        System.runAs(guestUser) {

            update testIEN;
                      
            Test.stopTest();
        }

        reduivy__Individual_Enrollment__c result = [SELECT Id, reduivy__UUID__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :testCon.Id];

        System.assertNotEquals(null, result.reduivy__UUID__c, 'reduivy__UUID__c should not be null');
    }
}