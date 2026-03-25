/**
 * @Author 		WDCi (XiRouh)
 * @Date 		Feb 2025
 * @group 		Job Queue Framework
 * @Description Retry job confirmation modal
 * @changehistory
 * ISS-002229 28-02-2025 XiRouh - retry job confirmation modal
 * ISS-002547 10-07-2025 Lean - support job queue group and removed return data as it is no longer needed
 */
public with sharing class REDU_JqhRetryJobConfirmationModal_LCTRL {
    
    @AuraEnabled
    public static REDU_LightningResponse retryJob(List<Id> jobQueueIds, String selectedRetryOption){

        try {
            Set<Id> jobQueueSet = new Set<Id>(jobQueueIds);
            JQH_JobManager.retryJobs(jobQueueSet, selectedRetryOption, true);

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