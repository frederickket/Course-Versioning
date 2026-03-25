/**
 * @author      WDCi (VTan)
 * @date        Mar 2024
 * @group       Finance
 * @description Test class for TRL_PrepaymentHandler_EXE
 * @changehistory
 * ISS-001866 26-02-2024 VTan - New class
 * ISS-002536 18-07-2025 XiRouh - Added test methods to cover the transition from 'Non-Transactional Entry' to other transaction types
 */
@IsTest
public inherited sharing class TRL_PrepaymentHandler_TEST extends REDU_TriggerExecutable {
    
	/**
     * @description Initialise test environment
     */
    private static final String ITEMTYPE_DEPOSIT = 'Deposit';
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static String statusConfirmed = TRO_Helper.getConfirmedStatuses().get(0);
    static String statusDraft = TRO_Helper.getDraftStatuses().get(0);

    static final String Prevent_Total_Amount_Changed_ERROR_MSG = 'You cannot update the amount because the Transaction Order Status is set to Confirmed.';

    /**
     * @description Default method to setup required data for automated test
     */
    @TestSetup
    static void makeData(){

        // Create rio education ivy settings and sample data
        testFactory.setupDefaultSettings();
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {

            Test.startTest();

            testFactory.initMasterData(SPL_Helper.getApiName());
            testFactory.initOfferingData(SST_Helper.getApiName());
            testFactory.initStudentData(IPE_Helper.getApiName(), true);

            //Create Academic Progress
            Date todayDate = date.today();
            reduivy__Study_Term__c currentTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Sample_Record_Code__c = : testFactory.CYTKey LIMIT 1];
            List<reduivy__Individual_Academic_Progress__c> termProgressList = new List<reduivy__Individual_Academic_Progress__c>();

            for(reduivy__Individual_Program_Enrollment__c ipe : [SELECT Id, reduivy__Contact__c, reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE reduivy__Sample_Record_Code__c <> '' AND RecordTypeId =: IPE_Helper.getMasterEnrollmentRecordTypeId()]){

                reduivy__Individual_Academic_Progress__c termProgress = REDU_TestData_UTIL.newIndividualAcademicProgress(ipe.reduivy__Contact__c + '|' + currentTerm.Id, ipe.reduivy__Contact__c, currentTerm.Id, null);

                termProgressList.add(termProgress);
            }

            insert termProgressList;

            //Create a transaction order without individual academic progress (e.g.: Deposit)
            List<reduivy__Transaction_Order__c> transactionOrderList = new List<reduivy__Transaction_Order__c>();
            String statusDraft = TRO_Helper.getDraftStatuses().get(0);
            for(Contact con : [SELECT Id FROM Contact WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT]){

                reduivy__Transaction_Order__c trnOrderDeposit = REDU_TestData_UTIL.newTransactionOrder(con.Id + '|Deposit', con.Id, null, todayDate, statusDraft, 0, 0, 0);
                trnOrderDeposit.reduivy__Apply_Payment__c = true;

                transactionOrderList.add(trnOrderDeposit);
            }

            insert transactionOrderList;

            List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
            for(reduivy__Transaction_Order__c trnOrder : transactionOrderList){
                reduivy__Transaction_Line_Item__c trnLineItemDeposit = REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c, trnOrder.Id, null, ITEMTYPE_DEPOSIT, ITEMTYPE_DEPOSIT, 200, null, null);
                trnLineItemList.add(trnLineItemDeposit);
            }

            insert trnLineItemList;

            Test.stopTest();
        }
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testPrepaymentHandlerAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();

        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Apply_Payment__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Individual_Academic_Progress__c = null]){

            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, trnOrder.Id, 'Payment', null, 200, 0, ITEMTYPE_DEPOSIT));

            System.Assert.areEqual(true, trnOrder.reduivy__Apply_Payment__c, 'Apply payment in transaction order should be marked as true');
            System.Assert.areEqual(200, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 0 for each transaction order');
            System.Assert.areEqual(200, trnOrder.reduivy__Total_Amount__c, 'Total amount should be 0.');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
        }

        System.runAs(ADMIN_USER){

            // Execute test
            Test.startTest();

            insert trnPaymentList;

            Test.stopTest();
        }

        for(reduivy__Transaction_Line_Item__c trnLineItem : [SELECT Id, reduivy__Outstanding_Amount__c, reduivy__Total_Amount__c, reduivy__Offset_Amount__c, reduivy__Transaction_Order__r.reduivy__Status__c, reduivy__Transaction_Type__c  FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_ORDERLINE]){
            
            System.Assert.areEqual(0, trnLineItem.reduivy__Outstanding_Amount__c, 'Outstanding Amount should be 0 for each transaction line item');
            System.Assert.areEqual(200, trnLineItem.reduivy__Total_Amount__c, 'Total amount should be 0.');
            System.Assert.areEqual(200, trnLineItem.reduivy__Offset_Amount__c, 'Offset Amount should be 200 for each transaction line item');
            System.Assert.areEqual(true, TRO_Helper.getConfirmedStatuses().contains(trnLineItem.reduivy__Transaction_Order__r.reduivy__Status__c), 'Transaction Order should be updated to Confirmed.');
        }

        Map<String, reduivy__Transaction_Item_Type_Config__mdt> trnItemTypeConfig = TRL_Helper.getPrepaymentItemTypeConfigs();
        List<reduivy__Transaction_Payment__c> trnPaymentCheckList = [SELECT Id, reduivy__Applicable_Item_Type__c FROM reduivy__Transaction_Payment__c WHERE reduivy__Remaining_Amount__c = 200];
        System.Assert.areEqual(false, trnPaymentCheckList.isEmpty(), 'Pre-payment record (Transaction Payment) should be created.');

        for(reduivy__Transaction_Payment__c trnPaymentCheck : trnPaymentCheckList){
            System.Assert.areEqual(trnItemTypeConfig.get(ITEMTYPE_DEPOSIT).reduivy__Payment_Applicable_Item_Type__c, trnPaymentCheck.reduivy__Applicable_Item_Type__c, 'A pre-payment record (Transaction Payment) should be created.');
        }
    }

    /**
     * @description Test the prepayment handler when Transaction Type is changed from 'Non-Transactional Entry' to normal entry as admin
     */
    @IsTest
    static void testPrepaymentHandlerWhenTransactionTypeChangesAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Get existing transaction orders from setup
        List<reduivy__Transaction_Order__c> statusChangeTroList = new List<reduivy__Transaction_Order__c>();
        List<reduivy__Transaction_Order__c> trnOrderList = [
            SELECT Id, reduivy__Contact__c, reduivy__Apply_Payment__c, reduivy__Status__c , reduivy__Sample_Record_Code__c
            FROM reduivy__Transaction_Order__c 
            WHERE reduivy__Individual_Academic_Progress__c = null
            LIMIT 1
        ];
        
        System.Assert.isFalse(trnOrderList.isEmpty(), 'Transaction orders should exist from test setup');

        //Create Transaction Line Item with Non-Transactional Entry type
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        for(reduivy__Transaction_Order__c trnOrder : trnOrderList){
            
            // Create a transaction line item with Non-Transactional Entry type
            reduivy__Transaction_Line_Item__c trnLineItem = REDU_TestData_UTIL.newTransactionOrderLine(
                trnOrder.reduivy__Sample_Record_Code__c + '|NonTransactionalDeposit', 
                trnOrder.Id, 
                null, 
                ITEMTYPE_DEPOSIT, 
                ITEMTYPE_DEPOSIT, 
                300, 
                null, 
                null
            );
            
            // Set as Non-Transactional Entry with offset amount equal to total amount (fully paid)
            trnLineItem.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY;
            trnLineItem.reduivy__Offset_Amount__c = 300; // Equal to total amount (fully paid)
            trnLineItem.reduivy__Total_Amount__c = 300;
            trnLineItemList.add(trnLineItem);

            statusChangeTroList.add(new reduivy__Transaction_Order__c(Id = trnOrder.Id, reduivy__Status__c = statusConfirmed));
        }

        System.runAs(ADMIN_USER){

            // Insert transaction line items as Non-Transactional Entry
            insert trnLineItemList;
            
            // Verify no prepayment is created for Non-Transactional Entry
            List<reduivy__Transaction_Line_Item__c> insertedItems = [
                SELECT Id, reduivy__Total_Amount__c, reduivy__Offset_Amount__c, reduivy__Transaction_Type__c, 
                    reduivy__Item_Type__c, reduivy__Transaction_Order__c, reduivy__Contact_Id__c
                FROM reduivy__Transaction_Line_Item__c 
                WHERE Id IN: trnLineItemList
            ];
            
            // Count existing prepayments before the test
            Integer initialPrepaymentCount = [SELECT COUNT() FROM reduivy__Transaction_Payment__c WHERE reduivy__Transaction_Type__c = 'Prepayment'];

            List<reduivy__Transaction_Payment__c> prePaymentRecords = [
                SELECT Id
                FROM reduivy__Transaction_Payment__c 
                WHERE reduivy__Transaction_Type__c = 'Prepayment'
            ];

            for(reduivy__Transaction_Line_Item__c item : insertedItems){
                System.Assert.areEqual(TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY, item.reduivy__Transaction_Type__c, 'Transaction type should be Non-Transactional Entry');
                System.Assert.areEqual(300, item.reduivy__Total_Amount__c, 'Total amount should be 300');
                System.Assert.areEqual(300, item.reduivy__Offset_Amount__c, 'Offset amount should be 300 (fully paid)');
                System.Assert.areEqual(ITEMTYPE_DEPOSIT, item.reduivy__Item_Type__c, 'Item type should be Deposit');
            }

            // Execute test - Change transaction type from Non-Transactional Entry to normal entry
            Test.startTest();

            update statusChangeTroList;

            // Update transaction type to normal entry (Order Line)
            for(reduivy__Transaction_Line_Item__c item : insertedItems){
                item.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE; // Change to normal transaction type
            }
            
            try{
                update insertedItems;
                System.Assert.fail('Should be failed with the Prevent_Total_Amount_Changed Validation Rule! Exception message: ' + Prevent_Total_Amount_Changed_ERROR_MSG);
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(Prevent_Total_Amount_Changed_ERROR_MSG), 'Wrong exception message! Excepted: ' + Prevent_Total_Amount_Changed_ERROR_MSG + '; Actual: ' + exp.getMessage());
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test the prepayment handler when Transaction Type is changed from 'Non-Transactional Entry' to normal entry as student
     */
    @IsTest
    static void testPrepaymentHandlerWhenTransactionTypeChangesAsStudent(){
        
        // Get existing transaction orders from setup
        List<reduivy__Transaction_Order__c> statusChangeTroList = new List<reduivy__Transaction_Order__c>();
        List<reduivy__Transaction_Order__c> trnOrderList = [
            SELECT Id, reduivy__Contact__c, reduivy__Apply_Payment__c, reduivy__Status__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Transaction_Order__c 
            WHERE reduivy__Individual_Academic_Progress__c = null
            LIMIT 1
        ];
        
        System.Assert.isFalse(trnOrderList.isEmpty(), 'Transaction orders should exist from test setup');

        User studentUser = [SELECT Id, 
                        ContactId, 
                        ProfileId 
                        FROM User 
                        WHERE ContactId = : trnOrderList[0].reduivy__Contact__c];

        //Create Transaction Line Item with Non-Transactional Entry type
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        for(reduivy__Transaction_Order__c trnOrder : trnOrderList){
            
            // Create a transaction line item with Non-Transactional Entry type
            reduivy__Transaction_Line_Item__c trnLineItem = REDU_TestData_UTIL.newTransactionOrderLine(
                trnOrder.reduivy__Sample_Record_Code__c + '|NonTransactionalDeposit', 
                trnOrder.Id, 
                null, 
                ITEMTYPE_DEPOSIT, 
                ITEMTYPE_DEPOSIT, 
                300,
                null, 
                null
            );
            
            // Set as Non-Transactional Entry with offset amount equal to total amount (fully paid)
            trnLineItem.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY;
            trnLineItem.reduivy__Offset_Amount__c = 300; // Equal to total amount (fully paid)
            trnLineItem.reduivy__Total_Amount__c = 300;
            trnLineItemList.add(trnLineItem);

            statusChangeTroList.add(new reduivy__Transaction_Order__c(Id = trnOrder.Id, reduivy__Status__c = statusConfirmed));
        }

        System.runAs(studentUser){

            // Insert transaction line items as Non-Transactional Entry
            insert trnLineItemList;
            
            // Verify no prepayment is created for Non-Transactional Entry
            List<reduivy__Transaction_Line_Item__c> insertedItems = [
                SELECT Id, reduivy__Total_Amount__c, reduivy__Offset_Amount__c, reduivy__Transaction_Type__c, 
                    reduivy__Item_Type__c, reduivy__Transaction_Order__c, reduivy__Contact_Id__c
                FROM reduivy__Transaction_Line_Item__c 
                WHERE Id IN: trnLineItemList
            ];
            
            // Count existing prepayments before the test
            Integer initialPrepaymentCount = [SELECT COUNT() FROM reduivy__Transaction_Payment__c WHERE reduivy__Transaction_Type__c = 'Prepayment'];

            List<reduivy__Transaction_Payment__c> prePaymentRecords = [
                SELECT Id
                FROM reduivy__Transaction_Payment__c 
                WHERE reduivy__Transaction_Type__c = 'Prepayment'
            ];

            for(reduivy__Transaction_Line_Item__c item : insertedItems){
                System.Assert.areEqual(TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY, item.reduivy__Transaction_Type__c, 'Transaction type should be Non-Transactional Entry');
                System.Assert.areEqual(300, item.reduivy__Total_Amount__c, 'Total amount should be 300');
                System.Assert.areEqual(300, item.reduivy__Offset_Amount__c, 'Offset amount should be 300 (fully paid)');
                System.Assert.areEqual(ITEMTYPE_DEPOSIT, item.reduivy__Item_Type__c, 'Item type should be Deposit');
            }

            // Execute test - Change transaction type from Non-Transactional Entry to normal entry
            Test.startTest();
            
            update statusChangeTroList;

            // Update transaction type to normal entry (Order Line)
            for(reduivy__Transaction_Line_Item__c item : insertedItems){
                item.reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE; // Change to normal transaction type
            }
            
            try{
                update insertedItems;
                System.Assert.fail('Should be failed with the Prevent_Total_Amount_Changed Validation Rule! Exception message: ' + Prevent_Total_Amount_Changed_ERROR_MSG);
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(Prevent_Total_Amount_Changed_ERROR_MSG), 'Wrong exception message! Excepted: ' + Prevent_Total_Amount_Changed_ERROR_MSG + '; Actual: ' + exp.getMessage());
            }


            Test.stopTest();

        }
    }
}