/**
 * @Author 		WDCi (Lean)
 * @Date 		Jan 2025
 * @group 		Job Queue Framework
 * @Description Cancel job quick action
 * @changehistory
 * ISS-002219 06-01-2025 Lean - cancel job quick action
 * ISS-002547 11-07-2025 Lean - Added support for job queue group
 */
public with sharing class REDU_JqhCancelJob_LCTRL {
    
    @AuraEnabled
    public static REDU_LightningResponse cancelJob(Id jobQueueId){

        try {

            if (String.isNotBlank(jobQueueId)) {

                JQH_JobManager.cancelJob(jobQueueId);

                if (jobQueueId.getSobjectType() == Schema.reduivy__Job_Queue__c.getSobjectType()) {
                    return new REDU_LightningResponse(true, Label.Job_Queue_Was_Cancelled, null);
                } else {
                    return new REDU_LightningResponse(true, Label.Job_Queue_Group_Was_Cancelled, null);
                }
                
            } else {
                String errorMsg = String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{'', JQG_Helper.getObjectLabel() + '/' + JQH_Helper.getObjectLabel()});
                throw new REDU_ApplicationException(errorMsg);
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