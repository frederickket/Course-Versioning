/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Trigger
 * @description Trigger for Transaction Order
 * @changehistory
 * 
 */
trigger Trigger_TransactionOrder on reduivy__Transaction_Order__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Transaction_Order__c);
}