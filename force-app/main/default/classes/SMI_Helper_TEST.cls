/**
 * @author      WDCi (Lean)
 * @date        July 2024
 * @group       Test
 * @description Test class for SMX_Helper
 * @changehistory
 * ISS-001992 09-07-2024 new class
 */
@IsTest
public inherited sharing class SMI_Helper_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    @TestSetup
    static void makeData(){
        testFactory.setupDefaultSettings();
        
    }

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Fee_Matrix_Item__c.getLabel(), SMI_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Fee_Matrix_Item__c.getLabelPlural(), SMI_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Fee_Matrix_Item__c.getName(), SMI_Helper.getApiName());

        Test.stopTest();
        
    }
	
}