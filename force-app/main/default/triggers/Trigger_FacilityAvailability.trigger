/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Trigger
 * @description Trigger for reduivy__Facility_Availability__c
 * @changehistory
 * 
 */
trigger Trigger_FacilityAvailability on reduivy__Facility_Availability__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Facility_Availability__c);
}