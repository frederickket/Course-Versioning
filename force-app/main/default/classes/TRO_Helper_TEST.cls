/**
 * @author      WDCi (Lean)
 * @date        Feb 2024
 * @group       Test
 * @description Test class for TRO_Helper
 * @changehistory
 * ISS-001857 05-02-2024 new class
 */
@IsTest
public inherited sharing class TRO_Helper_TEST {

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Transaction_Order__c.getLabel(), TRO_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Transaction_Order__c.getLabelPlural(), TRO_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Transaction_Order__c.getName(), TRO_Helper.getApiName());

        Test.stopTest();
        
    }
	
}