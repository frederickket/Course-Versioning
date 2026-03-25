/**
 * @author      WDCi (VTan)
 * @date        Feb 2024
 * @group       Finance
 * @description Test class for STM_GenerateOrders_EXE
 * @changehistory
 * ISS-002025 16-08-2024 VTan - New class
 */
@IsTest
public inherited sharing class STM_GenerateOrders_TEST {
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

        Test.startTest();

        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {

        	testFactory.initMasterData(SPT_Helper.getApiName());
			testFactory.initOfferingData(SIT_Helper.getApiName());
			testFactory.initStudentData(IPE_Helper.getApiName(), true);

		}
        Test.stopTest();
    }

    /**
     * @description Test the Apply Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testGenerateIprOrdersAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Term__c currentTerm = [SELECT Id, reduivy__Generate_Transaction_Orders__c FROM reduivy__Study_Term__c WHERE reduivy__Sample_Record_Code__c = : testFactory.CYTKey ORDER BY Name ASC LIMIT 1];
        List<reduivy__Individual_Academic_Progress__c> updateIprListList = new List<reduivy__Individual_Academic_Progress__c>();
        for(reduivy__Individual_Academic_Progress__c ipr : [SELECT Id, reduivy__Generate_Transaction_Orders__c 
                                                    FROM reduivy__Individual_Academic_Progress__c 
                                                    WHERE reduivy__Academic_Term__c =: currentTerm.Id]){

            System.Assert.areEqual(false, ipr.reduivy__Generate_Transaction_Orders__c, 'Generate Transaction Orders should be unchecked');
            ipr.reduivy__Student_Fee_Type__c = IPR_Helper.STUDENT_FEE_TYPE_DOMESTIC;
            updateIprListList.add(ipr);
        }

        update updateIprListList;

        Test.startTest();

        System.runAs(ADMIN_USER){
            currentTerm.reduivy__Generate_Transaction_Orders__c = true;

            update currentTerm;
        }
        Test.stopTest();

        for(reduivy__Individual_Academic_Progress__c ipr : [SELECT Id, reduivy__Generate_Transaction_Orders__c 
                                                    FROM reduivy__Individual_Academic_Progress__c 
                                                    WHERE reduivy__Academic_Term__c =: currentTerm.Id]){

            System.Assert.areEqual(true, ipr.reduivy__Generate_Transaction_Orders__c, 'Generate Transaction Orders should be checked');
        }
    }
}