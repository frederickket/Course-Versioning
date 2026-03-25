/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Test
 * @description Test class for SUR_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class SUR_Helper_TEST {


    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Unit_Requirement__c.getLabel(), SUR_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Unit_Requirement__c.getLabelPlural(), SUR_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Unit_Requirement__c.getName(), SUR_Helper.getApiName());

        Test.stopTest();
        
    }
}