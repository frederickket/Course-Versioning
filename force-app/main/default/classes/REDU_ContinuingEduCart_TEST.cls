/**
 * @author      WDCi (XW)
 * @date        Jan 2024
 * @group       Test
 * @description Test class for Continuing Edu Cart
 * @changehistory
 * ISS-001660 04-06-2024 XW - Created test class
 * ISS-002793 10-02-2026 Lean - Support custom criteria
 */
@IsTest
public inherited sharing class REDU_ContinuingEduCart_TEST {
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static List<String> TRO_STATUSES_DRAFT = TRO_Helper.getDraftStatuses();

    /**
     * @description Default method to setup required data for automated test
     */
    @TestSetup
    static void makeData(){

        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER){
            Test.startTest();

            testFactory.initStudentData(USR_Helper.getApiName(), true);

            User studentUser = testFactory.getStudentUser();


            reduivy__Transaction_Order__c order0 = new reduivy__Transaction_Order__c(
                reduivy__Status__c = TRO_STATUSES_DRAFT.get(0),
                reduivy__Contact__c = studentUser.ContactId,
                reduivy__Total_Paid_Amount__c = 0,
                reduivy__Sample_Record_Code__c = 'Order0'
            );

            reduivy__Transaction_Order__c order1 = new reduivy__Transaction_Order__c(
                reduivy__Status__c = TRO_STATUSES_DRAFT.get(0),
                reduivy__Contact__c = studentUser.ContactId,
                reduivy__Total_Paid_Amount__c = 500,
                reduivy__Sample_Record_Code__c = 'Order500'
            );

            reduivy__Transaction_Order__c order2 = new reduivy__Transaction_Order__c(
                reduivy__Status__c = TRO_STATUSES_DRAFT.get(0),
                reduivy__Contact__c = studentUser.ContactId,
                reduivy__Total_Paid_Amount__c = 600,
                reduivy__Sample_Record_Code__c = 'Order600'
            );

            reduivy__Transaction_Order__c order3 = new reduivy__Transaction_Order__c(
                reduivy__Status__c = TRO_STATUSES_DRAFT.get(0),
                reduivy__Contact__c = studentUser.ContactId,
                reduivy__Total_Paid_Amount__c = 700,
                reduivy__Sample_Record_Code__c = 'Order700'
            );

            List<reduivy__Transaction_Order__c> orderList = new List<reduivy__Transaction_Order__c>{
                order0, order1, order2, order3
            };

            insert orderList;

            List<reduivy__Transaction_Line_Item__c> transactionLines = new List<reduivy__Transaction_Line_Item__c>();

            for(reduivy__Transaction_Order__c order : orderList){
                for (Integer i = 0; i < 5; i++){
                    String sampleRecordCode = 'Application|' + i;
                    Id troId = order.Id;
                    Id studyFeeMatrixItemId = null;
                    String itemName = sampleRecordCode;
                    String itemType = 'Application';
                    Decimal totalAmount = 1000;
                    Decimal offsetAmount = 0;
                    Decimal outstandingAmount = 0;

                    reduivy__Transaction_Line_Item__c item = REDU_TestData_UTIL.newTransactionOrderLine(sampleRecordCode, troId, studyFeeMatrixItemId, itemName, itemType, totalAmount, offsetAmount, outstandingAmount);
                    item.reduivy__Quantity__c = (i + 1);
                    item.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE;

                    transactionLines.add(item);
                }
            }
            insert transactionLines;

            Test.stopTest();

        }
    }

    @IsTest
    static void testGetAllTransactionOrdersAsAdmin() {
        List<reduivy__Transaction_Order__c> expectedTroList = [
            SELECT Id, Name
            FROM reduivy__Transaction_Order__c
            WHERE reduivy__Payment_Status__c IN (:TRO_Helper.PAYMENT_STATUS_NOTPAID, :TRO_Helper.PAYMENT_STATUS_PARTIALLYPAID)
            OR reduivy__Status__c IN: TRO_Helper.getDraftStatuses()
        ];

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER) {
            REDU_LightningResponse response = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(null, null, null);
            System.Assert.areEqual(true, response.isSuccess, 'Admin should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroList = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            //there should 0 records as we restrict the query by orderIds or contactId
            System.Assert.areEqual(0, actualTroList.size(), 'Wrong Transaction Order count!');
            
        }

        
        Test.stopTest();
    }

    /**
     * @description Test with multi currencies enabled
     */
    @IsTest
    static void testGetAllTransactionOrdersWithMultiCurrenciesAsAdmin() {

        if (!ORG_Helper.isMultiCurrenciesOrg()) {
            //we won't run this test in non multi currencies org as it will fail
            return;
        }

        List<reduivy__Transaction_Order__c> expectedTroList = new List<reduivy__Transaction_Order__c>();
        List<String> expectedTroIdList = new List<String>();
        for(reduivy__Transaction_Order__c tro : [
            SELECT Id, Name, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c
            WHERE (reduivy__Payment_Status__c IN (:TRO_Helper.PAYMENT_STATUS_NOTPAID, :TRO_Helper.PAYMENT_STATUS_PARTIALLYPAID)
            OR reduivy__Status__c IN: TRO_Helper.getDraftStatuses())
            AND reduivy__Sample_Record_Code__c IN ('Order0', 'Order500')
        ]){
            expectedTroList.add(tro);
            expectedTroIdList.add(tro.Id);
        }


        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER) {
            REDU_LightningResponse response = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(expectedTroIdList, null, null);
            System.Assert.areEqual(true, response.isSuccess, 'Admin should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroList = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            System.Assert.areEqual(expectedTroList.size(), actualTroList.size(), 'Wrong Transaction Order count!');
            
            for(reduivy__Transaction_Order__c actualTro : actualTroList) {
                System.Assert.isTrue(actualTro.isSet('CurrencyIsoCode'), 'The CurrencyIsoCode is not found.');
            }
        }
        
        Test.stopTest();
    }

    @IsTest
    static void testGetAllTransactionOrdersAsFaculty() {
        List<reduivy__Transaction_Order__c> expectedTroList = [
            SELECT Id, Name
            FROM reduivy__Transaction_Order__c
            WHERE reduivy__Payment_Status__c IN (:TRO_Helper.PAYMENT_STATUS_NOTPAID, :TRO_Helper.PAYMENT_STATUS_PARTIALLYPAID)
            OR reduivy__Status__c IN: TRO_Helper.getDraftStatuses()
        ];

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        System.runAs(FACULTY_USER) {
            REDU_LightningResponse response = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(null, null, null);
            System.Assert.areEqual(true, response.isSuccess, 'Faculty should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroList = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            //there should 0 records as we restrict the query by orderIds or contactId
            System.Assert.areEqual(0, actualTroList.size(), 'Wrong Transaction Order count!');
            
        }

        
        Test.stopTest();
    }


    @IsTest
    static void testGetAllTransactionOrdersAsStudent() {
        List<reduivy__Transaction_Order__c> expectedTroList = [
            SELECT Id, Name
            FROM reduivy__Transaction_Order__c
            WHERE reduivy__Payment_Status__c IN (:TRO_Helper.PAYMENT_STATUS_NOTPAID, :TRO_Helper.PAYMENT_STATUS_PARTIALLYPAID)
            OR reduivy__Status__c IN: TRO_Helper.getDraftStatuses()
        ];

        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();
        
        System.runAs(studentUser) {
            REDU_LightningResponse response = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(null, null, null);
            System.Assert.areEqual(true, response.isSuccess, 'Student should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroList = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            System.Assert.areEqual(expectedTroList.size(), actualTroList.size(), 'Wrong Transaction Order count!');
            
        }

        
        Test.stopTest();
    }


    @IsTest
    static void testGetSelectedTransactionOrdersAsAdmin() {
        List<reduivy__Transaction_Order__c> expectedTroList = new List<reduivy__Transaction_Order__c>();
        List<String> expectedTroIdList = new List<String>();
        for(reduivy__Transaction_Order__c tro : [
            SELECT Id, Name, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c
            WHERE (reduivy__Payment_Status__c IN (:TRO_Helper.PAYMENT_STATUS_NOTPAID, :TRO_Helper.PAYMENT_STATUS_PARTIALLYPAID)
            OR reduivy__Status__c IN: TRO_Helper.getDraftStatuses())
            AND reduivy__Sample_Record_Code__c IN ('Order0', 'Order500')
        ]){
            expectedTroList.add(tro);
            expectedTroIdList.add(tro.Id);
        }


        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER) {
            REDU_LightningResponse response = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(expectedTroIdList, null, null);
            System.Assert.areEqual(true, response.isSuccess, 'Admin should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroList = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            Integer expectedTroCounter = 0;
            System.Assert.areEqual(expectedTroList.size(), actualTroList.size(), 'Wrong Transaction Order count!');
            for(reduivy__Transaction_Order__c actualTro : actualTroList) {
                
                System.Assert.areEqual(expectedTroList[expectedTroCounter].Id, actualTro.Id, 'Wrong Transaction Order Id!');
                System.Assert.areEqual(expectedTroList[expectedTroCounter].reduivy__Total_Paid_Amount__c, actualTro.reduivy__Total_Paid_Amount__c, 'Wrong Transaction Order Total Paid amount!');

                expectedTroCounter++;
            }
        }

        
        Test.stopTest();
    }

    @IsTest
    static void testGetSelectedTransactionOrdersAsFaculty() {
        List<reduivy__Transaction_Order__c> expectedTroList = new List<reduivy__Transaction_Order__c>();
        List<String> expectedTroIdList = new List<String>();
        for(reduivy__Transaction_Order__c tro : [
            SELECT Id, Name, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c
            WHERE (reduivy__Payment_Status__c IN (:TRO_Helper.PAYMENT_STATUS_NOTPAID, :TRO_Helper.PAYMENT_STATUS_PARTIALLYPAID)
            OR reduivy__Status__c IN: TRO_Helper.getDraftStatuses())
            AND reduivy__Sample_Record_Code__c IN ('Order0', 'Order500')
        ]){
            expectedTroList.add(tro);
            expectedTroIdList.add(tro.Id);
        }


        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        System.runAs(FACULTY_USER) {
            REDU_LightningResponse response = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(expectedTroIdList, null, null);
            System.Assert.areEqual(true, response.isSuccess, 'Faculty should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroList = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            Integer expectedTroCounter = 0;
            System.Assert.areEqual(expectedTroList.size(), actualTroList.size(), 'Wrong Transaction Order count!');
            for(reduivy__Transaction_Order__c actualTro : actualTroList) {
                
                System.Assert.areEqual(expectedTroList[expectedTroCounter].Id, actualTro.Id, 'Wrong Transaction Order Id!');
                System.Assert.areEqual(expectedTroList[expectedTroCounter].reduivy__Total_Paid_Amount__c, actualTro.reduivy__Total_Paid_Amount__c, 'Wrong Transaction Order Total Paid amount!');

                expectedTroCounter++;
            }
        }

        
        Test.stopTest();
    }

    @IsTest
    static void testGetSelectedTransactionOrdersAsStudent() {
        List<reduivy__Transaction_Order__c> expectedTroList = new List<reduivy__Transaction_Order__c>();
        List<String> expectedTroIdList = new List<String>();
        for(reduivy__Transaction_Order__c tro : [
            SELECT Id, Name, reduivy__Total_Paid_Amount__c
            FROM reduivy__Transaction_Order__c
            WHERE (reduivy__Payment_Status__c IN (:TRO_Helper.PAYMENT_STATUS_NOTPAID, :TRO_Helper.PAYMENT_STATUS_PARTIALLYPAID)
            OR reduivy__Status__c IN: TRO_Helper.getDraftStatuses())
            AND reduivy__Sample_Record_Code__c IN ('Order0', 'Order500')
        ]){
            expectedTroList.add(tro);
            expectedTroIdList.add(tro.Id);
        }


        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();
        
        System.runAs(studentUser) {
            REDU_LightningResponse response = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(expectedTroIdList, null, null);
            System.Assert.areEqual(true, response.isSuccess, 'Student should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroList = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            Integer expectedTroCounter = 0;
            System.Assert.areEqual(expectedTroList.size(), actualTroList.size(), 'Wrong Transaction Order count!');
            for(reduivy__Transaction_Order__c actualTro : actualTroList) {
                
                System.Assert.areEqual(expectedTroList[expectedTroCounter].Id, actualTro.Id, 'Wrong Transaction Order Id!');
                System.Assert.areEqual(expectedTroList[expectedTroCounter].reduivy__Total_Paid_Amount__c, actualTro.reduivy__Total_Paid_Amount__c, 'Wrong Transaction Order Total Paid amount!');

                expectedTroCounter++;
            }
        }

        
        Test.stopTest();
    }

    
    @IsTest
    static void testGetCommunityInfoAsAdmin() {
        String expectedCommunityInfo = JSON.serialize(ORG_Helper.getCommunityInfo());
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER) {
            REDU_LightningResponse response = REDU_ContinuingEduCart_LCTRL.getCommunityInfo();
            System.Assert.areEqual(expectedCommunityInfo, response.responseData, 'Wrong community info!');
        }

        Test.stopTest();
    }

    @IsTest
    static void testGetCommunityInfoAsFaculty() {
        String expectedCommunityInfo = JSON.serialize(ORG_Helper.getCommunityInfo());
        
        User FACULTY_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(FACULTY_USER) {
            REDU_LightningResponse response = REDU_ContinuingEduCart_LCTRL.getCommunityInfo();
            System.Assert.areEqual(expectedCommunityInfo, response.responseData, 'Wrong community info!');
        }

        Test.stopTest();
    }

    @IsTest
    static void testGetCommunityInfoAsStudent() {
        String expectedCommunityInfo = JSON.serialize(ORG_Helper.getCommunityInfo());
        
        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();
        
        System.runAs(studentUser) {
            REDU_LightningResponse response = REDU_ContinuingEduCart_LCTRL.getCommunityInfo();
            System.Assert.areEqual(expectedCommunityInfo, response.responseData, 'Wrong community info!');
        }

        Test.stopTest();
    }

    /**
     * @description ISS-002793 Get order with custom criteria as admin
     */
    @IsTest
    static void testGetSelectedTransactionOrdersWithCustomCriteriaAsAdmin() {

        List<reduivy__Transaction_Order__c> existingTroList = [
            SELECT Id, Name
            FROM reduivy__Transaction_Order__c
        ];

        System.Assert.areEqual(true, !existingTroList.isEmpty());
         
        List<Id> orderIds = new List<Id>();
        String troVoidStatus = TRO_Helper.getVoidStatuses().get(0);
        for (reduivy__Transaction_Order__c tro : existingTroList) {
            tro.reduivy__Status__c = troVoidStatus;
            orderIds.add(tro.Id);
        }

        REDU_Database_UTIL.doUpdate(existingTroList);

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER) {
            REDU_LightningResponse response = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(orderIds, null, null);
            System.Assert.areEqual(true, response.isSuccess, 'Admin should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroList = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            //there should 0 records based on default criteria
            System.Assert.areEqual(4, actualTroList.size(), 'Wrong Transaction Order count!');
            
            REDU_LightningResponse responseCustomCriteria = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(orderIds, null, 'reduivy__Status__c = \'Void\'');
            System.Assert.areEqual(true, response.isSuccess, 'Admin should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroListCustomCriteria = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            //the record count should match
            System.Assert.areEqual(existingTroList.size(), actualTroListCustomCriteria.size(), 'Wrong Transaction Order count!');
        }

        
        Test.stopTest();
    }

    /**
     * @description ISS-002793 Get order with custom criteria as faculty
     */
    @IsTest
    static void testGetSelectedTransactionOrdersWithCustomCriteriaAsFaculty() {

        List<reduivy__Transaction_Order__c> existingTroList = [
            SELECT Id, Name
            FROM reduivy__Transaction_Order__c            
        ];

        System.Assert.areEqual(true, !existingTroList.isEmpty());
         
        List<Id> orderIds = new List<Id>();
        String troVoidStatus = TRO_Helper.getVoidStatuses().get(0);
        for (reduivy__Transaction_Order__c tro : existingTroList) {
            tro.reduivy__Status__c = troVoidStatus;
            orderIds.add(tro.Id);
        }

        REDU_Database_UTIL.doUpdate(existingTroList);

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        System.runAs(FACULTY_USER) {
            REDU_LightningResponse response = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(orderIds, null, null);
            System.Assert.areEqual(true, response.isSuccess, 'Admin should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroList = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            //there should 0 records based on default criteria
            System.Assert.areEqual(4, actualTroList.size(), 'Wrong Transaction Order count!');
            
            REDU_LightningResponse responseCustomCriteria = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(orderIds, null, 'reduivy__Status__c = \'Void\'');
            System.Assert.areEqual(true, response.isSuccess, 'Admin should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroListCustomCriteria = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            //the record count should match
            System.Assert.areEqual(existingTroList.size(), actualTroListCustomCriteria.size(), 'Wrong Transaction Order count!');
        }

        
        Test.stopTest();
    }

    /**
     * @description ISS-002793 Get order with custom criteria as student
     */
    @IsTest
    static void testGetSelectedTransactionOrdersWithCustomCriteriaAsStudent() {

        List<reduivy__Transaction_Order__c> existingTroList = [
            SELECT Id, Name
            FROM reduivy__Transaction_Order__c            
        ];

        System.Assert.areEqual(true, !existingTroList.isEmpty());
         
        List<Id> orderIds = new List<Id>();
        String troVoidStatus = TRO_Helper.getVoidStatuses().get(0);
        for (reduivy__Transaction_Order__c tro : existingTroList) {
            tro.reduivy__Status__c = troVoidStatus;
            orderIds.add(tro.Id);
        }

        REDU_Database_UTIL.doUpdate(existingTroList);

        User STUDENT_USER = testFactory.getStudentUser();
        
        Test.startTest();
        
        System.runAs(STUDENT_USER) {
            REDU_LightningResponse response = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(orderIds, null, null);
            System.Assert.areEqual(true, response.isSuccess, 'Admin should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroList = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            //there should 0 records based on default criteria
            System.Assert.areEqual(4, actualTroList.size(), 'Wrong Transaction Order count!');
            
            REDU_LightningResponse responseCustomCriteria = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(orderIds, null, 'reduivy__Status__c = \'Void\'');
            System.Assert.areEqual(true, response.isSuccess, 'Admin should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroListCustomCriteria = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            //the record count should match
            System.Assert.areEqual(existingTroList.size(), actualTroListCustomCriteria.size(), 'Wrong Transaction Order count!');
        }

        
        Test.stopTest();
    }

    /**
     * @description ISS-002793 Get order with custom criteria as admin
     */
    @IsTest
    static void testGetSelectedTransactionOrdersWithoutOrderLineAsAdmin() {

        List<reduivy__Transaction_Order__c> existingTroList = [
            SELECT Id, Name
            FROM reduivy__Transaction_Order__c
        ];

        System.Assert.areEqual(true, !existingTroList.isEmpty());
         
        List<Id> orderIds = new List<Id>();
        for (reduivy__Transaction_Order__c tro : existingTroList) {
            orderIds.add(tro.Id);
        }

        List<reduivy__Transaction_Line_Item__c> tliList = [SELECT Id FROM reduivy__Transaction_Line_Item__c 
            WHERE reduivy__Transaction_Order__c IN: orderIds
        ];

        REDU_Database_UTIL.doDelete(tliList);

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER) {
            REDU_LightningResponse response = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(orderIds, null, null);
            System.Assert.areEqual(true, response.isSuccess, 'Admin should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroList = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            //there should 0 records based on default criteria
            System.Assert.areEqual(0, actualTroList.size(), 'Wrong Transaction Order count!');
            
            REDU_LightningResponse responseCustomCriteria = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(orderIds, null, 'reduivy__Status__c = \'Void\'');
            System.Assert.areEqual(true, response.isSuccess, 'Admin should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroListCustomCriteria = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            //there should 0 records based on custom criteria
            System.Assert.areEqual(0, actualTroListCustomCriteria.size(), 'Wrong Transaction Order count!');
        }

        
        Test.stopTest();
    }

    /**
     * @description ISS-002793 Get order with custom criteria as faculty
     */
    @IsTest
    static void testGetSelectedTransactionOrdersWithoutOrderLineAsFaculty() {

        List<reduivy__Transaction_Order__c> existingTroList = [
            SELECT Id, Name
            FROM reduivy__Transaction_Order__c
        ];

        System.Assert.areEqual(true, !existingTroList.isEmpty());
         
        List<Id> orderIds = new List<Id>();
        for (reduivy__Transaction_Order__c tro : existingTroList) {
            orderIds.add(tro.Id);
        }

        List<reduivy__Transaction_Line_Item__c> tliList = [SELECT Id FROM reduivy__Transaction_Line_Item__c 
            WHERE reduivy__Transaction_Order__c IN: orderIds
        ];

        REDU_Database_UTIL.doDelete(tliList);

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        System.runAs(FACULTY_USER) {
            REDU_LightningResponse response = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(orderIds, null, null);
            System.Assert.areEqual(true, response.isSuccess, 'Admin should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroList = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            //there should 0 records based on default criteria
            System.Assert.areEqual(0, actualTroList.size(), 'Wrong Transaction Order count!');
            
            REDU_LightningResponse responseCustomCriteria = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(orderIds, null, 'reduivy__Status__c = \'Void\'');
            System.Assert.areEqual(true, response.isSuccess, 'Admin should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroListCustomCriteria = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            //there should 0 records based on custom criteria
            System.Assert.areEqual(0, actualTroListCustomCriteria.size(), 'Wrong Transaction Order count!');
        }

        
        Test.stopTest();
    }

    /**
     * @description ISS-002793 Get order with custom criteria as student
     */
    @IsTest
    static void testGetSelectedTransactionOrdersWithoutOrderLineAsStudent() {

        List<reduivy__Transaction_Order__c> existingTroList = [
            SELECT Id, Name
            FROM reduivy__Transaction_Order__c
        ];

        System.Assert.areEqual(true, !existingTroList.isEmpty());
         
        List<Id> orderIds = new List<Id>();
        for (reduivy__Transaction_Order__c tro : existingTroList) {
            orderIds.add(tro.Id);
        }

        List<reduivy__Transaction_Line_Item__c> tliList = [SELECT Id FROM reduivy__Transaction_Line_Item__c 
            WHERE reduivy__Transaction_Order__c IN: orderIds
        ];

        REDU_Database_UTIL.doDelete(tliList);

        User STUDENT_USER = testFactory.getStudentUser();
        
        Test.startTest();
        
        System.runAs(STUDENT_USER) {
            REDU_LightningResponse response = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(orderIds, null, null);
            System.Assert.areEqual(true, response.isSuccess, 'Admin should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroList = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            //there should 0 records based on default criteria
            System.Assert.areEqual(0, actualTroList.size(), 'Wrong Transaction Order count!');
            
            REDU_LightningResponse responseCustomCriteria = REDU_ContinuingEduCart_LCTRL.getTransactionOrders(orderIds, null, 'reduivy__Status__c = \'Void\'');
            System.Assert.areEqual(true, response.isSuccess, 'Admin should be able to get transaction orders!');

            List<reduivy__Transaction_Order__c> actualTroListCustomCriteria = (List<reduivy__Transaction_Order__c>) JSON.deserialize(response.responseData, List<reduivy__Transaction_Order__c>.class);
            //there should 0 records based on custom criteria
            System.Assert.areEqual(0, actualTroListCustomCriteria.size(), 'Wrong Transaction Order count!');
        }

        
        Test.stopTest();
    }
}