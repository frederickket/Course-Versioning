/**
 * @author      WDCi (VTan)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for TRO_DefaultValues_EXE
 * @changehistory
 * ISS-002026 12-08-2023 VTan - new class
 */
@IsTest
public inherited sharing class TRO_DefaultValues_TEST {

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

        Test.startTest();

        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {

        	testFactory.initMasterData(SPL_Helper.getApiName());
			testFactory.initOfferingData(null);
			testFactory.initStudentData(SER_Helper.getApiName(), true);
		}
        Test.stopTest();
    }

    /**
     * @description Test generate Order with per credit, study unit, term and academic year fees. Order Generation Action = New Order Only
     */
    @IsTest
    static void testGenerateTrnOrder() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Term__c currentTerm = [SELECT Id, reduivy__Apply_Non_Repayable_FA__c, reduivy__Apply_Repayable_FA__c, reduivy__Apply_Payment__c 
                                        FROM reduivy__Study_Term__c 
                                        WHERE reduivy__Sample_Record_Code__c = : testFactory.CYTKey 
                                        ORDER BY Name ASC LIMIT 1];

        currentTerm.reduivy__Apply_Non_Repayable_FA__c = true;
        currentTerm.reduivy__Apply_Repayable_FA__c = true;
        currentTerm.reduivy__Apply_Payment__c = true;

        update currentTerm;

        Map<String, reduivy__Transaction_Order__c> newTroMap = new Map<String, reduivy__Transaction_Order__c>();
        for(reduivy__Individual_Academic_Progress__c ipr : [SELECT Id, reduivy__Contact__c, reduivy__Academic_Term__c
                                                    FROM reduivy__Individual_Academic_Progress__c 
                                                    WHERE reduivy__Academic_Term__c =: currentTerm.Id]){

            newTroMap.put(ipr.reduivy__Contact__c + '_' + ipr.reduivy__Academic_Term__c + '_Transaction Order', REDU_TestData_UTIL.newTransactionOrder(ipr.reduivy__Contact__c + '_' + ipr.reduivy__Academic_Term__c + '_Transaction Order', ipr.reduivy__Contact__c, ipr.Id, System.today(), TRO_Helper.getConfirmedStatuses().get(0), 0, 0, 0));
        }

        Test.startTest();
		System.runAs(ADMIN_USER) {
            insert newTroMap.Values();
        }
        Test.stopTest();

        for(reduivy__Transaction_Order__c tro : [SELECT Id, reduivy__Apply_Non_Repayable_FA__c, reduivy__Apply_Repayable_FA__c, reduivy__Apply_Payment__c 
                                        FROM reduivy__Transaction_Order__c 
                                        WHERE reduivy__Sample_Record_Code__c IN : newTroMap.keySet()]){

            System.Assert.areEqual(true, tro.reduivy__Apply_Non_Repayable_FA__c, 'Apply Non Repayable FA should be defaulted to true based on the related study term');
            System.Assert.areEqual(true, tro.reduivy__Apply_Repayable_FA__c, 'Apply Repayable FA should be defaulted to true based on the related study term');
            System.Assert.areEqual(true, tro.reduivy__Apply_Payment__c, 'Apply Payment should be defaulted to true based on the related study term');
        }

    }
}