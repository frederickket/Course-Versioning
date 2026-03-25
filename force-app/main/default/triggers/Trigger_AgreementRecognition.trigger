/**
 * @author      WDCi (Lean)
 * @date        Sept 2025
 * @group       Trigger
 * @description Trigger for Agreement Recognition
 * @changehistory
 * ISS-002497 23-09-2025 Lean - New admission option data model
 */
trigger Trigger_AgreementRecognition on reduivy__Agreement_Recognition__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Agreement_Recognition__c);
}