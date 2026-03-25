/**
 * @author      WDCi (dblack)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for IEN_SetUnitIpsStatus_EXE
 * @changehistory
 * ISS-001768 12-12-2023 dblack - new class
 * ISS-002033 24-07-2024 Sueanne - update test to check IPS status when letter grade is updated
 * ISS-002486 11-06-2025 XiRouh - Updated to assign the completed status according to the grade result
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@isTest
public inherited sharing class IEN_SetUnitIpsStatus_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final Integer IEN_QTY = 2;

    static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';

    static String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);

    static final String IEN_COMPLETED_PASS_STATUS = IEN_Helper.getCompletedPassStatuses().get(0);
    static final String IEN_COMPLETED_FAIL_STATUS = IEN_Helper.getCompletedFailStatuses().get(0);

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
			testFactory.initOfferingData(SOF_Helper.getApiName());
            testFactory.initStudentData(IPR_Helper.getApiName(), true);

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
				String enrollmentStatus = IPE_INPROGRESS_STATUS;
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

				ipeList.add(ipe);
			}
			
			insert ipeList;

            Test.stopTest();

        }
    }
	
    /**
     * @description Test as an admin user when an individual enrollment is created, the status of the individual plan structure (unit) is updated
     */
    @isTest
    static void testIpsuStatusWhenIenCreatedAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        // Setup test data
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN : studentContacts LIMIT 1];

        // Get study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT 	Id, (select Id from reduivy__Study_Offerings__r limit 1)
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

        // Create the individual enrollment records
        for (reduivy__Study_Unit__c sun : sunList) {

            for (Contact student : studentContacts) {
                String sampleRecordCode = null;
                Id contactId = student.Id;
                Id studyOfferingId = sofMap.get(sun.Id);
                String enrollmentStatus = IEN_COMPLETED_FAIL_STATUS;
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

                ien.reduivy__Grade_Result__c = 'Fail';

                ienList.add(ien);
            }
        }

        // Execute test
        Test.startTest();
		System.runAs(ADMIN_USER) {

            insert ienList;

            // Verify test results
            List<reduivy__Individual_Plan_Structure__c> ipsList = [
                SELECT reduivy__Status__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Enrollment__c IN: ienList
            ];

            System.Assert.isFalse(
                ipsList.isEmpty(),
                'The list should contain individual plan structure records'
            );

            for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

                System.Assert.areEqual(
                    'Failed',
                    ips.reduivy__Status__c,
                    'The actual value should be as expected'
                );
            }
		}

        Test.stopTest();
    }

    /**
     * @description Test as an admin user when an individual enrollment status is updated, the status of the individual plan structure (unit) is updated
     */
    @isTest
    static void testIpsuStatusWhenIenStatusUpdatedAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        // Setup test data

        // Update the individual enrollment records

        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN : studentContacts LIMIT 1];

        // Get study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT 	Id, (select Id from reduivy__Study_Offerings__r limit 1)
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

        // Create the individual enrollment records
        for (reduivy__Study_Unit__c sun : sunList) {

            for (Contact student : studentContacts) {
                String sampleRecordCode = null;
                Id contactId = student.Id;
                Id studyOfferingId = sofMap.get(sun.Id);
                String enrollmentStatus = 'Enrolled';
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
        }

        // Execute test
        Test.startTest();
		System.runAs(ADMIN_USER) {

            insert ienList;

            // Verify test results
            List<reduivy__Individual_Plan_Structure__c> ipsList = [
                SELECT reduivy__Status__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Enrollment__c IN: ienList
            ];

            System.Assert.isFalse(
                ipsList.isEmpty(),
                'The list should contain individual plan structure records'
            );

            for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

                System.Assert.areEqual(
                    'In Progress',
                    ips.reduivy__Status__c,
                    'The actual value should be as expected'
                );
            }

            // Execute test
            for (reduivy__Individual_Enrollment__c ien : ienList) {
                ien.reduivy__Enrollment_Status__c = 'Withdrawn';
            }

            update ienList;

            // Verify test results
            List<reduivy__Individual_Plan_Structure__c> ipsList2 = [
                SELECT reduivy__Status__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Enrollment__c IN: ienList
            ];

            System.Assert.isFalse(
                ipsList2.isEmpty(),
                'The list should contain individual plan structure records'
            );

            for (reduivy__Individual_Plan_Structure__c ips : ipsList2) {

                System.Assert.areEqual(
                    'Withdrawn',
                    ips.reduivy__Status__c,
                    'The actual value should be as expected'
                );
            }
		}

        Test.stopTest();
    }

    /**
     * @description Test as an admin user when an individual enrollment grade is updated, the status of the individual plan structure (unit) is updated
     */
    @isTest
    static void testIpsuStatusWhenIenGradeUpdatedAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        // Setup test data

        // Update the individual enrollment records

        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN : studentContacts LIMIT 1];

        // Get study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT 	Id, (select Id from reduivy__Study_Offerings__r limit 1)
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

        // Create the individual enrollment records
        for (reduivy__Study_Unit__c sun : sunList) {

            for (Contact student : studentContacts) {
                String sampleRecordCode = null;
                Id contactId = student.Id;
                Id studyOfferingId = sofMap.get(sun.Id);
                String enrollmentStatus = 'Enrolled';
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
        }

        // Execute test
        Test.startTest();
		System.runAs(ADMIN_USER) {

            insert ienList;

            // Verify test results
            List<reduivy__Individual_Plan_Structure__c> ipsList = [
                SELECT reduivy__Status__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Enrollment__c IN: ienList
            ];

            System.Assert.isFalse(
                ipsList.isEmpty(),
                'The list should contain individual plan structure records'
            );

            for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

                System.Assert.areEqual(
                    'In Progress',
                    ips.reduivy__Status__c,
                    'The actual value should be as expected'
                );
            }

            // Execute test
            for (reduivy__Individual_Enrollment__c ien : ienList) {
                ien.reduivy__Letter_Grade__c = 'A';
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            }

            update ienList;

            // Verify test results
            List<reduivy__Individual_Plan_Structure__c> ipsList2 = [
                SELECT reduivy__Status__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Enrollment__c IN: ienList
            ];

            System.Assert.isFalse(
                ipsList2.isEmpty(),
                'The list should contain individual plan structure records'
            );

            for (reduivy__Individual_Plan_Structure__c ips : ipsList2) {

                System.Assert.areEqual(
                    IEN_COMPLETED_PASS_STATUS,
                    ips.reduivy__Status__c,
                    'The actual value should be as expected'
                );
            }
		}

        Test.stopTest();

    }

    /**
     * @description Test as a faculty user when an individual enrollment is created, the status of the individual plan structure (unit) is updated
     */
    @isTest
    static void testIpsuStatusWhenIenCreatedAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        // Setup test data
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN : studentContacts LIMIT 1];

        // Get study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT 	Id, (select Id from reduivy__Study_Offerings__r limit 1)
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

        // Create the individual enrollment records
        for (reduivy__Study_Unit__c sun : sunList) {

            for (Contact student : studentContacts) {
                String sampleRecordCode = null;
                Id contactId = student.Id;
                Id studyOfferingId = sofMap.get(sun.Id);
                String enrollmentStatus = IEN_COMPLETED_FAIL_STATUS;
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

                ien.reduivy__Grade_Result__c = 'Fail';

                ienList.add(ien);
            }
        }

        // Execute test
        Test.startTest();
		System.runAs(FACULTY_USER) {

            insert ienList;

            // Verify test results
            List<reduivy__Individual_Plan_Structure__c> ipsList = [
                SELECT reduivy__Status__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Enrollment__c IN: ienList
            ];

            System.Assert.isFalse(
                ipsList.isEmpty(),
                'The list should contain individual plan structure records'
            );

            for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

                System.Assert.areEqual(
                    'Failed',
                    ips.reduivy__Status__c,
                    'The actual value should be as expected'
                );
            }
		}

        Test.stopTest();
    }

    /**
     * @description Test as a faculty user when an individual enrollment status is updated, the status of the individual plan structure (unit) is updated
     */
    @isTest
    static void testIpsuStatusWhenIenStatusUpdatedAsFaculty() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Update the individual enrollment records

        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN : studentContacts LIMIT 1];

        // Get study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT 	Id, (select Id from reduivy__Study_Offerings__r limit 1)
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

        // Create the individual enrollment records
        for (reduivy__Study_Unit__c sun : sunList) {

            for (Contact student : studentContacts) {
                String sampleRecordCode = null;
                Id contactId = student.Id;
                Id studyOfferingId = sofMap.get(sun.Id);
                String enrollmentStatus = 'Enrolled';
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
        }

        // Execute test
        Test.startTest();
		System.runAs(FACULTY_USER) {

            insert ienList;

            // Verify test results
            List<reduivy__Individual_Plan_Structure__c> ipsList = [
                SELECT reduivy__Status__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Enrollment__c IN: ienList
            ];

            System.Assert.isFalse(
                ipsList.isEmpty(),
                'The list should contain individual plan structure records'
            );

            for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

                System.Assert.areEqual(
                    'In Progress',
                    ips.reduivy__Status__c,
                    'The actual value should be as expected'
                );
            }

            // Execute test
            for (reduivy__Individual_Enrollment__c ien : ienList) {
                ien.reduivy__Enrollment_Status__c = 'Withdrawn';
            }

            update ienList;

            // Verify test results
            List<reduivy__Individual_Plan_Structure__c> ipsList2 = [
                SELECT reduivy__Status__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Enrollment__c IN: ienList
            ];

            System.Assert.isFalse(
                ipsList2.isEmpty(),
                'The list should contain individual plan structure records'
            );

            for (reduivy__Individual_Plan_Structure__c ips : ipsList2) {

                System.Assert.areEqual(
                    'Withdrawn',
                    ips.reduivy__Status__c,
                    'The actual value should be as expected'
                );
            }
		}

        Test.stopTest();
    }

    /**
     * @description Test as an facculty user when an individual enrollment grade is updated, the status of the individual plan structure (unit) is updated
     */
    @isTest
    static void testIpsuStatusWhenIenGradeUpdatedAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Update the individual enrollment records

        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN : studentContacts LIMIT 1];

        // Get study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT 	Id, (select Id from reduivy__Study_Offerings__r limit 1)
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

        // Create the individual enrollment records
        for (reduivy__Study_Unit__c sun : sunList) {

            for (Contact student : studentContacts) {
                String sampleRecordCode = null;
                Id contactId = student.Id;
                Id studyOfferingId = sofMap.get(sun.Id);
                String enrollmentStatus = 'Enrolled';
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
        }

        // Execute test
        Test.startTest();
		System.runAs(FACULTY_USER) {

            insert ienList;

            // Verify test results
            List<reduivy__Individual_Plan_Structure__c> ipsList = [
                SELECT reduivy__Status__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Enrollment__c IN: ienList
            ];

            System.Assert.isFalse(
                ipsList.isEmpty(),
                'The list should contain individual plan structure records'
            );

            for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

                System.Assert.areEqual(
                    'In Progress',
                    ips.reduivy__Status__c,
                    'The actual value should be as expected'
                );
            }

            // Execute test
            for (reduivy__Individual_Enrollment__c ien : ienList) {
                ien.reduivy__Letter_Grade__c = 'A';
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            }

            update ienList;

            // Verify test results
            List<reduivy__Individual_Plan_Structure__c> ipsList2 = [
                SELECT reduivy__Status__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Enrollment__c IN: ienList
            ];

            System.Assert.isFalse(
                ipsList2.isEmpty(),
                'The list should contain individual plan structure records'
            );

            for (reduivy__Individual_Plan_Structure__c ips : ipsList2) {

                System.Assert.areEqual(
                    IEN_COMPLETED_PASS_STATUS,
                    ips.reduivy__Status__c,
                    'The actual value should be as expected'
                );
            }
		}

        Test.stopTest();

    }

    /**
     * @description Test as a student user when an individual enrollment is created, the status of the individual plan structure (unit) is updated
     */
    @isTest
    static void testIpsuStatusWhenIenCreatedAsStudent() {
	
        // Setup test data
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id, contactId FROM User WHERE ContactId IN: studentContacts];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        // Get study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT 	Id, (select Id from reduivy__Study_Offerings__r limit 1)
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

        // Create the individual enrollment records
        for (reduivy__Study_Unit__c sun : sunList) {

            for (Contact student : studentContacts) {
                String sampleRecordCode = null;
                Id contactId = student.Id;
                Id studyOfferingId = sofMap.get(sun.Id);
                String enrollmentStatus = IEN_COMPLETED_FAIL_STATUS;
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

                ien.reduivy__Grade_Result__c = 'Fail';

                ienList.add(ien);
            }
        }

        // Execute test
        Test.startTest();
		System.runAs(studentUser) {

            insert ienList;

            // Verify test results
            List<reduivy__Individual_Plan_Structure__c> ipsList = [
                SELECT reduivy__Status__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Enrollment__c IN: ienList
            ];

            System.Assert.isFalse(
                ipsList.isEmpty(),
                'The list should contain individual plan structure records'
            );

            for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

                System.Assert.areEqual(
                    'Failed',
                    ips.reduivy__Status__c,
                    'The actual value should be as expected'
                );
            }
		}

        Test.stopTest();
    }

    /**
     * @description Test as a student user when an individual enrollment status is updated, the status of the individual plan structure (unit) is updated
     */
    @isTest
    static void testIpsuStatusWhenIenStatusUpdatedAsStudent() {
	
        // Setup test data

        // Update the individual enrollment records

        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id, contactId FROM User WHERE ContactId IN: studentContacts];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        // Get study offering records
        Map<Id, Id> sofMap = new Map<Id, Id>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT 	Id, (select Id from reduivy__Study_Offerings__r limit 1)
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

        // Create the individual enrollment records
        for (reduivy__Study_Unit__c sun : sunList) {

            for (Contact student : studentContacts) {
                String sampleRecordCode = null;
                Id contactId = student.Id;
                Id studyOfferingId = sofMap.get(sun.Id);
                String enrollmentStatus = 'Enrolled';
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
        }

        // Execute test
        Test.startTest();
		System.runAs(studentUser) {

            insert ienList;

            // Verify test results
            List<reduivy__Individual_Plan_Structure__c> ipsList = [
                SELECT reduivy__Status__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Enrollment__c IN: ienList
            ];

            System.Assert.isFalse(
                ipsList.isEmpty(),
                'The list should contain individual plan structure records'
            );

            for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

                System.Assert.areEqual(
                    'In Progress',
                    ips.reduivy__Status__c,
                    'The actual value should be as expected'
                );
            }

            // Execute test
            for (reduivy__Individual_Enrollment__c ien : ienList) {
                ien.reduivy__Enrollment_Status__c = 'Withdrawn';
            }

            update ienList;

            // Verify test results
            List<reduivy__Individual_Plan_Structure__c> ipsList2 = [
                SELECT reduivy__Status__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Enrollment__c IN: ienList
            ];

            System.Assert.isFalse(
                ipsList2.isEmpty(),
                'The list should contain individual plan structure records'
            );

            for (reduivy__Individual_Plan_Structure__c ips : ipsList2) {

                System.Assert.areEqual(
                    'Withdrawn',
                    ips.reduivy__Status__c,
                    'The actual value should be as expected'
                );
            }
		}

        Test.stopTest();
    }
}