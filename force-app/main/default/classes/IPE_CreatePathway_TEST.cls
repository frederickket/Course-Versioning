/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Test
 * @description Test class for IPE_CreatePathway_EXE
 * @changehistory
 * ISS-001662 12-10-2023 dblack - new class
 */
@IsTest
public inherited sharing class IPE_CreatePathway_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
	
    static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';
	static final String STUDY_PATHWAY = 'BACBIS_MajorA_DEFAULT';
	static final String STUDY_PATHWAY_TERM = 'BACBIS_MajorA_DEFAULT_T1';
	static final String ACADEMIC_TERM = 'NYT1';

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
            testFactory.initOfferingData(STM_Helper.getApiName());
			testFactory.initStudentData(CON_Helper.getApiName(), false);

			Test.stopTest();
        }

    }

    /**
     * @description Test as admin that individual pathway records are created after an IPE record is inserted
     */
    @IsTest
    static void testCreateIpwAfterIpeInsertAsAdminUser() {

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
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c
		];
		for (reduivy__Study_Plan__c spl : splList) {
			splMap.put(spl.reduivy__Sample_Record_Code__c, spl);
		}

		// Get study term records
		Map<String, reduivy__Study_Term__c> stmMap = new Map<String, reduivy__Study_Term__c>();
		List<reduivy__Study_Term__c> stmList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Term__c
		];
		for (reduivy__Study_Term__c stm : stmList) {
			if (stm.reduivy__Sample_Record_Code__c.equals(ACADEMIC_TERM)) {
				stmMap.put(stm.reduivy__Sample_Record_Code__c, stm);
			}
		}

		// Get Study Pathway records
		Map<String, reduivy__Study_Pathway__c> spwMap = new Map<String, reduivy__Study_Pathway__c>();
		List<reduivy__Study_Pathway__c> spwList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Pathway__c
		];
		for (reduivy__Study_Pathway__c spw : spwList) {
			if (spw.reduivy__Sample_Record_Code__c.equals(STUDY_PATHWAY)) {
				spwMap.put(spw.reduivy__Sample_Record_Code__c, spw);
			}
		}

		// Verify pre-test conditions: no IPW records exist
		List<reduivy__Individual_Pathway__c> ipwList = [
			SELECT Id
			FROM reduivy__Individual_Pathway__c
		];
		System.Assert.isTrue(
			ipwList.isEmpty(),
			'There should not yet be any IPW records'
		);

		List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
		
		Test.startTest();

		// Execute test
		System.runAs(ADMIN_USER) {

			// Create individual program enrollment records
			List<String> enrollmentStatuses = IPE_Helper.getInProgressStatuses();

			for (Integer i = 0; i < studentCon.size(); i++) {
				String sampleRecordCode = 'IPE_CreatePathway_TEST-' + String.valueOf(i);
				Id contactId = studentCon[i].Id;
				Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
				Id studyPlanId = splMap.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = stmMap.get(ACADEMIC_TERM).Id;
				Id studyPathwayId = spwMap.get(STUDY_PATHWAY).Id;
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
		Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
			SELECT Id, reduivy__Study_Plan__c
			FROM reduivy__Individual_Program_Enrollment__c
			WHERE reduivy__Sample_Record_Code__c LIKE '%IPE_CreatePathway_TEST-%'
		]);
		System.Assert.isFalse(
			ipeList.isEmpty(),
			'There should be a list of IPE records'
		);
		ipwList = [
			SELECT 	Id, reduivy__Individual_Program_Enrollment__r.reduivy__Starting_Term__c,
					reduivy__Enrollment_Method__c, reduivy__Status__c,
					reduivy__Term_Number__c, reduivy__Academic_Term__c,
					reduivy__Recommended_Credits__c, reduivy__Max_Credits__c,
					reduivy__Individual_Program_Enrollment__c,
					reduivy__Description__c, reduivy__Sample_Record_Code__c
			FROM reduivy__Individual_Pathway__c
		];
		System.Assert.areEqual(
			4 * ipeList.size(),
			ipwList.size(),
			'There should be the expected number of IPW records'
		);
		Map<Id, Map<Integer, reduivy__Individual_Pathway__c>> ipwMap = new Map<Id, Map<Integer, reduivy__Individual_Pathway__c>>();
		for (reduivy__Individual_Pathway__c ipw : ipwList) {
			if (!ipwMap.containsKey(ipw.reduivy__Individual_Program_Enrollment__c)) {
				ipwMap.put(ipw.reduivy__Individual_Program_Enrollment__c, new Map<Integer, reduivy__Individual_Pathway__c>());
			}
			ipwMap.get(ipw.reduivy__Individual_Program_Enrollment__c).put(Integer.valueOf(ipw.reduivy__Term_Number__c), ipw);
		}
		for (reduivy__Individual_Pathway__c ipw : ipwList) {
			Integer termNumber = Integer.valueOf(ipw.reduivy__Term_Number__c);
			if (termNumber == 1) {
				System.Assert.areEqual(
					ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Starting_Term__c,
					ipwMap.get(ipw.reduivy__Individual_Program_Enrollment__c).get(termNumber).reduivy__Academic_Term__c,
					'The actual value should be as expected'
				);
			} else {
				System.Assert.isNull(
					ipwMap.get(ipw.reduivy__Individual_Program_Enrollment__c).get(termNumber).reduivy__Academic_Term__c,
					'The actual value should be as expected'
				);
			}
		}
	}

    /**
     * @description Test as admin that individual pathway records are created after an IPE record is updated
     */
	@IsTest
    static void testCreateIpwAfterIpeUpdateAsAdminUser() {

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
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c
		];
		for (reduivy__Study_Plan__c spl : splList) {
			splMap.put(spl.reduivy__Sample_Record_Code__c, spl);
		}

		// Get study term records
		Map<String, reduivy__Study_Term__c> stmMap = new Map<String, reduivy__Study_Term__c>();
		List<reduivy__Study_Term__c> stmList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Term__c
		];
		for (reduivy__Study_Term__c stm : stmList) {
			if (stm.reduivy__Sample_Record_Code__c.equals(ACADEMIC_TERM)) {
				stmMap.put(stm.reduivy__Sample_Record_Code__c, stm);
			}
		}

		Map<String, reduivy__Study_Pathway__c> spwMap = new Map<String, reduivy__Study_Pathway__c>();
		List<reduivy__Study_Pathway__c> spwList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Pathway__c
		];
		for (reduivy__Study_Pathway__c spw : spwList) {
			if (spw.reduivy__Sample_Record_Code__c.equals(STUDY_PATHWAY)) {
				spwMap.put(spw.reduivy__Sample_Record_Code__c, spw);
			}
		}

		List<reduivy__Individual_Pathway__c> ipwList = new List<reduivy__Individual_Pathway__c>();
		List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
		
		Test.startTest();

		// Execute test
		System.runAs(ADMIN_USER) {

			// Create individual program enrollment records
			List<String> ipeDraftStatuses = IPE_Helper.getDraftStatuses();

			for (Integer i = 0; i < studentCon.size(); i++) {
				String sampleRecordCode = 'IPE_CreatePathway_TEST-' + String.valueOf(i);
				Id contactId = studentCon[i].Id;
				Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
				Id studyPlanId = splMap.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = stmMap.get(ACADEMIC_TERM).Id;
				Id studyPathwayId = spwMap.get(STUDY_PATHWAY).Id;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = ipeDraftStatuses[0];
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

			// Verify pre conditions: no IPW records exist
			ipwList = [
				SELECT Id
				FROM reduivy__Individual_Pathway__c
			];
			System.Assert.isTrue(
				ipwList.isEmpty(),
				'There should not yet be any IPW records'
			);

			List<String> ipeInProgressStatuses = IPE_Helper.getInProgressStatuses();
			for(reduivy__Individual_Program_Enrollment__c ipe : ipeList){
				ipe.reduivy__Enrollment_Status__c = ipeInProgressStatuses[0];
			}
			
			update ipeList;
		}

		Test.stopTest();
	
		// Verify test results
		Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
			SELECT Id, reduivy__Study_Plan__c
			FROM reduivy__Individual_Program_Enrollment__c
			WHERE reduivy__Sample_Record_Code__c LIKE '%IPE_CreatePathway_TEST-%'
		]);
		System.Assert.isFalse(
			ipeList.isEmpty(),
			'There should be a list of IPE records'
		);
		ipwList = [
			SELECT 	Id, reduivy__Individual_Program_Enrollment__r.reduivy__Starting_Term__c,
					reduivy__Enrollment_Method__c, reduivy__Status__c,
					reduivy__Term_Number__c, reduivy__Academic_Term__c,
					reduivy__Recommended_Credits__c, reduivy__Max_Credits__c,
					reduivy__Individual_Program_Enrollment__c,
					reduivy__Description__c, reduivy__Sample_Record_Code__c
			FROM reduivy__Individual_Pathway__c
		];
		System.Assert.areEqual(
			4 * ipeList.size(),
			ipwList.size(),
			'There should be the expected number of IPW records'
		);
		Map<Id, Map<Integer, reduivy__Individual_Pathway__c>> ipwMap = new Map<Id, Map<Integer, reduivy__Individual_Pathway__c>>();
		for (reduivy__Individual_Pathway__c ipw : ipwList) {
			if (!ipwMap.containsKey(ipw.reduivy__Individual_Program_Enrollment__c)) {
				ipwMap.put(ipw.reduivy__Individual_Program_Enrollment__c, new Map<Integer, reduivy__Individual_Pathway__c>());
			}
			ipwMap.get(ipw.reduivy__Individual_Program_Enrollment__c).put(Integer.valueOf(ipw.reduivy__Term_Number__c), ipw);
		}
		for (reduivy__Individual_Pathway__c ipw : ipwList) {
			Integer termNumber = Integer.valueOf(ipw.reduivy__Term_Number__c);
			if (termNumber == 1) {
				System.Assert.areEqual(
					ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Starting_Term__c,
					ipwMap.get(ipw.reduivy__Individual_Program_Enrollment__c).get(termNumber).reduivy__Academic_Term__c,
					'The actual value should be as expected'
				);
			} else {
				System.Assert.isNull(
					ipwMap.get(ipw.reduivy__Individual_Program_Enrollment__c).get(termNumber).reduivy__Academic_Term__c,
					'The actual value should be as expected'
				);
			}
		}
	}

    /**
     * @description Test as admin that any existing individual pathway records are updated after an IPE record is updated
     */
	@IsTest
    static void testUpdateIpwAfterIpeUpdateAsAdminUser() {

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

		// Get study plan records
		Map<String, reduivy__Study_Plan__c> splMap = new Map<String, reduivy__Study_Plan__c>();
		List<reduivy__Study_Plan__c> splList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c
		];
		for (reduivy__Study_Plan__c spl : splList) {
			if (spl.reduivy__Sample_Record_Code__c.equals(STUDY_PLAN)) {
				splMap.put(spl.reduivy__Sample_Record_Code__c, spl);
			}
		}

		// Get study term records
		Map<String, reduivy__Study_Term__c> stmMap = new Map<String, reduivy__Study_Term__c>();
		List<reduivy__Study_Term__c> stmList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Term__c
		];
		for (reduivy__Study_Term__c stm : stmList) {
			if (stm.reduivy__Sample_Record_Code__c.equals(ACADEMIC_TERM)) {
				stmMap.put(stm.reduivy__Sample_Record_Code__c, stm);
			}
		}

		List<reduivy__Individual_Pathway__c> ipwList = new List<reduivy__Individual_Pathway__c>();
		Map<Id, Map<Decimal, reduivy__Individual_Pathway__c>> ipwCreateMap = new Map<Id, Map<Decimal, reduivy__Individual_Pathway__c>>();
		List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();

		Test.startTest();

		// Execute test
		System.runAs(ADMIN_USER) {
			// Add custom study pathway records
			String spwActiveStatus = SPW_Helper.STATUS_ACTIVE;
			Map<String, reduivy__Study_Pathway__c> spwMap = new Map<String, reduivy__Study_Pathway__c>();
			List<reduivy__Study_Pathway__c> spwList = [
				SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Pathway__c
			];
			for (reduivy__Study_Pathway__c spw : spwList) {
				if (spw.reduivy__Sample_Record_Code__c.equals(STUDY_PATHWAY)) {

					spwMap.put(spw.reduivy__Sample_Record_Code__c, spw);
					reduivy__Study_Pathway__c spwCustom = 
						REDU_TestData_UTIL.newStudyPathway(
							'BACBIS_CUSTOM',
							splMap.get(STUDY_PLAN).Id,
							'Bachelor of Business Custom Pathway',
							spwActiveStatus,
							false
						);

					spwMap.put(spwCustom.reduivy__Sample_Record_Code__c, spwCustom);
				}
			}
			upsert spwMap.values();

			// Add custom study pathway term records
			Map<String, reduivy__Study_Pathway_Term__c> sptCustomMap = new Map<String, reduivy__Study_Pathway_Term__c>();
			List<reduivy__Study_Pathway_Term__c> sptList = [
				SELECT Id, reduivy__Term_Number__c, reduivy__Sample_Record_Code__c
				FROM reduivy__Study_Pathway_Term__c
				WHERE reduivy__Study_Pathway__c = :spwMap.get(STUDY_PATHWAY).Id
			];
			for (reduivy__Study_Pathway_Term__c spt : sptList) {
				reduivy__Study_Pathway_Term__c sptCustom = new reduivy__Study_Pathway_Term__c();
				sptCustom.reduivy__Study_Pathway__c = spwMap.get('BACBIS_CUSTOM').Id;
				sptCustom.reduivy__Description__c = 'BACBIS_CUSTOM: Bachelor of Business Custom Pathway';
				sptCustom.reduivy__Term_Number__c = spt.reduivy__Term_Number__c;
				sptCustom.reduivy__Sample_Record_Code__c = 
					'BACBIS_CUSTOM_T' + String.valueOf(Integer.valueOf(spt.reduivy__Term_Number__c));
				sptCustomMap.put(sptCustom.reduivy__Sample_Record_Code__c, sptCustom);
			}
			insert sptCustomMap.values();
			
			// Create individual program enrollment records
			List<String> ipeInProgressStatuses = IPE_Helper.getInProgressStatuses();

			for (Integer i = 0; i < studentCon.size(); i++) {
				String sampleRecordCode = 'IPE_CreatePathway_TEST-' + String.valueOf(i);
				Id contactId = studentCon[i].Id;
				Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
				Id studyPlanId = splMap.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = stmMap.get(ACADEMIC_TERM).Id;
				Id studyPathwayId = spwMap.get(STUDY_PATHWAY).Id;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = ipeInProgressStatuses[0];
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
					ipe.reduivy__Study_Pathway_Mode__c = IPE_Helper.PATHWAYMODE_CUSTOM;
				ipeList.add(ipe);
			}
			
			insert ipeList;

			// Verify pre-test condition
			ipwList = [
				SELECT 	Id, reduivy__Individual_Program_Enrollment__c, reduivy__Term_Number__c,
				reduivy__Description__c, reduivy__Sample_Record_Code__c
				FROM reduivy__Individual_Pathway__c 
				WHERE reduivy__Individual_Program_Enrollment__c IN: ipeList
			];

			System.Assert.isFalse(
				ipwList.isEmpty(),
				'There should be an initial list of IPW records'
			);
			
			for (reduivy__Individual_Pathway__c ipw : ipwList) {
				if (!ipwCreateMap.containsKey(ipw.reduivy__Individual_Program_Enrollment__c)) {
					ipwCreateMap.put(ipw.reduivy__Individual_Program_Enrollment__c, new Map<Decimal, reduivy__Individual_Pathway__c>());
				}

				ipwCreateMap.get(ipw.reduivy__Individual_Program_Enrollment__c).put(ipw.reduivy__Term_Number__c, ipw);
			}

			List<reduivy__Individual_Program_Enrollment__c> ipeUpdateList = new List<reduivy__Individual_Program_Enrollment__c>();
			for(reduivy__Individual_Program_Enrollment__c ipe : ipeList){

				// Verify the current IPE pathway selection and update pathway for the test
				System.Assert.areEqual(
					'Custom',
					ipe.reduivy__Study_Pathway_Mode__c,
					'The current value should be as expected'
				);
				System.Assert.areEqual(
					'BACBIS_MajorA_DEFAULT',
					STUDY_PATHWAY,
					'The current value should be as expected'
				);
				System.Assert.areEqual(
					spwMap.get(STUDY_PATHWAY).Id,
					ipe.reduivy__Study_Pathway__c,
					'The current value should be as expected'
				);

				reduivy__Individual_Program_Enrollment__c ipeUpdate = new reduivy__Individual_Program_Enrollment__c();
				ipeUpdate.reduivy__Study_Pathway__c = spwMap.get('BACBIS_CUSTOM').Id;
				ipeUpdate.Id = ipe.Id;

				ipeUpdateList.add(ipeUpdate);
			}
			
			update ipeUpdateList;
		}

		Test.stopTest();
	
		// Verify test results
		Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
			SELECT Id, reduivy__Study_Plan__c, reduivy__Study_Pathway_Mode__c, reduivy__Study_Pathway__c
			FROM reduivy__Individual_Program_Enrollment__c
			WHERE Id IN: ipeList
		]);

		System.Assert.isFalse(
			ipeList.isEmpty(),
			'There should be a list of IPE records'
		);

		ipwList = [
			SELECT 	Id, reduivy__Individual_Program_Enrollment__r.reduivy__Starting_Term__c,
					reduivy__Enrollment_Method__c, reduivy__Status__c,
					reduivy__Term_Number__c, reduivy__Academic_Term__c,
					reduivy__Recommended_Credits__c, reduivy__Max_Credits__c,
					reduivy__Individual_Program_Enrollment__c,
					reduivy__Description__c, reduivy__Sample_Record_Code__c
			FROM reduivy__Individual_Pathway__c
			WHERE reduivy__Individual_Program_Enrollment__c IN: ipeList
		];

		System.Assert.areEqual(
			4 * ipeList.size(),
			ipwList.size(),
			'There should be the expected number of IPW records'
		);

		Map<Id, Map<Integer, reduivy__Individual_Pathway__c>> ipwUpdateMap = new Map<Id, Map<Integer, reduivy__Individual_Pathway__c>>();
		for (reduivy__Individual_Pathway__c ipw : ipwList) {
			if (!ipwUpdateMap.containsKey(ipw.reduivy__Individual_Program_Enrollment__c)) {
				ipwUpdateMap.put(ipw.reduivy__Individual_Program_Enrollment__c, new Map<Integer, reduivy__Individual_Pathway__c>());
			}
			ipwUpdateMap.get(ipw.reduivy__Individual_Program_Enrollment__c).put(Integer.valueOf(ipw.reduivy__Term_Number__c), ipw);
		}

		for (reduivy__Individual_Pathway__c ipw : ipwList) {
			Integer termNumber = Integer.valueOf(ipw.reduivy__Term_Number__c);
			System.Assert.areEqual(
				ipwCreateMap.get(ipw.reduivy__Individual_Program_Enrollment__c).get(termNumber).Id,
				ipwUpdateMap.get(ipw.reduivy__Individual_Program_Enrollment__c).get(termNumber).Id,
				'The actual value should be as expected'
			);

			if (termNumber == 1) {
				System.Assert.areEqual(
					ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Starting_Term__c,
					ipwUpdateMap.get(ipw.reduivy__Individual_Program_Enrollment__c).get(termNumber).reduivy__Academic_Term__c,
					'The actual value should be as expected'
				);
			} else {
				System.Assert.isNull(
					ipwUpdateMap.get(ipw.reduivy__Individual_Program_Enrollment__c).get(termNumber).reduivy__Academic_Term__c,
					'The actual value should be as expected'
				);
			}

			System.Assert.areNotEqual(
				ipwCreateMap.get(ipw.reduivy__Individual_Program_Enrollment__c).get(termNumber).reduivy__Description__c,
				ipwUpdateMap.get(ipw.reduivy__Individual_Program_Enrollment__c).get(termNumber).reduivy__Description__c,
				'The actual value should be as expected'
			);
		}
	}
}