/**
 * @author      WDCi (Jordan)
 * @date        Nov 2024
 * @group       Trigger executable
 * @description To populate the withdrawal date when individual session enrollment is withdrawn
 * @changehistory
 * ISS-002141 28-11-2024 Jordan - new class
 */
public inherited sharing class ISN_WithdrawalDate_EXE extends REDU_TriggerExecutable {
    
    private static final List<String> ISN_WITHDRAWN_STATUSES = ISN_Helper.getWithdrawnStatuses();

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

            //Set the withdrawn date whenever an ISN is withdrawn
            for (reduivy__Individual_Session_Enrollment__c isnNew : (List<reduivy__Individual_Session_Enrollment__c>) newList) {
                reduivy__Individual_Session_Enrollment__c isnOld = (reduivy__Individual_Session_Enrollment__c) oldMap.get(isnNew.Id);

                if (isnNew.reduivy__Enrollment_Status__c != isnOld.reduivy__Enrollment_Status__c && 
                    ISN_WITHDRAWN_STATUSES.contains(isnNew.reduivy__Enrollment_Status__c) &&
                    !ISN_WITHDRAWN_STATUSES.contains(isnOld.reduivy__Enrollment_Status__c) &&
                    isnNew.reduivy__Withdrawal_Date__c == null
                ) {
                    isnNew.reduivy__Withdrawal_Date__c = System.today();
                }
            }
        }
    }
}