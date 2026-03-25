/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Trigger executable
 * @description Create the group records (individual plan structure, record type: group)
 * @changehistory
 * ISS-001662 09-10-2023 dblack - new class
 * ISS-001928 25-05-2025 VTan - Allow creation of IPS group if IPE is set to preview
 */
public inherited sharing class IPE_CreateGroup_EXE extends REDU_TriggerExecutable {

    /**
     * @description AfterInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(
        System.TriggerOperation operationType, 
        List<SObject> newList, Map<Id, SObject> newMap, 
        List<SObject> oldList, Map<Id, SObject> oldMap, 
        Schema.DescribeSObjectResult sobjResult) {

        if ((operationType == TriggerOperation.AFTER_INSERT) && 
            (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))) {

            List<String> ipeInProgressStatusList = IPE_Helper.getInProgressStatuses();
            List<String> ipePreviewStatusList = IPE_Helper.getPreviewStatuses();
            Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
            for (reduivy__Individual_Program_Enrollment__c ipe : (List<reduivy__Individual_Program_Enrollment__c>) newList) {
                if ((ipeInProgressStatusList.contains(ipe.reduivy__Enrollment_Status__c) ||
                    ipePreviewStatusList.contains(ipe.reduivy__Enrollment_Status__c)) && 
                    (String.isNotBlank(ipe.reduivy__Study_Plan__c))) {
                    ipeMap.put(ipe.Id, ipe);
                }
            }
            if (!ipeMap.isEmpty()) {
                IPS_Helper.createGroup(ipeMap);
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
    public override void executeAfterUpdate(
        System.TriggerOperation operationType, 
        List<SObject> newList, Map<Id, SObject> newMap, 
        List<SObject> oldList, Map<Id, SObject> oldMap, 
        Schema.DescribeSObjectResult sobjResult) {

        if ((operationType == TriggerOperation.AFTER_UPDATE) && 
            (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))) {

            List<String> ipeDraftStatusList = IPE_Helper.getDraftStatuses();
            List<String> ipeInProgressStatusList = IPE_Helper.getInProgressStatuses();
            List<String> ipePreviewStatusList = IPE_Helper.getPreviewStatuses();

            Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
            for (reduivy__Individual_Program_Enrollment__c ipeNew : (List<reduivy__Individual_Program_Enrollment__c>) newList) {
                reduivy__Individual_Program_Enrollment__c ipeOld = (reduivy__Individual_Program_Enrollment__c) oldMap.get(ipeNew.Id);
                if ((ipeNew.reduivy__Enrollment_Status__c != ipeOld.reduivy__Enrollment_Status__c) && 
                    (ipeInProgressStatusList.contains(ipeNew.reduivy__Enrollment_Status__c) ||
                    ipePreviewStatusList.contains(ipeNew.reduivy__Enrollment_Status__c)) && 
                    (ipeDraftStatusList.contains(ipeOld.reduivy__Enrollment_Status__c)) && 
                    (String.isNotBlank(ipeNew.reduivy__Study_Plan__c))) {
                    ipeMap.put(ipeNew.Id, ipeNew);
                }
            }
            if (!ipeMap.isEmpty()) {
                IPS_Helper.createGroup(ipeMap);
            }
        }
    }
}