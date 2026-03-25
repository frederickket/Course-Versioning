/**
 * @author      WDCi (Lean)
 * @date        July 2025
 * @group       Test
 * @description Test class for INO_Helper
 * @changehistory
 * ISS-002551 22-07-2025 Lean - new class
 */
@IsTest
public inherited sharing class INO_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Support_Note__c.getLabel(), INO_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Support_Note__c.getLabelPlural(), INO_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Support_Note__c.getName(), INO_Helper.getApiName());
        System.Assert.areEqual('Name', INO_Helper.getTranslationFieldNameForName());

        Test.stopTest();
        
    }

    /**
     * @description Test trigger coverage
     */
    @IsTest
    static void testTriggerCoverage() {
        
        Test.startTest();
        
        reduivy__Individual_Support_Note__c newIno = REDU_TestData_UTIL.newIndividualSupportNote(
            'Trigger_Test',
            null,
            null,
            null,
            'Trigger_Test',
            'Academic',
            System.today(),
            'Public',
            'Test Summary'
        );

        REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Support_Note__c>{newIno});

        Test.stopTest();

        List<reduivy__Individual_Support_Note__c> inoList = [SELECT Id, Name FROM reduivy__Individual_Support_Note__c WHERE Id = :newIno.Id];
        System.Assert.areEqual(1, inoList.size(), 'Expected 1 record');
    }
	
}