/**
 * @author      WDCi (Lean)
 * @date        July 2024
 * @group       Trigger
 * @description Trigger for reduivy__Study_Fee_Matrix__c
 * @changehistory
 * 
 */
trigger Trigger_StudyFeeMatrix on reduivy__Study_Fee_Matrix__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Study_Fee_Matrix__c);
}