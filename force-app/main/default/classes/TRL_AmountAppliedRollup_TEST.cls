/**
 * @author      WDCi (XiRouh)
 * @date        Feb 2026
 * @group       Test
 * @description Test class for TRL_AmountAppliedRollup_EXE
 * @changehistory
 * ISS-002591 13-02-2026 XiRouh - new class
 */
@IsTest
public inherited sharing class TRL_AmountAppliedRollup_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static List<String> TRO_STATUSES_DRAFT = TRO_Helper.getDraftStatuses();
    static String SRC_TRO = 'TRO';
    static String SRC_SVO = 'SVO';
    static String SRC_SVT = 'SVT';
    static String SRC_TRL_ORDER = 'TRL_ORDER';
    static String SRC_TRL_DISCOUNT = 'TRL_DISCOUNT';

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

            User studentUser = testFactory.getStudentUser();

            // Create Transaction Order
            reduivy__Transaction_Order__c order = new reduivy__Transaction_Order__c(
                reduivy__Status__c = TRO_STATUSES_DRAFT.get(0), 
                reduivy__Contact__c = studentUser.ContactId,
                reduivy__Total_Paid_Amount__c = 0,
                reduivy__Total_Amount__c = 10000,
                reduivy__Sample_Record_Code__c = SRC_TRO
            );
            insert order;

            // Create Order Line Transaction Line Items
            List<reduivy__Transaction_Line_Item__c> orderLines = new List<reduivy__Transaction_Line_Item__c>();
            for (Integer i = 1; i <= 3; i++){
                reduivy__Transaction_Line_Item__c item = REDU_TestData_UTIL.newTransactionOrderLine(
                    SRC_TRL_ORDER + i, 
                    order.Id, 
                    null, 
                    'Course ' + i, 
                    'Application', 
                    1000 * i, 
                    null, 
                    null
                );
                item.reduivy__Quantity__c = 1;
                item.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
                orderLines.add(item);
            }
            insert orderLines;

            // Create Study Voucher
            reduivy__Study_Voucher__c svo = new reduivy__Study_Voucher__c();
            svo.Name = SRC_SVO;
            svo.reduivy__Code__c = SRC_SVO;
            svo.reduivy__Voucher_Type__c = SVO_Helper.VOUCHER_TYPE_AMOUNT;
            svo.reduivy__Status__c = SVO_Helper.STATUS_ACTIVE;
            svo.reduivy__Apply_As__c = SVO_Helper.APPLY_AS_ORDER;
            svo.reduivy__Sample_Record_Code__c = SRC_SVO;
            insert svo;
            
            // Create Study Voucher Transactions
            List<reduivy__Study_Voucher_Transaction__c> svtList = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 1; i <= 3; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_Helper.STATUS_DRAFT,
                    reduivy__Sample_Record_Code__c = (SRC_SVT + i)
                );
                svtList.add(svt);
            }
            insert svtList;

            Test.stopTest();
        }
    }
	
    /**
     * @description Test insert discount entry triggers rollup as Admin
     */
    @isTest
    static void testInsertDiscountEntryAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);
            
            // Verify initial state
            Decimal initialAmountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, initialAmountApplied, 'Initial Amount Applied should be 0 or null');

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry 1';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Verify rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(100, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 100 after insert');

            Test.stopTest();
        }
    }

    /**
     * @description Test insert multiple discount entries triggers rollup as Admin
     */
    @isTest
    static void testInsertMultipleDiscountEntriesAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create multiple discount entries
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 1; i <= 3; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Discount Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = i * 50;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            // Verify rollup (50 + 100 + 150 = 300)
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(300, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 300');

            Test.stopTest();
        }
    }

    /**
     * @description Test update discount entry amount triggers rollup as Admin
     */
    @isTest
    static void testUpdateDiscountEntryAmountAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Update amount
            discountEntry.reduivy__Unit_Price__c = 200;
            update discountEntry;

            // Verify rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(200, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 200 after update');

            Test.stopTest();
        }
    }

    /**
     * @description Test update discount entry type triggers rollup as Admin
     */
    @isTest
    static void testUpdateDiscountEntryTypeAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Verify initial rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(100, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 100');

            // Change to non-discount type
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            update discountEntry;

            // Verify rollup removed
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(0, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 0 after type change');

            Test.stopTest();
        }
    }

    /**
     * @description Test update discount entry parent triggers rollup on both SVTs as Admin
     */
    @isTest
    static void testUpdateDiscountEntryParentAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt1 = getStudyVoucherTransaction(1);
            reduivy__Study_Voucher_Transaction__c svt2 = getStudyVoucherTransaction(2);

            // Create discount entry on SVT1
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt1.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt1.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 150;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Verify SVT1 has amount
            svt1 = getStudyVoucherTransaction(1);
            System.Assert.areEqual(150, svt1.reduivy__Amount_Applied__c, 'SVT1 Amount Applied should be 150');

            // Move to SVT2
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt2.Id;
            update discountEntry;

            // Verify SVT1 is now 0 and SVT2 has the amount
            svt1 = getStudyVoucherTransaction(1);
            svt2 = getStudyVoucherTransaction(2);
            System.Assert.areEqual(0, svt1.reduivy__Amount_Applied__c, 'SVT1 Amount Applied should be 0');
            System.Assert.areEqual(150, svt2.reduivy__Amount_Applied__c, 'SVT2 Amount Applied should be 150');

            Test.stopTest();
        }
    }

    /**
     * @description Test delete discount entry triggers rollup as Admin
     */
    @isTest
    static void testDeleteDiscountEntryAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Verify rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(100, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 100');

            // Delete discount entry
            delete discountEntry;

            // Verify rollup removed
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(0, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 0 after delete');

            Test.stopTest();
        }
    }

    /**
     * @description Test undelete discount entry triggers rollup as Admin
     */
    @isTest
    static void testUndeleteDiscountEntryAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Delete
            delete discountEntry;

            // Verify rollup removed
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(0, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 0 after delete');

            // Undelete
            undelete discountEntry;

            // Verify rollup restored
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(100, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 100 after undelete');

            Test.stopTest();
        }
    }

    /**
     * @description Test non-discount entry does not trigger rollup as Admin
     */
    @isTest
    static void testNonDiscountEntryNoRollupAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create order line (not discount entry)
            reduivy__Transaction_Line_Item__c orderLine = new reduivy__Transaction_Line_Item__c();
            orderLine.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            orderLine.reduivy__Study_Voucher_Transaction__c = svt.Id;
            orderLine.reduivy__Item_Name__c = 'Order Line';
            orderLine.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            orderLine.reduivy__Item_Type__c = 'Application';
            orderLine.reduivy__Quantity__c = 1;
            orderLine.reduivy__Unit_Price__c = 100;
            orderLine.reduivy__Sample_Record_Code__c = SRC_TRL_ORDER + 99;
            orderLine.reduivy__Entry_Type__c = 'Credit';
            insert orderLine;

            // Verify no rollup
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 or null for non-discount entry');

            Test.stopTest();
        }
    }

    /**
     * @description Test discount entry without parent SVT does not trigger rollup as Admin
     */
    @isTest
    static void testDiscountEntryNoParentNoRollupAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Transaction_Order__c order = getTransactionOrder();

            // Create discount entry without SVT parent
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = order.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry No Parent';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 99;
            insert discountEntry;

            // Verify all SVTs still have 0 amount applied
            List<reduivy__Study_Voucher_Transaction__c> svts = getAllStudyVoucherTransactions();
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;

                System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 or null when no parent');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk insert of 200 discount entries across multiple SVTs as admin
     */
    @isTest
    static void testBulkInsertDiscountEntriesAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            List<reduivy__Study_Voucher_Transaction__c> svts = getAllStudyVoucherTransactions();
            
            // Create 200 discount entries distributed across the 3 SVTs
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher_Transaction__c svt = svts[Math.mod(i, svts.size())];
                
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Bulk Discount Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 10;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'BULK_DISCOUNT_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            // Verify rollups - each SVT should have approximately 66-67 entries worth 10 each
            List<reduivy__Study_Voucher_Transaction__c> updatedSvts = getAllStudyVoucherTransactions();
            for(reduivy__Study_Voucher_Transaction__c svt : updatedSvts){
                System.Assert.isTrue(svt.reduivy__Amount_Applied__c >= 660 && svt.reduivy__Amount_Applied__c <= 670, 
                    'Each SVT should have approximately 660-670 in Amount Applied');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk update of 200 discount entries as admin
     */
    @isTest
    static void testBulkUpdateDiscountEntriesAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);
            
            // Create 200 discount entries
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Bulk Update Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 5;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'BULK_UPDATE_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            Test.startTest();

            // Update all entries to double the amount
            for(reduivy__Transaction_Line_Item__c entry : discountEntries){
                entry.reduivy__Unit_Price__c = 10;
            }
            update discountEntries;

            // Verify rollup: 200 entries * 10 = 2000
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(2000, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 2000 after bulk update');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk delete of 200 discount entries as admin
     */
    @isTest
    static void testBulkDeleteDiscountEntriesAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);
            
            // Create 200 discount entries
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Bulk Delete Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 5;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'BULK_DELETE_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            Test.startTest();

            // Verify initial rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(1000, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 1000 before delete');

            // Delete all entries
            delete discountEntries;

            // Verify rollup is now 0
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(0, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 0 after bulk delete');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk move of discount entries from one SVT to another as admin
     */
    @isTest
    static void testBulkMoveDiscountEntriesBetweenSVTsAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            reduivy__Study_Voucher_Transaction__c svt1 = getStudyVoucherTransaction(1);
            reduivy__Study_Voucher_Transaction__c svt2 = getStudyVoucherTransaction(2);
            
            // Create 100 discount entries on SVT1
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 100; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt1.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt1.Id;
                discountEntry.reduivy__Item_Name__c = 'Move Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 10;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'BULK_MOVE_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            Test.startTest();

            // Move all entries to SVT2
            for(reduivy__Transaction_Line_Item__c entry : discountEntries){
                entry.reduivy__Study_Voucher_Transaction__c = svt2.Id;
            }
            update discountEntries;

            // Verify SVT1 is now 0 and SVT2 has all the amount
            svt1 = getStudyVoucherTransaction(1);
            svt2 = getStudyVoucherTransaction(2);
            System.Assert.areEqual(0, svt1.reduivy__Amount_Applied__c, 
                'SVT1 Amount Applied should be 0 after bulk move');
            System.Assert.areEqual(1000, svt2.reduivy__Amount_Applied__c, 
                'SVT2 Amount Applied should be 1000 after bulk move');

            Test.stopTest();
        }
    }

    /**
     * @description Test discount entry with null amount as admin
     */
    @isTest
    static void testDiscountEntryWithNullAmountAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry with null unit price
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Null Amount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 'NULL';
            // Don't set Unit_Price - it will be null
            insert discountEntry;

            // Verify rollup handles null as 0
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 when discount entry has null amount');

            Test.stopTest();
        }
    }

    /**
     * @description Test discount entry with zero amount as admin
     */
    @isTest
    static void testDiscountEntryWithZeroAmountAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry with zero amount
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Zero Amount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 0;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 'ZERO';
            insert discountEntry;

            // Verify rollup
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 when discount entry has zero amount');

            Test.stopTest();
        }
    }

    /**
     * @description Test update discount entry from null parent to valid parent as admin
     */
    @isTest
    static void testUpdateFromNullParentToValidParentAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Transaction_Order__c order = getTransactionOrder();
            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry without parent
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = order.Id;
            discountEntry.reduivy__Item_Name__c = 'No Parent Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 250;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 'NOPARENT';
            insert discountEntry;

            // Verify SVT still has 0
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 'SVT should have 0 when entry has no parent');

            // Add parent
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            update discountEntry;

            // Verify rollup now includes the amount
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(250, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 250 after adding parent');

            Test.stopTest();
        }
    }

    /**
     * @description Test update discount entry from valid parent to null parent admin
     */
    @isTest
    static void testUpdateFromValidParentToNullParentAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry with parent
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Has Parent Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 300;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 'HASPARENT';
            insert discountEntry;

            // Verify initial rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(300, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 300 initially');

            // Remove parent
            discountEntry.reduivy__Study_Voucher_Transaction__c = null;
            update discountEntry;

            // Verify rollup removed
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 after removing parent');

            Test.stopTest();
        }
    }

    /**
     * @description Test mixed operations in single transaction as admin
     */
    @isTest
    static void testMixedOperationsInSingleTransactionAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt1 = getStudyVoucherTransaction(1);
            reduivy__Study_Voucher_Transaction__c svt2 = getStudyVoucherTransaction(2);

            // Create multiple entries with different amounts
            List<reduivy__Transaction_Line_Item__c> entries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 5; i++){
                reduivy__Transaction_Line_Item__c entry = new reduivy__Transaction_Line_Item__c();
                entry.reduivy__Transaction_Order__c = svt1.reduivy__Transaction_Order__c;
                entry.reduivy__Study_Voucher_Transaction__c = svt1.Id;
                entry.reduivy__Item_Name__c = 'Mixed Entry ' + i;
                entry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                entry.reduivy__Item_Type__c = 'Tuition';
                entry.reduivy__Quantity__c = 1;
                entry.reduivy__Unit_Price__c = (i + 1) * 10;
                entry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                entry.reduivy__Sample_Record_Code__c = 'MIXED_' + i;
                entries.add(entry);
            }
            insert entries;

            // Verify initial state: 10 + 20 + 30 + 40 + 50 = 150
            svt1 = getStudyVoucherTransaction(1);
            System.Assert.areEqual(150, svt1.reduivy__Amount_Applied__c, 
                'SVT1 should have 150 initially');

            // Perform mixed operations: update amounts, change types, move parents
            entries[0].reduivy__Unit_Price__c = 100; // Update amount
            entries[1].reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE; // Change type
            entries[2].reduivy__Study_Voucher_Transaction__c = svt2.Id; // Move to SVT2
            // entries[3] and entries[4] remain unchanged
            update entries;

            // Verify results
            // SVT1: 100 (entry 0) + 40 (entry 3) + 50 (entry 4) = 190
            // SVT2: 30 (entry 2) = 30
            svt1 = getStudyVoucherTransaction(1);
            svt2 = getStudyVoucherTransaction(2);
            System.Assert.areEqual(190, svt1.reduivy__Amount_Applied__c, 
                'SVT1 should have 190 after mixed operations');
            System.Assert.areEqual(30, svt2.reduivy__Amount_Applied__c, 
                'SVT2 should have 30 after mixed operations');

            Test.stopTest();
        }
    }

    /**
     * @description Test concurrent updates to same SVT from multiple discount entries as admin
     */
    @isTest
    static void testConcurrentUpdatesToSameSVTAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create multiple discount entries
            List<reduivy__Transaction_Line_Item__c> entries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 50; i++){
                reduivy__Transaction_Line_Item__c entry = new reduivy__Transaction_Line_Item__c();
                entry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                entry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                entry.reduivy__Item_Name__c = 'Concurrent Entry ' + i;
                entry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                entry.reduivy__Item_Type__c = 'Tuition';
                entry.reduivy__Quantity__c = 1;
                entry.reduivy__Unit_Price__c = 20;
                entry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                entry.reduivy__Sample_Record_Code__c = 'CONCURRENT_' + i;
                entries.add(entry);
            }
            insert entries;

            // Update all entries simultaneously
            for(reduivy__Transaction_Line_Item__c entry : entries){
                entry.reduivy__Unit_Price__c = 25;
            }
            update entries;

            // Verify final rollup: 50 entries * 25 = 1250
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(1250, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 1250 after concurrent updates');

            Test.stopTest();
        }
    }

    /**
     * @description Test update quantity affects total amount rollup as admin
     */
    @isTest
    static void testUpdateQuantityAffectsRollupAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Quantity Test Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 2;
            discountEntry.reduivy__Unit_Price__c = 50;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 'QTY';
            insert discountEntry;

            // Verify initial rollup (assuming Total_Amount__c = Quantity * Unit_Price = 2 * 50 = 100)
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(100, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 100 (2 * 50)');

            // Update quantity
            discountEntry.reduivy__Quantity__c = 5;
            update discountEntry;

            // Verify rollup updated (5 * 50 = 250)
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(250, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 250 (5 * 50) after quantity update');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk undelete of discount entries as admin
     */
    @isTest
    static void testBulkUndeleteDiscountEntriesAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);
            
            // Create 50 discount entries
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 50; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Bulk Undelete Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 15;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'BULK_UNDELETE_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            // Delete all entries
            delete discountEntries;

            Test.startTest();

            // Verify amount is 0 after delete
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 after delete');

            // Undelete all entries
            undelete discountEntries;

            // Verify rollup restored: 50 * 15 = 750
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(750, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 750 after bulk undelete');

            Test.stopTest();
        }
    }

    /**
     * @description Test delete operation with both order lines and discount entries in same transaction as admin
     */
    @isTest
    static void testMixedDeleteOrderLineAndDiscountEntryAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);
            reduivy__Transaction_Order__c order = getTransactionOrder();

            // Create discount entries
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 3; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Discount Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 100;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'MIXED_DEL_DISC_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            // Create order lines (non-discount)
            List<reduivy__Transaction_Line_Item__c> orderLines = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 2; i++){
                reduivy__Transaction_Line_Item__c orderLine = new reduivy__Transaction_Line_Item__c();
                orderLine.reduivy__Transaction_Order__c = order.Id;
                orderLine.reduivy__Study_Voucher_Transaction__c = svt.Id;
                orderLine.reduivy__Item_Name__c = 'Order Line ' + i;
                orderLine.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
                orderLine.reduivy__Item_Type__c = 'Application';
                orderLine.reduivy__Quantity__c = 1;
                orderLine.reduivy__Unit_Price__c = 50;
                orderLine.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                orderLine.reduivy__Sample_Record_Code__c = 'MIXED_DEL_ORDER_' + i;
                orderLines.add(orderLine);
            }
            insert orderLines;

            // Verify initial rollup (only discount entries counted: 3 * 100 = 300)
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(300, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 300 initially');

            // Delete both discount entries and order lines in same operation
            List<reduivy__Transaction_Line_Item__c> allToDelete = new List<reduivy__Transaction_Line_Item__c>();
            allToDelete.addAll(discountEntries);
            allToDelete.addAll(orderLines);
            delete allToDelete;

            // Verify rollup is now 0 (only discount entries affected rollup)
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 after mixed delete operation');

            Test.stopTest();
        }
    }

    /**
     * @description Test simultaneous type change and parent move in bulk operations as admin
     */
    @isTest
    static void testBulkTypeChangeAndParentMoveAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt1 = getStudyVoucherTransaction(1);
            reduivy__Study_Voucher_Transaction__c svt2 = getStudyVoucherTransaction(2);

            // Create 10 discount entries on SVT1
            List<reduivy__Transaction_Line_Item__c> entries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 10; i++){
                reduivy__Transaction_Line_Item__c entry = new reduivy__Transaction_Line_Item__c();
                entry.reduivy__Transaction_Order__c = svt1.reduivy__Transaction_Order__c;
                entry.reduivy__Study_Voucher_Transaction__c = svt1.Id;
                entry.reduivy__Item_Name__c = 'Type Change Entry ' + i;
                entry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                entry.reduivy__Item_Type__c = 'Tuition';
                entry.reduivy__Quantity__c = 1;
                entry.reduivy__Unit_Price__c = 40;
                entry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                entry.reduivy__Sample_Record_Code__c = 'TYPE_MOVE_' + i;
                entries.add(entry);
            }
            insert entries;

            // Verify initial: SVT1 = 400 (10 * 40)
            svt1 = getStudyVoucherTransaction(1);
            System.Assert.areEqual(400, svt1.reduivy__Amount_Applied__c, 'SVT1 should be 400 initially');

            // Perform bulk operation:
            // - First 3 entries: Move to SVT2 (remain discount entries)
            // - Next 3 entries: Change to order lines (remain on SVT1, should not count)
            // - Last 4 entries: Both move to SVT2 AND change to order lines (should not count)
            for(Integer i = 0; i < 3; i++){
                entries[i].reduivy__Study_Voucher_Transaction__c = svt2.Id;
            }
            for(Integer i = 3; i < 6; i++){
                entries[i].reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            }
            for(Integer i = 6; i < 10; i++){
                entries[i].reduivy__Study_Voucher_Transaction__c = svt2.Id;
                entries[i].reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            }
            update entries;

            // Verify final state:
            // SVT1: 0 entries remaining (3 moved, 3 changed to order line, 4 moved+changed)
            // SVT2: 120 (3 discount entries * 40, the 4 order lines don't count)
            svt1 = getStudyVoucherTransaction(1);
            svt2 = getStudyVoucherTransaction(2);
            
            Decimal svt1Amount = svt1.reduivy__Amount_Applied__c != null ? svt1.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, svt1Amount, 'SVT1 should be 0 after bulk type change and move');
            System.Assert.areEqual(120, svt2.reduivy__Amount_Applied__c, 
                'SVT2 should be 120 (only 3 discount entries count)');

            Test.stopTest();
        }
    }

    /**
     * @description Test insert discount entry triggers rollup as faculty
     */
    @isTest
    static void testInsertDiscountEntryAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);
            
            // Verify initial state
            Decimal initialAmountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, initialAmountApplied, 'Initial Amount Applied should be 0 or null');

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry 1';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Verify rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(100, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 100 after insert');

            Test.stopTest();
        }
    }

    /**
     * @description Test insert multiple discount entries triggers rollup as faculty
     */
    @isTest
    static void testInsertMultipleDiscountEntriesAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create multiple discount entries
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 1; i <= 3; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Discount Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = i * 50;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            // Verify rollup (50 + 100 + 150 = 300)
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(300, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 300');

            Test.stopTest();
        }
    }

    /**
     * @description Test update discount entry amount triggers rollup as faculty
     */
    @isTest
    static void testUpdateDiscountEntryAmountAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Update amount
            discountEntry.reduivy__Unit_Price__c = 200;
            update discountEntry;

            // Verify rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(200, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 200 after update');

            Test.stopTest();
        }
    }

    /**
     * @description Test update discount entry type triggers rollup as faculty
     */
    @isTest
    static void testUpdateDiscountEntryTypeAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Verify initial rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(100, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 100');

            // Change to non-discount type
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            update discountEntry;

            // Verify rollup removed
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(0, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 0 after type change');

            Test.stopTest();
        }
    }

    /**
     * @description Test update discount entry parent triggers rollup on both SVTs as faculty
     */
    @isTest
    static void testUpdateDiscountEntryParentAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt1 = getStudyVoucherTransaction(1);
            reduivy__Study_Voucher_Transaction__c svt2 = getStudyVoucherTransaction(2);

            // Create discount entry on SVT1
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt1.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt1.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 150;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Verify SVT1 has amount
            svt1 = getStudyVoucherTransaction(1);
            System.Assert.areEqual(150, svt1.reduivy__Amount_Applied__c, 'SVT1 Amount Applied should be 150');

            // Move to SVT2
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt2.Id;
            update discountEntry;

            // Verify SVT1 is now 0 and SVT2 has the amount
            svt1 = getStudyVoucherTransaction(1);
            svt2 = getStudyVoucherTransaction(2);
            System.Assert.areEqual(0, svt1.reduivy__Amount_Applied__c, 'SVT1 Amount Applied should be 0');
            System.Assert.areEqual(150, svt2.reduivy__Amount_Applied__c, 'SVT2 Amount Applied should be 150');

            Test.stopTest();
        }
    }

    /**
     * @description Test delete discount entry triggers rollup as faculty
     */
    @isTest
    static void testDeleteDiscountEntryAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Verify rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(100, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 100');

            // Delete discount entry
            delete discountEntry;

            // Verify rollup removed
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(0, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 0 after delete');

            Test.stopTest();
        }
    }

    /**
     * @description Test undelete discount entry triggers rollup as faculty
     */
    @isTest
    static void testUndeleteDiscountEntryAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Delete
            delete discountEntry;

            // Verify rollup removed
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(0, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 0 after delete');

            // Undelete
            undelete discountEntry;

            // Verify rollup restored
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(100, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 100 after undelete');

            Test.stopTest();
        }
    }

    /**
     * @description Test non-discount entry does not trigger rollup as faculty
     */
    @isTest
    static void testNonDiscountEntryNoRollupAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create order line (not discount entry)
            reduivy__Transaction_Line_Item__c orderLine = new reduivy__Transaction_Line_Item__c();
            orderLine.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            orderLine.reduivy__Study_Voucher_Transaction__c = svt.Id;
            orderLine.reduivy__Item_Name__c = 'Order Line';
            orderLine.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            orderLine.reduivy__Item_Type__c = 'Application';
            orderLine.reduivy__Quantity__c = 1;
            orderLine.reduivy__Unit_Price__c = 100;
            orderLine.reduivy__Sample_Record_Code__c = SRC_TRL_ORDER + 99;
            orderLine.reduivy__Entry_Type__c = 'Credit';
            insert orderLine;

            // Verify no rollup
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 or null for non-discount entry');

            Test.stopTest();
        }
    }

    /**
     * @description Test discount entry without parent SVT does not trigger rollup as faculty
     */
    @isTest
    static void testDiscountEntryNoParentNoRollupAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Transaction_Order__c order = getTransactionOrder();

            // Create discount entry without SVT parent
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = order.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry No Parent';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 99;
            insert discountEntry;

            // Verify all SVTs still have 0 amount applied
            List<reduivy__Study_Voucher_Transaction__c> svts = getAllStudyVoucherTransactions();
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;

                System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 or null when no parent');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk insert of 200 discount entries across multiple SVTs as faculty
     */
    @isTest
    static void testBulkInsertDiscountEntriesAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            List<reduivy__Study_Voucher_Transaction__c> svts = getAllStudyVoucherTransactions();
            
            // Create 200 discount entries distributed across the 3 SVTs
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher_Transaction__c svt = svts[Math.mod(i, svts.size())];
                
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Bulk Discount Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 10;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'BULK_DISCOUNT_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            // Verify rollups - each SVT should have approximately 66-67 entries worth 10 each
            List<reduivy__Study_Voucher_Transaction__c> updatedSvts = getAllStudyVoucherTransactions();
            for(reduivy__Study_Voucher_Transaction__c svt : updatedSvts){
                System.Assert.isTrue(svt.reduivy__Amount_Applied__c >= 660 && svt.reduivy__Amount_Applied__c <= 670, 
                    'Each SVT should have approximately 660-670 in Amount Applied');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk update of 200 discount entries as faculty
     */
    @isTest
    static void testBulkUpdateDiscountEntriesAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);
            
            // Create 200 discount entries
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Bulk Update Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 5;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'BULK_UPDATE_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            Test.startTest();

            // Update all entries to double the amount
            for(reduivy__Transaction_Line_Item__c entry : discountEntries){
                entry.reduivy__Unit_Price__c = 10;
            }
            update discountEntries;

            // Verify rollup: 200 entries * 10 = 2000
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(2000, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 2000 after bulk update');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk delete of 200 discount entries as faculty
     */
    @isTest
    static void testBulkDeleteDiscountEntriesAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);
            
            // Create 200 discount entries
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Bulk Delete Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 5;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'BULK_DELETE_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            Test.startTest();

            // Verify initial rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(1000, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 1000 before delete');

            // Delete all entries
            delete discountEntries;

            // Verify rollup is now 0
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(0, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 0 after bulk delete');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk move of discount entries from one SVT to another as faculty
     */
    @isTest
    static void testBulkMoveDiscountEntriesBetweenSVTsAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            reduivy__Study_Voucher_Transaction__c svt1 = getStudyVoucherTransaction(1);
            reduivy__Study_Voucher_Transaction__c svt2 = getStudyVoucherTransaction(2);
            
            // Create 100 discount entries on SVT1
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 100; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt1.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt1.Id;
                discountEntry.reduivy__Item_Name__c = 'Move Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 10;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'BULK_MOVE_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            Test.startTest();

            // Move all entries to SVT2
            for(reduivy__Transaction_Line_Item__c entry : discountEntries){
                entry.reduivy__Study_Voucher_Transaction__c = svt2.Id;
            }
            update discountEntries;

            // Verify SVT1 is now 0 and SVT2 has all the amount
            svt1 = getStudyVoucherTransaction(1);
            svt2 = getStudyVoucherTransaction(2);
            System.Assert.areEqual(0, svt1.reduivy__Amount_Applied__c, 
                'SVT1 Amount Applied should be 0 after bulk move');
            System.Assert.areEqual(1000, svt2.reduivy__Amount_Applied__c, 
                'SVT2 Amount Applied should be 1000 after bulk move');

            Test.stopTest();
        }
    }

    /**
     * @description Test discount entry with null amount as faculty
     */
    @isTest
    static void testDiscountEntryWithNullAmountAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry with null unit price
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Null Amount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 'NULL';
            // Don't set Unit_Price - it will be null
            insert discountEntry;

            // Verify rollup handles null as 0
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 when discount entry has null amount');

            Test.stopTest();
        }
    }

    /**
     * @description Test discount entry with zero amount as faculty
     */
    @isTest
    static void testDiscountEntryWithZeroAmountAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry with zero amount
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Zero Amount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 0;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 'ZERO';
            insert discountEntry;

            // Verify rollup
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 when discount entry has zero amount');

            Test.stopTest();
        }
    }

    /**
     * @description Test update discount entry from null parent to valid parent as faculty
     */
    @isTest
    static void testUpdateFromNullParentToValidParentAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Transaction_Order__c order = getTransactionOrder();
            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry without parent
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = order.Id;
            discountEntry.reduivy__Item_Name__c = 'No Parent Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 250;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 'NOPARENT';
            insert discountEntry;

            // Verify SVT still has 0
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 'SVT should have 0 when entry has no parent');

            // Add parent
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            update discountEntry;

            // Verify rollup now includes the amount
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(250, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 250 after adding parent');

            Test.stopTest();
        }
    }

    /**
     * @description Test update discount entry from valid parent to null parent admin
     */
    @isTest
    static void testUpdateFromValidParentToNullParentAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry with parent
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Has Parent Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 300;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 'HASPARENT';
            insert discountEntry;

            // Verify initial rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(300, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 300 initially');

            // Remove parent
            discountEntry.reduivy__Study_Voucher_Transaction__c = null;
            update discountEntry;

            // Verify rollup removed
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 after removing parent');

            Test.stopTest();
        }
    }

    /**
     * @description Test mixed operations in single transaction as faculty
     */
    @isTest
    static void testMixedOperationsInSingleTransactionAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt1 = getStudyVoucherTransaction(1);
            reduivy__Study_Voucher_Transaction__c svt2 = getStudyVoucherTransaction(2);

            // Create multiple entries with different amounts
            List<reduivy__Transaction_Line_Item__c> entries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 5; i++){
                reduivy__Transaction_Line_Item__c entry = new reduivy__Transaction_Line_Item__c();
                entry.reduivy__Transaction_Order__c = svt1.reduivy__Transaction_Order__c;
                entry.reduivy__Study_Voucher_Transaction__c = svt1.Id;
                entry.reduivy__Item_Name__c = 'Mixed Entry ' + i;
                entry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                entry.reduivy__Item_Type__c = 'Tuition';
                entry.reduivy__Quantity__c = 1;
                entry.reduivy__Unit_Price__c = (i + 1) * 10;
                entry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                entry.reduivy__Sample_Record_Code__c = 'MIXED_' + i;
                entries.add(entry);
            }
            insert entries;

            // Verify initial state: 10 + 20 + 30 + 40 + 50 = 150
            svt1 = getStudyVoucherTransaction(1);
            System.Assert.areEqual(150, svt1.reduivy__Amount_Applied__c, 
                'SVT1 should have 150 initially');

            // Perform mixed operations: update amounts, change types, move parents
            entries[0].reduivy__Unit_Price__c = 100; // Update amount
            entries[1].reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE; // Change type
            entries[2].reduivy__Study_Voucher_Transaction__c = svt2.Id; // Move to SVT2
            // entries[3] and entries[4] remain unchanged
            update entries;

            // Verify results
            // SVT1: 100 (entry 0) + 40 (entry 3) + 50 (entry 4) = 190
            // SVT2: 30 (entry 2) = 30
            svt1 = getStudyVoucherTransaction(1);
            svt2 = getStudyVoucherTransaction(2);
            System.Assert.areEqual(190, svt1.reduivy__Amount_Applied__c, 
                'SVT1 should have 190 after mixed operations');
            System.Assert.areEqual(30, svt2.reduivy__Amount_Applied__c, 
                'SVT2 should have 30 after mixed operations');

            Test.stopTest();
        }
    }

    /**
     * @description Test concurrent updates to same SVT from multiple discount entries as faculty
     */
    @isTest
    static void testConcurrentUpdatesToSameSVTAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create multiple discount entries
            List<reduivy__Transaction_Line_Item__c> entries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 50; i++){
                reduivy__Transaction_Line_Item__c entry = new reduivy__Transaction_Line_Item__c();
                entry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                entry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                entry.reduivy__Item_Name__c = 'Concurrent Entry ' + i;
                entry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                entry.reduivy__Item_Type__c = 'Tuition';
                entry.reduivy__Quantity__c = 1;
                entry.reduivy__Unit_Price__c = 20;
                entry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                entry.reduivy__Sample_Record_Code__c = 'CONCURRENT_' + i;
                entries.add(entry);
            }
            insert entries;

            // Update all entries simultaneously
            for(reduivy__Transaction_Line_Item__c entry : entries){
                entry.reduivy__Unit_Price__c = 25;
            }
            update entries;

            // Verify final rollup: 50 entries * 25 = 1250
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(1250, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 1250 after concurrent updates');

            Test.stopTest();
        }
    }

    /**
     * @description Test update quantity affects total amount rollup as faculty
     */
    @isTest
    static void testUpdateQuantityAffectsRollupAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Quantity Test Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 2;
            discountEntry.reduivy__Unit_Price__c = 50;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 'QTY';
            insert discountEntry;

            // Verify initial rollup (assuming Total_Amount__c = Quantity * Unit_Price = 2 * 50 = 100)
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(100, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 100 (2 * 50)');

            // Update quantity
            discountEntry.reduivy__Quantity__c = 5;
            update discountEntry;

            // Verify rollup updated (5 * 50 = 250)
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(250, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 250 (5 * 50) after quantity update');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk undelete of discount entries as faculty
     */
    @isTest
    static void testBulkUndeleteDiscountEntriesAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);
            
            // Create 50 discount entries
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 50; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Bulk Undelete Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 15;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'BULK_UNDELETE_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            // Delete all entries
            delete discountEntries;

            Test.startTest();

            // Verify amount is 0 after delete
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 after delete');

            // Undelete all entries
            undelete discountEntries;

            // Verify rollup restored: 50 * 15 = 750
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(750, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 750 after bulk undelete');

            Test.stopTest();
        }
    }

    /**
     * @description Test delete operation with both order lines and discount entries in same transaction as faculty
     */
    @isTest
    static void testMixedDeleteOrderLineAndDiscountEntryAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);
            reduivy__Transaction_Order__c order = getTransactionOrder();

            // Create discount entries
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 3; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Discount Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 100;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'MIXED_DEL_DISC_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            // Create order lines (non-discount)
            List<reduivy__Transaction_Line_Item__c> orderLines = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 2; i++){
                reduivy__Transaction_Line_Item__c orderLine = new reduivy__Transaction_Line_Item__c();
                orderLine.reduivy__Transaction_Order__c = order.Id;
                orderLine.reduivy__Study_Voucher_Transaction__c = svt.Id;
                orderLine.reduivy__Item_Name__c = 'Order Line ' + i;
                orderLine.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
                orderLine.reduivy__Item_Type__c = 'Application';
                orderLine.reduivy__Quantity__c = 1;
                orderLine.reduivy__Unit_Price__c = 50;
                orderLine.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                orderLine.reduivy__Sample_Record_Code__c = 'MIXED_DEL_ORDER_' + i;
                orderLines.add(orderLine);
            }
            insert orderLines;

            // Verify initial rollup (only discount entries counted: 3 * 100 = 300)
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(300, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 300 initially');

            // Delete both discount entries and order lines in same operation
            List<reduivy__Transaction_Line_Item__c> allToDelete = new List<reduivy__Transaction_Line_Item__c>();
            allToDelete.addAll(discountEntries);
            allToDelete.addAll(orderLines);
            delete allToDelete;

            // Verify rollup is now 0 (only discount entries affected rollup)
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 after mixed delete operation');

            Test.stopTest();
        }
    }

    /**
     * @description Test simultaneous type change and parent move in bulk operations as faculty
     */
    @isTest
    static void testBulkTypeChangeAndParentMoveAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt1 = getStudyVoucherTransaction(1);
            reduivy__Study_Voucher_Transaction__c svt2 = getStudyVoucherTransaction(2);

            // Create 10 discount entries on SVT1
            List<reduivy__Transaction_Line_Item__c> entries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 10; i++){
                reduivy__Transaction_Line_Item__c entry = new reduivy__Transaction_Line_Item__c();
                entry.reduivy__Transaction_Order__c = svt1.reduivy__Transaction_Order__c;
                entry.reduivy__Study_Voucher_Transaction__c = svt1.Id;
                entry.reduivy__Item_Name__c = 'Type Change Entry ' + i;
                entry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                entry.reduivy__Item_Type__c = 'Tuition';
                entry.reduivy__Quantity__c = 1;
                entry.reduivy__Unit_Price__c = 40;
                entry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                entry.reduivy__Sample_Record_Code__c = 'TYPE_MOVE_' + i;
                entries.add(entry);
            }
            insert entries;

            // Verify initial: SVT1 = 400 (10 * 40)
            svt1 = getStudyVoucherTransaction(1);
            System.Assert.areEqual(400, svt1.reduivy__Amount_Applied__c, 'SVT1 should be 400 initially');

            // Perform bulk operation:
            // - First 3 entries: Move to SVT2 (remain discount entries)
            // - Next 3 entries: Change to order lines (remain on SVT1, should not count)
            // - Last 4 entries: Both move to SVT2 AND change to order lines (should not count)
            for(Integer i = 0; i < 3; i++){
                entries[i].reduivy__Study_Voucher_Transaction__c = svt2.Id;
            }
            for(Integer i = 3; i < 6; i++){
                entries[i].reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            }
            for(Integer i = 6; i < 10; i++){
                entries[i].reduivy__Study_Voucher_Transaction__c = svt2.Id;
                entries[i].reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            }
            update entries;

            // Verify final state:
            // SVT1: 0 entries remaining (3 moved, 3 changed to order line, 4 moved+changed)
            // SVT2: 120 (3 discount entries * 40, the 4 order lines don't count)
            svt1 = getStudyVoucherTransaction(1);
            svt2 = getStudyVoucherTransaction(2);
            
            Decimal svt1Amount = svt1.reduivy__Amount_Applied__c != null ? svt1.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, svt1Amount, 'SVT1 should be 0 after bulk type change and move');
            System.Assert.areEqual(120, svt2.reduivy__Amount_Applied__c, 
                'SVT2 should be 120 (only 3 discount entries count)');

            Test.stopTest();
        }
    }

    /**
     * @description Test insert discount entry triggers rollup as student
     */
    @isTest
    static void testInsertDiscountEntryAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);
            
            // Verify initial state
            Decimal initialAmountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, initialAmountApplied, 'Initial Amount Applied should be 0 or null');

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry 1';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Verify rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(100, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 100 after insert');

            Test.stopTest();
        }
    }

    /**
     * @description Test insert multiple discount entries triggers rollup as student
     */
    @isTest
    static void testInsertMultipleDiscountEntriesAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create multiple discount entries
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 1; i <= 3; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Discount Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = i * 50;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            // Verify rollup (50 + 100 + 150 = 300)
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(300, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 300');

            Test.stopTest();
        }
    }

    /**
     * @description Test update discount entry amount triggers rollup as student
     */
    @isTest
    static void testUpdateDiscountEntryAmountAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Update amount
            discountEntry.reduivy__Unit_Price__c = 200;
            update discountEntry;

            // Verify rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(200, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 200 after update');

            Test.stopTest();
        }
    }

    /**
     * @description Test update discount entry type triggers rollup as student
     */
    @isTest
    static void testUpdateDiscountEntryTypeAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Verify initial rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(100, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 100');

            // Change to non-discount type
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            update discountEntry;

            // Verify rollup removed
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(0, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 0 after type change');

            Test.stopTest();
        }
    }

    /**
     * @description Test update discount entry parent triggers rollup on both SVTs as student
     */
    @isTest
    static void testUpdateDiscountEntryParentAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt1 = getStudyVoucherTransaction(1);
            reduivy__Study_Voucher_Transaction__c svt2 = getStudyVoucherTransaction(2);

            // Create discount entry on SVT1
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt1.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt1.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 150;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Verify SVT1 has amount
            svt1 = getStudyVoucherTransaction(1);
            System.Assert.areEqual(150, svt1.reduivy__Amount_Applied__c, 'SVT1 Amount Applied should be 150');

            // Move to SVT2
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt2.Id;
            update discountEntry;

            // Verify SVT1 is now 0 and SVT2 has the amount
            svt1 = getStudyVoucherTransaction(1);
            svt2 = getStudyVoucherTransaction(2);
            System.Assert.areEqual(0, svt1.reduivy__Amount_Applied__c, 'SVT1 Amount Applied should be 0');
            System.Assert.areEqual(150, svt2.reduivy__Amount_Applied__c, 'SVT2 Amount Applied should be 150');

            Test.stopTest();
        }
    }

    /**
     * @description Test delete discount entry triggers rollup as student
     */
    @isTest
    static void testDeleteDiscountEntryAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Verify rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(100, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 100');

            // Delete discount entry
            delete discountEntry;

            // Verify rollup removed
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(0, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 0 after delete');

            Test.stopTest();
        }
    }

    /**
     * @description Test undelete discount entry triggers rollup as student
     */
    @isTest
    static void testUndeleteDiscountEntryAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 1;
            insert discountEntry;

            // Delete
            delete discountEntry;

            // Verify rollup removed
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(0, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 0 after delete');

            // Undelete
            undelete discountEntry;

            // Verify rollup restored
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(100, svt.reduivy__Amount_Applied__c, 'Amount Applied should be 100 after undelete');

            Test.stopTest();
        }
    }

    /**
     * @description Test non-discount entry does not trigger rollup as student
     */
    @isTest
    static void testNonDiscountEntryNoRollupAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create order line (not discount entry)
            reduivy__Transaction_Line_Item__c orderLine = new reduivy__Transaction_Line_Item__c();
            orderLine.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            orderLine.reduivy__Study_Voucher_Transaction__c = svt.Id;
            orderLine.reduivy__Item_Name__c = 'Order Line';
            orderLine.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            orderLine.reduivy__Item_Type__c = 'Application';
            orderLine.reduivy__Quantity__c = 1;
            orderLine.reduivy__Unit_Price__c = 100;
            orderLine.reduivy__Sample_Record_Code__c = SRC_TRL_ORDER + 99;
            orderLine.reduivy__Entry_Type__c = 'Credit';
            insert orderLine;

            // Verify no rollup
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 or null for non-discount entry');

            Test.stopTest();
        }
    }

    /**
     * @description Test discount entry without parent SVT does not trigger rollup as student
     */
    @isTest
    static void testDiscountEntryNoParentNoRollupAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Transaction_Order__c order = getTransactionOrder();

            // Create discount entry without SVT parent
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = order.Id;
            discountEntry.reduivy__Item_Name__c = 'Discount Entry No Parent';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 100;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 99;
            insert discountEntry;

            // Verify all SVTs still have 0 amount applied
            List<reduivy__Study_Voucher_Transaction__c> svts = getAllStudyVoucherTransactions();
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;

                System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 or null when no parent');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk insert of 200 discount entries across multiple SVTs as student
     */
    @isTest
    static void testBulkInsertDiscountEntriesAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            List<reduivy__Study_Voucher_Transaction__c> svts = getAllStudyVoucherTransactions();
            
            // Create 200 discount entries distributed across the 3 SVTs
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher_Transaction__c svt = svts[Math.mod(i, svts.size())];
                
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Bulk Discount Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 10;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'BULK_DISCOUNT_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            // Verify rollups - each SVT should have approximately 66-67 entries worth 10 each
            List<reduivy__Study_Voucher_Transaction__c> updatedSvts = getAllStudyVoucherTransactions();
            for(reduivy__Study_Voucher_Transaction__c svt : updatedSvts){
                System.Assert.isTrue(svt.reduivy__Amount_Applied__c >= 660 && svt.reduivy__Amount_Applied__c <= 670, 
                    'Each SVT should have approximately 660-670 in Amount Applied');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk update of 200 discount entries as student
     */
    @isTest
    static void testBulkUpdateDiscountEntriesAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);
            
            // Create 200 discount entries
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Bulk Update Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 5;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'BULK_UPDATE_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            Test.startTest();

            // Update all entries to double the amount
            for(reduivy__Transaction_Line_Item__c entry : discountEntries){
                entry.reduivy__Unit_Price__c = 10;
            }
            update discountEntries;

            // Verify rollup: 200 entries * 10 = 2000
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(2000, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 2000 after bulk update');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk delete of 200 discount entries as student
     */
    @isTest
    static void testBulkDeleteDiscountEntriesAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);
            
            // Create 200 discount entries
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Bulk Delete Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 5;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'BULK_DELETE_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            Test.startTest();

            // Verify initial rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(1000, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 1000 before delete');

            // Delete all entries
            delete discountEntries;

            // Verify rollup is now 0
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(0, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 0 after bulk delete');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk move of discount entries from one SVT to another as student
     */
    @isTest
    static void testBulkMoveDiscountEntriesBetweenSVTsAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            reduivy__Study_Voucher_Transaction__c svt1 = getStudyVoucherTransaction(1);
            reduivy__Study_Voucher_Transaction__c svt2 = getStudyVoucherTransaction(2);
            
            // Create 100 discount entries on SVT1
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 100; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt1.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt1.Id;
                discountEntry.reduivy__Item_Name__c = 'Move Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 10;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'BULK_MOVE_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            Test.startTest();

            // Move all entries to SVT2
            for(reduivy__Transaction_Line_Item__c entry : discountEntries){
                entry.reduivy__Study_Voucher_Transaction__c = svt2.Id;
            }
            update discountEntries;

            // Verify SVT1 is now 0 and SVT2 has all the amount
            svt1 = getStudyVoucherTransaction(1);
            svt2 = getStudyVoucherTransaction(2);
            System.Assert.areEqual(0, svt1.reduivy__Amount_Applied__c, 
                'SVT1 Amount Applied should be 0 after bulk move');
            System.Assert.areEqual(1000, svt2.reduivy__Amount_Applied__c, 
                'SVT2 Amount Applied should be 1000 after bulk move');

            Test.stopTest();
        }
    }

    /**
     * @description Test discount entry with null amount as student
     */
    @isTest
    static void testDiscountEntryWithNullAmountAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry with null unit price
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Null Amount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 'NULL';
            // Don't set Unit_Price - it will be null
            insert discountEntry;

            // Verify rollup handles null as 0
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 when discount entry has null amount');

            Test.stopTest();
        }
    }

    /**
     * @description Test discount entry with zero amount as student
     */
    @isTest
    static void testDiscountEntryWithZeroAmountAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry with zero amount
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Zero Amount Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 0;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 'ZERO';
            insert discountEntry;

            // Verify rollup
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 when discount entry has zero amount');

            Test.stopTest();
        }
    }

    /**
     * @description Test update discount entry from null parent to valid parent as student
     */
    @isTest
    static void testUpdateFromNullParentToValidParentAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Transaction_Order__c order = getTransactionOrder();
            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry without parent
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = order.Id;
            discountEntry.reduivy__Item_Name__c = 'No Parent Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 250;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 'NOPARENT';
            insert discountEntry;

            // Verify SVT still has 0
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 'SVT should have 0 when entry has no parent');

            // Add parent
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            update discountEntry;

            // Verify rollup now includes the amount
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(250, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 250 after adding parent');

            Test.stopTest();
        }
    }

    /**
     * @description Test update discount entry from valid parent to null parent admin
     */
    @isTest
    static void testUpdateFromValidParentToNullParentAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry with parent
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Has Parent Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 1;
            discountEntry.reduivy__Unit_Price__c = 300;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 'HASPARENT';
            insert discountEntry;

            // Verify initial rollup
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(300, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 300 initially');

            // Remove parent
            discountEntry.reduivy__Study_Voucher_Transaction__c = null;
            update discountEntry;

            // Verify rollup removed
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 after removing parent');

            Test.stopTest();
        }
    }

    /**
     * @description Test mixed operations in single transaction as student
     */
    @isTest
    static void testMixedOperationsInSingleTransactionAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt1 = getStudyVoucherTransaction(1);
            reduivy__Study_Voucher_Transaction__c svt2 = getStudyVoucherTransaction(2);

            // Create multiple entries with different amounts
            List<reduivy__Transaction_Line_Item__c> entries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 5; i++){
                reduivy__Transaction_Line_Item__c entry = new reduivy__Transaction_Line_Item__c();
                entry.reduivy__Transaction_Order__c = svt1.reduivy__Transaction_Order__c;
                entry.reduivy__Study_Voucher_Transaction__c = svt1.Id;
                entry.reduivy__Item_Name__c = 'Mixed Entry ' + i;
                entry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                entry.reduivy__Item_Type__c = 'Tuition';
                entry.reduivy__Quantity__c = 1;
                entry.reduivy__Unit_Price__c = (i + 1) * 10;
                entry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                entry.reduivy__Sample_Record_Code__c = 'MIXED_' + i;
                entries.add(entry);
            }
            insert entries;

            // Verify initial state: 10 + 20 + 30 + 40 + 50 = 150
            svt1 = getStudyVoucherTransaction(1);
            System.Assert.areEqual(150, svt1.reduivy__Amount_Applied__c, 
                'SVT1 should have 150 initially');

            // Perform mixed operations: update amounts, change types, move parents
            entries[0].reduivy__Unit_Price__c = 100; // Update amount
            entries[1].reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE; // Change type
            entries[2].reduivy__Study_Voucher_Transaction__c = svt2.Id; // Move to SVT2
            // entries[3] and entries[4] remain unchanged
            update entries;

            // Verify results
            // SVT1: 100 (entry 0) + 40 (entry 3) + 50 (entry 4) = 190
            // SVT2: 30 (entry 2) = 30
            svt1 = getStudyVoucherTransaction(1);
            svt2 = getStudyVoucherTransaction(2);
            System.Assert.areEqual(190, svt1.reduivy__Amount_Applied__c, 
                'SVT1 should have 190 after mixed operations');
            System.Assert.areEqual(30, svt2.reduivy__Amount_Applied__c, 
                'SVT2 should have 30 after mixed operations');

            Test.stopTest();
        }
    }

    /**
     * @description Test concurrent updates to same SVT from multiple discount entries as student
     */
    @isTest
    static void testConcurrentUpdatesToSameSVTAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create multiple discount entries
            List<reduivy__Transaction_Line_Item__c> entries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 50; i++){
                reduivy__Transaction_Line_Item__c entry = new reduivy__Transaction_Line_Item__c();
                entry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                entry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                entry.reduivy__Item_Name__c = 'Concurrent Entry ' + i;
                entry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                entry.reduivy__Item_Type__c = 'Tuition';
                entry.reduivy__Quantity__c = 1;
                entry.reduivy__Unit_Price__c = 20;
                entry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                entry.reduivy__Sample_Record_Code__c = 'CONCURRENT_' + i;
                entries.add(entry);
            }
            insert entries;

            // Update all entries simultaneously
            for(reduivy__Transaction_Line_Item__c entry : entries){
                entry.reduivy__Unit_Price__c = 25;
            }
            update entries;

            // Verify final rollup: 50 entries * 25 = 1250
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(1250, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 1250 after concurrent updates');

            Test.stopTest();
        }
    }

    /**
     * @description Test update quantity affects total amount rollup as student
     */
    @isTest
    static void testUpdateQuantityAffectsRollupAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);

            // Create discount entry
            reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
            discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
            discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
            discountEntry.reduivy__Item_Name__c = 'Quantity Test Entry';
            discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
            discountEntry.reduivy__Item_Type__c = 'Tuition';
            discountEntry.reduivy__Quantity__c = 2;
            discountEntry.reduivy__Unit_Price__c = 50;
            discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
            discountEntry.reduivy__Sample_Record_Code__c = SRC_TRL_DISCOUNT + 'QTY';
            insert discountEntry;

            // Verify initial rollup (assuming Total_Amount__c = Quantity * Unit_Price = 2 * 50 = 100)
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(100, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 100 (2 * 50)');

            // Update quantity
            discountEntry.reduivy__Quantity__c = 5;
            update discountEntry;

            // Verify rollup updated (5 * 50 = 250)
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(250, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 250 (5 * 50) after quantity update');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk undelete of discount entries as student
     */
    @isTest
    static void testBulkUndeleteDiscountEntriesAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);
            
            // Create 50 discount entries
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 50; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Bulk Undelete Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 15;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'BULK_UNDELETE_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            // Delete all entries
            delete discountEntries;

            Test.startTest();

            // Verify amount is 0 after delete
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 after delete');

            // Undelete all entries
            undelete discountEntries;

            // Verify rollup restored: 50 * 15 = 750
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(750, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 750 after bulk undelete');

            Test.stopTest();
        }
    }

    /**
     * @description Test delete operation with both order lines and discount entries in same transaction as student
     */
    @isTest
    static void testMixedDeleteOrderLineAndDiscountEntryAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt = getStudyVoucherTransaction(1);
            reduivy__Transaction_Order__c order = getTransactionOrder();

            // Create discount entries
            List<reduivy__Transaction_Line_Item__c> discountEntries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 3; i++){
                reduivy__Transaction_Line_Item__c discountEntry = new reduivy__Transaction_Line_Item__c();
                discountEntry.reduivy__Transaction_Order__c = svt.reduivy__Transaction_Order__c;
                discountEntry.reduivy__Study_Voucher_Transaction__c = svt.Id;
                discountEntry.reduivy__Item_Name__c = 'Discount Entry ' + i;
                discountEntry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                discountEntry.reduivy__Item_Type__c = 'Tuition';
                discountEntry.reduivy__Quantity__c = 1;
                discountEntry.reduivy__Unit_Price__c = 100;
                discountEntry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                discountEntry.reduivy__Sample_Record_Code__c = 'MIXED_DEL_DISC_' + i;
                discountEntries.add(discountEntry);
            }
            insert discountEntries;

            // Create order lines (non-discount)
            List<reduivy__Transaction_Line_Item__c> orderLines = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 2; i++){
                reduivy__Transaction_Line_Item__c orderLine = new reduivy__Transaction_Line_Item__c();
                orderLine.reduivy__Transaction_Order__c = order.Id;
                orderLine.reduivy__Study_Voucher_Transaction__c = svt.Id;
                orderLine.reduivy__Item_Name__c = 'Order Line ' + i;
                orderLine.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
                orderLine.reduivy__Item_Type__c = 'Application';
                orderLine.reduivy__Quantity__c = 1;
                orderLine.reduivy__Unit_Price__c = 50;
                orderLine.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                orderLine.reduivy__Sample_Record_Code__c = 'MIXED_DEL_ORDER_' + i;
                orderLines.add(orderLine);
            }
            insert orderLines;

            // Verify initial rollup (only discount entries counted: 3 * 100 = 300)
            svt = getStudyVoucherTransaction(1);
            System.Assert.areEqual(300, svt.reduivy__Amount_Applied__c, 
                'Amount Applied should be 300 initially');

            // Delete both discount entries and order lines in same operation
            List<reduivy__Transaction_Line_Item__c> allToDelete = new List<reduivy__Transaction_Line_Item__c>();
            allToDelete.addAll(discountEntries);
            allToDelete.addAll(orderLines);
            delete allToDelete;

            // Verify rollup is now 0 (only discount entries affected rollup)
            svt = getStudyVoucherTransaction(1);
            Decimal amountApplied = svt.reduivy__Amount_Applied__c != null ? svt.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 after mixed delete operation');

            Test.stopTest();
        }
    }

    /**
     * @description Test simultaneous type change and parent move in bulk operations as student
     */
    @isTest
    static void testBulkTypeChangeAndParentMoveAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher_Transaction__c svt1 = getStudyVoucherTransaction(1);
            reduivy__Study_Voucher_Transaction__c svt2 = getStudyVoucherTransaction(2);

            // Create 10 discount entries on SVT1
            List<reduivy__Transaction_Line_Item__c> entries = new List<reduivy__Transaction_Line_Item__c>();
            for(Integer i = 0; i < 10; i++){
                reduivy__Transaction_Line_Item__c entry = new reduivy__Transaction_Line_Item__c();
                entry.reduivy__Transaction_Order__c = svt1.reduivy__Transaction_Order__c;
                entry.reduivy__Study_Voucher_Transaction__c = svt1.Id;
                entry.reduivy__Item_Name__c = 'Type Change Entry ' + i;
                entry.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
                entry.reduivy__Item_Type__c = 'Tuition';
                entry.reduivy__Quantity__c = 1;
                entry.reduivy__Unit_Price__c = 40;
                entry.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
                entry.reduivy__Sample_Record_Code__c = 'TYPE_MOVE_' + i;
                entries.add(entry);
            }
            insert entries;

            // Verify initial: SVT1 = 400 (10 * 40)
            svt1 = getStudyVoucherTransaction(1);
            System.Assert.areEqual(400, svt1.reduivy__Amount_Applied__c, 'SVT1 should be 400 initially');

            // Perform bulk operation:
            // - First 3 entries: Move to SVT2 (remain discount entries)
            // - Next 3 entries: Change to order lines (remain on SVT1, should not count)
            // - Last 4 entries: Both move to SVT2 AND change to order lines (should not count)
            for(Integer i = 0; i < 3; i++){
                entries[i].reduivy__Study_Voucher_Transaction__c = svt2.Id;
            }
            for(Integer i = 3; i < 6; i++){
                entries[i].reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            }
            for(Integer i = 6; i < 10; i++){
                entries[i].reduivy__Study_Voucher_Transaction__c = svt2.Id;
                entries[i].reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
            }
            update entries;

            // Verify final state:
            // SVT1: 0 entries remaining (3 moved, 3 changed to order line, 4 moved+changed)
            // SVT2: 120 (3 discount entries * 40, the 4 order lines don't count)
            svt1 = getStudyVoucherTransaction(1);
            svt2 = getStudyVoucherTransaction(2);
            
            Decimal svt1Amount = svt1.reduivy__Amount_Applied__c != null ? svt1.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, svt1Amount, 'SVT1 should be 0 after bulk type change and move');
            System.Assert.areEqual(120, svt2.reduivy__Amount_Applied__c, 
                'SVT2 should be 120 (only 3 discount entries count)');

            Test.stopTest();
        }
    }

    /**
     * @description Helper method to get a specific Study Voucher Transaction
     */
    static reduivy__Study_Voucher_Transaction__c getStudyVoucherTransaction(Integer index) {
        return [SELECT Id, reduivy__Study_Voucher__c, reduivy__Transaction_Order__c, 
                       reduivy__Status__c, reduivy__Amount__c, reduivy__Amount_Applied__c
                FROM reduivy__Study_Voucher_Transaction__c
                WHERE reduivy__Sample_Record_Code__c = :(SRC_SVT + index)
                LIMIT 1];
    }

    /**
     * @description Helper method to get all Study Voucher Transactions
     */
    static List<reduivy__Study_Voucher_Transaction__c> getAllStudyVoucherTransactions() {
        return [SELECT Id, reduivy__Study_Voucher__c, reduivy__Transaction_Order__c, 
                       reduivy__Status__c, reduivy__Amount__c, reduivy__Amount_Applied__c
                FROM reduivy__Study_Voucher_Transaction__c
                WHERE reduivy__Sample_Record_Code__c LIKE :(SRC_SVT + '%')
                ORDER BY reduivy__Sample_Record_Code__c ASC];
    }

    /**
     * @description Helper method to get Transaction Order
     */
    static reduivy__Transaction_Order__c getTransactionOrder() {
        return [SELECT Id, reduivy__Contact__c, reduivy__Status__c, reduivy__Total_Amount__c
                FROM reduivy__Transaction_Order__c
                WHERE reduivy__Sample_Record_Code__c = :SRC_TRO
                LIMIT 1];
    }
}