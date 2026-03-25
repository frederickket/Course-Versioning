/**
 * @author      WDCi (VTan)
 * @date        Mar 2024
 * @group       Finance
 * @description Test class for TRL_ApplyPayment_EXE
 * @changehistory
 * ISS-001866 26-02-2024 VTan - New class
 * ISS-002288 19-02-2025 XW - added test for 2 transaction payment with same type and remaining
 */
@IsTest
public inherited sharing class TRL_ApplyPayment_TEST{
    
    static final String SCHOLARSHIP = 'Scholarship';
    static final String GRANT = 'Grant';
    static final String FEDERALLOAN = 'Federal Student Loan';
    static List<String> TRO_STATUSES_CONFIRMED = TRO_Helper.getConfirmedStatuses();
    static List<String> TRO_STATUSES_DRAFT = TRO_Helper.getDraftStatuses();

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

            insert termProgressList;

            //Create Study Funding
            List<reduivy__Study_Funding__c> studyFunding = new List<reduivy__Study_Funding__c>();
            studyFunding.add(REDU_TestData_UTIL.newStudyFunding('ACME Scholarship', 'ACME Scholarship', SCHOLARSHIP, 5000000, 1, 0, 0, SFD_Helper.STATUS_ACTIVE));
            studyFunding.add(REDU_TestData_UTIL.newStudyFunding('ACME Grant', 'ACME Grant', GRANT, 5000000, 2, 0, 0, SFD_Helper.STATUS_ACTIVE));
            studyFunding.add(REDU_TestData_UTIL.newStudyFunding('ACME Scholarship Rich', 'ACME Scholarship Rich', SCHOLARSHIP, 5000000, 1, 0, 0, SFD_Helper.STATUS_ACTIVE));
            studyFunding.add(REDU_TestData_UTIL.newStudyFunding('Federal Loan', 'Federal Loan', FEDERALLOAN, 5000000, 2, 0, 0, SFD_Helper.STATUS_ACTIVE));
            studyFunding.add(REDU_TestData_UTIL.newStudyFunding('Federal Loan 2', 'Federal Loan 2', FEDERALLOAN, 5000000, 2, 0, 0, SFD_Helper.STATUS_ACTIVE));
            insert studyFunding;

            //Create Transaction Order && Funding Allocation
            List<reduivy__Transaction_Order__c> transactionOrderList = new List<reduivy__Transaction_Order__c>();
            List<reduivy__Individual_Funding_Allocation__c> idvFundingAllocationList = new List<reduivy__Individual_Funding_Allocation__c>();
            String statusDraft = TRO_STATUSES_DRAFT.get(0);
            for(reduivy__Individual_Academic_Progress__c termProgress : termProgressList){

                reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(termProgress.reduivy__Sample_Record_Code__c + '|Order', termProgress.reduivy__Contact__c, termProgress.Id, todayDate, statusDraft, 0, 0, 0);
                transactionOrder.reduivy__Apply_Payment__c = true;
                transactionOrder.reduivy__Apply_Non_Repayable_FA__c = true;
                transactionOrder.reduivy__Apply_Repayable_FA__c = true;
                transactionOrderList.add(transactionOrder);

                idvFundingAllocationList.add(REDU_TestData_UTIL.newIdvFundingAllocation(studyFunding[0].reduivy__Sample_Record_Code__c + '|' + termProgress.reduivy__Contact__c, termProgress.reduivy__Contact__c, studyFunding[0].Id, 1000, System.today(), System.today().addDays(180), 0, IFA_Helper.STATUS_ACTIVE));
                idvFundingAllocationList.add(REDU_TestData_UTIL.newIdvFundingAllocation(studyFunding[1].reduivy__Sample_Record_Code__c + '|' + termProgress.reduivy__Contact__c, termProgress.reduivy__Contact__c, studyFunding[1].Id, 500, System.today(), System.today().addDays(180), 0, IFA_Helper.STATUS_ACTIVE));
                idvFundingAllocationList.add(REDU_TestData_UTIL.newIdvFundingAllocation(studyFunding[2].reduivy__Sample_Record_Code__c + '|' + termProgress.reduivy__Contact__c, termProgress.reduivy__Contact__c, studyFunding[2].Id, 2600, System.today(), System.today().addDays(180), 0, IFA_Helper.STATUS_ACTIVE));
                idvFundingAllocationList.add(REDU_TestData_UTIL.newIdvFundingAllocation(studyFunding[3].reduivy__Sample_Record_Code__c + '|' + termProgress.reduivy__Contact__c, termProgress.reduivy__Contact__c, studyFunding[3].Id, 800, System.today(), System.today().addDays(180), 0, IFA_Helper.STATUS_ACTIVE));
                idvFundingAllocationList.add(REDU_TestData_UTIL.newIdvFundingAllocation(studyFunding[4].reduivy__Sample_Record_Code__c + '|' + termProgress.reduivy__Contact__c, termProgress.reduivy__Contact__c, studyFunding[4].Id, 700, System.today(), System.today().addDays(180), 0, IFA_Helper.STATUS_ACTIVE));
            }

            insert transactionOrderList;
            insert idvFundingAllocationList;

            Test.stopTest();
        }
    }


