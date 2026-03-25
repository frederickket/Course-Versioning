/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Test
 * @description Test class for LOG_PopulateLookupFields_EXE
 * @changehistory
 */
@IsTest
public inherited sharing class LOG_PopulateLookupFields_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    @TestSetup
    static void makeData(){
        
    }

    /**
     * @description Test populate lookup with valid record id
     */
    @IsTest
    static void testLogWithValidIds(){
        
        Test.startTest();
        
        Account acc = REDU_TestData_UTIL.newAdministrativeAccount(null, 'Test administrative');
        insert acc;

        reduivy__Log__c testLog = new reduivy__Log__c(
            Name = 'Test class',
            reduivy__Record_Id__c = acc.Id
        );

        insert testLog;

        System.Assert.areEqual(true, String.isNotBlank(testLog.Id));

        Test.stopTest();
        
    }

    /**
     * @description Test populate lookup with invalid record id
     */
    @IsTest
    static void testLogWithInvalidIds(){
        
        Test.startTest();
        
        reduivy__Log__c testLog = new reduivy__Log__c(
            Name = 'Test class',
            reduivy__Record_Id__c = 'invalidid'
        );

        insert testLog;

        System.Assert.areEqual(true, String.isNotBlank(testLog.Id));
        
        Test.stopTest();
        
    }

    /**
     * @description Test populate lookup with valid record id during update
     */
    @IsTest
    static void testLogWithUpdateValidIds(){
        
        Account acc = REDU_TestData_UTIL.newAdministrativeAccount(null, 'Test administrative');
        insert acc;

        reduivy__Log__c testLog = new reduivy__Log__c(
            Name = 'Test class',
            reduivy__Record_Id__c = 'invalidid'
        );

        insert testLog;

        Test.startTest();
        
        testLog.reduivy__Record_Id__c = acc.Id;
        update testLog;

        System.Assert.areEqual(true, String.isNotBlank(testLog.reduivy__Record_Id__c));

        Test.stopTest();
        
    }
}