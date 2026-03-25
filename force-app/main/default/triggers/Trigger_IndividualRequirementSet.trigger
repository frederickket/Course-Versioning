/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Trigger
 * @description Trigger for Individual Requirement Set
 * @changehistory
 * 
 */
trigger Trigger_IndividualRequirementSet on reduivy__Individual_Requirement_Set__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Individual_Requirement_Set__c);
}

