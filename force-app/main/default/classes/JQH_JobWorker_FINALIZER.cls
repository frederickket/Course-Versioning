/**
 * @author      WDCi (Lean)
 * @date        Dec 2024
 * @group       Job Queue Framework
 * @description The job handler worker finalizer class for JQH_JobWorker_QUEUE
 * @changehistory
 * ISS-002219 20-12-2024 Lean - new class
 * ISS-002547 09-07-2025 Lean - enhanced to support job queue group
 */
public inherited sharing class JQH_JobWorker_FINALIZER implements finalizer {

    /**
     * @description Job queue record
     */
    reduivy__Job_Queue__c finalizerJobQueue;

    /**
     * @description Job handler processing results
     */
    JQH_JobManager.HandlerResult finalizerResults;

    /**
     * @description Default constructor
     */
    public JQH_JobWorker_FINALIZER() {

    }

    /**
     * @description Finalizer execute method
     * @param ctx FinalizerContext
     * @return void
     */
    public void execute(FinalizerContext ctx) {

        if (getJobQueue() != null) {

            //Check the queueable job status
            if (ctx.getResult() == ParentJobResult.SUCCESS) {
                //for success execution if handled exception, we will check the handler results
                Boolean isSuccess = this.finalizerResults.fail.isEmpty();

                //set the job status to completed/completed with error
                JQH_Helper.jobCompleted(getJobQueue(), this.finalizerResults);

                List<reduivy__Log__c> recordLogs = new List<reduivy__Log__c>();
                //create the log for every success id and link it to the job queue
                for (Id successId : this.finalizerResults.success.keySet()) {
                    reduivy__Log__c successLog = REDU_Logging_UTIL.initInfo(getJobOperation(), getJobHandlerClassName(), null, successId, String.join(this.finalizerResults.success.get(successId), '\n'));
                    JQH_Helper.linkLogToJobs(successLog, getJobQueue());

                    recordLogs.add(successLog);
                }

                //create the log for every warning id and link it to the job queue
                for (Id warningId : this.finalizerResults.warning.keySet()) {
                    reduivy__Log__c warningLog = REDU_Logging_UTIL.initWarning(getJobOperation(), getJobHandlerClassName(), null, warningId, String.join(this.finalizerResults.warning.get(warningId), '\n'));
                    JQH_Helper.linkLogToJobs(warningLog, getJobQueue());

                    recordLogs.add(warningLog);
                }

                //create the log for every error id and link it to the job queue
                for (Id errorId : this.finalizerResults.fail.keySet()) {
                    reduivy__Log__c errorLog = REDU_Logging_UTIL.initError(getJobOperation(), getJobHandlerClassName(), null, errorId, String.join(this.finalizerResults.fail.get(errorId), '\n'), null);
                    JQH_Helper.linkLogToJobs(errorLog, getJobQueue());

                    recordLogs.add(errorLog);
                }

                REDU_SystemMode_UTIL.doInsert(recordLogs);

                if (isSuccess) {
                    //log the job as completed
                    logJobCompleted();
                } else {
                    //log the job as completed with error
                    logJobCompletedWithError();
                }

            } else {
                //for unhandled exception, we assume that the handler exited without proper error handling, hence all records are considered error
                JQH_JobManager.HandlerResult localErrorResults = new JQH_JobManager.HandlerResult();
                for (Id recId : getRecordIds()) {
                    localErrorResults.addFailResult(recId, ctx.getException().getMessage());
                }

                //set the job status to completed/completed with error
                JQH_Helper.jobCompleted(getJobQueue(), localErrorResults);

                //log the job as failed
                logJobFailed(ctx.getException());
            }

            if (getNextJob() != null) {
                //restart the worker if there is a job available in the queue, note that we are not allowed to chain job in test class
                if (!Test.isRunningTest()) {
                    JQH_JobManager.startWorker(getJobQueue()?.Id, true);
                }
            } else {
                String msg = String.format(Label.Job_Worker_Completed_Log_Details, new List<String>{UserInfo.getName(), getJobQueue()?.Id});
                reduivy__Log__c workerCompletedLog = REDU_Logging_UTIL.initAsyncJobCompletedLog('JQH_JobWorker_QUEUE', null, msg);
                REDU_SystemMode_UTIL.doInsert(new List<reduivy__Log__c>{workerCompletedLog});
            }
        }
    }
    
    /**
     * @description Setter for finalizerJobQueue
     * @param finalizerJobQueue
     * @return void 
     */
    public void setFinalizerJobQueue(reduivy__Job_Queue__c finalizerJobQueue) {
        this.finalizerJobQueue = finalizerJobQueue;
    }

    /**
     * @description Setter for finalizerResults
     * @param finalizerResults
     * @return void
     */
    public void setFinalizerResults(JQH_JobManager.HandlerResult finalizerResults) {
        this.finalizerResults = finalizerResults;
    }

    /**
     * @description Return finalizerJobQueue
     * @return reduivy__Job_Queue__c
     */
    private reduivy__Job_Queue__c getJobQueue() {
        return this.finalizerJobQueue;
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
     * @description Return list of ids for job handler
     * @return List<Id>
     */
    private List<Id> getRecordIds() {
        return JQH_Helper.deserializeRecordIds(getJobQueue()?.reduivy__Job_Handler_Record_Ids__c);
    }

    /**
     * @description Return the next job available in the queue
     */
    private reduivy__Job_Queue__c getNextJob() {
        return JQH_Helper.getNextJob();
    }

    /**
     * @description Create the job completed log for audit and monitoring purposes
     * @return void
     */
    private void logJobCompleted() {
        reduivy__Log__c completedLog = REDU_Logging_UTIL.initAsyncJobCompletedLog(getJobOperation(), getJobHandlerClassName(), this);
        JQH_Helper.linkLogToJobs(completedLog, getJobQueue());
        
        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Log__c>{completedLog});
    }

    /**
     * @description Create the job completed with error log for audit and monitoring purposes
     * @return void
     */
    private void logJobCompletedWithError() {
        reduivy__Log__c completedLog = REDU_Logging_UTIL.initAsyncJobCompletedWithErrorLog(getJobOperation(), getJobHandlerClassName(), this);
        JQH_Helper.linkLogToJobs(completedLog, getJobQueue());

        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Log__c>{completedLog});
    }

    /**
     * @description Create the job failed log for audit and monitoring purposes
     * @return void
     */
    private void logJobFailed(Exception exp) {
        reduivy__Log__c completedLog = REDU_Logging_UTIL.initAsyncJobFailedLog(getJobOperation(), getJobHandlerClassName(), exp.getMessage(), exp, this);
        JQH_Helper.linkLogToJobs(completedLog, getJobQueue());

        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Log__c>{completedLog});
    }
}