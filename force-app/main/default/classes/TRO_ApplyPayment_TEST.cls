/**
 * @author      WDCi (VTan)
 * @date        Feb 2024
 * @group       Finance
 * @description Test class for TRO_ApplyPayment_EXE
 * @changehistory
 * ISS-001866 26-02-2024 VTan - New class
 * ISS-001986 25-06-2024 Sueanne - Added test for the case without link TRO to Individual Academic Progress and only checked Disburse Repayable/Non Repayable FA
 * ISS-002288 19-02-2025 XW - added test for 2 transaction payment with same type and remaining
 * ISS-002578 08-08-2025 XiRouh - Added test for overpayment
 */
@IsTest
public inherited sharing class TRO_ApplyPayment_TEST{
    
    static final String SCHOLARSHIP = 'Scholarship';
    static final String GRANT = 'Grant';
    static final String FEDERALLOAN = 'Federal Student Loan';
    static List<String> TRO_STATUSES_DRAFT = TRO_Helper.getDraftStatuses();
    static List<String> TRO_STATUSES_CONFIRMED = TRO_Helper.getConfirmedStatuses();

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
            reduivy__Study_Term__c currentTerm = [SELECT Id 
                                                FROM reduivy__Study_Term__c 
                                                WHERE reduivy__Sample_Record_Code__c = : testFactory.CYTKey LIMIT 1];
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
            for(reduivy__Individual_Academic_Progress__c termProgress : termProgressList){

                reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(termProgress.reduivy__Sample_Record_Code__c + '|Order', termProgress.reduivy__Contact__c, termProgress.Id, todayDate, TRO_STATUSES_DRAFT.get(0), 0, 0, 0);
                transactionOrder.reduivy__Apply_Payment__c = true;
                transactionOrder.reduivy__Apply_Non_Repayable_FA__c = true;
                transactionOrder.reduivy__Apply_Repayable_FA__c = true;
                transactionOrderList.add(transactionOrder);

                idvFundingAllocationList.add(REDU_TestData_UTIL.newIdvFundingAllocation(studyFunding[0].reduivy__Sample_Record_Code__c + '|' + termProgress.reduivy__Contact__c, termProgress.reduivy__Contact__c, studyFunding[0].Id, 1000, System.today(), System.today().addDays(180), 0, IFA_Helper.STATUS_ACTIVE));
                idvFundingAllocationList.add(REDU_TestData_UTIL.newIdvFundingAllocation(studyFunding[1].reduivy__Sample_Record_Code__c + '|' + termProgress.reduivy__Contact__c, termProgress.reduivy__Contact__c, studyFunding[1].Id, 500, System.today(), System.today().addDays(180), 0, IFA_Helper.STATUS_ACTIVE));
                idvFundingAllocationList.add(REDU_TestData_UTIL.newIdvFundingAllocation(studyFunding[2].reduivy__Sample_Record_Code__c + '|' + termProgress.reduivy__Contact__c, termProgress.reduivy__Contact__c, studyFunding[0].Id, 2600, System.today(), System.today().addDays(180), 0, IFA_Helper.STATUS_ACTIVE));
                idvFundingAllocationList.add(REDU_TestData_UTIL.newIdvFundingAllocation(studyFunding[3].reduivy__Sample_Record_Code__c + '|' + termProgress.reduivy__Contact__c, termProgress.reduivy__Contact__c, studyFunding[2].Id, 800, System.today(), System.today().addDays(180), 0, IFA_Helper.STATUS_ACTIVE));
                idvFundingAllocationList.add(REDU_TestData_UTIL.newIdvFundingAllocation(studyFunding[4].reduivy__Sample_Record_Code__c + '|' + termProgress.reduivy__Contact__c, termProgress.reduivy__Contact__c, studyFunding[3].Id, 700, System.today(), System.today().addDays(180), 0, IFA_Helper.STATUS_ACTIVE));
            }

            insert transactionOrderList;
            insert idvFundingAllocationList;

            List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
            for(reduivy__Transaction_Order__c trnOrder : transactionOrderList){
                
                //Create Transaction Line Item
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Application', trnOrder.Id, null, 'Admission Fee', 'Application', 300, null, null));
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Tuition', trnOrder.Id, null, 'Tuition Fee', 'Tuition', 2500, null, null));
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Residential', trnOrder.Id, null, 'Housing fee', 'Residential', 1000, null, null));
            }

            insert trnLineItemList;

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
        for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, 
                                                                    reduivy__Contact__c, 
                                                                    reduivy__Amount__c 
                                                                    FROM reduivy__Individual_Funding_Allocation__c]){

            fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
        }

        //Create Transction Payment
        List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c, 
                                                    reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Draft');

            trnOrderList.add(trnOrder);
        }
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

        
        System.runAs(ADMIN_USER){
            // Execute test
            Test.startTest();

            for(reduivy__Transaction_Order__c trnOrder: trnOrderList){
                trnOrder.reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0);
            }
            
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
                                                    FROM reduivy__Transaction_Order__c]){
            
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
                                                        FROM reduivy__Transaction_Payment__c]){
            
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
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term). 2 TRP with type 'Payment' is created and left with remaining amount.
     */
    @IsTest
    static void testApplyPaymentWithRemainingForSameTypeAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
        for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, 
                                                                    reduivy__Contact__c, 
                                                                    reduivy__Amount__c 
                                                                    FROM reduivy__Individual_Funding_Allocation__c]){

            fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
        }

        //Create Transction Payment
        List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c, 
                                                    reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 100, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Draft');

            trnOrderList.add(trnOrder);
        }
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

        
        System.runAs(ADMIN_USER){
            // Execute test
            Test.startTest();

            for(reduivy__Transaction_Order__c trnOrder: trnOrderList){
                trnOrder.reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0);
            }
            
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
                                                    FROM reduivy__Transaction_Order__c]){
            
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
                                                        FROM reduivy__Transaction_Payment__c]){
            
            if(conTotalRemainingAmountMap.containsKey(trnPayment.reduivy__Contact__c)){
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, conTotalRemainingAmountMap.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId : conTotalRemainingAmountMap.keySet()){
            System.Assert.areEqual(300, conTotalRemainingAmountMap.get(conId), 'Total remaining amount for transaction payment should be 300');
        }
    }

    /**
     * @description Test the payment application on order for Disburse Non Repayable FA when the checkboxes is checked.
     */
    @IsTest
    static void testDisburseNonRepayableFaAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
        for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, 
                                                                    reduivy__Contact__c, 
                                                                    reduivy__Amount__c 
                                                                    FROM reduivy__Individual_Funding_Allocation__c]){

            fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
        }

        //Create Transction Payment
        List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c, 
                                                    reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Draft');

            trnOrderList.add(trnOrder);
        }
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

        System.runAs(ADMIN_USER){

            // Execute test
            Test.startTest();

            for(reduivy__Transaction_Order__c trnOrder: trnOrderList){
                trnOrder.reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0);
                trnOrder.reduivy__Apply_Payment__c = false;
                trnOrder.reduivy__Apply_Non_Repayable_FA__c = true;
                trnOrder.reduivy__Apply_Repayable_FA__c = false;
            }
            
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
                                                    FROM reduivy__Transaction_Order__c]){
            
            //Check Field Mapping
            System.Assert.areEqual(2300, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be 2300');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(1500, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 1500 for each transaction order');
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
                                                        FROM reduivy__Transaction_Payment__c]){
            
            if(conTotalRemainingAmountMap.containsKey(trnPayment.reduivy__Contact__c)){
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, conTotalRemainingAmountMap.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId : conTotalRemainingAmountMap.keySet()){
            System.Assert.areEqual(2500, conTotalRemainingAmountMap.get(conId), 'Total remaining amount for transaction payment should be 2500');
        }
    }

    /**
     * @description Test the payment application on order for Disburse Non Repayable FA when the checkboxes is checked. 2 TRP with type 'Non Repayable' is created and left with remaining amount.
     */
    @IsTest
    static void testDisburseNonRepayableFaWithRemainingForSameTypeAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
        for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, 
                                                                    reduivy__Contact__c, 
                                                                    reduivy__Amount__c 
                                                                    FROM reduivy__Individual_Funding_Allocation__c]){

            fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
        }

        //Create Transction Payment
        List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c, 
                                                    reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|2600.00').Id, 2600, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Draft');

            trnOrderList.add(trnOrder);
        }
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

        System.runAs(ADMIN_USER){

            // Execute test
            Test.startTest();

            for(reduivy__Transaction_Order__c trnOrder: trnOrderList){
                trnOrder.reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0);
                trnOrder.reduivy__Apply_Payment__c = false;
                trnOrder.reduivy__Apply_Non_Repayable_FA__c = true;
                trnOrder.reduivy__Apply_Repayable_FA__c = false;
            }
            
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
                                                    FROM reduivy__Transaction_Order__c]){
            
            //Check Field Mapping
            System.Assert.areEqual(1300, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be 2300');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(2500, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 1500 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');
        }

        //check for empty amount of fee line
        for( reduivy__Transaction_Line_Item__c trl : [SELECT Id, reduivy__Total_Amount__c FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY]){
            System.Assert.areNotEqual(0, trl.reduivy__Total_Amount__c, 'Transaction Line Item with Total Amount of 0 is created!');
        }
        
        Map<Id, Decimal> conTotalRemainingAmountMap =  new Map<Id, Decimal>();
        for(reduivy__Transaction_Payment__c trnPayment : [SELECT Id, 
                                                        reduivy__Contact__c, 
                                                        reduivy__Amount__c, 
                                                        reduivy__Remaining_Amount__c, 
                                                        reduivy__Applicable_Item_Type__c, 
                                                        reduivy__Transaction_Type__c 
                                                        FROM reduivy__Transaction_Payment__c]){
            
            if(conTotalRemainingAmountMap.containsKey(trnPayment.reduivy__Contact__c)){
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, conTotalRemainingAmountMap.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId : conTotalRemainingAmountMap.keySet()){
            System.Assert.areEqual(3100, conTotalRemainingAmountMap.get(conId), 'Total remaining amount for transaction payment should be 3100');
        }
    }

    /**
     * @description Test the payment application on order for Disburse Repayable FA when the checkboxes is checked.
     */
    @IsTest
    static void testDisburseRepayableFaAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
        for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, 
                                                                    reduivy__Contact__c, 
                                                                    reduivy__Amount__c 
                                                                    FROM reduivy__Individual_Funding_Allocation__c]){

            fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
        }

        //Create Transction Payment
        List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c, 
                                                    reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Draft');

            trnOrderList.add(trnOrder);
        }
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

        System.runAs(ADMIN_USER){

            // Execute test
            Test.startTest();

            for(reduivy__Transaction_Order__c trnOrder: trnOrderList){
                trnOrder.reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0);
                trnOrder.reduivy__Apply_Payment__c = false;
                trnOrder.reduivy__Apply_Non_Repayable_FA__c = false;
                trnOrder.reduivy__Apply_Repayable_FA__c = true;
            }
            
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
                                                    FROM reduivy__Transaction_Order__c]){
            
            //Check Field Mapping
            System.Assert.areEqual(3000, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be 3000');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(800, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 800 for each transaction order');
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
                                                        FROM reduivy__Transaction_Payment__c]){
            
            if(conTotalRemainingAmountMap.containsKey(trnPayment.reduivy__Contact__c)){
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, conTotalRemainingAmountMap.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId : conTotalRemainingAmountMap.keySet()){
            System.Assert.areEqual(3200, conTotalRemainingAmountMap.get(conId), 'Total remaining amount for transaction payment should be 3200');
        }
    }

    /**
     * @description Test the payment application on order for Disburse Repayable FA when the checkboxes is checked. 2 TRP with type 'Repayable' is created and left with remaining amount.
     */
    @IsTest
    static void testDisburseRepayableFaWithRemainingForSameTypeAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
        for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, 
                                                                    reduivy__Contact__c, 
                                                                    reduivy__Amount__c 
                                                                    FROM reduivy__Individual_Funding_Allocation__c]){

            fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
        }

        //Create Transction Payment
        List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c, 
                                                    reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|2600.00').Id, 2600, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|700.00').Id, 700, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Draft');

            trnOrderList.add(trnOrder);
        }
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

        System.runAs(ADMIN_USER){

            // Execute test
            Test.startTest();

            for(reduivy__Transaction_Order__c trnOrder: trnOrderList){
                trnOrder.reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0);
                trnOrder.reduivy__Apply_Payment__c = false;
                trnOrder.reduivy__Apply_Non_Repayable_FA__c = false;
                trnOrder.reduivy__Apply_Repayable_FA__c = true;
            }
            
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
                                                    FROM reduivy__Transaction_Order__c]){
            
            //Check Field Mapping
            System.Assert.areEqual(2800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be 2800');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(1000, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 1000 for each transaction order');
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
                                                        FROM reduivy__Transaction_Payment__c]){
            
            if(conTotalRemainingAmountMap.containsKey(trnPayment.reduivy__Contact__c)){
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, conTotalRemainingAmountMap.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                conTotalRemainingAmountMap.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId : conTotalRemainingAmountMap.keySet()){
            System.Assert.areEqual(5300, conTotalRemainingAmountMap.get(conId), 'Total remaining amount for transaction payment should be 5300');
        }
    }


    /**
     * @description Test the payment application on order without Individual Academic Progress linked to TRO.
     */
    @IsTest
    static void testWithoutIdvAcademicProgressAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
        for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, 
                                                                    reduivy__Contact__c, 
                                                                    reduivy__Amount__c 
                                                                    FROM reduivy__Individual_Funding_Allocation__c]){

            fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
        }

        //Create Transction Payment
        List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c, 
                                                    reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Draft');

            trnOrderList.add(trnOrder);
        }
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

        System.runAs(ADMIN_USER){

            // Execute test
            Test.startTest();

            for(reduivy__Transaction_Order__c trnOrder: trnOrderList){
                trnOrder.reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0);
                trnOrder.reduivy__Individual_Academic_Progress__c = null;
            }
            
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
                                                    FROM reduivy__Transaction_Order__c]){
            
            //Check Field Mapping
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to 0');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 3800 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');
        }
        
        Map<Id, Decimal> conTotalRemainingAmountMap =  new Map<Id, Decimal>();
        for(reduivy__Transaction_Payment__c trnPayment : [SELECT Id, 
                                                        reduivy__Contact__c, 
                                                        reduivy__Amount__c, 
                                                        reduivy__Remaining_Amount__c, 
                                                        reduivy__Applicable_Item_Type__c, 
                                                        reduivy__Transaction_Type__c 
                                                        FROM reduivy__Transaction_Payment__c]){
            
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
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c, 
                                                    reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Draft');

            trnOrderList.add(trnOrder);
        }
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

        System.runAs(studentUser){
            // Execute test
            Test.startTest();

            for(reduivy__Transaction_Order__c trnOrder: trnOrderList){
                trnOrder.reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0);
            }
            
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
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term). 2 TRP with type 'Payment' is created and left with remaining amount.
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
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c, 
                                                    reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 100, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Draft');

            trnOrderList.add(trnOrder);
        }
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

        System.runAs(studentUser){
            // Execute test
            Test.startTest();

            for(reduivy__Transaction_Order__c trnOrder: trnOrderList){
                trnOrder.reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0);
            }
            
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
            System.Assert.areEqual(300, conTotalRemainingAmountMap.get(conId), 'Total remaining amount for transaction payment should be 300');
        }
    }

    /**
     * @description Test the payment application on order for Disburse Non Repayable FA when the checkboxes is checked.
     */
    @IsTest
    static void testDisburseNonRepayableFaAsStudent(){

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
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c, 
                                                    reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Draft');

            trnOrderList.add(trnOrder);
        }
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

        System.runAs(studentUser){
            // Execute test
            Test.startTest();

            for(reduivy__Transaction_Order__c trnOrder: trnOrderList){
                trnOrder.reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0);
                trnOrder.reduivy__Apply_Payment__c = false;
                trnOrder.reduivy__Apply_Non_Repayable_FA__c = true;
                trnOrder.reduivy__Apply_Repayable_FA__c = false;
            }
            
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
            System.Assert.areEqual(2300, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be 2300');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(1500, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 1500 for each transaction order');
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
            System.Assert.areEqual(2500, conTotalRemainingAmountMap.get(conId), 'Total remaining amount for transaction payment should be 2500');
        }
    }

    /**
     * @description Test the payment application on order for Disburse Non Repayable FA when the checkboxes is checked. 2 TRP with type 'Non Repayable' is created and left with remaining amount.
     */
    @IsTest
    static void testDisburseNonRepayableFaWithRemainingForSameTypeAsStudent(){

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
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c, 
                                                    reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|2600.00').Id, 2600, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Draft');

            trnOrderList.add(trnOrder);
        }
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

        System.runAs(studentUser){
            // Execute test
            Test.startTest();

            for(reduivy__Transaction_Order__c trnOrder: trnOrderList){
                trnOrder.reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0);
                trnOrder.reduivy__Apply_Payment__c = false;
                trnOrder.reduivy__Apply_Non_Repayable_FA__c = true;
                trnOrder.reduivy__Apply_Repayable_FA__c = false;
            }
            
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
            System.Assert.areEqual(1300, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be 1300');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(2500, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 2500 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');
        }

        List<reduivy__Transaction_Line_Item__c> trlList = [SELECT Id, reduivy__Transaction_Order__c, reduivy__Contact__c
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
            System.Assert.areEqual(3100, conTotalRemainingAmountMap.get(conId), 'Total remaining amount for transaction payment should be 3100');
        }
    }

