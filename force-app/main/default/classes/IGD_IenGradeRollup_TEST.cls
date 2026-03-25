/**
 * @author      WDCi (dblack)
 * @date        Jan 2024
 * @group       Test
 * @description Test class for IGD_IenGradeRollup_EXE
 * @changehistory
 * ISS-001827 12-01-2024 dblack - new class
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@IsTest
public inherited sharing class IGD_IenGradeRollup_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final Integer IGD_QTY = 2;
    static final Decimal GRADE_QTY = 80;

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData() {
        
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(SUN_Helper.getApiName());
            testFactory.initOfferingData(SGP_Helper.getApiName());
            testFactory.initStudentData(IPR_Helper.getApiName(), false);

            // Get the students
            List<Contact> studentContacts = [SELECT Id 
                FROM Contact 
                WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            ];

            List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
            Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

            for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
                studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
            }

            // Create individual enrollment records
            List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
            for (Contact student : studentContacts) {

                String sampleRecordCode = null;
                Id contactId = student.Id;
                Id studyOfferingId = null;
                String enrollmentStatus = null;
                Decimal attemptNumber = null;
                Date enrollmentDate = null;
                Date startDate = null;
                Date endDate = null;
                Date censusDate = null;
                Decimal creditsOffered = null;
                Id idvAcademicProgressId = null;
                Id idvAcademicProfileId = studentToIPFMap.get(student.Id);

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

            Test.stopTest();
        }
    }

    /**
     * @description Test as an admin user that the insert of individual enrollment grade records rolls up to the individual enrollment record
     */
    @IsTest
    static void testIgdRollUpToIenAfterInsertAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        // Get the students
        List<Contact> studentContacts = [SELECT Id 
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
        ];

        // Get the individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c IN :studentContacts
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain the individual enrollment records'
        );

        // Create the individual enrollment grade records
        List<reduivy__Study_Grade_Period_Setting__c> sgpList = [SELECT Id 
            FROM reduivy__Study_Grade_Period_Setting__c 
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
        ];

        List<reduivy__Individual_Enrollment_Grade__c> igdList = new List<reduivy__Individual_Enrollment_Grade__c>();
        for (reduivy__Individual_Enrollment__c ien : ienList) {
            for (reduivy__Study_Grade_Period_Setting__c sgp : sgpList) {
                reduivy__Individual_Enrollment_Grade__c igd = new reduivy__Individual_Enrollment_Grade__c(
                    reduivy__Contact__c = ien.reduivy__Contact__c,
                    reduivy__Individual_Enrollment__c = ien.Id,
                    reduivy__Numerical_Grade__c = GRADE_QTY,
                    reduivy__Numerical_Grade_Adjustment__c = 0,
                    reduivy__Study_Grade_Period_Setting__c = sgp.Id
                );

                igdList.add(igd);
            }
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            insert igdList;
            Test.stopTest();
        }

        // Verify test results
        ienList = [
            SELECT  reduivy__Numerical_Grade__c,
                    (SELECT reduivy__Weighted_Grade__c, Study_Grade_Period_Setting__r.Weight__c FROM reduivy__Individual_Enrollment_Grades__r)
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN :studentContacts
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isFalse(
                ien.reduivy__Individual_Enrollment_Grades__r.isEmpty(),
                'The list should contain individual enrollment grade records'
            );

            Decimal expectedValue = 0;
            for (reduivy__Individual_Enrollment_Grade__c igd : ien.reduivy__Individual_Enrollment_Grades__r) {

                System.Assert.areEqual(
                    GRADE_QTY * igd.Study_Grade_Period_Setting__r.Weight__c / 100,
                    igd.reduivy__Weighted_Grade__c,
                    'The actual value should be as expected'
                );

                expectedValue += igd.reduivy__Weighted_Grade__c;
            }

            System.Assert.isTrue(
                expectedValue > 0,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedValue,
                ien.reduivy__Numerical_Grade__c,
                'The actual value should be as expected'
            );
        }
    }
	
    /**
     * @description Test as an admin user that the update of individual enrollment grade records rolls up to the individual enrollment record
     */
    @IsTest
    static void testIgdRollUpToIenAfterUpdateAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        // Get the students
        List<Contact> studentContacts = [SELECT Id 
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
        ];

        // Get the individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c IN :studentContacts
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain the individual enrollment records'
        );


        // Create the individual enrollment grade records
        List<reduivy__Study_Grade_Period_Setting__c> sgpList = [SELECT Id 
            FROM reduivy__Study_Grade_Period_Setting__c 
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
        ];

        List<reduivy__Individual_Enrollment_Grade__c> igdList = new List<reduivy__Individual_Enrollment_Grade__c>();
        for (reduivy__Individual_Enrollment__c ien : ienList) {
            for (reduivy__Study_Grade_Period_Setting__c sgp : sgpList) {
                reduivy__Individual_Enrollment_Grade__c igd = new reduivy__Individual_Enrollment_Grade__c(
                    reduivy__Contact__c = ien.reduivy__Contact__c,
                    reduivy__Individual_Enrollment__c = ien.Id,
                    reduivy__Numerical_Grade__c = GRADE_QTY,
                    reduivy__Numerical_Grade_Adjustment__c = 0,
                    reduivy__Study_Grade_Period_Setting__c = sgp.Id
                );

                igdList.add(igd);
            }
        }

        insert igdList;

        // Update the individual enrollment grades
        for (reduivy__Individual_Enrollment_Grade__c igd : igdList) {
            igd.reduivy__Numerical_Grade__c += GRADE_QTY;
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            update igdList;
            Test.stopTest();
        }

        // Verify test results
        ienList = [
            SELECT  reduivy__Numerical_Grade__c,
                    (SELECT reduivy__Weighted_Grade__c, Study_Grade_Period_Setting__r.Weight__c FROM reduivy__Individual_Enrollment_Grades__r)
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN :studentContacts
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isFalse(
                ien.reduivy__Individual_Enrollment_Grades__r.isEmpty(),
                'The list should contain individual enrollment grade records'
            );

            Decimal expectedValue = 0;
            for (reduivy__Individual_Enrollment_Grade__c igd : ien.reduivy__Individual_Enrollment_Grades__r) {

                System.Assert.areEqual(
                    (GRADE_QTY + GRADE_QTY) * igd.Study_Grade_Period_Setting__r.Weight__c / 100,
                    igd.reduivy__Weighted_Grade__c,
                    'The actual value should be as expected'
                );

                expectedValue += igd.reduivy__Weighted_Grade__c;
            }

            System.Assert.isTrue(
                expectedValue > 0,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedValue,
                ien.reduivy__Numerical_Grade__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a faculty user that the insert of individual enrollment grade records rolls up to the individual enrollment record
     */
    @IsTest
    static void testIgdRollUpToIenAfterInsertAsFaculty() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Get the students
        List<Contact> studentContacts = [SELECT Id 
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
        ];

        // Get the individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c IN :studentContacts
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain the individual enrollment records'
        );


        // Create the individual enrollment grade records
        List<reduivy__Study_Grade_Period_Setting__c> sgpList = [SELECT Id 
            FROM reduivy__Study_Grade_Period_Setting__c 
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
        ];

        List<reduivy__Individual_Enrollment_Grade__c> igdList = new List<reduivy__Individual_Enrollment_Grade__c>();
        for (reduivy__Individual_Enrollment__c ien : ienList) {
            for (reduivy__Study_Grade_Period_Setting__c sgp : sgpList) {
                reduivy__Individual_Enrollment_Grade__c igd = new reduivy__Individual_Enrollment_Grade__c(
                    reduivy__Contact__c = ien.reduivy__Contact__c,
                    reduivy__Individual_Enrollment__c = ien.Id,
                    reduivy__Numerical_Grade__c = GRADE_QTY,
                    reduivy__Numerical_Grade_Adjustment__c = 0,
                    reduivy__Study_Grade_Period_Setting__c = sgp.Id
                );

                igdList.add(igd);
            }
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            insert igdList;
            Test.stopTest();
        }

        // Verify test results
        ienList = [
            SELECT  reduivy__Numerical_Grade__c,
                    (SELECT reduivy__Weighted_Grade__c, Study_Grade_Period_Setting__r.Weight__c FROM reduivy__Individual_Enrollment_Grades__r)
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN :studentContacts
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isFalse(
                ien.reduivy__Individual_Enrollment_Grades__r.isEmpty(),
                'The list should contain individual enrollment grade records'
            );

            Decimal expectedValue = 0;
            for (reduivy__Individual_Enrollment_Grade__c igd : ien.reduivy__Individual_Enrollment_Grades__r) {

                System.Assert.areEqual(
                    GRADE_QTY * igd.Study_Grade_Period_Setting__r.Weight__c / 100,
                    igd.reduivy__Weighted_Grade__c,
                    'The actual value should be as expected'
                );

                expectedValue += igd.reduivy__Weighted_Grade__c;
            }

            System.Assert.isTrue(
                expectedValue > 0,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedValue,
                ien.reduivy__Numerical_Grade__c,
                'The actual value should be as expected'
            );
        }
    }
	
    /**
     * @description Test as a faculty user that the update of individual enrollment grade records rolls up to the individual enrollment record
     */
    @IsTest
    static void testIgdRollUpToIenAfterUpdateAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Get the students
        List<Contact> studentContacts = [SELECT Id 
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
        ];

        // Get the individual enrollment records
        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c IN :studentContacts
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain the individual enrollment records'
        );


        // Create the individual enrollment grade records
        List<reduivy__Study_Grade_Period_Setting__c> sgpList = [SELECT Id 
            FROM reduivy__Study_Grade_Period_Setting__c 
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
        ];

        List<reduivy__Individual_Enrollment_Grade__c> igdList = new List<reduivy__Individual_Enrollment_Grade__c>();
        for (reduivy__Individual_Enrollment__c ien : ienList) {
            for (reduivy__Study_Grade_Period_Setting__c sgp : sgpList) {
                reduivy__Individual_Enrollment_Grade__c igd = new reduivy__Individual_Enrollment_Grade__c(
                    reduivy__Contact__c = ien.reduivy__Contact__c,
                    reduivy__Individual_Enrollment__c = ien.Id,
                    reduivy__Numerical_Grade__c = GRADE_QTY,
                    reduivy__Numerical_Grade_Adjustment__c = 0,
                    reduivy__Study_Grade_Period_Setting__c = sgp.Id
                );

                igdList.add(igd);
            }
        }

        insert igdList;

        // Update the individual enrollment grades
        for (reduivy__Individual_Enrollment_Grade__c igd : igdList) {
            igd.reduivy__Numerical_Grade__c += GRADE_QTY;
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            update igdList;
            Test.stopTest();
        }

        // Verify test results
        ienList = [
            SELECT  reduivy__Numerical_Grade__c,
                    (SELECT reduivy__Weighted_Grade__c, Study_Grade_Period_Setting__r.Weight__c FROM reduivy__Individual_Enrollment_Grades__r)
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN :studentContacts
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            System.Assert.isFalse(
                ien.reduivy__Individual_Enrollment_Grades__r.isEmpty(),
                'The list should contain individual enrollment grade records'
            );

            Decimal expectedValue = 0;
            for (reduivy__Individual_Enrollment_Grade__c igd : ien.reduivy__Individual_Enrollment_Grades__r) {

                System.Assert.areEqual(
                    (GRADE_QTY + GRADE_QTY) * igd.Study_Grade_Period_Setting__r.Weight__c / 100,
                    igd.reduivy__Weighted_Grade__c,
                    'The actual value should be as expected'
                );

                expectedValue += igd.reduivy__Weighted_Grade__c;
            }

            System.Assert.isTrue(
                expectedValue > 0,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedValue,
                ien.reduivy__Numerical_Grade__c,
                'The actual value should be as expected'
            );
        }
    }
}