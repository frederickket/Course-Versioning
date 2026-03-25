/**
 * @author      WDCi (XiRouh)
 * @date        Aug 2025
 * @group       Test
 * @description Test class for TRL_OffsetLineItemRollup_EXE
 * @changehistory
 * ISS-002587 13-08-2025 XiRouh - new class
 */
@IsTest
public inherited sharing class TRL_OffsetLineItemRollup_TEST {

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
     * @description Test monetary and discount entry insert with parent as admin - should update parent's reduivy__Offset_Amount__c and reduivy__Discount_Amount__c
     */
    @IsTest
    static void testAfterInsert_MonetaryAndDiscountEntry_WithParentAsAdmin() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount - should be updated by rollup
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Get initial values before monetary entry insert
        reduivy__Transaction_Line_Item__c parentBefore = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                        FROM reduivy__Transaction_Line_Item__c 
                                                        WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountBefore = parentBefore.reduivy__Offset_Amount__c ?? 0;
        Decimal discountBefore = parentBefore.reduivy__Discount__c ?? 0;
        
        // Create discount entry as child of the order line
        reduivy__Transaction_Line_Item__c discountEntry = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount',
            TRL_Helper.ITEM_TYPE_TUITION,
            25.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        // Set the parent relationship manually since helper method doesn't include it
        discountEntry.reduivy__Offset_Line_Item__c = parentOrderLine.Id;

        // Create monetary entry as child of the order line
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId - this makes it a child
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            50.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            insert discountEntry;
            insert monetaryEntry;
            
            Test.stopTest();
        }

        // Verify parent's Offset_Amount__c is updated correctly
        reduivy__Transaction_Line_Item__c parentAfter = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                        FROM reduivy__Transaction_Line_Item__c 
                                                        WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfter = parentAfter.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfter = parentAfter.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.isTrue(offsetAmountBefore != offsetAmountAfter, 'Parent offset amount should have changed');
        System.Assert.areEqual(0.00, offsetAmountBefore, 'Parent offset amount should initially be 0');
        System.Assert.areEqual(50.00, offsetAmountAfter, 'Parent offset amount should be updated to 50.00 after monetary entry insert');

        System.Assert.isTrue(discountBefore != discountAfter, 'Parent offset amount should have changed');
        System.Assert.areEqual(0.00, discountBefore, 'Parent offset amount should initially be 0');
        System.Assert.areEqual(25.00, discountAfter, 'Parent discount should be updated to 25.00 after discount entry insert');
    }

    /**
     * @description Test Non Transactional Entry insert - should not trigger rollup
     */
    @IsTest
    static void testAfterInsert_NonTransactionalType_WithParentAsAdmin() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Get initial values
        reduivy__Transaction_Line_Item__c parentBefore = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                        FROM reduivy__Transaction_Line_Item__c 
                                                        WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountBefore = parentBefore.reduivy__Offset_Amount__c ?? 0;
        Decimal discountBefore = parentBefore.reduivy__Discount__c ?? 0;

        // Create another Non Transactional Entry line with parent relationship
        reduivy__Transaction_Line_Item__c nonTransactionalEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            50.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );

        // Set parent relationship to test non-qualified rollup
        nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY;

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            insert nonTransactionalEntry;
            
            Test.stopTest();
        }

        // Verify no rollup occurs (needRollup returns false for non-qualified types)
        reduivy__Transaction_Line_Item__c parentAfter = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                        FROM reduivy__Transaction_Line_Item__c 
                                                        WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfter = parentAfter.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfter = parentAfter.reduivy__Discount__c ?? 0;

        // Assertions - values should remain unchanged
        System.Assert.areEqual(offsetAmountBefore, offsetAmountAfter, 'Parent offset amount should remain unchanged for non-qualified types');
        System.Assert.areEqual(discountBefore, discountAfter, 'Parent discount should remain unchanged for non-qualified types');
    }

    /**
     * @description Test insert without parent - should not trigger rollup
     */
    @IsTest
    static void testAfterInsert_WithoutParentAsAdmin() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE', 'TRO_UpdateStatus_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create monetary entry WITHOUT parent (Offset_Line_Item__c is null)
        reduivy__Transaction_Line_Item__c monetaryEntryWithoutParent = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment Without Parent',
            TRL_Helper.ITEM_TYPE_TUITION,
            50.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // This should not trigger any rollup since there's no parent
            insert monetaryEntryWithoutParent;
            
            Test.stopTest();
        }

        // Verify the record was created successfully (no exceptions thrown)
        reduivy__Transaction_Line_Item__c insertedRecord = [SELECT Id, reduivy__Offset_Line_Item__c, reduivy__Transaction_Type__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :monetaryEntryWithoutParent.Id];
        
        // Assertions
        System.assertNotEquals(null, insertedRecord.Id, 'Record should be inserted successfully');
        System.Assert.areEqual(null, insertedRecord.reduivy__Offset_Line_Item__c, 'Record should have no parent');
        System.Assert.areEqual(TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY, insertedRecord.reduivy__Transaction_Type__c, 'Record should be monetary entry type');
    }

    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test updating Total_Amount__c on monetary entry - should recalculate parent's Offset_Amount__c
     */
    @IsTest
    static void testAfterUpdate_AmountChanged_MonetaryEntryAsAdmin() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create monetary entry as child of the order line
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            30.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;

        // Get parent values after initial insert
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Update the monetary entry amount
            monetaryEntry.reduivy__Unit_Price__c = 50.00; // Changed from 30.00 to 50.00
            update monetaryEntry;
            
            Test.stopTest();
        }

        // Get parent values after update
        reduivy__Transaction_Line_Item__c parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(30.00, offsetAmountAfterInsert, 'Parent offset amount should be 30.00 after initial insert');
        System.Assert.areEqual(50.00, offsetAmountAfterUpdate, 'Parent offset amount should be updated to 50.00 after amount change');
        System.Assert.areEqual(discountAfterInsert, discountAfterUpdate, 'Parent discount should remain unchanged');
    }

    /**
     * @description Test updating Total_Amount__c on discount entry - should recalculate parent's Discount__c
     */
    @IsTest
    static void testAfterUpdate_AmountChanged_DiscountEntryAsAdmin() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create discount entry as child of the order line
        reduivy__Transaction_Line_Item__c discountEntry = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount',
            TRL_Helper.ITEM_TYPE_TUITION,
            20.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        discountEntry.reduivy__Offset_Line_Item__c = parentOrderLine.Id;
        insert discountEntry;

        // Get parent values after initial insert
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Update the discount entry amount
            discountEntry.reduivy__Unit_Price__c = 35.00; // Changed from 20.00 to 35.00
            update discountEntry;
            
            Test.stopTest();
        }

        // Get parent values after update
        reduivy__Transaction_Line_Item__c parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(20.00, discountAfterInsert, 'Parent discount should be 20.00 after initial insert');
        System.Assert.areEqual(35.00, discountAfterUpdate, 'Parent discount should be updated to 35.00 after amount change');
        System.Assert.areEqual(offsetAmountAfterInsert, offsetAmountAfterUpdate, 'Parent offset amount should remain unchanged');
    }

    /**
     * @description Test changing transaction type - should trigger rollup
     */
    @IsTest
    static void testAfterUpdate_TransactionTypeChanged_AsAdmin() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE', 'TRO_UpdateStatus_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create a non-qualified entry (Non Transactional Entry) with parent
        reduivy__Transaction_Line_Item__c nonTransactionalEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            40.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );

        nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY;

        insert nonTransactionalEntry;

        // Get parent values after initial insert (should be unchanged since non-qualified)
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Change transaction type to qualified type (MONETARYENTRY)
            nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY;
            nonTransactionalEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            update nonTransactionalEntry;
        }

        // Get parent values after update
        reduivy__Transaction_Line_Item__c parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(0.00, offsetAmountAfterInsert, 'Parent offset amount should remain 0 after non-qualified insert');
        System.Assert.areEqual(40.00, offsetAmountAfterUpdate, 'Parent offset amount should be updated to 40.00 after changing to qualified type');
        System.Assert.areEqual(discountAfterInsert, discountAfterUpdate, 'Parent discount should remain unchanged');

        System.runAs(ADMIN_USER) {

            // Change transaction type to non qualified type (NONTRANSACTIONALENTRY)
            nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY;
            update nonTransactionalEntry;
        }

        parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(0.00, offsetAmountAfterUpdate, 'Parent offset amount should be updated to 0 after changing to non qualified type');
        System.Assert.areEqual(discountAfterInsert, discountAfterUpdate, 'Parent discount should remain unchanged');

        System.runAs(ADMIN_USER) {
            
            // Change transaction type to qualified type (MONETARYENTRY)
            nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY;
            update nonTransactionalEntry;
        }

        // Get parent values after update
        parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(0.00, offsetAmountAfterInsert, 'Parent offset amount should remain 0 after non-qualified insert');
        System.Assert.areEqual(40.00, offsetAmountAfterUpdate, 'Parent offset amount should be updated to 40.00 after changing to qualified type');
        System.Assert.areEqual(discountAfterInsert, discountAfterUpdate, 'Parent discount should remain unchanged');

        System.runAs(ADMIN_USER) {
            
            // Change transaction type to qualified type (MONETARYENTRY)
            nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            nonTransactionalEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_DEBIT;
            update nonTransactionalEntry;
        }

        // Get parent values after update
        parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(0.00, offsetAmountAfterUpdate, 'Parent offset amount should be updated to 0.00 after changing to discount type');
        System.Assert.areEqual(40.00, discountAfterUpdate, 'Parent discount amount should be updated to 40.00 after changing to discount type');
    }

    /**
     * @description Test updating parent field (reduivy__Offset_Line_Item__c) - should trigger rollup
     */
    @IsTest
    static void testAfterUpdate_OffsetLineItemParentChangesAsAdmin() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact studentContact = [
            SELECT Id, reduivy__Sample_Record_Code__c
            FROM Contact
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create Transaction Order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            200.00, // totalAmount
            200.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create two parent offset line items
        reduivy__Transaction_Line_Item__c parentOrderLine1 = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null,
            'Test Fee Item 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00,
            0.00,
            100.00
        );
        reduivy__Transaction_Line_Item__c parentOrderLine2 = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null,
            'Test Fee Item 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00,
            0.00,
            100.00
        );
        insert new List<reduivy__Transaction_Line_Item__c>{parentOrderLine1, parentOrderLine2};

        // Create monetary entry WITH first parent (for scenario 1 and 3)
        reduivy__Transaction_Line_Item__c entryWithParent = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null,
            parentOrderLine1.Id,
            null,
            'Payment with Parent',
            TRL_Helper.ITEM_TYPE_TUITION,
            75.00,
            0.00,
            0.00
        );

        // Create monetary entry WITHOUT parent (for scenario 2)
        reduivy__Transaction_Line_Item__c entryNoParent = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null,
            null,
            null,
            'Payment without Parent',
            TRL_Helper.ITEM_TYPE_TUITION,
            66.00,
            0.00,
            0.00
        );
        insert new List<reduivy__Transaction_Line_Item__c>{entryWithParent, entryNoParent};

        System.runAs(ADMIN_USER) {
            Test.startTest();

            // ---------------- Scenario 1: Change from valid parent → different valid parent ----------------
            entryWithParent.reduivy__Offset_Line_Item__c = parentOrderLine2.Id;
            update entryWithParent;
        }

        // Fetch final parent values
        Map<Id, reduivy__Transaction_Line_Item__c> parentsFinal = new Map<Id, reduivy__Transaction_Line_Item__c>(
            [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c
            FROM reduivy__Transaction_Line_Item__c
            WHERE Id IN (:parentOrderLine1.Id, :parentOrderLine2.Id)]
        );

        // Assertions for Scenario 1: first → second
        System.assertEquals(0.00, parentsFinal.get(parentOrderLine1.Id).reduivy__Offset_Amount__c, 
            'After moving child from parent1 to parent2, parent1 should be 0.00');

        System.assertEquals(75.00, parentsFinal.get(parentOrderLine2.Id).reduivy__Offset_Amount__c, 
            'After moving child to parent2, parent2 should have 75.00');

        System.runAs(ADMIN_USER) {
            // ---------------- Scenario 2: Change from blank parent → valid parent ----------------
            entryNoParent.reduivy__Offset_Line_Item__c = parentOrderLine1.Id;
            update entryNoParent;
        }

        parentsFinal = new Map<Id, reduivy__Transaction_Line_Item__c>(
            [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c
            FROM reduivy__Transaction_Line_Item__c
            WHERE Id IN (:parentOrderLine1.Id, :parentOrderLine2.Id)]
        );

        // Assertions for Scenario 2: blank → valid
        System.assertEquals(66.00, parentsFinal.get(parentOrderLine1.Id).reduivy__Offset_Amount__c,
            'After assigning a child to parent1, it should have 66.00');

        System.assertEquals(75.00, parentsFinal.get(parentOrderLine2.Id).reduivy__Offset_Amount__c,
            'Parent2 should remain unchanged at 75.00');

        System.runAs(ADMIN_USER) {
            // ---------------- Scenario 3: Change from valid parent → blank parent ----------------
            entryWithParent.reduivy__Offset_Line_Item__c = null;
            update entryWithParent;

            Test.stopTest();
        }

        parentsFinal = new Map<Id, reduivy__Transaction_Line_Item__c>(
            [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c
            FROM reduivy__Transaction_Line_Item__c
            WHERE Id IN (:parentOrderLine1.Id, :parentOrderLine2.Id)]
        );

        // Assertions for Scenario 3: valid → blank
        System.assertEquals(66.00, parentsFinal.get(parentOrderLine1.Id).reduivy__Offset_Amount__c,
            'Parent1 should still have 66.00 from previous assignment');
        System.assertEquals(0.00, parentsFinal.get(parentOrderLine2.Id).reduivy__Offset_Amount__c,
            'Parent2 should be 0.00 after child removal');
    }

    /**
     * @description Test updating non-rollup fields - should not trigger rollup
     */
    @IsTest
    static void testAfterUpdate_NoRelevantChangesAsAdmin() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create monetary entry
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            80.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;

        // Get parent values after initial insert
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Update non-rollup fields (Item Name) - should not trigger rollup
            monetaryEntry.reduivy__Item_Name__c = 'Updated Payment Name';
            update monetaryEntry;
            
            Test.stopTest();
        }

        // Get parent values after update
        reduivy__Transaction_Line_Item__c parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions - values should remain unchanged since no relevant fields were updated
        System.Assert.areEqual(80.00, offsetAmountAfterInsert, 'Parent offset amount should be 80.00 after initial insert');
        System.Assert.areEqual(offsetAmountAfterInsert, offsetAmountAfterUpdate, 'Parent offset amount should remain unchanged after non-relevant field update');
        System.Assert.areEqual(discountAfterInsert, discountAfterUpdate, 'Parent discount should remain unchanged after non-relevant field update');
        
        // Verify the non-rollup field was actually updated
        reduivy__Transaction_Line_Item__c updatedMonetaryEntry = [SELECT Id, reduivy__Item_Name__c 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE Id = :monetaryEntry.Id];
        System.Assert.areEqual('Updated Payment Name', updatedMonetaryEntry.reduivy__Item_Name__c, 'Item name should be updated');
    }

    // ========== AFTER DELETE TESTS ==========
    
    /**
     * @description Test deleting monetary entry with parent - should decrease parent's Offset_Amount__c
     */
    @IsTest
    static void testAfterDelete_MonetaryEntry_WithParentAsAdmin() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create multiple monetary entries to test partial deletion
        List<reduivy__Transaction_Line_Item__c> monetaryEntries = new List<reduivy__Transaction_Line_Item__c>();
        
        reduivy__Transaction_Line_Item__c monetaryEntry1 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            30.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        monetaryEntries.add(monetaryEntry1);
        
        reduivy__Transaction_Line_Item__c monetaryEntry2 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            20.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        monetaryEntries.add(monetaryEntry2);
        
        insert monetaryEntries;

        // Get parent values after initial insert
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Delete one monetary entry
            delete monetaryEntry1;
            
            Test.stopTest();
        }

        // Get parent values after delete
        reduivy__Transaction_Line_Item__c parentAfterDelete = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterDelete = parentAfterDelete.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterDelete = parentAfterDelete.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(50.00, offsetAmountAfterInsert, 'Parent offset amount should be 50.00 after both inserts (30+20)');
        System.Assert.areEqual(20.00, offsetAmountAfterDelete, 'Parent offset amount should be 20.00 after deleting 30.00 entry');
        System.Assert.areEqual(discountAfterInsert, discountAfterDelete, 'Parent discount should remain unchanged');
        
        // Verify the record was actually deleted
        List<reduivy__Transaction_Line_Item__c> remainingEntries = [SELECT Id FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id = :monetaryEntry1.Id];
        System.Assert.areEqual(0, remainingEntries.size(), 'Deleted monetary entry should not exist');
    }

    /**
     * @description Test deleting discount entry with parent - should decrease parent's Discount__c
     */
    @IsTest
    static void testAfterDelete_DiscountEntry_WithParentAsAdmin() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create multiple discount entries to test partial deletion
        List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
        
        reduivy__Transaction_Line_Item__c discountEntry1 = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            15.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        discountEntry1.reduivy__Offset_Line_Item__c = parentOrderLine.Id;
        discountEntries.add(discountEntry1);
        
        reduivy__Transaction_Line_Item__c discountEntry2 = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            10.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        discountEntry2.reduivy__Offset_Line_Item__c = parentOrderLine.Id;
        discountEntries.add(discountEntry2);
        
        insert discountEntries;

        // Get parent values after initial insert
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Delete one discount entry
            delete discountEntry1;
            
            Test.stopTest();
        }

        // Get parent values after delete
        reduivy__Transaction_Line_Item__c parentAfterDelete = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterDelete = parentAfterDelete.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterDelete = parentAfterDelete.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(25.00, discountAfterInsert, 'Parent discount should be 25.00 after both inserts (15+10)');
        System.Assert.areEqual(10.00, discountAfterDelete, 'Parent discount should be 10.00 after deleting 15.00 entry');
        System.Assert.areEqual(offsetAmountAfterInsert, offsetAmountAfterDelete, 'Parent offset amount should remain unchanged');
        
        // Verify the record was actually deleted
        List<reduivy__Transaction_Line_Item__c> remainingEntries = [SELECT Id FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id = :discountEntry1.Id];
        System.Assert.areEqual(0, remainingEntries.size(), 'Deleted discount entry should not exist');
    }

    /**
     * @description Test bulk delete of mixed qualified types - should update parent totals correctly
     */
    @IsTest
    static void testAfterDelete_BulkDeleteAsAdmin() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE', 'TRO_UpdateStatus_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            200.00, // totalAmount
            200.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create multiple parent offset line items
        List<reduivy__Transaction_Line_Item__c> parentOrderLines = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= 2; i++) {
            reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
                studentContact.reduivy__Sample_Record_Code__c,
                transactionOrder.Id,
                null, // studyFeeMatrixItemId
                'Test Fee Item ' + i,
                TRL_Helper.ITEM_TYPE_TUITION,
                100.00, // totalAmount
                0.00,   // offsetAmount
                100.00  // outstandingAmount
            );
            parentOrderLines.add(parentOrderLine);
        }
        insert parentOrderLines;

        // Create mixed transaction line items for bulk delete
        List<reduivy__Transaction_Line_Item__c> mixedEntries = new List<reduivy__Transaction_Line_Item__c>();
        
        // 1. Monetary Entry (qualified) - will be deleted
        reduivy__Transaction_Line_Item__c monetaryEntry1 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLines[0].Id, // first parent
            null, // idvFundingAllocationId
            'Test Payment 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            30.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        mixedEntries.add(monetaryEntry1);
        
        // 2. Monetary Entry (qualified) - will remain
        reduivy__Transaction_Line_Item__c monetaryEntry2 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLines[0].Id, // first parent
            null, // idvFundingAllocationId
            'Test Payment 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            20.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        mixedEntries.add(monetaryEntry2);
        
        // 3. Discount Entry (qualified) - will be deleted
        reduivy__Transaction_Line_Item__c discountEntry1 = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            15.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        discountEntry1.reduivy__Offset_Line_Item__c = parentOrderLines[1].Id; // second parent
        mixedEntries.add(discountEntry1);
        
        // 4. Discount Entry (qualified) - will remain
        reduivy__Transaction_Line_Item__c discountEntry2 = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            10.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        discountEntry2.reduivy__Offset_Line_Item__c = parentOrderLines[1].Id; // second parent
        mixedEntries.add(discountEntry2);
        
        // 5. Order Line (non-qualified) - will be deleted but should not affect rollup
        reduivy__Transaction_Line_Item__c orderLineEntry = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Another Order Line',
            TRL_Helper.ITEM_TYPE_TUITION,
            25.00, // totalAmount
            0.00,  // offsetAmount
            25.00  // outstandingAmount
        );
        orderLineEntry.reduivy__Offset_Line_Item__c = parentOrderLines[0].Id; // first parent
        mixedEntries.add(orderLineEntry);
        
        // 6. Monetary Entry without parent - will be deleted but should not affect rollup
        reduivy__Transaction_Line_Item__c monetaryWithoutParent = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            null, // NO PARENT
            null, // idvFundingAllocationId
            'Test Payment 3',
            TRL_Helper.ITEM_TYPE_TUITION,
            35.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        mixedEntries.add(monetaryWithoutParent);
        
        insert mixedEntries;

        // Get parent values after initial insert
        List<reduivy__Transaction_Line_Item__c> parentsAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                                    FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id IN :parentOrderLines
                                                                    ORDER BY reduivy__Item_Name__c];
        
        Map<Id, reduivy__Transaction_Line_Item__c> parentMapAfterInsert = new Map<Id, reduivy__Transaction_Line_Item__c>(parentsAfterInsert);

        // Prepare entries to delete (will delete some qualified and some non-qualified)
        List<reduivy__Transaction_Line_Item__c> entriesToDelete = new List<reduivy__Transaction_Line_Item__c>{
            monetaryEntry1,      // Qualified - affects parent 1
            discountEntry1,      // Qualified - affects parent 2
            orderLineEntry,      // Non-qualified - should not affect rollup
            monetaryWithoutParent // Qualified but no parent - should not affect rollup
        };

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Bulk delete mixed entries
            delete entriesToDelete;
            
            Test.stopTest();
        }

        // Get parent values after delete
        List<reduivy__Transaction_Line_Item__c> parentsAfterDelete = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                                    FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id IN :parentOrderLines
                                                                    ORDER BY reduivy__Item_Name__c];
        
        Map<Id, reduivy__Transaction_Line_Item__c> parentMapAfterDelete = new Map<Id, reduivy__Transaction_Line_Item__c>(parentsAfterDelete);

        // Assertions
        // Parent 1 should have had 50.00 (30+20) offset amount, after delete should have 20.00
        System.Assert.areEqual(50.00, parentMapAfterInsert.get(parentOrderLines[0].Id).reduivy__Offset_Amount__c ?? 0, 
                        'Parent 1 should have 50.00 offset amount after initial insert');
        System.Assert.areEqual(20.00, parentMapAfterDelete.get(parentOrderLines[0].Id).reduivy__Offset_Amount__c ?? 0, 
                        'Parent 1 should have 20.00 offset amount after deleting 30.00 monetary entry');
        
        // Parent 2 should have had 25.00 (15+10) discount, after delete should have 10.00
        System.Assert.areEqual(25.00, parentMapAfterInsert.get(parentOrderLines[1].Id).reduivy__Discount__c ?? 0, 
                        'Parent 2 should have 25.00 discount after initial insert');
        System.Assert.areEqual(10.00, parentMapAfterDelete.get(parentOrderLines[1].Id).reduivy__Discount__c ?? 0, 
                        'Parent 2 should have 10.00 discount after deleting 15.00 discount entry');
        
        // Verify the records were actually deleted
        List<reduivy__Transaction_Line_Item__c> remainingDeletedEntries = [SELECT Id FROM reduivy__Transaction_Line_Item__c 
                                                                        WHERE Id IN :entriesToDelete];
        System.Assert.areEqual(0, remainingDeletedEntries.size(), 'All deleted entries should not exist');
        
        // Verify remaining entries still exist
        List<reduivy__Transaction_Line_Item__c> remainingEntries = [SELECT Id FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id = :monetaryEntry2.Id OR Id = :discountEntry2.Id];
        System.Assert.areEqual(2, remainingEntries.size(), 'Remaining entries should still exist');
    }

    // ========== AFTER UNDELETE TESTS ==========

    /**
     * @description Test undelete monetary entry with valid parent - as admin
     */
    @IsTest
    static void testAfterUndelete_MonetaryEntry_WithParentAsAdmin() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [
            SELECT Id, reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        System.runAs(ADMIN_USER) {
            
            // Create necessary parent records
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // academicProgressId
                Date.today(),
                TRO_Helper.STATUS_TYPE_SUBMITTED,
                100.00, // totalAmount
                100.00, // outstandingAmount
                0.00    // paidAmount
            );
            insert transactionOrder;

            // Create parent order line
            reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
                studentContact.reduivy__Sample_Record_Code__c,
                transactionOrder.Id,
                null, // studyFeeMatrixItemId
                'Test Fee Item',
                TRL_Helper.ITEM_TYPE_TUITION,
                100.00, // totalAmount
                0.00,   // offsetAmount
                100.00  // outstandingAmount
            );
            insert parentOrderLine;

            // Create monetary entry as child of the order line
            reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
                studentContact.reduivy__Sample_Record_Code__c,
                transactionOrder.Id,
                null, // transactionPaymentId
                parentOrderLine.Id, // offsetLineItemId
                null, // idvFundingAllocationId
                'Test Payment',
                TRL_Helper.ITEM_TYPE_TUITION,
                25.00, // totalAmount
                0.00,  // offsetAmount
                0.00   // outstandingAmount
            );
            insert monetaryEntry;

            // Get parent's offset amount before delete
            reduivy__Transaction_Line_Item__c parentBefore = [
                SELECT reduivy__Offset_Amount__c 
                FROM reduivy__Transaction_Line_Item__c 
                WHERE Id = :parentOrderLine.Id
            ];
            Decimal offsetBefore = parentBefore.reduivy__Offset_Amount__c;

            // Delete the monetary entry
            delete monetaryEntry;

            // Verify parent's offset amount was reduced
            reduivy__Transaction_Line_Item__c parentAfterDelete = [
                SELECT reduivy__Offset_Amount__c 
                FROM reduivy__Transaction_Line_Item__c 
                WHERE Id = :parentOrderLine.Id
            ];

            Test.startTest();
            
            // Undelete the monetary entry
            undelete monetaryEntry;
            
            Test.stopTest();

            // Verify parent's Offset_Amount__c is restored
            reduivy__Transaction_Line_Item__c parentAfterUndelete = [
                SELECT reduivy__Offset_Amount__c 
                FROM reduivy__Transaction_Line_Item__c 
                WHERE Id = :parentOrderLine.Id
            ];
            
            System.assertEquals(offsetBefore, parentAfterUndelete.reduivy__Offset_Amount__c, 
                'Parent offset amount should be restored after undelete');
            System.assertEquals(25.00, parentAfterUndelete.reduivy__Offset_Amount__c, 
                'Parent offset amount should equal monetary entry amount');
        }
    }

    /**
     * @description Test undelete discount entry with valid parent - as admin
     */
    @IsTest
    static void testAfterUndelete_DiscountEntry_WithParentAsAdmin() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        System.runAs(ADMIN_USER) {
            
            // Create necessary parent records
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // academicProgressId
                Date.today(),
                TRO_Helper.STATUS_TYPE_SUBMITTED,
                100.00, // totalAmount
                100.00, // outstandingAmount
                0.00    // paidAmount
            );
            insert transactionOrder;

            // Create parent order line
            reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
                studentContact.reduivy__Sample_Record_Code__c,
                transactionOrder.Id,
                null, // studyFeeMatrixItemId
                'Test Fee Item',
                TRL_Helper.ITEM_TYPE_TUITION,
                100.00, // totalAmount
                0.00,   // offsetAmount
                100.00  // outstandingAmount
            );
            insert parentOrderLine;

            // Create discount entry as child of the order line
            reduivy__Transaction_Line_Item__c discountEntry = REDU_TestData_UTIL.newTransactionDiscountEntry(
                studentContact.reduivy__Sample_Record_Code__c,
                transactionOrder.Id,
                'Test Discount',
                TRL_Helper.ITEM_TYPE_TUITION,
                25.00, // totalAmount
                null,  // idvFundingAllocationId
                null,  // studyVoucherTransactionId
                null,  // studyFeeMatrixItemId
                null   // individualEnrollmentId
            );
            // Set the parent relationship for discount entry
            discountEntry.reduivy__Offset_Line_Item__c = parentOrderLine.Id;
            insert discountEntry;

            // Get the parent's discount amount before delete
            reduivy__Transaction_Line_Item__c parentBefore = [SELECT reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
            Decimal discountBefore = parentBefore.reduivy__Discount__c;

            // Delete the discount entry
            delete discountEntry;

            // Verify parent's discount amount was reduced
            reduivy__Transaction_Line_Item__c parentAfterDelete = [SELECT reduivy__Discount__c 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE Id = :parentOrderLine.Id];
            
            Test.startTest();
            
            // Undelete the discount entry
            undelete discountEntry;
            
            Test.stopTest();

            // Verify parent's Discount__c is increased back
            reduivy__Transaction_Line_Item__c parentAfterUndelete = [SELECT reduivy__Discount__c 
                                                                    FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id = :parentOrderLine.Id];
            
            System.assertEquals(discountBefore, parentAfterUndelete.reduivy__Discount__c, 
                            'Parent discount amount should be restored after undelete');
            System.assertEquals(25.00, parentAfterUndelete.reduivy__Discount__c, 
                            'Parent discount amount should equal discount entry amount');
        }
    }

    //Student
        // ========== AFTER INSERT TESTS ==========

    /**
     * @description Test monetary and discount entry insert with parent as Student - should update parent's reduivy__Offset_Amount__c and reduivy__Discount_Amount__c
     */
    @IsTest
    static void testAfterInsert_MonetaryAndDiscountEntry_WithParentAsStudent() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});
        
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
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount - should be updated by rollup
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Get initial values before monetary entry insert
        reduivy__Transaction_Line_Item__c parentBefore = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                        FROM reduivy__Transaction_Line_Item__c 
                                                        WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountBefore = parentBefore.reduivy__Offset_Amount__c ?? 0;
        Decimal discountBefore = parentBefore.reduivy__Discount__c ?? 0;
        
        // Create discount entry as child of the order line
        reduivy__Transaction_Line_Item__c discountEntry = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount',
            TRL_Helper.ITEM_TYPE_TUITION,
            25.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        // Set the parent relationship manually since helper method doesn't include it
        discountEntry.reduivy__Offset_Line_Item__c = parentOrderLine.Id;

        // Create monetary entry as child of the order line
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId - this makes it a child
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            50.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );

        System.runAs(studentUser) {
            Test.startTest();
            
            insert discountEntry;
            insert monetaryEntry;
            
            Test.stopTest();
        }

        // Verify parent's Offset_Amount__c is updated correctly
        reduivy__Transaction_Line_Item__c parentAfter = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                        FROM reduivy__Transaction_Line_Item__c 
                                                        WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfter = parentAfter.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfter = parentAfter.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.isTrue(offsetAmountBefore != offsetAmountAfter, 'Parent offset amount should have changed');
        System.Assert.areEqual(0.00, offsetAmountBefore, 'Parent offset amount should initially be 0');
        System.Assert.areEqual(50.00, offsetAmountAfter, 'Parent offset amount should be updated to 50.00 after monetary entry insert');

        System.Assert.isTrue(discountBefore != discountAfter, 'Parent offset amount should have changed');
        System.Assert.areEqual(0.00, discountBefore, 'Parent offset amount should initially be 0');
        System.Assert.areEqual(25.00, discountAfter, 'Parent discount should be updated to 25.00 after discount entry insert');
    }

    /**
     * @description Test Non Transactional Entry insert - should not trigger rollup
     */
    @IsTest
    static void testAfterInsert_NonTransactionalType_WithParentAsStudent() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

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
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Get initial values
        reduivy__Transaction_Line_Item__c parentBefore = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                        FROM reduivy__Transaction_Line_Item__c 
                                                        WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountBefore = parentBefore.reduivy__Offset_Amount__c ?? 0;
        Decimal discountBefore = parentBefore.reduivy__Discount__c ?? 0;

        // Create another Non Transactional Entry line with parent relationship
        reduivy__Transaction_Line_Item__c nonTransactionalEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            50.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );

        // Set parent relationship to test non-qualified rollup
        nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY;

        System.runAs(studentUser) {
            Test.startTest();
            
            insert nonTransactionalEntry;
            
            Test.stopTest();
        }

        // Verify no rollup occurs (needRollup returns false for non-qualified types)
        reduivy__Transaction_Line_Item__c parentAfter = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                        FROM reduivy__Transaction_Line_Item__c 
                                                        WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfter = parentAfter.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfter = parentAfter.reduivy__Discount__c ?? 0;

        // Assertions - values should remain unchanged
        System.Assert.areEqual(offsetAmountBefore, offsetAmountAfter, 'Parent offset amount should remain unchanged for non-qualified types');
        System.Assert.areEqual(discountBefore, discountAfter, 'Parent discount should remain unchanged for non-qualified types');
    }

    /**
     * @description Test insert without parent - should not trigger rollup
     */
    @IsTest
    static void testAfterInsert_WithoutParentAsStudent() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE', 'TRO_UpdateStatus_EXE'});

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
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create monetary entry WITHOUT parent (Offset_Line_Item__c is null)
        reduivy__Transaction_Line_Item__c monetaryEntryWithoutParent = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment Without Parent',
            TRL_Helper.ITEM_TYPE_TUITION,
            50.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );

        System.runAs(studentUser) {
            Test.startTest();
            
            // This should not trigger any rollup since there's no parent
            insert monetaryEntryWithoutParent;
            
            Test.stopTest();
        }

        // Verify the record was created successfully (no exceptions thrown)
        reduivy__Transaction_Line_Item__c insertedRecord = [SELECT Id, reduivy__Offset_Line_Item__c, reduivy__Transaction_Type__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :monetaryEntryWithoutParent.Id];
        
        // Assertions
        System.assertNotEquals(null, insertedRecord.Id, 'Record should be inserted successfully');
        System.Assert.areEqual(null, insertedRecord.reduivy__Offset_Line_Item__c, 'Record should have no parent');
        System.Assert.areEqual(TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY, insertedRecord.reduivy__Transaction_Type__c, 'Record should be monetary entry type');
    }

    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test updating Total_Amount__c on monetary entry - should recalculate parent's Offset_Amount__c
     */
    @IsTest
    static void testAfterUpdate_AmountChanged_MonetaryEntryAsStudent() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

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
		
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create monetary entry as child of the order line
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            30.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;

        // Get parent values after initial insert
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(studentUser) {
            Test.startTest();
            
            // Update the monetary entry amount
            monetaryEntry.reduivy__Unit_Price__c = 50.00; // Changed from 30.00 to 50.00
            update monetaryEntry;
            
            Test.stopTest();
        }

        // Get parent values after update
        reduivy__Transaction_Line_Item__c parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(30.00, offsetAmountAfterInsert, 'Parent offset amount should be 30.00 after initial insert');
        System.Assert.areEqual(50.00, offsetAmountAfterUpdate, 'Parent offset amount should be updated to 50.00 after amount change');
        System.Assert.areEqual(discountAfterInsert, discountAfterUpdate, 'Parent discount should remain unchanged');
    }

    /**
     * @description Test updating Total_Amount__c on discount entry - should recalculate parent's Discount__c
     */
    @IsTest
    static void testAfterUpdate_AmountChanged_DiscountEntryAsStudent() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

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
		
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create discount entry as child of the order line
        reduivy__Transaction_Line_Item__c discountEntry = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount',
            TRL_Helper.ITEM_TYPE_TUITION,
            20.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        discountEntry.reduivy__Offset_Line_Item__c = parentOrderLine.Id;
        insert discountEntry;

        // Get parent values after initial insert
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(studentUser) {
            Test.startTest();
            
            // Update the discount entry amount
            discountEntry.reduivy__Unit_Price__c = 35.00; // Changed from 20.00 to 35.00
            update discountEntry;
            
            Test.stopTest();
        }

        // Get parent values after update
        reduivy__Transaction_Line_Item__c parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(20.00, discountAfterInsert, 'Parent discount should be 20.00 after initial insert');
        System.Assert.areEqual(35.00, discountAfterUpdate, 'Parent discount should be updated to 35.00 after amount change');
        System.Assert.areEqual(offsetAmountAfterInsert, offsetAmountAfterUpdate, 'Parent offset amount should remain unchanged');
    }

    /**
     * @description Test changing transaction type - should trigger rollup
     */
    @IsTest
    static void testAfterUpdate_TransactionTypeChanged_AsStudent() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE', 'TRO_UpdateStatus_EXE'});

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
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create a non-qualified entry (Non Transactional Entry) with parent
        reduivy__Transaction_Line_Item__c nonTransactionalEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            40.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );

        nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY;

        insert nonTransactionalEntry;

        // Get parent values after initial insert (should be unchanged since non-qualified)
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(studentUser) {
            Test.startTest();
            
            // Change transaction type to qualified type (MONETARYENTRY)
            nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY;
            nonTransactionalEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            update nonTransactionalEntry;
        }

        // Get parent values after update
        reduivy__Transaction_Line_Item__c parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(0.00, offsetAmountAfterInsert, 'Parent offset amount should remain 0 after non-qualified insert');
        System.Assert.areEqual(40.00, offsetAmountAfterUpdate, 'Parent offset amount should be updated to 40.00 after changing to qualified type');
        System.Assert.areEqual(discountAfterInsert, discountAfterUpdate, 'Parent discount should remain unchanged');

        System.runAs(studentUser) {

            // Change transaction type to non qualified type (NONTRANSACTIONALENTRY)
            nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY;
            update nonTransactionalEntry;
        }

        parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(0.00, offsetAmountAfterUpdate, 'Parent offset amount should be updated to 0 after changing to non qualified type');
        System.Assert.areEqual(discountAfterInsert, discountAfterUpdate, 'Parent discount should remain unchanged');

        System.runAs(studentUser) {
            
            // Change transaction type to qualified type (MONETARYENTRY)
            nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY;
            update nonTransactionalEntry;
        }

        // Get parent values after update
        parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(0.00, offsetAmountAfterInsert, 'Parent offset amount should remain 0 after non-qualified insert');
        System.Assert.areEqual(40.00, offsetAmountAfterUpdate, 'Parent offset amount should be updated to 40.00 after changing to qualified type');
        System.Assert.areEqual(discountAfterInsert, discountAfterUpdate, 'Parent discount should remain unchanged');

        System.runAs(studentUser) {
            
            // Change transaction type to qualified type (MONETARYENTRY)
            nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            nonTransactionalEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_DEBIT;
            update nonTransactionalEntry;
        }

        // Get parent values after update
        parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(0.00, offsetAmountAfterUpdate, 'Parent offset amount should be updated to 0.00 after changing to discount type');
        System.Assert.areEqual(40.00, discountAfterUpdate, 'Parent discount amount should be updated to 40.00 after changing to discount type');
    }

    /**
     * @description Test updating parent field (reduivy__Offset_Line_Item__c) - should trigger rollup
     */
    @IsTest
    static void testAfterUpdate_OffsetLineItemParentChangesAsStudent() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        Contact studentContact = [
            SELECT Id, reduivy__Sample_Record_Code__c
            FROM Contact
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        // Create Transaction Order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            200.00, // totalAmount
            200.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create two parent offset line items
        reduivy__Transaction_Line_Item__c parentOrderLine1 = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null,
            'Test Fee Item 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00,
            0.00,
            100.00
        );
        reduivy__Transaction_Line_Item__c parentOrderLine2 = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null,
            'Test Fee Item 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00,
            0.00,
            100.00
        );
        insert new List<reduivy__Transaction_Line_Item__c>{parentOrderLine1, parentOrderLine2};

        // Create monetary entry WITH first parent (for scenario 1 and 3)
        reduivy__Transaction_Line_Item__c entryWithParent = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null,
            parentOrderLine1.Id,
            null,
            'Payment with Parent',
            TRL_Helper.ITEM_TYPE_TUITION,
            75.00,
            0.00,
            0.00
        );

        // Create monetary entry WITHOUT parent (for scenario 2)
        reduivy__Transaction_Line_Item__c entryNoParent = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null,
            null,
            null,
            'Payment without Parent',
            TRL_Helper.ITEM_TYPE_TUITION,
            66.00,
            0.00,
            0.00
        );
        insert new List<reduivy__Transaction_Line_Item__c>{entryWithParent, entryNoParent};

        System.runAs(studentUser) {
            Test.startTest();

            // ---------------- Scenario 1: Change from valid parent → different valid parent ----------------
            entryWithParent.reduivy__Offset_Line_Item__c = parentOrderLine2.Id;
            update entryWithParent;
        }

        // Fetch final parent values
        Map<Id, reduivy__Transaction_Line_Item__c> parentsFinal = new Map<Id, reduivy__Transaction_Line_Item__c>(
            [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c
            FROM reduivy__Transaction_Line_Item__c
            WHERE Id IN (:parentOrderLine1.Id, :parentOrderLine2.Id)]
        );

        // Assertions for Scenario 1: first → second
        System.assertEquals(0.00, parentsFinal.get(parentOrderLine1.Id).reduivy__Offset_Amount__c, 
            'After moving child from parent1 to parent2, parent1 should be 0.00');

        System.assertEquals(75.00, parentsFinal.get(parentOrderLine2.Id).reduivy__Offset_Amount__c, 
            'After moving child to parent2, parent2 should have 75.00');

        System.runAs(studentUser) {
            // ---------------- Scenario 2: Change from blank parent → valid parent ----------------
            entryNoParent.reduivy__Offset_Line_Item__c = parentOrderLine1.Id;
            update entryNoParent;
        }

        parentsFinal = new Map<Id, reduivy__Transaction_Line_Item__c>(
            [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c
            FROM reduivy__Transaction_Line_Item__c
            WHERE Id IN (:parentOrderLine1.Id, :parentOrderLine2.Id)]
        );

        // Assertions for Scenario 2: blank → valid
        System.assertEquals(66.00, parentsFinal.get(parentOrderLine1.Id).reduivy__Offset_Amount__c,
            'After assigning a child to parent1, it should have 66.00');

        System.assertEquals(75.00, parentsFinal.get(parentOrderLine2.Id).reduivy__Offset_Amount__c,
            'Parent2 should remain unchanged at 75.00');

        System.runAs(studentUser) {
            // ---------------- Scenario 3: Change from valid parent → blank parent ----------------
            entryWithParent.reduivy__Offset_Line_Item__c = null;
            update entryWithParent;

            Test.stopTest();
        }

        parentsFinal = new Map<Id, reduivy__Transaction_Line_Item__c>(
            [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c
            FROM reduivy__Transaction_Line_Item__c
            WHERE Id IN (:parentOrderLine1.Id, :parentOrderLine2.Id)]
        );

        // Assertions for Scenario 3: valid → blank
        System.assertEquals(66.00, parentsFinal.get(parentOrderLine1.Id).reduivy__Offset_Amount__c,
            'Parent1 should still have 66.00 from previous assignment');
        System.assertEquals(0.00, parentsFinal.get(parentOrderLine2.Id).reduivy__Offset_Amount__c,
            'Parent2 should be 0.00 after child removal');
    }

    /**
     * @description Test updating non-rollup fields - should not trigger rollup
     */
    @IsTest
    static void testAfterUpdate_NoRelevantChangesAsStudent() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

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
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create monetary entry
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            80.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;

        // Get parent values after initial insert
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(studentUser) {
            Test.startTest();
            
            // Update non-rollup fields (Item Name) - should not trigger rollup
            monetaryEntry.reduivy__Item_Name__c = 'Updated Payment Name';
            update monetaryEntry;
            
            Test.stopTest();
        }

        // Get parent values after update
        reduivy__Transaction_Line_Item__c parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions - values should remain unchanged since no relevant fields were updated
        System.Assert.areEqual(80.00, offsetAmountAfterInsert, 'Parent offset amount should be 80.00 after initial insert');
        System.Assert.areEqual(offsetAmountAfterInsert, offsetAmountAfterUpdate, 'Parent offset amount should remain unchanged after non-relevant field update');
        System.Assert.areEqual(discountAfterInsert, discountAfterUpdate, 'Parent discount should remain unchanged after non-relevant field update');
        
        // Verify the non-rollup field was actually updated
        reduivy__Transaction_Line_Item__c updatedMonetaryEntry = [SELECT Id, reduivy__Item_Name__c 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE Id = :monetaryEntry.Id];
        System.Assert.areEqual('Updated Payment Name', updatedMonetaryEntry.reduivy__Item_Name__c, 'Item name should be updated');
    }

    // ========== AFTER DELETE TESTS ==========
    
    /**
     * @description Test deleting monetary entry with parent - should decrease parent's Offset_Amount__c
     */
    @IsTest
    static void testAfterDelete_MonetaryEntry_WithParentAsStudent() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});
        
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
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create multiple monetary entries to test partial deletion
        List<reduivy__Transaction_Line_Item__c> monetaryEntries = new List<reduivy__Transaction_Line_Item__c>();
        
        reduivy__Transaction_Line_Item__c monetaryEntry1 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            30.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        monetaryEntries.add(monetaryEntry1);
        
        reduivy__Transaction_Line_Item__c monetaryEntry2 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            20.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        monetaryEntries.add(monetaryEntry2);
        
        System.runAs(studentUser) {
            insert monetaryEntries;
        }

        // Get parent values after initial insert
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(studentUser) {
            Test.startTest();
            
            // Delete one monetary entry
            delete monetaryEntry1;
            
            Test.stopTest();
        }

        // Get parent values after delete
        reduivy__Transaction_Line_Item__c parentAfterDelete = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterDelete = parentAfterDelete.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterDelete = parentAfterDelete.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(50.00, offsetAmountAfterInsert, 'Parent offset amount should be 50.00 after both inserts (30+20)');
        System.Assert.areEqual(20.00, offsetAmountAfterDelete, 'Parent offset amount should be 20.00 after deleting 30.00 entry');
        System.Assert.areEqual(discountAfterInsert, discountAfterDelete, 'Parent discount should remain unchanged');
        
        // Verify the record was actually deleted
        List<reduivy__Transaction_Line_Item__c> remainingEntries = [SELECT Id FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id = :monetaryEntry1.Id];
        System.Assert.areEqual(0, remainingEntries.size(), 'Deleted monetary entry should not exist');
    }

    /**
     * @description Test deleting discount entry with parent - should decrease parent's Discount__c
     */
    @IsTest
    static void testAfterDelete_DiscountEntry_WithParentAsStudent() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

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
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create multiple discount entries to test partial deletion
        List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
        
        reduivy__Transaction_Line_Item__c discountEntry1 = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            15.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        discountEntry1.reduivy__Offset_Line_Item__c = parentOrderLine.Id;
        discountEntries.add(discountEntry1);
        
        reduivy__Transaction_Line_Item__c discountEntry2 = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            10.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        discountEntry2.reduivy__Offset_Line_Item__c = parentOrderLine.Id;
        discountEntries.add(discountEntry2);
        
        System.runAs(studentUser) {
            insert discountEntries;
        }

        // Get parent values after initial insert
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(studentUser) {
            Test.startTest();
            
            // Delete one discount entry
            delete discountEntry1;
            
            Test.stopTest();
        }

        // Get parent values after delete
        reduivy__Transaction_Line_Item__c parentAfterDelete = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterDelete = parentAfterDelete.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterDelete = parentAfterDelete.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(25.00, discountAfterInsert, 'Parent discount should be 25.00 after both inserts (15+10)');
        System.Assert.areEqual(10.00, discountAfterDelete, 'Parent discount should be 10.00 after deleting 15.00 entry');
        System.Assert.areEqual(offsetAmountAfterInsert, offsetAmountAfterDelete, 'Parent offset amount should remain unchanged');
        
        // Verify the record was actually deleted
        List<reduivy__Transaction_Line_Item__c> remainingEntries = [SELECT Id FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id = :discountEntry1.Id];
        System.Assert.areEqual(0, remainingEntries.size(), 'Deleted discount entry should not exist');
    }

    /**
     * @description Test bulk delete of mixed qualified types - should update parent totals correctly
     */
    @IsTest
    static void testAfterDelete_BulkDeleteAsStudent() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE', 'TRO_UpdateStatus_EXE'});

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
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            200.00, // totalAmount
            200.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create multiple parent offset line items
        List<reduivy__Transaction_Line_Item__c> parentOrderLines = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= 2; i++) {
            reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
                studentContact.reduivy__Sample_Record_Code__c,
                transactionOrder.Id,
                null, // studyFeeMatrixItemId
                'Test Fee Item ' + i,
                TRL_Helper.ITEM_TYPE_TUITION,
                100.00, // totalAmount
                0.00,   // offsetAmount
                100.00  // outstandingAmount
            );
            parentOrderLines.add(parentOrderLine);
        }
        insert parentOrderLines;

        // Create mixed transaction line items for bulk delete
        List<reduivy__Transaction_Line_Item__c> mixedEntries = new List<reduivy__Transaction_Line_Item__c>();
        
        // 1. Monetary Entry (qualified) - will be deleted
        reduivy__Transaction_Line_Item__c monetaryEntry1 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLines[0].Id, // first parent
            null, // idvFundingAllocationId
            'Test Payment 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            30.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        mixedEntries.add(monetaryEntry1);
        
        // 2. Monetary Entry (qualified) - will remain
        reduivy__Transaction_Line_Item__c monetaryEntry2 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLines[0].Id, // first parent
            null, // idvFundingAllocationId
            'Test Payment 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            20.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        mixedEntries.add(monetaryEntry2);
        
        // 3. Discount Entry (qualified) - will be deleted
        reduivy__Transaction_Line_Item__c discountEntry1 = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            15.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        discountEntry1.reduivy__Offset_Line_Item__c = parentOrderLines[1].Id; // second parent
        mixedEntries.add(discountEntry1);
        
        // 4. Discount Entry (qualified) - will remain
        reduivy__Transaction_Line_Item__c discountEntry2 = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            10.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        discountEntry2.reduivy__Offset_Line_Item__c = parentOrderLines[1].Id; // second parent
        mixedEntries.add(discountEntry2);
        
        // 5. Order Line (non-qualified) - will be deleted but should not affect rollup
        reduivy__Transaction_Line_Item__c orderLineEntry = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Another Order Line',
            TRL_Helper.ITEM_TYPE_TUITION,
            25.00, // totalAmount
            0.00,  // offsetAmount
            25.00  // outstandingAmount
        );
        orderLineEntry.reduivy__Offset_Line_Item__c = parentOrderLines[0].Id; // first parent
        mixedEntries.add(orderLineEntry);
        
        // 6. Monetary Entry without parent - will be deleted but should not affect rollup
        reduivy__Transaction_Line_Item__c monetaryWithoutParent = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            null, // NO PARENT
            null, // idvFundingAllocationId
            'Test Payment 3',
            TRL_Helper.ITEM_TYPE_TUITION,
            35.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        mixedEntries.add(monetaryWithoutParent);
        
        System.runAs(studentUser) {
            insert mixedEntries;
        }

        // Get parent values after initial insert
        List<reduivy__Transaction_Line_Item__c> parentsAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                                    FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id IN :parentOrderLines
                                                                    ORDER BY reduivy__Item_Name__c];
        
        Map<Id, reduivy__Transaction_Line_Item__c> parentMapAfterInsert = new Map<Id, reduivy__Transaction_Line_Item__c>(parentsAfterInsert);

        // Prepare entries to delete (will delete some qualified and some non-qualified)
        List<reduivy__Transaction_Line_Item__c> entriesToDelete = new List<reduivy__Transaction_Line_Item__c>{
            monetaryEntry1,      // Qualified - affects parent 1
            discountEntry1,      // Qualified - affects parent 2
            orderLineEntry,      // Non-qualified - should not affect rollup
            monetaryWithoutParent // Qualified but no parent - should not affect rollup
        };

        System.runAs(studentUser) {
            Test.startTest();
            
            // Bulk delete mixed entries
            delete entriesToDelete;
            
            Test.stopTest();
        }

        // Get parent values after delete
        List<reduivy__Transaction_Line_Item__c> parentsAfterDelete = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                                    FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id IN :parentOrderLines
                                                                    ORDER BY reduivy__Item_Name__c];
        
        Map<Id, reduivy__Transaction_Line_Item__c> parentMapAfterDelete = new Map<Id, reduivy__Transaction_Line_Item__c>(parentsAfterDelete);

        // Assertions
        // Parent 1 should have had 50.00 (30+20) offset amount, after delete should have 20.00
        System.Assert.areEqual(50.00, parentMapAfterInsert.get(parentOrderLines[0].Id).reduivy__Offset_Amount__c ?? 0, 
                        'Parent 1 should have 50.00 offset amount after initial insert');
        System.Assert.areEqual(20.00, parentMapAfterDelete.get(parentOrderLines[0].Id).reduivy__Offset_Amount__c ?? 0, 
                        'Parent 1 should have 20.00 offset amount after deleting 30.00 monetary entry');
        
        // Parent 2 should have had 25.00 (15+10) discount, after delete should have 10.00
        System.Assert.areEqual(25.00, parentMapAfterInsert.get(parentOrderLines[1].Id).reduivy__Discount__c ?? 0, 
                        'Parent 2 should have 25.00 discount after initial insert');
        System.Assert.areEqual(10.00, parentMapAfterDelete.get(parentOrderLines[1].Id).reduivy__Discount__c ?? 0, 
                        'Parent 2 should have 10.00 discount after deleting 15.00 discount entry');
        
        // Verify the records were actually deleted
        List<reduivy__Transaction_Line_Item__c> remainingDeletedEntries = [SELECT Id FROM reduivy__Transaction_Line_Item__c 
                                                                        WHERE Id IN :entriesToDelete];
        System.Assert.areEqual(0, remainingDeletedEntries.size(), 'All deleted entries should not exist');
        
        // Verify remaining entries still exist
        List<reduivy__Transaction_Line_Item__c> remainingEntries = [SELECT Id FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id = :monetaryEntry2.Id OR Id = :discountEntry2.Id];
        System.Assert.areEqual(2, remainingEntries.size(), 'Remaining entries should still exist');
    }

    // ========== AFTER UNDELETE TESTS ==========

    /**
     * @description Test undelete monetary entry with valid parent - as Student
     */
    @IsTest
    static void testAfterUndelete_MonetaryEntry_WithParentAsStudent() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});
        
        Contact studentContact = [
            SELECT Id, reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        System.runAs(studentUser) {
            
            // Create necessary parent records
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // academicProgressId
                Date.today(),
                TRO_Helper.STATUS_TYPE_SUBMITTED,
                100.00, // totalAmount
                100.00, // outstandingAmount
                0.00    // paidAmount
            );
            insert transactionOrder;

            // Create parent order line
            reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
                studentContact.reduivy__Sample_Record_Code__c,
                transactionOrder.Id,
                null, // studyFeeMatrixItemId
                'Test Fee Item',
                TRL_Helper.ITEM_TYPE_TUITION,
                100.00, // totalAmount
                0.00,   // offsetAmount
                100.00  // outstandingAmount
            );
            insert parentOrderLine;

            // Create monetary entry as child of the order line
            reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
                studentContact.reduivy__Sample_Record_Code__c,
                transactionOrder.Id,
                null, // transactionPaymentId
                parentOrderLine.Id, // offsetLineItemId
                null, // idvFundingAllocationId
                'Test Payment',
                TRL_Helper.ITEM_TYPE_TUITION,
                25.00, // totalAmount
                0.00,  // offsetAmount
                0.00   // outstandingAmount
            );
            insert monetaryEntry;

            // Get parent's offset amount before delete
            reduivy__Transaction_Line_Item__c parentBefore = [
                SELECT reduivy__Offset_Amount__c 
                FROM reduivy__Transaction_Line_Item__c 
                WHERE Id = :parentOrderLine.Id
            ];
            Decimal offsetBefore = parentBefore.reduivy__Offset_Amount__c;

            // Delete the monetary entry
            delete monetaryEntry;

            // Verify parent's offset amount was reduced
            reduivy__Transaction_Line_Item__c parentAfterDelete = [
                SELECT reduivy__Offset_Amount__c 
                FROM reduivy__Transaction_Line_Item__c 
                WHERE Id = :parentOrderLine.Id
            ];

            Test.startTest();
            
            // Undelete the monetary entry
            undelete monetaryEntry;
            
            Test.stopTest();

            // Verify parent's Offset_Amount__c is restored
            reduivy__Transaction_Line_Item__c parentAfterUndelete = [
                SELECT reduivy__Offset_Amount__c 
                FROM reduivy__Transaction_Line_Item__c 
                WHERE Id = :parentOrderLine.Id
            ];
            
            System.assertEquals(offsetBefore, parentAfterUndelete.reduivy__Offset_Amount__c, 
                'Parent offset amount should be restored after undelete');
            System.assertEquals(25.00, parentAfterUndelete.reduivy__Offset_Amount__c, 
                'Parent offset amount should equal monetary entry amount');
        }
    }

    /**
     * @description Test undelete discount entry with valid parent - as Student
     */
    @IsTest
    static void testAfterUndelete_DiscountEntry_WithParentAsStudent() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});
        
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
        
        System.runAs(studentUser) {
            
            // Create necessary parent records
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // academicProgressId
                Date.today(),
                TRO_Helper.STATUS_TYPE_SUBMITTED,
                100.00, // totalAmount
                100.00, // outstandingAmount
                0.00    // paidAmount
            );
            insert transactionOrder;

            // Create parent order line
            reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
                studentContact.reduivy__Sample_Record_Code__c,
                transactionOrder.Id,
                null, // studyFeeMatrixItemId
                'Test Fee Item',
                TRL_Helper.ITEM_TYPE_TUITION,
                100.00, // totalAmount
                0.00,   // offsetAmount
                100.00  // outstandingAmount
            );
            insert parentOrderLine;

            // Create discount entry as child of the order line
            reduivy__Transaction_Line_Item__c discountEntry = REDU_TestData_UTIL.newTransactionDiscountEntry(
                studentContact.reduivy__Sample_Record_Code__c,
                transactionOrder.Id,
                'Test Discount',
                TRL_Helper.ITEM_TYPE_TUITION,
                25.00, // totalAmount
                null,  // idvFundingAllocationId
                null,  // studyVoucherTransactionId
                null,  // studyFeeMatrixItemId
                null   // individualEnrollmentId
            );
            // Set the parent relationship for discount entry
            discountEntry.reduivy__Offset_Line_Item__c = parentOrderLine.Id;
            insert discountEntry;

            // Get the parent's discount amount before delete
            reduivy__Transaction_Line_Item__c parentBefore = [SELECT reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
            Decimal discountBefore = parentBefore.reduivy__Discount__c;

            // Delete the discount entry
            delete discountEntry;

            // Verify parent's discount amount was reduced
            reduivy__Transaction_Line_Item__c parentAfterDelete = [SELECT reduivy__Discount__c 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE Id = :parentOrderLine.Id];
            
            Test.startTest();
            
            // Undelete the discount entry
            undelete discountEntry;
            
            Test.stopTest();

            // Verify parent's Discount__c is increased back
            reduivy__Transaction_Line_Item__c parentAfterUndelete = [SELECT reduivy__Discount__c 
                                                                    FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id = :parentOrderLine.Id];
            
            System.assertEquals(discountBefore, parentAfterUndelete.reduivy__Discount__c, 
                            'Parent discount amount should be restored after undelete');
            System.assertEquals(25.00, parentAfterUndelete.reduivy__Discount__c, 
                            'Parent discount amount should equal discount entry amount');
        }
    }

    //Faculty
    // ========== AFTER INSERT TESTS ==========

    /**
     * @description Test monetary and discount entry insert with parent as faculty - should update parent's reduivy__Offset_Amount__c and reduivy__Discount_Amount__c
     */
    @IsTest
    static void testAfterInsert_MonetaryAndDiscountEntry_WithParentAsFaculty() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount - should be updated by rollup
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Get initial values before monetary entry insert
        reduivy__Transaction_Line_Item__c parentBefore = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                        FROM reduivy__Transaction_Line_Item__c 
                                                        WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountBefore = parentBefore.reduivy__Offset_Amount__c ?? 0;
        Decimal discountBefore = parentBefore.reduivy__Discount__c ?? 0;
        
        // Create discount entry as child of the order line
        reduivy__Transaction_Line_Item__c discountEntry = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount',
            TRL_Helper.ITEM_TYPE_TUITION,
            25.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        // Set the parent relationship manually since helper method doesn't include it
        discountEntry.reduivy__Offset_Line_Item__c = parentOrderLine.Id;

        // Create monetary entry as child of the order line
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId - this makes it a child
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            50.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            insert discountEntry;
            insert monetaryEntry;
            
            Test.stopTest();
        }

        // Verify parent's Offset_Amount__c is updated correctly
        reduivy__Transaction_Line_Item__c parentAfter = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                        FROM reduivy__Transaction_Line_Item__c 
                                                        WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfter = parentAfter.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfter = parentAfter.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.isTrue(offsetAmountBefore != offsetAmountAfter, 'Parent offset amount should have changed');
        System.Assert.areEqual(0.00, offsetAmountBefore, 'Parent offset amount should initially be 0');
        System.Assert.areEqual(50.00, offsetAmountAfter, 'Parent offset amount should be updated to 50.00 after monetary entry insert');

        System.Assert.isTrue(discountBefore != discountAfter, 'Parent offset amount should have changed');
        System.Assert.areEqual(0.00, discountBefore, 'Parent offset amount should initially be 0');
        System.Assert.areEqual(25.00, discountAfter, 'Parent discount should be updated to 25.00 after discount entry insert');
    }

    /**
     * @description Test Non Transactional Entry insert - should not trigger rollup
     */
    @IsTest
    static void testAfterInsert_NonTransactionalType_WithParentAsFaculty() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Get initial values
        reduivy__Transaction_Line_Item__c parentBefore = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                        FROM reduivy__Transaction_Line_Item__c 
                                                        WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountBefore = parentBefore.reduivy__Offset_Amount__c ?? 0;
        Decimal discountBefore = parentBefore.reduivy__Discount__c ?? 0;

        // Create another Non Transactional Entry line with parent relationship
        reduivy__Transaction_Line_Item__c nonTransactionalEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            50.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );

        // Set parent relationship to test non-qualified rollup
        nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY;

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            insert nonTransactionalEntry;
            
            Test.stopTest();
        }

        // Verify no rollup occurs (needRollup returns false for non-qualified types)
        reduivy__Transaction_Line_Item__c parentAfter = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                        FROM reduivy__Transaction_Line_Item__c 
                                                        WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfter = parentAfter.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfter = parentAfter.reduivy__Discount__c ?? 0;

        // Assertions - values should remain unchanged
        System.Assert.areEqual(offsetAmountBefore, offsetAmountAfter, 'Parent offset amount should remain unchanged for non-qualified types');
        System.Assert.areEqual(discountBefore, discountAfter, 'Parent discount should remain unchanged for non-qualified types');
    }

    /**
     * @description Test insert without parent - should not trigger rollup
     */
    @IsTest
    static void testAfterInsert_WithoutParentAsFaculty() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE', 'TRO_UpdateStatus_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create monetary entry WITHOUT parent (Offset_Line_Item__c is null)
        reduivy__Transaction_Line_Item__c monetaryEntryWithoutParent = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment Without Parent',
            TRL_Helper.ITEM_TYPE_TUITION,
            50.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // This should not trigger any rollup since there's no parent
            insert monetaryEntryWithoutParent;
            
            Test.stopTest();
        }

        // Verify the record was created successfully (no exceptions thrown)
        reduivy__Transaction_Line_Item__c insertedRecord = [SELECT Id, reduivy__Offset_Line_Item__c, reduivy__Transaction_Type__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :monetaryEntryWithoutParent.Id];
        
        // Assertions
        System.assertNotEquals(null, insertedRecord.Id, 'Record should be inserted successfully');
        System.Assert.areEqual(null, insertedRecord.reduivy__Offset_Line_Item__c, 'Record should have no parent');
        System.Assert.areEqual(TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY, insertedRecord.reduivy__Transaction_Type__c, 'Record should be monetary entry type');
    }

    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test updating Total_Amount__c on monetary entry - should recalculate parent's Offset_Amount__c
     */
    @IsTest
    static void testAfterUpdate_AmountChanged_MonetaryEntryAsFaculty() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create monetary entry as child of the order line
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            30.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;

        // Get parent values after initial insert
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Update the monetary entry amount
            monetaryEntry.reduivy__Unit_Price__c = 50.00; // Changed from 30.00 to 50.00
            update monetaryEntry;
            
            Test.stopTest();
        }

        // Get parent values after update
        reduivy__Transaction_Line_Item__c parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(30.00, offsetAmountAfterInsert, 'Parent offset amount should be 30.00 after initial insert');
        System.Assert.areEqual(50.00, offsetAmountAfterUpdate, 'Parent offset amount should be updated to 50.00 after amount change');
        System.Assert.areEqual(discountAfterInsert, discountAfterUpdate, 'Parent discount should remain unchanged');
    }

    /**
     * @description Test updating Total_Amount__c on discount entry - should recalculate parent's Discount__c
     */
    @IsTest
    static void testAfterUpdate_AmountChanged_DiscountEntryAsFaculty() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create discount entry as child of the order line
        reduivy__Transaction_Line_Item__c discountEntry = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount',
            TRL_Helper.ITEM_TYPE_TUITION,
            20.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        discountEntry.reduivy__Offset_Line_Item__c = parentOrderLine.Id;
        insert discountEntry;

        // Get parent values after initial insert
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Update the discount entry amount
            discountEntry.reduivy__Unit_Price__c = 35.00; // Changed from 20.00 to 35.00
            update discountEntry;
            
            Test.stopTest();
        }

        // Get parent values after update
        reduivy__Transaction_Line_Item__c parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(20.00, discountAfterInsert, 'Parent discount should be 20.00 after initial insert');
        System.Assert.areEqual(35.00, discountAfterUpdate, 'Parent discount should be updated to 35.00 after amount change');
        System.Assert.areEqual(offsetAmountAfterInsert, offsetAmountAfterUpdate, 'Parent offset amount should remain unchanged');
    }

    /**
     * @description Test changing transaction type - should trigger rollup
     */
    @IsTest
    static void testAfterUpdate_TransactionTypeChanged_AsFaculty() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE', 'TRO_UpdateStatus_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create a non-qualified entry (Non Transactional Entry) with parent
        reduivy__Transaction_Line_Item__c nonTransactionalEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            40.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );

        nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY;

        insert nonTransactionalEntry;

        // Get parent values after initial insert (should be unchanged since non-qualified)
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Change transaction type to qualified type (MONETARYENTRY)
            nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY;
            nonTransactionalEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            update nonTransactionalEntry;
        }

        // Get parent values after update
        reduivy__Transaction_Line_Item__c parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(0.00, offsetAmountAfterInsert, 'Parent offset amount should remain 0 after non-qualified insert');
        System.Assert.areEqual(40.00, offsetAmountAfterUpdate, 'Parent offset amount should be updated to 40.00 after changing to qualified type');
        System.Assert.areEqual(discountAfterInsert, discountAfterUpdate, 'Parent discount should remain unchanged');

        System.runAs(FACULTY_USER) {

            // Change transaction type to non qualified type (NONTRANSACTIONALENTRY)
            nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY;
            update nonTransactionalEntry;
        }

        parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(0.00, offsetAmountAfterUpdate, 'Parent offset amount should be updated to 0 after changing to non qualified type');
        System.Assert.areEqual(discountAfterInsert, discountAfterUpdate, 'Parent discount should remain unchanged');

        System.runAs(FACULTY_USER) {
            
            // Change transaction type to qualified type (MONETARYENTRY)
            nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY;
            update nonTransactionalEntry;
        }

        // Get parent values after update
        parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(0.00, offsetAmountAfterInsert, 'Parent offset amount should remain 0 after non-qualified insert');
        System.Assert.areEqual(40.00, offsetAmountAfterUpdate, 'Parent offset amount should be updated to 40.00 after changing to qualified type');
        System.Assert.areEqual(discountAfterInsert, discountAfterUpdate, 'Parent discount should remain unchanged');

        System.runAs(FACULTY_USER) {
            
            // Change transaction type to qualified type (MONETARYENTRY)
            nonTransactionalEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            nonTransactionalEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_DEBIT;
            update nonTransactionalEntry;
        }

        // Get parent values after update
        parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(0.00, offsetAmountAfterUpdate, 'Parent offset amount should be updated to 0.00 after changing to discount type');
        System.Assert.areEqual(40.00, discountAfterUpdate, 'Parent discount amount should be updated to 40.00 after changing to discount type');
    }

    /**
     * @description Test updating parent field (reduivy__Offset_Line_Item__c) - should trigger rollup
     */
    @IsTest
    static void testAfterUpdate_OffsetLineItemParentChangesAsFaculty() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact studentContact = [
            SELECT Id, reduivy__Sample_Record_Code__c
            FROM Contact
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create Transaction Order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null,
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            200.00, // totalAmount
            200.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create two parent offset line items
        reduivy__Transaction_Line_Item__c parentOrderLine1 = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null,
            'Test Fee Item 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00,
            0.00,
            100.00
        );
        reduivy__Transaction_Line_Item__c parentOrderLine2 = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null,
            'Test Fee Item 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00,
            0.00,
            100.00
        );
        insert new List<reduivy__Transaction_Line_Item__c>{parentOrderLine1, parentOrderLine2};

        // Create monetary entry WITH first parent (for scenario 1 and 3)
        reduivy__Transaction_Line_Item__c entryWithParent = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null,
            parentOrderLine1.Id,
            null,
            'Payment with Parent',
            TRL_Helper.ITEM_TYPE_TUITION,
            75.00,
            0.00,
            0.00
        );

        // Create monetary entry WITHOUT parent (for scenario 2)
        reduivy__Transaction_Line_Item__c entryNoParent = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null,
            null,
            null,
            'Payment without Parent',
            TRL_Helper.ITEM_TYPE_TUITION,
            66.00,
            0.00,
            0.00
        );
        insert new List<reduivy__Transaction_Line_Item__c>{entryWithParent, entryNoParent};

        System.runAs(FACULTY_USER) {
            Test.startTest();

            // ---------------- Scenario 1: Change from valid parent → different valid parent ----------------
            entryWithParent.reduivy__Offset_Line_Item__c = parentOrderLine2.Id;
            update entryWithParent;
        }

        // Fetch final parent values
        Map<Id, reduivy__Transaction_Line_Item__c> parentsFinal = new Map<Id, reduivy__Transaction_Line_Item__c>(
            [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c
            FROM reduivy__Transaction_Line_Item__c
            WHERE Id IN (:parentOrderLine1.Id, :parentOrderLine2.Id)]
        );

        // Assertions for Scenario 1: first → second
        System.assertEquals(0.00, parentsFinal.get(parentOrderLine1.Id).reduivy__Offset_Amount__c, 
            'After moving child from parent1 to parent2, parent1 should be 0.00');

        System.assertEquals(75.00, parentsFinal.get(parentOrderLine2.Id).reduivy__Offset_Amount__c, 
            'After moving child to parent2, parent2 should have 75.00');

        System.runAs(FACULTY_USER) {
            // ---------------- Scenario 2: Change from blank parent → valid parent ----------------
            entryNoParent.reduivy__Offset_Line_Item__c = parentOrderLine1.Id;
            update entryNoParent;
        }

        parentsFinal = new Map<Id, reduivy__Transaction_Line_Item__c>(
            [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c
            FROM reduivy__Transaction_Line_Item__c
            WHERE Id IN (:parentOrderLine1.Id, :parentOrderLine2.Id)]
        );

        // Assertions for Scenario 2: blank → valid
        System.assertEquals(66.00, parentsFinal.get(parentOrderLine1.Id).reduivy__Offset_Amount__c,
            'After assigning a child to parent1, it should have 66.00');

        System.assertEquals(75.00, parentsFinal.get(parentOrderLine2.Id).reduivy__Offset_Amount__c,
            'Parent2 should remain unchanged at 75.00');

        System.runAs(FACULTY_USER) {
            // ---------------- Scenario 3: Change from valid parent → blank parent ----------------
            entryWithParent.reduivy__Offset_Line_Item__c = null;
            update entryWithParent;

            Test.stopTest();
        }

        parentsFinal = new Map<Id, reduivy__Transaction_Line_Item__c>(
            [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c
            FROM reduivy__Transaction_Line_Item__c
            WHERE Id IN (:parentOrderLine1.Id, :parentOrderLine2.Id)]
        );

        // Assertions for Scenario 3: valid → blank
        System.assertEquals(66.00, parentsFinal.get(parentOrderLine1.Id).reduivy__Offset_Amount__c,
            'Parent1 should still have 66.00 from previous assignment');
        System.assertEquals(0.00, parentsFinal.get(parentOrderLine2.Id).reduivy__Offset_Amount__c,
            'Parent2 should be 0.00 after child removal');
    }

    /**
     * @description Test updating non-rollup fields - should not trigger rollup
     */
    @IsTest
    static void testAfterUpdate_NoRelevantChangesAsFaculty() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create monetary entry
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            80.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;

        // Get parent values after initial insert
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Update non-rollup fields (Item Name) - should not trigger rollup
            monetaryEntry.reduivy__Item_Name__c = 'Updated Payment Name';
            update monetaryEntry;
            
            Test.stopTest();
        }

        // Get parent values after update
        reduivy__Transaction_Line_Item__c parentAfterUpdate = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterUpdate = parentAfterUpdate.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterUpdate = parentAfterUpdate.reduivy__Discount__c ?? 0;

        // Assertions - values should remain unchanged since no relevant fields were updated
        System.Assert.areEqual(80.00, offsetAmountAfterInsert, 'Parent offset amount should be 80.00 after initial insert');
        System.Assert.areEqual(offsetAmountAfterInsert, offsetAmountAfterUpdate, 'Parent offset amount should remain unchanged after non-relevant field update');
        System.Assert.areEqual(discountAfterInsert, discountAfterUpdate, 'Parent discount should remain unchanged after non-relevant field update');
        
        // Verify the non-rollup field was actually updated
        reduivy__Transaction_Line_Item__c updatedMonetaryEntry = [SELECT Id, reduivy__Item_Name__c 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE Id = :monetaryEntry.Id];
        System.Assert.areEqual('Updated Payment Name', updatedMonetaryEntry.reduivy__Item_Name__c, 'Item name should be updated');
    }

    // ========== AFTER DELETE TESTS ==========
    
    /**
     * @description Test deleting monetary entry with parent - should decrease parent's Offset_Amount__c
     */
    @IsTest
    static void testAfterDelete_MonetaryEntry_WithParentAsFaculty() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create multiple monetary entries to test partial deletion
        List<reduivy__Transaction_Line_Item__c> monetaryEntries = new List<reduivy__Transaction_Line_Item__c>();
        
        reduivy__Transaction_Line_Item__c monetaryEntry1 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            30.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        monetaryEntries.add(monetaryEntry1);
        
        reduivy__Transaction_Line_Item__c monetaryEntry2 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            20.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        monetaryEntries.add(monetaryEntry2);
        
        System.runAs(FACULTY_USER) {
            insert monetaryEntries;
        }

        // Get parent values after initial insert
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Delete one monetary entry
            delete monetaryEntry1;
            
            Test.stopTest();
        }

        // Get parent values after delete
        reduivy__Transaction_Line_Item__c parentAfterDelete = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterDelete = parentAfterDelete.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterDelete = parentAfterDelete.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(50.00, offsetAmountAfterInsert, 'Parent offset amount should be 50.00 after both inserts (30+20)');
        System.Assert.areEqual(20.00, offsetAmountAfterDelete, 'Parent offset amount should be 20.00 after deleting 30.00 entry');
        System.Assert.areEqual(discountAfterInsert, discountAfterDelete, 'Parent discount should remain unchanged');
        
        // Verify the record was actually deleted
        List<reduivy__Transaction_Line_Item__c> remainingEntries = [SELECT Id FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id = :monetaryEntry1.Id];
        System.Assert.areEqual(0, remainingEntries.size(), 'Deleted monetary entry should not exist');
    }

    /**
     * @description Test deleting discount entry with parent - should decrease parent's Discount__c
     */
    @IsTest
    static void testAfterDelete_DiscountEntry_WithParentAsFaculty() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount
            100.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create parent offset line item (order line)
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert parentOrderLine;

        // Create multiple discount entries to test partial deletion
        List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
        
        reduivy__Transaction_Line_Item__c discountEntry1 = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            15.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        discountEntry1.reduivy__Offset_Line_Item__c = parentOrderLine.Id;
        discountEntries.add(discountEntry1);
        
        reduivy__Transaction_Line_Item__c discountEntry2 = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            10.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        discountEntry2.reduivy__Offset_Line_Item__c = parentOrderLine.Id;
        discountEntries.add(discountEntry2);
        
        System.runAs(FACULTY_USER) {
            insert discountEntries;
        }

        // Get parent values after initial insert
        reduivy__Transaction_Line_Item__c parentAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterInsert = parentAfterInsert.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterInsert = parentAfterInsert.reduivy__Discount__c ?? 0;

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Delete one discount entry
            delete discountEntry1;
            
            Test.stopTest();
        }

        // Get parent values after delete
        reduivy__Transaction_Line_Item__c parentAfterDelete = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
        
        Decimal offsetAmountAfterDelete = parentAfterDelete.reduivy__Offset_Amount__c ?? 0;
        Decimal discountAfterDelete = parentAfterDelete.reduivy__Discount__c ?? 0;

        // Assertions
        System.Assert.areEqual(25.00, discountAfterInsert, 'Parent discount should be 25.00 after both inserts (15+10)');
        System.Assert.areEqual(10.00, discountAfterDelete, 'Parent discount should be 10.00 after deleting 15.00 entry');
        System.Assert.areEqual(offsetAmountAfterInsert, offsetAmountAfterDelete, 'Parent offset amount should remain unchanged');
        
        // Verify the record was actually deleted
        List<reduivy__Transaction_Line_Item__c> remainingEntries = [SELECT Id FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id = :discountEntry1.Id];
        System.Assert.areEqual(0, remainingEntries.size(), 'Deleted discount entry should not exist');
    }

    /**
     * @description Test bulk delete of mixed qualified types - should update parent totals correctly
     */
    @IsTest
    static void testAfterDelete_BulkDeleteAsFaculty() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE', 'TRO_UpdateStatus_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        // Create necessary parent records
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            200.00, // totalAmount
            200.00, // outstandingAmount
            0.00    // paidAmount
        );
        insert transactionOrder;

        // Create multiple parent offset line items
        List<reduivy__Transaction_Line_Item__c> parentOrderLines = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= 2; i++) {
            reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
                studentContact.reduivy__Sample_Record_Code__c,
                transactionOrder.Id,
                null, // studyFeeMatrixItemId
                'Test Fee Item ' + i,
                TRL_Helper.ITEM_TYPE_TUITION,
                100.00, // totalAmount
                0.00,   // offsetAmount
                100.00  // outstandingAmount
            );
            parentOrderLines.add(parentOrderLine);
        }
        insert parentOrderLines;

        // Create mixed transaction line items for bulk delete
        List<reduivy__Transaction_Line_Item__c> mixedEntries = new List<reduivy__Transaction_Line_Item__c>();
        
        // 1. Monetary Entry (qualified) - will be deleted
        reduivy__Transaction_Line_Item__c monetaryEntry1 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLines[0].Id, // first parent
            null, // idvFundingAllocationId
            'Test Payment 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            30.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        mixedEntries.add(monetaryEntry1);
        
        // 2. Monetary Entry (qualified) - will remain
        reduivy__Transaction_Line_Item__c monetaryEntry2 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            parentOrderLines[0].Id, // first parent
            null, // idvFundingAllocationId
            'Test Payment 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            20.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        mixedEntries.add(monetaryEntry2);
        
        // 3. Discount Entry (qualified) - will be deleted
        reduivy__Transaction_Line_Item__c discountEntry1 = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            15.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        discountEntry1.reduivy__Offset_Line_Item__c = parentOrderLines[1].Id; // second parent
        mixedEntries.add(discountEntry1);
        
        // 4. Discount Entry (qualified) - will remain
        reduivy__Transaction_Line_Item__c discountEntry2 = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            10.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        discountEntry2.reduivy__Offset_Line_Item__c = parentOrderLines[1].Id; // second parent
        mixedEntries.add(discountEntry2);
        
        // 5. Order Line (non-qualified) - will be deleted but should not affect rollup
        reduivy__Transaction_Line_Item__c orderLineEntry = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Another Order Line',
            TRL_Helper.ITEM_TYPE_TUITION,
            25.00, // totalAmount
            0.00,  // offsetAmount
            25.00  // outstandingAmount
        );
        orderLineEntry.reduivy__Offset_Line_Item__c = parentOrderLines[0].Id; // first parent
        mixedEntries.add(orderLineEntry);
        
        // 6. Monetary Entry without parent - will be deleted but should not affect rollup
        reduivy__Transaction_Line_Item__c monetaryWithoutParent = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            null, // NO PARENT
            null, // idvFundingAllocationId
            'Test Payment 3',
            TRL_Helper.ITEM_TYPE_TUITION,
            35.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        mixedEntries.add(monetaryWithoutParent);
        
        System.runAs(FACULTY_USER) {
            insert mixedEntries;
        }

        // Get parent values after initial insert
        List<reduivy__Transaction_Line_Item__c> parentsAfterInsert = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                                    FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id IN :parentOrderLines
                                                                    ORDER BY reduivy__Item_Name__c];
        
        Map<Id, reduivy__Transaction_Line_Item__c> parentMapAfterInsert = new Map<Id, reduivy__Transaction_Line_Item__c>(parentsAfterInsert);

        // Prepare entries to delete (will delete some qualified and some non-qualified)
        List<reduivy__Transaction_Line_Item__c> entriesToDelete = new List<reduivy__Transaction_Line_Item__c>{
            monetaryEntry1,      // Qualified - affects parent 1
            discountEntry1,      // Qualified - affects parent 2
            orderLineEntry,      // Non-qualified - should not affect rollup
            monetaryWithoutParent // Qualified but no parent - should not affect rollup
        };

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Bulk delete mixed entries
            delete entriesToDelete;
            
            Test.stopTest();
        }

        // Get parent values after delete
        List<reduivy__Transaction_Line_Item__c> parentsAfterDelete = [SELECT Id, reduivy__Offset_Amount__c, reduivy__Discount__c 
                                                                    FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id IN :parentOrderLines
                                                                    ORDER BY reduivy__Item_Name__c];
        
        Map<Id, reduivy__Transaction_Line_Item__c> parentMapAfterDelete = new Map<Id, reduivy__Transaction_Line_Item__c>(parentsAfterDelete);

        // Assertions
        // Parent 1 should have had 50.00 (30+20) offset amount, after delete should have 20.00
        System.Assert.areEqual(50.00, parentMapAfterInsert.get(parentOrderLines[0].Id).reduivy__Offset_Amount__c ?? 0, 
                        'Parent 1 should have 50.00 offset amount after initial insert');
        System.Assert.areEqual(20.00, parentMapAfterDelete.get(parentOrderLines[0].Id).reduivy__Offset_Amount__c ?? 0, 
                        'Parent 1 should have 20.00 offset amount after deleting 30.00 monetary entry');
        
        // Parent 2 should have had 25.00 (15+10) discount, after delete should have 10.00
        System.Assert.areEqual(25.00, parentMapAfterInsert.get(parentOrderLines[1].Id).reduivy__Discount__c ?? 0, 
                        'Parent 2 should have 25.00 discount after initial insert');
        System.Assert.areEqual(10.00, parentMapAfterDelete.get(parentOrderLines[1].Id).reduivy__Discount__c ?? 0, 
                        'Parent 2 should have 10.00 discount after deleting 15.00 discount entry');
        
        // Verify the records were actually deleted
        List<reduivy__Transaction_Line_Item__c> remainingDeletedEntries = [SELECT Id FROM reduivy__Transaction_Line_Item__c 
                                                                        WHERE Id IN :entriesToDelete];
        System.Assert.areEqual(0, remainingDeletedEntries.size(), 'All deleted entries should not exist');
        
        // Verify remaining entries still exist
        List<reduivy__Transaction_Line_Item__c> remainingEntries = [SELECT Id FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id = :monetaryEntry2.Id OR Id = :discountEntry2.Id];
        System.Assert.areEqual(2, remainingEntries.size(), 'Remaining entries should still exist');
    }

    // ========== AFTER UNDELETE TESTS ==========

    /**
     * @description Test undelete monetary entry with valid parent - as Faculty
     */
    @IsTest
    static void testAfterUndelete_MonetaryEntry_WithParentAsFaculty() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});

        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [
            SELECT Id, reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        System.runAs(FACULTY_USER) {
            
            // Create necessary parent records
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // academicProgressId
                Date.today(),
                TRO_Helper.STATUS_TYPE_SUBMITTED,
                100.00, // totalAmount
                100.00, // outstandingAmount
                0.00    // paidAmount
            );
            insert transactionOrder;

            // Create parent order line
            reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
                studentContact.reduivy__Sample_Record_Code__c,
                transactionOrder.Id,
                null, // studyFeeMatrixItemId
                'Test Fee Item',
                TRL_Helper.ITEM_TYPE_TUITION,
                100.00, // totalAmount
                0.00,   // offsetAmount
                100.00  // outstandingAmount
            );
            insert parentOrderLine;

            // Create monetary entry as child of the order line
            reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
                studentContact.reduivy__Sample_Record_Code__c,
                transactionOrder.Id,
                null, // transactionPaymentId
                parentOrderLine.Id, // offsetLineItemId
                null, // idvFundingAllocationId
                'Test Payment',
                TRL_Helper.ITEM_TYPE_TUITION,
                25.00, // totalAmount
                0.00,  // offsetAmount
                0.00   // outstandingAmount
            );
            insert monetaryEntry;

            // Get parent's offset amount before delete
            reduivy__Transaction_Line_Item__c parentBefore = [
                SELECT reduivy__Offset_Amount__c 
                FROM reduivy__Transaction_Line_Item__c 
                WHERE Id = :parentOrderLine.Id
            ];
            Decimal offsetBefore = parentBefore.reduivy__Offset_Amount__c;

            // Delete the monetary entry
            delete monetaryEntry;

            // Verify parent's offset amount was reduced
            reduivy__Transaction_Line_Item__c parentAfterDelete = [
                SELECT reduivy__Offset_Amount__c 
                FROM reduivy__Transaction_Line_Item__c 
                WHERE Id = :parentOrderLine.Id
            ];

            Test.startTest();
            
            // Undelete the monetary entry
            undelete monetaryEntry;
            
            Test.stopTest();

            // Verify parent's Offset_Amount__c is restored
            reduivy__Transaction_Line_Item__c parentAfterUndelete = [
                SELECT reduivy__Offset_Amount__c 
                FROM reduivy__Transaction_Line_Item__c 
                WHERE Id = :parentOrderLine.Id
            ];
            
            System.assertEquals(offsetBefore, parentAfterUndelete.reduivy__Offset_Amount__c, 
                'Parent offset amount should be restored after undelete');
            System.assertEquals(25.00, parentAfterUndelete.reduivy__Offset_Amount__c, 
                'Parent offset amount should equal monetary entry amount');
        }
    }

    /**
     * @description Test undelete discount entry with valid parent - as Faculty
     */
    @IsTest
    static void testAfterUndelete_DiscountEntry_WithParentAsFaculty() {
        //Muting the trigger to prevent other rollup triggers from running and causing validation rules to fire, such as when the TRO total amount changes after a payment is applied.
        REDU_TriggerController.muteTriggers(new Set<String>{'TRL_TransactionOrderRollup_EXE', 'TRL_TransactionPaymentRollup_EXE', 'TRO_ContactRollup_EXE', 'TRP_ContactRollup_EXE', 'TRP_FundingAllocationRollup_EXE'});
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        System.runAs(FACULTY_USER) {
            
            // Create necessary parent records
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // academicProgressId
                Date.today(),
                TRO_Helper.STATUS_TYPE_SUBMITTED,
                100.00, // totalAmount
                100.00, // outstandingAmount
                0.00    // paidAmount
            );
            insert transactionOrder;

            // Create parent order line
            reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
                studentContact.reduivy__Sample_Record_Code__c,
                transactionOrder.Id,
                null, // studyFeeMatrixItemId
                'Test Fee Item',
                TRL_Helper.ITEM_TYPE_TUITION,
                100.00, // totalAmount
                0.00,   // offsetAmount
                100.00  // outstandingAmount
            );
            insert parentOrderLine;

            // Create discount entry as child of the order line
            reduivy__Transaction_Line_Item__c discountEntry = REDU_TestData_UTIL.newTransactionDiscountEntry(
                studentContact.reduivy__Sample_Record_Code__c,
                transactionOrder.Id,
                'Test Discount',
                TRL_Helper.ITEM_TYPE_TUITION,
                25.00, // totalAmount
                null,  // idvFundingAllocationId
                null,  // studyVoucherTransactionId
                null,  // studyFeeMatrixItemId
                null   // individualEnrollmentId
            );
            // Set the parent relationship for discount entry
            discountEntry.reduivy__Offset_Line_Item__c = parentOrderLine.Id;
            insert discountEntry;

            // Get the parent's discount amount before delete
            reduivy__Transaction_Line_Item__c parentBefore = [SELECT reduivy__Discount__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE Id = :parentOrderLine.Id];
            Decimal discountBefore = parentBefore.reduivy__Discount__c;

            // Delete the discount entry
            delete discountEntry;

            // Verify parent's discount amount was reduced
            reduivy__Transaction_Line_Item__c parentAfterDelete = [SELECT reduivy__Discount__c 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE Id = :parentOrderLine.Id];
            
            Test.startTest();
            
            // Undelete the discount entry
            undelete discountEntry;
            
            Test.stopTest();

            // Verify parent's Discount__c is increased back
            reduivy__Transaction_Line_Item__c parentAfterUndelete = [SELECT reduivy__Discount__c 
                                                                    FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE Id = :parentOrderLine.Id];
            
            System.assertEquals(discountBefore, parentAfterUndelete.reduivy__Discount__c, 
                            'Parent discount amount should be restored after undelete');
            System.assertEquals(25.00, parentAfterUndelete.reduivy__Discount__c, 
                            'Parent discount amount should equal discount entry amount');
        }
    }
}