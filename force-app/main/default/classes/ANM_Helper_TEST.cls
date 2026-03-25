/**
 * @author      WDCi (Lean)
 * @date        April 2023
 * @group       Test
 * @description Test class for ANM_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class ANM_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Announcement__c.getLabel(), ANM_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Announcement__c.getLabelPlural(), ANM_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Announcement__c.getName(), ANM_Helper.getApiName());

        Test.stopTest();
        
    }
	
}