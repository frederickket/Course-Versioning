/**
 * @author      WDCi (XiRouh)
 * @date        Feb 2025
 * @group       Test
 * @description Test class for REDU_JqhCancelJobConfirmationModal_LCTRL
 * @changehistory
 * ISS-002229 28-02-2025 XiRouh - new class
 * ISS-002547 15-07-2025 Lean - Added job group test
 */
@IsTest
public inherited sharing class REDU_JqhCancelJobConfirmationModal_TEST {
    
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
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);
        
        Test.startTest();

        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, false);
            JQH_JobManager.queueJob(job, false);
        }

        List<reduivy__Job_Queue__c> jobQueueBefore = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        List<Id> toBeCanceledIds = new List<Id>();

        for(reduivy__Job_Queue__c jqh : jobQueueBefore) {
            toBeCanceledIds.add(jqh.Id);
        }

        System.Assert.areEqual(toBeCanceledIds.size(), 2, 'Should Have 2 jobs in the queue');
        System.Assert.areEqual(JQH_Helper.STATUS_PENDING, jobQueueBefore[0].reduivy__Status__c);
        System.Assert.areEqual(JQH_Helper.STATUS_PENDING, jobQueueBefore[1].reduivy__Status__c);


        System.runAs(ADMIN_USER) {
            REDU_JqhCancelJobConfirmationModal_LCTRL.cancelJob(toBeCanceledIds);
        }

        List<reduivy__Job_Queue__c> jobQueueAfter = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(JQH_Helper.STATUS_CANCELLED, jobQueueAfter[0].reduivy__Status__c);
        System.Assert.areEqual(JQH_Helper.STATUS_CANCELLED, jobQueueAfter[1].reduivy__Status__c);

        Test.stopTest();
    }

    /**
     * @description Test cancel pending job queue group as admin
    */
    @IsTest
    static void testCancelPendingJobQueueGroupAsAdmin(){
        
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
            REDU_JqhCancelJobConfirmationModal_LCTRL.cancelJob(new List<Id>(toBeCanceledIds));
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
                REDU_JqhCancelJobConfirmationModal_LCTRL.cancelJob(new List<Id>{jobQueue.Id});
            } catch(Exception exp) {
                System.Assert.areEqual(String.format(Label.Job_Queue_Cannot_Be_Cancelled, new List<String>{jobQueue.Name}), exp.getMessage());
            }
        }
    }

    /**
     * @description Test cancel a completed job queue group as admin
    */
    @IsTest
    static void testCancelCompletedJobQueueGroupAsAdmin(){
        
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
                REDU_JqhCancelJobConfirmationModal_LCTRL.cancelJob(new List<Id>(toBeCanceledIds));
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
                REDU_JqhCancelJobConfirmationModal_LCTRL.cancelJob(new List<Id>{'a0v9n000001iBFRAA2'});
            } catch(Exception exp) {
                String expextedError = String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{'a0v9n000001iBFRAA2', JQG_Helper.getObjectLabel() + '/' + JQH_Helper.getObjectLabel()});
                System.Assert.areEqual(expextedError, exp.getMessage());
            }
        }

        Test.stopTest();
    }
}