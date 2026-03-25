/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for SPO_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class SPO_Helper_TEST {

    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Plan_Option__c.getSObjectType(), SPO_Helper.getObjectType());
        System.Assert.areEqual(SObjectType.reduivy__Study_Plan_Option__c.getLabel(), SPO_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Plan_Option__c.getLabelPlural(), SPO_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Plan_Option__c.getName(), SPO_Helper.getApiName());

        Test.stopTest();
        
    }
}