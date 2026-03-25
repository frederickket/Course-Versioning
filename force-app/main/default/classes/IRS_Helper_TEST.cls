/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Test
 * @description Test class for IRS_Helper
 * @changehistory
 * ISS-002128 18-06-2025 XW - create new class
 */
@IsTest
public inherited sharing class IRS_Helper_TEST {

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Requirement_Set__c.getLabel(), IRS_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Requirement_Set__c.getLabelPlural(), IRS_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Requirement_Set__c.getName(), IRS_Helper.getApiName());

        Test.stopTest();
        
    }
	
}