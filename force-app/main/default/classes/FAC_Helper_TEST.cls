/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Test
 * @description Test class for FAC_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class FAC_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Facility__c.getLabel(), FAC_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Facility__c.getLabelPlural(), FAC_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Facility__c.getName(), FAC_Helper.getApiName());

        Test.stopTest();
        
    }
}