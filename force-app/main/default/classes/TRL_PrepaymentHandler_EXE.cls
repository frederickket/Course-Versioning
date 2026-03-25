/**
 * @author      WDCi (VTan)
 * @date        Feb 2024
 * @group       Finance
 * @description Transaction line item (Deposit) needs to be converted as prepayment when the order line is fully paid.
 * @changehistory
 * ISS-001850 23-02-2024 VTan - New class
 * ISS-002536 18-07-2025 XiRouh - Updated the trigger condition to ignore TRL entries of type 'Non-Transactional Entry'
 */
public inherited sharing class TRL_PrepaymentHandler_EXE extends REDU_TriggerExecutable {

    private static final Map<String, reduivy__Transaction_Item_Type_Config__mdt> TRN_ITEM_TYPE_CONFIG = TRL_Helper.getPrepaymentItemTypeConfigs();

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
            Set<Id> trnOrderIds = new Set<Id>();
            
            for (reduivy__Transaction_Line_Item__c trnLineItem : (List<reduivy__Transaction_Line_Item__c>) newList) {

                //ISS-002536
                if (shouldCreatePrepayment(trnLineItem, null)) {
                    trnLineItemMap.put(trnLineItem.Id, trnLineItem);
                    trnOrderIds.add(trnLineItem.reduivy__Transaction_Order__c);
                }
            }

            if(!trnLineItemMap.isEmpty()){
                createPrepayment(trnLineItemMap, trnOrderIds);
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
            Set<Id> trnOrderIds = new Set<Id>();
            
            for (reduivy__Transaction_Line_Item__c trnLineItemNew : (List<reduivy__Transaction_Line_Item__c>) newList) {
                reduivy__Transaction_Line_Item__c trnLineItemOld = (reduivy__Transaction_Line_Item__c) oldMap.get(trnLineItemNew.Id);

                //ISS-002536
                if (shouldCreatePrepayment(trnLineItemNew, trnLineItemOld)) {
                    trnLineItemMap.put(trnLineItemNew.Id, trnLineItemNew);
                    trnOrderIds.add(trnLineItemNew.reduivy__Transaction_Order__c);
                }
            }

            if(!trnLineItemMap.isEmpty()){
                createPrepayment(trnLineItemMap, trnOrderIds);
            }
        }
    }

    /**
     * @description ISS-002536 Determine if the transaction line item is valid for prepayment creation
     * @param trnLineItemNew
     * @param trnLineItemOld
     * @return Boolean
     */
    private Boolean shouldCreatePrepayment(reduivy__Transaction_Line_Item__c trnLineItemNew, reduivy__Transaction_Line_Item__c trnLineItemOld) {
        Boolean baseCondition = (
            trnLineItemNew.reduivy__Transaction_Type__c != TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY &&
            trnLineItemNew.reduivy__Offset_Amount__c != null &&
            trnLineItemNew.reduivy__Offset_Amount__c > 0 &&
            TRN_ITEM_TYPE_CONFIG.containsKey(trnLineItemNew.reduivy__Item_Type__c) &&
            trnLineItemNew.reduivy__Offset_Amount__c == trnLineItemNew.reduivy__Total_Amount__c
        );
        
        if (trnLineItemOld == null) {
            return baseCondition;
        }
        
        Boolean offsetAmountChanged = (trnLineItemNew.reduivy__Offset_Amount__c != trnLineItemOld.reduivy__Offset_Amount__c);
        
        Boolean transactionTypeChanged = (
            trnLineItemOld.reduivy__Transaction_Type__c == TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY &&
            trnLineItemNew.reduivy__Transaction_Type__c != TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY
        );
        
        return baseCondition && (offsetAmountChanged || transactionTypeChanged);
    }

    /**
     * @description Create new payment for prepayment transaction and update transaction order to confirmed.
     * @param trnLineItemMap Map of qualified transaction line items to be created with new prepayment
     * @return void
     */
    private void createPrepayment(Map<Id, reduivy__Transaction_Line_Item__c> trnLineItemMap, Set<Id> trnOrderIds) {

        //Get transaction order status, need to be updated to confirmed if currently in draft
        Map<String, Object> troBindParams = new Map<String, Object>{
            'trnOrderIds' => trnOrderIds,
            'orderStatusDraft' => TRO_Helper.getDraftStatuses()

        };

        String troQuery = 'SELECT Id, reduivy__Status__c' +
        ' FROM reduivy__Transaction_Order__c' +
        ' WHERE Id IN: trnOrderIds AND reduivy__Status__c IN :orderStatusDraft';

        String troStatusConfirmed = TRO_Helper.getConfirmedStatuses().get(0);
        Map<String, reduivy__Transaction_Order__c> updateTrnOrderMap = new Map<String, reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : (List<reduivy__Transaction_Order__c>) Database.queryWithBinds(troQuery, troBindParams, AccessLevel.USER_MODE)){

            trnOrder.reduivy__Status__c = troStatusConfirmed;
            updateTrnOrderMap.put(trnOrder.Id, trnOrder);
        }
        
        Map<String, List<reduivy__Transaction_Line_Item__c>> trlListByIdMap = new Map<String, List<reduivy__Transaction_Line_Item__c>>();
        Map<String, reduivy__Transaction_Payment__c> paymentListbyTrlIdMap = new Map<String, reduivy__Transaction_Payment__c>();
        for(reduivy__Transaction_Line_Item__c trnLineItem : trnLineItemMap.values()){

            reduivy__Transaction_Payment__c trnPayment = new reduivy__Transaction_Payment__c();
            trnPayment.reduivy__Transaction_Type__c = TRN_ITEM_TYPE_CONFIG.get(trnLineItem.reduivy__Item_Type__c).reduivy__Payment_Transaction_Type__c;
            trnPayment.reduivy__Status__c = TRN_ITEM_TYPE_CONFIG.get(trnLineItem.reduivy__Item_Type__c).reduivy__Payment_Status__c;
            trnPayment.reduivy__Refundable__c = TRN_ITEM_TYPE_CONFIG.get(trnLineItem.reduivy__Item_Type__c).reduivy__Payment_Refundable__c;
            trnPayment.reduivy__Amount__c = trnLineItem.reduivy__Offset_Amount__c;
            trnPayment.reduivy__Contact__c = trnLineItem.reduivy__Contact_Id__c;

            String paymentApplicableType = TRN_ITEM_TYPE_CONFIG.get(trnLineItem.reduivy__Item_Type__c).reduivy__Payment_Applicable_Item_Type__c;
            if(String.isNotBlank(paymentApplicableType)){
                trnPayment.reduivy__Applicable_to_Specific_Types__c = TRP_Helper.APPLICABLE_TO_TYPES_YES;
                trnPayment.reduivy__Applicable_Item_Type__c = paymentApplicableType;
            }else{
                trnPayment.reduivy__Applicable_to_Specific_Types__c = TRP_Helper.APPLICABLE_TO_TYPES_NO;
            }

            paymentListbyTrlIdMap.put(String.valueOf(trnLineItem.Id), trnPayment);

            //For error handling
            trlListByIdMap.put(String.valueOf(trnLineItem.Id), new List<reduivy__Transaction_Line_Item__c>{trnLineItem});

            if(trlListByIdMap.containsKey(trnLineItem.reduivy__Transaction_Order__c)){
                trlListByIdMap.get(trnLineItem.reduivy__Transaction_Order__c).add(trnLineItem);
            }else{
                trlListByIdMap.put(trnLineItem.reduivy__Transaction_Order__c, new List<reduivy__Transaction_Line_Item__c>{trnLineItem});
            }
        }

        if(!paymentListbyTrlIdMap.isEmpty()){

            REDU_Database_UTIL.doInsert(paymentListbyTrlIdMap, trlListByIdMap, false);
        }

        if(!updateTrnOrderMap.isEmpty()){

            REDU_Database_UTIL.doUpdate(updateTrnOrderMap, trlListByIdMap, false);
        }
    }
}