/**
 * @author      WDCi (XW)
 * @date        May 2025
 * @group       Term unenrollment
 * @description Invocable class for get individual enrollment
 * @changehistory
 * ISS-002436 13-05-2025 XW - create new class
 */
global inherited sharing class IPR_GetIndividualEnrollment_FLOW {

    /**
     * @description Invocable method to get the relatd ien based on the given ipr id
     * @param requests
     * @return List<IPR_GetIndividualEnrollment_FLOW.Response>
     */
    @InvocableMethod(label='Get Individual Enrollments by Academic Progress' description='Retrieves all related Individual Enrollment records with the specified enrollment statuses based on the given Individual Academic Progress Id.' category='Enrollment')
    global static List<IPR_GetIndividualEnrollment_FLOW.Response> execute(List<IPR_GetIndividualEnrollment_FLOW.Request> requests) {

        Boolean isSuccess = true;
        String message = '';

        List<IPR_GetIndividualEnrollment_FLOW.Response> responses = new List<IPR_GetIndividualEnrollment_FLOW.Response>();

        Map<Id, String> iprEnrollmentStatusesMap = new Map<Id, String>();
        Map<Id, List<reduivy__Individual_Enrollment__c>> ienListByIprIdMap = new Map<Id, List<reduivy__Individual_Enrollment__c>>();
        
        try {

            //merge requests into 1
            for (IPR_GetIndividualEnrollment_FLOW.Request request : requests) {
                Id iprId = request.individualAcademicProgressId;

                if(String.isNotBlank(iprId)){
                    iprEnrollmentStatusesMap.put(iprId, request.statusesForWithdrawal);
                }
            }

            ienListByIprIdMap = IPR_Helper.getIndividualEnrollments(iprEnrollmentStatusesMap);

        } catch(QueryException qex){
            isSuccess = false;
            message = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
        } catch (Exception exp) {
            isSuccess = false;
            message = REDU_Database_UTIL.cleanseErrorMessage(exp.getMessage());
        } finally {

            //return list of related ien id based on the request ipr id
            for (IPR_GetIndividualEnrollment_FLOW.Request request : requests) {
                IPR_GetIndividualEnrollment_FLOW.Response response = new IPR_GetIndividualEnrollment_FLOW.Response();
                
                if(ienListByIprIdMap.containsKey(request.individualAcademicProgressId)) {
                    List<reduivy__Individual_Enrollment__c> ienList = ienListByIprIdMap.get(request.individualAcademicProgressId);
                    response.ienList = ienList;
                } else {
                    response.ienList = new List<reduivy__Individual_Enrollment__c>();
                }
                
                response.status = isSuccess ? REDU_LightningResponse.SUCCESS : REDU_LightningResponse.FAIL;
                response.message = message;
                responses.add(response);
            }
        }
        
        return responses;
    }

    
    /**
     * @description Request wrapper class
     */
    global class Request {

        @InvocableVariable(label='Individual Academic Progress Id' description='The ID of the Individual Academic Progress record whose related Individual Enrollments should be retrieved.' required=true)
        global Id individualAcademicProgressId;

        @InvocableVariable(label='Eligible Enrollment Status for Withdrawal' description='A semicolon-separated list of Individual Enrollment statuses eligible for withdrawal (e.g., Enrolled;Enrollment Requested;Withdrawal Requested).' required=true)
        global String statusesForWithdrawal;

    }

    /**
     * @description Response wrapper class
     */
    global class Response {

        @InvocableVariable(label='Response status' description='The response status e.g., success or fail')
        global String status;

        @InvocableVariable(label='Response Message' description='The response message.')
        global String message;

        @InvocableVariable(label='Individual Enrollments' description='A list of related Individual Enrollment records with the specified enrollment statuses based on the provided Individual Academic Progress ID.')
        global List<reduivy__Individual_Enrollment__c> ienList;

    }
}
