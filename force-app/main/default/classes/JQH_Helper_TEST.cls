/**
 * @author      WDCi (Lean)
 * @date        Jan 2025
 * @group       Test
 * @description Test class for JQH_Helper
 * @changehistory
 * ISS-002219 02-01-2025 Lean - new class
 * ISS-002547 14-07-2025 Lean - Added job group test
 */
@IsTest
public inherited sharing class JQH_Helper_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    static Map<String, Object> SAMPLE_PARAMS = new Map<String, Object>();
    static {
        SAMPLE_PARAMS.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, 'a0v9n000001iBFR');
        SAMPLE_PARAMS.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, 'Sample record name');
        SAMPLE_PARAMS.put(JQH_JobQueue_OBJ.PARAM_IS_RETRY, true);
        SAMPLE_PARAMS.put(JQH_JobQueue_OBJ.PARAM_LAST_ATTEMPT_COUNT, 1);
        SAMPLE_PARAMS.put(JQH_JobQueue_OBJ.PARAM_RETRY_ORIGIN_JOB_QUEUE_NO, 'JOB-XXXXX');
        SAMPLE_PARAMS.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'sampleJobOperationContext');
    }

    static List<Id> SAMPLE_RECORD_IDS = new List<Id>{'0019n00000SLfS7AAL', '0019n00000SLfSDAA1'};

    @TestSetup
    static void makeData(){
        
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
        Id sysAdminUserId = UserInfo.getUserId();

        String params = JQH_Helper.serializeParams(SAMPLE_PARAMS);
        String recordIds = JQH_Helper.serializeRecordIds(SAMPLE_RECORD_IDS);

		System.runAs(ADMIN_USER) {
            Test.startTest();            

            reduivy__Job_Queue_Group__c jobQueueGroup1 = REDU_TestData_UTIL.newJobQueueGroup('SAMPLE_JOB_1', 'SAMPLE_JOB_1');
            reduivy__Job_Queue_Group__c jobQueueGroup2 = REDU_TestData_UTIL.newJobQueueGroup('SAMPLE_JOB_2', 'SAMPLE_JOB_2');
            reduivy__Job_Queue_Group__c jobQueueGroup3 = REDU_TestData_UTIL.newJobQueueGroup('SAMPLE_JOB_3', 'SAMPLE_JOB_3');
            reduivy__Job_Queue_Group__c jobQueueGroup4 = REDU_TestData_UTIL.newJobQueueGroup('SAMPLE_JOB_4', 'SAMPLE_JOB_4');
            
            REDU_Database_UTIL.doInsert(new List<reduivy__Job_Queue_Group__c>{jobQueueGroup1, jobQueueGroup2, jobQueueGroup3, jobQueueGroup4});

            reduivy__Job_Queue__c sampleJob1 = REDU_TestData_UTIL.newJobQueue(
                'SAMPLE_JOB_1',
                jobQueueGroup1.Id,
                'SAMPLE_JOB_1',
                'Sample_Job',
                'JQH_Sample_HANDLER',
                params,
                recordIds,
                null,
                null,
                null,
                null,
                JQH_Helper.STATUS_PENDING
            );

            reduivy__Job_Queue__c sampleJob2 = REDU_TestData_UTIL.newJobQueue(
                'SAMPLE_JOB_2',
                jobQueueGroup2.Id,
                'SAMPLE_JOB_2',
                'Sample_Job',
                'JQH_Sample_HANDLER',
                params,
                recordIds,
                null,
                null,
                null,
                null,
                JQH_Helper.STATUS_PENDING
            );

            reduivy__Job_Queue__c sampleJob3 = REDU_TestData_UTIL.newJobQueue(
                'SAMPLE_JOB_3',
                jobQueueGroup3.Id,
                'SAMPLE_JOB_3',
                'Sample_Job',
                'JQH_Sample_HANDLER',
                params,
                recordIds,
                null,
                null,
                null,
                null,
                JQH_Helper.STATUS_PENDING
            );

            sampleJob3.OwnerId = sysAdminUserId;

            reduivy__Job_Queue__c sampleJob4 = REDU_TestData_UTIL.newJobQueue(
                'SAMPLE_JOB_4',
                jobQueueGroup4.Id,
                'SAMPLE_JOB_4',
                'Sample_Job',
                'JQH_Sample_HANDLER',
                params,
                recordIds,
                null,
                null,
                null,
                null,
                JQH_Helper.STATUS_PENDING
            );

            sampleJob4.OwnerId = sysAdminUserId;

            REDU_Database_UTIL.doInsert(new List<reduivy__Job_Queue__c>{sampleJob1, sampleJob2, sampleJob3, sampleJob4});

            Test.stopTest();
        }
    }

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Job_Queue__c.getLabel(), JQH_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Job_Queue__c.getLabelPlural(), JQH_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Job_Queue__c.getName(), JQH_Helper.getApiName());

        Test.stopTest();
        
    }

    /**
     * @description Test getPendingJobsForUser() as admin
     */
    @IsTest
    static void testGetPendingJobsForUserAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        //Test as admin user, this should have existing jobs in the queue
        System.runAs(ADMIN_USER){
            List<reduivy__Job_Queue__c> jobQueues = JQH_Helper.getPendingJobsForUser(ADMIN_USER.Id);

            System.Assert.areEqual(2, jobQueues.size());

            for (reduivy__Job_Queue__c jobQueue : jobQueues) {
                System.Assert.areEqual(ADMIN_USER.Id, jobQueue.OwnerId, 'The job owner is not the same.');
                System.Assert.areEqual(JQH_Helper.STATUS_PENDING, jobQueue.reduivy__Status__c, 'The job status is not pending.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test getPendingJobsForUser() as non permitted user
     */
    @IsTest
    static void testGetPendingJobsForUserAsNonPermittedUser(){
        
        USER SETUP_USER = testFactory.getSetupUser();

        Test.startTest();

        //Test as admin user, this should have existing jobs in the queue
        System.runAs(SETUP_USER){
            try {
            List<reduivy__Job_Queue__c> jobQueues = JQH_Helper.getPendingJobsForUser(SETUP_USER.Id);

            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s) - reduivy__Job_Queue__c'), 'Unexpected error: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test getNextJob() as admin
     */
    @IsTest
    static void testGetNextJobAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        //Test as admin user, this should have existing jobs in the queue
        System.runAs(ADMIN_USER){
            List<reduivy__Job_Queue__c> jobQueues = JQH_Helper.getPendingJobsForUser(ADMIN_USER.Id);

            reduivy__Job_Queue__c jobQueue = JQH_Helper.getNextJob();

            System.Assert.areEqual(jobQueues.get(0).Id, jobQueue.Id);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test isWorkerFree() as admin
     */
    @IsTest
    static void testIsWorkerFreeAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        System.Assert.areEqual(true, JQH_Helper.isWorkerFree());

        Test.stopTest();
        
    }

    /**
     * @description Test getJobOperationSettings() as admin
     */
    @IsTest
    static void testGetJobOperationSettingsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        String operationName = 'Sample_Job';

        Test.startTest();
        
        reduivy__Job_Queue_Config__mdt jobConfig = JQH_Helper.getJobOperationSettings(operationName);
        System.Assert.isNotNull(jobConfig);

        Test.stopTest();
        
    }

    /**
     * @description Test getJobOperationSettings() with invalid operation as admin
     */
    @IsTest
    static void testGetJobOperationSettingsWithInvalidOperationAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        String operationName = 'Invalid_Job_Operation';

        Test.startTest();
        
        try {
            reduivy__Job_Queue_Config__mdt jobConfig = JQH_Helper.getJobOperationSettings(operationName);
        } catch (Exception exp) {
            String message = String.format(Label.Missing_Job_Queue_Config, new List<String>{operationName});

            System.Assert.areEqual(message, exp.getMessage());
        }

        Test.stopTest();
        
    }

    /**
     * @description Test toJobObject() as admin
     */
    @IsTest
    static void testToJobObjectAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        String operationName = 'Sample_Job';

        Test.startTest();

        //Test as admin user, this should have existing jobs in the queue
        System.runAs(ADMIN_USER){
            reduivy__Job_Queue__c jobQueue = JQH_Helper.getNextJob();
            System.Assert.isNotNull(jobQueue);

            reduivy__Job_Queue_Config__mdt jobConfig = JQH_Helper.getJobOperationSettings(operationName);

            JQH_JobQueue_OBJ job = JQH_Helper.toJobObject(jobQueue);
            System.Assert.areEqual(SAMPLE_PARAMS.get(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID), job.getSourceRecordId());
            System.Assert.areEqual(SAMPLE_PARAMS.get(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME), job.getSourceRecordName());
            System.Assert.areEqual(SAMPLE_PARAMS.get(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT), job.getJobOperationContext());
            System.Assert.areEqual(SAMPLE_PARAMS.get(JQH_JobQueue_OBJ.PARAM_IS_RETRY), job.isRetry());
            System.Assert.areEqual(SAMPLE_PARAMS.get(JQH_JobQueue_OBJ.PARAM_LAST_ATTEMPT_COUNT), job.getLastAttemptCount());
            System.Assert.areEqual(SAMPLE_PARAMS.get(JQH_JobQueue_OBJ.PARAM_RETRY_ORIGIN_JOB_QUEUE_NO), job.getRetryOriginJobNo());
            System.Assert.areEqual(jobQueue.Id, job.getSObject().Id);
            System.Assert.areEqual('reduivy.JQH_Sample_HANDLER', job.getJobHandler().getClassName());
            System.Assert.areEqual(jobConfig.DeveloperName, job.getJobConfig().DeveloperName);
            System.Assert.areEqual(jobConfig.reduivy__Job_Handler_Batch_Size__c, job.getBatchSize());

            Set<Id> sampleRecordIdsSet = new Set<Id>(SAMPLE_RECORD_IDS);
            System.Assert.isTrue(sampleRecordIdsSet.containsAll(job.getRecordIds()));

            System.Assert.areEqual(false, job.getParams().isEmpty());
            System.Assert.areEqual(true, job.getSystemParams().isEmpty());
            System.Assert.areEqual(false, job.getJobParams().isEmpty());
            System.Assert.areEqual(6, job.getJobParams().keySet().size());
            System.Assert.areEqual(false, job.hasCallout());
            System.Assert.areEqual(true, job.isExecutable());

            System.Assert.isNotNull(job.getJobQueueGroupId(), 'The job queue should have a job queue group.');
            System.Assert.areEqual(jobQueue.reduivy__Job_Queue_Group__c, job.getJobQueueGroupId());
        }

        Test.stopTest();
        
    }

    /**
     * @Description Test deserializeRecordIds() as admin
     */
    @IsTest
    static void testdeserializeRecordIdsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        System.runAs(ADMIN_USER){
            List<Id> recordIds = JQH_Helper.deserializeRecordIds(JQH_Helper.serializeRecordIds(SAMPLE_RECORD_IDS));
            System.Assert.areEqual(2, recordIds.size());

            try {
                List<Id> invalidrecordIds = JQH_Helper.deserializeRecordIds('invalidid;invalidid');
            } catch (Exception exp) {
                String expectedError = String.format(Label.Error_Converting_String_To_Id, new List<String>{'invalidid;invalidid'});
                System.Assert.areEqual(expectedError, exp.getMessage());
            }
        }
        Test.stopTest();
        
    }

    /**
     * @Description Test deserializeParams() as admin
     */
    @IsTest
    static void testdeserializeParamsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        System.runAs(ADMIN_USER){
            Map<String, Object> params = JQH_Helper.deserializeParams(JQH_Helper.serializeParams(SAMPLE_PARAMS));
            System.Assert.areEqual(6, params.keySet().size());
        }
        Test.stopTest();
        
    }

    /**
     * @description Test getHandlerClass()
     */
    @IsTest
    static void testGetHandlerClassAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        System.runAs(ADMIN_USER){
            JQH_JobHandler jobHandler = JQH_Helper.getHandlerClass('reduivy.JQH_Sample_HANDLER');
            System.Assert.areEqual('reduivy.JQH_Sample_HANDLER', jobHandler.getClassName());

            try {
                JQH_JobHandler jobHandler2 = JQH_Helper.getHandlerClass(null);
            } catch (Exception exp) {
                String expectedError = Label.Missing_Job_Handler_Class_Name;
                System.Assert.areEqual(expectedError, exp.getMessage());
            }

            try {
                JQH_JobHandler jobHandler3 = JQH_Helper.getHandlerClass('Invalidclass');
            } catch (Exception exp) {
                String expectedError = String.format(Label.Error_Initializing_Job_Handler, new List<String>{'Invalidclass'});
                System.Assert.areEqual(expectedError, exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test getGeneratorClass()
     */
    @IsTest
    static void testGetGeneratorClassAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        System.runAs(ADMIN_USER){
            JQH_JobGenerator jobGenerator = JQH_Helper.getGeneratorClass('reduivy.JQH_Sample_GENERATOR');
            System.Assert.areEqual('reduivy.JQH_Sample_GENERATOR', jobGenerator.getClassName());

            try {
                JQH_JobGenerator jobGenerator2 = JQH_Helper.getGeneratorClass(null);
            } catch (Exception exp) {
                String expectedError = Label.Missing_Job_Generator_Class_Name;
                System.Assert.areEqual(expectedError, exp.getMessage());
            }

            try {
                JQH_JobGenerator jobGenerator3 = JQH_Helper.getGeneratorClass('Invalidclass');
            } catch (Exception exp) {
                String expectedError = String.format(Label.Error_Initializing_Job_Generator, new List<String>{'Invalidclass'});
                System.Assert.areEqual(expectedError, exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test getBatchedJobQueues() as admin
     */
    @IsTest
    static void testGetBatchedJobQueuesByAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        System.runAs(ADMIN_USER){
            
            List<Account> sampleAccounts = new List<Account>();
            for (Integer i = 0; i < 500; i ++) {
                Account acc = new Account(Name = 'Sample Account');
                sampleAccounts.add(acc);
            }

            REDU_TriggerController.muteAllTriggers();

            REDU_Database_UTIL.doInsert(sampleAccounts);
            
            REDU_TriggerController.unmuteAllTriggers();

            List<Id> accIds = new List<Id>();
            List<Id> allIds = new List<Id>();
            for (Account acc : sampleAccounts) {
                accIds.add(acc.Id);
                allIds.add(acc.Id);
            }

            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', accIds, null);

            List<reduivy__Job_Queue__c> jobQueues = JQH_Helper.getBatchedJobQueues(job);
            System.Assert.areEqual(5, jobQueues.size());

            List<List<Id>> pagedIds = REDU_List_UTIL.getPageIterable(allIds, job.getBatchSize());

            Integer counter = 0;
            for (reduivy__Job_Queue__c jobQueue : jobQueues) {
                System.Assert.areEqual(JQH_Helper.serializeRecordIds(pagedIds.get(counter)), jobQueue.reduivy__Job_Handler_Record_Ids__c);

                counter ++;
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test getBatchedJobQueues() with empty record ids as admin
     */
    @IsTest
    static void testGetBatchedJobQueuesWithoutRecordIdsByAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        System.runAs(ADMIN_USER){
            
            List<Id> accIds = new List<Id>();
            List<Id> emptyIds = new List<Id>();

            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', accIds, null);

            List<reduivy__Job_Queue__c> jobQueues = JQH_Helper.getBatchedJobQueues(job);
            System.Assert.areEqual(1, jobQueues.size());

            List<List<Id>> pagedIds = REDU_List_UTIL.getPageIterable(emptyIds, job.getBatchSize());

            Integer counter = 0;
            for (reduivy__Job_Queue__c jobQueue : jobQueues) {
                System.Assert.areEqual(true, String.isBlank(jobQueue.reduivy__Job_Handler_Record_Ids__c));

                counter ++;
            }

            System.Assert.areEqual(1, counter);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test job completed logging as admin
     */
    @IsTest
    static void testJobCompletedLoggingAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        System.runAs(ADMIN_USER){
            reduivy__Job_Queue__c jobQueue = JQH_Helper.getNextJob();

            JQH_Helper.jobStarted(jobQueue);

            reduivy__Job_Queue__c startedJob = [SELECT Id, 
                reduivy__Status__c, 
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Job_Handler_Error_Record_Ids__c
                FROM reduivy__Job_Queue__c
                WHERE Id =: jobQueue.Id
                WITH USER_MODE
            ];

            System.Assert.areEqual(JQH_Helper.STATUS_PROCESSING, startedJob.reduivy__Status__c);
            System.Assert.isNotNull(startedJob.reduivy__Start_Datetime__c, 'The start datetime should be populated.');
            System.Assert.isNull(startedJob.reduivy__End_Datetime__c, 'The end datetime should not be populated.');
            System.Assert.isTrue(String.isBlank(startedJob.reduivy__Job_Handler_Error_Record_Ids__c), 'The error record ids should be blank.');

            JQH_JobManager.HandlerResult results = new JQH_JobManager.HandlerResult();
            results.addSuccessResult('0019n00000SLfS7AAL', 'The success message.');
            results.addSuccessResult('0019n00000SLfSDAA1', 'The success message.');

            JQH_Helper.jobCompleted(jobQueue, results);

            reduivy__Job_Queue__c completedJob = [SELECT Id, 
                reduivy__Status__c, 
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Job_Handler_Error_Record_Ids__c,
                reduivy__Job_Handler_Success_Record_Ids__c,
                reduivy__Job_Handler_Warning_Record_Ids__c
                FROM reduivy__Job_Queue__c
                WHERE Id =: jobQueue.Id
                WITH USER_MODE
            ];

            System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, completedJob.reduivy__Status__c);
            System.Assert.isNotNull(completedJob.reduivy__Start_Datetime__c, 'The start datetime should be populated.');
            System.Assert.isNotNull(completedJob.reduivy__End_Datetime__c, 'The end datetime should be populated.');
            System.Assert.isTrue(String.isBlank(completedJob.reduivy__Job_Handler_Error_Record_Ids__c), 'The error record ids should be blank.');
            System.Assert.isTrue(String.isBlank(completedJob.reduivy__Job_Handler_Warning_Record_Ids__c), 'The warning record ids should be blank.');
            System.Assert.isTrue(String.isNotBlank(completedJob.reduivy__Job_Handler_Success_Record_Ids__c), 'The success record ids should not be blank.');
            System.Assert.areEqual('0019n00000SLfS7AAL;0019n00000SLfSDAA1', completedJob.reduivy__Job_Handler_Success_Record_Ids__c);
        }
        
        Test.stopTest();
        
    }

    /**
     * @description Test job completed with error logging as admin
     */
    @IsTest
    static void testJobCompletedWithErrorLoggingAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        System.runAs(ADMIN_USER){
            reduivy__Job_Queue__c jobQueue = JQH_Helper.getNextJob();

            JQH_Helper.jobStarted(jobQueue);

            reduivy__Job_Queue__c startedJob = [SELECT Id, 
                reduivy__Status__c, 
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Job_Handler_Error_Record_Ids__c
                FROM reduivy__Job_Queue__c
                WHERE Id =: jobQueue.Id
                WITH USER_MODE
            ];

            System.Assert.areEqual(JQH_Helper.STATUS_PROCESSING, startedJob.reduivy__Status__c);
            System.Assert.isNotNull(startedJob.reduivy__Start_Datetime__c, 'The start datetime should be populated.');
            System.Assert.isNull(startedJob.reduivy__End_Datetime__c, 'The end datetime should not be populated.');
            System.Assert.isTrue(String.isBlank(startedJob.reduivy__Job_Handler_Error_Record_Ids__c), 'The error record ids should be blank.');

            JQH_JobManager.HandlerResult results = new JQH_JobManager.HandlerResult();
            results.addFailResult('0019n00000SLfS7AAL', 'The error message.');
            results.addFailResult('0019n00000SLfSDAA1', 'The error message.');

            JQH_Helper.jobCompleted(jobQueue, results);

            reduivy__Job_Queue__c completedJob = [SELECT Id, 
                reduivy__Status__c, 
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Job_Handler_Error_Record_Ids__c,
                reduivy__Job_Handler_Success_Record_Ids__c,
                reduivy__Job_Handler_Warning_Record_Ids__c
                FROM reduivy__Job_Queue__c
                WHERE Id =: jobQueue.Id
                WITH USER_MODE
            ];

            System.Assert.areEqual(JQH_Helper.STATUS_FAILED, completedJob.reduivy__Status__c);
            System.Assert.isNotNull(completedJob.reduivy__Start_Datetime__c, 'The start datetime should be populated.');
            System.Assert.isNotNull(completedJob.reduivy__End_Datetime__c, 'The end datetime should be populated.');
            System.Assert.isTrue(String.isBlank(completedJob.reduivy__Job_Handler_Success_Record_Ids__c), 'The success record ids should be blank.');
            System.Assert.isTrue(String.isBlank(completedJob.reduivy__Job_Handler_Warning_Record_Ids__c), 'The warning record ids should be blank.');
            System.Assert.isTrue(String.isNotBlank(completedJob.reduivy__Job_Handler_Error_Record_Ids__c), 'The error record ids should not be blank.');
            System.Assert.areEqual('0019n00000SLfS7AAL;0019n00000SLfSDAA1', completedJob.reduivy__Job_Handler_Error_Record_Ids__c);
        }
        
        Test.stopTest();
        
    }

    /**
     * @description Test job completed with warning logging as admin
     */
    @IsTest
    static void testJobCompletedWithWarningLoggingAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        System.runAs(ADMIN_USER){
            reduivy__Job_Queue__c jobQueue = JQH_Helper.getNextJob();

            JQH_Helper.jobStarted(jobQueue);

            reduivy__Job_Queue__c startedJob = [SELECT Id, 
                reduivy__Status__c, 
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Job_Handler_Warning_Record_Ids__c
                FROM reduivy__Job_Queue__c
                WHERE Id =: jobQueue.Id
                WITH USER_MODE
            ];

            System.Assert.areEqual(JQH_Helper.STATUS_PROCESSING, startedJob.reduivy__Status__c);
            System.Assert.isNotNull(startedJob.reduivy__Start_Datetime__c, 'The start datetime should be populated.');
            System.Assert.isNull(startedJob.reduivy__End_Datetime__c, 'The end datetime should not be populated.');
            System.Assert.isTrue(String.isBlank(startedJob.reduivy__Job_Handler_Warning_Record_Ids__c), 'The error record ids should be blank.');

            JQH_JobManager.HandlerResult results = new JQH_JobManager.HandlerResult();
            results.addWarningResult('0019n00000SLfS7AAL', 'The warning message.');
            results.addWarningResult('0019n00000SLfSDAA1', 'The warning message.');

            JQH_Helper.jobCompleted(jobQueue, results);

            reduivy__Job_Queue__c completedJob = [SELECT Id, 
                reduivy__Status__c, 
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Job_Handler_Warning_Record_Ids__c,
                reduivy__Job_Handler_Success_Record_Ids__c,
                reduivy__Job_Handler_Error_Record_Ids__c
                FROM reduivy__Job_Queue__c
                WHERE Id =: jobQueue.Id
                WITH USER_MODE
            ];

            System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, completedJob.reduivy__Status__c);
            System.Assert.isNotNull(completedJob.reduivy__Start_Datetime__c, 'The start datetime should be populated.');
            System.Assert.isNotNull(completedJob.reduivy__End_Datetime__c, 'The end datetime should be populated.');
            System.Assert.isTrue(String.isBlank(completedJob.reduivy__Job_Handler_Success_Record_Ids__c), 'The success record ids should be blank.');
            System.Assert.isTrue(String.isBlank(completedJob.reduivy__Job_Handler_Error_Record_Ids__c), 'The error record ids should be blank.');
            System.Assert.isTrue(String.isNotBlank(completedJob.reduivy__Job_Handler_Warning_Record_Ids__c), 'The warning record ids should not be blank.');
            System.Assert.areEqual('0019n00000SLfS7AAL;0019n00000SLfSDAA1', completedJob.reduivy__Job_Handler_Warning_Record_Ids__c);
        }
        
        Test.stopTest();
        
    }

    /**
     * @description Test log linkage as admin
     */
    @IsTest
    static void testLogLinkageAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        System.runAs(ADMIN_USER){
            reduivy__Job_Queue__c jobQueue = JQH_Helper.getNextJob();

            reduivy__Log__c log = REDU_TestData_UTIL.newLog('Test', null, null, 'Test', null, null);

            System.Assert.areEqual(null, log.reduivy__Job_Queue_Group__c);
            System.Assert.areEqual(null, log.reduivy__Job_Queue__c);

            JQH_Helper.linkLogToJobs(log, jobQueue);

            System.Assert.areEqual(jobQueue.reduivy__Job_Queue_Group__c, log.reduivy__Job_Queue_Group__c);
            System.Assert.areEqual(jobQueue.Id, log.reduivy__Job_Queue__c);
        }
        
        Test.stopTest();
        
    }
}