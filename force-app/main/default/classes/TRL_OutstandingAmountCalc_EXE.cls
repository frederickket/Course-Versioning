/**
 * @author      WDCi (VTan)
 * @date        Mar 2024
 * @group       Finance
 * @description Calculate outstanding amount based on (Offset Amount - Total Amount=)
 * @changehistory
 * ISS-001866 04-03-2024 VTan - New class
 */
public inherited sharing class TRL_OutstandingAmountCalc_EXE extends REDU_TriggerExecutable {
    
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

                if(trnLineItem.reduivy__Offset_Amount__c != null || trnLineItem.reduivy__Total_Amount__c != null){

                    calculateOutstandingAmount(trnLineItem);
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

                if (trnLineItemNew.reduivy__Total_Amount__c != trnLineItemOld.reduivy__Total_Amount__c || trnLineItemNew.reduivy__Offset_Amount__c != trnLineItemOld.reduivy__Offset_Amount__c) {
                    calculateOutstandingAmount(trnLineItemNew);
                }
            }
        }
    }

    /**
     * @description
     * @param trnLineItem
     * @return void
     */
    private void calculateOutstandingAmount(reduivy__Transaction_Line_Item__c trnLineItem) {

        Decimal outstandingAmt = 0;
        Decimal totalAmt = trnLineItem.reduivy__Total_Amount__c == null ? 0 : trnLineItem.reduivy__Total_Amount__c;
        Decimal offsetAmt = trnLineItem.reduivy__Offset_Amount__c == null ? 0 : trnLineItem.reduivy__Offset_Amount__c;

        outstandingAmt = totalAmt - offsetAmt;
        trnLineItem.reduivy__Outstanding_Amount__c = outstandingAmt;
    }
}