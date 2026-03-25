/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for IPW_AcademicProgress_EXE
 * @changehistory
 * ISS-001816 29-12-2023 Lean - new class
 */
@isTest
public inherited sharing class IPW_AcademicProgress_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);

    static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
		testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();

			testFactory.initMasterData(SPT_Helper.getApiName());
			testFactory.initOfferingData(STM_Helper.getApiName());
			testFactory.initStudentData(USR_Helper.getApiName(), true);

            Test.stopTest();
		}
    }
	
    /**
     * @description Test new individual pathway with academic term to trigger the academic progress creation with generation type = By IPE as admin
     */
    @IsTest
    static void testAcademicProgressWithNewIpwAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		// Get study program records
		Map<String, reduivy__Study_Program__c> spgMap = new Map<String, reduivy__Study_Program__c>();
		List<reduivy__Study_Program__c> spgList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Program__c
		];

		for (reduivy__Study_Program__c spg : spgList) {
			spgMap.put(spg.reduivy__Sample_Record_Code__c, spg);
		}

		// Get study plan records
		Map<String, reduivy__Study_Plan__c> splMap = new Map<String, reduivy__Study_Plan__c>();
		List<reduivy__Study_Plan__c> splList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c
		];

		for (reduivy__Study_Plan__c spl : splList) {
			splMap.put(spl.reduivy__Sample_Record_Code__c, spl);
		}

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

		List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
		Test.startTest();

		// Execute test
		System.runAs(ADMIN_USER) {

			// Create individual program enrollment records			
			for (Contact student : studentContacts) {
				String sampleRecordCode = student.Id + '_' + splMap.get(STUDY_PLAN).Id;
				Id contactId = student.Id;
				Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
				Id studyPlanId = splMap.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = academicTerm.Id;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = IPE_INPROGRESS_STATUS;
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
		}
	
		Test.stopTest();

		// Verify test results
		Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
			SELECT Id,
            reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__c,
            (
                SELECT Id, 
                reduivy__Academic_Term__c,
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c,
                reduivy__Term_Number__c,
                reduivy__Individual_Academic_Progress__c
                FROM reduivy__Individual_Pathways__r
                ORDER BY reduivy__Term_Number__c 
            )
			FROM reduivy__Individual_Program_Enrollment__c
		]);

        Map<Id, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<Id, reduivy__Individual_Academic_Profile__c>([
            SELECT Id,
            reduivy__Contact__c,
            (
                SELECT Id,
                reduivy__Contact__c,
                reduivy__Academic_Term__c,
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c,
                reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Academic_Progress__r
            )
            FROM reduivy__Individual_Academic_Profile__c
        ]);

        System.Assert.isFalse(ipeMap.isEmpty(), 'There should be ipe created.');
        System.Assert.isFalse(ipfMap.isEmpty(), 'There should be ipf created.');

        for (reduivy__Individual_Program_Enrollment__c ipe: ipeMap.values()) {

            reduivy__Individual_Pathway__c firstIpw;
            for (reduivy__Individual_Pathway__c ipw : ipe.reduivy__Individual_Pathways__r) {
                // Take the first ipw for assertion
                if (ipw.reduivy__Term_Number__c == 1) {
                    firstIpw = ipw;
                }
            }

            System.Assert.isNotNull(firstIpw, 'No ipw found for assertion.');
            System.Assert.areEqual(academicTerm.Id, firstIpw.reduivy__Academic_Term__c);
            System.Assert.isNotNull(firstIpw.reduivy__Individual_Academic_Progress__c);
            System.Assert.isNotNull(ipe.reduivy__Individual_Academic_Profile__c, 'The individual academic profile should be set.');
            
            integer foundIprCount = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipfMap.get(ipe.reduivy__Individual_Academic_Profile__c).reduivy__Individual_Academic_Progress__r) {
                if (ipr.reduivy__Academic_Term__c == firstIpw.reduivy__Academic_Term__c) {
                    foundIprCount ++;

                    System.Assert.areEqual(ipe.reduivy__Contact__c, ipr.reduivy__Contact__c);
                    System.Assert.areEqual(ipe.reduivy__Individual_Academic_Profile__c, ipr.reduivy__Individual_Academic_Profile__c);
                    System.Assert.areEqual(firstIpw.reduivy__Academic_Term__c, ipr.reduivy__Academic_Term__c);
                    System.Assert.areEqual(firstIpw.reduivy__Max_Credits__c, ipr.reduivy__Max_Credits__c);
                    System.Assert.areEqual(firstIpw.reduivy__Recommended_Credits__c, ipr.reduivy__Recommended_Credits__c);
                }
            }

            System.Assert.areEqual(1, foundIprCount, 'There is no ipr found that matches the ipf and academic term set on the ipw.');
        }

	}

    /**
     * @description Test update of individual pathway to create trigger the academic progress creation with generation type = By IPE as admin
     */
    @IsTest
    static void testAcademicProgressWithExistingIpwAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		// Get study program records
		Map<String, reduivy__Study_Program__c> spgMap = new Map<String, reduivy__Study_Program__c>();
		List<reduivy__Study_Program__c> spgList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Program__c
		];

		for (reduivy__Study_Program__c spg : spgList) {
			spgMap.put(spg.reduivy__Sample_Record_Code__c, spg);
		}

		// Get study plan records
		Map<String, reduivy__Study_Plan__c> splMap = new Map<String, reduivy__Study_Plan__c>();
		List<reduivy__Study_Plan__c> splList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c
		];

		for (reduivy__Study_Plan__c spl : splList) {
			splMap.put(spl.reduivy__Sample_Record_Code__c, spl);
		}

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

		Test.startTest();

        List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();

		// Execute test
		System.runAs(ADMIN_USER) {

			// Create individual program enrollment records			
			for (Contact student : studentContacts) {
				String sampleRecordCode = student.Id + '_' + splMap.get(STUDY_PLAN).Id;
				Id contactId = student.Id;
				Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
				Id studyPlanId = splMap.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = null;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = IPE_INPROGRESS_STATUS;
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
		}
	
		Test.stopTest();

		// Verify test results
        List<reduivy__Individual_Pathway__c> ipwUpdateList = new List<reduivy__Individual_Pathway__c>();

		Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
			SELECT Id,
            reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__c,
            (
                SELECT Id, 
                reduivy__Academic_Term__c,
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c,
                reduivy__Term_Number__c,
                reduivy__Individual_Academic_Progress__c
                FROM reduivy__Individual_Pathways__r
                ORDER BY reduivy__Term_Number__c 
            )
			FROM reduivy__Individual_Program_Enrollment__c
		]);

        Map<Id, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<Id, reduivy__Individual_Academic_Profile__c>([
            SELECT Id,
            reduivy__Contact__c,
            (
                SELECT Id,
                reduivy__Contact__c,
                reduivy__Academic_Term__c,
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c,
                reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Academic_Progress__r
            )
            FROM reduivy__Individual_Academic_Profile__c
        ]);

        System.Assert.isFalse(ipeMap.isEmpty(), 'There should be ipe created.');
        System.Assert.isFalse(ipfMap.isEmpty(), 'There should be ipf created.');

        for (reduivy__Individual_Program_Enrollment__c ipe: ipeMap.values()) {

            reduivy__Individual_Pathway__c firstIpw;
            for (reduivy__Individual_Pathway__c ipw : ipe.reduivy__Individual_Pathways__r) {
                // Take the first ipw for assertion
                if (ipw.reduivy__Term_Number__c == 1) {
                    firstIpw = ipw;
                }
            }

            System.Assert.isNotNull(firstIpw, 'No ipw found for assertion.');
            System.Assert.isNull(firstIpw.reduivy__Academic_Term__c);
            System.Assert.isNotNull(ipe.reduivy__Individual_Academic_Profile__c, 'The individual academic profile should be set.');
            System.Assert.isTrue(ipfMap.get(ipe.reduivy__Individual_Academic_Profile__c).reduivy__Individual_Academic_Progress__r.isEmpty(), 'There should not be any individual academic progress created.');

            // set the academic term to simulate the update of ipw to trigger the ipr creation
            firstIpw.reduivy__Academic_Term__c = academicTerm.Id;
            ipwUpdateList.add(firstIpw);
        }

        System.runAs(ADMIN_USER) {
            update ipwUpdateList;
        }

        // Verify test results
		ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
			SELECT Id,
            reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__c,
            (
                SELECT Id, 
                reduivy__Academic_Term__c,
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c,
                reduivy__Term_Number__c,
                reduivy__Individual_Academic_Progress__c
                FROM reduivy__Individual_Pathways__r
                ORDER BY reduivy__Term_Number__c 
            )
			FROM reduivy__Individual_Program_Enrollment__c
		]);

        ipfMap = new Map<Id, reduivy__Individual_Academic_Profile__c>([
            SELECT Id,
            reduivy__Contact__c,
            (
                SELECT Id,
                reduivy__Contact__c,
                reduivy__Academic_Term__c,
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c,
                reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Academic_Progress__r
            )
            FROM reduivy__Individual_Academic_Profile__c
        ]);

        System.Assert.isFalse(ipeMap.isEmpty(), 'There should be ipe created.');
        System.Assert.isFalse(ipfMap.isEmpty(), 'There should be ipf created.');

        for (reduivy__Individual_Program_Enrollment__c ipe: ipeMap.values()) {

            reduivy__Individual_Pathway__c firstIpw;
            for (reduivy__Individual_Pathway__c ipw : ipe.reduivy__Individual_Pathways__r) {
                // Take the first ipw for assertion
                if (ipw.reduivy__Term_Number__c == 1) {
                    firstIpw = ipw;
                }
            }

            System.Assert.isNotNull(firstIpw, 'No ipw found for assertion.');
            System.Assert.areEqual(academicTerm.Id, firstIpw.reduivy__Academic_Term__c);
            System.Assert.isNotNull(firstIpw.reduivy__Individual_Academic_Progress__c);
            System.Assert.isNotNull(ipe.reduivy__Individual_Academic_Profile__c, 'The individual academic profile should be set.');
            
            integer foundIprCount = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipfMap.get(ipe.reduivy__Individual_Academic_Profile__c).reduivy__Individual_Academic_Progress__r) {
                if (ipr.reduivy__Academic_Term__c == firstIpw.reduivy__Academic_Term__c) {
                    foundIprCount ++;

                    System.Assert.areEqual(ipe.reduivy__Contact__c, ipr.reduivy__Contact__c);
                    System.Assert.areEqual(ipe.reduivy__Individual_Academic_Profile__c, ipr.reduivy__Individual_Academic_Profile__c);
                    System.Assert.areEqual(firstIpw.reduivy__Academic_Term__c, ipr.reduivy__Academic_Term__c);
                    System.Assert.areEqual(firstIpw.reduivy__Max_Credits__c, ipr.reduivy__Max_Credits__c);
                    System.Assert.areEqual(firstIpw.reduivy__Recommended_Credits__c, ipr.reduivy__Recommended_Credits__c);
                }
            }

            System.Assert.areEqual(1, foundIprCount, 'There is no ipr found that matches the ipf and academic term set on the ipw.');
        }
	}

    /**
     * @description Test exception
     */
    @IsTest
    static void testExceptionAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		// Get study program records
		Map<String, reduivy__Study_Program__c> spgMap = new Map<String, reduivy__Study_Program__c>();
		List<reduivy__Study_Program__c> spgList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Program__c
		];

		for (reduivy__Study_Program__c spg : spgList) {
			spgMap.put(spg.reduivy__Sample_Record_Code__c, spg);
		}

		// Get study plan records
		Map<String, reduivy__Study_Plan__c> splMap = new Map<String, reduivy__Study_Plan__c>();
		List<reduivy__Study_Plan__c> splList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c
		];

		for (reduivy__Study_Plan__c spl : splList) {
			splMap.put(spl.reduivy__Sample_Record_Code__c, spl);
		}

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

		Test.startTest();

        List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();

		// Execute test
		System.runAs(ADMIN_USER) {

			// Create individual program enrollment records			
			for (Contact student : studentContacts) {
				String sampleRecordCode = student.Id + '_' + splMap.get(STUDY_PLAN).Id;
				Id contactId = student.Id;
				Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
				Id studyPlanId = splMap.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = null;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = IPE_INPROGRESS_STATUS;
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
		}
	
		Test.stopTest();

		// Verify test results
        List<reduivy__Individual_Pathway__c> ipwUpdateList = new List<reduivy__Individual_Pathway__c>();

		Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
			SELECT Id,
            reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__c,
            (
                SELECT Id, 
                reduivy__Academic_Term__c,
                reduivy__Individual_Program_Enrollment__c,
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c,
                reduivy__Term_Number__c,
                reduivy__Individual_Academic_Progress__c
                FROM reduivy__Individual_Pathways__r
                ORDER BY reduivy__Term_Number__c 
            )
			FROM reduivy__Individual_Program_Enrollment__c
		]);

        Map<Id, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<Id, reduivy__Individual_Academic_Profile__c>([
            SELECT Id,
            reduivy__Contact__c,
            (
                SELECT Id,
                reduivy__Contact__c,
                reduivy__Academic_Term__c,
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c,
                reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Academic_Progress__r
            )
            FROM reduivy__Individual_Academic_Profile__c
        ]);

        System.Assert.isFalse(ipeMap.isEmpty(), 'There should be ipe created.');
        System.Assert.isFalse(ipfMap.isEmpty(), 'There should be ipf created.');

        for (reduivy__Individual_Program_Enrollment__c ipe: ipeMap.values()) {

            reduivy__Individual_Pathway__c firstIpw;
            for (reduivy__Individual_Pathway__c ipw : ipe.reduivy__Individual_Pathways__r) {
                // Take the first ipw for assertion
                if (ipw.reduivy__Term_Number__c == 1) {
                    firstIpw = ipw;
                }
            }

            System.Assert.isNotNull(firstIpw, 'No ipw found for assertion.');
            System.Assert.isNull(firstIpw.reduivy__Academic_Term__c);
            System.Assert.isNull(firstIpw.reduivy__Individual_Academic_Progress__c);
            System.Assert.isNotNull(ipe.reduivy__Individual_Academic_Profile__c, 'The individual academic profile should be set.');
            System.Assert.isTrue(ipfMap.get(ipe.reduivy__Individual_Academic_Profile__c).reduivy__Individual_Academic_Progress__r.isEmpty(), 'There should not be any individual academic progress created.');

            // set the academic term to simulate the update of ipw to trigger the ipr creation
            firstIpw.reduivy__Academic_Term__c = academicTerm.Id;
            ipwUpdateList.add(firstIpw);
        }

        // disable the triggers so that we can delete the IPF without error
        REDU_TriggerController.muteAllTriggers();
        delete ipfMap.values();
        REDU_TriggerController.unmuteAllTriggers();

        System.runAs(ADMIN_USER) {
            try {
                update ipwUpdateList;
                System.Assert.fail('This should fail with missing individual academic profile error.');

            } catch (Exception exp) {
                String recordUrl = REDU_OrganizationInfo_UTIL.getDomainUrl() + ipwUpdateList.get(0).reduivy__Individual_Program_Enrollment__c;
                String expectedError = String.format(Label.Missing_Info_For_Record, new List<String>{IPF_Helper.getObjectLabel(), IPE_Helper.getObjectLabel(), recordUrl});

                System.Assert.isTrue(exp.getMessage().contains(expectedError));
            }
        }
	}

    /**
     * @description Test new individual pathway with academic term to trigger the academic progress creation with generation type = By IPE as faculty
     */
    @IsTest
    static void testAcademicProgressWithNewIpwAsFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		// Get study program records
		Map<String, reduivy__Study_Program__c> spgMap = new Map<String, reduivy__Study_Program__c>();
		List<reduivy__Study_Program__c> spgList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Program__c
		];

		for (reduivy__Study_Program__c spg : spgList) {
			spgMap.put(spg.reduivy__Sample_Record_Code__c, spg);
		}

		// Get study plan records
		Map<String, reduivy__Study_Plan__c> splMap = new Map<String, reduivy__Study_Plan__c>();
		List<reduivy__Study_Plan__c> splList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c
		];

		for (reduivy__Study_Plan__c spl : splList) {
			splMap.put(spl.reduivy__Sample_Record_Code__c, spl);
		}

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

		List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
		Test.startTest();

		// Execute test
		System.runAs(FACULTY_USER) {

			// Create individual program enrollment records			
			for (Contact student : studentContacts) {
				String sampleRecordCode = student.Id + '_' + splMap.get(STUDY_PLAN).Id;
				Id contactId = student.Id;
				Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
				Id studyPlanId = splMap.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = academicTerm.Id;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = IPE_INPROGRESS_STATUS;
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
			
            try {
                insert ipeList;

                System.Assert.fail('Faculty user should not have permission to create reduivy__Individual_Program_Enrollment__c.');

            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(String.format(Label.Creation_Disallowed_Error, new List<String>{IPE_Helper.getObjectLabel()})), 'Unexpected error: ' + exp.getMessage());
            }
		}
	
		Test.stopTest();

	}

    /**
     * @description Test update of individual pathway to create trigger the academic progress creation with generation type = By IPE as faculty
     */
    @IsTest
    static void testAcademicProgressWithExistingIpwAsFacultyUser() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		// Get study program records
		Map<String, reduivy__Study_Program__c> spgMap = new Map<String, reduivy__Study_Program__c>();
		List<reduivy__Study_Program__c> spgList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Program__c
		];

		for (reduivy__Study_Program__c spg : spgList) {
			spgMap.put(spg.reduivy__Sample_Record_Code__c, spg);
		}

		// Get study plan records
		Map<String, reduivy__Study_Plan__c> splMap = new Map<String, reduivy__Study_Plan__c>();
		List<reduivy__Study_Plan__c> splList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c
		];

		for (reduivy__Study_Plan__c spl : splList) {
			splMap.put(spl.reduivy__Sample_Record_Code__c, spl);
		}

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

		Test.startTest();

        List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();

		// Execute test
		System.runAs(ADMIN_USER) {

			// Create individual program enrollment records			
			for (Contact student : studentContacts) {
				String sampleRecordCode = student.Id + '_' + splMap.get(STUDY_PLAN).Id;
				Id contactId = student.Id;
				Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
				Id studyPlanId = splMap.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = null;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = IPE_INPROGRESS_STATUS;
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
		}
	
		Test.stopTest();

		// Verify test results
        List<reduivy__Individual_Pathway__c> ipwUpdateList = new List<reduivy__Individual_Pathway__c>();

		Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
			SELECT Id,
            reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__c,
            (
                SELECT Id, 
                reduivy__Academic_Term__c,
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c,
                reduivy__Term_Number__c,
                reduivy__Individual_Academic_Progress__c
                FROM reduivy__Individual_Pathways__r
                ORDER BY reduivy__Term_Number__c 
            )
			FROM reduivy__Individual_Program_Enrollment__c
		]);

        Map<Id, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<Id, reduivy__Individual_Academic_Profile__c>([
            SELECT Id,
            reduivy__Contact__c,
            (
                SELECT Id,
                reduivy__Contact__c,
                reduivy__Academic_Term__c,
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c,
                reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Academic_Progress__r
            )
            FROM reduivy__Individual_Academic_Profile__c
        ]);

        System.Assert.isFalse(ipeMap.isEmpty(), 'There should be ipe created.');
        System.Assert.isFalse(ipfMap.isEmpty(), 'There should be ipf created.');

        for (reduivy__Individual_Program_Enrollment__c ipe: ipeMap.values()) {

            reduivy__Individual_Pathway__c firstIpw;
            for (reduivy__Individual_Pathway__c ipw : ipe.reduivy__Individual_Pathways__r) {
                // Take the first ipw for assertion
                if (ipw.reduivy__Term_Number__c == 1) {
                    firstIpw = ipw;
                }
            }

            System.Assert.isNotNull(firstIpw, 'No ipw found for assertion.');
            System.Assert.isNull(firstIpw.reduivy__Academic_Term__c);
            System.Assert.isNotNull(ipe.reduivy__Individual_Academic_Profile__c, 'The individual academic profile should be set.');
            System.Assert.isTrue(ipfMap.get(ipe.reduivy__Individual_Academic_Profile__c).reduivy__Individual_Academic_Progress__r.isEmpty(), 'There should not be any individual academic progress created.');

            // set the academic term to simulate the update of ipw to trigger the ipr creation
            firstIpw.reduivy__Academic_Term__c = academicTerm.Id;
            ipwUpdateList.add(firstIpw);
        }

        System.runAs(FACULTY_USER) {
            update ipwUpdateList;
        }

        // Verify test results
		ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
			SELECT Id,
            reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__c,
            (
                SELECT Id, 
                reduivy__Academic_Term__c,
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c,
                reduivy__Term_Number__c,
                reduivy__Individual_Academic_Progress__c
                FROM reduivy__Individual_Pathways__r
                ORDER BY reduivy__Term_Number__c 
            )
			FROM reduivy__Individual_Program_Enrollment__c
		]);

        ipfMap = new Map<Id, reduivy__Individual_Academic_Profile__c>([
            SELECT Id,
            reduivy__Contact__c,
            (
                SELECT Id,
                reduivy__Contact__c,
                reduivy__Academic_Term__c,
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c,
                reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Academic_Progress__r
            )
            FROM reduivy__Individual_Academic_Profile__c
        ]);

        System.Assert.isFalse(ipeMap.isEmpty(), 'There should be ipe created.');
        System.Assert.isFalse(ipfMap.isEmpty(), 'There should be ipf created.');

        for (reduivy__Individual_Program_Enrollment__c ipe: ipeMap.values()) {

            reduivy__Individual_Pathway__c firstIpw;
            for (reduivy__Individual_Pathway__c ipw : ipe.reduivy__Individual_Pathways__r) {
                // Take the first ipw for assertion
                if (ipw.reduivy__Term_Number__c == 1) {
                    firstIpw = ipw;
                }
            }

            System.Assert.isNotNull(firstIpw, 'No ipw found for assertion.');
            System.Assert.areEqual(academicTerm.Id, firstIpw.reduivy__Academic_Term__c);
            System.Assert.isNotNull(firstIpw.reduivy__Individual_Academic_Progress__c);
            System.Assert.isNotNull(ipe.reduivy__Individual_Academic_Profile__c, 'The individual academic profile should be set.');
            
            integer foundIprCount = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipfMap.get(ipe.reduivy__Individual_Academic_Profile__c).reduivy__Individual_Academic_Progress__r) {
                if (ipr.reduivy__Academic_Term__c == firstIpw.reduivy__Academic_Term__c) {
                    foundIprCount ++;

                    System.Assert.areEqual(ipe.reduivy__Contact__c, ipr.reduivy__Contact__c);
                    System.Assert.areEqual(ipe.reduivy__Individual_Academic_Profile__c, ipr.reduivy__Individual_Academic_Profile__c);
                    System.Assert.areEqual(firstIpw.reduivy__Academic_Term__c, ipr.reduivy__Academic_Term__c);
                    System.Assert.areEqual(firstIpw.reduivy__Max_Credits__c, ipr.reduivy__Max_Credits__c);
                    System.Assert.areEqual(firstIpw.reduivy__Recommended_Credits__c, ipr.reduivy__Recommended_Credits__c);
                }
            }

            System.Assert.areEqual(1, foundIprCount, 'There is no ipr found that matches the ipf and academic term set on the ipw.');
        }
	}

    /**
     * @description Test new individual pathway with academic term to trigger the academic progress creation with generation type = By IPE as student
     */
    @IsTest
    static void testAcademicProgressWithNewIpwAsStudyUser() {

		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
            LIMIT 1
        ];

		// Get study program records
		Map<String, reduivy__Study_Program__c> spgMap = new Map<String, reduivy__Study_Program__c>();
		List<reduivy__Study_Program__c> spgList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Program__c
		];

		for (reduivy__Study_Program__c spg : spgList) {
			spgMap.put(spg.reduivy__Sample_Record_Code__c, spg);
		}

		// Get study plan records
		Map<String, reduivy__Study_Plan__c> splMap = new Map<String, reduivy__Study_Plan__c>();
		List<reduivy__Study_Plan__c> splList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c
		];

		for (reduivy__Study_Plan__c spl : splList) {
			splMap.put(spl.reduivy__Sample_Record_Code__c, spl);
		}

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

		List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
		Test.startTest();

		// Execute test
		System.runAs(studentUser) {

			// Create individual program enrollment records			
			for (Contact student : studentContacts) {
				String sampleRecordCode = student.Id + '_' + splMap.get(STUDY_PLAN).Id;
				Id contactId = student.Id;
				Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
				Id studyPlanId = splMap.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = academicTerm.Id;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = IPE_INPROGRESS_STATUS;
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
			
            try {
                insert ipeList;

                System.Assert.fail('Student user should not have permission to create reduivy__Individual_Program_Enrollment__c.');

            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(String.format(Label.Creation_Disallowed_Error, new List<String>{IPE_Helper.getObjectLabel()})), 'Unexpected error: ' + exp.getMessage());
            }
		}
	
		Test.stopTest();

	}

    /**
     * @description Test update of individual pathway to create trigger the academic progress creation with generation type = By IPE as student
     */
    @IsTest
    static void testAcademicProgressWithExistingIpwAsStudentUser() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
            LIMIT 1
        ];

		// Get study program records
		Map<String, reduivy__Study_Program__c> spgMap = new Map<String, reduivy__Study_Program__c>();
		List<reduivy__Study_Program__c> spgList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Program__c
		];

		for (reduivy__Study_Program__c spg : spgList) {
			spgMap.put(spg.reduivy__Sample_Record_Code__c, spg);
		}

		// Get study plan records
		Map<String, reduivy__Study_Plan__c> splMap = new Map<String, reduivy__Study_Plan__c>();
		List<reduivy__Study_Plan__c> splList = [
			SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c
		];

		for (reduivy__Study_Plan__c spl : splList) {
			splMap.put(spl.reduivy__Sample_Record_Code__c, spl);
		}

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

		Test.startTest();

        List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();

		// Execute test
		System.runAs(ADMIN_USER) {

			// Create individual program enrollment records			
			for (Contact student : studentContacts) {
				String sampleRecordCode = student.Id + '_' + splMap.get(STUDY_PLAN).Id;
				Id contactId = student.Id;
				Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
				Id studyPlanId = splMap.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = null;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = IPE_INPROGRESS_STATUS;
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
		}
	
		Test.stopTest();

		// Verify test results
        List<reduivy__Individual_Pathway__c> ipwUpdateList = new List<reduivy__Individual_Pathway__c>();

		Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
			SELECT Id,
            reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__c,
            (
                SELECT Id, 
                reduivy__Academic_Term__c,
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c,
                reduivy__Term_Number__c,
                reduivy__Individual_Academic_Progress__c
                FROM reduivy__Individual_Pathways__r
                ORDER BY reduivy__Term_Number__c 
            )
			FROM reduivy__Individual_Program_Enrollment__c
		]);

        Map<Id, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<Id, reduivy__Individual_Academic_Profile__c>([
            SELECT Id,
            reduivy__Contact__c,
            (
                SELECT Id,
                reduivy__Contact__c,
                reduivy__Academic_Term__c,
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c,
                reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Academic_Progress__r
            )
            FROM reduivy__Individual_Academic_Profile__c
        ]);

        System.Assert.isFalse(ipeMap.isEmpty(), 'There should be ipe created.');
        System.Assert.isFalse(ipfMap.isEmpty(), 'There should be ipf created.');

        for (reduivy__Individual_Program_Enrollment__c ipe: ipeMap.values()) {

            reduivy__Individual_Pathway__c firstIpw;
            for (reduivy__Individual_Pathway__c ipw : ipe.reduivy__Individual_Pathways__r) {
                // Take the first ipw for assertion
                if (ipw.reduivy__Term_Number__c == 1) {
                    firstIpw = ipw;
                }
            }

            System.Assert.isNotNull(firstIpw, 'No ipw found for assertion.');
            System.Assert.isNull(firstIpw.reduivy__Academic_Term__c);
            System.Assert.isNotNull(ipe.reduivy__Individual_Academic_Profile__c, 'The individual academic profile should be set.');
            System.Assert.isTrue(ipfMap.get(ipe.reduivy__Individual_Academic_Profile__c).reduivy__Individual_Academic_Progress__r.isEmpty(), 'There should not be any individual academic progress created.');

            // set the academic term to simulate the update of ipw to trigger the ipr creation
            firstIpw.reduivy__Academic_Term__c = academicTerm.Id;
            ipwUpdateList.add(firstIpw);
        }

        System.runAs(studentUser) {
            update ipwUpdateList;
        }

        // Verify test results
		ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
			SELECT Id,
            reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__c,
            (
                SELECT Id, 
                reduivy__Academic_Term__c,
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c,
                reduivy__Term_Number__c,
                reduivy__Individual_Academic_Progress__c
                FROM reduivy__Individual_Pathways__r
                ORDER BY reduivy__Term_Number__c 
            )
			FROM reduivy__Individual_Program_Enrollment__c
		]);

        ipfMap = new Map<Id, reduivy__Individual_Academic_Profile__c>([
            SELECT Id,
            reduivy__Contact__c,
            (
                SELECT Id,
                reduivy__Contact__c,
                reduivy__Academic_Term__c,
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c,
                reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Academic_Progress__r
            )
            FROM reduivy__Individual_Academic_Profile__c
        ]);

        System.Assert.isFalse(ipeMap.isEmpty(), 'There should be ipe created.');
        System.Assert.isFalse(ipfMap.isEmpty(), 'There should be ipf created.');

        for (reduivy__Individual_Program_Enrollment__c ipe: ipeMap.values()) {

            reduivy__Individual_Pathway__c firstIpw;
            for (reduivy__Individual_Pathway__c ipw : ipe.reduivy__Individual_Pathways__r) {
                // Take the first ipw for assertion
                if (ipw.reduivy__Term_Number__c == 1) {
                    firstIpw = ipw;
                }
            }

            System.Assert.isNotNull(firstIpw, 'No ipw found for assertion.');
            System.Assert.areEqual(academicTerm.Id, firstIpw.reduivy__Academic_Term__c);
            System.Assert.isNotNull(firstIpw.reduivy__Individual_Academic_Progress__c);
            System.Assert.isNotNull(ipe.reduivy__Individual_Academic_Profile__c, 'The individual academic profile should be set.');
            
            integer foundIprCount = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipfMap.get(ipe.reduivy__Individual_Academic_Profile__c).reduivy__Individual_Academic_Progress__r) {
                if (ipr.reduivy__Academic_Term__c == firstIpw.reduivy__Academic_Term__c) {
                    foundIprCount ++;

                    System.Assert.areEqual(ipe.reduivy__Contact__c, ipr.reduivy__Contact__c);
                    System.Assert.areEqual(ipe.reduivy__Individual_Academic_Profile__c, ipr.reduivy__Individual_Academic_Profile__c);
                    System.Assert.areEqual(firstIpw.reduivy__Academic_Term__c, ipr.reduivy__Academic_Term__c);
                    System.Assert.areEqual(firstIpw.reduivy__Max_Credits__c, ipr.reduivy__Max_Credits__c);
                    System.Assert.areEqual(firstIpw.reduivy__Recommended_Credits__c, ipr.reduivy__Recommended_Credits__c);
                }
            }

            System.Assert.areEqual(1, foundIprCount, 'There is no ipr found that matches the ipf and academic term set on the ipw.');
        }
	}
	
}