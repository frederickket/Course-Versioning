/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for AUE_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class AUE_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Agreement_Unit_Equivalent__c.getLabel(), AUE_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Agreement_Unit_Equivalent__c.getLabelPlural(), AUE_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Agreement_Unit_Equivalent__c.getName(), AUE_Helper.getApiName());

        Test.stopTest();
        
    }
	
}