/**
 * @author      WDCi (dblack)
 * @date        Jan 2024
 * @group       Test
 * @description Test class for IPE_Completion_EXE
 * @changehistory
 * ISS-001817 03-01-2024 dblack - new class
 */
@IsTest
public inherited sharing class IPE_Completion_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';

    static final List<String> IPE_INPROGRESS_STATUSES = IPE_Helper.getInProgressStatuses();
    static final List<String> IPE_COMPLETED_STATUSES = IPE_Helper.getCompletedStatuses();

    static final Integer IPE_QTY = 5;
    static final Integer CREDITS_QTY = 10;

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData() {
        
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();

        	testFactory.initMasterData(SPS_Helper.getApiName());
			testFactory.initStudentData(USR_Helper.getApiName(), true);

            List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
            for (Contact student : testFactory.students.values()) {
				String sampleRecordCode = student.Id + '_' + testFactory.studyPlans.get(STUDY_PLAN).Id;
				Id contactId = student.Id;
				Id studyProgramId = testFactory.studyPrograms.get(STUDY_PROGRAM).Id;
				Id studyPlanId = testFactory.studyPlans.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = null;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = IPE_INPROGRESS_STATUSES.get(0);
				Id idvAcademicProfileId = null;
				reduivy__Individual_Program_Enrollment__c ipe = 
					REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
						sampleRecordCode, 
						contactId, 
						studyProgramId, 
						studyPlanId, 
						studyIntakeId, 
						startingTermId, 
						studyPathwayId, 
						defaultCampusId, 
						classYear, 
						classStanding, 
						eligibleToEnroll, 
						enrollmentStatus,
						idvAcademicProfileId
					);

				ipeList.add(ipe);
			}
			
			insert ipeList;

            Test.stopTest();
		}
    }
	
    /**
     * @description Test as an admin user the individual program enrollment status when there are remaining credits required but required children are not completed
     */
    @isTest
    static void testIpeStatusWithRemaininingCreditsRequired_ChildrenNotCompletedAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        // Get individual program enrollment records
        List<reduivy__Individual_Program_Enrollment__c> ipeList = [
            SELECT  reduivy__Credits_Earned__c, reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            LIMIT :IPE_QTY
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain the individual program enrollment records'
        );

        // Set pre-test condition
        Set<Id> ipeIdSet = new Set<Id>();
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            ipeIdSet.add(ipe.Id);
            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c;
            ipe.reduivy__Required_Children_Completed__c = true;
        }

        update ipeList;

        // Verify pre-test condition and update for test
        ipeList = [
            SELECT  reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c, reduivy__Credits_Earned__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_COMPLETED_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c == 100,
                'The actual value should be as expected'
            );

            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c - CREDITS_QTY;
            ipe.reduivy__Required_Children_Completed__c = false;
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            update ipeList;
            Test.stopTest();
        }

        // Verify test results
        ipeList = [
            SELECT reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_INPROGRESS_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c < 100,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as an admin user the individual program enrollment status when there are remaining credits required
     */
    @isTest
    static void testIpeStatusWithRemaininingCreditsRequired_ChildrenCompletedAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        // Get individual program enrollment records
        List<reduivy__Individual_Program_Enrollment__c> ipeList = [
            SELECT  reduivy__Credits_Earned__c, reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            LIMIT :IPE_QTY
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain the individual program enrollment records'
        );

        // Set pre-test condition
        Set<Id> ipeIdSet = new Set<Id>();
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            ipeIdSet.add(ipe.Id);
            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c;
            ipe.reduivy__Required_Children_Completed__c = true;
        }

        update ipeList;

        // Verify pre-test condition and update for test
        ipeList = [
            SELECT  reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c, reduivy__Credits_Earned__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_COMPLETED_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c == 100,
                'The actual value should be as expected'
            );

            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c - CREDITS_QTY;
            ipe.reduivy__Required_Children_Completed__c = true;
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            update ipeList;
            Test.stopTest();
        }

        // Verify test results
        ipeList = [
            SELECT reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_INPROGRESS_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c < 100,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as an admin user the individual program enrollment status when there are not remaining credits required but required children are not completed
     */
    @isTest
    static void testIpeStatusWithoutRemaininingCreditsRequired_ChildrenNotCompletedAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        // Get individual program enrollment records
        List<reduivy__Individual_Program_Enrollment__c> ipeList = [
            SELECT  reduivy__Credits_Earned__c, reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            LIMIT :IPE_QTY
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain the individual program enrollment records'
        );

        // Set pre-test condition
        Set<Id> ipeIdSet = new Set<Id>();
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            ipeIdSet.add(ipe.Id);
            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c - CREDITS_QTY;
        }

        update ipeList;

        // Verify pre-test condition and update for test
        ipeList = [
            SELECT  reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c, reduivy__Credits_Earned__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_INPROGRESS_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c < 100,
                'The actual value should be as expected'
            );

            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c;
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            update ipeList;
            Test.stopTest();
        }

        // Verify test results
        ipeList = [
            SELECT reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_INPROGRESS_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c == 100,
                'The actual value should be as expected'
            );
        }
    }


    /**
     * @description Test as an admin user the individual program enrollment status when there are not remaining credits required and required children are completed
     */
    @isTest
    static void testIpeStatusWithoutRemaininingCreditsRequired_ChildrenCompletedAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        // Get individual program enrollment records
        List<reduivy__Individual_Program_Enrollment__c> ipeList = [
            SELECT  reduivy__Credits_Earned__c, reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            LIMIT :IPE_QTY
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain the individual program enrollment records'
        );

        // Set pre-test condition
        Set<Id> ipeIdSet = new Set<Id>();
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            ipeIdSet.add(ipe.Id);
            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c - CREDITS_QTY;
            ipe.reduivy__Required_Children_Completed__c = true;
        }

        update ipeList;

        // Verify pre-test condition and update for test
        ipeList = [
            SELECT  reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c, reduivy__Credits_Earned__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_INPROGRESS_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c < 100,
                'The actual value should be as expected'
            );

            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c;
            ipe.reduivy__Required_Children_Completed__c = true;
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            update ipeList;
            Test.stopTest();
        }

        // Verify test results
        ipeList = [
            SELECT reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_COMPLETED_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c == 100,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a faculty user the individual program enrollment status when there are remaining credits required but required children are not completed
     */
    @isTest
    static void testIpeStatusWithRemaininingCreditsRequired_ChildrenNotCompletedAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Get individual program enrollment records
        List<reduivy__Individual_Program_Enrollment__c> ipeList = [
            SELECT  reduivy__Credits_Earned__c, reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            LIMIT :IPE_QTY
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain the individual program enrollment records'
        );

        // Set pre-test condition
        Set<Id> ipeIdSet = new Set<Id>();
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            ipeIdSet.add(ipe.Id);
            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c;
            ipe.reduivy__Required_Children_Completed__c = true;
        }

        update ipeList;

        // Verify pre-test condition and update for test
        ipeList = [
            SELECT  reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c, reduivy__Credits_Earned__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_COMPLETED_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c == 100,
                'The actual value should be as expected'
            );

            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c - CREDITS_QTY;
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            update ipeList;
            Test.stopTest();
        }

        // Verify test results
        ipeList = [
            SELECT reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_INPROGRESS_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c < 100,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a faculty user the individual program enrollment status when there are remaining credits required and required children are completed
     */
    @isTest
    static void testIpeStatusWithRemaininingCreditsRequired_ChildrenCompletedAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Get individual program enrollment records
        List<reduivy__Individual_Program_Enrollment__c> ipeList = [
            SELECT  reduivy__Credits_Earned__c, reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            LIMIT :IPE_QTY
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain the individual program enrollment records'
        );

        // Set pre-test condition
        Set<Id> ipeIdSet = new Set<Id>();
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            ipeIdSet.add(ipe.Id);
            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c;
            ipe.reduivy__Required_Children_Completed__c = true;
        }

        update ipeList;

        // Verify pre-test condition and update for test
        ipeList = [
            SELECT  reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c, reduivy__Credits_Earned__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_COMPLETED_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c == 100,
                'The actual value should be as expected'
            );

            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c - CREDITS_QTY;
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            update ipeList;
            Test.stopTest();
        }

        // Verify test results
        ipeList = [
            SELECT reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_INPROGRESS_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c < 100,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a faculty user the individual program enrollment status when there are not remaining credits required but required children are not completed
     */
    @isTest
    static void testIpeStatusWithoutRemaininingCreditsRequired_ChildrenNotCompletedAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Get individual program enrollment records
        List<reduivy__Individual_Program_Enrollment__c> ipeList = [
            SELECT  reduivy__Credits_Earned__c, reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            LIMIT :IPE_QTY
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain the individual program enrollment records'
        );

        // Set pre-test condition
        Set<Id> ipeIdSet = new Set<Id>();
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            ipeIdSet.add(ipe.Id);
            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c - CREDITS_QTY;
        }

        update ipeList;

        // Verify pre-test condition and update for test
        ipeList = [
            SELECT  reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c, reduivy__Credits_Earned__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_INPROGRESS_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c < 100,
                'The actual value should be as expected'
            );

            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c;
            ipe.reduivy__Required_Children_Completed__c = false;
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            update ipeList;
            Test.stopTest();
        }

        // Verify test results
        ipeList = [
            SELECT reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_INPROGRESS_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c == 100,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a faculty user the individual program enrollment status when there are not remaining credits required and required children are completed
     */
    @isTest
    static void testIpeStatusWithoutRemaininingCreditsRequired_ChildrenCompletedAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Get individual program enrollment records
        List<reduivy__Individual_Program_Enrollment__c> ipeList = [
            SELECT  reduivy__Credits_Earned__c, reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            LIMIT :IPE_QTY
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain the individual program enrollment records'
        );

        // Set pre-test condition
        Set<Id> ipeIdSet = new Set<Id>();
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            ipeIdSet.add(ipe.Id);
            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c - CREDITS_QTY;
        }

        update ipeList;

        // Verify pre-test condition and update for test
        ipeList = [
            SELECT  reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c, reduivy__Credits_Earned__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_INPROGRESS_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c < 100,
                'The actual value should be as expected'
            );

            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c;
            ipe.reduivy__Required_Children_Completed__c = true;
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            update ipeList;
            Test.stopTest();
        }

        // Verify test results
        ipeList = [
            SELECT reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_COMPLETED_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c == 100,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a student user the individual program enrollment status when there are remaining credits required and required children are completed
     */
    @isTest
    static void testIpeStatusWithRemaininingCreditsRequired_ChildrenCompletedAsStudent() {

        // Setup test data

        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get individual program enrollment records
        List<reduivy__Individual_Program_Enrollment__c> ipeList = [
            SELECT  reduivy__Credits_Earned__c, reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Contact__c IN :studentContacts
            LIMIT :IPE_QTY
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain the individual program enrollment records'
        );

        // Set pre-test condition
        Set<Id> ipeIdSet = new Set<Id>();
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            
            ipeIdSet.add(ipe.Id);
            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c;
            ipe.reduivy__Required_Children_Completed__c = true;
        }

        update ipeList;

        // Verify pre-test condition and update for test
        ipeList = [
            SELECT  reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c, reduivy__Credits_Earned__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_COMPLETED_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c == 100,
                'The actual value should be as expected'
            );

            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c - CREDITS_QTY;
            ipe.reduivy__Required_Children_Completed__c = true;
        }

        System.runAs(studentUser) {

            // Execute test
            Test.startTest();
            update ipeList;
            Test.stopTest();
        }

        // Verify test results
        ipeList = [
            SELECT reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_INPROGRESS_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c < 100,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a student user the individual program enrollment status when there are remaining credits required but required children are not completed
     */
    @isTest
    static void testIpeStatusWithRemaininingCreditsRequired_ChildrenNotCompletedAsStudent() {

        // Setup test data

        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get individual program enrollment records
        List<reduivy__Individual_Program_Enrollment__c> ipeList = [
            SELECT  reduivy__Credits_Earned__c, reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Contact__c IN :studentContacts
            LIMIT :IPE_QTY
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain the individual program enrollment records'
        );

        // Set pre-test condition
        Set<Id> ipeIdSet = new Set<Id>();
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            
            ipeIdSet.add(ipe.Id);
            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c;
            ipe.reduivy__Required_Children_Completed__c = true;
        }

        update ipeList;

        // Verify pre-test condition and update for test
        ipeList = [
            SELECT  reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c, reduivy__Credits_Earned__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_COMPLETED_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c == 100,
                'The actual value should be as expected'
            );

            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c - CREDITS_QTY;
            ipe.reduivy__Required_Children_Completed__c = false;
        }

        System.runAs(studentUser) {

            // Execute test
            Test.startTest();
            update ipeList;
            Test.stopTest();
        }

        // Verify test results
        ipeList = [
            SELECT reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_INPROGRESS_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c < 100,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a student user the individual program enrollment status when there are not remaining credits required and required children are completed
     */
    @isTest
    static void testIpeStatusWithoutRemaininingCreditsRequired_ChildrenCompletedAsStudent() {

        // Setup test data

        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get individual program enrollment records
        List<reduivy__Individual_Program_Enrollment__c> ipeList = [
            SELECT  reduivy__Credits_Earned__c, reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Contact__c IN :studentContacts
            LIMIT :IPE_QTY
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain the individual program enrollment records'
        );

        // Set pre-test condition
        Set<Id> ipeIdSet = new Set<Id>();
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            
            ipeIdSet.add(ipe.Id);
            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c - CREDITS_QTY;
        }

        update ipeList;

        // Verify pre-test condition and update for test
        ipeList = [
            SELECT  reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c, reduivy__Credits_Earned__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_INPROGRESS_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c < 100,
                'The actual value should be as expected'
            );

            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c;
            ipe.reduivy__Required_Children_Completed__c = true;
        }

        System.runAs(studentUser) {

            // Execute test
            Test.startTest();
            update ipeList;
            Test.stopTest();
        }

        // Verify test results
        ipeList = [
            SELECT reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_COMPLETED_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c == 100,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a student user the individual program enrollment status when there are not remaining credits required but required children are not completed
     */
    @isTest
    static void testIpeStatusWithoutRemaininingCreditsRequired_ChildrenNotCompletedAsStudent() {

        // Setup test data

        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get individual program enrollment records
        List<reduivy__Individual_Program_Enrollment__c> ipeList = [
            SELECT  reduivy__Credits_Earned__c, reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Contact__c IN :studentContacts
            LIMIT :IPE_QTY
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain the individual program enrollment records'
        );

        // Set pre-test condition
        Set<Id> ipeIdSet = new Set<Id>();
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            
            ipeIdSet.add(ipe.Id);
            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c - CREDITS_QTY;
        }

        update ipeList;

        // Verify pre-test condition and update for test
        ipeList = [
            SELECT  reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c, reduivy__Credits_Earned__c,
                    reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_INPROGRESS_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c < 100,
                'The actual value should be as expected'
            );

            ipe.reduivy__Credits_Earned__c = ipe.reduivy__Study_Plan__r.reduivy__Total_Required_Credits__c;
            ipe.reduivy__Required_Children_Completed__c = false;
        }

        System.runAs(studentUser) {

            // Execute test
            Test.startTest();
            update ipeList;
            Test.stopTest();
        }

        // Verify test results
        ipeList = [
            SELECT reduivy__Enrollment_Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN :ipeIdSet
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                IPE_INPROGRESS_STATUSES.get(0),
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipe.reduivy__Completion_Percentage__c == 100,
                'The actual value should be as expected'
            );
        }
    }
}