/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for IPF_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class IPF_Helper_TEST {
    
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
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Academic_Profile__c.getLabel(), IPF_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Academic_Profile__c.getLabelPlural(), IPF_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Academic_Profile__c.getName(), IPF_Helper.getApiName());

        Test.stopTest();
        
    }
}