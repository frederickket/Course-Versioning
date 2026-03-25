/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Test
 * @description Test class for IEN_CompletionEngine_EXE
 * @changehistory
 * ISS-001822 15-01-2024 Lean - new class
 * ISS-002405 23-04-2025 XW - Added test case for update individual enrollment with internal grade released to released
 * ISS-002486 10-06-2025 XiRouh - Updated IEN_COMPLETED_STATUS to IEN_COMPLETED_PASS_STATUS, Added IEN_COMPLETED_FAIL_STATUS
 * ISS-002485 11-06-2025 XiRouh -Updated to cover more scenarios of grade release status transitions
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@IsTest
public inherited sharing class IEN_CompletionEngine_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
    static final String IEN_COMPLETED_PASS_STATUS = IEN_Helper.getCompletedPassStatuses().get(0);
    static final String IEN_COMPLETED_FAIL_STATUS = IEN_Helper.getCompletedFailStatuses().get(0);
    static final String IEN_WAITLISTED_STATUS = IEN_Helper.getWaitlistedStatuses().get(0);

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
     * @description Test as admin for new individual enrollment without grade released
     */
    @IsTest
    static void testNewIenWithEnrolledStatusAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
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
		
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Numerical_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for new individual enrollment with grade released using valid numerical grade
     */
    @IsTest
    static void testNewIenWithValidNumericalGradeAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 5
            ]) {
                for (Contact student : studentContacts) {
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
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
		}
		
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(90, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(4, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }
    }

    /**
     * @description Test as admin for new individual enrollment with grade released using invalid numerical grade
     */
    @IsTest
    static void testNewIenWithInvalidNumericalGradeAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 5
            ]) {
                for (Contact student : studentContacts) {
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
                    ien.reduivy__Numerical_Grade__c = 101;

                    newIenList.add(ien);
                }
            }

            try {
                REDU_Database_UTIL.doInsert(newIenList);

                System.Assert.fail('This should fail with error.');

            } catch (Exception exp) {
                String ienSgsFieldLabel = Schema.SObjectType.reduivy__Individual_Enrollment__c.fields.reduivy__Study_Grade_Setting__c.getLabel();
                String ienLetterGradeFieldLabel = Schema.SObjectType.reduivy__Individual_Enrollment__c.fields.reduivy__Letter_Grade__c.getLabel();
                String ienNumericalGradeFieldLabel = Schema.SObjectType.reduivy__Individual_Enrollment__c.fields.reduivy__Final_Numerical_Grade__c.getLabel();

                String expectedError = String.format(Label.Matching_Grading_Scheme_Failed_For_Grade_Release, new List<String>{SGD_Helper.getObjectLabel(), ienNumericalGradeFieldLabel, ienLetterGradeFieldLabel});

                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Invalid expected message: ' + exp.getMessage());
            }
		}
		
    }
	
    /**
     * @description Test as admin for new individual enrollment with grade released using valid numerical grade
     */
    @IsTest
    static void testNewIenWithValidLetterGradeAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
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
                    ien.reduivy__Letter_Grade__c = 'B';

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
		}
		
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70.9, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        Test.stopTest();

    }

    /**
     * @description Test as admin for update individual enrollment with grade released and change of grade after release
     */
    @IsTest
    static void testUpdateIenWithNumericalGradeAndReleaseAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        REDU_TriggerController.muteTriggers(new Set<String>{
            'IEN_AcademicProgress_Before',
            'IEN_AcademicProgressRollup_After',
            'IEN_SetUnitIpsStatus_After',
            'IEN_ReassignIpsu_After',
            'IEN_ReassignIpsu_Before'
        });
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        // Update the B and F grading scheme to remove the reduivy__Enrollment_Status__c field
        List<reduivy__Study_Grading_Scheme__c> bSgds = [SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Study_Grading_Scheme__c 
            WHERE reduivy__Letter_Grade__c IN ('A', 'F') 
        ];

        for (reduivy__Study_Grading_Scheme__c sgd : bSgds) {
            sgd.reduivy__Enrollment_Status__c = '';
        }

        REDU_Database_UTIL.doUpdate(bSgds);

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
		
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Numerical_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
        }

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Numerical_Grade__c = 90;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(90, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(4, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Numerical_Grade__c = 70;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        //From Released - Completed Pass update to Internal Release
        //Expected Enrollment Status: In Progress
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_INTERNALRELEASE;
            ien.reduivy__Numerical_Grade__c = 70;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_INPROGRESS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        //Update status from Internal Release - In Progress to Internal Release - Completed, to check if the status updates correctly during the transition between internal statuses.
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        //From Internal Release - Completed Pass update to Internal Audit
        //Expected Enrollment Status: In Progress
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_INTERNALAUDIT;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_INPROGRESS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        //update status from Internal Release - In Progress update to Released to set the status to completed pass
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        //From Released - Completed Pass update to Not Release
        //Expected Enrollment Status: In Progress
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_INPROGRESS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        //Update status to inactive status
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Enrollment_Status__c = IEN_WAITLISTED_STATUS;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        //From Waitlisted - Not Release update to Released
        //Expected Enrollment Status: Waitlisted 
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_WAITLISTED_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        //Update status to active status
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        //update grade result from pass to fail
        //Expected Enrollment Status: Completed Fail 
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Numerical_Grade__c = 0;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('F', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(0, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(0, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Fail', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_FAIL_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        //update grade result from fail to pass
        //Expected Enrollment Status: Completed 
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Numerical_Grade__c = 100;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(100, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(4, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for update individual enrollment with grade released and change of letter grade after release
     */
    @IsTest
    static void testUpdateIenWithLetterGradeAndReleaseAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
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
		
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Numerical_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
        }

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Letter_Grade__c = 'A';
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(100, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(4, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Letter_Grade__c = 'B';
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70.9, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        Test.stopTest();
    }
	
    /**
     * @description Test as admin for update individual enrollment with grade released and exclude flags
     */
    @IsTest
    static void testUpdateIenWithExcludeFlagsAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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
		
        Set<Id> sgsIds = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Study_Grade_Setting__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Numerical_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);

            sgsIds.add(ien.reduivy__Study_Grade_Setting__c);
        }

        // Update the B grading scheme with exclude flags to simulate the exclusion
        List<reduivy__Study_Grading_Scheme__c> bSgds = [SELECT Id 
            FROM reduivy__Study_Grading_Scheme__c 
            WHERE reduivy__Study_Grade_Setting__c IN: sgsIds
            AND reduivy__Letter_Grade__c = 'B'
        ];

        for (reduivy__Study_Grading_Scheme__c sgd : bSgds) {
            sgd.reduivy__Exclude_Credits_Earned__c = SGD_Helper.EXCLUDE_CREDITSEARNED_YES;
            sgd.reduivy__Exclude_GPA_Calculation__c = SGD_Helper.EXCLUDE_GPA_YES;
        }

        REDU_Database_UTIL.doUpdate(bSgds);

        SGD_Helper.getStudyGradingSchemes(sgsIds, false);

        Test.startTest();

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Letter_Grade__c = 'A';
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(100, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(4, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Letter_Grade__c = 'B';
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70.9, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(true, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(true, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        Test.stopTest();
    }

    /**
     * @description Test as Admin for update individual enrollment with grade released and bypass grade
     */
    @IsTest
    static void testUpdateIenWithBypassGradeAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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
		
        Set<Id> sgsIds = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Study_Grade_Setting__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Numerical_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);

            sgsIds.add(ien.reduivy__Study_Grade_Setting__c);
        }

        // Update the FA grading scheme with exclude flags to simulate the bypass
        List<reduivy__Study_Grading_Scheme__c> bSgds = [SELECT Id 
            FROM reduivy__Study_Grading_Scheme__c 
            WHERE reduivy__Study_Grade_Setting__c IN: sgsIds
            AND reduivy__Letter_Grade__c = 'FA'
        ];

        for (reduivy__Study_Grading_Scheme__c sgd : bSgds) {
            sgd.reduivy__Exclude_Credits_Earned__c = SGD_Helper.EXCLUDE_CREDITSEARNED_YES;
            sgd.reduivy__Exclude_GPA_Calculation__c = SGD_Helper.EXCLUDE_GPA_YES;
            sgd.reduivy__Grade_Result__c = 'Waive';
        }

        REDU_Database_UTIL.doUpdate(bSgds);
        
        SGD_Helper.getStudyGradingSchemes(sgsIds, false);

        Test.startTest();

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Letter_Grade__c = 'A';
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(100, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(4, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Letter_Grade__c = 'FA';
            ien.reduivy__Numerical_Grade__c = 50;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('FA', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(50, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(0, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Waive', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(true, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(true, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_FAIL_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        Test.stopTest();
    }

    /**
     * @description Test as Admin for update individual enrollment from released to not released
     */
    @IsTest
    static void testUpdateIenWithNotReleasedAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
		
        //Simulate new individual enrollment for the students
        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            LIMIT 5
        ]) {
            for (Contact student : studentContacts) {
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
            }
        }

        REDU_Database_UTIL.doInsert(newIenList);
		
        List<reduivy__Individual_Enrollment__c> unReleaseIenList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(90, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(4, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);

            reduivy__Individual_Enrollment__c unreleaseIen = new reduivy__Individual_Enrollment__c();
            unreleaseIen.Id = ien.Id;
            unreleaseIen.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;

            unReleaseIenList.add(unreleaseIen);
        }

        Test.startTest();

        System.runAs(ADMIN_USER){

            REDU_Database_UTIL.doUpdate(unReleaseIenList);
        }

        Test.stopTest();

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(90, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c);
        }
    }

    /**
     * @description Test as admin for update individual enrollment with internal grade released to released
     */
    @IsTest
    static void testUpdateIenWithLetterGradeFromInteralReleaseToReleasedAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
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
		
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Numerical_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
        }

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Letter_Grade__c = 'A';
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(100, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(4, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        //update to internal release first
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_INTERNALRELEASE;
            ien.reduivy__Letter_Grade__c = 'B';
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70.9, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_INPROGRESS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        //update to released from internal release
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70.9, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        Test.stopTest();
    }
	

    /**
     * @description Test as Faculty for new individual enrollment without grade released
     */
    @IsTest
    static void testNewIenWithEnrolledStatusAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        Test.startTest();

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
		
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Numerical_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
        }

        Test.stopTest();
    }

    /**
     * @description Test as Faculty for new individual enrollment with grade released using valid numerical grade
     */
    @IsTest
    static void testNewIenWithValidNumericalGradeAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
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
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
		}
		
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(90, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(4, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }
    }

    /**
     * @description Test as Faculty for new individual enrollment with grade released using invalid numerical grade
     */
    @IsTest
    static void testNewIenWithInvalidNumericalGradeAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
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
                    ien.reduivy__Numerical_Grade__c = 101;

                    newIenList.add(ien);
                }
            }

            try {
                REDU_Database_UTIL.doInsert(newIenList);

                System.Assert.fail('This should fail with error.');

            } catch (Exception exp) {
                String ienSgsFieldLabel = Schema.SObjectType.reduivy__Individual_Enrollment__c.fields.reduivy__Study_Grade_Setting__c.getLabel();
                String ienLetterGradeFieldLabel = Schema.SObjectType.reduivy__Individual_Enrollment__c.fields.reduivy__Letter_Grade__c.getLabel();
                String ienNumericalGradeFieldLabel = Schema.SObjectType.reduivy__Individual_Enrollment__c.fields.reduivy__Final_Numerical_Grade__c.getLabel();

                String expectedError = String.format(Label.Matching_Grading_Scheme_Failed_For_Grade_Release, new List<String>{SGD_Helper.getObjectLabel(), ienNumericalGradeFieldLabel, ienLetterGradeFieldLabel});

                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Invalid expected message: ' + exp.getMessage());
            }
		}
		
    }
	
    /**
     * @description Test as Faculty for new individual enrollment with grade released using valid numerical grade
     */
    @IsTest
    static void testNewIenWithValidLetterGradeAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        Test.startTest();
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
                    ien.reduivy__Letter_Grade__c = 'B';

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
		}
        
        Test.stopTest();
		
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70.9, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }
    }

    /**
     * @description Test as Faculty for update individual enrollment with grade released and change of grade after release
     */
    @IsTest
    static void testUpdateIenWithNumericalGradeAndReleaseAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        REDU_TriggerController.muteTriggers(new Set<String>{
            'IEN_AcademicProgress_Before',
            'IEN_AcademicProgressRollup_After',
            'IEN_SetUnitIpsStatus_After',
            'IEN_ReassignIpsu_After',
            'IEN_ReassignIpsu_Before'
        });
        
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

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        // Update the B and F grading scheme to remove the reduivy__Enrollment_Status__c field
        List<reduivy__Study_Grading_Scheme__c> bSgds = [SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Study_Grading_Scheme__c 
            WHERE reduivy__Letter_Grade__c IN ('A', 'F') 
        ];

        for (reduivy__Study_Grading_Scheme__c sgd : bSgds) {
            sgd.reduivy__Enrollment_Status__c = '';
        }

        REDU_Database_UTIL.doUpdate(bSgds);

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        Test.startTest();

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
		
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Numerical_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
        }

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Numerical_Grade__c = 90;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(90, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(4, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Numerical_Grade__c = 70;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        //From Released - Completed Pass update to Internal Release
        //Expected Enrollment Status: In Progress
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_INTERNALRELEASE;
            ien.reduivy__Numerical_Grade__c = 70;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_INPROGRESS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        //Update status from Internal Release - In Progress to Internal Release - Completed, to check if the status updates correctly during the transition between internal statuses.
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        //From Internal Release - Completed Pass update to Internal Audit
        //Expected Enrollment Status: In Progress
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_INTERNALAUDIT;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_INPROGRESS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        //update status from Internal Release - In Progress update to Released to set the status to completed pass
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        //From Released - Completed Pass update to Not Release
        //Expected Enrollment Status: In Progress
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_INPROGRESS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        //Update status to inactive status
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Enrollment_Status__c = IEN_WAITLISTED_STATUS;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        //From Waitlisted - Not Release update to Released
        //Expected Enrollment Status: Waitlisted 
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_WAITLISTED_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        //Update status to active status
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        //update grade result from pass to fail
        //Expected Enrollment Status: Completed Fail 
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Numerical_Grade__c = 0;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('F', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(0, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(0, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Fail', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_FAIL_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        //update grade result from fail to pass
        //Expected Enrollment Status: Completed 
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Numerical_Grade__c = 100;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(100, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(4, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        Test.stopTest();
    }

    /**
     * @description Test as Faculty for update individual enrollment with grade released and change of letter grade after release
     */
    @IsTest
    static void testUpdateIenWithLetterGradeAndReleaseAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
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

        Test.startTest();

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Numerical_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
        }

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Letter_Grade__c = 'A';
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(100, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(4, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Letter_Grade__c = 'B';
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70.9, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        Test.stopTest();
    }
	
    /**
     * @description Test as Faculty for update individual enrollment with grade released and exclude flags
     */
    @IsTest
    static void testUpdateIenWithExcludeFlagsAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
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
		
        Set<Id> sgsIds = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Study_Grade_Setting__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Numerical_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);

            sgsIds.add(ien.reduivy__Study_Grade_Setting__c);
        }

        // Update the B grading scheme with exclude flags to simulate the exclusion
        List<reduivy__Study_Grading_Scheme__c> bSgds = [SELECT Id 
            FROM reduivy__Study_Grading_Scheme__c 
            WHERE reduivy__Study_Grade_Setting__c IN: sgsIds
            AND reduivy__Letter_Grade__c = 'B'
        ];

        for (reduivy__Study_Grading_Scheme__c sgd : bSgds) {
            sgd.reduivy__Exclude_Credits_Earned__c = SGD_Helper.EXCLUDE_CREDITSEARNED_YES;
            sgd.reduivy__Exclude_GPA_Calculation__c = SGD_Helper.EXCLUDE_GPA_YES;
        }

        REDU_Database_UTIL.doUpdate(bSgds);

        SGD_Helper.getStudyGradingSchemes(sgsIds, false);

        Test.startTest();

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Letter_Grade__c = 'A';
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(100, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(4, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Letter_Grade__c = 'B';
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70.9, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(true, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(true, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        Test.stopTest();
    }

    /**
     * @description Test as Faculty for update individual enrollment with grade released and bypass grade
     */
    @IsTest
    static void testUpdateIenWithBypassGradeAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
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
		
        Set<Id> sgsIds = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Study_Grade_Setting__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Numerical_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);

            sgsIds.add(ien.reduivy__Study_Grade_Setting__c);
        }

        // Update the FA grading scheme with exclude flags to simulate the bypass
        List<reduivy__Study_Grading_Scheme__c> bSgds = [SELECT Id 
            FROM reduivy__Study_Grading_Scheme__c 
            WHERE reduivy__Study_Grade_Setting__c IN: sgsIds
            AND reduivy__Letter_Grade__c = 'FA'
        ];

        for (reduivy__Study_Grading_Scheme__c sgd : bSgds) {
            sgd.reduivy__Exclude_Credits_Earned__c = SGD_Helper.EXCLUDE_CREDITSEARNED_YES;
            sgd.reduivy__Exclude_GPA_Calculation__c = SGD_Helper.EXCLUDE_GPA_YES;
            sgd.reduivy__Grade_Result__c = 'Waive';
        }

        REDU_Database_UTIL.doUpdate(bSgds);
        
        SGD_Helper.getStudyGradingSchemes(sgsIds, false);
        
        Test.startTest();

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Letter_Grade__c = 'A';
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(100, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(4, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Letter_Grade__c = 'FA';
            ien.reduivy__Numerical_Grade__c = 50;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('FA', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(50, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(0, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Waive', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(true, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(true, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_FAIL_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        Test.stopTest();
    }
    
    /**
     * @description Test as admin for update individual enrollment with internal grade released to released
     */
    @IsTest
    static void testUpdateIenWithLetterGradeFromInteralReleaseToReleasedAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        Test.startTest();

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
		
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Numerical_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
        }

        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
            ien.reduivy__Letter_Grade__c = 'A';
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(100, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(4, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        //update to internal release first
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_INTERNALRELEASE;
            ien.reduivy__Letter_Grade__c = 'B';
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70.9, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_INPROGRESS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        //update to released from internal release
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(70.9, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c);
        }

        Test.stopTest();
    }
	
    /**
     * @description Test as admin that setting Skip_Completion_Engine__c to true prevents grade processing on insert and update
     */
    @IsTest
    static void testSkipCompletionEngineAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        Test.startTest();

        System.runAs(ADMIN_USER) {

            // Insert IENs with grade release status set AND skip flag = true
            // Expectation: completion engine is bypassed, so grade fields remain unprocessed
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 5
            ]) {
                for (Contact student : studentContacts) {
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
                    ien.reduivy__Skip_Completion_Engine__c = true;

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
        }

        // Grade fields should NOT have been populated because the engine was skipped
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c, 'Letter grade should not be set when skip flag is true');
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c, 'Grade points should not be set when skip flag is true');
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c, 'Grade result should not be set when skip flag is true');
            System.Assert.areEqual(IEN_INPROGRESS_STATUS, ien.reduivy__Enrollment_Status__c, 'Enrollment status should remain In Progress when skip flag is true');
        }

        // Now update the same IENs with skip flag still true — engine should still be bypassed
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Numerical_Grade__c = 70;
            ien.reduivy__Skip_Completion_Engine__c = true;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c, 'Letter grade should not be set when skip flag is true on update');
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c, 'Grade points should not be set when skip flag is true on update');
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c, 'Grade result should not be set when skip flag is true on update');
            System.Assert.areEqual(IEN_INPROGRESS_STATUS, ien.reduivy__Enrollment_Status__c, 'Enrollment status should remain In Progress when skip flag is true on update');
        }

        // Finally, flip the skip flag off — engine should now process normally
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Numerical_Grade__c = 69;
            ien.reduivy__Skip_Completion_Engine__c = false;
        }

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c, 'Letter grade should be resolved once skip flag is false');
            System.Assert.areEqual(69, ien.reduivy__Final_Numerical_Grade__c, 'Numerical grade should be retained');
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c, 'Grade points should be set once skip flag is false');
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c, 'Grade result should be set once skip flag is false');
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c, 'Enrollment status should update to completed pass once skip flag is false');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty that setting Skip_Completion_Engine__c to true prevents grade processing on insert and update
     */
    @IsTest
    static void testSkipCompletionEngineAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        Test.startTest();

        System.runAs(FACULTY_USER) {

            // Insert IENs with grade release status set AND skip flag = true
            // Expectation: completion engine is bypassed, so grade fields remain unprocessed
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 5
            ]) {
                for (Contact student : studentContacts) {
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
                    ien.reduivy__Skip_Completion_Engine__c = true;

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
        }

        // Grade fields should NOT have been populated because the engine was skipped
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c, 'Letter grade should not be set when skip flag is true');
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c, 'Grade points should not be set when skip flag is true');
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c, 'Grade result should not be set when skip flag is true');
            System.Assert.areEqual(IEN_INPROGRESS_STATUS, ien.reduivy__Enrollment_Status__c, 'Enrollment status should remain In Progress when skip flag is true');
        }

        // Now update the same IENs with skip flag still true — engine should still be bypassed
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Numerical_Grade__c = 70;
            ien.reduivy__Skip_Completion_Engine__c = true;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c, 'Letter grade should not be set when skip flag is true on update');
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c, 'Grade points should not be set when skip flag is true on update');
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c, 'Grade result should not be set when skip flag is true on update');
            System.Assert.areEqual(IEN_INPROGRESS_STATUS, ien.reduivy__Enrollment_Status__c, 'Enrollment status should remain In Progress when skip flag is true on update');
        }

        // Finally, flip the skip flag off — engine should now process normally
        for (reduivy__Individual_Enrollment__c ien : newIenList) {
            ien.reduivy__Numerical_Grade__c = 69;
            ien.reduivy__Skip_Completion_Engine__c = false;
        }

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(newIenList);
        }

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Final_Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('B', ien.reduivy__Letter_Grade__c, 'Letter grade should be resolved once skip flag is false');
            System.Assert.areEqual(69, ien.reduivy__Final_Numerical_Grade__c, 'Numerical grade should be retained');
            System.Assert.areEqual(3, ien.reduivy__Grade_Points__c, 'Grade points should be set once skip flag is false');
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c, 'Grade result should be set once skip flag is false');
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, ien.reduivy__Enrollment_Status__c, 'Enrollment status should update to completed pass once skip flag is false');
        }

        Test.stopTest();
    }
}