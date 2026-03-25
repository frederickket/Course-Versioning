/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Test
 * @description Test class for SPL_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class SPL_Helper_TEST {

    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Plan__c.getLabel(), SPL_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Plan__c.getLabelPlural(), SPL_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Plan__c.getName(), SPL_Helper.getApiName());

        Test.stopTest();
        
    }
}