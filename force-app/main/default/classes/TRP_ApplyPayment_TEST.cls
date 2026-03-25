/**
 * @author      WDCi (VTan)
 * @date        Mar 2024
 * @group       Finance
 * @description Test class for TRP_ApplyPayment_EXE
 * @changehistory
 * ISS-001866 26-02-2024 VTan - New class
 * ISS-002288 19-02-2025 XW - added test for 2 transaction payment with same type and remaining
 */
@IsTest
public inherited sharing class TRP_ApplyPayment_TEST{
    
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
            reduivy__Study_Term__c currentTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Sample_Record_Code__c = : testFactory.CYTKey LIMIT 1];
            List<reduivy__Individual_Academic_Progress__c> termProgressList = new List<reduivy__Individual_Academic_Progress__c>();

            for (reduivy__Individual_Academic_Progress__c termProgress : [SELECT Id, Name,
                reduivy__Sample_Record_Code__c,
                reduivy__Contact__c,
                reduivy__Academic_Term__c,
                reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Academic_Progress__c
                WHERE reduivy__Academic_Term__c =: currentTerm.Id
            ]) {
                termProgressList.add(termProgress);
            }

            //Create Study Funding
            List<reduivy__Study_Funding__c> studyFunding = new List<reduivy__Study_Funding__c>();
            studyFunding.add(REDU_TestData_UTIL.newStudyFunding('ACME Scholarship', 'ACME Scholarship', SCHOLARSHIP, 5000000, 1, 0, 0, SFD_Helper.STATUS_ACTIVE));
            studyFunding.add(REDU_TestData_UTIL.newStudyFunding('ACME Grant', 'ACME Grant', GRANT, 5000000, 2, 0, 0, SFD_Helper.STATUS_ACTIVE));
            studyFunding.add(REDU_TestData_UTIL.newStudyFunding('ACME Scholarship Rich', 'ACME Scholarship', SCHOLARSHIP, 5000000, 1, 0, 0, SFD_Helper.STATUS_ACTIVE));
            studyFunding.add(REDU_TestData_UTIL.newStudyFunding('Federal Loan', 'Federal Loan', FEDERALLOAN, 5000000, 2, 0, 0, SFD_Helper.STATUS_ACTIVE));
            studyFunding.add(REDU_TestData_UTIL.newStudyFunding('Federal Loan 2', 'Federal Loan 2', FEDERALLOAN, 5000000, 2, 0, 0, SFD_Helper.STATUS_ACTIVE));
            insert studyFunding;

            //Create Transaction Order && Funding Allocation
            List<reduivy__Transaction_Order__c> transactionOrderList = new List<reduivy__Transaction_Order__c>();
            List<reduivy__Transaction_Order__c> confirmedTransactionOrderList = new List<reduivy__Transaction_Order__c>();
            List<reduivy__Individual_Funding_Allocation__c> idvFundingAllocationList = new List<reduivy__Individual_Funding_Allocation__c>();
            for(reduivy__Individual_Academic_Progress__c termProgress : termProgressList){

                reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(termProgress.reduivy__Sample_Record_Code__c + '|Order', termProgress.reduivy__Contact__c, termProgress.Id, todayDate, TRO_STATUSES_DRAFT.get(0), 0, 0, 0);
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

            List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
            for(reduivy__Transaction_Order__c trnOrder : transactionOrderList){
                
                confirmedTransactionOrderList.add(new reduivy__Transaction_Order__c(Id = trnOrder.Id, reduivy__Status__c = TRO_STATUSES_CONFIRMED[0]));

                //Create Transaction Line Item
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Application', trnOrder.Id, null, 'Admission Fee', 'Application', 300, null, null));
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Tuition', trnOrder.Id, null, 'Tuition Fee', 'Tuition', 2500, null, null));
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrder.reduivy__Sample_Record_Code__c + '|Residential', trnOrder.Id, null, 'Housing fee', 'Residential', 1000, null, null));
            }

            insert trnLineItemList;
            update confirmedTransactionOrderList;

            Test.stopTest();
        }
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testApplyPaymentInsertAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, reduivy__Contact__c, reduivy__Sample_Record_Code__c, reduivy__Apply_Payment__c, reduivy__Apply_Non_Repayable_FA__c, reduivy__Apply_Repayable_FA__c FROM reduivy__Transaction_Order__c]);

        Map<Id, reduivy__Transaction_Order__c> trnOrderDepositMap = new Map<Id, reduivy__Transaction_Order__c>();
        for(Id trnOrderId : trnOrderMap.keySet()){

            reduivy__Transaction_Order__c trnOrderDeposit = REDU_TestData_UTIL.newTransactionOrder(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Deposit', trnOrderMap.get(trnOrderId).reduivy__Contact__c, null, date.today(), TRO_STATUSES_DRAFT.get(0), 0, 0, 0);
            trnOrderDeposit.reduivy__Apply_Payment__c = true;
            trnOrderDepositMap.put(trnOrderMap.get(trnOrderId).reduivy__Contact__c, trnOrderDeposit);
        }

        System.runAs(ADMIN_USER){
            insert trnOrderDepositMap.values();

            List<reduivy__Transaction_Line_Item__c> trnLineItemDepositList = new List<reduivy__Transaction_Line_Item__c>();
            for(Id conId: trnOrderDepositMap.keySet()){
                trnLineItemDepositList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrderDepositMap.get(conId).reduivy__Sample_Record_Code__c, trnOrderDepositMap.get(conId).Id, null, 'Deposit', 'Deposit', 200, null, null));

            }
            insert trnLineItemDepositList;

            Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
            for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, reduivy__Contact__c, reduivy__Amount__c FROM reduivy__Individual_Funding_Allocation__c]){

                fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
            }

            //Create Transction Payment
            List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
            List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
            for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c, reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c WHERE Id IN: trnOrderMap.keySet()]){
                
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1000, 0, 'Application;Tuition;Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, trnOrderDepositMap.get(trnOrder.reduivy__Contact__c).Id, 'Payment', null, 300, 0, 'Deposit'));

                //Check Field Mapping
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
                System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
                System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrderDepositMap.get(trnOrder.reduivy__Contact__c).reduivy__Status__c), 'Transaction Order status for the Deposit transaction should be in Draft');
                System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status for the Deposit transaction should be in Draft');

                trnOrderList.add(trnOrder);
            }

            //No Monetary Entry records are created yet because no transaction payment records are created yet.
            List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
            System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

            
            // Execute test
            Test.startTest();

            insert trnPaymentList;

            Test.stopTest();
        }

        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c FROM reduivy__Transaction_Order__c WHERE Id IN: trnOrderMap.keySet()]){

            System.Assert.areEqual(0, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to 0');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 3800 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');
        }

        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Apply_Payment__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Status__c FROM reduivy__Transaction_Order__c WHERE reduivy__Individual_Academic_Progress__c = null]){

            System.Assert.areEqual(-100, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to -100 due to overpaid');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status for deposit should be updated to Confirmed');
        }

        //check for empty amount of fee line
        List<reduivy__Transaction_Line_Item__c> trlList = [SELECT Id 
            FROM reduivy__Transaction_Line_Item__c 
            WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY 
            AND reduivy__Total_Amount__c = 0];
        
        System.Assert.areEqual(0, trlList.size(), 'Transaction Line Item with total amount of 0 should not be created!');

        Map<Id, Decimal> totalRemainingAmountCheck = new Map<Id, Decimal>();
        for(reduivy__Transaction_Payment__c trnPayment : [SELECT Id, reduivy__Contact__c, reduivy__Amount__c, reduivy__Remaining_Amount__c, reduivy__Applicable_Item_Type__c, reduivy__Transaction_Type__c FROM reduivy__Transaction_Payment__c]){
            if(totalRemainingAmountCheck.containsKey(trnPayment.reduivy__Contact__c)){
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, totalRemainingAmountCheck.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId: totalRemainingAmountCheck.keySet()){
            System.Assert.areEqual(100, totalRemainingAmountCheck.get(conId), 'Total remaining amount for transaction payments should be 100');
        }
    }

    /**
     * @description Test the payment when a transaction payment is applied to a transaction order. the tro apply payment is false. 
     */
    @IsTest
    static void testApplyPaymentInsertAsAdminTroNoApplyPayment(){

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, 
            reduivy__Contact__c 
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        User ADMIN_USER = testFactory.getReduAdminUser();

        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Sample_Record_Code__c, 
            reduivy__Apply_Payment__c, 
            reduivy__Apply_Non_Repayable_FA__c, 
            reduivy__Apply_Repayable_FA__c 
            FROM reduivy__Transaction_Order__c
            WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]);

        for(reduivy__Transaction_Order__c tro : trnOrderMap.values()){
            tro.reduivy__Apply_Payment__c = false;
        }

        update trnOrderMap.values();

        System.runAs(ADMIN_USER){


            Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
            for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, 
                reduivy__Contact__c, 
                reduivy__Amount__c 
                FROM reduivy__Individual_Funding_Allocation__c
                WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c
            ]){

                fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
            }

            //Create Transction Payment
            List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
            
            List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
            for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c, reduivy__Sample_Record_Code__c 
                FROM reduivy__Transaction_Order__c WHERE Id IN: trnOrderMap.keySet()
            ]){
                
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, trnOrder.Id, 'Payment', null, 3800, 0, null));

                //Check Field Mapping
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
                System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
                System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status for the Deposit transaction should be in Draft');

                trnOrderList.add(trnOrder);
            }

            //No Monetary Entry records are created yet because no transaction payment records are created yet.
            List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
            System.debug('trlMonetoryEntry ::');
            System.debug(trlMonetoryEntry);
            System.debug('trnPaymentList ::');
            System.debug(trnPaymentList);
            System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

            // Execute test
            Test.startTest();

            insert trnPaymentList;

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
            WHERE Id IN: trnOrderMap.keySet()
        ]){

            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be 3880');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');
        }

        //check for empty amount of fee line
        List<reduivy__Transaction_Line_Item__c> trlList = [SELECT Id 
            FROM reduivy__Transaction_Line_Item__c 
            WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY 
            AND reduivy__Total_Amount__c = 0];
        
        System.Assert.areEqual(0, trlList.size(), 'Transaction Line Item with total amount of 0 should not be created!');

        Map<Id, Decimal> totalRemainingAmountCheck = new Map<Id, Decimal>();
        for(reduivy__Transaction_Payment__c trnPayment : [SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Amount__c, 
            reduivy__Remaining_Amount__c, 
            reduivy__Applicable_Item_Type__c, 
            reduivy__Transaction_Type__c 
            FROM reduivy__Transaction_Payment__c
            WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c
        ]){
            if(totalRemainingAmountCheck.containsKey(trnPayment.reduivy__Contact__c)){
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, totalRemainingAmountCheck.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId: totalRemainingAmountCheck.keySet()){
            System.Assert.areEqual(3800, totalRemainingAmountCheck.get(conId), 'Total remaining amount for transaction payments should be 3800');
        }
    }


    /**
     * @description Test the payment when a transaction payment is applied to a transaction order. the tro apply payment is true. 
     */
    @IsTest
    static void testApplyPaymentInsertAsAdminTroHasApplyPayment(){

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, 
            reduivy__Contact__c 
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        User ADMIN_USER = testFactory.getReduAdminUser();

        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Sample_Record_Code__c, 
            reduivy__Apply_Payment__c, 
            reduivy__Apply_Non_Repayable_FA__c, 
            reduivy__Apply_Repayable_FA__c 
            FROM reduivy__Transaction_Order__c
            WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]);

        System.runAs(ADMIN_USER){

            Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
            for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, 
                reduivy__Contact__c, 
                reduivy__Amount__c 
                FROM reduivy__Individual_Funding_Allocation__c
                WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c
            ]){

                fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
            }

            //Create Transction Payment
            List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
            
            List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
            for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c, reduivy__Sample_Record_Code__c 
                FROM reduivy__Transaction_Order__c WHERE Id IN: trnOrderMap.keySet()
            ]){
                
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, trnOrder.Id, 'Payment', null, 3800, 0, null));

                //Check Field Mapping
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
                System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
                System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status for the Deposit transaction should be in Draft');

                trnOrderList.add(trnOrder);
            }

            //No Monetary Entry records are created yet because no transaction payment records are created yet.
            List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
            System.debug('trlMonetoryEntry ::');
            System.debug(trlMonetoryEntry);
            System.debug('trnPaymentList ::');
            System.debug(trnPaymentList);
            System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

            // Execute test
            Test.startTest();

            insert trnPaymentList;

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
            WHERE Id IN: trnOrderMap.keySet()
        ]){

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

        Map<Id, Decimal> totalRemainingAmountCheck = new Map<Id, Decimal>();
        for(reduivy__Transaction_Payment__c trnPayment : [SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Amount__c, 
            reduivy__Remaining_Amount__c, 
            reduivy__Applicable_Item_Type__c, 
            reduivy__Transaction_Type__c 
            FROM reduivy__Transaction_Payment__c
            WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c
        ]){
            if(totalRemainingAmountCheck.containsKey(trnPayment.reduivy__Contact__c)){
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, totalRemainingAmountCheck.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId: totalRemainingAmountCheck.keySet()){
            System.Assert.areEqual(0, totalRemainingAmountCheck.get(conId), 'Total remaining amount for transaction payments should be 0');
        }
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testApplyPaymentWithRemainingForSameTypeInsertAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, reduivy__Contact__c, reduivy__Sample_Record_Code__c, reduivy__Apply_Payment__c, reduivy__Apply_Non_Repayable_FA__c, reduivy__Apply_Repayable_FA__c FROM reduivy__Transaction_Order__c]);

        Map<Id, reduivy__Transaction_Order__c> trnOrderDepositMap = new Map<Id, reduivy__Transaction_Order__c>();
        for(Id trnOrderId : trnOrderMap.keySet()){

            reduivy__Transaction_Order__c trnOrderDeposit = REDU_TestData_UTIL.newTransactionOrder(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Deposit', trnOrderMap.get(trnOrderId).reduivy__Contact__c, null, date.today(), TRO_STATUSES_DRAFT.get(0), 0, 0, 0);
            trnOrderDeposit.reduivy__Apply_Payment__c = true;
            trnOrderDepositMap.put(trnOrderMap.get(trnOrderId).reduivy__Contact__c, trnOrderDeposit);
        }

        System.runAs(ADMIN_USER){
            insert trnOrderDepositMap.values();

            List<reduivy__Transaction_Line_Item__c> trnLineItemDepositList = new List<reduivy__Transaction_Line_Item__c>();
            for(Id conId: trnOrderDepositMap.keySet()){
                trnLineItemDepositList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrderDepositMap.get(conId).reduivy__Sample_Record_Code__c, trnOrderDepositMap.get(conId).Id, null, 'Deposit', 'Deposit', 200, null, null));

            }
            insert trnLineItemDepositList;

            Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
            for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, reduivy__Contact__c, reduivy__Amount__c FROM reduivy__Individual_Funding_Allocation__c]){

                fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
            }

            //Create Transction Payment
            List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
            List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
            for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c, reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c WHERE Id IN: trnOrderMap.keySet()]){
                
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1000, 0, 'Application;Tuition;Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 100, 0, 'Application;Tuition;Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, trnOrderDepositMap.get(trnOrder.reduivy__Contact__c).Id, 'Payment', null, 300, 0, 'Deposit'));

                //Check Field Mapping
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
                System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
                System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrderDepositMap.get(trnOrder.reduivy__Contact__c).reduivy__Status__c), 'Transaction Order status for the Deposit transaction should be in Draft');
                System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status for the Deposit transaction should be in Draft');

                trnOrderList.add(trnOrder);
            }

            //No Monetary Entry records are created yet because no transaction payment records are created yet.
            List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
            System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

            
            // Execute test
            Test.startTest();

            insert trnPaymentList;

            Test.stopTest();
        }

        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c FROM reduivy__Transaction_Order__c WHERE Id IN: trnOrderMap.keySet()]){

            System.Assert.areEqual(0, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to 0');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 3800 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');
        }

        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Apply_Payment__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Status__c FROM reduivy__Transaction_Order__c WHERE reduivy__Individual_Academic_Progress__c = null]){

            System.Assert.areEqual(-100, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to -100 due to overpaid');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status for deposit should be updated to Confirmed');
        }

        //check for empty amount of fee line
        List<reduivy__Transaction_Line_Item__c> trlList = [SELECT Id 
            FROM reduivy__Transaction_Line_Item__c 
            WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY 
            AND reduivy__Total_Amount__c = 0];
        
        System.Assert.areEqual(0, trlList.size(), 'Transaction Line Item with total amount of 0 should not be created!');

        Map<Id, Decimal> totalRemainingAmountCheck = new Map<Id, Decimal>();
        for(reduivy__Transaction_Payment__c trnPayment : [SELECT Id, reduivy__Contact__c, reduivy__Amount__c, reduivy__Remaining_Amount__c, reduivy__Applicable_Item_Type__c, reduivy__Transaction_Type__c FROM reduivy__Transaction_Payment__c]){
            if(totalRemainingAmountCheck.containsKey(trnPayment.reduivy__Contact__c)){
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, totalRemainingAmountCheck.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId: totalRemainingAmountCheck.keySet()){
            System.Assert.areEqual(200, totalRemainingAmountCheck.get(conId), 'Total remaining amount for transaction payments should be 200');
        }
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testApplyPaymentUpdateAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, reduivy__Contact__c, reduivy__Sample_Record_Code__c, reduivy__Apply_Payment__c, reduivy__Apply_Non_Repayable_FA__c, reduivy__Apply_Repayable_FA__c FROM reduivy__Transaction_Order__c]);

        Map<Id, reduivy__Transaction_Order__c> trnOrderDepositMap = new Map<Id, reduivy__Transaction_Order__c>();
        for(Id trnOrderId : trnOrderMap.keySet()){

            reduivy__Transaction_Order__c trnOrderDeposit = REDU_TestData_UTIL.newTransactionOrder(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Deposit', trnOrderMap.get(trnOrderId).reduivy__Contact__c, null, date.today(), TRO_STATUSES_DRAFT.get(0), 0, 0, 0);
            trnOrderDeposit.reduivy__Apply_Payment__c = true;
            trnOrderDepositMap.put(trnOrderMap.get(trnOrderId).reduivy__Contact__c, trnOrderDeposit);
        }

        insert trnOrderDepositMap.values();

        List<reduivy__Transaction_Line_Item__c> trnLineItemDepositList = new List<reduivy__Transaction_Line_Item__c>();
        for(Id conId: trnOrderDepositMap.keySet()){
            trnLineItemDepositList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrderDepositMap.get(conId).reduivy__Sample_Record_Code__c, trnOrderDepositMap.get(conId).Id, null, 'Deposit', 'Deposit', 200, null, null));

        }

        System.runAs(ADMIN_USER){

            insert trnLineItemDepositList;

            Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
            for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, reduivy__Contact__c, reduivy__Amount__c FROM reduivy__Individual_Funding_Allocation__c]){

                fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
            }

            //Create Transction Payment
            List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
            List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
            for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c, reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c WHERE Id IN: trnOrderMap.keySet()]){
                
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1000, 0, 'Application;Tuition;Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, trnOrderDepositMap.get(trnOrder.reduivy__Contact__c).Id, 'Payment', null, 300, 0, 'Deposit'));

                //Check Field Mapping
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
                System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
                System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrderDepositMap.get(trnOrder.reduivy__Contact__c).reduivy__Status__c), 'Transaction Order status for the Deposit transaction should be in Draft');
                System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status for the Deposit transaction should be in Draft');

                trnOrderList.add(trnOrder);
            }

            for(reduivy__Transaction_Payment__c trnPayment : trnPaymentList){
                trnPayment.reduivy__Status__c = TRP_Helper.STATUS_DRAFT;
            }

            insert trnPaymentList;

            //No Monetary Entry records are created yet because no transaction payment records are created yet.
            List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
            System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

            for(reduivy__Transaction_Payment__c trnPayment : trnPaymentList){
                trnPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
            }

            
            // Execute test
            Test.startTest();
            
            update trnPaymentList;

            Test.stopTest();
        }

        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c FROM reduivy__Transaction_Order__c WHERE Id IN: trnOrderMap.keySet()]){

            System.Assert.areEqual(0, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to 0');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 3800 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');
        }

        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Apply_Payment__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Status__c FROM reduivy__Transaction_Order__c WHERE reduivy__Individual_Academic_Progress__c = null]){
            System.Assert.areEqual(-100, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to -100 due to overpaid');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status for deposit should be updated to Confirmed');
        }

        //check for empty amount of fee line
        List<reduivy__Transaction_Line_Item__c> trlList = [SELECT Id 
            FROM reduivy__Transaction_Line_Item__c 
            WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY 
            AND reduivy__Total_Amount__c = 0];
        
        System.Assert.areEqual(0, trlList.size(), 'Transaction Line Item with total amount of 0 should not be created!');

        Map<Id, Decimal> totalRemainingAmountCheck = new Map<Id, Decimal>();
        for(reduivy__Transaction_Payment__c trnPayment : [SELECT Id, reduivy__Contact__c, reduivy__Amount__c, reduivy__Remaining_Amount__c, reduivy__Applicable_Item_Type__c, reduivy__Transaction_Type__c FROM reduivy__Transaction_Payment__c]){
            if(totalRemainingAmountCheck.containsKey(trnPayment.reduivy__Contact__c)){
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, totalRemainingAmountCheck.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId: totalRemainingAmountCheck.keySet()){
            System.Assert.areEqual(100, totalRemainingAmountCheck.get(conId), 'Total remaining amount for transaction payments should be 100');
        }
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term). 2 TRP with type 'Payment' is created and left with remaining amount.
     */
    @IsTest
    static void testApplyPaymentWithRemaningForSameTypeUpdateAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, reduivy__Contact__c, reduivy__Sample_Record_Code__c, reduivy__Apply_Payment__c, reduivy__Apply_Non_Repayable_FA__c, reduivy__Apply_Repayable_FA__c FROM reduivy__Transaction_Order__c]);

        Map<Id, reduivy__Transaction_Order__c> trnOrderDepositMap = new Map<Id, reduivy__Transaction_Order__c>();
        for(Id trnOrderId : trnOrderMap.keySet()){

            reduivy__Transaction_Order__c trnOrderDeposit = REDU_TestData_UTIL.newTransactionOrder(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Deposit', trnOrderMap.get(trnOrderId).reduivy__Contact__c, null, date.today(), TRO_STATUSES_DRAFT.get(0), 0, 0, 0);
            trnOrderDeposit.reduivy__Apply_Payment__c = true;
            trnOrderDepositMap.put(trnOrderMap.get(trnOrderId).reduivy__Contact__c, trnOrderDeposit);
        }

        insert trnOrderDepositMap.values();

        List<reduivy__Transaction_Line_Item__c> trnLineItemDepositList = new List<reduivy__Transaction_Line_Item__c>();
        for(Id conId: trnOrderDepositMap.keySet()){
            trnLineItemDepositList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrderDepositMap.get(conId).reduivy__Sample_Record_Code__c, trnOrderDepositMap.get(conId).Id, null, 'Deposit', 'Deposit', 200, null, null));

        }

        System.runAs(ADMIN_USER){

            insert trnLineItemDepositList;

            Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
            for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, reduivy__Contact__c, reduivy__Amount__c FROM reduivy__Individual_Funding_Allocation__c]){

                fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
            }

            //Create Transction Payment
            List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
            List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
            for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c, reduivy__Sample_Record_Code__c 
                                                    FROM reduivy__Transaction_Order__c WHERE Id IN: trnOrderMap.keySet()]){
                
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1000, 0, 'Application;Tuition;Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, trnOrderDepositMap.get(trnOrder.reduivy__Contact__c).Id, 'Payment', null, 300, 0, 'Deposit'));

                //Check Field Mapping
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
                System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
                System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrderDepositMap.get(trnOrder.reduivy__Contact__c).reduivy__Status__c), 'Transaction Order status for the Deposit transaction should be in Draft');
                System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status for the Deposit transaction should be in Draft');

                trnOrderList.add(trnOrder);
            }

            for(reduivy__Transaction_Payment__c trnPayment : trnPaymentList){
                trnPayment.reduivy__Status__c = TRP_Helper.STATUS_DRAFT;
            }

            insert trnPaymentList;

            //No Monetary Entry records are created yet because no transaction payment records are created yet.
            List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
            System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

            for(reduivy__Transaction_Payment__c trnPayment : trnPaymentList){
                trnPayment.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
            }

            
            // Execute test
            Test.startTest();
            
            update trnPaymentList;

            Test.stopTest();
        }

        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c FROM reduivy__Transaction_Order__c WHERE Id IN: trnOrderMap.keySet()]){

            System.Assert.areEqual(0, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to 0');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 3800 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');
        }

        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Apply_Payment__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Status__c FROM reduivy__Transaction_Order__c WHERE reduivy__Individual_Academic_Progress__c = null]){
            System.Assert.areEqual(-100, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to -100 due to overpaid');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status for deposit should be updated to Confirmed');
        }

        //check for empty amount of fee line
        List<reduivy__Transaction_Line_Item__c> trlList = [SELECT Id 
            FROM reduivy__Transaction_Line_Item__c 
            WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY 
            AND reduivy__Total_Amount__c = 0];
        
        System.Assert.areEqual(0, trlList.size(), 'Transaction Line Item with total amount of 0 should not be created!');

        Map<Id, Decimal> totalRemainingAmountCheck = new Map<Id, Decimal>();
        for(reduivy__Transaction_Payment__c trnPayment : [SELECT Id, reduivy__Contact__c, reduivy__Amount__c, reduivy__Remaining_Amount__c, reduivy__Applicable_Item_Type__c, reduivy__Transaction_Type__c FROM reduivy__Transaction_Payment__c]){
            if(totalRemainingAmountCheck.containsKey(trnPayment.reduivy__Contact__c)){
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, totalRemainingAmountCheck.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId: totalRemainingAmountCheck.keySet()){
            System.Assert.areEqual(100, totalRemainingAmountCheck.get(conId), 'Total remaining amount for transaction payments should be 100');
        }
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testApplyPaymentInsertAsStudent(){

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, 
            reduivy__Contact__c 
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ContactId = : masterIPE.reduivy__Contact__c];

        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Sample_Record_Code__c, 
            reduivy__Apply_Payment__c, 
            reduivy__Apply_Non_Repayable_FA__c, 
            reduivy__Apply_Repayable_FA__c 
            FROM reduivy__Transaction_Order__c
            WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]);

        Map<Id, reduivy__Transaction_Order__c> trnOrderDepositMap = new Map<Id, reduivy__Transaction_Order__c>();
        for(Id trnOrderId : trnOrderMap.keySet()){

            reduivy__Transaction_Order__c trnOrderDeposit = REDU_TestData_UTIL.newTransactionOrder(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Deposit', trnOrderMap.get(trnOrderId).reduivy__Contact__c, null, date.today(), TRO_STATUSES_DRAFT.get(0), 0, 0, 0);
            trnOrderDeposit.reduivy__Apply_Payment__c = true;
            trnOrderDepositMap.put(trnOrderMap.get(trnOrderId).reduivy__Contact__c, trnOrderDeposit);
        }

        System.runAs(studentUser){

            insert trnOrderDepositMap.values();

            List<reduivy__Transaction_Line_Item__c> trnLineItemDepositList = new List<reduivy__Transaction_Line_Item__c>();
            for(Id conId: trnOrderDepositMap.keySet()){
                trnLineItemDepositList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrderDepositMap.get(conId).reduivy__Sample_Record_Code__c, trnOrderDepositMap.get(conId).Id, null, 'Deposit', 'Deposit', 200, null, null));

            }

            insert trnLineItemDepositList;

            Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
            for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, 
                reduivy__Contact__c, 
                reduivy__Amount__c 
                FROM reduivy__Individual_Funding_Allocation__c
                WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c
            ]){

                fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
            }

            //Create Transction Payment
            List<reduivy__Transaction_Payment__c> depositTrnPaymentList = new List<reduivy__Transaction_Payment__c>();
            List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
            
            List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
            for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c, reduivy__Sample_Record_Code__c 
                FROM reduivy__Transaction_Order__c WHERE Id IN: trnOrderMap.keySet()
            ]){
                
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1000, 0, 'Application;Tuition;Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, trnOrderDepositMap.get(trnOrder.reduivy__Contact__c).Id, 'Payment', null, 300, 0, 'Deposit'));

                //Check Field Mapping
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
                System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
                System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrderDepositMap.get(trnOrder.reduivy__Contact__c).reduivy__Status__c), 'Transaction Order status for the Deposit transaction should be in Draft');
                System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status for the Deposit transaction should be in Draft');

                trnOrderList.add(trnOrder);
            }

            //No Monetary Entry records are created yet because no transaction payment records are created yet.
            List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
            System.debug('trlMonetoryEntry ::');
            System.debug(trlMonetoryEntry);
            System.debug('trnPaymentList ::');
            System.debug(trnPaymentList);
            System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');


            // Execute test
            Test.startTest();

            insert depositTrnPaymentList;
            insert trnPaymentList;

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
            WHERE Id IN: trnOrderMap.keySet()
        ]){

            System.Assert.areEqual(0, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to 0');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 3800 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');
        }

        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Apply_Payment__c, 
            reduivy__Total_Outstanding_Amount__c, 
            reduivy__Total_Amount__c, 
            reduivy__Total_Paid_Amount__c, 
            reduivy__Status__c 
            FROM reduivy__Transaction_Order__c 
            WHERE reduivy__Individual_Academic_Progress__c = null AND reduivy__Contact__c =: masterIPE.reduivy__Contact__c
        ]){

            System.Assert.areEqual(-100, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to -100 due to overpaid');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status for deposit should be updated to Confirmed');
        }

        //check for empty amount of fee line
        List<reduivy__Transaction_Line_Item__c> trlList = [SELECT Id 
            FROM reduivy__Transaction_Line_Item__c 
            WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY 
            AND reduivy__Total_Amount__c = 0];
        
        System.Assert.areEqual(0, trlList.size(), 'Transaction Line Item with total amount of 0 should not be created!');

        Map<Id, Decimal> totalRemainingAmountCheck = new Map<Id, Decimal>();
        for(reduivy__Transaction_Payment__c trnPayment : [SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Amount__c, 
            reduivy__Remaining_Amount__c, 
            reduivy__Applicable_Item_Type__c, 
            reduivy__Transaction_Type__c 
            FROM reduivy__Transaction_Payment__c
            WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c
        ]){
            if(totalRemainingAmountCheck.containsKey(trnPayment.reduivy__Contact__c)){
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, totalRemainingAmountCheck.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId: totalRemainingAmountCheck.keySet()){
            System.Assert.areEqual(100, totalRemainingAmountCheck.get(conId), 'Total remaining amount for transaction payments should be 100');
        }
    }

    /**
     * @description Test the payment when a transaction payment is applied to a transaction order. the tro apply payment is false. 
     */
    @IsTest
    static void testApplyPaymentInsertAsStudentTroNoApplyPayment(){

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, 
            reduivy__Contact__c 
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ContactId = : masterIPE.reduivy__Contact__c];

        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Sample_Record_Code__c, 
            reduivy__Apply_Payment__c, 
            reduivy__Apply_Non_Repayable_FA__c, 
            reduivy__Apply_Repayable_FA__c 
            FROM reduivy__Transaction_Order__c
            WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]);

        for(reduivy__Transaction_Order__c tro : trnOrderMap.values()){
            tro.reduivy__Apply_Payment__c = false;
        }

        update trnOrderMap.values();

        System.runAs(studentUser){


            Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
            for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, 
                reduivy__Contact__c, 
                reduivy__Amount__c 
                FROM reduivy__Individual_Funding_Allocation__c
                WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c
            ]){

                fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
            }

            //Create Transction Payment
            List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
            
            List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
            for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c, reduivy__Sample_Record_Code__c 
                FROM reduivy__Transaction_Order__c WHERE Id IN: trnOrderMap.keySet()
            ]){
                
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, trnOrder.Id, 'Payment', null, 3800, 0, null));

                //Check Field Mapping
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
                System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
                System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status for the Deposit transaction should be in Draft');

                trnOrderList.add(trnOrder);
            }

            //No Monetary Entry records are created yet because no transaction payment records are created yet.
            List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
            System.debug('trlMonetoryEntry ::');
            System.debug(trlMonetoryEntry);
            System.debug('trnPaymentList ::');
            System.debug(trnPaymentList);
            System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

            // Execute test
            Test.startTest();

            insert trnPaymentList;

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
            WHERE Id IN: trnOrderMap.keySet()
        ]){

            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be 3800');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');
        }

        //check for empty amount of fee line
        List<reduivy__Transaction_Line_Item__c> trlList = [SELECT Id 
            FROM reduivy__Transaction_Line_Item__c 
            WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY 
            AND reduivy__Total_Amount__c = 0];
        
        System.Assert.areEqual(0, trlList.size(), 'Transaction Line Item with total amount of 0 should not be created!');

        Map<Id, Decimal> totalRemainingAmountCheck = new Map<Id, Decimal>();
        for(reduivy__Transaction_Payment__c trnPayment : [SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Amount__c, 
            reduivy__Remaining_Amount__c, 
            reduivy__Applicable_Item_Type__c, 
            reduivy__Transaction_Type__c 
            FROM reduivy__Transaction_Payment__c
            WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c
        ]){
            if(totalRemainingAmountCheck.containsKey(trnPayment.reduivy__Contact__c)){
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, totalRemainingAmountCheck.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId: totalRemainingAmountCheck.keySet()){
            System.Assert.areEqual(3800, totalRemainingAmountCheck.get(conId), 'Total remaining amount for transaction payments should be 3800');
        }
    }


    /**
     * @description Test the payment when a transaction payment is applied to a transaction order. the tro apply payment is true. 
     */
    @IsTest
    static void testApplyPaymentInsertAsStudentTroHasApplyPayment(){

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, 
            reduivy__Contact__c 
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ContactId = : masterIPE.reduivy__Contact__c];

        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Sample_Record_Code__c, 
            reduivy__Apply_Payment__c, 
            reduivy__Apply_Non_Repayable_FA__c, 
            reduivy__Apply_Repayable_FA__c 
            FROM reduivy__Transaction_Order__c
            WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]);

        System.runAs(studentUser){

            Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
            for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, 
                reduivy__Contact__c, 
                reduivy__Amount__c 
                FROM reduivy__Individual_Funding_Allocation__c
                WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c
            ]){

                fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
            }

            //Create Transction Payment
            List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
            
            List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
            for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c, reduivy__Sample_Record_Code__c 
                FROM reduivy__Transaction_Order__c WHERE Id IN: trnOrderMap.keySet()
            ]){
                
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, trnOrder.Id, 'Payment', null, 3800, 0, null));

                //Check Field Mapping
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
                System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
                System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status for the Deposit transaction should be in Draft');

                trnOrderList.add(trnOrder);
            }

            //No Monetary Entry records are created yet because no transaction payment records are created yet.
            List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
            System.debug('trlMonetoryEntry ::');
            System.debug(trlMonetoryEntry);
            System.debug('trnPaymentList ::');
            System.debug(trnPaymentList);
            System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

            // Execute test
            Test.startTest();

            insert trnPaymentList;

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
            WHERE Id IN: trnOrderMap.keySet()
        ]){

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

        Map<Id, Decimal> totalRemainingAmountCheck = new Map<Id, Decimal>();
        for(reduivy__Transaction_Payment__c trnPayment : [SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Amount__c, 
            reduivy__Remaining_Amount__c, 
            reduivy__Applicable_Item_Type__c, 
            reduivy__Transaction_Type__c 
            FROM reduivy__Transaction_Payment__c
            WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c
        ]){
            if(totalRemainingAmountCheck.containsKey(trnPayment.reduivy__Contact__c)){
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, totalRemainingAmountCheck.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId: totalRemainingAmountCheck.keySet()){
            System.Assert.areEqual(0, totalRemainingAmountCheck.get(conId), 'Total remaining amount for transaction payments should be 0');
        }
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term). 2 TRP with type 'Payment' is created and left with remaining amount.
     */
    @IsTest
    static void testApplyPaymentWithRemainingForSameTypeInsertAsStudent(){

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, 
            reduivy__Contact__c 
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ContactId = : masterIPE.reduivy__Contact__c];

        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Sample_Record_Code__c, 
            reduivy__Apply_Payment__c, 
            reduivy__Apply_Non_Repayable_FA__c, 
            reduivy__Apply_Repayable_FA__c 
            FROM reduivy__Transaction_Order__c
            WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]);

        Map<Id, reduivy__Transaction_Order__c> trnOrderDepositMap = new Map<Id, reduivy__Transaction_Order__c>();
        for(Id trnOrderId : trnOrderMap.keySet()){

            reduivy__Transaction_Order__c trnOrderDeposit = REDU_TestData_UTIL.newTransactionOrder(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Deposit', trnOrderMap.get(trnOrderId).reduivy__Contact__c, null, date.today(), TRO_STATUSES_DRAFT.get(0), 0, 0, 0);
            trnOrderDeposit.reduivy__Apply_Payment__c = true;
            trnOrderDepositMap.put(trnOrderMap.get(trnOrderId).reduivy__Contact__c, trnOrderDeposit);
        }

        System.runAs(studentUser){

            insert trnOrderDepositMap.values();

            List<reduivy__Transaction_Line_Item__c> trnLineItemDepositList = new List<reduivy__Transaction_Line_Item__c>();
            for(Id conId: trnOrderDepositMap.keySet()){
                trnLineItemDepositList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrderDepositMap.get(conId).reduivy__Sample_Record_Code__c, trnOrderDepositMap.get(conId).Id, null, 'Deposit', 'Deposit', 200, null, null));

            }

            insert trnLineItemDepositList;

            Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
            for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, 
                reduivy__Contact__c, 
                reduivy__Amount__c 
                FROM reduivy__Individual_Funding_Allocation__c
                WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c
            ]){

                fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
            }

            //Create Transction Payment
            List<reduivy__Transaction_Payment__c> depositTrnPaymentList = new List<reduivy__Transaction_Payment__c>();
            List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
            
            List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
            for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c, reduivy__Sample_Record_Code__c 
                FROM reduivy__Transaction_Order__c WHERE Id IN: trnOrderMap.keySet()
            ]){
                
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1000, 0, 'Application;Tuition;Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 100, 0, 'Application;Tuition;Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, trnOrderDepositMap.get(trnOrder.reduivy__Contact__c).Id, 'Payment', null, 300, 0, 'Deposit'));

                //Check Field Mapping
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
                System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
                System.Assert.areEqual(true, TRO_STATUSES_DRAFT.contains(trnOrderDepositMap.get(trnOrder.reduivy__Contact__c).reduivy__Status__c), 'Transaction Order status for the Deposit transaction should be in Draft');
                System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status for the Deposit transaction should be in Draft');

                trnOrderList.add(trnOrder);
            }

            //No Monetary Entry records are created yet because no transaction payment records are created yet.
            List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
            System.debug('trlMonetoryEntry ::');
            System.debug(trlMonetoryEntry);
            System.debug('trnPaymentList ::');
            System.debug(trnPaymentList);
            System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');


            // Execute test
            Test.startTest();

            insert depositTrnPaymentList;
            insert trnPaymentList;

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
            WHERE Id IN: trnOrderMap.keySet()
        ]){

            System.Assert.areEqual(0, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to 0');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 3800 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');
        }

        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Apply_Payment__c, 
            reduivy__Total_Outstanding_Amount__c, 
            reduivy__Total_Amount__c, 
            reduivy__Total_Paid_Amount__c, 
            reduivy__Status__c 
            FROM reduivy__Transaction_Order__c 
            WHERE reduivy__Individual_Academic_Progress__c = null AND reduivy__Contact__c =: masterIPE.reduivy__Contact__c
        ]){

            System.Assert.areEqual(-100, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to -100 due to overpaid');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status for deposit should be updated to Confirmed');
        }

        //check for empty amount of fee line
        List<reduivy__Transaction_Line_Item__c> trlList = [SELECT Id 
            FROM reduivy__Transaction_Line_Item__c 
            WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY 
            AND reduivy__Total_Amount__c = 0];
        
        System.Assert.areEqual(0, trlList.size(), 'Transaction Line Item with total amount of 0 should not be created!');

        Map<Id, Decimal> totalRemainingAmountCheck = new Map<Id, Decimal>();
        for(reduivy__Transaction_Payment__c trnPayment : [SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Amount__c, 
            reduivy__Remaining_Amount__c, 
            reduivy__Applicable_Item_Type__c, 
            reduivy__Transaction_Type__c 
            FROM reduivy__Transaction_Payment__c
            WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c
        ]){
            if(totalRemainingAmountCheck.containsKey(trnPayment.reduivy__Contact__c)){
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, totalRemainingAmountCheck.get(trnPayment.reduivy__Contact__c) + trnPayment.reduivy__Remaining_Amount__c);
            }else{
                totalRemainingAmountCheck.put(trnPayment.reduivy__Contact__c, trnPayment.reduivy__Remaining_Amount__c);
            }
        }

        for(Id conId: totalRemainingAmountCheck.keySet()){
            System.Assert.areEqual(200, totalRemainingAmountCheck.get(conId), 'Total remaining amount for transaction payments should be 100');
        }
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term) to simulate the amount consumption issue
     */
    @IsTest
    static void testApplyPaymentInsertWithConsumptionIssueAsStudent(){
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, 
            reduivy__Contact__c 
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        List<reduivy__Transaction_Order__c> statusUpdateTroList = new List<reduivy__Transaction_Order__c>();
        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c tro :[SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Sample_Record_Code__c, 
            reduivy__Apply_Payment__c, 
            reduivy__Apply_Non_Repayable_FA__c, 
            reduivy__Apply_Repayable_FA__c 
            FROM reduivy__Transaction_Order__c
            WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]){
                trnOrderMap.put(tro.Id, tro);

                statusUpdateTroList.add(new reduivy__Transaction_Order__c(Id = tro.Id, reduivy__Status__c = TRO_STATUSES_DRAFT[0]));
            }

        update statusUpdateTroList;

        //Delete the sample line item so that we can simulate a different sequence
        REDU_Database_UTIL.doDelete([SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_ORDERLINE AND reduivy__Transaction_Order__r.reduivy__Contact__c =: masterIPE.reduivy__Contact__c]);

        User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ContactId = : masterIPE.reduivy__Contact__c];

        List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        for(Id trnOrderId : trnOrderMap.keySet()){

            //Create Transaction Line Item
            trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Residential', trnOrderId, null, 'Housing fee', 'Residential', 1000, null, null));
            trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Tuition', trnOrderId, null, 'Tuition Fee', 'Tuition', 2500, null, null));
            trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Application', trnOrderId, null, 'Admission Fee', 'Application', 300, null, null));
                        
        }

        insert trnLineItemList;


        //update the tro to confirmed
        for(reduivy__Transaction_Order__c tro : statusUpdateTroList) {
            tro.reduivy__Status__c = TRO_STATUSES_CONFIRMED[0];
        }
        update statusUpdateTroList;

        System.runAs(studentUser){

            Map<String, reduivy__Individual_Funding_Allocation__c> fundAllocationMap = new Map<String, reduivy__Individual_Funding_Allocation__c>();
            for(reduivy__Individual_Funding_Allocation__c fundAllocation : [SELECT Id, 
                reduivy__Contact__c, 
                reduivy__Amount__c 
                FROM reduivy__Individual_Funding_Allocation__c
                WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c
            ]){

                fundAllocationMap.put(fundAllocation.reduivy__Contact__c + '|' + fundAllocation.reduivy__Amount__c, fundAllocation);
            }

            //Create Transction Payment
            List<reduivy__Transaction_Payment__c> trnPaymentList = new List<reduivy__Transaction_Payment__c>();
            
            for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, reduivy__Contact__c, reduivy__Total_Amount__c, reduivy__Total_Outstanding_Amount__c, reduivy__Total_Paid_Amount__c, reduivy__Individual_Academic_Progress__c, reduivy__Status__c, reduivy__Sample_Record_Code__c 
                FROM reduivy__Transaction_Order__c WHERE Id IN: trnOrderMap.keySet()
            ]){
                
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|1000.00').Id, 1000, 0, 'Tuition'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Non Repayable Financial Aid Disbursement', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|500.00').Id, 500, 0, 'Tuition'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Repayable Financial Aid Disbursement	', fundAllocationMap.get(trnOrder.reduivy__Contact__c + '|800.00').Id, 800, 0, 'Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Credit Note', null, 400, 0, 'Application;Tuition;Residential'));
                trnPaymentList.add(REDU_TestData_UTIL.newTransactionPayment( trnOrder.reduivy__Contact__c, trnOrder.reduivy__Contact__c, null, 'Payment', null, 1000, 0, 'Application;Tuition;Residential'));

                //Check Field Mapping
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 3800 for each transaction order');
                System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
                System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
                System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status for the Deposit transaction should be in Draft');

            }

            //No Monetary Entry records are created yet because no transaction payment records are created yet.
            List<reduivy__Transaction_Line_Item__c> trlMonetoryEntry = [SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY];
            System.debug('trlMonetoryEntry ::');
            System.debug(trlMonetoryEntry);
            System.debug('trnPaymentList ::');
            System.debug(trnPaymentList);
            System.Assert.areEqual(true, trlMonetoryEntry.isEmpty(), 'Monetary Entry records should not be created yet');

            // Execute test
            Test.startTest();

            insert trnPaymentList;

            Test.stopTest();
        }

        //check for empty amount of fee line
        List<reduivy__Transaction_Line_Item__c> trlList = [SELECT Id 
            FROM reduivy__Transaction_Line_Item__c 
            WHERE reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY 
            AND reduivy__Total_Amount__c = 0];
        
        System.Assert.areEqual(0, trlList.size(), 'Transaction Line Item with total amount of 0 should not be created!');

        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Total_Amount__c, 
            reduivy__Total_Outstanding_Amount__c, 
            reduivy__Total_Paid_Amount__c, 
            reduivy__Individual_Academic_Progress__c, 
            reduivy__Status__c 
            FROM reduivy__Transaction_Order__c 
            WHERE Id IN: trnOrderMap.keySet()
        ]){

            System.Assert.areEqual(300, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total outstanding amount should be offset to 0');
            System.Assert.areEqual(3800, trnOrder.reduivy__Total_Amount__c, 'Total Amount should be 3800 for each transaction order');
            System.Assert.areEqual(3500, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 3800 for each transaction order');
            System.Assert.areEqual(true, TRO_STATUSES_CONFIRMED.contains(trnOrder.reduivy__Status__c), 'Transaction Order status should be in Confirmed');
        }

    }
}