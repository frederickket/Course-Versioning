/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Test
 * @description Test class for IPR_CalculateGPA_EXE
 * @changehistory
 * ISS-001836 10-01-2024 Lean - new class
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@IsTest
public inherited sharing class IPR_CalculateGPA_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';
    
    static final List<String> IPE_INPROGRESS_STATUSES = IPE_Helper.getInProgressStatuses();
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

        	testFactory.initMasterData(SPS_Helper.getApiName());
            testFactory.initOfferingData(SOF_Helper.getApiName());
			testFactory.initStudentData(IPR_Helper.getApiName(), false);

            List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
            for (Contact student : testFactory.students.values()) {
				String sampleRecordCode = student.Id + '_' + testFactory.studyPlans.get(STUDY_PLAN).Id;
				Id contactId = student.Id;
				Id studyProgramId = testFactory.studyPrograms.get(STUDY_PROGRAM).Id;
				Id studyPlanId = testFactory.studyPlans.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = null;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = IPE_INPROGRESS_STATUSES.get(0);
				Id idvAcademicProfileId = testFactory.individualAcademicProfiles.get(student.reduivy__Sample_Record_Code__c).Id;
				reduivy__Individual_Program_Enrollment__c ipe = 
					REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
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

            Test.stopTest();
		}
    }
	
    /**
     * @description Test as admin for gpa calculation with newly enrolled individual enrollment
     */
    @IsTest
    static void testIprWithNewEnrolledIenAsAdmin() {
        
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
                            null,
                            true
                        )
                    );
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
		}
		
        Set<Id> iprIds = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Individual_Academic_Progress__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isTrue(String.isNotBlank(ien.reduivy__Individual_Academic_Progress__c), 'No individual academic progress linked.');
            iprIds.add(ien.reduivy__Individual_Academic_Progress__c);
        }

        Boolean hasIpr = false;
        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Cumulative_GPA__c,
            reduivy__Cumulative_Credits_Attempted__c,
            reduivy__Cumulative_Quality_Points__c
            FROM reduivy__Individual_Academic_Progress__c
            WHERE Id IN: iprIds
        ]) {

            System.Assert.areEqual(0, ipr.reduivy__Cumulative_GPA__c);

            hasIpr = true;
        }

        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');
    }

    /**
     * @description Test as admin for gpa calculation with newly grade released individual enrollment
     */
    @IsTest
    static void testIpfWithNewGradeReleasedIenAsAdmin() {
        
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
                        null,
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
		
        Set<Id> iprIds = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Individual_Academic_Progress__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isTrue(String.isNotBlank(ien.reduivy__Individual_Academic_Progress__c), 'No individual academic progress linked.');
            iprIds.add(ien.reduivy__Individual_Academic_Progress__c);
        }

        Boolean hasIpr = false;
        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Cumulative_GPA__c,
            reduivy__Cumulative_Credits_Attempted__c,
            reduivy__Cumulative_Quality_Points__c
            FROM reduivy__Individual_Academic_Progress__c
            WHERE Id IN: iprIds
        ]) {

            System.Assert.areEqual(4, ipr.reduivy__Cumulative_GPA__c);

            hasIpr = true;
        }

        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');
    }

    /**
     * @description Test as faculty for gpa calculation with newly enrolled individual enrollment
     */
    @IsTest
    static void testIprWithNewEnrolledIenAsFaculty() {
                
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
                            null,
                            true
                        )
                    );
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
		}
		
        Set<Id> iprIds = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Individual_Academic_Progress__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isTrue(String.isNotBlank(ien.reduivy__Individual_Academic_Progress__c), 'No individual academic progress linked.');
            iprIds.add(ien.reduivy__Individual_Academic_Progress__c);
        }

        Boolean hasIpr = false;
        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Cumulative_GPA__c,
            reduivy__Cumulative_Credits_Attempted__c,
            reduivy__Cumulative_Quality_Points__c
            FROM reduivy__Individual_Academic_Progress__c
            WHERE Id IN: iprIds
        ]) {

            System.Assert.areEqual(0, ipr.reduivy__Cumulative_GPA__c);

            hasIpr = true;
        }

        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');
    }

    /**
     * @description Test as faculty for gpa calculation with newly grade released individual enrollment
     */
    @IsTest
    static void testIprWithNewGradeReleasedIenAsFaculty() {
                
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
                        null,
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
		
        Set<Id> iprIds = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Individual_Academic_Progress__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: newIenList
        ]) {
            System.Assert.isTrue(String.isNotBlank(ien.reduivy__Individual_Academic_Progress__c), 'No individual academic progress linked.');
            iprIds.add(ien.reduivy__Individual_Academic_Progress__c);
        }

        Boolean hasIpr = false;
        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Cumulative_GPA__c,
            reduivy__Cumulative_Credits_Attempted__c,
            reduivy__Cumulative_Quality_Points__c
            FROM reduivy__Individual_Academic_Progress__c
            WHERE Id IN: iprIds
        ]) {

            System.Assert.areEqual(4, ipr.reduivy__Cumulative_GPA__c);

            hasIpr = true;
        }

        System.Assert.isTrue(hasIpr, 'No individual academic progress found for assertion.');
    }
	
}