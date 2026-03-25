/**
 * @author      WDCi (Lean)
 * @date        Jan 2025
 * @group       Test
 * @description Test class for REDU_JqhCancelJob_LCTRL
 * @changehistory
 * ISS-002219 06-01-2025 Lean - new class
 * ISS-002547 15-07-2025 Lean - Added job group test
 */

@IsTest
public inherited sharing class REDU_JqhCancelJob_TEST {
    
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
        }

        reduivy__Job_Queue__c jobQueueBefore = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(JQH_Helper.STATUS_PENDING, jobQueueBefore.reduivy__Status__c);

        System.runAs(ADMIN_USER) {
            REDU_JqhCancelJob_LCTRL.cancelJob(jobQueueBefore.Id);
        }

        reduivy__Job_Queue__c jobQueueAfter = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(JQH_Helper.STATUS_CANCELLED, jobQueueAfter.reduivy__Status__c);

        Test.stopTest();
    }

    /**
     * @description Test cancel pending job queue group as admin
     */
    @IsTest
    static void testCancelPendingJobQueueGroupAsAdmin(){
        
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

        reduivy__Job_Queue__c jobQueueBefore = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(JQG_Helper.STATUS_PENDING, jobQueueBefore.reduivy__Job_Queue_Group__r.reduivy__Status__c);
        System.Assert.areEqual(JQH_Helper.STATUS_PENDING, jobQueueBefore.reduivy__Status__c);

        System.runAs(ADMIN_USER) {
            REDU_JqhCancelJob_LCTRL.cancelJob(jobQueueBefore.reduivy__Job_Queue_Group__c);
        }

        reduivy__Job_Queue__c jobQueueAfter = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(JQG_Helper.STATUS_CANCELLED, jobQueueAfter.reduivy__Job_Queue_Group__r.reduivy__Status__c);
        System.Assert.areEqual(JQH_Helper.STATUS_CANCELLED, jobQueueAfter.reduivy__Status__c);

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
                REDU_JqhCancelJob_LCTRL.cancelJob(jobQueue.Id);
            } catch(Exception exp) {
                String expectedError = String.format(Label.Job_Queue_Cannot_Be_Cancelled, new List<String>{jobQueue.Name});
                System.Assert.areEqual(expectedError, exp.getMessage());
            }
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
        
        reduivy__Job_Queue__c jobQueueBefore = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.reduivy__Status__c, reduivy__Job_Queue_Group__r.Name FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(JQG_Helper.STATUS_COMPLETED, jobQueueBefore.reduivy__Job_Queue_Group__r.reduivy__Status__c);
        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, jobQueueBefore.reduivy__Status__c);

        System.runAs(ADMIN_USER) {
            try {
                REDU_JqhCancelJob_LCTRL.cancelJob(jobQueueBefore.reduivy__Job_Queue_Group__c);
            } catch(Exception exp) {
                String expectedError = String.format(Label.Job_Queue_Group_Cannot_Be_Cancelled, new List<String>{jobQueueBefore.reduivy__Job_Queue_Group__r.Name});
                System.Assert.areEqual(expectedError, exp.getMessage());
            }
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

            try {
                REDU_JqhCancelJob_LCTRL.cancelJob('a0v9n000001iBFRAA2');
            } catch(Exception exp) {
                String expextedError = String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{'a0v9n000001iBFRAA2', JQG_Helper.getObjectLabel() + '/' + JQH_Helper.getObjectLabel()});
                System.Assert.areEqual(expextedError, exp.getMessage());
            }
        }

        Test.stopTest();
    }
}