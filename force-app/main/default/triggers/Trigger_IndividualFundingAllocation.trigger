/**
 * @author      WDCi (Lean)
 * @date        Feb 2024
 * @group       Trigger
 * @description Trigger for Individual Funding ALlocation
 * @changehistory
 * 
 */
trigger Trigger_IndividualFundingAllocation on reduivy__Individual_Funding_Allocation__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Individual_Funding_Allocation__c);
}