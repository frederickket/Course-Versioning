/**
 * @author      WDCi (Lean)
 * @date        Feb 2026
 * @group       Test
 * @description Test class for IPR_CumulativeAndRollup_EXE with reattempt scenario
 * @changehistory
 * ISS-002786 03-02-2026 Lean - moved ISS-002433 test scenario here
 */
@IsTest
public inherited sharing class IPR_CumulativeAndRollup_Reattempt_TEST {

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
     * @description ISS-002433 Test as admin for unit that fail in term 1 and pass in term 3 (reattempt)
     */
    @IsTest
    static void testReattemptFailInT1PassInT3AsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - fail - 0
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 0;
                ien1.reduivy__Grade_Points__c = 0;
                ien1.reduivy__Numerical_Grade__c = 0;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 3;
                ien9.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 100 - reattempt
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 4;
                ien12.reduivy__Numerical_Grade__c = 100;
                
                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(30, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(2.5, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(9, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(30, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(2.5, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(21, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(78, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(39, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(117, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.5455, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as admin for unit that fail in term 1 and pass in term 3 (reattempt) with Exclude GPA setting = false
     */
    @IsTest
    static void testReattemptFailInT1PassInT3WithInclusionAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //disable Exclude GPA setting
        reduivy__RIO_Education_Ivy_Settings__c settings = REDU_AppSetting_UTIL.getOrgDefaultSetting();
        settings.reduivy__Exclude_GPA_For_Repeated_Unit__c = false;

        update settings;

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - fail - 0
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 0;
                ien1.reduivy__Grade_Points__c = 0;
                ien1.reduivy__Numerical_Grade__c = 0;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 3;
                ien9.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 100 - reattempt
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 4;
                ien12.reduivy__Numerical_Grade__c = 100;
                
                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(30, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(2.5, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(9, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(30, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(2.5, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(21, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(78, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(39, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(117, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as admin for unit that pass in term 1 and reattempt with better grade in term 3
     */
    @IsTest
    static void testReattemptBetterGradeInT3AsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 3;
                ien1.reduivy__Grade_Points__c = 3;
                ien1.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 3;
                ien9.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 100 - reattempt
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 4;
                ien12.reduivy__Numerical_Grade__c = 100;
                
                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(39, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(39, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(87, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.625, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(39, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(117, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.5455, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as admin for unit that pass in term 1 and reattempt with better grade in term 3 with Exclude GPA setting = false
     */
    @IsTest
    static void testReattemptBetterGradeInT3WithInclusionAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //disable Exclude GPA setting
        reduivy__RIO_Education_Ivy_Settings__c settings = REDU_AppSetting_UTIL.getOrgDefaultSetting();
        settings.reduivy__Exclude_GPA_For_Repeated_Unit__c = false;

        update settings;

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 3;
                ien1.reduivy__Grade_Points__c = 3;
                ien1.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 3;
                ien9.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 100 - reattempt
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 4;
                ien12.reduivy__Numerical_Grade__c = 100;
                
                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(39, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(39, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(87, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.625, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(39, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(126, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.5, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as admin for unit that pass in term 1 with better grade and reattempt with lower grade in term 3
     */
    @IsTest
    static void testReattemptBetterGradeInT1LowerGradeInT3AsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 3;
                ien1.reduivy__Grade_Points__c = 3;
                ien1.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 3;
                ien9.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 60 - reattempt
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 4;
                ien12.reduivy__Numerical_Grade__c = 60;
                
                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(39, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(39, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(87, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.625, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(33, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(2.75, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(114, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.4545, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as admin for unit that pass in term 1 with better grade and reattempt with lower grade in term 3 with Exclude GPA setting = false
     */
    @IsTest
    static void testReattemptBetterGradeInT1LowerGradeInT3WithInclusionAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        //disable Exclude GPA setting
        reduivy__RIO_Education_Ivy_Settings__c settings = REDU_AppSetting_UTIL.getOrgDefaultSetting();
        settings.reduivy__Exclude_GPA_For_Repeated_Unit__c = false;

        update settings;
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 3;
                ien1.reduivy__Grade_Points__c = 3;
                ien1.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 3;
                ien9.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 60 - reattempt
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 4;
                ien12.reduivy__Numerical_Grade__c = 60;
                
                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(39, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(39, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(87, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.625, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(33, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(2.75, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(120, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.3333, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as faculty for unit that fail in term 1 and pass in term 3 (reattempt)
     */
    @IsTest
    static void testReattemptFailInT1PassInT3AsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - fail - 0
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 0;
                ien1.reduivy__Grade_Points__c = 0;
                ien1.reduivy__Numerical_Grade__c = 0;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 3;
                ien9.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 100 - reattempt
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 4;
                ien12.reduivy__Numerical_Grade__c = 100;
                
                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(30, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(2.5, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(9, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(30, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(2.5, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(21, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(78, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(39, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(117, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.5455, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as faculty for unit that fail in term 1 and pass in term 3 (reattempt) with Exclude GPA setting = false
     */
    @IsTest
    static void testReattemptFailInT1PassInT3WithInclusionAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        //disable Exclude GPA setting
        reduivy__RIO_Education_Ivy_Settings__c settings = REDU_AppSetting_UTIL.getOrgDefaultSetting();
        settings.reduivy__Exclude_GPA_For_Repeated_Unit__c = false;

        update settings;

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - fail - 0
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 0;
                ien1.reduivy__Grade_Points__c = 0;
                ien1.reduivy__Numerical_Grade__c = 0;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 3;
                ien9.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 100 - reattempt
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 4;
                ien12.reduivy__Numerical_Grade__c = 100;
                
                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(30, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(2.5, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(9, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(30, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(2.5, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(21, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(78, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(39, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(117, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as faculty for unit that pass in term 1 and reattempt with better grade in term 3
     */
    @IsTest
    static void testReattemptBetterGradeInT3AsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 3;
                ien1.reduivy__Grade_Points__c = 3;
                ien1.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 3;
                ien9.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 100 - reattempt
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 4;
                ien12.reduivy__Numerical_Grade__c = 100;
                
                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(39, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(39, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(87, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.625, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(39, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(117, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.5455, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as faculty for unit that pass in term 1 and reattempt with better grade in term 3 with Exclude GPA setting = false
     */
    @IsTest
    static void testReattemptBetterGradeInT3WithInclusionAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        //disable Exclude GPA setting
        reduivy__RIO_Education_Ivy_Settings__c settings = REDU_AppSetting_UTIL.getOrgDefaultSetting();
        settings.reduivy__Exclude_GPA_For_Repeated_Unit__c = false;

        update settings;

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 3;
                ien1.reduivy__Grade_Points__c = 3;
                ien1.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 3;
                ien9.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 100 - reattempt
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 4;
                ien12.reduivy__Numerical_Grade__c = 100;
                
                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(39, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(39, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(87, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.625, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(39, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(126, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.5, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as faculty for unit that pass in term 1 with better grade and reattempt with lower grade in term 3
     */
    @IsTest
    static void testReattemptBetterGradeInT1LowerGradeInT3AsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 3;
                ien1.reduivy__Grade_Points__c = 3;
                ien1.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 3;
                ien9.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 60 - reattempt
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 4;
                ien12.reduivy__Numerical_Grade__c = 60;
                
                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(39, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(39, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(87, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.625, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(33, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(2.75, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(114, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.4545, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as faculty for unit that pass in term 1 with better grade and reattempt with lower grade in term 3 with Exclude GPA setting = false
     */
    @IsTest
    static void testReattemptBetterGradeInT1LowerGradeInT3WithInclusionAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        //disable Exclude GPA setting
        reduivy__RIO_Education_Ivy_Settings__c settings = REDU_AppSetting_UTIL.getOrgDefaultSetting();
        settings.reduivy__Exclude_GPA_For_Repeated_Unit__c = false;

        update settings;
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 3;
                ien1.reduivy__Grade_Points__c = 3;
                ien1.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 3;
                ien9.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 60 - reattempt
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 4;
                ien12.reduivy__Numerical_Grade__c = 60;
                
                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(39, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(39, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(87, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.625, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(33, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(2.75, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(36, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(120, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.3333, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002786 Test as admin for unit that fail and then pass in the same term
     */
    @IsTest
    static void testReattemptSameUnitFailAndPassInSameTermAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ]);
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - fail - 0
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 0;
                ien1.reduivy__Grade_Points__c = 0;
                ien1.reduivy__Numerical_Grade__c = 0;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 0 (reattempt)
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(1, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(42, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(2.8, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(5, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(5, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(15, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(42, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.5, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002786 Test as admin for unit that fail and then pass in the same term with Exclude GPA setting = false
     */
    @IsTest
    static void testReattemptSameUnitFailAndPassInSameTermWithInclusionAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //disable Exclude GPA setting
        reduivy__RIO_Education_Ivy_Settings__c settings = REDU_AppSetting_UTIL.getOrgDefaultSetting();
        settings.reduivy__Exclude_GPA_For_Repeated_Unit__c = false;

        update settings;

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ]);
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - fail - 0
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 0;
                ien1.reduivy__Grade_Points__c = 0;
                ien1.reduivy__Numerical_Grade__c = 0;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 0 (reattempt)
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(1, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(42, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(2.8, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(5, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(5, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(15, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(15, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(42, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(2.8, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002786 Test as faculty for unit that fail and then pass in the same term
     */
    @IsTest
    static void testReattemptSameUnitFailAndPassInSameTermAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ]);
        
        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - fail - 0
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 0;
                ien1.reduivy__Grade_Points__c = 0;
                ien1.reduivy__Numerical_Grade__c = 0;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 0 (reattempt)
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(1, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(42, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(2.8, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(5, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(5, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(15, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(42, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.5, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002786 Test as faculty for unit that fail and then pass in the same term with Exclude GPA setting = false
     */
    @IsTest
    static void testReattemptSameUnitFailAndPassInSameTermWithInclusionAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        //disable Exclude GPA setting
        reduivy__RIO_Education_Ivy_Settings__c settings = REDU_AppSetting_UTIL.getOrgDefaultSetting();
        settings.reduivy__Exclude_GPA_For_Repeated_Unit__c = false;

        update settings;

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ]);
        
        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - fail - 0
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 0;
                ien1.reduivy__Grade_Points__c = 0;
                ien1.reduivy__Numerical_Grade__c = 0;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 0 (reattempt)
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(1, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(42, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(2.8, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(5, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(5, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(15, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(15, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(42, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(2.8, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as admin for unit that fail in term 1 and pass in term 3 (reattempt) with multiple attemps in term 3
     */
    @IsTest
    static void testReattemptFailInT1PassMultipleInT3AsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - fail - 0
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 0;
                ien1.reduivy__Grade_Points__c = 0;
                ien1.reduivy__Numerical_Grade__c = 0;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 3;
                ien9.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 100 - reattempt - best
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 4;
                ien12.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 65 - reattempt - non best
                reduivy__Individual_Enrollment__c ien13 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien13.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien13.reduivy__Credits_Attempted__c = 3;
                ien13.reduivy__Credits_Earned__c = 3;
                ien13.reduivy__Grade_Points__c = 3;
                ien13.reduivy__Numerical_Grade__c = 65;
                
                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12, ien13});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(30, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(2.5, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(9, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(30, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(2.5, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(21, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(78, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.2, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(13, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(13, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(39, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(117, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.5455, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as admin for unit that fail in term 1 and pass in term 3 (reattempt) with multiple attemps in term 3 and Exclude GPA setting = false
     */
    @IsTest
    static void testReattemptFailInT1PassMultipleInT3WithInclusionAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //disable Exclude GPA setting
        reduivy__RIO_Education_Ivy_Settings__c settings = REDU_AppSetting_UTIL.getOrgDefaultSetting();
        settings.reduivy__Exclude_GPA_For_Repeated_Unit__c = false;

        update settings;

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - fail - 0
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 0;
                ien1.reduivy__Grade_Points__c = 0;
                ien1.reduivy__Numerical_Grade__c = 0;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 3;
                ien9.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 100 - reattempt - best
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 4;
                ien12.reduivy__Numerical_Grade__c = 100;
                
                //t3 - pass - 65 - reattempt - non best
                reduivy__Individual_Enrollment__c ien13 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien13.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien13.reduivy__Credits_Attempted__c = 3;
                ien13.reduivy__Credits_Earned__c = 3;
                ien13.reduivy__Grade_Points__c = 3;
                ien13.reduivy__Numerical_Grade__c = 65;

                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12, ien13});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(30, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(2.5, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(9, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(30, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(2.5, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(21, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(78, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.2, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(13, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(13, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(39, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(39, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(126, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.2308, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as faculty for unit that fail in term 1 and pass in term 3 (reattempt) with multiple attemps in term 3
     */
    @IsTest
    static void testReattemptFailInT1PassMultipleInT3AsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - fail - 0
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 0;
                ien1.reduivy__Grade_Points__c = 0;
                ien1.reduivy__Numerical_Grade__c = 0;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 3;
                ien9.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 100 - reattempt - best
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 4;
                ien12.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 65 - reattempt - non best
                reduivy__Individual_Enrollment__c ien13 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien13.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien13.reduivy__Credits_Attempted__c = 3;
                ien13.reduivy__Credits_Earned__c = 3;
                ien13.reduivy__Grade_Points__c = 3;
                ien13.reduivy__Numerical_Grade__c = 65;
                
                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12, ien13});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(30, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(2.5, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(9, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(30, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(2.5, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(21, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(78, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.2, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(13, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(13, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(39, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(117, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.5455, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as faculty for unit that fail in term 1 and pass in term 3 (reattempt) with multiple attemps in term 3 and Exclude GPA setting = false
     */
    @IsTest
    static void testReattemptFailInT1PassMultipleInT3WithInclusionAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        //disable Exclude GPA setting
        reduivy__RIO_Education_Ivy_Settings__c settings = REDU_AppSetting_UTIL.getOrgDefaultSetting();
        settings.reduivy__Exclude_GPA_For_Repeated_Unit__c = false;

        update settings;

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - fail - 0
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 0;
                ien1.reduivy__Grade_Points__c = 0;
                ien1.reduivy__Numerical_Grade__c = 0;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 4;
                ien2.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 3;
                ien3.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 4;
                ien5.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 3;
                ien9.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 100 - reattempt - best
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 4;
                ien12.reduivy__Numerical_Grade__c = 100;
                
                //t3 - pass - 65 - reattempt - non best
                reduivy__Individual_Enrollment__c ien13 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien13.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien13.reduivy__Credits_Attempted__c = 3;
                ien13.reduivy__Credits_Earned__c = 3;
                ien13.reduivy__Grade_Points__c = 3;
                ien13.reduivy__Numerical_Grade__c = 65;

                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12, ien13});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(30, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(2.5, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(4, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(9, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(30, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(2.5, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(8, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(21, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(78, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.2, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(13, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(13, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(39, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(39, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(126, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.2308, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as admin for unit that pass in term 1 and reattempt with better grade in term 3 with multiple attempts in term 1 and 3
     */
    @IsTest
    static void testReattemptBetterGradeInT3MutipleAttemptsAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 3;
                ien1.reduivy__Grade_Points__c = 3;
                ien1.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 65 reattempt - non best
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 3;
                ien2.reduivy__Numerical_Grade__c = 65;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 4;
                ien3.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 3;
                ien5.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 4;
                ien9.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 3;
                ien12.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 100 - reattempt best
                reduivy__Individual_Enrollment__c ien13 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien13.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien13.reduivy__Credits_Attempted__c = 3;
                ien13.reduivy__Credits_Earned__c = 3;
                ien13.reduivy__Grade_Points__c = 4;
                ien13.reduivy__Numerical_Grade__c = 100;
                
                //t3 - pass - 70 - reattempt non best
                reduivy__Individual_Enrollment__c ien14 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien14.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien14.reduivy__Credits_Attempted__c = 3;
                ien14.reduivy__Credits_Earned__c = 3;
                ien14.reduivy__Grade_Points__c = 3;
                ien14.reduivy__Numerical_Grade__c = 70;

                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12, ien13, ien14});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.2, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(5, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(5, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(15, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(39, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(9, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(9, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(27, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(87, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.625, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.2, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(14, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(14, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(42, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(117, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.5455, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as admin for unit that pass in term 1 and reattempt with better grade in term 3 with multiple attempts in term 1 and 3 and exclude GPA setting = false
     */
    @IsTest
    static void testReattemptBetterGradeInT3MutipleAttemptsWithInclusionAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //disable Exclude GPA setting
        reduivy__RIO_Education_Ivy_Settings__c settings = REDU_AppSetting_UTIL.getOrgDefaultSetting();
        settings.reduivy__Exclude_GPA_For_Repeated_Unit__c = false;

        update settings;
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(ADMIN_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 3;
                ien1.reduivy__Grade_Points__c = 3;
                ien1.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 65 reattempt - non best
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 3;
                ien2.reduivy__Numerical_Grade__c = 65;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 4;
                ien3.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 3;
                ien5.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 4;
                ien9.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 3;
                ien12.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 100 - reattempt best
                reduivy__Individual_Enrollment__c ien13 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien13.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien13.reduivy__Credits_Attempted__c = 3;
                ien13.reduivy__Credits_Earned__c = 3;
                ien13.reduivy__Grade_Points__c = 4;
                ien13.reduivy__Numerical_Grade__c = 100;
                
                //t3 - pass - 70 - reattempt non best
                reduivy__Individual_Enrollment__c ien14 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien14.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien14.reduivy__Credits_Attempted__c = 3;
                ien14.reduivy__Credits_Earned__c = 3;
                ien14.reduivy__Grade_Points__c = 3;
                ien14.reduivy__Numerical_Grade__c = 70;

                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12, ien13, ien14});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.2, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(5, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(5, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(15, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(15, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(48, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.2, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(9, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(9, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(27, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(27, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(96, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.5556, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.2, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(14, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(14, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(42, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(42, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(144, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.4286, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as faculty for unit that pass in term 1 and reattempt with better grade in term 3 with multiple attempts in term 1 and 3
     */
    @IsTest
    static void testReattemptBetterGradeInT3MutipleAttemptsAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 3;
                ien1.reduivy__Grade_Points__c = 3;
                ien1.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 65 reattempt - non best
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 3;
                ien2.reduivy__Numerical_Grade__c = 65;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 4;
                ien3.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 3;
                ien5.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 4;
                ien9.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 3;
                ien12.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 100 - reattempt best
                reduivy__Individual_Enrollment__c ien13 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien13.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien13.reduivy__Credits_Attempted__c = 3;
                ien13.reduivy__Credits_Earned__c = 3;
                ien13.reduivy__Grade_Points__c = 4;
                ien13.reduivy__Numerical_Grade__c = 100;
                
                //t3 - pass - 70 - reattempt non best
                reduivy__Individual_Enrollment__c ien14 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien14.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien14.reduivy__Credits_Attempted__c = 3;
                ien14.reduivy__Credits_Earned__c = 3;
                ien14.reduivy__Grade_Points__c = 3;
                ien14.reduivy__Numerical_Grade__c = 70;

                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12, ien13, ien14});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.2, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(5, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(5, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(15, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(39, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.25, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(9, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(9, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(27, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(87, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.625, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.2, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(14, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(14, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(42, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(117, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.5455, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }

    /**
     * @description ISS-002433 Test as faculty for unit that pass in term 1 and reattempt with better grade in term 3 with multiple attempts in term 1 and 3 and exclude GPA setting = false
     */
    @IsTest
    static void testReattemptBetterGradeInT3MutipleAttemptsWithInclusionAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        //disable Exclude GPA setting
        reduivy__RIO_Education_Ivy_Settings__c settings = REDU_AppSetting_UTIL.getOrgDefaultSetting();
        settings.reduivy__Exclude_GPA_For_Repeated_Unit__c = false;

        update settings;
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> '' 
            LIMIT 1
        ];
        
        //Get current running term
        Map<Id, reduivy__Study_Term__c> academicTerms = new Map<Id, reduivy__Study_Term__c>([SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__Sample_Record_Code__c IN ('PYT1', 'PYT2', 'CYT1')
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 3
        ]);
        
        Test.startTest();

		System.runAs(FACULTY_USER){

            //Simulate new individual enrollment for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            Map<String, reduivy__Study_Offering__c> sofMap = new Map<String, reduivy__Study_Offering__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c IN: academicTerms.keySet()
                AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T1_SAMPLE_UNIT_CODES 
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T2_SAMPLE_UNIT_CODES
                    OR reduivy__Study_Unit__r.reduivy__Unit_Code__c IN: T3_SAMPLE_UNIT_CODES
                )
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            ]) {
                sofMap.put(sof.reduivy__Sample_Record_Code__c, sof);
            }

            for (Contact student : studentContacts) {
                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien1.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien1.reduivy__Credits_Attempted__c = 3;
                ien1.reduivy__Credits_Earned__c = 3;
                ien1.reduivy__Grade_Points__c = 3;
                ien1.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 65 reattempt - non best
                reduivy__Individual_Enrollment__c ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_PYT1_SYDNEY').Id,
                    IEN_COMPLETED_FAIL_STATUS,
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

                ien2.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien2.reduivy__Credits_Attempted__c = 3;
                ien2.reduivy__Credits_Earned__c = 3;
                ien2.reduivy__Grade_Points__c = 3;
                ien2.reduivy__Numerical_Grade__c = 65;

                //t1 - pass - 100
                reduivy__Individual_Enrollment__c ien3 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS102_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS102_PYT1_SYDNEY').Id,
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

                ien3.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien3.reduivy__Credits_Attempted__c = 3;
                ien3.reduivy__Credits_Earned__c = 3;
                ien3.reduivy__Grade_Points__c = 4;
                ien3.reduivy__Numerical_Grade__c = 100;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien4 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS103_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS103_PYT1_SYDNEY').Id,
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

                ien4.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien4.reduivy__Credits_Attempted__c = 3;
                ien4.reduivy__Credits_Earned__c = 3;
                ien4.reduivy__Grade_Points__c = 3;
                ien4.reduivy__Numerical_Grade__c = 70;

                //t1 - pass - 70
                reduivy__Individual_Enrollment__c ien5 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('COM101_PYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('COM101_PYT1_SYDNEY').Id,
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

                ien5.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien5.reduivy__Credits_Attempted__c = 3;
                ien5.reduivy__Credits_Earned__c = 3;
                ien5.reduivy__Grade_Points__c = 3;
                ien5.reduivy__Numerical_Grade__c = 70;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien6 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS201_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS201_PYT2_SYDNEY').Id,
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

                ien6.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien6.reduivy__Credits_Attempted__c = 3;
                ien6.reduivy__Credits_Earned__c = 3;
                ien6.reduivy__Grade_Points__c = 4;
                ien6.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien7 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS202_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS202_PYT2_SYDNEY').Id,
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

                ien7.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien7.reduivy__Credits_Attempted__c = 3;
                ien7.reduivy__Credits_Earned__c = 3;
                ien7.reduivy__Grade_Points__c = 4;
                ien7.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien8 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT101_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT101_PYT2_SYDNEY').Id,
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

                ien8.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien8.reduivy__Credits_Attempted__c = 3;
                ien8.reduivy__Credits_Earned__c = 3;
                ien8.reduivy__Grade_Points__c = 4;
                ien8.reduivy__Numerical_Grade__c = 100;

                //t2 - pass - 100
                reduivy__Individual_Enrollment__c ien9 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MKT102_PYT2_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MKT102_PYT2_SYDNEY').Id,
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

                ien9.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien9.reduivy__Credits_Attempted__c = 3;
                ien9.reduivy__Credits_Earned__c = 3;
                ien9.reduivy__Grade_Points__c = 4;
                ien9.reduivy__Numerical_Grade__c = 100;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien10 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT301_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT301_CYT1_SYDNEY').Id,
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

                ien10.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien10.reduivy__Credits_Attempted__c = 3;
                ien10.reduivy__Credits_Earned__c = 3;
                ien10.reduivy__Grade_Points__c = 3;
                ien10.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien11 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('MGT302_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('MGT302_CYT1_SYDNEY').Id,
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

                ien11.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien11.reduivy__Credits_Attempted__c = 3;
                ien11.reduivy__Credits_Earned__c = 3;
                ien11.reduivy__Grade_Points__c = 3;
                ien11.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 70
                reduivy__Individual_Enrollment__c ien12 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('ICT101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('ICT101_CYT1_SYDNEY').Id,
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

                ien12.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien12.reduivy__Credits_Attempted__c = 3;
                ien12.reduivy__Credits_Earned__c = 3;
                ien12.reduivy__Grade_Points__c = 3;
                ien12.reduivy__Numerical_Grade__c = 70;

                //t3 - pass - 100 - reattempt best
                reduivy__Individual_Enrollment__c ien13 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien13.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien13.reduivy__Credits_Attempted__c = 3;
                ien13.reduivy__Credits_Earned__c = 3;
                ien13.reduivy__Grade_Points__c = 4;
                ien13.reduivy__Numerical_Grade__c = 100;
                
                //t3 - pass - 70 - reattempt non best
                reduivy__Individual_Enrollment__c ien14 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sofMap.get('BUS101_CYT1_SYDNEY').reduivy__Sample_Record_Code__c,
                    student.Id,
                    sofMap.get('BUS101_CYT1_SYDNEY').Id,
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

                ien14.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_NOTRELEASED;
                ien14.reduivy__Credits_Attempted__c = 3;
                ien14.reduivy__Credits_Earned__c = 3;
                ien14.reduivy__Grade_Points__c = 3;
                ien14.reduivy__Numerical_Grade__c = 70;

                newIenList.addAll(new List<reduivy__Individual_Enrollment__c>{ien1, ien2, ien3, ien4, ien5, ien6, ien7, ien8, ien9, ien10, ien11, ien12, ien13, ien14});
            }

            REDU_Database_UTIL.doInsert(newIenList);

            for (reduivy__Individual_Enrollment__c ien : newIenList) {
                ien.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;
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
                reduivy__GPA__c,
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
            System.Assert.areEqual(3, ipf.reduivy__Individual_Academic_Progress__r.size(), 'Invalid number of individual academic progress.');

            Integer counter = 1;
            for (reduivy__Individual_Academic_Progress__c ipr : ipf.reduivy__Individual_Academic_Progress__r) {

                if (academicTerms.containsKey(ipr.reduivy__Academic_Term__c)) {
                    if (counter == 1) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.2, ipr.reduivy__GPA__c);
                        
                        System.Assert.areEqual(5, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(5, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(15, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(12, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(15, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(48, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.2, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 2) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(12, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(4, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(9, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(9, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(27, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(24, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(27, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(96, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.5556, ipr.reduivy__Cumulative_GPA__c);

                    } else if (counter == 3) {
                        System.Assert.areEqual(48, ipr.reduivy__Quality_Points__c);
                        System.Assert.areEqual(15, ipr.reduivy__Credits_Attempted__c);
                        System.Assert.areEqual(3.2, ipr.reduivy__GPA__c);

                        System.Assert.areEqual(14, ipr.reduivy__Cumulative_Units_Completed__c);
                        System.Assert.areEqual(14, ipr.reduivy__Cumulative_Units_Enrolled__c);
                        System.Assert.areEqual(42, ipr.reduivy__Cumulative_Credits_Attempted__c);
                        System.Assert.areEqual(33, ipr.reduivy__Cumulative_Credits_Earned__c);
                        System.Assert.areEqual(42, ipr.reduivy__Cumulative_Credits_Enrolled__c);
                        System.Assert.areEqual(144, ipr.reduivy__Cumulative_Quality_Points__c);
                        System.Assert.areEqual(3.4286, ipr.reduivy__Cumulative_GPA__c);

                    }

                } else {
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Completed__c == null || ipr.reduivy__Cumulative_Units_Completed__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Units_Enrolled__c == null || ipr.reduivy__Cumulative_Units_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Attempted__c == null || ipr.reduivy__Cumulative_Credits_Attempted__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Earned__c == null || ipr.reduivy__Cumulative_Credits_Earned__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Credits_Enrolled__c == null || ipr.reduivy__Cumulative_Credits_Enrolled__c == 0);
                    System.Assert.areEqual(true, ipr.reduivy__Cumulative_Quality_Points__c == null || ipr.reduivy__Cumulative_Quality_Points__c == 0);
                }

                counter ++;
            }
        }
		
        System.Assert.isTrue(hasIpf, 'No individual academic profile found for assertion.');

        Test.stopTest();
    }
}