/**
 * @author      WDCi (Lean)
 * @date        Sept 2025
 * @group       Test
 * @description Test class for ADP_Helper
 * @changehistory
 * ISS-002497 24-09-2025 Lean - New admission option data model
 */
@IsTest
public inherited sharing class ADP_Helper_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    @TestSetup
    static void makeData(){
        // Create settings
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(null);

            Test.stopTest();
		}
    }

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Admission_Path__c.getLabel(), ADP_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Admission_Path__c.getLabelPlural(), ADP_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Admission_Path__c.getName(), ADP_Helper.getApiName());
        System.Assert.areEqual('Name', ADP_Helper.getTranslationFieldNameForName());
        Test.stopTest();
        
    }
    
}