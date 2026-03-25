/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Test
 * @description Test class for IPE_DefaultValues_EXE
 * @changehistory
 * ISS-001618 04-10-2023 dblack - new class
 */
@IsTest
public inherited sharing class IPE_DefaultValues_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';
    static final String STUDY_INTAKE = 'SYDNEY_BACBIS_NYINTAKE';
    static final String ACADEMIC_TERM = 'NYT1';
    static final String STUDY_PATHWAY = 'BACBIS_MajorA_DEFAULT';

    /**
     * @description Initialise test data for each test
     */
	@TestSetup
    static void makeData() {

        // Create settings
		testFactory.setupDefaultSettings();

        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(SPU_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
			testFactory.initStudentData(CON_Helper.getApiName(), false);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin that the default values are set when there is a related study intake
     */
    @IsTest
    static void testDefaultValuesWithStudyIntakeAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		List<Contact> studentCon = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		// Get study program records
		Map<String, reduivy__Study_Program__c> spgMap = new Map<String, reduivy__Study_Program__c>();
		List<reduivy__Study_Program__c> spgList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Program__c
		];
		for (reduivy__Study_Program__c spg : spgList) {
			spgMap.put(spg.reduivy__Sample_Record_Code__c, spg);
		}

        List<reduivy__Study_Plan__c> splList = [
			SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Type__c FROM reduivy__Study_Plan__c
		];
		for (reduivy__Study_Plan__c spl : splList) {
            spl.reduivy__Type__c = 'Major';
        }

        update splList;

		// Get the study intake records
        Map<String, reduivy__Study_Intake__c> sitMap = new Map<String, reduivy__Study_Intake__c>();
        List<reduivy__Study_Intake__c> sitList = [
            SELECT  Id, reduivy__Study_Program__c, reduivy__Default_Study_Plan__c, reduivy__Default_Study_Pathway__c, reduivy__Default_Study_Plan__r.reduivy__Type__c,
                    reduivy__Academic_Term__c, reduivy__Campus__c, reduivy__Sample_Record_Code__c, reduivy__Class_Year__c, reduivy__Cohort_ID__c
            FROM reduivy__Study_Intake__c
        ];

        for (reduivy__Study_Intake__c sit : sitList) {
            sit.reduivy__Class_Year__c = String.valueOf(System.today().year());
            sit.reduivy__Cohort_ID__c = 'TEST_COHORT';

			sitMap.put(sit.reduivy__Sample_Record_Code__c, sit);
		}

        update sitList;

		List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
		Test.startTest();

		// Execute test
		System.runAs(ADMIN_USER) {

			// Create individual program enrollment records
			List<String> enrollmentStatuses = IPE_Helper.getInProgressStatuses();
			
			for (Integer i = 0; i < studentCon.size(); i++) {
				String sampleRecordCode = 'IPE_CreateGroup_TEST-' + String.valueOf(i);
				Id contactId = studentCon[i].Id;
				Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
				Id studyPlanId = null;
				Id studyIntakeId = sitMap.get(STUDY_INTAKE).Id;
				Id startingTermId = null;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = enrollmentStatuses[0];
                Id idvAcademicProfileId = null;
				reduivy__Individual_Program_Enrollment__c ipe = 
					REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
						sampleRecordCode, 
						contactId, 
						studyProgramId, 
						studyPlanId, 
						studyIntakeId, 
						startingTermId, 
						studyPathwayId, 
						defaultCampusId, 
						classYear, 
						classStanding, 
						eligibleToEnroll, 
						enrollmentStatus,
                        idvAcademicProfileId
					);
				ipeList.add(ipe);
			}
			
			insert ipeList;
		}
	
		Test.stopTest();

        // Verify test results
        ipeList = [
            SELECT  reduivy__Study_Intake__c,
                    reduivy__Study_Plan__c, reduivy__Study_Pathway__c, 
                    reduivy__Starting_Term__c, reduivy__Default_Campus__c,
                    reduivy__Class_Year__c, reduivy__Cohort_ID__c, reduivy__Study_Plan_Option_Type__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Study_Intake__c != null
        ];
        System.Assert.isFalse(
            ipeList.isEmpty(),
            'There should be a list of individual program enrollment records'
        );
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.isNotNull(ipe.reduivy__Study_Plan__c);
            System.Assert.isNotNull(ipe.reduivy__Study_Pathway__c);
            System.Assert.isNotNull(ipe.reduivy__Starting_Term__c);
            System.Assert.isNotNull(ipe.reduivy__Default_Campus__c);
            System.Assert.isNotNull(ipe.reduivy__Class_Year__c);
            System.Assert.isNotNull(ipe.reduivy__Cohort_ID__c);
            System.Assert.isNotNull(ipe.reduivy__Study_Plan_Option_Type__c);

            System.Assert.areEqual(
                sitMap.get(STUDY_INTAKE).reduivy__Default_Study_Plan__c,
                ipe.reduivy__Study_Plan__c,
                'The actual value should be as expected'
            );
            System.Assert.areEqual(
                sitMap.get(STUDY_INTAKE).reduivy__Default_Study_Pathway__c,
                ipe.reduivy__Study_Pathway__c,
                'The actual value should be as expected'
            );
            System.Assert.areEqual(
                sitMap.get(STUDY_INTAKE).reduivy__Academic_Term__c,
                ipe.reduivy__Starting_Term__c,
                'The actual value should be as expected'
            );
            System.Assert.areEqual(
                sitMap.get(STUDY_INTAKE).reduivy__Campus__c,
                ipe.reduivy__Default_Campus__c,
                'The actual value should be as expected'
            );
            System.Assert.areEqual(
                sitMap.get(STUDY_INTAKE).reduivy__Class_Year__c,
                ipe.reduivy__Class_Year__c,
                'The actual value should be as expected'
            );
            System.Assert.areEqual(
                sitMap.get(STUDY_INTAKE).reduivy__Default_Study_Plan__r.reduivy__Type__c,
                ipe.reduivy__Study_Plan_Option_Type__c,
                'The actual value should be as expected'
            );
            System.Assert.areEqual(
                sitMap.get(STUDY_INTAKE).reduivy__Cohort_ID__c,
                ipe.reduivy__Cohort_ID__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as admin that the default values are set when there is a related study plan but no related study intake
     */
    @IsTest
    static void testDefaultValuesWithStudyPlanAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		List<Contact> studentCon = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		// Get study program records
		Map<String, reduivy__Study_Program__c> spgMap = new Map<String, reduivy__Study_Program__c>();
		List<reduivy__Study_Program__c> spgList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Program__c
		];
		for (reduivy__Study_Program__c spg : spgList) {
			spgMap.put(spg.reduivy__Sample_Record_Code__c, spg);
		}

        // Get study plan records
		Map<String, reduivy__Study_Plan__c> splMap = new Map<String, reduivy__Study_Plan__c>();
		List<reduivy__Study_Plan__c> splList = [
			SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Type__c FROM reduivy__Study_Plan__c
		];
		for (reduivy__Study_Plan__c spl : splList) {
            spl.reduivy__Type__c = 'Major';

			splMap.put(spl.reduivy__Sample_Record_Code__c, spl);
		}

        update splList;

        // Get a campus record
        List<Account> accList = [
            SELECT Id
            FROM Account 
            WHERE RecordTypeId = :ACC_Helper.getCampusRecordTypeId()
            LIMIT 1
        ];

        List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
		Test.startTest();

		// Execute test
		System.runAs(ADMIN_USER) {

			// Create individual program enrollment records
			List<String> enrollmentStatuses = IPE_Helper.getInProgressStatuses();
			
			for (Integer i = 0; i < studentCon.size(); i++) {
				String sampleRecordCode = 'IPE_CreateGroup_TEST-' + String.valueOf(i);
				Id contactId = studentCon[i].Id;
				Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
				Id studyPlanId = splMap.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = null;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = enrollmentStatuses[0];
                Id idvAcademicProfileId = null;
				reduivy__Individual_Program_Enrollment__c ipe = 
					REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
						sampleRecordCode, 
						contactId, 
						studyProgramId, 
						studyPlanId, 
						studyIntakeId, 
						startingTermId, 
						studyPathwayId, 
						defaultCampusId, 
						classYear, 
						classStanding, 
						eligibleToEnroll, 
						enrollmentStatus,
                        idvAcademicProfileId
					);
				ipeList.add(ipe);
			}
			
			insert ipeList;
		}
	
		Test.stopTest();

        // Verify test results
        ipeList = [
            SELECT  reduivy__Study_Plan__c, reduivy__Study_Pathway__c, reduivy__Cohort_ID__c, reduivy__Class_Year__c,
                    reduivy__Study_Pathway__r.reduivy__Study_Plan__c, reduivy__Study_Plan_Option_Type__c, reduivy__Study_Pathway__r.reduivy__Study_Plan__r.reduivy__Type__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Study_Plan__c != null
        ];
        System.Assert.isFalse(
            ipeList.isEmpty(),
            'There should be a list of individual program enrollment records'
        );
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.isNotNull(ipe.reduivy__Study_Plan__c);
            System.Assert.isNotNull(ipe.reduivy__Study_Pathway__c);
            System.Assert.isNotNull(ipe.reduivy__Study_Plan_Option_Type__c);

            System.Assert.areEqual(
                splMap.get(STUDY_PLAN).Id,
                ipe.reduivy__Study_Plan__c,
                'The actual value should be as expected'
            );
            System.Assert.areEqual(
                ipe.reduivy__Study_Plan__c, 
                ipe.reduivy__Study_Pathway__r.reduivy__Study_Plan__c,
                'The actual value should be as expected'
            );
            System.Assert.areEqual(
                ipe.reduivy__Study_Pathway__r.reduivy__Study_Plan__r.reduivy__Type__c, 
                ipe.reduivy__Study_Plan_Option_Type__c,
                'The actual value should be as expected'
            );

            System.assertEquals(
                true, 
                String.isBlank(ipe.reduivy__Cohort_ID__c), 
                'The Cohort ID should remain empty because the Study Intake is not populated'
            );

            System.assertEquals(
                true, 
                String.isBlank(ipe.reduivy__Class_Year__c), 
                'The Class Year should remain empty because the Study Intake is not populated'
            );
        }
    }

    /**
     * @description Test as admin that the default values are set when there is not a related study intake nor related study plan
     */
    @IsTest
    static void testDefaultValuesWithStudyProgramAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		List<Contact> studentCon = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

         // Get study plan records
		Map<String, reduivy__Study_Plan__c> splMap = new Map<String, reduivy__Study_Plan__c>();
		List<reduivy__Study_Plan__c> splList = [
			SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Type__c FROM reduivy__Study_Plan__c
		];
		for (reduivy__Study_Plan__c spl : splList) {
            spl.reduivy__Type__c = 'Major';
		}

        update splList;

		// Get study pathway, study plan and study program records
		Map<String, reduivy__Study_Pathway__c> spwMap = new Map<String, reduivy__Study_Pathway__c>();
		List<reduivy__Study_Pathway__c> spwList = [
			SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Study_Plan__c, reduivy__Study_Plan__r.reduivy__Study_Program__c, reduivy__Study_Plan__r.reduivy__Type__c FROM reduivy__Study_Pathway__c
		];
		for (reduivy__Study_Pathway__c spw : spwList) {
			if (spw.reduivy__Sample_Record_Code__c.equals(STUDY_PATHWAY)) {
				spwMap.put(spw.reduivy__Sample_Record_Code__c, spw);
			}
		}

        // Setup test data
        List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();

        Test.startTest();

		// Execute test
		System.runAs(ADMIN_USER) {

			// Create individual program enrollment records
			List<String> enrollmentStatuses = IPE_Helper.getInProgressStatuses();

			for (Integer i = 0; i < studentCon.size(); i++) {
				String sampleRecordCode = 'IPE_CreatePathway_TEST-' + String.valueOf(i);
				Id contactId = studentCon[i].Id;
				Id studyProgramId = spwMap.get(STUDY_PATHWAY).reduivy__Study_Plan__r.reduivy__Study_Program__c;
				Id studyPlanId = null;
				Id studyIntakeId = null;
				Id startingTermId = null;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = enrollmentStatuses[0];
                Id idvAcademicProfileId = null;
				reduivy__Individual_Program_Enrollment__c ipe = 
					REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
						sampleRecordCode, 
						contactId, 
						studyProgramId, 
						studyPlanId, 
						studyIntakeId, 
						startingTermId, 
						studyPathwayId, 
						defaultCampusId, 
						classYear, 
						classStanding, 
						eligibleToEnroll, 
						enrollmentStatus,
                        idvAcademicProfileId
					);
				ipeList.add(ipe);
			}
			
			insert ipeList;
		}

		Test.stopTest();

        // Verify test results
        ipeList = [
            SELECT  reduivy__Study_Program__c, reduivy__Cohort_ID__c, reduivy__Class_Year__c,
                    reduivy__Study_Plan__c, reduivy__Study_Pathway__c, reduivy__Study_Plan_Option_Type__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Study_Program__c != null
        ];
        System.Assert.isFalse(
            ipeList.isEmpty(),
            'There should be a list of individual program enrollment records'
        );
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.isNotNull(ipe.reduivy__Study_Plan__c);
            System.Assert.isNotNull(ipe.reduivy__Study_Pathway__c);
            System.Assert.isNotNull(ipe.reduivy__Study_Plan_Option_Type__c);

            System.Assert.areEqual(
                spwMap.get(STUDY_PATHWAY).reduivy__Study_Plan__c,
                ipe.reduivy__Study_Plan__c,
                'The actual value should be as expected'
            );
            System.Assert.areEqual(
                spwMap.get(STUDY_PATHWAY).Id,
                ipe.reduivy__Study_Pathway__c,
                'The actual value should be as expected'
            );
            System.Assert.areEqual(
                spwMap.get(STUDY_PATHWAY).reduivy__Study_Plan__r.reduivy__Type__c,
                ipe.reduivy__Study_Plan_Option_Type__c,
                'The actual value should be as expected'
            );

            System.assertEquals(
                true, 
                String.isBlank(ipe.reduivy__Cohort_ID__c), 
                'The Cohort ID should remain empty because the Study Intake is not populated'
            );

            System.assertEquals(
                true, 
                String.isBlank(ipe.reduivy__Class_Year__c), 
                'The Class Year should remain empty because the Study Intake is not populated'
            );
        }
    }

    /**
     * @description Test as admin that the default values are set for multiple IPE records with different blank fields
     */
    @IsTest
    static void testDefaultValuesWithMultipleBlankFieldScenarios() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentCon = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<Account> campusList = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1];

        // Get study program records
        Map<String, reduivy__Study_Program__c> spgMap = new Map<String, reduivy__Study_Program__c>();
        List<reduivy__Study_Program__c> spgList = [
            SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Program__c
        ];
        for (reduivy__Study_Program__c spg : spgList) {
            spgMap.put(spg.reduivy__Sample_Record_Code__c, spg);
        }

        // Get study plan records and set Type
        Map<String, reduivy__Study_Plan__c> splMap = new Map<String, reduivy__Study_Plan__c>();
        List<reduivy__Study_Plan__c> splList = [
            SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Type__c FROM reduivy__Study_Plan__c
        ];
        for (reduivy__Study_Plan__c spl : splList) {
            spl.reduivy__Type__c = 'Major';
            splMap.put(spl.reduivy__Sample_Record_Code__c, spl);
        }
        update splList;

        // Get the study intake records and set required fields
        Map<String, reduivy__Study_Intake__c> sitMap = new Map<String, reduivy__Study_Intake__c>();
        List<reduivy__Study_Intake__c> sitList = [
            SELECT  Id, reduivy__Study_Program__c, reduivy__Default_Study_Plan__c, reduivy__Default_Study_Pathway__c, 
                    reduivy__Academic_Term__c, reduivy__Campus__c, reduivy__Sample_Record_Code__c, 
                    reduivy__Class_Year__c, reduivy__Cohort_ID__c
            FROM reduivy__Study_Intake__c
        ];

        for (reduivy__Study_Intake__c sit : sitList) {
            sit.reduivy__Class_Year__c = String.valueOf(System.today().year());
            sit.reduivy__Cohort_ID__c = 'TEST_COHORT';
            sitMap.put(sit.reduivy__Sample_Record_Code__c, sit);
        }
        update sitList;

        List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
        Test.startTest();

        // Execute test
        System.runAs(ADMIN_USER) {

            List<String> enrollmentStatuses = IPE_Helper.getInProgressStatuses();
            Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
            Id studyPlanId = splMap.get(STUDY_PLAN).Id;
            Id studyIntakeId = sitMap.get(STUDY_INTAKE).Id;

            // Scenario 1: All fields blank except Study Program (should use default Study Plan from Study Program)
            reduivy__Individual_Program_Enrollment__c ipe1 = 
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    'IPE_Scenario1_TEST', 
                    studentCon[0].Id, 
                    studyProgramId, 
                    null, // studyPlanId - blank
                    null, // studyIntakeId - blank
                    null, // startingTermId - blank
                    null, // studyPathwayId - blank
                    null, // defaultCampusId - blank
                    null, // classYear - blank
                    null, // classStanding
                    true, // eligibleToEnroll
                    enrollmentStatuses[0],
                    null  // idvAcademicProfileId
                );
            ipeList.add(ipe1);

            // Scenario 2: Only Study Plan blank (should populate Study Plan from Study Intake)
            reduivy__Individual_Program_Enrollment__c ipe2 = 
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    'IPE_Scenario2_TEST', 
                    studentCon[0].Id, 
                    studyProgramId, 
                    null, // studyPlanId - blank
                    studyIntakeId, // studyIntakeId - populated
                    sitList[0].reduivy__Academic_Term__c, // startingTermId - populated
                    sitList[0].reduivy__Default_Study_Pathway__c, // studyPathwayId - populated
                    campusList[0].Id, // defaultCampusId - populated
                    sitList[0].reduivy__Class_Year__c, // classYear - populated
                    null, // classStanding
                    true, // eligibleToEnroll
                    enrollmentStatuses[0],
                    null  // idvAcademicProfileId
                );
            ipeList.add(ipe2);

            // Scenario 3: Only Study Pathway blank (should populate Study Pathway from Study Intake)
            reduivy__Individual_Program_Enrollment__c ipe3 = 
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    'IPE_Scenario3_TEST', 
                    studentCon[0].Id, 
                    studyProgramId, 
                    studyPlanId, // studyPlanId - populated
                    studyIntakeId, // studyIntakeId - populated
                    sitList[0].reduivy__Academic_Term__c, // startingTermId - populated
                    null, // studyPathwayId - blank
                    campusList[0].Id, // defaultCampusId - populated
                    sitList[0].reduivy__Class_Year__c, // classYear - populated
                    null, // classStanding
                    true, // eligibleToEnroll
                    enrollmentStatuses[0],
                    null  // idvAcademicProfileId
                );
            ipeList.add(ipe3);

            // Scenario 4: Only Starting Term blank (should populate Starting Term from Study Intake)
            reduivy__Individual_Program_Enrollment__c ipe4 = 
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    'IPE_Scenario4_TEST', 
                    studentCon[0].Id, 
                    studyProgramId, 
                    studyPlanId, // studyPlanId - populated
                    studyIntakeId, // studyIntakeId - populated
                    null, // startingTermId - blank
                    sitList[0].reduivy__Default_Study_Pathway__c, // studyPathwayId - populated
                    campusList[0].Id, // defaultCampusId - populated
                    sitList[0].reduivy__Class_Year__c, // classYear - populated
                    null, // classStanding
                    true, // eligibleToEnroll
                    enrollmentStatuses[0],
                    null  // idvAcademicProfileId
                );
            ipeList.add(ipe4);

            // Scenario 5: Only Default Campus blank (should populate Default Campus from Study Intake)
            reduivy__Individual_Program_Enrollment__c ipe5 = 
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    'IPE_Scenario5_TEST', 
                    studentCon[0].Id, 
                    studyProgramId, 
                    studyPlanId, // studyPlanId - populated
                    studyIntakeId, // studyIntakeId - populated
                    sitList[0].reduivy__Academic_Term__c, // startingTermId - populated
                    sitList[0].reduivy__Default_Study_Pathway__c, // studyPathwayId - populated
                    null, // defaultCampusId - null
                    sitList[0].reduivy__Class_Year__c, // classYear - populated
                    null, // classStanding
                    true, // eligibleToEnroll
                    enrollmentStatuses[0],
                    null  // idvAcademicProfileId
                );
            ipeList.add(ipe5);

            // Scenario 6: Only Class Year blank with Study Intake (should populate Class Year from Study Intake)
            reduivy__Individual_Program_Enrollment__c ipe6 = 
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    'IPE_Scenario6_TEST', 
                    studentCon[0].Id, 
                    studyProgramId, 
                    studyPlanId, // studyPlanId - populated
                    studyIntakeId, // studyIntakeId - populated
                    sitList[0].reduivy__Academic_Term__c, // startingTermId - populated
                    sitList[0].reduivy__Default_Study_Pathway__c, // studyPathwayId - populated
                    campusList[0].Id, // defaultCampusId - populated
                    null, // classYear - blank
                    null, // classStanding
                    true, // eligibleToEnroll
                    enrollmentStatuses[0],
                    null  // idvAcademicProfileId
                );

                ipe6.reduivy__Study_Plan_Option_Type__c = 'Major';
            ipeList.add(ipe6);

            // Scenario 7: Only Cohort ID blank with Study Intake (should populate Cohort ID from Study Intake)
            reduivy__Individual_Program_Enrollment__c ipe7 = 
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    'IPE_Scenario7_TEST', 
                    studentCon[0].Id, 
                    studyProgramId, 
                    studyPlanId, // studyPlanId - populated
                    studyIntakeId, // studyIntakeId - populated
                    sitList[0].reduivy__Academic_Term__c, // startingTermId - populated
                    sitList[0].reduivy__Default_Study_Pathway__c, // studyPathwayId - populated
                    campusList[0].Id, // defaultCampusId - populated
                    String.valueOf(System.today().year()), // classYear - populated
                    null, // classStanding
                    true, // eligibleToEnroll
                    enrollmentStatuses[0],
                    null  // idvAcademicProfileId
                );

            ipe7.reduivy__Study_Plan_Option_Type__c = 'Major';
            ipeList.add(ipe7);

            // Scenario 8: Only Study Plan Option Type blank with Study Intake (should populate from Study Intake's Study Plan Type)
            reduivy__Individual_Program_Enrollment__c ipe8 = 
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    'IPE_Scenario8_TEST', 
                    studentCon[0].Id, 
                    studyProgramId, 
                    studyPlanId, // studyPlanId - populated
                    studyIntakeId, // studyIntakeId - populated
                    sitList[0].reduivy__Academic_Term__c, // startingTermId - populated
                    sitList[0].reduivy__Default_Study_Pathway__c, // studyPathwayId - populated
                    campusList[0].Id, // defaultCampusId - populated
                    String.valueOf(System.today().year()), // classYear - populated
                    null, // classStanding
                    true, // eligibleToEnroll
                    enrollmentStatuses[0],
                    null  // idvAcademicProfileId
                );
            ipeList.add(ipe8);

            // Scenario 9: Study Plan populated but no Study Intake (should use Study Plan defaults)
            reduivy__Individual_Program_Enrollment__c ipe9 = 
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    'IPE_Scenario9_TEST', 
                    studentCon[0].Id, 
                    studyProgramId, 
                    studyPlanId, // studyPlanId - populated
                    null, // studyIntakeId - blank
                    null, // startingTermId - blank
                    null, // studyPathwayId - blank
                    null, // defaultCampusId - blank
                    null, // classYear - blank
                    null, // classStanding
                    true, // eligibleToEnroll
                    enrollmentStatuses[0],
                    null  // idvAcademicProfileId
                );
            ipeList.add(ipe9);

            // Scenario 10: Multiple fields blank with Study Intake (should populate all from Study Intake)
            reduivy__Individual_Program_Enrollment__c ipe10 = 
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    'IPE_Scenario10_TEST', 
                    studentCon[0].Id, 
                    studyProgramId, 
                    null, // studyPlanId - blank
                    studyIntakeId, // studyIntakeId - populated
                    null, // startingTermId - blank
                    null, // studyPathwayId - blank
                    null, // defaultCampusId - blank
                    null, // classYear - blank
                    null, // classStanding
                    true, // eligibleToEnroll
                    enrollmentStatuses[0],
                    null  // idvAcademicProfileId
                );
            ipeList.add(ipe10);

            insert ipeList;
        }

        Test.stopTest();

        // Verify test results
        List<reduivy__Individual_Program_Enrollment__c> insertedIpes = [
            SELECT  Id, reduivy__Sample_Record_Code__c, reduivy__Study_Intake__c,
                    reduivy__Study_Plan__c, reduivy__Study_Pathway__c, 
                    reduivy__Starting_Term__c, reduivy__Default_Campus__c,
                    reduivy__Class_Year__c, reduivy__Cohort_ID__c, reduivy__Study_Plan_Option_Type__c,
                    reduivy__Study_Pathway__r.reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Sample_Record_Code__c LIKE 'IPE_Scenario%'
            ORDER BY reduivy__Sample_Record_Code__c
        ];

        Map<String, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        for(reduivy__Individual_Program_Enrollment__c ipe : insertedIpes) {
            ipeMap.put(ipe.reduivy__Sample_Record_Code__c, ipe);
        }

        System.Assert.areEqual(10, insertedIpes.size(), 'Should have 10 IPE records created');

        // Verify Scenario 1: All fields blank except Study Program
        reduivy__Individual_Program_Enrollment__c scenario1 = ipeMap.get('IPE_Scenario1_TEST');
        System.Assert.areEqual('IPE_Scenario1_TEST', scenario1.reduivy__Sample_Record_Code__c);
        System.Assert.isNotNull(scenario1.reduivy__Study_Plan__c, 'Study Plan should be populated from default Study Program');
        System.Assert.isNotNull(scenario1.reduivy__Study_Pathway__c, 'Study Pathway should be populated from default Study Plan');
        System.Assert.isNotNull(scenario1.reduivy__Study_Plan_Option_Type__c, 'Study Plan Option Type should be populated');
        System.Assert.isNull(scenario1.reduivy__Study_Intake__c, 'Study Intake should remain null');
        System.Assert.isNull(scenario1.reduivy__Class_Year__c, 'Class Year should remain null (no Study Intake)');
        System.Assert.isNull(scenario1.reduivy__Cohort_ID__c, 'Cohort ID should remain null (no Study Intake)');

        // Verify Scenario 2: Only Study Plan blank with Study Intake
        reduivy__Individual_Program_Enrollment__c scenario2 = ipeMap.get('IPE_Scenario2_TEST');
        System.Assert.areEqual('IPE_Scenario2_TEST', scenario2.reduivy__Sample_Record_Code__c);
        System.Assert.isNotNull(scenario2.reduivy__Study_Plan__c, 'Study Plan should be populated from Study Intake');
        System.Assert.isNotNull(scenario2.reduivy__Study_Pathway__c, 'Study Pathway should be populated from Study Intake');
        System.Assert.isNotNull(scenario2.reduivy__Starting_Term__c, 'Starting Term should be populated from Study Intake');
        System.Assert.isNotNull(scenario2.reduivy__Default_Campus__c, 'Default Campus should be populated from Study Intake');
        System.Assert.isNotNull(scenario2.reduivy__Class_Year__c, 'Class Year should be populated from Study Intake');
        System.Assert.isNotNull(scenario2.reduivy__Cohort_ID__c, 'Cohort ID should be populated from Study Intake');
        System.Assert.isNotNull(scenario2.reduivy__Study_Plan_Option_Type__c, 'Study Plan Option Type should be populated');
        System.Assert.areEqual(sitMap.get(STUDY_INTAKE).reduivy__Default_Study_Plan__c, scenario2.reduivy__Study_Plan__c, 'Should match Study Intake default Study Plan');

        // Verify Scenario 3: Only Study Pathway blank with Study Intake
        reduivy__Individual_Program_Enrollment__c scenario3 = ipeMap.get('IPE_Scenario3_TEST');
        System.Assert.areEqual('IPE_Scenario3_TEST', scenario3.reduivy__Sample_Record_Code__c);
        System.Assert.isNotNull(scenario3.reduivy__Study_Pathway__c, 'Study Pathway should be populated from Study Intake');
        System.Assert.areEqual(sitMap.get(STUDY_INTAKE).reduivy__Default_Study_Pathway__c, scenario3.reduivy__Study_Pathway__c, 'Should match Study Intake default Study Pathway');

        // Verify Scenario 4: Only Starting Term blank with Study Intake
        reduivy__Individual_Program_Enrollment__c scenario4 = ipeMap.get('IPE_Scenario4_TEST');
        System.Assert.areEqual('IPE_Scenario4_TEST', scenario4.reduivy__Sample_Record_Code__c);
        System.Assert.isNotNull(scenario4.reduivy__Starting_Term__c, 'Starting Term should be populated from Study Intake');
        System.Assert.areEqual(sitMap.get(STUDY_INTAKE).reduivy__Academic_Term__c, scenario4.reduivy__Starting_Term__c, 'Should match Study Intake Academic Term');

        // Verify Scenario 5: Only Default Campus blank with Study Intake
        reduivy__Individual_Program_Enrollment__c scenario5 = ipeMap.get('IPE_Scenario5_TEST');
        System.Assert.areEqual('IPE_Scenario5_TEST', scenario5.reduivy__Sample_Record_Code__c);
        System.Assert.isNotNull(scenario5.reduivy__Default_Campus__c, 'Default Campus should be populated from Study Intake');
        System.Assert.areEqual(sitMap.get(STUDY_INTAKE).reduivy__Campus__c, scenario5.reduivy__Default_Campus__c, 'Should match Study Intake Campus');

        // Verify Scenario 6: Only Class Year blank with Study Intake
        reduivy__Individual_Program_Enrollment__c scenario6 = ipeMap.get('IPE_Scenario6_TEST');
        System.Assert.areEqual('IPE_Scenario6_TEST', scenario6.reduivy__Sample_Record_Code__c);
        System.Assert.isNotNull(scenario6.reduivy__Class_Year__c, 'Class Year should be populated from Study Intake');
        System.Assert.areEqual(sitMap.get(STUDY_INTAKE).reduivy__Class_Year__c, scenario6.reduivy__Class_Year__c, 'Should match Study Intake Class Year');

        // Verify Scenario 7: Only Cohort ID blank with Study Intake
        reduivy__Individual_Program_Enrollment__c scenario7 = ipeMap.get('IPE_Scenario7_TEST');
        System.Assert.areEqual('IPE_Scenario7_TEST', scenario7.reduivy__Sample_Record_Code__c);
        System.Assert.isNotNull(scenario7.reduivy__Cohort_ID__c, 'Cohort ID should be populated from Study Intake');
        System.Assert.areEqual(sitMap.get(STUDY_INTAKE).reduivy__Cohort_ID__c, scenario7.reduivy__Cohort_ID__c, 'Should match Study Intake Cohort ID');

        // Verify Scenario 8: Only Study Plan Option Type blank with Study Intake
        reduivy__Individual_Program_Enrollment__c scenario8 = ipeMap.get('IPE_Scenario8_TEST');
        System.Assert.areEqual('IPE_Scenario8_TEST', scenario8.reduivy__Sample_Record_Code__c);
        System.Assert.isNotNull(scenario8.reduivy__Study_Plan_Option_Type__c, 'Study Plan Option Type should be populated from Study Intake');

        // Verify Scenario 9: Study Plan populated but no Study Intake
        reduivy__Individual_Program_Enrollment__c scenario9 = ipeMap.get('IPE_Scenario9_TEST');
        System.Assert.areEqual('IPE_Scenario9_TEST', scenario9.reduivy__Sample_Record_Code__c);
        System.Assert.isNotNull(scenario9.reduivy__Study_Plan__c, 'Study Plan should remain populated');
        System.Assert.isNotNull(scenario9.reduivy__Study_Pathway__c, 'Study Pathway should be populated from Study Plan');
        System.Assert.isNotNull(scenario9.reduivy__Study_Plan_Option_Type__c, 'Study Plan Option Type should be populated from Study Plan');
        System.Assert.isNull(scenario9.reduivy__Study_Intake__c, 'Study Intake should remain null');
        System.Assert.isNull(scenario9.reduivy__Class_Year__c, 'Class Year should remain null (no Study Intake)');
        System.Assert.isNull(scenario9.reduivy__Cohort_ID__c, 'Cohort ID should remain null (no Study Intake)');
        System.Assert.areEqual(splMap.get(STUDY_PLAN).Id, scenario9.reduivy__Study_Plan__c, 'Should match the provided Study Plan');

        // Verify Scenario 10: Multiple fields blank with Study Intake
        reduivy__Individual_Program_Enrollment__c scenario10 = ipeMap.get('IPE_Scenario10_TEST');
        System.Assert.areEqual('IPE_Scenario10_TEST', scenario10.reduivy__Sample_Record_Code__c);
        System.Assert.isNotNull(scenario10.reduivy__Study_Plan__c, 'Study Plan should be populated from Study Intake');
        System.Assert.isNotNull(scenario10.reduivy__Study_Pathway__c, 'Study Pathway should be populated from Study Intake');
        System.Assert.isNotNull(scenario10.reduivy__Starting_Term__c, 'Starting Term should be populated from Study Intake');
        System.Assert.isNotNull(scenario10.reduivy__Default_Campus__c, 'Default Campus should be populated from Study Intake');
        System.Assert.isNotNull(scenario10.reduivy__Class_Year__c, 'Class Year should be populated from Study Intake');
        System.Assert.isNotNull(scenario10.reduivy__Cohort_ID__c, 'Cohort ID should be populated from Study Intake');
        System.Assert.isNotNull(scenario10.reduivy__Study_Plan_Option_Type__c, 'Study Plan Option Type should be populated from Study Intake');
        
        // Verify all Study Intake related fields match expected values
        System.Assert.areEqual(sitMap.get(STUDY_INTAKE).reduivy__Default_Study_Plan__c, scenario10.reduivy__Study_Plan__c, 'Should match Study Intake default Study Plan');
        System.Assert.areEqual(sitMap.get(STUDY_INTAKE).reduivy__Default_Study_Pathway__c, scenario10.reduivy__Study_Pathway__c, 'Should match Study Intake default Study Pathway');
        System.Assert.areEqual(sitMap.get(STUDY_INTAKE).reduivy__Academic_Term__c, scenario10.reduivy__Starting_Term__c, 'Should match Study Intake Academic Term');
        System.Assert.areEqual(sitMap.get(STUDY_INTAKE).reduivy__Campus__c, scenario10.reduivy__Default_Campus__c, 'Should match Study Intake Campus');
        System.Assert.areEqual(sitMap.get(STUDY_INTAKE).reduivy__Class_Year__c, scenario10.reduivy__Class_Year__c, 'Should match Study Intake Class Year');
        System.Assert.areEqual(sitMap.get(STUDY_INTAKE).reduivy__Cohort_ID__c, scenario10.reduivy__Cohort_ID__c, 'Should match Study Intake Cohort ID');
    }

    /**
     * @description Test that child IPE records are not processed by the trigger and do not get default values populated
     */
    @IsTest
    static void testChildIPERecordsDoNotGetDefaultValues() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentCon = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Get study program records
        Map<String, reduivy__Study_Program__c> spgMap = new Map<String, reduivy__Study_Program__c>();
        List<reduivy__Study_Program__c> spgList = [
            SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Program__c
        ];
        for (reduivy__Study_Program__c spg : spgList) {
            spgMap.put(spg.reduivy__Sample_Record_Code__c, spg);
        }

        Test.startTest();

        // Execute test
        System.runAs(ADMIN_USER) {

            List<String> enrollmentStatuses = IPE_Helper.getInProgressStatuses();
            List<String> draftEnrollmentStatuses = IPE_Helper.getDraftStatuses();
            Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;

            // First, create a Master IPE record that will be used as parent record for child IPE
            reduivy__Individual_Program_Enrollment__c masterIpe = 
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    'MASTER_IPE_TEST', 
                    studentCon[0].Id, 
                    studyProgramId, 
                    null, // studyPlanId - will be populated by trigger
                    null, // studyIntakeId
                    null, // startingTermId
                    null, // studyPathwayId
                    null, // defaultCampusId
                    null, // classYear
                    null, // classStanding
                    true, // eligibleToEnroll
                    enrollmentStatuses[0],
                    null  // idvAcademicProfileId
                );

            // Insert master IPE record first
            insert masterIpe;

            // Now create Child IPE record with blank Study Plan field
            reduivy__Individual_Program_Enrollment__c childIpe = 
                REDU_TestData_UTIL.newChildIndividualProgramEnrollment(
                    'CHILD_IPE_TEST',
                    studentCon[0].Id,
                    studyProgramId,
                    null, // studyPlanId - blank (this should NOT be populated by trigger)
                    masterIpe.Id, // masterIndividualProgramEnrollmentId
                    null, // completionRequirement
                    true, // eligibleToEnroll
                    draftEnrollmentStatuses[0]
                );

            // Insert child IPE record
            insert childIpe;
        }

        Test.stopTest();

        // Verify that Master IPE record got default values populated
        reduivy__Individual_Program_Enrollment__c insertedMasterIpe = [
            SELECT  Id, reduivy__Study_Plan__c, RecordTypeId
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Sample_Record_Code__c = 'MASTER_IPE_TEST'
            LIMIT 1
        ];

        System.Assert.areEqual(IPE_Helper.getMasterEnrollmentRecordTypeId(), insertedMasterIpe.RecordTypeId, 'Should be Master record type');
        System.Assert.isNotNull(insertedMasterIpe.reduivy__Study_Plan__c, 'Master IPE Study Plan should be populated by trigger');

        // Verify that Child IPE record did NOT get default values populated
        reduivy__Individual_Program_Enrollment__c insertedChildIpe = [
            SELECT  Id, reduivy__Study_Plan__c, RecordTypeId, reduivy__Master_Enrollment__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Sample_Record_Code__c = 'CHILD_IPE_TEST'
            LIMIT 1
        ];

        System.Assert.areEqual(IPE_Helper.getChildEnrollmentRecordTypeId(), insertedChildIpe.RecordTypeId, 'Should be Child record type');
        System.Assert.isNotNull(insertedChildIpe.reduivy__Master_Enrollment__c, 'Master Enrollment should be populated');
        System.Assert.isNull(insertedChildIpe.reduivy__Study_Plan__c, 'Child IPE Study Plan should remain blank (trigger should not populate)');
    }
}