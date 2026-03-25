/**
 * @author      WDCi (XW)
 * @date        May 2025
 * @group       Enrollment Wizard
 * @description To withdraw the student from the term
 * @changehistory
 * ISS-002436 05-05-2025 XW - create new class
 */

public with sharing class REDU_IpePathwayWithdrawFromTerm_LCTRL {

    /**
     * @description get related of inprogress individual enrollment of the individual academic progress and student record type id
     * @param  iprId the ipr id
     * @return       REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualEnrollments(String iprId, String statusesForWithdrawal){

        try {
            List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
            List<List<reduivy__Individual_Enrollment__c>> ienListList = IPR_Helper.getIndividualEnrollments(new Map<Id, String> {Id.valueOf(iprId) => statusesForWithdrawal}).values();
            if(ienListList != null && !ienListList.isEmpty()){
                ienList = ienListList[0];
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(ienList));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description get the default withdraw status
     * @return   REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getDefaultWithdrawnStatus(){
        try{
            List<String> withdrawnStatuses = IEN_Helper.getWithdrawnStatuses();
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, withdrawnStatuses.isEmpty() ? null : withdrawnStatuses[0]);
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description update the enrollment status of the inprogress ien
     * @param  recordIds        list of record id to update
     * @param  statusesForWithdrawal ien statuses to be considered to withdraw
     * @param  enrollmentStatus the enrollment status to be updated to
     * @return                  REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse updateEnrollmentStatus(String iprId, List<String> ienIdList, String enrollmentStatus){
        SavePoint sp = Database.setSavepoint();
        try {
            Map<String, List<String>> ienIdListByIprIdMap = new Map<String, List<String>>{
                iprId => ienIdList
            };

            List<String> updatedIenIdList = new List<String>();
            Map<String, List<String>> updatedIenIdMap = IPR_Helper.unenrollIpr(
                ienIdListByIprIdMap,
                new Map<String, String>{
                    iprid => enrollmentStatus
                }
            );
            if(updatedIenIdMap != null && !updatedIenIdMap.isEmpty()) {
                updatedIenIdList = updatedIenIdMap.values()[0];
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(updatedIenIdList));
            
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            Database.rollback(sp);
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

}