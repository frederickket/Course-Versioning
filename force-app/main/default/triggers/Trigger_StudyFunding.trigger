/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Trigger
 * @description Trigger for Study Funding
 * @changehistory
 * 
 */
trigger Trigger_StudyFunding on reduivy__Study_Funding__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Study_Funding__c);
}