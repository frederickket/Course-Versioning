/**
 * @author      WDCi (Lean)
 * @date        Dec 2024
 * @group       Job Queue Framework
 * @description The job queue invocable class for cancelling a job
 * @changehistory
 * ISS-002219 20-12-2024 Lean - new class
 * ISS-002547 11-07-2025 Lean - support job queue group
 */
global inherited sharing class JQH_CancelJob_FLOW {
    
    /**
     * @description Invocable method to cancel a job via flow
     * @param requests
     * @return List<JQH_CancelJob_FLOW.Response>
     */
    @InvocableMethod(label='Cancel a Job' description='Cancel a job.' category='Job Queue')
    global static List<JQH_CancelJob_FLOW.Response> execute(List<JQH_CancelJob_FLOW.Request> requests) {
        
        String status = '';
        String msg = '';

        System.SavePoint sp = Database.setSavepoint();
        Boolean isSuccess = true;

        List<JQH_CancelJob_FLOW.Response> responses = new List<JQH_CancelJob_FLOW.Response>();
        Map<Id, String> requestResponseMsgs = new Map<Id, String>();

        try {
            Set<Id> jobQueueIds = new Set<Id>();

            for (JQH_CancelJob_FLOW.Request request : requests) {

                String responseMsg;

                if (String.isNotBlank(request.jobQueueId)) {
                    
                    jobQueueIds.add(request.jobQueueId);
                    
                    if (request.jobQueueId.getSobjectType() == Schema.reduivy__Job_Queue__c.getSobjectType()) {
                        responseMsg = Label.Job_Queue_Was_Cancelled;
                    } else {
                        responseMsg = Label.Job_Queue_Group_Was_Cancelled;
                    }
                } else {
                    //invalid id error
                    responseMsg = String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{'', JQG_Helper.getObjectLabel() + '/' + JQH_Helper.getObjectLabel()});
                }

                requestResponseMsgs.put(request.jobQueueId, responseMsg);
            }

            JQH_JobManager.cancelJobs(jobQueueIds);

            status = JQH_JobManager.SUCCESS;
            
        } catch (Exception exp) {
            Database.rollback(sp);
            isSuccess = false;

            status = JQH_JobManager.FAIL;
            msg = exp.getMessage();

        } finally {

            for (JQH_CancelJob_FLOW.Request request : requests) {
                JQH_CancelJob_FLOW.Response response = new JQH_CancelJob_FLOW.Response();
                response.status = status;

                //set the response messsage
                response.message = isSuccess ? requestResponseMsgs.get(request.jobQueueId) : msg;

                responses.add(response);
            }
        }

        return responses;
    }

    /**
     * @description Request wrapper class
     */
    global class Request {

        @InvocableVariable(label='Job Queue Group or Job Queue Id' description='The job queue group or job queue id to be cancelled.' required=true)
        global Id jobQueueId;
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