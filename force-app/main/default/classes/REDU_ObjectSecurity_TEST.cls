/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_ObjectSecurity_UTIL
 * @changehistory
 * 
 */
@isTest
public inherited sharing class REDU_ObjectSecurity_TEST {

    /**
     * @description Test object and fls validation with positive result
     */
    @IsTest
    static void testValidateAccessPositive(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User permittedUser = testFactory.getReduAdminUser();

        Test.startTest();
        System.runAs(permittedUser){
            try {
                REDU_ObjectSecurity_UTIL.validateAccess(ACC_Helper.getApiName(), new List<String>{'reduivy__Code__c'}, AccessType.READABLE, false);
            } catch (Exception exp) {
                System.Assert.fail('The user should have right access.');
            }
        }
        Test.stopTest();
        
    }

    /**
     * @description Test object and fls validation with negative result
     */
    @IsTest
    static void testValidateAccessNegative(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User nonPermittedUser = testFactory.getSetupUser();

        Test.startTest();
        System.runAs(nonPermittedUser){
            try {
                REDU_ObjectSecurity_UTIL.validateAccess(ACC_Helper.getApiName(), new List<String>{'reduivy__Code__c'}, AccessType.READABLE, false);
                System.Assert.fail('The user should not have access.');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s) - Account.'), 'Unexpected error message. The error is: ' + exp.getMessage());
            }
        }
        Test.stopTest();
        
    }

    /**
     * @description Test object and fls validation with negative result for invalid field
     */
    @IsTest
    static void testValidateAccessNegativeWithInvalidField(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User permittedUser = testFactory.getReduAdminUser();

        Test.startTest();
        System.runAs(permittedUser){
            try {
                REDU_ObjectSecurity_UTIL.validateAccess(ACC_Helper.getApiName(), new List<String>{'reduivy__XXXX__c'}, AccessType.READABLE, false);
                System.Assert.fail('The user should not have access.');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Invalid field reduivy__XXXX__c for object Account.'), 'Unexpected error message. The error is: ' + exp.getMessage());
            }
        }
        Test.stopTest();
        
    }

    /**
     * @description Test object and fls validation with negative result for silent
     */
    @IsTest
    static void testValidateAccessNegativeWithSilent(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User nonPermittedUser = testFactory.getSetupUser();

        Test.startTest();
        System.runAs(nonPermittedUser){
            try {
                String errorMessage = REDU_ObjectSecurity_UTIL.validateAccess(ACC_Helper.getApiName(), new List<String>{'reduivy__Code__c'}, AccessType.READABLE, true);
                System.Assert.isTrue(errorMessage.contains('Insufficient READABLE access on following object(s) and field(s) - Account.'), 'Unexpected error message. The error is: ' + errorMessage);
            } catch (Exception exp) {
                System.Assert.fail('The user should not fail with exception as it is silent.');
                
            }
        }
        Test.stopTest();
        
    }

    /**
     * @description Test validate delete access
     */
    @IsTest
    static void testValidateDeleteAccess(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User nonPermittedUser = testFactory.getSetupUser();

        List<Account> accounts = new List<Account>{
            REDU_TestData_UTIL.newEducationalInstitution(
                'sample', 
                'sample unit', 
                'sample code'
            )
        };

        REDU_Database_UTIL.doInsert(accounts);

        reduivy__Study_Program__c spg = REDU_TestData_UTIL.newStudyProgram('sample', accounts.get(0).Id, 'sample', 'Masters', 'sample');
        REDU_Database_UTIL.doInsert(new List<reduivy__Study_Program__c> {spg});

        Test.startTest();
        
        System.runAs(nonPermittedUser) {
            //test with silent
            String accessError = REDU_ObjectSecurity_UTIL.validateDeleteAccess(new List<reduivy__Study_Program__c> {spg}, true);

            System.Assert.isTrue(accessError.contains('Insufficient Delete access on following object(s) and field(s) - reduivy__Study_Program__c'), 'The exception is invalid: ' + accessError);

            //test without silent
            try {
                REDU_ObjectSecurity_UTIL.validateDeleteAccess(new List<reduivy__Study_Program__c> {spg}, false);

                System.Assert.fail('This should fail with FLS error as we handle the delete permission check differently.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                
                System.Assert.isTrue(exp.getMessage().contains('Insufficient Delete access on following object(s) and field(s) - reduivy__Study_Program__c'), 'The exception is invalid: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test query exception
     */
    @IsTest
    static void testHandleQueryException(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User nonPermittedUser = testFactory.getSetupUser();

        List<Account> accounts = new List<Account>{
            REDU_TestData_UTIL.newEducationalInstitution(
                'sample', 
                'sample unit', 
                'sample code'
            )
        };

        REDU_Database_UTIL.doInsert(accounts);

        Test.startTest();
        
        System.runAs(nonPermittedUser) {
            
            //test with silent
            try {
                List<Account> result = [SELECT Id, Name, reduivy__Code__c FROM Account WITH USER_MODE];

                System.Assert.fail('This should fail with FLS error.');

            } catch(QueryException exp) {
                REDU_Logging_UTIL.debug(exp);

                String accessError = REDU_ObjectSecurity_UTIL.handleQueryException(exp, true);

                System.Assert.isTrue(accessError.contains('Insufficient READABLE access on following object(s) and field(s) - Account'), 'The exception is invalid: ' + accessError);
            }

            //test without silent
            try {
                List<Account> result = [SELECT Id, Name, reduivy__Code__c FROM Account WITH USER_MODE];

                System.Assert.fail('This should fail with FLS error.');

            } catch(QueryException qexp) {
                REDU_Logging_UTIL.debug(qexp);

                try {
                    String accessError = REDU_ObjectSecurity_UTIL.handleQueryException(qexp, false);
                    System.Assert.fail('This should fail with exception.');

                } catch (Exception exp) {
                    System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s) - Account'), 'The exception is invalid: ' + exp.getMessage());
                }
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test dml exception
     */
    @IsTest
    static void handleDmlException(){
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User nonPermittedUser = testFactory.getSetupUser();

        Test.startTest();

        System.runAs(nonPermittedUser){

            //test with silent
            try {
                List<Account> accounts = new List<Account>{
                    REDU_TestData_UTIL.newEducationalInstitution(
                        'sample', 
                        'sample unit', 
                        'sample code'
                    )
                };
        
                Database.insert(accounts, AccessLevel.USER_MODE);

            } catch(DmlException dexp) {
                REDU_Logging_UTIL.debug(dexp);

                String accessError = REDU_ObjectSecurity_UTIL.handleDmlException('Account', dexp, AccessType.CREATABLE.name(), true);

                System.Assert.isTrue(
                    (
                        accessError.contains('Insufficient CREATABLE access on following object(s) and field(s) - Account') ||
                        accessError.contains('Access to entity \'Account\'')
                    ),
                    'The exception is invalid: ' + accessError
                );
            } catch(Exception exp) {
                REDU_Logging_UTIL.debug(exp);

                String accessError = exp.getMessage();

                System.Assert.isTrue(
                    (
                        accessError.contains('Insufficient CREATABLE access on following object(s) and field(s) - Account') ||
                        accessError.contains('Access to entity \'Account\'')
                    ),
                    'The exception is invalid: ' + accessError
                );
            }

            //test without silent
            try {
                List<Account> accounts = new List<Account>{
                    REDU_TestData_UTIL.newEducationalInstitution(
                        'sample', 
                        'sample unit', 
                        'sample code'
                    )
                };
        
                Database.insert(accounts, AccessLevel.USER_MODE);

                System.Assert.fail('This should fail with FLS error.');

            } catch(DmlException dexp) {
                REDU_Logging_UTIL.debug(dexp);

                try {
                    String accessError = REDU_ObjectSecurity_UTIL.handleDmlException('Account', dexp, AccessType.CREATABLE.name(), false);
                    System.Assert.fail('This should fail with exception.');

                } catch (Exception exp) {
                    System.Assert.isTrue(exp.getMessage().contains('Insufficient CREATABLE access on following object(s) and field(s) - Account'), 'The exception is invalid: ' + exp.getMessage());
                }
            } catch(Exception exp) {
                REDU_Logging_UTIL.debug(exp);

                String accessError = exp.getMessage();

                System.Assert.isTrue(
                    (
                        accessError.contains('Insufficient CREATABLE access on following object(s) and field(s) - Account') ||
                        accessError.contains('Access to entity \'Account\'')
                    ),
                    'The exception is invalid: ' + accessError
                );
            }
        }

        Test.stopTest();
        
    }
	
}