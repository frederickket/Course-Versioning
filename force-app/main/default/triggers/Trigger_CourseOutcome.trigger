/**
 * @author      RIO Education
 * @date        2026
 * @group       Trigger
 * @description Trigger for Course_Outcome__c — assigns sequential CO codes on insert
 *              and renumbers remaining records after delete.
 */
trigger Trigger_CourseOutcome on Course_Outcome__c (before insert, after delete) {
    if (Trigger.isBefore && Trigger.isInsert) {
        CO_SetCode_EXE.onBeforeInsert(Trigger.new);
    } else if (Trigger.isAfter && Trigger.isDelete) {
        CO_SetCode_EXE.onAfterDelete(Trigger.old);
    }
}
