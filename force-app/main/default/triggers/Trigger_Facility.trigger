/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Trigger
 * @description Trigger for Facility
 * @changehistory
 */
trigger Trigger_Facility on reduivy__Facility__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Facility__c);
}