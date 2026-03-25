/**
 * @author      WDCi (Lean)
 * @date        June 2025
 * @group       Enrollment Wizard
 * @description Enrollment finalization
 * @changehistory
 * ISS-002493 10-06-2025 Lean - new class
 */
public with sharing class REDU_IpePathwayEnrollmentFinalize_LCTRL {

    /**
     * @description Return the list of individual enrollments by the individual academic progress id
     * @param individualAcademicProgressId Individual academic progress id
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualEnrollments(String individualAcademicProgressId){

        try {
            Map<Id, List<reduivy__Individual_Enrollment__c>> ienListByIpr = IPR_Helper.getIndividualEnrollments(new Map<Id, String>{Id.valueOf(individualAcademicProgressId) => null});
            List<reduivy__Individual_Enrollment__c> ienList = ienListByIpr.containsKey(individualAcademicProgressId) ? ienListByIpr.get(individualAcademicProgressId) : new List<reduivy__Individual_Enrollment__c>();

            REDU_Logging_UTIL.debugJsonString('ienListByIpr', ienListByIpr);

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(ienList));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}