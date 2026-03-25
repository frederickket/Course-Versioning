/**
 * @author      WDCi (XiRouh)
 * @date        Aug 2025
 * @group       Test
 * @description Test class for TRP_FundingAllocationRollup_EXE
 * @changehistory
 * ISS-002587 13-08-2025 XiRouh - new class
 */
@IsTest
public inherited sharing class TRP_FundingAllocationRollup_TEST {

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
        	
            testFactory.initMasterData(SFD_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }

    //Admin
    // ========== AFTER INSERT TESTS ==========

    /**
     * @description Test executeAfterInsert with active TRP having amount as Admin
     */
    @IsTest
    static void testExecuteAfterInsertActiveTrpWithAmountAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            Test.startTest();
            
            // Create active Transaction Payment with amount
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            Test.stopTest();
            
            // Assertions
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be rolled up from active TRP');
        }
    }

    /**
     * @description Test executeAfterInsert with draft TRP as Admin (no rollup)
     */
    @IsTest
    static void testExecuteAfterInsertDraftTrpAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            Test.startTest();
            
            // Create draft Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Make it draft
            insert trp;
            
            Test.stopTest();
            
            // Assertions
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should remain 0 as TRP is draft');
        }
    }

    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test executeAfterUpdate when TRP amount changes as Admin
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
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 250.00');
            
            Test.startTest();
            
            // Update TRP amount
            trp.reduivy__Amount__c = 500.00;
            update trp;
            
            Test.stopTest();
            
            // Assertions
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(500.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be updated to 500.00 after amount change');
        }
    }

    /**
     * @description Test executeAfterUpdate when TRP status changes from active to draft as Admin
     */
    @IsTest
    static void testExecuteAfterUpdateStatusChangedToDraftAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 250.00');
            
            Test.startTest();
            
            // Change status to draft
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT;
            update trp;
            
            Test.stopTest();
            
            // Assertions - amount should be removed from rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 0.00 after status change to draft');
        }
    }

    /**
     * @description Test executeAfterUpdate when TRP status changes from draft to active as Admin
     */
    @IsTest
    static void testExecuteAfterUpdateStatusChangedToActiveAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create draft Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Set to draft initially
            insert trp;
            
            // Verify initial state - should be 0 since TRP is draft
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 0.00 for draft TRP');
            
            Test.startTest();
            
            // Change status to active
            trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
            update trp;
            
            Test.stopTest();
            
            // Assertions - amount should be included in rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 250.00 after status change to active');
        }
    }

    /**
     * @description Test executeAfterUpdate when TRP IFA reference changes as Admin
     */
    @IsTest
    static void testExecuteAfterUpdateIfaReferenceChangedAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            
            // Create two Individual Funding Allocations
            reduivy__Individual_Funding_Allocation__c ifa1 = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            
            reduivy__Individual_Funding_Allocation__c ifa2 = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c + '_2',
                studentContact.Id,
                std.Id,
                1500.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert new List<reduivy__Individual_Funding_Allocation__c>{ifa1, ifa2};
            
            // Create active Transaction Payment linked to first IFA
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa1.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            List<reduivy__Individual_Funding_Allocation__c> ifas = [SELECT Id, reduivy__Disbursed_Amount__c 
                                                                    FROM reduivy__Individual_Funding_Allocation__c 
                                                                    WHERE Id IN (:ifa1.Id, :ifa2.Id)
                                                                    ORDER BY Id];
            System.assertEquals(250.00, ifas[0].reduivy__Disbursed_Amount__c, 'IFA1 should have disbursed amount of 250.00');
            System.assertEquals(0.00, ifas[1].reduivy__Disbursed_Amount__c, 'IFA2 should have disbursed amount of 0.00');
            
            Test.startTest();
            
            // Change IFA reference from ifa1 to ifa2
            trp.reduivy__Individual_Funding_Allocation__c = ifa2.Id;
            update trp;
            
            Test.stopTest();
            
            // Assertions - amount should be moved from IFA1 to IFA2
            ifas = [SELECT Id, reduivy__Disbursed_Amount__c 
                    FROM reduivy__Individual_Funding_Allocation__c 
                    WHERE Id IN (:ifa1.Id, :ifa2.Id)
                    ORDER BY Id];
            System.assertEquals(0.00, ifas[0].reduivy__Disbursed_Amount__c, 'IFA1 should have disbursed amount of 0.00 after reference change');
            System.assertEquals(250.00, ifas[1].reduivy__Disbursed_Amount__c, 'IFA2 should have disbursed amount of 250.00 after reference change');
        }
    }

    /**
     * @description Test executeAfterUpdate with no relevant field changes as Admin (no rollup)
     */
    @IsTest
    static void testExecuteAfterUpdateNoRelevantChangesAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 250.00');
            Decimal initialAmount = ifa.reduivy__Disbursed_Amount__c;
            
            Test.startTest();
            
            // Update non-relevant field (Applied Amount - this doesn't affect rollup)
            trp.reduivy__Applied_Amount__c = 300.00;
            update trp;
            
            Test.stopTest();
            
            // Assertions - amount should remain unchanged
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(initialAmount, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should remain unchanged when non-relevant fields are updated');
        }
    }

    /**
     * @description Test executeAfterUpdate when multiple relevant fields change simultaneously as Admin
     */
    @IsTest
    static void testExecuteAfterUpdateMultipleFieldsChangedAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create draft Transaction Payment with initial amount
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Set to draft initially
            insert trp;
            
            // Verify initial state - should be 0 since TRP is draft
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 0.00 for draft TRP');
            
            Test.startTest();
            
            // Update both status and amount simultaneously
            trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
            trp.reduivy__Amount__c = 500.00;
            update trp;
            
            Test.stopTest();
            
            // Assertions - should reflect both changes (active status + new amount)
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(500.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 500.00 reflecting both status and amount changes');
        }
    }

    /**
     * @description Test executeAfterUpdate when TRP IFA reference changes from null to populated
     */
    @IsTest
    static void testExecuteAfterUpdateIfaReferenceFromNullAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment without IFA reference initially
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                null, // No IFA reference initially
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial state
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 0');
            
            Test.startTest();
            
            // Update TRP to add IFA reference
            trp.reduivy__Individual_Funding_Allocation__c = ifa.Id;
            update trp;
            
            Test.stopTest();
            
            // Assertions
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be rolled up after IFA reference is added');
        }
    }

    /**
     * @description Test executeAfterUpdate when TRP IFA reference changes from populated to null
     */
    @IsTest
    static void testExecuteAfterUpdateIfaReferenceToNullAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment with IFA reference
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 250.00');
            
            Test.startTest();
            
            // Update TRP to remove IFA reference
            trp.reduivy__Individual_Funding_Allocation__c = null;
            update trp;
            
            Test.stopTest();
            
            // Assertions - amount should be removed from rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 0.00 after IFA reference is removed');
        }
    }
	
    // ========== AFTER DELETE TESTS ==========

    /**
     * @description Test executeAfterDelete with active TRP having amount as Admin
     */
    @IsTest
    static void testExecuteAfterDeleteActiveTrpWithAmountAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment with amount
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                250.00,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 250.00');
            
            Test.startTest();
            
            // Delete the TRP
            delete trp;
            
            Test.stopTest();
            
            // Assertions - amount should be removed from rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 0.00 after deleting active TRP');
        }
    }

    /**
     * @description Test executeAfterDelete with draft TRP as Admin (no rollup)
     */
    @IsTest
    static void testExecuteAfterDeleteDraftTrpAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create draft Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                250.00,
                null // applicableItemType
            );
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Make it draft
            insert trp;
            
            // Verify initial state - should be 0 since TRP is draft
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 0.00 for draft TRP');
            
            Test.startTest();
            
            // Delete the draft TRP
            delete trp;
            
            Test.stopTest();
            
            // Assertions - amount should remain 0 as draft TRP deletion doesn't affect rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should remain 0.00 after deleting draft TRP');
        }
    }

    // ========== AFTER UNDELETE TESTS ==========

    /**
     * @description Test executeAfterUndelete with active TRP having amount as Admin
     */
    @IsTest
    static void testExecuteAfterUndeleteActiveTrpWithAmountAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment with amount
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                250.00,
                null // applicableItemType
            );
            insert trp;
            
            // Delete the TRP first
            delete trp;
            
            // Verify TRP deletion reduced the rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 0.00 after deletion');
            
            Test.startTest();
            
            // Undelete the TRP
            undelete trp;
            
            Test.stopTest();
            
            // Assertions - amount should be added back to rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 250.00 after undeleting active TRP');
        }
    }

    /**
     * @description Test executeAfterUndelete with draft TRP as Admin (no rollup)
     */
    @IsTest
    static void testExecuteAfterUndeleteDraftTrpAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(ADMIN_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create draft Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                250.00,
                null // applicableItemType
            );
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Make it draft
            insert trp;
            
            // Delete the TRP
            delete trp;
            
            // Verify initial state - should remain 0 since TRP was draft
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 0.00 before and after deletion');
            
            Test.startTest();
            
            // Undelete the draft TRP
            undelete trp;
            
            Test.stopTest();
            
            // Assertions - amount should remain 0 as draft TRP undelete doesn't affect rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should remain 0.00 after undeleting draft TRP');
        }
    }

    //Student
    // ========== AFTER INSERT TESTS ==========

    /**
     * @description Test executeAfterInsert with active TRP having amount as Student
     */
    @IsTest
    static void testExecuteAfterInsertActiveTrpWithAmountAsStudent() {
                
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
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(studentUser) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            Test.startTest();
            
            // Create active Transaction Payment with amount
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            Test.stopTest();
            
            // Assertions
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be rolled up from active TRP');
        }
    }

    /**
     * @description Test executeAfterInsert with draft TRP as Student (no rollup)
     */
    @IsTest
    static void testExecuteAfterInsertDraftTrpAsStudent() {
                
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
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(studentUser) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            Test.startTest();
            
            // Create draft Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Make it draft
            insert trp;
            
            Test.stopTest();
            
            // Assertions
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should remain 0 as TRP is draft');
        }
    }

    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test executeAfterUpdate when TRP amount changes as Student
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
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(studentUser) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 250.00');
            
            Test.startTest();
            
            // Update TRP amount
            trp.reduivy__Amount__c = 500.00;
            update trp;
            
            Test.stopTest();
            
            // Assertions
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(500.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be updated to 500.00 after amount change');
        }
    }

    /**
     * @description Test executeAfterUpdate when TRP status changes from active to draft as Student
     */
    @IsTest
    static void testExecuteAfterUpdateStatusChangedToDraftAsStudent() {
                
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
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(studentUser) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 250.00');
            
            Test.startTest();
            
            // Change status to draft
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT;
            update trp;
            
            Test.stopTest();
            
            // Assertions - amount should be removed from rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 0.00 after status change to draft');
        }
    }

    /**
     * @description Test executeAfterUpdate when TRP status changes from draft to active as Student
     */
    @IsTest
    static void testExecuteAfterUpdateStatusChangedToActiveAsStudent() {
                
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
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(studentUser) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create draft Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Set to draft initially
            insert trp;
            
            // Verify initial state - should be 0 since TRP is draft
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 0.00 for draft TRP');
            
            Test.startTest();
            
            // Change status to active
            trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
            update trp;
            
            Test.stopTest();
            
            // Assertions - amount should be included in rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 250.00 after status change to active');
        }
    }

    /**
     * @description Test executeAfterUpdate when TRP IFA reference changes as Student
     */
    @IsTest
    static void testExecuteAfterUpdateIfaReferenceChangedAsStudent() {
                
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
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(studentUser) {
            
            // Create two Individual Funding Allocations
            reduivy__Individual_Funding_Allocation__c ifa1 = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            
            reduivy__Individual_Funding_Allocation__c ifa2 = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c + '_2',
                studentContact.Id,
                std.Id,
                1500.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert new List<reduivy__Individual_Funding_Allocation__c>{ifa1, ifa2};
            
            // Create active Transaction Payment linked to first IFA
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa1.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            List<reduivy__Individual_Funding_Allocation__c> ifas = [SELECT Id, reduivy__Disbursed_Amount__c 
                                                                    FROM reduivy__Individual_Funding_Allocation__c 
                                                                    WHERE Id IN (:ifa1.Id, :ifa2.Id)
                                                                    ORDER BY Id];
            System.assertEquals(250.00, ifas[0].reduivy__Disbursed_Amount__c, 'IFA1 should have disbursed amount of 250.00');
            System.assertEquals(0.00, ifas[1].reduivy__Disbursed_Amount__c, 'IFA2 should have disbursed amount of 0.00');
            
            Test.startTest();
            
            // Change IFA reference from ifa1 to ifa2
            trp.reduivy__Individual_Funding_Allocation__c = ifa2.Id;
            update trp;
            
            Test.stopTest();
            
            // Assertions - amount should be moved from IFA1 to IFA2
            ifas = [SELECT Id, reduivy__Disbursed_Amount__c 
                    FROM reduivy__Individual_Funding_Allocation__c 
                    WHERE Id IN (:ifa1.Id, :ifa2.Id)
                    ORDER BY Id];
            System.assertEquals(0.00, ifas[0].reduivy__Disbursed_Amount__c, 'IFA1 should have disbursed amount of 0.00 after reference change');
            System.assertEquals(250.00, ifas[1].reduivy__Disbursed_Amount__c, 'IFA2 should have disbursed amount of 250.00 after reference change');
        }
    }

    /**
     * @description Test executeAfterUpdate with no relevant field changes as Student (no rollup)
     */
    @IsTest
    static void testExecuteAfterUpdateNoRelevantChangesAsStudent() {
                
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
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(studentUser) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 250.00');
            Decimal initialAmount = ifa.reduivy__Disbursed_Amount__c;
            
            Test.startTest();
            
            // Update non-relevant field (Applied Amount - this doesn't affect rollup)
            trp.reduivy__Applied_Amount__c = 300.00;
            update trp;
            
            Test.stopTest();
            
            // Assertions - amount should remain unchanged
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(initialAmount, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should remain unchanged when non-relevant fields are updated');
        }
    }

    /**
     * @description Test executeAfterUpdate when multiple relevant fields change simultaneously as Student
     */
    @IsTest
    static void testExecuteAfterUpdateMultipleFieldsChangedAsStudent() {
                
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
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(studentUser) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create draft Transaction Payment with initial amount
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Set to draft initially
            insert trp;
            
            // Verify initial state - should be 0 since TRP is draft
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 0.00 for draft TRP');
            
            Test.startTest();
            
            // Update both status and amount simultaneously
            trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
            trp.reduivy__Amount__c = 500.00;
            update trp;
            
            Test.stopTest();
            
            // Assertions - should reflect both changes (active status + new amount)
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(500.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 500.00 reflecting both status and amount changes');
        }
    }

    /**
     * @description Test executeAfterUpdate when TRP IFA reference changes from null to populated
     */
    @IsTest
    static void testExecuteAfterUpdateIfaReferenceFromNullAsStudent() {
                
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
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(studentUser) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment without IFA reference initially
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                null, // No IFA reference initially
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial state
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 0');
            
            Test.startTest();
            
            // Update TRP to add IFA reference
            trp.reduivy__Individual_Funding_Allocation__c = ifa.Id;
            update trp;
            
            Test.stopTest();
            
            // Assertions
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be rolled up after IFA reference is added');
        }
    }

    /**
     * @description Test executeAfterUpdate when TRP IFA reference changes from populated to null
     */
    @IsTest
    static void testExecuteAfterUpdateIfaReferenceToNullAsStudent() {
                
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
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(studentUser) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment with IFA reference
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 250.00');
            
            Test.startTest();
            
            // Update TRP to remove IFA reference
            trp.reduivy__Individual_Funding_Allocation__c = null;
            update trp;
            
            Test.stopTest();
            
            // Assertions - amount should be removed from rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 0.00 after IFA reference is removed');
        }
    }
	
    // ========== AFTER DELETE TESTS ==========

    /**
     * @description Test executeAfterDelete with active TRP having amount as Student
     */
    @IsTest
    static void testExecuteAfterDeleteActiveTrpWithAmountAsStudent() {
                
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
		
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(studentUser) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment with amount
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                250.00,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 250.00');
            
            Test.startTest();
            
            // Delete the TRP
            delete trp;
            
            Test.stopTest();
            
            // Assertions - amount should be removed from rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 0.00 after deleting active TRP');
        }
    }

    /**
     * @description Test executeAfterDelete with draft TRP as Student (no rollup)
     */
    @IsTest
    static void testExecuteAfterDeleteDraftTrpAsStudent() {
                
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
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(studentUser) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create draft Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                250.00,
                null // applicableItemType
            );
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Make it draft
            insert trp;
            
            // Verify initial state - should be 0 since TRP is draft
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 0.00 for draft TRP');
            
            Test.startTest();
            
            // Delete the draft TRP
            delete trp;
            
            Test.stopTest();
            
            // Assertions - amount should remain 0 as draft TRP deletion doesn't affect rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should remain 0.00 after deleting draft TRP');
        }
    }

    // ========== AFTER UNDELETE TESTS ==========

    /**
     * @description Test executeAfterUndelete with active TRP having amount as Student
     */
    @IsTest
    static void testExecuteAfterUndeleteActiveTrpWithAmountAsStudent() {
                
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
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(studentUser) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment with amount
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                250.00,
                null // applicableItemType
            );
            insert trp;
            
            // Delete the TRP first
            delete trp;
            
            // Verify TRP deletion reduced the rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 0.00 after deletion');
            
            Test.startTest();
            
            // Undelete the TRP
            undelete trp;
            
            Test.stopTest();
            
            // Assertions - amount should be added back to rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 250.00 after undeleting active TRP');
        }
    }

    /**
     * @description Test executeAfterUndelete with draft TRP as Student (no rollup)
     */
    @IsTest
    static void testExecuteAfterUndeleteDraftTrpAsStudent() {
                
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
		
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(studentUser) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create draft Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                250.00,
                null // applicableItemType
            );
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Make it draft
            insert trp;
            
            // Delete the TRP
            delete trp;
            
            // Verify initial state - should remain 0 since TRP was draft
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 0.00 before and after deletion');
            
            Test.startTest();
            
            // Undelete the draft TRP
            undelete trp;
            
            Test.stopTest();
            
            // Assertions - amount should remain 0 as draft TRP undelete doesn't affect rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should remain 0.00 after undeleting draft TRP');
        }
    }

    //Faculty
    // ========== AFTER INSERT TESTS ==========

    /**
     * @description Test executeAfterInsert with active TRP having amount as Faculty
     */
    @IsTest
    static void testExecuteAfterInsertActiveTrpWithAmountAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            Test.startTest();
            
            // Create active Transaction Payment with amount
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            Test.stopTest();
            
            // Assertions
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be rolled up from active TRP');
        }
    }

    /**
     * @description Test executeAfterInsert with draft TRP as Faculty (no rollup)
     */
    @IsTest
    static void testExecuteAfterInsertDraftTrpAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            Test.startTest();
            
            // Create draft Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Make it draft
            insert trp;
            
            Test.stopTest();
            
            // Assertions
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should remain 0 as TRP is draft');
        }
    }

    // ========== AFTER UPDATE TESTS ==========

    /**
     * @description Test executeAfterUpdate when TRP amount changes as Faculty
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
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 250.00');
            
            Test.startTest();
            
            // Update TRP amount
            trp.reduivy__Amount__c = 500.00;
            update trp;
            
            Test.stopTest();
            
            // Assertions
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(500.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be updated to 500.00 after amount change');
        }
    }

    /**
     * @description Test executeAfterUpdate when TRP status changes from active to draft as Faculty
     */
    @IsTest
    static void testExecuteAfterUpdateStatusChangedToDraftAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 250.00');
            
            Test.startTest();
            
            // Change status to draft
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT;
            update trp;
            
            Test.stopTest();
            
            // Assertions - amount should be removed from rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 0.00 after status change to draft');
        }
    }

    /**
     * @description Test executeAfterUpdate when TRP status changes from draft to active as Faculty
     */
    @IsTest
    static void testExecuteAfterUpdateStatusChangedToActiveAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create draft Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Set to draft initially
            insert trp;
            
            // Verify initial state - should be 0 since TRP is draft
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 0.00 for draft TRP');
            
            Test.startTest();
            
            // Change status to active
            trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
            update trp;
            
            Test.stopTest();
            
            // Assertions - amount should be included in rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 250.00 after status change to active');
        }
    }

    /**
     * @description Test executeAfterUpdate when TRP IFA reference changes as Faculty
     */
    @IsTest
    static void testExecuteAfterUpdateIfaReferenceChangedAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            
            // Create two Individual Funding Allocations
            reduivy__Individual_Funding_Allocation__c ifa1 = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            
            reduivy__Individual_Funding_Allocation__c ifa2 = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c + '_2',
                studentContact.Id,
                std.Id,
                1500.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert new List<reduivy__Individual_Funding_Allocation__c>{ifa1, ifa2};
            
            // Create active Transaction Payment linked to first IFA
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa1.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            List<reduivy__Individual_Funding_Allocation__c> ifas = [SELECT Id, reduivy__Disbursed_Amount__c 
                                                                    FROM reduivy__Individual_Funding_Allocation__c 
                                                                    WHERE Id IN (:ifa1.Id, :ifa2.Id)
                                                                    ORDER BY Id];
            System.assertEquals(250.00, ifas[0].reduivy__Disbursed_Amount__c, 'IFA1 should have disbursed amount of 250.00');
            System.assertEquals(0.00, ifas[1].reduivy__Disbursed_Amount__c, 'IFA2 should have disbursed amount of 0.00');
            
            Test.startTest();
            
            // Change IFA reference from ifa1 to ifa2
            trp.reduivy__Individual_Funding_Allocation__c = ifa2.Id;
            update trp;
            
            Test.stopTest();
            
            // Assertions - amount should be moved from IFA1 to IFA2
            ifas = [SELECT Id, reduivy__Disbursed_Amount__c 
                    FROM reduivy__Individual_Funding_Allocation__c 
                    WHERE Id IN (:ifa1.Id, :ifa2.Id)
                    ORDER BY Id];
            System.assertEquals(0.00, ifas[0].reduivy__Disbursed_Amount__c, 'IFA1 should have disbursed amount of 0.00 after reference change');
            System.assertEquals(250.00, ifas[1].reduivy__Disbursed_Amount__c, 'IFA2 should have disbursed amount of 250.00 after reference change');
        }
    }

    /**
     * @description Test executeAfterUpdate with no relevant field changes as Faculty (no rollup)
     */
    @IsTest
    static void testExecuteAfterUpdateNoRelevantChangesAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 250.00');
            Decimal initialAmount = ifa.reduivy__Disbursed_Amount__c;
            
            Test.startTest();
            
            // Update non-relevant field (Applied Amount - this doesn't affect rollup)
            trp.reduivy__Applied_Amount__c = 300.00;
            update trp;
            
            Test.stopTest();
            
            // Assertions - amount should remain unchanged
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(initialAmount, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should remain unchanged when non-relevant fields are updated');
        }
    }

    /**
     * @description Test executeAfterUpdate when multiple relevant fields change simultaneously as Faculty
     */
    @IsTest
    static void testExecuteAfterUpdateMultipleFieldsChangedAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create draft Transaction Payment with initial amount
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Set to draft initially
            insert trp;
            
            // Verify initial state - should be 0 since TRP is draft
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 0.00 for draft TRP');
            
            Test.startTest();
            
            // Update both status and amount simultaneously
            trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
            trp.reduivy__Amount__c = 500.00;
            update trp;
            
            Test.stopTest();
            
            // Assertions - should reflect both changes (active status + new amount)
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(500.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 500.00 reflecting both status and amount changes');
        }
    }

    /**
     * @description Test executeAfterUpdate when TRP IFA reference changes from null to populated
     */
    @IsTest
    static void testExecuteAfterUpdateIfaReferenceFromNullAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment without IFA reference initially
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                null, // No IFA reference initially
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial state
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 0');
            
            Test.startTest();
            
            // Update TRP to add IFA reference
            trp.reduivy__Individual_Funding_Allocation__c = ifa.Id;
            update trp;
            
            Test.stopTest();
            
            // Assertions
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be rolled up after IFA reference is added');
        }
    }

    /**
     * @description Test executeAfterUpdate when TRP IFA reference changes from populated to null
     */
    @IsTest
    static void testExecuteAfterUpdateIfaReferenceToNullAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment with IFA reference
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                null,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 250.00');
            
            Test.startTest();
            
            // Update TRP to remove IFA reference
            trp.reduivy__Individual_Funding_Allocation__c = null;
            update trp;
            
            Test.stopTest();
            
            // Assertions - amount should be removed from rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 0.00 after IFA reference is removed');
        }
    }
	
    // ========== AFTER DELETE TESTS ==========

    /**
     * @description Test executeAfterDelete with active TRP having amount as Faculty
     */
    @IsTest
    static void testExecuteAfterDeleteActiveTrpWithAmountAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment with amount
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                250.00,
                null // applicableItemType
            );
            insert trp;
            
            // Verify initial rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 250.00');
            
            Test.startTest();
            
            // Delete the TRP
            delete trp;
            
            Test.stopTest();
            
            // Assertions - amount should be removed from rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 0.00 after deleting active TRP');
        }
    }

    /**
     * @description Test executeAfterDelete with draft TRP as Faculty (no rollup)
     */
    @IsTest
    static void testExecuteAfterDeleteDraftTrpAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create draft Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                250.00,
                null // applicableItemType
            );
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Make it draft
            insert trp;
            
            // Verify initial state - should be 0 since TRP is draft
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Initial disbursed amount should be 0.00 for draft TRP');
            
            Test.startTest();
            
            // Delete the draft TRP
            delete trp;
            
            Test.stopTest();
            
            // Assertions - amount should remain 0 as draft TRP deletion doesn't affect rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should remain 0.00 after deleting draft TRP');
        }
    }

    // ========== AFTER UNDELETE TESTS ==========

    /**
     * @description Test executeAfterUndelete with active TRP having amount as Faculty
     */
    @IsTest
    static void testExecuteAfterUndeleteActiveTrpWithAmountAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create active Transaction Payment with amount
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                250.00,
                null // applicableItemType
            );
            insert trp;
            
            // Delete the TRP first
            delete trp;
            
            // Verify TRP deletion reduced the rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 0.00 after deletion');
            
            Test.startTest();
            
            // Undelete the TRP
            undelete trp;
            
            Test.stopTest();
            
            // Assertions - amount should be added back to rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(250.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 250.00 after undeleting active TRP');
        }
    }

    /**
     * @description Test executeAfterUndelete with draft TRP as Faculty (no rollup)
     */
    @IsTest
    static void testExecuteAfterUndeleteDraftTrpAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        reduivy__Study_Funding__c std = [SELECT Id FROM reduivy__Study_Funding__c LIMIT 1];
        
        System.runAs(FACULTY_USER) {
            
            // Create Individual Funding Allocation
            reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                std.Id,
                1000.00,
                Date.today().addDays(-30),
                Date.today().addDays(365),
                0.00,
                IFA_Helper.STATUS_ACTIVE
            );
            insert ifa;
            
            // Create draft Transaction Payment
            reduivy__Transaction_Payment__c trp = REDU_TestData_UTIL.newTransactionPayment(
                studentContact.reduivy__Sample_Record_Code__c,
                studentContact.Id,
                null, // transactionOrderId
                TRP_Helper.TRANSACTION_TYPE_PAYMENT,
                ifa.Id,
                250.00,
                250.00,
                null // applicableItemType
            );
            trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT; // Make it draft
            insert trp;
            
            // Delete the TRP
            delete trp;
            
            // Verify initial state - should remain 0 since TRP was draft
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should be 0.00 before and after deletion');
            
            Test.startTest();
            
            // Undelete the draft TRP
            undelete trp;
            
            Test.stopTest();
            
            // Assertions - amount should remain 0 as draft TRP undelete doesn't affect rollup
            ifa = [SELECT Id, reduivy__Disbursed_Amount__c FROM reduivy__Individual_Funding_Allocation__c WHERE Id = :ifa.Id];
            System.assertEquals(0.00, ifa.reduivy__Disbursed_Amount__c, 'Disbursed amount should remain 0.00 after undeleting draft TRP');
        }
    }
}