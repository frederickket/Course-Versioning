/**
 * @author      WDCi (Lean)
 * @date        July 2025
 * @group       Finance
 * @description Rollup the total amount of monetary transaction line item to transaction payment
 * @changehistory
 * ISS-002587 24-07-2024 Lean - new class
 */

public without sharing class TRL_TransactionPaymentRollup_EXE extends REDU_TriggerExecutable {

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

                //include the old parent to the rollup if the parent has changed
                Id newParentId = newTrl?.reduivy__Transaction_Payment__c;
                Id oldParentId = oldTrl?.reduivy__Transaction_Payment__c;

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

        Boolean isMonetaryEntry = newTrl?.reduivy__Transaction_Type__c == TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY;
        Boolean wasMonetaryEntry = oldTrl?.reduivy__Transaction_Type__c == TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY;

        Decimal newAmt = newTrl?.reduivy__Total_Amount__c ?? 0;
        Decimal oldAmt = oldTrl?.reduivy__Total_Amount__c ?? 0;

        Id newParentId = newTrl?.reduivy__Transaction_Payment__c;
        Id oldParentId = oldTrl?.reduivy__Transaction_Payment__c;

        Boolean isAmtChanged = newAmt != oldAmt;
        Boolean isParentChanged = newParentId != oldParentId;
        
        // Reject any scenario where both new and old have no parent (no target to roll up to)
        if (String.isBlank(newParentId) && String.isBlank(oldParentId)) {
            return false;
        }

        // Handle delete: if newTrl is null but oldTrl was Monetary Entry
        if (newTrl == null && wasMonetaryEntry && String.isNotBlank(oldParentId)) {
            return true;
        }

        return String.isNotBlank(newParentId) && (
            (isMonetaryEntry && !wasMonetaryEntry) || 
            (!isMonetaryEntry && wasMonetaryEntry) || 
            (isMonetaryEntry && (isAmtChanged || isParentChanged))
        );
    }

    /**
     * @description Perform rollup to transaction payment
     * @param trlList
     * @return void
     */
    private void doRollup(List<reduivy__Transaction_Line_Item__c> trlList) {
        
        if (!trlList.isEmpty()) {
            
            Map<Id, List<reduivy__Transaction_Line_Item__c>> trlListByParent = new Map<Id, List<reduivy__Transaction_Line_Item__c>>();
            
            for (reduivy__Transaction_Line_Item__c trl : trlList) {
                if (String.isNotBlank(trl.reduivy__Transaction_Payment__c)) {
                    if (!trlListByParent.containsKey(trl.reduivy__Transaction_Payment__c)) {
                        trlListByParent.put(trl.reduivy__Transaction_Payment__c, new List<reduivy__Transaction_Line_Item__c>());
                    }

                    trlListByParent.get(trl.reduivy__Transaction_Payment__c).add(trl);
                }
            }

            Set<String> trpFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Applied_Amount__c'
            };

            Set<String> trlFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Total_Amount__c',
                'reduivy__Transaction_Type__c'
            };

            Map<String, Object> bindParams = new Map<String, Object>();
            bindParams.put('parentIds', trlListByParent.keySet());
            bindParams.put('trlTypes', new Set<String>{TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY});

            String trpSoql = 'SELECT ' + String.join(trpFields, ', ') + ', ' +
                ' (SELECT ' + String.join(trlFields, ', ') + 
                    ' FROM reduivy__Transaction_Line_Items__r ' + 
                    ' WHERE reduivy__Transaction_Type__c IN: trlTypes ' +
                ' ) ' +
                ' FROM reduivy__Transaction_Payment__c ' + 
                ' WHERE Id IN: parentIds ' +
                ' FOR UPDATE';
            
            Map<String, Set<String>> objectFls = new Map<String, Set<String>>();
            objectFls.put(TRP_Helper.getApiName(), trpFields);
            objectFls.put(TRL_Helper.getApiName(), trlFields);

            List<reduivy__Transaction_Payment__c> trpUpdateList = new List<reduivy__Transaction_Payment__c>();
            for (reduivy__Transaction_Payment__c trp : (List<reduivy__Transaction_Payment__c>) REDU_SystemMode_UTIL.doQuery(trpSoql, bindParams, objectFls)) {
                Decimal amountApplied = 0;

                for (reduivy__Transaction_Line_Item__c trl : trp.reduivy__Transaction_Line_Items__r) {
                    if (trl.reduivy__Transaction_Type__c == TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY) {
                        amountApplied += (trl.reduivy__Total_Amount__c ?? 0);
                    }
                }

                if (trp.reduivy__Applied_Amount__c != amountApplied) {
                    reduivy__Transaction_Payment__c trpUpdate = new reduivy__Transaction_Payment__c();
                    trpUpdate.Id = trp.Id;
                    trpUpdate.reduivy__Applied_Amount__c = amountApplied;

                    trpUpdateList.add(trpUpdate);
                }
            }

            if (!trpUpdateList.isEmpty()) {
                REDU_SystemMode_UTIL.doUpdate(trpUpdateList, trlListByParent, 'Id', false);
            }
        }
    }
}