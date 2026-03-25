/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Test
 * @description Test class for IEN_BestAttempt_EXE
 * @changehistory
 * ISS-001822 16-01-2024 Lean - new class
 * ISS-002486 28-07-2025 XiRouh - Added a new test method to cover multiple IENs with different status and grade combinations
 * ISS-002743 15-12-2025 XiRouh - Added test methods to consider the IEN within the same Individual Academic Profile context and Updated test methods that create IENs to link them with IPF
 * ISS-002783 28-01-2026 Lean - updated test class to removed the assertion on Exclude GPA Calculation and Exclude Credits Earned flag
 */
@IsTest
public inherited sharing class IEN_BestAttempt_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);

    static final String IEN_COMPLETED_PASS_STATUS = IEN_Helper.getCompletedPassStatuses().get(0);

    static final String IEN_COMPLETED_FAIL_STATUS = IEN_Helper.getCompletedFailStatuses().get(0);

    /*
     * @description we mute some non related triggers to save the resources
     */
    static final Set<String> TRIGGERS_TO_MUTE = new Set<String>{
        'IEN_AcademicProgress_Before',
        'IEN_AcademicProgressRollup_After',
        'IEN_SetUnitIpsStatus_After',
        'IEN_ReassignIpsu_After',
        'IEN_ReassignIpsu_Before'
    };

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
			testFactory.initStudentData(USR_Helper.getApiName(), false);

            Test.stopTest();
		}
    }

    /**
     * @description Triggers to be muted for test
     */
    private static void muteTriggers() {

        REDU_TriggerController.muteTriggers(TRIGGERS_TO_MUTE);

    }

    /**
     * @description Triggers to be muted for test
     */
    private static void unmuteTriggers() {

        REDU_TriggerController.unmuteTriggers(TRIGGERS_TO_MUTE);
        
    }
	
    /**
     * @description Test as admin for new individual enrollment without grade released to ensure best attempt is not set
     */
    @IsTest
    static void testNewIenWithEnrolledStatusAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        muteTriggers();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();
        for (Contact contact : studentContacts) {

            reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c();
            ipf.reduivy__Contact__c = contact.Id;
            ipf.reduivy__Academic_Level__c = 'Masters';
            ipf.reduivy__Status__c = 'Active';

            ipfList.add(ipf);
        }

        insert ipfList;

        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : ipfList) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        Test.startTest();
		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 5
            ]) {
                for (Contact student : studentContacts) {
                    newIenList.add(
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today(),
                            null,
                            null,
                            null,
                            3,
                            null,
                            studentToIPFMap.get(student.Id),
                            true
                        )
                    );
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
		}
		
        // Check to ensure the best attempt is not set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Best_Attempt__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(false, ien.reduivy__Best_Attempt__c);
        }

        Test.stopTest();

    }

    /**
     * @description Test as admin for new individual enrollment with grade released using valid numerical grade to ensure best attempt is set
     */
    @IsTest
    static void testNewIenWithValidNumericalGradeAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        muteTriggers();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();
        for (Contact contact : studentContacts) {

            reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c();
            ipf.reduivy__Contact__c = contact.Id;
            ipf.reduivy__Academic_Level__c = 'Masters';
            ipf.reduivy__Status__c = 'Active';

            ipfList.add(ipf);
        }

        insert ipfList;

        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : ipfList) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
        List<reduivy__Individual_Enrollment__c> newAttemptIenList = new List<reduivy__Individual_Enrollment__c>();

        Test.startTest();
		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 5
            ]) {
                for (Contact student : studentContacts) {
                    // first attempt with lower grade
                    reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        studentToIPFMap.get(student.Id),
                        true
                    );

                    ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
                    ien.reduivy__Numerical_Grade__c = 90;

                    newIenList.add(ien);

                    // second ien with higher grade
                    reduivy__Individual_Enrollment__c ienNewAttempt = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        2,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        studentToIPFMap.get(student.Id),
                        true
                    );

                    ienNewAttempt.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
                    ienNewAttempt.reduivy__Numerical_Grade__c = 100;

                    newAttemptIenList.add(ienNewAttempt);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
            REDU_Database_UTIL.doInsert(newAttemptIenList);
		}
		
        Map<Id, reduivy__Individual_Enrollment__c> newIenMap = new Map<Id, reduivy__Individual_Enrollment__c>(newIenList);
        Map<Id, reduivy__Individual_Enrollment__c> newAttemptIenMap = new Map<Id, reduivy__Individual_Enrollment__c>(newAttemptIenList);

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Best_Attempt__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList AND Id IN: newAttemptIenList
        ]) {
            if (newIenMap.containsKey(ien.Id)) {
                // This should not have the best attempt
                System.Assert.areEqual(false, ien.reduivy__Best_Attempt__c);
            } else {
                // This should have the best attempt
                System.Assert.areEqual(true, ien.reduivy__Best_Attempt__c);
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for update individual enrollment with grade released and change of grade after release to ensure the best attempt is set correctly
     */
    @IsTest
    static void testUpdateIenWithNumericalGradeAndReleaseAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        muteTriggers();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();
        for (Contact contact : studentContacts) {

            reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c();
            ipf.reduivy__Contact__c = contact.Id;
            ipf.reduivy__Academic_Level__c = 'Masters';
            ipf.reduivy__Status__c = 'Active';

            ipfList.add(ipf);
        }

        insert ipfList;

        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : ipfList) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
        List<reduivy__Individual_Enrollment__c> newAttemptIenList = new List<reduivy__Individual_Enrollment__c>();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 5
            ]) {
                for (Contact student : studentContacts) {
                    //first attempt
                    reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        studentToIPFMap.get(student.Id),
                        true
                    );

                    newIenList.add(ien);

                    //second attempt
                    reduivy__Individual_Enrollment__c ienNewAttempt = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        2,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        studentToIPFMap.get(student.Id),
                        true
                    );

                    newAttemptIenList.add(ienNewAttempt);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
            REDU_Database_UTIL.doInsert(newAttemptIenList);
		}

        Map<Id, reduivy__Individual_Enrollment__c> newIenMap = new Map<Id, reduivy__Individual_Enrollment__c>(newIenList);
        Map<Id, reduivy__Individual_Enrollment__c> newAttemptIenMap = new Map<Id, reduivy__Individual_Enrollment__c>(newAttemptIenList);

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Best_Attempt__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList AND Id IN: newAttemptIenList
        ]) {
            if (newIenMap.containsKey(ien.Id)) {
                System.Assert.areEqual(false, ien.reduivy__Best_Attempt__c);
            } else {
                System.Assert.areEqual(false, ien.reduivy__Best_Attempt__c);
            }
        }

        // simulate the grade release for first attempt ien
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Numerical_Grade__c = 90;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Best_Attempt__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList AND Id IN: newAttemptIenList
        ]) {
            if (newIenMap.containsKey(ien.Id)) {
                // This should have the best attempt
                System.Assert.areEqual(true, ien.reduivy__Best_Attempt__c);
            } else {
                // This should not have the best attempt
                System.Assert.areEqual(false, ien.reduivy__Best_Attempt__c);
            }
        }

        //simulate the grade release for second attempt with higher grade
        for (reduivy__Individual_Enrollment__c ien : newAttemptIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Numerical_Grade__c = 91;
        }

        Test.startTest();

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newAttemptIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Best_Attempt__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList AND Id IN: newAttemptIenList
        ]) {
            if (newIenMap.containsKey(ien.Id)) {
                // This should not have the best attempt
                System.Assert.areEqual(false, ien.reduivy__Best_Attempt__c);
            } else {
                // This should have the best attempt
                System.Assert.areEqual(true, ien.reduivy__Best_Attempt__c);
            }
        }

        //simulate the update of second attempt with fail grade
        for (reduivy__Individual_Enrollment__c ien : newAttemptIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Numerical_Grade__c = 0;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newAttemptIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Best_Attempt__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList AND Id IN: newAttemptIenList
        ]) {
            if (newIenMap.containsKey(ien.Id)) {
                // This should have the best attempt
                System.Assert.areEqual(true, ien.reduivy__Best_Attempt__c);
            } else {
                // This should not have the best attempt
                System.Assert.areEqual(false, ien.reduivy__Best_Attempt__c);
            }
        }

        //simulate deletion
        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doDelete(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Best_Attempt__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList AND Id IN: newAttemptIenList
        ]) {
            if (newIenMap.containsKey(ien.Id)) {
                System.Assert.fail('This should have been deleted.');
            } else {
                // This should have the best attempt
                System.Assert.areEqual(true, ien.reduivy__Best_Attempt__c);
            }
        }

        //simulate undeletion
        System.runAs(ADMIN_USER) {
            Database.undelete(newIenList, AccessLevel.USER_MODE);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Best_Attempt__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList AND Id IN: newAttemptIenList
        ]) {
            if (newIenMap.containsKey(ien.Id)) {
                // This should have the best attempt
                System.Assert.areEqual(true, ien.reduivy__Best_Attempt__c);
            } else {
                // This should not have the best attempt
                System.Assert.areEqual(false, ien.reduivy__Best_Attempt__c);
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for new individual enrollment without grade released to ensure best attempt is not set
     */
    @IsTest
    static void testNewIenWithEnrolledStatusAsFaculty() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        muteTriggers();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();
        for (Contact contact : studentContacts) {

            reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c();
            ipf.reduivy__Contact__c = contact.Id;
            ipf.reduivy__Academic_Level__c = 'Masters';
            ipf.reduivy__Status__c = 'Active';

            ipfList.add(ipf);
        }

        insert ipfList;

        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : ipfList) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 5
            ]) {
                for (Contact student : studentContacts) {
                    newIenList.add(
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today(),
                            null,
                            null,
                            null,
                            3,
                            null,
                            studentToIPFMap.get(student.Id),
                            true
                        )
                    );
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
		}
		
        // Check to ensure the best attempt is not set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Best_Attempt__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(false, ien.reduivy__Best_Attempt__c);
        }
    }

    /**
     * @description Test as faculty for new individual enrollment with grade released using valid numerical grade to ensure best attempt is set
     */
    @IsTest
    static void testNewIenWithValidNumericalGradeAsFaculty() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        muteTriggers();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();
        for (Contact contact : studentContacts) {

            reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c();
            ipf.reduivy__Contact__c = contact.Id;
            ipf.reduivy__Academic_Level__c = 'Masters';
            ipf.reduivy__Status__c = 'Active';

            ipfList.add(ipf);
        }

        insert ipfList;

        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : ipfList) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
        List<reduivy__Individual_Enrollment__c> newAttemptIenList = new List<reduivy__Individual_Enrollment__c>();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 5
            ]) {
                for (Contact student : studentContacts) {
                    // first attempt with lower grade
                    reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        studentToIPFMap.get(student.Id),
                        true
                    );

                    ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
                    ien.reduivy__Numerical_Grade__c = 90;

                    newIenList.add(ien);

                    // second ien with higher grade
                    reduivy__Individual_Enrollment__c ienNewAttempt = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        2,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        studentToIPFMap.get(student.Id),
                        true
                    );

                    ienNewAttempt.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
                    ienNewAttempt.reduivy__Numerical_Grade__c = 100;

                    newAttemptIenList.add(ienNewAttempt);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
            REDU_Database_UTIL.doInsert(newAttemptIenList);
		}
		
        Map<Id, reduivy__Individual_Enrollment__c> newIenMap = new Map<Id, reduivy__Individual_Enrollment__c>(newIenList);
        Map<Id, reduivy__Individual_Enrollment__c> newAttemptIenMap = new Map<Id, reduivy__Individual_Enrollment__c>(newAttemptIenList);

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Best_Attempt__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList AND Id IN: newAttemptIenList
        ]) {
            if (newIenMap.containsKey(ien.Id)) {
                // This should not have the best attempt
                System.Assert.areEqual(false, ien.reduivy__Best_Attempt__c);
            } else {
                // This should have the best attempt
                System.Assert.areEqual(true, ien.reduivy__Best_Attempt__c);
            }
        }
    }

    /**
     * @description Test as faculty for update individual enrollment with grade released and change of grade after release to ensure the best attempt is set correctly
     */
    @IsTest
    static void testUpdateIenWithNumericalGradeAndReleaseAsFaculty() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        muteTriggers();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();
        for (Contact contact : studentContacts) {

            reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c();
            ipf.reduivy__Contact__c = contact.Id;
            ipf.reduivy__Academic_Level__c = 'Masters';
            ipf.reduivy__Status__c = 'Active';

            ipfList.add(ipf);
        }

        insert ipfList;

        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : ipfList) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
        List<reduivy__Individual_Enrollment__c> newAttemptIenList = new List<reduivy__Individual_Enrollment__c>();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 5
            ]) {
                for (Contact student : studentContacts) {
                    //first attempt
                    reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        studentToIPFMap.get(student.Id),
                        true
                    );

                    newIenList.add(ien);

                    //second attempt
                    reduivy__Individual_Enrollment__c ienNewAttempt = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        2,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        studentToIPFMap.get(student.Id),
                        true
                    );

                    newAttemptIenList.add(ienNewAttempt);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
            REDU_Database_UTIL.doInsert(newAttemptIenList);
		}
		
        Map<Id, reduivy__Individual_Enrollment__c> newIenMap = new Map<Id, reduivy__Individual_Enrollment__c>(newIenList);
        Map<Id, reduivy__Individual_Enrollment__c> newAttemptIenMap = new Map<Id, reduivy__Individual_Enrollment__c>(newAttemptIenList);

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Best_Attempt__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList AND Id IN: newAttemptIenList
        ]) {
            if (newIenMap.containsKey(ien.Id)) {
                System.Assert.areEqual(false, ien.reduivy__Best_Attempt__c);
            } else {
                System.Assert.areEqual(false, ien.reduivy__Best_Attempt__c);
            }
        }

        // simulate the grade release for first attempt ien
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Numerical_Grade__c = 90;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Best_Attempt__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList AND Id IN: newAttemptIenList
        ]) {
            if (newIenMap.containsKey(ien.Id)) {
                // This should have the best attempt
                System.Assert.areEqual(true, ien.reduivy__Best_Attempt__c);
            } else {
                // This should not have the best attempt
                System.Assert.areEqual(false, ien.reduivy__Best_Attempt__c);
            }
        }

        //simulate the grade release for second attempt with higher grade
        for (reduivy__Individual_Enrollment__c ien : newAttemptIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Numerical_Grade__c = 91;
        }

        Test.startTest();

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newAttemptIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Best_Attempt__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList AND Id IN: newAttemptIenList
        ]) {
            if (newIenMap.containsKey(ien.Id)) {
                // This should not have the best attempt
                System.Assert.areEqual(false, ien.reduivy__Best_Attempt__c);
            } else {
                // This should have the best attempt
                System.Assert.areEqual(true, ien.reduivy__Best_Attempt__c);
            }
        }

        //simulate the update of second attempt with fail grade
        for (reduivy__Individual_Enrollment__c ien : newAttemptIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Numerical_Grade__c = 0;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newAttemptIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Best_Attempt__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList AND Id IN: newAttemptIenList
        ]) {
            if (newIenMap.containsKey(ien.Id)) {
                // This should have the best attempt
                System.Assert.areEqual(true, ien.reduivy__Best_Attempt__c);
            } else {
                // This should not have the best attempt
                System.Assert.areEqual(false, ien.reduivy__Best_Attempt__c);
            }
        }

        //simulate deletion
        System.runAs(FACULTY_USER) {
            try {
                REDU_Database_UTIL.doDelete(newIenList);
                System.Assert.fail('This should fail with deletion permission.');
            } catch (Exception exp) {
                System.Assert.areEqual('Insufficient Delete access on following object(s) and field(s) - reduivy__Individual_Enrollment__c', exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin to update multiple individual enrollments with different combination of grade result, numerical grade, and start date.
     */
    @IsTest
    static void testUpdateMultipleIensWithDifferentGradesAndStatusesAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        muteTriggers();
        REDU_TriggerController.muteTriggers(new Set<String>{'IEN_CompletionEngine_EXE'});

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c();
        ipf.reduivy__Contact__c = studentContacts[0].Id;
        ipf.reduivy__Academic_Level__c = 'Masters';
        ipf.reduivy__Status__c = 'Active';

        insert ipf;

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        List<reduivy__Study_Offering__c> sof = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Offering__c WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY' LIMIT 1];
        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 0,
            reduivy__Credits_Offered__c = 3,
            reduivy__Credits_Attempted__c = 3,
            reduivy__Grade_Points__c = 0,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_FAIL,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_FAIL_STATUS,
            reduivy__Individual_Academic_Profile__c = ipf.Id,
            reduivy__Start_Date__c = System.today(),
            reduivy__Exclude_GPA_Calculation__c = false
        ));

        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 90,
            reduivy__Credits_Offered__c = 3,
            reduivy__Credits_Attempted__c = 3,
            reduivy__Grade_Points__c = 3.7,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipf.Id,
            reduivy__Start_Date__c = System.today().addDays(1),
            reduivy__Exclude_GPA_Calculation__c = false
        ));

        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 80,
            reduivy__Credits_Offered__c = 3,
            reduivy__Credits_Attempted__c = 3,
            reduivy__Grade_Points__c = 3.5,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_FAIL_STATUS,
            reduivy__Individual_Academic_Profile__c = ipf.Id,
            reduivy__Start_Date__c = System.today().addDays(2),
            reduivy__Exclude_GPA_Calculation__c = false
        ));

        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 70,
            reduivy__Credits_Offered__c = 3,
            reduivy__Credits_Attempted__c = 3,
            reduivy__Grade_Points__c = 3,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipf.Id,
            reduivy__Start_Date__c = System.today().addDays(3),
            reduivy__Exclude_GPA_Calculation__c = false
        ));

        //[4] should be the final best attempt
        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 100,
            reduivy__Credits_Offered__c = 3,
            reduivy__Credits_Attempted__c = 3,
            reduivy__Grade_Points__c = 4,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipf.Id,
            reduivy__Start_Date__c = System.today().addDays(4),
            reduivy__Exclude_GPA_Calculation__c = false
        ));

        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 100,
            reduivy__Credits_Offered__c = 3,
            reduivy__Credits_Attempted__c = 3,
            reduivy__Grade_Points__c = 4,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipf.Id,
            reduivy__Start_Date__c = System.today().addDays(3),
            reduivy__Exclude_GPA_Calculation__c = false
        ));

        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 101,
            reduivy__Credits_Offered__c = 3,
            reduivy__Credits_Attempted__c = 3,
            reduivy__Grade_Points__c = 4,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipf.Id,
            reduivy__Start_Date__c = System.today().addDays(5),
            reduivy__Exclude_GPA_Calculation__c = true
        ));

        insert newIenList;

        Test.startTest();

        System.runAs(ADMIN_USER){
            newIenList[0].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update newIenList[0];

            List<reduivy__Individual_Enrollment__c> ienResult = [SELECT Id,
            reduivy__Best_Attempt__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList];

            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.Id == newIenList[0].Id) {
                    System.assertEquals(true, ien.reduivy__Best_Attempt__c, '[0] ien should be the best attempt now');
                } else {
                    Integer index = ienResult.indexOf(ien);
                    System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'ienResult[' + index + '] should not be the best attempt');
                }
            }

            newIenList[1].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update newIenList[1];
            
            ienResult = [SELECT Id,
            reduivy__Best_Attempt__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList];

            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.Id == newIenList[1].Id) {
                    System.assertEquals(true, ien.reduivy__Best_Attempt__c, '[1] ien should be the best attempt now');
                } else {
                    Integer index = ienResult.indexOf(ien);
                    System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'ienResult[' + index + '] should not be the best attempt');
                }
            }

            newIenList[2].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update newIenList[2];
            
            ienResult = [SELECT Id,
            reduivy__Best_Attempt__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList];

            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.Id == newIenList[1].Id) {
                    System.assertEquals(true, ien.reduivy__Best_Attempt__c, '[1] ien should be the best attempt now');
                } else {
                    Integer index = ienResult.indexOf(ien);
                    System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'ienResult[' + index + '] should not be the best attempt');
                }
            }

            newIenList[3].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update newIenList[3];
            
            ienResult = [SELECT Id,
            reduivy__Best_Attempt__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList];

            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.Id == newIenList[1].Id) {
                    System.assertEquals(true, ien.reduivy__Best_Attempt__c, '[1] ien should be the best attempt now');
                } else {
                    Integer index = ienResult.indexOf(ien);
                    System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'ienResult[' + index + '] should not be the best attempt');
                }
            }

            newIenList[4].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update newIenList[4];
            
            ienResult = [SELECT Id,
            reduivy__Best_Attempt__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList];

            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.Id == newIenList[4].Id) {
                    System.assertEquals(true, ien.reduivy__Best_Attempt__c, '[4] ien should be the best attempt now');
                } else {
                    Integer index = ienResult.indexOf(ien);
                    System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'ienResult[' + index + '] should not be the best attempt');
                }
            }

            newIenList[5].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update newIenList[5];
            
            ienResult = [SELECT Id,
            reduivy__Best_Attempt__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList];

            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.Id == newIenList[4].Id) {
                    System.assertEquals(true, ien.reduivy__Best_Attempt__c, '[4] ien should be the best attempt now');
                } else {
                    Integer index = ienResult.indexOf(ien);
                    System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'ienResult[' + index + '] should not be the best attempt');
                }
            }

            newIenList[6].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update newIenList[6];
            
            ienResult = [SELECT Id,
            reduivy__Best_Attempt__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList];

            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.Id == newIenList[4].Id) {
                    System.assertEquals(true, ien.reduivy__Best_Attempt__c, '[4] ien should be the best attempt now');
                } else {
                    Integer index = ienResult.indexOf(ien);
                    System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'ienResult[' + index + '] should not be the best attempt');
                }
            }
        }

        Test.stopTest();
    }
	
    /**
     * @description Test as faculty to update multiple individual enrollments with different combination of grade result, numerical grade, and start date
     */
    @IsTest
    static void testUpdateMultipleIensWithDifferentGradesAndStatusesAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        muteTriggers();
        REDU_TriggerController.muteTriggers(new Set<String>{'IEN_CompletionEngine_EXE'});

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c();
        ipf.reduivy__Contact__c = studentContacts[0].Id;
        ipf.reduivy__Academic_Level__c = 'Masters';
        ipf.reduivy__Status__c = 'Active';

        insert ipf;

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        List<reduivy__Study_Offering__c> sof = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Offering__c WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY' LIMIT 1];
        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 0,
            reduivy__Credits_Offered__c = 3,
            reduivy__Credits_Attempted__c = 3,
            reduivy__Grade_Points__c = 0,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_FAIL,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_FAIL_STATUS,
            reduivy__Individual_Academic_Profile__c = ipf.Id,
            reduivy__Start_Date__c = System.today(),
            reduivy__Exclude_GPA_Calculation__c = false
        ));

        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 90,
            reduivy__Credits_Offered__c = 3,
            reduivy__Credits_Attempted__c = 3,
            reduivy__Grade_Points__c = 3.7,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipf.Id,
            reduivy__Start_Date__c = System.today().addDays(1),
            reduivy__Exclude_GPA_Calculation__c = false
        ));

        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 80,
            reduivy__Credits_Offered__c = 3,
            reduivy__Credits_Attempted__c = 3,
            reduivy__Grade_Points__c = 3.5,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_FAIL_STATUS,
            reduivy__Individual_Academic_Profile__c = ipf.Id,
            reduivy__Start_Date__c = System.today().addDays(2),
            reduivy__Exclude_GPA_Calculation__c = false
        ));

        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 70,
            reduivy__Credits_Offered__c = 3,
            reduivy__Credits_Attempted__c = 3,
            reduivy__Grade_Points__c = 3,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipf.Id,
            reduivy__Start_Date__c = System.today().addDays(3),
            reduivy__Exclude_GPA_Calculation__c = false
        ));

        //[4] should be the final best attempt
        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 100,
            reduivy__Credits_Offered__c = 3,
            reduivy__Credits_Attempted__c = 3,
            reduivy__Grade_Points__c = 4,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipf.Id,
            reduivy__Start_Date__c = System.today().addDays(4),
            reduivy__Exclude_GPA_Calculation__c = false
        ));

        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 100,
            reduivy__Credits_Offered__c = 3,
            reduivy__Credits_Attempted__c = 3,
            reduivy__Grade_Points__c = 4,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipf.Id,
            reduivy__Start_Date__c = System.today().addDays(3),
            reduivy__Exclude_GPA_Calculation__c = false
        ));

        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 101,
            reduivy__Credits_Offered__c = 3,
            reduivy__Credits_Attempted__c = 3,
            reduivy__Grade_Points__c = 4,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipf.Id,
            reduivy__Start_Date__c = System.today().addDays(5),
            reduivy__Exclude_GPA_Calculation__c = true
        ));
        
        insert newIenList;

        Test.startTest();

        System.runAs(FACULTY_USER){
            newIenList[0].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update newIenList[0];

            List<reduivy__Individual_Enrollment__c> ienResult = [SELECT Id,
            reduivy__Best_Attempt__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList];

            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.Id == newIenList[0].Id) {
                    System.assertEquals(true, ien.reduivy__Best_Attempt__c, '[0] ien should be the best attempt now');
                } else {
                    Integer index = ienResult.indexOf(ien);
                    System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'ienResult[' + index + '] should not be the best attempt');
                }
            }

            newIenList[1].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update newIenList[1];
            
            ienResult = [SELECT Id,
            reduivy__Best_Attempt__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList];

            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.Id == newIenList[1].Id) {
                    System.assertEquals(true, ien.reduivy__Best_Attempt__c, '[1] ien should be the best attempt now');
                } else {
                    Integer index = ienResult.indexOf(ien);
                    System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'ienResult[' + index + '] should not be the best attempt');
                }
            }

            newIenList[2].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update newIenList[2];
            
            ienResult = [SELECT Id,
            reduivy__Best_Attempt__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList];

            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.Id == newIenList[1].Id) {
                    System.assertEquals(true, ien.reduivy__Best_Attempt__c, '[1] ien should be the best attempt now');
                } else {
                    Integer index = ienResult.indexOf(ien);
                    System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'ienResult[' + index + '] should not be the best attempt');
                }
            }

            newIenList[3].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update newIenList[3];
            
            ienResult = [SELECT Id,
            reduivy__Best_Attempt__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList];

            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.Id == newIenList[1].Id) {
                    System.assertEquals(true, ien.reduivy__Best_Attempt__c, '[1] ien should be the best attempt now');
                } else {
                    Integer index = ienResult.indexOf(ien);
                    System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'ienResult[' + index + '] should not be the best attempt');
                }
            }

            newIenList[4].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update newIenList[4];
            
            ienResult = [SELECT Id,
            reduivy__Best_Attempt__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList];

            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.Id == newIenList[4].Id) {
                    System.assertEquals(true, ien.reduivy__Best_Attempt__c, '[4] ien should be the best attempt now');
                } else {
                    Integer index = ienResult.indexOf(ien);
                    System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'ienResult[' + index + '] should not be the best attempt');
                }
            }

            newIenList[5].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update newIenList[5];
            
            ienResult = [SELECT Id,
            reduivy__Best_Attempt__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList];

            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.Id == newIenList[4].Id) {
                    System.assertEquals(true, ien.reduivy__Best_Attempt__c, '[4] ien should be the best attempt now');
                } else {
                    Integer index = ienResult.indexOf(ien);
                    System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'ienResult[' + index + '] should not be the best attempt');
                }
            }

            newIenList[6].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update newIenList[6];
            
            ienResult = [SELECT Id,
            reduivy__Best_Attempt__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList];

            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.Id == newIenList[4].Id) {
                    System.assertEquals(true, ien.reduivy__Best_Attempt__c, '[4] ien should be the best attempt now');
                } else {
                    Integer index = ienResult.indexOf(ien);
                    System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'ienResult[' + index + '] should not be the best attempt');
                }
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test that best attempt is evaluated within same IPF - different best attempts per IPF as admin
     */
    @IsTest
    static void testBestAttemptWithinSameIpfAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        muteTriggers();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        // Create two IPFs for the same student
        List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();
        ipfList.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 1',
            reduivy__Primary__c = true
        ));
        ipfList.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 2',
            reduivy__Primary__c = false
        ));
        insert ipfList;

        List<reduivy__Study_Offering__c> sof = [SELECT Id, reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Academic_Term__c =: academicTerm.Id 
            AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY' 
            LIMIT 1
        ];

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        // Create IENs for IPF 1
        // IPF 1: Best should be 90 (Pass)
        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 70,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[0].Id
        ));

        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 90,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[0].Id
        ));

        // Create IENs for IPF 2
        // IPF 2: Best should be 85 (Pass)
        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 60,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[1].Id
        ));

        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 85,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[1].Id
        ));

        insert newIenList;

        Test.startTest();

        System.runAs(ADMIN_USER){
            // Release all grades
            for(reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            }
            update newIenList;

            // Query results
            List<reduivy__Individual_Enrollment__c> ienResult = [SELECT Id,
                reduivy__Best_Attempt__c,
                reduivy__Individual_Academic_Profile__c,
                reduivy__Numerical_Grade__c,
                reduivy__Exclude_Credits_Earned__c,
                reduivy__Exclude_GPA_Calculation__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id IN: newIenList
                ORDER BY reduivy__Individual_Academic_Profile__c, reduivy__Numerical_Grade__c
            ];

            // Verify IPF 1 results
            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.reduivy__Individual_Academic_Profile__c == ipfList[0].Id) {
                    if (ien.reduivy__Numerical_Grade__c == 90) {
                        System.assertEquals(true, ien.reduivy__Best_Attempt__c, 'IEN with grade 90 in IPF 1 should be best attempt');
                    } else {
                        System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'IEN with grade 70 in IPF 1 should not be best attempt');
                    }
                }
            }

            // Verify IPF 2 results
            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.reduivy__Individual_Academic_Profile__c == ipfList[1].Id) {
                    if (ien.reduivy__Numerical_Grade__c == 85) {
                        System.assertEquals(true, ien.reduivy__Best_Attempt__c, 'IEN with grade 85 in IPF 2 should be best attempt');
                    } else {
                        System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'IEN with grade 60 in IPF 2 should not be best attempt');
                    }
                }
            }

            // Verify isolation: Best in IPF 1 (90) should not affect best in IPF 2 (85)
            Integer bestAttemptCount = 0;
            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.reduivy__Best_Attempt__c) {
                    bestAttemptCount++;
                }
            }
            System.assertEquals(2, bestAttemptCount, 
                'Should have exactly 2 best attempts - one per IPF');
        }

        Test.stopTest();
    }

    /**
     * @description Test that higher grade in one IPF doesn't override best attempt in another IPF as admin
     */
    @IsTest
    static void testIpfIsolationForBestAttemptAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        muteTriggers();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        reduivy__Study_Term__c academicTerm = [SELECT Id
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        // Create two IPFs
        List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();
        ipfList.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 1'
        ));
        ipfList.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 2'
        ));
        insert ipfList;

        List<reduivy__Study_Offering__c> sof = [SELECT Id 
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Academic_Term__c =: academicTerm.Id 
            AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY' 
            LIMIT 1
        ];

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        // IPF 1: Grade 100 (highest overall)
        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 100,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[0].Id
        ));

        // IPF 2: Grade 75 (lower than IPF 1, but should still be best for IPF 2)
        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 50,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[1].Id
        ));

        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 75,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[1].Id
        ));

        insert newIenList;

        Test.startTest();

        System.runAs(ADMIN_USER){
            // Release all grades
            for(reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            }
            update newIenList;

            List<reduivy__Individual_Enrollment__c> ienResult = [SELECT Id,
                reduivy__Best_Attempt__c,
                reduivy__Individual_Academic_Profile__c,
                reduivy__Numerical_Grade__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id IN: newIenList
            ];

            // Verify: Grade 100 in IPF 1 is best for IPF 1
            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.reduivy__Individual_Academic_Profile__c == ipfList[0].Id && 
                    ien.reduivy__Numerical_Grade__c == 100) {
                    System.assertEquals(true, ien.reduivy__Best_Attempt__c, 
                        'Grade 100 should be best attempt in IPF 1');
                }
            }

            // Verify: Grade 75 in IPF 2 is best for IPF 2 (not affected by 100 in IPF 1)
            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.reduivy__Individual_Academic_Profile__c == ipfList[1].Id) {
                    if (ien.reduivy__Numerical_Grade__c == 75) {
                        System.assertEquals(true, ien.reduivy__Best_Attempt__c, 
                            'Grade 75 should be best attempt in IPF 2, independent of IPF 1');
                    } else {
                        System.assertEquals(false, ien.reduivy__Best_Attempt__c, 
                            'Grade 50 should not be best attempt in IPF 2');
                    }
                }
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test best attempt when releasing grades sequentially across different IPFs as admin
     */
    @IsTest
    static void testSequentialGradeReleaseAcrossIpfsAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        muteTriggers();

        List<Contact> studentContacts = [SELECT Id 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        reduivy__Study_Term__c academicTerm = [SELECT Id
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        // Create two IPFs
        List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();
        ipfList.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 1'
        ));
        ipfList.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 2'
        ));
        insert ipfList;

        List<reduivy__Study_Offering__c> sof = [SELECT Id 
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Academic_Term__c =: academicTerm.Id 
            AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY' 
            LIMIT 1
        ];

        List<reduivy__Individual_Enrollment__c> ipf1IenList = new List<reduivy__Individual_Enrollment__c>();
        List<reduivy__Individual_Enrollment__c> ipf2IenList = new List<reduivy__Individual_Enrollment__c>();

        // IPF 1 IENs
        ipf1IenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 80,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[0].Id
        ));

        ipf1IenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 95,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[0].Id
        ));

        // IPF 2 IENs
        ipf2IenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 70,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[1].Id
        ));

        ipf2IenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 88,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[1].Id
        ));

        insert ipf1IenList;
        insert ipf2IenList;

        Test.startTest();

        System.runAs(ADMIN_USER){
            // Release IPF 1 grade (80)
            ipf1IenList[0].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update ipf1IenList[0];

            List<reduivy__Individual_Enrollment__c> checkIpf1 = [SELECT Id, reduivy__Best_Attempt__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :ipf1IenList[0].Id
            ];
            System.assertEquals(true, checkIpf1[0].reduivy__Best_Attempt__c, 
                'First released IEN in IPF 1 should be best');

            // Release IPF 2 grade (70)
            ipf2IenList[0].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update ipf2IenList[0];

            List<reduivy__Individual_Enrollment__c> checkIpf2 = [SELECT Id, reduivy__Best_Attempt__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :ipf2IenList[0].Id
            ];
            System.assertEquals(true, checkIpf2[0].reduivy__Best_Attempt__c, 
                'First released IEN in IPF 2 should be best');

            // Verify IPF 1 best is still correct
            checkIpf1 = [SELECT Id, reduivy__Best_Attempt__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :ipf1IenList[0].Id
            ];
            System.assertEquals(true, checkIpf1[0].reduivy__Best_Attempt__c, 
                'IPF 1 best should not be affected by IPF 2 releases');

            // Release higher grade in IPF 1 (95)
            ipf1IenList[1].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update ipf1IenList[1];

            List<reduivy__Individual_Enrollment__c> allIpf1 = [SELECT Id, reduivy__Best_Attempt__c, reduivy__Numerical_Grade__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id IN :ipf1IenList
                ORDER BY reduivy__Numerical_Grade__c
            ];

            System.assertEquals(false, allIpf1[0].reduivy__Best_Attempt__c, 
                'Grade 80 should no longer be best in IPF 1');
            System.assertEquals(true, allIpf1[1].reduivy__Best_Attempt__c, 
                'Grade 95 should now be best in IPF 1');

            // Verify IPF 2 still has its own best (70)
            checkIpf2 = [SELECT Id, reduivy__Best_Attempt__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :ipf2IenList[0].Id
            ];
            System.assertEquals(true, checkIpf2[0].reduivy__Best_Attempt__c, 
                'IPF 2 best should not be affected by IPF 1 updates');

            // Release higher grade in IPF 2 (88)
            ipf2IenList[1].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update ipf2IenList[1];

            List<reduivy__Individual_Enrollment__c> allIpf2 = [SELECT Id, reduivy__Best_Attempt__c, reduivy__Numerical_Grade__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id IN :ipf2IenList
                ORDER BY reduivy__Numerical_Grade__c
            ];

            System.assertEquals(false, allIpf2[0].reduivy__Best_Attempt__c, 
                'Grade 70 should no longer be best in IPF 2');
            System.assertEquals(true, allIpf2[1].reduivy__Best_Attempt__c, 
                'Grade 88 should now be best in IPF 2');

            // Final verification: Each IPF has exactly one best attempt
            List<reduivy__Individual_Enrollment__c> allIens = [SELECT Id, 
                reduivy__Best_Attempt__c,
                reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id IN :ipf1IenList OR Id IN :ipf2IenList
            ];

            Integer ipf1BestCount = 0;
            Integer ipf2BestCount = 0;
            for (reduivy__Individual_Enrollment__c ien : allIens) {
                if (ien.reduivy__Best_Attempt__c) {
                    if (ien.reduivy__Individual_Academic_Profile__c == ipfList[0].Id) {
                        ipf1BestCount++;
                    } else {
                        ipf2BestCount++;
                    }
                }
            }

            System.assertEquals(1, ipf1BestCount, 'IPF 1 should have exactly one best attempt');
            System.assertEquals(1, ipf2BestCount, 'IPF 2 should have exactly one best attempt');
        }

        Test.stopTest();
    }

    /**
     * @description Test that best attempt is evaluated within same IPF - different best attempts per IPF ad faculty
     */
    @IsTest
    static void testBestAttemptWithinSameIpfAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        muteTriggers();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        // Create two IPFs for the same student
        List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();
        ipfList.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 1',
            reduivy__Primary__c = true
        ));
        ipfList.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 2',
            reduivy__Primary__c = false
        ));
        insert ipfList;

        List<reduivy__Study_Offering__c> sof = [SELECT Id, reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Academic_Term__c =: academicTerm.Id 
            AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY' 
            LIMIT 1
        ];

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        // Create IENs for IPF 1
        // IPF 1: Best should be 90 (Pass)
        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 70,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[0].Id
        ));

        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 90,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[0].Id
        ));

        // Create IENs for IPF 2
        // IPF 2: Best should be 85 (Pass)
        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 60,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[1].Id
        ));

        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 85,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[1].Id
        ));

        insert newIenList;

        Test.startTest();

        System.runAs(FACULTY_USER){
            // Release all grades
            for(reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            }
            update newIenList;

            // Query results
            List<reduivy__Individual_Enrollment__c> ienResult = [SELECT Id,
                reduivy__Best_Attempt__c,
                reduivy__Individual_Academic_Profile__c,
                reduivy__Numerical_Grade__c,
                reduivy__Exclude_Credits_Earned__c,
                reduivy__Exclude_GPA_Calculation__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id IN: newIenList
                ORDER BY reduivy__Individual_Academic_Profile__c, reduivy__Numerical_Grade__c
            ];

            // Verify IPF 1 results
            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.reduivy__Individual_Academic_Profile__c == ipfList[0].Id) {
                    if (ien.reduivy__Numerical_Grade__c == 90) {
                        System.assertEquals(true, ien.reduivy__Best_Attempt__c, 'IEN with grade 90 in IPF 1 should be best attempt');
                    } else {
                        System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'IEN with grade 70 in IPF 1 should not be best attempt');
                    }
                }
            }

            // Verify IPF 2 results
            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.reduivy__Individual_Academic_Profile__c == ipfList[1].Id) {
                    if (ien.reduivy__Numerical_Grade__c == 85) {
                        System.assertEquals(true, ien.reduivy__Best_Attempt__c, 'IEN with grade 85 in IPF 2 should be best attempt');
                    } else {
                        System.assertEquals(false, ien.reduivy__Best_Attempt__c, 'IEN with grade 60 in IPF 2 should not be best attempt');
                    }
                }
            }

            // Verify isolation: Best in IPF 1 (90) should not affect best in IPF 2 (85)
            Integer bestAttemptCount = 0;
            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.reduivy__Best_Attempt__c) {
                    bestAttemptCount++;
                }
            }
            System.assertEquals(2, bestAttemptCount, 
                'Should have exactly 2 best attempts - one per IPF');
        }

        Test.stopTest();
    }

    /**
     * @description Test that higher grade in one IPF doesn't override best attempt in another IPF ad faculty
     */
    @IsTest
    static void testIpfIsolationForBestAttemptAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        muteTriggers();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        reduivy__Study_Term__c academicTerm = [SELECT Id
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        // Create two IPFs
        List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();
        ipfList.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 1'
        ));
        ipfList.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 2'
        ));
        insert ipfList;

        List<reduivy__Study_Offering__c> sof = [SELECT Id 
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Academic_Term__c =: academicTerm.Id 
            AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY' 
            LIMIT 1
        ];

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        // IPF 1: Grade 100 (highest overall)
        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 100,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[0].Id
        ));

        // IPF 2: Grade 75 (lower than IPF 1, but should still be best for IPF 2)
        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 50,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[1].Id
        ));

        newIenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 75,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[1].Id
        ));

        insert newIenList;

        Test.startTest();

        System.runAs(FACULTY_USER){
            // Release all grades
            for(reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            }
            update newIenList;

            List<reduivy__Individual_Enrollment__c> ienResult = [SELECT Id,
                reduivy__Best_Attempt__c,
                reduivy__Individual_Academic_Profile__c,
                reduivy__Numerical_Grade__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id IN: newIenList
            ];

            // Verify: Grade 100 in IPF 1 is best for IPF 1
            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.reduivy__Individual_Academic_Profile__c == ipfList[0].Id && 
                    ien.reduivy__Numerical_Grade__c == 100) {
                    System.assertEquals(true, ien.reduivy__Best_Attempt__c, 
                        'Grade 100 should be best attempt in IPF 1');
                }
            }

            // Verify: Grade 75 in IPF 2 is best for IPF 2 (not affected by 100 in IPF 1)
            for (reduivy__Individual_Enrollment__c ien : ienResult) {
                if (ien.reduivy__Individual_Academic_Profile__c == ipfList[1].Id) {
                    if (ien.reduivy__Numerical_Grade__c == 75) {
                        System.assertEquals(true, ien.reduivy__Best_Attempt__c, 
                            'Grade 75 should be best attempt in IPF 2, independent of IPF 1');
                    } else {
                        System.assertEquals(false, ien.reduivy__Best_Attempt__c, 
                            'Grade 50 should not be best attempt in IPF 2');
                    }
                }
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test best attempt when releasing grades sequentially across different IPFs ad faculty
     */
    @IsTest
    static void testSequentialGradeReleaseAcrossIpfsAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        muteTriggers();

        List<Contact> studentContacts = [SELECT Id 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        reduivy__Study_Term__c academicTerm = [SELECT Id
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        // Create two IPFs
        List<reduivy__Individual_Academic_Profile__c> ipfList = new List<reduivy__Individual_Academic_Profile__c>();
        ipfList.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 1'
        ));
        ipfList.add(new reduivy__Individual_Academic_Profile__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Academic_Level__c = 'Masters',
            reduivy__Status__c = IPF_Helper.STATUS_ACTIVE,
            Name = 'IPF 2'
        ));
        insert ipfList;

        List<reduivy__Study_Offering__c> sof = [SELECT Id 
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Academic_Term__c =: academicTerm.Id 
            AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY' 
            LIMIT 1
        ];

        List<reduivy__Individual_Enrollment__c> ipf1IenList = new List<reduivy__Individual_Enrollment__c>();
        List<reduivy__Individual_Enrollment__c> ipf2IenList = new List<reduivy__Individual_Enrollment__c>();

        // IPF 1 IENs
        ipf1IenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 80,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[0].Id
        ));

        ipf1IenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 95,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[0].Id
        ));

        // IPF 2 IENs
        ipf2IenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 70,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[1].Id
        ));

        ipf2IenList.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Study_Offering__c = sof[0].Id,
            reduivy__Numerical_Grade__c = 88,
            reduivy__Grade_Result__c = IEN_Helper.GRADE_RESULT_TYPE_PASS,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Individual_Academic_Profile__c = ipfList[1].Id
        ));

        insert ipf1IenList;
        insert ipf2IenList;

        Test.startTest();

        System.runAs(FACULTY_USER){
            // Release IPF 1 grade (80)
            ipf1IenList[0].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update ipf1IenList[0];

            List<reduivy__Individual_Enrollment__c> checkIpf1 = [SELECT Id, reduivy__Best_Attempt__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :ipf1IenList[0].Id
            ];
            System.assertEquals(true, checkIpf1[0].reduivy__Best_Attempt__c, 
                'First released IEN in IPF 1 should be best');

            // Release IPF 2 grade (70)
            ipf2IenList[0].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update ipf2IenList[0];

            List<reduivy__Individual_Enrollment__c> checkIpf2 = [SELECT Id, reduivy__Best_Attempt__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :ipf2IenList[0].Id
            ];
            System.assertEquals(true, checkIpf2[0].reduivy__Best_Attempt__c, 
                'First released IEN in IPF 2 should be best');

            // Verify IPF 1 best is still correct
            checkIpf1 = [SELECT Id, reduivy__Best_Attempt__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :ipf1IenList[0].Id
            ];
            System.assertEquals(true, checkIpf1[0].reduivy__Best_Attempt__c, 
                'IPF 1 best should not be affected by IPF 2 releases');

            // Release higher grade in IPF 1 (95)
            ipf1IenList[1].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update ipf1IenList[1];

            List<reduivy__Individual_Enrollment__c> allIpf1 = [SELECT Id, reduivy__Best_Attempt__c, reduivy__Numerical_Grade__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id IN :ipf1IenList
                ORDER BY reduivy__Numerical_Grade__c
            ];

            System.assertEquals(false, allIpf1[0].reduivy__Best_Attempt__c, 
                'Grade 80 should no longer be best in IPF 1');
            System.assertEquals(true, allIpf1[1].reduivy__Best_Attempt__c, 
                'Grade 95 should now be best in IPF 1');

            // Verify IPF 2 still has its own best (70)
            checkIpf2 = [SELECT Id, reduivy__Best_Attempt__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :ipf2IenList[0].Id
            ];
            System.assertEquals(true, checkIpf2[0].reduivy__Best_Attempt__c, 
                'IPF 2 best should not be affected by IPF 1 updates');

            // Release higher grade in IPF 2 (88)
            ipf2IenList[1].reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            update ipf2IenList[1];

            List<reduivy__Individual_Enrollment__c> allIpf2 = [SELECT Id, reduivy__Best_Attempt__c, reduivy__Numerical_Grade__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id IN :ipf2IenList
                ORDER BY reduivy__Numerical_Grade__c
            ];

            System.assertEquals(false, allIpf2[0].reduivy__Best_Attempt__c, 
                'Grade 70 should no longer be best in IPF 2');
            System.assertEquals(true, allIpf2[1].reduivy__Best_Attempt__c, 
                'Grade 88 should now be best in IPF 2');

            // Final verification: Each IPF has exactly one best attempt
            List<reduivy__Individual_Enrollment__c> allIens = [SELECT Id, 
                reduivy__Best_Attempt__c,
                reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id IN :ipf1IenList OR Id IN :ipf2IenList
            ];

            Integer ipf1BestCount = 0;
            Integer ipf2BestCount = 0;
            for (reduivy__Individual_Enrollment__c ien : allIens) {
                if (ien.reduivy__Best_Attempt__c) {
                    if (ien.reduivy__Individual_Academic_Profile__c == ipfList[0].Id) {
                        ipf1BestCount++;
                    } else {
                        ipf2BestCount++;
                    }
                }
            }

            System.assertEquals(1, ipf1BestCount, 'IPF 1 should have exactly one best attempt');
            System.assertEquals(1, ipf2BestCount, 'IPF 2 should have exactly one best attempt');
        }

        Test.stopTest();
    }
}