/**
 * @author      WDCi (Jordan)
 * @date        Mar 2024
 * @group       Test
 * @description Test class for REDU_CustomRollup_UTIL and REDU_CustomRollup_OBJ
 * @changehistory
 * ISS-001853 05-03-2024 Jordan - new test class
 * ISS-002453 20-06-2025 XW - added the test cases for testing the enhancement on reducing query count
 * ISS-002536 24-07-2025 XiRouh - added the test cases for testing the enhancement on rollup condition formula check
 * ISS-002587 13-08-2025 XiRouh - Updated all test methods to use custom metadata in unit-test-metadata set up based on the Account and Contact objects
 */
@IsTest
public inherited sharing class REDU_CustomRollup_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
		// Create settings
		testFactory.setupDefaultSettings();
		
		// Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            
            testFactory.initStudentData(USR_Helper.getApiName(), true);
        }
    }

    /**
     * @description Test method
     */
    @IsTest
    static void testGetRollupConfigsByParentObject(){
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> rollupConfigsByParentObject = REDU_CustomRollup_UTIL.getRollupConfigsByParentObject('Contact');

        System.Assert.isTrue(rollupConfigsByParentObject.size() > 0);
    }

    /**
     * @description Test SUM rollup on Sequence__c with matching and non-matching Contact_Type__c (Applicant)
     */
    @IsTest
    static void testSumRollupMatchingAndNonMatchingContactsAsAdmin() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            // Create test Account
            Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
            insert testAccount;

            Test.startTest();
            
            // Create Contacts with matching Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT
            List<Contact> contacts = new List<Contact>();
            contacts.add(new Contact(
                FirstName = 'Test1', 
                LastName = 'Contact1', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 10,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test2', 
                LastName = 'Contact2', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 20,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            // Create Contact with non-matching Contact_Type__c
            contacts.add(new Contact(
                FirstName = 'Test3', 
                LastName = 'Contact3', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                reduivy__Sequence__c = 30,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            insert contacts;
            
            Test.stopTest();

            // Verify rollup calculation - should sum only matching records (10 + 20 = 30)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(30, updatedAccount.NumberOfEmployees, 'SUM rollup should only include Applicant contacts');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (insert contacts + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test SUM rollup on Sequence__c when Contact_Type__c changes between matching and non-matching (Applicant)
     */
    @IsTest
    static void testSumRollupContactTypeTransitionAsAdmin() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            // Create test Account
            Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
            insert testAccount;

            // Create initial Contact as CON_Helper.CONTACT_TYPE_STUDENT
            Contact testContact = new Contact(
                FirstName = 'Test', 
                LastName = 'Contact', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                reduivy__Sequence__c = 50,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            );
            insert testContact;

            Test.startTest();
            
            // Change Contact_Type__c to CON_Helper.CONTACT_TYPE_APPLICANT to trigger rollup
            testContact.reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT;
            update testContact;
            
            Test.stopTest();

            // Verify rollup calculation - should now include this contact (50)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(50, updatedAccount.NumberOfEmployees, 'SUM rollup should include contact after type change to Applicant');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (update contact + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test SUM rollup on Sequence__c when matching and non-matching Contacts are deleted
     */
    @IsTest
    static void testSumRollupOnContactDeletionAsAdmin() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            // Create test Account
            Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
            insert testAccount;

            // Create Contacts - mix of matching and non-matching
            List<Contact> contacts = new List<Contact>();
            contacts.add(new Contact(
                FirstName = 'Test1', 
                LastName = 'Contact1', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 15,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test2', 
                LastName = 'Contact2', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 25,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test3', 
                LastName = 'Contact3', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                reduivy__Sequence__c = 35,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            insert contacts;

            Test.startTest();
            
            // Delete one matching and one non-matching contact
            delete new List<Contact>{contacts[0], contacts[2]};
            
            Test.stopTest();

            // Verify rollup calculation - should only have remaining Applicant contact (25)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(25, updatedAccount.NumberOfEmployees, 'SUM rollup should reflect remaining Applicant contact after deletion');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (delete contacts + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test SUM rollup in bulk operations with mixed matching and non-matching Contacts
     */
    @IsTest
    static void testSumRollupBulkMixedMatchingAndNonMatchingContactsAsAdmin() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            // Create test Account
            Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
            insert testAccount;

            Test.startTest();
            
            // Create bulk Contacts with mixed types
            List<Contact> contacts = new List<Contact>();
            Decimal expectedSum = 0;
            
            // Add 100 Applicant contacts
            for(Integer i = 0; i < 100; i++) {
                Decimal sequenceValue = (i + 1) * 2; // 2, 4, 6, 8, ...
                contacts.add(new Contact(
                    FirstName = CON_Helper.CONTACT_TYPE_APPLICANT + i, 
                    LastName = 'Contact' + i, 
                    AccountId = testAccount.Id,
                    reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                    reduivy__Sequence__c = sequenceValue,
                    reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
                ));
                expectedSum += sequenceValue;
            }
            
            // Add 50 non-matching contacts (should not be included in sum)
            for(Integer i = 0; i < 50; i++) {
                contacts.add(new Contact(
                    FirstName = CON_Helper.CONTACT_TYPE_STUDENT + i, 
                    LastName = 'Contact' + i, 
                    AccountId = testAccount.Id,
                    reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                    reduivy__Sequence__c = (i + 1) * 10,
                    reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
                ));
            }
            
            insert contacts;
            
            Test.stopTest();

            // Verify rollup calculation - should sum only Applicant contacts
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(expectedSum, updatedAccount.NumberOfEmployees, 'SUM rollup should only include Applicant contacts in bulk operation');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (bulk insert + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test MIN rollup on Sequence__c for matching Contact_Type__c (Applicant)
     */
    @IsTest
    static void testMinRollupForMatchingContactsAsAdmin() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MAX', 'ACC_CON_Sample_SUM'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            // Create test Account
            Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
            insert testAccount;

            Test.startTest();
            
            // Create Contacts with varying sequence values
            List<Contact> contacts = new List<Contact>();
            contacts.add(new Contact(
                FirstName = 'Test1', 
                LastName = 'Contact1', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 100,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test2', 
                LastName = 'Contact2', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 5, // This should be the minimum
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test3', 
                LastName = 'Contact3', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 50,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            // Add non-matching contact with lower value (should be ignored)
            contacts.add(new Contact(
                FirstName = 'Test4', 
                LastName = 'Contact4', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                reduivy__Sequence__c = 1,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            insert contacts;
            
            Test.stopTest();

            // Verify MIN rollup calculation - should be 5 (minimum among Applicants only)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(5, updatedAccount.NumberOfEmployees, 'MIN rollup should return minimum value among Applicant contacts only');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (insert contacts + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test MAX rollup on Sequence__c for matching Contact_Type__c (Applicant)
     */
    @IsTest
    static void testMaxRollupForMatchingContactsAsAdmin() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MIN', 'ACC_CON_Sample_SUM'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            // Create test Account
            Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
            insert testAccount;

            Test.startTest();
            
            // Create Contacts with varying sequence values
            List<Contact> contacts = new List<Contact>();
            contacts.add(new Contact(
                FirstName = 'Test1', 
                LastName = 'Contact1', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 10,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test2', 
                LastName = 'Contact2', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 75, // This should be the maximum
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test3', 
                LastName = 'Contact3', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 50,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            // Add non-matching contact with higher value (should be ignored)
            contacts.add(new Contact(
                FirstName = 'Test4', 
                LastName = 'Contact4', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                reduivy__Sequence__c = 200,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            insert contacts;
            
            Test.stopTest();

            // Verify MAX rollup calculation - should be 75 (maximum among Applicants only)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(75, updatedAccount.NumberOfEmployees, 'MAX rollup should return maximum value among Applicant contacts only');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (insert contacts + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test COUNT rollup for matching Contact_Type__c (Applicant)
     */
    @IsTest
    static void testCountRollupForMatchingContactsAsAdmin() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN', 'ACC_CON_Sample_SUM'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            // Create test Account
            Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
            insert testAccount;

            Test.startTest();
            
            // Create mix of Applicant and non-Applicant contacts
            List<Contact> contacts = new List<Contact>();
            
            // Add 3 Applicant contacts
            for(Integer i = 0; i < 3; i++) {
                contacts.add(new Contact(
                    FirstName = CON_Helper.CONTACT_TYPE_APPLICANT + i, 
                    LastName = 'Contact' + i, 
                    AccountId = testAccount.Id,
                    reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                    reduivy__Sequence__c = (i + 1) * 10,
                    reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
                ));
            }
            
            // Add 2 non-Applicant contacts (should not be counted)
            for(Integer i = 0; i < 2; i++) {
                contacts.add(new Contact(
                    FirstName = CON_Helper.CONTACT_TYPE_STUDENT + i, 
                    LastName = 'Contact' + i, 
                    AccountId = testAccount.Id,
                    reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                    reduivy__Sequence__c = (i + 1) * 5,
                    reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
                ));
            }
            
            insert contacts;
            
            Test.stopTest();

            // Verify COUNT rollup calculation - should count only Applicant contacts (3)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(3, updatedAccount.NumberOfEmployees, 'COUNT rollup should count only Applicant contacts');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (insert contacts + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test rollup condition filter transitions - match to non-match to match again
     * This tests the efficiency of the rollup logic when records transition between matching and non-matching states
     */
    @IsTest
    static void testRollupConditionFilterTransitionsAsAdmin() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN', 'ACC_CON_Sample_SUM'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            // Create test Account
            Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
            insert testAccount;

            // Create initial contacts - one matching, one non-matching
            List<Contact> contacts = new List<Contact>();
            contacts.add(new Contact(
                FirstName = 'Test1', 
                LastName = 'Contact1', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT, // Initially matching
                reduivy__Sequence__c = 10,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test2', 
                LastName = 'Contact2', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT, // Initially non-matching
                reduivy__Sequence__c = 20,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            insert contacts;

            // Verify initial state - should count 1 Applicant
            Account initialAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(1, initialAccount.NumberOfEmployees, 'Initial count should be 1 for single Applicant');

            // Reset limits tracking for transition testing
            Test.startTest();
            
            // Phase 1: Change matching contact to non-matching (Applicant -> Other)
            contacts[0].reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT;
            update contacts[0];
            
            Integer dmlRowsPhase1 = Limits.getDmlRows();
            Integer queryCountPhase1 = Limits.getQueries();
            Integer queryRowsPhase1 = Limits.getQueryRows();
            
            // Verify rollup updated - should now be 0
            Account phase1Account = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(0, phase1Account.NumberOfEmployees, 'Count should be 0 after changing Applicant to Other');
            
            // Phase 2: Change non-matching contact to matching (Other -> Applicant)
            contacts[1].reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT;
            update contacts[1];
            
            Integer dmlRowsPhase2 = Limits.getDmlRows();
            Integer queryCountPhase2 = Limits.getQueries();
            Integer queryRowsPhase2 = Limits.getQueryRows();
            
            // Verify rollup updated - should now be 1 again
            Account phase2Account = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(1, phase2Account.NumberOfEmployees, 'Count should be 1 after changing Other to Applicant');
            
            // Phase 3: Change both contacts - one back to matching, one to non-matching
            contacts[0].reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT; // Other -> Applicant
            contacts[1].reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT;     // Applicant -> Other
            update contacts;
            
            Integer dmlRowsPhase3 = Limits.getDmlRows();
            Integer queryCountPhase3 = Limits.getQueries();
            Integer queryRowsPhase3 = Limits.getQueryRows();
            
            // Verify rollup updated - should still be 1
            Account phase3Account = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(1, phase3Account.NumberOfEmployees, 'Count should be 1 after contact type swaps');
            
            // Phase 4: Update sequence value without changing type (should trigger minimal processing)
            contacts[0].reduivy__Sequence__c = 50; // Still Applicant, just changing sequence
            update contacts[0];
            
            Integer dmlRowsPhase4 = Limits.getDmlRows();
            Integer queryCountPhase4 = Limits.getQueries();
            Integer queryRowsPhase4 = Limits.getQueryRows();
            
            // Verify rollup still correct - count should remain 1
            Account phase4Account = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(1, phase4Account.NumberOfEmployees, 'Count should remain 1 after sequence change on matching record');
            
            // Phase 5: Update non-matching record (should NOT trigger rollup processing)
            contacts[1].reduivy__Sequence__c = 100; // Still Other type, changing sequence
            update contacts[1];
            
            Integer dmlRowsPhase5 = Limits.getDmlRows();
            Integer queryCountPhase5 = Limits.getQueries();
            Integer queryRowsPhase5 = Limits.getQueryRows();
            
            Test.stopTest();

            // Final verification
            Account finalAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(1, finalAccount.NumberOfEmployees, 'Final count should remain 1');

            // Assert DML efficiency - each phase should have performed updates
            System.Assert.isTrue(dmlRowsPhase1 > 0, 'Phase 1: Should perform DML for match->non-match transition! Actual: ' + dmlRowsPhase1);
            System.Assert.isTrue(dmlRowsPhase2 > dmlRowsPhase1, 'Phase 2: Should perform additional DML for non-match->match transition! Actual: ' + dmlRowsPhase2);
            System.Assert.isTrue(dmlRowsPhase3 > dmlRowsPhase2, 'Phase 3: Should perform additional DML for bulk type changes! Actual: ' + dmlRowsPhase3);
            System.Assert.isTrue(dmlRowsPhase4 > dmlRowsPhase3, 'Phase 4: Should perform DML for sequence change on matching record! Actual: ' + dmlRowsPhase4);
            
            // Phase 5 should be the most efficient - updating non-matching record should have minimal impact
            Integer phase5DmlDelta = dmlRowsPhase5 - dmlRowsPhase4;
            System.Assert.isTrue(phase5DmlDelta <= 2, 'Phase 5: Should have minimal DML impact for non-matching record update! Delta: ' + phase5DmlDelta);

            // Assert query efficiency - should have queries for each phase that affects matching records
            System.Assert.isTrue(queryCountPhase1 > 0, 'Phase 1: Should perform queries for match->non-match transition! Actual: ' + queryCountPhase1);
            System.Assert.isTrue(queryCountPhase2 > queryCountPhase1, 'Phase 2: Should perform additional queries for non-match->match transition! Actual: ' + queryCountPhase2);
            System.Assert.isTrue(queryCountPhase3 > queryCountPhase2, 'Phase 3: Should perform additional queries for bulk changes! Actual: ' + queryCountPhase3);
            System.Assert.isTrue(queryCountPhase4 > queryCountPhase3, 'Phase 4: Should perform queries for matching record field change! Actual: ' + queryCountPhase4);
            
            // Query efficiency check - Phase 5 should be most efficient
            Integer phase5QueryDelta = queryCountPhase5 - queryCountPhase4;
            System.Assert.isTrue(phase5QueryDelta <= 2, 'Phase 5: Should have minimal query impact for non-matching record update! Delta: ' + phase5QueryDelta);

            // Assert query rows returned
            System.Assert.isTrue(queryRowsPhase3 > 0, 'Should return query rows for rollup calculations! Actual: ' + queryRowsPhase3);
        }
    }

    /**
     * @description Test SUM rollup on Sequence__c with matching and non-matching Contact_Type__c (Applicant)
     */
    @IsTest
    static void testSumRollupMatchingAndNonMatchingContactsAsFaculty() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER) {
            // Create test Account
            Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
            insert testAccount;

            Test.startTest();
            
            // Create Contacts with matching Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT
            List<Contact> contacts = new List<Contact>();
            contacts.add(new Contact(
                FirstName = 'Test1', 
                LastName = 'Contact1', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 10,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test2', 
                LastName = 'Contact2', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 20,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            // Create Contact with non-matching Contact_Type__c
            contacts.add(new Contact(
                FirstName = 'Test3', 
                LastName = 'Contact3', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                reduivy__Sequence__c = 30,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            insert contacts;
            
            Test.stopTest();

            // Verify rollup calculation - should sum only matching records (10 + 20 = 30)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(30, updatedAccount.NumberOfEmployees, 'SUM rollup should only include Applicant contacts');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (insert contacts + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test SUM rollup on Sequence__c when Contact_Type__c changes between matching and non-matching (Applicant)
     */
    @IsTest
    static void testSumRollupContactTypeTransitionAsFaculty() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER) {
            // Create test Account
            Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
            insert testAccount;

            // Create initial Contact as CON_Helper.CONTACT_TYPE_STUDENT
            Contact testContact = new Contact(
                FirstName = 'Test', 
                LastName = 'Contact', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                reduivy__Sequence__c = 50,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            );
            insert testContact;

            Test.startTest();
            
            // Change Contact_Type__c to CON_Helper.CONTACT_TYPE_APPLICANT to trigger rollup
            testContact.reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT;
            update testContact;
            
            Test.stopTest();

            // Verify rollup calculation - should now include this contact (50)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(50, updatedAccount.NumberOfEmployees, 'SUM rollup should include contact after type change to Applicant');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (update contact + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test SUM rollup on Sequence__c when matching and non-matching Contacts are deleted
     */
    @IsTest
    static void testSumRollupOnContactDeletionAsFaculty() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER) {
            // Create test Account
            Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
            insert testAccount;

            // Create Contacts - mix of matching and non-matching
            List<Contact> contacts = new List<Contact>();
            contacts.add(new Contact(
                FirstName = 'Test1', 
                LastName = 'Contact1', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 15,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test2', 
                LastName = 'Contact2', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 25,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test3', 
                LastName = 'Contact3', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                reduivy__Sequence__c = 35,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            insert contacts;

            Test.startTest();
            
            // Delete one matching and one non-matching contact
            delete new List<Contact>{contacts[0], contacts[2]};
            
            Test.stopTest();

            // Verify rollup calculation - should only have remaining Applicant contact (25)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(25, updatedAccount.NumberOfEmployees, 'SUM rollup should reflect remaining Applicant contact after deletion');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (delete contacts + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test SUM rollup in bulk operations with mixed matching and non-matching Contacts
     */
    @IsTest
    static void testSumRollupBulkMixedMatchingAndNonMatchingContactsAsFaculty() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER) {
            // Create test Account
            Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
            insert testAccount;

            Test.startTest();
            
            // Create bulk Contacts with mixed types
            List<Contact> contacts = new List<Contact>();
            Decimal expectedSum = 0;
            
            // Add 100 Applicant contacts
            for(Integer i = 0; i < 100; i++) {
                Decimal sequenceValue = (i + 1) * 2; // 2, 4, 6, 8, ...
                contacts.add(new Contact(
                    FirstName = CON_Helper.CONTACT_TYPE_APPLICANT + i, 
                    LastName = 'Contact' + i, 
                    AccountId = testAccount.Id,
                    reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                    reduivy__Sequence__c = sequenceValue,
                    reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
                ));
                expectedSum += sequenceValue;
            }
            
            // Add 50 non-matching contacts (should not be included in sum)
            for(Integer i = 0; i < 50; i++) {
                contacts.add(new Contact(
                    FirstName = CON_Helper.CONTACT_TYPE_STUDENT + i, 
                    LastName = 'Contact' + i, 
                    AccountId = testAccount.Id,
                    reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                    reduivy__Sequence__c = (i + 1) * 10,
                    reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
                ));
            }
            
            insert contacts;
            
            Test.stopTest();

            // Verify rollup calculation - should sum only Applicant contacts
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(expectedSum, updatedAccount.NumberOfEmployees, 'SUM rollup should only include Applicant contacts in bulk operation');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (bulk insert + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test MIN rollup on Sequence__c for matching Contact_Type__c (Applicant)
     */
    @IsTest
    static void testMinRollupForMatchingContactsAsFaculty() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MAX', 'ACC_CON_Sample_SUM'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER) {
            // Create test Account
            Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
            insert testAccount;

            Test.startTest();
            
            // Create Contacts with varying sequence values
            List<Contact> contacts = new List<Contact>();
            contacts.add(new Contact(
                FirstName = 'Test1', 
                LastName = 'Contact1', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 100,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test2', 
                LastName = 'Contact2', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 5, // This should be the minimum
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test3', 
                LastName = 'Contact3', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 50,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            // Add non-matching contact with lower value (should be ignored)
            contacts.add(new Contact(
                FirstName = 'Test4', 
                LastName = 'Contact4', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                reduivy__Sequence__c = 1,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            insert contacts;
            
            Test.stopTest();

            // Verify MIN rollup calculation - should be 5 (minimum among Applicants only)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(5, updatedAccount.NumberOfEmployees, 'MIN rollup should return minimum value among Applicant contacts only');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (insert contacts + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test MAX rollup on Sequence__c for matching Contact_Type__c (Applicant)
     */
    @IsTest
    static void testMaxRollupForMatchingContactsAsFaculty() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MIN', 'ACC_CON_Sample_SUM'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER) {
            // Create test Account
            Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
            insert testAccount;

            Test.startTest();
            
            // Create Contacts with varying sequence values
            List<Contact> contacts = new List<Contact>();
            contacts.add(new Contact(
                FirstName = 'Test1', 
                LastName = 'Contact1', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 10,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test2', 
                LastName = 'Contact2', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 75, // This should be the maximum
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test3', 
                LastName = 'Contact3', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 50,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            // Add non-matching contact with higher value (should be ignored)
            contacts.add(new Contact(
                FirstName = 'Test4', 
                LastName = 'Contact4', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                reduivy__Sequence__c = 200,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            insert contacts;
            
            Test.stopTest();

            // Verify MAX rollup calculation - should be 75 (maximum among Applicants only)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(75, updatedAccount.NumberOfEmployees, 'MAX rollup should return maximum value among Applicant contacts only');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (insert contacts + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test COUNT rollup for matching Contact_Type__c (Applicant)
     */
    @IsTest
    static void testCountRollupForMatchingContactsAsFaculty() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN', 'ACC_CON_Sample_SUM'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER) {
            // Create test Account
            Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
            insert testAccount;

            Test.startTest();
            
            // Create mix of Applicant and non-Applicant contacts
            List<Contact> contacts = new List<Contact>();
            
            // Add 3 Applicant contacts
            for(Integer i = 0; i < 3; i++) {
                contacts.add(new Contact(
                    FirstName = CON_Helper.CONTACT_TYPE_APPLICANT + i, 
                    LastName = 'Contact' + i, 
                    AccountId = testAccount.Id,
                    reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                    reduivy__Sequence__c = (i + 1) * 10,
                    reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
                ));
            }
            
            // Add 2 non-Applicant contacts (should not be counted)
            for(Integer i = 0; i < 2; i++) {
                contacts.add(new Contact(
                    FirstName = CON_Helper.CONTACT_TYPE_STUDENT + i, 
                    LastName = 'Contact' + i, 
                    AccountId = testAccount.Id,
                    reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                    reduivy__Sequence__c = (i + 1) * 5,
                    reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
                ));
            }
            
            insert contacts;
            
            Test.stopTest();

            // Verify COUNT rollup calculation - should count only Applicant contacts (3)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(3, updatedAccount.NumberOfEmployees, 'COUNT rollup should count only Applicant contacts');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (insert contacts + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test rollup condition filter transitions - match to non-match to match again
     * This tests the efficiency of the rollup logic when records transition between matching and non-matching states
     */
    @IsTest
    static void testRollupConditionFilterTransitionsAsFaculty() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN', 'ACC_CON_Sample_SUM'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER) {
            // Create test Account
            Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
            insert testAccount;

            // Create initial contacts - one matching, one non-matching
            List<Contact> contacts = new List<Contact>();
            contacts.add(new Contact(
                FirstName = 'Test1', 
                LastName = 'Contact1', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT, // Initially matching
                reduivy__Sequence__c = 10,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test2', 
                LastName = 'Contact2', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT, // Initially non-matching
                reduivy__Sequence__c = 20,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            insert contacts;

            // Verify initial state - should count 1 Applicant
            Account initialAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(1, initialAccount.NumberOfEmployees, 'Initial count should be 1 for single Applicant');

            // Reset limits tracking for transition testing
            Test.startTest();
            
            // Phase 1: Change matching contact to non-matching (Applicant -> Other)
            contacts[0].reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT;
            update contacts[0];
            
            Integer dmlRowsPhase1 = Limits.getDmlRows();
            Integer queryCountPhase1 = Limits.getQueries();
            Integer queryRowsPhase1 = Limits.getQueryRows();
            
            // Verify rollup updated - should now be 0
            Account phase1Account = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(0, phase1Account.NumberOfEmployees, 'Count should be 0 after changing Applicant to Other');
            
            // Phase 2: Change non-matching contact to matching (Other -> Applicant)
            contacts[1].reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT;
            update contacts[1];
            
            Integer dmlRowsPhase2 = Limits.getDmlRows();
            Integer queryCountPhase2 = Limits.getQueries();
            Integer queryRowsPhase2 = Limits.getQueryRows();
            
            // Verify rollup updated - should now be 1 again
            Account phase2Account = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(1, phase2Account.NumberOfEmployees, 'Count should be 1 after changing Other to Applicant');
            
            // Phase 3: Change both contacts - one back to matching, one to non-matching
            contacts[0].reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT; // Other -> Applicant
            contacts[1].reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT;     // Applicant -> Other
            update contacts;
            
            Integer dmlRowsPhase3 = Limits.getDmlRows();
            Integer queryCountPhase3 = Limits.getQueries();
            Integer queryRowsPhase3 = Limits.getQueryRows();
            
            // Verify rollup updated - should still be 1
            Account phase3Account = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(1, phase3Account.NumberOfEmployees, 'Count should be 1 after contact type swaps');
            
            // Phase 4: Update sequence value without changing type (should trigger minimal processing)
            contacts[0].reduivy__Sequence__c = 50; // Still Applicant, just changing sequence
            update contacts[0];
            
            Integer dmlRowsPhase4 = Limits.getDmlRows();
            Integer queryCountPhase4 = Limits.getQueries();
            Integer queryRowsPhase4 = Limits.getQueryRows();
            
            // Verify rollup still correct - count should remain 1
            Account phase4Account = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(1, phase4Account.NumberOfEmployees, 'Count should remain 1 after sequence change on matching record');
            
            // Phase 5: Update non-matching record (should NOT trigger rollup processing)
            contacts[1].reduivy__Sequence__c = 100; // Still Other type, changing sequence
            update contacts[1];
            
            Integer dmlRowsPhase5 = Limits.getDmlRows();
            Integer queryCountPhase5 = Limits.getQueries();
            Integer queryRowsPhase5 = Limits.getQueryRows();
            
            Test.stopTest();

            // Final verification
            Account finalAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(1, finalAccount.NumberOfEmployees, 'Final count should remain 1');

            // Assert DML efficiency - each phase should have performed updates
            System.Assert.isTrue(dmlRowsPhase1 > 0, 'Phase 1: Should perform DML for match->non-match transition! Actual: ' + dmlRowsPhase1);
            System.Assert.isTrue(dmlRowsPhase2 > dmlRowsPhase1, 'Phase 2: Should perform additional DML for non-match->match transition! Actual: ' + dmlRowsPhase2);
            System.Assert.isTrue(dmlRowsPhase3 > dmlRowsPhase2, 'Phase 3: Should perform additional DML for bulk type changes! Actual: ' + dmlRowsPhase3);
            System.Assert.isTrue(dmlRowsPhase4 > dmlRowsPhase3, 'Phase 4: Should perform DML for sequence change on matching record! Actual: ' + dmlRowsPhase4);
            
            // Phase 5 should be the most efficient - updating non-matching record should have minimal impact
            Integer phase5DmlDelta = dmlRowsPhase5 - dmlRowsPhase4;
            System.Assert.isTrue(phase5DmlDelta <= 2, 'Phase 5: Should have minimal DML impact for non-matching record update! Delta: ' + phase5DmlDelta);

            // Assert query efficiency - should have queries for each phase that affects matching records
            System.Assert.isTrue(queryCountPhase1 > 0, 'Phase 1: Should perform queries for match->non-match transition! Actual: ' + queryCountPhase1);
            System.Assert.isTrue(queryCountPhase2 > queryCountPhase1, 'Phase 2: Should perform additional queries for non-match->match transition! Actual: ' + queryCountPhase2);
            System.Assert.isTrue(queryCountPhase3 > queryCountPhase2, 'Phase 3: Should perform additional queries for bulk changes! Actual: ' + queryCountPhase3);
            System.Assert.isTrue(queryCountPhase4 > queryCountPhase3, 'Phase 4: Should perform queries for matching record field change! Actual: ' + queryCountPhase4);
            
            // Query efficiency check - Phase 5 should be most efficient
            Integer phase5QueryDelta = queryCountPhase5 - queryCountPhase4;
            System.Assert.isTrue(phase5QueryDelta <= 2, 'Phase 5: Should have minimal query impact for non-matching record update! Delta: ' + phase5QueryDelta);

            // Assert query rows returned
            System.Assert.isTrue(queryRowsPhase3 > 0, 'Should return query rows for rollup calculations! Actual: ' + queryRowsPhase3);
        }
    }

    /**
     * @description Test SUM rollup on Sequence__c with matching and non-matching Contact_Type__c (Applicant)
     */
    @IsTest
    static void testSumRollupMatchingAndNonMatchingContactsAsStudent() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN'});

        // Get existing student contact and user
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        // Create test Account
        Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
        insert testAccount;

        System.runAs(studentUser) {

            Test.startTest();
            
            // Create Contacts with matching Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT
            List<Contact> contacts = new List<Contact>();
            contacts.add(new Contact(
                FirstName = 'Test1', 
                LastName = 'Contact1', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 10,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test2', 
                LastName = 'Contact2', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 20,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            // Create Contact with non-matching Contact_Type__c
            contacts.add(new Contact(
                FirstName = 'Test3', 
                LastName = 'Contact3', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                reduivy__Sequence__c = 30,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            insert contacts;
            
            Test.stopTest();

            // Verify rollup calculation - should sum only matching records (10 + 20 = 30)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(30, updatedAccount.NumberOfEmployees, 'SUM rollup should only include Applicant contacts');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (insert contacts + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test SUM rollup on Sequence__c when Contact_Type__c changes between matching and non-matching (Applicant)
     */
    @IsTest
    static void testSumRollupContactTypeTransitionAsStudent() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN'});

        // Get existing student contact and user
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        // Create test Account
        Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
        insert testAccount;

        System.runAs(studentUser) {

            // Create initial Contact as CON_Helper.CONTACT_TYPE_STUDENT
            Contact testContact = new Contact(
                FirstName = 'Test', 
                LastName = 'Contact', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                reduivy__Sequence__c = 50,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            );
            insert testContact;

            Test.startTest();
            
            // Change Contact_Type__c to CON_Helper.CONTACT_TYPE_APPLICANT to trigger rollup
            testContact.reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT;
            update testContact;
            
            Test.stopTest();

            // Verify rollup calculation - should now include this contact (50)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(50, updatedAccount.NumberOfEmployees, 'SUM rollup should include contact after type change to Applicant');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (update contact + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test SUM rollup on Sequence__c when matching and non-matching Contacts are deleted
     */
    @IsTest
    static void testSumRollupOnContactDeletionAsStudent() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN'});

        // Get existing student contact and user
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        // Create test Account
        Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
        insert testAccount;

        System.runAs(studentUser) {

            // Create Contacts - mix of matching and non-matching
            List<Contact> contacts = new List<Contact>();
            contacts.add(new Contact(
                FirstName = 'Test1', 
                LastName = 'Contact1', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 15,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test2', 
                LastName = 'Contact2', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 25,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test3', 
                LastName = 'Contact3', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                reduivy__Sequence__c = 35,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            insert contacts;

            Test.startTest();
            
            // Delete one matching and one non-matching contact
            delete new List<Contact>{contacts[0], contacts[2]};
            
            Test.stopTest();

            // Verify rollup calculation - should only have remaining Applicant contact (25)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(25, updatedAccount.NumberOfEmployees, 'SUM rollup should reflect remaining Applicant contact after deletion');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (delete contacts + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test SUM rollup in bulk operations with mixed matching and non-matching Contacts
     */
    @IsTest
    static void testSumRollupBulkMixedMatchingAndNonMatchingContactsAsStudent() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN'});

        // Get existing student contact and user
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        // Create test Account
        Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
        insert testAccount;

        System.runAs(studentUser) {

            Test.startTest();
            
            // Create bulk Contacts with mixed types
            List<Contact> contacts = new List<Contact>();
            Decimal expectedSum = 0;
            
            // Add 100 Applicant contacts
            for(Integer i = 0; i < 100; i++) {
                Decimal sequenceValue = (i + 1) * 2; // 2, 4, 6, 8, ...
                contacts.add(new Contact(
                    FirstName = CON_Helper.CONTACT_TYPE_APPLICANT + i, 
                    LastName = 'Contact' + i, 
                    AccountId = testAccount.Id,
                    reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                    reduivy__Sequence__c = sequenceValue,
                    reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
                ));
                expectedSum += sequenceValue;
            }
            
            // Add 50 non-matching contacts (should not be included in sum)
            for(Integer i = 0; i < 50; i++) {
                contacts.add(new Contact(
                    FirstName = CON_Helper.CONTACT_TYPE_STUDENT + i, 
                    LastName = 'Contact' + i, 
                    AccountId = testAccount.Id,
                    reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                    reduivy__Sequence__c = (i + 1) * 10,
                    reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
                ));
            }
            
            insert contacts;
            
            Test.stopTest();

            // Verify rollup calculation - should sum only Applicant contacts
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(expectedSum, updatedAccount.NumberOfEmployees, 'SUM rollup should only include Applicant contacts in bulk operation');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (bulk insert + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test MIN rollup on Sequence__c for matching Contact_Type__c (Applicant)
     */
    @IsTest
    static void testMinRollupForMatchingContactsAsStudent() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MAX', 'ACC_CON_Sample_SUM'});

        // Get existing student contact and user
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        // Create test Account
        Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
        insert testAccount;

        System.runAs(studentUser) {

            Test.startTest();
            
            // Create Contacts with varying sequence values
            List<Contact> contacts = new List<Contact>();
            contacts.add(new Contact(
                FirstName = 'Test1', 
                LastName = 'Contact1', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 100,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test2', 
                LastName = 'Contact2', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 5, // This should be the minimum
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test3', 
                LastName = 'Contact3', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 50,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            // Add non-matching contact with lower value (should be ignored)
            contacts.add(new Contact(
                FirstName = 'Test4', 
                LastName = 'Contact4', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                reduivy__Sequence__c = 1,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            insert contacts;
            
            Test.stopTest();

            // Verify MIN rollup calculation - should be 5 (minimum among Applicants only)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(5, updatedAccount.NumberOfEmployees, 'MIN rollup should return minimum value among Applicant contacts only');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (insert contacts + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test MAX rollup on Sequence__c for matching Contact_Type__c (Applicant)
     */
    @IsTest
    static void testMaxRollupForMatchingContactsAsStudent() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_COUNT', 'ACC_CON_Sample_MIN', 'ACC_CON_Sample_SUM'});

        // Get existing student contact and user
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        // Create test Account
        Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
        insert testAccount;

        System.runAs(studentUser) {

            Test.startTest();
            
            // Create Contacts with varying sequence values
            List<Contact> contacts = new List<Contact>();
            contacts.add(new Contact(
                FirstName = 'Test1', 
                LastName = 'Contact1', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 10,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test2', 
                LastName = 'Contact2', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 75, // This should be the maximum
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test3', 
                LastName = 'Contact3', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                reduivy__Sequence__c = 50,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            // Add non-matching contact with higher value (should be ignored)
            contacts.add(new Contact(
                FirstName = 'Test4', 
                LastName = 'Contact4', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                reduivy__Sequence__c = 200,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            insert contacts;
            
            Test.stopTest();

            // Verify MAX rollup calculation - should be 75 (maximum among Applicants only)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(75, updatedAccount.NumberOfEmployees, 'MAX rollup should return maximum value among Applicant contacts only');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (insert contacts + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test COUNT rollup for matching Contact_Type__c (Applicant)
     */
    @IsTest
    static void testCountRollupForMatchingContactsAsStudent() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN', 'ACC_CON_Sample_SUM'});

        // Get existing student contact and user
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        // Create test Account
        Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
        insert testAccount;

        System.runAs(studentUser) {

            Test.startTest();
            
            // Create mix of Applicant and non-Applicant contacts
            List<Contact> contacts = new List<Contact>();
            
            // Add 3 Applicant contacts
            for(Integer i = 0; i < 3; i++) {
                contacts.add(new Contact(
                    FirstName = CON_Helper.CONTACT_TYPE_APPLICANT + i, 
                    LastName = 'Contact' + i, 
                    AccountId = testAccount.Id,
                    reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
                    reduivy__Sequence__c = (i + 1) * 10,
                    reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
                ));
            }
            
            // Add 2 non-Applicant contacts (should not be counted)
            for(Integer i = 0; i < 2; i++) {
                contacts.add(new Contact(
                    FirstName = CON_Helper.CONTACT_TYPE_STUDENT + i, 
                    LastName = 'Contact' + i, 
                    AccountId = testAccount.Id,
                    reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
                    reduivy__Sequence__c = (i + 1) * 5,
                    reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
                ));
            }
            
            insert contacts;
            
            Test.stopTest();

            // Verify COUNT rollup calculation - should count only Applicant contacts (3)
            Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(3, updatedAccount.NumberOfEmployees, 'COUNT rollup should count only Applicant contacts');

            // Check limits
            Integer dmlRows = Limits.getDmlRows();
            Integer queryCount = Limits.getQueries();
            Integer queryRows = Limits.getQueryRows();

            System.Assert.isTrue(dmlRows > 1, 'Should be more than 1 dml row performed (insert contacts + update parent fields)! Actual: ' + dmlRows);
            System.Assert.isTrue(queryCount > 0, 'SOQL query should be performed in the OBJ class! Actual: ' + queryCount);
            System.Assert.isTrue(queryRows > 0, 'Should be more than 0 rows queried in the OBJ class! Actual: ' + queryRows);
        }
    }

    /**
     * @description Test rollup condition filter transitions - match to non-match to match again
     * This tests the efficiency of the rollup logic when records transition between matching and non-matching states
     */
    @IsTest
    static void testRollupConditionFilterTransitionsAsStudent() {
        REDU_CustomRollupController.muteRollups(new Set<String>{'ACC_CON_Sample_MAX', 'ACC_CON_Sample_MIN', 'ACC_CON_Sample_SUM'});

        // Get existing student contact and user
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        // Create test Account
        Account testAccount = new Account(Name = 'Test Account', reduivy__Sample_Record_Code__c = 'ROLLUP_TEST');
        insert testAccount;

        System.runAs(studentUser) {

            // Create initial contacts - one matching, one non-matching
            List<Contact> contacts = new List<Contact>();
            contacts.add(new Contact(
                FirstName = 'Test1', 
                LastName = 'Contact1', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT, // Initially matching
                reduivy__Sequence__c = 10,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            contacts.add(new Contact(
                FirstName = 'Test2', 
                LastName = 'Contact2', 
                AccountId = testAccount.Id,
                reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT, // Initially non-matching
                reduivy__Sequence__c = 20,
                reduivy__Sample_Record_Code__c = 'ROLLUP_TEST'
            ));
            
            insert contacts;

            // Verify initial state - should count 1 Applicant
            Account initialAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(1, initialAccount.NumberOfEmployees, 'Initial count should be 1 for single Applicant');

            // Reset limits tracking for transition testing
            Test.startTest();
            
            // Phase 1: Change matching contact to non-matching (Applicant -> Other)
            contacts[0].reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT;
            update contacts[0];
            
            Integer dmlRowsPhase1 = Limits.getDmlRows();
            Integer queryCountPhase1 = Limits.getQueries();
            Integer queryRowsPhase1 = Limits.getQueryRows();
            
            // Verify rollup updated - should now be 0
            Account phase1Account = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(0, phase1Account.NumberOfEmployees, 'Count should be 0 after changing Applicant to Other');
            
            // Phase 2: Change non-matching contact to matching (Other -> Applicant)
            contacts[1].reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT;
            update contacts[1];
            
            Integer dmlRowsPhase2 = Limits.getDmlRows();
            Integer queryCountPhase2 = Limits.getQueries();
            Integer queryRowsPhase2 = Limits.getQueryRows();
            
            // Verify rollup updated - should now be 1 again
            Account phase2Account = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(1, phase2Account.NumberOfEmployees, 'Count should be 1 after changing Other to Applicant');
            
            // Phase 3: Change both contacts - one back to matching, one to non-matching
            contacts[0].reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT; // Other -> Applicant
            contacts[1].reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT;     // Applicant -> Other
            update contacts;
            
            Integer dmlRowsPhase3 = Limits.getDmlRows();
            Integer queryCountPhase3 = Limits.getQueries();
            Integer queryRowsPhase3 = Limits.getQueryRows();
            
            // Verify rollup updated - should still be 1
            Account phase3Account = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(1, phase3Account.NumberOfEmployees, 'Count should be 1 after contact type swaps');
            
            // Phase 4: Update sequence value without changing type (should trigger minimal processing)
            contacts[0].reduivy__Sequence__c = 50; // Still Applicant, just changing sequence
            update contacts[0];
            
            Integer dmlRowsPhase4 = Limits.getDmlRows();
            Integer queryCountPhase4 = Limits.getQueries();
            Integer queryRowsPhase4 = Limits.getQueryRows();
            
            // Verify rollup still correct - count should remain 1
            Account phase4Account = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(1, phase4Account.NumberOfEmployees, 'Count should remain 1 after sequence change on matching record');
            
            // Phase 5: Update non-matching record (should NOT trigger rollup processing)
            contacts[1].reduivy__Sequence__c = 100; // Still Other type, changing sequence
            update contacts[1];
            
            Integer dmlRowsPhase5 = Limits.getDmlRows();
            Integer queryCountPhase5 = Limits.getQueries();
            Integer queryRowsPhase5 = Limits.getQueryRows();
            
            Test.stopTest();

            // Final verification
            Account finalAccount = [SELECT NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(1, finalAccount.NumberOfEmployees, 'Final count should remain 1');

            // Assert DML efficiency - each phase should have performed updates
            System.Assert.isTrue(dmlRowsPhase1 > 0, 'Phase 1: Should perform DML for match->non-match transition! Actual: ' + dmlRowsPhase1);
            System.Assert.isTrue(dmlRowsPhase2 > dmlRowsPhase1, 'Phase 2: Should perform additional DML for non-match->match transition! Actual: ' + dmlRowsPhase2);
            System.Assert.isTrue(dmlRowsPhase3 > dmlRowsPhase2, 'Phase 3: Should perform additional DML for bulk type changes! Actual: ' + dmlRowsPhase3);
            System.Assert.isTrue(dmlRowsPhase4 > dmlRowsPhase3, 'Phase 4: Should perform DML for sequence change on matching record! Actual: ' + dmlRowsPhase4);
            
            // Phase 5 should be the most efficient - updating non-matching record should have minimal impact
            Integer phase5DmlDelta = dmlRowsPhase5 - dmlRowsPhase4;
            System.Assert.isTrue(phase5DmlDelta <= 2, 'Phase 5: Should have minimal DML impact for non-matching record update! Delta: ' + phase5DmlDelta);

            // Assert query efficiency - should have queries for each phase that affects matching records
            System.Assert.isTrue(queryCountPhase1 > 0, 'Phase 1: Should perform queries for match->non-match transition! Actual: ' + queryCountPhase1);
            System.Assert.isTrue(queryCountPhase2 > queryCountPhase1, 'Phase 2: Should perform additional queries for non-match->match transition! Actual: ' + queryCountPhase2);
            System.Assert.isTrue(queryCountPhase3 > queryCountPhase2, 'Phase 3: Should perform additional queries for bulk changes! Actual: ' + queryCountPhase3);
            System.Assert.isTrue(queryCountPhase4 > queryCountPhase3, 'Phase 4: Should perform queries for matching record field change! Actual: ' + queryCountPhase4);
            
            // Query efficiency check - Phase 5 should be most efficient
            Integer phase5QueryDelta = queryCountPhase5 - queryCountPhase4;
            System.Assert.isTrue(phase5QueryDelta <= 2, 'Phase 5: Should have minimal query impact for non-matching record update! Delta: ' + phase5QueryDelta);

            // Assert query rows returned
            System.Assert.isTrue(queryRowsPhase3 > 0, 'Should return query rows for rollup calculations! Actual: ' + queryRowsPhase3);
        }
    }

    /**
     * @description Test rollup condition filter with relationship field as admin
     */
    @IsTest
    static void testRollupConditionWithRelationshipFieldAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Custom_Rollup_Config__mdt mockConfig = new reduivy__Custom_Rollup_Config__mdt();
        mockConfig.reduivy__Master_Object_Name__c = 'Account';
        mockConfig.reduivy__Child_Object_Name__c = 'Contact';
        mockConfig.reduivy__Parent_Relationship_Field__c = 'AccountId';
        mockConfig.reduivy__Child_Object_Field_Name__c = 'reduivy__Contact_Type__c';
        mockConfig.reduivy__Master_Object_Field_Name__c = 'NumberOfEmployees';
        mockConfig.reduivy__Rollup_Type__c = 'COUNT';
        mockConfig.reduivy__Field_Type__c = 'INTEGER';
        mockConfig.reduivy__Filter_Logic__c = '{0}';
        mockConfig.reduivy__Filter_Criteria_1__c = 'reduivy__Contact_Type__c = \'Applicant\'';
        mockConfig.reduivy__Rollup_Condition_Logic__c = '{0}';
        mockConfig.reduivy__Rollup_Condition_Formula_1__c = 'Account.RecordTypeId = null';
        
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> rollupConfigsByParentObject = 
            new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        rollupConfigsByParentObject.put('Account', new List<reduivy__Custom_Rollup_Config__mdt>{mockConfig});
        
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.reduivy__Sample_Record_Code__c = 'ROLLUP_TEST';
        insert testAccount;
        
        Contact testContact = new Contact();
        testContact.LastName = 'Test Contact';
        testContact.AccountId = testAccount.Id;
        testContact.reduivy__Sample_Record_Code__c = 'ROLLUP_TEST';
        
        if (Schema.sObjectType.Contact.fields.getMap().containsKey('reduivy__Contact_Type__c')) {
            testContact.put('reduivy__Contact_Type__c', 'Applicant');
        }
        
        insert testContact;
        
        List<Contact> contactList = new List<Contact>{testContact};
        List<SObject> testObjects = (List<SObject>)contactList;
        
        REDU_CustomRollup_OBJ rollupInstance = new REDU_CustomRollup_OBJ(
            testObjects,
            new List<SObject>(),
            rollupConfigsByParentObject
        );
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            try {
                rollupInstance.doRollup();
                System.Assert.fail('An exception should have been thrown');
            } catch (REDU_ApplicationException ex) {
                String expectedMsg = String.format(Label.Rollup_Conditions_Not_Allow_Relationship_Field_Error, new List<String>{'Account.RecordTypeId'});

                System.Assert.isTrue(
                    ex.getMessage().contains(expectedMsg),
                    'Invalid message: ' + ex.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test rollup condition filter with relationship field as faculty
     */
    @IsTest
    static void testRollupConditionWithRelationshipFieldAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        reduivy__Custom_Rollup_Config__mdt mockConfig = new reduivy__Custom_Rollup_Config__mdt();
        mockConfig.reduivy__Master_Object_Name__c = 'Account';
        mockConfig.reduivy__Child_Object_Name__c = 'Contact';
        mockConfig.reduivy__Parent_Relationship_Field__c = 'AccountId';
        mockConfig.reduivy__Child_Object_Field_Name__c = 'reduivy__Contact_Type__c';
        mockConfig.reduivy__Master_Object_Field_Name__c = 'NumberOfEmployees';
        mockConfig.reduivy__Rollup_Type__c = 'COUNT';
        mockConfig.reduivy__Field_Type__c = 'INTEGER';
        mockConfig.reduivy__Filter_Logic__c = '{0}';
        mockConfig.reduivy__Filter_Criteria_1__c = 'reduivy__Contact_Type__c = \'Applicant\'';
        mockConfig.reduivy__Rollup_Condition_Logic__c = '{0}';
        mockConfig.reduivy__Rollup_Condition_Formula_1__c = 'Account.RecordTypeId = null';
        
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> rollupConfigsByParentObject = 
            new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        rollupConfigsByParentObject.put('Account', new List<reduivy__Custom_Rollup_Config__mdt>{mockConfig});
        
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.reduivy__Sample_Record_Code__c = 'ROLLUP_TEST';
        insert testAccount;
        
        Contact testContact = new Contact();
        testContact.LastName = 'Test Contact';
        testContact.AccountId = testAccount.Id;
        testContact.reduivy__Sample_Record_Code__c = 'ROLLUP_TEST';
        
        if (Schema.sObjectType.Contact.fields.getMap().containsKey('reduivy__Contact_Type__c')) {
            testContact.put('reduivy__Contact_Type__c', 'Applicant');
        }
        
        insert testContact;
        
        List<Contact> contactList = new List<Contact>{testContact};
        List<SObject> testObjects = (List<SObject>)contactList;
        
        REDU_CustomRollup_OBJ rollupInstance = new REDU_CustomRollup_OBJ(
            testObjects,
            new List<SObject>(),
            rollupConfigsByParentObject
        );
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            try {
                rollupInstance.doRollup();
                System.Assert.fail('An exception should have been thrown');
            } catch (REDU_ApplicationException ex) {
                String expectedMsg = String.format(Label.Rollup_Conditions_Not_Allow_Relationship_Field_Error, new List<String>{'Account.RecordTypeId'});

                System.Assert.isTrue(
                    ex.getMessage().contains(expectedMsg),
                    'Invalid message: ' + ex.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test rollup condition filter with relationship field as student
     */
    @IsTest
    static void testRollupConditionWithRelationshipFieldAsStudent() {
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        reduivy__Custom_Rollup_Config__mdt mockConfig = new reduivy__Custom_Rollup_Config__mdt();
        mockConfig.reduivy__Master_Object_Name__c = 'Account';
        mockConfig.reduivy__Child_Object_Name__c = 'Contact';
        mockConfig.reduivy__Parent_Relationship_Field__c = 'AccountId';
        mockConfig.reduivy__Child_Object_Field_Name__c = 'reduivy__Contact_Type__c';
        mockConfig.reduivy__Master_Object_Field_Name__c = 'NumberOfEmployees';
        mockConfig.reduivy__Rollup_Type__c = 'COUNT';
        mockConfig.reduivy__Field_Type__c = 'INTEGER';
        mockConfig.reduivy__Filter_Logic__c = '{0}';
        mockConfig.reduivy__Filter_Criteria_1__c = 'reduivy__Contact_Type__c = \'Applicant\'';
        mockConfig.reduivy__Rollup_Condition_Logic__c = '{0}';
        mockConfig.reduivy__Rollup_Condition_Formula_1__c = 'Account.RecordTypeId = null';
        
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> rollupConfigsByParentObject = 
            new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        rollupConfigsByParentObject.put('Account', new List<reduivy__Custom_Rollup_Config__mdt>{mockConfig});
        
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.reduivy__Sample_Record_Code__c = 'ROLLUP_TEST';
        insert testAccount;
        
        Contact testContact = new Contact();
        testContact.LastName = 'Test Contact';
        testContact.AccountId = testAccount.Id;
        testContact.reduivy__Sample_Record_Code__c = 'ROLLUP_TEST';
        
        if (Schema.sObjectType.Contact.fields.getMap().containsKey('reduivy__Contact_Type__c')) {
            testContact.put('reduivy__Contact_Type__c', 'Applicant');
        }
        
        insert testContact;
        
        List<Contact> contactList = new List<Contact>{testContact};
        List<SObject> testObjects = (List<SObject>)contactList;
        
        REDU_CustomRollup_OBJ rollupInstance = new REDU_CustomRollup_OBJ(
            testObjects,
            new List<SObject>(),
            rollupConfigsByParentObject
        );
        
        System.runAs(studentUser) {
            Test.startTest();
            try {
                rollupInstance.doRollup();
                System.Assert.fail('An exception should have been thrown');
            } catch (REDU_ApplicationException ex) {
                String expectedMsg = String.format(Label.Rollup_Conditions_Not_Allow_Relationship_Field_Error, new List<String>{'Account.RecordTypeId'});

                System.Assert.isTrue(
                    ex.getMessage().contains(expectedMsg),
                    'Invalid message: ' + ex.getMessage()
                );
            }
            Test.stopTest();
        }
    }
}