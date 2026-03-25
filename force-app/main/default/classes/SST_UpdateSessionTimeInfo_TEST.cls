/**
 * @author      WDCi (VTan)
 * @date        Jul 2024
 * @group       Test
 * @description Test class for SSE_GenerateStudyEvents_EXE
 * @changehistory
 * ISS-001922 05-07-2024 new class
 */
@IsTest
public inherited sharing class SST_UpdateSessionTimeInfo_TEST {
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

            testFactory.initMasterData(null);
            testFactory.initOfferingData(SST_Helper.getApiName());

            Test.stopTest();
        }
    }

    /**
     * @description Test the weekly event creation from study session
     */
    @IsTest
    static void testSessionTimeInfoOnUpdateAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session_Time__c sstWeekly = [SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Sample_Record_Code__c, reduivy__Default_Facility__c, reduivy__Study_Session__r.reduivy__Start_Date_Calculated__c, reduivy__Study_Session__r.reduivy__End_Date_Calculated__c  FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY LIMIT 1];

        reduivy__Study_Session_Time__c newSstBiWeekly = REDU_TestData_UTIL.newStudySessionTime('Mon BiWeekly(9-11)' + sstWeekly.reduivy__Sample_Record_Code__c, sstWeekly.reduivy__Study_Session__c, sstWeekly.reduivy__Default_Facility__c, 'Lecture - Monday BiWeekly', null, 'Monday', 'Weekly', null, null, Time.newInstance(9, 0, 0, 0), Time.newInstance(11, 0, 0, 0));
        insert newSstBiWeekly;

        newSstBiWeekly.reduivy__Recurrence__c = SST_Helper.RECURRENCE_BIWEEKLY;

        Test.startTest();

        System.runAs(ADMIN_USER) {
            // Execute test
            update newSstBiWeekly;
        }

        Test.stopTest();

        reduivy__Study_Session_Time__c sstCheck = [SELECT Id, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Update_Action__c, reduivy__Historical_Recurrence__c FROM reduivy__Study_Session_Time__c WHERE Id = :newSstBiWeekly.Id LIMIT 1];
        System.Assert.areEqual(SST_Helper.UPDATE_ACTION_RECREATE, sstCheck.reduivy__Update_Action__c, 'Study session time\'s update action should be updated');
        System.Assert.areEqual(true, String.isNotBlank(sstCheck.reduivy__Historical_Recurrence__c), 'Study session time\'s historical recurrence should be populated');
    }
}