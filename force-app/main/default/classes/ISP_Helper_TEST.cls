/**
 * @author      WDCi (Lean)
 * @date        July 2025
 * @group       Test
 * @description Test class for ISP_Helper
 * @changehistory
 * ISS-002551 22-07-2025 Lean - new class
 */
@IsTest
public inherited sharing class ISP_Helper_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
	@TestSetup
    static void makeData(){
        
    }

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Success_Plan__c.getLabel(), ISP_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Success_Plan__c.getLabelPlural(), ISP_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Success_Plan__c.getName(), ISP_Helper.getApiName());
        System.Assert.areEqual('Name', ISP_Helper.getTranslationFieldNameForName());

        Test.stopTest();
        
    }

    /**
     * @description Test trigger coverage
     */
    @IsTest
    static void testTriggerCoverage() {
        
        Test.startTest();
        
        reduivy__Individual_Success_Plan__c newIsp = REDU_TestData_UTIL.newIndividualSuccessPlan(
            'Trigger_Test',
            null,
            null,
            'Trigger_Test',
            null,
            System.today(),
            System.today(),
            'Test Summary'
        );

        REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Success_Plan__c>{newIsp});

        Test.stopTest();

        List<reduivy__Individual_Success_Plan__c> ispList = [SELECT Id, Name FROM reduivy__Individual_Success_Plan__c WHERE Id = :newIsp.Id];
        System.Assert.areEqual(1, ispList.size(), 'Expected 1 record');
    }
	
}