/**
 * @author      WDCi (Lean)
 * @date        Oct 2023
 * @group       Enrollment Wizard
 * @description Student enrollment wizard
 * @changehistory
 * ISS-001752 03-10-2023 Lean - new class
 * ISS-001924 24-05-2024 Sueanne - Major/Minor Enrollment
 * ISS-002203 17-01-2025 Jordan - Copy Completion Requirement from Study Plan Option to new Program Enrollment
 * ISS-002336 24-03-2024 Lean - Added missed/failed unit
 * ISS-002330 20-03-2025 XW - show campuses translation name in filter campus combobox if found
 * ISS-002401 21-04-2025 Lean - Added enrollment action status
 * ISS-002436 06-05-2025 XW - Added Individual academic progress
 * ISS-002459 13-05-2025 Lean - Get IPE in progress enrollment statuses
 */
public with sharing class REDU_IpePathways_LCTRL {
    
    /**
     * @description Get the list of individual pathway based on individual program enrollment id
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualPathways(Id masterIpeId){
        
        try {
            //query the individual pathway
            List<reduivy__Individual_Pathway__c> idvPathways = new List<reduivy__Individual_Pathway__c>();
            for (reduivy__Individual_Pathway__c ipw : [SELECT Id, 
                reduivy__Term_Number__c,
                reduivy__Status__c,
                reduivy__Individual_Academic_Progress__c,
                reduivy__Individual_Academic_Progress__r.reduivy__Enrollment_Action_Status__c
                FROM reduivy__Individual_Pathway__c
                WHERE reduivy__Individual_Program_Enrollment__c =: masterIpeId
                WITH USER_MODE
                ORDER BY reduivy__Term_Number__c ASC NULLS LAST
            ]) {
                idvPathways.add(ipw);
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(idvPathways));
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
     * @description Get the list of campus based on individual program enrollment id
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getCampuses(Id masterIpeId){

        try {
            //query the master ipe to find out the educational institution
            List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id, 
                reduivy__Default_Campus__c,
                reduivy__Study_Program__c,
                reduivy__Study_Program__r.reduivy__Educational_Institution__c
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE Id =: masterIpeId
                WITH USER_MODE
                LIMIT 1
            ];

            List<Account> campuses = new List<Account>();
            if (!ipeList.isEmpty() && String.isNotBlank(ipeList.get(0).reduivy__Study_Program__r.reduivy__Educational_Institution__c)) {
                
                String accTranslationNameField = ACC_Helper.getTranslationFieldNameForName();
                Set<String> fieldsToQuery = new Set<String>{
                    'Id',
                    'Name',
                    accTranslationNameField
                };
                String soqlQuery = 'SELECT ' + String.join(fieldsToQuery, ', ')
                                + ' FROM Account'
                                + ' WHERE RecordTypeId = :campusRecordTypeId'
                                + ' AND ParentId =: eduInstId'
                                + ' AND reduivy__Status__c =: statusActive'
                                + ' ORDER BY ' + accTranslationNameField;
                
                Map<String, Object> bindMap = new Map<String, Object>{
                    'campusRecordTypeId' => ACC_Helper.getCampusRecordTypeId(),
                    'eduInstId' => ipeList.get(0).reduivy__Study_Program__r.reduivy__Educational_Institution__c,
                    'statusActive' => ACC_Helper.STATUS_ACTIVE
                };

                for (Account campus : (List<Account>) Database.queryWithBinds(soqlQuery, bindMap, AccessLevel.USER_MODE)) {
                    campuses.add(campus);
                }
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(campuses));
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
     * @description Create new pathway for master individual program enrollment
     * @param masterIpeId
     * @return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse createIndividualPathway(Id masterIpeId){

        try {
            Integer count = 0;
            reduivy__Individual_Pathway__c lastIpw;

            for (reduivy__Individual_Pathway__c ipw : [SELECT Id,
                reduivy__Description__c,
                reduivy__Enrollment_Method__c,
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c,
                reduivy__Individual_Program_Enrollment__r.reduivy__Study_Pathway__c
                FROM reduivy__Individual_Pathway__c
                WHERE reduivy__Individual_Program_Enrollment__c =: masterIpeId
                WITH USER_MODE
                ORDER BY reduivy__Term_Number__c ASC NULLS LAST
            ]) {
                count ++;

                lastIpw = ipw;
            }

            reduivy__Individual_Pathway__c newPathway = new reduivy__Individual_Pathway__c();
            newPathway.reduivy__Individual_Program_Enrollment__c = masterIpeId;
            newPathway.reduivy__Term_Number__c = count + 1;
            
            if (lastIpw != null) {
                //by default we inherit the details from the last pathway
                newPathway.reduivy__Description__c = lastIpw.reduivy__Description__c;
                newPathway.reduivy__Enrollment_Method__c = lastIpw.reduivy__Enrollment_Method__c;
                newPathway.reduivy__Max_Credits__c = lastIpw.reduivy__Max_Credits__c;
                newPathway.reduivy__Recommended_Credits__c = lastIpw.reduivy__Recommended_Credits__c;

                if (String.isNotBlank(lastIpw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Pathway__c)) {
                    //we will then look for the study pathway term if there is one match
                    for (reduivy__Study_Pathway_Term__c spt : [SELECT Id,
                        reduivy__Description__c,
                        reduivy__Enrollment_Method__c,
                        reduivy__Max_Credits__c,
                        reduivy__Recommended_Credits__c
                        FROM reduivy__Study_Pathway_Term__c
                        WHERE reduivy__Study_Pathway__c =: lastIpw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Pathway__c
                        AND reduivy__Term_Number__c =: count
                        WITH USER_MODE
                        LIMIT 1
                    ]) {
                        newPathway.reduivy__Description__c = spt.reduivy__Description__c;
                        newPathway.reduivy__Enrollment_Method__c = spt.reduivy__Enrollment_Method__c;
                        newPathway.reduivy__Max_Credits__c = spt.reduivy__Max_Credits__c;
                        newPathway.reduivy__Recommended_Credits__c = spt.reduivy__Recommended_Credits__c;
                    }
                }
            }

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Pathway__c>{newPathway});

            REDU_LightningResponse response = new REDU_LightningResponse(true, Label.The_Record_Was_Saved, JSON.serialize(newPathway));
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
     * @description Get the list of study plan (from spo) with student enrollment (true/false enrolled) based on masterIpeId and studentId
     * @param masterIpeId
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getSpoStudentEnrollment(Id masterIpeId){
        try {
            //find masterSpId and studentId by masterIpeId
            Id masterSpId = null;
            Id studentId = null;
            if(masterIpeId != null){
                reduivy__Individual_Program_Enrollment__c masterIpe = [SELECT id,
                    reduivy__Study_Plan__c,
                    reduivy__Contact__c
                    FROM reduivy__Individual_Program_Enrollment__c
                    WHERE Id = :masterIpeId
                    AND RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
                    WITH USER_MODE
                    LIMIT 1
                ]; 
                masterSpId = masterIpe.reduivy__Study_Plan__c;
                studentId = masterIpe.reduivy__Contact__c;
            }

            //create wrapper list to hold each study plan and enrollment status together
            List<SpoEnrollWrapper> spIsEnrolled = new List<SpoEnrollWrapper>();
            Map<Id, Boolean> spEnrollMap = new Map<Id, Boolean>();
            Map<Id, reduivy__Study_Plan__c> spRecordMap = new Map<Id, reduivy__Study_Plan__c>();
            if(masterSpId != null){
            
                //find study plan option, where master study plan id = masterSpId
                String splTransaltionNameField = SPL_Helper.getTranslationFieldNameForName();
                Set<String> fieldsToQuery = new Set<String>{
                    'Id', 
                    'reduivy__Status__c',
                    'reduivy__Child_Study_Plan__r.Id',
                    'reduivy__Child_Study_Plan__r.Name',
                    'reduivy__Child_Study_Plan__r.reduivy__Study_Program__c',
                    'reduivy__Child_Study_Plan__r.' + splTransaltionNameField
                };
                String soqlQuery = 'SELECT ' + String.join(fieldsToQuery, ', ')
                                + ' FROM reduivy__Study_Plan_Option__c'
                                + ' WHERE reduivy__Master_Study_Plan__c = :masterSpId'
                                + ' AND reduivy__Status__c = :statusActive';
                Map<String, Object> bindMap = new Map<String, Object>{
                    'masterSpId' => masterSpId,
                    'statusActive' => SPO_Helper.STATUS_ACTIVE
                };

                for(reduivy__Study_Plan_Option__c spo : (List<reduivy__Study_Plan_Option__c>) Database.queryWithBinds(soqlQuery, bindMap, AccessLevel.USER_MODE)){
                    //construct study plan obj
                    reduivy__Study_Plan__c sp = new reduivy__Study_Plan__c(  
                        id = spo.reduivy__Child_Study_Plan__r.Id,  
                        reduivy__Study_Program__c = spo.reduivy__Child_Study_Plan__r.reduivy__Study_Program__c  
                    );  
                    if(spo.reduivy__Child_Study_Plan__r.get(splTransaltionNameField) != null) {
                        sp.Name = (String) spo.reduivy__Child_Study_Plan__r.get(splTransaltionNameField);
                    } else {
                        sp.Name = spo.reduivy__Child_Study_Plan__r.Name;
                    }
                    

                    //set default enrolled is false
                    spEnrollMap.put(sp.Id, false);
                    spRecordMap.put(sp.Id, sp);
                }

                //get enrolled statueses
                Set<String> enrolledStatus = new Set<String>();
                enrolledStatus.addAll(IPE_Helper.getInProgressStatuses());
                enrolledStatus.addAll(IPE_Helper.getCompletedStatuses());

                if(!spEnrollMap.isEmpty()){
                    for(reduivy__Individual_Program_Enrollment__c ipe : [
                        SELECT id, reduivy__Contact__c,
                        reduivy__Study_Plan__r.Id,
                        reduivy__Study_Plan__r.Name,
                        reduivy__Study_Plan__r.reduivy__Study_Program__c  
                        FROM reduivy__Individual_Program_Enrollment__c
                        WHERE reduivy__Enrollment_Status__c IN :enrolledStatus
                        AND reduivy__Master_Enrollment__c = :masterIpeId
                        AND reduivy__Contact__c = :studentId
                        AND RecordTypeId = :IPE_Helper.getChildEnrollmentRecordTypeId()
                        WITH USER_MODE
                    ]){
                        //if found idv program enroll record, replace enrollment = true
                        if(spEnrollMap.containsKey(ipe.reduivy__Study_Plan__r.Id)){
                            spEnrollMap.put(ipe.reduivy__Study_Plan__r.Id, true);
                        }
                    }
                }
                
                for(Id spId : spEnrollMap.KeySet()){
                    spIsEnrolled.add(new SpoEnrollWrapper(spRecordMap.get(spId), spEnrollMap.get(spId)));
                }
            }
            
            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(spIsEnrolled));
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
     * @description to enroll or unenroll the study plan options
     * @param masterIpeId 
     * @param toEnrollUnenroll consist of study plan and operation to do (enroll/unenroll)
     * @return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse manageChildIpeEnrollment(Id masterIpeId, String toEnrollUnenroll){
        try {

            Map<String, List<reduivy__Study_Plan__c>> getMap = new Map<String, List<reduivy__Study_Plan__c>>();
            if(toEnrollUnenroll != null && masterIpeId != null){
                //get Map<operation, List<studyPlan>>, operation can be enroll/unenroll
                getMap = (Map<String, List<reduivy__Study_Plan__c>>) JSON.deserialize(toEnrollUnenroll, Map<String, List<reduivy__Study_Plan__c>>.class);
                 
                //find masterIpe by masterIpeId
                reduivy__Individual_Program_Enrollment__c masterIpe = [
                    SELECT Id, reduivy__Contact__c, reduivy__Eligible_To_Enroll__c, reduivy__Study_Plan__c
                    FROM reduivy__Individual_Program_Enrollment__c
                    WHERE Id = :masterIpeId
                    AND RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
                    WITH USER_MODE
                    LIMIT 1
                ];

                //ISS-002203 find study plan option, where master study plan id = masterSpId
                Map<Id, String> spCompletionReqMap = new Map<Id, String>();

                for(reduivy__Study_Plan_Option__c spo : [SELECT Id, 
                    reduivy__Child_Study_Plan__r.Id,
                    reduivy__Completion_Requirement__c
                    FROM reduivy__Study_Plan_Option__c
                    WHERE reduivy__Master_Study_Plan__c = :masterIpe.reduivy__Study_Plan__c
                    AND reduivy__Status__c = :SPO_Helper.STATUS_ACTIVE
                    WITH USER_MODE
                ]){
                    //get completion requirement
                    spCompletionReqMap.put(spo.reduivy__Child_Study_Plan__r.Id, spo.reduivy__Completion_Requirement__c);
                }

                //To Enroll - insert child ipe record
                if(getMap.containsKey('enroll') && masterIpe != null){
                    
                    List<reduivy__Individual_Program_Enrollment__c> ipeToInsert = new List<reduivy__Individual_Program_Enrollment__c>();
                    for(reduivy__Study_Plan__c enrollSp : getMap.get('enroll')){

                        reduivy__Individual_Program_Enrollment__c ipe = new reduivy__Individual_Program_Enrollment__c(
                            RecordTypeId = IPE_Helper.getChildEnrollmentRecordTypeId(),
                            reduivy__Study_Program__c = enrollSp.reduivy__Study_Program__c,
                            reduivy__Study_Plan__c = enrollSp.Id,
                            reduivy__Master_Enrollment__c = masterIpe.Id,
                            reduivy__Enrollment_Status__c = IPE_Helper.getInProgressStatuses()[0],
                            reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                            reduivy__Eligible_To_Enroll__c = masterIpe.reduivy__Eligible_To_Enroll__c,
                            reduivy__Completion_Requirement__c = spCompletionReqMap.get(enrollSp.Id)
                        );

                        ipeToInsert.add(ipe);
                    }
                    
                    if(!ipeToInsert.isEmpty()){
                        REDU_Database_UTIL.doInsert(ipeToInsert);
                    }
                }

                //To Unenroll - change enrollment sttaus -> IPE_Helper.getWithdrawnStatuses()
                if(getMap.containsKey('unenroll') && masterIpe != null){
                    
                    //get all child ipe list that enrolled by current student
                    Map<Id, reduivy__Individual_Program_Enrollment__c> childIpes = new Map<Id, reduivy__Individual_Program_Enrollment__c>();

                    for(reduivy__Individual_Program_Enrollment__c childIpe : [
                        SELECT Id, reduivy__Study_Plan__c, reduivy__Enrollment_Status__c
                        FROM reduivy__Individual_Program_Enrollment__c
                        WHERE reduivy__Master_Enrollment__c = :masterIpe.Id
                        AND RecordTypeId = :IPE_Helper.getChildEnrollmentRecordTypeId()
                        AND reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
                        AND reduivy__Contact__c = :masterIpe.reduivy__Contact__c
                        WITH USER_MODE
                    ]){
                        childIpes.put(childIpe.reduivy__Study_Plan__c, childIpe);
                    }

                    List<reduivy__Individual_Program_Enrollment__c> ipeToUnenroll = new List<reduivy__Individual_Program_Enrollment__c>();
                    
                    for(reduivy__Study_Plan__c unenrollSp : getMap.get('unenroll')){
                        if(childIpes.containsKey(unenrollSp.Id)){
                            reduivy__Individual_Program_Enrollment__c unenrollIpe = childIpes.get(unenrollSp.Id);
                            unenrollIpe.reduivy__Enrollment_Status__c = IPE_Helper.getWithdrawnStatuses()[0];
                            
                            ipeToUnenroll.add(unenrollIpe);
                        }
                    }

                    if(!ipeToUnenroll.isEmpty()){
                        REDU_Database_UTIL.doUpdate(ipeToUnenroll);
                    }
                }

            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(getMap));

            return response;

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }

    }

    // inetrnal wrapper class - to hold study plan with its enrollment status (true/false)
    public class SpoEnrollWrapper {
        public reduivy__Study_Plan__c studyPlan { get; set; }
        public Boolean isEnrolled { get; set; }

        public SpoEnrollWrapper(reduivy__Study_Plan__c sp, Boolean enrolled) {
            studyPlan = sp;
            isEnrolled = enrolled;
        }
    }

    /**
     * @description ISS-002336 Return the missed and failed study units for the previous term based on the study pathway
     * @param ipeId
     * @param studyPlanId
     * @param studyPathwayId
     * @param userMode
     * @param currentTermNumber
     * @param missedFailedUnitListingOption
     * @return Set<Id>
     */
    public static Set<Id> getMissedFailedStudyUnits(Id ipeId, Id studyPlanId, Id studyPathwayId, String userMode, Decimal currentTermNumber, String missedFailedUnitListingOption) {

        if (String.isBlank(ipeId)) {
            throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters, new List<String>{'ipeId'}));
        }

        if (String.isBlank(studyPlanId)) {
            throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters, new List<String>{'studyPlanId'}));
        }

        if (String.isBlank(studyPathwayId)) {
            throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters, new List<String>{'studyPathwayId'}));
        }

        if (currentTermNumber == null || currentTermNumber == 0) {
            throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters, new List<String>{'currentTermNumber'}));
        }

        //missed or failed study unit ids
        Set<Id> missedFailedSunIds = new Set<Id>();

        //study pathway unit study unit ids
        Set<Id> sptUnitIds = new Set<Id>();

        //get the previous term study pathway unit
        for (reduivy__Study_Pathway_Unit__c spt : [SELECT Id,
            reduivy__Applicable_Study_Plan__c,
            reduivy__Number_of_Units_from_Group__c,
            reduivy__Study_Plan_Group__c,
            reduivy__Study_Unit__c
            FROM reduivy__Study_Pathway_Unit__c
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c =: studyPathwayId
            AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c <: currentTermNumber
            WITH USER_MODE
        ]) {
            //match the study pathway unit
            if (String.isBlank(spt.reduivy__Applicable_Study_Plan__c)
                || (String.isNotBlank(spt.reduivy__Applicable_Study_Plan__c) && spt.reduivy__Applicable_Study_Plan__c == studyPlanId)
            ) {
                if (String.isNotBlank(spt.reduivy__Study_Unit__c)) {
                    sptUnitIds.add(spt.reduivy__Study_Unit__c);
                }
            }
        }

        if (!sptUnitIds.isEmpty()) {
            //find all the attempted individual plan structure unit for the ipe
            List<String> ipsUnitStatuses = new List<String>();
            List<String> nonEnrollableStatuses = IPS_Helper.getUnitNonEnrollableStatuses();
            List<String> failedStatuses = IPS_Helper.getUnitFailedStatuses();

            ipsUnitStatuses.addAll(nonEnrollableStatuses);
            ipsUnitStatuses.addAll(failedStatuses);

            List<String> unitIpsFields = new List<String>{
                'Id',
                'reduivy__Target_Unit_Id__c',
                'reduivy__Status__c',
                'reduivy__Parent_Plan_Structure__c'
            };

            Map<String, Object> unitIpsBindParams = new Map<String, Object>();
            unitIpsBindParams.put('statuses', ipsUnitStatuses);
            unitIpsBindParams.put('unitIpsRtId', IPS_Helper.getUnitRecordTypeId());
            unitIpsBindParams.put('ipeId', ipeId);

            String unitIpsSoql = 'SELECT ' + String.join(unitIpsFields, ', ') +
                ' FROM reduivy__Individual_Plan_Structure__c ' +
                ' WHERE reduivy__Status__c IN: statuses ' +
                ' AND RecordTypeId =: unitIpsRtId ' +
                 'AND reduivy__Individual_Program_Enrollment__c =: ipeId ';

            if (String.isBlank(userMode) || userMode != USR_Helper.USER_MODE_ADMIN) {
                unitIpsBindParams.put('hidden', false);

                unitIpsSoql += ' AND reduivy__Hidden__c =: hidden ';
            }

            Set<Id> enrolledCompletedSunIds = new Set<Id>();

            for (reduivy__Individual_Plan_Structure__c unitIps : (List<reduivy__Individual_Plan_Structure__c>) Database.queryWithBinds(unitIpsSoql, unitIpsBindParams, AccessLevel.USER_MODE)) {
                if (String.isNotBlank(unitIps.reduivy__Parent_Plan_Structure__c) && String.isNotBlank(unitIps.reduivy__Target_Unit_Id__c)) {
                    if (failedStatuses.contains(unitIps.reduivy__Status__c)) {

                        //for failed unit, we add it to the list directly
                        if (missedFailedUnitListingOption == 'All') {
                            missedFailedSunIds.add(unitIps.reduivy__Target_Unit_Id__c);
                        }

                    } else if (nonEnrollableStatuses.contains(unitIps.reduivy__Status__c)) {

                        //for enrolled/completed, we add to a separate list for matching
                        enrolledCompletedSunIds.add(unitIps.reduivy__Target_Unit_Id__c);
                    }
                }
            }

            //remove the enrolled/completed from the pathway list
            sptUnitIds.removeAll(enrolledCompletedSunIds);

            if (missedFailedUnitListingOption == 'All') {
                missedFailedSunIds.addAll(sptUnitIds);
            }
        }

        return missedFailedSunIds;
    }

    /**
     * @description Return the enrollment action status config
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getEnrollmentActionStatusConfigs(){

        try {
            Map<String, reduivy__IdvPw_Enrollment_Action_Status_Config__mdt> configs = new Map<String, reduivy__IdvPw_Enrollment_Action_Status_Config__mdt>();
            for (reduivy__IdvPw_Enrollment_Action_Status_Config__mdt config : IPW_Helper.getEnrollmentActionStatusConfigs()) {
                configs.put(config.reduivy__Enrollment_Action_Status__c, config);
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(configs));

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
     * @description Return the list of IPE in progress statuses
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIpeStatusConfigs() {

        try {
            Map<String, reduivy__IdvPe_Enrollment_Status_Config__mdt> configs = new Map<String, reduivy__IdvPe_Enrollment_Status_Config__mdt>();
            for (reduivy__IdvPe_Enrollment_Status_Config__mdt config : IPE_Helper.getEnrollmentStatusConfig()) {
                configs.put(config.reduivy__Enrollment_Status__c, config);
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(configs));

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