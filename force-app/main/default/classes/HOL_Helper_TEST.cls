/**
 * @author      WDCi (Lean)
 * @date        April 2023
 * @group       Test
 * @description Test class for HOL_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class HOL_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Holiday__c.getLabel(), HOL_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Holiday__c.getLabelPlural(), HOL_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Holiday__c.getName(), HOL_Helper.getApiName());

        Test.stopTest();
        
    }
	
}