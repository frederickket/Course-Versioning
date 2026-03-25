/**
 * @author      WDCi (XW)
 * @date        Dec 2025
 * @group       Trigger
 * @description Trigger for reduivy__Agreement_Recognition_Unit__c
 * @changehistory
 * 
 */
trigger Trigger_AgreementRecognitionUnit on reduivy__Agreement_Recognition_Unit__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Agreement_Recognition_Unit__c);
}