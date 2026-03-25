/**
 * @author      WDCi (XW)
 * @date        May 2025
 * @group       Term unenrollment
 * @description Invocable class for term unenrollment
 * @changehistory
 * ISS-002436 13-05-2025 XW - create new class
 */
global inherited sharing class IPR_TermUnenrollment_FLOW {

    /**
     * @description Invocable method to unenroll from a term via flow
     * @param requests
     * @return List<IPR_TermUnenrollment_FLOW.Response>
     */
    @InvocableMethod(label='Unenroll Individual Enrollments by Individual Academic Progress' description='Unenrolls all related Individual Enrollment records linked to the specified Individual Academic Progress record.' category='Term Unenrollment')
    global static List<IPR_TermUnenrollment_FLOW.Response> execute(List<IPR_TermUnenrollment_FLOW.Request> requests) {

        System.SavePoint sp = Database.setSavepoint();
        Boolean isSuccess = true;
        String message = '';

        List<IPR_TermUnenrollment_FLOW.Response> responses = new List<IPR_TermUnenrollment_FLOW.Response>();
        Map<String, String> enrollmentStatusMap = new Map<String, String>();
        Map<String, String> statusesForWithdrawalMap = new Map<String, String>();
        Map<String,List<String>> updatedIenIdMap = new Map<String,List<String>>();
        Map<String, List<String>> ienListByIprIdMap = new Map<String, List<String>>();
        try {

            //merge requests into 1
            for (IPR_TermUnenrollment_FLOW.Request request : requests) {
                String iprId = request.individualAcademicProgressId;
                if(String.isNotBlank(iprId)){
                    ienListByIprIdMap.put(iprId, request.ienIdList);
                    enrollmentStatusMap.put(iprId, request.enrollmentStatus);
                }
            }
            updatedIenIdMap = IPR_Helper.unenrollIpr(ienListByIprIdMap, enrollmentStatusMap);

        } catch (Exception exp) {
            Database.rollback(sp);

            isSuccess = false;
            message = REDU_Database_UTIL.cleanseErrorMessage(exp.getMessage());

        } finally {

            //return list of related ien id based on the request ipr id
            for (IPR_TermUnenrollment_FLOW.Request request : requests) {
                IPR_TermUnenrollment_FLOW.Response response = new IPR_TermUnenrollment_FLOW.Response();
                
                response.status = isSuccess ? REDU_LightningResponse.SUCCESS : REDU_LightningResponse.FAIL;
                
                List<Id> ienIdList = new List<Id>();

                if(updatedIenIdMap.containsKey(request.individualAcademicProgressId)) {
                    ienIdList = updatedIenIdMap.get(request.individualAcademicProgressId);
                }
                
                response.ienIdList = ienIdList;
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

        @InvocableVariable(label='Individual Academic Progress Id' description='The ID of the Individual Academic Progress record whose related Individual Enrollments should be unenrolled.' required=true)
        global Id individualAcademicProgressId;

        @InvocableVariable(label='Individual Enrollment Id List' description='List of Individual Enrollment Id to be withdrawn.' required=true)
        global List<Id> ienIdList;

        @InvocableVariable(label='Target Enrollment Status' description='The status to assign to each affected Individual Enrollment record during the unenrollment process.' required=true)
        global String enrollmentStatus;
    }

    /**
     * @description Response wrapper class
     */
    global class Response {
        @InvocableVariable(label='Response status' description='The response status e.g., success or fail')
        global String status;

        @InvocableVariable(label='Response Message' description='The response message.')
        global String message;
        
        @InvocableVariable(label='Unenrolled Individual Enrollment Ids' description='A list of Individual Enrollment record IDs that were successfully unenrolled.')
        global List<String> ienIdList;        

    }
}
