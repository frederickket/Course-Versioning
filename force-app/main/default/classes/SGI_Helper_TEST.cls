/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for SGI_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class SGI_Helper_TEST {

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Grade_Item__c.getLabel(), SGI_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Grade_Item__c.getLabelPlural(), SGI_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Grade_Item__c.getName(), SGI_Helper.getApiName());

        Test.stopTest();
        
    }
}