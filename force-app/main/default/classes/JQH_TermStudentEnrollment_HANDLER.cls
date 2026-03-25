/**
 * @author      WDCi (XiRouh)
 * @date        Feb 2025
 * @group       Term Student Enrollment
 * @description The job handler for term student enrollment
 * @changehistory
 * ISS-002229 13-02-2025 XiRouh - new class
 * ISS-002535 15-07-2025 XiRouh - Updated performUnitEnrollment() to check for an existing placeholder individual enrollment before creating a new one
 * ISS-002743 09-12-2025 XiRouh - Updated to use IPF-based grouping instead of Contact-based grouping while performing unit enrollment
 * ISS-002785 28-01-2026 Lean - Fixed study offering query to respect status
 */
public with sharing class JQH_TermStudentEnrollment_HANDLER implements JQH_JobHandler{
    /**
     * @description List of record ids
     */
    private List<Id> recordIds;

    /**
     * @description Map of params
     */
    private Map<String, Object> params;

    /**
     * @description Default constructor
     */
    public JQH_TermStudentEnrollment_HANDLER() {
        this.recordIds = new List<Id>();
        this.params = new Map<String, Object>();
    }

    /**
     * @description Return generator class name
     * @return String
     */
    public String getClassName() {
        return 'reduivy.JQH_TermStudentEnrollment_HANDLER';
    }

    /**
     * @description Return handler class instance details
     * @return String
     */
    public String getClassInstanceDetails() {
        return String.valueOf(this);
    }

    /**
     * @description Set record ids to be processed
     * @param recordIds List of record id
     * @return void
     */
    public void setRecordIds(List<Id> recordIds) {
        this.recordIds = recordIds;
    }

    /**
     * @description Set parameters for the handler
     * @param params Map of params in key value pair
     * @return void
     */
    public void setParams(Map<String, Object> params) {
        this.params = params;
    }

    //init the result monitor
    private JQH_JobManager.HandlerResult resultMonitor = new JQH_JobManager.HandlerResult();

    /**
     * @description Release grade
     * @return JQH_JobManager.HandlerResult
     */
    public JQH_JobManager.HandlerResult execute() {
        //init the savepoint for rollback
        SavePoint sp = Database.setSavepoint();

        try{
            Set<String> ipwQueryFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Individual_Program_Enrollment__c',
                'reduivy__Individual_Program_Enrollment__r.Name',
                'reduivy__Individual_Program_Enrollment__r.reduivy__Study_Pathway__c',
                'reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c',
                'reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c',
                'reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.Name',
                'reduivy__Individual_Program_Enrollment__r.reduivy__Study_Plan__c',
                'reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c',
                'reduivy__Academic_Term__c', 
                'reduivy__Term_Number__c'
            };

            Map<String, Object> ipwBindParams = new Map<String, Object>{
                'ipwIds' => recordIds
            };

            String ipwSoqlQuery = 'SELECT ' + String.join(ipwQueryFields, ', ') + 
                ' FROM reduivy__Individual_Pathway__c ' +
                ' WHERE Id IN : ipwIds ' +
                ' ORDER BY reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sequence__c NULLS LAST ';
            
            List<reduivy__Individual_Pathway__c> ipwRecordsForTermEnrollment = new List<reduivy__Individual_Pathway__c>();
            for(reduivy__Individual_Pathway__c ipw : (List<reduivy__Individual_Pathway__c>) Database.queryWithBinds(ipwSoqlQuery, ipwBindParams, AccessLevel.USER_MODE)){
                ipwRecordsForTermEnrollment.add(ipw);
            }
            
            String toBeEnrolledTermId = this.params.containsKey('toBeEnrolledTermId') ? String.valueOf(this.params.get('toBeEnrolledTermId')) : '';
            Boolean proceedForUnitEnrollment = this.params.containsKey('proceedForUnitEnrollment') ? Boolean.valueOf(this.params.get('proceedForUnitEnrollment')) : false;
            Boolean bypassRequirementRules = this.params.containsKey('bypassRequirementRules') ? Boolean.valueOf(this.params.get('bypassRequirementRules')) : false;
            String existingIndividualEnrollmentStatuses = this.params.containsKey('existingIndividualEnrollmentStatuses') ? String.valueOf(this.params.get('existingIndividualEnrollmentStatuses')) : '';
            
            List<reduivy__Individual_Pathway__c> successfulEnrolledIntoTermIpwRecords = new List<reduivy__Individual_Pathway__c>();

            if (!ipwRecordsForTermEnrollment.isEmpty()) {
                successfulEnrolledIntoTermIpwRecords = performTermEnrollment(ipwRecordsForTermEnrollment, toBeEnrolledTermId);
            }

            if(proceedForUnitEnrollment) {
                if (!successfulEnrolledIntoTermIpwRecords.isEmpty()) {
                    performUnitEnrollment(successfulEnrolledIntoTermIpwRecords, bypassRequirementRules, toBeEnrolledTermId, existingIndividualEnrollmentStatuses);
                }
            }

        } catch (Exception exp) {
            //rollback if there is an exception
            Database.rollback(sp);

            //add the error to the result monitor
            for (Id recordId : recordIds) {
                String errorMsg = String.format(Label.All_Changes_Have_Been_Rolled_Back_Due_To_Error, new List<String>{REDU_Database_UTIL.cleanseErrorMessage(exp.getMessage()), exp.getStackTraceString()});
                resultMonitor.addFailResult(recordId, errorMsg);
            }

        }

        return resultMonitor;

    }

    /**
     * @description Update the IPWs that do not have an academic term populated to match the "To Be Enrolled" term.
     * @param ipwRecords
     * @param toBeEnrolledTermId
     * @return List<reduivy__Individual_Pathway__c> 
     */
    public List<reduivy__Individual_Pathway__c> performTermEnrollment(List<reduivy__Individual_Pathway__c> ipwRecords, String toBeEnrolledTermId) {
        List<reduivy__Individual_Pathway__c> ipwToPeformTermEnrollment = new List<reduivy__Individual_Pathway__c>();
        List<reduivy__Individual_Pathway__c> successRecords = new List<reduivy__Individual_Pathway__c>();
        Map<Id, reduivy__Individual_Pathway__c> originalRecordsMap = new Map<Id, reduivy__Individual_Pathway__c>();
        
        //Store all original records for unit enrollment
        for(reduivy__Individual_Pathway__c ipw : ipwRecords) {
            originalRecordsMap.put(ipw.Id, ipw);
        }
        
        //Handle the records that need term enrollment
        for(reduivy__Individual_Pathway__c ipw : ipwRecords) {
            if(ipw.reduivy__Academic_Term__c == null) {
                ipwToPeformTermEnrollment.add(new reduivy__Individual_Pathway__c(
                    Id = ipw.Id,    
                    reduivy__Academic_Term__c = toBeEnrolledTermId,
                    reduivy__Auto_Enrollment__c = true
                ));
            } else {
                //Records that already have a term set are considered successful without updates
                successRecords.add(originalRecordsMap.get(ipw.Id));
            }
        }
    
        //Process the records that need updating
        if(!ipwToPeformTermEnrollment.isEmpty()) {
            //Can't use REDU_Database_UTIL to add errors because these aren't trigger records
            List<Database.SaveResult> updateResults = Database.update(ipwToPeformTermEnrollment, false, AccessLevel.USER_MODE);
            
            //Track success/failure
            Integer counter = 0;
            for (Database.SaveResult sr : updateResults){
                if (sr.isSuccess()) {
                    //Add the original record to the success list (Need all the queried field in the original record)
                    reduivy__Individual_Pathway__c originalRecord = originalRecordsMap.get(ipwToPeformTermEnrollment.get(counter).Id);
                    
                    successRecords.add(originalRecord);
                } else {
                    //add the error to the result monitor
                    resultMonitor.addFailResult(ipwToPeformTermEnrollment.get(counter).Id, REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage()));
                }

                counter ++;
            }
        }

        //Add the success records to the result monitor
        if (!successRecords.isEmpty()) {
            for (reduivy__Individual_Pathway__c ipw : successRecords) {
                resultMonitor.addSuccessResult(ipw.Id, Label.Success);
            }
        }
    
        return successRecords;
    } 

    /**
     * @description To create IEN for each eligible IPW
     * @param ipwRecords 
     * @param bypassRequirementRules 
     * @param toBeEnrolledTermId 
     * @param existingIndividualEnrollmentStatuses 
     * @return void
     */
    public void performUnitEnrollment(List<reduivy__Individual_Pathway__c> ipwRecords, Boolean bypassRequirementRules, String toBeEnrolledTermId, String existingIndividualEnrollmentStatuses) {
        //Get the study pathway and term number from the ipws
        Map<Id, Set<Decimal>> studyPathwayIdWithTermNumbers = new Map<Id, Set<Decimal>>();
        //For bindParams
        Set<Decimal> termNumber = new Set<Decimal>();
        Set<Id> campusIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        //For query child ipe
        Set<Id> ipeIds = new Set<Id>();

        Map<Id, Id> ipeWithIpfId = new Map<Id, Id>();

        //For a later process to retrieve the contact's enrolled study plan:
        //if the SPU has an applicable study plan populated, we can determine whether it matches any of the master or child IPE study plans associated with the contact
        Map<Id, Set<Id>> contactIdWithStudyPlanId = new Map<Id, Set<Id>>();
        for (reduivy__Individual_Pathway__c ipw : ipwRecords) {
            Id studyPathwayId;

            if(String.isNotBlank(ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Pathway__c)) {
                studyPathwayId = ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Pathway__c;
            }

            if (String.isNotBlank(studyPathwayId)) {
                if(!studyPathwayIdWithTermNumbers.containsKey(studyPathwayId)) {
                    studyPathwayIdWithTermNumbers.put(studyPathwayId, new Set<Decimal>());
                }

                if(ipw.reduivy__Term_Number__c != null) {
                    studyPathwayIdWithTermNumbers.get(studyPathwayId).add(ipw.reduivy__Term_Number__c);
                }
            }

            if (String.isNotBlank(ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c) && !contactIdWithStudyPlanId.containsKey(ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c)) {
                contactIdWithStudyPlanId.put(ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, new Set<Id>());
            }

            if(String.isNotBlank(ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Plan__c)) {
                contactIdWithStudyPlanId.get(ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c).add(ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Plan__c);
            }

            // if(String.isNotBlank(ipw.reduivy__Individual_Program_Enrollment__c)) {
            //     ipeIds.add(ipw.reduivy__Individual_Program_Enrollment__c);
            // }

            termNumber.add(ipw.reduivy__Term_Number__c);

            if(String.isNotBlank(ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c)) {
                campusIds.add(ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c);
            }

            if(String.isNotBlank(ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c)) {
                contactIds.add(ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c);
            }

            if(String.isNotBlank(ipw.reduivy__Individual_Program_Enrollment__c) && String.isNotBlank(ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c)) {
                ipeWithIpfId.put(ipw.reduivy__Individual_Program_Enrollment__c, ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c);
            }
        }

        //Query the ipw records for each contact to get the master/child program enrollment’s study plan
        Set<String> ipeQueryFields = new Set<String>{
            'Id',
            'reduivy__Contact__c',
            'reduivy__Study_Plan__c'
        };

        Map<String, Object> ipeBindParams = new Map<String, Object>{
            'activeStatuses' => IPE_Helper.getInProgressStatuses(),
            'contactIds' => contactIds,
            'masterIPEIds' => ipeWithIpfId.keySet()
        };

        String ipeSoqlQuery = 'SELECT ' + String.join(ipeQueryFields, ', ') + 
            ' FROM reduivy__Individual_Program_Enrollment__c ' +
            ' WHERE reduivy__Contact__c IN : contactIds ' + 
            ' AND reduivy__Master_Enrollment__c IN : masterIPEIds ' +
            ' AND reduivy__Enrollment_Status__c IN : activeStatuses ';
        
        List<reduivy__Individual_Program_Enrollment__c> ipeRecords = new List<reduivy__Individual_Program_Enrollment__c>();
        for(reduivy__Individual_Program_Enrollment__c ipe : (List<reduivy__Individual_Program_Enrollment__c>) Database.queryWithBinds(ipeSoqlQuery, ipeBindParams, AccessLevel.USER_MODE)){
            ipeRecords.add(ipe);
        }
        
        for(reduivy__Individual_Program_Enrollment__c ipe : ipeRecords) {
            if (!contactIdWithStudyPlanId.containsKey(ipe.reduivy__Contact__c)) {
                contactIdWithStudyPlanId.put(ipe.reduivy__Contact__c, new Set<Id>());
            }
        
            contactIdWithStudyPlanId.get(ipe.reduivy__Contact__c).add(ipe.reduivy__Study_Plan__c);
        }

        //Query the Study Pathway Term and study pathway unit based on the Term Number and study pathway
        Set<String> sptQueryFields = new Set<String>{
            'Id',
            'reduivy__Term_Number__c',
            'reduivy__Study_Pathway__c'
        };

        Map<String, Object> sptBindParams = new Map<String, Object>{
            'spwIds' => studyPathwayIdWithTermNumbers.keySet(),
            'termNumber' => termNumber
        };

        Set<String> spuQueryFields = new Set<String>{
            'Id',
            'reduivy__Study_Unit__c',
            'reduivy__Study_Unit__r.Name',
            'reduivy__Applicable_Study_Plan__c',
            'reduivy__Study_Pathway_Term__c',
            'reduivy__Study_Plan_Group__c'
        };

        String sptSoqlQuery = 'SELECT ' + String.join(sptQueryFields, ', ') + 
            ' , (SELECT ' + String.join(spuQueryFields, ', ') + ' FROM reduivy__Study_Pathway_Units__r WHERE reduivy__Study_Unit__c != null) ' +
            ' FROM reduivy__Study_Pathway_Term__c ' +
            ' WHERE reduivy__Study_Pathway__c IN : spwIds ' +
            ' AND reduivy__Term_Number__c IN : termNumber ';
        
        List<reduivy__Study_Pathway_Term__c> sptRecords = new List<reduivy__Study_Pathway_Term__c>();
        for(reduivy__Study_Pathway_Term__c spt : (List<reduivy__Study_Pathway_Term__c>) Database.queryWithBinds(sptSoqlQuery, sptBindParams, AccessLevel.USER_MODE)){
            sptRecords.add(spt);
        }
        
        //Study Pathway Id, Term Number, Study Pathway Term
        //For a later process to retrieve the related SPT based on the IPE's study pathway and the IPW's term number.
        Map<Id, Map<Decimal, reduivy__Study_Pathway_Term__c>> studyPathwayIdWithSpt = new Map<Id, Map<Decimal, reduivy__Study_Pathway_Term__c>>();
        //For SOF query bind param
        Set<Id> studyUnitIds = new Set<Id>();

        for (reduivy__Study_Pathway_Term__c spt : sptRecords) {
            if (!studyPathwayIdWithSpt.containsKey(spt.reduivy__Study_Pathway__c)) {
                studyPathwayIdWithSpt.put(spt.reduivy__Study_Pathway__c, new Map<Decimal, reduivy__Study_Pathway_Term__c>());
            }
        
            studyPathwayIdWithSpt.get(spt.reduivy__Study_Pathway__c).put(spt.reduivy__Term_Number__c, spt);

            //Collect all study unit IDs from the study pathway units
            for (reduivy__Study_Pathway_Unit__c spu : spt.reduivy__Study_Pathway_Units__r) {
                if (String.isNotBlank(spu.reduivy__Study_Unit__c)) {
                    studyUnitIds.add(spu.reduivy__Study_Unit__c);
                }
            }
        }

        //Query the study offering
        List<String> sofPositiveStatuses = SOF_Helper.getPositiveStatuses(); //ISS-002785

        Set<String> sofQueryFields = new Set<String>{
            'Id',
            'reduivy__Available_Places__c',
            'reduivy__Unlimited_Places__c',
            'reduivy__Study_Unit__c',
            'reduivy__Campus__c',
            'reduivy__Sequence__c'
        };

        Map<String, Object> sofBindParams = new Map<String, Object>{
            'sunIds' => studyUnitIds,
            'academicTermId' => toBeEnrolledTermId,
            'campusesIds' => campusIds,
            'statuses' => sofPositiveStatuses
        };

        String sofSoqlQuery = 'SELECT ' + String.join(sofQueryFields, ', ') + 
            ' FROM reduivy__Study_Offering__c ' +
            ' WHERE reduivy__Study_Unit__c IN :sunIds ' + 
            ' AND reduivy__Academic_Term__c = :academicTermId ' + 
            ' AND reduivy__Campus__c = :campusesIds ' + 
            ' AND reduivy__Status__c IN :statuses ' + 
            ' FOR UPDATE ';

        List<reduivy__Study_Offering__c> sofRecords = new List<reduivy__Study_Offering__c>();
        for(reduivy__Study_Offering__c sof : (List<reduivy__Study_Offering__c>) Database.queryWithBinds(sofSoqlQuery, sofBindParams, AccessLevel.USER_MODE)){
            sofRecords.add(sof);
        }

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Sequence__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
        };

        sofRecords.sort(new REDU_SObjectComparator(criteria));
        
        //Map for tracking available study offerings by unit and campus
        //StudyUnitId, CampusId, List<Study Offering (ordered by reduivy__Sequence__c)>
        Map<Id, Map<Id, List<reduivy__Study_Offering__c>>> studyUnitIdWithOrderedSofs = new Map<Id, Map<Id, List<reduivy__Study_Offering__c>>>();
        
        //Map to track remaining available places
        Map<Id, Decimal> sofIdToAvailablePlaces = new Map<Id, Decimal>();

        for (reduivy__Study_Offering__c sof : sofRecords) {

            sofIdToAvailablePlaces.put(sof.Id, sof.reduivy__Available_Places__c);
            
            if (!studyUnitIdWithOrderedSofs.containsKey(sof.reduivy__Study_Unit__c)) {
                studyUnitIdWithOrderedSofs.put(sof.reduivy__Study_Unit__c, new Map<Id, List<reduivy__Study_Offering__c>>());
            }
            
            if (!studyUnitIdWithOrderedSofs.get(sof.reduivy__Study_Unit__c).containsKey(sof.reduivy__Campus__c)) {
                studyUnitIdWithOrderedSofs.get(sof.reduivy__Study_Unit__c).put(sof.reduivy__Campus__c, new List<reduivy__Study_Offering__c>());
            }
            
            studyUnitIdWithOrderedSofs.get(sof.reduivy__Study_Unit__c).get(sof.reduivy__Campus__c).add(sof);
        }

        //Query the individual enrollments for each contact
        Set<String> ienQueryFields = new Set<String>{
            'Id',
            'reduivy__Target_Unit_Id__c',
            'reduivy__Contact__c',
            'reduivy__Study_Offering__c',
            'reduivy__Individual_Academic_Progress__c',
            'reduivy__Credit_Transfer_Application__c',
            'reduivy__Enrollment_Status__c',
            'reduivy__Individual_Academic_Profile__c'
        };

        //ISS-002535 - Added to also query IENs with open status to retrieve the placeholder IEN
        List<String> existingIenStatuses = existingIndividualEnrollmentStatuses.split(';');
        List<String> ienOpenStatuses = IEN_Helper.getOpenStatuses();

        Set<String> statusesToBeQueried = new Set<String>();
        statusesToBeQueried.addAll(ienOpenStatuses);
        statusesToBeQueried.addAll(existingIenStatuses);

        Map<String, Object> ienBindParams = new Map<String, Object>{
            'sunIds' => studyUnitIds,
            'contactIds' => contactIds,
            'statusesToBeQueried' => statusesToBeQueried,
            'recordTypeId' =>  IEN_Helper.getStudentRecordTypeId(),
            'ienEnrollmentTypeProgram' => IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            'ipfIds' => ipeWithIpfId.values()
        };

        String ienSoqlQuery = 'SELECT ' + String.join(ienQueryFields, ', ') + 
            ' FROM reduivy__Individual_Enrollment__c ' +
            ' WHERE reduivy__Target_Unit_Id__c IN : sunIds ' + 
            ' AND reduivy__Contact__c IN :contactIds ' + 
            ' AND reduivy__Enrollment_Status__c IN :statusesToBeQueried ' + 
            ' AND RecordTypeId = :recordTypeId ' +
            ' AND reduivy__Enrollment_Type__c = :ienEnrollmentTypeProgram ' +
            ' AND reduivy__Individual_Academic_Profile__c IN :ipfIds ' +
            ' ORDER BY CreatedDate ASC';

        //contact Id, IEN's study unit ids
        //To store the IEN's study unit IDs that the contact has, we will not perform unit enrollment again for any existing IEN study unit with a status other than 'Open'
        Map<Id, Set<Id>> ipfIdWithIenStudyUnitId = new Map<Id, Set<Id>>();
        //ISS-002535 - contact + target unit id, ien
        Map<String, reduivy__Individual_Enrollment__c> existingOpenIenForIdvAcademicProfileWithStudyUnit = new Map<String, reduivy__Individual_Enrollment__c>();

        for(reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) Database.queryWithBinds(ienSoqlQuery, ienBindParams, AccessLevel.USER_MODE)){
            // ISS-002535 - If the IEN matches any of the configured existing IEN statuses, we consider that this contact no longer needs to enroll in the study unit.
            // If the IEN has an open status and is not in one of the configured statuses, we add it to the map for later use.
            if(existingIenStatuses.contains(ien.reduivy__Enrollment_Status__c)) {
                if (!ipfIdWithIenStudyUnitId.containsKey(ien.reduivy__Individual_Academic_Profile__c)) {
                    ipfIdWithIenStudyUnitId.put(ien.reduivy__Individual_Academic_Profile__c, new Set<Id>());
                }
            
                ipfIdWithIenStudyUnitId.get(ien.reduivy__Individual_Academic_Profile__c).add(ien.reduivy__Target_Unit_Id__c );
            } else if (ienOpenStatuses.contains(ien.reduivy__Enrollment_Status__c)) {

                if(String.isBlank(ien.reduivy__Study_Offering__c) && String.isBlank(ien.reduivy__Individual_Academic_Progress__c) && String.isBlank(ien.reduivy__Credit_Transfer_Application__c)) {
                    String key = ien.reduivy__Individual_Academic_Profile__c + '_' + ien.reduivy__Target_Unit_Id__c;

                    if(!existingOpenIenForIdvAcademicProfileWithStudyUnit.containsKey(key)) {
                        existingOpenIenForIdvAcademicProfileWithStudyUnit.put(key, ien);
                    }
                }
            }
        }

        //Process enrollments
        Id IenStudentRecordTypeId = IEN_Helper.getStudentRecordTypeId();
        String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
        Map<Id, List<reduivy__Individual_Enrollment__c>> ipwIdWithIenList = new Map<Id, List<reduivy__Individual_Enrollment__c>>();

        //To track the corresponding IPW ID for each IEN for error handling, the sequence should be the same as iensToBeCreated
        List<Id> ipwRefForIensToBeCreated = new List<Id>();

        //To store the IEN records to be created
        List<reduivy__Individual_Enrollment__c> iensToBeCreated = new List<reduivy__Individual_Enrollment__c>();

        //To store the failure exception for each IPW ID
        Map<Id, List<String>> ipwIdWithFailureLogs = new Map<Id, List<String>>();

        for (reduivy__Individual_Pathway__c ipw : ipwRecords) {
            //init an empty failure logs
            ipwIdWithFailureLogs.put(ipw.Id, new List<String>());

            //Get the contact Id, study pathway id, campus id, term number of the ipw
            Id contactId = ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c;
            Id studyPathwayId = ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Pathway__c;
            Id campusId = ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c;
            Id academicProfileId = ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c;
            Decimal termNum = ipw.reduivy__Term_Number__c;

            //To store the IPW's applicable study plan for later use
            Set<Id> contactsStudyPlanIds = contactIdWithStudyPlanId.containsKey(contactId) ? 
            contactIdWithStudyPlanId.get(contactId) : new Set<Id>();

            //To store the study units that are already enrolled
            Set<Id> enrolledStudyUnits = ipfIdWithIenStudyUnitId.containsKey(academicProfileId) ?
            ipfIdWithIenStudyUnitId.get(academicProfileId) : new Set<Id>();

            //To get the related SPT that matches the IPW's study pathway and term number
            reduivy__Study_Pathway_Term__c spt = studyPathwayIdWithSpt.containsKey(studyPathwayId) && 
            studyPathwayIdWithSpt.get(studyPathwayId).containsKey(termNum) ? 
            studyPathwayIdWithSpt.get(studyPathwayId).get(termNum) : null;

            if (spt != null && String.isNotBlank(academicProfileId)) {
                //Loop for each study pathway units in the SPT
                for (reduivy__Study_Pathway_Unit__c spu : spt.reduivy__Study_Pathway_Units__r) {
                    Id studyUnitId = spu.reduivy__Study_Unit__c;

                    //To check if the IPW's contact has enrolled in the study unit or not
                    //To check if the study pathway unit has a specified applicable study plan or not
                    //If yes, verify whether the applicable study plan matches any study plan that the contact's master/child IPE has enrolled in
                    if (!enrolledStudyUnits.contains(studyUnitId)) {
                        if(String.isBlank(spu.reduivy__Applicable_Study_Plan__c) || contactsStudyPlanIds.contains(spu.reduivy__Applicable_Study_Plan__c)) {
                            Boolean enrollmentSuccessful = false;

                            //Check if there are offerings for this unit and campus
                            if (studyUnitIdWithOrderedSofs.containsKey(studyUnitId) && 
                                studyUnitIdWithOrderedSofs.get(studyUnitId).containsKey(campusId)) {
                                
                                //The offerings are already ordered by sequence from the query
                                List<reduivy__Study_Offering__c> availableOfferings = 
                                    studyUnitIdWithOrderedSofs.get(studyUnitId).get(campusId);
                                
                                //Find first offering with available places
                                for (reduivy__Study_Offering__c sof : availableOfferings) {
                                    Decimal availablePlaces = sofIdToAvailablePlaces.get(sof.Id);

                                    if (sof.reduivy__Unlimited_Places__c || availablePlaces > 0) {
                                        reduivy__Individual_Enrollment__c tempIen = new reduivy__Individual_Enrollment__c(
                                            reduivy__Contact__c = contactId,
                                            reduivy__Study_Offering__c = sof.Id,
                                            RecordTypeId = ienStudentRecordTypeId,
                                            reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS,
                                            reduivy__Bypass_Requirement_Met__c = bypassRequirementRules,
                                            reduivy__Auto_Enrollment__c = true,
                                            reduivy__Individual_Academic_Profile__c = academicProfileId
                                        );

                                        // ISS-002535 - Try to find a placeholder IEN for the contactId + studyUnitId, if found, use it for the upsert; otherwise, create a new one.
                                        String key = academicProfileId + '_' + studyUnitId; 
                                        if(existingOpenIenForIdvAcademicProfileWithStudyUnit.containsKey(key)) {
                                            tempIen.Id = existingOpenIenForIdvAcademicProfileWithStudyUnit.get(key).Id;
                                        }

                                        //Create enrollment
                                        iensToBeCreated.add(tempIen);

                                        //Add the current IPW ID to the ipwRefForIensToBeCreated list so that the index of iensToBeCreated corresponds to the index of ipwRefForIensToBeCreated
                                        ipwRefForIensToBeCreated.add(ipw.Id);

                                        enrollmentSuccessful = true;
                                        
                                        //Update available places if not unlimited
                                        if (!(sof.reduivy__Unlimited_Places__c) && availablePlaces > 0) {
                                            sofIdToAvailablePlaces.put(sof.Id, availablePlaces - 1);
                                        }
                                        
                                        //Add to enrolled units to prevent duplicate enrollments
                                        enrolledStudyUnits.add(studyUnitId);
                                        break; //Move to next unit
                                    }

                                    //If the execution does not enter the 'if' block for available places checking, it will proceed to loop for the next SOF
                                }
                            }

                            //If the SOF is not found or if all of the applicable SOF's available places are full
                            if(!enrollmentSuccessful) {                            
                                ipwIdWithFailureLogs.get(ipw.Id).add(String.format(Label.Term_Student_Enrollment_No_Available_Place_Remaining_In_Study_Offering_Error_Msg,
                                new List<String>{IPE_Helper.getObjectLabel(), ipw.reduivy__Individual_Program_Enrollment__r.Name, SOF_Helper.getObjectLabel(), SUN_Helper.getObjectLabel(),spu.reduivy__Study_Unit__r.Name}));
                            }
                        }    
                    } else {
                        resultMonitor.addWarningResult(ipw.Id, String.format(Label.Term_Student_Enrollment_Already_Enrolled_To_The_Study_Unit,
                        new List<String>{SUN_Helper.getObjectLabel(), spu.reduivy__Study_Unit__r.Name, IPE_Helper.getObjectLabel(), ipw.reduivy__Individual_Program_Enrollment__r.Name, IEN_Helper.getObjectLabel(), ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.Name}));
                    }
                }
            } else if (spt == null) { //If the SPT is not found   
                ipwIdWithFailureLogs.get(ipw.Id).add(String.format(Label.Term_Student_Enrollment_No_Applicable_Study_Pathway_Term_Found,
                new List<String>{SPT_Helper.getObjectLabel(), ipw.reduivy__Individual_Program_Enrollment__r.Name, IPE_Helper.getObjectLabel(), SPW_Helper.getObjectLabel(), (ipw.reduivy__Term_Number__c).toString()}));
            } else if (String.isBlank(academicProfileId)) { //If IPF not found
                ipwIdWithFailureLogs.get(ipw.Id).add(String.format(Label.Term_Student_Enrollment_IPW_Parent_IPE_Not_Linked_to_IPF,
                new List<String>{IPE_Helper.getObjectLabel(), ipw.reduivy__Individual_Program_Enrollment__r.Name, IPF_Helper.getObjectLabel()}));
            }
        }

        if(!iensToBeCreated.isEmpty()) {
             //Can't use REDU_Database_UTIL to add errors because these aren't trigger records
             List<Database.UpsertResult> upsertResults = Database.upsert(iensToBeCreated, false, AccessLevel.USER_MODE);
            
            //Track success/failure
            Integer counter = 0;
            for (Database.UpsertResult sr : upsertResults){
                if (!sr.isSuccess()) {
                    Id correspondingIpwId = ipwRefForIensToBeCreated.get(counter);
                
                    ipwIdWithFailureLogs.get(correspondingIpwId).add(REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage()));
                }

                counter ++;
            }
        }

        if(!ipwIdWithFailureLogs.isEmpty()) {
            for(Id ipwId : ipwIdWithFailureLogs.keySet()) {
                List<String> errorMsgs = ipwIdWithFailureLogs.get(ipwId);

                if (!errorMsgs.isEmpty()) {
                    for(String erroMsg : errorMsgs) {
                        resultMonitor.addFailResult(ipwId, erroMsg);
                    }

                    if(resultMonitor.success.containsKey(ipwId)) {
                        resultMonitor.success.remove(ipwId);
                    }
                }
            }
        }
    }
}