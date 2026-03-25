/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Test
 * @description Test class for IEN_WaitlistDate_EXE
 * @changehistory
 * ISS-001763 27-10-2023 dblack - new class
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@IsTest
public inherited sharing class IEN_WaitlistDate_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

	static final String STUDY_UNIT = 'BUS101';

    static final String IEN_WAITLISTED_STATUS = IEN_Helper.getWaitlistedStatuses().get(0);

    static final String IEN_OPEN_STATUS = IEN_Helper.getOpenStatuses().get(0);

    static final String IEN_ENROLLEMENTREQUESTED_STATUS = IEN_Helper.getEnrollmentRequestedStatuses().get(0);

    static final String IEN_WITHDRAWN_STATUS = IEN_Helper.getWithdrawnStatuses().get(0);

    /**
     * @description Create settings and test data
     */
	@TestSetup
    static void makeData() {
		
		// Create settings
		testFactory.setupDefaultSettings();
        
        // Create test data
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
     * @description Test as admin that the individual enrollment record waitlist field is populated (before insert)
     */
    @IsTest
    static void testIenWaitlistDateBeforeInsertAsAdminUser() {
	
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
            AND reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
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
                            IEN_WAITLISTED_STATUS,
                            1,
                            null,
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
		
        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isNotNull(ien.reduivy__Waitlist_Date__c, 'The waitlist date should be set.');
        }

        Test.stopTest();
        
	}

    /**
     * @description Test as admin that the individual enrollment record waitlist field is populated (before update)
     */
    @IsTest
    static void testIenWaitlistDateBeforeUpdateAsAdminUser() {
	
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
            AND reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
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
                            null,
                            1,
                            null,
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
		
        // Check to ensure the waitlist date is not set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isNull(ien.reduivy__Waitlist_Date__c, 'The waitlist date should not be set yet.');
        }

        System.runAs(ADMIN_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WAITLISTED_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isNotNull(ien.reduivy__Waitlist_Date__c, 'The waitlist date should be set.');
        }

        System.runAs(ADMIN_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_OPEN_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is removed
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isNull(ien.reduivy__Waitlist_Date__c, 'The waitlist date should be removed.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for the 'Preserve pre-enrollment waitlist date' checkbox checked (before update)
     */
    @IsTest
    static void testIenWaitlistDatePreserveCsCheckedBeforeUpdateAsAdminUser() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        DateTime presetDateTime = Datetime.newInstance(2000, 2, 20);

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
            AND reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        reduivy__RIO_Education_Ivy_Settings__c cs = reduivy__RIO_Education_Ivy_Settings__c.getOrgDefaults();
        Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = true;

        update Cs;

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
                            IEN_ENROLLEMENTREQUESTED_STATUS,
                            1,
                            null,
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
                ien.reduivy__Waitlist_Date__c = presetDateTime;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}
		
        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(ien.reduivy__Waitlist_Date__c, presetDateTime ,'The waitlist date should be set.');
        }

        System.runAs(ADMIN_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WAITLISTED_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is not updated
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should not be updated after changed to the waitlisted status.');
        }

        System.runAs(ADMIN_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is updated
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should not be updated after changed to the withdrawn status.');
        }

        System.runAs(ADMIN_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Waitlist_Date__c = null;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is not set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isNull(ien.reduivy__Waitlist_Date__c, 'The waitlist date should not be set.');
        }

        System.runAs(ADMIN_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WAITLISTED_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is updated when it is null
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areNotEqual(ien.reduivy__Waitlist_Date__c, presetDateTime,'The waitlist date should be updated.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for the 'Preserve pre-enrollment waitlist date' checkbox unchecked (before update)
     */
    @IsTest
    static void testIenWaitlistDatePreserveCsUncheckedBeforeUpdateAsAdminUser() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        DateTime presetDateTime = Datetime.newInstance(2000, 2, 20);
        
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
            AND reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        reduivy__RIO_Education_Ivy_Settings__c cs = reduivy__RIO_Education_Ivy_Settings__c.getOrgDefaults();
        Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = false;

        update Cs;

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
                            IEN_ENROLLEMENTREQUESTED_STATUS,
                            1,
                            null,
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
                ien.reduivy__Waitlist_Date__c = presetDateTime;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}
		
        // Check to ensure the waitlist date is not set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should be set.');
        }

        System.runAs(ADMIN_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WAITLISTED_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areNotEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should be updated after changed to the waitlisted status.');
        }

        System.runAs(ADMIN_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should not be updated after changed to the withdrawn status.');
        }

        System.runAs(ADMIN_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_ENROLLEMENTREQUESTED_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areNotEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should not be updated after changed to the withdrawn status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty that the individual enrollment record waitlist field is populated (before insert)
     */
    @IsTest
    static void testIenWaitlistDateBeforeInsertAsFacultyUser() {
	        
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
            AND reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
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
                            IEN_WAITLISTED_STATUS,
                            1,
                            null,
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
		
        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isNotNull(ien.reduivy__Waitlist_Date__c, 'The waitlist date should be set.');
        }

        Test.stopTest();
        
	}

    /**
     * @description Test as faculty that the individual enrollment record waitlist field is populated (before update)
     */
    @IsTest
    static void testIenWaitlistDateBeforeUpdateAsFacultyUser() {
	        
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
            AND reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
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
                            null,
                            1,
                            null,
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
		
        // Check to ensure the waitlist date is not set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isNull(ien.reduivy__Waitlist_Date__c, 'The waitlist date should not be set yet.');
        }

        System.runAs(FACULTY_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WAITLISTED_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isNotNull(ien.reduivy__Waitlist_Date__c, 'The waitlist date should be set.');
        }

        System.runAs(FACULTY_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_OPEN_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is removed
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isNull(ien.reduivy__Waitlist_Date__c, 'The waitlist date should be removed.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for the 'Preserve pre-enrollment waitlist date' checkbox (before update)
     */
    @IsTest
    static void testIenWaitlistDatePreserveCsCheckedBeforeUpdateAsFacultyUser() {
	
        User FACULTY_USER = testFactory.getReduFacultyUser();
        DateTime presetDateTime = Datetime.newInstance(2000, 2, 20);
        
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
            AND reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        reduivy__RIO_Education_Ivy_Settings__c cs = reduivy__RIO_Education_Ivy_Settings__c.getOrgDefaults();
        Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = true;

        update Cs;

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
                            IEN_ENROLLEMENTREQUESTED_STATUS,
                            1,
                            null,
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
                ien.reduivy__Waitlist_Date__c = presetDateTime;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}
		
        // Check to ensure the waitlist date is not set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should be set.');
        }

        System.runAs(FACULTY_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WAITLISTED_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should not be updated after changed to the waitlisted status.');
        }

        System.runAs(FACULTY_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should not be updated after changed to the withdrawn status.');
        }

        System.runAs(FACULTY_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Waitlist_Date__c = null;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is not set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isNull(ien.reduivy__Waitlist_Date__c, 'The waitlist date should not be set.');
        }

        System.runAs(FACULTY_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WAITLISTED_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is updated when it is null
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areNotEqual(ien.reduivy__Waitlist_Date__c, presetDateTime,'The waitlist date should be updated.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for the 'Preserve pre-enrollment waitlist date' checkbox unchecked (before update)
     */
    @IsTest
    static void testIenWaitlistDatePreserveCsUncheckedBeforeUpdateAsFacultyUser() {
	
        User FACULTY_USER = testFactory.getReduFacultyUser();
        DateTime presetDateTime = Datetime.newInstance(2000, 2, 20);
        
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
            AND reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        reduivy__RIO_Education_Ivy_Settings__c cs = reduivy__RIO_Education_Ivy_Settings__c.getOrgDefaults();
        Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = false;

        update Cs;

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
                            IEN_ENROLLEMENTREQUESTED_STATUS,
                            1,
                            null,
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
                ien.reduivy__Waitlist_Date__c = presetDateTime;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}

        // Check to ensure the waitlist date is not set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should be set.');
        }

        System.runAs(FACULTY_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WAITLISTED_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areNotEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should be updated after changed to the waitlisted status.');
        }

        System.runAs(FACULTY_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should not be updated after changed to the withdrawn status.');
        }

        System.runAs(FACULTY_USER){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_ENROLLEMENTREQUESTED_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areNotEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should not be updated after changed to the withdrawn status.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student that the individual enrollment record waitlist field is populated (before insert)
     */
    @IsTest
    static void testIenWaitlistDateBeforeInsertAsStudentUser() {
	
        User studentUser = testFactory.getStudentUser();

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        Test.startTest();
		System.runAs(studentUser){

            //Simulate new individual enrollment for the students
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 5
            ]) {

                newIenList.add(
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        studentUser.ContactId + '_' + sof.reduivy__Sample_Record_Code__c,
                        studentUser.ContactId,
                        sof.Id,
                        IEN_WAITLISTED_STATUS,
                        1,
                        null,
                        null,
                        null,
                        null,
                        3,
                        null,
                        studentIpfs[0].Id,
                        true
                    )
                );
            }

            REDU_Database_UTIL.doInsert(newIenList);
		}
		
        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isNotNull(ien.reduivy__Waitlist_Date__c, 'The waitlist date should be set.');
        }

        Test.stopTest();
        
	}

    /**
     * @description Test as student that the individual enrollment record waitlist field is populated (before update)
     */
    @IsTest
    static void testIenWaitlistDateBeforeUpdateAsStudentUser() {
	
        User studentUser = testFactory.getStudentUser();

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        Test.startTest();
		System.runAs(studentUser){

            //Simulate new individual enrollment for the students
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 5
            ]) {
                newIenList.add(
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        studentUser.ContactId + '_' + sof.reduivy__Sample_Record_Code__c,
                        studentUser.ContactId,
                        sof.Id,
                        null,
                        1,
                        null,
                        null,
                        null,
                        null,
                        3,
                        null,
                        studentIpfs[0].Id,
                        true
                    )
                );
            }

            REDU_Database_UTIL.doInsert(newIenList);
		}
		
        // Check to ensure the waitlist date is not set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isNull(ien.reduivy__Waitlist_Date__c, 'The waitlist date should not be set yet.');
        }

        System.runAs(studentUser){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WAITLISTED_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isNotNull(ien.reduivy__Waitlist_Date__c, 'The waitlist date should be set.');
        }

        System.runAs(studentUser){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_OPEN_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is removed
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isNull(ien.reduivy__Waitlist_Date__c, 'The waitlist date should be removed.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for the 'Preserve pre-enrollment waitlist date' checkbox (before update)
     */
    @IsTest
    static void testIenWaitlistDatePreserveCsCheckedBeforeUpdateAsStudentUser() {
	
        User studentUser = testFactory.getStudentUser();
        DateTime presetDateTime = Datetime.newInstance(2000, 2, 20);
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        reduivy__RIO_Education_Ivy_Settings__c cs = reduivy__RIO_Education_Ivy_Settings__c.getOrgDefaults();
        Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = true;

        update Cs;

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        Test.startTest();
		System.runAs(studentUser){

            //Simulate new individual enrollment for the students
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 5
            ]) {
                newIenList.add(
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        studentUser.ContactId + '_' + sof.reduivy__Sample_Record_Code__c,
                        studentUser.ContactId,
                        sof.Id,
                        null,
                        1,
                        null,
                        null,
                        null,
                        null,
                        3,
                        null,
                        studentIpfs[0].Id,
                        true
                    )
                );
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Waitlist_Date__c = presetDateTime;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}
		
        // Check to ensure the waitlist date is not set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should be set.');
        }

        System.runAs(studentUser){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WAITLISTED_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should not be updated after changed to the waitlisted status.');
        }

        System.runAs(studentUser){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should not be updated after changed to the withdrawn status.');
        }

        System.runAs(studentUser){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Waitlist_Date__c = null;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is not set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isNull(ien.reduivy__Waitlist_Date__c, 'The waitlist date should not be set.');
        }

        System.runAs(studentUser){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WAITLISTED_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is updated when it is null
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areNotEqual(ien.reduivy__Waitlist_Date__c, presetDateTime,'The waitlist date should be updated.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for the 'Preserve pre-enrollment waitlist date' checkbox unchecked (before update)
     */
    @IsTest
    static void testIenWaitlistDatePreserveCsUncheckedBeforeUpdateAsStudentUser() {
	
        User studentUser = testFactory.getStudentUser();
        DateTime presetDateTime = Datetime.newInstance(2000, 2, 20);

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();

        reduivy__RIO_Education_Ivy_Settings__c cs = reduivy__RIO_Education_Ivy_Settings__c.getOrgDefaults();
        Cs.reduivy__Preserve_pre_enrollment_waitlist_date__c = false;

        update Cs;

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        Test.startTest();
		System.runAs(studentUser){

            //Simulate new individual enrollment for the students
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                LIMIT 5
            ]) {
                newIenList.add(
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        studentUser.ContactId + '_' + sof.reduivy__Sample_Record_Code__c,
                        studentUser.ContactId,
                        sof.Id,
                        null,
                        1,
                        null,
                        null,
                        null,
                        null,
                        3,
                        null,
                        studentIpfs[0].Id,
                        true
                    )
                );
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Waitlist_Date__c = presetDateTime;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}
		
        // Check to ensure the waitlist date is not set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should be set.');
        }

        System.runAs(studentUser){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WAITLISTED_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areNotEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should be updated after changed to the waitlisted status.');
        }

        System.runAs(studentUser){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should not be updated after changed to the withdrawn status.');
        }

        System.runAs(studentUser){
            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Enrollment_Status__c = IEN_ENROLLEMENTREQUESTED_STATUS;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
        }

        // Check to ensure the waitlist date is set
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Waitlist_Date__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areNotEqual(ien.reduivy__Waitlist_Date__c, presetDateTime, 'The waitlist date should not be updated after changed to the withdrawn status.');
        }

        Test.stopTest();
    }
}