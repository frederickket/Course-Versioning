/**
 * @Author 		WDCi (XiRouh)
 * @Date 		Feb 2025
 * @group 		Job Queue Framework
 * @Description Clear jobs confirmation modal
 * @changehistory
 * ISS-002229 28-02-2025 XiRouh - Clear jobs confirmation modal
 */
public with sharing class REDU_JqhClearJobsConfirmationModal_LCTRL {
    
    @AuraEnabled
    public static REDU_LightningResponse clearJobs(String jobOperation, String recordId){
        try {
            if (String.isBlank(recordId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'recordId'}));
            }

            if (String.isBlank(jobOperation)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'jobOperation'}));
            }
    
            String jobOperationContext = JQH_helper.getJobOperationContext(jobOperation, recordId);
            JQH_JobManager.clearJobHistory(jobOperationContext);
    
            return new REDU_LightningResponse(true, Label.Job_Queue_Was_Cleared, null);
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}