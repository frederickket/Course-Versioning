/**
 * @author      WDCi (dblack)
 * @date        Nov 2023
 * @group       Test
 * @description Test class for IEN_SetGradeSetting_EXE
 * @changehistory
 * ISS-001766 06-11-2023 dblack - new class
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@isTest
public inherited sharing class IEN_SetGradeSetting_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
	
	/*
     * @description we mute some non related triggers to save the resources
     */
    static final Set<String> TRIGGERS_TO_MUTE = new Set<String>{
        'IEN_AcademicProgress_Before'
    };

    /**
     * @description Initialise test data for each test
     */
	@TestSetup
    static void makeData() {

		// Create settings
		testFactory.setupDefaultSettings();

		User ADMIN_USER = testFactory.getReduAdminUser();
		// Create test data
        System.runAs(ADMIN_USER) {
			Test.startTest();

			testFactory.initMasterData(SUN_Helper.getApiName());
			testFactory.initOfferingData(SOF_Helper.getApiName());
			testFactory.initStudentData(IPR_Helper.getApiName(), true);

			List<reduivy__Study_Grade_Setting__c> sgsList = new List<reduivy__Study_Grade_Setting__c>();
			sgsList.add(REDU_TestData_UTIL.newStudyGradeSetting('SGS A', testFactory.eduInst.Id, 'SGS A', SGS_Helper.GRADING_SETTING_TYPE_PERCENTAGE_LETTER));
        	sgsList.add(REDU_TestData_UTIL.newStudyGradeSetting('SGS B', testFactory.eduInst.Id, 'SGS B', SGS_Helper.GRADING_SETTING_TYPE_PERCENTAGE_LETTER));

			REDU_Database_UTIL.doInsert(sgsList);

			Test.stopTest();
		}
    }

	/**
     * @description Triggers to be muted for test
     */
    private static void muteTriggers() {

        REDU_TriggerController.muteTriggers(TRIGGERS_TO_MUTE);

    }

    /**
     * @description Triggers to unmute for test
     */
    private static void unmuteTriggers() {

        REDU_TriggerController.unmuteTriggers(TRIGGERS_TO_MUTE);

    }

    /**
     * @description Test as admin that the IEN grade setting type is set from the SOF before insert
     */
    @IsTest
    static void testSetIenGradeSettingFromStudyOfferingBeforeInsertAsAdminUser() {
	
		User ADMIN_USER = testFactory.getReduAdminUser();

		muteTriggers();

		// Setup test data
		List<reduivy__Study_Grade_Setting__c> gradeSettings = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c IN ('SGS A', 'SGS B')];
		List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, reduivy__Study_Grade_Setting__c, (SELECT Id, reduivy__Study_Grade_Setting__c FROM reduivy__Study_Offerings__r WHERE reduivy__Academic_Term__r.reduivy__End_Date__c > TODAY LIMIT 1) FROM reduivy__Study_Unit__c LIMIT 2];
		List<reduivy__Study_Offering__c> sofList =  new List<reduivy__Study_Offering__c>();

		for (reduivy__Study_Unit__c sun : studyUnits) {
			sofList.addAll(sun.reduivy__Study_Offerings__r);
		}

		System.Assert.isFalse(
			sofList.isEmpty(),
			'The list should contain some study offering records records'
		);

		sofList.get(0).reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id;
		sofList.get(1).reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;

		update sofList;

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

		for (Contact student : studentContacts) {

			String sampleRecordCode = null;
			Id contactId = student.Id;
			Id studyOfferingId = sofList.get(0).Id;
			String enrollmentStatus = 'Enrollment Requested';
			Decimal attemptNumber = null;
			Date enrollmentDate = null;
			Date startDate = null; 
			Date endDate = null;
			Date censusDate = null;
			Decimal creditsOffered = null;
			Id idvAcademicProgressId = null;
			Id idvAcademicProfileId = studentToIPFMap.get(contactId);

			reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
				sampleRecordCode,
				contactId,
				studyOfferingId,
				enrollmentStatus,
				attemptNumber,
				enrollmentDate,
				startDate, 
				endDate,
				censusDate,
				creditsOffered,
				idvAcademicProgressId,
				idvAcademicProfileId,
				true
			);

			ienList.add(ien);
		}

		System.runAs(ADMIN_USER) {
		
			// Execute test
			Test.startTest();
			REDU_Database_UTIL.doInsert(ienList);
			Test.stopTest();
		}
		
		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				sofList.get(0).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}
	}

    /**
     * @description Test as admin that the IEN grade setting type is set from the SUN before insert
     */
    @IsTest
    static void testSetIenGradeSettingFromStudyUnitBeforeInsertAsAdminUser() {
		
		User ADMIN_USER = testFactory.getReduAdminUser();

		muteTriggers();

		// Setup test data
		List<reduivy__Study_Grade_Setting__c> gradeSettings = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c IN ('SGS A', 'SGS B')];
		List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, reduivy__Study_Grade_Setting__c, (SELECT Id, reduivy__Study_Grade_Setting__c FROM reduivy__Study_Offerings__r WHERE reduivy__Academic_Term__r.reduivy__End_Date__c > TODAY LIMIT 1) FROM reduivy__Study_Unit__c LIMIT 2];
		List<reduivy__Study_Offering__c> sofList =  new List<reduivy__Study_Offering__c>();

		for (reduivy__Study_Unit__c sun : studyUnits) {
			sofList.addAll(sun.reduivy__Study_Offerings__r);
		}

		System.Assert.isFalse(
			sofList.isEmpty(),
			'The list should contain some study offering records records'
		);

		studyUnits.get(0).reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id;
		studyUnits.get(1).reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;

		update studyUnits;

		sofList.get(0).reduivy__Study_Grade_Setting__c = null;
		sofList.get(1).reduivy__Study_Grade_Setting__c = null;

		update sofList;

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

		for (Contact student : studentContacts) {

			String sampleRecordCode = null;
			Id contactId = student.Id;
			Id studyOfferingId = sofList.get(0).Id;
			String enrollmentStatus = 'Enrollment Requested';
			Decimal attemptNumber = null;
			Date enrollmentDate = null;
			Date startDate = null; 
			Date endDate = null;
			Date censusDate = null;
			Decimal creditsOffered = null;
			Id idvAcademicProgressId = null;
			Id idvAcademicProfileId = studentToIPFMap.get(contactId);

			reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
				sampleRecordCode,
				contactId,
				studyOfferingId,
				enrollmentStatus,
				attemptNumber,
				enrollmentDate,
				startDate, 
				endDate,
				censusDate,
				creditsOffered,
				idvAcademicProgressId,
				idvAcademicProfileId,
				true
			);

			ienList.add(ien);
		}

		System.runAs(ADMIN_USER) {
		
			// Execute test
			Test.startTest();
			REDU_Database_UTIL.doInsert(ienList);
			Test.stopTest();
		}
		
		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				studyUnits.get(0).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}
	}

    /**
     * @description Test as admin that the IEN grade setting type is set from the SOF before update
     */
    @IsTest
    static void testSetIenGradeSettingFromStudyOfferingBeforeUpdateAsAdminUser() {
		
		User ADMIN_USER = testFactory.getReduAdminUser();

		muteTriggers();

		// Setup test data
		List<reduivy__Study_Grade_Setting__c> gradeSettings = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c IN ('SGS A', 'SGS B')];
		List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, reduivy__Study_Grade_Setting__c, (SELECT Id, reduivy__Study_Grade_Setting__c FROM reduivy__Study_Offerings__r WHERE reduivy__Academic_Term__r.reduivy__End_Date__c > TODAY LIMIT 1) FROM reduivy__Study_Unit__c LIMIT 2];
		List<reduivy__Study_Offering__c> sofList =  new List<reduivy__Study_Offering__c>();

		for (reduivy__Study_Unit__c sun : studyUnits) {
			sofList.addAll(sun.reduivy__Study_Offerings__r);
		}

		System.Assert.isFalse(
			sofList.isEmpty(),
			'The list should contain some study offering records records'
		);

		sofList.get(0).reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id;
		sofList.get(1).reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;

		update sofList;

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

		for (Contact student : studentContacts) {

			String sampleRecordCode = null;
			Id contactId = student.Id;
			Id studyOfferingId = sofList.get(0).Id;
			String enrollmentStatus = 'Enrollment Requested';
			Decimal attemptNumber = null;
			Date enrollmentDate = null;
			Date startDate = null; 
			Date endDate = null;
			Date censusDate = null;
			Decimal creditsOffered = null;
			Id idvAcademicProgressId = null;
			Id idvAcademicProfileId = studentToIPFMap.get(contactId);

			reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
				sampleRecordCode,
				contactId,
				studyOfferingId,
				enrollmentStatus,
				attemptNumber,
				enrollmentDate,
				startDate, 
				endDate,
				censusDate,
				creditsOffered,
				idvAcademicProgressId,
				idvAcademicProfileId,
				true
			);

			ienList.add(ien);
		}

		System.runAs(ADMIN_USER) {
		
			// Execute test
			Test.startTest();
			REDU_Database_UTIL.doInsert(ienList);
			Test.stopTest();
		}
		
		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				sofList.get(0).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}

		System.runAs(ADMIN_USER) {
			List<reduivy__Individual_Enrollment__c> ienUpdateList = new List<reduivy__Individual_Enrollment__c>();
			for (reduivy__Individual_Enrollment__c ien : ienList) {
				ienUpdateList.add(new reduivy__Individual_Enrollment__c(Id = ien.Id, reduivy__Study_Offering__c = sofList.get(1).Id));
			}

			REDU_Database_UTIL.doUpdate(ienUpdateList);
		}

		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				sofList.get(1).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}
	}

    /**
     * @description Test as admin that the IEN grade setting type is set from the SUN before update
     */
    @IsTest
    static void testSetIenGradeSettingFromStudyUnitBeforeUpdateAsAdminUser() {
		
		User ADMIN_USER = testFactory.getReduAdminUser();

		muteTriggers();

		// Setup test data
		List<reduivy__Study_Grade_Setting__c> gradeSettings = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c IN ('SGS A', 'SGS B')];
		List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, reduivy__Study_Grade_Setting__c, (SELECT Id, reduivy__Study_Grade_Setting__c FROM reduivy__Study_Offerings__r WHERE reduivy__Academic_Term__r.reduivy__End_Date__c > TODAY LIMIT 1) FROM reduivy__Study_Unit__c LIMIT 2];
		List<reduivy__Study_Offering__c> sofList =  new List<reduivy__Study_Offering__c>();

		for (reduivy__Study_Unit__c sun : studyUnits) {
			sofList.addAll(sun.reduivy__Study_Offerings__r);
		}

		System.Assert.isFalse(
			sofList.isEmpty(),
			'The list should contain some study offering records records'
		);

		studyUnits.get(0).reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id;
		studyUnits.get(1).reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;

		update studyUnits;

		sofList.get(0).reduivy__Study_Grade_Setting__c = null;
		sofList.get(1).reduivy__Study_Grade_Setting__c = null;

		update sofList;

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

		for (Contact student : studentContacts) {

			String sampleRecordCode = null;
			Id contactId = student.Id;
			Id studyOfferingId = sofList.get(0).Id;
			String enrollmentStatus = 'Enrollment Requested';
			Decimal attemptNumber = null;
			Date enrollmentDate = null;
			Date startDate = null; 
			Date endDate = null;
			Date censusDate = null;
			Decimal creditsOffered = null;
			Id idvAcademicProgressId = null;
			Id idvAcademicProfileId = studentToIPFMap.get(contactId);

			reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
				sampleRecordCode,
				contactId,
				studyOfferingId,
				enrollmentStatus,
				attemptNumber,
				enrollmentDate,
				startDate, 
				endDate,
				censusDate,
				creditsOffered,
				idvAcademicProgressId,
				idvAcademicProfileId,
				true
			);

			ienList.add(ien);
		}

		System.runAs(ADMIN_USER) {
		
			// Execute test
			Test.startTest();
			REDU_Database_UTIL.doInsert(ienList);
			Test.stopTest();
		}
		
		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				studyUnits.get(0).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}

		System.runAs(ADMIN_USER) {
			List<reduivy__Individual_Enrollment__c> ienUpdateList = new List<reduivy__Individual_Enrollment__c>();
			for (reduivy__Individual_Enrollment__c ien : ienList) {
				ienUpdateList.add(new reduivy__Individual_Enrollment__c(Id = ien.Id, reduivy__Study_Offering__c = sofList.get(1).Id));
			}

			REDU_Database_UTIL.doUpdate(ienUpdateList);
		}

		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				studyUnits.get(1).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}
	}

    /**
     * @description Test as faculty that the IEN grade setting type is set from the SOF before insert
     */
    @IsTest
    static void testSetIenGradeSettingFromStudyOfferingBeforeInsertAsFacultyUser() {
		
		User FACULTY_USER = testFactory.getReduFacultyUser();

		muteTriggers();

		// Setup test data
		List<reduivy__Study_Grade_Setting__c> gradeSettings = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c IN ('SGS A', 'SGS B')];
		List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, reduivy__Study_Grade_Setting__c, (SELECT Id, reduivy__Study_Grade_Setting__c FROM reduivy__Study_Offerings__r WHERE reduivy__Academic_Term__r.reduivy__End_Date__c > TODAY LIMIT 1) FROM reduivy__Study_Unit__c LIMIT 2];
		List<reduivy__Study_Offering__c> sofList =  new List<reduivy__Study_Offering__c>();

		for (reduivy__Study_Unit__c sun : studyUnits) {
			sofList.addAll(sun.reduivy__Study_Offerings__r);
		}

		System.Assert.isFalse(
			sofList.isEmpty(),
			'The list should contain some study offering records records'
		);

		sofList.get(0).reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id;
		sofList.get(1).reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;

		update sofList;

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

		for (Contact student : studentContacts) {

			String sampleRecordCode = null;
			Id contactId = student.Id;
			Id studyOfferingId = sofList.get(0).Id;
			String enrollmentStatus = 'Enrollment Requested';
			Decimal attemptNumber = null;
			Date enrollmentDate = null;
			Date startDate = null; 
			Date endDate = null;
			Date censusDate = null;
			Decimal creditsOffered = null;
			Id idvAcademicProgressId = null;
			Id idvAcademicProfileId = studentToIPFMap.get(contactId);

			reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
				sampleRecordCode,
				contactId,
				studyOfferingId,
				enrollmentStatus,
				attemptNumber,
				enrollmentDate,
				startDate, 
				endDate,
				censusDate,
				creditsOffered,
				idvAcademicProgressId,
				idvAcademicProfileId,
				true
			);

			ienList.add(ien);
		}

		System.runAs(FACULTY_USER) {
		
			// Execute test
			Test.startTest();
			REDU_Database_UTIL.doInsert(ienList);
			Test.stopTest();
		}
		
		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				sofList.get(0).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}
	}

    /**
     * @description Test as faculty that the IEN grade setting type is set from the SUN before insert
     */
    @IsTest
    static void testSetIenGradeSettingFromStudyUnitBeforeInsertAsFacultyUser() {
		
		User FACULTY_USER = testFactory.getReduFacultyUser();

		muteTriggers();

		// Setup test data
		List<reduivy__Study_Grade_Setting__c> gradeSettings = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c IN ('SGS A', 'SGS B')];
		List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, reduivy__Study_Grade_Setting__c, (SELECT Id, reduivy__Study_Grade_Setting__c FROM reduivy__Study_Offerings__r WHERE reduivy__Academic_Term__r.reduivy__End_Date__c > TODAY LIMIT 1) FROM reduivy__Study_Unit__c LIMIT 2];
		List<reduivy__Study_Offering__c> sofList =  new List<reduivy__Study_Offering__c>();

		for (reduivy__Study_Unit__c sun : studyUnits) {
			sofList.addAll(sun.reduivy__Study_Offerings__r);
		}

		System.Assert.isFalse(
			sofList.isEmpty(),
			'The list should contain some study offering records records'
		);

		studyUnits.get(0).reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id;
		studyUnits.get(1).reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;

		update studyUnits;

		sofList.get(0).reduivy__Study_Grade_Setting__c = null;
		sofList.get(1).reduivy__Study_Grade_Setting__c = null;

		update sofList;

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

		for (Contact student : studentContacts) {

			String sampleRecordCode = null;
			Id contactId = student.Id;
			Id studyOfferingId = sofList.get(0).Id;
			String enrollmentStatus = 'Enrollment Requested';
			Decimal attemptNumber = null;
			Date enrollmentDate = null;
			Date startDate = null; 
			Date endDate = null;
			Date censusDate = null;
			Decimal creditsOffered = null;
			Id idvAcademicProgressId = null;
			Id idvAcademicProfileId = studentToIPFMap.get(contactId);

			reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
				sampleRecordCode,
				contactId,
				studyOfferingId,
				enrollmentStatus,
				attemptNumber,
				enrollmentDate,
				startDate, 
				endDate,
				censusDate,
				creditsOffered,
				idvAcademicProgressId,
				idvAcademicProfileId,
				true
			);

			ienList.add(ien);
		}

		System.runAs(FACULTY_USER) {
		
			// Execute test
			Test.startTest();
			REDU_Database_UTIL.doInsert(ienList);
			Test.stopTest();
		}
		
		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				studyUnits.get(0).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}
	}

    /**
     * @description Test as faculty that the IEN grade setting type is set from the SOF before update
     */
    @IsTest
    static void testSetIenGradeSettingFromStudyOfferingBeforeUpdateAsFacultyUser() {
		
		User FACULTY_USER = testFactory.getReduFacultyUser();

		muteTriggers();

		// Setup test data
		List<reduivy__Study_Grade_Setting__c> gradeSettings = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c IN ('SGS A', 'SGS B')];
		List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, reduivy__Study_Grade_Setting__c, (SELECT Id, reduivy__Study_Grade_Setting__c FROM reduivy__Study_Offerings__r WHERE reduivy__Academic_Term__r.reduivy__End_Date__c > TODAY LIMIT 1) FROM reduivy__Study_Unit__c LIMIT 2];
		List<reduivy__Study_Offering__c> sofList =  new List<reduivy__Study_Offering__c>();

		for (reduivy__Study_Unit__c sun : studyUnits) {
			sofList.addAll(sun.reduivy__Study_Offerings__r);
		}

		System.Assert.isFalse(
			sofList.isEmpty(),
			'The list should contain some study offering records records'
		);

		sofList.get(0).reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id;
		sofList.get(1).reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;

		update sofList;

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

		for (Contact student : studentContacts) {

			String sampleRecordCode = null;
			Id contactId = student.Id;
			Id studyOfferingId = sofList.get(0).Id;
			String enrollmentStatus = 'Enrollment Requested';
			Decimal attemptNumber = null;
			Date enrollmentDate = null;
			Date startDate = null; 
			Date endDate = null;
			Date censusDate = null;
			Decimal creditsOffered = null;
			Id idvAcademicProgressId = null;
			Id idvAcademicProfileId = studentToIPFMap.get(contactId);

			reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
				sampleRecordCode,
				contactId,
				studyOfferingId,
				enrollmentStatus,
				attemptNumber,
				enrollmentDate,
				startDate, 
				endDate,
				censusDate,
				creditsOffered,
				idvAcademicProgressId,
				idvAcademicProfileId,
				true
			);

			ienList.add(ien);
		}

		System.runAs(FACULTY_USER) {
		
			// Execute test
			Test.startTest();
			REDU_Database_UTIL.doInsert(ienList);
			Test.stopTest();
		}
		
		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				sofList.get(0).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}

		System.runAs(FACULTY_USER) {
			List<reduivy__Individual_Enrollment__c> ienUpdateList = new List<reduivy__Individual_Enrollment__c>();
			for (reduivy__Individual_Enrollment__c ien : ienList) {
				ienUpdateList.add(new reduivy__Individual_Enrollment__c(Id = ien.Id, reduivy__Study_Offering__c = sofList.get(1).Id));
			}

			REDU_Database_UTIL.doUpdate(ienUpdateList);
		}

		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				sofList.get(1).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}
	}

    /**
     * @description Test as faculty that the IEN grade setting type is set from the SUN before update
     */
    @IsTest
    static void testSetIenGradeSettingFromStudyUnitBeforeUpdateAsFacultyUser() {
		
		User FACULTY_USER = testFactory.getReduFacultyUser();
		
		muteTriggers();

		// Setup test data
		List<reduivy__Study_Grade_Setting__c> gradeSettings = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c IN ('SGS A', 'SGS B')];
		List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, reduivy__Study_Grade_Setting__c, (SELECT Id, reduivy__Study_Grade_Setting__c FROM reduivy__Study_Offerings__r WHERE reduivy__Academic_Term__r.reduivy__End_Date__c > TODAY LIMIT 1) FROM reduivy__Study_Unit__c LIMIT 2];
		List<reduivy__Study_Offering__c> sofList =  new List<reduivy__Study_Offering__c>();

		for (reduivy__Study_Unit__c sun : studyUnits) {
			sofList.addAll(sun.reduivy__Study_Offerings__r);
		}

		System.Assert.isFalse(
			sofList.isEmpty(),
			'The list should contain some study offering records records'
		);

		studyUnits.get(0).reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id;
		studyUnits.get(1).reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;

		update studyUnits;

		sofList.get(0).reduivy__Study_Grade_Setting__c = null;
		sofList.get(1).reduivy__Study_Grade_Setting__c = null;

		update sofList;

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

		for (Contact student : studentContacts) {

			String sampleRecordCode = null;
			Id contactId = student.Id;
			Id studyOfferingId = sofList.get(0).Id;
			String enrollmentStatus = 'Enrollment Requested';
			Decimal attemptNumber = null;
			Date enrollmentDate = null;
			Date startDate = null; 
			Date endDate = null;
			Date censusDate = null;
			Decimal creditsOffered = null;
			Id idvAcademicProgressId = null;
			Id idvAcademicProfileId = studentToIPFMap.get(contactId);

			reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
				sampleRecordCode,
				contactId,
				studyOfferingId,
				enrollmentStatus,
				attemptNumber,
				enrollmentDate,
				startDate, 
				endDate,
				censusDate,
				creditsOffered,
				idvAcademicProgressId,
				idvAcademicProfileId,
				true
			);

			ienList.add(ien);
		}

		System.runAs(FACULTY_USER) {
		
			// Execute test
			Test.startTest();
			REDU_Database_UTIL.doInsert(ienList);
			Test.stopTest();
		}
		
		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				studyUnits.get(0).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}

		System.runAs(FACULTY_USER) {
			List<reduivy__Individual_Enrollment__c> ienUpdateList = new List<reduivy__Individual_Enrollment__c>();
			for (reduivy__Individual_Enrollment__c ien : ienList) {
				ienUpdateList.add(new reduivy__Individual_Enrollment__c(Id = ien.Id, reduivy__Study_Offering__c = sofList.get(1).Id));
			}

			REDU_Database_UTIL.doUpdate(ienUpdateList);
		}

		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				studyUnits.get(1).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}
	}

    /**
     * @description Test as a student that the IEN grade setting type is set from the SOF before insert
     */
    @IsTest
    static void testSetIenGradeSettingFromStudyOfferingBeforeInsertAsStudentUser() {
	
		muteTriggers();

		// Setup test data
		List<reduivy__Study_Grade_Setting__c> gradeSettings = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c IN ('SGS A', 'SGS B')];
		List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, reduivy__Study_Grade_Setting__c, (SELECT Id, reduivy__Study_Grade_Setting__c FROM reduivy__Study_Offerings__r WHERE reduivy__Academic_Term__r.reduivy__End_Date__c > TODAY LIMIT 1) FROM reduivy__Study_Unit__c LIMIT 2];
		List<reduivy__Study_Offering__c> sofList =  new List<reduivy__Study_Offering__c>();

		for (reduivy__Study_Unit__c sun : studyUnits) {
			sofList.addAll(sun.reduivy__Study_Offerings__r);
		}

		System.Assert.isFalse(
			sofList.isEmpty(),
			'The list should contain some study offering records records'
		);

		sofList.get(0).reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id;
		sofList.get(1).reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;

		update sofList;

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id, ContactId
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

		List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

		for (Contact student : studentContacts) {

			String sampleRecordCode = null;
			Id contactId = student.Id;
			Id studyOfferingId = sofList.get(0).Id;
			String enrollmentStatus = 'Enrollment Requested';
			Decimal attemptNumber = null;
			Date enrollmentDate = null;
			Date startDate = null; 
			Date endDate = null;
			Date censusDate = null;
			Decimal creditsOffered = null;
			Id idvAcademicProgressId = null;
			Id idvAcademicProfileId = studentIpfs[0].Id;

			reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
				sampleRecordCode,
				contactId,
				studyOfferingId,
				enrollmentStatus,
				attemptNumber,
				enrollmentDate,
				startDate, 
				endDate,
				censusDate,
				creditsOffered,
				idvAcademicProgressId,
				idvAcademicProfileId,
				true
			);

			ienList.add(ien);
		}

		System.runAs(studentUser) {
		
			// Execute test
			Test.startTest();
			REDU_Database_UTIL.doInsert(ienList);
			Test.stopTest();
		}
		
		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				sofList.get(0).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}
	}

    /**
     * @description Test as a student that the IEN grade setting type is set from the SUN before insert
     */
    @IsTest
    static void testSetIenGradeSettingFromStudyUnitBeforeInsertAsStudentUser() {
	
		muteTriggers();

		// Setup test data
		List<reduivy__Study_Grade_Setting__c> gradeSettings = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c IN ('SGS A', 'SGS B')];
		List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, reduivy__Study_Grade_Setting__c, (SELECT Id, reduivy__Study_Grade_Setting__c FROM reduivy__Study_Offerings__r WHERE reduivy__Academic_Term__r.reduivy__End_Date__c > TODAY LIMIT 1) FROM reduivy__Study_Unit__c LIMIT 2];
		List<reduivy__Study_Offering__c> sofList =  new List<reduivy__Study_Offering__c>();

		for (reduivy__Study_Unit__c sun : studyUnits) {
			sofList.addAll(sun.reduivy__Study_Offerings__r);
		}

		System.Assert.isFalse(
			sofList.isEmpty(),
			'The list should contain some study offering records records'
		);

		studyUnits.get(0).reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id;
		studyUnits.get(1).reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;

		update studyUnits;

		sofList.get(0).reduivy__Study_Grade_Setting__c = null;
		sofList.get(1).reduivy__Study_Grade_Setting__c = null;

		update sofList;

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id, ContactId
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

		List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

		for (Contact student : studentContacts) {

			String sampleRecordCode = null;
			Id contactId = student.Id;
			Id studyOfferingId = sofList.get(0).Id;
			String enrollmentStatus = 'Enrollment Requested';
			Decimal attemptNumber = null;
			Date enrollmentDate = null;
			Date startDate = null; 
			Date endDate = null;
			Date censusDate = null;
			Decimal creditsOffered = null;
			Id idvAcademicProgressId = null;
			Id idvAcademicProfileId = studentIpfs[0].Id;

			reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
				sampleRecordCode,
				contactId,
				studyOfferingId,
				enrollmentStatus,
				attemptNumber,
				enrollmentDate,
				startDate, 
				endDate,
				censusDate,
				creditsOffered,
				idvAcademicProgressId,
				idvAcademicProfileId,
				true
			);

			ienList.add(ien);
		}

		System.runAs(studentUser) {
		
			// Execute test
			Test.startTest();
			REDU_Database_UTIL.doInsert(ienList);
			Test.stopTest();
		}
		
		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				studyUnits.get(0).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}
	}

    /**
     * @description Test as a student that the IEN grade setting type is set from the SOF before update
     */
    @IsTest
    static void testSetIenGradeSettingFromStudyOfferingBeforeUpdateAsStudentUser() {
	
		muteTriggers();

		// Setup test data
		List<reduivy__Study_Grade_Setting__c> gradeSettings = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c IN ('SGS A', 'SGS B')];
		List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, reduivy__Study_Grade_Setting__c, (SELECT Id, reduivy__Study_Grade_Setting__c FROM reduivy__Study_Offerings__r WHERE reduivy__Academic_Term__r.reduivy__End_Date__c > TODAY LIMIT 1) FROM reduivy__Study_Unit__c LIMIT 2];
		List<reduivy__Study_Offering__c> sofList =  new List<reduivy__Study_Offering__c>();

		for (reduivy__Study_Unit__c sun : studyUnits) {
			sofList.addAll(sun.reduivy__Study_Offerings__r);
		}

		System.Assert.isFalse(
			sofList.isEmpty(),
			'The list should contain some study offering records records'
		);

		sofList.get(0).reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id;
		sofList.get(1).reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;

		update sofList;

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id, ContactId
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

		List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

		for (Contact student : studentContacts) {

			String sampleRecordCode = null;
			Id contactId = student.Id;
			Id studyOfferingId = sofList.get(0).Id;
			String enrollmentStatus = 'Enrollment Requested';
			Decimal attemptNumber = null;
			Date enrollmentDate = null;
			Date startDate = null; 
			Date endDate = null;
			Date censusDate = null;
			Decimal creditsOffered = null;
			Id idvAcademicProgressId = null;
			Id idvAcademicProfileId = studentIpfs[0].Id;

			reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
				sampleRecordCode,
				contactId,
				studyOfferingId,
				enrollmentStatus,
				attemptNumber,
				enrollmentDate,
				startDate, 
				endDate,
				censusDate,
				creditsOffered,
				idvAcademicProgressId,
				idvAcademicProfileId,
				true
			);

			ienList.add(ien);
		}

		System.runAs(studentUser) {
		
			// Execute test
			Test.startTest();
			REDU_Database_UTIL.doInsert(ienList);
			Test.stopTest();
		}
		
		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				sofList.get(0).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}

		System.runAs(studentUser) {
			List<reduivy__Individual_Enrollment__c> ienUpdateList = new List<reduivy__Individual_Enrollment__c>();
			for (reduivy__Individual_Enrollment__c ien : ienList) {
				ienUpdateList.add(new reduivy__Individual_Enrollment__c(Id = ien.Id, reduivy__Study_Offering__c = sofList.get(1).Id));
			}

			REDU_Database_UTIL.doUpdate(ienUpdateList);
		}

		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				sofList.get(1).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}
	}

    /**
     * @description Test as a student that the IEN grade setting type is set from the SUN before update
     */
    @IsTest
    static void testSetIenGradeSettingFromStudyUnitBeforeUpdateAsStudentUser() {
	
		muteTriggers();

		// Setup test data
		List<reduivy__Study_Grade_Setting__c> gradeSettings = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c IN ('SGS A', 'SGS B')];
		List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, reduivy__Study_Grade_Setting__c, (SELECT Id, reduivy__Study_Grade_Setting__c FROM reduivy__Study_Offerings__r WHERE reduivy__Academic_Term__r.reduivy__End_Date__c > TODAY LIMIT 1) FROM reduivy__Study_Unit__c LIMIT 2];
		List<reduivy__Study_Offering__c> sofList =  new List<reduivy__Study_Offering__c>();

		for (reduivy__Study_Unit__c sun : studyUnits) {
			sofList.addAll(sun.reduivy__Study_Offerings__r);
		}

		System.Assert.isFalse(
			sofList.isEmpty(),
			'The list should contain some study offering records records'
		);

		studyUnits.get(0).reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id;
		studyUnits.get(1).reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;

		update studyUnits;

		sofList.get(0).reduivy__Study_Grade_Setting__c = null;
		sofList.get(1).reduivy__Study_Grade_Setting__c = null;

		update sofList;

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id, ContactId
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

		List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

		for (Contact student : studentContacts) {

			String sampleRecordCode = null;
			Id contactId = student.Id;
			Id studyOfferingId = sofList.get(0).Id;
			String enrollmentStatus = 'Enrollment Requested';
			Decimal attemptNumber = null;
			Date enrollmentDate = null;
			Date startDate = null; 
			Date endDate = null;
			Date censusDate = null;
			Decimal creditsOffered = null;
			Id idvAcademicProgressId = null;
			Id idvAcademicProfileId = studentIpfs[0].Id;

			reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
				sampleRecordCode,
				contactId,
				studyOfferingId,
				enrollmentStatus,
				attemptNumber,
				enrollmentDate,
				startDate, 
				endDate,
				censusDate,
				creditsOffered,
				idvAcademicProgressId,
				idvAcademicProfileId,
				true
			);

			ienList.add(ien);
		}

		System.runAs(studentUser) {
		
			// Execute test
			Test.startTest();
			REDU_Database_UTIL.doInsert(ienList);
			Test.stopTest();
		}
		
		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				studyUnits.get(0).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}

		System.runAs(studentUser) {
			List<reduivy__Individual_Enrollment__c> ienUpdateList = new List<reduivy__Individual_Enrollment__c>();
			for (reduivy__Individual_Enrollment__c ien : ienList) {
				ienUpdateList.add(new reduivy__Individual_Enrollment__c(Id = ien.Id, reduivy__Study_Offering__c = sofList.get(1).Id));
			}

			REDU_Database_UTIL.doUpdate(ienUpdateList);
		}

		// Verify test results
		ienList = [
			SELECT 	reduivy__Study_Grade_Setting__c, 
			reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
			reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Enrollment_Status__c = 'Enrollment Requested'
		];

		System.Assert.isFalse(
			ienList.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : ienList) {

			System.Assert.isNotNull(
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areEqual(
				studyUnits.get(1).reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);

			System.Assert.areNotEqual(
				ien.reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c,
				ien.reduivy__Study_Grade_Setting__c,
				'The actual value should be as expected'
			);
		}
	}

	/**
	 * @description Test as admin that:
	 * - the IEN grade setting is NOT overwritten on insert if already populated
	 * - the IEN grade setting IS overwritten on update if the SOF changes
	 */
	@IsTest
	static void testSetIenGradeSettingNotOverwrittenIfAlreadySetAsAdminUser() {

		User ADMIN_USER = testFactory.getReduAdminUser();

		muteTriggers();

		// Setup test data
		List<reduivy__Study_Grade_Setting__c> gradeSettings = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c IN ('SGS A', 'SGS B')];
		List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, reduivy__Study_Grade_Setting__c, (SELECT Id, reduivy__Study_Grade_Setting__c FROM reduivy__Study_Offerings__r WHERE reduivy__Academic_Term__r.reduivy__End_Date__c > TODAY LIMIT 1) FROM reduivy__Study_Unit__c LIMIT 2];
		List<reduivy__Study_Offering__c> sofList = new List<reduivy__Study_Offering__c>();

		for (reduivy__Study_Unit__c sun : studyUnits) {
			sofList.addAll(sun.reduivy__Study_Offerings__r);
		}

		System.Assert.isFalse(
			sofList.isEmpty(),
			'The list should contain some study offering records'
		);

		// Assign SGS A to SOF 0 and SGS B to SOF 1
		sofList.get(0).reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id;
		sofList.get(1).reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;
		update sofList;

		List<Contact> studentContacts = [SELECT Id,
			reduivy__Sample_Record_Code__c
			FROM Contact
			WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
			AND reduivy__Sample_Record_Code__c <> ''
		];

		List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
		Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

		for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
			studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
		}

		// --- INSERT: pre-populate Study_Grade_Setting__c with SGS B ---
		// SOF 0 carries SGS A, so if the trigger incorrectly runs it would overwrite with SGS A
		// The String.isBlank guard on insert should prevent this and preserve SGS B
		List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

		for (Contact student : studentContacts) {
			reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
				null,
				student.Id,
				sofList.get(0).Id,
				'Enrollment Requested',
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				studentToIPFMap.get(student.Id),
				true
			);

			ien.reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;

			ienList.add(ien);
		}

		Test.startTest();

		System.runAs(ADMIN_USER) {
			REDU_Database_UTIL.doInsert(ienList);
		}

		// Verify SGS B was preserved on insert and NOT overwritten with SGS A from SOF 0
		List<reduivy__Individual_Enrollment__c> insertedIens = [
			SELECT Id, reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE Id IN: ienList
		];

		System.Assert.isFalse(
			insertedIens.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : insertedIens) {
			System.Assert.areEqual(
				gradeSettings.get(1).Id,
				ien.reduivy__Study_Grade_Setting__c,
				'The pre-set grade setting (SGS B) should not be overwritten by the trigger on insert'
			);
		}

		// --- UPDATE: change SOF from SOF 0 to SOF 1 (which carries SGS B) ---
		// Even though Study_Grade_Setting__c is already populated with SGS B, the trigger should
		// always refresh it from the new SOF when SOF changes — resulting in SGS B from SOF 1
		// (coincidentally the same value here, but driven by the SOF, not the pre-existing value)
		// To make the overwrite clearly observable, keep Study_Grade_Setting__c as SGS A on the update
		// so we can confirm the trigger replaces it with SGS B from SOF 1
		List<reduivy__Individual_Enrollment__c> ienUpdateList = new List<reduivy__Individual_Enrollment__c>();

		for (reduivy__Individual_Enrollment__c ien : insertedIens) {
			ienUpdateList.add(new reduivy__Individual_Enrollment__c(
				Id = ien.Id,
				reduivy__Study_Offering__c = sofList.get(1).Id,
				reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id  // set to SGS A — trigger should overwrite with SGS B from SOF 1
			));
		}

		System.runAs(ADMIN_USER) {
			REDU_Database_UTIL.doUpdate(ienUpdateList);
		}

		// Verify the grade setting was refreshed to SGS B from SOF 1, overwriting the stale SGS A
		List<reduivy__Individual_Enrollment__c> updatedIens = [
			SELECT reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE Id IN: ienUpdateList
		];

		System.Assert.isFalse(
			updatedIens.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : updatedIens) {
			System.Assert.areEqual(
				gradeSettings.get(1).Id,
				ien.reduivy__Study_Grade_Setting__c,
				'The grade setting should be refreshed to SGS B from the new SOF 1 when SOF changes'
			);

			System.Assert.areNotEqual(
				gradeSettings.get(0).Id,
				ien.reduivy__Study_Grade_Setting__c,
				'The stale grade setting (SGS A) should have been replaced by the new SOF grade setting (SGS B)'
			);
		}

		Test.stopTest();
	}

	/**
	 * @description Test as faculty that:
	 * - the IEN grade setting is NOT overwritten on insert if already populated
	 * - the IEN grade setting IS overwritten on update if the SOF changes
	 */
	@IsTest
	static void testSetIenGradeSettingNotOverwrittenIfAlreadySetAsFacultyUser() {

		User FACULTY_USER = testFactory.getReduFacultyUser();

		muteTriggers();

		// Setup test data
		List<reduivy__Study_Grade_Setting__c> gradeSettings = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c IN ('SGS A', 'SGS B')];
		List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, reduivy__Study_Grade_Setting__c, (SELECT Id, reduivy__Study_Grade_Setting__c FROM reduivy__Study_Offerings__r WHERE reduivy__Academic_Term__r.reduivy__End_Date__c > TODAY LIMIT 1) FROM reduivy__Study_Unit__c LIMIT 2];
		List<reduivy__Study_Offering__c> sofList = new List<reduivy__Study_Offering__c>();

		for (reduivy__Study_Unit__c sun : studyUnits) {
			sofList.addAll(sun.reduivy__Study_Offerings__r);
		}

		System.Assert.isFalse(
			sofList.isEmpty(),
			'The list should contain some study offering records'
		);

		// Assign SGS A to SOF 0 and SGS B to SOF 1
		sofList.get(0).reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id;
		sofList.get(1).reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;
		update sofList;

		List<Contact> studentContacts = [SELECT Id,
			reduivy__Sample_Record_Code__c
			FROM Contact
			WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
			AND reduivy__Sample_Record_Code__c <> ''
		];

		List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
		Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

		for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
			studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
		}

		// --- INSERT: pre-populate Study_Grade_Setting__c with SGS B ---
		// SOF 0 carries SGS A, so if the trigger incorrectly runs it would overwrite with SGS A
		// The String.isBlank guard on insert should prevent this and preserve SGS B
		List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

		for (Contact student : studentContacts) {
			reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
				null,
				student.Id,
				sofList.get(0).Id,
				'Enrollment Requested',
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				studentToIPFMap.get(student.Id),
				true
			);

			ien.reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;

			ienList.add(ien);
		}

		Test.startTest();

		System.runAs(FACULTY_USER) {
			REDU_Database_UTIL.doInsert(ienList);
		}

		// Verify SGS B was preserved on insert and NOT overwritten with SGS A from SOF 0
		List<reduivy__Individual_Enrollment__c> insertedIens = [
			SELECT Id, reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE Id IN: ienList
		];

		System.Assert.isFalse(
			insertedIens.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : insertedIens) {
			System.Assert.areEqual(
				gradeSettings.get(1).Id,
				ien.reduivy__Study_Grade_Setting__c,
				'The pre-set grade setting (SGS B) should not be overwritten by the trigger on insert'
			);
		}

		// --- UPDATE: change SOF from SOF 0 to SOF 1 (which carries SGS B) ---
		// Set Study_Grade_Setting__c to SGS A so the overwrite to SGS B from SOF 1 is clearly observable
		List<reduivy__Individual_Enrollment__c> ienUpdateList = new List<reduivy__Individual_Enrollment__c>();

		for (reduivy__Individual_Enrollment__c ien : insertedIens) {
			ienUpdateList.add(new reduivy__Individual_Enrollment__c(
				Id = ien.Id,
				reduivy__Study_Offering__c = sofList.get(1).Id,
				reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id  // set to SGS A — trigger should overwrite with SGS B from SOF 1
			));
		}

		System.runAs(FACULTY_USER) {
			REDU_Database_UTIL.doUpdate(ienUpdateList);
		}

		// Verify the grade setting was refreshed to SGS B from SOF 1, overwriting the stale SGS A
		List<reduivy__Individual_Enrollment__c> updatedIens = [
			SELECT reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE Id IN: ienUpdateList
		];

		System.Assert.isFalse(
			updatedIens.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : updatedIens) {
			System.Assert.areEqual(
				gradeSettings.get(1).Id,
				ien.reduivy__Study_Grade_Setting__c,
				'The grade setting should be refreshed to SGS B from the new SOF 1 when SOF changes'
			);

			System.Assert.areNotEqual(
				gradeSettings.get(0).Id,
				ien.reduivy__Study_Grade_Setting__c,
				'The stale grade setting (SGS A) should have been replaced by the new SOF grade setting (SGS B)'
			);
		}

		Test.stopTest();
	}

	/**
	 * @description Test as student that:
	 * - the IEN grade setting is NOT overwritten on insert if already populated
	 * - the IEN grade setting IS overwritten on update if the SOF changes
	 */
	@IsTest
	static void testSetIenGradeSettingNotOverwrittenIfAlreadySetAsStudentUser() {

		muteTriggers();

		// Setup test data
		List<reduivy__Study_Grade_Setting__c> gradeSettings = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c IN ('SGS A', 'SGS B')];
		List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, reduivy__Study_Grade_Setting__c, (SELECT Id, reduivy__Study_Grade_Setting__c FROM reduivy__Study_Offerings__r WHERE reduivy__Academic_Term__r.reduivy__End_Date__c > TODAY LIMIT 1) FROM reduivy__Study_Unit__c LIMIT 2];
		List<reduivy__Study_Offering__c> sofList = new List<reduivy__Study_Offering__c>();

		for (reduivy__Study_Unit__c sun : studyUnits) {
			sofList.addAll(sun.reduivy__Study_Offerings__r);
		}

		System.Assert.isFalse(
			sofList.isEmpty(),
			'The list should contain some study offering records'
		);

		// Assign SGS A to SOF 0 and SGS B to SOF 1
		sofList.get(0).reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id;
		sofList.get(1).reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;
		update sofList;

		List<Contact> studentContacts = [SELECT Id,
			reduivy__Sample_Record_Code__c
			FROM Contact
			WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
			AND reduivy__Sample_Record_Code__c <> ''
			LIMIT 1
		];

		User studentUser = [SELECT Id, ContactId
			FROM User
			WHERE ContactId IN: studentContacts
			AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
			LIMIT 1
		];

		List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
		Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

		for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
			studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
		}

		// --- INSERT: pre-populate Study_Grade_Setting__c with SGS B ---
		// SOF 0 carries SGS A, so if the trigger incorrectly runs it would overwrite with SGS A
		// The String.isBlank guard on insert should prevent this and preserve SGS B
		List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

		for (Contact student : studentContacts) {
			reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
				null,
				student.Id,
				sofList.get(0).Id,
				'Enrollment Requested',
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				studentToIPFMap.get(student.Id),
				true
			);

			ien.reduivy__Study_Grade_Setting__c = gradeSettings.get(1).Id;

			ienList.add(ien);
		}

		Test.startTest();

		System.runAs(studentUser) {
			REDU_Database_UTIL.doInsert(ienList);
		}

		// Verify SGS B was preserved on insert and NOT overwritten with SGS A from SOF 0
		List<reduivy__Individual_Enrollment__c> insertedIens = [
			SELECT Id, reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE Id IN: ienList
		];

		System.Assert.isFalse(
			insertedIens.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : insertedIens) {
			System.Assert.areEqual(
				gradeSettings.get(1).Id,
				ien.reduivy__Study_Grade_Setting__c,
				'The pre-set grade setting (SGS B) should not be overwritten by the trigger on insert'
			);
		}

		// --- UPDATE: change SOF from SOF 0 to SOF 1 (which carries SGS B) ---
		// Set Study_Grade_Setting__c to SGS A so the overwrite to SGS B from SOF 1 is clearly observable
		List<reduivy__Individual_Enrollment__c> ienUpdateList = new List<reduivy__Individual_Enrollment__c>();

		for (reduivy__Individual_Enrollment__c ien : insertedIens) {
			ienUpdateList.add(new reduivy__Individual_Enrollment__c(
				Id = ien.Id,
				reduivy__Study_Offering__c = sofList.get(1).Id,
				reduivy__Study_Grade_Setting__c = gradeSettings.get(0).Id  // set to SGS A — trigger should overwrite with SGS B from SOF 1
			));
		}

		System.runAs(studentUser) {
			REDU_Database_UTIL.doUpdate(ienUpdateList);
		}

		// Verify the grade setting was refreshed to SGS B from SOF 1, overwriting the stale SGS A
		List<reduivy__Individual_Enrollment__c> updatedIens = [
			SELECT reduivy__Study_Grade_Setting__c
			FROM reduivy__Individual_Enrollment__c
			WHERE Id IN: ienUpdateList
		];

		System.Assert.isFalse(
			updatedIens.isEmpty(),
			'The list should contain some individual enrollment records'
		);

		for (reduivy__Individual_Enrollment__c ien : updatedIens) {
			System.Assert.areEqual(
				gradeSettings.get(1).Id,
				ien.reduivy__Study_Grade_Setting__c,
				'The grade setting should be refreshed to SGS B from the new SOF 1 when SOF changes'
			);

			System.Assert.areNotEqual(
				gradeSettings.get(0).Id,
				ien.reduivy__Study_Grade_Setting__c,
				'The stale grade setting (SGS A) should have been replaced by the new SOF grade setting (SGS B)'
			);
		}

		Test.stopTest();
	}
}