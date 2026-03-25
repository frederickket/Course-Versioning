/**
 * @author      WDCi (dblack)
 * @date        Dec 2023
 * @group       Trigger executable
 * @description Individual Enrollment - upon status change, update the individual plan structure (unit) status
 * @changehistory
 * ISS-001768 12-12-2023 dblack - new class
 * ISS-001910 25-03-2024 vtan - Enhancement to set the IPS Unit status and the update IPS Unit status logic to a sharable method
 * ISS-002033 24-07-2024 Sueanne - to update the IPS status when grade result is updated
 */
public inherited sharing class IEN_SetUnitIpsStatus_EXE extends REDU_TriggerExecutable {

    static final Id IEN_STUDENT_RTID =  IEN_Helper.getStudentRecordTypeId();

    /**
     * @description Individual enrollment type
     */
    private static final String IEN_ENROLLMENTTYPE_PROGRAM = IEN_Helper.ENROLLMENT_TYPE_PROGRAM;

    /**
     * @description AfterInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>();
            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
                if (ienNew.RecordTypeId == IEN_STUDENT_RTID &&
                    ienNew.reduivy__Enrollment_Type__c == IEN_ENROLLMENTTYPE_PROGRAM) {
                    ienMap.put(ienNew.Id, ienNew);
                }
            }

            if (!ienMap.isEmpty()) {
                setIpsuStatus(ienMap);
            }
        }
    }

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

            Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
                reduivy__Individual_Enrollment__c ienOld = (reduivy__Individual_Enrollment__c) oldMap.get(ienNew.Id);

                if (ienNew.RecordTypeId == IEN_STUDENT_RTID && 
                    ienNew.reduivy__Enrollment_Type__c == IEN_ENROLLMENTTYPE_PROGRAM &&
                    (ienNew.reduivy__Enrollment_Status__c != ienOld.reduivy__Enrollment_Status__c ||
                    ienNew.reduivy__Grade_Result__c != ienOld.reduivy__Grade_Result__c)
                ) {
                    ienMap.put(ienNew.Id, ienNew);
                }
            }

            if (!ienMap.isEmpty()) {
                setIpsuStatus(ienMap);
            }
        }
    }

    /**
     * @description Set the status of individual plan structure records
     * @param ienMap Map<Id, reduivy__Individual_Enrollment__c>
     */
    private static void setIpsuStatus(Map<Id, reduivy__Individual_Enrollment__c> ienMap) {

        List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>([
            SELECT  Id, reduivy__Status__c, reduivy__Individual_Enrollment__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Enrollment__c IN :ienMap.keySet()
            WITH USER_MODE
            ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST, Name ASC
        ]);

        // Map to be used to check if the status has changed, we only update records with status changed.
        Map<Id, String> ipsUnitStatusMap = new Map<Id, String>();
        for(reduivy__Individual_Plan_Structure__c ipsUnit : ipsuList){
            ipsUnitStatusMap.put(ipsUnit.Id, ipsUnit.reduivy__Status__c);
        }

        if (!ipsuList.isEmpty()) {

            List<reduivy__Individual_Plan_Structure__c> ipsuUpdateList = new List<reduivy__Individual_Plan_Structure__c>();
            //Only add the IPS withs status change ot the update list.
            for(reduivy__Individual_Plan_Structure__c ipsu : IPS_Helper.updateIpsUnitStatus(ipsuList, ienMap)){
                if(ipsu.reduivy__Status__c != ipsUnitStatusMap.get(ipsu.Id)){

                    ipsuUpdateList.add(ipsu);
                }
            }

            if (!ipsuUpdateList.isEmpty()) {
                
                REDU_Database_UTIL.doUpdate(ipsuUpdateList, ienMap, 'reduivy__Individual_Enrollment__c', false);
            }
        }
    }
}
