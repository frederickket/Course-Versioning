/**
 * @Author 		WDCi (Lean)
 * @Date 		Jan 2025
 * @group 		Job Queue Framework
 * @Description Retry job quick action
 * @changehistory
 * ISS-002219 06-01-2025 Lean - retry job quick action
 * ISS-002547 10-07-2025 Lean - support job queue group and removed return data as it is no longer needed
 */
public with sharing class REDU_JqhRetryJob_LCTRL {
    
    @AuraEnabled
    public static REDU_LightningResponse retryJob(Id jobQueueId, String selectedRetryOption){

        try {
            JQH_JobManager.retryJob(jobQueueId, selectedRetryOption, true);

            return new REDU_LightningResponse(true, Label.Job_Queue_Was_Submitted_For_Retry, null);

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}