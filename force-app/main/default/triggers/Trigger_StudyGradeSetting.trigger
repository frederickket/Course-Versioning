/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Trigger
 * @description Trigger for Study Grade Setting
 * @changehistory
 * 
 */
trigger Trigger_StudyGradeSetting on reduivy__Study_Grade_Setting__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Study_Grade_Setting__c);
}