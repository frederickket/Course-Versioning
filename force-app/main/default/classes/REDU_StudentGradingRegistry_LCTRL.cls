/**
 * @author      WDCi (CM)
 * @date        Aug 2024
 * @group       Grade Management
 * @description Student Grading Wizard - Grading students for the selected record
 * @changehistory
 * ISS-001918 06-08-2024 CM - new class
 * ISS-002261 08-03-2025 Jordan - strip inaccessible fields before upsert
 * ISS-002257 29-01-2025 Jordan - allow admin to lock/unlock a grading period setting and individual enrollment grade
 * ISS-002259 20-03-2025 Jordan - allow admin to configure more fields in the note screen
 */
public with sharing class REDU_StudentGradingRegistry_LCTRL {

    /**
    * @description ISS-002259 Get fields
    * @param fieldSetName Field set name
    * @param objectName Object name
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
    * @description Get Study Session/Study Offering info and StudentWrappers to grade
    * @param recordId Study Session/Study Offering Id to get info for
    * @param sObjectName denotes if this is grading for a Study Session or Study Offering
    * @param gradingPeriod The selected grading period id
    * @param validStudentIenStatus Student Individual Enrollment Statuses to search for
    * @param validStudentIsnStatus Student Individual Session Enrollment Statuses to search for (Study Session only)
    * @param individualEnrollmentGradeFieldSet Fieldset api name of extra fields to mark on the Individual Enrollment Grades
    * @param individualGradeItemNotesFieldSetName ISS-002259 Fieldset api name of additional fields in the notes screen
    * @return REDU_LightningResponse
    */    
    @AuraEnabled
    public static REDU_LightningResponse getGradingData(
        String recordId, String sObjectName, 
        String gradingPeriod, 
        String validStudentIenStatus, String validStudentIsnStatus,
        String individualEnrollmentGradeFieldSet,
        String individualGradeItemNotesFieldSetName
    ){

        try {

            //Separate Study Offering for easier access across both object types
            reduivy__Study_Offering__c studyOffering;
            reduivy__Study_Session__c studySession;

            if (sObjectName == SSE_Helper.getApiName()){
                //Get Study Session info
                studySession = getStudySessionInfo(recordId);
                //Get Study Offering from Session
                studyOffering = studySession.reduivy__Study_Offering__r;
            } else if (sObjectName == SOF_Helper.getApiName()){
                //Query Study Offering directly
                studyOffering = getStudyOfferingInfo(recordId);
            } else {
                //Invalid object
                String objectNames = String.join(new List<String>{SOF_Helper.getObjectLabel(), SSE_Helper.getObjectLabel()}, ', ');
                throw new REDU_ApplicationException(String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{recordId, objectNames}));
            }

            //Determine the grading period here
            reduivy__Study_Grade_Period_Setting__c targetSgp;
            Set<Id> termIds = new Set<Id>();
            termIds.add(studyOffering.reduivy__Academic_Term__c);

            List<reduivy__Study_Grade_Period_Setting__c> sgpList = [
                SELECT Id, 
                Name, 
                reduivy__Academic_Term__c, 
                reduivy__Study_Offering__c, 
                reduivy__Start_Date__c, 
                reduivy__End_Date__c,
                reduivy__Locking_Mode__c
                FROM reduivy__Study_Grade_Period_Setting__c
                WHERE reduivy__Status__c =: SGP_Helper.STATUS_ACTIVE AND 
                (reduivy__Academic_Term__c IN :termIds 
                OR reduivy__Study_Offering__c = :studyOffering.Id)
                WITH USER_MODE
                ORDER BY reduivy__End_Date__c DESC
            ];

            //If we've set any Study Grade Period Settings against the Study Offering, use only those ones
            List<reduivy__Study_Grade_Period_Setting__c> sofStudyGradePeriodSettingList = new List<reduivy__Study_Grade_Period_Setting__c>();
            for (reduivy__Study_Grade_Period_Setting__c sgp : sgpList){
                if (sgp.reduivy__Study_Offering__c == studyOffering.Id){
                    sofStudyGradePeriodSettingList.add(sgp);
                }

                if (sgp.Id == gradingPeriod){
                    targetSgp = sgp;
                }
            }

            if (!sofStudyGradePeriodSettingList.isEmpty()){
                sgpList = sofStudyGradePeriodSettingList;
            }

            //If no Study Grade Period Setting was selected, find the appropriate one based on the filter date
            if (targetSgp == null){
                for (reduivy__Study_Grade_Period_Setting__c sgp : sgpList){
                    if (targetSgp == null //Will ensure we set the first one if possible
                        || (sgp.reduivy__Start_Date__c <= System.today() && sgp.reduivy__End_Date__c >= System.today())
                    ){
                        targetSgp = sgp;
                    }
                }
            }

            //If there's still no Study Grade Period Setting, throw an error
            if (targetSgp == null){
                throw new REDU_ApplicationException(String.format(Label.No_Object_found, new List<String>{SGP_Helper.getObjectLabel()}));
            }

            //Get Study Grade Items
            List<reduivy__Study_Grade_Item__c> sgiList = [
                SELECT Id, 
                Name, 
                reduivy__Parent_Grade_Item__c, 
                reduivy__Weight__c, 
                reduivy__Display_Type__c,
                (
                    SELECT Id, 
                    Name, 
                    reduivy__Parent_Grade_Item__c, 
                    reduivy__Weight__c, 
                    reduivy__Display_Type__c, 
                    reduivy__Parent_Grade_Item__r.reduivy__Weight__c
                    FROM reduivy__Child_Grade_Items__r
                    ORDER BY reduivy__Sequence__c ASC
                ) 
                FROM reduivy__Study_Grade_Item__c
                WHERE reduivy__Study_Unit__c = :studyOffering.reduivy__Study_Unit__c 
                AND reduivy__Parent_Grade_Item__c = null
                WITH USER_MODE
                ORDER BY reduivy__Sequence__c ASC
            ];

            if (sgiList.isEmpty()) {
                //Not able to display grading table as there is no study grade items found.
                throw new REDU_ApplicationException(String.format(Label.No_Object_found, new List<String>{SGI_Helper.getObjectPluralLabel()}));
            }

            Set<Id> hiddenParentSgis = new Set<Id>();
            //Populate table columns in lightning component
            List<StudyGradeItemWrapper> tableColumnSgiList = new List<StudyGradeItemWrapper>();
            for (reduivy__Study_Grade_Item__c sgi : sgiList){
                //Parent Study Grade Items with children should be hidden - showing only the children.
                if (!sgi.reduivy__Child_Grade_Items__r.isEmpty()){
                    hiddenParentSgis.add(sgi.Id);
                    tableColumnSgiList.add(new StudyGradeItemWrapper(sgi, true));

                    for (reduivy__Study_Grade_Item__c childSgi : sgi.reduivy__Child_Grade_Items__r){
                        tableColumnSgiList.add(new StudyGradeItemWrapper(childSgi, false));
                    }
                } else {
                    tableColumnSgiList.add(new StudyGradeItemWrapper(sgi, false));
                }
            }

            //Get Study Grading Schemes (for marking Grades)
            //Handle Study Grading Scheme query later because different students might have different grading schemes
            Set<Id> studyGradeSettingIds = new Set<Id>();
            //Need to find study offering's default Study Grade Setting
            String defaultSgsId = String.isNotBlank(studyOffering.reduivy__Study_Grade_Setting__c) 
                ? studyOffering.reduivy__Study_Grade_Setting__c 
                : studyOffering.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c;
            
            studyGradeSettingIds.add(defaultSgsId);            

            //Get Student Individual Enrollments
            Set<String> ienQueryFields = new Set<String>{
                'Id', 
                'reduivy__Study_Offering__c', 
                'reduivy__Study_Grade_Setting__c', 
                'reduivy__Contact__c', 
                'reduivy__Contact__r.Name', 
                'reduivy__Contact__r.LastName'
            };

            //Get Individual Enrollments through either IEN or ISN
            List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
            String ienStudentRtId = IEN_Helper.getStudentRecordTypeId();
            List<String> ienStatuses = String.isNotBlank(validStudentIenStatus) ? validStudentIenStatus.split(';') : new List<String>();
            
            Map<String, Object> ienBindParams = new Map<String, Object>();
            ienBindParams.put('ienStudentRtId', ienStudentRtId);
            ienBindParams.put('ienStatuses', ienStatuses);

            //Study Session - Filter by ISN
            if (sObjectName == SSE_Helper.getApiName()){
                //Filter students by Individual Session Enrollment
                List<String> isnStatuses = String.isNotBlank(validStudentIsnStatus) ? validStudentIsnStatus.split(';') : new List<String>();
                String isnStudentRtId = ISN_Helper.getStudentRecordTypeId();
                Set<Id> filteredIenIds = new Set<Id>();

                //Search Individual Session Enrollments separately so we can filter based on certain criteria
                for (reduivy__Individual_Session_Enrollment__c isn : [
                    SELECT Id, 
                    reduivy__Individual_Enrollment__c
                    FROM reduivy__Individual_Session_Enrollment__c
                    WHERE reduivy__Study_Session__c = :recordId 
                    AND RecordTypeId = :isnStudentRtId
                    AND reduivy__Enrollment_Status__c IN :isnStatuses
                    WITH USER_MODE
                ]){
                    if (String.isNotBlank(isn.reduivy__Individual_Enrollment__c)){
                        filteredIenIds.add(isn.reduivy__Individual_Enrollment__c);
                    }
                }

                //Query Individual Enrollments
                String ienQueryString = 'SELECT ' + String.join((Iterable<String>) ienQueryFields, ', ')
                    + ' FROM reduivy__Individual_Enrollment__c '
                    + 'WHERE Id IN :filteredIenIds AND reduivy__Enrollment_Status__c IN :ienStatuses AND RecordTypeId = :ienStudentRtId '
                    + 'ORDER BY reduivy__Contact__r.Name ASC';

                ienBindParams.put('filteredIenIds', filteredIenIds);

                for (reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) Database.queryWithBinds(ienQueryString, ienBindParams, AccessLevel.USER_MODE)) {
                    ienList.add(ien);
                }

            } else {
                //Filter students by Individual Enrollment
                String ienQueryString = 'SELECT ' + String.join((Iterable<String>) ienQueryFields, ', ')
                    + ' FROM reduivy__Individual_Enrollment__c '
                    + 'WHERE reduivy__Study_Offering__c = :recordId AND reduivy__Enrollment_Status__c IN :ienStatuses AND RecordTypeId = :ienStudentRtId '
                    + 'ORDER BY reduivy__Contact__r.Name ASC';

                ienBindParams.put('recordId', recordId);

                for (reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) Database.queryWithBinds(ienQueryString, ienBindParams, AccessLevel.USER_MODE)) {
                    ienList.add(ien);
                }
                
            }
            
            //Find existing Individual Enrollment Grade and Individual Grade Item records for Individual Enrollments
            Map<Id, reduivy__Individual_Enrollment_Grade__c> ienToIgdMap = new Map<Id, reduivy__Individual_Enrollment_Grade__c>();
            List<StudentWrapper> studentWrappers = new List<StudentWrapper>();
            List<reduivy__Individual_Enrollment_Grade__c> existingIgdList = new List<reduivy__Individual_Enrollment_Grade__c>();

            List<String> igdFields = new List<String>{
                'Id', 
                'reduivy__Individual_Enrollment__c', 
                'reduivy__Academic_Term__c', 
                'reduivy__Contact__c', 
                'reduivy__Notes__c', 
                'reduivy__Status__c', 
                'reduivy__Study_Grade_Period_Setting__c', 
                'reduivy__Study_Offering__c', 
                'reduivy__Locking_Mode_Override__c'
            };
            
            //Get custom Individual Enrollment Grade fields
            if (String.isNotBlank(individualEnrollmentGradeFieldSet)){
                //Need to use a set in case duplicate fields are added through field set
                Set<String> igdFieldsSet = new Set<String>();
                igdFieldsSet.addAll(igdFields);
                igdFieldsSet.addAll(REDU_Metadata_UTIL.getFields('reduivy__Individual_Enrollment_Grade__c', individualEnrollmentGradeFieldSet, false));
                
                //Replace list with de-duplicated list via set
                igdFields = new List<String>();
                igdFields.addAll(igdFieldsSet);
            }
            
            //Filter by Term
            String termId = studyOffering.reduivy__Academic_Term__c;

            String igdSoql = 'SELECT ' + String.join(igdFields, ', ') 
                + ' FROM reduivy__Individual_Enrollment_Grade__c ' 
                + ' WHERE reduivy__Individual_Enrollment__c IN :ienList ' 
                + ' AND reduivy__Academic_Term__c = :termId ' 
                + ' AND reduivy__Study_Grade_Period_Setting__c = :targetSgpId ';
            Map<String, Object> igdBindParams = new Map<String, Object>();
            igdBindParams.put('ienList', ienList);
            igdBindParams.put('termId', termId);
            igdBindParams.put('targetSgpId', targetSgp.Id);

            for(reduivy__Individual_Enrollment_Grade__c igd : (List<reduivy__Individual_Enrollment_Grade__c>) Database.queryWithBinds(igdSoql, igdBindParams, AccessLevel.USER_MODE)) {
                existingIgdList.add(igd);
            }

            //Individual Grade Item
            Set<String> igiFields = new Set<String>{
                'Id', 
                'Name', 
                'reduivy__Individual_Enrollment_Grade__c', 
                'reduivy__Weight__c', 
                'reduivy__Study_Grade_Item__c', 
                'reduivy__Parent_Grade_Item__c', 
                'reduivy__Letter_Grade__c', 
                'reduivy__Numerical_Grade__c',
                'reduivy__Status__c'
            };

            //Get custom Individual Grade Item fields
            if (String.isNotBlank(individualGradeItemNotesFieldSetName)){
                igiFields.addAll(REDU_Metadata_UTIL.getFields('reduivy__Individual_Grade_Item__c', individualGradeItemNotesFieldSetName, false));
            }

            String igiSoql = 'SELECT ' + String.join(igiFields, ', ') 
                + ' FROM reduivy__Individual_Grade_Item__c ' 
                + ' WHERE reduivy__Individual_Enrollment_Grade__c IN :existingIgdList ' 
                + ' ORDER BY reduivy__Study_Grade_Item__r.reduivy__Sequence__c ASC ';
            Map<String, Object> igiBindParams = new Map<String, Object>();
            igiBindParams.put('existingIgdList', existingIgdList);

            Map<Id, List<reduivy__Individual_Grade_Item__c>> existingIgiByIgd = new Map<Id, List<reduivy__Individual_Grade_Item__c>>();
            for(reduivy__Individual_Grade_Item__c igi : (List<reduivy__Individual_Grade_Item__c>) Database.queryWithBinds(igiSoql, igiBindParams, AccessLevel.USER_MODE)) {
                if(existingIgiByIgd.containsKey(igi.reduivy__Individual_Enrollment_Grade__c)){
                    existingIgiByIgd.get(igi.reduivy__Individual_Enrollment_Grade__c).add(igi);
                } else {
                    existingIgiByIgd.put(igi.reduivy__Individual_Enrollment_Grade__c, new List<reduivy__Individual_Grade_Item__c>{igi});
                }
            }

            //Populate existing maps
            for (reduivy__Individual_Enrollment_Grade__c igd : existingIgdList){
                ienToIgdMap.put(igd.reduivy__Individual_Enrollment__c, igd);
            }

            for (reduivy__Individual_Enrollment__c ien : ienList){

                //Create new, blank Individual Enrollment Grade and Individual Grade Item records if needed
                List<reduivy__Individual_Grade_Item__c> igiGrades = new List<reduivy__Individual_Grade_Item__c>();
                reduivy__Individual_Enrollment_Grade__c igd = new reduivy__Individual_Enrollment_Grade__c();

                if (!ienToIgdMap.containsKey(ien.Id)){
                    //New Individual Enrollment Grade
                    igd.reduivy__Individual_Enrollment__c = ien.Id;
                    igd.reduivy__Academic_Term__c = studyOffering.reduivy__Academic_Term__c;
                    igd.reduivy__Contact__c = ien.reduivy__Contact__c;
                    igd.reduivy__Study_Grade_Period_Setting__c = targetSgp.Id;
                    igd.reduivy__Study_Offering__c = studyOffering.Id;
                    
                    ienToIgdMap.put(ien.Id, igd);
                } else {
                    //Existing Individual Enrollment Grade
                    igd = ienToIgdMap.get(ien.Id);

                    //Existing Individual Grade Items
                    if(existingIgiByIgd.containsKey(igd.Id)){
                        igiGrades = existingIgiByIgd.get(igd.Id);
                    }
                }

                //Track which Study Grade Items have been graded already
                Map<String, reduivy__Individual_Grade_Item__c> igiBySgiId = new Map<String, reduivy__Individual_Grade_Item__c>();
                for(reduivy__Individual_Grade_Item__c igi : igiGrades){
                    if(String.isNotBlank(igi.reduivy__Study_Grade_Item__c)){
                        igiBySgiId.put(igi.reduivy__Study_Grade_Item__c, igi);
                    }
                }
                
                Set<String> validSgiIds = new Set<String>();

                List<GradeWrapper> gradeWrapperList = new List<GradeWrapper>();
                for (StudyGradeItemWrapper sgiWrapper : tableColumnSgiList){
                    reduivy__Study_Grade_Item__c sgi = sgiWrapper.sgi;

                    //Instead of just looking for existing grades, we need to add any missing grades too
                    reduivy__Individual_Grade_Item__c igi = new reduivy__Individual_Grade_Item__c();
                    reduivy__Individual_Grade_Item__c oldIgi;

                    if(igiBySgiId.containsKey(sgi.id)){
                        igi = igiBySgiId.get(sgi.id);
                        oldIgi = igi.clone(true, true);
                    }

                    //Set Individual Grade Item record info based on Study Grade Item for new and existing records
                    igi.Name = sgi.Name;
                    igi.reduivy__Study_Grade_Item__c = sgi.id;
                    igi.reduivy__Weight__c = sgi.reduivy__Weight__c;

                    //we clone the oldIgi as igi if it is null
                    if(oldIgi == null){
                        oldIgi = igi.clone(true, true);
                    }

                    GradeWrapper gw = new GradeWrapper(sgi, igi, oldIgi, hiddenParentSgis.contains(igi.reduivy__Study_Grade_Item__c));
                    gradeWrapperList.add(gw);

                    validSgiIds.add(igi.reduivy__Study_Grade_Item__c);
                    
                }

                //Find student's study grade setting
                if (String.isNotBlank(ien.reduivy__Study_Grade_Setting__c)){
                    studyGradeSettingIds.add(ien.reduivy__Study_Grade_Setting__c);
                } else {
                    //If student is missing the grade setting, give them the default
                    ien.reduivy__Study_Grade_Setting__c = defaultSgsId;
                }

                //Combine into StudentWrapper
                StudentWrapper studWrapper = new StudentWrapper(ien, igd, gradeWrapperList);
                studentWrappers.add(studWrapper);
            }

            List<reduivy__Study_Grading_Scheme__c> sgsList = getStudyGradingSchemes(studyGradeSettingIds);

            //Get a list of active picklist values
            List<REDU_PicklistOption_OBJ> igiStatusList = new List<REDU_PicklistOption_OBJ>();
            List<Schema.PicklistEntry> activeIgdStatuses = IGI_Helper.getStatuses();
            for (Schema.PicklistEntry ple : activeIgdStatuses){
                igiStatusList.add(new REDU_PicklistOption_OBJ(ple.getLabel(), ple.getValue(), false));
            }
            
            //Return DataWrapper
            DataWrapper dw = new DataWrapper(sgsList, studentWrappers, tableColumnSgiList, targetSgp, individualEnrollmentGradeFieldSet, igiStatusList);

            if (sObjectName == SSE_Helper.getApiName()){
                dw.setRecord(studySession, studyOffering);
            } else {
                dw.setRecord(studyOffering);
            }

            dw.gradingPeriodOptions = getStudyGradePeriodOptions(sgpList, targetSgp.Id);

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(dw));
            return response;
            
        } catch (QueryException qex){
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp){
            throw REDU_Exception_UTIL.auraException(exp.getMessage(), exp.getLineNumber(), null);
        }

    }

    /**
    * @description Return Study Session info
    * @param studySessionId Study Session Id to get info for
    * @return reduivy__Study_Session__c
    */   
    private static reduivy__Study_Session__c getStudySessionInfo(String studySessionId){

        reduivy__Study_Session__c studySession = [
            SELECT Id, 
            Name, 
            reduivy__Study_Offering__c, 
            reduivy__Study_Offering__r.Name, 
            reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c, 
            reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c, 
            reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c, 
            reduivy__Study_Offering__r.reduivy__Grade_Item_Status_Background_Colours__c, 
            reduivy__Study_Offering__r.reduivy__Academic_Term__c, 
            reduivy__Study_Offering__r.reduivy__Study_Unit__c, 
            reduivy__Study_Offering__r.reduivy__Academic_Term__r.Name, 
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c, 
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Grade_Item_Status_Background_Colours__c
            FROM reduivy__Study_Session__c
            WHERE Id = :studySessionId
            WITH USER_MODE
        ];

        return studySession;
    }

    /**
    * @description Return Study Offering info
    * @param studyOfferingId Study Offering Id to get info for
    * @return reduivy__Study_Offering__c
    */   
    private static reduivy__Study_Offering__c getStudyOfferingInfo(String studyOfferingId){

        reduivy__Study_Offering__c studyOffering = [
            SELECT Id, 
            Name, 
            reduivy__Study_Grade_Setting__c,
            reduivy__Start_Date_Calculated__c, 
            reduivy__End_Date_Calculated__c, 
            reduivy__Grade_Item_Status_Background_Colours__c,
            reduivy__Academic_Term__c, 
            reduivy__Study_Unit__c, 
            reduivy__Academic_Term__r.Name, 
            reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c, 
            reduivy__Study_Unit__r.reduivy__Grade_Item_Status_Background_Colours__c
            FROM reduivy__Study_Offering__c
            WHERE Id = :studyOfferingId
            WITH USER_MODE
        ];

        return studyOffering;
    }

    /**
    * @description Return relevant Study Grading Schemes (picklist values for grading)
    * @param studyGradeSettingIds All possible Study Grade Settings to search for
    * @return List<reduivy__Study_Grading_Scheme__c>
    */
    private static List<reduivy__Study_Grading_Scheme__c> getStudyGradingSchemes(Set<Id> studyGradeSettingIds){

        List<reduivy__Study_Grading_Scheme__c> sgsList = [
            SELECT Id, 
            reduivy__Study_Grade_Setting__c, 
            reduivy__Grade_Points__c, 
            reduivy__Letter_Grade__c, 
            reduivy__Letter_Grade_Scoring_Range__c, 
            reduivy__Numerical_Grade_Higher_Range__c, 
            reduivy__Numerical_Grade_Lower_Range__c
            FROM reduivy__Study_Grading_Scheme__c
            WHERE reduivy__Study_Grade_Setting__c IN :studyGradeSettingIds 
            AND reduivy__Display_In_Wizard__c = true
            WITH USER_MODE
            //Sort by manual sorting sequence, and then descending order of grade range
            ORDER BY reduivy__Sequence__c ASC NULLS LAST, 
            reduivy__Numerical_Grade_Lower_Range__c DESC NULLS LAST, 
            reduivy__Numerical_Grade_Higher_Range__c DESC NULLS LAST
        ];

        return sgsList;
    }

    /**
    * @description Wrapper class - All data returned for the component
    */
    public class DataWrapper{

        @AuraEnabled public reduivy__Study_Session__c studySession {get;set;}
        @AuraEnabled public reduivy__Study_Offering__c studyOffering {get;set;}
        @AuraEnabled public String recordName {get;set;} //For ease of access
        @AuraEnabled public List<StudentWrapper> studentWrappers {get;set;}
        @AuraEnabled public List<StudyGradeItemWrapper> tableColumnSgiList {get;set;}
        @AuraEnabled public List<reduivy__Study_Grading_Scheme__c> studyGradingSchemeList {get;set;}
        @AuraEnabled public reduivy__Study_Grade_Period_Setting__c sgp {get;set;} 
        @AuraEnabled public List<REDU_DynamicFieldValue_OBJ> igdCustomFields {get;set;}
        @AuraEnabled public List<REDU_PicklistOption_OBJ> igiStatusList {get;set;} 
        @AuraEnabled public List<REDU_PicklistOption_OBJ> gradingPeriodOptions {get; set;} 
        @AuraEnabled public Map<String, String> gradeItemStatusColourMap {get;set;}
        
        //Constructor
        public DataWrapper(List<reduivy__Study_Grading_Scheme__c> sgsList, List<StudentWrapper> studentWrappers, 
            List<StudyGradeItemWrapper> tableColumnSgiList, reduivy__Study_Grade_Period_Setting__c sgp,
            String igdFieldSet, 
            List<REDU_PicklistOption_OBJ> igiStatusList
        ){
            this.studyGradingSchemeList = sgsList;
            this.studentWrappers = studentWrappers;
            this.tableColumnSgiList = tableColumnSgiList;
            this.sgp = sgp;
            this.gradingPeriodOptions = new List <REDU_PicklistOption_OBJ>();
            this.igiStatusList = igiStatusList;
            this.gradeItemStatusColourMap = new Map<String, String>();

            //Custom Individual Enrollment Grade fields
            this.igdCustomFields = new List<REDU_DynamicFieldValue_OBJ>();
            if (String.isNotBlank(igdFieldSet)){
                this.igdCustomFields = REDU_Metadata_UTIL.getFieldSetMembers('reduivy__Individual_Enrollment_Grade__c', igdFieldSet);
            }   

        }

        //Set record using a Study Session
        public void setRecord (reduivy__Study_Session__c studySession, reduivy__Study_Offering__c studyOffering){
            this.studySession = studySession;
            this.studyOffering = studyOffering;
            this.recordName = studySession.Name;
            this.setGradeItemStatusColourMap();
        }

        //Set record using a Study Offering
        public void setRecord (reduivy__Study_Offering__c studyOffering){
            this.studyOffering = studyOffering;
            this.recordName = studyOffering.Name;
            this.setGradeItemStatusColourMap();
        }

        //Sets up colour mapping for Individual Grade Item statuses
        private void setGradeItemStatusColourMap(){
            String colourString;
            //Get colours from Study Offering
            if (String.isNotBlank(this.studyOffering.reduivy__Grade_Item_Status_Background_Colours__c)){
                colourString = this.studyOffering.reduivy__Grade_Item_Status_Background_Colours__c;
            //Get colours from Study Unit
            } else if (String.isNotBlank(this.studyOffering.reduivy__Study_Unit__c) && String.isNotBlank(this.studyOffering.reduivy__Study_Unit__r.reduivy__Grade_Item_Status_Background_Colours__c)){
                colourString = this.studyOffering.reduivy__Study_Unit__r.reduivy__Grade_Item_Status_Background_Colours__c;
            }

            if (String.isNotBlank(colourString)){
                for (String status_colour : colourString.split(';')){
                    String status = status_colour.split('=')[0];
                    String colour = status_colour.split('=')[1];
                    this.gradeItemStatusColourMap.put(status, colour);
                }
            }
        }

    }

    /**
    * @description Wrapper class - All students, individual enrollments, and their related grade records
    */
    public class StudentWrapper{

        @AuraEnabled public reduivy__Individual_Enrollment__c ien {get;set;}
        @AuraEnabled public reduivy__Individual_Enrollment_Grade__c igd {get;set;}
        @AuraEnabled public List<GradeWrapper> gradeWrapperList {get;set;}
        @AuraEnabled public Boolean hasGradeChanged {get; set;}
        @AuraEnabled public reduivy__Individual_Enrollment_Grade__c oldIgd {get;set;}
        @AuraEnabled public Boolean isShown {get;set;}
        @AuraEnabled public String cssClass {get;set;}

        //Constructor
        public StudentWrapper(reduivy__Individual_Enrollment__c ien, reduivy__Individual_Enrollment_Grade__c igd, List<GradeWrapper> gwList){
            this.ien = ien;
            this.igd = igd;
            this.oldIgd = igd.clone(true, true);
            this.gradeWrapperList = gwList;
            this.isShown = true;
            this.cssClass = '';
        }

        //Returns TRUE if any grades have been marked for this StudentWrapper
        public boolean hasGradeChanged(){

            if(this.hasGradeChanged == null){
                this.hasGradeChanged = false;

                for (GradeWrapper gw : gradeWrapperList){
                    if(gw.hasValueChanged() || gw.hasStatusChanged()){
                        this.hasGradeChanged = true;
                        break;
                    }
                }

                //Check if Individual Enrollment Grade has been changed (due to custom fields)
                //We can just compare the objects directly, as any changes to the fields will cause the objects to stop matching.
                if (this.igd != this.oldIgd){
                    this.hasGradeChanged = true;
                }
            }

            return this.hasGradeChanged;
        }

    }

    /**
     * @description Wrapper class - Denotes a single Individual Grade Item record for a student
     */
    public class GradeWrapper{

        @AuraEnabled
        public reduivy__Individual_Grade_Item__c igi {get;set;}
        
        @AuraEnabled
        public Boolean isHiddenParent {get;set;}
        
        @AuraEnabled
        public String sgiId {get;set;}
        
        @AuraEnabled
        public String parentSgiId {get;set;}
        
        @AuraEnabled
        public reduivy__Individual_Grade_Item__c oldIgi {get;set;}
        
        @AuraEnabled
        public Boolean hasChanged {get; set;}
        
        //Contstructor
        public GradeWrapper(reduivy__Study_Grade_Item__c sgi, reduivy__Individual_Grade_Item__c igi, reduivy__Individual_Grade_Item__c oldIgi, Boolean isHiddenParent){
            this.igi = igi;
            this.isHiddenParent = isHiddenParent;
            this.sgiId = sgi.Id;
            this.parentSgiId = sgi.reduivy__Parent_Grade_Item__c;

            //We store the current value here to compare with the new value to decide whether we want to update the record or not
            this.oldIgi = oldIgi;

        }

        //Returns TRUE if the grade has been updated
        public boolean hasValueChanged(){

            if(this.hasChanged == null){
                this.hasChanged = false;

                //We can just compare the objects directly, as any changes to the fields will cause the objects to stop matching.
                if (igi != oldIgi){
                    this.hasChanged = true;
                }
            }

            return this.hasChanged;
        }

        //Returns TRUE if the status has been updated
        public Boolean hasStatusChanged(){
            return this.igi.reduivy__Status__c != this.oldIgi.reduivy__Status__c;
        }

    }

    /**
    * @description Wrapper class - Each Study Grade Item is repesenting a column in the component
    */
    public class StudyGradeItemWrapper{

        @AuraEnabled public reduivy__Study_Grade_Item__c sgi {get;set;}
        @AuraEnabled public Boolean isHiddenParent {get;set;}
        @AuraEnabled public Boolean isShown {get;set;}
        @AuraEnabled public String weight {get;set;}

        //Constructor
        public StudyGradeItemWrapper(reduivy__Study_Grade_Item__c sgi, Boolean isHiddenParent){
            this.sgi = sgi;
            this.isHiddenParent = isHiddenParent;
            //Need isShown for .html as we can only check true values
            this.isShown = !isHiddenParent;
            //Determine Weight - If it has a parent, we need to show the parent weight too
            if (String.isNotBlank(sgi.reduivy__Parent_Grade_Item__c)){
                this.weight = '(' + sgi.reduivy__Weight__c.stripTrailingZeros().toPlainString() + '%/' + sgi.reduivy__Parent_Grade_Item__r.reduivy__Weight__c.stripTrailingZeros().toPlainString() + '%)';
            } else {
                this.weight = sgi.reduivy__Weight__c.stripTrailingZeros().toPlainString() + '%';
            }
        }

    }

    /**
    * @description Upsert grades
    * @param studentWrappersString JSON string of studentWrappers
    * @param individualEnrollmentGradeFieldSet api name of Individual Enrollment Grade custom fields fieldset
    * @param igdStatus status to update the Individual Enrollment Grade with
    * @return REDU_LightningResponse
    */
    @AuraEnabled
    public static REDU_LightningResponse saveGradingData(String studentWrappersString, String individualEnrollmentGradeFieldSet, String igdStatus, String igdLockedStatus){

        Savepoint sp = Database.setSavepoint();
        
        //We don't want partial successes to impact GPA
        try { 
            
            //Convert JSON string to list of studentWrappers
            List<StudentWrapper> studentWrappers = (List<StudentWrapper>)JSON.deserialize(studentWrappersString, List<StudentWrapper>.Class);

            REDU_Logging_UTIL.debug('saveGradingData', studentWrappersString);

            //Insert new Individual Enrollment Grades with no Ids
            List<reduivy__Individual_Enrollment_Grade__c> igdList = new List<reduivy__Individual_Enrollment_Grade__c>();
            for (StudentWrapper sw : studentWrappers){
                //Only insert GradeWrapper if grades have been marked
                //Can also update status. But we only update the status after doing the reduivy__Individual_Grade_Item__c records
                if (sw.hasGradeChanged() || 
                    (String.isNotBlank(igdStatus) && sw.igd.Id != null && sw.igd.reduivy__Status__c != igdStatus)
                ){
                    //Also update existing Individual Enrollment Grade to update custom fields
                    //I think it's missing a check here. hascustomFieldsChange()?
                    if (sw.igd.Id == null || String.isNotBlank(individualEnrollmentGradeFieldSet) || 
                        (String.isNotBlank(igdStatus) && sw.igd.reduivy__Status__c != igdStatus)
                    ){
                        igdList.add(sw.igd);
                    }
                }
            }

            if(!igdList.isEmpty()){
                REDU_Database_UTIL.doUpsert(igdList);
            }

            //Add lookup to Individual Enrollment Grades for each Individual Grade Item that's missing the lookup
            Map<String, List<reduivy__Individual_Grade_Item__c>> nonParentGradesMap = new Map<String, List<reduivy__Individual_Grade_Item__c>>();
            Map<String, reduivy__Individual_Grade_Item__c> parentGradesMap = new Map<String, reduivy__Individual_Grade_Item__c>();
            List<reduivy__Individual_Grade_Item__c> parentGradesForDML = new List<reduivy__Individual_Grade_Item__c>();

            for (StudentWrapper sw : studentWrappers){
                //ParentGrade - Only insert GradeWrapper if grades have been marked
                if (sw.hasGradeChanged()){
                    for (GradeWrapper gw : sw.gradeWrapperList){
                        gw.igi.reduivy__Individual_Enrollment_Grade__c = sw.igd.Id;

                        if (gw.isHiddenParent){
                            //handle parent igi here, we only do if it is new or has igi
                            if (gw.igi.Id == null || gw.hasValueChanged() || gw.hasStatusChanged()){
                                parentGradesForDML.add(gw.igi);
                            }

                            String parentGradeKey = sw.igd.Id + '_' + gw.igi.reduivy__Study_Grade_Item__c;
                            parentGradesMap.put(parentGradeKey, gw.igi);

                        } else {
                            //handle non parent igi here, we only do if it has igi
                            if(gw.igi.Id == null || gw.hasValueChanged() || gw.hasStatusChanged()){
                                String parentGradeKey = sw.igd.Id + '_' + (String.isNotBlank(gw.parentSgiId) ? gw.parentSgiId : '' );
                                if(nonParentGradesMap.containsKey(parentGradeKey)){
                                    nonParentGradesMap.get(parentGradeKey).add(gw.igi);
                                } else {
                                    nonParentGradesMap.put(parentGradeKey, new List<reduivy__Individual_Grade_Item__c>{gw.igi});
                                }
                            }
                        }
                    }
                }
            }

            //Upsert parent igis first, ensuring Ids are populated
            if (!parentGradesForDML.isEmpty()){
                //ISS-002261 strip inaccessible fields
                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPSERTABLE, parentGradesForDML);

                REDU_Database_UTIL.doUpsert(decision.getRecords());
            }
            
            List<reduivy__Individual_Grade_Item__c> nonParentGradesForDML = new List<reduivy__Individual_Grade_Item__c>();
            for(String parentKey : nonParentGradesMap.keySet()){

                String parentGradeId = parentGradesMap.containsKey(parentKey) ? parentGradesMap.get(parentKey).Id : null;

                for(reduivy__Individual_Grade_Item__c igi : nonParentGradesMap.get(parentKey)){
                    igi.reduivy__Parent_Grade_Item__c = String.isNotBlank(parentGradeId) ? parentGradeId : null;

                    nonParentGradesForDML.add(igi);
                }
            }

            //Upsert Grades
            if (!nonParentGradesForDML.isEmpty()){
                //ISS-002261 strip inaccessible fields
                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPSERTABLE, nonParentGradesForDML);

                REDU_Database_UTIL.doUpsert(decision.getRecords());
            }

            //Update Individual Enrollment Grade Status if one is supplied (purposely doing this after Individual Grade Items are updated)
            if (String.isNotBlank(igdStatus)){
                List<reduivy__Individual_Enrollment_Grade__c> igdStatusUpdateList = new List<reduivy__Individual_Enrollment_Grade__c>();
                for (reduivy__Individual_Enrollment_Grade__c igd : igdList){
                    if (igd.reduivy__Status__c != igdLockedStatus && igd.reduivy__Status__c != igdStatus){
                        igd.reduivy__Status__c = igdStatus;
                        igdStatusUpdateList.add(igd);
                    }
                }
                
                if (!igdStatusUpdateList.isEmpty()){
                    //ISS-002261 strip inaccessible fields
                    SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPSERTABLE, igdStatusUpdateList);

                    REDU_Database_UTIL.doUpdate(decision.getRecords());
                }
            }

            //Return errorWrapper
            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, null);
            return response;

        } catch (Exception exp){
            Database.rollback(sp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage(), exp.getLineNumber(), exp.getStackTraceString());
        }
        
    }

    /**
     * @description Get Study Grade Period Settings picklist
     * @return List<REDU_PicklistOption_OBJ>
     */
    private static List<REDU_PicklistOption_OBJ> getStudyGradePeriodOptions(List<reduivy__Study_Grade_Period_Setting__c> sgpList, String defaultValue){

        List<REDU_PicklistOption_OBJ> options = new List<REDU_PicklistOption_OBJ>();

		for(reduivy__Study_Grade_Period_Setting__c sgp : sgpList){
            options.add(new REDU_PicklistOption_OBJ(sgp.Name, sgp.Id, (String.isNotBlank(defaultValue) && defaultValue == sgp.Id ? true : false) ));
		}

        return options;
    }
    
}
