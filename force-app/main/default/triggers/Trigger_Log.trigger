/**
 * @author      WDCi (Log)
 * @date        Aug 2023
 * @group       Trigger
 * @description Trigger for LOg
 * @changehistory
 * 
 */
trigger Trigger_Log on reduivy__Log__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Log__c);
}