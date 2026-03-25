/**
 * @author      WDCi (dblack)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for IPS_UnitIpsCompletion_EXE
 * @changehistory
 * ISS-001817 13-12-2023 dblack - new class
 * ISS-002034 24-01-2025 XW - remove invalid ipsu and added new test methods
 * ISS-002272 17-02-2025 XW - created some test method for failed ipsu
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@isTest
public inherited sharing class IPS_UnitIpsCompletion_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final Integer IPSU_QTY = 10;

    static final String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);
    static final String SPL_MAJOR = 'BACBIS_MajorA';
    static final String SPL_MINOR = 'BACBIS_MinorA';
    static final String STUDY_INTAKE = 'SYDNEY_BACBIS_CYINTAKE';

    static final String SEQUENCE_SPL = 'Sequence Study Plan';
    static final String BACBIS_SPR_SRC = 'BACBIS';
    static final String ICT101_SRC = 'ICT101';
    static final String BUS101_SRC = 'BUS101';
    static final String BUS101_SOF_SRC = 'BUS101_CYT1_SYDNEY';
    static final String ICT101_SOF_SRC = 'ICT101_CYT1_SYDNEY';

    static final String RO_SPL_NAME = 'Required Optional Study Plan';
    static final Decimal RO_SPL_TOTAL_REQUIRED_CREDITS = 100;
    static final List<String> RO_SUN_SPS_GROUP_CAT = new List<String>{'R1', 'O1'};
    static final List<String> RO_SUN_SPS_UNIT_CAT = new List<String>{'R1', 'O1', 'O2'};
    static final String RO_SPS_GROUP_PREFIX = 'Group ';
    static final String RO_SPS_UNIT_PREFIX = 'UNIT ';
    static final Decimal RO_SPS_GROUP_FIRST_LEVEL_CREDITS = 40;
    static final Decimal RO_SPS_GROUP_SECOND_LEVEL_CREDITS = 20;
    
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
			testFactory.initStudentData(IPF_Helper.getApiName(), true);

            List<reduivy__Individual_Program_Enrollment__c> masterIpeList = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childIpeList = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> requiredOptionalIpeList = new List<reduivy__Individual_Program_Enrollment__c>();
            createSequenceStudyPlan();
            List<reduivy__Study_Plan_Structure__c> roSpsuList = createRequiredOptionalStudyPlan();

            for (Contact student : testFactory.students.values()) {
                String masterIpekey = student.reduivy__Sample_Record_Code__c + '_' + SPL_MAJOR;
                String childIpekey = student.reduivy__Sample_Record_Code__c + '_' + SPL_MINOR;
                String sequenceIpekey = student.reduivy__Sample_Record_Code__c + '_' + SEQUENCE_SPL;
                String roIpekey = student.reduivy__Sample_Record_Code__c + '_' + RO_SPL_NAME;

                reduivy__Individual_Program_Enrollment__c newMasterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    masterIpekey, 
                    student.Id, 
                    testFactory.studyPlans.get(SPL_MAJOR).reduivy__Study_Program__c, 
                    testFactory.studyPlans.get(SPL_MAJOR).Id, 
                    null, 
                    testFactory.academicTerms.get('CYT1').Id, 
                    null, 
                    testFactory.campuses.get('SYDNEY').Id, 
                    String.valueOf(testFactory.academicTerms.get('CYT1').reduivy__Start_Date__c.year()), 
                    'Freshman', 
                    true, 
                    IPE_INPROGRESS_STATUS, 
                    testFactory.individualAcademicProfiles.get(student.reduivy__Sample_Record_Code__c).Id
                );

                reduivy__Individual_Program_Enrollment__c newChildIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(
                    childIpekey, 
                    student.Id, 
                    testFactory.studyPlans.get(SPL_MINOR).reduivy__Study_Program__c, 
                    testFactory.studyPlans.get(SPL_MINOR).Id,
                    null, 
                    IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, 
                    true, 
                    IPE_INPROGRESS_STATUS
                );

       
                reduivy__Individual_Program_Enrollment__c newSequenceIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    sequenceIpekey, 
                    student.Id, 
                    testFactory.studyPlans.get(SEQUENCE_SPL).reduivy__Study_Program__c, 
                    testFactory.studyPlans.get(SEQUENCE_SPL).Id, 
                    null, 
                    testFactory.academicTerms.get('CYT1').Id, 
                    null, 
                    testFactory.campuses.get('SYDNEY').Id, 
                    String.valueOf(testFactory.academicTerms.get('CYT1').reduivy__Start_Date__c.year()), 
                    'Freshman', 
                    true, 
                    IPE_INPROGRESS_STATUS, 
                    testFactory.individualAcademicProfiles.get(student.reduivy__Sample_Record_Code__c).Id
                );

                reduivy__Individual_Program_Enrollment__c newRequiredOptionalIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    roIpekey, 
                    student.Id, 
                    testFactory.studyPlans.get(RO_SPL_NAME).reduivy__Study_Program__c, 
                    testFactory.studyPlans.get(RO_SPL_NAME).Id, 
                    null, 
                    testFactory.academicTerms.get('CYT1').Id, 
                    null, 
                    testFactory.campuses.get('SYDNEY').Id, 
                    String.valueOf(testFactory.academicTerms.get('CYT1').reduivy__Start_Date__c.year()), 
                    'Freshman', 
                    true, 
                    IPE_INPROGRESS_STATUS, 
                    testFactory.individualAcademicProfiles.get(student.reduivy__Sample_Record_Code__c).Id
                );



                masterIpeList.add(newMasterIpe);
                masterIpeList.add(newSequenceIpe);
                masterIpeList.add(newRequiredOptionalIpe);
                requiredOptionalIpeList.add(newRequiredOptionalIpe);
                childIpeList.add(newChildIpe);

            }

            REDU_SystemMode_UTIL.doInsert(masterIpeList);

            Integer counter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childIpeList) {
                childIpe.reduivy__Master_Enrollment__c = masterIpeList.get(counter).Id;
            }

            REDU_SystemMode_UTIL.doInsert(childIpeList);

            List<String> spsgName = new List<String> {
                RO_SPS_GROUP_PREFIX + 'R1O1',
                RO_SPS_GROUP_PREFIX + 'O1O1',
                RO_SPS_GROUP_PREFIX + 'R1R1',
                RO_SPS_GROUP_PREFIX + 'O1R1'
            };

            Map<String, reduivy__Individual_Plan_Structure__c> secondLevelIpsgMap = new Map<String, reduivy__Individual_Plan_Structure__c>();
            
            for(reduivy__Individual_Plan_Structure__c secondLevelSpsg : [
                SELECT Id, Name, reduivy__Study_Plan_Structure__c, reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c
                FROM reduivy__Individual_Plan_Structure__c
                WHERE RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
                AND reduivy__Parent_Plan_Structure__c != null
                AND reduivy__Study_Plan_Structure__r.Name IN :spsgName
            ]) {
                secondLevelIpsgMap.put(secondLevelSpsg.reduivy__Individual_Program_Enrollment__c, secondLevelSpsg);
            }

            List<reduivy__Individual_Plan_Structure__c> optionalIpsuList = new List<reduivy__Individual_Plan_Structure__c>();

            for(reduivy__Study_Plan_Structure__c roSpsu : roSpsuList){
                if(roSpsu.reduivy__Category__c == SPS_Helper.CATEGORY_REQUIRED) {
                    continue;
                }

                for(reduivy__Individual_Program_Enrollment__c roIpe : requiredOptionalIpeList) {
                    if(roSpsu.reduivy__Parent_Study_Plan_Structure__c == secondLevelIpsgMap.get(roIpe.Id).reduivy__Study_Plan_Structure__c){
                        reduivy__Individual_Plan_Structure__c optionalIpsu = IPS_Helper.initUnitPlanStructure(roIpe.Id, secondLevelIpsgMap.get(roIpe.Id).Id, null, roSpsu);
                        optionalIpsuList.add(optionalIpsu);
                    }
                }
            }

            insert optionalIpsuList;
            


            Test.stopTest();
            
        }
    }

    /**
     * @description Test as an admin user that an insert of an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     * according to the individual plan unit primary
     */
    @isTest
    static void testA_IpsUnitRollUpToParentGroupByPrimaryAfterInsertAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data
        String splQuery = '%' + SPL_MAJOR;
        
        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Target_Unit_Id__c, reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c, RecordTypeId,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c, reduivy__Study_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ips : ipsMap.get(ipeId).get(ipsgId)) {

                    reduivy__Individual_Plan_Structure__c ipsu1 = ips.clone(false, true, false, false);
                    ipsu1.reduivy__Primary__c = false;
                    ipsu1.reduivy__Status__c = 'Completed';
                    ipsuList.add(ipsu1);

                    reduivy__Individual_Plan_Structure__c ipsu2 = ipsu1.clone(false, true, false, false);
                    if (!sunIdSet.contains(ipsu2.reduivy__Target_Unit_Id__c)) {
                        ipsu2.reduivy__Primary__c = true;
                        sunIdSet.add(ipsu2.reduivy__Target_Unit_Id__c);
                    }
                    ipsuList.add(ipsu2);
                }
            }
        }

        System.runAs(ADMIN_USER) {

            // Execute test by inserting duplicate ips unit 
            Test.startTest();
            insert ipsuList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c = 'Completed'
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {

                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
                expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                ++expectedUnitsPassed;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as an admin user that an insert to an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     * according to the individual plan group sequence number
     */
    @isTest
    static void testB_IpsUnitRollUpToParentGroupBySequenceAfterInsertAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data
        String splQuery = '%' + SPL_MAJOR;
        
        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c, RecordTypeId,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c, reduivy__Study_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ips : ipsMap.get(ipeId).get(ipsgId)) {

                    reduivy__Individual_Plan_Structure__c ipsu1 = ips.clone(false, true, false, false);
                    ipsu1.reduivy__Primary__c = false;
                    ipsu1.reduivy__Status__c = 'Completed';
                    ipsuList.add(ipsu1);
                }
            }
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            insert ipsuList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c = 'Completed'
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {
                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
                expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                ++expectedUnitsPassed;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a faculty user that an insert of an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     * according to the individual plan unit primary
     */
    @isTest
    static void testC_IpsUnitRollUpToParentGroupByPrimaryAfterInsertAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data
        String splQuery = '%' + SPL_MAJOR;
        
        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Target_Unit_Id__c, reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c, RecordTypeId,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c, reduivy__Study_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ips : ipsMap.get(ipeId).get(ipsgId)) {

                    reduivy__Individual_Plan_Structure__c ipsu1 = ips.clone(false, true, false, false);
                    ipsu1.reduivy__Primary__c = false;
                    ipsu1.reduivy__Status__c = 'Completed';
                    ipsuList.add(ipsu1);

                    reduivy__Individual_Plan_Structure__c ipsu2 = ipsu1.clone(false, true, false, false);
                    if (!sunIdSet.contains(ipsu2.reduivy__Target_Unit_Id__c)) {
                        ipsu2.reduivy__Primary__c = true;
                        sunIdSet.add(ipsu2.reduivy__Target_Unit_Id__c);
                    }
                    ipsuList.add(ipsu2);
                }
            }
        }

        System.runAs(FACULTY_USER) {

            // Execute test by inserting duplicate ips unit 
            Test.startTest();
            insert ipsuList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c = 'Completed'
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {

                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
				expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                ++expectedUnitsPassed;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );
			
			System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a faculty user that an insert to an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     * according to the individual plan group sequence number
     */
    @isTest
    static void testD_IpsUnitRollUpToParentGroupBySequenceAfterInsertAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data
        String splQuery = '%' + SPL_MAJOR;
        
        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c, RecordTypeId,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c, reduivy__Study_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ips : ipsMap.get(ipeId).get(ipsgId)) {

                    reduivy__Individual_Plan_Structure__c ipsu1 = ips.clone(false, true, false, false);
                    ipsu1.reduivy__Primary__c = false;
                    ipsu1.reduivy__Status__c = 'Completed';
                    ipsuList.add(ipsu1);
                }
            }
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            insert ipsuList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c = 'Completed'
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {
                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
				expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                ++expectedUnitsPassed;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );
			
			System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a student user that an insert of an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     * according to the individual plan unit primary
     */
    @isTest
    static void testE_IpsUnitRollUpToParentGroupByPrimaryAfterInsertAsStudent() {

        // Setup test data
        String splQuery = '%' + SPL_MAJOR;
        
        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Target_Unit_Id__c, reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c, RecordTypeId,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c, reduivy__Study_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN :studentContacts
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ips : ipsMap.get(ipeId).get(ipsgId)) {

                    reduivy__Individual_Plan_Structure__c ipsu1 = ips.clone(false, true, false, false);
                    ipsu1.reduivy__Primary__c = false;
                    ipsu1.reduivy__Status__c = 'Completed';
                    ipsuList.add(ipsu1);

                    reduivy__Individual_Plan_Structure__c ipsu2 = ipsu1.clone(false, true, false, false);
                    if (!sunIdSet.contains(ipsu2.reduivy__Target_Unit_Id__c)) {
                        ipsu2.reduivy__Primary__c = true;
                        sunIdSet.add(ipsu2.reduivy__Target_Unit_Id__c);
                    }
                    ipsuList.add(ipsu2);
                }
            }
        }

        System.runAs(studentUser) {

            // Execute test by inserting duplicate ips unit 
            Test.startTest();
            insert ipsuList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c = 'Completed'
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {

                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
				expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                ++expectedUnitsPassed;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );
			
			System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a student user that an insert to an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     * according to the individual plan group sequence number
     */
    @isTest
    static void testF_IpsUnitRollUpToParentGroupBySequenceAfterInsertAsStudent() {

        // Setup test data
        String splQuery = '%' + SPL_MAJOR;
        
        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c, RecordTypeId,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c, reduivy__Study_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN :studentContacts
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ips : ipsMap.get(ipeId).get(ipsgId)) {

                    reduivy__Individual_Plan_Structure__c ipsu1 = ips.clone(false, true, false, false);
                    ipsu1.reduivy__Primary__c = false;
                    ipsu1.reduivy__Status__c = 'Completed';
                    ipsuList.add(ipsu1);

                }
            }
        }

        System.runAs(studentUser) {

            // Execute test
            Test.startTest();
            insert ipsuList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c = 'Completed'
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {
                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
				expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                ++expectedUnitsPassed;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );
			
			System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as an admin user that an update to an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     * according to the individual plan unit primary
     */
    @isTest
    static void testG_IpsUnitRollUpToParentGroupByPrimaryAfterUpdateAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data
        String splQuery = '%' + SPL_MAJOR;
        
        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsUnitList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                List<reduivy__Individual_Plan_Structure__c> ipsuList = ipsMap.get(ipeId).get(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

                    index = ipsUnitList.indexOf(ipsu);
                    ipsu.reduivy__Primary__c = (Math.mod(index, 2) == 0) ? true : false;
                    ipsu.reduivy__Status__c = 'Completed';
                    ipsUnitList.add(ipsu);
                }
            }
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            update ipsUnitList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c = 'Completed'
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {
                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
				expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                ++expectedUnitsPassed;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );
			
			System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as an admin user that an update to an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     * according to the individual plan group sequence number
     */
    @isTest
    static void testH_IpsUnitRollUpToParentGroupBySequenceAfterUpdateAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data
        String splQuery = '%' + SPL_MAJOR;
        
        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsUnitList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                List<reduivy__Individual_Plan_Structure__c> ipsuList = ipsMap.get(ipeId).get(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

                    index = ipsUnitList.indexOf(ipsu);
                    ipsu.reduivy__Primary__c = false;
                    ipsu.reduivy__Status__c = 'Completed';
                    ipsUnitList.add(ipsu);
                }
            }
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            update ipsUnitList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c = 'Completed'
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {
                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
				expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                ++expectedUnitsPassed;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );
			
			System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a faculty user that an update to an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     * according to the individual plan unit primary
     */
    @isTest
    static void testI_IpsUnitRollUpToParentGroupByPrimaryAfterUpdateAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data
        String splQuery = '%' + SPL_MAJOR;
        
        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsUnitList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                List<reduivy__Individual_Plan_Structure__c> ipsuList = ipsMap.get(ipeId).get(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

                    index = ipsUnitList.indexOf(ipsu);
                    ipsu.reduivy__Primary__c = (Math.mod(index, 2) == 0) ? true : false;
                    ipsu.reduivy__Status__c = 'Completed';
                    ipsUnitList.add(ipsu);
                }
            }
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            update ipsUnitList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c = 'Completed'
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {
                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
				expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                ++expectedUnitsPassed;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );
			
			System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a faculty user that an update to an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     * according to the individual plan group sequence number
     */
    @isTest
    static void testJ_IpsUnitRollUpToParentGroupBySequenceAfterUpdateAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data
        String splQuery = '%' + SPL_MAJOR;
        
        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsUnitList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                List<reduivy__Individual_Plan_Structure__c> ipsuList = ipsMap.get(ipeId).get(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

                    index = ipsUnitList.indexOf(ipsu);
                    ipsu.reduivy__Primary__c = false;
                    ipsu.reduivy__Status__c = 'Completed';
                    ipsUnitList.add(ipsu);
                }
            }
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            update ipsUnitList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c = 'Completed'
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {
                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
				expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                ++expectedUnitsPassed;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );
			
			System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a student user that an update to an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     * according to the individual plan unit primary
     */
    @isTest
    static void testK_IpsUnitRollUpToParentGroupByPrimaryAfterUpdateAsStudent() {

        // Setup test data
        String splQuery = '%' + SPL_MAJOR;
        
        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN :studentContacts
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsUnitList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                List<reduivy__Individual_Plan_Structure__c> ipsuList = ipsMap.get(ipeId).get(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

                    index = ipsUnitList.indexOf(ipsu);
                    ipsu.reduivy__Primary__c = (Math.mod(index, 2) == 0) ? true : false;
                    ipsu.reduivy__Status__c = 'Completed';
                    ipsUnitList.add(ipsu);
                }
            }
        }

        System.runAs(studentUser) {

            // Execute test
            Test.startTest();
            update ipsUnitList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c = 'Completed'
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {
                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
				expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                ++expectedUnitsPassed;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );
			
			System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a student user that an update to an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     * according to the individual plan group sequence number
     */
    @isTest
    static void testL_IpsUnitRollUpToParentGroupBySequenceAfterUpdateAsStudent() {

        // Setup test data
        String splQuery = '%' + SPL_MAJOR;
        
        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN :studentContacts
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsUnitList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                List<reduivy__Individual_Plan_Structure__c> ipsuList = ipsMap.get(ipeId).get(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

                    index = ipsUnitList.indexOf(ipsu);
                    ipsu.reduivy__Primary__c = false;
                    ipsu.reduivy__Status__c = 'Completed';
                    ipsUnitList.add(ipsu);
                }
            }
        }

        System.runAs(studentUser) {

            // Execute test
            Test.startTest();
            update ipsUnitList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c = 'Completed'
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {
                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
				expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                ++expectedUnitsPassed;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );
			
			System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as an admin user that deletion of an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     */
    @isTest
    static void testM_IpsUnitRollUpToParentGroupAfterDeleteAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data
        String splQuery = '%' + SPL_MAJOR;
        
        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsUnitList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                List<reduivy__Individual_Plan_Structure__c> ipsuList = ipsMap.get(ipeId).get(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

                    index = ipsUnitList.indexOf(ipsu);
                    ipsu.reduivy__Primary__c = (Math.mod(index, 2) == 0) ? true : false;
                    ipsu.reduivy__Status__c = 'Completed';
                    ipsUnitList.add(ipsu);
                }
            }
        }

        System.runAs(ADMIN_USER) {
            update ipsUnitList;
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c = 'Completed'
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {
                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
				expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                ++expectedUnitsPassed;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );
			
			System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            delete ipsUnitList;
            Test.stopTest();
		}

        // Verify test results
        ipsgList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            System.Assert.areEqual(
                0, ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                0, ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                0, ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                0, ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                0, ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a faculty user that deletion of an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     */
    @isTest
    static void testN_IpsUnitRollUpToParentGroupAfterDeleteAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data
        String splQuery = '%' + SPL_MAJOR;
        
        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsUnitList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                List<reduivy__Individual_Plan_Structure__c> ipsuList = ipsMap.get(ipeId).get(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

                    index = ipsUnitList.indexOf(ipsu);
                    ipsu.reduivy__Primary__c = (Math.mod(index, 2) == 0) ? true : false;
                    ipsu.reduivy__Status__c = 'Completed';
                    ipsUnitList.add(ipsu);
                }
            }
        }

        update ipsUnitList;

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c = 'Completed'
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {
                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
				expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                ++expectedUnitsPassed;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );
			
			System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            
            try {
                delete ipsUnitList;
                System.Assert.fail('This should fail with insufficient access error.');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'));
            }
            
            Test.stopTest();
		}
    }

    /**
     * @description Test as a student user that deletion of an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     */
    @isTest
    static void testO_IpsUnitRollUpToParentGroupAfterDeleteAsStudent() {

        // Setup test data
        String splQuery = '%' + SPL_MAJOR;
        
        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN :studentContacts
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsUnitList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                List<reduivy__Individual_Plan_Structure__c> ipsuList = ipsMap.get(ipeId).get(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

                    index = ipsUnitList.indexOf(ipsu);
                    ipsu.reduivy__Primary__c = (Math.mod(index, 2) == 0) ? true : false;
                    ipsu.reduivy__Status__c = 'Completed';
                    ipsUnitList.add(ipsu);
                }
            }
        }

        update ipsUnitList;

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c = 'Completed'
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {
                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
				expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                ++expectedUnitsPassed;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );
			
			System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }

        System.runAs(studentUser) {

            // Execute test
            Test.startTest();

            try {
                delete ipsUnitList;
                System.Assert.fail('This should fail with insufficient access error.');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'));
            }

            Test.stopTest();
		}
    }

    
    /**
     * @description Test as an admin user that an insert to an ien contribute credits to the correct parent ips group if primary ips group isnt speficied
     */
    @isTest
    static void testP_IpsUnitContributionNonPrimaryAfterInsertAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Study_Offering__c bus101Sof = null;
        reduivy__Study_Offering__c ict101Sof = null;

        for(reduivy__Study_Offering__c sof : [
        SELECT Id, Name, reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
        FROM reduivy__Study_Offering__c
        WHERE reduivy__Sample_Record_Code__c IN (:BUS101_SOF_SRC, :ICT101_SOF_SRC)]) {
            if(sof.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == BUS101_SRC) {
                bus101Sof = sof;
            } else if (sof.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == ICT101_SRC) {
                ict101Sof = sof;
            }
        }

        System.Assert.isNotNull(bus101Sof, BUS101_SOF_SRC + ' should be created!');
        System.Assert.isNotNull(ict101Sof, ICT101_SOF_SRC + ' should be created!');

        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        List<Contact> students = [SELECT Id FROM Contact where reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN :students];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        for(Contact student: students) {
            
            reduivy__Individual_Enrollment__c bus1Ien = new reduivy__Individual_Enrollment__c();
            bus1Ien.reduivy__Study_Offering__c = bus101Sof.Id;
            bus1Ien.RecordTypeId = IEN_Helper.getStudentRecordTypeId();
            bus1Ien.reduivy__Contact__c = student.Id;
            bus1Ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            bus1Ien.reduivy__Numerical_Grade__c = 60;
            bus1Ien.reduivy__Individual_Academic_Profile__c = studentToIPFMap.get(student.Id);
            ienList.add(bus1Ien);
            
            reduivy__Individual_Enrollment__c ict1Ien = new reduivy__Individual_Enrollment__c();
            ict1Ien.RecordTypeId = IEN_Helper.getStudentRecordTypeId();
            ict1Ien.reduivy__Study_Offering__c = ict101Sof.Id;
            ict1Ien.reduivy__Contact__c = student.Id;
            ict1Ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ict1Ien.reduivy__Numerical_Grade__c = 60;
            ict1Ien.reduivy__Individual_Academic_Profile__c = studentToIPFMap.get(student.Id);
            ienList.add(ict1Ien);
        }
        
        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            insert ienList;
            Test.stopTest();
		}

        String splQuery = '%' + SEQUENCE_SPL;
        
        // Verify test results
        for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT 
            Id, Name, reduivy__Parent_Plan_Structure__r.reduivy__Study_Plan_Structure__r.reduivy__Sequence__c,
            reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c,
            reduivy__Credits_Contribution__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
            AND reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = :ICT101_SRC
            LIMIT :IPSU_QTY
            ]) {

            if(ipsUnit.reduivy__Parent_Plan_Structure__r.reduivy__Study_Plan_Structure__r.reduivy__Sequence__c == 2) {
                System.Assert.areEqual(ipsUnit.reduivy__Credits_Contribution__c, IPS_Helper.CREDITS_CONTRIBUTION_YES, 'This ipsUnit should be contribute credit to its parent group!');
            } else{
                System.Assert.areEqual(ipsUnit.reduivy__Credits_Contribution__c, IPS_Helper.CREDITS_CONTRIBUTION_NO, 'This ipsUnit should not be contribute credit to its parent group!');
            }
        }
       
    }
    
    /**
     * @description Test as an admin user that an update to an ien contribute credits to the correct parent ips group if primary ips group isnt speficied
     */
    @isTest
    static void testQ_IpsUnitContributionNonPrimaryAfterUpdateAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Study_Offering__c bus101Sof = null;
        reduivy__Study_Offering__c ict101Sof = null;

        for(reduivy__Study_Offering__c sof : [
        SELECT Id, Name, reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
        FROM reduivy__Study_Offering__c
        WHERE reduivy__Sample_Record_Code__c IN (:BUS101_SOF_SRC, :ICT101_SOF_SRC)]) {
            if(sof.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == BUS101_SRC) {
                bus101Sof = sof;
            } else if (sof.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == ICT101_SRC) {
                ict101Sof = sof;
            }
        }

        System.Assert.isNotNull(bus101Sof, BUS101_SOF_SRC + ' should be created!');
        System.Assert.isNotNull(ict101Sof, ICT101_SOF_SRC + ' should be created!');

        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        List<Contact> students = [SELECT Id FROM Contact where reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN :students];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        for(Contact student: students) {
            
            reduivy__Individual_Enrollment__c bus1Ien = new reduivy__Individual_Enrollment__c();
            bus1Ien.reduivy__Study_Offering__c = bus101Sof.Id;
            bus1Ien.RecordTypeId = IEN_Helper.getStudentRecordTypeId();
            bus1Ien.reduivy__Contact__c = student.Id;
            bus1Ien.reduivy__Individual_Academic_Profile__c = studentToIPFMap.get(student.Id);
            ienList.add(bus1Ien);
            
            reduivy__Individual_Enrollment__c ict1Ien = new reduivy__Individual_Enrollment__c();
            ict1Ien.RecordTypeId = IEN_Helper.getStudentRecordTypeId();
            ict1Ien.reduivy__Study_Offering__c = ict101Sof.Id;
            ict1Ien.reduivy__Contact__c = student.Id;
            ict1Ien.reduivy__Individual_Academic_Profile__c = studentToIPFMap.get(student.Id);
            ienList.add(ict1Ien);

        }

        insert ienList;

        // Setup test data
        String splQuery = '%' + SEQUENCE_SPL;
        
        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT Id
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        for(reduivy__Individual_Enrollment__c  ien : ienList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Numerical_Grade__c = 60;
        }
        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            update ienList;
            Test.stopTest();
		}
        
        // Verify test results
        for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT 
            Id, Name, reduivy__Parent_Plan_Structure__r.reduivy__Study_Plan_Structure__r.reduivy__Sequence__c,
            reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c,
            reduivy__Credits_Contribution__c
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE Id IN :ipsList
            AND reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = :ICT101_SRC]) {

            if(ipsUnit.reduivy__Parent_Plan_Structure__r.reduivy__Study_Plan_Structure__r.reduivy__Sequence__c == 2) {
                System.Assert.areEqual(ipsUnit.reduivy__Credits_Contribution__c, IPS_Helper.CREDITS_CONTRIBUTION_YES, 'This ipsUnit should be contribute credit to its parent group!');
            } else{
                System.Assert.areEqual(ipsUnit.reduivy__Credits_Contribution__c, IPS_Helper.CREDITS_CONTRIBUTION_NO, 'This ipsUnit should not be contribute credit to its parent group!');
            }
        }
       
    }

    static void createSequenceStudyPlan() {
        reduivy__Study_Plan__c newSpl = new reduivy__Study_Plan__c();
        newSpl.Name = SEQUENCE_SPL;
        newSpl.reduivy__Sample_Record_Code__c = SEQUENCE_SPL;
        newSpl.reduivy__Study_Program__c = testFactory.studyPrograms.get(BACBIS_SPR_SRC).Id;
     
        insert newSpl;
        testFactory.studyPlans.put(SEQUENCE_SPL, newSpl);

        List<reduivy__Study_Plan_Structure__c> spsgList = new List<reduivy__Study_Plan_Structure__c>();
        for(Integer i = 1; i <= 3; i++) {
            reduivy__Study_Plan_Structure__c newSpsg = new reduivy__Study_Plan_Structure__c();
            newSpsg.Name = 'Group ' + String.valueOf(i);
            newSpsg.reduivy__Study_Plan__c = newSpl.Id;
            newSpsg.reduivy__Category__c = SPS_Helper.CATEGORY_OPTIONAL;
            newSpsg.reduivy__Sequence__c = i;
            newSpsg.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
            newSpsg.reduivy__Credits__c = 10;
            spsgList.add(newSpsg);   
        }
        insert spsgList;

        List<reduivy__Study_Plan_Structure__c> spsuList = new List<reduivy__Study_Plan_Structure__c>();
        for(reduivy__Study_Plan_Structure__c spsg : spsgList) {
            reduivy__Study_Plan_Structure__c newSpsu = new reduivy__Study_Plan_Structure__c();
            newSpsu.Name = spsg.Name + ' ' + ICT101_SRC;
            newSpsu.reduivy__Sample_Record_Code__c = newSpsu.Name;
            newSpsu.reduivy__Study_Plan__c = newSpl.Id;
            newSpsu.reduivy__Category__c = SPS_Helper.CATEGORY_OPTIONAL;
            newSpsu.reduivy__Parent_Study_Plan_Structure__c = spsg.Id;
            newSpsu.reduivy__Study_Unit__c = testFactory.studyUnits.get(ICT101_SRC).Id;
            newSpsu.RecordTypeId = SPS_Helper.getUnitRecordTypeId();
            newSpsu.reduivy__Credits__c = 10;
            spsuList.add(newSpsu);
        }

        reduivy__Study_Plan_Structure__c newBUS101Spsu = new reduivy__Study_Plan_Structure__c();
        newBUS101Spsu.Name = spsgList.get(0).Name + ' ' + BUS101_SRC;
        newBUS101Spsu.reduivy__Sample_Record_Code__c = newBUS101Spsu.Name;
        newBUS101Spsu.reduivy__Study_Plan__c = newSpl.Id;
        newBUS101Spsu.reduivy__Category__c = SPS_Helper.CATEGORY_OPTIONAL;
        newBUS101Spsu.reduivy__Parent_Study_Plan_Structure__c = spsgList.get(0).Id;
        newBUS101Spsu.reduivy__Study_Unit__c = testFactory.studyUnits.get(BUS101_SRC).Id;
        newBUS101Spsu.RecordTypeId = SPS_Helper.getUnitRecordTypeId();
        spsuList.add(newBUS101Spsu);

        insert spsuList;



    }

    
    static List<reduivy__Study_Plan_Structure__c> createRequiredOptionalStudyPlan(){
        reduivy__Study_Plan__c newSpl = new reduivy__Study_Plan__c();
        newSpl.Name = RO_SPL_NAME;
        newSpl.reduivy__Sample_Record_Code__c = RO_SPL_NAME;
        newSpl.reduivy__Study_Program__c = testFactory.studyPrograms.get(BACBIS_SPR_SRC).Id;
        newSpl.reduivy__Total_Required_Credits__c = RO_SPL_TOTAL_REQUIRED_CREDITS;
     
        insert newSpl;
        testFactory.studyPlans.put(RO_SPL_NAME, newSpl);

        Map<String, reduivy__Study_Unit__c> name_sunMap = createRequiredOptionalStudyUnit();
        system.debug(JSON.serialize(name_sunMap));

        //first level
        List<reduivy__Study_Plan_Structure__c> spsg1List = new List<reduivy__Study_Plan_Structure__c>();
        for(String firstLevelCat : RO_SUN_SPS_GROUP_CAT){
            reduivy__Study_Plan_Structure__c newSpsg = new reduivy__Study_Plan_Structure__c();
            newSpsg.Name = RO_SPS_GROUP_PREFIX + String.valueOf(firstLevelCat);
            newSpsg.reduivy__Study_Plan__c = newSpl.Id;
            newSpsg.reduivy__Category__c = firstLevelCat == 'R1' ? 'Required' : 'Optional';
            newSpsg.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
            newSpsg.reduivy__Credits__c = RO_SPS_GROUP_FIRST_LEVEL_CREDITS;
            spsg1List.add(newSpsg);   
        }
        insert spsg1List;

        //second level
        List<reduivy__Study_Plan_Structure__c> spsg2List = new List<reduivy__Study_Plan_Structure__c>();
        for( reduivy__Study_Plan_Structure__c spsgParent : spsg1List) {
            for(String secondLevelCat : RO_SUN_SPS_GROUP_CAT){
                reduivy__Study_Plan_Structure__c newSpsg = new reduivy__Study_Plan_Structure__c();
                newSpsg.Name = spsgParent.Name + String.valueOf(secondLevelCat);
                newSpsg.reduivy__Study_Plan__c = newSpl.Id;
                newSpsg.reduivy__Parent_Study_Plan_Structure__c = spsgParent.Id;
                newSpsg.reduivy__Category__c = secondLevelCat == 'R1' ? 'Required' : 'Optional';
                newSpsg.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
                newSpsg.reduivy__Credits__c = RO_SPS_GROUP_SECOND_LEVEL_CREDITS;
                spsg2List.add(newSpsg);
            }
        }
        insert spsg2List;

        List<reduivy__Study_Plan_Structure__c> spsuList = new List<reduivy__Study_Plan_Structure__c>();

        //unit
        for(reduivy__Study_Plan_Structure__c spsg2 : spsg2List) {
            for(String childCategory : RO_SUN_SPS_UNIT_CAT){
                reduivy__Study_Unit__c sun = name_sunMap.get(spsg2.Name.removeStart(RO_SPS_GROUP_PREFIX) + childCategory);

                reduivy__Study_Plan_Structure__c newSpsu = new reduivy__Study_Plan_Structure__c();
                newSpsu.Name = RO_SPS_UNIT_PREFIX + sun.Name;
                newSpsu.reduivy__Sample_Record_Code__c = newSpsu.Name;
                newSpsu.reduivy__Study_Plan__c = newSpl.Id;
                newSpsu.reduivy__Category__c = childCategory == 'R1' ? 'Required' : 'Optional';
                newSpsu.reduivy__Parent_Study_Plan_Structure__c = spsg2.Id;
                newSpsu.reduivy__Study_Unit__c = sun.Id;
                newSpsu.RecordTypeId = SPS_Helper.getUnitRecordTypeId();
                newSpsu.reduivy__Credits__c = 10;
                spsuList.add(newSpsu);
            }
        }

        insert spsuList;

        return spsuList;
    }

    /**
     * @description create study units for required and optional use case to avoid confusion and to control the sps structure better.
     */
    static Map<String, reduivy__Study_Unit__c> createRequiredOptionalStudyUnit() {
        List<reduivy__Study_Unit__c> studyUnitList = new List<reduivy__Study_Unit__c>();

        for(String firstLevelGroupCategory : RO_SUN_SPS_GROUP_CAT) {
            for(String secondLevelGroupCategory : RO_SUN_SPS_GROUP_CAT){
                for(String childCategory : RO_SUN_SPS_UNIT_CAT){
                    String sunName = firstLevelGroupCategory + secondLevelGroupCategory + childCategory;
                    reduivy__Study_Unit__c sun = REDU_TestData_UTIL.newStudyUnit(sunName, testFactory.eduInst.Id, testFactory.studyGradeSettings.get('PERCENTAGE_SCORE').Id, sunName, sunName, 10, 'Business, Management, and Marketing', '100', 0.125, null);
                    studyUnitList.add(sun);

                }  
            }
        }

        insert studyUnitList;

        Map<String, reduivy__Study_Unit__c> name_sunMap = new Map<String, reduivy__Study_Unit__c>();

        for(reduivy__Study_Unit__c sun : studyUnitList) {
            name_sunMap.put(sun.Name, sun);
        }
        return name_sunMap;
    }


    /**
     * @description Test as an admin user that an insert of an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     * according to the individual plan unit primary
     */
    @isTest
    static void testR_FailedIpsUnitRollUpToParentGroupByPrimaryAfterInsertAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data
        
        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Target_Unit_Id__c, reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c, RecordTypeId,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c, reduivy__Study_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ips : ipsMap.get(ipeId).get(ipsgId)) {

                    reduivy__Individual_Plan_Structure__c ipsu1 = ips.clone(false, true, false, false);
                    ipsu1.reduivy__Primary__c = false;
                    ipsu1.reduivy__Status__c = 'Completed';
                    ipsuList.add(ipsu1);

                    reduivy__Individual_Plan_Structure__c ipsu2 = ipsu1.clone(false, true, false, false);
                    if (!sunIdSet.contains(ipsu2.reduivy__Target_Unit_Id__c)) {
                        ipsu2.reduivy__Primary__c = true;
                        sunIdSet.add(ipsu2.reduivy__Target_Unit_Id__c);
                    }
                    ipsu2.reduivy__Status__c = 'Failed';
                    ipsuList.add(ipsu2);
                    
                }
            }
        }

        System.runAs(ADMIN_USER) {

            // Execute test by inserting duplicate ips unit 
            Test.startTest();
            insert ipsuList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Status__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c IN ('Completed', 'Failed')
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {

                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
                expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                expectedUnitsPassed += (ipsu.reduivy__Status__c == 'Completed') ? 1 : 0;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as an admin user that an insert of an failed individual plan structure (unit) rolls up to the parent individual plan structure (group)
     * according to the individual plan unit primary
     */
    @isTest
    static void testS_FailedIpsUnitRollUpToParentGroupByPrimaryAfterUpdateAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data
        
        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Target_Unit_Id__c, reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c, RecordTypeId,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c, reduivy__Study_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ips : ipsMap.get(ipeId).get(ipsgId)) {

                    reduivy__Individual_Plan_Structure__c ipsu1 = ips.clone(false, true, false, false);
                    ipsu1.reduivy__Primary__c = false;
                    ipsu1.reduivy__Status__c = 'Completed';
                    ipsuList.add(ipsu1);

                    reduivy__Individual_Plan_Structure__c ipsu2 = ipsu1.clone(false, true, false, false);
                    if (!sunIdSet.contains(ipsu2.reduivy__Target_Unit_Id__c)) {
                        ipsu2.reduivy__Primary__c = true;
                        sunIdSet.add(ipsu2.reduivy__Target_Unit_Id__c);
                    }
                    ipsu2.reduivy__Status__c = 'Failed';
                    ipsuList.add(ipsu2);
                    
                }
            }
        }

        System.runAs(ADMIN_USER) {

            // Execute test by inserting duplicate ips unit 
            Test.startTest();
            insert ipsuList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Status__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c IN ('Completed', 'Failed')
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {

                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
                expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                expectedUnitsPassed += (ipsu.reduivy__Status__c == 'Completed') ? 1 : 0;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    
    /**
     * @description Test as an admin user that an update to an failed individual plan structure (unit) rolls up to the parent individual plan structure (group)
     * according to the individual plan unit primary
     */
    @isTest
    static void testT_FailedIpsUnitRollUpToParentGroupByPrimaryAfterUpdateAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data
        
        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsUnitList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                List<reduivy__Individual_Plan_Structure__c> ipsuList = ipsMap.get(ipeId).get(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

                    index = ipsUnitList.indexOf(ipsu);
                    if(Math.mod(index, 2) == 0) {
                        ipsu.reduivy__Primary__c = true;
                        ipsu.reduivy__Status__c = 'Completed';
                    } else {
                        ipsu.reduivy__Primary__c = false;
                        ipsu.reduivy__Status__c = 'Failed';
                    }
                    ipsUnitList.add(ipsu);
                }
            }
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            update ipsUnitList;
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Status__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c IN ('Completed', 'Failed')
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {
                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
				expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                expectedUnitsPassed += (ipsu.reduivy__Status__c == 'Completed') ? 1 : 0;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );
			
			System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

        /**
     * @description Test as an admin user that deletion of an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     */
    @isTest
    static void testU_FailedIpsUnitRollUpToParentGroupAfterDeleteAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data
        
        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            LIMIT :IPSU_QTY
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            if (!ipsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new Map<Id, List<reduivy__Individual_Plan_Structure__c>>());
            }
            if (!ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipsMap.get(ips.reduivy__Individual_Program_Enrollment__c).get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
        }

        List<reduivy__Individual_Plan_Structure__c> ipsUnitList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();
        Integer index;

        for (Id ipeId : ipsMap.keySet()) {
            Set<Id> sunIdSet = new Set<Id>();
            for (Id ipsgId : ipsMap.get(ipeId).keySet()) {
                ipsgIdSet.add(ipsgId);
                List<reduivy__Individual_Plan_Structure__c> ipsuList = ipsMap.get(ipeId).get(ipsgId);
                for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

                    index = ipsUnitList.indexOf(ipsu);
                    if(Math.mod(index, 2) == 0) {
                        ipsu.reduivy__Primary__c = true;
                        ipsu.reduivy__Status__c = 'Completed';
                    } else {
                        ipsu.reduivy__Primary__c = false;
                        ipsu.reduivy__Status__c = 'Failed';
                    }
                    ipsUnitList.add(ipsu);
                }
            }
        }

        System.runAs(ADMIN_USER) {
            update ipsUnitList;
		}

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Status__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c IN ('Completed', 'Failed')
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {
                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
				expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                expectedUnitsPassed += (ipsu.reduivy__Status__c == 'Completed') ? 1 : 0;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );
			
			System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            delete ipsUnitList;
            Test.stopTest();
		}

        // Verify test results
        ipsgList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            System.Assert.areEqual(
                0, ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                0, ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                0, ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                0, ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                0, ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    
    /**
     * @description Test as an admin user that an insert of an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     * according to the individual plan unit primary
     */
    @isTest
    static void testV_IpsUnitRollUpToParentGroupAfterUpdate_OptionalOnly_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data
        String splQuery = '%' + RO_SPL_NAME;
        
        
        //only get ips units that have the parent sps of BACBIS_MajorA_GROUPA_1_1
        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();
        for(reduivy__Individual_Plan_Structure__c ipsu : [
            SELECT  reduivy__Target_Unit_Id__c, reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c, RecordTypeId,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c, reduivy__Study_Plan_Structure__c, reduivy__Status__c, reduivy__Category__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :IPS_Helper.CATEGORY_OPTIONAL
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
        ]){
            ipsgIdSet.add(ipsu.reduivy__Parent_Plan_Structure__c);
            ipsuList.add(ipsu);
        }

        System.Assert.isFalse(
            ipsuList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        for(reduivy__Individual_Plan_Structure__c ipsu: ipsuList) {
            ipsu.reduivy__Status__c = 'Completed';
        }

        System.runAs(ADMIN_USER) {   
            Test.startTest();
            update ipsuList;
            Test.stopTest();
        }

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            reduivy__Status__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c = 'Completed'
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            System.Assert.areEqual('In Progress', ipsg.reduivy__Status__c, 'IPSG status should not be updated!');

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {

                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
                expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                ++expectedUnitsPassed;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as an admin user that an insert of an individual plan structure (unit) rolls up to the parent individual plan structure (group)
     * according to the individual plan unit primary
     */
    @isTest
    static void testV_IpsUnitRollUpToParentGroupAfterUpdate_RequiredOnly_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data
        String splQuery = '%' + RO_SPL_NAME;
        
        
        //only get ips units that have the parent sps of BACBIS_MajorA_GROUPA_1_1
        // Get individual plan structure (unit) records
        List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
        Set<Id> ipsgIdSet = new Set<Id>();
        for(reduivy__Individual_Plan_Structure__c ipsu : [
            SELECT  reduivy__Target_Unit_Id__c, reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits__c, reduivy__Credits_Earned__c, reduivy__Units_Passed__c, reduivy__Units_Contributed__c, RecordTypeId,
                    reduivy__Individual_Program_Enrollment__c, reduivy__Parent_Plan_Structure__c, reduivy__Study_Plan_Structure__c, reduivy__Status__c, reduivy__Category__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c != null
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :IPS_Helper.CATEGORY_REQUIRED
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Sample_Record_Code__c LIKE :splQuery
        ]){
            ipsgIdSet.add(ipsu.reduivy__Parent_Plan_Structure__c);
            ipsuList.add(ipsu);
        }

        System.Assert.isFalse(
            ipsuList.isEmpty(),
            'The list should contain individual plan structure (unit) records'
        );

        for(reduivy__Individual_Plan_Structure__c ipsu: ipsuList) {
            ipsu.reduivy__Status__c = 'Completed';
        }

        System.runAs(ADMIN_USER) {   
            Test.startTest();
            update ipsuList;
            Test.stopTest();
        }

        // Verify test results
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT Id, 
            reduivy__Credits_Enrolled__c, 
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Earned__c, 
            reduivy__Units_Passed__c,
            reduivy__Units_Contributed__c,
            reduivy__Status__c,
            (
                SELECT Id, 
                reduivy__Primary__c, 
                reduivy__Credits__c, 
                reduivy__Credits_Earned__c,
                reduivy__Credits_Contribution__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name
                FROM reduivy__Individual_Plan_Structures__r
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Status__c = 'Completed'
            )
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the parent individual plan structure (group) records'
        );

        REDU_Logging_UTIL.debugJsonString('ipsgList :: ', ipsgList);

        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            System.Assert.areEqual('In Progress', ipsg.reduivy__Status__c, 'IPSG status should not be updated!');

            Decimal expectedCreditsEnrolled = 0;
            Decimal expectedUnitsEnrolled = 0;
            Decimal expectedCreditsEarned = 0;
            Decimal expectedUnitsPassed = 0;
            Decimal expectedUnitsContributed = 0;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {

                expectedCreditsEnrolled += (ipsu.reduivy__Credits__c == null) ? 0 : ipsu.reduivy__Credits__c;
                ++expectedUnitsEnrolled;
                expectedCreditsEarned += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? ipsu.reduivy__Credits_Earned__c : 0;
                expectedUnitsContributed += (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) ? 1 : 0;
                ++expectedUnitsPassed;
            }

            System.Assert.areEqual(
                expectedCreditsEnrolled,
                ipsg.reduivy__Credits_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsEnrolled,
                ipsg.reduivy__Units_Enrolled__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedCreditsEarned,
                ipsg.reduivy__Credits_Earned__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsPassed,
                ipsg.reduivy__Units_Passed__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedUnitsContributed,
                ipsg.reduivy__Units_Contributed__c,
                'The actual value should be as expected'
            );
        }
    }

    

}