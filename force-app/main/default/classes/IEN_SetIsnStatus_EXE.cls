/**
 * @author      WDCi (Sueanne)
 * @date        Aug 2024
 * @group       Trigger executable
 * @description When individual enrollment's enrollment status change to Completed/Dropped/Withdrawn/Withdrawn with Penalty, update the individual session enrollment's enrollment status
 * @changehistory
 * ISS-002051 19-08-2024 Sueanne - new class
 */

public inherited sharing class IEN_SetIsnStatus_EXE extends REDU_TriggerExecutable {

    /**
     * @description AfterUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            Map<Id, reduivy__Individual_Enrollment__c> qualifiedIen = new Map<Id, reduivy__Individual_Enrollment__c>();
            
            for(reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) newList){
                reduivy__Individual_Enrollment__c oldIen = (reduivy__Individual_Enrollment__c) oldMap.get(ien.Id);

                if(ien.reduivy__Enrollment_Status__c != oldIen.reduivy__Enrollment_Status__c 
                    && ISN_Helper.getIenToIsnStatusMap().containsKey(ien.reduivy__Enrollment_Status__c) 
                    && ien.RecordTypeId == IEN_Helper.getStudentRecordTypeId()
                ){
                    qualifiedIen.put(ien.Id, ien);
                }
            }

            if(!qualifiedIen.isEmpty()){
                toUpdateIsnEnrollmentStatus(qualifiedIen);
            }
        }
    }

    /**
     * @description To update the enrollment status of Individual Session Enrolment
     * @param qualifiedIen map of qualified individual enrollment
     */
    private void toUpdateIsnEnrollmentStatus(Map<Id, reduivy__Individual_Enrollment__c> qualifiedIen) {
        
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = new List<reduivy__Individual_Session_Enrollment__c>();

        //find individual session enrollments
        Map<String, Object> isnBindParams = new Map<String, Object>();
        isnBindParams.put('isnStudentRtId', ISN_Helper.getStudentRecordTypeId());
        isnBindParams.put('ienIds', qualifiedIen.keySet());
        isnBindParams.put('enrolledStatus', ISN_Helper.getInProgressStatuses());

        String isnQuery = 'SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c' +
            ' FROM reduivy__Individual_Session_Enrollment__c ' +
            ' WHERE RecordTypeId = :isnStudentRtId' +
            ' AND reduivy__Individual_Enrollment__c IN :ienIds' +
            ' AND reduivy__Enrollment_Status__c IN :enrolledStatus';

        for(reduivy__Individual_Session_Enrollment__c isn : (List<reduivy__Individual_Session_Enrollment__c>) Database.queryWithBinds(isnQuery, isnBindParams, AccessLevel.USER_MODE)){

            reduivy__Individual_Enrollment__c ien = qualifiedIen.get(isn.reduivy__Individual_Enrollment__c);
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getIenToIsnStatusMap().get(ien.reduivy__Enrollment_Status__c);
            isnToUpdate.add(isn);
        }

        if(!isnToUpdate.isEmpty()){
            REDU_Database_UTIL.doUpdate(isnToUpdate, qualifiedIen, 'reduivy__Individual_Enrollment__c', false);
        }

    }

}