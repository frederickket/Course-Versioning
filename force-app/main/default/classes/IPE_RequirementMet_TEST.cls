/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Test
 * @description Test class for IPE_RequirementMet_EXE
 * @changehistory
 * ISS-001618 03-10-2023 dblack - new class
 * ISS-002155 31-12-2024 XW - added test cases for custom reqtype
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@IsTest
public inherited sharing class IPE_RequirementMet_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final Decimal EARNED_CREDITS = 10.0;
    static final Integer UNITS_ENROLLED = 2;

    static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';
    static final String STUDY_UNIT = 'COM103';
    static final String STUDY_INTAKE = 'SYDNEY_BACBIS_CYINTAKE';
    static final String STARTING_STUDY_TERM = 'CYT1';
    static final String CURRENT_YEAR_TERM_2 = 'CYT2';
    static final String STUDY_PATWHAY = 'BACBIS_MajorA_DEFAULT';
    static final String CAMPUS = 'SYDNEY';

    //child ipe
    static final String splMinorKey = 'BACBIS_MinorA';
    
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

            testFactory.initMasterData(SPU_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
			testFactory.initStudentData(USR_Helper.getApiName(), true);

            List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
            for (Contact student : testFactory.students.values()) {
				String sampleRecordCode = student.Id + '_' + testFactory.studyPlans.get(STUDY_PLAN).Id;
				Id contactId = student.Id;
				Id studyProgramId = testFactory.studyPrograms.get(STUDY_PROGRAM).Id;
				Id studyPlanId = testFactory.studyPlans.get(STUDY_PLAN).Id;
				Id studyIntakeId = testFactory.studyIntakes.get(STUDY_INTAKE).Id;
				Id startingTermId = testFactory.academicTerms.get(STARTING_STUDY_TERM).Id;
				Id studyPathwayId = testFactory.studyPathways.get(STUDY_PATWHAY).Id;
				Id defaultCampusId = testFactory.campuses.get(CAMPUS).Id;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = false;
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

                    String childSampleRecordCode = student.Id + '_' + testFactory.studyPlans.get(splMinorKey).Id;
                    String ipeEnrollmentStatus = IPE_Helper.getInProgressStatuses().get(0);
                reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(
                    childSampleRecordCode, 
                    contactId, 
                    testFactory.studyPlans.get(splMinorKey).reduivy__Study_Program__c, 
                    testFactory.studyPlans.get(splMinorKey).Id,
                    ipe.Id, 
                    IPE_Helper.COMPLETION_REQUIREMENT_OPTIONAL,
                    true, 
                    ipeEnrollmentStatus);

				ipeList.add(ipe);
                ipeList.add(childIpe);
			}
			
			insert ipeList;



            Test.stopTest();
        }
    }

    /**
     * @description Test as admin user when the requirement has been met
     */
    @IsTest
    static void testCreditsIpeRequirementMetAsAdminUser() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Get the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Credits_Earned__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId =: IPE_Helper.getMasterEnrollmentRecordTypeId()
        ]);

        // Verify requirement met before test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CREDITS AND reduivy__Requirement_Met__c = true
        ];

        System.Assert.isTrue(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );

        // Execute test
        Test.startTest();

        System.runAs(ADMIN_USER) {

            // Update the individual program requirements records for the test
            for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {
                ipe.reduivy__Credits_Earned__c = EARNED_CREDITS;
            }

            update ipeMap.values();
            
        }
        
        Test.stopTest();

        // Verify test results
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CREDITS AND reduivy__Requirement_Met__c = true
        ];
        System.Assert.isFalse(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );
    }

    /**
     * @description Test as faculty user when the requirement has been met
     */
    @IsTest
    static void testCreditsIpeRequirementMetAsFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Get the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Credits_Earned__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId =: IPE_Helper.getMasterEnrollmentRecordTypeId()
        ]);

        // Verify requirement met before test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CREDITS AND reduivy__Requirement_Met__c = true
        ];

        System.Assert.isTrue(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );

        // Execute test
        Test.startTest();
        System.runAs(FACULTY_USER) {

            // Update the individual program requirements records for the test
            for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {
                ipe.reduivy__Credits_Earned__c = EARNED_CREDITS;
            }

            update ipeMap.values();
            
        }
        
        Test.stopTest();

        // Verify test results
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CREDITS AND reduivy__Requirement_Met__c = true
        ];
        System.Assert.isFalse(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );
    }

    /**
     * @description Test as setup user when the requirement has been met
     */
    @IsTest
    static void testCreditsIpeRequirementMetAsSetupUser() {

        User setupUser = testFactory.getSetupUser();

        // Get the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Credits_Earned__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId =: IPE_Helper.getMasterEnrollmentRecordTypeId()
        ]);

        // Verify requirement met before test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CREDITS AND reduivy__Requirement_Met__c = true
        ];

        System.Assert.isTrue(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );

        // Execute test
        Test.startTest();
        System.runAs(setupUser) {

            // Update the individual program requirements records for the test
            for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {
                ipe.reduivy__Credits_Earned__c = EARNED_CREDITS;
            }

            update ipeMap.values();
            
        }
        
        Test.stopTest();

        // Verify test results
        iurList =[
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CREDITS
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
    }

    /**
     * @description Test as admin user when the requirement has been met
     */
    @IsTest
    static void testCreditsIpeRequirementNotMetAsAdminUser() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Get the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Credits_Earned__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId =: IPE_Helper.getMasterEnrollmentRecordTypeId()
        ]);

        // Verify requirement met before test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CREDITS AND reduivy__Requirement_Met__c = true
        ];

        System.Assert.isTrue(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );

        // Execute test
        Test.startTest();

        System.runAs(ADMIN_USER) {

            // Update the individual program requirements records for the test
            for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {
                ipe.reduivy__Credits_Earned__c = EARNED_CREDITS - 1;
            }

            update ipeMap.values();
            
        }
        
        Test.stopTest();

        // Verify test results
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CREDITS AND reduivy__Requirement_Met__c = true
        ];
        System.Assert.isTrue(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );
    }

    /**
     * @description Test as faculty user when the requirement has been met
     */
    @IsTest
    static void testCreditsIpeRequirementNotMetAsFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Get the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Credits_Earned__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId =: IPE_Helper.getMasterEnrollmentRecordTypeId()
        ]);

        // Verify requirement met before test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CREDITS AND reduivy__Requirement_Met__c = true
        ];

        System.Assert.isTrue(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );

        // Execute test
        Test.startTest();
        System.runAs(FACULTY_USER) {

            // Update the individual program requirements records for the test
            for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {
                ipe.reduivy__Credits_Earned__c = EARNED_CREDITS - 1;
            }

            update ipeMap.values();
            
        }
        
        Test.stopTest();

        // Verify test results
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CREDITS AND reduivy__Requirement_Met__c = true
        ];
        System.Assert.isTrue(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );
    }

    /**
     * @description Test as setup user when the requirement has been met
     */
    @IsTest
    static void testCreditsIpeRequirementNotMetAsSetupUser() {

        User setupUser = testFactory.getSetupUser();

        // Get the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Credits_Earned__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId =: IPE_Helper.getMasterEnrollmentRecordTypeId()
        ]);

        // Verify requirement met before test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CREDITS AND reduivy__Requirement_Met__c = true
        ];

        System.Assert.isTrue(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );

        // Execute test
        Test.startTest();
        System.runAs(setupUser) {

            // Update the individual program requirements records for the test
            for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {
                ipe.reduivy__Credits_Earned__c = EARNED_CREDITS - 1;
            }

            update ipeMap.values();
            
        }
        
        Test.stopTest();

        // Verify test results
        iurList =[
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CREDITS
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
    }

    /**
     * @description Test as admin user when the requirement has been met (custom)
     */
    @IsTest
    static void testCustomNumberIpeRequirementMetAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Get the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(); 
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeByContactMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(); 
        for(reduivy__Individual_Program_Enrollment__c ipe :[
            SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Credits_Earned__c, reduivy__Completion_Percentage__c,
            reduivy__Contact__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId =: IPE_Helper.getMasterEnrollmentRecordTypeId()
        ]) {
            ipeMap.put(ipe.Id, ipe);
            ipeByContactMap.put(ipe.reduivy__Contact__c, ipe);
        }

        //create ips, ien and iur before modifying ipe units enrolled

        List<Contact> studentList = [SELECT Id, Name, reduivy__Sample_Record_Code__c FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT];

        List<reduivy__Individual_Enrollment__c> studentIenList = createStudentEnrolledIen(studentList);
        insert studentIenList;

        Map<Id, reduivy__Individual_Enrollment__c> ienByipe = new Map<Id, reduivy__Individual_Enrollment__c>();
        
        for(reduivy__Individual_Enrollment__c ien : studentIenList) {
            ienByipe.put(ipeByContactMap.get(ien.reduivy__Contact__c).Id, ien);
        }

        reduivy__Study_Plan_Structure__c parentUsps = [SELECT Id,
            reduivy__Allow_Pre_Enrollment__c, reduivy__Category__c, reduivy__Credits__c,
            reduivy__Description__c, reduivy__Hide_in_Enrollment__c, reduivy__Sequence__c, reduivy__Requirement_Logic__c,
            reduivy__Parent_Study_Plan_Structure__c
            FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_COM103' LIMIT 1];

        Map<Id, reduivy__Individual_Plan_Structure__c> parentGroupIpsByIpe = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        
        for(reduivy__Individual_Plan_Structure__c gips : [ SELECT Id, reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Study_Plan_Structure__c = :parentUsps.reduivy__Parent_Study_Plan_Structure__c
        ]) {
            parentGroupIpsByIpe.put(gips.reduivy__Individual_Program_Enrollment__c,gips);
        }

        List<reduivy__Individual_Plan_Structure__c> newUnitIps = new List<reduivy__Individual_Plan_Structure__c>();
        for(Id ipeId : ipeMap.keySet()){
            reduivy__Individual_Plan_Structure__c unitIps = IPS_Helper.initUnitPlanStructure(ipeId, parentGroupIpsByIpe.get(ipeId).Id, ienByipe.get(ipeId).Id, parentUsps);
            newUnitIps.add(unitIps);
        }

        insert newUnitIps;

        // Verify requirement met before test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CUSTOM AND reduivy__Requirement_Met__c = true
        ];

        System.Assert.isTrue(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );

        reduivy__Study_Offering__c cyt2Com103Sof = createComSof();
        insert cyt2Com103Sof;

        // Execute test
        Test.startTest();

        System.runAs(ADMIN_USER) {
            List<reduivy__Individual_Enrollment__c> comIenList = new List<reduivy__Individual_Enrollment__c>();
            for(Contact student : studentList) {
                reduivy__Individual_Enrollment__c newIenToInsert = REDU_TestData_UTIL.newStudentIndividualEnrollment('COM103', student.Id, cyt2Com103Sof.Id, IEN_Helper.getInProgressStatuses()[0], 1, System.today(), cyt2Com103Sof.reduivy__Start_Date__c, cyt2Com103Sof.reduivy__End_Date__c, cyt2Com103Sof.reduivy__Census_Date__c, 10, null, null, true);
                comIenList.add(newIenToInsert);
            }
            insert comIenList;
        }
        
        Test.stopTest();

        // Verify test results
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CUSTOM AND reduivy__Requirement_Met__c = true
        ];
        System.Assert.isFalse(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );
    }

    /**
     * @description Test as admin user when the requirement has been met (custom)
     */
    @IsTest
    static void testCustomNumberIpeRequirementNotMetAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Get the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(); 
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeByContactMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(); 
        for(reduivy__Individual_Program_Enrollment__c ipe :[
            SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Credits_Earned__c, reduivy__Completion_Percentage__c,
            reduivy__Contact__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId =: IPE_Helper.getMasterEnrollmentRecordTypeId()
        ]) {
            ipeMap.put(ipe.Id, ipe);
            ipeByContactMap.put(ipe.reduivy__Contact__c, ipe);
        }

        
        // Verify requirement met before test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CUSTOM AND reduivy__Requirement_Met__c = true
        ];

        System.Assert.isTrue(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );

        // Execute test
        Test.startTest();


        reduivy__Study_Offering__c cyt2Com103Sof = createComSof();
        insert cyt2Com103Sof;

        List<Contact> studentList = [SELECT Id, Name, reduivy__Sample_Record_Code__c FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT];
        List<reduivy__Individual_Enrollment__c> studentIenList = new List<reduivy__Individual_Enrollment__c>();

        
        System.runAs(ADMIN_USER) {
            for(Contact student : studentList) {
                studentIenList.add(REDU_TestData_UTIL.newStudentIndividualEnrollment('COM103', student.Id, cyt2Com103Sof.Id, IEN_Helper.getInProgressStatuses()[0], 1, System.today(), cyt2Com103Sof.reduivy__Start_Date__c, cyt2Com103Sof.reduivy__End_Date__c, cyt2Com103Sof.reduivy__Census_Date__c, 10, null, null, true ));
            }
            insert studentIenList;
        }

        Map<Id, reduivy__Individual_Enrollment__c> ienByipe = new Map<Id, reduivy__Individual_Enrollment__c>();
        
        for(reduivy__Individual_Enrollment__c ien : studentIenList) {
            ienByipe.put(ipeByContactMap.get(ien.reduivy__Contact__c).Id, ien);
        }

        reduivy__Study_Plan_Structure__c parentUsps = [SELECT Id,
            reduivy__Allow_Pre_Enrollment__c, reduivy__Category__c, reduivy__Credits__c,
            reduivy__Description__c, reduivy__Hide_in_Enrollment__c, reduivy__Sequence__c, reduivy__Requirement_Logic__c,
            reduivy__Parent_Study_Plan_Structure__c
            FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_COM103' LIMIT 1];

        Map<Id, reduivy__Individual_Plan_Structure__c> parentGroupIpsByIpe = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        
        for(reduivy__Individual_Plan_Structure__c gips : [ SELECT Id, reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Study_Plan_Structure__c = :parentUsps.reduivy__Parent_Study_Plan_Structure__c
        ]) {
            parentGroupIpsByIpe.put(gips.reduivy__Individual_Program_Enrollment__c,gips);
        }

        List<reduivy__Individual_Plan_Structure__c> newUnitIps = new List<reduivy__Individual_Plan_Structure__c>();
        for(Id ipeId : ipeMap.keySet()){
            reduivy__Individual_Plan_Structure__c unitIps = IPS_Helper.initUnitPlanStructure(ipeId, parentGroupIpsByIpe.get(ipeId).Id, ienByipe.get(ipeId).Id, parentUsps);
            newUnitIps.add(unitIps);
        }

        insert newUnitIps;

        
        Test.stopTest();

        // Verify test results
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CUSTOM AND reduivy__Requirement_Met__c = true
        ];
        System.Assert.isTrue(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );
    }

    /**
     * @description Test as faculty user when the requirement has been met (custom)
     */
    @IsTest
    static void testCustomNumberIpeRequirementMetAsFacultyUser() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Get the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(); 
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeByContactMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(); 
        for(reduivy__Individual_Program_Enrollment__c ipe :[
            SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Credits_Earned__c, reduivy__Completion_Percentage__c,
            reduivy__Contact__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId =: IPE_Helper.getMasterEnrollmentRecordTypeId()
        ]) {
            ipeMap.put(ipe.Id, ipe);
            ipeByContactMap.put(ipe.reduivy__Contact__c, ipe);
        }

        //create ips, ien and iur before modifying ipe units enrolled

        List<Contact> studentList = [SELECT Id, Name, reduivy__Sample_Record_Code__c FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT];

        List<reduivy__Individual_Enrollment__c> studentIenList = createStudentEnrolledIen(studentList);
        insert studentIenList;

        Map<Id, reduivy__Individual_Enrollment__c> ienByipe = new Map<Id, reduivy__Individual_Enrollment__c>();
        
        for(reduivy__Individual_Enrollment__c ien : studentIenList) {
            ienByipe.put(ipeByContactMap.get(ien.reduivy__Contact__c).Id, ien);
        }

        reduivy__Study_Plan_Structure__c parentUsps = [SELECT Id,
            reduivy__Allow_Pre_Enrollment__c, reduivy__Category__c, reduivy__Credits__c,
            reduivy__Description__c, reduivy__Hide_in_Enrollment__c, reduivy__Sequence__c, reduivy__Requirement_Logic__c,
            reduivy__Parent_Study_Plan_Structure__c
            FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_COM103' LIMIT 1];

        Map<Id, reduivy__Individual_Plan_Structure__c> parentGroupIpsByIpe = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        
        for(reduivy__Individual_Plan_Structure__c gips : [ SELECT Id, reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Study_Plan_Structure__c = :parentUsps.reduivy__Parent_Study_Plan_Structure__c
        ]) {
            parentGroupIpsByIpe.put(gips.reduivy__Individual_Program_Enrollment__c,gips);
        }

        List<reduivy__Individual_Plan_Structure__c> newUnitIps = new List<reduivy__Individual_Plan_Structure__c>();
        for(Id ipeId : ipeMap.keySet()){
            reduivy__Individual_Plan_Structure__c unitIps = IPS_Helper.initUnitPlanStructure(ipeId, parentGroupIpsByIpe.get(ipeId).Id, ienByipe.get(ipeId).Id, parentUsps);
            newUnitIps.add(unitIps);
        }

        insert newUnitIps;

        // Verify requirement met before test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CUSTOM AND reduivy__Requirement_Met__c = true
        ];

        System.Assert.isTrue(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );

        reduivy__Study_Offering__c cyt2Com103Sof = createComSof();
        insert cyt2Com103Sof;

        // Execute test
        Test.startTest();

        System.runAs(FACULTY_USER) {
            List<reduivy__Individual_Enrollment__c> comIenList = new List<reduivy__Individual_Enrollment__c>();
            for(Contact student : studentList) {
                reduivy__Individual_Enrollment__c newIenToInsert = REDU_TestData_UTIL.newStudentIndividualEnrollment('COM103', student.Id, cyt2Com103Sof.Id, IEN_Helper.getInProgressStatuses()[0], 1, System.today(), cyt2Com103Sof.reduivy__Start_Date__c, cyt2Com103Sof.reduivy__End_Date__c, cyt2Com103Sof.reduivy__Census_Date__c, 10, null, null, true );
                comIenList.add(newIenToInsert);
            }
            insert comIenList;
        }
        
        Test.stopTest();

        // Verify test results
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CUSTOM AND reduivy__Requirement_Met__c = true
        ];
        System.Assert.isFalse(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );
    }

    /**
     * @description Test as faculty user when the requirement has been met (custom)
     */
    @IsTest
    static void testCustomNumberIpeRequirementNotMetAsFacultyUser() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        // Get the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(); 
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeByContactMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(); 
        for(reduivy__Individual_Program_Enrollment__c ipe :[
            SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Credits_Earned__c, reduivy__Completion_Percentage__c,
            reduivy__Contact__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId =: IPE_Helper.getMasterEnrollmentRecordTypeId()
        ]) {
            ipeMap.put(ipe.Id, ipe);
            ipeByContactMap.put(ipe.reduivy__Contact__c, ipe);
        }

        
        // Verify requirement met before test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CUSTOM AND reduivy__Requirement_Met__c = true
        ];

        System.Assert.isTrue(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );

        // Execute test
        Test.startTest();


        reduivy__Study_Offering__c cyt2Com103Sof = createComSof();
        insert cyt2Com103Sof;

        List<Contact> studentList = [SELECT Id, Name, reduivy__Sample_Record_Code__c FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT];
        List<reduivy__Individual_Enrollment__c> studentIenList = new List<reduivy__Individual_Enrollment__c>();

        
        System.runAs(FACULTY_USER) {
            for(Contact student : studentList) {
                studentIenList.add(REDU_TestData_UTIL.newStudentIndividualEnrollment('COM103', student.Id, cyt2Com103Sof.Id, IEN_Helper.getInProgressStatuses()[0], 1, System.today(), cyt2Com103Sof.reduivy__Start_Date__c, cyt2Com103Sof.reduivy__End_Date__c, cyt2Com103Sof.reduivy__Census_Date__c, 10, null, null, true ));
            }
            insert studentIenList;
        }

        Map<Id, reduivy__Individual_Enrollment__c> ienByipe = new Map<Id, reduivy__Individual_Enrollment__c>();
        
        for(reduivy__Individual_Enrollment__c ien : studentIenList) {
            ienByipe.put(ipeByContactMap.get(ien.reduivy__Contact__c).Id, ien);
        }

        reduivy__Study_Plan_Structure__c parentUsps = [SELECT Id,
            reduivy__Allow_Pre_Enrollment__c, reduivy__Category__c, reduivy__Credits__c,
            reduivy__Description__c, reduivy__Hide_in_Enrollment__c, reduivy__Sequence__c, reduivy__Requirement_Logic__c,
            reduivy__Parent_Study_Plan_Structure__c
            FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_COM103' LIMIT 1];

        Map<Id, reduivy__Individual_Plan_Structure__c> parentGroupIpsByIpe = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        
        for(reduivy__Individual_Plan_Structure__c gips : [ SELECT Id, reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Study_Plan_Structure__c = :parentUsps.reduivy__Parent_Study_Plan_Structure__c
        ]) {
            parentGroupIpsByIpe.put(gips.reduivy__Individual_Program_Enrollment__c,gips);
        }

        List<reduivy__Individual_Plan_Structure__c> newUnitIps = new List<reduivy__Individual_Plan_Structure__c>();
        for(Id ipeId : ipeMap.keySet()){
            reduivy__Individual_Plan_Structure__c unitIps = IPS_Helper.initUnitPlanStructure(ipeId, parentGroupIpsByIpe.get(ipeId).Id, ienByipe.get(ipeId).Id, parentUsps);
            newUnitIps.add(unitIps);
        }

        insert newUnitIps;

        
        Test.stopTest();

        // Verify test results
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CUSTOM AND reduivy__Requirement_Met__c = true
        ];
        System.Assert.isTrue(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );
    }

    
    /**
     * @description Test as admin user when the requirement has been met (custom)
     */
    @IsTest
    static void testCustomNumberInvalidMatchingValueAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Get the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(); 
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeByContactMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(); 
        for(reduivy__Individual_Program_Enrollment__c ipe :[
            SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Credits_Earned__c, reduivy__Completion_Percentage__c,
            reduivy__Contact__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId =: IPE_Helper.getMasterEnrollmentRecordTypeId()
        ]) {
            ipeMap.put(ipe.Id, ipe);
            ipeByContactMap.put(ipe.reduivy__Contact__c, ipe);
        }

        //create ips, ien and iur before modifying ipe units enrolled

        List<Contact> studentList = [SELECT Id, Name, reduivy__Sample_Record_Code__c FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT];

        List<reduivy__Individual_Enrollment__c> studentIenList = createStudentEnrolledIen(studentList);
        insert studentIenList;

        Map<Id, reduivy__Individual_Enrollment__c> ienByipe = new Map<Id, reduivy__Individual_Enrollment__c>();
        
        for(reduivy__Individual_Enrollment__c ien : studentIenList) {
            ienByipe.put(ipeByContactMap.get(ien.reduivy__Contact__c).Id, ien);
        }

        reduivy__Study_Plan_Structure__c parentUsps = [SELECT Id,
            reduivy__Allow_Pre_Enrollment__c, reduivy__Category__c, reduivy__Credits__c,
            reduivy__Description__c, reduivy__Hide_in_Enrollment__c, reduivy__Sequence__c, reduivy__Requirement_Logic__c,
            reduivy__Parent_Study_Plan_Structure__c
            FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_COM103' LIMIT 1];

        Map<Id, reduivy__Individual_Plan_Structure__c> parentGroupIpsByIpe = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        
        for(reduivy__Individual_Plan_Structure__c gips : [ SELECT Id, reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Study_Plan_Structure__c = :parentUsps.reduivy__Parent_Study_Plan_Structure__c
        ]) {
            parentGroupIpsByIpe.put(gips.reduivy__Individual_Program_Enrollment__c,gips);
        }

        List<reduivy__Individual_Plan_Structure__c> newUnitIps = new List<reduivy__Individual_Plan_Structure__c>();
        for(Id ipeId : ipeMap.keySet()){
            reduivy__Individual_Plan_Structure__c unitIps = IPS_Helper.initUnitPlanStructure(ipeId, parentGroupIpsByIpe.get(ipeId).Id, ienByipe.get(ipeId).Id, parentUsps);
            newUnitIps.add(unitIps);
        }

        insert newUnitIps;

        // Verify requirement met and change to invalid matching value before test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        iurList = [
            SELECT reduivy__Requirement_Met__c, reduivy__Requirement_ID__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CUSTOM
        ];

        reduivy__Individual_Plan_Unit_Requirement__c updateInvalidIur;
        for(reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {
            if(iur.reduivy__Requirement_Met__c) {
                System.Assert.fail('The actual value should be as expected');
            }

            if(iur.reduivy__Requirement_ID__c == 'UNITS2') {
                iur.reduivy__Field_Matching_Value__c = 'invalid';
                updateInvalidIur = iur;
            }
        }

        if(updateInvalidIur == null) {
            System.Assert.fail('Custom iur should be found');
        } else {
            REDU_TriggerController.muteAllTriggers();
            update updateInvalidIur;
            REDU_TriggerController.unmuteAllTriggers();
        }
        reduivy__Study_Offering__c cyt2Com103Sof = createComSof();
        insert cyt2Com103Sof;

        // Execute test
        Test.startTest();
        try {
            System.runAs(ADMIN_USER) {
                List<reduivy__Individual_Enrollment__c> comIenList = new List<reduivy__Individual_Enrollment__c>();
                for(Contact student : studentList) {
                    reduivy__Individual_Enrollment__c newIenToInsert = REDU_TestData_UTIL.newStudentIndividualEnrollment('COM103', student.Id, cyt2Com103Sof.Id, IEN_Helper.getInProgressStatuses()[0], 1, System.today(), cyt2Com103Sof.reduivy__Start_Date__c, cyt2Com103Sof.reduivy__End_Date__c, cyt2Com103Sof.reduivy__Census_Date__c, 10, null, null, true );
                    comIenList.add(newIenToInsert);
                }
                
                insert comIenList;
            }
            System.Assert.fail('Invalid matching value, should be failed');
        } catch (Exception exp) {
            
        }
        Test.stopTest();


    }    
    /**
     * @description Test as admin user when the requirement has been met (custom)
     */
    @IsTest
    static void testChildIpeUpdatedAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Get the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> masterIpeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(); 
        Map<Id, reduivy__Individual_Program_Enrollment__c> childIpeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(); 
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeByContactMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(); 
        Map<Id, reduivy__Individual_Program_Enrollment__c> childIpeByContactMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(); 
        Id firstChildIpeId;
        for(reduivy__Individual_Program_Enrollment__c ipe :[
            SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Credits_Earned__c, reduivy__Completion_Percentage__c,
            reduivy__Contact__c, RecordTypeId
            FROM reduivy__Individual_Program_Enrollment__c
        ]) {

            if(ipe.RecordTypeId == IPE_Helper.getMasterEnrollmentRecordTypeId()) {
                masterIpeMap.put(ipe.Id, ipe);
                ipeByContactMap.put(ipe.reduivy__Contact__c, ipe);
            }
            else if(ipe.RecordTypeId == IPE_Helper.getChildEnrollmentRecordTypeId()) {
                childIpeMap.put(ipe.Id, ipe);
                if(firstChildIpeId == null) {
                    firstChildIpeId = ipe.Id;
                } 
            }
        }

        if(firstChildIpeId == null){
            System.Assert.fail('Should be able to get child ipe');
        } 

        
        List<Contact> studentList = [SELECT Id, Name, reduivy__Sample_Record_Code__c FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT];
        
        
        //create ips, ien and iur before modifying ipe units enrolled
        List<reduivy__Individual_Enrollment__c> studentIenList = createStudentEnrolledIen(studentList);
        insert studentIenList;

        Map<Id, reduivy__Individual_Enrollment__c> ienByipe = new Map<Id, reduivy__Individual_Enrollment__c>();
        
        for(reduivy__Individual_Enrollment__c ien : studentIenList) {
            ienByipe.put(ipeByContactMap.get(ien.reduivy__Contact__c).Id, ien);
        }

        reduivy__Study_Plan_Structure__c parentUsps = [SELECT Id,
            reduivy__Allow_Pre_Enrollment__c, reduivy__Category__c, reduivy__Credits__c,
            reduivy__Description__c, reduivy__Hide_in_Enrollment__c, reduivy__Sequence__c, reduivy__Requirement_Logic__c,
            reduivy__Parent_Study_Plan_Structure__c
            FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_COM103' LIMIT 1];

        Map<Id, reduivy__Individual_Plan_Structure__c> parentGroupIpsByIpe = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        
        for(reduivy__Individual_Plan_Structure__c gips : [ SELECT Id, reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__c IN :masterIpeMap.keySet()
            AND reduivy__Study_Plan_Structure__c = :parentUsps.reduivy__Parent_Study_Plan_Structure__c
        ]) {
            parentGroupIpsByIpe.put(gips.reduivy__Individual_Program_Enrollment__c,gips);
        }

        List<reduivy__Individual_Plan_Structure__c> newUnitIps = new List<reduivy__Individual_Plan_Structure__c>();
        for(Id ipeId : masterIpeMap.keySet()){
            reduivy__Individual_Plan_Structure__c unitIps = IPS_Helper.initUnitPlanStructure(ipeId, parentGroupIpsByIpe.get(ipeId).Id, ienByipe.get(ipeId).Id, parentUsps);
            newUnitIps.add(unitIps);
        }

        insert newUnitIps;

        // Verify requirement met and change to invalid matching value before test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        iurList = [
            SELECT reduivy__Requirement_Met__c, reduivy__Requirement_ID__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :masterIpeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CUSTOM
        ];

        


        reduivy__Study_Offering__c cyt2Com103Sof = createComSof();
        insert cyt2Com103Sof;

        // Execute test
        Test.startTest();
        
        System.runAs(ADMIN_USER) {
            
            childIpeMap.get(firstChildIpeId).reduivy__Units_Enrolled__c = 10;
            update childIpeMap.get(firstChildIpeId);
        }
        
        Test.stopTest();

        // Verify test results
        iurList = [
            SELECT reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c IN :masterIpeMap.keySet()
            AND reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CUSTOM AND reduivy__Requirement_Met__c = true
        ];
        System.Assert.isTrue(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );
    }


    static reduivy__Study_Offering__c createComSof(){
              
        String sofSampleDataCode = STUDY_UNIT + '_' + CURRENT_YEAR_TERM_2 + '_' + CAMPUS;
        reduivy__Study_Unit__c com103Sun = [SELECT Id FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = :STUDY_UNIT LIMIT 1];
        reduivy__Study_Term__c term = [SELECT Id, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Census_Date__c FROM reduivy__Study_Term__c WHERE reduivy__Sample_Record_Code__c = :CURRENT_YEAR_TERM_2 LIMIT 1];
        Account sydneyCampus = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];
        
        reduivy__Study_Offering__c cyt2Com103Sof = REDU_TestData_UTIL.newStudyOffering(sofSampleDataCode, com103Sun.Id, term.Id, sydneyCampus.Id, sofSampleDataCode, 30, term.reduivy__Start_Date__c, term.reduivy__End_Date__c);
        cyt2Com103Sof.reduivy__Status_Override__c = SOF_Helper.getEnrollmentClosedStatuses()[0];

        return cyt2Com103Sof;
    }

    static List<reduivy__Individual_Enrollment__c> createStudentEnrolledIen(List<Contact> studentList) {
        String bus101SampleCode = 'BUS101';

        List<reduivy__Individual_Enrollment__c> studentIenList = new List<reduivy__Individual_Enrollment__c>();
        String bus101SampleDataCode = bus101SampleCode + '_' + STARTING_STUDY_TERM + '_' + CAMPUS;
        reduivy__Study_Offering__c bus101sof = [SELECT Id, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Census_Date__c,reduivy__Sample_Record_Code__c FROM reduivy__Study_Offering__c WHERE reduivy__Sample_Record_Code__c = :bus101SampleDataCode];
        for(Contact student : studentList) {
            String src = student.reduivy__Sample_Record_Code__c + '_' + bus101sof.reduivy__Sample_Record_Code__c;
            reduivy__Individual_Enrollment__c newIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(src, student.Id, bus101sof.Id, IEN_Helper.getInProgressStatuses()[0], 1, System.today(), bus101sof.reduivy__Start_Date__c, bus101sof.reduivy__End_Date__c, bus101sof.reduivy__Census_Date__c, 10, null, null, true );
            studentIenList.add(newIen);
        }

        return studentIenList;
    }

    @isTest
    static void testCustomBatch10AsAdmin(){  
        generalTestCustomBatchAsAdmin(10); 
    }

    @isTest
    static void testCustomBatch30AsAdmin(){
        generalTestCustomBatchAsAdmin(30); 
    }

    @isTest
    static void testCustomBatch50AsAdmin(){
        generalTestCustomBatchAsAdmin(50); 
    }

    static void generalTestCustomBatchAsAdmin(Integer numberOfCount) {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Get the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(); 
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeByContactMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(); 
        for(reduivy__Individual_Program_Enrollment__c ipe :[
            SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Credits_Earned__c, reduivy__Completion_Percentage__c,
            reduivy__Contact__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId =: IPE_Helper.getMasterEnrollmentRecordTypeId()
        ]) {
            ipeMap.put(ipe.Id, ipe);
            ipeByContactMap.put(ipe.reduivy__Contact__c, ipe);
        }

        //create ips, ien and iur before modifying ipe units enrolled
        List<Contact> studentList = [SELECT Id, Name, reduivy__Sample_Record_Code__c FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT];

        List<reduivy__Individual_Enrollment__c> studentIenList = createStudentEnrolledIen(studentList);
        insert studentIenList;

        Map<Id, reduivy__Individual_Enrollment__c> ienByipe = new Map<Id, reduivy__Individual_Enrollment__c>();
        
        for(reduivy__Individual_Enrollment__c ien : studentIenList) {
            ienByipe.put(ipeByContactMap.get(ien.reduivy__Contact__c).Id, ien);
        }

        reduivy__Study_Plan_Structure__c parentUsps = [SELECT Id,
            reduivy__Allow_Pre_Enrollment__c, reduivy__Category__c, reduivy__Credits__c,
            reduivy__Description__c, reduivy__Hide_in_Enrollment__c, reduivy__Sequence__c, reduivy__Requirement_Logic__c,
            reduivy__Parent_Study_Plan_Structure__c
            FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA_COM103' LIMIT 1];

        Map<Id, reduivy__Individual_Plan_Structure__c> parentGroupIpsByIpe = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        
        for(reduivy__Individual_Plan_Structure__c gips : [ SELECT Id, reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Study_Plan_Structure__c = :parentUsps.reduivy__Parent_Study_Plan_Structure__c
        ]) {
            parentGroupIpsByIpe.put(gips.reduivy__Individual_Program_Enrollment__c,gips);
        }

        List<reduivy__Individual_Plan_Structure__c> newUnitIps = new List<reduivy__Individual_Plan_Structure__c>();
        for(Id ipeId : ipeMap.keySet()){
            reduivy__Individual_Plan_Structure__c unitIps = IPS_Helper.initUnitPlanStructure(ipeId, parentGroupIpsByIpe.get(ipeId).Id, ienByipe.get(ipeId).Id, parentUsps);
            newUnitIps.add(unitIps);
        }

        insert newUnitIps;
        
        //get one of the ipr and clone numberOfCount times
        reduivy__Individual_Plan_Unit_Requirement__c iurToBeCloned = [SELECT Id,
        reduivy__Field_Name__c, reduivy__Field_Matching_Operator__c, reduivy__Field_Matching_Value__c,
        reduivy__Individual_Plan_Unit__c, reduivy__Requirement_ID__c, reduivy__Requirement_Met__c, reduivy__Requirement_Type__c
        FROM reduivy__Individual_Plan_Unit_Requirement__c WHERE reduivy__Requirement_Type__c = :IUR_Helper.REQTYPE_CUSTOM LIMIT 1];
        
        List<reduivy__Individual_Plan_Unit_Requirement__c> clonedList = cloneIur(iurToBeCloned, numberOfCount);

        // Get the count of IUR records before insertion
        Integer iurCountBefore = [SELECT COUNT() FROM reduivy__Individual_Plan_Unit_Requirement__c];

        Datetime timeBefore = System.now();
        insert clonedList;
        Datetime timeAfter = System.now();
        REDU_Logging_UTIL.debug('Difference in ms (Total number of requirement: ' + numberOfCount + ' ): ',  (timeAfter.millisecond() - timeBefore.millisecond()));

        // Assert that the total count of IUR records increased by the expected amount
        Integer iurCountAfter = [SELECT COUNT() FROM reduivy__Individual_Plan_Unit_Requirement__c];
        System.assertEquals(iurCountBefore + numberOfCount, iurCountAfter, 'Total IUR count should increase by the number of cloned records');
        
        // Assert performance expectation
        Long executionTime = timeAfter.getTime() - timeBefore.getTime();
        System.assert(executionTime < 10000, 'Insertion should complete within reasonable time (less than 10 seconds). Actual time: ' + executionTime + 'ms');
    }

    static List<reduivy__Individual_Plan_Unit_Requirement__c> cloneIur(reduivy__Individual_Plan_Unit_Requirement__c iur, Integer count) {
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        for(Integer i = 0; i < count; i++) {
            reduivy__Individual_Plan_Unit_Requirement__c clonedIur = iur.clone(false, true, false, false);
            iurList.add(clonedIur);
        }
        return iurList;
    }

}