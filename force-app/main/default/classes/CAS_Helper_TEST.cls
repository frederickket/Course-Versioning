/**
 * @author      WDCi (Lean)
 * @date        May 2024
 * @group       Test
 * @description Test class for CAS_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class CAS_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Contact_Association__c.getLabel(), CAS_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Contact_Association__c.getLabelPlural(), CAS_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Contact_Association__c.getName(), CAS_Helper.getApiName());

        Test.stopTest();
        
    }
}