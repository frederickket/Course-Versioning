/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_Permission_UTIL
 * @changehistory
 * 
 */
@isTest
public inherited sharing class REDU_Permission_TEST {

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
            
            testFactory.initStudentData(USR_Helper.getApiName(), true);

            Test.stopTest();
        }
    }
	
	@IsTest
    static void testAdminPermission(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        System.runAs(ADMIN_USER){
            System.Assert.areEqual(true, REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN));
            System.Assert.areEqual(false, REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY));
            System.Assert.areEqual(false, REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.STUDENT));
            System.Assert.areEqual(true, REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER));
            System.Assert.areEqual(false, REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.GUEST));
        }
        Test.stopTest();
        
    }

    @IsTest
    static void testFacultyPermission(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        System.runAs(FACULTY_USER){
            System.Assert.areEqual(false, REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN));
            System.Assert.areEqual(true, REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY));
            System.Assert.areEqual(false, REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.STUDENT));
            System.Assert.areEqual(true, REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER));
            System.Assert.areEqual(false, REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.GUEST));
        }
        Test.stopTest();
        
    }

    @IsTest
    static void testStudentPermission(){
        
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
            AND IsActive = true
        ];

        Test.startTest();
        System.runAs(reduStudent) {
            System.Assert.areEqual(false, REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN));
            System.Assert.areEqual(false, REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY));
            System.Assert.areEqual(true, REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.STUDENT));
            System.Assert.areEqual(true, REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER));
            System.Assert.areEqual(false, REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.GUEST));
        }
        Test.stopTest();
        
    }
}