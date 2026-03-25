/**
 * @author      WDCi (Lean)
 * @date        Jun 2024
 * @group       Study Session Scheduler
 * @description Study session scheduler session component
 * @changehistory
 * ISS-001920 12-06-2024 Lean - new class
 * ISS-002661 09-10-2025 XW - consider study event from diff timezone by querying study event from previous day and next day
 */
public with sharing class REDU_SessionSchedulerSession_LCTRL {
    
    /**
     * @description Delete study session
     * @param studySessionId Study session Id
     * @return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse deleteStudySession(String studySessionId){
        Savepoint sp = Database.setSavepoint();

        try {
            
            if(String.isNotBlank(studySessionId)){

                reduivy__Study_Session__c sess = new reduivy__Study_Session__c(Id = studySessionId);

                //User needs to be able to delete regardless of ownership
                REDU_SystemMode_UTIL.doDelete(new List<reduivy__Study_Session__c>{sess});
                
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(studySessionId));

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

    /**
     * @description Get double booking data
     * @param  studySessionId The study session id
     * @return                REDU_LightningResponse
     */
    @AuraEnabled(cacheable = true)
    public static REDU_LightningResponse checkDoubleBooking(String studySessionId){

        try {

            if(String.isNotBlank(studySessionId)){

                Set<Id> facultyId = new Set<Id>();
                Set<Id> facilityId = new Set<Id>();
                Set<Date> dateList = new Set<Date>();
                List<reduivy__Study_Event_Relation__c> facultySessionSer = new List<reduivy__Study_Event_Relation__c>();
                List<reduivy__Study_Event_Relation__c> facilitySessionSer = new List<reduivy__Study_Event_Relation__c>();
                
                List<String> validRelationType = new List<String> {SER_Helper.RELATION_TYPE_FACILITY, SER_Helper.RELATION_TYPE_FACULTY};
                for(reduivy__Study_Event_Relation__c ser : [
                    SELECT Id,
                    Name,
                    reduivy__Study_Event__r.reduivy__Start_Date_Non_TZ__c,
                    reduivy__Event_Start_Datetime__c,
                    reduivy__Event_End_Datetime__c,
                    reduivy__Contact__c,
                    reduivy__Contact__r.Name,
                    reduivy__Facility__c,
                    reduivy__Facility__r.Name
                    FROM reduivy__Study_Event_Relation__c
                    WHERE reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :studySessionId
                    AND reduivy__Relation_Type__c IN :validRelationType
                    WITH USER_MODE
                    ORDER BY reduivy__Event_Start_Datetime__c 
                ]){
                    Date serDate = ser.reduivy__Study_Event__r.reduivy__Start_Date_Non_TZ__c;
                    dateList.add(serDate);
                    //there might be case that the conflicted event is from different time zone and from different date, we need to include them as well
                    dateList.add(serDate.addDays(1));
                    dateList.add(serDate.addDays(-1));

                    if(String.isNotBlank(ser.reduivy__Contact__c)){
                        facultySessionSer.add(ser);
                        facultyId.add(ser.reduivy__Contact__c);
                    }

                    if(String.isNotBlank(ser.reduivy__Facility__c)){
                        facilitySessionSer.add(ser);
                        facilityId.add(ser.reduivy__Facility__c);
                    }
                }

                List<reduivy__Study_Event_Relation__c> facultyConflictedSer = new List<reduivy__Study_Event_Relation__c>();
                List<reduivy__Study_Event_Relation__c> facilityConflictedSer = new List<reduivy__Study_Event_Relation__c>();
                if(!facultyId.isEmpty() || !facilityId.isEmpty()){
                    //get conflicted ser
                    //To prevent querying in a for loop, each ser with the same date and same resource id is retrieved
                    //and will be filtered independently in js side
                    //Map<resourceId, List<Ser>>
                    for(reduivy__Study_Event_Relation__c ser : [
                        SELECT Id, Name,
                        reduivy__Study_Event__r.reduivy__Start_Date_Non_TZ__c,
                        reduivy__Event_Start_Datetime__c,
                        reduivy__Event_End_Datetime__c,
                        reduivy__Contact__c,
                        reduivy__Contact__r.Name,
                        reduivy__Facility__c,
                        reduivy__Facility__r.Name
                        FROM reduivy__Study_Event_Relation__c
                        WHERE reduivy__Study_Event__r.reduivy__Start_Date_Non_TZ__c IN: dateList
                        AND (reduivy__Contact__c IN :facultyId
                        OR reduivy__Facility__c IN :facilityId
                        )
                        WITH USER_MODE
                    ]){
                        if(String.isNotBlank(ser.reduivy__Contact__c)){
                            
                            facultyConflictedSer.add(ser);
                            
                        } 
                        if (String.isNotBlank(ser.reduivy__Facility__c)){
                        
                            facilityConflictedSer.add(ser);
                            
                        }
                        
                    }
                }

                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeFieldName('sessionData');
                gen.writeStartObject();
                gen.writeObjectField(SER_Helper.RELATION_TYPE_FACULTY, facultySessionSer);
                gen.writeObjectField(SER_Helper.RELATION_TYPE_FACILITY, facilitySessionSer);
                gen.writeEndObject();
                gen.writeFieldName('conflictData');
                gen.writeStartObject(); 
                gen.writeObjectField(SER_Helper.RELATION_TYPE_FACULTY, facultyConflictedSer);
                gen.writeObjectField(SER_Helper.RELATION_TYPE_FACILITY, facilityConflictedSer);
                gen.writeEndObject();
                gen.writeEndObject();

                return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, gen.getAsString());
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, null);
            
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}