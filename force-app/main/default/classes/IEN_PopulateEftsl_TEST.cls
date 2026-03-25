/**
 * @author      WDCi (dblack)
 * @date        Nov 2023
 * @group       Test
 * @description Test class for IEN_PopulateEftsl_EXE
 * @changehistory
 * ISS-001765 03-11-2023 dblack - new class
 * ISS-001837 10-01-2024 dblack - updated so that the EFTSL logic is consistent with the credits offered logic
 * ISS-002752 16-12-2025 XiRouh - Added testSofChangedToSameStudyUnit()
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@IsTest
public inherited sharing class IEN_PopulateEftsl_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final Integer IEN_QTY = 2;
    static final Decimal EFTSL_QTY = 0.1;

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();

        	testFactory.initMasterData(SUN_Helper.getApiName());
			testFactory.initOfferingData(SOF_Helper.getApiName());
			testFactory.initStudentData(IPR_Helper.getApiName(), true);

            Test.stopTest();
		}
    }
	
    /**
     * @description Test as an admin user that the individual enrollment EFTSL is set upon insert
     */
    @IsTest
    static void testIenEftslIsSetOnInsertAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        // Set up test data

        // Get student
        User studentUser = testFactory.getStudentUser();

        // Get study offering records
        List<reduivy__Study_Offering__c> sofList = [
            SELECT Id FROM reduivy__Study_Offering__c LIMIT :IEN_QTY
        ];

        System.Assert.isFalse(
            sofList.isEmpty(),
            'The list should contain study offering records'
        );

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : sofList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sof.Id;
            String enrollmentStatus = null;
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

		System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            insert ienList;
            Test.stopTest();		
		}

        // Verify test result
        ienList = [
            SELECT  reduivy__EFTSL__c,
                    reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c,
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a faculty user that the individual enrollment EFTSL is set upon insert
     */
    @IsTest
    static void testIenEftslIsSetOnInsertAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        // Set up test data

        // Get student
        User studentUser = testFactory.getStudentUser();

        // Get study offering records
        List<reduivy__Study_Offering__c> sofList = [
            SELECT Id FROM reduivy__Study_Offering__c LIMIT :IEN_QTY
        ];

        System.Assert.isFalse(
            sofList.isEmpty(),
            'The list should contain study offering records'
        );

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : sofList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sof.Id;
            String enrollmentStatus = null;
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

		System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            insert ienList;
            Test.stopTest();		
		}

        // Verify test result
        ienList = [
            SELECT  reduivy__EFTSL__c,
                    reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c,
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a student user that the individual enrollment EFTSL is set upon insert
     */
    @IsTest
    static void testIenEftslIsSetOnInsertAsStudent() {

        // Set up test data

        // Get student
        User studentUser = testFactory.getStudentUser();

        // Get study offering records
        List<reduivy__Study_Offering__c> sofList = [
            SELECT Id FROM reduivy__Study_Offering__c LIMIT :IEN_QTY
        ];

        System.Assert.isFalse(
            sofList.isEmpty(),
            'The list should contain study offering records'
        );

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : sofList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sof.Id;
            String enrollmentStatus = null;
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

		System.runAs(studentUser) {

            // Execute test
            Test.startTest();
            insert ienList;
            Test.stopTest();		
		}

        // Verify test result
        ienList = [
            SELECT  reduivy__EFTSL__c,
                    reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c,
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as an admin user that the individual enrollment EFTSL is set upon update
     */
    @IsTest
    static void testIenEftslIsSetOnUpdateAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        // Set up test data

        // Get student
        User studentUser = testFactory.getStudentUser();

        // Get study offering records
        List<reduivy__Study_Offering__c> sofList = new List<reduivy__Study_Offering__c>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id, reduivy__Study_Unit__c from reduivy__Study_Offerings__r) FROM reduivy__Study_Unit__c WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1') LIMIT :IEN_QTY
        ];
        for (reduivy__Study_Unit__c sun : sunList) {
            sofList.add(sun.reduivy__Study_Offerings__r.get(0));
            continue;
        }

        System.Assert.isFalse(
            sofList.isEmpty(),
            'The list should contain study offering records'
        );

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        Test.startTest();

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : sofList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sof.Id;
            String enrollmentStatus = null;
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

        insert ienList;

        // Verify pre-test condition and update for test
        ienList = [
            SELECT Id, reduivy__EFTSL__c, reduivy__Target_Unit_Id__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            // Change the study offering to one that has a different study unit
            for (reduivy__Study_Offering__c sof : sofList) {
                if (sof.reduivy__Study_Unit__c != ien.reduivy__Target_Unit_Id__c) {
                    ien.reduivy__Study_Offering__c = sof.Id;
                    ien.reduivy__EFTSL__c = null;
                }
            }
        }

		System.runAs(ADMIN_USER) {

            // Execute test
            update ienList;
		}

        // Verify test result
        ienList = [
            SELECT  reduivy__EFTSL__c,
                    reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c,
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test as a faculty user that the individual enrollment EFTSL is set upon update
     */
    @IsTest
    static void testIenEftslIsSetOnUpdateAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        // Set up test data

        // Get student
        User studentUser = testFactory.getStudentUser();

        // Get study offering records
        List<reduivy__Study_Offering__c> sofList = new List<reduivy__Study_Offering__c>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id, reduivy__Study_Unit__c from reduivy__Study_Offerings__r) FROM reduivy__Study_Unit__c WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1') LIMIT :IEN_QTY
        ];
        for (reduivy__Study_Unit__c sun : sunList) {
            sofList.add(sun.reduivy__Study_Offerings__r.get(0));
            continue;
        }

        System.Assert.isFalse(
            sofList.isEmpty(),
            'The list should contain study offering records'
        );

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        Test.startTest();

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : sofList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sof.Id;
            String enrollmentStatus = null;
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

        insert ienList;

        // Verify pre-test condition and update for test
        ienList = [
            SELECT Id, reduivy__EFTSL__c, reduivy__Target_Unit_Id__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            // Change the study offering to one that has a different study unit
            for (reduivy__Study_Offering__c sof : sofList) {
                if (sof.reduivy__Study_Unit__c != ien.reduivy__Target_Unit_Id__c) {
                    ien.reduivy__Study_Offering__c = sof.Id;
                    ien.reduivy__EFTSL__c = null;
                }
            }
        }

		System.runAs(FACULTY_USER) {

            // Execute test
            update ienList;
		}

        // Verify test result
        ienList = [
            SELECT  reduivy__EFTSL__c,
                    reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c,
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test as a student user that the individual enrollment EFTSL is set upon update
     */
    @IsTest
    static void testIenEftslIsSetOnUpdateAsStudent() {

        // Set up test data

        // Get student
        User studentUser = testFactory.getStudentUser();

        // Get study offering records
        List<reduivy__Study_Offering__c> sofList = new List<reduivy__Study_Offering__c>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id, reduivy__Study_Unit__c from reduivy__Study_Offerings__r) FROM reduivy__Study_Unit__c WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1') LIMIT :IEN_QTY
        ];
        for (reduivy__Study_Unit__c sun : sunList) {
            sofList.add(sun.reduivy__Study_Offerings__r.get(0));
            continue;
        }

        System.Assert.isFalse(
            sofList.isEmpty(),
            'The list should contain study offering records'
        );

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        Test.startTest();

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : sofList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sof.Id;
            String enrollmentStatus = null;
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

        insert ienList;

        // Verify pre-test condition and update for test
        ienList = [
            SELECT Id, reduivy__EFTSL__c, reduivy__Target_Unit_Id__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            // Change the study offering to one that has a different study unit
            for (reduivy__Study_Offering__c sof : sofList) {
                if (sof.reduivy__Study_Unit__c != ien.reduivy__Target_Unit_Id__c) {
                    ien.reduivy__Study_Offering__c = sof.Id;
                    ien.reduivy__EFTSL__c = null;
                }
            }
        }

		System.runAs(studentUser) {

            // Execute test
            update ienList;
		}

        // Verify test result
        ienList = [
            SELECT  reduivy__EFTSL__c,
                    reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c,
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test as an admin user that the individual enrollment EFTSL is not overriden upon insert
     */
    @IsTest
    static void testIenEftslNotSetOnInsertAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        // Set up test data

        // Get student
        User studentUser = testFactory.getStudentUser();

        // Get study offering records
        List<reduivy__Study_Offering__c> sofList = [
            SELECT Id, reduivy__Study_Unit__r.reduivy__Default_EFTSL__c FROM reduivy__Study_Offering__c LIMIT :IEN_QTY
        ];

        System.Assert.isFalse(
            sofList.isEmpty(),
            'The list should contain study offering records'
        );

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        Test.startTest();

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : sofList) {

            System.Assert.areNotEqual(
                sof.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c,
                EFTSL_QTY,
                'The actual value should not be the same as the expected value'
            );

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sof.Id;
            String enrollmentStatus = null;
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

            ien.reduivy__EFTSL__c = EFTSL_QTY;

            ienList.add(ien);
        }

		System.runAs(ADMIN_USER) {

            // Execute test
            insert ienList;
		}

        // Verify test result
        ienList = [
            SELECT  reduivy__EFTSL__c,
                    reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: ienList
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                 EFTSL_QTY,
                 ien.reduivy__EFTSL__c,
                 'The actual value should not be the same as the expected value'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test as a faculty user that the individual enrollment EFTSL is not overriden upon insert
     */
    @IsTest
    static void testIenEftslNotSetOnInsertAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        // Set up test data

        // Get student
        User studentUser = testFactory.getStudentUser();

        // Get study offering records
        List<reduivy__Study_Offering__c> sofList = [
            SELECT Id, reduivy__Study_Unit__r.reduivy__Default_EFTSL__c FROM reduivy__Study_Offering__c LIMIT :IEN_QTY
        ];

        System.Assert.isFalse(
            sofList.isEmpty(),
            'The list should contain study offering records'
        );

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        Test.startTest();

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : sofList) {

            System.Assert.areNotEqual(
                sof.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c,
                EFTSL_QTY,
                'The actual value should not be the same as the expected value'
            );

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sof.Id;
            String enrollmentStatus = null;
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

            ien.reduivy__EFTSL__c = EFTSL_QTY;

            ienList.add(ien);
        }

		System.runAs(FACULTY_USER) {

            // Execute test
            insert ienList;
		}

        // Verify test result
        ienList = [
            SELECT  reduivy__EFTSL__c,
                    reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: ienList
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                 EFTSL_QTY,
                 ien.reduivy__EFTSL__c,
                 'The actual value should not be the same as the expected value'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test as a student user that the individual enrollment EFTSL is not overriden upon insert
     */
    @IsTest
    static void testIenEftslNotSetOnInsertAsStudent() {

        // Set up test data

        // Get student
        User studentUser = testFactory.getStudentUser();

        // Get study offering records
        List<reduivy__Study_Offering__c> sofList = [
            SELECT Id, reduivy__Study_Unit__r.reduivy__Default_EFTSL__c FROM reduivy__Study_Offering__c LIMIT :IEN_QTY
        ];

        System.Assert.isFalse(
            sofList.isEmpty(),
            'The list should contain study offering records'
        );

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        Test.startTest();

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : sofList) {

            System.Assert.areNotEqual(
                sof.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c,
                EFTSL_QTY,
                'The actual value should not be the same as the expected value'
            );

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sof.Id;
            String enrollmentStatus = null;
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

            ien.reduivy__EFTSL__c = EFTSL_QTY;

            ienList.add(ien);
        }

		System.runAs(studentUser) {

            // Execute test
            insert ienList;
		}

        // Verify test result
        ienList = [
            SELECT  reduivy__EFTSL__c,
                    reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: ienList
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                 EFTSL_QTY,
                 ien.reduivy__EFTSL__c,
                 'The actual value should not be the same as the expected value'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test as an admin user that the individual enrollment EFTSL is not changed upon update
     */
    @IsTest
    static void testIenEftslNotSetOnUpdateAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        // Set up test data

        // Get student
        User studentUser = testFactory.getStudentUser();

        // Get study offering records
        List<reduivy__Study_Offering__c> sofList = new List<reduivy__Study_Offering__c>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id, reduivy__Study_Unit__c from reduivy__Study_Offerings__r) FROM reduivy__Study_Unit__c WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1') LIMIT :IEN_QTY
        ];
        for (reduivy__Study_Unit__c sun : sunList) {
            sofList.add(sun.reduivy__Study_Offerings__r.get(0));
            continue;
        }

        System.Assert.isFalse(
            sofList.isEmpty(),
            'The list should contain study offering records'
        );

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        Test.startTest();

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : sofList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sof.Id;
            String enrollmentStatus = null;
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

        insert ienList;

        // Verify pre-test condition and update for test
        ienList = [
            SELECT Id, reduivy__EFTSL__c, reduivy__Target_Unit_Id__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            // Change the study offering to one that has a different study unit
            for (reduivy__Study_Offering__c sof : sofList) {
                if (sof.reduivy__Study_Unit__c != ien.reduivy__Target_Unit_Id__c) {
                    ien.reduivy__Study_Offering__c = sof.Id;
                    ien.reduivy__EFTSL__c = EFTSL_QTY;
                }
            }
        }

		System.runAs(ADMIN_USER) {

            // Execute test
            update ienList;
		}

        // Verify test result
        ienList = [
            SELECT  reduivy__EFTSL__c,
                    reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                EFTSL_QTY,
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test as a faculty user that the individual enrollment EFTSL is not changed upon update
     */
    @IsTest
    static void testIenEftslNotSetOnUpdateAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        // Set up test data

        // Get student
        User studentUser = testFactory.getStudentUser();

        // Get study offering records
        List<reduivy__Study_Offering__c> sofList = new List<reduivy__Study_Offering__c>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id, reduivy__Study_Unit__c from reduivy__Study_Offerings__r) FROM reduivy__Study_Unit__c WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1') LIMIT :IEN_QTY
        ];
        for (reduivy__Study_Unit__c sun : sunList) {
            sofList.add(sun.reduivy__Study_Offerings__r.get(0));
            continue;
        }

        System.Assert.isFalse(
            sofList.isEmpty(),
            'The list should contain study offering records'
        );

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        Test.startTest();

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : sofList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sof.Id;
            String enrollmentStatus = null;
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

        insert ienList;

        // Verify pre-test condition and update for test
        ienList = [
            SELECT Id, reduivy__EFTSL__c, reduivy__Target_Unit_Id__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            // Change the study offering to one that has a different study unit
            for (reduivy__Study_Offering__c sof : sofList) {
                if (sof.reduivy__Study_Unit__c != ien.reduivy__Target_Unit_Id__c) {
                    ien.reduivy__Study_Offering__c = sof.Id;
                    ien.reduivy__EFTSL__c = EFTSL_QTY;
                }
            }
        }

		System.runAs(FACULTY_USER) {

            // Execute test
            update ienList;
		}

        // Verify test result
        ienList = [
            SELECT  reduivy__EFTSL__c,
                    reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                EFTSL_QTY,
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test as a student user that the individual enrollment EFTSL is not changed upon update
     */
    @IsTest
    static void testIenEftslNotSetOnUpdateAsStudent() {

        // Set up test data

        // Get student
        User studentUser = testFactory.getStudentUser();

        // Get study offering records
        List<reduivy__Study_Offering__c> sofList = new List<reduivy__Study_Offering__c>();
        List<reduivy__Study_Unit__c> sunList = [
            SELECT Id, (select Id, reduivy__Study_Unit__c from reduivy__Study_Offerings__r) FROM reduivy__Study_Unit__c WHERE reduivy__Unit_Code__c IN: testFactory.termSunList.get('CYT1') LIMIT :IEN_QTY
        ];
        for (reduivy__Study_Unit__c sun : sunList) {
            sofList.add(sun.reduivy__Study_Offerings__r.get(0));
            continue;
        }

        System.Assert.isFalse(
            sofList.isEmpty(),
            'The list should contain study offering records'
        );

        Test.startTest();

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        // Create individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : sofList) {

            String sampleRecordCode = null;
            Id contactId = studentUser.ContactId;
            Id studyOfferingId = sof.Id;
            String enrollmentStatus = null;
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

        insert ienList;

        // Verify pre-test condition and update for test
        ienList = [
            SELECT Id, reduivy__EFTSL__c, reduivy__Target_Unit_Id__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            // Change the study offering to one that has a different study unit
            for (reduivy__Study_Offering__c sof : sofList) {
                if (sof.reduivy__Study_Unit__c != ien.reduivy__Target_Unit_Id__c) {
                    ien.reduivy__Study_Offering__c = sof.Id;
                    ien.reduivy__EFTSL__c = EFTSL_QTY;
                }
            }
        }

		System.runAs(studentUser) {

            // Execute test
            update ienList;
		}

        // Verify test result
        ienList = [
            SELECT  reduivy__EFTSL__c,
                    reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isNotNull(
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                EFTSL_QTY,
                ien.reduivy__EFTSL__c,
                'The actual value should be as expected'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test changing SOF to another SOF with the SAME study unit as admin
     */
    @IsTest
    static void testEftslSofChangedToSameStudyUnitAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        // Get student
        List<Contact> studentContacts = [
            SELECT Id 
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT 
            LIMIT 1
        ];
        
        System.Assert.isFalse(studentContacts.isEmpty(), 'Should have at least one student contact');

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN :studentContacts LIMIT 1];

        // Get a study unit
        reduivy__Study_Unit__c studyUnit = [
            SELECT Id, reduivy__Default_EFTSL__c 
            FROM reduivy__Study_Unit__c 
            WHERE reduivy__Default_EFTSL__c != null
            LIMIT 1
        ];

        // Ensure study unit has EFTSL value
        if (studyUnit.reduivy__Default_EFTSL__c == null) {
            studyUnit.reduivy__Default_EFTSL__c = 0.125;
            update studyUnit;
        }

        // Get or create academic term
        reduivy__Study_Term__c academicTerm = [
            SELECT Id 
            FROM reduivy__Study_Term__c 
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId()
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        Id campusId = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1].Id;

        // Create TWO study offerings for the SAME study unit
        List<reduivy__Study_Offering__c> sofList = new List<reduivy__Study_Offering__c>();
        
        sofList.add(new reduivy__Study_Offering__c(
            Name = 'Test SOF 1 - Same Unit',
            reduivy__Study_Unit__c = studyUnit.Id,
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campusId,
            reduivy__Start_Date__c = System.today(),
            reduivy__End_Date__c = System.today().addDays(30),
            reduivy__Capacity__c = 20
        ));

        sofList.add(new reduivy__Study_Offering__c(
            Name = 'Test SOF 2 - Same Unit',
            reduivy__Study_Unit__c = studyUnit.Id,
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campusId,
            reduivy__Start_Date__c = System.today().addDays(1),
            reduivy__End_Date__c = System.today().addDays(31),
            reduivy__Capacity__c = 20
        ));

        insert sofList;

        System.Assert.areEqual(2, sofList.size(), 'Should have created 2 study offerings');

        // Create IEN with first SOF
        reduivy__Individual_Enrollment__c ien = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sofList[0].Id,
            RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Enrollment_Status__c = IEN_Helper.getInProgressStatuses()[0],
            reduivy__Enrollment_Date__c = System.today(),
            reduivy__Study_Unit__c = studyUnit.Id,
            reduivy__Individual_Academic_Profile__c = studentIpfs[0].Id
        );

        Test.startTest();
        
        System.runAs(ADMIN_USER) {
            insert ien;
        }

        // Verify EFTSL was set on insert
        ien = [
            SELECT Id, 
            reduivy__EFTSL__c, 
            reduivy__Study_Offering__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE Id = :ien.Id
        ];

        System.Assert.isNotNull(ien.reduivy__EFTSL__c, 
            'EFTSL should be set on insert');
        System.Assert.areEqual(studyUnit.reduivy__Default_EFTSL__c, ien.reduivy__EFTSL__c,
            'EFTSL should match study unit default EFTSL');
        System.Assert.areEqual(sofList[0].Id, ien.reduivy__Study_Offering__c,
            'IEN should be linked to first SOF');

        Decimal originalEftsl = ien.reduivy__EFTSL__c;

        // Clear EFTSL and change to SECOND SOF (same study unit)
        ien.reduivy__EFTSL__c = null;
        studyUnit.reduivy__Default_EFTSL__c = 50;

        REDU_TriggerController.muteTriggers(new Set<String>{'IEN_PopulateEftsl_EXE'});
        update ien;
        update studyUnit;
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IEN_PopulateEftsl_EXE'});

        studyUnit = [
            SELECT Id, reduivy__Default_EFTSL__c 
            FROM reduivy__Study_Unit__c 
            WHERE Id = :studyUnit.Id
            LIMIT 1
        ];

        System.Assert.areEqual(50, studyUnit.reduivy__Default_EFTSL__c,
            'Default EFTSL should be updated to 50');
        
        ien.reduivy__Study_Offering__c = sofList[1].Id;

        System.runAs(ADMIN_USER) {
            update ien;
        }

        Test.stopTest();

        // Verify EFTSL was recalculated even though study unit is the same
        ien = [
            SELECT Id, 
            reduivy__EFTSL__c, 
            reduivy__Study_Offering__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE Id = :ien.Id
        ];

        System.Assert.isNotNull(ien.reduivy__EFTSL__c,
            'EFTSL should be recalculated after SOF change');
        System.Assert.areEqual(studyUnit.reduivy__Default_EFTSL__c, ien.reduivy__EFTSL__c,
            'EFTSL should still match study unit default EFTSL');
        System.Assert.areEqual(sofList[1].Id, ien.reduivy__Study_Offering__c,
            'IEN should now be linked to second SOF');
        System.Assert.areEqual(studyUnit.Id, ien.reduivy__Target_Unit_Id__c,
            'Target Unit should remain the same');
        
        // EFTSL should not be the same value
        System.Assert.areNotEqual(originalEftsl, ien.reduivy__EFTSL__c,
            'EFTSL value should be same (same study unit) but recalculated');
    }

    /**
     * @description Test changing SOF to another SOF with the SAME study unit as faculty
     */
    @IsTest
    static void testEftslSofChangedToSameStudyUnitAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        // Get student
        List<Contact> studentContacts = [
            SELECT Id 
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT 
            LIMIT 1
        ];
        
        System.Assert.isFalse(studentContacts.isEmpty(), 'Should have at least one student contact');

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN :studentContacts LIMIT 1];

        // Get a study unit
        reduivy__Study_Unit__c studyUnit = [
            SELECT Id, reduivy__Default_EFTSL__c 
            FROM reduivy__Study_Unit__c 
            WHERE reduivy__Default_EFTSL__c != null
            LIMIT 1
        ];

        // Ensure study unit has EFTSL value
        if (studyUnit.reduivy__Default_EFTSL__c == null) {
            studyUnit.reduivy__Default_EFTSL__c = 0.125;
            update studyUnit;
        }

        // Get or create academic term
        reduivy__Study_Term__c academicTerm = [
            SELECT Id 
            FROM reduivy__Study_Term__c 
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId()
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        Id campusId = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1].Id;

        // Create TWO study offerings for the SAME study unit
        List<reduivy__Study_Offering__c> sofList = new List<reduivy__Study_Offering__c>();
        
        sofList.add(new reduivy__Study_Offering__c(
            Name = 'Test SOF 1 - Same Unit',
            reduivy__Study_Unit__c = studyUnit.Id,
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campusId,
            reduivy__Start_Date__c = System.today(),
            reduivy__End_Date__c = System.today().addDays(30),
            reduivy__Capacity__c = 20
        ));

        sofList.add(new reduivy__Study_Offering__c(
            Name = 'Test SOF 2 - Same Unit',
            reduivy__Study_Unit__c = studyUnit.Id,
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campusId,
            reduivy__Start_Date__c = System.today().addDays(1),
            reduivy__End_Date__c = System.today().addDays(31),
            reduivy__Capacity__c = 20
        ));

        insert sofList;

        System.Assert.areEqual(2, sofList.size(), 'Should have created 2 study offerings');

        // Create IEN with first SOF
        reduivy__Individual_Enrollment__c ien = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sofList[0].Id,
            RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Enrollment_Status__c = IEN_Helper.getInProgressStatuses()[0],
            reduivy__Enrollment_Date__c = System.today(),
            reduivy__Study_Unit__c = studyUnit.Id,
            reduivy__Individual_Academic_Profile__c = studentIpfs[0].Id
        );

        Test.startTest();
        
        System.runAs(FACULTY_USER) {
            insert ien;
        }

        // Verify EFTSL was set on insert
        ien = [
            SELECT Id, 
            reduivy__EFTSL__c, 
            reduivy__Study_Offering__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE Id = :ien.Id
        ];

        System.Assert.isNotNull(ien.reduivy__EFTSL__c, 
            'EFTSL should be set on insert');
        System.Assert.areEqual(studyUnit.reduivy__Default_EFTSL__c, ien.reduivy__EFTSL__c,
            'EFTSL should match study unit default EFTSL');
        System.Assert.areEqual(sofList[0].Id, ien.reduivy__Study_Offering__c,
            'IEN should be linked to first SOF');

        Decimal originalEftsl = ien.reduivy__EFTSL__c;

        // Clear EFTSL and change to SECOND SOF (same study unit)
        ien.reduivy__EFTSL__c = null;
        studyUnit.reduivy__Default_EFTSL__c = 50;

        REDU_TriggerController.muteTriggers(new Set<String>{'IEN_PopulateEftsl_EXE'});
        update ien;
        update studyUnit;
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IEN_PopulateEftsl_EXE'});

        studyUnit = [
            SELECT Id, reduivy__Default_EFTSL__c 
            FROM reduivy__Study_Unit__c 
            WHERE Id = :studyUnit.Id
            LIMIT 1
        ];

        System.Assert.areEqual(50, studyUnit.reduivy__Default_EFTSL__c,
            'Default EFTSL should be updated to 50');
        
        ien.reduivy__Study_Offering__c = sofList[1].Id;

        System.runAs(FACULTY_USER) {
            update ien;
        }

        Test.stopTest();

        // Verify EFTSL was recalculated even though study unit is the same
        ien = [
            SELECT Id, 
            reduivy__EFTSL__c, 
            reduivy__Study_Offering__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE Id = :ien.Id
        ];

        System.Assert.isNotNull(ien.reduivy__EFTSL__c,
            'EFTSL should be recalculated after SOF change');
        System.Assert.areEqual(studyUnit.reduivy__Default_EFTSL__c, ien.reduivy__EFTSL__c,
            'EFTSL should still match study unit default EFTSL');
        System.Assert.areEqual(sofList[1].Id, ien.reduivy__Study_Offering__c,
            'IEN should now be linked to second SOF');
        System.Assert.areEqual(studyUnit.Id, ien.reduivy__Target_Unit_Id__c,
            'Target Unit should remain the same');
        
        // EFTSL should not be the same value
        System.Assert.areNotEqual(originalEftsl, ien.reduivy__EFTSL__c,
            'EFTSL value should be same (same study unit) but recalculated');
    }

    /**
     * @description Test changing SOF to another SOF with the SAME study unit as student
     */
    @IsTest
    static void testEftslSofChangedToSameStudyUnitAsStudent() {

        // Get student
        List<Contact> studentContacts = [
            SELECT Id 
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT 
            LIMIT 1
        ];

        User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :studentContacts LIMIT 1
        ];
        
        System.Assert.isFalse(studentContacts.isEmpty(), 'Should have at least one student contact');

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN :studentContacts LIMIT 1];

        // Get a study unit
        reduivy__Study_Unit__c studyUnit = [
            SELECT Id, reduivy__Default_EFTSL__c 
            FROM reduivy__Study_Unit__c 
            WHERE reduivy__Default_EFTSL__c != null
            LIMIT 1
        ];

        // Ensure study unit has EFTSL value
        if (studyUnit.reduivy__Default_EFTSL__c == null) {
            studyUnit.reduivy__Default_EFTSL__c = 0.125;
            update studyUnit;
        }

        // Get or create academic term
        reduivy__Study_Term__c academicTerm = [
            SELECT Id 
            FROM reduivy__Study_Term__c 
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId()
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        Id campusId = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1].Id;

        // Create TWO study offerings for the SAME study unit
        List<reduivy__Study_Offering__c> sofList = new List<reduivy__Study_Offering__c>();
        
        sofList.add(new reduivy__Study_Offering__c(
            Name = 'Test SOF 1 - Same Unit',
            reduivy__Study_Unit__c = studyUnit.Id,
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campusId,
            reduivy__Start_Date__c = System.today(),
            reduivy__End_Date__c = System.today().addDays(30),
            reduivy__Capacity__c = 20
        ));

        sofList.add(new reduivy__Study_Offering__c(
            Name = 'Test SOF 2 - Same Unit',
            reduivy__Study_Unit__c = studyUnit.Id,
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campusId,
            reduivy__Start_Date__c = System.today().addDays(1),
            reduivy__End_Date__c = System.today().addDays(31),
            reduivy__Capacity__c = 20
        ));

        insert sofList;

        System.Assert.areEqual(2, sofList.size(), 'Should have created 2 study offerings');

        // Create IEN with first SOF
        reduivy__Individual_Enrollment__c ien = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sofList[0].Id,
            RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Enrollment_Status__c = IEN_Helper.getInProgressStatuses()[0],
            reduivy__Enrollment_Date__c = System.today(),
            reduivy__Study_Unit__c = studyUnit.Id,
            reduivy__Individual_Academic_Profile__c = studentIpfs[0].Id
        );

        Test.startTest();
        
        System.runAs(studentUser) {
            insert ien;
        }

        // Verify EFTSL was set on insert
        ien = [
            SELECT Id, 
            reduivy__EFTSL__c, 
            reduivy__Study_Offering__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE Id = :ien.Id
        ];

        System.Assert.isNotNull(ien.reduivy__EFTSL__c, 
            'EFTSL should be set on insert');
        System.Assert.areEqual(studyUnit.reduivy__Default_EFTSL__c, ien.reduivy__EFTSL__c,
            'EFTSL should match study unit default EFTSL');
        System.Assert.areEqual(sofList[0].Id, ien.reduivy__Study_Offering__c,
            'IEN should be linked to first SOF');

        Decimal originalEftsl = ien.reduivy__EFTSL__c;

        // Clear EFTSL and change to SECOND SOF (same study unit)
        ien.reduivy__EFTSL__c = null;
        studyUnit.reduivy__Default_EFTSL__c = 50;

        REDU_TriggerController.muteTriggers(new Set<String>{'IEN_PopulateEftsl_EXE'});
        update ien;
        update studyUnit;
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IEN_PopulateEftsl_EXE'});

        studyUnit = [
            SELECT Id, reduivy__Default_EFTSL__c 
            FROM reduivy__Study_Unit__c 
            WHERE Id = :studyUnit.Id
            LIMIT 1
        ];

        System.Assert.areEqual(50, studyUnit.reduivy__Default_EFTSL__c,
            'Default EFTSL should be updated to 50');
        
        ien.reduivy__Study_Offering__c = sofList[1].Id;

        System.runAs(studentUser) {
            update ien;
        }

        Test.stopTest();

        // Verify EFTSL was recalculated even though study unit is the same
        ien = [
            SELECT Id, 
            reduivy__EFTSL__c, 
            reduivy__Study_Offering__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Default_EFTSL__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE Id = :ien.Id
        ];

        System.Assert.isNotNull(ien.reduivy__EFTSL__c,
            'EFTSL should be recalculated after SOF change');
        System.Assert.areEqual(studyUnit.reduivy__Default_EFTSL__c, ien.reduivy__EFTSL__c,
            'EFTSL should still match study unit default EFTSL');
        System.Assert.areEqual(sofList[1].Id, ien.reduivy__Study_Offering__c,
            'IEN should now be linked to second SOF');
        System.Assert.areEqual(studyUnit.Id, ien.reduivy__Target_Unit_Id__c,
            'Target Unit should remain the same');
        
        // EFTSL should not be the same value
        System.Assert.areNotEqual(originalEftsl, ien.reduivy__EFTSL__c,
            'EFTSL value should be same (same study unit) but recalculated');
    }
}