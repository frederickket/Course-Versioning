/**
 * @author      WDCi (XW)
 * @date        Jan 2024
 * @group       Trigger Executable
 * @description To delete the related study events relations before study event is deleted
 * @changehistory
 * ISS-001976 13-06-2024 XW - create new class
 */
public without sharing class SEV_DeleteStudyEventRelations_EXE extends REDU_TriggerExecutable{
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
                deleteStudyEventRelations((List<reduivy__Study_Event__c>)oldList);
            }
        }
    }

    /**
     * @description Delete study event relation when study event is deleted
     * @param  sevList the study events that will be determine which study event relations to be deleted
     */ 
    private void deleteStudyEventRelations(List<reduivy__Study_Event__c> sevList) {
        Map<String, Object> serBindParams = new Map<String, Object>();
        serBindParams.put('sevList', sevList);

        String serSoql = 'SELECT Id, ' +
            ' Name ' +
            ' FROM reduivy__Study_Event_Relation__c ' +
            ' WHERE reduivy__Study_Event__c IN: sevList';
        
        Map<String, Set<String>> serObjectFieldsFls = new Map<String, Set<String>>();
        serObjectFieldsFls.put(SER_Helper.getApiName(), new Set<String>{'Id'});

        List<reduivy__Study_Event_Relation__c> relationsToDelete = new List<reduivy__Study_Event_Relation__c>();
        for(reduivy__Study_Event_Relation__c sev : (List<reduivy__Study_Event_Relation__c>) REDU_SystemMode_UTIL.doQuery(serSoql, serBindParams, serObjectFieldsFls)){
            relationsToDelete.add(sev);
        }

        if (!relationsToDelete.isEmpty()){
            //Delete records regardless of ownership using system mode
            REDU_SystemMode_Util.doDelete(relationsToDelete);
        }
    }
}