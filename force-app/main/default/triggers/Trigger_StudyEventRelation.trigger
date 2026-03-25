/**
 * @author      WDCi (Lean)
 * @date        April 2024
 * @group       Trigger
 * @description Trigger for reduivy__Study_Event_Relation__c
 * @changehistory
 * 
 */
trigger Trigger_StudyEventRelation on reduivy__Study_Event_Relation__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Study_Event_Relation__c);
}