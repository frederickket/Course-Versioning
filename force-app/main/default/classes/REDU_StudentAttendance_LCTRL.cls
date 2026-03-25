/**
 * @Author 		WDCi (Lean)
 * @Date 		July 2024
 * @group 		Attendance
 * @Description Attendance taking wizard for faculty
 * @changehistory
 * ISS-001919 31-07-2024 Lean - new class
 * ISS-002245 13-01-2025 XiRouh - update the logic to support showRecordsBasedOnAllocation attribute
 */
public with sharing class REDU_StudentAttendance_LCTRL {
    
    /**
     * @description Get the study events for attendance marking for the day
     * @param recordId Session record id if available
     * @param userMode Admin or Faculty
     * @param forDate date
     */
	@AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudyEvents(
        String recordId, String userMode, Date forDate, String validFacultyIsnStatus, 
        Boolean showRecordsBasedOnAllocation
    ){

        try {
            //define the date for query
            if (forDate == null) {
                forDate = System.today();
            }

            Datetime startDt = Datetime.newInstance(forDate, Time.newInstance(0, 0, 0, 0));
            Datetime endDt = Datetime.newInstance(forDate.addDays(1), Time.newInstance(0, 0, 0, 0));

            Id contactId;
            Id studySessionId;

            //if recordId == study session, we will only list the study events for the study session
            if (String.isNotBlank(recordId)) {
                Id tempRecordId = Id.valueOf(recordId);
                if (tempRecordId.getSobjectType() == Schema.reduivy__Study_Session__c.getSObjectType()) {
                    studySessionId = tempRecordId;
                }
            }

            //prepare the query for study events
            Set<String> sevFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Start__c',
                'reduivy__End__c',
                'reduivy__Status__c',
                'reduivy__Study_Session_Time__c',
                'reduivy__Study_Session_Time__r.reduivy__Study_Session__c',
                'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Background_Colour__c',
                'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__c',
                'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c',
                'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Background_Colour__c'
            };

            Map<String, Object> sevBindParams = new Map<String, Object>();
            sevBindParams.put('start', startDt);
            sevBindParams.put('end', endDt);
            sevBindParams.put('sevType', SEV_Helper.TYPE_STUDY_SESSION);
            sevBindParams.put('attendanceStatuses', SER_Helper.getAttendanceMarkedStatuses());
            sevBindParams.put('isnStudentRtId', ISN_Helper.getStudentRecordTypeId());

            String sevSoql = 'SELECT ' + String.join(sevFields, ', ') + ', ' +
                ' (SELECT Id FROM reduivy__Study_Event_Relations__r WHERE reduivy__Attendance_Status__c IN: attendanceStatuses AND reduivy__Individual_Session_Enrollment__r.RecordTypeId =: isnStudentRtId) ' +
                ' FROM reduivy__Study_Event__c ' + 
                ' WHERE reduivy__Start__c >=: start ' + 
                ' AND reduivy__End__c <: end ' + 
                ' AND reduivy__Type__c =: sevType ';

            if (String.isNotBlank(studySessionId)) {
                sevBindParams.put('studySessionId', studySessionId);

                sevSoql += ' AND reduivy__Study_Session_Time__r.reduivy__Study_Session__c =: studySessionId ';
            }

            Map<String, Set<String>> sevObjectFieldsFls = new Map<String, Set<String>>();
            sevObjectFieldsFls.put(SEV_Helper.getApiName(), sevFields);
            sevObjectFieldsFls.put(SST_Helper.getApiName(), new Set<String>{'reduivy__Study_Session__c'});
            sevObjectFieldsFls.put(SSE_Helper.getApiName(), new Set<String>{'reduivy__Background_Colour__c', 'reduivy__Study_Offering__c'});
            sevObjectFieldsFls.put(SOF_Helper.getApiName(), new Set<String>{'reduivy__Study_Unit__c'});
            sevObjectFieldsFls.put(SUN_Helper.getApiName(), new Set<String>{'reduivy__Background_Colour__c'});

            //search for study events for listing
            List<reduivy__Study_Event__c> studyEvents = new List<reduivy__Study_Event__c>();

            if (String.isNotBlank(userMode) && userMode == USR_Helper.USER_MODE_ADMIN) {
                //for admin mode, we will list all study events
                sevSoql += ' ORDER BY reduivy__Start__c ';

                //Query data protected by restriction rules using system mode
                for (reduivy__Study_Event__c sev : (List<reduivy__Study_Event__c>) REDU_SystemMode_UTIL.doQuery(sevSoql, sevBindParams, sevObjectFieldsFls)) {
                    studyEvents.add(sev);
                }
            } else {
                //for user mode, we will list the study events related to the contact
                User currentUser = USR_Helper.getCurrentUserInfo(UserInfo.getUserId());
                if (currentUser != null && String.isNotBlank(currentUser.ContactId)) {
                    contactId = currentUser.ContactId;
                } else {
                    throw new REDU_ApplicationException(Label.Failed_To_Identify_The_Contact_For_Current_User);
                }

                Set<String> isnFacultyEnrollmentStatuses = String.isNotBlank(validFacultyIsnStatus) ? new Set<String>(validFacultyIsnStatus.split(';')) : new Set<String>();

                if(showRecordsBasedOnAllocation == true) { //ISS-002245 if showRecordsBasedOnAllocation is true, we will show all the study events that have study event relation lookup to
                    Set<String> serFields = new Set<String>{
                        'Id',
                        'reduivy__Study_Event__c',
                        'reduivy__Relation_Type__c',
                        'reduivy__Relation_Name__c'
                    };
    
                    Map<String, Object> serBindParams = new Map<String, Object>();
                    serBindParams.put('contactId', contactId);
                    serBindParams.put('positiveStatuses', new Set<String>{SER_Helper.RESPONSE_STATUS_ACCEPTED, SER_Helper.RESPONSE_STATUS_NEW});
                    serBindParams.put('start', startDt);
                    serBindParams.put('end', endDt);
                    serBindParams.put('sevType', SEV_Helper.TYPE_STUDY_SESSION);
                    serBindParams.put('isnFacultyRtId', ISN_Helper.getFacultyRecordTypeId());
    
                    
                    String serSoql = 'SELECT ' + String.join(serFields, ', ') + 
                        ' FROM reduivy__Study_Event_Relation__c ' +
                        ' WHERE reduivy__Contact__c =: contactId ' + 
                        ' AND reduivy__Response_Status__c IN: positiveStatuses ' +
                        ' AND reduivy__Study_Event__r.reduivy__Start__c >=: start ' + 
                        ' AND reduivy__Study_Event__r.reduivy__End__c <: end ' +
                        ' AND reduivy__Study_Event__r.reduivy__Type__c =: sevType ' +
                        ' AND reduivy__Individual_Session_Enrollment__r.RecordTypeId =: isnFacultyRtId ';
                    
                    //Query data protected by restriction rules using system mode
                    Map<String, Set<String>> serObjectFieldsFls = new Map<String, Set<String>>();
                    serObjectFieldsFls.put(SER_Helper.getApiName(), serFields);
                    Set<Id> sevIds = new Set<Id>();

                    for (reduivy__Study_Event_Relation__c ser : (List<reduivy__Study_Event_Relation__c>) REDU_SystemMode_UTIL.doQuery(serSoql, serBindParams, serObjectFieldsFls)) {
                        if (String.isNotBlank(ser.reduivy__Study_Event__c)) {
                            sevIds.add(ser.reduivy__Study_Event__c);
                        }
                    }

                    if (!sevIds.isEmpty()) {
                        //we only get the related study events assigned to the contact
                        sevBindParams.put('sevIds', sevIds);
    
                        sevSoql += ' AND Id IN: sevIds ';
                        sevSoql += ' ORDER BY reduivy__Start__c ';
    
                        //Query data protected by restriction rules using system mode
                        for (reduivy__Study_Event__c sev : (List<reduivy__Study_Event__c>) REDU_SystemMode_UTIL.doQuery(sevSoql, sevBindParams, sevObjectFieldsFls)) {
                            studyEvents.add(sev);
                        }
                    }
                } else { //ISS-002245 if showRecordsBasedOnAllocation is false, we will show all the study events that have individual session enrollment regardless it have study event relation or not

                    Set<String> isnFields = new Set<String>{
                        'Id',
                        'reduivy__Study_Session__c'
                    };

                    Map<String, Object> isnBindParams = new Map<String, Object>();
                    isnBindParams.put('contactId', contactId);
                    isnBindParams.put('enrollmentstatuses', isnFacultyEnrollmentStatuses);
                    isnBindParams.put('start', startDt.date());
                    isnBindParams.put('end', endDt.date());
                    isnBindParams.put('isnFacultyRtId', ISN_Helper.getFacultyRecordTypeId());

                    String isnSoql = 'SELECT ' + String.join(isnFields, ', ') + 
                        ' FROM reduivy__Individual_Session_Enrollment__c ' +
                        ' WHERE reduivy__Contact_Id__c = :contactId ' +
                        ' AND RecordTypeId = :isnFacultyRtId ' +
                        ' AND reduivy__Enrollment_Status__c IN :enrollmentstatuses ';

                    Map<String, Set<String>> isnObjectFieldsFls = new Map<String, Set<String>>();
                    isnObjectFieldsFls.put(ISN_Helper.getApiName(), isnFields);
                    Set<Id> sseIds = new Set<Id>();

                    for (reduivy__Individual_Session_Enrollment__c isn : (List<reduivy__Individual_Session_Enrollment__c>) REDU_SystemMode_UTIL.doQuery(isnSoql, isnBindParams, isnObjectFieldsFls)) {
                        if (String.isNotBlank(isn.reduivy__Study_Session__c)) {
                            sseIds.add(isn.reduivy__Study_Session__c);
                        }
                    }

                    if (!sseIds.isEmpty()) {
                        sevBindParams.put('sseIds', sseIds);
    
                        sevSoql += ' AND reduivy__Study_Session_Time__r.reduivy__Study_Session__c IN: sseIds ';
                        sevSoql += ' ORDER BY reduivy__Start__c ';
    
                        //Query data protected by restriction rules using system mode
                        for (reduivy__Study_Event__c sev : (List<reduivy__Study_Event__c>) REDU_SystemMode_UTIL.doQuery(sevSoql, sevBindParams, sevObjectFieldsFls)) {
                            studyEvents.add(sev);
                        }
                    }
                }
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(studyEvents));

            return response;

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}