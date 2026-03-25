/**
 * @author      WDCi (Lean)
 * @date        Jan 2025
 * @group       Test
 * @description Test class for IPA_Helper
 * @changehistory
 * ISS-002165 07-01-2025 Lean - new class
 */

@IsTest
public inherited sharing class IPA_Helper_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    @TestSetup
    static void makeData(){
        // Create settings
		testFactory.setupDefaultSettings();
        testFactory.initMasterData(null);
        
    }

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Program_Application__c.getLabel(), IPA_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Program_Application__c.getLabelPlural(), IPA_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Program_Application__c.getName(), IPA_Helper.getApiName());

        Test.stopTest();
        
    }

    /**
     * @description To cover Trigger_IndividualProgramApplication
     */
    @IsTest
    static void testInsertIPA(){
        
        Test.startTest();
        
        List<reduivy__Study_Program__c> studyProgram = [SELECT Id FROM reduivy__Study_Program__c LIMIT 1];

        Contact testCon = REDU_TestData_UTIL.newStudentContact('test', null, 'Test', 'Test', 'test@example.com', null);
        insert testCon;
        
        List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();

        ipaList.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = testCon.Id,
            reduivy__Study_Program__c = studyProgram[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_Helper.getSubmittedStatuses()[0]
        ));

        insert ipaList;

        Test.stopTest();

        List<reduivy__Individual_Program_Application__c> ipaResultList = [SELECT Id FROM reduivy__Individual_Program_Application__c WHERE Id = :ipaList[0].Id];
        System.Assert.areEqual(1, ipaResultList.size());
    }
}