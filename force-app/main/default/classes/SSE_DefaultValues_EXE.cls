/**
 * @author      WDCi (Lean)
 * @date        Apr 2025
 * @group       Study Session
 * @description To set the default value for new study session
 * @changehistory
 * ISS-002403 14-04-2025 Lean - new class
 */
public inherited sharing class SSE_DefaultValues_EXE extends REDU_TriggerExecutable {
    
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
        
        Schema.DescribeFieldResult genStatusField = SObjectType.reduivy__Study_Session__c.fields.reduivy__Study_Event_Generation_Status__c;
        List<Schema.PicklistEntry> genStatusOptions = genStatusField.getPicklistValues();

        String genStatusDefault;
        for (Schema.PicklistEntry opt : genStatusOptions) {
            if (opt.isActive() && opt.isDefaultValue()) {
                genStatusDefault = opt.getValue();
            }
        }

        for (reduivy__Study_Session__c objNew : (List<reduivy__Study_Session__c>) newList) {
            objNew.reduivy__Booked_Places__c = 0;
            objNew.reduivy__Waitlist_Places__c = 0;
            objNew.reduivy__Study_Event_Generation_Status__c = genStatusDefault;
        }
    }
}