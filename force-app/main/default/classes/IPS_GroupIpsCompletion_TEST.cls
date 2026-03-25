/**
 * @author      WDCi (dblack)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for IPS_GroupIpsCompletion_EXE
 * @changehistory
 * ISS-001817 13-12-2023 dblack - new class
 */
@isTest
public inherited sharing class IPS_GroupIpsCompletion_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';
    
    static final List<String> IPE_INPROGRESS_STATUSES = IPE_Helper.getInProgressStatuses();

    static final List<String> IPS_GROUP_NOTSTARTED_STATUSES = IPS_Helper.getGroupNotStartedStatuses();
    static final List<String> IPS_GROUP_INPROGRESS_STATUSES = IPS_Helper.getGroupInProgressStatuses();
    static final List<String> IPS_GROUP_COMPLETED_STATUSES = IPS_Helper.getGroupCompletedStatuses();

    static final Integer IPSG_QTY = 10;    
    static final Decimal CREDITS_QTY = 10;
    static final Decimal UNITS_QTY = 10;

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
     * @description Test as an admin user that the individual plan structure (group) status is updated to not-started
     */
    @isTest
    static void testA_IpsGroupStatusNotStartedAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits__c, reduivy__Credits_Enrolled__c, reduivy__Credits_Earned__c, 
                    reduivy__Units_Required__c, reduivy__Units_Enrolled__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Completion_Percentage__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            LIMIT :IPSG_QTY
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;
		
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {
		
			ipsgIdSet.add(ipsg.Id);
			index = ipsgList.indexOf(ipsg);
			
			if (index < (ipsgList.size()/2)) {
			
				ipsg.reduivy__Credits__c = CREDITS_QTY;
                ipsg.reduivy__Credits_Enrolled__c = 0;
                ipsg.reduivy__Credits_Earned__c = 0;

                ipsg.reduivy__Units_Required__c = null;
                ipsg.reduivy__Units_Enrolled__c = null;
                ipsg.reduivy__Units_Passed__c = null;
                ipsg.reduivy__Units_Contributed__c = null;
				
			} else {
			
                ipsg.reduivy__Credits__c = null;
                ipsg.reduivy__Credits_Enrolled__c = null;
                ipsg.reduivy__Credits_Earned__c = null;

                ipsg.reduivy__Units_Required__c = UNITS_QTY;
                ipsg.reduivy__Units_Enrolled__c = 0;
                ipsg.reduivy__Units_Passed__c = 0;
                ipsg.reduivy__Units_Contributed__c = 0;
			}		
		}
		
        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            update ipsgList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT reduivy__Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );
		
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

			System.Assert.areEqual(
				IPS_GROUP_NOTSTARTED_STATUSES.get(0),
				ips.reduivy__Status__c,
				'The actual value should be as expected'
			);
			
			System.Assert.areEqual(
				0, ips.reduivy__Completion_Percentage__c,
				'The actual value should be as expected'
			);
		}	
	}
	
    /**
     * @description Test as an admin user that the individual plan structure (group) status is updated to in-progress
     */
    @isTest
    static void testB_IpsGroupStatusInProgressAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits__c, reduivy__Credits_Enrolled__c, reduivy__Credits_Earned__c, 
                    reduivy__Units_Required__c, reduivy__Units_Enrolled__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Completion_Percentage__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            LIMIT :IPSG_QTY
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;
		
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {
		
			ipsgIdSet.add(ipsg.Id);
			index = ipsgList.indexOf(ipsg);
			
			if (index < (ipsgList.size()/2)) {
			
				ipsg.reduivy__Credits__c = (2 * CREDITS_QTY);
                ipsg.reduivy__Credits_Enrolled__c = CREDITS_QTY;
                ipsg.reduivy__Credits_Earned__c = 0;

                ipsg.reduivy__Units_Required__c = null;
                ipsg.reduivy__Units_Enrolled__c = null;
                ipsg.reduivy__Units_Passed__c = null;
                ipsg.reduivy__Units_Contributed__c = null;
				
			} else {
			
                ipsg.reduivy__Credits__c = null;
                ipsg.reduivy__Credits_Enrolled__c = null;
                ipsg.reduivy__Credits_Earned__c = null;

                ipsg.reduivy__Units_Required__c = (2 * UNITS_QTY);
                ipsg.reduivy__Units_Enrolled__c = UNITS_QTY;
                ipsg.reduivy__Units_Passed__c = 0;
                ipsg.reduivy__Units_Contributed__c = 0;
			}
		}
		
        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            update ipsgList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT reduivy__Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );
		
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

			System.Assert.areEqual(
				IPS_GROUP_INPROGRESS_STATUSES.get(0),
				ips.reduivy__Status__c,
				'The actual value should be as expected'
			);
			
			System.Assert.areEqual(
				0, ips.reduivy__Completion_Percentage__c,
				'The actual value should be as expected'
			);
		}
	}
	
    /**
     * @description Test as an admin user that the individual plan structure (group) status is updated to completed
     */
    @isTest
    static void testC1_IpsGroupStatusCompleted_OptionalOnly_AsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        // Get individual plan structure (group) records for update
        // we test for bacbis_majora_groupa
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits__c, reduivy__Credits_Enrolled__c, reduivy__Credits_Earned__c, 
                    reduivy__Units_Required__c, reduivy__Units_Enrolled__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Completion_Percentage__c, reduivy__Parent_Plan_Structure__c, reduivy__Category__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            AND reduivy__Category__c =:IPS_Helper.CATEGORY_OPTIONAL
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;
		
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {
		
			ipsgIdSet.add(ipsg.Id);
			index = ipsgList.indexOf(ipsg);
			
			if (index < (ipsgList.size()/2)) {
			
				ipsg.reduivy__Credits__c = CREDITS_QTY;
                ipsg.reduivy__Credits_Enrolled__c = ipsg.reduivy__Credits__c;
                ipsg.reduivy__Credits_Earned__c = ipsg.reduivy__Credits_Enrolled__c;

                ipsg.reduivy__Units_Required__c = null;
                ipsg.reduivy__Units_Enrolled__c = null;
                ipsg.reduivy__Units_Passed__c = null;
                ipsg.reduivy__Units_Contributed__c = null;
				
			} else {
			
                ipsg.reduivy__Credits__c = null;
                ipsg.reduivy__Credits_Enrolled__c = null;
                ipsg.reduivy__Credits_Earned__c = null;

                ipsg.reduivy__Units_Required__c = UNITS_QTY;
                ipsg.reduivy__Units_Enrolled__c = ipsg.reduivy__Units_Required__c;
                ipsg.reduivy__Units_Passed__c = ipsg.reduivy__Units_Enrolled__c;
                ipsg.reduivy__Units_Contributed__c = ipsg.reduivy__Units_Enrolled__c;
			}		
		}
		
        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            update ipsgList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT reduivy__Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );
		
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

			System.Assert.areEqual(
				IPS_GROUP_INPROGRESS_STATUSES.get(0),
				ips.reduivy__Status__c,
				'The actual value should be as expected'
			);
			
			System.Assert.areEqual(
				100, ips.reduivy__Completion_Percentage__c,
				'The actual value should be as expected'
			);
		}
	}

    /**
     * @description Test as an admin user that the individual plan structure (group) status is updated to completed
     */
    @isTest
    static void testC2_IpsGroupStatusCompleted_All_AsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        // Get individual plan structure (group) records for update
        // we test for bacbis_majora_groupa
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits__c, reduivy__Credits_Enrolled__c, reduivy__Credits_Earned__c, 
                    reduivy__Units_Required__c, reduivy__Units_Enrolled__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Completion_Percentage__c, reduivy__Parent_Plan_Structure__c, reduivy__Category__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
        ];

        Set<Id> parentPlanStructureId = new Set<Id>();

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;
		
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {
            parentPlanStructureId.add(ipsg.reduivy__Parent_Plan_Structure__c);
			ipsgIdSet.add(ipsg.Id);
			index = ipsgList.indexOf(ipsg);
            ipsg.reduivy__Required_Children_Completed__c = true;
			
			if (index < (ipsgList.size()/2)) {
			
				ipsg.reduivy__Credits__c = CREDITS_QTY;
                ipsg.reduivy__Credits_Enrolled__c = ipsg.reduivy__Credits__c;
                ipsg.reduivy__Credits_Earned__c = ipsg.reduivy__Credits_Enrolled__c;

                ipsg.reduivy__Units_Required__c = null;
                ipsg.reduivy__Units_Enrolled__c = null;
                ipsg.reduivy__Units_Passed__c = null;
                ipsg.reduivy__Units_Contributed__c = null;
				
			} else {
			
                ipsg.reduivy__Credits__c = null;
                ipsg.reduivy__Credits_Enrolled__c = null;
                ipsg.reduivy__Credits_Earned__c = null;

                ipsg.reduivy__Units_Required__c = UNITS_QTY;
                ipsg.reduivy__Units_Enrolled__c = ipsg.reduivy__Units_Required__c;
                ipsg.reduivy__Units_Passed__c = ipsg.reduivy__Units_Enrolled__c;
                ipsg.reduivy__Units_Contributed__c = ipsg.reduivy__Units_Enrolled__c;
			}		
		}
		
        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            update ipsgList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT reduivy__Status__c, reduivy__Completion_Percentage__c, reduivy__Category__c, RecordType.DeveloperName,
            reduivy__Credits__c, reduivy__Credits_Enrolled__c, reduivy__Credits_Earned__c,
            reduivy__Units_Required__c, reduivy__Units_Enrolled__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c, 
            (SELECT Id, reduivy__Category__c, RecordType.DeveloperName FROM reduivy__Individual_Plan_Structures__r)
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );
		
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

			System.Assert.areEqual(
				IPS_GROUP_COMPLETED_STATUSES.get(0),
				ips.reduivy__Status__c,
				'The actual value should be as expected'
			);
			
			System.Assert.areEqual(
				100, ips.reduivy__Completion_Percentage__c,
				'The actual value should be as expected'
			);
		}
	}

    /**
     * @description Test as a faculty user that the individual plan structure (group) status is updated to not-started
     */
    @isTest
    static void testD_IpsGroupStatusNotStartedAsFaculty() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits__c, reduivy__Credits_Enrolled__c, reduivy__Credits_Earned__c, 
                    reduivy__Units_Required__c, reduivy__Units_Enrolled__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Completion_Percentage__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            LIMIT :IPSG_QTY
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;
		
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {
		
			ipsgIdSet.add(ipsg.Id);
			index = ipsgList.indexOf(ipsg);
			
			if (index < (ipsgList.size()/2)) {
			
				ipsg.reduivy__Credits__c = CREDITS_QTY;
                ipsg.reduivy__Credits_Enrolled__c = 0;
                ipsg.reduivy__Credits_Earned__c = 0;

                ipsg.reduivy__Units_Required__c = null;
                ipsg.reduivy__Units_Enrolled__c = null;
                ipsg.reduivy__Units_Passed__c = null;
                ipsg.reduivy__Units_Contributed__c = null;
				
			} else {
			
                ipsg.reduivy__Credits__c = null;
                ipsg.reduivy__Credits_Enrolled__c = null;
                ipsg.reduivy__Credits_Earned__c = null;

                ipsg.reduivy__Units_Required__c = UNITS_QTY;
                ipsg.reduivy__Units_Enrolled__c = 0;
                ipsg.reduivy__Units_Passed__c = 0;
                ipsg.reduivy__Units_Contributed__c = 0;
			}		
		}
		
        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            update ipsgList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT reduivy__Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );
		
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

			System.Assert.areEqual(
				IPS_GROUP_NOTSTARTED_STATUSES.get(0),
				ips.reduivy__Status__c,
				'The actual value should be as expected'
			);
			
			System.Assert.areEqual(
				0, ips.reduivy__Completion_Percentage__c,
				'The actual value should be as expected'
			);
		}
	
	}
	
    /**
     * @description Test as a faculty user that the individual plan structure (group) status is updated to in-progress
     */
    @isTest
    static void testE_IpsGroupStatusInProgressAsFaculty() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits__c, reduivy__Credits_Enrolled__c, reduivy__Credits_Earned__c, 
                    reduivy__Units_Required__c, reduivy__Units_Enrolled__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Completion_Percentage__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            LIMIT :IPSG_QTY
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;
		
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {
		
			ipsgIdSet.add(ipsg.Id);
			index = ipsgList.indexOf(ipsg);
			
			if (index < (ipsgList.size()/2)) {
			
				ipsg.reduivy__Credits__c = (2 * CREDITS_QTY);
                ipsg.reduivy__Credits_Enrolled__c = CREDITS_QTY;
                ipsg.reduivy__Credits_Earned__c = 0;

                ipsg.reduivy__Units_Required__c = null;
                ipsg.reduivy__Units_Enrolled__c = null;
                ipsg.reduivy__Units_Passed__c = null;
                ipsg.reduivy__Units_Contributed__c = null;
				
			} else {
			
                ipsg.reduivy__Credits__c = null;
                ipsg.reduivy__Credits_Enrolled__c = null;
                ipsg.reduivy__Credits_Earned__c = null;

                ipsg.reduivy__Units_Required__c = (2 * UNITS_QTY);
                ipsg.reduivy__Units_Enrolled__c = UNITS_QTY;
                ipsg.reduivy__Units_Passed__c = 0;
                ipsg.reduivy__Units_Contributed__c = 0;
			}		
		}
		
        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            update ipsgList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT reduivy__Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );
		
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

			System.Assert.areEqual(
				IPS_GROUP_INPROGRESS_STATUSES.get(0),
				ips.reduivy__Status__c,
				'The actual value should be as expected'
			);
			
			System.Assert.areEqual(
				0, ips.reduivy__Completion_Percentage__c,
				'The actual value should be as expected'
			);
		}
	}
	
    /**
     * @description Test as a faculty user that the individual plan structure (group) status is updated to completed
     */
    @isTest
    static void testF1_IpsGroupStatusCompleted_OptionalOnly_AsFaculty() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits__c, reduivy__Credits_Enrolled__c, reduivy__Credits_Earned__c, 
                    reduivy__Units_Required__c, reduivy__Units_Enrolled__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Completion_Percentage__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            LIMIT :IPSG_QTY
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;
		
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {
		
			ipsgIdSet.add(ipsg.Id);
			index = ipsgList.indexOf(ipsg);
			
			if (index < (ipsgList.size()/2)) {
			
				ipsg.reduivy__Credits__c = CREDITS_QTY;
                ipsg.reduivy__Credits_Enrolled__c = ipsg.reduivy__Credits__c;
                ipsg.reduivy__Credits_Earned__c = ipsg.reduivy__Credits_Enrolled__c;

                ipsg.reduivy__Units_Required__c = null;
                ipsg.reduivy__Units_Enrolled__c = null;
                ipsg.reduivy__Units_Passed__c = null;
                ipsg.reduivy__Units_Contributed__c = null;
				
			} else {
			
                ipsg.reduivy__Credits__c = null;
                ipsg.reduivy__Credits_Enrolled__c = null;
                ipsg.reduivy__Credits_Earned__c = null;

                ipsg.reduivy__Units_Required__c = UNITS_QTY;
                ipsg.reduivy__Units_Enrolled__c = ipsg.reduivy__Units_Required__c;
                ipsg.reduivy__Units_Passed__c = ipsg.reduivy__Units_Enrolled__c;
                ipsg.reduivy__Units_Contributed__c = ipsg.reduivy__Units_Enrolled__c;
			}		
		}
		
        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            update ipsgList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT reduivy__Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );
		
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

			System.Assert.areEqual(
				IPS_GROUP_INPROGRESS_STATUSES.get(0),
				ips.reduivy__Status__c,
				'The actual value should be as expected'
			);
			
			System.Assert.areEqual(
				100, ips.reduivy__Completion_Percentage__c,
				'The actual value should be as expected'
			);
		}
	}
	
    /**
     * @description Test as a faculty user that the individual plan structure (group) status is updated to completed
     */
    @isTest
    static void testF2_IpsGroupStatusCompleted_All_AsFaculty() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits__c, reduivy__Credits_Enrolled__c, reduivy__Credits_Earned__c, 
                    reduivy__Units_Required__c, reduivy__Units_Enrolled__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Completion_Percentage__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            LIMIT :IPSG_QTY
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;
		
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {
		
			ipsgIdSet.add(ipsg.Id);
			index = ipsgList.indexOf(ipsg);
            ipsg.reduivy__Required_Children_Completed__c = true;
			
			if (index < (ipsgList.size()/2)) {
			
				ipsg.reduivy__Credits__c = CREDITS_QTY;
                ipsg.reduivy__Credits_Enrolled__c = ipsg.reduivy__Credits__c;
                ipsg.reduivy__Credits_Earned__c = ipsg.reduivy__Credits_Enrolled__c;

                ipsg.reduivy__Units_Required__c = null;
                ipsg.reduivy__Units_Enrolled__c = null;
                ipsg.reduivy__Units_Passed__c = null;
                ipsg.reduivy__Units_Contributed__c = null;
				
			} else {
			
                ipsg.reduivy__Credits__c = null;
                ipsg.reduivy__Credits_Enrolled__c = null;
                ipsg.reduivy__Credits_Earned__c = null;

                ipsg.reduivy__Units_Required__c = UNITS_QTY;
                ipsg.reduivy__Units_Enrolled__c = ipsg.reduivy__Units_Required__c;
                ipsg.reduivy__Units_Passed__c = ipsg.reduivy__Units_Enrolled__c;
                ipsg.reduivy__Units_Contributed__c = ipsg.reduivy__Units_Enrolled__c;
			}		
		}
		
        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            update ipsgList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT reduivy__Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );
		
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

			System.Assert.areEqual(
				IPS_GROUP_COMPLETED_STATUSES.get(0),
				ips.reduivy__Status__c,
				'The actual value should be as expected'
			);
			
			System.Assert.areEqual(
				100, ips.reduivy__Completion_Percentage__c,
				'The actual value should be as expected'
			);
		}
	}
	
    /**
     * @description Test as a student user that the individual plan structure (group) status is updated to not-started
     */
    @isTest
    static void testG_IpsGroupStatusNotStartedAsStudent() {
	
        // Setup test data

        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits__c, reduivy__Credits_Enrolled__c, reduivy__Credits_Earned__c, 
                    reduivy__Units_Required__c, reduivy__Units_Enrolled__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Completion_Percentage__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN :studentContacts
            AND reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            LIMIT :IPSG_QTY
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        Integer index;
        Set<Id> ipsgIdSet = new Set<Id>();
        List<reduivy__Individual_Plan_Structure__c> ipsgUpdateList = new List<reduivy__Individual_Plan_Structure__c>();
		
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {
		
            ipsgIdSet.add(ipsg.Id);
            index = ipsgList.indexOf(ipsg);
            
            if (index < (ipsgList.size()/2)) {
            
                ipsg.reduivy__Credits__c = CREDITS_QTY;
                ipsg.reduivy__Credits_Enrolled__c = 0;
                ipsg.reduivy__Credits_Earned__c = 0;

                ipsg.reduivy__Units_Required__c = null;
                ipsg.reduivy__Units_Enrolled__c = null;
                ipsg.reduivy__Units_Passed__c = null;
                ipsg.reduivy__Units_Contributed__c = null;
                
            } else {
            
                ipsg.reduivy__Credits__c = null;
                ipsg.reduivy__Credits_Enrolled__c = null;
                ipsg.reduivy__Credits_Earned__c = null;

                ipsg.reduivy__Units_Required__c = UNITS_QTY;
                ipsg.reduivy__Units_Enrolled__c = 0;
                ipsg.reduivy__Units_Passed__c = 0;
                ipsg.reduivy__Units_Contributed__c = 0;
            }
            
            ipsgUpdateList.add(ipsg);
        }
		
        System.runAs(studentUser) {

            // Execute test
            Test.startTest();
            update ipsgUpdateList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT reduivy__Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );
		
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

			System.Assert.areEqual(
				IPS_GROUP_NOTSTARTED_STATUSES.get(0),
				ips.reduivy__Status__c,
				'The actual value should be as expected'
			);
			
			System.Assert.areEqual(
				0, ips.reduivy__Completion_Percentage__c,
				'The actual value should be as expected'
			);
		}
	}
	
    /**
     * @description Test as a student user that the individual plan structure (group) status is updated to in-progress
     */
    @isTest
    static void testH_IpsGroupStatusInProgressAsStudent() {
	
        // Setup test data

        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits__c, reduivy__Credits_Enrolled__c, reduivy__Credits_Earned__c, 
                    reduivy__Units_Required__c, reduivy__Units_Enrolled__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Completion_Percentage__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN :studentContacts
            AND reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            LIMIT :IPSG_QTY
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        Integer index;
        Set<Id> ipsgIdSet = new Set<Id>();
        List<reduivy__Individual_Plan_Structure__c> ipsgUpdateList = new List<reduivy__Individual_Plan_Structure__c>();
		
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {
		
            ipsgIdSet.add(ipsg.Id);
            index = ipsgList.indexOf(ipsg);
            
            if (index < (ipsgList.size()/2)) {
            
                ipsg.reduivy__Credits__c = (2 * CREDITS_QTY);
                ipsg.reduivy__Credits_Enrolled__c = CREDITS_QTY;
                ipsg.reduivy__Credits_Earned__c = 0;

                ipsg.reduivy__Units_Required__c = null;
                ipsg.reduivy__Units_Enrolled__c = null;
                ipsg.reduivy__Units_Passed__c = null;
                ipsg.reduivy__Units_Contributed__c = null;
                
            } else {
            
                ipsg.reduivy__Credits__c = null;
                ipsg.reduivy__Credits_Enrolled__c = null;
                ipsg.reduivy__Credits_Earned__c = null;

                ipsg.reduivy__Units_Required__c = (2 * UNITS_QTY);
                ipsg.reduivy__Units_Enrolled__c = UNITS_QTY;
                ipsg.reduivy__Units_Passed__c = 0;
                ipsg.reduivy__Units_Contributed__c = 0;
            }
            
            ipsgUpdateList.add(ipsg);
        }
		
        System.runAs(studentUser) {

            // Execute test
            Test.startTest();
            update ipsgUpdateList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT reduivy__Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );
		
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

			System.Assert.areEqual(
				IPS_GROUP_INPROGRESS_STATUSES.get(0),
				ips.reduivy__Status__c,
				'The actual value should be as expected'
			);
			
			System.Assert.areEqual(
				0, ips.reduivy__Completion_Percentage__c,
				'The actual value should be as expected'
			);
		}
	}
	

    /**
     * @description Test as a student user that the individual plan structure (group) status is updated to completed
     */
    @isTest
    static void testI_IpsGroupStatusCompleted_OptionalOnly_AsStudent() {
	
        // Setup test data

        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits__c, reduivy__Credits_Enrolled__c, reduivy__Credits_Earned__c, 
                    reduivy__Units_Required__c, reduivy__Units_Enrolled__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Completion_Percentage__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN :studentContacts
            AND reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            LIMIT :IPSG_QTY
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        Integer index;
        Set<Id> ipsgIdSet = new Set<Id>();
        List<reduivy__Individual_Plan_Structure__c> ipsgUpdateList = new List<reduivy__Individual_Plan_Structure__c>();
		
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {
		
            ipsgIdSet.add(ipsg.Id);
            index = ipsgList.indexOf(ipsg);
            
            if (index < (ipsgList.size()/2)) {
            
                ipsg.reduivy__Credits__c = (2 * CREDITS_QTY);
                ipsg.reduivy__Credits_Enrolled__c = ipsg.reduivy__Credits__c;
                ipsg.reduivy__Credits_Earned__c = ipsg.reduivy__Credits_Enrolled__c;

                ipsg.reduivy__Units_Required__c = null;
                ipsg.reduivy__Units_Enrolled__c = null;
                ipsg.reduivy__Units_Passed__c = null;
                ipsg.reduivy__Units_Contributed__c = null;
                
            } else {
            
                ipsg.reduivy__Credits__c = null;
                ipsg.reduivy__Credits_Enrolled__c = null;
                ipsg.reduivy__Credits_Earned__c = null;

                ipsg.reduivy__Units_Required__c = (2 * UNITS_QTY);
                ipsg.reduivy__Units_Enrolled__c = ipsg.reduivy__Units_Required__c;
                ipsg.reduivy__Units_Passed__c = ipsg.reduivy__Units_Enrolled__c;
                ipsg.reduivy__Units_Contributed__c = ipsg.reduivy__Units_Enrolled__c;
            }
            
            ipsgUpdateList.add(ipsg);
        }
		
        System.runAs(studentUser) {

            // Execute test
            Test.startTest();
            update ipsgUpdateList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT reduivy__Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );
		
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

			System.Assert.areEqual(
				IPS_GROUP_INPROGRESS_STATUSES.get(0),
				ips.reduivy__Status__c,
				'The actual value should be as expected'
			);
			
			System.Assert.areEqual(
				100, ips.reduivy__Completion_Percentage__c,
				'The actual value should be as expected'
			);
		}
	}

    /**
     * @description Test as a student user that the individual plan structure (group) status is updated to completed
     */
    @isTest
    static void testI_IpsGroupStatusCompleted_All_AsStudent() {
	
        // Setup test data

        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits__c, reduivy__Credits_Enrolled__c, reduivy__Credits_Earned__c, 
                    reduivy__Units_Required__c, reduivy__Units_Enrolled__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Completion_Percentage__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN :studentContacts
            AND reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            LIMIT :IPSG_QTY
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        Integer index;
        Set<Id> ipsgIdSet = new Set<Id>();
        List<reduivy__Individual_Plan_Structure__c> ipsgUpdateList = new List<reduivy__Individual_Plan_Structure__c>();
		
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {
		
            ipsgIdSet.add(ipsg.Id);
            index = ipsgList.indexOf(ipsg);
            ipsg.reduivy__Required_Children_Completed__c = true;
            
            if (index < (ipsgList.size()/2)) {
            
                ipsg.reduivy__Credits__c = (2 * CREDITS_QTY);
                ipsg.reduivy__Credits_Enrolled__c = ipsg.reduivy__Credits__c;
                ipsg.reduivy__Credits_Earned__c = ipsg.reduivy__Credits_Enrolled__c;

                ipsg.reduivy__Units_Required__c = null;
                ipsg.reduivy__Units_Enrolled__c = null;
                ipsg.reduivy__Units_Passed__c = null;
                ipsg.reduivy__Units_Contributed__c = null;
                
            } else {
            
                ipsg.reduivy__Credits__c = null;
                ipsg.reduivy__Credits_Enrolled__c = null;
                ipsg.reduivy__Credits_Earned__c = null;

                ipsg.reduivy__Units_Required__c = (2 * UNITS_QTY);
                ipsg.reduivy__Units_Enrolled__c = ipsg.reduivy__Units_Required__c;
                ipsg.reduivy__Units_Passed__c = ipsg.reduivy__Units_Enrolled__c;
                ipsg.reduivy__Units_Contributed__c = ipsg.reduivy__Units_Enrolled__c;
            }
            
            ipsgUpdateList.add(ipsg);
        }
		
        System.runAs(studentUser) {

            // Execute test
            Test.startTest();
            update ipsgUpdateList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT reduivy__Status__c, reduivy__Completion_Percentage__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );
		
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

			System.Assert.areEqual(
				IPS_GROUP_COMPLETED_STATUSES.get(0),
				ips.reduivy__Status__c,
				'The actual value should be as expected'
			);
			
			System.Assert.areEqual(
				100, ips.reduivy__Completion_Percentage__c,
				'The actual value should be as expected'
			);
		}
	}

    /**
     * @description Test as a student user that an update to an individual plan structure (group) rolls up to the parent individual plan structure (group)
     */
    @isTest
    static void testJ_IpsGroupRollUpToParentGroupAfterUpdateAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            LIMIT :IPSG_QTY
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        Set<Id> ipsgParentIdSet = new Set<Id>();
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            ipsgParentIdSet.add(ipsg.reduivy__Parent_Plan_Structure__c);

            ipsg.reduivy__Credits_Enrolled__c = ((ipsg.reduivy__Credits_Enrolled__c == null) ? 0 : ipsg.reduivy__Credits_Enrolled__c);
            ipsg.reduivy__Credits_Enrolled__c += CREDITS_QTY;

            ipsg.reduivy__Units_Enrolled__c = ((ipsg.reduivy__Units_Enrolled__c == null) ? 0 : ipsg.reduivy__Units_Enrolled__c);
            ++ipsg.reduivy__Units_Enrolled__c;

            ipsg.reduivy__Credits_Earned__c = (ipsg.reduivy__Credits_Earned__c == null) ? 0 : ipsg.reduivy__Credits_Earned__c;
            ipsg.reduivy__Credits_Earned__c += CREDITS_QTY;

            ipsg.reduivy__Units_Passed__c = (ipsg.reduivy__Units_Passed__c == null) ? 0 : ipsg.reduivy__Units_Passed__c;
            ipsg.reduivy__Units_Passed__c += UNITS_QTY;

            ipsg.reduivy__Units_Contributed__c = (ipsg.reduivy__Units_Contributed__c == null) ? 0 : ipsg.reduivy__Units_Contributed__c;
            ipsg.reduivy__Units_Contributed__c += UNITS_QTY;
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            update ipsgList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    (select reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                            reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c
                     from reduivy__Individual_Plan_Structures__r
                     where RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
                     and reduivy__Parent_Plan_Structure__c != null)
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgParentIdSet
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsg : ips.reduivy__Individual_Plan_Structures__r) {
                expectedCreditsEnrolled += ipsg.reduivy__Credits_Enrolled__c;
                expectedUnitsEnrolled += ipsg.reduivy__Units_Enrolled__c;
                expectedCreditsEarned += ipsg.reduivy__Credits_Earned__c;
                expectedUnitsPassed += ipsg.reduivy__Units_Passed__c;
                expectedUnitsContributed += ipsg.reduivy__Units_Contributed__c;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ips.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ips.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ips.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ips.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsContributed,
                ips.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a faculty user that an update to an individual plan structure (group) rolls up to the parent individual plan structure (group)
     */
    @isTest
    static void testK_IpsGroupRollUpToParentGroupAfterUpdateAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            LIMIT :IPSG_QTY
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        Set<Id> ipsgParentIdSet = new Set<Id>();
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            ipsgParentIdSet.add(ipsg.reduivy__Parent_Plan_Structure__c);

            ipsg.reduivy__Credits_Enrolled__c = ((ipsg.reduivy__Credits_Enrolled__c == null) ? 0 : ipsg.reduivy__Credits_Enrolled__c);
            ipsg.reduivy__Credits_Enrolled__c += CREDITS_QTY;

            ipsg.reduivy__Units_Enrolled__c = ((ipsg.reduivy__Units_Enrolled__c == null) ? 0 : ipsg.reduivy__Units_Enrolled__c);
            ++ipsg.reduivy__Units_Enrolled__c;

            ipsg.reduivy__Credits_Earned__c = (ipsg.reduivy__Credits_Earned__c == null) ? 0 : ipsg.reduivy__Credits_Earned__c;
            ipsg.reduivy__Credits_Earned__c += CREDITS_QTY;

            ipsg.reduivy__Units_Passed__c = (ipsg.reduivy__Units_Passed__c == null) ? 0 : ipsg.reduivy__Units_Passed__c;
            ipsg.reduivy__Units_Passed__c += UNITS_QTY;

            ipsg.reduivy__Units_Contributed__c = (ipsg.reduivy__Units_Contributed__c == null) ? 0 : ipsg.reduivy__Units_Contributed__c;
            ipsg.reduivy__Units_Contributed__c += UNITS_QTY;
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            update ipsgList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    (select reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                            reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c
                     from reduivy__Individual_Plan_Structures__r
                     where RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
                     and reduivy__Parent_Plan_Structure__c != null)
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgParentIdSet
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;
            
            for (reduivy__Individual_Plan_Structure__c ipsg : ips.reduivy__Individual_Plan_Structures__r) {
                expectedCreditsEnrolled += ipsg.reduivy__Credits_Enrolled__c;
                expectedUnitsEnrolled += ipsg.reduivy__Units_Enrolled__c;
                expectedCreditsEarned += ipsg.reduivy__Credits_Earned__c;
                expectedUnitsPassed += ipsg.reduivy__Units_Passed__c;
                expectedUnitsContributed += ipsg.reduivy__Units_Contributed__c;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ips.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ips.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ips.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ips.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsContributed,
                ips.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a student user that an update to an individual plan structure (group) rolls up to the parent individual plan structure (group)
     */
    @isTest
    static void testL_IpsGroupRollUpToParentGroupAfterUpdateAsStudent() {

        // Setup test data

        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN :studentContacts
            AND reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            LIMIT :IPSG_QTY
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        List<reduivy__Individual_Plan_Structure__c> ipsgUpdateList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgParentIdSet = new Set<Id>();
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            ipsgParentIdSet.add(ipsg.reduivy__Parent_Plan_Structure__c);

            ipsg.reduivy__Credits_Enrolled__c = ((ipsg.reduivy__Credits_Enrolled__c == null) ? 0 : ipsg.reduivy__Credits_Enrolled__c);
            ipsg.reduivy__Credits_Enrolled__c += CREDITS_QTY;

            ipsg.reduivy__Units_Enrolled__c = ((ipsg.reduivy__Units_Enrolled__c == null) ? 0 : ipsg.reduivy__Units_Enrolled__c);
            ++ipsg.reduivy__Units_Enrolled__c;

            ipsg.reduivy__Credits_Earned__c = (ipsg.reduivy__Credits_Earned__c == null) ? 0 : ipsg.reduivy__Credits_Earned__c;
            ipsg.reduivy__Credits_Earned__c += CREDITS_QTY;

            ipsg.reduivy__Units_Passed__c = (ipsg.reduivy__Units_Passed__c == null) ? 0 : ipsg.reduivy__Units_Passed__c;
            ipsg.reduivy__Units_Passed__c += UNITS_QTY;

            ipsg.reduivy__Units_Contributed__c = (ipsg.reduivy__Units_Contributed__c == null) ? 0 : ipsg.reduivy__Units_Contributed__c;
            ipsg.reduivy__Units_Contributed__c += UNITS_QTY;

            ipsgUpdateList.add(ipsg);
        }

        System.runAs(studentUser) {

            // Execute test
            Test.startTest();
            update ipsgUpdateList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    (select reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                            reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c
                     from reduivy__Individual_Plan_Structures__r
                     where RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
                     and reduivy__Parent_Plan_Structure__c != null)
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgParentIdSet
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;
            
            for (reduivy__Individual_Plan_Structure__c ipsg : ips.reduivy__Individual_Plan_Structures__r) {
                expectedCreditsEnrolled += ipsg.reduivy__Credits_Enrolled__c;
                expectedUnitsEnrolled += ipsg.reduivy__Units_Enrolled__c;
                expectedCreditsEarned += ipsg.reduivy__Credits_Earned__c;
                expectedUnitsPassed += ipsg.reduivy__Units_Passed__c;
                expectedUnitsContributed += ipsg.reduivy__Units_Contributed__c;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ips.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ips.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ips.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ips.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsContributed,
                ips.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as an admin user that deletion of an individual plan structure (group) rolls up to the parent individual plan structure (group)
     */
    @isTest
    static void testM_IpsGroupRollUpToParentGroupAfterDeleteAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            LIMIT :IPSG_QTY
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        Set<Id> ipsgIdSet = new Set<Id>();
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            ipsgIdSet.add(ipsg.Id);

            ipsg.reduivy__Credits_Enrolled__c = ((ipsg.reduivy__Credits_Enrolled__c == null) ? 0 : ipsg.reduivy__Credits_Enrolled__c);
            ipsg.reduivy__Credits_Enrolled__c += CREDITS_QTY;

            ipsg.reduivy__Units_Enrolled__c = ((ipsg.reduivy__Units_Enrolled__c == null) ? 0 : ipsg.reduivy__Units_Enrolled__c);
            ++ipsg.reduivy__Units_Enrolled__c;

            ipsg.reduivy__Credits_Earned__c = (ipsg.reduivy__Credits_Earned__c == null) ? 0 : ipsg.reduivy__Credits_Earned__c;
            ipsg.reduivy__Credits_Earned__c += CREDITS_QTY;

            ipsg.reduivy__Units_Passed__c = ((ipsg.reduivy__Units_Passed__c == null) ? 0 : ipsg.reduivy__Units_Passed__c);
            ++ipsg.reduivy__Units_Passed__c;

            ipsg.reduivy__Units_Contributed__c = ((ipsg.reduivy__Units_Contributed__c == null) ? 0 : ipsg.reduivy__Units_Contributed__c);
            ++ipsg.reduivy__Units_Contributed__c;
        }

        update ipsgList;

        // Verify pre-test conditions
        ipsgList = [
            SELECT  reduivy__Parent_Plan_Structure__r.reduivy__Credits_Enrolled__c,
                    reduivy__Parent_Plan_Structure__r.reduivy__Units_Enrolled__c,
                    reduivy__Parent_Plan_Structure__r.reduivy__Credits_Earned__c,
                    reduivy__Parent_Plan_Structure__r.reduivy__Units_Passed__c,
                    reduivy__Parent_Plan_Structure__r.reduivy__Units_Contributed__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            System.Assert.isTrue(
                ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Credits_Enrolled__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Units_Enrolled__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Credits_Earned__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Units_Passed__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Units_Contributed__c > 0,
                'The actual value should be as expected'
            );
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            delete ipsgList;
            Test.stopTest();
		}

        // Verify test results
        for (reduivy__Individual_Plan_Structure__c ipsg : [
            SELECT  reduivy__Parent_Plan_Structure__r.reduivy__Credits_Enrolled__c,
                    reduivy__Parent_Plan_Structure__r.reduivy__Units_Enrolled__c,
                    reduivy__Parent_Plan_Structure__r.reduivy__Credits_Earned__c,
                    reduivy__Parent_Plan_Structure__r.reduivy__Units_Passed__c,
                    reduivy__Parent_Plan_Structure__r.reduivy__Units_Contributed__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ]) {
            System.Assert.areEqual(
                0, ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                0, ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );
            System.Assert.areEqual(
                0, ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                0, ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                0, ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a faculty user that deletion of an individual plan structure (group) rolls up to the parent individual plan structure (group)
     */
    @isTest
    static void testN_IpsGroupRollUpToParentGroupAfterDeleteAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            LIMIT :IPSG_QTY
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        Set<Id> ipsgIdSet = new Set<Id>();
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            ipsgIdSet.add(ipsg.Id);

            ipsg.reduivy__Credits_Enrolled__c = ((ipsg.reduivy__Credits_Enrolled__c == null) ? 0 : ipsg.reduivy__Credits_Enrolled__c);
            ipsg.reduivy__Credits_Enrolled__c += CREDITS_QTY;

            ipsg.reduivy__Units_Enrolled__c = ((ipsg.reduivy__Units_Enrolled__c == null) ? 0 : ipsg.reduivy__Units_Enrolled__c);
            ++ipsg.reduivy__Units_Enrolled__c;

            ipsg.reduivy__Credits_Earned__c = (ipsg.reduivy__Credits_Earned__c == null) ? 0 : ipsg.reduivy__Credits_Earned__c;
            ipsg.reduivy__Credits_Earned__c += CREDITS_QTY;

            ipsg.reduivy__Units_Passed__c = ((ipsg.reduivy__Units_Passed__c == null) ? 0 : ipsg.reduivy__Units_Passed__c);
            ++ipsg.reduivy__Units_Passed__c;

            ipsg.reduivy__Units_Contributed__c = ((ipsg.reduivy__Units_Contributed__c == null) ? 0 : ipsg.reduivy__Units_Contributed__c);
            ++ipsg.reduivy__Units_Contributed__c;
        }

        update ipsgList;

        // Verify pre-test conditions
        ipsgList = [
            SELECT  reduivy__Parent_Plan_Structure__r.reduivy__Credits_Enrolled__c,
                    reduivy__Parent_Plan_Structure__r.reduivy__Units_Enrolled__c,
                    reduivy__Parent_Plan_Structure__r.reduivy__Credits_Earned__c,
                    reduivy__Parent_Plan_Structure__r.reduivy__Units_Passed__c,
                    reduivy__Parent_Plan_Structure__r.reduivy__Units_Contributed__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            System.Assert.isTrue(
                ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Credits_Enrolled__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Units_Enrolled__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Credits_Earned__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Units_Passed__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Units_Contributed__c > 0,
                'The actual value should be as expected'
            );
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();

            try {
                delete ipsgList;
                System.Assert.fail('This should fail with insufficient access error.');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'));
            }

            Test.stopTest();
		}
    }

    /**
     * @description Test as a student user that deletion of an individual plan structure (group) rolls up to the parent individual plan structure (group)
     */
    @isTest
    static void testO_IpsGroupRollUpToParentGroupAfterDeleteAsStudent() {

        // Setup test data

        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN :studentContacts
            AND reduivy__Parent_Plan_Structure__c != null
            AND reduivy__Parent_Plan_Structure__r.reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            LIMIT :IPSG_QTY
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain individual plan structure (group) records'
        );

        Set<Id> ipsgIdSet = new Set<Id>();
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            ipsgIdSet.add(ipsg.Id);

            ipsg.reduivy__Credits_Enrolled__c = ((ipsg.reduivy__Credits_Enrolled__c == null) ? 0 : ipsg.reduivy__Credits_Enrolled__c);
            ipsg.reduivy__Credits_Enrolled__c += CREDITS_QTY;

            ipsg.reduivy__Units_Enrolled__c = ((ipsg.reduivy__Units_Enrolled__c == null) ? 0 : ipsg.reduivy__Units_Enrolled__c);
            ++ipsg.reduivy__Units_Enrolled__c;

            ipsg.reduivy__Credits_Earned__c = (ipsg.reduivy__Credits_Earned__c == null) ? 0 : ipsg.reduivy__Credits_Earned__c;
            ipsg.reduivy__Credits_Earned__c += CREDITS_QTY;

            ipsg.reduivy__Units_Passed__c = ((ipsg.reduivy__Units_Passed__c == null) ? 0 : ipsg.reduivy__Units_Passed__c);
            ++ipsg.reduivy__Units_Passed__c;

            ipsg.reduivy__Units_Contributed__c = ((ipsg.reduivy__Units_Contributed__c == null) ? 0 : ipsg.reduivy__Units_Contributed__c);
            ++ipsg.reduivy__Units_Contributed__c;
        }

        update ipsgList;

        // Verify pre-test conditions
        ipsgList = [
            SELECT  reduivy__Parent_Plan_Structure__r.reduivy__Credits_Enrolled__c,
                    reduivy__Parent_Plan_Structure__r.reduivy__Units_Enrolled__c,
                    reduivy__Parent_Plan_Structure__r.reduivy__Credits_Earned__c,
                    reduivy__Parent_Plan_Structure__r.reduivy__Units_Passed__c,
                    reduivy__Parent_Plan_Structure__r.reduivy__Units_Contributed__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            System.Assert.isTrue(
                ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Credits_Enrolled__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Units_Enrolled__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Credits_Earned__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Units_Passed__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Parent_Plan_Structure__r.reduivy__Units_Contributed__c > 0,
                'The actual value should be as expected'
            );
        }

        System.runAs(studentUser) {

            // Execute test
            Test.startTest();

            try {
                delete ipsgList;
                System.Assert.fail('This should fail with insufficient access error.');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'));
            }

            Test.stopTest();
		}
    }
}