/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for SGP_Helper
 * @changehistory
 * 
 */
@isTest
public inherited sharing class SGP_Helper_TEST {

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Grade_Period_Setting__c.getLabel(), SGP_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Grade_Period_Setting__c.getLabelPlural(), SGP_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Grade_Period_Setting__c.getName(), SGP_Helper.getApiName());

        Test.stopTest();
        
    }
	
}