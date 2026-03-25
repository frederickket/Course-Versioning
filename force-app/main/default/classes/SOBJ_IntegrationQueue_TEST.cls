/**
 * @author      WDCi (Xirouh)
 * @date        June 2024
 * @group       Test
 * @description ISS-001978 - Test class for SOBJ_IntegrationQueue_EXE
 * @changehistory
 * ISS-001978 31-06-2024 Xirouh - new Test class for SOBJ_IntegrationQueue_EXE
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@IsTest
public inherited sharing class SOBJ_IntegrationQueue_TEST {

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

        reduivy__RIO_Education_Ivy_Settings__c cs = REDU_AppSetting_UTIL.getOrgDefaultSetting();
        cs.reduivy__Enable_External_Portal_Sync__c = true;
        update cs;

        HttpResponse mockResponse = new HttpResponse();
        Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));

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

            reduivy__Individual_Enrollment__c testIEN = new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = testCon.Id, 
                reduivy__Enrollment_Status__c = 'Enrolled',
                reduivy__Individual_Academic_Profile__c = ipf.Id
            );

            insert testIEN;

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
     * @description Test SOBJ_IntegrationQueue_EXE executeAfterInsert (Run as admin)
     */
    @IsTest
    static void testForExecuteAfterInsertAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];

        HttpResponse mockResponse = new HttpResponse();
        Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));

        reduivy__Individual_Academic_Profile__c ipf = [SELECT Id FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :testCon.Id];

        Test.startTest();
        System.runAs(ADMIN_USER) {
            reduivy__Individual_Enrollment__c testIEN = new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = testCon.Id, 
                reduivy__Enrollment_Status__c = 'Enrolled',
                reduivy__Individual_Academic_Profile__c = ipf.Id
            );

            insert testIEN;

            reduivy__Integration_Queue__c inqRecord = [
                SELECT Id, reduivy__Action_Type__c, reduivy__Object_Type__c, reduivy__Status__c, reduivy__Target_System__c, reduivy__Payload1__c, reduivy__Payload2__c, reduivy__Object_Id__c 
                FROM reduivy__Integration_Queue__c 
                WHERE reduivy__Object_Id__c = :testIEN.Id
                LIMIT 1
            ];

            System.assertEquals('Insert', inqRecord.reduivy__Action_Type__c, 'Action Type should be Insert');
            System.assertEquals('reduivy__Individual_Enrollment__c', inqRecord.reduivy__Object_Type__c, 'Object Type should be reduivy__Individual_Enrollment__c');
            System.assertEquals(INQ_Helper.TARGET_SYSTEM_TYPE_EXT_PORTAL, inqRecord.reduivy__Target_System__c, 'Target System should be External Portal');
            System.assertNotEquals(null, inqRecord.reduivy__Payload1__c, 'Payload1 should not be null');
            System.assertEquals(testIEN.Id, inqRecord.reduivy__Object_Id__c, 'Object Id should match the test enrollment Id');

        }

        Test.stopTest();
    }

    /**
     * @description Test SOBJ_IntegrationQueue_EXE executeAfterInsert (Run as guest)
     */
    @IsTest
    static void testForExecuteAfterInsertAsGuest() {
	
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

        HttpResponse mockResponse = new HttpResponse();
        Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));

        try{
            Test.startTest();
            System.runAs(guestUser) {

                insert testIEN;
            }
            Test.stopTest();
        } catch (Exception exp) {
            //guest is allowed to create records, however it is not allowed to update record
            System.Assert.isTrue(exp.getMessage().contains('Insufficient UPDATABLE access on following object(s) and field(s) - reduivy__Integration_Queue__c'), 'Unexpected error: ' + exp.getMessage());
        }
    }

    /**
     * @description Test SOBJ_IntegrationQueue_EXE executeAfterUpdate (Run as admin)
     */
    @IsTest
    static void testForExecuteAfterUpdateAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];
        
        reduivy__Individual_Enrollment__c testIEN = [
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            LIMIT 1
        ];

        testIEN.reduivy__Enrollment_Status__c = 'Completed';

        HttpResponse mockResponse = new HttpResponse();
        Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));

        Test.startTest();
        System.runAs(ADMIN_USER) {
            update testIEN; 

            reduivy__Integration_Queue__c inqRecord = [
                SELECT Id, reduivy__Action_Type__c, reduivy__Object_Type__c, reduivy__Status__c, reduivy__Target_System__c, reduivy__Payload1__c, reduivy__Payload2__c, reduivy__Object_Id__c 
                FROM reduivy__Integration_Queue__c 
                WHERE reduivy__Object_Id__c = :testIEN.Id
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            
            System.assertEquals('Update', inqRecord.reduivy__Action_Type__c, 'Action Type should be Update');
            System.assertEquals('reduivy__Individual_Enrollment__c', inqRecord.reduivy__Object_Type__c, 'Object Type should be reduivy__Individual_Enrollment__c');
            System.assertEquals(INQ_Helper.TARGET_SYSTEM_TYPE_EXT_PORTAL, inqRecord.reduivy__Target_System__c, 'Target System should be External Portal');
            System.assertNotEquals(null, inqRecord.reduivy__Payload1__c, 'Payload1 should not be null');
            System.assertEquals(testIEN.Id, inqRecord.reduivy__Object_Id__c, 'Object Id should match the test enrollment Id');

        }

        Test.stopTest();
    }

    /**
     * @description Test SOBJ_IntegrationQueue_EXE executeAfterUpdate (Run as guest)
     */
    @IsTest
    static void testForExecuteAfterUpdateAsGuest() {
	
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];

        User guestUser = [
            SELECT Id, ContactId
            FROM User
            WHERE ContactId = :testCon.Id
            LIMIT 1
        ];
        
        reduivy__Individual_Enrollment__c testIEN = [
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            LIMIT 1
        ];

        testIEN.reduivy__Enrollment_Status__c = 'Completed';

        HttpResponse mockResponse = new HttpResponse();
        Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));

        System.runAs(guestUser) {
            //Guest user is not suppose to perform the update 
            try {
                Test.startTest();

                Database.update(testIEN, AccessLevel.USER_MODE);

                Assert.fail('An exception should have been thrown');

                Test.stopTest();
            } catch (System.TypeException e) {
                Assert.isTrue(
                e.getMessage().contains('DML operation UPDATE not allowed'),
                'Exception message does not match: ' + e.getMessage()
                );
            }
            
        }
    }

    /**
     * @description Test SOBJ_IntegrationQueue_EXE executeAfterDelete (Run as admin)
     */
    @IsTest
    static void testForExecuteAfterDeleteAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];

        reduivy__Individual_Enrollment__c testIEN = [
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            LIMIT 1
        ];

        HttpResponse mockResponse = new HttpResponse();
        Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));

        Test.startTest();
        System.runAs(ADMIN_USER) {
            delete testIEN; 

            reduivy__Integration_Queue__c inqRecord = [
                SELECT Id, reduivy__Action_Type__c, reduivy__Object_Type__c, reduivy__Status__c, reduivy__Target_System__c, reduivy__Payload1__c, reduivy__Payload2__c, reduivy__Object_Id__c 
                FROM reduivy__Integration_Queue__c 
                WHERE reduivy__Object_Id__c = :testIEN.Id
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            
            System.assertEquals('Delete', inqRecord.reduivy__Action_Type__c, 'Action Type should be Delete');
            System.assertEquals('reduivy__Individual_Enrollment__c', inqRecord.reduivy__Object_Type__c, 'Object Type should be reduivy__Individual_Enrollment__c');
            System.assertEquals(INQ_Helper.TARGET_SYSTEM_TYPE_EXT_PORTAL, inqRecord.reduivy__Target_System__c, 'Target System should be External Portal');
            System.assertNotEquals(null, inqRecord.reduivy__Payload1__c, 'Payload1 should not be null');
            System.assertEquals(testIEN.Id, inqRecord.reduivy__Object_Id__c, 'Object Id should match the test enrollment Id');
        
        }

        Test.stopTest();
    }

    /**
     * @description Test SOBJ_IntegrationQueue_EXE executeAfterDelete (Run as guest)
     */
    @IsTest
    static void testForExecuteAfterDeleteAsGuest() {
	
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];

        User guestUser = [
            SELECT Id, ContactId
            FROM User
            WHERE ContactId = :testCon.Id
            LIMIT 1
        ];
        
        reduivy__Individual_Enrollment__c testIEN = [
            SELECT Id, reduivy__Enrollment_Status__c , IsDeleted
            FROM reduivy__Individual_Enrollment__c 
            LIMIT 1
        ];

        HttpResponse mockResponse = new HttpResponse();
        Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));

        System.runAs(guestUser) {
            //Guest user is not suppose to perform the delete 
            try {
                Test.startTest();

                Database.delete(testIEN, AccessLevel.USER_MODE);

                Assert.fail('An exception should have been thrown');

                Test.stopTest();

            } catch (System.TypeException e) {
                Assert.isTrue(
                e.getMessage().contains('DML operation DELETE not allowed'),
                'Exception message does not match: ' + e.getMessage()
                );
            }
            
        }
    }

    /**
     * @description Test SOBJ_IntegrationQueue_EXE executeAfterUndelete (Run as admin)
     */
    @IsTest
    static void testForExecuteAfterUndeleteAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];

        reduivy__Individual_Enrollment__c testIEN = [
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            LIMIT 1
        ];
        
        HttpResponse mockResponse = new HttpResponse();
        Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));

        Test.startTest();
        System.runAs(ADMIN_USER) {
            delete testIEN; 

            Database.undelete(testIEN, AccessLevel.USER_MODE);

            reduivy__Integration_Queue__c inqRecord = [
                SELECT Id, reduivy__Action_Type__c, reduivy__Object_Type__c, reduivy__Status__c, reduivy__Target_System__c, reduivy__Payload1__c, reduivy__Payload2__c, reduivy__Object_Id__c 
                FROM reduivy__Integration_Queue__c 
                WHERE reduivy__Object_Id__c = :testIEN.Id
                AND reduivy__Action_Type__c = 'Undelete'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            
            System.assertEquals('Undelete', inqRecord.reduivy__Action_Type__c, 'Action Type should be Undelete');
            System.assertEquals('reduivy__Individual_Enrollment__c', inqRecord.reduivy__Object_Type__c, 'Object Type should be reduivy__Individual_Enrollment__c');
            System.assertEquals(INQ_Helper.TARGET_SYSTEM_TYPE_EXT_PORTAL, inqRecord.reduivy__Target_System__c, 'Target System should be External Portal');
            System.assertNotEquals(null, inqRecord.reduivy__Payload1__c, 'Payload1 should not be null');
            System.assertEquals(testIEN.Id, inqRecord.reduivy__Object_Id__c, 'Object Id should match the test enrollment Id');

        }

        Test.stopTest();
    }

    /**
     * @description Test SOBJ_IntegrationQueue_EXE executeAfterUndelete (Run as guest)
     */
    @IsTest
    static void testForExecuteAfterUndeleteAsGuest() {
	
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];

        User guestUser = [
            SELECT Id, ContactId
            FROM User
            WHERE ContactId = :testCon.Id
            LIMIT 1
        ];
        
        reduivy__Individual_Enrollment__c testIEN = [
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            LIMIT 1
        ];


        HttpResponse mockResponse = new HttpResponse();
        Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));

        System.runAs(guestUser) {

            //Guest user is not suppose to perform the undelete 
            try {
                Test.startTest();

                REDU_SystemMode_UTIL.doDelete(new List<reduivy__Individual_Enrollment__c>{testIEN});

                Assert.fail('An exception should have been thrown');

                Test.stopTest();
                
            } catch (Exception exp) {
                Assert.isTrue(
                    exp.getMessage().contains('Insufficient Delete access on following object(s) and field(s) - reduivy__Individual_Enrollment__c'),
                    'Exception message does not match: ' + exp.getMessage()
                );
            }
        }
    }
}