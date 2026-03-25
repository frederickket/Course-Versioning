/**
 * @author      WDCi (XiRouh)
 * @date        Aug 2025
 * @group       Test
 * @description Test class for TRL_TransactionPaymentRollup_EXE
 * @changehistory
 * ISS-002587 13-08-2025 XiRouh - new class
 */
@IsTest
public inherited sharing class TRL_TransactionPaymentRollup_TEST {

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
     * @description Test executeAfterInsert with non-monetary TRLs as Admin (no rollup)
     */
    @IsTest 
    static void testExecuteAfterInsertNonMonetaryAsAdmin() {
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
        
        // Create non-monetary TRL (order line)
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            insert orderLine;
            
            Test.stopTest();
        }
        
        // Assertions - No rollup should occur for non-monetary entries
        // Since no transaction payment was created, we just verify the record was inserted successfully
        reduivy__Transaction_Line_Item__c insertedTrl = [
            SELECT Id, reduivy__Transaction_Type__c, reduivy__Total_Amount__c
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :orderLine.Id
        ];
        
        System.assertEquals(TRL_Helper.TRANSACTION_TYPE_ORDERLINE, insertedTrl.reduivy__Transaction_Type__c, 
            'TRL should be of order line type');
        System.assertEquals(100.00, insertedTrl.reduivy__Total_Amount__c, 
            'TRL amount should be 100.00');
    }

    /**
     * @description Test executeAfterInsert with new monetary TRLs linked to payment as Admin
     */
    @IsTest 
    static void testExecuteAfterInsertNewMonetaryEntryAsAdmin() {
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
        
        // Create transaction payment
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount - should be updated by rollup
            null    // applicableItemType
        );
        insert transactionPayment;
        
        // Create monetary entry linked to payment
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            50.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            insert monetaryEntry;
            
            Test.stopTest();
        }
        
        // Assertions - Applied amount should be rolled up to transaction payment
        reduivy__Transaction_Payment__c updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(50.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be rolled up to 50.00');
    }

    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test executeAfterUpdate with no monetary type or relevant changes as Admin
     */
    @IsTest 
    static void testExecuteAfterUpdateNoRelevantChangeAsAdmin() {
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
        
        // Create non-monetary TRL (order line)
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert orderLine;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Update non-relevant field
            orderLine.reduivy__Item_Name__c = 'Updated Item Name';
            update orderLine;
            
            Test.stopTest();
        }
        
        // Assertions - No rollup should occur
        reduivy__Transaction_Line_Item__c updatedTrl = [
            SELECT Id, reduivy__Item_Name__c, reduivy__Total_Amount__c
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :orderLine.Id
        ];
        
        System.assertEquals('Updated Item Name', updatedTrl.reduivy__Item_Name__c, 
            'Item name should be updated');
        System.assertEquals(100.00, updatedTrl.reduivy__Total_Amount__c, 
            'Amount should remain unchanged');
    }

    /**
     * @description Test executeAfterUpdate when TRL changes from non-monetary to monetary as Admin
     */
    @IsTest 
    static void testExecuteAfterUpdateBecameMonetaryAsAdmin() {
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
        
        // Create transaction payment
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment;
        
        // Create non-monetary TRL first
        reduivy__Transaction_Line_Item__c trl = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            75.00, // totalAmount
            0.00,  // offsetAmount
            75.00  // outstandingAmount
        );
        insert trl;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Change to monetary entry and link to payment
            trl.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY;
            trl.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            trl.reduivy__Transaction_Payment__c = transactionPayment.Id;
            update trl;
            
            Test.stopTest();
        }
        
        // Assertions - Applied amount should be rolled up
        reduivy__Transaction_Payment__c updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(75.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be rolled up to 75.00');
    }

    /**
     * @description Test executeAfterUpdate when TRL changes from monetary to non-monetary as Admin
     */
    @IsTest 
    static void testExecuteAfterUpdateBecameNonMonetaryAsAdmin() {
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
        
        // Create transaction payment
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment;
        
        // Create monetary entry first
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            80.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Change to non-monetary type
            monetaryEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            monetaryEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_DEBIT;
            update monetaryEntry;
            
            Test.stopTest();
        }
        
        // Assertions - Applied amount should be recalculated (should be 0)
        reduivy__Transaction_Payment__c updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(0.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be recalculated to 0.00');
    }

    /**
     * @description Test executeAfterUpdate when monetary TRL amount changes as Admin
     */
    @IsTest 
    static void testExecuteAfterUpdateAmountChangedAsAdmin() {
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
        
        // Create transaction payment
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment;
        
        // Create monetary entry
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            60.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;

        reduivy__Transaction_Payment__c updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(60.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be updated to 60.00');
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Change the amount
            monetaryEntry.reduivy__Unit_Price__c = 90.00;
            update monetaryEntry;
            
            Test.stopTest();
        }
        
        // Assertions - Applied amount should be updated
        updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(90.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be updated to 90.00');
    }

    /**
     * @description Test executeAfterUpdate when monetary TRL parent changes as Admin
     */
    @IsTest 
    static void testExecuteAfterUpdateParentChangedAsAdmin() {
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
        
        // Create first transaction payment
        reduivy__Transaction_Payment__c transactionPayment1 = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment1;
        
        // Create second transaction payment
        reduivy__Transaction_Payment__c transactionPayment2 = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment2;
        
        // Create monetary entry linked to first payment
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment1.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            70.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Change parent to second payment
            monetaryEntry.reduivy__Transaction_Payment__c = transactionPayment2.Id;
            update monetaryEntry;
            
            Test.stopTest();
        }
        
        // Assertions - Both payments should be updated
        List<reduivy__Transaction_Payment__c> updatedPayments = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id IN (:transactionPayment1.Id, :transactionPayment2.Id)
            ORDER BY Id
        ];
        
        reduivy__Transaction_Payment__c payment1 = updatedPayments[0].Id == transactionPayment1.Id ? 
            updatedPayments[0] : updatedPayments[1];
        reduivy__Transaction_Payment__c payment2 = updatedPayments[0].Id == transactionPayment2.Id ? 
            updatedPayments[0] : updatedPayments[1];
        
        System.assertEquals(0.00, payment1.reduivy__Applied_Amount__c, 
            'First payment applied amount should be 0.00');
        System.assertEquals(70.00, payment2.reduivy__Applied_Amount__c, 
            'Second payment applied amount should be 70.00');
    }

    /**
     * @description Test executeAfterUpdate when old parent needs rollup due to parent change as Admin
     */
    @IsTest 
    static void testExecuteAfterUpdateOldParentNeedsRollupAsAdmin() {
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
        
        // Create first transaction payment
        reduivy__Transaction_Payment__c transactionPayment1 = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment1;
        
        // Create second transaction payment
        reduivy__Transaction_Payment__c transactionPayment2 = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment2;
        
        // Create two monetary entries linked to first payment
        reduivy__Transaction_Line_Item__c monetaryEntry1 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment1.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            40.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        
        reduivy__Transaction_Line_Item__c monetaryEntry2 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment1.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            30.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        
        insert new List<reduivy__Transaction_Line_Item__c>{monetaryEntry1, monetaryEntry2};
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Move one entry to second payment
            monetaryEntry1.reduivy__Transaction_Payment__c = transactionPayment2.Id;
            update monetaryEntry1;
            
            Test.stopTest();
        }
        
        // Assertions - Old parent should be recalculated, new parent should include moved entry
        List<reduivy__Transaction_Payment__c> updatedPayments = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id IN (:transactionPayment1.Id, :transactionPayment2.Id)
            ORDER BY Id
        ];
        
        reduivy__Transaction_Payment__c payment1 = updatedPayments[0].Id == transactionPayment1.Id ? 
            updatedPayments[0] : updatedPayments[1];
        reduivy__Transaction_Payment__c payment2 = updatedPayments[0].Id == transactionPayment2.Id ? 
            updatedPayments[0] : updatedPayments[1];
        
        System.assertEquals(30.00, payment1.reduivy__Applied_Amount__c, 
            'First payment should have remaining entry amount of 30.00');
        System.assertEquals(40.00, payment2.reduivy__Applied_Amount__c, 
            'Second payment should have moved entry amount of 40.00');
    }
	
    // ========== AFTER DELETE TESTS ==========

    /**
     * @description Test executeAfterDelete with non-monetary TRLs as Admin (no rollup)
     */
    @IsTest 
    static void testExecuteAfterDeleteNonMonetaryAsAdmin() {
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
        
        // Create non-monetary TRL (order line)
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert orderLine;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            delete orderLine;
            
            Test.stopTest();
        }
        
        // Assertions - No rollup should occur for non-monetary entries
        // Verify the record was deleted successfully
        List<reduivy__Transaction_Line_Item__c> deletedTrls = [
            SELECT Id 
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :orderLine.Id
            ALL ROWS
        ];
        
        System.assertEquals(1, deletedTrls.size(), 
            'TRL should be in recycle bin');
        
        // Since no transaction payment was involved, we just verify deletion was successful
        // No rollup assertions needed as this is non-monetary
    }

    /**
     * @description Test executeAfterDelete with deleted monetary TRL that had a parent as Admin
     */
    @IsTest 
    static void testExecuteAfterDeleteMonetaryEntryDeletedAsAdmin() {
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
        
        // Create transaction payment
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            200.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment;
        
        // Create two monetary entries linked to payment
        reduivy__Transaction_Line_Item__c monetaryEntry1 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            80.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        
        reduivy__Transaction_Line_Item__c monetaryEntry2 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            60.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        
        insert new List<reduivy__Transaction_Line_Item__c>{monetaryEntry1, monetaryEntry2};
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Delete one monetary entry
            delete monetaryEntry1;
            
            Test.stopTest();
        }
        
        // Assertions - Applied amount should be recalculated without deleted entry
        reduivy__Transaction_Payment__c updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(60.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be recalculated to 60.00 (remaining entry only)');
        
        // Verify the record was deleted
        List<reduivy__Transaction_Line_Item__c> deletedTrls = [
            SELECT Id 
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :monetaryEntry1.Id
            ALL ROWS
        ];
        
        System.assertEquals(1, deletedTrls.size(), 
            'Deleted TRL should be in recycle bin');
    }

    // ========== AFTER UNDELETE TESTS ==========

    /**
     * @description Test executeAfterUndelete with non-monetary TRLs as Admin (no rollup)
     */
    @IsTest 
    static void testExecuteAfterUndeleteNonMonetaryAsAdmin() {
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
        
        // Create non-monetary TRL (order line)
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert orderLine;

        System.runAs(ADMIN_USER) {
        
            // Delete the record first
            delete orderLine;

            Test.startTest();
            
            // Undelete the record
            undelete orderLine;
            
            Test.stopTest();
        }
        
        // Assertions - No rollup should occur for non-monetary entries
        // Verify the record was restored successfully
        reduivy__Transaction_Line_Item__c restoredTrl = [
            SELECT Id, reduivy__Transaction_Type__c, reduivy__Total_Amount__c, reduivy__Item_Name__c
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :orderLine.Id
        ];
        
        System.assertEquals(TRL_Helper.TRANSACTION_TYPE_ORDERLINE, restoredTrl.reduivy__Transaction_Type__c, 
            'Restored TRL should be of order line type');
        System.assertEquals(100.00, restoredTrl.reduivy__Total_Amount__c, 
            'Restored TRL amount should be 100.00');
        System.assertEquals('Test Fee Item', restoredTrl.reduivy__Item_Name__c, 
            'Restored TRL should have original item name');
    }

    /**
     * @description Test executeAfterUndelete with restored monetary TRL linked to payment as Admin
     */
    @IsTest 
    static void testExecuteAfterUndeleteMonetaryEntryRestoredAsAdmin() {
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
        
        // Create transaction payment
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            200.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment;
        
        // Create two monetary entries linked to payment
        reduivy__Transaction_Line_Item__c monetaryEntry1 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            90.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        
        reduivy__Transaction_Line_Item__c monetaryEntry2 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            50.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        
        insert new List<reduivy__Transaction_Line_Item__c>{monetaryEntry1, monetaryEntry2};
        
        System.runAs(ADMIN_USER) {
            // Delete one monetary entry
            delete monetaryEntry1;
            
            // Verify applied amount after deletion (should be 50.00)
            reduivy__Transaction_Payment__c paymentAfterDelete = [
                SELECT Id, reduivy__Applied_Amount__c
                FROM reduivy__Transaction_Payment__c 
                WHERE Id = :transactionPayment.Id
            ];
            System.assertEquals(50.00, paymentAfterDelete.reduivy__Applied_Amount__c, 
                'Applied amount should be 50.00 after deletion');

            Test.startTest();
            
            // Undelete the monetary entry
            undelete monetaryEntry1;
            
            Test.stopTest();
        }
        
        // Assertions - Applied amount should be recalculated with restored entry
        reduivy__Transaction_Payment__c updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(140.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be recalculated to 140.00 (both entries restored)');
        
        // Verify the record was restored successfully
        reduivy__Transaction_Line_Item__c restoredTrl = [
            SELECT Id, reduivy__Transaction_Type__c, reduivy__Total_Amount__c, 
                reduivy__Item_Name__c, reduivy__Transaction_Payment__c
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :monetaryEntry1.Id
        ];
        
        System.assertEquals(TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY, restoredTrl.reduivy__Transaction_Type__c, 
            'Restored TRL should be of monetary entry type');
        System.assertEquals(90.00, restoredTrl.reduivy__Total_Amount__c, 
            'Restored TRL amount should be 90.00');
        System.assertEquals(transactionPayment.Id, restoredTrl.reduivy__Transaction_Payment__c, 
            'Restored TRL should be linked to original payment');
        System.assertEquals('Test Payment 1', restoredTrl.reduivy__Item_Name__c, 
            'Restored TRL should have original item name');
    }

    //Student
    // ========== AFTER INSERT TESTS ==========

    /**
     * @description Test executeAfterInsert with non-monetary TRLs as Student (no rollup)
     */
    @IsTest 
    static void testExecuteAfterInsertNonMonetaryAsStudent() {

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
        
        // Create non-monetary TRL (order line)
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        
        System.runAs(studentUser) {
            Test.startTest();
            
            insert orderLine;
            
            Test.stopTest();
        }
        
        // Assertions - No rollup should occur for non-monetary entries
        // Since no transaction payment was created, we just verify the record was inserted successfully
        reduivy__Transaction_Line_Item__c insertedTrl = [
            SELECT Id, reduivy__Transaction_Type__c, reduivy__Total_Amount__c
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :orderLine.Id
        ];
        
        System.assertEquals(TRL_Helper.TRANSACTION_TYPE_ORDERLINE, insertedTrl.reduivy__Transaction_Type__c, 
            'TRL should be of order line type');
        System.assertEquals(100.00, insertedTrl.reduivy__Total_Amount__c, 
            'TRL amount should be 100.00');
    }

    /**
     * @description Test executeAfterInsert with new monetary TRLs linked to payment as Student
     */
    @IsTest 
    static void testExecuteAfterInsertNewMonetaryEntryAsStudent() {
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
        
        // Create transaction payment
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount - should be updated by rollup
            null    // applicableItemType
        );
        insert transactionPayment;
        
        // Create monetary entry linked to payment
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            50.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        
        System.runAs(studentUser) {
            Test.startTest();
            
            insert monetaryEntry;
            
            Test.stopTest();
        }
        
        // Assertions - Applied amount should be rolled up to transaction payment
        reduivy__Transaction_Payment__c updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(50.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be rolled up to 50.00');
    }

    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test executeAfterUpdate with no monetary type or relevant changes as Student
     */
    @IsTest 
    static void testExecuteAfterUpdateNoRelevantChangeAsStudent() {
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
        
        // Create non-monetary TRL (order line)
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert orderLine;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Update non-relevant field
            orderLine.reduivy__Item_Name__c = 'Updated Item Name';
            update orderLine;
            
            Test.stopTest();
        }
        
        // Assertions - No rollup should occur
        reduivy__Transaction_Line_Item__c updatedTrl = [
            SELECT Id, reduivy__Item_Name__c, reduivy__Total_Amount__c
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :orderLine.Id
        ];
        
        System.assertEquals('Updated Item Name', updatedTrl.reduivy__Item_Name__c, 
            'Item name should be updated');
        System.assertEquals(100.00, updatedTrl.reduivy__Total_Amount__c, 
            'Amount should remain unchanged');
    }

    /**
     * @description Test executeAfterUpdate when TRL changes from non-monetary to monetary as Student
     */
    @IsTest 
    static void testExecuteAfterUpdateBecameMonetaryAsStudent() {
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
        
        // Create transaction payment
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment;
        
        // Create non-monetary TRL first
        reduivy__Transaction_Line_Item__c trl = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            75.00, // totalAmount
            0.00,  // offsetAmount
            75.00  // outstandingAmount
        );
        insert trl;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Change to monetary entry and link to payment
            trl.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY;
            trl.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            trl.reduivy__Transaction_Payment__c = transactionPayment.Id;
            update trl;
            
            Test.stopTest();
        }
        
        // Assertions - Applied amount should be rolled up
        reduivy__Transaction_Payment__c updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(75.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be rolled up to 75.00');
    }

    /**
     * @description Test executeAfterUpdate when TRL changes from monetary to non-monetary as Student
     */
    @IsTest 
    static void testExecuteAfterUpdateBecameNonMonetaryAsStudent() {
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
        
        // Create transaction payment
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment;
        
        // Create monetary entry first
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            80.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Change to non-monetary type
            monetaryEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            monetaryEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_DEBIT;
            update monetaryEntry;
            
            Test.stopTest();
        }
        
        // Assertions - Applied amount should be recalculated (should be 0)
        reduivy__Transaction_Payment__c updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(0.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be recalculated to 0.00');
    }

    /**
     * @description Test executeAfterUpdate when monetary TRL amount changes as Student
     */
    @IsTest 
    static void testExecuteAfterUpdateAmountChangedAsStudent() {
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

        // Create transaction payment
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment;

        // Create monetary entry
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            60.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;

        reduivy__Transaction_Payment__c updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];

        System.assertEquals(60.00, updatedPayment.reduivy__Applied_Amount__c, 
                'Applied amount should be updated to 60.00');

        System.runAs(studentUser) {

            Test.startTest();
            
            // Change the amount
            monetaryEntry.reduivy__Unit_Price__c = 90.00;
            update monetaryEntry;
            
            Test.stopTest();
        }
        
        // Assertions - Applied amount should be updated
        updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(90.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be updated to 90.00');
    }

    /**
     * @description Test executeAfterUpdate when monetary TRL parent changes as Student
     */
    @IsTest 
    static void testExecuteAfterUpdateParentChangedAsStudent() {
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
        
        // Create first transaction payment
        reduivy__Transaction_Payment__c transactionPayment1 = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment1;
        
        // Create second transaction payment
        reduivy__Transaction_Payment__c transactionPayment2 = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment2;
        
        // Create monetary entry linked to first payment
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment1.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            70.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Change parent to second payment
            monetaryEntry.reduivy__Transaction_Payment__c = transactionPayment2.Id;
            update monetaryEntry;
            
            Test.stopTest();
        }
        
        // Assertions - Both payments should be updated
        List<reduivy__Transaction_Payment__c> updatedPayments = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id IN (:transactionPayment1.Id, :transactionPayment2.Id)
            ORDER BY Id
        ];
        
        reduivy__Transaction_Payment__c payment1 = updatedPayments[0].Id == transactionPayment1.Id ? 
            updatedPayments[0] : updatedPayments[1];
        reduivy__Transaction_Payment__c payment2 = updatedPayments[0].Id == transactionPayment2.Id ? 
            updatedPayments[0] : updatedPayments[1];
        
        System.assertEquals(0.00, payment1.reduivy__Applied_Amount__c, 
            'First payment applied amount should be 0.00');
        System.assertEquals(70.00, payment2.reduivy__Applied_Amount__c, 
            'Second payment applied amount should be 70.00');
    }

    /**
     * @description Test executeAfterUpdate when old parent needs rollup due to parent change as Student
     */
    @IsTest 
    static void testExecuteAfterUpdateOldParentNeedsRollupAsStudent() {
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
        
        // Create first transaction payment
        reduivy__Transaction_Payment__c transactionPayment1 = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment1;
        
        // Create second transaction payment
        reduivy__Transaction_Payment__c transactionPayment2 = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment2;
        
        // Create two monetary entries linked to first payment
        reduivy__Transaction_Line_Item__c monetaryEntry1 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment1.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            40.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        
        reduivy__Transaction_Line_Item__c monetaryEntry2 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment1.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            30.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        
        insert new List<reduivy__Transaction_Line_Item__c>{monetaryEntry1, monetaryEntry2};
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Move one entry to second payment
            monetaryEntry1.reduivy__Transaction_Payment__c = transactionPayment2.Id;
            update monetaryEntry1;
            
            Test.stopTest();
        }
        
        // Assertions - Old parent should be recalculated, new parent should include moved entry
        List<reduivy__Transaction_Payment__c> updatedPayments = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id IN (:transactionPayment1.Id, :transactionPayment2.Id)
            ORDER BY Id
        ];
        
        reduivy__Transaction_Payment__c payment1 = updatedPayments[0].Id == transactionPayment1.Id ? 
            updatedPayments[0] : updatedPayments[1];
        reduivy__Transaction_Payment__c payment2 = updatedPayments[0].Id == transactionPayment2.Id ? 
            updatedPayments[0] : updatedPayments[1];
        
        System.assertEquals(30.00, payment1.reduivy__Applied_Amount__c, 
            'First payment should have remaining entry amount of 30.00');
        System.assertEquals(40.00, payment2.reduivy__Applied_Amount__c, 
            'Second payment should have moved entry amount of 40.00');
    }
	
    // ========== AFTER DELETE TESTS ==========

    /**
     * @description Test executeAfterDelete with non-monetary TRLs as Student (no rollup)
     */
    @IsTest 
    static void testExecuteAfterDeleteNonMonetaryAsStudent() {
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
        
        // Create non-monetary TRL (order line)
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        
        System.runAs(studentUser) {
            insert orderLine;

            Test.startTest();
            
            delete orderLine;
            
            Test.stopTest();
        }
        
        // Assertions - No rollup should occur for non-monetary entries
        // Verify the record was deleted successfully
        List<reduivy__Transaction_Line_Item__c> deletedTrls = [
            SELECT Id 
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :orderLine.Id
            ALL ROWS
        ];
        
        System.assertEquals(1, deletedTrls.size(), 
            'TRL should be in recycle bin');
        
        // Since no transaction payment was involved, we just verify deletion was successful
        // No rollup assertions needed as this is non-monetary
    }

    /**
     * @description Test executeAfterDelete with deleted monetary TRL that had a parent as Student
     */
    @IsTest 
    static void testExecuteAfterDeleteMonetaryEntryDeletedAsStudent() {
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
        
        // Create transaction payment
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            200.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment;
        
        // Create two monetary entries linked to payment
        reduivy__Transaction_Line_Item__c monetaryEntry1 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            80.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        
        reduivy__Transaction_Line_Item__c monetaryEntry2 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            60.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        
        System.runAs(studentUser) {
            insert new List<reduivy__Transaction_Line_Item__c>{monetaryEntry1, monetaryEntry2};

            Test.startTest();
            
            // Delete one monetary entry
            delete monetaryEntry1;
            
            Test.stopTest();
        }
        
        // Assertions - Applied amount should be recalculated without deleted entry
        reduivy__Transaction_Payment__c updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(60.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be recalculated to 60.00 (remaining entry only)');
        
        // Verify the record was deleted
        List<reduivy__Transaction_Line_Item__c> deletedTrls = [
            SELECT Id 
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :monetaryEntry1.Id
            ALL ROWS
        ];
        
        System.assertEquals(1, deletedTrls.size(), 
            'Deleted TRL should be in recycle bin');
    }

    // ========== AFTER UNDELETE TESTS ==========

    /**
     * @description Test executeAfterUndelete with non-monetary TRLs as Student (no rollup)
     */
    @IsTest 
    static void testExecuteAfterUndeleteNonMonetaryAsStudent() {
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
        
        // Create non-monetary TRL (order line)
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );

        System.runAs(studentUser) {
            insert orderLine;
            
            // Delete the record first
            delete orderLine;

            Test.startTest();
            
            // Undelete the record
            undelete orderLine;
            
            Test.stopTest();
        }
        
        // Assertions - No rollup should occur for non-monetary entries
        // Verify the record was restored successfully
        reduivy__Transaction_Line_Item__c restoredTrl = [
            SELECT Id, reduivy__Transaction_Type__c, reduivy__Total_Amount__c, reduivy__Item_Name__c
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :orderLine.Id
        ];
        
        System.assertEquals(TRL_Helper.TRANSACTION_TYPE_ORDERLINE, restoredTrl.reduivy__Transaction_Type__c, 
            'Restored TRL should be of order line type');
        System.assertEquals(100.00, restoredTrl.reduivy__Total_Amount__c, 
            'Restored TRL amount should be 100.00');
        System.assertEquals('Test Fee Item', restoredTrl.reduivy__Item_Name__c, 
            'Restored TRL should have original item name');
    }

    /**
     * @description Test executeAfterUndelete with restored monetary TRL linked to payment as Student
     */
    @IsTest 
    static void testExecuteAfterUndeleteMonetaryEntryRestoredAsStudent() {
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
        
        // Create transaction payment
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            200.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment;
        
        // Create two monetary entries linked to payment
        reduivy__Transaction_Line_Item__c monetaryEntry1 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            90.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        
        reduivy__Transaction_Line_Item__c monetaryEntry2 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            50.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        
        System.runAs(studentUser) {
            insert new List<reduivy__Transaction_Line_Item__c>{monetaryEntry1, monetaryEntry2};

            // Delete one monetary entry
            delete monetaryEntry1;
            
            // Verify applied amount after deletion (should be 50.00)
            reduivy__Transaction_Payment__c paymentAfterDelete = [
                SELECT Id, reduivy__Applied_Amount__c
                FROM reduivy__Transaction_Payment__c 
                WHERE Id = :transactionPayment.Id
            ];
            System.assertEquals(50.00, paymentAfterDelete.reduivy__Applied_Amount__c, 
                'Applied amount should be 50.00 after deletion');

            Test.startTest();
            
            // Undelete the monetary entry
            undelete monetaryEntry1;
            
            Test.stopTest();
        }
        
        // Assertions - Applied amount should be recalculated with restored entry
        reduivy__Transaction_Payment__c updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(140.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be recalculated to 140.00 (both entries restored)');
        
        // Verify the record was restored successfully
        reduivy__Transaction_Line_Item__c restoredTrl = [
            SELECT Id, reduivy__Transaction_Type__c, reduivy__Total_Amount__c, 
                reduivy__Item_Name__c, reduivy__Transaction_Payment__c
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :monetaryEntry1.Id
        ];
        
        System.assertEquals(TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY, restoredTrl.reduivy__Transaction_Type__c, 
            'Restored TRL should be of monetary entry type');
        System.assertEquals(90.00, restoredTrl.reduivy__Total_Amount__c, 
            'Restored TRL amount should be 90.00');
        System.assertEquals(transactionPayment.Id, restoredTrl.reduivy__Transaction_Payment__c, 
            'Restored TRL should be linked to original payment');
        System.assertEquals('Test Payment 1', restoredTrl.reduivy__Item_Name__c, 
            'Restored TRL should have original item name');
    }

    //Faculty
    /**
     * @description Test executeAfterInsert with non-monetary TRLs as Faculty (no rollup)
     */
    @IsTest 
    static void testExecuteAfterInsertNonMonetaryAsFaculty() {
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
        
        // Create non-monetary TRL (order line)
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            insert orderLine;
            
            Test.stopTest();
        }
        
        // Assertions - No rollup should occur for non-monetary entries
        // Since no transaction payment was created, we just verify the record was inserted successfully
        reduivy__Transaction_Line_Item__c insertedTrl = [
            SELECT Id, reduivy__Transaction_Type__c, reduivy__Total_Amount__c
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :orderLine.Id
        ];
        
        System.assertEquals(TRL_Helper.TRANSACTION_TYPE_ORDERLINE, insertedTrl.reduivy__Transaction_Type__c, 
            'TRL should be of order line type');
        System.assertEquals(100.00, insertedTrl.reduivy__Total_Amount__c, 
            'TRL amount should be 100.00');
    }

    /**
     * @description Test executeAfterInsert with new monetary TRLs linked to payment as Faculty
     */
    @IsTest 
    static void testExecuteAfterInsertNewMonetaryEntryAsFaculty() {
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
        
        // Create transaction payment
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount - should be updated by rollup
            null    // applicableItemType
        );
        insert transactionPayment;
        
        // Create monetary entry linked to payment
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            50.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            insert monetaryEntry;
            
            Test.stopTest();
        }
        
        // Assertions - Applied amount should be rolled up to transaction payment
        reduivy__Transaction_Payment__c updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(50.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be rolled up to 50.00');
    }

    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test executeAfterUpdate with no monetary type or relevant changes as Faculty
     */
    @IsTest 
    static void testExecuteAfterUpdateNoRelevantChangeAsFaculty() {
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
        
        // Create non-monetary TRL (order line)
        reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Fee Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            100.00, // totalAmount
            0.00,   // offsetAmount
            100.00  // outstandingAmount
        );
        insert orderLine;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Update non-relevant field
            orderLine.reduivy__Item_Name__c = 'Updated Item Name';
            update orderLine;
            
            Test.stopTest();
        }
        
        // Assertions - No rollup should occur
        reduivy__Transaction_Line_Item__c updatedTrl = [
            SELECT Id, reduivy__Item_Name__c, reduivy__Total_Amount__c
            FROM reduivy__Transaction_Line_Item__c 
            WHERE Id = :orderLine.Id
        ];
        
        System.assertEquals('Updated Item Name', updatedTrl.reduivy__Item_Name__c, 
            'Item name should be updated');
        System.assertEquals(100.00, updatedTrl.reduivy__Total_Amount__c, 
            'Amount should remain unchanged');
    }

    /**
     * @description Test executeAfterUpdate when TRL changes from non-monetary to monetary as Faculty
     */
    @IsTest 
    static void testExecuteAfterUpdateBecameMonetaryAsFaculty() {
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
        
        // Create transaction payment
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment;
        
        // Create non-monetary TRL first
        reduivy__Transaction_Line_Item__c trl = REDU_TestData_UTIL.newTransactionOrderLine(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            null, // studyFeeMatrixItemId
            'Test Item',
            TRL_Helper.ITEM_TYPE_TUITION,
            75.00, // totalAmount
            0.00,  // offsetAmount
            75.00  // outstandingAmount
        );
        insert trl;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Change to monetary entry and link to payment
            trl.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY;
            trl.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            trl.reduivy__Transaction_Payment__c = transactionPayment.Id;
            update trl;
            
            Test.stopTest();
        }
        
        // Assertions - Applied amount should be rolled up
        reduivy__Transaction_Payment__c updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(75.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be rolled up to 75.00');
    }

    /**
     * @description Test executeAfterUpdate when TRL changes from monetary to non-monetary as Faculty
     */
    @IsTest 
    static void testExecuteAfterUpdateBecameNonMonetaryAsFaculty() {
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
        
        // Create transaction payment
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment;
        
        // Create monetary entry first
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            80.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Change to non-monetary type
            monetaryEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            monetaryEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_DEBIT;
            update monetaryEntry;
            
            Test.stopTest();
        }
        
        // Assertions - Applied amount should be recalculated (should be 0)
        reduivy__Transaction_Payment__c updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(0.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be recalculated to 0.00');
    }

    /**
     * @description Test executeAfterUpdate when monetary TRL amount changes as Faculty
     */
    @IsTest 
    static void testExecuteAfterUpdateAmountChangedAsFaculty() {
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
        
        // Create transaction payment
        reduivy__Transaction_Payment__c transactionPayment = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment;
        
        // Create monetary entry
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            60.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;

        reduivy__Transaction_Payment__c updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(60.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be updated to 60.00');
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Change the amount
            monetaryEntry.reduivy__Unit_Price__c = 90.00;
            update monetaryEntry;
            
            Test.stopTest();
        }
        
        // Assertions - Applied amount should be updated
        updatedPayment = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :transactionPayment.Id
        ];
        
        System.assertEquals(90.00, updatedPayment.reduivy__Applied_Amount__c, 
            'Applied amount should be updated to 90.00');
    }

    /**
     * @description Test executeAfterUpdate when monetary TRL parent changes as Faculty
     */
    @IsTest 
    static void testExecuteAfterUpdateParentChangedAsFaculty() {
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
        
        // Create first transaction payment
        reduivy__Transaction_Payment__c transactionPayment1 = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment1;
        
        // Create second transaction payment
        reduivy__Transaction_Payment__c transactionPayment2 = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment2;
        
        // Create monetary entry linked to first payment
        reduivy__Transaction_Line_Item__c monetaryEntry = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment1.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment',
            TRL_Helper.ITEM_TYPE_TUITION,
            70.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        insert monetaryEntry;
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Change parent to second payment
            monetaryEntry.reduivy__Transaction_Payment__c = transactionPayment2.Id;
            update monetaryEntry;
            
            Test.stopTest();
        }
        
        // Assertions - Both payments should be updated
        List<reduivy__Transaction_Payment__c> updatedPayments = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id IN (:transactionPayment1.Id, :transactionPayment2.Id)
            ORDER BY Id
        ];
        
        reduivy__Transaction_Payment__c payment1 = updatedPayments[0].Id == transactionPayment1.Id ? 
            updatedPayments[0] : updatedPayments[1];
        reduivy__Transaction_Payment__c payment2 = updatedPayments[0].Id == transactionPayment2.Id ? 
            updatedPayments[0] : updatedPayments[1];
        
        System.assertEquals(0.00, payment1.reduivy__Applied_Amount__c, 
            'First payment applied amount should be 0.00');
        System.assertEquals(70.00, payment2.reduivy__Applied_Amount__c, 
            'Second payment applied amount should be 70.00');
    }

    /**
     * @description Test executeAfterUpdate when old parent needs rollup due to parent change as Faculty
     */
    @IsTest 
    static void testExecuteAfterUpdateOldParentNeedsRollupAsFaculty() {
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
        
        // Create first transaction payment
        reduivy__Transaction_Payment__c transactionPayment1 = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment1;
        
        // Create second transaction payment
        reduivy__Transaction_Payment__c transactionPayment2 = REDU_TestData_UTIL.newTransactionPayment(
            studentContact.reduivy__Sample_Record_Code__c,
            studentContact.Id,
            transactionOrder.Id,
            TRP_Helper.TRANSACTION_TYPE_PAYMENT,
            null, // idvFundingAllocationId
            100.00, // amount
            0.00,   // appliedAmount
            null    // applicableItemType
        );
        insert transactionPayment2;
        
        // Create two monetary entries linked to first payment
        reduivy__Transaction_Line_Item__c monetaryEntry1 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment1.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 1',
            TRL_Helper.ITEM_TYPE_TUITION,
            40.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        
        reduivy__Transaction_Line_Item__c monetaryEntry2 = REDU_TestData_UTIL.newTransactionMonetaryEntry(
            studentContact.reduivy__Sample_Record_Code__c,
            transactionOrder.Id,
            transactionPayment1.Id, // transactionPaymentId
            null, // offsetLineItemId
            null, // idvFundingAllocationId
            'Test Payment 2',
            TRL_Helper.ITEM_TYPE_TUITION,
            30.00, // totalAmount
            0.00,  // offsetAmount
            0.00   // outstandingAmount
        );
        
        insert new List<reduivy__Transaction_Line_Item__c>{monetaryEntry1, monetaryEntry2};
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Move one entry to second payment
            monetaryEntry1.reduivy__Transaction_Payment__c = transactionPayment2.Id;
            update monetaryEntry1;
            
            Test.stopTest();
        }
        
        // Assertions - Old parent should be recalculated, new parent should include moved entry
        List<reduivy__Transaction_Payment__c> updatedPayments = [
            SELECT Id, reduivy__Applied_Amount__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id IN (:transactionPayment1.Id, :transactionPayment2.Id)
            ORDER BY Id
        ];
        
        reduivy__Transaction_Payment__c payment1 = updatedPayments[0].Id == transactionPayment1.Id ? 
            updatedPayments[0] : updatedPayments[1];
        reduivy__Transaction_Payment__c payment2 = updatedPayments[0].Id == transactionPayment2.Id ? 
            updatedPayments[0] : updatedPayments[1];
        
        System.assertEquals(30.00, payment1.reduivy__Applied_Amount__c, 
            'First payment should have remaining entry amount of 30.00');
        System.assertEquals(40.00, payment2.reduivy__Applied_Amount__c, 
            'Second payment should have moved entry amount of 40.00');
    }
}