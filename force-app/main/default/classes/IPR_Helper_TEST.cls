/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for IPR_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class IPR_Helper_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    @TestSetup
    static void makeData(){
        // Create settings
		testFactory.setupDefaultSettings();
        
    }

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Academic_Progress__c.getLabel(), IPR_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Academic_Progress__c.getLabelPlural(), IPR_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Academic_Progress__c.getName(), IPR_Helper.getApiName());

        Test.stopTest();
        
    }
}