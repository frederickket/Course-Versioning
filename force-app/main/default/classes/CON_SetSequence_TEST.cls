/**
 * @author      WDCi (XiRouh)
 * @date        Feb 2025
 * @group       Term Student Enrollment
 * @description Test class for CON_SetSequence_EXE
 * @changehistory
 * ISS-002229 14-02-2025 XiRouh - new class
 */
@isTest
public inherited sharing class CON_SetSequence_TEST {
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
            testFactory.initMasterData(null);
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initStudentData(IAC_Helper.getApiName(), true);
        }
    }

    /**
     * @description Test beforeInsert() as admin
     */
    @IsTest
    static void testBeforeInsertAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
    
        Test.startTest();
        
        System.runAs(ADMIN_USER) {
            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
            );

            insert testContact;

            List<Contact> result = [SELECT Id, reduivy__Sequence__c FROM Contact WHERE Id = :testContact.Id];
            System.Assert.isNotNull(result[0].reduivy__Sequence__c, 'Sequence should be populated');
        }

        Test.stopTest();
    }

    /**
     * @description Test beforeInsert() as faculty
     */
    @IsTest
    static void testBeforeInsertAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();
    
        Test.startTest();
        
        System.runAs(FACULTY_USER) {
            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
            );

            insert testContact;

            List<Contact> result = [SELECT Id, reduivy__Sequence__c FROM Contact WHERE Id = :testContact.Id];
            System.Assert.isNotNull(result[0].reduivy__Sequence__c, 'Sequence should be populated');
        }

        Test.stopTest();
    }

    /**
     * @description Test beforeUpdate() as admin
     */
    @IsTest
    static void testBeforeUpdateAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
    
        Test.startTest();
        
        System.runAs(ADMIN_USER) {
            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
            );

            REDU_TriggerController.muteTriggers(new Set<String>{'CON_SetSequence_EXE'});

            insert testContact;

            List<Contact> assertSequenceField = [SELECT Id, reduivy__Sequence__c FROM Contact WHERE Id = :testContact.Id];
            System.Assert.isNull(assertSequenceField[0].reduivy__Sequence__c, 'Sequence should not be populated');

            REDU_TriggerController.unmuteTriggers(new Set<String>{'CON_SetSequence_EXE'});

            update testContact;

            List<Contact> result = [SELECT Id, reduivy__Sequence__c FROM Contact WHERE Id = :testContact.Id];
            System.Assert.isNotNull(result[0].reduivy__Sequence__c, 'Sequence should be populated');
        }

        Test.stopTest();
    }

    /**
     * @description Test beforeUpdate() as faculty
     */
    @IsTest
    static void testBeforeUpdateAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();
    
        Test.startTest();
        
        System.runAs(FACULTY_USER) {
            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
            );

            REDU_TriggerController.muteTriggers(new Set<String>{'CON_SetSequence_EXE'});

            insert testContact;

            List<Contact> assertSequenceField = [SELECT Id, reduivy__Sequence__c FROM Contact WHERE Id = :testContact.Id];
            System.Assert.isNull(assertSequenceField[0].reduivy__Sequence__c, 'Sequence should not be populated');

            REDU_TriggerController.unmuteTriggers(new Set<String>{'CON_SetSequence_EXE'});

            update testContact;

            List<Contact> result = [SELECT Id, reduivy__Sequence__c FROM Contact WHERE Id = :testContact.Id];
            System.Assert.isNotNull(result[0].reduivy__Sequence__c, 'Sequence should be populated');
        }

        Test.stopTest();
    }
}