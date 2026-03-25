/**
 * @author      WDCi (Lean)
 * @date        Sept 2025
 * @group       Trigger
 * @description Trigger for Study Program Admission Path
 * @changehistory
 * ISS-002497 23-09-2025 Lean - New admission option data model
 */
trigger Trigger_StudyProgramAdmissionPath on reduivy__Study_Program_Admission_Path__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Study_Program_Admission_Path__c);
}