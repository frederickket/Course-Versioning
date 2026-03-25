/**
 * @author      WDCi (Lean)
 * @date        July 2024
 * @group       Test
 * @description Test class for SMX_Helper
 * @changehistory
 * ISS-001992 09-07-2024 new class
 */
@IsTest
public inherited sharing class SMX_Helper_TEST {

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Fee_Matrix__c.getLabel(), SMX_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Fee_Matrix__c.getLabelPlural(), SMX_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Fee_Matrix__c.getName(), SMX_Helper.getApiName());

        Test.stopTest();
        
    }
	
}