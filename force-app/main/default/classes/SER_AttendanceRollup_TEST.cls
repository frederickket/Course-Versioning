/**
 * @author      WDCi (Sueanne)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for SER_AttendanceRollup_EXE
 * @changehistory
 * ISS-002049 27-06-2024 Sueanne - new class
 */
@isTest
public inherited sharing class SER_AttendanceRollup_TEST {

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

            Test.startTest();

        	testFactory.initMasterData(SPL_Helper.getApiName());
            testFactory.initOfferingData(null);
            testFactory.initStudentData(SER_Helper.getApiName(), true);
            
            Test.stopTest();
		}
    }

    //-------------- test for Total Attended --------------
    /**
     * @description Test as admin for rollup total attended after insert study event relation
     */
    @isTest
    static void testTotalAttendedAfterInsertAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String ISN_STUDENT_RTID = ISN_Helper.getStudentRecordTypeId();
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get individual session enrollment
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE RecordTypeId = :ISN_STUDENT_RTID
        ]);

        //get current Total Attended
        Map<Id, Integer> isnCountAttendance = new Map<Id, Integer>();
        for(SObject sobj : [
            SELECT COUNT(Id) countResult, reduivy__Individual_Session_Enrollment__c
            FROM reduivy__Study_Event_Relation__c 
            WHERE reduivy__Individual_Session_Enrollment__c IN :isnMap.keySet()
            AND reduivy__Attendance_Status__c IN :TOTAL_ATTENDED_STATUSES
            AND reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
            GROUP BY reduivy__Individual_Session_Enrollment__c
        ]){
            isnCountAttendance.put((Id)sobj.get('reduivy__Individual_Session_Enrollment__c'), (Integer)sobj.get('countResult'));
        }

        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //get study event
        List<reduivy__Study_Event__c> studyEvent = [SELECT Id
            FROM reduivy__Study_Event__c 
            LIMIT 1
        ];
        
        //create study event relation
        Integer randomIndex = Math.round(Math.random());
        List<reduivy__Study_Event_Relation__c> serToInsert = new List<reduivy__Study_Event_Relation__c>();

        for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
            serToInsert.add(REDU_TestData_UTIL.newStudentStudyEventRelation('To test attendance rollup', studentContact[0].Id, studyEvent[0].Id, isn.Id, null, null, TOTAL_ATTENDED_STATUSES[randomIndex]));
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doInsert(serToInsert);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnCountAttendance.keySet()
        ]){
            System.Assert.areEqual(isnCountAttendance.get(isn.Id) + 1, isn.reduivy__Total_Attended__c, 'Individual session enrollment\'s total attended amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup total attended after update study event relation
     */
    @isTest
    static void testTotalAttendedAfterUpdateAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();

        //update to other status first 
        //(due to data factory attendance status are 'Attended', we need to update to other status first for test Total Attended rollup)
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ABSENT_STATUS;
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //update as attended status
        Integer randomIndex = Math.round(Math.random());

        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ATTENDED_STATUSES[randomIndex];

            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doUpdate(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Attended__c, 'Individual session enrollment\'s total attended amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup total attended after delete study event relation
     */
    @isTest
    static void testTotalAttendedAfterDeleteAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        //update to attended status
        Integer randomIndex = Math.round(Math.random());
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ATTENDED_STATUSES[randomIndex];
        }
        REDU_SystemMode_UTIL.doUpdate(serList);
        
        //get isn Id
        Set<Id> isnIds = new Set<Id>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            isnIds.add(ser.reduivy__Individual_Session_Enrollment__c);
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doDelete(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnIds
        ]){
            System.Assert.areEqual(0, isn.reduivy__Total_Attended__c, 'Individual session enrollment\'s total attended amount should be 0.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup total attended after undelete study event relation
     */
    @isTest
    static void testTotalAttendedAfterUndeleteAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];
        
        //update to attended status
        Integer randomIndex = Math.round(Math.random());
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ATTENDED_STATUSES[randomIndex];
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //get isn Id
        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            
            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doDelete(serList);

            undelete serList;
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Attended__c, 'Individual session enrollment\'s total attended amount should be 0.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup total attended after insert study event relation
     */
    @isTest
    static void testTotalAttendedAfterInsertAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String ISN_STUDENT_RTID = ISN_Helper.getStudentRecordTypeId();
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get individual session enrollment
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE RecordTypeId = :ISN_STUDENT_RTID
        ]);

        //get current Total Attended
        Map<Id, Integer> isnCountAttendance = new Map<Id, Integer>();
        for(SObject sobj : [
            SELECT COUNT(Id) countResult, reduivy__Individual_Session_Enrollment__c
            FROM reduivy__Study_Event_Relation__c 
            WHERE reduivy__Individual_Session_Enrollment__c IN :isnMap.keySet()
            AND reduivy__Attendance_Status__c IN :TOTAL_ATTENDED_STATUSES
            AND reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
            GROUP BY reduivy__Individual_Session_Enrollment__c
        ]){
            isnCountAttendance.put((Id)sobj.get('reduivy__Individual_Session_Enrollment__c'), (Integer)sobj.get('countResult'));
        }

        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //get study event
        List<reduivy__Study_Event__c> studyEvent = [SELECT Id
            FROM reduivy__Study_Event__c 
            LIMIT 1
        ];
        
        //create study event relation
        Integer randomIndex = Math.round(Math.random());
        List<reduivy__Study_Event_Relation__c> serToInsert = new List<reduivy__Study_Event_Relation__c>();

        for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
            serToInsert.add(REDU_TestData_UTIL.newStudentStudyEventRelation('To test attendance rollup', studentContact[0].Id, studyEvent[0].Id, isn.Id, null, null, TOTAL_ATTENDED_STATUSES[randomIndex]));
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doInsert(serToInsert);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnCountAttendance.keySet()
        ]){
            System.Assert.areEqual(isnCountAttendance.get(isn.Id) + 1, isn.reduivy__Total_Attended__c, 'Individual session enrollment\'s total attended amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup total attended after update study event relation
     */
    @isTest
    static void testTotalAttendedAfterUpdateAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();

        //update to other status first 
        //(due to data factory attendance status are 'Attended', we need to update to other status first for test Total Attended rollup)
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ABSENT_STATUS;
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //update as attended status
        Integer randomIndex = Math.round(Math.random());

        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ATTENDED_STATUSES[randomIndex];

            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doUpdate(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Attended__c, 'Individual session enrollment\'s total attended amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup total attended after delete study event relation
     */
    @isTest
    static void testTotalAttendedAfterDeleteAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        //update to attended status
        Integer randomIndex = Math.round(Math.random());
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ATTENDED_STATUSES[randomIndex];
        }
        REDU_SystemMode_UTIL.doUpdate(serList);
        
        //get isn Id
        Set<Id> isnIds = new Set<Id>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            isnIds.add(ser.reduivy__Individual_Session_Enrollment__c);
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doDelete(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnIds
        ]){
            System.Assert.areEqual(0, isn.reduivy__Total_Attended__c, 'Individual session enrollment\'s total attended amount should be 0.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup total attended after undelete study event relation
     */
    @isTest
    static void testTotalAttendedAfterUndeleteAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];
        
        //update to attended status
        Integer randomIndex = Math.round(Math.random());
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ATTENDED_STATUSES[randomIndex];
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //get isn Id
        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            
            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doDelete(serList);

            undelete serList;
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Attended__c, 'Individual session enrollment\'s total attended amount should be 0.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup total attended after insert study event relation
     */
    @isTest
    static void testTotalAttendedAfterInsertAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String ISN_STUDENT_RTID = ISN_Helper.getStudentRecordTypeId();
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get individual session enrollment
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE RecordTypeId = :ISN_STUDENT_RTID
        ]);

        //get current Total Attended
        Map<Id, Integer> isnCountAttendance = new Map<Id, Integer>();
        for(SObject sobj : [
            SELECT COUNT(Id) countResult, reduivy__Individual_Session_Enrollment__c
            FROM reduivy__Study_Event_Relation__c 
            WHERE reduivy__Individual_Session_Enrollment__c IN :isnMap.keySet()
            AND reduivy__Attendance_Status__c IN :TOTAL_ATTENDED_STATUSES
            AND reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
            GROUP BY reduivy__Individual_Session_Enrollment__c
        ]){
            isnCountAttendance.put((Id)sobj.get('reduivy__Individual_Session_Enrollment__c'), (Integer)sobj.get('countResult'));
        }

        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //get study event
        List<reduivy__Study_Event__c> studyEvent = [SELECT Id
            FROM reduivy__Study_Event__c 
            LIMIT 1
        ];
        
        //create study event relation
        Integer randomIndex = Math.round(Math.random());
        List<reduivy__Study_Event_Relation__c> serToInsert = new List<reduivy__Study_Event_Relation__c>();

        for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
            serToInsert.add(REDU_TestData_UTIL.newStudentStudyEventRelation('To test attendance rollup', studentContact[0].Id, studyEvent[0].Id, isn.Id, null, null, TOTAL_ATTENDED_STATUSES[randomIndex]));
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doInsert(serToInsert);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnCountAttendance.keySet()
        ]){
            System.Assert.areEqual(isnCountAttendance.get(isn.Id) + 1, isn.reduivy__Total_Attended__c, 'Individual session enrollment\'s total attended amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup total attended after update study event relation
     */
    @isTest
    static void testTotalAttendedAfterUpdateAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();

        //update to other status first 
        //(due to data factory attendance status are 'Attended', we need to update to other status first for test Total Attended rollup)
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ABSENT_STATUS;
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //update as attended status
        Integer randomIndex = Math.round(Math.random());

        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ATTENDED_STATUSES[randomIndex];

            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doUpdate(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Attended__c, 'Individual session enrollment\'s total attended amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup total attended after delete study event relation
     */
    @isTest
    static void testTotalAttendedAfterDeleteAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        //update to attended status
        Integer randomIndex = Math.round(Math.random());
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ATTENDED_STATUSES[randomIndex];
        }
        REDU_SystemMode_UTIL.doUpdate(serList);
        
        //get isn Id
        Set<Id> isnIds = new Set<Id>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            isnIds.add(ser.reduivy__Individual_Session_Enrollment__c);
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doDelete(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnIds
        ]){
            System.Assert.areEqual(0, isn.reduivy__Total_Attended__c, 'Individual session enrollment\'s total attended amount should be 0.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup total attended after undelete study event relation
     */
    @isTest
    static void testTotalAttendedAfterUndeleteAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
            AND reduivy__Contact__c = :studentUser.contactId
        ];
        
        //update to attended status
        Integer randomIndex = Math.round(Math.random());
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ATTENDED_STATUSES[randomIndex];
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //get isn Id
        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            
            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doDelete(serList);

            undelete serList;
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Attended__c, 'Individual session enrollment\'s total attended amount should be 0.');
        }

        Test.stopTest();
    }


    //-------------- test for Total Absent --------------
    /**
     * @description Test as admin for rollup total absent after insert study event relation
     */
    @isTest
    static void testTotalAbsentAfterInsertAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        String ISN_STUDENT_RTID = ISN_Helper.getStudentRecordTypeId();
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get individual session enrollment
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE RecordTypeId = :ISN_STUDENT_RTID
        ]);

        //get current Total Absent
        Map<Id, Integer> isnCountAttendance = new Map<Id, Integer>();
        for(SObject sobj : [
            SELECT COUNT(Id) countResult, reduivy__Individual_Session_Enrollment__c
            FROM reduivy__Study_Event_Relation__c 
            WHERE reduivy__Individual_Session_Enrollment__c IN :isnMap.keySet()
            AND reduivy__Attendance_Status__c = :TOTAL_ABSENT_STATUS
            AND reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
            GROUP BY reduivy__Individual_Session_Enrollment__c
        ]){
            isnCountAttendance.put((Id)sobj.get('reduivy__Individual_Session_Enrollment__c'), (Integer)sobj.get('countResult'));
        }

        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //get study event
        List<reduivy__Study_Event__c> studyEvent = [SELECT Id
            FROM reduivy__Study_Event__c 
            LIMIT 1
        ];
        
        //create study event relation
        Integer randomIndex = Math.round(Math.random());
        List<reduivy__Study_Event_Relation__c> serToInsert = new List<reduivy__Study_Event_Relation__c>();

        for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
            serToInsert.add(REDU_TestData_UTIL.newStudentStudyEventRelation('To test attendance rollup', studentContact[0].Id, studyEvent[0].Id, isn.Id, null, null, TOTAL_ABSENT_STATUS));
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doInsert(serToInsert);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnCountAttendance.keySet()
        ]){
            System.Assert.areEqual(isnCountAttendance.get(isn.Id) + 1, isn.reduivy__Total_Absent__c, 'Individual session enrollment\'s total absent amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup total absent after update study event relation
     */
    @isTest
    static void testTotalAbsentAfterUpdateAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();

        //update to other status first 
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ATTENDED_STATUSES[0];
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //update as absent status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ABSENT_STATUS;

            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doUpdate(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Absent__c, 'Individual session enrollment\'s total absent amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup total absent after delete study event relation
     */
    @isTest
    static void testTotalAbsentAfterDeleteAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        //update to absent status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ABSENT_STATUS;
        }
        REDU_SystemMode_UTIL.doUpdate(serList);
        
        //get isn Id
        Set<Id> isnIds = new Set<Id>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            isnIds.add(ser.reduivy__Individual_Session_Enrollment__c);
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doDelete(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnIds
        ]){
            System.Assert.areEqual(0, isn.reduivy__Total_Absent__c, 'Individual session enrollment\'s total absent amount should be 0.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup total absent after undelete study event relation
     */
    @isTest
    static void testTotalAbsentAfterUndeleteAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];
        
        //update to absent status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ABSENT_STATUS;
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //get isn Id
        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            
            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doDelete(serList);

            undelete serList;
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Absent__c, 'Individual session enrollment\'s total absent amount should be 0.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup total absent after insert study event relation
     */
    @isTest
    static void testTotalAbsentAfterInsertAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        String ISN_STUDENT_RTID = ISN_Helper.getStudentRecordTypeId();
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get individual session enrollment
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE RecordTypeId = :ISN_STUDENT_RTID
        ]);

        //get current Total Absent
        Map<Id, Integer> isnCountAttendance = new Map<Id, Integer>();
        for(SObject sobj : [
            SELECT COUNT(Id) countResult, reduivy__Individual_Session_Enrollment__c
            FROM reduivy__Study_Event_Relation__c 
            WHERE reduivy__Individual_Session_Enrollment__c IN :isnMap.keySet()
            AND reduivy__Attendance_Status__c = :TOTAL_ABSENT_STATUS
            AND reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
            GROUP BY reduivy__Individual_Session_Enrollment__c
        ]){
            isnCountAttendance.put((Id)sobj.get('reduivy__Individual_Session_Enrollment__c'), (Integer)sobj.get('countResult'));
        }

        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //get study event
        List<reduivy__Study_Event__c> studyEvent = [SELECT Id
            FROM reduivy__Study_Event__c 
            LIMIT 1
        ];
        
        //create study event relation
        Integer randomIndex = Math.round(Math.random());
        List<reduivy__Study_Event_Relation__c> serToInsert = new List<reduivy__Study_Event_Relation__c>();

        for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
            serToInsert.add(REDU_TestData_UTIL.newStudentStudyEventRelation('To test attendance rollup', studentContact[0].Id, studyEvent[0].Id, isn.Id, null, null, TOTAL_ABSENT_STATUS));
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doInsert(serToInsert);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnCountAttendance.keySet()
        ]){
            System.Assert.areEqual(isnCountAttendance.get(isn.Id) + 1, isn.reduivy__Total_Absent__c, 'Individual session enrollment\'s total absent amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup total absent after update study event relation
     */
    @isTest
    static void testTotalAbsentAfterUpdateAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();

        //update to other status first 
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ATTENDED_STATUSES[0];
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //update as absent status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ABSENT_STATUS;

            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doUpdate(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Absent__c, 'Individual session enrollment\'s total absent amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup total absent after delete study event relation
     */
    @isTest
    static void testTotalAbsentAfterDeleteAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        //update to absent status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ABSENT_STATUS;
        }
        REDU_SystemMode_UTIL.doUpdate(serList);
        
        //get isn Id
        Set<Id> isnIds = new Set<Id>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            isnIds.add(ser.reduivy__Individual_Session_Enrollment__c);
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doDelete(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnIds
        ]){
            System.Assert.areEqual(0, isn.reduivy__Total_Absent__c, 'Individual session enrollment\'s total absent amount should be 0.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup total absent after undelete study event relation
     */
    @isTest
    static void testTotalAbsentAfterUndeleteAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];
        
        //update to absent status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ABSENT_STATUS;
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //get isn Id
        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            
            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doDelete(serList);

            undelete serList;
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Absent__c, 'Individual session enrollment\'s total absent amount should be 0.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup total absent after insert study event relation
     */
    @isTest
    static void testTotalAbsentAfterInsertAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        String ISN_STUDENT_RTID = ISN_Helper.getStudentRecordTypeId();
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get individual session enrollment
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE RecordTypeId = :ISN_STUDENT_RTID
        ]);

        //get current Total Absent
        Map<Id, Integer> isnCountAttendance = new Map<Id, Integer>();
        for(SObject sobj : [
            SELECT COUNT(Id) countResult, reduivy__Individual_Session_Enrollment__c
            FROM reduivy__Study_Event_Relation__c 
            WHERE reduivy__Individual_Session_Enrollment__c IN :isnMap.keySet()
            AND reduivy__Attendance_Status__c = :TOTAL_ABSENT_STATUS
            AND reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
            GROUP BY reduivy__Individual_Session_Enrollment__c
        ]){
            isnCountAttendance.put((Id)sobj.get('reduivy__Individual_Session_Enrollment__c'), (Integer)sobj.get('countResult'));
        }

        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //get study event
        List<reduivy__Study_Event__c> studyEvent = [SELECT Id
            FROM reduivy__Study_Event__c 
            LIMIT 1
        ];
        
        //create study event relation
        Integer randomIndex = Math.round(Math.random());
        List<reduivy__Study_Event_Relation__c> serToInsert = new List<reduivy__Study_Event_Relation__c>();

        for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
            serToInsert.add(REDU_TestData_UTIL.newStudentStudyEventRelation('To test attendance rollup', studentContact[0].Id, studyEvent[0].Id, isn.Id, null, null, TOTAL_ABSENT_STATUS));
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doInsert(serToInsert);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnCountAttendance.keySet()
        ]){
            System.Assert.areEqual(isnCountAttendance.get(isn.Id) + 1, isn.reduivy__Total_Absent__c, 'Individual session enrollment\'s total absent amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup total absent after update study event relation
     */
    @isTest
    static void testTotalAbsentAfterUpdateAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();

        //update to other status first 
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ATTENDED_STATUSES[0];
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //update as absent status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ABSENT_STATUS;

            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doUpdate(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Absent__c, 'Individual session enrollment\'s total absent amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup total absent after delete study event relation
     */
    @isTest
    static void testTotalAbsentAfterDeleteAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        //update to absent status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ABSENT_STATUS;
        }
        REDU_SystemMode_UTIL.doUpdate(serList);
        
        //get isn Id
        Set<Id> isnIds = new Set<Id>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            isnIds.add(ser.reduivy__Individual_Session_Enrollment__c);
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doDelete(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnIds
        ]){
            System.Assert.areEqual(0, isn.reduivy__Total_Absent__c, 'Individual session enrollment\'s total absent amount should be 0.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup total absent after undelete study event relation
     */
    @isTest
    static void testTotalAbsentAfterUndeleteAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
            AND reduivy__Contact__c = :studentUser.contactId
        ];
        
        //update to absent status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ABSENT_STATUS;
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //get isn Id
        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            
            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doDelete(serList);

            undelete serList;
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Absent__c, 'Individual session enrollment\'s total absent amount should be 0.');
        }

        Test.stopTest();
    }


    //-------------- test for Total Excused --------------
    /**
     * @description Test as admin for rollup total excused after insert study event relation
     */
    @isTest
    static void testTotalExcusedAfterInsertAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        String TOTAL_EXCUSED_STATUS = SER_Helper.ATTENDANCE_STATUS_EXCUSED;
        String ISN_STUDENT_RTID = ISN_Helper.getStudentRecordTypeId();
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get individual session enrollment
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE RecordTypeId = :ISN_STUDENT_RTID
        ]);

        //get current Total Excused
        Map<Id, Integer> isnCountAttendance = new Map<Id, Integer>();
        for(SObject sobj : [
            SELECT COUNT(Id) countResult, reduivy__Individual_Session_Enrollment__c
            FROM reduivy__Study_Event_Relation__c 
            WHERE reduivy__Individual_Session_Enrollment__c IN :isnMap.keySet()
            AND reduivy__Attendance_Status__c = :TOTAL_EXCUSED_STATUS
            AND reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
            GROUP BY reduivy__Individual_Session_Enrollment__c
        ]){
            isnCountAttendance.put((Id)sobj.get('reduivy__Individual_Session_Enrollment__c'), (Integer)sobj.get('countResult'));
        }

        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //get study event
        List<reduivy__Study_Event__c> studyEvent = [SELECT Id
            FROM reduivy__Study_Event__c 
            LIMIT 1
        ];
        
        //create study event relation
        Integer randomIndex = Math.round(Math.random());
        List<reduivy__Study_Event_Relation__c> serToInsert = new List<reduivy__Study_Event_Relation__c>();

        for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
            serToInsert.add(REDU_TestData_UTIL.newStudentStudyEventRelation('To test attendance rollup', studentContact[0].Id, studyEvent[0].Id, isn.Id, null, null, TOTAL_EXCUSED_STATUS));
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doInsert(serToInsert);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnCountAttendance.keySet()
        ]){
            System.Assert.areEqual(isnCountAttendance.get(isn.Id) + 1, isn.reduivy__Total_Excused__c, 'Individual session enrollment\'s total excused amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup total excused after update study event relation
     */
    @isTest
    static void testTotalExcusedAfterUpdateAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        String TOTAL_EXCUSED_STATUS = SER_Helper.ATTENDANCE_STATUS_EXCUSED;
        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();

        //update to other status first 
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ATTENDED_STATUSES[0];
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //update as excused status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_EXCUSED_STATUS;

            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doUpdate(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Excused__c, 'Individual session enrollment\'s total excused amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup total excused after delete study event relation
     */
    @isTest
    static void testTotalExcusedAfterDeleteAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        String TOTAL_EXCUSED_STATUS = SER_Helper.ATTENDANCE_STATUS_EXCUSED;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        //update to excused status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_EXCUSED_STATUS;
        }
        REDU_SystemMode_UTIL.doUpdate(serList);
        
        //get isn Id
        Set<Id> isnIds = new Set<Id>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            isnIds.add(ser.reduivy__Individual_Session_Enrollment__c);
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doDelete(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnIds
        ]){
            System.Assert.areEqual(0, isn.reduivy__Total_Excused__c, 'Individual session enrollment\'s total excused amount should be 0.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup total excused after undelete study event relation
     */
    @isTest
    static void testTotalExcusedAfterUndeleteAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        String TOTAL_EXCUSED_STATUS = SER_Helper.ATTENDANCE_STATUS_EXCUSED;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];
        
        //update to excused status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_EXCUSED_STATUS;
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //get isn Id
        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            
            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doDelete(serList);

            undelete serList;
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Excused__c, 'Individual session enrollment\'s total excused amount should be 0.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup total excused after insert study event relation
     */
    @isTest
    static void testTotalExcusedAfterInsertAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        String TOTAL_EXCUSED_STATUS = SER_Helper.ATTENDANCE_STATUS_EXCUSED;
        String ISN_STUDENT_RTID = ISN_Helper.getStudentRecordTypeId();
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get individual session enrollment
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE RecordTypeId = :ISN_STUDENT_RTID
        ]);

        //get current Total Excused
        Map<Id, Integer> isnCountAttendance = new Map<Id, Integer>();
        for(SObject sobj : [
            SELECT COUNT(Id) countResult, reduivy__Individual_Session_Enrollment__c
            FROM reduivy__Study_Event_Relation__c 
            WHERE reduivy__Individual_Session_Enrollment__c IN :isnMap.keySet()
            AND reduivy__Attendance_Status__c = :TOTAL_EXCUSED_STATUS
            AND reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
            GROUP BY reduivy__Individual_Session_Enrollment__c
        ]){
            isnCountAttendance.put((Id)sobj.get('reduivy__Individual_Session_Enrollment__c'), (Integer)sobj.get('countResult'));
        }

        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //get study event
        List<reduivy__Study_Event__c> studyEvent = [SELECT Id
            FROM reduivy__Study_Event__c 
            LIMIT 1
        ];
        
        //create study event relation
        Integer randomIndex = Math.round(Math.random());
        List<reduivy__Study_Event_Relation__c> serToInsert = new List<reduivy__Study_Event_Relation__c>();

        for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
            serToInsert.add(REDU_TestData_UTIL.newStudentStudyEventRelation('To test attendance rollup', studentContact[0].Id, studyEvent[0].Id, isn.Id, null, null, TOTAL_EXCUSED_STATUS));
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doInsert(serToInsert);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnCountAttendance.keySet()
        ]){
            System.Assert.areEqual(isnCountAttendance.get(isn.Id) + 1, isn.reduivy__Total_Excused__c, 'Individual session enrollment\'s total excused amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup total excused after update study event relation
     */
    @isTest
    static void testTotalExcusedAfterUpdateAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        String TOTAL_EXCUSED_STATUS = SER_Helper.ATTENDANCE_STATUS_EXCUSED;
        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();

        //update to other status first 
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ATTENDED_STATUSES[0];
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //update as excused status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_EXCUSED_STATUS;

            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doUpdate(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Excused__c, 'Individual session enrollment\'s total excused amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup total excused after delete study event relation
     */
    @isTest
    static void testTotalExcusedAfterDeleteAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        String TOTAL_EXCUSED_STATUS = SER_Helper.ATTENDANCE_STATUS_EXCUSED;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        //update to excused status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_EXCUSED_STATUS;
        }
        REDU_SystemMode_UTIL.doUpdate(serList);
        
        //get isn Id
        Set<Id> isnIds = new Set<Id>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            isnIds.add(ser.reduivy__Individual_Session_Enrollment__c);
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doDelete(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnIds
        ]){
            System.Assert.areEqual(0, isn.reduivy__Total_Excused__c, 'Individual session enrollment\'s total excused amount should be 0.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup total excused after undelete study event relation
     */
    @isTest
    static void testTotalExcusedAfterUndeleteAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        String TOTAL_EXCUSED_STATUS = SER_Helper.ATTENDANCE_STATUS_EXCUSED;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];
        
        //update to excused status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_EXCUSED_STATUS;
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //get isn Id
        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            
            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doDelete(serList);

            undelete serList;
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Excused__c, 'Individual session enrollment\'s total excused amount should be 0.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup total excused after insert study event relation
     */
    @isTest
    static void testTotalExcusedAfterInsertAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        String TOTAL_EXCUSED_STATUS = SER_Helper.ATTENDANCE_STATUS_EXCUSED;
        String ISN_STUDENT_RTID = ISN_Helper.getStudentRecordTypeId();
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get individual session enrollment
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE RecordTypeId = :ISN_STUDENT_RTID
        ]);

        //get current Total Excused
        Map<Id, Integer> isnCountAttendance = new Map<Id, Integer>();
        for(SObject sobj : [
            SELECT COUNT(Id) countResult, reduivy__Individual_Session_Enrollment__c
            FROM reduivy__Study_Event_Relation__c 
            WHERE reduivy__Individual_Session_Enrollment__c IN :isnMap.keySet()
            AND reduivy__Attendance_Status__c = :TOTAL_EXCUSED_STATUS
            AND reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
            GROUP BY reduivy__Individual_Session_Enrollment__c
        ]){
            isnCountAttendance.put((Id)sobj.get('reduivy__Individual_Session_Enrollment__c'), (Integer)sobj.get('countResult'));
        }

        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //get study event
        List<reduivy__Study_Event__c> studyEvent = [SELECT Id
            FROM reduivy__Study_Event__c 
            LIMIT 1
        ];
        
        //create study event relation
        Integer randomIndex = Math.round(Math.random());
        List<reduivy__Study_Event_Relation__c> serToInsert = new List<reduivy__Study_Event_Relation__c>();

        for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
            serToInsert.add(REDU_TestData_UTIL.newStudentStudyEventRelation('To test attendance rollup', studentContact[0].Id, studyEvent[0].Id, isn.Id, null, null, TOTAL_EXCUSED_STATUS));
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doInsert(serToInsert);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnCountAttendance.keySet()
        ]){
            System.Assert.areEqual(isnCountAttendance.get(isn.Id) + 1, isn.reduivy__Total_Excused__c, 'Individual session enrollment\'s total excused amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup total excused after update study event relation
     */
    @isTest
    static void testTotalExcusedAfterUpdateAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        String TOTAL_EXCUSED_STATUS = SER_Helper.ATTENDANCE_STATUS_EXCUSED;
        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();

        //update to other status first 
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_ATTENDED_STATUSES[0];
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //update as excused status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_EXCUSED_STATUS;

            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doUpdate(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Excused__c, 'Individual session enrollment\'s total excused amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup total excused after delete study event relation
     */
    @isTest
    static void testTotalExcusedAfterDeleteAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        String TOTAL_EXCUSED_STATUS = SER_Helper.ATTENDANCE_STATUS_EXCUSED;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];

        //update to excused status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_EXCUSED_STATUS;
        }
        REDU_SystemMode_UTIL.doUpdate(serList);
        
        //get isn Id
        Set<Id> isnIds = new Set<Id>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            isnIds.add(ser.reduivy__Individual_Session_Enrollment__c);
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doDelete(serList);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnIds
        ]){
            System.Assert.areEqual(0, isn.reduivy__Total_Excused__c, 'Individual session enrollment\'s total excused amount should be 0.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup total excused after undelete study event relation
     */
    @isTest
    static void testTotalExcusedAfterUndeleteAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        String TOTAL_EXCUSED_STATUS = SER_Helper.ATTENDANCE_STATUS_EXCUSED;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
            AND reduivy__Contact__c = :studentUser.contactId
        ];
        
        //update to excused status
        for(reduivy__Study_Event_Relation__c ser : serList){
            ser.reduivy__Attendance_Status__c = TOTAL_EXCUSED_STATUS;
        }
        REDU_SystemMode_UTIL.doUpdate(serList);

        //get isn Id
        Map<Id, Integer> isnTrackCount = new Map<Id, Integer>();
        for(reduivy__Study_Event_Relation__c ser : serList){
            
            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            Integer count = isnTrackCount.containsKey(isnId) ? isnTrackCount.get(isnId) + 1 : 1;
            isnTrackCount.put(isnId, count);
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doDelete(serList);

            undelete serList;
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnTrackCount.keySet()
        ]){
            System.Assert.areEqual(isnTrackCount.get(isn.Id), isn.reduivy__Total_Excused__c, 'Individual session enrollment\'s total excused amount should be 0.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup after update individual session enrollment lookup in study event relation
     */
    @isTest
    static void testUpdateAssociatedSerAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        String TOTAL_EXCUSED_STATUS = SER_Helper.ATTENDANCE_STATUS_EXCUSED;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];
        Map<Id, reduivy__Study_Event_Relation__c> serMap = new Map<Id, reduivy__Study_Event_Relation__c>(serList);

        Map<Id, Integer> attendedCount = new Map<Id, Integer>();
        Map<Id, Integer> absentCount = new Map<Id, Integer>();
        Map<Id, Integer> excusedCount = new Map<Id, Integer>();
        List<reduivy__Study_Event_Relation__c> serToUpdate = new List<reduivy__Study_Event_Relation__c>();

        //get the first ser's isnId
        Id firstIsnId = serList[0].reduivy__Individual_Session_Enrollment__c;

        //update lookup isn Id 
        //(all ser associated with firstIsnId will to update to secondIsnId. the sequence based on the serList)
        for(reduivy__Study_Event_Relation__c ser : serList){
            
            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            //update for all the SER that associated to the first ISN's only
            //if we update all SER from all ISN, all of ISN will do the rollup. We cannot check whether the oldIsn's SER is rollup or not in that case.
            if(isnId == firstIsnId){

                //replace current isnId to secondIsnId
                isnId = serList[1].reduivy__Individual_Session_Enrollment__c; 

                ser.reduivy__Individual_Session_Enrollment__c = isnId;
                serToUpdate.add(ser);
            }

            if(TOTAL_ATTENDED_STATUSES.contains(ser.reduivy__Attendance_Status__c)){
                Integer count = attendedCount.containsKey(isnId) ? attendedCount.get(isnId) + 1 : 1;
                attendedCount.put(isnId, count);

            } else if(TOTAL_ABSENT_STATUS == ser.reduivy__Attendance_Status__c){
                Integer count = absentCount.containsKey(isnId) ? absentCount.get(isnId) + 1 : 1;
                absentCount.put(isnId, count);

            }else if(TOTAL_EXCUSED_STATUS == ser.reduivy__Attendance_Status__c){
                Integer count = excusedCount.containsKey(isnId) ? excusedCount.get(isnId) + 1 : 1;
                excusedCount.put(isnId, count);
            }
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doUpdate(serToUpdate);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :serMap.keySet()
        ]){
            System.Assert.areEqual(attendedCount.get(isn.Id), isn.reduivy__Total_Attended__c, 'Individual session enrollment\'s total attended amount does not match.');
            System.Assert.areEqual(absentCount.get(isn.Id), isn.reduivy__Total_Absent__c, 'Individual session enrollment\'s total absent amount does not match.');
            System.Assert.areEqual(excusedCount.get(isn.Id), isn.reduivy__Total_Excused__c, 'Individual session enrollment\'s total excused amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup after set individual session enrollment lookup to null in study event relation
     */
    @isTest
    static void testUnlinkAssociatedSerAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        String TOTAL_EXCUSED_STATUS = SER_Helper.ATTENDANCE_STATUS_EXCUSED;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];
        Map<Id, reduivy__Study_Event_Relation__c> serMap = new Map<Id, reduivy__Study_Event_Relation__c>(serList);

        Map<Id, Integer> attendedCount = new Map<Id, Integer>();
        Map<Id, Integer> absentCount = new Map<Id, Integer>();
        Map<Id, Integer> excusedCount = new Map<Id, Integer>();
        List<reduivy__Study_Event_Relation__c> serToUpdate = new List<reduivy__Study_Event_Relation__c>();

        //get the first ser's isnId
        Id firstIsnId = serList[0].reduivy__Individual_Session_Enrollment__c;

        //update lookup isn Id 
        //(all ser associated with firstIsnId will to update to secondIsnId. the sequence based on the serList)
        for(reduivy__Study_Event_Relation__c ser : serList){
            
            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            //update for all the SER that associated to the first ISN's only
            //if we update all SER from all ISN, all of ISN will do the rollup. We cannot check whether the oldIsn's SER is rollup or not in that case.
            if(isnId == firstIsnId){

                //replace current isnId to secondIsnId
                isnId = serList[1].reduivy__Individual_Session_Enrollment__c; 

                ser.reduivy__Individual_Session_Enrollment__c = null;
                serToUpdate.add(ser);
            } else {

                if(TOTAL_ATTENDED_STATUSES.contains(ser.reduivy__Attendance_Status__c)){
                    Integer count = attendedCount.containsKey(isnId) ? attendedCount.get(isnId) + 1 : 1;
                    attendedCount.put(isnId, count);
    
                } else if(TOTAL_ABSENT_STATUS == ser.reduivy__Attendance_Status__c){
                    Integer count = absentCount.containsKey(isnId) ? absentCount.get(isnId) + 1 : 1;
                    absentCount.put(isnId, count);
    
                }else if(TOTAL_EXCUSED_STATUS == ser.reduivy__Attendance_Status__c){
                    Integer count = excusedCount.containsKey(isnId) ? excusedCount.get(isnId) + 1 : 1;
                    excusedCount.put(isnId, count);
                }
            }

        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doUpdate(serToUpdate);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :serMap.keySet()
        ]){
            System.Assert.areEqual(attendedCount.get(isn.Id), isn.reduivy__Total_Attended__c, 'Individual session enrollment\'s total attended amount does not match.');
            System.Assert.areEqual(absentCount.get(isn.Id), isn.reduivy__Total_Absent__c, 'Individual session enrollment\'s total absent amount does not match.');
            System.Assert.areEqual(excusedCount.get(isn.Id), isn.reduivy__Total_Excused__c, 'Individual session enrollment\'s total excused amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup after change study event relation's relation type by update individual session enrollment's record type
     */
    @isTest
    static void testUpdateSerRelationTypeAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        List<String> TOTAL_ATTENDED_STATUSES = new List<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
        String TOTAL_ABSENT_STATUS = SER_Helper.ATTENDANCE_STATUS_ABSENT;
        String TOTAL_EXCUSED_STATUS = SER_Helper.ATTENDANCE_STATUS_EXCUSED;
        String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

        //get study event relations
        List<reduivy__Study_Event_Relation__c> serList = [
            SELECT Id, reduivy__Attendance_Status__c, reduivy__Individual_Session_Enrollment__c 
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT
        ];
        Map<Id, reduivy__Study_Event_Relation__c> serMap = new Map<Id, reduivy__Study_Event_Relation__c>(serList);

        Map<Id, Integer> attendedCount = new Map<Id, Integer>();
        Map<Id, Integer> absentCount = new Map<Id, Integer>();
        Map<Id, Integer> excusedCount = new Map<Id, Integer>();
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = new List<reduivy__Individual_Session_Enrollment__c>();

        //get the first ser's isnId
        Id firstIsnId = serList[0].reduivy__Individual_Session_Enrollment__c;

        //update lookup isn Id 
        //(all ser associated with firstIsnId will to update to secondIsnId. the sequence based on the serList)
        for(reduivy__Study_Event_Relation__c ser : serList){
            
            Id isnId = ser.reduivy__Individual_Session_Enrollment__c;

            //update for all the SER that associated to the first ISN's only
            //if we update all SER from all ISN, all of ISN will do the rollup. We cannot check whether the oldIsn's SER is rollup or not in that case.
            if(isnId == firstIsnId && isnToUpdate.isEmpty()){

                reduivy__Individual_Session_Enrollment__c isnUpdate = new reduivy__Individual_Session_Enrollment__c();
                isnUpdate.Id = isnId;
                isnUpdate.RecordTypeId = ISN_Helper.getFacultyRecordTypeId(); //update to faculty record type
                isnToUpdate.add(isnUpdate);
            } else {

                if(TOTAL_ATTENDED_STATUSES.contains(ser.reduivy__Attendance_Status__c)){
                    Integer count = attendedCount.containsKey(isnId) ? attendedCount.get(isnId) + 1 : 1;
                    attendedCount.put(isnId, count);
    
                } else if(TOTAL_ABSENT_STATUS == ser.reduivy__Attendance_Status__c){
                    Integer count = absentCount.containsKey(isnId) ? absentCount.get(isnId) + 1 : 1;
                    absentCount.put(isnId, count);
    
                }else if(TOTAL_EXCUSED_STATUS == ser.reduivy__Attendance_Status__c){
                    Integer count = excusedCount.containsKey(isnId) ? excusedCount.get(isnId) + 1 : 1;
                    excusedCount.put(isnId, count);
                }
            }

        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doUpdate(isnToUpdate);
        }

        //check individual session enrollment rollup
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :serMap.keySet()
        ]){
            System.Assert.areEqual(attendedCount.get(isn.Id), isn.reduivy__Total_Attended__c, 'Individual session enrollment\'s total attended amount does not match.');
            System.Assert.areEqual(absentCount.get(isn.Id), isn.reduivy__Total_Absent__c, 'Individual session enrollment\'s total absent amount does not match.');
            System.Assert.areEqual(excusedCount.get(isn.Id), isn.reduivy__Total_Excused__c, 'Individual session enrollment\'s total excused amount does not match.');
        }

        Test.stopTest();
    }
}