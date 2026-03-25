/**
 * @author      WDCi (Jordan)
 * @date        Nov 2024
 * @group       Trigger executable
 * @description Test class for SPS_DefaultValues_EXE
 * @changehistory
 * ISS-002176 27-11-2024 Jordan - new class
 */
@IsTest
public inherited sharing class SPS_DefaultValues_TEST {

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

            Test.stopTest();
        }
    }

    /**
     * @description Test copying credits from study unit when a new study plan structure (unit) is created
     */
    @IsTest
    static void testSpsInsertCopyCreditsAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();

        //Get study unit
        List<reduivy__Study_Plan__c> studyPlanList = [SELECT Id FROM reduivy__Study_Plan__c LIMIT 5];
        System.Assert.isTrue(studyPlanList.size() > 1);

        reduivy__Study_Unit__c studyUnit = [SELECT Id, reduivy__Credits__c FROM reduivy__Study_Unit__c LIMIT 1];
        System.Assert.isNotNull(studyUnit.reduivy__Credits__c);
        
        System.runAs(ADMIN_USER){
            //Create unit study plan structures without credits set
            List<reduivy__Study_Plan_Structure__c> spsList = new List<reduivy__Study_Plan_Structure__c>();

            for (reduivy__Study_Plan__c studyPlan : studyPlanList) {
                reduivy__Study_Plan_Structure__c sps = new reduivy__Study_Plan_Structure__c();
                sps.RecordTypeId = SPS_Helper.getUnitRecordTypeId();
                sps.reduivy__Study_Plan__c = studyPlan.Id;
                sps.reduivy__Study_Unit__c = studyUnit.Id;
                spsList.add(sps);
            }

            Test.startTest();
            insert spsList;
            Test.stopTest();

            Set<Id> spsIds = new Set<Id>();
            for (reduivy__Study_Plan_Structure__c sps : spsList) {
                spsIds.add(sps.Id);
            }

            //Assert credits copied successfully
            List<reduivy__Study_Plan_Structure__c> spsListAfter = [SELECT reduivy__Credits__c FROM reduivy__Study_Plan_Structure__c WHERE Id IN :spsIds];
            System.Assert.areEqual(spsList.size(), spsListAfter.size());

            for (reduivy__Study_Plan_Structure__c spsAfter : spsListAfter) {
                System.Assert.areEqual(studyUnit.reduivy__Credits__c, spsAfter.reduivy__Credits__c);
            }
        }
    }
}