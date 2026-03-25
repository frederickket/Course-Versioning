/**
 * @author      WDCi (VTan)
 * @date        Feb 2024
 * @group       Finance
 * @description Apply payment when a transaction line item is created or updated.
 * @changehistory
 * ISS-001866 27-02-2024 name - description
 */
public inherited sharing class TRL_ApplyPayment_EXE extends REDU_TriggerExecutable {

    private static final String TRN_TYPE_ORDERLINE = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;

    /**
     * @description AfterInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            Map<Id, reduivy__Transaction_Line_Item__c> trnLineItemMap = new Map<Id, reduivy__Transaction_Line_Item__c>();
            for (reduivy__Transaction_Line_Item__c trnLineItem : (List<reduivy__Transaction_Line_Item__c>) newList) {

                if(trnLineItem.reduivy__Transaction_Type__c == TRN_TYPE_ORDERLINE ){

                    trnLineItemMap.put(trnLineItem.Id, trnLineItem);
                }
            }

            if(!trnLineItemMap.isEmpty()){

                TRP_Helper.processPayment(trnLineItemMap, null, trnLineItemMap);
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
    public override void executeAfterUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            Map<Id, reduivy__Transaction_Line_Item__c> trnLineItemMap = new Map<Id, reduivy__Transaction_Line_Item__c>();
            for (reduivy__Transaction_Line_Item__c trnLineItemNew : (List<reduivy__Transaction_Line_Item__c>) newList) {
                reduivy__Transaction_Line_Item__c trnLineItemOld = (reduivy__Transaction_Line_Item__c) oldMap.get(trnLineItemNew.Id);

                if(trnLineItemNew.reduivy__Transaction_Type__c == TRN_TYPE_ORDERLINE && trnLineItemNew.reduivy__Total_Amount__c != trnLineItemOld.reduivy__Total_Amount__c){

                    trnLineItemMap.put(trnLineItemNew.Id, trnLineItemNew);
                }
            }

            if(!trnLineItemMap.isEmpty()){

                TRP_Helper.processPayment(trnLineItemMap, null, trnLineItemMap);
            }
        }
    }
}