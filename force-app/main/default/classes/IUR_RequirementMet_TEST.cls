/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Test
 * @description Test class for IUR_RequirementMet_EXE
 * @changehistory
 * ISS-001618 23-10-2023 dblack - new class
 * ISS-001979 15-07-2024 Sueanne - remove pre-req enrolled/completed option
 * ISS-002044 29-07-2024 Sueanne - include test for "Conflict" requirement type
 * ISS-002226 06-01-2025 XW - renamed Conflict type to 'Enrolled or Completed'
 */
@IsTest
public inherited sharing class IUR_RequirementMet_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String STUDY_UNIT_COMPLETED = 'BUS102';
    static final String STUDY_UNIT_NOT_COMPLETED = 'MAT201';
	static final String IPS_REQUIREMENT_LOGIC = 'COM101 AND (BUS101 OR BUS102)';

    static final String IUR_REQTYPE_PREREQ = IUR_Helper.REQTYPE_PREREQ;
    static final String IUR_REQTYPE_COREQ = IUR_Helper.REQTYPE_COREQ;
    static final String IUR_REQTYPE_ENROLLED_COMPLETED = IUR_Helper.REQTYPE_ENROLLED_COMPLETED;
    static final String IUR_REQTYPE_CREDITS = IUR_Helper.REQTYPE_CREDITS;
    static final String IUR_REQTYPE_OTHER = IUR_Helper.REQTYPE_OTHER;

    static final List<String> IUR_REQTYPES = new List<String>{
        IUR_REQTYPE_PREREQ,
        IUR_REQTYPE_COREQ,
        IUR_REQTYPE_ENROLLED_COMPLETED,
        IUR_REQTYPE_CREDITS,
        IUR_REQTYPE_OTHER
    };

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
            testFactory.initOfferingData(SOF_Helper.getApiName());
            testFactory.initStudentData(IPE_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test as an admin user the IUR requirement is met (before insert)
     */
    @IsTest
    static void testIurRequirementIsMetBeforeInsertAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        // Setup test data

        // Delete existing IURs
        delete [SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c];

        // Update the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id, reduivy__Credits_Earned__c
            FROM reduivy__Individual_Program_Enrollment__c
        ]);

        System.Assert.isFalse(
            ipeMap.isEmpty(),
            'There should be a map of individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {

            ipe.reduivy__Credits_Earned__c = 10.0;
        }
        update ipeMap.values();

        // Update the individual enrollment records
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Grade_Result__c
            FROM reduivy__Individual_Enrollment__c
        ]);

        System.Assert.isFalse(
            ienMap.isEmpty(),
            'There should be a map of individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {

            ien.reduivy__Grade_Result__c = 'RPL';
        }        
        update ienMap.values();

        // Update the individual plan structure unit records
        List<reduivy__Individual_Plan_Structure__c> ipsuList = [
            SELECT Id, reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienMap.keySet()
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
        ];

        System.Assert.isFalse(
            ipsuList.isEmpty(),
            'There should be a list of individual plan structure unit records'
        );

        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

            ipsu.reduivy__Status__c = 'Completed';
        }
        update ipsuList;

        // Get map of study unit records
        Map<String, reduivy__Study_Unit__c> sunMap = new Map<String, reduivy__Study_Unit__c>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, Name
            FROM reduivy__Study_Unit__c
        ];

        for (reduivy__Study_Unit__c sun : sunList) {

            sunMap.put(sun.Name, sun);
        }

        System.Assert.isFalse(
            sunMap.isEmpty(),
            'There should be a map of study unit records'
        );

        // Create the individual plan unit requirement records
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {
            for (String reqType : IUR_REQTYPES) {

                reduivy__Individual_Plan_Unit_Requirement__c iur = new reduivy__Individual_Plan_Unit_Requirement__c();
                iur.reduivy__Individual_Plan_Unit__c = ipsu.Id;
                iur.reduivy__Requirement_ID__c = 'IUR-' + String.valueOf(IUR_REQTYPES.indexOf(reqType));
                iur.reduivy__Credits__c = 0.0;
                iur.reduivy__Requirement_Type__c = reqType;
                iur.reduivy__Required_Study_Unit__c = sunMap.get(STUDY_UNIT_COMPLETED).Id;
                iur.reduivy__Other__c = 'Other';
                iurList.add(iur);
            }
        }

        // Perform test
        System.runAs(ADMIN_USER) {
            insert iurList;
        }

        // Verify test results
        iurList = [
            SELECT  Id, Name, reduivy__Individual_Plan_Unit__c,
                    reduivy__Requirement_ID__c, reduivy__Required_Study_Unit__c,
                    reduivy__Requirement_Type__c, reduivy__Requirement_Met__c,
                    reduivy__Credits__c, reduivy__Other__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Requirement_ID__c != null
        ];

        System.Assert.isFalse(
            iurList.isEmpty(),
            'There should be a list of individual plan unit requirement records'
        );

        for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

            if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_PREREQ) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_COREQ) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_ENROLLED_COMPLETED) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_CREDITS) {

                System.Assert.isNull(
                    iur.reduivy__Required_Study_Unit__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_OTHER) {

                System.Assert.isNull(
                    iur.reduivy__Required_Study_Unit__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test as an admin user the IUR requirement is not met (before insert)
     */
    @IsTest
    static void testIurRequirementNotMetBeforeInsertAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        // Setup test data

        // Delete existing IURs
        delete [SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c];

        // Update the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id, reduivy__Credits_Earned__c
            FROM reduivy__Individual_Program_Enrollment__c
        ]);

        System.Assert.isFalse(
            ipeMap.isEmpty(),
            'There should be a map of individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {

            ipe.reduivy__Credits_Earned__c = null;
        }
        update ipeMap.values();

        // Update the individual enrollment records
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Grade_Result__c
            FROM reduivy__Individual_Enrollment__c
        ]);

        System.Assert.isFalse(
            ienMap.isEmpty(),
            'There should be a map of individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {

            ien.reduivy__Enrollment_Status__c = null;
            ien.reduivy__Grade_Result__c = null;
        }
        update ienMap.values();

        // Get the individual plan structure unit records
        List<reduivy__Individual_Plan_Structure__c> ipsuList = [
            SELECT Id 
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienMap.keySet()
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
        ];

        System.Assert.isFalse(
            ipsuList.isEmpty(),
            'There should be a list of individual plan structure unit records'
        );

        // Get map of study unit records
        Map<String, reduivy__Study_Unit__c> sunMap = new Map<String, reduivy__Study_Unit__c>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, Name
            FROM reduivy__Study_Unit__c
        ];

        for (reduivy__Study_Unit__c sun : sunList) {
            sunMap.put(sun.Name, sun);
        }

        System.Assert.isFalse(
            sunMap.isEmpty(),
            'There should be a map of study unit records'
        );

        // Create the individual plan unit requirement records
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {
            for (String reqType : IUR_REQTYPES) {

                reduivy__Individual_Plan_Unit_Requirement__c iur = new reduivy__Individual_Plan_Unit_Requirement__c();
                iur.reduivy__Individual_Plan_Unit__c = ipsu.Id;
                iur.reduivy__Requirement_ID__c = 'IUR-' + String.valueOf(IUR_REQTYPES.indexOf(reqType));
                iur.reduivy__Credits__c = 200.0;
                iur.reduivy__Requirement_Type__c = reqType;
                iur.reduivy__Required_Study_Unit__c = sunMap.get(STUDY_UNIT_NOT_COMPLETED).Id;
                iur.reduivy__Other__c = 'Other';
                iurList.add(iur);
            }
        }

        // Perform test
        System.runAs(ADMIN_USER) {

            insert iurList;
        }

        // Verify test results
        iurList = [
            SELECT  Id, Name, reduivy__Individual_Plan_Unit__c,
                    reduivy__Requirement_ID__c, reduivy__Required_Study_Unit__c,
                    reduivy__Requirement_Type__c, reduivy__Requirement_Met__c,
                    reduivy__Credits__c, reduivy__Other__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Requirement_ID__c != null
        ];

        System.Assert.isFalse(
            iurList.isEmpty(),
            'There should be a list of individual plan unit requirement records'
        );

        for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

            if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_PREREQ) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isFalse(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );
                
            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_COREQ) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_ENROLLED_COMPLETED) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isFalse(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_CREDITS) {

                System.Assert.isNull(
                    iur.reduivy__Required_Study_Unit__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isFalse(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_OTHER) {

                System.Assert.isNull(
                    iur.reduivy__Required_Study_Unit__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test as an admin user the IUR requirement is met (before update)
     */
    @IsTest
    static void testIurRequirementIsMetBeforeUpdateAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        // Setup test data

        // Update the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id, reduivy__Credits_Earned__c
            FROM reduivy__Individual_Program_Enrollment__c
        ]);

        System.Assert.isFalse(
            ipeMap.isEmpty(),
            'There should be a map of individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {

            ipe.reduivy__Credits_Earned__c = 10.0;
        }
        update ipeMap.values();

        // Update the individual enrollment records
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Grade_Result__c
            FROM reduivy__Individual_Enrollment__c
        ]);

        System.Assert.isFalse(
            ienMap.isEmpty(),
            'There should be a map of individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {

            ien.reduivy__Grade_Result__c = 'RPL';
        }
        update ienMap.values();

        // Update the individual plan structure unit records
        List<reduivy__Individual_Plan_Structure__c> ipsuList = [
            SELECT reduivy__Status__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
        ];

        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

            ipsu.reduivy__Status__c = 'Completed';
        }
        update ipsuList;

        // Get map of study unit records
        Map<String, reduivy__Study_Unit__c> sunMap = new Map<String, reduivy__Study_Unit__c>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, Name
            FROM reduivy__Study_Unit__c
        ];

        for (reduivy__Study_Unit__c sun : sunList) {

            sunMap.put(sun.Name, sun); 
        }

        System.Assert.isFalse(
            sunMap.isEmpty(),
            'There should be a map of study unit records'
        );

        // Get the individual plan unit requirment records for the test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = [
            SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c
        ];

        System.Assert.isFalse(
            ienMap.isEmpty(),
            'There should be a list of individual plan unit requirement records'
        );

        for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

            iur.reduivy__Required_Study_Unit__c = sunMap.get(STUDY_UNIT_COMPLETED).Id;
            iur.reduivy__Credits__c = 0.0;
            iur.reduivy__Other__c = 'Other';
        }

        // Perform test
        System.runAs(ADMIN_USER) {

            update iurList;
        }

        // Verify test results
        iurList = [
            SELECT  Id, Name, reduivy__Individual_Plan_Unit__c,
                    reduivy__Requirement_ID__c, reduivy__Required_Study_Unit__c,
                    reduivy__Requirement_Type__c, reduivy__Requirement_Met__c,
                    reduivy__Credits__c, reduivy__Other__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
        ];

        System.Assert.isFalse(
            iurList.isEmpty(),
            'There should be a list of individual plan unit requirement records'
        );

        for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

            if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_PREREQ) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_COREQ) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_ENROLLED_COMPLETED) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isFalse(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_CREDITS) {

                System.Assert.isNull(
                    iur.reduivy__Required_Study_Unit__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_OTHER) {

                System.Assert.isNull(
                    iur.reduivy__Required_Study_Unit__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test as an admin user the IUR requirement is not met (before update)
     */
    @IsTest
    static void testIurRequirementNotMetBeforeUpdateAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        // Setup test data

        // Update the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id, reduivy__Credits_Earned__c
            FROM reduivy__Individual_Program_Enrollment__c
        ]);

        System.Assert.isFalse(
            ipeMap.isEmpty(),
            'There should be a map of individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {

            ipe.reduivy__Credits_Earned__c = null;
        }
        update ipeMap.values();

        // Update the individual enrollment records
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Grade_Result__c
            FROM reduivy__Individual_Enrollment__c
        ]);

        System.Assert.isFalse(
            ienMap.isEmpty(),
            'There should be a map of individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {

            ien.reduivy__Enrollment_Status__c = null;
            ien.reduivy__Grade_Result__c = null;
        }
        update ienMap.values();

        // Get map of study unit records
        Map<String, reduivy__Study_Unit__c> sunMap = new Map<String, reduivy__Study_Unit__c>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, Name
            FROM reduivy__Study_Unit__c
        ];

        for (reduivy__Study_Unit__c sun : sunList) {

            sunMap.put(sun.Name, sun);
        }

        System.Assert.isFalse(
            sunMap.isEmpty(),
            'There should be a map of study unit records'
        );

        // Get the individual plan unit requirment records for the test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = [
            SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c
        ];

        System.Assert.isFalse(
            ienMap.isEmpty(),
            'There should be a list of individual plan unit requirement records'
        );

        for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

            iur.reduivy__Required_Study_Unit__c = sunMap.get(STUDY_UNIT_NOT_COMPLETED).Id;
            iur.reduivy__Credits__c = 200.0;
            iur.reduivy__Other__c = 'Other';
        }

        // Perform test
        System.runAs(ADMIN_USER) {

            update iurList;
        }

        // Verify test results
        iurList = [
            SELECT  Id, Name, reduivy__Individual_Plan_Unit__c,
                    reduivy__Requirement_ID__c, reduivy__Required_Study_Unit__c,
                    reduivy__Requirement_Type__c, reduivy__Requirement_Met__c,
                    reduivy__Credits__c, reduivy__Other__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
        ];

        System.Assert.isFalse(
            iurList.isEmpty(),
            'There should be a list of individual plan unit requirement records'
        );

        for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

            if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_PREREQ) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isFalse(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_COREQ) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_ENROLLED_COMPLETED) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isFalse(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_CREDITS) {

                System.Assert.isNull(
                    iur.reduivy__Required_Study_Unit__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isFalse(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_OTHER) {

                System.Assert.isNull(
                    iur.reduivy__Required_Study_Unit__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test as a student user the IUR requirement is met (before insert)
     */
    @IsTest
    static void testIurRequirementIsMetBeforeInsertAsStudentUser() {

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

        Test.startTest();

		System.runAs(studentUser) {

            // Setup test data

            // Delete existing IURs
            delete [SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c];

            // Update the individual program enrollment records
            Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
                SELECT Id, reduivy__Credits_Earned__c
                FROM reduivy__Individual_Program_Enrollment__c
            ]);

            System.Assert.isFalse(
                ipeMap.isEmpty(),
                'There should be a map of individual program enrollment records'
            );

            for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {

                ipe.reduivy__Credits_Earned__c = 10.0;
            }
            update ipeMap.values();

            // Update the individual enrollment records
            Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Grade_Result__c
                FROM reduivy__Individual_Enrollment__c
            ]);

            System.Assert.isFalse(
                ienMap.isEmpty(),
                'There should be a map of individual enrollment records'
            );

            for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {

                ien.reduivy__Grade_Result__c = 'RPL';
            }
            update ienMap.values();

            // Update the individual plan structure unit records
            List<reduivy__Individual_Plan_Structure__c> ipsuList = [
                SELECT Id, reduivy__Status__c
                FROM reduivy__Individual_Plan_Structure__c
                WHERE reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienMap.keySet()
                AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            ];

            System.Assert.isFalse(
                ipsuList.isEmpty(),
                'There should be a list of individual plan structure unit records'
            );

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

                ipsu.reduivy__Status__c = 'Completed';
            }
            update ipsuList;

            // Get map of study unit records
            Map<String, reduivy__Study_Unit__c> sunMap = new Map<String, reduivy__Study_Unit__c>();
            List<reduivy__Study_Unit__c> sunList = [
                SELECT Id, Name
                FROM reduivy__Study_Unit__c
            ];
            for (reduivy__Study_Unit__c sun : sunList) {
                sunMap.put(sun.Name, sun);
            }
            System.Assert.isFalse(
                sunMap.isEmpty(),
                'There should be a map of study unit records'
            );

            // Create the individual plan unit requirement records
            List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
            for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {
                for (String reqType : IUR_REQTYPES) {

                    reduivy__Individual_Plan_Unit_Requirement__c iur = new reduivy__Individual_Plan_Unit_Requirement__c();
                    iur.reduivy__Individual_Plan_Unit__c = ipsu.Id;
                    iur.reduivy__Requirement_ID__c = 'IUR-' + String.valueOf(IUR_REQTYPES.indexOf(reqType));
                    iur.reduivy__Credits__c = 0.0;
                    iur.reduivy__Requirement_Type__c = reqType;
                    iur.reduivy__Required_Study_Unit__c = sunMap.get(STUDY_UNIT_COMPLETED).Id;
                    iur.reduivy__Other__c = 'Other';
                    iurList.add(iur);
                }
            }

            // Perform test
            insert iurList;

            // Verify test results
            iurList = [
                SELECT  Id, Name, reduivy__Individual_Plan_Unit__c,
                        reduivy__Requirement_ID__c, reduivy__Required_Study_Unit__c,
                        reduivy__Requirement_Type__c, reduivy__Requirement_Met__c,
                        reduivy__Credits__c, reduivy__Other__c
                FROM reduivy__Individual_Plan_Unit_Requirement__c
                WHERE reduivy__Requirement_ID__c != null
            ];

            System.Assert.isFalse(
                iurList.isEmpty(),
                'There should be a list of individual plan unit requirement records'
            );

            for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

                if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_PREREQ) {

                    System.Assert.isNull(
                        iur.reduivy__Credits__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isNull(
                        iur.reduivy__Other__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isTrue(
                        iur.reduivy__Requirement_Met__c,
                        'The actual value should be as expected'
                    );

                } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_COREQ) {

                    System.Assert.isNull(
                        iur.reduivy__Credits__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isNull(
                        iur.reduivy__Other__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isTrue(
                        iur.reduivy__Requirement_Met__c,
                        'The actual value should be as expected'
                    );

                } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_ENROLLED_COMPLETED) {

                    System.Assert.isNull(
                        iur.reduivy__Credits__c,
                        'The actual value should be as expected'
                    );
    
                    System.Assert.isNull(
                        iur.reduivy__Other__c,
                        'The actual value should be as expected'
                    );
    
                    System.Assert.isTrue(
                        iur.reduivy__Requirement_Met__c,
                        'The actual value should be as expected'
                    );
    
                } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_CREDITS) {

                    System.Assert.isNull(
                        iur.reduivy__Required_Study_Unit__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isNull(
                        iur.reduivy__Other__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isTrue(
                        iur.reduivy__Requirement_Met__c,
                        'The actual value should be as expected'
                    );

                } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_OTHER) {

                    System.Assert.isNull(
                        iur.reduivy__Required_Study_Unit__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isNull(
                        iur.reduivy__Credits__c,
                        'The actual value should be as expected'
                    );
                }
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test as a student user the IUR requirement is not met (before insert)
     */
    @IsTest
    static void testIurRequirementNotMetBeforeInsertAsStudentUser() {

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

        Test.startTest();

		System.runAs(studentUser) {

            // Setup test data

            // Delete existing IURs
            delete [SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c];

            // Update the individual program enrollment records
            Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
                SELECT Id, reduivy__Credits_Earned__c
                FROM reduivy__Individual_Program_Enrollment__c
            ]);

            System.Assert.isFalse(
                ipeMap.isEmpty(),
                'There should be a map of individual program enrollment records'
            );

            for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {

                ipe.reduivy__Credits_Earned__c = null;
            }
            update ipeMap.values();

            // Update the individual enrollment records
            Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Grade_Result__c
                FROM reduivy__Individual_Enrollment__c
            ]);

            System.Assert.isFalse(
                ienMap.isEmpty(),
                'There should be a map of individual enrollment records'
            );

            for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {

                ien.reduivy__Enrollment_Status__c = null;
                ien.reduivy__Grade_Result__c = null;
            }
            update ienMap.values();

            // Get the individual plan structure unit records
            List<reduivy__Individual_Plan_Structure__c> ipsuList = [
                SELECT Id 
                FROM reduivy__Individual_Plan_Structure__c
                WHERE reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienMap.keySet()
                AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            ];

            System.Assert.isFalse(
                ipsuList.isEmpty(),
                'There should be a list of individual plan structure unit records'
            );

            // Get map of study unit records
            Map<String, reduivy__Study_Unit__c> sunMap = new Map<String, reduivy__Study_Unit__c>();
            List<reduivy__Study_Unit__c> sunList = [
                SELECT Id, Name
                FROM reduivy__Study_Unit__c
            ];
            for (reduivy__Study_Unit__c sun : sunList) {
                sunMap.put(sun.Name, sun);
            }

            System.Assert.isFalse(
                sunMap.isEmpty(),
                'There should be a map of study unit records'
            );

            // Create the individual plan unit requirement records
            List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
            for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {
                for (String reqType : IUR_REQTYPES) {

                    reduivy__Individual_Plan_Unit_Requirement__c iur = new reduivy__Individual_Plan_Unit_Requirement__c();
                    iur.reduivy__Individual_Plan_Unit__c = ipsu.Id;
                    iur.reduivy__Requirement_ID__c = 'IUR-' + String.valueOf(IUR_REQTYPES.indexOf(reqType));
                    iur.reduivy__Credits__c = 200.0;
                    iur.reduivy__Requirement_Type__c = reqType;
                    iur.reduivy__Required_Study_Unit__c = sunMap.get(STUDY_UNIT_NOT_COMPLETED).Id;
                    iur.reduivy__Other__c = 'Other';
                    iurList.add(iur);
                }
            }

            // Perform test
            insert iurList;

            // Verify test results
            iurList = [
                SELECT  Id, Name, reduivy__Individual_Plan_Unit__c,
                        reduivy__Requirement_ID__c, reduivy__Required_Study_Unit__c,
                        reduivy__Requirement_Type__c, reduivy__Requirement_Met__c,
                        reduivy__Credits__c, reduivy__Other__c
                FROM reduivy__Individual_Plan_Unit_Requirement__c
                WHERE reduivy__Requirement_ID__c != null
            ];

            System.Assert.isFalse(
                iurList.isEmpty(),
                'There should be a list of individual plan unit requirement records'
            );

            for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

                if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_PREREQ) {

                    System.Assert.isNull(
                        iur.reduivy__Credits__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isNull(
                        iur.reduivy__Other__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isFalse(
                        iur.reduivy__Requirement_Met__c,
                        'The actual value should be as expected'
                    );

                } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_COREQ) {

                    System.Assert.isNull(
                        iur.reduivy__Credits__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isNull(
                        iur.reduivy__Other__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isTrue(
                        iur.reduivy__Requirement_Met__c,
                        'The actual value should be as expected'
                    );

                } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_ENROLLED_COMPLETED) {

                    System.Assert.isNull(
                        iur.reduivy__Credits__c,
                        'The actual value should be as expected'
                    );
    
                    System.Assert.isNull(
                        iur.reduivy__Other__c,
                        'The actual value should be as expected'
                    );
    
                    System.Assert.isFalse(
                        iur.reduivy__Requirement_Met__c,
                        'The actual value should be as expected'
                    );
    
                } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_CREDITS) {

                    System.Assert.isNull(
                        iur.reduivy__Required_Study_Unit__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isNull(
                        iur.reduivy__Other__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isFalse(
                        iur.reduivy__Requirement_Met__c,
                        'The actual value should be as expected'
                    );

                } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_OTHER) {

                    System.Assert.isNull(
                        iur.reduivy__Required_Study_Unit__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isNull(
                        iur.reduivy__Credits__c,
                        'The actual value should be as expected'
                    );
                }
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test as a student user the IUR requirement is met (before update)
     */
    @IsTest
    static void testIurRequirementIsMetBeforeUpdateAsStudentUser() {

        Test.startTest();
        // Setup test data

        // Update the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id, reduivy__Credits_Earned__c
            FROM reduivy__Individual_Program_Enrollment__c
        ]);

        System.Assert.isFalse(
            ipeMap.isEmpty(),
            'There should be a map of individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {

            ipe.reduivy__Credits_Earned__c = 10.0;
        }
        update ipeMap.values();

        // Update the individual enrollment records
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Grade_Result__c
            FROM reduivy__Individual_Enrollment__c
        ]);

        System.Assert.isFalse(
            ienMap.isEmpty(),
            'There should be a map of individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {

            ien.reduivy__Grade_Result__c = 'RPL';
        }
        update ienMap.values();

        // Update the individual plan structure unit records
        List<reduivy__Individual_Plan_Structure__c> ipsuList = [
            SELECT reduivy__Status__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
        ];

        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

            ipsu.reduivy__Status__c = 'Completed';
        }
        update ipsuList;

        // Get map of study unit records
        Map<String, reduivy__Study_Unit__c> sunMap = new Map<String, reduivy__Study_Unit__c>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, Name
            FROM reduivy__Study_Unit__c
        ];

        for (reduivy__Study_Unit__c sun : sunList) {

            sunMap.put(sun.Name, sun);
        }

        System.Assert.isFalse(
            sunMap.isEmpty(),
            'There should be a map of study unit records'
        );

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

            // Get the individual plan unit requirment records for the test
            List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = [
                SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c
            ];

            System.Assert.isFalse(
                ienMap.isEmpty(),
                'There should be a list of individual plan unit requirement records'
            );

            for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

                iur.reduivy__Required_Study_Unit__c = sunMap.get(STUDY_UNIT_COMPLETED).Id;
                iur.reduivy__Credits__c = 0.0;
                iur.reduivy__Other__c = 'Other';
            }

            // Perform test
            update iurList;

            // Verify test results
            iurList = [
                SELECT  Id, Name, reduivy__Individual_Plan_Unit__c,
                        reduivy__Requirement_ID__c, reduivy__Required_Study_Unit__c,
                        reduivy__Requirement_Type__c, reduivy__Requirement_Met__c,
                        reduivy__Credits__c, reduivy__Other__c
                FROM reduivy__Individual_Plan_Unit_Requirement__c
            ];

            System.Assert.isFalse(
                iurList.isEmpty(),
                'There should be a list of individual plan unit requirement records'
            );

            for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

                if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_PREREQ) {

                    System.Assert.isNull(
                        iur.reduivy__Credits__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isNull(
                        iur.reduivy__Other__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isTrue(
                        iur.reduivy__Requirement_Met__c,
                        'The actual value should be as expected'
                    );

                } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_COREQ) {

                    System.Assert.isNull(
                        iur.reduivy__Credits__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isNull(
                        iur.reduivy__Other__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isTrue(
                        iur.reduivy__Requirement_Met__c,
                        'The actual value should be as expected'
                    );

                } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_ENROLLED_COMPLETED) {

                    System.Assert.isNull(
                        iur.reduivy__Credits__c,
                        'The actual value should be as expected'
                    );
    
                    System.Assert.isNull(
                        iur.reduivy__Other__c,
                        'The actual value should be as expected'
                    );
    
                    System.Assert.isTrue(
                        iur.reduivy__Requirement_Met__c,
                        'The actual value should be as expected'
                    );
    
                } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_CREDITS) {

                    System.Assert.isNull(
                        iur.reduivy__Required_Study_Unit__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isNull(
                        iur.reduivy__Other__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isTrue(
                        iur.reduivy__Requirement_Met__c,
                        'The actual value should be as expected'
                    );

                } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_OTHER) {

                    System.Assert.isNull(
                        iur.reduivy__Required_Study_Unit__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isNull(
                        iur.reduivy__Credits__c,
                        'The actual value should be as expected'
                    );
                }
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test as a student user the IUR requirement is not met (before update)
     */
    @IsTest
    static void testIurRequirementNotMetBeforeUpdateAsStudentUser() {

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
        
        Test.startTest();

		System.runAs(studentUser) {

            // Setup test data

            // Update the individual program enrollment records
            Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
                SELECT Id, reduivy__Credits_Earned__c
                FROM reduivy__Individual_Program_Enrollment__c
            ]);

            System.Assert.isFalse(
                ipeMap.isEmpty(),
                'There should be a map of individual program enrollment records'
            );

            for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {

                ipe.reduivy__Credits_Earned__c = null;
            }
            update ipeMap.values();

            // Update the individual enrollment records
            Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Grade_Result__c
                FROM reduivy__Individual_Enrollment__c
            ]);

            System.Assert.isFalse(
                ienMap.isEmpty(),
                'There should be a map of individual enrollment records'
            );

            for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {

                ien.reduivy__Enrollment_Status__c = null;
                ien.reduivy__Grade_Result__c = null;
            }
            update ienMap.values();

            // Get map of study unit records
            Map<String, reduivy__Study_Unit__c> sunMap = new Map<String, reduivy__Study_Unit__c>();
            List<reduivy__Study_Unit__c> sunList = [
                SELECT Id, Name
                FROM reduivy__Study_Unit__c
            ];

            for (reduivy__Study_Unit__c sun : sunList) {

                sunMap.put(sun.Name, sun);
            }

            System.Assert.isFalse(
                sunMap.isEmpty(),
                'There should be a map of study unit records'
            );

            // Get the individual plan unit requirment records for the test
            List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = [
                SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c
            ];

            System.Assert.isFalse(
                ienMap.isEmpty(),
                'There should be a list of individual plan unit requirement records'
            );

            for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

                iur.reduivy__Required_Study_Unit__c = sunMap.get(STUDY_UNIT_NOT_COMPLETED).Id;
                iur.reduivy__Credits__c = 200.0;
                iur.reduivy__Other__c = 'Other';
            }

            // Perform test
            update iurList;

            // Verify test results
            iurList = [
                SELECT  Id, Name, reduivy__Individual_Plan_Unit__c,
                        reduivy__Requirement_ID__c, reduivy__Required_Study_Unit__c,
                        reduivy__Requirement_Type__c, reduivy__Requirement_Met__c,
                        reduivy__Credits__c, reduivy__Other__c
                FROM reduivy__Individual_Plan_Unit_Requirement__c
            ];

            System.Assert.isFalse(
                iurList.isEmpty(),
                'There should be a list of individual plan unit requirement records'
            );

            for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

                if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_PREREQ) {

                    System.Assert.isNull(
                        iur.reduivy__Credits__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isNull(
                        iur.reduivy__Other__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isFalse(
                        iur.reduivy__Requirement_Met__c,
                        'The actual value should be as expected'
                    );

                } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_COREQ) {

                    System.Assert.isNull(
                        iur.reduivy__Credits__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isNull(
                        iur.reduivy__Other__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isTrue(
                        iur.reduivy__Requirement_Met__c,
                        'The actual value should be as expected'
                    );

                } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_ENROLLED_COMPLETED) {

                    System.Assert.isNull(
                        iur.reduivy__Credits__c,
                        'The actual value should be as expected'
                    );
    
                    System.Assert.isNull(
                        iur.reduivy__Other__c,
                        'The actual value should be as expected'
                    );
    
                    System.Assert.isFalse(
                        iur.reduivy__Requirement_Met__c,
                        'The actual value should be as expected'
                    );
    
                } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_CREDITS) {

                    System.Assert.isNull(
                        iur.reduivy__Required_Study_Unit__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isNull(
                        iur.reduivy__Other__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isFalse(
                        iur.reduivy__Requirement_Met__c,
                        'The actual value should be as expected'
                    );

                } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_OTHER) {

                    System.Assert.isNull(
                        iur.reduivy__Required_Study_Unit__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.isNull(
                        iur.reduivy__Credits__c,
                        'The actual value should be as expected'
                    );
                }
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test as a faculty user the IUR requirement is met (before insert)
     */
    @IsTest
    static void testIurRequirementIsMetBeforeInsertAsFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        // Setup test data

        // Delete existing IURs
        delete [SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c];

        // Update the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id, reduivy__Credits_Earned__c
            FROM reduivy__Individual_Program_Enrollment__c
        ]);

        System.Assert.isFalse(
            ipeMap.isEmpty(),
            'There should be a map of individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {

            ipe.reduivy__Credits_Earned__c = 10.0;
        }
        update ipeMap.values();

        // Update the individual enrollment records
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Grade_Result__c
            FROM reduivy__Individual_Enrollment__c
        ]);

        System.Assert.isFalse(
            ienMap.isEmpty(),
            'There should be a map of individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {

            ien.reduivy__Grade_Result__c = 'RPL';
        }
        update ienMap.values();

        // Update the individual plan structure unit records
        List<reduivy__Individual_Plan_Structure__c> ipsuList = [
            SELECT Id, reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienMap.keySet()
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
        ];

        System.Assert.isFalse(
            ipsuList.isEmpty(),
            'There should be a list of individual plan structure unit records'
        );

        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

            ipsu.reduivy__Status__c = 'Completed';
        }
        update ipsuList;

        // Get map of study unit records
        Map<String, reduivy__Study_Unit__c> sunMap = new Map<String, reduivy__Study_Unit__c>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, Name
            FROM reduivy__Study_Unit__c
        ];

        for (reduivy__Study_Unit__c sun : sunList) {

            sunMap.put(sun.Name, sun);
        }

        System.Assert.isFalse(
            sunMap.isEmpty(),
            'There should be a map of study unit records'
        );

        // Create the individual plan unit requirement records
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {
            for (String reqType : IUR_REQTYPES) {

                reduivy__Individual_Plan_Unit_Requirement__c iur = new reduivy__Individual_Plan_Unit_Requirement__c();
                iur.reduivy__Individual_Plan_Unit__c = ipsu.Id;
                iur.reduivy__Requirement_ID__c = 'IUR-' + String.valueOf(IUR_REQTYPES.indexOf(reqType));
                iur.reduivy__Credits__c = 0.0;
                iur.reduivy__Requirement_Type__c = reqType;
                iur.reduivy__Required_Study_Unit__c = sunMap.get(STUDY_UNIT_COMPLETED).Id;
                iur.reduivy__Other__c = 'Other';
                iurList.add(iur);
            }
        }

        // Perform test
        System.runAs(FACULTY_USER) {

            insert iurList;
        }

        // Verify test results
        iurList = [
            SELECT  Id, Name, reduivy__Individual_Plan_Unit__c,
                    reduivy__Requirement_ID__c, reduivy__Required_Study_Unit__c,
                    reduivy__Requirement_Type__c, reduivy__Requirement_Met__c,
                    reduivy__Credits__c, reduivy__Other__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Requirement_ID__c != null
        ];

        System.Assert.isFalse(
            iurList.isEmpty(),
            'There should be a list of individual plan unit requirement records'
        );

        for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

            if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_PREREQ) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_COREQ) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_ENROLLED_COMPLETED) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_CREDITS) {

                System.Assert.isNull(
                    iur.reduivy__Required_Study_Unit__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_OTHER) {

                System.Assert.isNull(
                    iur.reduivy__Required_Study_Unit__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test as a faculty user the IUR requirement is not met (before insert)
     */
    @IsTest
    static void testIurRequirementNotMetBeforeInsertAsFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        // Setup test data

        // Delete existing IURs
        delete [SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c];

        // Update the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id, reduivy__Credits_Earned__c
            FROM reduivy__Individual_Program_Enrollment__c
        ]);

        System.Assert.isFalse(
            ipeMap.isEmpty(),
            'There should be a map of individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {

            ipe.reduivy__Credits_Earned__c = null;
        }
        update ipeMap.values();

        // Update the individual enrollment records
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Grade_Result__c
            FROM reduivy__Individual_Enrollment__c
        ]);

        System.Assert.isFalse(
            ienMap.isEmpty(),
            'There should be a map of individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {

            ien.reduivy__Enrollment_Status__c = null;
            ien.reduivy__Grade_Result__c = null;
        }
        update ienMap.values();

        // Get the individual plan structure unit records
        List<reduivy__Individual_Plan_Structure__c> ipsuList = [
            SELECT Id 
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__c IN :ipeMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienMap.keySet()
            AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
        ];

        System.Assert.isFalse(
            ipsuList.isEmpty(),
            'There should be a list of individual plan structure unit records'
        );

        // Get map of study unit records
        Map<String, reduivy__Study_Unit__c> sunMap = new Map<String, reduivy__Study_Unit__c>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, Name
            FROM reduivy__Study_Unit__c
        ];

        for (reduivy__Study_Unit__c sun : sunList) {

            sunMap.put(sun.Name, sun);
        }

        System.Assert.isFalse(
            sunMap.isEmpty(),
            'There should be a map of study unit records'
        );

        // Create the individual plan unit requirement records
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {
            for (String reqType : IUR_REQTYPES) {

                reduivy__Individual_Plan_Unit_Requirement__c iur = new reduivy__Individual_Plan_Unit_Requirement__c();
                iur.reduivy__Individual_Plan_Unit__c = ipsu.Id;
                iur.reduivy__Requirement_ID__c = 'IUR-' + String.valueOf(IUR_REQTYPES.indexOf(reqType));
                iur.reduivy__Credits__c = 200.0;
                iur.reduivy__Requirement_Type__c = reqType;
                iur.reduivy__Required_Study_Unit__c = sunMap.get(STUDY_UNIT_NOT_COMPLETED).Id;
                iur.reduivy__Other__c = 'Other';
                iurList.add(iur);
            }
        }

        // Perform test
        System.runAs(FACULTY_USER) {

            insert iurList;
        }

        // Verify test results
        iurList = [
            SELECT  Id, Name, reduivy__Individual_Plan_Unit__c,
                    reduivy__Requirement_ID__c, reduivy__Required_Study_Unit__c,
                    reduivy__Requirement_Type__c, reduivy__Requirement_Met__c,
                    reduivy__Credits__c, reduivy__Other__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Requirement_ID__c != null
        ];

        System.Assert.isFalse(
            iurList.isEmpty(),
            'There should be a list of individual plan unit requirement records'
        );

        for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

            if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_PREREQ) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isFalse(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_COREQ) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_ENROLLED_COMPLETED) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isFalse(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_CREDITS) {
                System.Assert.isNull(
                    iur.reduivy__Required_Study_Unit__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isFalse(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_OTHER) {

                System.Assert.isNull(
                    iur.reduivy__Required_Study_Unit__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test as a faculty user the IUR requirement is met (before update)
     */
    @IsTest
    static void testIurRequirementIsMetBeforeUpdateAsFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        // Setup test data

        // Update the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id, reduivy__Credits_Earned__c
            FROM reduivy__Individual_Program_Enrollment__c
        ]);

        System.Assert.isFalse(
            ipeMap.isEmpty(),
            'There should be a map of individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {

            ipe.reduivy__Credits_Earned__c = 10.0;
        }
        update ipeMap.values();

        // Update the individual enrollment records
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Grade_Result__c
            FROM reduivy__Individual_Enrollment__c
        ]);

        System.Assert.isFalse(
            ienMap.isEmpty(),
            'There should be a map of individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {

            ien.reduivy__Grade_Result__c = 'RPL';
        }
        update ienMap.values();

        // Update the individual plan structure unit records
        List<reduivy__Individual_Plan_Structure__c> ipsuList = [
            SELECT reduivy__Status__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
        ];

        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {

            ipsu.reduivy__Status__c = 'Completed';
        }
        update ipsuList;

        List<reduivy__Individual_Plan_Structure__c> ipsuList2 = [
            SELECT reduivy__Status__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
        ];

        // Get map of study unit records
        Map<String, reduivy__Study_Unit__c> sunMap = new Map<String, reduivy__Study_Unit__c>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, Name
            FROM reduivy__Study_Unit__c
        ];

        for (reduivy__Study_Unit__c sun : sunList) {

            sunMap.put(sun.Name, sun);
        }

        System.Assert.isFalse(
            sunMap.isEmpty(),
            'There should be a map of study unit records'
        );

        // Get the individual plan unit requirment records for the test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = [
            SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c
        ];

        System.Assert.isFalse(
            ienMap.isEmpty(),
            'There should be a list of individual plan unit requirement records'
        );

        for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

            iur.reduivy__Required_Study_Unit__c = sunMap.get(STUDY_UNIT_COMPLETED).Id;
            iur.reduivy__Credits__c = 0.0;
            iur.reduivy__Other__c = 'Other';
        }

        // Perform test
        System.runAs(FACULTY_USER) {

            update iurList;
        }

        // Verify test results
        iurList = [
            SELECT  Id, Name, reduivy__Individual_Plan_Unit__c,
                    reduivy__Requirement_ID__c, reduivy__Required_Study_Unit__c,
                    reduivy__Requirement_Type__c, reduivy__Requirement_Met__c,
                    reduivy__Credits__c, reduivy__Other__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
        ];

        System.Assert.isFalse(
            iurList.isEmpty(),
            'There should be a list of individual plan unit requirement records'
        );

        for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

            if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_PREREQ) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_COREQ) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_ENROLLED_COMPLETED) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_CREDITS) {

                System.Assert.isNull(
                    iur.reduivy__Required_Study_Unit__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_OTHER) {

                System.Assert.isNull(
                    iur.reduivy__Required_Study_Unit__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test as a faculty user the IUR requirement is not met (before update)
     */
    @IsTest
    static void testIurRequirementNotMetBeforeUpdateAsFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        // Setup test data

        // Update the individual program enrollment records
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id, reduivy__Credits_Earned__c
            FROM reduivy__Individual_Program_Enrollment__c
        ]);

        System.Assert.isFalse(
            ipeMap.isEmpty(),
            'There should be a map of individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {

            ipe.reduivy__Credits_Earned__c = null;
        }
        update ipeMap.values();

        // Update the individual enrollment records
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Grade_Result__c
            FROM reduivy__Individual_Enrollment__c
        ]);

        System.Assert.isFalse(
            ienMap.isEmpty(),
            'There should be a map of individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {

            ien.reduivy__Enrollment_Status__c = null;
            ien.reduivy__Grade_Result__c = null;
        }
        update ienMap.values();

        // Get map of study unit records
        Map<String, reduivy__Study_Unit__c> sunMap = new Map<String, reduivy__Study_Unit__c>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, Name
            FROM reduivy__Study_Unit__c
        ];

        for (reduivy__Study_Unit__c sun : sunList) {

            sunMap.put(sun.Name, sun);
        }

        System.Assert.isFalse(
            sunMap.isEmpty(),
            'There should be a map of study unit records'
        );

        // Get the individual plan unit requirment records for the test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = [
            SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c
        ];

        System.Assert.isFalse(
            ienMap.isEmpty(),
            'There should be a list of individual plan unit requirement records'
        );

        for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

            iur.reduivy__Required_Study_Unit__c = sunMap.get(STUDY_UNIT_NOT_COMPLETED).Id;
            iur.reduivy__Credits__c = 200.0;
            iur.reduivy__Other__c = 'Other';
        }

        // Perform test
        System.runAs(FACULTY_USER) {

            update iurList;
        }

        // Verify test results
        iurList = [
            SELECT  Id, Name, reduivy__Individual_Plan_Unit__c,
                    reduivy__Requirement_ID__c, reduivy__Required_Study_Unit__c,
                    reduivy__Requirement_Type__c, reduivy__Requirement_Met__c,
                    reduivy__Credits__c, reduivy__Other__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
        ];

        System.Assert.isFalse(
            iurList.isEmpty(),
            'There should be a list of individual plan unit requirement records'
        );

        for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {

            if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_PREREQ) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isFalse(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_COREQ) {
                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isTrue(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_ENROLLED_COMPLETED) {

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isFalse(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_CREDITS) {

                System.Assert.isNull(
                    iur.reduivy__Required_Study_Unit__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Other__c,
                    'The actual value should be as expected'
                );

                System.Assert.isFalse(
                    iur.reduivy__Requirement_Met__c,
                    'The actual value should be as expected'
                );

            } else if (iur.reduivy__Requirement_Type__c == IUR_REQTYPE_OTHER) {

                System.Assert.isNull(
                    iur.reduivy__Required_Study_Unit__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    iur.reduivy__Credits__c,
                    'The actual value should be as expected'
                );
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test as an admin user the IPS requirement met field is reset (after insert)
     */
    @IsTest
    static void testIpsRequirementMetAfterInsertAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        // Setup test data

        // Delete existing IURs
        delete [SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c];

        // Verify pre-test condition
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsuBeforeMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id, LastModifiedDate, reduivy__Requirement_Met__c, reduivy__Requirement_Logic__c, reduivy__Study_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
        ]);

        System.Assert.isFalse(
            ipsuBeforeMap.isEmpty(),
            'The actual value should be as expected'
        );

        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>();
        for (Id ipsuId : ipsuBeforeMap.keySet()) {

            if(!spsUnitMap.containsKey(ipsuBeforeMap.get(ipsuId).reduivy__Study_Plan_Structure__c)){

                reduivy__Study_Plan_Structure__c spsUnit = new reduivy__Study_Plan_Structure__c();
                spsUnit.Id = ipsuBeforeMap.get(ipsuId).reduivy__Study_Plan_Structure__c;
                spsUnit.reduivy__Requirement_Logic__c = 'IUR-0 AND IUR-1 AND IUR-2 AND IUR-3 AND IUR-4';

                spsUnitMap.put(ipsuBeforeMap.get(ipsuId).reduivy__Study_Plan_Structure__c, spsUnit);
            }
        }
        update spsUnitMap.values();

        // Create the individual plan unit requirement records for the test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuBeforeMap.values()) {
            for (String reqType : IUR_REQTYPES) {

                reduivy__Individual_Plan_Unit_Requirement__c iur = new reduivy__Individual_Plan_Unit_Requirement__c();
                iur.reduivy__Individual_Plan_Unit__c = ipsu.Id;
                iur.reduivy__Requirement_ID__c = 'IUR-' + String.valueOf(IUR_REQTYPES.indexOf(reqType));
                iur.reduivy__Credits__c = 0.0;
                iur.reduivy__Requirement_Type__c = reqType;
                iur.reduivy__Other__c = 'Other';
                iurList.add(iur);
            }
        }

        // Perform test
        System.runAs(ADMIN_USER) {

            insert iurList;
        }

        // Verify test result
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsuAfterMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id, LastModifiedDate, reduivy__Requirement_Met__c, reduivy__Requirement_Logic__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsuBeforeMap.keySet()
        ]);

        for (Id ipsuId : ipsuAfterMap.keySet()) {

            System.Assert.areNotEqual(
                ipsuBeforeMap.get(ipsuId).reduivy__Requirement_Met__c, 
                ipsuAfterMap.get(ipsuId).reduivy__Requirement_Met__c,
                'The actual value should be as expected'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test as an admin user the IPS requirement met field is reset (after update)
     */
    @IsTest
    static void testIpsRequirementMetAfterUpdateAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        // Setup test data

        // Verify pre-test condition
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsuBeforeMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id, LastModifiedDate, reduivy__Requirement_Met__c, (select Id, reduivy__Requirement_Met__c, reduivy__Requirement_ID__c from reduivy__Individual_Plan_Unit_Requirements__r)
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId() AND reduivy__Requirement_Met__c = false AND reduivy__Requirement_Logic__c = :IPS_REQUIREMENT_LOGIC
        ]);

        System.Assert.isFalse(
            ipsuBeforeMap.isEmpty(),
            'The actual value should be as expected'
        );

        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT reduivy__Enrollment_Status__c, reduivy__Grade_Result__c FROM reduivy__Individual_Enrollment__c
        ];
        for (reduivy__Individual_Enrollment__c ien : ienList) {

            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Numerical_Grade__c = 90;

        }

        // Perform test
        System.runAs(ADMIN_USER) {

            update ienList;
        }

        // Verify test result
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsuAfterMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id, LastModifiedDate, reduivy__Requirement_Met__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsuBeforeMap.keySet()
        ]);

        for (Id ipsuId : ipsuAfterMap.keySet()) {

            System.Assert.areNotEqual(
                ipsuBeforeMap.get(ipsuId).reduivy__Requirement_Met__c, 
                ipsuAfterMap.get(ipsuId).reduivy__Requirement_Met__c,
                'The actual value should be as expected'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test as an admin user the IPS requirement met field is reset (after delete)
     */
    @IsTest
    static void testIpsRequirementMetAfterDeleteAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        // Setup test data

        // Get the individual plan unit requirement records for the test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsuMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id, reduivy__Requirement_Met__c, (select Id from reduivy__Individual_Plan_Unit_Requirements__r)
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
        ]);

        System.Assert.isFalse(
            ipsuMap.isEmpty(),
            'The actual value should be as expected'
        );

        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuMap.values()) {

            if (!ipsu.reduivy__Individual_Plan_Unit_Requirements__r.isEmpty()) {
                iurList.addAll(ipsu.reduivy__Individual_Plan_Unit_Requirements__r);
            }
        }

        System.Assert.isFalse(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );

        // Perform test
        System.runAs(ADMIN_USER) {

            delete iurList;
        }

        // Verify test result
        for (reduivy__Individual_Plan_Structure__c ipsu : [
            SELECT Id, reduivy__Requirement_Met__c 
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
        ]) {
            System.Assert.isTrue(
                ipsu.reduivy__Requirement_Met__c,
                'The actual value should be as expected'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test as a faculty user the IPS requirement met field is reset (after insert)
     */
    @IsTest
    static void testIpsRequirementMetAfterInsertAsFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        // Setup test data

        // Delete existing IURs
        delete [SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c];

        // Verify pre-test condition
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsuBeforeMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id, LastModifiedDate, reduivy__Requirement_Met__c, reduivy__Requirement_Logic__c, reduivy__Study_Plan_Structure__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
        ]);

        System.Assert.isFalse(
            ipsuBeforeMap.isEmpty(),
            'The actual value should be as expected'
        );

        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>();
        for (Id ipsuId : ipsuBeforeMap.keySet()) {

            if(!spsUnitMap.containsKey(ipsuBeforeMap.get(ipsuId).reduivy__Study_Plan_Structure__c)){

                reduivy__Study_Plan_Structure__c spsUnit = new reduivy__Study_Plan_Structure__c();
                spsUnit.Id = ipsuBeforeMap.get(ipsuId).reduivy__Study_Plan_Structure__c;
                spsUnit.reduivy__Requirement_Logic__c = 'IUR-0 AND IUR-1 AND IUR-2 AND IUR-3 AND IUR-4';

                spsUnitMap.put(ipsuBeforeMap.get(ipsuId).reduivy__Study_Plan_Structure__c, spsUnit);
            }
        }
        update spsUnitMap.values();

        // Create the individual plan unit requirement records for the test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuBeforeMap.values()) {
            for (String reqType : IUR_REQTYPES) {

                reduivy__Individual_Plan_Unit_Requirement__c iur = new reduivy__Individual_Plan_Unit_Requirement__c();
                iur.reduivy__Individual_Plan_Unit__c = ipsu.Id;
                iur.reduivy__Requirement_ID__c = 'IUR-' + String.valueOf(IUR_REQTYPES.indexOf(reqType));
                iur.reduivy__Credits__c = 0.0;
                iur.reduivy__Requirement_Type__c = reqType;
                iur.reduivy__Other__c = 'Other';
                iurList.add(iur);
            }
        }

        // Perform test
        System.runAs(FACULTY_USER) {

            insert iurList;
        }

        // Verify test result
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsuAfterMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id, LastModifiedDate, reduivy__Requirement_Met__c, reduivy__Requirement_Logic__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsuBeforeMap.keySet()
        ]);

        for (Id ipsuId : ipsuAfterMap.keySet()) {

            System.Assert.areNotEqual(
                ipsuBeforeMap.get(ipsuId).reduivy__Requirement_Met__c, 
                ipsuAfterMap.get(ipsuId).reduivy__Requirement_Met__c,
                'The actual value should be as expected'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test as a faculty user the IPS requirement met field is reset (after update)
     */
    @IsTest
    static void testIpsRequirementMetAfterUpdateAsFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        // Setup test data

        // Verify pre-test condition
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsuBeforeMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id, LastModifiedDate, reduivy__Requirement_Met__c, reduivy__Requirement_Logic__c, (select Id, reduivy__Requirement_Met__c, reduivy__Requirement_ID__c from reduivy__Individual_Plan_Unit_Requirements__r)
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId() AND reduivy__Requirement_Met__c = false AND reduivy__Requirement_Logic__c = :IPS_REQUIREMENT_LOGIC
        ]);

        System.Assert.isFalse(
            ipsuBeforeMap.isEmpty(),
            'The actual value should be as expected'
        );

        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT reduivy__Enrollment_Status__c, reduivy__Grade_Result__c FROM reduivy__Individual_Enrollment__c
        ];
        for (reduivy__Individual_Enrollment__c ien : ienList) {

            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Numerical_Grade__c = 90;

        }
    
        // Perform test
        System.runAs(FACULTY_USER) {

            update ienList;
        }

        // Verify test result
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsuAfterMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id, LastModifiedDate, reduivy__Requirement_Met__c, reduivy__Requirement_Logic__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsuBeforeMap.keySet()
        ]);

        for (Id ipsuId : ipsuAfterMap.keySet()) {

            System.Assert.areNotEqual(
                ipsuBeforeMap.get(ipsuId).reduivy__Requirement_Met__c, 
                ipsuAfterMap.get(ipsuId).reduivy__Requirement_Met__c,
                'The actual value should be as expected'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test as a faculty user the IPS requirement met field is reset (after delete)
     */
    @IsTest
    static void testIpsRequirementMetAfterDeleteAsFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        // Setup test data

        // Get the individual plan unit requirement records for the test
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsuMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([
            SELECT Id, reduivy__Requirement_Met__c, (select Id from reduivy__Individual_Plan_Unit_Requirements__r)
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
        ]);

        System.Assert.isFalse(
            ipsuMap.isEmpty(),
            'The actual value should be as expected'
        );

        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuMap.values()) {

            if (!ipsu.reduivy__Individual_Plan_Unit_Requirements__r.isEmpty()) {
                iurList.addAll(ipsu.reduivy__Individual_Plan_Unit_Requirements__r);
            }
        }
        
        System.Assert.isFalse(
            iurList.isEmpty(),
            'The actual value should be as expected'
        );

        // Perform test
        System.runAs(FACULTY_USER) {

            delete iurList;
        }

        // Verify test result
        for (reduivy__Individual_Plan_Structure__c ipsu : [
            SELECT Id, reduivy__Requirement_Met__c 
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
        ]) {
            System.Assert.isTrue(
                ipsu.reduivy__Requirement_Met__c,
                'The actual value should be as expected'
            );
        }

        Test.stopTest();
    }
}