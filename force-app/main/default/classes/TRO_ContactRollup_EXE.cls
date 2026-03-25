/**
 * @author      WDCi (Lean)
 * @date        July 2025
 * @group       Finance
 * @description Rollup the total outstanding amount to contact
 * @changehistory
 * ISS-002587 24-07-2024 Lean - new class
 */

public without sharing class TRO_ContactRollup_EXE extends REDU_TriggerExecutable {

    static final Set<String> TRO_ROLLUP_STATUSES = new Set<String>();
    static {
        TRO_ROLLUP_STATUSES.addAll(TRO_Helper.getSubmittedStatuses());
        TRO_ROLLUP_STATUSES.addAll(TRO_Helper.getConfirmedStatuses());
        TRO_ROLLUP_STATUSES.addAll(TRO_Helper.getRefundedStatuses());
    }

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

            List<reduivy__Transaction_Order__c> workingList = new List<reduivy__Transaction_Order__c>();
            for (reduivy__Transaction_Order__c newTro : (List<reduivy__Transaction_Order__c>) newList) {
                if (needRollup(newTro, null)){
                    workingList.add(newTro);
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

            List<reduivy__Transaction_Order__c> workingList = new List<reduivy__Transaction_Order__c>();
            for (reduivy__Transaction_Order__c newTro : (List<reduivy__Transaction_Order__c>) newList) {
                reduivy__Transaction_Order__c oldTro = (reduivy__Transaction_Order__c) oldMap.get(newTro.Id);

                if (needRollup(newTro, oldTro)){
                    workingList.add(newTro);

                }
                
                //include the old parent to the rollup if the parent has changed
                Id newParentId = newTro?.reduivy__Contact__c;
                Id oldParentId = oldTro?.reduivy__Contact__c;

                if (String.isNotBlank(oldParentId) && newParentId != oldParentId) {
                    workingList.add(oldTro);
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

            List<reduivy__Transaction_Order__c> workingList = new List<reduivy__Transaction_Order__c>();
            for (reduivy__Transaction_Order__c oldTro : (List<reduivy__Transaction_Order__c>) oldList) {
                if (needRollup(null, oldTro)){
                    workingList.add(oldTro);
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

            List<reduivy__Transaction_Order__c> workingList = new List<reduivy__Transaction_Order__c>();
            for (reduivy__Transaction_Order__c newTro : (List<reduivy__Transaction_Order__c>) newList) {
                if (needRollup(newTro, null)){
                    workingList.add(newTro);
                }
            }

            doRollup(workingList);
        }
    }
	
    /**
     * @description Validate if a TRO fulfill the rollup criteria
     * @param newTro
     * @param oldTro
     * @return Boolean
     */
    private Boolean needRollup(reduivy__Transaction_Order__c newTro, reduivy__Transaction_Order__c oldTro) {

        Decimal newAmt = newTro?.reduivy__Total_Outstanding_Amount__c ?? 0;
        Decimal oldAmt = oldTro?.reduivy__Total_Outstanding_Amount__c ?? 0;

        Id newParentId = newTro?.reduivy__Contact__c;
        Id oldParentId = oldTro?.reduivy__Contact__c;

        Boolean isStatusQualified = TRO_ROLLUP_STATUSES.contains(newTro?.reduivy__Status__c);
        Boolean wasStatusQualified = TRO_ROLLUP_STATUSES.contains(oldTro?.reduivy__Status__c);

        Boolean isAmtChanged = newAmt != oldAmt;
        Boolean isParentChanged = newParentId != oldParentId;
        
        // Reject any scenario where both new and old have no parent (no target to roll up to)
        if (String.isBlank(newParentId) && String.isBlank(oldParentId)) {
            return false;
        }

        // Handle delete: if newTro is null but oldTro status was qualified
        if (newTro == null && wasStatusQualified && String.isNotBlank(oldParentId)) {
            return true;
        }

        return String.isNotBlank(newParentId) && (
            (isStatusQualified && !wasStatusQualified) || 
            (!isStatusQualified && wasStatusQualified) || 
            (isStatusQualified && (isAmtChanged || isParentChanged))
        );
    }

    /**
     * @description Perform rollup to contact
     * @param troList
     * @return void
     */
    private void doRollup(List<reduivy__Transaction_Order__c> troList) {
        
        if (!troList.isEmpty()) {
            
            Map<Id, List<reduivy__Transaction_Order__c>> troListByParent = new Map<Id, List<reduivy__Transaction_Order__c>>();
            
            for (reduivy__Transaction_Order__c tro : troList) {
                if (String.isNotBlank(tro.reduivy__Contact__c)) {
                    if (!troListByParent.containsKey(tro.reduivy__Contact__c)) {
                        troListByParent.put(tro.reduivy__Contact__c, new List<reduivy__Transaction_Order__c>());
                    }

                    troListByParent.get(tro.reduivy__Contact__c).add(tro);
                }
            }

            Set<String> contactFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Total_Outstanding_Amount__c'
            };

            Set<String> troFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Total_Outstanding_Amount__c'
            };

            Map<String, Object> bindParams = new Map<String, Object>();
            bindParams.put('parentIds', troListByParent.keySet());
            bindParams.put('troStatuses', TRO_ROLLUP_STATUSES);

            String contactSoql = 'SELECT ' + String.join(contactFields, ', ') + ', ' +
                ' (SELECT ' + String.join(troFields, ', ') + 
                    ' FROM reduivy__Transaction_Orders__r ' + 
                    ' WHERE reduivy__Status__c IN: troStatuses ' +
                ' ) ' +
                ' FROM Contact ' + 
                ' WHERE Id IN: parentIds ' +
                ' FOR UPDATE';
            
            Map<String, Set<String>> objectFls = new Map<String, Set<String>>();
            objectFls.put(CON_Helper.getApiName(), contactFields);
            objectFls.put(TRO_Helper.getApiName(), troFields);

            List<Contact> contactUpdateList = new List<Contact>();
            for (Contact con : (List<Contact>) REDU_SystemMode_UTIL.doQuery(contactSoql, bindParams, objectFls)) {
                Decimal totalOutstandingAmount = 0;

                for (reduivy__Transaction_Order__c tro : con.reduivy__Transaction_Orders__r) {
                    totalOutstandingAmount += (tro.reduivy__Total_Outstanding_Amount__c ?? 0);
                }

                if (con.reduivy__Total_Outstanding_Amount__c != totalOutstandingAmount) {
                    Contact conUpdate = new Contact();
                    conUpdate.Id = con.Id;
                    conUpdate.reduivy__Total_Outstanding_Amount__c = totalOutstandingAmount;

                    contactUpdateList.add(conUpdate);
                }
            }

            if (!contactUpdateList.isEmpty()) {
                REDU_SystemMode_UTIL.doUpdate(contactUpdateList, troListByParent, 'Id', false);
            }
        }
    }
}