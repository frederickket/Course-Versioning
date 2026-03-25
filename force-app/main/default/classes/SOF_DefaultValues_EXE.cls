/**
 * @author      WDCi (XiRouh)
 * @date        March 2025
 * @group       Study Offering
 * @description To set the default value for new study offering
 * @changehistory
 * ISS-002200 21-03-2025 XiRouh - new class
 */
public inherited sharing class SOF_DefaultValues_EXE extends REDU_TriggerExecutable {
    
	/**
     * @description BeforeInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        for (reduivy__Study_Offering__c objNew : (List<reduivy__Study_Offering__c>) newList) {
            objNew.reduivy__Booked_Places__c = 0;
            objNew.reduivy__Waitlist_Places__c = 0;
        }
    }
}