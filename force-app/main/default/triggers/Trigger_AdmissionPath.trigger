/**
 * @author      WDCi (Lean)
 * @date        Sept 2025
 * @group       Trigger
 * @description Trigger for Admission Path
 * @changehistory
 * ISS-002497 23-09-2025 Lean - New admission option data model
 */
trigger Trigger_AdmissionPath on reduivy__Admission_Path__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Admission_Path__c);
}