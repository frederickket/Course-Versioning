/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Test
 * @description Test class for SIT_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class SIT_Helper_TEST {

    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Intake__c.getLabel(), SIT_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Intake__c.getLabelPlural(), SIT_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Intake__c.getName(), SIT_Helper.getApiName());

        Test.stopTest();
        
    }
    
}