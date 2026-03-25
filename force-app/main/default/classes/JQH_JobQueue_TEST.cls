/**
 * @author      WDCi (Lean)
 * @date        Jan 2025
 * @group       Test
 * @description Test class for JQH_JobQueue_OBJ
 * @changehistory
 * ISS-002219 03-01-2025 Lean - new class
 * ISS-002547 15-07-2025 Lean - Added job group test
 */

@IsTest
public inherited sharing class JQH_JobQueue_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    @TestSetup
    static void makeData(){
        
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();

		System.runAs(ADMIN_USER) {

            testFactory.initMasterData(null);
            testFactory.initOfferingData(SOF_Helper.getApiName());
            testFactory.initStudentData(IEN_Helper.getApiName(), false);
        }
    }

    /**
     * @description Test job queue object methods
     */
    @IsTest
    static void testNormalJobQueueMethods(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        String operationName = 'Sample_Job';

        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, 'a0v9n000001iBFR');
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, 'Sample record name');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'sampleJobOperationContext');
        params.put(JQH_JobQueue_OBJ.PARAM_IS_RETRY, true);
        params.put(JQH_JobQueue_OBJ.PARAM_LAST_ATTEMPT_COUNT, 1);
        params.put(JQH_JobQueue_OBJ.PARAM_RETRY_ORIGIN_JOB_QUEUE_NO, 'JOB-XXXXX');
        params.put(JQH_JobQueue_OBJ.PARAM_HAS_CALLOUT, false);

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);

        List<Id> ienIds = new List<Id>(ienMaps.keySet());

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            reduivy__Job_Queue_Config__mdt jobConfig = JQH_Helper.getJobOperationSettings(operationName);

            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(operationName, ienIds, params);
            
            System.Assert.areEqual(false, job.getParams().isEmpty());
            System.Assert.areEqual(true, job.getSystemParams().isEmpty());
            System.Assert.areEqual(false, job.getJobParams().isEmpty());
            System.Assert.areEqual(8, job.getJobParams().keySet().size());

            System.Assert.areEqual(params.get(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID), job.getSourceRecordId());
            System.Assert.areEqual(params.get(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME), job.getSourceRecordName());
            System.Assert.areEqual(params.get(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT), job.getJobOperationContext());
            System.Assert.areEqual(params.get(JQH_JobQueue_OBJ.PARAM_IS_RETRY), job.isRetry());
            System.Assert.areEqual(params.get(JQH_JobQueue_OBJ.PARAM_LAST_ATTEMPT_COUNT), job.getLastAttemptCount());
            System.Assert.areEqual(params.get(JQH_JobQueue_OBJ.PARAM_RETRY_ORIGIN_JOB_QUEUE_NO), job.getRetryOriginJobNo());
            System.Assert.areEqual('reduivy.JQH_Sample_HANDLER', job.getJobHandler().getClassName());
            System.Assert.areEqual(true, String.isBlank(job.getSObject().Id));
            System.Assert.areEqual(jobConfig.DeveloperName, job.getJobConfig().DeveloperName);
            System.Assert.areEqual(jobConfig.reduivy__Job_Handler_Batch_Size__c, job.getBatchSize());
            System.Assert.isTrue(ienMaps.keySet().containsAll(job.getRecordIds()));
            System.Assert.areEqual('Enrolled', job.getJobParams().get('enrollmentStatus'));
            System.Assert.areEqual(false, job.hasCallout());
            System.Assert.areEqual(true, job.isExecutable());

            //assert job queue for job via initNewJob
            reduivy__Job_Queue_Group__c jobQueueGroup1 = REDU_TestData_UTIL.newJobQueueGroup('sameJobOperationContext1', 'sameJobOperationContext1');
            REDU_Database_UTIL.doInsert(new List<reduivy__Job_Queue_Group__c>{jobQueueGroup1});

            job.setJobQueueGroupId(jobQueueGroup1.Id);
            System.Assert.areEqual(jobQueueGroup1.Id, job.getJobQueueGroupId());

            //assert job queue for job via JQH_JobQueue_OBJ initiation
            reduivy__Job_Queue_Group__c jobQueueGroup2 = REDU_TestData_UTIL.newJobQueueGroup('sameJobOperationContext2', 'sameJobOperationContext2');
            REDU_Database_UTIL.doInsert(new List<reduivy__Job_Queue_Group__c>{jobQueueGroup2});

            reduivy__Job_Queue__c sampleJob1 = REDU_TestData_UTIL.newJobQueue(
                'SAMPLE_JOB_1',
                jobQueueGroup2.Id,
                'SAMPLE_JOB_1',
                'Sample_Job',
                'JQH_Sample_HANDLER',
                JQH_Helper.serializeParams(params),
                JQH_Helper.serializeRecordIds(ienIds),
                null,
                null,
                null,
                null,
                JQH_Helper.STATUS_PENDING
            );

            JQH_JobQueue_OBJ jobViaJobQueue = new JQH_JobQueue_OBJ(sampleJob1);

            System.Assert.areEqual(jobQueueGroup2.Id, jobViaJobQueue.getJobQueueGroupId());
        }

        Test.stopTest();
        
    }
}