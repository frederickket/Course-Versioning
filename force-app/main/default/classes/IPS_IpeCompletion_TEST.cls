/**
 * @author      WDCi (dblack)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for IPS_IpeCompletion_EXE
 * @changehistory
 * ISS-001817 13-12-2023 dblack - new class
 */
@isTest
public inherited sharing class IPS_IpeCompletion_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final Decimal CREDITS_QTY = 10;

    static final String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);
    static final String SPL_MAJOR = 'BACBIS_MajorA';
    static final String SPL_MINOR = 'BACBIS_MinorA';
    static final String STUDY_INTAKE = 'SYDNEY_BACBIS_CYINTAKE';
        
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

			testFactory.initMasterData(SPU_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
			testFactory.initStudentData(USR_Helper.getApiName(), true);

            List<reduivy__Individual_Program_Enrollment__c> masterIpeList = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childIpeList = new List<reduivy__Individual_Program_Enrollment__c>();

            for (Contact student : testFactory.students.values()) {
                String masterIpekey = student.reduivy__Sample_Record_Code__c + '_' + SPL_MAJOR;
                String childIpekey = student.reduivy__Sample_Record_Code__c + '_' + SPL_MINOR;

                reduivy__Individual_Program_Enrollment__c newMasterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    masterIpekey, 
                    student.Id, 
                    testFactory.studyPlans.get(SPL_MAJOR).reduivy__Study_Program__c, 
                    testFactory.studyPlans.get(SPL_MAJOR).Id, 
                    testFactory.studyIntakes.get(STUDY_INTAKE).Id, 
                    testFactory.academicTerms.get('CYT1').Id, 
                    testFactory.studyIntakes.get(STUDY_INTAKE).reduivy__Default_Study_Pathway__c, 
                    testFactory.campuses.get('SYDNEY').Id, 
                    String.valueOf(testFactory.academicTerms.get('CYT1').reduivy__Start_Date__c.year()), 
                    'Freshman', 
                    true, 
                    IPE_INPROGRESS_STATUS, 
                    null
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

                masterIpeList.add(newMasterIpe);
                childIpeList.add(newChildIpe);

            }

            REDU_SystemMode_UTIL.doInsert(masterIpeList);

            Integer counter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childIpeList) {
                childIpe.reduivy__Master_Enrollment__c = masterIpeList.get(counter).Id;
            }

            REDU_SystemMode_UTIL.doInsert(childIpeList);

            Test.stopTest();
        }
    }

    /**
     * @description Test as an admin user that an update to a top-level individual plan structure (group) rolls up to the individual program enrollment
     */
    @isTest
    static void testA_IpsGroupRollUpToIpeAfterUpdateAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c, reduivy__Credits_Earned__c, reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c = null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the top-level individual plan structure (group) records'
        );

        Set<Id> ipeIdSet = new Set<Id>();
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            ipeIdSet.add(ipsg.reduivy__Individual_Program_Enrollment__c);

            ipsg.reduivy__Credits_Enrolled__c = ((ipsg.reduivy__Credits_Enrolled__c == null) ? 0 : ipsg.reduivy__Credits_Enrolled__c);
            ipsg.reduivy__Credits_Enrolled__c += CREDITS_QTY;

            ipsg.reduivy__Units_Enrolled__c = ((ipsg.reduivy__Units_Enrolled__c == null) ? 0 : ipsg.reduivy__Units_Enrolled__c);
            ++ipsg.reduivy__Units_Enrolled__c;

            ipsg.reduivy__Credits_Earned__c = (ipsg.reduivy__Credits_Earned__c == null) ? 0 : ipsg.reduivy__Credits_Earned__c;
            ipsg.reduivy__Credits_Earned__c += CREDITS_QTY;
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            update ipsgList;
            Test.stopTest();

            // Verify test results
            List<reduivy__Individual_Program_Enrollment__c> ipeList = [
                SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c, reduivy__Credits_Earned__c,
                        (select Id 
                         from reduivy__Individual_Plan_Structures__r
                         where RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
                         and reduivy__Parent_Plan_Structure__c = null)
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE Id IN :ipeIdSet
            ];

            System.Assert.isFalse(
                ipeList.isEmpty(),
                'The list should contain individual program enrollment records'
            );

            for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

                System.Assert.areEqual(
                    ipe.reduivy__Individual_Plan_Structures__r.size() * CREDITS_QTY,
                    ipe.reduivy__Credits_Enrolled__c,
                    'The actual value should be as expected'
                );

                System.Assert.areEqual(
                    ipe.reduivy__Individual_Plan_Structures__r.size(),
                    ipe.reduivy__Units_Enrolled__c,
                    'The actual value should be as expected'
                );

                System.Assert.areEqual(
                    ipe.reduivy__Individual_Plan_Structures__r.size() * CREDITS_QTY,
                    ipe.reduivy__Credits_Earned__c,
                    'The actual value should be as expected'
                );
            }
        }
    }

    /**
     * @description Test as a faculty user that an update to a top-level individual plan structure (group) rolls up to the individual program enrollment
     */
    @isTest
    static void testB_IpsGroupRollUpToIpeAfterUpdateAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c, reduivy__Credits_Earned__c, reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c = null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the top-level individual plan structure (group) records'
        );

        Set<Id> ipeIdSet = new Set<Id>();
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            ipeIdSet.add(ipsg.reduivy__Individual_Program_Enrollment__c);

            ipsg.reduivy__Credits_Enrolled__c = ((ipsg.reduivy__Credits_Enrolled__c == null) ? 0 : ipsg.reduivy__Credits_Enrolled__c);
            ipsg.reduivy__Credits_Enrolled__c += CREDITS_QTY;

            ipsg.reduivy__Units_Enrolled__c = ((ipsg.reduivy__Units_Enrolled__c == null) ? 0 : ipsg.reduivy__Units_Enrolled__c);
            ++ipsg.reduivy__Units_Enrolled__c;

            ipsg.reduivy__Credits_Earned__c = (ipsg.reduivy__Credits_Earned__c == null) ? 0 : ipsg.reduivy__Credits_Earned__c;
            ipsg.reduivy__Credits_Earned__c += CREDITS_QTY;
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            update ipsgList;
            Test.stopTest();

            // Verify test results
            List<reduivy__Individual_Program_Enrollment__c> ipeList = [
                SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c, reduivy__Credits_Earned__c,
                        (select Id 
                         from reduivy__Individual_Plan_Structures__r
                         where RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
                         and reduivy__Parent_Plan_Structure__c = null)
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE Id IN :ipeIdSet
            ];

            System.Assert.isFalse(
                ipeList.isEmpty(),
                'The list should contain individual program enrollment records'
            );

            for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

                System.Assert.areEqual(
                    ipe.reduivy__Individual_Plan_Structures__r.size() * CREDITS_QTY,
                    ipe.reduivy__Credits_Enrolled__c,
                    'The actual value should be as expected'
                );

                System.Assert.areEqual(
                    ipe.reduivy__Individual_Plan_Structures__r.size(),
                    ipe.reduivy__Units_Enrolled__c,
                    'The actual value should be as expected'
                );

                System.Assert.areEqual(
                    ipe.reduivy__Individual_Plan_Structures__r.size() * CREDITS_QTY,
                    ipe.reduivy__Credits_Earned__c,
                    'The actual value should be as expected'
                );
            }
        }
    }

    /**
     * @description Test as a student user that an update to a top-level individual plan structure (group) rolls up to the individual program enrollment
     */
    @isTest
    static void testC_IpsGroupRollUpToIpeAfterUpdateAsStudent() {

        // Setup test data

        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits_Earned__c, reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN :studentContacts
            AND reduivy__Parent_Plan_Structure__c = null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the top-level individual plan structure (group) records'
        );

        Set<Id> ipeIdSet = new Set<Id>();
        List<reduivy__Individual_Plan_Structure__c> ipsgUpdateList = new List<reduivy__Individual_Plan_Structure__c>();
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            ipeIdSet.add(ipsg.reduivy__Individual_Program_Enrollment__c);

            ipsg.reduivy__Credits_Enrolled__c = ((ipsg.reduivy__Credits_Enrolled__c == null) ? 0 : ipsg.reduivy__Credits_Enrolled__c);
            ipsg.reduivy__Credits_Enrolled__c += CREDITS_QTY;

            ipsg.reduivy__Units_Enrolled__c = ((ipsg.reduivy__Units_Enrolled__c == null) ? 0 : ipsg.reduivy__Units_Enrolled__c);
            ++ipsg.reduivy__Units_Enrolled__c;

            ipsg.reduivy__Credits_Earned__c = (ipsg.reduivy__Credits_Earned__c == null) ? 0 : ipsg.reduivy__Credits_Earned__c;
            ipsg.reduivy__Credits_Earned__c += CREDITS_QTY;

            ipsgUpdateList.add(ipsg);
        }

        System.runAs(studentUser) {

            // Execute test
            Test.startTest();
            update ipsgUpdateList;
            Test.stopTest();

            // Verify test results
            List<reduivy__Individual_Program_Enrollment__c> ipeList = [
                SELECT  reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c, reduivy__Credits_Earned__c,
                        (select Id, reduivy__Credits__c
                         from reduivy__Individual_Plan_Structures__r
                         where RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
                         and reduivy__Parent_Plan_Structure__c = null)
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE Id IN :ipeIdSet
            ];

            System.Assert.isFalse(
                ipeList.isEmpty(),
                'The list should contain individual program enrollment records'
            );

            for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

                System.Assert.areEqual(
                    ipe.reduivy__Individual_Plan_Structures__r.size() * CREDITS_QTY,
                    ipe.reduivy__Credits_Enrolled__c,
                    'The actual value should be as expected'
                );

                System.Assert.areEqual(
                    ipe.reduivy__Individual_Plan_Structures__r.size(),
                    ipe.reduivy__Units_Enrolled__c,
                    'The actual value should be as expected'
                );

                System.Assert.areEqual(
                    ipe.reduivy__Individual_Plan_Structures__r.size() * CREDITS_QTY,
                    ipe.reduivy__Credits_Earned__c,
                    'The actual value should be as expected'
                );
            }
        }
    }

    /**
     * @description Test as an admin user that deletion of a top-level individual plan structure (group) rolls up to the individual program enrollment
     */
    @isTest
    static void testD_IpsGroupRollUpToIpeAfterDeleteAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  Id, reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c, 
                    reduivy__Credits_Earned__c, reduivy__Individual_Program_Enrollment__c,
                    reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Earned__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c = null
            AND reduivy__Individual_Program_Enrollment__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the top-level individual plan structure (group) records'
        );

        Set<Id> ipsgIdSet = new Set<Id>();
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            ipsgIdSet.add(ipsg.Id);

            ipsg.reduivy__Credits_Enrolled__c = ((ipsg.reduivy__Credits_Enrolled__c == null) ? 0 : ipsg.reduivy__Credits_Enrolled__c);
            ipsg.reduivy__Credits_Enrolled__c += CREDITS_QTY;

            ipsg.reduivy__Units_Enrolled__c = ((ipsg.reduivy__Units_Enrolled__c == null) ? 0 : ipsg.reduivy__Units_Enrolled__c);
            ++ipsg.reduivy__Units_Enrolled__c;

            ipsg.reduivy__Credits_Earned__c = (ipsg.reduivy__Credits_Earned__c == null) ? 0 : ipsg.reduivy__Credits_Earned__c;
            ipsg.reduivy__Credits_Earned__c += CREDITS_QTY;
        }

        update ipsgList;

        // Verify pre-test condition
        for (reduivy__Individual_Plan_Structure__c ipsg : [
            SELECT  reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Enrolled__c,
                    reduivy__Individual_Program_Enrollment__r.reduivy__Units_Enrolled__c,
                    reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Earned__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ]) {
            System.Assert.isTrue(
                ipsg.reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Enrolled__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Individual_Program_Enrollment__r.reduivy__Units_Enrolled__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Earned__c > 0,
                'The actual value should be as expected'
            );
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            delete ipsgList;
            Test.stopTest();

            // Verify test results
            for (reduivy__Individual_Plan_Structure__c ipsg : [
                SELECT  reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Enrolled__c,
                        reduivy__Individual_Program_Enrollment__r.reduivy__Units_Enrolled__c,
                        reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Earned__c
                FROM reduivy__Individual_Plan_Structure__c
                WHERE Id IN :ipsgIdSet
            ]) {
                System.Assert.areEqual(
                    0, ipsg.reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Enrolled__c,
                    'The actual value should be as expected'
                );

                System.Assert.areEqual(
                    0, ipsg.reduivy__Individual_Program_Enrollment__r.reduivy__Units_Enrolled__c,
                    'The actual value should be as expected'
                );

                System.Assert.areEqual(
                    0, ipsg.reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Earned__c,
                    'The actual value should be as expected'
                );
            }
		}
    }

    /**
     * @description Test as a faculty user that deletion of a top-level individual plan structure (group) rolls up to the individual program enrollment
     */
    @isTest
    static void testE_IpsGroupRollUpToIpeAfterDeleteAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  Id, reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits_Earned__c, reduivy__Individual_Program_Enrollment__c,
                    reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Earned__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Parent_Plan_Structure__c = null
            AND reduivy__Individual_Program_Enrollment__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the top-level individual plan structure (group) records'
        );

        Set<Id> ipsgIdSet = new Set<Id>();
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            ipsgIdSet.add(ipsg.Id);

            ipsg.reduivy__Credits_Enrolled__c = ((ipsg.reduivy__Credits_Enrolled__c == null) ? 0 : ipsg.reduivy__Credits_Enrolled__c);
            ipsg.reduivy__Credits_Enrolled__c += CREDITS_QTY;

            ipsg.reduivy__Units_Enrolled__c = ((ipsg.reduivy__Units_Enrolled__c == null) ? 0 : ipsg.reduivy__Units_Enrolled__c);
            ++ipsg.reduivy__Units_Enrolled__c;

            ipsg.reduivy__Credits_Earned__c = (ipsg.reduivy__Credits_Earned__c == null) ? 0 : ipsg.reduivy__Credits_Earned__c;
            ipsg.reduivy__Credits_Earned__c += CREDITS_QTY;
        }

        update ipsgList;

        // Verify pre-test condition
        for (reduivy__Individual_Plan_Structure__c ipsg : [
            SELECT  reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Enrolled__c,
                    reduivy__Individual_Program_Enrollment__r.reduivy__Units_Enrolled__c,
                    reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Earned__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ]) {
            System.Assert.isTrue(
                ipsg.reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Enrolled__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Individual_Program_Enrollment__r.reduivy__Units_Enrolled__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Earned__c > 0,
                'The actual value should be as expected'
            );
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();

            try {
                delete ipsgList;
                System.Assert.fail('This should fail with insufficient access error.');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'));
            }

            Test.stopTest();
		}
    }

    /**
     * @description Test as a student user that deletion of a top-level individual plan structure (group) rolls up to the individual program enrollment
     */
    @isTest
    static void testF_IpsGroupRollUpToIpeAfterDeleteAsStudent() {

        // Setup test data

        // Get student
        List<Contact> studentContacts = [
            SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1
        ];
        User studentUser = [
            SELECT Id FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];

        // Get individual plan structure (group) records for update
        List<reduivy__Individual_Plan_Structure__c> ipsgList = [
            SELECT  Id, reduivy__Credits_Enrolled__c, reduivy__Units_Enrolled__c,
                    reduivy__Credits_Earned__c, reduivy__Individual_Program_Enrollment__c,
                    reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Earned__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN :studentContacts
            AND reduivy__Parent_Plan_Structure__c = null
            AND reduivy__Individual_Program_Enrollment__c != null
            AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
        ];

        System.Assert.isFalse(
            ipsgList.isEmpty(),
            'The list should contain the top-level individual plan structure (group) records'
        );

        Set<Id> ipsgIdSet = new Set<Id>();
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            ipsgIdSet.add(ipsg.Id);

            ipsg.reduivy__Credits_Enrolled__c = ((ipsg.reduivy__Credits_Enrolled__c == null) ? 0 : ipsg.reduivy__Credits_Enrolled__c);
            ipsg.reduivy__Credits_Enrolled__c += CREDITS_QTY;

            ipsg.reduivy__Units_Enrolled__c = ((ipsg.reduivy__Units_Enrolled__c == null) ? 0 : ipsg.reduivy__Units_Enrolled__c);
            ++ipsg.reduivy__Units_Enrolled__c;

            ipsg.reduivy__Credits_Earned__c = (ipsg.reduivy__Credits_Earned__c == null) ? 0 : ipsg.reduivy__Credits_Earned__c;
            ipsg.reduivy__Credits_Earned__c += CREDITS_QTY;
        }

        update ipsgList;

        // Verify pre-test condition
        ipsgList = [
            SELECT  reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Enrolled__c,
                    reduivy__Individual_Program_Enrollment__r.reduivy__Units_Enrolled__c,
                    reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Earned__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE Id IN :ipsgIdSet
        ];
        for (reduivy__Individual_Plan_Structure__c ipsg : ipsgList) {

            System.Assert.isTrue(
                ipsg.reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Enrolled__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Individual_Program_Enrollment__r.reduivy__Units_Enrolled__c > 0,
                'The actual value should be as expected'
            );

            System.Assert.isTrue(
                ipsg.reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Earned__c > 0,
                'The actual value should be as expected'
            );
        }

        System.runAs(studentUser) {

            // Execute test
            Test.startTest();

            try {
                delete ipsgList;
                System.Assert.fail('This should fail with insufficient access error.');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'));
            }

            Test.stopTest();
		}
    }
}