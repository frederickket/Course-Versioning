/**
 * @author      WDCi (Lean)
 * @date        Jan 2025
 * @group       Test
 * @description Test class for JQH_StartWorker_FLOW
 * @changehistory
 * ISS-002219 03-01-2025 Lean - new class
 * ISS-002547 15-07-2025 Lean - Added job group test
 */

@IsTest
public inherited sharing class JQH_StartWorker_TEST {
    
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
            //simulate the data from flow
            JQH_StartWorker_FLOW.Request flowRequest = new JQH_StartWorker_FLOW.Request();

            //invoke the method
            List<JQH_StartWorker_FLOW.Response> responses = JQH_StartWorker_FLOW.execute(new List<JQH_StartWorker_FLOW.Request>{flowRequest});

            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
            System.Assert.areEqual(Label.Job_Worker_Was_Started, responses.get(0).message);
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
            //simulate the data from flow
            JQH_StartWorker_FLOW.Request flowRequest = new JQH_StartWorker_FLOW.Request();
            flowRequest.lastJobQueueId = jobQueueBefore.Id;

            //invoke the method
            List<JQH_StartWorker_FLOW.Response> responses = JQH_StartWorker_FLOW.execute(new List<JQH_StartWorker_FLOW.Request>{flowRequest});

            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
            System.Assert.areEqual(Label.Job_Worker_Was_Started, responses.get(0).message);
        }

        Test.stopTest();

        reduivy__Job_Queue__c jobQueueAfter = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        
        System.Assert.areEqual(JQH_Helper.STATUS_PROCESSING, jobQueueAfter.reduivy__Status__c);

        reduivy__Log__c repeatedJobError = [SELECT Id, Name FROM reduivy__Log__c WHERE Name =: Label.Repeated_Job_Queue_Error_Title AND reduivy__Reference__c =: jobQueueAfter.Id];

        System.Assert.areEqual(Label.Repeated_Job_Queue_Error_Title, repeatedJobError.Name);
        
    }
}