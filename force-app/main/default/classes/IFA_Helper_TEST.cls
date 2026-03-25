/**
 * @author      WDCi (Lean)
 * @date        Feb 2024
 * @group       Test
 * @description Test class for IFA_Helper
 * @changehistory
 * ISS-001857 05-02-2024 new class
 */
@IsTest
public inherited sharing class IFA_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Funding_Allocation__c.getLabel(), IFA_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Funding_Allocation__c.getLabelPlural(), IFA_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Funding_Allocation__c.getName(), IFA_Helper.getApiName());

        Test.stopTest();
        
    }
	
}