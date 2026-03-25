/**
 * @author      WDCi (Lean)
 * @date        Dec 2024
 * @group       Job Queue Framework
 * @description The job handler worker queueable class
 * @changehistory
 * ISS-002219 20-12-2024 Lean - new class
 * ISS-002547 09-07-2025 Lean - enhanced to support job queue group
 */
public inherited sharing class JQH_JobWorker_QUEUE implements Queueable {
    
    /**
     * @description Job queue record
     */
    reduivy__Job_Queue__c jobQueue;
    
    /**
     * @description Last processed job queue id to prevent infinite loop
     */
    Id lastJobQueueId;

    /**
     * @description Default constructor
     */
    public JQH_JobWorker_QUEUE() {

        //Get the next available job from the queue
        reduivy__Job_Queue__c newJob = getNextJob();

        if (newJob != null){    
            this.jobQueue = newJob;

            //set job status to processing
            JQH_Helper.jobStarted(this.jobQueue);

            //job started log
            logJobStarted();
        }

    }

    /**
     * @description Set last processed job queue id
     */
    public void setLastJobQueueId(Id lastJobQueueId) {
        this.lastJobQueueId = lastJobQueueId;
    }

    /**
     * @description JQH_JobWorker_QUEUE execute method
     * @param ctx QueueableContext
     * @return void
     */
    public void execute(QueueableContext ctx) {

        if (getJobQueue() != null) {
            //we will terminate the worker if the same job is being picked up again to avoid infinite loop
            if (getJobQueue().Id != lastJobQueueId) {
                //init the finalizer for queueable
                JQH_JobWorker_FINALIZER jobWorkerFinalizer = new JQH_JobWorker_FINALIZER();
                System.attachFinalizer(jobWorkerFinalizer);
                
                try {                    
                    //set the job queue to finalizer
                    jobWorkerFinalizer.setFinalizerJobQueue(getJobQueue());

                    //convert job queue to invocable job object so that we can get the job handler
                    JQH_JobQueue_OBJ job = JQH_Helper.toJobObject(getJobQueue());

                    //execute the handler and add the results to finalizer
                    jobWorkerFinalizer.setFinalizerResults(job.getJobHandler().execute());

                } catch (Exception exp) {
                    //for unhandled exception, we assume that the handler exited without proper error handling, hence all records are considered error
                    JQH_JobManager.HandlerResult localErrorResults = new JQH_JobManager.HandlerResult();
                    for (Id recId : getRecordIds()) {
                        localErrorResults.addFailResult(recId, exp.getMessage() + ' ' + exp.getStackTraceString());
                    }

                    jobWorkerFinalizer.setFinalizerResults(localErrorResults);
                }
                
            } else {
                REDU_Logging_UTIL.logError(Label.Repeated_Job_Queue_Error_Title, lastJobQueueId, null, null, String.format(Label.Repeated_Job_Queue_Error_Description, new List<String>{lastJobQueueId}), null);
            }
        }
    }

    /**
     * @description Get the next job available in the queue
     * @return reduivy__Job_Queue__c
     */
    private reduivy__Job_Queue__c getNextJob() {
        return JQH_Helper.getNextJob();
    }

    /**
     * @description Return job queue record
     * @return reduivy__Job_Queue__c
     */
    private reduivy__Job_Queue__c getJobQueue() {
        return this.jobQueue;
    }

    /**
     * @description Return job operation name
     * @return String
     */
    private String getJobOperation() {
        return getJobQueue()?.reduivy__Job_Operation__c;
    }

    /**
     * @description Return job handler class name
     * @return String
     */
    private String getJobHandlerClassName() {
        return getJobQueue()?.reduivy__Job_Handler_Class_Name__c;
    }

    /**
     * @description Return list of record ids for job handler
     * @return List<Id>
     */
    private List<Id> getRecordIds() {
        return JQH_Helper.deserializeRecordIds(getJobQueue()?.reduivy__Job_Handler_Record_Ids__c);
    }

    /**
     * @description Create the job started log for audit and monitoring purposes
     * @return void
     */
    private void logJobStarted() {
        reduivy__Log__c startLog = REDU_Logging_UTIL.initAsyncJobStartedLog(getJobOperation(), getJobHandlerClassName(), this);
        JQH_Helper.linkLogToJobs(startLog, getJobQueue());

        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Log__c>{startLog});
    }

    
}