/**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testApplyPaymentAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
        for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, reduivy__Contact__c, reduivy__Amount__c FROM reduivy__Individual_Funding_Allocation__c]){

            fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
        }

        //Create Transction Payment
        List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c, reduivy__Sample_Record_Code__c 
                                                FROM reduivy__Transaction_Order__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');

            //Prepare Transaction Line Item for insertion during test
            trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Application', trnOrder.Id, null, 'Admission Fee', 'Application', 300, null, null));
            trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Tuition', trnOrder.Id, null, 'Tuition Fee', 'Tuition', 2500, null, null));
            trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Residential', trnOrder.Id, null, 'Housing fee', 'Residential', 1000, null, null));

            //update status to confirmed
            trnOrderList.add(new reduivy__Transaction_Order__c(Id = trnOrder.Id, reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0)));
        }
        
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trnLineItemCheck = [SELECT Id FROM reduivy__Transaction_Line_Item__c ];
        System.Assert.areEqual(true, trnLineItemCheck.isEmpty(), 'Transaction Line Items (both line item and monetary entry) should not be created yet');

        System.runAs(ADMIN_USER){

            // Execute test
            Test.startTest();

            insert trnLineItemList;
            update trnOrderList;

            Test.stopTest();
        }

        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c FROM reduivy__Transaction_Order__c]){
            
            //Check Field Mapping
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to 0');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 3800 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');
        }

        //check for empty amount of fee line
        List<reduivy__Transaction_Line_Item__c> trlList = [SELECT Id 
            FROM reduivy__Transaction_Line_Item__c 
            WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY 
            AND reduivy__Total_Amount__c = 0];
        
        System.Assert.areEqual(0, trlList.size(), 'Transaction Line Item with total amount of 0 should not be created!');

        Map<Id, Decimal> conTotalRemainingAmountMap =  new Map<Id, Decimal>();
        for(reduivy__Transaction_Payment__c trnPayment : [SELECT Id, reduivy__Contact__c, reduivy__Amount__c, reduivy__Remaining_Amount__c, reduivy__Applicable_Item_Type__c, reduivy__Transaction_Type__c FROM reduivy__Transaction_Payment__c]){
            
            if(conTotalRemainingAmountMap.containsKey(trnPayment.reduivy__Contact__c)){
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, conTotalRemainingAmountMap.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId : conTotalRemainingAmountMap.keySet()){
            System.Assert.areEqual(200, conTotalRemainingAmountMap.get(conId), 'Total remaining amount for transaction payment should be 200');
        }
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testApplyPaymentWithRemainingForSameTypeAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
        for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, reduivy__Contact__c, reduivy__Amount__c FROM reduivy__Individual_Funding_Allocation__c]){

            fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
        }

        //Create Transction Payment
        List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c, reduivy__Sample_Record_Code__c 
                                                FROM reduivy__Transaction_Order__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');

            //Prepare Transaction Line Item for insertion during test
            trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Application', trnOrder.Id, null, 'Admission Fee', 'Application', 300, null, null));
            trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Tuition', trnOrder.Id, null, 'Tuition Fee', 'Tuition', 2500, null, null));
            trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Residential', trnOrder.Id, null, 'Housing fee', 'Residential', 1000, null, null));
            
            //update status to confirmed
            trnOrderList.add(new reduivy__Transaction_Order__c(Id = trnOrder.Id, reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0)));
        }
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trnLineItemCheck = [SELECT Id FROM reduivy__Transaction_Line_Item__c ];
        System.Assert.areEqual(true, trnLineItemCheck.isEmpty(), 'Transaction Line Items (both line item and monetary entry) should not be created yet');

        System.runAs(ADMIN_USER){

            // Execute test
            Test.startTest();

            insert trnLineItemList;
            update trnOrderList;

            Test.stopTest();
        }

        //check for empty amount of fee line
        List<reduivy__Transaction_Line_Item__c> trlList = [SELECT Id 
            FROM reduivy__Transaction_Line_Item__c 
            WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY 
            AND reduivy__Total_Amount__c = 0];
        
        System.Assert.areEqual(0, trlList.size(), 'Transaction Line Item with total amount of 0 should not be created!');

        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c FROM reduivy__Transaction_Order__c]){
            
            //Check Field Mapping
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to 0');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 3800 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');
        }

        Map<Id, Decimal> conTotalRemainingAmountMap =  new Map<Id, Decimal>();
        for(reduivy__Transaction_Payment__c trnPayment : [SELECT Id, reduivy__Contact__c, reduivy__Amount__c, reduivy__Remaining_Amount__c, reduivy__Applicable_Item_Type__c, reduivy__Transaction_Type__c FROM reduivy__Transaction_Payment__c]){
            
            if(conTotalRemainingAmountMap.containsKey(trnPayment.reduivy__Contact__c)){
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, conTotalRemainingAmountMap.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId : conTotalRemainingAmountMap.keySet()){
            System.Assert.areEqual(600, conTotalRemainingAmountMap.get(conId), 'Total remaining amount for transaction payment should be 600');
        }
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testApplyPaymentAsStudent(){

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, 
                                                            reduivy__Contact__c 
                                                            FROM reduivy__Individual_Program_Enrollment__c 
                                                            WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, 
                        ContactId, 
                        ProfileId 
                        FROM User 
                        WHERE ContactId = : masterIPE.reduivy__Contact__c];

        Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
        for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, 
                                                                        reduivy__Contact__c, 
                                                                        reduivy__Amount__c 
                                                                        FROM reduivy__Individual_Funding_Allocation__c
                                                                        WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]){

            fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
        }

        //Create Transction Payment
        List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c, 
                                                    reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c
                                                    WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');

            //Prepare Transaction Line Item for insertion during test
            trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Application', trnOrder.Id, null, 'Admission Fee', 'Application', 300, null, null));
            trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Tuition', trnOrder.Id, null, 'Tuition Fee', 'Tuition', 2500, null, null));
            trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Residential', trnOrder.Id, null, 'Housing fee', 'Residential', 1000, null, null));
            
            //update status to confirmed
            trnOrderList.add(new reduivy__Transaction_Order__c(Id = trnOrder.Id, reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0)));
        }
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trnLineItemCheck = [SELECT Id FROM reduivy__Transaction_Line_Item__c ];
        System.Assert.areEqual(true, trnLineItemCheck.isEmpty(), 'Transaction Line Items (both line item and monetary entry) should not be created yet');

        System.runAs(studentUser){

            // Execute test
            Test.startTest();

            insert trnLineItemList;
            update trnOrderList;

            Test.stopTest();
        }

        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c 
                                                    FROM reduivy__Transaction_Order__c 
                                                    WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]){
            
            //Check Field Mapping
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to 0');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 3800 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');
        }

        //check for empty amount of fee line
        List<reduivy__Transaction_Line_Item__c> trlList = [SELECT Id 
            FROM reduivy__Transaction_Line_Item__c 
            WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY 
            AND reduivy__Total_Amount__c = 0];
        
        System.Assert.areEqual(0, trlList.size(), 'Transaction Line Item with total amount of 0 should not be created!');

        Map<Id, Decimal> conTotalRemainingAmountMap =  new Map<Id, Decimal>();
        for(reduivy__Transaction_Payment__c trnPayment : [SELECT Id, 
                                                        reduivy__Contact__c, 
                                                        reduivy__Amount__c, 
                                                        reduivy__Remaining_Amount__c, 
                                                        reduivy__Applicable_Item_Type__c, 
                                                        reduivy__Transaction_Type__c 
                                                        FROM reduivy__Transaction_Payment__c
                                                        WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]){
            
            if(conTotalRemainingAmountMap.containsKey(trnPayment.reduivy__Contact__c)){
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, conTotalRemainingAmountMap.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId : conTotalRemainingAmountMap.keySet()){
            System.Assert.areEqual(200, conTotalRemainingAmountMap.get(conId), 'Total remaining amount for transaction payment should be 200');
        }
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testApplyPaymentWithRemainingForSameTypeAsStudent(){

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, 
                                                            reduivy__Contact__c 
                                                            FROM reduivy__Individual_Program_Enrollment__c 
                                                            WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, 
                        ContactId, 
                        ProfileId 
                        FROM User 
                        WHERE ContactId = : masterIPE.reduivy__Contact__c];

        Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
        for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, 
                                                                        reduivy__Contact__c, 
                                                                        reduivy__Amount__c 
                                                                        FROM reduivy__Individual_Funding_Allocation__c
                                                                        WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]){

            fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
        }

        //Create Transction Payment
        List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c, 
                                                    reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c
                                                    WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');

            //Prepare Transaction Line Item for insertion during test
            trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Application', trnOrder.Id, null, 'Admission Fee', 'Application', 300, null, null));
            trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Tuition', trnOrder.Id, null, 'Tuition Fee', 'Tuition', 2500, null, null));
            trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Residential', trnOrder.Id, null, 'Housing fee', 'Residential', 1000, null, null));
            
            //update status to confirmed
            trnOrderList.add(new reduivy__Transaction_Order__c(Id = trnOrder.Id, reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0)));
        }
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trnLineItemCheck = [SELECT Id FROM reduivy__Transaction_Line_Item__c ];
        System.Assert.areEqual(true, trnLineItemCheck.isEmpty(), 'Transaction Line Items (both line item and monetary entry) should not be created yet');

        System.runAs(studentUser){

            // Execute test
            Test.startTest();

            insert trnLineItemList;
            update trnOrderList;

            Test.stopTest();
        }

        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c 
                                                    FROM reduivy__Transaction_Order__c 
                                                    WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]){
            
            //Check Field Mapping
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to 0');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 3800 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');
        }

        //check for empty amount of fee line
        List<reduivy__Transaction_Line_Item__c> trlList = [SELECT Id 
            FROM reduivy__Transaction_Line_Item__c 
            WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY 
            AND reduivy__Total_Amount__c = 0];
    
        System.Assert.areEqual(0, trlList.size(), 'Transaction Line Item with total amount of 0 should not be created!');

        Map<Id, Decimal> conTotalRemainingAmountMap =  new Map<Id, Decimal>();
        for(reduivy__Transaction_Payment__c trnPayment : [SELECT Id, 
                                                        reduivy__Contact__c, 
                                                        reduivy__Amount__c, 
                                                        reduivy__Remaining_Amount__c, 
                                                        reduivy__Applicable_Item_Type__c, 
                                                        reduivy__Transaction_Type__c 
                                                        FROM reduivy__Transaction_Payment__c
                                                        WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]){
            
            if(conTotalRemainingAmountMap.containsKey(trnPayment.reduivy__Contact__c)){
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, conTotalRemainingAmountMap.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId : conTotalRemainingAmountMap.keySet()){
            System.Assert.areEqual(600, conTotalRemainingAmountMap.get(conId), 'Total remaining amount for transaction payment should be 600');
        }
    }
}