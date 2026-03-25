/**
 * @author      WDCi (XiRouh)
 * @date        Jan 2025
 * @group       Term Student Enrollment Wizard
 * @description 
 * @changehistory
 * ISS-002229 20-01-2025 XiRouh - initial version
 * ISS-002495 23-09-2025 XW - support translation for long text field
 * ISS-002736 25-11-2025 XiRouh - added enableWrapText param
 */
public with sharing class REDU_TermStudentEnrollmentModal_LCTRL {
    
    /**
     * @description get study term details
     * @param studyTermRecordId
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable = true)
    public static REDU_LightningResponse getStudyTermDetails(Id studyTermRecordId) {
        try {
            if (String.isBlank(studyTermRecordId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters, 
                new List<String>{'studyTermRecordId'}));
            }
    
            Set<String> stmFields = new Set<String>{
                'Name',
                'reduivy__Academic_Year__r.Name',
                'reduivy__Academic_Year__r.reduivy__Educational_Institution__c'
            };

            Map<String, Object> stmBindParams = new Map<String, Object>();
            stmBindParams.put('Id', studyTermRecordId);
            stmBindParams.put('AcademicTermRecordTypeId', STM_Helper.getAcademicTermRecordTypeId());

            String stmSoql = 'SELECT ' + String.join(stmFields, ', ') +
                ' FROM reduivy__Study_Term__c ' +
                ' WHERE Id = :Id ' + 
                ' AND RecordTypeId = :AcademicTermRecordTypeId ';

            List<reduivy__Study_Term__c> stmList = Database.queryWithBinds(stmSoql, stmBindParams, AccessLevel.USER_MODE);
    
            if (stmList.isEmpty()) {
                throw new REDU_ApplicationException(String.format(Label.Invalid_Record_Id_For_Object_Type,
                    new List<String>{studyTermRecordId, STM_Helper.getAcademicTermRecordTypeLabel()}));
            }
    
            reduivy__Study_Term__c stm = stmList[0];
    
            Map<String, String> responseData = new Map<String, String>{
                'studyTermName' => stm.Name,
                'academicYearName' => stm.reduivy__Academic_Year__r.Name,
                'eduInstitutionId' => stm.reduivy__Academic_Year__r.reduivy__Educational_Institution__c
            };
    
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);
    
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description get available academic term and campus for combobox
     * @param
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable = true)
    public static REDU_LightningResponse getComboboxOptions(Id eduInstitutionId, Id currentTermId) {
        try {
            if(String.isBlank(eduInstitutionId)) {
                throw new REDU_ApplicationException(Label.Educational_Institution_Id_Not_Found);
            }

            if (String.isBlank(currentTermId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters, 
                new List<String>{'currentTermId'}));
            }

            Set<String> stmFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Start_Date__c',
                'reduivy__End_Date__c'
            };

            Map<String, Object> stmBindParams = new Map<String, Object>();
            stmBindParams.put('AcademicTermRecordTypeId', STM_Helper.getAcademicTermRecordTypeId());
            stmBindParams.put('eduInsId', eduInstitutionId);

            String stmSoql = 'SELECT ' + String.join(stmFields, ', ') +
                ' FROM reduivy__Study_Term__c ' +
                ' WHERE RecordTypeId = :AcademicTermRecordTypeId ' +
                ' AND reduivy__Academic_Year__r.reduivy__Educational_Institution__c = :eduInsId ' + 
                ' ORDER BY reduivy__Start_Date__c ASC ';

            List<reduivy__Study_Term__c> stmList = new List<reduivy__Study_Term__c>();

            for(reduivy__Study_Term__c stm : (List<reduivy__Study_Term__c>) Database.queryWithBinds(stmSoql, stmBindParams, AccessLevel.USER_MODE)){
                if(stm.Id != currentTermId) {
                    stmList.add(stm);
                }
            }

            Set<String> accFields = new Set<String>{
                'Id',
                'Name'
            };

            Map<String, Object> accBindParams = new Map<String, Object>();
            accBindParams.put('campusRecordTypeId', ACC_Helper.getCampusRecordTypeId());
            accBindParams.put('eduInsId', eduInstitutionId);

            String accSoql = 'SELECT ' + String.join(accFields, ', ') +
                ' FROM Account ' +
                ' WHERE RecordTypeId = :campusRecordTypeId ' + 
                ' AND ParentId = :eduInsId ';

            List<Account> accList = new List<Account>();

            for(Account acc : (List<Account>) Database.queryWithBinds(accSoql, accBindParams, AccessLevel.USER_MODE)){
                accList.add(acc);
            }

            Set<String> spgFields = new Set<String>{
                'Id',
                'Name'
            };

            Map<String, Object> spgBindParams = new Map<String, Object>();
            spgBindParams.put('eduInsId', eduInstitutionId);

            String spgSoql = 'SELECT ' + String.join(spgFields, ', ') +
                ' FROM reduivy__Study_Program__c ' + 
                ' WHERE reduivy__Educational_Institution__c = :eduInsId ';

            List<reduivy__Study_Program__c> spgList = new List<reduivy__Study_Program__c>();

            for(reduivy__Study_Program__c spg : (List<reduivy__Study_Program__c>) Database.queryWithBinds(spgSoql, spgBindParams, AccessLevel.USER_MODE)){
                spgList.add(spg);
            }
            
            Map<String, Object> optionsMap = new Map<String, Object>{
                'term' => stmList,
                'campus' => accList,
                'studyProgram' => spgList
            };

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(optionsMap)); 

            return response;
        } catch (QueryException qex) {

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg); 

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }  
    }

    /**
     * @description get available study intakes
     * @param selectedStudyProgramId
     * @param selectedCampusId
     * @param studyIntakeSelectionTableFields
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable = true)
    public static REDU_LightningResponse getStudyIntakes(Id selectedStudyProgramId, Id selectedCampusId, String studyIntakeSelectionTableFields, String language, Boolean enableWrapText) {
        try {
            if (String.isBlank(selectedStudyProgramId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'selectedStudyProgramId'}));
            }

            if (String.isBlank(selectedCampusId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'selectedCampusId'}));
            }

            if (String.isBlank(studyIntakeSelectionTableFields)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'studyIntakeSelectionTableFields'}));
            }

            language = String.isBlank(language) ? UserInfo.getLanguage() : language;
            SObjectType rootSObjectType = reduivy__Study_Intake__c.sObjectType;
            
            JSONGenerator tableColJsonGen = JSON.createGenerator(true);
            REDU_Datatable_UTIL.generateTableColMetadata(
                tableColJsonGen, 
                rootSObjectType, 
                studyIntakeSelectionTableFields, 
                false, 
                null,  
                false, 
                '_self', 
                false,
                enableWrapText
            );
            
            JSONGenerator tableFieldRefMetadata = JSON.createGenerator(true);
            REDU_Datatable_UTIL.generateRefLinksMetadata(tableFieldRefMetadata, rootSObjectType, studyIntakeSelectionTableFields);
            
            Set<String> setFieldAPI = new Set<String>{'Id', 'Name'};
            
            for (String field : studyIntakeSelectionTableFields.split(';')) {
                Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, rootSObjectType);
                setFieldAPI.add(field);
                
                if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                    setFieldAPI.add(REDU_Metadata_UTIL.getReferenceFieldForQuery(field, true));
                } else if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                    setFieldAPI.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
                }
            }

            Map<String, Object> sitBindParams = new Map<String, Object>{
                'studyProgramId' => selectedStudyProgramId,
                'campusId' => selectedCampusId
            };

            String sitSoql = 'SELECT ' + String.join(new List<String>(setFieldAPI), ', ') +
                ' FROM reduivy__Study_Intake__c ' +
                ' WHERE reduivy__Campus__c = :campusId ' +
                ' AND reduivy__Study_Program__c = :studyProgramId ' +
                ' ORDER BY reduivy__Registration_Open_Date__c, Name NULLS LAST ';

            List<reduivy__Study_Intake__c> studyIntakes = (List<reduivy__Study_Intake__c>) Database.queryWithBinds(sitSoql, sitBindParams, AccessLevel.USER_MODE);

            Map<String, Object> translationInfo = REDU_TranslationManager.getTranslationInfo(SIT_Helper.getApiName(), studyIntakes, setFieldAPI, language);

            Map<String, Object> responseJSON = new Map<String, Object>{
                REDU_Datatable_UTIL.COLUMNS_PARAM => JSON.deserializeUntyped(tableColJsonGen.getAsString()),
                REDU_Datatable_UTIL.RECORDS_PARAM => studyIntakes,
                REDU_Datatable_UTIL.REFLINKS_PARAM => JSON.deserializeUntyped(tableFieldRefMetadata.getAsString()),
                REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM => translationInfo
            };

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseJSON));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description get records that will be updated/created during the term enrollment process
     * @param selectedAcademicTermId
     * @param selectedCampusId
     * @param selectedAcademicTermId
     * @param academicTermToBeEnroll
     * @param eligibleStudentCountTableStudyIntakeField
     * @return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse getTermEnrollmentRecords (List<Id> selectedStudyIntakeIds, Id selectedCampusId, Id selectedAcademicTermId, Id academicTermToBeEnroll, String eligibleStudentCountTableStudyIntakeField, Boolean enableWrapText) {
        try{
            //Study Intake Id, IPE Id, IPW Id
            Map<Id, List<Map<Id, Id>>> studyIntakesWithIPWToBeProcessedInTermEnrollment = new Map<Id, List<Map<Id, Id>>>();
            //Study Intake Id, IPE Id, IPW Id
            Map<Id, List<Map<Id, Id>>> studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment = new Map<Id, List<Map<Id, Id>>>();
            //Study Intake Id, IPE Id, Name (To show the name in the error details)
            Map<Id, List<Map<Id, String>>> studyIntakesWithIPWToBeExcluded = new Map<Id, List<Map<Id, String>>>();
            
            if(String.isBlank(eligibleStudentCountTableStudyIntakeField)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'eligibleStudentCountTableStudyIntakeField'}));
            }

            Set<String> ipeFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Study_Intake__c',
                'reduivy__Study_Intake__r.Name'
            };

            Set<String> ipwFields = new Set<String>{
                'Id',
                'reduivy__Term_Number__c',
                'reduivy__Academic_Term__c',
                'reduivy__Status__c'
            };

            Map<String, Object> ipeBindParams = new Map<String, Object>();
            ipeBindParams.put('academicTermId', selectedAcademicTermId);
            ipeBindParams.put('campusId', selectedCampusId);
            ipeBindParams.put('activeStatuses', IPE_Helper.getInProgressStatuses());
            ipeBindParams.put('studyIntakesIds', selectedStudyIntakeIds);
            ipeBindParams.put('masterIPERecordTypeId', IPE_Helper.getMasterEnrollmentRecordTypeId());
            ipeBindParams.put('childIPERecordTypeId', IPE_Helper.getChildEnrollmentRecordTypeId());
            ipeBindParams.put('autoEnrollmentStatus', IPE_Helper.AUTO_ENROLLMENT_AUTO);

            //For master IPE, the query filter will based on the record itself, for child ipe, the filter will based on child_ipe.master_ipe's fields
            String ipeSoql = 'SELECT ' + String.join(ipeFields, ', ') +
                ' , (SELECT ' + String.join(ipwFields, ', ') + ' FROM reduivy__Individual_Pathways__r ORDER BY reduivy__Term_Number__c) ' +
                ' FROM reduivy__Individual_Program_Enrollment__c ' +
                ' WHERE reduivy__Enrollment_Status__c = :activeStatuses ' +
                ' AND reduivy__Auto_Enrollment__c = :autoEnrollmentStatus ' +
                ' AND ((RecordTypeId = :masterIPERecordTypeId AND reduivy__Study_Intake__c IN :studyIntakesIds AND (reduivy__Default_Campus__c = :campusId OR reduivy__Default_Campus__c = NULL)) ' +
                ' OR (RecordTypeId = :childIPERecordTypeId AND reduivy__Master_Enrollment__r.reduivy__Study_Intake__c IN :studyIntakesIds AND (reduivy__Master_Enrollment__r.reduivy__Default_Campus__c = :campusId OR reduivy__Master_Enrollment__r.reduivy__Default_Campus__c = NULL))) ' +
                ' ORDER BY reduivy__Contact__r.reduivy__Sequence__c ASC ';

            Map<String, String> studyIntakesIdWithName = new Map<String, String>();

            for(reduivy__Individual_Program_Enrollment__c ipe : (List<reduivy__Individual_Program_Enrollment__c>) Database.queryWithBinds(ipeSoql, ipeBindParams, AccessLevel.USER_MODE)){      
                //To store the previous (Current) term ipw
                reduivy__Individual_Pathway__c prevTermIPW;
                //To store the IPW that should be enroll into the new term
                reduivy__Individual_Pathway__c toBeEnrolledTermIPW;

                List<reduivy__Individual_Pathway__c> ipws = ipe.reduivy__Individual_Pathways__r;

                Boolean ipwWithAcademicTermExist = false;
                Boolean continueChecking = true;

                if(ipe.reduivy__Study_Intake__c != null && !studyIntakesIdWithName.containsKey(ipe.reduivy__Study_Intake__c)) {
                    studyIntakesIdWithName.put(ipe.reduivy__Study_Intake__c, ipe.reduivy__Study_Intake__r.Name);
                }

                //IPE do not have any ipw found > Skip
                //Last ipw academic term is not null > Skip
                //Last ipw academic term is selectedAcademicTermId > skip
                //Last ipw academic term is not null but is in a term != selectedAcademicTermId or academicTermToBeEnroll > skip
                //Last ipw academic term is academicTermToBeEnroll > proceed
                //Last ipw academic term is null > proceed
                if(ipws.size() > 0 && 
                    (ipws[ipws.size() - 1].reduivy__Academic_Term__c == null || ipws[ipws.size() - 1].reduivy__Academic_Term__c == academicTermToBeEnroll)) {

                    for (reduivy__Individual_Pathway__c ipw : ipws) {
                        if(ipw.reduivy__Academic_Term__c != null) { //For Scenario 1 Check
                            ipwWithAcademicTermExist = true; 
                        }
                        
                        if (ipw.reduivy__Academic_Term__c == selectedAcademicTermId) {
                            if(prevTermIPW == null) { //To ensure only one ipw is in this term
                                prevTermIPW = ipw;
                            } else {
                                //add into excluded list and skip ipe
                                addToExcludedList(ipe, Label.Multiple_IPWs_Enrolled_In_Current_Term_Error, studyIntakesWithIPWToBeExcluded);

                                //have to exit the ipw loop and continue with another ipe
                                continueChecking = false;
                                break;
                            }
                            
                        }

                        if (ipw.reduivy__Academic_Term__c == academicTermToBeEnroll) {
                            if (toBeEnrolledTermIPW == null) { //To ensure only one ipw is in this term
                                if(ipw.reduivy__Status__c != IPW_Helper.STATUS_COMPLETED) { //To ensure the ipw is not completed for already enrolled student
                                    toBeEnrolledTermIPW = ipw;
                                } else {
                                    //add into excluded list and skip ipe
                                    addToExcludedList(ipe, Label.IPW_Enrolled_And_Completed_In_New_Term_Error, studyIntakesWithIPWToBeExcluded);

                                    //have to exit the ipw loop and continue with another ipe
                                    continueChecking = false;
                                    break;
                                }
                            } else { 
                                //add into excluded list and skip ipe
                                addToExcludedList(ipe, Label.Multiple_IPWs_Enrolled_In_New_Term_Error, studyIntakesWithIPWToBeExcluded);

                                //have to exit the ipw loop and continue with another ipe
                                continueChecking = false;
                                break;
                            }
                        }
                    }

                    if(!continueChecking) continue;

                    if(prevTermIPW == null && toBeEnrolledTermIPW == null) { //Scenario 1 - If there is no previous term && there is no ipw is in the term to be enrolled
                        processForWithoutPrevAndToBeEnrolledTerm(ipws, ipe, ipwWithAcademicTermExist, studyIntakesWithIPWToBeProcessedInTermEnrollment, studyIntakesWithIPWToBeExcluded);
                    } else if (prevTermIPW == null && toBeEnrolledTermIPW != null) { //Scenario 2 - If there is no previous term && there is one ipw is in the term to be enrolled
                        processForWithoutPrevAndWithToBeEnrolledTerm(ipws, ipe, toBeEnrolledTermIPW, studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment, studyIntakesWithIPWToBeExcluded);
                    } else if (prevTermIPW != null && toBeEnrolledTermIPW == null) { //Scenario 3 - If there is one previous term && there is no ipw is in the term to be enrolled
                        processForWithPrevTermAndWithoutToBeEnrolledTerm(ipws, ipe, prevTermIPW, studyIntakesWithIPWToBeProcessedInTermEnrollment, studyIntakesWithIPWToBeExcluded);
                    } else if (prevTermIPW != null && toBeEnrolledTermIPW != null) { //Scenario 4 - If there is one previous term && there is one ipw is in the term to be enrolled
                        processForWithPrevAndToBeEnrolledTerm(ipws, ipe, prevTermIPW, toBeEnrolledTermIPW, studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment, studyIntakesWithIPWToBeExcluded);
                    } else {
                        addToExcludedList(ipe, Label.Unhandled_Scenario_Error, studyIntakesWithIPWToBeExcluded);
                    }
                }
            }

            List<Map<String, Object>> columnMap = constructDataTableColumn(eligibleStudentCountTableStudyIntakeField, enableWrapText);
            List<Map<String, String>> dataMap = constructDataTableData(studyIntakesIdWithName, eligibleStudentCountTableStudyIntakeField, studyIntakesWithIPWToBeProcessedInTermEnrollment, studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment, studyIntakesWithIPWToBeExcluded);

            Map<String, Object> finalMap = new Map<String, Object>{
                'columns' => columnMap,
                'records' => dataMap,
                'studyIntakesWithIPWToBeProcessedInTermEnrollment' => studyIntakesWithIPWToBeProcessedInTermEnrollment,
                'studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment' => studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment,
                'studyIntakesIdWithName' => studyIntakesIdWithName
            };

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(finalMap));
            
            return response;
        } catch (QueryException qex) {

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg); 
            
        } catch (LimitException lex) {

            String errorMsg = Label.Too_Many_Query_Rows;
            throw REDU_Exception_UTIL.auraException(errorMsg); 

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }  
    }

    /**
     * @description Scenario 1 - If there is no previous term && there is no ipw is in the term to be enrolled
     * @param ipws
     * @param ipe
     * @param ipwWithAcademicTermExist
     * @param studyIntakesWithIPWToBeProcessedInTermEnrollment
     * @param studyIntakesWithIPWToBeExcluded
     * @return void
     */
    private static void processForWithoutPrevAndToBeEnrolledTerm(List<reduivy__Individual_Pathway__c> ipws, reduivy__Individual_Program_Enrollment__c ipe, Boolean ipwWithAcademicTermExist, Map<Id, List<Map<Id, Id>>> studyIntakesWithIPWToBeProcessedInTermEnrollment, Map<Id, List<Map<Id, String>>> studyIntakesWithIPWToBeExcluded) {
        if(ipws[0].reduivy__Term_Number__c == 1 && ipws[0].reduivy__Academic_Term__c == null) { //check if #1 is exist and academic term is blank

            if(ipwWithAcademicTermExist) { //check if subsequent ipw.reduivy__Academic_Term__c are all blank, if not, skip ipe
                //add into excluded list (reason > ipw in prev term and to be enrolled term not found, but there are ipw is enrolled in other term)
                addToExcludedList(ipe, Label.IPW_Not_Found_In_Selected_Terms_But_Enrolled_Elsewhere_Error, studyIntakesWithIPWToBeExcluded);

                return;
            }

            //add into process list if it is not being return
            addToTermEnrollmentProcessList(ipe, ipws[0].Id, studyIntakesWithIPWToBeProcessedInTermEnrollment);

            return;
        } else {
            //add to the excluded list (reason > Both prev term and to be enrolled term ipw not found and ipw with term number = 1 not found or already enrolled in other term)
            addToExcludedList(ipe, Label.IPW_Term_Not_Found_Or_Already_Enrolled_Error, studyIntakesWithIPWToBeExcluded);

            return;
        }
    }

    /**
     * @description Scenario 2 - If there is no previous term && there is one ipw is in the term to be enrolled
     * @param ipws
     * @param ipe
     * @param toBeEnrolledTermIPW
     * @param studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment
     * @param studyIntakesWithIPWToBeExcluded
     * @return void
     */
    private static void processForWithoutPrevAndWithToBeEnrolledTerm(List<reduivy__Individual_Pathway__c> ipws, reduivy__Individual_Program_Enrollment__c ipe, reduivy__Individual_Pathway__c toBeEnrolledTermIPW, Map<Id, List<Map<Id, Id>>> studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment, Map<Id, List<Map<Id, String>>> studyIntakesWithIPWToBeExcluded) {
        if(toBeEnrolledTermIPW.reduivy__Term_Number__c == 1) { //check if ipw in to be enrolled term is #1
            //if new term is #1, proceed to check subsequent ipw.reduivy__Academic_Term__c are all blank
            for(Integer i = ipws.indexOf(toBeEnrolledTermIPW) + 1; i < ipws.size(); i++) {
                if(ipws[i].reduivy__Academic_Term__c != null) { //if not all subsequent ipw.reduivy__Academic_Term__c are all blank, skip ipe
                    //add into excluded list (reason > ipw in to be enrolled term found, but there are subsequet ipw is enrolled in other term)
                    addToExcludedList(ipe, Label.IPW_Subsequent_Enrollment_Mismatch_Error, studyIntakesWithIPWToBeExcluded);

                    return;
                }
            }

            //add into process list if it is not being skip in the for loop check (the ipw already enrolled in the to be enrolled term, so we do not have to do the term enrollment, but we can store it for the unit enrollment)
            addToUnitEnrollmentProcessList(ipe, toBeEnrolledTermIPW.Id, studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment);

            return;

        } else {
            //add to the excluded list (reason > ipw in prev term not found and ipw in to be enrolled term found but not in #1)
            addToExcludedList(ipe, Label.IPW_Not_Found_In_Current_And_Not_IPW_1_In_Enrolled_Term_Error, studyIntakesWithIPWToBeExcluded);

            return;
        } 
    }

    /**
     * @description Scenario 3 - If there is one previous term && there is no ipw is in the term to be enrolled
     * @param ipws
     * @param ipe
     * @param prevTermIPW
     * @param studyIntakesWithIPWToBeProcessedInTermEnrollment
     * @param studyIntakesWithIPWToBeExcluded
     * @return void
     */
    private static void processForWithPrevTermAndWithoutToBeEnrolledTerm(List<reduivy__Individual_Pathway__c> ipws, reduivy__Individual_Program_Enrollment__c ipe, reduivy__Individual_Pathway__c prevTermIPW, Map<Id, List<Map<Id, Id>>> studyIntakesWithIPWToBeProcessedInTermEnrollment, Map<Id, List<Map<Id, String>>> studyIntakesWithIPWToBeExcluded) {
        //if the subsequent term are all blank, proccessed
        for(Integer i = ipws.indexOf(prevTermIPW) + 1; i < ipws.size(); i++) {
            if(ipws[i].reduivy__Academic_Term__c != null) {
                //if not all subsequent ipw.reduivy__Academic_Term__c are all blank, skip ipe
                //add into excluded list (reason > ipw in prev term found, but there are subsequent ipw is enrolled in other term)
                addToExcludedList(ipe, Label.IPW_Subsequent_Enrollment_Mismatch_Error, studyIntakesWithIPWToBeExcluded);

                return;
            }
        }

        //add into process list if it is not being return
        try { //prevent ipws[ipws.indexOf(prevTermIPW) + 1] from not existing and causing an out of bounds error. This shouldn't happen since we already checked that prevTerm will not be the last term, but this is just a precaution
            addToTermEnrollmentProcessList(ipe, ipws[ipws.indexOf(prevTermIPW) + 1].Id, studyIntakesWithIPWToBeProcessedInTermEnrollment);

            return;
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Scenario 4 - If there is one previous term && there is one ipw is in the term to be enrolled
     * @param ipws
     * @param ipe
     * @param prevTermIPW
     * @param toBeEnrolledTermIPW
     * @param studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment
     * @param studyIntakesWithIPWToBeExcluded
     * @return void
     */
    private static void processForWithPrevAndToBeEnrolledTerm(List<reduivy__Individual_Pathway__c> ipws, reduivy__Individual_Program_Enrollment__c ipe, reduivy__Individual_Pathway__c prevTermIPW, reduivy__Individual_Pathway__c toBeEnrolledTermIPW, Map<Id, List<Map<Id, Id>>> studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment, Map<Id, List<Map<Id, String>>> studyIntakesWithIPWToBeExcluded) {
        if(toBeEnrolledTermIPW.reduivy__Term_Number__c - prevTermIPW.reduivy__Term_Number__c == 1) {
            //add into process list (the ipw already enrolled in the to be enrolled term, so we do not have to do the term enrollment, but we can store it for the unit enrollment)
            addToUnitEnrollmentProcessList(ipe, toBeEnrolledTermIPW.Id, studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment);

            return;
        } else {
            //add into excluded list (reason > ipw in prev term and ipw in to be enrolled term found, but there are not subsequential)
            addToExcludedList(ipe, Label.IPW_Terms_Not_Subsequential_Error, studyIntakesWithIPWToBeExcluded);

            return;
        }
    }

    /**
     * @description To add the ipe to the eligible for term enrollment list
     * @param ipe
     * @param ipwId
     * @param studyIntakesWithIPWToBeProcessedInTermEnrollment
     * @return void
     */
    private static void addToTermEnrollmentProcessList(reduivy__Individual_Program_Enrollment__c ipe, Id ipwId, Map<Id, List<Map<Id, Id>>> studyIntakesWithIPWToBeProcessedInTermEnrollment) {
        Map<Id, Id> tempMap = new Map<Id, Id>();
        tempMap.put(ipe.Id, ipwId);

        if (!studyIntakesWithIPWToBeProcessedInTermEnrollment.containsKey(ipe.reduivy__Study_Intake__c)) {
            studyIntakesWithIPWToBeProcessedInTermEnrollment.put(ipe.reduivy__Study_Intake__c, new List<Map<Id, Id>>());
        }

        studyIntakesWithIPWToBeProcessedInTermEnrollment.get(ipe.reduivy__Study_Intake__c).add(tempMap);
    }

    /**
     * @description To add the ipe to the eligible for unit enrollment list
     * @param ipe
     * @param ipwId
     * @param studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment
     * @return void
     */
    private static void addToUnitEnrollmentProcessList(reduivy__Individual_Program_Enrollment__c ipe, Id ipwId, Map<Id, List<Map<Id, Id>>> studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment) {
        Map<Id, Id> tempMap = new Map<Id, Id>();
        tempMap.put(ipe.Id, ipwId);

        if(!studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment.containsKey(ipe.reduivy__Study_Intake__c)) {
            studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment.put(ipe.reduivy__Study_Intake__c, new List<Map<Id, Id>>());
        }

        studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment.get(ipe.reduivy__Study_Intake__c).add(tempMap);
    }

    /**
     * @description To add the ipe to the excluded list
     * @param ipe
     * @param errorLabel
     * @param studyIntakesWithIPWToBeExcluded
     * @return void
     */
    private static void addToExcludedList(reduivy__Individual_Program_Enrollment__c ipe, String errorLabel, Map<Id, List<Map<Id, String>>> studyIntakesWithIPWToBeExcluded) {
        Map<Id, String> tempMap = new Map<Id, String>();
        tempMap.put(ipe.Id, errorLabel);
        
        if(!studyIntakesWithIPWToBeExcluded.containsKey(ipe.reduivy__Study_Intake__c)) {
            studyIntakesWithIPWToBeExcluded.put(ipe.reduivy__Study_Intake__c, new List<Map<Id, String>>());
        }

        studyIntakesWithIPWToBeExcluded.get(ipe.reduivy__Study_Intake__c).add(tempMap);
    }

    /**
     * @description To construct the data table column base
     * @param eligibleStudentCountTableStudyIntakeField
     * @return List<Map<String, Object>> columnMap
     */
    private static List<Map<String, Object>> constructDataTableColumn(String eligibleStudentCountTableStudyIntakeField, Boolean enableWrapText) {
        List<Map<String, Object>> columnMap = new List<Map<String, Object>>();
        SObjectType rootSObjectType = reduivy__Study_Intake__c.sObjectType;
    
        // Generate column metadata using REDU_Datatable_UTIL
        JSONGenerator tableColJsonGen = JSON.createGenerator(true);
        REDU_Datatable_UTIL.generateTableColMetadata(
            tableColJsonGen, 
            rootSObjectType, 
            eligibleStudentCountTableStudyIntakeField, 
            false, 
            null,  
            false, 
            '_self', 
            false,
            enableWrapText
        );
    
        // Deserialize the generated JSON to get the columns
        List<Object> columns = (List<Object>) JSON.deserializeUntyped(tableColJsonGen.getAsString());
    
        // Iterate through the columns and add them to the columnMap
        for (Object col : columns) {
            Map<String, Object> colMap = (Map<String, Object>) col;
            columnMap.add(new Map<String, Object>{
                'label' => (String) colMap.get('label'),
                'fieldName' => (String) colMap.get('fieldName')
            });
        }
    
        // Add fixed columns at the end
        columnMap.add(new Map<String, Object>{
            'label' => Label.Eligible_Student_Records_Field_Label,
            'fieldName' => 'detailsOfRecordsToBeProcessed'
        });
    
        columnMap.add(new Map<String, Object>{
            'label' => Label.Excluded_Student_Records_Field_Label,
            'fieldName' => 'detailsOfRecordsToBeExcluded'
        });
    
        return columnMap;
    }

    /**
     * @description To construct the data table data
     * @param studyIntakesIdWithName
     * @param eligibleStudentCountTableStudyIntakeField
     * @param studyIntakesWithIPWToBeProcessedInTermEnrollment
     * @param studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment
     * @param studyIntakesWithIPWToBeExcluded
     * @return List<Map<String, String>> dataMap
     */
    private static List<Map<String, String>> constructDataTableData(Map<String, String> studyIntakesIdWithName, String eligibleStudentCountTableStudyIntakeField, Map<Id, List<Map<Id, Id>>> studyIntakesWithIPWToBeProcessedInTermEnrollment, Map<Id, List<Map<Id, Id>>> studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment, Map<Id, List<Map<Id, String>>> studyIntakesWithIPWToBeExcluded) {
        List<Map<String, String>> dataMap = new List<Map<String, String>>();
        List<String> sitFields = new List<String>(eligibleStudentCountTableStudyIntakeField.split(';'));
    
        Map<String, Object> sitBindParams = new Map<String, Object>();
        sitBindParams.put('sitIds', studyIntakesIdWithName.keySet());
    
        String sitSoql = 'SELECT ' + String.join(sitFields, ', ') + 
                    ' FROM reduivy__Study_Intake__c ' +
                    ' WHERE Id IN :sitIds';
    
        List<reduivy__Study_Intake__c> studyIntakeRecords = (List<reduivy__Study_Intake__c>) Database.queryWithBinds(sitSoql, sitBindParams, AccessLevel.USER_MODE);
    
        Map<Id, reduivy__Study_Intake__c> studyIntakeRecordsMap = new Map<Id, reduivy__Study_Intake__c>(studyIntakeRecords);
    
        //Each datatable row = 1 study intake
        for (Id studyIntakeId : studyIntakesIdWithName.keySet()) {
            //Get the number of term enrollment and unit enrollment to be processed
            Integer termEnrollmentCount = studyIntakesWithIPWToBeProcessedInTermEnrollment.containsKey(studyIntakeId) ? 
                studyIntakesWithIPWToBeProcessedInTermEnrollment.get(studyIntakeId).size() : 0;
    
            Integer unitEnrollmentCount = studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment.containsKey(studyIntakeId) ? 
                studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment.get(studyIntakeId).size() : 0;
    
            Integer excludedRecordsCount = studyIntakesWithIPWToBeExcluded.containsKey(studyIntakeId) ? 
                studyIntakesWithIPWToBeExcluded.get(studyIntakeId).size() : 0;
    
            String exclusionDetails = constructExclusionDetails(studyIntakeId, excludedRecordsCount, studyIntakesWithIPWToBeExcluded);
    
            Map<String, String> rowMap = new Map<String, String>();
            reduivy__Study_Intake__c studyIntakeRecord = studyIntakeRecordsMap.containsKey(studyIntakeId) ? studyIntakeRecordsMap.get(studyIntakeId) : null;
    
            for(String field : sitFields) {
                if(field.contains('.')) {
                    List<String> parts = field.split('\\.');
                    SObject currentObj = studyIntakeRecord;
                    for(Integer i = 0; i < parts.size() - 1; i++) {
                        currentObj = currentObj.getSObject(parts[i]);
                    }
                    rowMap.put(field, String.valueOf(currentObj?.get(parts[parts.size() - 1])));
                } else {
                    rowMap.put(field, String.valueOf(studyIntakeRecord.get(field)));
                }
            }
    
            //Add fixed columns
            Integer totalEnrollmentCount = termEnrollmentCount + unitEnrollmentCount;
            rowMap.put('detailsOfRecordsToBeProcessed', String.valueOf(totalEnrollmentCount));
            rowMap.put('detailsOfRecordsToBeExcluded', exclusionDetails.trim());
            rowMap.put('numberOfRecordsToBeProcessed', String.valueOf(totalEnrollmentCount));
            rowMap.put('numberOfRecordsToBeExcluded', String.valueOf(excludedRecordsCount));

            rowMap.put('Id', studyIntakeId);
    
            dataMap.add(rowMap);
        }
    
        return dataMap;
    }

    /**
     * @description Helper method to construct exclusion details
     * @param studyIntakeId
     * @param excludedRecordsCount
     * @param studyIntakesWithIPWToBeExcluded
     * @return String exclusion details
     */
    private static String constructExclusionDetails(Id studyIntakeId, Integer excludedRecordsCount, Map<Id, List<Map<Id, String>>> studyIntakesWithIPWToBeExcluded) {
        if (excludedRecordsCount == 0) {
            return '0';
        }
        
        String exclusionDetails = String.format(Label.Excluded_Record_Reason_Label, 
            new List<String>{ String.valueOf(excludedRecordsCount) });
        
        if (studyIntakesWithIPWToBeExcluded.containsKey(studyIntakeId)) {
            Set<String> processedErrorLabels = new Set<String>();
            
            for (Map<Id, String> errorMap : studyIntakesWithIPWToBeExcluded.get(studyIntakeId)) {
                for (Id ipeId : errorMap.keySet()) {
                    String errorLabel = errorMap.get(ipeId);
                    String recordUrl = URL.getOrgDomainUrl() + '/' + ipeId;
                    
                    if (!processedErrorLabels.contains(errorLabel)) {
                        exclusionDetails += String.format(Label.Excluded_Record_Details_Label, 
                            new List<String>{ errorLabel, recordUrl });
                        
                        processedErrorLabels.add(errorLabel);
                    }
                }
            }
        }
        
        return exclusionDetails;
    }

    /**
     * @description To init queue job
     * @param toBeProcessedIpwIds
     * @param toBeEnrolledTermId
     * @param proceedForUnitEnrollment
     * @param bypassRequirementRules
     * @param existingIndividualEnrollmentStatuses
     * @return void
     */
    @AuraEnabled
    public static void initQueueJob(String jobOperation, List<Id> toBeProcessedIpwIds, String toBeEnrolledTermId, Boolean proceedForUnitEnrollment, Boolean bypassRequirementRules, String existingIndividualEnrollmentStatuses) {
        
        try {
            if(String.isNotBlank(toBeEnrolledTermId) && !toBeProcessedIpwIds.isEmpty() && proceedForUnitEnrollment != null){

                reduivy__Study_Term__c studyTerm = [SELECT Id, 
                    Name 
                    FROM reduivy__Study_Term__c 
                    WHERE Id =: toBeEnrolledTermId
                    WITH USER_MODE
                ];

                Map<String, Object> params = new Map<String, Object>();
                
                params.put('toBeEnrolledTermId', toBeEnrolledTermId);
                params.put('proceedForUnitEnrollment', proceedForUnitEnrollment);
                params.put('bypassRequirementRules', bypassRequirementRules);
                params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
                params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(jobOperation, toBeEnrolledTermId));
                params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, toBeEnrolledTermId);
                params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, studyTerm.Name);

                JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(jobOperation, toBeProcessedIpwIds, params);
                JQH_JobManager.queueJob(job, true);
            }

        } catch (QueryException qex) {

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg); 
            
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}