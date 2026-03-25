/**
 * @author      WDCi (XiRouh)
 * @date        Aug 2025
 * @group       
 * @description Set the Study Voucher transaction status to map to the updated Transaction Order status based on the custom metadata configuration.
 * @changehistory
 * ISS-002566 19-08-2025 XiRouh - new class
 */
public inherited sharing class TRO_SetStudyVoucherTrxStatus_EXE extends REDU_TriggerExecutable {

    /**
     * @description Map to match Transaction Order and Study Voucher Transaction statuses
     */
    static final Map<String, String> TRO_TO_SVT_STATUS_MAP = TRO_Helper.getTroToSvtStatusMap();

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

            Map<Id, reduivy__Transaction_Order__c> troMap = new Map<Id, reduivy__Transaction_Order__c>();

            for (reduivy__Transaction_Order__c newTro : (List<reduivy__Transaction_Order__c>) newList) {
                reduivy__Transaction_Order__c oldTro = (reduivy__Transaction_Order__c) oldMap.get(newTro.Id);

                if(newTro.reduivy__Status__c != oldTro.reduivy__Status__c 
                    && TRO_TO_SVT_STATUS_MAP.containsKey(newTro.reduivy__Status__c) 
                ){
                    troMap.put(newTro.Id, newTro);
                }
            }

            if(!troMap.isEmpty()) {
                updateRelatedSvtStatus(troMap);
            }
        }
    }
	
    /**
     * @description Set the Study Voucher transaction status to map to the updated Transaction Order status based on the custom metadata configuration
     * @param   Map<Id, reduivy__Transaction_Order__c> troMap
     * @return void
     */
    private void updateRelatedSvtStatus(Map<Id, reduivy__Transaction_Order__c> troMap) {

        if(!troMap.isEmpty()) {
            List<reduivy__Study_Voucher_Transaction__c> svtToUpdate = new List<reduivy__Study_Voucher_Transaction__c>();

            //find related study voucher transactions
            Map<String, Object> svtBindParams = new Map<String, Object>();
            svtBindParams.put('troIds', troMap.keySet());

            String svtQuery = 'SELECT Id, reduivy__Status__c, reduivy__Transaction_Order__c' +
                ' FROM reduivy__Study_Voucher_Transaction__c ' +
                ' WHERE reduivy__Transaction_Order__c IN :troIds ';

            for(reduivy__Study_Voucher_Transaction__c svt : (List<reduivy__Study_Voucher_Transaction__c>) Database.queryWithBinds(svtQuery, svtBindParams, AccessLevel.USER_MODE)){
                reduivy__Transaction_Order__c parentTro = troMap.get(svt.reduivy__Transaction_Order__c);

                if(TRO_TO_SVT_STATUS_MAP.containsKey(parentTro.reduivy__Status__c) && svt.reduivy__Status__c != TRO_TO_SVT_STATUS_MAP.get(parentTro.reduivy__Status__c)) {

                    svt.reduivy__Status__c = TRO_TO_SVT_STATUS_MAP.get(parentTro.reduivy__Status__c);
                    svtToUpdate.add(svt);
                }
            }

            if(!svtToUpdate.isEmpty()){
                REDU_Database_UTIL.doUpdate(svtToUpdate, troMap, 'reduivy__Transaction_Order__c', false);
            }
        }
    }
}