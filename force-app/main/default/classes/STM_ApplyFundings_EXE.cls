/**
 * @author      WDCi (VTan)
 * @date        Feb 2024
 * @group       Finance
 * @description Trigger funding payment application for related transaction order when Apply Repayable/Non Repayable FA is checked (Academic Term).
 * @changehistory
 * ISS-001848 20-02-2024 VTan - New class
 * ISS-002179 06-12-2024 XW - Get the batch size from getApplyFABatchSize instead of getFaDisbursementBatchSize
 */
public inherited sharing class STM_ApplyFundings_EXE extends REDU_TriggerExecutable {
    
    @TestVisible private static boolean testQueueJob = false;

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

        if (operationType == TriggerOperation.AFTER_UPDATE && 
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            Id stAcademicTermRTID = STM_Helper.getAcademicTermRecordTypeId();
            Map<Id, reduivy__Study_Term__c> qualifiedStMap = new Map<Id, reduivy__Study_Term__c>();

            for (reduivy__Study_Term__c stNew : (List<reduivy__Study_Term__c>) newList) {
                reduivy__Study_Term__c stOld = (reduivy__Study_Term__c) oldMap.get(stNew.Id);

                if (stNew.RecordTypeId == stAcademicTermRTID &&
                    ((stNew.reduivy__Apply_Non_Repayable_FA__c && stNew.reduivy__Apply_Non_Repayable_FA__c != stOld.reduivy__Apply_Non_Repayable_FA__c) ||
                    (stNew.reduivy__Apply_Repayable_FA__c && stNew.reduivy__Apply_Repayable_FA__c != stOld.reduivy__Apply_Repayable_FA__c))) {

                        qualifiedStMap.put(stNew.Id, stNew);
                }
            }

            REDU_Logging_UTIL.debug('STM_FundingDisbursement_EXE', qualifiedStMap);

            if (!qualifiedStMap.isEmpty()) {
                updateTransactionOrder(qualifiedStMap);
            }
        }
    }

    /**
     * @description
     * @param
     * @return void
     */
    private void updateTransactionOrder(Map<Id, reduivy__Study_Term__c> qualifiedStMap) {

        Map<String, Object> toBindParams = new Map<String, Object>{
            'academicTermIds' => qualifiedStMap.keySet()
        };

        String toQuery = 'SELECT Id, reduivy__Apply_Non_Repayable_FA__c, reduivy__Apply_Repayable_FA__c,' +
            ' reduivy__Individual_Academic_Progress__r.reduivy__Academic_Term__r.reduivy__Apply_Non_Repayable_FA__c, reduivy__Individual_Academic_Progress__r.reduivy__Academic_Term__r.reduivy__Apply_Repayable_FA__c' +
            ' FROM reduivy__Transaction_Order__c ' +
            ' WHERE reduivy__Individual_Academic_Progress__r.reduivy__Academic_Term__c IN: academicTermIds';
        
        Map<Id, reduivy__Transaction_Order__c> transactionOrderMap = new Map<Id, reduivy__Transaction_Order__c>((List<reduivy__Transaction_Order__c>)Database.queryWithBinds(toQuery, toBindParams, AccessLevel.USER_MODE));

        if(!transactionOrderMap.isEmpty()){
            REDU_Logging_UTIL.debug('STM_FundingDisbursement_EXE', transactionOrderMap);

            if(System.isFuture() || System.isBatch() || System.isQueueable() || (Test.isRunningTest() && !testQueueJob )){
                STM_ApplyFundings_QUEUE queueJob = new STM_ApplyFundings_QUEUE(REDU_List_UTIL.getPageIterable(new List<Id>(transactionOrderMap.keySet()), REDU_AppSetting_UTIL.getApplyFABatchSize())); //ISS-002179
                queueJob.updateTransactionOrder(transactionOrderMap.values());

            }else{

                STM_ApplyFundings_QUEUE queueJob = new STM_ApplyFundings_QUEUE(REDU_List_UTIL.getPageIterable(new List<Id>(transactionOrderMap.keySet()), REDU_AppSetting_UTIL.getApplyFABatchSize())); //ISS-002179
                System.enqueueJob(queueJob);
            }
        }
    }
}