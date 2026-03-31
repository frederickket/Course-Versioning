/**
 * @author      RIO Education
 * @date        2026
 * @group       Trigger
 * @description Trigger for Program_Outcome__c — assigns sequential PO codes on insert
 *              and renumbers remaining records after delete.
 */
trigger Trigger_ProgramOutcome on Program_Outcome__c (before insert, after delete) {
    if (Trigger.isBefore && Trigger.isInsert) {
        PO_SetCode_EXE.onBeforeInsert(Trigger.new);
    } else if (Trigger.isAfter && Trigger.isDelete) {
        PO_SetCode_EXE.onAfterDelete(Trigger.old);
    }
}
