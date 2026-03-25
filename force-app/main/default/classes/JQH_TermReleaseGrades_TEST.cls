/**
 * @author      WDCi (XiRouh)
 * @date        March 2025
 * @group       Test Class
 * @description 
 * @changehistory
 * ISS-2311 07-03-2025 XiRouh - Test Class for JQH_TermReleaseGrades_GENERATOR And JQH_TermReleaseGrades_HANDLER
 */
@IsTest
public with sharing class JQH_TermReleaseGrades_TEST {
    private static final String JOB_OPERATION = 'Term_Grade_Release';
    private static final String GRADE_RELEASE_STATUS = IEN_Helper.getGradeReleasedStatuses()[0];

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
			testFactory.initStudentData(IEN_Helper.getApiName(), true);

            Test.stopTest();
        }
    }
    
    /**
     * @description Test the Release Grades job through the Generator
     */
    @IsTest
    static void testReleaseGradesJobFromGenerator(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();
        
            Map<String, Object> params = new Map<String, Object>();
            params.put('selectedGradeReleaseStatus', GRADE_RELEASE_STATUS);
            params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, ''));

            Map<Id, reduivy__Study_Offering__c> sofMaps = new Map<Id, reduivy__Study_Offering__c>([
                SELECT Id 
                FROM reduivy__Study_Offering__c
            ]);

            List<reduivy__Individual_Enrollment__c> ienList = [
                SELECT Id, reduivy__Grade_Release_Status__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Study_Offering__c IN :sofMaps.keySet()
            ];

            List<Id> ienIds = new List<Id>();
            for (reduivy__Individual_Enrollment__c ien : ienList){
                System.Assert.areNotEqual(GRADE_RELEASE_STATUS, ien.reduivy__Grade_Release_Status__c,'Should not have released grades yet');
                ienIds.add(ien.Id);
            }

            JQH_JobManager.executeJobGenerator(JOB_OPERATION, new List<Id>(sofMaps.keySet()), params, true);

            Test.stopTest();

            //Check Generator ran
            Integer generatorJobCount = [SELECT COUNT() 
                FROM AsyncApexJob
                WHERE JobType = 'Queueable'
                AND ApexClass.Name = 'JQH_JobGenerator_QUEUE'
                AND Status = 'Completed'
                AND CreatedById =: ADMIN_USER.Id
                WITH USER_MODE
            ];
            System.Assert.areEqual(1, generatorJobCount);

            //Check Job Queue records were created
            List<reduivy__Job_Queue__c> jobQueueCheckList = [
                SELECT Id, reduivy__Job_Handler_Record_Ids__c
                FROM reduivy__Job_Queue__c
                WHERE reduivy__Job_Operation__c = :JOB_OPERATION
            ];
            System.Assert.isTrue(jobQueueCheckList.size() > 0, 'No Job Queue records created');
            //Check all individual enrollment are set to be updated
            Integer jqCcIdsCount = 0;
            for (reduivy__Job_Queue__c jq : jobQueueCheckList){
                jqCcIdsCount += jq.reduivy__Job_Handler_Record_Ids__c.split(';').size();
            }
            System.Assert.areEqual(ienIds.size(), jqCcIdsCount, 'Incorrect number of CCs planned for update');
            
            //Individual Enrollment won't have updated because test limits subsequent async calls
        }
    }

    /**
     * @description Test the Release Grades job through the Handler
     */
    @IsTest
    static void testReleaseGradesJobFromHandler(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            //Get 1st Term
            List<reduivy__Study_Term__c> term = [
                SELECT Id, Name
                FROM reduivy__Study_Term__c
                ORDER BY reduivy__Start_Date__c ASC
                LIMIT 1
            ];
            
            Map<String, Object> params = new Map<String, Object>();
            params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, term[0].Id));
            params.put('selectedGradeReleaseStatus', GRADE_RELEASE_STATUS);

            Map<Id, reduivy__Study_Offering__c> sofMaps = new Map<Id, reduivy__Study_Offering__c>([
                SELECT Id 
                FROM reduivy__Study_Offering__c
            ]);

            List<reduivy__Individual_Enrollment__c> ienList = [
                SELECT Id, reduivy__Grade_Release_Status__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Study_Offering__c IN :sofMaps.keySet()
            ];

            List<reduivy__Study_Grade_Setting__c> sgsList = [SELECT Id FROM reduivy__Study_Grade_Setting__c LIMIT 1];
            List<reduivy__Study_Grading_Scheme__c> sgdList = [SELECT Id, reduivy__For_Fail_Absent__c FROM reduivy__Study_Grading_Scheme__c WHERE reduivy__Study_Grade_Setting__c = :sgsList[0].Id AND reduivy__Grade_Result__c = 'Fail' LIMIT 1];

            sgdList[0].reduivy__For_Fail_Absent__c = true;
            update sgdList;

            List<reduivy__Individual_Enrollment__c> ienToBeUpdate = new List<reduivy__Individual_Enrollment__c>();

            List<Id> ienIds = new List<Id>();
            for (reduivy__Individual_Enrollment__c ien : ienList){
                System.Assert.areNotEqual(GRADE_RELEASE_STATUS, ien.reduivy__Grade_Release_Status__c,'Should not have released grades yet');

                ienToBeUpdate.add(new reduivy__Individual_Enrollment__c(
                    Id = ien.Id,
                    reduivy__Numerical_Grade__c = 60,
                    reduivy__Study_Grade_Setting__c = sgsList[0].Id
                ));

                ienIds.add(ien.Id);
            }

            update ienToBeUpdate;
            
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(JOB_OPERATION, ienIds, params);
            JQH_JobManager.queueJob(job, true);

            Test.stopTest();
            
            //Check individual enrollment were updated
            List<reduivy__Individual_Enrollment__c> ienCheckList = [
                SELECT Id, reduivy__Grade_Release_Status__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Study_Offering__c IN :sofMaps.keySet()
            ];
            for (reduivy__Individual_Enrollment__c ien : ienCheckList){
                System.Assert.areEqual(GRADE_RELEASE_STATUS, ien.reduivy__Grade_Release_Status__c,'Should have released grades');
            }

            List<reduivy__Job_Queue__c> jobQueueCheckList = [
                SELECT Id, reduivy__Number_of_Success_Records__c
                FROM reduivy__Job_Queue__c
                WHERE reduivy__Job_Operation__c = :JOB_OPERATION
            ];

            System.Assert.areEqual(ienCheckList.size(), jobQueueCheckList[0].reduivy__Number_of_Success_Records__c, 'All IENs should have released grades');
        }
    }

    /**
     * @description Test the Release Grades job through the Handler (With Already Released Warning)
     */
    @IsTest
    static void testReleaseGradesJobFromHandlerWithAlreadyReleasedWarning(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            //Get 1st Term
            List<reduivy__Study_Term__c> term = [
                SELECT Id, Name
                FROM reduivy__Study_Term__c
                ORDER BY reduivy__Start_Date__c ASC
                LIMIT 1
            ];
            
            Map<String, Object> params = new Map<String, Object>();
            params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, term[0].Id));
            params.put('selectedGradeReleaseStatus', GRADE_RELEASE_STATUS);

            Map<Id, reduivy__Study_Offering__c> sofMaps = new Map<Id, reduivy__Study_Offering__c>([
                SELECT Id 
                FROM reduivy__Study_Offering__c
            ]);

            List<reduivy__Individual_Enrollment__c> ienList = [
                SELECT Id, reduivy__Grade_Release_Status__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Study_Offering__c IN :sofMaps.keySet()
            ];

            List<reduivy__Study_Grade_Setting__c> sgsList = [SELECT Id FROM reduivy__Study_Grade_Setting__c LIMIT 1];
            List<reduivy__Study_Grading_Scheme__c> sgdList = [SELECT Id, reduivy__For_Fail_Absent__c FROM reduivy__Study_Grading_Scheme__c WHERE reduivy__Study_Grade_Setting__c = :sgsList[0].Id AND reduivy__Grade_Result__c = 'Fail' LIMIT 1];

            sgdList[0].reduivy__For_Fail_Absent__c = true;
            update sgdList;

            List<reduivy__Individual_Enrollment__c> ienToBeUpdate = new List<reduivy__Individual_Enrollment__c>();

            List<Id> ienIds = new List<Id>();
            for (reduivy__Individual_Enrollment__c ien : ienList){
                System.Assert.areNotEqual(GRADE_RELEASE_STATUS, ien.reduivy__Grade_Release_Status__c,'Should not have released grades yet');

                ienToBeUpdate.add(new reduivy__Individual_Enrollment__c(
                    Id = ien.Id,
                    reduivy__Numerical_Grade__c = 60,
                    reduivy__Study_Grade_Setting__c = sgsList[0].Id,
                    reduivy__Grade_Release_Status__c = GRADE_RELEASE_STATUS
                ));

                ienIds.add(ien.Id);
            }

            update ienToBeUpdate;

            ienList = [
                SELECT Id, reduivy__Grade_Release_Status__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Study_Offering__c IN :sofMaps.keySet()
            ];

            for (reduivy__Individual_Enrollment__c ien : ienList){
                System.Assert.areEqual(GRADE_RELEASE_STATUS, ien.reduivy__Grade_Release_Status__c,'Should have released grades');
            }
            
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(JOB_OPERATION, ienIds, params);
            JQH_JobManager.queueJob(job, true);

            Test.stopTest();

            List<reduivy__Job_Queue__c> jobQueueCheckList = [
                SELECT Id, reduivy__Number_of_Warning_Records__c
                FROM reduivy__Job_Queue__c
                WHERE reduivy__Job_Operation__c = :JOB_OPERATION
            ];

            System.Assert.areEqual(ienList.size(), jobQueueCheckList[0].reduivy__Number_of_Warning_Records__c, 'All IENs should have added into warning list');

            List<reduivy__Log__c> logsList = [SELECT Id, reduivy__Short_Description__c FROM reduivy__Log__c WHERE reduivy__Record_Id__c IN :ienIds];
            System.Assert.areEqual(ienList.size(), logsList.size(), 'All of the IENs should be added to the warning list because their grades have already been released.');
            
            for (reduivy__Log__c log : logsList) {
                System.Assert.areEqual(log.reduivy__Short_Description__c, String.format(Label.Term_Grade_Release_IEN_Already_In_Selected_Release_Status, new List<String>{GRADE_RELEASE_STATUS}));
            }
        }
    }

    /**
     * @description Test the Release Grades job through the Handler (With Grade Result To Be Skipped Warning)
     */
    @IsTest
    static void testReleaseGradesJobFromHandlerWithGRToBeSkippedWarning(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            //Get 1st Term
            List<reduivy__Study_Term__c> term = [
                SELECT Id, Name
                FROM reduivy__Study_Term__c
                ORDER BY reduivy__Start_Date__c ASC
                LIMIT 1
            ];
            
            Map<String, Object> params = new Map<String, Object>();
            params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, term[0].Id));
            params.put('selectedGradeReleaseStatus', GRADE_RELEASE_STATUS);

            Map<Id, reduivy__Study_Offering__c> sofMaps = new Map<Id, reduivy__Study_Offering__c>([
                SELECT Id 
                FROM reduivy__Study_Offering__c
            ]);

            List<reduivy__Individual_Enrollment__c> ienList = [
                SELECT Id, reduivy__Grade_Release_Status__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Study_Offering__c IN :sofMaps.keySet()
            ];

            List<reduivy__Study_Grade_Setting__c> sgsList = [SELECT Id FROM reduivy__Study_Grade_Setting__c LIMIT 1];
            List<reduivy__Study_Grading_Scheme__c> sgdList = [SELECT Id, reduivy__For_Fail_Absent__c FROM reduivy__Study_Grading_Scheme__c WHERE reduivy__Study_Grade_Setting__c = :sgsList[0].Id AND reduivy__Grade_Result__c = 'Fail' LIMIT 1];

            sgdList[0].reduivy__For_Fail_Absent__c = true;
            update sgdList;

            List<reduivy__Individual_Enrollment__c> ienToBeUpdate = new List<reduivy__Individual_Enrollment__c>();

            List<Id> ienIds = new List<Id>();
            for (reduivy__Individual_Enrollment__c ien : ienList){
                System.Assert.areNotEqual(GRADE_RELEASE_STATUS, ien.reduivy__Grade_Release_Status__c,'Should not have released grades yet');

                ienToBeUpdate.add(new reduivy__Individual_Enrollment__c(
                    Id = ien.Id,
                    reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_RPL,
                    reduivy__Study_Grade_Setting__c = sgsList[0].Id,
                    reduivy__Numerical_Grade__c = 60,
                    reduivy__Credit_Transfer_Received__c = true
                ));

                ienIds.add(ien.Id);
            }

            update ienToBeUpdate;

            ienList = [
                SELECT Id, reduivy__Grade_Release_Status__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Study_Offering__c IN :sofMaps.keySet()
            ];

            for (reduivy__Individual_Enrollment__c ien : ienList){
                System.Assert.areNotEqual(GRADE_RELEASE_STATUS, ien.reduivy__Grade_Release_Status__c,'Should have not released grades yet');
            }
            
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(JOB_OPERATION, ienIds, params);
            JQH_JobManager.queueJob(job, true);

            Test.stopTest();

            List<reduivy__Job_Queue__c> jobQueueCheckList = [
                SELECT Id, reduivy__Number_of_Warning_Records__c
                FROM reduivy__Job_Queue__c
                WHERE reduivy__Job_Operation__c = :JOB_OPERATION
            ];

            System.Assert.areEqual(ienList.size(), jobQueueCheckList[0].reduivy__Number_of_Warning_Records__c, 'All IENs should have added into warning list');

            List<reduivy__Log__c> logsList = [SELECT Id, reduivy__Short_Description__c FROM reduivy__Log__c WHERE reduivy__Record_Id__c IN :ienIds];
            System.Assert.areEqual(ienList.size(), logsList.size(), 'All of the IENs should be added to the warning list because are all originated from credit transfer application.');
            
            List<String> ienGradeResultsToBeSkipped = IEN_Helper.getGradeResultBypassStatuses();

            DescribeSObjectResult describe = SObjectType.reduivy__Credit_Transfer_Application__c;
            String ctaObjectLabel = describe.getLabel();

            for (reduivy__Log__c log : logsList) {
                System.Assert.areEqual(log.reduivy__Short_Description__c, String.format(Label.Term_Grade_Release_IEN_Originates_From_Credit_Transfer_Application,
                    new List<String>{ctaObjectLabel}));
            }
        }
    }

    /**
     * @description Test the Release Grades job through the Handler (With Fail)
     */
    @IsTest
    static void testReleaseGradesJobFromHandlerWithFail(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            //Get 1st Term
            List<reduivy__Study_Term__c> term = [
                SELECT Id, Name
                FROM reduivy__Study_Term__c
                ORDER BY reduivy__Start_Date__c ASC
                LIMIT 1
            ];
            
            Map<String, Object> params = new Map<String, Object>();
            params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, term[0].Id));
            params.put('selectedGradeReleaseStatus', GRADE_RELEASE_STATUS);

            Map<Id, reduivy__Study_Offering__c> sofMaps = new Map<Id, reduivy__Study_Offering__c>([
                SELECT Id 
                FROM reduivy__Study_Offering__c
            ]);

            List<reduivy__Individual_Enrollment__c> ienList = [
                SELECT Id, reduivy__Grade_Release_Status__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Study_Offering__c IN :sofMaps.keySet()
            ];

            List<reduivy__Individual_Enrollment__c> ienToBeUpdate = new List<reduivy__Individual_Enrollment__c>();

            List<Id> ienIds = new List<Id>();
            for (reduivy__Individual_Enrollment__c ien : ienList){
                System.Assert.areNotEqual(GRADE_RELEASE_STATUS, ien.reduivy__Grade_Release_Status__c,'Should not have released grades yet');

                ienToBeUpdate.add(new reduivy__Individual_Enrollment__c(
                    Id = ien.Id,
                    reduivy__Numerical_Grade__c = null,
                    reduivy__Study_Grade_Setting__c = null
                ));

                ienIds.add(ien.Id);
            }

            update ienToBeUpdate;
            
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(JOB_OPERATION, ienIds, params);
            JQH_JobManager.queueJob(job, true);

            Test.stopTest();
            
            List<reduivy__Job_Queue__c> jobQueueCheckList = [
                SELECT Id, reduivy__Number_of_Error_Records__c
                FROM reduivy__Job_Queue__c
                WHERE reduivy__Job_Operation__c = :JOB_OPERATION
            ];

            System.Assert.areEqual(ienList.size(), jobQueueCheckList[0].reduivy__Number_of_Error_Records__c, 'All IENs should have added into error list');

            List<reduivy__Log__c> logsList = [SELECT Id FROM reduivy__Log__c WHERE reduivy__Record_Id__c IN :ienIds];
            System.Assert.areEqual(ienList.size(), logsList.size(), 'All IENs should be added to the error list due to the numerical grade not being populated and the study grade setting not being found.');
        }
    }
}