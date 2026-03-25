/**
 * @author      WDCi (XW)
 * @date        June 2024
 * @group       Test
 * @description Test class for SEV_CreateFacilityEventRelations_EXE
 * @changehistory
 * ISS-001922 18-06-2024 XW - create new class
 */
@IsTest
public inherited sharing class SEV_CreateFacilityEventRelations_TEST{
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String INSUFFICIENT_CREATABLE_ACCESS = 'Insufficient CREATABLE access';
    static final Map<String, Integer> DAY_OF_WEEK = new Map<String, Integer>{ 'Monday' => 0, 'Tuesday' => 1, 'Wednesday' => 2, 'Thursday' => 3, 'Friday' => 4, 'Saturday' => 5, 'Sunday' => 6 };
    /**
     * @description Default method to setup required data for automated test
     */
    @TestSetup
    static void makeData(){

        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER){
            Test.startTest();

            testFactory.initMasterData(null);
            testFactory.initOfferingData(SST_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);

            //delete sample availability to avoid confusion in test methods
            REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Facility_Availability__c]);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for creating a study event
     */
    @IsTest
    static void testCreateSingleEventAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Session_Time__c> sessionTimes = [SELECT Id, Name, reduivy__Default_Facility__c, reduivy__Start_Date__c, reduivy__Start_Time__c, reduivy__End_Date__c, reduivy__End_Time__c
                                                             FROM reduivy__Study_Session_Time__c
                                                             LIMIT 1];

        reduivy__Study_Event__c event;

        Datetime startDt = Datetime.newInstance(sessionTimes[0].reduivy__Start_Date__c, sessionTimes[0].reduivy__Start_Time__c);
        Datetime endDt = Datetime.newInstance(sessionTimes[0].reduivy__End_Date__c, sessionTimes[0].reduivy__End_Time__c);

        reduivy__Study_Event__c studyEvent = new reduivy__Study_Event__c(

            reduivy__Study_Session_Time__c = sessionTimes[0].Id, 
            Name = 'Test 1', 
            reduivy__Type__c = 'Study Session', 
            reduivy__Location__c = null, 
            reduivy__Status__c = 'Confirmed', 
            reduivy__Start__c = startDt, 
            reduivy__End__c = endDt, 
            reduivy__Start_Date_Non_TZ__c = startDt.date(), 
            reduivy__Start_Time_Non_TZ__c = startDt.time(), 
            reduivy__End_Date_Non_TZ__c = endDt.date(), 
            reduivy__End_Time_Non_TZ__c = endDt.time()
        );

        System.runAs(ADMIN_USER){


            Test.startTest();

            List<reduivy__Study_Event__c> studyEventList = new List<reduivy__Study_Event__c>{ studyEvent };
            REDU_Database_UTIL.doInsert(studyEventList);


            try{
                List<reduivy__Study_Event_Relation__c> eventRelationList = [SELECT Id, Name, reduivy__Facility__c
                                                                            FROM reduivy__Study_Event_Relation__c
                                                                            WHERE reduivy__Study_Event__r.Id = :studyEventList[0].Id];
                System.Assert.areEqual(1, eventRelationList.size(), 'Size of event relation list should be 1');
                System.Assert.areNotEqual(null, eventRelationList[0].reduivy__Facility__c, 'Facility is null.');
            } catch (Exception ex){
                System.Assert.fail('Should be able to find study event relation: ' + ex.getMessage());
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test as student for creating a study event
     */
    @IsTest
    static void testCreateSingleEventAsStudent(){

        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c
                                         FROM Contact
                                         WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT AND reduivy__Sample_Record_Code__c <> ''
                                         LIMIT 1];

        User studentUser = [SELECT Id, ContactId, ProfileId
                            FROM User
                            WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId IN:studentContacts
                            LIMIT 1];


        List<reduivy__Study_Session_Time__c> sessionTimes = [SELECT Id, Name, reduivy__Default_Facility__c, reduivy__Start_Date__c, reduivy__Start_Time__c, reduivy__End_Date__c, reduivy__End_Time__c
                                                             FROM reduivy__Study_Session_Time__c
                                                             LIMIT 1];

        reduivy__Study_Event__c event;

        Datetime startDt = Datetime.newInstance(sessionTimes[0].reduivy__Start_Date__c, sessionTimes[0].reduivy__Start_Time__c);
        Datetime endDt = Datetime.newInstance(sessionTimes[0].reduivy__End_Date__c, sessionTimes[0].reduivy__End_Time__c);

        reduivy__Study_Event__c studyEvent = new reduivy__Study_Event__c(

            reduivy__Study_Session_Time__c = sessionTimes[0].Id, 
            Name = 'Test 1', 
            reduivy__Type__c = 'Study Session', 
            reduivy__Location__c = null, 
            reduivy__Status__c = 'Confirmed', 
            reduivy__Start__c = startDt, 
            reduivy__End__c = endDt, 
            reduivy__Start_Date_Non_TZ__c = startDt.date(), 
            reduivy__Start_Time_Non_TZ__c = startDt.time(), 
            reduivy__End_Date_Non_TZ__c = endDt.date(), 
            reduivy__End_Time_Non_TZ__c = endDt.time()
        );
        List<reduivy__Study_Event__c> studyEventList = new List<reduivy__Study_Event__c>{ studyEvent };
        System.runAs(studentUser){
            Test.startTest();

            try{
                REDU_Database_UTIL.doInsert(studyEventList);


                System.Assert.fail('Should not be able to insert study event.');
            } catch (Exception ex){
                System.Assert.isTrue(ex.getMessage().contains(INSUFFICIENT_CREATABLE_ACCESS), 'Unexpected exception occurs: ' + ex.getMessage());
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for creating a study event
     */
    @IsTest
    static void testCreateSingleEventAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<reduivy__Study_Session_Time__c> sessionTimes = [SELECT Id, Name, reduivy__Default_Facility__c, reduivy__Start_Date__c, reduivy__Start_Time__c, reduivy__End_Date__c, reduivy__End_Time__c
                                                             FROM reduivy__Study_Session_Time__c
                                                             LIMIT 1];

        reduivy__Study_Event__c event;

        Datetime startDt = Datetime.newInstance(sessionTimes[0].reduivy__Start_Date__c, sessionTimes[0].reduivy__Start_Time__c);
        Datetime endDt = Datetime.newInstance(sessionTimes[0].reduivy__End_Date__c, sessionTimes[0].reduivy__End_Time__c);

        reduivy__Study_Event__c studyEvent = new reduivy__Study_Event__c(

            reduivy__Study_Session_Time__c = sessionTimes[0].Id, 
            Name = 'Test 1', 
            reduivy__Type__c = 'Study Session', 
            reduivy__Location__c = null, 
            reduivy__Status__c = 'Confirmed', 
            reduivy__Start__c = startDt, 
            reduivy__End__c = endDt, 
            reduivy__Start_Date_Non_TZ__c = startDt.date(), 
            reduivy__Start_Time_Non_TZ__c = startDt.time(), 
            reduivy__End_Date_Non_TZ__c = endDt.date(), 
            reduivy__End_Time_Non_TZ__c = endDt.time()
        );
        List<reduivy__Study_Event__c> studyEventList = new List<reduivy__Study_Event__c>{ studyEvent };
        System.runAs(FACULTY_USER){
            Test.startTest();

            try{
                REDU_Database_UTIL.doInsert(studyEventList);


                System.Assert.fail('Should not be able to insert study event.');
            } catch (Exception ex){
                System.Assert.isTrue(ex.getMessage().contains(INSUFFICIENT_CREATABLE_ACCESS), 'Unexpected exception occurs: ' + ex.getMessage());
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for creating multiple study events
     */
    @IsTest
    static void testCreateMultipleEventsAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Session_Time__c> sessionTimes = [SELECT Id, Name, reduivy__Default_Facility__c, reduivy__Start_Date__c, reduivy__Start_Time__c, reduivy__End_Date__c, reduivy__End_Time__c, reduivy__Day_of_Week__c
                                                             FROM reduivy__Study_Session_Time__c
                                                             LIMIT 1];

        List<reduivy__Study_Event__c> studyEventList = new List<reduivy__Study_Event__c>();
        Integer nameCounter = 0;
        Integer daysToAdd = DAY_OF_WEEK.get(sessionTimes[0].reduivy__Day_of_Week__c);

        for (Date currentDate = sessionTimes[0].reduivy__Start_Date__c.addDays(daysToAdd); currentDate <= sessionTimes[0].reduivy__End_Date__c; currentDate = currentDate.addDays(7)){
            Datetime startDt = Datetime.newInstance(currentDate, sessionTimes[0].reduivy__Start_Time__c);
            Datetime endDt = Datetime.newInstance(currentDate, sessionTimes[0].reduivy__End_Time__c);
            studyEventList.add(new reduivy__Study_Event__c(
                reduivy__Study_Session_Time__c = sessionTimes[0].Id, 
                Name = 'Test ' + nameCounter, 
                reduivy__Type__c = 'Study Session', 
                reduivy__Location__c = null, 
                reduivy__Status__c = 'Confirmed', 
                reduivy__Start__c = startDt, 
                reduivy__End__c = endDt, 
                reduivy__Start_Date_Non_TZ__c = startDt.date(), 
                reduivy__Start_Time_Non_TZ__c = startDt.time(), 
                reduivy__End_Date_Non_TZ__c = endDt.date(), 
                reduivy__End_Time_Non_TZ__c = endDt.time()
            ));
            nameCounter++;
        }

        System.runAs(ADMIN_USER){


            Test.startTest();

            REDU_Database_UTIL.doInsert(studyEventList);


            try{
                List<reduivy__Study_Event_Relation__c> eventRelationList = [SELECT Id, Name, reduivy__Facility__c
                                                                            FROM reduivy__Study_Event_Relation__c
                                                                            WHERE reduivy__Study_Event__r.Id IN:studyEventList];
                System.Assert.areEqual(nameCounter, eventRelationList.size(), 'Size of event list should be ' + nameCounter);
                for (Integer i = 0; i < nameCounter; i++){
                    System.Assert.areNotEqual(null, eventRelationList[i].reduivy__Facility__c, 'Facility is null.');
                }
            } catch (Exception ex){
                System.Assert.fail('Should be able to find study event relation: ' + ex.getMessage());
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test as student for creating multiple study events
     */
    @IsTest
    static void testCreateMultipleEventsAsStudent(){
        final Integer EVENT_COUNT = 5;

        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c
                                         FROM Contact
                                         WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT AND reduivy__Sample_Record_Code__c <> ''
                                         LIMIT 1];

        User studentUser = [SELECT Id, ContactId, ProfileId
                            FROM User
                            WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId IN:studentContacts
                            LIMIT 1];


        List<reduivy__Study_Session_Time__c> sessionTimes = [SELECT Id, Name, reduivy__Default_Facility__c, reduivy__Start_Date__c, reduivy__Start_Time__c, reduivy__End_Date__c, reduivy__End_Time__c
                                                             FROM reduivy__Study_Session_Time__c
                                                             LIMIT :EVENT_COUNT];

        List<reduivy__Study_Event__c> studyEventList = new List<reduivy__Study_Event__c>();
        for (Integer i = 0; i < EVENT_COUNT; i++){
            Datetime startDt = Datetime.newInstance(sessionTimes[i].reduivy__Start_Date__c, sessionTimes[i].reduivy__Start_Time__c);
            Datetime endDt = Datetime.newInstance(sessionTimes[i].reduivy__End_Date__c, sessionTimes[i].reduivy__End_Time__c);


            reduivy__Study_Event__c studyEvent = new reduivy__Study_Event__c(

                reduivy__Study_Session_Time__c = sessionTimes[i].Id, 
                Name = 'Test ' + (i + 1), 
                reduivy__Type__c = 'Study Session', 
                reduivy__Location__c = null, 
                reduivy__Status__c = 'Confirmed', 
                reduivy__Start__c = startDt, 
                reduivy__End__c = endDt, 
                reduivy__Start_Date_Non_TZ__c = startDt.date(), 
                reduivy__Start_Time_Non_TZ__c = startDt.time(), 
                reduivy__End_Date_Non_TZ__c = endDt.date(), 
                reduivy__End_Time_Non_TZ__c = endDt.time()
            );

            studyEventList.add(studyEvent);
        }

        System.runAs(studentUser){
            Test.startTest();

            try{
                REDU_Database_UTIL.doInsert(studyEventList);


                System.Assert.fail('Should not be able to insert study event.');
            } catch (Exception ex){
                System.Assert.isTrue(ex.getMessage().contains(INSUFFICIENT_CREATABLE_ACCESS), 'Unexpected exception occurs: ' + ex.getMessage());
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for creating multiple study events
     */
    @IsTest
    static void testCreateMultipleEventsAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        final Integer EVENT_COUNT = 5;

        List<reduivy__Study_Session_Time__c> sessionTimes = [SELECT Id, Name, reduivy__Default_Facility__c, reduivy__Start_Date__c, reduivy__Start_Time__c, reduivy__End_Date__c, reduivy__End_Time__c
                                                             FROM reduivy__Study_Session_Time__c
                                                             LIMIT :EVENT_COUNT];

        List<reduivy__Study_Event__c> studyEventList = new List<reduivy__Study_Event__c>();
        for (Integer i = 0; i < EVENT_COUNT; i++){
            Datetime startDt = Datetime.newInstance(sessionTimes[i].reduivy__Start_Date__c, sessionTimes[i].reduivy__Start_Time__c);
            Datetime endDt = Datetime.newInstance(sessionTimes[i].reduivy__End_Date__c, sessionTimes[i].reduivy__End_Time__c);


            reduivy__Study_Event__c studyEvent = new reduivy__Study_Event__c(

                reduivy__Study_Session_Time__c = sessionTimes[i].Id, 
                Name = 'Test ' + (i + 1), 
                reduivy__Type__c = 'Study Session', 
                reduivy__Location__c = null, 
                reduivy__Status__c = 'Confirmed', 
                reduivy__Start__c = startDt, 
                reduivy__End__c = endDt, 
                reduivy__Start_Date_Non_TZ__c = startDt.date(), 
                reduivy__Start_Time_Non_TZ__c = startDt.time(), 
                reduivy__End_Date_Non_TZ__c = endDt.date(), 
                reduivy__End_Time_Non_TZ__c = endDt.time()
            );

            studyEventList.add(studyEvent);
        }

        System.runAs(FACULTY_USER){
            Test.startTest();

            try{
                REDU_Database_UTIL.doInsert(studyEventList);


                System.Assert.fail('Should not be able to insert study event.');
            } catch (Exception ex){
                System.Assert.isTrue(ex.getMessage().contains(INSUFFICIENT_CREATABLE_ACCESS), 'Unexpected exception occurs: ' + ex.getMessage());
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for reduivy__Respect_Resource_Availability__c == true and facility is available
     */
    @IsTest
    static void testCheckedRespectAndFacilityIsAvailableAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Session_Time__c> sessionTimes = [SELECT Id, Name, reduivy__Default_Facility__c, reduivy__Start_Date__c, reduivy__Start_Time__c, reduivy__End_Date__c, reduivy__End_Time__c, reduivy__Day_of_Week__c, reduivy__Study_Session__r.Id, reduivy__Study_Session__r.Name, reduivy__Study_Session__r.reduivy__Respect_Resource_Availability__c
                                                             FROM reduivy__Study_Session_Time__c
                                                             LIMIT 1];
        List<reduivy__Study_Session__c> sessions = new List<reduivy__Study_Session__c>{ sessionTimes[0].reduivy__Study_Session__r };

        sessions[0].reduivy__Respect_Resource_Availability__c = true;
        REDU_Database_UTIL.doUpdate(sessions);

        List<reduivy__Facility_Availability__c> availability = new List<reduivy__Facility_Availability__c>{ new reduivy__Facility_Availability__c(
            reduivy__Facility__c = sessionTimes[0].reduivy__Default_Facility__c, 

            reduivy__Monday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(-1), 
            reduivy__Monday_To__c = sessionTimes[0].reduivy__End_Time__c.addHours(1), 
            reduivy__Tuesday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(-1), 
            reduivy__Tuesday_To__c = sessionTimes[0].reduivy__End_Time__c.addHours(1), 
            reduivy__Wednesday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(-1), 
            reduivy__Wednesday_To__c = sessionTimes[0].reduivy__End_Time__c.addHours(1), 
            reduivy__Thursday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(-1), 
            reduivy__Thursday_To__c = sessionTimes[0].reduivy__End_Time__c.addHours(1), 
            reduivy__Friday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(-1), 
            reduivy__Friday_To__c = sessionTimes[0].reduivy__End_Time__c.addHours(1), 
            reduivy__Saturday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(-1), 
            reduivy__Saturday_To__c = sessionTimes[0].reduivy__End_Time__c.addHours(1), 
            reduivy__Sunday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(-1), 
            reduivy__Sunday_To__c = sessionTimes[0].reduivy__End_Time__c.addHours(1)
        ) };

        REDU_Database_Util.doInsert(availability);

        List<reduivy__Study_Event__c> studyEventList = new List<reduivy__Study_Event__c>();
        Integer nameCounter = 1;
        Integer daysToAdd = DAY_OF_WEEK.get(sessionTimes[0].reduivy__Day_of_Week__c);

        for (Date currentDate = sessionTimes[0].reduivy__Start_Date__c.addDays(daysToAdd); currentDate <= sessionTimes[0].reduivy__End_Date__c; currentDate = currentDate.addDays(7)){
            Datetime startDt = Datetime.newInstance(currentDate, sessionTimes[0].reduivy__Start_Time__c);
            Datetime endDt = Datetime.newInstance(currentDate, sessionTimes[0].reduivy__End_Time__c);
            studyEventList.add(new reduivy__Study_Event__c(
                reduivy__Study_Session_Time__c = sessionTimes[0].Id, 
                Name = 'Test ' + nameCounter, 
                reduivy__Type__c = 'Study Session', 
                reduivy__Location__c = null, 
                reduivy__Status__c = 'Confirmed', 
                reduivy__Start__c = startDt, 
                reduivy__End__c = endDt, 
                reduivy__Start_Date_Non_TZ__c = startDt.date(), 
                reduivy__Start_Time_Non_TZ__c = startDt.time(), 
                reduivy__End_Date_Non_TZ__c = endDt.date(), 
                reduivy__End_Time_Non_TZ__c = endDt.time()
            ));
            nameCounter++;
        }


        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_Database_Util.doInsert(studyEventList);

            List<reduivy__Study_Event_Relation__c> eventRelationList = [SELECT Id, Name, reduivy__Facility__c
                                                                        FROM reduivy__Study_Event_Relation__c
                                                                        WHERE reduivy__Study_Event__r.Id = :studyEventList[0].Id];

            System.Assert.areEqual(1, eventRelationList.size(), 'Size of event relation list should be 1');
            System.Assert.areNotEqual(null, eventRelationList[0].reduivy__Facility__c, 'Facility is null.');

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for reduivy__Respect_Resource_Availability__c == true and facility is NOT available
     */
    @IsTest
    static void testCheckedRespectButFacilityIsNotAvailableAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Session_Time__c> sessionTimes = [SELECT Id, Name, reduivy__Default_Facility__c, reduivy__Start_Date__c, reduivy__Start_Time__c, reduivy__End_Date__c, reduivy__End_Time__c, reduivy__Day_of_Week__c, reduivy__Study_Session__r.Id, reduivy__Study_Session__r.Name, reduivy__Study_Session__r.reduivy__Respect_Resource_Availability__c
                                                             FROM reduivy__Study_Session_Time__c
                                                             LIMIT 1];
        List<reduivy__Study_Session__c> sessions = new List<reduivy__Study_Session__c>{ sessionTimes[0].reduivy__Study_Session__r };

        sessions[0].reduivy__Respect_Resource_Availability__c = true;
        REDU_Database_UTIL.doUpdate(sessions);

        List<reduivy__Facility_Availability__c> availability = new List<reduivy__Facility_Availability__c>{ new reduivy__Facility_Availability__c(
            reduivy__Facility__c = sessionTimes[0].reduivy__Default_Facility__c, 

            reduivy__Monday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(1), 
            reduivy__Monday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Tuesday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(1), 
            reduivy__Tuesday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Wednesday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(1), 
            reduivy__Wednesday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Thursday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(1), 
            reduivy__Thursday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Friday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(1), 
            reduivy__Friday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Saturday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(1), 
            reduivy__Saturday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Sunday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(1), 
            reduivy__Sunday_To__c = sessionTimes[0].reduivy__End_Time__c
        ) };

        REDU_Database_Util.doInsert(availability);

        List<reduivy__Study_Event__c> studyEventList = new List<reduivy__Study_Event__c>();
        Integer nameCounter = 1;
        Integer daysToAdd = DAY_OF_WEEK.get(sessionTimes[0].reduivy__Day_of_Week__c);

        for (Date currentDate = sessionTimes[0].reduivy__Start_Date__c.addDays(daysToAdd); currentDate <= sessionTimes[0].reduivy__End_Date__c; currentDate = currentDate.addDays(7)){
            Datetime startDt = Datetime.newInstance(currentDate, sessionTimes[0].reduivy__Start_Time__c);
            Datetime endDt = Datetime.newInstance(currentDate, sessionTimes[0].reduivy__End_Time__c);
            studyEventList.add(new reduivy__Study_Event__c(
                reduivy__Study_Session_Time__c = sessionTimes[0].Id, 
                Name = 'Test ' + nameCounter, 
                reduivy__Type__c = 'Study Session', 
                reduivy__Location__c = null, 
                reduivy__Status__c = 'Confirmed', 
                reduivy__Start__c = startDt, 
                reduivy__End__c = endDt, 
                reduivy__Start_Date_Non_TZ__c = startDt.date(), 
                reduivy__Start_Time_Non_TZ__c = startDt.time(), 
                reduivy__End_Date_Non_TZ__c = endDt.date(), 
                reduivy__End_Time_Non_TZ__c = endDt.time()
            ));
            nameCounter++;
        }


        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_Database_Util.doInsert(studyEventList);

            List<reduivy__Study_Event_Relation__c> eventRelationList = [SELECT Id, Name, reduivy__Facility__c
                                                                        FROM reduivy__Study_Event_Relation__c
                                                                        WHERE reduivy__Study_Event__r.Id IN :studyEventList];
            System.Assert.areEqual(0, eventRelationList.size(), 'No study event relation should be created.');


            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for reduivy__Respect_Resource_Availability__c == true and facility is NOT available for half of the study events
     */
    @IsTest
    static void testCheckedRespectButFacilityIsNotAvailableForHalfAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Session_Time__c> sessionTimes = [SELECT Id, Name, reduivy__Default_Facility__c, reduivy__Start_Date__c, reduivy__Start_Time__c, reduivy__End_Date__c, reduivy__End_Time__c, reduivy__Day_of_Week__c, reduivy__Study_Session__r.Id, reduivy__Study_Session__r.Name, reduivy__Study_Session__r.reduivy__Respect_Resource_Availability__c
                                                             FROM reduivy__Study_Session_Time__c
                                                             LIMIT 1];
        List<reduivy__Study_Session__c> sessions = new List<reduivy__Study_Session__c>{ sessionTimes[0].reduivy__Study_Session__r };

        sessions[0].reduivy__Respect_Resource_Availability__c = true;
        REDU_Database_UTIL.doUpdate(sessions);
        Date middleDate = midDate(sessionTimes[0].reduivy__Start_Date__c, sessionTimes[0].reduivy__End_Date__c);

        List<reduivy__Facility_Availability__c> availability = new List<reduivy__Facility_Availability__c>{ new reduivy__Facility_Availability__c(
            reduivy__Facility__c = sessionTimes[0].reduivy__Default_Facility__c, 
            reduivy__To_Date__c = middleDate, 
            reduivy__Monday_From__c = sessionTimes[0].reduivy__Start_Time__c, 
            reduivy__Monday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Tuesday_From__c = sessionTimes[0].reduivy__Start_Time__c, 
            reduivy__Tuesday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Wednesday_From__c = sessionTimes[0].reduivy__Start_Time__c, 
            reduivy__Wednesday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Thursday_From__c = sessionTimes[0].reduivy__Start_Time__c, 
            reduivy__Thursday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Friday_From__c = sessionTimes[0].reduivy__Start_Time__c, 
            reduivy__Friday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Saturday_From__c = sessionTimes[0].reduivy__Start_Time__c, 
            reduivy__Saturday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Sunday_From__c = sessionTimes[0].reduivy__Start_Time__c, 
            reduivy__Sunday_To__c = sessionTimes[0].reduivy__End_Time__c
        ), new reduivy__Facility_Availability__c(
            reduivy__Facility__c = sessionTimes[0].reduivy__Default_Facility__c, 
            reduivy__From_Date__c = middleDate.addDays(1), 
            reduivy__Monday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(1), 
            reduivy__Monday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Tuesday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(1), 
            reduivy__Tuesday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Wednesday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(1), 
            reduivy__Wednesday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Thursday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(1), 
            reduivy__Thursday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Friday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(1), 
            reduivy__Friday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Saturday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(1), 
            reduivy__Saturday_To__c = sessionTimes[0].reduivy__End_Time__c, 
            reduivy__Sunday_From__c = sessionTimes[0].reduivy__Start_Time__c.addHours(1), 
            reduivy__Sunday_To__c = sessionTimes[0].reduivy__End_Time__c
        ) };

        REDU_Database_Util.doInsert(availability);

        List<reduivy__Study_Event__c> studyEventList = new List<reduivy__Study_Event__c>();
        Integer nameCounter = 0;
        Integer daysToAdd = DAY_OF_WEEK.get(sessionTimes[0].reduivy__Day_of_Week__c);

        for (Date currentDate = sessionTimes[0].reduivy__Start_Date__c.addDays(daysToAdd); currentDate <= sessionTimes[0].reduivy__End_Date__c; currentDate = currentDate.addDays(7)){
            Datetime startDt = Datetime.newInstance(currentDate, sessionTimes[0].reduivy__Start_Time__c);
            Datetime endDt = Datetime.newInstance(currentDate, sessionTimes[0].reduivy__End_Time__c);
            studyEventList.add(new reduivy__Study_Event__c(
                reduivy__Study_Session_Time__c = sessionTimes[0].Id, 
                Name = 'Test ' + nameCounter, 
                reduivy__Type__c = 'Study Session', 
                reduivy__Location__c = null, 
                reduivy__Status__c = 'Confirmed', 
                reduivy__Start__c = startDt, 
                reduivy__End__c = endDt, 
                reduivy__Start_Date_Non_TZ__c = startDt.date(), 
                reduivy__Start_Time_Non_TZ__c = startDt.time(), 
                reduivy__End_Date_Non_TZ__c = endDt.date(), 
                reduivy__End_Time_Non_TZ__c = endDt.time()
            ));
            nameCounter++;
        }


        System.runAs(ADMIN_USER){
            Test.startTest();


            REDU_Database_Util.doInsert(studyEventList);

            List<reduivy__Study_Event_Relation__c> eventRelationList = [SELECT Id, Name, reduivy__Facility__c
                                                                        FROM reduivy__Study_Event_Relation__c
                                                                        WHERE reduivy__Study_Event__r.Id IN :studyEventList];
            System.Assert.areNotEqual(nameCounter, eventRelationList.size(), 'Half of the study event relations should be created.');
            System.Assert.areNotEqual(0, eventRelationList.size(), 'Half of the study event relations should be created.');


            Test.stopTest();
        }
    }

    static Date midDate(Date date1, Date date2){
        Time midnight = Time.newInstance(0, 0, 0, 0);
        return DateTime.newInstance((DateTime.newInstance(date1, midnight).getTime() + DateTime.newInstance(date2, midnight).getTime()) / 2).date();
    }

}