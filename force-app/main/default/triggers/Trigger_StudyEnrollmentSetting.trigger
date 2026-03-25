/**
 * @author      WDCi (Lean)
 * @date        Mar 2025
 * @group       Trigger
 * @description Trigger for Study Enrollment Settings
 * @changehistory
 * 
 */
trigger Trigger_StudyEnrollmentSetting on reduivy__Study_Enrollment_Setting__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Study_Enrollment_Setting__c);
}