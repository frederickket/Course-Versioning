/**
 * @author      WDCi (dblack)
 * @date        Nov 2023
 * @group       Test
 * @description Test class for AUE_CheckStudyUnitCode_EXE
 * @changehistory
 * ISS-001659 09-11-2023 dblack - new class
 */
@IsTest
public inherited sharing class AUE_CheckStudyUnitCode_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

	static final Integer AGR_QTY = 10; // Agreement
	static final Integer AUE_QTY = 10; // Agreement unit equivalent
    static final Integer SUN_QTY = 10; // Study unit
	
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

			testFactory.initMasterData(SUN_Helper.getApiName());
			testFactory.initStudentData(IAC_Helper.getApiName(), true);

			// Create agreement records
			List<reduivy__Agreement__c> agrList = new List<reduivy__Agreement__c>();
			for (Integer i = 0; i < AGR_QTY; i++) {

				String sampleRecordCode = null;
				Id educationalInstitutionId = null;
				Id externalEducationalInstitutionId = null;
				String name = 'AGR-' + String.valueOf(i);
				Date startDate = null;
				Date endDate = null;
				String status = null;
				String type = null;

				reduivy__Agreement__c agr = REDU_TestData_UTIL.newAgreement(
					sampleRecordCode, 
					educationalInstitutionId, 
					externalEducationalInstitutionId,
					name, 
					startDate, 
					endDate, 
					status, 
					type
				);

				agrList.add(agr);
			}

			insert agrList;

			Test.stopTest();
		}
    }

    /**
     * @description Test as admin that an error is not thrown when the study unit record does exist after insert
     */
    @IsTest
    static void testWhenStudyUnitDoesExistAfterInsertAsAdminUser() {
		User ADMIN_USER = testFactory.getReduAdminUser();

		// Setup test data

		// Get study unit codes that do have study unit records
		Set<String> sunCodeSet = new Set<String>();
		List<reduivy__Study_Unit__c> sunList = [
			SELECT reduivy__Unit_Code__c
			FROM reduivy__Study_Unit__c
			LIMIT :SUN_QTY
		];

		System.Assert.isFalse(
			sunList.isEmpty(),
			'The actual value should be as expected'
		);

		for (reduivy__Study_Unit__c sun : sunList) {
			sunCodeSet.add(sun.reduivy__Unit_Code__c);
		}
		
		// Create the agreement unit equivalent records
		List<reduivy__Agreement_Unit_Equivalent__c> aueList = new List<reduivy__Agreement_Unit_Equivalent__c>();
		List<reduivy__Agreement__c> agrList = [
			SELECT Id FROM reduivy__Agreement__c LIMIT :AGR_QTY
		];
		for (reduivy__Agreement__c agr : agrList) {
			for (Integer i = 0; i < AUE_QTY; i++) {

				String sampleRecordCode = null;
				Id agreementId = agr.Id;
				String originUnitName = null;
				Set<String> originUnitCodes = new Set<String>();
				Set<String> targetUnitCodes = sunCodeSet;
				String status = null;
				String type = null;

				reduivy__Agreement_Unit_Equivalent__c aue = REDU_TestData_UTIL.newAgreementUnitEquivalent(
					sampleRecordCode,
					agreementId,
					originUnitName,
					originUnitCodes,
					targetUnitCodes,
					status,
					type
				);

				aueList.add(aue);
			}
		}
		
		System.runAs(ADMIN_USER) {

			// Execute test
			Test.startTest();
			try {
				insert aueList;

			} catch (Exception e) {

				System.Assert.fail('An exception should not have been thrown: ' + e.getMessage());
			}
			Test.stopTest();
		}
	}

    /**
     * @description Test as admin that an error is thrown when the study unit record does not exist after insert
     */
    @IsTest
    static void testWhenStudyUnitDoesNotExistAfterInsertAsAdminUser() {
		User ADMIN_USER = testFactory.getReduAdminUser();

		// Setup test data

		// Create study unit codes that do not have study unit records
		Set<String> sunCodeSet = new Set<String>();
		for (Integer i = 0; i < SUN_QTY; i++) {
			sunCodeSet.add('SUN-' + String.valueOf(i));
		}
		
		// Create the agreement unit equivalent records
		List<reduivy__Agreement_Unit_Equivalent__c> aueList = new List<reduivy__Agreement_Unit_Equivalent__c>();
		List<reduivy__Agreement__c> agrList = [
			SELECT Id FROM reduivy__Agreement__c LIMIT :AGR_QTY
		];
		for (reduivy__Agreement__c agr : agrList) {
			for (Integer i = 0; i < AUE_QTY; i++) {

				String sampleRecordCode = null;
				Id agreementId = agr.Id;
				String originUnitName = null;
				Set<String> originUnitCodes = new Set<String>();
				Set<String> targetUnitCodes = sunCodeSet;
				String status = null;
				String type = null;

				reduivy__Agreement_Unit_Equivalent__c aue = REDU_TestData_UTIL.newAgreementUnitEquivalent(
					sampleRecordCode,
					agreementId,
					originUnitName,
					originUnitCodes,
					targetUnitCodes,
					status,
					type
				);

				aueList.add(aue);
			}
		}
		
		System.runAs(ADMIN_USER) {

			// Execute test
			Test.startTest();
			try {
				insert aueList;
				System.Assert.fail('An exception should have been thrown');

			} catch (Exception e) {

				List<String> paramList = new List<String>{SUN_Helper.getObjectLabel(), String.join(sunCodeSet, ', ')};
				String expectedMsg = String.format(Label.Invalid_Study_Unit_Codes, paramList);

				System.Assert.isTrue(
					e.getMessage().contains(expectedMsg),
					'Invalid message: ' + e.getMessage()
				);
			}
			Test.stopTest();
		}
	}

    /**
     * @description Test as admin that an error is not thrown when the study unit record does exist after update
     */
    @IsTest
    static void testWhenStudyUnitDoesExistAfterUpdateAsAdminUser() {
		User ADMIN_USER = testFactory.getReduAdminUser();

		// Get study unit codes that do have study unit records
		Set<String> sunCodeSet = new Set<String>();
		List<reduivy__Study_Unit__c> sunList = [
			SELECT reduivy__Unit_Code__c
			FROM reduivy__Study_Unit__c
			ORDER BY reduivy__Unit_Code__c ASC
			LIMIT :SUN_QTY
		];
		System.Assert.isFalse(
			sunList.isEmpty(),
			'The actual value should be as expected'
		);
		for (reduivy__Study_Unit__c sun : sunList) {
			sunCodeSet.add(sun.reduivy__Unit_Code__c);
		}
		
		// Create the agreement unit equivalent records
		List<reduivy__Agreement_Unit_Equivalent__c> aueList = new List<reduivy__Agreement_Unit_Equivalent__c>();
		List<reduivy__Agreement__c> agrList = [
			SELECT Id FROM reduivy__Agreement__c LIMIT :AGR_QTY
		];
		for (reduivy__Agreement__c agr : agrList) {
			for (Integer i = 0; i < AUE_QTY; i++) {

				String sampleRecordCode = null;
				Id agreementId = agr.Id;
				String originUnitName = null;
				Set<String> originUnitCodes = new Set<String>();
				Set<String> targetUnitCodes = sunCodeSet;
				String status = null;
				String type = null;

				reduivy__Agreement_Unit_Equivalent__c aue = REDU_TestData_UTIL.newAgreementUnitEquivalent(
					sampleRecordCode,
					agreementId,
					originUnitName,
					originUnitCodes,
					targetUnitCodes,
					status,
					type
				);

				aueList.add(aue);
			}
		}

		insert aueList;

		// Update the agreement unit equivalent records with study unit codes that do have study unit records
		sunCodeSet.clear();
		sunList = [
			SELECT reduivy__Unit_Code__c
			FROM reduivy__Study_Unit__c
			ORDER BY reduivy__Unit_Code__c DESC
			LIMIT :SUN_QTY
		];
		for (reduivy__Study_Unit__c sun : sunList) {
			sunCodeSet.add(sun.reduivy__Unit_Code__c);
		}
		for (reduivy__Agreement_Unit_Equivalent__c aue : aueList) {
			aue.reduivy__Target_Unit_Codes__c = String.join(sunCodeSet, ';');
		}
		
		System.runAs(ADMIN_USER) {

			// Execute test
			Test.startTest();
			try {
				update aueList;

			} catch (Exception e) {

				System.Assert.fail('An exception should not have been thrown: ' + e.getMessage());
			}
			Test.stopTest();
		}
	}

    /**
     * @description Test as admin that an error is thrown when the study unit record does not exist after update
     */
    @IsTest
    static void testWhenStudyUnitDoesNotExistAfterUpdateAsAdminUser() {
		User ADMIN_USER = testFactory.getReduAdminUser();
		
		// Setup test data

		// Get study unit codes that do have study unit records
		Set<String> sunCodeSet = new Set<String>();
		List<reduivy__Study_Unit__c> sunList = [
			SELECT reduivy__Unit_Code__c
			FROM reduivy__Study_Unit__c
			ORDER BY reduivy__Unit_Code__c ASC
			LIMIT :SUN_QTY
		];

		System.Assert.isFalse(
			sunList.isEmpty(),
			'The actual value should be as expected'
		);

		for (reduivy__Study_Unit__c sun : sunList) {
			sunCodeSet.add(sun.reduivy__Unit_Code__c);
		}
		
		// Create the agreement unit equivalent records
		List<reduivy__Agreement_Unit_Equivalent__c> aueList = new List<reduivy__Agreement_Unit_Equivalent__c>();
		List<reduivy__Agreement__c> agrList = [
			SELECT Id FROM reduivy__Agreement__c LIMIT :AGR_QTY
		];
		for (reduivy__Agreement__c agr : agrList) {
			for (Integer i = 0; i < AUE_QTY; i++) {

				String sampleRecordCode = null;
				Id agreementId = agr.Id;
				String originUnitName = null;
				Set<String> originUnitCodes = new Set<String>();
				Set<String> targetUnitCodes = sunCodeSet;
				String status = null;
				String type = null;

				reduivy__Agreement_Unit_Equivalent__c aue = REDU_TestData_UTIL.newAgreementUnitEquivalent(
					sampleRecordCode,
					agreementId,
					originUnitName,
					originUnitCodes,
					targetUnitCodes,
					status,
					type
				);

				aueList.add(aue);
			}
		}

		insert aueList;

		// Update the agreement unit equivalent records with study unit codes that don't have study unit records
		sunCodeSet.clear();
		for (Integer i = 0; i < SUN_QTY; i++) {
			sunCodeSet.add('SUN-' + String.valueOf(i));
		}
		for (reduivy__Agreement_Unit_Equivalent__c aue : aueList) {
			aue.reduivy__Target_Unit_Codes__c = String.join(sunCodeSet, ';');
		}
		
		System.runAs(ADMIN_USER) {

			// Execute test
			Test.startTest();
			try {
				update aueList;
				System.Assert.fail('An exception should have been thrown');

			} catch (Exception e) {

				List<String> paramList = new List<String>{SUN_Helper.getObjectLabel(), String.join(sunCodeSet, ', ')};
				String expectedMsg = String.format(Label.Invalid_Study_Unit_Codes, paramList);

				System.Assert.isTrue(
					e.getMessage().contains(expectedMsg),
					'Invalid message: ' + e.getMessage()
				);
			}
			Test.stopTest();
		}
	}
}