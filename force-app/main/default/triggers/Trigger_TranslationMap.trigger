/**
 * @author      WDCi (Lean)
 * @date        Feb 2025
 * @group       Trigger
 * @description Trigger for Translation Map
 * @changehistory
 */
trigger Trigger_TranslationMap on reduivy__Translation_Map__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Translation_Map__c);
}