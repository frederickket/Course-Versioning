/**
 * @author      WDCi (dblack)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for IPS_ResetStatus_EXE
 * @changehistory
 * ISS-001831 19-12-2023 dblack - new class
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@isTest
public inherited sharing class IPS_ResetStatus_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';
    
    static final List<String> IPE_INPROGRESS_STATUSES = IPE_Helper.getInProgressStatuses();

    static final Integer IPE_QTY = 2;
    static final Integer IEN_QTY = 2;

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

			testFactory.initMasterData(SPS_Helper.getApiName());
            testFactory.initOfferingData(SOF_Helper.getApiName());
			testFactory.initStudentData(IPF_Helper.getApiName(), true);

            List<reduivy__Individual_Program_Enrollment__c> newIpeList = new List<reduivy__Individual_Program_Enrollment__c>();
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
				Id idvAcademicProfileId = testFactory.individualAcademicProfiles.get(student.reduivy__Sample_Record_Code__c).Id;
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

                newIpeList.add(ipe);
			}
			
			insert newIpeList;

            // Get student
            List<Contact> studentContacts = [
                SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
            ];
            User studentUser = [
                SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
            ];

            // Get the individual program enrollment records
            List<reduivy__Individual_Program_Enrollment__c> ipeList = [
                SELECT Id FROM reduivy__Individual_Program_Enrollment__c LIMIT :IPE_QTY
            ];

			System.Assert.isFalse(
				ipeList.isEmpty(),
				'The list should contain individual program enrollment records'
			);

			// Get study unit, study plan structure and study offering records
			Map<Id, Id> spsMap = new Map<Id, Id>();
            Map<Id, Id> sofMap = new Map<Id, Id>();
			List<reduivy__Study_Unit__c> sunList = [
				SELECT 	Id, reduivy__Unit_Code__c,
						(select Id from reduivy__Study_Plan_Structures__r limit 1),
                        (select Id from reduivy__Study_Offerings__r limit 1)
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
					sun.reduivy__Study_Plan_Structures__r.isEmpty(),
					'The list should contain study plan structure records'
				);

				spsMap.put(sun.Id, sun.reduivy__Study_Plan_Structures__r.get(0).Id);

				System.Assert.isFalse(
					sun.reduivy__Study_Offerings__r.isEmpty(),
					'The list should contain study offering records'
				);

				sofMap.put(sun.Id, sun.reduivy__Study_Offerings__r.get(0).Id);
			}

            Test.startTest();
            // Create individual enrollment records
            Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Unit__c sun : sunList) {

                String sampleRecordCode = null;
                Id contactId = studentUser.ContactId;
                Id studyOfferingId = sofMap.get(sun.Id);
                String enrollmentStatus = 'Enrolled';
                Decimal attemptNumber = null;
                Date enrollmentDate = null;
                Date startDate = null;
                Date endDate = null;
                Date censusDate = null;
                Decimal creditsOffered = null;
                Id idvAcademicProgressId = null;
                Id idvAcademicProfileId = null;

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

                ienMap.put(sun.Id, ien);
            }

            insert ienMap.values();

            // Create the individual plan structure records
            List<reduivy__Individual_Plan_Structure__c> ipsList = new List<reduivy__Individual_Plan_Structure__c>();
            for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
                for (reduivy__Study_Unit__c sun : sunList) {

                    String sampleRecordCode = null;
                    Id individualProgramEnrollmentId = ipe.Id;
                    Id parentPlanStructureId = null;
                    Id unitStudyPlanStructureId = spsMap.get(sun.Id);
                    String category = null;
                    Decimal credits = null;
                    Boolean isPrimary = true;
                    String status = 'In Progress';

                    reduivy__Individual_Plan_Structure__c ips = REDU_TestData_UTIL.newIndividualUnitPlanStructure(
                        sampleRecordCode,
                        individualProgramEnrollmentId,
                        parentPlanStructureId,
                        unitStudyPlanStructureId,
                        category,
                        credits,
                        isPrimary,
                        status
                    );

                    ips.reduivy__Individual_Enrollment__c = ienMap.get(sun.Id).Id;

                    ipsList.add(ips);
                }
            }

            insert ipsList;

            Test.stopTest();
        }
    }
	
    /**
     * @description Test as an admin user the individual plan structure (unit) status is reset to 'Not Started' when the individual enrollment is unlinked
     */
    @isTest
    static void testIpsStatusIsResetToNotStartedWhenIenUnlinkedAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Set up test data

        Test.startTest();
        List<String> ipsUnitNotStartedStatuses = IPS_Helper.getUnitNotStartedStatuses();

        List<reduivy__Individual_Plan_Structure__c> ipsuList = [
            SELECT reduivy__Individual_Enrollment__c, reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Enrollment__c != null
            AND reduivy__Status__c NOT IN :ipsUnitNotStartedStatuses
        ];

        System.Assert.isFalse(
            ipsuList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Set<Id> ipsuIdSet = new Set<Id>();
        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

            ipsuIdSet.add(ipsu.Id);
            ipsu.reduivy__Individual_Enrollment__c = null;
        }

		System.runAs(ADMIN_USER) {

            // Execute test
            update ipsuList;	
		}

        // Verify test result
        for (reduivy__Individual_Plan_Structure__c ipsu : [
            SELECT reduivy__Status__c FROM reduivy__Individual_Plan_Structure__c WHERE Id IN :ipsuIdSet
        ]) {
            System.Assert.isTrue(
                ipsUnitNotStartedStatuses.contains(ipsu.reduivy__Status__c),
                'The individual plan structure (unit) status should be Not Started'
            );
        }
        Test.stopTest();	
    }

    /**
     * @description Test as a faculty user the individual plan structure (unit) status is reset to 'Not Started' when the individual enrollment is unlinked
     */
    @isTest
    static void testIpsStatusIsResetToNotStartedWhenIenUnlinkedAsFaculty() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Set up test data
        Test.startTest();

        List<String> ipsUnitNotStartedStatuses = IPS_Helper.getUnitNotStartedStatuses();

        List<reduivy__Individual_Plan_Structure__c> ipsuList = [
            SELECT reduivy__Individual_Enrollment__c, reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Enrollment__c != null
            AND reduivy__Status__c NOT IN :ipsUnitNotStartedStatuses
        ];

        System.Assert.isFalse(
            ipsuList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Set<Id> ipsuIdSet = new Set<Id>();
        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

            ipsuIdSet.add(ipsu.Id);
            ipsu.reduivy__Individual_Enrollment__c = null;
        }

		System.runAs(FACULTY_USER) {

            // Execute test
            update ipsuList;		
		}

        // Verify test result
        for (reduivy__Individual_Plan_Structure__c ipsu : [
            SELECT reduivy__Status__c FROM reduivy__Individual_Plan_Structure__c WHERE Id IN :ipsuIdSet
        ]) {
            System.Assert.isTrue(
                ipsUnitNotStartedStatuses.contains(ipsu.reduivy__Status__c),
                'The individual plan structure (unit) status should be Not Started'
            );
        }
        Test.stopTest();
    }

    /**
     * @description Test as a student user the individual plan structure (unit) status is reset to 'Not Started' when the individual enrollment is unlinked
     */
    @isTest
    static void testIpsStatusIsResetToNotStartedWhenIenUnlinkedAsStudent() {
	
        // Set up test data

        Test.startTest();
        List<String> ipsUnitNotStartedStatuses = IPS_Helper.getUnitNotStartedStatuses();

        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        List<reduivy__Individual_Plan_Structure__c> ipsuList = [
            SELECT  reduivy__Individual_Enrollment__c, reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN :studentContacts
            AND reduivy__Individual_Enrollment__c != null
            AND reduivy__Status__c NOT IN :ipsUnitNotStartedStatuses
        ];

        System.Assert.isFalse(
            ipsuList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Set<Id> ipsuIdSet = new Set<Id>();
        List<reduivy__Individual_Plan_Structure__c> ipsuUpdateList = new List<reduivy__Individual_Plan_Structure__c>();
        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

            ipsuIdSet.add(ipsu.Id);
            ipsu.reduivy__Individual_Enrollment__c = null;
            ipsuUpdateList.add(ipsu);
        }

		System.runAs(studentUser) {

            // Execute test
            update ipsuUpdateList;
		}

        // Verify test result
        for (reduivy__Individual_Plan_Structure__c ipsu : [
            SELECT reduivy__Status__c FROM reduivy__Individual_Plan_Structure__c WHERE Id IN :ipsuIdSet
        ]) {
            System.Assert.isTrue(
                ipsUnitNotStartedStatuses.contains(ipsu.reduivy__Status__c),
                'The individual plan structure (unit) status should be Not Started'
            );
        }
        Test.stopTest();
    }	
}