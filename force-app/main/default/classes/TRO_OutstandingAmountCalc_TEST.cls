/**
 * @author      WDCi (VTan)
 * @date        Mar 2024
 * @group       Finance
 * @description Test class for TRO_OutstandingAmountCalc_EXE
 * @changehistory
 * ISS-001866 26-02-2024 VTan - New class
 */
@IsTest
public inherited sharing class TRO_OutstandingAmountCalc_TEST extends REDU_TriggerExecutable {
    
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

            Test.stopTest();
        }
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testOutstandingAmountCalcAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, 
                                                                                                    reduivy__Contact__c, 
                                                                                                    reduivy__Sample_Record_Code__c 
                                                                                                    FROM reduivy__Transaction_Order__c]);
        System.runAs(ADMIN_USER){

            // Execute test
            Test.startTest();

            //Create Transaction Line Item
            List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
            for(Id trnOrderId : trnOrderMap.keySet()){

                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Application', trnOrderMap.get(trnOrderId).Id, null, 'Admission Fee', 'Application', 300, null, null));
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Tuition With Discount', trnOrderMap.get(trnOrderId).Id, null, 'Tuition Fee', 'Tuition', 2500, null, null));
            }
            insert trnLineItemList;

            for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                        reduivy__Total_Amount__c, 
                                                        reduivy__Total_Outstanding_Amount__c, 
                                                        reduivy__Total_Paid_Amount__c 
                                                        FROM reduivy__Transaction_Order__c 
                                                        WHERE Id IN: trnOrderMap.keySet()]){

                System.Assert.areEqual(2800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 2800 for each transaction order');
                System.Assert.areEqual(2800, trnOrder.reduivy__Total_Amount__c, 'Total amount should be 2800.');
                System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            }
        


            for(Id trnOrderId : trnOrderMap.keySet()){

                trnOrderMap.get(trnOrderId).reduivy__Total_Paid_Amount__c = 2800;
            }
            update trnOrderMap.values();

            Test.stopTest();
        }

        for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                                                    reduivy__Total_Amount__c, 
                                                    reduivy__Total_Outstanding_Amount__c, 
                                                    reduivy__Total_Paid_Amount__c 
                                                    FROM reduivy__Transaction_Order__c 
                                                    WHERE Id IN: trnOrderMap.keySet()]){

            System.Assert.areEqual(0, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 0 for each transaction order');
            System.Assert.areEqual(2800, trnOrder.reduivy__Total_Amount__c, 'Total amount should be 2800.');
            System.Assert.areEqual(2800, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 2800 for each transaction order');
        }
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testOutstandingAmountCalcAsStudent(){

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
                                                                                                    reduivy__Sample_Record_Code__c 
                                                                                                    FROM reduivy__Transaction_Order__c 
                                                                                                    WHERE reduivy__Contact__c =: masterIPE.reduivy__Contact__c]);

        System.runAs(studentUser){
            Test.startTest();
            //Create Transaction Line Item
            List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
            for(Id trnOrderId : trnOrderMap.keySet()){
                
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Application', trnOrderMap.get(trnOrderId).Id, null, 'Admission Fee', 'Application', 300, null, null));
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Tuition With Discount', trnOrderMap.get(trnOrderId).Id, null, 'Tuition Fee', 'Tuition', 2500, null, null));
            }
            insert trnLineItemList;
            
            for(reduivy__Transaction_Order__c trnOrder : [SELECT Id, 
                reduivy__Total_Amount__c, 
                reduivy__Total_Outstanding_Amount__c, 
                reduivy__Total_Paid_Amount__c 
                FROM reduivy__Transaction_Order__c 
                WHERE Id IN: trnOrderMap.keySet()]){
                    
                    System.Assert.areEqual(2800, trnOrder.reduivy__Total_Outstanding_Amount__c, 'Total Outstanding Amount should be 2800 for each transaction order');
                    System.Assert.areEqual(2800, trnOrder.reduivy__Total_Amount__c, 'Total amount should be 2800.');
                    System.Assert.areEqual(0, trnOrder.reduivy__Total_Paid_Amount__c, 'Total Paid Amount should be 0 for each transaction order');
            }       
            Test.stopTest();                                                                           
        }

    }
}