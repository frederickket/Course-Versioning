/**
 * @author      WDCi (Lean)
 * @date        Aug 2023
 * @group       Trigger
 * @description Trigger for Individual Enrollment
 * @changehistory
 * 
 */
trigger Trigger_IndividualEnrollment on reduivy__Individual_Enrollment__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Individual_Enrollment__c);
}