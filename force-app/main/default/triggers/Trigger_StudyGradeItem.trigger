/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Trigger
 * @description Trigger for Individual Academic Profile
 * @changehistory
 * 
 */
trigger Trigger_StudyGradeItem on reduivy__Study_Grade_Item__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Study_Grade_Item__c);
}