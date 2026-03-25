/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for AGR_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class AGR_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Agreement__c.getLabel(), AGR_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Agreement__c.getLabelPlural(), AGR_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Agreement__c.getName(), AGR_Helper.getApiName());

        Test.stopTest();
        
    }
	
}