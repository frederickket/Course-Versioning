/**
 * @author      WDCi (Sueanne)
 * @date        June 2024
 * @group       Finance
 * @description Test class for TRP_DeleteLineItems_EXE
 * @changehistory
 * ISS-001988 27-06-2024 Sueanne - New class
 */
@IsTest
public inherited sharing class TRP_DeleteLineItems_TEST{
    
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
            reduivy__Study_Term__c currentTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Sample_Record_Code__c = : testFactory.CYTKey LIMIT 1];
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
            List<reduivy__Transaction_Order__c> confirmedTransactionOrderList = new List<reduivy__Transaction_Order__c>();
            List<String> troConfirmedStatuses = TRO_Helper.getConfirmedStatuses();
            List<String> troDraftStatuses = TRO_Helper.getDraftStatuses();
            for(reduivy__Individual_Academic_Progress__c termProgress : termProgressList){

                reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(termProgress.reduivy__Sample_Record_Code__c + '|Order', termProgress.reduivy__Contact__c, termProgress.Id, todayDate, troDraftStatuses.get(0), 0, 0, 0);
                transactionOrder.reduivy__Apply_Payment__c = true;
                transactionOrder.reduivy__Apply_Non_Repayable_FA__c = true;
                transactionOrder.reduivy__Apply_Repayable_FA__c = true;
                transactionOrderList.add(transactionOrder);
            }

            REDU_SystemMode_UTIL.doInsert(transactionOrderList);

            List<reduivy__Transaction_Payment__c> transactionPaymentList = new List<reduivy__Transaction_Payment__c>();
            List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();

            for(reduivy__Transaction_Order__c trnOrder : transactionOrderList){
                //update to confirmed
                confirmedTransactionOrderList.add(new reduivy__Transaction_Order__c(Id = trnOrder.Id, reduivy__Status__c = troConfirmedStatuses.get(0)));
                
                //Create Transaction Payment
                transactionPaymentList.add(REDU_TestData_UTIL.newTransactionPayment(trnOrder.reduivy__Sample_Record_Code__c + '|Payment', trnOrder.reduivy__Contact__c, null, 'Payment', null, 500, 0, 'Application'));
                
                //Create Transaction Line Item - Order Line for TRO
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Application', trnOrder.Id, null, 'Admission Fee', 'Application', 300, null, null));
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Residential', trnOrder.Id, null, 'Residential Fee', 'Residential', 500, null, null));
            }
            
            REDU_SystemMode_UTIL.doInsert(trnLineItemList);
            REDU_SystemMode_UTIL.doUpdate(confirmedTransactionOrderList);
            REDU_SystemMode_UTIL.doInsert(transactionPaymentList);

            Test.stopTest();
        }
    }

    /**
     * @description Test as Admin for the deletion of related transaction line item if the transaction payment is deleted.
     */
    @IsTest
    static void testDeleteTrnPaymentAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        Map<Id, reduivy__Transaction_Payment__c> trnPaymentMap = new Map<Id, reduivy__Transaction_Payment__c>();

        System.runAs(ADMIN_USER){

            // Execute test
            Test.startTest();

            trnPaymentMap = new Map<Id, reduivy__Transaction_Payment__c>([SELECT Id, reduivy__Contact__c, reduivy__Transaction_Order__c, reduivy__Transaction_Type__c, reduivy__Individual_Funding_Allocation__c, reduivy__Amount__c, reduivy__Status__c, reduivy__Applicable_Item_Type__c, reduivy__Sample_Record_Code__c FROM reduivy__Transaction_Payment__c]);

            //Transaction line items are not deleted yet
            trnLineItemList = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Payment__c IN: trnPaymentMap.keySet()];
            System.Assert.areEqual(false, trnLineItemList.isEmpty(), 'Transaction line item should not be deleted yet.');

            REDU_SystemMode_UTIL.doDelete(trnPaymentMap.values());

            Test.stopTest();
        }

        trnLineItemList.clear();
        trnLineItemList = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Payment__c IN: trnPaymentMap.keySet()];
        System.Assert.areEqual(true, trnLineItemList.isEmpty(), 'Transaction line items should be deleted.');

        trnLineItemList.clear();
        trnLineItemList = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Payment__c NOT IN: trnPaymentMap.keySet() LIMIT 1];
        System.Assert.areEqual(false, trnLineItemList.isEmpty(), 'Transaction line items that no linked to Transaction Payment should not be deleted.');
    }

    /**
     * @description Test as Faculty user for the deletion of related transaction line item if the transaction payment is deleted.
     */
    @IsTest
    static void testDeleteTrnPaymentAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Map<Id, reduivy__Transaction_Payment__c> trnPaymentMap = new Map<Id, reduivy__Transaction_Payment__c>([SELECT Id, reduivy__Contact__c, reduivy__Transaction_Order__c, reduivy__Transaction_Type__c, reduivy__Individual_Funding_Allocation__c, reduivy__Amount__c, reduivy__Status__c, reduivy__Applicable_Item_Type__c, reduivy__Sample_Record_Code__c FROM reduivy__Transaction_Payment__c]);

        //Transaction line items are not deleted yet
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Payment__c IN: trnPaymentMap.keySet()];
        System.Assert.areEqual(false, trnLineItemList.isEmpty(), 'Transaction line item should be insert for test.');

        System.runAs(FACULTY_USER){

            // Execute test
            Test.startTest();

            try {
                Database.delete(trnPaymentMap.values(),  AccessLevel.USER_MODE);
                System.Assert.fail('Faculty user should not have permission to delete Transaction Payment.');

            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY') || exp.getMessage().contains('DML operation DELETE not allowed'), 'The error should be include CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY');
            }

            Test.stopTest();
        }

    }

    /**
     * @description Test as Student user for the deletion of related transaction line item if the transaction payment is deleted.
     */
    @IsTest
    static void testDeleteTrnPaymentAsStudent(){

        //get a student for test & assign permission set
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

		User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
            LIMIT 1
        ];
        
        Map<Id, reduivy__Transaction_Payment__c> trnPaymentMap = new Map<Id, reduivy__Transaction_Payment__c>([SELECT Id, reduivy__Contact__c, reduivy__Transaction_Order__c, reduivy__Transaction_Type__c, reduivy__Individual_Funding_Allocation__c, reduivy__Amount__c, reduivy__Status__c, reduivy__Applicable_Item_Type__c, reduivy__Sample_Record_Code__c FROM reduivy__Transaction_Payment__c]);

        //Transaction line items are not deleted yet
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Payment__c IN: trnPaymentMap.keySet()];
        System.Assert.areEqual(false, trnLineItemList.isEmpty(), 'Transaction line item should be insert for test.');

        System.runAs(studentUser){

            // Execute test
            Test.startTest();

            try {
                Database.delete(trnPaymentMap.values(),  AccessLevel.USER_MODE);
                System.Assert.fail('Student user should not have permission to delete Transaction Payment.');

            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY') || exp.getMessage().contains('DML operation DELETE not allowed'), 'The error should be include CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY');
            }

            Test.stopTest();
        }

    }

}