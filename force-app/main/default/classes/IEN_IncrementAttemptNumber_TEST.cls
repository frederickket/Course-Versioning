/**
 * @author      WDCi (dblack)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for IEN_IncrementAttemptNumber_EXE
 * @changehistory
 * ISS-001832 20-12-2023 dblack - new class
 * ISS-001982 03-07-2024 Sueanne - update test for check attempt number is 1 when enroll first time
 * ISS-002448 07-05-2025 XiRouh - Updated to cover scenario where to use custom metadata to determine which statuses should increase attempt number
 * ISS-002743 15-12-2025 XiRouh - Added test methods to consider the IEN within the same Individual Academic Profile context and Updated test methods that create IENs to link them with IPF
 */
@isTest
public inherited sharing class IEN_IncrementAttemptNumber_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String IEN_COMPLETED_STATUS = IEN_Helper.getCompletedStatuses().get(0);
    static final String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
    static final String IEN_WITHDRAWN_STATUS = IEN_Helper.getWithdrawnStatuses().get(0);

    static final Integer IEN_QTY = 2;

    static final Id IEN_STUDENT_RTID = IEN_Helper.getStudentRecordTypeId();

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData() {

        // Create settings
        testFactory.setupDefaultSettings();

        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {

            Test.startTest();

			testFactory.initMasterData(SUN_Helper.getApiName());
			testFactory.initOfferingData(SOF_Helper.getApiName());
			testFactory.initStudentData(IPR_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test as an admin user the individual enrollment attempt number will not consider the withdrawn ien
     */
    @isTest
    static void testRetainAttemptNumberAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        // Set up test data
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get study unit and study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT :IEN_QTY
        ];

        System.Assert.isFalse(
            sunList.isEmpty(),
            'The list should contain study unit records'
        );

        for (reduivy__Study_Unit__c sun : sunList) {

            System.Assert.isFalse(
                sun.reduivy__Study_Offerings__r.isEmpty(),
                'The list should contain study offering records'
            );

            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        // Create new withdrawn individual enrollment records
        List<reduivy__Individual_Enrollment__c> withdrawnIenNewList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Unit__c sun : sunList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sofMap.get(sun.Id);
            String enrollmentStatus = IEN_WITHDRAWN_STATUS;
            Decimal attemptNumber = null;
            Date enrollmentDate = null;
            Date startDate = null;
            Date endDate = null;
            Date censusDate = null;
            Decimal creditsOffered = null;
            Id idvAcademicProgressId = null;
            Id idvAcademicProfileId = studentIpfs[0].Id;

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                sampleRecordCode,
                contactId,
                studyOfferingId,
                enrollmentStatus,
                attemptNumber,
                enrollmentDate,
                startDate,
                endDate,
                censusDate,
                creditsOffered,
                idvAcademicProgressId,
                idvAcademicProfileId,
                true
            );

            withdrawnIenNewList.add(ien);
        }

		System.runAs(ADMIN_USER) {
            Test.startTest();
            // Execute test
            insert withdrawnIenNewList;
		}

        // Verify test result
        Set<Id> withdrawnIenNewIdSet = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : withdrawnIenNewList) {
            withdrawnIenNewIdSet.add(ien.Id);
        }

        List<reduivy__Individual_Enrollment__c> withdrawnIenList = [
            SELECT reduivy__Contact__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :withdrawnIenNewIdSet
        ];

        System.Assert.isFalse(
            withdrawnIenList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ienNew : withdrawnIenList) {

            Decimal expectedAttemptNumber = 1;

            System.Assert.areEqual(
                expectedAttemptNumber,
                ienNew.reduivy__Attempt_Number__c,
                'The individual enrollment attempt number should have attempt number as expected'
            );
        }

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Unit__c sun : sunList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sofMap.get(sun.Id);
            String enrollmentStatus = IEN_INPROGRESS_STATUS;
            Decimal attemptNumber = null;
            Date enrollmentDate = null;
            Date startDate = null;
            Date endDate = null;
            Date censusDate = null;
            Decimal creditsOffered = null;
            Id idvAcademicProgressId = null;
            Id idvAcademicProfileId = studentIpfs[0].Id;

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                sampleRecordCode,
                contactId,
                studyOfferingId,
                enrollmentStatus,
                attemptNumber,
                enrollmentDate,
                startDate,
                endDate,
                censusDate,
                creditsOffered,
                idvAcademicProgressId,
                idvAcademicProfileId,
                true
            );

            ienList.add(ien);
        }

        insert ienList;
        List<reduivy__Individual_Enrollment__c> ienAttemptedList = [
            SELECT reduivy__Contact__c, reduivy__Study_Offering__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            ORDER BY reduivy__Attempt_Number__c DESC
        ];

        System.Assert.isFalse(
            ienAttemptedList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        // Create map of already attempted numbers
        Map<Id, Map<Id, Decimal>> ienAttemptedMap = new Map<Id, Map<Id, Decimal>>();
        for (reduivy__Individual_Enrollment__c ienAttempted : ienAttemptedList) {
            if (!ienAttemptedMap.containsKey(ienAttempted.reduivy__Contact__c)) {
                ienAttemptedMap.put(ienAttempted.reduivy__Contact__c, new Map<Id, Decimal>());
            }
            ienAttemptedMap.get(ienAttempted.reduivy__Contact__c).put(ienAttempted.reduivy__Target_Unit_Id__c, ienAttempted.reduivy__Attempt_Number__c);
            continue;
        }

        // Create new individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienNewList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Individual_Enrollment__c ienAttempted : ienAttemptedList) {

            System.Assert.areEqual(
                ienAttemptedMap.get(ienAttempted.reduivy__Contact__c).get(ienAttempted.reduivy__Target_Unit_Id__c), 
                ienAttempted.reduivy__Attempt_Number__c,
                'The individual enrollment attempted number should be as expected'
            );

            reduivy__Individual_Enrollment__c ienNew = ienAttempted.clone(false, true, false, false);
            ienNew.reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS;
            ienNew.reduivy__Attempt_Number__c = null;
            ienNew.RecordTypeId = IEN_STUDENT_RTID;
            ienNew.reduivy__Individual_Academic_Profile__c = studentIpfs[0].Id;

            ienNewList.add(ienNew);
        }

		System.runAs(ADMIN_USER) {

            // Execute test
            insert ienNewList;
		}

        // Verify test result
        Set<Id> ienNewIdSet = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : ienNewList) {
            ienNewIdSet.add(ien.Id);
        }
        ienNewList = [
            SELECT reduivy__Contact__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienNewIdSet
        ];

        System.Assert.isFalse(
            ienNewList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ienNew : ienNewList) {

            Decimal expectedAttemptNumber = 2;

            System.Assert.areEqual(
                expectedAttemptNumber,
                ienNew.reduivy__Attempt_Number__c,
                'The individual enrollment attempt number should have incremented as expected'
            );
        }

        //Create another set of new in-progress individual enrollment records so that we can check whether it increments from the in-progress records or the withdrawn records
        List<reduivy__Individual_Enrollment__c> thirdIenNewList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Individual_Enrollment__c ienAttempted : ienAttemptedList) {

            reduivy__Individual_Enrollment__c ienNew = ienAttempted.clone(false, true, false, false);
            ienNew.reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS;
            ienNew.reduivy__Attempt_Number__c = null;
            ienNew.RecordTypeId = IEN_STUDENT_RTID;
            ienNew.reduivy__Individual_Academic_Profile__c = studentIpfs[0].Id;

            thirdIenNewList.add(ienNew);
        }

		System.runAs(ADMIN_USER) {

            // Execute test
            insert thirdIenNewList;
            Test.stopTest();		
		}

        // Verify test result
        Set<Id> thirdIenNewIdSet = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : thirdIenNewList) {
            thirdIenNewIdSet.add(ien.Id);
        }

        List<reduivy__Individual_Enrollment__c> thirdIenList = [
            SELECT reduivy__Contact__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :thirdIenNewIdSet
        ];

        System.Assert.isFalse(
            withdrawnIenList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ienNew : thirdIenList) {

            Decimal expectedAttemptNumber = 3;

            System.Assert.areEqual(
                expectedAttemptNumber,
                ienNew.reduivy__Attempt_Number__c,
                'The individual enrollment attempt number should have attempt number as expected'
            );
        }
    }

    /**
     * @description Test as an admin user the individual enrollment attempt number is incremented when inserted
     */
    @isTest
    static void testIncrementAttemptNumberAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        // Set up test data
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get study unit and study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT :IEN_QTY
        ];

        System.Assert.isFalse(
            sunList.isEmpty(),
            'The list should contain study unit records'
        );

        for (reduivy__Study_Unit__c sun : sunList) {

            System.Assert.isFalse(
                sun.reduivy__Study_Offerings__r.isEmpty(),
                'The list should contain study offering records'
            );

            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Unit__c sun : sunList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sofMap.get(sun.Id);
            String enrollmentStatus = IEN_INPROGRESS_STATUS;
            Decimal attemptNumber = null;
            Date enrollmentDate = null;
            Date startDate = null;
            Date endDate = null;
            Date censusDate = null;
            Decimal creditsOffered = null;
            Id idvAcademicProgressId = null;
            Id idvAcademicProfileId = studentIpfs[0].Id;

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                sampleRecordCode,
                contactId,
                studyOfferingId,
                enrollmentStatus,
                attemptNumber,
                enrollmentDate,
                startDate,
                endDate,
                censusDate,
                creditsOffered,
                idvAcademicProgressId,
                idvAcademicProfileId,
                true
            );

            ienList.add(ien);
        }
        insert ienList;
        
        List<reduivy__Individual_Enrollment__c> ienAttemptedList = [
            SELECT reduivy__Contact__c, reduivy__Study_Offering__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            ORDER BY reduivy__Attempt_Number__c DESC
        ];

        System.Assert.isFalse(
            ienAttemptedList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        //Update the status to completed
        for (reduivy__Individual_Enrollment__c ien : ienAttemptedList) {
            ien.reduivy__Enrollment_Status__c = IEN_COMPLETED_STATUS;
        }

        update ienAttemptedList;

        // Create map of already attempted numbers
        Map<Id, Map<Id, Decimal>> ienAttemptedMap = new Map<Id, Map<Id, Decimal>>();
        for (reduivy__Individual_Enrollment__c ienAttempted : ienAttemptedList) {
            if (!ienAttemptedMap.containsKey(ienAttempted.reduivy__Contact__c)) {
                ienAttemptedMap.put(ienAttempted.reduivy__Contact__c, new Map<Id, Decimal>());
            }
            ienAttemptedMap.get(ienAttempted.reduivy__Contact__c).put(ienAttempted.reduivy__Target_Unit_Id__c, ienAttempted.reduivy__Attempt_Number__c);
            continue;
        }

        // Create new individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienNewList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Individual_Enrollment__c ienAttempted : ienAttemptedList) {

            System.Assert.areEqual(
                ienAttemptedMap.get(ienAttempted.reduivy__Contact__c).get(ienAttempted.reduivy__Target_Unit_Id__c), 
                ienAttempted.reduivy__Attempt_Number__c,
                'The individual enrollment attempted number should be as expected'
            );

            reduivy__Individual_Enrollment__c ienNew = ienAttempted.clone(false, true, false, false);
            ienNew.reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS;
            ienNew.reduivy__Attempt_Number__c = null;
            ienNew.RecordTypeId = IEN_STUDENT_RTID;
            ienNew.reduivy__Individual_Academic_Profile__c = studentIpfs[0].Id;

            ienNewList.add(ienNew);
        }

		System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            insert ienNewList;
            Test.stopTest();		
		}

        // Verify test result
        Set<Id> ienNewIdSet = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : ienNewList) {
            ienNewIdSet.add(ien.Id);
        }
        ienNewList = [
            SELECT reduivy__Contact__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienNewIdSet
        ];

        System.Assert.isFalse(
            ienNewList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ienNew : ienNewList) {

            Decimal expectedAttemptNumber = (ienAttemptedMap.get(ienNew.reduivy__Contact__c).get(ienNew.reduivy__Target_Unit_Id__c)) + 1;

            System.Assert.areEqual(
                expectedAttemptNumber,
                ienNew.reduivy__Attempt_Number__c,
                'The individual enrollment attempt number should have incremented as expected'
            );
        }
    }

    /**
     * @description Test as an admin user the individual enrollment attempt number when first insert
     */
    @isTest
    static void testFirstInsertIenAttemptNumberAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        // Set up test data
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get study unit and study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT :IEN_QTY
        ];

        System.Assert.isFalse(
            sunList.isEmpty(),
            'The list should contain study unit records'
        );

        for (reduivy__Study_Unit__c sun : sunList) {

            System.Assert.isFalse(
                sun.reduivy__Study_Offerings__r.isEmpty(),
                'The list should contain study offering records'
            );

            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Unit__c sun : sunList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sofMap.get(sun.Id);
            String enrollmentStatus = IEN_INPROGRESS_STATUS;
            Decimal attemptNumber = null;
            Date enrollmentDate = null;
            Date startDate = null;
            Date endDate = null;
            Date censusDate = null;
            Decimal creditsOffered = null;
            Id idvAcademicProgressId = null;
            Id idvAcademicProfileId = studentIpfs[0].Id;

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                sampleRecordCode,
                contactId,
                studyOfferingId,
                enrollmentStatus,
                attemptNumber,
                enrollmentDate,
                startDate,
                endDate,
                censusDate,
                creditsOffered,
                idvAcademicProgressId,
                idvAcademicProfileId,
                true
            );

            ienList.add(ien);
        }

		System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            insert ienList;
            Test.stopTest();		
		}

        // Verify test result
        Set<Id> ienNewIdSet = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : ienList) {
            ienNewIdSet.add(ien.Id);
        }

        List<reduivy__Individual_Enrollment__c> ienNewList = [
            SELECT reduivy__Contact__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienNewIdSet
        ];

        System.Assert.isFalse(
            ienNewList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ienNew : ienNewList) {

            Decimal expectedAttemptNumber = 1;

            System.Assert.areEqual(
                expectedAttemptNumber,
                ienNew.reduivy__Attempt_Number__c,
                'The individual enrollment attempt number should have incremented as expected'
            );
        }
    }

    /**
     * @description Test as a faculty user the individual enrollment attempt number will not consider the withdrawn ien
     */
    @isTest
    static void testRetainAttemptNumberAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        // Set up test data
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get study unit and study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT :IEN_QTY
        ];

        System.Assert.isFalse(
            sunList.isEmpty(),
            'The list should contain study unit records'
        );

        for (reduivy__Study_Unit__c sun : sunList) {

            System.Assert.isFalse(
                sun.reduivy__Study_Offerings__r.isEmpty(),
                'The list should contain study offering records'
            );

            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        // Create new withdrawn individual enrollment records
        List<reduivy__Individual_Enrollment__c> withdrawnIenNewList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Unit__c sun : sunList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sofMap.get(sun.Id);
            String enrollmentStatus = IEN_WITHDRAWN_STATUS;
            Decimal attemptNumber = null;
            Date enrollmentDate = null;
            Date startDate = null;
            Date endDate = null;
            Date censusDate = null;
            Decimal creditsOffered = null;
            Id idvAcademicProgressId = null;
            Id idvAcademicProfileId = studentIpfs[0].Id;

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                sampleRecordCode,
                contactId,
                studyOfferingId,
                enrollmentStatus,
                attemptNumber,
                enrollmentDate,
                startDate,
                endDate,
                censusDate,
                creditsOffered,
                idvAcademicProgressId,
                idvAcademicProfileId,
                true
            );

            withdrawnIenNewList.add(ien);
        }

		System.runAs(FACULTY_USER) {
            Test.startTest();
            // Execute test
            insert withdrawnIenNewList;
		}

        // Verify test result
        Set<Id> withdrawnIenNewIdSet = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : withdrawnIenNewList) {
            withdrawnIenNewIdSet.add(ien.Id);
        }

        List<reduivy__Individual_Enrollment__c> withdrawnIenList = [
            SELECT reduivy__Contact__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :withdrawnIenNewIdSet
        ];

        System.Assert.isFalse(
            withdrawnIenList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ienNew : withdrawnIenList) {

            Decimal expectedAttemptNumber = 1;

            System.Assert.areEqual(
                expectedAttemptNumber,
                ienNew.reduivy__Attempt_Number__c,
                'The individual enrollment attempt number should have attempt number as expected'
            );
        }

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Unit__c sun : sunList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sofMap.get(sun.Id);
            String enrollmentStatus = IEN_INPROGRESS_STATUS;
            Decimal attemptNumber = null;
            Date enrollmentDate = null;
            Date startDate = null;
            Date endDate = null;
            Date censusDate = null;
            Decimal creditsOffered = null;
            Id idvAcademicProgressId = null;
            Id idvAcademicProfileId = studentIpfs[0].Id;

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                sampleRecordCode,
                contactId,
                studyOfferingId,
                enrollmentStatus,
                attemptNumber,
                enrollmentDate,
                startDate,
                endDate,
                censusDate,
                creditsOffered,
                idvAcademicProgressId,
                idvAcademicProfileId,
                true
            );

            ienList.add(ien);
        }
        insert ienList;

        List<reduivy__Individual_Enrollment__c> ienAttemptedList = [
            SELECT reduivy__Contact__c, reduivy__Study_Offering__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            ORDER BY reduivy__Attempt_Number__c DESC
        ];

        System.Assert.isFalse(
            ienAttemptedList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        // Create map of already attempted numbers
        Map<Id, Map<Id, Decimal>> ienAttemptedMap = new Map<Id, Map<Id, Decimal>>();
        for (reduivy__Individual_Enrollment__c ienAttempted : ienAttemptedList) {
            if (!ienAttemptedMap.containsKey(ienAttempted.reduivy__Contact__c)) {
                ienAttemptedMap.put(ienAttempted.reduivy__Contact__c, new Map<Id, Decimal>());
            }
            ienAttemptedMap.get(ienAttempted.reduivy__Contact__c).put(ienAttempted.reduivy__Target_Unit_Id__c, ienAttempted.reduivy__Attempt_Number__c);
            continue;
        }

        // Create new individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienNewList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Individual_Enrollment__c ienAttempted : ienAttemptedList) {

            System.Assert.areEqual(
                ienAttemptedMap.get(ienAttempted.reduivy__Contact__c).get(ienAttempted.reduivy__Target_Unit_Id__c), 
                ienAttempted.reduivy__Attempt_Number__c,
                'The individual enrollment attempted number should be as expected'
            );

            reduivy__Individual_Enrollment__c ienNew = ienAttempted.clone(false, true, false, false);
            ienNew.reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS;
            ienNew.reduivy__Attempt_Number__c = null;
            ienNew.RecordTypeId = IEN_STUDENT_RTID;
            ienNew.reduivy__Individual_Academic_Profile__c = studentIpfs[0].Id;

            ienNewList.add(ienNew);
        }
 
		System.runAs(FACULTY_USER) {

            // Execute test
            insert ienNewList;
		}

        // Verify test result
        Set<Id> ienNewIdSet = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : ienNewList) {
            ienNewIdSet.add(ien.Id);
        }
        ienNewList = [
            SELECT reduivy__Contact__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienNewIdSet
        ];

        System.Assert.isFalse(
            ienNewList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ienNew : ienNewList) {

            Decimal expectedAttemptNumber = 2;

            System.Assert.areEqual(
                expectedAttemptNumber,
                ienNew.reduivy__Attempt_Number__c,
                'The individual enrollment attempt number should have incremented as expected'
            );
        }

        //Create another set of new in-progress individual enrollment records so that we can check whether it increments from the in-progress records or the withdrawn records
        List<reduivy__Individual_Enrollment__c> thirdIenNewList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Individual_Enrollment__c ienAttempted : ienAttemptedList) {

            reduivy__Individual_Enrollment__c ienNew = ienAttempted.clone(false, true, false, false);
            ienNew.reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS;
            ienNew.reduivy__Attempt_Number__c = null;
            ienNew.RecordTypeId = IEN_STUDENT_RTID;
            ienNew.reduivy__Individual_Academic_Profile__c = studentIpfs[0].Id;

            thirdIenNewList.add(ienNew);
        }

		System.runAs(FACULTY_USER) {

            // Execute test
            insert thirdIenNewList;
            Test.stopTest();		
		}

        // Verify test result
        Set<Id> thirdIenNewIdSet = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : thirdIenNewList) {
            thirdIenNewIdSet.add(ien.Id);
        }

        List<reduivy__Individual_Enrollment__c> thirdIenList = [
            SELECT reduivy__Contact__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :thirdIenNewIdSet
        ];

        System.Assert.isFalse(
            withdrawnIenList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ienNew : thirdIenList) {

            Decimal expectedAttemptNumber = 3;

            System.Assert.areEqual(
                expectedAttemptNumber,
                ienNew.reduivy__Attempt_Number__c,
                'The individual enrollment attempt number should have attempt number as expected'
            );
        }
    }

    /**
     * @description Test as a faculty user the individual enrollment attempt number is incremented when inserted
     */
    @isTest
    static void testIncrementAttemptNumberAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        // Set up test data
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get study unit and study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT :IEN_QTY
        ];

        System.Assert.isFalse(
            sunList.isEmpty(),
            'The list should contain study unit records'
        );

        for (reduivy__Study_Unit__c sun : sunList) {

            System.Assert.isFalse(
                sun.reduivy__Study_Offerings__r.isEmpty(),
                'The list should contain study offering records'
            );

            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Unit__c sun : sunList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sofMap.get(sun.Id);
            String enrollmentStatus = IEN_INPROGRESS_STATUS;
            Decimal attemptNumber = null;
            Date enrollmentDate = null;
            Date startDate = null;
            Date endDate = null;
            Date censusDate = null;
            Decimal creditsOffered = null;
            Id idvAcademicProgressId = null;
            Id idvAcademicProfileId = studentIpfs[0].Id;

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                sampleRecordCode,
                contactId,
                studyOfferingId,
                enrollmentStatus,
                attemptNumber,
                enrollmentDate,
                startDate,
                endDate,
                censusDate,
                creditsOffered,
                idvAcademicProgressId,
                idvAcademicProfileId,
                true
            );

            ienList.add(ien);
        }
        insert ienList;
        
        List<reduivy__Individual_Enrollment__c> ienAttemptedList = [
            SELECT reduivy__Contact__c, reduivy__Study_Offering__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            ORDER BY reduivy__Attempt_Number__c DESC
        ];

        System.Assert.isFalse(
            ienAttemptedList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        //Update the status to completed
        for (reduivy__Individual_Enrollment__c ien : ienAttemptedList) {
            ien.reduivy__Enrollment_Status__c = IEN_COMPLETED_STATUS;
        }

        update ienAttemptedList;

        // Create map of already attempted numbers
        Map<Id, Map<Id, Decimal>> ienAttemptedMap = new Map<Id, Map<Id, Decimal>>();
        for (reduivy__Individual_Enrollment__c ienAttempted : ienAttemptedList) {
            if (!ienAttemptedMap.containsKey(ienAttempted.reduivy__Contact__c)) {
                ienAttemptedMap.put(ienAttempted.reduivy__Contact__c, new Map<Id, Decimal>());
            }
            ienAttemptedMap.get(ienAttempted.reduivy__Contact__c).put(ienAttempted.reduivy__Target_Unit_Id__c, ienAttempted.reduivy__Attempt_Number__c);
            continue;
        }

        // Create new individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienNewList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Individual_Enrollment__c ienAttempted : ienAttemptedList) {

            System.Assert.areEqual(
                ienAttemptedMap.get(ienAttempted.reduivy__Contact__c).get(ienAttempted.reduivy__Target_Unit_Id__c), 
                ienAttempted.reduivy__Attempt_Number__c,
                'The individual enrollment attempted number should be as expected'
            );

            reduivy__Individual_Enrollment__c ienNew = ienAttempted.clone(false, true, false, false);
            ienNew.reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS;
            ienNew.reduivy__Attempt_Number__c = null;
            ienNew.RecordTypeId = IEN_STUDENT_RTID;
            ienNew.reduivy__Individual_Academic_Profile__c = studentIpfs[0].Id;

            ienNewList.add(ienNew);
        }

		System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            insert ienNewList;
            Test.stopTest();		
		}

        // Verify test result
        Set<Id> ienNewIdSet = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : ienNewList) {
            ienNewIdSet.add(ien.Id);
        }
        ienNewList = [
            SELECT reduivy__Contact__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienNewIdSet
        ];

        System.Assert.isFalse(
            ienNewList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ienNew : ienNewList) {

            Decimal expectedAttemptNumber = (ienAttemptedMap.get(ienNew.reduivy__Contact__c).get(ienNew.reduivy__Target_Unit_Id__c)) + 1;

            System.Assert.areEqual(
                expectedAttemptNumber,
                ienNew.reduivy__Attempt_Number__c,
                'The individual enrollment attempt number should have incremented as expected'
            );
        }
    }

    /**
     * @description Test as an faculty user the individual enrollment attempt number when first insert
     */
    @isTest
    static void testFirstInsertIenAttemptNumberAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Set up test data
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get study unit and study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT :IEN_QTY
        ];

        System.Assert.isFalse(
            sunList.isEmpty(),
            'The list should contain study unit records'
        );

        for (reduivy__Study_Unit__c sun : sunList) {

            System.Assert.isFalse(
                sun.reduivy__Study_Offerings__r.isEmpty(),
                'The list should contain study offering records'
            );

            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Unit__c sun : sunList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sofMap.get(sun.Id);
            String enrollmentStatus = IEN_INPROGRESS_STATUS;
            Decimal attemptNumber = null;
            Date enrollmentDate = null;
            Date startDate = null;
            Date endDate = null;
            Date censusDate = null;
            Decimal creditsOffered = null;
            Id idvAcademicProgressId = null;
            Id idvAcademicProfileId = studentIpfs[0].Id;

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                sampleRecordCode,
                contactId,
                studyOfferingId,
                enrollmentStatus,
                attemptNumber,
                enrollmentDate,
                startDate,
                endDate,
                censusDate,
                creditsOffered,
                idvAcademicProgressId,
                idvAcademicProfileId,
                true
            );

            ienList.add(ien);
        }

		System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            insert ienList;
            Test.stopTest();		
		}

        // Verify test result
        Set<Id> ienNewIdSet = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : ienList) {
            ienNewIdSet.add(ien.Id);
        }

        List<reduivy__Individual_Enrollment__c> ienNewList = [
            SELECT reduivy__Contact__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienNewIdSet
        ];

        System.Assert.isFalse(
            ienNewList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ienNew : ienNewList) {

            Decimal expectedAttemptNumber = 1;

            System.Assert.areEqual(
                expectedAttemptNumber,
                ienNew.reduivy__Attempt_Number__c,
                'The individual enrollment attempt number should have incremented as expected'
            );
        }
    }

    /**
     * @description Test as a student user the individual enrollment attempt number is not incremented when inserted
     */
    @isTest
    static void testRetainAttemptNumberAsStudent() {

        // Set up test data
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get study unit and study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT :IEN_QTY
        ];

        System.Assert.isFalse(
            sunList.isEmpty(),
            'The list should contain study unit records'
        );

        for (reduivy__Study_Unit__c sun : sunList) {

            System.Assert.isFalse(
                sun.reduivy__Study_Offerings__r.isEmpty(),
                'The list should contain study offering records'
            );

            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        // Create new withdrawn individual enrollment records
        List<reduivy__Individual_Enrollment__c> withdrawnIenNewList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Unit__c sun : sunList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sofMap.get(sun.Id);
            String enrollmentStatus = IEN_WITHDRAWN_STATUS;
            Decimal attemptNumber = null;
            Date enrollmentDate = null;
            Date startDate = null;
            Date endDate = null;
            Date censusDate = null;
            Decimal creditsOffered = null;
            Id idvAcademicProgressId = null;
            Id idvAcademicProfileId = studentIpfs[0].Id;

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                sampleRecordCode,
                contactId,
                studyOfferingId,
                enrollmentStatus,
                attemptNumber,
                enrollmentDate,
                startDate,
                endDate,
                censusDate,
                creditsOffered,
                idvAcademicProgressId,
                idvAcademicProfileId,
                true
            );

            withdrawnIenNewList.add(ien);
        }

		System.runAs(studentUser) {
            Test.startTest();
            // Execute test
            insert withdrawnIenNewList;
		}

        // Verify test result
        Set<Id> withdrawnIenNewIdSet = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : withdrawnIenNewList) {
            withdrawnIenNewIdSet.add(ien.Id);
        }

        List<reduivy__Individual_Enrollment__c> withdrawnIenList = [
            SELECT reduivy__Contact__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :withdrawnIenNewIdSet
        ];

        System.Assert.isFalse(
            withdrawnIenList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ienNew : withdrawnIenList) {

            Decimal expectedAttemptNumber = 1;

            System.Assert.areEqual(
                expectedAttemptNumber,
                ienNew.reduivy__Attempt_Number__c,
                'The individual enrollment attempt number should have attempt number as expected'
            );
        }

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Unit__c sun : sunList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sofMap.get(sun.Id);
            String enrollmentStatus = IEN_INPROGRESS_STATUS;
            Decimal attemptNumber = null;
            Date enrollmentDate = null;
            Date startDate = null;
            Date endDate = null;
            Date censusDate = null;
            Decimal creditsOffered = null;
            Id idvAcademicProgressId = null;
            Id idvAcademicProfileId = studentIpfs[0].Id;

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                sampleRecordCode,
                contactId,
                studyOfferingId,
                enrollmentStatus,
                attemptNumber,
                enrollmentDate,
                startDate,
                endDate,
                censusDate,
                creditsOffered,
                idvAcademicProgressId,
                idvAcademicProfileId,
                true
            );

            ienList.add(ien);
        }
        insert ienList;

        // Get individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienAttemptedList = [
            SELECT reduivy__Contact__c, reduivy__Study_Offering__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN :studentContacts
            ORDER BY reduivy__Attempt_Number__c DESC
        ];

        System.Assert.isFalse(
            ienAttemptedList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        // Create map of already attempted numbers
        Map<Id, Map<Id, Decimal>> ienAttemptedMap = new Map<Id, Map<Id, Decimal>>();
        for (reduivy__Individual_Enrollment__c ienAttempted : ienAttemptedList) {
            if (!ienAttemptedMap.containsKey(ienAttempted.reduivy__Contact__c)) {
                ienAttemptedMap.put(ienAttempted.reduivy__Contact__c, new Map<Id, Decimal>());
            }
            ienAttemptedMap.get(ienAttempted.reduivy__Contact__c).put(ienAttempted.reduivy__Target_Unit_Id__c, ienAttempted.reduivy__Attempt_Number__c);
            continue;
        }

        // Create new individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienNewList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Individual_Enrollment__c ienAttempted : ienAttemptedList) {

            System.Assert.areEqual(
                ienAttemptedMap.get(ienAttempted.reduivy__Contact__c).get(ienAttempted.reduivy__Target_Unit_Id__c), 
                ienAttempted.reduivy__Attempt_Number__c,
                'The individual enrollment attempted number should be as expected'
            );

            reduivy__Individual_Enrollment__c ienNew = ienAttempted.clone(false, true, false, false);
            ienNew.reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS;
            ienNew.reduivy__Attempt_Number__c = null;
            ienNew.RecordTypeId = IEN_STUDENT_RTID;
            ienNew.reduivy__Individual_Academic_Profile__c = studentIpfs[0].Id;

            ienNewList.add(ienNew);
        }

		System.runAs(studentUser) {

            // Execute test
            insert ienNewList;
		}

        // Verify test result
        Set<Id> ienNewIdSet = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : ienNewList) {
            ienNewIdSet.add(ien.Id);
        }
        ienNewList = [
            SELECT reduivy__Contact__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienNewIdSet
        ];

        System.Assert.isFalse(
            ienNewList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ienNew : ienNewList) {

            Decimal expectedAttemptNumber = 2;

            System.Assert.areEqual(
                expectedAttemptNumber,
                ienNew.reduivy__Attempt_Number__c,
                'The individual enrollment attempt number should have incremented as expected'
            );
        }

        //Create another set of new in-progress individual enrollment records so that we can check whether it increments from the in-progress records or the withdrawn records
        List<reduivy__Individual_Enrollment__c> thirdIenNewList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Individual_Enrollment__c ienAttempted : ienAttemptedList) {

            reduivy__Individual_Enrollment__c ienNew = ienAttempted.clone(false, true, false, false);
            ienNew.reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS;
            ienNew.reduivy__Attempt_Number__c = null;
            ienNew.RecordTypeId = IEN_STUDENT_RTID;
            ienNew.reduivy__Individual_Academic_Profile__c = studentIpfs[0].Id;

            thirdIenNewList.add(ienNew);
        }

		System.runAs(studentUser) {

            // Execute test
            insert thirdIenNewList;
            Test.stopTest();		
		}

        // Verify test result
        Set<Id> thirdIenNewIdSet = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : thirdIenNewList) {
            thirdIenNewIdSet.add(ien.Id);
        }

        List<reduivy__Individual_Enrollment__c> thirdIenList = [
            SELECT reduivy__Contact__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :thirdIenNewIdSet
        ];

        System.Assert.isFalse(
            withdrawnIenList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ienNew : thirdIenList) {

            Decimal expectedAttemptNumber = 3;

            System.Assert.areEqual(
                expectedAttemptNumber,
                ienNew.reduivy__Attempt_Number__c,
                'The individual enrollment attempt number should have attempt number as expected'
            );
        }
    }

    /**
     * @description Test as a student user the individual enrollment attempt number is incremented when inserted
     */
    @isTest
    static void testIncrementAttemptNumberAsStudent() {

        // Set up test data
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get study unit and study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT :IEN_QTY
        ];

        System.Assert.isFalse(
            sunList.isEmpty(),
            'The list should contain study unit records'
        );

        for (reduivy__Study_Unit__c sun : sunList) {

            System.Assert.isFalse(
                sun.reduivy__Study_Offerings__r.isEmpty(),
                'The list should contain study offering records'
            );

            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Unit__c sun : sunList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sofMap.get(sun.Id);
            String enrollmentStatus = IEN_INPROGRESS_STATUS;
            Decimal attemptNumber = null;
            Date enrollmentDate = null;
            Date startDate = null;
            Date endDate = null;
            Date censusDate = null;
            Decimal creditsOffered = null;
            Id idvAcademicProgressId = null;
            Id idvAcademicProfileId = studentIpfs[0].Id;

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                sampleRecordCode,
                contactId,
                studyOfferingId,
                enrollmentStatus,
                attemptNumber,
                enrollmentDate,
                startDate,
                endDate,
                censusDate,
                creditsOffered,
                idvAcademicProgressId,
                idvAcademicProfileId,
                true
            );

            ienList.add(ien);
        }
        insert ienList;

        // Get individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienAttemptedList = [
            SELECT reduivy__Contact__c, reduivy__Study_Offering__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN :studentContacts
            ORDER BY reduivy__Attempt_Number__c DESC
        ];

        System.Assert.isFalse(
            ienAttemptedList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        //Update the status to completed
        for (reduivy__Individual_Enrollment__c ien : ienAttemptedList) {
            ien.reduivy__Enrollment_Status__c = IEN_COMPLETED_STATUS;
        }

        update ienAttemptedList;

        // Create map of already attempted numbers
        Map<Id, Map<Id, Decimal>> ienAttemptedMap = new Map<Id, Map<Id, Decimal>>();
        for (reduivy__Individual_Enrollment__c ienAttempted : ienAttemptedList) {
            if (!ienAttemptedMap.containsKey(ienAttempted.reduivy__Contact__c)) {
                ienAttemptedMap.put(ienAttempted.reduivy__Contact__c, new Map<Id, Decimal>());
            }
            ienAttemptedMap.get(ienAttempted.reduivy__Contact__c).put(ienAttempted.reduivy__Target_Unit_Id__c, ienAttempted.reduivy__Attempt_Number__c);
            continue;
        }

        // Create new individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienNewList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Individual_Enrollment__c ienAttempted : ienAttemptedList) {

            System.Assert.areEqual(
                ienAttemptedMap.get(ienAttempted.reduivy__Contact__c).get(ienAttempted.reduivy__Target_Unit_Id__c), 
                ienAttempted.reduivy__Attempt_Number__c,
                'The individual enrollment attempted number should be as expected'
            );

            reduivy__Individual_Enrollment__c ienNew = ienAttempted.clone(false, true, false, false);
            ienNew.reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS;
            ienNew.reduivy__Attempt_Number__c = null;
            ienNew.RecordTypeId = IEN_STUDENT_RTID;
            ienNew.reduivy__Individual_Academic_Profile__c = studentIpfs[0].Id;

            ienNewList.add(ienNew);
        }

		System.runAs(studentUser) {

            // Execute test
            Test.startTest();
            insert ienNewList;
            Test.stopTest();	
		}

        // Verify test result
        Set<Id> ienNewIdSet = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : ienNewList) {
            ienNewIdSet.add(ien.Id);
        }
        ienNewList = [
            SELECT reduivy__Contact__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienNewIdSet
        ];

        System.Assert.isFalse(
            ienNewList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ienNew : ienNewList) {

            Decimal expectedAttemptNumber = (ienAttemptedMap.get(ienNew.reduivy__Contact__c).get(ienNew.reduivy__Target_Unit_Id__c)) + 1;

            System.Assert.areEqual(
                expectedAttemptNumber,
                ienNew.reduivy__Attempt_Number__c,
                'The individual enrollment attempt number should have incremented as expected'
            );
        }
    }

    /**
     * @description Test as an student user the individual enrollment attempt number when first insert
     */
    @isTest
    static void testFirstInsertIenAttemptNumberAsStudent() {

        // Set up test data
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get study unit and study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT :IEN_QTY
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        System.Assert.isFalse(
            sunList.isEmpty(),
            'The list should contain study unit records'
        );

        for (reduivy__Study_Unit__c sun : sunList) {

            System.Assert.isFalse(
                sun.reduivy__Study_Offerings__r.isEmpty(),
                'The list should contain study offering records'
            );

            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Unit__c sun : sunList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sofMap.get(sun.Id);
            String enrollmentStatus = IEN_INPROGRESS_STATUS;
            Decimal attemptNumber = null;
            Date enrollmentDate = null;
            Date startDate = null;
            Date endDate = null;
            Date censusDate = null;
            Decimal creditsOffered = null;
            Id idvAcademicProgressId = null;
            Id idvAcademicProfileId = studentIpfs[0].Id;

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                sampleRecordCode,
                contactId,
                studyOfferingId,
                enrollmentStatus,
                attemptNumber,
                enrollmentDate,
                startDate,
                endDate,
                censusDate,
                creditsOffered,
                idvAcademicProgressId,
                idvAcademicProfileId,
                true
            );

            ienList.add(ien);
        }

		System.runAs(studentUser) {

            // Execute test
            Test.startTest();
            insert ienList;
            Test.stopTest();		
		}

        // Verify test result
        Set<Id> ienNewIdSet = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : ienList) {
            ienNewIdSet.add(ien.Id);
        }

        List<reduivy__Individual_Enrollment__c> ienNewList = [
            SELECT reduivy__Contact__c, reduivy__Target_Unit_Id__c, reduivy__Attempt_Number__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienNewIdSet
        ];

        System.Assert.isFalse(
            ienNewList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ienNew : ienNewList) {

            Decimal expectedAttemptNumber = 1;

            System.Assert.areEqual(
                expectedAttemptNumber,
                ienNew.reduivy__Attempt_Number__c,
                'The individual enrollment attempt number should have incremented as expected'
            );
        }
    }

    /**
     * @description Test that attempt numbers are tracked separately within each IPF as admin
     */
    @isTest
    static void testAttemptNumberWithinSameIpfAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        // Set up test data
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get study unit and study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT 1
        ];

        System.Assert.isFalse(
            sunList.isEmpty(),
            'The list should contain study unit records'
        );

        for (reduivy__Study_Unit__c sun : sunList) {
            System.Assert.isFalse(
                sun.reduivy__Study_Offerings__r.isEmpty(),
                'The list should contain study offering records'
            );
            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        // Create two IPFs for the same student
        List<reduivy__Individual_Academic_Profile__c> studentIpfs = new List<reduivy__Individual_Academic_Profile__c>();
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 1',
            reduivy__Primary__c = true
        ));
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 2',
            reduivy__Primary__c = false
        ));
        insert studentIpfs;

        Test.startTest();

        System.runAs(ADMIN_USER) {
            // Create first IEN in IPF 1
            reduivy__Individual_Enrollment__c ien1Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_COMPLETED_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert ien1Ipf1;

            // Verify first attempt in IPF 1
            ien1Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien1Ipf1.Id];
            System.Assert.areEqual(1, ien1Ipf1.reduivy__Attempt_Number__c, 
                'First IEN in IPF 1 should have attempt number 1');

            // Create first IEN in IPF 2 for same unit
            reduivy__Individual_Enrollment__c ien1Ipf2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_COMPLETED_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[1].Id,
                true
            );
            insert ien1Ipf2;

            // Verify first attempt in IPF 2 starts at 1 (not affected by IPF 1)
            ien1Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien1Ipf2.Id];
            System.Assert.areEqual(1, ien1Ipf2.reduivy__Attempt_Number__c, 
                'First IEN in IPF 2 should have attempt number 1, independent of IPF 1');

            // Create second IEN in IPF 1
            reduivy__Individual_Enrollment__c ien2Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert ien2Ipf1;

            // Verify second attempt in IPF 1 increments to 2
            ien2Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien2Ipf1.Id];
            System.Assert.areEqual(2, ien2Ipf1.reduivy__Attempt_Number__c, 
                'Second IEN in IPF 1 should have attempt number 2');

            // Create second IEN in IPF 2
            reduivy__Individual_Enrollment__c ien2Ipf2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[1].Id,
                true
            );
            insert ien2Ipf2;

            // Verify second attempt in IPF 2 increments to 2 (independent of IPF 1)
            ien2Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien2Ipf2.Id];
            System.Assert.areEqual(2, ien2Ipf2.reduivy__Attempt_Number__c, 
                'Second IEN in IPF 2 should have attempt number 2, independent of IPF 1');

            // Create third IEN in IPF 1
            reduivy__Individual_Enrollment__c ien3Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert ien3Ipf1;

            // Verify third attempt in IPF 1
            ien3Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien3Ipf1.Id];
            System.Assert.areEqual(3, ien3Ipf1.reduivy__Attempt_Number__c, 
                'Third IEN in IPF 1 should have attempt number 3');

            // Verify IPF 2 still has only 2 attempts
            List<reduivy__Individual_Enrollment__c> ipf2Iens = [SELECT reduivy__Attempt_Number__c 
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c = :studentUser.ContactId
                AND reduivy__Target_Unit_Id__c = :sunList[0].Id
                AND reduivy__Individual_Academic_Profile__c = :studentIpfs[1].Id
                ORDER BY reduivy__Attempt_Number__c DESC
            ];
            System.Assert.areEqual(2, ipf2Iens.size(), 'IPF 2 should have 2 attempts');
            System.Assert.areEqual(2, ipf2Iens[0].reduivy__Attempt_Number__c, 
                'Latest attempt in IPF 2 should still be 2');
        }

        Test.stopTest();
    }

    /**
     * @description Test that high attempt numbers in one IPF don't affect another IPF as admin
     */
    @isTest
    static void testIpfIsolationForAttemptNumberAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT 1
        ];

        for (reduivy__Study_Unit__c sun : sunList) {
            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        // Create two IPFs
        List<reduivy__Individual_Academic_Profile__c> studentIpfs = new List<reduivy__Individual_Academic_Profile__c>();
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 1'
        ));
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 2'
        ));
        insert studentIpfs;

        Test.startTest();

        System.runAs(ADMIN_USER) {
            // Create 5 attempts in IPF 1
            List<reduivy__Individual_Enrollment__c> ipf1Iens = new List<reduivy__Individual_Enrollment__c>();
            for (Integer i = 0; i < 5; i++) {
                ipf1Iens.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    null,
                    studentUser.ContactId,
                    sofMap.get(sunList[0].Id),
                    IEN_COMPLETED_STATUS,
                    i + 1,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    studentIpfs[0].Id,
                    true
                ));
            }
            insert ipf1Iens;

            // Verify IPF 1 has attempts 1-5
            ipf1Iens = [SELECT reduivy__Attempt_Number__c 
                FROM reduivy__Individual_Enrollment__c 
                WHERE Id IN :ipf1Iens 
                ORDER BY reduivy__Attempt_Number__c
            ];
            for (Integer i = 0; i < ipf1Iens.size(); i++) {
                System.Assert.areEqual(i + 1, ipf1Iens[i].reduivy__Attempt_Number__c, 
                    'IPF 1 attempt ' + (i + 1) + ' should be correct');
            }

            // Now create first IEN in IPF 2 - should start at 1, not 6
            reduivy__Individual_Enrollment__c ien1Ipf2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[1].Id,
                true
            );
            insert ien1Ipf2;

            ien1Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien1Ipf2.Id];
            System.Assert.areEqual(1, ien1Ipf2.reduivy__Attempt_Number__c, 
                'First IEN in IPF 2 should be attempt 1, not affected by 5 attempts in IPF 1');
        }

        Test.stopTest();
    }

    /**
     * @description Test attempt number with withdrawn status across different IPFs as admin
     */
    @isTest
    static void testRetainAttemptNumberAcrossIpfsAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT 1
        ];

        for (reduivy__Study_Unit__c sun : sunList) {
            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        // Create two IPFs
        List<reduivy__Individual_Academic_Profile__c> studentIpfs = new List<reduivy__Individual_Academic_Profile__c>();
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 1'
        ));
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 2'
        ));
        insert studentIpfs;

        Test.startTest();

        System.runAs(ADMIN_USER) {
            // IPF 1: Create withdrawn IEN (attempt 1)
            reduivy__Individual_Enrollment__c withdrawn1Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_WITHDRAWN_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert withdrawn1Ipf1;

            withdrawn1Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :withdrawn1Ipf1.Id];
            System.Assert.areEqual(1, withdrawn1Ipf1.reduivy__Attempt_Number__c, 
                'Withdrawn IEN in IPF 1 should be attempt 1');

            // IPF 1: Create in-progress IEN (should be attempt 1, retained)
            reduivy__Individual_Enrollment__c inprogress1Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert inprogress1Ipf1;

            inprogress1Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :inprogress1Ipf1.Id];
            System.Assert.areEqual(1, inprogress1Ipf1.reduivy__Attempt_Number__c, 
                'In-progress IEN in IPF 1 should retain attempt 1 (withdrawn doesn\'t increment)');

            // IPF 2: Create withdrawn IEN (attempt 1)
            reduivy__Individual_Enrollment__c withdrawn1Ipf2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_WITHDRAWN_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[1].Id,
                true
            );
            insert withdrawn1Ipf2;

            withdrawn1Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :withdrawn1Ipf2.Id];
            System.Assert.areEqual(1, withdrawn1Ipf2.reduivy__Attempt_Number__c, 
                'Withdrawn IEN in IPF 2 should be attempt 1');

            // IPF 2: Create in-progress IEN (should be attempt 1, retained)
            reduivy__Individual_Enrollment__c inprogress1Ipf2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[1].Id,
                true
            );
            insert inprogress1Ipf2;

            inprogress1Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :inprogress1Ipf2.Id];
            System.Assert.areEqual(1, inprogress1Ipf2.reduivy__Attempt_Number__c, 
                'In-progress IEN in IPF 2 should retain attempt 1 (independent of IPF 1)');

            // Update IPF 1 in-progress to completed
            inprogress1Ipf1.reduivy__Enrollment_Status__c = IEN_COMPLETED_STATUS;
            update inprogress1Ipf1;

            // IPF 1: Create another IEN (should be attempt 2)
            reduivy__Individual_Enrollment__c ien2Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert ien2Ipf1;

            ien2Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien2Ipf1.Id];
            System.Assert.areEqual(2, ien2Ipf1.reduivy__Attempt_Number__c, 
                'New IEN in IPF 1 should be attempt 2 after completed status');

            // Verify IPF 2 still has attempt 1
            inprogress1Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :inprogress1Ipf2.Id];
            System.Assert.areEqual(1, inprogress1Ipf2.reduivy__Attempt_Number__c, 
                'IPF 2 should still have attempt 1, unaffected by IPF 1');
        }

        Test.stopTest();
    }

    /**
     * @description Test that attempt numbers are tracked separately within each IPF as faculty
     */
    @isTest
    static void testAttemptNumberWithinSameIpfAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        // Set up test data
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get study unit and study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT 1
        ];

        System.Assert.isFalse(
            sunList.isEmpty(),
            'The list should contain study unit records'
        );

        for (reduivy__Study_Unit__c sun : sunList) {
            System.Assert.isFalse(
                sun.reduivy__Study_Offerings__r.isEmpty(),
                'The list should contain study offering records'
            );
            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        // Create two IPFs for the same student
        List<reduivy__Individual_Academic_Profile__c> studentIpfs = new List<reduivy__Individual_Academic_Profile__c>();
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 1',
            reduivy__Primary__c = true
        ));
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 2',
            reduivy__Primary__c = false
        ));
        insert studentIpfs;

        Test.startTest();

        System.runAs(FACULTY_USER) {
            // Create first IEN in IPF 1
            reduivy__Individual_Enrollment__c ien1Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_COMPLETED_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert ien1Ipf1;

            // Verify first attempt in IPF 1
            ien1Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien1Ipf1.Id];
            System.Assert.areEqual(1, ien1Ipf1.reduivy__Attempt_Number__c, 
                'First IEN in IPF 1 should have attempt number 1');

            // Create first IEN in IPF 2 for same unit
            reduivy__Individual_Enrollment__c ien1Ipf2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_COMPLETED_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[1].Id,
                true
            );
            insert ien1Ipf2;

            // Verify first attempt in IPF 2 starts at 1 (not affected by IPF 1)
            ien1Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien1Ipf2.Id];
            System.Assert.areEqual(1, ien1Ipf2.reduivy__Attempt_Number__c, 
                'First IEN in IPF 2 should have attempt number 1, independent of IPF 1');

            // Create second IEN in IPF 1
            reduivy__Individual_Enrollment__c ien2Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert ien2Ipf1;

            // Verify second attempt in IPF 1 increments to 2
            ien2Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien2Ipf1.Id];
            System.Assert.areEqual(2, ien2Ipf1.reduivy__Attempt_Number__c, 
                'Second IEN in IPF 1 should have attempt number 2');

            // Create second IEN in IPF 2
            reduivy__Individual_Enrollment__c ien2Ipf2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[1].Id,
                true
            );
            insert ien2Ipf2;

            // Verify second attempt in IPF 2 increments to 2 (independent of IPF 1)
            ien2Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien2Ipf2.Id];
            System.Assert.areEqual(2, ien2Ipf2.reduivy__Attempt_Number__c, 
                'Second IEN in IPF 2 should have attempt number 2, independent of IPF 1');

            // Create third IEN in IPF 1
            reduivy__Individual_Enrollment__c ien3Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert ien3Ipf1;

            // Verify third attempt in IPF 1
            ien3Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien3Ipf1.Id];
            System.Assert.areEqual(3, ien3Ipf1.reduivy__Attempt_Number__c, 
                'Third IEN in IPF 1 should have attempt number 3');

            // Verify IPF 2 still has only 2 attempts
            List<reduivy__Individual_Enrollment__c> ipf2Iens = [SELECT reduivy__Attempt_Number__c 
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c = :studentUser.ContactId
                AND reduivy__Target_Unit_Id__c = :sunList[0].Id
                AND reduivy__Individual_Academic_Profile__c = :studentIpfs[1].Id
                ORDER BY reduivy__Attempt_Number__c DESC
            ];
            System.Assert.areEqual(2, ipf2Iens.size(), 'IPF 2 should have 2 attempts');
            System.Assert.areEqual(2, ipf2Iens[0].reduivy__Attempt_Number__c, 
                'Latest attempt in IPF 2 should still be 2');
        }

        Test.stopTest();
    }

    /**
     * @description Test that high attempt numbers in one IPF don't affect another IPF as faculty
     */
    @isTest
    static void testIpfIsolationForAttemptNumberAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT 1
        ];

        for (reduivy__Study_Unit__c sun : sunList) {
            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        // Create two IPFs
        List<reduivy__Individual_Academic_Profile__c> studentIpfs = new List<reduivy__Individual_Academic_Profile__c>();
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 1'
        ));
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 2'
        ));
        insert studentIpfs;

        Test.startTest();

        System.runAs(FACULTY_USER) {
            // Create 5 attempts in IPF 1
            List<reduivy__Individual_Enrollment__c> ipf1Iens = new List<reduivy__Individual_Enrollment__c>();
            for (Integer i = 0; i < 5; i++) {
                ipf1Iens.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    null,
                    studentUser.ContactId,
                    sofMap.get(sunList[0].Id),
                    IEN_COMPLETED_STATUS,
                    i + 1,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    studentIpfs[0].Id,
                    true
                ));
            }
            insert ipf1Iens;

            // Verify IPF 1 has attempts 1-5
            ipf1Iens = [SELECT reduivy__Attempt_Number__c 
                FROM reduivy__Individual_Enrollment__c 
                WHERE Id IN :ipf1Iens 
                ORDER BY reduivy__Attempt_Number__c
            ];
            for (Integer i = 0; i < ipf1Iens.size(); i++) {
                System.Assert.areEqual(i + 1, ipf1Iens[i].reduivy__Attempt_Number__c, 
                    'IPF 1 attempt ' + (i + 1) + ' should be correct');
            }

            // Now create first IEN in IPF 2 - should start at 1, not 6
            reduivy__Individual_Enrollment__c ien1Ipf2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[1].Id,
                true
            );
            insert ien1Ipf2;

            ien1Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien1Ipf2.Id];
            System.Assert.areEqual(1, ien1Ipf2.reduivy__Attempt_Number__c, 
                'First IEN in IPF 2 should be attempt 1, not affected by 5 attempts in IPF 1');
        }

        Test.stopTest();
    }

    /**
     * @description Test attempt number with withdrawn status across different IPFs
     */
    @isTest
    static void testRetainAttemptNumberAcrossIpfsAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT 1
        ];

        for (reduivy__Study_Unit__c sun : sunList) {
            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        // Create two IPFs
        List<reduivy__Individual_Academic_Profile__c> studentIpfs = new List<reduivy__Individual_Academic_Profile__c>();
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 1'
        ));
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 2'
        ));
        insert studentIpfs;

        Test.startTest();

        System.runAs(FACULTY_USER) {
            // IPF 1: Create withdrawn IEN (attempt 1)
            reduivy__Individual_Enrollment__c withdrawn1Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_WITHDRAWN_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert withdrawn1Ipf1;

            withdrawn1Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :withdrawn1Ipf1.Id];
            System.Assert.areEqual(1, withdrawn1Ipf1.reduivy__Attempt_Number__c, 
                'Withdrawn IEN in IPF 1 should be attempt 1');

            // IPF 1: Create in-progress IEN (should be attempt 1, retained)
            reduivy__Individual_Enrollment__c inprogress1Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert inprogress1Ipf1;

            inprogress1Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :inprogress1Ipf1.Id];
            System.Assert.areEqual(1, inprogress1Ipf1.reduivy__Attempt_Number__c, 
                'In-progress IEN in IPF 1 should retain attempt 1 (withdrawn doesn\'t increment)');

            // IPF 2: Create withdrawn IEN (attempt 1)
            reduivy__Individual_Enrollment__c withdrawn1Ipf2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_WITHDRAWN_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[1].Id,
                true
            );
            insert withdrawn1Ipf2;

            withdrawn1Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :withdrawn1Ipf2.Id];
            System.Assert.areEqual(1, withdrawn1Ipf2.reduivy__Attempt_Number__c, 
                'Withdrawn IEN in IPF 2 should be attempt 1');

            // IPF 2: Create in-progress IEN (should be attempt 1, retained)
            reduivy__Individual_Enrollment__c inprogress1Ipf2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[1].Id,
                true
            );
            insert inprogress1Ipf2;

            inprogress1Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :inprogress1Ipf2.Id];
            System.Assert.areEqual(1, inprogress1Ipf2.reduivy__Attempt_Number__c, 
                'In-progress IEN in IPF 2 should retain attempt 1 (independent of IPF 1)');

            // Update IPF 1 in-progress to completed
            inprogress1Ipf1.reduivy__Enrollment_Status__c = IEN_COMPLETED_STATUS;
            update inprogress1Ipf1;

            // IPF 1: Create another IEN (should be attempt 2)
            reduivy__Individual_Enrollment__c ien2Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert ien2Ipf1;

            ien2Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien2Ipf1.Id];
            System.Assert.areEqual(2, ien2Ipf1.reduivy__Attempt_Number__c, 
                'New IEN in IPF 1 should be attempt 2 after completed status');

            // Verify IPF 2 still has attempt 1
            inprogress1Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :inprogress1Ipf2.Id];
            System.Assert.areEqual(1, inprogress1Ipf2.reduivy__Attempt_Number__c, 
                'IPF 2 should still have attempt 1, unaffected by IPF 1');
        }

        Test.stopTest();
    }

    /**
     * @description Test that attempt numbers are tracked separately within each IPF as student
     */
    @isTest
    static void testAttemptNumberWithinSameIpfAsStudent() {

        // Set up test data
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get study unit and study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT 1
        ];

        System.Assert.isFalse(
            sunList.isEmpty(),
            'The list should contain study unit records'
        );

        for (reduivy__Study_Unit__c sun : sunList) {
            System.Assert.isFalse(
                sun.reduivy__Study_Offerings__r.isEmpty(),
                'The list should contain study offering records'
            );
            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        // Create two IPFs for the same student
        List<reduivy__Individual_Academic_Profile__c> studentIpfs = new List<reduivy__Individual_Academic_Profile__c>();
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 1',
            reduivy__Primary__c = true
        ));
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 2',
            reduivy__Primary__c = false
        ));
        insert studentIpfs;

        Test.startTest();

        System.runAs(studentUser) {
            // Create first IEN in IPF 1
            reduivy__Individual_Enrollment__c ien1Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_COMPLETED_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert ien1Ipf1;

            // Verify first attempt in IPF 1
            ien1Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien1Ipf1.Id];
            System.Assert.areEqual(1, ien1Ipf1.reduivy__Attempt_Number__c, 
                'First IEN in IPF 1 should have attempt number 1');

            // Create first IEN in IPF 2 for same unit
            reduivy__Individual_Enrollment__c ien1Ipf2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_COMPLETED_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[1].Id,
                true
            );
            insert ien1Ipf2;

            // Verify first attempt in IPF 2 starts at 1 (not affected by IPF 1)
            ien1Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien1Ipf2.Id];
            System.Assert.areEqual(1, ien1Ipf2.reduivy__Attempt_Number__c, 
                'First IEN in IPF 2 should have attempt number 1, independent of IPF 1');

            // Create second IEN in IPF 1
            reduivy__Individual_Enrollment__c ien2Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert ien2Ipf1;

            // Verify second attempt in IPF 1 increments to 2
            ien2Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien2Ipf1.Id];
            System.Assert.areEqual(2, ien2Ipf1.reduivy__Attempt_Number__c, 
                'Second IEN in IPF 1 should have attempt number 2');

            // Create second IEN in IPF 2
            reduivy__Individual_Enrollment__c ien2Ipf2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[1].Id,
                true
            );
            insert ien2Ipf2;

            // Verify second attempt in IPF 2 increments to 2 (independent of IPF 1)
            ien2Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien2Ipf2.Id];
            System.Assert.areEqual(2, ien2Ipf2.reduivy__Attempt_Number__c, 
                'Second IEN in IPF 2 should have attempt number 2, independent of IPF 1');

            // Create third IEN in IPF 1
            reduivy__Individual_Enrollment__c ien3Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert ien3Ipf1;

            // Verify third attempt in IPF 1
            ien3Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien3Ipf1.Id];
            System.Assert.areEqual(3, ien3Ipf1.reduivy__Attempt_Number__c, 
                'Third IEN in IPF 1 should have attempt number 3');

            // Verify IPF 2 still has only 2 attempts
            List<reduivy__Individual_Enrollment__c> ipf2Iens = [SELECT reduivy__Attempt_Number__c 
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c = :studentUser.ContactId
                AND reduivy__Target_Unit_Id__c = :sunList[0].Id
                AND reduivy__Individual_Academic_Profile__c = :studentIpfs[1].Id
                ORDER BY reduivy__Attempt_Number__c DESC
            ];
            System.Assert.areEqual(2, ipf2Iens.size(), 'IPF 2 should have 2 attempts');
            System.Assert.areEqual(2, ipf2Iens[0].reduivy__Attempt_Number__c, 
                'Latest attempt in IPF 2 should still be 2');
        }

        Test.stopTest();
    }

    /**
     * @description Test that high attempt numbers in one IPF don't affect another IPF as student
     */
    @isTest
    static void testIpfIsolationForAttemptNumberAsStudent() {

        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT 1
        ];

        for (reduivy__Study_Unit__c sun : sunList) {
            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        // Create two IPFs
        List<reduivy__Individual_Academic_Profile__c> studentIpfs = new List<reduivy__Individual_Academic_Profile__c>();
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 1'
        ));
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 2'
        ));
        insert studentIpfs;

        Test.startTest();

        System.runAs(studentUser) {
            // Create 5 attempts in IPF 1
            List<reduivy__Individual_Enrollment__c> ipf1Iens = new List<reduivy__Individual_Enrollment__c>();
            for (Integer i = 0; i < 5; i++) {
                ipf1Iens.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    null,
                    studentUser.ContactId,
                    sofMap.get(sunList[0].Id),
                    IEN_COMPLETED_STATUS,
                    i + 1,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    studentIpfs[0].Id,
                    true
                ));
            }
            insert ipf1Iens;

            // Verify IPF 1 has attempts 1-5
            ipf1Iens = [SELECT reduivy__Attempt_Number__c 
                FROM reduivy__Individual_Enrollment__c 
                WHERE Id IN :ipf1Iens 
                ORDER BY reduivy__Attempt_Number__c
            ];
            for (Integer i = 0; i < ipf1Iens.size(); i++) {
                System.Assert.areEqual(i + 1, ipf1Iens[i].reduivy__Attempt_Number__c, 
                    'IPF 1 attempt ' + (i + 1) + ' should be correct');
            }

            // Now create first IEN in IPF 2 - should start at 1, not 6
            reduivy__Individual_Enrollment__c ien1Ipf2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[1].Id,
                true
            );
            insert ien1Ipf2;

            ien1Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien1Ipf2.Id];
            System.Assert.areEqual(1, ien1Ipf2.reduivy__Attempt_Number__c, 
                'First IEN in IPF 2 should be attempt 1, not affected by 5 attempts in IPF 1');
        }

        Test.stopTest();
    }

    /**
     * @description Test attempt number with withdrawn status across different IPFs
     */
    @isTest
    static void testRetainAttemptNumberAcrossIpfsAsStudent() {

        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id from reduivy__Study_Offerings__r limit 1)
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1')
            ORDER BY reduivy__Unit_Code__c
            LIMIT 1
        ];

        for (reduivy__Study_Unit__c sun : sunList) {
            sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
        }

        // Create two IPFs
        List<reduivy__Individual_Academic_Profile__c> studentIpfs = new List<reduivy__Individual_Academic_Profile__c>();
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 1'
        ));
        studentIpfs.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentUser.ContactId,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 2'
        ));
        insert studentIpfs;

        Test.startTest();

        System.runAs(studentUser) {
            // IPF 1: Create withdrawn IEN (attempt 1)
            reduivy__Individual_Enrollment__c withdrawn1Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_WITHDRAWN_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert withdrawn1Ipf1;

            withdrawn1Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :withdrawn1Ipf1.Id];
            System.Assert.areEqual(1, withdrawn1Ipf1.reduivy__Attempt_Number__c, 
                'Withdrawn IEN in IPF 1 should be attempt 1');

            // IPF 1: Create in-progress IEN (should be attempt 1, retained)
            reduivy__Individual_Enrollment__c inprogress1Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert inprogress1Ipf1;

            inprogress1Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :inprogress1Ipf1.Id];
            System.Assert.areEqual(1, inprogress1Ipf1.reduivy__Attempt_Number__c, 
                'In-progress IEN in IPF 1 should retain attempt 1 (withdrawn doesn\'t increment)');

            // IPF 2: Create withdrawn IEN (attempt 1)
            reduivy__Individual_Enrollment__c withdrawn1Ipf2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_WITHDRAWN_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[1].Id,
                true
            );
            insert withdrawn1Ipf2;

            withdrawn1Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :withdrawn1Ipf2.Id];
            System.Assert.areEqual(1, withdrawn1Ipf2.reduivy__Attempt_Number__c, 
                'Withdrawn IEN in IPF 2 should be attempt 1');

            // IPF 2: Create in-progress IEN (should be attempt 1, retained)
            reduivy__Individual_Enrollment__c inprogress1Ipf2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[1].Id,
                true
            );
            insert inprogress1Ipf2;

            inprogress1Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :inprogress1Ipf2.Id];
            System.Assert.areEqual(1, inprogress1Ipf2.reduivy__Attempt_Number__c, 
                'In-progress IEN in IPF 2 should retain attempt 1 (independent of IPF 1)');

            // Update IPF 1 in-progress to completed
            inprogress1Ipf1.reduivy__Enrollment_Status__c = IEN_COMPLETED_STATUS;
            update inprogress1Ipf1;

            // IPF 1: Create another IEN (should be attempt 2)
            reduivy__Individual_Enrollment__c ien2Ipf1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                null,
                studentUser.ContactId,
                sofMap.get(sunList[0].Id),
                IEN_INPROGRESS_STATUS,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                studentIpfs[0].Id,
                true
            );
            insert ien2Ipf1;

            ien2Ipf1 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :ien2Ipf1.Id];
            System.Assert.areEqual(2, ien2Ipf1.reduivy__Attempt_Number__c, 
                'New IEN in IPF 1 should be attempt 2 after completed status');

            // Verify IPF 2 still has attempt 1
            inprogress1Ipf2 = [SELECT reduivy__Attempt_Number__c FROM reduivy__Individual_Enrollment__c WHERE Id = :inprogress1Ipf2.Id];
            System.Assert.areEqual(1, inprogress1Ipf2.reduivy__Attempt_Number__c, 
                'IPF 2 should still have attempt 1, unaffected by IPF 1');
        }

        Test.stopTest();
    }
}