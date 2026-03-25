/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Test
 * @description Test class for SPW_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class SPW_Helper_TEST {

    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Pathway__c.getSObjectType(), SPW_Helper.getObjectType());
        System.Assert.areEqual(SObjectType.reduivy__Study_Pathway__c.getLabel(), SPW_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Pathway__c.getLabelPlural(), SPW_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Pathway__c.getName(), SPW_Helper.getApiName());

        Test.stopTest();
        
    }
}