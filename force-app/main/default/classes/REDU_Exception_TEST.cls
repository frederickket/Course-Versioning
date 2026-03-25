/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_Exception_UTIL
 * @changehistory
 * 
 */
@isTest
public inherited sharing class REDU_Exception_TEST {

    /**
     * @description Test init aura handled exception
     */
	@IsTest
    static void testInitAuraException(){
        
        Test.startTest();
        
        AuraHandledException ahe = REDU_Exception_UTIL.auraException('message');
        
        System.Assert.areEqual('message', ahe.getMessage());

        Test.stopTest();
        
    }

    /**
     * @description Test init aura handled exception
     */
    @IsTest
    static void testInitAuraExceptionFull(){
        
        Test.startTest();
        
        AuraHandledException ahe = REDU_Exception_UTIL.auraException('message', 10, 'stacktrace');

        System.Assert.areEqual('message: 10 - stacktrace', ahe.getMessage());

        Test.stopTest();
        
    }

    /**
     * @description Test init aura handled exception from exception
     */
    @IsTest
    static void testInitAuraExceptionWithException(){
        
        Test.startTest();
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User nonPermittedUser = testFactory.getSetupUser();
        
        System.runAs(nonPermittedUser) {
            try {
                List<Account> accounts = new List<Account>{
                    REDU_TestData_UTIL.newEducationalInstitution(
                        'sample', 
                        'sample unit', 
                        'sample code'
                    )
                };

                REDU_Database_UTIL.doInsert(accounts);

                System.Assert.fail('This should fail with error.');

            } catch (Exception exp) {

                AuraHandledException ahe = REDU_Exception_UTIL.auraException(exp);

                System.Assert.isTrue(
                    (
                        ahe.getMessage().contains('Insufficient CREATABLE access on following object(s) and field(s) - Account') ||
                        ahe.getMessage().contains('Access to entity \'Account\'')
                    ),
                    'The exception is invalid: ' + ahe.getMessage()
                );
            }

        }

        Test.stopTest();
        
    }
}