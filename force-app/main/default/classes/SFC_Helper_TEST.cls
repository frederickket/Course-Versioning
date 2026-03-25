/**
 * @author      WDCi (Lean)
 * @date        July 2024
 * @group       Test
 * @description Test class for SFC_Helper
 * @changehistory
 * ISS-001992 09-07-2024 new class
 */
@IsTest
public inherited sharing class SFC_Helper_TEST {


    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Fee_Config__c.getLabel(), SFC_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Fee_Config__c.getLabelPlural(), SFC_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Fee_Config__c.getName(), SFC_Helper.getApiName());

        Test.stopTest();
        
    }
	
}