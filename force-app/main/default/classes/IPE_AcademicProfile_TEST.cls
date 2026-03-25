/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for IPE_AcademicProfile_EXE
 * @changehistory
 * ISS-001816 19-12-2023 Lean - new class
 */
@IsTest
public inherited sharing class IPE_AcademicProfile_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);

	static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';

	static final String ACADEMIC_PROFILE_NAME_FORMAT_SYNTAX = 'Academic Profile - {0} ({1})'; //e.g., Academic Profile - John Doe (Degree Honours)
    /**
     * @description Initialise test data for each test
     */
	@TestSetup
    static void makeData() {

		testFactory.setupDefaultSettings();

		User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {

			Test.startTest();

			testFactory.initMasterData(SPL_Helper.getApiName());
			testFactory.initStudentData(IAC_Helper.getApiName(), true);

			Test.stopTest();
		}

    }

    /**
     * @description Test academic profile creation with generation type = By IPE as admin
     */
    @IsTest
    static void testAcademicProfileByIpeWithNewIpeAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		reduivy__RIO_Education_Ivy_Settings__c settings = REDU_AppSetting_UTIL.getOrgDefaultSetting();
		settings.reduivy__Academic_Profile_Generation_Type__c = IPF_Helper.PROFILE_GEN_TYPE_BYIPE;

		update settings;

		List<Contact> studentContacts = [SELECT Id, 
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

		List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
		Test.startTest();

		// Execute test
		System.runAs(ADMIN_USER) {

			// Create individual program enrollment records			
			for (Contact student : studentContacts) {
				String sampleRecordCode = student.Id + '_' + splMap.get(STUDY_PLAN).Id;
				Id contactId = student.Id;
				Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
				Id studyPlanId = splMap.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = null;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = IPE_INPROGRESS_STATUS;
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
			SELECT Id,
			Name,
			reduivy__Contact__c,
			reduivy__Contact_Name__c,
			reduivy__Study_Program_Academic_Level__c,
            reduivy__Individual_Academic_Profile__c,
			reduivy__Individual_Academic_Profile__r.Name,
			reduivy__Individual_Academic_Profile__r.reduivy__Contact__c
			FROM reduivy__Individual_Program_Enrollment__c
		]);

		System.Assert.isFalse(ipeMap.isEmpty(), 'There should be a list of IPE records');

        Map<Id, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<Id, reduivy__Individual_Academic_Profile__c>([
			SELECT Id,
            Name,
			reduivy__Contact__c,
			reduivy__Contact__r.Name,
			reduivy__Academic_Level__c
			FROM reduivy__Individual_Academic_Profile__c
		]);

		System.Assert.isFalse(ipeMap.isEmpty(), 'There should be a list of IPE records');
        System.Assert.isFalse(ipfMap.isEmpty(), 'There should be a list of IPF records');
        System.Assert.areEqual(ipfMap.size(), ipeMap.size(), 'The number of records should be equal.');

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {
            System.Assert.areEqual(true, String.isNotBlank(ipe.reduivy__Individual_Academic_Profile__c));
			System.Assert.areEqual(ipe.reduivy__Contact__c, ipe.reduivy__Individual_Academic_Profile__r.reduivy__Contact__c);

			String recName = String.format(ACADEMIC_PROFILE_NAME_FORMAT_SYNTAX, new List<String>{ipe.reduivy__Contact_Name__c, ipe.reduivy__Study_Program_Academic_Level__c});

			System.Assert.areEqual(recName, ipe.reduivy__Individual_Academic_Profile__r.Name);
        }

	}

	/**
     * @description Test academic profile recreation with generation type = By IPE as admin
     */
    @IsTest
    static void testAcademicProfileByIpeWithExistingIpeAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		reduivy__RIO_Education_Ivy_Settings__c settings = REDU_AppSetting_UTIL.getOrgDefaultSetting();
		settings.reduivy__Academic_Profile_Generation_Type__c = IPF_Helper.PROFILE_GEN_TYPE_BYIPE;

		update settings;

		List<Contact> studentContacts = [SELECT Id, 
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

		List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
		Test.startTest();

		// Execute test
		System.runAs(ADMIN_USER) {

			// Create individual program enrollment records			
			for (Contact student : studentContacts) {
				String sampleRecordCode = student.Id + '_' + splMap.get(STUDY_PLAN).Id;
				Id contactId = student.Id;
				Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
				Id studyPlanId = splMap.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = null;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = IPE_INPROGRESS_STATUS;
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
			SELECT Id,
            reduivy__Individual_Academic_Profile__c
			FROM reduivy__Individual_Program_Enrollment__c
		]);

		System.Assert.isFalse(ipeMap.isEmpty(), 'There should be a list of IPE records');

        Map<Id, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<Id, reduivy__Individual_Academic_Profile__c>([
			SELECT Id,
            Name,
			reduivy__Contact__c
			FROM reduivy__Individual_Academic_Profile__c
		]);

		System.Assert.isFalse(ipeMap.isEmpty(), 'There should be a list of IPE records');
        System.Assert.isFalse(ipfMap.isEmpty(), 'There should be a list of IPF records');
        System.Assert.areEqual(ipfMap.size(), ipeMap.size(), 'The number of records should be equal.');

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {
            System.Assert.areEqual(true, String.isNotBlank(ipe.reduivy__Individual_Academic_Profile__c));
        }

		// Unset the reduivy__Individual_Academic_Profile__c
		System.runAs(ADMIN_USER) {
			for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {
				ipe.reduivy__Individual_Academic_Profile__c = null;
			}

			update ipeMap.values();
		}

		ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
			SELECT Id,
            Name,
			reduivy__Contact__c,
			reduivy__Contact_Name__c,
			reduivy__Study_Program_Academic_Level__c,
            reduivy__Individual_Academic_Profile__c,
			reduivy__Individual_Academic_Profile__r.Name,
			reduivy__Individual_Academic_Profile__r.reduivy__Contact__c
			FROM reduivy__Individual_Program_Enrollment__c
		]);

		ipfMap = new Map<Id, reduivy__Individual_Academic_Profile__c>([
			SELECT Id,
            Name,
			reduivy__Contact__c,
			reduivy__Contact__r.Name,
			reduivy__Academic_Level__c
			FROM reduivy__Individual_Academic_Profile__c
		]);

		// The reduivy__Individual_Academic_Profile__c should be null
		for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {
            System.Assert.areEqual(true, String.isNotBlank(ipe.reduivy__Individual_Academic_Profile__c));
			System.Assert.areEqual(ipe.reduivy__Contact__c, ipe.reduivy__Individual_Academic_Profile__r.reduivy__Contact__c);

			String recName = String.format(ACADEMIC_PROFILE_NAME_FORMAT_SYNTAX, new List<String>{ipe.reduivy__Contact_Name__c, ipe.reduivy__Study_Program_Academic_Level__c});

			System.Assert.areEqual(recName, ipe.reduivy__Individual_Academic_Profile__r.Name);
        }

		System.Assert.areEqual(ipfMap.size(), ipeMap.size() * 2, 'The number of records should be double.');
	}

	/**
     * @description Test academic profile creation with generation type = By Identifier as admin
     */
    @IsTest
    static void testAcademicProfileByIdentifierWithNewIpeAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		reduivy__RIO_Education_Ivy_Settings__c settings = REDU_AppSetting_UTIL.getOrgDefaultSetting();
		settings.reduivy__Academic_Profile_Generation_Type__c = IPF_Helper.PROFILE_GEN_TYPE_BYIDENTIFIERMAPPING;

		update settings;

		List<Contact> studentContacts = [SELECT Id, 
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

		List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
		Test.startTest();

		// Execute test
		System.runAs(ADMIN_USER) {

			// Create individual program enrollment records
			for (Integer a = 0; a < 2; a ++) {			
				for (Contact student : studentContacts) {
					String sampleRecordCode = student.Id + '_' + splMap.get(STUDY_PLAN).Id + '_' + a;
					Id contactId = student.Id;
					Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
					Id studyPlanId = splMap.get(STUDY_PLAN).Id;
					Id studyIntakeId = null;
					Id startingTermId = null;
					Id studyPathwayId = null;
					Id defaultCampusId = null;
					String classYear = null;
					String classStanding = null;
					Boolean eligibleToEnroll = true;
					String enrollmentStatus = IPE_INPROGRESS_STATUS;
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
			}
			
			insert ipeList;
		}
	
		Test.stopTest();

		// Verify test results
		Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
			SELECT Id,
			reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__c
			FROM reduivy__Individual_Program_Enrollment__c
		]);

		System.Assert.isFalse(ipeMap.isEmpty(), 'There should be a list of IPE records');

        Map<Id, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<Id, reduivy__Individual_Academic_Profile__c>([
			SELECT Id,
            Name,
			reduivy__Contact__c,
			reduivy__Contact__r.Name,
			reduivy__Academic_Level__c
			FROM reduivy__Individual_Academic_Profile__c
		]);

		System.Assert.isFalse(ipeMap.isEmpty(), 'There should be a list of IPE records');
        System.Assert.isFalse(ipfMap.isEmpty(), 'There should be a list of IPF records');
        System.Assert.areEqual(ipfMap.size(), ipeMap.size() / 2, 'The number of records should be half.');

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {
            System.Assert.areEqual(true, String.isNotBlank(ipe.reduivy__Individual_Academic_Profile__c));
			System.Assert.areEqual(ipfMap.get(ipe.reduivy__Individual_Academic_Profile__c).reduivy__Contact__c, ipe.reduivy__Contact__c);
        }

		for (reduivy__Individual_Academic_Profile__c ipf : ipfMap.values()) {
			String recName = String.format(ACADEMIC_PROFILE_NAME_FORMAT_SYNTAX, new List<String>{ipf.reduivy__Contact__r.Name, ipf.reduivy__Academic_Level__c});

			System.Assert.areEqual(recName, ipf.Name);
		}
	}

	/**
     * @description Test academic profile reassociation with generation type = By Identifier as admin
     */
    @IsTest
    static void testAcademicProfileByIdentifierWithExistingIpeAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		reduivy__RIO_Education_Ivy_Settings__c settings = REDU_AppSetting_UTIL.getOrgDefaultSetting();
		settings.reduivy__Academic_Profile_Generation_Type__c = IPF_Helper.PROFILE_GEN_TYPE_BYIDENTIFIERMAPPING;

		update settings;

		List<Contact> studentContacts = [SELECT Id, 
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

		List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
		Test.startTest();

		// Execute test
		System.runAs(ADMIN_USER) {

			// Create individual program enrollment records
			for (Integer a = 0; a < 2; a ++) {			
				for (Contact student : studentContacts) {
					String sampleRecordCode = student.Id + '_' + splMap.get(STUDY_PLAN).Id + '_' + a;
					Id contactId = student.Id;
					Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
					Id studyPlanId = splMap.get(STUDY_PLAN).Id;
					Id studyIntakeId = null;
					Id startingTermId = null;
					Id studyPathwayId = null;
					Id defaultCampusId = null;
					String classYear = null;
					String classStanding = null;
					Boolean eligibleToEnroll = true;
					String enrollmentStatus = IPE_INPROGRESS_STATUS;
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
			}
			
			insert ipeList;
		}
	
		Test.stopTest();

		// Verify test results
		Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
			SELECT Id,
			reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__c
			FROM reduivy__Individual_Program_Enrollment__c
		]);

		System.Assert.isFalse(ipeMap.isEmpty(), 'There should be a list of IPE records');

        Map<Id, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<Id, reduivy__Individual_Academic_Profile__c>([
			SELECT Id,
            Name,
			reduivy__Contact__c,
			reduivy__Contact__r.Name,
			reduivy__Academic_Level__c
			FROM reduivy__Individual_Academic_Profile__c
		]);

		System.Assert.isFalse(ipeMap.isEmpty(), 'There should be a list of IPE records');
        System.Assert.isFalse(ipfMap.isEmpty(), 'There should be a list of IPF records');
        System.Assert.areEqual(ipfMap.size(), ipeMap.size() / 2, 'The number of records should be half.');

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {
            System.Assert.areEqual(true, String.isNotBlank(ipe.reduivy__Individual_Academic_Profile__c));
			System.Assert.areEqual(ipfMap.get(ipe.reduivy__Individual_Academic_Profile__c).reduivy__Contact__c, ipe.reduivy__Contact__c);
        }

		for (reduivy__Individual_Academic_Profile__c ipf : ipfMap.values()) {
			String recName = String.format(ACADEMIC_PROFILE_NAME_FORMAT_SYNTAX, new List<String>{ipf.reduivy__Contact__r.Name, ipf.reduivy__Academic_Level__c});

			System.Assert.areEqual(recName, ipf.Name);
		}

		// Unset the reduivy__Individual_Academic_Profile__c
		System.runAs(ADMIN_USER) {
			for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {
				ipe.reduivy__Individual_Academic_Profile__c = null;
			}

			update ipeMap.values();
		}

		ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
			SELECT Id,
            reduivy__Individual_Academic_Profile__c,
			reduivy__Contact__c
			FROM reduivy__Individual_Program_Enrollment__c
		]);

		ipfMap = new Map<Id, reduivy__Individual_Academic_Profile__c>([
			SELECT Id,
            Name,
			reduivy__Contact__c
			FROM reduivy__Individual_Academic_Profile__c
		]);

		// The reduivy__Individual_Academic_Profile__c should be null
		for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {
            System.Assert.areEqual(true, String.isNotBlank(ipe.reduivy__Individual_Academic_Profile__c));
			System.Assert.areEqual(ipfMap.get(ipe.reduivy__Individual_Academic_Profile__c).reduivy__Contact__c, ipe.reduivy__Contact__c);
        }

		System.Assert.areEqual(ipfMap.size(), ipeMap.size() / 2, 'The number of records should be half.');
	}
}