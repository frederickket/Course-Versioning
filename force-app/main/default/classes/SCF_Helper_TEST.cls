/**
 * @author      WDCi (XW)
 * @date        Aug 2025
 * @group       Test
 * @description Test class for SCF_Helper
 * @changehistory
 * 
 */
@isTest
public inherited sharing class SCF_Helper_TEST {
	
    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Scoring_Config__c.getLabel(), SCF_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Scoring_Config__c.getLabelPlural(), SCF_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Scoring_Config__c.getName(), SCF_Helper.getApiName());

        Test.stopTest();
        
    }
	
}