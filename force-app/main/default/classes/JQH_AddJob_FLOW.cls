/**
 * @author      WDCi (Lean)
 * @date        Dec 2024
 * @group       Job Queue Framework
 * @description The job queue invocable class for adding a new job
 * @changehistory
 * ISS-002219 20-12-2024 Lean - new class
 * ISS-002547 11-07-2025 Lean - Removed required attribute
 */
global inherited sharing class JQH_AddJob_FLOW {
    
    /**
     * @description Invocable method to add job to the queue via flow
     * @param requests
     * @return List<JQH_AddJob_FLOW.Response>
     */
    @InvocableMethod(label='Add Job To Queue' description='Initiate and add job to the job queue.' category='Job Queue')
    global static List<JQH_AddJob_FLOW.Response> execute(List<JQH_AddJob_FLOW.Request> requests) {
        
        String status = '';
        String msg = '';

        System.SavePoint sp = Database.setSavepoint();
        Boolean isSuccess = true;

        List<JQH_AddJob_FLOW.Response> responses = new List<JQH_AddJob_FLOW.Response>();
        Boolean startWorker = false;
        
        try {
            List<JQH_JobQueue_OBJ> newJobs = new List<JQH_JobQueue_OBJ>();

            for (JQH_AddJob_FLOW.Request request : requests) {

                String jobOperation = request.jobOperation;
                String jobOperationContext = request.jobOperationContext;

                List<Id> recordIds = request.recordIds;
                Map<String, Object> params = JQH_Helper.deserializeParams(request.paramsString);
                params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, jobOperationContext);
                
                startWorker = request.startWorker ? true : startWorker;

                JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(jobOperation, recordIds, params);
                newJobs.add(job);
            }
            
            JQH_JobManager.queueJobs(newJobs, startWorker);

            status = JQH_JobManager.SUCCESS;
            msg = Label.Job_Was_Added_To_Queue;

        } catch (Exception exp) {
            Database.rollback(sp);
            isSuccess = false;

            status = JQH_JobManager.FAIL;
            msg = exp.getMessage();

        } finally {

            for (JQH_AddJob_FLOW.Request request : requests) {
                JQH_AddJob_FLOW.Response response = new JQH_AddJob_FLOW.Response();
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

        @InvocableVariable(label='Job Operation Context' description='The job operation name to match the job config custom metadata type.' required=true)
        global String jobOperationContext;

        @InvocableVariable(label='Job Operation' description='The job operation name to match the job config custom metadata type.' required=true)
        global String jobOperation;

        @InvocableVariable(label='List of Record Ids' description='List of record ids to be processed.' required=true)
        global List<Id> recordIds;

        @InvocableVariable(label='Deserialized Params String' description='The deserialized JSON string that represents the key value pair params.')
        global String paramsString;

        @InvocableVariable(label='Start Worker' description='To start the worker immediately.')
        global Boolean startWorker;
    }

    /**
     * @description Response wrapper class
     */
    global class Response {
        @InvocableVariable(label='Job queue response status' description='The job queue response status e.g., success or fail.')
        global String status;

        @InvocableVariable(label='Job queue response message' description='The job queue response message.')
        global String message;
    }
}