/**
 * @author      WDCi (Lean)
 * @date        Sept 2025
 * @group       Test
 * @description Test class for ARC_Helper
 * @changehistory
 * ISS-002497 24-09-2025 Lean - New admission option data model
 */
@IsTest
public inherited sharing class ARC_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Agreement_Recognition__c.getLabel(), ARC_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Agreement_Recognition__c.getLabelPlural(), ARC_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Agreement_Recognition__c.getName(), ARC_Helper.getApiName());
        System.Assert.areEqual('Name', ARC_Helper.getTranslationFieldNameForName());

        Test.stopTest();
        
    }
    
}