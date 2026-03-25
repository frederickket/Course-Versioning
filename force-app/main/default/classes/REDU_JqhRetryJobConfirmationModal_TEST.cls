/**
 * @author      WDCi (XiRouh)
 * @date        Feb 2025
 * @group       Test
 * @description Test class for REDU_JqhRetryJobConfirmationModal_LCTRL
 * @changehistory
 * ISS-002229 28-02-2025 XiRouh - new class
 * ISS-002547 15-07-2025 Lean - Added job group test
 */
@IsTest
public inherited sharing class REDU_JqhRetryJobConfirmationModal_TEST {
    
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
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job1 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params1);
            JQH_JobQueue_OBJ job2 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params2);
            JQH_JobManager.queueJobs(new List<JQH_JobQueue_OBJ>{job1, job2}, false);
        }

        List<reduivy__Job_Queue__c> jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        
        List<Id> toBeRetryIds = new List<Id>();
        for(reduivy__Job_Queue__c jqh : jobQueue) {
            toBeRetryIds.add(jqh.Id);
        }

        System.Assert.areEqual(toBeRetryIds.size(), 2, 'Should Have 2 jobs in the queue');
        
        jobQueue[0].reduivy__Status__c = JQH_Helper.STATUS_FAILED;
        jobQueue[1].reduivy__Status__c = JQH_Helper.STATUS_FAILED;

        REDU_Database_UTIL.doUpdate(jobQueue);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobManager.clearJobQueueGroupsOperationContextCache();
            REDU_JqhRetryJobConfirmationModal_LCTRL.retryJob(toBeRetryIds, JQH_Helper.RETRY_TYPE_ALL);
        }

        Test.stopTest();
        
        List<reduivy__Job_Queue__c> retryJobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Origin_Job_Queue_ID__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job' AND reduivy__Origin_Job_Queue_ID__c != null];

        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, retryJobQueue[0].reduivy__Status__c);
        System.Assert.areEqual(jobQueue[0].reduivy__Job_Handler_Record_Ids__c, retryJobQueue[1].reduivy__Job_Handler_Record_Ids__c);
        System.Assert.isNotNull(retryJobQueue[0].reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areNotEqual(jobQueue[0].reduivy__Job_Queue_Group__c, retryJobQueue[0].reduivy__Job_Queue_Group__c);

        System.Assert.areEqual(JQH_Helper.STATUS_PENDING, retryJobQueue[1].reduivy__Status__c);
        System.Assert.areEqual(jobQueue[1].reduivy__Job_Handler_Record_Ids__c, retryJobQueue[1].reduivy__Job_Handler_Record_Ids__c);
        System.Assert.isNotNull(retryJobQueue[1].reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areNotEqual(jobQueue[1].reduivy__Job_Queue_Group__c, retryJobQueue[1].reduivy__Job_Queue_Group__c);

    }

    /**
     * @description Test retry a failed/completed job queue group with all records
    */
    @IsTest
    static void testRetryFailedJobQueueGroupWithAllRecordsAsAdmin(){
        
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
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job1 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params1);
            JQH_JobQueue_OBJ job2 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params2);
            JQH_JobManager.queueJobs(new List<JQH_JobQueue_OBJ>{job1, job2}, false);
        }

        List<reduivy__Job_Queue__c> jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.Name FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        
        List<Id> toBeRetryIds = new List<Id>();
        for(reduivy__Job_Queue__c jqh : jobQueue) {
            toBeRetryIds.add(jqh.reduivy__Job_Queue_Group__c);

            System.Assert.isNotNull(jqh.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        }

        System.Assert.areEqual(toBeRetryIds.size(), 2, 'Should Have 2 jobs in the queue');
        
        jobQueue[0].reduivy__Status__c = JQH_Helper.STATUS_FAILED;
        jobQueue[1].reduivy__Status__c = JQH_Helper.STATUS_FAILED;

        REDU_Database_UTIL.doUpdate(jobQueue);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobManager.clearJobQueueGroupsOperationContextCache();
            REDU_JqhRetryJobConfirmationModal_LCTRL.retryJob(toBeRetryIds, JQH_Helper.RETRY_TYPE_ALL);
        }

        Test.stopTest();
        
        List<reduivy__Job_Queue__c> retryJobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Origin_Job_Queue_ID__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job' AND reduivy__Origin_Job_Queue_ID__c != null];

        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, retryJobQueue[0].reduivy__Status__c);
        System.Assert.areEqual(jobQueue[0].reduivy__Job_Handler_Record_Ids__c, retryJobQueue[1].reduivy__Job_Handler_Record_Ids__c);
        System.Assert.isNotNull(retryJobQueue[0].reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areNotEqual(jobQueue[0].reduivy__Job_Queue_Group__c, retryJobQueue[0].reduivy__Job_Queue_Group__c);

        System.Assert.areEqual(JQH_Helper.STATUS_PENDING, retryJobQueue[1].reduivy__Status__c);
        System.Assert.areEqual(jobQueue[1].reduivy__Job_Handler_Record_Ids__c, retryJobQueue[1].reduivy__Job_Handler_Record_Ids__c);
        System.Assert.isNotNull(retryJobQueue[1].reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areNotEqual(jobQueue[1].reduivy__Job_Queue_Group__c, retryJobQueue[1].reduivy__Job_Queue_Group__c);

    }

    /**
     * @description Test retry a failed/completed job with error records
    */
    @IsTest
    static void testRetryFailedJobWithErrorRecordsAsAdmin(){
        
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
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job1 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params1);
            JQH_JobQueue_OBJ job2 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params2);
            JQH_JobManager.queueJobs(new List<JQH_JobQueue_OBJ>{job1, job2}, false);
        }

        List<reduivy__Job_Queue__c> jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        
        List<Id> toBeRetryIds = new List<Id>();
        for(reduivy__Job_Queue__c jqh : jobQueue) {
            toBeRetryIds.add(jqh.Id);
        }

        System.Assert.areEqual(toBeRetryIds.size(), 2, 'Should Have 2 jobs in the queue');

        jobQueue[0].reduivy__Status__c = JQH_Helper.STATUS_FAILED;
        jobQueue[0].reduivy__Job_Handler_Error_Record_Ids__c = JQH_Helper.serializeRecordIds(new List<Id>{ienMaps.values().get(0).Id, ienMaps.values().get(0).Id});

        jobQueue[1].reduivy__Status__c = JQH_Helper.STATUS_FAILED;
        jobQueue[1].reduivy__Job_Handler_Error_Record_Ids__c = JQH_Helper.serializeRecordIds(new List<Id>{ienMaps.values().get(0).Id, ienMaps.values().get(0).Id});

        REDU_Database_UTIL.doUpdate(jobQueue);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobManager.clearJobQueueGroupsOperationContextCache();
            REDU_JqhRetryJobConfirmationModal_LCTRL.retryJob(toBeRetryIds, JQH_Helper.RETRY_TYPE_ERROR_ONLY);
        }

        Test.stopTest();
        
        List<reduivy__Job_Queue__c> retryJobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Origin_Job_Queue_ID__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job' AND reduivy__Origin_Job_Queue_ID__c != null];

        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, retryJobQueue[0].reduivy__Status__c);
        System.Assert.areEqual(jobQueue[0].reduivy__Job_Handler_Error_Record_Ids__c, retryJobQueue[1].reduivy__Job_Handler_Record_Ids__c);
        System.Assert.isNotNull(retryJobQueue[0].reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areNotEqual(jobQueue[0].reduivy__Job_Queue_Group__c, retryJobQueue[0].reduivy__Job_Queue_Group__c);

        System.Assert.areEqual(JQH_Helper.STATUS_PENDING, retryJobQueue[1].reduivy__Status__c);
        System.Assert.areEqual(jobQueue[1].reduivy__Job_Handler_Error_Record_Ids__c, retryJobQueue[1].reduivy__Job_Handler_Record_Ids__c);
        System.Assert.isNotNull(retryJobQueue[1].reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areNotEqual(jobQueue[1].reduivy__Job_Queue_Group__c, retryJobQueue[1].reduivy__Job_Queue_Group__c);

    }

    /**
     * @description Test retry a failed/completed job queue group with error records
    */
    @IsTest
    static void testRetryFailedJobQueueGroupWithErrorRecordsAsAdmin(){
        
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
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job1 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params1);
            JQH_JobQueue_OBJ job2 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params2);
            JQH_JobManager.queueJobs(new List<JQH_JobQueue_OBJ>{job1, job2}, false);
        }

        List<reduivy__Job_Queue__c> jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        
        List<Id> toBeRetryIds = new List<Id>();
        for(reduivy__Job_Queue__c jqh : jobQueue) {
            toBeRetryIds.add(jqh.reduivy__Job_Queue_Group__c);

            System.Assert.isNotNull(jqh.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        }

        System.Assert.areEqual(toBeRetryIds.size(), 2, 'Should Have 2 jobs in the queue');

        jobQueue[0].reduivy__Status__c = JQH_Helper.STATUS_FAILED;
        jobQueue[0].reduivy__Job_Handler_Error_Record_Ids__c = JQH_Helper.serializeRecordIds(new List<Id>{ienMaps.values().get(0).Id, ienMaps.values().get(0).Id});

        jobQueue[1].reduivy__Status__c = JQH_Helper.STATUS_FAILED;
        jobQueue[1].reduivy__Job_Handler_Error_Record_Ids__c = JQH_Helper.serializeRecordIds(new List<Id>{ienMaps.values().get(0).Id, ienMaps.values().get(0).Id});

        REDU_Database_UTIL.doUpdate(jobQueue);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobManager.clearJobQueueGroupsOperationContextCache();
            REDU_JqhRetryJobConfirmationModal_LCTRL.retryJob(toBeRetryIds, JQH_Helper.RETRY_TYPE_ERROR_ONLY);
        }

        Test.stopTest();
        
        List<reduivy__Job_Queue__c> retryJobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Origin_Job_Queue_ID__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job' AND reduivy__Origin_Job_Queue_ID__c != null];

        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, retryJobQueue[0].reduivy__Status__c);
        System.Assert.areEqual(jobQueue[0].reduivy__Job_Handler_Error_Record_Ids__c, retryJobQueue[1].reduivy__Job_Handler_Record_Ids__c);
        System.Assert.isNotNull(retryJobQueue[0].reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areNotEqual(jobQueue[0].reduivy__Job_Queue_Group__c, retryJobQueue[0].reduivy__Job_Queue_Group__c);

        System.Assert.areEqual(JQH_Helper.STATUS_PENDING, retryJobQueue[1].reduivy__Status__c);
        System.Assert.areEqual(jobQueue[1].reduivy__Job_Handler_Error_Record_Ids__c, retryJobQueue[1].reduivy__Job_Handler_Record_Ids__c);
        System.Assert.isNotNull(retryJobQueue[1].reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areNotEqual(jobQueue[1].reduivy__Job_Queue_Group__c, retryJobQueue[1].reduivy__Job_Queue_Group__c);

    }

    /**
     * @description Test retry a pending job as admin
    */
    @IsTest
    static void testRetryPendingJobAsAdmin(){
        
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
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job1 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params1);
            JQH_JobQueue_OBJ job2 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params2);
            JQH_JobManager.queueJobs(new List<JQH_JobQueue_OBJ>{job1, job2}, false);
        }

        List<reduivy__Job_Queue__c> jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        List<Id> toBeRetryIds = new List<Id>();
        List<String> jobQueueNames = new List<String>();
        for(reduivy__Job_Queue__c jqh : jobQueue) {
            toBeRetryIds.add(jqh.Id);
            jobQueueNames.add(jqh.Name);
        }

        System.Assert.areEqual(toBeRetryIds.size(), 2, 'Should Have 2 jobs in the queue');

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            try {
                REDU_JqhRetryJobConfirmationModal_LCTRL.retryJob(toBeRetryIds, JQH_Helper.RETRY_TYPE_ERROR_ONLY);
            } catch (Exception exp) {
                String errorMsg = exp.getMessage();

                System.Assert.isTrue(errorMsg.contains(String.format(Label.Job_Queue_Cannot_Be_Retried, new List<String>{String.join(jobQueueNames, ', ')})), 
                                    'Unexpected error: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test retry a pending job as admin
    */
    @IsTest
    static void testRetryPendingJobQueueGroupAsAdmin(){
        
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
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job1 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params1);
            JQH_JobQueue_OBJ job2 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params2);
            JQH_JobManager.queueJobs(new List<JQH_JobQueue_OBJ>{job1, job2}, false);
        }

        List<reduivy__Job_Queue__c> jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.Name FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        List<Id> toBeRetryIds = new List<Id>();
        List<String> jobQueueGroupNames = new List<String>();
        for(reduivy__Job_Queue__c jqh : jobQueue) {
            toBeRetryIds.add(jqh.reduivy__Job_Queue_Group__c);
            jobQueueGroupNames.add(jqh.reduivy__Job_Queue_Group__r.Name);

            System.Assert.isNotNull(jqh.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        }

        System.Assert.areEqual(toBeRetryIds.size(), 2, 'Should Have 2 jobs in the queue');

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            try {
                JQH_JobManager.clearJobQueueGroupsOperationContextCache();
                REDU_JqhRetryJobConfirmationModal_LCTRL.retryJob(toBeRetryIds, JQH_Helper.RETRY_TYPE_ERROR_ONLY);
            } catch (Exception exp) {

                String errorMsg = exp.getMessage();

                System.Assert.isTrue(errorMsg.contains(String.format(Label.Job_Queue_Cannot_Be_Retried, new List<String>{String.join(jobQueueGroupNames, ', ')})), 
                                    'Unexpected error: ' + exp.getMessage());
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
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job1 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params1);
            JQH_JobQueue_OBJ job2 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params2);
            JQH_JobManager.queueJobs(new List<JQH_JobQueue_OBJ>{job1, job2}, false);
        }

        List<reduivy__Job_Queue__c> jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        List<Id> toBeRetryIds = new List<Id>();
        List<String> jobQueueNames = new List<String>();
        for(reduivy__Job_Queue__c jqh : jobQueue) {
            toBeRetryIds.add(jqh.Id);
            jobQueueNames.add(jqh.Name);
        }

        System.Assert.areEqual(toBeRetryIds.size(), 2, 'Should Have 2 jobs in the queue');

        jobQueue[0].reduivy__Status__c = JQH_Helper.STATUS_PROCESSING;
        jobQueue[1].reduivy__Status__c = JQH_Helper.STATUS_PROCESSING;

        REDU_Database_UTIL.doUpdate(jobQueue);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            try {
                REDU_JqhRetryJobConfirmationModal_LCTRL.retryJob(toBeRetryIds, JQH_Helper.RETRY_TYPE_ERROR_ONLY);
            } catch (Exception exp) {
                String errorMsg = exp.getMessage();

                System.Assert.isTrue(errorMsg.contains(String.format(Label.Job_Queue_Cannot_Be_Retried, new List<String>{String.join(jobQueueNames, ', ')})), 
                                    'Unexpected error: ' + exp.getMessage());
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
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job1 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params1);
            JQH_JobQueue_OBJ job2 = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params2);
            JQH_JobManager.queueJobs(new List<JQH_JobQueue_OBJ>{job1, job2}, false);
        }

        List<reduivy__Job_Queue__c> jobQueue = [SELECT Id, Name, reduivy__Status__c, reduivy__Job_Operation__c, reduivy__Job_Handler_Record_Ids__c, reduivy__Job_Handler_Error_Record_Ids__c, reduivy__Number_of_Attempts__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.Name FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        List<Id> toBeRetryIds = new List<Id>();
        List<String> jobQueueGroupNames = new List<String>();
        for(reduivy__Job_Queue__c jqh : jobQueue) {
            toBeRetryIds.add(jqh.reduivy__Job_Queue_Group__c);
            jobQueueGroupNames.add(jqh.reduivy__Job_Queue_Group__r.Name);

            System.Assert.isNotNull(jqh.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        }

        System.Assert.areEqual(toBeRetryIds.size(), 2, 'Should Have 2 jobs in the queue');

        jobQueue[0].reduivy__Status__c = JQH_Helper.STATUS_PROCESSING;
        jobQueue[1].reduivy__Status__c = JQH_Helper.STATUS_PROCESSING;

        REDU_Database_UTIL.doUpdate(jobQueue);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            try {
                JQH_JobManager.clearJobQueueGroupsOperationContextCache();
                REDU_JqhRetryJobConfirmationModal_LCTRL.retryJob(toBeRetryIds, JQH_Helper.RETRY_TYPE_ERROR_ONLY);
            } catch (Exception exp) {

                String errorMsg = exp.getMessage();

                System.Assert.isTrue(errorMsg.contains(String.format(Label.Job_Queue_Cannot_Be_Retried, new List<String>{String.join(jobQueueGroupNames, ', ')})), 
                                    'Unexpected error: ' + exp.getMessage());
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
                REDU_JqhRetryJobConfirmationModal_LCTRL.retryJob(new List<Id>{'a0v9n000001iBFRAA2'}, JQH_Helper.RETRY_TYPE_ALL);
            } catch(Exception exp) {
                String expextedError = String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{'a0v9n000001iBFRAA2', JQG_Helper.getObjectLabel() + '/' + JQH_Helper.getObjectLabel()});
                System.Assert.areEqual(expextedError, exp.getMessage());
            }
        }

        Test.stopTest();
    }
}