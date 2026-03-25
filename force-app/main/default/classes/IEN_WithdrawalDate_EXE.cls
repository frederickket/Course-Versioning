/**
 * @author      WDCi (Jordan)
 * @date        Nov 2024
 * @group       Trigger executable
 * @description To populate the withdrawal date when individual enrollment is withdrawn
 * @changehistory
 * ISS-002140 29-11-2024 Jordan - new class
 */
public inherited sharing class IEN_WithdrawalDate_EXE extends REDU_TriggerExecutable {

    static final Set<String> IEN_WITHDRAWN_STATUSES = new Set<String>();

    static {
        IEN_WITHDRAWN_STATUSES.addAll(IEN_Helper.getWithdrawnStatuses());
        IEN_WITHDRAWN_STATUSES.addAll(IEN_Helper.getWithdrawnFailStatuses());
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            //Set the withdrawn date whenever an IEN is withdrawn
            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
                reduivy__Individual_Enrollment__c ienOld = (reduivy__Individual_Enrollment__c) oldMap.get(ienNew.Id);

                if (ienOld.reduivy__Enrollment_Status__c != ienNew.reduivy__Enrollment_Status__c && 
                    (IEN_WITHDRAWN_STATUSES.contains(ienNew.reduivy__Enrollment_Status__c) && !IEN_WITHDRAWN_STATUSES.contains(ienOld.reduivy__Enrollment_Status__c)) && 
                    ienNew.reduivy__Withdrawal_Date__c == null
                ) {
                    ienNew.reduivy__Withdrawal_Date__c = System.today();
                }
            }
        }
    }
}