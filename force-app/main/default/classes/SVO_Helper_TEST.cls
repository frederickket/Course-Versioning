/**
 * @author      WDCi (Lean)
 * @date        July 2024
 * @group       Test
 * @description Test class for SVO_Helper
 * @changehistory
 * ISS-001992 09-07-2024 new class
 */
@IsTest
public inherited sharing class SVO_Helper_TEST {

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Voucher__c.getLabel(), SVO_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Voucher__c.getLabelPlural(), SVO_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Voucher__c.getName(), SVO_Helper.getApiName());

        Test.stopTest();
        
    }
	
}