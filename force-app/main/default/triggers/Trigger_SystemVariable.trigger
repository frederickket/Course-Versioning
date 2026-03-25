/**
 * @author      WDCi (Lean)
 * @date        July 2024
 * @group       Trigger
 * @description Trigger for reduivy__System_Variable__c
 * @changehistory
 * 
 */
trigger Trigger_SystemVariable on reduivy__System_Variable__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__System_Variable__c);
}