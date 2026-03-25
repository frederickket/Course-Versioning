/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for SPT_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class SPT_Helper_TEST {

    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Pathway_Term__c.getLabel(), SPT_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Pathway_Term__c.getLabelPlural(), SPT_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Pathway_Term__c.getName(), SPT_Helper.getApiName());

        Test.stopTest();
        
    }
}