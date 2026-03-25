/**
 * @author      WDCi (XW)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for REDU_SessionSchedulerSession_CTRL
 * @changehistory
 * ISS-001920 15-08-2024 XW - create new class
 */

@IsTest
public inherited sharing class REDU_SessionSchedulerSession_TEST {

    private class FacilityFaculty{
        public List<reduivy__Study_Event_Relation__c> faculty;
        public List<reduivy__Study_Event_Relation__c> facility;
    }  
    private class DoubleBookingWrapper{
        public FacilityFaculty sessionData;
        public FacilityFaculty conflictData;
    }
    
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

        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
        	testFactory.initMasterData(null);
            testFactory.initFacultyData(CON_Helper.getApiName(), false);
            testFactory.initOfferingData(null);
            testFactory.initStudentData(IPR_Helper.getApiName(), true);
		}
    }
	
    /**
     * @description Test as admin for delete study session
     */
    @IsTest
    static void testForAdminDeleteSse() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session__c sse = [
            SELECT Id, Name, (
                SELECT Id, Name
                FROM reduivy__Individual_Session_Enrollments__r
            )
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];

        delete sse.reduivy__Individual_Session_Enrollments__r;
        

        // TO DO: implement unit test run as admin
		System.runAs(ADMIN_USER){
		    Test.startTest();

            REDU_SessionSchedulerSession_LCTRL.deleteStudySession(sse.Id);

            List<reduivy__Study_Session__c> deletedSse = [
                SELECT Id, Name
                FROM reduivy__Study_Session__c
                WHERE Id = :sse.Id
                LIMIT 1
            ];
            System.Assert.areEqual(0, deletedSse.size(), 'The Study Session should be deleted!');
            

            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as student for delete study session
     */
	@IsTest
    static void testForStudentDeleteSse() {
        
		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
            LIMIT 1
        ];

        reduivy__Study_Session__c sse = [
            SELECT Id, Name, (
                SELECT Id, Name
                FROM reduivy__Individual_Session_Enrollments__r
            )
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];

        delete sse.reduivy__Individual_Session_Enrollments__r;

        // TO DO: implement unit test run as student
		System.runAs(studentUser){
            Test.startTest();

            try {
                REDU_SessionSchedulerSession_LCTRL.deleteStudySession(sse.Id);
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Insufficient Delete access on following object(s) and field(s) - reduivy__Study_Session__c'), 'Unexpected error: ' + exp.getMessage());
            }

            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as faculty for delete study session
     */
	@IsTest
    static void testForFacultyDeleteSse() {
		        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Study_Session__c sse = [
            SELECT Id, Name, (
                SELECT Id, Name
                FROM reduivy__Individual_Session_Enrollments__r
            )
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];

        delete sse.reduivy__Individual_Session_Enrollments__r;

        // TO DO: implement unit test run as faculty
		System.runAs(FACULTY_USER){
            Test.startTest();

            try {
                REDU_SessionSchedulerSession_LCTRL.deleteStudySession(sse.Id);
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Insufficient Delete access on following object(s) and field(s) - reduivy__Study_Session__c'), 'Unexpected error: ' + exp.getMessage());
            }
            
            Test.stopTest();
		}
		
    }

    /**
     * @description Test as admin for checking double booking
     */
	@IsTest
    static void testForAdminCheckingDoubleBooking() {
		
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session__c sse = [SELECT Id,
            Name
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];


        reduivy__Study_Session_Time__c sst = [SELECT Id,
            Name, 
            reduivy__Day_of_Week__c,
            reduivy__Recurrence__c,
            reduivy__Default_Facility__c,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Start_Time__c,
            reduivy__End_Time__c
            FROM reduivy__Study_Session_Time__c
            WHERE reduivy__Study_Session__c = :sse.Id
            LIMIT 1
        ];
        reduivy__Study_Session_Time__c newSst = new reduivy__Study_Session_Time__c(
            Name = sst.Name,
            reduivy__Day_of_Week__c = sst.reduivy__Day_of_Week__c,
            reduivy__Recurrence__c = sst.reduivy__Recurrence__c,
            reduivy__Default_Facility__c = sst.reduivy__Default_Facility__c,
            reduivy__Start_Date__c = sst.reduivy__Start_Date__c,
            reduivy__End_Date__c = sst.reduivy__End_Date__c,
            reduivy__Start_Time__c = sst.reduivy__Start_Time__c,
            reduivy__End_Time__c = sst.reduivy__End_Time__c,
            reduivy__Study_Session__c = sse.Id
        );
        insert newSst;
        sse.reduivy__Study_Event_Generation_Status__c = SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATE;
        update sse;

        reduivy__Study_Event__c newCreatedSev = [SELECT Id,
            Name,
            reduivy__Start_Date_Non_TZ__c,
            reduivy__Start_Time_Non_TZ__c,
            reduivy__End_Date_Non_TZ__c,
            reduivy__End_Time_Non_TZ__c,
            reduivy__Start__c,
            reduivy__End__c,
            reduivy__Location__c,
            reduivy__Status__c,
            reduivy__Study_Session_Time__c,
            reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            FROM reduivy__Study_Event__c
            WHERE reduivy__Study_Session_Time__c = :newSst.Id
            LIMIT 1
        ];
        List<reduivy__Study_Event_Relation__c> duplicatedTargetFacultySer = [SELECT Id,
            Name,
            reduivy__Contact__c,
            reduivy__Event_Start_Datetime__c
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Contact__c != null
            AND reduivy__Event_Start_Datetime__c = :newCreatedSev.reduivy__Start__c
            LIMIT 1
        ];

        if(duplicatedTargetFacultySer.isEmpty()){
            reduivy__Study_Event__c willBeConflictedSev = REDU_TestData_UTIL.newSessionStudyEvent('Will be Conflicted Sev', newCreatedSev.reduivy__Study_Session_Time__c, 'Will be Conflicted Sev', newCreatedSev.reduivy__Location__c, newCreatedSev.reduivy__Status__c, newCreatedSev.reduivy__Start__c, newCreatedSev.reduivy__End__c);
            insert willBeConflictedSev;

            Contact faculty = [SELECT Id, Name FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_FACULTY LIMIT 1];
            List<reduivy__Study_Event_Relation__c> conflictedSerList = new List<reduivy__Study_Event_Relation__c>();
            reduivy__Study_Event_Relation__c willBeConflictedSer = REDU_TestData_UTIL.newFacultyStudyEventRelation('Will be Conflicted Faculty Ser', faculty.Id, willBeConflictedSev.Id, null);
            reduivy__Study_Event_Relation__c duplicatedSer = REDU_TestData_UTIL.newFacultyStudyEventRelation('Dulplicated Faculty Ser', faculty.Id, willBeConflictedSev.Id, null);
            conflictedSerList.add(willBeConflictedSer);
            conflictedSerList.add(duplicatedSer);
            
            insert conflictedSerList;
            duplicatedTargetFacultySer.add(willBeConflictedSer);
        }


        REDU_SessionSchedulerTimeline_LCTRL.allocateStudyEventRelation(
            new List<String> { newSst.Id }, 'future', 'FACULTY', new List<String>(), 
            JSON.serialize(newCreatedSev), 0, true, '', duplicatedTargetFacultySer[0].reduivy__Contact__c
        );

        
        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse blankResponse = REDU_SessionSchedulerSession_LCTRL.checkDoubleBooking(null);
            System.Assert.areEqual(null, blankResponse.responseData, 'Double Booking data should be null!');

            REDU_LightningResponse response = REDU_SessionSchedulerSession_LCTRL.checkDoubleBooking(sse.Id);
            DoubleBookingWrapper root = (DoubleBookingWrapper) JSON.deserialize(response.responseData, DoubleBookingWrapper.class);

            System.Assert.areNotEqual(0, root.sessionData.facility.size(), 'The Session Facility should not be empty!');
            System.Assert.areNotEqual(0, root.sessionData.faculty.size(), 'The Session Faculty should not be empty!');
            System.Assert.areNotEqual(0, root.conflictData.facility.size(), 'The Conflict Facility should not be empty!');
            System.Assert.areNotEqual(0, root.conflictData.faculty.size(), 'The Conflict Faculty should not be empty!');

            Test.stopTest();
        }
    }

    /**
     * @description Test as student for checking double booking
     */
	@IsTest
    static void testForStudentCheckingDoubleBooking() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
            LIMIT 1
        ];

        reduivy__Study_Event_Relation__c ser = [
            SELECT Id, 
            reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Contact__c = null
            LIMIT 1
        ];
        
        System.runAs(studentUser){
            Test.startTest();

            REDU_LightningResponse response = REDU_SessionSchedulerSession_LCTRL.checkDoubleBooking(ser.reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c);
            DoubleBookingWrapper root = (DoubleBookingWrapper) JSON.deserialize(response.responseData, DoubleBookingWrapper.class);

            System.Assert.areEqual(0, root.sessionData.facility.size(), 'The Session should be empty!');
            System.Assert.areEqual(0, root.conflictData.facility.size(), 'The Session should be empty!');


            Test.stopTest();
        }
    }


    /**
     * @description Test as faculty for checking double booking
     */
	@IsTest
    static void testForFacultyCheckingDoubleBooking() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Study_Event_Relation__c ser = [
            SELECT Id, 
            reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Contact__c = null
            LIMIT 1
        ];
        
        System.runAs(FACULTY_USER){
            Test.startTest();

            REDU_LightningResponse response = REDU_SessionSchedulerSession_LCTRL.checkDoubleBooking(ser.reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c);
            DoubleBookingWrapper root = (DoubleBookingWrapper) JSON.deserialize(response.responseData, DoubleBookingWrapper.class);

            System.Assert.areNotEqual(0, root.sessionData.facility.size(), 'The Session should not be empty!');
            System.Assert.areNotEqual(0, root.conflictData.facility.size(), 'The Session should not be empty!');


            Test.stopTest();
        }
    }



}