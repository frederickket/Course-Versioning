/**
 * @author      WDCi (Sueanne)
 * @date        July 2024
 * @group       Finance
 * @description To delete "Discount Entry" Transaction Line Item when "Order Line" Transaction Line Item is deleted
 * @changehistory
 * ISS-002030 23-07-2024 Sueanne - New class
 */
public without sharing class TRL_DeleteDiscount_EXE extends REDU_TriggerExecutable {
    
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

            Map<Id, reduivy__Transaction_Line_Item__c> trlOldMap = new Map<Id, reduivy__Transaction_Line_Item__c>((List<reduivy__Transaction_Line_Item__c>) oldList);
            
            //get the "Order Line" and "Discount Entry" that is going to delete
            Map<Id, reduivy__Transaction_Line_Item__c> ordLineToDelete = new Map<Id, reduivy__Transaction_Line_Item__c>();

            for(reduivy__Transaction_Line_Item__c oldTrl : trlOldMap.values()){

                if(oldTrl.reduivy__Transaction_Type__c == TRL_Helper.TRANSACTION_TYPE_ORDERLINE){
                    ordLineToDelete.put(oldTrl.Id, oldTrl);
                }
            }


            if(!ordLineToDelete.isEmpty()){

                //Get related "Discount Entry" transaction line item 
                Map<String, Object> trlBindParams = new Map<String, Object>{
                    'trlIds' => ordLineToDelete.keySet(),
                    'discountEntry' => TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY
                };
                
                String trlQuery = 'SELECT Id' +
                    ' FROM reduivy__Transaction_Line_Item__c' +
                    ' WHERE reduivy__Offset_Line_Item__c IN :trlIds AND reduivy__Transaction_Type__c = :discountEntry';
                
                Map<String, Set<String>> trlObjectFieldsFls = new Map<String, Set<String>>();
                trlObjectFieldsFls.put(TRL_Helper.getApiName(), new Set<String>{'Id'});

                List<reduivy__Transaction_Line_Item__c> discountList = new List<reduivy__Transaction_Line_Item__c>();
                for(reduivy__Transaction_Line_Item__c trl : (List<reduivy__Transaction_Line_Item__c>) REDU_SystemMode_UTIL.doQuery(trlQuery, trlBindParams, trlObjectFieldsFls)){
                    discountList.add(trl);
                }
                
                //delete "Discount Entry" transaction line item
                if(!discountList.isEmpty()){
                    //Delete records regardless of ownership using system mode
                    REDU_SystemMode_UTIL.doDelete(discountList);
                }
            }
        }
    }

}