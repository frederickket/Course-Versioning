/**
 * @author      WDCi (XiRouh)
 * @date        Feb 2025
 * @group       Term Student Enrollment
 * @description Test class for JQH_TermStudentEnrollment_HANDLER
 * @changehistory
 * ISS-002229 14-02-2025 XiRouh - new class
 * ISS-002535 15-07-2025 XiRouh - Added new test method to cover the scenarios in ISS-002535
 * ISS-002743 15-12-2025 XiRouh - Added test methods to consider the IEN within the same Individual Academic Profile context and Updated test methods that create IENs to link them with IPF
 * ISS-002785 28-01-2026 Lean - Added new test to cover enrollment with cancelled study offering
 */
@isTest
public inherited sharing class JQH_TermStudentEnrollment_TEST {
 
    private static final String JOB_OPERATION = 'Term_Student_Enrollment';
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);
    static final String SOF_POSITIVE_STATUS = SOF_Helper.getPositiveStatuses().get(0);
    static final String SPL_MAJOR = 'BACBIS_MajorA';
    static final String STUDY_INTAKE = 'SYDNEY_BACBIS_CYINTAKE';

    /**
     * @description Default method to setup required data for automated test
     */
    @TestSetup
    static void makeData(){

        // Create settings
		testFactory.setupDefaultSettings();

        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();
            testFactory.FULLDATA = true;
            testFactory.initMasterData(null);
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initStudentData(IAC_Helper.getApiName(), true);

            List<reduivy__Individual_Program_Enrollment__c> masterIpeList = new List<reduivy__Individual_Program_Enrollment__c>();

            for (Contact student : testFactory.students.values()) {
                String masterIpekey = student.reduivy__Sample_Record_Code__c + '_' + SPL_MAJOR;

                reduivy__Individual_Program_Enrollment__c newMasterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    masterIpekey, 
                    student.Id, 
                    testFactory.studyPlans.get(SPL_MAJOR).reduivy__Study_Program__c, 
                    testFactory.studyPlans.get(SPL_MAJOR).Id, 
                    testFactory.studyIntakes.get(STUDY_INTAKE).Id, 
                    testFactory.academicTerms.get('CYT1').Id, 
                    testFactory.studyIntakes.get(STUDY_INTAKE).reduivy__Default_Study_Pathway__c, 
                    testFactory.campuses.get('SYDNEY').Id, 
                    String.valueOf(testFactory.academicTerms.get('CYT1').reduivy__Start_Date__c.year()), 
                    'Freshman', 
                    true, 
                    IPE_INPROGRESS_STATUS, 
                    null
                );

                masterIpeList.add(newMasterIpe);
            }

            //To set sequence for each contact
            REDU_SystemMode_UTIL.doUpdate(testFactory.students.values());
            REDU_SystemMode_UTIL.doInsert(masterIpeList);

            List<reduivy__Individual_Program_Enrollment__c> ipes = [SELECT Id, (SELECT Id, reduivy__Term_Number__c, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Pathways__r ORDER BY reduivy__Term_Number__c) FROM reduivy__Individual_Program_Enrollment__c ORDER BY reduivy__Contact__r.reduivy__Sequence__c ASC];
            List<reduivy__Individual_Program_Enrollment__c> ipesToBeUpdated = new List<reduivy__Individual_Program_Enrollment__c>();

            for(reduivy__Individual_Program_Enrollment__c ipe : ipes) {
                ipesToBeUpdated.add(new reduivy__Individual_Program_Enrollment__c(Id = ipe.Id, reduivy__Auto_Enrollment__c = IPE_Helper.AUTO_ENROLLMENT_AUTO));
            }

            REDU_SystemMode_UTIL.doUpdate(ipesToBeUpdated);

            Test.stopTest();
        }
    }

    /**
     * @description Test execute() as admin
     */
    @IsTest
    static void testExecuteAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        String autoStatus = IPE_Helper.AUTO_ENROLLMENT_AUTO;

        List<reduivy__Individual_Program_Enrollment__c> ipes = [
            SELECT Id, reduivy__Default_Campus__c, reduivy__Starting_Term__r.reduivy__End_Date__c, 
            (SELECT Id, reduivy__Term_Number__c, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c 
            FROM reduivy__Individual_Pathways__r ORDER BY reduivy__Term_Number__c) 
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Auto_Enrollment__c = :autoStatus
            ORDER BY reduivy__Contact__r.reduivy__Sequence__c ASC
        ];
        
        Date toBeEnrolledTermStartDate = ipes[0].reduivy__Starting_Term__r.reduivy__End_Date__c.addDays(31);
        List<reduivy__Study_Term__c> terms = [SELECT Id, Name, reduivy__End_Date__c, reduivy__Start_Date__c FROM reduivy__Study_Term__c WHERE reduivy__Start_Date__c = :toBeEnrolledTermStartDate];
    
        List<reduivy__Study_Unit__c> studyUnits = [SELECT Id FROM reduivy__Study_Unit__c];
        List<reduivy__Study_Offering__c> studyOfferingsToBeCreated = new List<reduivy__Study_Offering__c>();
        
        for(reduivy__Study_Unit__c su : studyUnits) {
            studyOfferingsToBeCreated.add(new reduivy__Study_Offering__c(
                reduivy__Unlimited_Places__c = true,
                reduivy__Study_Unit__c = su.Id,
                reduivy__Academic_Term__c = terms[0].Id,
                reduivy__Campus__c = ipes[0].reduivy__Default_Campus__c,
                reduivy__Start_Date__c = terms[0].reduivy__Start_Date__c,
                reduivy__End_Date__c = terms[0].reduivy__End_Date__c
            ));         
        }

        REDU_SystemMode_UTIL.doInsert(studyOfferingsToBeCreated);

        List<reduivy__Individual_Pathway__c> ipws = [SELECT Id FROM reduivy__Individual_Pathway__c];
        List<Id> ipwIds = new List<Id>();
        for (reduivy__Individual_Pathway__c ipw : ipws) {
            ipwIds.add(ipw.Id);
        }

        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Cancelled';
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', terms[0].Id);
        params.put('proceedForUnitEnrollment', true);
        params.put('bypassRequirementRules', true);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, terms[0].Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, terms[0].Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, terms[0].Name);
            
        System.runAs(ADMIN_USER) {            
            JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
            handler.setRecordIds(ipwIds);
            handler.setParams(params);
            
            Test.startTest();
            JQH_JobManager.HandlerResult result = handler.execute();

            System.assertEquals(0, result.fail.size(), 'Should not have any failures');
        }

        Test.stopTest();
    }

    /**
     * @description Nagative Test execute() as admin
     */
    @IsTest
    static void nagativeTestExecuteAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<reduivy__Individual_Pathway__c> ipws = [SELECT Id FROM reduivy__Individual_Pathway__c];
        List<Id> ipwIds = new List<Id>();
        for (reduivy__Individual_Pathway__c ipw : ipws) {
            ipwIds.add(ipw.Id);
        }

        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Cancelled';

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', 'invalidId'); // Invalid ID to force error
        params.put('proceedForUnitEnrollment', true);
        params.put('bypassRequirementRules', false);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        
        // Create and configure the handler
        JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
        handler.setRecordIds(ipwIds);
        handler.setParams(params);
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            JQH_JobManager.HandlerResult result = handler.execute();
            Test.stopTest();
            
            System.assertEquals(ipwIds.size(), result.fail.size(), 'Should have failures for all invalid records');
        }
    }

    /**
     * @description Test performTermEnrollment() as admin
     */
    @IsTest
    static void testPerformTermEnrollmentAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        String autoStatus = IPE_Helper.AUTO_ENROLLMENT_AUTO;
            
        List<reduivy__Individual_Program_Enrollment__c> ipes = [
            SELECT Id, reduivy__Starting_Term__r.reduivy__End_Date__c, 
            (SELECT Id, reduivy__Term_Number__c, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c 
            FROM reduivy__Individual_Pathways__r ORDER BY reduivy__Term_Number__c) 
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE reduivy__Auto_Enrollment__c = :autoStatus
            ORDER BY reduivy__Contact__r.reduivy__Sequence__c ASC
        ];

        List<Id> ipwIds = new List<Id>();

        for(reduivy__Individual_Program_Enrollment__c ipe : ipes) {
            for(reduivy__Individual_Pathway__c ipw : ipe.reduivy__Individual_Pathways__r) {
                if(ipw.reduivy__Term_Number__c == 2) {
                    ipwIds.add(ipw.Id);
                }
            }
        }

        Date toBeEnrolledTermStartDate = ipes[0].reduivy__Starting_Term__r.reduivy__End_Date__c.addDays(31);
        List<reduivy__Study_Term__c> terms = [SELECT Id, Name FROM reduivy__Study_Term__c WHERE reduivy__Start_Date__c = :toBeEnrolledTermStartDate];
        
        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Cancelled';

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', terms[0].Id);
        params.put('proceedForUnitEnrollment', false);
        params.put('bypassRequirementRules', false);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, terms[0].Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, terms[0].Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, terms[0].Name);
        
        JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
        handler.setRecordIds(ipwIds);
        handler.setParams(params);

        System.runAs(ADMIN_USER) {            
            Test.startTest();
            JQH_JobManager.HandlerResult result = handler.execute();
            
            List<reduivy__Individual_Pathway__c> updatedIpws = [
                SELECT Id, reduivy__Academic_Term__c 
                FROM reduivy__Individual_Pathway__c 
                WHERE Id IN :ipwIds 
                AND reduivy__Academic_Term__c != null
                AND reduivy__Academic_Term__c = :terms[0].Id
                AND reduivy__Auto_Enrollment__c = true
            ];
            
            System.assertEquals(0, result.fail.size(), 'There should be no failures');
        }

        Test.stopTest();
    }

    /**
     * @description Test performUnitEnrollment() as admin
     */
    @IsTest
    static void testPerformUnitEnrollmentAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        String autoStatus = IPE_Helper.AUTO_ENROLLMENT_AUTO;

        reduivy__Study_Plan__c bacComStudyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACCOM_MajorA'];

        List<reduivy__Individual_Program_Enrollment__c> ipes = [
            SELECT Id, reduivy__Contact__c, reduivy__Default_Campus__c, reduivy__Starting_Term__r.reduivy__End_Date__c, reduivy__Study_Pathway__c, reduivy__Study_Plan__c, reduivy__Study_Program__c, reduivy__Individual_Academic_Profile__c,
            (SELECT Id, reduivy__Term_Number__c, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c 
            FROM reduivy__Individual_Pathways__r ORDER BY reduivy__Term_Number__c) 
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Auto_Enrollment__c = :autoStatus
            ORDER BY reduivy__Contact__r.reduivy__Sequence__c ASC
        ];
        
        Date toBeEnrolledTermStartDate = ipes[0].reduivy__Starting_Term__r.reduivy__End_Date__c.addDays(31);
        List<reduivy__Study_Term__c> terms = [SELECT Id, Name, reduivy__End_Date__c, reduivy__Start_Date__c FROM reduivy__Study_Term__c WHERE reduivy__Start_Date__c = :toBeEnrolledTermStartDate];
        List<reduivy__Study_Term__c> randomTerms = [SELECT Id FROM reduivy__Study_Term__c WHERE Id NOT IN (:ipes[0].reduivy__Starting_Term__c, :terms[0].Id) AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId()];

        List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, Name FROM reduivy__Study_Unit__c];
        List<reduivy__Study_Offering__c> studyOfferingsToBeCreated = new List<reduivy__Study_Offering__c>();
        
        for(reduivy__Study_Unit__c su : studyUnits) {
            if(su.Name != 'MGT301' && su.Name != 'MGT302') {                
                Decimal capacity = su.Name == 'BUS201' || su.Name == 'BUS202' ? 3 : 1;

                studyOfferingsToBeCreated.add(new reduivy__Study_Offering__c(
                    reduivy__Capacity__c = capacity,
                    reduivy__Study_Unit__c = su.Id,
                    reduivy__Academic_Term__c = terms[0].Id,
                    reduivy__Campus__c = ipes[0].reduivy__Default_Campus__c,
                    reduivy__Start_Date__c = terms[0].reduivy__Start_Date__c,
                    reduivy__End_Date__c = terms[0].reduivy__End_Date__c
                ));  
            }   
        }

        REDU_SystemMode_UTIL.doInsert(studyOfferingsToBeCreated);

        List<reduivy__Study_Offering__c> toBeEnrolledSof = [SELECT Id FROM reduivy__Study_Offering__c WHERE reduivy__Study_Unit__r.Name IN ('BUS101', 'BUS102', 'BUS103', 'COM101')];
        List<reduivy__Study_Pathway_Unit__c> spuWithApplicableStudyPlan = [SELECT Id FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :ipes[0].reduivy__Study_Pathway__c AND (reduivy__Study_Unit__r.Name = 'BUS201' OR reduivy__Study_Unit__r.Name = 'BUS202')];

        spuWithApplicableStudyPlan[0].reduivy__Applicable_Study_Plan__c = ipes[0].reduivy__Study_Plan__c;
        spuWithApplicableStudyPlan[1].reduivy__Applicable_Study_Plan__c = ipes[0].reduivy__Study_Plan__c;
        update spuWithApplicableStudyPlan;

        List<reduivy__Study_Pathway_Term__c> sptWithTermNumber4 = [SELECT Id FROM reduivy__Study_Pathway_Term__c WHERE reduivy__Study_Pathway__c = :ipes[0].reduivy__Study_Pathway__c AND reduivy__Term_Number__c = 4];
        delete sptWithTermNumber4;

        List<reduivy__Study_Plan__c> otherStudyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Id != :ipes[0].reduivy__Study_Plan__c LIMIT 1];

        // Create new Individual Academic Profiles for testing
        Map<Id, reduivy__Individual_Academic_Profile__c> contactToNewIpfMap = new Map<Id, reduivy__Individual_Academic_Profile__c>();
        List<reduivy__Individual_Academic_Profile__c> newIpfList = new List<reduivy__Individual_Academic_Profile__c>();
        
        for(Integer i = 0; i < 8; i++) {
            reduivy__Individual_Program_Enrollment__c ipe = ipes[i];
            
            reduivy__Individual_Academic_Profile__c newIpf = REDU_TestData_UTIL.newIndividualAcademicProfile(
                'AutoEnroll_IPF_' + i,
                ipe.reduivy__Contact__c,
                'AutoEnroll_IPF_' + i,
                IPF_Helper.STATUS_ACTIVE,
                true
            );
            
            newIpfList.add(newIpf);
            contactToNewIpfMap.put(ipe.reduivy__Contact__c, newIpf);
        }
        
        insert newIpfList;
        
        // Update IPEs to link with new IPFs
        List<reduivy__Individual_Program_Enrollment__c> ipesToUpdateWithNewIpf = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Integer i = 0; i < 8; i++) {
            reduivy__Individual_Program_Enrollment__c ipe = ipes[i];
            ipe.reduivy__Individual_Academic_Profile__c = contactToNewIpfMap.get(ipe.reduivy__Contact__c).Id;
            ipesToUpdateWithNewIpf.add(ipe);
        }
        
        update ipesToUpdateWithNewIpf;

        Map<Decimal, Id> expectedResultMap = new Map<Decimal, Id>();
        List<Id> ipwIds = new List<Id>();

        List<reduivy__Individual_Pathway__c> ipwsToBeUpdated = new List<reduivy__Individual_Pathway__c>();
        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> ipesToBeUpdated = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childIpeToBeCreated = new List<reduivy__Individual_Program_Enrollment__c>();

        for(Integer i = 0; i < 8; i++) {
            reduivy__Individual_Program_Enrollment__c ipe = ipes[i];

            for(reduivy__Individual_Pathway__c ipw : ipe.reduivy__Individual_Pathways__r) {

                if(i == 0) { //1. Normal Success Scenario
                    if(ipw.reduivy__Term_Number__c == 1) {
                        ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = null, reduivy__Individual_Academic_Progress__c = null));
                        ipwIds.add(ipw.Id);
                    }
                }

                if(i == 1) { //2. Have enrolled (warning)
                    if(ipw.reduivy__Term_Number__c == 1) {
                        ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = null, reduivy__Individual_Academic_Progress__c = null));
                        ipwIds.add(ipw.Id);

                        ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                            reduivy__Contact__c = ipe.reduivy__Contact__c,
                            reduivy__Study_Offering__c = toBeEnrolledSof[0].Id,
                            RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
                            reduivy__Enrollment_Status__c = IEN_Helper.getInProgressStatuses()[0],
                            reduivy__Bypass_Requirement_Met__c = true,
                            reduivy__Individual_Academic_Profile__c = contactToNewIpfMap.get(ipe.reduivy__Contact__c).Id
                        ));

                        ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                            reduivy__Contact__c = ipe.reduivy__Contact__c,
                            reduivy__Study_Offering__c = toBeEnrolledSof[1].Id,
                            RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
                            reduivy__Enrollment_Status__c = IEN_Helper.getInProgressStatuses()[0],
                            reduivy__Bypass_Requirement_Met__c = true,
                            reduivy__Individual_Academic_Profile__c = contactToNewIpfMap.get(ipe.reduivy__Contact__c).Id
                        ));

                        ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                            reduivy__Contact__c = ipe.reduivy__Contact__c,
                            reduivy__Study_Offering__c = toBeEnrolledSof[2].Id,
                            RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
                            reduivy__Enrollment_Status__c = IEN_Helper.getInProgressStatuses()[0],
                            reduivy__Bypass_Requirement_Met__c = true,
                            reduivy__Individual_Academic_Profile__c = contactToNewIpfMap.get(ipe.reduivy__Contact__c).Id
                        ));

                        ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                            reduivy__Contact__c = ipe.reduivy__Contact__c,
                            reduivy__Study_Offering__c = toBeEnrolledSof[3].Id,
                            RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
                            reduivy__Enrollment_Status__c = IEN_Helper.getInProgressStatuses()[0],
                            reduivy__Bypass_Requirement_Met__c = true,
                            reduivy__Individual_Academic_Profile__c = contactToNewIpfMap.get(ipe.reduivy__Contact__c).Id
                        ));
                    }
                }

                if(i == 2) { //3. Exceed Study Offering available places (error)
                    if(ipw.reduivy__Term_Number__c == 1) {
                        ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = terms[0].Id));
                        ipwIds.add(ipw.Id);
                    }
                }

                if(i == 3) { //4. Have applicable study plan populated and it is not match with the IPE's study plan (skipped without error or warning logged)  
                    if(ipw.reduivy__Term_Number__c == 2) {
                        ipwIds.add(ipw.Id);

                        ipesToBeUpdated.add(new reduivy__Individual_Program_Enrollment__c(Id = ipe.Id, reduivy__Study_Plan__c = otherStudyPlan[0].Id));
                    }
                }

                if(i == 4) { //5. Have applicable study plan populated and it is match with the Master IPE's study plan               
                    if(ipw.reduivy__Term_Number__c == 2) {
                        ipwIds.add(ipw.Id);
                    }
                }

                if(i == 5) { //6. Have applicable study plan populated and it is match with the Child IPE's study plan            
                    if(ipw.reduivy__Term_Number__c == 2) {
                        ipwIds.add(ipw.Id);

                        ipesToBeUpdated.add(new reduivy__Individual_Program_Enrollment__c(Id = ipe.Id, reduivy__Study_Plan__c = otherStudyPlan[0].Id));

                        childIpeToBeCreated.add(REDU_TestData_UTIL.newChildIndividualProgramEnrollment(
                            'Test Child IPE', 
                            ipe.reduivy__Contact__c,
                            ipe.reduivy__Study_Program__c, 
                            ipe.reduivy__Study_Plan__c, 
                            ipe.Id, 
                            IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, 
                            true, 
                            IPE_INPROGRESS_STATUS
                        ));
                    }
                }

                if(i == 6) { //7. Study Offering not found (error)
                    if(ipw.reduivy__Term_Number__c == 1) {
                        ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = randomTerms[0].Id));
                    }

                    if(ipw.reduivy__Term_Number__c == 2) {
                        ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = ipes[0].reduivy__Starting_Term__c));
                    }

                    if(ipw.reduivy__Term_Number__c == 3) {
                        ipwIds.add(ipw.Id);
                    }
                }

                if(i == 7) { //8. Study Pathway Term not found (error)
                    if(ipw.reduivy__Term_Number__c == 1) {
                        ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = randomTerms[0].Id));
                    }

                    if(ipw.reduivy__Term_Number__c == 2) {
                        ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = randomTerms[1].Id));
                    }

                    if(ipw.reduivy__Term_Number__c == 3) {
                        ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = ipes[0].reduivy__Starting_Term__c));
                    }

                    if(ipw.reduivy__Term_Number__c == 4) {
                        ipwIds.add(ipw.Id);
                    }
                }
            }
        }

        REDU_SystemMode_UTIL.doUpdate(ipesToBeUpdated);
        REDU_SystemMode_UTIL.doInsert(ienToBeCreated);
        REDU_SystemMode_UTIL.doInsert(childIpeToBeCreated);
        REDU_SystemMode_UTIL.doUpdate(ipwsToBeUpdated);

        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Cancelled;';

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', terms[0].Id);
        params.put('proceedForUnitEnrollment', true);
        params.put('bypassRequirementRules', true);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, terms[0].Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, terms[0].Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, terms[0].Name);

        JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
        handler.setRecordIds(ipwIds);
        handler.setParams(params);

        System.runAs(ADMIN_USER) {            
            Test.startTest();
            JQH_JobManager.HandlerResult result = handler.execute();

            List<reduivy__Individual_Enrollment__c> enrolledIEN = [
                SELECT Id, 
                reduivy__Contact__c, 
                reduivy__Individual_Academic_Profile__c,
                reduivy__Target_Unit_Id__c
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Auto_Enrollment__c = true
            ];
            
            System.Assert.areEqual(8, enrolledIEN.size(), '8 Individual Enrollment should be created');

            // Assert that all auto-created enrollments are linked to the correct Individual Academic Profile
            for(reduivy__Individual_Enrollment__c ien : enrolledIEN) {
                System.Assert.isNotNull(ien.reduivy__Individual_Academic_Profile__c, 'Individual Academic Profile should be set for auto-created enrollment');
                System.Assert.areEqual(
                    contactToNewIpfMap.get(ien.reduivy__Contact__c).Id,
                    ien.reduivy__Individual_Academic_Profile__c,
                    'Individual Academic Profile should match the IPE profile for contact'
                );
            }

            System.assertEquals(3, result.fail.size(), 'There should be 3 failures');
            System.assertEquals(1, result.warning.size(), 'There should be 1 warning');
            
            Test.stopTest();
        }
    }

    /**
     * @description ISS-002785 Test performTermEnrollment() with study offering = cancelled status as admin
     */
    @IsTest
    static void testPerformUnitEnrollmentWithStudyOfferingCancelledAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        //cancel all study offering
        List<reduivy__Study_Offering__c> sofList = [SELECT Id, reduivy__Status_Override__c
            FROM reduivy__Study_Offering__c
        ];

        for (reduivy__Study_Offering__c sof : sofList) {
            sof.reduivy__Status_Override__c = 'Cancelled';
        }

        REDU_Database_UTIL.doUpdate(sofList);

        //start the auto enrollment process
        String autoStatus = IPE_Helper.AUTO_ENROLLMENT_AUTO;
            
        List<reduivy__Individual_Program_Enrollment__c> ipes = [
            SELECT Id, reduivy__Starting_Term__r.reduivy__End_Date__c, 
            (SELECT Id, reduivy__Term_Number__c, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c 
            FROM reduivy__Individual_Pathways__r ORDER BY reduivy__Term_Number__c) 
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE reduivy__Auto_Enrollment__c = :autoStatus
            ORDER BY reduivy__Contact__r.reduivy__Sequence__c ASC
        ];

        List<Id> ipwIds = new List<Id>();

        for(reduivy__Individual_Program_Enrollment__c ipe : ipes) {
            for(reduivy__Individual_Pathway__c ipw : ipe.reduivy__Individual_Pathways__r) {
                if(ipw.reduivy__Term_Number__c == 2) {
                    ipwIds.add(ipw.Id);
                }
            }
        }

        Date toBeEnrolledTermStartDate = ipes[0].reduivy__Starting_Term__r.reduivy__End_Date__c.addDays(31);
        List<reduivy__Study_Term__c> terms = [SELECT Id, Name FROM reduivy__Study_Term__c WHERE reduivy__Start_Date__c = :toBeEnrolledTermStartDate];
        
        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Cancelled';

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', terms[0].Id);
        params.put('proceedForUnitEnrollment', true);
        params.put('bypassRequirementRules', true);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, terms[0].Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, terms[0].Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, terms[0].Name);
        
        JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
        handler.setRecordIds(ipwIds);
        handler.setParams(params);

        Test.startTest();

        System.runAs(ADMIN_USER) {
            JQH_JobManager.HandlerResult result = handler.execute();
            
            System.debug(JSON.serialize(result));

            List<reduivy__Individual_Pathway__c> updatedIpws = [
                SELECT Id,
                reduivy__Academic_Term__c,
                reduivy__Auto_Enrollment__c,
                reduivy__Individual_Program_Enrollment__r.Name
                FROM reduivy__Individual_Pathway__c 
                WHERE Id IN :ipwIds 
                AND reduivy__Academic_Term__c != null
                AND reduivy__Academic_Term__c = :terms[0].Id
            ];
            
            System.Assert.areEqual(ipwIds.size(), updatedIpws.size(), 'There is no individual pathway found for assertion.');

            Set<String> pathwayUnits = new Set<String>{
                'BUS201',
                'BUS202'
            };

            for (reduivy__Individual_Pathway__c ipw : updatedIpws) {
                System.Assert.areEqual(true, ipw.reduivy__Auto_Enrollment__c);
                System.Assert.areEqual(true, result.fail.containsKey(ipw.Id));

                Integer errorCount = 0;
                for (String unitCode : pathwayUnits) {
                    String expectedError = String.format(Label.Term_Student_Enrollment_No_Available_Place_Remaining_In_Study_Offering_Error_Msg, 
                        new List<String>{IPE_Helper.getObjectLabel(), ipw.reduivy__Individual_Program_Enrollment__r.Name, SOF_Helper.getObjectLabel(), SUN_Helper.getObjectLabel(), unitCode}
                    );

                    for (String errorMsg : result.fail.get(ipw.Id)) {
                        if (expectedError == errorMsg) {
                            errorCount ++;
                        }
                    }
                }

                System.Assert.areEqual(2, errorCount);

            }


        }

        Test.stopTest();
    }

    /**
     * @description ISS-002785 Test performTermEnrollment() with study offering = draft status as admin
     */
    @IsTest
    static void testPerformUnitEnrollmentWithStudyOfferingDraftAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        //cancel all study offering
        List<reduivy__Study_Offering__c> sofList = [SELECT Id, reduivy__Status_Override__c
            FROM reduivy__Study_Offering__c
        ];

        for (reduivy__Study_Offering__c sof : sofList) {
            sof.reduivy__Status_Override__c = 'Draft';
        }

        REDU_Database_UTIL.doUpdate(sofList);

        //start the auto enrollment process
        String autoStatus = IPE_Helper.AUTO_ENROLLMENT_AUTO;
            
        List<reduivy__Individual_Program_Enrollment__c> ipes = [
            SELECT Id, reduivy__Starting_Term__r.reduivy__End_Date__c, 
            (SELECT Id, reduivy__Term_Number__c, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c 
            FROM reduivy__Individual_Pathways__r ORDER BY reduivy__Term_Number__c) 
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE reduivy__Auto_Enrollment__c = :autoStatus
            ORDER BY reduivy__Contact__r.reduivy__Sequence__c ASC
        ];

        List<Id> ipwIds = new List<Id>();

        for(reduivy__Individual_Program_Enrollment__c ipe : ipes) {
            for(reduivy__Individual_Pathway__c ipw : ipe.reduivy__Individual_Pathways__r) {
                if(ipw.reduivy__Term_Number__c == 2) {
                    ipwIds.add(ipw.Id);
                }
            }
        }

        Date toBeEnrolledTermStartDate = ipes[0].reduivy__Starting_Term__r.reduivy__End_Date__c.addDays(31);
        List<reduivy__Study_Term__c> terms = [SELECT Id, Name FROM reduivy__Study_Term__c WHERE reduivy__Start_Date__c = :toBeEnrolledTermStartDate];
        
        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Cancelled';

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', terms[0].Id);
        params.put('proceedForUnitEnrollment', true);
        params.put('bypassRequirementRules', true);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, terms[0].Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, terms[0].Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, terms[0].Name);
        
        JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
        handler.setRecordIds(ipwIds);
        handler.setParams(params);

        Test.startTest();

        System.runAs(ADMIN_USER) {
            JQH_JobManager.HandlerResult result = handler.execute();
            
            System.debug(JSON.serialize(result));

            List<reduivy__Individual_Pathway__c> updatedIpws = [
                SELECT Id,
                reduivy__Academic_Term__c,
                reduivy__Auto_Enrollment__c,
                reduivy__Individual_Program_Enrollment__r.Name
                FROM reduivy__Individual_Pathway__c 
                WHERE Id IN :ipwIds 
                AND reduivy__Academic_Term__c != null
                AND reduivy__Academic_Term__c = :terms[0].Id
            ];
            
            System.Assert.areEqual(ipwIds.size(), updatedIpws.size(), 'There is no individual pathway found for assertion.');

            Set<String> pathwayUnits = new Set<String>{
                'BUS201',
                'BUS202'
            };

            for (reduivy__Individual_Pathway__c ipw : updatedIpws) {
                System.Assert.areEqual(true, ipw.reduivy__Auto_Enrollment__c);
                System.Assert.areEqual(true, result.fail.containsKey(ipw.Id));

                Integer errorCount = 0;
                for (String unitCode : pathwayUnits) {
                    String expectedError = String.format(Label.Term_Student_Enrollment_No_Available_Place_Remaining_In_Study_Offering_Error_Msg, 
                        new List<String>{IPE_Helper.getObjectLabel(), ipw.reduivy__Individual_Program_Enrollment__r.Name, SOF_Helper.getObjectLabel(), SUN_Helper.getObjectLabel(), unitCode}
                    );

                    for (String errorMsg : result.fail.get(ipw.Id)) {
                        if (expectedError == errorMsg) {
                            errorCount ++;
                        }
                    }
                }

                System.Assert.areEqual(2, errorCount);

            }


        }

        Test.stopTest();
    }

    /**
     * @description ISS-002785 Test performTermEnrollment() with study offering = completed status as admin
     */
    @IsTest
    static void testPerformUnitEnrollmentWithStudyOfferingCompletedAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        //cancel all study offering
        List<reduivy__Study_Offering__c> sofList = [SELECT Id, reduivy__Status_Override__c
            FROM reduivy__Study_Offering__c
        ];

        for (reduivy__Study_Offering__c sof : sofList) {
            sof.reduivy__Status_Override__c = 'Completed';
        }

        REDU_Database_UTIL.doUpdate(sofList);

        //start the auto enrollment process
        String autoStatus = IPE_Helper.AUTO_ENROLLMENT_AUTO;
            
        List<reduivy__Individual_Program_Enrollment__c> ipes = [
            SELECT Id, reduivy__Starting_Term__r.reduivy__End_Date__c, 
            (SELECT Id, reduivy__Term_Number__c, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c 
            FROM reduivy__Individual_Pathways__r ORDER BY reduivy__Term_Number__c) 
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE reduivy__Auto_Enrollment__c = :autoStatus
            ORDER BY reduivy__Contact__r.reduivy__Sequence__c ASC
        ];

        List<Id> ipwIds = new List<Id>();

        for(reduivy__Individual_Program_Enrollment__c ipe : ipes) {
            for(reduivy__Individual_Pathway__c ipw : ipe.reduivy__Individual_Pathways__r) {
                if(ipw.reduivy__Term_Number__c == 2) {
                    ipwIds.add(ipw.Id);
                }
            }
        }

        Date toBeEnrolledTermStartDate = ipes[0].reduivy__Starting_Term__r.reduivy__End_Date__c.addDays(31);
        List<reduivy__Study_Term__c> terms = [SELECT Id, Name FROM reduivy__Study_Term__c WHERE reduivy__Start_Date__c = :toBeEnrolledTermStartDate];
        
        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Cancelled';

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', terms[0].Id);
        params.put('proceedForUnitEnrollment', true);
        params.put('bypassRequirementRules', true);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, terms[0].Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, terms[0].Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, terms[0].Name);
        
        JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
        handler.setRecordIds(ipwIds);
        handler.setParams(params);

        Test.startTest();

        System.runAs(ADMIN_USER) {
            JQH_JobManager.HandlerResult result = handler.execute();
            
            System.debug(JSON.serialize(result));

            List<reduivy__Individual_Pathway__c> updatedIpws = [
                SELECT Id,
                reduivy__Academic_Term__c,
                reduivy__Auto_Enrollment__c,
                reduivy__Individual_Program_Enrollment__r.Name
                FROM reduivy__Individual_Pathway__c 
                WHERE Id IN :ipwIds 
                AND reduivy__Academic_Term__c != null
                AND reduivy__Academic_Term__c = :terms[0].Id
            ];
            
            System.Assert.areEqual(ipwIds.size(), updatedIpws.size(), 'There is no individual pathway found for assertion.');

            Set<String> pathwayUnits = new Set<String>{
                'BUS201',
                'BUS202'
            };

            for (reduivy__Individual_Pathway__c ipw : updatedIpws) {
                System.Assert.areEqual(true, ipw.reduivy__Auto_Enrollment__c);
                System.Assert.areEqual(true, result.fail.containsKey(ipw.Id));

                Integer errorCount = 0;
                for (String unitCode : pathwayUnits) {
                    String expectedError = String.format(Label.Term_Student_Enrollment_No_Available_Place_Remaining_In_Study_Offering_Error_Msg, 
                        new List<String>{IPE_Helper.getObjectLabel(), ipw.reduivy__Individual_Program_Enrollment__r.Name, SOF_Helper.getObjectLabel(), SUN_Helper.getObjectLabel(), unitCode}
                    );

                    for (String errorMsg : result.fail.get(ipw.Id)) {
                        if (expectedError == errorMsg) {
                            errorCount ++;
                        }
                    }
                }

                System.Assert.areEqual(2, errorCount);

            }


        }

        Test.stopTest();
    }

    /**
     * @description Test performUnitEnrollment() with IEN in configured status and in open status as admin
     */
    @IsTest
    static void testPerformUnitEnrollmentWithIenInConfiguredAndOpenStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Individual_Program_Enrollment__c ipeToBeUsed = [SELECT Id, reduivy__Contact__c, reduivy__Auto_Enrollment__c, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Default_Campus__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND reduivy__Study_Intake__r.reduivy__Sample_Record_Code__c = :STUDY_INTAKE
            AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = :SPL_MAJOR
            AND reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            LIMIT 1
        ];

        System.Assert.isTrue(ipeToBeUsed != null, 'An Individual Program Enrollment should be found');

        reduivy__Individual_Pathway__c ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.isTrue(ipwToBeUsed != null, 'An Individual Pathway should be found');

        ipwToBeUsed.reduivy__Academic_Term__c = null;
        ipwToBeUsed.reduivy__Individual_Academic_Progress__c = null;

        update ipwToBeUsed;

        reduivy__Study_Term__c toBeEnrollTerm = [SELECT Id, Name FROM reduivy__Study_Term__c WHERE Id != :ipeToBeUsed.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

        System.Assert.isTrue(toBeEnrollTerm != null, 'An Study Term should be found');

        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();

        for(reduivy__Study_Pathway_Unit__c relatedSpu : [SELECT Id, reduivy__Study_Unit__c 
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :ipeToBeUsed.reduivy__Study_Pathway__c 
            AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c = 2
            AND reduivy__Study_Unit__c != null
        ]) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = relatedSpu.reduivy__Study_Unit__c,
                reduivy__Academic_Term__c = toBeEnrollTerm.Id,
                reduivy__Campus__c = ipeToBeUsed.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20,
                reduivy__Status_Override__c = SOF_POSITIVE_STATUS
            ));
        }

        insert sofToBeCreated;

        List<reduivy__Individual_Enrollment__c> ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        delete ienRelatedToContact;

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();

        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = ipeToBeUsed.reduivy__Contact__c,
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Enrollment_Status__c = 'Completed',
                reduivy__Bypass_Requirement_Met__c = true
            ));

            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = ipeToBeUsed.reduivy__Contact__c,
                reduivy__Study_Unit__c = sof.reduivy__Study_Unit__c,
                reduivy__Enrollment_Status__c = IEN_Helper.getOpenStatuses().get(0),
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreated;

        ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size() * 2, ienRelatedToContact.size(), 'There should be two IENs created for each Study Offering associated with the contact.');

        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Deferred;';

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', toBeEnrollTerm.Id);
        params.put('proceedForUnitEnrollment', true);
        params.put('bypassRequirementRules', true);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, toBeEnrollTerm.Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, toBeEnrollTerm.Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, toBeEnrollTerm.Name);

        List<Id> ipwIds = new List<Id>();
        ipwIds.add(ipwToBeUsed.Id);

        JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
        handler.setRecordIds(ipwIds);
        handler.setParams(params);

        System.runAs(ADMIN_USER) {            
            Test.startTest();
            JQH_JobManager.HandlerResult result = handler.execute();
            Test.stopTest();
        }

        ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.areEqual(toBeEnrollTerm.Id, ipwToBeUsed.reduivy__Academic_Term__c, 'The Individual Pathway should be enrolled in the specified term.');
        System.Assert.isTrue(String.isNotBlank(ipwToBeUsed.reduivy__Individual_Academic_Progress__c), 'The Individual Pathway should have the Individual Academic Progress populated.');
        
        ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size() * 2, ienRelatedToContact.size(), 'There should be no new IEN created for the contact.');    
    }

    /**
     * @description Test performUnitEnrollment() with no IEN in configured status but has IEN in open status as admin
     */
    @IsTest
    static void testPerformUnitEnrollmentWithNoIenInConfiguredButInOpenStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Individual_Program_Enrollment__c ipeToBeUsed = [SELECT Id, reduivy__Contact__c, reduivy__Auto_Enrollment__c, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Default_Campus__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND reduivy__Study_Intake__r.reduivy__Sample_Record_Code__c = :STUDY_INTAKE
            AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = :SPL_MAJOR
            AND reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            LIMIT 1
        ];

        System.Assert.isTrue(ipeToBeUsed != null, 'An Individual Program Enrollment should be found');

        reduivy__Individual_Pathway__c ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.isTrue(ipwToBeUsed != null, 'An Individual Pathway should be found');

        ipwToBeUsed.reduivy__Academic_Term__c = null;
        ipwToBeUsed.reduivy__Individual_Academic_Progress__c = null;

        update ipwToBeUsed;

        reduivy__Study_Term__c toBeEnrollTerm = [SELECT Id, Name FROM reduivy__Study_Term__c WHERE Id != :ipeToBeUsed.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

        System.Assert.isTrue(toBeEnrollTerm != null, 'An Study Term should be found');

        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();

        for(reduivy__Study_Pathway_Unit__c relatedSpu : [SELECT Id, reduivy__Study_Unit__c 
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :ipeToBeUsed.reduivy__Study_Pathway__c 
            AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c = 2
            AND reduivy__Study_Unit__c != null
        ]) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = relatedSpu.reduivy__Study_Unit__c,
                reduivy__Academic_Term__c = toBeEnrollTerm.Id,
                reduivy__Campus__c = ipeToBeUsed.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20,
                reduivy__Status_Override__c = SOF_POSITIVE_STATUS
            ));
        }

        insert sofToBeCreated;
 
        Set<Id> sofIds = new Set<Id>();
        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            sofIds.add(sof.Id);
        }

        List<reduivy__Individual_Enrollment__c> ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        delete ienRelatedToContact;

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();

        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = ipeToBeUsed.reduivy__Contact__c,
                reduivy__Study_Unit__c = sof.reduivy__Study_Unit__c,
                reduivy__Enrollment_Status__c = IEN_Helper.getOpenStatuses().get(0),
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreated;

        Map<String, Id> ienWithKey = new Map<String, Id>();
        for(reduivy__Individual_Enrollment__c ien : ienToBeCreated) {
            String key = ien.reduivy__Contact__c + '_' + ien.reduivy__Study_Unit__c;

            ienWithKey.put(key, ien.Id);
        }

        ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size(), ienRelatedToContact.size(), 'There should be an IEN created for each Study Offering associated with the contact.');

        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Deferred;';

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', toBeEnrollTerm.Id);
        params.put('proceedForUnitEnrollment', true);
        params.put('bypassRequirementRules', true);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, toBeEnrollTerm.Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, toBeEnrollTerm.Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, toBeEnrollTerm.Name);

        List<Id> ipwIds = new List<Id>();
        ipwIds.add(ipwToBeUsed.Id);

        JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
        handler.setRecordIds(ipwIds);
        handler.setParams(params);

        System.runAs(ADMIN_USER) {            
            Test.startTest();
            JQH_JobManager.HandlerResult result = handler.execute();
            Test.stopTest();
        }

        ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.areEqual(toBeEnrollTerm.Id, ipwToBeUsed.reduivy__Academic_Term__c, 'The Individual Pathway should be enrolled in the specified term.');
        System.Assert.isTrue(String.isNotBlank(ipwToBeUsed.reduivy__Individual_Academic_Progress__c), 'The Individual Pathway should have the Individual Academic Progress populated.');
        
        ienRelatedToContact = [SELECT Id, reduivy__Contact__c, reduivy__Enrollment_Status__c, reduivy__Study_Offering__c, reduivy__Study_Offering__r.reduivy__Study_Unit__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size(), ienRelatedToContact.size(), 'There should be no new IEN created for the contact.');    
        
        List<String> ienInProgressStatuses = IEN_Helper.getInProgressStatuses();

        for(reduivy__Individual_Enrollment__c ien : ienRelatedToContact) {
            String key = ien.reduivy__Contact__c + '_' + ien.reduivy__Study_Offering__r.reduivy__Study_Unit__c;

            System.Assert.isTrue(ienWithKey.containsKey(key), 'The IEN should come from the placeholder IEN.');
            System.Assert.isTrue(sofIds.contains(ien.reduivy__Study_Offering__c), 'The IEN should belong to one of the previously created Study Offerings.');
            System.Assert.isTrue(ienInProgressStatuses.contains(ien.reduivy__Enrollment_Status__c), 'The IEN should have an in progress status.');
        }
    }

    /**
     * @description Test performUnitEnrollment() with IEN in configured status but no IEN in open status as admin
     */
    @IsTest
    static void testPerformUnitEnrollmentWithIenInConfiguredButNotInOpenStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Individual_Program_Enrollment__c ipeToBeUsed = [SELECT Id, reduivy__Contact__c, reduivy__Auto_Enrollment__c, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Default_Campus__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND reduivy__Study_Intake__r.reduivy__Sample_Record_Code__c = :STUDY_INTAKE
            AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = :SPL_MAJOR
            AND reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            LIMIT 1
        ];

        System.Assert.isTrue(ipeToBeUsed != null, 'An Individual Program Enrollment should be found');

        reduivy__Individual_Pathway__c ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.isTrue(ipwToBeUsed != null, 'An Individual Pathway should be found');

        ipwToBeUsed.reduivy__Academic_Term__c = null;
        ipwToBeUsed.reduivy__Individual_Academic_Progress__c = null;

        update ipwToBeUsed;

        reduivy__Study_Term__c toBeEnrollTerm = [SELECT Id, Name FROM reduivy__Study_Term__c WHERE Id != :ipeToBeUsed.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

        System.Assert.isTrue(toBeEnrollTerm != null, 'An Study Term should be found');

        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();

        for(reduivy__Study_Pathway_Unit__c relatedSpu : [SELECT Id, reduivy__Study_Unit__c 
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :ipeToBeUsed.reduivy__Study_Pathway__c 
            AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c = 2
            AND reduivy__Study_Unit__c != null
        ]) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = relatedSpu.reduivy__Study_Unit__c,
                reduivy__Academic_Term__c = toBeEnrollTerm.Id,
                reduivy__Campus__c = ipeToBeUsed.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20,
                reduivy__Status_Override__c = SOF_POSITIVE_STATUS
            ));
        }

        insert sofToBeCreated;

        List<reduivy__Individual_Enrollment__c> ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        delete ienRelatedToContact;

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();

        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = ipeToBeUsed.reduivy__Contact__c,
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Enrollment_Status__c = 'Completed',
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreated;

        ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size(), ienRelatedToContact.size(), 'There should be an IEN created for each Study Offering associated with the contact.');

        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Deferred;';

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', toBeEnrollTerm.Id);
        params.put('proceedForUnitEnrollment', true);
        params.put('bypassRequirementRules', true);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, toBeEnrollTerm.Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, toBeEnrollTerm.Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, toBeEnrollTerm.Name);

        List<Id> ipwIds = new List<Id>();
        ipwIds.add(ipwToBeUsed.Id);

        JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
        handler.setRecordIds(ipwIds);
        handler.setParams(params);

        System.runAs(ADMIN_USER) {            
            Test.startTest();
            JQH_JobManager.HandlerResult result = handler.execute();
            Test.stopTest();
        }

        ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.areEqual(toBeEnrollTerm.Id, ipwToBeUsed.reduivy__Academic_Term__c, 'The Individual Pathway should be enrolled in the specified term.');
        System.Assert.isTrue(String.isNotBlank(ipwToBeUsed.reduivy__Individual_Academic_Progress__c), 'The Individual Pathway should have the Individual Academic Progress populated.');
        
        ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size(), ienRelatedToContact.size(), 'There should be no new IEN created for the contact since they already have IENs in configured status.');
    }

    /**
     * @description Test performUnitEnrollment() with no IEN in either configured or open status as admin
     */
    @IsTest
    static void testPerformUnitEnrollmentWithNoIenInConfiguredOrOpenStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Individual_Program_Enrollment__c ipeToBeUsed = [SELECT Id, reduivy__Contact__c, reduivy__Auto_Enrollment__c, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Default_Campus__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND reduivy__Study_Intake__r.reduivy__Sample_Record_Code__c = :STUDY_INTAKE
            AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = :SPL_MAJOR
            AND reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            LIMIT 1
        ];

        System.Assert.isTrue(ipeToBeUsed != null, 'An Individual Program Enrollment should be found');

        reduivy__Individual_Pathway__c ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.isTrue(ipwToBeUsed != null, 'An Individual Pathway should be found');

        ipwToBeUsed.reduivy__Academic_Term__c = null;
        ipwToBeUsed.reduivy__Individual_Academic_Progress__c = null;

        update ipwToBeUsed;

        reduivy__Study_Term__c toBeEnrollTerm = [SELECT Id, Name FROM reduivy__Study_Term__c WHERE Id != :ipeToBeUsed.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

        System.Assert.isTrue(toBeEnrollTerm != null, 'An Study Term should be found');

        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();

        for(reduivy__Study_Pathway_Unit__c relatedSpu : [SELECT Id, reduivy__Study_Unit__c 
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :ipeToBeUsed.reduivy__Study_Pathway__c 
            AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c = 2
            AND reduivy__Study_Unit__c != null
        ]) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = relatedSpu.reduivy__Study_Unit__c,
                reduivy__Academic_Term__c = toBeEnrollTerm.Id,
                reduivy__Campus__c = ipeToBeUsed.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20,
                reduivy__Status_Override__c = SOF_POSITIVE_STATUS
            ));
        }

        insert sofToBeCreated;

        // Delete all existing IENs to ensure no existing enrollment status
        List<reduivy__Individual_Enrollment__c> ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        delete ienRelatedToContact;

        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Deferred;';

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', toBeEnrollTerm.Id);
        params.put('proceedForUnitEnrollment', true);
        params.put('bypassRequirementRules', true);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, toBeEnrollTerm.Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, toBeEnrollTerm.Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, toBeEnrollTerm.Name);

        List<Id> ipwIds = new List<Id>();
        ipwIds.add(ipwToBeUsed.Id);

        JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
        handler.setRecordIds(ipwIds);
        handler.setParams(params);

        System.runAs(ADMIN_USER) {            
            Test.startTest();
            JQH_JobManager.HandlerResult result = handler.execute();
            Test.stopTest();
        }

        ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.areEqual(toBeEnrollTerm.Id, ipwToBeUsed.reduivy__Academic_Term__c, 'The Individual Pathway should be enrolled in the specified term.');
        System.Assert.isTrue(String.isNotBlank(ipwToBeUsed.reduivy__Individual_Academic_Progress__c), 'The Individual Pathway should have the Individual Academic Progress populated.');
        
        ienRelatedToContact = [SELECT Id, reduivy__Enrollment_Status__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size(), ienRelatedToContact.size(), 'New IENs should be created for each Study Offering.');
        
        List<String> ienInProgressStatuses = IEN_Helper.getInProgressStatuses();
        for(reduivy__Individual_Enrollment__c ien : ienRelatedToContact) {
            System.Assert.isTrue(ienInProgressStatuses.contains(ien.reduivy__Enrollment_Status__c), 'The IEN should have an in progress status.');
        }
    }

    /**
     * @description Test performUnitEnrollment() with multiple IENs in open status as admin
     */
    @IsTest
    static void testPerformUnitEnrollmentWithMultipleOpenStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Individual_Program_Enrollment__c ipeToBeUsed = [SELECT Id, reduivy__Contact__c, reduivy__Auto_Enrollment__c, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Default_Campus__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND reduivy__Study_Intake__r.reduivy__Sample_Record_Code__c = :STUDY_INTAKE
            AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = :SPL_MAJOR
            AND reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            LIMIT 1
        ];

        System.Assert.isTrue(ipeToBeUsed != null, 'An Individual Program Enrollment should be found');

        reduivy__Individual_Pathway__c ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.isTrue(ipwToBeUsed != null, 'An Individual Pathway should be found');

        ipwToBeUsed.reduivy__Academic_Term__c = null;
        ipwToBeUsed.reduivy__Individual_Academic_Progress__c = null;

        update ipwToBeUsed;

        reduivy__Study_Term__c toBeEnrollTerm = [SELECT Id, Name FROM reduivy__Study_Term__c WHERE Id != :ipeToBeUsed.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

        System.Assert.isTrue(toBeEnrollTerm != null, 'An Study Term should be found');

        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();

        for(reduivy__Study_Pathway_Unit__c relatedSpu : [SELECT Id, reduivy__Study_Unit__c 
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :ipeToBeUsed.reduivy__Study_Pathway__c 
            AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c = 2
            AND reduivy__Study_Unit__c != null
        ]) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = relatedSpu.reduivy__Study_Unit__c,
                reduivy__Academic_Term__c = toBeEnrollTerm.Id,
                reduivy__Campus__c = ipeToBeUsed.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20,
                reduivy__Status_Override__c = SOF_POSITIVE_STATUS
            ));
        }

        insert sofToBeCreated;

        List<reduivy__Individual_Enrollment__c> ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        delete ienRelatedToContact;

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();

        // Create multiple IENs in open status for each study unit
        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            // Create first IEN in open status (older)
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = ipeToBeUsed.reduivy__Contact__c,
                reduivy__Study_Unit__c = sof.reduivy__Study_Unit__c,
                reduivy__Enrollment_Status__c = IEN_Helper.getOpenStatuses().get(0),
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreated;

        // Create second batch of IENs in open status (newer)
        List<reduivy__Individual_Enrollment__c> ienToBeCreatedSecond = new List<reduivy__Individual_Enrollment__c>();
        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreatedSecond.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = ipeToBeUsed.reduivy__Contact__c,
                reduivy__Study_Unit__c = sof.reduivy__Study_Unit__c,
                reduivy__Enrollment_Status__c = IEN_Helper.getOpenStatuses().get(0),
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreatedSecond;

        // Store the first (older) IEN IDs for comparison
        Map<String, Id> firstIenWithKey = new Map<String, Id>();
        for(reduivy__Individual_Enrollment__c ien : ienToBeCreated) {
            String key = ien.reduivy__Contact__c + '_' + ien.reduivy__Study_Unit__c;
            firstIenWithKey.put(key, ien.Id);
        }

        ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size() * 2, ienRelatedToContact.size(), 'There should be multiple IENs created for each Study Offering associated with the contact.');

        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Deferred;';

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', toBeEnrollTerm.Id);
        params.put('proceedForUnitEnrollment', true);
        params.put('bypassRequirementRules', true);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, toBeEnrollTerm.Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, toBeEnrollTerm.Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, toBeEnrollTerm.Name);

        List<Id> ipwIds = new List<Id>();
        ipwIds.add(ipwToBeUsed.Id);

        JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
        handler.setRecordIds(ipwIds);
        handler.setParams(params);

        System.runAs(ADMIN_USER) {            
            Test.startTest();
            JQH_JobManager.HandlerResult result = handler.execute();
            Test.stopTest();
        }

        ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.areEqual(toBeEnrollTerm.Id, ipwToBeUsed.reduivy__Academic_Term__c, 'The Individual Pathway should be enrolled in the specified term.');
        System.Assert.isTrue(String.isNotBlank(ipwToBeUsed.reduivy__Individual_Academic_Progress__c), 'The Individual Pathway should have the Individual Academic Progress populated.');
        
        ienRelatedToContact = [SELECT Id, reduivy__Contact__c, reduivy__Enrollment_Status__c, reduivy__Study_Offering__c, reduivy__Study_Offering__r.reduivy__Study_Unit__c 
            FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size() * 2, ienRelatedToContact.size(), 'There should be no new IEN created for the contact.');
        
        List<String> ienInProgressStatuses = IEN_Helper.getInProgressStatuses();
        Integer updatedCount = 0;
        
        for(reduivy__Individual_Enrollment__c ien : ienRelatedToContact) {
            if(ienInProgressStatuses.contains(ien.reduivy__Enrollment_Status__c)) {
                updatedCount++;
                String key = ien.reduivy__Contact__c + '_' + ien.reduivy__Study_Offering__r.reduivy__Study_Unit__c;
                System.Assert.isTrue(firstIenWithKey.containsKey(key), 'The updated IEN should be the first (older) one based on CreatedDate ASC ordering.');
            }
        }
        
        System.Assert.areEqual(sofToBeCreated.size(), updatedCount, 'Only one IEN per study unit should be updated with Study Offering.');
    }

    /**
     * @description Test performUnitEnrollment() with multiple IENs in configured status as admin
     */
    @IsTest
    static void testPerformUnitEnrollmentWithMultipleConfiguredStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Individual_Program_Enrollment__c ipeToBeUsed = [SELECT Id, reduivy__Contact__c, reduivy__Auto_Enrollment__c, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Default_Campus__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND reduivy__Study_Intake__r.reduivy__Sample_Record_Code__c = :STUDY_INTAKE
            AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = :SPL_MAJOR
            AND reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            LIMIT 1
        ];

        System.Assert.isTrue(ipeToBeUsed != null, 'An Individual Program Enrollment should be found');

        reduivy__Individual_Pathway__c ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.isTrue(ipwToBeUsed != null, 'An Individual Pathway should be found');

        ipwToBeUsed.reduivy__Academic_Term__c = null;
        ipwToBeUsed.reduivy__Individual_Academic_Progress__c = null;

        update ipwToBeUsed;

        reduivy__Study_Term__c toBeEnrollTerm = [SELECT Id, Name FROM reduivy__Study_Term__c WHERE Id != :ipeToBeUsed.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

        System.Assert.isTrue(toBeEnrollTerm != null, 'An Study Term should be found');

        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();

        for(reduivy__Study_Pathway_Unit__c relatedSpu : [SELECT Id, reduivy__Study_Unit__c 
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :ipeToBeUsed.reduivy__Study_Pathway__c 
            AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c = 2
            AND reduivy__Study_Unit__c != null
        ]) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = relatedSpu.reduivy__Study_Unit__c,
                reduivy__Academic_Term__c = toBeEnrollTerm.Id,
                reduivy__Campus__c = ipeToBeUsed.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20,
                reduivy__Status_Override__c = SOF_POSITIVE_STATUS
            ));
        }

        insert sofToBeCreated;

        List<reduivy__Individual_Enrollment__c> ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        delete ienRelatedToContact;

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();

        // Create multiple IENs with different configured statuses for each study unit
        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = ipeToBeUsed.reduivy__Contact__c,
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Enrollment_Status__c = 'Completed',
                reduivy__Bypass_Requirement_Met__c = true
            ));

            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = ipeToBeUsed.reduivy__Contact__c,
                reduivy__Study_Unit__c = sof.reduivy__Study_Unit__c,
                reduivy__Enrollment_Status__c = 'Withdrawn',
                reduivy__Bypass_Requirement_Met__c = true
            ));

            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = ipeToBeUsed.reduivy__Contact__c,
                reduivy__Study_Unit__c = sof.reduivy__Study_Unit__c,
                reduivy__Enrollment_Status__c = 'Enrolled',
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreated;

        ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size() * 3, ienRelatedToContact.size(), 'There should be three IENs created for each Study Offering associated with the contact.');

        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Deferred;';

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', toBeEnrollTerm.Id);
        params.put('proceedForUnitEnrollment', true);
        params.put('bypassRequirementRules', true);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, toBeEnrollTerm.Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, toBeEnrollTerm.Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, toBeEnrollTerm.Name);

        List<Id> ipwIds = new List<Id>();
        ipwIds.add(ipwToBeUsed.Id);

        JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
        handler.setRecordIds(ipwIds);
        handler.setParams(params);

        System.runAs(ADMIN_USER) {            
            Test.startTest();
            JQH_JobManager.HandlerResult result = handler.execute();
            Test.stopTest();
        }

        ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.areEqual(toBeEnrollTerm.Id, ipwToBeUsed.reduivy__Academic_Term__c, 'The Individual Pathway should be enrolled in the specified term.');
        System.Assert.isTrue(String.isNotBlank(ipwToBeUsed.reduivy__Individual_Academic_Progress__c), 'The Individual Pathway should have the Individual Academic Progress populated.');
        
        ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size() * 3, ienRelatedToContact.size(), 'There should be no new IEN created for the contact since all study units have configured status IENs.');    
    }

    /**
     * @description Test performUnitEnrollment() with IENs that are neither in configured nor in open status as admin
     */
    @IsTest
    static void testPerformUnitEnrollmentWithIenNotInConfiguredOrOpenStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Individual_Program_Enrollment__c ipeToBeUsed = [SELECT Id, reduivy__Contact__c, reduivy__Auto_Enrollment__c, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Default_Campus__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND reduivy__Study_Intake__r.reduivy__Sample_Record_Code__c = :STUDY_INTAKE
            AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = :SPL_MAJOR
            AND reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            LIMIT 1
        ];

        System.Assert.isTrue(ipeToBeUsed != null, 'An Individual Program Enrollment should be found');

        reduivy__Individual_Pathway__c ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.isTrue(ipwToBeUsed != null, 'An Individual Pathway should be found');

        ipwToBeUsed.reduivy__Academic_Term__c = null;
        ipwToBeUsed.reduivy__Individual_Academic_Progress__c = null;

        update ipwToBeUsed;

        reduivy__Study_Term__c toBeEnrollTerm = [SELECT Id, Name FROM reduivy__Study_Term__c WHERE Id != :ipeToBeUsed.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

        System.Assert.isTrue(toBeEnrollTerm != null, 'An Study Term should be found');

        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();

        for(reduivy__Study_Pathway_Unit__c relatedSpu : [SELECT Id, reduivy__Study_Unit__c 
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :ipeToBeUsed.reduivy__Study_Pathway__c 
            AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c = 2
            AND reduivy__Study_Unit__c != null
        ]) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = relatedSpu.reduivy__Study_Unit__c,
                reduivy__Academic_Term__c = toBeEnrollTerm.Id,
                reduivy__Campus__c = ipeToBeUsed.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20,
                reduivy__Status_Override__c = SOF_POSITIVE_STATUS
            ));
        }

        insert sofToBeCreated;

        List<reduivy__Individual_Enrollment__c> ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        delete ienRelatedToContact;

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();

        // Create IENs with statuses that are neither configured nor open (e.g., a custom status)
        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = ipeToBeUsed.reduivy__Contact__c,
                reduivy__Study_Unit__c = sof.reduivy__Study_Unit__c,
                reduivy__Enrollment_Status__c = IEN_Helper.getWithdrawalRequestedStatuses().get(0),
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreated;

        ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size(), ienRelatedToContact.size(), 'There should be an IEN created for each Study Offering associated with the contact.');

        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Deferred;';

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', toBeEnrollTerm.Id);
        params.put('proceedForUnitEnrollment', true);
        params.put('bypassRequirementRules', true);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, toBeEnrollTerm.Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, toBeEnrollTerm.Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, toBeEnrollTerm.Name);

        List<Id> ipwIds = new List<Id>();
        ipwIds.add(ipwToBeUsed.Id);

        JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
        handler.setRecordIds(ipwIds);
        handler.setParams(params);

        System.runAs(ADMIN_USER) {            
            Test.startTest();
            JQH_JobManager.HandlerResult result = handler.execute();
            Test.stopTest();
        }

        ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.areEqual(toBeEnrollTerm.Id, ipwToBeUsed.reduivy__Academic_Term__c, 'The Individual Pathway should be enrolled in the specified term.');
        System.Assert.isTrue(String.isNotBlank(ipwToBeUsed.reduivy__Individual_Academic_Progress__c), 'The Individual Pathway should have the Individual Academic Progress populated.');
        
        ienRelatedToContact = [SELECT Id, reduivy__Contact__c, reduivy__Enrollment_Status__c, reduivy__Study_Offering__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        
        // Should have the original IENs plus new ones created
        System.Assert.areEqual(sofToBeCreated.size() * 2, ienRelatedToContact.size(), 'New IENs should be created since existing ones are not in configured or open status.');    
        
        Set<Id> sofIds = new Set<Id>();
        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            sofIds.add(sof.Id);
        }

        Integer newIens = 0;
        List<String> ienInProgressStatuses = IEN_Helper.getInProgressStatuses();
        for(reduivy__Individual_Enrollment__c ien : ienRelatedToContact) {
            if(ien.reduivy__Study_Offering__c != null && sofIds.contains(ien.reduivy__Study_Offering__c)) {
                System.Assert.isTrue(ienInProgressStatuses.contains(ien.reduivy__Enrollment_Status__c), 'New IEN should have an in progress status.');
                newIens++;
            }
        }
        
        System.Assert.areEqual(sofToBeCreated.size(), newIens, 'New IENs should be created for each study unit.');
    }

    /**
     * @description Test performUnitEnrollment() with IEN in open status that has SOF assigned as admin
     */
    @IsTest
    static void testPerformUnitEnrollmentWithOpenStatusIenWithSofAssignedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Individual_Program_Enrollment__c ipeToBeUsed = [SELECT Id, reduivy__Contact__c, reduivy__Auto_Enrollment__c, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Default_Campus__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND reduivy__Study_Intake__r.reduivy__Sample_Record_Code__c = :STUDY_INTAKE
            AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = :SPL_MAJOR
            AND reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            LIMIT 1
        ];

        System.Assert.isTrue(ipeToBeUsed != null, 'An Individual Program Enrollment should be found');

        reduivy__Individual_Pathway__c ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.isTrue(ipwToBeUsed != null, 'An Individual Pathway should be found');

        ipwToBeUsed.reduivy__Academic_Term__c = null;
        ipwToBeUsed.reduivy__Individual_Academic_Progress__c = null;

        update ipwToBeUsed;

        reduivy__Study_Term__c toBeEnrollTerm = [SELECT Id, Name FROM reduivy__Study_Term__c WHERE Id != :ipeToBeUsed.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

        System.Assert.isTrue(toBeEnrollTerm != null, 'An Study Term should be found');

        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();

        for(reduivy__Study_Pathway_Unit__c relatedSpu : [SELECT Id, reduivy__Study_Unit__c 
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :ipeToBeUsed.reduivy__Study_Pathway__c 
            AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c = 2
            AND reduivy__Study_Unit__c != null
        ]) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = relatedSpu.reduivy__Study_Unit__c,
                reduivy__Academic_Term__c = toBeEnrollTerm.Id,
                reduivy__Campus__c = ipeToBeUsed.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20,
                reduivy__Status_Override__c = SOF_POSITIVE_STATUS
            ));
        }

        insert sofToBeCreated;
 
        Set<Id> sofIds = new Set<Id>();
        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            sofIds.add(sof.Id);
        }

        List<reduivy__Individual_Enrollment__c> ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        delete ienRelatedToContact;

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();

        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = ipeToBeUsed.reduivy__Contact__c,
                reduivy__Study_Unit__c = sof.reduivy__Study_Unit__c,
                reduivy__Enrollment_Status__c = IEN_Helper.getOpenStatuses().get(0),
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreated;

        Set<Id> createdIenIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : ienToBeCreated) {
            createdIenIds.add(ien.Id);
        }

        ienRelatedToContact = [SELECT Id, reduivy__Study_Offering__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size(), ienRelatedToContact.size(), 'There should be an IEN created for each Study Offering associated with the contact.');
        
        for(reduivy__Individual_Enrollment__c ien : ienRelatedToContact) {
            ien.reduivy__Individual_Academic_Progress__c = null;
        }

        REDU_TriggerController.muteTriggers(new Set<String>{'IEN_AcademicProgress_EXE'});
        update ienRelatedToContact;
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IEN_AcademicProgress_EXE'});

        ienRelatedToContact = [SELECT Id, reduivy__Study_Offering__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        
        for(reduivy__Individual_Enrollment__c ien : ienRelatedToContact) {
            System.Assert.isTrue(String.isNotBlank(ien.reduivy__Study_Offering__c), 'The IEN should have the Study Offering populated.');
            System.Assert.isTrue(String.isBlank(ien.reduivy__Individual_Academic_Progress__c), 'The IEN should not have the Individual Academic Progress populated.');
        }

        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Deferred;';

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', toBeEnrollTerm.Id);
        params.put('proceedForUnitEnrollment', true);
        params.put('bypassRequirementRules', true);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, toBeEnrollTerm.Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, toBeEnrollTerm.Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, toBeEnrollTerm.Name);

        List<Id> ipwIds = new List<Id>();
        ipwIds.add(ipwToBeUsed.Id);

        JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
        handler.setRecordIds(ipwIds);
        handler.setParams(params);

        System.runAs(ADMIN_USER) {            
            Test.startTest();
            JQH_JobManager.HandlerResult result = handler.execute();
            Test.stopTest();
        }

        ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.areEqual(toBeEnrollTerm.Id, ipwToBeUsed.reduivy__Academic_Term__c, 'The Individual Pathway should be enrolled in the specified term.');
        System.Assert.isTrue(String.isNotBlank(ipwToBeUsed.reduivy__Individual_Academic_Progress__c), 'The Individual Pathway should have the Individual Academic Progress populated.');

        ienRelatedToContact = [SELECT Id, reduivy__Enrollment_Status__c, reduivy__Contact__c, reduivy__Study_Offering__r.reduivy__Study_Unit__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size() * 2, ienRelatedToContact.size(), 'There should be new IENs created for each Study Offering associated with the contact.');
        
        List<String> ienOpenStatus = IEN_Helper.getOpenStatuses();
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();

        for(reduivy__Individual_Enrollment__c ien : ienRelatedToContact) {
            if(createdIenIds.contains(ien.Id)) {
                System.Assert.isTrue(ienOpenStatus.contains(ien.reduivy__Enrollment_Status__c), 'The existing IEN should be in Open status, as it should not be upserted due to the Study Offering field being populated.');
            } else {
                System.Assert.isTrue(ienInProgressStatus.contains(ien.reduivy__Enrollment_Status__c), 'The newly created IEN should have an In Progress status.');
            }
        } 
    }

    /**
     * @description Test performUnitEnrollment() with IEN in open status that has IPR assigned as admin
     */
    @IsTest
    static void testPerformUnitEnrollmentWithOpenStatusIenWithIprAssignedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Individual_Program_Enrollment__c ipeToBeUsed = [SELECT Id, reduivy__Contact__c, reduivy__Auto_Enrollment__c, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Default_Campus__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND reduivy__Study_Intake__r.reduivy__Sample_Record_Code__c = :STUDY_INTAKE
            AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = :SPL_MAJOR
            AND reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            LIMIT 1
        ];

        System.Assert.isTrue(ipeToBeUsed != null, 'An Individual Program Enrollment should be found');

        reduivy__Individual_Pathway__c ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.isTrue(ipwToBeUsed != null, 'An Individual Pathway should be found');

        ipwToBeUsed.reduivy__Academic_Term__c = null;
        ipwToBeUsed.reduivy__Individual_Academic_Progress__c = null;

        update ipwToBeUsed;

        reduivy__Study_Term__c toBeEnrollTerm = [SELECT Id, Name FROM reduivy__Study_Term__c WHERE Id != :ipeToBeUsed.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

        System.Assert.isTrue(toBeEnrollTerm != null, 'An Study Term should be found');

        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();

        for(reduivy__Study_Pathway_Unit__c relatedSpu : [SELECT Id, reduivy__Study_Unit__c 
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :ipeToBeUsed.reduivy__Study_Pathway__c 
            AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c = 2
            AND reduivy__Study_Unit__c != null
        ]) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = relatedSpu.reduivy__Study_Unit__c,
                reduivy__Academic_Term__c = toBeEnrollTerm.Id,
                reduivy__Campus__c = ipeToBeUsed.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20,
                reduivy__Status_Override__c = SOF_POSITIVE_STATUS
            ));
        }

        insert sofToBeCreated;
 
        Set<Id> sofIds = new Set<Id>();
        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            sofIds.add(sof.Id);
        }

        List<reduivy__Individual_Enrollment__c> ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        delete ienRelatedToContact;

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();

        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = ipeToBeUsed.reduivy__Contact__c,
                reduivy__Study_Unit__c = sof.reduivy__Study_Unit__c,
                reduivy__Enrollment_Status__c = IEN_Helper.getOpenStatuses().get(0),
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreated;

        Set<Id> createdIenIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : ienToBeCreated) {
            createdIenIds.add(ien.Id);
        }

        ienRelatedToContact = [SELECT Id, reduivy__Study_Offering__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size(), ienRelatedToContact.size(), 'There should be an IEN created for each Study Offering associated with the contact.');
        
        for(reduivy__Individual_Enrollment__c ien : ienRelatedToContact) {
            ien.reduivy__Study_Offering__c = null;
        }

        update ienRelatedToContact;

        ienRelatedToContact = [SELECT Id, reduivy__Study_Offering__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        for(reduivy__Individual_Enrollment__c ien : ienRelatedToContact) {
            System.Assert.isTrue(String.isNotBlank(ien.reduivy__Individual_Academic_Progress__c), 'The IEN should have the Individual Academic Progress populated.');
            System.Assert.isTrue(String.isBlank(ien.reduivy__Study_Offering__c), 'The IEN should not have the Study Offering populated.');
        }

        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Deferred;';

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', toBeEnrollTerm.Id);
        params.put('proceedForUnitEnrollment', true);
        params.put('bypassRequirementRules', true);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, toBeEnrollTerm.Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, toBeEnrollTerm.Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, toBeEnrollTerm.Name);

        List<Id> ipwIds = new List<Id>();
        ipwIds.add(ipwToBeUsed.Id);

        JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
        handler.setRecordIds(ipwIds);
        handler.setParams(params);

        System.runAs(ADMIN_USER) {            
            Test.startTest();
            JQH_JobManager.HandlerResult result = handler.execute();
            Test.stopTest();
        }

        ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.areEqual(toBeEnrollTerm.Id, ipwToBeUsed.reduivy__Academic_Term__c, 'The Individual Pathway should be enrolled in the specified term.');
        System.Assert.isTrue(String.isNotBlank(ipwToBeUsed.reduivy__Individual_Academic_Progress__c), 'The Individual Pathway should have the Individual Academic Progress populated.');

        ienRelatedToContact = [SELECT Id, reduivy__Enrollment_Status__c, reduivy__Contact__c, reduivy__Study_Offering__r.reduivy__Study_Unit__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size() * 2, ienRelatedToContact.size(), 'There should be new IENs created for each Study Offering associated with the contact.');
        
        List<String> ienOpenStatus = IEN_Helper.getOpenStatuses();
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();

        for(reduivy__Individual_Enrollment__c ien : ienRelatedToContact) {
            if(createdIenIds.contains(ien.Id)) {
                System.Assert.isTrue(ienOpenStatus.contains(ien.reduivy__Enrollment_Status__c), 'The existing IEN should be in Open status, as it should not be upserted due to the Individual Academic Progress field being populated.');
            } else {
                System.Assert.isTrue(ienInProgressStatus.contains(ien.reduivy__Enrollment_Status__c), 'The newly created IEN should have an In Progress status.');
            }
        } 
    }

    /**
     * @description Test performUnitEnrollment() with IEN in open status that has CTA assigned as admin
     */
    @IsTest
    static void testPerformUnitEnrollmentWithOpenStatusIenWithCtaAssignedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Individual_Program_Enrollment__c ipeToBeUsed = [SELECT Id, reduivy__Contact__c, reduivy__Auto_Enrollment__c, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Default_Campus__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND reduivy__Study_Intake__r.reduivy__Sample_Record_Code__c = :STUDY_INTAKE
            AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = :SPL_MAJOR
            AND reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            LIMIT 1
        ];

        System.Assert.isTrue(ipeToBeUsed != null, 'An Individual Program Enrollment should be found');

        reduivy__Individual_Pathway__c ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.isTrue(ipwToBeUsed != null, 'An Individual Pathway should be found');

        ipwToBeUsed.reduivy__Academic_Term__c = null;
        ipwToBeUsed.reduivy__Individual_Academic_Progress__c = null;

        update ipwToBeUsed;

        reduivy__Study_Term__c toBeEnrollTerm = [SELECT Id, Name FROM reduivy__Study_Term__c WHERE Id != :ipeToBeUsed.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

        System.Assert.isTrue(toBeEnrollTerm != null, 'An Study Term should be found');

        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();

        for(reduivy__Study_Pathway_Unit__c relatedSpu : [SELECT Id, reduivy__Study_Unit__c 
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :ipeToBeUsed.reduivy__Study_Pathway__c 
            AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c = 2
            AND reduivy__Study_Unit__c != null
        ]) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = relatedSpu.reduivy__Study_Unit__c,
                reduivy__Academic_Term__c = toBeEnrollTerm.Id,
                reduivy__Campus__c = ipeToBeUsed.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20,
                reduivy__Status_Override__c = SOF_POSITIVE_STATUS
            ));
        }

        insert sofToBeCreated;
 
        Set<Id> sofIds = new Set<Id>();
        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            sofIds.add(sof.Id);
        }

        List<reduivy__Individual_Enrollment__c> ienRelatedToContact = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        delete ienRelatedToContact;

        reduivy__Agreement_Unit_Equivalent__c agreementUnitEquiv = [SELECT Id FROM reduivy__Agreement_Unit_Equivalent__c LIMIT 1];
        reduivy__Credit_Transfer_Application__c cta = REDU_TestData_UTIL.newCreditTransferApplication(ipeToBeUsed.Id, ipeToBeUsed.reduivy__Contact__c, agreementUnitEquiv.Id, ipeToBeUsed.Id, null, 'A', 99, null, null, System.today(), CTA_Helper.STATUS_TYPE_DRAFT, null, new Set<String>{}, CTA_Helper.TYPE_INCOMING);

        insert cta;

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();

        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = ipeToBeUsed.reduivy__Contact__c,
                reduivy__Study_Unit__c = sof.reduivy__Study_Unit__c,
                reduivy__Enrollment_Status__c = IEN_Helper.getOpenStatuses().get(0),
                reduivy__Bypass_Requirement_Met__c = true,
                reduivy__Credit_Transfer_Application__c = cta.Id
            ));
        }

        insert ienToBeCreated;

        Set<Id> createdIenIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : ienToBeCreated) {
            createdIenIds.add(ien.Id);
        }

        ienRelatedToContact = [SELECT Id, reduivy__Study_Offering__c, reduivy__Individual_Academic_Progress__c, reduivy__Credit_Transfer_Application__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size(), ienRelatedToContact.size(), 'There should be an IEN created for each Study Offering associated with the contact.');

        for(reduivy__Individual_Enrollment__c ien : ienRelatedToContact) {
            System.Assert.isTrue(String.isBlank(ien.reduivy__Individual_Academic_Progress__c), 'The IEN should not have the Individual Academic Progress populated.');
            System.Assert.isTrue(String.isBlank(ien.reduivy__Study_Offering__c), 'The IEN should not have the Study Offering populated.');
            System.Assert.isTrue(String.isNotBlank(ien.reduivy__Credit_Transfer_Application__c), 'The IEN should have the Credit Transfer Application populated.');
        }

        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Deferred;';

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', toBeEnrollTerm.Id);
        params.put('proceedForUnitEnrollment', true);
        params.put('bypassRequirementRules', true);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, toBeEnrollTerm.Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, toBeEnrollTerm.Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, toBeEnrollTerm.Name);

        List<Id> ipwIds = new List<Id>();
        ipwIds.add(ipwToBeUsed.Id);

        JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
        handler.setRecordIds(ipwIds);
        handler.setParams(params);

        System.runAs(ADMIN_USER) {            
            Test.startTest();
            JQH_JobManager.HandlerResult result = handler.execute();
            Test.stopTest();
        }

        ipwToBeUsed = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ipeToBeUsed.Id 
            AND reduivy__Term_Number__c = 2
            LIMIT 1
        ];

        System.Assert.areEqual(toBeEnrollTerm.Id, ipwToBeUsed.reduivy__Academic_Term__c, 'The Individual Pathway should be enrolled in the specified term.');
        System.Assert.isTrue(String.isNotBlank(ipwToBeUsed.reduivy__Individual_Academic_Progress__c), 'The Individual Pathway should have the Individual Academic Progress populated.');

        ienRelatedToContact = [SELECT Id, reduivy__Enrollment_Status__c, reduivy__Contact__c, reduivy__Study_Offering__r.reduivy__Study_Unit__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :ipeToBeUsed.reduivy__Contact__c];
        System.Assert.areEqual(sofToBeCreated.size() * 2, ienRelatedToContact.size(), 'There should be new IENs created for each Study Offering associated with the contact.');
        
        List<String> ienOpenStatus = IEN_Helper.getOpenStatuses();
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();

        for(reduivy__Individual_Enrollment__c ien : ienRelatedToContact) {
            if(createdIenIds.contains(ien.Id)) {
                System.Assert.isTrue(ienOpenStatus.contains(ien.reduivy__Enrollment_Status__c), 'The existing IEN should be in Open status, as it should not be upserted due to the Credit Transfer Application field being populated.');
            } else {
                System.Assert.isTrue(ienInProgressStatus.contains(ien.reduivy__Enrollment_Status__c), 'The newly created IEN should have an In Progress status.');
            }
        } 
    }

    /**
     * @description Test auto enrollment with multiple IPFs - should link to correct IPF
     */
    @IsTest
    static void testPerformUnitEnrollmentWithMultipleIpfsAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        String autoStatus = IPE_Helper.AUTO_ENROLLMENT_AUTO;

        List<reduivy__Individual_Program_Enrollment__c> ipes = [
            SELECT Id, reduivy__Contact__c, reduivy__Default_Campus__c, reduivy__Starting_Term__r.reduivy__End_Date__c, 
            reduivy__Study_Pathway__c, reduivy__Study_Plan__c, reduivy__Study_Program__c, reduivy__Individual_Academic_Profile__c,
            (SELECT Id, reduivy__Term_Number__c, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c 
            FROM reduivy__Individual_Pathways__r ORDER BY reduivy__Term_Number__c) 
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Auto_Enrollment__c = :autoStatus
            ORDER BY reduivy__Contact__r.reduivy__Sequence__c ASC
            LIMIT 2
        ];
        
        Date toBeEnrolledTermStartDate = ipes[0].reduivy__Starting_Term__r.reduivy__End_Date__c.addDays(31);
        List<reduivy__Study_Term__c> terms = [
            SELECT Id, Name, reduivy__End_Date__c, reduivy__Start_Date__c 
            FROM reduivy__Study_Term__c 
            WHERE reduivy__Start_Date__c = :toBeEnrolledTermStartDate
        ];

        List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, Name FROM reduivy__Study_Unit__c WHERE Name IN ('BUS101', 'BUS102', 'BUS103', 'COM101')];
        List<reduivy__Study_Offering__c> studyOfferingsToBeCreated = new List<reduivy__Study_Offering__c>();
        
        for(reduivy__Study_Unit__c su : studyUnits) {
            studyOfferingsToBeCreated.add(new reduivy__Study_Offering__c(
                reduivy__Capacity__c = 10,
                reduivy__Study_Unit__c = su.Id,
                reduivy__Academic_Term__c = terms[0].Id,
                reduivy__Campus__c = ipes[0].reduivy__Default_Campus__c,
                reduivy__Start_Date__c = terms[0].reduivy__Start_Date__c,
                reduivy__End_Date__c = terms[0].reduivy__End_Date__c
            ));  
        }

        REDU_SystemMode_UTIL.doInsert(studyOfferingsToBeCreated);

        List<reduivy__Study_Offering__c> toBeEnrolledSof = [
            SELECT Id, reduivy__Study_Unit__c 
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Study_Unit__r.Name IN ('BUS101', 'BUS102', 'BUS103', 'COM101')
            AND reduivy__Academic_Term__c = :terms[0].Id
            ORDER BY reduivy__Study_Unit__r.Name
        ];

        // Scenario Setup:
        // Contact 1: Has 2 IPEs (master IPE for auto-enrollment + another IPE with different IPF)
        //            - IPE1 (Master): Linked to IPF1, used for auto-enrollment
        //            - IPE2 (Other): Linked to IPF2
        //            - Pre-create 2 IENs linked to IPF2 (should not affect auto-enrollment to IPF1)
        // Contact 2: Has 1 IPE (master IPE for auto-enrollment)
        //            - IPE1 (Master): Linked to IPF3, used for auto-enrollment

        reduivy__Individual_Program_Enrollment__c contact1MasterIpe = ipes[0];
        reduivy__Individual_Program_Enrollment__c contact2MasterIpe = ipes[1];

        // Create new Individual Academic Profiles
        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        List<reduivy__Individual_Academic_Profile__c> newIpfList = new List<reduivy__Individual_Academic_Profile__c>();
        
        // IPF1 for Contact 1 Master IPE (for auto-enrollment)
        reduivy__Individual_Academic_Profile__c ipf1 = REDU_TestData_UTIL.newIndividualAcademicProfile(
            'Contact1_Master_IPF',
            contact1MasterIpe.reduivy__Contact__c,
            'Contact1_Master_IPF',
            IPF_Helper.STATUS_ACTIVE,
            true
        );
        newIpfList.add(ipf1);
        ipfMap.put('IPF1', ipf1);
        
        // IPF2 for Contact 1 Other IPE (should not be used for auto-enrollment)
        reduivy__Individual_Academic_Profile__c ipf2 = REDU_TestData_UTIL.newIndividualAcademicProfile(
            'Contact1_Other_IPF',
            contact1MasterIpe.reduivy__Contact__c,
            'Contact1_Other_IPF',
            IPF_Helper.STATUS_ACTIVE,
            false
        );
        newIpfList.add(ipf2);
        ipfMap.put('IPF2', ipf2);
        
        // IPF3 for Contact 2 Master IPE (for auto-enrollment)
        reduivy__Individual_Academic_Profile__c ipf3 = REDU_TestData_UTIL.newIndividualAcademicProfile(
            'Contact2_Master_IPF',
            contact2MasterIpe.reduivy__Contact__c,
            'Contact2_Master_IPF',
            IPF_Helper.STATUS_ACTIVE,
            true
        );
        newIpfList.add(ipf3);
        ipfMap.put('IPF3', ipf3);
        
        insert newIpfList;
        
        // Update Master IPEs to link with their respective IPFs
        contact1MasterIpe.reduivy__Individual_Academic_Profile__c = ipf1.Id;
        contact2MasterIpe.reduivy__Individual_Academic_Profile__c = ipf3.Id;
        update new List<reduivy__Individual_Program_Enrollment__c>{contact1MasterIpe, contact2MasterIpe};
        
        // Create another IPE for Contact 1 linked to IPF2
        reduivy__Individual_Program_Enrollment__c contact1OtherIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            'Contact1_Other_IPE',
            contact1MasterIpe.reduivy__Contact__c,
            contact1MasterIpe.reduivy__Study_Program__c,
            contact1MasterIpe.reduivy__Study_Plan__c,
            null,
            contact1MasterIpe.reduivy__Starting_Term__c,
            null,
            null,
            null,
            null,
            false,
            IPE_Helper.getInProgressStatuses()[0],
            ipf2.Id
        );
        insert contact1OtherIpe;

        // Pre-create IENs for Contact 1 linked to IPF2 (not the master IPE's IPF)
        List<reduivy__Individual_Enrollment__c> preCreatedIensForIpf2 = new List<reduivy__Individual_Enrollment__c>();
        preCreatedIensForIpf2.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = contact1MasterIpe.reduivy__Contact__c,
            reduivy__Study_Offering__c = toBeEnrolledSof[0].Id, // BUS101
            RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
            reduivy__Enrollment_Status__c = IEN_Helper.getInProgressStatuses()[0],
            reduivy__Bypass_Requirement_Met__c = true,
            reduivy__Individual_Academic_Profile__c = ipf2.Id
        ));
        preCreatedIensForIpf2.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = contact1MasterIpe.reduivy__Contact__c,
            reduivy__Study_Offering__c = toBeEnrolledSof[1].Id, // BUS102
            RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
            reduivy__Enrollment_Status__c = IEN_Helper.getInProgressStatuses()[0],
            reduivy__Bypass_Requirement_Met__c = true,
            reduivy__Individual_Academic_Profile__c = ipf2.Id
        ));
        insert preCreatedIensForIpf2;

        // Setup IPWs for auto-enrollment
        List<Id> ipwIds = new List<Id>();
        List<reduivy__Individual_Pathway__c> ipwsToBeUpdated = new List<reduivy__Individual_Pathway__c>();
        
        for(reduivy__Individual_Program_Enrollment__c ipe : new List<reduivy__Individual_Program_Enrollment__c>{contact1MasterIpe, contact2MasterIpe}) {
            for(reduivy__Individual_Pathway__c ipw : ipe.reduivy__Individual_Pathways__r) {
                if(ipw.reduivy__Term_Number__c == 1) {
                    ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                        Id = ipw.Id, 
                        reduivy__Academic_Term__c = null, 
                        reduivy__Individual_Academic_Progress__c = null
                    ));
                    ipwIds.add(ipw.Id);
                }
            }
        }
        
        REDU_SystemMode_UTIL.doUpdate(ipwsToBeUpdated);

        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Cancelled;';

        Map<String, Object> params = new Map<String, Object>();
        params.put('toBeEnrolledTermId', terms[0].Id);
        params.put('proceedForUnitEnrollment', true);
        params.put('bypassRequirementRules', true);
        params.put('existingIndividualEnrollmentStatuses', existingIndividualEnrollmentStatuses);
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, terms[0].Id));
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, terms[0].Id);
        params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, terms[0].Name);

        JQH_TermStudentEnrollment_HANDLER handler = new JQH_TermStudentEnrollment_HANDLER();
        handler.setRecordIds(ipwIds);
        handler.setParams(params);

        System.runAs(ADMIN_USER) {            
            Test.startTest();
            JQH_JobManager.HandlerResult result = handler.execute();

            // Query all IENs for both contacts
            List<reduivy__Individual_Enrollment__c> allIENs = [
                SELECT Id, 
                reduivy__Contact__c, 
                reduivy__Individual_Academic_Profile__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Offering__c,
                reduivy__Auto_Enrollment__c
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c IN (:contact1MasterIpe.reduivy__Contact__c, :contact2MasterIpe.reduivy__Contact__c)
                ORDER BY reduivy__Contact__c, CreatedDate
            ];

            // Separate auto-enrolled IENs from pre-created IENs
            List<reduivy__Individual_Enrollment__c> autoEnrolledIENs = new List<reduivy__Individual_Enrollment__c>();
            List<reduivy__Individual_Enrollment__c> contact1PreCreatedIENs = new List<reduivy__Individual_Enrollment__c>();
            
            for(reduivy__Individual_Enrollment__c ien : allIENs) {
                if(ien.reduivy__Auto_Enrollment__c) {
                    autoEnrolledIENs.add(ien);
                } else if(ien.reduivy__Contact__c == contact1MasterIpe.reduivy__Contact__c) {
                    contact1PreCreatedIENs.add(ien);
                }
            }

            // Assertions for auto-enrolled IENs
            System.Assert.areEqual(8, autoEnrolledIENs.size(), '8 Individual Enrollments should be auto-created (4 units x 2 contacts)');

            // Assert Contact 1 auto-enrolled IENs are linked to IPF1 (Master IPE's IPF), not IPF2
            Integer contact1AutoEnrolledCount = 0;
            for(reduivy__Individual_Enrollment__c ien : autoEnrolledIENs) {
                if(ien.reduivy__Contact__c == contact1MasterIpe.reduivy__Contact__c) {
                    contact1AutoEnrolledCount++;
                    System.Assert.isNotNull(ien.reduivy__Individual_Academic_Profile__c, 'Contact 1: IPF should be set for auto-created enrollment');
                    System.Assert.areEqual(
                        ipf1.Id,
                        ien.reduivy__Individual_Academic_Profile__c,
                        'Contact 1: Auto-enrolled IEN should link to IPF1 (Master IPE IPF), not IPF2'
                    );
                    System.Assert.areNotEqual(
                        ipf2.Id,
                        ien.reduivy__Individual_Academic_Profile__c,
                        'Contact 1: Auto-enrolled IEN should NOT link to IPF2 (Other IPE IPF)'
                    );
                }
            }
            System.Assert.areEqual(4, contact1AutoEnrolledCount, 'Contact 1 should have 4 auto-enrolled IENs');

            // Assert Contact 2 auto-enrolled IENs are linked to IPF3
            Integer contact2AutoEnrolledCount = 0;
            for(reduivy__Individual_Enrollment__c ien : autoEnrolledIENs) {
                if(ien.reduivy__Contact__c == contact2MasterIpe.reduivy__Contact__c) {
                    contact2AutoEnrolledCount++;
                    System.Assert.isNotNull(ien.reduivy__Individual_Academic_Profile__c, 'Contact 2: IPF should be set for auto-created enrollment');
                    System.Assert.areEqual(
                        ipf3.Id,
                        ien.reduivy__Individual_Academic_Profile__c,
                        'Contact 2: Auto-enrolled IEN should link to IPF3 (Master IPE IPF)'
                    );
                }
            }
            System.Assert.areEqual(4, contact2AutoEnrolledCount, 'Contact 2 should have 4 auto-enrolled IENs');

            // Assert pre-created IENs for Contact 1 remain linked to IPF2
            System.Assert.areEqual(2, contact1PreCreatedIENs.size(), 'Contact 1 should have 2 pre-created IENs');
            for(reduivy__Individual_Enrollment__c ien : contact1PreCreatedIENs) {
                System.Assert.areEqual(
                    ipf2.Id,
                    ien.reduivy__Individual_Academic_Profile__c,
                    'Contact 1: Pre-created IEN should remain linked to IPF2'
                );
            }

            System.Assert.areEqual(2, result.success.size(), 'There should be 2 successful IPW enrollments');
            
            Test.stopTest();
        }
    }
}