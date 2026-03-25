/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Test
 * @description Test class for STM_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class STM_Helper_TEST {

    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Term__c.getLabel(), STM_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Term__c.getLabelPlural(), STM_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Term__c.getName(), STM_Helper.getApiName());

        Test.stopTest();
        
    }

    @IsTest
    static void testGetRecordTypes(){
        
        Test.startTest();
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.reduivy__Study_Term__c.getRecordtypeInfosByDeveloperName();

        System.Assert.areEqual(rtMap.get('Academic_Year').getRecordTypeId(), STM_Helper.getAcademicYearRecordTypeId());
        System.Assert.areEqual(rtMap.get('Academic_Year').getName(), STM_Helper.getAcademicYearRecordTypeLabel());
        System.Assert.areEqual(rtMap.get('Academic_Term').getRecordTypeId(), STM_Helper.getAcademicTermRecordTypeId());
        System.Assert.areEqual(rtMap.get('Academic_Term').getName(), STM_Helper.getAcademicTermRecordTypeLabel());

        Test.stopTest();
        
    }
}