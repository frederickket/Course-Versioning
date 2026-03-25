/**
 * @author      WDCi (dblack)
 * @date        Jan 2024
 * @group       Test
 * @description Test class for IGI_ParentGradeRollup_EXE
 * @changehistory
 * ISS-001827 12-01-2024 dblack - new class
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@IsTest
public inherited sharing class IGI_ParentGradeRollup_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final Integer IGI_PARENT_QTY = 2;
    static final Integer IGI_CHILD_QTY = 2;

    static final Decimal GRADE_WEIGHT = 50;
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
                        reduivy__Study_Grade_Period_Setting__c = sgp.Id
                    );

                    igdList.add(igd);
                }
            }
            
            insert igdList;

            // Create the parent individual grade item records
            List<reduivy__Individual_Grade_Item__c> igiList = new List<reduivy__Individual_Grade_Item__c>();
            for (reduivy__Individual_Enrollment_Grade__c igd : igdList) {
                for (Integer i = 0; i < IGI_PARENT_QTY; i++) {
                    reduivy__Individual_Grade_Item__c igi = new reduivy__Individual_Grade_Item__c(
                        reduivy__Individual_Enrollment_Grade__c = igd.Id,
                        reduivy__Parent_Grade_Item__c = null,
                        reduivy__Weight__c = GRADE_WEIGHT
                    );

                    igiList.add(igi);
                }
            }

            insert igiList;

            Test.stopTest();
        }
    }

    /**
     * @description Test as an admin user that the insert of child individual grade item records rolls up to the parent individual grade item record
     */
    @IsTest
    static void testIgiChildRollUpToIgiParentAfterInsertAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        // Get the students
        List<Contact> studentContacts = [SELECT Id 
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
        ];

        // Get the parent individual grade item records
        List<reduivy__Individual_Grade_Item__c> igiParentList = [
            SELECT Id, reduivy__Individual_Enrollment_Grade__c
            FROM reduivy__Individual_Grade_Item__c 
            WHERE reduivy__Individual_Enrollment_Grade__r.reduivy__Contact__c IN :studentContacts
        ];

        System.Assert.isFalse(
            igiParentList.isEmpty(),
            'The list should contain the individual grade item records'
        );


        // Create the child individual grade item records
        List<reduivy__Individual_Grade_Item__c> igiChildList = new List<reduivy__Individual_Grade_Item__c>();
        for (reduivy__Individual_Grade_Item__c igiParent : igiParentList) {
            for (Integer i = 0; i < IGI_CHILD_QTY; i++) {
                reduivy__Individual_Grade_Item__c igiChild = new reduivy__Individual_Grade_Item__c(
                    reduivy__Individual_Enrollment_Grade__c = igiParent.reduivy__Individual_Enrollment_Grade__c,
                    reduivy__Parent_Grade_Item__c = igiParent.Id,
                    reduivy__Numerical_Grade__c = GRADE_QTY,
                    reduivy__Numerical_Grade_Adjustment__c = 0,
                    reduivy__Weight__c = GRADE_WEIGHT
                );

                igiChildList.add(igiChild);
            }
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            insert igiChildList;
            Test.stopTest();
        }

        // Verify test results

        Set<Id> igiParentIdSet = new Set<Id>();
        for (reduivy__Individual_Grade_Item__c igiChild : igiChildList) {
            igiParentIdSet.add(igiChild.reduivy__Parent_Grade_Item__c);
        }
        
        igiParentList = [
            SELECT  reduivy__Numerical_Grade__c,
                    (SELECT reduivy__Weighted_Grade__c FROM Child_Grade_Items__r)
            FROM reduivy__Individual_Grade_Item__c
            WHERE Id IN :igiParentIdSet
        ];

        System.Assert.isFalse(
            igiParentList.isEmpty(),
            'The list should contain individual grade item records'
        );

        for (reduivy__Individual_Grade_Item__c igiParent : igiParentList) {

            System.Assert.isFalse(
                igiParent.Child_Grade_Items__r.isEmpty(),
                'The list should contain individual grade item records'
            );

            Decimal expectedValue = 0;
            for (reduivy__Individual_Grade_Item__c igiChild : igiParent.Child_Grade_Items__r) {

                System.Assert.areEqual(
                    GRADE_QTY * GRADE_WEIGHT / 100,
                    igiChild.reduivy__Weighted_Grade__c,
                    'The actual value should be as expected'
                );

                expectedValue += igiChild.reduivy__Weighted_Grade__c;
            }

            System.Assert.isTrue(
                expectedValue > 0,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedValue,
                igiParent.reduivy__Numerical_Grade__c,
                'The actual value should be as expected'
            );
        }
    }
	
    /**
     * @description Test as an admin user that that the update of child individual grade item records rolls up to the parent individual grade item record
     */
    @IsTest
    static void testIgiChildRollUpToIgiParentAfterUpdateAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        // Get the student
        // Get the students
        List<Contact> studentContacts = [SELECT Id 
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
        ];

        // Get the parent individual grade item records
        List<reduivy__Individual_Grade_Item__c> igiParentList = [
            SELECT Id, reduivy__Individual_Enrollment_Grade__c
            FROM reduivy__Individual_Grade_Item__c 
            WHERE reduivy__Individual_Enrollment_Grade__r.reduivy__Contact__c IN :studentContacts
        ];

        System.Assert.isFalse(
            igiParentList.isEmpty(),
            'The list should contain the individual grade item records'
        );


        // Create the child individual grade item records
        List<reduivy__Individual_Grade_Item__c> igiChildList = new List<reduivy__Individual_Grade_Item__c>();
        for (reduivy__Individual_Grade_Item__c igiParent : igiParentList) {
            for (Integer i = 0; i < IGI_CHILD_QTY; i++) {
                reduivy__Individual_Grade_Item__c igiChild = new reduivy__Individual_Grade_Item__c(
                    reduivy__Individual_Enrollment_Grade__c = igiParent.reduivy__Individual_Enrollment_Grade__c,
                    reduivy__Parent_Grade_Item__c = igiParent.Id,
                    reduivy__Numerical_Grade__c = GRADE_QTY,
                    reduivy__Numerical_Grade_Adjustment__c = 0,
                    reduivy__Weight__c = GRADE_WEIGHT
                );

                igiChildList.add(igiChild);
            }
        }

        insert igiChildList;

        // Update the child individual grade items
        for (reduivy__Individual_Grade_Item__c igiChild : igiChildList) {
            igiChild.reduivy__Numerical_Grade__c += GRADE_QTY;
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            Test.startTest();
            update igiChildList;
            Test.stopTest();
        }

        // Verify test results

        Set<Id> igiParentIdSet = new Set<Id>();
        for (reduivy__Individual_Grade_Item__c igiChild : igiChildList) {
            igiParentIdSet.add(igiChild.reduivy__Parent_Grade_Item__c);
        }

        igiParentList = [
            SELECT  reduivy__Numerical_Grade__c,
                    (SELECT reduivy__Weighted_Grade__c FROM Child_Grade_Items__r)
            FROM reduivy__Individual_Grade_Item__c
            WHERE Id IN :igiParentIdSet
        ];

        System.Assert.isFalse(
            igiParentList.isEmpty(),
            'The list should contain individual grade item records'
        );

        for (reduivy__Individual_Grade_Item__c igiParent : igiParentList) {

            System.Assert.isFalse(
                igiParent.Child_Grade_Items__r.isEmpty(),
                'The list should contain individual grade item records'
            );

            Decimal expectedValue = 0;
            for (reduivy__Individual_Grade_Item__c igiChild : igiParent.Child_Grade_Items__r) {

                System.Assert.areEqual(
                    (GRADE_QTY + GRADE_QTY) * GRADE_WEIGHT / 100,
                    igiChild.reduivy__Weighted_Grade__c,
                    'The actual value should be as expected'
                );

                expectedValue += igiChild.reduivy__Weighted_Grade__c;
            }

            System.Assert.isTrue(
                expectedValue > 0,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedValue,
                igiParent.reduivy__Numerical_Grade__c,
                'The actual value should be as expected'
            );
        }
    }

    /**
     * @description Test as a faculty user that the insert of child individual grade item records rolls up to the parent individual grade item record
     */
    @IsTest
    static void testIgiChildRollUpToIgiParentAfterInsertAsFaculty() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Get the student
        // Get the students
        List<Contact> studentContacts = [SELECT Id 
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
        ];

        // Get the parent individual grade item records
        List<reduivy__Individual_Grade_Item__c> igiParentList = [
            SELECT Id, reduivy__Individual_Enrollment_Grade__c
            FROM reduivy__Individual_Grade_Item__c 
            WHERE reduivy__Individual_Enrollment_Grade__r.reduivy__Contact__c IN :studentContacts
        ];

        System.Assert.isFalse(
            igiParentList.isEmpty(),
            'The list should contain the individual grade item records'
        );


        // Create the child individual grade item records
        List<reduivy__Individual_Grade_Item__c> igiChildList = new List<reduivy__Individual_Grade_Item__c>();
        for (reduivy__Individual_Grade_Item__c igiParent : igiParentList) {
            for (Integer i = 0; i < IGI_CHILD_QTY; i++) {
                reduivy__Individual_Grade_Item__c igiChild = new reduivy__Individual_Grade_Item__c(
                    reduivy__Individual_Enrollment_Grade__c = igiParent.reduivy__Individual_Enrollment_Grade__c,
                    reduivy__Parent_Grade_Item__c = igiParent.Id,
                    reduivy__Numerical_Grade__c = GRADE_QTY,
                    reduivy__Numerical_Grade_Adjustment__c = 0,
                    reduivy__Weight__c = GRADE_WEIGHT
                );

                igiChildList.add(igiChild);
            }
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            insert igiChildList;
            Test.stopTest();
        }

        // Verify test results

        Set<Id> igiParentIdSet = new Set<Id>();
        for (reduivy__Individual_Grade_Item__c igiChild : igiChildList) {
            igiParentIdSet.add(igiChild.reduivy__Parent_Grade_Item__c);
        }

        igiParentList = [
            SELECT  reduivy__Numerical_Grade__c,
                    (select reduivy__Weighted_Grade__c from Child_Grade_Items__r)
            FROM reduivy__Individual_Grade_Item__c
            WHERE Id IN :igiParentIdSet
        ];

        System.Assert.isFalse(
            igiParentList.isEmpty(),
            'The list should contain individual grade item records'
        );

        for (reduivy__Individual_Grade_Item__c igiParent : igiParentList) {

            System.Assert.isFalse(
                igiParent.Child_Grade_Items__r.isEmpty(),
                'The list should contain individual grade item records'
            );

            Decimal expectedValue = 0;
            for (reduivy__Individual_Grade_Item__c igiChild : igiParent.Child_Grade_Items__r) {

                System.Assert.areEqual(
                    GRADE_QTY * GRADE_WEIGHT / 100,
                    igiChild.reduivy__Weighted_Grade__c,
                    'The actual value should be as expected'
                );

                expectedValue += igiChild.reduivy__Weighted_Grade__c;
            }

            System.Assert.isTrue(
                expectedValue > 0,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedValue,
                igiParent.reduivy__Numerical_Grade__c,
                'The actual value should be as expected'
            );
        }
    }
	
    /**
     * @description Test as a faculty user that that the update of child individual grade item records rolls up to the parent individual grade item record
     */
    @IsTest
    static void testIgiChildRollUpToIgiParentAfterUpdateAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        // Get the students
        List<Contact> studentContacts = [SELECT Id 
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
        ];

        // Get the parent individual grade item records
        List<reduivy__Individual_Grade_Item__c> igiParentList = [
            SELECT Id, reduivy__Individual_Enrollment_Grade__c
            FROM reduivy__Individual_Grade_Item__c 
            WHERE reduivy__Individual_Enrollment_Grade__r.reduivy__Contact__c IN :studentContacts
        ];

        System.Assert.isFalse(
            igiParentList.isEmpty(),
            'The list should contain the individual grade item records'
        );


        // Create the child individual grade item records
        List<reduivy__Individual_Grade_Item__c> igiChildList = new List<reduivy__Individual_Grade_Item__c>();
        for (reduivy__Individual_Grade_Item__c igiParent : igiParentList) {
            for (Integer i = 0; i < IGI_CHILD_QTY; i++) {
                reduivy__Individual_Grade_Item__c igiChild = new reduivy__Individual_Grade_Item__c(
                    reduivy__Individual_Enrollment_Grade__c = igiParent.reduivy__Individual_Enrollment_Grade__c,
                    reduivy__Parent_Grade_Item__c = igiParent.Id,
                    reduivy__Numerical_Grade__c = GRADE_QTY,
                    reduivy__Numerical_Grade_Adjustment__c = 0,
                    reduivy__Weight__c = GRADE_WEIGHT
                );

                igiChildList.add(igiChild);
            }
        }

        insert igiChildList;

        // Update the child individual grade items
        for (reduivy__Individual_Grade_Item__c igiChild : igiChildList) {
            igiChild.reduivy__Numerical_Grade__c += GRADE_QTY;
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            Test.startTest();
            update igiChildList;
            Test.stopTest();
        }

        // Verify test results

        Set<Id> igiParentIdSet = new Set<Id>();
        for (reduivy__Individual_Grade_Item__c igiChild : igiChildList) {
            igiParentIdSet.add(igiChild.reduivy__Parent_Grade_Item__c);
        }

        igiParentList = [
            SELECT  reduivy__Numerical_Grade__c,
                    (select reduivy__Weighted_Grade__c from Child_Grade_Items__r)
            FROM reduivy__Individual_Grade_Item__c
            WHERE Id IN :igiParentIdSet
        ];

        System.Assert.isFalse(
            igiParentList.isEmpty(),
            'The list should contain individual grade item records'
        );

        for (reduivy__Individual_Grade_Item__c igiParent : igiParentList) {

            System.Assert.isFalse(
                igiParent.Child_Grade_Items__r.isEmpty(),
                'The list should contain individual grade item records'
            );

            Decimal expectedValue = 0;
            for (reduivy__Individual_Grade_Item__c igiChild : igiParent.Child_Grade_Items__r) {

                System.Assert.areEqual(
                    (GRADE_QTY + GRADE_QTY) * GRADE_WEIGHT / 100,
                    igiChild.reduivy__Weighted_Grade__c,
                    'The actual value should be as expected'
                );

                expectedValue += igiChild.reduivy__Weighted_Grade__c;
            }

            System.Assert.isTrue(
                expectedValue > 0,
                'The actual value should be as expected'
            );

            System.Assert.areEqual(
                expectedValue,
                igiParent.reduivy__Numerical_Grade__c,
                'The actual value should be as expected'
            );
        }
    }
}