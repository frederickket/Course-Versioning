/**
 * @author      WDCi (XW)
 * @date        Sept 2024
 * @group       Test
 * @description Test class for Continuing Edu Cart Order
 * @changehistory
 * ISS-002393 16-04-2025 XW - moved test methods from REDU_ContinuingEduCart_TEST
 * ISS-002736 25-11-2025 XiRouh - added enableWrapText param
 * ISS-002793 10-02-2026 Lean - Added more status
 */
@IsTest
public inherited sharing class REDU_ContinuingEduCartOrder_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static List<String> TRO_STATUSES_DRAFT = TRO_Helper.getDraftStatuses();
    static String SRC_TRO = 'TRO';
    static String SRC_TRL = 'TRL';
    static String SRC_SVO = 'Order Discount SVO';
    static String SRC_SVT = 'Order Discount SVT';

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

            reduivy__Transaction_Order__c order = new reduivy__Transaction_Order__c(
                reduivy__Status__c = TRO_STATUSES_DRAFT.get(0), 
                reduivy__Contact__c = studentUser.ContactId,
                reduivy__Total_Paid_Amount__c = 500,
                reduivy__Total_Amount__c = 15000,
                reduivy__Sample_Record_Code__c = SRC_TRO
            );

            insert order;

            List<reduivy__Transaction_Line_Item__c> transactionLines = new List<reduivy__Transaction_Line_Item__c>();

            for (Integer i = 1; i <= 5; i++){

                reduivy__Transaction_Line_Item__c item = REDU_TestData_UTIL.newTransactionOrderLine(SRC_TRL + i, order.Id, null, 'Course 1', 'Application', 1000, null, null);
                item.reduivy__Quantity__c = i;
                item.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;

                transactionLines.add(item);
            }
            insert transactionLines;

            reduivy__Study_Voucher__c svo = new reduivy__Study_Voucher__c();
            svo.Name = SRC_SVO;
            svo.reduivy__Code__c = SRC_SVO;
            svo.reduivy__Voucher_Type__c = SVO_Helper.VOUCHER_TYPE_AMOUNT;
            svo.reduivy__Status__c = SVO_Helper.STATUS_ACTIVE;
            svo.reduivy__Apply_As__c = SVO_Helper.APPLY_AS_ORDER;
            svo.reduivy__Sample_Record_Code__c = SRC_SVO;

            insert svo;
            
            List<reduivy__Study_Voucher_Transaction__c> svtList = new List<reduivy__Study_Voucher_Transaction__c>();
            for(Integer i = 1; i <= 2; i++){
                reduivy__Study_Voucher_Transaction__c svt = new reduivy__Study_Voucher_Transaction__c(
                    reduivy__Study_Voucher__c = svo.Id,
                    reduivy__Transaction_Order__c = order.Id,
                    reduivy__Status__c = SVT_Helper.STATUS_DRAFT,
                    reduivy__Amount__c = i * 1500,
                    reduivy__Sample_Record_Code__c = (SRC_SVT + i)
                );
                svtList.add(svt);
            }

            insert svtList;

            Test.stopTest();
		}

    }
	
    /**
     * @description Test if order id is null, transaction line item is still fetchable
     */
    @isTest
    static void testNoOrderIdFetchTransactionLinesAsStudent(){

        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            //List<reduivy__Transaction_Order__c> transactionOrder =
            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.fetchTransactionLines(null, 'reduivy__Quantity__c;reduivy__Unit_Price__c;reduivy__Total_Amount__c', UserInfo.getLanguage(), true);
            System.Assert.areEqual(true, response.isSuccess, 'Transaction Lines cannot be fetched');

            Test.stopTest();
        }
    }
    
    /**
     * @description Test if order id is null, transaction line item is still fetchable
     */
    @isTest
    static void testNoOrderIdFetchTransactionLinesAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        System.runAs(FACULTY_USER){
            Test.startTest();

            //List<reduivy__Transaction_Order__c> transactionOrder =
            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.fetchTransactionLines(null, 'reduivy__Quantity__c;reduivy__Unit_Price__c;reduivy__Total_Amount__c', UserInfo.getLanguage(), true);
            System.Assert.areEqual(true, response.isSuccess, 'Transaction Lines cannot be fetched');

            Test.stopTest();
        }
    }
    
    /**
     * @description Test if order id is null, transaction line item is still fetchable
     */
    @isTest
    static void testNoOrderIdFetchTransactionLinesAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER){
            Test.startTest();

            //List<reduivy__Transaction_Order__c> transactionOrder =
            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.fetchTransactionLines(null, 'reduivy__Quantity__c;reduivy__Unit_Price__c;reduivy__Total_Amount__c', UserInfo.getLanguage(), true);
            System.Assert.areEqual(true, response.isSuccess, 'Transaction Lines cannot be fetched');

            Test.stopTest();
        }
    }

    /**
     * @description Test if order id is not null, transaction line item is fetchable
     */
    @isTest
    static void testSpecificOrderIdFetchTransactionLinesAsStudent(){
        User studentUser = testFactory.getStudentUser();

        reduivy__Transaction_Order__c order = getTransactionOrder();

        System.runAs(studentUser){
            Test.startTest();

            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.fetchTransactionLines(order.Id, 'reduivy__Quantity__c;reduivy__Unit_Price__c;reduivy__Total_Amount__c', UserInfo.getLanguage(), true);
            System.Assert.areEqual(true, response.isSuccess);
            Test.stopTest();
        }
    }
    
    /**
     * @description Test if order id is not null, transaction line item is fetchable
     */
    @isTest
    static void testSpecificOrderIdFetchTransactionLinesAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Transaction_Order__c order = getTransactionOrder();

        System.runAs(FACULTY_USER){
            Test.startTest();

            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.fetchTransactionLines(order.Id, 'reduivy__Quantity__c;reduivy__Unit_Price__c;reduivy__Total_Amount__c', UserInfo.getLanguage(), true);
            System.Assert.areEqual(true, response.isSuccess);
            Test.stopTest();
        }
    }
    
    /**
     * @description Test if order id is not null, transaction line item is fetchable
     */
    @isTest
    static void testSpecificOrderIdFetchTransactionLinesAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Transaction_Order__c order = getTransactionOrder();

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.fetchTransactionLines(order.Id, 'reduivy__Quantity__c;reduivy__Unit_Price__c;reduivy__Total_Amount__c', UserInfo.getLanguage(), true);
            System.Assert.areEqual(true, response.isSuccess);
            Test.stopTest();
        }
    }

    /**
     * @description Test the transaction line item is deletable
     */
    @isTest
    static void testDeleteTransactionLineAsStudent(){
        User studentUser = testFactory.getStudentUser();

        reduivy__Transaction_Order__c order = getTransactionOrder();

        List<reduivy__Transaction_Line_Item__c> transactionLines = getTransactionLineItems();

        System.runAs(studentUser){

            List<String> transactionLinesId = new List<String>{ transactionLines[0].Id };
            Test.startTest();

            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.deleteTransactionLine(order.Id, transactionLinesId);
            System.Assert.areEqual(true, response.isSuccess);

            Test.stopTest();
        }
    }

    /**
     * @description Test the transaction line item is deletable
     */
    @isTest
    static void testDeleteTransactionLineAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Transaction_Order__c order = getTransactionOrder();

        List<reduivy__Transaction_Line_Item__c> transactionLines = getTransactionLineItems();

        System.runAs(FACULTY_USER){

            List<String> transactionLinesId = new List<String>{ transactionLines[0].Id };
            Test.startTest();

            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.deleteTransactionLine(order.Id, transactionLinesId);
            System.Assert.areEqual(true, response.isSuccess);

            Test.stopTest();
        }
    }

    /**
     * @description Test the transaction line item is deletable
     */
    @isTest
    static void testDeleteTransactionLineAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Transaction_Order__c order = getTransactionOrder();

        List<reduivy__Transaction_Line_Item__c> transactionLines = getTransactionLineItems();

        System.runAs(ADMIN_USER){

            List<String> transactionLinesId = new List<String>{ transactionLines[0].Id };
            Test.startTest();

            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.deleteTransactionLine(order.Id, transactionLinesId);
            System.Assert.areEqual(true, response.isSuccess);

            Test.stopTest();
        }
    }

    /**
     * @description Test the transaction order will be deleted if the last transaction line is deleted
     */
    @isTest
    static void testDeleteLastTransactionLineAsStudent(){
        User studentUser = testFactory.getStudentUser();

        reduivy__Transaction_Order__c order = new reduivy__Transaction_Order__c(
            reduivy__Status__c = TRO_STATUSES_DRAFT.get(0), 
            reduivy__Contact__c = studentUser.ContactId
        );

        insert order;

        reduivy__Transaction_Line_Item__c item = REDU_TestData_UTIL.newTransactionOrderLine('Application', order.Id, null, 'Course 1', 'Application', 1000, null, null);
        insert item;

        System.runAs(studentUser){

            List<String> transactionLinesId = new List<String>{ item.Id };
            Test.startTest();


            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.deleteTransactionLine(order.Id, transactionLinesId);
            System.Assert.areEqual(true, response.isSuccess);

            Test.stopTest();
        }
    }

    /**
     * @description Test the transaction order will be deleted if the last transaction line is deleted
     */
    @isTest
    static void testDeleteLastTransactionLineAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        User studentUser = testFactory.getStudentUser();

        reduivy__Transaction_Order__c order = new reduivy__Transaction_Order__c(
            reduivy__Status__c = TRO_STATUSES_DRAFT.get(0), 
            reduivy__Contact__c = studentUser.ContactId
        );

        insert order;

        reduivy__Transaction_Line_Item__c item = REDU_TestData_UTIL.newTransactionOrderLine('Application', order.Id, null, 'Course 1', 'Application', 1000, null, null);
        insert item;

        List<String> transactionLinesId = new List<String>{ item.Id };

        System.runAs(FACULTY_USER){

            Test.startTest();


            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.deleteTransactionLine(order.Id, transactionLinesId);
            System.Assert.areEqual(true, response.isSuccess);

            Test.stopTest();
        }
    }
    
     /**
     * @description Test the transaction order will be deleted if the last transaction line is deleted
     */
    @isTest
    static void testDeleteLastTransactionLineAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        User studentUser = testFactory.getStudentUser();

        reduivy__Transaction_Order__c order = new reduivy__Transaction_Order__c(
            reduivy__Status__c = TRO_STATUSES_DRAFT.get(0), 
            reduivy__Contact__c = studentUser.ContactId
        );

        insert order;

        reduivy__Transaction_Line_Item__c item = REDU_TestData_UTIL.newTransactionOrderLine('Application', order.Id, null, 'Course 1', 'Application', 1000, null, null);
        insert item;
        
        List<String> transactionLinesId = new List<String>{ item.Id };

        System.runAs(ADMIN_USER){

            Test.startTest();

            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.deleteTransactionLine(order.Id, transactionLinesId);
            System.Assert.areEqual(true, response.isSuccess);

            Test.stopTest();
        }
    }    

    /**
    * @description Test the transaction order will be deleted if the last transaction line is deleted
    */
    @isTest
    static void testDeleteAllTransactionLinesAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        User studentUser = testFactory.getStudentUser();

        reduivy__Transaction_Order__c order = new reduivy__Transaction_Order__c(
            reduivy__Status__c = TRO_STATUSES_DRAFT.get(0), 
            reduivy__Contact__c = studentUser.ContactId
        );

        insert order;

        reduivy__Transaction_Line_Item__c item = REDU_TestData_UTIL.newTransactionOrderLine('Application', order.Id, null, 'Course 1', 'Application', 1000, null, null);
        insert item;

        System.runAs(ADMIN_USER){

            Test.startTest();

            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.deleteTransactionLine(order.Id, null);
            System.Assert.areEqual(true, response.isSuccess);

            Test.stopTest();
        }
    }


    /**
    * @description Test the transaction order will be deleted if the last transaction line is deleted
    */
    @isTest
    static void testDeleteAllTransactionLinesAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        User studentUser = testFactory.getStudentUser();

        reduivy__Transaction_Order__c order = new reduivy__Transaction_Order__c(
            reduivy__Status__c = TRO_STATUSES_DRAFT.get(0), 
            reduivy__Contact__c = studentUser.ContactId
        );

        insert order;

        reduivy__Transaction_Line_Item__c item = REDU_TestData_UTIL.newTransactionOrderLine('Application', order.Id, null, 'Course 1', 'Application', 1000, null, null);
        insert item;

        System.runAs(FACULTY_USER){

            Test.startTest();

            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.deleteTransactionLine(order.Id, null);
            System.Assert.areEqual(true, response.isSuccess);

            Test.stopTest();
        }
    }    

    /**
    * @description Test the transaction order will be deleted if the last transaction line is deleted
    */
    @isTest
    static void testDeleteAllTransactionLinesAsStudent(){
        
        User studentUser = testFactory.getStudentUser();

        reduivy__Transaction_Order__c order = new reduivy__Transaction_Order__c(
            reduivy__Status__c = TRO_STATUSES_DRAFT.get(0), 
            reduivy__Contact__c = studentUser.ContactId
        );

        insert order;

        reduivy__Transaction_Line_Item__c item = REDU_TestData_UTIL.newTransactionOrderLine('Application', order.Id, null, 'Course 1', 'Application', 1000, null, null);
        insert item;

        System.runAs(studentUser){

            Test.startTest();

            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.deleteTransactionLine(order.Id, null);
            System.Assert.areEqual(true, response.isSuccess);

            Test.stopTest();
        }
    }    

    /**
     * @description test update quantity of transaction line item 
     */
    @isTest
    static void testUpdateOrderAsStudent(){
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            Test.startTest();

            reduivy__Transaction_Order__c order = getTransactionOrder();

            List<reduivy__Transaction_Line_Item__c> transactionLines = getTransactionLineItems();

            String transactionItemsArray = '{\"attributes": {\"type": "reduivy__Transaction_Line_Item__c",\"url": "/services/data/v60.0/sobjects/reduivy__Transaction_Line_Item__c/' + transactionLines[1].Id + '"},\"reduivy__Quantity__c": "12",\"reduivy__Unit_Price__c": 123,\"reduivy__Total_Amount__c": 1476,\"Id": "' + transactionLines[1].Id + '",\"actionIcon": "utility:delete",\"reduivy__Subtotal__c": 1476}';

            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.updateTransactionFeeLine(order.Id, transactionItemsArray);
            System.Assert.areEqual(true, response.isSuccess);

            Test.stopTest();
        }
    }

    /**
     * @description test update quantity of transaction line item 
     */
    @isTest
    static void testUpdateOrderAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        System.runAs(FACULTY_USER){
            Test.startTest();

            reduivy__Transaction_Order__c order = getTransactionOrder();

            List<reduivy__Transaction_Line_Item__c> transactionLines = getTransactionLineItems();

            String transactionItemsArray = '{\"attributes": {\"type": "reduivy__Transaction_Line_Item__c",\"url": "/services/data/v60.0/sobjects/reduivy__Transaction_Line_Item__c/' + transactionLines[2].Id + '"},\"reduivy__Quantity__c": "12",\"reduivy__Unit_Price__c": 123,\"reduivy__Total_Amount__c": 1476,\"Id": "' + transactionLines[2].Id + '",\"actionIcon": "utility:delete",\"reduivy__Subtotal__c": 1476}';

            
            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.updateTransactionFeeLine(order.Id, transactionItemsArray);
            System.Assert.areEqual(true, response.isSuccess, response.message);

            Test.stopTest();
        }
    }
    
    /**
     * @description test update quantity of transaction line item 
     */
    @isTest
    static void testUpdateOrderAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Transaction_Order__c order = getTransactionOrder();

        List<reduivy__Transaction_Line_Item__c> transactionLines = getTransactionLineItems();

        String transactionItemsArray = '{\"attributes": {\"type": "reduivy__Transaction_Line_Item__c",\"url": "/services/data/v60.0/sobjects/reduivy__Transaction_Line_Item__c/' + transactionLines[3].Id + '"},\"reduivy__Quantity__c": "12",\"reduivy__Unit_Price__c": 123,\"reduivy__Total_Amount__c": 1476,\"Id": "' + transactionLines[3].Id + '",\"actionIcon": "utility:delete",\"reduivy__Subtotal__c": 1476}';

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.updateTransactionFeeLine(order.Id, transactionItemsArray);
            System.Assert.areEqual(true, response.isSuccess);

            Test.stopTest();
        }
    }

    @IsTest
    static void testGetTransactionOrderStatusesAsStudent() {
        User studentUser = testFactory.getStudentUser();
        List<String> expectedDraftStatuses = TRO_Helper.getDraftStatuses();

        Test.startTest();
        
        System.runAs(studentUser) {
            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.getTransactionOrderStatuses();
            Map<String, List<String>> actualStatuses = (Map<String, List<String>>) JSON.deserialize(response.responseData, Map<String, List<String>>.class);
            System.Assert.isTrue(actualStatuses.containsKey('Draft'), 'Draft statuses should be retrieved!');

            //ISS-002793
            System.Assert.isTrue(actualStatuses.containsKey('Confirmed'), 'Confirmed statuses should be retrieved!');
            System.Assert.isTrue(actualStatuses.containsKey('Submitted'), 'Submitted statuses should be retrieved!');
            System.Assert.isTrue(actualStatuses.containsKey('Void'), 'Void statuses should be retrieved!');
            System.Assert.isTrue(actualStatuses.containsKey('Refunded'), 'Refunded statuses should be retrieved!');
            System.Assert.areEqual(JSON.serialize(expectedDraftStatuses), JSON.serialize(actualStatuses.get(TRO_Helper.STATUS_TYPE_DRAFT)), 'Wrong draft statuses!');
        }
        

        Test.stopTest();
    }

    @IsTest
    static void testGetTransactionOrderStatusesAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        List<String> expectedDraftStatuses = TRO_Helper.getDraftStatuses();

        Test.startTest();
        
        System.runAs(FACULTY_USER) {
            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.getTransactionOrderStatuses();
            Map<String, List<String>> actualStatuses = (Map<String, List<String>>) JSON.deserialize(response.responseData, Map<String, List<String>>.class);
            System.Assert.isTrue(actualStatuses.containsKey('Draft'), 'Draft statuses should be retrieved!');

            //ISS-002793
            System.Assert.isTrue(actualStatuses.containsKey('Confirmed'), 'Confirmed statuses should be retrieved!');
            System.Assert.isTrue(actualStatuses.containsKey('Submitted'), 'Submitted statuses should be retrieved!');
            System.Assert.isTrue(actualStatuses.containsKey('Void'), 'Void statuses should be retrieved!');
            System.Assert.isTrue(actualStatuses.containsKey('Refunded'), 'Refunded statuses should be retrieved!');
            System.Assert.areEqual(JSON.serialize(expectedDraftStatuses), JSON.serialize(actualStatuses.get(TRO_Helper.STATUS_TYPE_DRAFT)), 'Wrong draft statuses!');
        }
        

        Test.stopTest();
    }
    
    @IsTest
    static void testGetTransactionOrderStatusesAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        List<String> expectedDraftStatuses = TRO_Helper.getDraftStatuses();

        Test.startTest();
        
        System.runAs(ADMIN_USER) {
            REDU_LightningResponse response = REDU_ContinuingEduCartOrder_LCTRL.getTransactionOrderStatuses();
            Map<String, List<String>> actualStatuses = (Map<String, List<String>>) JSON.deserialize(response.responseData, Map<String, List<String>>.class);
            System.Assert.isTrue(actualStatuses.containsKey('Draft'), 'Draft statuses should be retrieved!');

            //ISS-002793
            System.Assert.isTrue(actualStatuses.containsKey('Confirmed'), 'Confirmed statuses should be retrieved!');
            System.Assert.isTrue(actualStatuses.containsKey('Submitted'), 'Submitted statuses should be retrieved!');
            System.Assert.isTrue(actualStatuses.containsKey('Void'), 'Void statuses should be retrieved!');
            System.Assert.isTrue(actualStatuses.containsKey('Refunded'), 'Refunded statuses should be retrieved!');
            System.Assert.areEqual(JSON.serialize(expectedDraftStatuses), JSON.serialize(actualStatuses.get(TRO_Helper.STATUS_TYPE_DRAFT)), 'Wrong draft statuses!');
        }
        

        Test.stopTest();
    }

    /**
     * @description test distribute order with 1 order level discount as admin
     */
    @IsTest
    static void testDistributeOrderDiscount_1OrderDiscount_Admin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();

        List<reduivy__Study_Voucher_Transaction__c> svtOrderDiscounts = getOrderDiscountSvt();
        svtOrderDiscounts[0].reduivy__Status__c = SVT_Helper.STATUS_CONFIRMED;
        update svtOrderDiscounts[0];
        
        reduivy__Transaction_Order__c order = getTransactionOrder();

        System.runAs(ADMIN_USER) {
            REDU_ContinuingEduCartOrder_LCTRL.distributeOrderDiscount(order.Id);
        }

        reduivy__Transaction_Order__c orderAfterUpdate = getTransactionOrder();
        System.Assert.areEqual(15000 - 1500, orderAfterUpdate.reduivy__Total_Amount__c, 'Wrong total amount!');
        System.Assert.areEqual(15000 - 1500, orderAfterUpdate.reduivy__Total_Outstanding_Amount__c, 'Wrong total outstanding amount!');
        System.Assert.areEqual(TRO_Helper.getConfirmedStatuses()[0], orderAfterUpdate.reduivy__Status__c, 'Wrong status!');
        
        List<reduivy__Transaction_Line_Item__c> trlsAfterUpdate = getTransactionLineItems();
        System.Assert.areEqual(5, trlsAfterUpdate.size(), 'Wrong list size!');

        for(Integer i = 0; i < 5; i++) {
            reduivy__Transaction_Line_Item__c trl = trlsAfterUpdate[i];
            Decimal distributedOrderDiscount = (i + 1) * 100;

            System.Assert.areEqual((i + 1) * 1000, trl.reduivy__Subtotal__c, 'Wrong total amount!');
            System.Assert.areEqual(distributedOrderDiscount, trl.reduivy__Discount__c.round(), 'Wrong discount!');
            System.Assert.areEqual(trl.reduivy__Subtotal__c - distributedOrderDiscount, trl.reduivy__Total_Amount__c.round(), 'Wrong total amount!');
        }

        Test.stopTest();
    }

    
    /**
     * @description test distribute order with 2 order level discount as admin
     */
    @IsTest
    static void testDistributeOrderDiscount_2OrderDiscount_Admin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();

        List<reduivy__Study_Voucher_Transaction__c> svtOrderDiscounts = getOrderDiscountSvt();
        svtOrderDiscounts[0].reduivy__Status__c = SVT_Helper.STATUS_CONFIRMED;
        svtOrderDiscounts[1].reduivy__Status__c = SVT_Helper.STATUS_CONFIRMED;
        update svtOrderDiscounts;
        
        reduivy__Transaction_Order__c order = getTransactionOrder();

        System.runAs(ADMIN_USER) {
            REDU_ContinuingEduCartOrder_LCTRL.distributeOrderDiscount(order.Id);
        }

        reduivy__Transaction_Order__c orderAfterUpdate = getTransactionOrder();
        System.Assert.areEqual(15000 - 4500, orderAfterUpdate.reduivy__Total_Amount__c, 'Wrong total amount!');
        System.Assert.areEqual(15000 - 4500, orderAfterUpdate.reduivy__Total_Outstanding_Amount__c, 'Wrong total outstanding amount!');
        System.Assert.areEqual(TRO_Helper.getConfirmedStatuses()[0], orderAfterUpdate.reduivy__Status__c, 'Wrong status!');
        
        List<reduivy__Transaction_Line_Item__c> trlsAfterUpdate = getTransactionLineItems();
        System.Assert.areEqual(5, trlsAfterUpdate.size(), 'Wrong list size!');

        for(Integer i = 0; i < 5; i++) {
            reduivy__Transaction_Line_Item__c trl = trlsAfterUpdate[i];
            Decimal distributedOrderDiscount = (i + 1) * 300;

            System.Assert.areEqual((i + 1) * 1000, trl.reduivy__Subtotal__c, 'Wrong total amount!');
            System.Assert.areEqual(distributedOrderDiscount, trl.reduivy__Discount__c.round(), 'Wrong discount!');
            System.Assert.areEqual(trl.reduivy__Subtotal__c - distributedOrderDiscount, trl.reduivy__Total_Amount__c.round(), 'Wrong total amount!');
        }

        Test.stopTest();
    }
    
    /**
     * @description test distribute order with 1 line discount and 1 order level discount as admin
     */
    @IsTest
    static void testDistributeOrderDiscount_1LineDiscount1OrderDiscount_Admin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();

        List<reduivy__Transaction_Line_Item__c> trls= getTransactionLineItems();
        reduivy__Transaction_Order__c order = getTransactionOrder();

        List<reduivy__Study_Voucher_Transaction__c> svtOrderDiscounts = getOrderDiscountSvt();
        svtOrderDiscounts[0].reduivy__Status__c = SVT_Helper.STATUS_CONFIRMED;
        update svtOrderDiscounts[0];
        
        reduivy__Transaction_Line_Item__c lineDiscountTrl = new reduivy__Transaction_Line_Item__c();
        lineDiscountTrl.reduivy__Transaction_Order__c = order.Id;
        lineDiscountTrl.reduivy__Item_Name__c = 'Line Discount';
        lineDiscountTrl.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
        lineDiscountTrl.reduivy__Item_Type__c = 'Application';
        lineDiscountTrl.reduivy__Quantity__c = 1;
        lineDiscountTrl.reduivy__Unit_Price__c = 100;
        lineDiscountTrl.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
        lineDiscountTrl.reduivy__Offset_Line_Item__c = trls[0].Id;

        insert lineDiscountTrl;

        System.runAs(ADMIN_USER) {
            REDU_ContinuingEduCartOrder_LCTRL.distributeOrderDiscount(order.Id);
        }
        
        reduivy__Transaction_Order__c orderAfterUpdate = getTransactionOrder();
        System.Assert.areEqual(15000 - 1600, orderAfterUpdate.reduivy__Total_Amount__c, 'Wrong total amount!');
        System.Assert.areEqual(15000 - 1600, orderAfterUpdate.reduivy__Total_Outstanding_Amount__c, 'Wrong total outstanding amount!');
        System.Assert.areEqual(TRO_Helper.getConfirmedStatuses()[0], orderAfterUpdate.reduivy__Status__c, 'Wrong status!');
        
        List<reduivy__Transaction_Line_Item__c> trlsAfterUpdate = getTransactionLineItems();
        System.Assert.areEqual(5, trlsAfterUpdate.size(), 'Wrong list size!');

        
        System.Assert.areEqual(1000, trlsAfterUpdate[0].reduivy__Subtotal__c, 'Wrong subtotal!');
        System.Assert.areEqual(((Decimal)(900.0 / 14900 * 1500) + 100).setScale(2), trlsAfterUpdate[0].reduivy__Discount__c.setScale(2), 'Wrong discount!');
        System.Assert.areEqual(trlsAfterUpdate[0].reduivy__Subtotal__c - ((Decimal)(900.0 / 14900 * 1500) + 100).setScale(2), trlsAfterUpdate[0].reduivy__Total_Amount__c.setScale(2), 'Wrong total amount!');


        for(Integer i = 1; i < 5; i++) {
            reduivy__Transaction_Line_Item__c trl = trlsAfterUpdate[i];

            Decimal distributedOrderDiscount = (trl.reduivy__Subtotal__c / 14900.0 * 1500);
        
            System.Assert.areEqual((i + 1) * 1000, trl.reduivy__Subtotal__c, 'Wrong total amount!');
            System.Assert.areEqual(distributedOrderDiscount.setScale(2), trl.reduivy__Discount__c.setScale(2), 'Wrong discount!');
            System.Assert.areEqual(((Decimal)trl.reduivy__Subtotal__c - distributedOrderDiscount).setScale(2), trl.reduivy__Total_Amount__c.setScale(2), 'Wrong total amount!');
        }

        Test.stopTest();
    }

    /**
     * @description test the behaviour when checking out if the tro status is confirmed as admin
     */
    @IsTest
    static void testDistributedOrderDiscount_Admin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();

        List<reduivy__Study_Voucher_Transaction__c> svtOrderDiscounts = getOrderDiscountSvt();
        svtOrderDiscounts[0].reduivy__Status__c = SVT_Helper.STATUS_CONFIRMED;
        update svtOrderDiscounts[0];
        
        reduivy__Transaction_Order__c order = getTransactionOrder();

        System.runAs(ADMIN_USER) {
            REDU_ContinuingEduCartOrder_LCTRL.distributeOrderDiscount(order.Id);
        }

        reduivy__Transaction_Order__c orderAfterUpdate = getTransactionOrder();
        System.Assert.areEqual(15000 - 1500, orderAfterUpdate.reduivy__Total_Amount__c, 'Wrong total amount!');
        System.Assert.areEqual(15000 - 1500, orderAfterUpdate.reduivy__Total_Outstanding_Amount__c, 'Wrong total outstanding amount!');
        System.Assert.areEqual(TRO_Helper.getConfirmedStatuses()[0], orderAfterUpdate.reduivy__Status__c, 'Wrong status!');
        
        List<reduivy__Transaction_Line_Item__c> trlsAfterUpdate = getTransactionLineItems();
        System.Assert.areEqual(5, trlsAfterUpdate.size(), 'Wrong list size!');

        for(Integer i = 0; i < 5; i++) {
            reduivy__Transaction_Line_Item__c trl = trlsAfterUpdate[i];
            Decimal distributedOrderDiscount = (i + 1) * 100;

            System.Assert.areEqual((i + 1) * 1000, trl.reduivy__Subtotal__c, 'Wrong total amount!');
            System.Assert.areEqual(distributedOrderDiscount, trl.reduivy__Discount__c.round(), 'Wrong discount!');
            System.Assert.areEqual(trl.reduivy__Subtotal__c - distributedOrderDiscount, trl.reduivy__Total_Amount__c.round(), 'Wrong total amount!');
        }

        //now we distribute again, should be nothing happened
        System.runAs(ADMIN_USER) {
            REDU_ContinuingEduCartOrder_LCTRL.distributeOrderDiscount(order.Id);
        }

        reduivy__Transaction_Order__c orderAfterUpdate2 = getTransactionOrder();
        System.Assert.areEqual(orderAfterUpdate.reduivy__Total_Amount__c, orderAfterUpdate2.reduivy__Total_Amount__c, 'Wrong total amount!');
        System.Assert.areEqual(orderAfterUpdate.reduivy__Total_Outstanding_Amount__c, orderAfterUpdate2.reduivy__Total_Outstanding_Amount__c, 'Wrong total outstanding amount!');
        System.Assert.areEqual(orderAfterUpdate.reduivy__Status__c, orderAfterUpdate2.reduivy__Status__c, 'Wrong status!');
        
        List<reduivy__Transaction_Line_Item__c> trlsAfterUpdate2 = getTransactionLineItems();
        System.Assert.areEqual(5, trlsAfterUpdate2.size(), 'Wrong list size!');

        for(Integer i = 0; i < 5; i++) {
            reduivy__Transaction_Line_Item__c trl2 = trlsAfterUpdate2[i];
            reduivy__Transaction_Line_Item__c trl = trlsAfterUpdate[i];

            System.Assert.areEqual(trl.reduivy__Subtotal__c, trl2.reduivy__Subtotal__c, 'Wrong total amount!');
            System.Assert.areEqual(trl.reduivy__Discount__c, trl2.reduivy__Discount__c, 'Wrong discount!');
            System.Assert.areEqual(trl.reduivy__Total_Amount__c, trl2.reduivy__Total_Amount__c, 'Wrong total amount!');
        }



        Test.stopTest();


    }
    
    /**
     * @description test distribute order with 1 order level discount as student
     */
    @IsTest
    static void testDistributeOrderDiscount_1OrderDiscount_Student() {
        
        User studentUser = testFactory.getStudentUser();
        Test.startTest();

        List<reduivy__Study_Voucher_Transaction__c> svtOrderDiscounts = getOrderDiscountSvt();
        svtOrderDiscounts[0].reduivy__Status__c = SVT_Helper.STATUS_CONFIRMED;
        update svtOrderDiscounts[0];
        
        reduivy__Transaction_Order__c order = getTransactionOrder();

        System.runAs(studentUser) {
            REDU_ContinuingEduCartOrder_LCTRL.distributeOrderDiscount(order.Id);
        }

        reduivy__Transaction_Order__c orderAfterUpdate = getTransactionOrder();
        System.Assert.areEqual(15000 - 1500, orderAfterUpdate.reduivy__Total_Amount__c, 'Wrong total amount!');
        System.Assert.areEqual(15000 - 1500, orderAfterUpdate.reduivy__Total_Outstanding_Amount__c, 'Wrong total outstanding amount!');
        System.Assert.areEqual(TRO_Helper.getConfirmedStatuses()[0], orderAfterUpdate.reduivy__Status__c, 'Wrong status!');
        
        List<reduivy__Transaction_Line_Item__c> trlsAfterUpdate = getTransactionLineItems();
        System.Assert.areEqual(5, trlsAfterUpdate.size(), 'Wrong list size!');

        for(Integer i = 0; i < 5; i++) {
            reduivy__Transaction_Line_Item__c trl = trlsAfterUpdate[i];
            Decimal distributedOrderDiscount = (i + 1) * 100;

            System.Assert.areEqual((i + 1) * 1000, trl.reduivy__Subtotal__c, 'Wrong total amount!');
            System.Assert.areEqual(distributedOrderDiscount, trl.reduivy__Discount__c.round(), 'Wrong discount!');
            System.Assert.areEqual(trl.reduivy__Subtotal__c - distributedOrderDiscount, trl.reduivy__Total_Amount__c.round(), 'Wrong total amount!');
        }

        Test.stopTest();
    }

    /**
     * @description test distribute order with 2 order level discount as student
     */
    @IsTest
    static void testDistributeOrderDiscount_2OrderDiscount_Student() {
        
        User studentUser = testFactory.getStudentUser();
        Test.startTest();

        List<reduivy__Study_Voucher_Transaction__c> svtOrderDiscounts = getOrderDiscountSvt();
        svtOrderDiscounts[0].reduivy__Status__c = SVT_Helper.STATUS_CONFIRMED;
        svtOrderDiscounts[1].reduivy__Status__c = SVT_Helper.STATUS_CONFIRMED;
        update svtOrderDiscounts;
        
        reduivy__Transaction_Order__c order = getTransactionOrder();

        System.runAs(studentUser) {
            REDU_ContinuingEduCartOrder_LCTRL.distributeOrderDiscount(order.Id);
        }

        reduivy__Transaction_Order__c orderAfterUpdate = getTransactionOrder();
        System.Assert.areEqual(15000 - 4500, orderAfterUpdate.reduivy__Total_Amount__c, 'Wrong total amount!');
        System.Assert.areEqual(15000 - 4500, orderAfterUpdate.reduivy__Total_Outstanding_Amount__c, 'Wrong total outstanding amount!');
        System.Assert.areEqual(TRO_Helper.getConfirmedStatuses()[0], orderAfterUpdate.reduivy__Status__c, 'Wrong status!');
        
        List<reduivy__Transaction_Line_Item__c> trlsAfterUpdate = getTransactionLineItems();
        System.Assert.areEqual(5, trlsAfterUpdate.size(), 'Wrong list size!');

        for(Integer i = 0; i < 5; i++) {
            reduivy__Transaction_Line_Item__c trl = trlsAfterUpdate[i];
            Decimal distributedOrderDiscount = (i + 1) * 300;

            System.Assert.areEqual((i + 1) * 1000, trl.reduivy__Subtotal__c, 'Wrong total amount!');
            System.Assert.areEqual(distributedOrderDiscount, trl.reduivy__Discount__c.round(), 'Wrong discount!');
            System.Assert.areEqual(trl.reduivy__Subtotal__c - distributedOrderDiscount, trl.reduivy__Total_Amount__c.round(), 'Wrong total amount!');
        }

        Test.stopTest();
    }
    
    /**
     * @description test distribute order with 1 order level discount and 1 line discount as student
     */
    @IsTest
    static void testDistributeOrderDiscount_1LineDiscount1OrderDiscount_Student() {
        
        User studentUser = testFactory.getStudentUser();
        Test.startTest();

        List<reduivy__Transaction_Line_Item__c> trls= getTransactionLineItems();
        reduivy__Transaction_Order__c order = getTransactionOrder();

        List<reduivy__Study_Voucher_Transaction__c> svtOrderDiscounts = getOrderDiscountSvt();
        svtOrderDiscounts[0].reduivy__Status__c = SVT_Helper.STATUS_CONFIRMED;
        update svtOrderDiscounts[0];
        
        reduivy__Transaction_Line_Item__c lineDiscountTrl = new reduivy__Transaction_Line_Item__c();
        lineDiscountTrl.reduivy__Transaction_Order__c = order.Id;
        lineDiscountTrl.reduivy__Item_Name__c = 'Line Discount';
        lineDiscountTrl.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY;
        lineDiscountTrl.reduivy__Item_Type__c = 'Application';
        lineDiscountTrl.reduivy__Quantity__c = 1;
        lineDiscountTrl.reduivy__Unit_Price__c = 100;
        lineDiscountTrl.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT;
        lineDiscountTrl.reduivy__Offset_Line_Item__c = trls[0].Id;

        insert lineDiscountTrl;

        System.runAs(studentUser) {
            REDU_ContinuingEduCartOrder_LCTRL.distributeOrderDiscount(order.Id);
        }

        reduivy__Transaction_Order__c orderAfterUpdate = getTransactionOrder();
        System.Assert.areEqual(15000 - 1600, orderAfterUpdate.reduivy__Total_Amount__c, 'Wrong total amount!');
        System.Assert.areEqual(15000 - 1600, orderAfterUpdate.reduivy__Total_Outstanding_Amount__c, 'Wrong total outstanding amount!');
        System.Assert.areEqual(TRO_Helper.getConfirmedStatuses()[0], orderAfterUpdate.reduivy__Status__c, 'Wrong status!');
        
        List<reduivy__Transaction_Line_Item__c> trlsAfterUpdate = getTransactionLineItems();
        System.Assert.areEqual(5, trlsAfterUpdate.size(), 'Wrong list size!');

        
        System.Assert.areEqual(1000, trlsAfterUpdate[0].reduivy__Subtotal__c, 'Wrong subtotal!');
        System.Assert.areEqual(((Decimal)(900.0 / 14900 * 1500) + 100).setScale(2), trlsAfterUpdate[0].reduivy__Discount__c.setScale(2), 'Wrong discount!');
        System.Assert.areEqual(trlsAfterUpdate[0].reduivy__Subtotal__c - ((Decimal)(900.0 / 14900 * 1500) + 100).setScale(2), trlsAfterUpdate[0].reduivy__Total_Amount__c.setScale(2), 'Wrong total amount!');


        for(Integer i = 1; i < 5; i++) {
            reduivy__Transaction_Line_Item__c trl = trlsAfterUpdate[i];

            Decimal distributedOrderDiscount = (trl.reduivy__Subtotal__c / 14900.0 * 1500);
        
            System.Assert.areEqual((i + 1) * 1000, trl.reduivy__Subtotal__c, 'Wrong total amount!');
            System.Assert.areEqual(distributedOrderDiscount.setScale(2), trl.reduivy__Discount__c.setScale(2), 'Wrong discount!');
            System.Assert.areEqual(((Decimal)trl.reduivy__Subtotal__c - distributedOrderDiscount).setScale(2), trl.reduivy__Total_Amount__c.setScale(2), 'Wrong total amount!');
        }

        Test.stopTest();
    }

    /**
     * @description test the behaviour when checking out if the tro status is confirmed as student
     */
    @IsTest
    static void testDistributedOrderDiscount_Student(){
        
        User studentUser = testFactory.getStudentUser();
        Test.startTest();

        List<reduivy__Study_Voucher_Transaction__c> svtOrderDiscounts = getOrderDiscountSvt();
        svtOrderDiscounts[0].reduivy__Status__c = SVT_Helper.STATUS_CONFIRMED;
        update svtOrderDiscounts[0];
        
        reduivy__Transaction_Order__c order = getTransactionOrder();

        System.runAs(studentUser) {
            REDU_ContinuingEduCartOrder_LCTRL.distributeOrderDiscount(order.Id);
        }

        reduivy__Transaction_Order__c orderAfterUpdate = getTransactionOrder();
        System.Assert.areEqual(15000 - 1500, orderAfterUpdate.reduivy__Total_Amount__c.round(), 'Wrong total amount!');
        System.Assert.areEqual(15000 - 1500, orderAfterUpdate.reduivy__Total_Outstanding_Amount__c, 'Wrong total outstanding amount!');
        System.Assert.areEqual(TRO_Helper.getConfirmedStatuses()[0], orderAfterUpdate.reduivy__Status__c, 'Wrong status!');
        
        List<reduivy__Transaction_Line_Item__c> trlsAfterUpdate = getTransactionLineItems();
        System.Assert.areEqual(5, trlsAfterUpdate.size(), 'Wrong list size!');

        for(Integer i = 0; i < 5; i++) {
            reduivy__Transaction_Line_Item__c trl = trlsAfterUpdate[i];
            Decimal distributedOrderDiscount = (i + 1) * 100;

            System.Assert.areEqual((i + 1) * 1000, trl.reduivy__Subtotal__c, 'Wrong total amount!');
            System.Assert.areEqual(distributedOrderDiscount, trl.reduivy__Discount__c.round(), 'Wrong discount!');
            System.Assert.areEqual(trl.reduivy__Subtotal__c - distributedOrderDiscount, trl.reduivy__Total_Amount__c.round(), 'Wrong total amount!');
        }

        //now we distribute again, should be nothing happened
        System.runAs(studentUser) {
            REDU_ContinuingEduCartOrder_LCTRL.distributeOrderDiscount(order.Id);
        }

        reduivy__Transaction_Order__c orderAfterUpdate2 = getTransactionOrder();
        System.Assert.areEqual(orderAfterUpdate.reduivy__Total_Amount__c, orderAfterUpdate2.reduivy__Total_Amount__c, 'Wrong total amount!');
        System.Assert.areEqual(orderAfterUpdate.reduivy__Total_Outstanding_Amount__c, orderAfterUpdate2.reduivy__Total_Outstanding_Amount__c, 'Wrong total outstanding amount!');
        System.Assert.areEqual(orderAfterUpdate.reduivy__Status__c, orderAfterUpdate2.reduivy__Status__c, 'Wrong status!');
        
        List<reduivy__Transaction_Line_Item__c> trlsAfterUpdate2 = getTransactionLineItems();
        System.Assert.areEqual(5, trlsAfterUpdate2.size(), 'Wrong list size!');

        for(Integer i = 0; i < 5; i++) {
            reduivy__Transaction_Line_Item__c trl2 = trlsAfterUpdate2[i];
            reduivy__Transaction_Line_Item__c trl = trlsAfterUpdate[i];

            System.Assert.areEqual(trl.reduivy__Subtotal__c, trl2.reduivy__Subtotal__c, 'Wrong total amount!');
            System.Assert.areEqual(trl.reduivy__Discount__c, trl2.reduivy__Discount__c, 'Wrong discount!');
            System.Assert.areEqual(trl.reduivy__Total_Amount__c, trl2.reduivy__Total_Amount__c, 'Wrong total amount!');
        }



        Test.stopTest();


    }

    /**
     * @description test get tro from the id as admin
     */
    @IsTest
    static void testGetTransactionOrderAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        reduivy__Transaction_Order__c expectedTro = getTransactionOrder();

        System.runAs(ADMIN_USER) {
            REDU_LightningResponse result = REDU_ContinuingEduCartOrder_LCTRL.getTransactionOrder(expectedTro.Id);
            reduivy__Transaction_Order__c actualTro = (reduivy__Transaction_Order__c) JSON.deserialize(result.responseData, reduivy__Transaction_Order__c.class);

            System.Assert.areEqual(expectedTro.Id, actualTro.Id, 'Wrong transaction order retrieved!');
        }
        
        Test.stopTest();
    }

    /**
     * @description test get tro where the id is empty as admin
     */
    @IsTest
    static void testGetTransactionOrderIdEmptyAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        System.runAs(ADMIN_USER) {
            REDU_LightningResponse result = REDU_ContinuingEduCartOrder_LCTRL.getTransactionOrder(null);
            reduivy__Transaction_Order__c actualTro = (reduivy__Transaction_Order__c) JSON.deserialize(result.responseData, reduivy__Transaction_Order__c.class);

            System.Assert.isNull(actualTro, 'Transaction order should not be retrieved!');
        }
        
        Test.stopTest();
    }
    
    /**
     * @description test get tro from the id as faculty
     */
    @IsTest
    static void testGetTransactionOrderAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        reduivy__Transaction_Order__c expectedTro = getTransactionOrder();

        System.runAs(FACULTY_USER) {
            REDU_LightningResponse result = REDU_ContinuingEduCartOrder_LCTRL.getTransactionOrder(expectedTro.Id);
            reduivy__Transaction_Order__c actualTro = (reduivy__Transaction_Order__c) JSON.deserialize(result.responseData, reduivy__Transaction_Order__c.class);

            System.Assert.areEqual(expectedTro.Id, actualTro.Id, 'Wrong transaction order retrieved!');
        }
        
        Test.stopTest();
    }

    /**
     * @description test get tro where the id is empty as faculty
     */
    @IsTest
    static void testGetTransactionOrderIdEmptyAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        System.runAs(FACULTY_USER) {
            REDU_LightningResponse result = REDU_ContinuingEduCartOrder_LCTRL.getTransactionOrder(null);
            reduivy__Transaction_Order__c actualTro = (reduivy__Transaction_Order__c) JSON.deserialize(result.responseData, reduivy__Transaction_Order__c.class);

            System.Assert.isNull(actualTro, 'Transaction order should not be retrieved!');
        }
        
        Test.stopTest();
    }
    
    /**
     * @description test get tro from the id as student
     */
    @IsTest
    static void testGetTransactionOrderAsStudent() {
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        reduivy__Transaction_Order__c expectedTro = getTransactionOrder();

        System.runAs(studentUser) {
            REDU_LightningResponse result = REDU_ContinuingEduCartOrder_LCTRL.getTransactionOrder(expectedTro.Id);
            reduivy__Transaction_Order__c actualTro = (reduivy__Transaction_Order__c) JSON.deserialize(result.responseData, reduivy__Transaction_Order__c.class);

            System.Assert.areEqual(expectedTro.Id, actualTro.Id, 'Wrong transaction order retrieved!');
        }
        
        Test.stopTest();
    }

    /**
     * @description test get tro where the id is empty as student
     */
    @IsTest
    static void testGetTransactionOrderIdEmptyAsStudent() {
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        System.runAs(studentUser) {
            REDU_LightningResponse result = REDU_ContinuingEduCartOrder_LCTRL.getTransactionOrder(null);
            reduivy__Transaction_Order__c actualTro = (reduivy__Transaction_Order__c) JSON.deserialize(result.responseData, reduivy__Transaction_Order__c.class);

            System.Assert.isNull(actualTro, 'Transaction order should not be retrieved!');
        }
        
        Test.stopTest();
    }

    static reduivy__Transaction_Order__c getTransactionOrder() {
        return [SELECT Id, reduivy__Contact__c, reduivy__Status__c, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Total_Outstanding_Amount__c
            FROM reduivy__Transaction_Order__c
            WHERE reduivy__Sample_Record_Code__c = :SRC_TRO
            LIMIT 1];
    }

    static List<reduivy__Transaction_Line_Item__c> getTransactionLineItems() {
        return [SELECT Id, reduivy__transaction_order__c, reduivy__Transaction_Type__c, reduivy__Total_Amount__c, reduivy__Subtotal__c, reduivy__Discount__c
            FROM reduivy__Transaction_Line_Item__c
            WHERE reduivy__transaction_order__r.reduivy__Sample_Record_Code__c = :SRC_TRO
            AND reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_ORDERLINE
            ORDER BY reduivy__Sample_Record_Code__c ASC];
    }

    static List<reduivy__Study_Voucher_Transaction__c> getOrderDiscountSvt() {

        Set<String> srcSet = new Set<String>{
            SRC_SVT + 1,
            SRC_SVT + 2
        };

        return [
            SELECT Id, Name, reduivy__Amount__c
            FROM reduivy__Study_Voucher_Transaction__c
            WHERE reduivy__Sample_Record_Code__c IN :srcSet
            ORDER BY reduivy__Sample_Record_Code__c ASC
        ];
    }
}	
