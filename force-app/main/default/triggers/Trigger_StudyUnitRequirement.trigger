/**
 * @author      WDCi (Lean)
 * @date        Aug 2023
 * @group       Trigger
 * @description Trigger for Study Unit Requirement
 * @changehistory
 * 
 */
trigger Trigger_StudyUnitRequirement on reduivy__Study_Unit_Requirement__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Study_Unit_Requirement__c);
}