/**
 * @author      WDCi (Sueanne)
 * @date        Aug 2024
 * @group       Trigger executable
 * @description When individual session enrollment is deleted, the associated study event relation should be delete too
 * @changehistory
 * ISS-002052 21-08-2024 Sueanne - new class
 */
public without sharing class ISN_DeleteStudyEventRelations_EXE extends REDU_TriggerExecutable {
    
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)){

            Map<Id, reduivy__Individual_Session_Enrollment__c> isnOldMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>((List<reduivy__Individual_Session_Enrollment__c>) oldList);
            
            if (!isnOldMap.isEmpty()) {
                Set<String> serFields = new Set<String>{
                    'Id'
                };

                Map<String, Object> serBindParams = new Map<String, Object>();
                serBindParams.put('isnIds', isnOldMap.keySet());

                String serQuery = 'SELECT ' + String.join(serFields, ', ') +
                    ' FROM reduivy__Study_Event_Relation__c ' +
                    ' WHERE reduivy__Individual_Session_Enrollment__c IN: isnIds';

                Map<String, Set<String>> serObjectFieldsFls = new Map<String, Set<String>>();
                serObjectFieldsFls.put(SER_Helper.getApiName(), serFields);

                //get associated study event relations
                List<reduivy__Study_Event_Relation__c> serToDelete = new List<reduivy__Study_Event_Relation__c>();
                    
                for(reduivy__Study_Event_Relation__c ser : (List<reduivy__Study_Event_Relation__c>) REDU_SystemMode_UTIL.doQuery(serQuery, serBindParams, serObjectFieldsFls)){
                    serToDelete.add(ser);
                }

                if(!serToDelete.isEmpty()){
                    //Delete records regardless of ownership using system mode
                    REDU_SystemMode_UTIL.doDelete(serToDelete, isnOldMap, 'reduivy__Individual_Session_Enrollment__c', false);
                }
            }
        }
    }

}