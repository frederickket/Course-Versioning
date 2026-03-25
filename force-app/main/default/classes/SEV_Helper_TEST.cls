/**
 * @author      WDCi (Lean)
 * @date        April 2023
 * @group       Test
 * @description Test class for SEV_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class SEV_Helper_TEST {

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Event__c.getLabel(), SEV_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Event__c.getLabelPlural(), SEV_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Event__c.getName(), SEV_Helper.getApiName());

        Test.stopTest();
        
    }
	
}