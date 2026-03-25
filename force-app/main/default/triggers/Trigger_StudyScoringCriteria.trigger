/**
 * @author      WDCi (XW)
 * @date        July 2025
 * @group       Trigger
 * @description Trigger for reduivy__Study_Scoring_Criteria__c
 * @changehistory
 * 
 */
trigger Trigger_StudyScoringCriteria on reduivy__Study_Scoring_Criteria__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Study_Scoring_Criteria__c);
}