/**
 * @author      WDCi (Sueanne)
 * @date        July 2024
 * @group       Finance
 * @description To test the deletion of "Discount Entry" Transaction Line Item when deleting the offsetting "Order Line" Transaction Line Item
 * @changehistory
 * ISS-002030 23-07-2024 Sueanne - New class
 */
@IsTest
public inherited sharing class TRL_DeleteDiscount_TEST {
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Default method to setup required data for automated test
     */
    @TestSetup
    static void makeData(){
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {

            Test.startTest();

            testFactory.initMasterData(SPL_Helper.getApiName());
            testFactory.initOfferingData(SST_Helper.getApiName());
            testFactory.initStudentData(IPE_Helper.getApiName(), true);

            //Create Academic Progress
            Date todayDate = date.today();
            List<reduivy__Study_Term__c> termList = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Start_Date__c <= :todayDate AND reduivy__End_Date__c >= :todayDate AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() ORDER BY Name ASC];
            
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
            REDU_SystemMode_UTIL.doInsert(termProgressList);


            //Create Transaction Order
            List<reduivy__Transaction_Order__c> transactionOrderList = new List<reduivy__Transaction_Order__c>();
            String troStatusDraft = TRO_Helper.getDraftStatuses().get(0);
            for(reduivy__Individual_Academic_Progress__c termProgress : termProgressList){

                reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(termProgress.reduivy__Sample_Record_Code__c + '|Order', termProgress.reduivy__Contact__c, termProgress.Id, todayDate, troStatusDraft, 0, 0, 0);
                transactionOrder.reduivy__Apply_Payment__c = true;
                transactionOrder.reduivy__Apply_Non_Repayable_FA__c = true;
                transactionOrder.reduivy__Apply_Repayable_FA__c = true;
                transactionOrderList.add(transactionOrder);
            }
            REDU_SystemMode_UTIL.doInsert(transactionOrderList);


            List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
            for(reduivy__Transaction_Order__c trnOrder : transactionOrderList){
                
                //Create Transaction Line Item
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Tuition', trnOrder.Id, null, 'Tuition Fee', 'Tuition', 2500, null, null));

            }
            REDU_SystemMode_UTIL.doInsert(trnLineItemList);

            Test.stopTest();
        }
    }

    /**
     * @description Test the deletion of transaction line item (discount entry) when deleting the offsetting transaction line item (order line)
     */
    @IsTest
    static void testDiscountEntryDeletionForAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get "order line" Transaction Line Item
        Map<Id, reduivy__Transaction_Line_Item__c> orderLineMap = new Map<Id, reduivy__Transaction_Line_Item__c>([
            SELECT Id, reduivy__Item_Type__c, reduivy__Transaction_Type__c, reduivy__Sample_Record_Code__c, reduivy__Transaction_Order__c 
            FROM reduivy__Transaction_Line_Item__c
            WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_ORDERLINE
        ]);

        //add "order line" Transaction Line Item, and apply to the "order line"
        List<reduivy__Transaction_Line_Item__c> discountToInsert = new List<reduivy__Transaction_Line_Item__c>();

        for(reduivy__Transaction_Line_Item__c trl : orderLineMap.values()){

            reduivy__Transaction_Line_Item__c discountLine = REDU_TestData_UTIL.newTransactionDiscountEntry(trl.reduivy__Sample_Record_Code__c + '|Discount', trl.reduivy__Transaction_Order__c, 'Tuition Fee Discount', 'Tuition', 500, null, null, null, null);
            discountLine.reduivy__Offset_Line_Item__c = trl.Id;
            discountToInsert.add(discountLine);
        }

        System.Assert.areEqual(false, discountToInsert.isEmpty(), 'The "discount entry" Transaction Line Item map should not be empty.');
        REDU_SystemMode_UTIL.doInsert(discountToInsert);

        System.runAs(ADMIN_USER){

            //delete "order line"
            REDU_SystemMode_UTIL.doDelete(orderLineMap.values());
        }

        //check to ensure "order line" has been deleted
        List<reduivy__Transaction_Line_Item__c> orderLineAfterDelete = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_ORDERLINE];
        System.Assert.isTrue(orderLineAfterDelete.isEmpty(), 'The "order line" Transaction Line Item list should be deleted.');

        //check to ensure "discount entry" has been deleted too
        List<reduivy__Transaction_Line_Item__c> discountEntryAfterDelete = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY];
        System.Assert.isTrue(discountEntryAfterDelete.isEmpty(), 'The "discount entry" Transaction Line Item list should be deleted.');

        Test.stopTest();

    }

    /**
     * @description Test the deletion of transaction line item (discount entry) when deleting the offsetting transaction line item (order line)
     */
    @IsTest
    static void testDiscountEntryDeletionForFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //get "order line" Transaction Line Item
        Map<Id, reduivy__Transaction_Line_Item__c> orderLineMap = new Map<Id, reduivy__Transaction_Line_Item__c>([
            SELECT Id, reduivy__Item_Type__c, reduivy__Transaction_Type__c, reduivy__Sample_Record_Code__c, reduivy__Transaction_Order__c 
            FROM reduivy__Transaction_Line_Item__c
            WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_ORDERLINE
        ]);

        //add "order line" Transaction Line Item, and apply to the "order line"
        List<reduivy__Transaction_Line_Item__c> discountToInsert = new List<reduivy__Transaction_Line_Item__c>();

        for(reduivy__Transaction_Line_Item__c trl : orderLineMap.values()){

            reduivy__Transaction_Line_Item__c discountLine = REDU_TestData_UTIL.newTransactionDiscountEntry(trl.reduivy__Sample_Record_Code__c + '|Discount', trl.reduivy__Transaction_Order__c, 'Tuition Fee Discount', 'Tuition', 500, null, null, null, null);
            discountLine.reduivy__Offset_Line_Item__c = trl.Id;
            discountToInsert.add(discountLine);
        }

        System.Assert.areEqual(false, discountToInsert.isEmpty(), 'The "discount entry" Transaction Line Item map should not be empty.');
        REDU_SystemMode_UTIL.doInsert(discountToInsert);

        System.runAs(FACULTY_USER){

            //delete "order line"
            REDU_SystemMode_UTIL.doDelete(orderLineMap.values());
        }

        //check to ensure "order line" has been deleted
        List<reduivy__Transaction_Line_Item__c> orderLineAfterDelete = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_ORDERLINE];
        System.Assert.isTrue(orderLineAfterDelete.isEmpty(), 'The "order line" Transaction Line Item list should be deleted.');

        //check to ensure "discount entry" has been deleted too
        List<reduivy__Transaction_Line_Item__c> discountEntryAfterDelete = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY];
        System.Assert.isTrue(discountEntryAfterDelete.isEmpty(), 'The "discount entry" Transaction Line Item list should be deleted.');

        Test.stopTest();

    }

    /**
     * @description Test the deletion of transaction line item (discount entry) when deleting the offsetting transaction line item (order line)
     */
    @IsTest
    static void testDiscountEntryDeletionForStudent(){

        //get student
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        Test.startTest();

        //get "order line" Transaction Line Item
        Map<Id, reduivy__Transaction_Line_Item__c> orderLineMap = new Map<Id, reduivy__Transaction_Line_Item__c>([
            SELECT Id, reduivy__Item_Type__c, reduivy__Transaction_Type__c, reduivy__Sample_Record_Code__c, reduivy__Transaction_Order__c 
            FROM reduivy__Transaction_Line_Item__c
            WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_ORDERLINE
        ]);

        //add "order line" Transaction Line Item, and apply to the "order line"
        List<reduivy__Transaction_Line_Item__c> discountToInsert = new List<reduivy__Transaction_Line_Item__c>();

        for(reduivy__Transaction_Line_Item__c trl : orderLineMap.values()){

            reduivy__Transaction_Line_Item__c discountLine = REDU_TestData_UTIL.newTransactionDiscountEntry(trl.reduivy__Sample_Record_Code__c + '|Discount', trl.reduivy__Transaction_Order__c, 'Tuition Fee Discount', 'Tuition', 500, null, null, null, null);
            discountLine.reduivy__Offset_Line_Item__c = trl.Id;
            discountToInsert.add(discountLine);
        }

        System.Assert.areEqual(false, discountToInsert.isEmpty(), 'The "discount entry" Transaction Line Item map should not be empty.');
        REDU_SystemMode_UTIL.doInsert(discountToInsert);

        System.runAs(studentUser){

            //ty to delete "order line"
            try{
                REDU_Database_UTIL.doDelete(orderLineMap.values());
                System.Assert.fail('The deletion should be failed.');
            }catch(Exception exp){
                System.Assert.areEqual(true, exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'), 'The expected error message should be thrown.');
            }
        }

        //check to ensure "order line" has not been deleted
        List<reduivy__Transaction_Line_Item__c> orderLineAfterDelete = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_ORDERLINE];
        System.Assert.areEqual(false, orderLineAfterDelete.isEmpty(), 'The "order line" Transaction Line Item list should not be deleted.');

        //check to ensure "discount entry" has not been deleted
        List<reduivy__Transaction_Line_Item__c> discountEntryAfterDelete = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY];
        System.Assert.areEqual(false, discountEntryAfterDelete.isEmpty(), 'The "discount entry" Transaction Line Item list should not be deleted.');

        Test.stopTest();

    }
    
}