/**
 * @author      WDCi (Lean)
 * @date        Jul 2025
 * @group       Trigger
 * @description Trigger for Study Requirement
 * @changehistory
 * 
 */
trigger Trigger_StudyRequirement on reduivy__Study_Requirement__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Study_Requirement__c);
}