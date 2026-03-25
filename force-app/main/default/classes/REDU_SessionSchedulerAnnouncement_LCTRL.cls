/**
 * @author      WDCi (Lean)
 * @date        Jun 2024
 * @group       Study Session Scheduler
 * @description Study session scheduler announcement modal
 * @changehistory
 * ISS-001920 11-06-2024 Lean - new class
 */
public with sharing class REDU_SessionSchedulerAnnouncement_LCTRL {
    
    @AuraEnabled
    /**
     * @description To send an announcement
     * @param studySessionId The session id
     * @param announcementSummary The announcement summary
     * @param announcementDetails The announcement details
     * @param notifyStudents If this is true, the student session connection with Enrollment Status = Enrolled will be considered
     * @param notifyFaculties If this is true, the faculty session connection with Enrollment Status = Enrolled will be considered
     * @param isnStartDate If this is defined, we will get the session connection with Start Date >= isnStartDate (for student) or the session connection that has attendance with date >= isnStartDate and excused = false (for faculty)
     * @param isnEndDate If this is defined, we will get the session connection with End Date <= isnEndDate (for student) or the session connection that has attendance with date <= isnEndDate and excused = false (for faculty)
     * @param channelTypes The announcement Notification Channel Type(s)
     */
    public static void sendAnnouncement(String studySessionId, String announcementSummary, String announcementDetails, Boolean notifyStudents, Boolean notifyFaculties, Date isnStartDate, Date isnEndDate, String channelTypes){
        Savepoint sp = Database.setSavePoint();
        
        try{
            reduivy__Announcement__c ann = new reduivy__Announcement__c();
            ann.Name = announcementSummary;
            ann.reduivy__Details__c = announcementDetails;
            ann.reduivy__Record_Id__c = studySessionId;
            ann.reduivy__Channel_Type__c = channelTypes;
            ann.reduivy__Notification_Sender_Id__c = UserInfo.getUserId();
            ann.reduivy__Notification_Target_Type__c = (channelTypes != null && channelTypes.contains(ANM_Helper.NCT_NOTIFICATION) ? ANM_Helper.NTT_RECORD_PAGE : null);
            ann.reduivy__Notification_Target_Value__c = null;
            ann.reduivy__Status__c = ANM_Helper.STATUS_SEND;

            //Set receiver Ids
            Set<String> receiverIdsSet = new Set<String>();
            Set<Id> remainingContactIds = new Set<Id>();
            //ISS-001903
            Set<Id> allContactIds = new Set<Id>();

            //Student Ids
            if (notifyStudents) {

                Set<String> isnFields = new Set<String>{
                    'Id',
                    'Name',
                    'reduivy__Individual_Enrollment__r.reduivy__Contact__c',
                    'reduivy__Individual_Enrollment__r.reduivy__Contact__r.reduivy__User__c',
                    'reduivy__Start_Date__c',
                    'reduivy__End_Date__c',
                    'reduivy__Study_Session__r.reduivy__Start_Date__c',
                    'reduivy__Study_Session__r.reduivy__End_Date__c'
                };

                String isnSoql = 'SELECT ' + String.join(isnFields, ', ') +
                    ' FROM reduivy__Individual_Session_Enrollment__c ' + 
                    ' WHERE reduivy__Study_Session__c =: studySessionId ' +
                    ' AND RecordTypeId =: studentRtId ' +
                    ' AND reduivy__Enrollment_Status__c IN: inProgressStatuses';

                Map<String, Object> isnBindParams = new Map<String, Object>{
                    'studySessionId' => studySessionId,
                    'studentRtId' => ISN_Helper.getStudentRecordTypeId(),
                    'inProgressStatuses' => ISN_Helper.getInProgressStatuses()
                };

                for (reduivy__Individual_Session_Enrollment__c studentIsn : (List<reduivy__Individual_Session_Enrollment__c>) Database.queryWithBinds(isnSoql, isnBindParams, AccessLevel.USER_MODE)){
                    //this is to handle sc with empty dates
                    Date startDate = (studentIsn.reduivy__Start_Date__c != null ? studentIsn.reduivy__Start_Date__c : studentIsn.reduivy__Study_Session__r.reduivy__Start_Date__c);
                    Date endDate = (studentIsn.reduivy__End_Date__c != null ? studentIsn.reduivy__End_Date__c: studentIsn.reduivy__Study_Session__r.reduivy__End_Date__c);
                    
                    //this is to consider any students that fall within the date range
                    Boolean validReceiver = false;

                    if (isnStartDate != null && isnEndDate != null) {
                        if (isnStartDate <= endDate && isnEndDate >= startDate) {
                            validReceiver = true;
                        }
                    } else if (isnStartDate != null) {
                        if (startDate >= isnStartDate) {
                            validReceiver = true;
                        }
                    } else if (isnEndDate != null) {
                        if (endDate <= isnEndDate ) {
                            validReceiver = true;
                        }
                    } else {
                        validReceiver = true;
                    }

                    if (validReceiver) {
                        if (String.isNotBlank(studentIsn.reduivy__Individual_Enrollment__r?.reduivy__Contact__r?.reduivy__User__c)) {
                            receiverIdsSet.add(studentIsn.reduivy__Individual_Enrollment__r.reduivy__Contact__r.reduivy__User__c);
                        } else {
                            remainingContactIds.add(studentIsn.reduivy__Individual_Enrollment__r.reduivy__Contact__c);
                        }
                        
                        allContactIds.add(studentIsn.reduivy__Individual_Enrollment__r.reduivy__Contact__c);
                    }
                }
            }

            //Faculty Ids
            if (notifyFaculties) {

                Set<String> isnFields = new Set<String>{
                    'Id',
                    'Name',
                    'reduivy__Individual_Enrollment__r.reduivy__Contact__c',
                    'reduivy__Individual_Enrollment__r.reduivy__Contact__r.reduivy__User__c'
                };

                String isnSoql = 'SELECT ' + String.join(isnFields, ', ') +
                    ' FROM reduivy__Individual_Session_Enrollment__c ' + 
                    ' WHERE reduivy__Study_Session__c =: studySessionId ' +
                    ' AND RecordTypeId =: facultyRtId ' +
                    ' AND reduivy__Enrollment_Status__c IN: inProgressStatuses ';

                Map<String, Object> isnBindParams = new Map<String, Object>{
                    'studySessionId' => studySessionId,
                    'facultyRtId' => ISN_Helper.getFacultyRecordTypeId(),
                    'inProgressStatuses' => ISN_Helper.getInProgressStatuses()
                };

                if (isnStartDate != null && isnEndDate != null) {
                    isnBindParams.put('responseStatuses', new Set<String>{SER_Helper.RESPONSE_STATUS_NEW, SER_Helper.RESPONSE_STATUS_ACCEPTED});
                    isnBindParams.put('startDate', isnStartDate);
                    isnBindParams.put('endDate', isnEndDate);

                    isnSoql += ' AND Id IN (SELECT reduivy__Individual_Session_Enrollment__c FROM reduivy__Study_Event_Relation__c WHERE reduivy__Study_Event__r.reduivy__Start_Date_Non_TZ__c >= :startDate AND reduivy__Study_Event__r.reduivy__Start_Date_Non_TZ__c <= :endDate AND reduivy__Response_Status__c IN: responseStatuses)';
                
                } else if (isnStartDate != null) {
                    isnBindParams.put('responseStatuses', new Set<String>{SER_Helper.RESPONSE_STATUS_NEW, SER_Helper.RESPONSE_STATUS_ACCEPTED});
                    isnBindParams.put('startDate', isnStartDate);

                    isnSoql += ' AND Id IN (SELECT reduivy__Individual_Session_Enrollment__c FROM reduivy__Study_Event_Relation__c WHERE reduivy__Study_Event__r.reduivy__Start_Date_Non_TZ__c >= :startDate AND reduivy__Response_Status__c IN: responseStatuses)';
                
                } else if (isnEndDate != null) {
                    isnBindParams.put('responseStatuses', new Set<String>{SER_Helper.RESPONSE_STATUS_NEW, SER_Helper.RESPONSE_STATUS_ACCEPTED});
                    isnBindParams.put('endDate', isnEndDate);

                    isnSoql += ' AND Id IN (SELECT reduivy__Individual_Session_Enrollment__c FROM reduivy__Study_Event_Relation__c WHERE reduivy__Study_Event__r.reduivy__Start_Date_Non_TZ__c <= :endDate AND reduivy__Response_Status__c IN: responseStatuses)';
                }

                for (reduivy__Individual_Session_Enrollment__c facultyIsn : (List<reduivy__Individual_Session_Enrollment__c>) Database.queryWithBinds(isnSoql, isnBindParams, AccessLevel.USER_MODE)){
                    if (String.isNotBlank(facultyIsn.reduivy__Individual_Enrollment__r?.reduivy__Contact__r?.reduivy__User__c)) {
                        receiverIdsSet.add(facultyIsn.reduivy__Individual_Enrollment__r.reduivy__Contact__r.reduivy__User__c);
                    } else {
                        remainingContactIds.add(facultyIsn.reduivy__Individual_Enrollment__r.reduivy__Contact__c);
                    }
                    
                    allContactIds.add(facultyIsn.reduivy__Individual_Enrollment__r.reduivy__Contact__c);
                }
            }

            //Get Users for Contacts that don't have their User lookup field set
            List<User> remainingContactUsers = [SELECT Id FROM User WHERE ContactId IN :remainingContactIds WITH USER_MODE];
            
            for (User remainingContactUser : remainingContactUsers) {
                receiverIdsSet.add(remainingContactUser.Id);
            }

            receiverIdsSet.add(UserInfo.getUserId());
            
            if (!receiverIdsSet.isEmpty()) {
                ann.reduivy__Notification_Receivers_Id__c = String.join(receiverIdsSet, ';');
            }
            
            if (!allContactIds.isEmpty()) {
                ann.reduivy__Notification_Receivers_Contact_Id__c = String.join(allContactIds, ';');
            }

            REDU_Database_UTIL.doInsert(new List<reduivy__Announcement__c>{ann});

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