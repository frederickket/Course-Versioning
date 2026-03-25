/**
 * @author      WDCi (Lean)
 * @date        March 2023
 * @group       Test
 * @description Test class for REDU_TriggerManager
 * @changehistory
 * ISS-001591 30-03-2023 Lean - new class
 */
@IsTest
public inherited sharing class REDU_TriggerManager_TEST {

    @TestSetup
    static void makeData(){
        // Create settings
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
		testFactory.setupDefaultSettings();
    }

    /**
     * @description Test trigger manager
     */
    @IsTest
    static void testManager(){
        
        Test.startTest();
        REDU_TestData_FACTORY factory = new REDU_TestData_FACTORY();
        List<Account> newAccounts = factory.initSampleAccount(10);
            
        insert newAccounts;

        List<Log__c> testLogs = [SELECT Id, Name, Reference__c FROM Log__c];
        //before insert + after insert
        Integer beforeInsertCount = 0;
        Integer afterInsertCount = 0;

        for (Log__c log : testLogs) {
            if (log.Reference__c == 'BeforeInsert') {
                beforeInsertCount ++;
            } else if (log.Reference__c == 'AfterInsert') {
                afterInsertCount ++;
            }
        }

        System.Assert.areEqual(10, beforeInsertCount);
        System.Assert.areEqual(10, afterInsertCount);

        Test.stopTest();
        
    }
}