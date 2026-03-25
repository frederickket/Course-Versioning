/**
 * @author      WDCi (VTan)
 * @date        Jul 2024
 * @group       Trigger Executable
 * @description To update start and end date of study event based on the timezone configured.
 * @changehistory
 * ISS-001922 04-07-2024 VTan - create new class
 */
public inherited sharing class SEV_SetEventDateTime_EXE extends REDU_TriggerExecutable{

    /**
     * @description BeforeInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
    
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            String userTimezone = UserInfo.getTimeZone().getID();
            for(reduivy__Study_Event__c sev : (List<reduivy__Study_Event__c>) newList){

                DateTime startDt = Datetime.newInstance(sev.reduivy__Start_Date_Non_TZ__c, sev.reduivy__Start_Time_Non_TZ__c);
                DateTime endDt = Datetime.newInstance(sev.reduivy__End_Date_Non_TZ__c, sev.reduivy__End_Time_Non_TZ__c);

                if (String.isBlank(sev.reduivy__Timezone__c) || sev.reduivy__Timezone__c == userTimezone){
                    sev.reduivy__Start__c = startDt;
                    sev.reduivy__End__c = endDt;
                } else {
                    //Need to convert back to user time to get the right date time
                    sev.reduivy__Start__c = REDU_Date_UTIL.convertDateTime(startDt, userTimezone, sev.reduivy__Timezone__c);
                    sev.reduivy__End__c = REDU_Date_UTIL.convertDateTime(endDt, userTimezone, sev.reduivy__Timezone__c);
                }
            }
        }
    }

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
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            
            String userTimezone = UserInfo.getTimeZone().getID();
            for (reduivy__Study_Event__c sevNew : (List<reduivy__Study_Event__c>) newList) {

                reduivy__Study_Event__c sevOld = (reduivy__Study_Event__c) oldMap.get(sevNew.Id);
                if(sevNew.reduivy__Start_Date_Non_TZ__c != sevOld.reduivy__Start_Date_Non_TZ__c ||
                    sevNew.reduivy__Start_Time_Non_TZ__c != sevOld.reduivy__Start_Time_Non_TZ__c ||
                    sevNew.reduivy__End_Date_Non_TZ__c != sevOld.reduivy__End_Date_Non_TZ__c ||
                    sevNew.reduivy__End_Time_Non_TZ__c != sevOld.reduivy__End_Time_Non_TZ__c ||
                    sevNew.reduivy__Start__c == null || sevNew.reduivy__End__c == null){

                    DateTime startDt = Datetime.newInstance(sevNew.reduivy__Start_Date_Non_TZ__c, sevNew.reduivy__Start_Time_Non_TZ__c);
                    DateTime endDt = Datetime.newInstance(sevNew.reduivy__End_Date_Non_TZ__c, sevNew.reduivy__End_Time_Non_TZ__c);

                    if (String.isBlank(sevNew.reduivy__Timezone__c) || sevNew.reduivy__Timezone__c == userTimezone){
                        sevNew.reduivy__Start__c = startDt;
                        sevNew.reduivy__End__c = endDt;
                    } else {
                        //Need to convert back to user time to get the right date time
                        sevNew.reduivy__Start__c = REDU_Date_UTIL.convertDateTime(startDt, userTimezone, sevNew.reduivy__Timezone__c);
                        sevNew.reduivy__End__c = REDU_Date_UTIL.convertDateTime(endDt, userTimezone, sevNew.reduivy__Timezone__c);
                    }
                }
            }
        }
    }
}