/**
 * @author      WDCi (Lean)
 * @date        Aug 2023
 * @group       Trigger
 * @description Trigger for Credit Transfer Application
 * @changehistory
 * 
 */
trigger Trigger_CreditTransferApplication on reduivy__Credit_Transfer_Application__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.reduivy__Credit_Transfer_Application__c);
}