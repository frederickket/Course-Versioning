/**
 * @author      WDCi (Lean)
 * @date        Dec 2024
 * @group       Test
 * @description Test class for JQH_CancelJob_FLOW
 * @changehistory
 * ISS-002219 31-12-2024 Lean - new class
 * ISS-002547 14-07-2025 Lean - Added job group test
 */

@IsTest
public inherited sharing class JQH_CancelJob_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Initialise test data for each test
     */
    @TestSetup
    static void makeData(){
        
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(SPS_Helper.getApiName());
            testFactory.initOfferingData(SOF_Helper.getApiName());
			testFactory.initStudentData(IEN_Helper.getApiName(), false);

            Test.stopTest();
        }
    }

    /**
     * @description Test cancel pending job as admin
     */
    @IsTest
    static void testCancelPendingJobAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);
        
        Test.startTest();

        System.runAs(ADMIN_USER){
            //simulate the data from flow
            JQH_AddJob_FLOW.Request flowRequest = new JQH_AddJob_FLOW.Request();
            flowRequest.jobOperationContext = 'Sample_Job';
            flowRequest.jobOperation = 'Sample_Job';
            flowRequest.paramsString = JQH_Helper.serializeParams(params);
            flowRequest.recordIds = new List<Id>(ienMaps.keySet());
            flowRequest.startWorker = false;

            //invoke the method
            List<JQH_AddJob_FLOW.Response> responses = JQH_AddJob_FLOW.execute(new List<JQH_AddJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
            System.Assert.areEqual(Label.Job_Was_Added_To_Queue, responses.get(0).message);
        }
        
        Test.stopTest();

        reduivy__Job_Queue__c jobQueueBefore = [SELECT Id, Name, reduivy__Job_Operation_Context__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation_Context__c = 'Sample_Job'];

        System.Assert.areEqual(JQH_Helper.STATUS_PENDING, jobQueueBefore.reduivy__Status__c);

        System.runAs(ADMIN_USER) {
            //simulate the data from flow
            JQH_CancelJob_FLOW.Request flowRequest = new JQH_CancelJob_FLOW.Request();
            flowRequest.jobQueueId = jobQueueBefore.Id;

            //invoke the method
            List<JQH_CancelJob_FLOW.Response> responses = JQH_CancelJob_FLOW.execute(new List<JQH_CancelJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(Label.Job_Queue_Was_Cancelled, responses.get(0).message);
            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
        }

        reduivy__Job_Queue__c jobQueueAfter = [SELECT Id, Name, reduivy__Job_Operation_Context__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation_Context__c = 'Sample_Job'];

        System.Assert.areEqual(JQH_Helper.STATUS_CANCELLED, jobQueueAfter.reduivy__Status__c);
    }

    /**
     * @description Test cancel pending job queue group as admin
     */
    @IsTest
    static void testCancelPendingJobQueueGroupAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);
        
        Test.startTest();

        System.runAs(ADMIN_USER){
            //simulate the data from flow
            JQH_AddJob_FLOW.Request flowRequest = new JQH_AddJob_FLOW.Request();
            flowRequest.jobOperationContext = 'Sample_Job';
            flowRequest.jobOperation = 'Sample_Job';
            flowRequest.paramsString = JQH_Helper.serializeParams(params);
            flowRequest.recordIds = new List<Id>(ienMaps.keySet());
            flowRequest.startWorker = false;

            //invoke the method
            List<JQH_AddJob_FLOW.Response> responses = JQH_AddJob_FLOW.execute(new List<JQH_AddJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
            System.Assert.areEqual(Label.Job_Was_Added_To_Queue, responses.get(0).message);
        }
        
        Test.stopTest();

        reduivy__Job_Queue_Group__c jobQueueGroupBefore = [SELECT Id, Name, reduivy__Job_Operation_Context__c, reduivy__Status__c FROM reduivy__Job_Queue_Group__c WHERE reduivy__Job_Operation_Context__c = 'Sample_Job'];

        System.Assert.areEqual(JQG_Helper.STATUS_PENDING, jobQueueGroupBefore.reduivy__Status__c);

        System.runAs(ADMIN_USER) {
            //simulate the data from flow
            JQH_CancelJob_FLOW.Request flowRequest = new JQH_CancelJob_FLOW.Request();
            flowRequest.jobQueueId = jobQueueGroupBefore.Id;

            //invoke the method
            List<JQH_CancelJob_FLOW.Response> responses = JQH_CancelJob_FLOW.execute(new List<JQH_CancelJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(Label.Job_Queue_Group_Was_Cancelled, responses.get(0).message);
            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
        }

        reduivy__Job_Queue_Group__c jobQueueGroupAfter = [SELECT Id, Name, reduivy__Job_Operation_Context__c, reduivy__Status__c FROM reduivy__Job_Queue_Group__c WHERE reduivy__Job_Operation_Context__c = 'Sample_Job'];

        System.Assert.areEqual(JQG_Helper.STATUS_CANCELLED, jobQueueGroupAfter.reduivy__Status__c);
    }

    /**
     * @description Test cancel multiple pending jobs by job queue and job queue group as admin
     */
    @IsTest
    static void testCancelMultiplePendingJobsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);
        
        Test.startTest();

        System.runAs(ADMIN_USER){
            //simulate the data from flow
            JQH_AddJob_FLOW.Request flowRequest1 = new JQH_AddJob_FLOW.Request();
            flowRequest1.jobOperationContext = 'Sample_Job_1';
            flowRequest1.jobOperation = 'Sample_Job';
            flowRequest1.paramsString = JQH_Helper.serializeParams(params);
            flowRequest1.recordIds = new List<Id>(ienMaps.keySet());
            flowRequest1.startWorker = false;

            JQH_AddJob_FLOW.Request flowRequest2 = new JQH_AddJob_FLOW.Request();
            flowRequest2.jobOperationContext = 'Sample_Job_2';
            flowRequest2.jobOperation = 'Sample_Job';
            flowRequest2.paramsString = JQH_Helper.serializeParams(params);
            flowRequest2.recordIds = new List<Id>(ienMaps.keySet());
            flowRequest2.startWorker = false;

            //invoke the method
            List<JQH_AddJob_FLOW.Response> responses = JQH_AddJob_FLOW.execute(new List<JQH_AddJob_FLOW.Request>{flowRequest1, flowRequest2});

            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
            System.Assert.areEqual(Label.Job_Was_Added_To_Queue, responses.get(0).message);
        }
        
        Test.stopTest();

        reduivy__Job_Queue__c jobQueueBefore = [SELECT Id, Name, reduivy__Job_Operation_Context__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation_Context__c = 'Sample_Job_1'];
        reduivy__Job_Queue_Group__c jobQueueGroupBefore = [SELECT Id, Name, reduivy__Job_Operation_Context__c, reduivy__Status__c FROM reduivy__Job_Queue_Group__c WHERE reduivy__Job_Operation_Context__c = 'Sample_Job_2'];

        System.Assert.areEqual(JQH_Helper.STATUS_PENDING, jobQueueBefore.reduivy__Status__c);
        System.Assert.areEqual(JQG_Helper.STATUS_PENDING, jobQueueGroupBefore.reduivy__Status__c);

        System.runAs(ADMIN_USER) {
            //simulate the data from flow
            JQH_CancelJob_FLOW.Request flowRequest1 = new JQH_CancelJob_FLOW.Request();
            flowRequest1.jobQueueId = jobQueueBefore.Id;

            JQH_CancelJob_FLOW.Request flowRequest2 = new JQH_CancelJob_FLOW.Request();
            flowRequest2.jobQueueId = jobQueueGroupBefore.Id;

            //invoke the method
            List<JQH_CancelJob_FLOW.Response> responses = JQH_CancelJob_FLOW.execute(new List<JQH_CancelJob_FLOW.Request>{flowRequest1, flowRequest2});

            System.Assert.areEqual(Label.Job_Queue_Was_Cancelled, responses.get(0).message);
            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);

            System.Assert.areEqual(Label.Job_Queue_Group_Was_Cancelled, responses.get(1).message);
            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(1).status);
        }

        reduivy__Job_Queue__c jobQueueAfter = [SELECT Id, Name, reduivy__Job_Operation_Context__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation_Context__c = 'Sample_Job_1'];
        reduivy__Job_Queue_Group__c jobQueueGroupAfter = [SELECT Id, Name, reduivy__Job_Operation_Context__c, reduivy__Status__c FROM reduivy__Job_Queue_Group__c WHERE reduivy__Job_Operation_Context__c = 'Sample_Job_2'];

        System.Assert.areEqual(JQH_Helper.STATUS_CANCELLED, jobQueueAfter.reduivy__Status__c);
        System.Assert.areEqual(JQG_Helper.STATUS_CANCELLED, jobQueueGroupAfter.reduivy__Status__c);
    }

    /**
     * @description Test cancel a completed job as admin
     */
    @IsTest
    static void testCancelCompletedJobAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);  

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //simulate the data from flow
            JQH_AddJob_FLOW.Request flowRequest = new JQH_AddJob_FLOW.Request();
            flowRequest.jobOperationContext = 'Sample_Job';
            flowRequest.jobOperation = 'Sample_Job';
            flowRequest.paramsString = JQH_Helper.serializeParams(params);
            flowRequest.recordIds = new List<Id>(ienMaps.keySet());
            flowRequest.startWorker = true;

            //invoke the method
            List<JQH_AddJob_FLOW.Response> responses = JQH_AddJob_FLOW.execute(new List<JQH_AddJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
        }

        Test.stopTest();
        
        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Job_Operation_Context__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation_Context__c = 'Sample_Job'];

        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, jobQueue.reduivy__Status__c);

        System.runAs(ADMIN_USER) {
            //simulate the data from flow
            JQH_CancelJob_FLOW.Request flowRequest = new JQH_CancelJob_FLOW.Request();
            flowRequest.jobQueueId = jobQueue.Id;

            //invoke the method
            List<JQH_CancelJob_FLOW.Response> responses = JQH_CancelJob_FLOW.execute(new List<JQH_CancelJob_FLOW.Request>{flowRequest});

            String expectedError = String.format(Label.Job_Queue_Cannot_Be_Cancelled, new List<String>{jobQueue.Name});
            System.Assert.areEqual(expectedError, responses.get(0).message);
            System.Assert.areEqual(JQH_JobManager.FAIL, responses.get(0).status);

        }
    }

    /**
     * @description Test cancel a completed job queue group as admin
     */
    @IsTest
    static void testCancelCompletedJobQueueGroupAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);  

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //simulate the data from flow
            JQH_AddJob_FLOW.Request flowRequest = new JQH_AddJob_FLOW.Request();
            flowRequest.jobOperationContext = 'Sample_Job';
            flowRequest.jobOperation = 'Sample_Job';
            flowRequest.paramsString = JQH_Helper.serializeParams(params);
            flowRequest.recordIds = new List<Id>(ienMaps.keySet());
            flowRequest.startWorker = true;

            //invoke the method
            List<JQH_AddJob_FLOW.Response> responses = JQH_AddJob_FLOW.execute(new List<JQH_AddJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
        }

        Test.stopTest();
        
        reduivy__Job_Queue_Group__c jobQueueGroup = [SELECT Id, Name, reduivy__Job_Operation_Context__c, reduivy__Status__c FROM reduivy__Job_Queue_Group__c WHERE reduivy__Job_Operation_Context__c = 'Sample_Job'];

        System.Assert.areEqual(JQG_Helper.STATUS_COMPLETED, jobQueueGroup.reduivy__Status__c);

        System.runAs(ADMIN_USER) {
            //simulate the data from flow
            JQH_CancelJob_FLOW.Request flowRequest = new JQH_CancelJob_FLOW.Request();
            flowRequest.jobQueueId = jobQueueGroup.Id;

            //invoke the method
            List<JQH_CancelJob_FLOW.Response> responses = JQH_CancelJob_FLOW.execute(new List<JQH_CancelJob_FLOW.Request>{flowRequest});

            String expectedError = String.format(Label.Job_Queue_Group_Cannot_Be_Cancelled, new List<String>{jobQueueGroup.Name});
            System.Assert.areEqual(expectedError, responses.get(0).message);
            System.Assert.areEqual(JQH_JobManager.FAIL, responses.get(0).status);

        }
    }

    /**
     * @description Test cancel an invalid job as admin
     */
    @IsTest
    static void testCancelInvalidJobAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //simulate the data from flow
            JQH_CancelJob_FLOW.Request flowRequest = new JQH_CancelJob_FLOW.Request();
            flowRequest.jobQueueId = Id.valueOf('a0v9n000001iBFRAA2');

            //invoke the method
            List<JQH_CancelJob_FLOW.Response> responses = JQH_CancelJob_FLOW.execute(new List<JQH_CancelJob_FLOW.Request>{flowRequest});

            String expextedError = String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{flowRequest.jobQueueId, JQG_Helper.getObjectLabel() + '/' + JQH_Helper.getObjectLabel()});
            System.Assert.areEqual(expextedError, responses.get(0).message);
            System.Assert.areEqual(JQH_JobManager.FAIL, responses.get(0).status);

        }

        Test.stopTest();
    }
}