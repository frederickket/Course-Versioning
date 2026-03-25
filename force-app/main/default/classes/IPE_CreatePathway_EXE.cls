/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Trigger executable
 * @description Create the individual pathway records
 * @changehistory
 * ISS-001662 12-10-2023 dblack - new class
 * ISS-001928 24-05-2024 VTan - Allow creation of Individual Pathway when IPE is converted from preview.
 */
public inherited sharing class IPE_CreatePathway_EXE extends REDU_TriggerExecutable {

    /**
     * @description Individual program enrollment master enrollment record type id
     * @return Id
     */
    static final Id IPE_MASTER_ENROLLMENT_RECORD_TYPE_ID = IPE_Helper.getMasterEnrollmentRecordTypeId();

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
            Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
            for (reduivy__Individual_Program_Enrollment__c ipe : (List<reduivy__Individual_Program_Enrollment__c>) newList) {
                if ((ipeInProgressStatusList.contains(ipe.reduivy__Enrollment_Status__c)) && 
                    (String.isNotBlank(ipe.reduivy__Study_Pathway__c)) && 
                    (ipe.RecordTypeId == IPE_MASTER_ENROLLMENT_RECORD_TYPE_ID)
                ) {
                    ipeMap.put(ipe.Id, ipe);
                }
            }
            if (!ipeMap.isEmpty()) {
                IPW_Helper.createPathway(ipeMap);
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
                if ((ipeInProgressStatusList.contains(ipeNew.reduivy__Enrollment_Status__c)) && 
                    (String.isNotBlank(ipeNew.reduivy__Study_Pathway__c)) && 
                    (ipeNew.RecordTypeId == IPE_MASTER_ENROLLMENT_RECORD_TYPE_ID) && 
                    ((ipeDraftStatusList.contains(ipeOld.reduivy__Enrollment_Status__c) ||
                    ipePreviewStatusList.contains(ipeOld.reduivy__Enrollment_Status__c)) || 
                     (ipeNew.reduivy__Study_Pathway__c != ipeOld.reduivy__Study_Pathway__c))
                ) {
                    ipeMap.put(ipeNew.Id, ipeNew);
                }
            }
            if (!ipeMap.isEmpty()) {
                IPW_Helper.createPathway(ipeMap);
            }
        }
    }
}