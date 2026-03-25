/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Test
 * @description Test class for CON_CreateAccount_EXE
 * @changehistory
 * ISS-001618 02-10-2023 dblack - new class
 */
@IsTest
public inherited sharing class CON_CreateAccount_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Number of records for bulk testing
     */
    static final Integer BULK_QTY = 20;

    /**
     * @description Administrative account name format for custom setting
     */
    static final String ADMIN_ACCOUNT_NAME_FORMAT = '{FirstName} {LastName} Administrative Account';
    
    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData() {
        // Create settings
        testFactory.setupDefaultSettings();
    }

    /**
     * @description Test as admin that an account is created when a contact is created
     */
    @IsTest
    static void testCreateAccountAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        // Setup test data
        Map<String, Contact> conMap = new Map<String, Contact>();
        
        System.runAs(ADMIN_USER) {
            // Set custom setting value for administrative account name format
            reduivy__RIO_Education_Ivy_Settings__c cs = reduivy__RIO_Education_Ivy_Settings__c.getOrgDefaults();
            cs.reduivy__Administrative_Account_Name_Format__c = ADMIN_ACCOUNT_NAME_FORMAT;
            update cs;

            // Create contacts without a linked account
            for (Integer i = 0; i < BULK_QTY; i++) {
                Contact con = new Contact();
                con.FirstName = 'FirstName-' + String.valueOf(i);
                con.LastName = 'LastName-' + String.valueOf(i);
                con.Email = 'FirstName.LastName-' + String.valueOf(i) + '@email.org';
                conMap.put(con.Email, con);
            }

            // Execute test
            Test.startTest();
            insert conMap.values();
            Test.stopTest();
        }

        // Verify test results
        List<Contact> conList = [
            SELECT FirstName, LastName, Account.Name, Account.RecordType.DeveloperName
            FROM Contact
            WHERE Email IN: conMap.keySet()
            AND AccountId != null
        ];
        System.Assert.areEqual(
            conMap.size(),
            conList.size(),
            'Each of the contacts should have a linked account'
        );
        String expectedAccountName;
        String expectedRecordTypeId = ACC_Helper.getAdministrativeRecordTypeId();
        for (Contact con : conList) {
            expectedAccountName = 
                ADMIN_ACCOUNT_NAME_FORMAT.replace('{FirstName}', con.FirstName).replace('{LastName}', con.LastName);
            System.Assert.areEqual(
                expectedAccountName,
                con.Account.Name,
                'The account name should be as expected'
            );
            System.Assert.areEqual(
                expectedRecordTypeId, 
                con.Account.RecordTypeId,
                'The account record type should be as expected'
            );
        }
    }
}