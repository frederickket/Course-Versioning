/**
 * @author      WDCi (Lean)
 * @date        Oct 2023
 * @group       Enrollment wizard
 * @description Enrollment wizard
 * @changehistory
 * ISS-001752 06-10-2023 Lean - New class
 * ISS-002189 18-12-2024 XW - get study plan id of child ipe
 * ISS-002330 21-03-2025 XW - added getIndividualPathway
 */
public with sharing class REDU_IpePathwayTerm_LCTRL {
    
    /**
     * @description Return a list of individual program enrollments based on Master individual program enrollment id
     * @param masterIpeId
     * @return REDU_LightningResponse
     */
	@AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualProgramEnrollments(Id masterIpeId){
        
        try {
            List<String> positiveIpeEnrollmentStatuses = IPE_Helper.getPositiveStatuses();

            List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id,
                RecordTypeId,
                Name,
                reduivy__Enrollment_Status__c,
                reduivy__Study_Plan__c,
                (
                    SELECT Id,
                    RecordTypeId,
                    Name,
                    reduivy__Enrollment_Status__c,
                    reduivy__Study_Plan__c //ISS-002189
                    FROM reduivy__Child_Individual_Program_Enrollments__r
                    WHERE reduivy__Enrollment_Status__c IN: positiveIpeEnrollmentStatuses
                    ORDER BY CreatedDate
                )
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE Id =: masterIpeId
                WITH USER_MODE
            ];

            List<reduivy__Individual_Program_Enrollment__c> sortedIpeList = new List<reduivy__Individual_Program_Enrollment__c>();
            for (reduivy__Individual_Program_Enrollment__c masterIpe : ipeList) {
                sortedIpeList.add(masterIpe);

                for (reduivy__Individual_Program_Enrollment__c childIpe : masterIpe.reduivy__Child_Individual_Program_Enrollments__r) {
                    sortedIpeList.add(childIpe);
                }
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(sortedIpeList));
            
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}