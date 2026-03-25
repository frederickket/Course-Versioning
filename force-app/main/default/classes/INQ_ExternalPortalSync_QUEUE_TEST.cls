/**
 * @author      WDCi (Xirouh)
 * @date        July 2024
 * @group       Test
 * @description Test class for INQ_ExternalPortalSync_QUEUE
 * @changehistory
 * ISS-001978 24-06-2024 Xirouh - new class
 */
@IsTest
public inherited sharing class INQ_ExternalPortalSync_QUEUE_TEST {

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
            
            Contact testCon = new Contact(LastName = 'Doe', reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT);

            insert testCon;

            Test.stopTest();
        }
    }
	
    /**
     * @description Test for INQ_ExternalPortalSync_QUEUE Line if (inqIdsList == null || inqIdsList.isEmpty())
     */
    @IsTest
    static void testForINQ_ExternalPortalSync_QUEUE() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<List<Id>> nullList = new List<List<Id>>();

        Test.startTest();

        System.runAs(ADMIN_USER) {
            INQ_ExternalPortalSync_QUEUE queueJob = new INQ_ExternalPortalSync_QUEUE(nullList);
            Id jobId = System.enqueueJob(queueJob);    

            System.Assert.isNotNull(jobId, 'The job should be queued successfully.');
        }

        Test.stopTest();
    }

    /**
     * @description Test for PATCH action type for line 
     * if (record.reduivy__Action_Type__c == INQ_Helper.ACTION_TYPE_UPDATE || record.reduivy__Action_Type__c == INQ_Helper.ACTION_TYPE_DELETE) {
        httpMethod = 'PATCH';
        }
     */
    @IsTest
    static void testForPatchActionType() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];
        
        List<Map<String, Object>> responseList = new List<Map<String, Object>>();
        Map<String, Object> responseItem = new Map<String, Object>();
        HttpResponse mockResponse = new HttpResponse();
        Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));

        reduivy__Integration_Queue__c testINQ = new reduivy__Integration_Queue__c(
                reduivy__Action_Type__c = INQ_Helper.ACTION_TYPE_UPDATE,
                reduivy__Object_Type__c = 'reduivy__Individual_Enrollment__c',
                reduivy__Status__c = INQ_Helper.STATUS_TYPE_READY_TO_SYNC,
                reduivy__Target_System__c = INQ_Helper.TARGET_SYSTEM_TYPE_EXT_PORTAL,
                reduivy__Object_Id__c = testCon.Id,
                reduivy__Payload2__c = 'payload2'
        );

        Test.startTest();
        System.runAs(ADMIN_USER) {
            insert testINQ;
        }
            
        Test.stopTest();

        reduivy__Integration_Queue__c result = [
                SELECT Id, reduivy__Action_Type__c
                FROM reduivy__Integration_Queue__c 
                WHERE Id = :testINQ.Id
                LIMIT 1
        ];

        System.Assert.areEqual(INQ_Helper.ACTION_TYPE_UPDATE, result.reduivy__Action_Type__c, 'Action type should be update.'); 
    }

    /**
     * @description Test for doCallout with bad response message (JSONException)
     */
    @IsTest
    static void testForDoCalloutWithBadResponseMsg() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];

        HttpResponse mockResponse = new HttpResponse();

        reduivy__Individual_Enrollment__c testIEN = new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = testCon.Id, 
                reduivy__Enrollment_Status__c = 'Enrolled'
        );

        Test.startTest();
        System.runAs(ADMIN_USER) {
            insert testIEN;

            mockResponse.setStatusCode(200);
            mockResponse.setBody('testBadResponseMsg');
            Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));
        }

        Test.stopTest();

        reduivy__Integration_Queue__c result = [
                SELECT Id, reduivy__Action_Type__c, reduivy__Response_Message__c, reduivy__Status__c
                FROM reduivy__Integration_Queue__c 
                WHERE reduivy__Object_Id__c = :testIEN.Id
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        System.Assert.areEqual(INQ_Helper.STATUS_TYPE_SYNC_FAILED, result.reduivy__Status__c, 'Status should be sync failed');
        String responseMessageFirstLine = result.reduivy__Response_Message__c.split('\n')[0];

        System.Assert.isTrue(INQ_Helper.BAD_RESPONSE_MSG.contains(responseMessageFirstLine), 
            'Status code not found error message not match: ' + responseMessageFirstLine);    
    }

    /**
     * @description Test for success doCallout with structured JSON response
     */
    @IsTest
    static void testForDoCalloutWithSuccessResponse() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];

        List<Map<String, Object>> responseList = new List<Map<String, Object>>();
        Map<String, Object> responseItem = new Map<String, Object>();
        HttpResponse mockResponse = new HttpResponse();

        Test.startTest();

        reduivy__Individual_Enrollment__c testIEN = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = testCon.Id, 
            reduivy__Enrollment_Status__c = 'Enrolled'
        );

        System.runAs(ADMIN_USER) {

            insert testIEN;
        }

        responseItem.put('id', testIEN.Id);
        responseItem.put('success', true);
        responseList.add(responseItem);
        String responseMsg = JSON.serialize(responseList);

        mockResponse.setStatusCode(200);
        mockResponse.setBody(responseMsg);
        Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));

        Test.stopTest();

        reduivy__Integration_Queue__c result = [
                SELECT Id, reduivy__Action_Type__c, reduivy__Response_Message__c, reduivy__Status__c
                FROM reduivy__Integration_Queue__c 
                WHERE reduivy__Object_Id__c = :testIEN.Id
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        System.Assert.areEqual(INQ_Helper.STATUS_TYPE_SYNC_SUCCEEDED, result.reduivy__Status__c, 'Status should be sync succeeded'); 
        System.Assert.isTrue(mockResponse.getBody().contains(result.reduivy__Response_Message__c), 'Response message not match: ' + mockResponse.getBody());
    }

    /**
     * @description Test for doCallout with structured JSON response but id not found
     */
    @IsTest
    static void testForDoCalloutIdNotFound() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];

        List<Map<String, Object>> responseList = new List<Map<String, Object>>();
        Map<String, Object> responseItem = new Map<String, Object>();
        HttpResponse mockResponse = new HttpResponse();
        responseItem.put('id', testCon.Id);
        responseItem.put('success', true);
        responseList.add(responseItem);
        String responseMsg = JSON.serialize(responseList);

        mockResponse.setStatusCode(200);
        mockResponse.setBody(responseMsg);
        Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));

        Test.startTest();
        reduivy__Individual_Enrollment__c testIEN = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = testCon.Id, 
            reduivy__Enrollment_Status__c = 'Enrolled'
        );

        System.runAs(ADMIN_USER) {

            insert testIEN;
        }

        Test.stopTest();

        reduivy__Integration_Queue__c result = [
                SELECT Id, reduivy__Action_Type__c, reduivy__Response_Message__c, reduivy__Status__c
                FROM reduivy__Integration_Queue__c 
                WHERE reduivy__Object_Id__c = :testIEN.Id
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        System.Assert.areEqual(INQ_Helper.STATUS_TYPE_SYNC_FAILED, result.reduivy__Status__c, 'Status should be sync failed'); 
        String responseMessageFirstLine = result.reduivy__Response_Message__c.split('\n')[0];

        System.Assert.isTrue(INQ_Helper.RECORD_NOT_FOUND.contains(responseMessageFirstLine), 
            'Status code not found error message not match: ' + responseMessageFirstLine);    
        }

    /**
     * @description Test for doCallout with status code not in the successStatusCodeList
     */
    @IsTest
    static void testForDoCalloutStatusCodeNotFound() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];

        List<Map<String, Object>> responseList = new List<Map<String, Object>>();
        Map<String, Object> responseItem = new Map<String, Object>();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(404);
        Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));

        Test.startTest();
        reduivy__Individual_Enrollment__c testIEN = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = testCon.Id, 
            reduivy__Enrollment_Status__c = 'Enrolled'
        );

        System.runAs(ADMIN_USER) {

            insert testIEN;
        }

        Test.stopTest();

        reduivy__Integration_Queue__c result = [
                SELECT Id, reduivy__Action_Type__c, reduivy__Response_Message__c, reduivy__Status__c
                FROM reduivy__Integration_Queue__c 
                WHERE reduivy__Object_Id__c = :testIEN.Id
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        System.debug(INQ_Helper.SUCCESS_CODE_NOT_IN_LIST);
        System.debug(result.reduivy__Response_Message__c);

        System.Assert.areEqual(INQ_Helper.STATUS_TYPE_SYNC_FAILED, result.reduivy__Status__c, 'Status should be sync failed');

        String responseMessageFirstLine = result.reduivy__Response_Message__c.split('\n')[0];

        System.Assert.isTrue(INQ_Helper.SUCCESS_CODE_NOT_IN_LIST.contains(responseMessageFirstLine), 
            'Status code not found error message not match: ' + responseMessageFirstLine);    
    }

    /**
     * @description Test for doCallout when inqConfig not found
     */
    @IsTest
    static void testForDoCalloutINQConfigNotFound() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];

        List<Map<String, Object>> responseList = new List<Map<String, Object>>();
        Map<String, Object> responseItem = new Map<String, Object>();
        HttpResponse mockResponse = new HttpResponse();
        Test.setMock(HttpCalloutMock.class, new INQ_ExternalPortalSync_TESTMOCK(mockResponse));

        Test.startTest();
        reduivy__Integration_Queue__c testINQ = new reduivy__Integration_Queue__c(
            reduivy__Action_Type__c = INQ_Helper.ACTION_TYPE_UPDATE,
            reduivy__Object_Type__c = 'inqConfig Not Found',
            reduivy__Status__c = INQ_Helper.STATUS_TYPE_READY_TO_SYNC,
            reduivy__Target_System__c = INQ_Helper.TARGET_SYSTEM_TYPE_EXT_PORTAL,
            reduivy__Object_Id__c = testCon.Id
        );

        System.runAs(ADMIN_USER) {    

            insert testINQ;
        }

        Test.stopTest();

        reduivy__Integration_Queue__c result = [
                SELECT Id, reduivy__Action_Type__c, reduivy__Response_Message__c, reduivy__Status__c
                FROM reduivy__Integration_Queue__c 
                WHERE Id = :testINQ.Id
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        System.Assert.areEqual(INQ_Helper.STATUS_TYPE_SYNC_FAILED, result.reduivy__Status__c, 'Status should be sync failed');
        System.Assert.isTrue(INQ_Helper.ENDPOINT_NOT_FOUND.contains(result.reduivy__Response_Message__c), 'Endpoint not found error message not match: ' + result.reduivy__Response_Message__c);
    }
}