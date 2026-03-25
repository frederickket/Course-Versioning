/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Trigger executable
 * @description Prevent the change of program status from any status to draft to avoid recreation of children records
 * @changehistory
 * ISS-001662 06-10-2023 dblack - new class
 * ISS-002148 24-10-2024 Lean - Prevent user from changing the IPE status from preview to other status or vice versa
 */
public inherited sharing class IPE_ProgramStatusChange_EXE extends REDU_TriggerExecutable {

    /**
     * @description BeforeUpdate: prevent the change of program status from any status to draft
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeUpdate(
        System.TriggerOperation operationType, 
        List<SObject> newList, Map<Id, SObject> newMap, 
        List<SObject> oldList, Map<Id, SObject> oldMap, 
        Schema.DescribeSObjectResult sobjResult) {

        if (operationType == TriggerOperation.BEFORE_UPDATE) {

            List<String> ipeDraftStatusList = IPE_Helper.getDraftStatuses();
            List<String> ipePreviewStatusList = IPE_Helper.getPreviewStatuses();

            Map<Id, reduivy__Individual_Program_Enrollment__c> ipeOldMap = 
                new Map<Id, reduivy__Individual_Program_Enrollment__c>((List<reduivy__Individual_Program_Enrollment__c>) oldList);

            for (reduivy__Individual_Program_Enrollment__c ipeNew : (List<reduivy__Individual_Program_Enrollment__c>) newList) {
                reduivy__Individual_Program_Enrollment__c ipeOld = ipeOldMap.get(ipeNew.Id);
                
                if ((ipeNew.reduivy__Enrollment_Status__c != ipeOld.reduivy__Enrollment_Status__c) && 
                    (
                        (ipeDraftStatusList.contains(ipeNew.reduivy__Enrollment_Status__c) && !ipeDraftStatusList.contains(ipeOld.reduivy__Enrollment_Status__c)) ||
                        (ipePreviewStatusList.contains(ipeNew.reduivy__Enrollment_Status__c) && !ipePreviewStatusList.contains(ipeOld.reduivy__Enrollment_Status__c)) ||
                        (!ipePreviewStatusList.contains(ipeNew.reduivy__Enrollment_Status__c) && ipePreviewStatusList.contains(ipeOld.reduivy__Enrollment_Status__c))
                    )
                ) {
                    ipeNew.reduivy__Enrollment_Status__c.addError(Label.IPE_ProgramStatusChange_EXE_StatusChangeDisallowed);
                }
            }
        }
    }	
}