/**
 * @author      WDCi (XW)
 * @date        June 2024
 * @group       Study Session Scheduler
 * @description Controller for StudySessionSchedulerAssignFacilityModal lwc
 * @changehistory
 * ISS-1920 03-07-2024 XW - create new class
 */
public with sharing class REDU_SessionFacilityAssignment_LCTRL {
    
    static String ACTION_UPDATE_UNALLOCATED = 'UPDATE_UNALLOCATED';
    static String ACTION_ADD_INTO_ALL = 'ADD_INTO_ALL';
    static String ACTION_REPLACE_ALL = 'REPLACE_ALL';

    /**
     * @description Update the facility
     * @param  studySessionTimeIds The study session times selected
     * @param  actionType     The action to perform
     * @param  facilityId     The facility id to change
     * @return                REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse updateAssignFacility(List<String> studySessionTimeIds, String actionType, String facilityId){
        Savepoint sp = Database.setSavePoint();
        
        try{
            Set<Id> idToNofity = new Set<Id>();
            List<reduivy__Study_Event_Relation__c> serToInsert = new List<reduivy__Study_Event_Relation__c>();

            if(!studySessionTimeIds.isEmpty() && String.isNotBlank(actionType) && String.isNotBlank(facilityId)){

                List<reduivy__Study_Event__c> allSevList = new List<reduivy__Study_Event__c>();

                for(reduivy__Study_Event__c sev :  [    
                    SELECT Id, Name,
                    reduivy__Study_Session_Time__c, reduivy__Study_Session_Time__r.Name,
                    reduivy__Study_Session_Time__r.reduivy__Study_Session__c, reduivy__Study_Session_Time__r.reduivy__Study_Session__r.Name, (
                        SELECT Id, Name, reduivy__Facility__c
                        FROM reduivy__Study_Event_Relations__r
                        WHERE reduivy__Relation_Type__c = :SER_Helper.RELATION_TYPE_FACILITY
                    )
                    FROM reduivy__Study_Event__c
                    WHERE reduivy__Study_Session_Time__c IN :studySessionTimeIds
                    WITH USER_MODE
                ]) {
                    allSevList.add(sev);
                }

                REDU_Logging_UTIL.debug('allSevList', allSevList);

                if(!allSevList.isEmpty()){
                    List<reduivy__Study_Event__c> unallocatedSevList = new List<reduivy__Study_Event__c>();
                    List<reduivy__Study_Event_Relation__c> allSerList = new List<reduivy__Study_Event_Relation__c>();
                    Map<Id, reduivy__Study_Event__c> unduplicatedSevMap = new Map<Id, reduivy__Study_Event__c>(allSevList);
                    Boolean isAllocated = false;
                    List<reduivy__Study_Event_Relation__c> serToDeleteList = new List<reduivy__Study_Event_Relation__c>();

                    for(reduivy__Study_Event__c sev : allSevList) {
                        isAllocated = false;

                        for(reduivy__Study_Event_Relation__c ser : sev.reduivy__Study_Event_Relations__r){
                            isAllocated = true;
                            if(ser.reduivy__Facility__c == facilityId) {
                                unduplicatedSevMap.remove(sev.Id);
                            }

                            allSerList.add(ser);
                        }

                        if(!isAllocated) {
                            unallocatedSevList.add(sev);
                        }
                    }

                    Set<Id> unduplicatedSevIds = unduplicatedSevMap.keySet();
                    if(actionType == ACTION_UPDATE_UNALLOCATED) {
                        for(reduivy__Study_Event__c unallocatedSev : unallocatedSevList) {

                            reduivy__Study_Event_Relation__c newSer = new reduivy__Study_Event_Relation__c(
                                reduivy__Response_Status__c = SER_Helper.RESPONSE_STATUS_ACCEPTED,
                                reduivy__Facility__c = facilityId,
                                reduivy__Study_Event__c = unallocatedSev.Id
                            );

                            idToNofity.add(unallocatedSev.Id);
                            serToInsert.add(newSer);
                        }

                    } else if(actionType == ACTION_ADD_INTO_ALL) {
                        for(Id unduplicatedSevId : unduplicatedSevIds){
                            reduivy__Study_Event_Relation__c newSer = new reduivy__Study_Event_Relation__c(
                                reduivy__Response_Status__c = SER_Helper.RESPONSE_STATUS_ACCEPTED,
                                reduivy__Facility__c = facilityId,
                                reduivy__Study_Event__c = unduplicatedSevId
                            );

                            idToNofity.add(unduplicatedSevId);
                            serToInsert.add(newSer);
                        }

                    } else if(actionType == ACTION_REPLACE_ALL) {
                        
                        if(!allSerList.isEmpty()){
                            //Delete records regardless of ownership using system mode
                            REDU_SystemMode_UTIL.doDelete(allSerList);
                        }

                        for(reduivy__Study_Event__c sev : allSevList){   
                            reduivy__Study_Event_Relation__c newSer = new reduivy__Study_Event_Relation__c(
                                reduivy__Response_Status__c = SER_Helper.RESPONSE_STATUS_ACCEPTED,
                                reduivy__Facility__c = facilityId,
                                reduivy__Study_Event__c = sev.Id
                            );

                            idToNofity.add(sev.Id);
                            serToInsert.add(newSer);
                        }

                    }

                    if(!serToInsert.isEmpty()){
                        REDU_Logging_UTIL.debug('serToInsert', serToInsert);
                        REDU_Database_UTIL.doInsert(serToInsert);
                    }
                }
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(idToNofity));
            
        } catch (QueryException qex) {
            Database.rollback(sp);
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            Database.rollback(sp);
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
    
}