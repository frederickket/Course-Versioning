/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Test
 * @description Test class for IEN_AcademicProgressRollup_EXE
 * @changehistory
 * ISS-001818 08-01-2024 Lean - new class
 * ISS-001929 05-04-2024 Jordan - change IPR test methods
 * ISS-002486 10-06-2025 XiRouh - Updated IENs that already had grades released to use the Completed – Pass status, as credits earned are now calculated based on the enrollment status rather than the grade result
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 * ISS-002433 28-01-2026 Lean - Updated to cover the credits earned calculation for multiple attempted units in the same term
 */
@IsTest
public inherited sharing class IEN_AcademicProgressRollup_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
    static final String IEN_COMPLETED_PASS_STATUS = IEN_Helper.getCompletedPassStatuses().get(0);

    static List<String> SAMPLE_UNIT_CODES = testFactory.term1SunList;
    
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
     * @description Test as admin for new individual enrollment with enrolled status
     */
    @IsTest
    static void testNewIenWithEnrolledStatusAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, Name,
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

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(0, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(0, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(0, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(0, ipr.reduivy__Quality_Points__c);
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();
    }

    /**
     * @description Test as admin for individual enrollment with grade released
     */
    @IsTest
    static void testNewIenWithGradeReleasedAsAdmin() {
        
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
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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
                        IEN_COMPLETED_PASS_STATUS,
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
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;
                    ien.reduivy__Numerical_Grade__c = 100;

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
		}

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(5, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(60, ipr.reduivy__Quality_Points__c);
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();
    }

    /**
     * @description Test as faculty for new individual enrollment with enrolled status
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

        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(0, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(0, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(0, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(0, ipr.reduivy__Quality_Points__c);
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();
    }

    /**
     * @description Test as faculty for individual enrollment with grade released
     */
    @IsTest
    static void testNewIenWithGradeReleasedAsFaculty() {
                
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

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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
                        IEN_COMPLETED_PASS_STATUS,
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
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;
                    ien.reduivy__Numerical_Grade__c = 100;

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
		}

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(5, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(60, ipr.reduivy__Quality_Points__c);
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();
    }
	
    /**
     * @description Test as student for new individual enrollment with enrolled status
     */
	@IsTest
    static void testNewIenWithEnrolledStatusAsStudent() {
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

		User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        Test.startTest();

		System.runAs(studentUser){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(0, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(0, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(0, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(0, ipr.reduivy__Quality_Points__c);
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');
		
        Test.stopTest();
    }
	
    /**
     * @description Test as student for individual enrollment with grade released
     */
    @IsTest
    static void testNewIenWithGradeReleasedAsStudent() {
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

		User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }
        
        Test.startTest();

		System.runAs(studentUser){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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
                        IEN_COMPLETED_PASS_STATUS,
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
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;

                    newIenList.add(ien);
                }
            }

            try {
                REDU_Database_UTIL.doInsert(newIenList);
                System.Assert.fail('This should failed with FLS error.');

            } catch (Exception exp) {
                String expectedError = 'Insufficient CREATABLE access on following object(s) and field(s) - reduivy__Individual_Enrollment__c: reduivy__Grade_Release_Status__c, reduivy__Credits_Attempted__c, reduivy__Credits_Earned__c, reduivy__Grade_Points__c';
                
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'This should failed with FLS error.');
            }
		}

        Test.stopTest();
    }

    /**
     * @description Test as admin for updating individual enrollment from unreleased status to grade released
     */
    @IsTest
    static void testUpdateIenToGradeReleasedAsAdmin() {
        
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

        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
                ien.reduivy__Credits_Attempted__c = 3;
                ien.reduivy__Credits_Earned__c = 3;
                ien.reduivy__Grade_Points__c = 4;
                ien.reduivy__Numerical_Grade__c = 100;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(5, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(60, ipr.reduivy__Quality_Points__c);
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();
    }

    /**
     * @description Test as admin for updating individual enrollment with grade released to unreleased
     */
    @IsTest
    static void testUpdateReleasedIenToEnrolledStatusAsAdmin() {
        
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
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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
                        IEN_COMPLETED_PASS_STATUS,
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
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;
                    ien.reduivy__Numerical_Grade__c = 100;

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(0, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(0, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(0, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(0, ipr.reduivy__Quality_Points__c);
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();
    }

    /**
     * @description Test as faculty for updating individual enrollment from unreleased status to grade released
     */
    @IsTest
    static void testUpdateIenToGradeReleasedAsFaculty() {
                
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

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
                ien.reduivy__Credits_Attempted__c = 3;
                ien.reduivy__Credits_Earned__c = 3;
                ien.reduivy__Grade_Points__c = 4;
                ien.reduivy__Numerical_Grade__c = 100;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(5, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(60, ipr.reduivy__Quality_Points__c);
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();

    }

    /**
     * @description Test as faculty for updating individual enrollment with grade released to unreleased
     */
    @IsTest
    static void testUpdateReleasedIenToEnrolledStatusAsFaculty() {
                
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

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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
                        IEN_COMPLETED_PASS_STATUS,
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
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;
                    ien.reduivy__Numerical_Grade__c = 100;

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(0, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(0, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(0, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(0, ipr.reduivy__Quality_Points__c);
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();
    }

    /**
     * @description Test as student for updating individual enrollment from unreleased status to grade released
     */
    @IsTest
    static void testUpdateIenToGradeReleasedAsStudent() {
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

		User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        Test.startTest();

		System.runAs(studentUser){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
                ien.reduivy__Credits_Attempted__c = 3;
                ien.reduivy__Credits_Earned__c = 3;
                ien.reduivy__Grade_Points__c = 4;
            }

            try {
                REDU_Database_UTIL.doUpdate(newIenList);
                System.Assert.fail('This should failed with FLS error.');
                
            } catch (Exception exp) {
                String expectedError = 'Insufficient UPDATABLE access on following object(s) and field(s) - reduivy__Individual_Enrollment__c: reduivy__Grade_Release_Status__c, reduivy__Credits_Attempted__c, reduivy__Credits_Earned__c, reduivy__Grade_Points__c';
                
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'This should failed with FLS error.');
            }
		}

        Test.stopTest();

    }

    /**
     * @description Test as student for updating individual enrollment with grade released to unreleased
     */
    @IsTest
    static void testUpdateReleasedIenToEnrolledStatusAsStudent() {
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

		User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
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
        
        Test.startTest();

		System.runAs(studentUser){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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
                        IEN_COMPLETED_PASS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        null,
                        true
                    );

                    ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;

                    newIenList.add(ien);
                }
            }

            try {
                REDU_Database_UTIL.doInsert(newIenList);
                System.Assert.fail('This should failed with FLS error.');
                
            } catch (Exception exp) {
                String expectedError = 'Insufficient CREATABLE access on following object(s) and field(s) - reduivy__Individual_Enrollment__c: reduivy__Grade_Release_Status__c';
                
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'This should failed with FLS error.');
            }
		}

        Test.stopTest();
    }

    /**
     * @description Test as admin for individual enrollment with grade point change
     */
    @IsTest
    static void testUpdateGradeForReleasedIenAsAdmin() {
        
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
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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
                        IEN_COMPLETED_PASS_STATUS,
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
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;
                    ien.reduivy__Numerical_Grade__c = 100;
                    
                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Numerical_Grade__c = 70;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(5, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(45, ipr.reduivy__Quality_Points__c);
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();
    }

    /**
     * @description Test as faculty for individual enrollment with grade point change
     */
    @IsTest
    static void testUpdateGradeForReleasedIenAsFaculty() {
                
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

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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
                        IEN_COMPLETED_PASS_STATUS,
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
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;
                    ien.reduivy__Numerical_Grade__c = 100;

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Numerical_Grade__c = 70;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(5, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(45, ipr.reduivy__Quality_Points__c);
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();
    }

    /**
     * @description Test as admin for individual enrollment with exclude credits earned
     */
    @IsTest
    static void testExcludeCreditsEarnedForReleasedIenAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, Name,
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

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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
                        IEN_COMPLETED_PASS_STATUS,
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
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;
                    ien.reduivy__Numerical_Grade__c = 100;

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Exclude_Credits_Earned__c = true;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(5, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(0, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(60, ipr.reduivy__Quality_Points__c);
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();
    }

    /**
     * @description Test as admin for individual enrollment with exclude gpa
     */
    @IsTest
    static void testExcludeGpaForReleasedIenAsAdmin() {
        
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

        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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
                        IEN_COMPLETED_PASS_STATUS,
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
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;
                    ien.reduivy__Numerical_Grade__c = 100;

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Exclude_GPA_Calculation__c = true;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(5, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(0, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(0, ipr.reduivy__Quality_Points__c);
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();
    }

    /**
     * @description Test as faculty for individual enrollment with exclude credits earned
     */
    @IsTest
    static void testExcludeCreditsEarnedForReleasedIenAsFaculty() {
                
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

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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
                        IEN_COMPLETED_PASS_STATUS,
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
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;
                    ien.reduivy__Numerical_Grade__c = 100;

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Exclude_Credits_Earned__c = true;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(5, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(0, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(60, ipr.reduivy__Quality_Points__c);
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();
    }

    /**
     * @description Test as faculty for individual enrollment with exclude gpa
     */
    @IsTest
    static void testExcludeGpaForReleasedIenAsFaculty() {
                
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

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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
                        IEN_COMPLETED_PASS_STATUS,
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
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;
                    ien.reduivy__Numerical_Grade__c = 100;

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Exclude_GPA_Calculation__c = true;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(5, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(0, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(0, ipr.reduivy__Quality_Points__c);
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();
    }

    /**
     * @description Test as admin for changing individual enrollment IPR
     */
    @IsTest
    static void testIenChangeIprAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        //Map from contact to sample record code
        Map<Id, String> contactSampleRecordCodeMap = new Map<Id, String>();

        for (Contact studentContact : studentContacts) {
            contactSampleRecordCodeMap.put(studentContact.Id, studentContact.reduivy__Sample_Record_Code__c);
        }
        
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

        // Create a primary individual academic profile and progress for the students
        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Academic_Progress__c> newIprMap = new Map<String, reduivy__Individual_Academic_Progress__c>();

        for (Contact student: studentContacts) {
            newIpfMap.put(
                student.reduivy__Sample_Record_Code__c + '_NewProfile',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_NewProfile',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_NewProfile',
                    IPF_Helper.STATUS_ACTIVE,
                    false
                )
            );
        }

        REDU_Database_UTIL.doInsert(newIpfMap.values());

        for (reduivy__Individual_Academic_Profile__c ipf : newIpfMap.values()) {
            newIprMap.put(
                ipf.reduivy__Sample_Record_Code__c + '_' + academicTerm.reduivy__Sample_Record_Code__c + '_NEW',
                REDU_TestData_UTIL.newIndividualAcademicProgress(
                    ipf.reduivy__Sample_Record_Code__c + '_' + academicTerm.reduivy__Sample_Record_Code__c + '_NEW',
                    ipf.reduivy__Contact__c,
                    academicTerm.Id,
                    ipf.Id
                )
            );
        }

        REDU_Database_UTIL.doInsert(newIprMap.values());

        Test.startTest();

        System.runAs(ADMIN_USER){
            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 5
            ]) {
                for (Contact student : studentContacts) {
                    String ipfKey = student.reduivy__Sample_Record_Code__c + '_NewProfile';

                    reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_COMPLETED_PASS_STATUS,
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
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;
                    ien.reduivy__Numerical_Grade__c = 100;

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                String contactSampleRecordCode = contactSampleRecordCodeMap.get(ien.reduivy__Contact__c);
                String newIpfKey = contactSampleRecordCode + '_NewProfile';
                reduivy__Individual_Academic_Profile__c newIpf = newIpfMap.get(newIpfKey);
                String newIprKey = newIpf.reduivy__Sample_Record_Code__c + '_' + academicTerm.reduivy__Sample_Record_Code__c + '_NEW';
                reduivy__Individual_Academic_Progress__c newIpr = newIprMap.get(newIprKey);
                ien.reduivy__Individual_Academic_Progress__c = newIpr.Id;
                ien.reduivy__Individual_Academic_Profile__c = newIpf.Id;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        Test.stopTest();

        Boolean hasNewIpr = false;
        Boolean hasOldIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            if (String.isNotBlank(ipr.reduivy__Sample_Record_Code__c) && ipr.reduivy__Sample_Record_Code__c.contains('_NEW')) {
                hasNewIpr = true;

                System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

                System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
                System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

                System.Assert.areEqual(5, ipr.reduivy__Units_Completed__c);
                System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                System.Assert.areEqual(15, ipr.reduivy__Credits_Earned__c);
                System.Assert.areEqual(60, ipr.reduivy__Quality_Points__c);
            } else {
                hasOldIpr = true;

                System.Assert.isTrue(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There should be no individual enrollment found.');

                System.Assert.areEqual(0, ipr.reduivy__Units_Enrolled__c);
                System.Assert.areEqual(0, ipr.reduivy__Credits_Enrolled__c);

                System.Assert.areEqual(0, ipr.reduivy__Units_Completed__c);
                System.Assert.areEqual(0, ipr.reduivy__Credits_Attempted__c);
                System.Assert.areEqual(0, ipr.reduivy__Credits_Earned__c);
                System.Assert.areEqual(0, ipr.reduivy__Quality_Points__c);
            }
        }

        System.Assert.isTrue(hasNewIpr, 'No new individual academic progress found for assertion.');
        System.Assert.isTrue(hasOldIpr, 'No old individual academic progress found for assertion.');
    }
    
    /**
     * @description Test as faculty for changing individual enrollment IPR
     */
    @IsTest
    static void testIenChangeIprAsFaculty() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        //Map from contact to sample record code
        Map<Id, String> contactSampleRecordCodeMap = new Map<Id, String>();

        for (Contact studentContact : studentContacts) {
            contactSampleRecordCodeMap.put(studentContact.Id, studentContact.reduivy__Sample_Record_Code__c);
        }
        
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

        // Create a primary individual academic profile and progress for the students
        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Academic_Progress__c> newIprMap = new Map<String, reduivy__Individual_Academic_Progress__c>();

        for (Contact student: studentContacts) {
            newIpfMap.put(
                student.reduivy__Sample_Record_Code__c + '_NewProfile',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_NewProfile',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_NewProfile',
                    IPF_Helper.STATUS_ACTIVE,
                    false
                )
            );
        }

        REDU_Database_UTIL.doInsert(newIpfMap.values());

        for (reduivy__Individual_Academic_Profile__c ipf : newIpfMap.values()) {
            newIprMap.put(
                ipf.reduivy__Sample_Record_Code__c + '_' + academicTerm.reduivy__Sample_Record_Code__c + '_NEW',
                REDU_TestData_UTIL.newIndividualAcademicProgress(
                    ipf.reduivy__Sample_Record_Code__c + '_' + academicTerm.reduivy__Sample_Record_Code__c + '_NEW',
                    ipf.reduivy__Contact__c,
                    academicTerm.Id,
                    ipf.Id
                )
            );
        }

        REDU_Database_UTIL.doInsert(newIprMap.values());

        Test.startTest();

        System.runAs(FACULTY_USER){
            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 5
            ]) {
                for (Contact student : studentContacts) {
                    String ipfKey = student.reduivy__Sample_Record_Code__c + '_NewProfile';

                    reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_COMPLETED_PASS_STATUS,
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
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;
                    ien.reduivy__Numerical_Grade__c = 100;

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                String contactSampleRecordCode = contactSampleRecordCodeMap.get(ien.reduivy__Contact__c);
                String newIpfKey = contactSampleRecordCode + '_NewProfile';
                reduivy__Individual_Academic_Profile__c newIpf = newIpfMap.get(newIpfKey);
                String newIprKey = newIpf.reduivy__Sample_Record_Code__c + '_' + academicTerm.reduivy__Sample_Record_Code__c + '_NEW';
                reduivy__Individual_Academic_Progress__c newIpr = newIprMap.get(newIprKey);
                ien.reduivy__Individual_Academic_Progress__c = newIpr.Id;
                ien.reduivy__Individual_Academic_Profile__c = newIpf.Id;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        Test.stopTest();

        Boolean hasNewIpr = false;
        Boolean hasOldIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            if (String.isNotBlank(ipr.reduivy__Sample_Record_Code__c) && ipr.reduivy__Sample_Record_Code__c.contains('_NEW')) {
                hasNewIpr = true;

                System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

                System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
                System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

                System.Assert.areEqual(5, ipr.reduivy__Units_Completed__c);
                System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                System.Assert.areEqual(15, ipr.reduivy__Credits_Earned__c);
                System.Assert.areEqual(60, ipr.reduivy__Quality_Points__c);
            } else {
                hasOldIpr = true;

                System.Assert.isTrue(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There should be no individual enrollment found.');

                System.Assert.areEqual(0, ipr.reduivy__Units_Enrolled__c);
                System.Assert.areEqual(0, ipr.reduivy__Credits_Enrolled__c);

                System.Assert.areEqual(0, ipr.reduivy__Units_Completed__c);
                System.Assert.areEqual(0, ipr.reduivy__Credits_Attempted__c);
                System.Assert.areEqual(0, ipr.reduivy__Credits_Earned__c);
                System.Assert.areEqual(0, ipr.reduivy__Quality_Points__c);
            }
        }

        System.Assert.isTrue(hasNewIpr, 'No new individual academic progress found for assertion.');
        System.Assert.isTrue(hasOldIpr, 'No old individual academic progress found for assertion.');
    }

    /**
     * @description Test as student for changing individual enrollment IPR
     */
    @IsTest
    static void testIenChangeIprAsStudent() {
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

		User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
            LIMIT 1
        ];
        
        //Map from contact to sample record code
        Map<Id, String> contactSampleRecordCodeMap = new Map<Id, String>();

        for (Contact studentContact : studentContacts) {
            contactSampleRecordCodeMap.put(studentContact.Id, studentContact.reduivy__Sample_Record_Code__c);
        }
        
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

        // Create a primary individual academic profile and progress for the students
        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Academic_Progress__c> newIprMap = new Map<String, reduivy__Individual_Academic_Progress__c>();

        for (Contact student: studentContacts) {
            newIpfMap.put(
                student.reduivy__Sample_Record_Code__c + '_NewProfile',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_NewProfile',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_NewProfile',
                    IPF_Helper.STATUS_ACTIVE,
                    false
                )
            );
        }

        REDU_Database_UTIL.doInsert(newIpfMap.values());

        for (reduivy__Individual_Academic_Profile__c ipf : newIpfMap.values()) {
            newIprMap.put(
                ipf.reduivy__Sample_Record_Code__c + '_' + academicTerm.reduivy__Sample_Record_Code__c + '_NEW',
                REDU_TestData_UTIL.newIndividualAcademicProgress(
                    ipf.reduivy__Sample_Record_Code__c + '_' + academicTerm.reduivy__Sample_Record_Code__c + '_NEW',
                    ipf.reduivy__Contact__c,
                    academicTerm.Id,
                    ipf.Id
                )
            );
        }

        REDU_Database_UTIL.doInsert(newIprMap.values());

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

		//Simulate new individual enrollment for the students
        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            LIMIT 5
        ]) {
            for (Contact student : studentContacts) {
                String ipfKey = student.reduivy__Sample_Record_Code__c + '_NewProfile';

                reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    student.Id,
                    sof.Id,
                    IEN_COMPLETED_PASS_STATUS,
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
                ien.reduivy__Credits_Attempted__c = 3;
                ien.reduivy__Credits_Earned__c = 3;
                ien.reduivy__Grade_Points__c = 4;
                ien.reduivy__Numerical_Grade__c = 100;

                newIenList.add(ien);
            }
        }

        REDU_Database_UTIL.doInsert(newIenList);

        Test.startTest();

        System.runAs(studentUser){
            List<reduivy__Individual_Enrollment__c> ienUpdateList = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                String contactSampleRecordCode = contactSampleRecordCodeMap.get(ien.reduivy__Contact__c);
                String newIpfKey = contactSampleRecordCode + '_NewProfile';
                reduivy__Individual_Academic_Profile__c newIpf = newIpfMap.get(newIpfKey);
                String newIprKey = newIpf.reduivy__Sample_Record_Code__c + '_' + academicTerm.reduivy__Sample_Record_Code__c + '_NEW';
                reduivy__Individual_Academic_Progress__c newIpr = newIprMap.get(newIprKey);

                reduivy__Individual_Enrollment__c ienUpdate = new reduivy__Individual_Enrollment__c();
                ienUpdate.Id = ien.Id;
                ienUpdate.reduivy__Individual_Academic_Progress__c = newIpr.Id;
                ien.reduivy__Individual_Academic_Profile__c = newIpf.Id;
                ienUpdateList.add(ienUpdate);
            }

            REDU_Database_UTIL.doUpdate(ienUpdateList);
        }

        Test.stopTest();

        Boolean hasNewIpr = false;
        Boolean hasOldIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            if (String.isNotBlank(ipr.reduivy__Sample_Record_Code__c) && ipr.reduivy__Sample_Record_Code__c.contains('_NEW')) {
                hasNewIpr = true;

                System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

                System.Assert.areEqual(5, ipr.reduivy__Units_Enrolled__c);
                System.Assert.areEqual(15, ipr.reduivy__Credits_Enrolled__c);

                System.Assert.areEqual(5, ipr.reduivy__Units_Completed__c);
                System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                System.Assert.areEqual(15, ipr.reduivy__Credits_Earned__c);
                System.Assert.areEqual(60, ipr.reduivy__Quality_Points__c);
            } else {
                hasOldIpr = true;

                System.Assert.isTrue(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There should be no individual enrollment found.');

                System.Assert.areEqual(0, ipr.reduivy__Units_Enrolled__c);
                System.Assert.areEqual(0, ipr.reduivy__Credits_Enrolled__c);

                System.Assert.areEqual(0, ipr.reduivy__Units_Completed__c);
                System.Assert.areEqual(0, ipr.reduivy__Credits_Attempted__c);
                System.Assert.areEqual(0, ipr.reduivy__Credits_Earned__c);
                System.Assert.areEqual(0, ipr.reduivy__Quality_Points__c);
            }
        }

        System.Assert.isTrue(hasNewIpr, 'No new individual academic progress found for assertion.');
        System.Assert.isTrue(hasOldIpr, 'No old individual academic progress found for assertion.');
    }

    /**
     * @description ISS-002433 Test as admin for multiple attempts of the same unit in the same term to ensure the credits earned is only considered once
     */
    @IsTest
    static void testMultipleAttempsForSameUnitInSameTermAsAdmin() {
        
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

        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            Map<Id, Integer> reattemptIenCounter = new Map<Id, Integer>();
            Integer counter = 1;

            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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
                        IEN_COMPLETED_PASS_STATUS,
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
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;
                    ien.reduivy__Numerical_Grade__c = 100;
                    
                    newIenList.add(ien);

                    if (!reattemptIenCounter.containsKey(student.Id)) {

                        reduivy__Individual_Enrollment__c reattemptIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_reattempt',
                            student.Id,
                            sof.Id,
                            IEN_COMPLETED_PASS_STATUS,
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

                        reattemptIen.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
                        reattemptIen.reduivy__Credits_Attempted__c = 3;
                        reattemptIen.reduivy__Credits_Earned__c = 3;
                        reattemptIen.reduivy__Grade_Points__c = 4;
                        reattemptIen.reduivy__Numerical_Grade__c = 100;
                        
                        newIenList.add(reattemptIen);

                        reattemptIenCounter.put(student.Id, counter);
                    }

                    counter ++;
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                if (!ien.reduivy__Sample_Record_Code__c.endsWith('_reattempt')) {
                    //we skip updating reattempt ien to keep the grade as 100
                    ien.reduivy__Numerical_Grade__c = 70;
                }

                counter ++;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(6, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(18, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(6, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(18, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(57, ipr.reduivy__Quality_Points__c); //9 quality points x 5 + 12 quality points x 1
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as faculty for multiple attempts of the same unit in the same term to ensure the credits earned is only considered once
     */
    @IsTest
    static void testMultipleAttempsForSameUnitInSameTermAsFaculty() {
        
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

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            Map<Id, Integer> reattemptIenCounter = new Map<Id, Integer>();
            Integer counter = 1;

            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
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
                        IEN_COMPLETED_PASS_STATUS,
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
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;
                    ien.reduivy__Numerical_Grade__c = 100;
                    
                    newIenList.add(ien);

                    if (!reattemptIenCounter.containsKey(student.Id)) {

                        reduivy__Individual_Enrollment__c reattemptIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_reattempt',
                            student.Id,
                            sof.Id,
                            IEN_COMPLETED_PASS_STATUS,
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

                        reattemptIen.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
                        reattemptIen.reduivy__Credits_Attempted__c = 3;
                        reattemptIen.reduivy__Credits_Earned__c = 3;
                        reattemptIen.reduivy__Grade_Points__c = 4;
                        reattemptIen.reduivy__Numerical_Grade__c = 100;
                        
                        newIenList.add(reattemptIen);

                        reattemptIenCounter.put(student.Id, counter);
                    }

                    counter ++;
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                if (!ien.reduivy__Sample_Record_Code__c.endsWith('_reattempt')) {
                    //we skip updating reattempt ien to keep the grade as 100
                    ien.reduivy__Numerical_Grade__c = 70;
                }

                counter ++;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c =: academicTerm.Id
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(6, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(18, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(6, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(18, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(15, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(57, ipr.reduivy__Quality_Points__c); //9 quality points x 5 + 12 quality points x 1
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as admin for multiple attempts of the same unit in the different term to ensure the credits earned is calculated separately
     */
    @IsTest
    static void testMultipleAttempsForSameUnitInDifferentTermAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
        ];
        
        //Get current running term
        List<reduivy__Study_Term__c> academicTerms = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND (reduivy__Sample_Record_Code__c = 'PYT1' OR reduivy__Sample_Record_Code__c = 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ];
        
        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: SAMPLE_UNIT_CODES
            ]) {
                for (Contact student : studentContacts) {
                    reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_COMPLETED_PASS_STATUS,
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
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;
                    ien.reduivy__Numerical_Grade__c = 100;
                    
                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Numerical_Grade__c = 70;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c IN: academicTerms
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(4, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(12, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(4, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(12, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(36, ipr.reduivy__Quality_Points__c); //9 quality points x 4
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as faculty for multiple attempts of the same unit in the different term to ensure the credits earned is calculated separately
     */
    @IsTest
    static void testMultipleAttempsForSameUnitInDifferentTermAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
        ];
        
        //Get current running term
        List<reduivy__Study_Term__c> academicTerms = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND (reduivy__Sample_Record_Code__c = 'PYT1' OR reduivy__Sample_Record_Code__c = 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ];
        
        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c IN: studentContacts];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: SAMPLE_UNIT_CODES
            ]) {
                for (Contact student : studentContacts) {
                    reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_COMPLETED_PASS_STATUS,
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
                    ien.reduivy__Credits_Attempted__c = 3;
                    ien.reduivy__Credits_Earned__c = 3;
                    ien.reduivy__Grade_Points__c = 4;
                    ien.reduivy__Numerical_Grade__c = 100;
                    
                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Numerical_Grade__c = 70;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}

        Boolean hasIpr = false;

        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Units_Completed__c,
            reduivy__Units_Enrolled__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Enrolled__c,
            reduivy__Quality_Points__c,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
            )
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Contact__c IN: studentContacts
            AND reduivy__Academic_Term__c IN: academicTerms
        ]) {
            hasIpr = true;

            System.Assert.isFalse(ipr.reduivy__Individual_Enrollments__r.isEmpty(), 'There is no individual enrollment found.');

            System.Assert.areEqual(4, ipr.reduivy__Units_Enrolled__c);
            System.Assert.areEqual(12, ipr.reduivy__Credits_Enrolled__c);

            System.Assert.areEqual(4, ipr.reduivy__Units_Completed__c);
            System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
            System.Assert.areEqual(12, ipr.reduivy__Credits_Earned__c);
            System.Assert.areEqual(36, ipr.reduivy__Quality_Points__c); //9 quality points x 4
        }
		
        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');

        Test.stopTest();
    }
}