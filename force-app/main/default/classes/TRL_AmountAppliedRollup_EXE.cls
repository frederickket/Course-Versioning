/**
 * @author      WDCi (XiRouh)
 * @date        Feb 2026
 * @group       Finance
 * @description Rollup the total amount of discount entry transaction line items to study voucher transaction
 * @changehistory
 * ISS-002591 11-02-2026 XiRouh - new class
 */

public without sharing class TRL_AmountAppliedRollup_EXE extends REDU_TriggerExecutable {

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

            List<reduivy__Transaction_Line_Item__c> workingList = new List<reduivy__Transaction_Line_Item__c>();
            for (reduivy__Transaction_Line_Item__c newTrl : (List<reduivy__Transaction_Line_Item__c>) newList) {
                if (needRollup(newTrl, null)){
                    workingList.add(newTrl);
                }
            }

            doRollup(workingList);
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

            List<reduivy__Transaction_Line_Item__c> workingList = new List<reduivy__Transaction_Line_Item__c>();
            for (reduivy__Transaction_Line_Item__c newTrl : (List<reduivy__Transaction_Line_Item__c>) newList) {
                reduivy__Transaction_Line_Item__c oldTrl = (reduivy__Transaction_Line_Item__c) oldMap.get(newTrl.Id);

                if (needRollup(newTrl, oldTrl)){
                    workingList.add(newTrl);
                }
                
                // Include the old parent to the rollup if the parent has changed
                Id newParentId = newTrl?.reduivy__Study_Voucher_Transaction__c;
                Id oldParentId = oldTrl?.reduivy__Study_Voucher_Transaction__c;
    
                if (String.isNotBlank(oldParentId) && newParentId != oldParentId) {
                    workingList.add(oldTrl);
                }
            }

            doRollup(workingList);
        }
    }

    /**
     * @description AfterDelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Transaction_Line_Item__c> workingList = new List<reduivy__Transaction_Line_Item__c>();
            for (reduivy__Transaction_Line_Item__c oldTrl : (List<reduivy__Transaction_Line_Item__c>) oldList) {
                if (needRollup(null, oldTrl)){
                    workingList.add(oldTrl);
                }
            }

            doRollup(workingList);
        }
    }

    /**
     * @description AfterUndelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUndelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Transaction_Line_Item__c> workingList = new List<reduivy__Transaction_Line_Item__c>();
            for (reduivy__Transaction_Line_Item__c newTrl : (List<reduivy__Transaction_Line_Item__c>) newList) {
                if (needRollup(newTrl, null)){
                    workingList.add(newTrl);
                }
            }

            doRollup(workingList);
        }
    }
	
    /**
     * @description Validate if a TRL fulfill the rollup criteria
     * @param newTrl
     * @param oldTrl
     * @return Boolean
     */
    private Boolean needRollup(reduivy__Transaction_Line_Item__c newTrl, reduivy__Transaction_Line_Item__c oldTrl) {

        Boolean isDiscountEntry = newTrl?.reduivy__Transaction_Type__c == TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
        Boolean wasDiscountEntry = oldTrl?.reduivy__Transaction_Type__c == TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
        
        Decimal newAmt = newTrl?.reduivy__Total_Amount__c ?? 0;
        Decimal oldAmt = oldTrl?.reduivy__Total_Amount__c ?? 0;

        Id newParentId = newTrl?.reduivy__Study_Voucher_Transaction__c;
        Id oldParentId = oldTrl?.reduivy__Study_Voucher_Transaction__c;

        Boolean isAmtChanged = newAmt != oldAmt;
        Boolean isParentChanged = newParentId != oldParentId;
        
        // Reject any scenario where both new and old have no parent (no target to roll up to)
        if (String.isBlank(newParentId) && String.isBlank(oldParentId)) {
            return false;
        }

        // Handle delete: if newTrl is null but oldTrl was Discount Entry
        if (newTrl == null && wasDiscountEntry && String.isNotBlank(oldParentId)) {
            return true;
        }

        return String.isNotBlank(newParentId) && (
            (isDiscountEntry && !wasDiscountEntry) || // Changed to Discount Entry
            (!isDiscountEntry && wasDiscountEntry) || // Changed from Discount Entry
            (isDiscountEntry && (isAmtChanged || isParentChanged)) // Discount Entry with amount or parent changed
        );
    }

    /**
     * @description Perform rollup to study voucher transaction
     * @param trlList
     * @return void
     */
    private void doRollup(List<reduivy__Transaction_Line_Item__c> trlList) {
        
        if (!trlList.isEmpty()) {
            
            Map<Id, List<reduivy__Transaction_Line_Item__c>> trlListByParent = new Map<Id, List<reduivy__Transaction_Line_Item__c>>();
            
            for (reduivy__Transaction_Line_Item__c trl : trlList) {
                if (String.isNotBlank(trl.reduivy__Study_Voucher_Transaction__c)) {
                    if (!trlListByParent.containsKey(trl.reduivy__Study_Voucher_Transaction__c)) {
                        trlListByParent.put(trl.reduivy__Study_Voucher_Transaction__c, new List<reduivy__Transaction_Line_Item__c>());
                    }

                    trlListByParent.get(trl.reduivy__Study_Voucher_Transaction__c).add(trl);
                }
            }

            Set<String> svtFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Amount_Applied__c'
            };

            Set<String> trlFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Total_Amount__c',
                'reduivy__Transaction_Type__c'
            };

            Map<String, Object> bindParams = new Map<String, Object>();
            bindParams.put('parentIds', trlListByParent.keySet());
            bindParams.put('trlType', TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY);

            String svtSoql = 'SELECT ' + String.join(svtFields, ', ') + ', ' +
                ' (SELECT ' + String.join(trlFields, ', ') + 
                    ' FROM reduivy__Transaction_Line_Items__r ' + 
                    ' WHERE reduivy__Transaction_Type__c = :trlType ' +
                ' ) ' +
                ' FROM reduivy__Study_Voucher_Transaction__c ' + 
                ' WHERE Id IN :parentIds ' +
                ' FOR UPDATE';
            
            Map<String, Set<String>> objectFls = new Map<String, Set<String>>();
            objectFls.put(SVT_Helper.getApiName(), svtFields);
            objectFls.put(TRL_Helper.getApiName(), trlFields);

            List<reduivy__Study_Voucher_Transaction__c> svtUpdateList = new List<reduivy__Study_Voucher_Transaction__c>();
            for (reduivy__Study_Voucher_Transaction__c svt : (List<reduivy__Study_Voucher_Transaction__c>) REDU_SystemMode_UTIL.doQuery(svtSoql, bindParams, objectFls)) {
                Decimal totalAmountApplied = 0;

                for (reduivy__Transaction_Line_Item__c trl : svt.reduivy__Transaction_Line_Items__r) {
                    if (trl.reduivy__Transaction_Type__c == TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY) {
                        totalAmountApplied += (trl.reduivy__Total_Amount__c ?? 0);
                    }
                }

                if (svt.reduivy__Amount_Applied__c != totalAmountApplied) {
                    reduivy__Study_Voucher_Transaction__c svtUpdate = new reduivy__Study_Voucher_Transaction__c();
                    svtUpdate.Id = svt.Id;
                    svtUpdate.reduivy__Amount_Applied__c = totalAmountApplied;

                    svtUpdateList.add(svtUpdate);
                }
            }

            if (!svtUpdateList.isEmpty()) {
                REDU_SystemMode_UTIL.doUpdate(svtUpdateList, trlListByParent, 'Id', false);
            }
        }
    }
}