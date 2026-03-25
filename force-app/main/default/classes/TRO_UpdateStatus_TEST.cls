/**
 * @author      WDCi (XW)
 * @date        Apr 2025
 * @group       Test
 * @description Test class for TRO_UpdateStatus_EXE
 * @changehistory
 * ISS-002429 29-04-2025 XW - new class
 */
@IsTest
public inherited sharing class TRO_UpdateStatus_TEST {

    static final String SRC_CON = 'sandydoe@redu.example';
    static final String TRO_STATUS_DRAFT = TRO_Helper.getDraftStatuses()[0];
    static final String TRO_STATUS_CONFIRMED = TRO_Helper.getConfirmedStatuses()[0];
    static final List<String> TRO_STATUSES_DRAFT = TRO_Helper.getDraftStatuses();
    static final List<String> TRO_STATUSES_CONFIRMED = TRO_Helper.getConfirmedStatuses();
    static final Integer NUMBER_OF_TRL = 3;
    static final Decimal TRL_UNIT_PRICE = 10;

    static Contact conStudent;

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
        	
            testFactory.initMasterData(ACC_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for insert payment with exact payment
     */
    @IsTest
    static void testAsAdmin_InsertPayment_ExactPayment() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        //add new transaction order
        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for(Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            reduivy__Transaction_Line_Item__c trl = newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE);
            trlList.add(trl);
        }

        insert trlList;

        reduivy__Transaction_Order__c troAfterInsertTrl = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.areEqual(0, troAfterInsertTrl.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troAfterInsertTrl.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troAfterInsertTrl.reduivy__Status__c);

        Decimal trpAmount = 60;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, trpAmount, TRP_Helper.STATUS_ACTIVE);
        Test.startTest();
        
		System.runAs(ADMIN_USER){
            insert trp;
		}

        reduivy__Transaction_Order__c troAfterInsertTrp = queryTro(tro.Id);
        System.Assert.areEqual(trpAmount, troAfterInsertTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(trpAmount, troAfterInsertTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(0, troAfterInsertTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterInsertTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterInsertTrl.reduivy__Status__c);
        
        Test.stopTest();
		
    }

    /**
     * @description Test as admin for insert payment with over payment
     */
    @IsTest
    static void testAsAdmin_InsertPayment_OverPayment() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        // Create and insert Transaction Order
        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        // Create and insert Transaction Line Items
        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        // Query and assert initial state
        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        // Overpay (e.g. amount = 70)
        Decimal overpaidAmount = 70;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, overpaidAmount, TRP_Helper.STATUS_ACTIVE);
        trp.reduivy__Transaction_Order__c = troBeforeTrp.Id;

        // Perform test operation
        Test.startTest();
        System.runAs(ADMIN_USER) {
            insert trp;
        }
        Test.stopTest();

        // Query and assert after payment
        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(70, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(-10, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c);
    }

    /**
     * @description Test as admin for insert payment with under payment
     */
    @IsTest
    static void testAsAdmin_InsertPayment_UnderPayment() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        Decimal underpaidAmount = 30;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, underpaidAmount, TRP_Helper.STATUS_ACTIVE);

        Test.startTest();
        System.runAs(ADMIN_USER) {
            insert trp;
        }
        Test.stopTest();

        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(30, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(30, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c); // Should still be draft
    }

    /**
     * @description Test as admin for no payment
     */
    @IsTest
    static void testAsAdmin_InsertPayment_NoPayment() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troAfterInsertTrl = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troAfterInsertTrl.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troAfterInsertTrl.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troAfterInsertTrl.reduivy__Status__c);

        // No payment inserted here
    }

    /**
     * @description Test as admin for insert payment with multiple payment
     */
    @IsTest
    static void testAsAdmin_InsertPayment_MultiplePayments() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        reduivy__Transaction_Payment__c trp1 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);
        reduivy__Transaction_Payment__c trp2 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);

        Test.startTest();
        System.runAs(ADMIN_USER) {
            insert new List<reduivy__Transaction_Payment__c>{ trp1, trp2 };
        }
        Test.stopTest();

        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(0, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c);
    }

    /**
     * @description Test as admin for insert payment with multiple payment
     */
    @IsTest
    static void testAsAdmin_InsertPayment_MultiplePayments2() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        reduivy__Transaction_Payment__c trp1 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);
        Test.startTest();
        System.runAs(ADMIN_USER) {
            insert trp1;
        }

        
        reduivy__Transaction_Order__c troAfterFirstTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterFirstTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(30, troAfterFirstTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(30, troAfterFirstTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterFirstTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterFirstTrp.reduivy__Status__c);

        reduivy__Transaction_Payment__c trp2 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);
        
        System.runAs(ADMIN_USER) {
            insert trp2;
        }
        Test.stopTest();

        reduivy__Transaction_Order__c troAfterSecondTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterSecondTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(60, troAfterSecondTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(0, troAfterSecondTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterSecondTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterSecondTrp.reduivy__Status__c);
    }
    
    /**
     * @description Test as admin for insert payment with tro linked with exact payment
     */
    @IsTest
    static void testAsAdmin_InsertPaymentWithTro_ExactPayment() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        //add new transaction order
        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for(Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            reduivy__Transaction_Line_Item__c trl = newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE);
            trlList.add(trl);
        }

        insert trlList;

        reduivy__Transaction_Order__c troAfterInsertTrl = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.areEqual(0, troAfterInsertTrl.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troAfterInsertTrl.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troAfterInsertTrl.reduivy__Status__c);

        Decimal trpAmount = 60;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, trpAmount, TRP_Helper.STATUS_ACTIVE);
        trp.reduivy__Transaction_Order__c = troAfterInsertTrl.Id;
        Test.startTest();
        
		System.runAs(ADMIN_USER){
            insert trp;
		}

        reduivy__Transaction_Order__c troAfterInsertTrp = queryTro(tro.Id);
        System.Assert.areEqual(trpAmount, troAfterInsertTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(trpAmount, troAfterInsertTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(0, troAfterInsertTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterInsertTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterInsertTrl.reduivy__Status__c);
        
        Test.stopTest();
		
    }

    
    /**
     * @description Test as admin for insert payment with tro linked with over payment
     */
    @IsTest
    static void testAsAdmin_InsertPaymentWithTro_OverPayment() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        // Create and insert Transaction Order
        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        insert tro;

        // Create and insert Transaction Line Items
        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        // Query and assert initial state
        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        // Overpay (e.g. amount = 70)
        Decimal overpaidAmount = 70;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, overpaidAmount, TRP_Helper.STATUS_ACTIVE);
        trp.reduivy__Transaction_Order__c = tro.Id;

        // Perform test operation
        Test.startTest();
        System.runAs(ADMIN_USER) {
            insert trp;
        }
        Test.stopTest();

        // Query and assert after payment
        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(70, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(-10, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c);
    }

    /**
     * @description Test as admin for insert payment with tro linked with under payment
     */
    @IsTest
    static void testAsAdmin_InsertPaymentWithTro_UnderPayment() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        Decimal underpaidAmount = 30;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, underpaidAmount, TRP_Helper.STATUS_ACTIVE);
        trp.reduivy__Transaction_Order__c = tro.Id;

        Test.startTest();
        System.runAs(ADMIN_USER) {
            insert trp;
        }
        Test.stopTest();

        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(30, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(30, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c); // Should still be draft
    }

    /**
     * @description Test as admin for no payment
     */
    @IsTest
    static void testAsAdmin_InsertPaymentWithTro_NoPayment() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troAfterInsertTrl = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troAfterInsertTrl.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troAfterInsertTrl.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troAfterInsertTrl.reduivy__Status__c);

        // No payment inserted here
    }

    /**
     * @description Test as admin for insert payment with tro linked with multiple payment
     */
    @IsTest
    static void testAsAdmin_InsertPaymentWithTro_MultiplePayments() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        reduivy__Transaction_Payment__c trp1 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);
        reduivy__Transaction_Payment__c trp2 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);
        trp1.reduivy__Transaction_Order__c = tro.Id;
        trp2.reduivy__Transaction_Order__c = tro.Id;

        Test.startTest();
        System.runAs(ADMIN_USER) {
            insert new List<reduivy__Transaction_Payment__c>{ trp1, trp2 };
        }
        Test.stopTest();

        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(0, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c);
    }
    

    /**
     * @description Test as student for insert payment with exact payment
     */
    @IsTest
    static void testAsStudent_InsertPayment_ExactPayment() {

        User studentUser = testFactory.getStudentUser();

        //add new transaction order
        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for(Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            reduivy__Transaction_Line_Item__c trl = newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE);
            trlList.add(trl);
        }

        insert trlList;

        reduivy__Transaction_Order__c troAfterInsertTrl = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.areEqual(0, troAfterInsertTrl.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troAfterInsertTrl.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troAfterInsertTrl.reduivy__Status__c);

        Decimal trpAmount = 60;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, trpAmount, TRP_Helper.STATUS_ACTIVE);
        Test.startTest();
        
		System.runAs(studentUser){
            insert trp;
		}

        reduivy__Transaction_Order__c troAfterInsertTrp = queryTro(tro.Id);
        System.Assert.areEqual(trpAmount, troAfterInsertTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(trpAmount, troAfterInsertTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(0, troAfterInsertTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterInsertTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterInsertTrl.reduivy__Status__c);
        
        Test.stopTest();
		
    }

    /**
     * @description Test as student for insert payment with over payment
     */
    @IsTest
    static void testAsStudent_InsertPayment_OverPayment() {
        User studentUser = testFactory.getStudentUser();

        // Create and insert Transaction Order
        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        // Create and insert Transaction Line Items
        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        // Query and assert initial state
        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        // Overpay (e.g. amount = 70)
        Decimal overpaidAmount = 70;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, overpaidAmount, TRP_Helper.STATUS_ACTIVE);
        trp.reduivy__Transaction_Order__c = troBeforeTrp.Id;
        
        // Perform test operation
        Test.startTest();
        System.runAs(studentUser) {
            insert trp;
        }
        Test.stopTest();

        // Query and assert after payment
        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(70, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(-10, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c);
    }

    /**
     * @description Test as student for insert payment with under payment
     */
    @IsTest
    static void testAsStudent_InsertPayment_UnderPayment() {
        User studentUser = testFactory.getStudentUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        Decimal underpaidAmount = 30;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, underpaidAmount, TRP_Helper.STATUS_ACTIVE);

        Test.startTest();
        System.runAs(studentUser) {
            insert trp;
        }
        Test.stopTest();

        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(30, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(30, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c); // Should still be draft
    }

    /**
     * @description Test as student for no payment
     */
    @IsTest
    static void testAsStudent_InsertPayment_NoPayment() {
        User studentUser = testFactory.getStudentUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troAfterInsertTrl = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troAfterInsertTrl.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troAfterInsertTrl.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troAfterInsertTrl.reduivy__Status__c);

        // No payment inserted here
    }

    /**
     * @description Test as student for insert payment with multiple payment
     */
    @IsTest
    static void testAsStudent_InsertPayment_MultiplePayments() {
        User studentUser = testFactory.getStudentUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        reduivy__Transaction_Payment__c trp1 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);
        reduivy__Transaction_Payment__c trp2 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);

        Test.startTest();
        System.runAs(studentUser) {
            insert new List<reduivy__Transaction_Payment__c>{ trp1, trp2 };
        }
        Test.stopTest();

        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(0, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c);
    }
    
    /**
     * @description Test as student for insert payment with multiple payment
     */
    @IsTest
    static void testAsStudent_InsertPayment_MultiplePayments2() {
        User studentUser = testFactory.getStudentUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        reduivy__Transaction_Payment__c trp1 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);
        Test.startTest();
        System.runAs(studentUser) {
            insert trp1;
        }

        
        reduivy__Transaction_Order__c troAfterFirstTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterFirstTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(30, troAfterFirstTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(30, troAfterFirstTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterFirstTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterFirstTrp.reduivy__Status__c);

        reduivy__Transaction_Payment__c trp2 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);
        
        System.runAs(studentUser) {
            insert trp2;
        }
        Test.stopTest();

        reduivy__Transaction_Order__c troAfterSecondTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterSecondTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(60, troAfterSecondTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(0, troAfterSecondTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterSecondTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterSecondTrp.reduivy__Status__c);
    }
    
    
    /**
     * @description Test as student for insert payment with tro linked with exact payment
     */
    @IsTest
    static void testAsStudent_InsertPaymentWithTro_ExactPayment() {

        User studentUser = testFactory.getStudentUser();

        //add new transaction order
        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for(Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            reduivy__Transaction_Line_Item__c trl = newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE);
            trlList.add(trl);
        }

        insert trlList;

        reduivy__Transaction_Order__c troAfterInsertTrl = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.areEqual(0, troAfterInsertTrl.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troAfterInsertTrl.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troAfterInsertTrl.reduivy__Status__c);

        Decimal trpAmount = 60;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, trpAmount, TRP_Helper.STATUS_ACTIVE);
        trp.reduivy__Transaction_Order__c = troAfterInsertTrl.Id;
        Test.startTest();
        
		System.runAs(studentUser){
            insert trp;
		}

        reduivy__Transaction_Order__c troAfterInsertTrp = queryTro(tro.Id);
        System.Assert.areEqual(trpAmount, troAfterInsertTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(trpAmount, troAfterInsertTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(0, troAfterInsertTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterInsertTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterInsertTrl.reduivy__Status__c);
        
        Test.stopTest();
		
    }

    
    /**
     * @description Test as student for insert payment with tro linked with over payment
     */
    @IsTest
    static void testAsStudent_InsertPaymentWithTro_OverPayment() {
        User studentUser = testFactory.getStudentUser();

        // Create and insert Transaction Order
        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        insert tro;

        // Create and insert Transaction Line Items
        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        // Query and assert initial state
        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        // Overpay (e.g. amount = 70)
        Decimal overpaidAmount = 70;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, overpaidAmount, TRP_Helper.STATUS_ACTIVE);
        trp.reduivy__Transaction_Order__c = tro.Id;

        // Perform test operation
        Test.startTest();
        System.runAs(studentUser) {
            insert trp;
        }
        Test.stopTest();

        // Query and assert after payment
        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(70, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(-10, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c);
    }

    /**
     * @description Test as student for insert payment with tro linked with under payment
     */
    @IsTest
    static void testAsStudent_InsertPaymentWithTro_UnderPayment() {
        User studentUser = testFactory.getStudentUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        Decimal underpaidAmount = 30;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, underpaidAmount, TRP_Helper.STATUS_ACTIVE);
        trp.reduivy__Transaction_Order__c = tro.Id;

        Test.startTest();
        System.runAs(studentUser) {
            insert trp;
        }
        Test.stopTest();

        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(30, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(30, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c); // Should still be draft
    }

    /**
     * @description Test as student for no payment
     */
    @IsTest
    static void testAsStudent_InsertPaymentWithTro_NoPayment() {
        User studentUser = testFactory.getStudentUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troAfterInsertTrl = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troAfterInsertTrl.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troAfterInsertTrl.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troAfterInsertTrl.reduivy__Status__c);

        // No payment inserted here
    }

    /**
     * @description Test as student for insert payment with tro linked with multiple payment
     */
    @IsTest
    static void testAsStudent_InsertPaymentWithTro_MultiplePayments() {
        User studentUser = testFactory.getStudentUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        reduivy__Transaction_Payment__c trp1 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);
        reduivy__Transaction_Payment__c trp2 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);
        trp1.reduivy__Transaction_Order__c = tro.Id;
        trp2.reduivy__Transaction_Order__c = tro.Id;

        Test.startTest();
        System.runAs(studentUser) {
            insert new List<reduivy__Transaction_Payment__c>{ trp1, trp2 };
        }
        Test.stopTest();

        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(0, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c);
    }


    
    /**
     * @description Test as faculty for insert payment with exact payment
     */
    @IsTest
    static void testAsFaculty_InsertPayment_ExactPayment() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        //add new transaction order
        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for(Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            reduivy__Transaction_Line_Item__c trl = newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE);
            trlList.add(trl);
        }

        insert trlList;

        reduivy__Transaction_Order__c troAfterInsertTrl = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.areEqual(0, troAfterInsertTrl.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troAfterInsertTrl.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troAfterInsertTrl.reduivy__Status__c);

        Decimal trpAmount = 60;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, trpAmount, TRP_Helper.STATUS_ACTIVE);
        Test.startTest();
        
		System.runAs(FACULTY_USER){
            insert trp;
		}

        reduivy__Transaction_Order__c troAfterInsertTrp = queryTro(tro.Id);
        System.Assert.areEqual(trpAmount, troAfterInsertTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(trpAmount, troAfterInsertTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(0, troAfterInsertTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterInsertTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterInsertTrl.reduivy__Status__c);
        
        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for insert payment with over payment
     */
    @IsTest
    static void testAsFaculty_InsertPayment_OverPayment() {        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        // Create and insert Transaction Order
        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        // Create and insert Transaction Line Items
        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        // Query and assert initial state
        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        // Overpay (e.g. amount = 70)
        Decimal overpaidAmount = 70;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, overpaidAmount, TRP_Helper.STATUS_ACTIVE);
        trp.reduivy__Transaction_Order__c = troBeforeTrp.Id;

        // Perform test operation
        Test.startTest();
        System.runAs(FACULTY_USER) {
            insert trp;
        }
        Test.stopTest();

        // Query and assert after payment
        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(70, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(-10, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c);
    }

    /**
     * @description Test as faculty for insert payment with under payment
     */
    @IsTest
    static void testAsFaculty_InsertPayment_UnderPayment() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        Decimal underpaidAmount = 30;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, underpaidAmount, TRP_Helper.STATUS_ACTIVE);

        Test.startTest();
        System.runAs(FACULTY_USER) {
            insert trp;
        }
        Test.stopTest();

        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(30, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(30, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c); // Should still be draft
    }

    /**
     * @description Test as faculty for no payment
     */
    @IsTest
    static void testAsFaculty_InsertPayment_NoPayment() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troAfterInsertTrl = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troAfterInsertTrl.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troAfterInsertTrl.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troAfterInsertTrl.reduivy__Status__c);

        // No payment inserted here
    }

    /**
     * @description Test as faculty for insert payment with multiple payment
     */
    @IsTest
    static void testAsFaculty_InsertPayment_MultiplePayments() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        reduivy__Transaction_Payment__c trp1 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);
        reduivy__Transaction_Payment__c trp2 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);

        Test.startTest();
        System.runAs(FACULTY_USER) {
            insert new List<reduivy__Transaction_Payment__c>{ trp1, trp2 };
        }
        Test.stopTest();

        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(0, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c);
    }
    
    /**
     * @description Test as faculty for insert payment with multiple payment
     */
    @IsTest
    static void testAsFaculty_InsertPayment_MultiplePayments2() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        tro.reduivy__Apply_Payment__c = true;
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        reduivy__Transaction_Payment__c trp1 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);
        Test.startTest();
        System.runAs(FACULTY_USER) {
            insert trp1;
        }

        
        reduivy__Transaction_Order__c troAfterFirstTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterFirstTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(30, troAfterFirstTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(30, troAfterFirstTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterFirstTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterFirstTrp.reduivy__Status__c);

        reduivy__Transaction_Payment__c trp2 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);
        
        System.runAs(FACULTY_USER) {
            insert trp2;
        }
        Test.stopTest();

        reduivy__Transaction_Order__c troAfterSecondTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterSecondTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(60, troAfterSecondTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(0, troAfterSecondTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterSecondTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterSecondTrp.reduivy__Status__c);
    }

    /**
     * @description Test as faculty for insert payment with tro linked with exact payment
     */
    @IsTest
    static void testAsFaculty_InsertPaymentWithTro_ExactPayment() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        //add new transaction order
        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for(Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            reduivy__Transaction_Line_Item__c trl = newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE);
            trlList.add(trl);
        }

        insert trlList;

        reduivy__Transaction_Order__c troAfterInsertTrl = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.areEqual(0, troAfterInsertTrl.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troAfterInsertTrl.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troAfterInsertTrl.reduivy__Status__c);

        Decimal trpAmount = 60;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, trpAmount, TRP_Helper.STATUS_ACTIVE);
        trp.reduivy__Transaction_Order__c = troAfterInsertTrl.Id;
        Test.startTest();
        
		System.runAs(FACULTY_USER){
            insert trp;
		}

        reduivy__Transaction_Order__c troAfterInsertTrp = queryTro(tro.Id);
        System.Assert.areEqual(trpAmount, troAfterInsertTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(trpAmount, troAfterInsertTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(0, troAfterInsertTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterInsertTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterInsertTrl.reduivy__Status__c);
        
        Test.stopTest();
		
    }

    
    /**
     * @description Test as faculty for insert payment with tro linked with over payment
     */
    @IsTest
    static void testAsFaculty_InsertPaymentWithTro_OverPayment() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        // Create and insert Transaction Order
        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        insert tro;

        // Create and insert Transaction Line Items
        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        // Query and assert initial state
        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        // Overpay (e.g. amount = 70)
        Decimal overpaidAmount = 70;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, overpaidAmount, TRP_Helper.STATUS_ACTIVE);
        trp.reduivy__Transaction_Order__c = tro.Id;

        // Perform test operation
        Test.startTest();
        System.runAs(FACULTY_USER) {
            insert trp;
        }
        Test.stopTest();

        // Query and assert after payment
        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(70, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(-10, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c);
    }

    /**
     * @description Test as faculty for insert payment with tro linked with under payment
     */
    @IsTest
    static void testAsFaculty_InsertPaymentWithTro_UnderPayment() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        Decimal underpaidAmount = 30;
        reduivy__Transaction_Payment__c trp = newTrp(getCon().Id, underpaidAmount, TRP_Helper.STATUS_ACTIVE);
        trp.reduivy__Transaction_Order__c = tro.Id;

        Test.startTest();
        System.runAs(FACULTY_USER) {
            insert trp;
        }
        Test.stopTest();

        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(30, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(30, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c); // Should still be draft
    }

    /**
     * @description Test as faculty for no payment
     */
    @IsTest
    static void testAsFaculty_InsertPaymentWithTro_NoPayment() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troAfterInsertTrl = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troAfterInsertTrl.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troAfterInsertTrl.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troAfterInsertTrl.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troAfterInsertTrl.reduivy__Status__c);

        // No payment inserted here
    }

    /**
     * @description Test as faculty for insert payment with tro linked with multiple payment
     */
    @IsTest
    static void testAsFaculty_InsertPaymentWithTro_MultiplePayments() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        reduivy__Transaction_Order__c tro = newTro(TRO_STATUS_DRAFT);
        insert tro;

        List<reduivy__Transaction_Line_Item__c> trlList = new List<reduivy__Transaction_Line_Item__c>();
        for (Integer i = 1; i <= NUMBER_OF_TRL; i++) {
            trlList.add(newTrl(tro.Id, 'Item ' + i, i, TRL_UNIT_PRICE));
        }
        insert trlList;

        reduivy__Transaction_Order__c troBeforeTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(0, troBeforeTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(60, troBeforeTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_DRAFT.contains(troBeforeTrp.reduivy__Status__c), 'Wrong status! Excepted: Draft; Actual: ' + troBeforeTrp.reduivy__Status__c);

        reduivy__Transaction_Payment__c trp1 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);
        reduivy__Transaction_Payment__c trp2 = newTrp(getCon().Id, 30, TRP_Helper.STATUS_ACTIVE);
        trp1.reduivy__Transaction_Order__c = tro.Id;
        trp2.reduivy__Transaction_Order__c = tro.Id;

        Test.startTest();
        System.runAs(FACULTY_USER) {
            insert new List<reduivy__Transaction_Payment__c>{ trp1, trp2 };
        }
        Test.stopTest();

        reduivy__Transaction_Order__c troAfterTrp = queryTro(tro.Id);
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Amount__c, 'Wrong Total Amount!');
        System.Assert.areEqual(60, troAfterTrp.reduivy__Total_Paid_Amount__c, 'Wrong Total Paid Amount!');
        System.Assert.areEqual(0, troAfterTrp.reduivy__Total_Outstanding_Amount__c, 'Wrong Total Outstanding Amount!');
        System.Assert.isTrue(TRO_STATUSES_CONFIRMED.contains(troAfterTrp.reduivy__Status__c), 'Wrong status! Excepted: Confirmed; Actual: ' + troAfterTrp.reduivy__Status__c);
    }
    

    /**
     * @description Create a new Transaction Order
     * @param  status Status (Draft, active...)
     * @return        reduivy__Transaction_Order__c
     */
    static reduivy__Transaction_Order__c newTro(String status){
        reduivy__Transaction_Order__c tro = new reduivy__Transaction_Order__c();
        tro.reduivy__Status__c = status;
        tro.reduivy__Contact__c = getCon().Id;
        tro.reduivy__Apply_Payment__c = true;

        return tro;
    }

    /**
     * @description Create a new Transaction Line Item
     * @param  troId     Parent Transaction Order id
     * @param  itemname  Item Name
     * @param  quantity  Quantity
     * @param  unitPrice Unit Price
     * @return           reduivy__Transaction_Line_Item__c
     */
    static reduivy__Transaction_Line_Item__c newTrl(Id troId, String itemname, Decimal quantity, Decimal unitPrice) {
        reduivy__Transaction_Line_Item__c trl = new reduivy__Transaction_Line_Item__c();
        trl.reduivy__Transaction_Order__c = troId;
        trl.reduivy__Item_Name__c = itemname;
        trl.reduivy__Quantity__c = quantity;
        trl.reduivy__Unit_Price__c = unitPrice;

        trl.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;
        trl.reduivy__Item_Type__c = TRL_Helper.ITEM_TYPE_TUITION;
        trl.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_DEBIT;

        return trl;
    }

    /**
     * @description create a new transaction payment
     * @param  conId  student contact id
     * @param  amount Amount of the payment
     * @param  status payment status (Draft, active...)
     * @return        reduivy__Transaction_Payment__c
     */
    static reduivy__Transaction_Payment__c newTrp(Id conId, Decimal amount, String status) {
        reduivy__Transaction_Payment__c trp = new reduivy__Transaction_Payment__c();
        trp.reduivy__Contact__c = conId;
        trp.reduivy__Amount__c = amount;
        
        trp.reduivy__Status__c = status;
        return trp;
    }

    /**
     * @description return student contact
     * @return   Contact
     */
    static Contact getCon(){
        if(conStudent == null) {
            conStudent = [
                SELECT Id FROM Contact WHERE reduivy__Sample_Record_Code__c =: SRC_CON LIMIT 1
            ];
        }

        return conStudent;

    }
    /**
     * @description query for transaction order based on id
     * @param  troId
     * @return      reduivy__Transaction_Order__c
     */
    static reduivy__Transaction_Order__c queryTro(Id troId){
        return [
            SELECT Id, reduivy__Status__c, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Payment_Status__c,
            (
                SELECT Id, reduivy__Item_Name__c, reduivy__Quantity__c, reduivy__Unit_Price__c
                FROM reduivy__Transaction_Line_Items__r
            )
            FROM reduivy__Transaction_Order__c
            WHERE Id = :troId
            LIMIT 1
        ];
    }
	
}