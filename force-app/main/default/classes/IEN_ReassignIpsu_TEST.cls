/**
 * @author      WDCi (dblack)
 * @date        Nov 2023
 * @group       Test
 * @description Test class for IEN_ReassignIpsu_EXE
 * @changehistory
 * ISS-001763 02-11-2023 dblack - new class
 * ISS-002395 11-04-2025 XiRouh - updated to cater the revised after insert and after update logic
 * ISS-002395 21-05-2025 XiRouh - updated to cater the revised after insert and after update logic
 * ISS-002486 10-06-2025 XiRouh - updated IEN_COMPLETED_STATUS from getCompletedStatuses to getCompletedPassStatuses
 * ISS-002743 15-12-2025 XiRouh - Added test methods to consider the IEN within the same Individual Academic Profile context and Updated test methods that create IENs to link them with IPF
 */
@IsTest
public inherited sharing class IEN_ReassignIpsu_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
    static final String IEN_OPEN_STATUS = IEN_Helper.getOpenStatuses().get(0);
    static final String IEN_DROPPED_STATUS = IEN_Helper.getDroppedStatuses().get(0);
    static final String IEN_COMPLETED_STATUS = IEN_Helper.getCompletedPassStatuses().get(0);
    static final String IEN_WITHDRAWN_STATUS = IEN_Helper.getWithdrawnStatuses().get(0);

    static final Map<String, String> IPSUSTATUSMAP = IPS_Helper.getIpsuStatusMap();

    static final String STUDY_UNIT_BUS101 = 'BUS101';
    static final String STUDY_UNIT_BUS102 = 'BUS102';

    static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';

    static String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);
    
    /**
     * @description Create settings and test data
     */
	@TestSetup
    static void makeData() {
		
		// Create rio education ivy settings and sample data
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(SPS_Helper.getApiName());
			testFactory.initOfferingData(SOF_Helper.getApiName());
			testFactory.initStudentData(IPR_Helper.getApiName(), true);

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
				String enrollmentStatus = IPE_INPROGRESS_STATUS;
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
     * @description Test as admin that an individual plan structure unit record is reassigned after insert and before delete
     */
    @IsTest
    static void testIenReassignIpsuAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

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

        //Simulate new individual enrollment for the students
        Map<String, reduivy__Individual_Enrollment__c> newIenMap = new Map<String, reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            for (Contact student : studentContacts) {
                newIenMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
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

        System.Assert.isFalse(newIenMap.isEmpty(), 'No ien for testing.');

        System.runAs(ADMIN_USER) {

            // Execute test
			Test.startTest();
            insert newIenMap.values();
            Test.stopTest();
			
		}

        Set<Id> ipsSunIds = new Set<Id>();
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        System.runAs(ADMIN_USER) {
            delete newIenMap.values();
        }

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            System.Assert.isNull(ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual('Not Started', ips.reduivy__Status__c);
        }
	}

    /**
     * @description Test assignment priority as admin 
     */
    @IsTest
    static void testAssignmentPriorityAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

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

        //Simulate new individual enrollment for the students
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithHigherPriorityStatus = new Map<String, reduivy__Individual_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithInactiveStatus = new Map<String, reduivy__Individual_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithLowerPriorityStatus = new Map<String, reduivy__Individual_Enrollment__c>();

        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            for (Contact student : studentContacts) {
                newIenMapWithHigherPriorityStatus.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_newIenMapWithHigherPriorityStatus',
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
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
                        null,
                        true
                    )
                );

                newIenMapWithInactiveStatus.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_newIenMapWithInactiveStatus',
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_newIenMapWithInactiveStatus',
                        student.Id,
                        sof.Id,
                        IEN_OPEN_STATUS,
                        3,
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

                newIenMapWithLowerPriorityStatus.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_newIenMapWithLowerPriorityStatus',
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_newIenMapWithLowerPriorityStatus',
                        student.Id,
                        sof.Id,
                        IEN_WITHDRAWN_STATUS,
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

        System.Assert.isFalse(newIenMapWithLowerPriorityStatus.isEmpty(), 'No ien for testing.');

        System.runAs(ADMIN_USER) {

            // Execute test
			Test.startTest();
            insert newIenMapWithLowerPriorityStatus.values();			
		}

        Set<Id> ipsSunIds = new Set<Id>();
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c + '_newIenMapWithLowerPriorityStatus';
            
            System.Assert.areEqual(true, newIenMapWithLowerPriorityStatus.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithLowerPriorityStatus.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_WITHDRAWN_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //To test will the ips being reassign if ien with higher priority status are inserted
        System.runAs(ADMIN_USER) {
            // Execute test
            insert newIenMapWithHigherPriorityStatus.values();
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c + '_newIenMapWithHigherPriorityStatus';
            
            System.Assert.areEqual(true, newIenMapWithHigherPriorityStatus.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithHigherPriorityStatus.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);
        }

        System.runAs(ADMIN_USER) {
            delete newIenMapWithHigherPriorityStatus.values();
        }

        //after delete it will reassign to the lower priority status ien have created
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c  + '_newIenMapWithLowerPriorityStatus';
            
            System.Assert.areEqual(true, newIenMapWithLowerPriorityStatus.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithLowerPriorityStatus.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_WITHDRAWN_STATUS), ips.reduivy__Status__c);
        }

        //To create an IEN that should be linked but is currently not linked, so when inserting the open-status IEN, we can check whether it runs the reassign logic. If it does, the IPs will link to the newIenMapWithHigherPriorityStatus
        for(reduivy__Individual_Enrollment__c ien : newIenMapWithHigherPriorityStatus.values()) {
            ien.Id = null;
        }
        
        REDU_TriggerController.muteTriggers(new Set<String>{'IEN_ReassignIpsu_EXE'});
        insert newIenMapWithHigherPriorityStatus.values();
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IEN_ReassignIpsu_EXE'});


        //Open status do not have priority configured, so it should not run the reassign logic
        System.runAs(ADMIN_USER) {
            insert newIenMapWithInactiveStatus.values();
            Test.stopTest();
        }

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c  + '_newIenMapWithLowerPriorityStatus';
            
            System.Assert.areEqual(true, newIenMapWithLowerPriorityStatus.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithLowerPriorityStatus.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_WITHDRAWN_STATUS), ips.reduivy__Status__c);
        }
	}

    /**
     * @description Test as admin that an individual plan structure unit record is reassigned after insert and before delete with multiple individual enrollment attemps
     */
    @IsTest
    static void testMultipleIenReassignIpsuAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

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

        //Simulate new individual enrollment for the students
        Map<String, reduivy__Individual_Enrollment__c> newIenMap = new Map<String, reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            for (Contact student : studentContacts) {
                for (Decimal attempt = 1; attempt <= 2; attempt ++) {
                    newIenMap.put(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_' + attempt,
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_' + attempt,
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            attempt,
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
        }

        System.Assert.isFalse(newIenMap.isEmpty(), 'No ien for testing.');

        System.runAs(ADMIN_USER) {

            // Execute test
			Test.startTest();
            insert newIenMap.values();
            Test.stopTest();
			
		}

        Set<Id> ipsSunIds = new Set<Id>();
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c +
                '_' +
                ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c;
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(2, ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        System.runAs(ADMIN_USER) {
            List<reduivy__Individual_Enrollment__c> ienDeleteList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Individual_Enrollment__c ien : newIenMap.values()) {
                if (ien.reduivy__Attempt_Number__c == 2) {
                    ienDeleteList.add(ien);
                }
            }

            delete ienDeleteList;
        }

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            System.Assert.isNotNull(ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(1, ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);
        }
	}

    /**
     * @description Test as admin that an individual plan structure unit record is reassigned after update
     */
    @IsTest
    static void testIenReassignIpsuAfterUpdateAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

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

        //Simulate new individual enrollment for the students
        Map<String, reduivy__Individual_Enrollment__c> newIenMap = new Map<String, reduivy__Individual_Enrollment__c>();

        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            for (Contact student : studentContacts) {
                newIenMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '1',
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '1',
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

                newIenMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '2',
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '2',
                        student.Id,
                        sof.Id,
                        IEN_OPEN_STATUS,
                        1,
                        System.today().addDays(-1),
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

        System.Assert.isFalse(newIenMap.isEmpty(), 'No ien for testing.');

        System.runAs(ADMIN_USER) {

            // Execute test
			Test.startTest();
            insert newIenMap.values();
			
		}

        Set<Id> ipsSunIds = new Set<Id>();
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c + '1';
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        List<reduivy__Individual_Enrollment__c> ienToBeUpdated = new List<reduivy__Individual_Enrollment__c>();

        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Enrollment_Status__c = :IEN_OPEN_STATUS 
            AND reduivy__Contact__c IN: studentContacts])
        {
            ienToBeUpdated.add(new reduivy__Individual_Enrollment__c(
                Id = ien.Id,
                reduivy__Enrollment_Status__c = IEN_DROPPED_STATUS,
                reduivy__Attempt_Number__c = 2
            ));
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            update ienToBeUpdated;
		}

        //update to dropped status will not reassign
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c + '1';
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        for(reduivy__Individual_Enrollment__c ien : ienToBeUpdated) {
            ien.reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS;
        }

        System.runAs(ADMIN_USER) {

            // Execute test
            update ienToBeUpdated;
            Test.stopTest();
		}

        //update to in progress status will trigger reassign
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c + '2';
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }
	}

    /**
     * @description Test as faculty that an individual plan structure unit record is reassigned after insert and before delete
     */
    @IsTest
    static void testIenReassignIpsuAsFacultyUser() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
		List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

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

        //Simulate new individual enrollment for the students
        Map<String, reduivy__Individual_Enrollment__c> newIenMap = new Map<String, reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            for (Contact student : studentContacts) {
                newIenMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
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

        System.Assert.isFalse(newIenMap.isEmpty(), 'No ien for testing.');

        System.runAs(FACULTY_USER) {

            // Execute test
			Test.startTest();
            insert newIenMap.values();
            Test.stopTest();
			
		}

        Set<Id> ipsSunIds = new Set<Id>();
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        System.runAs(FACULTY_USER) {
            delete newIenMap.values();
        }

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            System.Assert.isNull(ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual('Not Started', ips.reduivy__Status__c);
        }
	}

    /**
     * @description Test assignment priority as faculty
     */
    @IsTest
    static void testAssignmentPriorityAsFacultyUser() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

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

        //Simulate new individual enrollment for the students
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithHigherPriorityStatus = new Map<String, reduivy__Individual_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithInactiveStatus = new Map<String, reduivy__Individual_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithLowerPriorityStatus = new Map<String, reduivy__Individual_Enrollment__c>();

        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            for (Contact student : studentContacts) {
                newIenMapWithHigherPriorityStatus.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_newIenMapWithHigherPriorityStatus',
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
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
						null,
                        true
                    )
                );

                newIenMapWithInactiveStatus.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_newIenMapWithInactiveStatus',
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_newIenMapWithInactiveStatus',
                        student.Id,
                        sof.Id,
                        IEN_OPEN_STATUS,
                        3,
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

                newIenMapWithLowerPriorityStatus.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_newIenMapWithLowerPriorityStatus',
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_newIenMapWithLowerPriorityStatus',
                        student.Id,
                        sof.Id,
                        IEN_WITHDRAWN_STATUS,
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

        System.Assert.isFalse(newIenMapWithLowerPriorityStatus.isEmpty(), 'No ien for testing.');

        System.runAs(FACULTY_USER) {

            // Execute test
			Test.startTest();
            insert newIenMapWithLowerPriorityStatus.values();			
		}

        Set<Id> ipsSunIds = new Set<Id>();
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c + '_newIenMapWithLowerPriorityStatus';
            
            System.Assert.areEqual(true, newIenMapWithLowerPriorityStatus.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithLowerPriorityStatus.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_WITHDRAWN_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //To test will the ips being reassign if ien with higher priority status are inserted
        System.runAs(FACULTY_USER) {
            // Execute test
            insert newIenMapWithHigherPriorityStatus.values();
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c + '_newIenMapWithHigherPriorityStatus';
            
            System.Assert.areEqual(true, newIenMapWithHigherPriorityStatus.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithHigherPriorityStatus.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);
        }

        System.runAs(FACULTY_USER) {
            delete newIenMapWithHigherPriorityStatus.values();
        }

        //after delete it will reassign to the lower priority status ien have created
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c  + '_newIenMapWithLowerPriorityStatus';
            
            System.Assert.areEqual(true, newIenMapWithLowerPriorityStatus.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithLowerPriorityStatus.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_WITHDRAWN_STATUS), ips.reduivy__Status__c);
        }

        //To create an IEN that should be linked but is currently not linked, so when inserting the open-status IEN, we can check whether it runs the reassign logic. If it does, the IPs will link to the newIenMapWithHigherPriorityStatus
        for(reduivy__Individual_Enrollment__c ien : newIenMapWithHigherPriorityStatus.values()) {
            ien.Id = null;
        }
        
        REDU_TriggerController.muteTriggers(new Set<String>{'IEN_ReassignIpsu_EXE'});
        insert newIenMapWithHigherPriorityStatus.values();
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IEN_ReassignIpsu_EXE'});


        //Open status do not have priority configured, so it should not run the reassign logic
        System.runAs(FACULTY_USER) {
            insert newIenMapWithInactiveStatus.values();
            Test.stopTest();
        }

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c  + '_newIenMapWithLowerPriorityStatus';
            
            System.Assert.areEqual(true, newIenMapWithLowerPriorityStatus.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithLowerPriorityStatus.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_WITHDRAWN_STATUS), ips.reduivy__Status__c);
        }
	}

    /**
     * @description Test as faculty that an individual plan structure unit record is reassigned after insert and before delete with multiple individual enrollment attemps
     */
    @IsTest
    static void testMultipleIenReassignIpsuAsFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

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

        //Simulate new individual enrollment for the students
        Map<String, reduivy__Individual_Enrollment__c> newIenMap = new Map<String, reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            for (Contact student : studentContacts) {
                for (Decimal attempt = 1; attempt <= 2; attempt ++) {
                    newIenMap.put(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_' + attempt,
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_' + attempt,
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            attempt,
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
        }

        System.Assert.isFalse(newIenMap.isEmpty(), 'No ien for testing.');

        System.runAs(FACULTY_USER) {

            // Execute test
			Test.startTest();
            insert newIenMap.values();
            Test.stopTest();
			
		}

        Set<Id> ipsSunIds = new Set<Id>();
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c +
                '_' +
                ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c;
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(2, ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        System.runAs(FACULTY_USER) {
            List<reduivy__Individual_Enrollment__c> ienDeleteList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Individual_Enrollment__c ien : newIenMap.values()) {
                if (ien.reduivy__Attempt_Number__c == 2) {
                    ienDeleteList.add(ien);
                }
            }

            delete ienDeleteList;
        }

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            System.Assert.isNotNull(ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(1, ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);
        }
	}

     /**
     * @description Test as faculty that an individual plan structure unit record is reassigned after update
     */
    @IsTest
    static void testIenReassignIpsuAfterUpdateAsFacultyUser() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

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

        //Simulate new individual enrollment for the students
        Map<String, reduivy__Individual_Enrollment__c> newIenMap = new Map<String, reduivy__Individual_Enrollment__c>();

        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            for (Contact student : studentContacts) {
                newIenMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '1',
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '1',
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

                newIenMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '2',
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '2',
                        student.Id,
                        sof.Id,
                        IEN_OPEN_STATUS,
                        1,
                        System.today().addDays(-1),
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

        System.Assert.isFalse(newIenMap.isEmpty(), 'No ien for testing.');

        System.runAs(FACULTY_USER) {

            // Execute test
			Test.startTest();
            insert newIenMap.values();
			
		}

        Set<Id> ipsSunIds = new Set<Id>();
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c + '1';
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        List<reduivy__Individual_Enrollment__c> ienToBeUpdated = new List<reduivy__Individual_Enrollment__c>();

        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Enrollment_Status__c = :IEN_OPEN_STATUS 
            AND reduivy__Contact__c IN: studentContacts])
        {
            ienToBeUpdated.add(new reduivy__Individual_Enrollment__c(
                Id = ien.Id,
                reduivy__Enrollment_Status__c = IEN_DROPPED_STATUS,
                reduivy__Attempt_Number__c = 2
            ));
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            update ienToBeUpdated;
		}

        //update to dropped status will not reassign
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c + '1';
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        for(reduivy__Individual_Enrollment__c ien : ienToBeUpdated) {
            ien.reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS;
        }

        System.runAs(FACULTY_USER) {

            // Execute test
            update ienToBeUpdated;
            Test.stopTest();
		}

        //update to in progress status will trigger reassign
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c + '2';
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }
	}

    /**
     * @description Test as student that an individual plan structure unit record is reassigned after insert and before delete
     */
    @IsTest
    static void testIenReassignIpsuAsStudentUser() {

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
        
        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

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

        //Simulate new individual enrollment for the students
        Map<String, reduivy__Individual_Enrollment__c> newIenMap = new Map<String, reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            for (Contact student : studentContacts) {
                newIenMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
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

        System.Assert.isFalse(newIenMap.isEmpty(), 'No ien for testing.');

        System.runAs(studentUser) {

            // Execute test
			Test.startTest();
            insert newIenMap.values();
            Test.stopTest();
			
		}

        Set<Id> ipsSunIds = new Set<Id>();
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        System.runAs(studentUser) {
            try {
                delete newIenMap.values();
                System.Assert.fail('This should fail with insufficient access error.');
                
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('insufficient access rights on object id'));
            }
        }

	}

    /**
     * @description Test assignment priority as student
     */
    @IsTest
    static void testAssignmentPriorityAsAsStudentUser() {
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
        
        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

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

       //Simulate new individual enrollment for the students
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithHigherPriorityStatus = new Map<String, reduivy__Individual_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithInactiveStatus = new Map<String, reduivy__Individual_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithLowerPriorityStatus = new Map<String, reduivy__Individual_Enrollment__c>();

        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            for (Contact student : studentContacts) {
                newIenMapWithHigherPriorityStatus.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_newIenMapWithHigherPriorityStatus',
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
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
						null,
                        true
                    )
                );

                newIenMapWithInactiveStatus.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_newIenMapWithInactiveStatus',
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_newIenMapWithInactiveStatus',
                        student.Id,
                        sof.Id,
                        IEN_OPEN_STATUS,
                        3,
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

                newIenMapWithLowerPriorityStatus.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_newIenMapWithLowerPriorityStatus',
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_newIenMapWithLowerPriorityStatus',
                        student.Id,
                        sof.Id,
                        IEN_WITHDRAWN_STATUS,
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

        System.Assert.isFalse(newIenMapWithLowerPriorityStatus.isEmpty(), 'No ien for testing.');

        System.runAs(studentUser) {

            // Execute test
			Test.startTest();
            insert newIenMapWithLowerPriorityStatus.values();	
			
		}

         Set<Id> ipsSunIds = new Set<Id>();
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c + '_newIenMapWithLowerPriorityStatus';
            
            System.Assert.areEqual(true, newIenMapWithLowerPriorityStatus.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithLowerPriorityStatus.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_WITHDRAWN_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //To test will the ips being reassign if ien with higher priority status are inserted
        System.runAs(studentUser) {
            // Execute test
            insert newIenMapWithHigherPriorityStatus.values();
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c + '_newIenMapWithHigherPriorityStatus';
            
            System.Assert.areEqual(true, newIenMapWithHigherPriorityStatus.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithHigherPriorityStatus.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);
        }

        System.runAs(studentUser) {
            try {
                delete newIenMapWithHigherPriorityStatus.values();
                System.Assert.fail('This should fail with insufficient access error.');
                
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('insufficient access rights on object id'));
            }
        }

        delete newIenMapWithHigherPriorityStatus.values();

        //To create an IEN that should be linked but is currently not linked, so when inserting the open-status IEN, we can check whether it runs the reassign logic. If it does, the IPs will link to the newIenMapWithHigherPriorityStatus
        for(reduivy__Individual_Enrollment__c ien : newIenMapWithHigherPriorityStatus.values()) {
            ien.Id = null;
        }
        
        REDU_TriggerController.muteTriggers(new Set<String>{'IEN_ReassignIpsu_EXE'});
        insert newIenMapWithHigherPriorityStatus.values();
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IEN_ReassignIpsu_EXE'});

        //Open status do not have priority configured, so it should not run the reassign logic
        System.runAs(studentUser) {
            insert newIenMapWithInactiveStatus.values();
            Test.stopTest();
        }

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c  + '_newIenMapWithLowerPriorityStatus';
            
            System.Assert.areEqual(true, newIenMapWithLowerPriorityStatus.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithLowerPriorityStatus.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_WITHDRAWN_STATUS), ips.reduivy__Status__c);
        }
    }

    /**
     * @description Test as student that an individual plan structure unit record is reassigned after update
     */
    @IsTest
    static void testIenReassignIpsuAfterUpdateAsStudentUser() {        
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
        
        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

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

        //Simulate new individual enrollment for the students
        Map<String, reduivy__Individual_Enrollment__c> newIenMap = new Map<String, reduivy__Individual_Enrollment__c>();

        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            for (Contact student : studentContacts) {
                newIenMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '1',
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '1',
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

                newIenMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '2',
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '2',
                        student.Id,
                        sof.Id,
                        IEN_OPEN_STATUS,
                        1,
                        System.today().addDays(-1),
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

        System.Assert.isFalse(newIenMap.isEmpty(), 'No ien for testing.');

        System.runAs(studentUser) {

            // Execute test
			Test.startTest();
            insert newIenMap.values();
			
		}

        Set<Id> ipsSunIds = new Set<Id>();
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c + '1';
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        List<reduivy__Individual_Enrollment__c> ienToBeUpdated = new List<reduivy__Individual_Enrollment__c>();

        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Enrollment_Status__c = :IEN_OPEN_STATUS 
            AND reduivy__Contact__c IN: studentContacts])
        {
            ienToBeUpdated.add(new reduivy__Individual_Enrollment__c(
                Id = ien.Id,
                reduivy__Enrollment_Status__c = IEN_DROPPED_STATUS,
                reduivy__Attempt_Number__c = 2
            ));
        }

        System.runAs(studentUser) {

            // Execute test
            update ienToBeUpdated;
		}

        //update to dropped status will not reassign
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c + '1';
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        for(reduivy__Individual_Enrollment__c ien : ienToBeUpdated) {
            ien.reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS;
        }

        System.runAs(studentUser) {

            // Execute test
            update ienToBeUpdated;
            Test.stopTest();
		}

        //update to in progress status will trigger reassign
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c + '2';
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }
	}

    /**
     * @description Test for reassginment priority decision making logic as admin
     */
    @IsTest
    static void testPriorityLogicAsAdminUser() {
        REDU_TriggerController.muteTriggers(new Set<String>{'IPS_IpeCompletion_EXE', 'IPS_UnitIpsCompletion_EXE', 'IUR_RequirementMet_EXE', 'IEN_StudyOfferingRollup_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

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

        //Simulate new individual enrollment for the students
        Map<String, reduivy__Individual_Enrollment__c> newIenMap = new Map<String, reduivy__Individual_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithEarlierDateLargerAttempt = new Map<String, reduivy__Individual_Enrollment__c>(); //will reassign as the attempt number > newIenMap
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithEarlierStartDateAndLaterEnrollmentDate = new Map<String, reduivy__Individual_Enrollment__c>(); //will reassign as enrollment date is > than the newIenMapWithEarlierDateLargerAttempt
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithDroppedStatus = new Map<String, reduivy__Individual_Enrollment__c>(); //will not reassign as it is inactive status
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithCompletedStatus = new Map<String, reduivy__Individual_Enrollment__c>(); //will reassign as completed have higher priority

        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            for (Contact student : studentContacts) {
                newIenMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        System.today(),
                        null,
                        null,
                        3,
                        null,
						null,
                        true
                    )
                );

                newIenMapWithEarlierDateLargerAttempt.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        2,
                        System.today().addDays(-5),
                        System.today().addDays(-5),
                        null,
                        null,
                        3,
                        null,
						null,
                        true
                    )
                );

                newIenMapWithEarlierStartDateAndLaterEnrollmentDate.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        2,
                        System.today().addDays(5),
                        System.today().addDays(-5),
                        null,
                        null,
                        3,
                        null,
						null,
                        true
                    )
                );

                newIenMapWithDroppedStatus.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_DROPPED_STATUS,
                        3,
                        System.today(),
                        System.today(),
                        null,
                        null,
                        3,
                        null,
						null,
                        true
                    )
                );

                newIenMapWithCompletedStatus.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_COMPLETED_STATUS,
                        1,
                        System.today().addDays(-10),
                        System.today().addDays(-10),
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

        System.runAs(ADMIN_USER) {

            insert newIenMap.values();		
            // Execute test
			Test.startTest();	
		}

        Set<Id> ipsSunIds = new Set<Id>();
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //Will be reassigned to new inserted ien
        System.runAs(ADMIN_USER) {

            // Execute test
            insert newIenMapWithEarlierDateLargerAttempt.values();			
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMapWithEarlierDateLargerAttempt.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithEarlierDateLargerAttempt.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //Will be reassigned to new inserted ien
        System.runAs(ADMIN_USER) {

            // Execute test
            insert newIenMapWithEarlierStartDateAndLaterEnrollmentDate.values();			
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMapWithEarlierStartDateAndLaterEnrollmentDate.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithEarlierStartDateAndLaterEnrollmentDate.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //Will not be reassigned to new inserted ien
        System.runAs(ADMIN_USER) {

            // Execute test
            insert newIenMapWithDroppedStatus.values();			
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMapWithEarlierStartDateAndLaterEnrollmentDate.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithEarlierStartDateAndLaterEnrollmentDate.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //Will be reassigned to newIenMapWithEarlierDateLargerAttempt
        System.runAs(ADMIN_USER) {

            // Execute test
            delete newIenMapWithEarlierStartDateAndLaterEnrollmentDate.values();			
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMapWithEarlierDateLargerAttempt.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithEarlierDateLargerAttempt.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //Will be reassigned to newIenMap
        System.runAs(ADMIN_USER) {

            // Execute test
            delete newIenMapWithEarlierDateLargerAttempt.values();			
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //Will be reassigned
        System.runAs(ADMIN_USER) {

            // Execute test
            insert newIenMapWithCompletedStatus.values();		
            
            Test.stopTest();
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMapWithCompletedStatus.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithCompletedStatus.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_COMPLETED_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));
    }

    /**
     * @description Test for reassginment priority decision making logic as faculty
     */
    @IsTest
    static void testPriorityLogicAsFacultyUser() {
        REDU_TriggerController.muteTriggers(new Set<String>{'IPS_IpeCompletion_EXE', 'IPS_UnitIpsCompletion_EXE', 'IUR_RequirementMet_EXE', 'IEN_StudyOfferingRollup_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

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

        //Simulate new individual enrollment for the students
        Map<String, reduivy__Individual_Enrollment__c> newIenMap = new Map<String, reduivy__Individual_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithEarlierDateLargerAttempt = new Map<String, reduivy__Individual_Enrollment__c>(); //will reassign as the attempt number > newIenMap
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithEarlierStartDateAndLaterEnrollmentDate = new Map<String, reduivy__Individual_Enrollment__c>(); //will reassign as enrollment date is > than the newIenMapWithEarlierDateLargerAttempt
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithDroppedStatus = new Map<String, reduivy__Individual_Enrollment__c>(); //will not reassign as it is inactive status
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithCompletedStatus = new Map<String, reduivy__Individual_Enrollment__c>(); //will reassign as completed have higher priority

        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            for (Contact student : studentContacts) {
                newIenMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        System.today(),
                        null,
                        null,
                        3,
                        null,
						null,
                        true
                    )
                );

                newIenMapWithEarlierDateLargerAttempt.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        2,
                        System.today().addDays(-5),
                        System.today().addDays(-5),
                        null,
                        null,
                        3,
                        null,
						null,
                        true
                    )
                );

                newIenMapWithEarlierStartDateAndLaterEnrollmentDate.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        2,
                        System.today().addDays(5),
                        System.today().addDays(-5),
                        null,
                        null,
                        3,
                        null,
						null,
                        true
                    )
                );

                newIenMapWithDroppedStatus.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_DROPPED_STATUS,
                        3,
                        System.today(),
                        System.today(),
                        null,
                        null,
                        3,
                        null,
						null,
                        true
                    )
                );

                newIenMapWithCompletedStatus.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_COMPLETED_STATUS,
                        1,
                        System.today().addDays(-10),
                        System.today().addDays(-10),
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

        System.runAs(FACULTY_USER) {

            // Execute test
            insert newIenMap.values();		
			Test.startTest();	
		}

        Set<Id> ipsSunIds = new Set<Id>();
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //Will be reassigned to new inserted ien
        System.runAs(FACULTY_USER) {

            // Execute test
            insert newIenMapWithEarlierDateLargerAttempt.values();			
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMapWithEarlierDateLargerAttempt.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithEarlierDateLargerAttempt.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //Will be reassigned to new inserted ien
        System.runAs(FACULTY_USER) {

            // Execute test
            insert newIenMapWithEarlierStartDateAndLaterEnrollmentDate.values();			
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMapWithEarlierStartDateAndLaterEnrollmentDate.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithEarlierStartDateAndLaterEnrollmentDate.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //Will not be reassigned to new inserted ien
        System.runAs(FACULTY_USER) {

            // Execute test
            insert newIenMapWithDroppedStatus.values();			
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMapWithEarlierStartDateAndLaterEnrollmentDate.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithEarlierStartDateAndLaterEnrollmentDate.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //Will be reassigned to newIenMapWithEarlierDateLargerAttempt
        System.runAs(FACULTY_USER) {

            // Execute test
            delete newIenMapWithEarlierStartDateAndLaterEnrollmentDate.values();			
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMapWithEarlierDateLargerAttempt.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithEarlierDateLargerAttempt.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //Will be reassigned to newIenMap
        System.runAs(FACULTY_USER) {

            // Execute test
            delete newIenMapWithEarlierDateLargerAttempt.values();			
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //Will be reassigned
        System.runAs(FACULTY_USER) {

            // Execute test
            insert newIenMapWithCompletedStatus.values();		
            
            Test.stopTest();
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMapWithCompletedStatus.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithCompletedStatus.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_COMPLETED_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));
    }

    /**
     * @description Test for reassginment priority decision making logic as student
     */
    @IsTest
    static void testPriorityLogicAsStudentUser() {
        REDU_TriggerController.muteTriggers(new Set<String>{'IPS_IpeCompletion_EXE', 'IPS_UnitIpsCompletion_EXE', 'IUR_RequirementMet_EXE', 'IEN_StudyOfferingRollup_EXE'});
        
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
        
        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

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

        //Simulate new individual enrollment for the students
        Map<String, reduivy__Individual_Enrollment__c> newIenMap = new Map<String, reduivy__Individual_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithEarlierDateLargerAttempt = new Map<String, reduivy__Individual_Enrollment__c>(); //will reassign as the attempt number > newIenMap
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithEarlierStartDateAndLaterEnrollmentDate = new Map<String, reduivy__Individual_Enrollment__c>(); //will reassign as enrollment date is > than the newIenMapWithEarlierDateLargerAttempt
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithDroppedStatus = new Map<String, reduivy__Individual_Enrollment__c>(); //will not reassign as it is inactive status
        Map<String, reduivy__Individual_Enrollment__c> newIenMapWithCompletedStatus = new Map<String, reduivy__Individual_Enrollment__c>(); //will reassign as completed have higher priority

        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            for (Contact student : studentContacts) {
                newIenMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        System.today(),
                        null,
                        null,
                        3,
                        null,
						null,
                        true
                    )
                );

                newIenMapWithEarlierDateLargerAttempt.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        2,
                        System.today().addDays(-5),
                        System.today().addDays(-5),
                        null,
                        null,
                        3,
                        null,
						null,
                        true
                    )
                );

                newIenMapWithEarlierStartDateAndLaterEnrollmentDate.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        2,
                        System.today().addDays(5),
                        System.today().addDays(-5),
                        null,
                        null,
                        3,
                        null,
						null,
                        true
                    )
                );

                newIenMapWithDroppedStatus.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_DROPPED_STATUS,
                        3,
                        System.today(),
                        System.today(),
                        null,
                        null,
                        3,
                        null,
						null,
                        true
                    )
                );

                newIenMapWithCompletedStatus.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_COMPLETED_STATUS,
                        1,
                        System.today().addDays(-10),
                        System.today().addDays(-10),
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

        System.runAs(studentUser) {

            // Execute test
			Test.startTest();
            insert newIenMap.values();			
		}

        Set<Id> ipsSunIds = new Set<Id>();
        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMap.containsKey(matchingKey));
            System.Assert.areEqual(newIenMap.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //Will be reassigned to new inserted ien
        System.runAs(studentUser) {

            // Execute test
            insert newIenMapWithEarlierDateLargerAttempt.values();			
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMapWithEarlierDateLargerAttempt.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithEarlierDateLargerAttempt.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //Will be reassigned to new inserted ien
        System.runAs(studentUser) {

            // Execute test
            insert newIenMapWithEarlierStartDateAndLaterEnrollmentDate.values();			
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMapWithEarlierStartDateAndLaterEnrollmentDate.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithEarlierStartDateAndLaterEnrollmentDate.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //Will not be reassigned to new inserted ien
        System.runAs(studentUser) {

            // Execute test
            insert newIenMapWithDroppedStatus.values();			
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMapWithEarlierStartDateAndLaterEnrollmentDate.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithEarlierStartDateAndLaterEnrollmentDate.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));

        //Will be reassigned to newIenMapWithEarlierDateLargerAttempt
        System.runAs(studentUser) {
            try {
            delete newIenMapWithEarlierStartDateAndLaterEnrollmentDate.values();			
                System.Assert.fail('This should fail with insufficient access error.');
                
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('insufficient access rights on object id'));
            }
		}

        //Will be reassigned
        System.runAs(studentUser) {

            // Execute test
            insert newIenMapWithCompletedStatus.values();		
            
            Test.stopTest();
		}

        for(reduivy__Individual_Plan_Structure__c ips : [SELECT Id, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Enrollment__c, 
            reduivy__Target_Unit_Id__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Revalidate_Completion__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: studentContacts
        ]){
            String matchingKey = ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c + 
                '_' + 
                ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Sample_Record_Code__c;
            
            System.Assert.areEqual(true, newIenMapWithCompletedStatus.containsKey(matchingKey));
            System.Assert.areEqual(newIenMapWithCompletedStatus.get(matchingKey).Id, ips.reduivy__Individual_Enrollment__c);
            System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_COMPLETED_STATUS), ips.reduivy__Status__c);

            ipsSunIds.add(ips.reduivy__Target_Unit_Id__c);
        }

        System.Assert.isTrue(!ipsSunIds.isEmpty(), 'No individual plan structure found.');
        System.Assert.isTrue(studyUnits.keySet().containsAll(ipsSunIds));
    }

    /**
     * @description Test for should reassign logic as admin
     */
    @IsTest
    static void testShouldReassignLogicAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
            LIMIT 1
        ]);

        reduivy__Study_Term__c academicTerm = [SELECT Id, reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Study_Offering__c> sofList = [SELECT Id, reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id 
            AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c IN: studyUnits.values()
            LIMIT 1
        ];

        System.Assert.isFalse(studentContacts.isEmpty() || sofList.isEmpty(), 'Test data not available');

        Contact testStudent = studentContacts[0];
        reduivy__Study_Offering__c testSof = sofList[0];
        
        reduivy__Individual_Enrollment__c ienWithBlankStatus = REDU_TestData_UTIL.newStudentIndividualEnrollment(
            testStudent.reduivy__Sample_Record_Code__c + '_blank_status',
            testStudent.Id,
            testSof.Id,
            '', // Blank status
            1,
            System.today(),
            null,
            null,
            null,
            3,
            null,
            null,
            false // Don't set ID
        );
        
        reduivy__Individual_Enrollment__c ienWithPriorityStatus = REDU_TestData_UTIL.newStudentIndividualEnrollment(
            testStudent.reduivy__Sample_Record_Code__c + '_priority_status',
            testStudent.Id,
            testSof.Id,
            IEN_INPROGRESS_STATUS,
            1,
            System.today(),
            null,
            null,
            null,
            3,
            null,
			null,
            false
        );
        
        reduivy__Individual_Enrollment__c ienWithNonPriorityStatus = REDU_TestData_UTIL.newStudentIndividualEnrollment(
            testStudent.reduivy__Sample_Record_Code__c + '_nonpriority_status',
            testStudent.Id,
            testSof.Id,
            IEN_OPEN_STATUS,
            1,
            System.today(),
            null,
            null,
            null,
            3,
            null,
			null,
            false
        );
        
        reduivy__Individual_Enrollment__c ienWithdrawn = REDU_TestData_UTIL.newStudentIndividualEnrollment(
            testStudent.reduivy__Sample_Record_Code__c + '_withdrawn',
            testStudent.Id,
            testSof.Id,
            IEN_WITHDRAWN_STATUS,
            1,
            System.today(),
            null,
            null,
            null,
            3,
            null,
			null,
            false
        );
        
        reduivy__Individual_Enrollment__c ienDropped = REDU_TestData_UTIL.newStudentIndividualEnrollment(
            testStudent.reduivy__Sample_Record_Code__c + '_dropped',
            testStudent.Id,
            testSof.Id,
            IEN_DROPPED_STATUS,
            1,
            System.today(),
            null,
            null,
            null,
            3,
            null,
			null,
            false
        );
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Test 1: Insert with blank status - should NOT trigger reassign
            Integer ipsCountBefore = [SELECT COUNT() FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
                AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c = :testStudent.Id];
            
            insert ienWithBlankStatus;
            
            Integer ipsCountBlankStatus = [SELECT COUNT() FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Individual_Enrollment__c = :ienWithBlankStatus.Id];
            
            System.Assert.areEqual(0, ipsCountBlankStatus,
                'No IPS should be linked when inserting IEN with blank status');
            
            // Test 2: Insert with priority status - should trigger reassign
            insert ienWithPriorityStatus;
            
            Integer ipsCountPriorityStatus = [SELECT COUNT() FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Individual_Enrollment__c = :ienWithPriorityStatus.Id];
            
            System.Assert.isTrue(ipsCountPriorityStatus > 0,
                'IPS should be linked when inserting IEN with priority status');
            
            // Test 3: Insert with non-priority status - should NOT trigger reassign
            insert ienWithNonPriorityStatus;
            
            Integer ipsCountNonPriorityStatus = [SELECT COUNT() FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Individual_Enrollment__c = :ienWithNonPriorityStatus.Id];
            
            System.Assert.areEqual(0, ipsCountNonPriorityStatus,
                'No IPS should be linked when inserting IEN with non-priority status');
            
            // Test 4: Update from non-priority to priority - should trigger reassign
            ienWithNonPriorityStatus.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_STATUS;
            update ienWithNonPriorityStatus;
            
            // Should reassign to higher priority IEN
            List<reduivy__Individual_Plan_Structure__c> ipsAfterUpdate = [
                SELECT Id, reduivy__Individual_Enrollment__c
                FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
                AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c = :testStudent.Id
            ];
            
            // Should be linked to highest priority IEN (INPROGRESS has highest priority)
            System.Assert.areEqual(ienWithPriorityStatus.Id, ipsAfterUpdate[0].reduivy__Individual_Enrollment__c,
                'IPS should be linked to highest priority IEN after update');
            
            // Test 5: Update within same priority level - should NOT trigger reassign
            Id currentLinkedIen = ipsAfterUpdate[0].reduivy__Individual_Enrollment__c;
            
            insert ienWithdrawn;
            insert ienDropped;
            
            // Update withdrawn to dropped (both priority 4)
            ienWithdrawn.reduivy__Enrollment_Status__c = IEN_DROPPED_STATUS;
            update ienWithdrawn;
            
            List<reduivy__Individual_Plan_Structure__c> ipsAfterSamePriorityUpdate = [
                SELECT Id, reduivy__Individual_Enrollment__c
                FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
                AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c = :testStudent.Id
            ];
            
            // Should still be linked to the same highest priority IEN
            System.Assert.areEqual(currentLinkedIen, ipsAfterSamePriorityUpdate[0].reduivy__Individual_Enrollment__c,
                'IPS should remain linked to same IEN when updating within same priority level');
            
            Test.stopTest();
        }
    }

    /**
     * @description Test for should reassign logic as faculty
     */
    @IsTest
    static void testShouldReassignLogicAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
            LIMIT 1
        ]);

        reduivy__Study_Term__c academicTerm = [SELECT Id, reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Study_Offering__c> sofList = [SELECT Id, reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id 
            AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c IN: studyUnits.values()
            LIMIT 1
        ];

        System.Assert.isFalse(studentContacts.isEmpty() || sofList.isEmpty(), 'Test data not available');

        Contact testStudent = studentContacts[0];
        reduivy__Study_Offering__c testSof = sofList[0];
        
        reduivy__Individual_Enrollment__c ienWithBlankStatus = REDU_TestData_UTIL.newStudentIndividualEnrollment(
            testStudent.reduivy__Sample_Record_Code__c + '_blank_status',
            testStudent.Id,
            testSof.Id,
            '', // Blank status
            1,
            System.today(),
            null,
            null,
            null,
            3,
            null,
            null,
            false // Don't set ID
        );
        
        reduivy__Individual_Enrollment__c ienWithPriorityStatus = REDU_TestData_UTIL.newStudentIndividualEnrollment(
            testStudent.reduivy__Sample_Record_Code__c + '_priority_status',
            testStudent.Id,
            testSof.Id,
            IEN_INPROGRESS_STATUS,
            1,
            System.today(),
            null,
            null,
            null,
            3,
            null,
			null,
            false
        );
        
        reduivy__Individual_Enrollment__c ienWithNonPriorityStatus = REDU_TestData_UTIL.newStudentIndividualEnrollment(
            testStudent.reduivy__Sample_Record_Code__c + '_nonpriority_status',
            testStudent.Id,
            testSof.Id,
            IEN_OPEN_STATUS,
            1,
            System.today(),
            null,
            null,
            null,
            3,
            null,
			null,
            false
        );
        
        reduivy__Individual_Enrollment__c ienWithdrawn = REDU_TestData_UTIL.newStudentIndividualEnrollment(
            testStudent.reduivy__Sample_Record_Code__c + '_withdrawn',
            testStudent.Id,
            testSof.Id,
            IEN_WITHDRAWN_STATUS,
            1,
            System.today(),
            null,
            null,
            null,
            3,
            null,
			null,
            false
        );
        
        reduivy__Individual_Enrollment__c ienDropped = REDU_TestData_UTIL.newStudentIndividualEnrollment(
            testStudent.reduivy__Sample_Record_Code__c + '_dropped',
            testStudent.Id,
            testSof.Id,
            IEN_DROPPED_STATUS,
            1,
            System.today(),
            null,
            null,
            null,
            3,
            null,
			null,
            false
        );
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Test 1: Insert with blank status - should NOT trigger reassign
            Integer ipsCountBefore = [SELECT COUNT() FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
                AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c = :testStudent.Id];
            
            insert ienWithBlankStatus;
            
            Integer ipsCountBlankStatus = [SELECT COUNT() FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Individual_Enrollment__c = :ienWithBlankStatus.Id];
            
            System.Assert.areEqual(0, ipsCountBlankStatus,
                'No IPS should be linked when inserting IEN with blank status');
            
            // Test 2: Insert with priority status - should trigger reassign
            insert ienWithPriorityStatus;
            
            Integer ipsCountPriorityStatus = [SELECT COUNT() FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Individual_Enrollment__c = :ienWithPriorityStatus.Id];
            
            System.Assert.isTrue(ipsCountPriorityStatus > 0,
                'IPS should be linked when inserting IEN with priority status');
            
            // Test 3: Insert with non-priority status - should NOT trigger reassign
            insert ienWithNonPriorityStatus;
            
            Integer ipsCountNonPriorityStatus = [SELECT COUNT() FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Individual_Enrollment__c = :ienWithNonPriorityStatus.Id];
            
            System.Assert.areEqual(0, ipsCountNonPriorityStatus,
                'No IPS should be linked when inserting IEN with non-priority status');
            
            // Test 4: Update from non-priority to priority - should trigger reassign
            ienWithNonPriorityStatus.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_STATUS;
            update ienWithNonPriorityStatus;
            
            // Should reassign to higher priority IEN
            List<reduivy__Individual_Plan_Structure__c> ipsAfterUpdate = [
                SELECT Id, reduivy__Individual_Enrollment__c
                FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
                AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c = :testStudent.Id
            ];
            
            // Should be linked to highest priority IEN (INPROGRESS has highest priority)
            System.Assert.areEqual(ienWithPriorityStatus.Id, ipsAfterUpdate[0].reduivy__Individual_Enrollment__c,
                'IPS should be linked to highest priority IEN after update');
            
            // Test 5: Update within same priority level - should NOT trigger reassign
            Id currentLinkedIen = ipsAfterUpdate[0].reduivy__Individual_Enrollment__c;
            
            insert ienWithdrawn;
            insert ienDropped;
            
            // Update withdrawn to dropped (both priority 4)
            ienWithdrawn.reduivy__Enrollment_Status__c = IEN_DROPPED_STATUS;
            update ienWithdrawn;
            
            List<reduivy__Individual_Plan_Structure__c> ipsAfterSamePriorityUpdate = [
                SELECT Id, reduivy__Individual_Enrollment__c
                FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
                AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c = :testStudent.Id
            ];
            
            // Should still be linked to the same highest priority IEN
            System.Assert.areEqual(currentLinkedIen, ipsAfterSamePriorityUpdate[0].reduivy__Individual_Enrollment__c,
                'IPS should remain linked to same IEN when updating within same priority level');
            
            Test.stopTest();
        }
    }

    /**
     * @description Test for should reassign logic as student
     */
    @IsTest
    static void testShouldReassignLogicAsStudent() {

        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c 
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

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
            LIMIT 1
        ]);

        reduivy__Study_Term__c academicTerm = [SELECT Id, reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        List<reduivy__Study_Offering__c> sofList = [SELECT Id, reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id 
            AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c IN: studyUnits.values()
            LIMIT 1
        ];

        System.Assert.isFalse(studentContacts.isEmpty() || sofList.isEmpty(), 'Test data not available');

        Contact testStudent = studentContacts[0];
        reduivy__Study_Offering__c testSof = sofList[0];
        
        reduivy__Individual_Enrollment__c ienWithBlankStatus = REDU_TestData_UTIL.newStudentIndividualEnrollment(
            testStudent.reduivy__Sample_Record_Code__c + '_blank_status',
            testStudent.Id,
            testSof.Id,
            '', // Blank status
            1,
            System.today(),
            null,
            null,
            null,
            3,
            null,
            null,
            false 
        );
        
        reduivy__Individual_Enrollment__c ienWithPriorityStatus = REDU_TestData_UTIL.newStudentIndividualEnrollment(
            testStudent.reduivy__Sample_Record_Code__c + '_priority_status',
            testStudent.Id,
            testSof.Id,
            IEN_INPROGRESS_STATUS,
            1,
            System.today(),
            null,
            null,
            null,
            3,
            null,
			null,
            false
        );
        
        reduivy__Individual_Enrollment__c ienWithNonPriorityStatus = REDU_TestData_UTIL.newStudentIndividualEnrollment(
            testStudent.reduivy__Sample_Record_Code__c + '_nonpriority_status',
            testStudent.Id,
            testSof.Id,
            IEN_OPEN_STATUS,
            1,
            System.today(),
            null,
            null,
            null,
            3,
            null,
			null,
            false
        );
        
        reduivy__Individual_Enrollment__c ienWithdrawn = REDU_TestData_UTIL.newStudentIndividualEnrollment(
            testStudent.reduivy__Sample_Record_Code__c + '_withdrawn',
            testStudent.Id,
            testSof.Id,
            IEN_WITHDRAWN_STATUS,
            1,
            System.today(),
            null,
            null,
            null,
            3,
            null,
			null,
            false
        );
        
        reduivy__Individual_Enrollment__c ienDropped = REDU_TestData_UTIL.newStudentIndividualEnrollment(
            testStudent.reduivy__Sample_Record_Code__c + '_dropped',
            testStudent.Id,
            testSof.Id,
            IEN_DROPPED_STATUS,
            1,
            System.today(),
            null,
            null,
            null,
            3,
            null,
			null,
            false
        );
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Test 1: Insert with blank status - should NOT trigger reassign
            Integer ipsCountBefore = [SELECT COUNT() FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
                AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c = :testStudent.Id];
            
            insert ienWithBlankStatus;
            
            Integer ipsCountBlankStatus = [SELECT COUNT() FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Individual_Enrollment__c = :ienWithBlankStatus.Id];
            
            System.Assert.areEqual(0, ipsCountBlankStatus,
                'No IPS should be linked when inserting IEN with blank status');
            
            // Test 2: Insert with priority status - should trigger reassign
            insert ienWithPriorityStatus;
            
            Integer ipsCountPriorityStatus = [SELECT COUNT() FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Individual_Enrollment__c = :ienWithPriorityStatus.Id];
            
            System.Assert.isTrue(ipsCountPriorityStatus > 0,
                'IPS should be linked when inserting IEN with priority status');
            
            // Test 3: Insert with non-priority status - should NOT trigger reassign
            insert ienWithNonPriorityStatus;
            
            Integer ipsCountNonPriorityStatus = [SELECT COUNT() FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Individual_Enrollment__c = :ienWithNonPriorityStatus.Id];
            
            System.Assert.areEqual(0, ipsCountNonPriorityStatus,
                'No IPS should be linked when inserting IEN with non-priority status');
            
            // Test 4: Update from non-priority to priority - should trigger reassign
            ienWithNonPriorityStatus.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_STATUS;
            update ienWithNonPriorityStatus;
            
            // Should reassign to higher priority IEN
            List<reduivy__Individual_Plan_Structure__c> ipsAfterUpdate = [
                SELECT Id, reduivy__Individual_Enrollment__c
                FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
                AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c = :testStudent.Id
            ];
            
            // Should be linked to highest priority IEN (INPROGRESS has highest priority)
            System.Assert.areEqual(ienWithPriorityStatus.Id, ipsAfterUpdate[0].reduivy__Individual_Enrollment__c,
                'IPS should be linked to highest priority IEN after update');
            
            // Test 5: Update within same priority level - should NOT trigger reassign
            Id currentLinkedIen = ipsAfterUpdate[0].reduivy__Individual_Enrollment__c;
            
            insert ienWithdrawn;
            insert ienDropped;
            
            // Update withdrawn to dropped (both priority 4)
            ienWithdrawn.reduivy__Enrollment_Status__c = IEN_DROPPED_STATUS;
            update ienWithdrawn;
            
            List<reduivy__Individual_Plan_Structure__c> ipsAfterSamePriorityUpdate = [
                SELECT Id, reduivy__Individual_Enrollment__c
                FROM reduivy__Individual_Plan_Structure__c 
                WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Target_Unit_Id__c IN: studyUnits.keySet()
                AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c = :testStudent.Id
            ];
            
            // Should still be linked to the same highest priority IEN
            System.Assert.areEqual(currentLinkedIen, ipsAfterSamePriorityUpdate[0].reduivy__Individual_Enrollment__c,
                'IPS should remain linked to same IEN when updating within same priority level');
            
            Test.stopTest();
        }
    }

    /**
     * @description Test that IPS reassignment is filtered by Individual Academic Profile as admin
     */
    @IsTest
    static void testIpsReassignmentFilteredByIpfAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

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

        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
            
        // Create two different Individual Academic Profiles for the same student
        for (Contact student : studentContacts) {
            // Primary IPF
            ipfMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPF_Primary',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF_Primary',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF_Primary',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
            
            // Secondary IPF (different program)
            ipfMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPF_Secondary',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF_Secondary',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF_Secondary',
                    IPF_Helper.STATUS_ACTIVE,
                    false
                )
            );
        }
        
        insert ipfMap.values();
        
        // Create IPE for each IPF
        for (Contact student : studentContacts) {
            // IPE for Primary IPF
            ipeMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPE_Primary',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE_Primary',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get(student.reduivy__Sample_Record_Code__c + '_IPF_Primary').Id
                )
            );
            
            // IPE for Secondary IPF
            ipeMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPE_Secondary',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE_Secondary',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get(student.reduivy__Sample_Record_Code__c + '_IPF_Secondary').Id
                )
            );
        }
        
        insert ipeMap.values();
        
        // Verify both IPE have IPS created
        Map<Id, List<reduivy__Individual_Plan_Structure__c>> ipeIpsMap = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
        
        for (reduivy__Individual_Plan_Structure__c ips : [
            SELECT Id, 
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Individual_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c IN :ipeMap.values()
            AND reduivy__Target_Unit_Id__c IN :studyUnits.keySet()
        ]) {
            if (!ipeIpsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipeIpsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipeIpsMap.get(ips.reduivy__Individual_Program_Enrollment__c).add(ips);
            
            // Initially, IPS should not be linked to any IEN
            System.Assert.isNull(ips.reduivy__Individual_Enrollment__c, 'IPS should not be linked to IEN initially');
        }
        
        System.Assert.areEqual(2, ipeIpsMap.size(), 'Both IPE should have IPS created');
        
        // Create IEN for Primary IPF only
        Map<String, reduivy__Individual_Enrollment__c> ienMap = new Map<String, reduivy__Individual_Enrollment__c>();
        
        System.runAs(ADMIN_USER) {
            Test.startTest();

            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c IN: studyUnits.values()
            ]) {
                for (Contact student : studentContacts) {
                    ienMap.put(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_Primary',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_Primary',
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
                            ipfMap.get(student.reduivy__Sample_Record_Code__c + '_IPF_Primary').Id,
                            true
                        )
                    );
                }
            }
            
            insert ienMap.values();
            Test.stopTest();
        }
        
        // Verify IPS linkage - only Primary IPF's IPS should be linked
        Map<Id, List<reduivy__Individual_Plan_Structure__c>> ipeIpsAfterMap = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
        
        for (reduivy__Individual_Plan_Structure__c ips : [
            SELECT Id, 
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Individual_Enrollment__c,
            reduivy__Individual_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c IN :ipeMap.values()
            AND reduivy__Target_Unit_Id__c IN :studyUnits.keySet()
        ]) {
            if (!ipeIpsAfterMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipeIpsAfterMap.put(ips.reduivy__Individual_Program_Enrollment__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipeIpsAfterMap.get(ips.reduivy__Individual_Program_Enrollment__c).add(ips);
            
            // Check if this IPS belongs to Primary IPF
            for (Contact student : studentContacts) {
                Id primaryIpfId = ipfMap.get(student.reduivy__Sample_Record_Code__c + '_IPF_Primary').Id;
                Id secondaryIpfId = ipfMap.get(student.reduivy__Sample_Record_Code__c + '_IPF_Secondary').Id;
                
                if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == primaryIpfId) {
                    // Primary IPF's IPS should be linked to IEN
                    System.Assert.isNotNull(ips.reduivy__Individual_Enrollment__c, 
                        'IPS under Primary IPF should be linked to IEN');
                    System.Assert.areEqual(primaryIpfId, ips.reduivy__Individual_Enrollment__r.reduivy__Individual_Academic_Profile__c,
                        'IEN should belong to the same IPF as IPS');
                    System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c,
                        'IPS status should match IEN status');
                        
                } else if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == secondaryIpfId) {
                    // Secondary IPF's IPS should NOT be linked (no IEN created for this IPF)
                    System.Assert.isNull(ips.reduivy__Individual_Enrollment__c, 
                        'IPS under Secondary IPF should NOT be linked to IEN from different IPF');
                }
            }
        }
    }

    /**
     * @description Test that IPS reassignment respects IPF boundaries when deleting IEN as admin
     */
    @IsTest
    static void testIpsReassignmentByIpfOnDeleteAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101
            LIMIT 1
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

        reduivy__Study_Term__c academicTerm = [SELECT Id
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> ienMap = new Map<String, reduivy__Individual_Enrollment__c>();
            
        // Create two IPF for the same student
        for (Contact student : studentContacts) {
            ipfMap.put(
                'IPF1',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF1',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF1',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
            
            ipfMap.put(
                'IPF2',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF2',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF2',
                    IPF_Helper.STATUS_ACTIVE,
                    false
                )
            );
        }
        
        insert ipfMap.values();
        
        // Create IPE for each IPF
        for (Contact student : studentContacts) {
            ipeMap.put(
                'IPE1',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE1',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null, null, null, null, null, null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get('IPF1').Id
                )
            );
            
            ipeMap.put(
                'IPE2',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE2',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null, null, null, null, null, null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get('IPF2').Id
                )
            );
        }
        
        insert ipeMap.values();

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Create IEN for both IPF with different attempt numbers
            for (reduivy__Study_Offering__c sof : [SELECT Id
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c IN: studyUnits.values()
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    // IPF1 - Attempt 2 (higher priority)
                    ienMap.put(
                        'IEN_IPF1_Attempt2',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_IPF1_A2',
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            2,
                            System.today(),
                            null, null, null, 3, null,
                            ipfMap.get('IPF1').Id,
                            true
                        )
                    );
                    
                    // IPF1 - Attempt 1 (lower priority)
                    ienMap.put(
                        'IEN_IPF1_Attempt1',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_IPF1_A1',
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today().addDays(-1),
                            null, null, null, 3, null,
                            ipfMap.get('IPF1').Id,
                            true
                        )
                    );
                    
                    // IPF2 - Attempt 1
                    ienMap.put(
                        'IEN_IPF2_Attempt1',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_IPF2_A1',
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today(),
                            null, null, null, 3, null,
                            ipfMap.get('IPF2').Id,
                            true
                        )
                    );
                }
            }
            
            insert ienMap.values();
        }
        
        // Verify initial state - each IPF's IPS should link to their respective highest priority IEN
        Map<Id, reduivy__Individual_Plan_Structure__c> ipfToIpsMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        
        for (reduivy__Individual_Plan_Structure__c ips : [
            SELECT Id,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Enrollment__c,
            reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.Name
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c IN :ipeMap.values()
            AND reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            ipfToIpsMap.put(ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c, ips);
            
            if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == ipfMap.get('IPF1').Id) {
                System.Assert.areEqual(2, ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
                    'IPF1 IPS should link to Attempt 2');
            } else if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == ipfMap.get('IPF2').Id) {
                System.Assert.areEqual(1, ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
                    'IPF2 IPS should link to Attempt 1');
            }
        }
        
        // Delete IPF1's Attempt 2 IEN
        System.runAs(ADMIN_USER) {
            delete ienMap.get('IEN_IPF1_Attempt2');
            Test.stopTest();
        }
        
        // Verify after deletion
        for (reduivy__Individual_Plan_Structure__c ips : [
            SELECT Id,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Enrollment__c,
            reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c IN :ipeMap.values()
            AND reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == ipfMap.get('IPF1').Id) {
                // IPF1's IPS should now link to Attempt 1 (fallback within same IPF)
                System.Assert.isNotNull(ips.reduivy__Individual_Enrollment__c,
                    'IPF1 IPS should reassign to remaining IEN within same IPF');
                System.Assert.areEqual(1, ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
                    'IPF1 IPS should link to Attempt 1 after Attempt 2 deletion');
                    
            } else if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == ipfMap.get('IPF2').Id) {
                // IPF2's IPS should remain unchanged (still linked to its own Attempt 1)
                System.Assert.areEqual(1, ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
                    'IPF2 IPS should remain unchanged, still linked to its own IEN');
            }
        }
    }

    /**
     * @description Test IPS reassignment with multiple IPF and priority changes as admin
     */
    @IsTest
    static void testIpsReassignmentByIpfOnUpdateAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101
            LIMIT 1
        ]);

        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

        reduivy__Study_Term__c academicTerm = [SELECT Id
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> ienMap = new Map<String, reduivy__Individual_Enrollment__c>();
            
        // Create two IPF for the same student
        for (Contact student : studentContacts) {
            ipfMap.put(
                'IPF1',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF1',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF1',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
            
            ipfMap.put(
                'IPF2',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF2',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF2',
                    IPF_Helper.STATUS_ACTIVE,
                    false
                )
            );
        }
        
        insert ipfMap.values();
        
        // Create IPE for each IPF
        for (Contact student : studentContacts) {
            ipeMap.put(
                'IPE1',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE1',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null, // studyIntakeId
                    null, // startingTermId
                    null, // studyPathwayId
                    null, // defaultCampusId
                    null, // classYear
                    null, // classStanding
                    true, // eligibleToEnroll
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get('IPF1').Id
                )
            );
            
            ipeMap.put(
                'IPE2',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE2',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null, // studyIntakeId
                    null, // startingTermId
                    null, // studyPathwayId
                    null, // defaultCampusId
                    null, // classYear
                    null, // classStanding
                    true, // eligibleToEnroll
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get('IPF2').Id
                )
            );
        }
        
        insert ipeMap.values();

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Create multiple IEN for both IPF with different statuses
            for (reduivy__Study_Offering__c sof : [SELECT Id
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c IN: studyUnits.values()
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    // IPF1 - Open status IEN (Attempt 1) - will be updated to Withdrawn
                    ienMap.put(
                        'IEN1_Open',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_IEN1_Open',
                            student.Id,
                            sof.Id,
                            IEN_OPEN_STATUS,
                            1,
                            System.today(),
                            null, null, null, 3, null,
                            ipfMap.get('IPF1').Id,
                            true
                        )
                    );
                    
                    // IPF1 - InProgress status IEN (Attempt 2) - higher priority
                    ienMap.put(
                        'IEN1_InProgress',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_IEN1_InProgress',
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            2,
                            System.today(),
                            null, null, null, 3, null,
                            ipfMap.get('IPF1').Id,
                            true
                        )
                    );
                    
                    // IPF2 - InProgress status IEN (Attempt 1)
                    ienMap.put(
                        'IEN2_InProgress',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_IEN2_InProgress',
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today(),
                            null, null, null, 3, null,
                            ipfMap.get('IPF2').Id,
                            true
                        )
                    );
                }
            }
            
            insert ienMap.values();
        }
        
        // Verify initial state - IPF1's IPS should link to Attempt 2 (InProgress, higher attempt)
        Map<Id, reduivy__Individual_Plan_Structure__c> ipfIpsMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        
        for (reduivy__Individual_Plan_Structure__c ips : [
            SELECT Id,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Enrollment__c,
            reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
            reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c IN :ipeMap.values()
            AND reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            ipfIpsMap.put(ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c, ips);
        }
        
        System.Assert.areEqual(2, ipfIpsMap.size(), 'Both IPF should have IPS');
        System.Assert.areEqual(
            2, 
            ipfIpsMap.get(ipfMap.get('IPF1').Id).reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
            'IPF1 IPS should initially link to Attempt 2 (InProgress)'
        );
        System.Assert.areEqual(
            1, 
            ipfIpsMap.get(ipfMap.get('IPF2').Id).reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
            'IPF2 IPS should link to Attempt 1'
        );
        
        // Update IPF1's Open status IEN to Withdrawn (has configured priority but lower than InProgress)
        System.runAs(ADMIN_USER) {
            reduivy__Individual_Enrollment__c ienToUpdate = ienMap.get('IEN1_Open');
            ienToUpdate.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_STATUS;
            update ienToUpdate;
            Test.stopTest();
        }
        
        // Verify after update - IPF1's IPS should remain linked to Attempt 2
        // because InProgress has higher priority than Withdrawn
        for (reduivy__Individual_Plan_Structure__c ips : [
            SELECT Id,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Enrollment__c,
            reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
            reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c IN :ipeMap.values()
            AND reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == ipfMap.get('IPF1').Id) {
                // IPF1's IPS should still link to Attempt 2 (InProgress has higher priority than Withdrawn)
                System.Assert.areEqual(
                    2, 
                    ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
                    'IPF1 IPS should still link to Attempt 2 after update (InProgress has higher priority)'
                );
                System.Assert.areEqual(
                    IEN_INPROGRESS_STATUS,
                    ips.reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c,
                    'IPF1 IPS should link to InProgress status IEN'
                );
                System.Assert.areEqual(
                    IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS),
                    ips.reduivy__Status__c,
                    'IPF1 IPS status should match InProgress IEN'
                );
                    
            } else if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == ipfMap.get('IPF2').Id) {
                // IPF2's IPS should remain completely unchanged
                System.Assert.areEqual(
                    1, 
                    ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
                    'IPF2 IPS should remain unchanged at Attempt 1'
                );
                System.Assert.areEqual(
                    IEN_INPROGRESS_STATUS,
                    ips.reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c,
                    'IPF2 IPS should remain linked to its own InProgress IEN'
                );
                System.Assert.areEqual(
                    IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS),
                    ips.reduivy__Status__c,
                    'IPF2 IPS status should remain as InProgress'
                );
            }
        }
    }

    /**
     * @description Test that IPS reassignment is filtered by Individual Academic Profile as faculty
     */
    @IsTest
    static void testIpsReassignmentFilteredByIpfAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

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

        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
            
        // Create two different Individual Academic Profiles for the same student
        for (Contact student : studentContacts) {
            // Primary IPF
            ipfMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPF_Primary',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF_Primary',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF_Primary',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
            
            // Secondary IPF (different program)
            ipfMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPF_Secondary',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF_Secondary',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF_Secondary',
                    IPF_Helper.STATUS_ACTIVE,
                    false
                )
            );
        }
        
        insert ipfMap.values();
        
        // Create IPE for each IPF
        for (Contact student : studentContacts) {
            // IPE for Primary IPF
            ipeMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPE_Primary',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE_Primary',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get(student.reduivy__Sample_Record_Code__c + '_IPF_Primary').Id
                )
            );
            
            // IPE for Secondary IPF
            ipeMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPE_Secondary',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE_Secondary',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get(student.reduivy__Sample_Record_Code__c + '_IPF_Secondary').Id
                )
            );
        }
        
        insert ipeMap.values();
        
        // Verify both IPE have IPS created
        Map<Id, List<reduivy__Individual_Plan_Structure__c>> ipeIpsMap = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
        
        for (reduivy__Individual_Plan_Structure__c ips : [
            SELECT Id, 
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Individual_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c IN :ipeMap.values()
            AND reduivy__Target_Unit_Id__c IN :studyUnits.keySet()
        ]) {
            if (!ipeIpsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipeIpsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipeIpsMap.get(ips.reduivy__Individual_Program_Enrollment__c).add(ips);
            
            // Initially, IPS should not be linked to any IEN
            System.Assert.isNull(ips.reduivy__Individual_Enrollment__c, 'IPS should not be linked to IEN initially');
        }
        
        System.Assert.areEqual(2, ipeIpsMap.size(), 'Both IPE should have IPS created');
        
        // Create IEN for Primary IPF only
        Map<String, reduivy__Individual_Enrollment__c> ienMap = new Map<String, reduivy__Individual_Enrollment__c>();
        
        System.runAs(FACULTY_USER) {
            Test.startTest();

            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c IN: studyUnits.values()
            ]) {
                for (Contact student : studentContacts) {
                    ienMap.put(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_Primary',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_Primary',
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
                            ipfMap.get(student.reduivy__Sample_Record_Code__c + '_IPF_Primary').Id,
                            true
                        )
                    );
                }
            }
            
            insert ienMap.values();
            Test.stopTest();
        }
        
        // Verify IPS linkage - only Primary IPF's IPS should be linked
        Map<Id, List<reduivy__Individual_Plan_Structure__c>> ipeIpsAfterMap = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
        
        for (reduivy__Individual_Plan_Structure__c ips : [
            SELECT Id, 
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Individual_Enrollment__c,
            reduivy__Individual_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c IN :ipeMap.values()
            AND reduivy__Target_Unit_Id__c IN :studyUnits.keySet()
        ]) {
            if (!ipeIpsAfterMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipeIpsAfterMap.put(ips.reduivy__Individual_Program_Enrollment__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipeIpsAfterMap.get(ips.reduivy__Individual_Program_Enrollment__c).add(ips);
            
            // Check if this IPS belongs to Primary IPF
            for (Contact student : studentContacts) {
                Id primaryIpfId = ipfMap.get(student.reduivy__Sample_Record_Code__c + '_IPF_Primary').Id;
                Id secondaryIpfId = ipfMap.get(student.reduivy__Sample_Record_Code__c + '_IPF_Secondary').Id;
                
                if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == primaryIpfId) {
                    // Primary IPF's IPS should be linked to IEN
                    System.Assert.isNotNull(ips.reduivy__Individual_Enrollment__c, 
                        'IPS under Primary IPF should be linked to IEN');
                    System.Assert.areEqual(primaryIpfId, ips.reduivy__Individual_Enrollment__r.reduivy__Individual_Academic_Profile__c,
                        'IEN should belong to the same IPF as IPS');
                    System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c,
                        'IPS status should match IEN status');
                        
                } else if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == secondaryIpfId) {
                    // Secondary IPF's IPS should NOT be linked (no IEN created for this IPF)
                    System.Assert.isNull(ips.reduivy__Individual_Enrollment__c, 
                        'IPS under Secondary IPF should NOT be linked to IEN from different IPF');
                }
            }
        }
    }

    /**
     * @description Test that IPS reassignment respects IPF boundaries when deleting IEN as faculty
     */
    @IsTest
    static void testIpsReassignmentByIpfOnDeleteAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101
            LIMIT 1
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

        reduivy__Study_Term__c academicTerm = [SELECT Id
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> ienMap = new Map<String, reduivy__Individual_Enrollment__c>();
            
        // Create two IPF for the same student
        for (Contact student : studentContacts) {
            ipfMap.put(
                'IPF1',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF1',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF1',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
            
            ipfMap.put(
                'IPF2',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF2',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF2',
                    IPF_Helper.STATUS_ACTIVE,
                    false
                )
            );
        }
        
        insert ipfMap.values();
        
        // Create IPE for each IPF
        for (Contact student : studentContacts) {
            ipeMap.put(
                'IPE1',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE1',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null, null, null, null, null, null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get('IPF1').Id
                )
            );
            
            ipeMap.put(
                'IPE2',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE2',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null, null, null, null, null, null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get('IPF2').Id
                )
            );
        }
        
        insert ipeMap.values();

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Create IEN for both IPF with different attempt numbers
            for (reduivy__Study_Offering__c sof : [SELECT Id
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c IN: studyUnits.values()
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    // IPF1 - Attempt 2 (higher priority)
                    ienMap.put(
                        'IEN_IPF1_Attempt2',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_IPF1_A2',
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            2,
                            System.today(),
                            null, null, null, 3, null,
                            ipfMap.get('IPF1').Id,
                            true
                        )
                    );
                    
                    // IPF1 - Attempt 1 (lower priority)
                    ienMap.put(
                        'IEN_IPF1_Attempt1',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_IPF1_A1',
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today().addDays(-1),
                            null, null, null, 3, null,
                            ipfMap.get('IPF1').Id,
                            true
                        )
                    );
                    
                    // IPF2 - Attempt 1
                    ienMap.put(
                        'IEN_IPF2_Attempt1',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_IPF2_A1',
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today(),
                            null, null, null, 3, null,
                            ipfMap.get('IPF2').Id,
                            true
                        )
                    );
                }
            }
            
            insert ienMap.values();
        }
        
        // Verify initial state - each IPF's IPS should link to their respective highest priority IEN
        Map<Id, reduivy__Individual_Plan_Structure__c> ipfToIpsMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        
        for (reduivy__Individual_Plan_Structure__c ips : [
            SELECT Id,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Enrollment__c,
            reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.Name
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c IN :ipeMap.values()
            AND reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            ipfToIpsMap.put(ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c, ips);
            
            if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == ipfMap.get('IPF1').Id) {
                System.Assert.areEqual(2, ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
                    'IPF1 IPS should link to Attempt 2');
            } else if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == ipfMap.get('IPF2').Id) {
                System.Assert.areEqual(1, ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
                    'IPF2 IPS should link to Attempt 1');
            }
        }
        
        // Delete IPF1's Attempt 2 IEN
        System.runAs(FACULTY_USER) {
            delete ienMap.get('IEN_IPF1_Attempt2');
            Test.stopTest();
        }
        
        // Verify after deletion
        for (reduivy__Individual_Plan_Structure__c ips : [
            SELECT Id,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Enrollment__c,
            reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c IN :ipeMap.values()
            AND reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == ipfMap.get('IPF1').Id) {
                // IPF1's IPS should now link to Attempt 1 (fallback within same IPF)
                System.Assert.isNotNull(ips.reduivy__Individual_Enrollment__c,
                    'IPF1 IPS should reassign to remaining IEN within same IPF');
                System.Assert.areEqual(1, ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
                    'IPF1 IPS should link to Attempt 1 after Attempt 2 deletion');
                    
            } else if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == ipfMap.get('IPF2').Id) {
                // IPF2's IPS should remain unchanged (still linked to its own Attempt 1)
                System.Assert.areEqual(1, ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
                    'IPF2 IPS should remain unchanged, still linked to its own IEN');
            }
        }
    }

    /**
     * @description Test IPS reassignment with multiple IPF and priority changes as faculty
     */
    @IsTest
    static void testIpsReassignmentByIpfOnUpdateAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101
            LIMIT 1
        ]);

        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

        reduivy__Study_Term__c academicTerm = [SELECT Id
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> ienMap = new Map<String, reduivy__Individual_Enrollment__c>();
            
        // Create two IPF for the same student
        for (Contact student : studentContacts) {
            ipfMap.put(
                'IPF1',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF1',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF1',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
            
            ipfMap.put(
                'IPF2',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF2',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF2',
                    IPF_Helper.STATUS_ACTIVE,
                    false
                )
            );
        }
        
        insert ipfMap.values();
        
        // Create IPE for each IPF
        for (Contact student : studentContacts) {
            ipeMap.put(
                'IPE1',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE1',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null, // studyIntakeId
                    null, // startingTermId
                    null, // studyPathwayId
                    null, // defaultCampusId
                    null, // classYear
                    null, // classStanding
                    true, // eligibleToEnroll
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get('IPF1').Id
                )
            );
            
            ipeMap.put(
                'IPE2',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE2',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null, // studyIntakeId
                    null, // startingTermId
                    null, // studyPathwayId
                    null, // defaultCampusId
                    null, // classYear
                    null, // classStanding
                    true, // eligibleToEnroll
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get('IPF2').Id
                )
            );
        }
        
        insert ipeMap.values();

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Create multiple IEN for both IPF with different statuses
            for (reduivy__Study_Offering__c sof : [SELECT Id
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c IN: studyUnits.values()
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    // IPF1 - Open status IEN (Attempt 1) - will be updated to Withdrawn
                    ienMap.put(
                        'IEN1_Open',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_IEN1_Open',
                            student.Id,
                            sof.Id,
                            IEN_OPEN_STATUS,
                            1,
                            System.today(),
                            null, null, null, 3, null,
                            ipfMap.get('IPF1').Id,
                            true
                        )
                    );
                    
                    // IPF1 - InProgress status IEN (Attempt 2) - higher priority
                    ienMap.put(
                        'IEN1_InProgress',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_IEN1_InProgress',
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            2,
                            System.today(),
                            null, null, null, 3, null,
                            ipfMap.get('IPF1').Id,
                            true
                        )
                    );
                    
                    // IPF2 - InProgress status IEN (Attempt 1)
                    ienMap.put(
                        'IEN2_InProgress',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_IEN2_InProgress',
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today(),
                            null, null, null, 3, null,
                            ipfMap.get('IPF2').Id,
                            true
                        )
                    );
                }
            }
            
            insert ienMap.values();
        }
        
        // Verify initial state - IPF1's IPS should link to Attempt 2 (InProgress, higher attempt)
        Map<Id, reduivy__Individual_Plan_Structure__c> ipfIpsMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        
        for (reduivy__Individual_Plan_Structure__c ips : [
            SELECT Id,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Enrollment__c,
            reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
            reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c IN :ipeMap.values()
            AND reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            ipfIpsMap.put(ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c, ips);
        }
        
        System.Assert.areEqual(2, ipfIpsMap.size(), 'Both IPF should have IPS');
        System.Assert.areEqual(
            2, 
            ipfIpsMap.get(ipfMap.get('IPF1').Id).reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
            'IPF1 IPS should initially link to Attempt 2 (InProgress)'
        );
        System.Assert.areEqual(
            1, 
            ipfIpsMap.get(ipfMap.get('IPF2').Id).reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
            'IPF2 IPS should link to Attempt 1'
        );
        
        // Update IPF1's Open status IEN to Withdrawn (has configured priority but lower than InProgress)
        System.runAs(FACULTY_USER) {
            reduivy__Individual_Enrollment__c ienToUpdate = ienMap.get('IEN1_Open');
            ienToUpdate.reduivy__Enrollment_Status__c = IEN_WITHDRAWN_STATUS;
            update ienToUpdate;
            Test.stopTest();
        }
        
        // Verify after update - IPF1's IPS should remain linked to Attempt 2
        // because InProgress has higher priority than Withdrawn
        for (reduivy__Individual_Plan_Structure__c ips : [
            SELECT Id,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Enrollment__c,
            reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
            reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c IN :ipeMap.values()
            AND reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c IN: studyUnits.values()
        ]) {
            if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == ipfMap.get('IPF1').Id) {
                // IPF1's IPS should still link to Attempt 2 (InProgress has higher priority than Withdrawn)
                System.Assert.areEqual(
                    2, 
                    ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
                    'IPF1 IPS should still link to Attempt 2 after update (InProgress has higher priority)'
                );
                System.Assert.areEqual(
                    IEN_INPROGRESS_STATUS,
                    ips.reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c,
                    'IPF1 IPS should link to InProgress status IEN'
                );
                System.Assert.areEqual(
                    IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS),
                    ips.reduivy__Status__c,
                    'IPF1 IPS status should match InProgress IEN'
                );
                    
            } else if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == ipfMap.get('IPF2').Id) {
                // IPF2's IPS should remain completely unchanged
                System.Assert.areEqual(
                    1, 
                    ips.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c,
                    'IPF2 IPS should remain unchanged at Attempt 1'
                );
                System.Assert.areEqual(
                    IEN_INPROGRESS_STATUS,
                    ips.reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c,
                    'IPF2 IPS should remain linked to its own InProgress IEN'
                );
                System.Assert.areEqual(
                    IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS),
                    ips.reduivy__Status__c,
                    'IPF2 IPS status should remain as InProgress'
                );
            }
        }
    }

    /**
     * @description Test that IPS reassignment is filtered by Individual Academic Profile as student
     */
    @IsTest
    static void testIpsReassignmentFilteredByIpfAsStudent() {
        
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

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, 
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR reduivy__Unit_Code__c =: STUDY_UNIT_BUS102
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No sun found for testing.');

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

        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
            
        // Create two different Individual Academic Profiles for the same student
        for (Contact student : studentContacts) {
            // Primary IPF
            ipfMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPF_Primary',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF_Primary',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF_Primary',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
            
            // Secondary IPF (different program)
            ipfMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPF_Secondary',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF_Secondary',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF_Secondary',
                    IPF_Helper.STATUS_ACTIVE,
                    false
                )
            );
        }
        
        insert ipfMap.values();
        
        // Create IPE for each IPF
        for (Contact student : studentContacts) {
            // IPE for Primary IPF
            ipeMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPE_Primary',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE_Primary',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get(student.reduivy__Sample_Record_Code__c + '_IPF_Primary').Id
                )
            );
            
            // IPE for Secondary IPF
            ipeMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPE_Secondary',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE_Secondary',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get(student.reduivy__Sample_Record_Code__c + '_IPF_Secondary').Id
                )
            );
        }
        
        insert ipeMap.values();
        
        // Verify both IPE have IPS created
        Map<Id, List<reduivy__Individual_Plan_Structure__c>> ipeIpsMap = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
        
        for (reduivy__Individual_Plan_Structure__c ips : [
            SELECT Id, 
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Individual_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c IN :ipeMap.values()
            AND reduivy__Target_Unit_Id__c IN :studyUnits.keySet()
        ]) {
            if (!ipeIpsMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipeIpsMap.put(ips.reduivy__Individual_Program_Enrollment__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipeIpsMap.get(ips.reduivy__Individual_Program_Enrollment__c).add(ips);
            
            // Initially, IPS should not be linked to any IEN
            System.Assert.isNull(ips.reduivy__Individual_Enrollment__c, 'IPS should not be linked to IEN initially');
        }
        
        System.Assert.areEqual(2, ipeIpsMap.size(), 'Both IPE should have IPS created');
        
        // Create IEN for Primary IPF only
        Map<String, reduivy__Individual_Enrollment__c> ienMap = new Map<String, reduivy__Individual_Enrollment__c>();
        
        System.runAs(studentUser) {
            Test.startTest();

            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c IN: studyUnits.values()
            ]) {
                for (Contact student : studentContacts) {
                    ienMap.put(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_Primary',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_Primary',
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
                            ipfMap.get(student.reduivy__Sample_Record_Code__c + '_IPF_Primary').Id,
                            true
                        )
                    );
                }
            }
            
            insert ienMap.values();
            Test.stopTest();
        }
        
        // Verify IPS linkage - only Primary IPF's IPS should be linked
        Map<Id, List<reduivy__Individual_Plan_Structure__c>> ipeIpsAfterMap = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
        
        for (reduivy__Individual_Plan_Structure__c ips : [
            SELECT Id, 
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Individual_Enrollment__c,
            reduivy__Individual_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c IN :ipeMap.values()
            AND reduivy__Target_Unit_Id__c IN :studyUnits.keySet()
        ]) {
            if (!ipeIpsAfterMap.containsKey(ips.reduivy__Individual_Program_Enrollment__c)) {
                ipeIpsAfterMap.put(ips.reduivy__Individual_Program_Enrollment__c, new List<reduivy__Individual_Plan_Structure__c>());
            }
            ipeIpsAfterMap.get(ips.reduivy__Individual_Program_Enrollment__c).add(ips);
            
            // Check if this IPS belongs to Primary IPF
            for (Contact student : studentContacts) {
                Id primaryIpfId = ipfMap.get(student.reduivy__Sample_Record_Code__c + '_IPF_Primary').Id;
                Id secondaryIpfId = ipfMap.get(student.reduivy__Sample_Record_Code__c + '_IPF_Secondary').Id;
                
                if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == primaryIpfId) {
                    // Primary IPF's IPS should be linked to IEN
                    System.Assert.isNotNull(ips.reduivy__Individual_Enrollment__c, 
                        'IPS under Primary IPF should be linked to IEN');
                    System.Assert.areEqual(primaryIpfId, ips.reduivy__Individual_Enrollment__r.reduivy__Individual_Academic_Profile__c,
                        'IEN should belong to the same IPF as IPS');
                    System.Assert.areEqual(IPSUSTATUSMAP.get(IEN_INPROGRESS_STATUS), ips.reduivy__Status__c,
                        'IPS status should match IEN status');
                        
                } else if (ips.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c == secondaryIpfId) {
                    // Secondary IPF's IPS should NOT be linked (no IEN created for this IPF)
                    System.Assert.isNull(ips.reduivy__Individual_Enrollment__c, 
                        'IPS under Secondary IPF should NOT be linked to IEN from different IPF');
                }
            }
        }
    }
}