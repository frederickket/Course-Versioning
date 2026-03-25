/**
 * @author      WDCi (Sueanne)
 * @date        Aug 2024
 * @group       Trigger executable
 * @description To populate individual session enrolment's enrollment date, start date and end date
 * @changehistory
 * ISS-002057 23-08-2024 Sueanne - new class
 */
public inherited sharing class ISN_PopulateDate_EXE extends REDU_TriggerExecutable {
    
    static final Id ISN_STUDENT_RTID =  ISN_Helper.getStudentRecordTypeId();

    /**
     * @description BeforeInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Session_Enrollment__c> isnList = new List<reduivy__Individual_Session_Enrollment__c>();
            for (reduivy__Individual_Session_Enrollment__c isnNew : (List<reduivy__Individual_Session_Enrollment__c>) newList) {
                if (isnNew.RecordTypeId == ISN_STUDENT_RTID) {
                    isnList.add(isnNew);
                }
            }

            if (!isnList.isEmpty()) {
                setDates(isnList);
            }
        }
    }

    /**
     * @description BeforeUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)){

            List<reduivy__Individual_Session_Enrollment__c> isnList = new List<reduivy__Individual_Session_Enrollment__c>();
            for (reduivy__Individual_Session_Enrollment__c isnNew : (List<reduivy__Individual_Session_Enrollment__c>) newList) {
                reduivy__Individual_Session_Enrollment__c isnOld = (reduivy__Individual_Session_Enrollment__c) oldMap.get(isnNew.Id);

                if (isnNew.RecordTypeId == ISN_STUDENT_RTID &&
                    ((isnNew.reduivy__Study_Session__c != isnOld.reduivy__Study_Session__c) || 
                    (isnNew.reduivy__Enrollment_Status__c != isnOld.reduivy__Enrollment_Status__c))
                ) {
                    isnList.add(isnNew);
                }

                if (!isnList.isEmpty()) {
                    setDates(isnList);
                }
            }
        }
    }

    /**
     * @description Sets the individual session enrollment dates: enrollment date, start date and end date
     * @param isnList List<reduivy__Individual_Session_Enrollment__c>
     */
    public void setDates(List<reduivy__Individual_Session_Enrollment__c> isnList) {

        List<reduivy__Individual_Session_Enrollment__c> qualifiedIsns = new List<reduivy__Individual_Session_Enrollment__c>();
        Set<Id> sseIds = new Set<Id>();

        for (reduivy__Individual_Session_Enrollment__c isn : isnList) {

            if (String.isNotBlank(isn.reduivy__Study_Session__c)) {
                if ((ISN_Helper.getInProgressStatuses().contains(isn.reduivy__Enrollment_Status__c) || ISN_Helper.getCompletedStatuses().contains(isn.reduivy__Enrollment_Status__c)) && 
                    ((isn.reduivy__Enrollment_Date__c == null) || (isn.reduivy__Start_Date__c == null) || (isn.reduivy__End_Date__c == null))
                ) {
                    qualifiedIsns.add(isn);
                    sseIds.add(isn.reduivy__Study_Session__c);
                }

            } else {
                isn.reduivy__Enrollment_Date__c = null;
                isn.reduivy__Start_Date__c = null;
                isn.reduivy__End_Date__c = null;
            }
        }

        if (!qualifiedIsns.isEmpty()) {

            Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
                SELECT Id, reduivy__Study_Offering__c, 
                    reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c, 
                    reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c
                FROM reduivy__Study_Session__c
                WHERE Id IN :sseIds
                WITH USER_MODE
            ]);

            
            for (reduivy__Individual_Session_Enrollment__c isn : qualifiedIsns) {

                if (sseMap.containsKey(isn.reduivy__Study_Session__c)) {
                    reduivy__Study_Session__c sse = sseMap.get(isn.reduivy__Study_Session__c);

                    if (isn.reduivy__Enrollment_Date__c == null) {
                        isn.reduivy__Enrollment_Date__c = System.today();
                    }
                    
                    isn.reduivy__Start_Date__c = sse.reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c;
                    isn.reduivy__End_Date__c = sse.reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c;
                }
            }
        }
    }

}