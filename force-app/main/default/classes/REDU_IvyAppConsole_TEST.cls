/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_IvyAppConsole_LCTRL
 * @changehistory
 * ISS-002574 04-08-2025 Lean - Decommission the applicant license type count
 */
@isTest
public inherited sharing class REDU_IvyAppConsole_TEST {



    /**
     * @description Test license job initiation
     */
	@IsTest
	static void testInitLicenseJob(){
		
		Test.startTest();
		
		REDU_LightningResponse response = REDU_IvyAppConsole_LCTRL.initLicenseJob();

		Test.stopTest();
		
		System.Assert.areEqual(true, response.isSuccess);
	}

    /**
	 * @description Test admin license usage count
	 */
	@IsTest
	static void testGetAdminLicenseInfo(){
		
		Test.startTest();
		
		REDU_LightningResponse response = REDU_IvyAppConsole_LCTRL.getLicensesInfo(REDU_LicenseManagement_UTIL.ADMIN);
        Map<String, Object> licenseInfo = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

		Test.stopTest();
		
		System.Assert.areEqual(true, licenseInfo.containsKey('totalLicenses'));
        System.Assert.areEqual(true, licenseInfo.containsKey('usedLicenses'));
	}

    /**
	 * @description Test student license usage count
	 */
	@IsTest
	static void testGetStudentLicenseInfo(){
		
		Test.startTest();
		
		REDU_LightningResponse response = REDU_IvyAppConsole_LCTRL.getLicensesInfo(REDU_LicenseManagement_UTIL.STUDENT);
        Map<String, Object> licenseInfo = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

		Test.stopTest();
		
		System.Assert.areEqual(true, licenseInfo.containsKey('totalLicenses'));
        System.Assert.areEqual(true, licenseInfo.containsKey('usedLicenses'));
	}

    /**
	 * @description Test faculty license usage count
	 */
	@IsTest
	static void testGetFacultyLicenseInfo(){
		
		Test.startTest();
		
		REDU_LightningResponse response = REDU_IvyAppConsole_LCTRL.getLicensesInfo(REDU_LicenseManagement_UTIL.FACULTY);
        Map<String, Object> licenseInfo = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

		Test.stopTest();
		
		System.Assert.areEqual(true, licenseInfo.containsKey('totalLicenses'));
        System.Assert.areEqual(true, licenseInfo.containsKey('usedLicenses'));
	}
}