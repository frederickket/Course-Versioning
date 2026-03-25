/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Test
 * @description Test class for IPS_RequirementMet_EXE
 * @changehistory
 * ISS-001762 20-10-2023 dblack - new class
 * ISS-002486 11-06-2025 XiRouh - Updated to assign the completed status according to the grade result
 */
@IsTest
public inherited sharing class IPS_RequirementMet_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

	static final String UNIT_STUDY_PLAN_STRUCTURE = 'BACBIS_MajorA_SEC301';
	static final String IPS_REQUIREMENT_LOGIC = 'COM101 AND (BUS101 OR BUS102)';

	static final String IEN_COMPLETED_PASS_STATUS = IEN_Helper.getCompletedPassStatuses().get(0);

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
			testFactory.initOfferingData(SGP_Helper.getApiName());
			testFactory.initStudentData(IPE_Helper.getApiName(), true);

			Test.stopTest();
        }
    }

    /**
     * @description Test as admin when the IPS requirement is met according to the requirement logic
     */
    @IsTest
    static void testIpsRequirementIsMetAsAdminUser() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
		Test.startTest();

		// Setup test data
		// Check for records availability for testing
		List<reduivy__Individual_Plan_Structure__c> ipsuList = [
			SELECT reduivy__Requirement_Logic__c, reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Structure__c
			WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
			AND reduivy__Requirement_Logic__c = :IPS_REQUIREMENT_LOGIC
		];

		System.Assert.isFalse(
			ipsuList.isEmpty(),
			'There should be a list of individual plan structure unit records'
		);

		System.runAs(ADMIN_USER) {
			// Update the individual enrollment records
			List<reduivy__Individual_Enrollment__c> ienList = [
				SELECT reduivy__Enrollment_Status__c, reduivy__Grade_Result__c FROM reduivy__Individual_Enrollment__c
			];
			for (reduivy__Individual_Enrollment__c ien : ienList) {
				ien.reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS;
				ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
				ien.reduivy__Numerical_Grade__c = 90;

			}
		
			update ienList;
		}
		
		// Verify test results
		ipsuList = [
			SELECT reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Structure__c
			WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
			AND reduivy__Requirement_Logic__c = :IPS_REQUIREMENT_LOGIC
		];
		for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

			System.Assert.isTrue(
				ipsu.reduivy__Requirement_Met__c,
				'The actual value should be as expected'
			);
		}

		Test.stopTest();
	}

    /**
     * @description Test as admin when the IPS requirement is not met according to the requirement logic
     */
    @IsTest
    static void testIpsRequirementNotMetAsAdminUser() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
		Test.startTest();

		// Setup test data
		// Check for records availability for testing
		List<reduivy__Individual_Plan_Structure__c> ipsuList = [
			SELECT reduivy__Requirement_Logic__c, reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Structure__c
			WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
			AND reduivy__Requirement_Logic__c = :IPS_REQUIREMENT_LOGIC
		];

		System.runAs(ADMIN_USER) {

			// Update the individual enrollment records
			List<reduivy__Individual_Enrollment__c> ienList = [
				SELECT reduivy__Enrollment_Status__c
				FROM reduivy__Individual_Enrollment__c
			];

			for (reduivy__Individual_Enrollment__c ien : ienList) {
				ien.reduivy__Enrollment_Status__c = 'Enrolled';
			}

			update ienList;

			// Update the individual plan unit requirement records
			List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = [
				SELECT Id, reduivy__Requirement_Met__c
				FROM reduivy__Individual_Plan_Unit_Requirement__c
			];

			for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {
				iur.reduivy__Requirement_Met__c  = !iur.reduivy__Requirement_Met__c;
			}

			// Execute test
			update iurList;
		}
			
		// Verify test results
		ipsuList = [
			SELECT reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Structure__c
			WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
			AND reduivy__Requirement_Logic__c = :IPS_REQUIREMENT_LOGIC
		];
		for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

			System.Assert.isFalse(
				ipsu.reduivy__Requirement_Met__c,
				'The actual value should be as expected'
			);
		}

		Test.stopTest();
	}

    /**
     * @description Test as faculty when the IPS requirement is met according to the requirement logic
     */
    @IsTest
    static void testIpsRequirementIsMetAsFacultyUser() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
		Test.startTest();

		// Setup test data
		// Check for records availability for testing
		List<reduivy__Individual_Plan_Structure__c> ipsuList = [
			SELECT reduivy__Requirement_Logic__c, reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Structure__c
			WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
			AND reduivy__Requirement_Logic__c = :IPS_REQUIREMENT_LOGIC
		];

		System.Assert.isFalse(
			ipsuList.isEmpty(),
			'There should be a list of individual plan structure unit records'
		);

		System.runAs(FACULTY_USER) {
			// Update the individual enrollment records
			List<reduivy__Individual_Enrollment__c> ienList = [
				SELECT reduivy__Enrollment_Status__c, reduivy__Grade_Result__c FROM reduivy__Individual_Enrollment__c
			];
			for (reduivy__Individual_Enrollment__c ien : ienList) {
				ien.reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS;
				ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
				ien.reduivy__Numerical_Grade__c = 90;
			}
		
			update ienList;
		}
		
		// Verify test results
		ipsuList = [
			SELECT reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Structure__c
			WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
			AND reduivy__Requirement_Logic__c = :IPS_REQUIREMENT_LOGIC
		];

		for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

			System.Assert.isTrue(
				ipsu.reduivy__Requirement_Met__c,
				'The actual value should be as expected'
			);
		}

		Test.stopTest();
	}

    /**
     * @description Test as faculty when the IPS requirement is not met according to the requirement logic
     */
    @IsTest
    static void testIpsRequirementNotMetAsFacultyUser() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
		Test.startTest();

		// Setup test data
		// Check for records availability for testing
		List<reduivy__Individual_Plan_Structure__c> ipsuList = [
			SELECT reduivy__Requirement_Logic__c, reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Structure__c
			WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
			AND reduivy__Requirement_Logic__c = :IPS_REQUIREMENT_LOGIC
		];

		System.runAs(FACULTY_USER) {
			// Update the individual enrollment records
			List<reduivy__Individual_Enrollment__c> ienList = [
				SELECT reduivy__Enrollment_Status__c
				FROM reduivy__Individual_Enrollment__c
			];

			for (reduivy__Individual_Enrollment__c ien : ienList) {
				ien.reduivy__Enrollment_Status__c = 'Enrolled';
			}

			update ienList;

			// Update the individual plan unit requirement records
			List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = [
				SELECT Id, reduivy__Requirement_Met__c
				FROM reduivy__Individual_Plan_Unit_Requirement__c
			];

			for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

				iur.reduivy__Requirement_Met__c  = !iur.reduivy__Requirement_Met__c;
			}		
		
			// Execute test
			update iurList;
		}
			
		// Verify test results
		ipsuList = [
			SELECT reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Structure__c
			WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
			AND reduivy__Requirement_Logic__c = :IPS_REQUIREMENT_LOGIC
		];

		for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

			System.Assert.isFalse(
				ipsu.reduivy__Requirement_Met__c,
				'The actual value should be as expected'
			);
		}

		Test.stopTest();
	}

    /**
     * @description Test as a student when the IPS requirement is met according to the requirement logic
     */
    @IsTest
    static void testIpsRequirementIsMetAsStudentUser() {

		Test.startTest();

		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id, ContactId, ProfileId 
            FROM User 
            WHERE ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts 
            LIMIT 1
        ];

		// Update the individual enrollment records
		List<reduivy__Individual_Enrollment__c> ienList = [
			SELECT reduivy__Enrollment_Status__c, reduivy__Grade_Result__c FROM reduivy__Individual_Enrollment__c
		];
		for (reduivy__Individual_Enrollment__c ien : ienList) {
			ien.reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS;
			ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
			ien.reduivy__Numerical_Grade__c = 90;
		}
		update ienList;

		System.runAs(studentUser) {

			// Update the individual plan structure unit records
			List<reduivy__Individual_Plan_Structure__c> ipsuList = [
				SELECT reduivy__Requirement_Logic__c, reduivy__Requirement_Met__c
				FROM reduivy__Individual_Plan_Structure__c
				WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
				AND reduivy__Requirement_Logic__c = :IPS_REQUIREMENT_LOGIC
			];

			System.Assert.isFalse(
				ipsuList.isEmpty(),
				'There should be a list of individual plan structure unit records'
			);
		
			// Verify test results
			ipsuList = [
				SELECT reduivy__Requirement_Met__c
				FROM reduivy__Individual_Plan_Structure__c
				WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
				AND reduivy__Requirement_Logic__c = :IPS_REQUIREMENT_LOGIC
			];

			for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

				System.Assert.isTrue(
					ipsu.reduivy__Requirement_Met__c,
					'The actual value should be as expected'
				);
			}
		}

		Test.stopTest();
	}

    /**
     * @description Test as a student when the IPS requirement is not met according to the requirement logic
     */
    @IsTest
    static void testIpsRequirementNotMetAsStudentUser() {

		Test.startTest();

		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id, ContactId, ProfileId 
            FROM User 
            WHERE ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts 
            LIMIT 1
        ];

		System.runAs(studentUser) {

			// Setup test data

			// Update the individual enrollment records
			List<reduivy__Individual_Enrollment__c> ienList = [
				SELECT reduivy__Enrollment_Status__c
				FROM reduivy__Individual_Enrollment__c
			];

			for (reduivy__Individual_Enrollment__c ien : ienList) {
				ien.reduivy__Enrollment_Status__c = 'Enrolled';
			}

			update ienList;

			// Update the individual plan unit requirement records
			List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = [
				SELECT Id, reduivy__Requirement_Met__c
				FROM reduivy__Individual_Plan_Unit_Requirement__c
			];

			for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

				iur.reduivy__Requirement_Met__c  = !iur.reduivy__Requirement_Met__c;
			}
		
			// Execute test
			update iurList;
		
			// Verify test results
			List<reduivy__Individual_Plan_Structure__c> ipsuList = [
				SELECT reduivy__Requirement_Met__c
				FROM reduivy__Individual_Plan_Structure__c
				WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
				AND reduivy__Requirement_Logic__c = :IPS_REQUIREMENT_LOGIC
			];

			for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

				System.Assert.isFalse(
					ipsu.reduivy__Requirement_Met__c,
					'The actual value should be as expected'
				);
			}
		}

		Test.stopTest();
	}

    /**
     * @description Test as admin that the individual plan unit requirement met field is updated for 'Pre-Requisite'
     */
    @IsTest
    static void testIurRequirementMetForRequirementTypePreReqAsAdminUser() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
		Test.startTest();

		// Setup test data
		List<reduivy__Individual_Plan_Structure__c> bus201IpsList = [
			SELECT Id,
			reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Structure__c
			WHERE reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c = 'BUS201'
			AND reduivy__Requirement_Met__c = FALSE
		];

		// Verify pre-test condition using sandydoe@redu.example, fionnadoe@redu.example and tommydoe@redu.example who haven't completed BUS101
		List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = [
			SELECT reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Unit_Requirement__c
			WHERE reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_PREREQ_BYPASS
			AND reduivy__Individual_Plan_Unit__c IN: bus201IpsList
		];

		System.Assert.isFalse(
			iurList.isEmpty(),
			'The actual value should be as expected'
		);

		for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

			System.Assert.isFalse(
				iur.reduivy__Requirement_Met__c,
				'The actual value should be as expected'
			);
		}

		// Setup the individual enrollment records
		List<reduivy__Individual_Enrollment__c> ienList = [
			SELECT reduivy__Grade_Result__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c = 'BUS101'
		];

		for (reduivy__Individual_Enrollment__c ien : ienList) {
			ien.reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS;
			ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
			ien.reduivy__Numerical_Grade__c = 90;

		}

		System.runAs(ADMIN_USER) {
			update ienList;
		}
				
		// Verify test results
		iurList = [
			SELECT reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Unit_Requirement__c
			WHERE Id IN: iurList
		];

		System.Assert.isFalse(
			iurList.isEmpty(),
			'The actual value should be as expected'
		);

		for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

			System.Assert.isTrue(
				iur.reduivy__Requirement_Met__c,
				'The actual value should be as expected'
			);
		}

		for (reduivy__Individual_Plan_Structure__c ips : [SELECT Id, reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Structure__c
			WHERE Id IN: bus201IpsList
		]) {

			System.Assert.isTrue(
				ips.reduivy__Requirement_Met__c,
				'The actual value should be as expected'
			);
		}

		Test.stopTest();
	}

    /**
     * @description Test as admin that the individual plan unit requirement met field is updated for 'Other'
     */
    @IsTest
    static void testIurRequirementMetForRequirementTypeOtherAsAdminUser() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
		Test.startTest();

		// Setup test data
		List<reduivy__Individual_Plan_Structure__c> bus201IpsList = [
			SELECT Id,
			reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Structure__c
			WHERE reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c = 'BUS201'
			AND reduivy__Requirement_Met__c = FALSE
		];

		// Verify pre-test condition using sandydoe@redu.example, fionnadoe@redu.example and tommydoe@redu.example who haven't completed BUS101
		List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = [
			SELECT reduivy__Requirement_Met__c,
			reduivy__Individual_Plan_Unit__c
			FROM reduivy__Individual_Plan_Unit_Requirement__c
			WHERE reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_PREREQ_BYPASS
			AND reduivy__Individual_Plan_Unit__c IN: bus201IpsList
		];

		System.Assert.isFalse(
			iurList.isEmpty(),
			'The actual value should be as expected'
		);

		// Change the type from pre-req to other
		for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

			System.Assert.isFalse(
				iur.reduivy__Requirement_Met__c,
				'The actual value should be as expected'
			);

			iur.reduivy__Requirement_Type__c = IUR_Helper.REQTYPE_OTHER;
			iur.reduivy__Requirement_Met__c = true;
		}

		System.runAs(ADMIN_USER) {
			update iurList;
		}

		for (reduivy__Individual_Plan_Structure__c ips : [SELECT Id, reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Structure__c
			WHERE Id IN: bus201IpsList
		]) {

			System.Assert.isTrue(
				ips.reduivy__Requirement_Met__c,
				'The actual value should be as expected'
			);
		}

		Test.stopTest();
	}

    /**
     * @description Test as faculty that the individual plan unit requirement met field is updated for 'Pre-Requisite'
     */
    @IsTest
    static void testIurRequirementMetForRequirementTypePreReqAsFacultyUser() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
		Test.startTest();

		// Setup test data
		List<reduivy__Individual_Plan_Structure__c> bus201IpsList = [
			SELECT Id,
			reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Structure__c
			WHERE reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c = 'BUS201'
			AND reduivy__Requirement_Met__c = FALSE
		];

		// Verify pre-test condition using sandydoe@redu.example, fionnadoe@redu.example and tommydoe@redu.example who haven't completed BUS101
		List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = [
			SELECT reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Unit_Requirement__c
			WHERE reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_PREREQ_BYPASS
			AND reduivy__Individual_Plan_Unit__c IN: bus201IpsList
		];

		System.Assert.isFalse(
			iurList.isEmpty(),
			'The actual value should be as expected'
		);

		for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

			System.Assert.isFalse(
				iur.reduivy__Requirement_Met__c,
				'The actual value should be as expected'
			);
		}

		// Setup the individual enrollment records
		List<reduivy__Individual_Enrollment__c> ienList = [
			SELECT reduivy__Grade_Result__c
			FROM reduivy__Individual_Enrollment__c
			WHERE reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c = 'BUS101'
		];

		for (reduivy__Individual_Enrollment__c ien : ienList) {
			ien.reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS;
			ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
			ien.reduivy__Numerical_Grade__c = 90;

		}

		System.runAs(FACULTY_USER) {
			update ienList;
		}
				
		// Verify test results
		iurList = [
			SELECT reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Unit_Requirement__c
			WHERE Id IN: iurList
		];

		System.Assert.isFalse(
			iurList.isEmpty(),
			'The actual value should be as expected'
		);

		for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

			System.Assert.isTrue(
				iur.reduivy__Requirement_Met__c,
				'The actual value should be as expected'
			);
		}

		for (reduivy__Individual_Plan_Structure__c ips : [SELECT Id, reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Structure__c
			WHERE Id IN: bus201IpsList
		]) {

			System.Assert.isTrue(
				ips.reduivy__Requirement_Met__c,
				'The actual value should be as expected'
			);
		}
		
		Test.stopTest();
	}

    /**
     * @description Test as faculty that the individual plan unit requirement met field is updated for 'Other'
     */
    @IsTest
    static void testIurRequirementMetForRequirementTypeOtherAsFacultyUser() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
		Test.startTest();

		// Setup test data
		List<reduivy__Individual_Plan_Structure__c> bus201IpsList = [
			SELECT Id,
			reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Structure__c
			WHERE reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c = 'BUS201'
			AND reduivy__Requirement_Met__c = FALSE
		];

		// Verify pre-test condition using sandydoe@redu.example, fionnadoe@redu.example and tommydoe@redu.example who haven't completed BUS101
		List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = [
			SELECT reduivy__Requirement_Met__c,
			reduivy__Individual_Plan_Unit__c
			FROM reduivy__Individual_Plan_Unit_Requirement__c
			WHERE reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_PREREQ_BYPASS
			AND reduivy__Individual_Plan_Unit__c IN: bus201IpsList
		];

		System.Assert.isFalse(
			iurList.isEmpty(),
			'The actual value should be as expected'
		);

		// Change the type from pre-req to other
		for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

			System.Assert.isFalse(
				iur.reduivy__Requirement_Met__c,
				'The actual value should be as expected'
			);

			iur.reduivy__Requirement_Type__c = IUR_Helper.REQTYPE_OTHER;
			iur.reduivy__Requirement_Met__c = true;
		}

		System.runAs(FACULTY_USER) {
			update iurList;
		}

		for (reduivy__Individual_Plan_Structure__c ips : [SELECT Id, reduivy__Requirement_Met__c
			FROM reduivy__Individual_Plan_Structure__c
			WHERE Id IN: bus201IpsList
		]) {

			System.Assert.isTrue(
				ips.reduivy__Requirement_Met__c,
				'The actual value should be as expected'
			);
		}

		Test.stopTest();
	}
}