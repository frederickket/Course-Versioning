/**
 * @author      WDCi (XW)
 * @date        Sep 2025
 * @group       Trigger Executable
 * @description Delete the children individual requirements when individual requirement sets are deleted.
 * @changehistory
 * ISS-002506 12-09-2025 XW - new class
 */

public without sharing class IRS_DeleteRequirement_EXE extends REDU_TriggerExecutable {

    /**
     * @description BeforeDelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            if(!oldList.isEmpty()) {
                deleteIndividualRequirements((List<reduivy__Individual_Requirement_Set__c>) oldList);
            }

        }
    }
	
    /**
     * @description Delete the children individual requirements when individual requirement sets are deleted.
     * @param deletedirslist
     * @return void
     */
    private void deleteIndividualRequirements(List<reduivy__Individual_Requirement_Set__c> irsList) {
        List<reduivy__Individual_Requirement__c> irqToBeDeleted = new List<reduivy__Individual_Requirement__c>();
        String irqQuery = 'SELECT Id FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__c IN :irsList';

        Map<String, Set<String>> flsFields = new Map<String, Set<String>> {
            IRQ_Helper.getApiName() => new Set<String>{'Id'}
        };
        Map<String, Object> irqBindMap = new Map<String, Object>{
            'irsList' => irsList
        };
        
        for(reduivy__Individual_Requirement__c irq : (List<reduivy__Individual_Requirement__c>) REDU_SystemMode_UTIL.doQuery(irqQuery, irqBindMap, flsFields)) {
            irqToBeDeleted.add(irq);
        }

        if(!irqToBeDeleted.isEmpty()) {
            REDU_SystemMode_Util.doDelete(irqToBeDeleted);
        }

        
    }
}