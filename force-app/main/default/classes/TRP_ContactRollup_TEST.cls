/**
 * @author      WDCi (XiRouh)
 * @date        Aug 2025
 * @group       Test
 * @description Test class for TRP_ContactRollup_EXE
 * @changehistory
 * ISS-002587 13-08-2025 XiRouh - new class
 */
@IsTest
public inherited sharing class TRP_ContactRollup_TEST {

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
            Test.startTest();
        	
            testFactory.initStudentData(USR_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }

    //Admin
    // ========== AFTER INSERT TESTS ==========

    /**
     * @description Test executeAfterInsert with TRP having non-qualified status as Admin (no rollup)
     */
    @IsTest
    static void testExecuteAfterInsertNonQualifiedStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Get initial balance
        Decimal initialBalance = studentContact.reduivy__Balance_Amount__c;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Create TRP with non-qualified status (not ACTIVE)
            reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null,
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                null, // idvFundingAllocationId
                50.00, // amount
                0.00,  // appliedAmount
                null   // applicableItemType
            );
            transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Non-qualified status
            
            insert transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should not change since status is not qualified
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(initialBalance, studentContact.reduivy__Balance_Amount__c, 
            'Balance should not change for non-qualified status TRP');
    }

    /**
     * @description Test executeAfterInsert with TRP having qualified status and linked to contact as Admin
     */
    @IsTest
    static void testExecuteAfterInsertQualifiedStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Get initial balance
        Decimal initialBalance = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Create TRP with qualified status (ACTIVE)
            reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null,
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                null, // idvFundingAllocationId
                50.00, // amount
                0.00,  // appliedAmount
                null   // applicableItemType
            );
            transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE; // Qualified status
            
            insert transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should increase by remaining amount
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(initialBalance + 50.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should increase by TRP remaining amount for qualified status');
    }

    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test executeAfterUpdate with no relevant changes to status, amount, or parent as Admin
     */
    @IsTest
    static void testExecuteAfterUpdateNoRelevantChangeAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        insert transactionPayment;
        
        // Get balance after initial insert
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterInsert = studentContact.reduivy__Balance_Amount__c;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Update TRP with no relevant changes (just description)
            transactionPayment.reduivy__Description__c = 'Updated description';
            update transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should remain the same
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceAfterInsert, studentContact.reduivy__Balance_Amount__c, 
            'Balance should not change when no relevant fields are updated');
    }

    /**
     * @description Test executeAfterUpdate when TRP status changes from non-qualified to qualified as Admin
     */
    @IsTest
    static void testExecuteAfterUpdateBecameQualifiedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Non-qualified status
        insert transactionPayment;
        
        // Get balance after initial insert (should be unchanged)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterInsert = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Update TRP status to qualified
            transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
            update transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should increase by remaining amount
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceAfterInsert + 50.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should increase when TRP becomes qualified');
    }

    /**
     * @description Test executeAfterUpdate when TRP status changes from qualified to non-qualified as Admin
     */
    @IsTest
    static void testExecuteAfterUpdateBecameNonQualifiedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE; // Qualified status
        insert transactionPayment;
        
        // Get balance after initial insert (should be increased)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterInsert = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Update TRP status to non-qualified
            transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_DRAFT;
            update transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should decrease by remaining amount
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceAfterInsert - 50.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should decrease when TRP becomes non-qualified');
    }

    /**
     * @description Test executeAfterUpdate when qualified TRP remaining amount changes as Admin
     */
    @IsTest
    static void testExecuteAfterUpdateAmountChangedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        insert transactionPayment;
        
        // Get balance after initial insert
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterInsert = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Update TRP remaining amount
            transactionPayment.reduivy__Amount__c = 75.00; // Changed from 50 to 75
            update transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should reflect the new remaining amount (increase by 25)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceAfterInsert + 25.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should reflect the change in remaining amount');
    }

    /**
     * @description Test executeAfterUpdate when qualified TRP parent contact changes as Admin
     */
    @IsTest
    static void testExecuteAfterUpdateParentChangedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Get two student contacts
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 2
        ];
        
        Contact originalContact = studentContacts[0];
        Contact newContact = studentContacts[1];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            originalContact.reduivy__Sample_Record_Code__c,
            originalContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        insert transactionPayment;
        
        // Get balances after initial insert
        originalContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :originalContact.Id];
        newContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :newContact.Id];
        Decimal originalBalanceAfterInsert = originalContact.reduivy__Balance_Amount__c ?? 0;
        Decimal newBalanceAfterInsert = newContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Update TRP to point to new contact
            transactionPayment.reduivy__Contact__c = newContact.Id;
            update transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Original contact balance should decrease, new contact balance should increase
        originalContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :originalContact.Id];
        newContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :newContact.Id];
        
        System.assertEquals(originalBalanceAfterInsert - 50.00, originalContact.reduivy__Balance_Amount__c, 
            'Original contact balance should decrease when TRP moves to another contact');
        System.assertEquals(newBalanceAfterInsert + 50.00, newContact.reduivy__Balance_Amount__c, 
            'New contact balance should increase when TRP is assigned to it');
    }

    /**
     * @description Test executeAfterUpdate when old contact needs rollup due to parent change as Admin
     */
    @IsTest
    static void testExecuteAfterUpdateOldContactNeedsRollupAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Get two student contacts
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 2
        ];
        
        Contact originalContact = studentContacts[0];
        Contact newContact = studentContacts[1];
        
        // Create first TRP that will be moved
        reduivy__Transaction_Payment__c trpToMove = REDU_TestData_UTIL.newTransactionPayment(
            originalContact.reduivy__Sample_Record_Code__c,
            originalContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        trpToMove.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        // Create second TRP that stays with original contact
        reduivy__Transaction_Payment__c trpStaying = REDU_TestData_UTIL.newTransactionPayment(
            originalContact.reduivy__Sample_Record_Code__c,
            originalContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            30.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        trpStaying.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        insert new List<reduivy__Transaction_Payment__c>{trpToMove, trpStaying};
        
        // Get balances after initial insert (should be 50 + 30 = 80 for original, 0 for new)
        originalContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :originalContact.Id];
        newContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :newContact.Id];
        Decimal originalBalanceAfterInsert = originalContact.reduivy__Balance_Amount__c ?? 0;
        Decimal newBalanceAfterInsert = newContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Move one TRP to new contact
            trpToMove.reduivy__Contact__c = newContact.Id;
            update trpToMove;
            
            Test.stopTest();
        }
        
        // Assertions - Original contact should have 30 remaining, new contact should have 50
        originalContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :originalContact.Id];
        newContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :newContact.Id];
        
        System.assertEquals(30.00, originalContact.reduivy__Balance_Amount__c, 
            'Original contact should have correct remaining balance after TRP is moved');
        System.assertEquals(newBalanceAfterInsert + 50.00, newContact.reduivy__Balance_Amount__c, 
            'New contact should have increased balance when TRP is assigned to it');
    }

    // ========== AFTER DELETE TESTS ==========

    /**
     * @description Test executeAfterDelete with TRP having non-qualified status as Admin (no rollup)
     */
    @IsTest
    static void testExecuteAfterDeleteNonQualifiedStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Non-qualified status
        insert transactionPayment;
        
        // Get balance after insert (should not have changed since status is non-qualified)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceBeforeDelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Delete the non-qualified TRP
            delete transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should not change since TRP was non-qualified
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];

        Decimal balanceAfterDelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        System.assertEquals(balanceBeforeDelete, balanceAfterDelete, 
            'Balance should not change when deleting non-qualified status TRP');
    }

    /**
     * @description Test executeAfterDelete with qualified TRP linked to contact as Admin
     */
    @IsTest
    static void testExecuteAfterDeleteQualifiedStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE; // Qualified status
        insert transactionPayment;
        
        // Get balance after insert (should have increased by 50)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceBeforeDelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Delete the qualified TRP
            delete transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should decrease by the TRP remaining amount
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceBeforeDelete - 50.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should decrease by TRP remaining amount when deleting qualified status TRP');
    }

    // ========== AFTER UNDELETE TESTS ==========

    /**
     * @description Test executeAfterUndelete with TRP having non-qualified status as Admin (no rollup)
     */
    @IsTest
    static void testExecuteAfterUndeleteNonQualifiedStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Non-qualified status

        System.runAs(ADMIN_USER) {
            insert transactionPayment;
        
            // Delete the TRP first
            delete transactionPayment;
        }
        
        // Get balance after delete
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterDelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Undelete the non-qualified TRP
            undelete transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should not change since TRP is non-qualified
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];

        Decimal balanceAfterUndelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        System.assertEquals(balanceAfterDelete, balanceAfterUndelete, 
            'Balance should not change when undeleting non-qualified status TRP');
    }

    /**
     * @description Test executeAfterUndelete with qualified TRP linked to contact as Admin
     */
    @IsTest
    static void testExecuteAfterUndeleteQualifiedStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE; // Qualified status

        System.runAs(ADMIN_USER) {
            insert transactionPayment;
        
            // Delete the TRP first
            delete transactionPayment;
        }
        
        // Get balance after delete (should have decreased by 50)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterDelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Undelete the qualified TRP
            undelete transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should increase by the TRP remaining amount
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceAfterDelete + 50.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should increase by TRP remaining amount when undeleting qualified status TRP');
    }

    //Student
    // ========== AFTER INSERT TESTS ==========

    /**
     * @description Test executeAfterInsert with TRP having non-qualified status as Student (no rollup)
     */
    @IsTest
    static void testExecuteAfterInsertNonQualifiedStatusAsStudent() {
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
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
        
        // Get initial balance
        Decimal initialBalance = studentContact.reduivy__Balance_Amount__c;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Create TRP with non-qualified status (not ACTIVE)
            reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null,
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                null, // idvFundingAllocationId
                50.00, // amount
                0.00,  // appliedAmount
                null   // applicableItemType
            );
            transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Non-qualified status
            
            insert transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should not change since status is not qualified
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(initialBalance, studentContact.reduivy__Balance_Amount__c, 
            'Balance should not change for non-qualified status TRP');
    }

    /**
     * @description Test executeAfterInsert with TRP having qualified status and linked to contact as Student
     */
    @IsTest
    static void testExecuteAfterInsertQualifiedStatusAsStudent() {
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
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
        
        // Get initial balance
        Decimal initialBalance = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Create TRP with qualified status (ACTIVE)
            reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null,
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                null, // idvFundingAllocationId
                50.00, // amount
                0.00,  // appliedAmount
                null   // applicableItemType
            );
            transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE; // Qualified status
            
            insert transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should increase by remaining amount
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(initialBalance + 50.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should increase by TRP remaining amount for qualified status');
    }

    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test executeAfterUpdate with no relevant changes to status, amount, or parent as Student
     */
    @IsTest
    static void testExecuteAfterUpdateNoRelevantChangeAsStudent() {
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
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
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        insert transactionPayment;
        
        // Get balance after initial insert
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterInsert = studentContact.reduivy__Balance_Amount__c;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Update TRP with no relevant changes (just description)
            transactionPayment.reduivy__Description__c = 'Updated description';
            update transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should remain the same
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceAfterInsert, studentContact.reduivy__Balance_Amount__c, 
            'Balance should not change when no relevant fields are updated');
    }

    /**
     * @description Test executeAfterUpdate when TRP status changes from non-qualified to qualified as Student
     */
    @IsTest
    static void testExecuteAfterUpdateBecameQualifiedAsStudent() {
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
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
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Non-qualified status
        insert transactionPayment;
        
        // Get balance after initial insert (should be unchanged)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterInsert = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Update TRP status to qualified
            transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
            update transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should increase by remaining amount
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceAfterInsert + 50.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should increase when TRP becomes qualified');
    }

    /**
     * @description Test executeAfterUpdate when TRP status changes from qualified to non-qualified as Student
     */
    @IsTest
    static void testExecuteAfterUpdateBecameNonQualifiedAsStudent() {
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
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
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE; // Qualified status
        insert transactionPayment;
        
        // Get balance after initial insert (should be increased)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterInsert = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Update TRP status to non-qualified
            transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_DRAFT;
            update transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should decrease by remaining amount
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceAfterInsert - 50.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should decrease when TRP becomes non-qualified');
    }

    /**
     * @description Test executeAfterUpdate when qualified TRP remaining amount changes as Student
     */
    @IsTest
    static void testExecuteAfterUpdateAmountChangedAsStudent() {
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
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
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        insert transactionPayment;
        
        // Get balance after initial insert
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterInsert = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Update TRP remaining amount
            transactionPayment.reduivy__Amount__c = 75.00; // Changed from 50 to 75
            update transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should reflect the new remaining amount (increase by 25)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceAfterInsert + 25.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should reflect the change in remaining amount');
    }

    // ========== AFTER DELETE TESTS ==========

    /**
     * @description Test executeAfterDelete with TRP having non-qualified status as Student (no rollup)
     */
    @IsTest
    static void testExecuteAfterDeleteNonQualifiedStatusAsStudent() {
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
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
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Non-qualified status

        System.runAs(studentUser) {
            insert transactionPayment;
        }
        
        // Get balance after insert (should not have changed since status is non-qualified)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceBeforeDelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Delete the non-qualified TRP
            delete transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should not change since TRP was non-qualified
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];

        Decimal balanceAfterDelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        System.assertEquals(balanceBeforeDelete, balanceAfterDelete, 
            'Balance should not change when deleting non-qualified status TRP');
    }

    /**
     * @description Test executeAfterDelete with qualified TRP linked to contact as Student
     */
    @IsTest
    static void testExecuteAfterDeleteQualifiedStatusAsStudent() {
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
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
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE; // Qualified status

        System.runAs(studentUser) {
            insert transactionPayment;
        }
        
        // Get balance after insert (should have increased by 50)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceBeforeDelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Delete the qualified TRP
            delete transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should decrease by the TRP remaining amount
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceBeforeDelete - 50.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should decrease by TRP remaining amount when deleting qualified status TRP');
    }

    // ========== AFTER UNDELETE TESTS ==========

    /**
     * @description Test executeAfterUndelete with TRP having non-qualified status as Student (no rollup)
     */
    @IsTest
    static void testExecuteAfterUndeleteNonQualifiedStatusAsStudent() {
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
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
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Non-qualified status

        System.runAs(studentUser) {
            insert transactionPayment;
        
            // Delete the TRP first
            delete transactionPayment;
        }
        
        // Get balance after delete
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterDelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Undelete the non-qualified TRP
            undelete transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should not change since TRP is non-qualified
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];

        Decimal balanceAfterUndelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        System.assertEquals(balanceAfterDelete, balanceAfterUndelete, 
            'Balance should not change when undeleting non-qualified status TRP');
    }

    /**
     * @description Test executeAfterUndelete with qualified TRP linked to contact as Student
     */
    @IsTest
    static void testExecuteAfterUndeleteQualifiedStatusAsStudent() {
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
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
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE; // Qualified status

        System.runAs(studentUser) {
            insert transactionPayment;
        
            // Delete the TRP first
            delete transactionPayment;
        }
        
        // Get balance after delete (should have decreased by 50)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterDelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Undelete the qualified TRP
            undelete transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should increase by the TRP remaining amount
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceAfterDelete + 50.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should increase by TRP remaining amount when undeleting qualified status TRP');
    }

    //Faculty
    // ========== AFTER INSERT TESTS ==========

    /**
     * @description Test executeAfterInsert with TRP having non-qualified status as Faculty (no rollup)
     */
    @IsTest
    static void testExecuteAfterInsertNonQualifiedStatusAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Get initial balance
        Decimal initialBalance = studentContact.reduivy__Balance_Amount__c;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Create TRP with non-qualified status (not ACTIVE)
            reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null,
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                null, // idvFundingAllocationId
                50.00, // amount
                0.00,  // appliedAmount
                null   // applicableItemType
            );
            transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Non-qualified status
            
            insert transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should not change since status is not qualified
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(initialBalance, studentContact.reduivy__Balance_Amount__c, 
            'Balance should not change for non-qualified status TRP');
    }

    /**
     * @description Test executeAfterInsert with TRP having qualified status and linked to contact as Faculty
     */
    @IsTest
    static void testExecuteAfterInsertQualifiedStatusAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Get initial balance
        Decimal initialBalance = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Create TRP with qualified status (ACTIVE)
            reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null,
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                null, // idvFundingAllocationId
                50.00, // amount
                0.00,  // appliedAmount
                null   // applicableItemType
            );
            transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE; // Qualified status
            
            insert transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should increase by remaining amount
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(initialBalance + 50.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should increase by TRP remaining amount for qualified status');
    }

    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test executeAfterUpdate with no relevant changes to status, amount, or parent as Faculty
     */
    @IsTest
    static void testExecuteAfterUpdateNoRelevantChangeAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        insert transactionPayment;
        
        // Get balance after initial insert
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterInsert = studentContact.reduivy__Balance_Amount__c;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Update TRP with no relevant changes (just description)
            transactionPayment.reduivy__Description__c = 'Updated description';
            update transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should remain the same
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceAfterInsert, studentContact.reduivy__Balance_Amount__c, 
            'Balance should not change when no relevant fields are updated');
    }

    /**
     * @description Test executeAfterUpdate when TRP status changes from non-qualified to qualified as Faculty
     */
    @IsTest
    static void testExecuteAfterUpdateBecameQualifiedAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Non-qualified status
        insert transactionPayment;
        
        // Get balance after initial insert (should be unchanged)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterInsert = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Update TRP status to qualified
            transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
            update transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should increase by remaining amount
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceAfterInsert + 50.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should increase when TRP becomes qualified');
    }

    /**
     * @description Test executeAfterUpdate when TRP status changes from qualified to non-qualified as Faculty
     */
    @IsTest
    static void testExecuteAfterUpdateBecameNonQualifiedAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE; // Qualified status
        insert transactionPayment;
        
        // Get balance after initial insert (should be increased)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterInsert = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Update TRP status to non-qualified
            transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_DRAFT;
            update transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should decrease by remaining amount
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceAfterInsert - 50.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should decrease when TRP becomes non-qualified');
    }

    /**
     * @description Test executeAfterUpdate when qualified TRP remaining amount changes as Faculty
     */
    @IsTest
    static void testExecuteAfterUpdateAmountChangedAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        insert transactionPayment;
        
        // Get balance after initial insert
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterInsert = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Update TRP remaining amount
            transactionPayment.reduivy__Amount__c = 75.00; // Changed from 50 to 75
            update transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should reflect the new remaining amount (increase by 25)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceAfterInsert + 25.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should reflect the change in remaining amount');
    }

    /**
     * @description Test executeAfterUpdate when qualified TRP parent contact changes as Faculty
     */
    @IsTest
    static void testExecuteAfterUpdateParentChangedAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Get two student contacts
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 2
        ];
        
        Contact originalContact = studentContacts[0];
        Contact newContact = studentContacts[1];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            originalContact.reduivy__Sample_Record_Code__c,
            originalContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        insert transactionPayment;
        
        // Get balances after initial insert
        originalContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :originalContact.Id];
        newContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :newContact.Id];
        Decimal originalBalanceAfterInsert = originalContact.reduivy__Balance_Amount__c ?? 0;
        Decimal newBalanceAfterInsert = newContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Update TRP to point to new contact
            transactionPayment.reduivy__Contact__c = newContact.Id;
            update transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Original contact balance should decrease, new contact balance should increase
        originalContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :originalContact.Id];
        newContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :newContact.Id];
        
        System.assertEquals(originalBalanceAfterInsert - 50.00, originalContact.reduivy__Balance_Amount__c, 
            'Original contact balance should decrease when TRP moves to another contact');
        System.assertEquals(newBalanceAfterInsert + 50.00, newContact.reduivy__Balance_Amount__c, 
            'New contact balance should increase when TRP is assigned to it');
    }

    /**
     * @description Test executeAfterUpdate when old contact needs rollup due to parent change as Faculty
     */
    @IsTest
    static void testExecuteAfterUpdateOldContactNeedsRollupAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Get two student contacts
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 2
        ];
        
        Contact originalContact = studentContacts[0];
        Contact newContact = studentContacts[1];
        
        // Create first TRP that will be moved
        reduivy__Transaction_Payment__c trpToMove = REDU_TestData_UTIL.newTransactionPayment(
            originalContact.reduivy__Sample_Record_Code__c,
            originalContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        trpToMove.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        // Create second TRP that stays with original contact
        reduivy__Transaction_Payment__c trpStaying = REDU_TestData_UTIL.newTransactionPayment(
            originalContact.reduivy__Sample_Record_Code__c,
            originalContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            30.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        trpStaying.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        insert new List<reduivy__Transaction_Payment__c>{trpToMove, trpStaying};
        
        // Get balances after initial insert (should be 50 + 30 = 80 for original, 0 for new)
        originalContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :originalContact.Id];
        newContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :newContact.Id];
        Decimal originalBalanceAfterInsert = originalContact.reduivy__Balance_Amount__c ?? 0;
        Decimal newBalanceAfterInsert = newContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Move one TRP to new contact
            trpToMove.reduivy__Contact__c = newContact.Id;
            update trpToMove;
            
            Test.stopTest();
        }
        
        // Assertions - Original contact should have 30 remaining, new contact should have 50
        originalContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :originalContact.Id];
        newContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :newContact.Id];
        
        System.assertEquals(30.00, originalContact.reduivy__Balance_Amount__c, 
            'Original contact should have correct remaining balance after TRP is moved');
        System.assertEquals(newBalanceAfterInsert + 50.00, newContact.reduivy__Balance_Amount__c, 
            'New contact should have increased balance when TRP is assigned to it');
    }

    // ========== AFTER DELETE TESTS ==========

    /**
     * @description Test executeAfterDelete with TRP having non-qualified status as Faculty (no rollup)
     */
    @IsTest
    static void testExecuteAfterDeleteNonQualifiedStatusAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Non-qualified status

        System.runAs(FACULTY_USER) {
            insert transactionPayment;
        }
        
        // Get balance after insert (should not have changed since status is non-qualified)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceBeforeDelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Delete the non-qualified TRP
            delete transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should not change since TRP was non-qualified
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];

        Decimal balanceAfterDelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        System.assertEquals(balanceBeforeDelete, balanceAfterDelete, 
            'Balance should not change when deleting non-qualified status TRP');
    }

    /**
     * @description Test executeAfterDelete with qualified TRP linked to contact as Faculty
     */
    @IsTest
    static void testExecuteAfterDeleteQualifiedStatusAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE; // Qualified status

        System.runAs(FACULTY_USER) {
            insert transactionPayment;
        }
        
        // Get balance after insert (should have increased by 50)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceBeforeDelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Delete the qualified TRP
            delete transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should decrease by the TRP remaining amount
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceBeforeDelete - 50.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should decrease by TRP remaining amount when deleting qualified status TRP');
    }

    // ========== AFTER UNDELETE TESTS ==========

    /**
     * @description Test executeAfterUndelete with TRP having non-qualified status as Faculty (no rollup)
     */
    @IsTest
    static void testExecuteAfterUndeleteNonQualifiedStatusAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Non-qualified status

        System.runAs(FACULTY_USER) {
            insert transactionPayment;
        
            // Delete the TRP first
            delete transactionPayment;
        }
        
        // Get balance after delete
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterDelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Undelete the non-qualified TRP
            undelete transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should not change since TRP is non-qualified
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];

        Decimal balanceAfterUndelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        System.assertEquals(balanceAfterDelete, balanceAfterUndelete, 
            'Balance should not change when undeleting non-qualified status TRP');
    }

    /**
     * @description Test executeAfterUndelete with qualified TRP linked to contact as Faculty
     */
    @IsTest
    static void testExecuteAfterUndeleteQualifiedStatusAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Balance_Amount__c
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            50.00, // amount
            0.00,  // appliedAmount
            null   // applicableItemType
        );
        transactionPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE; // Qualified status

        System.runAs(FACULTY_USER) {
            insert transactionPayment;
        
            // Delete the TRP first
            delete transactionPayment;
        }
        
        // Get balance after delete (should have decreased by 50)
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        Decimal balanceAfterDelete = studentContact.reduivy__Balance_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Undelete the qualified TRP
            undelete transactionPayment;
            
            Test.stopTest();
        }
        
        // Assertions - Balance should increase by the TRP remaining amount
        studentContact = [SELECT reduivy__Balance_Amount__c FROM Contact WHERE Id = :studentContact.Id];
        System.assertEquals(balanceAfterDelete + 50.00, studentContact.reduivy__Balance_Amount__c, 
            'Balance should increase by TRP remaining amount when undeleting qualified status TRP');
    }
}