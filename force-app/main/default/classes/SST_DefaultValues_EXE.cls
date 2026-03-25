/**
 * @author      WDCi (Lean)
 * @date        Apr 2025
 * @group       Study Session Time
 * @description To set the default value for new study session time
 * @changehistory
 * ISS-002403 14-04-2025 Lean - new class
 */
public inherited sharing class SST_DefaultValues_EXE extends REDU_TriggerExecutable {
    
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
        
        Schema.DescribeFieldResult updateActionField = SObjectType.reduivy__Study_Session_Time__c.fields.reduivy__Update_Action__c;
        List<Schema.PicklistEntry> updateActionOptions = updateActionField.getPicklistValues();

        String updateActionDefault;
        for (Schema.PicklistEntry opt : updateActionOptions) {
            if (opt.isActive() && opt.isDefaultValue()) {
                updateActionDefault = opt.getValue();
            }
        }

        for (reduivy__Study_Session_Time__c objNew : (List<reduivy__Study_Session_Time__c>) newList) {
            objNew.reduivy__Update_Action__c = updateActionDefault;
            objNew.reduivy__Historical_Recurrence__c = null;
        }
    }
}