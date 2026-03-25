/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for IPF_PrimaryProfile_EXE
 * @changehistory
 * ISS-001816 19-12-2023 Lean - new class
 */
@IsTest
public inherited sharing class IPF_PrimaryProfile_TEST {
    
	/**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);

	static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';

	static final String ACADEMIC_PROFILE_NAME_FORMAT_SYNTAX = 'Academic Profile - {0}';

    /**
     * @description Initialise test data for each test
     */
	@TestSetup
    static void makeData() {

		testFactory.setupDefaultSettings();

		User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
			Test.startTest();

			testFactory.initMasterData(SPS_Helper.getApiName());
			testFactory.initStudentData(CON_Helper.getApiName(), false);

			Test.stopTest();
		}

    }

    /**
     * @description Test unique primary academic profile creation with generation type = By IPE as admin
     */
    @IsTest
    static void testNewUniquePrimaryIpfAsAdminUser() {

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

		Integer primaryIpfCount = 0;
        Integer totalIpf = 0;
		for (reduivy__Individual_Academic_Profile__c ipf : [
			SELECT Id,
            Name,
			reduivy__Contact__c,
            reduivy__Primary__c
			FROM reduivy__Individual_Academic_Profile__c
		]) {
			if (ipf.reduivy__Primary__c) {
                primaryIpfCount ++;
            }

            totalIpf ++;
		}

        System.Assert.areNotEqual(0, totalIpf);
        System.Assert.areNotEqual(0, primaryIpfCount);
        System.Assert.areEqual(primaryIpfCount, totalIpf, 'The primary IPF should be equal to total IPF created.');
	}

    /**
     * @description Test duplicate primary academic profile creation with generation type = By IPE as admin
     */
    @IsTest
    static void testNewDuplicatePrimaryIpfAsAdminUser() {

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

			// Create duplicate individual program enrollment records for each students to simulate duplicate primary individual academic profile
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

        Integer primaryIpfCount = 0;
        Integer totalIpf = 0;
		for (reduivy__Individual_Academic_Profile__c ipf : [
			SELECT Id,
            Name,
			reduivy__Contact__c,
            reduivy__Primary__c
			FROM reduivy__Individual_Academic_Profile__c
		]) {
			if (ipf.reduivy__Primary__c) {
                primaryIpfCount ++;
            }

            totalIpf ++;
		}

        System.Assert.areNotEqual(0, totalIpf);
        System.Assert.areNotEqual(0, primaryIpfCount);
        System.Assert.areEqual(primaryIpfCount, totalIpf / 2, 'The primary IPF should be half of total IPF created.');
	}
	
    /**
     * @description Test new primary academic profile with generation type = By IPE as admin
     */
    @IsTest
    static void testNewPrimaryIpfAsAdminUser() {

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

		Integer primaryIpfCount = 0;
        Integer totalIpf = 0;
		for (reduivy__Individual_Academic_Profile__c ipf : [
			SELECT Id,
            Name,
			reduivy__Contact__c,
            reduivy__Primary__c
			FROM reduivy__Individual_Academic_Profile__c
		]) {
			if (ipf.reduivy__Primary__c) {
                primaryIpfCount ++;
            }

            totalIpf ++;
		}

        System.Assert.areNotEqual(0, totalIpf);
        System.Assert.areNotEqual(0, primaryIpfCount);
        System.Assert.areEqual(primaryIpfCount, totalIpf, 'The primary IPF should be equal to total IPF created.');

        // simulate a new primary individual academic profiel for each students
        List<reduivy__Individual_Academic_Profile__c> newPrimaryProfiles = new List<reduivy__Individual_Academic_Profile__c>();

        System.runAs(ADMIN_USER) {

            for (Contact student : studentContacts) {
                newPrimaryProfiles.add(
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.Id + '_NewPrimary',
                        student.Id,
                        student.Id + '_NewPrimary',
                        IPF_Helper.STATUS_ACTIVE,
                        true
                    )
                );
            }

            insert newPrimaryProfiles;
        }

        // Retrieve other individual academic profile to ensure that the primary checkbox is unchecked
		for (reduivy__Individual_Academic_Profile__c ipf : [
			SELECT Id,
            Name,
			reduivy__Contact__c,
            reduivy__Primary__c
			FROM reduivy__Individual_Academic_Profile__c
            WHERE Id NOT IN: newPrimaryProfiles
		]) {
			System.Assert.isFalse(ipf.reduivy__Primary__c, 'This should not be primary.');
		}
	}

    /**
     * @description Test new primary academic profile with generation type = By IPE as admin
     */
    @IsTest
    static void testUpdatedPrimaryIpfAsAdminUser() {

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

		Integer primaryIpfCount = 0;
        Integer totalIpf = 0;
		for (reduivy__Individual_Academic_Profile__c ipf : [
			SELECT Id,
            Name,
			reduivy__Contact__c,
            reduivy__Primary__c
			FROM reduivy__Individual_Academic_Profile__c
		]) {
			if (ipf.reduivy__Primary__c) {
                primaryIpfCount ++;
            }

            totalIpf ++;
		}

        System.Assert.areNotEqual(0, totalIpf);
        System.Assert.areNotEqual(0, primaryIpfCount);
        System.Assert.areEqual(primaryIpfCount, totalIpf, 'The primary IPF should be equal to total IPF created.');
        
        System.runAs(ADMIN_USER) {

            // simulate a new primary individual academic profiel for each students
            List<reduivy__Individual_Academic_Profile__c> newPrimaryProfiles = new List<reduivy__Individual_Academic_Profile__c>();

            for (Contact student : studentContacts) {
                newPrimaryProfiles.add(
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.Id + '_NewPrimary',
                        student.Id,
                        student.Id + '_NewPrimary',
                        IPF_Helper.STATUS_ACTIVE,
                        true
                    )
                );
            }

            insert newPrimaryProfiles;

            List<reduivy__Individual_Academic_Profile__c> existingProfiles = new List<reduivy__Individual_Academic_Profile__c>();

            // Retrieve other individual academic profile to ensure that the primary checkbox is unchecked
            for (reduivy__Individual_Academic_Profile__c ipf : [
                SELECT Id,
                Name,
                reduivy__Contact__c,
                reduivy__Primary__c
                FROM reduivy__Individual_Academic_Profile__c
                WHERE Id NOT IN: newPrimaryProfiles
            ]) {
                System.Assert.isFalse(ipf.reduivy__Primary__c, 'This should not be primary.');

                // Simulate to repromote the existing profile to be come primary again
                ipf.reduivy__Primary__c = true;

                existingProfiles.add(ipf);
            }

            update existingProfiles;

            // Test to ensure that the other profiles are demoted
            for (reduivy__Individual_Academic_Profile__c ipf : [
                SELECT Id,
                Name,
                reduivy__Contact__c,
                reduivy__Primary__c
                FROM reduivy__Individual_Academic_Profile__c
                WHERE Id NOT IN: existingProfiles
            ]) {
                System.Assert.isFalse(ipf.reduivy__Primary__c, 'This should not be primary.');
            }
        }


	}
}