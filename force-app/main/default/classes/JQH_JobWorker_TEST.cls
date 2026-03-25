/**
 * @author      WDCi (Lean)
 * @date        Jan 2025
 * @group       Test
 * @description Test class for JQH_JobWorker_QUEUE
 * @changehistory
 * ISS-002219 03-01-2025 Lean - new class
 * ISS-002547 15-07-2025 Lean - Added job group test
 */

@IsTest
public inherited sharing class JQH_JobWorker_TEST {
    
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
     * @description Test add job worker completed successfully as admin
     */
    @IsTest
    static void testJobWorkerCompletedAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put('testGradeUpdate', true);
        params.put('gradeReleaseStatus', IEN_Helper.GRADE_RELEASE_STATUS_RELEASED);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id,
            reduivy__Numerical_Grade__c,
            reduivy__Grade_Release_Status__c       
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);

        for (reduivy__Individual_Enrollment__c ien : ienMaps.values()) {
            if (ien.reduivy__Grade_Release_Status__c != IEN_Helper.GRADE_RELEASE_STATUS_RELEASED && ien.reduivy__Numerical_Grade__c == null) {
                ien.reduivy__Numerical_Grade__c = 90;
            }
        }

        REDU_Database_UTIL.doUpdate(ienMaps.values());

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

        Boolean foundStartLog = false;
        Boolean foundCompletedLog = false;
        Boolean foundRecordSuccessLog = false;

        String startedLogTitle = String.format(Label.Job_Started_Log, new List<String>{jobQueue.reduivy__Job_Operation__c});
        String completedLogTitle = String.format(Label.Job_Completed_Log_Title, new List<String>{jobQueue.reduivy__Job_Operation__c});
        
        Boolean foundJobWorkerStartLog = false;
        Boolean foundJobWorkerCompletedLog = false;

        String jobWorkerStartedLogTitle = String.format(Label.Job_Started_Log, new List<String>{'JQH_JobWorker_QUEUE'});
        String jobWorkerCompletedLogTitle = String.format(Label.Job_Completed_Log_Title, new List<String>{'JQH_JobWorker_QUEUE'});

        for (reduivy__Log__c log : [SELECT Id,
            Name,
            reduivy__Type__c,
            reduivy__Reference__c,
            reduivy__Record_Id__c,
            reduivy__Short_Description__c,
            reduivy__Job_Queue__c,
            reduivy__Job_Queue_Group__c
            FROM reduivy__Log__c
        ]) {
            if (log.reduivy__Job_Queue__c == jobQueue.Id) {
                System.Assert.areEqual(jobQueue.reduivy__Job_Queue_Group__c, log.reduivy__Job_Queue_Group__c, 'Unexpected log: ' + JSON.serialize(log));

                //assert logs that linked to job queue
                if (log.Name == startedLogTitle) {
                    foundStartLog = true;
                } else if (log.Name == completedLogTitle) {
                    foundCompletedLog = true;
                } else if (String.isNotBlank(log.reduivy__Record_Id__c)) {

                    foundRecordSuccessLog = true;

                    System.Assert.areEqual(LOG_Helper.TYPE_INFO, log.reduivy__Type__c);
                    System.Assert.isTrue(ienMaps.containsKey(log.reduivy__Record_Id__c), 'The record is invalid.');
                    System.Assert.areEqual('Success.', log.reduivy__Short_Description__c);
                } else {
                    System.Assert.fail('Unexpected log: ' + JSON.serialize(log));
                }
            } else {
                //assert job worker started/completed logs
                if (log.Name == jobWorkerStartedLogTitle) {
                    foundJobWorkerStartLog = true;
                } else if (log.Name == jobWorkerCompletedLogTitle) {
                    foundJobWorkerCompletedLog = true;
                } else {
                    System.Assert.fail('Unexpected log: ' + JSON.serialize(log));
                }
            }
        }

        System.Assert.isTrue(foundStartLog, 'There should be 1 job handler started log.');
        System.Assert.isTrue(foundCompletedLog, 'There should be 1 job handler completed log.');
        System.Assert.isTrue(foundRecordSuccessLog, 'There should be record success logs.');
        System.Assert.isTrue(foundJobWorkerStartLog, 'There should be 1 job worker started log.');
        System.Assert.isTrue(foundJobWorkerCompletedLog, 'There should be 1 job worker completed log.');
    }

    /**
     * @description Test add job worker completed with error as admin
     */
    @IsTest
    static void testJobWorkerCompletedWithErrorAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put('testGradeUpdate', true);
        params.put('gradeReleaseStatus', IEN_Helper.GRADE_RELEASE_STATUS_RELEASED);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id,
            reduivy__Numerical_Grade__c,
            reduivy__Grade_Release_Status__c       
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);

        for (reduivy__Individual_Enrollment__c ien : ienMaps.values()) {
            if (ien.reduivy__Grade_Release_Status__c != IEN_Helper.GRADE_RELEASE_STATUS_RELEASED && ien.reduivy__Numerical_Grade__c == null) {
                //simulate the bad data here
                ien.reduivy__Numerical_Grade__c = 200;
            }
        }

        REDU_Database_UTIL.doUpdate(ienMaps.values());

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, true);
        }

        Test.stopTest();
        
        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(JQH_Helper.STATUS_FAILED, jobQueue.reduivy__Status__c);
        System.Assert.isNotNull(jobQueue.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areEqual(JQG_Helper.STATUS_FAILED, jobQueue.reduivy__Job_Queue_Group__r.reduivy__Status__c);

        Boolean foundStartLog = false;
        Boolean foundFailedLog = false;
        Boolean foundRecordErrorLog = false;

        String startedLogTitle = String.format(Label.Job_Started_Log, new List<String>{jobQueue.reduivy__Job_Operation__c});
        String failedLogTitle = String.format(Label.Job_Completed_With_Error_Log_Title, new List<String>{jobQueue.reduivy__Job_Operation__c});

        Boolean foundJobWorkerStartLog = false;
        Boolean foundJobWorkerCompletedLog = false;
        
        String jobWorkerStartedLogTitle = String.format(Label.Job_Started_Log, new List<String>{'JQH_JobWorker_QUEUE'});
        String jobWorkerCompletedLogTitle = String.format(Label.Job_Completed_Log_Title, new List<String>{'JQH_JobWorker_QUEUE'});

        String ienLetterGradeFieldLabel = Schema.SObjectType.reduivy__Individual_Enrollment__c.fields.reduivy__Letter_Grade__c.getLabel();
        String ienNumericalGradeFieldLabel = Schema.SObjectType.reduivy__Individual_Enrollment__c.fields.reduivy__Final_Numerical_Grade__c.getLabel();

        String expectedError = String.format(Label.Matching_Grading_Scheme_Failed_For_Grade_Release, new List<String>{SGD_Helper.getObjectLabel(), ienNumericalGradeFieldLabel, ienLetterGradeFieldLabel});

        for (reduivy__Log__c log : [SELECT Id,
            Name,
            reduivy__Type__c,
            reduivy__Reference__c,
            reduivy__Record_Id__c,
            reduivy__Short_Description__c,
            reduivy__Job_Queue__c,
            reduivy__Job_Queue_Group__c
            FROM reduivy__Log__c
        ]) {
            if (log.reduivy__Job_Queue__c == jobQueue.Id) {
                System.Assert.areEqual(jobQueue.reduivy__Job_Queue_Group__c, log.reduivy__Job_Queue_Group__c, 'Unexpected log: ' + JSON.serialize(log));

                //assert logs that linked to job queue
                if (log.Name == startedLogTitle) {
                    foundStartLog = true;
                } else if (log.Name == failedLogTitle) {
                    foundFailedLog = true;
                } else if (String.isNotBlank(log.reduivy__Record_Id__c)) {

                    foundRecordErrorLog = true;

                    System.Assert.areEqual(LOG_Helper.TYPE_ERROR, log.reduivy__Type__c);
                    System.Assert.isTrue(ienMaps.containsKey(log.reduivy__Record_Id__c), 'The record is invalid.');
                    System.Assert.areEqual(expectedError, log.reduivy__Short_Description__c);
                } else {
                    System.Assert.fail('Unexpected log: ' + JSON.serialize(log));
                }
            } else {
                //assert job worker started/completed logs
                if (log.Name == jobWorkerStartedLogTitle) {
                    foundJobWorkerStartLog = true;
                } else if (log.Name == jobWorkerCompletedLogTitle) {
                    foundJobWorkerCompletedLog = true;
                } else {
                    System.Assert.fail('Unexpected log: ' + JSON.serialize(log));
                }
            }
        }

        System.Assert.isTrue(foundStartLog, 'There should be 1 job handler started log.');
        System.Assert.isTrue(foundFailedLog, 'There should be 1 job handler completed with error log.');
        System.Assert.isTrue(foundRecordErrorLog, 'There should be record error logs.');
        System.Assert.isTrue(foundJobWorkerStartLog, 'There should be 1 job worker started log.');
        System.Assert.isTrue(foundJobWorkerCompletedLog, 'There should be 1 job worker completed log.');
    }

    /**
     * @description Test add job worker failed with unhandled exception as admin
     */
    @IsTest
    static void testJobWorkerFailedAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put('testGradeUpdate', true);
        params.put('gradeReleaseStatus', IEN_Helper.GRADE_RELEASE_STATUS_RELEASED);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id,
            reduivy__Numerical_Grade__c,
            reduivy__Grade_Release_Status__c       
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Error_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, true);
        }

        Test.stopTest();
        
        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Error_Job'];

        System.Assert.areEqual(JQH_Helper.STATUS_FAILED, jobQueue.reduivy__Status__c);
        System.Assert.isNotNull(jobQueue.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areEqual(JQG_Helper.STATUS_FAILED, jobQueue.reduivy__Job_Queue_Group__r.reduivy__Status__c);

        Boolean foundStartLog = false;
        Boolean foundFailedLog = false;
        Boolean foundRecordErrorLog = false;

        String startedLogTitle = String.format(Label.Job_Started_Log, new List<String>{jobQueue.reduivy__Job_Operation__c});
        String failedLogTitle = String.format(Label.Job_Completed_With_Error_Log_Title, new List<String>{jobQueue.reduivy__Job_Operation__c});

        Boolean foundJobWorkerStartLog = false;
        Boolean foundJobWorkerCompletedLog = false;
        
        String jobWorkerStartedLogTitle = String.format(Label.Job_Started_Log, new List<String>{'JQH_JobWorker_QUEUE'});
        String jobWorkerCompletedLogTitle = String.format(Label.Job_Completed_Log_Title, new List<String>{'JQH_JobWorker_QUEUE'});

        for (reduivy__Log__c log : [SELECT Id,
            Name,
            reduivy__Type__c,
            reduivy__Reference__c,
            reduivy__Record_Id__c,
            reduivy__Short_Description__c,
            reduivy__Job_Queue__c,
            reduivy__Job_Queue_Group__c
            FROM reduivy__Log__c
        ]) {
            if (log.reduivy__Job_Queue__c == jobQueue.Id) {
                System.Assert.areEqual(jobQueue.reduivy__Job_Queue_Group__c, log.reduivy__Job_Queue_Group__c, 'Unexpected log: ' + JSON.serialize(log));

                if (log.Name == startedLogTitle) {
                    foundStartLog = true;
                } else if (log.Name == failedLogTitle) {
                    foundFailedLog = true;
                    System.Assert.isTrue(log.reduivy__Short_Description__c.contains('This is an exception.'), 'Unexpected error: ' + log.reduivy__Short_Description__c);

                } else if (String.isNotBlank(log.reduivy__Record_Id__c)) {
                    foundRecordErrorLog = true;
                    System.Assert.isTrue(log.reduivy__Short_Description__c.contains('This is an exception.'), 'Unexpected error: ' + log.reduivy__Short_Description__c);

                } else {
                    System.Assert.fail('Unexpected log: ' + JSON.serialize(log));
                }
            } else {
                //assert job worker started/completed logs
                if (log.Name == jobWorkerStartedLogTitle) {
                    foundJobWorkerStartLog = true;
                } else if (log.Name == jobWorkerCompletedLogTitle) {
                    foundJobWorkerCompletedLog = true;
                } else {
                    System.Assert.fail('Unexpected log: ' + JSON.serialize(log));
                }
            }
        }

        System.Assert.isTrue(foundStartLog, 'There should be 1 job handler started log.');
        System.Assert.isTrue(foundFailedLog, 'There should be 1 job handler completed with error log.');
        System.Assert.isTrue(foundRecordErrorLog, 'There should be record error logs.');
        System.Assert.isTrue(foundJobWorkerStartLog, 'There should be 1 job worker started log.');
        System.Assert.isTrue(foundJobWorkerCompletedLog, 'There should be 1 job worker completed log.');
    }

    /**
     * @description Test add job worker completed successfully with warning as admin
     */
    @IsTest
    static void testJobWorkerCompletedWithWarningAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put('testGradeUpdate', true);
        params.put('gradeReleaseStatus', IEN_Helper.GRADE_RELEASE_STATUS_RELEASED);
        params.put('warningtest', true);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id,
            reduivy__Numerical_Grade__c,
            reduivy__Grade_Release_Status__c       
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Error_Job', new List<Id>(ienMaps.keySet()), params);
            JQH_JobManager.queueJob(job, true);
        }

        Test.stopTest();
        
        reduivy__Job_Queue__c jobQueue = [SELECT Id, Name, reduivy__Job_Operation__c, reduivy__Status__c, reduivy__Job_Queue_Group__c, reduivy__Job_Queue_Group__r.reduivy__Status__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Error_Job'];

        System.Assert.areEqual(JQH_Helper.STATUS_COMPLETED, jobQueue.reduivy__Status__c);
        System.Assert.isNotNull(jobQueue.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
        System.Assert.areEqual(JQG_Helper.STATUS_COMPLETED, jobQueue.reduivy__Job_Queue_Group__r.reduivy__Status__c);

        Boolean foundStartLog = false;
        Boolean foundCompletedLog = false;
        Boolean foundRecordWarningLog = false;

        String startedLogTitle = String.format(Label.Job_Started_Log, new List<String>{jobQueue.reduivy__Job_Operation__c});
        String completedLogTitle = String.format(Label.Job_Completed_Log_Title, new List<String>{jobQueue.reduivy__Job_Operation__c});
        
        Boolean foundJobWorkerStartLog = false;
        Boolean foundJobWorkerCompletedLog = false;

        String jobWorkerStartedLogTitle = String.format(Label.Job_Started_Log, new List<String>{'JQH_JobWorker_QUEUE'});
        String jobWorkerCompletedLogTitle = String.format(Label.Job_Completed_Log_Title, new List<String>{'JQH_JobWorker_QUEUE'});

        for (reduivy__Log__c log : [SELECT Id,
            Name,
            reduivy__Type__c,
            reduivy__Reference__c,
            reduivy__Record_Id__c,
            reduivy__Short_Description__c,
            reduivy__Job_Queue__c,
            reduivy__Job_Queue_Group__c
            FROM reduivy__Log__c
        ]) {
            if (log.reduivy__Job_Queue__c == jobQueue.Id) {
                System.Assert.areEqual(jobQueue.reduivy__Job_Queue_Group__c, log.reduivy__Job_Queue_Group__c, 'Unexpected log: ' + JSON.serialize(log));
                
                //assert logs that linked to job queue
                if (log.Name == startedLogTitle) {
                    foundStartLog = true;
                } else if (log.Name == completedLogTitle) {
                    foundCompletedLog = true;
                } else if (String.isNotBlank(log.reduivy__Record_Id__c)) {

                    foundRecordWarningLog = true;

                    System.Assert.areEqual(LOG_Helper.TYPE_WARNING, log.reduivy__Type__c);
                    System.Assert.isTrue(ienMaps.containsKey(log.reduivy__Record_Id__c), 'The record is invalid.');
                    System.Assert.areEqual('This is a warning test.', log.reduivy__Short_Description__c);
                } else {
                    System.Assert.fail('Unexpected log: ' + JSON.serialize(log));
                }
            } else {
                //assert job worker started/completed logs
                if (log.Name == jobWorkerStartedLogTitle) {
                    foundJobWorkerStartLog = true;
                } else if (log.Name == jobWorkerCompletedLogTitle) {
                    foundJobWorkerCompletedLog = true;
                } else {
                    System.Assert.fail('Unexpected log: ' + JSON.serialize(log));
                }
            }
        }

        System.Assert.isTrue(foundStartLog, 'There should be 1 job handler started log.');
        System.Assert.isTrue(foundCompletedLog, 'There should be 1 job handler completed log.');
        System.Assert.isTrue(foundRecordWarningLog, 'There should be record warning logs.');
        System.Assert.isTrue(foundJobWorkerStartLog, 'There should be 1 job worker started log.');
        System.Assert.isTrue(foundJobWorkerCompletedLog, 'There should be 1 job worker completed log.');
    }
}