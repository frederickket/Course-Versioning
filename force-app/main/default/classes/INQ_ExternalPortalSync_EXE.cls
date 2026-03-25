/**
 * @author      WDCi (Xirouh)
 * @date        June 2024
 * @group       
 * @description trigger for integration queue after inq insert and after inq update
 * @changehistory
 * ISS-001978 24-06-2024 Xirouh - new class
 */
public inherited sharing class INQ_ExternalPortalSync_EXE extends REDU_TriggerExecutable {

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

        //TODO change the permission
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER) ||
        REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.GUEST)
        ) {
            Map<Id, reduivy__Integration_Queue__c> inqMap = new Map<Id, reduivy__Integration_Queue__c>();
            Map<String, String> objectAndActionTypes = new Map<String, String>();

            for (reduivy__Integration_Queue__c inqNew : (List<reduivy__Integration_Queue__c>) newList) {
                if (inqNew.reduivy__Status__c == INQ_Helper.STATUS_TYPE_READY_TO_SYNC) {
                    inqMap.put(inqNew.Id, inqNew);
                    objectAndActionTypes.put(inqNew.reduivy__Object_Type__c, inqNew.reduivy__Action_Type__c);
                }
            }
            
            if (objectAndActionTypes.size() == 1) {
                syncCalloutQueue(inqMap);
            } else {                
                for (reduivy__Integration_Queue__c inq : inqMap.values()) {
                    inq.reduivy__Object_Type__c.addError(Label.Mixture_Of_Object_And_Operation_Type_Error);
                }
            }
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER) ||
        REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.GUEST)
        ) {
            Map<Id, reduivy__Integration_Queue__c> inqMap = new Map<Id, reduivy__Integration_Queue__c>();
            Map<String, String> objectAndActionTypes = new Map<String, String>();

            for (reduivy__Integration_Queue__c inqNew : (List<reduivy__Integration_Queue__c>) newList) {
                if (inqNew.reduivy__Status__c == INQ_Helper.STATUS_TYPE_READY_TO_SYNC) {
                    inqMap.put(inqNew.Id, inqNew);
                    objectAndActionTypes.put(inqNew.reduivy__Object_Type__c, inqNew.reduivy__Action_Type__c);
                }
            }
            
            if (objectAndActionTypes.size() == 1) {
                syncCalloutQueue(inqMap);
            } else {
                for (reduivy__Integration_Queue__c inq : inqMap.values()) {
                    inq.reduivy__Object_Type__c.addError(Label.Mixture_Of_Object_And_Operation_Type_Error);
                }
            }
        }
    }
	
    /**
     * @description
     * @param inqMap
     * @return void
     */
    private void syncCalloutQueue(Map<Id, reduivy__Integration_Queue__c> inqMap) {
        if(!inqMap.isEmpty()){
            if(System.isFuture() || System.isBatch() || System.isQueueable()){
                INQ_ExternalPortalSync_QUEUE queueJob = new INQ_ExternalPortalSync_QUEUE(REDU_List_UTIL.getPageIterable(new List<Id>(inqMap.keySet()), REDU_AppSetting_UTIL.getIntegrationQueueBatchSize()));
                queueJob.executeCalloutSync(inqMap.values());

            }else{
                INQ_ExternalPortalSync_QUEUE queueJob = new INQ_ExternalPortalSync_QUEUE(REDU_List_UTIL.getPageIterable(new List<Id>(inqMap.keySet()), REDU_AppSetting_UTIL.getIntegrationQueueBatchSize()));
                System.enqueueJob(queueJob);
            }
        }
    }
}