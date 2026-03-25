/**
 * @author      WDCi (VTan)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for ISN_IenAttendanceRequirementMet_TEST
 * @changehistory
 * ISS-002055 29-08-2024 VTan - new class
 */
@IsTest
public inherited sharing class ISN_IenAttendanceRequirementMet_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Initialise test data for each test
     */
	@TestSetup
    static void makeData() {

		// Create settings
		testFactory.setupDefaultSettings();

		// Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();
			testFactory.initMasterData(SPS_Helper.getApiName());
            testFactory.initOfferingData(null);
            testFactory.initStudentData(SER_Helper.getApiName(), true);
            Test.stopTest();
        }
    }

    /*
     * @description Test as admin that each of the individual session enrollment record date fields are populated (before update)
     */
    @IsTest
    static void testAttendanceRequirementMetAfterUpdateAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Individual_Session_Enrollment__c> updateIsnList = new List<reduivy__Individual_Session_Enrollment__c>();
        Set<Id> ienIdSet = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Attendance_Requirement_Met__c, 
                                            (SELECT Id, reduivy__Attendance_Percentage__c, reduivy__Enrollment_Status__c, reduivy__Study_Session__r.reduivy__Required_Attendance_Percentage__c
                                            FROM reduivy__Individual_Session_Enrollments__r
                                            WHERE recordTypeId = :ISN_Helper.getStudentRecordTypeId())
                                            FROM reduivy__Individual_Enrollment__c
                                            WHERE recordTypeId = : IEN_Helper.getStudentRecordTypeId()]){

            for(reduivy__Individual_Session_Enrollment__c isn : ien.reduivy__Individual_Session_Enrollments__r){

                System.Assert.areEqual(0.00, isn.reduivy__Attendance_Percentage__c, 'Attendance Percentage should be 0.00');
                System.Assert.areEqual(90.00, isn.reduivy__Study_Session__r.reduivy__Required_Attendance_Percentage__c, 'Required attendance Percentage should be 90.00');

                updateIsnList.add(new reduivy__Individual_Session_Enrollment__c(
                                        Id = isn.Id, 
                                        reduivy__Total_Attended__c = 1, 
                                        reduivy__Total_Absent__c = 1, 
                                        reduivy__Total_Excused__c = 0));
                
                ienIdSet.add(ien.Id);
            }
        }

        update updateIsnList;

        Test.startTest();
        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Attendance_Requirement_Met__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :ienIdSet]){
            System.Assert.areEqual(IEN_Helper.ATTENDANCE_REQUIREMENT_MET_NO, ien.reduivy__Attendance_Requirement_Met__c, 'Attendance Requirement Met should be No');
        }

        for(reduivy__Individual_Session_Enrollment__c isn : updateIsnList){
            isn.reduivy__Total_Attended__c = 9;
            isn.reduivy__Total_Absent__c = 1;
            isn.reduivy__Total_Excused__c = 0;
        }

        System.runAs(ADMIN_USER){
            update updateIsnList;
        }
        Test.stopTest();

        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Attendance_Requirement_Met__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :ienIdSet]){
            System.Assert.areEqual(IEN_Helper.ATTENDANCE_REQUIREMENT_MET_YES, ien.reduivy__Attendance_Requirement_Met__c, 'Attendance Requirement Met should be Yes');
        }
    }
    
    /*
     * @description Test as admin that each of the individual session enrollment record date fields are populated (before update)
     */
    @IsTest
    static void testAttendanceRequirementMetAfterInsertAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Individual_Session_Enrollment__c> insertIsnList = new List<reduivy__Individual_Session_Enrollment__c>();
        List<reduivy__Individual_Session_Enrollment__c> deleteIsnList = new List<reduivy__Individual_Session_Enrollment__c>();
        Set<Id> ienIdSet = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Attendance_Requirement_Met__c, 
                                            (SELECT Id, reduivy__Attendance_Percentage__c, reduivy__Study_Session__c, reduivy__Enrollment_Status__c, 
                                            reduivy__Individual_Enrollment__c, reduivy__Study_Session__r.reduivy__Required_Attendance_Percentage__c
                                            FROM reduivy__Individual_Session_Enrollments__r
                                            WHERE recordTypeId = :ISN_Helper.getStudentRecordTypeId())
                                            FROM reduivy__Individual_Enrollment__c
                                            WHERE recordTypeId = : IEN_Helper.getStudentRecordTypeId()]){

            for(reduivy__Individual_Session_Enrollment__c isn : ien.reduivy__Individual_Session_Enrollments__r){

                System.Assert.areEqual(0.00, isn.reduivy__Attendance_Percentage__c, 'Attendance Percentage should be 0.00');
                System.Assert.areEqual(90.00, isn.reduivy__Study_Session__r.reduivy__Required_Attendance_Percentage__c, 'Required attendance Percentage should be 90.00');

                insertIsnList.add(new reduivy__Individual_Session_Enrollment__c(
                                        reduivy__Total_Attended__c = 1, 
                                        reduivy__Total_Absent__c = 1, 
                                        reduivy__Total_Excused__c = 0,
                                        reduivy__Study_Session__c = isn.reduivy__Study_Session__c,
                                        reduivy__Individual_Enrollment__c = isn.reduivy__Individual_Enrollment__c,
                                        recordTypeId = ISN_Helper.getStudentRecordTypeId(),
                                        reduivy__Enrollment_Status__c = isn.reduivy__Enrollment_Status__c));

                deleteIsnList.add(new reduivy__Individual_Session_Enrollment__c(
                                        Id = isn.Id));

                ienIdSet.add(ien.Id);
            }
        }

        delete deleteIsnList;

        Test.startTest();

        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Attendance_Requirement_Met__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :ienIdSet]){
            System.Assert.areEqual(IEN_Helper.ATTENDANCE_REQUIREMENT_MET_YES, ien.reduivy__Attendance_Requirement_Met__c, 'Attendance Requirement Met should be Yes');
        }

        System.runAs(ADMIN_USER){
            insert insertIsnList;
        }
        Test.stopTest();

        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Attendance_Requirement_Met__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :ienIdSet]){
            System.Assert.areEqual(IEN_Helper.ATTENDANCE_REQUIREMENT_MET_NO, ien.reduivy__Attendance_Requirement_Met__c, 'Attendance Requirement Met should be No');
        }
    }

    /*
     * @description Test as admin that each of the individual session enrollment record date fields are populated (before update)
     */
    @IsTest
    static void testAttendanceRequirementMetAfterDeleteAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Individual_Session_Enrollment__c> updateIsnList = new List<reduivy__Individual_Session_Enrollment__c>();
        Set<Id> ienIdSet = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Attendance_Requirement_Met__c, 
                                            (SELECT Id, reduivy__Attendance_Percentage__c, reduivy__Study_Session__c, reduivy__Enrollment_Status__c, reduivy__Study_Session__r.reduivy__Required_Attendance_Percentage__c
                                            FROM reduivy__Individual_Session_Enrollments__r
                                            WHERE recordTypeId = :ISN_Helper.getStudentRecordTypeId())
                                            FROM reduivy__Individual_Enrollment__c
                                            WHERE recordTypeId = : IEN_Helper.getStudentRecordTypeId()]){

            for(reduivy__Individual_Session_Enrollment__c isn : ien.reduivy__Individual_Session_Enrollments__r){

                System.Assert.areEqual(0.00, isn.reduivy__Attendance_Percentage__c, 'Attendance Percentage should be 0.00');
                System.Assert.areEqual(90.00, isn.reduivy__Study_Session__r.reduivy__Required_Attendance_Percentage__c, 'Required attendance Percentage should be 90.00');

                updateIsnList.add(new reduivy__Individual_Session_Enrollment__c(
                                        Id = isn.Id, 
                                        reduivy__Total_Attended__c = 10, 
                                        reduivy__Total_Absent__c = 0, 
                                        reduivy__Total_Excused__c = 0,
                                        reduivy__Study_Session__c = isn.reduivy__Study_Session__c,
                                        recordTypeId = ISN_Helper.getStudentRecordTypeId(),
                                        reduivy__Enrollment_Status__c = isn.reduivy__Enrollment_Status__c));
                
                ienIdSet.add(ien.Id);
            }
        }

        Test.startTest();

        System.runAs(ADMIN_USER){
            delete updateIsnList;
        }
        Test.stopTest();

        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Attendance_Requirement_Met__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :ienIdSet]){
            System.Assert.areEqual(IEN_Helper.ATTENDANCE_REQUIREMENT_MET_YES, ien.reduivy__Attendance_Requirement_Met__c, 'Attendance Requirement Met should be No');
        }
    }

    /*
     * @description Test as admin that each of the individual session enrollment record date fields are populated (before update)
     */
    @IsTest
    static void testAttendanceRequirementMetAfterUndeleteAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Individual_Session_Enrollment__c> undeleteIsnList = new List<reduivy__Individual_Session_Enrollment__c>();
        Set<Id> ienIdSet = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Attendance_Requirement_Met__c, 
                                            (SELECT Id, reduivy__Attendance_Percentage__c, reduivy__Study_Session__c, reduivy__Enrollment_Status__c, 
                                            reduivy__Individual_Enrollment__c, reduivy__Study_Session__r.reduivy__Required_Attendance_Percentage__c
                                            FROM reduivy__Individual_Session_Enrollments__r
                                            WHERE recordTypeId = :ISN_Helper.getStudentRecordTypeId())
                                            FROM reduivy__Individual_Enrollment__c
                                            WHERE recordTypeId = : IEN_Helper.getStudentRecordTypeId()]){

            for(reduivy__Individual_Session_Enrollment__c isn : ien.reduivy__Individual_Session_Enrollments__r){

                System.Assert.areEqual(0.00, isn.reduivy__Attendance_Percentage__c, 'Attendance Percentage should be 0.00');
                System.Assert.areEqual(90.00, isn.reduivy__Study_Session__r.reduivy__Required_Attendance_Percentage__c, 'Required attendance Percentage should be 90.00');

                undeleteIsnList.add(new reduivy__Individual_Session_Enrollment__c(
                                        Id = isn.Id,
                                        reduivy__Total_Attended__c = 1, 
                                        reduivy__Total_Absent__c = 1, 
                                        reduivy__Total_Excused__c = 0));

                ienIdSet.add(ien.Id);
            }
        }

        update undeleteIsnList;
        delete undeleteIsnList;

        Test.startTest();

        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Attendance_Requirement_Met__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :ienIdSet]){
            System.Assert.areEqual(IEN_Helper.ATTENDANCE_REQUIREMENT_MET_YES, ien.reduivy__Attendance_Requirement_Met__c, 'Attendance Requirement Met should be Yes');
        }
        
        undelete undeleteIsnList;
        
        Test.stopTest();

        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Attendance_Requirement_Met__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :ienIdSet]){
            System.Assert.areEqual(IEN_Helper.ATTENDANCE_REQUIREMENT_MET_NO, ien.reduivy__Attendance_Requirement_Met__c, 'Attendance Requirement Met should be No');
        }
    }

    /*
     * @description Test as admin that each of the individual session enrollment record date fields are populated (before update)
     */
    @IsTest
    static void testAttendanceRequirementMetAfterUpdateAsFaculty() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<reduivy__Individual_Session_Enrollment__c> updateIsnList = new List<reduivy__Individual_Session_Enrollment__c>();
        List<reduivy__Individual_Session_Enrollment__c> deleteIsnList = new List<reduivy__Individual_Session_Enrollment__c>();
        Set<Id> ienIdSet = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Attendance_Requirement_Met__c, 
                                            (SELECT Id, reduivy__Attendance_Percentage__c, reduivy__Study_Session__c, reduivy__Enrollment_Status__c, 
                                            reduivy__Individual_Enrollment__c, reduivy__Study_Session__r.reduivy__Required_Attendance_Percentage__c
                                            FROM reduivy__Individual_Session_Enrollments__r
                                            WHERE recordTypeId = :ISN_Helper.getStudentRecordTypeId())
                                            FROM reduivy__Individual_Enrollment__c
                                            WHERE recordTypeId = : IEN_Helper.getStudentRecordTypeId()]){

            for(reduivy__Individual_Session_Enrollment__c isn : ien.reduivy__Individual_Session_Enrollments__r){

                System.Assert.areEqual(0.00, isn.reduivy__Attendance_Percentage__c, 'Attendance Percentage should be 0.00');
                System.Assert.areEqual(90.00, isn.reduivy__Study_Session__r.reduivy__Required_Attendance_Percentage__c, 'Required attendance Percentage should be 90.00');

                deleteIsnList.add(new reduivy__Individual_Session_Enrollment__c(
                                        Id = isn.Id));

                updateIsnList.add(new reduivy__Individual_Session_Enrollment__c(
                                        reduivy__Total_Attended__c = 1, 
                                        reduivy__Total_Absent__c = 1, 
                                        reduivy__Total_Excused__c = 0,
                                        reduivy__Study_Session__c = isn.reduivy__Study_Session__c,
                                        reduivy__Individual_Enrollment__c = isn.reduivy__Individual_Enrollment__c,
                                        recordTypeId = ISN_Helper.getStudentRecordTypeId(),
                                        reduivy__Enrollment_Status__c = isn.reduivy__Enrollment_Status__c));
                
                ienIdSet.add(ien.Id);
            }
        }

        delete deleteIsnList;

        Test.startTest();

        System.runAs(FACULTY_USER){

            insert updateIsnList;

            for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Attendance_Requirement_Met__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :ienIdSet]){
                System.Assert.areEqual(IEN_Helper.ATTENDANCE_REQUIREMENT_MET_NO, ien.reduivy__Attendance_Requirement_Met__c, 'Attendance Requirement Met should be No');
            }

            for(reduivy__Individual_Session_Enrollment__c isn : updateIsnList){
                isn.reduivy__Total_Attended__c = 9;
                isn.reduivy__Total_Absent__c = 1;
                isn.reduivy__Total_Excused__c = 0;
            }
        
            update updateIsnList;
        }
        Test.stopTest();

        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Attendance_Requirement_Met__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :ienIdSet]){
            System.Assert.areEqual(IEN_Helper.ATTENDANCE_REQUIREMENT_MET_YES, ien.reduivy__Attendance_Requirement_Met__c, 'Attendance Requirement Met should be Yes');
        }
    }

    /*
     * @description Test as admin that each of the individual session enrollment record date fields are populated (before update)
     */
    @IsTest
    static void testAttendanceRequirementMetAfterInsertAsFaculty() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<reduivy__Individual_Session_Enrollment__c> insertIsnList = new List<reduivy__Individual_Session_Enrollment__c>();
        List<reduivy__Individual_Session_Enrollment__c> deleteIsnList = new List<reduivy__Individual_Session_Enrollment__c>();
        Set<Id> ienIdSet = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Attendance_Requirement_Met__c, 
                                            (SELECT Id, reduivy__Attendance_Percentage__c, reduivy__Study_Session__c, reduivy__Enrollment_Status__c, 
                                            reduivy__Individual_Enrollment__c, reduivy__Study_Session__r.reduivy__Required_Attendance_Percentage__c
                                            FROM reduivy__Individual_Session_Enrollments__r
                                            WHERE recordTypeId = :ISN_Helper.getStudentRecordTypeId())
                                            FROM reduivy__Individual_Enrollment__c
                                            WHERE recordTypeId = : IEN_Helper.getStudentRecordTypeId()]){

            for(reduivy__Individual_Session_Enrollment__c isn : ien.reduivy__Individual_Session_Enrollments__r){

                System.Assert.areEqual(0.00, isn.reduivy__Attendance_Percentage__c, 'Attendance Percentage should be 0.00');
                System.Assert.areEqual(90.00, isn.reduivy__Study_Session__r.reduivy__Required_Attendance_Percentage__c, 'Required attendance Percentage should be 90.00');

                insertIsnList.add(new reduivy__Individual_Session_Enrollment__c(
                                        reduivy__Total_Attended__c = 1, 
                                        reduivy__Total_Absent__c = 1, 
                                        reduivy__Total_Excused__c = 0,
                                        reduivy__Study_Session__c = isn.reduivy__Study_Session__c,
                                        reduivy__Individual_Enrollment__c = isn.reduivy__Individual_Enrollment__c,
                                        recordTypeId = ISN_Helper.getStudentRecordTypeId(),
                                        reduivy__Enrollment_Status__c = isn.reduivy__Enrollment_Status__c));

                deleteIsnList.add(new reduivy__Individual_Session_Enrollment__c(
                                        Id = isn.Id));

                ienIdSet.add(ien.Id);
            }
        }

        delete deleteIsnList;

        Test.startTest();

        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Attendance_Requirement_Met__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :ienIdSet]){
            System.Assert.areEqual(IEN_Helper.ATTENDANCE_REQUIREMENT_MET_YES, ien.reduivy__Attendance_Requirement_Met__c, 'Attendance Requirement Met should be Yes');
        }

        System.runAs(FACULTY_USER){
            insert insertIsnList;
        }
        Test.stopTest();

        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Attendance_Requirement_Met__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :ienIdSet]){
            System.Assert.areEqual(IEN_Helper.ATTENDANCE_REQUIREMENT_MET_NO, ien.reduivy__Attendance_Requirement_Met__c, 'Attendance Requirement Met should be No');
        }
    }
}