/**
 * @author      WDCi (Lean)
 * @date        Jan 2025
 * @group       Test
 * @description Test class for JQH_RetryJob_FLOW
 * @changehistory
 * ISS-002219 03-01-2025 Lean - new class
 * ISS-002547 15-07-2025 Lean - Added job group test
 */

@IsTest
public inherited sharing class JQH_RetryJob_TEST {
    
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
     * @description Test retry a failed/completed job with all records
     */
    @IsTest
    static void testRetryFailedJobWithAllRecordsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, false);
        }

        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.Name FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        jobQueue.reduivy__Status__c = JQH_Helper.STATUS_FAILED;

        REDU_Database_UTIL.doUpdate(new List<reduivy__Job_Queue__c>{jobQueue});

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobManager.clearJobQueueGroupsOperationContextCache();

            //simulate the data from flow
            JQH_RetryJob_FLOW.Request flowRequest = new JQH_RetryJob_FLOW.Request();
            flowRequest.jobQueueId = jobQueue.Id;
            flowRequest.retryAllRecords = true;
            flowRequest.startWorker = true;

            //invoke the method
            List<JQH_RetryJob_FLOW.Response> responses = JQH_RetryJob_FLOW.execute(new List<JQH_RetryJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
            System.Assert.areEqual(Label.Job_Queue_Was_Submitted_For_Retry, responses.get(0).message);

        }

        Test.stopTest();
        
        reduivy__Job_Queue__c retryJobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Origin_Job_Queue_ID__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.Name FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job' AND reduivy__Origin_Job_Queue_ID__c =: jobQueue.Name];

        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, retryJobQueue.reduivy__Status__c);
        System.Assert.areEqual(jobQueue.reduivy__Job_Handler_Record_Ids__c, retryJobQueue.reduivy__Job_Handler_Record_Ids__c);
        System.Assert.areNotEqual(jobQueue.reduivy__Job_Queue_Group__c, retryJobQueue.reduivy__Job_Queue_Group__c);
    }

    /**
     * @description Test retry a failed/completed job queue with all records
     */
    @IsTest
    static void testRetryFailedJobQueueGroupWithAllRecordsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, false);
        }

        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.Name FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        jobQueue.reduivy__Status__c = JQH_Helper.STATUS_FAILED;

        REDU_Database_UTIL.doUpdate(new List<reduivy__Job_Queue__c>{jobQueue});

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobManager.clearJobQueueGroupsOperationContextCache();

            //simulate the data from flow
            JQH_RetryJob_FLOW.Request flowRequest = new JQH_RetryJob_FLOW.Request();
            flowRequest.jobQueueId = jobQueue.reduivy__Job_Queue_Group__c;
            flowRequest.retryAllRecords = true;
            flowRequest.startWorker = true;

            //invoke the method
            List<JQH_RetryJob_FLOW.Response> responses = JQH_RetryJob_FLOW.execute(new List<JQH_RetryJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
            System.Assert.areEqual(Label.Job_Queue_Was_Submitted_For_Retry, responses.get(0).message);

        }

        Test.stopTest();
        
        reduivy__Job_Queue__c retryJobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Origin_Job_Queue_ID__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.Name FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job' AND reduivy__Origin_Job_Queue_ID__c =: jobQueue.Name];

        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, retryJobQueue.reduivy__Status__c);
        System.Assert.areEqual(jobQueue.reduivy__Job_Handler_Record_Ids__c, retryJobQueue.reduivy__Job_Handler_Record_Ids__c);
        System.Assert.areNotEqual(jobQueue.reduivy__Job_Queue_Group__c, retryJobQueue.reduivy__Job_Queue_Group__c);
    }

    /**
     * @description Test retry a failed/completed job with error records
     */
    @IsTest
    static void testRetryFailedJobWithErrorRecordsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, false);
        }

        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.Name FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        jobQueue.reduivy__Status__c = JQH_Helper.STATUS_FAILED;
        jobQueue.reduivy__Job_Handler_Error_Record_Ids__c = JQH_Helper.serializeRecordIds(new List<Id>{ienMaps.values().get(0).Id, ienMaps.values().get(0).Id});

        REDU_Database_UTIL.doUpdate(new List<reduivy__Job_Queue__c>{jobQueue});

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobManager.clearJobQueueGroupsOperationContextCache();

            //simulate the data from flow
            JQH_RetryJob_FLOW.Request flowRequest = new JQH_RetryJob_FLOW.Request();
            flowRequest.jobQueueId = jobQueue.Id;
            flowRequest.retryAllRecords = false;
            flowRequest.startWorker = true;

            //invoke the method
            List<JQH_RetryJob_FLOW.Response> responses = JQH_RetryJob_FLOW.execute(new List<JQH_RetryJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
            System.Assert.areEqual(Label.Job_Queue_Was_Submitted_For_Retry, responses.get(0).message);
        }

        Test.stopTest();
        
        reduivy__Job_Queue__c retryJobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Origin_Job_Queue_ID__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.Name FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job' AND reduivy__Origin_Job_Queue_ID__c =: jobQueue.Name];

        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, retryJobQueue.reduivy__Status__c);
        System.Assert.areEqual(jobQueue.reduivy__Job_Handler_Error_Record_Ids__c, retryJobQueue.reduivy__Job_Handler_Record_Ids__c);
        System.Assert.areEqual(jobQueue.reduivy__Number_of_Attempts__c + 1, retryJobQueue.reduivy__Number_of_Attempts__c);
        System.Assert.areNotEqual(jobQueue.reduivy__Job_Queue_Group__c, retryJobQueue.reduivy__Job_Queue_Group__c);

    }

    /**
     * @description Test retry a failed/completed job queue group with error records
     */
    @IsTest
    static void testRetryFailedJobQueueGroupWithErrorRecordsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, false);
        }

        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.Name FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        jobQueue.reduivy__Status__c = JQH_Helper.STATUS_FAILED;
        jobQueue.reduivy__Job_Handler_Error_Record_Ids__c = JQH_Helper.serializeRecordIds(new List<Id>{ienMaps.values().get(0).Id, ienMaps.values().get(0).Id});

        REDU_Database_UTIL.doUpdate(new List<reduivy__Job_Queue__c>{jobQueue});

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobManager.clearJobQueueGroupsOperationContextCache();

            //simulate the data from flow
            JQH_RetryJob_FLOW.Request flowRequest = new JQH_RetryJob_FLOW.Request();
            flowRequest.jobQueueId = jobQueue.reduivy__Job_Queue_Group__c;
            flowRequest.retryAllRecords = false;
            flowRequest.startWorker = true;

            //invoke the method
            List<JQH_RetryJob_FLOW.Response> responses = JQH_RetryJob_FLOW.execute(new List<JQH_RetryJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
            System.Assert.areEqual(Label.Job_Queue_Was_Submitted_For_Retry, responses.get(0).message);
        }

        Test.stopTest();
        
        reduivy__Job_Queue__c retryJobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Origin_Job_Queue_ID__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.Name FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job' AND reduivy__Origin_Job_Queue_ID__c =: jobQueue.Name];

        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, retryJobQueue.reduivy__Status__c);
        System.Assert.areEqual(jobQueue.reduivy__Job_Handler_Error_Record_Ids__c, retryJobQueue.reduivy__Job_Handler_Record_Ids__c);
        System.Assert.areEqual(jobQueue.reduivy__Number_of_Attempts__c + 1, retryJobQueue.reduivy__Number_of_Attempts__c);
        System.Assert.areNotEqual(jobQueue.reduivy__Job_Queue_Group__c, retryJobQueue.reduivy__Job_Queue_Group__c);

    }

    /**
     * @description Test retry a pending job as admin
     */
    @IsTest
    static void testRetryPendingJobAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, false);
        }

        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.Name FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobManager.clearJobQueueGroupsOperationContextCache();

            //simulate the data from flow
            JQH_RetryJob_FLOW.Request flowRequest = new JQH_RetryJob_FLOW.Request();
            flowRequest.jobQueueId = jobQueue.Id;
            flowRequest.retryAllRecords = true;
            flowRequest.startWorker = true;

            //invoke the method
            List<JQH_RetryJob_FLOW.Response> responses = JQH_RetryJob_FLOW.execute(new List<JQH_RetryJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(JQH_JobManager.FAIL, responses.get(0).status);
            String expextedError = String.format(Label.Job_Queue_Cannot_Be_Retried, new List<String>{jobQueue.Name});
            System.Assert.areEqual(expextedError, responses.get(0).message);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test retry a pending job queue group as admin
     */
    @IsTest
    static void testRetryPendingJobQueueGroupAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, false);
        }

        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.Name FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobManager.clearJobQueueGroupsOperationContextCache();

            //simulate the data from flow
            JQH_RetryJob_FLOW.Request flowRequest = new JQH_RetryJob_FLOW.Request();
            flowRequest.jobQueueId = jobQueue.reduivy__Job_Queue_Group__c;
            flowRequest.retryAllRecords = true;
            flowRequest.startWorker = true;

            //invoke the method
            List<JQH_RetryJob_FLOW.Response> responses = JQH_RetryJob_FLOW.execute(new List<JQH_RetryJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(JQH_JobManager.FAIL, responses.get(0).status);
            String expextedError = String.format(Label.Job_Queue_Cannot_Be_Retried, new List<String>{jobQueue.reduivy__Job_Queue_Group__r.Name});
            System.Assert.areEqual(expextedError, responses.get(0).message);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test retry a processing job as admin
     */
    @IsTest
    static void testRetryProcessingJobAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, false);
        }

        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.Name FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        jobQueue.reduivy__Status__c = JQH_Helper.STATUS_PROCESSING;
        
        REDU_Database_UTIL.doUpdate(new List<reduivy__Job_Queue__c>{jobQueue});

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobManager.clearJobQueueGroupsOperationContextCache();

            //simulate the data from flow
            JQH_RetryJob_FLOW.Request flowRequest = new JQH_RetryJob_FLOW.Request();
            flowRequest.jobQueueId = jobQueue.Id;
            flowRequest.retryAllRecords = true;
            flowRequest.startWorker = true;

            //invoke the method
            List<JQH_RetryJob_FLOW.Response> responses = JQH_RetryJob_FLOW.execute(new List<JQH_RetryJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(JQH_JobManager.FAIL, responses.get(0).status);
            String expextedError = String.format(Label.Job_Queue_Cannot_Be_Retried, new List<String>{jobQueue.Name});
            System.Assert.areEqual(expextedError, responses.get(0).message);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test retry a processing job queue group as admin
     */
    @IsTest
    static void testRetryProcessingJobQueueGroupAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, false);
        }

        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.Name FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        jobQueue.reduivy__Status__c = JQH_Helper.STATUS_PROCESSING;
        
        REDU_Database_UTIL.doUpdate(new List<reduivy__Job_Queue__c>{jobQueue});

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobManager.clearJobQueueGroupsOperationContextCache();

            //simulate the data from flow
            JQH_RetryJob_FLOW.Request flowRequest = new JQH_RetryJob_FLOW.Request();
            flowRequest.jobQueueId = jobQueue.reduivy__Job_Queue_Group__c;
            flowRequest.retryAllRecords = true;
            flowRequest.startWorker = true;

            //invoke the method
            List<JQH_RetryJob_FLOW.Response> responses = JQH_RetryJob_FLOW.execute(new List<JQH_RetryJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(JQH_JobManager.FAIL, responses.get(0).status);
            String expextedError = String.format(Label.Job_Queue_Cannot_Be_Retried, new List<String>{jobQueue.reduivy__Job_Queue_Group__r.Name});
            System.Assert.areEqual(expextedError, responses.get(0).message);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test retry an invalid job as admin
     */
    @IsTest
    static void testRetryInvalidJobAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){

            //simulate the data from flow
            JQH_RetryJob_FLOW.Request flowRequest = new JQH_RetryJob_FLOW.Request();
            flowRequest.jobQueueId = 'a0v9n000001iBFRAA2';
            flowRequest.retryAllRecords = true;
            flowRequest.startWorker = true;

            //invoke the method
            List<JQH_RetryJob_FLOW.Response> responses = JQH_RetryJob_FLOW.execute(new List<JQH_RetryJob_FLOW.Request>{flowRequest});

            System.Assert.areEqual(JQH_JobManager.FAIL, responses.get(0).status);
            String expextedError = String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{flowRequest.jobQueueId, JQG_Helper.getObjectLabel() + '/' + JQH_Helper.getObjectLabel()});
            System.Assert.areEqual(expextedError, responses.get(0).message);
        }

        Test.stopTest();
    }
}