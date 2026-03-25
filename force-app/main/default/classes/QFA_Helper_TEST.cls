/**
 * @author      WDCi (Lean)
 * @date        May 2024
 * @group       Test
 * @description Test class for QFA_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class QFA_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Qualified_Faculty__c.getLabel(), QFA_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Qualified_Faculty__c.getLabelPlural(), QFA_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Qualified_Faculty__c.getName(), QFA_Helper.getApiName());

        Test.stopTest();
        
    }
}