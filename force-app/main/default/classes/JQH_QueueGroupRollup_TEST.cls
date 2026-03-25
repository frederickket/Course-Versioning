/**
 * @author      WDCi (Lean)
 * @date        July 2025
 * @group       Test
 * @description Test class for JQH_QueueGroupRollup_EXE
 * @changehistory
 * ISS-002547 10-07-2025 Lean - new trigger
 */

@IsTest
public inherited sharing class JQH_QueueGroupRollup_TEST {
    
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
     * @description Test pending jobs
     */
    @IsTest
    static void testInsertPendingJobsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
                SELECT Id FROM reduivy__Individual_Enrollment__c
                WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
            ]);
            
            List<reduivy__Job_Queue_Group__c> jobQueueGroups = new List<reduivy__Job_Queue_Group__c>();
            List<reduivy__Job_Queue__c> jobQueues = new List<reduivy__Job_Queue__c>();

            //create job queue group
            for (Integer i = 0; i < 10; i ++) {
                String jobQueueGroupCode = 'Sample_Job_' + i;

                reduivy__Job_Queue_Group__c newJqg = REDU_TestData_UTIL.newJobQueueGroup(
                    jobQueueGroupCode,
                    jobQueueGroupCode
                );

                jobQueueGroups.add(newJqg);
            }

            REDU_Database_UTIL.doInsert(jobQueueGroups);
            
            //create number of job queues based on the job queue group index e.g., job queue group at index 3 would have 3 job queues
            Integer index = 1;
            for (reduivy__Job_Queue_Group__c jqg : jobQueueGroups) {
                for (Integer i = 0; i < index; i ++) {
                    String jobQueueCode = jqg.reduivy__Job_Operation_Context__c + '_' + i;

                    reduivy__Job_Queue__c newJqh = REDU_TestData_UTIL.newJobQueue(
                        jobQueueCode,
                        jqg.Id,
                        jqg.reduivy__Job_Operation_Context__c,
                        'Sample_Job',
                        null,
                        null,
                        JQH_Helper.serializeRecordIds(ienMaps.keySet()),
                        null,
                        null,
                        null,
                        null,
                        JQH_Helper.STATUS_PENDING
                    );

                    jobQueues.add(newJqh);
                }

                index ++;
            }

            REDU_Database_UTIL.doInsert(jobQueues);

            Integer counter = 1;
            for (reduivy__Job_Queue_Group__c jqg : [SELECT Id,
                reduivy__Total_Jobs__c,
                reduivy__Completed_Jobs__c,
                reduivy__Failed_Jobs__c,
                reduivy__Cancelled_Jobs__c,
                reduivy__Total_Records__c,
                reduivy__Success_Records__c,
                reduivy__Error_Records__c,
                reduivy__Warning_Records__c,
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Status__c,
                (
                    SELECT Id, 
                    reduivy__Number_of_Records__c,
                    reduivy__Number_of_Success_Records__c,
                    reduivy__Number_of_Error_Records__c,
                    reduivy__Number_of_Warning_Records__c,
                    reduivy__Status__c,
                    reduivy__Start_Datetime__c,
                    reduivy__End_Datetime__c
                    FROM reduivy__Job_Queues__r
                )
                FROM reduivy__Job_Queue_Group__c
                WHERE Id IN: jobQueueGroups
            ]) {

                Decimal totalJobs = 0;
                Decimal completedJobs = 0;
                Decimal cancelledJobs = 0;
                Decimal failedJobs = 0;

                Decimal totalRecords = 0;
                Decimal successRecords = 0;
                Decimal errorRecords = 0;
                Decimal warningRecords = 0;
                Datetime firstStart;
                Datetime lastEnd;

                for (reduivy__Job_Queue__c jqh : jqg.reduivy__Job_Queues__r) {
                    totalJobs ++;
                    totalRecords += (jqh.reduivy__Number_of_Records__c ?? 0);

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED) {
                        completedJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_CANCELLED) {
                        cancelledJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        failedJobs ++;
                    }

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED || jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        //we won't include the record count for success, warning, error if the job is cancelled.
                        successRecords += (jqh.reduivy__Number_of_Success_Records__c ?? 0);
                        errorRecords += (jqh.reduivy__Number_of_Error_Records__c ?? 0);
                        warningRecords += (jqh.reduivy__Number_of_Warning_Records__c ?? 0);

                        if (firstStart == null || firstStart > jqh.reduivy__Start_Datetime__c) {
                            firstStart = jqh.reduivy__Start_Datetime__c;
                        }

                        if (lastEnd == null || lastEnd < jqh.reduivy__End_Datetime__c) {
                            lastEnd = jqh.reduivy__End_Datetime__c;
                        }
                    }
                }

                System.Assert.areEqual(counter, jqg.reduivy__Job_Queues__r.size());
                System.Assert.areEqual(totalJobs, jqg.reduivy__Total_Jobs__c);
                System.Assert.areEqual(completedJobs, jqg.reduivy__Completed_Jobs__c);
                System.Assert.areEqual(failedJobs, jqg.reduivy__Failed_Jobs__c);
                System.Assert.areEqual(cancelledJobs, jqg.reduivy__Cancelled_Jobs__c);
                System.Assert.areEqual(totalRecords, jqg.reduivy__Total_Records__c);
                System.Assert.areEqual(successRecords, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(errorRecords, jqg.reduivy__Error_Records__c);
                System.Assert.areEqual(warningRecords, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(firstStart, jqg.reduivy__Start_Datetime__c);
                System.Assert.areEqual(lastEnd, jqg.reduivy__End_Datetime__c);
                System.Assert.areEqual(JQG_Helper.STATUS_PENDING, jqg.reduivy__Status__c);                

                System.Assert.areEqual(0, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Error_Records__c);

                counter ++;
            }

            System.Assert.areEqual(index, counter, 'The number of job queue groups does not match.');
        }

        Test.stopTest();

    }

    /**
     * @description Test processing jobs
     */
    @IsTest
    static void testInsertProcessingJobsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
                SELECT Id FROM reduivy__Individual_Enrollment__c
                WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
            ]);
            
            List<reduivy__Job_Queue_Group__c> jobQueueGroups = new List<reduivy__Job_Queue_Group__c>();
            List<reduivy__Job_Queue__c> jobQueues = new List<reduivy__Job_Queue__c>();

            //create job queue group
            for (Integer i = 0; i < 10; i ++) {
                String jobQueueGroupCode = 'Sample_Job_' + i;

                reduivy__Job_Queue_Group__c newJqg = REDU_TestData_UTIL.newJobQueueGroup(
                    jobQueueGroupCode,
                    jobQueueGroupCode
                );

                jobQueueGroups.add(newJqg);
            }

            REDU_Database_UTIL.doInsert(jobQueueGroups);
            
            //create number of job queues based on the job queue group index e.g., job queue group at index 3 would have 3 job queues
            Integer index = 1;
            for (reduivy__Job_Queue_Group__c jqg : jobQueueGroups) {
                for (Integer i = 0; i < index; i ++) {
                    String jobQueueCode = jqg.reduivy__Job_Operation_Context__c + '_' + i;

                    reduivy__Job_Queue__c newJqh = REDU_TestData_UTIL.newJobQueue(
                        jobQueueCode,
                        jqg.Id,
                        jqg.reduivy__Job_Operation_Context__c,
                        'Sample_Job',
                        null,
                        null,
                        JQH_Helper.serializeRecordIds(ienMaps.keySet()),
                        null,
                        null,
                        null,
                        null,
                        JQH_Helper.STATUS_PROCESSING
                    );

                    jobQueues.add(newJqh);
                }

                index ++;
            }

            REDU_Database_UTIL.doInsert(jobQueues);

            Integer counter = 1;
            for (reduivy__Job_Queue_Group__c jqg : [SELECT Id,
                reduivy__Total_Jobs__c,
                reduivy__Completed_Jobs__c,
                reduivy__Failed_Jobs__c,
                reduivy__Cancelled_Jobs__c,
                reduivy__Total_Records__c,
                reduivy__Success_Records__c,
                reduivy__Error_Records__c,
                reduivy__Warning_Records__c,
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Status__c,
                (
                    SELECT Id, 
                    reduivy__Number_of_Records__c,
                    reduivy__Number_of_Success_Records__c,
                    reduivy__Number_of_Error_Records__c,
                    reduivy__Number_of_Warning_Records__c,
                    reduivy__Status__c,
                    reduivy__Start_Datetime__c,
                    reduivy__End_Datetime__c
                    FROM reduivy__Job_Queues__r
                )
                FROM reduivy__Job_Queue_Group__c
                WHERE Id IN: jobQueueGroups
            ]) {

                Decimal totalJobs = 0;
                Decimal completedJobs = 0;
                Decimal cancelledJobs = 0;
                Decimal failedJobs = 0;

                Decimal totalRecords = 0;
                Decimal successRecords = 0;
                Decimal errorRecords = 0;
                Decimal warningRecords = 0;
                Datetime firstStart;
                Datetime lastEnd;

                for (reduivy__Job_Queue__c jqh : jqg.reduivy__Job_Queues__r) {
                    totalJobs ++;
                    totalRecords += (jqh.reduivy__Number_of_Records__c ?? 0);

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED) {
                        completedJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_CANCELLED) {
                        cancelledJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        failedJobs ++;
                    }

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED || jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        //we won't include the record count for success, warning, error if the job is cancelled.
                        successRecords += (jqh.reduivy__Number_of_Success_Records__c ?? 0);
                        errorRecords += (jqh.reduivy__Number_of_Error_Records__c ?? 0);
                        warningRecords += (jqh.reduivy__Number_of_Warning_Records__c ?? 0);

                        if (firstStart == null || firstStart > jqh.reduivy__Start_Datetime__c) {
                            firstStart = jqh.reduivy__Start_Datetime__c;
                        }

                        if (lastEnd == null || lastEnd < jqh.reduivy__End_Datetime__c) {
                            lastEnd = jqh.reduivy__End_Datetime__c;
                        }
                    }
                }

                System.Assert.areEqual(counter, jqg.reduivy__Job_Queues__r.size());
                System.Assert.areEqual(totalJobs, jqg.reduivy__Total_Jobs__c);
                System.Assert.areEqual(completedJobs, jqg.reduivy__Completed_Jobs__c);
                System.Assert.areEqual(failedJobs, jqg.reduivy__Failed_Jobs__c);
                System.Assert.areEqual(cancelledJobs, jqg.reduivy__Cancelled_Jobs__c);
                System.Assert.areEqual(totalRecords, jqg.reduivy__Total_Records__c);
                System.Assert.areEqual(successRecords, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(errorRecords, jqg.reduivy__Error_Records__c);
                System.Assert.areEqual(warningRecords, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(firstStart, jqg.reduivy__Start_Datetime__c);
                System.Assert.areEqual(lastEnd, jqg.reduivy__End_Datetime__c);
                System.Assert.areEqual(JQG_Helper.STATUS_PROCESSING, jqg.reduivy__Status__c);                

                System.Assert.areEqual(0, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Error_Records__c);

                counter ++;
            }

            System.Assert.areEqual(index, counter, 'The number of job queue groups does not match.');
        }

        Test.stopTest();

    }

    /**
     * @description Test completed jobs
     */
    @IsTest
    static void testInsertCompletedJobsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
                SELECT Id FROM reduivy__Individual_Enrollment__c
                WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
            ]);
            
            List<reduivy__Job_Queue_Group__c> jobQueueGroups = new List<reduivy__Job_Queue_Group__c>();
            List<reduivy__Job_Queue__c> jobQueues = new List<reduivy__Job_Queue__c>();

            //create job queue group
            for (Integer i = 0; i < 10; i ++) {
                String jobQueueGroupCode = 'Sample_Job_' + i;

                reduivy__Job_Queue_Group__c newJqg = REDU_TestData_UTIL.newJobQueueGroup(
                    jobQueueGroupCode,
                    jobQueueGroupCode
                );

                jobQueueGroups.add(newJqg);
            }

            REDU_Database_UTIL.doInsert(jobQueueGroups);
            
            //create number of job queues based on the job queue group index e.g., job queue group at index 3 would have 3 job queues
            Integer index = 1;
            for (reduivy__Job_Queue_Group__c jqg : jobQueueGroups) {
                for (Integer i = 0; i < index; i ++) {
                    String jobQueueCode = jqg.reduivy__Job_Operation_Context__c + '_' + i;

                    reduivy__Job_Queue__c newJqh = REDU_TestData_UTIL.newJobQueue(
                        jobQueueCode,
                        jqg.Id,
                        jqg.reduivy__Job_Operation_Context__c,
                        'Sample_Job',
                        null,
                        null,
                        JQH_Helper.serializeRecordIds(ienMaps.keySet()),
                        null,
                        null,
                        null,
                        null,
                        JQH_Helper.STATUS_COMPLETED
                    );

                    newJqh.reduivy__Job_Handler_Success_Record_Ids__c = JQH_Helper.serializeRecordIds(ienMaps.keySet());
                    newJqh.reduivy__Job_Handler_Warning_Record_Ids__c = JQH_Helper.serializeRecordIds(ienMaps.keySet());

                    jobQueues.add(newJqh);
                }

                index ++;
            }

            REDU_Database_UTIL.doInsert(jobQueues);

            Integer counter = 1;
            for (reduivy__Job_Queue_Group__c jqg : [SELECT Id,
                reduivy__Total_Jobs__c,
                reduivy__Completed_Jobs__c,
                reduivy__Failed_Jobs__c,
                reduivy__Cancelled_Jobs__c,
                reduivy__Total_Records__c,
                reduivy__Success_Records__c,
                reduivy__Error_Records__c,
                reduivy__Warning_Records__c,
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Status__c,
                (
                    SELECT Id, 
                    reduivy__Number_of_Records__c,
                    reduivy__Number_of_Success_Records__c,
                    reduivy__Number_of_Error_Records__c,
                    reduivy__Number_of_Warning_Records__c,
                    reduivy__Status__c,
                    reduivy__Start_Datetime__c,
                    reduivy__End_Datetime__c
                    FROM reduivy__Job_Queues__r
                )
                FROM reduivy__Job_Queue_Group__c
                WHERE Id IN: jobQueueGroups
            ]) {

                Decimal totalJobs = 0;
                Decimal completedJobs = 0;
                Decimal cancelledJobs = 0;
                Decimal failedJobs = 0;

                Decimal totalRecords = 0;
                Decimal successRecords = 0;
                Decimal errorRecords = 0;
                Decimal warningRecords = 0;
                Datetime firstStart;
                Datetime lastEnd;

                for (reduivy__Job_Queue__c jqh : jqg.reduivy__Job_Queues__r) {
                    totalJobs ++;
                    totalRecords += (jqh.reduivy__Number_of_Records__c ?? 0);

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED) {
                        completedJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_CANCELLED) {
                        cancelledJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        failedJobs ++;
                    }

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED || jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        //we won't include the record count for success, warning, error if the job is cancelled.
                        successRecords += (jqh.reduivy__Number_of_Success_Records__c ?? 0);
                        errorRecords += (jqh.reduivy__Number_of_Error_Records__c ?? 0);
                        warningRecords += (jqh.reduivy__Number_of_Warning_Records__c ?? 0);

                        if (firstStart == null || firstStart > jqh.reduivy__Start_Datetime__c) {
                            firstStart = jqh.reduivy__Start_Datetime__c;
                        }

                        if (lastEnd == null || lastEnd < jqh.reduivy__End_Datetime__c) {
                            lastEnd = jqh.reduivy__End_Datetime__c;
                        }
                    }
                }

                System.Assert.areEqual(counter, jqg.reduivy__Job_Queues__r.size());
                System.Assert.areEqual(totalJobs, jqg.reduivy__Total_Jobs__c);
                System.Assert.areEqual(completedJobs, jqg.reduivy__Completed_Jobs__c);
                System.Assert.areEqual(failedJobs, jqg.reduivy__Failed_Jobs__c);
                System.Assert.areEqual(cancelledJobs, jqg.reduivy__Cancelled_Jobs__c);
                System.Assert.areEqual(totalRecords, jqg.reduivy__Total_Records__c);
                System.Assert.areEqual(successRecords, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(errorRecords, jqg.reduivy__Error_Records__c);
                System.Assert.areEqual(warningRecords, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(firstStart, jqg.reduivy__Start_Datetime__c);
                System.Assert.areEqual(lastEnd, jqg.reduivy__End_Datetime__c);
                System.Assert.areEqual(JQG_Helper.STATUS_COMPLETED, jqg.reduivy__Status__c);                
                
                System.Assert.areNotEqual(0, jqg.reduivy__Success_Records__c);
                System.Assert.areNotEqual(0, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Error_Records__c);

                counter ++;
            }

            System.Assert.areEqual(index, counter, 'The number of job queue groups does not match.');
        }

        Test.stopTest();

    }

    /**
     * @description Test fail jobs
     */
    @IsTest
    static void testInsertFailedJobsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
                SELECT Id FROM reduivy__Individual_Enrollment__c
                WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
            ]);
            
            List<reduivy__Job_Queue_Group__c> jobQueueGroups = new List<reduivy__Job_Queue_Group__c>();
            List<reduivy__Job_Queue__c> jobQueues = new List<reduivy__Job_Queue__c>();

            //create job queue group
            for (Integer i = 0; i < 10; i ++) {
                String jobQueueGroupCode = 'Sample_Job_' + i;

                reduivy__Job_Queue_Group__c newJqg = REDU_TestData_UTIL.newJobQueueGroup(
                    jobQueueGroupCode,
                    jobQueueGroupCode
                );

                jobQueueGroups.add(newJqg);
            }

            REDU_Database_UTIL.doInsert(jobQueueGroups);
            
            //create number of job queues based on the job queue group index e.g., job queue group at index 3 would have 3 job queues
            Integer index = 1;
            for (reduivy__Job_Queue_Group__c jqg : jobQueueGroups) {
                for (Integer i = 0; i < index; i ++) {
                    String jobQueueCode = jqg.reduivy__Job_Operation_Context__c + '_' + i;

                    reduivy__Job_Queue__c newJqh = REDU_TestData_UTIL.newJobQueue(
                        jobQueueCode,
                        jqg.Id,
                        jqg.reduivy__Job_Operation_Context__c,
                        'Sample_Job',
                        null,
                        null,
                        JQH_Helper.serializeRecordIds(ienMaps.keySet()),
                        null,
                        null,
                        null,
                        null,
                        JQH_Helper.STATUS_FAILED
                    );

                    newJqh.reduivy__Job_Handler_Error_Record_Ids__c = JQH_Helper.serializeRecordIds(ienMaps.keySet());

                    jobQueues.add(newJqh);
                }

                index ++;
            }

            REDU_Database_UTIL.doInsert(jobQueues);

            Integer counter = 1;
            for (reduivy__Job_Queue_Group__c jqg : [SELECT Id,
                reduivy__Total_Jobs__c,
                reduivy__Completed_Jobs__c,
                reduivy__Failed_Jobs__c,
                reduivy__Cancelled_Jobs__c,
                reduivy__Total_Records__c,
                reduivy__Success_Records__c,
                reduivy__Error_Records__c,
                reduivy__Warning_Records__c,
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Status__c,
                (
                    SELECT Id, 
                    reduivy__Number_of_Records__c,
                    reduivy__Number_of_Success_Records__c,
                    reduivy__Number_of_Error_Records__c,
                    reduivy__Number_of_Warning_Records__c,
                    reduivy__Status__c,
                    reduivy__Start_Datetime__c,
                    reduivy__End_Datetime__c
                    FROM reduivy__Job_Queues__r
                )
                FROM reduivy__Job_Queue_Group__c
                WHERE Id IN: jobQueueGroups
            ]) {

                Decimal totalJobs = 0;
                Decimal completedJobs = 0;
                Decimal cancelledJobs = 0;
                Decimal failedJobs = 0;

                Decimal totalRecords = 0;
                Decimal successRecords = 0;
                Decimal errorRecords = 0;
                Decimal warningRecords = 0;
                Datetime firstStart;
                Datetime lastEnd;

                for (reduivy__Job_Queue__c jqh : jqg.reduivy__Job_Queues__r) {
                    totalJobs ++;
                    totalRecords += (jqh.reduivy__Number_of_Records__c ?? 0);

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED) {
                        completedJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_CANCELLED) {
                        cancelledJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        failedJobs ++;
                    }

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED || jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        //we won't include the record count for success, warning, error if the job is cancelled.
                        successRecords += (jqh.reduivy__Number_of_Success_Records__c ?? 0);
                        errorRecords += (jqh.reduivy__Number_of_Error_Records__c ?? 0);
                        warningRecords += (jqh.reduivy__Number_of_Warning_Records__c ?? 0);

                        if (firstStart == null || firstStart > jqh.reduivy__Start_Datetime__c) {
                            firstStart = jqh.reduivy__Start_Datetime__c;
                        }

                        if (lastEnd == null || lastEnd < jqh.reduivy__End_Datetime__c) {
                            lastEnd = jqh.reduivy__End_Datetime__c;
                        }
                    }
                }

                System.Assert.areEqual(counter, jqg.reduivy__Job_Queues__r.size());
                System.Assert.areEqual(totalJobs, jqg.reduivy__Total_Jobs__c);
                System.Assert.areEqual(completedJobs, jqg.reduivy__Completed_Jobs__c);
                System.Assert.areEqual(failedJobs, jqg.reduivy__Failed_Jobs__c);
                System.Assert.areEqual(cancelledJobs, jqg.reduivy__Cancelled_Jobs__c);
                System.Assert.areEqual(totalRecords, jqg.reduivy__Total_Records__c);
                System.Assert.areEqual(successRecords, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(errorRecords, jqg.reduivy__Error_Records__c);
                System.Assert.areEqual(warningRecords, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(firstStart, jqg.reduivy__Start_Datetime__c);
                System.Assert.areEqual(lastEnd, jqg.reduivy__End_Datetime__c);
                System.Assert.areEqual(JQG_Helper.STATUS_FAILED, jqg.reduivy__Status__c);                
                
                System.Assert.areEqual(0, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Warning_Records__c);
                System.Assert.areNotEqual(0, jqg.reduivy__Error_Records__c);

                counter ++;
            }

            System.Assert.areEqual(index, counter, 'The number of job queue groups does not match.');
        }

        Test.stopTest();

    }

    /**
     * @description Test pending to in progress
     */
    @IsTest
    static void testUpdatePendingJobsToInProgressAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
                SELECT Id FROM reduivy__Individual_Enrollment__c
                WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
            ]);
            
            List<reduivy__Job_Queue_Group__c> jobQueueGroups = new List<reduivy__Job_Queue_Group__c>();
            List<reduivy__Job_Queue__c> jobQueues = new List<reduivy__Job_Queue__c>();

            //create job queue group
            for (Integer i = 0; i < 10; i ++) {
                String jobQueueGroupCode = 'Sample_Job_' + i;

                reduivy__Job_Queue_Group__c newJqg = REDU_TestData_UTIL.newJobQueueGroup(
                    jobQueueGroupCode,
                    jobQueueGroupCode
                );

                jobQueueGroups.add(newJqg);
            }

            REDU_Database_UTIL.doInsert(jobQueueGroups);
            
            //create number of job queues based on the job queue group index e.g., job queue group at index 3 would have 3 job queues
            Integer index = 1;
            for (reduivy__Job_Queue_Group__c jqg : jobQueueGroups) {
                for (Integer i = 0; i < index; i ++) {
                    String jobQueueCode = jqg.reduivy__Job_Operation_Context__c + '_' + i;

                    reduivy__Job_Queue__c newJqh = REDU_TestData_UTIL.newJobQueue(
                        jobQueueCode,
                        jqg.Id,
                        jqg.reduivy__Job_Operation_Context__c,
                        'Sample_Job',
                        null,
                        null,
                        JQH_Helper.serializeRecordIds(ienMaps.keySet()),
                        null,
                        null,
                        null,
                        null,
                        JQH_Helper.STATUS_PENDING
                    );

                    jobQueues.add(newJqh);
                }

                index ++;
            }

            REDU_Database_UTIL.doInsert(jobQueues);

            Integer counter = 1;
            for (reduivy__Job_Queue_Group__c jqg : [SELECT Id,
                reduivy__Total_Jobs__c,
                reduivy__Completed_Jobs__c,
                reduivy__Failed_Jobs__c,
                reduivy__Cancelled_Jobs__c,
                reduivy__Total_Records__c,
                reduivy__Success_Records__c,
                reduivy__Error_Records__c,
                reduivy__Warning_Records__c,
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Status__c,
                (
                    SELECT Id, 
                    reduivy__Number_of_Records__c,
                    reduivy__Number_of_Success_Records__c,
                    reduivy__Number_of_Error_Records__c,
                    reduivy__Number_of_Warning_Records__c,
                    reduivy__Status__c,
                    reduivy__Start_Datetime__c,
                    reduivy__End_Datetime__c
                    FROM reduivy__Job_Queues__r
                )
                FROM reduivy__Job_Queue_Group__c
                WHERE Id IN: jobQueueGroups
            ]) {

                Decimal totalJobs = 0;
                Decimal completedJobs = 0;
                Decimal cancelledJobs = 0;
                Decimal failedJobs = 0;

                Decimal totalRecords = 0;
                Decimal successRecords = 0;
                Decimal errorRecords = 0;
                Decimal warningRecords = 0;
                Datetime firstStart;
                Datetime lastEnd;

                for (reduivy__Job_Queue__c jqh : jqg.reduivy__Job_Queues__r) {
                    totalJobs ++;
                    totalRecords += (jqh.reduivy__Number_of_Records__c ?? 0);

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED) {
                        completedJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_CANCELLED) {
                        cancelledJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        failedJobs ++;
                    }

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED || jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        //we won't include the record count for success, warning, error if the job is cancelled.
                        successRecords += (jqh.reduivy__Number_of_Success_Records__c ?? 0);
                        errorRecords += (jqh.reduivy__Number_of_Error_Records__c ?? 0);
                        warningRecords += (jqh.reduivy__Number_of_Warning_Records__c ?? 0);

                        if (firstStart == null || firstStart > jqh.reduivy__Start_Datetime__c) {
                            firstStart = jqh.reduivy__Start_Datetime__c;
                        }

                        if (lastEnd == null || lastEnd < jqh.reduivy__End_Datetime__c) {
                            lastEnd = jqh.reduivy__End_Datetime__c;
                        }
                    }
                }

                System.Assert.areEqual(counter, jqg.reduivy__Job_Queues__r.size());
                System.Assert.areEqual(totalJobs, jqg.reduivy__Total_Jobs__c);
                System.Assert.areEqual(completedJobs, jqg.reduivy__Completed_Jobs__c);
                System.Assert.areEqual(failedJobs, jqg.reduivy__Failed_Jobs__c);
                System.Assert.areEqual(cancelledJobs, jqg.reduivy__Cancelled_Jobs__c);
                System.Assert.areEqual(totalRecords, jqg.reduivy__Total_Records__c);
                System.Assert.areEqual(successRecords, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(errorRecords, jqg.reduivy__Error_Records__c);
                System.Assert.areEqual(warningRecords, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(firstStart, jqg.reduivy__Start_Datetime__c);
                System.Assert.areEqual(lastEnd, jqg.reduivy__End_Datetime__c);
                System.Assert.areEqual(JQG_Helper.STATUS_PENDING, jqg.reduivy__Status__c);                

                System.Assert.areEqual(0, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Error_Records__c);

                counter ++;
            }

            System.Assert.areEqual(index, counter, 'The number of job queue groups does not match.');

            for (reduivy__Job_Queue__c jqh : jobQueues) {
                jqh.reduivy__Status__c = JQH_Helper.STATUS_PROCESSING;
            }

            REDU_Database_UTIL.doUpdate(jobQueues);

            Integer counter2 = 1;
            for (reduivy__Job_Queue_Group__c jqg : [SELECT Id,
                reduivy__Total_Jobs__c,
                reduivy__Completed_Jobs__c,
                reduivy__Failed_Jobs__c,
                reduivy__Cancelled_Jobs__c,
                reduivy__Total_Records__c,
                reduivy__Success_Records__c,
                reduivy__Error_Records__c,
                reduivy__Warning_Records__c,
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Status__c,
                (
                    SELECT Id, 
                    reduivy__Number_of_Records__c,
                    reduivy__Number_of_Success_Records__c,
                    reduivy__Number_of_Error_Records__c,
                    reduivy__Number_of_Warning_Records__c,
                    reduivy__Status__c,
                    reduivy__Start_Datetime__c,
                    reduivy__End_Datetime__c
                    FROM reduivy__Job_Queues__r
                )
                FROM reduivy__Job_Queue_Group__c
                WHERE Id IN: jobQueueGroups
            ]) {

                Decimal totalJobs = 0;
                Decimal completedJobs = 0;
                Decimal cancelledJobs = 0;
                Decimal failedJobs = 0;

                Decimal totalRecords = 0;
                Decimal successRecords = 0;
                Decimal errorRecords = 0;
                Decimal warningRecords = 0;
                Datetime firstStart;
                Datetime lastEnd;

                for (reduivy__Job_Queue__c jqh : jqg.reduivy__Job_Queues__r) {
                    totalJobs ++;
                    totalRecords += (jqh.reduivy__Number_of_Records__c ?? 0);

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED) {
                        completedJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_CANCELLED) {
                        cancelledJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        failedJobs ++;
                    }

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED || jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        //we won't include the record count for success, warning, error if the job is cancelled.
                        successRecords += (jqh.reduivy__Number_of_Success_Records__c ?? 0);
                        errorRecords += (jqh.reduivy__Number_of_Error_Records__c ?? 0);
                        warningRecords += (jqh.reduivy__Number_of_Warning_Records__c ?? 0);

                        if (firstStart == null || firstStart > jqh.reduivy__Start_Datetime__c) {
                            firstStart = jqh.reduivy__Start_Datetime__c;
                        }

                        if (lastEnd == null || lastEnd < jqh.reduivy__End_Datetime__c) {
                            lastEnd = jqh.reduivy__End_Datetime__c;
                        }
                    }
                }

                System.Assert.areEqual(counter2, jqg.reduivy__Job_Queues__r.size());
                System.Assert.areEqual(totalJobs, jqg.reduivy__Total_Jobs__c);
                System.Assert.areEqual(completedJobs, jqg.reduivy__Completed_Jobs__c);
                System.Assert.areEqual(failedJobs, jqg.reduivy__Failed_Jobs__c);
                System.Assert.areEqual(cancelledJobs, jqg.reduivy__Cancelled_Jobs__c);
                System.Assert.areEqual(totalRecords, jqg.reduivy__Total_Records__c);
                System.Assert.areEqual(successRecords, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(errorRecords, jqg.reduivy__Error_Records__c);
                System.Assert.areEqual(warningRecords, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(firstStart, jqg.reduivy__Start_Datetime__c);
                System.Assert.areEqual(lastEnd, jqg.reduivy__End_Datetime__c);
                System.Assert.areEqual(JQG_Helper.STATUS_PROCESSING, jqg.reduivy__Status__c);                

                System.Assert.areEqual(0, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Error_Records__c);

                counter2 ++;
            }

            System.Assert.areEqual(index, counter2, 'The number of job queue groups does not match.');
        }

        Test.stopTest();

    }

    /**
     * @description Test in progress to completed
     */
    @IsTest
    static void testUpdateProcessingJobsToCompletedAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
                SELECT Id FROM reduivy__Individual_Enrollment__c
                WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
            ]);
            
            List<reduivy__Job_Queue_Group__c> jobQueueGroups = new List<reduivy__Job_Queue_Group__c>();
            List<reduivy__Job_Queue__c> jobQueues = new List<reduivy__Job_Queue__c>();

            //create job queue group
            for (Integer i = 0; i < 10; i ++) {
                String jobQueueGroupCode = 'Sample_Job_' + i;

                reduivy__Job_Queue_Group__c newJqg = REDU_TestData_UTIL.newJobQueueGroup(
                    jobQueueGroupCode,
                    jobQueueGroupCode
                );

                jobQueueGroups.add(newJqg);
            }

            REDU_Database_UTIL.doInsert(jobQueueGroups);
            
            //create number of job queues based on the job queue group index e.g., job queue group at index 3 would have 3 job queues
            Integer index = 1;
            for (reduivy__Job_Queue_Group__c jqg : jobQueueGroups) {
                for (Integer i = 0; i < index; i ++) {
                    String jobQueueCode = jqg.reduivy__Job_Operation_Context__c + '_' + i;

                    reduivy__Job_Queue__c newJqh = REDU_TestData_UTIL.newJobQueue(
                        jobQueueCode,
                        jqg.Id,
                        jqg.reduivy__Job_Operation_Context__c,
                        'Sample_Job',
                        null,
                        null,
                        JQH_Helper.serializeRecordIds(ienMaps.keySet()),
                        null,
                        null,
                        null,
                        null,
                        JQH_Helper.STATUS_PROCESSING
                    );

                    jobQueues.add(newJqh);
                }

                index ++;
            }

            REDU_Database_UTIL.doInsert(jobQueues);

            Integer counter = 1;
            for (reduivy__Job_Queue_Group__c jqg : [SELECT Id,
                reduivy__Total_Jobs__c,
                reduivy__Completed_Jobs__c,
                reduivy__Failed_Jobs__c,
                reduivy__Cancelled_Jobs__c,
                reduivy__Total_Records__c,
                reduivy__Success_Records__c,
                reduivy__Error_Records__c,
                reduivy__Warning_Records__c,
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Status__c,
                (
                    SELECT Id, 
                    reduivy__Number_of_Records__c,
                    reduivy__Number_of_Success_Records__c,
                    reduivy__Number_of_Error_Records__c,
                    reduivy__Number_of_Warning_Records__c,
                    reduivy__Status__c,
                    reduivy__Start_Datetime__c,
                    reduivy__End_Datetime__c
                    FROM reduivy__Job_Queues__r
                )
                FROM reduivy__Job_Queue_Group__c
                WHERE Id IN: jobQueueGroups
            ]) {

                Decimal totalJobs = 0;
                Decimal completedJobs = 0;
                Decimal cancelledJobs = 0;
                Decimal failedJobs = 0;

                Decimal totalRecords = 0;
                Decimal successRecords = 0;
                Decimal errorRecords = 0;
                Decimal warningRecords = 0;
                Datetime firstStart;
                Datetime lastEnd;

                for (reduivy__Job_Queue__c jqh : jqg.reduivy__Job_Queues__r) {
                    totalJobs ++;
                    totalRecords += (jqh.reduivy__Number_of_Records__c ?? 0);

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED) {
                        completedJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_CANCELLED) {
                        cancelledJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        failedJobs ++;
                    }

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED || jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        //we won't include the record count for success, warning, error if the job is cancelled.
                        successRecords += (jqh.reduivy__Number_of_Success_Records__c ?? 0);
                        errorRecords += (jqh.reduivy__Number_of_Error_Records__c ?? 0);
                        warningRecords += (jqh.reduivy__Number_of_Warning_Records__c ?? 0);

                        if (firstStart == null || firstStart > jqh.reduivy__Start_Datetime__c) {
                            firstStart = jqh.reduivy__Start_Datetime__c;
                        }

                        if (lastEnd == null || lastEnd < jqh.reduivy__End_Datetime__c) {
                            lastEnd = jqh.reduivy__End_Datetime__c;
                        }
                    }
                }

                System.Assert.areEqual(counter, jqg.reduivy__Job_Queues__r.size());
                System.Assert.areEqual(totalJobs, jqg.reduivy__Total_Jobs__c);
                System.Assert.areEqual(completedJobs, jqg.reduivy__Completed_Jobs__c);
                System.Assert.areEqual(failedJobs, jqg.reduivy__Failed_Jobs__c);
                System.Assert.areEqual(cancelledJobs, jqg.reduivy__Cancelled_Jobs__c);
                System.Assert.areEqual(totalRecords, jqg.reduivy__Total_Records__c);
                System.Assert.areEqual(successRecords, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(errorRecords, jqg.reduivy__Error_Records__c);
                System.Assert.areEqual(warningRecords, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(firstStart, jqg.reduivy__Start_Datetime__c);
                System.Assert.areEqual(lastEnd, jqg.reduivy__End_Datetime__c);
                System.Assert.areEqual(JQG_Helper.STATUS_PROCESSING, jqg.reduivy__Status__c);                

                System.Assert.areEqual(0, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Error_Records__c);

                counter ++;
            }

            System.Assert.areEqual(index, counter, 'The number of job queue groups does not match.');

            for (reduivy__Job_Queue__c jqh : jobQueues) {
                jqh.reduivy__Status__c = JQH_Helper.STATUS_COMPLETED;
                jqh.reduivy__Job_Handler_Success_Record_Ids__c = JQH_Helper.serializeRecordIds(ienMaps.keySet());
                jqh.reduivy__Job_Handler_Warning_Record_Ids__c = JQH_Helper.serializeRecordIds(ienMaps.keySet());
            }

            REDU_Database_UTIL.doUpdate(jobQueues);

            Integer counter2 = 1;
            for (reduivy__Job_Queue_Group__c jqg : [SELECT Id,
                reduivy__Total_Jobs__c,
                reduivy__Completed_Jobs__c,
                reduivy__Failed_Jobs__c,
                reduivy__Cancelled_Jobs__c,
                reduivy__Total_Records__c,
                reduivy__Success_Records__c,
                reduivy__Error_Records__c,
                reduivy__Warning_Records__c,
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Status__c,
                (
                    SELECT Id, 
                    reduivy__Number_of_Records__c,
                    reduivy__Number_of_Success_Records__c,
                    reduivy__Number_of_Error_Records__c,
                    reduivy__Number_of_Warning_Records__c,
                    reduivy__Status__c,
                    reduivy__Start_Datetime__c,
                    reduivy__End_Datetime__c
                    FROM reduivy__Job_Queues__r
                )
                FROM reduivy__Job_Queue_Group__c
                WHERE Id IN: jobQueueGroups
            ]) {

                Decimal totalJobs = 0;
                Decimal completedJobs = 0;
                Decimal cancelledJobs = 0;
                Decimal failedJobs = 0;

                Decimal totalRecords = 0;
                Decimal successRecords = 0;
                Decimal errorRecords = 0;
                Decimal warningRecords = 0;
                Datetime firstStart;
                Datetime lastEnd;

                for (reduivy__Job_Queue__c jqh : jqg.reduivy__Job_Queues__r) {
                    totalJobs ++;
                    totalRecords += (jqh.reduivy__Number_of_Records__c ?? 0);

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED) {
                        completedJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_CANCELLED) {
                        cancelledJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        failedJobs ++;
                    }

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED || jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        //we won't include the record count for success, warning, error if the job is cancelled.
                        successRecords += (jqh.reduivy__Number_of_Success_Records__c ?? 0);
                        errorRecords += (jqh.reduivy__Number_of_Error_Records__c ?? 0);
                        warningRecords += (jqh.reduivy__Number_of_Warning_Records__c ?? 0);

                        if (firstStart == null || firstStart > jqh.reduivy__Start_Datetime__c) {
                            firstStart = jqh.reduivy__Start_Datetime__c;
                        }

                        if (lastEnd == null || lastEnd < jqh.reduivy__End_Datetime__c) {
                            lastEnd = jqh.reduivy__End_Datetime__c;
                        }
                    }
                }

                System.Assert.areEqual(counter2, jqg.reduivy__Job_Queues__r.size());
                System.Assert.areEqual(totalJobs, jqg.reduivy__Total_Jobs__c);
                System.Assert.areEqual(completedJobs, jqg.reduivy__Completed_Jobs__c);
                System.Assert.areEqual(failedJobs, jqg.reduivy__Failed_Jobs__c);
                System.Assert.areEqual(cancelledJobs, jqg.reduivy__Cancelled_Jobs__c);
                System.Assert.areEqual(totalRecords, jqg.reduivy__Total_Records__c);
                System.Assert.areEqual(successRecords, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(errorRecords, jqg.reduivy__Error_Records__c);
                System.Assert.areEqual(warningRecords, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(firstStart, jqg.reduivy__Start_Datetime__c);
                System.Assert.areEqual(lastEnd, jqg.reduivy__End_Datetime__c);
                System.Assert.areEqual(JQG_Helper.STATUS_COMPLETED, jqg.reduivy__Status__c);     
                
                System.Assert.areNotEqual(0, jqg.reduivy__Success_Records__c);
                System.Assert.areNotEqual(0, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Error_Records__c);

                counter2 ++;
            }

            System.Assert.areEqual(index, counter2, 'The number of job queue groups does not match.');
        }

        Test.stopTest();

    }

    /**
     * @description Test in progress to failed
     */
    @IsTest
    static void testUpdateProcessingJobsToFailedAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
                SELECT Id FROM reduivy__Individual_Enrollment__c
                WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
            ]);
            
            List<reduivy__Job_Queue_Group__c> jobQueueGroups = new List<reduivy__Job_Queue_Group__c>();
            List<reduivy__Job_Queue__c> jobQueues = new List<reduivy__Job_Queue__c>();

            //create job queue group
            for (Integer i = 0; i < 10; i ++) {
                String jobQueueGroupCode = 'Sample_Job_' + i;

                reduivy__Job_Queue_Group__c newJqg = REDU_TestData_UTIL.newJobQueueGroup(
                    jobQueueGroupCode,
                    jobQueueGroupCode
                );

                jobQueueGroups.add(newJqg);
            }

            REDU_Database_UTIL.doInsert(jobQueueGroups);
            
            //create number of job queues based on the job queue group index e.g., job queue group at index 3 would have 3 job queues
            Integer index = 1;
            for (reduivy__Job_Queue_Group__c jqg : jobQueueGroups) {
                for (Integer i = 0; i < index; i ++) {
                    String jobQueueCode = jqg.reduivy__Job_Operation_Context__c + '_' + i;

                    reduivy__Job_Queue__c newJqh = REDU_TestData_UTIL.newJobQueue(
                        jobQueueCode,
                        jqg.Id,
                        jqg.reduivy__Job_Operation_Context__c,
                        'Sample_Job',
                        null,
                        null,
                        JQH_Helper.serializeRecordIds(ienMaps.keySet()),
                        null,
                        null,
                        null,
                        null,
                        JQH_Helper.STATUS_PROCESSING
                    );

                    jobQueues.add(newJqh);
                }

                index ++;
            }

            REDU_Database_UTIL.doInsert(jobQueues);

            Integer counter = 1;
            for (reduivy__Job_Queue_Group__c jqg : [SELECT Id,
                reduivy__Total_Jobs__c,
                reduivy__Completed_Jobs__c,
                reduivy__Failed_Jobs__c,
                reduivy__Cancelled_Jobs__c,
                reduivy__Total_Records__c,
                reduivy__Success_Records__c,
                reduivy__Error_Records__c,
                reduivy__Warning_Records__c,
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Status__c,
                (
                    SELECT Id, 
                    reduivy__Number_of_Records__c,
                    reduivy__Number_of_Success_Records__c,
                    reduivy__Number_of_Error_Records__c,
                    reduivy__Number_of_Warning_Records__c,
                    reduivy__Status__c,
                    reduivy__Start_Datetime__c,
                    reduivy__End_Datetime__c
                    FROM reduivy__Job_Queues__r
                )
                FROM reduivy__Job_Queue_Group__c
                WHERE Id IN: jobQueueGroups
            ]) {

                Decimal totalJobs = 0;
                Decimal completedJobs = 0;
                Decimal cancelledJobs = 0;
                Decimal failedJobs = 0;

                Decimal totalRecords = 0;
                Decimal successRecords = 0;
                Decimal errorRecords = 0;
                Decimal warningRecords = 0;
                Datetime firstStart;
                Datetime lastEnd;

                for (reduivy__Job_Queue__c jqh : jqg.reduivy__Job_Queues__r) {
                    totalJobs ++;
                    totalRecords += (jqh.reduivy__Number_of_Records__c ?? 0);

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED) {
                        completedJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_CANCELLED) {
                        cancelledJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        failedJobs ++;
                    }

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED || jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        //we won't include the record count for success, warning, error if the job is cancelled.
                        successRecords += (jqh.reduivy__Number_of_Success_Records__c ?? 0);
                        errorRecords += (jqh.reduivy__Number_of_Error_Records__c ?? 0);
                        warningRecords += (jqh.reduivy__Number_of_Warning_Records__c ?? 0);

                        if (firstStart == null || firstStart > jqh.reduivy__Start_Datetime__c) {
                            firstStart = jqh.reduivy__Start_Datetime__c;
                        }

                        if (lastEnd == null || lastEnd < jqh.reduivy__End_Datetime__c) {
                            lastEnd = jqh.reduivy__End_Datetime__c;
                        }
                    }
                }

                System.Assert.areEqual(counter, jqg.reduivy__Job_Queues__r.size());
                System.Assert.areEqual(totalJobs, jqg.reduivy__Total_Jobs__c);
                System.Assert.areEqual(completedJobs, jqg.reduivy__Completed_Jobs__c);
                System.Assert.areEqual(failedJobs, jqg.reduivy__Failed_Jobs__c);
                System.Assert.areEqual(cancelledJobs, jqg.reduivy__Cancelled_Jobs__c);
                System.Assert.areEqual(totalRecords, jqg.reduivy__Total_Records__c);
                System.Assert.areEqual(successRecords, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(errorRecords, jqg.reduivy__Error_Records__c);
                System.Assert.areEqual(warningRecords, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(firstStart, jqg.reduivy__Start_Datetime__c);
                System.Assert.areEqual(lastEnd, jqg.reduivy__End_Datetime__c);
                System.Assert.areEqual(JQG_Helper.STATUS_PROCESSING, jqg.reduivy__Status__c);                

                System.Assert.areEqual(0, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Error_Records__c);

                counter ++;
            }

            System.Assert.areEqual(index, counter, 'The number of job queue groups does not match.');

            for (reduivy__Job_Queue__c jqh : jobQueues) {
                jqh.reduivy__Status__c = JQH_Helper.STATUS_FAILED;
                jqh.reduivy__Job_Handler_Error_Record_Ids__c = JQH_Helper.serializeRecordIds(ienMaps.keySet());
            }

            REDU_Database_UTIL.doUpdate(jobQueues);

            Integer counter2 = 1;
            for (reduivy__Job_Queue_Group__c jqg : [SELECT Id,
                reduivy__Total_Jobs__c,
                reduivy__Completed_Jobs__c,
                reduivy__Failed_Jobs__c,
                reduivy__Cancelled_Jobs__c,
                reduivy__Total_Records__c,
                reduivy__Success_Records__c,
                reduivy__Error_Records__c,
                reduivy__Warning_Records__c,
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Status__c,
                (
                    SELECT Id, 
                    reduivy__Number_of_Records__c,
                    reduivy__Number_of_Success_Records__c,
                    reduivy__Number_of_Error_Records__c,
                    reduivy__Number_of_Warning_Records__c,
                    reduivy__Status__c,
                    reduivy__Start_Datetime__c,
                    reduivy__End_Datetime__c
                    FROM reduivy__Job_Queues__r
                )
                FROM reduivy__Job_Queue_Group__c
                WHERE Id IN: jobQueueGroups
            ]) {

                Decimal totalJobs = 0;
                Decimal completedJobs = 0;
                Decimal cancelledJobs = 0;
                Decimal failedJobs = 0;

                Decimal totalRecords = 0;
                Decimal successRecords = 0;
                Decimal errorRecords = 0;
                Decimal warningRecords = 0;
                Datetime firstStart;
                Datetime lastEnd;

                for (reduivy__Job_Queue__c jqh : jqg.reduivy__Job_Queues__r) {
                    totalJobs ++;
                    totalRecords += (jqh.reduivy__Number_of_Records__c ?? 0);

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED) {
                        completedJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_CANCELLED) {
                        cancelledJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        failedJobs ++;
                    }

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED || jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        //we won't include the record count for success, warning, error if the job is cancelled.
                        successRecords += (jqh.reduivy__Number_of_Success_Records__c ?? 0);
                        errorRecords += (jqh.reduivy__Number_of_Error_Records__c ?? 0);
                        warningRecords += (jqh.reduivy__Number_of_Warning_Records__c ?? 0);

                        if (firstStart == null || firstStart > jqh.reduivy__Start_Datetime__c) {
                            firstStart = jqh.reduivy__Start_Datetime__c;
                        }

                        if (lastEnd == null || lastEnd < jqh.reduivy__End_Datetime__c) {
                            lastEnd = jqh.reduivy__End_Datetime__c;
                        }
                    }
                }

                System.Assert.areEqual(counter2, jqg.reduivy__Job_Queues__r.size());
                System.Assert.areEqual(totalJobs, jqg.reduivy__Total_Jobs__c);
                System.Assert.areEqual(completedJobs, jqg.reduivy__Completed_Jobs__c);
                System.Assert.areEqual(failedJobs, jqg.reduivy__Failed_Jobs__c);
                System.Assert.areEqual(cancelledJobs, jqg.reduivy__Cancelled_Jobs__c);
                System.Assert.areEqual(totalRecords, jqg.reduivy__Total_Records__c);
                System.Assert.areEqual(successRecords, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(errorRecords, jqg.reduivy__Error_Records__c);
                System.Assert.areEqual(warningRecords, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(firstStart, jqg.reduivy__Start_Datetime__c);
                System.Assert.areEqual(lastEnd, jqg.reduivy__End_Datetime__c);
                System.Assert.areEqual(JQG_Helper.STATUS_FAILED, jqg.reduivy__Status__c);     
                
                System.Assert.areEqual(0, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Warning_Records__c);
                System.Assert.areNotEqual(0, jqg.reduivy__Error_Records__c);

                counter2 ++;
            }

            System.Assert.areEqual(index, counter2, 'The number of job queue groups does not match.');
        }

        Test.stopTest();

    }
    
    /**
     * @description Test delete and undelete jobs
     */
    @IsTest
    static void testDeleteAndUndeleteCompletedJobsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
                SELECT Id FROM reduivy__Individual_Enrollment__c
                WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
            ]);
            
            List<reduivy__Job_Queue_Group__c> jobQueueGroups = new List<reduivy__Job_Queue_Group__c>();
            List<reduivy__Job_Queue__c> jobQueues = new List<reduivy__Job_Queue__c>();

            //create job queue group
            for (Integer i = 0; i < 10; i ++) {
                String jobQueueGroupCode = 'Sample_Job_' + i;

                reduivy__Job_Queue_Group__c newJqg = REDU_TestData_UTIL.newJobQueueGroup(
                    jobQueueGroupCode,
                    jobQueueGroupCode
                );

                jobQueueGroups.add(newJqg);
            }

            REDU_Database_UTIL.doInsert(jobQueueGroups);
            
            //create number of job queues based on the job queue group index e.g., job queue group at index 3 would have 3 job queues
            Integer index = 1;
            for (reduivy__Job_Queue_Group__c jqg : jobQueueGroups) {
                for (Integer i = 0; i < index; i ++) {
                    String jobQueueCode = jqg.reduivy__Job_Operation_Context__c + '_' + i;

                    reduivy__Job_Queue__c newJqh = REDU_TestData_UTIL.newJobQueue(
                        jobQueueCode,
                        jqg.Id,
                        jqg.reduivy__Job_Operation_Context__c,
                        'Sample_Job',
                        null,
                        null,
                        JQH_Helper.serializeRecordIds(ienMaps.keySet()),
                        null,
                        null,
                        null,
                        null,
                        JQH_Helper.STATUS_COMPLETED
                    );

                    newJqh.reduivy__Job_Handler_Success_Record_Ids__c = JQH_Helper.serializeRecordIds(ienMaps.keySet());
                    newJqh.reduivy__Job_Handler_Warning_Record_Ids__c = JQH_Helper.serializeRecordIds(ienMaps.keySet());

                    jobQueues.add(newJqh);
                }

                index ++;
            }

            REDU_Database_UTIL.doInsert(jobQueues);

            Integer counter = 1;
            for (reduivy__Job_Queue_Group__c jqg : [SELECT Id,
                reduivy__Total_Jobs__c,
                reduivy__Completed_Jobs__c,
                reduivy__Failed_Jobs__c,
                reduivy__Cancelled_Jobs__c,
                reduivy__Total_Records__c,
                reduivy__Success_Records__c,
                reduivy__Error_Records__c,
                reduivy__Warning_Records__c,
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Status__c,
                (
                    SELECT Id, 
                    reduivy__Number_of_Records__c,
                    reduivy__Number_of_Success_Records__c,
                    reduivy__Number_of_Error_Records__c,
                    reduivy__Number_of_Warning_Records__c,
                    reduivy__Status__c,
                    reduivy__Start_Datetime__c,
                    reduivy__End_Datetime__c
                    FROM reduivy__Job_Queues__r
                )
                FROM reduivy__Job_Queue_Group__c
                WHERE Id IN: jobQueueGroups
            ]) {

                Decimal totalJobs = 0;
                Decimal completedJobs = 0;
                Decimal cancelledJobs = 0;
                Decimal failedJobs = 0;

                Decimal totalRecords = 0;
                Decimal successRecords = 0;
                Decimal errorRecords = 0;
                Decimal warningRecords = 0;
                Datetime firstStart;
                Datetime lastEnd;

                for (reduivy__Job_Queue__c jqh : jqg.reduivy__Job_Queues__r) {
                    totalJobs ++;
                    totalRecords += (jqh.reduivy__Number_of_Records__c ?? 0);

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED) {
                        completedJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_CANCELLED) {
                        cancelledJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        failedJobs ++;
                    }

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED || jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        //we won't include the record count for success, warning, error if the job is cancelled.
                        successRecords += (jqh.reduivy__Number_of_Success_Records__c ?? 0);
                        errorRecords += (jqh.reduivy__Number_of_Error_Records__c ?? 0);
                        warningRecords += (jqh.reduivy__Number_of_Warning_Records__c ?? 0);

                        if (firstStart == null || firstStart > jqh.reduivy__Start_Datetime__c) {
                            firstStart = jqh.reduivy__Start_Datetime__c;
                        }

                        if (lastEnd == null || lastEnd < jqh.reduivy__End_Datetime__c) {
                            lastEnd = jqh.reduivy__End_Datetime__c;
                        }
                    }
                }

                System.Assert.areEqual(counter, jqg.reduivy__Job_Queues__r.size());
                System.Assert.areEqual(totalJobs, jqg.reduivy__Total_Jobs__c);
                System.Assert.areEqual(completedJobs, jqg.reduivy__Completed_Jobs__c);
                System.Assert.areEqual(failedJobs, jqg.reduivy__Failed_Jobs__c);
                System.Assert.areEqual(cancelledJobs, jqg.reduivy__Cancelled_Jobs__c);
                System.Assert.areEqual(totalRecords, jqg.reduivy__Total_Records__c);
                System.Assert.areEqual(successRecords, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(errorRecords, jqg.reduivy__Error_Records__c);
                System.Assert.areEqual(warningRecords, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(firstStart, jqg.reduivy__Start_Datetime__c);
                System.Assert.areEqual(lastEnd, jqg.reduivy__End_Datetime__c);
                System.Assert.areEqual(JQG_Helper.STATUS_COMPLETED, jqg.reduivy__Status__c);                
                
                System.Assert.areNotEqual(0, jqg.reduivy__Success_Records__c);
                System.Assert.areNotEqual(0, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Error_Records__c);

                counter ++;
            }

            System.Assert.areEqual(index, counter, 'The number of job queue groups does not match.');

            Set<Id> jobQueueIds = new Set<Id>();
            for (reduivy__Job_Queue__c jqh : jobQueues) {
                jobQueueIds.add(jqh.Id);
            }

            Database.delete(new List<Id>(jobQueueIds), AccessLevel.USER_MODE);

            Integer counter2 = 1;
            for (reduivy__Job_Queue_Group__c jqg : [SELECT Id,
                reduivy__Total_Jobs__c,
                reduivy__Completed_Jobs__c,
                reduivy__Failed_Jobs__c,
                reduivy__Cancelled_Jobs__c,
                reduivy__Total_Records__c,
                reduivy__Success_Records__c,
                reduivy__Error_Records__c,
                reduivy__Warning_Records__c,
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Status__c,
                (
                    SELECT Id, 
                    reduivy__Number_of_Records__c,
                    reduivy__Number_of_Success_Records__c,
                    reduivy__Number_of_Error_Records__c,
                    reduivy__Number_of_Warning_Records__c,
                    reduivy__Status__c,
                    reduivy__Start_Datetime__c,
                    reduivy__End_Datetime__c
                    FROM reduivy__Job_Queues__r
                )
                FROM reduivy__Job_Queue_Group__c
                WHERE Id IN: jobQueueGroups
            ]) {

                Decimal totalJobs = 0;
                Decimal completedJobs = 0;
                Decimal cancelledJobs = 0;
                Decimal failedJobs = 0;

                Decimal totalRecords = 0;
                Decimal successRecords = 0;
                Decimal errorRecords = 0;
                Decimal warningRecords = 0;
                Datetime firstStart;
                Datetime lastEnd;

                for (reduivy__Job_Queue__c jqh : jqg.reduivy__Job_Queues__r) {
                    totalJobs ++;
                    totalRecords += (jqh.reduivy__Number_of_Records__c ?? 0);

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED) {
                        completedJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_CANCELLED) {
                        cancelledJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        failedJobs ++;
                    }

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED || jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        //we won't include the record count for success, warning, error if the job is cancelled.
                        successRecords += (jqh.reduivy__Number_of_Success_Records__c ?? 0);
                        errorRecords += (jqh.reduivy__Number_of_Error_Records__c ?? 0);
                        warningRecords += (jqh.reduivy__Number_of_Warning_Records__c ?? 0);

                        if (firstStart == null || firstStart > jqh.reduivy__Start_Datetime__c) {
                            firstStart = jqh.reduivy__Start_Datetime__c;
                        }

                        if (lastEnd == null || lastEnd < jqh.reduivy__End_Datetime__c) {
                            lastEnd = jqh.reduivy__End_Datetime__c;
                        }
                    }
                }

                System.Assert.areEqual(0, jqg.reduivy__Job_Queues__r.size());
                System.Assert.areEqual(totalJobs, jqg.reduivy__Total_Jobs__c);
                System.Assert.areEqual(completedJobs, jqg.reduivy__Completed_Jobs__c);
                System.Assert.areEqual(failedJobs, jqg.reduivy__Failed_Jobs__c);
                System.Assert.areEqual(cancelledJobs, jqg.reduivy__Cancelled_Jobs__c);
                System.Assert.areEqual(totalRecords, jqg.reduivy__Total_Records__c);
                System.Assert.areEqual(successRecords, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(errorRecords, jqg.reduivy__Error_Records__c);
                System.Assert.areEqual(warningRecords, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(firstStart, jqg.reduivy__Start_Datetime__c);
                System.Assert.areEqual(lastEnd, jqg.reduivy__End_Datetime__c);
                System.Assert.areEqual(JQG_Helper.STATUS_PENDING, jqg.reduivy__Status__c);                
                
                System.Assert.areEqual(0, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Error_Records__c);

                counter2 ++;
            }

            System.Assert.areEqual(index, counter2, 'The number of job queue groups does not match.');

            Database.undelete(new List<Id>(jobQueueIds), AccessLevel.USER_MODE);

            Integer counter3 = 1;
            for (reduivy__Job_Queue_Group__c jqg : [SELECT Id,
                reduivy__Total_Jobs__c,
                reduivy__Completed_Jobs__c,
                reduivy__Failed_Jobs__c,
                reduivy__Cancelled_Jobs__c,
                reduivy__Total_Records__c,
                reduivy__Success_Records__c,
                reduivy__Error_Records__c,
                reduivy__Warning_Records__c,
                reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c,
                reduivy__Status__c,
                (
                    SELECT Id, 
                    reduivy__Number_of_Records__c,
                    reduivy__Number_of_Success_Records__c,
                    reduivy__Number_of_Error_Records__c,
                    reduivy__Number_of_Warning_Records__c,
                    reduivy__Status__c,
                    reduivy__Start_Datetime__c,
                    reduivy__End_Datetime__c
                    FROM reduivy__Job_Queues__r
                )
                FROM reduivy__Job_Queue_Group__c
                WHERE Id IN: jobQueueGroups
            ]) {

                Decimal totalJobs = 0;
                Decimal completedJobs = 0;
                Decimal cancelledJobs = 0;
                Decimal failedJobs = 0;

                Decimal totalRecords = 0;
                Decimal successRecords = 0;
                Decimal errorRecords = 0;
                Decimal warningRecords = 0;
                Datetime firstStart;
                Datetime lastEnd;

                for (reduivy__Job_Queue__c jqh : jqg.reduivy__Job_Queues__r) {
                    totalJobs ++;
                    totalRecords += (jqh.reduivy__Number_of_Records__c ?? 0);

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED) {
                        completedJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_CANCELLED) {
                        cancelledJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        failedJobs ++;
                    }

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED || jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        //we won't include the record count for success, warning, error if the job is cancelled.
                        successRecords += (jqh.reduivy__Number_of_Success_Records__c ?? 0);
                        errorRecords += (jqh.reduivy__Number_of_Error_Records__c ?? 0);
                        warningRecords += (jqh.reduivy__Number_of_Warning_Records__c ?? 0);

                        if (firstStart == null || firstStart > jqh.reduivy__Start_Datetime__c) {
                            firstStart = jqh.reduivy__Start_Datetime__c;
                        }

                        if (lastEnd == null || lastEnd < jqh.reduivy__End_Datetime__c) {
                            lastEnd = jqh.reduivy__End_Datetime__c;
                        }
                    }
                }

                System.Assert.areEqual(counter3, jqg.reduivy__Job_Queues__r.size());
                System.Assert.areEqual(totalJobs, jqg.reduivy__Total_Jobs__c);
                System.Assert.areEqual(completedJobs, jqg.reduivy__Completed_Jobs__c);
                System.Assert.areEqual(failedJobs, jqg.reduivy__Failed_Jobs__c);
                System.Assert.areEqual(cancelledJobs, jqg.reduivy__Cancelled_Jobs__c);
                System.Assert.areEqual(totalRecords, jqg.reduivy__Total_Records__c);
                System.Assert.areEqual(successRecords, jqg.reduivy__Success_Records__c);
                System.Assert.areEqual(errorRecords, jqg.reduivy__Error_Records__c);
                System.Assert.areEqual(warningRecords, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(firstStart, jqg.reduivy__Start_Datetime__c);
                System.Assert.areEqual(lastEnd, jqg.reduivy__End_Datetime__c);
                System.Assert.areEqual(JQG_Helper.STATUS_COMPLETED, jqg.reduivy__Status__c);                
                
                System.Assert.areNotEqual(0, jqg.reduivy__Success_Records__c);
                System.Assert.areNotEqual(0, jqg.reduivy__Warning_Records__c);
                System.Assert.areEqual(0, jqg.reduivy__Error_Records__c);

                counter3 ++;
            }

            System.Assert.areEqual(index, counter3, 'The number of job queue groups does not match.');
        }

        Test.stopTest();

    }
}