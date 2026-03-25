/**
 * @author      WDCi (VTan)
 * @date        Mar 2024
 * @group       Finance
 * @description Calculate total amount (subtotal and total amount)
 * @changehistory
 * ISS-001866 04-03-2024 VTan - New class
 */
public inherited sharing class TRL_TotalAmountCalc_EXE extends REDU_TriggerExecutable {
    
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
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            for (reduivy__Transaction_Line_Item__c trnLineItem : (List<reduivy__Transaction_Line_Item__c>) newList) {

                if(trnLineItem.reduivy__Unit_Price__c != null && trnLineItem.reduivy__Quantity__c != null){

                    calculateTotalAmount(trnLineItem);
                }
            }
        }
    }

    /**
     * @description BeforeUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            for (reduivy__Transaction_Line_Item__c trnLineItemNew : (List<reduivy__Transaction_Line_Item__c>) newList) {
                reduivy__Transaction_Line_Item__c trnLineItemOld = (reduivy__Transaction_Line_Item__c) oldMap.get(trnLineItemNew.Id);

                if (trnLineItemNew.reduivy__Unit_Price__c != trnLineItemOld.reduivy__Unit_Price__c || trnLineItemNew.reduivy__Quantity__c != trnLineItemOld.reduivy__Quantity__c || trnLineItemNew.reduivy__Discount__c != trnLineItemOld.reduivy__Discount__c) {
                    calculateTotalAmount(trnLineItemNew);
                }
            }
        }
    }

    /**
     * @description
     * @param trnLineItem
     * @return void
     */
    private void calculateTotalAmount(reduivy__Transaction_Line_Item__c trnLineItem) {
        
        if(trnLineItem.reduivy__Unit_Price__c != null && trnLineItem.reduivy__Quantity__c != null){

            trnLineItem.reduivy__Subtotal__c = trnLineItem.reduivy__Unit_Price__c * trnLineItem.reduivy__Quantity__c;

            if(trnLineItem.reduivy__Discount__c != null){
                trnLineItem.reduivy__Total_Amount__c = trnLineItem.reduivy__Subtotal__c - trnLineItem.reduivy__Discount__c;
            }else{
                trnLineItem.reduivy__Total_Amount__c = trnLineItem.reduivy__Subtotal__c;
            }
            
        }else{

            trnLineItem.reduivy__Subtotal__c = 0;
            trnLineItem.reduivy__Total_Amount__c = 0;

        }
    }
}