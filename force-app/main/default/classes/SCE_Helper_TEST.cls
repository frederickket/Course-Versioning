/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for SCE_Helper
 * @changehistory
 * 
 */
@isTest
public inherited sharing class SCE_Helper_TEST {
	
    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Cohort_Enrollment__c.getLabel(), SCE_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Cohort_Enrollment__c.getLabelPlural(), SCE_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Cohort_Enrollment__c.getName(), SCE_Helper.getApiName());

        Test.stopTest();
        
    }
	
}