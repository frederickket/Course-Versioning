/**
 * @author      WDCi (Lean)
 * @date        Sept 2025
 * @group       Test
 * @description Test class for ADO_Helper
 * @changehistory
 * ISS-002497 24-09-2025 Lean - New admission option data model
 */
@IsTest
public inherited sharing class ADO_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Admission_Path_Option__c.getLabel(), ADO_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Admission_Path_Option__c.getLabelPlural(), ADO_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Admission_Path_Option__c.getName(), ADO_Helper.getApiName());
        System.Assert.areEqual('Name', ADO_Helper.getTranslationFieldNameForName());

        Test.stopTest();
        
    }
    
}