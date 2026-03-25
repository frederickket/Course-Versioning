/**
 * @author      WDCi (Lean)
 * @date        Jan 2025
 * @group       Trigger
 * @description Trigger for reduivy__Job_Queue__c
 * @changehistory
 * ISS-002219 22-01-2025  Lean - new class
 */
trigger Trigger_JobQueue on reduivy__Job_Queue__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Job_Queue__c);
}