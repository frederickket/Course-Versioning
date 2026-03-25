/**
 * @author      WDCi (Sueanne)
 * @date        July 2024
 * @group       Finance
 * @description Ensure no associated "monetary entry" transaction line item before delete "order line" transaction line item
 * @changehistory
 * ISS-002017 22-07-2024 Sueanne - New class
 * ISS-002536 18-07-2025 XiRouh - Updated the trigger condition to run only when the transaction type is 'Order'.
 */
public inherited sharing class TRL_DeleteValidation_EXE extends REDU_TriggerExecutable {
    
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
                Map<Id, reduivy__Transaction_Line_Item__c> trlOldMap = new Map<Id, reduivy__Transaction_Line_Item__c>();

                for (reduivy__Transaction_Line_Item__c trl : (List<reduivy__Transaction_Line_Item__c>) oldList) {
                    if (trl.reduivy__Transaction_Type__c == TRL_Helper.TRANSACTION_TYPE_ORDERLINE) {
                        trlOldMap.put(trl.Id, trl);
                    }
                }
                //Get related transaction line item
                Map<String, Object> trlBindParams = new Map<String, Object>{
                    'trlIds' => trlOldMap.keySet(),
                    'monetaryLine' => TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY
                };
                
                String trlQuery = 'SELECT Id, Name, reduivy__Offset_Line_Item__c' +
                    ' FROM reduivy__Transaction_Line_Item__c' +
                    ' WHERE reduivy__Offset_Line_Item__c IN :trlIds AND reduivy__Transaction_Type__c = :monetaryLine';
                
                
                Map<Id, List<String>> relatedTrlName = new Map<Id, List<String>>();

                for (reduivy__Transaction_Line_Item__c trnLineItem : (List<reduivy__Transaction_Line_Item__c>) Database.queryWithBinds(trlQuery, trlBindParams, AccessLevel.USER_MODE)) {

                    //gather the trl name that is unable to delete (having associated Monetary Entry) 
                    if(trlOldMap.containsKey(trnLineItem.reduivy__Offset_Line_Item__c)){

                        if(!relatedTrlName.containsKey(trnLineItem.reduivy__Offset_Line_Item__c)){
                            relatedTrlName.put(trnLineItem.reduivy__Offset_Line_Item__c, new List<String>());
                        }
                        relatedTrlName.get(trnLineItem.reduivy__Offset_Line_Item__c).add(trnLineItem.Name);
                    }
                }

                //Show error for the line item that having related Monetary Entry
                for (Id trlId : trlOldMap.keySet()){
                    if(relatedTrlName.containsKey(trlId)){
                        trlOldMap.get(trlId).addError(String.format(Label.Cannot_Delete_Child_Error, new List<String>{ String.join(relatedTrlName.get(trlId), ', ') }));
                    }
                }
            }
        }
    }
}