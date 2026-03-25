/**
 * @author      WDCi (Lean)
 * @date        Feb 2025
 * @group       Trigger
 * @description Trigger for Translation
 * @changehistory
 */
trigger Trigger_Translation on reduivy__Translation__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Translation__c);
}