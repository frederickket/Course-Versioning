/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_License_BATCH
 * @changehistory
 * ISS-002574 04-08-2025 Lean - Decommission the applicant license type count
 */
@isTest
public inherited sharing class REDU_License_BATCH_TEST {

	/**
	 * @description Initialise test environment
	 */
	static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

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

			testFactory.initMasterData(ACC_Helper.getApiName());
			testFactory.initFacultyData(USR_Helper.getApiName(), true);
			testFactory.initStudentData(USR_Helper.getApiName(), true);

			Test.stopTest();
		}
	}

	/**
	 * @description Test admin license usage count
	 */
	@IsTest
	static void testAdminCount(){
		
		Test.startTest();
		
		REDU_License_BATCH batchJob = new REDU_License_BATCH(REDU_LicenseManagement_UTIL.ADMIN);
		Database.executeBatch(batchJob);

		Test.stopTest();
		
		System.Assert.areNotEqual(0, REDU_LicenseManagement_UTIL.getReduAdminLicensesUsed());
	}

	/**
	 * @description Test student license usage count
	 */
	@IsTest
	static void testStudentCount(){
		
		Test.startTest();
		
		REDU_License_BATCH batchJob = new REDU_License_BATCH(REDU_LicenseManagement_UTIL.STUDENT);
		Database.executeBatch(batchJob);

		Test.stopTest();
		
		System.Assert.areNotEqual(0, REDU_LicenseManagement_UTIL.getReduStudentLicensesUsed());
	}

	/**
	 * @description Test faculty license usage count
	 */
	@IsTest
	static void testFacultyCount(){
		
		Test.startTest();
		
		REDU_License_BATCH batchJob = new REDU_License_BATCH(REDU_LicenseManagement_UTIL.FACULTY);
		Database.executeBatch(batchJob);

		Test.stopTest();
		
		System.Assert.areNotEqual(0, REDU_LicenseManagement_UTIL.getReduFacultyLicensesUsed());
	}
}