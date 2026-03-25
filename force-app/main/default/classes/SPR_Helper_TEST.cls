/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Test
 * @description Test class for SPR_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class SPR_Helper_TEST {

    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Plan_Unit_Requirement__c.getLabel(), SPR_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Plan_Unit_Requirement__c.getLabelPlural(), SPR_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Plan_Unit_Requirement__c.getName(), SPR_Helper.getApiName());

        Test.stopTest();
        
    }
}