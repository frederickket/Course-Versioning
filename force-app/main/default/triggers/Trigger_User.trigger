/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Trigger
 * @description Trigger for User
 * @changehistory
 */
trigger Trigger_User on User (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete
) {    
    REDU_TriggerManager.execute(Trigger.operationType, Trigger.new, Trigger.old, Schema.SobjectType.User);
}