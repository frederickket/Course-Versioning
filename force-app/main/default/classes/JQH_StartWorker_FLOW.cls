/**
 * @author      WDCi (Lean)
 * @date        Dec 2024
 * @group       Job Queue Framework
 * @description The job queue invocable class for starting job worker
 * @changehistory
 * ISS-002219 20-12-2024 Lean - new class
 */
global inherited sharing class JQH_StartWorker_FLOW {
    
    /**
     * @description Invocable method to start job worker via flow
     * @param requests
     * @return List<JQH_StartWorker_FLOW.Response>
     */
    @InvocableMethod(label='Start Job Worker' description='Start the job worker.' category='Job Queue')
    global static List<JQH_StartWorker_FLOW.Response> execute(List<JQH_StartWorker_FLOW.Request> requests) {
        
        String status = '';
        String msg = '';

        System.SavePoint sp = Database.setSavepoint();
        Boolean isSuccess = true;

        List<JQH_StartWorker_FLOW.Response> responses = new List<JQH_StartWorker_FLOW.Response>();

        try {
            for (JQH_StartWorker_FLOW.Request request : requests) {
                //we will only invoke the start worker once using the first job to avoid duplicate async job error
                JQH_JobManager.startWorker(request.lastJobQueueId, false);
                break;
            }

            status = JQH_JobManager.SUCCESS;
            msg = Label.Job_Worker_Was_Started;

        } catch (Exception exp) {
            Database.rollback(sp);
            isSuccess = false;

            status = JQH_JobManager.FAIL;
            msg = exp.getMessage();

        } finally {

            for (JQH_StartWorker_FLOW.Request request : requests) {
                JQH_StartWorker_FLOW.Response response = new JQH_StartWorker_FLOW.Response();
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

        @InvocableVariable(label='Last Job Queue Id' description='The last processed job queue id if there is any')
        global Id lastJobQueueId;
    }

    /**
     * @description Response wrapper class
     */
    global class Response {
        @InvocableVariable(label='Job worker response status' description='The job worker response status e.g., success or fail')
        global String status;

        @InvocableVariable(label='Job worker response message' description='The job worker response message')
        global String message;
    }
}