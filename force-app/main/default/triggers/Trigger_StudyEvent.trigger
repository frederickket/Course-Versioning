/**
 * @author      WDCi (Lean)
 * @date        Apr 2024
 * @group       Trigger
 * @description Trigger for reduivy__Study_Event__c
 * @changehistory
 * 
 */
trigger Trigger_StudyEvent on reduivy__Study_Event__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Study_Event__c);
}