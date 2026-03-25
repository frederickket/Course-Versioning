/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Test
 * @description Test class for SPU_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class SPU_Helper_TEST {
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Pathway_Unit__c.getLabel(), SPU_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Pathway_Unit__c.getLabelPlural(), SPU_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Pathway_Unit__c.getName(), SPU_Helper.getApiName());

        Test.stopTest();
        
    }
}