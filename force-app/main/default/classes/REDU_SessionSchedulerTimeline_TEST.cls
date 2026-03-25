/**
 * @author      WDCi (XW)
 * @date        July 2024
 * @group       Test
 * @description Test class for REDU_SessionSchedulerTimeline_LCTRL
 * @changehistory
 * ISS-001920 16-08-2024 XW - create new class
 */
@IsTest
public inherited sharing class REDU_SessionSchedulerTimeline_TEST {

    private static final String FACULTY = REDU_SessionSchedulerTimeline_LCTRL.FACULTY;
    private static final String FACILITY = REDU_SessionSchedulerTimeline_LCTRL.FACILITY;

    private static final String EVENTCHANGE_SINGLE = REDU_SessionSchedulerTimeline_LCTRL.EVENTCHANGE_SINGLE;
    private static final String EVENTCHANGE_ALLTHISDAY = REDU_SessionSchedulerTimeline_LCTRL.EVENTCHANGE_ALLTHISDAY;
    private static final String EVENTCHANGE_THISWEEK = REDU_SessionSchedulerTimeline_LCTRL.EVENTCHANGE_THISWEEK;
    private static final String EVENTCHANGE_TWOWEEKS = REDU_SessionSchedulerTimeline_LCTRL.EVENTCHANGE_TWOWEEKS;
    private static final String EVENTCHANGE_FOURWEEKS = REDU_SessionSchedulerTimeline_LCTRL.EVENTCHANGE_FOURWEEKS;
    private static final String EVENTCHANGE_FUTURE = REDU_SessionSchedulerTimeline_LCTRL.EVENTCHANGE_FUTURE;

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static String INSUFFICIENT_READABLE_ACCESS_ERROR = 'Insufficient READABLE access';
    static String INSUFFICIENT_UPDATABLE_ACCESS_ERROR = 'Insufficient UPDATABLE access';
    static String INSUFFICIENT_DELETE_ACCESS_ERROR = 'Insufficient DELETE access';
    static String SCRIPT_THROWN_EXCEPTION = 'Script-thrown exception';

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();

        	testFactory.initMasterData(null);
            testFactory.initFacultyData(CON_Helper.getApiName(), false);
            testFactory.initOfferingData(null);

            Test.stopTest();
		}
    }
	
    /**
     * @description Test as admin for GetCalendarEvents
     */
    @IsTest
    static void testForAdminGetCalendarEvents() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Facility__c> facilityList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Facility__c 
        ];
        
        Set<Id> facilityIdSet = new Map<Id, reduivy__Facility__c>(facilityList).keySet();
        reduivy__Study_Session__c startDateSession = [
            SELECT Id, reduivy__Start_Date__c
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];

        Datetime fromDate = Datetime.newInstance(testFactory.currentYearTerm1StartDate, Time.newInstance(0, 0, 0, 0));
        Datetime toDate = Datetime.newInstance(testFactory.currentYearTerm1EndDate, Time.newInstance(0, 0, 0, 0));

        // TO DO: implement unit test run as admin
		System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse response = REDU_SessionSchedulerTimeline_LCTRL.getCalendarEvents(new List<Id>(facilityIdSet), fromDate, toDate, '{"schedulingType":"Facility"}', null);
            Map<String, Object> facilityResponseData = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

            System.Assert.areEqual(true, facilityResponseData.containsKey(REDU_SessionSchedulerTimeline_LCTRL.CALEVENT_RESPONSEKEY_SEV), 'The studyEvents key is not found.');
            System.Assert.areEqual(true, facilityResponseData.containsKey(REDU_SessionSchedulerTimeline_LCTRL.CALEVENT_RESPONSEKEY_FILTERED_SESSIONCLASS_IDS), 'The filteredStudySessionIds key is not found.');

            List<reduivy__Study_Event__c> studyEventList = (List<reduivy__Study_Event__c>) JSON.deserialize(JSON.serialize(facilityResponseData.get('studyEvents')), List<reduivy__Study_Event__c>.class);
            System.Assert.isTrue(studyEventList.size() > 0, 'Should be able to retrieve Study Event List!');

            //blank response
            REDU_LightningResponse blankResponse = REDU_SessionSchedulerTimeline_LCTRL.getCalendarEvents(null, fromDate, toDate, '{"schedulingType":"Facility"}', null);
            Map<String, Object> blankResponseData = (Map<String, Object>) JSON.deserializeUntyped(blankResponse.responseData);

            System.Assert.areEqual(true, blankResponseData.containsKey(REDU_SessionSchedulerTimeline_LCTRL.CALEVENT_RESPONSEKEY_SEV), 'The studyEvents key is not found.');
            System.Assert.areEqual(true, blankResponseData.containsKey(REDU_SessionSchedulerTimeline_LCTRL.CALEVENT_RESPONSEKEY_FILTERED_SESSIONCLASS_IDS), 'The filteredStudySessionIds key is not found.');

            List<reduivy__Study_Event_Relation__c> studyEventRelationList = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(JSON.serialize(blankResponseData.get('studyEvents')), List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(0, studyEventRelationList.size(), ' Ser size should be 0!');

            
            Test.stopTest();
		}
		
    }

    @IsTest
    static void testForAdminGetSessionPreview() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session__c sse = [
            SELECT Id, Name, reduivy__Start_Date__c
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];

        reduivy__Study_Event_Relation__c serToDelete = [
            SELECT Id, Name
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :sse.Id
            AND reduivy__Contact__c = null
            LIMIT 1
        ];

        delete serToDelete;
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            REDU_LightningResponse response = REDU_SessionSchedulerTimeline_LCTRL.getSessionPreview(sse.Id, 'facility', true, sse.reduivy__Start_Date__c);
            List<reduivy__Study_Event__c> studyEventList = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
            System.Assert.areEqual(1, studyEventList.size(), 'The number of unallocated Sev should be only 1!');

         
            Test.stopTest();
        }
    }

    @IsTest
    static void testForAdminUnallocateAndAllocated() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Event_Relation__c facilityFutureSer;
        reduivy__Study_Event_Relation__c facultyAllDaySer;
        List<reduivy__Study_Event_Relation__c> serList = new List<reduivy__Study_Event_Relation__c>();

        for (reduivy__Study_Event_Relation__c ser : [SELECT Id, 
            Name, 
            reduivy__Facility__c, 
            reduivy__Contact__c, 
            reduivy__Relation_Type__c,
            reduivy__Study_Event__r.reduivy__Study_Session_Time__c, 
            reduivy__Study_Event__r.reduivy__Start__c, 
            reduivy__Study_Event__r.reduivy__Start_Date_Non_TZ__c, 
            reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            FROM reduivy__Study_Event_Relation__c
        ]){
            if(facultyAllDaySer == null && ser.reduivy__Contact__c != null && ser.reduivy__Relation_Type__c == SER_Helper.RELATION_TYPE_FACULTY){
                facultyAllDaySer = ser;
            } else if (facilityFutureSer == null && ser.reduivy__Facility__c != null) {
                facilityFutureSer = ser;
            }

            if(facultyAllDaySer != null && facilityFutureSer != null){
                break;
            }
        }

        System.runAs(ADMIN_USER) {
            Test.startTest();
        
            //empty studySessionTimeIdsList
            REDU_LightningResponse emptySessionTimeIdsListResponse = 
                REDU_SessionSchedulerTimeline_LCTRL.unallocateStudyEvent(new List<String> (),
                EVENTCHANGE_FUTURE, FACILITY, JSON.serialize(facilityFutureSer), 
                JSON.serialize(facilityFutureSer.reduivy__Study_Event__r), 1);

            List<reduivy__Study_Event_Relation__c> studyEventRelationList = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(emptySessionTimeIdsListResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);
            System.Assert.areEqual(0, studyEventRelationList.size(), 'Ser should be empty!');

            //empty parentSevString
            REDU_LightningResponse emptyParentSevStringResponse = 
                REDU_SessionSchedulerTimeline_LCTRL.unallocateStudyEvent(new List<String> {facilityFutureSer.reduivy__Study_Event__r.reduivy__Study_Session_Time__c},
                EVENTCHANGE_FUTURE, FACILITY, JSON.serialize(facilityFutureSer), 
                '', 1);

            studyEventRelationList = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(emptyParentSevStringResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);
            System.Assert.areEqual(0, studyEventRelationList.size(), 'Ser should be empty!');

            //empty selectedSerString
            REDU_LightningResponse emptySelectedSerStringResponse = 
                REDU_SessionSchedulerTimeline_LCTRL.unallocateStudyEvent(new List<String> {facilityFutureSer.reduivy__Study_Event__r.reduivy__Study_Session_Time__c},
                EVENTCHANGE_FUTURE, FACILITY, '', 
                JSON.serialize(facilityFutureSer.reduivy__Study_Event__r), 1);

            studyEventRelationList = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(emptySelectedSerStringResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);
            System.Assert.areEqual(0, studyEventRelationList.size(), 'Ser should be empty!');


            //correct scenario - facility - future
            REDU_LightningResponse unallocatedResponse = REDU_SessionSchedulerTimeline_LCTRL.unallocateStudyEvent(
                new List<String> {facilityFutureSer.reduivy__Study_Event__r.reduivy__Study_Session_Time__c},
                EVENTCHANGE_FUTURE, FACILITY, JSON.serialize(facilityFutureSer), 
                JSON.serialize(facilityFutureSer.reduivy__Study_Event__r), 1);
            if(unallocatedResponse.responseData.startsWith('[')){
                studyEventRelationList = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(unallocatedResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);
                System.Assert.areNotEqual(0, studyEventRelationList.size(), 'Ser should be deleted!');
            } else {
                reduivy__Study_Event_Relation__c studyEventRelation = (reduivy__Study_Event_Relation__c) JSON.deserialize(unallocatedResponse.responseData, reduivy__Study_Event_Relation__c.class);
                System.Assert.isNotNull(studyEventRelation, 'Should be deleting 1 Ser!');
            }

            REDU_LightningResponse allocatedResponse = REDU_SessionSchedulerTimeline_LCTRL.allocateStudyEventRelation(
                new List<String> {facilityFutureSer.reduivy__Study_Event__r.reduivy__Study_Session_Time__c},
                EVENTCHANGE_FUTURE, FACILITY, new List<String>(), JSON.serialize(facilityFutureSer.reduivy__Study_Event__r), 1,
                true, '', facilityFutureSer.reduivy__Facility__c
            );

            Map<String, Object> allocatedResponseRoot = (Map<String, Object>) JSON.deserializeUntyped(allocatedResponse.responseData);
            List<Object> upsertedStudyEventRelation = (List<Object>) allocatedResponseRoot.get('upsertedStudyEventRelation');
            System.Assert.areNotEqual(0, upsertedStudyEventRelation.size(), 'Ser should be allocated!');


            //correct scenario - faculty - all this day
            unallocatedResponse = REDU_SessionSchedulerTimeline_LCTRL.unallocateStudyEvent(
                new List<String> {facultyAllDaySer.reduivy__Study_Event__r.reduivy__Study_Session_Time__c},
                EVENTCHANGE_ALLTHISDAY, FACULTY, JSON.serialize(facultyAllDaySer), 
                JSON.serialize(facultyAllDaySer.reduivy__Study_Event__r), 1);
            if(unallocatedResponse.responseData.startsWith('[')){
                studyEventRelationList = (List<reduivy__Study_Event_Relation__c>) 
                    JSON.deserialize(unallocatedResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);
                System.Assert.areNotEqual(0, studyEventRelationList.size(), 'Ser should be deleted!');
            } else {
                reduivy__Study_Event_Relation__c studyEventRelation = (reduivy__Study_Event_Relation__c)
                    JSON.deserialize(unallocatedResponse.responseData, reduivy__Study_Event_Relation__c.class);
                System.Assert.isNotNull(studyEventRelation, 'Should be deleting 1 Ser!');
            }

            allocatedResponse = REDU_SessionSchedulerTimeline_LCTRL.allocateStudyEventRelation(
                new List<String> {facultyAllDaySer.reduivy__Study_Event__r.reduivy__Study_Session_Time__c},
                EVENTCHANGE_ALLTHISDAY, FACULTY, new List<String>(), JSON.serialize(facultyAllDaySer.reduivy__Study_Event__r), 1,
                true, '', facultyAllDaySer.reduivy__Contact__c
            );

            allocatedResponseRoot = (Map<String, Object>) JSON.deserializeUntyped(allocatedResponse.responseData);
            upsertedStudyEventRelation = (List<Object>) allocatedResponseRoot.get('upsertedStudyEventRelation');
            System.Assert.areNotEqual(0, upsertedStudyEventRelation.size(), 'Ser should be allocated!');

            //correct scenario - faculty - 2 weeks
            unallocatedResponse = REDU_SessionSchedulerTimeline_LCTRL.unallocateStudyEvent(
                new List<String> {facultyAllDaySer.reduivy__Study_Event__r.reduivy__Study_Session_Time__c},
                EVENTCHANGE_TWOWEEKS, FACULTY, JSON.serialize(facultyAllDaySer), 
                JSON.serialize(facultyAllDaySer.reduivy__Study_Event__r), 1);
            if(unallocatedResponse.responseData.startsWith('[')){
                studyEventRelationList = (List<reduivy__Study_Event_Relation__c>) 
                    JSON.deserialize(unallocatedResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);
                System.Assert.areNotEqual(0, studyEventRelationList.size(), 'Ser should be deleted!');
            } else {
                reduivy__Study_Event_Relation__c studyEventRelation = (reduivy__Study_Event_Relation__c)
                    JSON.deserialize(unallocatedResponse.responseData, reduivy__Study_Event_Relation__c.class);
                System.Assert.isNotNull(studyEventRelation, 'Should be deleting 1 Ser!');
            }

            allocatedResponse = REDU_SessionSchedulerTimeline_LCTRL.allocateStudyEventRelation(
                new List<String> {facultyAllDaySer.reduivy__Study_Event__r.reduivy__Study_Session_Time__c},
                EVENTCHANGE_TWOWEEKS, FACULTY, new List<String>(), JSON.serialize(facultyAllDaySer.reduivy__Study_Event__r), 1,
                true, '', facultyAllDaySer.reduivy__Contact__c
            );

            allocatedResponseRoot = (Map<String, Object>) JSON.deserializeUntyped(allocatedResponse.responseData);
            upsertedStudyEventRelation = (List<Object>) allocatedResponseRoot.get('upsertedStudyEventRelation');
            System.Assert.areNotEqual(0, upsertedStudyEventRelation.size(), 'Ser should be allocated!');

            Test.stopTest();
        }
    }

    @IsTest
    static void testForAdminChangeStudyEventTime() {
    
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Event_Relation__c facilitySer;
        reduivy__Study_Event_Relation__c facultySer;
        Id anotherFacilityId;
        Id anotherFacultyId;

        for(reduivy__Study_Event_Relation__c ser : [SELECT Id,
            reduivy__Event_Start_Datetime__c, 
            reduivy__Event_End_Datetime__c, 
            reduivy__Study_Event__c,
            reduivy__Facility__c,
            reduivy__Contact__c,
            reduivy__Relation_Type__c
            FROM reduivy__Study_Event_Relation__c
        ]){
            if(facilitySer == null && ser.reduivy__Facility__c != null){
                facilitySer = ser;
            } else if (facultySer == null && ser.reduivy__Contact__c != null && ser.reduivy__Relation_Type__c == SER_Helper.RELATION_TYPE_FACULTY){
                if(facilitySer != null && facilitySer.reduivy__Study_Event__c == ser.reduivy__Study_Event__c) {
                    continue;
                }
                facultySer = ser;
            }

            if(facilitySer != null && anotherFacilityId == null && ser.reduivy__Facility__c != facilitySer.reduivy__Facility__c){
                anotherFacilityId = ser.reduivy__Facility__c;
            } else if(facultySer != null && anotherFacultyId == null && ser.reduivy__Contact__c != facultySer.reduivy__Contact__c){
                anotherFacultyId = ser.reduivy__Contact__c;
            }

            if(facilitySer != null && facultySer != null && anotherFacilityId != null && anotherFacultyId != null) {
                break;
            }

        }

        System.runAs(ADMIN_USER) {
            
            Test.startTest();
            
            //Facility
            REDU_LightningResponse response = REDU_SessionSchedulerTimeline_LCTRL.changeStudyEventTime(facilitySer.Id, FACILITY, 
            facilitySer.reduivy__Event_Start_Datetime__c.addHours(1), facilitySer.reduivy__Event_End_Datetime__c.addHours(1), 
            facilitySer.reduivy__Facility__c, anotherFacilityId);
            
            reduivy__Study_Event_Relation__c serFacilityAfter = [
                SELECT Id, reduivy__Event_Start_Datetime__c, reduivy__Event_End_Datetime__c, reduivy__Facility__c
                FROM reduivy__Study_Event_Relation__c
                WHERE reduivy__Contact__c = null
                AND Id = :facilitySer.Id
                LIMIT 1
            ];
            
            System.Assert.areEqual(facilitySer.reduivy__Event_Start_Datetime__c.addHours(1), serFacilityAfter.reduivy__Event_Start_Datetime__c , 'Study Event time should have been changed!');
            System.Assert.areEqual(facilitySer.reduivy__Event_End_Datetime__c.addHours(1), serFacilityAfter.reduivy__Event_End_Datetime__c , 'Study Event time should have been changed!');
            System.Assert.areEqual(anotherFacilityId, serFacilityAfter.reduivy__Facility__c , 'Facility should have been changed!');
            

            //Faculty
            response = REDU_SessionSchedulerTimeline_LCTRL.changeStudyEventTime(facultySer.Id, FACULTY, 
                facultySer.reduivy__Event_Start_Datetime__c.addHours(1), facultySer.reduivy__Event_End_Datetime__c.addHours(1), 
                facultySer.reduivy__Contact__c, anotherFacultyId
            );
            
            reduivy__Study_Event_Relation__c serFacultyAfter = [
                SELECT Id, reduivy__Event_Start_Datetime__c, reduivy__Event_End_Datetime__c, reduivy__Contact__c
                FROM reduivy__Study_Event_Relation__c
                WHERE reduivy__Facility__c = null
                AND Id = :facultySer.Id
                LIMIT 1
            ];
            
            System.Assert.areEqual(facultySer.reduivy__Event_Start_Datetime__c.addHours(1), serFacultyAfter.reduivy__Event_Start_Datetime__c , 'Study Event time should have been changed!');
            System.Assert.areEqual(facultySer.reduivy__Event_End_Datetime__c.addHours(1), serFacultyAfter.reduivy__Event_End_Datetime__c , 'Study Event time should have been changed!');
            System.Assert.areEqual(anotherFacultyId, serFacultyAfter.reduivy__Contact__c , 'Contact should have been changed!');
            
            
            Test.stopTest();
        }
    }
	
}