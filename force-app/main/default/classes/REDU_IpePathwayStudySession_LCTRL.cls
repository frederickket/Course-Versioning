/**
 * @author      WDCi (Sueanne)
 * @date        Sept 2024
 * @group       Enrollment wizard
 * @description Controller to handle study session enrollment needed data
 * @changehistory
 * ISS-002050 17-09-2024 Sueanne - new class
 * ISS-002330 20-03-2025 XW - get translation name for study session
 * ISS-002381 11-04-2025 XiRouh - update sseNameWithTranslation to use the translated field only if it is not null; otherwise, use the original record name
 * ISS-002410 14-04-2025 XiRouh - Replaced isSet with != null
 */
public with sharing class REDU_IpePathwayStudySession_LCTRL {

    static final List<String> ISN_POSITIVE_STATUSES = new List<String>();
    static {
        ISN_POSITIVE_STATUSES.addAll(ISN_Helper.getInProgressStatuses());
        ISN_POSITIVE_STATUSES.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        ISN_POSITIVE_STATUSES.addAll(ISN_Helper.getWaitlistedStatuses());
        ISN_POSITIVE_STATUSES.addAll(ISN_Helper.getOpenStatuses());
    }

    /**
     * @description Find study session
     * @param studySessionId
     * @param individualEnrollmentId
     * @param masterIpeId
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse initStudySession(Id studySessionId, Id individualEnrollmentId, Id masterIpeId, Id individualPathwayId, String studySessionTitleField){

        try{
            if(String.isBlank(studySessionId) || String.isBlank(individualEnrollmentId) || String.isBlank(masterIpeId) || String.isBlank(individualPathwayId)){
                throw new REDU_ApplicationException(Label.Error_Contact_Admin);
            }

            //find individual pathway
            reduivy__Individual_Pathway__c ipw;
            List<reduivy__Individual_Pathway__c> ipwList = [
                SELECT Id,
                reduivy__Academic_Term__c,
                reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c
                FROM reduivy__Individual_Pathway__c
                WHERE Id = :individualPathwayId
                WITH USER_MODE
            ];

            if(!ipwList.isEmpty()){
                ipw = ipwList[0];
            } else {
                throw new REDU_ApplicationException(String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{individualPathwayId, IPW_Helper.getObjectLabel()}));
            }

            //find study session
            Set<String> sseFields = new Set<String>{
                'Id', 
                'Name', 
                'reduivy__Type__c', 
                'reduivy__Enable_Self_Enrollment__c',
                'reduivy__Pre_enrollment_Open_Date_Calculated__c',
                'reduivy__Enrollment_Open_Date_Calculated__c',
                'reduivy__Enrollment_Close_Date_Calculated__c',
                'reduivy__Start_Date_Calculated__c',
                'reduivy__End_Date_Calculated__c',
                'reduivy__Available_Places__c',
                'reduivy__Unlimited_Places__c',
                'reduivy__Status__c',
                'reduivy__Enable_Waitlist__c'
            };

            if (String.isNotBlank(studySessionTitleField)) {
                sseFields.add(studySessionTitleField);
            }

            String sseTranslationNameField = SSE_Helper.getTranslationFieldNameForName();
            sseFields.add(sseTranslationNameField);

            Map<String, Object> sseBindParams = new Map<String, Object>();
            sseBindParams.put('studySessionId', studySessionId);

            String sseSoql = 'SELECT ' + String.join(sseFields, ', ') + 
                ' FROM reduivy__Study_Session__c ' + 
                ' WHERE Id = :studySessionId ';
            
            List<reduivy__Study_Session__c> sseList = (List<reduivy__Study_Session__c>) Database.queryWithBinds(sseSoql, sseBindParams, AccessLevel.USER_MODE);

            reduivy__Study_Session__c sse;
            if(!sseList.isEmpty()){
                sse = sseList[0];
            } else {
                throw new REDU_ApplicationException(String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{studySessionId, SSE_Helper.getObjectLabel()}));
            }
            
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Individual_Enrollment__c = :individualEnrollmentId
                AND reduivy__Study_Session__c = :sse.Id
                AND reduivy__Enrollment_Status__c IN :ISN_POSITIVE_STATUSES
                WITH USER_MODE
            ];
            
            
            //get study term id by individual enrollment
            reduivy__Individual_Enrollment__c ien;
            List<reduivy__Individual_Enrollment__c> ienList = [
                SELECT Id, reduivy__Academic_Term_Id__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :individualEnrollmentId
                WITH USER_MODE
            ];

            //respect to cohort if enabled cohort enrollment
            reduivy__Study_Cohort_Enrollment__c sce;
            if(ipw != null && String.isNotBlank(ipw.reduivy__Academic_Term__c) && ipw.reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c){

                //find related Ipe
                reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
                    reduivy__Cohort_ID__c,
                    reduivy__Class_Standing__c,
                    reduivy__Class_Year__c
                    FROM reduivy__Individual_Program_Enrollment__c
                    WHERE Id = :masterIpeId
                    WITH USER_MODE
                ];
                
                if(ipe != null){
                    sce = SCE_Helper.getStudyCohortEnrollment(ipw.reduivy__Academic_Term__c, ipe.reduivy__Cohort_ID__c, ipe.reduivy__Class_Standing__c, ipe.reduivy__Class_Year__c);
                }
            }
            
            

            //construct map to return
            Map<String, Object> mapToReturn = new Map<String, Object>();
            mapToReturn.put('sse', sse);
            mapToReturn.put('isn', isnList.isEmpty() ? null : isnList[0]);
            mapToReturn.put('sce', sce);

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(mapToReturn));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Find related study session time
     * @param studySessionId
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudySessionTime(Id studySessionId){

        try{
            if(String.isBlank(studySessionId)){
                throw new REDU_ApplicationException(Label.Error_Contact_Admin);
            }

            //find study session time
            List<reduivy__Study_Session_Time__c> sstList = [
                SELECT Id
                FROM reduivy__Study_Session_Time__c
                WHERE reduivy__Study_Session__c = :studySessionId
                WITH USER_MODE
            ];

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(sstList));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Return study session status map by type
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudySessionStatuses(){

        try {
            Map<String, List<String>> sseStatusMap = new Map<String, List<String>>{
                SSE_Helper.STATUS_TYPE_NOTSTARTED => SSE_Helper.getNotStartedStatuses(),
                SSE_Helper.STATUS_TYPE_PREENROLLMENT_OPENED => SSE_Helper.getPreEnrollmentOpenedStatuses(),
                SSE_Helper.STATUS_TYPE_ENROLLMENT_OPENED => SSE_Helper.getEnrollmentOpenedStatuses(),
                SSE_Helper.STATUS_TYPE_ENROLLMENT_CLOSED => SSE_Helper.getEnrollmentClosedStatuses(),
                SSE_Helper.STATUS_TYPE_RUNNING => SSE_Helper.getRunningStatuses()
            };

            for (String key : sseStatusMap.keySet()) {
                if (sseStatusMap.get(key).isEmpty()) {
                    String errorMsg = String.format(Label.Missing_Object_Record, new List<String>{SObjectType.reduivy__Study_Session_Status_Config__mdt.getLabel() + '.' + key});
                    throw new REDU_ApplicationException(errorMsg);
                }
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(sseStatusMap));

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Return individual session enrollment's enrollment status map by type
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualSessionEnrollmentStatuses(){

        try {
            Map<String, List<String>> isnStatusMap = new Map<String, List<String>>{
                ISN_Helper.STATUS_TYPE_OPEN => ISN_Helper.getOpenStatuses(),
                ISN_Helper.STATUS_TYPE_ENROLLMENT_REQUESTED => ISN_Helper.getEnrollmentRequestedStatuses(),
                ISN_Helper.STATUS_TYPE_INPROGRESS => ISN_Helper.getInProgressStatuses(),
                ISN_Helper.STATUS_TYPE_COMPLETED => ISN_Helper.getCompletedStatuses(),
                ISN_Helper.STATUS_TYPE_WAITLISTED => ISN_Helper.getWaitlistedStatuses(),
                ISN_Helper.STATUS_TYPE_DROPPED => ISN_Helper.getDroppedStatuses(),
                ISN_Helper.STATUS_TYPE_WITHDRAWN => ISN_Helper.getWithdrawnStatuses()
            };

            for (String key : isnStatusMap.keySet()) {
                if (isnStatusMap.get(key).isEmpty()) {
                    String errorMsg = String.format(Label.Missing_Object_Record, new List<String>{SObjectType.reduivy__IdvSn_Enrollment_Status_Config__mdt.getLabel() + '.' + key});
                    throw new REDU_ApplicationException(errorMsg);
                }
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(isnStatusMap));
            
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Insert or update the individual session enrollment record based on the enrollment action.
     * @param individualEnrollmentId
     * @param studyOfferingId
     * @param sseRecord study session record
     * @param enrollmentAction ISN_Helper ENROLLMENT_ACTION
     * @return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse upsertEnrollment(Id individualEnrollmentId, String sseRecord, String enrollmentAction){

        Savepoint sp = Database.setSavePoint();

        try {
            reduivy__Study_Session__c sse = (reduivy__Study_Session__c) JSON.deserialize(sseRecord, reduivy__Study_Session__c.class);

            if (String.isBlank(individualEnrollmentId) || 
                String.isBlank(enrollmentAction) || 
                sse == null 
            ) {
                throw new REDU_ApplicationException(Label.Error_Contact_Admin);
            }

            //find individual enrollment
            List<reduivy__Individual_Enrollment__c> ienList = [SELECT Id
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :individualEnrollmentId
                WITH USER_MODE
            ];
            
            if (ienList.isEmpty()){
                throw new REDU_ApplicationException(Label.Error_Contact_Admin);
            }

            //check if isn exist
            reduivy__Individual_Enrollment__c ien = ienList[0];

            List<reduivy__Individual_Session_Enrollment__c> isnList = [SELECT Id,
                reduivy__Enrollment_Status__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c	 = :sse.Id
                AND reduivy__Individual_Enrollment__c = :ien.Id
                AND reduivy__Enrollment_Status__c IN :ISN_POSITIVE_STATUSES
                WITH USER_MODE
            ];

            reduivy__Individual_Session_Enrollment__c isn = isnList.isEmpty() ? null : isnList[0];

            if(isn == null){
                isn = new reduivy__Individual_Session_Enrollment__c();
                isn.reduivy__Individual_Enrollment__c = ien.Id;
                isn.RecordTypeId = ISN_Helper.getStudentRecordTypeId();
                isn.reduivy__Start_Date__c = sse.reduivy__Start_Date_Calculated__c;
                isn.reduivy__End_Date__c = sse.reduivy__End_Date_Calculated__c;
                isn.reduivy__Study_Session__c = sse.Id;
            }

            String responseMessage;
            Boolean isDoUpsert = true;

            String translatedNameFieldApiName = SSE_Helper.getTranslationFieldNameForName();
            String sseNameWithTranslation = (String) (sse.get(translatedNameFieldApiName) != null ? sse.get(translatedNameFieldApiName) : sse.Name);
            
            if (enrollmentAction == ISN_Helper.ENROLLMENT_ACTION_ENROLLREQUESTED) {
                //pre-enrollment = Enrollment Requested

                isn.reduivy__Enrollment_Status__c = ISN_Helper.getEnrollmentRequestedStatuses()[0];

                responseMessage = String.format(Label.Pre_Enrollment_Success, new List<String>{sseNameWithTranslation});

            } else if (enrollmentAction == ISN_Helper.ENROLLMENT_ACTION_ENROLL) {
                //enroll = Enrolled

                isn.reduivy__Enrollment_Status__c = ISN_Helper.getInProgressStatuses()[0];

                responseMessage = String.format(Label.Enrollment_Success, new List<String>{sseNameWithTranslation});

            } else if (enrollmentAction == ISN_Helper.ENROLLMENT_ACTION_JOINWAITLIST) {
                //join waitlist = Waitlisted

                isn.reduivy__Enrollment_Status__c = ISN_Helper.getWaitlistedStatuses()[0];

                responseMessage = String.format(Label.Join_Waitlist_Success, new List<String>{sseNameWithTranslation});

            } else if (enrollmentAction == ISN_Helper.ENROLLMENT_ACTION_WITHDRAWENROLLREQUESTED) {
                //withdraw from pre-enrollment = Not Started

                isn.reduivy__Enrollment_Status__c = ISN_Helper.getOpenStatuses()[0];

                responseMessage = String.format(Label.Withdraw_Pre_Enrollment_Success, new List<String>{sseNameWithTranslation});

            } else if (enrollmentAction == ISN_Helper.ENROLLMENT_ACTION_WITHDRAWWAITLIST) {
                //withdraw from waitlist = Not Started

                isn.reduivy__Enrollment_Status__c = ISN_Helper.getOpenStatuses()[0];
                
                responseMessage = String.format(Label.Withdraw_Waitlist_Success, new List<String>{sseNameWithTranslation});

            } else if (enrollmentAction == ISN_Helper.ENROLLMENT_ACTION_UNENROLL) {
                //unenroll = Withdrawn

                //check if isn having attendance
                List<reduivy__Study_Event_Relation__c> isnAttendance = [SELECT Id
                    FROM reduivy__Study_Event_Relation__c
                    WHERE reduivy__Individual_Session_Enrollment__c = :isn.Id
                    WITH USER_MODE
                ];

                //if didn't have attendance, delete isn
                if(isnAttendance.isEmpty()){
                    isDoUpsert = false;
                } else {
                    isn.reduivy__Enrollment_Status__c = ISN_Helper.getWithdrawnStatuses()[0];
                }

                responseMessage = String.format(Label.Unenrollment_Success, new List<String>{sseNameWithTranslation});
            }

            if(isDoUpsert){
                REDU_Database_UTIL.doUpsert(new List<reduivy__Individual_Session_Enrollment__c>{isn});
            } else {
                //we need to use system mode as the record could be deleted by non owner e.g., faculty deleting on behalf of student
                REDU_SystemMode_UTIL.doDelete(new List<reduivy__Individual_Session_Enrollment__c>{isn});
            }

            return new REDU_LightningResponse(true, responseMessage, JSON.serialize(new Set<Id>{isn.Id}));

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
     * @description To check if study session's study events having conflict with contact's booked events
     * @param studySessionId
     * @param contactId
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse checkEventConflict(Id studySessionId, Id contactId){

        try {
            //get study session
            reduivy__Study_Session__c sse = [
                SELECT Id, reduivy__Start_Date_Calculated__c, reduivy__End_Date_Calculated__c
                FROM reduivy__Study_Session__c
                WHERE Id = :studySessionId
                WITH USER_MODE
            ];

            //convert date to datetime
            Date startDate = sse.reduivy__Start_Date_Calculated__c;
            Date endDate = sse.reduivy__End_Date_Calculated__c;
            Datetime startDt = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day(), 0, 0, 0);
            Datetime endDt = Datetime.newInstance(endDate.year(), endDate.month(), endDate.day(), 0, 0, 0);

            List<String> enrollStatuses = new List<String>();
            enrollStatuses.addAll(ISN_Helper.getInProgressStatuses());
            enrollStatuses.addAll(ISN_Helper.getCompletedStatuses());

            //get contact's events
            List<reduivy__Study_Event__c> contactSev = CON_Helper.getContactEvents(contactId, startDt, endDt, enrollStatuses);

            //get study session's events
            Map<Date, List<reduivy__Study_Event__c>> sevMap = new Map<Date, List<reduivy__Study_Event__c>>();

            for(reduivy__Study_Event__c sev : [SELECT Id,
                reduivy__Study_Session_Time__c,
                reduivy__Study_Session_Time__r.reduivy__Study_Session__c,
                reduivy__Start_Date_Non_TZ__c,
                reduivy__Start_Time_Non_TZ__c,
                reduivy__End_Time_Non_TZ__c
                FROM reduivy__Study_Event__c
                WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :studySessionId
                WITH USER_MODE
            ]){
                if(!sevMap.containsKey(sev.reduivy__Start_Date_Non_TZ__c)){
                    sevMap.put(sev.reduivy__Start_Date_Non_TZ__c, new List<reduivy__Study_Event__c>());
                }
                sevMap.get(sev.reduivy__Start_Date_Non_TZ__c).add(sev);
            }

            //check conflict
            List<reduivy__Study_Event__c> conflictedSev = new List<reduivy__Study_Event__c>();

            for(reduivy__Study_Event__c conSev : contactSev){
                
                if(conSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c == studySessionId){
                    continue;
                }

                //check start date conflict
                if(sevMap.containsKey(conSev.reduivy__Start_Date_Non_TZ__c)){
                    
                    for(reduivy__Study_Event__c sev : sevMap.get(conSev.reduivy__Start_Date_Non_TZ__c)){

                        //check whether time conflict
                        if(conSev.reduivy__Start_Time_Non_TZ__c < sev.reduivy__End_Time_Non_TZ__c && conSev.reduivy__End_Time_Non_TZ__c > sev.reduivy__Start_Time_Non_TZ__c
                        ){
                            conflictedSev.add(conSev);
                            //we will stop once there is a conflict found, no point looping through all as we just need an indication
                            break;
                        }
                    }
                }
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(conflictedSev));
            
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}