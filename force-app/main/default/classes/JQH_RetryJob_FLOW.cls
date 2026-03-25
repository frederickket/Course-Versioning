/**
 * @author      WDCi (Lean)
 * @date        Dec 2024
 * @group       Job Queue Framework
 * @description The job queue invocable class for retrying a job
 * @changehistory
 * ISS-002219 31-12-2024 Lean - new class
 * ISS-002547 11-07-2025 Lean - Added support for job queue group
 */
global inherited sharing class JQH_RetryJob_FLOW {
    
    /**
     * @description Invocable method to retry a job via flow
     * @param requests
     * @return List<JQH_RetryJob_FLOW.Response>
     */
    @InvocableMethod(label='Retry a Job' description='Retry a job.' category='Job Queue')
    global static List<JQH_RetryJob_FLOW.Response> execute(List<JQH_RetryJob_FLOW.Request> requests) {
        
        String status = '';
        String msg = '';

        System.SavePoint sp = Database.setSavepoint();
        Boolean isSuccess = true;

        List<JQH_RetryJob_FLOW.Response> responses = new List<JQH_RetryJob_FLOW.Response>();
        Boolean startWorker = false;

        try {
            List<JQH_JobQueue_OBJ> retryJobs = new List<JQH_JobQueue_OBJ>();

            for (JQH_RetryJob_FLOW.Request request : requests) {
                //we will use the initRetryJobs here instead of retryJobs to support batch request in flow, we will queue the job separatedly after this
                List<JQH_JobQueue_OBJ> newRetryJobs = JQH_JobManager.initRetryJobs(new Set<Id>{request.jobQueueId}, (request.retryAllRecords ? JQH_Helper.RETRY_TYPE_ALL : JQH_Helper.RETRY_TYPE_ERROR_ONLY));

                startWorker = request.startWorker ? true : startWorker;

                retryJobs.addAll(newRetryJobs);
            }
            
            JQH_JobManager.queueJobs(retryJobs, startWorker);

            status = JQH_JobManager.SUCCESS;
            msg = Label.Job_Queue_Was_Submitted_For_Retry;

        } catch (Exception exp) {
            Database.rollback(sp);
            isSuccess = false;

            status = JQH_JobManager.FAIL;
            msg = exp.getMessage();

        } finally {

            for (JQH_RetryJob_FLOW.Request request : requests) {
                JQH_RetryJob_FLOW.Response response = new JQH_RetryJob_FLOW.Response();
                response.status = status;
                response.message = msg;

                responses.add(response);
            }
        }
        
        return responses;
    }

    /**
     * @description Request wrapper class
     */
    global class Request {

        @InvocableVariable(label='Job Queue Group/Job Queue Id' description='The job queue group or job queue id to be retried' required=true)
        global Id jobQueueId;

        @InvocableVariable(label='Retry All Records' description='To retry all records. Default is to retry error records only' required=true)
        global Boolean retryAllRecords;

        @InvocableVariable(label='Start Worker' description='To start the worker immediately')
        global Boolean startWorker;
    }

    /**
     * @description Response wrapper class
     */
    global class Response {
        @InvocableVariable(label='Job queue response status' description='The job queue response status e.g., success or fail')
        global String status;

        @InvocableVariable(label='Job queue response message' description='The job queue response message')
        global String message;
    }
}