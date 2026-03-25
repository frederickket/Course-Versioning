/**
 * @author      WDCi (Lean)
 * @date        Jan 2025
 * @group       Test
 * @description Test class for JQH_JobGenerator_QUEUE
 * @changehistory
 * ISS-002219 02-01-2025 Lean - new class
 * ISS-002547 14-07-2025 Lean - Added job group test
 */
@IsTest
public inherited sharing class JQH_JobGenerator_TEST {
    
	/**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    @TestSetup
    static void makeData(){
        
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();

		System.runAs(ADMIN_USER) {

            testFactory.initMasterData(SPS_Helper.getApiName());
            testFactory.initOfferingData(SOF_Helper.getApiName());
			testFactory.initStudentData(IEN_Helper.getApiName(), false);
        }
    }

    /**
     * @description Test job generator
     */
    @IsTest
    static void testJobGeneratorWithMultipleRecordsAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){

            Test.startTest();
            Map<Id, reduivy__Study_Offering__c> sofMaps = new Map<Id, reduivy__Study_Offering__c>([
                SELECT Id,
                Name,
                (
                    SELECT Id
                    FROM reduivy__Individual_Enrollments__r
                    WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
                )
                FROM reduivy__Study_Offering__c
            ]);

            Integer totalSofWithStudents = 0;
            for (reduivy__Study_Offering__c sof : sofMaps.values()) {
                if (!sof.reduivy__Individual_Enrollments__r.isEmpty()) {
                    totalSofWithStudents ++;
                }
            }

            reduivy__Job_Queue_Config__mdt jobConfig = JQH_Helper.getJobOperationSettings('Sample_Job');
            Map<String, Object> params = new Map<String, Object>();
            params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'sameJobOperationContext');

            reduivy__Job_Queue_Group__c jobQueueGroup = REDU_TestData_UTIL.newJobQueueGroup('sameJobOperationContext', 'sameJobOperationContext');
            REDU_Database_UTIL.doInsert(new List<reduivy__Job_Queue_Group__c>{jobQueueGroup});

            JQH_JobGenerator_QUEUE generatorQueue = new JQH_JobGenerator_QUEUE();
            generatorQueue.setJobConfig(jobConfig);
            generatorQueue.setParams(params);
            generatorQueue.setRecordIdsList(REDU_List_UTIL.getPageIterable(new List<Id>(sofMaps.keySet()), generatorQueue.getGeneratorBatchSize()));
            generatorQueue.setStartWorker(true);
            generatorQueue.setJobQueueGroupId(jobQueueGroup.Id);

            System.enqueueJob(generatorQueue);

            Test.stopTest();

            List<reduivy__Job_Queue__c> jobQueues = [SELECT Id, 
                Name, 
                reduivy__Job_Operation__c,
                reduivy__Job_Operation_Context__c,
                reduivy__Status__c,
                reduivy__Source_Record_Id__c,
                reduivy__Source_Record_Name__c,
                reduivy__Job_Queue_Group__c
                FROM reduivy__Job_Queue__c    
            ];

            System.Assert.isFalse(jobQueues.isEmpty(), 'There should be jobs in the queues.');
            System.Assert.areEqual(totalSofWithStudents, jobQueues.size());

            for (reduivy__Job_Queue__c jobQueue : jobQueues) {
                System.Assert.isTrue(String.isNotBlank(jobQueue.reduivy__Job_Operation_Context__c));
                System.Assert.areEqual('sameJobOperationContext', jobQueue.reduivy__Job_Operation_Context__c);
                System.Assert.isTrue(String.isNotBlank(jobQueue.reduivy__Source_Record_Id__c));
                System.Assert.isTrue(String.isNotBlank(jobQueue.reduivy__Source_Record_Name__c));
                System.Assert.areEqual(jobQueue.reduivy__Source_Record_Name__c, sofMaps.get(jobQueue.reduivy__Source_Record_Id__c).Name);
                System.Assert.isNotNull(jobQueue.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
                System.Assert.areEqual(jobQueueGroup.Id, jobQueue.reduivy__Job_Queue_Group__c);
            }
            

            List<reduivy__Log__c> logs = [SELECT Id,
                Name,
                reduivy__Reference__c,
                reduivy__Type__c
                FROM reduivy__Log__c
                WHERE reduivy__Job_Queue_Group__c =: jobQueueGroup.Id
            ];

            System.Assert.isFalse(logs.isEmpty(), 'There should be logs for the async execution.');
            System.Assert.areEqual(2, logs.size(), 'There should be 2 logs: job started and job completed log.');

            Boolean foundStartLog = false;
            Boolean foundCompletedLog = false;

            String startedLogTitle = String.format(Label.Job_Started_Log, new List<String>{jobConfig.reduivy__Job_Generator_Class_Name__c});
            String completedLogTitle = String.format(Label.Job_Completed_Log_Title, new List<String>{jobConfig.reduivy__Job_Generator_Class_Name__c});

            for (reduivy__Log__c log : logs) {
                if (log.Name == startedLogTitle) {
                    foundStartLog = true;
                } else if (log.Name == completedLogTitle) {
                    foundCompletedLog = true;
                }
            }

            System.Assert.isTrue(foundStartLog, 'There should be 1 job started log.');
            System.Assert.isTrue(foundCompletedLog, 'There should be 1 job completed log.');
        }
        
    }

    /**
     * @description Test job generator with smaller batch just to simulate the reinvocation of JQH_JobGenerator_QUEUE to have better code coverage although the next job won't be chained
     */
    @IsTest
    static void testJobGeneratorWithBatchSizeOneAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){

            Test.startTest();
            Map<Id, reduivy__Study_Offering__c> sofMaps = new Map<Id, reduivy__Study_Offering__c>([
                SELECT Id,
                Name,
                (
                    SELECT Id
                    FROM reduivy__Individual_Enrollments__r
                    WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
                )
                FROM reduivy__Study_Offering__c
            ]);

            Integer totalSofWithStudents = 0;
            for (reduivy__Study_Offering__c sof : sofMaps.values()) {
                if (!sof.reduivy__Individual_Enrollments__r.isEmpty()) {
                    totalSofWithStudents ++;
                }
            }

            //we clone the config here so that we can modify the value
            reduivy__Job_Queue_Config__mdt jobConfig = JQH_Helper.getJobOperationSettings('Sample_Job').clone(false, true, false, false);
            jobConfig.reduivy__Job_Generator_Batch_Size__c = 1;

            Map<String, Object> params = new Map<String, Object>();
            params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'sameJobOperationContext');

            reduivy__Job_Queue_Group__c jobQueueGroup = REDU_TestData_UTIL.newJobQueueGroup('sameJobOperationContext', 'sameJobOperationContext');
            REDU_Database_UTIL.doInsert(new List<reduivy__Job_Queue_Group__c>{jobQueueGroup});

            JQH_JobGenerator_QUEUE generatorQueue = new JQH_JobGenerator_QUEUE();
            generatorQueue.setJobConfig(jobConfig);
            generatorQueue.setParams(params);
            generatorQueue.setRecordIdsList(REDU_List_UTIL.getPageIterable(new List<Id>(sofMaps.keySet()), generatorQueue.getGeneratorBatchSize()));
            generatorQueue.setStartWorker(true);
            generatorQueue.setJobQueueGroupId(jobQueueGroup.Id);

            System.enqueueJob(generatorQueue);

            Test.stopTest();

            List<reduivy__Job_Queue__c> jobQueues = [SELECT Id, 
                Name, 
                reduivy__Job_Operation__c,
                reduivy__Job_Operation_Context__c,
                reduivy__Status__c,
                reduivy__Source_Record_Id__c,
                reduivy__Source_Record_Name__c,
                reduivy__Job_Queue_Group__c
                FROM reduivy__Job_Queue__c    
            ];

            System.Assert.isFalse(jobQueues.isEmpty(), 'There should be jobs in the queues.');
            System.Assert.areEqual(1, jobQueues.size(), 'There should be only 1 job in the queue as we set the batch size to 1.');

            for (reduivy__Job_Queue__c jobQueue : jobQueues) {
                System.Assert.isTrue(String.isNotBlank(jobQueue.reduivy__Job_Operation_Context__c));
                System.Assert.areEqual('sameJobOperationContext', jobQueue.reduivy__Job_Operation_Context__c);
                System.Assert.isTrue(String.isNotBlank(jobQueue.reduivy__Source_Record_Id__c));
                System.Assert.isTrue(String.isNotBlank(jobQueue.reduivy__Source_Record_Name__c));
                System.Assert.areEqual(jobQueue.reduivy__Source_Record_Name__c, sofMaps.get(jobQueue.reduivy__Source_Record_Id__c).Name);
                System.Assert.isNotNull(jobQueue.reduivy__Job_Queue_Group__c, 'The job queue should have a job queue group.');
                System.Assert.areEqual(jobQueueGroup.Id, jobQueue.reduivy__Job_Queue_Group__c);
            }
            

            List<reduivy__Log__c> logs = [SELECT Id,
                Name,
                reduivy__Reference__c,
                reduivy__Type__c
                FROM reduivy__Log__c
                WHERE reduivy__Job_Queue_Group__c =: jobQueueGroup.Id
            ];

            System.Assert.isFalse(logs.isEmpty(), 'There should be logs for the async execution.');
            System.Assert.areEqual(2, logs.size(), 'There should be 2 logs: job started and job completed log.');

            Boolean foundStartLog = false;
            Boolean foundCompletedLog = false;

            String startedLogTitle = String.format(Label.Job_Started_Log, new List<String>{jobConfig.reduivy__Job_Generator_Class_Name__c});
            String completedLogTitle = String.format(Label.Job_Completed_Log_Title, new List<String>{jobConfig.reduivy__Job_Generator_Class_Name__c});

            for (reduivy__Log__c log : logs) {
                if (log.Name == startedLogTitle) {
                    foundStartLog = true;
                } else if (log.Name == completedLogTitle) {
                    foundCompletedLog = true;
                }
            }

            System.Assert.isTrue(foundStartLog, 'There should be 1 job started log.');
            System.Assert.isTrue(foundCompletedLog, 'There should be 1 job completed log.');
        }
        
    }

    /**
     * @description Test job generator with invalid generator class name to simulate error handling
     */
    @IsTest
    static void testJobGeneratorWithInvalidClassAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){

            Test.startTest();
            Map<Id, reduivy__Study_Offering__c> sofMaps = new Map<Id, reduivy__Study_Offering__c>([
                SELECT Id,
                Name,
                (
                    SELECT Id
                    FROM reduivy__Individual_Enrollments__r
                    WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
                )
                FROM reduivy__Study_Offering__c
            ]);

            Integer totalSofWithStudents = 0;
            for (reduivy__Study_Offering__c sof : sofMaps.values()) {
                if (!sof.reduivy__Individual_Enrollments__r.isEmpty()) {
                    totalSofWithStudents ++;
                }
            }

            //we clone the config here so that we can modify the value
            reduivy__Job_Queue_Config__mdt jobConfig = JQH_Helper.getJobOperationSettings('Sample_Job').clone(false, true, false, false);
            jobConfig.reduivy__Job_Generator_Class_Name__c = 'Invalidclass';

            Map<String, Object> params = new Map<String, Object>();

            reduivy__Job_Queue_Group__c jobQueueGroup = REDU_TestData_UTIL.newJobQueueGroup('sameJobOperationContext', 'sameJobOperationContext');
            REDU_Database_UTIL.doInsert(new List<reduivy__Job_Queue_Group__c>{jobQueueGroup});

            JQH_JobGenerator_QUEUE generatorQueue = new JQH_JobGenerator_QUEUE();
            generatorQueue.setJobConfig(jobConfig);
            generatorQueue.setParams(params);
            generatorQueue.setRecordIdsList(REDU_List_UTIL.getPageIterable(new List<Id>(sofMaps.keySet()), generatorQueue.getGeneratorBatchSize()));
            generatorQueue.setStartWorker(true);
            generatorQueue.setJobQueueGroupId(jobQueueGroup.Id);

            System.enqueueJob(generatorQueue);

            Test.stopTest();            

            List<reduivy__Log__c> logs = [SELECT Id,
                Name,
                reduivy__Reference__c,
                reduivy__Type__c
                FROM reduivy__Log__c
                WHERE reduivy__Job_Queue_Group__c =: jobQueueGroup.Id
            ];

            System.Assert.isFalse(logs.isEmpty(), 'There should be logs for the async execution.');
            System.Assert.areEqual(2, logs.size(), 'There should be 2 logs: job started and job completed log.');

            Boolean foundStartLog = false;
            Boolean foundFailedLog = false;

            String startedLogTitle = String.format(Label.Job_Started_Log, new List<String>{jobConfig.reduivy__Job_Generator_Class_Name__c});
            String failedLogTitle = String.format(Label.Job_Failed_Log_Title, new List<String>{jobConfig.reduivy__Job_Generator_Class_Name__c});

            for (reduivy__Log__c log : logs) {
                if (log.Name == startedLogTitle) {
                    foundStartLog = true;
                } else if (log.Name == failedLogTitle) {
                    foundFailedLog = true;
                }
            }

            System.Assert.isTrue(foundStartLog, 'There should be 1 job started log.');
            System.Assert.isTrue(foundFailedLog, 'There should be 1 job failed log.');
        }
        
    }
}