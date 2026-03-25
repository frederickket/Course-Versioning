/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Test
 * @description Test class for IEN_SetCreditsAttempted_EXE
 * @changehistory
 * ISS-001822 15-01-2024 Lean - new class
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@IsTest
public inherited sharing class IEN_SetCreditsAttempted_TEST {

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
			testFactory.initStudentData(IPR_Helper.getApiName(), true);

            Test.stopTest();
		}
    }
	
    /**
     * @description Test as admin for new individual enrollment without grade released to ensure credits attempted is not set
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        Test.startTest();

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
		
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Letter_Grade__c,
            reduivy__Numerical_Grade__c,
            reduivy__Grade_Points__c,
            reduivy__Grade_Result__c,
            reduivy__Exclude_Credits_Earned__c,
            reduivy__Exclude_GPA_Calculation__c,
            reduivy__Credits_Attempted__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Numerical_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(null, ien.reduivy__Credits_Attempted__c);
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for new individual enrollment with grade released using valid numerical grade to ensure credits attempted is set
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        Test.startTest();

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
            reduivy__Credits_Attempted__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(90, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(4, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(3, ien.reduivy__Credits_Attempted__c);
        }

        Test.stopTest();
    }
	
    /**
     * @description Test as faculty for new individual enrollment without grade released to ensure credits attempted is not set
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
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
            reduivy__Credits_Attempted__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual(null, ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Numerical_Grade__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual(null, ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(null, ien.reduivy__Credits_Attempted__c);
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for new individual enrollment with grade released using valid numerical grade to ensure credits attempted is set
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

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
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
            reduivy__Credits_Attempted__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.areEqual('A', ien.reduivy__Letter_Grade__c);
            System.Assert.areEqual(90, ien.reduivy__Final_Numerical_Grade__c);
            System.Assert.areEqual(4, ien.reduivy__Grade_Points__c);
            System.Assert.areEqual('Pass', ien.reduivy__Grade_Result__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_Credits_Earned__c);
            System.Assert.areEqual(false, ien.reduivy__Exclude_GPA_Calculation__c);
            System.Assert.areEqual(3, ien.reduivy__Credits_Attempted__c);
        }

        Test.stopTest();
    }
}