/**
 * @author      WDCi (VTan)
 * @date        Feb 2024
 * @group       Finance
 * @description Apply transaction payment once transaction order is confirmed
 * @changehistory
 * ISS-001866 23-02-2024 VTan - New class
 */
public inherited sharing class TRO_ApplyPayment_EXE extends REDU_TriggerExecutable {

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

            Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>();
            List<String> troStatusesConfirmed = TRO_Helper.getConfirmedStatuses();
            for (reduivy__Transaction_Order__c trnOrder : (List<reduivy__Transaction_Order__c>) newList) {

                if(troStatusesConfirmed.contains(trnOrder.reduivy__Status__c)){
                    trnOrderMap.put(trnOrder.Id, trnOrder);
                }
            }

            if(!trnOrderMap.isEmpty()){
                TRP_Helper.processPayment(null, null, trnOrderMap);
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

            Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>();
            List<String> troStatusesConfirmed = TRO_Helper.getConfirmedStatuses();
            for (reduivy__Transaction_Order__c trnOrderNew : (List<reduivy__Transaction_Order__c>) newList) {
                reduivy__Transaction_Order__c trnOrderOld = (reduivy__Transaction_Order__c) oldMap.get(trnOrderNew.Id);

                if ((troStatusesConfirmed.contains(trnOrderNew.reduivy__Status__c) && trnOrderNew.reduivy__Status__c != trnOrderOld.reduivy__Status__c) || 
                    (troStatusesConfirmed.contains(trnOrderNew.reduivy__Status__c) && 
                        ((trnOrderNew.reduivy__Apply_Non_Repayable_FA__c && !trnOrderOld.reduivy__Apply_Non_Repayable_FA__c) ||
                        (trnOrderNew.reduivy__Apply_Repayable_FA__c && !trnOrderOld.reduivy__Apply_Repayable_FA__c) ||
                        (trnOrderNew.reduivy__Apply_Payment__c && !trnOrderOld.reduivy__Apply_Payment__c)
                        ))) {
                    trnOrderMap.put(trnOrderNew.Id, trnOrderNew);
                }
            }

            if(!trnOrderMap.isEmpty()){
                TRP_Helper.processPayment(null, null, trnOrderMap);
            }
        }
    }
}