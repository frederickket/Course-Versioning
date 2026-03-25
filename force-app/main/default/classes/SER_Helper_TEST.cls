/**
 * @author      WDCi (Lean)
 * @date        April 2023
 * @group       Test
 * @description Test class for SER_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class SER_Helper_TEST {

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Event_Relation__c.getLabel(), SER_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Event_Relation__c.getLabelPlural(), SER_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Event_Relation__c.getName(), SER_Helper.getApiName());

        Test.stopTest();
        
    }
	
}