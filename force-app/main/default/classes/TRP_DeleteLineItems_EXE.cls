/**
 * @author      WDCi (Sueanne)
 * @date        June 2024
 * @group       Finance
 * @description Delete all related Transaction Line Item if Transaction Payment is deleted
 * @changehistory
 * ISS-001988 27-06-2024 Sueanne - New class
 */
public without sharing class TRP_DeleteLineItems_EXE extends REDU_TriggerExecutable {
    
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

            if (!oldList.isEmpty()) {
                Map<Id, reduivy__Transaction_Payment__c> trpOldMap = new Map<Id, reduivy__Transaction_Payment__c>((List<reduivy__Transaction_Payment__c>) oldList);
                List<reduivy__Transaction_Line_Item__c> deleteList = new List<reduivy__Transaction_Line_Item__c>();
                
                //Get related transaction line item
                Map<String, Object> trlBindParams = new Map<String, Object>{
                    'trnPaymentIds' => trpOldMap.keySet(),
                    'monetaryEntryType' => TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY
                };

                String trlQuery = 'SELECT Id' +
                    ' FROM reduivy__Transaction_Line_Item__c' +
                    ' WHERE reduivy__Transaction_Payment__c IN: trnPaymentIds AND reduivy__Transaction_Type__c =: monetaryEntryType';

                Map<String, Set<String>> trlObjectFieldsFls = new Map<String, Set<String>>();
                trlObjectFieldsFls.put(TRL_Helper.getApiName(), new Set<String>{'Id'});
                
                for (reduivy__Transaction_Line_Item__c trnLineItem : (List<reduivy__Transaction_Line_Item__c>) REDU_SystemMode_UTIL.doQuery(trlQuery, trlBindParams, trlObjectFieldsFls)) {

                    deleteList.add(trnLineItem);
                }
                
                if (!deleteList.isEmpty()) {
                    //Delete records regardless of ownership using system mode
                    REDU_SystemMode_UTIL.doDelete(deleteList, trpOldMap, 'reduivy__Transaction_Payment__c', false);
                }
            }
        }
    }
}