/**
 * @author      WDCi (VTan)
 * @date        Feb 2024
 * @group       Finance
 * @description Apply transaction payment once transaction payment is created or approved
 * @changehistory
 * ISS-001850 27-02-2024 VTan - New class
 */
public inherited sharing class TRP_ApplyPayment_EXE extends REDU_TriggerExecutable {
    
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

            Map<String, List<reduivy__Transaction_Payment__c>> conTrnPaymentMap = new Map<String, List<reduivy__Transaction_Payment__c>>();
            Map<Id, reduivy__Transaction_Payment__c> trnPaymentMap = new Map<Id, reduivy__Transaction_Payment__c>();
            String statusActive = TRP_Helper.STATUS_ACTIVE;
            for (reduivy__Transaction_Payment__c trnPayment : (List<reduivy__Transaction_Payment__c>) newList) {

                if(trnPayment.reduivy__Status__c == statusActive && trnPayment.reduivy__Remaining_Amount__c > 0){

                    //Different action if the transaction payment has a transaction order lookup.
                    String conTrnPaymentKey;
                    if(trnPayment.reduivy__Transaction_Order__c == null){
                        conTrnPaymentKey = trnPayment.reduivy__Contact__c + '|' + trnPayment.reduivy__Transaction_Type__c;
                    }else{
                        conTrnPaymentKey = trnPayment.reduivy__Transaction_Order__c + '|' + trnPayment.reduivy__Transaction_Type__c;
                    }

                    if(conTrnPaymentMap.containsKey(conTrnPaymentKey)){
                        conTrnPaymentMap.get(conTrnPaymentKey).add(trnPayment);
                    }else{
                        conTrnPaymentMap.put(conTrnPaymentKey, new List<reduivy__Transaction_Payment__c>{trnPayment});
                    }

                    trnPaymentMap.put(trnPayment.Id, trnPayment);
                }
            }

            if(!conTrnPaymentMap.isEmpty()){
                TRP_Helper.processPayment(null, conTrnPaymentMap, trnPaymentMap);
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

            Map<String, List<reduivy__Transaction_Payment__c>> conTrnPaymentMap = new Map<String, List<reduivy__Transaction_Payment__c>>();
            Map<Id, reduivy__Transaction_Payment__c> trnPaymentMap = new Map<Id, reduivy__Transaction_Payment__c>();
            String statusActive = TRP_Helper.STATUS_ACTIVE;
            for (reduivy__Transaction_Payment__c trnPaymentNew : (List<reduivy__Transaction_Payment__c>) newList) {
                reduivy__Transaction_Payment__c trnPaymentOld = (reduivy__Transaction_Payment__c) oldMap.get(trnPaymentNew.Id);

                if (trnPaymentNew.reduivy__Status__c == statusActive && trnPaymentNew.reduivy__Status__c != trnPaymentOld.reduivy__Status__c && trnPaymentNew.reduivy__Remaining_Amount__c > 0) {

                    //Different action if the transaction payment has a transaction order lookup.
                    String conTrnPaymentKey;
                    if(trnPaymentNew.reduivy__Transaction_Order__c == null){
                        conTrnPaymentKey = trnPaymentNew.reduivy__Contact__c + '|' + trnPaymentNew.reduivy__Transaction_Type__c;
                    }else{
                        conTrnPaymentKey = trnPaymentNew.reduivy__Transaction_Order__c + '|' + trnPaymentNew.reduivy__Transaction_Type__c;
                    }

                    if(conTrnPaymentMap.containsKey(conTrnPaymentKey)){
                        conTrnPaymentMap.get(conTrnPaymentKey).add(trnPaymentNew);
                    }else{
                        conTrnPaymentMap.put(conTrnPaymentKey, new List<reduivy__Transaction_Payment__c>{trnPaymentNew});
                    }
                    
                    trnPaymentMap.put(trnPaymentNew.Id, trnPaymentNew);
                }
            }

            if(!conTrnPaymentMap.isEmpty()){
                TRP_Helper.processPayment(null, conTrnPaymentMap, trnPaymentMap);
            }
        }
    }
}