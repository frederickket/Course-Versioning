/**
 * @author      WDCi (Lean)
 * @date        May 2024
 * @group       Test
 * @description Test class for FVA_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class FAV_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Facility_Availability__c.getLabel(), FAV_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Facility_Availability__c.getLabelPlural(), FAV_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Facility_Availability__c.getName(), FAV_Helper.getApiName());

        Test.stopTest();
        
    }
}