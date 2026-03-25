/**
 * @author      WDCi (Lean)
 * @date        July 2025
 * @group       Job Queue Framework
 * @description To delete the related log when a job queue is deleted
 * @changehistory
 * ISS-002547 10-07-2025 Lean - new trigger
 */
public inherited sharing class JQH_DeleteRelatedRecords_EXE extends REDU_TriggerExecutable {
    
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

            //delete logs
            Set<String> logFields = new Set<String>{
                'Id',
                'reduivy__Job_Queue__c'
            };

            Map<String, Set<String>> logFls = new Map<String, Set<String>>{
                LOG_Helper.getApiName() => logFields
            };

            Map<String, Object> logBindParams = new Map<String, Object>();
            logBindParams.put('jqhIds', oldMap.keySet());

            String logSoql = 'SELECT ' + String.join(logFields, ', ') +
                ' FROM reduivy__Log__c ' +
                ' WHERE reduivy__Job_Queue__c IN: jqhIds ';
            
            List<reduivy__Log__c> logList = new List<reduivy__Log__c>();
            for (reduivy__Log__c log : (List<reduivy__Log__c>) REDU_SystemMode_UTIL.doQuery(logSoql, logBindParams, logFls)) {
                logList.add(log);
            }

            if (!logList.isEmpty()) {
                REDU_TriggerController.muteTriggers(new Set<String>{'reduivy__Log__c'});

                REDU_SystemMode_UTIL.doDelete(logList, oldMap, 'reduivy__Job_Queue__c', false);

                REDU_TriggerController.unmuteTriggers(new Set<String>{'reduivy__Log__c'});
            }
        }
    }
	
}