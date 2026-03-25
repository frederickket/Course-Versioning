/**
 * @author      WDCi (VTan)
 * @date        Jul 2024
 * @group       Test
 * @description Test class for SEV_SetEventDateTime_EXE
 * @changehistory
 * ISS-001922 05-07-2024 new class
 */
@IsTest
public inherited sharing class SEV_SetEventDateTime_TEST {
    
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

            Test.stopTest();
        }

    }

    /**
     * @description Test the set event date/time on creation.
     */
    @IsTest
    static void testSetEventDateOnCreation(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Date currentDate = System.today();
        DateTime startDt = DateTime.newInstance(currentDate, Time.newInstance(9, 0, 0, 0));
        DateTime endDt = DateTime.newInstance(currentDate, Time.newInstance(11, 0, 0, 0));

        string userTimeZone = String.valueOf(UserInfo.getTimeZone());
        
        reduivy__Study_Session__c sse = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Session__c LIMIT 1];
        reduivy__Study_Session_Time__c sst = REDU_TestData_UTIL.newStudySessionTime('Study_Session_Time_Test_' + sse.reduivy__Sample_Record_Code__c, sse.Id, null, 'Study Session Time Test', null, '', 'One-off', currentDate, currentDate, Time.newInstance(9, 0, 0, 0), Time.newInstance(11, 0, 0, 0));

        insert sst;

        List<reduivy__Study_Event__c> sevList = new List<reduivy__Study_Event__c>();
        sevList.add(REDU_TestData_UTIL.newSessionStudyEvent(startDt.format() + ' - Study Event Test', sst.Id, 'Study Event Test', null, 'Confirmed', startDt, endDt));
        sevList.add(REDU_TestData_UTIL.newSessionStudyEvent(startDt.format() + ' - Study Event Test', sst.Id, 'Study Event Test', null, 'Confirmed', startDt, endDt));
        sevList.add(REDU_TestData_UTIL.newSessionStudyEvent(startDt.format() + ' - Study Event Test', sst.Id, 'Study Event Test', null, 'Confirmed', startDt, endDt));

        sevList[1].reduivy__Timezone__c = userTimeZone;
        sevList[2].reduivy__Timezone__c = 'Australia/Sydney';

        // Execute test
        Test.startTest();

        System.runAs(ADMIN_USER) {
            insert sevList;
        }

        Test.stopTest();

        for(reduivy__Study_Event__c sev : [SELECT Id, reduivy__Timezone__c, reduivy__Start__c, reduivy__End__c FROM reduivy__Study_Event__c]){
            system.debug('TIMEZONE :: '+sev.reduivy__Timezone__c);
            system.debug(sev.reduivy__Start__c + ' - ' + sev.reduivy__End__c);

            if(String.isNotBlank(sev.reduivy__Timezone__c)){
                System.Assert.areEqual(REDU_Date_UTIL.convertDateTime(startDt, userTimeZone, sev.reduivy__Timezone__c), sev.reduivy__Start__c, 'Start DateTime should be converted based on user\'s timezone');
                System.Assert.areEqual(REDU_Date_UTIL.convertDateTime(endDt, userTimeZone, sev.reduivy__Timezone__c), sev.reduivy__End__c, 'End DateTime should be converted based on user\'s timezone');
            }else{
                System.Assert.areEqual(REDU_Date_UTIL.convertDateTime(startDt, userTimeZone, userTimeZone), sev.reduivy__Start__c, 'Start DateTime should be converted based on user\'s timezone');
            }
        }
    }

    /**
     * @description Test the set event date/time on update.
     */
    @IsTest
    static void testSetEventDateOnUpdate(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Date currentDate = System.today();
        DateTime startDt = DateTime.newInstance(currentDate, Time.newInstance(9, 0, 0, 0));
        DateTime endDt = DateTime.newInstance(currentDate, Time.newInstance(11, 0, 0, 0));

        string userTimeZone = String.valueOf(UserInfo.getTimeZone());
        
        reduivy__Study_Session__c sse = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Session__c LIMIT 1];
        reduivy__Study_Session_Time__c sst = REDU_TestData_UTIL.newStudySessionTime('Study_Session_Time_Test_' + sse.reduivy__Sample_Record_Code__c, sse.Id, null, 'Study Session Time Test', null, '', 'One-off', currentDate, currentDate, Time.newInstance(9, 0, 0, 0), Time.newInstance(11, 0, 0, 0));

        insert sst;

        List<reduivy__Study_Event__c> sevList = new List<reduivy__Study_Event__c>();
        sevList.add(REDU_TestData_UTIL.newSessionStudyEvent(startDt.format() + ' - Study Event Test', sst.Id, 'Study Event Test', null, 'Confirmed', DateTime.newInstance(2024, 1, 1, 0, 0, 0), DateTime.newInstance(2024, 1, 1, 0, 0, 0)));
        sevList.add(REDU_TestData_UTIL.newSessionStudyEvent(startDt.format() + ' - Study Event Test', sst.Id, 'Study Event Test', null, 'Confirmed', DateTime.newInstance(2024, 1, 1, 0, 0, 0), DateTime.newInstance(2024, 1, 1, 0, 0, 0)));
        sevList.add(REDU_TestData_UTIL.newSessionStudyEvent(startDt.format() + ' - Study Event Test', sst.Id, 'Study Event Test', null, 'Confirmed', DateTime.newInstance(2024, 1, 1, 0, 0, 0), DateTime.newInstance(2024, 1, 1, 0, 0, 0)));

        sevList[1].reduivy__Timezone__c = userTimeZone;
        sevList[2].reduivy__Timezone__c = 'Australia/Sydney';
        insert sevList;

        // Execute test
        Test.startTest();

        for(reduivy__Study_Event__c sev : sevList){
            sev.reduivy__Start_Date_Non_TZ__c = startDt.date();
            sev.reduivy__Start_Time_Non_TZ__c = startDt.time();
            sev.reduivy__End_Date_Non_TZ__c = endDt.date();
            sev.reduivy__End_Time_Non_TZ__c = endDt.time();
        }

        System.runAs(ADMIN_USER) {
            update sevList;
        }

        Test.stopTest();

        for(reduivy__Study_Event__c sev : [SELECT Id, reduivy__Timezone__c, reduivy__Start__c, reduivy__End__c FROM reduivy__Study_Event__c]){
            system.debug('TIMEZONE :: '+sev.reduivy__Timezone__c);
            system.debug(sev.reduivy__Start__c + ' - ' + sev.reduivy__End__c);

            if(String.isNotBlank(sev.reduivy__Timezone__c)){
                System.Assert.areEqual(REDU_Date_UTIL.convertDateTime(startDt, userTimeZone, sev.reduivy__Timezone__c), sev.reduivy__Start__c, 'Start DateTime should be converted based on user\'s timezone');
                System.Assert.areEqual(REDU_Date_UTIL.convertDateTime(endDt, userTimeZone, sev.reduivy__Timezone__c), sev.reduivy__End__c, 'End DateTime should be converted based on user\'s timezone');
            }else{
                System.Assert.areEqual(REDU_Date_UTIL.convertDateTime(startDt, userTimeZone, userTimeZone), sev.reduivy__Start__c, 'Start DateTime should be converted based on user\'s timezone');
            }
        }
    }
}