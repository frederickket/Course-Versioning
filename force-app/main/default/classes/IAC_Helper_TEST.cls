/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for IAC_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class IAC_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Achievement__c.getLabel(), IAC_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Achievement__c.getLabelPlural(), IAC_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Achievement__c.getName(), IAC_Helper.getApiName());

        Test.stopTest();
        
    }
	
}