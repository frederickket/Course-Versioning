/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Test
 * @description Test class for IPE_CreateGroup_EXE
 * @changehistory
 * ISS-001662 09-10-2023 dblack - new class
 */
@IsTest
public inherited sharing class IPE_CreateGroup_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';
	static final String GROUP_NAME = 'BACBIS_MajorA_GROUPA_1';
	static final Integer GROUP_QTY = 12;

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

            testFactory.initMasterData(SPS_Helper.getApiName());
			testFactory.initStudentData(CON_Helper.getApiName(), false);

			Test.stopTest();
        }

    }

    /**
     * @description Test as admin that group records are created after an IPE record is inserted
     */
    @IsTest
    static void testCreateIpsgAfterIpeInsertAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		User adminUser = testFactory.getReduAdminUser();
		List<Contact> studentCon = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		// Verify pre-test conditions: no IPS-Group records exist
		List<reduivy__Individual_Plan_Structure__c> ipsgList = [
			SELECT Id
			FROM reduivy__Individual_Plan_Structure__c
			WHERE RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
		];
		System.Assert.isTrue(
			ipsgList.isEmpty(),
			'There should not yet be any IPS-Group records'
		);

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
		System.runAs(adminUser) {

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
		Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
			SELECT Id, reduivy__Study_Plan__c
			FROM reduivy__Individual_Program_Enrollment__c
			WHERE reduivy__Sample_Record_Code__c LIKE '%IPE_CreateGroup_TEST-%'
		]);
		System.Assert.isFalse(
			ipeList.isEmpty(),
			'There should be a list of IPE records'
		);
		ipsgList = [
			SELECT 	Id, 
					reduivy__Study_Plan_Structure__r.Name,
					reduivy__Category__c, 
					reduivy__Credits__c, reduivy__Max_Credits__c,
					reduivy__Individual_Program_Enrollment__c,
					reduivy__Study_Plan_Structure__c,
					reduivy__Parent_Plan_Structure__c,
					reduivy__Parent_Plan_Structure__r.reduivy__Study_Plan_Structure__r.Name
			FROM reduivy__Individual_Plan_Structure__c
			WHERE RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
			AND reduivy__Study_Plan_Structure__r.reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN
		];
		System.Assert.areEqual(
			GROUP_QTY * ipeList.size(),
			ipsgList.size(),
			'The actual value should be as expected'
		);
		Map<Id, Map<String, reduivy__Individual_Plan_Structure__c>> ipsgMap = new Map<Id, Map<String, reduivy__Individual_Plan_Structure__c>>();
		for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {
			if (!ipsgMap.containsKey(ipsg.Id)) {
				ipsgMap.put(ipsg.Id, new Map<String, reduivy__Individual_Plan_Structure__c>());
			}
			ipsgMap.get(ipsg.Id).put(ipsg.reduivy__Study_Plan_Structure__r.Name, ipsg);
		}
		Integer ipsgCount = 0;
		for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {
			if (ipsg.reduivy__Study_Plan_Structure__r.Name.equals(GROUP_NAME)) {
				System.Assert.isTrue(
					ipeMap.containsKey(ipsgMap.get(ipsg.Id).get(GROUP_NAME).reduivy__Individual_Program_Enrollment__c),
					'The actual value should be as expected'
				);
				System.Assert.areEqual(
					'Required',
					ipsgMap.get(ipsg.Id).get(GROUP_NAME).reduivy__Category__c,
					'The actual value should be as expected'
				);
				System.Assert.areEqual(
					60.0000,
					ipsgMap.get(ipsg.Id).get(GROUP_NAME).reduivy__Credits__c,
					'The actual value should be as expected'
				);
				System.Assert.areEqual(
					'BACBIS_MajorA_GROUPA',
					ipsgMap.get(ipsg.Id).get(GROUP_NAME).reduivy__Parent_Plan_Structure__r.reduivy__Study_Plan_Structure__r.Name,
					'The actual value should be as expected'
				);
				++ipsgCount;
			}
		}
		System.Assert.areEqual(
			ipeList.size(),
			ipsgCount,
			'The actual value should be as expected'
		);
	}

    /**
     * @description Test as admin that group records are created after an IPE record is updated
     */
    @IsTest
    static void testCreateIpsgAfterIpeUpdateAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		User adminUser = testFactory.getReduAdminUser();
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

		List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
		List<reduivy__Individual_Plan_Structure__c> ipsgList = new List<reduivy__Individual_Plan_Structure__c>();

		Test.startTest();

		// Execute test
		System.runAs(adminUser) {

			// Create individual program enrollment records
			List<String> ipeDraftStatuses = IPE_Helper.getDraftStatuses();
			
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

			// Verify pre-test conditions: no IPS-Group records exist
			ipsgList = [SELECT Id
						FROM reduivy__Individual_Plan_Structure__c
						WHERE RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
			];

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
			WHERE reduivy__Sample_Record_Code__c LIKE '%IPE_CreateGroup_TEST-%'
		]);
		System.Assert.isFalse(
			ipeList.isEmpty(),
			'There should be a list of IPE records'
		);
		ipsgList = [
			SELECT 	Id, 
					reduivy__Study_Plan_Structure__r.Name,
					reduivy__Category__c, 
					reduivy__Credits__c, reduivy__Max_Credits__c,
					reduivy__Individual_Program_Enrollment__c,
					reduivy__Study_Plan_Structure__c,
					reduivy__Parent_Plan_Structure__c,
					reduivy__Parent_Plan_Structure__r.reduivy__Study_Plan_Structure__r.Name
			FROM reduivy__Individual_Plan_Structure__c
			WHERE RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
			AND reduivy__Study_Plan_Structure__r.reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN
		];
		System.Assert.areEqual(
			GROUP_QTY * ipeList.size(),
			ipsgList.size(),
			'The actual value should be as expected'
		);
		Map<Id, Map<String, reduivy__Individual_Plan_Structure__c>> ipsgMap = new Map<Id, Map<String, reduivy__Individual_Plan_Structure__c>>();
		for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {
			if (!ipsgMap.containsKey(ipsg.Id)) {
				ipsgMap.put(ipsg.Id, new Map<String, reduivy__Individual_Plan_Structure__c>());
			}
			ipsgMap.get(ipsg.Id).put(ipsg.reduivy__Study_Plan_Structure__r.Name, ipsg);
		}
		Integer ipsgCount = 0;
		for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {
			if (ipsg.reduivy__Study_Plan_Structure__r.Name.equals(GROUP_NAME)) {
				System.Assert.isTrue(
					ipeMap.containsKey(ipsgMap.get(ipsg.Id).get(GROUP_NAME).reduivy__Individual_Program_Enrollment__c),
					'The actual value should be as expected'
				);
				System.Assert.areEqual(
					'Required',
					ipsgMap.get(ipsg.Id).get(GROUP_NAME).reduivy__Category__c,
					'The actual value should be as expected'
				);
				System.Assert.areEqual(
					60.0000,
					ipsgMap.get(ipsg.Id).get(GROUP_NAME).reduivy__Credits__c,
					'The actual value should be as expected'
				);
				System.Assert.areEqual(
					'BACBIS_MajorA_GROUPA',
					ipsgMap.get(ipsg.Id).get(GROUP_NAME).reduivy__Parent_Plan_Structure__r.reduivy__Study_Plan_Structure__r.Name,
					'The actual value should be as expected'
				);
				++ipsgCount;
			}
		}
		System.Assert.areEqual(
			ipeList.size(),
			ipsgCount,
			'The actual value should be as expected'
		);
	}
}