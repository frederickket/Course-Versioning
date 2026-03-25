/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for CON_helper
 * @changehistory
 * 
 */
@isTest
public inherited sharing class CON_Helper_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
		
    }
	
    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.Contact.getLabel(), CON_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.Contact.getLabelPlural(), CON_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.Contact.getName(), CON_Helper.getApiName());

        Test.stopTest();
        
    }
	
}