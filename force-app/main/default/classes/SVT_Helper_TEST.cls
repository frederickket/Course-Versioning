/**
 * @author      WDCi (Lean)
 * @date        July 2024
 * @group       Test
 * @description Test class for SVT_Helper
 * @changehistory
 * ISS-001992 15-07-2024 new class
 */
@IsTest
public inherited sharing class SVT_Helper_TEST {

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Voucher_Transaction__c.getLabel(), SVT_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Voucher_Transaction__c.getLabelPlural(), SVT_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Voucher_Transaction__c.getName(), SVT_Helper.getApiName());

        Test.stopTest();
        
    }
	
}