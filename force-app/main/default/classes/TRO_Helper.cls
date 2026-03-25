/**
 * @author      WDCi (Lean)
 * @date        Feb 2024
 * @group       Object Helper
 * @description Transaction Order object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002024 31-07-2024 VTan - Introduced custom metadata for transaction order status configuration. 
 * ISS-002510 28-07-2025 XW - created distributeOrderDiscount to distribute order discount to the transaction order
 */
global inherited sharing class TRO_Helper implements SObject_Helper {

    /**
     * @description Transaction Order Status picklist constants - Confirmed
     */
    public static final String STATUS_TYPE_CONFIRMED = 'Confirmed';

    /**
     * @description Transaction Order Status picklist constants - Draft
     */
    public static final String STATUS_TYPE_DRAFT = 'Draft';

    /**
     * @description Transaction Order Status picklist constants - Void
     */
    public static final String STATUS_TYPE_VOID = 'Void';

    /**
     * @description Transaction Order Status picklist constants - Submitted
     */
    public static final String STATUS_TYPE_SUBMITTED = 'Submitted';
    
    /**
     * @description Transaction Order Status picklist constants - Refunded
     */
    public static final String STATUS_TYPE_REFUNDED = 'Refunded';

    /**
     * @description Transaction Order Payment Status - Paid
     */
    public static final String PAYMENT_STATUS_PAID = 'Paid';

    /**
     * @description Transaction Order Payment Status - Partially Paid
     */
    public static final String PAYMENT_STATUS_PARTIALLYPAID = 'Partially Paid';

    /**
     * @description Transaction Order Payment Status - Not Paid
     */
    public static final String PAYMENT_STATUS_NOTPAID = 'Not Paid';

    /**
     * @description Transaction Order Payment Status - No Payment Required
     */
    public static final String PAYMENT_STATUS_NOPAYMENTREQUIRED = 'No Payment Required';

    /**
     * @description Return object type
     * @return String
     */
    public static Schema.SObjectType getObjectType() {
        return SObjectType.reduivy__Transaction_Order__c.getSObjectType();
    }

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Transaction_Order__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Transaction_Order__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Transaction_Order__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Transaction_Order__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
    
    /** ISS-002024
     * @description List of reduivy__Transaction_Order_Status_Config__mdt
     */
    private static List<reduivy__Transaction_Order_Status_Config__mdt> troStatusConfigs;

    /**
     * @description Transaction order status configs metadata sorted according to Status field
     * @return List<reduivy__Transaction_Order_Status_Config__mdt>
     */
    public static List<reduivy__Transaction_Order_Status_Config__mdt> getTroStatusConfig(){

        if (troStatusConfigs == null) {
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Transaction_Order__c.fields.reduivy__Status__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__Transaction_Order_Status_Config__mdt> configs = reduivy__Transaction_Order_Status_Config__mdt.getAll().values();
            List<reduivy__Transaction_Order_Status_Config__mdt> sortedConfigs = new List<reduivy__Transaction_Order_Status_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList) {
                if(ple.isActive()) {
                    for (reduivy__Transaction_Order_Status_Config__mdt config : configs) {
                        if (config.reduivy__Active__c && ple.getValue() == config.reduivy__Status__c) {
                            sortedConfigs.add(config);
                        }
                    }
                }
            }

            troStatusConfigs = sortedConfigs;
        }

        return troStatusConfigs;
    }

    /**
     * @description Draft statuses
     */
    private static List<String> draftStatuses;
	
    /*
     * @description Return a list of Draft status
     * @return List<String>
     */
    public static List<String> getDraftStatuses() {

        if (draftStatuses == null) {
            draftStatuses = new List<String>();

            for (reduivy__Transaction_Order_Status_Config__mdt config : getTroStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_DRAFT) {
                    draftStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return draftStatuses;
    }

    /**
     * @description Submitted statuses
     */
    private static List<String> submittedStatuses;
	
    /*
     * @description Return a list of Submitted status
     * @return List<String>
     */
    public static List<String> getSubmittedStatuses() {

        if (submittedStatuses == null) {
            submittedStatuses = new List<String>();

            for (reduivy__Transaction_Order_Status_Config__mdt config : getTroStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_SUBMITTED) {
                    submittedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return submittedStatuses;
    }

    /**
     * @description Confirmed statuses
     */
    private static List<String> confirmedStatuses;
	
    /*
     * @description Return a list of Confirmed status
     * @return List<String>
     */
    public static List<String> getConfirmedStatuses() {

        if (confirmedStatuses == null) {
            confirmedStatuses = new List<String>();

            for (reduivy__Transaction_Order_Status_Config__mdt config : getTroStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_CONFIRMED) {
                    confirmedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return confirmedStatuses;
    }

    /**
     * @description Void statuses
     */
    private static List<String> voidStatuses;
	
    /*
     * @description Return a list of Void status
     * @return List<String>
     */
    public static List<String> getVoidStatuses() {

        if (voidStatuses == null) {
            voidStatuses = new List<String>();

            for (reduivy__Transaction_Order_Status_Config__mdt config : getTroStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_VOID) {
                    voidStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return voidStatuses;
    }

    /**
     * @description Refunded statuses
     */
    private static List<String> refundedStatuses;
	
    /*
     * @description Return a list of Refunded status
     * @return List<String>
     */
    public static List<String> getRefundedStatuses() {

        if (refundedStatuses == null) {
            refundedStatuses = new List<String>();

            for (reduivy__Transaction_Order_Status_Config__mdt config : getTroStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_REFUNDED) {
                    refundedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return refundedStatuses;
    }

    /**
     * @description Return a map to match TRO and SVT statuses
     */
    private static Map<String, String> troToSvtStatusMap;

    /**
     * @description Get map of Transaction Order to Study Voucher Transaction status
     * @return Map<String, String>
     */
    public static Map<String, String> getTroToSvtStatusMap() {
        
        if(troToSvtStatusMap == null){

            troToSvtStatusMap = new Map<String, String>();
    
            for (reduivy__Transaction_Order_Status_Config__mdt config : getTroStatusConfig()) {
    
                if (String.isNotBlank(config.reduivy__Study_Voucher_Transaction_Status__c)) {
                    troToSvtStatusMap.put(config.reduivy__Status__c, config.reduivy__Study_Voucher_Transaction_Status__c);
                }
            }
        }

        return troToSvtStatusMap;
    }

    /**
     * @description distribute the order level discount from study voucher transaction.
     * If the order level discount has been distributed before, the distributed trl discount entry will be deleted
     * @param  troIdSet troIdSet description
     */
    public static void distributeOrderDiscount(Set<Id> troIdSet) {
        SavePoint sp = Database.setSavepoint();
        try {
            if(!troIdSet.isEmpty()) {

                //delete existing distributed order discount if any
                deleteDistributedOrderDiscount(troIdSet);
                
                // get the study voucher transaction (order level discount)
                Map<Id, List<reduivy__Study_Voucher_Transaction__c>> orderLevelDiscountMap = getOrderDiscount(troIdSet);
                Map<Id, Map<Id, Decimal>> troIdToOrderItemAmountMap = new Map<Id, Map<Id, Decimal>>();
                Map<Id, Decimal> troTotalAmountMap = new Map<Id, Decimal>();
                List<reduivy__Transaction_Line_Item__c> distributedTrlListToInsert = new List<reduivy__Transaction_Line_Item__c>();
                
                if(orderLevelDiscountMap.isEmpty()) {
                    return;
                }
                
                //get the order line transaction line item
                for(reduivy__Transaction_Line_Item__c trl : [
                    SELECT Id, 
                    Name, 
                    reduivy__Unit_Price__c, 
                    reduivy__Subtotal__c,
                    reduivy__Outstanding_Amount__c,
                    reduivy__Total_Amount__c,
                    reduivy__Discount__c,
                    reduivy__Offset_Line_Item__c,
                    reduivy__Transaction_Type__c,
                    reduivy__Transaction_Order__c, 
                    reduivy__Transaction_Order__r.reduivy__Total_Amount__c
                    FROM reduivy__Transaction_Line_Item__c
                    WHERE reduivy__Transaction_Order__c IN :troIdSet
                    AND reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_ORDERLINE
                    WITH USER_MODE
                ]) {
                    if(!troIdToOrderItemAmountMap.containsKey(trl.reduivy__Transaction_Order__c)) {
                        troIdToOrderItemAmountMap.put(trl.reduivy__Transaction_Order__c, new Map<Id, Decimal>());
                    }
                    troIdToOrderItemAmountMap.get(trl.reduivy__Transaction_Order__c).put(trl.Id, (trl.reduivy__Total_Amount__c ?? 0));
                    
                    if(!troTotalAmountMap.containsKey(trl.reduivy__Transaction_Order__c)) {   
                        troTotalAmountMap.put(trl.reduivy__Transaction_Order__c, (trl.reduivy__Transaction_Order__r.reduivy__Total_Amount__c ?? 0));
                    }
                }

                //now we loop through the order level discount
                for(Id troId : orderLevelDiscountMap.keySet()) {
                    
                    //find the distribution ratio of the order level first
                    Map<Id, Decimal> trlDistributionRatio = new Map<Id, Decimal>();
                    Map<Id, Decimal> orderItemAmountMap = troIdToOrderItemAmountMap.get(troId);
                    Decimal troTotalAmount = troTotalAmountMap.get(troId);
                    Integer orderItemSize = 0;

                    //calculate the ratio for each order line item to be distributed
                    for(Id trlId : orderItemAmountMap.keySet()) {
                        Decimal ratio = orderItemAmountMap.get(trlId) / troTotalAmount;
                        trlDistributionRatio.put(trlId, ratio);
                        orderItemSize++;
                    }

                    //loop through all of the order level discount of each tro
                    for(reduivy__Study_Voucher_Transaction__c orderDiscountSvt : orderLevelDiscountMap.get(troId)) {
                        Decimal remainingOrderDiscount = orderDiscountSvt.reduivy__Amount__c ?? 0;
                        Decimal totalOrderDiscount = orderDiscountSvt.reduivy__Amount__c ?? 0;
                        Integer currentItemIdx = 0;

                        //create a discount entry trl for each order line trl
                        for(Id trlId : trlDistributionRatio.keySet()) {
                            Decimal ratio = trlDistributionRatio.get(trlId);

                            reduivy__Transaction_Line_Item__c distributedTrl = new reduivy__Transaction_Line_Item__c();
                            distributedTrl.reduivy__Transaction_Order__c = troId;
                            distributedTrl.reduivy__Study_Voucher_Transaction__c = orderDiscountSvt.Id;
                            distributedTrl.reduivy__Item_Name__c = orderDiscountSvt.reduivy__Study_Voucher__r.Name;
                            distributedTrl.reduivy__Quantity__c = 1;
                            distributedTrl.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                            distributedTrl.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                            distributedTrl.reduivy__Offset_Line_Item__c = trlId;
                            
                            if(currentItemIdx < orderItemSize - 1) {
                                //distribute based on ratio
                                distributedTrl.reduivy__Unit_Price__c = ratio * totalOrderDiscount;
                            } else {
                                //distribute all the remaining amount if it is the last trl to distribute to avoid d.p. issue
                                distributedTrl.reduivy__Unit_Price__c = remainingOrderDiscount; 
                            }

                            distributedTrlListToInsert.add(distributedTrl);
                            remainingOrderDiscount -= distributedTrl.reduivy__Unit_Price__c;

                            currentItemIdx++;
                        }
                    }
                }

                if(!distributedTrlListToInsert.isEmpty()) {
                    REDU_Database_UTIL.doInsert(distributedTrlListToInsert);
                }
            }
            
        } catch (Exception exp){
            Database.rollback(sp);
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description delete the distributed order discount if found
     * @param  troIdSet 
     */
    private static void deleteDistributedOrderDiscount(Set<Id> troIdSet){
        List<reduivy__Transaction_Line_Item__c> distributedOrderDiscount = new List<reduivy__Transaction_Line_Item__c>();
        for(reduivy__Transaction_Line_Item__c trl : [
            SELECT Id
            FROM reduivy__Transaction_Line_Item__c
            WHERE reduivy__Transaction_Order__c IN :troIdSet
            AND reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY
            AND reduivy__Study_Voucher_Transaction__c != null
            AND reduivy__Study_Voucher_Transaction__r.reduivy__Study_Voucher__r.reduivy__Apply_As__c = :SVO_Helper.APPLY_AS_ORDER
            WITH USER_MODE
        ]) {
            distributedOrderDiscount.add(trl);
        }

        if(!distributedOrderDiscount.isEmpty()) {
            REDU_Database_UTIL.doDelete(distributedOrderDiscount);
        }
    }
    
    /**
     * @description get a list of study voucher transaction (order level discount) and mapped them with the tro id
     * @param  troIdSet troIdSet description
     * @return          return description
     */
    private static Map<Id, List<reduivy__Study_Voucher_Transaction__c>> getOrderDiscount(Set<Id> troIdSet) {
        
        Map<Id, List<reduivy__Study_Voucher_Transaction__c>> troIdToSvtMap = new Map<Id, List<reduivy__Study_Voucher_Transaction__c>>();
        for(reduivy__Study_Voucher_Transaction__c svt : [
            SELECT Id,
            Name,
            reduivy__Amount__c,
            reduivy__Transaction_Order__c,
            reduivy__Study_Voucher__r.reduivy__Voucher_Type__c,
            reduivy__Study_Voucher__r.reduivy__Voucher_Value__c,
            reduivy__Study_Voucher__r.Name
            FROM reduivy__Study_Voucher_Transaction__c
            WHERE reduivy__Transaction_Order__c IN :troIdSet
            AND reduivy__Study_Voucher__r.reduivy__Apply_As__c = :SVO_Helper.APPLY_AS_ORDER
            AND reduivy__Status__c = :SVT_Helper.STATUS_CONFIRMED
            WITH USER_MODE
        ]) {
            if(troIdToSvtMap.containsKey(svt.reduivy__Transaction_Order__c)) {
                troIdToSvtMap.get(svt.reduivy__Transaction_Order__c).add(svt);
            } else {
                troIdToSvtMap.put(svt.reduivy__Transaction_Order__c, new List<reduivy__Study_Voucher_Transaction__c>{ svt });
            }
        }

        return troIdToSvtMap;
    }
}