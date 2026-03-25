/**
 * @author      WDCi (XiRouh)
 * @date        Feb 2026
 * @group       Finance
 * @description Rollup the amount applied and usage count of confirmed study voucher transactions to study voucher
 * @changehistory
 * ISS-002591 13-02-2026 XiRouh - new class
 */
public without sharing class SVT_StudyVoucherRollup_EXE extends REDU_TriggerExecutable {

    /**
     * @description Study Voucher Transaction - Confirmed statuses
     */
    private static final List<String> SVT_CONFIRMED_STATUSES = SVT_Helper.getConfirmedStatuses();

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

            List<reduivy__Study_Voucher_Transaction__c> workingList = new List<reduivy__Study_Voucher_Transaction__c>();
            for (reduivy__Study_Voucher_Transaction__c newSvt : (List<reduivy__Study_Voucher_Transaction__c>) newList) {
                if (needRollup(newSvt, null)){
                    workingList.add(newSvt);
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

            List<reduivy__Study_Voucher_Transaction__c> workingList = new List<reduivy__Study_Voucher_Transaction__c>();
            for (reduivy__Study_Voucher_Transaction__c newSvt : (List<reduivy__Study_Voucher_Transaction__c>) newList) {
                reduivy__Study_Voucher_Transaction__c oldSvt = (reduivy__Study_Voucher_Transaction__c) oldMap.get(newSvt.Id);

                if (needRollup(newSvt, oldSvt)){
                    workingList.add(newSvt);
                }
                
                // Include the old parent to the rollup if the parent has changed
                Id newParentId = newSvt?.reduivy__Study_Voucher__c;
                Id oldParentId = oldSvt?.reduivy__Study_Voucher__c;
    
                if (String.isNotBlank(oldParentId) && newParentId != oldParentId) {
                    workingList.add(oldSvt);
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

            List<reduivy__Study_Voucher_Transaction__c> workingList = new List<reduivy__Study_Voucher_Transaction__c>();
            for (reduivy__Study_Voucher_Transaction__c oldSvt : (List<reduivy__Study_Voucher_Transaction__c>) oldList) {
                if (needRollup(null, oldSvt)){
                    workingList.add(oldSvt);
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

            List<reduivy__Study_Voucher_Transaction__c> workingList = new List<reduivy__Study_Voucher_Transaction__c>();
            for (reduivy__Study_Voucher_Transaction__c newSvt : (List<reduivy__Study_Voucher_Transaction__c>) newList) {
                if (needRollup(newSvt, null)){
                    workingList.add(newSvt);
                }
            }

            doRollup(workingList);
        }
    }
	
    /**
     * @description Validate if a SVT fulfill the rollup criteria
     * @param newSvt
     * @param oldSvt
     * @return Boolean
     */
    private Boolean needRollup(reduivy__Study_Voucher_Transaction__c newSvt, reduivy__Study_Voucher_Transaction__c oldSvt) {

        Boolean isConfirmed = String.isNotBlank(newSvt?.reduivy__Status__c) && SVT_CONFIRMED_STATUSES.contains(newSvt?.reduivy__Status__c);
        Boolean wasConfirmed = String.isNotBlank(oldSvt?.reduivy__Status__c) && SVT_CONFIRMED_STATUSES.contains(oldSvt?.reduivy__Status__c);
        
        Decimal newAmt = newSvt?.reduivy__Amount_Applied__c ?? 0;
        Decimal oldAmt = oldSvt?.reduivy__Amount_Applied__c ?? 0;

        Id newParentId = newSvt?.reduivy__Study_Voucher__c;
        Id oldParentId = oldSvt?.reduivy__Study_Voucher__c;

        Boolean isAmtChanged = newAmt != oldAmt;
        Boolean isParentChanged = newParentId != oldParentId;
        Boolean isStatusChanged = isConfirmed != wasConfirmed;
        
        // Reject any scenario where both new and old have no parent (no target to roll up to)
        if (String.isBlank(newParentId) && String.isBlank(oldParentId)) {
            return false;
        }

        // Handle delete: if newSvt is null but oldSvt was Confirmed
        if (newSvt == null && wasConfirmed && String.isNotBlank(oldParentId)) {
            return true;
        }

        return String.isNotBlank(newParentId) && (
            (isConfirmed && !wasConfirmed) || // Changed to Confirmed status
            (!isConfirmed && wasConfirmed) || // Changed from Confirmed status
            (isConfirmed && (isAmtChanged || isParentChanged)) // Confirmed with amount or parent changed
        );
    }

    /**
     * @description Perform rollup to study voucher
     * @param svtList
     * @return void
     */
    private void doRollup(List<reduivy__Study_Voucher_Transaction__c> svtList) {
        
        if (!svtList.isEmpty()) {
            
            Map<Id, List<reduivy__Study_Voucher_Transaction__c>> svtListByParent = new Map<Id, List<reduivy__Study_Voucher_Transaction__c>>();

            for (reduivy__Study_Voucher_Transaction__c svt : svtList) {
                if (String.isNotBlank(svt.reduivy__Study_Voucher__c)) {
                    if (!svtListByParent.containsKey(svt.reduivy__Study_Voucher__c)) {
                        svtListByParent.put(svt.reduivy__Study_Voucher__c, new List<reduivy__Study_Voucher_Transaction__c>());
                    }

                    svtListByParent.get(svt.reduivy__Study_Voucher__c).add(svt);
                }
            }

            Set<String> svoFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Amount_Applied__c',
                'reduivy__Usage_Count__c'
            };

            Set<String> svtFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Amount_Applied__c',
                'reduivy__Status__c'
            };

            Map<String, Object> bindParams = new Map<String, Object>();
            bindParams.put('parentIds', svtListByParent.keySet());
            bindParams.put('statusConfirmed', SVT_CONFIRMED_STATUSES);

            String svoSoql = 'SELECT ' + String.join(svoFields, ', ') + ', ' +
                ' (SELECT ' + String.join(svtFields, ', ') + 
                    ' FROM reduivy__Study_Voucher_Transactions__r ' + 
                    ' WHERE reduivy__Status__c = :statusConfirmed ' +
                ' ) ' +
                ' FROM reduivy__Study_Voucher__c ' + 
                ' WHERE Id IN :parentIds ' +
                ' FOR UPDATE';
            
            Map<String, Set<String>> objectFls = new Map<String, Set<String>>();
            objectFls.put(SVO_Helper.getApiName(), svoFields);
            objectFls.put(SVT_Helper.getApiName(), svtFields);

            List<reduivy__Study_Voucher__c> svoUpdateList = new List<reduivy__Study_Voucher__c>();
            for (reduivy__Study_Voucher__c svo : (List<reduivy__Study_Voucher__c>) REDU_SystemMode_UTIL.doQuery(svoSoql, bindParams, objectFls)) {
                Decimal totalAmountApplied = 0;
                Integer usageCount = 0;

                for (reduivy__Study_Voucher_Transaction__c svt : svo.reduivy__Study_Voucher_Transactions__r) {
                    totalAmountApplied += (svt.reduivy__Amount_Applied__c ?? 0);
                    usageCount++;
                }

                if (svo.reduivy__Amount_Applied__c != totalAmountApplied || svo.reduivy__Usage_Count__c != usageCount) {
                    reduivy__Study_Voucher__c svoUpdate = new reduivy__Study_Voucher__c();
                    svoUpdate.Id = svo.Id;
                    svoUpdate.reduivy__Amount_Applied__c = totalAmountApplied;
                    svoUpdate.reduivy__Usage_Count__c = usageCount;

                    svoUpdateList.add(svoUpdate);
                }
            }

            if (!svoUpdateList.isEmpty()) {
                REDU_SystemMode_UTIL.doUpdate(svoUpdateList, svtListByParent, 'Id', false);
            }
        }
    }
}