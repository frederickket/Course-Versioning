/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_Map_UTIL
 * @changehistory
 * 
 */
@isTest
public inherited sharing class REDU_Map_TEST {
	
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    
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
        }
    }

	/**
     * @description Test Map Util method
     */
    @IsTest
    static void testParentChilMap(){

        List<reduivy__Study_Unit__c> suList = [SELECT Id, reduivy__Educational_Institution__c FROM reduivy__Study_Unit__c];

        System.Assert.areEqual(false, suList.isEmpty(), 'Failed to get list of Study Unit for testing');

        Test.startTest();

        Map<Id, List<SObject>> testResult = REDU_Map_UTIL.generateParentChilMap(suList, 'reduivy__Educational_Institution__c');

        Test.stopTest();

        System.Assert.areEqual(false, testResult.isEmpty(), 'ParentChilMap is not generated');

    }
}