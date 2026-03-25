/**
 * @author      WDCi (Lean)
 * @date        Jul 2025
 * @group       Trigger
 * @description Trigger for reduivy__Job_Queue_Group__c
 * @changehistory
 * ISS-002547 09-07-2025  Lean - new class
 */
trigger Trigger_JobQueueGroup on reduivy__Job_Queue_Group__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Job_Queue_Group__c);
}