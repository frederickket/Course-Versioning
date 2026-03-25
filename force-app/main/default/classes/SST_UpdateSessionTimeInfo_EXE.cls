/**
 * @author      WDCi (VTan)
 * @date        Jul 2024
 * @group       Trigger Executable
 * @description To handle study event creation/update when user has updated the study session status to 'Generate Study Events'
 * @changehistory
 * ISS-001922 02-07-2024 VTan - create new class
 */
public inherited sharing class SST_UpdateSessionTimeInfo_EXE extends REDU_TriggerExecutable{

    /**
     * @description BeforeUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult){

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {
            
            Map<Id, List<reduivy__Study_Session_Time__c>> sseIdSstMap = new Map<Id, List<reduivy__Study_Session_Time__c>>();
            for(reduivy__Study_Session_Time__c sst : (List<reduivy__Study_Session_Time__c>) newList){

                //Set study session time action to Recreate if Recurrence has changed or Bi-weekly
                if((String.isNotBlank(sst.reduivy__Historical_Recurrence__c) && sst.reduivy__Recurrence__c != sst.reduivy__Historical_Recurrence__c) ||
                    sst.reduivy__Recurrence__c == SST_Helper.RECURRENCE_BIWEEKLY){

                    sst.reduivy__Update_Action__c = SST_Helper.UPDATE_ACTION_RECREATE;
                    sst.reduivy__Historical_Recurrence__c = sst.reduivy__Recurrence__c;

                }else if(String.isBlank(sst.reduivy__Historical_Recurrence__c)){
                    sst.reduivy__Historical_Recurrence__c = sst.reduivy__Recurrence__c;
                }
            }
        }
    }
}