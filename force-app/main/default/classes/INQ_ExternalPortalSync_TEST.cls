/**
 * @author      WDCi (Xirouh)
 * @date        June 2024
 * @group       Test
 * @description Test class for INQ_ExternalPortalSync_EXE
 * @changehistory
 * ISS-001978 24-06-2024 Xirouh - new class
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@IsTest
public inherited sharing class INQ_ExternalPortalSync_TEST {

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

            reduivy__RIO_Education_Ivy_Settings__c cs = [SELECT Id, reduivy__Enable_External_Portal_Sync__c FROM reduivy__RIO_Education_Ivy_Settings__c LIMIT 1];
            cs.reduivy__Enable_External_Portal_Sync__c = true;
            update cs;
            
            testFactory.muteTriggers();

            Account testAcc = REDU_TestData_UTIL.newAdministrativeAccount('test', 'test');
            insert testAcc;

            Contact testCon = REDU_TestData_UTIL.newStudentContact('test', testAcc.Id, 'Test', 'Test', 'test@example.com', null);
            insert testCon;

            reduivy__Individual_Academic_Profile__c ipf = REDU_TestData_UTIL.newIndividualAcademicProfile(
                testCon.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                testCon.Id,
                testCon.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            );

            insert ipf;

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment('test', testCon.Id, null, null, null, null, null, null, null, null, null, ipf.Id, true);
            insert ien;

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

            testFactory.unmuteTriggers();

            Test.stopTest();
		}
    }

    /**
     * @description Test INQ_ExternalPortalSync_EXE executeAfterInsert (Run as admin)
     */
    @IsTest
    static void testForExecuteAfterInsertAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Individual_Enrollment__c ien = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c =: testCon.Id];

        List<Map<String, Object>> responseList = new List<Map<String, Object>>();
        Map<String, Object> responseItem = new Map<String, Object>();
        HttpResponse mockResponse = new HttpResponse();

        reduivy__Integration_Queue__c testINQ = new reduivy__Integration_Queue__c(
                reduivy__Action_Type__c = 'Insert',
                reduivy__Object_Type__c = 'reduivy__Individual_Enrollment__c',
                reduivy__Status__c = INQ_Helper.STATUS_TYPE_READY_TO_SYNC,
                reduivy__Target_System__c = INQ_Helper.TARGET_SYSTEM_TYPE_EXT_PORTAL,
                reduivy__Object_Id__c = ien.Id
        );

        Test.startTest();
        System.runAs(ADMIN_USER) {

            insert testINQ;

            responseItem.put('id', ien.Id);
            responseItem.put('success', true);
            responseList.add(responseItem);
            String responseMsg = JSON.serialize(responseList);

            mockResponse.setStatusCode(200);
            mockResponse.setBody(responseMsg);
            Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));
            
            Test.stopTest();
        }

        reduivy__Integration_Queue__c result = [
                SELECT Id, reduivy__Action_Type__c, reduivy__Response_Message__c, reduivy__Status__c
                FROM reduivy__Integration_Queue__c 
                WHERE Id = :testINQ.Id
                LIMIT 1
        ];

        System.Assert.areEqual(INQ_Helper.STATUS_TYPE_SYNC_SUCCEEDED, result.reduivy__Status__c, 'Status should be sync succeeded'); 
        System.Assert.isTrue(mockResponse.getBody().contains(result.reduivy__Response_Message__c), 'Response message not match: ' + mockResponse.getBody());
    }

    /**
     * @description Test INQ_ExternalPortalSync_EXE executeAfterInsert (Run as guest)
     */
    @IsTest
    static void testForExecuteAfterInsertAsGuest() {
	
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Individual_Enrollment__c ien = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c =: testCon.Id];

        List<Map<String, Object>> responseList = new List<Map<String, Object>>();
        Map<String, Object> responseItem = new Map<String, Object>();
        HttpResponse mockResponse = new HttpResponse();

        User guestUser = [
            SELECT Id, ContactId
            FROM User
            WHERE ContactId = :testCon.Id
            LIMIT 1
        ];

        reduivy__Integration_Queue__c testINQ = new reduivy__Integration_Queue__c(
                reduivy__Action_Type__c = 'Insert',
                reduivy__Object_Type__c = 'reduivy__Individual_Enrollment__c',
                reduivy__Status__c = INQ_Helper.STATUS_TYPE_READY_TO_SYNC,
                reduivy__Target_System__c = INQ_Helper.TARGET_SYSTEM_TYPE_EXT_PORTAL,
                reduivy__Object_Id__c = ien.Id
        );

        try {
            Test.startTest();
            System.runAs(guestUser) {

                insert testINQ;

                responseItem.put('id', ien.Id);
                responseItem.put('success', true);
                responseList.add(responseItem);
                String responseMsg = JSON.serialize(responseList);

                mockResponse.setStatusCode(200);
                mockResponse.setBody(responseMsg);
                Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));
            }
            Test.stopTest();
        
            System.Assert.fail('This should fail with object permission error.');
        } catch (Exception exp) {
            //guest is allowed to create records, however it is not allowed to update record
            System.Assert.isTrue(exp.getMessage().contains('Insufficient UPDATABLE access on following object(s) and field(s) - reduivy__Integration_Queue__c'), 'Unexpected error: ' + exp.getMessage());
        }

        reduivy__Integration_Queue__c result = [
                SELECT Id, reduivy__Action_Type__c, reduivy__Response_Message__c, reduivy__Status__c
                FROM reduivy__Integration_Queue__c 
                WHERE Id = :testINQ.Id
                LIMIT 1
        ];

        System.Assert.areEqual(INQ_Helper.STATUS_TYPE_READY_TO_SYNC, result.reduivy__Status__c, 'Status should be ready to sync as user does not have the right access to update the status.'); 
        
    }

    /**
     * @description Test INQ_ExternalPortalSync_EXE executeAfterUpdate (Run as admin)
     */
    @IsTest
    static void testForExecuteAfterUpdateAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Individual_Enrollment__c ien = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c =: testCon.Id];

        List<Map<String, Object>> responseList = new List<Map<String, Object>>();
        Map<String, Object> responseItem = new Map<String, Object>();
        HttpResponse mockResponse = new HttpResponse();

        reduivy__Integration_Queue__c testINQ = new reduivy__Integration_Queue__c(
            reduivy__Action_Type__c = 'Insert',
            reduivy__Object_Type__c = 'reduivy__Individual_Enrollment__c',
            reduivy__Target_System__c = INQ_Helper.TARGET_SYSTEM_TYPE_EXT_PORTAL,
            reduivy__Object_Id__c = ien.Id
        );

        insert testINQ;


        Test.startTest();
        System.runAs(ADMIN_USER) {
            testINQ.reduivy__Status__c = INQ_Helper.STATUS_TYPE_READY_TO_SYNC;

            update testINQ;

            responseItem.put('id', ien.Id);
            responseItem.put('success', true);
            responseList.add(responseItem);
            String responseMsg = JSON.serialize(responseList);

            mockResponse.setStatusCode(200);
            mockResponse.setBody(responseMsg);
            Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));
            
            Test.stopTest();
        }

        reduivy__Integration_Queue__c result = [
                SELECT Id, reduivy__Action_Type__c, reduivy__Response_Message__c, reduivy__Status__c
                FROM reduivy__Integration_Queue__c 
                WHERE Id = :testINQ.Id
                LIMIT 1
        ];

        System.Assert.areEqual(INQ_Helper.STATUS_TYPE_SYNC_SUCCEEDED, result.reduivy__Status__c, 'Status should be sync succeeded'); 
        System.Assert.isTrue(mockResponse.getBody().contains(result.reduivy__Response_Message__c), 'Response message not match: ' + mockResponse.getBody());
    }

    /**
     * @description Test INQ_ExternalPortalSync_EXE executeAfterUpdate (Run as guest)
     */
    @IsTest
    static void testForExecuteAfterUpdateAsGuest() {
	
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Individual_Enrollment__c ien = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c =: testCon.Id];

        List<Map<String, Object>> responseList = new List<Map<String, Object>>();
        Map<String, Object> responseItem = new Map<String, Object>();
        HttpResponse mockResponse = new HttpResponse();

        User guestUser = [
            SELECT Id, ContactId
            FROM User
            WHERE ContactId = :testCon.Id
            LIMIT 1
        ];

        reduivy__Integration_Queue__c testINQ = new reduivy__Integration_Queue__c(
            reduivy__Action_Type__c = 'Insert',
            reduivy__Object_Type__c = 'reduivy__Individual_Enrollment__c',
            reduivy__Target_System__c = INQ_Helper.TARGET_SYSTEM_TYPE_EXT_PORTAL,
            reduivy__Object_Id__c = ien.Id
        );

        insert testINQ;

        testINQ.reduivy__Status__c = INQ_Helper.STATUS_TYPE_READY_TO_SYNC;

        System.runAs(guestUser) {
            //Guest user is not suppose to perform the update 
            try {
                Test.startTest();

                Database.update(testINQ, AccessLevel.USER_MODE);

                Assert.fail('An exception should have been thrown');

            } catch (System.TypeException e) {
                System.Assert.isTrue(e.getMessage().contains('DML operation UPDATE not allowed'), 'Exception message does not match: ' + e.getMessage());
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test INQ_ExternalPortalSync_EXE executeAfterInsert when more than one object types
     */
    @IsTest
    static void testForInsertMultipleObjectTypes() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Map<String, Object>> responseList = new List<Map<String, Object>>();
        Map<String, Object> responseItem = new Map<String, Object>();
        HttpResponse mockResponse = new HttpResponse();

        List<reduivy__Integration_Queue__c> testINQ = new List<reduivy__Integration_Queue__c>();
        
        testINQ.add(new reduivy__Integration_Queue__c(
            reduivy__Object_Type__c = 'objectType1'
        ));

        testINQ.add(new reduivy__Integration_Queue__c(
            reduivy__Object_Type__c = 'objectType2'
        ));

        try {
            Test.startTest();
            System.runAs(ADMIN_USER) {
                insert testINQ;
            }

            Assert.fail('An exception should have been thrown');

        } catch (Exception e) {
            System.Assert.isTrue(e.getMessage().contains(Label.Mixture_Of_Object_And_Operation_Type_Error), 'Exception message does not match: ' + e.getMessage());
        }

        Test.stopTest();
    }

    /**
     * @description Test INQ_ExternalPortalSync_EXE executeAfterUpdate when more than one object types
     */
    @IsTest
    static void testForUpdateMultipleObjectTypes() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Map<String, Object>> responseList = new List<Map<String, Object>>();
        Map<String, Object> responseItem = new Map<String, Object>();
        HttpResponse mockResponse = new HttpResponse();

        reduivy__Integration_Queue__c testINQ1 = new reduivy__Integration_Queue__c(
                reduivy__Object_Type__c = 'objectType', 
                reduivy__Status__c = INQ_Helper.STATUS_TYPE_SYNC_FAILED
        );

        reduivy__Integration_Queue__c testINQ2 = new reduivy__Integration_Queue__c(
                reduivy__Object_Type__c = 'reduivy__Individual_Enrollment__c', 
                reduivy__Status__c = INQ_Helper.STATUS_TYPE_SYNC_FAILED
        );

        insert new List<reduivy__Integration_Queue__c>{testINQ1, testINQ2};

        testINQ1.reduivy__Status__c = INQ_Helper.STATUS_TYPE_READY_TO_SYNC;
        testINQ2.reduivy__Status__c = INQ_Helper.STATUS_TYPE_READY_TO_SYNC;

        try {
            Test.startTest();

            System.runAs(ADMIN_USER) {
                update new List<reduivy__Integration_Queue__c>{testINQ1, testINQ2};
            }
            
            Assert.fail('An exception should have been thrown');

        } catch (Exception e) {
            System.Assert.isTrue(e.getMessage().contains(Label.Mixture_Of_Object_And_Operation_Type_Error), 'Exception message does not match: ' + e.getMessage());
        }

        Test.stopTest();
    }
}