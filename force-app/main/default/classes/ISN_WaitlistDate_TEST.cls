/**
 * @author      WDCi (Sueanne)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for ISN_WaitlistDate_EXE
 * @changehistory
 * ISS-002056 23-08-2024 Sueanne - new class
 */
@IsTest
public inherited sharing class ISN_WaitlistDate_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
    static String ISN_INPROGRESS_STATUS = ISN_Helper.getInProgressStatuses().get(0);
    static String ISN_OPEN_STATUS = ISN_Helper.getOpenStatuses().get(0);
    static final String ISN_WITHDRAWN_STATUS = ISN_Helper.getWithdrawnStatuses().get(0);

    /**
     * @description Create settings and test data
     */
	@TestSetup
    static void makeData() {
		
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
                        studentIndividualSessionEnrollments.put(isnSampleRecord, REDU_TestData_UTIL.newStudentIndividualSessionEnrollment(isnSampleRecord, ss.Id, idvEnroll.Id, ss.reduivy__Start_Date__c, ISN_OPEN_STATUS));
                    }
                }
            }

            REDU_SystemMode_UTIL.doInsert(studentIndividualSessionEnrollments.values());

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin to check the waitlist date when updated individual session enrollment's enrollment status to 'Waitlisted' status (BeforeUpdate)
     */
    @IsTest
    static void testUpdateIsnToWaitlistedAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        DateTime presetDateTime = Datetime.newInstance(2000, 2, 20);
        Date expectedDate;
        reduivy__RIO_Education_Ivy_Settings__c cs = reduivy__RIO_Education_Ivy_Settings__c.getOrgDefaults();

        Test.startTest();

        //get Waitlisted and Enrollment Requested statuses
        List<String> waitlistedStatuses = ISN_Helper.getWaitlistedStatuses();
        List<String> enrollreqStatuses = ISN_Helper.getEnrollmentRequestedStatuses();

        Set<String> statusesToPopulateDate = new Set<String>();
        statusesToPopulateDate.addAll(waitlistedStatuses);
        statusesToPopulateDate.addAll(enrollreqStatuses);

        //get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :statusesToPopulateDate
            AND reduivy__Waitlist_Date__c = NULL
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ]);

        System.Assert.areEqual(false, isnMap.isEmpty(), 'Individual session enrollment record no found.');

        System.runAs(ADMIN_USER) {
            Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = false;

            update Cs;

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
            
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = waitlistedStatuses[0];
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
            expectedDate = System.now().date();
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areEqual(expectedDate, isn.reduivy__Waitlist_Date__c.date(), 'Waitlisted date should be today\'s date.');
        }

        System.runAs(ADMIN_USER) {
            Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = true;

            update Cs;

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
            
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = waitlistedStatuses[0];
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areEqual(presetDateTime, isn.reduivy__Waitlist_Date__c, 'Waitlisted date should be presetDateTime.');
        }

        System.runAs(ADMIN_USER) {

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_OPEN_STATUS;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be removed.');
        }

        System.runAs(ADMIN_USER) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_WITHDRAWN_STATUS;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.areEqual(presetDateTime, isn.reduivy__Waitlist_Date__c, 'The waitlist date should not be updated after changed to the withdrawn status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin to check the waitlist date when updated individual session enrollment's enrollment status to 'Enrollment Requested' status (BeforeUpdate)
     */
    @IsTest
    static void testUpdateIsnToEnrollmentRequestedAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        DateTime presetDateTime = Datetime.newInstance(2000, 2, 20);
        Date expectedDate;
        reduivy__RIO_Education_Ivy_Settings__c cs = reduivy__RIO_Education_Ivy_Settings__c.getOrgDefaults();
        
        Test.startTest();

        //get Waitlisted and Enrollment Requested statuses
        List<String> waitlistedStatuses = ISN_Helper.getWaitlistedStatuses();
        List<String> enrollreqStatuses = ISN_Helper.getEnrollmentRequestedStatuses();

        Set<String> statusesToPopulateDate = new Set<String>();
        statusesToPopulateDate.addAll(waitlistedStatuses);
        statusesToPopulateDate.addAll(enrollreqStatuses);

        //get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :statusesToPopulateDate
            AND reduivy__Waitlist_Date__c = NULL
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ]);

        System.Assert.areEqual(false, isnMap.isEmpty(), 'Individual session enrollment record no found.');

        System.runAs(ADMIN_USER) {
            Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = false;
    
            update Cs;

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = enrollreqStatuses[0];
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
            expectedDate = System.now().date();
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areEqual(expectedDate, isn.reduivy__Waitlist_Date__c.date(), 'Waitlisted date should be today\'s date.');
        }

        System.runAs(ADMIN_USER) {
            Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = true;
    
            update Cs;

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = enrollreqStatuses[0];
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areEqual(presetDateTime, isn.reduivy__Waitlist_Date__c, 'Waitlisted date should be presetDateTime.');
        }

        System.runAs(ADMIN_USER) {

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_OPEN_STATUS;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be removed.');
        }

        System.runAs(ADMIN_USER) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_WITHDRAWN_STATUS;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.areEqual(presetDateTime, isn.reduivy__Waitlist_Date__c, 'The waitlist date should not be updated after changed to the withdrawn status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin to check the waitlist date when insert individual session enrollment with 'Waitlisted' enrollment status (BeforeInsert)
     */
    @IsTest
    static void testInsertIsnToWaitlistedAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get Waitlisted and Enrollment Requested statuses
        List<String> waitlistedStatuses = ISN_Helper.getWaitlistedStatuses();
        List<String> enrollreqStatuses = ISN_Helper.getEnrollmentRequestedStatuses();

        Date expectedDate;

        Set<String> statusesToPopulateDate = new Set<String>();
        statusesToPopulateDate.addAll(waitlistedStatuses);
        statusesToPopulateDate.addAll(enrollreqStatuses);

        //get study sessions
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Start_Date__c
            FROM reduivy__Study_Session__c
        ]);

        System.Assert.areEqual(false, sseMap.isEmpty(), 'Study session record no found.');

        //get student individual enrollment
        List<reduivy__Individual_Enrollment__c> ien = [
            SELECT Id 
            FROM reduivy__Individual_Enrollment__c 
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            LIMIT 1
        ];

        List<reduivy__Individual_Session_Enrollment__c> isnToInsert = new List<reduivy__Individual_Session_Enrollment__c>();

        System.runAs(ADMIN_USER) {

            for(reduivy__Study_Session__c sse : sseMap.values()){
                isnToInsert.add(REDU_TestData_UTIL.newStudentIndividualSessionEnrollment('To_test_waitlistedDate', sse.Id, ien[0].Id, sse.reduivy__Start_Date__c, waitlistedStatuses[0]));
            }
            
            REDU_SystemMode_UTIL.doInsert(isnToInsert);
            expectedDate = System.now().date();
        }

        //get isn Id
        List<Id> isnIds = new List<Id>();
        for(reduivy__Individual_Session_Enrollment__c isn : isnToInsert){
            isnIds.add(isn.Id);
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnIds
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areEqual(expectedDate, isn.reduivy__Waitlist_Date__c.date(), 'Waitlist date should be today\'s date.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin to check the waitlist date when insert individual session enrollment with 'Enrollment Requested' enrollment status (BeforeInsert)
     */
    @IsTest
    static void testInsertIsnToEnrollmentRequestedAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get Waitlisted and Enrollment Requested statuses
        List<String> waitlistedStatuses = ISN_Helper.getWaitlistedStatuses();
        List<String> enrollreqStatuses = ISN_Helper.getEnrollmentRequestedStatuses();

        Date expectedDate;

        Set<String> statusesToPopulateDate = new Set<String>();
        statusesToPopulateDate.addAll(waitlistedStatuses);
        statusesToPopulateDate.addAll(enrollreqStatuses);

        //get study sessions
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Start_Date__c
            FROM reduivy__Study_Session__c
        ]);

        System.Assert.areEqual(false, sseMap.isEmpty(), 'Study session record no found.');

        //get student individual enrollment
        List<reduivy__Individual_Enrollment__c> ien = [
            SELECT Id 
            FROM reduivy__Individual_Enrollment__c 
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            LIMIT 1
        ];

        List<reduivy__Individual_Session_Enrollment__c> isnToInsert = new List<reduivy__Individual_Session_Enrollment__c>();

        System.runAs(ADMIN_USER) {

            for(reduivy__Study_Session__c sse : sseMap.values()){
                isnToInsert.add(REDU_TestData_UTIL.newStudentIndividualSessionEnrollment('To_test_waitlistedDate', sse.Id, ien[0].Id, sse.reduivy__Start_Date__c, enrollreqStatuses[0]));
            }
            
            REDU_SystemMode_UTIL.doInsert(isnToInsert);

            expectedDate = System.now().date();
        }

        //get isn Id
        List<Id> isnIds = new List<Id>();
        for(reduivy__Individual_Session_Enrollment__c isn : isnToInsert){
            isnIds.add(isn.Id);
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnIds
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areEqual(expectedDate, isn.reduivy__Waitlist_Date__c.date(), 'Waitlist date should be today\'s date.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check the waitlist date when updated individual session enrollment's enrollment status to 'Waitlisted' status (BeforeUpdate)
     */
    @IsTest
    static void testUpdateIsnToWaitlistedAsFaculty() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        DateTime presetDateTime = Datetime.newInstance(2000, 2, 20);
        reduivy__RIO_Education_Ivy_Settings__c cs = reduivy__RIO_Education_Ivy_Settings__c.getOrgDefaults();

        Test.startTest();

        //get Waitlisted and Enrollment Requested statuses
        List<String> waitlistedStatuses = ISN_Helper.getWaitlistedStatuses();
        List<String> enrollreqStatuses = ISN_Helper.getEnrollmentRequestedStatuses();

        Set<String> statusesToPopulateDate = new Set<String>();
        statusesToPopulateDate.addAll(waitlistedStatuses);
        statusesToPopulateDate.addAll(enrollreqStatuses);

        //get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :statusesToPopulateDate
            AND reduivy__Waitlist_Date__c = NULL
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ]);

        System.Assert.areEqual(false, isnMap.isEmpty(), 'Individual session enrollment record no found.');

        Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = false;
    
        update Cs;

        System.runAs(FACULTY_USER) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = waitlistedStatuses[0];
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areNotEqual(presetDateTime, isn.reduivy__Waitlist_Date__c, 'The waitlist date should be updated.');
        }

        Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = true;
    
        update Cs;

        System.runAs(FACULTY_USER) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = waitlistedStatuses[0];
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areEqual(presetDateTime, isn.reduivy__Waitlist_Date__c, 'Waitlisted date should be presetDateTime.');
        }

        System.runAs(FACULTY_USER) {

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_OPEN_STATUS;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be removed.');
        }

        System.runAs(FACULTY_USER) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_WITHDRAWN_STATUS;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.areEqual(presetDateTime, isn.reduivy__Waitlist_Date__c, 'The waitlist date should not be updated after changed to the withdrawn status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check the waitlist date when updated individual session enrollment's enrollment status to 'Enrollment Requested' status (BeforeUpdate)
     */
    @IsTest
    static void testUpdateIsnToEnrollmentRequestedAsFaculty() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        DateTime presetDateTime = Datetime.newInstance(2000, 2, 20);
        reduivy__RIO_Education_Ivy_Settings__c cs = reduivy__RIO_Education_Ivy_Settings__c.getOrgDefaults();
        
        Test.startTest();

        //get Waitlisted and Enrollment Requested statuses
        List<String> waitlistedStatuses = ISN_Helper.getWaitlistedStatuses();
        List<String> enrollreqStatuses = ISN_Helper.getEnrollmentRequestedStatuses();

        Set<String> statusesToPopulateDate = new Set<String>();
        statusesToPopulateDate.addAll(waitlistedStatuses);
        statusesToPopulateDate.addAll(enrollreqStatuses);

        //get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :statusesToPopulateDate
            AND reduivy__Waitlist_Date__c = NULL
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ]);

        System.Assert.areEqual(false, isnMap.isEmpty(), 'Individual session enrollment record no found.');

        System.runAs(FACULTY_USER) {
            Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = false;
    
            update Cs;

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = enrollreqStatuses[0];
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areNotEqual(presetDateTime, isn.reduivy__Waitlist_Date__c, 'The waitlist date should be updated.');
        }

        System.runAs(FACULTY_USER) {
            Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = true;
    
            update Cs;

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = enrollreqStatuses[0];
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areEqual(presetDateTime, isn.reduivy__Waitlist_Date__c, 'Waitlisted date should be presetDateTime.');
        }

        System.runAs(FACULTY_USER) {

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_OPEN_STATUS;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be removed.');
        }

        System.runAs(FACULTY_USER) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_WITHDRAWN_STATUS;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.areEqual(presetDateTime, isn.reduivy__Waitlist_Date__c, 'The waitlist date should not be updated after changed to the withdrawn status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check the waitlist date when insert individual session enrollment with 'Waitlisted' enrollment status (BeforeInsert)
     */
    @IsTest
    static void testInsertIsnToWaitlistedAsFaculty() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //get Waitlisted and Enrollment Requested statuses
        List<String> waitlistedStatuses = ISN_Helper.getWaitlistedStatuses();
        List<String> enrollreqStatuses = ISN_Helper.getEnrollmentRequestedStatuses();

        Date expectedDate;

        Set<String> statusesToPopulateDate = new Set<String>();
        statusesToPopulateDate.addAll(waitlistedStatuses);
        statusesToPopulateDate.addAll(enrollreqStatuses);

        //get study sessions
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Start_Date__c
            FROM reduivy__Study_Session__c
        ]);

        System.Assert.areEqual(false, sseMap.isEmpty(), 'Study session record no found.');

        //get student individual enrollment
        List<reduivy__Individual_Enrollment__c> ien = [
            SELECT Id 
            FROM reduivy__Individual_Enrollment__c 
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            LIMIT 1
        ];

        List<reduivy__Individual_Session_Enrollment__c> isnToInsert = new List<reduivy__Individual_Session_Enrollment__c>();

        System.runAs(FACULTY_USER) {

            for(reduivy__Study_Session__c sse : sseMap.values()){
                isnToInsert.add(REDU_TestData_UTIL.newStudentIndividualSessionEnrollment('To_test_waitlistedDate', sse.Id, ien[0].Id, sse.reduivy__Start_Date__c, waitlistedStatuses[0]));
            }
            
            REDU_SystemMode_UTIL.doInsert(isnToInsert);
            expectedDate = System.now().date();
        }

        //get isn Id
        List<Id> isnIds = new List<Id>();
        for(reduivy__Individual_Session_Enrollment__c isn : isnToInsert){
            isnIds.add(isn.Id);
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnIds
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areEqual(expectedDate, isn.reduivy__Waitlist_Date__c.date(), 'Waitlist date should be today\'s date.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty to check the waitlist date when insert individual session enrollment with 'Enrollment Requested' enrollment status (BeforeInsert)
     */
    @IsTest
    static void testInsertIsnToEnrollmentRequestedAsFaculty() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //get Waitlisted and Enrollment Requested statuses
        List<String> waitlistedStatuses = ISN_Helper.getWaitlistedStatuses();
        List<String> enrollreqStatuses = ISN_Helper.getEnrollmentRequestedStatuses();

        Date expectedDate;

        Set<String> statusesToPopulateDate = new Set<String>();
        statusesToPopulateDate.addAll(waitlistedStatuses);
        statusesToPopulateDate.addAll(enrollreqStatuses);

        //get study sessions
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Start_Date__c
            FROM reduivy__Study_Session__c
        ]);

        System.Assert.areEqual(false, sseMap.isEmpty(), 'Study session record no found.');

        //get student individual enrollment
        List<reduivy__Individual_Enrollment__c> ien = [
            SELECT Id 
            FROM reduivy__Individual_Enrollment__c 
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            LIMIT 1
        ];

        List<reduivy__Individual_Session_Enrollment__c> isnToInsert = new List<reduivy__Individual_Session_Enrollment__c>();

        System.runAs(FACULTY_USER) {

            for(reduivy__Study_Session__c sse : sseMap.values()){
                isnToInsert.add(REDU_TestData_UTIL.newStudentIndividualSessionEnrollment('To_test_waitlistedDate', sse.Id, ien[0].Id, sse.reduivy__Start_Date__c, enrollreqStatuses[0]));
            }
            
            REDU_SystemMode_UTIL.doInsert(isnToInsert);
            expectedDate = System.now().date();
        }

        //get isn Id
        List<Id> isnIds = new List<Id>();
        for(reduivy__Individual_Session_Enrollment__c isn : isnToInsert){
            isnIds.add(isn.Id);
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnIds
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areEqual(expectedDate, isn.reduivy__Waitlist_Date__c.date(), 'Waitlist date should be today\'s date.');
        }

        Test.stopTest();
    }


    /**
     * @description Test as student to check the waitlist date when updated individual session enrollment's enrollment status to 'Waitlisted' status (BeforeUpdate)
     */
    @IsTest
    static void testUpdateIsnToWaitlistedAsStudent() {
        Test.startTest();

        User studentUser = testFactory.getStudentUser();
        DateTime presetDateTime = Datetime.newInstance(2000, 2, 20);
        Date expectedDate;
        reduivy__RIO_Education_Ivy_Settings__c cs = reduivy__RIO_Education_Ivy_Settings__c.getOrgDefaults();

        //get Waitlisted and Enrollment Requested statuses
        List<String> waitlistedStatuses = ISN_Helper.getWaitlistedStatuses();
        List<String> enrollreqStatuses = ISN_Helper.getEnrollmentRequestedStatuses();

        Set<String> statusesToPopulateDate = new Set<String>();
        statusesToPopulateDate.addAll(waitlistedStatuses);
        statusesToPopulateDate.addAll(enrollreqStatuses);

        //get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :statusesToPopulateDate
            AND reduivy__Waitlist_Date__c = NULL
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ]);
        
        System.Assert.areEqual(false, isnMap.isEmpty(), 'Individual session enrollment record no found.');
    
        Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = false;

        update Cs;

        System.runAs(studentUser) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = waitlistedStatuses[0];
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
            expectedDate = System.now().date();
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areEqual(expectedDate, isn.reduivy__Waitlist_Date__c.date(), 'Waitlisted date should be today\'s date.');
        }
    
        Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = true;

        update Cs;

        System.runAs(studentUser) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = waitlistedStatuses[0];
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areEqual(presetDateTime, isn.reduivy__Waitlist_Date__c, 'Waitlisted date should be presetDateTime.');
        }

        System.runAs(studentUser) {

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_OPEN_STATUS;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be removed.');
        }

        System.runAs(studentUser) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_WITHDRAWN_STATUS;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.areEqual(presetDateTime, isn.reduivy__Waitlist_Date__c, 'The waitlist date should not be updated after changed to the withdrawn status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student to check the waitlist date when updated individual session enrollment's enrollment status to 'Enrollment Requested' status (BeforeUpdate)
     */
    @IsTest
    static void testUpdateIsnToEnrollmentRequestedAsStudent() {
        Test.startTest();

        User studentUser = testFactory.getStudentUser();
        DateTime presetDateTime = Datetime.newInstance(2000, 2, 20);
        Date expectedDate;
        reduivy__RIO_Education_Ivy_Settings__c cs = reduivy__RIO_Education_Ivy_Settings__c.getOrgDefaults();


        //get Waitlisted and Enrollment Requested statuses
        List<String> waitlistedStatuses = ISN_Helper.getWaitlistedStatuses();
        List<String> enrollreqStatuses = ISN_Helper.getEnrollmentRequestedStatuses();

        Set<String> statusesToPopulateDate = new Set<String>();
        statusesToPopulateDate.addAll(waitlistedStatuses);
        statusesToPopulateDate.addAll(enrollreqStatuses);

        //get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Enrollment_Status__c NOT IN :statusesToPopulateDate
            AND reduivy__Waitlist_Date__c = NULL
            AND RecordTypeId =: ISN_Helper.getStudentRecordTypeId()
        ]);

        System.Assert.areEqual(false, isnMap.isEmpty(), 'Individual session enrollment record no found.');

        Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = false;

        update Cs;

        System.runAs(studentUser) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = enrollreqStatuses[0];
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
            expectedDate = System.now().date();
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areEqual(expectedDate, isn.reduivy__Waitlist_Date__c.date(), 'Waitlisted date should be today\'s date.');
        }

        Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = true;

        update Cs;

        System.runAs(studentUser) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = enrollreqStatuses[0];
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areEqual(presetDateTime, isn.reduivy__Waitlist_Date__c, 'Waitlisted date should be presetDateTime.');
        }

        System.runAs(studentUser) {

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_OPEN_STATUS;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.isNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be removed.');
        }

        System.runAs(studentUser) {
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Waitlist_Date__c = presetDateTime;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());

            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Enrollment_Status__c = ISN_WITHDRAWN_STATUS;
            }
            
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.Assert.areEqual(presetDateTime, isn.reduivy__Waitlist_Date__c, 'The waitlist date should not be updated after changed to the withdrawn status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student to check the waitlist date when insert individual session enrollment with 'Waitlisted' enrollment status (BeforeInsert)
     */
    @IsTest
    static void testInsertIsnToWaitlistedAsStudent() {
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //get Waitlisted and Enrollment Requested statuses
        List<String> waitlistedStatuses = ISN_Helper.getWaitlistedStatuses();
        List<String> enrollreqStatuses = ISN_Helper.getEnrollmentRequestedStatuses();

        Date expectedDate;

        Set<String> statusesToPopulateDate = new Set<String>();
        statusesToPopulateDate.addAll(waitlistedStatuses);
        statusesToPopulateDate.addAll(enrollreqStatuses);

        //get study sessions
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Start_Date__c
            FROM reduivy__Study_Session__c
        ]);

        System.Assert.areEqual(false, sseMap.isEmpty(), 'Study session record no found.');

        //get student individual enrollment
        List<reduivy__Individual_Enrollment__c> ien = [
            SELECT Id 
            FROM reduivy__Individual_Enrollment__c 
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            LIMIT 1
        ];

        List<reduivy__Individual_Session_Enrollment__c> isnToInsert = new List<reduivy__Individual_Session_Enrollment__c>();

        System.runAs(studentUser) {

            for(reduivy__Study_Session__c sse : sseMap.values()){
                isnToInsert.add(REDU_TestData_UTIL.newStudentIndividualSessionEnrollment('To_test_waitlistedDate', sse.Id, ien[0].Id, sse.reduivy__Start_Date__c, waitlistedStatuses[0]));
            }
            
            REDU_SystemMode_UTIL.doInsert(isnToInsert);
            expectedDate = System.now().date();
        }

        //get isn Id
        List<Id> isnIds = new List<Id>();
        for(reduivy__Individual_Session_Enrollment__c isn : isnToInsert){
            isnIds.add(isn.Id);
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnIds
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areEqual(expectedDate, isn.reduivy__Waitlist_Date__c.date(), 'Waitlist date should be today\'s date.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student to check the waitlist date when insert individual session enrollment with 'Enrollment Requested' enrollment status (BeforeInsert)
     */
    @IsTest
    static void testInsertIsnToEnrollmentRequestedAsStudent() {
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //get Waitlisted and Enrollment Requested statuses
        List<String> waitlistedStatuses = ISN_Helper.getWaitlistedStatuses();
        List<String> enrollreqStatuses = ISN_Helper.getEnrollmentRequestedStatuses();

        Date expectedDate;

        Set<String> statusesToPopulateDate = new Set<String>();
        statusesToPopulateDate.addAll(waitlistedStatuses);
        statusesToPopulateDate.addAll(enrollreqStatuses);

        //get study sessions
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([
            SELECT Id, reduivy__Start_Date__c
            FROM reduivy__Study_Session__c
        ]);

        System.Assert.areEqual(false, sseMap.isEmpty(), 'Study session record no found.');

        //get student individual enrollment
        List<reduivy__Individual_Enrollment__c> ien = [
            SELECT Id 
            FROM reduivy__Individual_Enrollment__c 
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            LIMIT 1
        ];

        List<reduivy__Individual_Session_Enrollment__c> isnToInsert = new List<reduivy__Individual_Session_Enrollment__c>();

        System.runAs(studentUser) {

            for(reduivy__Study_Session__c sse : sseMap.values()){
                isnToInsert.add(REDU_TestData_UTIL.newStudentIndividualSessionEnrollment('To_test_waitlistedDate', sse.Id, ien[0].Id, sse.reduivy__Start_Date__c, enrollreqStatuses[0]));
            }
            
            REDU_SystemMode_UTIL.doInsert(isnToInsert);
            expectedDate = System.now().date();
        }

        //get isn Id
        List<Id> isnIds = new List<Id>();
        for(reduivy__Individual_Session_Enrollment__c isn : isnToInsert){
            isnIds.add(isn.Id);
        }

        //verify result
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnIds
        ]){
            System.Assert.isNotNull(isn.reduivy__Waitlist_Date__c, 'Waitlist date should be populated.');
            System.Assert.areEqual(expectedDate, isn.reduivy__Waitlist_Date__c.date(), 'Waitlist date should be today\'s date.');
        }

        Test.stopTest();
    }


}