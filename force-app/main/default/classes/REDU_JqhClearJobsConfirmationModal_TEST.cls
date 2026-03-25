/**
 * @author      WDCi (XiRouh)
 * @date        Feb 2025
 * @group       Test
 * @description Test class for REDU_JqhCancelJobConfirmationModal_LCTRL
 * @changehistory
 * ISS-002229 28-02-2025 XiRouh - new class
 */
@IsTest
public inherited sharing class REDU_JqhClearJobsConfirmationModal_TEST {
    
    /**
     * @description Initialise test environment
    */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    private static final String JOB_OPERATION = 'Term_Student_Enrollment';

    /**
     * @description Initialise test data for each test
    */
    @TestSetup
    static void makeData(){
        
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

        	testFactory.initMasterData(null);
            testFactory.initOfferingData(null);
			testFactory.initStudentData(IPE_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test clear jobs as admin
    */
    @IsTest
    static void testClearJobsAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        List<reduivy__Individual_Program_Enrollment__c> ipes = [SELECT Id, reduivy__Starting_Term__r.reduivy__End_Date__c, (SELECT Id, reduivy__Term_Number__c, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Pathways__r ORDER BY reduivy__Term_Number__c) FROM reduivy__Individual_Program_Enrollment__c ORDER BY reduivy__Contact__r.reduivy__Sequence__c ASC];
        Date toBeEnrolledTermStartDate = ipes[0].reduivy__Starting_Term__r.reduivy__End_Date__c.addDays(31);
        List<reduivy__Study_Term__c> terms = [SELECT Id, Name FROM reduivy__Study_Term__c WHERE reduivy__Start_Date__c = :toBeEnrolledTermStartDate];
        List<Id> toBeProcessedIds = new List<Id>();
        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Cancelled';

        for(reduivy__Individual_Program_Enrollment__c ipe : ipes) {
            for(reduivy__Individual_Pathway__c ipw : ipe.reduivy__Individual_Pathways__r) {
                if(ipw.reduivy__Term_Number__c == 2) {
                    toBeProcessedIds.add(ipw.Id);
                }
            }
        }

        Map<String, Object> params = new Map<String, Object>();
            
        params.put('toBeEnrolledTermId', terms[0].Id);
        params.put('proceedForUnitEnrollment', false);
        params.put('bypassRequirementRules', false);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, terms[0].Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, terms[0].Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, terms[0].Name);

        System.runAs(ADMIN_USER){

            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(JOB_OPERATION, toBeProcessedIds, params);
            JQH_JobManager.queueJob(job, true);

            List<reduivy__Job_Queue__c> jobQueue = [SELECT Id, reduivy__Job_Operation__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c =: JOB_OPERATION];
            
            System.Assert.areEqual(1, jobQueue.size(), 'A Job Queue should be created.');
        }

        System.runAs(ADMIN_USER){
            REDU_JqhClearJobsConfirmationModal_LCTRL.clearJobs(JOB_OPERATION, terms[0].Id);

            List<reduivy__Job_Queue__c> jobQueueResult = [SELECT Id, reduivy__Job_Operation__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c =: JOB_OPERATION];
            
            System.Assert.areEqual(1, jobQueueResult.size(), 'Job Queue should be cleared.');
        }

        Test.stopTest();
    }

    /**
     * @description Test clear jobs with invalid param as admin
    */
    @IsTest
    static void testClearJobWithInvalidParamsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JOB_OPERATION);

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);  

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, true);

            //invalid jobOperation
            try {
                REDU_JqhClearJobsConfirmationModal_LCTRL.clearJobs(null, new List<Id>(ienMaps.keySet())[0]);
            } catch(Exception exp) {
                String expextedError = String.format(Label.Missing_Required_Parameters,
                new List<String>{'jobOperation'});

                System.Assert.areEqual(expextedError, exp.getMessage());
            }

            //invalid id
            try {
                REDU_JqhClearJobsConfirmationModal_LCTRL.clearJobs('Sample_Job', null);
            } catch(Exception exp) {
                String expextedError = String.format(Label.Missing_Required_Parameters,
                new List<String>{'recordId'});

                System.Assert.areEqual(expextedError, exp.getMessage());
            }
        }

        Test.stopTest();
    }
}