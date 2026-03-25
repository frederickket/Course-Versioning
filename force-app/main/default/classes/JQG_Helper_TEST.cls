/**
 * @author      WDCi (Lean)
 * @date        July 2025
 * @group       Test
 * @description Test class for JQG_Helper
 * @changehistory
 * ISS-002547 14-07-2025 Lean - new class
 */
@IsTest
public inherited sharing class JQG_Helper_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
	@TestSetup
    static void makeData(){
        
    }

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Job_Queue_Group__c.getLabel(), JQG_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Job_Queue_Group__c.getLabelPlural(), JQG_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Job_Queue_Group__c.getName(), JQG_Helper.getApiName());
        System.Assert.areEqual('Name', JQG_Helper.getTranslationFieldNameForName());

        Test.stopTest();
        
    }
	
}