/**
 * @author      WDCi (VTan)
 * @date        Mar 2024
 * @group       Finance
 * @description Calculate outstanding amount based on (Total Paid Amount - Total Amount)
 * @changehistory
 * ISS-001866 04-03-2024 VTan - New class
 * ISS-002576 07-08-2025 XiRouh - Removed Formula.recalculateFormulas()
 */
public inherited sharing class TRO_OutstandingAmountCalc_EXE extends REDU_TriggerExecutable {
    
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

            List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
            for (reduivy__Transaction_Order__c trnOrder : (List<reduivy__Transaction_Order__c>) newList) {

                if(trnOrder.reduivy__Total_Paid_Amount__c != null || trnOrder.reduivy__Total_Amount__c != null){
                    trnOrderList.add(trnOrder);
                }
            }
            calculateOutstandingAmount(trnOrderList);
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

            List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
            for (reduivy__Transaction_Order__c trnOrderNew : (List<reduivy__Transaction_Order__c>) newList) {
                reduivy__Transaction_Order__c trnOrderOld = (reduivy__Transaction_Order__c) oldMap.get(trnOrderNew.Id);

                if (trnOrderNew.reduivy__Total_Amount__c != trnOrderOld.reduivy__Total_Amount__c || trnOrderNew.reduivy__Total_Paid_Amount__c != trnOrderOld.reduivy__Total_Paid_Amount__c) {
                    trnOrderList.add(trnOrderNew);
                }
            }
            calculateOutstandingAmount(trnOrderList);
        }
    }

    /**
     * @description
     * @param trnOrder
     * @return void
     */
    private void calculateOutstandingAmount(List<reduivy__Transaction_Order__c> trnOrders) {
        for(reduivy__Transaction_Order__c trnOrder : trnOrders) {
            Decimal outstandingAmt = 0;
            Decimal totalAmt = trnOrder.reduivy__Total_Amount__c == null ? 0 : trnOrder.reduivy__Total_Amount__c;
            Decimal paidAmt = trnOrder.reduivy__Total_Paid_Amount__c == null ? 0 : trnOrder.reduivy__Total_Paid_Amount__c;
            
            outstandingAmt = totalAmt - paidAmt;
            trnOrder.reduivy__Total_Outstanding_Amount__c = outstandingAmt;
        }
    }
}