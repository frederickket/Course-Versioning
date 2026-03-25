/**
 * @author      WDCi (Sueanne)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for REDU_ContactCalendar_LCTRL
 * @changehistory
 * ISS-001925 16-08-2024 Sueanne - new class
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@isTest
public inherited sharing class REDU_ContactCalendar_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
    static String ISN_INPROGRESS_STATUS = ISN_Helper.getInProgressStatuses().get(0);
    
    /**
     * @description Default method to setup required data for automated test
     */
    @TestSetup
    static void makeData(){

        // Create settings
		testFactory.setupDefaultSettings();
        
        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(ARU_Helper.getApiName());
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

            if (!testFactory.studyEvents.isEmpty()) {
                //create study event relation for student
                //Map studySessionId + IndividualSessionEnrollment (Map 1) --- match studySessionId
                Map<Id, List<reduivy__Individual_Session_Enrollment__c>> ssIdWithIsnList = new Map<Id, List<reduivy__Individual_Session_Enrollment__c>>();
                for(reduivy__Individual_Session_Enrollment__c isn : studentIndividualSessionEnrollments.values()){
                    if(isn.RecordTypeId == ISN_Helper.getStudentRecordTypeId()){
                        if (ssIdWithIsnList.containsKey(isn.reduivy__Study_Session__c)) {
                            ssIdWithIsnList.get(isn.reduivy__Study_Session__c).add(isn);
                        } else {
                            ssIdWithIsnList.put(isn.reduivy__Study_Session__c, new List<reduivy__Individual_Session_Enrollment__c>{isn});
                        }
                    }
                }
    
                //Map studySessionTimeId + studySessionId -> Map studySessionId + StudyEvent (Map 2)
                Map<Id, Id> sstIdWithSsId = new Map<Id, Id>();
                for(reduivy__Study_Session_Time__c sst : testFactory.studySessionTimes.values()){
                    sstIdWithSsId.put(sst.Id, sst.reduivy__Study_Session__c);
                }
    
                Map<Id, List<reduivy__Study_Event__c>> ssIdWithSe = new Map<Id, List<reduivy__Study_Event__c>>();
                for(reduivy__Study_Event__c se : testFactory.studyEvents.values()){
                    Id ssId = sstIdWithSsId.get(se.reduivy__Study_Session_Time__c);
                    if(ssId != null){
                        if(!ssIdWithSe.containsKey(ssId)){
                            ssIdWithSe.put(ssId, new List<reduivy__Study_Event__c>());
                        }
                        ssIdWithSe.get(ssId).add(se);
                    }
                }
    
                //match studySessionId Map 1 and Map 2 (for create study event relations)
                Map<Id, reduivy__Individual_Enrollment__c> iensMapById = new Map<Id, reduivy__Individual_Enrollment__c>(testFactory.studentIndividualEnrollments.values());
                Map<String, reduivy__Study_Event_Relation__c> studentStudyEventRelations = new Map<String, reduivy__Study_Event_Relation__c>();
                
                for(Id ssId : ssIdWithIsnList.keySet()){
                    if(ssIdWithSe.containsKey(ssId)){
                        List<reduivy__Study_Event__c> seList = ssIdWithSe.get(ssId);
                        List<reduivy__Individual_Session_Enrollment__c> isnList = ssIdWithIsnList.get(ssId);
                        for (reduivy__Individual_Session_Enrollment__c isn : isnList) {
                            for(reduivy__Study_Event__c se : seList){
                                DateTime startDt = se.reduivy__Start__c;
                                DateTime endDt = se.reduivy__End__c;
                                
                                if(endDt.date() <= System.today()){
                                    Time checkInTime = startDt.time();
                                    Time checkOutTime = endDt.time();
                                    String attendStatus = 'Attended';
                                    String serSampleRecord = isn.reduivy__Sample_Record_Code__c + '_' + se.reduivy__Sample_Record_Code__c;
                                    studentStudyEventRelations.put(serSampleRecord, REDU_TestData_UTIL.newStudentStudyEventRelation(serSampleRecord, iensMapById.get(isn.reduivy__Individual_Enrollment__c).reduivy__Contact__c, se.Id, isn.Id, checkInTime, checkOutTime, attendStatus));
                                }
                            }
                        }
                    }
                }
    
                REDU_SystemMode_UTIL.doInsert(studentStudyEventRelations.values());
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin to view student's calendar for REDU_ContactCalendar_LCTRL.getCalendarEvents()
     */
    @isTest   
    static void testGetCalendarEventsAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get the start and end date of the current months
        Date startDate = Date.today().toStartOfMonth();
        Datetime startDatetime = Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));

        Date endDate = startDate.addDays(Date.daysInMonth(startDate.year(), startDate.month()) - 1);
        Datetime endDatetime = Datetime.newInstance(endDate, Time.newInstance(23, 59, 59, 999));

        //set enrollment status
        List<String> enrollmentStatus = new List<String>{'Enrolled', 'Completed'};

        System.runAs(ADMIN_USER){

            try{
                //put empty contact Id 
                REDU_LightningResponse objResponse = REDU_ContactCalendar_LCTRL.getCalendarEvents(null, startDatetime, endDatetime, enrollmentStatus);
                Assert.fail('REDU_ApplicationException should be thrown.');

            }catch (Exception exp){
                System.Assert.isTrue(exp.getMessage().contains(Label.Failed_To_Identify_The_Contact_For_Current_User), 'The exception is not match. The error message: ' + exp.getMessage());
            }

        }

        Test.stopTest();
    }

    /**
     * @description Test as admin to view student's calendar for REDU_ContactCalendar_LCTRL.getCalendarEvents()
     */
    @isTest   
    static void testGetCalendarEventsForStudentAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //get the start and end date of the current months
        Date startDate = Date.today().toStartOfMonth();
        Datetime startDatetime = Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));

        Date endDate = startDate.addDays(Date.daysInMonth(startDate.year(), startDate.month()) - 1);
        Datetime endDatetime = Datetime.newInstance(endDate, Time.newInstance(23, 59, 59, 999));

        //set enrollment status
        List<String> enrollmentStatus = new List<String>{'Enrolled', 'Completed'};

        //get study sessions
        Map<Id, reduivy__Study_Session__c> studySessionList = new Map<Id, reduivy__Study_Session__c>([SELECT Id, reduivy__Start_Date_Calculated__c, reduivy__End_Date_Calculated__c FROM reduivy__Study_Session__c]);

        System.runAs(ADMIN_USER){
            
            REDU_LightningResponse objResponse = REDU_ContactCalendar_LCTRL.getCalendarEvents(studentContact.Id, startDatetime, endDatetime, enrollmentStatus);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_ContactCalendar_LCTRL');

            StudyEventsWrapper calendarEventsResponse = (StudyEventsWrapper) JSON.deserialize(objResponse.responseData, StudyEventsWrapper.class);
            System.Assert.isTrue(!calendarEventsResponse.studyEvents.isEmpty(), 'The return result should not be empty.');

            for(reduivy__Study_Event__c se : calendarEventsResponse.studyEvents){

                Id ssId = se.reduivy__Study_Session_Time__r?.reduivy__Study_Session__c;
                if(ssId != null && studySessionList.containsKey(ssId)){

                    Date ssStartDate = studySessionList.get(ssId).reduivy__Start_Date_Calculated__c;
                    Date ssEndDate = studySessionList.get(ssId).reduivy__End_Date_Calculated__c;

                    //study session's start and end date should not be outside the given range
                    System.Assert.isFalse((ssStartDate < startDate && ssEndDate < startDate) || (ssStartDate > endDate && ssEndDate > endDate), 'The study session\'s start and end date range cannot be entirely before or after the given date range. Expected related in between ' + startDate + ' to ' + endDate);

                    startDate = ssStartDate;
                    endDate = ssEndDate;
                }

                //The event's start and end date should not be outside the associated study session's start and end date range
                System.Assert.isFalse((se.reduivy__Start__c < startDate && se.reduivy__End__c < startDate) || (se.reduivy__Start__c > endDate && se.reduivy__End__c > endDate), 'The study event\'s start and end date cannot be entirely before or after the given date range. Expected between ' + startDate + ' to ' + endDate);
            }
        }

        Test.stopTest();

    }

    /**
     * @description Test as admin to view faculty's calendar for REDU_ContactCalendar_LCTRL.getCalendarEvents()
     */
    @isTest   
    static void testGetCalendarEventsForFacultyAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        Contact facultyContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_FACULTY
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //get the start and end date of the current months
        Date startDate = Date.today().toStartOfMonth();
        Datetime startDatetime = Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));

        Date endDate = startDate.addDays(Date.daysInMonth(startDate.year(), startDate.month()) - 1);
        Datetime endDatetime = Datetime.newInstance(endDate, Time.newInstance(23, 59, 59, 999));

        //set enrollment status
        List<String> enrollmentStatus = new List<String>{'Enrolled', 'Completed'};

        //get study sessions
        Map<Id, reduivy__Study_Session__c> studySessionList = new Map<Id, reduivy__Study_Session__c>([SELECT Id, reduivy__Start_Date_Calculated__c, reduivy__End_Date_Calculated__c FROM reduivy__Study_Session__c]);

        System.runAs(ADMIN_USER){
            
            REDU_LightningResponse objResponse = REDU_ContactCalendar_LCTRL.getCalendarEvents(facultyContact.Id, startDatetime, endDatetime, enrollmentStatus);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_ContactCalendar_LCTRL');

            StudyEventsWrapper calendarEventsResponse = (StudyEventsWrapper) JSON.deserialize(objResponse.responseData, StudyEventsWrapper.class);
            System.Assert.isTrue(!calendarEventsResponse.studyEvents.isEmpty(), 'The return result should not be empty.');

            for(reduivy__Study_Event__c se : calendarEventsResponse.studyEvents){

                Id ssId = se.reduivy__Study_Session_Time__r?.reduivy__Study_Session__c;
                if(ssId != null && studySessionList.containsKey(ssId)){

                    Date ssStartDate = studySessionList.get(ssId).reduivy__Start_Date_Calculated__c;
                    Date ssEndDate = studySessionList.get(ssId).reduivy__End_Date_Calculated__c;

                    //study session's start and end date should not be outside the given range
                    System.Assert.isFalse((ssStartDate < startDate && ssEndDate < startDate) || (ssStartDate > endDate && ssEndDate > endDate), 'The study session\'s start and end date range cannot be entirely before or after the given date range. Expected related in between ' + startDate + ' to ' + endDate);

                    startDate = ssStartDate;
                    endDate = ssEndDate;
                }

                //The event's start and end date should not be outside the associated study session's start and end date range
                System.Assert.isFalse((se.reduivy__Start__c < startDate && se.reduivy__End__c < startDate) || (se.reduivy__Start__c > endDate && se.reduivy__End__c > endDate), 'The study event\'s start and end date cannot be entirely before or after the given date range. Expected between ' + startDate + ' to ' + endDate);
            }
        }

        Test.stopTest();

    }

    /**
     * @description Test as faculty for REDU_ContactCalendar_LCTRL.getCalendarEvents()
     */
    @isTest   
    static void testGetCalendarEventsForFaculty() {
        Test.startTest();
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact facultyContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_FACULTY
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //get the start and end date of the current months
        Date startDate = Date.today().toStartOfMonth();
        Datetime startDatetime = Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));

        Date endDate = startDate.addDays(Date.daysInMonth(startDate.year(), startDate.month()) - 1);
        Datetime endDatetime = Datetime.newInstance(endDate, Time.newInstance(23, 59, 59, 999));

        //set enrollment status
        List<String> enrollmentStatus = new List<String>{'Enrolled', 'Completed'};

        //get study sessions
        Map<Id, reduivy__Study_Session__c> studySessionList = new Map<Id, reduivy__Study_Session__c>([SELECT Id, reduivy__Start_Date_Calculated__c, reduivy__End_Date_Calculated__c FROM reduivy__Study_Session__c]);

        System.runAs(FACULTY_USER){
            
            REDU_LightningResponse objResponse = REDU_ContactCalendar_LCTRL.getCalendarEvents(facultyContact.Id, startDatetime, endDatetime, enrollmentStatus);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_ContactCalendar_LCTRL');

            StudyEventsWrapper calendarEventsResponse = (StudyEventsWrapper) JSON.deserialize(objResponse.responseData, StudyEventsWrapper.class);
            System.Assert.isTrue(!calendarEventsResponse.studyEvents.isEmpty(), 'The return result should not be empty.');

            for(reduivy__Study_Event__c se : calendarEventsResponse.studyEvents){

                Id ssId = se.reduivy__Study_Session_Time__r?.reduivy__Study_Session__c;
                if(ssId != null && studySessionList.containsKey(ssId)){

                    Date ssStartDate = studySessionList.get(ssId).reduivy__Start_Date_Calculated__c;
                    Date ssEndDate = studySessionList.get(ssId).reduivy__End_Date_Calculated__c;

                    //study session's start and end date should not be outside the given range
                    System.Assert.isFalse((ssStartDate < startDate && ssEndDate < startDate) || (ssStartDate > endDate && ssEndDate > endDate), 'The study session\'s start and end date range cannot be entirely before or after the given date range. Expected related in between ' + startDate + ' to ' + endDate);

                    startDate = ssStartDate;
                    endDate = ssEndDate;
                }

                //The event's start and end date should not be outside the associated study session's start and end date range
                System.Assert.isFalse((se.reduivy__Start__c < startDate && se.reduivy__End__c < startDate) || (se.reduivy__Start__c > endDate && se.reduivy__End__c > endDate), 'The study event\'s start and end date cannot be entirely before or after the given date range. Expected between ' + startDate + ' to ' + endDate);
            }
        }

        Test.stopTest();

    }

    /**
     * @description Test as student for REDU_ContactCalendar_LCTRL.getCalendarEvents()
     */
    @isTest   
    static void testGetCalendarEventsForStudent() {
        Test.startTest();

        Contact studentContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContact.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        //get the start and end date of the current months
        Date startDate = Date.today().toStartOfMonth();
        Datetime startDatetime = Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));

        Date endDate = startDate.addDays(Date.daysInMonth(startDate.year(), startDate.month()) - 1);
        Datetime endDatetime = Datetime.newInstance(endDate, Time.newInstance(23, 59, 59, 999));

        //set enrollment status
        List<String> enrollmentStatus = new List<String>{'Enrolled', 'Completed'};

        //get study sessions
        Map<Id, reduivy__Study_Session__c> studySessionList = new Map<Id, reduivy__Study_Session__c>([SELECT Id, reduivy__Start_Date_Calculated__c, reduivy__End_Date_Calculated__c FROM reduivy__Study_Session__c]);

        System.runAs(studentUser){
            
            REDU_LightningResponse objResponse = REDU_ContactCalendar_LCTRL.getCalendarEvents(studentContact.Id, startDatetime, endDatetime, enrollmentStatus);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_ContactCalendar_LCTRL');

            StudyEventsWrapper calendarEventsResponse = (StudyEventsWrapper) JSON.deserialize(objResponse.responseData, StudyEventsWrapper.class);
            System.Assert.isTrue(!calendarEventsResponse.studyEvents.isEmpty(), 'The return result should not be empty.');

            for(reduivy__Study_Event__c se : calendarEventsResponse.studyEvents){

                Id ssId = se.reduivy__Study_Session_Time__r?.reduivy__Study_Session__c;
                if(ssId != null && studySessionList.containsKey(ssId)){

                    Date ssStartDate = studySessionList.get(ssId).reduivy__Start_Date_Calculated__c;
                    Date ssEndDate = studySessionList.get(ssId).reduivy__End_Date_Calculated__c;

                    //study session's start and end date should not be outside the given range
                    System.Assert.isFalse((ssStartDate < startDate && ssEndDate < startDate) || (ssStartDate > endDate && ssEndDate > endDate), 'The study session\'s start and end date range cannot be entirely before or after the given date range. Expected related in between ' + startDate + ' to ' + endDate);

                    startDate = ssStartDate;
                    endDate = ssEndDate;
                }

                //The event's start and end date should not be outside the associated study session's start and end date range
                System.Assert.isFalse((se.reduivy__Start__c < startDate && se.reduivy__End__c < startDate) || (se.reduivy__Start__c > endDate && se.reduivy__End__c > endDate), 'The study event\'s start and end date cannot be entirely before or after the given date range. Expected between ' + startDate + ' to ' + endDate);
            }
        }

        Test.stopTest();

    }

    /**
     * @description Test as faculty to show both student and faculty events together for REDU_ContactCalendar_LCTRL.getCalendarEvents()
     */
    @isTest   
    static void testGetCalendarEventsForFacultyStudent() {
        Test.startTest();
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Contact facultyContact = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_FACULTY
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //get the start and end date of the current months
        Date startDate = Date.today().toStartOfMonth();
        Datetime startDatetime = Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));

        Date endDate = startDate.addDays(Date.daysInMonth(startDate.year(), startDate.month()) - 1);
        Datetime endDatetime = Datetime.newInstance(endDate, Time.newInstance(23, 59, 59, 999));

        //set enrollment status
        List<String> enrollmentStatus = new List<String>{'Enrolled', 'Completed'};


        //add individual enrollment
        List<reduivy__Individual_Enrollment__c> facultyIndividualEnrollments = new List<reduivy__Individual_Enrollment__c>();
        facultyIndividualEnrollments.add(REDU_TestData_UTIL.newFacultyIndividualEnrollment('ienTestContactCalendar', facultyContact.Id, null, null));
        REDU_SystemMode_UTIL.doInsert(facultyIndividualEnrollments);
        
        //get study sessions
        Map<Id, reduivy__Study_Session__c> studySessionList = new Map<Id, reduivy__Study_Session__c>([SELECT Id, reduivy__Start_Date_Calculated__c, reduivy__End_Date_Calculated__c FROM reduivy__Study_Session__c]);

        //add individual session enrollment
        List<reduivy__Individual_Session_Enrollment__c> facultyIndividualSessionEnrollments = new List<reduivy__Individual_Session_Enrollment__c>();
        Id firstSsId = studySessionList.values().get(0).Id;
        facultyIndividualSessionEnrollments.add(REDU_TestData_UTIL.newFacultyIndividualSessionEnrollment('isnTestContactCalendar', firstSsId, facultyIndividualEnrollments[0].Id, 'Lecturer', startDate, 'Enrolled'));
        REDU_SystemMode_UTIL.doInsert(facultyIndividualSessionEnrollments);

        //get study session time associated to the first study event in list
        Map<Id, reduivy__Study_Session_Time__c> sstList = new Map<Id, reduivy__Study_Session_Time__c>([
            SELECT Id, reduivy__Study_Session__c 
            FROM reduivy__Study_Session_Time__c 
            WHERE reduivy__Study_Session__c = :firstSsId
        ]);

        System.runAs(FACULTY_USER){
            
            REDU_LightningResponse objResponse = REDU_ContactCalendar_LCTRL.getCalendarEvents(facultyContact.Id, startDatetime, endDatetime, enrollmentStatus);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_ContactCalendar_LCTRL');

            StudyEventsWrapper calendarEventsResponse = (StudyEventsWrapper) JSON.deserialize(objResponse.responseData, StudyEventsWrapper.class);
            System.Assert.isTrue(!calendarEventsResponse.studyEvents.isEmpty(), 'The return result should not be empty.');

            Boolean isStudentEventExist = false;
            for(reduivy__Study_Event__c se : calendarEventsResponse.studyEvents){

                //to flag the events if student individual session enrollment have included
                if(!sstList.isEmpty() && sstList.containsKey(se.reduivy__Study_Session_Time__c)){
                    isStudentEventExist = true;
                }
                
                Id ssId = se.reduivy__Study_Session_Time__r?.reduivy__Study_Session__c;
                if(ssId != null && studySessionList.containsKey(ssId)){

                    Date ssStartDate = studySessionList.get(ssId).reduivy__Start_Date_Calculated__c;
                    Date ssEndDate = studySessionList.get(ssId).reduivy__End_Date_Calculated__c;

                    //study session's start and end date should not be outside the given range
                    System.Assert.isFalse((ssStartDate < startDate && ssEndDate < startDate) || (ssStartDate > endDate && ssEndDate > endDate), 'The study session\'s start and end date range cannot be entirely before or after the given date range. Expected related in between ' + startDate + ' to ' + endDate);

                    startDate = ssStartDate;
                    endDate = ssEndDate;
                }

                //The event's start and end date should not be outside the associated study session's start and end date range
                System.Assert.isFalse((se.reduivy__Start__c < startDate && se.reduivy__End__c < startDate) || (se.reduivy__Start__c > endDate && se.reduivy__End__c > endDate), 'The study event\'s start and end date cannot be entirely before or after the given date range. Expected between ' + startDate + ' to ' + endDate);
            }

            //check the flag to make sure student individual session enrollment have included
            System.Assert.isTrue(isStudentEventExist, 'Student\'s event should be exist.');
        }

        Test.stopTest();

    }

    private class StudyEventsWrapper {

        public List<reduivy__Study_Event__c> studyEvents;
        public Map<String, String> translationNames;

    }
}