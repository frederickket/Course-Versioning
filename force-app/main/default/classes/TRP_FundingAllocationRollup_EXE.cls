/**
 * @author      WDCi (Lean)
 * @date        July 2025
 * @group       Finance
 * @description Rollup the total amount to individual funding allocation
 * @changehistory
 * ISS-002587 24-07-2024 Lean - new class
 */

public without sharing class TRP_FundingAllocationRollup_EXE extends REDU_TriggerExecutable {

    static String TRP_ACTIVE_STATUS = TRP_Helper.STATUS_ACTIVE;
    // TODO static {
    //     TRP_ROLLUP_STATUSES.addAll(TRP_Helper.getActiveStatuses());
    // }

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

            List<reduivy__Transaction_Payment__c> workingList = new List<reduivy__Transaction_Payment__c>();
            for (reduivy__Transaction_Payment__c newTrp : (List<reduivy__Transaction_Payment__c>) newList) {
                if (needRollup(newTrp, null)){
                    workingList.add(newTrp);
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

            List<reduivy__Transaction_Payment__c> workingList = new List<reduivy__Transaction_Payment__c>();
            for (reduivy__Transaction_Payment__c newTrp : (List<reduivy__Transaction_Payment__c>) newList) {
                reduivy__Transaction_Payment__c oldTrp = (reduivy__Transaction_Payment__c) oldMap.get(newTrp.Id);

                if (needRollup(newTrp, oldTrp)){
                    workingList.add(newTrp);

                }
                
                //include the old parent to the rollup if the parent has changed
                Id newParentId = newTrp?.reduivy__Individual_Funding_Allocation__c;
                Id oldParentId = oldTrp?.reduivy__Individual_Funding_Allocation__c;

                if (String.isNotBlank(oldParentId) && newParentId != oldParentId) {
                    workingList.add(oldTrp);
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

            List<reduivy__Transaction_Payment__c> workingList = new List<reduivy__Transaction_Payment__c>();
            for (reduivy__Transaction_Payment__c oldTrp : (List<reduivy__Transaction_Payment__c>) oldList) {
                if (needRollup(null, oldTrp)){
                    workingList.add(oldTrp);
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

            List<reduivy__Transaction_Payment__c> workingList = new List<reduivy__Transaction_Payment__c>();
            for (reduivy__Transaction_Payment__c newTrp : (List<reduivy__Transaction_Payment__c>) newList) {
                if (needRollup(newTrp, null)){
                    workingList.add(newTrp);
                }
            }

            doRollup(workingList);
        }
    }
	
    /**
     * @description Validate if a TRP fulfill the rollup criteria
     * @param newTrp
     * @param oldTrp
     * @return Boolean
     */
    private Boolean needRollup(reduivy__Transaction_Payment__c newTrp, reduivy__Transaction_Payment__c oldTrp) {

        Decimal newAmt = newTrp?.reduivy__Amount__c ?? 0;
        Decimal oldAmt = oldTrp?.reduivy__Amount__c ?? 0;

        Id newParentId = newTrp?.reduivy__Individual_Funding_Allocation__c;
        Id oldParentId = oldTrp?.reduivy__Individual_Funding_Allocation__c;

        Boolean isStatusQualified = newTrp?.reduivy__Status__c == TRP_ACTIVE_STATUS;
        Boolean wasStatusQualified = oldTrp?.reduivy__Status__c == TRP_ACTIVE_STATUS;

        Boolean isAmtChanged = newAmt != oldAmt;
        Boolean isParentChanged = newParentId != oldParentId;
        
        // Reject any scenario where both new and old have no parent (no target to roll up to)
        if (String.isBlank(newParentId) && String.isBlank(oldParentId)) {
            return false;
        }

        // Handle delete: if newTrp is null but oldTrp status was qualified
        if (newTrp == null && wasStatusQualified && String.isNotBlank(oldParentId)) {
            return true;
        }

        return String.isNotBlank(newParentId) && (
            (isStatusQualified && !wasStatusQualified) || 
            (!isStatusQualified && wasStatusQualified) || 
            (isStatusQualified && (isAmtChanged || isParentChanged))
        );
    }

    /**
     * @description Perform rollup to individual funding allocation
     * @param trpList
     * @return void
     */
    private void doRollup(List<reduivy__Transaction_Payment__c> trpList) {
        
        if (!trpList.isEmpty()) {
            
            Map<Id, List<reduivy__Transaction_Payment__c>> trpListByParent = new Map<Id, List<reduivy__Transaction_Payment__c>>();
            
            for (reduivy__Transaction_Payment__c trp : trpList) {
                if (String.isNotBlank(trp.reduivy__Individual_Funding_Allocation__c)) {
                    if (!trpListByParent.containsKey(trp.reduivy__Individual_Funding_Allocation__c)) {
                        trpListByParent.put(trp.reduivy__Individual_Funding_Allocation__c, new List<reduivy__Transaction_Payment__c>());
                    }

                    trpListByParent.get(trp.reduivy__Individual_Funding_Allocation__c).add(trp);
                }
            }

            Set<String> ifaFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Disbursed_Amount__c'
            };

            Set<String> trpFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Amount__c'
            };

            Map<String, Object> bindParams = new Map<String, Object>();
            bindParams.put('parentIds', trpListByParent.keySet());
            bindParams.put('trpStatus', TRP_ACTIVE_STATUS);

            String ifaSoql = 'SELECT ' + String.join(ifaFields, ', ') + ', ' +
                ' (SELECT ' + String.join(trpFields, ', ') + 
                    ' FROM reduivy__Transaction_Payments__r ' + 
                    ' WHERE reduivy__Status__c =: trpStatus ' +
                ' ) ' +
                ' FROM reduivy__Individual_Funding_Allocation__c ' + 
                ' WHERE Id IN: parentIds ' +
                ' FOR UPDATE';
            
            Map<String, Set<String>> objectFls = new Map<String, Set<String>>();
            objectFls.put(IFA_Helper.getApiName(), ifaFields);
            objectFls.put(TRP_Helper.getApiName(), trpFields);

            List<reduivy__Individual_Funding_Allocation__c> ifaUpdateList = new List<reduivy__Individual_Funding_Allocation__c>();
            for (reduivy__Individual_Funding_Allocation__c con : (List<reduivy__Individual_Funding_Allocation__c>) REDU_SystemMode_UTIL.doQuery(ifaSoql, bindParams, objectFls)) {
                Decimal disbursedAmount = 0;

                for (reduivy__Transaction_Payment__c trp : con.reduivy__Transaction_Payments__r) {
                    disbursedAmount += (trp.reduivy__Amount__c ?? 0);
                }

                if (con.reduivy__Disbursed_Amount__c != disbursedAmount) {
                    reduivy__Individual_Funding_Allocation__c ifaUpdate = new reduivy__Individual_Funding_Allocation__c();
                    ifaUpdate.Id = con.Id;
                    ifaUpdate.reduivy__Disbursed_Amount__c = disbursedAmount;

                    ifaUpdateList.add(ifaUpdate);
                }
            }

            if (!ifaUpdateList.isEmpty()) {
                REDU_SystemMode_UTIL.doUpdate(ifaUpdateList, trpListByParent, 'Id', false);
            }
        }
    }
}