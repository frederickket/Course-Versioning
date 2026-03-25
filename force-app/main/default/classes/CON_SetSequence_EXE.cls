/**
 * @author      WDCi (XiRouh)
 * @date        Feb 2025
 * @group       Trigger Executable
 * @description This is to update the sequence field on the contact. 
 * @changehistory
 * ISS-002229 XiRouh 14-02-2025 - New class
 */
public inherited sharing class CON_SetSequence_EXE extends REDU_TriggerExecutable {
    
    /**
     * @description AfterInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (operationType == TriggerOperation.BEFORE_INSERT) {
            Decimal maxSeq = REDU_AppSetting_UTIL.getMaximumSequenceNumber();

            for (Contact conNew : (List<Contact>) newList) {
                if(conNew.reduivy__Sequence__c == null) {
                    conNew.reduivy__Sequence__c = Integer.valueOf(Math.Random() * maxSeq);
                }
            }
        }
    }

    /**
     * @description AfterUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if(operationType == TriggerOperation.BEFORE_UPDATE) {
            Decimal maxSeq = REDU_AppSetting_UTIL.getMaximumSequenceNumber();

            for (Contact conNew : (List<Contact>) newList) {
                if(conNew.reduivy__Sequence__c == null) {
                    conNew.reduivy__Sequence__c = Integer.valueOf(Math.Random() * maxSeq);
                }
            }
        }
    }
}