/**
 * @author      WDCi (CM)
 * @date        Aug 2024
 * @group       Grade Management
 * @description Student Grading Wizard - List of Study Offerings and Study Sessions to grade
 * @changehistory
 * ISS-001918 01-08-2024 CM - new class
 * ISS-002245 13-01-2025 XiRouh - update the logic to support showRecordsBasedOnAllocation attribute
 */
public with sharing class REDU_StudentGrading_LCTRL {
    
    /**
     * @description Get any Study Offerings and Study Sessions for the given date
     * @param contactId Faculty user to find related Study Offerings/Sessions for
     * @param filterDate finds any records matching this Date
     * @param showNoGradeWarning Adds a warning indicator if grades have not been given
     * @param validStudentIenStatus Student enrollment statuses to consider for Individual Enrollments in a semi-colon (;) delimited list
     * @param validStudentIsnStatus Student enrollment statuses to consider for Individual Session Enrollments in a semi-colon (;) delimited list
     * @param validFacultyIenStatus Faculty enrollment statuses to consider for Individual Enrollments in a semi-colon (;) delimited list
     * @param validFacultyIsnStatus Faculty enrollment statuses to consider for Individual Session Enrollments in a semi-colon (;) delimited list
     * @param sofListingNameField Heading for a Study Offering listing. Defaults to Name
     * @param sofListingInfoFields Description fields for a Study Offering listing. Defaults to reduivy__Description__c
     * @param sseListingNameField Heading for a Study Session listing. Defaults to Name
     * @param sseListingInfoFields Description fields for a Study Session listing. Defaults to reduivy__Description__c
     * @return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse getListings(
        String contactId, Date filterDate, Boolean showNoGradeWarning, 
        String validStudentIenStatus, String validStudentIsnStatus, String validFacultyIenStatus, String validFacultyIsnStatus,
        String sofListingNameField, String sofListingInfoFields, String sseListingNameField, String sseListingInfoFields, Boolean showRecordsBasedOnAllocation
    ){

        try {
            List<ListingWrapper> listingWrappers = new List<ListingWrapper>();

            //Find current user's Contact
            if(String.isBlank(contactId)){
                Contact currentContact = CON_Helper.getCurrentLoggedInUserContact();
                if(currentContact != null){
                    contactId = currentContact.Id;
                }
            }

            if(String.isNotBlank(contactId)){

                String isnFacultyRtId = ISN_Helper.getFacultyRecordTypeId();
                String ienFacultyRtId = IEN_Helper.getFacultyRecordTypeId();
                String isnStudentRtId = ISN_Helper.getStudentRecordTypeId();
                String ienStudentRtId = IEN_Helper.getStudentRecordTypeId();
                Set<String> ienFacultyEnrollmentStatuses = String.isNotBlank(validFacultyIenStatus) ? new Set<String>(validFacultyIenStatus.split(';')) : new Set<String>();
                Set<String> isnFacultyEnrollmentStatuses = String.isNotBlank(validFacultyIsnStatus) ? new Set<String>(validFacultyIsnStatus.split(';')) : new Set<String>();
                Set<String> ienStudentEnrollmentStatuses = String.isNotBlank(validStudentIenStatus) ? new Set<String>(validStudentIenStatus.split(';')) : new Set<String>();
                Set<String> isnStudentEnrollmentStatuses = String.isNotBlank(validStudentIsnStatus) ? new Set<String>(validStudentIsnStatus.split(';')) : new Set<String>();

                Set<Id> allStudyOfferingIds = new Set<Id>();
                Set<Id> gradingStudyOfferingIds = new Set<Id>();
                Set<Id> gradingStudySessionIds = new Set<Id>();
                Set<Id> termIds = new Set<Id>();

                //Default to today's date if no filter date is specified
                if(filterDate == null){
                    filterDate = System.today();
                }

                //Find available Faculty IEN and ISN enrollments
                for (reduivy__Individual_Enrollment__c ien : [
                    SELECT Id, 
                    reduivy__Study_Offering__c, 
                    reduivy__Study_Offering__r.reduivy__Grade_By__c, 
                    reduivy__Study_Offering__r.reduivy__Academic_Term__c
                    FROM reduivy__Individual_Enrollment__c
                    WHERE reduivy__Contact__c = :contactId 
                    AND RecordTypeId = :ienFacultyRtId
                    AND reduivy__Enrollment_Status__c IN :ienFacultyEnrollmentStatuses
                    AND reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c <= :filterDate
                    AND reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c >= :filterDate
                    WITH USER_MODE
                ]){
                    allStudyOfferingIds.add(ien.reduivy__Study_Offering__c);

                    //Only display the Study Offering if we're grading by Study Offering
                    if (ien.reduivy__Study_Offering__r.reduivy__Grade_By__c == SOF_Helper.GRADE_BY_STUDYOFFERING){
                        gradingStudyOfferingIds.add(ien.reduivy__Study_Offering__c);
                    }

                    if (String.isNotBlank(ien.reduivy__Study_Offering__r.reduivy__Academic_Term__c)){
                        termIds.add(ien.reduivy__Study_Offering__r.reduivy__Academic_Term__c);
                    }
                }

                List<reduivy__Individual_Session_Enrollment__c> initialIndividualSessionEnrollment = [
                    SELECT Id, 
                    reduivy__Study_Session__c, 
                    reduivy__Study_Session__r.reduivy__Study_Offering__c,
                    reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Academic_Term__c
                    FROM reduivy__Individual_Session_Enrollment__c
                    WHERE reduivy__Contact_Id__c = :contactId 
                    AND RecordTypeId = :isnFacultyRtId
                    AND reduivy__Enrollment_Status__c IN :isnFacultyEnrollmentStatuses
                    AND reduivy__Study_Session__r.reduivy__Start_Date_Calculated__c <= :filterDate
                    AND reduivy__Study_Session__r.reduivy__End_Date_Calculated__c >= :filterDate
                    WITH USER_MODE
                ];

                Set<Id> individualSessionEnrollmentIds = new Set<Id>();
                Set<Id> iseIdsWithSer = new Set<Id>();

                for(reduivy__Individual_Session_Enrollment__c isn : initialIndividualSessionEnrollment) {
                    individualSessionEnrollmentIds.add(isn.Id);
                }

                if(showRecordsBasedOnAllocation == true) {
                    //Query the Study Event Relation that looks up to the above queried reduivy__Individual_Session_Enrollment__c
                    List<reduivy__Study_Event_Relation__c> sers = [
                        SELECT Id,
                        reduivy__Individual_Session_Enrollment__c
                        FROM reduivy__Study_Event_Relation__c 
                        WHERE reduivy__Individual_Session_Enrollment__c IN :individualSessionEnrollmentIds
                        AND reduivy__Contact__c = :contactId
                        WITH USER_MODE
                    ];

                    for(reduivy__Study_Event_Relation__c ser : sers) {
                        iseIdsWithSer.add(ser.reduivy__Individual_Session_Enrollment__c);
                    }

                    for(reduivy__Individual_Session_Enrollment__c isn : initialIndividualSessionEnrollment) {
                        if(iseIdsWithSer.contains(isn.Id)) {
                            if (!gradingStudyOfferingIds.contains(isn.reduivy__Study_Session__r.reduivy__Study_Offering__c)){
                                gradingStudySessionIds.add(isn.reduivy__Study_Session__c);
                                if (String.isNotBlank(isn.reduivy__Study_Session__r.reduivy__Study_Offering__c)){
                                    allStudyOfferingIds.add(isn.reduivy__Study_Session__r.reduivy__Study_Offering__c);
                                    if (String.isNotBlank(isn.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Academic_Term__c)){
                                        //Track Term for Study Grade Period Setting
                                        termIds.add(isn.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Academic_Term__c);
                                    }
                                }
                            }
                        }
                    }
                } else {
                    for (reduivy__Individual_Session_Enrollment__c isn : initialIndividualSessionEnrollment){
                        //Only display the Study Session if we're not displaying the Study Offering
                        if (!gradingStudyOfferingIds.contains(isn.reduivy__Study_Session__r.reduivy__Study_Offering__c)){
                            gradingStudySessionIds.add(isn.reduivy__Study_Session__c);
                            if (String.isNotBlank(isn.reduivy__Study_Session__r.reduivy__Study_Offering__c)){
                                allStudyOfferingIds.add(isn.reduivy__Study_Session__r.reduivy__Study_Offering__c);
                                if (String.isNotBlank(isn.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Academic_Term__c)){
                                    //Track Term for Study Grade Period Setting
                                    termIds.add(isn.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Academic_Term__c);
                                }
                            }
                        }
                    }
                }

                //Setup default listing fields
                if(String.isBlank(sofListingNameField)){
                    sofListingNameField = 'Name';
                }

                if(String.isBlank(sseListingNameField)){
                    sseListingNameField = 'Name';
                }
                
                Set<String> studyOfferingFields = new Set<String>{'Id'};
                studyOfferingFields.add('reduivy__Study_Unit__r.reduivy__Background_Colour__c'); //Background colour
                
                Set<String> studySessionFields = new Set<String>{'Id'};
                studySessionFields.add('reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Background_Colour__c'); //Background colour
                studySessionFields.add('reduivy__Background_Colour__c'); //Background colour

                //Get grading period for warning indicator logic
                Map<Id, Id> sofIdToSgpIdMap = new Map<Id, Id>();
                Map<Id, Id> termIdToSgpIdMap = new Map<Id, Id>();
                Set<String> igdKeys = new Set<String>(); //Set of Individual Enrollment Grades used to check if appropriate grade exists for each student
                if (showNoGradeWarning){
                    //Need Term fields for finding the Study Grade Period Setting
                    studySessionFields.add('reduivy__Study_Offering__r.reduivy__Academic_Term__c');
                    studyOfferingFields.add('reduivy__Academic_Term__c');

                    //Get Study Grade Period Settings related to either the Study Offerings or Academic Terms
                    List<reduivy__Study_Grade_Period_Setting__c> studyGradePeriodSettingList = [
                        SELECT Id, 
                        reduivy__Academic_Term__c, 
                        reduivy__Study_Offering__c, 
                        reduivy__Start_Date__c, 
                        reduivy__End_Date__c
                        FROM reduivy__Study_Grade_Period_Setting__c
                        WHERE reduivy__Status__c =: SGP_Helper.STATUS_ACTIVE AND
                        (reduivy__Academic_Term__c IN :termIds 
                        OR reduivy__Study_Offering__c IN :allStudyOfferingIds)
                        WITH USER_MODE
                        ORDER BY reduivy__End_Date__c DESC
                    ];

                    //Find default Study Grade Period Setting for each Study Offering
                    for (reduivy__Study_Grade_Period_Setting__c sgp : studyGradePeriodSettingList){
                        //Set for Study Offering
                        if (String.isNotBlank(sgp.reduivy__Study_Offering__c)){
                            //If dates match, or if we don't have a default date yet, set it as the default date
                            if (!sofIdToSgpIdMap.containsKey(sgp.reduivy__Study_Offering__c)
                            || (sgp.reduivy__Start_Date__c <= filterDate && sgp.reduivy__End_Date__c >= filterDate)){
                                sofIdToSgpIdMap.put(sgp.reduivy__Study_Offering__c, sgp.Id);
                            }
                        }

                        //Set for Term (is a fallback if one isn't provided for Study Offering)
                        if (String.isNotBlank(sgp.reduivy__Academic_Term__c)){
                            //If dates match, or if we don't have a default date yet, set it as the default date
                            if (!termIdToSgpIdMap.containsKey(sgp.reduivy__Academic_Term__c)
                            || (sgp.reduivy__Start_Date__c <= filterDate && sgp.reduivy__End_Date__c >= filterDate)){
                                termIdToSgpIdMap.put(sgp.reduivy__Academic_Term__c, sgp.Id);
                            }
                        }
                    }

                    //Get student Individual Enrollment Grades
                    for (reduivy__Individual_Enrollment_Grade__c igd : [
                        SELECT Id, 
                        reduivy__Individual_Enrollment__c, 
                        reduivy__Study_Offering__c, 
                        reduivy__Study_Grade_Period_Setting__c
                        FROM reduivy__Individual_Enrollment_Grade__c
                        WHERE reduivy__Study_Offering__c IN :allStudyOfferingIds
                        WITH USER_MODE
                    ]){
                        if (String.isNotBlank(igd.reduivy__Individual_Enrollment__c)
                            && String.isNotBlank(igd.reduivy__Study_Offering__c)
                            && String.isNotBlank(igd.reduivy__Study_Grade_Period_Setting__c)
                        ){
                            String igdKey = igd.reduivy__Individual_Enrollment__c + '_' + igd.reduivy__Study_Offering__c + '_' + igd.reduivy__Study_Grade_Period_Setting__c;
                            igdKeys.add(igdKey);
                        }   
                    }
                }

                //Grade By = Study Session
                List<String> uniqueStudySessionFields = new List<String>(studySessionFields);
                Map<String, Object> sseBindParams = new Map<String, Object>();
                String studySessionSoql = 'SELECT ' + String.join(uniqueStudySessionFields, ',');

                if (showNoGradeWarning){
                    //Need to include student enrollments for grade referencing
                    studySessionSoql += ', (SELECT Id, reduivy__Individual_Enrollment__c '
                        + 'FROM reduivy__Individual_Session_Enrollments__r '
                        + 'WHERE RecordTypeId = :isnStudentRtId AND reduivy__Enrollment_Status__c IN :isnStudentEnrollmentStatuses)';
                    sseBindParams.put('isnStudentRtId', isnStudentRtId);
                    sseBindParams.put('isnStudentEnrollmentStatuses', isnStudentEnrollmentStatuses);
                }

                studySessionSoql += ' FROM reduivy__Study_Session__c WHERE Id IN :gradingStudySessionIds '
                    + 'ORDER BY reduivy__Start_Date_Calculated__c DESC'; //Maybe this should be Name?

                sseBindParams.put('gradingStudySessionIds', gradingStudySessionIds);

                for(reduivy__Study_Session__c sse : (List<reduivy__Study_Session__c>) Database.queryWithBinds(studySessionSoql, sseBindParams, AccessLevel.USER_MODE)){
                    
                    //Setup ListingWrapper object to return
                    ListingWrapper sseLw = new ListingWrapper();
                    sseLw.id = sse.Id;
                    sseLw.nameField = sseListingNameField;
                    sseLw.infoFields = sseListingInfoFields;
                    sseLw.backgroundColour = String.isNotBlank(sse.reduivy__Background_Colour__c)
                        ? sse.reduivy__Background_Colour__c
                        : sse.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Background_Colour__c;
                    sseLw.sObjectName = SSE_Helper.getApiName();

                    //Find out if all students have been graded for the current study grade period
                    if (showNoGradeWarning){
                        
                        Boolean gradesGiven = true;
                        String currentStudyGradePeriod;

                        //Find default grading period map
                        if (sofIdToSgpIdMap.containsKey(sse.reduivy__Study_Offering__c)){
                            currentStudyGradePeriod = sofIdToSgpIdMap.get(sse.reduivy__Study_Offering__c);
                        } else if (termIdToSgpIdMap.containsKey(sse.reduivy__Study_Offering__r.reduivy__Academic_Term__c)){
                            currentStudyGradePeriod = termIdToSgpIdMap.get(sse.reduivy__Study_Offering__r.reduivy__Academic_Term__c);
                        }

                        if (String.isNotBlank(currentStudyGradePeriod) && String.isNotBlank(sse.reduivy__Study_Offering__c)){
                            //Determine igdKey
                            String igdKeySuffix = '_' + sse.reduivy__Study_Offering__c + '_' + currentStudyGradePeriod;

                            //Check/map student term grades
                            for (reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){
                                String igdKey = isn.reduivy__Individual_Enrollment__c + igdKeySuffix;
                                if (!igdKeys.contains(igdKey)){
                                    gradesGiven = false;
                                    break;
                                }
                            }
                        }
                        
                        sseLw.showNoGradeWarning = !gradesGiven;

                    }

                    listingWrappers.add(sseLw);
                }

                //Grade By = Study Offering
                List<String> uniqueSofFields = new List<String>(studyOfferingFields);
                Map<String, Object> sofBindParams = new Map<String, Object>();
                String sofSoql = 'SELECT ' + String.join(uniqueSofFields, ',');
                if (showNoGradeWarning){
                    //Need to include student enrollments for grade referencing
                    sofSoql += ', (SELECT Id '
                        + 'FROM reduivy__Individual_Enrollments__r '
                        + 'WHERE RecordTypeId = :ienStudentRtId AND reduivy__Enrollment_Status__c IN :ienStudentEnrollmentStatuses)';
                    sofBindParams.put('ienStudentRtId', ienStudentRtId);
                    sofBindParams.put('ienStudentEnrollmentStatuses', ienStudentEnrollmentStatuses);
                }
                
                sofSoql += ' FROM reduivy__Study_Offering__c WHERE Id IN :gradingStudyOfferingIds '
                    + 'ORDER BY reduivy__Start_Date_Calculated__c DESC';
                
                sofBindParams.put('gradingStudyOfferingIds', gradingStudyOfferingIds);
                
                for (reduivy__Study_Offering__c sof : (List<reduivy__Study_Offering__c>) Database.queryWithBinds(sofSoql, sofBindParams, AccessLevel.USER_MODE)){
                    
                    //Setup ListingWrapper object to return
                    ListingWrapper sofLw = new ListingWrapper();
                    sofLw.id = sof.Id;
                    sofLw.nameField = sofListingNameField;
                    sofLw.infoFields = sofListingInfoFields;
                    sofLw.backgroundColour = sof.reduivy__Study_Unit__r.reduivy__Background_Colour__c;
                    sofLw.sObjectName = SOF_Helper.getApiName();

                    //Find out if all students have been graded for the current study grade period
                    if (showNoGradeWarning){
                        
                        Boolean gradesGiven = true;
                        String currentStudyGradePeriod;

                        //Find default grading period map
                        if (sofIdToSgpIdMap.containsKey(sof.Id)){
                            currentStudyGradePeriod = sofIdToSgpIdMap.get(sof.Id);
                        } else if (termIdToSgpIdMap.containsKey(sof.reduivy__Academic_Term__c)){
                            currentStudyGradePeriod = termIdToSgpIdMap.get(sof.reduivy__Academic_Term__c);
                        }

                        if (String.isNotBlank(currentStudyGradePeriod)){
                            //Determine igdKey
                            String igdKeySuffix = '_' + sof.Id + '_' + currentStudyGradePeriod;

                            //Check/map student term grades
                            for (reduivy__Individual_Enrollment__c ien : sof.reduivy__Individual_Enrollments__r){
                                String igdKey = ien.Id + igdKeySuffix;
                                if (!igdKeys.contains(igdKey)){
                                    gradesGiven = false;
                                    break;
                                }
                            }
                        }
                        
                        sofLw.showNoGradeWarning = !gradesGiven;

                    }

                    listingWrappers.add(sofLw);
                }
            }

            //Return the list of selectable Study Offerings/Study Sessions
            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(listingWrappers));
            return response;

        } catch (QueryException qex){
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }

    }

    public class ListingWrapper {

        @AuraEnabled public String nameField {get; set;}
        @AuraEnabled public String infoFields {get; set;}
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String backgroundColour {get;set;}
        @AuraEnabled public Boolean showNoGradeWarning {get;set;}
        @AuraEnabled public String sObjectName {get;set;} //Expected values are reduivy__Study_Offering__c or reduivy__Study_Session__c
        
        public ListingWrapper(){
            this.showNoGradeWarning = false;
        }
    }
    
}