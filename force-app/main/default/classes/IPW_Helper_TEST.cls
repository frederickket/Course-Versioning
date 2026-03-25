/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for IPW_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class IPW_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Pathway__c.getLabel(), IPW_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Pathway__c.getLabelPlural(), IPW_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Pathway__c.getName(), IPW_Helper.getApiName());

        Test.stopTest();
        
    }
	
}