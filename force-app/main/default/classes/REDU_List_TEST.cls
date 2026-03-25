/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_List_UTIL
 * @changehistory
 * 
 */
@isTest
public inherited sharing class REDU_List_TEST {

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

            testFactory.initMasterData(SUN_Helper.getApiName());

            Test.stopTest();
        }
    }

    /**
     * @description Test List Util method
     */
    @IsTest
    static void testGetPageIterableList(){

        List<Id> suIdList = new List<Id>();
        for(reduivy__Study_Unit__c su : [SELECT Id FROM reduivy__Study_Unit__c]){
            suIdList.add(su.Id);
        }

        System.Assert.areEqual(false, suIdList.isEmpty(), 'Failed to get list of Study Unit for testing');

        Test.startTest();

        List<List<Id>> suIdPageIterable = REDU_List_UTIL.getPageIterable(suIdList, 5);

        Test.stopTest();

        System.Assert.areEqual(false, suIdPageIterable.isEmpty(), 'Missing list of page iterable Ids');

    }

    /**
     * @description Test Test List Util method
     */
    @IsTest
    static void testGetPageIterableSet(){

        Set<String> suIdSet = new Set<String>();
        for(reduivy__Study_Unit__c su : [SELECT Id FROM reduivy__Study_Unit__c]){
            suIdSet.add(su.Id);
        }

        System.Assert.areEqual(false, suIdSet.isEmpty(), 'Failed to get list of Study Unit for testing');

        Test.startTest();

        List<Set<String>> suIdPageIterable = REDU_List_UTIL.getPageIterable(suIdSet, 5);

        Test.stopTest();

        System.Assert.areEqual(false, suIdPageIterable.isEmpty(), 'Missing list of page iterable Ids');

    }
}