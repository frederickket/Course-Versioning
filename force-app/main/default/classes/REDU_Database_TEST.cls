/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_Database_UTIL. Note that we won't be covering the DML methods (doInsert, doUpdate, doUpsert, doDelete) as those are meant for trigger records.
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class REDU_Database_TEST {


    /**
     * @description Test cleanse message 
     */
    @IsTest
    static void testCleanseMessage(){
        
        String expMsgPrefix1 = 'FIELD_CUSTOM_VALIDATION_EXCEPTION,';
        String expMsgPrefix2 = 'VALIDATION MESSAGE:';
        String expMsgPrefix3 = 'A validation rule is preventing the record from being processed. This could be from this record, or a related record being updated. VALIDATION MESSAGE:';
        String expMsgPrefix4 = 'A validation rule is preventing this record from being processed. The validation rule might be on this record, or on a related record that\'s being updated. VALIDATION MESSAGE:';
        
        Test.startTest();
        String errorMessage1 = expMsgPrefix1 + expMsgPrefix2 + 'Sample exception 1';
        String errorMessage2 = expMsgPrefix2 + expMsgPrefix1 + 'Sample exception 2';
        String errorMessage3 = expMsgPrefix3 + expMsgPrefix4 + 'Sample exception 3';
        String errorMessage4 = expMsgPrefix4 + expMsgPrefix3 + 'Sample exception 4';

        System.Assert.areEqual('Sample exception 1', REDU_Database_UTIL.cleanseErrorMessage(errorMessage1));
        System.Assert.areEqual('Sample exception 2', REDU_Database_UTIL.cleanseErrorMessage(errorMessage2));
        System.Assert.areEqual('Sample exception 3', REDU_Database_UTIL.cleanseErrorMessage(errorMessage3));
        System.Assert.areEqual('Sample exception 4', REDU_Database_UTIL.cleanseErrorMessage(errorMessage4));

        Test.stopTest();
        
    }

    /**
     * @description Test insert with positive outcome
     */
    @IsTest
    static void testFlsForDmlPositive(){
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User reduAdmin = testFactory.getReduAdminUser();

        Test.startTest();

        System.runAs(reduAdmin){
            
            /**
             * ====================
             * test insert
             * ====================
             */
            List<Account> accounts = new List<Account>{
                REDU_TestData_UTIL.newEducationalInstitution(
                    'sample', 
                    'sample unit', 
                    'sample code'
                )
            };

            REDU_Database_UTIL.doInsert(accounts);

            List<reduivy__Study_Program__c> spgs = new List<reduivy__Study_Program__c>{
                REDU_TestData_UTIL.newStudyProgram(
                    'sample', 
                    accounts.get(0).Id, 
                    'sample', 
                    'Masters', 
                    'sample'
                )
            };

            REDU_Database_UTIL.doInsert(spgs, new Map<Id, Account>(accounts), 'reduivy__Educational_Institution__c', false);

            List<reduivy__Study_Plan__c> spls = new List<reduivy__Study_Plan__c>{
                REDU_TestData_UTIL.newStudyPlan(
                    'sample', 
                    spgs.get(0).Id, 
                    null,
                    'sample', 
                    null,
                    null,
                    false,
                    60
                )
            };

            Map<Id, List<reduivy__Study_Program__c>> splsSourceMap = new Map<Id, List<reduivy__Study_Program__c>>();
            splsSourceMap.put(spgs.get(0).Id, spgs);

            REDU_Database_UTIL.doInsert(spls, splsSourceMap, 'reduivy__Study_Program__c', false);

            /**
             * ====================
             * test update
             * ====================
             */
            REDU_Database_UTIL.doUpdate(accounts);

            REDU_Database_UTIL.doUpdate(spgs, new Map<Id, Account>(accounts), 'reduivy__Educational_Institution__c', false);

            REDU_Database_UTIL.doUpdate(spls, splsSourceMap, 'reduivy__Study_Program__c', false);

            /**
             * ====================
             * test upsert
             * ====================
             */
            REDU_Database_UTIL.doUpsert(accounts);

            REDU_Database_UTIL.doUpsert(spgs, new Map<Id, Account>(accounts), 'reduivy__Educational_Institution__c', false);

            REDU_Database_UTIL.doUpsert(spls, splsSourceMap, 'reduivy__Study_Program__c', false);

            /**
             * ====================
             * test delete
             * ====================
             */
            REDU_Database_UTIL.doDelete(spls);

            REDU_Database_UTIL.doDelete(spgs, new Map<Id, Account>(accounts), 'reduivy__Educational_Institution__c', false);

            System.Assert.isTrue(true);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test insert with negative outcome with allOrNone = true
     */
    @IsTest
    static void testFlsForDmlNegativeWithAllOrNone(){
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User nonPermittedUser = testFactory.getSetupUser();

        Test.startTest();

        List<Account> accounts = new List<Account>{
            REDU_TestData_UTIL.newEducationalInstitution(
                'sample', 
                'sample unit', 
                'sample code'
            )
        };

        REDU_Database_UTIL.doInsert(accounts);

        System.runAs(nonPermittedUser){

            /**
             * ====================
             * test insert
             * ====================
             */
            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');

                REDU_Database_UTIL.doInsert(new List<reduivy__Study_Program__c> {spg});

                System.Assert.fail('This should fail with FLS error.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('Access to entity \'reduivy__Study_Program__c\' denied'), 'The exception is invalid: ' + exp.getMessage());
            }

            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
                Map<Id, Account> sourceMap = new Map<Id, Account>(accounts);

                REDU_Database_UTIL.doInsert(new List<reduivy__Study_Program__c> {spg}, sourceMap, 'reduivy__Educational_Institution__c', true);

                System.Assert.fail('This should fail with FLS error.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('Access to entity \'reduivy__Study_Program__c\' denied'), 'The exception is invalid: ' + exp.getMessage());
            }

            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
                Map<Id, List<Account>> sourceMap = new Map<Id, List<Account>>();
                sourceMap.put(accounts.get(0).Id, accounts);

                REDU_Database_UTIL.doInsert(new List<reduivy__Study_Program__c> {spg}, new Map<Id, List<reduivy__Study_Program__c>>(), 'reduivy__Educational_Institution__c', true);

                System.Assert.fail('This should fail with FLS error.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('Access to entity \'reduivy__Study_Program__c\' denied'), 'The exception is invalid: ' + exp.getMessage());
            }

            /**
             * ====================
             * test update
             * ====================
             */
            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');

                REDU_Database_UTIL.doUpdate(new List<reduivy__Study_Program__c> {spg});

                System.Assert.fail('This should fail with FLS error.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('Access to entity \'reduivy__Study_Program__c\' denied'), 'The exception is invalid: ' + exp.getMessage());
            }

            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
                Map<Id, Account> sourceMap = new Map<Id, Account>(accounts);

                REDU_Database_UTIL.doUpdate(new List<reduivy__Study_Program__c> {spg}, sourceMap, 'reduivy__Educational_Institution__c', true);

                System.Assert.fail('This should fail with FLS error.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('Access to entity \'reduivy__Study_Program__c\' denied'), 'The exception is invalid: ' + exp.getMessage());
            }

            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
                Map<Id, List<Account>> sourceMap = new Map<Id, List<Account>>();
                sourceMap.put(accounts.get(0).Id, accounts);

                REDU_Database_UTIL.doUpdate(new List<reduivy__Study_Program__c> {spg}, new Map<Id, List<reduivy__Study_Program__c>>(), 'reduivy__Educational_Institution__c', true);

                System.Assert.fail('This should fail with FLS error.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('Access to entity \'reduivy__Study_Program__c\' denied'), 'The exception is invalid: ' + exp.getMessage());
            }

            /**
             * ====================
             * test upsert
             * ====================
             */
            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');

                REDU_Database_UTIL.doUpsert(new List<reduivy__Study_Program__c> {spg});

                System.Assert.fail('This should fail with FLS error.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('Access to entity \'reduivy__Study_Program__c\' denied'), 'The exception is invalid: ' + exp.getMessage());
            }

            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
                Map<Id, Account> sourceMap = new Map<Id, Account>(accounts);

                REDU_Database_UTIL.doUpsert(new List<reduivy__Study_Program__c> {spg}, sourceMap, 'reduivy__Educational_Institution__c', true);

                System.Assert.fail('This should fail with FLS error.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('Access to entity \'reduivy__Study_Program__c\' denied'), 'The exception is invalid: ' + exp.getMessage());
            }

            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
                Map<Id, List<Account>> sourceMap = new Map<Id, List<Account>>();
                sourceMap.put(accounts.get(0).Id, accounts);

                REDU_Database_UTIL.doUpsert(new List<reduivy__Study_Program__c> {spg}, new Map<Id, List<reduivy__Study_Program__c>>(), 'reduivy__Educational_Institution__c', true);

                System.Assert.fail('This should fail with FLS error.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('Access to entity \'reduivy__Study_Program__c\' denied'), 'The exception is invalid: ' + exp.getMessage());
            }
        }

        /**
         * ====================
         * test delete - we create study program to test the delete operation because user has access to standard object e.g., Account
         * ====================
         */
        reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
        REDU_Database_UTIL.doInsert(new List<reduivy__Study_Program__c> {spg});

        System.runAs(nonPermittedUser) {
            
            try {
                REDU_Database_UTIL.doDelete(new List<reduivy__Study_Program__c> {spg});

                System.Assert.fail('This should fail with FLS error.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('Insufficient Delete access on following object(s) and field(s) - reduivy__Study_Program__c'), 'The exception is invalid: ' + exp.getMessage());
            }

            try {
                Map<Id, reduivy__Study_Program__c> sourceMap = new Map<Id, reduivy__Study_Program__c>(new List<reduivy__Study_Program__c> {spg});

                REDU_Database_UTIL.doDelete(new List<reduivy__Study_Program__c> {spg}, sourceMap, 'Id', true);

                System.Assert.fail('This should fail with FLS error.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('Insufficient Delete access on following object(s) and field(s) - reduivy__Study_Program__c'), 'The exception is invalid: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test insert with negative outcome and allOrNone = false
     */
    @IsTest
    static void testFlsForDmlNegativeWithoutAllOrNone(){
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User nonPermittedUser = testFactory.getSetupUser();

        Test.startTest();

        List<Account> accounts = new List<Account>{
            REDU_TestData_UTIL.newEducationalInstitution(
                'sample', 
                'sample unit', 
                'sample code'
            )
        };

        REDU_Database_UTIL.doInsert(accounts);

        System.runAs(nonPermittedUser){

            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
                Map<Id, Account> sourceMap = new Map<Id, Account>(accounts);

                REDU_Database_UTIL.doInsert(new List<reduivy__Study_Program__c> {spg}, sourceMap, 'reduivy__Educational_Institution__c', false);

                for (Account acc : accounts) {
                    System.Assert.areEqual(true, !acc.getErrors().isEmpty());

                    String error = acc.getErrors().get(0).getMessage();

                    System.Assert.isTrue(error.contains('Access to entity \'reduivy__Study_Program__c\' denied'), 'The exception is invalid: ' + error);
                }

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.fail('Unexptected error: ' + exp.getMessage());
            }

            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
                Map<Id, List<Account>> sourceMap = new Map<Id, List<Account>>();
                sourceMap.put(accounts.get(0).Id, accounts);

                REDU_Database_UTIL.doInsert(new List<reduivy__Study_Program__c> {spg}, sourceMap, 'reduivy__Educational_Institution__c', false);

                for (Account acc : accounts) {
                    System.Assert.areEqual(true, !acc.getErrors().isEmpty());

                    String error = acc.getErrors().get(0).getMessage();

                    System.Assert.isTrue(error.contains('Access to entity \'reduivy__Study_Program__c\' denied'), 'The exception is invalid: ' + error);
                }

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.fail('Unexptected error: ' + exp.getMessage());
            }

            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
                Map<Id, Account> sourceMap = new Map<Id, Account>(accounts);

                REDU_Database_UTIL.doUpdate(new List<reduivy__Study_Program__c> {spg}, sourceMap, 'reduivy__Educational_Institution__c', false);

                for (Account acc : accounts) {
                    System.Assert.areEqual(true, !acc.getErrors().isEmpty());

                    String error = acc.getErrors().get(0).getMessage();

                    System.Assert.isTrue(error.contains('Access to entity \'reduivy__Study_Program__c\' denied'), 'The exception is invalid: ' + error);
                }

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.fail('Unexptected error: ' + exp.getMessage());
            }

            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
                Map<Id, List<Account>> sourceMap = new Map<Id, List<Account>>();
                sourceMap.put(accounts.get(0).Id, accounts);

                REDU_Database_UTIL.doUpdate(new List<reduivy__Study_Program__c> {spg}, sourceMap, 'reduivy__Educational_Institution__c', false);

                for (Account acc : accounts) {
                    System.Assert.areEqual(true, !acc.getErrors().isEmpty());

                    String error = acc.getErrors().get(0).getMessage();

                    System.Assert.isTrue(error.contains('Access to entity \'reduivy__Study_Program__c\' denied'), 'The exception is invalid: ' + error);
                }

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.fail('Unexptected error: ' + exp.getMessage());
            }

            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
                Map<Id, Account> sourceMap = new Map<Id, Account>(accounts);

                REDU_Database_UTIL.doUpsert(new List<reduivy__Study_Program__c> {spg}, sourceMap, 'reduivy__Educational_Institution__c', false);

                for (Account acc : accounts) {
                    System.Assert.areEqual(true, !acc.getErrors().isEmpty());

                    String error = acc.getErrors().get(0).getMessage();

                    System.Assert.isTrue(error.contains('Access to entity \'reduivy__Study_Program__c\' denied'), 'The exception is invalid: ' + error);
                }

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.fail('Unexptected error: ' + exp.getMessage());
            }

            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
                Map<Id, List<Account>> sourceMap = new Map<Id, List<Account>>();
                sourceMap.put(accounts.get(0).Id, accounts);

                REDU_Database_UTIL.doUpsert(new List<reduivy__Study_Program__c> {spg}, sourceMap, 'reduivy__Educational_Institution__c', false);

                for (Account acc : accounts) {
                    System.Assert.areEqual(true, !acc.getErrors().isEmpty());

                    String error = acc.getErrors().get(0).getMessage();

                    System.Assert.isTrue(error.contains('Access to entity \'reduivy__Study_Program__c\' denied'), 'The exception is invalid: ' + error);
                }

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.fail('Unexptected error: ' + exp.getMessage());
            }
        }

        /**
         * ====================
         * test delete - we create study program to test the delete operation because user has access to standard object e.g., Account
         * ====================
         */
        reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
        REDU_Database_UTIL.doInsert(new List<reduivy__Study_Program__c> {spg});

        System.runAs(nonPermittedUser) {
            
            try {
                Map<Id, Account> sourceMap = new Map<Id, Account>(accounts);

                REDU_Database_UTIL.doDelete(new List<reduivy__Study_Program__c> {spg}, sourceMap, 'reduivy__Educational_Institution__c', false);

                System.Assert.fail('This should fail with FLS error as we handle the delete permission check differently.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                
                System.Assert.isTrue(exp.getMessage().contains('Insufficient Delete access on following object(s) and field(s) - reduivy__Study_Program__c'), 'The exception is invalid: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }
    
    /**
     * @description test getMultiPicklistBindMap method
     */
    @IsTest
    static void testGetMultiPicklistBindMap() {
        
        List<String> rawValueList = new List<String>{'A', 'B', 'C', 'D'};
        
        Test.startTest();

        Map<String, Object> actualBindMap = REDU_Database_UTIL.getMultiPicklistBindMap('placeholder', rawValueList);
        System.Assert.areEqual(4, actualBindMap.size(), 'Wrong bind map size!');

        Integer counter = 0;
        for(String value : rawValueList) {
            counter++;
            System.Assert.isTrue(actualBindMap.containsKey('placeholder' + counter), 'Bind map should contains placeholder' + counter + '!');
            System.Assert.areEqual(value, actualBindMap.get('placeholder' + counter), 'Wrong bind map value!');
        }

        
        
        Test.stopTest();
    }
  
    /**
     * @description test getMultiPicklistPlaceholders method
     */
    @IsTest
    static void testGetMultiPicklistPlaceholders() {
        
        List<String> rawValueList = new List<String>{'A', 'B', 'C', 'D'};
        
        Test.startTest();

        Map<String, Object> bindMap = REDU_Database_UTIL.getMultiPicklistBindMap('placeholder', rawValueList);
        System.Assert.areEqual(4, bindMap.size(), 'Wrong bind map size!');
        
        Set<String> actualSet = REDU_Database_UTIL.getMultiPicklistPlaceholders(bindMap.keySet());
        System.Assert.areEqual(4, actualSet.size(), 'Wrong set size!');


        for(Integer i = 1; i <= 4; i++) {
            System.Assert.isTrue(actualSet.contains(':placeholder' + i), 'Should be existing in the set!');
        }

        
        
        Test.stopTest();
    }
	
}