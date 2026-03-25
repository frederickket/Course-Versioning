/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Trigger
 * @description Trigger for Study Pathway Term
 * @changehistory
 * 
 */
trigger Trigger_StudyPathwayTerm on reduivy__Study_Pathway_Term__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Study_Pathway_Term__c);
}