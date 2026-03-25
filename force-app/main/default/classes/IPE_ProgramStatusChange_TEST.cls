/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Test
 * @description Test class for IPE_ProgramStatusChange_EXE
 * @changehistory
 * ISS-001618 06-10-2023 dblack - new class
 */
@IsTest
public inherited sharing class IPE_ProgramStatusChange_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String STUDY_PROGRAM = 'BACBIS';
    static final String STUDY_INTAKE = 'SYDNEY_BACBIS_NYINTAKE';

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
            testFactory.initOfferingData(SIT_Helper.getApiName());
			testFactory.initStudentData(CON_Helper.getApiName(), false);

            Test.stopTest();
        }
    }

    /**
     * @description Test that the admin user can successfully update the program status from 'Draft' to 'In Progress'
     */
    @IsTest
    private static void testChangeProgramStatusFromDraftToInProgressAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		List<Contact> studentCon = [SELECT Id, 
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

		// Get the study intake records
        Map<String, reduivy__Study_Intake__c> sitMap = new Map<String, reduivy__Study_Intake__c>();
        List<reduivy__Study_Intake__c> sitList = [
            SELECT  Id, reduivy__Study_Program__c, reduivy__Default_Study_Plan__c, reduivy__Default_Study_Pathway__c, 
                    reduivy__Academic_Term__c, reduivy__Campus__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Intake__c
        ];
        for (reduivy__Study_Intake__c sit : sitList) {
			sitMap.put(sit.reduivy__Sample_Record_Code__c, sit);
		}

		List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
        List<String> enrollmentStatuses = IPE_Helper.getInProgressStatuses();
		List<String> ipeDraftStatuses = IPE_Helper.getDraftStatuses();

		Test.startTest();

		// Execute test
		System.runAs(ADMIN_USER) {

			// Create individual program enrollment records
			for (Integer i = 0; i < studentCon.size(); i++) {
				String sampleRecordCode = 'IPE_CreateGroup_TEST-' + String.valueOf(i);
				Id contactId = studentCon[i].Id;
				Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
				Id studyPlanId = sitMap.get(STUDY_INTAKE).reduivy__Default_Study_Plan__c;
				Id studyIntakeId = sitMap.get(STUDY_INTAKE).Id;
				Id startingTermId = null;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = ipeDraftStatuses[0];
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

            for(reduivy__Individual_Program_Enrollment__c ipe : ipeList){

                ipe.reduivy__Enrollment_Status__c = enrollmentStatuses[0];
            }

            update ipeList;
		}
	
		Test.stopTest();

        // Verify test result
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            System.Assert.areEqual(
                enrollmentStatuses[0], 
                ipe.reduivy__Enrollment_Status__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test that an exception is thrown when the admin user attempts to update the program status from 'In Progress' to 'Draft'
     */
    @IsTest
    private static void testChangeProgramStatusFromInProgressToDraftAsAdminUser(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		List<Contact> studentCon = [SELECT Id, 
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

		// Get the study intake records
        Map<String, reduivy__Study_Intake__c> sitMap = new Map<String, reduivy__Study_Intake__c>();
        List<reduivy__Study_Intake__c> sitList = [
            SELECT  Id, reduivy__Study_Program__c, reduivy__Default_Study_Plan__c, reduivy__Default_Study_Pathway__c, 
                    reduivy__Academic_Term__c, reduivy__Campus__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Intake__c
        ];
        for (reduivy__Study_Intake__c sit : sitList) {
			sitMap.put(sit.reduivy__Sample_Record_Code__c, sit);
		}

		List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
        List<String> enrollmentStatuses = IPE_Helper.getInProgressStatuses();
		List<String> ipeDraftStatuses = IPE_Helper.getDraftStatuses();

		Test.startTest();
            try {
            // Execute test
            System.runAs(ADMIN_USER) {

                // Create individual program enrollment records
                for (Integer i = 0; i < studentCon.size(); i++) {
                    String sampleRecordCode = 'IPE_CreateGroup_TEST-' + String.valueOf(i);
                    Id contactId = studentCon[i].Id;
                    Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
                    Id studyPlanId = null;
                    Id studyIntakeId = sitMap.get(STUDY_INTAKE).Id;
                    Id startingTermId = null;
                    Id studyPathwayId = null;
                    Id defaultCampusId = null;
                    String classYear = null;
                    String classStanding = null;
                    Boolean eligibleToEnroll = true;
                    String enrollmentStatus = enrollmentStatuses[0];
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

                for(reduivy__Individual_Program_Enrollment__c ipe : ipeList){

                    ipe.reduivy__Enrollment_Status__c = ipeDraftStatuses[0];
                }

                update ipeList;
            }
        
            Test.stopTest();

            System.Assert.fail('An exception should have been thrown');
        } catch (Exception e){

            System.Assert.isTrue(e.getMessage().contains(Label.IPE_ProgramStatusChange_EXE_StatusChangeDisallowed));
        }
    }

    /**
     * @description Test that an exception is thrown when the admin user attempts to update the program status from 'In Progress' to 'Preview'
     */
    @IsTest
    private static void testChangeProgramStatusFromInProgressToPreviewAsAdminUser(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		List<Contact> studentCon = [SELECT Id, 
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

		// Get the study intake records
        Map<String, reduivy__Study_Intake__c> sitMap = new Map<String, reduivy__Study_Intake__c>();
        List<reduivy__Study_Intake__c> sitList = [
            SELECT  Id, reduivy__Study_Program__c, reduivy__Default_Study_Plan__c, reduivy__Default_Study_Pathway__c, 
                    reduivy__Academic_Term__c, reduivy__Campus__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Intake__c
        ];
        for (reduivy__Study_Intake__c sit : sitList) {
			sitMap.put(sit.reduivy__Sample_Record_Code__c, sit);
		}

		List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
        List<String> enrollmentStatuses = IPE_Helper.getInProgressStatuses();
		List<String> ipePreviewStatuses = IPE_Helper.getPreviewStatuses();

		Test.startTest();
            try {
            // Execute test
            System.runAs(ADMIN_USER) {

                // Create individual program enrollment records
                for (Integer i = 0; i < studentCon.size(); i++) {
                    String sampleRecordCode = 'IPE_CreateGroup_TEST-' + String.valueOf(i);
                    Id contactId = studentCon[i].Id;
                    Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
                    Id studyPlanId = null;
                    Id studyIntakeId = sitMap.get(STUDY_INTAKE).Id;
                    Id startingTermId = null;
                    Id studyPathwayId = null;
                    Id defaultCampusId = null;
                    String classYear = null;
                    String classStanding = null;
                    Boolean eligibleToEnroll = true;
                    String enrollmentStatus = enrollmentStatuses[0];
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

                for(reduivy__Individual_Program_Enrollment__c ipe : ipeList){

                    ipe.reduivy__Enrollment_Status__c = ipePreviewStatuses[0];
                }

                update ipeList;
            }
        
            Test.stopTest();

            System.Assert.fail('An exception should have been thrown');
        } catch (Exception e){

            System.Assert.isTrue(e.getMessage().contains(Label.IPE_ProgramStatusChange_EXE_StatusChangeDisallowed));
        }
    }

    /**
     * @description Test that an exception is thrown when the admin user attempts to update the program status from 'Preview' to 'In Progress'
     */
    @IsTest
    private static void testChangeProgramStatusFromPreviewToInProgressAsAdminUser(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		List<Contact> studentCon = [SELECT Id, 
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

		// Get the study intake records
        Map<String, reduivy__Study_Intake__c> sitMap = new Map<String, reduivy__Study_Intake__c>();
        List<reduivy__Study_Intake__c> sitList = [
            SELECT  Id, reduivy__Study_Program__c, reduivy__Default_Study_Plan__c, reduivy__Default_Study_Pathway__c, 
                    reduivy__Academic_Term__c, reduivy__Campus__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Intake__c
        ];
        for (reduivy__Study_Intake__c sit : sitList) {
			sitMap.put(sit.reduivy__Sample_Record_Code__c, sit);
		}

		List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
        List<String> enrollmentStatuses = IPE_Helper.getInProgressStatuses();
		List<String> ipePreviewStatuses = IPE_Helper.getPreviewStatuses();

		Test.startTest();
            try {
            // Execute test
            System.runAs(ADMIN_USER) {

                // Create individual program enrollment records
                for (Integer i = 0; i < studentCon.size(); i++) {
                    String sampleRecordCode = 'IPE_CreateGroup_TEST-' + String.valueOf(i);
                    Id contactId = studentCon[i].Id;
                    Id studyProgramId = spgMap.get(STUDY_PROGRAM).Id;
                    Id studyPlanId = null;
                    Id studyIntakeId = sitMap.get(STUDY_INTAKE).Id;
                    Id startingTermId = null;
                    Id studyPathwayId = null;
                    Id defaultCampusId = null;
                    String classYear = null;
                    String classStanding = null;
                    Boolean eligibleToEnroll = true;
                    String enrollmentStatus = ipePreviewStatuses[0];
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

                for(reduivy__Individual_Program_Enrollment__c ipe : ipeList){

                    ipe.reduivy__Enrollment_Status__c = enrollmentStatuses[0];
                }

                update ipeList;
            }
        
            Test.stopTest();

            System.Assert.fail('An exception should have been thrown');
        } catch (Exception e){

            System.Assert.isTrue(e.getMessage().contains(Label.IPE_ProgramStatusChange_EXE_StatusChangeDisallowed));
        }
    }
}