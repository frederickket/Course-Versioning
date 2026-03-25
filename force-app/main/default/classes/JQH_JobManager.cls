/**
 * @author      WDCi (Lean)
 * @date        Dec 2024
 * @group       Job Queue Framework
 * @description The job handler manager
 * @changehistory
 * ISS-002219 11-12-2024 Lean - new class
 * ISS-002547 09-07-2025 Lean - enhanced to support job queue group
 */
global abstract with sharing class JQH_JobManager {
    
    /**
     * @description success
     */
    public static final String SUCCESS = 'success';

    /**
     * @descripton fail
     */
    public static final String FAIL = 'fail';

    /**
     * @descripton worker batch size = 1
     */
    global static final Integer WORKER_BATCH_SIZE = 1;

    /**
     * @description Execute a generator queueable class to generate data for actual jobs
     * @param jobOperation
     * @param recordIds
     * @param params
     * @return void
     */
    global static void executeJobGenerator(String jobOperation, List<Id> recordIds, Map<String, Object> params, Boolean startWorker) {
        
        Savepoint sp = Database.setSavepoint();

        try {
            reduivy__Job_Queue_Config__mdt jobConfig = JQH_Helper.getJobOperationSettings(jobOperation);

            if (String.isNotBlank(jobConfig?.reduivy__Job_Generator_Class_Name__c)) {

                Integer generatorBatchSize = jobConfig?.reduivy__Job_Generator_Batch_Size__c != null ? 
                    Integer.valueOf(jobConfig.reduivy__Job_Generator_Batch_Size__c) 
                    : REDU_List_UTIL.DEFAULT_ITERABLE_PAGE_SIZE;

                List<List<Id>> recordIdsList = REDU_List_UTIL.getPageIterable(recordIds, generatorBatchSize);
                
                //ISS-002547 init job queue group for every job generation invokation
                String jobOperationContext = String.valueOf(params.get(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT));

                if (String.isNotBlank(jobOperationContext)) {
                    reduivy__Job_Queue_Group__c newJobQueueGroup = initNewJobQueueGroup(jobOperationContext);
                    REDU_Database_UTIL.doInsert(new List<reduivy__Job_Queue_Group__c>{newJobQueueGroup});

                    JQH_JobGenerator_QUEUE generatorQueue = new JQH_JobGenerator_QUEUE();
                    generatorQueue.setRecordIdsList(recordIdsList);
                    generatorQueue.setParams(params);
                    generatorQueue.setJobConfig(jobConfig);
                    generatorQueue.setStartWorker(startWorker);
                    generatorQueue.setJobQueueGroupId(newJobQueueGroup.Id);

                    System.enqueueJob(generatorQueue);
                } else {
                    throw new REDU_ApplicationException(Label.Missing_Job_Operation_Context);
                }
            } else {
                throw new REDU_ApplicationException(Label.Missing_Job_Generator_Class_Name);
            }

        } catch (Exception exp) {
            Database.rollback(sp);
            throw exp;
        }
    }

    /**
     * @description Init a new job
     * @param jobOperation The operation name
     * @param recordIds The record ids to be processed
     * @param params The parameters to be passed to the handler
     * @return JQH_JobQueue_OBJ
     */
    global static JQH_JobQueue_OBJ initNewJob(String jobOperation, List<Id> recordIds, Map<String, Object> params) {
        return new JQH_JobQueue_OBJ(jobOperation, recordIds, params);
    }

    /**
     * @description Add a job to the queue
     * @param job
     * @return void
     */
    global static void queueJob(JQH_JobQueue_OBJ job, Boolean startWorker) {
        queueJobs(new List<JQH_JobQueue_OBJ>{job}, startWorker);
    }

    /**
     * @description Add multiple jobs to the queue
     * @param job
     * @return void
     */
    global static void queueJobs(List<JQH_JobQueue_OBJ> jobs, Boolean startWorker) {
        
        Savepoint sp = Database.setSavepoint();

        try {
            startAsyncJob(jobs, startWorker);
        } catch (Exception exp) {
            Database.rollback(sp);
            throw new REDU_ApplicationException(exp.getMessage());
        }
    }

    /**
     * @description Cancel a job
     * @param jobQueueId
     * @return void
     */
    global static void cancelJob(Id jobQueueId) {
        
        cancelJobs(new Set<Id>{jobQueueId});
    }

    /**
     * @description Cancel multiple jobs
     * @param jobQueueIds
     * @return void
     */
    global static void cancelJobs(Set<Id> jobQueueIds) {
        
        Savepoint sp = Database.setSavepoint();

        try {
            Set<Id> byJobQueueIds = new Set<Id>();
            Set<Id> byJobQueueGroupIds = new Set<Id>();
            Set<Id> invalidIds = new Set<Id>();

            for (Id recId : jobQueueIds) {

                if (recId?.getSobjectType() == Schema.reduivy__Job_Queue__c.getSobjectType()) {
                    byJobQueueIds.add(recId);
                } else if (recId?.getSobjectType() == Schema.reduivy__Job_Queue_Group__c.getSobjectType()) {
                    byJobQueueGroupIds.add(recId);
                } else {
                    invalidIds.add(recId);
                }
            }

            //handle invalid record id error
            if (!invalidIds.isEmpty()) {
                String msg = String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{String.join(invalidIds, ', '), JQG_Helper.getObjectLabel() + '/' + JQH_Helper.getObjectLabel()});
                throw new REDU_ApplicationException(msg);
            }

            if (!byJobQueueIds.isEmpty()) {
                //handle job queue cancellation
                List<reduivy__Job_Queue__c> jobQueues = [SELECT Id, 
                    Name,
                    reduivy__Job_Operation__c,
                    reduivy__Status__c 
                    FROM reduivy__Job_Queue__c
                    WHERE Id IN: byJobQueueIds
                    WITH USER_MODE
                ];

                List<String> nonCancellabelJobNames = new List<String>();
                List<reduivy__Job_Queue__c> cancellabelJobList = new List<reduivy__Job_Queue__c>();

                for (reduivy__Job_Queue__c jobQueue : jobQueues) {
                    if (jobQueue.reduivy__Status__c == JQH_Helper.STATUS_PENDING || jobQueue.reduivy__Status__c == JQH_Helper.STATUS_DRAFT) {
                        jobQueue.reduivy__Status__c = JQH_Helper.STATUS_CANCELLED;

                        cancellabelJobList.add(jobQueue);
                    } else {
                        nonCancellabelJobNames.add(jobQueue.Name);
                    }
                }

                if (!nonCancellabelJobNames.isEmpty()) {
                    //exit if contains non cancellable jobs
                    String jobNames = String.join(nonCancellabelJobNames, ', ');
                    throw new REDU_ApplicationException(String.format(Label.Job_Queue_Cannot_Be_Cancelled, new List<String>{jobNames}));

                } else if (!cancellabelJobList.isEmpty()) {
                    REDU_Database_UTIL.doUpdate(cancellabelJobList);
                }
                
            }
            
            if (!byJobQueueGroupIds.isEmpty()) {
                //handle job queue group cancellation
                List<reduivy__Job_Queue_Group__c> jobQueueGroups = [SELECT Id,
                    Name,
                    reduivy__Status__c,                
                    (
                        SELECT Id,
                        Name,
                        reduivy__Job_Operation__c,
                        reduivy__Status__c,
                        reduivy__Job_Queue_Group__c
                        FROM reduivy__Job_Queues__r
                    )
                    FROM reduivy__Job_Queue_Group__c
                    WHERE Id IN: byJobQueueGroupIds
                    WITH USER_MODE
                ];

                List<String> nonCancellabelJobQueueGroupNames = new List<String>();
                List<reduivy__Job_Queue_Group__c> cancellabelJobQueueGroupList = new List<reduivy__Job_Queue_Group__c>();
                List<reduivy__Job_Queue__c> cancellabelJobList = new List<reduivy__Job_Queue__c>();

                for (reduivy__Job_Queue_Group__c jqg : jobQueueGroups) {
                    if (jqg.reduivy__Status__c == JQG_Helper.STATUS_PENDING || 
                        jqg.reduivy__Status__c == JQG_Helper.STATUS_DRAFT ||
                        jqg.reduivy__Status__c == JQG_Helper.STATUS_PROCESSING
                    ) {
                        //mark the job queue group as cancelled
                        reduivy__Job_Queue_Group__c jqgUpdate = new reduivy__Job_Queue_Group__c();
                        jqgUpdate.Id = jqg.Id;
                        jqgUpdate.reduivy__Status__c = JQH_Helper.STATUS_CANCELLED;

                        cancellabelJobQueueGroupList.add(jqgUpdate);

                        for (reduivy__Job_Queue__c jqh : jqg.reduivy__Job_Queues__r) {
                            if (jqh.reduivy__Status__c == JQH_Helper.STATUS_PENDING ||
                                jqh.reduivy__Status__c == JQH_Helper.STATUS_DRAFT
                            ) {
                                //mark the related job queues as cancelled, we will leave the completed, failed or processing jobs
                                reduivy__Job_Queue__c jqhUpdate = new reduivy__Job_Queue__c();
                                jqhUpdate.Id = jqh.Id;
                                jqhUpdate.reduivy__Status__c = JQH_Helper.STATUS_CANCELLED;

                                cancellabelJobList.add(jqhUpdate);
                            }
                        }

                    } else {
                        nonCancellabelJobQueueGroupNames.add(jqg.Name);
                    }
                }

                if (!nonCancellabelJobQueueGroupNames.isEmpty()) {
                    //exit if the job queue group can't be cancelled
                    String jobQueueGroupNames = String.join(nonCancellabelJobQueueGroupNames, ', ');
                    throw new REDU_ApplicationException(String.format(Label.Job_Queue_Group_Cannot_Be_Cancelled, new List<String>{jobQueueGroupNames}));

                } else if (!cancellabelJobQueueGroupList.isEmpty()) {
                    REDU_Database_UTIL.doUpdate(cancellabelJobList);
                    REDU_Database_UTIL.doUpdate(cancellabelJobQueueGroupList);
                }
            }
        } catch (Exception exp) {
            Database.rollback(sp);
            throw exp;
        }
    }

    /**
     * @description ISS-002547 Retry jobs
     * @param jobQueueId
     * @param retryType Retry All Records or Error Records Only
     * @param startWorker
     * @return void
     */
    global static void retryJob(Id jobQueueId, String retryType, Boolean startWorker) {
        retryJobs(new Set<Id>{jobQueueId}, retryType, startWorker);
    }

    /**
     * @description ISS-002547 Retry jobs
     * @param jobQueueId
     * @param retryType Retry All Records or Error Records Only
     * @param startWorker
     * @return void
     */
    global static void retryJobs(Set<Id> jobQueueIds, String retryType, Boolean startWorker) {

        Savepoint sp = Database.setSavepoint();

        try {
            List<JQH_JobQueue_OBJ> retryJobList= instantiateRetryJobs(jobQueueIds, retryType);

            if (!retryJobList.isEmpty()) {
                JQH_JobManager.queueJobs(retryJobList, startWorker);
            } else {
                throw new REDU_ApplicationException(Label.No_Failed_Job_Queue_Are_available_For_Retry);
            }
        } catch (Exception exp) {
            Database.rollback(sp);
            throw exp;
        }
    }

    /**
     * @description Obsolete. Init a new job for retry
     * @param jobQueueId
     * @param retryType Retry All Records or Error Records Only
     * @return JQH_JobQueue_OBJ
     */
    global static JQH_JobQueue_OBJ initRetryJob(Id jobQueueId, String retryType) {
        //ISS-002547
        throw new UnsupportedOperationException('The operation is obsolete. Please use retryJob() or retryJobs().');
    }

    /**
     * @description Init multiple new job for retry
     * @param jobQueueIds
     * @param retryType Retry All Records or Error Records Only
     * @return List<JQH_JobQueue_OBJ>
     */
    global static List<JQH_JobQueue_OBJ> initRetryJobs(Set<Id> jobQueueIds, String retryType) {
        return instantiateRetryJobs(jobQueueIds, retryType);
    }

    /**
     * @description Init multiple new job for retry
     * @param jobQueueIds
     * @param retryType Retry All Records or Error Records Only
     * @return List<JQH_JobQueue_OBJ>
     */
    public static List<JQH_JobQueue_OBJ> instantiateRetryJobs(Set<Id> jobQueueIds, String retryType) {

        Savepoint sp = Database.setSavepoint();

        try {
            Set<Id> byJobQueueIds = new Set<Id>();
            Set<Id> byJobQueueGroupIds = new Set<Id>();
            Set<Id> invalidIds = new Set<Id>();

            for (Id recId : jobQueueIds) {

                if (recId?.getSobjectType() == Schema.reduivy__Job_Queue__c.getSobjectType()) {
                    byJobQueueIds.add(recId);
                } else if (recId?.getSobjectType() == Schema.reduivy__Job_Queue_Group__c.getSobjectType()) {
                    byJobQueueGroupIds.add(recId);
                } else {
                    invalidIds.add(recId);
                }
            }

            //handle invalid record id error
            if (!invalidIds.isEmpty()) {
                String msg = String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{String.join(invalidIds, ', '), JQG_Helper.getObjectLabel() + '/' + JQH_Helper.getObjectLabel()});
                throw new REDU_ApplicationException(msg);
            }

            List<JQH_JobQueue_OBJ> retryJobList = new List<JQH_JobQueue_OBJ>();
            List<reduivy__Job_Queue__c> retriedAttemptedJobList = new List<reduivy__Job_Queue__c>();

            List<reduivy__Job_Queue__c> jobQueues = new List<reduivy__Job_Queue__c>();

            if (!byJobQueueIds.isEmpty()) {
                jobQueues = [SELECT Id, 
                    Name,
                    reduivy__Job_Operation__c,
                    reduivy__Job_Operation_Context__c,
                    reduivy__Job_Handler_Class_Name__c,
                    reduivy__Job_Handler_Record_Ids__c,
                    reduivy__Job_Handler_Error_Record_Ids__c,
                    reduivy__Job_Handler_Warning_Record_Ids__c,
                    reduivy__Job_Handler_Success_Record_Ids__c,
                    reduivy__Job_Handler_Params__c,
                    reduivy__Number_of_Attempts__c,
                    reduivy__Origin_Job_Queue_ID__c,
                    reduivy__Retry_Attempted__c,
                    reduivy__Source_Record_Id__c,
                    reduivy__Source_Record_Name__c,
                    reduivy__Status__c,
                    reduivy__Job_Queue_Group__c
                    FROM reduivy__Job_Queue__c
                    WHERE Id IN: jobQueueIds
                    WITH USER_MODE
                ];
            }

            if (!byJobQueueGroupIds.isEmpty()) {
                List<reduivy__Job_Queue_Group__c> jobQueueGroups = [SELECT Id,
                    Name,
                    reduivy__Status__c,                
                    (
                        SELECT Id,
                        Name,
                        reduivy__Job_Operation__c,
                        reduivy__Job_Operation_Context__c,
                        reduivy__Job_Handler_Class_Name__c,
                        reduivy__Job_Handler_Record_Ids__c,
                        reduivy__Job_Handler_Error_Record_Ids__c,
                        reduivy__Job_Handler_Warning_Record_Ids__c,
                        reduivy__Job_Handler_Success_Record_Ids__c,
                        reduivy__Job_Handler_Params__c,
                        reduivy__Number_of_Attempts__c,
                        reduivy__Origin_Job_Queue_ID__c,
                        reduivy__Retry_Attempted__c,
                        reduivy__Source_Record_Id__c,
                        reduivy__Source_Record_Name__c,
                        reduivy__Status__c,
                        reduivy__Job_Queue_Group__c
                        FROM reduivy__Job_Queues__r
                    )
                    FROM reduivy__Job_Queue_Group__c
                    WHERE Id IN: byJobQueueGroupIds
                    WITH USER_MODE
                ];

                List<String> nonRetryableJobQueueGroupNames = new List<String>();
                for(reduivy__Job_Queue_Group__c jqg : jobQueueGroups) {
                    if (jqg.reduivy__Status__c != JQG_Helper.STATUS_PENDING && jqg.reduivy__Status__c != JQG_Helper.STATUS_PROCESSING) {
                        for (reduivy__Job_Queue__c jobQueue : jqg.reduivy__Job_Queues__r) {
                            jobQueues.add(jobQueue);
                        }
                    } else {
                        nonRetryableJobQueueGroupNames.add(jqg.Name);
                    }
                }

                if (!nonRetryableJobQueueGroupNames.isEmpty()) {
                    //error and exit if found one of the jobs cannot be retried
                    String jobNames = String.join(nonRetryableJobQueueGroupNames, ', ');
                    throw new REDU_ApplicationException(String.format(Label.Job_Queue_Cannot_Be_Retried, new List<String>{jobNames}));
                }
            }

            if (!jobQueues.isEmpty()) {

                List<String> nonRetryableJobNames = new List<String>();
                List<String> retryableJobNames = new List<String>();
                List<reduivy__Job_Queue__c> retryableJobList = new List<reduivy__Job_Queue__c>();

                for (reduivy__Job_Queue__c jobQueue : jobQueues) {
                    if (jobQueue.reduivy__Status__c != JQH_Helper.STATUS_PENDING && jobQueue.reduivy__Status__c != JQH_Helper.STATUS_PROCESSING) {
                        //store the list and name for query later
                        retryableJobList.add(jobQueue);
                        retryableJobNames.add(jobQueue.Name);
                    } else {
                        //store the name for error message
                        nonRetryableJobNames.add(jobQueue.Name);
                    }
                }

                if (!nonRetryableJobNames.isEmpty()) {
                    //error and exit if found one of the jobs cannot be retried
                    String jobNames = String.join(nonRetryableJobNames, ', ');
                    throw new REDU_ApplicationException(String.format(Label.Job_Queue_Cannot_Be_Retried, new List<String>{jobNames}));

                } else if (!retryableJobList.isEmpty()) {
                    //process the retryable jobs
                    Map<String, reduivy__Job_Queue__c> previousRetryJobQueueMap = new Map<String, reduivy__Job_Queue__c>();

                    for (reduivy__Job_Queue__c previousRetryJob : [SELECT Id,
                        Name,
                        reduivy__Number_of_Attempts__c,
                        reduivy__Origin_Job_Queue_ID__c
                        FROM reduivy__Job_Queue__c
                        WHERE reduivy__Origin_Job_Queue_ID__c IN: retryableJobNames
                        WITH USER_MODE
                        ORDER BY reduivy__Number_of_Attempts__c ASC, CreatedDate ASC
                    ]) {
                        previousRetryJobQueueMap.put(previousRetryJob.reduivy__Origin_Job_Queue_ID__c, previousRetryJob);
                    }

                    for (reduivy__Job_Queue__c jobQueue : retryableJobList) {
                        String recordIdsString;
                        //ISS-002547 technically we only support retry error records, but leaving the logic here just in case
                        if (retryType == JQH_Helper.RETRY_TYPE_ERROR_ONLY) {
                            recordIdsString = jobQueue.reduivy__Job_Handler_Error_Record_Ids__c;
                        } else {
                            recordIdsString = jobQueue.reduivy__Job_Handler_Record_Ids__c;
                        }

                        //ISS-002547 skip the record if there is no recordIds to retry
                        if (String.isBlank(recordIdsString)) {
                            continue;
                        }

                        //update the selected job's flag to indicate that someone has retried it before
                        reduivy__Job_Queue__c updateJobRetried = new reduivy__Job_Queue__c(
                            Id = jobQueue.Id,
                            reduivy__Retry_Attempted__c = true
                        );

                        retriedAttemptedJobList.add(updateJobRetried);

                        //init retry job
                        List<Id> retryRecordIds = JQH_Helper.deserializeRecordIds(recordIdsString);
                        Map<String, Object> retryParams = JQH_Helper.deserializeParams(jobQueue.reduivy__Job_Handler_Params__c);
                        retryParams.put(JQH_JobQueue_OBJ.PARAM_IS_RETRY, true);
                        retryParams.put(JQH_JobQueue_OBJ.PARAM_LAST_ATTEMPT_COUNT, (previousRetryJobQueueMap.containsKey(jobQueue.Name) ? previousRetryJobQueueMap.get(jobQueue.Name).reduivy__Number_of_Attempts__c : 1));
                        retryParams.put(JQH_JobQueue_OBJ.PARAM_RETRY_ORIGIN_JOB_QUEUE_NO, jobQueue.Name);

                        JQH_JobQueue_OBJ retryJob = JQH_JobManager.initNewJob(jobQueue.reduivy__Job_Operation__c, retryRecordIds, retryParams);

                        retryJobList.add(retryJob);
                    }
                }

                if (!retriedAttemptedJobList.isEmpty()) {
                    //update the current job with Retry Attempted = true
                    REDU_Database_UTIL.doUpdate(retriedAttemptedJobList);
                }
                
            }
            
            //return the new list for retry job
            return retryJobList;

        } catch (Exception exp) {
            Database.rollback(sp);
            throw exp;
        }
    }

    /**
     * @description Delete the jobs and logs related to a job context
     * @param jobQueueId
     * @return void
     */
    global static void clearJobHistory(String jobOperationContext) {

        Set<String> statusesToBeDeleted = new Set<String>{
            JQG_Helper.STATUS_DRAFT,
            JQG_Helper.STATUS_CANCELLED,
            JQG_Helper.STATUS_COMPLETED,
            JQG_Helper.STATUS_FAILED
        };
        
        List<reduivy__Job_Queue_Group__c> jobQueueGroups = new List<reduivy__Job_Queue_Group__c>();

        for (reduivy__Job_Queue_Group__c jqg : [SELECT Id, 
            Name,
            reduivy__Job_Operation_Context__c
            FROM reduivy__Job_Queue_Group__c
            WHERE reduivy__Job_Operation_Context__c =: jobOperationContext
            AND reduivy__Status__c IN: statusesToBeDeleted
            WITH USER_MODE
        ]) {
            jobQueueGroups.add(jqg);
        }

        if (!jobQueueGroups.isEmpty()) {
            REDU_SystemMode_UTIL.doDelete(jobQueueGroups);
        }
    }

    /**
     * @description Save jobs to the queue table and try to start the worker
     * @param job
     * @return void
     */
    private static void startAsyncJob(List<JQH_JobQueue_OBJ> jobs, Boolean startWorker) {

        saveJobs(jobs);
        
        //we will only start the worker if it is free
        if (startWorker && isWorkerFree()) {
            startWorker(null, false);
        }
    }

    /**
     * @description ISS-002547 Init a new job queue group for the session
     * @param jobOperationContext
     */
    public static reduivy__Job_Queue_Group__c initNewJobQueueGroup(String jobOperationContext) {
        reduivy__Job_Queue_Group__c jobQueueGroup = new reduivy__Job_Queue_Group__c();
        jobQueueGroup.reduivy__Job_Operation_Context__c = jobOperationContext;
        jobQueueGroup.reduivy__Status__c = JQG_Helper.STATUS_DRAFT;

        return jobQueueGroup;
    }

    /**
     * @description ISS-002547 Job Queue Group for the session
     */
    private static Map<String, reduivy__Job_Queue_Group__c> jobQueueGroupByOperationContext;

    /**
     * @description Initiate the job queue group for the current run time based on the job operation context. We create different job group based on context to support the bulk invokation from flow e.g., scheduled or record triggered.
     * @param jobs
     */
    private static void initiateJobGroup(List<JQH_JobQueue_OBJ> jobs) {

        Set<String> jobOperationContexts = new Set<String>();
        List<reduivy__Job_Queue_Group__c> newJobQueueGroups = new List<reduivy__Job_Queue_Group__c>();
        List<JQH_JobQueue_OBJ> jobsNeedingGroup = new List<JQH_JobQueue_OBJ>();

        for (JQH_JobQueue_OBJ job : jobs) {
            //skip if it already has job queue id
            if (String.isBlank(job.getJobQueueGroupId())) {

                if (String.isNotBlank(job.getJobOperationContext())) {
                    jobOperationContexts.add(job.getJobOperationContext());

                    jobsNeedingGroup.add(job);
                } else {
                    throw new REDU_ApplicationException(Label.Missing_Job_Operation_Context);
                }
            }
        }

        if (!jobsNeedingGroup.isEmpty()) {

            if (jobQueueGroupByOperationContext == null) {
                jobQueueGroupByOperationContext = new Map<String, reduivy__Job_Queue_Group__c>();
            }

            for (String jobOperationContext : jobOperationContexts) {
                if (!jobQueueGroupByOperationContext.containsKey(jobOperationContext)) {
                    reduivy__Job_Queue_Group__c newJqg = initNewJobQueueGroup(jobOperationContext);

                    jobQueueGroupByOperationContext.put(jobOperationContext, newJqg);
                    newJobQueueGroups.add(newJqg);
                }
            }

            if (!newJobQueueGroups.isEmpty()) {
                REDU_Database_UTIL.doInsert(newJobQueueGroups);
            }

            for (JQH_JobQueue_OBJ job : jobsNeedingGroup) {
                job.setJobQueueGroupId(jobQueueGroupByOperationContext.get(job.getJobOperationContext()).Id);
            }
        }
    }

    /**
     * @description For Unit Testing only. Reset the job queue group map so that the data created in retry test is not linked to the same job queue group.
     */
    @TestVisible
    private static void clearJobQueueGroupsOperationContextCache() {
        jobQueueGroupByOperationContext = new Map<String, reduivy__Job_Queue_Group__c>();
    }

    /**
     * @description Split the job based on the batch size and save them in the queue table
     * @param job
     * @return void
     */
    private static void saveJobs(List<JQH_JobQueue_OBJ> jobs) {
        
        //ISS-002547 initiate the job queue group for each job queue
        initiateJobGroup(jobs);

        List<reduivy__Job_Queue__c> jobQueues = new List<reduivy__Job_Queue__c>();
        for (JQH_JobQueue_OBJ job : jobs) {
		    jobQueues.addAll(JQH_Helper.getBatchedJobQueues(job));
        }

		REDU_Database_UTIL.doInsert(jobQueues);
	}
	
	/**
     * @description Check for the async job list to see if the job worker batch is currently running
     * @return Boolean
     */
	private static Boolean isWorkerFree() {

        return JQH_Helper.isWorkerFree();
	}
	
    /**
     * @description Start the job worker batchable class
     * @param lastJobQueueId
     * @param isChained Indicates that the worker is continuously chained by queuable job
     * @return void
     */
	global static void startWorker(Id lastJobQueueId, Boolean isChained) {

        if (isWorkerFree()) {

            if (!isChained) {
                String msg = String.format(Label.Job_Worker_Started_Log_Details, new List<String>{UserInfo.getName(), lastJobQueueId});
                reduivy__Log__c workerStartedLog = REDU_Logging_UTIL.initAsyncJobStartedLog('JQH_JobWorker_QUEUE', null, msg);
                REDU_SystemMode_UTIL.doInsert(new List<reduivy__Log__c>{workerStartedLog});
            }

            AsyncOptions options = new AsyncOptions();
            options.DuplicateSignature = QueueableDuplicateSignature.Builder().addId(UserInfo.getUserId()).addString('JQH_JobWorker').build();
            
            JQH_JobWorker_QUEUE workerQueue = new JQH_JobWorker_QUEUE();
            workerQueue.setLastJobQueueId(lastJobQueueId);
            
            System.enqueueJob(workerQueue, options);

        }
	}

    /**
     * @description Handler result wrapper class
     */
    global inherited sharing class HandlerResult {

        /**
         * @description Fail result, the id will be added to the Job Handler's Error Record Ids
         */
        global Map<Id, List<String>> fail = new Map<Id, List<String>>();

        /**
         * @description Warning result, the id will be added to the Job Handlers' Warning Record Ids
         */
        global Map<Id, List<String>> warning = new Map<Id, List<String>>();

        /**
         * @description Success result, the id will be added to the Job Handler's Success Record Ids
         */
        global Map<Id, List<String>> success = new Map<Id, List<String>>();

        /**
         * @description Add fail result
         * @param recordId
         * @param message
         */
        global void addFailResult(Id recordId, String message) {
            if (this.fail == null) {
                this.fail = new Map<Id, List<String>>();
            }

            if (this.fail.containsKey(recordId)) {
                this.fail.get(recordId).add(message);
            } else {
                this.fail.put(recordId, new List<String>{message});
            }
        }

        /**
         * @description Add warning result
         * @param recordId
         * @param message
         */
        global void addWarningResult(Id recordId, String message) {
            if (this.warning == null) {
                this.warning = new Map<Id, List<String>>();
            }

            if (this.warning.containsKey(recordId)) {
                this.warning.get(recordId).add(message);
            } else {
                this.warning.put(recordId, new List<String>{message});
            }
        }

        /**
         * @description Add success result
         * @param recordId
         * @param message
         */
        global void addSuccessResult(Id recordId, String message) {
            if (this.success == null) {
                this.success = new Map<Id, List<String>>();
            }

            if (this.success.containsKey(recordId)) {
                this.success.get(recordId).add(message);
            } else {
                this.success.put(recordId, new List<String>{message});
            }
        }
    }

    /**
     * @description Generator result wrapper class
     */
    global inherited sharing class GeneratorResult {

        /**
         * @description List of record ids to pass to Job Handler from Job Generator
         */
        global List<Id> recordIds = new List<Id>();

        /**
         * @description Map of params in key value pair to pass to Job Handler from Job Generator
         */
        global Map<String, Object> params = new Map<String, Object>();
    }
}