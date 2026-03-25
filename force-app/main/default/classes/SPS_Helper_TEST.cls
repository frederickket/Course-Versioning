/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Test
 * @description Test class for SPS_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class SPS_Helper_TEST {


    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Plan_Structure__c.getLabel(), SPS_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Plan_Structure__c.getLabelPlural(), SPS_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Plan_Structure__c.getName(), SPS_Helper.getApiName());

        Test.stopTest();
        
    }

    @IsTest
    static void testGetRecordTypes(){
        
        Test.startTest();
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.reduivy__Study_Plan_Structure__c.getRecordtypeInfosByDeveloperName();

        System.Assert.areEqual(rtMap.get('Group').getRecordTypeId(), SPS_Helper.getGroupRecordTypeId());
        System.Assert.areEqual(rtMap.get('Group').getName(), SPS_Helper.getGroupRecordTypeLabel());
        System.Assert.areEqual(rtMap.get('Unit').getRecordTypeId(), SPS_Helper.getUnitRecordTypeId());
        System.Assert.areEqual(rtMap.get('Unit').getName(), SPS_Helper.getUnitRecordTypeLabel());

        Test.stopTest();
        
    }
}