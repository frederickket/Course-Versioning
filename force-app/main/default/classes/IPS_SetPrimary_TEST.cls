/**
 * @author      WDCi (dblack)
 * @date        Nov 2023
 * @group       Test
 * @description Test class for IPS_SetPrimary_EXE
 * @changehistory
 * ISS-001767 06-11-2023 dblack - new class
 */
@IsTest
public inherited sharing class IPS_SetPrimary_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

	static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';

	static String GROUP_A11 = 'BACBIS_MajorA_GROUPA_1_1';
	static String GROUP_A12 = 'BACBIS_MajorA_GROUPA_1_2';

	static Set<String> GROUPNAMES = new Set<String>{GROUP_A11, GROUP_A12};

    static String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);
	static String IPS_COMPLETED_STATUS = IPS_Helper.getUnitCompletedStatuses().get(0);

    /**
     * @description Create settings and test data
     */
	@TestSetup
    static void makeData() {

		// Create settings
		testFactory.setupDefaultSettings();

		User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
			Test.startTest();

			testFactory.initMasterData(SPS_Helper.getApiName());
			testFactory.initStudentData(IAC_Helper.getApiName(), true);

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

	public static void sampleData() {
		List<reduivy__Individual_Program_Enrollment__c> ipeIpsList = [
			SELECT Id,
			(
				SELECT Id,
				reduivy__Study_Plan_Structure__c,
				reduivy__Individual_Program_Enrollment__c,
				reduivy__Parent_Plan_Structure__c,
				reduivy__Allow_Pre_Enrollment__c,
				reduivy__Category__c,
				reduivy__Credits__c,
				reduivy__Description__c,
				reduivy__Sequence__c,
				reduivy__Primary__c,
				reduivy__Credits_Contribution__c,
				RecordTypeId,
				reduivy__Status__c,
				reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
				FROM reduivy__Individual_Plan_Structures__r
				WHERE (RecordTypeId =: IPS_Helper.getGroupRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c IN: GROUPNAMES)
				OR (RecordTypeId =: IPS_Helper.getUnitRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_BUS101')
			) 
			FROM reduivy__Individual_Program_Enrollment__c
		];

		REDU_Logging_UTIL.debugJsonString('ipeIpsList', ipeIpsList);
		
		List<reduivy__Individual_Plan_Structure__c> newIpsList = new List<reduivy__Individual_Plan_Structure__c>();
		
		for (reduivy__Individual_Program_Enrollment__c ipe : ipeIpsList) {
			reduivy__Individual_Plan_Structure__c groupA11;
			reduivy__Individual_Plan_Structure__c groupA12;
			List<reduivy__Individual_Plan_Structure__c> unitIpsList = new List<reduivy__Individual_Plan_Structure__c>();

			for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
				if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A11) {
					groupA11 = ips;
				} else if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A12) {
					groupA12 = ips;
				} else if (ips.RecordTypeId == IPS_Helper.getUnitRecordTypeId()) {
					unitIpsList.add(ips);
				}
			}

			for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
				
				reduivy__Individual_Plan_Structure__c cloneIps = unitIps.clone(false, true, false, false);
				cloneIps.reduivy__Parent_Plan_Structure__c = groupA12.Id;
				cloneIps.reduivy__Status__c = IPS_COMPLETED_STATUS;
				cloneIps.reduivy__Primary__c = true;
				cloneIps.reduivy__UUID__C = null;
				cloneIps.reduivy__Study_Plan_Structure__r = null;

				unitIps.reduivy__Status__c = IPS_COMPLETED_STATUS;
				unitIps.reduivy__Study_Plan_Structure__r = null;

				newIpsList.add(unitIps);
				newIpsList.add(cloneIps);
			}
		}

		REDU_SystemMode_UTIL.doUpsert(newIpsList);
	
		System.Assert.isTrue(!newIpsList.isEmpty(), 'No unit ips found for cloning');
	}

    /**
     * @description Test as admin that the primary ipsu is set when inserted
     */
    @IsTest
    static void testIpsuPrimarySetWhenInsertedAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		// Execute test
		Test.startTest();
		System.runAs(ADMIN_USER) {
			sampleData();
		}

		// Verify test results
		List<reduivy__Individual_Program_Enrollment__c> ipeIpsList = [
			SELECT Id,
			(
				SELECT Id,
				reduivy__Study_Plan_Structure__c,
				reduivy__Individual_Program_Enrollment__c,
				reduivy__Parent_Plan_Structure__c,
				reduivy__Allow_Pre_Enrollment__c,
				reduivy__Category__c,
				reduivy__Credits__c,
				reduivy__Description__c,
				reduivy__Sequence__c,
				reduivy__Primary__c,
				reduivy__Credits_Contribution__c,
				RecordTypeId,
				reduivy__Status__c,
				reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
				FROM reduivy__Individual_Plan_Structures__r
				WHERE (RecordTypeId =: IPS_Helper.getGroupRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c IN: GROUPNAMES)
				OR (RecordTypeId =: IPS_Helper.getUnitRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_BUS101')
			) 
			FROM reduivy__Individual_Program_Enrollment__c
		];

		for (reduivy__Individual_Program_Enrollment__c ipe : ipeIpsList) {
			reduivy__Individual_Plan_Structure__c groupA11;
			reduivy__Individual_Plan_Structure__c groupA12;
			List<reduivy__Individual_Plan_Structure__c> unitIpsList = new List<reduivy__Individual_Plan_Structure__c>();

			for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
				if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A11) {
					groupA11 = ips;
				} else if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A12) {
					groupA12 = ips;
				} else if (ips.RecordTypeId == IPS_Helper.getUnitRecordTypeId()) {
					unitIpsList.add(ips);
				}
			}

			for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
				if (unitIps.reduivy__Parent_Plan_Structure__c == groupA11.Id) {
					System.Assert.areEqual(false, unitIps.reduivy__Primary__c);
					System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_NO, unitIps.reduivy__Credits_Contribution__c);

				} else if (unitIps.reduivy__Parent_Plan_Structure__c == groupA12.Id) {
					System.Assert.areEqual(true, unitIps.reduivy__Primary__c);
					System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_YES, unitIps.reduivy__Credits_Contribution__c);
				}
			}
		}

		Test.stopTest();
	}

    /**
     * @description Test as admin that the primary ipsu is set when updated
     */
    @IsTest
    static void testIpsuPrimarySetWhenUpdatedAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		// Execute test
		Test.startTest();
		System.runAs(ADMIN_USER) {
			sampleData();

			// Verify test results
			List<reduivy__Individual_Program_Enrollment__c> ipeIpsList = [
				SELECT Id,
				(
					SELECT Id,
					reduivy__Study_Plan_Structure__c,
					reduivy__Individual_Program_Enrollment__c,
					reduivy__Parent_Plan_Structure__c,
					reduivy__Allow_Pre_Enrollment__c,
					reduivy__Category__c,
					reduivy__Credits__c,
					reduivy__Description__c,
					reduivy__Sequence__c,
					reduivy__Primary__c,
					reduivy__Credits_Contribution__c,
					RecordTypeId,
					reduivy__Status__c,
					reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
					FROM reduivy__Individual_Plan_Structures__r
					WHERE (RecordTypeId =: IPS_Helper.getGroupRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c IN: GROUPNAMES)
					OR (RecordTypeId =: IPS_Helper.getUnitRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_BUS101')
				) 
				FROM reduivy__Individual_Program_Enrollment__c
			];

			List<reduivy__Individual_Plan_Structure__c> ipsuUpdateList = new List<reduivy__Individual_Plan_Structure__c>();

			for (reduivy__Individual_Program_Enrollment__c ipe : ipeIpsList) {
				reduivy__Individual_Plan_Structure__c groupA11;
				reduivy__Individual_Plan_Structure__c groupA12;
				List<reduivy__Individual_Plan_Structure__c> unitIpsList = new List<reduivy__Individual_Plan_Structure__c>();

				for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
					if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A11) {
						groupA11 = ips;
					} else if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A12) {
						groupA12 = ips;
					} else if (ips.RecordTypeId == IPS_Helper.getUnitRecordTypeId()) {
						unitIpsList.add(ips);
					}
				}

				for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
					if (unitIps.reduivy__Parent_Plan_Structure__c == groupA11.Id) {
						System.Assert.areEqual(false, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_NO, unitIps.reduivy__Credits_Contribution__c);

					} else if (unitIps.reduivy__Parent_Plan_Structure__c == groupA12.Id) {
						System.Assert.areEqual(true, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_YES, unitIps.reduivy__Credits_Contribution__c);
					}
				}

				for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
					reduivy__Individual_Plan_Structure__c ipsUpdate = new reduivy__Individual_Plan_Structure__c(Id = unitIps.Id);

					if (unitIps.reduivy__Parent_Plan_Structure__c == groupA11.Id) {
						ipsUpdate.reduivy__Primary__c = true;

					}

					ipsuUpdateList.add(ipsUpdate);
				}
			}

			System.Assert.isTrue(!ipsuUpdateList.isEmpty(), 'There is not ips for update.');

			REDU_Database_UTIL.doUpdate(ipsuUpdateList);

			// Verify test results again
			List<reduivy__Individual_Program_Enrollment__c> ipeIpsList2 = [
				SELECT Id,
				(
					SELECT Id,
					reduivy__Study_Plan_Structure__c,
					reduivy__Individual_Program_Enrollment__c,
					reduivy__Parent_Plan_Structure__c,
					reduivy__Allow_Pre_Enrollment__c,
					reduivy__Category__c,
					reduivy__Credits__c,
					reduivy__Description__c,
					reduivy__Sequence__c,
					reduivy__Primary__c,
					reduivy__Credits_Contribution__c,
					RecordTypeId,
					reduivy__Status__c,
					reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
					FROM reduivy__Individual_Plan_Structures__r
					WHERE (RecordTypeId =: IPS_Helper.getGroupRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c IN: GROUPNAMES)
					OR (RecordTypeId =: IPS_Helper.getUnitRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_BUS101')
				) 
				FROM reduivy__Individual_Program_Enrollment__c
			];

			for (reduivy__Individual_Program_Enrollment__c ipe : ipeIpsList2) {
				reduivy__Individual_Plan_Structure__c groupA11;
				reduivy__Individual_Plan_Structure__c groupA12;
				List<reduivy__Individual_Plan_Structure__c> unitIpsList = new List<reduivy__Individual_Plan_Structure__c>();

				for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
					if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A11) {
						groupA11 = ips;
					} else if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A12) {
						groupA12 = ips;
					} else if (ips.RecordTypeId == IPS_Helper.getUnitRecordTypeId()) {
						unitIpsList.add(ips);
					}
				}

				for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
					if (unitIps.reduivy__Parent_Plan_Structure__c == groupA11.Id) {
						System.Assert.areEqual(true, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_YES, unitIps.reduivy__Credits_Contribution__c);

					} else if (unitIps.reduivy__Parent_Plan_Structure__c == groupA12.Id) {
						System.Assert.areEqual(false, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_NO, unitIps.reduivy__Credits_Contribution__c);
					}
				}
			}
		}

		Test.stopTest();
	}

    /**
     * @description Test as admin that the primary ipsu is set when deleted
     */
    @IsTest
    static void testIpsuPrimarySetWhenDeletedAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		// Execute test
		Test.startTest();
		System.runAs(ADMIN_USER) {
			sampleData();
		
			// Verify test results
			List<reduivy__Individual_Program_Enrollment__c> ipeIpsList = [
				SELECT Id,
				(
					SELECT Id,
					reduivy__Study_Plan_Structure__c,
					reduivy__Individual_Program_Enrollment__c,
					reduivy__Parent_Plan_Structure__c,
					reduivy__Allow_Pre_Enrollment__c,
					reduivy__Category__c,
					reduivy__Credits__c,
					reduivy__Description__c,
					reduivy__Sequence__c,
					reduivy__Primary__c,
					reduivy__Credits_Contribution__c,
					RecordTypeId,
					reduivy__Status__c,
					reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
					FROM reduivy__Individual_Plan_Structures__r
					WHERE (RecordTypeId =: IPS_Helper.getGroupRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c IN: GROUPNAMES)
					OR (RecordTypeId =: IPS_Helper.getUnitRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_BUS101')
				) 
				FROM reduivy__Individual_Program_Enrollment__c
			];

			List<reduivy__Individual_Plan_Structure__c> ipsuDeleteList = new List<reduivy__Individual_Plan_Structure__c>();

			for (reduivy__Individual_Program_Enrollment__c ipe : ipeIpsList) {
				reduivy__Individual_Plan_Structure__c groupA11;
				reduivy__Individual_Plan_Structure__c groupA12;
				List<reduivy__Individual_Plan_Structure__c> unitIpsList = new List<reduivy__Individual_Plan_Structure__c>();

				for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
					if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A11) {
						groupA11 = ips;
					} else if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A12) {
						groupA12 = ips;
					} else if (ips.RecordTypeId == IPS_Helper.getUnitRecordTypeId()) {
						unitIpsList.add(ips);
					}
				}

				for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
					if (unitIps.reduivy__Parent_Plan_Structure__c == groupA11.Id) {
						System.Assert.areEqual(false, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_NO, unitIps.reduivy__Credits_Contribution__c);

					} else if (unitIps.reduivy__Parent_Plan_Structure__c == groupA12.Id) {
						System.Assert.areEqual(true, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_YES, unitIps.reduivy__Credits_Contribution__c);

						ipsuDeleteList.add(unitIps);
					}
				}
			}

			System.Assert.isTrue(!ipsuDeleteList.isEmpty(), 'No ips unit found for deletion.');

			REDU_Database_UTIL.doDelete(ipsuDeleteList);

			// Verify test results again
			List<reduivy__Individual_Program_Enrollment__c> ipeIpsList2 = [
				SELECT Id,
				(
					SELECT Id,
					reduivy__Study_Plan_Structure__c,
					reduivy__Individual_Program_Enrollment__c,
					reduivy__Parent_Plan_Structure__c,
					reduivy__Allow_Pre_Enrollment__c,
					reduivy__Category__c,
					reduivy__Credits__c,
					reduivy__Description__c,
					reduivy__Sequence__c,
					reduivy__Primary__c,
					reduivy__Credits_Contribution__c,
					RecordTypeId,
					reduivy__Status__c,
					reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
					FROM reduivy__Individual_Plan_Structures__r
					WHERE (RecordTypeId =: IPS_Helper.getGroupRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c IN: GROUPNAMES)
					OR (RecordTypeId =: IPS_Helper.getUnitRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_BUS101')
				) 
				FROM reduivy__Individual_Program_Enrollment__c
			];
			
			for (reduivy__Individual_Program_Enrollment__c ipe : ipeIpsList2) {
				reduivy__Individual_Plan_Structure__c groupA11;
				reduivy__Individual_Plan_Structure__c groupA12;
				List<reduivy__Individual_Plan_Structure__c> unitIpsList = new List<reduivy__Individual_Plan_Structure__c>();

				for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
					if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A11) {
						groupA11 = ips;
					} else if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A12) {
						groupA12 = ips;
					} else if (ips.RecordTypeId == IPS_Helper.getUnitRecordTypeId()) {
						unitIpsList.add(ips);
					}
				}

				for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
					if (unitIps.reduivy__Parent_Plan_Structure__c == groupA11.Id) {
						System.Assert.areEqual(false, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_YES, unitIps.reduivy__Credits_Contribution__c);

					} else if (unitIps.reduivy__Parent_Plan_Structure__c == groupA12.Id) {
						System.Assert.fail('This should have been deleted.');
					}
				}
			}
		}

		Test.stopTest();
	}

    /**
     * @description Test as admin that the primary ipsu is set when undeleted
     */
    @IsTest
    static void testIpsuPrimarySetWhenUndeletedAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
		// Execute test
		Test.startTest();
		System.runAs(ADMIN_USER) {
			sampleData();
		
			// Verify test results
			List<reduivy__Individual_Program_Enrollment__c> ipeIpsList = [
				SELECT Id,
				(
					SELECT Id,
					reduivy__Study_Plan_Structure__c,
					reduivy__Individual_Program_Enrollment__c,
					reduivy__Parent_Plan_Structure__c,
					reduivy__Allow_Pre_Enrollment__c,
					reduivy__Category__c,
					reduivy__Credits__c,
					reduivy__Description__c,
					reduivy__Sequence__c,
					reduivy__Primary__c,
					reduivy__Credits_Contribution__c,
					RecordTypeId,
					reduivy__Status__c,
					reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
					FROM reduivy__Individual_Plan_Structures__r
					WHERE (RecordTypeId =: IPS_Helper.getGroupRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c IN: GROUPNAMES)
					OR (RecordTypeId =: IPS_Helper.getUnitRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_BUS101')
				) 
				FROM reduivy__Individual_Program_Enrollment__c
			];

			List<reduivy__Individual_Plan_Structure__c> ipsuDeleteList = new List<reduivy__Individual_Plan_Structure__c>();

			for (reduivy__Individual_Program_Enrollment__c ipe : ipeIpsList) {
				reduivy__Individual_Plan_Structure__c groupA11;
				reduivy__Individual_Plan_Structure__c groupA12;
				List<reduivy__Individual_Plan_Structure__c> unitIpsList = new List<reduivy__Individual_Plan_Structure__c>();

				for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
					if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A11) {
						groupA11 = ips;
					} else if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A12) {
						groupA12 = ips;
					} else if (ips.RecordTypeId == IPS_Helper.getUnitRecordTypeId()) {
						unitIpsList.add(ips);
					}
				}

				for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
					if (unitIps.reduivy__Parent_Plan_Structure__c == groupA11.Id) {
						System.Assert.areEqual(false, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_NO, unitIps.reduivy__Credits_Contribution__c);

					} else if (unitIps.reduivy__Parent_Plan_Structure__c == groupA12.Id) {
						System.Assert.areEqual(true, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_YES, unitIps.reduivy__Credits_Contribution__c);

						ipsuDeleteList.add(unitIps);
					}
				}
			}

			System.Assert.isTrue(!ipsuDeleteList.isEmpty(), 'No ips unit found for deletion.');

			REDU_Database_UTIL.doDelete(ipsuDeleteList);

			// Verify test results again
			List<reduivy__Individual_Program_Enrollment__c> ipeIpsList2 = [
				SELECT Id,
				(
					SELECT Id,
					reduivy__Study_Plan_Structure__c,
					reduivy__Individual_Program_Enrollment__c,
					reduivy__Parent_Plan_Structure__c,
					reduivy__Allow_Pre_Enrollment__c,
					reduivy__Category__c,
					reduivy__Credits__c,
					reduivy__Description__c,
					reduivy__Sequence__c,
					reduivy__Primary__c,
					reduivy__Credits_Contribution__c,
					RecordTypeId,
					reduivy__Status__c,
					reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
					FROM reduivy__Individual_Plan_Structures__r
					WHERE (RecordTypeId =: IPS_Helper.getGroupRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c IN: GROUPNAMES)
					OR (RecordTypeId =: IPS_Helper.getUnitRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_BUS101')
				) 
				FROM reduivy__Individual_Program_Enrollment__c
			];
			
			for (reduivy__Individual_Program_Enrollment__c ipe : ipeIpsList2) {
				reduivy__Individual_Plan_Structure__c groupA11;
				reduivy__Individual_Plan_Structure__c groupA12;
				List<reduivy__Individual_Plan_Structure__c> unitIpsList = new List<reduivy__Individual_Plan_Structure__c>();

				for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
					if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A11) {
						groupA11 = ips;
					} else if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A12) {
						groupA12 = ips;
					} else if (ips.RecordTypeId == IPS_Helper.getUnitRecordTypeId()) {
						unitIpsList.add(ips);
					}
				}

				for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
					if (unitIps.reduivy__Parent_Plan_Structure__c == groupA11.Id) {
						System.Assert.areEqual(false, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_YES, unitIps.reduivy__Credits_Contribution__c);

					} else if (unitIps.reduivy__Parent_Plan_Structure__c == groupA12.Id) {
						System.Assert.fail('This should have been deleted.');
					}
				}
			}

			undelete ipsuDeleteList;

			// Verify test results again
			List<reduivy__Individual_Program_Enrollment__c> ipeIpsList3 = [
				SELECT Id,
				(
					SELECT Id,
					reduivy__Study_Plan_Structure__c,
					reduivy__Individual_Program_Enrollment__c,
					reduivy__Parent_Plan_Structure__c,
					reduivy__Allow_Pre_Enrollment__c,
					reduivy__Category__c,
					reduivy__Credits__c,
					reduivy__Description__c,
					reduivy__Sequence__c,
					reduivy__Primary__c,
					reduivy__Credits_Contribution__c,
					RecordTypeId,
					reduivy__Status__c,
					reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
					FROM reduivy__Individual_Plan_Structures__r
					WHERE (RecordTypeId =: IPS_Helper.getGroupRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c IN: GROUPNAMES)
					OR (RecordTypeId =: IPS_Helper.getUnitRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_BUS101')
				) 
				FROM reduivy__Individual_Program_Enrollment__c
			];
			
			for (reduivy__Individual_Program_Enrollment__c ipe : ipeIpsList3) {
				reduivy__Individual_Plan_Structure__c groupA11;
				reduivy__Individual_Plan_Structure__c groupA12;
				List<reduivy__Individual_Plan_Structure__c> unitIpsList = new List<reduivy__Individual_Plan_Structure__c>();

				for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
					if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A11) {
						groupA11 = ips;
					} else if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A12) {
						groupA12 = ips;
					} else if (ips.RecordTypeId == IPS_Helper.getUnitRecordTypeId()) {
						unitIpsList.add(ips);
					}
				}

				for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
					if (unitIps.reduivy__Parent_Plan_Structure__c == groupA11.Id) {
						System.Assert.areEqual(false, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_NO, unitIps.reduivy__Credits_Contribution__c);

					} else if (unitIps.reduivy__Parent_Plan_Structure__c == groupA12.Id) {
						System.Assert.areEqual(true, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_YES, unitIps.reduivy__Credits_Contribution__c);
					}
				}
			}
		}

		Test.stopTest();
	}

    /**
     * @description Test as faculty that the primary ipsu is set when inserted
     */
    @IsTest
    static void testIpsuPrimarySetWhenInsertedAsFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
		// Execute test
		Test.startTest();
		System.runAs(FACULTY_USER) {
			sampleData();
		}

		// Verify test results
		List<reduivy__Individual_Program_Enrollment__c> ipeIpsList = [
			SELECT Id,
			(
				SELECT Id,
				reduivy__Study_Plan_Structure__c,
				reduivy__Individual_Program_Enrollment__c,
				reduivy__Parent_Plan_Structure__c,
				reduivy__Allow_Pre_Enrollment__c,
				reduivy__Category__c,
				reduivy__Credits__c,
				reduivy__Description__c,
				reduivy__Sequence__c,
				reduivy__Primary__c,
				reduivy__Credits_Contribution__c,
				RecordTypeId,
				reduivy__Status__c,
				reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
				FROM reduivy__Individual_Plan_Structures__r
				WHERE (RecordTypeId =: IPS_Helper.getGroupRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c IN: GROUPNAMES)
				OR (RecordTypeId =: IPS_Helper.getUnitRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_BUS101')
			) 
			FROM reduivy__Individual_Program_Enrollment__c
		];

		for (reduivy__Individual_Program_Enrollment__c ipe : ipeIpsList) {
			reduivy__Individual_Plan_Structure__c groupA11;
			reduivy__Individual_Plan_Structure__c groupA12;
			List<reduivy__Individual_Plan_Structure__c> unitIpsList = new List<reduivy__Individual_Plan_Structure__c>();

			for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
				if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A11) {
					groupA11 = ips;
				} else if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A12) {
					groupA12 = ips;
				} else if (ips.RecordTypeId == IPS_Helper.getUnitRecordTypeId()) {
					unitIpsList.add(ips);
				}
			}

			for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
				if (unitIps.reduivy__Parent_Plan_Structure__c == groupA11.Id) {
					System.Assert.areEqual(false, unitIps.reduivy__Primary__c);
					System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_NO, unitIps.reduivy__Credits_Contribution__c);

				} else if (unitIps.reduivy__Parent_Plan_Structure__c == groupA12.Id) {
					System.Assert.areEqual(true, unitIps.reduivy__Primary__c);
					System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_YES, unitIps.reduivy__Credits_Contribution__c);
				}
			}
		}

		Test.stopTest();
	}

    /**
     * @description Test as faculty that the primary ipsu is set when updated
     */
    @IsTest
    static void testIpsuPrimarySetWhenUpdatedAsFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
		// Execute test
		Test.startTest();
		System.runAs(FACULTY_USER) {
			sampleData();

			// Verify test results
			List<reduivy__Individual_Program_Enrollment__c> ipeIpsList = [
				SELECT Id,
				(
					SELECT Id,
					reduivy__Study_Plan_Structure__c,
					reduivy__Individual_Program_Enrollment__c,
					reduivy__Parent_Plan_Structure__c,
					reduivy__Allow_Pre_Enrollment__c,
					reduivy__Category__c,
					reduivy__Credits__c,
					reduivy__Description__c,
					reduivy__Sequence__c,
					reduivy__Primary__c,
					reduivy__Credits_Contribution__c,
					RecordTypeId,
					reduivy__Status__c,
					reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
					FROM reduivy__Individual_Plan_Structures__r
					WHERE (RecordTypeId =: IPS_Helper.getGroupRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c IN: GROUPNAMES)
					OR (RecordTypeId =: IPS_Helper.getUnitRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_BUS101')
				) 
				FROM reduivy__Individual_Program_Enrollment__c
			];

			List<reduivy__Individual_Plan_Structure__c> ipsuUpdateList = new List<reduivy__Individual_Plan_Structure__c>();

			for (reduivy__Individual_Program_Enrollment__c ipe : ipeIpsList) {
				reduivy__Individual_Plan_Structure__c groupA11;
				reduivy__Individual_Plan_Structure__c groupA12;
				List<reduivy__Individual_Plan_Structure__c> unitIpsList = new List<reduivy__Individual_Plan_Structure__c>();

				for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
					if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A11) {
						groupA11 = ips;
					} else if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A12) {
						groupA12 = ips;
					} else if (ips.RecordTypeId == IPS_Helper.getUnitRecordTypeId()) {
						unitIpsList.add(ips);
					}
				}

				for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
					if (unitIps.reduivy__Parent_Plan_Structure__c == groupA11.Id) {
						System.Assert.areEqual(false, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_NO, unitIps.reduivy__Credits_Contribution__c);

					} else if (unitIps.reduivy__Parent_Plan_Structure__c == groupA12.Id) {
						System.Assert.areEqual(true, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_YES, unitIps.reduivy__Credits_Contribution__c);
					}
				}

				for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
					reduivy__Individual_Plan_Structure__c ipsUpdate = new reduivy__Individual_Plan_Structure__c(Id = unitIps.Id);

					if (unitIps.reduivy__Parent_Plan_Structure__c == groupA11.Id) {
						ipsUpdate.reduivy__Primary__c = true;

					}

					ipsuUpdateList.add(ipsUpdate);
				}
			}

			System.Assert.isTrue(!ipsuUpdateList.isEmpty(), 'There is not ips for update.');

			REDU_Database_UTIL.doUpdate(ipsuUpdateList);

			// Verify test results again
			List<reduivy__Individual_Program_Enrollment__c> ipeIpsList2 = [
				SELECT Id,
				(
					SELECT Id,
					reduivy__Study_Plan_Structure__c,
					reduivy__Individual_Program_Enrollment__c,
					reduivy__Parent_Plan_Structure__c,
					reduivy__Allow_Pre_Enrollment__c,
					reduivy__Category__c,
					reduivy__Credits__c,
					reduivy__Description__c,
					reduivy__Sequence__c,
					reduivy__Primary__c,
					reduivy__Credits_Contribution__c,
					RecordTypeId,
					reduivy__Status__c,
					reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
					FROM reduivy__Individual_Plan_Structures__r
					WHERE (RecordTypeId =: IPS_Helper.getGroupRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c IN: GROUPNAMES)
					OR (RecordTypeId =: IPS_Helper.getUnitRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_BUS101')
				) 
				FROM reduivy__Individual_Program_Enrollment__c
			];

			for (reduivy__Individual_Program_Enrollment__c ipe : ipeIpsList2) {
				reduivy__Individual_Plan_Structure__c groupA11;
				reduivy__Individual_Plan_Structure__c groupA12;
				List<reduivy__Individual_Plan_Structure__c> unitIpsList = new List<reduivy__Individual_Plan_Structure__c>();

				for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
					if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A11) {
						groupA11 = ips;
					} else if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A12) {
						groupA12 = ips;
					} else if (ips.RecordTypeId == IPS_Helper.getUnitRecordTypeId()) {
						unitIpsList.add(ips);
					}
				}

				for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
					if (unitIps.reduivy__Parent_Plan_Structure__c == groupA11.Id) {
						System.Assert.areEqual(true, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_YES, unitIps.reduivy__Credits_Contribution__c);

					} else if (unitIps.reduivy__Parent_Plan_Structure__c == groupA12.Id) {
						System.Assert.areEqual(false, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_NO, unitIps.reduivy__Credits_Contribution__c);
					}
				}
			}
		}

		Test.stopTest();
	}

    /**
     * @description Test as a student that the primary ipsu is set when inserted
     */
    @IsTest
    static void testIpsuPrimarySetWhenInsertedAsStudentUser() {

		User studentUser = testFactory.getStudentUser();

		// Execute test
		Test.startTest();
		System.runAs(studentUser) {
			sampleData();

			// Verify test results
			List<reduivy__Individual_Program_Enrollment__c> ipeIpsList = [
				SELECT Id,
				(
					SELECT Id,
					reduivy__Study_Plan_Structure__c,
					reduivy__Individual_Program_Enrollment__c,
					reduivy__Parent_Plan_Structure__c,
					reduivy__Allow_Pre_Enrollment__c,
					reduivy__Category__c,
					reduivy__Credits__c,
					reduivy__Description__c,
					reduivy__Sequence__c,
					reduivy__Primary__c,
					reduivy__Credits_Contribution__c,
					RecordTypeId,
					reduivy__Status__c,
					reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
					FROM reduivy__Individual_Plan_Structures__r
					WHERE (RecordTypeId =: IPS_Helper.getGroupRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c IN: GROUPNAMES)
					OR (RecordTypeId =: IPS_Helper.getUnitRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_BUS101')
				) 
				FROM reduivy__Individual_Program_Enrollment__c
			];

			for (reduivy__Individual_Program_Enrollment__c ipe : ipeIpsList) {
				reduivy__Individual_Plan_Structure__c groupA11;
				reduivy__Individual_Plan_Structure__c groupA12;
				List<reduivy__Individual_Plan_Structure__c> unitIpsList = new List<reduivy__Individual_Plan_Structure__c>();

				for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
					if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A11) {
						groupA11 = ips;
					} else if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A12) {
						groupA12 = ips;
					} else if (ips.RecordTypeId == IPS_Helper.getUnitRecordTypeId()) {
						unitIpsList.add(ips);
					}
				}

				for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
					if (unitIps.reduivy__Parent_Plan_Structure__c == groupA11.Id) {
						System.Assert.areEqual(false, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_NO, unitIps.reduivy__Credits_Contribution__c);

					} else if (unitIps.reduivy__Parent_Plan_Structure__c == groupA12.Id) {
						System.Assert.areEqual(true, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_YES, unitIps.reduivy__Credits_Contribution__c);
					}
				}
			}
		}

		Test.stopTest();
	}

    /**
     * @description Test as a student that the primary ipsu is set when updated
     */
    @IsTest
    static void testIpsuPrimarySetWhenUpdatedAsStudentUser() {

		User studentUser = testFactory.getStudentUser();

		// Execute test
		Test.startTest();
		System.runAs(studentUser) {
			sampleData();

			// Verify test results
			List<reduivy__Individual_Program_Enrollment__c> ipeIpsList = [
				SELECT Id,
				(
					SELECT Id,
					reduivy__Study_Plan_Structure__c,
					reduivy__Individual_Program_Enrollment__c,
					reduivy__Parent_Plan_Structure__c,
					reduivy__Allow_Pre_Enrollment__c,
					reduivy__Category__c,
					reduivy__Credits__c,
					reduivy__Description__c,
					reduivy__Sequence__c,
					reduivy__Primary__c,
					reduivy__Credits_Contribution__c,
					RecordTypeId,
					reduivy__Status__c,
					reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
					FROM reduivy__Individual_Plan_Structures__r
					WHERE (RecordTypeId =: IPS_Helper.getGroupRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c IN: GROUPNAMES)
					OR (RecordTypeId =: IPS_Helper.getUnitRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_BUS101')
				) 
				FROM reduivy__Individual_Program_Enrollment__c
			];

			List<reduivy__Individual_Plan_Structure__c> ipsuUpdateList = new List<reduivy__Individual_Plan_Structure__c>();

			for (reduivy__Individual_Program_Enrollment__c ipe : ipeIpsList) {
				reduivy__Individual_Plan_Structure__c groupA11;
				reduivy__Individual_Plan_Structure__c groupA12;
				List<reduivy__Individual_Plan_Structure__c> unitIpsList = new List<reduivy__Individual_Plan_Structure__c>();

				for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
					if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A11) {
						groupA11 = ips;
					} else if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A12) {
						groupA12 = ips;
					} else if (ips.RecordTypeId == IPS_Helper.getUnitRecordTypeId()) {
						unitIpsList.add(ips);
					}
				}

				for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
					if (unitIps.reduivy__Parent_Plan_Structure__c == groupA11.Id) {
						System.Assert.areEqual(false, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_NO, unitIps.reduivy__Credits_Contribution__c);

					} else if (unitIps.reduivy__Parent_Plan_Structure__c == groupA12.Id) {
						System.Assert.areEqual(true, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_YES, unitIps.reduivy__Credits_Contribution__c);
					}
				}

				for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
					reduivy__Individual_Plan_Structure__c ipsUpdate = new reduivy__Individual_Plan_Structure__c(Id = unitIps.Id);

					if (unitIps.reduivy__Parent_Plan_Structure__c == groupA11.Id) {
						ipsUpdate.reduivy__Primary__c = true;

					}

					ipsuUpdateList.add(ipsUpdate);
				}
			}

			System.Assert.isTrue(!ipsuUpdateList.isEmpty(), 'There is not ips for update.');

			REDU_Database_UTIL.doUpdate(ipsuUpdateList);

			// Verify test results again
			List<reduivy__Individual_Program_Enrollment__c> ipeIpsList2 = [
				SELECT Id,
				(
					SELECT Id,
					reduivy__Study_Plan_Structure__c,
					reduivy__Individual_Program_Enrollment__c,
					reduivy__Parent_Plan_Structure__c,
					reduivy__Allow_Pre_Enrollment__c,
					reduivy__Category__c,
					reduivy__Credits__c,
					reduivy__Description__c,
					reduivy__Sequence__c,
					reduivy__Primary__c,
					reduivy__Credits_Contribution__c,
					RecordTypeId,
					reduivy__Status__c,
					reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c
					FROM reduivy__Individual_Plan_Structures__r
					WHERE (RecordTypeId =: IPS_Helper.getGroupRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c IN: GROUPNAMES)
					OR (RecordTypeId =: IPS_Helper.getUnitRecordTypeId() AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_BUS101')
				) 
				FROM reduivy__Individual_Program_Enrollment__c
			];

			for (reduivy__Individual_Program_Enrollment__c ipe : ipeIpsList2) {
				reduivy__Individual_Plan_Structure__c groupA11;
				reduivy__Individual_Plan_Structure__c groupA12;
				List<reduivy__Individual_Plan_Structure__c> unitIpsList = new List<reduivy__Individual_Plan_Structure__c>();

				for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
					if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A11) {
						groupA11 = ips;
					} else if (ips.reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c == GROUP_A12) {
						groupA12 = ips;
					} else if (ips.RecordTypeId == IPS_Helper.getUnitRecordTypeId()) {
						unitIpsList.add(ips);
					}
				}

				for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsList) {
					if (unitIps.reduivy__Parent_Plan_Structure__c == groupA11.Id) {
						System.Assert.areEqual(true, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_YES, unitIps.reduivy__Credits_Contribution__c);

					} else if (unitIps.reduivy__Parent_Plan_Structure__c == groupA12.Id) {
						System.Assert.areEqual(false, unitIps.reduivy__Primary__c);
						System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_NO, unitIps.reduivy__Credits_Contribution__c);
					}
				}
			}
		}

		Test.stopTest();
	}
}