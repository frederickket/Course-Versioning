/**
 * @author      WDCi (XW)
 * @date        Jan 2025
 * @group       Test
 * @description Test class for IAU_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class IAU_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Achievement_Unit__c.getLabel(), IAU_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Achievement_Unit__c.getLabelPlural(), IAU_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Achievement_Unit__c.getName(), IAU_Helper.getApiName());

        Test.stopTest();
        
    }
	
}