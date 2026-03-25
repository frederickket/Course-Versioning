/**
 * @author      WDCi (Lean)
 * @date        Feb 2024
 * @group       Object Helper
 * @description Transaction Payment object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001986 24-06-2024 Sueanne - allow TRO without linked Individual Academic Progress to be able to create monetary entry
 * ISS-001990 01-07-2024 Sueanne - ensure checkboxes (Disburse Repayable/Non Repayable FA) apply correct Transaction Payment 
 * ISS-002288 10-02-2025 XW - Fixed bug where an empty amount of Monetary Entry TRL is created even if the offset TRL is fully paid by other payments with same type
 * ISS-002578 07-08-2025 XiRouh - Added check for the outstanding amount of the TRL to ensure that a monetary entry is only created when the outstanding amount is > 0, refer to the issue number in the code for details of the changes
 * ISS-002677 11-04-2025 XW - When a transaction payment with parent transaction order is applying payment to its parent tro, ensure that the parent transaction order has apply payment = true
 */
global inherited sharing class TRP_Helper implements SObject_Helper {

    /**
     * @description Transaction Line Item Status's Transaction Type picklist constants
     */
    private static final String TRNTYPE_MONETARYENTRY = TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY;
    private static final String ENTRYTYPE_CREDIT = TRL_Helper.ENTRY_TYPE_CREDIT;
    
    /**
     * @description Transaction Payment Status picklist constants
     */
    global static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Transaction Payment Status picklist constants
     */
    global static final String STATUS_DRAFT = 'Draft';

    /**
     * @description Transaction Payment Transaction Type picklist constants
     */
    global static final String TRN_TYPE_NONREPAYABLE = 'Non Repayable Financial Aid Disbursement';

    /**
     * @description Transaction Payment Transaction Type picklist constants
     */
    global static final String TRN_TYPE_REPAYABLE = 'Repayable Financial Aid Disbursement';

    /**
     * @description Transaction Payment Applicable to Specific Type picklist constants
     */
    global static final String APPLICABLE_TO_TYPES_YES = 'Yes';

    /**
     * @description Transaction Payment Applicable to Specific Type picklist constants
     */
    global static final String APPLICABLE_TO_TYPES_NO = 'No';

    /**
     * @description Transaction Payment Applicable Item Type picklist constants
     */
    global static final String APPLICABLE_ITEM_TYPE_TUITION = 'Tuition';

    /**
     * @description Transaction Payment Transaction Type Type picklist constants
     */
    global static final String TRANSACTION_TYPE_PAYMENT = 'Payment';

    /**
     * @description Transaction Payment Transaction Type Type picklist constants
     */
    global static final String TRANSACTION_TYPE_NON_REPAYABLE_FINANCIAL_AID_DISBURSEMENT = 'Non Repayable Financial Aid Disbursement';

    /**
     * @description Return object type
     * @return String
     */
    public static Schema.SObjectType getObjectType() {
        return SObjectType.reduivy__Transaction_Payment__c.getSObjectType();
    }

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Transaction_Payment__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Transaction_Payment__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Transaction_Payment__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Transaction_Payment__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
    
    /**
     * @description List of reduivy__Payment_Transaction_Type_Config__mdt
     */
    private static List<reduivy__Payment_Transaction_Type_Config__mdt> transactionTypeConfigs;

    /**
     * @description Transaction Type configs metadata sorted according to sequence
     * @return List<reduivy__Payment_Transaction_Type_Config__mdt>
     */
    public static List<reduivy__Payment_Transaction_Type_Config__mdt> getTransactionTypeConfigs(){

        if(transactionTypeConfigs == null) {

            List<reduivy__Payment_Transaction_Type_Config__mdt> pttConfigs = new List<reduivy__Payment_Transaction_Type_Config__mdt>();
            for(reduivy__Payment_Transaction_Type_Config__mdt ptt : reduivy__Payment_Transaction_Type_Config__mdt.getAll().values()) {
                if(ptt.reduivy__Active__c) {
                    pttConfigs.add(ptt);
                }
            }

            List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
                new REDU_SObjectComparator.SortCriterion(reduivy__Payment_Transaction_Type_Config__mdt.reduivy__Sequence__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
            };
            
            pttConfigs.sort(new REDU_SObjectComparator(criteria));

            transactionTypeConfigs = pttConfigs;
        }

        return transactionTypeConfigs;
    }

    /**
     * @description Apply the payment onto transaction order line
     * @param trnLineItemMap Map of the qualified transaction line items
     * @param conTrnPaymentMap Map of the available transaction payment to be applied
     * @param sourceObjMap Map of the triggering transction orders, to be used for error handling.
     * @return void
     */
    public static void processPayment(Map<Id, reduivy__Transaction_Line_Item__c> trnLineItemMap, Map<String, List<reduivy__Transaction_Payment__c>> conTrnPaymentMap, Map<Id, SObject> sourceObjMap) {
        
        /**
         * NOTE: Please bear in mind that when using transaction payment with Applicable Items, it could run into a racing condition where 
         * a transaction line item doesn't have sufficient amount applied when there are multiple transaction payment being processed in the same runtime.
         * For example:
         * A tuition transaction order has the following order line:
         *  - Residential = 1000
         *  - Tuition Fee = 2500
         *  - Application Fee = 300
         * The following transaction payments created/activated at the same time:
         *  - Non Repayable Financial Aid = 1000 (Applicable: Tuition)
         *  - Non Repayable Financial Aid = 500 (Applicable: Tuition)
         *  - Credit Note = 400 (Applicable: All)
         *  - Repayable Financial Aid = 800 (Applicable: Residential)
         *  - Payment = 1000 (Applicable: All)
         * This would end up with Application Fee not being applied with any payment as Tuition Fee and Residential have consumed the available payments. See TRP_ApplyPayment_TEST.testApplyPaymentInsertWithConsumptionIssueAsStudent().
         */

        Map<String, Object> trlBindParams = new Map<String, Object>();
        String trlQuery = 'SELECT Id, Name, reduivy__Item_Name__c, reduivy__Transaction_Order__c, reduivy__Outstanding_Amount__c, reduivy__Item_Type__c,'+
        ' reduivy__Transaction_Order__r.reduivy__Apply_Non_Repayable_FA__c, reduivy__Transaction_Order__r.reduivy__Apply_Repayable_FA__c, reduivy__Transaction_Order__r.reduivy__Apply_Payment__c,'+
        ' reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c, reduivy__Transaction_Order__r.reduivy__Contact__c' +
        ' FROM reduivy__Transaction_Line_Item__c';

        //Get all required information from Transaction Line Item
        if(trnLineItemMap == null && conTrnPaymentMap == null){

            //Get the related transaction line item based on transaction order
            trlBindParams = new Map<String, Object>{
                'trnOrderIds' => sourceObjMap.keySet(),
                'orderLineType' => TRL_Helper.TRANSACTION_TYPE_ORDERLINE,
                'orderStatusConfirmed' => TRO_Helper.getConfirmedStatuses()
            };

            trlQuery +=' WHERE reduivy__Transaction_Order__c IN: trnOrderIds AND reduivy__Transaction_Type__c =: orderLineType AND reduivy__Transaction_Order__r.reduivy__Status__c IN :orderStatusConfirmed';

        }else if(conTrnPaymentMap != null){

            Set<Id> contactIds = new Set<Id>();
            for(String conTrnPaymentKey : conTrnPaymentMap.keySet()){
                for(reduivy__Transaction_Payment__c trnPayment : conTrnPaymentMap.get(conTrnPaymentKey)){
                    contactIds.add(trnPayment.reduivy__Contact__c);
                }
            }

            //Get the related transaction line item based on contact
            trlBindParams = new Map<String, Object>{
                'contactIds' => contactIds,
                'orderLineType' => TRL_Helper.TRANSACTION_TYPE_ORDERLINE,
                'orderStatusConfirmed' => TRO_Helper.getConfirmedStatuses(),
                'orderStatusVoid' => TRO_Helper.getVoidStatuses()
            };

            trlQuery += ' WHERE reduivy__Transaction_Order__r.reduivy__Contact__c IN: contactIds AND reduivy__Transaction_Type__c =: orderLineType AND (reduivy__Transaction_Order__r.reduivy__Status__c =: orderStatusConfirmed OR (reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c = null AND reduivy__Transaction_Order__r.reduivy__Status__c !=: orderStatusVoid))';

        }else if(trnLineItemMap != null){

            //Get the related transaction line item based on transaction line item
            trlBindParams = new Map<String, Object>{
                'trnLineItemIds' => trnLineItemMap.keySet(),
                'orderLineType' => TRL_Helper.TRANSACTION_TYPE_ORDERLINE,
                'orderStatusConfirmed' => TRO_Helper.getConfirmedStatuses()
            };

            trlQuery += ' WHERE Id IN: trnLineItemIds AND reduivy__Transaction_Type__c =: orderLineType AND reduivy__Transaction_Order__r.reduivy__Status__c IN :orderStatusConfirmed';
        }

        trlQuery += ' ORDER BY reduivy__Transaction_Order__r.reduivy__Transaction_Date__c ASC NULLS LAST, CreatedDate ASC, Name ASC';

        REDU_Logging_UTIL.debug('TRP_Helper.processPayment.trlQuery', trlQuery);
        REDU_Logging_UTIL.debug('TRP_Helper.processPayment.trlBindParams', trlBindParams);

        Set<Id> contactIds = new Set<Id>();
        Map<Id, List<reduivy__Transaction_Line_Item__c>> orderTrnLineItemMap = new Map<Id, List<reduivy__Transaction_Line_Item__c>>();
        Map<Id, reduivy__Transaction_Order__c> troIdMap = new Map<Id, reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Line_Item__c trnLineItem : (List<reduivy__Transaction_Line_Item__c>) Database.queryWithBinds(trlQuery, trlBindParams, AccessLevel.USER_MODE)){

            //Get set of contact ids, to be used to query related payment
            contactIds.add(trnLineItem.reduivy__Transaction_Order__r.reduivy__Contact__c);
            
            if(orderTrnLineItemMap.containsKey(trnLineItem.reduivy__Transaction_Order__c)){
                orderTrnLineItemMap.get(trnLineItem.reduivy__Transaction_Order__c).add(trnLineItem);
            }else{
                orderTrnLineItemMap.put(trnLineItem.reduivy__Transaction_Order__c, new List<reduivy__Transaction_Line_Item__c>{trnLineItem});
            }

            if(!troIdMap.containsKey(trnLineItem.reduivy__Transaction_Order__c)) {
                troIdMap.put(trnLineItem.reduivy__Transaction_Order__c, trnLineItem.reduivy__Transaction_Order__r);
            }
        }

        //Get related transaction payment, skip query if conTrnPaymentMap is not empty as it is coming from TRP_ApplyPayment_EXE
        Map<Id, Decimal> trnPaymentRemainingAmount = new Map<Id, Decimal>();
        if(conTrnPaymentMap == null || conTrnPaymentMap.isEmpty()){

            conTrnPaymentMap = new Map<String, List<reduivy__Transaction_Payment__c>>();
            Map<String, Object> trpBindParams = new Map<String, Object>{
                'contactIds' => contactIds,
                'activeStatus' => STATUS_ACTIVE,
                'remainingAmountCheck' => 0
            };
    
            String trpQuery = 'SELECT Id, reduivy__Contact__c, reduivy__Transaction_Order__c, reduivy__Applicable_to_Specific_Types__c, reduivy__Applicable_Item_Type__c, reduivy__Transaction_Type__c, reduivy__Remaining_Amount__c, reduivy__Status__c, reduivy__Transaction_Date__c, reduivy__Individual_Funding_Allocation__r.reduivy__Study_Funding__r.reduivy__Sequence__c' +
                ' FROM reduivy__Transaction_Payment__c' +
                ' WHERE reduivy__Contact__c IN: contactIds AND reduivy__Remaining_Amount__c >: remainingAmountCheck AND reduivy__Status__c =: activeStatus' +
                ' ORDER BY reduivy__Contact__c ASC, reduivy__Transaction_Type__c ASC, reduivy__Individual_Funding_Allocation__r.reduivy__Study_Funding__r.reduivy__Sequence__c ASC NULLS LAST, reduivy__Transaction_Date__c ASC NULLS LAST';
            
            for(reduivy__Transaction_Payment__c trnPayment : (List<reduivy__Transaction_Payment__c>) Database.queryWithBinds(trpQuery, trpBindParams, AccessLevel.USER_MODE)){

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
    
                trnPaymentRemainingAmount.put(trnPayment.Id, trnPayment.reduivy__Remaining_Amount__c);
            }

        }else{

            for(String conTrnPaymentKey : conTrnPaymentMap.keySet()){

                for(reduivy__Transaction_Payment__c trnPayment : conTrnPaymentMap.get(conTrnPaymentKey)){
                    trnPaymentRemainingAmount.put(trnPayment.Id, trnPayment.reduivy__Remaining_Amount__c);
                }
            }
        }

        //Apply payment according to transaction type sequence
        List<reduivy__Transaction_Line_Item__c> monetaryEntryList = new List<reduivy__Transaction_Line_Item__c>();
        for(reduivy__Payment_Transaction_Type_Config__mdt transactionTypeConfig : getTransactionTypeConfigs()){

            for(Id trnOrderId : orderTrnLineItemMap.keySet()){
                monetaryEntryList.addAll(applyPayment(troIdMap.get(trnOrderId), orderTrnLineItemMap.get(trnOrderId), conTrnPaymentMap, transactionTypeConfig.reduivy__Transaction_Type__c, trnPaymentRemainingAmount));
            }
        }

        if(!monetaryEntryList.isEmpty()){
            
            if(sourceObjMap.values()[0].getSObjectType() == TRL_Helper.getObjectType()){
                REDU_Database_UTIL.doInsert(monetaryEntryList, sourceObjMap, 'Id', false);

            }else if(sourceObjMap.values()[0].getSObjectType() == TRO_Helper.getObjectType()){
                REDU_Database_UTIL.doInsert(monetaryEntryList, sourceObjMap, 'reduivy__Transaction_Order__c', false);

            }else if(sourceObjMap.values()[0].getSObjectType() == getObjectType()){
                REDU_Database_UTIL.doInsert(monetaryEntryList, sourceObjMap, 'reduivy__Transaction_Payment__c', false);

            }
        }
    }
    
    /**
     * @description
     * @param trnLineItemList List of the qualified transaction line items
     * @param conTrnPaymentMap Map of transaction payments
     * @param transactionType Transaction type
     * @param trnPaymentRemainingAmount Map of the calculated remaining amount for the transaction payment
     * @return List<reduivy__Transaction_Line_Item__c>
     */
    public static List<reduivy__Transaction_Line_Item__c> applyPayment(reduivy__Transaction_Order__c trnOrder, List<reduivy__Transaction_Line_Item__c> trnLineItemList, Map<String, List<reduivy__Transaction_Payment__c>> conTrnPaymentMap, String transactionType, Map<Id, Decimal> trnPaymentRemainingAmount) {
        List<reduivy__Transaction_Line_Item__c> monetaryEntryList = new List<reduivy__Transaction_Line_Item__c>();

        REDU_Logging_UTIL.debugJsonString('TRP_Helper.applyPayment.trnOrder', trnOrder);
        REDU_Logging_UTIL.debugJsonString('TRP_Helper.applyPayment.trnLineItemList', trnLineItemList);
        REDU_Logging_UTIL.debugJsonString('TRP_Helper.applyPayment.conTrnPaymentMap', conTrnPaymentMap);
        REDU_Logging_UTIL.debug('TRP_Helper.applyPayment.transactionType', transactionType);
        REDU_Logging_UTIL.debugJsonString('TRP_Helper.applyPayment.trnPaymentRemainingAmount', trnPaymentRemainingAmount);

        //we should not proceed to apply the payment if there is no line item
        if(trnLineItemList.isEmpty()){
            return monetaryEntryList;
        }

        for(reduivy__Transaction_Line_Item__c trnLineItem : trnLineItemList){
            //Skip if Disburse Non Repayable FA/Disburse Repayable FA is unchecked for scholarship/grant payments, or skip if apply payment is unchecked for other payments.
            // if((transactionType == TRN_TYPE_NONREPAYABLE && trnLineItem.reduivy__Transaction_Order__r.reduivy__Apply_Non_Repayable_FA__c && trnLineItem.reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c != null) || 
            //     (transactionType == TRN_TYPE_REPAYABLE && trnLineItem.reduivy__Transaction_Order__r.reduivy__Apply_Repayable_FA__c && trnLineItem.reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c != null) ||

            if((transactionType == TRN_TYPE_NONREPAYABLE && trnLineItem.reduivy__Transaction_Order__r.reduivy__Apply_Non_Repayable_FA__c) || 
            (transactionType == TRN_TYPE_REPAYABLE && trnLineItem.reduivy__Transaction_Order__r.reduivy__Apply_Repayable_FA__c) ||
            (transactionType != TRN_TYPE_NONREPAYABLE && transactionType != TRN_TYPE_REPAYABLE && trnLineItem.reduivy__Transaction_Order__r.reduivy__Apply_Payment__c)){

                //Need to apply payment specified with a transaction order
                String trnOrderIdTypeKey = trnOrder.Id + '|' + transactionType;
                if(trnLineItem.reduivy__Outstanding_Amount__c > 0 && conTrnPaymentMap.containsKey(trnOrderIdTypeKey)){

                    for(reduivy__Transaction_Payment__c trnPayment : conTrnPaymentMap.get(trnOrderIdTypeKey)){

                        //ISS-002578 - Added reduivy__Outstanding_Amount__c > 0 check here because after the previous transaction payment is processed, the transaction line item might no longer have an outstanding amount
                        if(trnLineItem.reduivy__Outstanding_Amount__c > 0 && trnPaymentRemainingAmount.get(trnPayment.Id) > 0 &&
                            (trnPayment.reduivy__Applicable_to_Specific_Types__c == APPLICABLE_TO_TYPES_NO ||
                            (trnPayment.reduivy__Applicable_to_Specific_Types__c == APPLICABLE_TO_TYPES_YES && !String.isEmpty(trnPayment.reduivy__Applicable_Item_Type__c) && trnPayment.reduivy__Applicable_Item_Type__c.split(';').contains(trnLineItem.reduivy__Item_Type__c)))){

                            monetaryEntryList.add(createMonetaryEntry(trnLineItem, trnPayment, trnPaymentRemainingAmount));
                        }
                    }
                }

                //Following by transaction payment without transction order linkage
                String trnContactIdTypeKey = trnLineItem.reduivy__Transaction_Order__r.reduivy__Contact__c + '|' + transactionType;
                if(trnLineItem.reduivy__Outstanding_Amount__c > 0 && conTrnPaymentMap.containsKey(trnContactIdTypeKey)){

                    for(reduivy__Transaction_Payment__c trnPayment : conTrnPaymentMap.get(trnContactIdTypeKey)){
                        //ISS-002578 - Added reduivy__Outstanding_Amount__c > 0 check here because after the previous transaction payment is processed, the transaction line item might no longer have an outstanding amount
                        if(trnLineItem.reduivy__Outstanding_Amount__c > 0 && trnPaymentRemainingAmount.get(trnPayment.Id) > 0 &&
                            (trnPayment.reduivy__Applicable_to_Specific_Types__c == APPLICABLE_TO_TYPES_NO ||
                            (trnPayment.reduivy__Applicable_to_Specific_Types__c == APPLICABLE_TO_TYPES_YES && !String.isEmpty(trnPayment.reduivy__Applicable_Item_Type__c) && trnPayment.reduivy__Applicable_Item_Type__c.split(';').contains(trnLineItem.reduivy__Item_Type__c)))){

                            monetaryEntryList.add(createMonetaryEntry(trnLineItem, trnPayment, trnPaymentRemainingAmount));
                            
                            //ISS-002288 we dont need to create empty amount of TRL if the offset TRL is fully paid by the previous payment
                            if(trnLineItem.reduivy__Outstanding_Amount__c <= 0) {
                                break; 
                            }
                        }
                    }
                }
            }
        }

        String conTrnTypeKey = trnOrder.Id + '|' + transactionType;
        // Create Monetary entry if payment specified with a transaction order has remaining balance
        // ISS-002577 consider if the tro has apply payment = true
        if(conTrnPaymentMap.containsKey(conTrnTypeKey) && trnOrder.reduivy__Apply_Payment__c){
            for(reduivy__Transaction_Payment__c trnPayment : conTrnPaymentMap.get(conTrnTypeKey)){

                if(trnPaymentRemainingAmount.get(trnPayment.Id) > 0){

                    monetaryEntryList.add(createMonetaryEntry(null, trnPayment, trnPaymentRemainingAmount));
                }
            }
        }

        return monetaryEntryList;
    }

    /**
     * @description
     * @param trnLineItem Qualified transaction line item
     * @param trnPayment Transction payment to be applied
     * @param trnPaymentRemainingAmount Map of the calculated remaining amount for the transaction payment
     * @return reduivy__Transaction_Line_Item__c
     */
    public static reduivy__Transaction_Line_Item__c createMonetaryEntry(reduivy__Transaction_Line_Item__c trnLineItem, reduivy__Transaction_Payment__c trnPayment, Map<Id, Decimal> trnPaymentRemainingAmount) {

        REDU_Logging_UTIL.debug('tli before', trnLineItem?.Id + ' ' + trnLineItem?.reduivy__Item_Type__c + ' ' + trnLineItem?.reduivy__Outstanding_Amount__c);
        REDU_Logging_UTIL.debug('trp before', trnPayment?.Id + ' ' + trnPayment?.reduivy__Transaction_Type__c + ' ' + trnPaymentRemainingAmount.get(trnPayment?.Id));

        reduivy__Transaction_Line_Item__c newMonetaryEntry = new reduivy__Transaction_Line_Item__c();
        newMonetaryEntry.reduivy__Transaction_Type__c = TRNTYPE_MONETARYENTRY;
        newMonetaryEntry.reduivy__Entry_Type__c = ENTRYTYPE_CREDIT;
        newMonetaryEntry.reduivy__Transaction_Payment__c = trnPayment.Id;
        

        if(trnLineItem != null){

            newMonetaryEntry.reduivy__Item_Type__c  = trnLineItem.reduivy__Item_Type__c ;
            newMonetaryEntry.reduivy__Offset_Line_Item__c = trnLineItem.Id;
            newMonetaryEntry.reduivy__Transaction_Order__c = trnLineItem.reduivy__Transaction_Order__c;
            newMonetaryEntry.reduivy__Item_Name__c = String.format(Label.Monetary_Entry_Name_Prefix, new List<String>{trnLineItem.Name});

            if(trnLineItem.reduivy__Outstanding_Amount__c > trnPaymentRemainingAmount.get(trnPayment.Id)){

                newMonetaryEntry.reduivy__Quantity__c = 1;
                newMonetaryEntry.reduivy__Unit_Price__c = trnPaymentRemainingAmount.get(trnPayment.Id);
                trnLineItem.reduivy__Outstanding_Amount__c -= trnPaymentRemainingAmount.get(trnPayment.Id);
    
                trnPaymentRemainingAmount.put(trnPayment.Id, 0);
    
            }else if(trnLineItem.reduivy__Outstanding_Amount__c <= trnPaymentRemainingAmount.get(trnPayment.Id)){
    
                newMonetaryEntry.reduivy__Quantity__c = 1;
                newMonetaryEntry.reduivy__Unit_Price__c = trnLineItem.reduivy__Outstanding_Amount__c;
                trnPaymentRemainingAmount.put(trnPayment.Id, trnPaymentRemainingAmount.get(trnPayment.Id) - trnLineItem.reduivy__Outstanding_Amount__c);
    
                trnLineItem.reduivy__Outstanding_Amount__c -= trnLineItem.reduivy__Outstanding_Amount__c;
            }
        }else{

            newMonetaryEntry.reduivy__Transaction_Order__c = trnPayment.reduivy__Transaction_Order__c;
            newMonetaryEntry.reduivy__Item_Name__c = Label.Monetary_Entry_Name_Placeholder;
            newMonetaryEntry.reduivy__Quantity__c = 1;
            newMonetaryEntry.reduivy__Unit_Price__c = trnPaymentRemainingAmount.get(trnPayment.Id);
            trnPaymentRemainingAmount.put(trnPayment.Id, 0);
        }

        REDU_Logging_UTIL.debug('tli after', trnLineItem?.Id + ' ' + trnLineItem?.reduivy__Item_Type__c + ' ' + trnLineItem?.reduivy__Outstanding_Amount__c);
        REDU_Logging_UTIL.debug('trpli after', newMonetaryEntry.reduivy__Unit_Price__c);
        REDU_Logging_UTIL.debug('trp after', trnPayment?.Id + ' ' + trnPaymentRemainingAmount.get(trnPayment?.Id));

        return newMonetaryEntry;
    }
}