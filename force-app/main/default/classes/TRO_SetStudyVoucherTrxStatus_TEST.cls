/**
 * @author      WDCi (XiRouh)
 * @date        Aug 2025
 * @group       Test
 * @description Test class for TRO_SetStudyVoucherTrxStatus_EXE
 * @changehistory
 * ISS-002566 20-08-2025 XiRouh - new class
 */
@IsTest
public inherited sharing class TRO_SetStudyVoucherTrxStatus_TEST {

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
     * @description Test positive scenario - Status change triggers SVT update as admin
     */
    @IsTest
    static void testPositiveScenarioStatusChangeUpdatesSVTAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create Transaction Order with Draft status
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO001', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 100.00, 100.00, 0.00
            );
            insert tro;
            
            // Create Study Voucher Transaction with Draft status
            reduivy__Study_Voucher_Transaction__c svt = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT001', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_DRAFT
            );
            insert svt;
            
            Test.startTest();
            
            // Update TRO status from Draft to Confirmed
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            Test.stopTest();
            
            // Assertions - SVT should be updated to Confirmed
            reduivy__Study_Voucher_Transaction__c updatedSvt = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :svt.Id
            ];
            System.assertEquals(SVT_Helper.STATUS_CONFIRMED, updatedSvt.reduivy__Status__c, 'SVT status should be updated to Confirmed');
        }
    }

    /**
     * @description Test no related Study Voucher Transactions as admin
     */
    @IsTest
    static void testNoRelatedSVTNoErrorsAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            // Create Transaction Order without any related SVT
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO002', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 200.00, 200.00, 0.00
            );
            insert tro;
            
            Test.startTest();
            
            // Update TRO status - should not cause errors even with no related SVT
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            Test.stopTest();
            
            // Assertions - No errors should occur and TRO should be updated
            reduivy__Transaction_Order__c updatedTro = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Transaction_Order__c 
                WHERE Id = :tro.Id
            ];
            System.assertEquals(TRO_Helper.STATUS_TYPE_CONFIRMED, updatedTro.reduivy__Status__c, 'TRO status should be updated successfully');
            
            // Verify no SVT exists for this TRO
            List<reduivy__Study_Voucher_Transaction__c> relatedSvts = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :tro.Id
            ];
            System.assertEquals(0, relatedSvts.size(), 'No SVT should exist for this TRO');
        }
    }

    /**
     * @description Test SVT already has correct status as admin
     */
    @IsTest
    static void testSVTAlreadyHasCorrectStatusNotUpdatedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create Transaction Order with Confirmed status
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO003', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_CONFIRMED, 150.00, 0.00, 150.00
            );
            insert tro;
            
            // Create Study Voucher Transaction with already matching Confirmed status
            reduivy__Study_Voucher_Transaction__c svt = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT003', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_CONFIRMED
            );
            insert svt;
            
            Test.startTest();
            
            // Update TRO status to same value (Confirmed to Confirmed)
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            Test.stopTest();
            
            // Assertions - SVT should remain unchanged
            reduivy__Study_Voucher_Transaction__c updatedSvt = [
                SELECT Id, reduivy__Status__c, LastModifiedDate
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :svt.Id
            ];
            System.assertEquals(SVT_Helper.STATUS_CONFIRMED, updatedSvt.reduivy__Status__c, 'SVT status should remain Confirmed');
        }
    }

    /**
     * @description Test bulk operation scenario as admin
     */
    @IsTest
    static void testBulkUpdateMultipleTROsAndSVTsAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            List<reduivy__Transaction_Order__c> troList = new List<reduivy__Transaction_Order__c>();
            List<reduivy__Study_Voucher_Transaction__c> svtList = new List<reduivy__Study_Voucher_Transaction__c>();
            
            // Create multiple TROs and SVTs
            for (Integer i = 1; i <= 5; i++) {
                reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                    'TRO00' + i, conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 100.00 * i, 100.00 * i, 0.00
                );
                troList.add(tro);
            }
            insert troList;
            
            for (reduivy__Transaction_Order__c tro : troList) {
                reduivy__Study_Voucher_Transaction__c svt = REDU_TestData_UTIL.newStudyVoucherTransaction(
                    'SVT' + tro.reduivy__Sample_Record_Code__c, studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_DRAFT
                );
                svtList.add(svt);
            }
            insert svtList;
            
            Test.startTest();
            
            // Bulk update all TROs from Draft to Confirmed
            for (reduivy__Transaction_Order__c tro : troList) {
                tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            }
            update troList;
            
            Test.stopTest();
            
            // Assertions - All SVTs should be updated to Confirmed
            List<reduivy__Study_Voucher_Transaction__c> updatedSvts = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id IN :svtList
            ];
            System.assertEquals(5, updatedSvts.size(), 'All 5 SVTs should be retrieved');
            
            for (reduivy__Study_Voucher_Transaction__c svt : updatedSvts) {
                System.assertEquals(SVT_Helper.STATUS_CONFIRMED, svt.reduivy__Status__c, 'All SVT statuses should be updated to Confirmed');
            }
        }
    }

    /**
     * @description Test mixed scenario - Some TROs qualify, others don't as admin
     */
    @IsTest
    static void testMixedScenarioSelectiveUpdatesAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create TRO that will qualify for update
            reduivy__Transaction_Order__c troToUpdate = REDU_TestData_UTIL.newTransactionOrder(
                'TRO_UPDATE', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 100.00, 100.00, 0.00
            );
            
            // Create TRO that won't qualify (no status change)
            reduivy__Transaction_Order__c troNoChange = REDU_TestData_UTIL.newTransactionOrder(
                'TRO_NOCHANGE', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_CONFIRMED, 200.00, 0.00, 200.00
            );
            
            insert new List<reduivy__Transaction_Order__c> { troToUpdate, troNoChange };
            
            // Create corresponding SVTs
            reduivy__Study_Voucher_Transaction__c svtToUpdate = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_UPDATE', studyVouchers[0].Id, troToUpdate.Id, SVT_Helper.STATUS_DRAFT
            );
            
            reduivy__Study_Voucher_Transaction__c svtNoChange = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_NOCHANGE', studyVouchers[0].Id, troNoChange.Id, SVT_Helper.STATUS_CONFIRMED
            );
            
            insert new List<reduivy__Study_Voucher_Transaction__c> { svtToUpdate, svtNoChange };
            
            Test.startTest();
            
            // Update only one TRO status (the other remains the same)
            troToUpdate.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            troNoChange.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED; // Same status, no change
            update new List<reduivy__Transaction_Order__c> { troToUpdate, troNoChange };
            
            Test.stopTest();
            
            // Assertions
            List<reduivy__Study_Voucher_Transaction__c> updatedSvts = [
                SELECT Id, reduivy__Status__c, reduivy__Transaction_Order__c
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id IN :new List<Id> { svtToUpdate.Id, svtNoChange.Id }
            ];
            
            for (reduivy__Study_Voucher_Transaction__c svt : updatedSvts) {
                if (svt.reduivy__Transaction_Order__c == troToUpdate.Id) {
                    System.assertEquals(SVT_Helper.STATUS_CONFIRMED, svt.reduivy__Status__c, 'SVT linked to changed TRO should be updated');
                } else {
                    System.assertEquals(SVT_Helper.STATUS_CONFIRMED, svt.reduivy__Status__c, 'SVT linked to unchanged TRO should remain the same');
                }
            }
        }
    }

    /**
     * @description Test multiple SVTs per TRO as admin
     */
    @IsTest
    static void testMultipleSVTsPerTROAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create one TRO
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO_MULTI', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 300.00, 300.00, 0.00
            );
            insert tro;
            
            // Create multiple SVTs for the same TRO
            List<reduivy__Study_Voucher_Transaction__c> svtList = new List<reduivy__Study_Voucher_Transaction__c>();
            for (Integer i = 1; i <= 3; i++) {
                reduivy__Study_Voucher_Transaction__c svt = REDU_TestData_UTIL.newStudyVoucherTransaction(
                    'SVT_MULTI_' + i, studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_DRAFT
                );
                svtList.add(svt);
            }
            insert svtList;
            
            Test.startTest();
            
            // Update TRO status from Draft to Confirmed
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            Test.stopTest();
            
            // Assertions - All SVTs for the TRO should be updated
            List<reduivy__Study_Voucher_Transaction__c> updatedSvts = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :tro.Id
            ];
            
            System.assertEquals(3, updatedSvts.size(), 'All 3 SVTs should be retrieved');
            
            for (reduivy__Study_Voucher_Transaction__c svt : updatedSvts) {
                System.assertEquals(SVT_Helper.STATUS_CONFIRMED, svt.reduivy__Status__c, 'All SVTs should be updated to Confirmed status');
            }
        }
    }

    /**
     * @description Test null status handling as admin
     */
    @IsTest
    static void testNullStatusHandlingAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create TRO with null status initially
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO_NULL', conStudent.Id, null, Date.today(), null, 100.00, 100.00, 0.00
            );
            insert tro;
            
            // Create SVT with Draft status
            reduivy__Study_Voucher_Transaction__c svt = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_NULL', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_DRAFT
            );
            insert svt;
            
            Test.startTest();
            
            // Update TRO status from null to Confirmed
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            // test multiple status changes
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_VOID;
            update tro;
            
            Test.stopTest();
            
            // Assertions - SVT should be updated to Void (last valid mapping)
            reduivy__Study_Voucher_Transaction__c updatedSvt = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :svt.Id
            ];
            System.assertEquals(SVT_Helper.STATUS_VOID, updatedSvt.reduivy__Status__c, 'SVT should be updated to Void status');
            
            // Verify TRO status
            reduivy__Transaction_Order__c updatedTro = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Transaction_Order__c 
                WHERE Id = :tro.Id
            ];
            System.assertEquals(TRO_Helper.STATUS_TYPE_VOID, updatedTro.reduivy__Status__c, 'TRO should have Void status');
        }
    }

    /**
     * @description Test multiple SVTs with different statuses all updated to same status as admin
     */
    @IsTest
    static void testMultipleSVTsWithDifferentStatusesUpdatedToSameAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create one TRO with Draft status
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO_DIFF_STATUS', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 500.00, 500.00, 0.00
            );
            insert tro;
            
            // Create multiple SVTs with different statuses for the same TRO
            List<reduivy__Study_Voucher_Transaction__c> svtList = new List<reduivy__Study_Voucher_Transaction__c>();
            
            // SVT 1 with Draft status
            reduivy__Study_Voucher_Transaction__c svt1 = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_DRAFT', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_DRAFT
            );
            svtList.add(svt1);
            
            // SVT 2 with Confirmed status
            reduivy__Study_Voucher_Transaction__c svt2 = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_CONFIRMED', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_CONFIRMED
            );
            svtList.add(svt2);
            
            // SVT 3 with Void status
            reduivy__Study_Voucher_Transaction__c svt3 = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_VOID', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_VOID
            );
            svtList.add(svt3);
            
            insert svtList;
            
            // Verify initial different statuses
            List<reduivy__Study_Voucher_Transaction__c> initialSvts = [
                SELECT Id, reduivy__Status__c, reduivy__Sample_Record_Code__c
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :tro.Id
                ORDER BY reduivy__Sample_Record_Code__c
            ];
            System.assertEquals(3, initialSvts.size(), 'Should have 3 SVTs');

            // Track which statuses are found
            Set<String> foundStatuses = new Set<String>();

            for (reduivy__Study_Voucher_Transaction__c svt : initialSvts) {
                foundStatuses.add(svt.reduivy__Status__c);
            }

            // Assert all required statuses exist
            System.assert(foundStatuses.contains(SVT_Helper.STATUS_DRAFT), 'Should contain Draft status');
            System.assert(foundStatuses.contains(SVT_Helper.STATUS_CONFIRMED), 'Should contain Confirmed status');
            System.assert(foundStatuses.contains(SVT_Helper.STATUS_VOID), 'Should contain Void status');
            
            Test.startTest();
            
            // Update TRO status from Draft to Confirmed
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            Test.stopTest();
            
            // Assertions - All SVTs should now have the same status (Confirmed)
            List<reduivy__Study_Voucher_Transaction__c> updatedSvts = [
                SELECT Id, reduivy__Status__c, reduivy__Sample_Record_Code__c
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :tro.Id
                ORDER BY reduivy__Sample_Record_Code__c
            ];
            
            System.assertEquals(3, updatedSvts.size(), 'Should still have 3 SVTs');
            
            for (reduivy__Study_Voucher_Transaction__c svt : updatedSvts) {
                System.assertEquals(SVT_Helper.STATUS_CONFIRMED, svt.reduivy__Status__c, 
                    'All SVTs should now have Confirmed status regardless of their initial status');
            }
        }
    }
	
    /**
     * @description Test positive scenario - Status change triggers SVT update as Faculty
     */
    @IsTest
    static void testPositiveScenarioStatusChangeUpdatesSVTAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create Transaction Order with Draft status
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO001', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 100.00, 100.00, 0.00
            );
            insert tro;
            
            // Create Study Voucher Transaction with Draft status
            reduivy__Study_Voucher_Transaction__c svt = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT001', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_DRAFT
            );
            insert svt;
            
            Test.startTest();
            
            // Update TRO status from Draft to Confirmed
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            Test.stopTest();
            
            // Assertions - SVT should be updated to Confirmed
            reduivy__Study_Voucher_Transaction__c updatedSvt = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :svt.Id
            ];
            System.assertEquals(SVT_Helper.STATUS_CONFIRMED, updatedSvt.reduivy__Status__c, 'SVT status should be updated to Confirmed');
        }
    }

    /**
     * @description Test no related Study Voucher Transactions as Faculty
     */
    @IsTest
    static void testNoRelatedSVTNoErrorsAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            // Create Transaction Order without any related SVT
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO002', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 200.00, 200.00, 0.00
            );
            insert tro;
            
            Test.startTest();
            
            // Update TRO status - should not cause errors even with no related SVT
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            Test.stopTest();
            
            // Assertions - No errors should occur and TRO should be updated
            reduivy__Transaction_Order__c updatedTro = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Transaction_Order__c 
                WHERE Id = :tro.Id
            ];
            System.assertEquals(TRO_Helper.STATUS_TYPE_CONFIRMED, updatedTro.reduivy__Status__c, 'TRO status should be updated successfully');
            
            // Verify no SVT exists for this TRO
            List<reduivy__Study_Voucher_Transaction__c> relatedSvts = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :tro.Id
            ];
            System.assertEquals(0, relatedSvts.size(), 'No SVT should exist for this TRO');
        }
    }

    /**
     * @description Test SVT already has correct status as Faculty
     */
    @IsTest
    static void testSVTAlreadyHasCorrectStatusNotUpdatedAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create Transaction Order with Confirmed status
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO003', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_CONFIRMED, 150.00, 0.00, 150.00
            );
            insert tro;
            
            // Create Study Voucher Transaction with already matching Confirmed status
            reduivy__Study_Voucher_Transaction__c svt = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT003', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_CONFIRMED
            );
            insert svt;
            
            Test.startTest();
            
            // Update TRO status to same value (Confirmed to Confirmed)
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            Test.stopTest();
            
            // Assertions - SVT should remain unchanged
            reduivy__Study_Voucher_Transaction__c updatedSvt = [
                SELECT Id, reduivy__Status__c, LastModifiedDate
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :svt.Id
            ];
            System.assertEquals(SVT_Helper.STATUS_CONFIRMED, updatedSvt.reduivy__Status__c, 'SVT status should remain Confirmed');
        }
    }

    /**
     * @description Test bulk operation scenario as Faculty
     */
    @IsTest
    static void testBulkUpdateMultipleTROsAndSVTsAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            List<reduivy__Transaction_Order__c> troList = new List<reduivy__Transaction_Order__c>();
            List<reduivy__Study_Voucher_Transaction__c> svtList = new List<reduivy__Study_Voucher_Transaction__c>();
            
            // Create multiple TROs and SVTs
            for (Integer i = 1; i <= 5; i++) {
                reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                    'TRO00' + i, conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 100.00 * i, 100.00 * i, 0.00
                );
                troList.add(tro);
            }
            insert troList;
            
            for (reduivy__Transaction_Order__c tro : troList) {
                reduivy__Study_Voucher_Transaction__c svt = REDU_TestData_UTIL.newStudyVoucherTransaction(
                    'SVT' + tro.reduivy__Sample_Record_Code__c, studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_DRAFT
                );
                svtList.add(svt);
            }
            insert svtList;
            
            Test.startTest();
            
            // Bulk update all TROs from Draft to Confirmed
            for (reduivy__Transaction_Order__c tro : troList) {
                tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            }
            update troList;
            
            Test.stopTest();
            
            // Assertions - All SVTs should be updated to Confirmed
            List<reduivy__Study_Voucher_Transaction__c> updatedSvts = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id IN :svtList
            ];
            System.assertEquals(5, updatedSvts.size(), 'All 5 SVTs should be retrieved');
            
            for (reduivy__Study_Voucher_Transaction__c svt : updatedSvts) {
                System.assertEquals(SVT_Helper.STATUS_CONFIRMED, svt.reduivy__Status__c, 'All SVT statuses should be updated to Confirmed');
            }
        }
    }

    /**
     * @description Test mixed scenario - Some TROs qualify, others don't as Faculty
     */
    @IsTest
    static void testMixedScenarioSelectiveUpdatesAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create TRO that will qualify for update
            reduivy__Transaction_Order__c troToUpdate = REDU_TestData_UTIL.newTransactionOrder(
                'TRO_UPDATE', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 100.00, 100.00, 0.00
            );
            
            // Create TRO that won't qualify (no status change)
            reduivy__Transaction_Order__c troNoChange = REDU_TestData_UTIL.newTransactionOrder(
                'TRO_NOCHANGE', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_CONFIRMED, 200.00, 0.00, 200.00
            );
            
            insert new List<reduivy__Transaction_Order__c> { troToUpdate, troNoChange };
            
            // Create corresponding SVTs
            reduivy__Study_Voucher_Transaction__c svtToUpdate = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_UPDATE', studyVouchers[0].Id, troToUpdate.Id, SVT_Helper.STATUS_DRAFT
            );
            
            reduivy__Study_Voucher_Transaction__c svtNoChange = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_NOCHANGE', studyVouchers[0].Id, troNoChange.Id, SVT_Helper.STATUS_CONFIRMED
            );
            
            insert new List<reduivy__Study_Voucher_Transaction__c> { svtToUpdate, svtNoChange };
            
            Test.startTest();
            
            // Update only one TRO status (the other remains the same)
            troToUpdate.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            troNoChange.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED; // Same status, no change
            update new List<reduivy__Transaction_Order__c> { troToUpdate, troNoChange };
            
            Test.stopTest();
            
            // Assertions
            List<reduivy__Study_Voucher_Transaction__c> updatedSvts = [
                SELECT Id, reduivy__Status__c, reduivy__Transaction_Order__c
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id IN :new List<Id> { svtToUpdate.Id, svtNoChange.Id }
            ];
            
            for (reduivy__Study_Voucher_Transaction__c svt : updatedSvts) {
                if (svt.reduivy__Transaction_Order__c == troToUpdate.Id) {
                    System.assertEquals(SVT_Helper.STATUS_CONFIRMED, svt.reduivy__Status__c, 'SVT linked to changed TRO should be updated');
                } else {
                    System.assertEquals(SVT_Helper.STATUS_CONFIRMED, svt.reduivy__Status__c, 'SVT linked to unchanged TRO should remain the same');
                }
            }
        }
    }

    /**
     * @description Test multiple SVTs per TRO as Faculty
     */
    @IsTest
    static void testMultipleSVTsPerTROAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create one TRO
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO_MULTI', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 300.00, 300.00, 0.00
            );
            insert tro;
            
            // Create multiple SVTs for the same TRO
            List<reduivy__Study_Voucher_Transaction__c> svtList = new List<reduivy__Study_Voucher_Transaction__c>();
            for (Integer i = 1; i <= 3; i++) {
                reduivy__Study_Voucher_Transaction__c svt = REDU_TestData_UTIL.newStudyVoucherTransaction(
                    'SVT_MULTI_' + i, studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_DRAFT
                );
                svtList.add(svt);
            }
            insert svtList;
            
            Test.startTest();
            
            // Update TRO status from Draft to Confirmed
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            Test.stopTest();
            
            // Assertions - All SVTs for the TRO should be updated
            List<reduivy__Study_Voucher_Transaction__c> updatedSvts = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :tro.Id
            ];
            
            System.assertEquals(3, updatedSvts.size(), 'All 3 SVTs should be retrieved');
            
            for (reduivy__Study_Voucher_Transaction__c svt : updatedSvts) {
                System.assertEquals(SVT_Helper.STATUS_CONFIRMED, svt.reduivy__Status__c, 'All SVTs should be updated to Confirmed status');
            }
        }
    }

    /**
     * @description Test null status handling as Faculty
     */
    @IsTest
    static void testNullStatusHandlingAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create TRO with null status initially
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO_NULL', conStudent.Id, null, Date.today(), null, 100.00, 100.00, 0.00
            );
            insert tro;
            
            // Create SVT with Draft status
            reduivy__Study_Voucher_Transaction__c svt = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_NULL', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_DRAFT
            );
            insert svt;
            
            Test.startTest();
            
            // Update TRO status from null to Confirmed
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            // test multiple status changes
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_VOID;
            update tro;
            
            Test.stopTest();
            
            // Assertions - SVT should be updated to Void (last valid mapping)
            reduivy__Study_Voucher_Transaction__c updatedSvt = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :svt.Id
            ];
            System.assertEquals(SVT_Helper.STATUS_VOID, updatedSvt.reduivy__Status__c, 'SVT should be updated to Void status');
            
            // Verify TRO status
            reduivy__Transaction_Order__c updatedTro = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Transaction_Order__c 
                WHERE Id = :tro.Id
            ];
            System.assertEquals(TRO_Helper.STATUS_TYPE_VOID, updatedTro.reduivy__Status__c, 'TRO should have Void status');
        }
    }

    /**
     * @description Test multiple SVTs with different statuses all updated to same status as Faculty
     */
    @IsTest
    static void testMultipleSVTsWithDifferentStatusesUpdatedToSameAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create one TRO with Draft status
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO_DIFF_STATUS', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 500.00, 500.00, 0.00
            );
            insert tro;
            
            // Create multiple SVTs with different statuses for the same TRO
            List<reduivy__Study_Voucher_Transaction__c> svtList = new List<reduivy__Study_Voucher_Transaction__c>();
            
            // SVT 1 with Draft status
            reduivy__Study_Voucher_Transaction__c svt1 = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_DRAFT', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_DRAFT
            );
            svtList.add(svt1);
            
            // SVT 2 with Confirmed status
            reduivy__Study_Voucher_Transaction__c svt2 = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_CONFIRMED', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_CONFIRMED
            );
            svtList.add(svt2);
            
            // SVT 3 with Void status
            reduivy__Study_Voucher_Transaction__c svt3 = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_VOID', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_VOID
            );
            svtList.add(svt3);
            
            insert svtList;
            
            // Verify initial different statuses
            List<reduivy__Study_Voucher_Transaction__c> initialSvts = [
                SELECT Id, reduivy__Status__c, reduivy__Sample_Record_Code__c
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :tro.Id
                ORDER BY reduivy__Sample_Record_Code__c
            ];
            System.assertEquals(3, initialSvts.size(), 'Should have 3 SVTs');

            // Track which statuses are found
            Set<String> foundStatuses = new Set<String>();

            for (reduivy__Study_Voucher_Transaction__c svt : initialSvts) {
                foundStatuses.add(svt.reduivy__Status__c);
            }

            // Assert all required statuses exist
            System.assert(foundStatuses.contains(SVT_Helper.STATUS_DRAFT), 'Should contain Draft status');
            System.assert(foundStatuses.contains(SVT_Helper.STATUS_CONFIRMED), 'Should contain Confirmed status');
            System.assert(foundStatuses.contains(SVT_Helper.STATUS_VOID), 'Should contain Void status');
            
            Test.startTest();
            
            // Update TRO status from Draft to Confirmed
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            Test.stopTest();
            
            // Assertions - All SVTs should now have the same status (Confirmed)
            List<reduivy__Study_Voucher_Transaction__c> updatedSvts = [
                SELECT Id, reduivy__Status__c, reduivy__Sample_Record_Code__c
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :tro.Id
                ORDER BY reduivy__Sample_Record_Code__c
            ];
            
            System.assertEquals(3, updatedSvts.size(), 'Should still have 3 SVTs');
            
            for (reduivy__Study_Voucher_Transaction__c svt : updatedSvts) {
                System.assertEquals(SVT_Helper.STATUS_CONFIRMED, svt.reduivy__Status__c, 
                    'All SVTs should now have Confirmed status regardless of their initial status');
            }
        }
    }
    
    /**
     * @description Test positive scenario - Status change triggers SVT update as Student
     */
    @IsTest
    static void testPositiveScenarioStatusChangeUpdatesSVTAsStudent() {

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: conStudent.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        System.runAs(studentUser) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create Transaction Order with Draft status
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO001', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 100.00, 100.00, 0.00
            );
            insert tro;
            
            // Create Study Voucher Transaction with Draft status
            reduivy__Study_Voucher_Transaction__c svt = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT001', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_DRAFT
            );
            insert svt;
            
            Test.startTest();
            
            // Update TRO status from Draft to Confirmed
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            Test.stopTest();
            
            // Assertions - SVT should be updated to Confirmed
            reduivy__Study_Voucher_Transaction__c updatedSvt = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :svt.Id
            ];
            System.assertEquals(SVT_Helper.STATUS_CONFIRMED, updatedSvt.reduivy__Status__c, 'SVT status should be updated to Confirmed');
        }
    }

    /**
     * @description Test no related Study Voucher Transactions as Student
     */
    @IsTest
    static void testNoRelatedSVTNoErrorsAsStudent() {

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: conStudent.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        System.runAs(studentUser) {
            // Create Transaction Order without any related SVT
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO002', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 200.00, 200.00, 0.00
            );
            insert tro;
            
            Test.startTest();
            
            // Update TRO status - should not cause errors even with no related SVT
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            Test.stopTest();
            
            // Assertions - No errors should occur and TRO should be updated
            reduivy__Transaction_Order__c updatedTro = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Transaction_Order__c 
                WHERE Id = :tro.Id
            ];
            System.assertEquals(TRO_Helper.STATUS_TYPE_CONFIRMED, updatedTro.reduivy__Status__c, 'TRO status should be updated successfully');
            
            // Verify no SVT exists for this TRO
            List<reduivy__Study_Voucher_Transaction__c> relatedSvts = [
                SELECT Id FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :tro.Id
            ];
            System.assertEquals(0, relatedSvts.size(), 'No SVT should exist for this TRO');
        }
    }

    /**
     * @description Test SVT already has correct status as Student
     */
    @IsTest
    static void testSVTAlreadyHasCorrectStatusNotUpdatedAsStudent() {

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: conStudent.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        System.runAs(studentUser) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create Transaction Order with Confirmed status
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO003', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_CONFIRMED, 150.00, 0.00, 150.00
            );
            insert tro;
            
            // Create Study Voucher Transaction with already matching Confirmed status
            reduivy__Study_Voucher_Transaction__c svt = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT003', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_CONFIRMED
            );
            insert svt;
            
            Test.startTest();
            
            // Update TRO status to same value (Confirmed to Confirmed)
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            Test.stopTest();
            
            // Assertions - SVT should remain unchanged
            reduivy__Study_Voucher_Transaction__c updatedSvt = [
                SELECT Id, reduivy__Status__c, LastModifiedDate
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :svt.Id
            ];
            System.assertEquals(SVT_Helper.STATUS_CONFIRMED, updatedSvt.reduivy__Status__c, 'SVT status should remain Confirmed');
        }
    }

    /**
     * @description Test bulk operation scenario as Student
     */
    @IsTest
    static void testBulkUpdateMultipleTROsAndSVTsAsStudent() {

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: conStudent.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        System.runAs(studentUser) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            List<reduivy__Transaction_Order__c> troList = new List<reduivy__Transaction_Order__c>();
            List<reduivy__Study_Voucher_Transaction__c> svtList = new List<reduivy__Study_Voucher_Transaction__c>();
            
            // Create multiple TROs and SVTs
            for (Integer i = 1; i <= 5; i++) {
                reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                    'TRO00' + i, conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 100.00 * i, 100.00 * i, 0.00
                );
                troList.add(tro);
            }
            insert troList;
            
            for (reduivy__Transaction_Order__c tro : troList) {
                reduivy__Study_Voucher_Transaction__c svt = REDU_TestData_UTIL.newStudyVoucherTransaction(
                    'SVT' + tro.reduivy__Sample_Record_Code__c, studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_DRAFT
                );
                svtList.add(svt);
            }
            insert svtList;
            
            Test.startTest();
            
            // Bulk update all TROs from Draft to Confirmed
            for (reduivy__Transaction_Order__c tro : troList) {
                tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            }
            update troList;
            
            Test.stopTest();
            
            // Assertions - All SVTs should be updated to Confirmed
            List<reduivy__Study_Voucher_Transaction__c> updatedSvts = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id IN :svtList
            ];
            System.assertEquals(5, updatedSvts.size(), 'All 5 SVTs should be retrieved');
            
            for (reduivy__Study_Voucher_Transaction__c svt : updatedSvts) {
                System.assertEquals(SVT_Helper.STATUS_CONFIRMED, svt.reduivy__Status__c, 'All SVT statuses should be updated to Confirmed');
            }
        }
    }

    /**
     * @description Test mixed scenario - Some TROs qualify, others don't as Student
     */
    @IsTest
    static void testMixedScenarioSelectiveUpdatesAsStudent() {

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: conStudent.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        System.runAs(studentUser) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create TRO that will qualify for update
            reduivy__Transaction_Order__c troToUpdate = REDU_TestData_UTIL.newTransactionOrder(
                'TRO_UPDATE', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 100.00, 100.00, 0.00
            );
            
            // Create TRO that won't qualify (no status change)
            reduivy__Transaction_Order__c troNoChange = REDU_TestData_UTIL.newTransactionOrder(
                'TRO_NOCHANGE', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_CONFIRMED, 200.00, 0.00, 200.00
            );
            
            insert new List<reduivy__Transaction_Order__c> { troToUpdate, troNoChange };
            
            // Create corresponding SVTs
            reduivy__Study_Voucher_Transaction__c svtToUpdate = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_UPDATE', studyVouchers[0].Id, troToUpdate.Id, SVT_Helper.STATUS_DRAFT
            );
            
            reduivy__Study_Voucher_Transaction__c svtNoChange = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_NOCHANGE', studyVouchers[0].Id, troNoChange.Id, SVT_Helper.STATUS_CONFIRMED
            );
            
            insert new List<reduivy__Study_Voucher_Transaction__c> { svtToUpdate, svtNoChange };
            
            Test.startTest();
            
            // Update only one TRO status (the other remains the same)
            troToUpdate.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            troNoChange.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED; // Same status, no change
            update new List<reduivy__Transaction_Order__c> { troToUpdate, troNoChange };
            
            Test.stopTest();
            
            // Assertions
            List<reduivy__Study_Voucher_Transaction__c> updatedSvts = [
                SELECT Id, reduivy__Status__c, reduivy__Transaction_Order__c
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id IN :new List<Id> { svtToUpdate.Id, svtNoChange.Id }
            ];
            
            for (reduivy__Study_Voucher_Transaction__c svt : updatedSvts) {
                if (svt.reduivy__Transaction_Order__c == troToUpdate.Id) {
                    System.assertEquals(SVT_Helper.STATUS_CONFIRMED, svt.reduivy__Status__c, 'SVT linked to changed TRO should be updated');
                } else {
                    System.assertEquals(SVT_Helper.STATUS_CONFIRMED, svt.reduivy__Status__c, 'SVT linked to unchanged TRO should remain the same');
                }
            }
        }
    }

    /**
     * @description Test multiple SVTs per TRO as Student
     */
    @IsTest
    static void testMultipleSVTsPerTROAsStudent() {

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: conStudent.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        System.runAs(studentUser) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create one TRO
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO_MULTI', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 300.00, 300.00, 0.00
            );
            insert tro;
            
            // Create multiple SVTs for the same TRO
            List<reduivy__Study_Voucher_Transaction__c> svtList = new List<reduivy__Study_Voucher_Transaction__c>();
            for (Integer i = 1; i <= 3; i++) {
                reduivy__Study_Voucher_Transaction__c svt = REDU_TestData_UTIL.newStudyVoucherTransaction(
                    'SVT_MULTI_' + i, studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_DRAFT
                );
                svtList.add(svt);
            }
            insert svtList;
            
            Test.startTest();
            
            // Update TRO status from Draft to Confirmed
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            Test.stopTest();
            
            // Assertions - All SVTs for the TRO should be updated
            List<reduivy__Study_Voucher_Transaction__c> updatedSvts = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :tro.Id
            ];
            
            System.assertEquals(3, updatedSvts.size(), 'All 3 SVTs should be retrieved');
            
            for (reduivy__Study_Voucher_Transaction__c svt : updatedSvts) {
                System.assertEquals(SVT_Helper.STATUS_CONFIRMED, svt.reduivy__Status__c, 'All SVTs should be updated to Confirmed status');
            }
        }
    }

    /**
     * @description Test null status handling as Student
     */
    @IsTest
    static void testNullStatusHandlingAsStudent() {

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: conStudent.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        System.runAs(studentUser) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create TRO with null status initially
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO_NULL', conStudent.Id, null, Date.today(), null, 100.00, 100.00, 0.00
            );
            insert tro;
            
            // Create SVT with Draft status
            reduivy__Study_Voucher_Transaction__c svt = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_NULL', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_DRAFT
            );
            insert svt;
            
            Test.startTest();
            
            // Update TRO status from null to Confirmed
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            // test multiple status changes
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_VOID;
            update tro;
            
            Test.stopTest();
            
            // Assertions - SVT should be updated to Void (last valid mapping)
            reduivy__Study_Voucher_Transaction__c updatedSvt = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE Id = :svt.Id
            ];
            System.assertEquals(SVT_Helper.STATUS_VOID, updatedSvt.reduivy__Status__c, 'SVT should be updated to Void status');
            
            // Verify TRO status
            reduivy__Transaction_Order__c updatedTro = [
                SELECT Id, reduivy__Status__c 
                FROM reduivy__Transaction_Order__c 
                WHERE Id = :tro.Id
            ];
            System.assertEquals(TRO_Helper.STATUS_TYPE_VOID, updatedTro.reduivy__Status__c, 'TRO should have Void status');
        }
    }

    /**
     * @description Test multiple SVTs with different statuses all updated to same status as Student
     */
    @IsTest
    static void testMultipleSVTsWithDifferentStatusesUpdatedToSameAsStudent() {

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: conStudent.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        System.runAs(studentUser) {
            // Query existing study voucher from test setup
            List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c LIMIT 1];
            System.assert(!studyVouchers.isEmpty(), 'Study voucher should exist from test setup');
            
            // Create one TRO with Draft status
            reduivy__Transaction_Order__c tro = REDU_TestData_UTIL.newTransactionOrder(
                'TRO_DIFF_STATUS', conStudent.Id, null, Date.today(), TRO_Helper.STATUS_TYPE_DRAFT, 500.00, 500.00, 0.00
            );
            insert tro;
            
            // Create multiple SVTs with different statuses for the same TRO
            List<reduivy__Study_Voucher_Transaction__c> svtList = new List<reduivy__Study_Voucher_Transaction__c>();
            
            // SVT 1 with Draft status
            reduivy__Study_Voucher_Transaction__c svt1 = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_DRAFT', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_DRAFT
            );
            svtList.add(svt1);
            
            // SVT 2 with Confirmed status
            reduivy__Study_Voucher_Transaction__c svt2 = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_CONFIRMED', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_CONFIRMED
            );
            svtList.add(svt2);
            
            // SVT 3 with Void status
            reduivy__Study_Voucher_Transaction__c svt3 = REDU_TestData_UTIL.newStudyVoucherTransaction(
                'SVT_VOID', studyVouchers[0].Id, tro.Id, SVT_Helper.STATUS_VOID
            );
            svtList.add(svt3);
            
            insert svtList;
            
            // Verify initial different statuses
            List<reduivy__Study_Voucher_Transaction__c> initialSvts = [
                SELECT Id, reduivy__Status__c, reduivy__Sample_Record_Code__c
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :tro.Id
                ORDER BY reduivy__Sample_Record_Code__c
            ];
            System.assertEquals(3, initialSvts.size(), 'Should have 3 SVTs');

            // Track which statuses are found
            Set<String> foundStatuses = new Set<String>();

            for (reduivy__Study_Voucher_Transaction__c svt : initialSvts) {
                foundStatuses.add(svt.reduivy__Status__c);
            }

            // Assert all required statuses exist
            System.assert(foundStatuses.contains(SVT_Helper.STATUS_DRAFT), 'Should contain Draft status');
            System.assert(foundStatuses.contains(SVT_Helper.STATUS_CONFIRMED), 'Should contain Confirmed status');
            System.assert(foundStatuses.contains(SVT_Helper.STATUS_VOID), 'Should contain Void status');
            
            Test.startTest();
            
            // Update TRO status from Draft to Confirmed
            tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
            update tro;
            
            Test.stopTest();
            
            // Assertions - All SVTs should now have the same status (Confirmed)
            List<reduivy__Study_Voucher_Transaction__c> updatedSvts = [
                SELECT Id, reduivy__Status__c, reduivy__Sample_Record_Code__c
                FROM reduivy__Study_Voucher_Transaction__c 
                WHERE reduivy__Transaction_Order__c = :tro.Id
                ORDER BY reduivy__Sample_Record_Code__c
            ];
            
            System.assertEquals(3, updatedSvts.size(), 'Should still have 3 SVTs');
            
            for (reduivy__Study_Voucher_Transaction__c svt : updatedSvts) {
                System.assertEquals(SVT_Helper.STATUS_CONFIRMED, svt.reduivy__Status__c, 
                    'All SVTs should now have Confirmed status regardless of their initial status');
            }
        }
    }
}