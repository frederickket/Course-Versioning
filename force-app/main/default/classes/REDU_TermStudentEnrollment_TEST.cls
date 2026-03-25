/**
 * @author      WDCi (XiRouh)
 * @date        Feb 2025
 * @group       Term Student Enrollment
 * @description Test class for REDU_TermStudentEnrollment_LCTRL
 * @changehistory
 * ISS-002229 14-02-2025 XiRouh - new class
 * ISS-002547 16-07-2025 Lean - Change to use job queue group
 */
@isTest
public inherited sharing class REDU_TermStudentEnrollment_TEST {

    private static final String JOB_OPERATION = 'Term_Student_Enrollment';

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

        	testFactory.initMasterData(null);
            testFactory.initOfferingData(null);
			testFactory.initStudentData(IPE_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test getJobQueueData() as admin
     */
    @IsTest
    static void testGetJobQueueDataAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER){
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

            String jobOperationContext = JQH_Helper.getJobOperationContext(JOB_OPERATION, terms[0].Id);

            Map<String, Object> params = new Map<String, Object>();
            params.put('toBeEnrolledTermId', terms[0].Id);
            params.put('proceedForUnitEnrollment', false);
            params.put('bypassRequirementRules', false);
            params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
            params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, jobOperationContext);
            params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, terms[0].Id);
            params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, terms[0].Name);

            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(JOB_OPERATION, toBeProcessedIds, params);
            JQH_JobManager.queueJob(job, true);

            List<reduivy__Job_Queue__c> jobQueue = [SELECT Id, reduivy__Job_Operation__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation_Context__c =: jobOperationContext];
            
            System.Assert.areEqual(1, jobQueue.size(), 'A Job Queue should be created.');
            System.Assert.isNotNull(jobQueue[0].reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');

            String jobQueueGroupFields = 'Name;CreatedDate;reduivy__Total_Records__c;reduivy__Success_Records__c;reduivy__Error_Records__c;reduivy__Status__c';
            String jobQueueGroupStatuses = 'Pending;Processing;Completed;Failed';

            REDU_LightningResponse response = REDU_TermStudentEnrollment_LCTRL.getJobQueueData(JOB_OPERATION, terms[0].Id, jobQueueGroupFields, jobQueueGroupStatuses);

            // Verify response
            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, Object> finalMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap.containsKey('jobQueueGroupRecords'), 'Response should contain jobQueueGroupRecords key');            
            
            // Verify records
            List<Object> recordsMapObj = (List<Object>) finalMap.get('jobQueueGroupRecords');
            System.Assert.isFalse(recordsMapObj.isEmpty(), 'records map should not be empty');

            Test.stopTest();
        }
    }

    /**
     * @description Test getJobQueueData() as faculty
     */
    @IsTest
    static void testGetJobQueueDataAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

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

        String jobOperationContext = JQH_Helper.getJobOperationContext(JOB_OPERATION, terms[0].Id);

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', terms[0].Id);
        params.put('proceedForUnitEnrollment', false);
        params.put('bypassRequirementRules', false);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, jobOperationContext);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, terms[0].Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, terms[0].Name);

        JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(JOB_OPERATION, toBeProcessedIds, params);
        JQH_JobManager.queueJob(job, true);

        List<reduivy__Job_Queue__c> jobQueue = [SELECT Id, reduivy__Job_Operation__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation_Context__c =: jobOperationContext];
            
        System.Assert.areEqual(1, jobQueue.size(), 'A Job Queue should be created.');
        System.Assert.isNotNull(jobQueue[0].reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        
        System.runAs(FACULTY_USER){
            String jobQueueGroupFields = 'Name;CreatedDate;reduivy__Total_Records__c;reduivy__Success_Records__c;reduivy__Error_Records__c;reduivy__Status__c';
            String jobQueueGroupStatuses = 'Pending;Processing;Completed;Failed';

            try {
                REDU_TermStudentEnrollment_LCTRL.getJobQueueData(JOB_OPERATION, terms[0].Id, jobQueueGroupFields, jobQueueGroupStatuses);
                System.Assert.fail('Expected an Exception for Insufficient access');
            } catch (Exception e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains('Insufficient'), 'Error message should contain the expected text');
            }
        }
    }

    /**
     * @description Test getJobQueueData() as student
     */
    @IsTest
    static void testGetJobQueueDataAsStudent(){
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

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

        String jobOperationContext = JQH_Helper.getJobOperationContext(JOB_OPERATION, terms[0].Id);

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', terms[0].Id);
        params.put('proceedForUnitEnrollment', false);
        params.put('bypassRequirementRules', false);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, jobOperationContext);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, terms[0].Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, terms[0].Name);

        JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(JOB_OPERATION, toBeProcessedIds, params);
        JQH_JobManager.queueJob(job, true);

        List<reduivy__Job_Queue__c> jobQueue = [SELECT Id, reduivy__Job_Operation__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation_Context__c =: jobOperationContext];
            
        System.Assert.areEqual(1, jobQueue.size(), 'A Job Queue should be created.');
        System.Assert.isNotNull(jobQueue[0].reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        
        System.runAs(reduStudent){
            String jobQueueGroupFields = 'Name;CreatedDate;reduivy__Total_Records__c;reduivy__Success_Records__c;reduivy__Error_Records__c;reduivy__Status__c';
            String jobQueueGroupStatuses = 'Pending;Processing;Completed;Failed';

            try {
                REDU_TermStudentEnrollment_LCTRL.getJobQueueData(JOB_OPERATION, terms[0].Id, jobQueueGroupFields, jobQueueGroupStatuses);
                System.Assert.fail('Expected an Exception for Insufficient access');
            } catch (Exception e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains('Insufficient'), 'Error message should contain the expected text');
            }
        }
    }

    /**
     * @description Negative Test for getJobQueueData()
     */
    @IsTest
    static void testgetJobQueueDataWithInvalidParams() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
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

            String jobOperationContext = JQH_Helper.getJobOperationContext(JOB_OPERATION, terms[0].Id);

            Map<String, Object> params = new Map<String, Object>();
            params.put('toBeEnrolledTermId', terms[0].Id);
            params.put('proceedForUnitEnrollment', false);
            params.put('bypassRequirementRules', false);
            params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
            params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, jobOperationContext);
            params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, terms[0].Id);
            params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, terms[0].Name);

            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(JOB_OPERATION, toBeProcessedIds, params);
            JQH_JobManager.queueJob(job, true);

            List<reduivy__Job_Queue__c> jobQueue = [SELECT Id, reduivy__Job_Operation__c, reduivy__Job_Queue_Group__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation_Context__c =: jobOperationContext];
            
            System.Assert.areEqual(1, jobQueue.size(), 'A Job Queue should be created.');
            System.Assert.isNotNull(jobQueue[0].reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');

            String jobQueueGroupFields = 'Name;CreatedDate;reduivy__Total_Records__c;reduivy__Success_Records__c;reduivy__Error_Records__c;reduivy__Status__c';
            String jobQueueGroupStatuses = 'Pending;Processing;Completed;Failed';

            //Test for blank termId
            try {
                REDU_TermStudentEnrollment_LCTRL.getJobQueueData(JOB_OPERATION, null, jobQueueGroupFields, jobQueueGroupStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank termId');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'RecordId'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank jobQueueGroupFields
            try {
                REDU_TermStudentEnrollment_LCTRL.getJobQueueData(JOB_OPERATION, terms[0].Id, null, jobQueueGroupStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank jobQueueGroupFields');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'jobQueueGroupFields'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank jobQueueGroupStatuses
            try {
                REDU_TermStudentEnrollment_LCTRL.getJobQueueData(JOB_OPERATION, terms[0].Id, jobQueueGroupFields, null);
                System.Assert.fail('Expected an AuraHandledException for blank jobQueueGroupStatuses');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'jobQueueGroupStatuses'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank operationContext
            try {
                REDU_TermStudentEnrollment_LCTRL.getJobQueueData(null, terms[0].Id, jobQueueGroupFields, jobQueueGroupStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank jobOperation');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'jobOperation'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }
            
            Test.stopTest();
        }
    }
}