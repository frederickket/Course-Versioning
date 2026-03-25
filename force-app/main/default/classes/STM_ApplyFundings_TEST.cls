/**
 * @author      WDCi (VTan)
 * @date        Feb 2024
 * @group       Finance
 * @description Test class for STM_ApplyFundings_EXE
 * @changehistory
 * ISS-001848 21-02-2024 VTan - New class
 */
@IsTest
public inherited sharing class STM_ApplyFundings_TEST{
    
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
			testFactory.initOfferingData(STM_Helper.getApiName());
			testFactory.initStudentData(IPR_Helper.getApiName(), true);

            //Create Academic Progress
            Date todayDate = date.today();
            reduivy__Study_Term__c currentTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Sample_Record_Code__c = : testFactory.CYTKey LIMIT 1];
            List<reduivy__Individual_Academic_Progress__c> termProgressList = new List<reduivy__Individual_Academic_Progress__c>();

            for(reduivy__Individual_Program_Enrollment__c ipe : [SELECT Id, reduivy__Contact__c, reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE reduivy__Sample_Record_Code__c <> '']){

                reduivy__Individual_Academic_Progress__c termProgress = REDU_TestData_UTIL.newIndividualAcademicProgress(ipe.reduivy__Contact__c + '|' + currentTerm.Id, ipe.reduivy__Contact__c, currentTerm.Id, null);

                termProgressList.add(termProgress);
            }

            insert termProgressList;

            //Create Transaction Order
            List<reduivy__Transaction_Order__c> transactionOrderList = new List<reduivy__Transaction_Order__c>();
            String troStatusConfirmed = TRO_Helper.getConfirmedStatuses().get(0);
            for(reduivy__Individual_Academic_Progress__c termProgress : termProgressList){

                reduivy__Transaction_Order__c transactionOrder = REDU_TestData_UTIL.newTransactionOrder(termProgress.reduivy__Sample_Record_Code__c, termProgress.reduivy__Contact__c, termProgress.Id, todayDate, troStatusConfirmed, 0, 0, 0);

                transactionOrderList.add(transactionOrder);
            }

            insert transactionOrderList;

            Test.stopTest();
        }
    }

    /**
     * @description Test the Apply Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testFundingApplicationAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Date todayDate = date.today();
        reduivy__Study_Term__c currentTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Sample_Record_Code__c = : testFactory.CYTKey ORDER BY Name ASC LIMIT 1];
        for(reduivy__Transaction_Order__c transactionOrder : [SELECT Id, reduivy__Apply_Non_Repayable_FA__c, reduivy__Apply_Repayable_FA__c FROM reduivy__Transaction_Order__c WHERE reduivy__Individual_Academic_Progress__r.reduivy__Academic_Term__c =: currentTerm.Id]){

            System.Assert.areEqual(false, transactionOrder.reduivy__Apply_Non_Repayable_FA__c, 'Apply Non Repayable FA should be unchecked');
            System.Assert.areEqual(false, transactionOrder.reduivy__Apply_Repayable_FA__c, 'Apply Repayable FA should be unchecked');
        }
    
        Test.startTest();

        System.runAs(ADMIN_USER){
            currentTerm.reduivy__Apply_Non_Repayable_FA__c = true;
            currentTerm.reduivy__Apply_Repayable_FA__c = true;

            update currentTerm;
        }

        Test.stopTest();

        for(reduivy__Transaction_Order__c transactionOrder : [SELECT Id, reduivy__Apply_Non_Repayable_FA__c, reduivy__Apply_Repayable_FA__c FROM reduivy__Transaction_Order__c WHERE reduivy__Individual_Academic_Progress__r.reduivy__Academic_Term__c =: currentTerm.Id]){

            System.Assert.areEqual(true, transactionOrder.reduivy__Apply_Non_Repayable_FA__c, 'Apply Non Repayable FA should be checked');
            System.Assert.areEqual(true, transactionOrder.reduivy__Apply_Repayable_FA__c, 'Apply Repayable FA should be checked');
        }
    }
}