/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Test 
 * @description Test class for SRQ_Helper
 * @changehistory
 * ISS-002128 18-06-2025 XW - create new class
 */
@IsTest
public inherited sharing class SRQ_Helper_TEST {

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Requirement__c.getLabel(), SRQ_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Requirement__c.getLabelPlural(), SRQ_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Requirement__c.getName(), SRQ_Helper.getApiName());

        Test.stopTest();
        
    }
	
}