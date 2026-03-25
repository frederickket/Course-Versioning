/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for IEN_AcademicProgress_EXE
 * @changehistory
 * ISS-001816 Lean 20-12-2023 - New class
 * ISS-002743 15-12-2025 XiRouh - Added test methods to consider the IEN within the same Individual Academic Profile context and Updated test methods that create IENs to link them with IPF
 */
@isTest
public inherited sharing class IEN_AcademicProgress_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);

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
			testFactory.initStudentData(USR_Helper.getApiName(), true);

            Test.stopTest();
		}
    }

    /**
     * @description Test new individual enrollment with valid individual academic profile as admin
     */
    @IsTest
    static void testNewIenWithPrimaryIpfAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
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

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();

        System.runAs(ADMIN_USER) {
            // Create a primary individual academic profile for the students
            for (Contact student: studentContacts) {
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        IPF_Helper.STATUS_ACTIVE,
                        true
                    )
                );
            }

            insert newIpfMap.values();

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';

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
                            newIpfMap.get(ipfKey).Id,
                            true
                        )
                    );
                }
            }

            insert newIenList;
        }

        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>([
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Sample_Record_Code__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Academic_Progress__c
        ]);

        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id,
            reduivy__Academic_Term_Id__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Progress__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]);

        System.Assert.areEqual(studentContacts.size(), iprMap.size());
        System.Assert.areEqual(studentContacts.size(), ienMap.size());

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Progress__c);

            reduivy__Individual_Academic_Progress__c ipr = iprMap.get(ien.reduivy__Individual_Academic_Progress__c);
            System.Assert.isNotNull(ipr);
            System.Assert.areEqual(ien.reduivy__Contact__c, ipr.reduivy__Contact__c);
            System.Assert.areEqual(ien.reduivy__Academic_Term_Id__c, ipr.reduivy__Academic_Term__c);
            System.Assert.areEqual(newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id, ipr.reduivy__Individual_Academic_Profile__c);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test new individual enrollment with valid individual academic profile and individual academic progress as admin
     */
    @IsTest
    static void testNewIenWithPrimaryIpfandIprAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
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

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Academic_Progress__c> newIprMap = new Map<String, reduivy__Individual_Academic_Progress__c>();

        System.runAs(ADMIN_USER) {
            // Create a primary individual academic profile for the students
            for (Contact student: studentContacts) {
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        IPF_Helper.STATUS_ACTIVE,
                        true
                    )
                );
            }

            insert newIpfMap.values();

            for (reduivy__Individual_Academic_Profile__c ipf : newIpfMap.values()) {
                newIprMap.put(
                    ipf.reduivy__Sample_Record_Code__c + '_' + academicTerm.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newIndividualAcademicProgress(
                        ipf.reduivy__Sample_Record_Code__c + '_' + academicTerm.reduivy__Sample_Record_Code__c,
                        ipf.reduivy__Contact__c,
                        academicTerm.Id,
                        ipf.Id
                    )
                );
            }

            insert newIprMap.values();

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';

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
                            newIpfMap.get(ipfKey).Id,
                            true
                        )
                    );
                }
            }

            insert newIenList;
        }

        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>([
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Sample_Record_Code__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Academic_Progress__c
        ]);

        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id,
            reduivy__Academic_Term_Id__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Progress__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]);

        System.Assert.areEqual(studentContacts.size(), iprMap.size());
        System.Assert.areEqual(studentContacts.size(), ienMap.size());

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Progress__c);

            reduivy__Individual_Academic_Progress__c ipr = iprMap.get(ien.reduivy__Individual_Academic_Progress__c);
            System.Assert.isNotNull(ipr);
            System.Assert.areEqual(ien.reduivy__Contact__c, ipr.reduivy__Contact__c);
            System.Assert.areEqual(ien.reduivy__Academic_Term_Id__c, ipr.reduivy__Academic_Term__c);
            System.Assert.areEqual(newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id, ipr.reduivy__Individual_Academic_Profile__c);
            System.Assert.areEqual(newIprMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile' + '_' + academicTerm.reduivy__Sample_Record_Code__c).Id, ipr.Id);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test new individual enrollment with valid individual academic profile as faculty
     */
    @IsTest
    static void testNewIenWithPrimaryIpfAsFaculty(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
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

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();

        System.runAs(ADMIN_USER) {
            // Create a primary individual academic profile for the students
            for (Contact student: studentContacts) {
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        IPF_Helper.STATUS_ACTIVE,
                        true
                    )
                );
            }

            insert newIpfMap.values();
        }

        System.runAs(FACULTY_USER) {
            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';

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
                            newIpfMap.get(ipfKey).Id,
                            true
                        )
                    );
                }
            }

            insert newIenList;
        }

        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>([
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Sample_Record_Code__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Academic_Progress__c
        ]);

        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id,
            reduivy__Academic_Term_Id__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Progress__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]);

        System.Assert.areEqual(studentContacts.size(), iprMap.size());
        System.Assert.areEqual(studentContacts.size(), ienMap.size());

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Progress__c);

            reduivy__Individual_Academic_Progress__c ipr = iprMap.get(ien.reduivy__Individual_Academic_Progress__c);
            System.Assert.isNotNull(ipr);
            System.Assert.areEqual(ien.reduivy__Contact__c, ipr.reduivy__Contact__c);
            System.Assert.areEqual(ien.reduivy__Academic_Term_Id__c, ipr.reduivy__Academic_Term__c);
            System.Assert.areEqual(newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id, ipr.reduivy__Individual_Academic_Profile__c);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test new individual enrollment with valid individual academic profile and individual academic progress as faculty
     */
    @IsTest
    static void testNewIenWithPrimaryIpfandIprAsFaculty(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
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

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Academic_Progress__c> newIprMap = new Map<String, reduivy__Individual_Academic_Progress__c>();

        System.runAs(ADMIN_USER) {
            // Create a primary individual academic profile for the students
            for (Contact student: studentContacts) {
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        IPF_Helper.STATUS_ACTIVE,
                        true
                    )
                );
            }

            insert newIpfMap.values();

            for (reduivy__Individual_Academic_Profile__c ipf : newIpfMap.values()) {
                newIprMap.put(
                    ipf.reduivy__Sample_Record_Code__c + '_' + academicTerm.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newIndividualAcademicProgress(
                        ipf.reduivy__Sample_Record_Code__c + '_' + academicTerm.reduivy__Sample_Record_Code__c,
                        ipf.reduivy__Contact__c,
                        academicTerm.Id,
                        ipf.Id
                    )
                );
            }

            insert newIprMap.values();
        }

        System.runAs(FACULTY_USER) {
            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';

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
                            newIpfMap.get(ipfKey).Id,
                            true
                        )
                    );
                }
            }

            insert newIenList;
        }

        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>([
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Sample_Record_Code__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Academic_Progress__c
        ]);

        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id,
            reduivy__Academic_Term_Id__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Progress__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]);

        System.Assert.areEqual(studentContacts.size(), iprMap.size());
        System.Assert.areEqual(studentContacts.size(), ienMap.size());

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Progress__c);

            reduivy__Individual_Academic_Progress__c ipr = iprMap.get(ien.reduivy__Individual_Academic_Progress__c);
            System.Assert.isNotNull(ipr);
            System.Assert.areEqual(ien.reduivy__Contact__c, ipr.reduivy__Contact__c);
            System.Assert.areEqual(ien.reduivy__Academic_Term_Id__c, ipr.reduivy__Academic_Term__c);
            System.Assert.areEqual(newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id, ipr.reduivy__Individual_Academic_Profile__c);
            System.Assert.areEqual(newIprMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile' + '_' + academicTerm.reduivy__Sample_Record_Code__c).Id, ipr.Id);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test new individual enrollment with valid individual academic profile as student
     */
    @IsTest
    static void testNewIenWithPrimaryIpfAsStudent(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
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

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();

        System.runAs(ADMIN_USER) {
            // Create a primary individual academic profile for the students
            for (Contact student: studentContacts) {
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        IPF_Helper.STATUS_ACTIVE,
                        true
                    )
                );
            }

            insert newIpfMap.values();
        }

        System.runAs(studentUser) {
            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';

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
                            newIpfMap.get(ipfKey).Id,
                            true
                        )
                    );
                }
            }

            insert newIenList;
        }

        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>([
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Sample_Record_Code__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Academic_Progress__c
        ]);

        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id,
            reduivy__Academic_Term_Id__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Progress__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]);

        System.Assert.areEqual(studentContacts.size(), iprMap.size());
        System.Assert.areEqual(studentContacts.size(), ienMap.size());

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Progress__c);

            reduivy__Individual_Academic_Progress__c ipr = iprMap.get(ien.reduivy__Individual_Academic_Progress__c);
            System.Assert.isNotNull(ipr);
            System.Assert.areEqual(ien.reduivy__Contact__c, ipr.reduivy__Contact__c);
            System.Assert.areEqual(ien.reduivy__Academic_Term_Id__c, ipr.reduivy__Academic_Term__c);
            System.Assert.areEqual(newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id, ipr.reduivy__Individual_Academic_Profile__c);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test new individual enrollment with valid individual academic profile and individual academic progress as student
     */
    @IsTest
    static void testNewIenWithPrimaryIpfandIprAsStudent(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
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

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Academic_Progress__c> newIprMap = new Map<String, reduivy__Individual_Academic_Progress__c>();

        System.runAs(ADMIN_USER) {
            // Create a primary individual academic profile for the students
            for (Contact student: studentContacts) {
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        IPF_Helper.STATUS_ACTIVE,
                        true
                    )
                );
            }

            insert newIpfMap.values();

            for (reduivy__Individual_Academic_Profile__c ipf : newIpfMap.values()) {
                newIprMap.put(
                    ipf.reduivy__Sample_Record_Code__c + '_' + academicTerm.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newIndividualAcademicProgress(
                        ipf.reduivy__Sample_Record_Code__c + '_' + academicTerm.reduivy__Sample_Record_Code__c,
                        ipf.reduivy__Contact__c,
                        academicTerm.Id,
                        ipf.Id
                    )
                );
            }

            insert newIprMap.values();
        }

        System.runAs(studentUser) {
            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';

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
                            newIpfMap.get(ipfKey).Id,
                            true
                        )
                    );
                }
            }

            insert newIenList;
        }

        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>([
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Sample_Record_Code__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Academic_Progress__c
        ]);

        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id,
            reduivy__Academic_Term_Id__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Progress__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]);

        System.Assert.areEqual(studentContacts.size(), iprMap.size());
        System.Assert.areEqual(studentContacts.size(), ienMap.size());

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Progress__c);

            reduivy__Individual_Academic_Progress__c ipr = iprMap.get(ien.reduivy__Individual_Academic_Progress__c);
            System.Assert.isNotNull(ipr);
            System.Assert.areEqual(ien.reduivy__Contact__c, ipr.reduivy__Contact__c);
            System.Assert.areEqual(ien.reduivy__Academic_Term_Id__c, ipr.reduivy__Academic_Term__c);
            System.Assert.areEqual(newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id, ipr.reduivy__Individual_Academic_Profile__c);
            System.Assert.areEqual(newIprMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile' + '_' + academicTerm.reduivy__Sample_Record_Code__c).Id, ipr.Id);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test new individual enrollment with non-primary individual academic profile as admin
     * This test verifies that IEN links to IAP based on the associated IPF rather than primary profile
     */
    @IsTest
    static void testNewIenWithNonPrimaryIpfAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 2
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

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();

        System.runAs(ADMIN_USER) {
            // Create both primary and non-primary individual academic profiles for the students
            for (Contact student: studentContacts) {
                // Primary profile
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        IPF_Helper.STATUS_ACTIVE,
                        true
                    )
                );
                
                // Non-primary profile (secondary program)
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_SecondaryProfile',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_SecondaryProfile',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_SecondaryProfile',
                        IPF_Helper.STATUS_ACTIVE,
                        false  // Not primary
                    )
                );
            }

            insert newIpfMap.values();

            //Simulate new individual enrollment for the students using NON-PRIMARY profile
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    String ipfKey = student.reduivy__Sample_Record_Code__c + '_SecondaryProfile';

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
                            newIpfMap.get(ipfKey).Id,  // Using non-primary profile
                            true
                        )
                    );
                }
            }

            insert newIenList;
        }

        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>([
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Primary__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Academic_Progress__c
        ]);

        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id,
            reduivy__Academic_Term_Id__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Progress__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]);

        System.Assert.areEqual(studentContacts.size(), iprMap.size(), 'Should create IAP for each student');
        System.Assert.areEqual(studentContacts.size(), ienMap.size(), 'Should create IEN for each student');

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Progress__c, 'IEN should be linked to IAP');

            reduivy__Individual_Academic_Progress__c ipr = iprMap.get(ien.reduivy__Individual_Academic_Progress__c);
            System.Assert.isNotNull(ipr, 'IAP should exist');
            System.Assert.areEqual(ien.reduivy__Contact__c, ipr.reduivy__Contact__c, 'IAP should belong to same student');
            System.Assert.areEqual(ien.reduivy__Academic_Term_Id__c, ipr.reduivy__Academic_Term__c, 'IAP should be for same academic term');
            
            // CRITICAL ASSERTION: Verify IAP is linked to the ASSOCIATED IPF (non-primary), not primary
            System.Assert.areEqual(
                ien.reduivy__Individual_Academic_Profile__c, 
                ipr.reduivy__Individual_Academic_Profile__c,
                'IAP should be linked to the associated IPF from IEN, not primary profile'
            );
            
            System.Assert.areEqual(
                newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_SecondaryProfile').Id, 
                ipr.reduivy__Individual_Academic_Profile__c,
                'IAP should be linked to secondary (non-primary) profile'
            );
            
            // Verify it's NOT linked to the primary profile
            System.Assert.areNotEqual(
                newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id,
                ipr.reduivy__Individual_Academic_Profile__c,
                'IAP should NOT be linked to primary profile'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test updating individual enrollment to different non-primary profile creates new IAP as admin
     * This test verifies that changing the IPF on an IEN creates a new IAP for the new IPF
     */
    @IsTest
    static void testUpdateIenToNonPrimaryIpfAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
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

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        System.runAs(ADMIN_USER) {
            // Create multiple profiles for the student
            for (Contact student: studentContacts) {
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_Profile1',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_Profile1',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_Profile1',
                        IPF_Helper.STATUS_ACTIVE,
                        true
                    )
                );
                
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_Profile2',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_Profile2',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_Profile2',
                        IPF_Helper.STATUS_ACTIVE,
                        false
                    )
                );
            }

            insert newIpfMap.values();

            // Create IEN with first profile
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    String ipfKey = student.reduivy__Sample_Record_Code__c + '_Profile1';

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
                            newIpfMap.get(ipfKey).Id,
                            true
                        )
                    );
                }
            }

            insert newIenList;
            
            // Verify initial linkage to Profile1
            reduivy__Individual_Enrollment__c ienBeforeUpdate = [
                SELECT Id, reduivy__Individual_Academic_Progress__c, reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :newIenList[0].Id
            ];
            
            Id initialIapId = ienBeforeUpdate.reduivy__Individual_Academic_Progress__c;
            System.Assert.isNotNull(initialIapId, 'Initial IAP should be created');
            
            // Update IEN to use Profile2
            for (Contact student : studentContacts) {
                newIenList[0].reduivy__Individual_Academic_Profile__c = newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile2').Id;
            }
            
            update newIenList;
        }

        // Verify new IAP is created for Profile2
        List<reduivy__Individual_Academic_Progress__c> iprList = [
            SELECT Id,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Contact__c,
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Academic_Progress__c
            ORDER BY CreatedDate
        ];
        
        reduivy__Individual_Enrollment__c updatedIen = [
            SELECT Id, 
            reduivy__Individual_Academic_Progress__c, 
            reduivy__Individual_Academic_Profile__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id = :newIenList[0].Id
        ];

        System.Assert.areEqual(2, iprList.size(), 'Should have 2 IAP records (one for each profile)');
        System.Assert.isNotNull(updatedIen.reduivy__Individual_Academic_Progress__c, 'IEN should be linked to IAP');
        
        // Verify IEN is now linked to the NEW profile's IAP
        reduivy__Individual_Academic_Progress__c linkedIap = [
            SELECT Id, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Academic_Progress__c
            WHERE Id = :updatedIen.reduivy__Individual_Academic_Progress__c
        ];
        
        System.Assert.areEqual(
            updatedIen.reduivy__Individual_Academic_Profile__c,
            linkedIap.reduivy__Individual_Academic_Profile__c,
            'IAP should be linked to the updated IPF from IEN'
        );
        
        System.Assert.areEqual(
            newIpfMap.get(updatedIen.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_Profile2').Id,
            linkedIap.reduivy__Individual_Academic_Profile__c,
            'IAP should be linked to Profile2 after update'
        );

        Test.stopTest();
    }

    /**
     * @description Test new individual enrollment with non-primary individual academic profile as faculty
     * This test verifies that IEN links to IAP based on the associated IPF rather than primary profile
     */
    @IsTest
    static void testNewIenWithNonPrimaryIpfAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 2
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

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();

        System.runAs(FACULTY_USER) {
            // Create both primary and non-primary individual academic profiles for the students
            for (Contact student: studentContacts) {
                // Primary profile
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        IPF_Helper.STATUS_ACTIVE,
                        true
                    )
                );
                
                // Non-primary profile (secondary program)
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_SecondaryProfile',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_SecondaryProfile',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_SecondaryProfile',
                        IPF_Helper.STATUS_ACTIVE,
                        false  // Not primary
                    )
                );
            }

            insert newIpfMap.values();

            //Simulate new individual enrollment for the students using NON-PRIMARY profile
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    String ipfKey = student.reduivy__Sample_Record_Code__c + '_SecondaryProfile';

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
                            newIpfMap.get(ipfKey).Id,  // Using non-primary profile
                            true
                        )
                    );
                }
            }

            insert newIenList;
        }

        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>([
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Primary__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Academic_Progress__c
        ]);

        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id,
            reduivy__Academic_Term_Id__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Progress__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]);

        System.Assert.areEqual(studentContacts.size(), iprMap.size(), 'Should create IAP for each student');
        System.Assert.areEqual(studentContacts.size(), ienMap.size(), 'Should create IEN for each student');

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Progress__c, 'IEN should be linked to IAP');

            reduivy__Individual_Academic_Progress__c ipr = iprMap.get(ien.reduivy__Individual_Academic_Progress__c);
            System.Assert.isNotNull(ipr, 'IAP should exist');
            System.Assert.areEqual(ien.reduivy__Contact__c, ipr.reduivy__Contact__c, 'IAP should belong to same student');
            System.Assert.areEqual(ien.reduivy__Academic_Term_Id__c, ipr.reduivy__Academic_Term__c, 'IAP should be for same academic term');
            
            // CRITICAL ASSERTION: Verify IAP is linked to the ASSOCIATED IPF (non-primary), not primary
            System.Assert.areEqual(
                ien.reduivy__Individual_Academic_Profile__c, 
                ipr.reduivy__Individual_Academic_Profile__c,
                'IAP should be linked to the associated IPF from IEN, not primary profile'
            );
            
            System.Assert.areEqual(
                newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_SecondaryProfile').Id, 
                ipr.reduivy__Individual_Academic_Profile__c,
                'IAP should be linked to secondary (non-primary) profile'
            );
            
            // Verify it's NOT linked to the primary profile
            System.Assert.areNotEqual(
                newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id,
                ipr.reduivy__Individual_Academic_Profile__c,
                'IAP should NOT be linked to primary profile'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test updating individual enrollment to different non-primary profile creates new IAP as faculty
     * This test verifies that changing the IPF on an IEN creates a new IAP for the new IPF
     */
    @IsTest
    static void testUpdateIenToNonPrimaryIpfAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
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

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        System.runAs(FACULTY_USER) {
            // Create multiple profiles for the student
            for (Contact student: studentContacts) {
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_Profile1',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_Profile1',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_Profile1',
                        IPF_Helper.STATUS_ACTIVE,
                        true
                    )
                );
                
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_Profile2',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_Profile2',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_Profile2',
                        IPF_Helper.STATUS_ACTIVE,
                        false
                    )
                );
            }

            insert newIpfMap.values();

            // Create IEN with first profile
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    String ipfKey = student.reduivy__Sample_Record_Code__c + '_Profile1';

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
                            newIpfMap.get(ipfKey).Id,
                            true
                        )
                    );
                }
            }

            insert newIenList;
            
            // Verify initial linkage to Profile1
            reduivy__Individual_Enrollment__c ienBeforeUpdate = [
                SELECT Id, reduivy__Individual_Academic_Progress__c, reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :newIenList[0].Id
            ];
            
            Id initialIapId = ienBeforeUpdate.reduivy__Individual_Academic_Progress__c;
            System.Assert.isNotNull(initialIapId, 'Initial IAP should be created');
            
            // Update IEN to use Profile2
            for (Contact student : studentContacts) {
                newIenList[0].reduivy__Individual_Academic_Profile__c = newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile2').Id;
            }
            
            update newIenList;
        }

        // Verify new IAP is created for Profile2
        List<reduivy__Individual_Academic_Progress__c> iprList = [
            SELECT Id,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Contact__c,
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Academic_Progress__c
            ORDER BY CreatedDate
        ];
        
        reduivy__Individual_Enrollment__c updatedIen = [
            SELECT Id, 
            reduivy__Individual_Academic_Progress__c, 
            reduivy__Individual_Academic_Profile__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id = :newIenList[0].Id
        ];

        System.Assert.areEqual(2, iprList.size(), 'Should have 2 IAP records (one for each profile)');
        System.Assert.isNotNull(updatedIen.reduivy__Individual_Academic_Progress__c, 'IEN should be linked to IAP');
        
        // Verify IEN is now linked to the NEW profile's IAP
        reduivy__Individual_Academic_Progress__c linkedIap = [
            SELECT Id, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Academic_Progress__c
            WHERE Id = :updatedIen.reduivy__Individual_Academic_Progress__c
        ];
        
        System.Assert.areEqual(
            updatedIen.reduivy__Individual_Academic_Profile__c,
            linkedIap.reduivy__Individual_Academic_Profile__c,
            'IAP should be linked to the updated IPF from IEN'
        );
        
        System.Assert.areEqual(
            newIpfMap.get(updatedIen.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_Profile2').Id,
            linkedIap.reduivy__Individual_Academic_Profile__c,
            'IAP should be linked to Profile2 after update'
        );

        Test.stopTest();
    }

    /**
     * @description Test new individual enrollment with non-primary individual academic profile as student
     * This test verifies that IEN links to IAP based on the associated IPF rather than primary profile
     */
    @IsTest
    static void testNewIenWithNonPrimaryIpfAsStudent(){
                
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
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

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();

        System.runAs(studentUser) {
            // Create both primary and non-primary individual academic profiles for the students
            for (Contact student: studentContacts) {
                // Primary profile
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                        IPF_Helper.STATUS_ACTIVE,
                        true
                    )
                );
                
                // Non-primary profile (secondary program)
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_SecondaryProfile',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_SecondaryProfile',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_SecondaryProfile',
                        IPF_Helper.STATUS_ACTIVE,
                        false  // Not primary
                    )
                );
            }

            insert newIpfMap.values();

            //Simulate new individual enrollment for the students using NON-PRIMARY profile
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    String ipfKey = student.reduivy__Sample_Record_Code__c + '_SecondaryProfile';

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
                            newIpfMap.get(ipfKey).Id,  // Using non-primary profile
                            true
                        )
                    );
                }
            }

            insert newIenList;
        }

        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>([
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__r.reduivy__Primary__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Academic_Progress__c
        ]);

        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id,
            reduivy__Academic_Term_Id__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Progress__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]);

        System.Assert.areEqual(studentContacts.size(), iprMap.size(), 'Should create IAP for each student');
        System.Assert.areEqual(studentContacts.size(), ienMap.size(), 'Should create IEN for each student');

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Progress__c, 'IEN should be linked to IAP');

            reduivy__Individual_Academic_Progress__c ipr = iprMap.get(ien.reduivy__Individual_Academic_Progress__c);
            System.Assert.isNotNull(ipr, 'IAP should exist');
            System.Assert.areEqual(ien.reduivy__Contact__c, ipr.reduivy__Contact__c, 'IAP should belong to same student');
            System.Assert.areEqual(ien.reduivy__Academic_Term_Id__c, ipr.reduivy__Academic_Term__c, 'IAP should be for same academic term');
            
            // CRITICAL ASSERTION: Verify IAP is linked to the ASSOCIATED IPF (non-primary), not primary
            System.Assert.areEqual(
                ien.reduivy__Individual_Academic_Profile__c, 
                ipr.reduivy__Individual_Academic_Profile__c,
                'IAP should be linked to the associated IPF from IEN, not primary profile'
            );
            
            System.Assert.areEqual(
                newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_SecondaryProfile').Id, 
                ipr.reduivy__Individual_Academic_Profile__c,
                'IAP should be linked to secondary (non-primary) profile'
            );
            
            // Verify it's NOT linked to the primary profile
            System.Assert.areNotEqual(
                newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id,
                ipr.reduivy__Individual_Academic_Profile__c,
                'IAP should NOT be linked to primary profile'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test updating individual enrollment to different non-primary profile creates new IAP as student
     * This test verifies that changing the IPF on an IEN creates a new IAP for the new IPF
     */
    @IsTest
    static void testUpdateIenToNonPrimaryIpfAsStudent(){
                
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
		
		User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
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

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        System.runAs(studentUser) {
            // Create multiple profiles for the student
            for (Contact student: studentContacts) {
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_Profile1',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_Profile1',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_Profile1',
                        IPF_Helper.STATUS_ACTIVE,
                        true
                    )
                );
                
                newIpfMap.put(
                    student.reduivy__Sample_Record_Code__c + '_Profile2',
                    REDU_TestData_UTIL.newIndividualAcademicProfile(
                        student.reduivy__Sample_Record_Code__c + '_Profile2',
                        student.Id,
                        student.reduivy__Sample_Record_Code__c + '_Profile2',
                        IPF_Helper.STATUS_ACTIVE,
                        false
                    )
                );
            }

            insert newIpfMap.values();

            // Create IEN with first profile
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    String ipfKey = student.reduivy__Sample_Record_Code__c + '_Profile1';

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
                            newIpfMap.get(ipfKey).Id,
                            true
                        )
                    );
                }
            }

            insert newIenList;
            
            // Verify initial linkage to Profile1
            reduivy__Individual_Enrollment__c ienBeforeUpdate = [
                SELECT Id, reduivy__Individual_Academic_Progress__c, reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :newIenList[0].Id
            ];
            
            Id initialIapId = ienBeforeUpdate.reduivy__Individual_Academic_Progress__c;
            System.Assert.isNotNull(initialIapId, 'Initial IAP should be created');
            
            // Update IEN to use Profile2
            for (Contact student : studentContacts) {
                newIenList[0].reduivy__Individual_Academic_Profile__c = newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile2').Id;
            }
            
            update newIenList;
        }

        // Verify new IAP is created for Profile2
        List<reduivy__Individual_Academic_Progress__c> iprList = [
            SELECT Id,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Contact__c,
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Academic_Progress__c
            ORDER BY CreatedDate
        ];
        
        reduivy__Individual_Enrollment__c updatedIen = [
            SELECT Id, 
            reduivy__Individual_Academic_Progress__c, 
            reduivy__Individual_Academic_Profile__c,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id = :newIenList[0].Id
        ];

        System.Assert.areEqual(2, iprList.size(), 'Should have 2 IAP records (one for each profile)');
        System.Assert.isNotNull(updatedIen.reduivy__Individual_Academic_Progress__c, 'IEN should be linked to IAP');
        
        // Verify IEN is now linked to the NEW profile's IAP
        reduivy__Individual_Academic_Progress__c linkedIap = [
            SELECT Id, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Academic_Progress__c
            WHERE Id = :updatedIen.reduivy__Individual_Academic_Progress__c
        ];
        
        System.Assert.areEqual(
            updatedIen.reduivy__Individual_Academic_Profile__c,
            linkedIap.reduivy__Individual_Academic_Profile__c,
            'IAP should be linked to the updated IPF from IEN'
        );
        
        System.Assert.areEqual(
            newIpfMap.get(updatedIen.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_Profile2').Id,
            linkedIap.reduivy__Individual_Academic_Profile__c,
            'IAP should be linked to Profile2 after update'
        );

        Test.stopTest();
    }
}