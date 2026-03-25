/**
 * @author      WDCi (dblack)
 * @date        Dec 2023
 * @group       Trigger executable
 * @description When the status of a study offering record is changed to cancelled, set the status of the related individual enrollment records to withdrawn
 * @changehistory
 * ISS-001825 07-12-2023 dblack - new class
 */
public without sharing class SOF_CancelOffering_EXE extends REDU_TriggerExecutable {

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

        if ((operationType == TriggerOperation.AFTER_UPDATE) && 
            (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN))) {

            // Get the study offering records that have had the status changed to cancelled
            Map<Id, reduivy__Study_Offering__c> sofCancelledMap = new Map<Id, reduivy__Study_Offering__c>();
            List<String> sofCancelledStatuses = SOF_Helper.getCancelledStatuses();

            for (reduivy__Study_Offering__c sofNew : (List<reduivy__Study_Offering__c>) newList) {
                reduivy__Study_Offering__c sofOld = (reduivy__Study_Offering__c) oldMap.get(sofNew.Id);

                if ((sofCancelledStatuses.contains(sofNew.reduivy__Status_Override__c)) && 
                    (!sofCancelledStatuses.contains(sofOld.reduivy__Status_Override__c))) {

                    sofCancelledMap.put(sofNew.Id, sofNew);
                }
            }

            if (!sofCancelledMap.isEmpty()) {

                // Individual enrollment statuses: enrolled, waitlisted, enrollment requested
                List<String> ienPositiveStatuses = new List<String>();
                ienPositiveStatuses.addAll(IEN_Helper.getInProgressStatuses());
                ienPositiveStatuses.addAll(IEN_Helper.getEnrollmentRequestedStatuses());
                ienPositiveStatuses.addAll(IEN_Helper.getWaitlistedStatuses());
                
                Set<String> ienFields = new Set<String>{
                    'Id',
                    'reduivy__Enrollment_Status__c'
                };

                Map<String, Object> ienBindParams = new Map<String, Object>();
                ienBindParams.put('sofIds', sofCancelledMap.keySet());
                ienBindParams.put('ienPositiveStatuses', ienPositiveStatuses);

                String ienSoql = 'SELECT ' + String.join(ienFields, ', ') +
                    ' FROM reduivy__Individual_Enrollment__c ' +
                    ' WHERE reduivy__Study_Offering__c IN: sofIds ' +
                    ' AND reduivy__Enrollment_Status__c IN: ienPositiveStatuses';

                Map<String, Set<String>> ienObjectFieldsFls = new Map<String, Set<String>>();
                ienObjectFieldsFls.put(IEN_Helper.getApiName(), ienFields);

                // Get the relevent individual enrollment records
                List<reduivy__Individual_Enrollment__c> ienList = REDU_SystemMode_UTIL.doQuery(ienSoql, ienBindParams, ienObjectFieldsFls);

                if (!ienList.isEmpty()) {

                    // Set the individual enrollment status to withdrawn                    
                    String ienStatusTypeWithdrawn = IEN_Helper.getWithdrawnStatuses().get(0);

                    for (reduivy__Individual_Enrollment__c ien : ienList) {

                        ien.reduivy__Enrollment_Status__c = ienStatusTypeWithdrawn;
                    }

                    //need to update all records regardless of visibility using system mode
                    REDU_SystemMode_UTIL.doUpdate(ienList, sofCancelledMap, 'reduivy__Study_Offering__c', false);
                }
            }
        }
    }	
}