/**
 * @author      WDCi (Lean)
 * @date        Sept 2025
 * @group       Test
 * @description Test class for SAP_Helper
 * @changehistory
 * ISS-002497 24-09-2025 Lean - New admission option data model
 */
@IsTest
public inherited sharing class SAP_Helper_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    @TestSetup
    static void makeData(){
        // Create settings
        testFactory.setupDefaultSettings();
    }

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Program_Admission_Path__c.getLabel(), SAP_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Program_Admission_Path__c.getLabelPlural(), SAP_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Program_Admission_Path__c.getName(), SAP_Helper.getApiName());
        System.Assert.areEqual('Name', SAP_Helper.getTranslationFieldNameForName());

        Test.stopTest();
        
    }
    
}