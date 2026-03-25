/**
 * @author      WDCi (Lean)
 * @date        Dec 2024
 * @group       Test
 * @description Test class for JQH_AddJob_FLOW
 * @changehistory
 * ISS-002219 31-12-2024 Lean - new class
 * ISS-002547 14-07-2025 Lean - Added jobOperationContext
 */

@IsTest
public inherited sharing class JQH_AddJob_TEST {
    
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
     * @description Test add job as admin
     */
    @IsTest
    static void testAddJobWithWorkerAsAdmin(){
        
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
            List<JQH_AddJob_FLOW.Response> responses = JQH_AddJob_Flow.execute(new List<JQH_AddJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(Label.Job_Was_Added_To_Queue, responses.get(0).message);
            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
        }

        Test.stopTest();
        
        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, jobQueue.reduivy__Status__c);
        System.Assert.isNotNull(jobQueue.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areEqual(JQG_Helper.STATUS_COMPLETED, jobQueue.reduivy__Job_Queue_Group__r.reduivy__Status__c);
    }

    /**
     * @description Test add job without starting the worker as admin
     */
    @IsTest
    static void testAddJobWithoutWorkerAsAdmin(){
        
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
            List<JQH_AddJob_FLOW.Response> responses = JQH_AddJob_Flow.execute(new List<JQH_AddJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(Label.Job_Was_Added_To_Queue, responses.get(0).message);
            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
        }

        Test.stopTest();
        
        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(JQH_Helper.STATUS_PENDING, jobQueue.reduivy__Status__c);
        System.Assert.isNotNull(jobQueue.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areEqual(JQG_Helper.STATUS_PENDING, jobQueue.reduivy__Job_Queue_Group__r.reduivy__Status__c);
    }

    /**
     * @description Test add multiple jobs as admin, the jobs that have the same operation context should be grouped under the same job queue group
     */
    @IsTest
    static void testAddMultipleJobsWithWorkerAsAdmin(){
        
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
            flowRequest1.startWorker = true;

            JQH_AddJob_FLOW.Request flowRequest2 = new JQH_AddJob_FLOW.Request();
            flowRequest2.jobOperationContext = 'Sample_Job_2';
            flowRequest2.jobOperation = 'Sample_Job';
            flowRequest2.paramsString = JQH_Helper.serializeParams(params);
            flowRequest2.recordIds = new List<Id>(ienMaps.keySet());
            flowRequest2.startWorker = true;

            JQH_AddJob_FLOW.Request flowRequest3 = new JQH_AddJob_FLOW.Request();
            flowRequest3.jobOperationContext = 'Sample_Job_2';
            flowRequest3.jobOperation = 'Sample_Job';
            flowRequest3.paramsString = JQH_Helper.serializeParams(params);
            flowRequest3.recordIds = new List<Id>(ienMaps.keySet());
            flowRequest3.startWorker = true;

            //invoke the method
            List<JQH_AddJob_FLOW.Response> responses = JQH_AddJob_Flow.execute(new List<JQH_AddJob_FLOW.Request>{flowRequest1, flowRequest2, flowRequest3});

            System.Assert.areEqual(Label.Job_Was_Added_To_Queue, responses.get(0).message);
            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
        }

        Test.stopTest();
        
        List<reduivy__Job_Queue__c> jobQueues = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Job_Operation_Context__c, reduivy__Status__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(3, jobQueues.size());
        
        Set<String> jobQueueGroups = new Set<String>();
        for (reduivy__Job_Queue__c jobQueue : jobQueues) {
            System.Assert.isNotNull(jobQueue.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');

            jobQueueGroups.add(jobQueue.reduivy__Job_Operation_Context__c + '_' + jobQueue.reduivy__Job_Queue_Group__c);
        }

        System.Assert.areEqual(2, jobQueueGroups.size());
    }

    /**
     * @description Test add job with invalid operation as admin
     */
    @IsTest
    static void testAddJobWithInvalidOperationAsAdmin(){
        
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
            flowRequest.jobOperationContext = 'Invalid_Job_Operation';
            flowRequest.jobOperation = 'Invalid_Job_Operation';
            flowRequest.paramsString = JQH_Helper.serializeParams(params);
            flowRequest.recordIds = new List<Id>(ienMaps.keySet());
            flowRequest.startWorker = true;

            //invoke the method
            List<JQH_AddJob_FLOW.Response> responses = JQH_AddJob_Flow.execute(new List<JQH_AddJob_FLOW.Request>{flowRequest});

            String expectedError = String.format(Label.Missing_Job_Queue_Config, new List<String>{flowRequest.jobOperation});
            System.Assert.areEqual(expectedError, responses.get(0).message);
            System.Assert.areEqual(JQH_JobManager.FAIL, responses.get(0).status);

        }

        Test.stopTest();
    }

    /**
     * @description Test add job with missing job operation context as admin
     */
    @IsTest
    static void testAddJobWithMissingJobOperationContextAsAdmin(){
        
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
            flowRequest.jobOperation = 'Sample_Job';
            flowRequest.paramsString = JQH_Helper.serializeParams(params);
            flowRequest.recordIds = new List<Id>(ienMaps.keySet());
            flowRequest.startWorker = true;

            //invoke the method
            List<JQH_AddJob_FLOW.Response> responses = JQH_AddJob_Flow.execute(new List<JQH_AddJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(Label.Missing_Job_Operation_Context, responses.get(0).message);
            System.Assert.areEqual(JQH_JobManager.FAIL, responses.get(0).status);
        }

        Test.stopTest();
    }
}