/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Test
 * @description Test class for SPG_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class SPG_Helper_TEST {

    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Program__c.getLabel(), SPG_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Program__c.getLabelPlural(), SPG_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Program__c.getName(), SPG_Helper.getApiName());

        Test.stopTest();
        
    }
}