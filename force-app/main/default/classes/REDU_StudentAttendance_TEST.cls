/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Test
 * @description Test class for REDU_StudentAttendance_LCTRL
 * @changehistory
 * ISS-001919 12-08-2024 Lean - new class
 */
@IsTest
public inherited sharing class REDU_StudentAttendance_TEST {
    
	/**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    static String sampleSessionKey = 'Lecture_MGT301_CYT1_SYDNEY';
    
    static String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
    static String ISN_INPROGRESS_STATUS = ISN_Helper.getInProgressStatuses().get(0);

    @TestSetup
    static void makeData(){
        // Create settings
		testFactory.setupDefaultSettings();

        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {

            Test.startTest();

            testFactory.initMasterData(SUN_Helper.getApiName());
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initOfferingData(null);
            testFactory.initStudentData(IEN_Helper.getApiName(), true);
            
            //find student idv enrollment status = enrolled, select first studyOfferingId for each student
            Map<reduivy__Individual_Enrollment__c, reduivy__Study_Offering__c> idvEnrollWithStudyOffer = new Map<reduivy__Individual_Enrollment__c, reduivy__Study_Offering__c>();
            Set<Id> studentIds = new Set<Id>();

            for(reduivy__Individual_Enrollment__c idvEnroll : testFactory.studentIndividualEnrollments.values()){
                if(idvEnroll.reduivy__Enrollment_Status__c == IEN_INPROGRESS_STATUS && idvEnroll.RecordTypeId == IEN_Helper.getStudentRecordTypeId() && !studentIds.contains(idvEnroll.reduivy__Contact__c)){
                    
                    for(reduivy__Study_Offering__c so : testFactory.studyOfferings.values()){
                        if(so.Id == idvEnroll.reduivy__Study_Offering__c){
                            idvEnrollWithStudyOffer.put(idvEnroll, so);
                            studentIds.add(idvEnroll.reduivy__Contact__c);
                        }
                    }

                }
            }

            //enroll students into Lecture study session (create student session enrollment)
            Map<String, reduivy__Individual_Session_Enrollment__c> studentIndividualSessionEnrollments = new Map<String, reduivy__Individual_Session_Enrollment__c>();

            for(reduivy__Individual_Enrollment__c idvEnroll : idvEnrollWithStudyOffer.keySet()){
                for(reduivy__Study_Session__c ss : testFactory.studySessions.values()){
                    if(ss.reduivy__Study_Offering__c == idvEnrollWithStudyOffer.get(idvEnroll).Id && ss.reduivy__Type__c == 'Lecture'){
                        String isnSampleRecord = ss.Name + '_' + idvEnroll.reduivy__Sample_Record_Code__c;
                        studentIndividualSessionEnrollments.put(isnSampleRecord, REDU_TestData_UTIL.newStudentIndividualSessionEnrollment(isnSampleRecord, ss.Id, idvEnroll.Id, ss.reduivy__Start_Date__c, ISN_INPROGRESS_STATUS));
                    }
                }
            }

            REDU_SystemMode_UTIL.doInsert(studentIndividualSessionEnrollments.values());

            Test.stopTest();
        }
    }

    /**
     * @description Test get study events with usermode = admin as admin user
     */
    @IsTest
    static void testGetStudyEventsWithAdminModeAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudentAttendance_LCTRL.getStudyEvents(null, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, response.isSuccess);
            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
            
            System.Assert.areEqual(8, studyEvents.size(), 'There should be 8 study events.');

            for (reduivy__Study_Event__c sev : studyEvents) {
                System.Assert.areEqual(sev.reduivy__Start__c.date(), testFactory.currentYearTerm1StartDate);
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get study events with usermode = faculty as admin user
     */
    @IsTest
    static void testGetStudyEventsWithFacultyModeAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        System.runAs(ADMIN_USER){
            try {
                REDU_LightningResponse response = REDU_StudentAttendance_LCTRL.getStudyEvents(null, USR_Helper.USER_MODE_FACULTY, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
                System.Assert.fail('This should fail with ' + Label.Failed_To_Identify_The_Contact_For_Current_User);
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(Label.Failed_To_Identify_The_Contact_For_Current_User));
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get study events with usermode = admin and session id as admin user
     */
    @IsTest
    static void testGetStudyEventsWithAdminModeAndSessionIdAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];

        System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, response.isSuccess);
            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
            
            System.Assert.areEqual(1, studyEvents.size(), 'There should be 8 study events.');

            for (reduivy__Study_Event__c sev : studyEvents) {
                System.Assert.areEqual(sev.reduivy__Start__c.date(), testFactory.currentYearTerm1StartDate);
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get study events with usermode = faculty and session id as admin user
     */
    @IsTest
    static void testGetStudyEventsWithFacultyModeAndSessionIdAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];

        System.runAs(ADMIN_USER){
            try {
                REDU_LightningResponse response = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_FACULTY, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
                System.Assert.fail('This should fail with ' + Label.Failed_To_Identify_The_Contact_For_Current_User);
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(Label.Failed_To_Identify_The_Contact_For_Current_User));
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get study events with usermode = admin as faculty user
     */
    @IsTest
    static void testGetStudyEventsWithAdminModeAsFaculty(){
        
        Test.startTest();
        User facultyUser = testFactory.getAllocatedFacultyUser();

        System.runAs(facultyUser){
            REDU_LightningResponse response = REDU_StudentAttendance_LCTRL.getStudyEvents(null, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, response.isSuccess);
            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
            
            System.Assert.areEqual(8, studyEvents.size(), 'There should be 8 study events.');
            
            for (reduivy__Study_Event__c sev : studyEvents) {
                System.Assert.areEqual(sev.reduivy__Start__c.date(), testFactory.currentYearTerm1StartDate);
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get study events with usermode = faculty as faculty user
     */
    @IsTest
    static void testGetStudyEventsWithFacultyModeAsFaculty(){
        
        Test.startTest();
        User facultyUser = testFactory.getAllocatedFacultyUser();

        System.runAs(facultyUser){
            REDU_LightningResponse response = REDU_StudentAttendance_LCTRL.getStudyEvents(null, USR_Helper.USER_MODE_FACULTY, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, response.isSuccess);
            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
            
            System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');
            
            for (reduivy__Study_Event__c sev : studyEvents) {
                System.Assert.areEqual(sev.reduivy__Start__c.date(), testFactory.currentYearTerm1StartDate);
            }
        }

        System.runAs(facultyUser){
            REDU_LightningResponse response = REDU_StudentAttendance_LCTRL.getStudyEvents(null, USR_Helper.USER_MODE_FACULTY, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, false);
            System.Assert.areEqual(true, response.isSuccess);
            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
            
            System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');
            
            for (reduivy__Study_Event__c sev : studyEvents) {
                System.Assert.areEqual(sev.reduivy__Start__c.date(), testFactory.currentYearTerm1StartDate);
            }
        }

        List<reduivy__Study_Event_Relation__c> studyEventRelations = [SELECT Id FROM reduivy__Study_Event_Relation__c];
        delete studyEventRelations;

        System.runAs(facultyUser){
            REDU_LightningResponse response = REDU_StudentAttendance_LCTRL.getStudyEvents(null, USR_Helper.USER_MODE_FACULTY, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, response.isSuccess);
            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
            
            System.Assert.areEqual(0, studyEvents.size(), 'There should be 0 study events.');
            
            for (reduivy__Study_Event__c sev : studyEvents) {
                System.Assert.areEqual(sev.reduivy__Start__c.date(), testFactory.currentYearTerm1StartDate);
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get study events with usermode = admin and session id as faculty user
     */
    @IsTest
    static void testGetStudyEventsWithAdminModeAndSessionIdAsFaculty(){
        
        Test.startTest();
        
        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];

        User facultyUser = testFactory.getAllocatedFacultyUser();

        System.runAs(facultyUser){
            REDU_LightningResponse response = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, response.isSuccess);
            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
            
            System.Assert.areEqual(1, studyEvents.size(), 'There should be 8 study events.');
            
            for (reduivy__Study_Event__c sev : studyEvents) {
                System.Assert.areEqual(sev.reduivy__Start__c.date(), testFactory.currentYearTerm1StartDate);
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get study events with usermode = faculty and session id as faculty user
     */
    @IsTest
    static void testGetStudyEventsWithFacultyModeAndSessionIdAsFaculty(){
        
        Test.startTest();
        
        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];

        User facultyUser = testFactory.getAllocatedFacultyUser();

        System.runAs(facultyUser){
            REDU_LightningResponse response = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_FACULTY, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, response.isSuccess);
            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
            
            System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');
            
            for (reduivy__Study_Event__c sev : studyEvents) {
                System.Assert.areEqual(sev.reduivy__Start__c.date(), testFactory.currentYearTerm1StartDate);
            }
        }

        System.runAs(facultyUser){
            REDU_LightningResponse response = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_FACULTY, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, false);
            System.Assert.areEqual(true, response.isSuccess);
            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
            
            System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');
            
            for (reduivy__Study_Event__c sev : studyEvents) {
                System.Assert.areEqual(sev.reduivy__Start__c.date(), testFactory.currentYearTerm1StartDate);
            }
        }

        List<reduivy__Study_Event_Relation__c> studyEventRelations = [SELECT Id FROM reduivy__Study_Event_Relation__c];
        delete studyEventRelations;

        System.runAs(facultyUser){
            REDU_LightningResponse response = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_FACULTY, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, response.isSuccess);
            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
            
            System.Assert.areEqual(0, studyEvents.size(), 'There should be 0 study events.');
            
            for (reduivy__Study_Event__c sev : studyEvents) {
                System.Assert.areEqual(sev.reduivy__Start__c.date(), testFactory.currentYearTerm1StartDate);
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get study events with usermode = admin as student user, this should not be a real use case but we add here just to cover the behavior.
     *              The student will get the same result as admin user due to the query is done using REDU_SystemMode_UTIL as the study event and study event relation is private.
     */
    @IsTest
    static void testGetStudyEventsWithAdminModeAsStudent(){
        
        Test.startTest();
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            REDU_LightningResponse response = REDU_StudentAttendance_LCTRL.getStudyEvents(null, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, response.isSuccess);
            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
            
            //In real case, this component should not be used by student
            System.Assert.areEqual(8, studyEvents.size(), 'There should be 0 study events.');
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get study events with usermode = faculty as student user, this should not be a real use case but we add here just to cover the behavior.
     *              The student will get the same result as faculty user due to the query is done using REDU_SystemMode_UTIL as the study event and study event relation is private.
     */
    @IsTest
    static void testGetStudyEventsWithFacultyModeAsStudent(){
        
        Test.startTest();
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser){
            REDU_LightningResponse response = REDU_StudentAttendance_LCTRL.getStudyEvents(null, USR_Helper.USER_MODE_FACULTY, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, response.isSuccess);
            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
            
            System.Assert.areEqual(0, studyEvents.size(), 'There should be 0 study events.');
        }

        Test.stopTest();
        
    }
}