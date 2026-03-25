/**
 * @author      WDCi (Lean)
 * @date        May 2024
 * @group       Trigger
 * @description Trigger for reduivy__Contact_Availability__c
 * @changehistory
 * 
 */
trigger Trigger_ContactAvailability on reduivy__Contact_Availability__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Contact_Availability__c);
}