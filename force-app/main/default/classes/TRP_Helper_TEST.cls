/**
 * @author      WDCi (Lean)
 * @date        Feb 2024
 * @group       Test
 * @description Test class for TRP_Helper
 * @changehistory
 * ISS-001857 05-02-2024 new class
 */
@IsTest
public inherited sharing class TRP_Helper_TEST {

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Transaction_Payment__c.getLabel(), TRP_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Transaction_Payment__c.getLabelPlural(), TRP_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Transaction_Payment__c.getName(), TRP_Helper.getApiName());

        Test.stopTest();
        
    }
	
}