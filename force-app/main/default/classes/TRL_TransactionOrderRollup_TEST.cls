/**
 * @author      WDCi (XiRouh)
 * @date        Aug 2025
 * @group       Test
 * @description Test class for TRL_TransactionOrderRollup_EXE
 * @changehistory
 * ISS-002587 13-08-2025 XiRouh - new class
 */
@IsTest
public inherited sharing class TRL_TransactionOrderRollup_TEST {

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
     * @description Test executeAfterInsert with Order Line as Admin (should roll up)
     */
    @IsTest
    static void testExecuteAfterInsertOrderLineAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount - should be updated by rollup
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line item
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Tuition Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            150.00, // totalAmount
            0.00,   // offsetAmount
            150.00  // outstandingAmount
        );

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            insert orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred - Total Amount should be updated to 150.00
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(150.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be rolled up from order line');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain 0 for order line');
    }

    /**
     * @description Test executeAfterInsert with Monetary Entry as Admin (should roll up)
     */
    @IsTest
    static void testExecuteAfterInsertMonetaryEntryAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount - should be updated by rollup
        );
        insert transactionOrder;

        // Create parent order line for offset reference
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            200.00, // totalAmount
            0.00,   // offsetAmount
            200.00  // outstandingAmount
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
            75.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            insert monetaryEntry;
            
            Test.stopTest();
        }

        // Verify rollup occurred - Total Paid Amount should be updated to 75.00
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(200.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should include order line amount');
        System.assertEquals(75.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should be rolled up from monetary entry');
    }

    /**
     * @description Test executeAfterInsert with non-qualified type as Admin (should skip)
     */
    @IsTest
    static void testExecuteAfterInsertNonQualifiedTypeAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create discount entry (non-qualified type for rollup)
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

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            insert discountEntry;
            
            Test.stopTest();
        }

        // Verify no rollup occurred - amounts should remain 0
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should not be updated for discount entry');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should not be updated for discount entry');
    }

    /**
     * @description Test executeAfterInsert with no parent as Admin (should skip)
     */
    @IsTest
    static void testExecuteAfterInsertNoParentAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create order line item without parent transaction order
        reduivy__Transaction_Line_Item__c orphanOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            null, // transactionOrderId - no parent
            null, // studyFeeMatrixItemId
            'Orphan Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            insert orphanOrderLine;
            
            Test.stopTest();
        }

        // Verify the record was created but no rollup processing occurred
        reduivy__Transaction_Line_Item__c createdItem = [
            SELECT Id, reduivy__Transaction_Order__c, reduivy__Total_Amount__c
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :orphanOrderLine.Id
        ];
        
        System.assertEquals(null, createdItem.reduivy__Transaction_Order__c, 
            'Transaction Line Item should have no parent order');
        System.assertEquals(100.00, createdItem.reduivy__Total_Amount__c, 
            'Transaction Line Item amount should be preserved');
        
        // No transaction orders should exist to verify rollup didn't happen
        Integer orderCount = [SELECT COUNT() FROM reduivy__Transaction_Order__c];
        System.assertEquals(0, orderCount, 
            'No transaction orders should exist when line item has no parent');
    }
	
    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test executeAfterUpdate from non-qualified to qualified type as Admin
     */
    @IsTest
    static void testExecuteAfterUpdateNonQualifiedToQualifiedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create discount entry (non-qualified type)
        reduivy__Transaction_Line_Item__c discountEntry = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount',
            TRL_Helper.ITEM_TYPE_TUITION,
            50.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        insert discountEntry;

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Change from discount entry to order line (qualified type)
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_DEBIT;
            update discountEntry;
            
            Test.stopTest();
        }

        // Verify rollup occurred - Total Amount should now include this item
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(50.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be rolled up after changing to qualified type');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain 0 for order line');
    }

    /**
     * @description Test executeAfterUpdate from qualified to non-qualified type as Admin
     */
    @IsTest
    static void testExecuteAfterUpdateQualifiedToNonQualifiedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line (qualified type)
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            75.00, // totalAmount
            0.00,  // offsetAmount
            75.00  // outstandingAmount
        );
        insert orderLine;

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Change from order line to discount entry (non-qualified type)
            orderLine.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            update orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred - Total Amount should be recalculated without this item
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be recalculated after changing to non-qualified type');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain 0');
    }

    /**
     * @description Test executeAfterUpdate from Order Line to Monetary Entry as Admin
     */
    @IsTest
    static void testExecuteAfterUpdateOrderLineToMonetaryEntryAsAdmin() {
        //Muting trigger to avoid triggering the You cannot update the amount because the Transaction Order Status is set to Confirmed validation rule
        REDU_TriggerController.muteTriggers(new Set<String>{'TRO_UpdateStatus_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            120.00, // totalAmount
            0.00,   // offsetAmount
            120.00  // outstandingAmount
        );
        insert orderLine;

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Change from order line to monetary entry
            orderLine.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY;
            orderLine.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            update orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred - amount should move from Total Amount to Total Paid Amount
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be 0 after changing from order line');
        System.assertEquals(120.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should include the amount after changing to monetary entry');
    }

    /**
     * @description Test executeAfterUpdate from Monetary Entry to Order Line as Admin
     */
    @IsTest
    static void testExecuteAfterUpdateMonetaryEntryToOrderLineAsAdmin() {
        //Muting trigger to avoid triggering the You cannot update the amount because the Transaction Order Status is set to Confirmed validation rule
        REDU_TriggerController.muteTriggers(new Set<String>{'TRO_UpdateStatus_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create monetary entry
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            90.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Change from monetary entry to order line
            monetaryEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            monetaryEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_DEBIT;
            update monetaryEntry;
            
            Test.stopTest();
        }

        // Verify rollup occurred - amount should move from Total Paid Amount to Total Amount
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(90.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should include the amount after changing to order line');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should be 0 after changing from monetary entry');
    }

    /**
     * @description Test executeAfterUpdate with amount change as Admin
     */
    @IsTest
    static void testExecuteAfterUpdateAmountChangedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert orderLine;

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Change the amount
            orderLine.reduivy__Unit_Price__c = 150.00;
            update orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred with new amount
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(150.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be updated with new amount');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain 0');
    }

    /**
     * @description Test executeAfterUpdate with parent change as Admin (should roll up both old and new parent)
     */
    @IsTest
    static void testExecuteAfterUpdateParentChangedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create first transaction order
        reduivy__Transaction_Order__c transactionOrder1 = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder1;

        // Create second transaction order
        reduivy__Transaction_Order__c transactionOrder2 = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder2;

        // Create order line under first transaction order
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder1.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            200.00, // totalAmount
            0.00,   // offsetAmount
            200.00  // outstandingAmount
        );
        insert orderLine;

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Move order line to second transaction order
            orderLine.reduivy__Transaction_Order__c = transactionOrder2.Id;
            update orderLine;
            
            Test.stopTest();
        }

        // Verify both transaction orders were rolled up
        List<reduivy__Transaction_Order__c> updatedOrders = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id IN (:transactionOrder1.Id, :transactionOrder2.Id)
            ORDER BY Id
        ];
        
        // First order should now have 0 total amount
        reduivy__Transaction_Order__c order1 = updatedOrders[0].Id == transactionOrder1.Id ? updatedOrders[0] : updatedOrders[1];
        reduivy__Transaction_Order__c order2 = updatedOrders[0].Id == transactionOrder2.Id ? updatedOrders[0] : updatedOrders[1];
        
        System.assertEquals(0.00, order1.reduivy__Total_Amount__c, 
            'First transaction order should have 0 total amount after item moved');
        System.assertEquals(200.00, order2.reduivy__Total_Amount__c, 
            'Second transaction order should have 200.00 total amount after item moved');
    }

    /**
     * @description Test executeAfterUpdate with no relevant changes as Admin (should skip)
     */
    @IsTest
    static void testExecuteAfterUpdateNoChangeAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert orderLine;

        // Get initial values
        reduivy__Transaction_Order__c initialOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, LastModifiedDate
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        DateTime initialModifiedDate = initialOrder.LastModifiedDate;

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Update a field that doesn't affect rollup (item name)
            orderLine.reduivy__Item_Name__c = 'Updated Fee Name';
            update orderLine;
            
            Test.stopTest();
        }

        // Verify no rollup occurred - LastModifiedDate should not change on transaction order
        reduivy__Transaction_Order__c finalOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, LastModifiedDate
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(100.00, finalOrder.reduivy__Total_Amount__c, 
            'Total Amount should remain unchanged');
        System.assertEquals(0.00, finalOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain unchanged');
        System.assertEquals(initialModifiedDate, finalOrder.LastModifiedDate, 
            'Transaction Order should not be updated when no relevant changes occur');
    }

    // ========== AFTER DELETE TESTS ==========

    /**
     * @description Test executeAfterDelete with qualified type and parent as Admin
     */
    @IsTest
    static void testExecuteAfterDeleteQualifiedWithParentAsAdmin() {
        //Muting trigger to avoid triggering the You cannot update the amount because the Transaction Order Status is set to Confirmed validation rule
        REDU_TriggerController.muteTriggers(new Set<String>{'TRO_UpdateStatus_EXE'});
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert orderLine;

        // Create monetary entry
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            orderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            60.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;

        // Verify initial rollup values
        reduivy__Transaction_Order__c initialOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        System.assertEquals(100.00, initialOrder.reduivy__Total_Amount__c, 'Initial total amount should be 100.00');
        System.assertEquals(60.00, initialOrder.reduivy__Total_Paid_Amount__c, 'Initial paid amount should be 60.00');

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            delete monetaryEntry;
            // Delete the order line (qualified type with parent)
            delete orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred after deletion - Total Amount should be recalculated
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be 0 after order line deletion');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Amount should be 0 after monetary line deletion');
    }

    // ========== AFTER UNDELETE TESTS ==========

    /**
     * @description Test executeAfterUndelete with Order Line as Admin
     */
    @IsTest
    static void testExecuteAfterUndeleteOrderLineAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            120.00, // totalAmount
            0.00,   // offsetAmount
            120.00  // outstandingAmount
        );

        System.runAs(ADMIN_USER) {
            insert orderLine;

            // Delete the order line first
            delete orderLine;
        }

        // Verify it was deleted and rollup occurred
        reduivy__Transaction_Order__c afterDeleteOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        System.assertEquals(0.00, afterDeleteOrder.reduivy__Total_Amount__c, 'Total amount should be 0 after deletion');

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Undelete the order line
            undelete orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred after undelete - Total Amount should be restored
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(120.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be restored after order line undelete');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain 0 for order line');
    }

    /**
     * @description Test executeAfterUndelete with Monetary Entry as Admin
     */
    @IsTest
    static void testExecuteAfterUndeleteMonetaryEntryAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create parent order line for offset reference
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            200.00, // totalAmount
            0.00,   // offsetAmount
            200.00  // outstandingAmount
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

        System.runAs(ADMIN_USER) {
            insert monetaryEntry;

            // Delete the monetary entry first
            delete monetaryEntry;
        }

        // Verify it was deleted and rollup occurred
        reduivy__Transaction_Order__c afterDeleteOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        System.assertEquals(0.00, afterDeleteOrder.reduivy__Total_Paid_Amount__c, 'Paid amount should be 0 after deletion');

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Undelete the monetary entry
            undelete monetaryEntry;
            
            Test.stopTest();
        }

        // Verify rollup occurred after undelete - Total Paid Amount should be restored
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(200.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should include order line amount');
        System.assertEquals(80.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should be restored after monetary entry undelete');
    }

    /**
     * @description Test executeAfterUndelete with non-qualified type as Admin (should skip)
     */
    @IsTest
    static void testExecuteAfterUndeleteNonQualifiedTypeAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount - preset value
            0.00,   // outstandingAmount
            50.00   // paidAmount - preset value
        );
        insert transactionOrder;

        // Create discount entry (non-qualified type)
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

        System.runAs(ADMIN_USER) {
            insert discountEntry;

            // Delete the discount entry first
            delete discountEntry;
        }

        // Get baseline values before undelete
        reduivy__Transaction_Order__c beforeUndeleteOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, LastModifiedDate
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        DateTime beforeUndeleteModifiedDate = beforeUndeleteOrder.LastModifiedDate;

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Undelete the discount entry (non-qualified type)
            undelete discountEntry;
            
            Test.stopTest();
        }

        // Verify no rollup occurred - amounts and LastModifiedDate should remain unchanged
        reduivy__Transaction_Order__c afterUndeleteOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, LastModifiedDate
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(100.00, afterUndeleteOrder.reduivy__Total_Amount__c, 
            'Total Amount should not change for non-qualified type undelete');
        System.assertEquals(50.00, afterUndeleteOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should not change for non-qualified type undelete');
        System.assertEquals(beforeUndeleteModifiedDate, afterUndeleteOrder.LastModifiedDate, 
            'Transaction Order should not be updated when undeleting non-qualified type');

        // Verify the discount entry was successfully undeleted
        List<reduivy__Transaction_Line_Item__c> undeletedEntries = [
            SELECT Id, reduivy__Transaction_Type__c, reduivy__Total_Amount__c
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :discountEntry.Id
        ];
        
        System.assertEquals(1, undeletedEntries.size(), 'Discount entry should be successfully undeleted');
        System.assertEquals(TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY, undeletedEntries[0].reduivy__Transaction_Type__c, 
            'Transaction type should remain as discount entry');
    }

    //Student
    // ========== AFTER INSERT TESTS ==========

    /**
     * @description Test executeAfterInsert with Order Line as Student (should roll up)
     */
    @IsTest
    static void testExecuteAfterInsertOrderLineAsStudent() {
        
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

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount - should be updated by rollup
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line item
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Tuition Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            150.00, // totalAmount
            0.00,   // offsetAmount
            150.00  // outstandingAmount
        );

        System.runAs(studentUser) {
            Test.startTest();
            
            insert orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred - Total Amount should be updated to 150.00
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(150.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be rolled up from order line');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain 0 for order line');
    }

    /**
     * @description Test executeAfterInsert with Monetary Entry as Student (should roll up)
     */
    @IsTest
    static void testExecuteAfterInsertMonetaryEntryAsStudent() {
        
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

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount - should be updated by rollup
        );
        insert transactionOrder;

        // Create parent order line for offset reference
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            200.00, // totalAmount
            0.00,   // offsetAmount
            200.00  // outstandingAmount
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
            75.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );

        System.runAs(studentUser) {
            Test.startTest();
            
            insert monetaryEntry;
            
            Test.stopTest();
        }

        // Verify rollup occurred - Total Paid Amount should be updated to 75.00
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(200.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should include order line amount');
        System.assertEquals(75.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should be rolled up from monetary entry');
    }

    /**
     * @description Test executeAfterInsert with non-qualified type as Student (should skip)
     */
    @IsTest
    static void testExecuteAfterInsertNonQualifiedTypeAsStudent() {
        
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

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create discount entry (non-qualified type for rollup)
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

        System.runAs(studentUser) {
            Test.startTest();
            
            insert discountEntry;
            
            Test.stopTest();
        }

        // Verify no rollup occurred - amounts should remain 0
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should not be updated for discount entry');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should not be updated for discount entry');
    }

    /**
     * @description Test executeAfterInsert with no parent as Student (should skip)
     */
    @IsTest
    static void testExecuteAfterInsertNoParentAsStudent() {

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

        // Create order line item without parent transaction order
        reduivy__Transaction_Line_Item__c orphanOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            null, // transactionOrderId - no parent
            null, // studyFeeMatrixItemId
            'Orphan Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );

        System.runAs(studentUser) {
            Test.startTest();
            
            insert orphanOrderLine;
            
            Test.stopTest();
        }

        // Verify the record was created but no rollup processing occurred
        reduivy__Transaction_Line_Item__c createdItem = [
            SELECT Id, reduivy__Transaction_Order__c, reduivy__Total_Amount__c
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :orphanOrderLine.Id
        ];
        
        System.assertEquals(null, createdItem.reduivy__Transaction_Order__c, 
            'Transaction Line Item should have no parent order');
        System.assertEquals(100.00, createdItem.reduivy__Total_Amount__c, 
            'Transaction Line Item amount should be preserved');
        
        // No transaction orders should exist to verify rollup didn't happen
        Integer orderCount = [SELECT COUNT() FROM reduivy__Transaction_Order__c];
        System.assertEquals(0, orderCount, 
            'No transaction orders should exist when line item has no parent');
    }
	
    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test executeAfterUpdate from non-qualified to qualified type as Student
     */
    @IsTest
    static void testExecuteAfterUpdateNonQualifiedToQualifiedAsStudent() {

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

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create discount entry (non-qualified type)
        reduivy__Transaction_Line_Item__c discountEntry = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount',
            TRL_Helper.ITEM_TYPE_TUITION,
            50.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        insert discountEntry;

        System.runAs(studentUser) {
            Test.startTest();
            
            // Change from discount entry to order line (qualified type)
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_DEBIT;
            update discountEntry;
            
            Test.stopTest();
        }

        // Verify rollup occurred - Total Amount should now include this item
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(50.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be rolled up after changing to qualified type');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain 0 for order line');
    }

    /**
     * @description Test executeAfterUpdate from qualified to non-qualified type as Student
     */
    @IsTest
    static void testExecuteAfterUpdateQualifiedToNonQualifiedAsStudent() {
        
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

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line (qualified type)
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            75.00, // totalAmount
            0.00,  // offsetAmount
            75.00  // outstandingAmount
        );
        insert orderLine;

        System.runAs(studentUser) {
            Test.startTest();
            
            // Change from order line to discount entry (non-qualified type)
            orderLine.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            update orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred - Total Amount should be recalculated without this item
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be recalculated after changing to non-qualified type');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain 0');
    }

    /**
     * @description Test executeAfterUpdate from Order Line to Monetary Entry as Student
     */
    @IsTest
    static void testExecuteAfterUpdateOrderLineToMonetaryEntryAsStudent() {
        //Muting trigger to avoid triggering the You cannot update the amount because the Transaction Order Status is set to Confirmed validation rule
        REDU_TriggerController.muteTriggers(new Set<String>{'TRO_UpdateStatus_EXE'});

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

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            120.00, // totalAmount
            0.00,   // offsetAmount
            120.00  // outstandingAmount
        );
        insert orderLine;

        System.runAs(studentUser) {
            Test.startTest();
            
            // Change from order line to monetary entry
            orderLine.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY;
            orderLine.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            update orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred - amount should move from Total Amount to Total Paid Amount
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be 0 after changing from order line');
        System.assertEquals(120.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should include the amount after changing to monetary entry');
    }

    /**
     * @description Test executeAfterUpdate from Monetary Entry to Order Line as Student
     */
    @IsTest
    static void testExecuteAfterUpdateMonetaryEntryToOrderLineAsStudent() {
        //Muting trigger to avoid triggering the You cannot update the amount because the Transaction Order Status is set to Confirmed validation rule
        REDU_TriggerController.muteTriggers(new Set<String>{'TRO_UpdateStatus_EXE'});

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

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create monetary entry
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            90.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;

        System.runAs(studentUser) {
            Test.startTest();
            
            // Change from monetary entry to order line
            monetaryEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            monetaryEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_DEBIT;
            update monetaryEntry;
            
            Test.stopTest();
        }

        // Verify rollup occurred - amount should move from Total Paid Amount to Total Amount
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(90.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should include the amount after changing to order line');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should be 0 after changing from monetary entry');
    }

    /**
     * @description Test executeAfterUpdate with amount change as Student
     */
    @IsTest
    static void testExecuteAfterUpdateAmountChangedAsStudent() {
        
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

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert orderLine;

        System.runAs(studentUser) {
            Test.startTest();
            
            // Change the amount
            orderLine.reduivy__Unit_Price__c = 150.00;
            update orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred with new amount
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(150.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be updated with new amount');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain 0');
    }

    /**
     * @description Test executeAfterUpdate with parent change as Student (should roll up both old and new parent)
     */
    @IsTest
    static void testExecuteAfterUpdateParentChangedAsStudent() {
        
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

        // Create first transaction order
        reduivy__Transaction_Order__c transactionOrder1 = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder1;

        // Create second transaction order
        reduivy__Transaction_Order__c transactionOrder2 = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder2;

        // Create order line under first transaction order
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder1.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            200.00, // totalAmount
            0.00,   // offsetAmount
            200.00  // outstandingAmount
        );
        insert orderLine;

        System.runAs(studentUser) {
            Test.startTest();
            
            // Move order line to second transaction order
            orderLine.reduivy__Transaction_Order__c = transactionOrder2.Id;
            update orderLine;
            
            Test.stopTest();
        }

        // Verify both transaction orders were rolled up
        List<reduivy__Transaction_Order__c> updatedOrders = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id IN (:transactionOrder1.Id, :transactionOrder2.Id)
            ORDER BY Id
        ];
        
        // First order should now have 0 total amount
        reduivy__Transaction_Order__c order1 = updatedOrders[0].Id == transactionOrder1.Id ? updatedOrders[0] : updatedOrders[1];
        reduivy__Transaction_Order__c order2 = updatedOrders[0].Id == transactionOrder2.Id ? updatedOrders[0] : updatedOrders[1];
        
        System.assertEquals(0.00, order1.reduivy__Total_Amount__c, 
            'First transaction order should have 0 total amount after item moved');
        System.assertEquals(200.00, order2.reduivy__Total_Amount__c, 
            'Second transaction order should have 200.00 total amount after item moved');
    }

    /**
     * @description Test executeAfterUpdate with no relevant changes as Student (should skip)
     */
    @IsTest
    static void testExecuteAfterUpdateNoChangeAsStudent() {
        
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

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert orderLine;

        // Get initial values
        reduivy__Transaction_Order__c initialOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, LastModifiedDate
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        DateTime initialModifiedDate = initialOrder.LastModifiedDate;

        System.runAs(studentUser) {
            Test.startTest();
            
            // Update a field that doesn't affect rollup (item name)
            orderLine.reduivy__Item_Name__c = 'Updated Fee Name';
            update orderLine;
            
            Test.stopTest();
        }

        // Verify no rollup occurred - LastModifiedDate should not change on transaction order
        reduivy__Transaction_Order__c finalOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, LastModifiedDate
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(100.00, finalOrder.reduivy__Total_Amount__c, 
            'Total Amount should remain unchanged');
        System.assertEquals(0.00, finalOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain unchanged');
        System.assertEquals(initialModifiedDate, finalOrder.LastModifiedDate, 
            'Transaction Order should not be updated when no relevant changes occur');
    }

    // ========== AFTER DELETE TESTS ==========
    
    /**
     * @description Test executeAfterDelete with qualified type and parent as Student
     */
    @IsTest
    static void testExecuteAfterDeleteQualifiedWithParentAsStudent() {
        //Muting trigger to avoid triggering the You cannot update the amount because the Transaction Order Status is set to Confirmed validation rule
        REDU_TriggerController.muteTriggers(new Set<String>{'TRO_UpdateStatus_EXE'});

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

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        
        // Create monetary entry
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            orderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            60.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        

        System.runAs(studentUser) {
            insert orderLine;
            insert monetaryEntry;
        }

        // Verify initial rollup values
        reduivy__Transaction_Order__c initialOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        System.assertEquals(100.00, initialOrder.reduivy__Total_Amount__c, 'Initial total amount should be 100.00');
        System.assertEquals(60.00, initialOrder.reduivy__Total_Paid_Amount__c, 'Initial paid amount should be 60.00');

        System.runAs(studentUser) {
            Test.startTest();
            
            delete monetaryEntry;
            // Delete the order line (qualified type with parent)
            delete orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred after deletion - Total Amount should be recalculated
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be 0 after order line deletion');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Amount should be 0 after monetary line deletion');
    }

    // ========== AFTER UNDELETE TESTS ==========

    /**
     * @description Test executeAfterUndelete with Order Line as Student
     */
    @IsTest
    static void testExecuteAfterUndeleteOrderLineAsStudent() {
        
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

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            120.00, // totalAmount
            0.00,   // offsetAmount
            120.00  // outstandingAmount
        );

        System.runAs(studentUser) {
            insert orderLine;

            // Delete the order line first
            delete orderLine;
        }

        // Verify it was deleted and rollup occurred
        reduivy__Transaction_Order__c afterDeleteOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        System.assertEquals(0.00, afterDeleteOrder.reduivy__Total_Amount__c, 'Total amount should be 0 after deletion');

        System.runAs(studentUser) {
            Test.startTest();
            
            // Undelete the order line
            undelete orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred after undelete - Total Amount should be restored
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(120.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be restored after order line undelete');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain 0 for order line');
    }

    /**
     * @description Test executeAfterUndelete with Monetary Entry as Student
     */
    @IsTest
    static void testExecuteAfterUndeleteMonetaryEntryAsStudent() {
        
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

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create parent order line for offset reference
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            200.00, // totalAmount
            0.00,   // offsetAmount
            200.00  // outstandingAmount
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

        System.runAs(studentUser) {
            insert monetaryEntry;

            // Delete the monetary entry first
            delete monetaryEntry;
        }

        // Verify it was deleted and rollup occurred
        reduivy__Transaction_Order__c afterDeleteOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        System.assertEquals(0.00, afterDeleteOrder.reduivy__Total_Paid_Amount__c, 'Paid amount should be 0 after deletion');

        System.runAs(studentUser) {
            Test.startTest();
            
            // Undelete the monetary entry
            undelete monetaryEntry;
            
            Test.stopTest();
        }

        // Verify rollup occurred after undelete - Total Paid Amount should be restored
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(200.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should include order line amount');
        System.assertEquals(80.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should be restored after monetary entry undelete');
    }

    /**
     * @description Test executeAfterUndelete with non-qualified type as Student (should skip)
     */
    @IsTest
    static void testExecuteAfterUndeleteNonQualifiedTypeAsStudent() {
        
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

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount - preset value
            0.00,   // outstandingAmount
            50.00   // paidAmount - preset value
        );
        insert transactionOrder;

        // Create discount entry (non-qualified type)
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

        System.runAs(studentUser) {
            insert discountEntry;

            // Delete the discount entry first
            delete discountEntry;
        }

        // Get baseline values before undelete
        reduivy__Transaction_Order__c beforeUndeleteOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, LastModifiedDate
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        DateTime beforeUndeleteModifiedDate = beforeUndeleteOrder.LastModifiedDate;

        System.runAs(studentUser) {
            Test.startTest();
            
            // Undelete the discount entry (non-qualified type)
            undelete discountEntry;
            
            Test.stopTest();
        }

        // Verify no rollup occurred - amounts and LastModifiedDate should remain unchanged
        reduivy__Transaction_Order__c afterUndeleteOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, LastModifiedDate
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(100.00, afterUndeleteOrder.reduivy__Total_Amount__c, 
            'Total Amount should not change for non-qualified type undelete');
        System.assertEquals(50.00, afterUndeleteOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should not change for non-qualified type undelete');
        System.assertEquals(beforeUndeleteModifiedDate, afterUndeleteOrder.LastModifiedDate, 
            'Transaction Order should not be updated when undeleting non-qualified type');

        // Verify the discount entry was successfully undeleted
        List<reduivy__Transaction_Line_Item__c> undeletedEntries = [
            SELECT Id, reduivy__Transaction_Type__c, reduivy__Total_Amount__c
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :discountEntry.Id
        ];
        
        System.assertEquals(1, undeletedEntries.size(), 'Discount entry should be successfully undeleted');
        System.assertEquals(TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY, undeletedEntries[0].reduivy__Transaction_Type__c, 
            'Transaction type should remain as discount entry');
    }

    //Faculty
    // ========== AFTER INSERT TESTS ==========

    /**
     * @description Test executeAfterInsert with Order Line as Faculty (should roll up)
     */
    @IsTest
    static void testExecuteAfterInsertOrderLineAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount - should be updated by rollup
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line item
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Tuition Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            150.00, // totalAmount
            0.00,   // offsetAmount
            150.00  // outstandingAmount
        );

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            insert orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred - Total Amount should be updated to 150.00
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(150.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be rolled up from order line');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain 0 for order line');
    }

    /**
     * @description Test executeAfterInsert with Monetary Entry as Faculty (should roll up)
     */
    @IsTest
    static void testExecuteAfterInsertMonetaryEntryAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount - should be updated by rollup
        );
        insert transactionOrder;

        // Create parent order line for offset reference
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            200.00, // totalAmount
            0.00,   // offsetAmount
            200.00  // outstandingAmount
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
            75.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            insert monetaryEntry;
            
            Test.stopTest();
        }

        // Verify rollup occurred - Total Paid Amount should be updated to 75.00
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(200.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should include order line amount');
        System.assertEquals(75.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should be rolled up from monetary entry');
    }

    /**
     * @description Test executeAfterInsert with non-qualified type as Faculty (should skip)
     */
    @IsTest
    static void testExecuteAfterInsertNonQualifiedTypeAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create discount entry (non-qualified type for rollup)
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

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            insert discountEntry;
            
            Test.stopTest();
        }

        // Verify no rollup occurred - amounts should remain 0
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should not be updated for discount entry');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should not be updated for discount entry');
    }

    /**
     * @description Test executeAfterInsert with no parent as Faculty (should skip)
     */
    @IsTest
    static void testExecuteAfterInsertNoParentAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create order line item without parent transaction order
        reduivy__Transaction_Line_Item__c orphanOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            null, // transactionOrderId - no parent
            null, // studyFeeMatrixItemId
            'Orphan Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            insert orphanOrderLine;
            
            Test.stopTest();
        }

        // Verify the record was created but no rollup processing occurred
        reduivy__Transaction_Line_Item__c createdItem = [
            SELECT Id, reduivy__Transaction_Order__c, reduivy__Total_Amount__c
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :orphanOrderLine.Id
        ];
        
        System.assertEquals(null, createdItem.reduivy__Transaction_Order__c, 
            'Transaction Line Item should have no parent order');
        System.assertEquals(100.00, createdItem.reduivy__Total_Amount__c, 
            'Transaction Line Item amount should be preserved');
        
        // No transaction orders should exist to verify rollup didn't happen
        Integer orderCount = [SELECT COUNT() FROM reduivy__Transaction_Order__c];
        System.assertEquals(0, orderCount, 
            'No transaction orders should exist when line item has no parent');
    }
	
    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test executeAfterUpdate from non-qualified to qualified type as Faculty
     */
    @IsTest
    static void testExecuteAfterUpdateNonQualifiedToQualifiedAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create discount entry (non-qualified type)
        reduivy__Transaction_Line_Item__c discountEntry = REDU_TestData_UTIL.newTransactionDiscountEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            'Test Discount',
            TRL_Helper.ITEM_TYPE_TUITION,
            50.00, // totalAmount
            null,  // idvFundingAllocationId
            null,  // studyVoucherTransactionId
            null,  // studyFeeMatrixItemId
            null   // individualEnrollmentId
        );
        insert discountEntry;

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Change from discount entry to order line (qualified type)
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_DEBIT;
            update discountEntry;
            
            Test.stopTest();
        }

        // Verify rollup occurred - Total Amount should now include this item
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(50.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be rolled up after changing to qualified type');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain 0 for order line');
    }

    /**
     * @description Test executeAfterUpdate from qualified to non-qualified type as Faculty
     */
    @IsTest
    static void testExecuteAfterUpdateQualifiedToNonQualifiedAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line (qualified type)
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            75.00, // totalAmount
            0.00,  // offsetAmount
            75.00  // outstandingAmount
        );
        insert orderLine;

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Change from order line to discount entry (non-qualified type)
            orderLine.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            update orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred - Total Amount should be recalculated without this item
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be recalculated after changing to non-qualified type');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain 0');
    }

    /**
     * @description Test executeAfterUpdate from Order Line to Monetary Entry as Faculty
     */
    @IsTest
    static void testExecuteAfterUpdateOrderLineToMonetaryEntryAsFaculty() {
        //Muting trigger to avoid triggering the You cannot update the amount because the Transaction Order Status is set to Confirmed validation rule
        REDU_TriggerController.muteTriggers(new Set<String>{'TRO_UpdateStatus_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            120.00, // totalAmount
            0.00,   // offsetAmount
            120.00  // outstandingAmount
        );
        insert orderLine;

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Change from order line to monetary entry
            orderLine.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY;
            orderLine.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            update orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred - amount should move from Total Amount to Total Paid Amount
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be 0 after changing from order line');
        System.assertEquals(120.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should include the amount after changing to monetary entry');
    }

    /**
     * @description Test executeAfterUpdate from Monetary Entry to Order Line as Faculty
     */
    @IsTest
    static void testExecuteAfterUpdateMonetaryEntryToOrderLineAsFaculty() {
        //Muting trigger to avoid triggering the You cannot update the amount because the Transaction Order Status is set to Confirmed validation rule
        REDU_TriggerController.muteTriggers(new Set<String>{'TRO_UpdateStatus_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create monetary entry
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            90.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Change from monetary entry to order line
            monetaryEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            monetaryEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_DEBIT;
            update monetaryEntry;
            
            Test.stopTest();
        }

        // Verify rollup occurred - amount should move from Total Paid Amount to Total Amount
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(90.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should include the amount after changing to order line');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should be 0 after changing from monetary entry');
    }

    /**
     * @description Test executeAfterUpdate with amount change as Faculty
     */
    @IsTest
    static void testExecuteAfterUpdateAmountChangedAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert orderLine;

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Change the amount
            orderLine.reduivy__Unit_Price__c = 150.00;
            update orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred with new amount
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(150.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be updated with new amount');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain 0');
    }

    /**
     * @description Test executeAfterUpdate with parent change as Faculty (should roll up both old and new parent)
     */
    @IsTest
    static void testExecuteAfterUpdateParentChangedAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create first transaction order
        reduivy__Transaction_Order__c transactionOrder1 = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder1;

        // Create second transaction order
        reduivy__Transaction_Order__c transactionOrder2 = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder2;

        // Create order line under first transaction order
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder1.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            200.00, // totalAmount
            0.00,   // offsetAmount
            200.00  // outstandingAmount
        );
        insert orderLine;

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Move order line to second transaction order
            orderLine.reduivy__Transaction_Order__c = transactionOrder2.Id;
            update orderLine;
            
            Test.stopTest();
        }

        // Verify both transaction orders were rolled up
        List<reduivy__Transaction_Order__c> updatedOrders = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id IN (:transactionOrder1.Id, :transactionOrder2.Id)
            ORDER BY Id
        ];
        
        // First order should now have 0 total amount
        reduivy__Transaction_Order__c order1 = updatedOrders[0].Id == transactionOrder1.Id ? updatedOrders[0] : updatedOrders[1];
        reduivy__Transaction_Order__c order2 = updatedOrders[0].Id == transactionOrder2.Id ? updatedOrders[0] : updatedOrders[1];
        
        System.assertEquals(0.00, order1.reduivy__Total_Amount__c, 
            'First transaction order should have 0 total amount after item moved');
        System.assertEquals(200.00, order2.reduivy__Total_Amount__c, 
            'Second transaction order should have 200.00 total amount after item moved');
    }

    /**
     * @description Test executeAfterUpdate with no relevant changes as Faculty (should skip)
     */
    @IsTest
    static void testExecuteAfterUpdateNoChangeAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert orderLine;

        // Get initial values
        reduivy__Transaction_Order__c initialOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, LastModifiedDate
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        DateTime initialModifiedDate = initialOrder.LastModifiedDate;

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Update a field that doesn't affect rollup (item name)
            orderLine.reduivy__Item_Name__c = 'Updated Fee Name';
            update orderLine;
            
            Test.stopTest();
        }

        // Verify no rollup occurred - LastModifiedDate should not change on transaction order
        reduivy__Transaction_Order__c finalOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, LastModifiedDate
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(100.00, finalOrder.reduivy__Total_Amount__c, 
            'Total Amount should remain unchanged');
        System.assertEquals(0.00, finalOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain unchanged');
        System.assertEquals(initialModifiedDate, finalOrder.LastModifiedDate, 
            'Transaction Order should not be updated when no relevant changes occur');
    }

    // ========== AFTER DELETE TESTS ==========

    /**
     * @description Test executeAfterDelete with qualified type and parent as Faculty
     */
    @IsTest
    static void testExecuteAfterDeleteQualifiedWithParentAsFaculty() {
        //Muting trigger to avoid triggering the You cannot update the amount because the Transaction Order Status is set to Confirmed validation rule
        REDU_TriggerController.muteTriggers(new Set<String>{'TRO_UpdateStatus_EXE'});
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        
        // Create monetary entry
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // transactionPaymentId
            orderLine.Id, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            60.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        

        System.runAs(FACULTY_USER) {
            insert orderLine;
            insert monetaryEntry;
        }

        // Verify initial rollup values
        reduivy__Transaction_Order__c initialOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        System.assertEquals(100.00, initialOrder.reduivy__Total_Amount__c, 'Initial total amount should be 100.00');
        System.assertEquals(60.00, initialOrder.reduivy__Total_Paid_Amount__c, 'Initial paid amount should be 60.00');

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            delete monetaryEntry;
            // Delete the order line (qualified type with parent)
            delete orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred after deletion - Total Amount should be recalculated
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be 0 after order line deletion');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Amount should be 0 after monetary line deletion');
    }

    // ========== AFTER UNDELETE TESTS ==========

    /**
     * @description Test executeAfterUndelete with Order Line as Faculty
     */
    @IsTest
    static void testExecuteAfterUndeleteOrderLineAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create order line
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee',
            TRL_Helper.ITEM_TYPE_TUITION,
            120.00, // totalAmount
            0.00,   // offsetAmount
            120.00  // outstandingAmount
        );

        System.runAs(FACULTY_USER) {
            insert orderLine;

            // Delete the order line first
            delete orderLine;
        }

        // Verify it was deleted and rollup occurred
        reduivy__Transaction_Order__c afterDeleteOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        System.assertEquals(0.00, afterDeleteOrder.reduivy__Total_Amount__c, 'Total amount should be 0 after deletion');

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Undelete the order line
            undelete orderLine;
            
            Test.stopTest();
        }

        // Verify rollup occurred after undelete - Total Amount should be restored
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(120.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should be restored after order line undelete');
        System.assertEquals(0.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should remain 0 for order line');
    }

    /**
     * @description Test executeAfterUndelete with Monetary Entry as Faculty
     */
    @IsTest
    static void testExecuteAfterUndeleteMonetaryEntryAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            0.00, // totalAmount
            0.00, // outstandingAmount
            0.00  // paidAmount
        );
        insert transactionOrder;

        // Create parent order line for offset reference
        reduivy__Transaction_Line_Item__c parentOrderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            200.00, // totalAmount
            0.00,   // offsetAmount
            200.00  // outstandingAmount
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

        System.runAs(FACULTY_USER) {
            insert monetaryEntry;

            // Delete the monetary entry first
            delete monetaryEntry;
        }

        // Verify it was deleted and rollup occurred
        reduivy__Transaction_Order__c afterDeleteOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        System.assertEquals(0.00, afterDeleteOrder.reduivy__Total_Paid_Amount__c, 'Paid amount should be 0 after deletion');

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Undelete the monetary entry
            undelete monetaryEntry;
            
            Test.stopTest();
        }

        // Verify rollup occurred after undelete - Total Paid Amount should be restored
        reduivy__Transaction_Order__c updatedOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(200.00, updatedOrder.reduivy__Total_Amount__c, 
            'Total Amount should include order line amount');
        System.assertEquals(80.00, updatedOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should be restored after monetary entry undelete');
    }

    /**
     * @description Test executeAfterUndelete with non-qualified type as Faculty (should skip)
     */
    @IsTest
    static void testExecuteAfterUndeleteNonQualifiedTypeAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create transaction order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            null, // academicProgressId
            Date.today(),
            TRO_Helper.STATUS_TYPE_SUBMITTED,
            100.00, // totalAmount - preset value
            0.00,   // outstandingAmount
            50.00   // paidAmount - preset value
        );
        insert transactionOrder;

        // Create discount entry (non-qualified type)
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

        System.runAs(FACULTY_USER) {
            insert discountEntry;

            // Delete the discount entry first
            delete discountEntry;
        }

        // Get baseline values before undelete
        reduivy__Transaction_Order__c beforeUndeleteOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, LastModifiedDate
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        DateTime beforeUndeleteModifiedDate = beforeUndeleteOrder.LastModifiedDate;

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Undelete the discount entry (non-qualified type)
            undelete discountEntry;
            
            Test.stopTest();
        }

        // Verify no rollup occurred - amounts and LastModifiedDate should remain unchanged
        reduivy__Transaction_Order__c afterUndeleteOrder = [
            SELECT Id, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, LastModifiedDate
            FROM reduivy__Transaction_Order__c 
            WHERE Id = :transactionOrder.Id
        ];
        
        System.assertEquals(100.00, afterUndeleteOrder.reduivy__Total_Amount__c, 
            'Total Amount should not change for non-qualified type undelete');
        System.assertEquals(50.00, afterUndeleteOrder.reduivy__Total_Paid_Amount__c, 
            'Total Paid Amount should not change for non-qualified type undelete');
        System.assertEquals(beforeUndeleteModifiedDate, afterUndeleteOrder.LastModifiedDate, 
            'Transaction Order should not be updated when undeleting non-qualified type');

        // Verify the discount entry was successfully undeleted
        List<reduivy__Transaction_Line_Item__c> undeletedEntries = [
            SELECT Id, reduivy__Transaction_Type__c, reduivy__Total_Amount__c
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :discountEntry.Id
        ];
        
        System.assertEquals(1, undeletedEntries.size(), 'Discount entry should be successfully undeleted');
        System.assertEquals(TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY, undeletedEntries[0].reduivy__Transaction_Type__c, 
            'Transaction type should remain as discount entry');
    }
}