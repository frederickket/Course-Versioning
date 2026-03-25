/**
 * @author      WDCi (Lean)
 * @date        July 2024
 * @group       Test
 * @description Test class for SFE_Helper
 * @changehistory
 * ISS-001992 09-07-2024 new class
 */
@IsTest
public inherited sharing class SFE_Helper_TEST {


    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Fee__c.getLabel(), SFE_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Fee__c.getLabelPlural(), SFE_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Fee__c.getName(), SFE_Helper.getApiName());

        Test.stopTest();
        
    }
	
}