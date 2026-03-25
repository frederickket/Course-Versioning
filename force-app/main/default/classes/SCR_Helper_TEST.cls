/**
 * @author      WDCi (XW)
 * @date        Aug 2025
 * @group       Test
 * @description Test class for SCR_Helper
 * @changehistory
 * 
 */
@isTest
public inherited sharing class SCR_Helper_TEST {
	
    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Scoring_Criteria__c.getLabel(), SCR_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Scoring_Criteria__c.getLabelPlural(), SCR_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Scoring_Criteria__c.getName(), SCR_Helper.getApiName());

        Test.stopTest();
        
    }
	
}