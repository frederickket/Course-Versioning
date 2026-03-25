/**
 * @author      WDCi (VTan)
 * @date        Feb 2024
 * @group       Finance
 * @description Trigger funding payment creation for related transaction order when Disburse Repayable/Non Repayable FA is checked (Academic Term).
 * @changehistory
 * ISS-001848 20-02-2024 VTan - New class
 */
public inherited sharing class STM_FundingDisbursement_EXE extends REDU_TriggerExecutable {
    
    @TestVisible private static boolean testQueueJob = false;

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

        if (operationType == TriggerOperation.AFTER_UPDATE && 
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            
        }
    }
}