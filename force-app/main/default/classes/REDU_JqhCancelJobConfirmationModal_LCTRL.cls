/**
 * @Author 		WDCi (XiRouh)
 * @Date 		Feb 2025
 * @group 		Job Queue Framework
 * @Description Cancel job confirmation modal
 * @changehistory
 * ISS-002229 28-02-2025 XiRouh - cancel job confirmation modal
 * ISS-002547 11-07-2025 Lean - Added support for job queue group
 */
public with sharing class REDU_JqhCancelJobConfirmationModal_LCTRL {
    
    @AuraEnabled
    public static REDU_LightningResponse cancelJob(List<Id> jobQueueIds){
        try {
            Set<Id> jobQueueSet = new Set<Id>(jobQueueIds);
    
            JQH_JobManager.cancelJobs(jobQueueSet);
    
            if (jobQueueIds.get(0).getSobjectType() == Schema.reduivy__Job_Queue__c.getSobjectType()) {
                return new REDU_LightningResponse(true, Label.Job_Queue_Was_Cancelled, null);
            } else {
                return new REDU_LightningResponse(true, Label.Job_Queue_Group_Was_Cancelled, null);
            }

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}