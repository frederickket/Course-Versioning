/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Test 
 * @description Test class for SRS_Helper
 * @changehistory
 * ISS-002128 18-06-2025 XW - create new class
 */
@IsTest
public inherited sharing class SRS_Helper_TEST {

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Requirement_Set__c.getLabel(), SRS_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Requirement_Set__c.getLabelPlural(), SRS_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Requirement_Set__c.getName(), SRS_Helper.getApiName());

        Test.stopTest();
        
    }
	
}