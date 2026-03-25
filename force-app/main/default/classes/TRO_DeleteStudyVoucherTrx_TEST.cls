/**
 * @author      WDCi (XiRouh)
 * @date        Aug 2025
 * @group       Test
 * @description Test class for TRO_DeleteStudyVoucherTrx_EXE
 * @changehistory
 * ISS-002566 20-08-2025 XiRouh - new class
 */
@IsTest
public inherited sharing class TRO_DeleteStudyVoucherTrx_TEST {

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
        	
            testFactory.initMasterData(SVO_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test single Transaction Order deletion deletes related Study Voucher Transaction as Admin
     */
    @IsTest
    static void testSingleTransactionOrderDeletionDeletesStudyVoucherTransactionAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            // Create Transaction Order
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                'TEST_TO_001', 
                conStudent.Id, 
                null, 
                Date.today(), 
                TRO_Helper.STATUS_TYPE_DRAFT, 
                1000.00, 
                1000.00, 
                0.00
            );
            insert transactionOrder;
            
            // Create Study Voucher Transaction linked to the Transaction Order
            reduivy__Study_Voucher_Transaction__c studyVoucherTransaction = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'TEST_SVT_001',
                studyVoucher.Id,
                transactionOrder.Id,
                SVT_Helper.STATUS_DRAFT
            );
            insert studyVoucherTransaction;
            
            // Verify Study Voucher Transaction exists before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            
            // Delete Transaction Order
            delete transactionOrder;
            
            // Assertions - Study Voucher Transaction should be deleted
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            
            System.assertEquals(1, svtBeforeDeletion.size(), 'Study Voucher Transaction should exist before Transaction Order deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'Study Voucher Transaction should be deleted when Transaction Order is deleted');
        }
    }

    /**
     * @description Test multiple Transaction Orders deletion deletes all related Study Voucher Transactions as Admin
     */
    @IsTest
    static void testMultipleTransactionOrdersDeletionDeletesAllRelatedStudyVoucherTransactionsAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            // Create multiple Transaction Orders
            List<reduivy__Transaction_Order__c> transactionOrders = new List<reduivy__Transaction_Order__c>();
            for(Integer i = 0; i < 3; i++) {
                transactionOrders.add(REDU_TestData_UTIL.newTransactionOrder(
                    'TEST_TO_00' + i, 
                    conStudent.Id, 
                    null, 
                    Date.today(), 
                    TRO_Helper.STATUS_TYPE_DRAFT, 
                    1000.00, 
                    1000.00, 
                    0.00
                ));
            }
            insert transactionOrders;
            
            // Create Study Voucher Transactions for each Transaction Order
            List<reduivy__Study_Voucher_Transaction__c> studyVoucherTransactions = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < transactionOrders.size(); i++) {
                studyVoucherTransactions.add(REDU_TestData_UTIL.newStudyVoucherTransaction(
                    'TEST_SVT_00' + i,
                    studyVoucher.Id,
                    transactionOrders[i].Id,
                    SVT_Helper.STATUS_DRAFT
                ));
            }
            insert studyVoucherTransactions;
            
            // Verify Study Voucher Transactions exist before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c IN :transactionOrders
            ];
            
            // Delete Transaction Orders
            delete transactionOrders;
            
            // Assertions - All Study Voucher Transactions should be deleted
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c IN :transactionOrders
            ];
            
            System.assertEquals(3, svtBeforeDeletion.size(), 'All Study Voucher Transactions should exist before Transaction Orders deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'All Study Voucher Transactions should be deleted when Transaction Orders are deleted');
        }
    }

    /**
     * @description Test Transaction Order with multiple Study Voucher Transactions deletion as Admin
     */
    @IsTest
    static void testTransactionOrderWithMultipleStudyVoucherTransactionsDeletionAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            // Create Transaction Order
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                'TEST_TO_001', 
                conStudent.Id, 
                null, 
                Date.today(), 
                TRO_Helper.STATUS_TYPE_DRAFT, 
                3000.00, 
                3000.00, 
                0.00
            );
            insert transactionOrder;
            
            // Create multiple Study Voucher Transactions linked to the same Transaction Order
            List<reduivy__Study_Voucher_Transaction__c> studyVoucherTransactions = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 3; i++) {
                studyVoucherTransactions.add(REDU_TestData_UTIL.newStudyVoucherTransaction(
                    'TEST_SVT_00' + i,
                    studyVoucher.Id,
                    transactionOrder.Id,
                    SVT_Helper.STATUS_DRAFT
                ));
            }
            insert studyVoucherTransactions;
            
            // Verify Study Voucher Transactions exist before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            
            // Delete Transaction Order
            delete transactionOrder;
            
            // Assertions - All Study Voucher Transactions should be deleted
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            
            System.assertEquals(3, svtBeforeDeletion.size(), 'Multiple Study Voucher Transactions should exist before Transaction Order deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'All Study Voucher Transactions should be deleted when Transaction Order is deleted');
        }
    }

    /**
     * @description Test Transaction Order deletion deletes Study Voucher Transaction linked with discount line as Admin
     */
    @IsTest
    static void testTransactionOrderDeletionDeletesStudyVoucherTransactionLinkedWithDiscountLineAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            // Create Transaction Order
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                'TEST_TO_001', 
                conStudent.Id, 
                null, 
                Date.today(), 
                TRO_Helper.STATUS_TYPE_DRAFT, 
                1000.00, 
                800.00, 
                0.00
            );
            insert transactionOrder;
            
            // Create Study Voucher Transaction
            reduivy__Study_Voucher_Transaction__c studyVoucherTransaction = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'TEST_SVT_001',
                studyVoucher.Id,
                transactionOrder.Id,
                SVT_Helper.STATUS_DRAFT
            );
            insert studyVoucherTransaction;
            
            // Create Transaction Order Line
            reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
                'TEST_TOL_001',
                transactionOrder.Id,
                null,
                'Tuition Fee',
                TRL_Helper.ITEM_TYPE_TUITION,
                1000.00,
                200.00,
                800.00
            );
            insert orderLine;
            
            // Create Transaction Discount Line linked to Study Voucher Transaction
            reduivy__Transaction_Line_Item__c discountLine = REDU_TestData_UTIL.newTransactionDiscountEntry(
                'TEST_TDL_001',
                transactionOrder.Id,
                'Study Voucher Discount',
                TRL_Helper.ITEM_TYPE_TUITION,
                200.00,
                null,
                studyVoucherTransaction.Id,
                null,
                null
            );
            insert discountLine;
            
            // Verify records exist before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :studyVoucherTransaction.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesBeforeDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c = :studyVoucherTransaction.Id
            ];
            
            // Delete Transaction Order
            delete transactionOrder;
            
            // Assertions
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :studyVoucherTransaction.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesAfterDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c = :studyVoucherTransaction.Id
            ];
            
            System.assertEquals(1, svtBeforeDeletion.size(), 'Study Voucher Transaction should exist before deletion');
            System.assertEquals(1, discountLinesBeforeDeletion.size(), 'Discount line should exist before deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'Study Voucher Transaction should be deleted');
            System.assertEquals(0, discountLinesAfterDeletion.size(), 'Discount line should be deleted with Transaction Order');
        }
    }

    /**
     * @description Test Transaction Order deletion with multiple Study Voucher Transactions linked to discount lines as Admin
     */
    @IsTest
    static void testTransactionOrderDeletionWithMultipleStudyVoucherTransactionsLinkedToDiscountLinesAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            // Create Transaction Order
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                'TEST_TO_001', 
                conStudent.Id, 
                null, 
                Date.today(), 
                TRO_Helper.STATUS_TYPE_DRAFT, 
                1000.00, 
                400.00, 
                0.00
            );
            insert transactionOrder;
            
            // Create multiple Study Voucher Transactions
            List<reduivy__Study_Voucher_Transaction__c> studyVoucherTransactions = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 3; i++) {
                studyVoucherTransactions.add(REDU_TestData_UTIL.newStudyVoucherTransaction(
                    'TEST_SVT_00' + i,
                    studyVoucher.Id,
                    transactionOrder.Id,
                    SVT_Helper.STATUS_DRAFT
                ));
            }
            insert studyVoucherTransactions;
            
            // Create Transaction Order Line
            reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
                'TEST_TOL_001',
                transactionOrder.Id,
                null,
                'Tuition Fee',
                TRL_Helper.ITEM_TYPE_TUITION,
                1000.00,
                600.00,
                400.00
            );
            insert orderLine;
            
            // Create Transaction Discount Lines for each Study Voucher Transaction
            List<reduivy__Transaction_Line_Item__c> discountLines = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < studyVoucherTransactions.size(); i++) {
                discountLines.add(REDU_TestData_UTIL.newTransactionDiscountEntry(
                    'TEST_TDL_00' + i,
                    transactionOrder.Id,
                    'Study Voucher Discount ' + i,
                    TRL_Helper.ITEM_TYPE_TUITION,
                    200.00,
                    null,
                    studyVoucherTransactions[i].Id,
                    null,
                    null
                ));
            }
            insert discountLines;
            
            // Verify records exist before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesBeforeDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c IN :studyVoucherTransactions
            ];
            
            // Delete Transaction Order
            delete transactionOrder;
            
            // Assertions
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesAfterDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c IN :studyVoucherTransactions
            ];
            
            System.assertEquals(3, svtBeforeDeletion.size(), 'Multiple Study Voucher Transactions should exist before deletion');
            System.assertEquals(3, discountLinesBeforeDeletion.size(), 'Multiple discount lines should exist before deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'All Study Voucher Transactions should be deleted');
            System.assertEquals(0, discountLinesAfterDeletion.size(), 'All discount lines should be deleted with Transaction Order');
        }
    }

    /**
     * @description Test Transaction Order deletion with Study Voucher Transaction linked to multiple discount lines as Admin
     */
    @IsTest
    static void testTransactionOrderDeletionWithStudyVoucherTransactionLinkedToMultipleDiscountLinesAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            // Create Transaction Order
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                'TEST_TO_001', 
                conStudent.Id, 
                null, 
                Date.today(), 
                TRO_Helper.STATUS_TYPE_DRAFT, 
                1000.00, 
                400.00, 
                0.00
            );
            insert transactionOrder;
            
            // Create Study Voucher Transaction
            reduivy__Study_Voucher_Transaction__c studyVoucherTransaction = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'TEST_SVT_001',
                studyVoucher.Id,
                transactionOrder.Id,
                SVT_Helper.STATUS_DRAFT
            );
            insert studyVoucherTransaction;
            
            // Create Transaction Order Lines
            List<reduivy__Transaction_Line_Item__c> orderLines = new List<reduivy__Transaction_Line_Item__c>();
            orderLines.add(REDU_TestData_UTIL.newTransactionOrderLine(
                'TEST_TOL_001',
                transactionOrder.Id,
                null,
                'Tuition Fee',
                TRL_Helper.ITEM_TYPE_TUITION,
                700.00,
                400.00,
                300.00
            ));
            orderLines.add(REDU_TestData_UTIL.newTransactionOrderLine(
                'TEST_TOL_002',
                transactionOrder.Id,
                null,
                'Registration Fee',
                TRL_Helper.ITEM_TYPE_TUITION,
                300.00,
                200.00,
                100.00
            ));
            insert orderLines;
            
            // Create multiple Transaction Discount Lines linked to the same Study Voucher Transaction
            List<reduivy__Transaction_Line_Item__c> discountLines = new List<reduivy__Transaction_Line_Item__c>();
            discountLines.add(REDU_TestData_UTIL.newTransactionDiscountEntry(
                'TEST_TDL_001',
                transactionOrder.Id,
                'Study Voucher Discount 1',
                TRL_Helper.ITEM_TYPE_TUITION,
                400.00,
                null,
                studyVoucherTransaction.Id,
                null,
                null
            ));
            discountLines.add(REDU_TestData_UTIL.newTransactionDiscountEntry(
                'TEST_TDL_002',
                transactionOrder.Id,
                'Study Voucher Discount 2',
                TRL_Helper.ITEM_TYPE_TUITION,
                200.00,
                null,
                studyVoucherTransaction.Id,
                null,
                null
            ));
            insert discountLines;
            
            // Verify records exist before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :studyVoucherTransaction.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesBeforeDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c = :studyVoucherTransaction.Id
            ];
            
            // Delete Transaction Order
            delete transactionOrder;
            
            // Assertions
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :studyVoucherTransaction.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesAfterDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c = :studyVoucherTransaction.Id
            ];
            
            System.assertEquals(1, svtBeforeDeletion.size(), 'Study Voucher Transaction should exist before deletion');
            System.assertEquals(2, discountLinesBeforeDeletion.size(), 'Multiple discount lines should exist before deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'Study Voucher Transaction should be deleted');
            System.assertEquals(0, discountLinesAfterDeletion.size(), 'All discount lines should be deleted with Transaction Order');
        }
    }
	
    /**
     * @description Test single Transaction Order deletion deletes related Study Voucher Transaction as Faculty
     */
    @IsTest
    static void testSingleTransactionOrderDeletionDeletesStudyVoucherTransactionAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            // Create Transaction Order
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                'TEST_TO_001', 
                conStudent.Id, 
                null, 
                Date.today(), 
                TRO_Helper.STATUS_TYPE_DRAFT, 
                1000.00, 
                1000.00, 
                0.00
            );
            insert transactionOrder;
            
            // Create Study Voucher Transaction linked to the Transaction Order
            reduivy__Study_Voucher_Transaction__c studyVoucherTransaction = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'TEST_SVT_001',
                studyVoucher.Id,
                transactionOrder.Id,
                SVT_Helper.STATUS_DRAFT
            );
            insert studyVoucherTransaction;
            
            // Verify Study Voucher Transaction exists before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            
            // Delete Transaction Order
            delete transactionOrder;
            
            // Assertions - Study Voucher Transaction should be deleted
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            
            System.assertEquals(1, svtBeforeDeletion.size(), 'Study Voucher Transaction should exist before Transaction Order deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'Study Voucher Transaction should be deleted when Transaction Order is deleted');
        }
    }

    /**
     * @description Test multiple Transaction Orders deletion deletes all related Study Voucher Transactions as Faculty
     */
    @IsTest
    static void testMultipleTransactionOrdersDeletionDeletesAllRelatedStudyVoucherTransactionsAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            // Create multiple Transaction Orders
            List<reduivy__Transaction_Order__c> transactionOrders = new List<reduivy__Transaction_Order__c>();
            for(Integer i = 0; i < 3; i++) {
                transactionOrders.add(REDU_TestData_UTIL.newTransactionOrder(
                    'TEST_TO_00' + i, 
                    conStudent.Id, 
                    null, 
                    Date.today(), 
                    TRO_Helper.STATUS_TYPE_DRAFT, 
                    1000.00, 
                    1000.00, 
                    0.00
                ));
            }
            insert transactionOrders;
            
            // Create Study Voucher Transactions for each Transaction Order
            List<reduivy__Study_Voucher_Transaction__c> studyVoucherTransactions = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < transactionOrders.size(); i++) {
                studyVoucherTransactions.add(REDU_TestData_UTIL.newStudyVoucherTransaction(
                    'TEST_SVT_00' + i,
                    studyVoucher.Id,
                    transactionOrders[i].Id,
                    SVT_Helper.STATUS_DRAFT
                ));
            }
            insert studyVoucherTransactions;
            
            // Verify Study Voucher Transactions exist before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c IN :transactionOrders
            ];
            
            // Delete Transaction Orders
            delete transactionOrders;
            
            // Assertions - All Study Voucher Transactions should be deleted
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c IN :transactionOrders
            ];
            
            System.assertEquals(3, svtBeforeDeletion.size(), 'All Study Voucher Transactions should exist before Transaction Orders deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'All Study Voucher Transactions should be deleted when Transaction Orders are deleted');
        }
    }

    /**
     * @description Test Transaction Order with multiple Study Voucher Transactions deletion as Faculty
     */
    @IsTest
    static void testTransactionOrderWithMultipleStudyVoucherTransactionsDeletionAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            // Create Transaction Order
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                'TEST_TO_001', 
                conStudent.Id, 
                null, 
                Date.today(), 
                TRO_Helper.STATUS_TYPE_DRAFT, 
                3000.00, 
                3000.00, 
                0.00
            );
            insert transactionOrder;
            
            // Create multiple Study Voucher Transactions linked to the same Transaction Order
            List<reduivy__Study_Voucher_Transaction__c> studyVoucherTransactions = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 3; i++) {
                studyVoucherTransactions.add(REDU_TestData_UTIL.newStudyVoucherTransaction(
                    'TEST_SVT_00' + i,
                    studyVoucher.Id,
                    transactionOrder.Id,
                    SVT_Helper.STATUS_DRAFT
                ));
            }
            insert studyVoucherTransactions;
            
            // Verify Study Voucher Transactions exist before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            
            // Delete Transaction Order
            delete transactionOrder;
            
            // Assertions - All Study Voucher Transactions should be deleted
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            
            System.assertEquals(3, svtBeforeDeletion.size(), 'Multiple Study Voucher Transactions should exist before Transaction Order deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'All Study Voucher Transactions should be deleted when Transaction Order is deleted');
        }
    }

    /**
     * @description Test Transaction Order deletion deletes Study Voucher Transaction linked with discount line as Faculty
     */
    @IsTest
    static void testTransactionOrderDeletionDeletesStudyVoucherTransactionLinkedWithDiscountLineAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            // Create Transaction Order
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                'TEST_TO_001', 
                conStudent.Id, 
                null, 
                Date.today(), 
                TRO_Helper.STATUS_TYPE_DRAFT, 
                1000.00, 
                800.00, 
                0.00
            );
            insert transactionOrder;
            
            // Create Study Voucher Transaction
            reduivy__Study_Voucher_Transaction__c studyVoucherTransaction = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'TEST_SVT_001',
                studyVoucher.Id,
                transactionOrder.Id,
                SVT_Helper.STATUS_DRAFT
            );
            insert studyVoucherTransaction;
            
            // Create Transaction Order Line
            reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
                'TEST_TOL_001',
                transactionOrder.Id,
                null,
                'Tuition Fee',
                TRL_Helper.ITEM_TYPE_TUITION,
                1000.00,
                200.00,
                800.00
            );
            insert orderLine;
            
            // Create Transaction Discount Line linked to Study Voucher Transaction
            reduivy__Transaction_Line_Item__c discountLine = REDU_TestData_UTIL.newTransactionDiscountEntry(
                'TEST_TDL_001',
                transactionOrder.Id,
                'Study Voucher Discount',
                TRL_Helper.ITEM_TYPE_TUITION,
                200.00,
                null,
                studyVoucherTransaction.Id,
                null,
                null
            );
            insert discountLine;
            
            // Verify records exist before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :studyVoucherTransaction.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesBeforeDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c = :studyVoucherTransaction.Id
            ];
            
            // Delete Transaction Order
            delete transactionOrder;
            
            // Assertions
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :studyVoucherTransaction.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesAfterDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c = :studyVoucherTransaction.Id
            ];
            
            System.assertEquals(1, svtBeforeDeletion.size(), 'Study Voucher Transaction should exist before deletion');
            System.assertEquals(1, discountLinesBeforeDeletion.size(), 'Discount line should exist before deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'Study Voucher Transaction should be deleted');
            System.assertEquals(0, discountLinesAfterDeletion.size(), 'Discount line should be deleted with Transaction Order');
        }
    }

    /**
     * @description Test Transaction Order deletion with multiple Study Voucher Transactions linked to discount lines as Faculty
     */
    @IsTest
    static void testTransactionOrderDeletionWithMultipleStudyVoucherTransactionsLinkedToDiscountLinesAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            // Create Transaction Order
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                'TEST_TO_001', 
                conStudent.Id, 
                null, 
                Date.today(), 
                TRO_Helper.STATUS_TYPE_DRAFT, 
                1000.00, 
                400.00, 
                0.00
            );
            insert transactionOrder;
            
            // Create multiple Study Voucher Transactions
            List<reduivy__Study_Voucher_Transaction__c> studyVoucherTransactions = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 3; i++) {
                studyVoucherTransactions.add(REDU_TestData_UTIL.newStudyVoucherTransaction(
                    'TEST_SVT_00' + i,
                    studyVoucher.Id,
                    transactionOrder.Id,
                    SVT_Helper.STATUS_DRAFT
                ));
            }
            insert studyVoucherTransactions;
            
            // Create Transaction Order Line
            reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
                'TEST_TOL_001',
                transactionOrder.Id,
                null,
                'Tuition Fee',
                TRL_Helper.ITEM_TYPE_TUITION,
                1000.00,
                600.00,
                400.00
            );
            insert orderLine;
            
            // Create Transaction Discount Lines for each Study Voucher Transaction
            List<reduivy__Transaction_Line_Item__c> discountLines = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < studyVoucherTransactions.size(); i++) {
                discountLines.add(REDU_TestData_UTIL.newTransactionDiscountEntry(
                    'TEST_TDL_00' + i,
                    transactionOrder.Id,
                    'Study Voucher Discount ' + i,
                    TRL_Helper.ITEM_TYPE_TUITION,
                    200.00,
                    null,
                    studyVoucherTransactions[i].Id,
                    null,
                    null
                ));
            }
            insert discountLines;
            
            // Verify records exist before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesBeforeDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c IN :studyVoucherTransactions
            ];
            
            // Delete Transaction Order
            delete transactionOrder;
            
            // Assertions
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesAfterDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c IN :studyVoucherTransactions
            ];
            
            System.assertEquals(3, svtBeforeDeletion.size(), 'Multiple Study Voucher Transactions should exist before deletion');
            System.assertEquals(3, discountLinesBeforeDeletion.size(), 'Multiple discount lines should exist before deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'All Study Voucher Transactions should be deleted');
            System.assertEquals(0, discountLinesAfterDeletion.size(), 'All discount lines should be deleted with Transaction Order');
        }
    }

    /**
     * @description Test Transaction Order deletion with Study Voucher Transaction linked to multiple discount lines as Faculty
     */
    @IsTest
    static void testTransactionOrderDeletionWithStudyVoucherTransactionLinkedToMultipleDiscountLinesAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            // Create Transaction Order
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                'TEST_TO_001', 
                conStudent.Id, 
                null, 
                Date.today(), 
                TRO_Helper.STATUS_TYPE_DRAFT, 
                1000.00, 
                400.00, 
                0.00
            );
            insert transactionOrder;
            
            // Create Study Voucher Transaction
            reduivy__Study_Voucher_Transaction__c studyVoucherTransaction = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'TEST_SVT_001',
                studyVoucher.Id,
                transactionOrder.Id,
                SVT_Helper.STATUS_DRAFT
            );
            insert studyVoucherTransaction;
            
            // Create Transaction Order Lines
            List<reduivy__Transaction_Line_Item__c> orderLines = new List<reduivy__Transaction_Line_Item__c>();
            orderLines.add(REDU_TestData_UTIL.newTransactionOrderLine(
                'TEST_TOL_001',
                transactionOrder.Id,
                null,
                'Tuition Fee',
                TRL_Helper.ITEM_TYPE_TUITION,
                700.00,
                400.00,
                300.00
            ));
            orderLines.add(REDU_TestData_UTIL.newTransactionOrderLine(
                'TEST_TOL_002',
                transactionOrder.Id,
                null,
                'Registration Fee',
                TRL_Helper.ITEM_TYPE_TUITION,
                300.00,
                200.00,
                100.00
            ));
            insert orderLines;
            
            // Create multiple Transaction Discount Lines linked to the same Study Voucher Transaction
            List<reduivy__Transaction_Line_Item__c> discountLines = new List<reduivy__Transaction_Line_Item__c>();
            discountLines.add(REDU_TestData_UTIL.newTransactionDiscountEntry(
                'TEST_TDL_001',
                transactionOrder.Id,
                'Study Voucher Discount 1',
                TRL_Helper.ITEM_TYPE_TUITION,
                400.00,
                null,
                studyVoucherTransaction.Id,
                null,
                null
            ));
            discountLines.add(REDU_TestData_UTIL.newTransactionDiscountEntry(
                'TEST_TDL_002',
                transactionOrder.Id,
                'Study Voucher Discount 2',
                TRL_Helper.ITEM_TYPE_TUITION,
                200.00,
                null,
                studyVoucherTransaction.Id,
                null,
                null
            ));
            insert discountLines;
            
            // Verify records exist before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :studyVoucherTransaction.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesBeforeDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c = :studyVoucherTransaction.Id
            ];
            
            // Delete Transaction Order
            delete transactionOrder;
            
            // Assertions
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :studyVoucherTransaction.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesAfterDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c = :studyVoucherTransaction.Id
            ];
            
            System.assertEquals(1, svtBeforeDeletion.size(), 'Study Voucher Transaction should exist before deletion');
            System.assertEquals(2, discountLinesBeforeDeletion.size(), 'Multiple discount lines should exist before deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'Study Voucher Transaction should be deleted');
            System.assertEquals(0, discountLinesAfterDeletion.size(), 'All discount lines should be deleted with Transaction Order');
        }
    }

    /**
     * @description Test single Transaction Order deletion deletes related Study Voucher Transaction as Student
     */
    @IsTest
    static void testSingleTransactionOrderDeletionDeletesStudyVoucherTransactionAsStudent(){
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: conStudent.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        System.runAs(studentUser) {
            // Create Transaction Order
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                'TEST_TO_001', 
                conStudent.Id, 
                null, 
                Date.today(), 
                TRO_Helper.STATUS_TYPE_DRAFT, 
                1000.00, 
                1000.00, 
                0.00
            );
            insert transactionOrder;
            
            // Create Study Voucher Transaction linked to the Transaction Order
            reduivy__Study_Voucher_Transaction__c studyVoucherTransaction = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'TEST_SVT_001',
                studyVoucher.Id,
                transactionOrder.Id,
                SVT_Helper.STATUS_DRAFT
            );
            insert studyVoucherTransaction;
            
            // Verify Study Voucher Transaction exists before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            
            // Delete Transaction Order
            delete transactionOrder;
            
            // Assertions - Study Voucher Transaction should be deleted
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            
            System.assertEquals(1, svtBeforeDeletion.size(), 'Study Voucher Transaction should exist before Transaction Order deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'Study Voucher Transaction should be deleted when Transaction Order is deleted');
        }
    }

    /**
     * @description Test multiple Transaction Orders deletion deletes all related Study Voucher Transactions as Student
     */
    @IsTest
    static void testMultipleTransactionOrdersDeletionDeletesAllRelatedStudyVoucherTransactionsAsStudent(){
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: conStudent.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        System.runAs(studentUser) {
            // Create multiple Transaction Orders
            List<reduivy__Transaction_Order__c> transactionOrders = new List<reduivy__Transaction_Order__c>();
            for(Integer i = 0; i < 3; i++) {
                transactionOrders.add(REDU_TestData_UTIL.newTransactionOrder(
                    'TEST_TO_00' + i, 
                    conStudent.Id, 
                    null, 
                    Date.today(), 
                    TRO_Helper.STATUS_TYPE_DRAFT, 
                    1000.00, 
                    1000.00, 
                    0.00
                ));
            }
            insert transactionOrders;
            
            // Create Study Voucher Transactions for each Transaction Order
            List<reduivy__Study_Voucher_Transaction__c> studyVoucherTransactions = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < transactionOrders.size(); i++) {
                studyVoucherTransactions.add(REDU_TestData_UTIL.newStudyVoucherTransaction(
                    'TEST_SVT_00' + i,
                    studyVoucher.Id,
                    transactionOrders[i].Id,
                    SVT_Helper.STATUS_DRAFT
                ));
            }
            insert studyVoucherTransactions;
            
            // Verify Study Voucher Transactions exist before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c IN :transactionOrders
            ];
            
            // Delete Transaction Orders
            delete transactionOrders;
            
            // Assertions - All Study Voucher Transactions should be deleted
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c IN :transactionOrders
            ];
            
            System.assertEquals(3, svtBeforeDeletion.size(), 'All Study Voucher Transactions should exist before Transaction Orders deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'All Study Voucher Transactions should be deleted when Transaction Orders are deleted');
        }
    }

    /**
     * @description Test Transaction Order with multiple Study Voucher Transactions deletion as Student
     */
    @IsTest
    static void testTransactionOrderWithMultipleStudyVoucherTransactionsDeletionAsStudent(){
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: conStudent.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        System.runAs(studentUser) {
            // Create Transaction Order
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                'TEST_TO_001', 
                conStudent.Id, 
                null, 
                Date.today(), 
                TRO_Helper.STATUS_TYPE_DRAFT, 
                3000.00, 
                3000.00, 
                0.00
            );
            insert transactionOrder;
            
            // Create multiple Study Voucher Transactions linked to the same Transaction Order
            List<reduivy__Study_Voucher_Transaction__c> studyVoucherTransactions = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 3; i++) {
                studyVoucherTransactions.add(REDU_TestData_UTIL.newStudyVoucherTransaction(
                    'TEST_SVT_00' + i,
                    studyVoucher.Id,
                    transactionOrder.Id,
                    SVT_Helper.STATUS_DRAFT
                ));
            }
            insert studyVoucherTransactions;
            
            // Verify Study Voucher Transactions exist before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            
            // Delete Transaction Order
            delete transactionOrder;
            
            // Assertions - All Study Voucher Transactions should be deleted
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            
            System.assertEquals(3, svtBeforeDeletion.size(), 'Multiple Study Voucher Transactions should exist before Transaction Order deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'All Study Voucher Transactions should be deleted when Transaction Order is deleted');
        }
    }

    /**
     * @description Test Transaction Order deletion deletes Study Voucher Transaction linked with discount line as Student
     */
    @IsTest
    static void testTransactionOrderDeletionDeletesStudyVoucherTransactionLinkedWithDiscountLineAsStudent(){
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: conStudent.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        System.runAs(studentUser) {
            // Create Transaction Order
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                'TEST_TO_001', 
                conStudent.Id, 
                null, 
                Date.today(), 
                TRO_Helper.STATUS_TYPE_DRAFT, 
                1000.00, 
                800.00, 
                0.00
            );
            insert transactionOrder;
            
            // Create Study Voucher Transaction
            reduivy__Study_Voucher_Transaction__c studyVoucherTransaction = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'TEST_SVT_001',
                studyVoucher.Id,
                transactionOrder.Id,
                SVT_Helper.STATUS_DRAFT
            );
            insert studyVoucherTransaction;
            
            // Create Transaction Order Line
            reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
                'TEST_TOL_001',
                transactionOrder.Id,
                null,
                'Tuition Fee',
                TRL_Helper.ITEM_TYPE_TUITION,
                1000.00,
                200.00,
                800.00
            );
            insert orderLine;
            
            // Create Transaction Discount Line linked to Study Voucher Transaction
            reduivy__Transaction_Line_Item__c discountLine = REDU_TestData_UTIL.newTransactionDiscountEntry(
                'TEST_TDL_001',
                transactionOrder.Id,
                'Study Voucher Discount',
                TRL_Helper.ITEM_TYPE_TUITION,
                200.00,
                null,
                studyVoucherTransaction.Id,
                null,
                null
            );
            insert discountLine;
            
            // Verify records exist before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :studyVoucherTransaction.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesBeforeDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c = :studyVoucherTransaction.Id
            ];
            
            // Delete Transaction Order
            delete transactionOrder;
            
            // Assertions
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :studyVoucherTransaction.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesAfterDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c = :studyVoucherTransaction.Id
            ];
            
            System.assertEquals(1, svtBeforeDeletion.size(), 'Study Voucher Transaction should exist before deletion');
            System.assertEquals(1, discountLinesBeforeDeletion.size(), 'Discount line should exist before deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'Study Voucher Transaction should be deleted');
            System.assertEquals(0, discountLinesAfterDeletion.size(), 'Discount line should be deleted with Transaction Order');
        }
    }

    /**
     * @description Test Transaction Order deletion with multiple Study Voucher Transactions linked to discount lines as Student
     */
    @IsTest
    static void testTransactionOrderDeletionWithMultipleStudyVoucherTransactionsLinkedToDiscountLinesAsStudent(){
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: conStudent.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        System.runAs(studentUser) {
            // Create Transaction Order
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                'TEST_TO_001', 
                conStudent.Id, 
                null, 
                Date.today(), 
                TRO_Helper.STATUS_TYPE_DRAFT, 
                1000.00, 
                400.00, 
                0.00
            );
            insert transactionOrder;
            
            // Create multiple Study Voucher Transactions
            List<reduivy__Study_Voucher_Transaction__c> studyVoucherTransactions = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 3; i++) {
                studyVoucherTransactions.add(REDU_TestData_UTIL.newStudyVoucherTransaction(
                    'TEST_SVT_00' + i,
                    studyVoucher.Id,
                    transactionOrder.Id,
                    SVT_Helper.STATUS_DRAFT
                ));
            }
            insert studyVoucherTransactions;
            
            // Create Transaction Order Line
            reduivy__Transaction_Line_Item__c orderLine = REDU_TestData_UTIL.newTransactionOrderLine(
                'TEST_TOL_001',
                transactionOrder.Id,
                null,
                'Tuition Fee',
                TRL_Helper.ITEM_TYPE_TUITION,
                1000.00,
                600.00,
                400.00
            );
            insert orderLine;
            
            // Create Transaction Discount Lines for each Study Voucher Transaction
            List<reduivy__Transaction_Line_Item__c> discountLines = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < studyVoucherTransactions.size(); i++) {
                discountLines.add(REDU_TestData_UTIL.newTransactionDiscountEntry(
                    'TEST_TDL_00' + i,
                    transactionOrder.Id,
                    'Study Voucher Discount ' + i,
                    TRL_Helper.ITEM_TYPE_TUITION,
                    200.00,
                    null,
                    studyVoucherTransactions[i].Id,
                    null,
                    null
                ));
            }
            insert discountLines;
            
            // Verify records exist before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesBeforeDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c IN :studyVoucherTransactions
            ];
            
            // Delete Transaction Order
            delete transactionOrder;
            
            // Assertions
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :transactionOrder.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesAfterDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c IN :studyVoucherTransactions
            ];
            
            System.assertEquals(3, svtBeforeDeletion.size(), 'Multiple Study Voucher Transactions should exist before deletion');
            System.assertEquals(3, discountLinesBeforeDeletion.size(), 'Multiple discount lines should exist before deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'All Study Voucher Transactions should be deleted');
            System.assertEquals(0, discountLinesAfterDeletion.size(), 'All discount lines should be deleted with Transaction Order');
        }
    }

    /**
     * @description Test Transaction Order deletion with Study Voucher Transaction linked to multiple discount lines as Student
     */
    @IsTest
    static void testTransactionOrderDeletionWithStudyVoucherTransactionLinkedToMultipleDiscountLinesAsStudent(){
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Study_Voucher__c studyVoucher = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: conStudent.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        System.runAs(studentUser) {
            // Create Transaction Order
            reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
                'TEST_TO_001', 
                conStudent.Id, 
                null, 
                Date.today(), 
                TRO_Helper.STATUS_TYPE_DRAFT, 
                1000.00, 
                400.00, 
                0.00
            );
            insert transactionOrder;
            
            // Create Study Voucher Transaction
            reduivy__Study_Voucher_Transaction__c studyVoucherTransaction = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'TEST_SVT_001',
                studyVoucher.Id,
                transactionOrder.Id,
                SVT_Helper.STATUS_DRAFT
            );
            insert studyVoucherTransaction;
            
            // Create Transaction Order Lines
            List<reduivy__Transaction_Line_Item__c> orderLines = new List<reduivy__Transaction_Line_Item__c>();
            orderLines.add(REDU_TestData_UTIL.newTransactionOrderLine(
                'TEST_TOL_001',
                transactionOrder.Id,
                null,
                'Tuition Fee',
                TRL_Helper.ITEM_TYPE_TUITION,
                700.00,
                400.00,
                300.00
            ));
            orderLines.add(REDU_TestData_UTIL.newTransactionOrderLine(
                'TEST_TOL_002',
                transactionOrder.Id,
                null,
                'Registration Fee',
                TRL_Helper.ITEM_TYPE_TUITION,
                300.00,
                200.00,
                100.00
            ));
            insert orderLines;
            
            // Create multiple Transaction Discount Lines linked to the same Study Voucher Transaction
            List<reduivy__Transaction_Line_Item__c> discountLines = new List<reduivy__Transaction_Line_Item__c>();
            discountLines.add(REDU_TestData_UTIL.newTransactionDiscountEntry(
                'TEST_TDL_001',
                transactionOrder.Id,
                'Study Voucher Discount 1',
                TRL_Helper.ITEM_TYPE_TUITION,
                400.00,
                null,
                studyVoucherTransaction.Id,
                null,
                null
            ));
            discountLines.add(REDU_TestData_UTIL.newTransactionDiscountEntry(
                'TEST_TDL_002',
                transactionOrder.Id,
                'Study Voucher Discount 2',
                TRL_Helper.ITEM_TYPE_TUITION,
                200.00,
                null,
                studyVoucherTransaction.Id,
                null,
                null
            ));
            insert discountLines;
            
            // Verify records exist before deletion
            List<reduivy__Study_Voucher_Transaction__c> svtBeforeDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :studyVoucherTransaction.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesBeforeDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c = :studyVoucherTransaction.Id
            ];
            
            // Delete Transaction Order
            delete transactionOrder;
            
            // Assertions
            List<reduivy__Study_Voucher_Transaction__c> svtAfterDeletion = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :studyVoucherTransaction.Id
            ];
            List<reduivy__Transaction_Line_Item__c> discountLinesAfterDeletion = [
                SELECT Id FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Study_Voucher_Transaction__c = :studyVoucherTransaction.Id
            ];
            
            System.assertEquals(1, svtBeforeDeletion.size(), 'Study Voucher Transaction should exist before deletion');
            System.assertEquals(2, discountLinesBeforeDeletion.size(), 'Multiple discount lines should exist before deletion');
            System.assertEquals(0, svtAfterDeletion.size(), 'Study Voucher Transaction should be deleted');
            System.assertEquals(0, discountLinesAfterDeletion.size(), 'All discount lines should be deleted with Transaction Order');
        }
    }
}