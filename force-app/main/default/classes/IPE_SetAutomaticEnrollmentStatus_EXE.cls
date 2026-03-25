/**
 * @author      WDCi (XiRouh)
 * @date        Feb 2025
 * @group       Trigger Executable
 * @description This is to update the auto enrollment field on the individual program enrollment 
 * @changehistory
 * ISS-002229 XiRouh 14-02-2025 - New class
 */
public inherited sharing class IPE_SetAutomaticEnrollmentStatus_EXE extends REDU_TriggerExecutable {

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

        if (operationType == TriggerOperation.BEFORE_INSERT) {
            for (reduivy__Individual_Program_Enrollment__c ipeNew : (List<reduivy__Individual_Program_Enrollment__c>) newList) {

                if(ipeNew.reduivy__Eligible_To_Enroll__c) {
                    ipeNew.reduivy__Auto_Enrollment__c = IPE_Helper.AUTO_ENROLLMENT_AUTO;
                } else {
                    ipeNew.reduivy__Auto_Enrollment__c = IPE_Helper.AUTO_ENROLLMENT_SKIPPED;
                }
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
        if (operationType == TriggerOperation.BEFORE_UPDATE) {
            for (reduivy__Individual_Program_Enrollment__c ipeNew : (List<reduivy__Individual_Program_Enrollment__c>) newList) {

                reduivy__Individual_Program_Enrollment__c ipeOld = (reduivy__Individual_Program_Enrollment__c) oldMap.get(ipeNew.Id);

                if(ipeNew.reduivy__Eligible_To_Enroll__c != ipeOld.reduivy__Eligible_To_Enroll__c) {
                    if(ipeNew.reduivy__Eligible_To_Enroll__c) {
                        ipeNew.reduivy__Auto_Enrollment__c = IPE_Helper.AUTO_ENROLLMENT_AUTO;
                    } else {
                        ipeNew.reduivy__Auto_Enrollment__c = IPE_Helper.AUTO_ENROLLMENT_SKIPPED;
                    }
                }
            }
        }
    }
}