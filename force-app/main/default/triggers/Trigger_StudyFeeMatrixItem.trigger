/**
 * @author      WDCi (Lean)
 * @date        July 2024
 * @group       Trigger
 * @description Trigger for reduivy__Study_Fee_Matrix_Item__c
 * @changehistory
 * 
 */
trigger Trigger_StudyFeeMatrixItem on reduivy__Study_Fee_Matrix_Item__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Study_Fee_Matrix_Item__c);
}