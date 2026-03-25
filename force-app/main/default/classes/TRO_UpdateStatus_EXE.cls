/**
 * @author      WDCi (XW)
 * @date        Apr 2025
 * @group       Transaction Order
 * @description Update the Status to Confirmed when the TRO Payment Status is fully or partially paid.
 * @changehistory
 * ISS-002429 28-04-2025 XW - new class
 * ISS-002576 07-08-2025 XiRouh - Updated from based on the payment status changes to based on the total paid amount changes
 */

public inherited sharing class TRO_UpdateStatus_EXE extends REDU_TriggerExecutable {
    

    static final List<String> TRO_CONFIRMED_STATUSES = TRO_Helper.getConfirmedStatuses();

    /**
     * @description AfterUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            Map<Id, reduivy__Transaction_Order__c> workingMap = new Map<Id, reduivy__Transaction_Order__c>();
            
            for (reduivy__Transaction_Order__c objNew : (List<reduivy__Transaction_Order__c>) newList) {
                reduivy__Transaction_Order__c objOld = (reduivy__Transaction_Order__c) oldMap.get(objNew.Id);

                if(
                    hasPaymentMade(objOld, objNew) && !TRO_CONFIRMED_STATUSES.contains(objNew.reduivy__Status__c)
                ) {
                    workingMap.put(objNew.Id, objNew);
                }
            }

            if(!workingMap.isEmpty()){
                updateStatus(workingMap);
            }
        }
    }

    /**
     * @description update the tro status to "Confirmed"
     * @param transaction map
     * @return void
     */
    private void updateStatus(Map<Id, reduivy__Transaction_Order__c> troMap) {
        List<reduivy__Transaction_Order__c> troToUpdate = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c tro : troMap.values()) {
            tro.reduivy__Status__c = TRO_CONFIRMED_STATUSES[0];
        }
    }

    /**
     * @description return true if payment has made and was not made previously
     * @param  oldTro 
     * @param  newTro 
     * @return        Boolean
     */
    private static Boolean hasPaymentMade(reduivy__Transaction_Order__c oldTro, reduivy__Transaction_Order__c newTro) {
        Boolean paymentWasMade = oldTro != null && oldTro.reduivy__Total_Paid_Amount__c != null && (oldTro.reduivy__Total_Paid_Amount__c > 0);
        Boolean paymentIsMade = newTro != null && newTro.reduivy__Total_Paid_Amount__c != null && (newTro.reduivy__Total_Paid_Amount__c > 0);

        Boolean result = !paymentWasMade && paymentIsMade;
        return result;
    }
}