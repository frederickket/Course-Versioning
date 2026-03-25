/**
 * @author      WDCi (Sueanne)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for IEN_SetIsnStatus_EXE
 * @changehistory
 * ISS-002051 20-08-2024 Sueanne - new class
 * ISS-002486 10-06-2025 XiRouh - updated all getCompletedStatuses to getCompletedPassStatuses
 */
@isTest
public inherited sharing class IEN_SetIsnStatus_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData() {
        
        // Create settings
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
        // Create test data
        System.runAs(ADMIN_USER) {

            Test.startTest();

            testFactory.initMasterData(ARU_Helper.getApiName());
			testFactory.initOfferingData(SSE_Helper.getApiName());
			testFactory.initStudentData(IEN_Helper.getApiName(), true);

            //get studentIndividualEnrollments
            Map<Id, reduivy__Individual_Enrollment__c> studentIndividualEnrollments = new Map<Id, reduivy__Individual_Enrollment__c>([
                SELECT Id, reduivy__Contact__c, reduivy__Enrollment_Status__c, RecordTypeId, reduivy__Study_Offering__c, reduivy__Sample_Record_Code__c
                FROM reduivy__Individual_Enrollment__c
                WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            ]);
            System.Assert.areEqual(false, studentIndividualEnrollments.isEmpty(), 'Student individual enrollment no found.'); 

            //get studyOfferings
            Map<Id, reduivy__Study_Offering__c> studyOfferings = new Map<Id, reduivy__Study_Offering__c>([
                SELECT Id, Name, reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
            ]);
            System.Assert.areEqual(false, studyOfferings.isEmpty(), 'Study offering record no found.'); 

            //get studySessions
            Map<Id, reduivy__Study_Session__c> studySessions = new Map<Id, reduivy__Study_Session__c>([
                SELECT Id, Name, reduivy__Study_Offering__c, reduivy__Type__c, reduivy__Start_Date__c
                FROM reduivy__Study_Session__c
            ]);
            System.Assert.areEqual(false, studySessions.isEmpty(), 'Study session record no found.'); 

            //find student idv enrollment status = enrolled, select first studyOfferingId for each student
            Map<reduivy__Individual_Enrollment__c, reduivy__Study_Offering__c> idvEnrollWithStudyOffer = new Map<reduivy__Individual_Enrollment__c, reduivy__Study_Offering__c>();
            Set<Id> studentIds = new Set<Id>();

            for(reduivy__Individual_Enrollment__c idvEnroll : studentIndividualEnrollments.values()){
                if(idvEnroll.reduivy__Enrollment_Status__c == IEN_Helper.getInProgressStatuses().get(0) && idvEnroll.RecordTypeId == IEN_Helper.getStudentRecordTypeId() && !studentIds.contains(idvEnroll.reduivy__Contact__c)){
                    
                    for(reduivy__Study_Offering__c so : studyOfferings.values()){
                        if(so.Id == idvEnroll.reduivy__Study_Offering__c){
                            idvEnrollWithStudyOffer.put(idvEnroll, so);
                            studentIds.add(idvEnroll.reduivy__Contact__c);
                        }
                    }

                }
            }
            
            //create individual session enrollment
            Map<String, reduivy__Individual_Session_Enrollment__c> studentIndividualSessionEnrollments = new Map<String, reduivy__Individual_Session_Enrollment__c>();
            for(reduivy__Individual_Enrollment__c idvEnroll : idvEnrollWithStudyOffer.keySet()){
                for(reduivy__Study_Session__c ss : studySessions.values()){
                    if(ss.reduivy__Study_Offering__c == idvEnrollWithStudyOffer.get(idvEnroll).Id && ss.reduivy__Type__c == 'Lecture'){
                        String isnSampleRecord = ss.Name + '_' + idvEnroll.reduivy__Sample_Record_Code__c;
                        studentIndividualSessionEnrollments.put(isnSampleRecord, REDU_TestData_UTIL.newStudentIndividualSessionEnrollment(isnSampleRecord, ss.Id, idvEnroll.Id, ss.reduivy__Start_Date__c, 'Enrolled'));
                    }
                }
            }
    
            REDU_SystemMode_UTIL.doInsert(studentIndividualSessionEnrollments.values());

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin to check student individual session enrollment's enrollment status after update associated individual enrollment status to 'Completed'
     */
    @isTest
    static void testUpdateIenCompletedAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        //get the individual enrollment
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
        ]);
        System.Assert.areEqual(false, ienMap.isEmpty(), 'Individual Enrollment map should not be empty.');
        
        System.runAs(ADMIN_USER) {

            //set enrollment status = 'Completed'
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_Helper.getCompletedPassStatuses()[0];
            }

            REDU_SystemMode_UTIL.doUpdate(ienMap.values());
        }

        //check the related individual session enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Session_Enrollment__c 
            WHERE reduivy__Individual_Enrollment__c IN :ienMap.keySet()
        ]){
            System.Assert.areEqual(ISN_Helper.getIenToIsnStatusMap().get(IEN_Helper.getCompletedPassStatuses()[0]), isn.reduivy__Enrollment_Status__c, 'The individual session enrollment should be updated as Completed status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin to check student individual session enrollment's enrollment status after update associated individual enrollment status to 'Dropped'
     */
    @isTest
    static void testUpdateIenDroppedAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        //get the individual enrollment
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
        ]);
        System.Assert.areEqual(false, ienMap.isEmpty(), 'Individual Enrollment map should not be empty.');
        
        System.runAs(ADMIN_USER) {

            //set enrollment status = 'Dropped'
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_Helper.getDroppedStatuses()[0];
            }

            REDU_SystemMode_UTIL.doUpdate(ienMap.values());
        }
        
        //check the related individual session enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Session_Enrollment__c 
            WHERE reduivy__Individual_Enrollment__c IN :ienMap.keySet()
        ]){
            System.Assert.areEqual(ISN_Helper.getIenToIsnStatusMap().get(IEN_Helper.getDroppedStatuses()[0]), isn.reduivy__Enrollment_Status__c, 'The individual session enrollment should be updated as Dropped status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin to check student individual session enrollment's enrollment status after update associated individual enrollment status to 'Withdrawn'
     */
    @isTest
    static void testUpdateIenWithdrawnAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        //get the individual enrollment
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
        ]);
        System.Assert.areEqual(false, ienMap.isEmpty(), 'Individual Enrollment map should not be empty.');
        
        System.runAs(ADMIN_USER) {

            //set enrollment status = 'Withdrawn'
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_Helper.getWithdrawnStatuses()[0];
            }
        
            REDU_SystemMode_UTIL.doUpdate(ienMap.values());
        }
        
        //check the related individual session enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Session_Enrollment__c 
            WHERE reduivy__Individual_Enrollment__c IN :ienMap.keySet()
        ]){
            System.Assert.areEqual(ISN_Helper.getIenToIsnStatusMap().get(IEN_Helper.getWithdrawnStatuses()[0]), isn.reduivy__Enrollment_Status__c, 'The individual session enrollment should be updated as Withdrawn status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin to check student individual session enrollment's enrollment status after update associated individual enrollment status to 'Withdrawn with Penalty'
     */
    @isTest
    static void testUpdateIenWithdrawnFailAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        //get the individual enrollment
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
        ]);
        System.Assert.areEqual(false, ienMap.isEmpty(), 'Individual Enrollment map should not be empty.');
        
        System.runAs(ADMIN_USER) {

            //set enrollment status = 'Withdrawn'
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_Helper.getWithdrawnFailStatuses()[0];
            }
        
            REDU_SystemMode_UTIL.doUpdate(ienMap.values());
        }
        
        //check the related individual session enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Session_Enrollment__c 
            WHERE reduivy__Individual_Enrollment__c IN :ienMap.keySet()
        ]){
            System.Assert.areEqual(ISN_Helper.getIenToIsnStatusMap().get(IEN_Helper.getWithdrawnFailStatuses()[0]), isn.reduivy__Enrollment_Status__c, 'The individual session enrollment should be updated as Withdrawn status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check student individual session enrollment's enrollment status after update associated individual enrollment status to 'Completed'
     */
    @isTest
    static void testUpdateIenCompletedAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        //get the individual enrollment
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
        ]);
        System.Assert.areEqual(false, ienMap.isEmpty(), 'Individual Enrollment map should not be empty.');
        
        System.runAs(FACULTY_USER) {

            //set enrollment status = 'Completed'
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_Helper.getCompletedPassStatuses()[0];
            }

            REDU_SystemMode_UTIL.doUpdate(ienMap.values());
        }

        //check the related individual session enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Session_Enrollment__c 
            WHERE reduivy__Individual_Enrollment__c IN :ienMap.keySet()
        ]){
            System.Assert.areEqual(ISN_Helper.getIenToIsnStatusMap().get(IEN_Helper.getCompletedPassStatuses()[0]), isn.reduivy__Enrollment_Status__c, 'The individual session enrollment should be updated as Completed status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check student individual session enrollment's enrollment status after update associated individual enrollment status to 'Dropped'
     */
    @isTest
    static void testUpdateIenDroppedAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        //get the individual enrollment
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
        ]);
        System.Assert.areEqual(false, ienMap.isEmpty(), 'Individual Enrollment map should not be empty.');
        
        System.runAs(FACULTY_USER) {

            //set enrollment status = 'Dropped'
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_Helper.getDroppedStatuses()[0];
            }

            REDU_SystemMode_UTIL.doUpdate(ienMap.values());
        }
        
        //check the related individual session enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Session_Enrollment__c 
            WHERE reduivy__Individual_Enrollment__c IN :ienMap.keySet()
        ]){
            System.Assert.areEqual(ISN_Helper.getIenToIsnStatusMap().get(IEN_Helper.getDroppedStatuses()[0]), isn.reduivy__Enrollment_Status__c, 'The individual session enrollment should be updated as Dropped status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check student individual session enrollment's enrollment status after update associated individual enrollment status to 'Withdrawn'
     */
    @isTest
    static void testUpdateIenWithdrawnAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        //get the individual enrollment
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
        ]);
        System.Assert.areEqual(false, ienMap.isEmpty(), 'Individual Enrollment map should not be empty.');
        
        System.runAs(FACULTY_USER) {

            //set enrollment status = 'Withdrawn'
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_Helper.getWithdrawnStatuses()[0];
            }
        
            REDU_SystemMode_UTIL.doUpdate(ienMap.values());            
        }

        //check the related individual session enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Session_Enrollment__c 
            WHERE reduivy__Individual_Enrollment__c IN :ienMap.keySet()
        ]){
            System.Assert.areEqual(ISN_Helper.getIenToIsnStatusMap().get(IEN_Helper.getWithdrawnStatuses()[0]), isn.reduivy__Enrollment_Status__c, 'The individual session enrollment should be updated as Withdrawn status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check student individual session enrollment's enrollment status after update associated individual enrollment status to 'Withdrawn with Penalty'
     */
    @isTest
    static void testUpdateIenWithdrawnFailAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //get the individual enrollment
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
        ]);
        System.Assert.areEqual(false, ienMap.isEmpty(), 'Individual Enrollment map should not be empty.');
        
        System.runAs(FACULTY_USER) {

            //set enrollment status = 'Withdrawn'
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_Helper.getWithdrawnFailStatuses()[0];
            }
        
            REDU_SystemMode_UTIL.doUpdate(ienMap.values());
        }
        
        //check the related individual session enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Session_Enrollment__c 
            WHERE reduivy__Individual_Enrollment__c IN :ienMap.keySet()
        ]){
            System.Assert.areEqual(ISN_Helper.getIenToIsnStatusMap().get(IEN_Helper.getWithdrawnFailStatuses()[0]), isn.reduivy__Enrollment_Status__c, 'The individual session enrollment should be updated as Withdrawn status.');
        }

        Test.stopTest();
    }



    /**
     * @description Test as student to check individual session enrollment's enrollment status after update associated individual enrollment status to 'Completed'
     */
    @isTest
    static void testUpdateIenCompletedAsStudent() {

        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //get the individual enrollment
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ]);
        System.Assert.areEqual(false, ienMap.isEmpty(), 'Individual Enrollment map should not be empty.');
        
        System.runAs(studentUser) {

            //set enrollment status = 'Completed'
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_Helper.getCompletedPassStatuses()[0];
            }

            REDU_SystemMode_UTIL.doUpdate(ienMap.values());
        }

        //check the related individual session enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Session_Enrollment__c 
            WHERE reduivy__Individual_Enrollment__c IN :ienMap.keySet()
        ]){
            System.Assert.areEqual(ISN_Helper.getIenToIsnStatusMap().get(IEN_Helper.getCompletedPassStatuses()[0]), isn.reduivy__Enrollment_Status__c, 'The individual session enrollment should be updated as Completed status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student to check individual session enrollment's enrollment status after update associated individual enrollment status to 'Dropped'
     */
    @isTest
    static void testUpdateIenDroppedAsStudent() {

        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //get the individual enrollment
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ]);
        System.Assert.areEqual(false, ienMap.isEmpty(), 'Individual Enrollment map should not be empty.');
        
        System.runAs(studentUser) {

            //set enrollment status = 'Dropped'
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_Helper.getDroppedStatuses()[0];
            }

            REDU_SystemMode_UTIL.doUpdate(ienMap.values());
        }
        
        //check the related individual session enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Session_Enrollment__c 
            WHERE reduivy__Individual_Enrollment__c IN :ienMap.keySet()
        ]){
            System.Assert.areEqual(ISN_Helper.getIenToIsnStatusMap().get(IEN_Helper.getDroppedStatuses()[0]), isn.reduivy__Enrollment_Status__c, 'The individual session enrollment should be updated as Dropped status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student to check individual session enrollment's enrollment status after update associated individual enrollment status to 'Withdrawn'
     */
    @isTest
    static void testUpdateIenWithdrawnAsStudent() {

        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //get the individual enrollment
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ]);
        System.Assert.areEqual(false, ienMap.isEmpty(), 'Individual Enrollment map should not be empty.');
        
        System.runAs(studentUser) {

            //set enrollment status = 'Withdrawn'
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_Helper.getWithdrawnStatuses()[0];
            }
        
            REDU_SystemMode_UTIL.doUpdate(ienMap.values());            
        }

        //check the related individual session enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Session_Enrollment__c 
            WHERE reduivy__Individual_Enrollment__c IN :ienMap.keySet()
        ]){
            System.Assert.areEqual(ISN_Helper.getIenToIsnStatusMap().get(IEN_Helper.getWithdrawnStatuses()[0]), isn.reduivy__Enrollment_Status__c, 'The individual session enrollment should be updated as Withdrawn status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student to check individual session enrollment's enrollment status after update associated individual enrollment status to 'Withdrawn with Penalty'
     */
    @isTest
    static void testUpdateIenWithdrawnFailAsStudent() {

        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //get the individual enrollment
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ]);
        System.Assert.areEqual(false, ienMap.isEmpty(), 'Individual Enrollment map should not be empty.');
        
        System.runAs(studentUser) {

            //set enrollment status = 'Withdrawn'
            for(reduivy__Individual_Enrollment__c ien : ienMap.values()){
                ien.reduivy__Enrollment_Status__c = IEN_Helper.getWithdrawnFailStatuses()[0];
            }
        
            REDU_SystemMode_UTIL.doUpdate(ienMap.values());
        }
        
        //check the related individual session enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Session_Enrollment__c 
            WHERE reduivy__Individual_Enrollment__c IN :ienMap.keySet()
        ]){
            System.Assert.areEqual(ISN_Helper.getIenToIsnStatusMap().get(IEN_Helper.getWithdrawnFailStatuses()[0]), isn.reduivy__Enrollment_Status__c, 'The individual session enrollment should be updated as Withdrawn status.');
        }

        Test.stopTest();
    }
}