/**
 * @author      WDCi (XW)
 * @date        Jan 2024
 * @group       Test
 * @description Test class for Continuing Edu Cart Payment
 * @changehistory
 * ISS-001660 04-06-2024 XW - created testCheckCompanyOrder and testUpdateCompanyOrder
 */
@IsTest
public inherited sharing class REDU_ContinuingEduCartPayment_TEST {
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static List<String> TRO_STATUSES_DRAFT = TRO_Helper.getDraftStatuses();
    static List<String> TRO_STATUSES_CONFIRMED = TRO_Helper.getConfirmedStatuses();
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

            Contact corporateContact = new Contact(Id = studentUser.ContactId);
            corporateContact.reduivy__Corporate_Purchaser__c = true;
            update corporateContact;

            reduivy__Transaction_Order__c order = new reduivy__Transaction_Order__c(
                reduivy__Status__c = TRO_STATUSES_DRAFT.get(0), 
                reduivy__Contact__c = corporateContact.Id
            );

            insert order;

            List<reduivy__Transaction_Line_Item__c> transactionLines = new List<reduivy__Transaction_Line_Item__c>();

            for (Integer i = 0; i < 5; i++){

                reduivy__Transaction_Line_Item__c item = REDU_TestData_UTIL.newTransactionOrderLine('Application|' + i, order.Id, null, 'Course 1', 'Application', 1000, null, null);
                item.reduivy__Quantity__c = (i + 1);

                transactionLines.add(item);
            }
            insert transactionLines;

            Test.stopTest();
        }
    }

    /**
     * @description Check the CorporatePurchaser is readable or not for admin
     */
    @isTest
    static void testCheckCompanyOrderAdmin(){
                    
        User ADMIN_USER = testFactory.getReduAdminUser();
                        
        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse response = REDU_ContinuingEduCartPayment_LCTRL.checkCompanyOrder(null);
            System.Assert.areEqual(true, response.isSuccess, 'Check company order failed');
            System.Assert.areEqual('false', response.message, 'CorporatePurchaser should not be true');
            
            Test.stopTest();
        }
    }
    
    /**
     * @description test update account and status values for transaction order for admin
     */
    @isTest
    static void testUpdateCompanyOrderAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Transaction_Order__c> order = [SELECT Id, reduivy__Contact__c, reduivy__Status__c
            FROM reduivy__Transaction_Order__c
            WHERE reduivy__Status__c IN :TRO_STATUSES_DRAFT
            LIMIT 1];
        
        List<reduivy__Transaction_Line_Item__c> transactionLines = [SELECT Id, reduivy__transaction_order__c
            FROM reduivy__Transaction_Line_Item__c
            WHERE reduivy__transaction_order__r.Id = :order[0].Id];
        
        System.runAs(ADMIN_USER){
            Test.startTest();
            REDU_LightningResponse response = REDU_ContinuingEduCartPayment_LCTRL.updateCompanyOrder(order[0].Id, TRO_STATUSES_CONFIRMED.get(0));
            System.Assert.areEqual(true, response.isSuccess, 'Update company order failed');
            Test.stopTest();
        }
    }
    
    /**
     * @description Check the CorporatePurchaser is readable or not for student
     */
    @isTest
    static void testCheckCompanyOrderStudent(){
        User studentUser = testFactory.getStudentUser();
        
        System.runAs(studentUser){
            Test.startTest();
            
            REDU_LightningResponse response = REDU_ContinuingEduCartPayment_LCTRL.checkCompanyOrder(null);
            System.Assert.areEqual(true, response.isSuccess, 'Check company order failed');
            System.Assert.areEqual('true', response.message, 'CorporatePurchaser should be true');
            
            Test.stopTest();
        }
    }
    
    /**
     * @description test update account and status values for transaction order for student
     */
    @isTest
    static void testUpdateCompanyOrderStudent(){
        User studentUser = testFactory.getStudentUser();
        
        List<reduivy__Transaction_Order__c> order = [SELECT Id, reduivy__Contact__c, reduivy__Status__c
            FROM reduivy__Transaction_Order__c
            WHERE reduivy__Status__c IN :TRO_STATUSES_DRAFT
            LIMIT 1];
        
        List<reduivy__Transaction_Line_Item__c> transactionLines = [SELECT Id, reduivy__transaction_order__c
            FROM reduivy__Transaction_Line_Item__c
            WHERE reduivy__transaction_order__r.Id = :order[0].Id];
        
        System.runAs(studentUser){
            Test.startTest();
            REDU_LightningResponse response = REDU_ContinuingEduCartPayment_LCTRL.updateCompanyOrder(order[0].Id, TRO_STATUSES_CONFIRMED.get(0));
            System.Assert.areEqual(true, response.isSuccess, 'Update company order failed');
            Test.stopTest();
            
        }        
    }
    
    /**
     * @description Check the CorporatePurchaser is readable or not for order
     */
    @isTest
    static void testCheckCompanyOrderFaculty(){
                        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        System.runAs(FACULTY_USER){
            Test.startTest();
            
            REDU_LightningResponse response = REDU_ContinuingEduCartPayment_LCTRL.checkCompanyOrder(null);
            System.Assert.areEqual(true, response.isSuccess, 'Check company order failed');
            System.Assert.areEqual('false', response.message, 'CorporatePurchaser should not be true');
            
            Test.stopTest();
        }
    }
    
    /**
     * @description test update account and status values for transaction order for order
     */
    @isTest
    static void testUpdateCompanyOrderFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<reduivy__Transaction_Order__c> order = [SELECT Id, reduivy__Contact__c, reduivy__Status__c
            FROM reduivy__Transaction_Order__c
            WHERE reduivy__Status__c IN :TRO_STATUSES_DRAFT
            LIMIT 1];
        
        List<reduivy__Transaction_Line_Item__c> transactionLines = [SELECT Id, reduivy__transaction_order__c
            FROM reduivy__Transaction_Line_Item__c
            WHERE reduivy__transaction_order__r.Id = :order[0].Id];
        
        System.runAs(FACULTY_USER){
            Test.startTest();
            REDU_LightningResponse response = REDU_ContinuingEduCartPayment_LCTRL.updateCompanyOrder(order[0].Id, TRO_STATUSES_CONFIRMED.get(0));
            System.Assert.areEqual(true, response.isSuccess, 'Update company order failed');
            Test.stopTest();
            
        }
    }

    /**
     * @description Test as setup user who doesn't have permission
     */
    @isTest
    static void testCheckCompanyOrderAsSetupUser(){
        User SETUP_USER = testFactory.getSetupUser();

        System.runAs(SETUP_USER){
            Test.startTest();
            
            try {
                REDU_LightningResponse response = REDU_ContinuingEduCartPayment_LCTRL.checkCompanyOrder(null);
                System.Assert.fail('This should fail with error.');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('No such column \'ContactId\' on entity \'User\''), 'Unexpected error: ' + exp.getMessage());
            }
            
            Test.stopTest();
        }
    }
    
    /**
     * @description Test as setup user who doesn't have permission
     */
    @isTest
    static void testUpdateCompanyOrderAsSetupUser(){
        User SETUP_USER = testFactory.getSetupUser();

        List<reduivy__Transaction_Order__c> order = [SELECT Id, reduivy__Contact__c, reduivy__Status__c
            FROM reduivy__Transaction_Order__c
            WHERE reduivy__Status__c IN :TRO_STATUSES_DRAFT
            LIMIT 1];
        
        List<reduivy__Transaction_Line_Item__c> transactionLines = [SELECT Id, reduivy__transaction_order__c
            FROM reduivy__Transaction_Line_Item__c
            WHERE reduivy__transaction_order__r.Id = :order[0].Id];
        
        System.runAs(SETUP_USER){
            Test.startTest();
            try{
                REDU_LightningResponse response = REDU_ContinuingEduCartPayment_LCTRL.updateCompanyOrder(order[0].Id, TRO_STATUSES_CONFIRMED.get(0));
                System.Assert.fail('This should fail with error.');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s)'), 'Unexpected error: ' + exp.getMessage());
            }

            Test.stopTest();
            
        }
    }
}