/**
 * @author      WDCi (Lean)
 * @date        July 2025
 * @group       Trigger
 * @description Trigger for reduivy__Individual_Success_Plan__c
 * @changehistory
 * 
 */
trigger Trigger_IndividualSuccessPlan on reduivy__Individual_Success_Plan__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Individual_Success_Plan__c);
}