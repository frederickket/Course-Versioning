/**
 * @author      WDCi (VTan)
 * @date        Aug 2024
 * @group       Finance
 * @description Trigger to update all related individual academic progress to generate transaction order.
 * @changehistory
 * ISS-002025 16-08-2024 VTan - New class
 */
public inherited sharing class STM_GenerateOrders_EXE extends REDU_TriggerExecutable {
    
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
                    (stNew.reduivy__Generate_Transaction_Orders__c && stNew.reduivy__Generate_Transaction_Orders__c != stOld.reduivy__Generate_Transaction_Orders__c)) {

                        qualifiedStMap.put(stNew.Id, stNew);
                }
            }

            REDU_Logging_UTIL.debug('STM_GenerateOrders_EXE', qualifiedStMap);
            updateIprGenerateOrders(qualifiedStMap);
        }
    }

    /**
     * @description
     * @param
     * @return void
     */
    private void updateIprGenerateOrders(Map<Id, reduivy__Study_Term__c> qualifiedStMap) {

        Map<String, Object> iprBindParams = new Map<String, Object>{
            'academicTermIds' => qualifiedStMap.keySet()
        };

        String iprQuery = 'SELECT Id, reduivy__Generate_Transaction_Orders__c, reduivy__Order_Generation_Action__c' +
            ' FROM reduivy__Individual_Academic_Progress__c ' +
            ' WHERE reduivy__Academic_Term__c IN: academicTermIds' +
            ' AND reduivy__Generate_Transaction_Orders__c = false';
        
        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>((List<reduivy__Individual_Academic_Progress__c>)Database.queryWithBinds(iprQuery, iprBindParams, AccessLevel.USER_MODE));

        if(!iprMap.isEmpty()){
            REDU_Logging_UTIL.debug('STM_GenerateOrders_EXE', iprMap);

            if(System.isFuture() || System.isBatch() || System.isQueueable() || (Test.isRunningTest() && !testQueueJob )){
                STM_GenerateOrders_QUEUE queueJob = new STM_GenerateOrders_QUEUE(REDU_List_UTIL.getPageIterable(new List<Id>(iprMap.keySet()), REDU_AppSetting_UTIL.getGenerateOrdersBatchSize()));
                queueJob.updateIdvAcademicProgress(iprMap.values());

            }else{

                STM_GenerateOrders_QUEUE queueJob = new STM_GenerateOrders_QUEUE(REDU_List_UTIL.getPageIterable(new List<Id>(iprMap.keySet()), REDU_AppSetting_UTIL.getGenerateOrdersBatchSize()));
                System.enqueueJob(queueJob);
            }
        }
    }
}