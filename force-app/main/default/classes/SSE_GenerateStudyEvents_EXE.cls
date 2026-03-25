/**
 * @author      WDCi (VTan)
 * @date        Jul 2024
 * @group       Trigger Executable
 * @description To handle study event creation/update when user has updated the study session status to 'Generate Study Events'
 * @changehistory
 * ISS-001922 02-07-2024 VTan - create new class
 */
public without sharing class SSE_GenerateStudyEvents_EXE extends REDU_TriggerExecutable{

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
            
            Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>();
            for(reduivy__Study_Session__c sse : (List<reduivy__Study_Session__c>) newList){

                reduivy__Study_Session__c sseOld = (reduivy__Study_Session__c) oldMap.get(sse.Id);
                if(sse.reduivy__Study_Event_Generation_Status__c == SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE && sse.reduivy__Study_Event_Generation_Status__c != sseOld.reduivy__Study_Event_Generation_Status__c){
                    sseMap.put(sse.Id, sse);
                }
            }

            if(!sseMap.isEmpty()){
                generateStudyEvents(sseMap);
            }
        }
    }

    /**
     * @description create/update study event when user has updated the study session status to 'Generate Study Events'
     * @param sseMap Map of Study Sessions
     * @return void
     */
    private void generateStudyEvents(Map<Id, reduivy__Study_Session__c> sseMap) {

        //Get the related session time based on session
        String sstQuery = 'SELECT Id, Name, reduivy__Study_Session__c,'+
        ' reduivy__Start_Date__c, reduivy__End_Date__c,'+
        ' reduivy__Start_Date_Calculated__c, reduivy__End_Date_Calculated__c,'+
        ' reduivy__Start_Time__c, reduivy__End_Time__c,' +
        ' reduivy__Recurrence__c, reduivy__Historical_Recurrence__c,'+
        ' reduivy__Day_of_Week__c, reduivy__Update_Action__c, reduivy__Change_Date__c,' +
        ' reduivy__Update_Settings__c, reduivy__Ignore_Holidays__c, reduivy__Timezone__c,' +
        ' reduivy__Study_Session__r.Name,' +
        ' reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__c, ' +
        ' reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__r.ParentId ' +
        ' FROM reduivy__Study_Session_Time__c' +
        ' WHERE reduivy__Study_Session__c IN : sessionTimeIds';

        Map<String, Object> sstBindParams = new Map<String, Object>{
            'sessionTimeIds' => sseMap.keySet()
        };

        Map<Id, List<reduivy__Study_Session_Time__c>> sseIdSessionTimeMap = new Map<Id, List<reduivy__Study_Session_Time__c>>();
        Map<Id, reduivy__Study_Session__c> sstStudySessionMap = new Map<Id, reduivy__Study_Session__c>(); // For error handling
        Map<Id, reduivy__Study_Session_Time__c> sstIdStudySessionTimeMap = new Map<Id, reduivy__Study_Session_Time__c>();
        Set<Id> accountIds = new Set<Id>();
        Date earliestStartDate = System.today();
        Date latestEndDate = System.today();
        for(reduivy__Study_Session_Time__c sst : (List<reduivy__Study_Session_Time__c>) Database.queryWithBinds(sstQuery, sstBindParams, AccessLevel.USER_MODE)){
            
            reduivy__Study_Session_Time__c sstToUpdate = new reduivy__Study_Session_Time__c();

            //Track earliest and latest dates, minimise the query result for holidays
            if (sst.reduivy__Start_Date_Calculated__c < earliestStartDate){
                earliestStartDate = sst.reduivy__Start_Date_Calculated__c;
            }
            if (sst.reduivy__End_Date_Calculated__c > latestEndDate){
                latestEndDate = sst.reduivy__End_Date_Calculated__c;
            }

            if (!sseIdSessionTimeMap.containsKey(sst.reduivy__Study_Session__c)) {
                sseIdSessionTimeMap.put(sst.reduivy__Study_Session__c, new List<reduivy__Study_Session_Time__c>());
            }
            sseIdSessionTimeMap.get(sst.reduivy__Study_Session__c).add(sst);

            sstIdStudySessionTimeMap.put(sst.Id, sst);

            //to query for holidays related to campus and educational institution
            if(String.isNotBlank(sst.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__c)){
                accountIds.add(sst.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__c);
            }
            if(String.isNotBlank(sst.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__r.ParentId)){
                accountIds.add(sst.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__r.ParentId);
            }
        }
        
        if(!sseIdSessionTimeMap.isEmpty()){

            List<reduivy__Study_Event__c> upsertStudyEventList = new List<reduivy__Study_Event__c>();
            List<reduivy__Study_Event__c> deleteStudyEventList = new List<reduivy__Study_Event__c>();

            //Get all related holidays
            String holidayQuery = 'SELECT Id, Name,'+
            ' reduivy__Educational_Institution_Campus__c,' + 
            ' reduivy__Educational_Institution_Campus__r.ParentId,' + 
            ' reduivy__Start_Date__c, reduivy__End_Date__c'+
            ' FROM reduivy__Holiday__c'+
            ' WHERE reduivy__Educational_Institution_Campus__c IN : accountIds' +
            ' AND reduivy__Start_Date__c <=: latestEndDate AND reduivy__End_Date__c >=: earliestStartDate';

            Map<String, Object> holidayBindParams = new Map<String, Object>{
                'accountIds' => accountIds,
                'earliestStartDate' => earliestStartDate,
                'latestEndDate' => latestEndDate
            };

            Map<Id, List<reduivy__Holiday__c>> accIdHolidayMap = new Map<Id, List<reduivy__Holiday__c>>();
            for(reduivy__Holiday__c holiday : (List<reduivy__Holiday__c>) Database.queryWithBinds(holidayQuery, holidayBindParams, AccessLevel.USER_MODE)){

                if (!accIdHolidayMap.containsKey(holiday.reduivy__Educational_Institution_Campus__c)) {
                    accIdHolidayMap.put(holiday.reduivy__Educational_Institution_Campus__c, new List<reduivy__Holiday__c>());
                }

                accIdHolidayMap.get(holiday.reduivy__Educational_Institution_Campus__c).add(holiday);
            }

            //Get all related study event
            Set<String> sevFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Study_Session_Time__c',
                'reduivy__ISO_Week__c',
                'reduivy__ISO_Year__c',
                'reduivy__Timezone__c',
                'reduivy__Start_Date_Non_TZ__c',
                'reduivy__Start_Time_Non_TZ__c',
                'reduivy__End_Date_Non_TZ__c',
                'reduivy__End_Time_Non_TZ__c'
            };

            String studyEventQuery = 'SELECT ' + String.join(sevFields, ', ') +
            ' FROM reduivy__Study_Event__c ' +
            ' WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c IN : sessionIds';

            Map<String, Object> studyEventBindParams = new Map<String, Object>{
                'sessionIds' => sseIdSessionTimeMap.keySet()
            };

            Map<String, Set<String>> sevObjectFieldsFls = new Map<String, Set<String>>();
            sevObjectFieldsFls.put(SEV_Helper.getApiName(), sevFields);

            Map<Id, List<reduivy__Study_Event__c>> sstIdStudyEventMap = new Map<Id, List<reduivy__Study_Event__c>>();
            for(reduivy__Study_Event__c sev : (List<reduivy__Study_Event__c>) REDU_SystemMode_UTIL.doQuery(studyEventQuery, studyEventBindParams, sevObjectFieldsFls)){

                if (!sstIdStudyEventMap.containsKey(sev.reduivy__Study_Session_Time__c)) {
                    sstIdStudyEventMap.put(sev.reduivy__Study_Session_Time__c, new List<reduivy__Study_Event__c>());
                }

                if(sstIdStudySessionTimeMap.get(sev.reduivy__Study_Session_Time__c).reduivy__Update_Action__c == SST_Helper.UPDATE_ACTION_RECREATE){
                    deleteStudyEventList.add(sev);
                }else{
                    sstIdStudyEventMap.get(sev.reduivy__Study_Session_Time__c).add(sev);
                }
                
            }

            // Creation/update of study event start
            for(Id sseId : sseIdSessionTimeMap.keySet()){

                for(reduivy__Study_Session_Time__c sst : sseIdSessionTimeMap.get(sseId)){

                    SSE_Helper.StudyEventInfo sevInfo;
                    List<reduivy__Study_Event__c> existingStudyEvents = new List<reduivy__Study_Event__c>();
                    if (sstIdStudyEventMap.containsKey(sst.Id)){
                        existingStudyEvents = sstIdStudyEventMap.get(sst.Id);
                    }

                    if (sst.reduivy__Recurrence__c == SST_Helper.RECURRENCE_WEEKLY){
                        sevInfo = SSE_Helper.generateStudyEvents(sst, 7, existingStudyEvents, accIdHolidayMap);
                    }else if(sst.reduivy__Recurrence__c == SST_Helper.RECURRENCE_BIWEEKLY){
                        sevInfo = SSE_Helper.generateStudyEvents(sst, 14, existingStudyEvents, accIdHolidayMap);
                    }else if(sst.reduivy__Recurrence__c == SST_Helper.RECURRENCE_DAILY){
                        sevInfo = SSE_Helper.generateStudyEvents(sst, 1, existingStudyEvents, accIdHolidayMap);
                    }else if(sst.reduivy__Recurrence__c == SST_Helper.RECURRENCE_ONEOFF){
                        sevInfo = SSE_Helper.generateStudyEvents(sst, 0, existingStudyEvents, accIdHolidayMap);
                    }

                    if (!sevInfo.studyEventsToUpsert.isEmpty()){
                        upsertStudyEventList.addAll(sevInfo.studyEventsToUpsert);
                    }
                    
                    if (!sevInfo.studyEventsToDelete.isEmpty()){
                        deleteStudyEventList.addAll(sevInfo.studyEventsToDelete);
                    }
                }
            }

            if(!upsertStudyEventList.isEmpty()){
                REDU_Database_UTIL.doUpsert(upsertStudyEventList, sstStudySessionMap, 'reduivy__Study_Session_Time__c', false);
            }

            if(!deleteStudyEventList.isEmpty()){
                REDU_SystemMode_UTIL.doDelete(deleteStudyEventList, sstStudySessionMap, 'reduivy__Study_Session_Time__c', false);
            }
        }

        //Update Study Session Status to Generated
        for (reduivy__Study_Session__c sse : sseMap.values()){
            sse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATED;
        }
    }
}