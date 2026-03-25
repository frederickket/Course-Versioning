/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for SGS_helper
 * @changehistory
 * 
 */
@isTest
public inherited sharing class SGS_Helper_TEST {

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Grade_Setting__c.getLabel(), SGS_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Grade_Setting__c.getLabelPlural(), SGS_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Grade_Setting__c.getName(), SGS_Helper.getApiName());

        Test.stopTest();
        
    }
	
}