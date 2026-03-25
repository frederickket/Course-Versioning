/**
 * @author      WDCi (XW)
 * @date        Jan 2026
 * @group       Test
 * @description Test class for ARU_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class ARU_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Agreement_Recognition_Unit__c.getLabel(), ARU_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Agreement_Recognition_Unit__c.getLabelPlural(), ARU_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Agreement_Recognition_Unit__c.getName(), ARU_Helper.getApiName());

        Test.stopTest();
        
    }
	
}