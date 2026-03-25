/**
 * @author      WDCi (Lean)
 * @date        March 2023
 * @group       Trigger
 * @description Trigger for Account
 * @changehistory
 */
trigger Trigger_Account on Account (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.Account);
}