/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_SystemMode_UTIL
 * @changehistory
 * 
 */
@isTest
public inherited sharing class REDU_SystemMode_TEST {

    @TestSetup
    static void makeData(){
        // Create settings
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
		testFactory.setupDefaultSettings();
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

            REDU_SystemMode_UTIL.doInsert(accounts);

            List<reduivy__Study_Program__c> spgs = new List<reduivy__Study_Program__c>{
                REDU_TestData_UTIL.newStudyProgram(
                    'sample', 
                    accounts.get(0).Id, 
                    'sample', 
                    'Masters', 
                    'sample'
                )
            };

            REDU_SystemMode_UTIL.doInsert(spgs, new Map<Id, Account>(accounts), 'reduivy__Educational_Institution__c', false);

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

            REDU_SystemMode_UTIL.doInsert(spls, splsSourceMap, 'reduivy__Study_Program__c', false);

            /**
             * ====================
             * test update
             * ====================
             */
            REDU_SystemMode_UTIL.doUpdate(accounts);

            REDU_SystemMode_UTIL.doUpdate(spgs, new Map<Id, Account>(accounts), 'reduivy__Educational_Institution__c', false);

            REDU_SystemMode_UTIL.doUpdate(spls, splsSourceMap, 'reduivy__Study_Program__c', false);

            /**
             * ====================
             * test upsert
             * ====================
             */
            REDU_SystemMode_UTIL.doUpsert(accounts);

            REDU_SystemMode_UTIL.doUpsert(spgs, new Map<Id, Account>(accounts), 'reduivy__Educational_Institution__c', false);

            REDU_SystemMode_UTIL.doUpsert(spls, splsSourceMap, 'reduivy__Study_Program__c', false);

            /**
             * ====================
             * test delete
             * ====================
             */
            REDU_SystemMode_UTIL.doDelete(spls);

            REDU_SystemMode_UTIL.doDelete(spgs, new Map<Id, Account>(accounts), 'reduivy__Educational_Institution__c', false);

            System.Assert.isTrue(true);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test insert with negative outcome with allOrNone = true
     */
    @IsTest
    static void testForDmlNegativeWithAllOrNone(){
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

        REDU_SystemMode_UTIL.doInsert(accounts);

        reduivy__Study_Program__c spg2 = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Study_Program__c> {spg2});

        String accId = Id.valueOf(accounts.get(0).Id);

        System.runAs(nonPermittedUser){

            /**
             * ====================
             * test insert
             * ====================
             */
            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accId, 'sample', 'Masters', 'sample');

                REDU_SystemMode_UTIL.doInsert(new List<reduivy__Study_Program__c> {spg});

                System.Assert.fail('This should fail.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                
                System.Assert.isTrue(exp.getMessage().contains('Insufficient CREATABLE access on following object(s) and field(s) - reduivy__Study_Program__c'), 'Unexpected error: ' + exp.getMessage());
            }

            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accId, 'sample', 'Masters', 'sample');
                Map<Id, Account> sourceMap = new Map<Id, Account>(accounts);

                REDU_SystemMode_UTIL.doInsert(new List<reduivy__Study_Program__c> {spg}, sourceMap, 'reduivy__Educational_Institution__c', true);

                System.Assert.fail('This should fail.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                
                System.Assert.isTrue(exp.getMessage().contains('Insufficient CREATABLE access on following object(s) and field(s) - reduivy__Study_Program__c'), 'Unexpected error: ' + exp.getMessage());
            }

            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accId, 'sample', 'Masters', 'sample');
                Map<Id, List<Account>> sourceMap = new Map<Id, List<Account>>();
                sourceMap.put(accounts.get(0).Id, accounts);

                REDU_SystemMode_UTIL.doInsert(new List<reduivy__Study_Program__c> {spg}, new Map<Id, List<reduivy__Study_Program__c>>(), 'reduivy__Educational_Institution__c', true);
                
                System.Assert.fail('This should fail.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                
                System.Assert.isTrue(exp.getMessage().contains('Insufficient CREATABLE access on following object(s) and field(s) - reduivy__Study_Program__c'), 'Unexpected error: ' + exp.getMessage());
            }

            /**
             * ====================
             * test update
             * ====================
             */
            try {
                spg2.reduivy__Educational_Institution__c = accId;
                REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Study_Program__c> {spg2});
                
                System.Assert.fail('This should fail.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                
                System.Assert.isTrue(exp.getMessage().contains('Insufficient UPDATABLE access on following object(s) and field(s) - reduivy__Study_Program__c'), 'Unexpected error: ' + exp.getMessage());
            }

            try {
                spg2.reduivy__Educational_Institution__c = accId;
                Map<Id, Account> sourceMap = new Map<Id, Account>(accounts);

                REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Study_Program__c> {spg2}, sourceMap, 'reduivy__Educational_Institution__c', true);
                
                System.Assert.fail('This should fail.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                
                System.Assert.isTrue(exp.getMessage().contains('Insufficient UPDATABLE access on following object(s) and field(s) - reduivy__Study_Program__c'), 'Unexpected error: ' + exp.getMessage());
            }

            try {
                spg2.reduivy__Educational_Institution__c = accId;
                Map<Id, List<Account>> sourceMap = new Map<Id, List<Account>>();
                sourceMap.put(accounts.get(0).Id, accounts);

                REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Study_Program__c> {spg2}, new Map<Id, List<reduivy__Study_Program__c>>(), 'reduivy__Educational_Institution__c', true);
                
                System.Assert.fail('This should fail.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                
                System.Assert.isTrue(exp.getMessage().contains('Insufficient UPDATABLE access on following object(s) and field(s) - reduivy__Study_Program__c'), 'Unexpected error: ' + exp.getMessage());
            }

            /**
             * ====================
             * test upsert
             * ====================
             */
            try {
                spg2.reduivy__Educational_Institution__c = accId;
                REDU_SystemMode_UTIL.doUpsert(new List<reduivy__Study_Program__c> {spg2});
                
                System.Assert.fail('This should fail.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                
                System.Assert.isTrue(exp.getMessage().contains('Insufficient UPSERTABLE access on following object(s) and field(s) - reduivy__Study_Program__c'), 'Unexpected error: ' + exp.getMessage());
            }

            try {
                spg2.reduivy__Educational_Institution__c = accId;
                Map<Id, Account> sourceMap = new Map<Id, Account>(accounts);

                REDU_SystemMode_UTIL.doUpsert(new List<reduivy__Study_Program__c> {spg2}, sourceMap, 'reduivy__Educational_Institution__c', true);
                
                System.Assert.fail('This should fail.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                
                System.Assert.isTrue(exp.getMessage().contains('Insufficient UPSERTABLE access on following object(s) and field(s) - reduivy__Study_Program__c'), 'Unexpected error: ' + exp.getMessage());
            }

            try {
                spg2.reduivy__Educational_Institution__c = accId;
                Map<Id, List<Account>> sourceMap = new Map<Id, List<Account>>();
                sourceMap.put(accounts.get(0).Id, accounts);

                REDU_SystemMode_UTIL.doUpsert(new List<reduivy__Study_Program__c> {spg2}, new Map<Id, List<reduivy__Study_Program__c>>(), 'reduivy__Educational_Institution__c', true);
                
                System.Assert.fail('This should fail.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                
                System.Assert.isTrue(exp.getMessage().contains('Insufficient UPSERTABLE access on following object(s) and field(s) - reduivy__Study_Program__c'), 'Unexpected error: ' + exp.getMessage());
            }
        }

        /**
         * ====================
         * test delete - we create study program to test the delete operation because user has access to standard object e.g., Account
         * ====================
         */
        reduivy__Study_Program__c spgDelete1 = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
        reduivy__Study_Program__c spgDelete2 = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Study_Program__c> {spgDelete1, spgDelete2});

        System.runAs(nonPermittedUser) {
            
            try {
                REDU_SystemMode_UTIL.doDelete(new List<reduivy__Study_Program__c> {spgDelete1});

            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Insufficient Delete access on following object(s) and field(s)'), 'Unexpected error: ' + exp.getMessage());
            }

            try {
                Map<Id, reduivy__Study_Program__c> sourceMap = new Map<Id, reduivy__Study_Program__c>(new List<reduivy__Study_Program__c> {spgDelete2});

                REDU_SystemMode_UTIL.doDelete(new List<reduivy__Study_Program__c> {spgDelete2}, sourceMap, 'Id', true);

            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Insufficient Delete access on following object(s) and field(s)'), 'Unexpected error: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test insert with negative outcome and allOrNone = false
     */
    @IsTest
    static void testForDmlNegativeWithoutAllOrNone(){
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User adminUser = testFactory.getReduAdminUser();

        Test.startTest();

        List<Account> accounts = new List<Account>{
            REDU_TestData_UTIL.newEducationalInstitution(
                'sample', 
                'sample unit', 
                'sample code'
            )
        };

        REDU_SystemMode_UTIL.doInsert(accounts);

        reduivy__Study_Program__c spg2 = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Study_Program__c> {spg2});

        /* We are going to test with invalid study program name*/
        String studyProgName = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ac nisi id ligula consectetur aliquet.';

        System.runAs(adminUser){

            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, studyProgName, 'Masters', 'sample');
                Map<Id, Account> sourceMap = new Map<Id, Account>(accounts);

                REDU_SystemMode_UTIL.doInsert(new List<reduivy__Study_Program__c> {spg}, sourceMap, 'reduivy__Educational_Institution__c', false);

                for (Account acc : accounts) {
                    System.Assert.areEqual(true, !acc.getErrors().isEmpty());

                    String error = acc.getErrors().get(0).getMessage();

                    System.Assert.isTrue(error.contains('Study Program Name: data value too large'), 'The exception is invalid: ' + error);
                }

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.fail('Unexptected error: ' + exp.getMessage());
            }

            try {
                reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, studyProgName, 'Masters', 'sample');
                Map<Id, List<Account>> sourceMap = new Map<Id, List<Account>>();
                sourceMap.put(accounts.get(0).Id, accounts);

                REDU_SystemMode_UTIL.doInsert(new List<reduivy__Study_Program__c> {spg}, sourceMap, 'reduivy__Educational_Institution__c', false);

                for (Account acc : accounts) {
                    System.Assert.areEqual(true, !acc.getErrors().isEmpty());

                    String error = acc.getErrors().get(0).getMessage();

                    System.Assert.isTrue(error.contains('Study Program Name: data value too large'), 'The exception is invalid: ' + error);
                }

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.fail('Unexptected error: ' + exp.getMessage());
            }

            try {
                spg2.Name = studyProgName;
                Map<Id, Account> sourceMap = new Map<Id, Account>(accounts);

                REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Study_Program__c> {spg2}, sourceMap, 'reduivy__Educational_Institution__c', false);

                for (Account acc : accounts) {
                    System.Assert.areEqual(true, !acc.getErrors().isEmpty());

                    String error = acc.getErrors().get(0).getMessage();

                    System.Assert.isTrue(error.contains('Study Program Name: data value too large'), 'The exception is invalid: ' + error);
                }

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.fail('Unexptected error: ' + exp.getMessage());
            }

            try {
                spg2.Name = studyProgName;
                Map<Id, List<Account>> sourceMap = new Map<Id, List<Account>>();
                sourceMap.put(accounts.get(0).Id, accounts);

                REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Study_Program__c> {spg2}, sourceMap, 'reduivy__Educational_Institution__c', false);

                for (Account acc : accounts) {
                    System.Assert.areEqual(true, !acc.getErrors().isEmpty());

                    String error = acc.getErrors().get(0).getMessage();

                    System.Assert.isTrue(error.contains('Study Program Name: data value too large'), 'The exception is invalid: ' + error);
                }

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.fail('Unexptected error: ' + exp.getMessage());
            }

            try {
                spg2.Name = studyProgName;
                Map<Id, Account> sourceMap = new Map<Id, Account>(accounts);

                REDU_SystemMode_UTIL.doUpsert(new List<reduivy__Study_Program__c> {spg2}, sourceMap, 'reduivy__Educational_Institution__c', false);

                for (Account acc : accounts) {
                    System.Assert.areEqual(true, !acc.getErrors().isEmpty());

                    String error = acc.getErrors().get(0).getMessage();

                    System.Assert.isTrue(error.contains('Study Program Name: data value too large'), 'The exception is invalid: ' + error);
                }

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.fail('Unexptected error: ' + exp.getMessage());
            }

            try {
                spg2.Name = studyProgName;
                Map<Id, List<Account>> sourceMap = new Map<Id, List<Account>>();
                sourceMap.put(accounts.get(0).Id, accounts);

                REDU_SystemMode_UTIL.doUpsert(new List<reduivy__Study_Program__c> {spg2}, sourceMap, 'reduivy__Educational_Institution__c', false);

                for (Account acc : accounts) {
                    System.Assert.areEqual(true, !acc.getErrors().isEmpty());

                    String error = acc.getErrors().get(0).getMessage();

                    System.Assert.isTrue(error.contains('Study Program Name: data value too large'), 'The exception is invalid: ' + error);
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
        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Study_Program__c> {spg});

        reduivy__Study_Plan__c spl = REDU_TestData_UTIL.newStudyPlan('sample', spg.Id, null, 'Sample Plan', null, null, false, 0);
        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Study_Plan__c> {spl});

        Map<String, List<reduivy__Trigger_Controller__mdt>> triggerControllerConfigs = REDU_TriggerController.triggerControllerConfigs == null ? new Map<String, List<reduivy__Trigger_Controller__mdt>>() : REDU_TriggerController.triggerControllerConfigs;
        List<reduivy__Trigger_Controller__mdt> spgTcList = new List<reduivy__Trigger_Controller__mdt>();
        spgTcList.add(sampleSpgTriggerControllers());

        if (triggerControllerConfigs.containsKey(SPG_Helper.getApiName())) {    
            triggerControllerConfigs.get(SPG_Helper.getApiName()).addAll(spgTcList);
        } else {
            triggerControllerConfigs.put(SPG_Helper.getApiName(), spgTcList);
        }

        REDU_TriggerController.triggerControllerConfigs = triggerControllerConfigs;

        System.runAs(adminUser) {
            
            try {
                Map<Id, Account> sourceMap = new Map<Id, Account>(accounts);

                REDU_SystemMode_UTIL.doDelete(new List<reduivy__Study_Program__c> {spg}, new Map<Id, reduivy__Study_Program__c>(new List<reduivy__Study_Program__c> {spg}), 'Id', false);

                System.Assert.areEqual(true, !spg.getErrors().isEmpty());

                String error = spg.getErrors().get(0).getMessage();

                System.Assert.isTrue(error.contains('This record can\'t be deleted because it has one or more related records'), 'The exception is invalid: ' + error);

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.fail('Unexptected error: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test query with positive result
     */
    @IsTest
    static void testQueryPositive(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User reduAdmin = testFactory.getReduAdminUser();

        Test.startTest();
        
        List<Account> accounts = new List<Account>{
            REDU_TestData_UTIL.newEducationalInstitution(
                'sample', 
                'sample unit', 
                'sample code'
            )
        };

        REDU_SystemMode_UTIL.doInsert(accounts);

        System.runAs(reduAdmin) {
            String soql = 'SELECT Id, Name FROM Account WHERE reduivy__Code__c =: code';
            Map<String, Object> bindParams = new Map<String, Object>();
            bindParams.put('code', 'sample code');

            Map<String, Set<String>> objectFieldsForFls = new Map<String, Set<String>>();
            objectFieldsForFls.put(ACC_Helper.getApiName(), new Set<String>{'Id', 'Name', 'reduivy__Code__c'});

            List<SObject> result = REDU_SystemMode_UTIL.doQuery(soql, bindParams, objectFieldsForFls);
            
            System.Assert.areEqual(false, result.isEmpty());
        }

        Test.stopTest();
        
    }

    /**
     * @description Test query with empty fls map
     */
    @IsTest
    static void testQueryNegativeWithEmptyFlsMap(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User reduAdmin = testFactory.getReduAdminUser();

        Test.startTest();
        
        List<Account> accounts = new List<Account>{
            REDU_TestData_UTIL.newEducationalInstitution(
                'sample', 
                'sample unit', 
                'sample code'
            )
        };

        REDU_SystemMode_UTIL.doInsert(accounts);

        System.runAs(reduAdmin) {
            String soql = 'SELECT Id, Name FROM Account WHERE reduivy__Code__c =: code';
            Map<String, Object> bindParams = new Map<String, Object>();
            bindParams.put('code', 'sample code');

            Map<String, Set<String>> objectFieldsForFls = new Map<String, Set<String>>();

            try {
                List<SObject> result = REDU_SystemMode_UTIL.doQuery(soql, bindParams, objectFieldsForFls);
                System.Assert.fail('This should fail with "' + Label.Missing_Object_And_Field_For_FLS + '" error.');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(Label.Missing_Object_And_Field_For_FLS), 'Unexpected error. The actual error is: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test query with negative result
     */
    @IsTest
    static void testQueryNegative(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User setupUser = testFactory.getSetupUser();

        Test.startTest();
        
        List<Account> accounts = new List<Account>{
            REDU_TestData_UTIL.newEducationalInstitution(
                'sample', 
                'sample unit', 
                'sample code'
            )
        };

        REDU_SystemMode_UTIL.doInsert(accounts);

        System.runAs(setupUser) {
            String soql = 'SELECT Id, Name FROM Account WHERE reduivy__Code__c =: code';
            Map<String, Object> bindParams = new Map<String, Object>();
            bindParams.put('code', 'sample code');

            Map<String, Set<String>> objectFieldsForFls = new Map<String, Set<String>>();
            objectFieldsForFls.put(ACC_Helper.getApiName(), new Set<String>{'Id', 'Name', 'reduivy__Code__c'});

            try {
                List<SObject> result = REDU_SystemMode_UTIL.doQuery(soql, bindParams, objectFieldsForFls);
                System.Assert.fail('This should fail with FLS error.');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s)'), 'Unexpected error. The actual error is: ' + exp.getMessage());
            }
            
        }

        Test.stopTest();
        
    }

    public static reduivy__Trigger_Controller__mdt sampleSpgTriggerControllers() {
        reduivy__Trigger_Controller__mdt tc = new reduivy__Trigger_Controller__mdt();
        tc.reduivy__Active__c = true;
        tc.reduivy__After_Delete__c = false;
        tc.reduivy__After_Insert__c = false;
        tc.reduivy__After_Undelete__c = false;
        tc.reduivy__After_Update__c = false;
        tc.reduivy__Before_Delete__c = true;
        tc.reduivy__Before_Insert__c = false;
        tc.reduivy__Before_Update__c = false;
        tc.reduivy__Class_Name__c = 'SOBJ_DeleteValidation_EXE';
        tc.reduivy__Record_Exclusion_Field__c = null;
        tc.reduivy__Record_Exclusion_Value__c = null;
        tc.reduivy__Sequence__c = 1.0;
        tc.reduivy__SObject__c = 'Study_Program__c';
        tc.reduivy__User_Exclusion_Field__c = null;
        tc.reduivy__User_Exclusion_Value__c = null;

        return tc;
    }
}