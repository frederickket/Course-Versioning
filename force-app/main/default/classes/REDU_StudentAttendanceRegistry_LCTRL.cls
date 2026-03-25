/**
 * @Author 		WDCi (Lean)
 * @Date 		July 2024
 * @group 		Attendance
 * @Description Attendance taking wizard for faculty
 * @changehistory
 * ISS-001919 31-07-2024 Lean - new class
 */
public with sharing class REDU_StudentAttendanceRegistry_LCTRL {
    
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
    
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudentsAttendances(String studyEventId, String studyEventRelationEditFieldSetName){

        try {
            List<String> serFormFields = new List<String>();
            if (String.isNotBlank(studyEventRelationEditFieldSetName)) {
                serFormFields = REDU_Metadata_UTIL.getFields('reduivy__Study_Event_Relation__c', studyEventRelationEditFieldSetName, false);
            }

            Set<String> sevFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Study_Session_Time__c',
                'reduivy__Study_Session_Time__r.reduivy__Study_Session__c',
                'reduivy__Start_Date_Non_TZ__c',
                'reduivy__End_Date_Non_TZ__c'
            };

            Set<String> serFields = new Set<String>{
                'Id', 
                'Name',
                'reduivy__Contact__c', 
                'reduivy__Attendance_Status__c',
                'reduivy__Individual_Session_Enrollment__c',
                'reduivy__Check_In__c',
                'reduivy__Check_Out__c',
                'reduivy__Notes__c',
                'reduivy__Relation_Name__c',
                'reduivy__Study_Event__c'
            };

            serFields.addAll(serFormFields);

            String sevSoql = 'SELECT ' + String.join(sevFields, ', ') + ', ' +
                ' ( SELECT ' + String.join(serFields, ',') + 
                    ' FROM reduivy__Study_Event_Relations__r ' +
                    ' WHERE reduivy__Individual_Session_Enrollment__r.RecordTypeId =: isnStudentRtId ) ' +
                ' FROM reduivy__Study_Event__c ' +
                ' WHERE Id =: studyEventId ' + 
                ' LIMIT 1 ';

            Map<String, Object> sevBindParams = new Map<String, Object>();
            sevBindParams.put('studyEventId', studyEventId);
            sevBindParams.put('isnStudentRtId', ISN_Helper.getStudentRecordTypeId());
            
            Map<String, Set<String>> sevObjectFieldsFls = new Map<String, Set<String>>();
            sevObjectFieldsFls.put(SEV_Helper.getApiName(), sevFields);
            sevObjectFieldsFls.put(SER_Helper.getApiName(), serFields);

            //query the study event and existing attendance records
            //Query data protected by restriction rules using system mode
            reduivy__Study_Event__c workingSev;
            for (reduivy__Study_Event__c sev : (List<reduivy__Study_Event__c>) REDU_SystemMode_UTIL.doQuery(sevSoql, sevBindParams, sevObjectFieldsFls)){
                for (reduivy__Study_Event_Relation__c ser : sev.reduivy__Study_Event_Relations__r) {
                    //loop to get all data
                }

                workingSev = sev;
            }

            if (workingSev != null) {
                Id sseId = workingSev?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__c;

                Map<String, reduivy__Study_Event_Relation__c> existingSerByIsn = new Map<String, reduivy__Study_Event_Relation__c>();
                for (reduivy__Study_Event_Relation__c existingSer : workingSev.reduivy__Study_Event_Relations__r) {
                    String isnSevKey = existingSer.reduivy__Individual_Session_Enrollment__c + '_' + existingSer.reduivy__Study_Event__c;

                    if (String.isNotBlank(isnSevKey)) {
                        existingSerByIsn.put(isnSevKey, existingSer);
                    }
                }

                if (String.isNotBlank(sseId)) {
                    Set<String> isnPositiveStatuses = new Set<String>();
                    isnPositiveStatuses.addAll(ISN_Helper.getInProgressStatuses());
                    isnPositiveStatuses.addAll(ISN_Helper.getCompletedStatuses());

                    Set<String> isnNegativeStatuses = new Set<String>();
                    isnNegativeStatuses.addAll(ISN_Helper.getWithdrawnStatuses());
                    isnNegativeStatuses.addAll(ISN_Helper.getDroppedStatuses());

                    Set<String> isnStatusesForAttendance = new Set<String>();
                    isnStatusesForAttendance.addAll(isnPositiveStatuses);
                    isnStatusesForAttendance.addAll(isnNegativeStatuses);

                    List<reduivy__Study_Event_Relation__c> serForAttendances = new List<reduivy__Study_Event_Relation__c>();

                    for (reduivy__Individual_Session_Enrollment__c studentIsn : [SELECT Id,
                        reduivy__Contact_Id__c,
                        reduivy__Enrollment_Status__c,
                        reduivy__Individual_Enrollment__c,
                        reduivy__Start_Date__c,
                        reduivy__End_Date__c,
                        reduivy__Withdrawal_Date__c
                        FROM reduivy__Individual_Session_Enrollment__c
                        WHERE  reduivy__Study_Session__c =: sseId
                        AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
                        AND reduivy__Enrollment_Status__c IN: isnStatusesForAttendance
                        WITH USER_MODE
                        ORDER BY reduivy__Individual_Enrollment__r.reduivy__Contact__r.Name ASC
                    ]){
                        Date startDate = studentIsn.reduivy__Start_Date__c == null ? workingSev.reduivy__Start_Date_Non_TZ__c : studentIsn.reduivy__Start_Date__c;
                        Date endDate = studentIsn.reduivy__End_Date__c == null ? workingSev.reduivy__End_Date_Non_TZ__c : studentIsn.reduivy__End_Date__c;

                        if (isnNegativeStatuses.contains(studentIsn.reduivy__Enrollment_Status__c))  {
                            //we will skip the withdrawn/dropped students if there is no withdrawl date specified as we won't know whether to list the students or not for the study event
                            //as the student may leave half way through the study and we still want to show the historical attendance
                            if (studentIsn.reduivy__Withdrawal_Date__c == null) {
                                continue;
                            } else {
                                endDate = studentIsn.reduivy__Withdrawal_Date__c;
                            }
                        }

                        //we only list the students that fall within the event start/end
                        if (startDate <= workingSev.reduivy__Start_Date_Non_TZ__c && endDate >= workingSev.reduivy__End_Date_Non_TZ__c) {

                            String isnSevKey = studentIsn.Id + '_' + workingSev.Id;

                            if (existingSerByIsn.containsKey(isnSevKey)) {
                                //add the existing ser to the response list
                                serForAttendances.add(existingSerByIsn.get(isnSevKey));
                            } else {
                                //init a new ser and add to response list
                                reduivy__Study_Event_Relation__c newSer = new reduivy__Study_Event_Relation__c(
                                    reduivy__Contact__c = studentIsn.reduivy__Contact_Id__c,
                                    reduivy__Attendance_Status__c = null,
                                    reduivy__Individual_Session_Enrollment__c = studentIsn.Id,
                                    reduivy__Study_Event__c = workingSev.Id,
                                    reduivy__Notes__c = null,
                                    reduivy__Check_In__c = null,
                                    reduivy__Check_Out__c = null
                                );

                                serForAttendances.add(newSer);
                            }
                        }
                    }

                    //Refresh the reduivy__Relation_Name__c formula field value so that we can use it as quick search
                    List<System.FormulaRecalcResult> formulaResults = System.Formula.recalculateFormulas(serForAttendances);
                    for (System.FormulaRecalcResult fr : formulaResults) {
                        if (!fr.isSuccess()) {
                            throw new REDU_ApplicationException(fr.getErrors()[0].getFieldName() + ' - ' + fr.getErrors()[0].getFieldError());
                        }
                    }

                    REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(serForAttendances));
                    return response;

                } else {
                    throw new REDU_ApplicationException(String.format(Label.Missing_Info_For_Record, new List<String>{SSE_Helper.getObjectLabel(), SEV_Helper.getObjectLabel(), workingSev.Id}));
                }

            } else {
                throw new REDU_ApplicationException(String.format(Label.Invalid_Record_Id, new List<String>{studyEventId}));
            }

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    @AuraEnabled
    public static REDU_LightningResponse saveStudentAttendances(String studentAttendancesData){

        Savepoint sp = Database.setSavePoint();

        try {
            if (String.isNotBlank(studentAttendancesData)) {
                List<reduivy__Study_Event_Relation__c> studentAttendances = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(studentAttendancesData, List<reduivy__Study_Event_Relation__c>.class);

                //Update attendance data protected by restriction rules using system mode
                REDU_SystemMode_UTIL.doUpsert(studentAttendances);

                return new REDU_LightningResponse(true, Label.Your_Changes_Are_Saved, JSON.serialize(studentAttendances));
            }

            return new REDU_LightningResponse(true, Label.Your_Changes_Are_Saved, null);

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