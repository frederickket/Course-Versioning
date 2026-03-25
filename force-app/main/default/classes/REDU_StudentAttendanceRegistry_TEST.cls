/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Test
 * @description Test class for REDU_StudentAttendanceRegistry_LCTRL
 * @changehistory
 * ISS-001919 12-08-2024 Lean - new class
 */
@IsTest
public inherited sharing class REDU_StudentAttendanceRegistry_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    static String sampleSessionKey = 'Lecture_MGT301_CYT1_SYDNEY';
    static Set<String> serFields = new Set<String>{'reduivy__Notes__c', 'reduivy__Check_In__c', 'reduivy__Check_Out__c', 'reduivy__Allow_Conflict__c'};

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
     * @description Test get fields as admin
     */
    @IsTest
    static void testGetFieldsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudentAttendanceRegistry_LCTRL.getFields('reduivy__AttendanceWizard_Notes', 'reduivy__Study_Event_Relation__c');
            System.Assert.areEqual(true, response.isSuccess);
            
            List<REDU_DynamicFieldValue_OBJ> fields = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(response.responseData, List<REDU_DynamicFieldValue_OBJ>.class);
            for (REDU_DynamicFieldValue_OBJ field : fields) {
                System.Assert.isTrue(serFields.contains(field.fieldName));
            }
            
        }
        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with new attendance as admin
     */
    @IsTest
    static void testGetStudentAttendanceWithNewDataAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];
        
        REDU_LightningResponse sevResponse;
        System.runAs(ADMIN_USER){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }
        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        //we delete the sample data to simulate the initialization of new attendance
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Event_Relation__c WHERE reduivy__Individual_Session_Enrollment__c IN: studentIsnList]);

        System.runAs(ADMIN_USER){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(studentIsnList.size(), attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(null, ser.Id, 'The id should be null for new records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with new attendance and start/end date within range as admin
     */
    @IsTest
    static void testGetStudentAttendanceWithNewDataAndDateInRangeAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];
        
        REDU_LightningResponse sevResponse;
        System.runAs(ADMIN_USER){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }

        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList) {
            isn.reduivy__Start_Date__c = testFactory.currentYearTerm1StartDate.addDays(-1);
            isn.reduivy__End_Date__c = testFactory.currentYearTerm1StartDate.addDays(1);
        }

        REDU_SystemMode_UTIL.doUpdate(studentIsnList);

        //we delete the sample data to simulate the initialization of new attendance
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Event_Relation__c WHERE reduivy__Individual_Session_Enrollment__c IN: studentIsnList]);

        System.runAs(ADMIN_USER){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(studentIsnList.size(), attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(null, ser.Id, 'The id should be null for new records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with new attendance and start/end date out of range as admin
     */
    @IsTest
    static void testGetStudentAttendanceWithNewDataAndDateOutOfRangeAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];
        
        REDU_LightningResponse sevResponse;
        System.runAs(ADMIN_USER){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }

        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList) {
            isn.reduivy__Start_Date__c = testFactory.currentYearTerm1StartDate.addDays(10);
            isn.reduivy__End_Date__c = testFactory.currentYearTerm1StartDate.addDays(11);
        }

        REDU_SystemMode_UTIL.doUpdate(studentIsnList);

        //we delete the sample data to simulate the initialization of new attendance
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Event_Relation__c WHERE reduivy__Individual_Session_Enrollment__c IN: studentIsnList]);

        System.runAs(ADMIN_USER){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(0, attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(null, ser.Id, 'The id should be null for new records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with new attendance and withdrawn date within range as admin
     */
    @IsTest
    static void testGetStudentAttendanceWithNewDataAndWithdrawnDateInRangeAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];
        
        REDU_LightningResponse sevResponse;
        System.runAs(ADMIN_USER){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }

        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList) {
            isn.reduivy__Withdrawal_Date__c = testFactory.currentYearTerm1EndDate;
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getWithdrawnStatuses().get(0);
        }

        REDU_SystemMode_UTIL.doUpdate(studentIsnList);
        
        //we delete the sample data to simulate the initialization of new attendance
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Event_Relation__c WHERE reduivy__Individual_Session_Enrollment__c IN: studentIsnList]);

        System.runAs(ADMIN_USER){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(studentIsnList.size(), attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(null, ser.Id, 'The id should be null for new records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with new attendance and withdrawn date out of range as admin
     */
    @IsTest
    static void testGetStudentAttendanceWithNewDataAndWithdrawnDateOutOfRangeAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];
        
        REDU_LightningResponse sevResponse;
        System.runAs(ADMIN_USER){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }

        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList) {
            isn.reduivy__Withdrawal_Date__c = testFactory.currentYearTerm1StartDate.addDays(-1);
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getWithdrawnStatuses().get(0);
        }

        REDU_SystemMode_UTIL.doUpdate(studentIsnList);

        //we delete the sample data to simulate the initialization of new attendance
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Event_Relation__c WHERE reduivy__Individual_Session_Enrollment__c IN: studentIsnList]);

        System.runAs(ADMIN_USER){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(0, attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(null, ser.Id, 'The id should be null for new records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with existing attendance as admin
     */
    @IsTest
    static void testGetStudentAttendanceWithExistingDataAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];

        REDU_LightningResponse sevResponse;
        System.runAs(ADMIN_USER){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }

        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        System.runAs(ADMIN_USER){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(studentIsnList.size(), attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(true, String.isNotBlank(ser.Id), 'The id should not be null for existing records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with existing attendance as admin and start/end date in range
     */
    @IsTest
    static void testGetStudentAttendanceWithExistingDataAndDateInRangeAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];

        REDU_LightningResponse sevResponse;
        System.runAs(ADMIN_USER){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }

        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList) {
            isn.reduivy__Start_Date__c = testFactory.currentYearTerm1StartDate.addDays(-1);
            isn.reduivy__End_Date__c = testFactory.currentYearTerm1StartDate.addDays(1);
        }

        REDU_SystemMode_UTIL.doUpdate(studentIsnList);

        System.runAs(ADMIN_USER){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(studentIsnList.size(), attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(true, String.isNotBlank(ser.Id), 'The id should not be null for existing records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with existing attendance as admin and start/end date out of range
     */
    @IsTest
    static void testGetStudentAttendanceWithExistingDataAndDateOutOfRangeAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];

        REDU_LightningResponse sevResponse;
        System.runAs(ADMIN_USER){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }
    
        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList) {
            isn.reduivy__Start_Date__c = testFactory.currentYearTerm1StartDate.addDays(10);
            isn.reduivy__End_Date__c = testFactory.currentYearTerm1StartDate.addDays(11);
        }

        REDU_SystemMode_UTIL.doUpdate(studentIsnList);

        System.runAs(ADMIN_USER){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(0, attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(true, String.isNotBlank(ser.Id), 'The id should not be null for existing records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with existing attendance and withdrawn date in rage as admin
     */
    @IsTest
    static void testGetStudentAttendanceWithExistingDataAndWithdrawnDateInRangeAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];

        REDU_LightningResponse sevResponse;
        System.runAs(ADMIN_USER){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }
    
        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList) {
            isn.reduivy__Withdrawal_Date__c = testFactory.currentYearTerm1EndDate;
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getWithdrawnStatuses().get(0);
        }

        REDU_SystemMode_UTIL.doUpdate(studentIsnList);

        System.runAs(ADMIN_USER){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(studentIsnList.size(), attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(true, String.isNotBlank(ser.Id), 'The id should not be null for existing records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with existing attendance and withdrawn date out of range as admin
     */
    @IsTest
    static void testGetStudentAttendanceWithExistingDataAndWithdrawnDateOutOfRangeAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];

        REDU_LightningResponse sevResponse;
        System.runAs(ADMIN_USER){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }
    
        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList) {
            isn.reduivy__Withdrawal_Date__c = testFactory.currentYearTerm1StartDate.addDays(-1);
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getWithdrawnStatuses().get(0);
        }

        REDU_SystemMode_UTIL.doUpdate(studentIsnList);

        System.runAs(ADMIN_USER){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(0, attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(true, String.isNotBlank(ser.Id), 'The id should not be null for existing records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test save student attendance with new attendance as admin
     */
    @IsTest
    static void testSaveStudentAttendanceWithNewDataAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];
        
        REDU_LightningResponse sevResponse;
        System.runAs(ADMIN_USER){
            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
        }

        System.Assert.areEqual(true, sevResponse.isSuccess);
        System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));

        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        //we delete the sample data to simulate the initialization of new attendance
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Event_Relation__c WHERE reduivy__Individual_Session_Enrollment__c IN: studentIsnList]);
        
        System.runAs(ADMIN_USER){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(studentIsnList.size(), attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(null, ser.Id, 'The id should be null for new records.');
                ser.reduivy__Attendance_Status__c = SER_Helper.ATTENDANCE_STATUS_ATTENDED;
            }

            REDU_LightningResponse saveResponse = REDU_StudentAttendanceRegistry_LCTRL.saveStudentAttendances(JSON.serialize(attendanceSers));
            System.Assert.isTrue(saveResponse.isSuccess);
            System.Assert.areEqual(Label.Your_Changes_Are_Saved, saveResponse.message);
        }

        List<reduivy__Study_Event_Relation__c> savedAttendanceSers = [SELECT Id,
            reduivy__Attendance_Status__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Individual_Session_Enrollment__c IN: studentIsnList
        ];

        System.Assert.areEqual(studentIsnList.size(), savedAttendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

        for (reduivy__Study_Event_Relation__c ser : savedAttendanceSers) {
            System.Assert.areEqual(SER_Helper.ATTENDANCE_STATUS_ATTENDED, ser.reduivy__Attendance_Status__c);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test save student attendance with existing attendance as admin
     */
    @IsTest
    static void testSaveStudentAttendanceWithExistingDataAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];

        REDU_LightningResponse sevResponse;
        System.runAs(ADMIN_USER){
            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
        }

        System.Assert.areEqual(true, sevResponse.isSuccess);
        System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));

        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        System.runAs(ADMIN_USER){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(studentIsnList.size(), attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(true, String.isNotBlank(ser.Id), 'The id should not be null for new records.');
                ser.reduivy__Attendance_Status__c = SER_Helper.ATTENDANCE_STATUS_ATTENDED;
            }

            REDU_LightningResponse saveResponse = REDU_StudentAttendanceRegistry_LCTRL.saveStudentAttendances(JSON.serialize(attendanceSers));
            System.Assert.isTrue(saveResponse.isSuccess);
            System.Assert.areEqual(Label.Your_Changes_Are_Saved, saveResponse.message);
        }

        List<reduivy__Study_Event_Relation__c> savedAttendanceSers = [SELECT Id,
            reduivy__Attendance_Status__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Individual_Session_Enrollment__c IN: studentIsnList
        ];

        System.Assert.areEqual(studentIsnList.size(), savedAttendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

        for (reduivy__Study_Event_Relation__c ser : savedAttendanceSers) {
            System.Assert.areEqual(SER_Helper.ATTENDANCE_STATUS_ATTENDED, ser.reduivy__Attendance_Status__c);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get fields as faculty
     */
    @IsTest
    static void testGetFieldsAsFaculty(){
        
        Test.startTest();
        System.runAs(testFactory.getAllocatedFacultyUser()){
            REDU_LightningResponse response = REDU_StudentAttendanceRegistry_LCTRL.getFields('reduivy__AttendanceWizard_Notes', 'reduivy__Study_Event_Relation__c');
            System.Assert.areEqual(true, response.isSuccess);
            
            List<REDU_DynamicFieldValue_OBJ> fields = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(response.responseData, List<REDU_DynamicFieldValue_OBJ>.class);
            for (REDU_DynamicFieldValue_OBJ field : fields) {
                System.Assert.isTrue(serFields.contains(field.fieldName));
            }
            
        }
        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with new attendance as faculty
     */
    @IsTest
    static void testGetStudentAttendanceWithNewDataAsFaculty(){
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];
        
        User facultyUser = testFactory.getAllocatedFacultyUser();

        REDU_LightningResponse sevResponse;
        System.runAs(facultyUser){
            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_FACULTY, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
        }

        System.Assert.areEqual(true, sevResponse.isSuccess);
        System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));

        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        //we delete the sample data to simulate the initialization of new attendance
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Event_Relation__c WHERE reduivy__Individual_Session_Enrollment__c IN: studentIsnList]);

        System.runAs(facultyUser){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(studentIsnList.size(), attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(null, ser.Id, 'The id should be null for new records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with new attendance and start/end date within range as faculty
     */
    @IsTest
    static void testGetStudentAttendanceWithNewDataAndDateInRangeAsFaculty(){
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];
        
        User facultyUser = testFactory.getAllocatedFacultyUser();
        REDU_LightningResponse sevResponse;
        System.runAs(facultyUser){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }

        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList) {
            isn.reduivy__Start_Date__c = testFactory.currentYearTerm1StartDate.addDays(-1);
            isn.reduivy__End_Date__c = testFactory.currentYearTerm1StartDate.addDays(1);
        }

        REDU_SystemMode_UTIL.doUpdate(studentIsnList);

        //we delete the sample data to simulate the initialization of new attendance
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Event_Relation__c WHERE reduivy__Individual_Session_Enrollment__c IN: studentIsnList]);

        System.runAs(facultyUser){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(studentIsnList.size(), attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(null, ser.Id, 'The id should be null for new records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with new attendance and start/end date out of range as faculty
     */
    @IsTest
    static void testGetStudentAttendanceWithNewDataAndDateOutOfRangeAsFaculty(){
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];
        
        User facultyUser = testFactory.getAllocatedFacultyUser();
        REDU_LightningResponse sevResponse;
        System.runAs(facultyUser){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }

        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList) {
            isn.reduivy__Start_Date__c = testFactory.currentYearTerm1StartDate.addDays(10);
            isn.reduivy__End_Date__c = testFactory.currentYearTerm1StartDate.addDays(11);
        }

        REDU_SystemMode_UTIL.doUpdate(studentIsnList);

        //we delete the sample data to simulate the initialization of new attendance
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Event_Relation__c WHERE reduivy__Individual_Session_Enrollment__c IN: studentIsnList]);

        System.runAs(facultyUser){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(0, attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(null, ser.Id, 'The id should be null for new records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with new attendance and withdrawn date within range as faculty
     */
    @IsTest
    static void testGetStudentAttendanceWithNewDataAndWithdrawnDateInRangeAsFaculty(){
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];
        
        User facultyUser = testFactory.getAllocatedFacultyUser();
        REDU_LightningResponse sevResponse;
        System.runAs(facultyUser){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }

        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList) {
            isn.reduivy__Withdrawal_Date__c = testFactory.currentYearTerm1EndDate;
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getWithdrawnStatuses().get(0);
        }

        REDU_SystemMode_UTIL.doUpdate(studentIsnList);
        
        //we delete the sample data to simulate the initialization of new attendance
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Event_Relation__c WHERE reduivy__Individual_Session_Enrollment__c IN: studentIsnList]);

        System.runAs(facultyUser){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(studentIsnList.size(), attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(null, ser.Id, 'The id should be null for new records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with new attendance and withdrawn date out of range as faculty
     */
    @IsTest
    static void testGetStudentAttendanceWithNewDataAndWithdrawnDateOutOfRangeAsFaculty(){
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];
        
        User facultyUser = testFactory.getAllocatedFacultyUser();
        REDU_LightningResponse sevResponse;
        System.runAs(facultyUser){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }

        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList) {
            isn.reduivy__Withdrawal_Date__c = testFactory.currentYearTerm1StartDate.addDays(-1);
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getWithdrawnStatuses().get(0);
        }

        REDU_SystemMode_UTIL.doUpdate(studentIsnList);

        //we delete the sample data to simulate the initialization of new attendance
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Event_Relation__c WHERE reduivy__Individual_Session_Enrollment__c IN: studentIsnList]);

        System.runAs(facultyUser){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(0, attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(null, ser.Id, 'The id should be null for new records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with existing attendance as faculty
     */
    @IsTest
    static void testGetStudentAttendanceWithExistingDataAsFaculty(){
        
        Test.startTest();
        
        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];

        User facultyUser = testFactory.getAllocatedFacultyUser();
        REDU_LightningResponse sevResponse;
        System.runAs(facultyUser){
            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_FACULTY, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
        }

        System.Assert.areEqual(true, sevResponse.isSuccess);
        System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));

        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        System.runAs(facultyUser){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(studentIsnList.size(), attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(true, String.isNotBlank(ser.Id), 'The id should not be null for existing records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with existing attendance as faculty and start/end date in range
     */
    @IsTest
    static void testGetStudentAttendanceWithExistingDataAndDateInRangeAsfaculty(){
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];

        User facultyUser = testFactory.getAllocatedFacultyUser();

        REDU_LightningResponse sevResponse;
        System.runAs(facultyUser){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }

        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList) {
            isn.reduivy__Start_Date__c = testFactory.currentYearTerm1StartDate.addDays(-1);
            isn.reduivy__End_Date__c = testFactory.currentYearTerm1StartDate.addDays(1);
        }

        REDU_SystemMode_UTIL.doUpdate(studentIsnList);

        System.runAs(facultyUser){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(studentIsnList.size(), attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(true, String.isNotBlank(ser.Id), 'The id should not be null for existing records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with existing attendance as faculty and start/end date out of range
     */
    @IsTest
    static void testGetStudentAttendanceWithExistingDataAndDateOutOfRangeAsFaculty(){
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];

        User facultyUser = testFactory.getAllocatedFacultyUser();

        REDU_LightningResponse sevResponse;
        System.runAs(facultyUser){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }
    
        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList) {
            isn.reduivy__Start_Date__c = testFactory.currentYearTerm1StartDate.addDays(10);
            isn.reduivy__End_Date__c = testFactory.currentYearTerm1StartDate.addDays(11);
        }

        REDU_SystemMode_UTIL.doUpdate(studentIsnList);

        System.runAs(facultyUser){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(0, attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(true, String.isNotBlank(ser.Id), 'The id should not be null for existing records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with existing attendance and withdrawn date in rage as faculty
     */
    @IsTest
    static void testGetStudentAttendanceWithExistingDataAndWithdrawnDateInRangeAsFaculty(){
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];

        User facultyUser = testFactory.getAllocatedFacultyUser();

        REDU_LightningResponse sevResponse;
        System.runAs(facultyUser){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }
    
        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList) {
            isn.reduivy__Withdrawal_Date__c = testFactory.currentYearTerm1EndDate;
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getWithdrawnStatuses().get(0);
        }

        REDU_SystemMode_UTIL.doUpdate(studentIsnList);

        System.runAs(facultyUser){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(studentIsnList.size(), attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(true, String.isNotBlank(ser.Id), 'The id should not be null for existing records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get student attendance with existing attendance and withdrawn date out of range as faculty
     */
    @IsTest
    static void testGetStudentAttendanceWithExistingDataAndWithdrawnDateOutOfRangeAsFaculty(){
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];

        User facultyUser = testFactory.getAllocatedFacultyUser();

        REDU_LightningResponse sevResponse;
        System.runAs(facultyUser){

            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_ADMIN, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
            System.Assert.areEqual(true, sevResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));
        }
    
        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList) {
            isn.reduivy__Withdrawal_Date__c = testFactory.currentYearTerm1StartDate.addDays(-1);
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getWithdrawnStatuses().get(0);
        }

        REDU_SystemMode_UTIL.doUpdate(studentIsnList);

        System.runAs(facultyUser){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(0, attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(true, String.isNotBlank(ser.Id), 'The id should not be null for existing records.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test save student attendance with new attendance as faculty
     */
    @IsTest
    static void testSaveStudentAttendanceWithNewDataAsFaculty(){
        
        Test.startTest();

        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];
        
        User facultyUser = testFactory.getAllocatedFacultyUser();

        REDU_LightningResponse sevResponse;
        System.runAs(facultyUser){
            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_FACULTY, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
        }

        System.Assert.areEqual(true, sevResponse.isSuccess);
        System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));

        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        //we delete the sample data to simulate the initialization of new attendance
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Event_Relation__c WHERE reduivy__Individual_Session_Enrollment__c IN: studentIsnList]);

        System.runAs(facultyUser){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(studentIsnList.size(), attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(null, ser.Id, 'The id should be null for new records.');
                ser.reduivy__Attendance_Status__c = SER_Helper.ATTENDANCE_STATUS_ATTENDED;
            }

            REDU_LightningResponse saveResponse = REDU_StudentAttendanceRegistry_LCTRL.saveStudentAttendances(JSON.serialize(attendanceSers));
            System.Assert.isTrue(saveResponse.isSuccess);
            System.Assert.areEqual(Label.Your_Changes_Are_Saved, saveResponse.message);
        }

        List<reduivy__Study_Event_Relation__c> savedAttendanceSers = [SELECT Id,
            reduivy__Attendance_Status__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Individual_Session_Enrollment__c IN: studentIsnList
        ];

        System.Assert.areEqual(studentIsnList.size(), savedAttendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

        for (reduivy__Study_Event_Relation__c ser : savedAttendanceSers) {
            System.Assert.areEqual(SER_Helper.ATTENDANCE_STATUS_ATTENDED, ser.reduivy__Attendance_Status__c);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test save student attendance with existing attendance as faculty
     */
    @IsTest
    static void testSaveStudentAttendanceWithExistingDataAsFaculty(){
        
        Test.startTest();
        
        reduivy__Study_Session__c testSession = [SELECT Id 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c =: sampleSessionKey
        ];

        User facultyUser = testFactory.getAllocatedFacultyUser();
        REDU_LightningResponse sevResponse;
        System.runAs(facultyUser){
            sevResponse = REDU_StudentAttendance_LCTRL.getStudyEvents(testSession.Id, USR_Helper.USER_MODE_FACULTY, testFactory.currentYearTerm1StartDate, ISN_INPROGRESS_STATUS, true);
        }

        System.Assert.areEqual(true, sevResponse.isSuccess);
        System.Assert.isTrue(String.isNotBlank(sevResponse.responseData));

        List<reduivy__Study_Event__c> studyEvents = (List<reduivy__Study_Event__c>) JSON.deserialize(sevResponse.responseData, List<reduivy__Study_Event__c>.class);
        
        System.Assert.areEqual(1, studyEvents.size(), 'There should be 1 study events.');

        reduivy__Study_Event__c workingSev = studyEvents.get(0);
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Enrollment_Status__c,
            RecordTypeId,
            reduivy__Contact_Id__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c =: workingSev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ];

        System.runAs(facultyUser){
            REDU_LightningResponse attendanceResponse = REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances(workingSev.Id, 'reduivy__AttendanceWizard_Notes');
            System.Assert.areEqual(true, attendanceResponse.isSuccess);
            System.Assert.isTrue(String.isNotBlank(attendanceResponse.responseData));

            List<reduivy__Study_Event_Relation__c> attendanceSers = (List<reduivy__Study_Event_Relation__c>) JSON.deserialize(attendanceResponse.responseData, List<reduivy__Study_Event_Relation__c>.class);

            System.Assert.areEqual(studentIsnList.size(), attendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

            for (reduivy__Study_Event_Relation__c ser : attendanceSers) {
                System.Assert.areEqual(true, String.isNotBlank(ser.Id), 'The id should not be null for existing records.');
                ser.reduivy__Attendance_Status__c = SER_Helper.ATTENDANCE_STATUS_ATTENDED;
            }

            REDU_LightningResponse saveResponse = REDU_StudentAttendanceRegistry_LCTRL.saveStudentAttendances(JSON.serialize(attendanceSers));
            System.Assert.isTrue(saveResponse.isSuccess);
            System.Assert.areEqual(Label.Your_Changes_Are_Saved, saveResponse.message);
        }
        
        List<reduivy__Study_Event_Relation__c> savedAttendanceSers = [SELECT Id,
            reduivy__Attendance_Status__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Individual_Session_Enrollment__c IN: studentIsnList
        ];

        System.Assert.areEqual(studentIsnList.size(), savedAttendanceSers.size(), 'The number of students does not match with the study event relation attendance records');

        for (reduivy__Study_Event_Relation__c ser : savedAttendanceSers) {
            System.Assert.areEqual(SER_Helper.ATTENDANCE_STATUS_ATTENDED, ser.reduivy__Attendance_Status__c);
        }

        Test.stopTest();
        
    }
}