/**
 * @author      WDCi (Sueanne)
 * @date        July 2024
 * @group       Finance
 * @description Ensure no associated "monetary entry" transaction line item before delete "order line" transaction line item
 * @changehistory
 * ISS-002017 22-07-2024 Sueanne - New class
 */
@IsTest
public inherited sharing class TRL_DeleteValidation_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static String troStatusConfirmed = TRO_Helper.getConfirmedStatuses().get(0);
    static String troStatusDraft = TRO_Helper.getDraftStatuses().get(0);
    static String troStatusSubmitted = TRO_Helper.getSubmittedStatuses().get(0);

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
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Application', trnOrder.Id, null, 'Admission Fee', 'Application', 300, null, null));
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Tuition', trnOrder.Id, null, 'Tuition Fee', 'Tuition', 500, null, null));
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Residential', trnOrder.Id, null, 'Housing fee', 'Residential', 1000, null, null));

            }
            REDU_SystemMode_UTIL.doInsert(trnLineItemList);

            Test.stopTest();

        }
    }


    /**
     * @description Test the deletion of transaction line item (order line) when it having related transaction line item (monetary entry)
     */
    @IsTest
    static void testDeleteOrderLineForAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //change tro to confirmed first to apply payment
        List<reduivy__Transaction_Order__c> troList = [SELECT Id, reduivy__Status__c FROM reduivy__Transaction_Order__c WHERE reduivy__Sample_Record_Code__c LIKE '%|Order'];
        for(reduivy__Transaction_Order__c tro : troList) {
            tro.reduivy__Status__c = troStatusConfirmed;
        }
        update troList;

        //get all transaction line item
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = [SELECT Id, reduivy__Item_Type__c, reduivy__Transaction_Type__c, reduivy__Sample_Record_Code__c, reduivy__Transaction_Order__r.reduivy__Contact__c, reduivy__Transaction_Order__c FROM reduivy__Transaction_Line_Item__c];


        //Create Transaction Payment to pay for Tuition Order 
        List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
        Map<Id, reduivy__Transaction_Line_Item__c> orderLineMap = new Map<Id, reduivy__Transaction_Line_Item__c>();

        for(reduivy__Transaction_Line_Item__c trl : trnLineItemList){

            if(trl.reduivy__Item_Type__c == 'Tuition'){
                reduivy__Transaction_Payment__c trnPayment = REDU_TestData_UTIL.newTransactionPayment(trl.reduivy__Sample_Record_Code__c + '_Payment', trl.reduivy__Transaction_Order__r.reduivy__Contact__c, trl.reduivy__Transaction_Order__c, 'Payment', null, 500, 0, 'Tuition');
                trnPaymentList.add(trnPayment);
            }

            if(trl.reduivy__Transaction_Type__c == TRL_Helper.TRANSACTION_TYPE_ORDERLINE){
                orderLineMap.put(trl.Id, trl);
            }
        }
        REDU_SystemMode_UTIL.doInsert(trnPaymentList);
        

        //Ensure "order line" should collected in the map
        System.Assert.areEqual(false, orderLineMap.isEmpty(), 'The "order line" Transaction Line Item map should not be empty.');

        //check to ensure "monetary entry" line item exist after added Transaction Payment
        List<reduivy__Transaction_Line_Item__c> monetaryList = [SELECT Id, Name FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(false, monetaryList.isEmpty(), 'The "monetary entry" Transaction Line Item list should not be empty.');
        
        //now update tro to draft to allow deletion
        for(reduivy__Transaction_Order__c tro : troList) {
            tro.reduivy__Status__c = troStatusSubmitted;
        }
        update troList;

        System.runAs(ADMIN_USER){

            //try to delete "order line" before delete "monetary entry"
            try{
                REDU_SystemMode_UTIL.doDelete(orderLineMap.values());
                System.Assert.fail('The deletion should be fail, an exception should be thrown.');

            }catch(Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('This record can\'t be deleted because it has one or more related records'), 'The expected error message should be thrown.');
            }

            //delete the "monetary entry"
            REDU_SystemMode_UTIL.doDelete(monetaryList);

            //delete "order line" after delete "monetary entry"
            REDU_SystemMode_UTIL.doDelete(orderLineMap.values());
        }

        //check to ensure "order line" has been deleted
        List<reduivy__Transaction_Line_Item__c> orderLineAfterDelete = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_ORDERLINE];
        System.Assert.isTrue(orderLineAfterDelete.isEmpty(), 'The "order line" Transaction Line Item list should be deleted.');

        Test.stopTest();

    }

    /**
     * @description Test the deletion of transaction line item (order line) when it having related transaction line item (monetary entry)
     */
    @IsTest
    static void testDeleteOrderLineForFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //change tro to confirmed first to apply payment
        List<reduivy__Transaction_Order__c> troList = [SELECT Id, reduivy__Status__c FROM reduivy__Transaction_Order__c WHERE reduivy__Sample_Record_Code__c LIKE '%|Order'];
        for(reduivy__Transaction_Order__c tro : troList) {
            tro.reduivy__Status__c = troStatusConfirmed;
        }
        update troList;
        
        //get all transaction line item
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = [SELECT Id, reduivy__Item_Type__c, reduivy__Transaction_Type__c, reduivy__Sample_Record_Code__c, reduivy__Transaction_Order__r.reduivy__Contact__c, reduivy__Transaction_Order__c FROM reduivy__Transaction_Line_Item__c];


        //Create Transaction Payment to pay for Tuition Order 
        List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
        Map<Id, reduivy__Transaction_Line_Item__c> orderLineMap = new Map<Id, reduivy__Transaction_Line_Item__c>();

        for(reduivy__Transaction_Line_Item__c trl : trnLineItemList){

            if(trl.reduivy__Item_Type__c == 'Tuition'){
                reduivy__Transaction_Payment__c trnPayment = REDU_TestData_UTIL.newTransactionPayment(trl.reduivy__Sample_Record_Code__c + '_Payment', trl.reduivy__Transaction_Order__r.reduivy__Contact__c, trl.reduivy__Transaction_Order__c, 'Payment', null, 500, 0, 'Tuition');
                trnPaymentList.add(trnPayment);
            }

            if(trl.reduivy__Transaction_Type__c == TRL_Helper.TRANSACTION_TYPE_ORDERLINE){
                orderLineMap.put(trl.Id, trl);
            }
        }
        REDU_SystemMode_UTIL.doInsert(trnPaymentList);
        

        //Ensure "order line" should collected in the map
        System.Assert.areEqual(false, orderLineMap.isEmpty(), 'The "order line" Transaction Line Item map should not be empty.');

        //check to ensure "monetary entry" line item exist after added Transaction Payment
        List<reduivy__Transaction_Line_Item__c> monetaryList = [SELECT Id, Name FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(false, monetaryList.isEmpty(), 'The "monetary entry" Transaction Line Item list should not be empty.');
        
        //now update tro to draft to allow deletion
        for(reduivy__Transaction_Order__c tro : troList) {
            tro.reduivy__Status__c = troStatusSubmitted;
        }
        update troList;

        System.runAs(FACULTY_USER){

            //try to delete "order line" before delete "monetary entry"
            try{
                REDU_SystemMode_UTIL.doDelete(orderLineMap.values());
                System.Assert.fail('The deletion should be fail, an exception should be thrown.');

            }catch(Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('This record can\'t be deleted because it has one or more related records'), 'The expected error message should be thrown.');
            }

            //delete the "monetary entry"
            REDU_SystemMode_UTIL.doDelete(monetaryList);

            //delete "order line" after delete "monetary entry"
            REDU_SystemMode_UTIL.doDelete(orderLineMap.values());
        }

        //check to ensure "order line" has been deleted
        List<reduivy__Transaction_Line_Item__c> orderLineAfterDelete = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_ORDERLINE];
        System.Assert.isTrue(orderLineAfterDelete.isEmpty(), 'The "order line" Transaction Line Item list should be deleted.');

        Test.stopTest();

    }

    /**
     * @description Test the deletion of transaction line item (order line) when it having related transaction line item (monetary entry)
     */
    @IsTest
    static void testDeleteOrderLineForStudent(){

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

        //change tro to confirmed first to apply payment
        List<reduivy__Transaction_Order__c> troList = [SELECT Id, reduivy__Status__c FROM reduivy__Transaction_Order__c WHERE reduivy__Sample_Record_Code__c LIKE '%|Order'];
        for(reduivy__Transaction_Order__c tro : troList) {
            tro.reduivy__Status__c = troStatusConfirmed;
        }
        update troList;
        
        //get all transaction line item
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = [SELECT Id, reduivy__Item_Type__c, reduivy__Transaction_Type__c, reduivy__Sample_Record_Code__c, reduivy__Transaction_Order__r.reduivy__Contact__c, reduivy__Transaction_Order__c FROM reduivy__Transaction_Line_Item__c];


        //Create Transaction Payment to pay for Tuition Order 
        List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
        Map<Id, reduivy__Transaction_Line_Item__c> orderLineMap = new Map<Id, reduivy__Transaction_Line_Item__c>();

        for(reduivy__Transaction_Line_Item__c trl : trnLineItemList){

            if(trl.reduivy__Item_Type__c == 'Tuition'){
                reduivy__Transaction_Payment__c trnPayment = REDU_TestData_UTIL.newTransactionPayment(trl.reduivy__Sample_Record_Code__c + '_Payment', trl.reduivy__Transaction_Order__r.reduivy__Contact__c, trl.reduivy__Transaction_Order__c, 'Payment', null, 500, 0, 'Tuition');
                trnPaymentList.add(trnPayment);
            }

            if(trl.reduivy__Transaction_Type__c == TRL_Helper.TRANSACTION_TYPE_ORDERLINE){
                orderLineMap.put(trl.Id, trl);
            }
        }
        REDU_SystemMode_UTIL.doInsert(trnPaymentList);
        

        //Ensure "order line" should collected in the map
        System.Assert.areEqual(false, orderLineMap.isEmpty(), 'The "order line" Transaction Line Item map should not be empty.');

        //check to ensure "monetary entry" line item exist after added Transaction Payment
        List<reduivy__Transaction_Line_Item__c> monetaryList = [SELECT Id, Name FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(false, monetaryList.isEmpty(), 'The "monetary entry" Transaction Line Item list should not be empty.');
        
        //now update tro to draft to allow deletion
        for(reduivy__Transaction_Order__c tro : troList) {
            tro.reduivy__Status__c = troStatusSubmitted;
        }
        update troList;

        System.runAs(studentUser){

            //try to delete "order line" before delete "monetary entry"
            try{
                REDU_SystemMode_UTIL.doDelete(orderLineMap.values());
                System.Assert.fail('The deletion should be fail, an exception should be thrown.');

            }catch(Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('This record can\'t be deleted because it has one or more related records'), 'The expected error message should be thrown.');
            }

            //delete the "monetary entry"
            REDU_SystemMode_UTIL.doDelete(monetaryList);

            //delete "order line" after delete "monetary entry"
            REDU_SystemMode_UTIL.doDelete(orderLineMap.values());
        }

        //check to ensure "order line" has been deleted
        List<reduivy__Transaction_Line_Item__c> orderLineAfterDelete = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_ORDERLINE];
        System.Assert.isTrue(orderLineAfterDelete.isEmpty(), 'The "order line" Transaction Line Item list should be deleted.');

        Test.stopTest();

    }

}