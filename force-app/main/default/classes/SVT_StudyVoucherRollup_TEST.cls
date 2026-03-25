/**
 * @author      WDCi (XiRouh)
 * @date        Feb 2026
 * @group       Test
 * @description Test class for SVT_StudyVoucherRollup_EXE
 * @changehistory
 * ISS-002591 13-02-2026 XiRouh - new class
 */
@IsTest
public inherited sharing class SVT_StudyVoucherRollup_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static List<String> TRO_STATUSES_DRAFT = TRO_Helper.getDraftStatuses();
    static List<String> SVT_CONFIRMED_STATUSES = SVT_Helper.getConfirmedStatuses();
    static String SRC_TRO = 'TRO';
    static String SRC_SVO = 'SVO';
    static String SRC_SVT = 'SVT';

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

            // Create Transaction Orders
            List<reduivy__Transaction_Order__c> orders = new List<reduivy__Transaction_Order__c>();
            for (Integer i = 1; i <= 3; i++) {
                reduivy__Transaction_Order__c order = new reduivy__Transaction_Order__c(
                    reduivy__Status__c = TRO_STATUSES_DRAFT.get(0), 
                    reduivy__Contact__c = studentUser.ContactId,
                    reduivy__Total_Paid_Amount__c = 0,
                    reduivy__Total_Amount__c = 5000 * i,
                    reduivy__Sample_Record_Code__c = SRC_TRO + i
                );
                orders.add(order);
            }
            insert orders;

            // Create Study Vouchers
            List<reduivy__Study_Voucher__c> vouchers = new List<reduivy__Study_Voucher__c>();
            for (Integer i = 1; i <= 3; i++) {
                reduivy__Study_Voucher__c svo = new reduivy__Study_Voucher__c();
                svo.Name = SRC_SVO + i;
                svo.reduivy__Code__c = SRC_SVO + i;
                svo.reduivy__Voucher_Type__c = SVO_Helper.VOUCHER_TYPE_AMOUNT;
                svo.reduivy__Status__c = SVO_Helper.STATUS_ACTIVE;
                svo.reduivy__Apply_As__c = SVO_Helper.APPLY_AS_ORDER;
                svo.reduivy__Sample_Record_Code__c = SRC_SVO + i;
                vouchers.add(svo);
            }
            insert vouchers;
            
            // Create Study Voucher Transactions
            List<reduivy__Study_Voucher_Transaction__c> svtList = new List<reduivy__Study_Voucher_Transaction__c>();
            
            // SVO1 has 3 transactions
            for(Integer i = 1; i <= 3; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = vouchers[0].Id,
                    reduivy__Transaction_Order__c = orders[i-1].Id,
                    reduivy__Status__c = SVT_Helper.STATUS_DRAFT,
                    reduivy__Amount_Applied__c = i * 100,
                    reduivy__Sample_Record_Code__c = (SRC_SVT + '1-' + i)
                );
                svtList.add(svt);
            }
            
            // SVO2 has 2 transactions
            for(Integer i = 1; i <= 2; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = vouchers[1].Id,
                    reduivy__Transaction_Order__c = orders[i-1].Id,
                    reduivy__Status__c = SVT_Helper.STATUS_DRAFT,
                    reduivy__Amount__c = i * 300,
                    reduivy__Amount_Applied__c = i * 200,
                    reduivy__Sample_Record_Code__c = (SRC_SVT + '2-' + i)
                );
                svtList.add(svt);
            }
            
            // SVO3 has 1 transaction
            reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                reduivy__Study_Voucher__c = vouchers[2].Id,
                reduivy__Transaction_Order__c = orders[0].Id,
                reduivy__Status__c = SVT_Helper.STATUS_DRAFT,
                reduivy__Amount__c = 1000,
                reduivy__Amount_Applied__c = 500,
                reduivy__Sample_Record_Code__c = (SRC_SVT + '3-1')
            );
            svtList.add(svt);

            insert svtList;

            Test.stopTest();
        }
    }
	
    /**
     * @description Test insert confirmed SVT triggers rollup as Admin
     */
    @isTest
    static void testInsertConfirmedSvtAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            Decimal initialAmountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal initialUsageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            
            // Verify initial state
            System.Assert.areEqual(0, initialAmountApplied, 'Initial Amount Applied should be 0');
            System.Assert.areEqual(0, initialUsageCount, 'Initial Usage Count should be 0');

            // Create confirmed SVT
            reduivy__Study_Voucher_Transaction__c newSvt = new reduivy__Study_Voucher_Transaction__c(
                reduivy__Study_Voucher__c = svo.Id,
                reduivy__Transaction_Order__c = order.Id,
                reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                reduivy__Amount__c = 1000,
                reduivy__Amount_Applied__c = 800,
                reduivy__Sample_Record_Code__c = 'NEW_SVT_1'
            );
            insert newSvt;

            // Verify rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(800, svo.reduivy__Amount_Applied__c, 'Amount Applied should be 800 after insert');
            System.Assert.areEqual(1, svo.reduivy__Usage_Count__c, 'Usage Count should be 1 after insert');

            Test.stopTest();
        }
    }

    /**
     * @description Test insert draft SVT does not trigger rollup as Admin
     */
    @isTest
    static void testInsertDraftSvtAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create draft SVT
            reduivy__Study_Voucher_Transaction__c newSvt = new reduivy__Study_Voucher_Transaction__c(
                reduivy__Study_Voucher__c = svo.Id,
                reduivy__Transaction_Order__c = order.Id,
                reduivy__Status__c = SVT_Helper.STATUS_DRAFT,
                reduivy__Amount__c = 1000,
                reduivy__Amount_Applied__c = 800,
                reduivy__Sample_Record_Code__c = 'NEW_DRAFT_SVT_1'
            );
            insert newSvt;

            // Verify no rollup
            svo = getStudyVoucher(1);

            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;

            System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 for draft');
            System.Assert.areEqual(0, usageCount, 'Usage Count should be 0 for draft');

            Test.stopTest();
        }
    }

    /**
     * @description Test update SVT status to confirmed triggers rollup as Admin
     */
    @isTest
    static void testUpdateSvtToConfirmedAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            List<reduivy__Study_Voucher_Transaction__c> svts = getStudyVoucherTransactions(1);

            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;

            // Verify initial state
            System.Assert.areEqual(0, amountApplied, 'Initial Amount Applied should be 0');
            System.Assert.areEqual(0, usageCount, 'Initial Usage Count should be 0');

            // Update first SVT to confirmed
            svts[0].reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            update svts[0];

            // Verify rollup
            svo = getStudyVoucher(1);

            amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;

            System.Assert.areEqual(100, amountApplied, 'Amount Applied should be 100');
            System.Assert.areEqual(1, usageCount, 'Usage Count should be 1');

            Test.stopTest();
        }
    }

    /**
     * @description Test update multiple SVTs to confirmed triggers rollup as Admin
     */
    @isTest
    static void testUpdateMultipleSvtsToConfirmedAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            List<reduivy__Study_Voucher_Transaction__c> svts = getStudyVoucherTransactions(1);

            // Update all SVTs to confirmed
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                svt.reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            }
            update svts;

            // Verify rollup (100 + 200 + 300 = 600)
            svo = getStudyVoucher(1);
            System.Assert.areEqual(600, svo.reduivy__Amount_Applied__c, 'Amount Applied should be 600');
            System.Assert.areEqual(3, svo.reduivy__Usage_Count__c, 'Usage Count should be 3');

            Test.stopTest();
        }
    }

    /**
     * @description Test update confirmed SVT amount triggers rollup as Admin
     */
    @isTest
    static void testUpdateConfirmedSvtAmountAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            List<reduivy__Study_Voucher_Transaction__c> svts = getStudyVoucherTransactions(1);

            // Set to confirmed
            svts[0].reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            update svts[0];

            // Verify initial rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(100, svo.reduivy__Amount_Applied__c, 'Amount Applied should be 100');

            // Update amount
            svts[0].reduivy__Amount_Applied__c = 250;
            update svts[0];

            // Verify updated rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(250, svo.reduivy__Amount_Applied__c, 'Amount Applied should be 250 after update');
            System.Assert.areEqual(1, svo.reduivy__Usage_Count__c, 'Usage Count should still be 1');

            Test.stopTest();
        }
    }

    /**
     * @description Test update confirmed SVT to draft removes from rollup as Admin
     */
    @isTest
    static void testUpdateConfirmedSvtToDraftAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            List<reduivy__Study_Voucher_Transaction__c> svts = getStudyVoucherTransactions(1);

            // Set to confirmed
            svts[0].reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            svts[1].reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            update svts;

            // Verify rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(300, svo.reduivy__Amount_Applied__c, 'Amount Applied should be 300');
            System.Assert.areEqual(2, svo.reduivy__Usage_Count__c, 'Usage Count should be 2');

            // Change first one back to draft
            svts[0].reduivy__Status__c = SVT_Helper.STATUS_DRAFT;
            update svts[0];

            // Verify rollup updated
            svo = getStudyVoucher(1);
            System.Assert.areEqual(200, svo.reduivy__Amount_Applied__c, 'Amount Applied should be 200 after status change');
            System.Assert.areEqual(1, svo.reduivy__Usage_Count__c, 'Usage Count should be 1 after status change');

            Test.stopTest();
        }
    }

    /**
     * @description Test update SVT parent triggers rollup on both vouchers as Admin
     */
    @isTest
    static void testUpdateSvtParentAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo1 = getStudyVoucher(1);
            reduivy__Study_Voucher__c svo2 = getStudyVoucher(2);
            List<reduivy__Study_Voucher_Transaction__c> svts = getStudyVoucherTransactions(1);

            // Set first SVT to confirmed under SVO1
            svts[0].reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            update svts[0];

            // Verify SVO1 has rollup
            svo1 = getStudyVoucher(1);
            System.Assert.areEqual(100, svo1.reduivy__Amount_Applied__c, 'SVO1 Amount Applied should be 100');
            System.Assert.areEqual(1, svo1.reduivy__Usage_Count__c, 'SVO1 Usage Count should be 1');

            // Move SVT to SVO2
            svts[0].reduivy__Study_Voucher__c = svo2.Id;
            update svts[0];

            // Verify SVO1 is now 0 and SVO2 has the rollup
            svo1 = getStudyVoucher(1);
            svo2 = getStudyVoucher(2);
            System.Assert.areEqual(0, svo1.reduivy__Amount_Applied__c, 'SVO1 Amount Applied should be 0');
            System.Assert.areEqual(0, svo1.reduivy__Usage_Count__c, 'SVO1 Usage Count should be 0');
            System.Assert.areEqual(100, svo2.reduivy__Amount_Applied__c, 'SVO2 Amount Applied should be 100');
            System.Assert.areEqual(1, svo2.reduivy__Usage_Count__c, 'SVO2 Usage Count should be 1');

            Test.stopTest();
        }
    }

    /**
     * @description Test delete confirmed SVT triggers rollup as Admin
     */
    @isTest
    static void testDeleteConfirmedSvtAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            List<reduivy__Study_Voucher_Transaction__c> svts = getStudyVoucherTransactions(1);

            // Set both to confirmed
            svts[0].reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            svts[1].reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            update svts;

            // Verify rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(300, svo.reduivy__Amount_Applied__c, 'Amount Applied should be 300');
            System.Assert.areEqual(2, svo.reduivy__Usage_Count__c, 'Usage Count should be 2');

            // Delete first SVT
            delete svts[0];

            // Verify rollup updated
            svo = getStudyVoucher(1);
            System.Assert.areEqual(200, svo.reduivy__Amount_Applied__c, 'Amount Applied should be 200 after delete');
            System.Assert.areEqual(1, svo.reduivy__Usage_Count__c, 'Usage Count should be 1 after delete');

            Test.stopTest();
        }
    }

    /**
     * @description Test delete draft SVT does not affect rollup as Admin
     */
    @isTest
    static void testDeleteDraftSvtAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            List<reduivy__Study_Voucher_Transaction__c> svts = getStudyVoucherTransactions(1);

            // Set first to confirmed
            svts[0].reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            update svts[0];

            // Verify rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(100, svo.reduivy__Amount_Applied__c, 'Amount Applied should be 100');
            System.Assert.areEqual(1, svo.reduivy__Usage_Count__c, 'Usage Count should be 1');

            // Delete draft SVT (second one)
            delete svts[1];

            // Verify rollup unchanged
            svo = getStudyVoucher(1);
            System.Assert.areEqual(100, svo.reduivy__Amount_Applied__c, 'Amount Applied should still be 100');
            System.Assert.areEqual(1, svo.reduivy__Usage_Count__c, 'Usage Count should still be 1');

            Test.stopTest();
        }
    }

    /**
     * @description Test undelete confirmed SVT triggers rollup as Admin
     */
    @isTest
    static void testUndeleteConfirmedSvtAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            List<reduivy__Study_Voucher_Transaction__c> svts = getStudyVoucherTransactions(1);

            // Set to confirmed
            svts[0].reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            update svts[0];

            // Delete
            delete svts[0];

            // Verify rollup removed
            svo = getStudyVoucher(1);
            System.Assert.areEqual(0, svo.reduivy__Amount_Applied__c, 'Amount Applied should be 0 after delete');
            System.Assert.areEqual(0, svo.reduivy__Usage_Count__c, 'Usage Count should be 0 after delete');

            // Undelete
            undelete svts[0];

            // Verify rollup restored
            svo = getStudyVoucher(1);
            System.Assert.areEqual(100, svo.reduivy__Amount_Applied__c, 'Amount Applied should be 100 after undelete');
            System.Assert.areEqual(1, svo.reduivy__Usage_Count__c, 'Usage Count should be 1 after undelete');

            Test.stopTest();
        }
    }

    /**
     * @description Test multiple vouchers rollup independently as Admin
     */
    @isTest
    static void testMultipleVouchersRollupAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo1 = getStudyVoucher(1);
            reduivy__Study_Voucher__c svo2 = getStudyVoucher(2);
            reduivy__Study_Voucher__c svo3 = getStudyVoucher(3);

            List<reduivy__Study_Voucher_Transaction__c> svts1 = getStudyVoucherTransactions(1);
            List<reduivy__Study_Voucher_Transaction__c> svts2 = getStudyVoucherTransactions(2);
            List<reduivy__Study_Voucher_Transaction__c> svts3 = getStudyVoucherTransactions(3);

            // Confirm different numbers of SVTs for each voucher
            // SVO1: Confirm 2 out of 3
            svts1[0].reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            svts1[1].reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            update svts1;

            // SVO2: Confirm 1 out of 2
            svts2[0].reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            update svts2[0];

            // SVO3: Confirm the only one
            svts3[0].reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            update svts3[0];

            // Verify each voucher has correct rollup
            svo1 = getStudyVoucher(1);
            svo2 = getStudyVoucher(2);
            svo3 = getStudyVoucher(3);

            System.Assert.areEqual(300, svo1.reduivy__Amount_Applied__c, 'SVO1 Amount Applied should be 300');
            System.Assert.areEqual(2, svo1.reduivy__Usage_Count__c, 'SVO1 Usage Count should be 2');

            System.Assert.areEqual(200, svo2.reduivy__Amount_Applied__c, 'SVO2 Amount Applied should be 200');
            System.Assert.areEqual(1, svo2.reduivy__Usage_Count__c, 'SVO2 Usage Count should be 1');

            System.Assert.areEqual(500, svo3.reduivy__Amount_Applied__c, 'SVO3 Amount Applied should be 500');
            System.Assert.areEqual(1, svo3.reduivy__Usage_Count__c, 'SVO3 Usage Count should be 1');

            Test.stopTest();
        }
    }

    /**
     * @description Test zero amount applied rollup as Admin
     */
    @isTest
    static void testZeroAmountAppliedAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            List<reduivy__Study_Voucher_Transaction__c> svts = getStudyVoucherTransactions(1);

            // Set to confirmed with 0 amount
            svts[0].reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            svts[0].reduivy__Amount_Applied__c = 0;
            update svts[0];

            // Verify rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(0, svo.reduivy__Amount_Applied__c, 'Amount Applied should be 0');
            System.Assert.areEqual(1, svo.reduivy__Usage_Count__c, 'Usage Count should still be 1');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk insert of 200 confirmed SVTs across multiple vouchers as admin
     */
    @isTest
    static void testBulkInsertConfirmedSvtsAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo1 = getStudyVoucher(1);
            reduivy__Study_Voucher__c svo2 = getStudyVoucher(2);
            reduivy__Study_Voucher__c svo3 = getStudyVoucher(3);
            List<reduivy__Study_Voucher__c> vouchers = new List<reduivy__Study_Voucher__c>{svo1, svo2, svo3};
            
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 200 confirmed SVTs distributed across the 3 vouchers
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher__c svo = vouchers[Math.mod(i, vouchers.size())];
                
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 50,
                    reduivy__Sample_Record_Code__c = 'BULK_INSERT_' + i
                );
                svts.add(svt);
            }
            insert svts;

            // Verify rollups - each voucher should have approximately 66-67 transactions
            svo1 = getStudyVoucher(1);
            svo2 = getStudyVoucher(2);
            svo3 = getStudyVoucher(3);

            System.Assert.isTrue(svo1.reduivy__Amount_Applied__c >= 3300 && svo1.reduivy__Amount_Applied__c <= 3350, 
                'SVO1 Amount Applied should be approximately 3300-3350');
            System.Assert.isTrue(svo1.reduivy__Usage_Count__c >= 66 && svo1.reduivy__Usage_Count__c <= 67, 
                'SVO1 Usage Count should be approximately 66-67');

            System.Assert.isTrue(svo2.reduivy__Amount_Applied__c >= 3300 && svo2.reduivy__Amount_Applied__c <= 3350, 
                'SVO2 Amount Applied should be approximately 3300-3350');
            System.Assert.isTrue(svo2.reduivy__Usage_Count__c >= 66 && svo2.reduivy__Usage_Count__c <= 67, 
                'SVO2 Usage Count should be approximately 66-67');

            System.Assert.isTrue(svo3.reduivy__Amount_Applied__c >= 3300 && svo3.reduivy__Amount_Applied__c <= 3350, 
                'SVO3 Amount Applied should be approximately 3300-3350');
            System.Assert.isTrue(svo3.reduivy__Usage_Count__c >= 66 && svo3.reduivy__Usage_Count__c <= 67, 
                'SVO3 Usage Count should be approximately 66-67');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk update of 200 SVTs from draft to confirmed as admin
     */
    @isTest
    static void testBulkUpdateSvtsDraftToConfirmedAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 200 draft SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_Helper.STATUS_DRAFT,
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 25,
                    reduivy__Sample_Record_Code__c = 'BULK_UPDATE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            Test.startTest();

            // Verify initial state
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 for draft');
            System.Assert.areEqual(0, usageCount, 'Usage Count should be 0 for draft');

            // Update all to confirmed
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                svt.reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            }
            update svts;

            // Verify rollup: 200 * 25 = 5000
            svo = getStudyVoucher(1);
            System.Assert.areEqual(5000, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 5000 after bulk update');
            System.Assert.areEqual(200, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 200 after bulk update');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk update of 200 confirmed SVTs amounts as admin
     */
    @isTest
    static void testBulkUpdateConfirmedSvtAmountsAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 200 confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 10,
                    reduivy__Sample_Record_Code__c = 'BULK_AMT_UPDATE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            Test.startTest();

            // Verify initial rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(2000, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 2000 initially');

            // Update all amounts
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                svt.reduivy__Amount_Applied__c = 20;
            }
            update svts;

            // Verify updated rollup: 200 * 20 = 4000
            svo = getStudyVoucher(1);
            System.Assert.areEqual(4000, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 4000 after bulk amount update');
            System.Assert.areEqual(200, svo.reduivy__Usage_Count__c, 
                'Usage Count should remain 200');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk update of 200 confirmed SVTs from confirmed to draft as admin
     */
    @isTest
    static void testBulkUpdateSvtsConfirmedToDraftAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 200 confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 15,
                    reduivy__Sample_Record_Code__c = 'BULK_TO_DRAFT_' + i
                );
                svts.add(svt);
            }
            insert svts;

            Test.startTest();

            // Verify initial rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(3000, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 3000 initially');
            System.Assert.areEqual(200, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 200 initially');

            // Update all to draft
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                svt.reduivy__Status__c = SVT_Helper.STATUS_DRAFT;
            }
            update svts;

            // Verify rollup cleared
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 after bulk status change');
            System.Assert.areEqual(0, usageCount, 
                'Usage Count should be 0 after bulk status change');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk move of 100 confirmed SVTs from one voucher to another as admin
     */
    @isTest
    static void testBulkMoveSvtsBetweenVouchersAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            reduivy__Study_Voucher__c svo1 = getStudyVoucher(1);
            reduivy__Study_Voucher__c svo2 = getStudyVoucher(2);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 100 confirmed SVTs under SVO1
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 100; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo1.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 30,
                    reduivy__Sample_Record_Code__c = 'BULK_MOVE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            Test.startTest();

            // Verify initial state
            svo1 = getStudyVoucher(1);
            System.Assert.areEqual(3000, svo1.reduivy__Amount_Applied__c, 
                'SVO1 Amount Applied should be 3000 initially');
            System.Assert.areEqual(100, svo1.reduivy__Usage_Count__c, 
                'SVO1 Usage Count should be 100 initially');

            // Move all to SVO2
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                svt.reduivy__Study_Voucher__c = svo2.Id;
            }
            update svts;

            // Verify SVO1 is now 0 and SVO2 has all the rollup
            svo1 = getStudyVoucher(1);
            svo2 = getStudyVoucher(2);
            
            Decimal svo1AmountApplied = svo1.reduivy__Amount_Applied__c != null ? svo1.reduivy__Amount_Applied__c : 0;
            Decimal svo1UsageCount = svo1.reduivy__Usage_Count__c != null ? svo1.reduivy__Usage_Count__c : 0;
            
            System.Assert.areEqual(0, svo1AmountApplied, 
                'SVO1 Amount Applied should be 0 after bulk move');
            System.Assert.areEqual(0, svo1UsageCount, 
                'SVO1 Usage Count should be 0 after bulk move');
            System.Assert.areEqual(3000, svo2.reduivy__Amount_Applied__c, 
                'SVO2 Amount Applied should be 3000 after bulk move');
            System.Assert.areEqual(100, svo2.reduivy__Usage_Count__c, 
                'SVO2 Usage Count should be 100 after bulk move');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk delete of 200 confirmed SVTs as admin
     */
    @isTest
    static void testBulkDeleteConfirmedSvtsAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 200 confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 12,
                    reduivy__Sample_Record_Code__c = 'BULK_DELETE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            Test.startTest();

            // Verify initial rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(2400, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 2400 before delete');
            System.Assert.areEqual(200, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 200 before delete');

            // Delete all SVTs
            delete svts;

            // Verify rollup cleared
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 after bulk delete');
            System.Assert.areEqual(0, usageCount, 
                'Usage Count should be 0 after bulk delete');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk undelete of 50 confirmed SVTs as admin
     */
    @isTest
    static void testBulkUndeleteConfirmedSvtsAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 50 confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 50; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 40,
                    reduivy__Sample_Record_Code__c = 'BULK_UNDELETE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            // Delete all
            delete svts;

            Test.startTest();

            // Verify rollup cleared
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 after delete');
            System.Assert.areEqual(0, usageCount, 'Usage Count should be 0 after delete');

            // Undelete all
            undelete svts;

            // Verify rollup restored: 50 * 40 = 2000
            svo = getStudyVoucher(1);
            System.Assert.areEqual(2000, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 2000 after bulk undelete');
            System.Assert.areEqual(50, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 50 after bulk undelete');

            Test.stopTest();
        }
    }

    /**
     * @description Test SVT with null amount applied as admin
     */
    @isTest
    static void testSvtWithNullAmountAppliedAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create confirmed SVT with null amount applied
            reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                reduivy__Study_Voucher__c = svo.Id,
                reduivy__Transaction_Order__c = order.Id,
                reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                reduivy__Amount__c = 1000,
                reduivy__Sample_Record_Code__c = 'NULL_AMT_SVT'
                // Amount_Applied__c is not set, will be null
            );
            insert svt;

            // Verify rollup handles null as 0
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 when SVT has null amount');
            System.Assert.areEqual(1, svo.reduivy__Usage_Count__c, 
                'Usage Count should still be 1');

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

            reduivy__Study_Voucher__c svo1 = getStudyVoucher(1);
            reduivy__Study_Voucher__c svo2 = getStudyVoucher(2);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 5 confirmed SVTs under SVO1
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 5; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo1.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount_Applied__c = (i + 1) * 50,
                    reduivy__Sample_Record_Code__c = 'MIXED_' + i
                );
                svts.add(svt);
            }
            insert svts;

            // Verify initial state: 50 + 100 + 150 + 200 + 250 = 750
            svo1 = getStudyVoucher(1);
            System.Assert.areEqual(750, svo1.reduivy__Amount_Applied__c, 
                'SVO1 should have 750 initially');
            System.Assert.areEqual(5, svo1.reduivy__Usage_Count__c, 
                'SVO1 should have 5 count initially');

            // Perform mixed operations
            svts[0].reduivy__Amount_Applied__c = 200; // Update amount
            svts[1].reduivy__Status__c = SVT_Helper.STATUS_DRAFT; // Change to draft
            svts[2].reduivy__Study_Voucher__c = svo2.Id; // Move to SVO2
            // svts[3] and svts[4] remain unchanged
            update svts;

            // Verify results
            // SVO1: 200 (svt 0) + 200 (svt 3) + 250 (svt 4) = 650, count = 3
            // SVO2: 150 (svt 2) = 150, count = 1
            svo1 = getStudyVoucher(1);
            svo2 = getStudyVoucher(2);
            
            System.Assert.areEqual(650, svo1.reduivy__Amount_Applied__c, 
                'SVO1 should have 650 after mixed operations');
            System.Assert.areEqual(3, svo1.reduivy__Usage_Count__c, 
                'SVO1 should have 3 count after mixed operations');
            System.Assert.areEqual(150, svo2.reduivy__Amount_Applied__c, 
                'SVO2 should have 150 after mixed operations');
            System.Assert.areEqual(1, svo2.reduivy__Usage_Count__c, 
                'SVO2 should have 1 count after mixed operations');

            Test.stopTest();
        }
    }

    /**
     * @description Test concurrent updates to same voucher from multiple SVTs as admin
     */
    @isTest
    static void testConcurrentUpdatesToSameVoucherAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 50 confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 50; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 30,
                    reduivy__Sample_Record_Code__c = 'CONCURRENT_' + i
                );
                svts.add(svt);
            }
            insert svts;

            // Update all amounts simultaneously
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                svt.reduivy__Amount_Applied__c = 45;
            }
            update svts;

            // Verify final rollup: 50 * 45 = 2250
            svo = getStudyVoucher(1);
            System.Assert.areEqual(2250, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 2250 after concurrent updates');
            System.Assert.areEqual(50, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 50');

            Test.stopTest();
        }
    }

    /**
     * @description Test multiple confirmed status values (if there are multiple)
     */
    @isTest
    static void testMultipleConfirmedStatusesAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create SVTs with different confirmed statuses (if multiple exist)
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < SVT_CONFIRMED_STATUSES.size(); i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[i],
                    reduivy__Amount__c = 1000,
                    reduivy__Amount_Applied__c = 100 * (i + 1),
                    reduivy__Sample_Record_Code__c = 'MULTI_STATUS_' + i
                );
                svts.add(svt);
            }
            
            if(!svts.isEmpty()){
                insert svts;

                // Calculate expected total
                Decimal expectedTotal = 0;
                for(Integer i = 0; i < svts.size(); i++){
                    expectedTotal += 100 * (i + 1);
                }

                // Verify all confirmed statuses are included in rollup
                svo = getStudyVoucher(1);
                System.Assert.areEqual(expectedTotal, svo.reduivy__Amount_Applied__c, 
                    'All confirmed statuses should be included in rollup');
                System.Assert.areEqual(svts.size(), svo.reduivy__Usage_Count__c, 
                    'Usage count should equal number of confirmed SVTs');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test delete operation with both confirmed and draft SVTs in same transaction as admin
     */
    @isTest
    static void testMixedDeleteConfirmedAndDraftSvtsAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> confirmedSvts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 3; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 1000,
                    reduivy__Amount_Applied__c = 150,
                    reduivy__Sample_Record_Code__c = 'MIXED_DEL_CONF_' + i
                );
                confirmedSvts.add(svt);
            }
            insert confirmedSvts;

            // Create draft SVTs
            List<reduivy__Study_Voucher_Transaction__c> draftSvts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 2; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_Helper.STATUS_DRAFT,
                    reduivy__Amount__c = 1000,
                    reduivy__Amount_Applied__c = 200,
                    reduivy__Sample_Record_Code__c = 'MIXED_DEL_DRAFT_' + i
                );
                draftSvts.add(svt);
            }
            insert draftSvts;

            // Verify initial rollup (only confirmed SVTs: 3 * 150 = 450)
            svo = getStudyVoucher(1);
            System.Assert.areEqual(450, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 450 initially (only confirmed)');
            System.Assert.areEqual(3, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 3 initially (only confirmed)');

            // Delete both confirmed and draft SVTs in same operation
            List<reduivy__Study_Voucher_Transaction__c> allToDelete = new List<reduivy__Study_Voucher_Transaction__c>();
            allToDelete.addAll(confirmedSvts);
            allToDelete.addAll(draftSvts);
            delete allToDelete;

            // Verify rollup is now 0 (only confirmed SVTs affected rollup)
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 after mixed delete operation');
            System.Assert.areEqual(0, usageCount, 
                'Usage Count should be 0 after mixed delete operation');

            Test.stopTest();
        }
    }

    /**
     * @description Test simultaneous status change and parent move in bulk operations as admin
     */
    @isTest
    static void testBulkStatusChangeAndParentMoveAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo1 = getStudyVoucher(1);
            reduivy__Study_Voucher__c svo2 = getStudyVoucher(2);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 10 confirmed SVTs on SVO1
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 10; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo1.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 1000,
                    reduivy__Amount_Applied__c = 60,
                    reduivy__Sample_Record_Code__c = 'STATUS_MOVE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            // Verify initial: SVO1 = 600 (10 * 60)
            svo1 = getStudyVoucher(1);
            System.Assert.areEqual(600, svo1.reduivy__Amount_Applied__c, 'SVO1 should be 600 initially');
            System.Assert.areEqual(10, svo1.reduivy__Usage_Count__c, 'SVO1 count should be 10 initially');

            // Perform bulk operation:
            // - First 3 SVTs: Move to SVO2 (remain confirmed)
            // - Next 3 SVTs: Change to draft (remain on SVO1, should not count)
            // - Last 4 SVTs: Both move to SVO2 AND change to draft (should not count)
            for(Integer i = 0; i < 3; i++){
                svts[i].reduivy__Study_Voucher__c = svo2.Id;
            }
            for(Integer i = 3; i < 6; i++){
                svts[i].reduivy__Status__c = SVT_Helper.STATUS_DRAFT;
            }
            for(Integer i = 6; i < 10; i++){
                svts[i].reduivy__Study_Voucher__c = svo2.Id;
                svts[i].reduivy__Status__c = SVT_Helper.STATUS_DRAFT;
            }
            update svts;

            // Verify final state:
            // SVO1: 0 (3 moved, 3 changed to draft, 4 moved+changed to draft)
            // SVO2: 180 (3 confirmed SVTs * 60, the 4 draft SVTs don't count)
            svo1 = getStudyVoucher(1);
            svo2 = getStudyVoucher(2);
            
            Decimal svo1Amount = svo1.reduivy__Amount_Applied__c != null ? svo1.reduivy__Amount_Applied__c : 0;
            Decimal svo1Count = svo1.reduivy__Usage_Count__c != null ? svo1.reduivy__Usage_Count__c : 0;
            
            System.Assert.areEqual(0, svo1Amount, 'SVO1 should be 0 after bulk status change and move');
            System.Assert.areEqual(0, svo1Count, 'SVO1 count should be 0 after bulk status change and move');
            System.Assert.areEqual(180, svo2.reduivy__Amount_Applied__c, 
                'SVO2 should be 180 (only 3 confirmed SVTs count)');
            System.Assert.areEqual(3, svo2.reduivy__Usage_Count__c, 
                'SVO2 count should be 3 (only 3 confirmed SVTs count)');

            Test.stopTest();
        }
    }

    /**
     * @description Test insert confirmed SVT triggers rollup as faculty
     */
    @isTest
    static void testInsertConfirmedSvtAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            Decimal initialAmountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal initialUsageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            
            // Verify initial state
            System.Assert.areEqual(0, initialAmountApplied, 'Initial Amount Applied should be 0');
            System.Assert.areEqual(0, initialUsageCount, 'Initial Usage Count should be 0');

            // Create confirmed SVT
            reduivy__Study_Voucher_Transaction__c newSvt = new reduivy__Study_Voucher_Transaction__c(
                reduivy__Study_Voucher__c = svo.Id,
                reduivy__Transaction_Order__c = order.Id,
                reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                reduivy__Amount__c = 1000,
                reduivy__Amount_Applied__c = 800,
                reduivy__Sample_Record_Code__c = 'NEW_SVT_1'
            );
            insert newSvt;

            // Verify rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(800, svo.reduivy__Amount_Applied__c, 'Amount Applied should be 800 after insert');
            System.Assert.areEqual(1, svo.reduivy__Usage_Count__c, 'Usage Count should be 1 after insert');

            Test.stopTest();
        }
    }

    /**
     * @description Test insert draft SVT does not trigger rollup as faculty
     */
    @isTest
    static void testInsertDraftSvtAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create draft SVT
            reduivy__Study_Voucher_Transaction__c newSvt = new reduivy__Study_Voucher_Transaction__c(
                reduivy__Study_Voucher__c = svo.Id,
                reduivy__Transaction_Order__c = order.Id,
                reduivy__Status__c = SVT_Helper.STATUS_DRAFT,
                reduivy__Amount__c = 1000,
                reduivy__Amount_Applied__c = 800,
                reduivy__Sample_Record_Code__c = 'NEW_DRAFT_SVT_1'
            );
            insert newSvt;

            // Verify no rollup
            svo = getStudyVoucher(1);

            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;

            System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 for draft');
            System.Assert.areEqual(0, usageCount, 'Usage Count should be 0 for draft');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk insert of 200 confirmed SVTs across multiple vouchers as faculty
     */
    @isTest
    static void testBulkInsertConfirmedSvtsAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo1 = getStudyVoucher(1);
            reduivy__Study_Voucher__c svo2 = getStudyVoucher(2);
            reduivy__Study_Voucher__c svo3 = getStudyVoucher(3);
            List<reduivy__Study_Voucher__c> vouchers = new List<reduivy__Study_Voucher__c>{svo1, svo2, svo3};
            
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 200 confirmed SVTs distributed across the 3 vouchers
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher__c svo = vouchers[Math.mod(i, vouchers.size())];
                
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 50,
                    reduivy__Sample_Record_Code__c = 'BULK_INSERT_' + i
                );
                svts.add(svt);
            }
            insert svts;

            // Verify rollups - each voucher should have approximately 66-67 transactions
            svo1 = getStudyVoucher(1);
            svo2 = getStudyVoucher(2);
            svo3 = getStudyVoucher(3);

            System.Assert.isTrue(svo1.reduivy__Amount_Applied__c >= 3300 && svo1.reduivy__Amount_Applied__c <= 3350, 
                'SVO1 Amount Applied should be approximately 3300-3350');
            System.Assert.isTrue(svo1.reduivy__Usage_Count__c >= 66 && svo1.reduivy__Usage_Count__c <= 67, 
                'SVO1 Usage Count should be approximately 66-67');

            System.Assert.isTrue(svo2.reduivy__Amount_Applied__c >= 3300 && svo2.reduivy__Amount_Applied__c <= 3350, 
                'SVO2 Amount Applied should be approximately 3300-3350');
            System.Assert.isTrue(svo2.reduivy__Usage_Count__c >= 66 && svo2.reduivy__Usage_Count__c <= 67, 
                'SVO2 Usage Count should be approximately 66-67');

            System.Assert.isTrue(svo3.reduivy__Amount_Applied__c >= 3300 && svo3.reduivy__Amount_Applied__c <= 3350, 
                'SVO3 Amount Applied should be approximately 3300-3350');
            System.Assert.isTrue(svo3.reduivy__Usage_Count__c >= 66 && svo3.reduivy__Usage_Count__c <= 67, 
                'SVO3 Usage Count should be approximately 66-67');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk update of 200 SVTs from draft to confirmed as faculty
     */
    @isTest
    static void testBulkUpdateSvtsDraftToConfirmedAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 200 draft SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_Helper.STATUS_DRAFT,
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 25,
                    reduivy__Sample_Record_Code__c = 'BULK_UPDATE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            Test.startTest();

            // Verify initial state
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 for draft');
            System.Assert.areEqual(0, usageCount, 'Usage Count should be 0 for draft');

            // Update all to confirmed
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                svt.reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            }
            update svts;

            // Verify rollup: 200 * 25 = 5000
            svo = getStudyVoucher(1);
            System.Assert.areEqual(5000, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 5000 after bulk update');
            System.Assert.areEqual(200, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 200 after bulk update');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk update of 200 confirmed SVTs amounts as faculty
     */
    @isTest
    static void testBulkUpdateConfirmedSvtAmountsAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 200 confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 10,
                    reduivy__Sample_Record_Code__c = 'BULK_AMT_UPDATE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            Test.startTest();

            // Verify initial rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(2000, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 2000 initially');

            // Update all amounts
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                svt.reduivy__Amount_Applied__c = 20;
            }
            update svts;

            // Verify updated rollup: 200 * 20 = 4000
            svo = getStudyVoucher(1);
            System.Assert.areEqual(4000, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 4000 after bulk amount update');
            System.Assert.areEqual(200, svo.reduivy__Usage_Count__c, 
                'Usage Count should remain 200');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk update of 200 confirmed SVTs from confirmed to draft as faculty
     */
    @isTest
    static void testBulkUpdateSvtsConfirmedToDraftAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 200 confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 15,
                    reduivy__Sample_Record_Code__c = 'BULK_TO_DRAFT_' + i
                );
                svts.add(svt);
            }
            insert svts;

            Test.startTest();

            // Verify initial rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(3000, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 3000 initially');
            System.Assert.areEqual(200, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 200 initially');

            // Update all to draft
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                svt.reduivy__Status__c = SVT_Helper.STATUS_DRAFT;
            }
            update svts;

            // Verify rollup cleared
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 after bulk status change');
            System.Assert.areEqual(0, usageCount, 
                'Usage Count should be 0 after bulk status change');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk move of 100 confirmed SVTs from one voucher to another as faculty
     */
    @isTest
    static void testBulkMoveSvtsBetweenVouchersAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            reduivy__Study_Voucher__c svo1 = getStudyVoucher(1);
            reduivy__Study_Voucher__c svo2 = getStudyVoucher(2);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 100 confirmed SVTs under SVO1
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 100; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo1.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 30,
                    reduivy__Sample_Record_Code__c = 'BULK_MOVE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            Test.startTest();

            // Verify initial state
            svo1 = getStudyVoucher(1);
            System.Assert.areEqual(3000, svo1.reduivy__Amount_Applied__c, 
                'SVO1 Amount Applied should be 3000 initially');
            System.Assert.areEqual(100, svo1.reduivy__Usage_Count__c, 
                'SVO1 Usage Count should be 100 initially');

            // Move all to SVO2
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                svt.reduivy__Study_Voucher__c = svo2.Id;
            }
            update svts;

            // Verify SVO1 is now 0 and SVO2 has all the rollup
            svo1 = getStudyVoucher(1);
            svo2 = getStudyVoucher(2);
            
            Decimal svo1AmountApplied = svo1.reduivy__Amount_Applied__c != null ? svo1.reduivy__Amount_Applied__c : 0;
            Decimal svo1UsageCount = svo1.reduivy__Usage_Count__c != null ? svo1.reduivy__Usage_Count__c : 0;
            
            System.Assert.areEqual(0, svo1AmountApplied, 
                'SVO1 Amount Applied should be 0 after bulk move');
            System.Assert.areEqual(0, svo1UsageCount, 
                'SVO1 Usage Count should be 0 after bulk move');
            System.Assert.areEqual(3000, svo2.reduivy__Amount_Applied__c, 
                'SVO2 Amount Applied should be 3000 after bulk move');
            System.Assert.areEqual(100, svo2.reduivy__Usage_Count__c, 
                'SVO2 Usage Count should be 100 after bulk move');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk delete of 200 confirmed SVTs as faculty
     */
    @isTest
    static void testBulkDeleteConfirmedSvtsAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 200 confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 12,
                    reduivy__Sample_Record_Code__c = 'BULK_DELETE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            Test.startTest();

            // Verify initial rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(2400, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 2400 before delete');
            System.Assert.areEqual(200, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 200 before delete');

            // Delete all SVTs
            delete svts;

            // Verify rollup cleared
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 after bulk delete');
            System.Assert.areEqual(0, usageCount, 
                'Usage Count should be 0 after bulk delete');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk undelete of 50 confirmed SVTs as faculty
     */
    @isTest
    static void testBulkUndeleteConfirmedSvtsAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 50 confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 50; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 40,
                    reduivy__Sample_Record_Code__c = 'BULK_UNDELETE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            // Delete all
            delete svts;

            Test.startTest();

            // Verify rollup cleared
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 after delete');
            System.Assert.areEqual(0, usageCount, 'Usage Count should be 0 after delete');

            // Undelete all
            undelete svts;

            // Verify rollup restored: 50 * 40 = 2000
            svo = getStudyVoucher(1);
            System.Assert.areEqual(2000, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 2000 after bulk undelete');
            System.Assert.areEqual(50, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 50 after bulk undelete');

            Test.stopTest();
        }
    }

    /**
     * @description Test SVT with null amount applied as faculty
     */
    @isTest
    static void testSvtWithNullAmountAppliedAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create confirmed SVT with null amount applied
            reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                reduivy__Study_Voucher__c = svo.Id,
                reduivy__Transaction_Order__c = order.Id,
                reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                reduivy__Amount__c = 1000,
                reduivy__Sample_Record_Code__c = 'NULL_AMT_SVT'
                // Amount_Applied__c is not set, will be null
            );
            insert svt;

            // Verify rollup handles null as 0
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 when SVT has null amount');
            System.Assert.areEqual(1, svo.reduivy__Usage_Count__c, 
                'Usage Count should still be 1');

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

            reduivy__Study_Voucher__c svo1 = getStudyVoucher(1);
            reduivy__Study_Voucher__c svo2 = getStudyVoucher(2);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 5 confirmed SVTs under SVO1
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 5; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo1.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount_Applied__c = (i + 1) * 50,
                    reduivy__Sample_Record_Code__c = 'MIXED_' + i
                );
                svts.add(svt);
            }
            insert svts;

            // Verify initial state: 50 + 100 + 150 + 200 + 250 = 750
            svo1 = getStudyVoucher(1);
            System.Assert.areEqual(750, svo1.reduivy__Amount_Applied__c, 
                'SVO1 should have 750 initially');
            System.Assert.areEqual(5, svo1.reduivy__Usage_Count__c, 
                'SVO1 should have 5 count initially');

            // Perform mixed operations
            svts[0].reduivy__Amount_Applied__c = 200; // Update amount
            svts[1].reduivy__Status__c = SVT_Helper.STATUS_DRAFT; // Change to draft
            svts[2].reduivy__Study_Voucher__c = svo2.Id; // Move to SVO2
            // svts[3] and svts[4] remain unchanged
            update svts;

            // Verify results
            // SVO1: 200 (svt 0) + 200 (svt 3) + 250 (svt 4) = 650, count = 3
            // SVO2: 150 (svt 2) = 150, count = 1
            svo1 = getStudyVoucher(1);
            svo2 = getStudyVoucher(2);
            
            System.Assert.areEqual(650, svo1.reduivy__Amount_Applied__c, 
                'SVO1 should have 650 after mixed operations');
            System.Assert.areEqual(3, svo1.reduivy__Usage_Count__c, 
                'SVO1 should have 3 count after mixed operations');
            System.Assert.areEqual(150, svo2.reduivy__Amount_Applied__c, 
                'SVO2 should have 150 after mixed operations');
            System.Assert.areEqual(1, svo2.reduivy__Usage_Count__c, 
                'SVO2 should have 1 count after mixed operations');

            Test.stopTest();
        }
    }

    /**
     * @description Test concurrent updates to same voucher from multiple SVTs as faculty
     */
    @isTest
    static void testConcurrentUpdatesToSameVoucherAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 50 confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 50; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 30,
                    reduivy__Sample_Record_Code__c = 'CONCURRENT_' + i
                );
                svts.add(svt);
            }
            insert svts;

            // Update all amounts simultaneously
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                svt.reduivy__Amount_Applied__c = 45;
            }
            update svts;

            // Verify final rollup: 50 * 45 = 2250
            svo = getStudyVoucher(1);
            System.Assert.areEqual(2250, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 2250 after concurrent updates');
            System.Assert.areEqual(50, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 50');

            Test.stopTest();
        }
    }

    /**
     * @description Test multiple confirmed status values (if there are multiple)
     */
    @isTest
    static void testMultipleConfirmedStatusesAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create SVTs with different confirmed statuses (if multiple exist)
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < SVT_CONFIRMED_STATUSES.size(); i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[i],
                    reduivy__Amount__c = 1000,
                    reduivy__Amount_Applied__c = 100 * (i + 1),
                    reduivy__Sample_Record_Code__c = 'MULTI_STATUS_' + i
                );
                svts.add(svt);
            }
            
            if(!svts.isEmpty()){
                insert svts;

                // Calculate expected total
                Decimal expectedTotal = 0;
                for(Integer i = 0; i < svts.size(); i++){
                    expectedTotal += 100 * (i + 1);
                }

                // Verify all confirmed statuses are included in rollup
                svo = getStudyVoucher(1);
                System.Assert.areEqual(expectedTotal, svo.reduivy__Amount_Applied__c, 
                    'All confirmed statuses should be included in rollup');
                System.Assert.areEqual(svts.size(), svo.reduivy__Usage_Count__c, 
                    'Usage count should equal number of confirmed SVTs');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test delete operation with both confirmed and draft SVTs in same transaction as faculty
     */
    @isTest
    static void testMixedDeleteConfirmedAndDraftSvtsAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> confirmedSvts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 3; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 1000,
                    reduivy__Amount_Applied__c = 150,
                    reduivy__Sample_Record_Code__c = 'MIXED_DEL_CONF_' + i
                );
                confirmedSvts.add(svt);
            }
            insert confirmedSvts;

            // Create draft SVTs
            List<reduivy__Study_Voucher_Transaction__c> draftSvts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 2; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_Helper.STATUS_DRAFT,
                    reduivy__Amount__c = 1000,
                    reduivy__Amount_Applied__c = 200,
                    reduivy__Sample_Record_Code__c = 'MIXED_DEL_DRAFT_' + i
                );
                draftSvts.add(svt);
            }
            insert draftSvts;

            // Verify initial rollup (only confirmed SVTs: 3 * 150 = 450)
            svo = getStudyVoucher(1);
            System.Assert.areEqual(450, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 450 initially (only confirmed)');
            System.Assert.areEqual(3, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 3 initially (only confirmed)');

            // Delete both confirmed and draft SVTs in same operation
            List<reduivy__Study_Voucher_Transaction__c> allToDelete = new List<reduivy__Study_Voucher_Transaction__c>();
            allToDelete.addAll(confirmedSvts);
            allToDelete.addAll(draftSvts);
            delete allToDelete;

            // Verify rollup is now 0 (only confirmed SVTs affected rollup)
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 after mixed delete operation');
            System.Assert.areEqual(0, usageCount, 
                'Usage Count should be 0 after mixed delete operation');

            Test.stopTest();
        }
    }

    /**
     * @description Test simultaneous status change and parent move in bulk operations as faculty
     */
    @isTest
    static void testBulkStatusChangeAndParentMoveAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Study_Voucher__c svo1 = getStudyVoucher(1);
            reduivy__Study_Voucher__c svo2 = getStudyVoucher(2);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 10 confirmed SVTs on SVO1
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 10; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo1.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 1000,
                    reduivy__Amount_Applied__c = 60,
                    reduivy__Sample_Record_Code__c = 'STATUS_MOVE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            // Verify initial: SVO1 = 600 (10 * 60)
            svo1 = getStudyVoucher(1);
            System.Assert.areEqual(600, svo1.reduivy__Amount_Applied__c, 'SVO1 should be 600 initially');
            System.Assert.areEqual(10, svo1.reduivy__Usage_Count__c, 'SVO1 count should be 10 initially');

            // Perform bulk operation:
            // - First 3 SVTs: Move to SVO2 (remain confirmed)
            // - Next 3 SVTs: Change to draft (remain on SVO1, should not count)
            // - Last 4 SVTs: Both move to SVO2 AND change to draft (should not count)
            for(Integer i = 0; i < 3; i++){
                svts[i].reduivy__Study_Voucher__c = svo2.Id;
            }
            for(Integer i = 3; i < 6; i++){
                svts[i].reduivy__Status__c = SVT_Helper.STATUS_DRAFT;
            }
            for(Integer i = 6; i < 10; i++){
                svts[i].reduivy__Study_Voucher__c = svo2.Id;
                svts[i].reduivy__Status__c = SVT_Helper.STATUS_DRAFT;
            }
            update svts;

            // Verify final state:
            // SVO1: 0 (3 moved, 3 changed to draft, 4 moved+changed to draft)
            // SVO2: 180 (3 confirmed SVTs * 60, the 4 draft SVTs don't count)
            svo1 = getStudyVoucher(1);
            svo2 = getStudyVoucher(2);
            
            Decimal svo1Amount = svo1.reduivy__Amount_Applied__c != null ? svo1.reduivy__Amount_Applied__c : 0;
            Decimal svo1Count = svo1.reduivy__Usage_Count__c != null ? svo1.reduivy__Usage_Count__c : 0;
            
            System.Assert.areEqual(0, svo1Amount, 'SVO1 should be 0 after bulk status change and move');
            System.Assert.areEqual(0, svo1Count, 'SVO1 count should be 0 after bulk status change and move');
            System.Assert.areEqual(180, svo2.reduivy__Amount_Applied__c, 
                'SVO2 should be 180 (only 3 confirmed SVTs count)');
            System.Assert.areEqual(3, svo2.reduivy__Usage_Count__c, 
                'SVO2 count should be 3 (only 3 confirmed SVTs count)');

            Test.stopTest();
        }
    }

    /**
     * @description Test insert confirmed SVT triggers rollup as student
     */
    @isTest
    static void testInsertConfirmedSvtAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            Decimal initialAmountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal initialUsageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            
            // Verify initial state
            System.Assert.areEqual(0, initialAmountApplied, 'Initial Amount Applied should be 0');
            System.Assert.areEqual(0, initialUsageCount, 'Initial Usage Count should be 0');

            // Create confirmed SVT
            reduivy__Study_Voucher_Transaction__c newSvt = new reduivy__Study_Voucher_Transaction__c(
                reduivy__Study_Voucher__c = svo.Id,
                reduivy__Transaction_Order__c = order.Id,
                reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                reduivy__Amount__c = 1000,
                reduivy__Amount_Applied__c = 800,
                reduivy__Sample_Record_Code__c = 'NEW_SVT_1'
            );
            insert newSvt;

            // Verify rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(800, svo.reduivy__Amount_Applied__c, 'Amount Applied should be 800 after insert');
            System.Assert.areEqual(1, svo.reduivy__Usage_Count__c, 'Usage Count should be 1 after insert');

            Test.stopTest();
        }
    }

    /**
     * @description Test insert draft SVT does not trigger rollup as student
     */
    @isTest
    static void testInsertDraftSvtAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create draft SVT
            reduivy__Study_Voucher_Transaction__c newSvt = new reduivy__Study_Voucher_Transaction__c(
                reduivy__Study_Voucher__c = svo.Id,
                reduivy__Transaction_Order__c = order.Id,
                reduivy__Status__c = SVT_Helper.STATUS_DRAFT,
                reduivy__Amount__c = 1000,
                reduivy__Amount_Applied__c = 800,
                reduivy__Sample_Record_Code__c = 'NEW_DRAFT_SVT_1'
            );
            insert newSvt;

            // Verify no rollup
            svo = getStudyVoucher(1);

            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;

            System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 for draft');
            System.Assert.areEqual(0, usageCount, 'Usage Count should be 0 for draft');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk insert of 200 confirmed SVTs across multiple vouchers as student
     */
    @isTest
    static void testBulkInsertConfirmedSvtsAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher__c svo1 = getStudyVoucher(1);
            reduivy__Study_Voucher__c svo2 = getStudyVoucher(2);
            reduivy__Study_Voucher__c svo3 = getStudyVoucher(3);
            List<reduivy__Study_Voucher__c> vouchers = new List<reduivy__Study_Voucher__c>{svo1, svo2, svo3};
            
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 200 confirmed SVTs distributed across the 3 vouchers
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher__c svo = vouchers[Math.mod(i, vouchers.size())];
                
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 50,
                    reduivy__Sample_Record_Code__c = 'BULK_INSERT_' + i
                );
                svts.add(svt);
            }
            insert svts;

            // Verify rollups - each voucher should have approximately 66-67 transactions
            svo1 = getStudyVoucher(1);
            svo2 = getStudyVoucher(2);
            svo3 = getStudyVoucher(3);

            System.Assert.isTrue(svo1.reduivy__Amount_Applied__c >= 3300 && svo1.reduivy__Amount_Applied__c <= 3350, 
                'SVO1 Amount Applied should be approximately 3300-3350');
            System.Assert.isTrue(svo1.reduivy__Usage_Count__c >= 66 && svo1.reduivy__Usage_Count__c <= 67, 
                'SVO1 Usage Count should be approximately 66-67');

            System.Assert.isTrue(svo2.reduivy__Amount_Applied__c >= 3300 && svo2.reduivy__Amount_Applied__c <= 3350, 
                'SVO2 Amount Applied should be approximately 3300-3350');
            System.Assert.isTrue(svo2.reduivy__Usage_Count__c >= 66 && svo2.reduivy__Usage_Count__c <= 67, 
                'SVO2 Usage Count should be approximately 66-67');

            System.Assert.isTrue(svo3.reduivy__Amount_Applied__c >= 3300 && svo3.reduivy__Amount_Applied__c <= 3350, 
                'SVO3 Amount Applied should be approximately 3300-3350');
            System.Assert.isTrue(svo3.reduivy__Usage_Count__c >= 66 && svo3.reduivy__Usage_Count__c <= 67, 
                'SVO3 Usage Count should be approximately 66-67');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk update of 200 SVTs from draft to confirmed as student
     */
    @isTest
    static void testBulkUpdateSvtsDraftToConfirmedAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 200 draft SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_Helper.STATUS_DRAFT,
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 25,
                    reduivy__Sample_Record_Code__c = 'BULK_UPDATE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            Test.startTest();

            // Verify initial state
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 for draft');
            System.Assert.areEqual(0, usageCount, 'Usage Count should be 0 for draft');

            // Update all to confirmed
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                svt.reduivy__Status__c = SVT_CONFIRMED_STATUSES[0];
            }
            update svts;

            // Verify rollup: 200 * 25 = 5000
            svo = getStudyVoucher(1);
            System.Assert.areEqual(5000, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 5000 after bulk update');
            System.Assert.areEqual(200, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 200 after bulk update');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk update of 200 confirmed SVTs amounts as student
     */
    @isTest
    static void testBulkUpdateConfirmedSvtAmountsAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 200 confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 10,
                    reduivy__Sample_Record_Code__c = 'BULK_AMT_UPDATE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            Test.startTest();

            // Verify initial rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(2000, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 2000 initially');

            // Update all amounts
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                svt.reduivy__Amount_Applied__c = 20;
            }
            update svts;

            // Verify updated rollup: 200 * 20 = 4000
            svo = getStudyVoucher(1);
            System.Assert.areEqual(4000, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 4000 after bulk amount update');
            System.Assert.areEqual(200, svo.reduivy__Usage_Count__c, 
                'Usage Count should remain 200');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk update of 200 confirmed SVTs from confirmed to draft as student
     */
    @isTest
    static void testBulkUpdateSvtsConfirmedToDraftAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 200 confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 15,
                    reduivy__Sample_Record_Code__c = 'BULK_TO_DRAFT_' + i
                );
                svts.add(svt);
            }
            insert svts;

            Test.startTest();

            // Verify initial rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(3000, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 3000 initially');
            System.Assert.areEqual(200, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 200 initially');

            // Update all to draft
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                svt.reduivy__Status__c = SVT_Helper.STATUS_DRAFT;
            }
            update svts;

            // Verify rollup cleared
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 after bulk status change');
            System.Assert.areEqual(0, usageCount, 
                'Usage Count should be 0 after bulk status change');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk move of 100 confirmed SVTs from one voucher to another as student
     */
    @isTest
    static void testBulkMoveSvtsBetweenVouchersAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            reduivy__Study_Voucher__c svo1 = getStudyVoucher(1);
            reduivy__Study_Voucher__c svo2 = getStudyVoucher(2);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 100 confirmed SVTs under SVO1
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 100; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo1.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 30,
                    reduivy__Sample_Record_Code__c = 'BULK_MOVE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            Test.startTest();

            // Verify initial state
            svo1 = getStudyVoucher(1);
            System.Assert.areEqual(3000, svo1.reduivy__Amount_Applied__c, 
                'SVO1 Amount Applied should be 3000 initially');
            System.Assert.areEqual(100, svo1.reduivy__Usage_Count__c, 
                'SVO1 Usage Count should be 100 initially');

            // Move all to SVO2
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                svt.reduivy__Study_Voucher__c = svo2.Id;
            }
            update svts;

            // Verify SVO1 is now 0 and SVO2 has all the rollup
            svo1 = getStudyVoucher(1);
            svo2 = getStudyVoucher(2);
            
            Decimal svo1AmountApplied = svo1.reduivy__Amount_Applied__c != null ? svo1.reduivy__Amount_Applied__c : 0;
            Decimal svo1UsageCount = svo1.reduivy__Usage_Count__c != null ? svo1.reduivy__Usage_Count__c : 0;
            
            System.Assert.areEqual(0, svo1AmountApplied, 
                'SVO1 Amount Applied should be 0 after bulk move');
            System.Assert.areEqual(0, svo1UsageCount, 
                'SVO1 Usage Count should be 0 after bulk move');
            System.Assert.areEqual(3000, svo2.reduivy__Amount_Applied__c, 
                'SVO2 Amount Applied should be 3000 after bulk move');
            System.Assert.areEqual(100, svo2.reduivy__Usage_Count__c, 
                'SVO2 Usage Count should be 100 after bulk move');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk delete of 200 confirmed SVTs as student
     */
    @isTest
    static void testBulkDeleteConfirmedSvtsAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 200 confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 200; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 12,
                    reduivy__Sample_Record_Code__c = 'BULK_DELETE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            Test.startTest();

            // Verify initial rollup
            svo = getStudyVoucher(1);
            System.Assert.areEqual(2400, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 2400 before delete');
            System.Assert.areEqual(200, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 200 before delete');

            // Delete all SVTs
            delete svts;

            // Verify rollup cleared
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 after bulk delete');
            System.Assert.areEqual(0, usageCount, 
                'Usage Count should be 0 after bulk delete');

            Test.stopTest();
        }
    }

    /**
     * @description Test bulk undelete of 50 confirmed SVTs as student
     */
    @isTest
    static void testBulkUndeleteConfirmedSvtsAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 50 confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 50; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 40,
                    reduivy__Sample_Record_Code__c = 'BULK_UNDELETE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            // Delete all
            delete svts;

            Test.startTest();

            // Verify rollup cleared
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            System.Assert.areEqual(0, amountApplied, 'Amount Applied should be 0 after delete');
            System.Assert.areEqual(0, usageCount, 'Usage Count should be 0 after delete');

            // Undelete all
            undelete svts;

            // Verify rollup restored: 50 * 40 = 2000
            svo = getStudyVoucher(1);
            System.Assert.areEqual(2000, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 2000 after bulk undelete');
            System.Assert.areEqual(50, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 50 after bulk undelete');

            Test.stopTest();
        }
    }

    /**
     * @description Test SVT with null amount applied as student
     */
    @isTest
    static void testSvtWithNullAmountAppliedAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create confirmed SVT with null amount applied
            reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                reduivy__Study_Voucher__c = svo.Id,
                reduivy__Transaction_Order__c = order.Id,
                reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                reduivy__Amount__c = 1000,
                reduivy__Sample_Record_Code__c = 'NULL_AMT_SVT'
                // Amount_Applied__c is not set, will be null
            );
            insert svt;

            // Verify rollup handles null as 0
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 when SVT has null amount');
            System.Assert.areEqual(1, svo.reduivy__Usage_Count__c, 
                'Usage Count should still be 1');

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

            reduivy__Study_Voucher__c svo1 = getStudyVoucher(1);
            reduivy__Study_Voucher__c svo2 = getStudyVoucher(2);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 5 confirmed SVTs under SVO1
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 5; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo1.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount_Applied__c = (i + 1) * 50,
                    reduivy__Sample_Record_Code__c = 'MIXED_' + i
                );
                svts.add(svt);
            }
            insert svts;

            // Verify initial state: 50 + 100 + 150 + 200 + 250 = 750
            svo1 = getStudyVoucher(1);
            System.Assert.areEqual(750, svo1.reduivy__Amount_Applied__c, 
                'SVO1 should have 750 initially');
            System.Assert.areEqual(5, svo1.reduivy__Usage_Count__c, 
                'SVO1 should have 5 count initially');

            // Perform mixed operations
            svts[0].reduivy__Amount_Applied__c = 200; // Update amount
            svts[1].reduivy__Status__c = SVT_Helper.STATUS_DRAFT; // Change to draft
            svts[2].reduivy__Study_Voucher__c = svo2.Id; // Move to SVO2
            // svts[3] and svts[4] remain unchanged
            update svts;

            // Verify results
            // SVO1: 200 (svt 0) + 200 (svt 3) + 250 (svt 4) = 650, count = 3
            // SVO2: 150 (svt 2) = 150, count = 1
            svo1 = getStudyVoucher(1);
            svo2 = getStudyVoucher(2);
            
            System.Assert.areEqual(650, svo1.reduivy__Amount_Applied__c, 
                'SVO1 should have 650 after mixed operations');
            System.Assert.areEqual(3, svo1.reduivy__Usage_Count__c, 
                'SVO1 should have 3 count after mixed operations');
            System.Assert.areEqual(150, svo2.reduivy__Amount_Applied__c, 
                'SVO2 should have 150 after mixed operations');
            System.Assert.areEqual(1, svo2.reduivy__Usage_Count__c, 
                'SVO2 should have 1 count after mixed operations');

            Test.stopTest();
        }
    }

    /**
     * @description Test concurrent updates to same voucher from multiple SVTs as student
     */
    @isTest
    static void testConcurrentUpdatesToSameVoucherAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 50 confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 50; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 100,
                    reduivy__Amount_Applied__c = 30,
                    reduivy__Sample_Record_Code__c = 'CONCURRENT_' + i
                );
                svts.add(svt);
            }
            insert svts;

            // Update all amounts simultaneously
            for(reduivy__Study_Voucher_Transaction__c svt : svts){
                svt.reduivy__Amount_Applied__c = 45;
            }
            update svts;

            // Verify final rollup: 50 * 45 = 2250
            svo = getStudyVoucher(1);
            System.Assert.areEqual(2250, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 2250 after concurrent updates');
            System.Assert.areEqual(50, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 50');

            Test.stopTest();
        }
    }

    /**
     * @description Test multiple confirmed status values (if there are multiple)
     */
    @isTest
    static void testMultipleConfirmedStatusesAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create SVTs with different confirmed statuses (if multiple exist)
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < SVT_CONFIRMED_STATUSES.size(); i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[i],
                    reduivy__Amount__c = 1000,
                    reduivy__Amount_Applied__c = 100 * (i + 1),
                    reduivy__Sample_Record_Code__c = 'MULTI_STATUS_' + i
                );
                svts.add(svt);
            }
            
            if(!svts.isEmpty()){
                insert svts;

                // Calculate expected total
                Decimal expectedTotal = 0;
                for(Integer i = 0; i < svts.size(); i++){
                    expectedTotal += 100 * (i + 1);
                }

                // Verify all confirmed statuses are included in rollup
                svo = getStudyVoucher(1);
                System.Assert.areEqual(expectedTotal, svo.reduivy__Amount_Applied__c, 
                    'All confirmed statuses should be included in rollup');
                System.Assert.areEqual(svts.size(), svo.reduivy__Usage_Count__c, 
                    'Usage count should equal number of confirmed SVTs');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test delete operation with both confirmed and draft SVTs in same transaction as student
     */
    @isTest
    static void testMixedDeleteConfirmedAndDraftSvtsAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher__c svo = getStudyVoucher(1);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create confirmed SVTs
            List<reduivy__Study_Voucher_Transaction__c> confirmedSvts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 3; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 1000,
                    reduivy__Amount_Applied__c = 150,
                    reduivy__Sample_Record_Code__c = 'MIXED_DEL_CONF_' + i
                );
                confirmedSvts.add(svt);
            }
            insert confirmedSvts;

            // Create draft SVTs
            List<reduivy__Study_Voucher_Transaction__c> draftSvts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 2; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_Helper.STATUS_DRAFT,
                    reduivy__Amount__c = 1000,
                    reduivy__Amount_Applied__c = 200,
                    reduivy__Sample_Record_Code__c = 'MIXED_DEL_DRAFT_' + i
                );
                draftSvts.add(svt);
            }
            insert draftSvts;

            // Verify initial rollup (only confirmed SVTs: 3 * 150 = 450)
            svo = getStudyVoucher(1);
            System.Assert.areEqual(450, svo.reduivy__Amount_Applied__c, 
                'Amount Applied should be 450 initially (only confirmed)');
            System.Assert.areEqual(3, svo.reduivy__Usage_Count__c, 
                'Usage Count should be 3 initially (only confirmed)');

            // Delete both confirmed and draft SVTs in same operation
            List<reduivy__Study_Voucher_Transaction__c> allToDelete = new List<reduivy__Study_Voucher_Transaction__c>();
            allToDelete.addAll(confirmedSvts);
            allToDelete.addAll(draftSvts);
            delete allToDelete;

            // Verify rollup is now 0 (only confirmed SVTs affected rollup)
            svo = getStudyVoucher(1);
            Decimal amountApplied = svo.reduivy__Amount_Applied__c != null ? svo.reduivy__Amount_Applied__c : 0;
            Decimal usageCount = svo.reduivy__Usage_Count__c != null ? svo.reduivy__Usage_Count__c : 0;
            System.Assert.areEqual(0, amountApplied, 
                'Amount Applied should be 0 after mixed delete operation');
            System.Assert.areEqual(0, usageCount, 
                'Usage Count should be 0 after mixed delete operation');

            Test.stopTest();
        }
    }

    /**
     * @description Test simultaneous status change and parent move in bulk operations as student
     */
    @isTest
    static void testBulkStatusChangeAndParentMoveAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Study_Voucher__c svo1 = getStudyVoucher(1);
            reduivy__Study_Voucher__c svo2 = getStudyVoucher(2);
            reduivy__Transaction_Order__c order = getTransactionOrder(1);

            // Create 10 confirmed SVTs on SVO1
            List<reduivy__Study_Voucher_Transaction__c> svts = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 0; i < 10; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo1.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_CONFIRMED_STATUSES[0],
                    reduivy__Amount__c = 1000,
                    reduivy__Amount_Applied__c = 60,
                    reduivy__Sample_Record_Code__c = 'STATUS_MOVE_' + i
                );
                svts.add(svt);
            }
            insert svts;

            // Verify initial: SVO1 = 600 (10 * 60)
            svo1 = getStudyVoucher(1);
            System.Assert.areEqual(600, svo1.reduivy__Amount_Applied__c, 'SVO1 should be 600 initially');
            System.Assert.areEqual(10, svo1.reduivy__Usage_Count__c, 'SVO1 count should be 10 initially');

            // Perform bulk operation:
            // - First 3 SVTs: Move to SVO2 (remain confirmed)
            // - Next 3 SVTs: Change to draft (remain on SVO1, should not count)
            // - Last 4 SVTs: Both move to SVO2 AND change to draft (should not count)
            for(Integer i = 0; i < 3; i++){
                svts[i].reduivy__Study_Voucher__c = svo2.Id;
            }
            for(Integer i = 3; i < 6; i++){
                svts[i].reduivy__Status__c = SVT_Helper.STATUS_DRAFT;
            }
            for(Integer i = 6; i < 10; i++){
                svts[i].reduivy__Study_Voucher__c = svo2.Id;
                svts[i].reduivy__Status__c = SVT_Helper.STATUS_DRAFT;
            }
            update svts;

            // Verify final state:
            // SVO1: 0 (3 moved, 3 changed to draft, 4 moved+changed to draft)
            // SVO2: 180 (3 confirmed SVTs * 60, the 4 draft SVTs don't count)
            svo1 = getStudyVoucher(1);
            svo2 = getStudyVoucher(2);
            
            Decimal svo1Amount = svo1.reduivy__Amount_Applied__c != null ? svo1.reduivy__Amount_Applied__c : 0;
            Decimal svo1Count = svo1.reduivy__Usage_Count__c != null ? svo1.reduivy__Usage_Count__c : 0;
            
            System.Assert.areEqual(0, svo1Amount, 'SVO1 should be 0 after bulk status change and move');
            System.Assert.areEqual(0, svo1Count, 'SVO1 count should be 0 after bulk status change and move');
            System.Assert.areEqual(180, svo2.reduivy__Amount_Applied__c, 
                'SVO2 should be 180 (only 3 confirmed SVTs count)');
            System.Assert.areEqual(3, svo2.reduivy__Usage_Count__c, 
                'SVO2 count should be 3 (only 3 confirmed SVTs count)');

            Test.stopTest();
        }
    }

    /**
     * @description Helper method to get a specific Study Voucher
     */
    static reduivy__Study_Voucher__c getStudyVoucher(Integer index) {
        return [SELECT Id, Name, reduivy__Code__c, reduivy__Amount_Applied__c, reduivy__Usage_Count__c
                FROM reduivy__Study_Voucher__c
                WHERE reduivy__Sample_Record_Code__c = :(SRC_SVO + index)
                LIMIT 1];
    }

    /**
     * @description Helper method to get Study Voucher Transactions for a specific voucher
     */
    static List<reduivy__Study_Voucher_Transaction__c> getStudyVoucherTransactions(Integer voucherIndex) {
        return [SELECT Id, reduivy__Study_Voucher__c, reduivy__Transaction_Order__c, 
                       reduivy__Status__c, reduivy__Amount__c, reduivy__Amount_Applied__c
                FROM reduivy__Study_Voucher_Transaction__c
                WHERE reduivy__Sample_Record_Code__c LIKE :(SRC_SVT + voucherIndex + '-%')
                ORDER BY reduivy__Sample_Record_Code__c ASC];
    }

    /**
     * @description Helper method to get a specific Transaction Order
     */
    static reduivy__Transaction_Order__c getTransactionOrder(Integer index) {
        return [SELECT Id, reduivy__Contact__c, reduivy__Status__c, reduivy__Total_Amount__c
                FROM reduivy__Transaction_Order__c
                WHERE reduivy__Sample_Record_Code__c = :(SRC_TRO + index)
                LIMIT 1];
    }
}