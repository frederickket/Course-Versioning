/**
 * @author      WDCi (XiRouh)
 * @date        Aug 2025
 * @group       
 * @description Delete all related Study Voucher Transaction if Transaction Order is deleted
 * @changehistory
 * ISS-002566 20-08-2025 XiRouh - new class
 */
public inherited sharing class TRO_DeleteStudyVoucherTrx_EXE extends REDU_TriggerExecutable {
    
	/**
     * @description BeforeDelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            if (!oldList.isEmpty()) {
                Map<Id, reduivy__Transaction_Order__c> troOldMap = new Map<Id, reduivy__Transaction_Order__c>((List<reduivy__Transaction_Order__c>) oldList);
                List<reduivy__Study_Voucher_Transaction__c> svtDeleteList = new List<reduivy__Study_Voucher_Transaction__c>();

                 //find related study voucher transactions
                Map<String, Object> svtBindParams = new Map<String, Object>();
                svtBindParams.put('troIds', troOldMap.keySet());

                String svtQuery = 'SELECT Id, reduivy__Transaction_Order__c' +
                    ' FROM reduivy__Study_Voucher_Transaction__c ' +
                    ' WHERE reduivy__Transaction_Order__c IN :troIds ';

                Map<String, Set<String>> svtObjectFieldsFls = new Map<String, Set<String>>();
                svtObjectFieldsFls.put(SVT_Helper.getApiName(), new Set<String>{'Id'});

                for(reduivy__Study_Voucher_Transaction__c svt : (List<reduivy__Study_Voucher_Transaction__c>) REDU_SystemMode_UTIL.doQuery(svtQuery, svtBindParams, svtObjectFieldsFls)){
                    svtDeleteList.add(svt);
                }

                if(!svtDeleteList.isEmpty()) {
                    REDU_SystemMode_UTIL.doDelete(svtDeleteList, troOldMap, 'reduivy__Transaction_Order__c', false);
                }
            }
        }
    }
}