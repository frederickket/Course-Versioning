/**
 * @author      WDCi (Lean)
 * @date        Jan 2025
 * @group       Trigger
 * @description Trigger for Individual Program Application
 * @changehistory
 * 
 */
trigger Trigger_IndividualProgramApplication on reduivy__Individual_Program_Application__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Individual_Program_Application__c);
}