/**
 * @author      WDCi (Lean)
 * @date        Feb 2024
 * @group       Test
 * @description Test class for TRL_Helper
 * @changehistory
 * ISS-001857 05-02-2024 new class
 */
@IsTest
public inherited sharing class TRL_Helper_TEST {

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Transaction_Line_Item__c.getLabel(), TRL_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Transaction_Line_Item__c.getLabelPlural(), TRL_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Transaction_Line_Item__c.getName(), TRL_Helper.getApiName());

        Test.stopTest();
        
    }
	
}