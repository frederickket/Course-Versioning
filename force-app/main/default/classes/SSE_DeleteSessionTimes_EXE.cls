/**
 * @author      WDCi (XW)
 * @date        Jan 2024
 * @group       Trigger Executable
 * @description To delete the related study session times before study session is deleted
 * @changehistory
 * ISS-001976 14-06-2024 XW - create new class
 */
public without sharing class SSE_DeleteSessionTimes_EXE extends REDU_TriggerExecutable{
    /**
     * @description BeforeDelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult){

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            if (!oldList.isEmpty()) {
                List<reduivy__Study_Session__c> workingList = (List<reduivy__Study_Session__c>)oldList;
                deleteSessionTimes(workingList);
            }
        }
    }

    /**
     * @description Delete study sessions time when study sessions is deleted
     * @param  sseList The study sessions that will be determine which study session times to be deleted
     */ 
    private void deleteSessionTimes(List<reduivy__Study_Session__c> sseList) {
        List<reduivy__Study_Session_Time__c> sstToDelete = new List<reduivy__Study_Session_Time__c>();
        for(reduivy__Study_Session_Time__c sst : [SELECT Id, 
            Name
            FROM reduivy__Study_Session_Time__c
            WHERE reduivy__Study_Session__c IN: sseList
            WITH USER_MODE //this is ok to run using user_mode as the relationship is master-detail
        ]){
            sstToDelete.add(sst);
        }

        if (!sstToDelete.isEmpty()){
            //Delete records regardless of ownership using system mode
            REDU_SystemMode_Util.doDelete(sstToDelete);
        }
    }

}