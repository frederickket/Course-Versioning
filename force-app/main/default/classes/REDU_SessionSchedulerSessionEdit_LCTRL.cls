/**
 * @author      WDCi (XW)
 * @date        July 2024
 * @group       
 * @description 
 * @changehistory
 * ISS-001920 18-07-2024 XW - create new class
 */
public with sharing class REDU_SessionSchedulerSessionEdit_LCTRL {
    private static String NEW_SST_PREFIX = 'newsst_';

    /**
     * @description Get field set members
     * @param fieldSetName Field set api name
     * @param objectName Object api name
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getFields(String fieldSetName, String objectName){
        try {
            
            List<REDU_DynamicFieldValue_OBJ> fields = REDU_Metadata_UTIL.getFieldSetMembers(objectName, fieldsetName);
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(fields));

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    
    /**
     * @description Upsert sessions and sessionTimes.
     * @param sessionsWithSessionTimesString A list of sessions with/without sessionTimes.
     * @param sstIdsToDelete A list of study session time ids to be deleted
     * @return REDU_LightningResponse
     */ 
    @AuraEnabled
    public static REDU_LightningResponse upsertSessionsAndSessionTimes(String sessionsWithSessionTimesString, List<String> sstIdsToDelete){
        Savepoint sp = Database.setSavepoint();

        try {
            List<reduivy__Study_Session_Time__c> sstToUpsert = new List<reduivy__Study_Session_Time__c>();
            List<reduivy__Study_Session__c> sseList = (List<reduivy__Study_Session__c>)  JSON.deserialize(sessionsWithSessionTimesString, List<reduivy__Study_Session__c>.class);
            List<Id> sseIdList = new List<Id>();
            REDU_Logging_UTIL.debug('sseList', sseList);

            if(!sseList.isEmpty()) {

                REDU_Database_UTIL.doUpsert(sseList);
                
                for(reduivy__Study_Session__c sse : sseList) {
                    sseIdList.add(sse.Id);

                    for(reduivy__Study_Session_Time__c sst : sse.reduivy__Study_Session_Times__r) {
                        if(String.valueOf(sst.Id).startsWith(NEW_SST_PREFIX)){
                            sst.Id = null;
                        }

                        if(sst.reduivy__Study_Session__c == null) {
                            sst.reduivy__Study_Session__c = sse.Id;
                        }

                        sstToUpsert.add(sst);
                    }
                }
            }

            if(!sstToUpsert.isEmpty()) {
                REDU_Database_UTIL.doUpsert(sstToUpsert);
            }

            //delete
            Set<String> idsToNotifyUpdate = new Set<String>();
            if(sstIdsToDelete != null && !sstIdsToDelete.isEmpty()) {
                List<reduivy__Study_Session_Time__c> sstToDeleteList = new List<reduivy__Study_Session_Time__c>();
                for(String id : sstIdsToDelete){
                    sstToDeleteList.add(new reduivy__Study_Session_Time__c(Id = id));
                }

                REDU_SystemMode_UTIL.doDelete(sstToDeleteList);
                idsToNotifyUpdate.addAll(sstIdsToDelete);
            }

            for(reduivy__Study_Session__c session: sseList){
                idsToNotifyUpdate.add(session.Id);
            }

            for (reduivy__Study_Session_Time__c sst: sstToUpsert) {
                idsToNotifyUpdate.add(sst.Id);
            }

            Map<String, Object> responseData = new Map<String, Object>{
                'idsToNotifyUpdate' => idsToNotifyUpdate,
                'sseIdList' => sseIdList
            };
          
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));

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

    @AuraEnabled
    public static REDU_LightningResponse generateStudyEvent(List<String> studySessionIds) {
        Savepoint sp = Database.setSavepoint();

        try{
            if(!studySessionIds.isEmpty()){
                List<reduivy__Study_Session__c> sseList = new List<reduivy__Study_Session__c>();
                for(String sseId: studySessionIds){
                    sseList.add(new reduivy__Study_Session__c(
                        Id = sseId,
                        reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE
                    ));
                }

                REDU_Database_UTIL.doUpdate(sseList);
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(studySessionIds));
        }
        catch (QueryException qex) {
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