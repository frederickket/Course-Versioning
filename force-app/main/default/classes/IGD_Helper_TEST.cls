/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for IGD_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class IGD_Helper_TEST {
    
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
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Enrollment_Grade__c.getLabel(), IGD_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Enrollment_Grade__c.getLabelPlural(), IGD_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Enrollment_Grade__c.getName(), IGD_Helper.getApiName());

        Test.stopTest();
        
    }
}