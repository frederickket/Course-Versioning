/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Trigger
 * @description Trigger for Agreement Unit Equivalent
 * @changehistory
 */
trigger Trigger_AgreementUnitEquivalent on reduivy__Agreement_Unit_Equivalent__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Agreement_Unit_Equivalent__c);
}