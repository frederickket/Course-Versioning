/**
 * @author      WDCi (Lean)
 * @date        Dec 2024
 * @group       Job Queue Framework
 * @description The job generator queueable class
 * @changehistory
 * ISS-002219 19-12-2024 Lean - new class
 * ISS-002547 09-07-2025 Lean - enhanced to support job queue group
 */
public inherited sharing class JQH_JobGenerator_QUEUE implements Queueable {

    /**
     * @description List of record id list
     */
    List<List<Id>> recordIdsList;

    /**
     * @description Map of params
     */
    Map<String, Object> params;

    /**
     * @description Job config custom metadata
     */
    reduivy__Job_Queue_Config__mdt jobConfig;

    /**
     * @description Flag to start worker
     */
    Boolean startWorker;

    /**
     * @description List of record id to be processed
     */
    List<Id> recordIds;

    /**
     * @description ISS-002547 Job queue group id
     */
    Id jobQueueGroupId;

    /**
     * @description Default constructor
     */
    public JQH_JobGenerator_QUEUE() {
        this.recordIdsList = new List<List<Id>>();
        this.params = new Map<String, Object>();
        this.startWorker = true;
    }

    /**
     * @description Set record ids to be queried
     * @param recordIds List of record id
     * @return void
     */
    public void setRecordIdsList(List<List<Id>> recordIdsList) {
        this.recordIdsList = recordIdsList;
    }

    /**
     * @description Set parameters for the generator
     * @param params Map of params in key value pair
     * @return void
     */
    public void setParams(Map<String, Object> params) {
        this.params = params;
    }

    /**
     * @description Set job config for the generator
     * @param params Map of params in key value pair
     * @return void
     */
    public void setJobConfig(reduivy__Job_Queue_Config__mdt jobConfig) {
        this.jobConfig = jobConfig;
    }

    /**
     * @description Set start worker
     * @param startWorker
     * @return void
     */
    public void setStartWorker(Boolean startWorker) {
        this.startWorker = startWorker;
    }

    /**
     * @description ISS-002547 Set job queue group id to be reused for subsequent job generator execution
     * @param jobQueueGroupId
     * @return void
     */
    public void setJobQueueGroupId(Id jobQueueGroupId) {
        this.jobQueueGroupId = jobQueueGroupId;
    }

    /**
     * @description Return the generator batch size defined in the job queue config metadata
     * @return Integer
     */
    public Integer getGeneratorBatchSize() {
        if (this.jobConfig?.reduivy__Job_Generator_Batch_Size__c != null) {
            return Integer.valueOf(this.jobConfig.reduivy__Job_Generator_Batch_Size__c);
        }

        return REDU_List_UTIL.DEFAULT_ITERABLE_PAGE_SIZE;
    }

    /**
     * @description Return the generator class name
     */
    public String getGeneratorClassName() {
        return this.jobConfig?.reduivy__Job_Generator_Class_Name__c;
    }

    /**
     * @description JQH_JobGenerator_QUEUE execute.
     * @param ctx QueueableContext
     * @return void
     */
    public void execute(QueueableContext ctx) {
        logJobStarted();

        //pop the record id list
        if (recordIdsList == null || recordIdsList.isEmpty()) {
            this.recordIds = new List<Id>();
        } else {
            this.recordIds = new List<Id>(recordIdsList.get(0));

            recordIdsList.remove(0);
            this.recordIdsList = recordIdsList;
        }

        try {

            if(!this.recordIds.isEmpty()) {
                
                //invoke the job generator to compile the data required
                JQH_JobGenerator jobGenerator = JQH_Helper.getGeneratorClass(getGeneratorClassName());
                jobGenerator.setJobConfig(this.jobConfig);
                jobGenerator.setParams(this.params);
                jobGenerator.setRecordIds(this.recordIds);

                List<JQH_JobManager.GeneratorResult> results = jobGenerator.execute();
                List<JQH_JobQueue_OBJ> jobs = new List<JQH_JobQueue_OBJ>();

                //initiate job
                for (JQH_JobManager.GeneratorResult result : results) {
                    JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(this.jobConfig?.reduivy__Job_Operation__c, result.recordIds, result.params);
                    
                    //ISS-002547 set the job queue group id here as we need to share the same id for all batches and to avoid JQH_JobManager overriding it
                    job.setJobQueueGroupId(this.jobQueueGroupId);

                    jobs.add(job);
                }

                //queue jobs without starting the worker, we should only start the worker in the last batch
                JQH_JobManager.queueJobs(jobs, false);
            }

            logJobCompleted();

        } catch (Exception exp) {
            logJobFailed(exp);

        } finally {

            if (this.recordIdsList != null && !this.recordIdsList.isEmpty()) {
                //queue the next job if there are more records to be processed
                JQH_JobGenerator_QUEUE generatorQueue = new JQH_JobGenerator_QUEUE();
                generatorQueue.setJobConfig(this.jobConfig);
                generatorQueue.setRecordIdsList(this.recordIdsList);
                generatorQueue.setParams(this.params);
                generatorQueue.setStartWorker(this.startWorker);

                //ISS-002547 pass the job queue group id to the next batch
                generatorQueue.setJobQueueGroupId(this.jobQueueGroupId);

                if (!Test.isRunningTest()) {
                    //we are not allowed to chain job in test class
                    System.enqueueJob(generatorQueue);
                }

            } else {

                try {
                    //try to start the worker since there is no more batch to be processed
                    if (this.startWorker && !JQH_Helper.getPendingJobsForUser(UserInfo.getUserId()).isEmpty()) {
                        if (!Test.isRunningTest()) {
                            //we are not allowed to chain job in test class
                            JQH_JobManager.startWorker(null, false);
                        }
                    }

                } catch (DuplicateMessageException dme) {
                    //the user might have existing running job, should be safe to ignore the error
                }
            }
        }
    }

    /**
     * @description Create the job started log for audit and monitoring purposes
     * @return void
     */
    private void logJobStarted() {
        reduivy__Log__c startLog = REDU_Logging_UTIL.initAsyncJobStartedLog(getGeneratorClassName(), getGeneratorClassName(), this);
        JQH_Helper.linkLogToJobs(startLog, tempJobQueue());

        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Log__c>{startLog});
    }

    /**
     * @description Create the job completed log for audit and monitoring purposes
     * @return void
     */
    private void logJobCompleted() {
        reduivy__Log__c completedLog = REDU_Logging_UTIL.initAsyncJobCompletedLog(getGeneratorClassName(), getGeneratorClassName(), this);
        JQH_Helper.linkLogToJobs(completedLog, tempJobQueue());

        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Log__c>{completedLog});
    }

    /**
     * @description Create the job failed log for audit and monitoring purposes
     * @return void
     */
    private void logJobFailed(Exception exp) {
        reduivy__Log__c completedLog = REDU_Logging_UTIL.initAsyncJobFailedLog(getGeneratorClassName(), getGeneratorClassName(), exp.getMessage(), exp, this);
        JQH_Helper.linkLogToJobs(completedLog, tempJobQueue());

        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Log__c>{completedLog});
    }

    /**
     * @description Return a temp job queue object with job queue group id
     */
    private reduivy__Job_Queue__c tempJobQueue() {
        return new reduivy__Job_Queue__c(reduivy__Job_Queue_Group__c = this.jobQueueGroupId);
    }
}