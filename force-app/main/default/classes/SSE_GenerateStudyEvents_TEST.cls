/**
 * @author      WDCi (VTan)
 * @date        Jul 2024
 * @group       Test
 * @description Test class for SSE_GenerateStudyEvents_EXE
 * @changehistory
 * ISS-001922 05-07-2024 new class
 */
@IsTest
public inherited sharing class SSE_GenerateStudyEvents_TEST {
    
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

            //delete all sample holidays to avoid conflict with test class
            REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Holiday__c WHERE reduivy__Sample_Record_Code__c != null]);
            Test.stopTest();
        }
    }

    /**
     * @description Test the weekly event creation from study session
     */
    @IsTest
    static void testGenerateWeeklyEvents(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session_Time__c sstWeekly = [SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 1];
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        integer numberDayBetween = sstWeekly.reduivy__Start_Date__c.daysBetween(sstWeekly.reduivy__End_Date__c);
        sstWeekly.reduivy__Start_Date__c = null;
        sstWeekly.reduivy__End_Date__c = null;

        update sstWeekly;

        reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
        updateSse.Id = sstWeekly.reduivy__Study_Session__c;
        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;

        // Execute test
        Test.startTest();

        System.runAs(ADMIN_USER) {
            update updateSse;
        }

        Test.stopTest();

        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];

        System.Assert.areEqual(20, sevListCheck.size(), '20 Study Events should be created for the Study Session Time');
    }

    /**
     * @description Test the weekly event creation from study session (with holiday)
     */
    @IsTest
    static void testGenerateWeeklyEventsExcludeHoliday(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session_Time__c sstWeekly = [SELECT Id, reduivy__Study_Session__c, reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__c, reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__r.ParentId FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 1];
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
        updateSse.Id = sstWeekly.reduivy__Study_Session__c;
        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
        update updateSse;

        for(reduivy__Study_Event__c sev : [SELECT Id, Name, reduivy__Start_Date_Non_TZ__c, reduivy__End_Date_Non_TZ__c 
                                            FROM reduivy__Study_Event__c 
                                            WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id]){
            
            sevListCheck.add(sev);
        }
        System.Assert.areEqual(20, sevListCheck.size(), '20 Study Events should be created for the Study Session Time');

        List<reduivy__Holiday__c> newHolidays = new List<reduivy__Holiday__c>();
        reduivy__Holiday__c eduInstitutionHoliday = new reduivy__Holiday__c();
        eduInstitutionHoliday.Name = 'Educational Institution Holiday';
        eduInstitutionHoliday.reduivy__Start_Date__c = sevListCheck[0].reduivy__Start_Date_Non_TZ__c;
        eduInstitutionHoliday.reduivy__End_Date__c = sevListCheck[0].reduivy__Start_Date_Non_TZ__c;
        eduInstitutionHoliday.reduivy__Educational_Institution_Campus__c = sstWeekly.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__r.ParentId;

        reduivy__Holiday__c campusHoliday = new reduivy__Holiday__c();
        campusHoliday.Name = 'Campus Holiday';
        campusHoliday.reduivy__Start_Date__c = sevListCheck[1].reduivy__Start_Date_Non_TZ__c;
        campusHoliday.reduivy__End_Date__c = sevListCheck[1].reduivy__Start_Date_Non_TZ__c;
        campusHoliday.reduivy__Educational_Institution_Campus__c = sstWeekly.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__c;

        newHolidays.add(eduInstitutionHoliday);
        newHolidays.add(campusHoliday);
        insert newHolidays;

        // Execute test
        Test.startTest();

        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
        update updateSse;

        Test.stopTest();

        sevListCheck.clear();
        for(reduivy__Study_Event__c sev : [SELECT Id, reduivy__Start_Date_Non_TZ__c, reduivy__End_Date_Non_TZ__c 
                                            FROM reduivy__Study_Event__c
                                            WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id]){

            sevListCheck.add(sev);
            System.Assert.areNotEqual(sev.reduivy__Start_Date_Non_TZ__c, eduInstitutionHoliday.reduivy__Start_Date__c, 'Educational Institution Holiday should be skipped.');
            System.Assert.areNotEqual(sev.reduivy__Start_Date_Non_TZ__c, campusHoliday.reduivy__Start_Date__c, 'Campus Holiday should be skipped.');

        }

        System.Assert.areEqual(18, sevListCheck.size(), '18 Study Events should be recreated/upserted for the Study Session Time as 2 holidays are skipped');

    }

    /**
     * @description Test the weekly event creation from study session (with multi days holiday)
     */
    @IsTest
    static void testGenerateWeeklyEventsExcludeMultiDaysHoliday(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session_Time__c sstWeekly = [SELECT Id, reduivy__Study_Session__c, reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__c, reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__r.ParentId FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 1];
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
        updateSse.Id = sstWeekly.reduivy__Study_Session__c;
        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
        update updateSse;

        for(reduivy__Study_Event__c sev : [SELECT Id, Name, reduivy__Start_Date_Non_TZ__c, reduivy__End_Date_Non_TZ__c 
                                            FROM reduivy__Study_Event__c 
                                            WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id]){
            
            sevListCheck.add(sev);
        }
        System.Assert.areEqual(20, sevListCheck.size(), '20 Study Events should be created for the Study Session Time');

        List<reduivy__Holiday__c> newHolidays = new List<reduivy__Holiday__c>();
        reduivy__Holiday__c eduInstitutionHoliday = new reduivy__Holiday__c();
        eduInstitutionHoliday.Name = 'Educational Institution Holiday';
        eduInstitutionHoliday.reduivy__Start_Date__c = sevListCheck[0].reduivy__Start_Date_Non_TZ__c;
        eduInstitutionHoliday.reduivy__End_Date__c = sevListCheck[2].reduivy__Start_Date_Non_TZ__c;
        eduInstitutionHoliday.reduivy__Educational_Institution_Campus__c = sstWeekly.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__r.ParentId;

        newHolidays.add(eduInstitutionHoliday);

        insert newHolidays;

        // Execute test
        Test.startTest();
        System.runAs(ADMIN_USER) {
            updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
            update updateSse;
        }

        Test.stopTest();

        sevListCheck.clear();
        for(reduivy__Study_Event__c sev : [SELECT Id, reduivy__Start_Date_Non_TZ__c, reduivy__End_Date_Non_TZ__c 
            FROM reduivy__Study_Event__c
            WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id
        ]){
            sevListCheck.add(sev);

            if (eduInstitutionHoliday.reduivy__Start_Date__c <= sev.reduivy__Start_Date_Non_TZ__c && eduInstitutionHoliday.reduivy__End_Date__c >= sev.reduivy__Start_Date_Non_TZ__c) {
                System.Assert.areNotEqual(sev.reduivy__Start_Date_Non_TZ__c, eduInstitutionHoliday.reduivy__Start_Date__c, 'Educational Institution Holiday should be skipped.');
            }

        }

        System.Assert.areEqual(17, sevListCheck.size(), '17 Study Events should be recreated/upserted for the Study Session Time as 2 holidays are skipped');

    }

    /**
     * @description Test the weekly event creation from study session (with holiday ignored)
     */
    @IsTest
    static void testGenerateWeeklyEventsIgnoreHoliday(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session_Time__c sstWeekly = [SELECT Id, reduivy__Study_Session__c, reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__c, reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__r.ParentId FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 1];
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        sstWeekly.reduivy__Ignore_Holidays__c = true;
        update sstWeekly;

        reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
        updateSse.Id = sstWeekly.reduivy__Study_Session__c;
        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
        update updateSse;

        for(reduivy__Study_Event__c sev : [SELECT Id, Name, reduivy__Start_Date_Non_TZ__c, reduivy__End_Date_Non_TZ__c 
                                            FROM reduivy__Study_Event__c 
                                            WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id]){
            
            sevListCheck.add(sev);
        }
        System.Assert.areEqual(20, sevListCheck.size(), '20 Study Events should be created for the Study Session Time');

        List<reduivy__Holiday__c> newHolidays = new List<reduivy__Holiday__c>();
        reduivy__Holiday__c eduInstitutionHoliday = new reduivy__Holiday__c();
        eduInstitutionHoliday.Name = 'Educational Institution Holiday';
        eduInstitutionHoliday.reduivy__Start_Date__c = sevListCheck[0].reduivy__Start_Date_Non_TZ__c;
        eduInstitutionHoliday.reduivy__End_Date__c = sevListCheck[0].reduivy__Start_Date_Non_TZ__c;
        eduInstitutionHoliday.reduivy__Educational_Institution_Campus__c = sstWeekly.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__r.ParentId;

        reduivy__Holiday__c campusHoliday = new reduivy__Holiday__c();
        campusHoliday.Name = 'Campus Holiday';
        campusHoliday.reduivy__Start_Date__c = sevListCheck[1].reduivy__Start_Date_Non_TZ__c;
        campusHoliday.reduivy__End_Date__c = sevListCheck[1].reduivy__Start_Date_Non_TZ__c;
        campusHoliday.reduivy__Educational_Institution_Campus__c = sstWeekly.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__c;

        newHolidays.add(eduInstitutionHoliday);
        newHolidays.add(campusHoliday);
        insert newHolidays;

        // Execute test
        Test.startTest();
        System.runAs(ADMIN_USER) {
            updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
            update updateSse;
        }

        Test.stopTest();

        sevListCheck.clear();
        for(reduivy__Study_Event__c sev : [SELECT Id, reduivy__Start_Date_Non_TZ__c, reduivy__End_Date_Non_TZ__c 
                                            FROM reduivy__Study_Event__c
                                            WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id]){

            sevListCheck.add(sev);
        }
        System.Assert.areEqual(20, sevListCheck.size(), '20 Study Events should be created for the Study Session Time configured with ignore holidays.');
    }

    /**
     * @description Test the weekly event creation from study session, with recreation method.
     */
    @IsTest
    static void testGenerateWeeklyEventsRecreate(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session_Time__c sstWeekly = [SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 1];
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        sstWeekly.reduivy__Update_Action__c = SST_Helper.UPDATE_ACTION_RECREATE;
        update sstWeekly;

        reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
        updateSse.Id = sstWeekly.reduivy__Study_Session__c;
        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
        update updateSse;

        Map<Id, reduivy__Study_Event__c> sevMapCheck = new Map<Id, reduivy__Study_Event__c>([SELECT Id, Name, reduivy__Start_Date_Non_TZ__c, reduivy__End_Date_Non_TZ__c FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id]);
        System.Assert.areEqual(20, sevMapCheck.size(), '20 Study Events should be created for the Study Session Time');
        
        // Execute test
        Test.startTest();
        System.runAs(ADMIN_USER) {
            updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
            update updateSse;
        }

        Test.stopTest();

        for(reduivy__Study_Event__c sev : [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id]){

            sevListCheck.add(sev);
            System.Assert.areEqual(false, sevMapCheck.containsKey(sev.Id), 'New list of Study Event should be created instead of upserting existing record.');
        }
        System.Assert.areEqual(20, sevListCheck.size(), '20 Study Events should be recreated for the Study Session Time');
        
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testGenerateDailyEvent(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session_Time__c sstWeekly = [SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Day_of_Week__c, reduivy__Recurrence__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 1];
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        sstWeekly.reduivy__Recurrence__c = SST_Helper.RECURRENCE_DAILY;
        sstWeekly.reduivy__End_Date__c = sstWeekly.reduivy__Start_Date__c.addDays(6);
        update sstWeekly;

        reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
        updateSse.Id = sstWeekly.reduivy__Study_Session__c;
        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;

        // Execute test
        Test.startTest();
        System.runAs(ADMIN_USER) {
            update updateSse;

            sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
            System.Assert.areEqual(7, sevListCheck.size(), '7 Study Events should be created for the Study Session Time');

            updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
            update updateSse;
        }

        Test.stopTest();

        sevListCheck.clear();
        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
        System.Assert.areEqual(7, sevListCheck.size(), '7 Study Events should be created for the Study Session Time');

    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testGenerateOneoffEvent(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session_Time__c targetSst = [SELECT Id, 
            Name,
            reduivy__Study_Session__c,
            reduivy__Start_Date__c,
            reduivy__Start_Time__c,
            reduivy__End_Date__c,
            reduivy__End_Time__c,
            reduivy__Default_Facility__c
            FROM reduivy__Study_Session_Time__c
            LIMIT 1
        ];

        reduivy__Study_Session_Time__c oneOffSst = REDU_TestData_UTIL.newStudySessionTime(
            'Exam',
            targetSst.reduivy__Study_Session__c,
            targetSst.reduivy__Default_Facility__c,
            'Workshop',
            null,
            'Friday',
            SST_Helper.RECURRENCE_ONEOFF,
            targetSst.reduivy__Start_Date__c,
            targetSst.reduivy__End_Date__c,
            targetSst.reduivy__Start_Time__c,
            targetSst.reduivy__End_Time__c
        );
        insert oneOffSst;

        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :oneOffSst.Id];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
        updateSse.Id = oneOffSst.reduivy__Study_Session__c;
        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;

        // Execute test
        Test.startTest();
        System.runAs(ADMIN_USER) {
            update updateSse;

            sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :oneOffSst.Id];
            System.Assert.areEqual(1, sevListCheck.size(), '1 Study Events should be created for the Study Session Time');

            updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
            update updateSse;
        }

        Test.stopTest();

        sevListCheck.clear();
        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :oneOffSst.Id];
        System.Assert.areEqual(1, sevListCheck.size(), '1 Study Events should be created for the Study Session Time');
    }

    /**
     * @description Test the Disburse Non Repayable/Repayable FA when the checkboxes are checked from study term (academic term).
     */
    @IsTest
    static void testGenerateBiweeklyEvents(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session_Time__c targetSst = [SELECT Id, 
            Name,
            reduivy__Study_Session__c,
            reduivy__Start_Date__c,
            reduivy__Start_Time__c,
            reduivy__End_Date__c,
            reduivy__End_Time__c,
            reduivy__Default_Facility__c
            FROM reduivy__Study_Session_Time__c
            LIMIT 1
        ];
        reduivy__Study_Session_Time__c sstBiweekly = REDU_TestData_UTIL.newStudySessionTime(
            'Workshop',
            targetSst.reduivy__Study_Session__c,
            targetSst.reduivy__Default_Facility__c,
            'Workshop',
            null,
            'Friday',
            SST_Helper.RECURRENCE_BIWEEKLY,
            targetSst.reduivy__Start_Date__c,
            targetSst.reduivy__End_Date__c,
            targetSst.reduivy__Start_Time__c,
            targetSst.reduivy__End_Time__c
        );
        insert sstBiweekly;
        
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstBiweekly.Id];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
        updateSse.Id = sstBiweekly.reduivy__Study_Session__c;
        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;

        // Execute test
        Test.startTest();
        System.runAs(ADMIN_USER) {
            update updateSse;
        }

        Test.stopTest();

        sevListCheck.clear();
        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstBiweekly.Id];
        System.Assert.areEqual(10, sevListCheck.size(), '10 Study Events should be created for the Study Session Time');
    }

    /**
     * @description Benchmark - Test 1 session with 1 session time.
     * Occurrence = every monday
     * Time 9am - 10am
     * Date range = 3 months
     */
    @IsTest
    static void testGenerateWeeklyEvents1Sse3Months(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session_Time__c sstWeekly = [SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Start_Time__c, reduivy__End_Time__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 1];
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');
        System.Assert.areEqual(true, String.isNotBlank(String.valueOf(sstWeekly.reduivy__Start_Date__c)), 'Study Session Time\'s start date shouldn\'t be empty.');

        sstWeekly.reduivy__End_Date__c = sstWeekly.reduivy__Start_Date__c.addDays(90);
        sstWeekly.reduivy__Start_Time__c = Time.newInstance(9, 0, 0, 0);
        sstWeekly.reduivy__End_Time__c = Time.newInstance(10, 0, 0, 0);
        update sstWeekly;

        reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
        updateSse.Id = sstWeekly.reduivy__Study_Session__c;
        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;

        // Execute test
        Decimal cpuTimeBefore;
        Decimal cpuTimeAfter;

        Test.startTest();
        System.runAs(ADMIN_USER) {
            cpuTimeBefore = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time Before Generate :: 1 Session x 1 Session Time x 3 Months - ', cpuTimeBefore);
            update updateSse;
            cpuTimeAfter = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time After Generate :: 1 Session x 1 Session Time x 3 Months -', cpuTimeAfter);
        }

        Test.stopTest();

        sevListCheck.clear();
        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
        System.Assert.areEqual(13, sevListCheck.size(), '13 Study Events should be created for the Study Session Time');
        System.Assert.isTrue((cpuTimeBefore - cpuTimeAfter) < 300, 'CPU Time Limit should be below 0.3 seconds.');
    }

    /**
     * @description Benchmark - Test 1 session with 1 session time.
     * Occurrence = every monday
     * Time 9am - 10am
     * Date range = 6 months
     */
    @IsTest
    static void testGenerateWeeklyEvents1Sse6Months(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session_Time__c sstWeekly = [SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Start_Time__c, reduivy__End_Time__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 1];
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');
        System.Assert.areEqual(true, String.isNotBlank(String.valueOf(sstWeekly.reduivy__Start_Date__c)), 'Study Session Time\'s start date shouldn\'t be empty.');

        sstWeekly.reduivy__End_Date__c = sstWeekly.reduivy__Start_Date__c.addDays(181);
        sstWeekly.reduivy__Start_Time__c = Time.newInstance(9, 0, 0, 0);
        sstWeekly.reduivy__End_Time__c = Time.newInstance(10, 0, 0, 0);
        update sstWeekly;

        reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
        updateSse.Id = sstWeekly.reduivy__Study_Session__c;
        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;

        // Execute test
        Decimal cpuTimeBefore;
        Decimal cpuTimeAfter;
        Test.startTest();

        System.runAs(ADMIN_USER) {
            cpuTimeBefore = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time Before Generate :: 1 Session x 1 Session Time x 6 Months - ', cpuTimeBefore);
            update updateSse;
            cpuTimeAfter = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time After Generate :: 1 Session x 1 Session Time x 6 Months -', cpuTimeAfter);
        }

        Test.stopTest();

        sevListCheck.clear();
        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
        System.Assert.areEqual(26, sevListCheck.size(), '26 Study Events should be created for the Study Session Time');
        System.Assert.isTrue((cpuTimeBefore - cpuTimeAfter) < 500, 'CPU Time Limit should be below 0.5 seconds.');
    }

    /**
     * @description Benchmark - Test 1 session with 1 session time.
     * Occurrence = every monday
     * Time 9am - 10am
     * Date range = 12 months
     */
    @IsTest
    static void testGenerateWeeklyEvents1Sse12Months(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session_Time__c sstWeekly = [SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Start_Time__c, reduivy__End_Time__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 1];
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');
        System.Assert.areEqual(true, String.isNotBlank(String.valueOf(sstWeekly.reduivy__Start_Date__c)), 'Study Session Time\'s start date shouldn\'t be empty.');

        sstWeekly.reduivy__End_Date__c = sstWeekly.reduivy__Start_Date__c.addDays(363);
        sstWeekly.reduivy__Start_Time__c = Time.newInstance(9, 0, 0, 0);
        sstWeekly.reduivy__End_Time__c = Time.newInstance(10, 0, 0, 0);
        update sstWeekly;

        reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
        updateSse.Id = sstWeekly.reduivy__Study_Session__c;
        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;

        // Execute test
        Decimal cpuTimeBefore;
        Decimal cpuTimeAfter;
        Test.startTest();

        System.runAs(ADMIN_USER) {
            cpuTimeBefore = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time Before Generate :: 1 Session x 1 Session Time x 12 Months - ', cpuTimeBefore);
            update updateSse;
            cpuTimeAfter = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time After Generate :: 1 Session x 1 Session Time x 12 Months -', cpuTimeAfter);
        }        

        Test.stopTest();

        sevListCheck.clear();
        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
        System.Assert.areEqual(52, sevListCheck.size(), '52 Study Events should be created for the Study Session Time');
        System.Assert.isTrue((cpuTimeBefore - cpuTimeAfter) < 1000, 'CPU Time Limit should be below 1 seconds.');
    }

    /**
     * @description Benchmark - Test 5 session with 1 session time.
     * Occurrence = every monday
     * Time 9am - 10am
     * Date range = 3 months
     */
    @IsTest
    static void testGenerateWeeklyEvents5Sse3Months(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Study_Session_Time__c> sstWeeklyMap = new Map<Id, reduivy__Study_Session_Time__c>([SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Start_Time__c, reduivy__End_Time__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 5]);
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeeklyMap.keySet()];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        Map<Id, reduivy__Study_Session__c> updateSseMap = new Map<Id, reduivy__Study_Session__c>();
        for(reduivy__Study_Session_Time__c sst : sstWeeklyMap.values()){

            System.Assert.areEqual(true, String.isNotBlank(String.valueOf(sst.reduivy__Start_Date__c)), 'Study Session Time\'s start date shouldn\'t be empty.');
            sst.reduivy__End_Date__c = sst.reduivy__Start_Date__c.addDays(90);
            sst.reduivy__Start_Time__c = Time.newInstance(9, 0, 0, 0);
            sst.reduivy__End_Time__c = Time.newInstance(10, 0, 0, 0);

            if(!updateSseMap.containsKey(sst.reduivy__Study_Session__c)){
                
                reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
                updateSse.Id = sst.reduivy__Study_Session__c;
                updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
                
                updateSseMap.put(updateSse.Id, updateSse);
            }
        }

        update sstWeeklyMap.values();

        // Execute test
        Decimal cpuTimeBefore;
        Decimal cpuTimeAfter;
        Test.startTest();

        System.runAs(ADMIN_USER) {
            cpuTimeBefore = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time Before Generate :: 5 Sessions x 1 Session Time x 3 Months - ', cpuTimeBefore);
            update updateSseMap.values();
            cpuTimeAfter = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time After Generate :: 5 Sessions x 1 Session Time x 3 Months -', cpuTimeAfter);
        }

        Test.stopTest();

        sevListCheck.clear();
        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeeklyMap.keySet()];
        System.Assert.areEqual(65, sevListCheck.size(), '65 Study Events should be created for the Study Session Times (13 * 5)');
        System.Assert.isTrue((cpuTimeBefore - cpuTimeAfter) < 400, 'CPU Time Limit should be below 0.4 seconds.');
    }

    /**
     * @description Benchmark - Test 5 session with 1 session time.
     * Occurrence = every monday
     * Time 9am - 10am
     * Date range = 6 months
     */
    @IsTest
    static void testGenerateWeeklyEvents5Sse6Months(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Study_Session_Time__c> sstWeeklyMap = new Map<Id, reduivy__Study_Session_Time__c>([SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Start_Time__c, reduivy__End_Time__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 5]);
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeeklyMap.keySet()];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        Map<Id, reduivy__Study_Session__c> updateSseMap = new Map<Id, reduivy__Study_Session__c>();
        for(reduivy__Study_Session_Time__c sst : sstWeeklyMap.values()){

            System.Assert.areEqual(true, String.isNotBlank(String.valueOf(sst.reduivy__Start_Date__c)), 'Study Session Time\'s start date shouldn\'t be empty.');
            sst.reduivy__End_Date__c = sst.reduivy__Start_Date__c.addDays(181);
            sst.reduivy__Start_Time__c = Time.newInstance(9, 0, 0, 0);
            sst.reduivy__End_Time__c = Time.newInstance(10, 0, 0, 0);

            if(!updateSseMap.containsKey(sst.reduivy__Study_Session__c)){
                
                reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
                updateSse.Id = sst.reduivy__Study_Session__c;
                updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
                
                updateSseMap.put(updateSse.Id, updateSse);
            }
        }

        update sstWeeklyMap.values();

        // Execute test
        Decimal cpuTimeBefore;
        Decimal cpuTimeAfter;
        Test.startTest();

        System.runAs(ADMIN_USER) {
            cpuTimeBefore = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time Before Generate :: 5 Sessions x 1 Session Time x 6 Months - ', cpuTimeBefore);
            update updateSseMap.values();
            cpuTimeAfter = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time After Generate :: 5 Sessions x 1 Session Time x 6 Months -', cpuTimeAfter);
        }

        Test.stopTest();

        sevListCheck.clear();
        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeeklyMap.keySet()];
        System.Assert.areEqual(130, sevListCheck.size(), '130 Study Events should be created for the Study Session Times (26 * 5)');
        System.Assert.isTrue((cpuTimeBefore - cpuTimeAfter) < 750, 'CPU Time Limit should be below 0.75 seconds.');
    }

    /**
     * @description Benchmark - Test 5 session with 1 session time.
     * Occurrence = every monday
     * Time 9am - 10am
     * Date range = 12 months
     */
    @IsTest
    static void testGenerateWeeklyEvents5Sse12Months(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Study_Session_Time__c> sstWeeklyMap = new Map<Id, reduivy__Study_Session_Time__c>([SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Start_Time__c, reduivy__End_Time__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 5]);
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeeklyMap.keySet()];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        Map<Id, reduivy__Study_Session__c> updateSseMap = new Map<Id, reduivy__Study_Session__c>();
        for(reduivy__Study_Session_Time__c sst : sstWeeklyMap.values()){

            System.Assert.areEqual(true, String.isNotBlank(String.valueOf(sst.reduivy__Start_Date__c)), 'Study Session Time\'s start date shouldn\'t be empty.');
            sst.reduivy__End_Date__c = sst.reduivy__Start_Date__c.addDays(363);
            sst.reduivy__Start_Time__c = Time.newInstance(9, 0, 0, 0);
            sst.reduivy__End_Time__c = Time.newInstance(10, 0, 0, 0);

            if(!updateSseMap.containsKey(sst.reduivy__Study_Session__c)){

                reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
                updateSse.Id = sst.reduivy__Study_Session__c;
                updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
                
                updateSseMap.put(updateSse.Id, updateSse);
            }
        }

        update sstWeeklyMap.values();

        // Execute test
        Decimal cpuTimeBefore;
        Decimal cpuTimeAfter;
        Test.startTest();

        System.runAs(ADMIN_USER) {
            cpuTimeBefore = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time Before Generate :: 5 Sessions x 1 Session Time x 12 Months - ', cpuTimeBefore);
            update updateSseMap.values();
            cpuTimeAfter = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time After Generate :: 5 Sessions x 1 Session Time x 12 Months -', cpuTimeAfter);
        }

        Test.stopTest();

        sevListCheck.clear();
        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeeklyMap.keySet()];
        System.Assert.areEqual(260, sevListCheck.size(), '260 Study Events should be created for the Study Session Times (52 * 5)');
        System.Assert.isTrue((cpuTimeBefore - cpuTimeAfter) < 1500, 'CPU Time Limit should be below 1.5 seconds.');
    }

    /**
     * @description Benchmark - Test 1 session with 5 session time.
     * Occurrence = every monday
     * Time 9am - 10am
     * Date range = 3 months
     */
    @IsTest
    static void testGenerateWeeklyEvents1Sse5Sst3Months(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Study_Session_Time__c> sstWeeklyMap = new Map<Id, reduivy__Study_Session_Time__c>([SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Start_Time__c, reduivy__End_Time__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 1]);
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeeklyMap.keySet()];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        Map<Id, reduivy__Study_Session__c> updateSseMap = new Map<Id, reduivy__Study_Session__c>();
        List<reduivy__Study_Session_Time__c> newSstList = new List<reduivy__Study_Session_Time__c>();
        for(reduivy__Study_Session_Time__c sst : sstWeeklyMap.values()){

            System.Assert.areEqual(true, String.isNotBlank(String.valueOf(sst.reduivy__Start_Date__c)), 'Study Session Time\'s start date shouldn\'t be empty.');
            sst.reduivy__End_Date__c = sst.reduivy__Start_Date__c.addDays(90);
            sst.reduivy__Start_Time__c = Time.newInstance(9, 0, 0, 0);
            sst.reduivy__End_Time__c = Time.newInstance(10, 0, 0, 0);

            Integer i = 0;
            while (i < 4) {
                
                newSstList.add(REDU_TestData_UTIL.newStudySessionTime('Mon(9-10)_' + i, sst.reduivy__Study_Session__c, null,'Lecture - Monday (' + i + ')', null, 'Monday', 'Weekly', sst.reduivy__Start_Date__c, sst.reduivy__End_Date__c, sst.reduivy__Start_Time__c, sst.reduivy__End_Time__c));
                i++;
            }

            if(!updateSseMap.containsKey(sst.reduivy__Study_Session__c)){
                
                reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
                updateSse.Id = sst.reduivy__Study_Session__c;
                updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
                
                updateSseMap.put(updateSse.Id, updateSse);
            }
        }

        update sstWeeklyMap.values();
        insert newSstList;

        // Execute test
        Decimal cpuTimeBefore;
        Decimal cpuTimeAfter;
        Test.startTest();

        System.runAs(ADMIN_USER) {
            cpuTimeBefore = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time Before Generate :: 1 Session x 5 Session Time x 3 Months - ', cpuTimeBefore);
            update updateSseMap.values();
            cpuTimeAfter = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time After Generate :: 1 Session x 5 Session Time x 3 Months -', cpuTimeAfter);
        }

        Test.stopTest();

        sevListCheck.clear();
        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :updateSseMap.keySet()];
        System.Assert.areEqual(65, sevListCheck.size(), '65 Study Events should be created for the Study Session Times (13 * 5)');
        System.Assert.isTrue((cpuTimeBefore - cpuTimeAfter) < 400, 'CPU Time Limit should be below 0.4 seconds.');
    }

    /**
     * @description Benchmark - Test 1 session with 5 session time.
     * Occurrence = every monday
     * Time 9am - 10am
     * Date range = 6 months
     */
    @IsTest
    static void testGenerateWeeklyEvents1Sse5Sst6Months(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Study_Session_Time__c> sstWeeklyMap = new Map<Id, reduivy__Study_Session_Time__c>([SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Start_Time__c, reduivy__End_Time__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 1]);
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeeklyMap.keySet()];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        Map<Id, reduivy__Study_Session__c> updateSseMap = new Map<Id, reduivy__Study_Session__c>();
        List<reduivy__Study_Session_Time__c> newSstList = new List<reduivy__Study_Session_Time__c>();
        for(reduivy__Study_Session_Time__c sst : sstWeeklyMap.values()){

            System.Assert.areEqual(true, String.isNotBlank(String.valueOf(sst.reduivy__Start_Date__c)), 'Study Session Time\'s start date shouldn\'t be empty.');
            sst.reduivy__End_Date__c = sst.reduivy__Start_Date__c.addDays(181);
            sst.reduivy__Start_Time__c = Time.newInstance(9, 0, 0, 0);
            sst.reduivy__End_Time__c = Time.newInstance(10, 0, 0, 0);

            Integer i = 0;
            while (i < 4) {
                
                newSstList.add(REDU_TestData_UTIL.newStudySessionTime('Mon(9-10)_' + i, sst.reduivy__Study_Session__c, null,'Lecture - Monday (' + i + ')', null, 'Monday', 'Weekly', sst.reduivy__Start_Date__c, sst.reduivy__End_Date__c, sst.reduivy__Start_Time__c, sst.reduivy__End_Time__c));
                i++;
            }

            if(!updateSseMap.containsKey(sst.reduivy__Study_Session__c)){
                
                reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
                updateSse.Id = sst.reduivy__Study_Session__c;
                updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
                
                updateSseMap.put(updateSse.Id, updateSse);
            }
        }

        update sstWeeklyMap.values();
        insert newSstList;

        // Execute test
        Decimal cpuTimeBefore;
        Decimal cpuTimeAfter;
        Test.startTest();

        System.runAs(ADMIN_USER) {
            cpuTimeBefore = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time Before Generate :: 1 Session x 5 Session Time x 6 Months - ', cpuTimeBefore);
            update updateSseMap.values();
            cpuTimeAfter = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time After Generate :: 1 Session x 5 Session Time x 6 Months -', cpuTimeAfter);
        }

        Test.stopTest();

        sevListCheck.clear();
        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :updateSseMap.keySet()];
        System.Assert.areEqual(130, sevListCheck.size(), '130 Study Events should be created for the Study Session Times (26 * 5)');
        System.Assert.isTrue((cpuTimeBefore - cpuTimeAfter) < 750, 'CPU Time Limit should be below 0.75 seconds.');
    }

    /**
     * @description Benchmark - Test 1 session with 5 session time.
     * Occurrence = every monday
     * Time 9am - 10am
     * Date range = 12 months
     */
    @IsTest
    static void testGenerateWeeklyEvents1Sse5Sst12Months(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Study_Session_Time__c> sstWeeklyMap = new Map<Id, reduivy__Study_Session_Time__c>([SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Start_Time__c, reduivy__End_Time__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 1]);
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeeklyMap.keySet()];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        Map<Id, reduivy__Study_Session__c> updateSseMap = new Map<Id, reduivy__Study_Session__c>();
        List<reduivy__Study_Session_Time__c> newSstList = new List<reduivy__Study_Session_Time__c>();
        for(reduivy__Study_Session_Time__c sst : sstWeeklyMap.values()){

            System.Assert.areEqual(true, String.isNotBlank(String.valueOf(sst.reduivy__Start_Date__c)), 'Study Session Time\'s start date shouldn\'t be empty.');
            sst.reduivy__End_Date__c = sst.reduivy__Start_Date__c.addDays(363);
            sst.reduivy__Start_Time__c = Time.newInstance(9, 0, 0, 0);
            sst.reduivy__End_Time__c = Time.newInstance(10, 0, 0, 0);

            Integer i = 0;
            while (i < 4) {
                
                newSstList.add(REDU_TestData_UTIL.newStudySessionTime('Mon(9-10)_' + i, sst.reduivy__Study_Session__c, null,'Lecture - Monday (' + i + ')', null, 'Monday', 'Weekly', sst.reduivy__Start_Date__c, sst.reduivy__End_Date__c, sst.reduivy__Start_Time__c, sst.reduivy__End_Time__c));
                i++;
            }

            if(!updateSseMap.containsKey(sst.reduivy__Study_Session__c)){
                
                reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
                updateSse.Id = sst.reduivy__Study_Session__c;
                updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
                
                updateSseMap.put(updateSse.Id, updateSse);
            }
        }

        update sstWeeklyMap.values();
        insert newSstList;
        
        // Execute test
        Decimal cpuTimeBefore;
        Decimal cpuTimeAfter;
        Test.startTest();

        System.runAs(ADMIN_USER) {
            cpuTimeBefore = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time Before Generate :: 1 Session x 5 Session Time x 12 Months - ', cpuTimeBefore);
            update updateSseMap.values();
            cpuTimeAfter = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time After Generate :: 1 Session x 5 Session Time x 12 Months -', cpuTimeAfter);
        }

        Test.stopTest();

        sevListCheck.clear();
        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :updateSseMap.keySet()];
        System.Assert.areEqual(260, sevListCheck.size(), '260 Study Events should be created for the Study Session Times (52 * 5)');
        System.Assert.isTrue((cpuTimeBefore - cpuTimeAfter) < 1500, 'CPU Time Limit should be below 1.5 seconds.');
    }

    /**
     * @description Benchmark - Test 5 session with 5 session time.
     * Occurrence = every monday
     * Time 9am - 10am
     * Date range = 3 months
     */
    @IsTest
    static void testGenerateWeeklyEvents5Sse5Sst3Months(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Study_Session_Time__c> sstWeeklyMap = new Map<Id, reduivy__Study_Session_Time__c>([SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Start_Time__c, reduivy__End_Time__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 5]);
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeeklyMap.keySet()];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        Map<Id, reduivy__Study_Session__c> updateSseMap = new Map<Id, reduivy__Study_Session__c>();
        List<reduivy__Study_Session_Time__c> newSstList = new List<reduivy__Study_Session_Time__c>();
        for(reduivy__Study_Session_Time__c sst : sstWeeklyMap.values()){

            System.Assert.areEqual(true, String.isNotBlank(String.valueOf(sst.reduivy__Start_Date__c)), 'Study Session Time\'s start date shouldn\'t be empty.');
            sst.reduivy__End_Date__c = sst.reduivy__Start_Date__c.addDays(90);
            sst.reduivy__Start_Time__c = Time.newInstance(9, 0, 0, 0);
            sst.reduivy__End_Time__c = Time.newInstance(10, 0, 0, 0);

            Integer i = 0;
            while (i < 4) {
                
                newSstList.add(REDU_TestData_UTIL.newStudySessionTime('Mon(9-10)_' + i, sst.reduivy__Study_Session__c, null,'Lecture - Monday (' + i + ')', null, 'Monday', 'Weekly', sst.reduivy__Start_Date__c, sst.reduivy__End_Date__c, sst.reduivy__Start_Time__c, sst.reduivy__End_Time__c));
                i++;
            }

            if(!updateSseMap.containsKey(sst.reduivy__Study_Session__c)){
                
                reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
                updateSse.Id = sst.reduivy__Study_Session__c;
                updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
                
                updateSseMap.put(updateSse.Id, updateSse);
            }
        }

        update sstWeeklyMap.values();
        insert newSstList;

        // Execute test
        Decimal cpuTimeBefore;
        Decimal cpuTimeAfter;
        Test.startTest();

        System.runAs(ADMIN_USER) {
            cpuTimeBefore = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time Before Generate :: 5 Sessions x 5 Session Time x 3 Months - ', cpuTimeBefore);
            update updateSseMap.values();
            cpuTimeAfter = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time After Generate :: 5 Sessions x 5 Session Time x 3 Months -', cpuTimeAfter);
        }

        Test.stopTest();

        sevListCheck.clear();
        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :updateSseMap.keySet()];
        System.Assert.areEqual(325, sevListCheck.size(), '325 Study Events should be created for the Study Session Times (13 * 5 * 5)');
        System.Assert.isTrue((cpuTimeBefore - cpuTimeAfter) < 1750, 'CPU Time Limit should be below 1.75 seconds.');
    }

    /**
     * @description Benchmark - Test 5 session with 5 session time.
     * Occurrence = every monday
     * Time 9am - 10am
     * Date range = 6 months
     */
    @IsTest
    static void testGenerateWeeklyEvents5Sse5Sst6Months(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Study_Session_Time__c> sstWeeklyMap = new Map<Id, reduivy__Study_Session_Time__c>([SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Start_Time__c, reduivy__End_Time__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 5]);
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeeklyMap.keySet()];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        Map<Id, reduivy__Study_Session__c> updateSseMap = new Map<Id, reduivy__Study_Session__c>();
        List<reduivy__Study_Session_Time__c> newSstList = new List<reduivy__Study_Session_Time__c>();
        for(reduivy__Study_Session_Time__c sst : sstWeeklyMap.values()){

            System.Assert.areEqual(true, String.isNotBlank(String.valueOf(sst.reduivy__Start_Date__c)), 'Study Session Time\'s start date shouldn\'t be empty.');
            sst.reduivy__End_Date__c = sst.reduivy__Start_Date__c.addDays(181);
            sst.reduivy__Start_Time__c = Time.newInstance(9, 0, 0, 0);
            sst.reduivy__End_Time__c = Time.newInstance(10, 0, 0, 0);

            Integer i = 0;
            while (i < 4) {
                
                newSstList.add(REDU_TestData_UTIL.newStudySessionTime('Mon(9-10)_' + i, sst.reduivy__Study_Session__c, null,'Lecture - Monday (' + i + ')', null, 'Monday', 'Weekly', sst.reduivy__Start_Date__c, sst.reduivy__End_Date__c, sst.reduivy__Start_Time__c, sst.reduivy__End_Time__c));
                i++;
            }

            if(!updateSseMap.containsKey(sst.reduivy__Study_Session__c)){
                
                reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
                updateSse.Id = sst.reduivy__Study_Session__c;
                updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
                
                updateSseMap.put(updateSse.Id, updateSse);
            }
        }

        update sstWeeklyMap.values();
        insert newSstList;

        // Execute test
        Decimal cpuTimeBefore;
        Decimal cpuTimeAfter;

        Test.startTest();

        System.runAs(ADMIN_USER) {
            cpuTimeBefore = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time Before Generate :: 5 Sessions x 5 Session Time x 6 Months - ', cpuTimeBefore);
            update updateSseMap.values();
            cpuTimeAfter = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time After Generate :: 5 Sessions x 5 Session Time x 6 Months -', cpuTimeAfter);
        }

        Test.stopTest();

        sevListCheck.clear();
        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :updateSseMap.keySet()];
        System.Assert.areEqual(650, sevListCheck.size(), '650 Study Events should be created for the Study Session Times (26 * 5 * 5)');
        System.Assert.isTrue((cpuTimeBefore - cpuTimeAfter) < 2500, 'CPU Time Limit should be below 2.5 seconds.');
    }

    /**
     * @description Benchmark - Test 5 session with 5 session time.
     * Occurrence = every monday
     * Time 9am - 10am
     * Date range = 12 months
     */
    @IsTest
    static void testGenerateWeeklyEvents5Sse5Sst12Months(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Study_Session_Time__c> sstWeeklyMap = new Map<Id, reduivy__Study_Session_Time__c>([SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Start_Time__c, reduivy__End_Time__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 5]);
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeeklyMap.keySet()];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        Map<Id, reduivy__Study_Session__c> updateSseMap = new Map<Id, reduivy__Study_Session__c>();
        List<reduivy__Study_Session_Time__c> newSstList = new List<reduivy__Study_Session_Time__c>();
        for(reduivy__Study_Session_Time__c sst : sstWeeklyMap.values()){

            System.Assert.areEqual(true, String.isNotBlank(String.valueOf(sst.reduivy__Start_Date__c)), 'Study Session Time\'s start date shouldn\'t be empty.');
            sst.reduivy__End_Date__c = sst.reduivy__Start_Date__c.addDays(363);
            sst.reduivy__Start_Time__c = Time.newInstance(9, 0, 0, 0);
            sst.reduivy__End_Time__c = Time.newInstance(10, 0, 0, 0);

            Integer i = 0;
            while (i < 4) {
                
                newSstList.add(REDU_TestData_UTIL.newStudySessionTime('Mon(9-10)_' + i, sst.reduivy__Study_Session__c, null,'Lecture - Monday (' + i + ')', null, 'Monday', 'Weekly', sst.reduivy__Start_Date__c, sst.reduivy__End_Date__c, sst.reduivy__Start_Time__c, sst.reduivy__End_Time__c));
                i++;
            }

            if(!updateSseMap.containsKey(sst.reduivy__Study_Session__c)){
                
                reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
                updateSse.Id = sst.reduivy__Study_Session__c;
                updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
                
                updateSseMap.put(updateSse.Id, updateSse);
            }
        }

        update sstWeeklyMap.values();
        insert newSstList;

        // Execute test
        Decimal cpuTimeBefore;
        Decimal cpuTimeAfter;
        Test.startTest();

        System.runAs(ADMIN_USER) {
            cpuTimeBefore = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time Before Generate :: 5 Sessions x 5 Session Time x 12 Months - ', cpuTimeBefore);
            update updateSseMap.values();
            cpuTimeAfter = Limits.getCpuTime();
            REDU_Logging_UTIL.debug('CPU Time After Generate :: 5 Sessions x 5 Session Time x 12 Months -', cpuTimeAfter);
        }

        Test.stopTest();

        sevListCheck.clear();
        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :updateSseMap.keySet()];
        System.Assert.areEqual(1300, sevListCheck.size(), '1300 Study Events should be created for the Study Session Times (52 * 5 * 5)');
        System.Assert.isTrue((cpuTimeBefore - cpuTimeAfter) < 5000, 'CPU Time Limit should be below 5 seconds.');
    }

    /**
     * @description Test regenerate study events after the sst time is updated (recurrence = weekly)
     */
    @IsTest
    static void testSstDateUpdatedWeekly(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session_Time__c sstWeekly = [SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 1];
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        integer numberDayBetween = sstWeekly.reduivy__Start_Date__c.daysBetween(sstWeekly.reduivy__End_Date__c);
 
        update sstWeekly;

        reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
        updateSse.Id = sstWeekly.reduivy__Study_Session__c;
        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;

        update updateSse;
        
        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];

        System.Assert.areEqual(20, sevListCheck.size(), '20 Study Events should be created for the Study Session Time');

        //now we change the start date and generate again, the out of range sevs should be deleted
        sstWeekly.reduivy__Start_Date__c = sstWeekly.reduivy__Start_Date__c.addDays(14);
        update sstWeekly;

        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
        // Execute test
        Test.startTest();

        System.runAs(ADMIN_USER) {
            update updateSse;
        }

        Test.stopTest();

        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];

        System.Assert.areEqual(18, sevListCheck.size(), '18 Study Events should be created for the Study Session Time');
    }

    /**
     * @description Test regenerate study events after the sst time is updated (recurrence = daily)
     */
    @IsTest
    static void testSstDateUpdatedDaily(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session_Time__c sstWeekly = [SELECT Id, reduivy__Study_Session__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Day_of_Week__c, reduivy__Recurrence__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Recurrence__c = :SST_Helper.RECURRENCE_WEEKLY AND reduivy__Study_Session__r.reduivy__Type__c = 'Lecture' LIMIT 1];
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        sstWeekly.reduivy__Recurrence__c = SST_Helper.RECURRENCE_DAILY;
        sstWeekly.reduivy__End_Date__c = sstWeekly.reduivy__Start_Date__c.addDays(6);
        update sstWeekly;

        reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
        updateSse.Id = sstWeekly.reduivy__Study_Session__c;
        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;

        update updateSse;

        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
        System.Assert.areEqual(7, sevListCheck.size(), '7 Study Events should be created for the Study Session Time');

        //now we change the start date and generate again, the out of range sevs should be deleted
        sstWeekly.reduivy__Start_Date__c = sstWeekly.reduivy__Start_Date__c.addDays(1);
        sstWeekly.reduivy__Day_of_Week__c = SST_Helper.DAY_OF_WEEK_TUESDAY;
        sstWeekly.reduivy__End_Date__c = sstWeekly.reduivy__End_Date__c.addDays(-1);
        sstWeekly.reduivy__Recurrence__c = SST_Helper.RECURRENCE_DAILY;
        update sstWeekly;
        
        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;

        // Execute test
        Test.startTest();
        System.runAs(ADMIN_USER) {
            update updateSse;
        }
        Test.stopTest();

        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstWeekly.Id];
        System.Assert.areEqual(5, sevListCheck.size(), '5 Study Events should be created for the Study Session Time');


    }

    
    /**
     * @description Test regenerate study events after the sst time is updated (recurrence = biweekly)
     */
    @IsTest
    static void testSstDateUpdatedBiweekly(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session_Time__c targetSst = [SELECT Id, 
            Name,
            reduivy__Study_Session__c,
            reduivy__Start_Date__c,
            reduivy__Start_Time__c,
            reduivy__End_Date__c,
            reduivy__End_Time__c,
            reduivy__Default_Facility__c
            FROM reduivy__Study_Session_Time__c
            LIMIT 1
        ];
        reduivy__Study_Session_Time__c sstBiweekly = REDU_TestData_UTIL.newStudySessionTime(
            'Workshop',
            targetSst.reduivy__Study_Session__c,
            targetSst.reduivy__Default_Facility__c,
            'Workshop',
            null,
            'Friday',
            SST_Helper.RECURRENCE_BIWEEKLY,
            targetSst.reduivy__Start_Date__c,
            targetSst.reduivy__End_Date__c,
            targetSst.reduivy__Start_Time__c,
            targetSst.reduivy__End_Time__c
        );
        insert sstBiweekly;
        
        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstBiweekly.Id];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
        updateSse.Id = sstBiweekly.reduivy__Study_Session__c;
        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
        update updateSse; 

        sevListCheck.clear();
        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstBiweekly.Id];
        System.Assert.areEqual(10, sevListCheck.size(), '10 Study Events should be created for the Study Session Time');

        //now we change the start date and generate again, the out of range sevs should be deleted
        sstBiweekly.reduivy__Start_Date__c = sstBiweekly.reduivy__Start_Date__c.addDays(21);
        update sstBiweekly;
        
        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
        
        // Execute test
        Test.startTest();
        System.runAs(ADMIN_USER) {
            update updateSse; 
        }

        sevListCheck = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :sstBiweekly.Id];
        System.Assert.areEqual(9, sevListCheck.size(), '9 Study Events should be created for the Study Session Time');
        

        Test.stopTest();
    }

    
    /**
     * @description Test regenerate study events after the sst time is updated (recurrence = oneoff)
     */
    @IsTest
    static void testSstDateUpdatedOneoff(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session_Time__c targetSst = [SELECT Id, 
            Name,
            reduivy__Study_Session__c,
            reduivy__Start_Date__c,
            reduivy__Start_Time__c,
            reduivy__End_Date__c,
            reduivy__End_Time__c,
            reduivy__Default_Facility__c
            FROM reduivy__Study_Session_Time__c
            LIMIT 1
        ];

        reduivy__Study_Session_Time__c oneOffSst = REDU_TestData_UTIL.newStudySessionTime(
            'Exam',
            targetSst.reduivy__Study_Session__c,
            targetSst.reduivy__Default_Facility__c,
            'Workshop',
            null,
            SST_Helper.DAY_OF_WEEK_MONDAY,
            SST_Helper.RECURRENCE_ONEOFF,
            targetSst.reduivy__Start_Date__c,
            targetSst.reduivy__End_Date__c,
            targetSst.reduivy__Start_Time__c,
            targetSst.reduivy__End_Time__c
        );
        insert oneOffSst;

        List<reduivy__Study_Event__c> sevListCheck = [SELECT Id, reduivy__Start_Date_Non_TZ__c FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :oneOffSst.Id];
        System.Assert.areEqual(true, sevListCheck.isEmpty(), 'No Event should be created for the Study Session Time yet');

        reduivy__Study_Session__c updateSse = new reduivy__Study_Session__c();
        updateSse.Id = oneOffSst.reduivy__Study_Session__c;
        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;

        update updateSse;

        sevListCheck = [SELECT Id, reduivy__Start_Date_Non_TZ__c FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :oneOffSst.Id];
        System.Assert.areEqual(1, sevListCheck.size(), '1 Study Events should be created for the Study Session Time');
        System.Assert.areEqual(targetSst.reduivy__Start_Date__c, sevListCheck[0].reduivy__Start_Date_Non_TZ__c);
        

        //now we change the start date and generate again, the out of range sevs should be deleted
        oneOffSst.reduivy__Start_Date__c = oneOffSst.reduivy__Start_Date__c.addDays(7);
        update oneOffSst;

        updateSse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;

        Test.startTest();
        System.runAs(ADMIN_USER) {
            update updateSse;
        }
        Test.stopTest();

        sevListCheck.clear();
        sevListCheck = [SELECT Id, reduivy__Start_Date_Non_TZ__c FROM reduivy__Study_Event__c WHERE reduivy__Study_Session_Time__c = :oneOffSst.Id];
        System.Assert.areEqual(1, sevListCheck.size(), '1 Study Events should be created for the Study Session Time');
        System.Assert.areEqual(targetSst.reduivy__Start_Date__c.addDays(7), sevListCheck[0].reduivy__Start_Date_Non_TZ__c);

    }

    
}