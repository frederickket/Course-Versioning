/**
 * @author      WDCi (Xirouh)
 * @date        June 2024
 * @group       Test
 * @description Test class for INQ_Helper
 * @changehistory
 * ISS-001978 24-06-2024  Xirouh - new class
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@IsTest
public inherited sharing class INQ_Helper_TEST {

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
            reduivy__RIO_Education_Ivy_Settings__c cs = [SELECT Id, reduivy__Enable_External_Portal_Sync__c FROM reduivy__RIO_Education_Ivy_Settings__c LIMIT 1];
            cs.reduivy__Enable_External_Portal_Sync__c = true;
            update cs;
        }
    }

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Integration_Queue__c.getLabel(), INQ_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Integration_Queue__c.getLabelPlural(), INQ_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Integration_Queue__c.getName(), INQ_Helper.getApiName());

        Test.stopTest();
    }

    /**
     * @description Test addIntegrationQueue
     */
    @IsTest
    static void testAddIntegrationQueue(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact testCon = new Contact(LastName = 'Doe', reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT);

        insert testCon;

        reduivy__Individual_Enrollment__c testIEN = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = testCon.Id, 
            reduivy__Enrollment_Status__c = 'Enrolled'
        );
        
        HttpResponse mockResponse = new HttpResponse();
        Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));

        Test.startTest();
        System.runAs(ADMIN_USER) {

            insert testIEN;  

            Test.stopTest();

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
    }

    /**
     * @description Test payload2
     */
    @IsTest
    static void testPayload2(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Prepare success and failure IDs
        List<Id> successIds = new List<Id>{};
        List<Id> failureIds = new List<Id>{}; 
        Integer statusCode = 200;

        HttpResponse mockResponse = new HttpResponse();
        Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));

        String largeString = 'x'.repeat(131073);

        reduivy__Integration_Queue__c longPayload = new reduivy__Integration_Queue__c (
            reduivy__Payload1__c = largeString
        );

        Test.startTest();
        System.runAs(ADMIN_USER) {

            Schema.DescribeSObjectResult sobjResult = reduivy__Integration_Queue__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED);
            SObject sObj = longPayload;

            // Call the addIntegrationQueue method
            reduivy__Integration_Queue__c result = INQ_Helper.addIntegrationQueue(
                'Insert',
                sobjResult,
                sObj,
                INQ_Helper.STATUS_TYPE_READY_TO_SYNC,
                INQ_Helper.TARGET_SYSTEM_TYPE_EXT_PORTAL
            );

            Test.stopTest();

            // Verify the payload is split correctly
            System.assertNotEquals(null, result.reduivy__Payload1__c, 'Payload1 should not be null');
            System.assertEquals(131072, result.reduivy__Payload1__c.length(), 'Payload1 should have 131072 characters');
            System.assertNotEquals(null, result.reduivy__Payload2__c, 'Payload2 should not be null');
        }        
    }

    /**
     * @description Test isDeleted Flag
     */
    @IsTest
    static void testIsDeletedFlag(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact testCon = new Contact(LastName = 'Doe');

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

        HttpResponse mockResponse = new HttpResponse();
        Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));

        Test.startTest();
        System.runAs(ADMIN_USER) {

            delete testIEN;

            Test.stopTest();
            
            reduivy__Integration_Queue__c result = [SELECT Id, reduivy__Payload1__c FROM reduivy__Integration_Queue__c WHERE reduivy__Object_Id__c = :testIEN.Id AND reduivy__Action_Type__c = :INQ_Helper.ACTION_TYPE_DELETE LIMIT 1];
            Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(result.reduivy__Payload1__c);

            System.assertEquals(true, payloadMap.get('IsDeleted'), 'The IsDeleted flag should be true.');
        }        
    }
}