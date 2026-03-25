/**
 * @author      WDCi (Xirouh)
 * @date        Jan 2024
 * @group       Trigger
 * @description Trigger for reduivy__Integration_Queue__c
 * @changehistory
 * ISS-001978 24-06-2024  Xirouh - new class
 */
trigger Trigger_IntegrationQueue on reduivy__Integration_Queue__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Integration_Queue__c);
}