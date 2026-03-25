/**
 * @author      WDCi (Lean)
 * @date        March 2023
 * @group       Test
 * @description Test class for REDU_SObject_UTIL
 * @changehistory
 * ISS-001591 31-03-2023 Lean - new class
 */
@IsTest
public inherited sharing class REDU_SObject_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    @TestSetup
    static void makeData(){
        // Create settings
		testFactory.setupDefaultSettings();

        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

            Account newAccount = new Account(Name = 'Test Account');
            insert newAccount;

            Contact newContact = new Contact(FirstName = 'Test First Name', LastName = 'Test Last Name', AccountId = newAccount.Id);
            insert newContact;

            Test.stopTest();
        }
    }

    /**
     * @description Test extract current object field
     */
    @IsTest
    static void testExtractFieldSimple(){
        
        Test.startTest();
        
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        Object fieldValue = REDU_SObject_UTIL.extractFieldValue(acc, 'Name');

        System.Assert.areEqual('Test Account', fieldValue);

        Test.stopTest();
        
    }

    /**
     * @description Test extract parent object field
     */
    @IsTest
    static void testExtractFieldParent(){
        
        Test.startTest();
        
        Contact contact = [SELECT Id, Name, AccountId, Account.Name FROM Contact LIMIT 1];
        Object fieldValue = REDU_SObject_UTIL.extractFieldValue(contact, 'Account.Name');

        System.Assert.areEqual('Test Account', fieldValue);

        Test.stopTest();
        
    }

    /**
     * @description Test get field type
     */
    @IsTest
    static void testGetFieldType(){
        
        Test.startTest();
        System.Assert.areEqual(REDU_SObject_UTIL.FIELDTYPE_BOOLEAN, REDU_SObject_UTIL.getFieldType(Schema.SoapType.BOOLEAN.name()));
        System.Assert.areEqual(REDU_SObject_UTIL.FIELDTYPE_DATE, REDU_SObject_UTIL.getFieldType(Schema.SoapType.DATE.name()));
        System.Assert.areEqual(REDU_SObject_UTIL.FIELDTYPE_DATETIME, REDU_SObject_UTIL.getFieldType(Schema.SoapType.DATETIME.name()));
        System.Assert.areEqual(REDU_SObject_UTIL.FIELDTYPE_NUMBER, REDU_SObject_UTIL.getFieldType(Schema.SoapType.INTEGER.name()));
        System.Assert.areEqual(REDU_SObject_UTIL.FIELDTYPE_NUMBER, REDU_SObject_UTIL.getFieldType(Schema.SoapType.DOUBLE.name()));
        System.Assert.areEqual(REDU_SObject_UTIL.FIELDTYPE_TEXT, REDU_SObject_UTIL.getFieldType(Schema.SoapType.STRING.name()));

        Test.stopTest();
        
    }

    /**
     * @description Test multi currencies setting
     */
    @IsTest
    static void testHasCurrencyIsoCode(){
        
        Test.startTest();
        
        if (!ORG_Helper.isMultiCurrenciesOrg()) {
            //we won't run this test in non multi currencies org as it will fail
            System.Assert.isFalse(REDU_SObject_UTIL.hasCurrencyIsoCode(reduivy__Transaction_Order__c.getSObjectType()), 'This should return false.');
        }

        ORG_Helper.testSimulateMultiCurrencies = true;
        if (ORG_Helper.isMultiCurrenciesOrg()) {
            System.Assert.isTrue(REDU_SObject_UTIL.hasCurrencyIsoCode(reduivy__Transaction_Order__c.getSObjectType()), 'This should return true.');
        }
        ORG_Helper.testSimulateMultiCurrencies = false;

        Test.stopTest();
        
    }
}