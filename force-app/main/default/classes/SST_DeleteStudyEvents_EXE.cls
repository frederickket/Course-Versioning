/**
 * @author      WDCi (XW)
 * @date        June 2024
 * @group       Trigger Executable
 * @description To delete the related study events before study session time is deleted
 * @changehistory
 * ISS-001976 13-06-2024 XW - create new class
 */
public without sharing class SST_DeleteStudyEvents_EXE extends REDU_TriggerExecutable{
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

            if (!oldList.isEmpty()){
                deleteStudyEvents((List<reduivy__Study_Session_Time__c>) oldList);
            }
        }
    }

    /**
     * @description Delete study event when study session time is deleted
     * @param sstList the Study Session Time that will be determine which study events to be deleted
     */
    private void deleteStudyEvents(List<reduivy__Study_Session_Time__c> sstList){

        Map<String, Object> sevBindParams = new Map<String, Object>();
        sevBindParams.put('sstList', sstList);

        String sevSoql = 'SELECT Id ' +
            ' FROM reduivy__Study_Event__c ' +
            ' WHERE reduivy__Study_Session_Time__c IN: sstList';

        Map<String, Set<String>> sevObjectFieldsFls = new Map<String, Set<String>>();
        sevObjectFieldsFls.put(SEV_Helper.getApiName(), new Set<String>{'Id'});

        List<reduivy__Study_Event__c> eventsToDelete = new List<reduivy__Study_Event__c>();
        for(reduivy__Study_Event__c sev : (List<reduivy__Study_Event__c>) REDU_SystemMode_UTIL.doQuery(sevSoql, sevBindParams, sevObjectFieldsFls)){
            eventsToDelete.add(sev);
        }

        if (!eventsToDelete.isEmpty()){
            //Delete records regardless of ownership using system mode
            REDU_SystemMode_Util.doDelete(eventsToDelete);
        }
    }

}