/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for IUR_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class IUR_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Plan_Unit_Requirement__c.getLabel(), IUR_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Plan_Unit_Requirement__c.getLabelPlural(), IUR_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Plan_Unit_Requirement__c.getName(), IUR_Helper.getApiName());

        Test.stopTest();
        
    }
	
}