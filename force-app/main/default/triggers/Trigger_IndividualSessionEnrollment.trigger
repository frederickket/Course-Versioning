/**
 * @author      WDCi (Lean)
 * @date        April 2024
 * @group       Trigger
 * @description Trigger for reduivy__Individual_Session_Enrollment__c
 * @changehistory
 * 
 */
trigger Trigger_IndividualSessionEnrollment on reduivy__Individual_Session_Enrollment__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Individual_Session_Enrollment__c);
}