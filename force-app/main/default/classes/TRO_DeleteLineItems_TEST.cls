/**
 * @author      WDCi (VTan)
 * @date        Feb 2024
 * @group       Finance
 * @description Test class for TRO_DeleteLineItems_EXE
 * @changehistory
 * ISS-001866 26-02-2024 VTan - New class
 * ISS-002017 22-07-2024 Sueanne - Added test for "Discount Entry" line item
 * ISS-002536 18-07-2025 XiRouh - Added test for "Non Transaction Type" line item
 */
@IsTest
public inherited sharing class TRO_DeleteLineItems_TEST{
    
	/**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

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
            List<reduivy__Study_Term__c> termList = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Start_Date__c <=: todayDate AND reduivy__End_Date__c >=: todayDate AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() ORDER BY Name ASC];
            
            reduivy__Study_Term__c currentTerm;
            if(termList.isEmpty()){
                //set currentTerm as future term(next term)
                currentTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Start_Date__c >: todayDate AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() ORDER BY Name ASC LIMIT 1];
            }else{
                currentTerm = termList[0];
            }

            List<reduivy__Individual_Academic_Progress__c> termProgressList = new List<reduivy__Individual_Academic_Progress__c>();

            for(reduivy__Individual_Program_Enrollment__c ipe : [SELECT Id, reduivy__Contact__c, reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE reduivy__Sample_Record_Code__c <> '' AND RecordTypeId =: IPE_Helper.getMasterEnrollmentRecordTypeId()]){

                reduivy__Individual_Academic_Progress__c termProgress = REDU_TestData_UTIL.newIndividualAcademicProgress(ipe.reduivy__Contact__c + '|' + currentTerm.Id, ipe.reduivy__Contact__c, currentTerm.Id, null);

                termProgressList.add(termProgress);
            }

            insert termProgressList;

            //Create Transaction Order
            List<reduivy__Transaction_Order__c> transactionOrderList = new List<reduivy__Transaction_Order__c>();
            String statusDraft = TRO_Helper.getDraftStatuses().get(0);
            for(reduivy__Individual_Academic_Progress__c termProgress : termProgressList){

                reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(termProgress.reduivy__Sample_Record_Code__c + '|Order', termProgress.reduivy__Contact__c, termProgress.Id, todayDate, statusDraft, 0, 0, 0);
                transactionOrder.reduivy__Apply_Payment__c = true;
                transactionOrder.reduivy__Apply_Non_Repayable_FA__c = true;
                transactionOrder.reduivy__Apply_Repayable_FA__c = true;
                transactionOrderList.add(transactionOrder);
            }

            insert transactionOrderList;

            List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
            for(reduivy__Transaction_Order__c trnOrder : transactionOrderList){
                
                //Create Transaction Line Item
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Application', trnOrder.Id, null, 'Admission Fee', 'Application', 300, null, null));
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Tuition', trnOrder.Id, null, 'Tuition Fee', 'Tuition', 2500, null, null));
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Residential', trnOrder.Id, null, 'Housing Fee', 'Residential', 1000, null, null));
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionDiscountEntry(trnOrder.reduivy__Sample_Record_Code__c + '|Discount', trnOrder.Id, 'Discount for Tuition', 'Tuition', 500, null, null, null, null));
            
                reduivy__Transaction_Line_Item__c nonTransactionTypeTrl = new reduivy__Transaction_Line_Item__c(
                    reduivy__Item_Name__c = 'Test Non Transaction Type',
                    reduivy__Transaction_Order__c = trnOrder.Id,
                    reduivy__Unit_Price__c = 500,
                    reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_NONTRANSACTIONALENTRY
                );

                trnLineItemList.add(nonTransactionTypeTrl);
            }

            insert trnLineItemList;

            Test.stopTest();
        }
    }

    /**
     * @description Test the deletion of related transaction line item if the transaction order is deleted.
     */
    @IsTest
    static void testDeleteTrnOrderSuccessAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c, reduivy__Sample_Record_Code__c FROM reduivy__Transaction_Order__c]);

        //Transaction line items are not deleted yet
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Order__c IN: trnOrderMap.keySet()];
        System.Assert.areEqual(false, trnLineItemList.isEmpty(), 'Transaction line item should not be deleted yet.');

        System.runAs(ADMIN_USER){

            // Execute test
            Test.startTest();

            delete trnOrderMap.values();

            Test.stopTest();
        }

        trnLineItemList = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Order__c IN: trnOrderMap.keySet()];
        System.Assert.areEqual(true, trnLineItemList.isEmpty(), 'Transaction line items should be deleted.');

    }

    /**
     * @description Test the deletion of related transaction line item if the transaction order is deleted.
     */
    @IsTest
    static void testDeleteTrnOrderFailedAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        String statusConfirmed = TRO_Helper.getConfirmedStatuses().get(0);

        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>();
        List<reduivy__Transaction_Order__c> confirmedTroList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c tro : [SELECT Id, 
        reduivy__Contact__c, reduivy__Total_Amount__c, 
        reduivy__Total_Outstanding_Amount__c, 
        reduivy__Total_Paid_Amount__c, 
        reduivy__Individual_Academic_Progress__c, 
        reduivy__Status__c, 
        reduivy__Sample_Record_Code__c 
        FROM reduivy__Transaction_Order__c LIMIT 1]){
            trnOrderMap.put(tro.Id, tro);
            confirmedTroList.add(new reduivy__Transaction_Order__c(Id = tro.Id, reduivy__Status__c = statusConfirmed));
        }

        //update to confirmed to allow payment being applied
        update confirmedTroList;

        System.runAs(ADMIN_USER){
            //Create Transction Payment
            List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
            for(Id trnOrderId : trnOrderMap.keySet()){
                
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrderMap.get(trnOrderId).reduivy__Contact__c, trnOrderMap.get(trnOrderId).reduivy__Contact__c, null, 'Payment', null, 3800, 0, 'Application;Tuition;Residential'));

                //Check Field Mapping
                System.Assert.areEqual(3800, trnOrderMap.get(trnOrderId).reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
                System.Assert.areEqual(3800, trnOrderMap.get(trnOrderId).reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
                System.Assert.areEqual(0, trnOrderMap.get(trnOrderId).reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            }
            
            insert trnPaymentList;

            //Transaction line items are not deleted yet
            List<reduivy__Transaction_Line_Item__c> trnLineItemList = [SELECT Id, 
                Name, 
                reduivy__Transaction_Type__c,
                reduivy__Offset_Amount__c 
                FROM reduivy__Transaction_Line_Item__c 
                WHERE reduivy__Transaction_Order__c IN: trnOrderMap.keySet()];
            System.Assert.areEqual(false, trnLineItemList.isEmpty(), 'Transaction line item should not be deleted yet.');
            for(reduivy__Transaction_Line_Item__c trnLineItem : trnLineItemList){

                if(trnLineItem.reduivy__Transaction_Type__c == TRL_Helper.TRANSACTION_TYPE_ORDERLINE){
                    System.Assert.areEqual(true, trnLineItem.reduivy__Offset_Amount__c > 0 , 'Offset amount should be more than 0.');
                }
            }


            try {

                delete trnOrderMap.values();
                system.Assert.fail('This should fail as the related line items have payment applied.');

            }catch (Exception exp) {

                String expectedErrorString1 = Label.Cannot_Delete_Child_Error.substringBefore('(');
                String expectedErrorString2 = Label.Cannot_Delete_Child_Error.substringAfter(')');
                System.Assert.isTrue(exp.getMessage().contains(expectedErrorString1) && exp.getMessage().contains(expectedErrorString2));
            }

            
            trnLineItemList = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Order__c IN: trnOrderMap.keySet()];
            System.Assert.areEqual(false, trnLineItemList.isEmpty(), 'Transaction line items should not be deleted as there are payments applied to them.');
        }
            
        Test.stopTest();
    }

    /**
     * @description Test the deletion of related transaction line item if the transaction order is deleted.
     */
    @IsTest
    static void testDeleteTrnOrderAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c, reduivy__Sample_Record_Code__c FROM reduivy__Transaction_Order__c]);

        //Transaction line items are not deleted yet
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Order__c IN: trnOrderMap.keySet()];
        System.Assert.areEqual(false, trnLineItemList.isEmpty(), 'Transaction line item should exist');

        System.runAs(FACULTY_USER){

            // Execute test
            Test.startTest();

            try{
                delete trnOrderMap.values();
            }catch(Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'), exp.getMessage());
            }

            Test.stopTest();
        }

        trnLineItemList = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Order__c IN: trnOrderMap.keySet()];
        System.Assert.areEqual(false, trnLineItemList.isEmpty(), 'Transaction line items should not be deleted.');

    }

    /**
    * @description Test the deletion of related transaction line item if the transaction order is deleted.
    */
   @IsTest
   static void testDeleteTrnOrderAsStudent(){

        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c, reduivy__Sample_Record_Code__c FROM reduivy__Transaction_Order__c]);
        Id firstOrdId = trnOrderMap.keySet().iterator().next();

        Contact studentContact = [SELECT Id FROM Contact WHERE Id = :trnOrderMap.get(firstOrdId).reduivy__Contact__c];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId = :studentContact.Id
            AND ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        //Transaction line items are not deleted yet
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Order__c IN: trnOrderMap.keySet()];
        System.Assert.areEqual(false, trnLineItemList.isEmpty(), 'Transaction line item should exist');

        System.runAs(studentUser){

            // Execute test
            Test.startTest();

            try{
                delete trnOrderMap.values();
            }catch(Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'), exp.getMessage());
            }

            Test.stopTest();
        }

        trnLineItemList = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Order__c IN: trnOrderMap.keySet()];
        System.Assert.areEqual(false, trnLineItemList.isEmpty(), 'Transaction line items should not be deleted.');

   }

}