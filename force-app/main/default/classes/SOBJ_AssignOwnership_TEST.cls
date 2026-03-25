/**
 * @author      WDCi (dblack)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for SOBJ_AssignOwnership_EXE
 * @changehistory
 * ISS-001813 07-12-2023 dblack - new class
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@isTest
public inherited sharing class SOBJ_AssignOwnership_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final Integer BULK_QTY = 10;

    static final String STUDY_INTAKE = 'SYDNEY_BACBIS_NYINTAKE';

    /**
     * @description Academic term code
     */
    private static final String ACADEMIC_TERM_CODE = 'CYT1';

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

			testFactory.initMasterData(null);
			testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initStudentData(IAC_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test as an admin user that the expected ownerId is assigned to the individual program enrollment record
     */
    @isTest
    static void testIpeAssignOwnershipAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
        
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

        reduivy__Study_Intake__c sit = [
            SELECT  Id, reduivy__Study_Program__c, reduivy__Default_Study_Plan__c, reduivy__Default_Study_Pathway__c, 
                    reduivy__Academic_Term__c, reduivy__Campus__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Intake__c
            LIMIT 1
        ];

		System.runAs(ADMIN_USER) {

            // Create the individual program enrollment records
            for (Integer i = 0; i < BULK_QTY; i++) {

                String sampleRecordCode = null;
                Id contactId = studentUser.ContactId;
                Id studyProgramId = sit.reduivy__Study_Program__c;
                Id studyPlanId = sit.reduivy__Default_Study_Plan__c;
                Id studyIntakeId = null;
                Id startingTermId = null;
                Id studyPathwayId = null;
                Id defaultCampusId = null;
                String classYear = null;
                String classStanding = null;
                Boolean eligibleToEnroll = true;
                String enrollmentStatus = 'In Progress';
                Id idvAcademicProfileId = null;

                reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
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

            // Execute test
            Test.startTest();
            insert ipeList;
            Test.stopTest();
		}

        // Verify test results
        ipeList = [
            SELECT OwnerId FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                ADMIN_USER.Id,
                ipe.OwnerId,
                'The admin user should be the owner of the individual program enrollment records'
            );
        }		
    }
	
    /**
     * @description Test as an admin user that the expected ownerId is assigned to the individual plan structure record
     */
    @isTest
    static void testIpsAssignOwnershipAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        List<reduivy__Individual_Plan_Structure__c> ipsList = new List<reduivy__Individual_Plan_Structure__c>();
        
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

        reduivy__Study_Intake__c sit = [
            SELECT  Id, reduivy__Study_Program__c, reduivy__Default_Study_Plan__c, reduivy__Default_Study_Pathway__c, 
                    reduivy__Academic_Term__c, reduivy__Campus__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Intake__c
            LIMIT 1
        ];

		System.runAs(ADMIN_USER) {

            // Create the individual program enrollment records
            List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
            for (Integer i = 0; i < BULK_QTY; i++) {

                String sampleRecordCode = null;
                Id contactId = studentUser.ContactId;
                Id studyProgramId = sit.reduivy__Study_Program__c;
                Id studyPlanId = sit.reduivy__Default_Study_Plan__c;
                Id studyIntakeId = null;
                Id startingTermId = null;
                Id studyPathwayId = null;
                Id defaultCampusId = null;
                String classYear = null;
                String classStanding = null;
                Boolean eligibleToEnroll = true;
                String enrollmentStatus = 'In Progress';
                Id idvAcademicProfileId = null;

                reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
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

            // Create the individual plan structure records
            for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
                for (Integer i = 0; i < BULK_QTY; i++) {

                    String sampleRecordCode = null;
                    Id individualProgramEnrollmentId = ipe.Id;
                    Id parentPlanStructureId = null;
                    Id unitStudyPlanStructureId = null;
                    Id individualPathwayId = null;
                    String category = null;
                    Decimal credits = null;
                    Boolean isPrimary = true;
                    String status = null;

                    reduivy__Individual_Plan_Structure__c ips = REDU_TestData_UTIL.newIndividualUnitPlanStructure(
                        sampleRecordCode,
                        individualProgramEnrollmentId,
                        parentPlanStructureId,
                        unitStudyPlanStructureId,
                        category,
                        credits,
                        isPrimary,
                        status
                    );

                    ipsList.add(ips);
                }
            }

            // Execute test
            Test.startTest();
            insert ipsList;
            Test.stopTest();
		}

        // Verify test results
        ipsList = [
            SELECT OwnerId 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure records'
        );

        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            System.Assert.areEqual(
                ADMIN_USER.Id,
                ips.OwnerId,
                'The admin user should be the owner of the individual plan structure records'
            );
        }		
    }

    /**
     * @description Test as an admin user that the expected ownerId is assigned to the individual enrollment record
     */
    @isTest
    static void testIenAssignOwnershipAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        
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

        reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c();
        ipf.reduivy__Contact__c = studentContacts[0].Id;
        ipf.reduivy__Academic_Level__c = 'Masters';
        ipf.reduivy__Status__c = 'Active';

        insert ipf;

		System.runAs(ADMIN_USER) {

            // Create the individual enrollment records
            for (Integer i = 0; i < BULK_QTY; i++) {

                String sampleRecordCode = null;
                Id contactId = studentUser.ContactId;
                Id studyOfferingId = null;
                String enrollmentStatus = null;
                Decimal attemptNumber = null;
                Date enrollmentDate = null;
                Date startDate = null;
                Date endDate = null;
                Date censusDate = null;
                Decimal creditsOffered = null;
                Id idvAcademicProgressId = null;
                Id idvAcademicProfileId = ipf.Id;

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

            // Execute test
            Test.startTest();
            insert ienList;
            Test.stopTest();
		}

        // Verify test results
        ienList = [
            SELECT OwnerId FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.areEqual(
                ADMIN_USER.Id,
                ien.OwnerId,
                'The admin user should be the owner of the individual enrollment records'
            );
        }		
    }

    /**
     * @description Test as an admin user that the expected ownerId is assigned to the individual academic profile record
     */
    @isTest
    static void testIpfAssignOwnershipAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();
        
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

		System.runAs(ADMIN_USER) {

            // Create the individual academic profile records
            for (Integer i = 0; i < BULK_QTY; i++) {

                reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c();
                ipf.reduivy__Contact__c = studentUser.ContactId;
                ipf.reduivy__Academic_Level__c = 'Masters';
                ipf.reduivy__Status__c = 'Active';

                ipfList.add(ipf);
            }

            // Execute test
            Test.startTest();
            insert ipfList;
            Test.stopTest();
		}

        // Verify test results
        ipfList = [
            SELECT OwnerId FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ipfList.isEmpty(),
            'The list should contain individual academic profile records'
        );

        for (reduivy__Individual_Academic_Profile__c ipf : ipfList) {

            System.Assert.areEqual(
                ADMIN_USER.Id,
                ipf.OwnerId,
                'The admin user should be the owner of the individual academic profile records'
            );
        }		
    }

    /**
     * @description Test as an admin user that the expected ownerId is assigned to the individual academic progress record
     */
    @isTest
    static void testIprAssignOwnershipAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        List<reduivy__Individual_Academic_Progress__c> iprList = new List<reduivy__Individual_Academic_Progress__c>();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		System.runAs(ADMIN_USER) {

            // Create the individual academic profile records
            List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();
            for (Contact contact : studentContacts) {

                reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c();
                ipf.reduivy__Contact__c = contact.Id;
                ipf.reduivy__Academic_Level__c = 'Masters';
                ipf.reduivy__Status__c = 'Active';

                ipfList.add(ipf);
            }

            insert ipfList;

            //Get academic term
            reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Sample_Record_Code__c = :ACADEMIC_TERM_CODE];

            // Create the individual academic progress records
            for (reduivy__Individual_Academic_Profile__c ipf : ipfList) {
                reduivy__Individual_Academic_Progress__c ipr = new reduivy__Individual_Academic_Progress__c();
                ipr.reduivy__Contact__c = ipf.reduivy__Contact__c;
                ipr.reduivy__Individual_Academic_Profile__c = ipf.Id;
                ipr.reduivy__Academic_Term__c = academicTerm.Id;

                iprList.add(ipr);
            }

            // Execute test
            Test.startTest();
            insert iprList;
            Test.stopTest();
		}

        // Verify test results
        iprList = [
            SELECT OwnerId FROM reduivy__Individual_Academic_Progress__c WHERE reduivy__Contact__c IN: studentContacts
        ];

        System.Assert.isFalse(
            iprList.isEmpty(),
            'The list should contain individual academic progress records'
        );

        for (reduivy__Individual_Academic_Progress__c ipr : iprList) {

            System.Assert.areEqual(
                ADMIN_USER.Id,
                ipr.OwnerId,
                'The admin user should be the owner of the individual academic progress records'
            );
        }
    }

    /**
     * @description Test as a faculty user that the expected ownerId is assigned to the individual program enrollment record
     */
    @isTest
    static void testIpeAssignOwnershipAsFaculty() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
        
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

        reduivy__Study_Intake__c sit = [
            SELECT  Id, reduivy__Study_Program__c, reduivy__Default_Study_Plan__c, reduivy__Default_Study_Pathway__c, 
                    reduivy__Academic_Term__c, reduivy__Campus__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Intake__c
            LIMIT 1
        ];

		System.runAs(FACULTY_USER) {

            // Create the individual program enrollment records
            for (Integer i = 0; i < BULK_QTY; i++) {

                String sampleRecordCode = null;
                Id contactId = studentUser.ContactId;
                Id studyProgramId = sit.reduivy__Study_Program__c;
                Id studyPlanId = sit.reduivy__Default_Study_Plan__c;
                Id studyIntakeId = null;
                Id startingTermId = null;
                Id studyPathwayId = null;
                Id defaultCampusId = null;
                String classYear = null;
                String classStanding = null;
                Boolean eligibleToEnroll = true;
                String enrollmentStatus = IPE_Helper.getPreviewStatuses().get(0);
                Id idvAcademicProfileId = null;

                reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
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

            // Execute test
            Test.startTest();
            insert ipeList;
            Test.stopTest();
		}

        // Verify test results
        ipeList = [
            SELECT OwnerId FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain individual program enrollment records'
        );

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                FACULTY_USER.Id,
                ipe.OwnerId,
                'The faculty user should be the owner of the individual program enrollment records'
            );
        }		
    }
	
    /**
     * @description Test as a faculty user that the expected ownerId is assigned to the individual plan structure record
     */
    @isTest
    static void testIpsAssignOwnershipAsFaculty() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        List<reduivy__Individual_Plan_Structure__c> ipsList = new List<reduivy__Individual_Plan_Structure__c>();
        
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

        reduivy__Study_Intake__c sit = [
            SELECT  Id, reduivy__Study_Program__c, reduivy__Default_Study_Plan__c, reduivy__Default_Study_Pathway__c, 
                    reduivy__Academic_Term__c, reduivy__Campus__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Intake__c
            LIMIT 1
        ];

		System.runAs(FACULTY_USER) {

            // Create the individual program enrollment records
            List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
            for (Integer i = 0; i < BULK_QTY; i++) {

                String sampleRecordCode = null;
                Id contactId = studentUser.ContactId;
                Id studyProgramId = sit.reduivy__Study_Program__c;
                Id studyPlanId = sit.reduivy__Default_Study_Plan__c;
                Id studyIntakeId = null;
                Id startingTermId = null;
                Id studyPathwayId = null;
                Id defaultCampusId = null;
                String classYear = null;
                String classStanding = null;
                Boolean eligibleToEnroll = true;
                String enrollmentStatus = IPE_Helper.getPreviewStatuses().get(0);
                Id idvAcademicProfileId = null;

                reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
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

            // Create the individual plan structure records
            for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
                for (Integer i = 0; i < BULK_QTY; i++) {

                    String sampleRecordCode = null;
                    Id individualProgramEnrollmentId = ipe.Id;
                    Id parentPlanStructureId = null;
                    Id unitStudyPlanStructureId = null;
                    Id individualPathwayId = null;
                    String category = null;
                    Decimal credits = null;
                    Boolean isPrimary = true;
                    String status = null;

                    reduivy__Individual_Plan_Structure__c ips = REDU_TestData_UTIL.newIndividualUnitPlanStructure(
                        sampleRecordCode,
                        individualProgramEnrollmentId,
                        parentPlanStructureId,
                        unitStudyPlanStructureId,
                        category,
                        credits,
                        isPrimary,
                        status
                    );

                    ipsList.add(ips);
                }
            }

            // Execute test
            Test.startTest();
            insert ipsList;
            Test.stopTest();
		}

        // Verify test results
        ipsList = [
            SELECT OwnerId 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure records'
        );

        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            System.Assert.areEqual(
                FACULTY_USER.Id,
                ips.OwnerId,
                'The faculty user should be the owner of the individual plan structure records'
            );
        }		
    }

    /**
     * @description Test as a faculty user that the expected ownerId is assigned to the individual enrollment record
     */
    @isTest
    static void testIenAssignOwnershipAsFaculty() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
		
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

        reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c();
        ipf.reduivy__Contact__c = studentContacts[0].Id;
        ipf.reduivy__Academic_Level__c = 'Masters';
        ipf.reduivy__Status__c = 'Active';

        insert ipf;

        System.runAs(FACULTY_USER) {

            // Create the individual enrollment records
            for (Integer i = 0; i < BULK_QTY; i++) {

                String sampleRecordCode = null;
                Id contactId = studentUser.ContactId;
                Id studyOfferingId = null;
                String enrollmentStatus = null;
                Decimal attemptNumber = null;
                Date enrollmentDate = null;
                Date startDate = null;
                Date endDate = null;
                Date censusDate = null;
                Decimal creditsOffered = null;
                Id idvAcademicProgressId = null;
                Id idvAcademicProfileId = ipf.Id;

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

            // Execute test
            Test.startTest();
            insert ienList;
            Test.stopTest();
		}

        // Verify test results
        ienList = [
            SELECT OwnerId FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.areEqual(
                FACULTY_USER.Id,
                ien.OwnerId,
                'The faculty user should be the owner of the individual enrollment records'
            );
        }		
    }

    /**
     * @description Test as a faculty user that the expected ownerId is assigned to the individual academic profile record
     */
    @isTest
    static void testIpfAssignOwnershipAsFaculty() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();
        
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

		System.runAs(FACULTY_USER) {

            // Create the individual academic profile records
            for (Integer i = 0; i < BULK_QTY; i++) {

                reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c();
                ipf.reduivy__Contact__c = studentUser.ContactId;
                ipf.reduivy__Academic_Level__c = 'Masters';
                ipf.reduivy__Status__c = 'Active';

                ipfList.add(ipf);
            }

            // Execute test
            Test.startTest();
            insert ipfList;
            Test.stopTest();
		}

        // Verify test results
        ipfList = [
            SELECT OwnerId FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ipfList.isEmpty(),
            'The list should contain individual academic profile records'
        );

        for (reduivy__Individual_Academic_Profile__c ipf : ipfList) {

            System.Assert.areEqual(
                FACULTY_USER.Id,
                ipf.OwnerId,
                'The faculty user should be the owner of the individual academic profile records'
            );
        }		
    }

    /**
     * @description Test as a faculty user that the expected ownerId is assigned to the individual academic progress record
     */
    @isTest
    static void testIprAssignOwnershipAsFaculty() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        List<reduivy__Individual_Academic_Progress__c> iprList = new List<reduivy__Individual_Academic_Progress__c>();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		System.runAs(FACULTY_USER) {

            // Create the individual academic profile records
            List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();
            for (Contact contact : studentContacts) {

                reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c();
                ipf.reduivy__Contact__c = contact.Id;
                ipf.reduivy__Academic_Level__c = 'Masters';
                ipf.reduivy__Status__c = 'Active';

                ipfList.add(ipf);
            }

            insert ipfList;

            //Get academic term
            reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Sample_Record_Code__c = :ACADEMIC_TERM_CODE];

            // Create the individual academic progress records
            for (reduivy__Individual_Academic_Profile__c ipf : ipfList) {
                reduivy__Individual_Academic_Progress__c ipr = new reduivy__Individual_Academic_Progress__c();
                ipr.reduivy__Contact__c = ipf.reduivy__Contact__c;
                ipr.reduivy__Individual_Academic_Profile__c = ipf.Id;
                ipr.reduivy__Academic_Term__c = academicTerm.Id;

                iprList.add(ipr);
            }

            // Execute test
            Test.startTest();
            insert iprList;
            Test.stopTest();
		}

        // Verify test results
        iprList = [
            SELECT OwnerId FROM reduivy__Individual_Academic_Progress__c WHERE reduivy__Contact__c IN: studentContacts
        ];

        System.Assert.isFalse(
            iprList.isEmpty(),
            'The list should contain individual academic progress records'
        );

        for (reduivy__Individual_Academic_Progress__c ipr : iprList) {

            System.Assert.areEqual(
                FACULTY_USER.Id,
                ipr.OwnerId,
                'The admin user should be the owner of the individual academic progress records'
            );
        }	
    }

    /**
     * @description Test as a student user that the expected ownerId is assigned to the individual program enrollment record
     */
    @isTest
    static void testIpeAssignOwnershipAsStudent() {

        // Setup test data

        List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();

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

        reduivy__Study_Intake__c sit = [
            SELECT  Id, reduivy__Study_Program__c, reduivy__Default_Study_Plan__c, reduivy__Default_Study_Pathway__c, 
                    reduivy__Academic_Term__c, reduivy__Campus__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Intake__c
            LIMIT 1
        ];

        System.runAs(studentUser) {

            // Create the individual program enrollment records
            for (Integer i = 0; i < BULK_QTY; i++) {

                String sampleRecordCode = null;
                Id contactId = studentUser.ContactId;
                Id studyProgramId = sit.reduivy__Study_Program__c;
                Id studyPlanId = sit.reduivy__Default_Study_Plan__c;
                Id studyIntakeId = null;
                Id startingTermId = null;
                Id studyPathwayId = null;
                Id defaultCampusId = null;
                String classYear = null;
                String classStanding = null;
                Boolean eligibleToEnroll = true;
                String enrollmentStatus = IPE_Helper.getPreviewStatuses().get(0);
                Id idvAcademicProfileId = null;

                reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
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

            // Execute test
            Test.startTest();
            insert ipeList;
            Test.stopTest();
		}

        // Verify test results
        ipeList = [
            SELECT OwnerId FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ipeList.isEmpty(),
            'The list should contain individual program enrollment records'
        );

        Id defaultOwnerId = REDU_AppSetting_UTIL.getDefaultOwnerId();

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

            System.Assert.areEqual(
                defaultOwnerId,
                ipe.OwnerId,
                'The default owner should be the owner of the individual program enrollment records'
            );
        }
    }

    /**
     * @description Test as a student user that the expected ownerId is assigned to the individual plan structure record
     */
    @isTest
    static void testIpsAssignOwnershipAsStudent() {

        // Setup test data

        List<reduivy__Individual_Plan_Structure__c> ipsList = new List<reduivy__Individual_Plan_Structure__c>();

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

        reduivy__Study_Intake__c sit = [
            SELECT  Id, reduivy__Study_Program__c, reduivy__Default_Study_Plan__c, reduivy__Default_Study_Pathway__c, 
                    reduivy__Academic_Term__c, reduivy__Campus__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Intake__c
            LIMIT 1
        ];

        System.runAs(studentUser) {

            // Create the individual program enrollment records
            List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
            for (Integer i = 0; i < BULK_QTY; i++) {

                String sampleRecordCode = null;
                Id contactId = studentUser.ContactId;
                Id studyProgramId = sit.reduivy__Study_Program__c;
                Id studyPlanId = sit.reduivy__Default_Study_Plan__c;
                Id studyIntakeId = null;
                Id startingTermId = null;
                Id studyPathwayId = null;
                Id defaultCampusId = null;
                String classYear = null;
                String classStanding = null;
                Boolean eligibleToEnroll = true;
                String enrollmentStatus = IPE_Helper.getPreviewStatuses().get(0);
                Id idvAcademicProfileId = null;

                reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
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

            // Create the individual plan structure records
            for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
                for (Integer i = 0; i < BULK_QTY; i++) {

                    String sampleRecordCode = null;
                    Id individualProgramEnrollmentId = ipe.Id;
                    Id parentPlanStructureId = null;
                    Id unitStudyPlanStructureId = null;
                    Id individualPathwayId = null;
                    String category = null;
                    Decimal credits = null;
                    Boolean isPrimary = true;
                    String status = null;

                    reduivy__Individual_Plan_Structure__c ips = REDU_TestData_UTIL.newIndividualUnitPlanStructure(
                        sampleRecordCode,
                        individualProgramEnrollmentId,
                        parentPlanStructureId,
                        unitStudyPlanStructureId,
                        category,
                        credits,
                        isPrimary,
                        status
                    );

                    ipsList.add(ips);
                }
            }

            // Execute test
            Test.startTest();
            insert ipsList;
            Test.stopTest();
		}

        // Verify test results
        ipsList = [
            SELECT OwnerId
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ipsList.isEmpty(),
            'The list should contain individual plan structure records'
        );

        Id defaultOwnerId = REDU_AppSetting_UTIL.getDefaultOwnerId();

        for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

            System.Assert.areEqual(
                defaultOwnerId,
                ips.OwnerId,
                'The default owner should be the owner of the individual plan structure records'
            );
        }
    }

    /**
     * @description Test as a student user that the expected ownerId is assigned to the individual enrollment record
     */
    @isTest
    static void testIenAssignOwnershipAsStudent() {

        // Setup test data

        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

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

        reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c();
        ipf.reduivy__Contact__c = studentContacts[0].Id;
        ipf.reduivy__Academic_Level__c = 'Masters';
        ipf.reduivy__Status__c = 'Active';

        insert ipf;

        System.runAs(studentUser) {

            // Create the individual enrollment records
            for (Integer i = 0; i < BULK_QTY; i++) {

                String sampleRecordCode = null;
                Id contactId = studentUser.ContactId;
                Id studyOfferingId = null;
                String enrollmentStatus = null;
                Decimal attemptNumber = null;
                Date enrollmentDate = null;
                Date startDate = null;
                Date endDate = null;
                Date censusDate = null;
                Decimal creditsOffered = null;
                Id idvAcademicProgressId = null;
                Id idvAcademicProfileId = ipf.Id;

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

            // Execute test
            Test.startTest();
            insert ienList;
            Test.stopTest();
		}

        // Verify test results
        ienList = [
            SELECT OwnerId FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        Id defaultOwnerId = REDU_AppSetting_UTIL.getDefaultOwnerId();

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.areEqual(
                defaultOwnerId,
                ien.OwnerId,
                'The default owner should be the owner of the individual enrollment records'
            );
        }
    }

    /**
     * @description Test as a student user that the expected ownerId is assigned to the individual academic profile record
     */
    @isTest
    static void testIpfAssignOwnershipAsStudent() {

        // Setup test data

        List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();

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

            // Create the individual academic profile records
            for (Integer i = 0; i < BULK_QTY; i++) {

                reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c();
                ipf.reduivy__Contact__c = studentUser.ContactId;
                ipf.reduivy__Academic_Level__c = 'Masters';
                ipf.reduivy__Status__c = 'Active';

                ipfList.add(ipf);
            }

            // Execute test
            Test.startTest();
            insert ipfList;
            Test.stopTest();
		}

        // Verify test results
        ipfList = [
            SELECT OwnerId FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            ipfList.isEmpty(),
            'The list should contain individual academic profile records'
        );

        Id defaultOwnerId = REDU_AppSetting_UTIL.getDefaultOwnerId();

        for (reduivy__Individual_Academic_Profile__c ipf : ipfList) {

            System.Assert.areEqual(
                defaultOwnerId,
                ipf.OwnerId,
                'The default owner should be the owner of the individual academic profile records'
            );
        }
    }

    /**
     * @description Test as a student user that the expected ownerId is assigned to the individual academic progress record
     */
    @isTest
    static void testIprAssignOwnershipAsStudent() {

        // Setup test data

        List<reduivy__Individual_Academic_Progress__c> iprList = new List<reduivy__Individual_Academic_Progress__c>();

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

            // Create the individual academic profile records
            List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();
            reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c();
            ipf.reduivy__Contact__c = studentUser.ContactId;
            ipf.reduivy__Academic_Level__c = 'Masters';
            ipf.reduivy__Status__c = 'Active';

            ipfList.add(ipf);

            insert ipfList;

            //Get academic term
            reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Sample_Record_Code__c = :ACADEMIC_TERM_CODE];

            // Create the individual academic progress records
            for (reduivy__Individual_Academic_Profile__c ipf2 : ipfList) {
                reduivy__Individual_Academic_Progress__c ipr = new reduivy__Individual_Academic_Progress__c();
                ipr.reduivy__Contact__c = ipf2.reduivy__Contact__c;
                ipr.reduivy__Individual_Academic_Profile__c = ipf2.Id;
                ipr.reduivy__Academic_Term__c = academicTerm.Id;

                iprList.add(ipr);
            }

            // Execute test
            Test.startTest();
            insert iprList;
            Test.stopTest();
		}

        // Verify test results
        iprList = [
            SELECT OwnerId FROM reduivy__Individual_Academic_Progress__c WHERE reduivy__Contact__c = :studentUser.ContactId
        ];

        System.Assert.isFalse(
            iprList.isEmpty(),
            'The list should contain individual academic progress records'
        );

        Id defaultOwnerId = REDU_AppSetting_UTIL.getDefaultOwnerId();

        for (reduivy__Individual_Academic_Progress__c ipr : iprList) {

            System.Assert.areEqual(
                defaultOwnerId,
                ipr.OwnerId,
                'The default owner should be the owner of the individual academic progress records'
            );
        }
    }
}