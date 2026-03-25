/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Test
 * @description Test class for IPR_CumulativeAndRollup_EXE, there is a sibling test class IPR_CumulativeAndRollup_Reattempt_TEST.
 * @changehistory
 * ISS-001836 03-01-2024 Lean - new class
 * ISS-002486 11-06-2025 XiRouh - Updated to assign the completed status according to the grade result
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 * ISS-002433 28-01-2026 Lean - Added new test cases to ensure the GPA and CGPA are correct with Exclude GPA setting = true/false
 */
@IsTest
public inherited sharing class IPR_CumulativeAndRollup_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';
    
    static final List<String> IPE_INPROGRESS_STATUSES = IPE_Helper.getInProgressStatuses();
    static final String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
    static final String IEN_COMPLETED_PASS_STATUS = IEN_Helper.getCompletedPassStatuses().get(0);
    static final String IEN_COMPLETED_FAIL_STATUS = IEN_Helper.getCompletedFailStatuses().get(0);

    static List<String> T1_SAMPLE_UNIT_CODES = testFactory.term1SunList;
    static List<String> T2_SAMPLE_UNIT_CODES = testFactory.term2SunList;
    static List<String> T3_SAMPLE_UNIT_CODES = testFactory.term3SunList;

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
			testFactory.initStudentData(USR_Helper.getApiName(), true);

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
				Id idvAcademicProfileId = null;
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
     * @description Test as admin for new individual enrollment with enrolled status
     */
    @IsTest
    static void testNewIenWithEnrolledStatusAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);

        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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

        Boolean hasIpf = false;

        for (reduivy__Individual_Academic_Profile__c ipf : [SELECT Id,
            (
                SELECT Id,
                reduivy__Units_Completed__c,
                reduivy__Units_Enrolled__c,
                reduivy__Credits_Attempted__c,
                reduivy__Credits_Earned__c,
                reduivy__Credits_Enrolled__c,
                reduivy__Quality_Points__c,
                reduivy__Cumulative_Units_Completed__c,
                reduivy__Cumulative_Units_Enrolled__c,
                reduivy__Cumulative_Credits_Attempted__c,
                reduivy__Cumulative_Credits_Earned__c,
                reduivy__Cumulative_Credits_Enrolled__c,
                reduivy__Cumulative_Quality_Points__c,
                reduivy__Cumulative_GPA__c,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__r
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
            )
            FROM reduivy__Individual_Academic_Profile__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]) {
            if (ipf.reduivy__Individual_Academic_Progress__r.isEmpty()) {
                continue;
            }

            hasIpf = true;
            System.Assert.areEqual(2, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                    Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                    Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                    Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                    Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                    
                    cumUnitsCompleted += unitsCompleted;
                    cumUnitsEnrolled += unitsEnrolled;
                    cumCreditsAttempted += creditsAttempted;
                    cumCreditsEarned += creditsEarned;
                    cumCreditsEnrolled += creditsEnrolled;
                    cumQualityPoints += qualityPoints;
                    
                    System.Assert.areEqual(cumUnitsCompleted, ipr.reduivy__Cumulative_Units_Completed__c);
                    System.Assert.areEqual(cumUnitsEnrolled, ipr.reduivy__Cumulative_Units_Enrolled__c);
                    System.Assert.areEqual(cumCreditsAttempted, ipr.reduivy__Cumulative_Credits_Attempted__c);
                    System.Assert.areEqual(cumCreditsEarned, ipr.reduivy__Cumulative_Credits_Earned__c);
                    System.Assert.areEqual(cumCreditsEnrolled, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                    System.Assert.areEqual(cumQualityPoints, ipr.reduivy__Cumulative_Quality_Points__c);

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }
            }

            System.Assert.areEqual(0, cumUnitsCompleted);
            System.Assert.areEqual(4, cumUnitsEnrolled);
            System.Assert.areEqual(0, cumCreditsAttempted);
            System.Assert.areEqual(0, cumCreditsEarned);
            System.Assert.areEqual(12, cumCreditsEnrolled);
            System.Assert.areEqual(0, cumQualityPoints);

        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

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
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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
                    ien.reduivy__Numerical_Grade__c = 100;

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
		}

        Boolean hasIpf = false;

        for (reduivy__Individual_Academic_Profile__c ipf : [SELECT Id,
            (
                SELECT Id,
                reduivy__Units_Completed__c,
                reduivy__Units_Enrolled__c,
                reduivy__Credits_Attempted__c,
                reduivy__Credits_Earned__c,
                reduivy__Credits_Enrolled__c,
                reduivy__Quality_Points__c,
                reduivy__Cumulative_Units_Completed__c,
                reduivy__Cumulative_Units_Enrolled__c,
                reduivy__Cumulative_Credits_Attempted__c,
                reduivy__Cumulative_Credits_Earned__c,
                reduivy__Cumulative_Credits_Enrolled__c,
                reduivy__Cumulative_Quality_Points__c,
                reduivy__Cumulative_GPA__c,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__r
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
            )
            FROM reduivy__Individual_Academic_Profile__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]) {
            if (ipf.reduivy__Individual_Academic_Progress__r.isEmpty()) {
                continue;
            }

            hasIpf = true;
            System.Assert.areEqual(2, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                    Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                    Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                    Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                    Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                    
                    cumUnitsCompleted += unitsCompleted;
                    cumUnitsEnrolled += unitsEnrolled;
                    cumCreditsAttempted += creditsAttempted;
                    cumCreditsEarned += creditsEarned;
                    cumCreditsEnrolled += creditsEnrolled;
                    cumQualityPoints += qualityPoints;
                    
                    System.Assert.areEqual(cumUnitsCompleted, ipr.reduivy__Cumulative_Units_Completed__c);
                    System.Assert.areEqual(cumUnitsEnrolled, ipr.reduivy__Cumulative_Units_Enrolled__c);
                    System.Assert.areEqual(cumCreditsAttempted, ipr.reduivy__Cumulative_Credits_Attempted__c);
                    System.Assert.areEqual(cumCreditsEarned, ipr.reduivy__Cumulative_Credits_Earned__c);
                    System.Assert.areEqual(cumCreditsEnrolled, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                    System.Assert.areEqual(cumQualityPoints, ipr.reduivy__Cumulative_Quality_Points__c);

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }
            }

            System.Assert.areEqual(4, cumUnitsCompleted);
            System.Assert.areEqual(4, cumUnitsEnrolled);
            System.Assert.areEqual(12, cumCreditsAttempted);
            System.Assert.areEqual(12, cumCreditsEarned);
            System.Assert.areEqual(12, cumCreditsEnrolled);
            System.Assert.areEqual(48, cumQualityPoints);

        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

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
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);

        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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

        Boolean hasIpf = false;

        for (reduivy__Individual_Academic_Profile__c ipf : [SELECT Id,
            (
                SELECT Id,
                reduivy__Units_Completed__c,
                reduivy__Units_Enrolled__c,
                reduivy__Credits_Attempted__c,
                reduivy__Credits_Earned__c,
                reduivy__Credits_Enrolled__c,
                reduivy__Quality_Points__c,
                reduivy__Cumulative_Units_Completed__c,
                reduivy__Cumulative_Units_Enrolled__c,
                reduivy__Cumulative_Credits_Attempted__c,
                reduivy__Cumulative_Credits_Earned__c,
                reduivy__Cumulative_Credits_Enrolled__c,
                reduivy__Cumulative_Quality_Points__c,
                reduivy__Cumulative_GPA__c,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__r
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
            )
            FROM reduivy__Individual_Academic_Profile__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]) {
            if (ipf.reduivy__Individual_Academic_Progress__r.isEmpty()) {
                continue;
            }

            hasIpf = true;
            System.Assert.areEqual(2, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                    Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                    Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                    Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                    Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                    
                    cumUnitsCompleted += unitsCompleted;
                    cumUnitsEnrolled += unitsEnrolled;
                    cumCreditsAttempted += creditsAttempted;
                    cumCreditsEarned += creditsEarned;
                    cumCreditsEnrolled += creditsEnrolled;
                    cumQualityPoints += qualityPoints;
                    
                    System.Assert.areEqual(cumUnitsCompleted, ipr.reduivy__Cumulative_Units_Completed__c);
                    System.Assert.areEqual(cumUnitsEnrolled, ipr.reduivy__Cumulative_Units_Enrolled__c);
                    System.Assert.areEqual(cumCreditsAttempted, ipr.reduivy__Cumulative_Credits_Attempted__c);
                    System.Assert.areEqual(cumCreditsEarned, ipr.reduivy__Cumulative_Credits_Earned__c);
                    System.Assert.areEqual(cumCreditsEnrolled, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                    System.Assert.areEqual(cumQualityPoints, ipr.reduivy__Cumulative_Quality_Points__c);

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }
            }

            System.Assert.areEqual(0, cumUnitsCompleted);
            System.Assert.areEqual(4, cumUnitsEnrolled);
            System.Assert.areEqual(0, cumCreditsAttempted);
            System.Assert.areEqual(0, cumCreditsEarned);
            System.Assert.areEqual(12, cumCreditsEnrolled);
            System.Assert.areEqual(0, cumQualityPoints);

        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

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
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);
        
        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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
                    ien.reduivy__Numerical_Grade__c = 100;

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
		}

        Boolean hasIpf = false;

        for (reduivy__Individual_Academic_Profile__c ipf : [SELECT Id,
            (
                SELECT Id,
                reduivy__Units_Completed__c,
                reduivy__Units_Enrolled__c,
                reduivy__Credits_Attempted__c,
                reduivy__Credits_Earned__c,
                reduivy__Credits_Enrolled__c,
                reduivy__Quality_Points__c,
                reduivy__Cumulative_Units_Completed__c,
                reduivy__Cumulative_Units_Enrolled__c,
                reduivy__Cumulative_Credits_Attempted__c,
                reduivy__Cumulative_Credits_Earned__c,
                reduivy__Cumulative_Credits_Enrolled__c,
                reduivy__Cumulative_Quality_Points__c,
                reduivy__Cumulative_GPA__c,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__r
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
            )
            FROM reduivy__Individual_Academic_Profile__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]) {
            if (ipf.reduivy__Individual_Academic_Progress__r.isEmpty()) {
                continue;
            }

            hasIpf = true;
            System.Assert.areEqual(2, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                    Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                    Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                    Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                    Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                    
                    cumUnitsCompleted += unitsCompleted;
                    cumUnitsEnrolled += unitsEnrolled;
                    cumCreditsAttempted += creditsAttempted;
                    cumCreditsEarned += creditsEarned;
                    cumCreditsEnrolled += creditsEnrolled;
                    cumQualityPoints += qualityPoints;
                    
                    System.Assert.areEqual(cumUnitsCompleted, ipr.reduivy__Cumulative_Units_Completed__c);
                    System.Assert.areEqual(cumUnitsEnrolled, ipr.reduivy__Cumulative_Units_Enrolled__c);
                    System.Assert.areEqual(cumCreditsAttempted, ipr.reduivy__Cumulative_Credits_Attempted__c);
                    System.Assert.areEqual(cumCreditsEarned, ipr.reduivy__Cumulative_Credits_Earned__c);
                    System.Assert.areEqual(cumCreditsEnrolled, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                    System.Assert.areEqual(cumQualityPoints, ipr.reduivy__Cumulative_Quality_Points__c);

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }
            }

            System.Assert.areEqual(4, cumUnitsCompleted);
            System.Assert.areEqual(4, cumUnitsEnrolled);
            System.Assert.areEqual(12, cumCreditsAttempted);
            System.Assert.areEqual(12, cumCreditsEarned);
            System.Assert.areEqual(12, cumCreditsEnrolled);
            System.Assert.areEqual(48, cumQualityPoints);

        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

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
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);
        
        Test.startTest();

		System.runAs(studentUser){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);
		}

        Boolean hasIpf = false;

        for (reduivy__Individual_Academic_Profile__c ipf : [SELECT Id,
            (
                SELECT Id,
                reduivy__Units_Completed__c,
                reduivy__Units_Enrolled__c,
                reduivy__Credits_Attempted__c,
                reduivy__Credits_Earned__c,
                reduivy__Credits_Enrolled__c,
                reduivy__Quality_Points__c,
                reduivy__Cumulative_Units_Completed__c,
                reduivy__Cumulative_Units_Enrolled__c,
                reduivy__Cumulative_Credits_Attempted__c,
                reduivy__Cumulative_Credits_Earned__c,
                reduivy__Cumulative_Credits_Enrolled__c,
                reduivy__Cumulative_Quality_Points__c,
                reduivy__Cumulative_GPA__c,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__r
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
            )
            FROM reduivy__Individual_Academic_Profile__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]) {
            if (ipf.reduivy__Individual_Academic_Progress__r.isEmpty()) {
                continue;
            }

            hasIpf = true;
            System.Assert.areEqual(2, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                    Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                    Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                    Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                    Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                    
                    cumUnitsCompleted += unitsCompleted;
                    cumUnitsEnrolled += unitsEnrolled;
                    cumCreditsAttempted += creditsAttempted;
                    cumCreditsEarned += creditsEarned;
                    cumCreditsEnrolled += creditsEnrolled;
                    cumQualityPoints += qualityPoints;
                    
                    System.Assert.areEqual(cumUnitsCompleted, ipr.reduivy__Cumulative_Units_Completed__c);
                    System.Assert.areEqual(cumUnitsEnrolled, ipr.reduivy__Cumulative_Units_Enrolled__c);
                    System.Assert.areEqual(cumCreditsAttempted, ipr.reduivy__Cumulative_Credits_Attempted__c);
                    System.Assert.areEqual(cumCreditsEarned, ipr.reduivy__Cumulative_Credits_Earned__c);
                    System.Assert.areEqual(cumCreditsEnrolled, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                    System.Assert.areEqual(cumQualityPoints, ipr.reduivy__Cumulative_Quality_Points__c);

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }
            }

            System.Assert.areEqual(0, cumUnitsCompleted);
            System.Assert.areEqual(4, cumUnitsEnrolled);
            System.Assert.areEqual(0, cumCreditsAttempted);
            System.Assert.areEqual(0, cumCreditsEarned);
            System.Assert.areEqual(12, cumCreditsEnrolled);
            System.Assert.areEqual(0, cumQualityPoints);

        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

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
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);
        
        Test.startTest();

		System.runAs(studentUser){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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
                    ien.reduivy__Numerical_Grade__c = 100;

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
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);

        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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

            List<reduivy__Individual_Enrollment__c> ienListToUpdate = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                reduivy__Individual_Enrollment__c ienToUpdate = new reduivy__Individual_Enrollment__c (
                    Id = ien.Id,
                    reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                    reduivy__Credits_Attempted__c = 3,
                    reduivy__Credits_Earned__c = 3,
                    reduivy__Grade_Points__c = 4,
                    reduivy__Numerical_Grade__c = 100
                );

                ienListToUpdate.add(ienToUpdate);
            }

            REDU_Database_UTIL.doUpdate(ienListToUpdate);
		}

        Boolean hasIpf = false;

        for (reduivy__Individual_Academic_Profile__c ipf : [SELECT Id,
            (
                SELECT Id,
                reduivy__Units_Completed__c,
                reduivy__Units_Enrolled__c,
                reduivy__Credits_Attempted__c,
                reduivy__Credits_Earned__c,
                reduivy__Credits_Enrolled__c,
                reduivy__Quality_Points__c,
                reduivy__Cumulative_Units_Completed__c,
                reduivy__Cumulative_Units_Enrolled__c,
                reduivy__Cumulative_Credits_Attempted__c,
                reduivy__Cumulative_Credits_Earned__c,
                reduivy__Cumulative_Credits_Enrolled__c,
                reduivy__Cumulative_Quality_Points__c,
                reduivy__Cumulative_GPA__c,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__r
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
            )
            FROM reduivy__Individual_Academic_Profile__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]) {
            if (ipf.reduivy__Individual_Academic_Progress__r.isEmpty()) {
                continue;
            }

            hasIpf = true;
            System.Assert.areEqual(2, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                    Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                    Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                    Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                    Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                    
                    cumUnitsCompleted += unitsCompleted;
                    cumUnitsEnrolled += unitsEnrolled;
                    cumCreditsAttempted += creditsAttempted;
                    cumCreditsEarned += creditsEarned;
                    cumCreditsEnrolled += creditsEnrolled;
                    cumQualityPoints += qualityPoints;
                    
                    System.Assert.areEqual(cumUnitsCompleted, ipr.reduivy__Cumulative_Units_Completed__c);
                    System.Assert.areEqual(cumUnitsEnrolled, ipr.reduivy__Cumulative_Units_Enrolled__c);
                    System.Assert.areEqual(cumCreditsAttempted, ipr.reduivy__Cumulative_Credits_Attempted__c);
                    System.Assert.areEqual(cumCreditsEarned, ipr.reduivy__Cumulative_Credits_Earned__c);
                    System.Assert.areEqual(cumCreditsEnrolled, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                    System.Assert.areEqual(cumQualityPoints, ipr.reduivy__Cumulative_Quality_Points__c);

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }
            }

            System.Assert.areEqual(4, cumUnitsCompleted);
            System.Assert.areEqual(4, cumUnitsEnrolled);
            System.Assert.areEqual(12, cumCreditsAttempted);
            System.Assert.areEqual(12, cumCreditsEarned);
            System.Assert.areEqual(12, cumCreditsEnrolled);
            System.Assert.areEqual(48, cumQualityPoints);

        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

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
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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

        Boolean hasIpf = false;

        for (reduivy__Individual_Academic_Profile__c ipf : [SELECT Id,
            (
                SELECT Id,
                reduivy__Units_Completed__c,
                reduivy__Units_Enrolled__c,
                reduivy__Credits_Attempted__c,
                reduivy__Credits_Earned__c,
                reduivy__Credits_Enrolled__c,
                reduivy__Quality_Points__c,
                reduivy__Cumulative_Units_Completed__c,
                reduivy__Cumulative_Units_Enrolled__c,
                reduivy__Cumulative_Credits_Attempted__c,
                reduivy__Cumulative_Credits_Earned__c,
                reduivy__Cumulative_Credits_Enrolled__c,
                reduivy__Cumulative_Quality_Points__c,
                reduivy__Cumulative_GPA__c,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__r
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
            )
            FROM reduivy__Individual_Academic_Profile__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]) {
            if (ipf.reduivy__Individual_Academic_Progress__r.isEmpty()) {
                continue;
            }

            hasIpf = true;
            System.Assert.areEqual(2, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                    Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                    Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                    Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                    Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                    
                    cumUnitsCompleted += unitsCompleted;
                    cumUnitsEnrolled += unitsEnrolled;
                    cumCreditsAttempted += creditsAttempted;
                    cumCreditsEarned += creditsEarned;
                    cumCreditsEnrolled += creditsEnrolled;
                    cumQualityPoints += qualityPoints;
                    
                    System.Assert.areEqual(cumUnitsCompleted, ipr.reduivy__Cumulative_Units_Completed__c);
                    System.Assert.areEqual(cumUnitsEnrolled, ipr.reduivy__Cumulative_Units_Enrolled__c);
                    System.Assert.areEqual(cumCreditsAttempted, ipr.reduivy__Cumulative_Credits_Attempted__c);
                    System.Assert.areEqual(cumCreditsEarned, ipr.reduivy__Cumulative_Credits_Earned__c);
                    System.Assert.areEqual(cumCreditsEnrolled, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                    System.Assert.areEqual(cumQualityPoints, ipr.reduivy__Cumulative_Quality_Points__c);

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }
            }

            System.Assert.areEqual(0, cumUnitsCompleted);
            System.Assert.areEqual(4, cumUnitsEnrolled);
            System.Assert.areEqual(0, cumCreditsAttempted);
            System.Assert.areEqual(0, cumCreditsEarned);
            System.Assert.areEqual(12, cumCreditsEnrolled);
            System.Assert.areEqual(0, cumQualityPoints);

        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

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
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);

        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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

            List<reduivy__Individual_Enrollment__c> ienListToUpdate = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ien : newIenList) {

                reduivy__Individual_Enrollment__c ienToUpdate = new reduivy__Individual_Enrollment__c (
                    Id = ien.Id,    
                    reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                    reduivy__Credits_Attempted__c = 3,
                    reduivy__Credits_Earned__c = 3,
                    reduivy__Grade_Points__c = 4,
                    reduivy__Numerical_Grade__c = 100
                );

                ienListToUpdate.add(ienToUpdate);
            }

            REDU_Database_UTIL.doUpdate(ienListToUpdate);
		}

        Boolean hasIpf = false;

        for (reduivy__Individual_Academic_Profile__c ipf : [SELECT Id,
            (
                SELECT Id,
                reduivy__Units_Completed__c,
                reduivy__Units_Enrolled__c,
                reduivy__Credits_Attempted__c,
                reduivy__Credits_Earned__c,
                reduivy__Credits_Enrolled__c,
                reduivy__Quality_Points__c,
                reduivy__Cumulative_Units_Completed__c,
                reduivy__Cumulative_Units_Enrolled__c,
                reduivy__Cumulative_Credits_Attempted__c,
                reduivy__Cumulative_Credits_Earned__c,
                reduivy__Cumulative_Credits_Enrolled__c,
                reduivy__Cumulative_Quality_Points__c,
                reduivy__Cumulative_GPA__c,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__r
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
            )
            FROM reduivy__Individual_Academic_Profile__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]) {
            if (ipf.reduivy__Individual_Academic_Progress__r.isEmpty()) {
                continue;
            }

            hasIpf = true;
            System.Assert.areEqual(2, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                    Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                    Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                    Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                    Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                    
                    cumUnitsCompleted += unitsCompleted;
                    cumUnitsEnrolled += unitsEnrolled;
                    cumCreditsAttempted += creditsAttempted;
                    cumCreditsEarned += creditsEarned;
                    cumCreditsEnrolled += creditsEnrolled;
                    cumQualityPoints += qualityPoints;
                    
                    System.Assert.areEqual(cumUnitsCompleted, ipr.reduivy__Cumulative_Units_Completed__c);
                    System.Assert.areEqual(cumUnitsEnrolled, ipr.reduivy__Cumulative_Units_Enrolled__c);
                    System.Assert.areEqual(cumCreditsAttempted, ipr.reduivy__Cumulative_Credits_Attempted__c);
                    System.Assert.areEqual(cumCreditsEarned, ipr.reduivy__Cumulative_Credits_Earned__c);
                    System.Assert.areEqual(cumCreditsEnrolled, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                    System.Assert.areEqual(cumQualityPoints, ipr.reduivy__Cumulative_Quality_Points__c);

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }
            }

            System.Assert.areEqual(4, cumUnitsCompleted);
            System.Assert.areEqual(4, cumUnitsEnrolled);
            System.Assert.areEqual(12, cumCreditsAttempted);
            System.Assert.areEqual(12, cumCreditsEarned);
            System.Assert.areEqual(12, cumCreditsEnrolled);
            System.Assert.areEqual(48, cumQualityPoints);

        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

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
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);
        
        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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

        Boolean hasIpf = false;

        for (reduivy__Individual_Academic_Profile__c ipf : [SELECT Id,
            (
                SELECT Id,
                reduivy__Units_Completed__c,
                reduivy__Units_Enrolled__c,
                reduivy__Credits_Attempted__c,
                reduivy__Credits_Earned__c,
                reduivy__Credits_Enrolled__c,
                reduivy__Quality_Points__c,
                reduivy__Cumulative_Units_Completed__c,
                reduivy__Cumulative_Units_Enrolled__c,
                reduivy__Cumulative_Credits_Attempted__c,
                reduivy__Cumulative_Credits_Earned__c,
                reduivy__Cumulative_Credits_Enrolled__c,
                reduivy__Cumulative_Quality_Points__c,
                reduivy__Cumulative_GPA__c,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__r
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
            )
            FROM reduivy__Individual_Academic_Profile__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]) {
            if (ipf.reduivy__Individual_Academic_Progress__r.isEmpty()) {
                continue;
            }

            hasIpf = true;
            System.Assert.areEqual(2, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                    Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                    Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                    Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                    Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                    
                    cumUnitsCompleted += unitsCompleted;
                    cumUnitsEnrolled += unitsEnrolled;
                    cumCreditsAttempted += creditsAttempted;
                    cumCreditsEarned += creditsEarned;
                    cumCreditsEnrolled += creditsEnrolled;
                    cumQualityPoints += qualityPoints;
                    
                    System.Assert.areEqual(cumUnitsCompleted, ipr.reduivy__Cumulative_Units_Completed__c);
                    System.Assert.areEqual(cumUnitsEnrolled, ipr.reduivy__Cumulative_Units_Enrolled__c);
                    System.Assert.areEqual(cumCreditsAttempted, ipr.reduivy__Cumulative_Credits_Attempted__c);
                    System.Assert.areEqual(cumCreditsEarned, ipr.reduivy__Cumulative_Credits_Earned__c);
                    System.Assert.areEqual(cumCreditsEnrolled, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                    System.Assert.areEqual(cumQualityPoints, ipr.reduivy__Cumulative_Quality_Points__c);

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }
            }

            System.Assert.areEqual(0, cumUnitsCompleted);
            System.Assert.areEqual(4, cumUnitsEnrolled);
            System.Assert.areEqual(0, cumCreditsAttempted);
            System.Assert.areEqual(0, cumCreditsEarned);
            System.Assert.areEqual(12, cumCreditsEnrolled);
            System.Assert.areEqual(0, cumQualityPoints);

        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

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
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);

        Test.startTest();

		System.runAs(studentUser){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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

            List<reduivy__Individual_Enrollment__c> ienListToUpdate = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ien : newIenList) {

                reduivy__Individual_Enrollment__c ienToUpdate = new reduivy__Individual_Enrollment__c (
                    reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                    reduivy__Credits_Attempted__c = 3,
                    reduivy__Credits_Earned__c = 3,
                    reduivy__Grade_Points__c = 4,
                    reduivy__Numerical_Grade__c = 100
                );

                ienListToUpdate.add(ienToUpdate);
            }

            try {
                REDU_Database_UTIL.doUpdate(ienListToUpdate);
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
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);
        
        Test.startTest();

		System.runAs(studentUser){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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
                    ien.reduivy__Numerical_Grade__c = 100;

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
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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
                    ien.reduivy__Numerical_Grade__c = 100;

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Points__c = 3;
                ien.reduivy__Numerical_Grade__c = 70;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}

        Boolean hasIpf = false;

        for (reduivy__Individual_Academic_Profile__c ipf : [SELECT Id,
            (
                SELECT Id,
                reduivy__Units_Completed__c,
                reduivy__Units_Enrolled__c,
                reduivy__Credits_Attempted__c,
                reduivy__Credits_Earned__c,
                reduivy__Credits_Enrolled__c,
                reduivy__Quality_Points__c,
                reduivy__Cumulative_Units_Completed__c,
                reduivy__Cumulative_Units_Enrolled__c,
                reduivy__Cumulative_Credits_Attempted__c,
                reduivy__Cumulative_Credits_Earned__c,
                reduivy__Cumulative_Credits_Enrolled__c,
                reduivy__Cumulative_Quality_Points__c,
                reduivy__Cumulative_GPA__c,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__r
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
            )
            FROM reduivy__Individual_Academic_Profile__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]) {
            if (ipf.reduivy__Individual_Academic_Progress__r.isEmpty()) {
                continue;
            }

            hasIpf = true;
            System.Assert.areEqual(2, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                    Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                    Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                    Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                    Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                    
                    cumUnitsCompleted += unitsCompleted;
                    cumUnitsEnrolled += unitsEnrolled;
                    cumCreditsAttempted += creditsAttempted;
                    cumCreditsEarned += creditsEarned;
                    cumCreditsEnrolled += creditsEnrolled;
                    cumQualityPoints += qualityPoints;
                    
                    System.Assert.areEqual(cumUnitsCompleted, ipr.reduivy__Cumulative_Units_Completed__c);
                    System.Assert.areEqual(cumUnitsEnrolled, ipr.reduivy__Cumulative_Units_Enrolled__c);
                    System.Assert.areEqual(cumCreditsAttempted, ipr.reduivy__Cumulative_Credits_Attempted__c);
                    System.Assert.areEqual(cumCreditsEarned, ipr.reduivy__Cumulative_Credits_Earned__c);
                    System.Assert.areEqual(cumCreditsEnrolled, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                    System.Assert.areEqual(cumQualityPoints, ipr.reduivy__Cumulative_Quality_Points__c);

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }
            }

            System.Assert.areEqual(4, cumUnitsCompleted);
            System.Assert.areEqual(4, cumUnitsEnrolled);
            System.Assert.areEqual(12, cumCreditsAttempted);
            System.Assert.areEqual(12, cumCreditsEarned);
            System.Assert.areEqual(12, cumCreditsEnrolled);
            System.Assert.areEqual(36, cumQualityPoints);

        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

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
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);
        
        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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
                    ien.reduivy__Numerical_Grade__c = 100;

                    newIenList.add(ien);
                }
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Points__c = 3;
                ien.reduivy__Numerical_Grade__c = 70;
            }

            REDU_Database_UTIL.doUpdate(newIenList);
		}

        Boolean hasIpf = false;

        for (reduivy__Individual_Academic_Profile__c ipf : [SELECT Id,
            (
                SELECT Id,
                reduivy__Units_Completed__c,
                reduivy__Units_Enrolled__c,
                reduivy__Credits_Attempted__c,
                reduivy__Credits_Earned__c,
                reduivy__Credits_Enrolled__c,
                reduivy__Quality_Points__c,
                reduivy__Cumulative_Units_Completed__c,
                reduivy__Cumulative_Units_Enrolled__c,
                reduivy__Cumulative_Credits_Attempted__c,
                reduivy__Cumulative_Credits_Earned__c,
                reduivy__Cumulative_Credits_Enrolled__c,
                reduivy__Cumulative_Quality_Points__c,
                reduivy__Cumulative_GPA__c,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__r
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
            )
            FROM reduivy__Individual_Academic_Profile__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]) {
            if (ipf.reduivy__Individual_Academic_Progress__r.isEmpty()) {
                continue;
            }

            hasIpf = true;
            System.Assert.areEqual(2, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                    Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                    Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                    Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                    Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                    
                    cumUnitsCompleted += unitsCompleted;
                    cumUnitsEnrolled += unitsEnrolled;
                    cumCreditsAttempted += creditsAttempted;
                    cumCreditsEarned += creditsEarned;
                    cumCreditsEnrolled += creditsEnrolled;
                    cumQualityPoints += qualityPoints;
                    
                    System.Assert.areEqual(cumUnitsCompleted, ipr.reduivy__Cumulative_Units_Completed__c);
                    System.Assert.areEqual(cumUnitsEnrolled, ipr.reduivy__Cumulative_Units_Enrolled__c);
                    System.Assert.areEqual(cumCreditsAttempted, ipr.reduivy__Cumulative_Credits_Attempted__c);
                    System.Assert.areEqual(cumCreditsEarned, ipr.reduivy__Cumulative_Credits_Earned__c);
                    System.Assert.areEqual(cumCreditsEnrolled, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                    System.Assert.areEqual(cumQualityPoints, ipr.reduivy__Cumulative_Quality_Points__c);

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }
            }

            System.Assert.areEqual(4, cumUnitsCompleted);
            System.Assert.areEqual(4, cumUnitsEnrolled);
            System.Assert.areEqual(12, cumCreditsAttempted);
            System.Assert.areEqual(12, cumCreditsEarned);
            System.Assert.areEqual(12, cumCreditsEnrolled);
            System.Assert.areEqual(36, cumQualityPoints);

        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description Test as admin for individual enrollment with exclude credits earned
     */
    @IsTest
    static void testExcludeCreditsEarnedForReleasedIenAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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

        Boolean hasIpf = false;

        for (reduivy__Individual_Academic_Profile__c ipf : [SELECT Id,
            (
                SELECT Id,
                reduivy__Units_Completed__c,
                reduivy__Units_Enrolled__c,
                reduivy__Credits_Attempted__c,
                reduivy__Credits_Earned__c,
                reduivy__Credits_Enrolled__c,
                reduivy__Quality_Points__c,
                reduivy__Cumulative_Units_Completed__c,
                reduivy__Cumulative_Units_Enrolled__c,
                reduivy__Cumulative_Credits_Attempted__c,
                reduivy__Cumulative_Credits_Earned__c,
                reduivy__Cumulative_Credits_Enrolled__c,
                reduivy__Cumulative_Quality_Points__c,
                reduivy__Cumulative_GPA__c,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__r
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
            )
            FROM reduivy__Individual_Academic_Profile__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]) {
            if (ipf.reduivy__Individual_Academic_Progress__r.isEmpty()) {
                continue;
            }

            hasIpf = true;
            System.Assert.areEqual(2, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                    Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                    Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                    Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                    Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                    
                    cumUnitsCompleted += unitsCompleted;
                    cumUnitsEnrolled += unitsEnrolled;
                    cumCreditsAttempted += creditsAttempted;
                    cumCreditsEarned += creditsEarned;
                    cumCreditsEnrolled += creditsEnrolled;
                    cumQualityPoints += qualityPoints;
                    
                    System.Assert.areEqual(cumUnitsCompleted, ipr.reduivy__Cumulative_Units_Completed__c);
                    System.Assert.areEqual(cumUnitsEnrolled, ipr.reduivy__Cumulative_Units_Enrolled__c);
                    System.Assert.areEqual(cumCreditsAttempted, ipr.reduivy__Cumulative_Credits_Attempted__c);
                    System.Assert.areEqual(cumCreditsEarned, ipr.reduivy__Cumulative_Credits_Earned__c);
                    System.Assert.areEqual(cumCreditsEnrolled, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                    System.Assert.areEqual(cumQualityPoints, ipr.reduivy__Cumulative_Quality_Points__c);

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }
            }

            System.Assert.areEqual(4, cumUnitsCompleted);
            System.Assert.areEqual(4, cumUnitsEnrolled);
            System.Assert.areEqual(12, cumCreditsAttempted);
            System.Assert.areEqual(0, cumCreditsEarned);
            System.Assert.areEqual(12, cumCreditsEnrolled);
            System.Assert.areEqual(48, cumQualityPoints);

        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

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
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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

        Boolean hasIpf = false;

        for (reduivy__Individual_Academic_Profile__c ipf : [SELECT Id,
            (
                SELECT Id,
                reduivy__Units_Completed__c,
                reduivy__Units_Enrolled__c,
                reduivy__Credits_Attempted__c,
                reduivy__Credits_Earned__c,
                reduivy__Credits_Enrolled__c,
                reduivy__Quality_Points__c,
                reduivy__Cumulative_Units_Completed__c,
                reduivy__Cumulative_Units_Enrolled__c,
                reduivy__Cumulative_Credits_Attempted__c,
                reduivy__Cumulative_Credits_Earned__c,
                reduivy__Cumulative_Credits_Enrolled__c,
                reduivy__Cumulative_Quality_Points__c,
                reduivy__Cumulative_GPA__c,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__r
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
            )
            FROM reduivy__Individual_Academic_Profile__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]) {
            if (ipf.reduivy__Individual_Academic_Progress__r.isEmpty()) {
                continue;
            }

            hasIpf = true;
            System.Assert.areEqual(2, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                    Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                    Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                    Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                    Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                    
                    cumUnitsCompleted += unitsCompleted;
                    cumUnitsEnrolled += unitsEnrolled;
                    cumCreditsAttempted += creditsAttempted;
                    cumCreditsEarned += creditsEarned;
                    cumCreditsEnrolled += creditsEnrolled;
                    cumQualityPoints += qualityPoints;
                    
                    System.Assert.areEqual(cumUnitsCompleted, ipr.reduivy__Cumulative_Units_Completed__c);
                    System.Assert.areEqual(cumUnitsEnrolled, ipr.reduivy__Cumulative_Units_Enrolled__c);
                    System.Assert.areEqual(cumCreditsAttempted, ipr.reduivy__Cumulative_Credits_Attempted__c);
                    System.Assert.areEqual(cumCreditsEarned, ipr.reduivy__Cumulative_Credits_Earned__c);
                    System.Assert.areEqual(cumCreditsEnrolled, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                    System.Assert.areEqual(cumQualityPoints, ipr.reduivy__Cumulative_Quality_Points__c);

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }
            }

            System.Assert.areEqual(4, cumUnitsCompleted);
            System.Assert.areEqual(4, cumUnitsEnrolled);
            System.Assert.areEqual(0, cumCreditsAttempted);
            System.Assert.areEqual(12, cumCreditsEarned);
            System.Assert.areEqual(12, cumCreditsEnrolled);
            System.Assert.areEqual(0, cumQualityPoints);

        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

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
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);
        
        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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

        Boolean hasIpf = false;

        for (reduivy__Individual_Academic_Profile__c ipf : [SELECT Id,
            (
                SELECT Id,
                reduivy__Units_Completed__c,
                reduivy__Units_Enrolled__c,
                reduivy__Credits_Attempted__c,
                reduivy__Credits_Earned__c,
                reduivy__Credits_Enrolled__c,
                reduivy__Quality_Points__c,
                reduivy__Cumulative_Units_Completed__c,
                reduivy__Cumulative_Units_Enrolled__c,
                reduivy__Cumulative_Credits_Attempted__c,
                reduivy__Cumulative_Credits_Earned__c,
                reduivy__Cumulative_Credits_Enrolled__c,
                reduivy__Cumulative_Quality_Points__c,
                reduivy__Cumulative_GPA__c,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__r
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
            )
            FROM reduivy__Individual_Academic_Profile__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]) {
            if (ipf.reduivy__Individual_Academic_Progress__r.isEmpty()) {
                continue;
            }

            hasIpf = true;
            System.Assert.areEqual(2, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                    Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                    Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                    Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                    Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                    
                    cumUnitsCompleted += unitsCompleted;
                    cumUnitsEnrolled += unitsEnrolled;
                    cumCreditsAttempted += creditsAttempted;
                    cumCreditsEarned += creditsEarned;
                    cumCreditsEnrolled += creditsEnrolled;
                    cumQualityPoints += qualityPoints;
                    
                    System.Assert.areEqual(cumUnitsCompleted, ipr.reduivy__Cumulative_Units_Completed__c);
                    System.Assert.areEqual(cumUnitsEnrolled, ipr.reduivy__Cumulative_Units_Enrolled__c);
                    System.Assert.areEqual(cumCreditsAttempted, ipr.reduivy__Cumulative_Credits_Attempted__c);
                    System.Assert.areEqual(cumCreditsEarned, ipr.reduivy__Cumulative_Credits_Earned__c);
                    System.Assert.areEqual(cumCreditsEnrolled, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                    System.Assert.areEqual(cumQualityPoints, ipr.reduivy__Cumulative_Quality_Points__c);

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }
            }

            System.Assert.areEqual(4, cumUnitsCompleted);
            System.Assert.areEqual(4, cumUnitsEnrolled);
            System.Assert.areEqual(12, cumCreditsAttempted);
            System.Assert.areEqual(0, cumCreditsEarned);
            System.Assert.areEqual(12, cumCreditsEnrolled);
            System.Assert.areEqual(48, cumQualityPoints);

        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

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
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);
        
        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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

        Boolean hasIpf = false;

        for (reduivy__Individual_Academic_Profile__c ipf : [SELECT Id,
            (
                SELECT Id,
                reduivy__Units_Completed__c,
                reduivy__Units_Enrolled__c,
                reduivy__Credits_Attempted__c,
                reduivy__Credits_Earned__c,
                reduivy__Credits_Enrolled__c,
                reduivy__Quality_Points__c,
                reduivy__Cumulative_Units_Completed__c,
                reduivy__Cumulative_Units_Enrolled__c,
                reduivy__Cumulative_Credits_Attempted__c,
                reduivy__Cumulative_Credits_Earned__c,
                reduivy__Cumulative_Credits_Enrolled__c,
                reduivy__Cumulative_Quality_Points__c,
                reduivy__Cumulative_GPA__c,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__r
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
            )
            FROM reduivy__Individual_Academic_Profile__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]) {
            if (ipf.reduivy__Individual_Academic_Progress__r.isEmpty()) {
                continue;
            }

            hasIpf = true;
            System.Assert.areEqual(2, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                    Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                    Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                    Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                    Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                    
                    cumUnitsCompleted += unitsCompleted;
                    cumUnitsEnrolled += unitsEnrolled;
                    cumCreditsAttempted += creditsAttempted;
                    cumCreditsEarned += creditsEarned;
                    cumCreditsEnrolled += creditsEnrolled;
                    cumQualityPoints += qualityPoints;
                    
                    System.Assert.areEqual(cumUnitsCompleted, ipr.reduivy__Cumulative_Units_Completed__c);
                    System.Assert.areEqual(cumUnitsEnrolled, ipr.reduivy__Cumulative_Units_Enrolled__c);
                    System.Assert.areEqual(cumCreditsAttempted, ipr.reduivy__Cumulative_Credits_Attempted__c);
                    System.Assert.areEqual(cumCreditsEarned, ipr.reduivy__Cumulative_Credits_Earned__c);
                    System.Assert.areEqual(cumCreditsEnrolled, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                    System.Assert.areEqual(cumQualityPoints, ipr.reduivy__Cumulative_Quality_Points__c);

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }
            }

            System.Assert.areEqual(4, cumUnitsCompleted);
            System.Assert.areEqual(4, cumUnitsEnrolled);
            System.Assert.areEqual(0, cumCreditsAttempted);
            System.Assert.areEqual(12, cumCreditsEarned);
            System.Assert.areEqual(12, cumCreditsEnrolled);
            System.Assert.areEqual(0, cumQualityPoints);

        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description Test as admin for deleting individual enrollment and individual academic progress
     */
    @IsTest
    static void testDeleteIprAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c LIKE 'PYT%'
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 2
        ]);

        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE 
                ((reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT1' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('BUS101', 'BUS102')) 
                OR 
                (reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = 'PYT2' AND reduivy__Study_Unit__r.reduivy__Unit_Code__c IN ('MKT101', 'MKT102')))
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
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

            List<reduivy__Individual_Enrollment__c> ienListToUpdate = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ien : newIenList) {

                reduivy__Individual_Enrollment__c ienToUpdate = new reduivy__Individual_Enrollment__c (
                    Id = ien.Id,
                    reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                    reduivy__Credits_Attempted__c = 3,
                    reduivy__Credits_Earned__c = 3,
                    reduivy__Grade_Points__c = 4,
                    reduivy__Numerical_Grade__c = 100
                );

                ienListToUpdate.add(ienToUpdate);
            }

            REDU_Database_UTIL.doUpdate(ienListToUpdate);
		}

        Boolean hasIpf = false;

        for (reduivy__Individual_Academic_Profile__c ipf : [SELECT Id,
            (
                SELECT Id,
                reduivy__Units_Completed__c,
                reduivy__Units_Enrolled__c,
                reduivy__Credits_Attempted__c,
                reduivy__Credits_Earned__c,
                reduivy__Credits_Enrolled__c,
                reduivy__Quality_Points__c,
                reduivy__Cumulative_Units_Completed__c,
                reduivy__Cumulative_Units_Enrolled__c,
                reduivy__Cumulative_Credits_Attempted__c,
                reduivy__Cumulative_Credits_Earned__c,
                reduivy__Cumulative_Credits_Enrolled__c,
                reduivy__Cumulative_Quality_Points__c,
                reduivy__Cumulative_GPA__c,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__r
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
            )
            FROM reduivy__Individual_Academic_Profile__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]) {
            if (ipf.reduivy__Individual_Academic_Progress__r.isEmpty()) {
                continue;
            }

            hasIpf = true;
            System.Assert.areEqual(2, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                    Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                    Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                    Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                    Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                    
                    cumUnitsCompleted += unitsCompleted;
                    cumUnitsEnrolled += unitsEnrolled;
                    cumCreditsAttempted += creditsAttempted;
                    cumCreditsEarned += creditsEarned;
                    cumCreditsEnrolled += creditsEnrolled;
                    cumQualityPoints += qualityPoints;
                    
                    System.Assert.areEqual(cumUnitsCompleted, ipr.reduivy__Cumulative_Units_Completed__c);
                    System.Assert.areEqual(cumUnitsEnrolled, ipr.reduivy__Cumulative_Units_Enrolled__c);
                    System.Assert.areEqual(cumCreditsAttempted, ipr.reduivy__Cumulative_Credits_Attempted__c);
                    System.Assert.areEqual(cumCreditsEarned, ipr.reduivy__Cumulative_Credits_Earned__c);
                    System.Assert.areEqual(cumCreditsEnrolled, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                    System.Assert.areEqual(cumQualityPoints, ipr.reduivy__Cumulative_Quality_Points__c);

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }
            }

            System.Assert.areEqual(4, cumUnitsCompleted);
            System.Assert.areEqual(4, cumUnitsEnrolled);
            System.Assert.areEqual(12, cumCreditsAttempted);
            System.Assert.areEqual(12, cumCreditsEarned);
            System.Assert.areEqual(12, cumCreditsEnrolled);
            System.Assert.areEqual(48, cumQualityPoints);

        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        System.runAs(ADMIN_USER) {
            //simulate the deletion of related individual enrollment and the first individual academic progress to force the recalculation of cumulative info on second academic progress
            List<reduivy__Individual_Enrollment__c> iensToDelete = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Academic_Term_Id__c =: academicTerms.values().get(0).Id];
            REDU_Database_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Session_Enrollment__c WHERE reduivy__Individual_Enrollment__c IN: iensToDelete]);
            REDU_Database_UTIL.doDelete(iensToDelete);
            REDU_Database_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Academic_Term__c =: academicTerms.values().get(0).Id]);
            REDU_Database_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Academic_Progress__c WHERE reduivy__Academic_Term__c =: academicTerms.values().get(0).Id]);
        }

        for (reduivy__Individual_Academic_Profile__c ipf : [SELECT Id,
            (
                SELECT Id,
                reduivy__Units_Completed__c,
                reduivy__Units_Enrolled__c,
                reduivy__Credits_Attempted__c,
                reduivy__Credits_Earned__c,
                reduivy__Credits_Enrolled__c,
                reduivy__Quality_Points__c,
                reduivy__Cumulative_Units_Completed__c,
                reduivy__Cumulative_Units_Enrolled__c,
                reduivy__Cumulative_Credits_Attempted__c,
                reduivy__Cumulative_Credits_Earned__c,
                reduivy__Cumulative_Credits_Enrolled__c,
                reduivy__Cumulative_Quality_Points__c,
                reduivy__Cumulative_GPA__c,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__r
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
            )
            FROM reduivy__Individual_Academic_Profile__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]) {

            if (ipf.reduivy__Individual_Academic_Progress__r.isEmpty()) {
                continue;
            }

            System.Assert.areEqual(1, ipf.reduivy__Individual_Academic_Progress__r.size(), 'There is no individual academic progress found.');
            
            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                    Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                    Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                    Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                    Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                    
                    cumUnitsCompleted += unitsCompleted;
                    cumUnitsEnrolled += unitsEnrolled;
                    cumCreditsAttempted += creditsAttempted;
                    cumCreditsEarned += creditsEarned;
                    cumCreditsEnrolled += creditsEnrolled;
                    cumQualityPoints += qualityPoints;
                    
                    System.Assert.areEqual(cumUnitsCompleted, ipr.reduivy__Cumulative_Units_Completed__c);
                    System.Assert.areEqual(cumUnitsEnrolled, ipr.reduivy__Cumulative_Units_Enrolled__c);
                    System.Assert.areEqual(cumCreditsAttempted, ipr.reduivy__Cumulative_Credits_Attempted__c);
                    System.Assert.areEqual(cumCreditsEarned, ipr.reduivy__Cumulative_Credits_Earned__c);
                    System.Assert.areEqual(cumCreditsEnrolled, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                    System.Assert.areEqual(cumQualityPoints, ipr.reduivy__Cumulative_Quality_Points__c);

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }
            }

            System.Assert.areEqual(2, cumUnitsCompleted);
            System.Assert.areEqual(2, cumUnitsEnrolled);
            System.Assert.areEqual(6, cumCreditsAttempted);
            System.Assert.areEqual(6, cumCreditsEarned);
            System.Assert.areEqual(6, cumCreditsEnrolled);
            System.Assert.areEqual(24, cumQualityPoints);

        }

        Test.stopTest();
    }

}