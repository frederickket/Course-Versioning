/**
 * @author      WDCi (Lean)
 * @date        Jan 2025
 * @group       Test
 * @description Test class for JQH_JobManager
 * @changehistory
 * ISS-002219 02-01-2025 Lean - new class
 * ISS-002547 14-07-2025 Lean - Added job group test
 */
@IsTest
public inherited sharing class JQH_JobManager_TEST {
    
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
     * @description Test execute generator as admin
     */
    @IsTest
    static void testExecuteGeneratorWithWorkerAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Study_Offering__c> softMaps = new Map<Id, reduivy__Study_Offering__c>([
            SELECT Id 
            FROM reduivy__Study_Offering__c
        ]);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobManager.executeJobGenerator('Sample_Job', new List<Id>(softMaps.keySet()), params, true);
        }

        Test.stopTest();

        Integer generatorJobCount = [SELECT COUNT() 
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            AND ApexClass.Name = 'JQH_JobGenerator_QUEUE'
            AND Status = 'Completed'
            AND CreatedById =: ADMIN_USER.Id
            WITH USER_MODE
        ];

        System.Assert.areEqual(1, generatorJobCount);
    }

    /**
     * @description Test execute generator without starting the worker as admin
     */
    @IsTest
    static void testExecuteGeneratorWithoutWorkerAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Study_Offering__c> softMaps = new Map<Id, reduivy__Study_Offering__c>([
            SELECT Id 
            FROM reduivy__Study_Offering__c
        ]);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobManager.executeJobGenerator('Sample_Job', new List<Id>(softMaps.keySet()), params, false);
        }

        Test.stopTest();

        Integer generatorJobCount = [SELECT COUNT() 
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            AND ApexClass.Name = 'JQH_JobGenerator_QUEUE'
            AND Status = 'Completed'
            AND CreatedById =: ADMIN_USER.Id
            WITH USER_MODE
        ];

        System.Assert.areEqual(1, generatorJobCount);
    }

    /**
     * @description Test execute generator with invalid operation as admin
     */
    @IsTest
    static void testExecuteGeneratorWithInvalidOperationAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Study_Offering__c> softMaps = new Map<Id, reduivy__Study_Offering__c>([
            SELECT Id 
            FROM reduivy__Study_Offering__c
        ]);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            try {
                JQH_JobManager.executeJobGenerator('Invalid_Job_Operation', new List<Id>(softMaps.keySet()), params, false);
            } catch (Exception exp) {
                String expectedError = String.format(Label.Missing_Job_Queue_Config, new List<String>{'Invalid_Job_Operation'});
                System.Assert.areEqual(expectedError, exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test execute generator with missing generator class as admin
     */
    @IsTest
    static void testExecuteGeneratorWithMissingGeneratorClassAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Study_Offering__c> softMaps = new Map<Id, reduivy__Study_Offering__c>([
            SELECT Id 
            FROM reduivy__Study_Offering__c
        ]);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            try {
                JQH_JobManager.executeJobGenerator('Sample_Error_Job', new List<Id>(softMaps.keySet()), params, false);
            } catch (Exception exp) {
                String expectedError = Label.Missing_Job_Generator_Class_Name;
                System.Assert.areEqual(expectedError, exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test execute generator with job operation context as admin
     */
    @IsTest
    static void testExecuteGeneratorWithMissingJobOperationContextAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        
        Map<Id, reduivy__Study_Offering__c> softMaps = new Map<Id, reduivy__Study_Offering__c>([
            SELECT Id 
            FROM reduivy__Study_Offering__c
        ]);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            try {
                JQH_JobManager.executeJobGenerator('Sample_Job', new List<Id>(softMaps.keySet()), params, false);
            } catch (Exception exp) {
                String expectedError = Label.Missing_Job_Operation_Context;
                System.Assert.areEqual(expectedError, exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test add job as admin
     */
    @IsTest
    static void testAddJobWithWorkerAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);  

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, true);
        }

        Test.stopTest();
        
        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, jobQueue.reduivy__Status__c);
        System.Assert.isNotNull(jobQueue.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areEqual(JQG_Helper.STATUS_COMPLETED, jobQueue.reduivy__Job_Queue_Group__r.reduivy__Status__c);
    }

    /**
     * @description Test add multiple jobs as admin, the jobs that have the same operation context should be grouped under the same job queue group
     */
    @IsTest
    static void testAddMultipleJobsWithWorkerAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params1 = new Map<String, Object>();
        params1.put('enrollmentStatus', 'Enrolled');
        params1.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job_1');

        Map<String, Object> params2 = new Map<String, Object>();
        params2.put('enrollmentStatus', 'Enrolled');
        params2.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job_2');

        Map<String, Object> params3 = new Map<String, Object>();
        params3.put('enrollmentStatus', 'Enrolled');
        params3.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job_2');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);  

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job1 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params1);
            JQH_JobQueue_OBJ job2 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params2);
            JQH_JobQueue_OBJ job3 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params3);
            JQH_JobManager.queueJobs(new List<JQH_JobQueue_OBJ>{job1, job2, job3}, true);
        }

        Test.stopTest();
        
        List<reduivy__Job_Queue__c> jobQueues = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Job_Operation_Context__c, reduivy__Status__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job' ORDER BY CreatedDate];
        System.Assert.isFalse(jobQueues.isEmpty(), 'There should be jobs in the queue.');
        System.Assert.areEqual(3, jobQueues.size());
        
        Integer counter = 0;
        Set<String> jobQueueGroups = new Set<String>();
        for (reduivy__Job_Queue__c jobQueue : jobQueues) {
            System.Assert.isNotNull(jobQueue.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
            jobQueueGroups.add(jobQueue.reduivy__Job_Operation_Context__c + '_' + jobQueue.reduivy__Job_Queue_Group__c);

            if (counter == 0) {
                System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, jobQueue.reduivy__Status__c);
                System.Assert.areEqual(JQG_Helper.STATUS_COMPLETED, jobQueue.reduivy__Job_Queue_Group__r.reduivy__Status__c);
            } else {
                System.Assert.areEqual(JQH_Helper.STATUS_PENDING, jobQueue.reduivy__Status__c);
                System.Assert.areEqual(JQG_Helper.STATUS_PENDING, jobQueue.reduivy__Job_Queue_Group__r.reduivy__Status__c);
            }

            counter ++;
        }

        System.Assert.areEqual(2, jobQueueGroups.size());
    }

    /**
     * @description Test add job without starting the worker as admin
     */
    @IsTest
    static void testAddJobWithoutWorkerAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);  

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, false);
        }

        Test.stopTest();
        
        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(JQH_Helper.STATUS_PENDING, jobQueue.reduivy__Status__c);
        System.Assert.isNotNull(jobQueue.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areEqual(JQG_Helper.STATUS_PENDING, jobQueue.reduivy__Job_Queue_Group__r.reduivy__Status__c);
    }

    /**
     * @description Test add multiple jobs without as admin
     */
    @IsTest
    static void testAddMultipleJobsWithoutWorkerAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params1 = new Map<String, Object>();
        params1.put('enrollmentStatus', 'Enrolled');
        params1.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job_1');

        Map<String, Object> params2 = new Map<String, Object>();
        params2.put('enrollmentStatus', 'Enrolled');
        params2.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job_2');

        Map<String, Object> params3 = new Map<String, Object>();
        params3.put('enrollmentStatus', 'Enrolled');
        params3.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job_2');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);  

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job1 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params1);
            JQH_JobQueue_OBJ job2 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params2);
            JQH_JobQueue_OBJ job3 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params3);
            JQH_JobManager.queueJobs(new List<JQH_JobQueue_OBJ>{job1, job2, job3}, false);
        }

        Test.stopTest();
        
        List<reduivy__Job_Queue__c> jobQueues = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Job_Operation_Context__c, reduivy__Status__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job' ORDER BY CreatedDate];
        System.Assert.isFalse(jobQueues.isEmpty(), 'There should be jobs in the queue.');
        System.Assert.areEqual(3, jobQueues.size());
        
        Set<String> jobQueueGroups = new Set<String>();
        for (reduivy__Job_Queue__c jobQueue : jobQueues) {
            System.Assert.isNotNull(jobQueue.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
            jobQueueGroups.add(jobQueue.reduivy__Job_Operation_Context__c + '_' + jobQueue.reduivy__Job_Queue_Group__c);

            System.Assert.areEqual(JQH_Helper.STATUS_PENDING, jobQueue.reduivy__Status__c);
            System.Assert.areEqual(JQG_Helper.STATUS_PENDING, jobQueue.reduivy__Job_Queue_Group__r.reduivy__Status__c);

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
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);  

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            try {
                JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Invalid_Job_Operation', new List<Id>(ienMaps.keySet()), params);
                JQH_JobManager.queueJob(job, true);
            } catch (Exception exp) {
                String expectedError = String.format(Label.Missing_Job_Queue_Config, new List<String>{'Invalid_Job_Operation'});
                System.Assert.areEqual(expectedError, exp.getMessage());
            }            
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
            try {
                JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params);
                JQH_JobManager.queueJob(job, true);
            } catch (Exception exp) {
                String expectedError = Label.Missing_Job_Operation_Context;
                System.Assert.areEqual(expectedError, exp.getMessage());
            }            
        }

        Test.stopTest();
    }

    /**
     * @description Test add job without record ids as admin
     */
    @IsTest
    static void testAddJobWithoutRecordIdAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(), params);
            JQH_JobManager.queueJob(job, true);
        }

        Test.stopTest();
        
        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, jobQueue.reduivy__Status__c);
    }

    /**
     * @description Test starting the worker manually as admin
     */
    @IsTest
    static void testStartWorkerAsAdmin(){
        
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
        
        reduivy__Job_Queue__c jobQueueBefore = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        
        System.Assert.areEqual(JQH_Helper.STATUS_PENDING, jobQueueBefore.reduivy__Status__c);
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobManager.startWorker(null, false);
        }

        Test.stopTest();

        reduivy__Job_Queue__c jobQueueAfter = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        
        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, jobQueueAfter.reduivy__Status__c);
    }

    /**
     * @description Test starting the worker manually with last job id as admin, we expect a repeated job error log
     */
    @IsTest
    static void testStartWorkerWithLastJobIdAsAdmin(){
        
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
        
        reduivy__Job_Queue__c jobQueueBefore = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        
        System.Assert.areEqual(JQH_Helper.STATUS_PENDING, jobQueueBefore.reduivy__Status__c);
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobManager.startWorker(jobQueueBefore.Id, true);
        }

        Test.stopTest();

        reduivy__Job_Queue__c jobQueueAfter = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        
        System.Assert.areEqual(JQH_Helper.STATUS_PROCESSING, jobQueueAfter.reduivy__Status__c);

        reduivy__Log__c repeatedJobError = [SELECT Id, Name FROM reduivy__Log__c WHERE Name =: Label.Repeated_Job_Queue_Error_Title AND reduivy__Reference__c =: jobQueueAfter.Id];

        System.Assert.areEqual(Label.Repeated_Job_Queue_Error_Title, repeatedJobError.Name);
        
    }

    /**
     * @description Test cancel pending job as admin
     */
    @IsTest
    static void testCancelPendingJobAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);
        
        Test.startTest();

        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, false);
        }

        reduivy__Job_Queue__c jobQueueBefore = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(JQH_Helper.STATUS_PENDING, jobQueueBefore.reduivy__Status__c);

        System.runAs(ADMIN_USER) {
            JQH_JobManager.cancelJob(jobQueueBefore.Id);
        }

        reduivy__Job_Queue__c jobQueueAfter = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(JQH_Helper.STATUS_CANCELLED, jobQueueAfter.reduivy__Status__c);

        Test.stopTest();
    }

    /**
     * @description Test cancel pending job queue group as admin
     */
    @IsTest
    static void testCancelMultiplePendingJobQueueGroupAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params1 = new Map<String, Object>();
        params1.put('enrollmentStatus', 'Enrolled');
        params1.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job_1');

        Map<String, Object> params2 = new Map<String, Object>();
        params2.put('enrollmentStatus', 'Enrolled');
        params2.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job_2');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);
        
        Test.startTest();

        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job1 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params1);
            JQH_JobQueue_OBJ job2 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params2);
            JQH_JobManager.queueJobs(new List<JQH_JobQueue_OBJ>{job1, job2}, false);
        }

        List<reduivy__Job_Queue__c> jobQueueBefore = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        Set<Id> toBeCanceledIds = new Set<Id>();

        for(reduivy__Job_Queue__c jqh : jobQueueBefore) {
            toBeCanceledIds.add(jqh.reduivy__Job_Queue_Group__c);
        }

        System.Assert.areEqual(toBeCanceledIds.size(), 2, 'Should Have 2 job queue group');
        System.Assert.areEqual(JQG_Helper.STATUS_PENDING, jobQueueBefore[0].reduivy__Job_Queue_Group__r.reduivy__Status__c);
        System.Assert.areEqual(JQH_Helper.STATUS_PENDING, jobQueueBefore[0].reduivy__Status__c);

        System.Assert.areEqual(JQG_Helper.STATUS_PENDING, jobQueueBefore[1].reduivy__Job_Queue_Group__r.reduivy__Status__c);
        System.Assert.areEqual(JQH_Helper.STATUS_PENDING, jobQueueBefore[1].reduivy__Status__c);


        System.runAs(ADMIN_USER) {
            JQH_JobManager.cancelJobs(toBeCanceledIds);
        }

        List<reduivy__Job_Queue__c> jobQueueAfter = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(JQG_Helper.STATUS_CANCELLED, jobQueueAfter[0].reduivy__Job_Queue_Group__r.reduivy__Status__c);
        System.Assert.areEqual(JQH_Helper.STATUS_CANCELLED, jobQueueAfter[0].reduivy__Status__c);

        System.Assert.areEqual(JQG_Helper.STATUS_CANCELLED, jobQueueAfter[1].reduivy__Job_Queue_Group__r.reduivy__Status__c);
        System.Assert.areEqual(JQH_Helper.STATUS_CANCELLED, jobQueueAfter[1].reduivy__Status__c);

        Test.stopTest();
    }
    
    /**
     * @description Test cancel a completed job as admin
     */
    @IsTest
    static void testCancelCompletedJobAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);  

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, true);
        }

        Test.stopTest();
        
        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, jobQueue.reduivy__Status__c);

        System.runAs(ADMIN_USER) {
            try {
                JQH_JobManager.cancelJob(jobQueue.Id);
            } catch(Exception exp) {
                System.Assert.areEqual(String.format(Label.Job_Queue_Cannot_Be_Cancelled, new List<String>{jobQueue.Name}), exp.getMessage());
            }
        }
    }

    /**
     * @description Test cancel a completed job queue group as admin
    */
    @IsTest
    static void testCancelMultipleCompletedJobQueueGroupAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params1 = new Map<String, Object>();
        params1.put('enrollmentStatus', 'Enrolled');
        params1.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job_1');

        Map<String, Object> params2 = new Map<String, Object>();
        params2.put('enrollmentStatus', 'Enrolled');
        params2.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job_2');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);
        
        Test.startTest();

        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job1 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params1);
            JQH_JobQueue_OBJ job2 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params2);
            JQH_JobManager.queueJobs(new List<JQH_JobQueue_OBJ>{job1, job2}, false);
        }

        List<reduivy__Job_Queue__c> jobQueueBefore = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.reduivy__Status__c, reduivy__Job_Queue_Group__r.Name FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        Set<Id> toBeCanceledIds = new Set<Id>();
        List<String> jobQueueGroupNames = new List<String>();
        List<reduivy__Job_Queue__c> jobQueuesUpdateList = new List<reduivy__Job_Queue__c>();
        for(reduivy__Job_Queue__c jqh : jobQueueBefore) {
            toBeCanceledIds.add(jqh.reduivy__Job_Queue_Group__c);
            jobQueueGroupNames.add(jqh.reduivy__Job_Queue_Group__r.Name);

            reduivy__Job_Queue__c jqhUpdate = new reduivy__Job_Queue__c(Id = jqh.Id, reduivy__Status__c = JQH_Helper.STATUS_COMPLETED);
            jobQueuesUpdateList.add(jqhUpdate);
        }

        //mark the job as completed manually as test doesn't support more than 1 queue
        REDU_Database_UTIL.doUpdate(jobQueuesUpdateList);

        System.Assert.areEqual(toBeCanceledIds.size(), 2, 'Should Have 2 job queue group');

        System.runAs(ADMIN_USER) {
            try {
                JQH_JobManager.cancelJobs(toBeCanceledIds);
            } catch(Exception exp) {
                System.Assert.areEqual(String.format(Label.Job_Queue_Group_Cannot_Be_Cancelled, new List<String>{String.join(jobQueueGroupNames, ', ')}), exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test cancel an invalid job as admin
     */
    @IsTest
    static void testCancelInvalidJobAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){

            try {
                JQH_JobManager.cancelJob('a0v9n000001iBFRAA2');
            } catch(Exception exp) {
                String expextedError = String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{'a0v9n000001iBFRAA2', JQG_Helper.getObjectLabel() + '/' + JQH_Helper.getObjectLabel()});
                System.Assert.areEqual(expextedError, exp.getMessage());
            }
        }

        Test.stopTest();
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

        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        jobQueue.reduivy__Status__c = JQH_Helper.STATUS_FAILED;

        REDU_Database_UTIL.doUpdate(new List<reduivy__Job_Queue__c>{jobQueue});

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //we clear the cache here to avoid the retry job linking to the same job queue group
            JQH_JobManager.clearJobQueueGroupsOperationContextCache();

            JQH_JobManager.retryJob(jobQueue.Id, JQH_Helper.RETRY_TYPE_ALL, true);
        }

        Test.stopTest();
        
        reduivy__Job_Queue__c originJobQueue = [SELECT Id, reduivy__Retry_Attempted__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE Id =: jobQueue.Id];
        reduivy__Job_Queue__c retryJobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Origin_Job_Queue_ID__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job' AND reduivy__Origin_Job_Queue_ID__c =: jobQueue.Name];

        System.Assert.areEqual(true, originJobQueue.reduivy__Retry_Attempted__c);
        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, retryJobQueue.reduivy__Status__c);
        System.Assert.areEqual(jobQueue.reduivy__Job_Handler_Record_Ids__c, retryJobQueue.reduivy__Job_Handler_Record_Ids__c);
        System.Assert.isNotNull(retryJobQueue.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areNotEqual(originJobQueue.reduivy__Job_Queue_Group__c, retryJobQueue.reduivy__Job_Queue_Group__c);

    }

    /**
     * @description Test retry a failed/completed job queue group with all records
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

        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        jobQueue.reduivy__Status__c = JQH_Helper.STATUS_FAILED;

        REDU_Database_UTIL.doUpdate(new List<reduivy__Job_Queue__c>{jobQueue});

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //we clear the cache here to avoid the retry job linking to the same job queue group
            JQH_JobManager.clearJobQueueGroupsOperationContextCache();

            JQH_JobManager.retryJob(jobQueue.reduivy__Job_Queue_Group__c, JQH_Helper.RETRY_TYPE_ALL, true);
        }

        Test.stopTest();
        
        reduivy__Job_Queue__c originJobQueue = [SELECT Id, reduivy__Retry_Attempted__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE Id =: jobQueue.Id];
        reduivy__Job_Queue__c retryJobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Origin_Job_Queue_ID__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job' AND reduivy__Origin_Job_Queue_ID__c =: jobQueue.Name];

        System.Assert.areEqual(true, originJobQueue.reduivy__Retry_Attempted__c);
        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, retryJobQueue.reduivy__Status__c);
        System.Assert.areEqual(jobQueue.reduivy__Job_Handler_Record_Ids__c, retryJobQueue.reduivy__Job_Handler_Record_Ids__c);
        System.Assert.isNotNull(retryJobQueue.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areNotEqual(originJobQueue.reduivy__Job_Queue_Group__c, retryJobQueue.reduivy__Job_Queue_Group__c);

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

        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        jobQueue.reduivy__Status__c = JQH_Helper.STATUS_FAILED;
        jobQueue.reduivy__Job_Handler_Error_Record_Ids__c = JQH_Helper.serializeRecordIds(new List<Id>{ienMaps.values().get(0).Id, ienMaps.values().get(0).Id});

        REDU_Database_UTIL.doUpdate(new List<reduivy__Job_Queue__c>{jobQueue});

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //we clear the cache here to avoid the retry job linking to the same job queue group
            JQH_JobManager.clearJobQueueGroupsOperationContextCache();

            JQH_JobManager.retryJob(jobQueue.Id, JQH_Helper.RETRY_TYPE_ERROR_ONLY, true);
        }

        Test.stopTest();
        
        reduivy__Job_Queue__c originJobQueue = [SELECT Id, reduivy__Retry_Attempted__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE Id =: jobQueue.Id];
        reduivy__Job_Queue__c retryJobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Origin_Job_Queue_ID__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job' AND reduivy__Origin_Job_Queue_ID__c =: jobQueue.Name];

        System.Assert.areEqual(true, originJobQueue.reduivy__Retry_Attempted__c);
        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, retryJobQueue.reduivy__Status__c);
        System.Assert.areEqual(jobQueue.reduivy__Job_Handler_Error_Record_Ids__c, retryJobQueue.reduivy__Job_Handler_Record_Ids__c);
        System.Assert.areEqual(jobQueue.reduivy__Number_of_Attempts__c + 1, retryJobQueue.reduivy__Number_of_Attempts__c);
        System.Assert.isNotNull(retryJobQueue.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areNotEqual(originJobQueue.reduivy__Job_Queue_Group__c, retryJobQueue.reduivy__Job_Queue_Group__c);

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

        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        jobQueue.reduivy__Status__c = JQH_Helper.STATUS_FAILED;
        jobQueue.reduivy__Job_Handler_Error_Record_Ids__c = JQH_Helper.serializeRecordIds(new List<Id>{ienMaps.values().get(0).Id, ienMaps.values().get(0).Id});

        REDU_Database_UTIL.doUpdate(new List<reduivy__Job_Queue__c>{jobQueue});

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //we clear the cache here to avoid the retry job linking to the same job queue group
            JQH_JobManager.clearJobQueueGroupsOperationContextCache();

            JQH_JobManager.retryJob(jobQueue.reduivy__Job_Queue_Group__c, JQH_Helper.RETRY_TYPE_ERROR_ONLY, true);
        }

        Test.stopTest();
        
        reduivy__Job_Queue__c originJobQueue = [SELECT Id, reduivy__Retry_Attempted__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE Id =: jobQueue.Id];
        reduivy__Job_Queue__c retryJobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Origin_Job_Queue_ID__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job' AND reduivy__Origin_Job_Queue_ID__c =: jobQueue.Name];

        System.Assert.areEqual(true, originJobQueue.reduivy__Retry_Attempted__c);
        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, retryJobQueue.reduivy__Status__c);
        System.Assert.areEqual(jobQueue.reduivy__Job_Handler_Error_Record_Ids__c, retryJobQueue.reduivy__Job_Handler_Record_Ids__c);
        System.Assert.areEqual(jobQueue.reduivy__Number_of_Attempts__c + 1, retryJobQueue.reduivy__Number_of_Attempts__c);
        System.Assert.isNotNull(retryJobQueue.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areNotEqual(originJobQueue.reduivy__Job_Queue_Group__c, retryJobQueue.reduivy__Job_Queue_Group__c);

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

        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            try {
                //we clear the cache here to avoid the retry job linking to the same job queue group
                JQH_JobManager.clearJobQueueGroupsOperationContextCache();
                
                JQH_JobManager.retryJob(jobQueue.Id, JQH_Helper.RETRY_TYPE_ERROR_ONLY, true);
            } catch (Exception exp) {
                String expextedError = String.format(Label.Job_Queue_Cannot_Be_Retried, new List<String>{jobQueue.Name});
                System.Assert.areEqual(expextedError, exp.getMessage());
            }
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
            try {
                //we clear the cache here to avoid the retry job linking to the same job queue group
                JQH_JobManager.clearJobQueueGroupsOperationContextCache();
                
                JQH_JobManager.retryJob(jobQueue.reduivy__Job_Queue_Group__c, JQH_Helper.RETRY_TYPE_ERROR_ONLY, true);
            } catch (Exception exp) {
                String expextedError = String.format(Label.Job_Queue_Cannot_Be_Retried, new List<String>{jobQueue.reduivy__Job_Queue_Group__r.Name});
                System.Assert.areEqual(expextedError, exp.getMessage());
            }
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

        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        jobQueue.reduivy__Status__c = JQH_Helper.STATUS_PROCESSING;
        
        REDU_Database_UTIL.doUpdate(new List<reduivy__Job_Queue__c>{jobQueue});

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            try {
                //we clear the cache here to avoid the retry job linking to the same job queue group
                JQH_JobManager.clearJobQueueGroupsOperationContextCache();

                JQH_JobManager.retryJob(jobQueue.Id, JQH_Helper.RETRY_TYPE_ERROR_ONLY, true);
            } catch (Exception exp) {
                String expextedError = String.format(Label.Job_Queue_Cannot_Be_Retried, new List<String>{jobQueue.Name});
                System.Assert.areEqual(expextedError, exp.getMessage());
            }
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
            try {
                //we clear the cache here to avoid the retry job linking to the same job queue group
                JQH_JobManager.clearJobQueueGroupsOperationContextCache();

                JQH_JobManager.retryJob(jobQueue.reduivy__Job_Queue_Group__c, JQH_Helper.RETRY_TYPE_ERROR_ONLY, true);
            } catch (Exception exp) {
                String expextedError = String.format(Label.Job_Queue_Cannot_Be_Retried, new List<String>{jobQueue.reduivy__Job_Queue_Group__r.Name});
                System.Assert.areEqual(expextedError, exp.getMessage());
            }
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

            try {
                //we clear the cache here to avoid the retry job linking to the same job queue group
                JQH_JobManager.clearJobQueueGroupsOperationContextCache();

                JQH_JobManager.retryJob('a0v9n000001iBFRAA2', JQH_Helper.RETRY_TYPE_ALL, true);
                
            } catch(Exception exp) {
                String expextedError = String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{'a0v9n000001iBFRAA2', JQG_Helper.getObjectLabel() + '/' + JQH_Helper.getObjectLabel()});
                System.Assert.areEqual(expextedError, exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test clear job history
     */
    @IsTest
    static void testClearJobHistoryAsAdmin(){
        
        String jobContext = 'TESTCLEARJOB';

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, jobContext);

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);  

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, true);
        }

        Test.stopTest();
        
        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Job_Operation_Context__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation_Context__c =: jobContext];
        List<reduivy__Log__c> logs = [SELECT Id FROM reduivy__Log__c WHERE reduivy__Job_Queue__c =: jobQueue.Id];

        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, jobQueue.reduivy__Status__c);
        System.Assert.areEqual(false, logs.isEmpty());

        System.runAs(ADMIN_USER) {
            JQH_JobManager.clearJobHistory(jobContext);
        }

        List<reduivy__Job_Queue__c> jobQueuesAfterClearance = [SELECT Id, Name, reduivy__Job_Operation_Context__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE Id =: jobQueue.Id];
        List<reduivy__Log__c> logsAfterClearance = [SELECT Id FROM reduivy__Log__c WHERE reduivy__Job_Queue__c =: jobQueue.Id];

        System.Assert.areEqual(true, jobQueuesAfterClearance.isEmpty());
        System.Assert.areEqual(true, logsAfterClearance.isEmpty());
    }
}