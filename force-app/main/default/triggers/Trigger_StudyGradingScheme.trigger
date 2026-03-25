/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Trigger
 * @description Trigger for Study Grading Scheme
 * @changehistory
 * 
 */
trigger Trigger_StudyGradingScheme on reduivy__Study_Grading_Scheme__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Study_Grading_Scheme__c);
}