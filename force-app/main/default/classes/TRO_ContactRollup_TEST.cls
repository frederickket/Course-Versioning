/**
 * @author      WDCi (XiRouh)
 * @date        Aug 2025
 * @group       Test
 * @description Test class for TRO_ContactRollup_EXE
 * @changehistory
 * ISS-002587 13-08-2025 XiRouh - new class
 */
@IsTest
public inherited sharing class TRO_ContactRollup_TEST {

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
     * @description Test executeAfterInsert with TROs that do not have qualified status as Admin (no rollup)
     */
    @IsTest static void testExecuteAfterInsertNonQualifiedStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Store initial outstanding amount
        Decimal initialOutstandingAmount = studentContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Create transaction order with non-qualified status (e.g., DRAFT)
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // academicProgressId
                Date.today(),
                TRO_Helper.STATUS_TYPE_DRAFT, // Non-qualified status
                100.00,  // totalAmount
                50.00,   // outstandingAmount
                50.00    // paidAmount
            );
            
            insert transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should NOT change since status is not qualified
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];

        Decimal amountAfterDelete = updatedContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.assertEquals(initialOutstandingAmount, amountAfterDelete, 
                        'Contact outstanding amount should not change for non-qualified TRO status');
    }

    /**
     * @description Test executeAfterInsert with new TRO having qualified status and linked to contact as Admin
     */
    @IsTest static void testExecuteAfterInsertQualifiedStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Store initial outstanding amount
        Decimal initialOutstandingAmount = studentContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Create transaction order with qualified status (e.g., SUBMITTED)
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // academicProgressId
                Date.today(),
                TRO_Helper.STATUS_TYPE_SUBMITTED, // Qualified status
                100.00,  // totalAmount
                75.00,   // outstandingAmount
                25.00    // paidAmount
            );
            
            insert transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should be updated with TRO outstanding amount
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = initialOutstandingAmount + 75.00;
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should include new qualified TRO outstanding amount');
    }

    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test executeAfterUpdate with no relevant changes to status, amount, or parent as Admin
     */
    @IsTest static void testExecuteAfterUpdateNoRelevantChangeAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Create and insert TRO with qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED, // Qualified status
            100.00,  // totalAmount
            60.00,   // outstandingAmount
            40.00    // paidAmount
        );
        insert transactionOrder;
        
        // Get contact's outstanding amount after initial insert
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterInsert = contactAfterInsert.reduivy__Total_Outstanding_Amount__c;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            // Muting trigger to avoid recalculating the outstanding amount
            REDU_TriggerController.muteTriggers(new Set<String>{'TRO_OutstandingAmountCalc_EXE'});

            // Update TRO with irrelevant change 
            transactionOrder.reduivy__Total_Amount__c = 1000;
            update transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should remain unchanged
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        System.assertEquals(amountAfterInsert, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should not change for irrelevant TRO updates');
    }

    /**
     * @description Test executeAfterUpdate when TRO status changes from non-qualified to qualified as Admin
     */
    @IsTest static void testExecuteAfterUpdateBecameQualifiedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Create and insert TRO with non-qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_DRAFT, // Non-qualified status
            100.00,  // totalAmount
            80.00,   // outstandingAmount
            20.00    // paidAmount
        );
        insert transactionOrder;
        
        // Get contact's outstanding amount after initial insert (should be unchanged)
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal initialAmount = contactAfterInsert.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Update TRO status to qualified
            transactionOrder.reduivy__Status__c = TRO_Helper.STATUS_TYPE_SUBMITTED;
            update transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should now include TRO amount
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = initialAmount + 80.00;
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should include TRO amount when status becomes qualified');
    }

    /**
     * @description Test executeAfterUpdate when TRO status changes from qualified to non-qualified as Admin
     */
    @IsTest static void testExecuteAfterUpdateBecameNonQualifiedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Create and insert TRO with qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_CONFIRMED, // Qualified status
            100.00,  // totalAmount
            100.00,   // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;
        
        // Get contact's outstanding amount after initial insert
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterInsert = contactAfterInsert.reduivy__Total_Outstanding_Amount__c;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Update TRO status to non-qualified
            transactionOrder.reduivy__Status__c = TRO_Helper.STATUS_TYPE_VOID;
            update transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should exclude TRO amount
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = amountAfterInsert - 100.00;
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should exclude TRO amount when status becomes non-qualified');
    }

    /**
     * @description Test executeAfterUpdate when qualified TRO outstanding amount changes as Admin
     */
    @IsTest static void testExecuteAfterUpdateAmountChangedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Create and insert TRO with qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED, // Qualified status
            100.00,  // totalAmount
            90.00,   // outstandingAmount
            10.00    // paidAmount
        );
        insert transactionOrder;
        
        // Get contact's outstanding amount after initial insert
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterInsert = contactAfterInsert.reduivy__Total_Outstanding_Amount__c;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Update TRO outstanding amount
            transactionOrder.reduivy__Total_Outstanding_Amount__c = 50.00;
            transactionOrder.reduivy__Total_Paid_Amount__c = 50.00;
            update transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should reflect the change
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = amountAfterInsert - 90.00 + 50.00; // Remove old amount, add new amount
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should reflect TRO outstanding amount changes');
    }

    /**
     * @description Test executeAfterUpdate when qualified TRO parent contact changes as Admin
     */
    @IsTest static void testExecuteAfterUpdateParentChangedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Get two different student contacts
        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                        FROM Contact 
                                        WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                        AND reduivy__Sample_Record_Code__c <> ''
                                        LIMIT 2];
        
        Contact originalContact = studentContacts[0];
        Contact newContact = studentContacts.size() > 1 ? studentContacts[1] : originalContact;
        
        // Create and insert TRO with qualified status linked to original contact
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            originalContact.reduivy__Sample_Record_Code__c,
            originalContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_CONFIRMED, // Qualified status
            100.00,  // totalAmount
            85.00,   // outstandingAmount
            15.00    // paidAmount
        );
        insert transactionOrder;
        
        // Get both contacts' outstanding amounts after initial insert
        Map<Id, Contact> contactsAfterInsert = new Map<Id, Contact>([SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                                                    FROM Contact 
                                                                    WHERE Id IN (:originalContact.Id, :newContact.Id)]);
        
        Decimal originalAmountAfterInsert = contactsAfterInsert.get(originalContact.Id).reduivy__Total_Outstanding_Amount__c;
        Decimal newAmountAfterInsert = contactsAfterInsert.get(newContact.Id).reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Update TRO to link to new contact
            transactionOrder.reduivy__Contact__c = newContact.Id;
            update transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Both contacts should have updated outstanding amounts
        Map<Id, Contact> updatedContacts = new Map<Id, Contact>([SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                                                FROM Contact 
                                                                WHERE Id IN (:originalContact.Id, :newContact.Id)]);
        
        Decimal expectedOriginalAmount = originalAmountAfterInsert - 85.00; // Remove TRO amount
        Decimal expectedNewAmount = newAmountAfterInsert + 85.00; // Add TRO amount
        
        System.assertEquals(expectedOriginalAmount, updatedContacts.get(originalContact.Id).reduivy__Total_Outstanding_Amount__c, 
                        'Original contact outstanding amount should decrease when TRO is moved away');
        
        System.assertEquals(expectedNewAmount, updatedContacts.get(newContact.Id).reduivy__Total_Outstanding_Amount__c, 
                        'New contact outstanding amount should increase when TRO is moved to it');
    }

    /**
     * @description Test executeAfterUpdate when old contact needs rollup due to parent change as Admin
     */
    @IsTest static void testExecuteAfterUpdateOldContactNeedsRollupAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Get two different student contacts
        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                        FROM Contact 
                                        WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                        AND reduivy__Sample_Record_Code__c <> ''
                                        LIMIT 2];
        
        Contact originalContact = studentContacts[0];
        Contact newContact = studentContacts.size() > 1 ? studentContacts[1] : originalContact;
        
        // Create two TROs for the original contact - one will be moved, one will stay
        List<reduivy__Transaction_Order__c> transactionOrders = new List<reduivy__Transaction_Order__c>();
        
        transactionOrders.add(REDU_TestData_UTIL.newTransactionOrder(
            originalContact.reduivy__Sample_Record_Code__c,
            originalContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED, // Qualified status
            100.00,  // totalAmount
            60.00,   // outstandingAmount (this will be moved)
            40.00    // paidAmount
        ));
        
        transactionOrders.add(REDU_TestData_UTIL.newTransactionOrder(
            originalContact.reduivy__Sample_Record_Code__c,
            originalContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_CONFIRMED, // Qualified status
            200.00,  // totalAmount
            120.00,  // outstandingAmount (this will stay)
            80.00    // paidAmount
        ));
        
        insert transactionOrders;
        
        // Get both contacts' outstanding amounts after initial insert
        Map<Id, Contact> contactsAfterInsert = new Map<Id, Contact>([SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                                                    FROM Contact 
                                                                    WHERE Id IN (:originalContact.Id, :newContact.Id)]);
        
        Decimal originalAmountAfterInsert = contactsAfterInsert.get(originalContact.Id).reduivy__Total_Outstanding_Amount__c;
        Decimal newAmountAfterInsert = contactsAfterInsert.get(newContact.Id).reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Move first TRO to new contact, second stays with original
            transactionOrders[0].reduivy__Contact__c = newContact.Id;
            update transactionOrders[0];
            
            Test.stopTest();
        }
        
        // Assertions - Both contacts should have correct rollup calculations
        Map<Id, Contact> updatedContacts = new Map<Id, Contact>([SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                                                FROM Contact 
                                                                WHERE Id IN (:originalContact.Id, :newContact.Id)]);
        
        // Original contact should have only the remaining TRO's outstanding amount (120.00)
        Decimal expectedOriginalAmount = 120.00;
        
        // New contact should have the moved TRO's outstanding amount (60.00) plus any existing amount
        Decimal expectedNewAmount = newAmountAfterInsert + 60.00;
        
        System.assertEquals(expectedOriginalAmount, updatedContacts.get(originalContact.Id).reduivy__Total_Outstanding_Amount__c, 
                        'Original contact should be properly recalculated after TRO is moved away');
        
        System.assertEquals(expectedNewAmount, updatedContacts.get(newContact.Id).reduivy__Total_Outstanding_Amount__c, 
                        'New contact should include moved TRO amount in rollup calculation');
    }

    // ========== AFTER DELETE TESTS ==========

    /**
     * @description Test executeAfterDelete with TRO having non-qualified status as Admin (no rollup)
     */
    @IsTest static void testExecuteAfterDeleteNonQualifiedStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Create and insert TRO with non-qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_DRAFT, // Non-qualified status
            100.00,  // totalAmount
            90.00,   // outstandingAmount
            10.00    // paidAmount
        );
        insert transactionOrder;
        
        // Get contact's outstanding amount after insert (should be unchanged due to non-qualified status)
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterInsert = contactAfterInsert.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Delete the non-qualified TRO
            delete transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should remain unchanged
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];

        Decimal amountAfterDelete = updatedContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.assertEquals(amountAfterInsert, amountAfterDelete, 
                        'Contact outstanding amount should not change when deleting non-qualified TRO');
    }

    /**
     * @description Test executeAfterDelete with qualified TRO linked to contact as Admin
     */
    @IsTest static void testExecuteAfterDeleteQualifiedStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Create and insert TRO with qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_CONFIRMED, // Qualified status
            100.00,  // totalAmount
            75.00,   // outstandingAmount
            25.00    // paidAmount
        );
        insert transactionOrder;
        
        // Get contact's outstanding amount after insert
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterInsert = contactAfterInsert.reduivy__Total_Outstanding_Amount__c;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Delete the qualified TRO
            delete transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should decrease by TRO outstanding amount
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = amountAfterInsert - 75.00;
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should decrease when deleting qualified TRO');
    }

    // ========== AFTER UNDELETE TESTS ==========

    /**
     * @description Test executeAfterUndelete with TRO having non-qualified status as Admin (no rollup)
     */
    @IsTest static void testExecuteAfterUndeleteNonQualifiedStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Create and insert TRO with non-qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_DRAFT, // Non-qualified status
            100.00,  // totalAmount
            85.00,   // outstandingAmount
            15.00    // paidAmount
        );
        insert transactionOrder;
        
        System.runAs(ADMIN_USER) {
            // Delete the TRO first
            delete transactionOrder;
        }
        
        // Get contact's outstanding amount after delete
        Contact contactAfterDelete = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterDelete = contactAfterDelete.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Undelete the non-qualified TRO
            undelete transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should remain unchanged
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];

        Decimal amountAfterUndelete = updatedContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.assertEquals(amountAfterDelete, amountAfterUndelete, 
                        'Contact outstanding amount should not change when undeleting non-qualified TRO');
    }

    /**
     * @description Test executeAfterUndelete with qualified TRO linked to contact as Admin
     */
    @IsTest static void testExecuteAfterUndeleteQualifiedStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Create and insert TRO with qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED, // Qualified status
            100.00,  // totalAmount
            65.00,   // outstandingAmount
            35.00    // paidAmount
        );
        insert transactionOrder;

        System.runAs(ADMIN_USER) {
            // Delete the TRO first
            delete transactionOrder;
        }
        
        // Get contact's outstanding amount after delete
        Contact contactAfterDelete = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterDelete = contactAfterDelete.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Undelete the qualified TRO
            undelete transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should increase by TRO outstanding amount
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = amountAfterDelete + 65.00;
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should increase when undeleting qualified TRO');
    }

    /**
     * @description Test that TROs with no parent contact (both old and new are blank) do not trigger rollup
     */
    @IsTest static void testNoParentContactNoRollupAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Store initial outstanding amount
        Decimal initialOutstandingAmount = studentContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Create TRO with qualified status but NO parent contact
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                studentContact.reduivy__Sample_Record_Code__c,
                null, // contactId - NO PARENT
                null, // academicProgressId
                Date.today(),
                TRO_Helper.STATUS_TYPE_SUBMITTED, // Qualified status
                100.00,  // totalAmount
                80.00,   // outstandingAmount
                20.00    // paidAmount
            );
            insert transactionOrder;
            
            // Update the TRO (still with no parent) - this tests the update scenario
            transactionOrder.reduivy__Total_Outstanding_Amount__c = 90.00;
            transactionOrder.reduivy__Total_Paid_Amount__c = 10.00;
            update transactionOrder;
            
            // Delete the TRO (still with no parent) - this tests the delete scenario  
            delete transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should remain completely unchanged
        // since the TRO never had a parent contact to roll up to
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal amountAfterDelete = updatedContact.reduivy__Total_Outstanding_Amount__c ?? 0;

        System.assertEquals(initialOutstandingAmount, amountAfterDelete, 
                        'Contact outstanding amount should not change for TROs with no parent contact');
        
        // Additional test: Create TRO with parent, then remove parent (old parent exists, new parent is blank)
        reduivy__Transaction_Order__c transactionOrderWithParent = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id, // HAS PARENT initially
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_CONFIRMED, // Qualified status
            200.00,  // totalAmount
            150.00,  // outstandingAmount
            50.00    // paidAmount
        );
        insert transactionOrderWithParent;
        
        // Get contact amount after insert (should include the TRO)
        Contact contactAfterParentInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                        FROM Contact 
                                        WHERE Id = :studentContact.Id];
        Decimal amountAfterParentInsert = contactAfterParentInsert.reduivy__Total_Outstanding_Amount__c;
        
        // Remove the parent contact (oldParent exists, newParent is blank) - should trigger rollup
        transactionOrderWithParent.reduivy__Contact__c = null;
        update transactionOrderWithParent;
        
        // Verify the rollup happened when parent was removed
        Contact contactAfterParentRemoval = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                            FROM Contact 
                                            WHERE Id = :studentContact.Id];
        
        Decimal expectedAmountAfterRemoval = amountAfterParentInsert - 150.00;
        System.assertEquals(expectedAmountAfterRemoval, contactAfterParentRemoval.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should decrease when parent is removed from qualified TRO');
    }

    //Student
    // ========== AFTER INSERT TESTS ==========

    /**
     * @description Test executeAfterInsert with TROs that do not have qualified status as Student (no rollup)
     */
    @IsTest static void testExecuteAfterInsertNonQualifiedStatusAsStudent() {

        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        // Store initial outstanding amount
        Decimal initialOutstandingAmount = studentContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Create transaction order with non-qualified status (e.g., DRAFT)
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // academicProgressId
                Date.today(),
                TRO_Helper.STATUS_TYPE_DRAFT, // Non-qualified status
                100.00,  // totalAmount
                50.00,   // outstandingAmount
                50.00    // paidAmount
            );
            
            insert transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should NOT change since status is not qualified
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];

        Decimal amountAfterDelete = updatedContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.assertEquals(initialOutstandingAmount, amountAfterDelete, 
                        'Contact outstanding amount should not change for non-qualified TRO status');
    }

    /**
     * @description Test executeAfterInsert with new TRO having qualified status and linked to contact as Student
     */
    @IsTest static void testExecuteAfterInsertQualifiedStatusAsStudent() {
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
		
		// Store initial outstanding amount
        Decimal initialOutstandingAmount = studentContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Create transaction order with qualified status (e.g., SUBMITTED)
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // academicProgressId
                Date.today(),
                TRO_Helper.STATUS_TYPE_SUBMITTED, // Qualified status
                100.00,  // totalAmount
                75.00,   // outstandingAmount
                25.00    // paidAmount
            );
            
            insert transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should be updated with TRO outstanding amount
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = initialOutstandingAmount + 75.00;
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should include new qualified TRO outstanding amount');
    }

    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test executeAfterUpdate with no relevant changes to status, amount, or parent as Student
     */
    @IsTest static void testExecuteAfterUpdateNoRelevantChangeAsStudent() {
            
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
		
		// Create and insert TRO with qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED, // Qualified status
            100.00,  // totalAmount
            60.00,   // outstandingAmount
            40.00    // paidAmount
        );
        insert transactionOrder;
        
        // Get contact's outstanding amount after initial insert
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterInsert = contactAfterInsert.reduivy__Total_Outstanding_Amount__c;
        
        System.runAs(studentUser) {
            Test.startTest();
            // Muting trigger to avoid recalculating the outstanding amount
            REDU_TriggerController.muteTriggers(new Set<String>{'TRO_OutstandingAmountCalc_EXE'});

            // Update TRO with irrelevant change 
            transactionOrder.reduivy__Total_Amount__c = 1000;
            update transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should remain unchanged
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        System.assertEquals(amountAfterInsert, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should not change for irrelevant TRO updates');
    }

    /**
     * @description Test executeAfterUpdate when TRO status changes from non-qualified to qualified as Student
     */
    @IsTest static void testExecuteAfterUpdateBecameQualifiedAsStudent() {
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
		
		// Create and insert TRO with non-qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_DRAFT, // Non-qualified status
            100.00,  // totalAmount
            80.00,   // outstandingAmount
            20.00    // paidAmount
        );
        insert transactionOrder;
        
        // Get contact's outstanding amount after initial insert (should be unchanged)
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal initialAmount = contactAfterInsert.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Update TRO status to qualified
            transactionOrder.reduivy__Status__c = TRO_Helper.STATUS_TYPE_SUBMITTED;
            update transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should now include TRO amount
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = initialAmount + 80.00;
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should include TRO amount when status becomes qualified');
    }

    /**
     * @description Test executeAfterUpdate when TRO status changes from qualified to non-qualified as Student
     */
    @IsTest static void testExecuteAfterUpdateBecameNonQualifiedAsStudent() {
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
		
		// Create and insert TRO with qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_CONFIRMED, // Qualified status
            100.00,  // totalAmount
            100.00,   // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;
        
        // Get contact's outstanding amount after initial insert
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterInsert = contactAfterInsert.reduivy__Total_Outstanding_Amount__c;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Update TRO status to non-qualified
            transactionOrder.reduivy__Status__c = TRO_Helper.STATUS_TYPE_VOID;
            update transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should exclude TRO amount
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = amountAfterInsert - 100.00;
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should exclude TRO amount when status becomes non-qualified');
    }

    /**
     * @description Test executeAfterUpdate when qualified TRO outstanding amount changes as Student
     */
    @IsTest static void testExecuteAfterUpdateAmountChangedAsStudent() {
 
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
		
		// Create and insert TRO with qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED, // Qualified status
            100.00,  // totalAmount
            90.00,   // outstandingAmount
            10.00    // paidAmount
        );
        insert transactionOrder;
        
        // Get contact's outstanding amount after initial insert
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterInsert = contactAfterInsert.reduivy__Total_Outstanding_Amount__c;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Update TRO outstanding amount
            transactionOrder.reduivy__Total_Outstanding_Amount__c = 50.00;
            transactionOrder.reduivy__Total_Paid_Amount__c = 50.00;
            update transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should reflect the change
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = amountAfterInsert - 90.00 + 50.00; // Remove old amount, add new amount
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should reflect TRO outstanding amount changes');
    }

    // ========== AFTER DELETE TESTS ==========

    /**
     * @description Test executeAfterDelete with TRO having non-qualified status as Student (no rollup)
     */
    @IsTest static void testExecuteAfterDeleteNonQualifiedStatusAsStudent() {
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
		
		// Create and insert TRO with non-qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_DRAFT, // Non-qualified status
            100.00,  // totalAmount
            90.00,   // outstandingAmount
            10.00    // paidAmount
        );

        System.runAs(studentUser) {
            insert transactionOrder;
        }
        
        // Get contact's outstanding amount after insert (should be unchanged due to non-qualified status)
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterInsert = contactAfterInsert.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Delete the non-qualified TRO
            delete transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should remain unchanged
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];

        Decimal amountAfterDelete = updatedContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.assertEquals(amountAfterInsert, amountAfterDelete, 
                        'Contact outstanding amount should not change when deleting non-qualified TRO');
    }

    /**
     * @description Test executeAfterDelete with qualified TRO linked to contact as Student
     */
    @IsTest static void testExecuteAfterDeleteQualifiedStatusAsStudent() {
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
		
		// Create and insert TRO with qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_CONFIRMED, // Qualified status
            100.00,  // totalAmount
            75.00,   // outstandingAmount
            25.00    // paidAmount
        );

        System.runAs(studentUser) {
            insert transactionOrder;
        }
        
        // Get contact's outstanding amount after insert
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterInsert = contactAfterInsert.reduivy__Total_Outstanding_Amount__c;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Delete the qualified TRO
            delete transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should decrease by TRO outstanding amount
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = amountAfterInsert - 75.00;
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should decrease when deleting qualified TRO');
    }

    // ========== AFTER UNDELETE TESTS ==========

    /**
     * @description Test executeAfterUndelete with TRO having non-qualified status as Student (no rollup)
     */
    @IsTest static void testExecuteAfterUndeleteNonQualifiedStatusAsStudent() {
         
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
		
		// Create and insert TRO with non-qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_DRAFT, // Non-qualified status
            100.00,  // totalAmount
            85.00,   // outstandingAmount
            15.00    // paidAmount
        );
        
        System.runAs(studentUser) {
            insert transactionOrder;
            
            // Delete the TRO first
            delete transactionOrder;
        }
        
        // Get contact's outstanding amount after delete
        Contact contactAfterDelete = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterDelete = contactAfterDelete.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Undelete the non-qualified TRO
            undelete transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should remain unchanged
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];

        Decimal amountAfterUndelete = updatedContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.assertEquals(amountAfterDelete, amountAfterUndelete, 
                        'Contact outstanding amount should not change when undeleting non-qualified TRO');
    }

    /**
     * @description Test executeAfterUndelete with qualified TRO linked to contact as Student
     */
    @IsTest static void testExecuteAfterUndeleteQualifiedStatusAsStudent() {
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
		
		// Create and insert TRO with qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED, // Qualified status
            100.00,  // totalAmount
            65.00,   // outstandingAmount
            35.00    // paidAmount
        );
        
        System.runAs(studentUser) {
            insert transactionOrder;
            // Delete the TRO first
            delete transactionOrder;
        }
        
        // Get contact's outstanding amount after delete
        Contact contactAfterDelete = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterDelete = contactAfterDelete.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Undelete the qualified TRO
            undelete transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should increase by TRO outstanding amount
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = amountAfterDelete + 65.00;
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should increase when undeleting qualified TRO');
    }

    /**
     * @description Test that TROs with no parent contact (both old and new are blank) do not trigger rollup
     */
    @IsTest static void testNoParentContactNoRollupAsStudent() {
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
		
		// Store initial outstanding amount
        Decimal initialOutstandingAmount = studentContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Create TRO with qualified status but NO parent contact
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                studentContact.reduivy__Sample_Record_Code__c,
                null, // contactId - NO PARENT
                null, // academicProgressId
                Date.today(),
                TRO_Helper.STATUS_TYPE_SUBMITTED, // Qualified status
                100.00,  // totalAmount
                80.00,   // outstandingAmount
                20.00    // paidAmount
            );
            insert transactionOrder;
            
            // Update the TRO (still with no parent) - this tests the update scenario
            transactionOrder.reduivy__Total_Outstanding_Amount__c = 90.00;
            transactionOrder.reduivy__Total_Paid_Amount__c = 10.00;
            update transactionOrder;
            
            // Delete the TRO (still with no parent) - this tests the delete scenario  
            delete transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should remain completely unchanged
        // since the TRO never had a parent contact to roll up to
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal amountAfterDelete = updatedContact.reduivy__Total_Outstanding_Amount__c ?? 0;

        System.assertEquals(initialOutstandingAmount, amountAfterDelete, 
                        'Contact outstanding amount should not change for TROs with no parent contact');
        
        // Additional test: Create TRO with parent, then remove parent (old parent exists, new parent is blank)
        reduivy__Transaction_Order__c transactionOrderWithParent = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id, // HAS PARENT initially
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_CONFIRMED, // Qualified status
            200.00,  // totalAmount
            150.00,  // outstandingAmount
            50.00    // paidAmount
        );
        insert transactionOrderWithParent;
        
        // Get contact amount after insert (should include the TRO)
        Contact contactAfterParentInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                        FROM Contact 
                                        WHERE Id = :studentContact.Id];
        Decimal amountAfterParentInsert = contactAfterParentInsert.reduivy__Total_Outstanding_Amount__c;
        
        // Remove the parent contact (oldParent exists, newParent is blank) - should trigger rollup
        transactionOrderWithParent.reduivy__Contact__c = null;
        update transactionOrderWithParent;
        
        // Verify the rollup happened when parent was removed
        Contact contactAfterParentRemoval = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                            FROM Contact 
                                            WHERE Id = :studentContact.Id];
        
        Decimal expectedAmountAfterRemoval = amountAfterParentInsert - 150.00;
        System.assertEquals(expectedAmountAfterRemoval, contactAfterParentRemoval.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should decrease when parent is removed from qualified TRO');
    }

    //Faculty
    // ========== AFTER INSERT TESTS ==========

    /**
     * @description Test executeAfterInsert with TROs that do not have qualified status as Faculty (no rollup)
     */
    @IsTest static void testExecuteAfterInsertNonQualifiedStatusAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Store initial outstanding amount
        Decimal initialOutstandingAmount = studentContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Create transaction order with non-qualified status (e.g., DRAFT)
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // academicProgressId
                Date.today(),
                TRO_Helper.STATUS_TYPE_DRAFT, // Non-qualified status
                100.00,  // totalAmount
                50.00,   // outstandingAmount
                50.00    // paidAmount
            );
            
            insert transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should NOT change since status is not qualified
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];

        Decimal amountAfterDelete = updatedContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.assertEquals(initialOutstandingAmount, amountAfterDelete, 
                        'Contact outstanding amount should not change for non-qualified TRO status');
    }

    /**
     * @description Test executeAfterInsert with new TRO having qualified status and linked to contact as Faculty
     */
    @IsTest static void testExecuteAfterInsertQualifiedStatusAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Store initial outstanding amount
        Decimal initialOutstandingAmount = studentContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Create transaction order with qualified status (e.g., SUBMITTED)
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // academicProgressId
                Date.today(),
                TRO_Helper.STATUS_TYPE_SUBMITTED, // Qualified status
                100.00,  // totalAmount
                75.00,   // outstandingAmount
                25.00    // paidAmount
            );
            
            insert transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should be updated with TRO outstanding amount
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = initialOutstandingAmount + 75.00;
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should include new qualified TRO outstanding amount');
    }

    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test executeAfterUpdate with no relevant changes to status, amount, or parent as Faculty
     */
    @IsTest static void testExecuteAfterUpdateNoRelevantChangeAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Create and insert TRO with qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED, // Qualified status
            100.00,  // totalAmount
            60.00,   // outstandingAmount
            40.00    // paidAmount
        );
        insert transactionOrder;
        
        // Get contact's outstanding amount after initial insert
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterInsert = contactAfterInsert.reduivy__Total_Outstanding_Amount__c;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            // Muting trigger to avoid recalculating the outstanding amount
            REDU_TriggerController.muteTriggers(new Set<String>{'TRO_OutstandingAmountCalc_EXE'});

            // Update TRO with irrelevant change 
            transactionOrder.reduivy__Total_Amount__c = 1000;
            update transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should remain unchanged
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        System.assertEquals(amountAfterInsert, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should not change for irrelevant TRO updates');
    }

    /**
     * @description Test executeAfterUpdate when TRO status changes from non-qualified to qualified as Faculty
     */
    @IsTest static void testExecuteAfterUpdateBecameQualifiedAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Create and insert TRO with non-qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_DRAFT, // Non-qualified status
            100.00,  // totalAmount
            80.00,   // outstandingAmount
            20.00    // paidAmount
        );
        insert transactionOrder;
        
        // Get contact's outstanding amount after initial insert (should be unchanged)
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal initialAmount = contactAfterInsert.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Update TRO status to qualified
            transactionOrder.reduivy__Status__c = TRO_Helper.STATUS_TYPE_SUBMITTED;
            update transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should now include TRO amount
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = initialAmount + 80.00;
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should include TRO amount when status becomes qualified');
    }

    /**
     * @description Test executeAfterUpdate when TRO status changes from qualified to non-qualified as Faculty
     */
    @IsTest static void testExecuteAfterUpdateBecameNonQualifiedAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Create and insert TRO with qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_CONFIRMED, // Qualified status
            100.00,  // totalAmount
            100.00,   // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;
        
        // Get contact's outstanding amount after initial insert
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterInsert = contactAfterInsert.reduivy__Total_Outstanding_Amount__c;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Update TRO status to non-qualified
            transactionOrder.reduivy__Status__c = TRO_Helper.STATUS_TYPE_VOID;
            update transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should exclude TRO amount
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = amountAfterInsert - 100.00;
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should exclude TRO amount when status becomes non-qualified');
    }

    /**
     * @description Test executeAfterUpdate when qualified TRO outstanding amount changes as Faculty
     */
    @IsTest static void testExecuteAfterUpdateAmountChangedAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Create and insert TRO with qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED, // Qualified status
            100.00,  // totalAmount
            90.00,   // outstandingAmount
            10.00    // paidAmount
        );
        insert transactionOrder;
        
        // Get contact's outstanding amount after initial insert
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterInsert = contactAfterInsert.reduivy__Total_Outstanding_Amount__c;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Update TRO outstanding amount
            transactionOrder.reduivy__Total_Outstanding_Amount__c = 50.00;
            transactionOrder.reduivy__Total_Paid_Amount__c = 50.00;
            update transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should reflect the change
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = amountAfterInsert - 90.00 + 50.00; // Remove old amount, add new amount
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should reflect TRO outstanding amount changes');
    }

    /**
     * @description Test executeAfterUpdate when qualified TRO parent contact changes as Faculty
     */
    @IsTest static void testExecuteAfterUpdateParentChangedAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Get two different student contacts
        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                        FROM Contact 
                                        WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                        AND reduivy__Sample_Record_Code__c <> ''
                                        LIMIT 2];
        
        Contact originalContact = studentContacts[0];
        Contact newContact = studentContacts.size() > 1 ? studentContacts[1] : originalContact;
        
        // Create and insert TRO with qualified status linked to original contact
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            originalContact.reduivy__Sample_Record_Code__c,
            originalContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_CONFIRMED, // Qualified status
            100.00,  // totalAmount
            85.00,   // outstandingAmount
            15.00    // paidAmount
        );
        insert transactionOrder;
        
        // Get both contacts' outstanding amounts after initial insert
        Map<Id, Contact> contactsAfterInsert = new Map<Id, Contact>([SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                                                    FROM Contact 
                                                                    WHERE Id IN (:originalContact.Id, :newContact.Id)]);
        
        Decimal originalAmountAfterInsert = contactsAfterInsert.get(originalContact.Id).reduivy__Total_Outstanding_Amount__c;
        Decimal newAmountAfterInsert = contactsAfterInsert.get(newContact.Id).reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Update TRO to link to new contact
            transactionOrder.reduivy__Contact__c = newContact.Id;
            update transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Both contacts should have updated outstanding amounts
        Map<Id, Contact> updatedContacts = new Map<Id, Contact>([SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                                                FROM Contact 
                                                                WHERE Id IN (:originalContact.Id, :newContact.Id)]);
        
        Decimal expectedOriginalAmount = originalAmountAfterInsert - 85.00; // Remove TRO amount
        Decimal expectedNewAmount = newAmountAfterInsert + 85.00; // Add TRO amount
        
        System.assertEquals(expectedOriginalAmount, updatedContacts.get(originalContact.Id).reduivy__Total_Outstanding_Amount__c, 
                        'Original contact outstanding amount should decrease when TRO is moved away');
        
        System.assertEquals(expectedNewAmount, updatedContacts.get(newContact.Id).reduivy__Total_Outstanding_Amount__c, 
                        'New contact outstanding amount should increase when TRO is moved to it');
    }

    /**
     * @description Test executeAfterUpdate when old contact needs rollup due to parent change as Faculty
     */
    @IsTest static void testExecuteAfterUpdateOldContactNeedsRollupAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Get two different student contacts
        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                        FROM Contact 
                                        WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                        AND reduivy__Sample_Record_Code__c <> ''
                                        LIMIT 2];
        
        Contact originalContact = studentContacts[0];
        Contact newContact = studentContacts.size() > 1 ? studentContacts[1] : originalContact;
        
        // Create two TROs for the original contact - one will be moved, one will stay
        List<reduivy__Transaction_Order__c> transactionOrders = new List<reduivy__Transaction_Order__c>();
        
        transactionOrders.add(REDU_TestData_UTIL.newTransactionOrder(
            originalContact.reduivy__Sample_Record_Code__c,
            originalContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED, // Qualified status
            100.00,  // totalAmount
            60.00,   // outstandingAmount (this will be moved)
            40.00    // paidAmount
        ));
        
        transactionOrders.add(REDU_TestData_UTIL.newTransactionOrder(
            originalContact.reduivy__Sample_Record_Code__c,
            originalContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_CONFIRMED, // Qualified status
            200.00,  // totalAmount
            120.00,  // outstandingAmount (this will stay)
            80.00    // paidAmount
        ));
        
        insert transactionOrders;
        
        // Get both contacts' outstanding amounts after initial insert
        Map<Id, Contact> contactsAfterInsert = new Map<Id, Contact>([SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                                                    FROM Contact 
                                                                    WHERE Id IN (:originalContact.Id, :newContact.Id)]);
        
        Decimal originalAmountAfterInsert = contactsAfterInsert.get(originalContact.Id).reduivy__Total_Outstanding_Amount__c;
        Decimal newAmountAfterInsert = contactsAfterInsert.get(newContact.Id).reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Move first TRO to new contact, second stays with original
            transactionOrders[0].reduivy__Contact__c = newContact.Id;
            update transactionOrders[0];
            
            Test.stopTest();
        }
        
        // Assertions - Both contacts should have correct rollup calculations
        Map<Id, Contact> updatedContacts = new Map<Id, Contact>([SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                                                FROM Contact 
                                                                WHERE Id IN (:originalContact.Id, :newContact.Id)]);
        
        // Original contact should have only the remaining TRO's outstanding amount (120.00)
        Decimal expectedOriginalAmount = 120.00;
        
        // New contact should have the moved TRO's outstanding amount (60.00) plus any existing amount
        Decimal expectedNewAmount = newAmountAfterInsert + 60.00;
        
        System.assertEquals(expectedOriginalAmount, updatedContacts.get(originalContact.Id).reduivy__Total_Outstanding_Amount__c, 
                        'Original contact should be properly recalculated after TRO is moved away');
        
        System.assertEquals(expectedNewAmount, updatedContacts.get(newContact.Id).reduivy__Total_Outstanding_Amount__c, 
                        'New contact should include moved TRO amount in rollup calculation');
    }

    // ========== AFTER DELETE TESTS ==========

    /**
     * @description Test executeAfterDelete with TRO having non-qualified status as Faculty (no rollup)
     */
    @IsTest static void testExecuteAfterDeleteNonQualifiedStatusAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Create and insert TRO with non-qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_DRAFT, // Non-qualified status
            100.00,  // totalAmount
            90.00,   // outstandingAmount
            10.00    // paidAmount
        );

        System.runAs(FACULTY_USER) {
            insert transactionOrder;
        }
        
        // Get contact's outstanding amount after insert (should be unchanged due to non-qualified status)
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterInsert = contactAfterInsert.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Delete the non-qualified TRO
            delete transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should remain unchanged
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];

        Decimal amountAfterDelete = updatedContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.assertEquals(amountAfterInsert, amountAfterDelete, 
                        'Contact outstanding amount should not change when deleting non-qualified TRO');
    }

    /**
     * @description Test executeAfterDelete with qualified TRO linked to contact as Faculty
     */
    @IsTest static void testExecuteAfterDeleteQualifiedStatusAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Create and insert TRO with qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_CONFIRMED, // Qualified status
            100.00,  // totalAmount
            75.00,   // outstandingAmount
            25.00    // paidAmount
        );
        
        System.runAs(FACULTY_USER) {
            insert transactionOrder;
        }
        
        // Get contact's outstanding amount after insert
        Contact contactAfterInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterInsert = contactAfterInsert.reduivy__Total_Outstanding_Amount__c;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Delete the qualified TRO
            delete transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should decrease by TRO outstanding amount
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = amountAfterInsert - 75.00;
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should decrease when deleting qualified TRO');
    }

    // ========== AFTER UNDELETE TESTS ==========

    /**
     * @description Test executeAfterUndelete with TRO having non-qualified status as Faculty (no rollup)
     */
    @IsTest static void testExecuteAfterUndeleteNonQualifiedStatusAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Create and insert TRO with non-qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_DRAFT, // Non-qualified status
            100.00,  // totalAmount
            85.00,   // outstandingAmount
            15.00    // paidAmount
        );
        
        System.runAs(FACULTY_USER) {
            insert transactionOrder;
            // Delete the TRO first
            delete transactionOrder;
        }
        
        // Get contact's outstanding amount after delete
        Contact contactAfterDelete = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterDelete = contactAfterDelete.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Undelete the non-qualified TRO
            undelete transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should remain unchanged
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];

        Decimal amountAfterUndelete = updatedContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.assertEquals(amountAfterDelete, amountAfterUndelete, 
                        'Contact outstanding amount should not change when undeleting non-qualified TRO');
    }

    /**
     * @description Test executeAfterUndelete with qualified TRO linked to contact as Faculty
     */
    @IsTest static void testExecuteAfterUndeleteQualifiedStatusAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Create and insert TRO with qualified status
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED, // Qualified status
            100.00,  // totalAmount
            65.00,   // outstandingAmount
            35.00    // paidAmount
        );

        System.runAs(FACULTY_USER) {
            insert transactionOrder;
            
            // Delete the TRO first
            delete transactionOrder;
        }
        
        // Get contact's outstanding amount after delete
        Contact contactAfterDelete = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                    FROM Contact 
                                    WHERE Id = :studentContact.Id];
        Decimal amountAfterDelete = contactAfterDelete.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Undelete the qualified TRO
            undelete transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should increase by TRO outstanding amount
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal expectedAmount = amountAfterDelete + 65.00;
        System.assertEquals(expectedAmount, updatedContact.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should increase when undeleting qualified TRO');
    }

    /**
     * @description Test that TROs with no parent contact (both old and new are blank) do not trigger rollup
     */
    @IsTest static void testNoParentContactNoRollupAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                AND reduivy__Sample_Record_Code__c <> ''
                                LIMIT 1];
        
        // Store initial outstanding amount
        Decimal initialOutstandingAmount = studentContact.reduivy__Total_Outstanding_Amount__c ?? 0;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Create TRO with qualified status but NO parent contact
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                studentContact.reduivy__Sample_Record_Code__c,
                null, // contactId - NO PARENT
                null, // academicProgressId
                Date.today(),
                TRO_Helper.STATUS_TYPE_SUBMITTED, // Qualified status
                100.00,  // totalAmount
                80.00,   // outstandingAmount
                20.00    // paidAmount
            );
            insert transactionOrder;
            
            // Update the TRO (still with no parent) - this tests the update scenario
            transactionOrder.reduivy__Total_Outstanding_Amount__c = 90.00;
            transactionOrder.reduivy__Total_Paid_Amount__c = 10.00;
            update transactionOrder;
            
            // Delete the TRO (still with no parent) - this tests the delete scenario  
            delete transactionOrder;
            
            Test.stopTest();
        }
        
        // Assertions - Contact outstanding amount should remain completely unchanged
        // since the TRO never had a parent contact to roll up to
        Contact updatedContact = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                FROM Contact 
                                WHERE Id = :studentContact.Id];
        
        Decimal amountAfterDelete = updatedContact.reduivy__Total_Outstanding_Amount__c ?? 0;

        System.assertEquals(initialOutstandingAmount, amountAfterDelete, 
                        'Contact outstanding amount should not change for TROs with no parent contact');
        
        // Additional test: Create TRO with parent, then remove parent (old parent exists, new parent is blank)
        reduivy__Transaction_Order__c transactionOrderWithParent = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id, // HAS PARENT initially
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_CONFIRMED, // Qualified status
            200.00,  // totalAmount
            150.00,  // outstandingAmount
            50.00    // paidAmount
        );
        insert transactionOrderWithParent;
        
        // Get contact amount after insert (should include the TRO)
        Contact contactAfterParentInsert = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                        FROM Contact 
                                        WHERE Id = :studentContact.Id];
        Decimal amountAfterParentInsert = contactAfterParentInsert.reduivy__Total_Outstanding_Amount__c;
        
        // Remove the parent contact (oldParent exists, newParent is blank) - should trigger rollup
        transactionOrderWithParent.reduivy__Contact__c = null;
        update transactionOrderWithParent;
        
        // Verify the rollup happened when parent was removed
        Contact contactAfterParentRemoval = [SELECT Id, reduivy__Total_Outstanding_Amount__c 
                                            FROM Contact 
                                            WHERE Id = :studentContact.Id];
        
        Decimal expectedAmountAfterRemoval = amountAfterParentInsert - 150.00;
        System.assertEquals(expectedAmountAfterRemoval, contactAfterParentRemoval.reduivy__Total_Outstanding_Amount__c, 
                        'Contact outstanding amount should decrease when parent is removed from qualified TRO');
    }
}