/**
     * @description Test the payment application on order for Disburse Non Repayable FA when the checkboxes is checked.
     */
    @IsTest
    static void testDisburseRepayableFaAsStudent(){

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
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c, 
                                                    reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Draft');

            trnOrderList.add(trnOrder);
        }
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

        System.runAs(studentUser){
            // Execute test
            Test.startTest();

            for(reduivy__Transaction_Order__c trnOrder: trnOrderList){
                trnOrder.reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0);
                trnOrder.reduivy__Apply_Payment__c = false;
                trnOrder.reduivy__Apply_Non_Repayable_FA__c = false;
                trnOrder.reduivy__Apply_Repayable_FA__c = true;
            }
            
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
            System.Assert.areEqual(3000, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be 3000');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(800, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 800 for each transaction order');
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
            System.Assert.areEqual(3200, conTotalRemainingAmountMap.get(conId), 'Total remaining amount for transaction payment should be 3200');
        }
    }

    /**
     * @description Test the payment application on order for Disburse Non Repayable FA when the checkboxes is checked. 2 TRP with type 'Repayable' is created and left with remaining amount.
     */
    @IsTest
    static void testDisburseRepayableFaWithRemainingForSameTypeAsStudent(){

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
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c, 
                                                    reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|2600.00').Id, 2600, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|700.00').Id, 700, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Draft');

            trnOrderList.add(trnOrder);
        }
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

        System.runAs(studentUser){
            // Execute test
            Test.startTest();

            for(reduivy__Transaction_Order__c trnOrder: trnOrderList){
                trnOrder.reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0);
                trnOrder.reduivy__Apply_Payment__c = false;
                trnOrder.reduivy__Apply_Non_Repayable_FA__c = false;
                trnOrder.reduivy__Apply_Repayable_FA__c = true;
            }
            
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
            System.Assert.areEqual(2800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be 3000');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(1000, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 800 for each transaction order');
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
            System.Assert.areEqual(5300, conTotalRemainingAmountMap.get(conId), 'Total remaining amount for transaction payment should be 5300');
        }
    }

    /**
     * @description Test the payment application on order without Individual Academic Progress linked to TRO.
     */
    @IsTest
    static void testWithoutIdvAcademicProgressAsStudent(){

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
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Contact__c, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c, 
                                                    reduivy__Individual_Academic_Progress__c, 
                                                    reduivy__Status__c, 
                                                    reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]){
            
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
            trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1300, 0, 'Application;Tuition;Residential'));

            //Check Field Mapping
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Draft');

            trnOrderList.add(trnOrder);
        }
        insert trnPaymentList;

        //No Monetary Entry records are created yet because 'Apply Payment', 'Disburse Non Repayable FA', and 'Disburse Repayable FA' are not checked in the Transaction Order
        List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

        System.runAs(studentUser){
            // Execute test
            Test.startTest();

            for(reduivy__Transaction_Order__c trnOrder: trnOrderList){
                trnOrder.reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0);
                trnOrder.reduivy__Individual_Academic_Progress__c = null;
            }
            
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
     * @description Test the payment application on order with overpayment scenario as admin
     */
    @IsTest
    static void testApplyPaymentWithOverpaymentAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        
        // Get one IPE for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, 
                                                            reduivy__Contact__c 
                                                            FROM reduivy__Individual_Program_Enrollment__c 
                                                            WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() 
                                                            LIMIT 1];

        reduivy__Individual_Academic_Progress__c iprForOtherContact = [SELECT Id, 
            reduivy__Contact__c 
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Contact__c != :masterIPE.reduivy__Contact__c 
            LIMIT 1]; 

        // Clear existing transaction orders for this contact
        List<reduivy__Transaction_Order__c> existingOrders = [SELECT Id, reduivy__Contact__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c
                                                            FROM reduivy__Transaction_Order__c 
                                                            WHERE reduivy__Contact__c = :masterIPE.reduivy__Contact__c];
        if(!existingOrders.isEmpty()){
            for(reduivy__Transaction_Order__c tro: existingOrders) {
                tro.reduivy__Contact__c = iprForOtherContact.reduivy__Contact__c;
                tro.reduivy__Individual_Academic_Progress__c = iprForOtherContact.Id;
                tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_DRAFT;
            }
        }

        update existingOrders;

        // Clear existing individual funding allocations for this contact
        //Instead of deleting the data, we reassign it to another contact to avoid test data conflict issues when running all test methods at once in ISS-002583
        List<reduivy__Individual_Funding_Allocation__c> existingAllocations = [SELECT Id, reduivy__Contact__c
                                                                            FROM reduivy__Individual_Funding_Allocation__c 
                                                                            WHERE reduivy__Contact__c = :masterIPE.reduivy__Contact__c];
        if(!existingAllocations.isEmpty()){
            for(reduivy__Individual_Funding_Allocation__c ifa : existingAllocations) {
                ifa.reduivy__Contact__c = iprForOtherContact.reduivy__Contact__c;
            }
        }

        update existingAllocations;

        // Get Academic Progress for this contact
        reduivy__Individual_Academic_Progress__c termProgress = [SELECT Id 
                                                                FROM reduivy__Individual_Academic_Progress__c 
                                                                WHERE reduivy__Contact__c = :masterIPE.reduivy__Contact__c 
                                                                LIMIT 1];

        // Create new Transaction Order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            masterIPE.reduivy__Contact__c + '|OverpaymentOrder', 
            masterIPE.reduivy__Contact__c, 
            termProgress.Id, 
            Date.today(), 
            TRO_STATUSES_DRAFT.get(0), 
            0, 
            0, 
            0
        );
        transactionOrder.reduivy__Apply_Payment__c = true;
        insert transactionOrder;

        // Create Transaction Line Item with 1000 amount
        reduivy__Transaction_Line_Item__c trnLineItem = REDU_TestData_UTIL.newTransactionOrderLine(
            transactionOrder.reduivy__Sample_Record_Code__c + '|TestFee', 
            transactionOrder.Id, 
            null, 
            'Test Fee', 
            'Tuition', 
            1000, 
            null, 
            null
        );
        insert trnLineItem;

        // Create two Transaction Payments with 1100 each
        List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
        trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment(
            masterIPE.reduivy__Contact__c + '|Payment1', 
            masterIPE.reduivy__Contact__c, 
            transactionOrder.Id, 
            'Payment', 
            null, 
            1100, 
            0, 
            null
        ));
        trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment(
            masterIPE.reduivy__Contact__c + '|Payment2', 
            masterIPE.reduivy__Contact__c, 
            transactionOrder.Id, 
            'Payment', 
            null, 
            1100, 
            0, 
            null
        ));
        insert trnPaymentList;

        // Verify initial state
        transactionOrder = [SELECT Id, 
                        reduivy__Contact__c, 
                        reduivy__Total_Amount__c, 
                        reduivy__Total_Outstanding_Amount__c, 
                        reduivy__Total_Paid_Amount__c, 
                        reduivy__Status__c 
                        FROM reduivy__Transaction_Order__c 
                        WHERE Id = :transactionOrder.Id];

        System.Assert.areEqual(1000, transactionOrder.reduivy__Total_Amount__c, 'Total Amount should be 1000');
        System.Assert.areEqual(1000, transactionOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 1000');
        System.Assert.areEqual(0, transactionOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 initially');
        System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(transactionOrder.reduivy__Status__c), 'Transaction Order status should be in Draft');

        // No Monetary Entry records should exist yet
        List<reduivy__Transaction_Line_Item__c> trlMonetaryEntry = [SELECT Id 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(true, trlMonetaryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

        System.runAs(ADMIN_USER){ 
            // Execute test - Confirm the Transaction Order
            Test.startTest();

            transactionOrder.reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0);
            update transactionOrder;

            Test.stopTest();
        }

        // Verify final state after confirmation
        transactionOrder = [SELECT Id, 
                        reduivy__Contact__c, 
                        reduivy__Total_Amount__c, 
                        reduivy__Total_Outstanding_Amount__c, 
                        reduivy__Total_Paid_Amount__c, 
                        reduivy__Status__c 
                        FROM reduivy__Transaction_Order__c 
                        WHERE Id = :transactionOrder.Id];

        // Assert Transaction Order amounts
        System.Assert.areEqual(1000, transactionOrder.reduivy__Total_Amount__c, 'Total Amount should remain 1000');
        System.Assert.areEqual(-1200, transactionOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be -1200 (overpayment)');
        System.Assert.areEqual(2200, transactionOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 2200');
        System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(transactionOrder.reduivy__Status__c), 'Transaction Order status should be Confirmed');

        // Verify Monetary Entry records are created
        List<reduivy__Transaction_Line_Item__c> monetaryEntries = [SELECT Id, 
                                                                reduivy__Total_Amount__c,
                                                                reduivy__Transaction_Order__c,
                                                                reduivy__Transaction_Payment__c,
                                                                reduivy__Offset_Line_Item__c
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY
                                                                AND reduivy__Transaction_Order__c = :transactionOrder.Id];

        System.Assert.areEqual(3, monetaryEntries.size(), 'Should have 3 monetary entry records created');

        // Verify monetary entries details
        Boolean hasOffsetEntry = false;
        Boolean hasFirstPaymentEntry = false;
        Boolean hasSecondPaymentEntry = false;

        for(reduivy__Transaction_Line_Item__c entry : monetaryEntries){
            System.Assert.areEqual(transactionOrder.Id, entry.reduivy__Transaction_Order__c, 'Monetary entry should be linked to transaction order');
            
            if(entry.reduivy__Total_Amount__c == 1000 && entry.reduivy__Offset_Line_Item__c == trnLineItem.Id){
                hasOffsetEntry = true;
                System.Assert.areNotEqual(null, entry.reduivy__Transaction_Payment__c, 'Offset entry should be linked to a transaction payment');
            }
            else {
                if(entry.reduivy__Total_Amount__c == 100){
                    hasFirstPaymentEntry = true;
                } else if (entry.reduivy__Total_Amount__c == 1100) {
                    hasSecondPaymentEntry = true;
                }
                System.Assert.areNotEqual(null, entry.reduivy__Transaction_Payment__c, 'Overpayment entry should be linked to a transaction payment');
                System.Assert.areEqual(null, entry.reduivy__Offset_Line_Item__c, 'Overpayment entry should not have offset line item');
            }
        }

        System.Assert.areEqual(true, hasOffsetEntry, 'Should have monetary entry with 1000 amount linked to order line item');
        System.Assert.areEqual(true, hasFirstPaymentEntry, 'Should have first overpayment entry with 100 amount');
        System.Assert.areEqual(true, hasSecondPaymentEntry, 'Should have second overpayment entry with 1100 amount');

        // Verify Transaction Payment remaining amounts
        List<reduivy__Transaction_Payment__c> updatedPayments = [SELECT Id, 
                                                                reduivy__Amount__c, 
                                                                reduivy__Remaining_Amount__c 
                                                                FROM reduivy__Transaction_Payment__c 
                                                                WHERE Id IN :trnPaymentList];

        for(reduivy__Transaction_Payment__c payment : updatedPayments){
            System.Assert.areEqual(1100, payment.reduivy__Amount__c, 'Payment amount should remain 1100');
            System.Assert.areEqual(0, payment.reduivy__Remaining_Amount__c, 'Payment should have 0 remaining amount');
        }

        // Check that no monetary entries with 0 amount were created
        List<reduivy__Transaction_Line_Item__c> zeroAmountEntries = [SELECT Id 
                                                                    FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY 
                                                                    AND reduivy__Total_Amount__c = 0];
        
        System.Assert.areEqual(0, zeroAmountEntries.size(), 'Transaction Line Item with total amount of 0 should not be created!');
    }

    /**
     * @description Test the payment application on order with overpayment scenario as student
     */
    @IsTest
    static void testApplyPaymentWithOverpaymentAsStudent(){        
        
        // Get one IPE for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, 
                                                            reduivy__Contact__c 
                                                            FROM reduivy__Individual_Program_Enrollment__c 
                                                            WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() 
                                                            LIMIT 1];

        User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ContactId = : masterIPE.reduivy__Contact__c];

        reduivy__Individual_Academic_Progress__c iprForOtherContact = [SELECT Id, 
            reduivy__Contact__c 
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Contact__c != :masterIPE.reduivy__Contact__c 
            LIMIT 1];

        // Clear existing transaction orders for this contact
        //Instead of deleting the data, we reassign it to another contact to avoid test data conflict issues when running all test methods at once in ISS-002583
        List<reduivy__Transaction_Order__c> existingOrders = [SELECT Id, reduivy__Contact__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c
                                                            FROM reduivy__Transaction_Order__c 
                                                            WHERE reduivy__Contact__c = :masterIPE.reduivy__Contact__c];
        if(!existingOrders.isEmpty()){
            for(reduivy__Transaction_Order__c tro: existingOrders) {
                tro.reduivy__Contact__c = iprForOtherContact.reduivy__Contact__c;
                tro.reduivy__Individual_Academic_Progress__c = iprForOtherContact.Id;
                tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_DRAFT;
            }
        }

        update existingOrders;

        // Clear existing individual funding allocations for this contact
        List<reduivy__Individual_Funding_Allocation__c> existingAllocations = [SELECT Id, reduivy__Contact__c
                                                                            FROM reduivy__Individual_Funding_Allocation__c 
                                                                            WHERE reduivy__Contact__c = :masterIPE.reduivy__Contact__c];
        if(!existingAllocations.isEmpty()){
            for(reduivy__Individual_Funding_Allocation__c ifa : existingAllocations) {
                ifa.reduivy__Contact__c = iprForOtherContact.reduivy__Contact__c;
            }
        }

        update existingAllocations;

        // Get Academic Progress for this contact
        reduivy__Individual_Academic_Progress__c termProgress = [SELECT Id 
                                                                FROM reduivy__Individual_Academic_Progress__c 
                                                                WHERE reduivy__Contact__c = :masterIPE.reduivy__Contact__c 
                                                                LIMIT 1];

        // Create new Transaction Order
        reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(
            masterIPE.reduivy__Contact__c + '|OverpaymentOrder', 
            masterIPE.reduivy__Contact__c, 
            termProgress.Id, 
            Date.today(), 
            TRO_STATUSES_DRAFT.get(0), 
            0, 
            0, 
            0
        );
        transactionOrder.reduivy__Apply_Payment__c = true;
        insert transactionOrder;

        // Create Transaction Line Item with 1000 amount
        reduivy__Transaction_Line_Item__c trnLineItem = REDU_TestData_UTIL.newTransactionOrderLine(
            transactionOrder.reduivy__Sample_Record_Code__c + '|TestFee', 
            transactionOrder.Id, 
            null, 
            'Test Fee', 
            'Tuition', 
            1000, 
            null, 
            null
        );
        insert trnLineItem;

        // Create two Transaction Payments with 1100 each
        List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
        trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment(
            masterIPE.reduivy__Contact__c + '|Payment1', 
            masterIPE.reduivy__Contact__c, 
            transactionOrder.Id, 
            'Payment', 
            null, 
            1100, 
            0, 
            null
        ));
        trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment(
            masterIPE.reduivy__Contact__c + '|Payment2', 
            masterIPE.reduivy__Contact__c, 
            transactionOrder.Id, 
            'Payment', 
            null, 
            1100, 
            0, 
            null
        ));
        insert trnPaymentList;

        // Verify initial state
        transactionOrder = [SELECT Id, 
                        reduivy__Contact__c, 
                        reduivy__Total_Amount__c, 
                        reduivy__Total_Outstanding_Amount__c, 
                        reduivy__Total_Paid_Amount__c, 
                        reduivy__Status__c 
                        FROM reduivy__Transaction_Order__c 
                        WHERE Id = :transactionOrder.Id];

        System.Assert.areEqual(1000, transactionOrder.reduivy__Total_Amount__c, 'Total Amount should be 1000');
        System.Assert.areEqual(1000, transactionOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 1000');
        System.Assert.areEqual(0, transactionOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 initially');
        System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(transactionOrder.reduivy__Status__c), 'Transaction Order status should be in Draft');

        // No Monetary Entry records should exist yet
        List<reduivy__Transaction_Line_Item__c> trlMonetaryEntry = [SELECT Id 
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
        System.Assert.areEqual(true, trlMonetaryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

        System.runAs(studentUser){ 
            // Execute test - Confirm the Transaction Order
            Test.startTest();

            transactionOrder.reduivy__Status__c = TRO_STATUSES_CONFIRMED.get(0);
            update transactionOrder;

            Test.stopTest();
        }

        // Verify final state after confirmation
        transactionOrder = [SELECT Id, 
                        reduivy__Contact__c, 
                        reduivy__Total_Amount__c, 
                        reduivy__Total_Outstanding_Amount__c, 
                        reduivy__Total_Paid_Amount__c, 
                        reduivy__Status__c 
                        FROM reduivy__Transaction_Order__c 
                        WHERE Id = :transactionOrder.Id];

        // Assert Transaction Order amounts
        System.Assert.areEqual(1000, transactionOrder.reduivy__Total_Amount__c, 'Total Amount should remain 1000');
        System.Assert.areEqual(-1200, transactionOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be -1200 (overpayment)');
        System.Assert.areEqual(2200, transactionOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 2200');
        System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(transactionOrder.reduivy__Status__c), 'Transaction Order status should be Confirmed');

        // Verify Monetary Entry records are created
        List<reduivy__Transaction_Line_Item__c> monetaryEntries = [SELECT Id, 
                                                                reduivy__Total_Amount__c,
                                                                reduivy__Transaction_Order__c,
                                                                reduivy__Transaction_Payment__c,
                                                                reduivy__Offset_Line_Item__c
                                                                FROM reduivy__Transaction_Line_Item__c 
                                                                WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY
                                                                AND reduivy__Transaction_Order__c = :transactionOrder.Id];

        System.Assert.areEqual(3, monetaryEntries.size(), 'Should have 3 monetary entry records created');

        // Verify monetary entries details
        Boolean hasOffsetEntry = false;
        Boolean hasFirstPaymentEntry = false;
        Boolean hasSecondPaymentEntry = false;

        for(reduivy__Transaction_Line_Item__c entry : monetaryEntries){
            System.Assert.areEqual(transactionOrder.Id, entry.reduivy__Transaction_Order__c, 'Monetary entry should be linked to transaction order');
            
            if(entry.reduivy__Total_Amount__c == 1000 && entry.reduivy__Offset_Line_Item__c == trnLineItem.Id){
                hasOffsetEntry = true;
                System.Assert.areNotEqual(null, entry.reduivy__Transaction_Payment__c, 'Offset entry should be linked to a transaction payment');
            }
            else {
                if(entry.reduivy__Total_Amount__c == 100){
                    hasFirstPaymentEntry = true;
                } else if (entry.reduivy__Total_Amount__c == 1100) {
                    hasSecondPaymentEntry = true;
                }
                System.Assert.areNotEqual(null, entry.reduivy__Transaction_Payment__c, 'Overpayment entry should be linked to a transaction payment');
                System.Assert.areEqual(null, entry.reduivy__Offset_Line_Item__c, 'Overpayment entry should not have offset line item');
            }
        }

        System.Assert.areEqual(true, hasOffsetEntry, 'Should have monetary entry with 1000 amount linked to order line item');
        System.Assert.areEqual(true, hasFirstPaymentEntry, 'Should have first overpayment entry with 100 amount');
        System.Assert.areEqual(true, hasSecondPaymentEntry, 'Should have second overpayment entry with 1100 amount');

        // Verify Transaction Payment remaining amounts
        List<reduivy__Transaction_Payment__c> updatedPayments = [SELECT Id, 
                                                                reduivy__Amount__c, 
                                                                reduivy__Remaining_Amount__c 
                                                                FROM reduivy__Transaction_Payment__c 
                                                                WHERE Id IN :trnPaymentList];

        for(reduivy__Transaction_Payment__c payment : updatedPayments){
            System.Assert.areEqual(1100, payment.reduivy__Amount__c, 'Payment amount should remain 1100');
            System.Assert.areEqual(0, payment.reduivy__Remaining_Amount__c, 'Payment should have 0 remaining amount');
        }

        // Check that no monetary entries with 0 amount were created
        List<reduivy__Transaction_Line_Item__c> zeroAmountEntries = [SELECT Id 
                                                                    FROM reduivy__Transaction_Line_Item__c 
                                                                    WHERE reduivy__Transaction_Type__c = :TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY 
                                                                    AND reduivy__Total_Amount__c = 0];
        
        System.Assert.areEqual(0, zeroAmountEntries.size(), 'Transaction Line Item with total amount of 0 should not be created!');
    }
}