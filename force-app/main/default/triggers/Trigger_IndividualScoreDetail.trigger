/**
 * @author      WDCi (XW)
 * @date        July 2025
 * @group       Trigger
 * @description Trigger for reduivy__Individual_Score_Detail__c
 * @changehistory
 * 
 */
trigger Trigger_IndividualScoreDetail on reduivy__Individual_Score_Detail__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Individual_Score_Detail__c);
}