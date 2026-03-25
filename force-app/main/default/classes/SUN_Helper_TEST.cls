/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Test
 * @description Test class for SUN_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class SUN_Helper_TEST {

    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.getLabel(), SUN_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.getLabelPlural(), SUN_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.getName(), SUN_Helper.getApiName());

        Test.stopTest();
        
    }
}