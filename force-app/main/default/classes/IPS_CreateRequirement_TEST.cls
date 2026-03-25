/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Test
 * @description Test class for IPS_CreateRequirement_EXE
 * @changehistory
 * ISS-001618 19-10-2023 dblack - new class
 */
@IsTest
public inherited sharing class IPS_CreateRequirement_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

	static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';
    
    static final List<String> IPE_INPROGRESS_STATUSES = IPE_Helper.getInProgressStatuses();

	static final String STUDY_PLAN_STRUCTURE_GROUP = 'BACBIS_MajorA_GROUPA_1_2';
	static final String STUDY_PLAN_STRUCTURE_UNIT = 'BACBIS_MajorA_BUS201';
	static final String PRE_REQUIREMENT_ID = 'BUS102';

    /**
     * @description Initialise test data for each test
     */
	@TestSetup
    static void makeData() {
		
		// Create settings
		testFactory.setupDefaultSettings();

		User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
			Test.startTest();

        	testFactory.initMasterData(SPS_Helper.getApiName());
            testFactory.initOfferingData(SOF_Helper.getApiName());
			testFactory.initStudentData(USR_Helper.getApiName(), true);

            List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
            for (Contact student : testFactory.students.values()) {
				String sampleRecordCode = student.Id + '_' + testFactory.studyPlans.get(STUDY_PLAN).Id;
				Id contactId = student.Id;
				Id studyProgramId = testFactory.studyPrograms.get(STUDY_PROGRAM).Id;
				Id studyPlanId = testFactory.studyPlans.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = null;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = IPE_INPROGRESS_STATUSES.get(0);
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

			Test.stopTest();
		}
    }

    /**
     * @description Test as admin that individual plan unit requirements are created from the study plan unit requirements
     */
    @IsTest
    static void testCreateIurFromSprAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		// Get the study plan structure unit records
		Map<String, reduivy__Study_Plan_Structure__c> spsuMap = new Map<String, reduivy__Study_Plan_Structure__c>();
		List<reduivy__Study_Plan_Structure__c> spsuList = [
			SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Study_Unit__c
			FROM reduivy__Study_Plan_Structure__c 
			WHERE RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
			AND reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_UNIT
		];

		System.Assert.isFalse(
			spsuList.isEmpty(),
			'There should be a list of study plan structure unit records'
		);

		for (reduivy__Study_Plan_Structure__c spsu : spsuList) {
			spsuMap.put(spsu.reduivy__Sample_Record_Code__c, spsu);
		}

		// Create study plan structure unit requirement records
		List<reduivy__Study_Plan_Unit_Requirement__c> sprList = new List<reduivy__Study_Plan_Unit_Requirement__c>();
		for(String spsuSampleCode : spsuMap.keySet()){

			reduivy__Study_Plan_Structure__c spsu = spsuMap.get(spsuSampleCode);
			String sampleRecordCode = spsu.reduivy__Sample_Record_Code__c + PRE_REQUIREMENT_ID;
			Id studyPlanUnitId = spsu.Id;
			String reqID = PRE_REQUIREMENT_ID;
			Decimal credits = 7.0;

			reduivy__Study_Plan_Unit_Requirement__c spr = REDU_TestData_UTIL.newCreditsStudyPlanUnitRequirement(
				sampleRecordCode,
				studyPlanUnitId,
				reqID,
				credits
			);

			//update the requirement logic on sps
			spsu.reduivy__Requirement_Logic__c = reqID;
			
			sprList.add(spr);
		}

		System.runAs(ADMIN_USER) {
			update spsuMap.values();
			insert sprList;
		}
		
		// Setup test data
		// Prepare information for study unit enrollment - BUS101
        Id masterIPERecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId();
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        Map<Id, reduivy__Individual_Plan_Structure__c> ipePlanStructureGroupMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, reduivy__Individual_Program_Enrollment__c, reduivy__Sample_Record_Code__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
                                                        FROM reduivy__Individual_Plan_Structure__c 
                                                        WHERE reduivy__Individual_Program_Enrollment__r.RecordtypeId =: masterIPERecordTypeId AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = : STUDY_PLAN_STRUCTURE_GROUP AND RecordTypeId =: ispGroupRTID]){

            ipePlanStructureGroupMap.put(ips.reduivy__Individual_Program_Enrollment__c, ips);
        }
		
		System.Assert.isFalse(
			ipePlanStructureGroupMap.isEmpty(),
			'There should be a list of individual plan structure group records'
		);

		// Create individual plan structure unit
		List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
		for(Id ipeId : ipePlanStructureGroupMap.keySet()){
			
			String sampleRecordCode = ipePlanStructureGroupMap.get(ipeId).reduivy__Sample_Record_Code__c + STUDY_PLAN_STRUCTURE_UNIT;
			Id individualProgramEnrollmentId = ipeId;
			Id parentPlanStructureId = ipePlanStructureGroupMap.get(ipeId).Id;
			Id unitStudyPlanStructureId = spsuMap.get(STUDY_PLAN_STRUCTURE_UNIT).Id;
			Id individualPathwayId = null;
			String category = null;
			Decimal credits = null;
			Boolean isPrimary = false;
			String status = null;
			reduivy__Individual_Plan_Structure__c ipsu = REDU_TestData_UTIL.newIndividualUnitPlanStructure(
				sampleRecordCode,
				individualProgramEnrollmentId,
				parentPlanStructureId,
				unitStudyPlanStructureId,
				category,
				credits,
				isPrimary,
				status
			);

			ipsuList.add(ipsu);
		}

		// Execute test
		Test.startTest();

		System.runAs(ADMIN_USER) {		
			insert ipsuList;
		}

		for (reduivy__Individual_Plan_Structure__c unitSps : [SELECT Id, reduivy__Requirement_Logic__c,
			(
				SELECT Id, reduivy__Requirement_ID__c
				FROM reduivy__Individual_Plan_Unit_Requirements__r
			)
			FROM reduivy__Individual_Plan_Structure__c
			WHERE Id IN: ipsuList
		]) {
			System.Assert.areEqual(PRE_REQUIREMENT_ID, unitSps.reduivy__Requirement_Logic__c);
			System.Assert.areEqual(1, unitSps.reduivy__Individual_Plan_Unit_Requirements__r.size());

			for (reduivy__Individual_Plan_Unit_Requirement__c iur : unitSps.reduivy__Individual_Plan_Unit_Requirements__r) {
				System.Assert.areEqual(PRE_REQUIREMENT_ID, iur.reduivy__Requirement_ID__c);
			}
		}

		Test.stopTest();
		
	}

	/**
     * @description Test as admin that individual plan unit requirements are created from the study unit requirements
     */
    @IsTest
    static void testCreateIurFromSurAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		// Get the study plan structure unit records
		Map<String, reduivy__Study_Plan_Structure__c> spsuMap = new Map<String, reduivy__Study_Plan_Structure__c>();
		List<reduivy__Study_Plan_Structure__c> spsuList = [
			SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Study_Unit__c
			FROM reduivy__Study_Plan_Structure__c 
			WHERE RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
			AND reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_UNIT
		];

		System.Assert.isFalse(
			spsuList.isEmpty(),
			'There should be a list of study plan structure unit records'
		);

		Set<Id> sunIds = new Set<Id>();
		for (reduivy__Study_Plan_Structure__c spsu : spsuList) {
			spsuMap.put(spsu.reduivy__Sample_Record_Code__c, spsu);
			sunIds.add(spsu.reduivy__Study_Unit__c);
		}

		Map<Id, reduivy__Study_Unit__c> sunMap = new Map<Id, reduivy__Study_Unit__c>();
		for (reduivy__Study_Unit__c sun : [SELECT Id,
			reduivy__Requirement_Logic__c,
			(
				SELECT Id,
				reduivy__Requirement_ID__c,
				reduivy__Requirement_Type__c,
				reduivy__Required_Study_Unit__c,
				reduivy__Credits__c,
				reduivy__Other__c
				FROM reduivy__Study_Unit_Requirements__r
			)
			FROM reduivy__Study_Unit__c
			WHERE Id IN: sunIds
		]) {
			sunMap.put(sun.Id, sun);
		}
		
		// Setup test data
		// Prepare information for study unit enrollment - BUS101
        Id masterIPERecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId();
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        Map<Id, reduivy__Individual_Plan_Structure__c> ipePlanStructureGroupMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, reduivy__Individual_Program_Enrollment__c, reduivy__Sample_Record_Code__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
                                                        FROM reduivy__Individual_Plan_Structure__c 
                                                        WHERE reduivy__Individual_Program_Enrollment__r.RecordtypeId =: masterIPERecordTypeId AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = : STUDY_PLAN_STRUCTURE_GROUP AND RecordTypeId =: ispGroupRTID]){

            ipePlanStructureGroupMap.put(ips.reduivy__Individual_Program_Enrollment__c, ips);
        }
		
		System.Assert.isFalse(
			ipePlanStructureGroupMap.isEmpty(),
			'There should be a list of individual plan structure group records'
		);

		// Create individual plan structure unit
		List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
		for(Id ipeId : ipePlanStructureGroupMap.keySet()){
			
			String sampleRecordCode = ipePlanStructureGroupMap.get(ipeId).reduivy__Sample_Record_Code__c + STUDY_PLAN_STRUCTURE_UNIT;
			Id individualProgramEnrollmentId = ipeId;
			Id parentPlanStructureId = ipePlanStructureGroupMap.get(ipeId).Id;
			Id unitStudyPlanStructureId = spsuMap.get(STUDY_PLAN_STRUCTURE_UNIT).Id;
			Id individualPathwayId = null;
			String category = null;
			Decimal credits = null;
			Boolean isPrimary = false;
			String status = null;
			reduivy__Individual_Plan_Structure__c ipsu = REDU_TestData_UTIL.newIndividualUnitPlanStructure(
				sampleRecordCode,
				individualProgramEnrollmentId,
				parentPlanStructureId,
				unitStudyPlanStructureId,
				category,
				credits,
				isPrimary,
				status
			);

			ipsuList.add(ipsu);
		}

		// Execute test
		Test.startTest();

		System.runAs(ADMIN_USER) {		
			insert ipsuList;
		}

		for (reduivy__Individual_Plan_Structure__c unitSps : [SELECT Id, 
			reduivy__Requirement_Logic__c,
			reduivy__Target_Unit_Id__c,
			(
				SELECT Id,
				reduivy__Requirement_ID__c,
				reduivy__Requirement_Type__c,
				reduivy__Required_Study_Unit__c,
				reduivy__Credits__c,
				reduivy__Other__c
				FROM reduivy__Individual_Plan_Unit_Requirements__r
			)
			FROM reduivy__Individual_Plan_Structure__c
			WHERE Id IN: ipsuList
		]) {
			reduivy__Study_Unit__c sun = sunMap.get(unitSps.reduivy__Target_Unit_Id__c);

			System.Assert.areEqual(sun.reduivy__Requirement_Logic__c, unitSps.reduivy__Requirement_Logic__c);
			System.Assert.areEqual(sun.reduivy__Study_Unit_Requirements__r.size(), unitSps.reduivy__Individual_Plan_Unit_Requirements__r.size());

			for (reduivy__Individual_Plan_Unit_Requirement__c iur : unitSps.reduivy__Individual_Plan_Unit_Requirements__r) {
				Boolean foundMatch = false;

				for (reduivy__Study_Unit_Requirement__c sur : sun.reduivy__Study_Unit_Requirements__r) {
					if (iur.reduivy__Requirement_ID__c == sur.reduivy__Requirement_ID__c) {
						System.Assert.areEqual(sur.reduivy__Requirement_ID__c, iur.reduivy__Requirement_ID__c);
						System.Assert.areEqual(sur.reduivy__Requirement_Type__c, iur.reduivy__Requirement_Type__c);
						System.Assert.areEqual(sur.reduivy__Required_Study_Unit__c, iur.reduivy__Required_Study_Unit__c);
						System.Assert.areEqual(sur.reduivy__Credits__c, iur.reduivy__Credits__c);
						System.Assert.areEqual(sur.reduivy__Other__c, iur.reduivy__Other__c);

						foundMatch = true;
					}
				}

				System.Assert.isTrue(foundMatch, 'No sur that matches the Requirement ID found.');
				
			}
		}

		Test.stopTest();
		
	}

	/**
     * @description Test as faculty that individual plan unit requirements are created from the study plan unit requirements
     */
    @IsTest
    static void testCreateIurFromSprAsFacultyUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
		// Get the study plan structure unit records
		Map<String, reduivy__Study_Plan_Structure__c> spsuMap = new Map<String, reduivy__Study_Plan_Structure__c>();
		List<reduivy__Study_Plan_Structure__c> spsuList = [
			SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Study_Unit__c
			FROM reduivy__Study_Plan_Structure__c 
			WHERE RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
			AND reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_UNIT
		];

		System.Assert.isFalse(
			spsuList.isEmpty(),
			'There should be a list of study plan structure unit records'
		);

		for (reduivy__Study_Plan_Structure__c spsu : spsuList) {
			spsuMap.put(spsu.reduivy__Sample_Record_Code__c, spsu);
		}

		// Create study plan structure unit requirement records
		List<reduivy__Study_Plan_Unit_Requirement__c> sprList = new List<reduivy__Study_Plan_Unit_Requirement__c>();
		for(String spsuSampleCode : spsuMap.keySet()){

			reduivy__Study_Plan_Structure__c spsu = spsuMap.get(spsuSampleCode);
			String sampleRecordCode = spsu.reduivy__Sample_Record_Code__c + PRE_REQUIREMENT_ID;
			Id studyPlanUnitId = spsu.Id;
			String reqID = PRE_REQUIREMENT_ID;
			Decimal credits = 7.0;

			reduivy__Study_Plan_Unit_Requirement__c spr = REDU_TestData_UTIL.newCreditsStudyPlanUnitRequirement(
				sampleRecordCode,
				studyPlanUnitId,
				reqID,
				credits
			);

			//update the requirement logic on sps
			spsu.reduivy__Requirement_Logic__c = reqID;
			
			sprList.add(spr);
		}

		System.runAs(ADMIN_USER) {
			update spsuMap.values();
			insert sprList;
		}
		
		// Setup test data
		// Prepare information for study unit enrollment - BUS101
        Id masterIPERecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId();
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        Map<Id, reduivy__Individual_Plan_Structure__c> ipePlanStructureGroupMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, reduivy__Individual_Program_Enrollment__c, reduivy__Sample_Record_Code__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
                                                        FROM reduivy__Individual_Plan_Structure__c 
                                                        WHERE reduivy__Individual_Program_Enrollment__r.RecordtypeId =: masterIPERecordTypeId AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = : STUDY_PLAN_STRUCTURE_GROUP AND RecordTypeId =: ispGroupRTID]){

            ipePlanStructureGroupMap.put(ips.reduivy__Individual_Program_Enrollment__c, ips);
        }
		
		System.Assert.isFalse(
			ipePlanStructureGroupMap.isEmpty(),
			'There should be a list of individual plan structure group records'
		);

		// Create individual plan structure unit
		List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
		for(Id ipeId : ipePlanStructureGroupMap.keySet()){
			
			String sampleRecordCode = ipePlanStructureGroupMap.get(ipeId).reduivy__Sample_Record_Code__c + STUDY_PLAN_STRUCTURE_UNIT;
			Id individualProgramEnrollmentId = ipeId;
			Id parentPlanStructureId = ipePlanStructureGroupMap.get(ipeId).Id;
			Id unitStudyPlanStructureId = spsuMap.get(STUDY_PLAN_STRUCTURE_UNIT).Id;
			Id individualPathwayId = null;
			String category = null;
			Decimal credits = null;
			Boolean isPrimary = false;
			String status = null;
			reduivy__Individual_Plan_Structure__c ipsu = REDU_TestData_UTIL.newIndividualUnitPlanStructure(
				sampleRecordCode,
				individualProgramEnrollmentId,
				parentPlanStructureId,
				unitStudyPlanStructureId,
				category,
				credits,
				isPrimary,
				status
			);

			ipsuList.add(ipsu);
		}

		// Execute test
		Test.startTest();

		System.runAs(FACULTY_USER) {		
			insert ipsuList;
		}

		for (reduivy__Individual_Plan_Structure__c unitSps : [SELECT Id, reduivy__Requirement_Logic__c,
			(
				SELECT Id, reduivy__Requirement_ID__c
				FROM reduivy__Individual_Plan_Unit_Requirements__r
			)
			FROM reduivy__Individual_Plan_Structure__c
			WHERE Id IN: ipsuList
		]) {
			System.Assert.areEqual(PRE_REQUIREMENT_ID, unitSps.reduivy__Requirement_Logic__c);
			System.Assert.areEqual(1, unitSps.reduivy__Individual_Plan_Unit_Requirements__r.size());

			for (reduivy__Individual_Plan_Unit_Requirement__c iur : unitSps.reduivy__Individual_Plan_Unit_Requirements__r) {
				System.Assert.areEqual(PRE_REQUIREMENT_ID, iur.reduivy__Requirement_ID__c);
			}
		}

		Test.stopTest();
	}

	/**
     * @description Test as faculty that individual plan unit requirements are created from the study unit requirements
     */
    @IsTest
    static void testCreateIurFromSurAsFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
		// Get the study plan structure unit records
		Map<String, reduivy__Study_Plan_Structure__c> spsuMap = new Map<String, reduivy__Study_Plan_Structure__c>();
		List<reduivy__Study_Plan_Structure__c> spsuList = [
			SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Study_Unit__c
			FROM reduivy__Study_Plan_Structure__c 
			WHERE RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
			AND reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_UNIT
		];

		System.Assert.isFalse(
			spsuList.isEmpty(),
			'There should be a list of study plan structure unit records'
		);

		Set<Id> sunIds = new Set<Id>();
		for (reduivy__Study_Plan_Structure__c spsu : spsuList) {
			spsuMap.put(spsu.reduivy__Sample_Record_Code__c, spsu);
			sunIds.add(spsu.reduivy__Study_Unit__c);
		}

		Map<Id, reduivy__Study_Unit__c> sunMap = new Map<Id, reduivy__Study_Unit__c>();
		for (reduivy__Study_Unit__c sun : [SELECT Id,
			reduivy__Requirement_Logic__c,
			(
				SELECT Id,
				reduivy__Requirement_ID__c,
				reduivy__Requirement_Type__c,
				reduivy__Required_Study_Unit__c,
				reduivy__Credits__c,
				reduivy__Other__c
				FROM reduivy__Study_Unit_Requirements__r
			)
			FROM reduivy__Study_Unit__c
			WHERE Id IN: sunIds
		]) {
			sunMap.put(sun.Id, sun);
		}
		
		// Setup test data
		// Prepare information for study unit enrollment - BUS101
        Id masterIPERecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId();
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        Map<Id, reduivy__Individual_Plan_Structure__c> ipePlanStructureGroupMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, reduivy__Individual_Program_Enrollment__c, reduivy__Sample_Record_Code__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
                                                        FROM reduivy__Individual_Plan_Structure__c 
                                                        WHERE reduivy__Individual_Program_Enrollment__r.RecordtypeId =: masterIPERecordTypeId AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = : STUDY_PLAN_STRUCTURE_GROUP AND RecordTypeId =: ispGroupRTID]){

            ipePlanStructureGroupMap.put(ips.reduivy__Individual_Program_Enrollment__c, ips);
        }
		
		System.Assert.isFalse(
			ipePlanStructureGroupMap.isEmpty(),
			'There should be a list of individual plan structure group records'
		);

		// Create individual plan structure unit
		List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
		for(Id ipeId : ipePlanStructureGroupMap.keySet()){
			
			String sampleRecordCode = ipePlanStructureGroupMap.get(ipeId).reduivy__Sample_Record_Code__c + STUDY_PLAN_STRUCTURE_UNIT;
			Id individualProgramEnrollmentId = ipeId;
			Id parentPlanStructureId = ipePlanStructureGroupMap.get(ipeId).Id;
			Id unitStudyPlanStructureId = spsuMap.get(STUDY_PLAN_STRUCTURE_UNIT).Id;
			Id individualPathwayId = null;
			String category = null;
			Decimal credits = null;
			Boolean isPrimary = false;
			String status = null;
			reduivy__Individual_Plan_Structure__c ipsu = REDU_TestData_UTIL.newIndividualUnitPlanStructure(
				sampleRecordCode,
				individualProgramEnrollmentId,
				parentPlanStructureId,
				unitStudyPlanStructureId,
				category,
				credits,
				isPrimary,
				status
			);

			ipsuList.add(ipsu);
		}

		// Execute test
		Test.startTest();

		System.runAs(FACULTY_USER) {		
			insert ipsuList;
		}

		for (reduivy__Individual_Plan_Structure__c unitSps : [SELECT Id, 
			reduivy__Requirement_Logic__c,
			reduivy__Target_Unit_Id__c,
			(
				SELECT Id,
				reduivy__Requirement_ID__c,
				reduivy__Requirement_Type__c,
				reduivy__Required_Study_Unit__c,
				reduivy__Credits__c,
				reduivy__Other__c
				FROM reduivy__Individual_Plan_Unit_Requirements__r
			)
			FROM reduivy__Individual_Plan_Structure__c
			WHERE Id IN: ipsuList
		]) {
			reduivy__Study_Unit__c sun = sunMap.get(unitSps.reduivy__Target_Unit_Id__c);

			System.Assert.areEqual(sun.reduivy__Requirement_Logic__c, unitSps.reduivy__Requirement_Logic__c);
			System.Assert.areEqual(sun.reduivy__Study_Unit_Requirements__r.size(), unitSps.reduivy__Individual_Plan_Unit_Requirements__r.size());

			for (reduivy__Individual_Plan_Unit_Requirement__c iur : unitSps.reduivy__Individual_Plan_Unit_Requirements__r) {
				Boolean foundMatch = false;

				for (reduivy__Study_Unit_Requirement__c sur : sun.reduivy__Study_Unit_Requirements__r) {
					if (iur.reduivy__Requirement_ID__c == sur.reduivy__Requirement_ID__c) {
						System.Assert.areEqual(sur.reduivy__Requirement_ID__c, iur.reduivy__Requirement_ID__c);
						System.Assert.areEqual(sur.reduivy__Requirement_Type__c, iur.reduivy__Requirement_Type__c);
						System.Assert.areEqual(sur.reduivy__Required_Study_Unit__c, iur.reduivy__Required_Study_Unit__c);
						System.Assert.areEqual(sur.reduivy__Credits__c, iur.reduivy__Credits__c);
						System.Assert.areEqual(sur.reduivy__Other__c, iur.reduivy__Other__c);

						foundMatch = true;
					}
				}

				System.Assert.isTrue(foundMatch, 'No sur that matches the Requirement ID found.');
				
			}
		}

		Test.stopTest();
	}

	/**
     * @description Test as student that individual plan unit requirements are created from the study plan unit requirements
     */
    @IsTest
    static void testCreateIurFromSprAsStudentUser() {
		
		User ADMIN_USER = testFactory.getReduAdminUser();

		// Get the study plan structure unit records
		Map<String, reduivy__Study_Plan_Structure__c> spsuMap = new Map<String, reduivy__Study_Plan_Structure__c>();
		List<reduivy__Study_Plan_Structure__c> spsuList = [
			SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Study_Unit__c
			FROM reduivy__Study_Plan_Structure__c 
			WHERE RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
			AND reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_UNIT
		];

		System.Assert.isFalse(
			spsuList.isEmpty(),
			'There should be a list of study plan structure unit records'
		);

		for (reduivy__Study_Plan_Structure__c spsu : spsuList) {
			spsuMap.put(spsu.reduivy__Sample_Record_Code__c, spsu);
		}

		// Create study plan structure unit requirement records
		List<reduivy__Study_Plan_Unit_Requirement__c> sprList = new List<reduivy__Study_Plan_Unit_Requirement__c>();
		for(String spsuSampleCode : spsuMap.keySet()){

			reduivy__Study_Plan_Structure__c spsu = spsuMap.get(spsuSampleCode);
			String sampleRecordCode = spsu.reduivy__Sample_Record_Code__c + PRE_REQUIREMENT_ID;
			Id studyPlanUnitId = spsu.Id;
			String reqID = PRE_REQUIREMENT_ID;
			Decimal credits = 7.0;

			reduivy__Study_Plan_Unit_Requirement__c spr = REDU_TestData_UTIL.newCreditsStudyPlanUnitRequirement(
				sampleRecordCode,
				studyPlanUnitId,
				reqID,
				credits
			);

			//update the requirement logic on sps
			spsu.reduivy__Requirement_Logic__c = reqID;
			
			sprList.add(spr);
		}

		System.runAs(ADMIN_USER) {
			update spsuMap.values();
			insert sprList;
		}

		reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

		// Setup test data
		// Prepare information for study unit enrollment - BUS101
        Id masterIPERecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId();
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        Map<Id, reduivy__Individual_Plan_Structure__c> ipePlanStructureGroupMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, reduivy__Individual_Program_Enrollment__c, reduivy__Sample_Record_Code__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
                                                        FROM reduivy__Individual_Plan_Structure__c 
                                                        WHERE reduivy__Individual_Program_Enrollment__r.Id =: masterIPE.Id AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = : STUDY_PLAN_STRUCTURE_GROUP AND RecordTypeId =: ispGroupRTID]){

            ipePlanStructureGroupMap.put(ips.reduivy__Individual_Program_Enrollment__c, ips);
        }

		System.Assert.isFalse(
			ipePlanStructureGroupMap.isEmpty(),
			'There should be a list of individual plan structure group records'
		);

		// Create individual plan structure unit
		List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
		for(Id ipeId : ipePlanStructureGroupMap.keySet()){
			
			String sampleRecordCode = ipePlanStructureGroupMap.get(ipeId).reduivy__Sample_Record_Code__c + STUDY_PLAN_STRUCTURE_UNIT;
			Id individualProgramEnrollmentId = ipeId;
			Id parentPlanStructureId = ipePlanStructureGroupMap.get(ipeId).Id;
			Id unitStudyPlanStructureId = spsuMap.get(STUDY_PLAN_STRUCTURE_UNIT).Id;
			Id individualPathwayId = null;
			String category = null;
			Decimal credits = null;
			Boolean isPrimary = false;
			String status = null;
			reduivy__Individual_Plan_Structure__c ipsu = REDU_TestData_UTIL.newIndividualUnitPlanStructure(
				sampleRecordCode,
				individualProgramEnrollmentId,
				parentPlanStructureId,
				unitStudyPlanStructureId,
				category,
				credits,
				isPrimary,
				status
			);

			ipsuList.add(ipsu);
		}

		// Execute test
		Test.startTest();

		System.runAs(studentUser) {		
			insert ipsuList;
		}

		for (reduivy__Individual_Plan_Structure__c unitSps : [SELECT Id, reduivy__Requirement_Logic__c,
			(
				SELECT Id, reduivy__Requirement_ID__c
				FROM reduivy__Individual_Plan_Unit_Requirements__r
			)
			FROM reduivy__Individual_Plan_Structure__c
			WHERE Id IN: ipsuList
		]) {
			System.Assert.areEqual(PRE_REQUIREMENT_ID, unitSps.reduivy__Requirement_Logic__c);
			System.Assert.areEqual(1, unitSps.reduivy__Individual_Plan_Unit_Requirements__r.size());

			for (reduivy__Individual_Plan_Unit_Requirement__c iur : unitSps.reduivy__Individual_Plan_Unit_Requirements__r) {
				System.Assert.areEqual(PRE_REQUIREMENT_ID, iur.reduivy__Requirement_ID__c);
			}
		}

		Test.stopTest();
	}

	/**
     * @description Test as student that individual plan unit requirements are created from the study unit requirements
     */
    @IsTest
    static void testCreateIurFromSurAsStudentUser() {

		// Get the study plan structure unit records
		Map<String, reduivy__Study_Plan_Structure__c> spsuMap = new Map<String, reduivy__Study_Plan_Structure__c>();
		List<reduivy__Study_Plan_Structure__c> spsuList = [
			SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Study_Unit__c
			FROM reduivy__Study_Plan_Structure__c 
			WHERE RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
			AND reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_UNIT
		];

		System.Assert.isFalse(
			spsuList.isEmpty(),
			'There should be a list of study plan structure unit records'
		);

		Set<Id> sunIds = new Set<Id>();
		for (reduivy__Study_Plan_Structure__c spsu : spsuList) {
			spsuMap.put(spsu.reduivy__Sample_Record_Code__c, spsu);
			sunIds.add(spsu.reduivy__Study_Unit__c);
		}

		Map<Id, reduivy__Study_Unit__c> sunMap = new Map<Id, reduivy__Study_Unit__c>();
		for (reduivy__Study_Unit__c sun : [SELECT Id,
			reduivy__Requirement_Logic__c,
			(
				SELECT Id,
				reduivy__Requirement_ID__c,
				reduivy__Requirement_Type__c,
				reduivy__Required_Study_Unit__c,
				reduivy__Credits__c,
				reduivy__Other__c
				FROM reduivy__Study_Unit_Requirements__r
			)
			FROM reduivy__Study_Unit__c
			WHERE Id IN: sunIds
		]) {
			sunMap.put(sun.Id, sun);
		}

		reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

		// Setup test data
		// Prepare information for study unit enrollment - BUS101
        Id masterIPERecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId();
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        Map<Id, reduivy__Individual_Plan_Structure__c> ipePlanStructureGroupMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, reduivy__Individual_Program_Enrollment__c, reduivy__Sample_Record_Code__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
                                                        FROM reduivy__Individual_Plan_Structure__c 
                                                        WHERE reduivy__Individual_Program_Enrollment__r.Id =: masterIPE.Id AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = : STUDY_PLAN_STRUCTURE_GROUP AND RecordTypeId =: ispGroupRTID]){

            ipePlanStructureGroupMap.put(ips.reduivy__Individual_Program_Enrollment__c, ips);
        }
		System.Assert.isFalse(
			ipePlanStructureGroupMap.isEmpty(),
			'There should be a list of individual plan structure group records'
		);

		// Create individual plan structure unit
		List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
		for(Id ipeId : ipePlanStructureGroupMap.keySet()){
			
			String sampleRecordCode = ipePlanStructureGroupMap.get(ipeId).reduivy__Sample_Record_Code__c + STUDY_PLAN_STRUCTURE_UNIT;
			Id individualProgramEnrollmentId = ipeId;
			Id parentPlanStructureId = ipePlanStructureGroupMap.get(ipeId).Id;
			Id unitStudyPlanStructureId = spsuMap.get(STUDY_PLAN_STRUCTURE_UNIT).Id;
			Id individualPathwayId = null;
			String category = null;
			Decimal credits = null;
			Boolean isPrimary = false;
			String status = null;
			reduivy__Individual_Plan_Structure__c ipsu = REDU_TestData_UTIL.newIndividualUnitPlanStructure(
				sampleRecordCode,
				individualProgramEnrollmentId,
				parentPlanStructureId,
				unitStudyPlanStructureId,
				category,
				credits,
				isPrimary,
				status
			);
			ipsuList.add(ipsu);
		}

		// Execute test
		Test.startTest();

		System.runAs(studentUser) {		
			insert ipsuList;
		}

		for (reduivy__Individual_Plan_Structure__c unitSps : [SELECT Id, 
			reduivy__Requirement_Logic__c,
			reduivy__Target_Unit_Id__c,
			(
				SELECT Id,
				reduivy__Requirement_ID__c,
				reduivy__Requirement_Type__c,
				reduivy__Required_Study_Unit__c,
				reduivy__Credits__c,
				reduivy__Other__c
				FROM reduivy__Individual_Plan_Unit_Requirements__r
			)
			FROM reduivy__Individual_Plan_Structure__c
			WHERE Id IN: ipsuList
		]) {
			reduivy__Study_Unit__c sun = sunMap.get(unitSps.reduivy__Target_Unit_Id__c);

			System.Assert.areEqual(sun.reduivy__Requirement_Logic__c, unitSps.reduivy__Requirement_Logic__c);
			System.Assert.areEqual(sun.reduivy__Study_Unit_Requirements__r.size(), unitSps.reduivy__Individual_Plan_Unit_Requirements__r.size());

			for (reduivy__Individual_Plan_Unit_Requirement__c iur : unitSps.reduivy__Individual_Plan_Unit_Requirements__r) {
				Boolean foundMatch = false;

				for (reduivy__Study_Unit_Requirement__c sur : sun.reduivy__Study_Unit_Requirements__r) {
					if (iur.reduivy__Requirement_ID__c == sur.reduivy__Requirement_ID__c) {
						System.Assert.areEqual(sur.reduivy__Requirement_ID__c, iur.reduivy__Requirement_ID__c);
						System.Assert.areEqual(sur.reduivy__Requirement_Type__c, iur.reduivy__Requirement_Type__c);
						System.Assert.areEqual(sur.reduivy__Required_Study_Unit__c, iur.reduivy__Required_Study_Unit__c);
						System.Assert.areEqual(sur.reduivy__Credits__c, iur.reduivy__Credits__c);
						System.Assert.areEqual(sur.reduivy__Other__c, iur.reduivy__Other__c);

						foundMatch = true;
					}
				}

				System.Assert.isTrue(foundMatch, 'No sur that matches the Requirement ID found.');
				
			}
		}

		Test.stopTest();
	}
}