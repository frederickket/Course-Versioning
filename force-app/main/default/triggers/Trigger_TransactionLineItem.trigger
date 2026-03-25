/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Trigger
 * @description Trigger for Transaction Line Item
 * @changehistory
 * 
 */
trigger Trigger_TransactionLineItem on reduivy__Transaction_Line_Item__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Transaction_Line_Item__c);
}