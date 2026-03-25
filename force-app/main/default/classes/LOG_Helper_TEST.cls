/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Test
 * @description Test class for LOG_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class LOG_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Log__c.getLabel(), LOG_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Log__c.getLabelPlural(), LOG_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Log__c.getName(), LOG_Helper.getApiName());

        Test.stopTest();
        
    }
}