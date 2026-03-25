/**
 * @author      WDCi (Vtan)
 * @date        Feb 2024
 * @group       Finance
 * @description Delete all related Transaction Line Item if Transaction Order is deleted
 * @changehistory
 * ISS-001866 23-02-2024 VTan - New class
 * ISS-001993 03-07-2024 Lean - Updated muting of custom rollup
 * ISS-002017 18-07-2024 Sueanne - Update to delete "Discount Entry" together
 * ISS-002030 26-07-2024 Sueanne - Updated muting of delete discount trigger
 * ISS-002536 18-07-2025 XiRouh - Added 'Non-Transactional Entry' to the trnTypeList so that TRLs with this type will also be deleted
 */
public inherited sharing class TRO_DeleteLineItems_EXE extends REDU_TriggerExecutable {
    
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
                List<reduivy__Transaction_Line_Item__c> deleteList = new List<reduivy__Transaction_Line_Item__c>();
                List<String> trnTypeList = new List<String>{TRL_Helper.TRANSACTION_TYPE_ORDERLINE, TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY, TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY};
                
                //Get related transaction line item
                Map<String, Object> trlBindParams = new Map<String, Object>{
                    'trnOrderIds' => troOldMap.keySet(),
                    'trnTypeList' => trnTypeList
                };

                String trlQuery = 'SELECT Id, reduivy__Transaction_Order__c' +
                    ' FROM reduivy__Transaction_Line_Item__c' +
                    ' WHERE reduivy__Transaction_Order__c IN: trnOrderIds AND reduivy__Transaction_Type__c IN: trnTypeList';

                Map<String, Set<String>> trlObjectFieldsFls = new Map<String, Set<String>>();
                trlObjectFieldsFls.put(TRL_Helper.getApiName(), new Set<String>{'Id'});

                for (reduivy__Transaction_Line_Item__c trnLineItem : (List<reduivy__Transaction_Line_Item__c>) REDU_SystemMode_UTIL.doQuery(trlQuery, trlBindParams, trlObjectFieldsFls)) {

                    deleteList.add(trnLineItem);
                }
                
                if (!deleteList.isEmpty()) {

                    //We need to mute the rollup of total amount and total amount paid from transaction line to transaction order as it is not required during the DML since the order will be deleted too.
                    REDU_CustomRollupController.muteRollups(new Set<String>{'reduivy__Transaction_Line_Item__c>>reduivy__Transaction_Order__c'});

                    //mute delete discount trigger to avoid delete "discount entry" twice as deleteList contains all TRL in TRO
                    REDU_TriggerController.muteTriggers(new Set<String>{'TRL_DeleteDiscount_EXE'});

                    REDU_SystemMode_UTIL.doDelete(deleteList, troOldMap, 'reduivy__Transaction_Order__c', false);

                    REDU_TriggerController.unmuteTriggers(new Set<String>{'TRL_DeleteDiscount_EXE'});

                    REDU_CustomRollupController.unmuteRollups(new Set<String>{'reduivy__Transaction_Line_Item__c>>reduivy__Transaction_Order__c'});
                }
            }
        }
    }
}