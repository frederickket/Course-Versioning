/**
 * @author      WDCi (XW)
 * @date        Aug 2024
 * @group       
 * @description 
 * @changehistory
 * ISS-001920 05-08-2024 - create new class
 */
public with sharing class REDU_SessionFacultyAssignment_LCTRL {
    
    /**
     * @description Get all qualified faculty of the selected study session
     * @param  studySessionId The id of target study session 
     * @return                REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse getAllQualifiedFaculty(String studySessionId){
        try {
            List<reduivy__Qualified_Faculty__c> qualifiedFacultyList = new List<reduivy__Qualified_Faculty__c>();

            if(String.isNotBlank(studySessionId)){

                List<reduivy__Study_Session__c> targetStudySession = new List<reduivy__Study_Session__c>();
                for(reduivy__Study_Session__c sse : [
                    SELECT reduivy__Study_Offering__r.reduivy__Study_Unit__c
                    FROM reduivy__Study_Session__c
                    WHERE Id = :studySessionId
                    WITH USER_MODE
                ]) {
                    targetStudySession.add(sse);
                }
                
                if(!targetStudySession.isEmpty()){

                    for(reduivy__Qualified_Faculty__c qfa : [
                        SELECT Id, reduivy__Study_Unit__c, reduivy__Contact__c,
                        reduivy__Contact__r.Name, reduivy__Faculty_Role__c
                        FROM reduivy__Qualified_Faculty__c
                        WHERE reduivy__Status__c = :QFA_Helper.STATUS_ACTIVE
                        AND reduivy__Study_Unit__c = :targetStudySession[0].reduivy__Study_Offering__r.reduivy__Study_Unit__c
                        WITH USER_MODE
                    ]){
                        qualifiedFacultyList.add(qfa);
                    }
                }         
            }
                            
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(qualifiedFacultyList));
        
        } catch (QueryException qex){
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description assign (add) a new faculty to a study event
     * @param  contactId               Contact Id
     * @param  studySessionTimeIds     List of Study Session Time Id
     * @param  status                  Response status 
     * @param  startDate               Date of beginning of the range
     * @param  endDate                 Date of end of the range
     * @param  primaryForStudySession  Make primary for study session
     * @param  primaryForStudyOffering Make primary for study offering 
     * @return                         REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse assignNewFaculty(String contactId, List<String> studySessionTimeIds, String status, Date startDate, Date endDate, Boolean primaryForStudySession, Boolean primaryForStudyOffering, List<String> facultyRoles){
        
        Savepoint sp = Database.setSavePoint();
        
        try {
            List<reduivy__Study_Event_Relation__c> serListToInsert = new List<reduivy__Study_Event_Relation__c>();
            List<Id> recordIdsToNotify = new List<Id>();
            if(String.isNotBlank(contactId) && studySessionTimeIds != null && !studySessionTimeIds.isEmpty()){

                //primary faculty
                if(primaryForStudySession || primaryForStudyOffering) {

                    reduivy__Study_Session_Time__c sst = [
                        SELECT Id, reduivy__Study_Session__c, reduivy__Study_Session__r.reduivy__Primary_Faculty__c,
                        reduivy__Study_Session__r.reduivy__Study_Offering__c,
                        reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Primary_Faculty__c
                        FROM reduivy__Study_Session_Time__c
                        WHERE Id IN :studySessionTimeIds
                        WITH USER_MODE
                        LIMIT 1
                    ];
                        
                    if(primaryForStudySession) {
                        reduivy__Study_Session__c sseToUpdate = new reduivy__Study_Session__c(
                            Id = sst.reduivy__Study_Session__c,
                            reduivy__Primary_Faculty__c = contactId
                        );

                        REDU_Database_UTIL.doUpdate(new List<reduivy__Study_Session__c> {sseToUpdate});
                        recordIdsToNotify.add(sst.reduivy__Study_Session__c);
                    }

                    if(primaryForStudyOffering) {
                        reduivy__Study_Offering__c sofToUpdate = new reduivy__Study_Offering__c(
                            Id = sst.reduivy__Study_Session__r.reduivy__Study_Offering__c,
                            reduivy__Primary_Faculty__c = contactId
                        );

                        REDU_Database_UTIL.doUpdate(new List<reduivy__Study_Offering__c> {sofToUpdate});
                        recordIdsToNotify.add(sst.reduivy__Study_Session__r.reduivy__Study_Offering__c);   
                    }
                }
                
                Map<String, Object> queryBind = new Map<String, Object>();
                String query = 'SELECT Id, Name, ' +
                    'reduivy__Study_Session_Time__c, ' +
                    'reduivy__Study_Session_Time__r.reduivy__Study_Session__c, ' +
                    'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__c ' +
                    'FROM reduivy__Study_Event__c ' +
                    'WHERE reduivy__Study_Session_Time__c IN :studySessionTimeIds ';

                    if(startDate != null) {
                        query += 'AND reduivy__Start_Date_Non_TZ__c >= :startDate ';
                        queryBind.put('startDate', startDate);
                    }

                    if(endDate != null) {
                        query += 'AND reduivy__End_Date_Non_TZ__c <= :endDate ';
                        queryBind.put('endDate', endDate);
                    }

                query += ' AND Id NOT IN ( ' + //check for duplicated ser
                    ' SELECT reduivy__Study_Event__c ' +
                    ' FROM reduivy__Study_Event_Relation__c ' +
                    ' WHERE reduivy__Contact__c = :contactId ';

                if(startDate != null) {
                    query += ' AND reduivy__Study_Event__r.reduivy__Start_Date_Non_TZ__c >= :startDate ';
                }
                
                if(endDate != null) {
                    query += ' AND reduivy__Study_Event__r.reduivy__End_Date_Non_TZ__c <= :endDate ';
                }
                                
                query += ' AND reduivy__Study_Event__r.reduivy__Study_Session_Time__c IN :studySessionTimeIds ' +
                ')';

                queryBind.put('studySessionTimeIds', studySessionTimeIds);
                queryBind.put('contactId', contactId);

                List<reduivy__Study_Event__c> studyEventList = new List<reduivy__Study_Event__c>();
                for (reduivy__Study_Event__c sev : (List<reduivy__Study_Event__c>) Database.queryWithBinds(query, queryBind, AccessLevel.USER_MODE)) {
                    studyEventList.add(sev);
                }

                Map<Id, Id> sevToIsnMap = SER_Helper.linkIenAndIsnRelationship(studyEventList, contactId, facultyRoles);

                if(!studyEventList.isEmpty()){

                    for(reduivy__Study_Event__c studyEvent : studyEventList){
                        reduivy__Study_Event_Relation__c newSer = new reduivy__Study_Event_Relation__c(
                            reduivy__Contact__c = contactId,
                            reduivy__Study_Event__c = studyEvent.Id,
                            reduivy__Response_Status__c = status,
                            reduivy__Individual_Session_Enrollment__c = sevToIsnMap.get(studyEvent.Id)
                        );

                        serListToInsert.add(newSer);
                        recordIdsToNotify.add(studyEvent.Id);
                    }

                    REDU_Database_UTIL.doInsert(serListToInsert);
                }
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(recordIdsToNotify));


        } catch (QueryException qex){
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