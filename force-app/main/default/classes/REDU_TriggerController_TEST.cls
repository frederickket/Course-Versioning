/**
 * @author      WDCi (Lean)
 * @date        March 2023
 * @group       Test
 * @description Test class for REDU_TriggerController
 * @changehistory
 * ISS-001591 30-03-2023 Lean - new class
 */
@IsTest
public inherited sharing class REDU_TriggerController_TEST {

    @TestSetup
    static void makeData(){
        // Create settings
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
		testFactory.setupDefaultSettings();
    }
    
    /**
     * @description Test for all trigger events
     */
    @IsTest
    static void testTriggerExecutionForAllEvents(){
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();
            List<Account> newAccounts = testFactory.initSampleAccount(10);

            insert newAccounts;
            update newAccounts;
            delete newAccounts;
            undelete newAccounts;

            List<Log__c> testLogs = [SELECT Id, Name, Reference__c FROM Log__c];
            
            Integer beforeInsertCount = 0;
            Integer afterInsertCount = 0;
            Integer beforeUpdateCount = 0;
            Integer afterUpdateCount = 0;
            Integer beforeDeleteCount = 0;
            Integer afterDeleteCount = 0;
            Integer afterUndeleteCount = 0;
            

            for (Log__c log : testLogs) {
                if (log.Reference__c == 'BeforeInsert') {
                    beforeInsertCount ++;
                } else if (log.Reference__c == 'AfterInsert') {
                    afterInsertCount ++;
                } else if (log.Reference__c == 'BeforeUpdate') {
                    beforeUpdateCount ++;
                } else if (log.Reference__c == 'AfterUpdate') {
                    afterUpdateCount ++;
                } else if (log.Reference__c == 'BeforeDelete') {
                    beforeDeleteCount ++;
                } else if (log.Reference__c == 'AfterDelete') {
                    afterDeleteCount ++;
                } else if (log.Reference__c == 'AfterUndelete') {
                    afterUndeleteCount ++;
                }
            }

            System.Assert.areEqual(10, beforeInsertCount);
            System.Assert.areEqual(10, afterInsertCount);
            System.Assert.areEqual(10, beforeUpdateCount);
            System.Assert.areEqual(10, afterUpdateCount);
            System.Assert.areEqual(10, beforeDeleteCount);
            System.Assert.areEqual(10, afterDeleteCount);
            System.Assert.areEqual(10, afterUndeleteCount);

            Test.stopTest();
        }
        
    }

    /**
     * @description Test trigger muting feature
     */
    @IsTest
    static void testTriggerMuting(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();
            REDU_TriggerController.muteTriggers(new Set<String>{'ACC_Sample_EXE'});

            List<Account> newAccounts = testFactory.initSampleAccount(10);
            insert newAccounts;

            REDU_TriggerController.unmuteTriggers(new Set<String>{'ACC_Sample_EXE'});

            update newAccounts;

            List<Log__c> testLogs = [SELECT Id, Name, Reference__c FROM Log__c];
            //before insert + after insert
            Integer insertCount = 0;
            Integer updateCount = 0;

            for (Log__c log : testLogs) {
                if (log.Reference__c.contains('Insert')) {
                    insertCount ++;
                } else if (log.Reference__c.contains('Update')) {
                    updateCount ++;
                }
            }

            System.Assert.areEqual(0, insertCount);
            System.Assert.areEqual(20, updateCount);

            Test.stopTest();
        }
        
    }

    /**
     * @description Test user exclusion by username
     */
    @IsTest
    static void testUserExclusion(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        User newAdmin = REDU_TestData_UTIL.newUser('AdminTestFirstname', 'AdminTestLastname', 'System Administrator');
        newAdmin.Username = 'AdminTestFirstname.AdminTestLastname@redu.example';
        insert newAdmin;

        System.runAs(newAdmin){
            List<Account> newAccounts = testFactory.initSampleAccount(10);
            insert newAccounts;
        }

        List<Log__c> testLogs = [SELECT Id, Name, Reference__c FROM Log__c];

        System.Assert.isTrue(testLogs.isEmpty());

        Test.stopTest();
        
    }

    /**
     * @description Test partials record exclusion for insert event
     */
    @IsTest
    static void testPartialRecordExclusionForInsert(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            List<Account> newAccounts = testFactory.initSampleAccount(10);

            Integer counter = 0;
            for (Account acc : newAccounts) {
                acc.Name = 'Skip Test Account';

                counter ++;

                if (counter > 4) {
                    break;
                }
            }

            insert newAccounts;

            List<Log__c> testLogs = [SELECT Id, Name, Reference__c FROM Log__c];

            Integer beforeInsertCount = 0;
            Integer afterInsertCount = 0;

            for (Log__c log : testLogs) {
                System.Assert.areNotEqual('Skip Test Account', log.Name);

                if (log.Reference__c == 'BeforeInsert') {
                    beforeInsertCount ++;
                } else if (log.Reference__c == 'AfterInsert') {
                    afterInsertCount ++;
                }
            }

            System.Assert.areEqual(5, beforeInsertCount);
            System.Assert.areEqual(5, afterInsertCount);

            Test.stopTest();
        }
        
    }

    /**
     * @description Test all records exclusion for insert event
     */
    @IsTest
    static void testAllRecordExclusionForInsert(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {

            Test.startTest();
            List<Account> newAccounts = testFactory.initSampleAccount(10);

            for (Account acc : newAccounts) {
                acc.Name = 'Skip Test Account';
            }

            insert newAccounts;

            List<Log__c> testLogs = [SELECT Id, Name, Reference__c FROM Log__c];

            Integer beforeInsertCount = 0;
            Integer afterInsertCount = 0;

            for (Log__c log : testLogs) {
                System.Assert.areNotEqual('Skip Test Account', log.Name);

                if (log.Reference__c == 'BeforeInsert') {
                    beforeInsertCount ++;
                } else if (log.Reference__c == 'AfterInsert') {
                    afterInsertCount ++;
                }
            }

            System.Assert.areEqual(0, beforeInsertCount);
            System.Assert.areEqual(0, afterInsertCount);

            Test.stopTest();
        }
        
    }

    /**
     * @description Test partial records exclusion for update event
     */
    @IsTest
    static void testPartialRecordExclusionForUpdate(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            List<Account> newAccounts = testFactory.initSampleAccount(10);

            insert newAccounts;

            Integer counter = 0;
            for (Account acc : newAccounts) {
                acc.Name = 'Skip Test Account';

                counter ++;

                if (counter > 4) {
                    break;
                }
            }

            update newAccounts;

            List<Log__c> testLogs = [SELECT Id, Name, Reference__c FROM Log__c];

            Integer insertCount = 0;
            Integer updateCount = 0;

            for (Log__c log : testLogs) {
                System.Assert.areNotEqual('Skip Test Account', log.Name);

                if (log.Reference__c.contains('Insert')) {
                    insertCount ++;
                } else if (log.Reference__c.contains('Update') ) {
                    updateCount ++;
                }
            }

            System.Assert.areEqual(20, insertCount);
            System.Assert.areEqual(10, updateCount);

            Test.stopTest();
        }
        
    }

    /**
     * @description Test all records exclusion for update event
     */
    @IsTest
    static void testAllRecordExclusionForUpdate(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            List<Account> newAccounts = testFactory.initSampleAccount(10);

            insert newAccounts;

            for (Account acc : newAccounts) {
                acc.Name = 'Skip Test Account';
            }

            update newAccounts;

            List<Log__c> testLogs = [SELECT Id, Name, Reference__c FROM Log__c];

            Integer insertCount = 0;
            Integer updateCount = 0;

            for (Log__c log : testLogs) {
                System.Assert.areNotEqual('Skip Test Account', log.Name);

                if (log.Reference__c.contains('Insert')) {
                    insertCount ++;
                } else if (log.Reference__c.contains('Update') ) {
                    updateCount ++;
                }
            }

            System.Assert.areEqual(20, insertCount);
            System.Assert.areEqual(0, updateCount);

            Test.stopTest();
        }
        
    }

    /**
     * @description Test for all trigger events for performance benchmark
     */
    @IsTest
    static void testTriggerExecutionPerformanceBenchmark(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();
            Integer startCpu = Limits.getCpuTime();
            List<Account> newAccounts = testFactory.initSampleAccount(200);

            insert newAccounts;
            update newAccounts;
            delete newAccounts;
            undelete newAccounts;

            List<Log__c> testLogs = [SELECT Id, Name, Reference__c FROM Log__c];
            
            Integer beforeInsertCount = 0;
            Integer afterInsertCount = 0;
            Integer beforeUpdateCount = 0;
            Integer afterUpdateCount = 0;
            Integer beforeDeleteCount = 0;
            Integer afterDeleteCount = 0;
            Integer afterUndeleteCount = 0;
            

            for (Log__c log : testLogs) {
                if (log.Reference__c == 'BeforeInsert') {
                    beforeInsertCount ++;
                } else if (log.Reference__c == 'AfterInsert') {
                    afterInsertCount ++;
                } else if (log.Reference__c == 'BeforeUpdate') {
                    beforeUpdateCount ++;
                } else if (log.Reference__c == 'AfterUpdate') {
                    afterUpdateCount ++;
                } else if (log.Reference__c == 'BeforeDelete') {
                    beforeDeleteCount ++;
                } else if (log.Reference__c == 'AfterDelete') {
                    afterDeleteCount ++;
                } else if (log.Reference__c == 'AfterUndelete') {
                    afterUndeleteCount ++;
                }
            }

            System.Assert.areEqual(200, beforeInsertCount);
            System.Assert.areEqual(200, afterInsertCount);
            System.Assert.areEqual(200, beforeUpdateCount);
            System.Assert.areEqual(200, afterUpdateCount);
            System.Assert.areEqual(200, beforeDeleteCount);
            System.Assert.areEqual(200, afterDeleteCount);
            System.Assert.areEqual(200, afterUndeleteCount);

            Integer endCpu = Limits.getCpuTime();
            Integer consumedCpu = endCpu - startCpu;
            System.debug(consumedCpu);

            System.Assert.isTrue(consumedCpu < 5000, 'The Apex CPU time consumed is too much: ' + consumedCpu);

            Test.stopTest();
        }
        
    }

    /**
     * @description Test trigger skipping with app disabled
     */
    @IsTest
    static void testTriggerSkippingWithAppDisabled(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

        User setupUser = testFactory.getSetupUser();

        System.runAs(setupUser) {
            reduivy__RIO_Education_Ivy_Settings__c appSetting = REDU_AppSetting_UTIL.getOrgDefaultSetting();
            appSetting.reduivy__Enable_RIO_Education__c = false;

            update appSetting;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();
            REDU_TriggerController.muteTriggers(new Set<String>{'ACC_Sample_EXE'});

            List<Account> newAccounts = testFactory.initSampleAccount(10);
            insert newAccounts;

            REDU_TriggerController.unmuteTriggers(new Set<String>{'ACC_Sample_EXE'});

            update newAccounts;

            List<Log__c> testLogs = [SELECT Id, Name, Reference__c FROM Log__c];
            //before insert + after insert
            Integer insertCount = 0;
            Integer updateCount = 0;

            for (Log__c log : testLogs) {
                if (log.Reference__c.contains('Insert')) {
                    insertCount ++;
                } else if (log.Reference__c.contains('Update')) {
                    updateCount ++;
                }
            }

            System.Assert.areEqual(0, insertCount);
            System.Assert.areEqual(0, updateCount);

            Test.stopTest();
        }
        
    }
}