/**
 * @author      WDCi (Lean)
 * @date        April 2023
 * @group       Test
 * @description Test class for SST_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class SST_Helper_TEST {



    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Session_Time__c.getLabel(), SST_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Session_Time__c.getLabelPlural(), SST_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Session_Time__c.getName(), SST_Helper.getApiName());

        Test.stopTest();
        
    }
	
}