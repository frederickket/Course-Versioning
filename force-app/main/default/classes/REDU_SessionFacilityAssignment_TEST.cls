/**
 * @author      WDCi (XW)
 * @date        July 2024
 * @group       Test
 * @description Test class for REDU_SessionFacilityAssignment_LCTRL
 * @changehistory
 * ISS-001920 18-07-2024 XW - create new class
 */
@IsTest
public inherited sharing class REDU_SessionFacilityAssignment_TEST {
    static String ACTION_UPDATE_UNALLOCATED = 'UPDATE_UNALLOCATED';
    static String ACTION_ADD_INTO_ALL = 'ADD_INTO_ALL';
    static String ACTION_REPLACE_ALL = 'REPLACE_ALL';
    static String INSUFFICIENT_ACCESS_OR_READONLY = 'INSUFFICIENT_ACCESS_OR_READONLY';

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

        	testFactory.initMasterData(SUN_Helper.getApiName());
            testFactory.initOfferingData(null);
            testFactory.initStudentData(USR_Helper.getApiName(), true);

            Test.stopTest();
		}
    }
	
    /**
     * @description Test as admin for updateAssignFacilityAddIntoAll
     */
    @IsTest
    static void testForAdminUpdateAssignFacilityAddIntoAll() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Event_Relation__c serFacility = [
            SELECT Id, Name,
            reduivy__Facility__c,
            reduivy__Study_Event__r.reduivy__Study_Session_Time__c,
            reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c =: SER_Helper.RELATION_TYPE_FACILITY
            LIMIT 1
        ];

        reduivy__Facility__c anotherFacility = [
            SELECT Id, Name
            FROM reduivy__Facility__c
            WHERE reduivy__Parent_Facility__c = null
            AND Id != :serFacility.reduivy__Facility__c
            LIMIT 1
        ];
        

        // TO DO: implement unit test run as admin
		System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_SessionFacilityAssignment_LCTRL.updateAssignFacility(
                new List<String> {serFacility.reduivy__Study_Event__r.reduivy__Study_Session_Time__c},
                ACTION_ADD_INTO_ALL, anotherFacility.Id);

            List<reduivy__Study_Event_Relation__c> newAddedSerList = [
                SELECT Id, Name
                FROM reduivy__Study_Event_Relation__c
                WHERE reduivy__Facility__c = :anotherFacility.Id
                AND reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = 
                :serFacility.reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            ];

            System.Assert.areNotEqual(0, newAddedSerList.size(), 'New added SER should not be empty');
            
            List<reduivy__Study_Event_Relation__c> originalSerList = [
                SELECT Id, Name
                FROM reduivy__Study_Event_Relation__c
                WHERE reduivy__Facility__c = :serFacility.reduivy__Facility__c
                AND reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = 
                :serFacility.reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            ];
            System.Assert.areNotEqual(0, originalSerList.size(), 'Original SER should not be empty');
                
            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as student for testForStudentUpdateAssignFacilityAddIntoAll
     */
	@IsTest
    static void testForStudentUpdateAssignFacilityAddIntoAll() {
        
		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
            LIMIT 1
        ];

            reduivy__Study_Event_Relation__c serFacility = [
                SELECT Id, Name,
                reduivy__Facility__c,
                reduivy__Study_Event__r.reduivy__Study_Session_Time__c,
                reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
                FROM reduivy__Study_Event_Relation__c
                WHERE reduivy__Relation_Type__c =: SER_Helper.RELATION_TYPE_FACILITY
                LIMIT 1
            ];
    
            reduivy__Facility__c anotherFacility = [
                SELECT Id, Name
                FROM reduivy__Facility__c
                WHERE reduivy__Parent_Facility__c = null
                AND Id != :serFacility.reduivy__Facility__c
                LIMIT 1
            ];
        // TO DO: implement unit test run as student
		System.runAs(studentUser){
            Test.startTest();
            REDU_SessionFacilityAssignment_LCTRL.updateAssignFacility(
                new List<String> {serFacility.reduivy__Study_Event__r.reduivy__Study_Session_Time__c},
                ACTION_ADD_INTO_ALL, anotherFacility.Id);

            List<reduivy__Study_Event_Relation__c> newAddedSerList = [
                SELECT Id, Name
                FROM reduivy__Study_Event_Relation__c
                WHERE reduivy__Facility__c = :anotherFacility.Id
                AND reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = 
                :serFacility.reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            ];

            System.Assert.areNotEqual(0, newAddedSerList.size(), 'New added SER should be created');

            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as faculty for xxx
     */
	@IsTest
    static void testForFacultyUpdateAssignFacilityAddIntoAll() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Study_Event_Relation__c serFacility = [
            SELECT Id, Name,
            reduivy__Facility__c,
            reduivy__Study_Event__r.reduivy__Study_Session_Time__c,
            reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c =: SER_Helper.RELATION_TYPE_FACILITY
            LIMIT 1
        ];

        reduivy__Facility__c anotherFacility = [
            SELECT Id, Name
            FROM reduivy__Facility__c
            WHERE reduivy__Parent_Facility__c = null
            AND Id != :serFacility.reduivy__Facility__c
            LIMIT 1
        ];
        
        // TO DO: implement unit test run as faculty
		System.runAs(FACULTY_USER){

            Test.startTest();
            REDU_SessionFacilityAssignment_LCTRL.updateAssignFacility(
                new List<String> {serFacility.reduivy__Study_Event__r.reduivy__Study_Session_Time__c},
                ACTION_ADD_INTO_ALL, anotherFacility.Id);

            List<reduivy__Study_Event_Relation__c> newAddedSerList = [
                SELECT Id, Name
                FROM reduivy__Study_Event_Relation__c
                WHERE reduivy__Facility__c = :anotherFacility.Id
                AND reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = 
                :serFacility.reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
                WITH USER_MODE
            ];

            System.Assert.areNotEqual(0, newAddedSerList.size(), 'New added SER should be created');

            Test.stopTest();
		}
		
    }


    /**
     * @description Test as admin for updateAssignFacilityReplaceAll
     */
    @IsTest
    static void testForAdminUpdateAssignFacilityReplaceAll() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Event_Relation__c serFacility = [
            SELECT Id, Name,
            reduivy__Facility__c,
            reduivy__Study_Event__r.reduivy__Study_Session_Time__c,
            reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c =: SER_Helper.RELATION_TYPE_FACILITY
            LIMIT 1
        ];

        reduivy__Facility__c anotherFacility = [
            SELECT Id, Name
            FROM reduivy__Facility__c
            WHERE reduivy__Parent_Facility__c = null
            AND Id != :serFacility.reduivy__Facility__c
            LIMIT 1
        ];
        

        // TO DO: implement unit test run as admin
		System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_SessionFacilityAssignment_LCTRL.updateAssignFacility(
                new List<String> {serFacility.reduivy__Study_Event__r.reduivy__Study_Session_Time__c},
                ACTION_REPLACE_ALL, anotherFacility.Id);

            List<reduivy__Study_Event_Relation__c> newAddedSerList = [
                SELECT Id, Name
                FROM reduivy__Study_Event_Relation__c
                WHERE reduivy__Facility__c = :anotherFacility.Id
                AND reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = 
                :serFacility.reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            ];

            System.Assert.areNotEqual(0, newAddedSerList.size(), 'New added SER should not be empty');
            
            List<reduivy__Study_Event_Relation__c> originalSerList = [
                SELECT Id, Name
                FROM reduivy__Study_Event_Relation__c
                WHERE reduivy__Facility__c = :serFacility.reduivy__Facility__c
                AND reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = 
                :serFacility.reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            ];
            System.Assert.areEqual(0, originalSerList.size(), 'Original SER should be deleted and empty');
                
            Test.stopTest();
		}
		
    }
	

    /**
     * @description Test as student for testForStudentUpdateAssignFacilityAddIntoAll
     */
	@IsTest
    static void testForStudentUpdateAssignFacilityReplaceAll() {
        
		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
            LIMIT 1
        ];

            reduivy__Study_Event_Relation__c serFacility = [
                SELECT Id, Name,
                reduivy__Facility__c,
                reduivy__Study_Event__r.reduivy__Study_Session_Time__c,
                reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
                FROM reduivy__Study_Event_Relation__c
                WHERE reduivy__Relation_Type__c =: SER_Helper.RELATION_TYPE_FACILITY
                LIMIT 1
            ];
    
            reduivy__Facility__c anotherFacility = [
                SELECT Id, Name
                FROM reduivy__Facility__c
                WHERE reduivy__Parent_Facility__c = null
                AND Id != :serFacility.reduivy__Facility__c
                LIMIT 1
            ];
        // TO DO: implement unit test run as student
		System.runAs(studentUser){
            Test.startTest();
            REDU_SessionFacilityAssignment_LCTRL.updateAssignFacility(
                new List<String> {serFacility.reduivy__Study_Event__r.reduivy__Study_Session_Time__c},
                ACTION_REPLACE_ALL, anotherFacility.Id);

            List<reduivy__Study_Event_Relation__c> newAddedSerList = [
                SELECT Id, Name
                FROM reduivy__Study_Event_Relation__c
                WHERE reduivy__Facility__c = :anotherFacility.Id
                AND reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = 
                :serFacility.reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
                WITH USER_MODE
            ];

            System.Assert.areNotEqual(0, newAddedSerList.size(), 'New added SER should be created');

            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as faculty for xxx
     */
	@IsTest
    static void testForFacultyUpdateAssignFacilityReplaceAll() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Study_Event_Relation__c serFacility = [
            SELECT Id, Name,
            reduivy__Facility__c,
            reduivy__Study_Event__r.reduivy__Study_Session_Time__c,
            reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c =: SER_Helper.RELATION_TYPE_FACILITY
            LIMIT 1
        ];

        reduivy__Facility__c anotherFacility = [
            SELECT Id, Name
            FROM reduivy__Facility__c
            WHERE reduivy__Parent_Facility__c = null
            AND Id != :serFacility.reduivy__Facility__c
            LIMIT 1
        ];
        
        // TO DO: implement unit test run as faculty
		System.runAs(FACULTY_USER){

            Test.startTest();
            try{
                REDU_SessionFacilityAssignment_LCTRL.updateAssignFacility(
                new List<String> {serFacility.reduivy__Study_Event__r.reduivy__Study_Session_Time__c},
                ACTION_REPLACE_ALL, anotherFacility.Id);

            }catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(INSUFFICIENT_ACCESS_OR_READONLY), 'Wrong exception: ' + exp.getMessage());
            }

            Test.stopTest();
		}
		
    }

    /**
     * @description Test as admin for updateAssignFacilityAddIntoAll
     */
    @IsTest
    static void testForAdminUpdateAssignFacilityUpdateUnallocated() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Event_Relation__c serFacility = [
            SELECT Id, Name,
            reduivy__Facility__c,
            reduivy__Study_Event__r.reduivy__Study_Session_Time__c,
            reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c =: SER_Helper.RELATION_TYPE_FACILITY
            LIMIT 1
        ];

        
        reduivy__Facility__c anotherFacility = [
            SELECT Id, Name
            FROM reduivy__Facility__c
            WHERE reduivy__Parent_Facility__c = null
            AND Id != :serFacility.reduivy__Facility__c
            LIMIT 1
            ];
            
            
        delete serFacility;
		System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_SessionFacilityAssignment_LCTRL.updateAssignFacility(
                new List<String> {serFacility.reduivy__Study_Event__r.reduivy__Study_Session_Time__c},
                ACTION_UPDATE_UNALLOCATED, anotherFacility.Id);

            List<reduivy__Study_Event_Relation__c> newAddedSerList = [
                SELECT Id, Name
                FROM reduivy__Study_Event_Relation__c
                WHERE reduivy__Facility__c = :anotherFacility.Id
                AND reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = 
                :serFacility.reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            ];

            System.Assert.areEqual(1, newAddedSerList.size(), 'New added SER should not be empty');
            
            List<reduivy__Study_Event_Relation__c> originalSerList = [
                SELECT Id, Name
                FROM reduivy__Study_Event_Relation__c
                WHERE reduivy__Facility__c = :serFacility.reduivy__Facility__c
                AND reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = 
                :serFacility.reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            ];
            System.Assert.areNotEqual(0, originalSerList.size(), 'Original SER should not be empty');
                
            Test.stopTest();
		}
		
    }

}