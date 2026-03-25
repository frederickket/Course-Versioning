/**
 * @author      WDCi (VTan)
 * @date        Mar 2024
 * @group       Finance
 * @description Test class for TRL_TotalAmountCalc_EXE
 * @changehistory
 * ISS-001866 26-02-2024 VTan - New class
 */
@IsTest
public inherited sharing class TRL_TotalAmountCalc_TEST{
    
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
    static void testTotalAmountCalcInsertAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, reduivy__Contact__c, reduivy__Sample_Record_Code__c, reduivy__Apply_Payment__c, reduivy__Apply_Non_Repayable_FA__c, reduivy__Apply_Repayable_FA__c FROM reduivy__Transaction_Order__c]);

        //Create Transaction Line Item
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        for(Id trnOrderId : trnOrderMap.keySet()){

            reduivy__Transaction_Line_Item__c trnLineItemWithDiscount = REDU_TestData_UTIL.newTransactionOrderLine(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Tuition With Discount', trnOrderMap.get(trnOrderId).Id, null, 'Tuition Fee', 'Tuition', 2500, null, null);
            trnLineItemWithDiscount.reduivy__Discount__c = 500;
            trnLineItemList.add(trnLineItemWithDiscount);

            System.Assert.areEqual(true, trnOrderMap.get(trnOrderId).reduivy__Apply_Payment__c, 'Apply payment in transaction order should be marked as true');
            System.Assert.areEqual(true, trnOrderMap.get(trnOrderId).reduivy__Apply_Non_Repayable_FA__c, 'Disburse Non Repayable FA in transaction order should be marked as true');
            System.Assert.areEqual(true, trnOrderMap.get(trnOrderId).reduivy__Apply_Repayable_FA__c, 'Disburse Repayable FA in transaction order should be marked as true');
        }

        System.runAs(ADMIN_USER){

            // Execute test
            Test.startTest();

            insert trnLineItemList;

            Test.stopTest();
        }
        
        for(reduivy__Transaction_Line_Item__c trnLineItem : [SELECT Id, reduivy__Total_Amount__c, reduivy__Outstanding_Amount__c FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Order__c IN: trnOrderMap.keySet()]){
            System.Assert.areEqual(2000, trnLineItem.reduivy__Total_Amount__c, 'Outstanding amount should be 2000.');
        }
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testTotalAmountCalcUpdateAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, reduivy__Contact__c, reduivy__Sample_Record_Code__c, reduivy__Apply_Payment__c, reduivy__Apply_Non_Repayable_FA__c, reduivy__Apply_Repayable_FA__c FROM reduivy__Transaction_Order__c]);

        //Create Transaction Line Item
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        for(Id trnOrderId : trnOrderMap.keySet()){

            trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Application', trnOrderMap.get(trnOrderId).Id, null, 'Admission Fee', 'Application', 300, null, null));

            reduivy__Transaction_Line_Item__c trnLineItemWithDiscount = REDU_TestData_UTIL.newTransactionOrderLine(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Tuition With Discount', trnOrderMap.get(trnOrderId).Id, null, 'Tuition Fee', 'Tuition', 2500, null, null);
            trnLineItemWithDiscount.reduivy__Discount__c = 500;
            trnLineItemList.add(trnLineItemWithDiscount);

            System.Assert.areEqual(true, trnOrderMap.get(trnOrderId).reduivy__Apply_Payment__c, 'Apply payment in transaction order should be marked as true');
            System.Assert.areEqual(true, trnOrderMap.get(trnOrderId).reduivy__Apply_Non_Repayable_FA__c, 'Disburse Non Repayable FA in transaction order should be marked as true');
            System.Assert.areEqual(true, trnOrderMap.get(trnOrderId).reduivy__Apply_Repayable_FA__c, 'Disburse Repayable FA in transaction order should be marked as true');
        }

        insert trnLineItemList;

        System.runAs(ADMIN_USER){

            // Execute test
            Test.startTest();

            for(reduivy__Transaction_Line_Item__c trnLineItem : trnLineItemList){
                if(trnLineItem.reduivy__Item_Type__c == 'Application'){
                    trnLineItem.reduivy__Unit_Price__c = 0;
                }else if(trnLineItem.reduivy__Item_Type__c == 'Tuition'){
                    trnLineItem.reduivy__Unit_Price__c = 2000;
                }
            }
            update trnLineItemList;

            Test.stopTest();
        }

        for(reduivy__Transaction_Line_Item__c trnLineItem : [SELECT Id, reduivy__Total_Amount__c, reduivy__Item_Type__c FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Order__c =: trnOrderMap.keySet()]){

            if(trnLineItem.reduivy__Item_Type__c == 'Application'){
                System.Assert.areEqual(0, trnLineItem.reduivy__Total_Amount__c, 'Total amount for the transaction line with type Application should be 0.');
            }else if(trnLineItem.reduivy__Item_Type__c == 'Tuition'){
                System.Assert.areEqual(1500, trnLineItem.reduivy__Total_Amount__c, 'Total amount for the transaction line with type Tuition should be 1500.');
            }
        }
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testTotalAmountCalcInsertAsStudent(){

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

        //Create Transaction Line Item
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        for(Id trnOrderId : trnOrderMap.keySet()){

            reduivy__Transaction_Line_Item__c trnLineItemWithDiscount = REDU_TestData_UTIL.newTransactionOrderLine(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Tuition With Discount', trnOrderMap.get(trnOrderId).Id, null, 'Tuition Fee', 'Tuition', 2500, null, null);
            trnLineItemWithDiscount.reduivy__Discount__c = 500;
            trnLineItemList.add(trnLineItemWithDiscount);

            System.Assert.areEqual(true, trnOrderMap.get(trnOrderId).reduivy__Apply_Payment__c, 'Apply payment in transaction order should be marked as true');
            System.Assert.areEqual(true, trnOrderMap.get(trnOrderId).reduivy__Apply_Non_Repayable_FA__c, 'Disburse Non Repayable FA in transaction order should be marked as true');
            System.Assert.areEqual(true, trnOrderMap.get(trnOrderId).reduivy__Apply_Repayable_FA__c, 'Disburse Repayable FA in transaction order should be marked as true');
        }

        System.runAs(studentUser){

            // Execute test
            Test.startTest();

            insert trnLineItemList;

            Test.stopTest();
        }
        
        for(reduivy__Transaction_Line_Item__c trnLineItem : [SELECT Id, reduivy__Total_Amount__c, reduivy__Outstanding_Amount__c FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Order__c IN: trnOrderMap.keySet()]){
            System.Assert.areEqual(2000, trnLineItem.reduivy__Total_Amount__c, 'Outstanding amount should be 2000.');
        }
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testTotalAmountCalcUpdateAsStudent(){

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

        //Create Transaction Line Item
        List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        for(Id trnOrderId : trnOrderMap.keySet()){

            trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Application', trnOrderMap.get(trnOrderId).Id, null, 'Admission Fee', 'Application', 300, null, null));

            reduivy__Transaction_Line_Item__c trnLineItemWithDiscount = REDU_TestData_UTIL.newTransactionOrderLine(trnOrderMap.get(trnOrderId).reduivy__Sample_Record_Code__c + '|Tuition With Discount', trnOrderMap.get(trnOrderId).Id, null, 'Tuition Fee', 'Tuition', 2500, null, null);
            trnLineItemWithDiscount.reduivy__Discount__c = 500;
            trnLineItemList.add(trnLineItemWithDiscount);

            System.Assert.areEqual(true, trnOrderMap.get(trnOrderId).reduivy__Apply_Payment__c, 'Apply payment in transaction order should be marked as true');
            System.Assert.areEqual(true, trnOrderMap.get(trnOrderId).reduivy__Apply_Non_Repayable_FA__c, 'Disburse Non Repayable FA in transaction order should be marked as true');
            System.Assert.areEqual(true, trnOrderMap.get(trnOrderId).reduivy__Apply_Repayable_FA__c, 'Disburse Repayable FA in transaction order should be marked as true');
        }

        insert trnLineItemList;

        System.runAs(studentUser){

            // Execute test
            Test.startTest();

            for(reduivy__Transaction_Line_Item__c trnLineItem : trnLineItemList){
                if(trnLineItem.reduivy__Item_Type__c == 'Application'){
                    trnLineItem.reduivy__Unit_Price__c = 0;
                }else if(trnLineItem.reduivy__Item_Type__c == 'Tuition'){
                    trnLineItem.reduivy__Unit_Price__c = 2000;
                }
            }
            update trnLineItemList;

            Test.stopTest();
        }

        for(reduivy__Transaction_Line_Item__c trnLineItem : [SELECT Id, 
                                                            reduivy__Total_Amount__c, 
                                                            reduivy__Item_Type__c 
                                                            FROM reduivy__Transaction_Line_Item__c 
                                                            WHERE reduivy__Transaction_Order__c =: trnOrderMap.keySet()]){

            if(trnLineItem.reduivy__Item_Type__c == 'Application'){
                System.Assert.areEqual(0, trnLineItem.reduivy__Total_Amount__c, 'Total amount for the transaction line with type Application should be 0.');
            }else if(trnLineItem.reduivy__Item_Type__c == 'Tuition'){
                System.Assert.areEqual(1500, trnLineItem.reduivy__Total_Amount__c, 'Total amount for the transaction line with type Tuition should be 1500.');
            }
        }
    }
}