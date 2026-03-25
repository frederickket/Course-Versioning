/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Test
 * @description Test class for IPE_DeleteEnrollment_EXE
 * @changehistory
 * ISS-001618 17-10-2023 dblack - new class
 * ISS-002487 22-07-2025 XiRouh - Added testMasterIpeDeletionAsAdminUser()
 */
@IsTest
public inherited sharing class IPE_DeleteEnrollment_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String STUDY_PROGRAM = 'BACBIS';
	static final String MAJOR_STUDY_PLAN = 'BACBIS_MajorA';
    static final String MINOR_STUDY_PLAN = 'BACBIS_MinorA';
    
    static final List<String> IPE_INPROGRESS_STATUSES = IPE_Helper.getInProgressStatuses();

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
			testFactory.initStudentData(USR_Helper.getApiName(), true);

            List<reduivy__Individual_Program_Enrollment__c> masterIpeList = new List<reduivy__Individual_Program_Enrollment__c>();
            for (Contact student : testFactory.students.values()) {
				String sampleRecordCode = student.Id + '_' + testFactory.studyPlans.get(MAJOR_STUDY_PLAN).Id;
				Id contactId = student.Id;
				Id studyProgramId = testFactory.studyPrograms.get(STUDY_PROGRAM).Id;
				Id studyPlanId = testFactory.studyPlans.get(MAJOR_STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = null;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = IPE_INPROGRESS_STATUSES.get(0);
				Id idvAcademicProfileId = null;
				reduivy__Individual_Program_Enrollment__c masterIpe = 
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

				masterIpeList.add(masterIpe);
			}
			
			insert masterIpeList;

            List<reduivy__Individual_Program_Enrollment__c> childIpeList = new List<reduivy__Individual_Program_Enrollment__c>();
            for(reduivy__Individual_Program_Enrollment__c ipe : masterIpeList) {
                String sampleRecordCode = ipe.Id + '_' + testFactory.studyPlans.get(MINOR_STUDY_PLAN).Id;
                Id contactId = ipe.reduivy__Contact__c;
                Id studyProgramId = ipe.reduivy__Study_Program__c;
                Id studyPlanId = testFactory.studyPlans.get(MINOR_STUDY_PLAN).Id;
                Id masterIndividualProgramEnrollmentId = ipe.Id;
                String completionRequirement = SPO_Helper.COMPLETION_REQUIREMENT_MANDATORY;
                Boolean eligibleToEnroll = true;
                String enrollmentStatus = IPE_INPROGRESS_STATUSES.get(0);


                reduivy__Individual_Program_Enrollment__c childIpe = 
					REDU_TestData_UTIL.newChildIndividualProgramEnrollment(
						sampleRecordCode,
                        contactId,
                        studyProgramId,
                        studyPlanId,
                        masterIndividualProgramEnrollmentId,
                        completionRequirement,
                        eligibleToEnroll,
                        enrollmentStatus
					);

                childIpeList.add(childIpe);
            }

            insert childIpeList;

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin that the ips records are deleted when the IPE record is deleted
     */
    @IsTest
    static void testDeleteEnrollmentAsAdminUser() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Verify pre-test conditions
		Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Program_Enrollment__c
        ]);
        System.Assert.isFalse(
            ipeMap.isEmpty(),
            'There should be a map of individual program enrollment records'
        );
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsgMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
        ]);
        System.Assert.isFalse(
            ipsgMap.isEmpty(),
            'There should be a map of individual plan structure group records'
        );
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsuMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Parent_Plan_Structure__c IN :ipsgMap.keySet()
        ]);
        System.Assert.isFalse(
            ipsuMap.isEmpty(),
            'There should be a map of individual plan structure unit records'
        );
        Map<Id, reduivy__Individual_Plan_Unit_Requirement__c> iurMap = new Map<Id, reduivy__Individual_Plan_Unit_Requirement__c>([
            SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c WHERE reduivy__Individual_Plan_Unit__c IN :ipsuMap.keySet()
        ]);
        System.Assert.isFalse(
            iurMap.isEmpty(),
            'There should be a map of individual plan unit requirement records'
        );
		
		System.runAs(ADMIN_USER) {
		
			// Execute test
			Test.startTest();
			delete ipeMap.values();
			Test.stopTest();
		}
		
		// Verify test results
		ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Program_Enrollment__c
        ]);
        System.Assert.isTrue(
            ipeMap.isEmpty(),
            'There should be no individual program enrollment records'
        );
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id FROM reduivy__Individual_Plan_Structure__c
        ]);
        System.Assert.isTrue(
            ipsMap.isEmpty(),
            'There should be no individual plan structure records'
        );
        iurMap = new Map<Id, reduivy__Individual_Plan_Unit_Requirement__c>([
            SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c
        ]);
        System.Assert.isTrue(
            iurMap.isEmpty(),
            'There should be no individual plan unit requirement records'
        );
	}

    /**
     * @description Test as an admin that the child IPEs and related IPs are deleted when the master IPE is deleted
     */
    @IsTest
    static void testMasterIpeDeletionAsAdminUser() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Verify pre-test conditions
		List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>([
            SELECT Id, RecordTypeId FROM reduivy__Individual_Program_Enrollment__c
        ]);

        Map<Id, reduivy__Individual_Program_Enrollment__c> masterIpeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
        Map<Id, reduivy__Individual_Program_Enrollment__c> childIpeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();

        for(reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            if(ipe.RecordTypeId == IPE_Helper.getMasterEnrollmentRecordTypeId()) {
                masterIpeMap.put(ipe.Id, ipe);
            } else {
                childIpeMap.put(ipe.Id, ipe);
            }
        }

        System.Assert.isFalse(
            masterIpeMap.isEmpty(),
            'There should be a map of master individual program enrollment records'
        );

        System.Assert.isFalse(
            childIpeMap.isEmpty(),
            'There should be a map of child individual program enrollment records'
        );

        List<reduivy__Individual_Plan_Structure__c> ipsgList = new List<reduivy__Individual_Plan_Structure__c>([
            SELECT Id, reduivy__Individual_Program_Enrollment__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c IN :masterIpeMap.keySet() OR reduivy__Individual_Program_Enrollment__c IN :childIpeMap.keySet()
        ]);

        Map<Id, reduivy__Individual_Plan_Structure__c> masterIpesIpsgMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        Map<Id, reduivy__Individual_Plan_Structure__c> childIpesIpsgMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();

        for(reduivy__Individual_Plan_Structure__c ips : ipsgList) {
            if(masterIpeMap.keySet().contains(ips.reduivy__Individual_Program_Enrollment__c)) {
                masterIpesIpsgMap.put(ips.Id, ips);
            } else {
                childIpesIpsgMap.put(ips.Id, ips);
            }
        }

        System.Assert.isFalse(
            masterIpesIpsgMap.isEmpty(),
            'There should be a map of individual plan structure group records for master IPEs'
        );

        System.Assert.isFalse(
            childIpesIpsgMap.isEmpty(),
            'There should be a map of individual plan structure group records for child IPEs'
        );

        List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>([
            SELECT Id, reduivy__Parent_Plan_Structure__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Parent_Plan_Structure__c IN :masterIpesIpsgMap.keySet() OR reduivy__Parent_Plan_Structure__c IN :childIpesIpsgMap.keySet()
        ]);

        Map<Id, reduivy__Individual_Plan_Structure__c> masterIpsuMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        Map<Id, reduivy__Individual_Plan_Structure__c> childIpsuMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();

        for(reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {
            if(masterIpesIpsgMap.keySet().contains(ipsu.reduivy__Parent_Plan_Structure__c)) {
                masterIpsuMap.put(ipsu.Id, ipsu);
            } else {
                childIpsuMap.put(ipsu.Id, ipsu);
            }
        }

        System.Assert.isFalse(
            masterIpsuMap.isEmpty(),
            'There should be a map of individual plan structure unit records for master IPEs'
        );

        System.Assert.isFalse(
            childIpsuMap.isEmpty(),
            'There should be a map of individual plan structure unit records for child IPEs'
        );

        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>([
            SELECT Id, reduivy__Individual_Plan_Unit__c FROM reduivy__Individual_Plan_Unit_Requirement__c WHERE reduivy__Individual_Plan_Unit__c IN :masterIpsuMap.keySet() OR reduivy__Individual_Plan_Unit__c IN :childIpsuMap.keySet()
        ]);

        Map<Id, reduivy__Individual_Plan_Unit_Requirement__c> masterIurMap = new Map<Id, reduivy__Individual_Plan_Unit_Requirement__c>();
        Map<Id, reduivy__Individual_Plan_Unit_Requirement__c> childIurMap = new Map<Id, reduivy__Individual_Plan_Unit_Requirement__c>();

        for(reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {
            if(masterIpsuMap.keySet().contains(iur.reduivy__Individual_Plan_Unit__c)) {
                masterIurMap.put(iur.Id, iur);
            } else {
                childIurMap.put(iur.Id, iur);
            }
        }

        System.Assert.isFalse(
            masterIurMap.isEmpty(),
            'There should be a map of individual plan unit requirement records for master IPEs'
        );

        System.Assert.isFalse(
            childIurMap.isEmpty(),
            'There should be a map of individual plan unit requirement records for child IPEs'
        );
		
		System.runAs(ADMIN_USER) {
		
			// Execute test
			Test.startTest();
			delete masterIpeMap.values();
			Test.stopTest();
		}
		
		// Verify test results
		Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Program_Enrollment__c
        ]);
        System.Assert.isTrue(
            ipeMap.isEmpty(),
            'There should be no individual program enrollment records'
        );
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id FROM reduivy__Individual_Plan_Structure__c
        ]);
        System.Assert.isTrue(
            ipsMap.isEmpty(),
            'There should be no individual plan structure records'
        );
        Map<Id, reduivy__Individual_Plan_Unit_Requirement__c> iurMap = new Map<Id, reduivy__Individual_Plan_Unit_Requirement__c>([
            SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c
        ]);
        System.Assert.isTrue(
            iurMap.isEmpty(),
            'There should be no individual plan unit requirement records'
        );
	}

    /**
     * @description Test as a faculty member to ensure they do not have permission to delete an IPE.
     */
    @IsTest
    static void testDeleteEnrollmentAsFacultyUser() {
	
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Verify pre-test conditions
		Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Program_Enrollment__c
        ]);
        System.Assert.isFalse(
            ipeMap.isEmpty(),
            'There should be a map of individual program enrollment records'
        );
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsgMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
        ]);
        System.Assert.isFalse(
            ipsgMap.isEmpty(),
            'There should be a map of individual plan structure group records'
        );
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsuMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Parent_Plan_Structure__c IN :ipsgMap.keySet()
        ]);
        System.Assert.isFalse(
            ipsuMap.isEmpty(),
            'There should be a map of individual plan structure unit records'
        );
        Map<Id, reduivy__Individual_Plan_Unit_Requirement__c> iurMap = new Map<Id, reduivy__Individual_Plan_Unit_Requirement__c>([
            SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c WHERE reduivy__Individual_Plan_Unit__c IN :ipsuMap.keySet()
        ]);
        System.Assert.isFalse(
            iurMap.isEmpty(),
            'There should be a map of individual plan unit requirement records'
        );
		
		System.runAs(FACULTY_USER) {
			Test.startTest();

            try {
			    delete ipeMap.values();
                System.Assert.fail('This should fail with insufficient access error.');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'));
            }

            Test.stopTest();
		}
	}

    /**
     * @description Test as a student member to ensure they do not have permission to delete an IPE.
     */
    @IsTest
    static void testDeleteEnrollmentAsStudentUser() {
	
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContacts[0].Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
         
        // Verify pre-test conditions
		Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentContacts[0].Id
        ]);
        System.Assert.isFalse(
            ipeMap.isEmpty(),
            'There should be a map of individual program enrollment records'
        );
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsgMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
        ]);
        System.Assert.isFalse(
            ipsgMap.isEmpty(),
            'There should be a map of individual plan structure group records'
        );
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsuMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Parent_Plan_Structure__c IN :ipsgMap.keySet()
        ]);
        System.Assert.isFalse(
            ipsuMap.isEmpty(),
            'There should be a map of individual plan structure unit records'
        );
        Map<Id, reduivy__Individual_Plan_Unit_Requirement__c> iurMap = new Map<Id, reduivy__Individual_Plan_Unit_Requirement__c>([
            SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c WHERE reduivy__Individual_Plan_Unit__c IN :ipsuMap.keySet()
        ]);
        System.Assert.isFalse(
            iurMap.isEmpty(),
            'There should be a map of individual plan unit requirement records'
        );
		
		System.runAs(studentUser) {
			Test.startTest();

            try {
			    delete ipeMap.values();
                System.Assert.fail('This should fail with insufficient access error.');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'));
            }

            Test.stopTest();
		}
	}
}