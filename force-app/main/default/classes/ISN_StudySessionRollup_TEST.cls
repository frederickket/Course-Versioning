/**
 * @author      WDCi (Sueanne)
 * @date        Sept 2024
 * @group       Test
 * @description Test class for ISN_StudySessionRollup_EXE
 * @changehistory
 * ISS-002060 02-09-2024 Sueanne - new class
 */
@isTest
public inherited sharing class ISN_StudySessionRollup_TEST {
    
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
        
        testFactory.setupDefaultSettings();

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
     * @description Test as admin for rollup booked place after insert individual session enrollment
     */
    @isTest
    static void testBookedPlaceAfterInsertAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnBookedStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                }
            }
        }

        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //get individual enrollment for isn creation
        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT Id FROM reduivy__Individual_Enrollment__c
        ];

        //create individual session enrollment
        List<reduivy__Individual_Session_Enrollment__c> isnToInsert = new List<reduivy__Individual_Session_Enrollment__c>();

        for(reduivy__Study_Session__c sse : sseMap.values()){
            Integer randIdx = (Integer)(Math.random() * isnBookedStatusSet.size());

            isnToInsert.add(REDU_TestData_UTIL.newStudentIndividualSessionEnrollment('To test study session places rollup', sse.Id, ienList[0].Id, null, isnBookedStatusSet[randIdx]));
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doInsert(isnToInsert);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Booked_Places__c != null ? sse.reduivy__Booked_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id) + 1, places, 'Study session\'s booked places does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup waitlisted place after insert individual session enrollment
     */
    @isTest
    static void testWaitlistedPlaceAfterInsertAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnWaitlistStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                }
            }
        }
 
        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //get individual enrollment for isn creation
        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT Id FROM reduivy__Individual_Enrollment__c
        ];

        //create isn
        List<reduivy__Individual_Session_Enrollment__c> isnToInsert = new List<reduivy__Individual_Session_Enrollment__c>();

        for(reduivy__Study_Session__c sse : sseMap.values()){
            Integer randIdx = (Integer)(Math.random() * isnWaitlistStatusSet.size());

            isnToInsert.add(REDU_TestData_UTIL.newStudentIndividualSessionEnrollment('To test study session places rollup', sse.Id, ienList[0].Id, null, isnWaitlistStatusSet[randIdx]));
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doInsert(isnToInsert);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Waitlist_Places__c != null ? sse.reduivy__Waitlist_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id) + 1, places, 'Study session\'s waitlisted place does not match.');
        }

        Test.stopTest();
    }
    
    /**
     * @description Test as admin for rollup booked place after update individual session enrollment
     */
    @isTest
    static void testBookedPlaceAfterUpdateAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                Integer randIdx = (Integer)(Math.random() * isnBookedStatusSet.size());

                reduivy__Individual_Session_Enrollment__c isnUpdate = new reduivy__Individual_Session_Enrollment__c();
                isnUpdate.Id = isn.Id;
                isnUpdate.reduivy__Enrollment_Status__c = isnBookedStatusSet[randIdx];
                isnToUpdate.add(isnUpdate);
            }            
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doUpdate(isnToUpdate);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Booked_Places__c != null ? sse.reduivy__Booked_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id), places, 'Study session\'s booked amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup waitlisted place after update individual session enrollment
     */
    @isTest
    static void testWaitlistedPlaceAfterUpdateAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                Integer randIdx = (Integer)(Math.random() * isnWaitlistStatusSet.size());

                reduivy__Individual_Session_Enrollment__c isnUpdate = new reduivy__Individual_Session_Enrollment__c();
                isnUpdate.Id = isn.Id;
                isnUpdate.reduivy__Enrollment_Status__c = isnWaitlistStatusSet[randIdx];
                isnToUpdate.add(isnUpdate);
            }            
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doUpdate(isnToUpdate);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Waitlist_Places__c != null ? sse.reduivy__Waitlist_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id), places, 'Study session\'s waitlisted amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup booked place after delete individual session enrollment
     */
    @isTest
    static void testBookedPlaceAfterDeleteAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        List<reduivy__Individual_Session_Enrollment__c> isnToDelete = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnBookedStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    isnToDelete.add(isn);
                }
            }            
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doDelete(isnToDelete);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Booked_Places__c != null ? sse.reduivy__Booked_Places__c : 0;
            System.Assert.areEqual(0, places, 'Study session\'s booked amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup waitlisted place after delete individual session enrollment
     */
    @isTest
    static void testWaitlistedPlaceAfterDeleteAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        List<reduivy__Individual_Session_Enrollment__c> isnToDelete = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnWaitlistStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    isnToDelete.add(isn);
                }
            }            
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doDelete(isnToDelete);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Waitlist_Places__c != null ? sse.reduivy__Waitlist_Places__c : 0;
            System.Assert.areEqual(0, places, 'Study session\'s waitlisted amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup booked place after undelete individual session enrollment
     */
    @isTest
    static void testBookedPlaceAfterUndeleteAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        List<reduivy__Individual_Session_Enrollment__c> isnToDelete = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnBookedStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                    isnToDelete.add(isn);
                }
            }            
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doDelete(isnToDelete);

            undelete isnToDelete;
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Booked_Places__c != null ? sse.reduivy__Booked_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id), places, 'Study session\'s booked amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup waitlisted place after undelete individual session enrollment
     */
    @isTest
    static void testWaitlistedPlaceAfterUndeleteAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        List<reduivy__Individual_Session_Enrollment__c> isnToDelete = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnWaitlistStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                    isnToDelete.add(isn);
                }
            }            
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doDelete(isnToDelete);

            undelete isnToDelete;
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Waitlist_Places__c != null ? sse.reduivy__Waitlist_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id), places, 'Study session\'s waitlisted amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup booked place after insert individual session enrollment
     */
    @isTest
    static void testBookedPlaceAfterInsertAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnBookedStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                }
            }
        }

        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //get individual enrollment for isn creation
        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT Id FROM reduivy__Individual_Enrollment__c
        ];

        //create individual session enrollment
        List<reduivy__Individual_Session_Enrollment__c> isnToInsert = new List<reduivy__Individual_Session_Enrollment__c>();

        for(reduivy__Study_Session__c sse : sseMap.values()){
            Integer randIdx = (Integer)(Math.random() * isnBookedStatusSet.size());

            isnToInsert.add(REDU_TestData_UTIL.newStudentIndividualSessionEnrollment('To test study session places rollup', sse.Id, ienList[0].Id, null, isnBookedStatusSet[randIdx]));
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doInsert(isnToInsert);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Booked_Places__c != null ? sse.reduivy__Booked_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id) + 1, places, 'Study session\'s booked places does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup waitlisted place after insert individual session enrollment
     */
    @isTest
    static void testWaitlistedPlaceAfterInsertAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnWaitlistStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                }
            }
        }
 
        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //get individual enrollment for isn creation
        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT Id FROM reduivy__Individual_Enrollment__c
        ];

        //create isn
        List<reduivy__Individual_Session_Enrollment__c> isnToInsert = new List<reduivy__Individual_Session_Enrollment__c>();

        for(reduivy__Study_Session__c sse : sseMap.values()){
            Integer randIdx = (Integer)(Math.random() * isnWaitlistStatusSet.size());

            isnToInsert.add(REDU_TestData_UTIL.newStudentIndividualSessionEnrollment('To test study session places rollup', sse.Id, ienList[0].Id, null, isnWaitlistStatusSet[randIdx]));
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doInsert(isnToInsert);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Waitlist_Places__c != null ? sse.reduivy__Waitlist_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id) + 1, places, 'Study session\'s waitlisted place does not match.');
        }

        Test.stopTest();
    }
    
    /**
     * @description Test as faculty for rollup booked place after update individual session enrollment
     */
    @isTest
    static void testBookedPlaceAfterUpdateAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                Integer randIdx = (Integer)(Math.random() * isnBookedStatusSet.size());

                reduivy__Individual_Session_Enrollment__c isnUpdate = new reduivy__Individual_Session_Enrollment__c();
                isnUpdate.Id = isn.Id;
                isnUpdate.reduivy__Enrollment_Status__c = isnBookedStatusSet[randIdx];
                isnToUpdate.add(isnUpdate);
            }            
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doUpdate(isnToUpdate);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Booked_Places__c != null ? sse.reduivy__Booked_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id), places, 'Study session\'s booked amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup waitlisted place after update individual session enrollment
     */
    @isTest
    static void testWaitlistedPlaceAfterUpdateAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                Integer randIdx = (Integer)(Math.random() * isnWaitlistStatusSet.size());

                reduivy__Individual_Session_Enrollment__c isnUpdate = new reduivy__Individual_Session_Enrollment__c();
                isnUpdate.Id = isn.Id;
                isnUpdate.reduivy__Enrollment_Status__c = isnWaitlistStatusSet[randIdx];
                isnToUpdate.add(isnUpdate);
            }            
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doUpdate(isnToUpdate);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Waitlist_Places__c != null ? sse.reduivy__Waitlist_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id), places, 'Study session\'s waitlisted amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup booked place after delete individual session enrollment
     */
    @isTest
    static void testBookedPlaceAfterDeleteAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        List<reduivy__Individual_Session_Enrollment__c> isnToDelete = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnBookedStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    isnToDelete.add(isn);
                }
            }            
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doDelete(isnToDelete);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Booked_Places__c != null ? sse.reduivy__Booked_Places__c : 0;
            System.Assert.areEqual(0, places, 'Study session\'s booked amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup waitlisted place after delete individual session enrollment
     */
    @isTest
    static void testWaitlistedPlaceAfterDeleteAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        List<reduivy__Individual_Session_Enrollment__c> isnToDelete = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnWaitlistStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    isnToDelete.add(isn);
                }
            }            
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doDelete(isnToDelete);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Waitlist_Places__c != null ? sse.reduivy__Waitlist_Places__c : 0;
            System.Assert.areEqual(0, places, 'Study session\'s waitlisted amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup booked place after undelete individual session enrollment
     */
    @isTest
    static void testBookedPlaceAfterUndeleteAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        List<reduivy__Individual_Session_Enrollment__c> isnToDelete = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnBookedStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                    isnToDelete.add(isn);
                }
            }            
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doDelete(isnToDelete);

            undelete isnToDelete;
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Booked_Places__c != null ? sse.reduivy__Booked_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id), places, 'Study session\'s booked amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup waitlisted place after undelete individual session enrollment
     */
    @isTest
    static void testWaitlistedPlaceAfterUndeleteAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        List<reduivy__Individual_Session_Enrollment__c> isnToDelete = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnWaitlistStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                    isnToDelete.add(isn);
                }
            }            
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doDelete(isnToDelete);

            undelete isnToDelete;
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Waitlist_Places__c != null ? sse.reduivy__Waitlist_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id), places, 'Study session\'s waitlisted amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup booked place after insert individual session enrollment
     */
    @isTest
    static void testBookedPlaceAfterInsertAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnBookedStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                }
            }
        }

        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE Id = :studentUser.contactId
            LIMIT 1
        ];

        //get individual enrollment for isn creation
        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT Id FROM reduivy__Individual_Enrollment__c
        ];

        //create individual session enrollment
        List<reduivy__Individual_Session_Enrollment__c> isnToInsert = new List<reduivy__Individual_Session_Enrollment__c>();

        for(reduivy__Study_Session__c sse : sseMap.values()){
            Integer randIdx = (Integer)(Math.random() * isnBookedStatusSet.size());

            isnToInsert.add(REDU_TestData_UTIL.newStudentIndividualSessionEnrollment('To test study session places rollup', sse.Id, ienList[0].Id, null, isnBookedStatusSet[randIdx]));
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doInsert(isnToInsert);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Booked_Places__c != null ? sse.reduivy__Booked_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id) + 1, places, 'Study session\'s booked places does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup booked place after insert individual session enrollment, but study session is fully booked
     */
    @isTest
    static void testFullyBookedPlaceAfterInsertAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, Name,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
            LIMIT 1
        ]);

        //get current amount and update the capacity
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnBookedStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                }
            }
            sse.reduivy__Capacity__c = 2;
        }

        update sseMap.values();

        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE Id = :studentUser.contactId
            LIMIT 1
        ];

        //get individual enrollment for isn creation
        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT Id FROM reduivy__Individual_Enrollment__c
        ];

        //create individual session enrollment
        List<reduivy__Individual_Session_Enrollment__c> isnToInsert = new List<reduivy__Individual_Session_Enrollment__c>();

        for(reduivy__Study_Session__c sse : sseMap.values()){
            for(Integer i = 0; i < sse.reduivy__Capacity__c + 1; i++) {
                Integer randIdx = (Integer)(Math.random() * isnBookedStatusSet.size());                
                
                isnToInsert.add(REDU_TestData_UTIL.newStudentIndividualSessionEnrollment('To test study session places rollup', sse.Id, ienList[0].Id, null, isnBookedStatusSet[randIdx]));
            }
        }

        System.runAs(studentUser){
            try{
                REDU_SystemMode_UTIL.doInsert(isnToInsert);
                System.Assert.fail('Should be failed due to Study Session Capacity!');
            } catch(Exception exp) {
                String expectedError = String.format(
                    Label.Error_No_Available_Places_Remaining_In_Study_Session,
                    new List<String> {
                        SSE_Helper.getObjectLabel(),
                        sseMap.values()[0].Name
                    }
                );
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Wrong exception message! Excepted: ' + expectedError + ', Actual: ' + exp.getMessage());
            }
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Booked_Places__c != null ? sse.reduivy__Booked_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id), places, 'Study session\'s booked places does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup waitlisted place after insert individual session enrollment
     */
    @isTest
    static void testWaitlistedPlaceAfterInsertAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnWaitlistStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                }
            }
        }
 
        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE Id = :studentUser.contactId
            LIMIT 1
        ];

        //get individual enrollment for isn creation
        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT Id FROM reduivy__Individual_Enrollment__c
        ];

        //create isn
        List<reduivy__Individual_Session_Enrollment__c> isnToInsert = new List<reduivy__Individual_Session_Enrollment__c>();

        for(reduivy__Study_Session__c sse : sseMap.values()){
            Integer randIdx = (Integer)(Math.random() * isnWaitlistStatusSet.size());

            isnToInsert.add(REDU_TestData_UTIL.newStudentIndividualSessionEnrollment('To test study session places rollup', sse.Id, ienList[0].Id, null, isnWaitlistStatusSet[randIdx]));
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doInsert(isnToInsert);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Waitlist_Places__c != null ? sse.reduivy__Waitlist_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id) + 1, places, 'Study session\'s waitlisted place does not match.');
        }

        Test.stopTest();
    }
    
    /**
     * @description Test as student for rollup booked place after update individual session enrollment
     */
    @isTest
    static void testBookedPlaceAfterUpdateAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                Integer randIdx = (Integer)(Math.random() * isnBookedStatusSet.size());

                reduivy__Individual_Session_Enrollment__c isnUpdate = new reduivy__Individual_Session_Enrollment__c();
                isnUpdate.Id = isn.Id;
                isnUpdate.reduivy__Enrollment_Status__c = isnBookedStatusSet[randIdx];
                isnToUpdate.add(isnUpdate);
            }            
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doUpdate(isnToUpdate);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Booked_Places__c != null ? sse.reduivy__Booked_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id), places, 'Study session\'s booked amount does not match.');
        }

        Test.stopTest();
    }
    
    /**
     * @description Test as student for rollup booked place after update individual session enrollment, but study session is fully booked
     */
    @isTest
    static void testFullyBookedPlaceAfterUpdateAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, Name,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
            LIMIT 1
        ]);

        //get individual enrollment for isn creation
        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT Id FROM reduivy__Individual_Enrollment__c
        ];

        //create individual session enrollment
        String IsnOpenStatus = ISN_Helper.getOpenStatuses()[0];
        List<reduivy__Individual_Session_Enrollment__c> isnToInsert = new List<reduivy__Individual_Session_Enrollment__c> {
             REDU_TestData_UTIL.newStudentIndividualSessionEnrollment('To test study session places rollup', sseMap.values()[0].Id, ienList[0].Id, null, IsnOpenStatus)
        };
        
        insert isnToInsert;

        sseMap.values()[0].reduivy__Capacity__c = 1;
        
        update sseMap.values();

        isnToInsert[0].reduivy__Enrollment_Status__c = isnBookedStatusSet[0];

        System.runAs(studentUser){
            try{
                REDU_SystemMode_UTIL.doUpdate(isnToInsert);
                System.Assert.fail('Should be failed due to Study Session Capacity!');
            } catch(Exception exp) {
                String expectedError = String.format(
                    Label.Error_No_Available_Places_Remaining_In_Study_Session,
                    new List<String> {
                        SSE_Helper.getObjectLabel(),
                        sseMap.values()[0].Name
                    }
                );
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Wrong exception message! Excepted: ' + expectedError + ', Actual: ' + exp.getMessage());
            }
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Booked_Places__c != null ? sse.reduivy__Booked_Places__c : 0;
            System.Assert.areEqual(sse.reduivy__Capacity__c, places, 'Study session\'s booked amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup waitlisted place after update individual session enrollment
     */
    @isTest
    static void testWaitlistedPlaceAfterUpdateAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                Integer randIdx = (Integer)(Math.random() * isnWaitlistStatusSet.size());

                reduivy__Individual_Session_Enrollment__c isnUpdate = new reduivy__Individual_Session_Enrollment__c();
                isnUpdate.Id = isn.Id;
                isnUpdate.reduivy__Enrollment_Status__c = isnWaitlistStatusSet[randIdx];
                isnToUpdate.add(isnUpdate);
            }            
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doUpdate(isnToUpdate);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Waitlist_Places__c != null ? sse.reduivy__Waitlist_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id), places, 'Study session\'s waitlisted amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup booked place after delete individual session enrollment
     */
    @isTest
    static void testBookedPlaceAfterDeleteAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        List<reduivy__Individual_Session_Enrollment__c> isnToDelete = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnBookedStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    isnToDelete.add(isn);
                }
            }            
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doDelete(isnToDelete);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Booked_Places__c != null ? sse.reduivy__Booked_Places__c : 0;
            System.Assert.areEqual(0, places, 'Study session\'s booked amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup waitlisted place after delete individual session enrollment
     */
    @isTest
    static void testWaitlistedPlaceAfterDeleteAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        List<reduivy__Individual_Session_Enrollment__c> isnToDelete = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnWaitlistStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    isnToDelete.add(isn);
                }
            }
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doDelete(isnToDelete);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Waitlist_Places__c != null ? sse.reduivy__Waitlist_Places__c : 0;
            System.Assert.areEqual(0, places, 'Study session\'s waitlisted amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup booked place after undelete individual session enrollment
     */
    @isTest
    static void testBookedPlaceAfterUndeleteAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c, reduivy__Contact_Id__c
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        List<reduivy__Individual_Session_Enrollment__c> isnToDelete = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnBookedStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    countMap.put(sse.Id, countMap.get(sse.Id) + 1);

                    if(isn.reduivy__Contact_Id__c == studentUser.contactId){
                        isnToDelete.add(isn);
                    }
                }
            }            
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doDelete(isnToDelete);

            undelete isnToDelete;
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Booked_Places__c != null ? sse.reduivy__Booked_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id), places, 'Study session\'s booked amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup waitlisted place after undelete individual session enrollment
     */
    @isTest
    static void testWaitlistedPlaceAfterUndeleteAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);

        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        List<reduivy__Individual_Session_Enrollment__c> isnToDelete = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            countMap.put(sse.Id, 0);

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(isnWaitlistStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    countMap.put(sse.Id, countMap.get(sse.Id) + 1);
                    isnToDelete.add(isn);
                }
            }            
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doDelete(isnToDelete);

            undelete isnToDelete;
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal places = sse.reduivy__Waitlist_Places__c != null ? sse.reduivy__Waitlist_Places__c : 0;
            System.Assert.areEqual(countMap.get(sse.Id), places, 'Study session\'s waitlisted amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup waitlisted place after update individual session enrollment's lookup study session
     */
    @isTest
    static void testUpdateAssociatedSseAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c 
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);
        List<reduivy__Study_Session__c> sseList = new List<reduivy__Study_Session__c>(sseMap.values());

        Map<Id, Decimal> countBooked = new Map<Id, Decimal>();
        Map<Id, Decimal> countWaitlisted = new Map<Id, Decimal>();
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            if(!countBooked.containsKey(sse.Id)){
                countBooked.put(sse.Id, 0);
            }

            if(!countWaitlisted.containsKey(sse.Id)){
                countWaitlisted.put(sse.Id, 0);
            }

            Id sseId = sse.Id;

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                if(sse.Id == sseList[0].Id){
                    sseId = sseList[1].Id;

                    reduivy__Individual_Session_Enrollment__c isnUpdate = new reduivy__Individual_Session_Enrollment__c();
                    isnUpdate.Id = isn.Id;
                    isnUpdate.reduivy__Study_Session__c = sseId;
                    isnToUpdate.add(isnUpdate);

                    if(!countBooked.containsKey(sseId)){
                        countBooked.put(sseId, 0);
                    }
        
                    if(!countWaitlisted.containsKey(sseId)){
                        countWaitlisted.put(sseId, 0);
                    }
                } 

                if(isnBookedStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    countBooked.put(sseId, countBooked.get(sseId) + 1);

                } else if(isnWaitlistStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    countWaitlisted.put(sseId, countWaitlisted.get(sseId) + 1);
                }
            }            
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doUpdate(isnToUpdate);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal bookedPlaces = sse.reduivy__Booked_Places__c != null ? sse.reduivy__Booked_Places__c : 0;
            Decimal waitlistedPlaces = sse.reduivy__Waitlist_Places__c != null ? sse.reduivy__Waitlist_Places__c : 0;
            System.Assert.areEqual(countBooked.get(sse.Id), bookedPlaces, 'Study session\'s booked amount does not match.');
            System.Assert.areEqual(countWaitlisted.get(sse.Id), waitlistedPlaces, 'Study session\'s waitlisted amount does not match.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup booked place after update individual session enrollment's enrollment status
     */
    @isTest
    static void testUpdateStatusEnrolledToNotStartedAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //statuses
        List<String> isnBookedStatusSet = new List<String>();
        isnBookedStatusSet.addAll(ISN_Helper.getInProgressStatuses());
        isnBookedStatusSet.addAll(ISN_Helper.getCompletedStatuses());

        List<String> isnWaitlistStatusSet = new List<String>();
        isnWaitlistStatusSet.addAll(ISN_Helper.getWaitlistedStatuses());

        //get study session 
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c,
                (SELECT Id, reduivy__Enrollment_Status__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollments__r 
                WHERE RecordTypeId = :ISN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Session__c
            WITH SYSTEM_MODE
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'Study Session map should not be empty.');
        List<reduivy__Study_Session__c> sseList = new List<reduivy__Study_Session__c>(sseMap.values());


        Map<Id, Decimal> countBooked = new Map<Id, Decimal>();
        Map<Id, Decimal> countWaitlisted = new Map<Id, Decimal>();
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = new List<reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Study_Session__c sse : sseMap.values()){

            if(!countBooked.containsKey(sse.Id)){
                countBooked.put(sse.Id, 0);
            }

            if(!countWaitlisted.containsKey(sse.Id)){
                countWaitlisted.put(sse.Id, 0);
            }

            for(reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r){

                System.Assert.areEqual(ISN_Helper.getInProgressStatuses()[0], isn.reduivy__Enrollment_Status__c, 'Individual Session Enrollment\'s enrollment status should be Not Started before test.');

                reduivy__Individual_Session_Enrollment__c isnUpdate = new reduivy__Individual_Session_Enrollment__c();
                isnUpdate.Id = isn.Id;
                isnUpdate.reduivy__Enrollment_Status__c = ISN_Helper.getOpenStatuses()[0];
                isnToUpdate.add(isnUpdate);

                isn.reduivy__Enrollment_Status__c = ISN_Helper.getOpenStatuses()[0];
                
                if(isnBookedStatusSet.contains(isn.reduivy__Enrollment_Status__c)){ 
                    countBooked.put(sse.Id, countBooked.get(sse.Id) + 1);

                } else if(isnWaitlistStatusSet.contains(isn.reduivy__Enrollment_Status__c)){
                    countWaitlisted.put(sse.Id, countWaitlisted.get(sse.Id) + 1);
                }
            }            
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doUpdate(isnToUpdate);
        }

        //validate result
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
            FROM reduivy__Study_Session__c
            WHERE Id IN :sseMap.keySet()
        ]){
            Decimal bookedPlaces = sse.reduivy__Booked_Places__c != null ? sse.reduivy__Booked_Places__c : 0;
            Decimal waitlistedPlaces = sse.reduivy__Waitlist_Places__c != null ? sse.reduivy__Waitlist_Places__c : 0;
            System.Assert.areEqual(countBooked.get(sse.Id), bookedPlaces, 'Study session\'s booked amount does not match.');
            System.Assert.areEqual(countWaitlisted.get(sse.Id), waitlistedPlaces, 'Study session\'s waitlisted amount does not match.');
        }

        Test.stopTest();
    }

}