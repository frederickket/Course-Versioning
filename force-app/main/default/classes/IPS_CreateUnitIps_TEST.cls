/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for IPS_CreateUnitIps_EXE
 * @changehistory
 * ISS-001815 12-12-2023 Lean - New class
 * ISS-002395 26-05-2025 XiRouh - Updated to cater the new priority logic
 * ISS-002486 10-06-2025 XiRouh - updated getCompletedStatuses to getCompletedPassStatuses
 * ISS-002542 14-07-2025 XiRouh - Added test methodd for the IEN creation logic
 * ISS-002743 15-12-2025 XiRouh - Added test methods to consider the IEN within the same Individual Academic Profile context and Updated test methods that create IENs to link them with IPF
 * ISS-002513 09-02-2026 XiRouh - Added test methods to cover the auto recognition cloning process
 */
@IsTest
public inherited sharing class IPS_CreateUnitIps_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    static String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);
    static String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
    static String IEN_COMPLETED_PASS_STATUS = IEN_Helper.getCompletedPassStatuses().get(0);
    static String IEN_COMPLETED_FAIL_STATUS = IEN_Helper.getCompletedFailStatuses().get(0);
    static String IEN_WITHDRAWN_STATUS = IEN_Helper.getWithdrawnStatuses().get(0);
    static String IEN_OPEN_STATUSES = IEN_Helper.getOpenStatuses().get(0);

    static final Map<String, String> IPSUSTATUSMAP = IPS_Helper.getIpsuStatusMap();

    /*
     * @description we mute some non related triggers to save the resources
     */
    static final Set<String> TRIGGERS_TO_MUTE = new Set<String>{
        'IEN_AcademicProgress_Before'
    };

    /**
     * @description Default method to setup required data for automated test
     */
    @TestSetup
    static void makeData(){

        // Create rio education ivy settings and sample data
        testFactory.setupDefaultSettings();
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(SPS_Helper.getApiName());
            testFactory.initOfferingData(SOF_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);

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
     * @description Triggers to unmute for test
     */
    private static void unmuteTriggers() {

        REDU_TriggerController.unmuteTriggers(TRIGGERS_TO_MUTE);

    }

    /**
     * @description Test the required unit individual plan structure creation when a new group individual plan structure is created from new individual enrollment.
     */
    @IsTest
    static void testRequiredUnitIpsCreationAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, 
            reduivy__Sample_Record_Code__c, 
            Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        Map<Id, reduivy__Study_Plan__c> studyPlans = new Map<Id, reduivy__Study_Plan__c>([SELECT Id, 
            reduivy__Study_Program__c,
            (
                SELECT Id,
                reduivy__Category__c,
                RecordTypeId,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Plan_Structures__r
            )
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
        ]);

        Map<Id, Decimal> studyPlansGroupCount = new Map<Id, Decimal>();
        Map<Id, Decimal> studyPlansRequiredUnitCount = new Map<Id, Decimal>();
        Set<Id> sunIds = new Set<Id>();

        for (reduivy__Study_Plan__c studyPlan : studyPlans.values()) {
            for (reduivy__Study_Plan_Structure__c sps : studyPlan.reduivy__Study_Plan_Structures__r) {
                if (sps.RecordTypeId == SPS_Helper.getUnitRecordTypeId()) {
                    if (sps.reduivy__Category__c == SPS_Helper.CATEGORY_REQUIRED) {
                        if (studyPlansRequiredUnitCount.containsKey(studyPlan.Id)) {
                            studyPlansRequiredUnitCount.put(studyPlan.Id, studyPlansRequiredUnitCount.get(studyPlan.Id) + 1);
                        } else {
                            studyPlansRequiredUnitCount.put(studyPlan.Id, 1);
                        }

                        sunIds.add(sps.reduivy__Study_Unit__c);
                    }
                } else if (sps.RecordTypeId == SPS_Helper.getGroupRecordTypeId()) {
                    if (studyPlansGroupCount.containsKey(studyPlan.Id)) {
                        studyPlansGroupCount.put(studyPlan.Id, studyPlansGroupCount.get(studyPlan.Id) + 1);
                    } else {
                        studyPlansGroupCount.put(studyPlan.Id, 1);
                    }
                }
            }
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

        List<reduivy__Individual_Academic_Profile__c> ipfToBeCreated = new List<reduivy__Individual_Academic_Profile__c>();
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (Contact student : students) {
            ipfToBeCreated.add(
                REDU_TestData_UTIL.newIndividualAcademicProfile(student.Id + '_' + student.Name, student.Id, student.Name, IPF_Helper.STATUS_ACTIVE, true)
            );
        }

        insert ipfToBeCreated;

        for (Integer i = 0; i < students.size(); i++) {
            studentToIPFMap.put(students[i].Id, ipfToBeCreated[i].Id);
        }

        List<Account> campus = [SELECT Id FROM Account WHERE Name = 'Sydney Campus' AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1];

        //To ensure all the study unit have a sof
        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();

        for(Id sunId : sunIds) {
            sofToBeCreated.add(REDU_TestData_UTIL.newStudyOffering(sunId + '_' + academicTerm.Id, sunId, academicTerm.Id, campus[0].Id, sunId + '_' + academicTerm.Id, 20, System.today(), System.today().addDays(30)));
        }

        insert sofToBeCreated;

        Map<String, reduivy__Individual_Enrollment__c> newIenWithCompletedStatusMap = new Map<String, reduivy__Individual_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> newIenWithWithdrawnStatusMap = new Map<String, reduivy__Individual_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> newIenWithInProgressStatusMap = new Map<String, reduivy__Individual_Enrollment__c>();

        for (reduivy__Study_Offering__c sof : sofToBeCreated) {
            for (Contact student : students) {
                newIenWithCompletedStatusMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
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
                    )
                );

                newIenWithWithdrawnStatusMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_WITHDRAWN_STATUS,
                        10,
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

                newIenWithInProgressStatusMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        20,
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

        insert newIenWithCompletedStatusMap.values();
        insert newIenWithWithdrawnStatusMap.values();
        insert newIenWithInProgressStatusMap.values();

        Test.startTest();

        System.runAs(ADMIN_USER){
            List<reduivy__Individual_Program_Enrollment__c> newIpes = new List<reduivy__Individual_Program_Enrollment__c>();

            for (Contact student : students) {
                for (reduivy__Study_Plan__c studyPlan : studyPlans.values()) {
                    newIpes.add(
                        REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                            student.Id + '_' + studyPlan.Id,
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
                            studentToIPFMap.get(student.Id)
                        )
                    );
                }
            }

            REDU_Database_UTIL.doInsert(newIpes);

            for (reduivy__Individual_Program_Enrollment__c ipe : [SELECT Id,
                reduivy__Study_Plan__c,
                (
                    SELECT Id,
                    RecordTypeId,
                    reduivy__Category__c,
                    reduivy__Status__c
                    FROM reduivy__Individual_Plan_Structures__r
                )
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE Id IN: newIpes
            ]) {
                
                Decimal groupIpsCount = 0;
                Decimal requiredUnitIpsCount = 0;
                for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
                    if (ips.RecordTypeId == IPS_Helper.getUnitRecordTypeId()) {
                        //we only expect required unit ips
                        System.Assert.areEqual(IPS_Helper.CATEGORY_REQUIRED, ips.reduivy__Category__c);
                        System.Assert.areEqual(IPS_Helper.STATUS_TYPE_COMPLETED, ips.reduivy__Status__c);
                        requiredUnitIpsCount ++;
                    } else if (ips.RecordTypeId == IPS_Helper.getGroupRecordTypeId()) {
                        groupIpsCount ++;
                    } else {
                        System.Assert.fail('The individual plan structure should have a RecordTypeId.');
                    }
                }

                System.Assert.areEqual(true, studyPlans.containsKey(ipe.reduivy__Study_Plan__c));
                System.Assert.areEqual(studyPlansGroupCount.get(ipe.reduivy__Study_Plan__c), groupIpsCount);
                System.Assert.areEqual(studyPlansRequiredUnitCount.get(ipe.reduivy__Study_Plan__c), requiredUnitIpsCount);
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test negative result for the automation to create the required unit individual plan structure creation when a new group individual plan structure is created from new individual enrollment.
     */
    @IsTest
    static void testRequiredUnitIpsCreationAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> students = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        Map<Id, reduivy__Study_Plan__c> studyPlans = new Map<Id, reduivy__Study_Plan__c>([SELECT Id, 
            reduivy__Study_Program__c,
            (
                SELECT Id,
                reduivy__Category__c,
                RecordTypeId,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Plan_Structures__r
            )
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' OR reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
        ]);

        Map<Id, Decimal> studyPlansGroupCount = new Map<Id, Decimal>();
        Map<Id, Decimal> studyPlansRequiredUnitCount = new Map<Id, Decimal>();
        Set<Id> sunIds = new Set<Id>();

        for (reduivy__Study_Plan__c studyPlan : studyPlans.values()) {
            for (reduivy__Study_Plan_Structure__c sps : studyPlan.reduivy__Study_Plan_Structures__r) {
                if (sps.RecordTypeId == SPS_Helper.getUnitRecordTypeId()) {
                    if (sps.reduivy__Category__c == SPS_Helper.CATEGORY_REQUIRED) {
                        if (studyPlansRequiredUnitCount.containsKey(studyPlan.Id)) {
                            studyPlansRequiredUnitCount.put(studyPlan.Id, studyPlansRequiredUnitCount.get(studyPlan.Id) + 1);
                        } else {
                            studyPlansRequiredUnitCount.put(studyPlan.Id, 1);
                        }

                        sunIds.add(sps.reduivy__Study_Unit__c);
                    }
                } else if (sps.RecordTypeId == SPS_Helper.getGroupRecordTypeId()) {
                    if (studyPlansGroupCount.containsKey(studyPlan.Id)) {
                        studyPlansGroupCount.put(studyPlan.Id, studyPlansGroupCount.get(studyPlan.Id) + 1);
                    } else {
                        studyPlansGroupCount.put(studyPlan.Id, 1);
                    }
                }
            }
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

        List<reduivy__Individual_Academic_Profile__c> ipfToBeCreated = new List<reduivy__Individual_Academic_Profile__c>();
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (Contact student : students) {
            ipfToBeCreated.add(
                REDU_TestData_UTIL.newIndividualAcademicProfile(student.Id + '_' + student.Name, student.Id, student.Name, IPF_Helper.STATUS_ACTIVE, true)
            );
        }

        insert ipfToBeCreated;

        for (Integer i = 0; i < students.size(); i++) {
            studentToIPFMap.put(students[i].Id, ipfToBeCreated[i].Id);
        }

        List<Account> campus = [SELECT Id FROM Account WHERE Name = 'Sydney Campus' AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1];

        //To ensure all the study unit have a sof
        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();

        for(Id sunId : sunIds) {
            sofToBeCreated.add(REDU_TestData_UTIL.newStudyOffering(sunId + '_' + academicTerm.Id, sunId, academicTerm.Id, campus[0].Id, sunId + '_' + academicTerm.Id, 20, System.today(), System.today().addDays(30)));
        }

        insert sofToBeCreated;

        Map<String, reduivy__Individual_Enrollment__c> newIenWithCompletedStatusMap = new Map<String, reduivy__Individual_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> newIenWithWithdrawnStatusMap = new Map<String, reduivy__Individual_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> newIenWithInProgressStatusMap = new Map<String, reduivy__Individual_Enrollment__c>();

        for (reduivy__Study_Offering__c sof : sofToBeCreated) {
            for (Contact student : students) {
                newIenWithCompletedStatusMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
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
                    )
                );

                newIenWithWithdrawnStatusMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_WITHDRAWN_STATUS,
                        10,
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

                newIenWithInProgressStatusMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        20,
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

        insert newIenWithCompletedStatusMap.values();
        insert newIenWithWithdrawnStatusMap.values();
        insert newIenWithInProgressStatusMap.values();

        Test.startTest();

        System.runAs(FACULTY_USER){
            List<reduivy__Individual_Program_Enrollment__c> newIpes = new List<reduivy__Individual_Program_Enrollment__c>();

            for (Contact student : students) {
                for (reduivy__Study_Plan__c studyPlan : studyPlans.values()) {
                    newIpes.add(
                        REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                            student.Id + '_' + studyPlan.Id,
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
                            studentToIPFMap.get(student.Id)
                        )
                    );
                }
            }

            try {
                REDU_Database_UTIL.doInsert(newIpes);
                System.Assert.fail('Faculty user should not have permission to create reduivy__Individual_Program_Enrollment__c.');

            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Insufficient CREATABLE access on following object(s) and field(s) - reduivy__Individual_Program_Enrollment__c'), 'Unexpected error: ' + exp.getMessage());
            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test negative result for the automation to create the required unit individual plan structure creation when a new group individual plan structure is created from new individual enrollment.
     */
    @IsTest
    static void testRequiredUnitIpsCreationAsStudent(){

        List<Contact> students = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId IN: students 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        Map<Id, reduivy__Study_Plan__c> studyPlans = new Map<Id, reduivy__Study_Plan__c>([SELECT Id, 
            reduivy__Study_Program__c,
            (
                SELECT Id,
                reduivy__Category__c,
                RecordTypeId,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Plan_Structures__r
            )
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' OR reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
        ]);

        Map<Id, Decimal> studyPlansGroupCount = new Map<Id, Decimal>();
        Map<Id, Decimal> studyPlansRequiredUnitCount = new Map<Id, Decimal>();
        Set<Id> sunIds = new Set<Id>();

        for (reduivy__Study_Plan__c studyPlan : studyPlans.values()) {
            for (reduivy__Study_Plan_Structure__c sps : studyPlan.reduivy__Study_Plan_Structures__r) {
                if (sps.RecordTypeId == SPS_Helper.getUnitRecordTypeId()) {
                    if (sps.reduivy__Category__c == SPS_Helper.CATEGORY_REQUIRED) {
                        if (studyPlansRequiredUnitCount.containsKey(studyPlan.Id)) {
                            studyPlansRequiredUnitCount.put(studyPlan.Id, studyPlansRequiredUnitCount.get(studyPlan.Id) + 1);
                        } else {
                            studyPlansRequiredUnitCount.put(studyPlan.Id, 1);
                        }

                        sunIds.add(sps.reduivy__Study_Unit__c);
                    }
                } else if (sps.RecordTypeId == SPS_Helper.getGroupRecordTypeId()) {
                    if (studyPlansGroupCount.containsKey(studyPlan.Id)) {
                        studyPlansGroupCount.put(studyPlan.Id, studyPlansGroupCount.get(studyPlan.Id) + 1);
                    } else {
                        studyPlansGroupCount.put(studyPlan.Id, 1);
                    }
                }
            }
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

        List<reduivy__Individual_Academic_Profile__c> ipfToBeCreated = new List<reduivy__Individual_Academic_Profile__c>();
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (Contact student : students) {
            ipfToBeCreated.add(
                REDU_TestData_UTIL.newIndividualAcademicProfile(student.Id + '_' + student.Name, student.Id, student.Name, IPF_Helper.STATUS_ACTIVE, true)
            );
        }

        insert ipfToBeCreated;

        for (Integer i = 0; i < students.size(); i++) {
            studentToIPFMap.put(students[i].Id, ipfToBeCreated[i].Id);
        }

        List<Account> campus = [SELECT Id FROM Account WHERE Name = 'Sydney Campus' AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1];

        //To ensure all the study unit have a sof
        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();

        for(Id sunId : sunIds) {
            sofToBeCreated.add(REDU_TestData_UTIL.newStudyOffering(sunId + '_' + academicTerm.Id, sunId, academicTerm.Id, campus[0].Id, sunId + '_' + academicTerm.Id, 20, System.today(), System.today().addDays(30)));
        }

        insert sofToBeCreated;

        Map<String, reduivy__Individual_Enrollment__c> newIenWithCompletedStatusMap = new Map<String, reduivy__Individual_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> newIenWithWithdrawnStatusMap = new Map<String, reduivy__Individual_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> newIenWithInProgressStatusMap = new Map<String, reduivy__Individual_Enrollment__c>();

        for (reduivy__Study_Offering__c sof : sofToBeCreated) {
            for (Contact student : students) {
                newIenWithCompletedStatusMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
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
                    )
                );

                newIenWithWithdrawnStatusMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_WITHDRAWN_STATUS,
                        10,
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

                newIenWithInProgressStatusMap.put(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        20,
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

        insert newIenWithCompletedStatusMap.values();
        insert newIenWithWithdrawnStatusMap.values();
        insert newIenWithInProgressStatusMap.values();

        Test.startTest();

        System.runAs(studentUser){
            List<reduivy__Individual_Program_Enrollment__c> newIpes = new List<reduivy__Individual_Program_Enrollment__c>();

            for (Contact student : students) {
                for (reduivy__Study_Plan__c studyPlan : studyPlans.values()) {
                    newIpes.add(
                        REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                            student.Id + '_' + studyPlan.Id,
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
                            studentToIPFMap.get(student.Id)
                        )
                    );
                }
            }

            try {
                REDU_Database_UTIL.doInsert(newIpes);
                System.Assert.fail('Student user should not have permission to create reduivy__Individual_Program_Enrollment__c.');

            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Insufficient CREATABLE access on following object(s) and field(s) - reduivy__Individual_Program_Enrollment__c'), 'Unexpected error: ' + exp.getMessage());
            }

        }

        Test.stopTest();
    }

    /**
     * @description Test the required unit individual plan structure creation when a new group individual plan structure is created from new individual enrollment. 
     *              The optional individual plan structure should also be created if it has individual enrollment for the same study unit.
     */
    @IsTest
    static void testOptionalUnitIpsCreationWithIndividualEnrollmentAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, Name,
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];

        Map<Id, reduivy__Study_Plan__c> studyPlans = new Map<Id, reduivy__Study_Plan__c>([SELECT Id, 
            reduivy__Study_Program__c,
            (
                SELECT Id,
                reduivy__Category__c,
                RecordTypeId,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Plan_Structures__r
            )
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' OR reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
        ]);

        Map<Id, Decimal> studyPlansGroupCount = new Map<Id, Decimal>();
        Map<Id, Decimal> studyPlansRequiredUnitCount = new Map<Id, Decimal>();
        Set<Id> sunIdsForEnrollment = new Set<Id>();

        for (reduivy__Study_Plan__c studyPlan : studyPlans.values()) {
            for (reduivy__Study_Plan_Structure__c sps : studyPlan.reduivy__Study_Plan_Structures__r) {
                if (sps.RecordTypeId == SPS_Helper.getUnitRecordTypeId()) {
                    if (sps.reduivy__Category__c == SPS_Helper.CATEGORY_REQUIRED) {
                        if (studyPlansRequiredUnitCount.containsKey(studyPlan.Id)) {
                            studyPlansRequiredUnitCount.put(studyPlan.Id, studyPlansRequiredUnitCount.get(studyPlan.Id) + 1);
                        } else {
                            studyPlansRequiredUnitCount.put(studyPlan.Id, 1);
                        }
                    } else {
                        System.Assert.isNotNull(sps.reduivy__Study_Unit__c);

                        sunIdsForEnrollment.add(sps.reduivy__Study_Unit__c);
                    }
                } else if (sps.RecordTypeId == SPS_Helper.getGroupRecordTypeId()) {
                    if (studyPlansGroupCount.containsKey(studyPlan.Id)) {
                        studyPlansGroupCount.put(studyPlan.Id, studyPlansGroupCount.get(studyPlan.Id) + 1);
                    } else {
                        studyPlansGroupCount.put(studyPlan.Id, 1);
                    }
                }
            }
        }

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();
        List<reduivy__Individual_Academic_Profile__c> ipfToBeCreated = new List<reduivy__Individual_Academic_Profile__c>();

        for (Contact student : students) {
            ipfToBeCreated.add(
                REDU_TestData_UTIL.newIndividualAcademicProfile(student.Id + '_' + student.Name, student.Id, student.Name, IPF_Helper.STATUS_ACTIVE, true)
            );
        }

        insert ipfToBeCreated;

        for (Integer i = 0; i < students.size(); i++) {
            studentToIPFMap.put(students[i].Id, ipfToBeCreated[i].Id);
        }

        Map<String, reduivy__Individual_Enrollment__c> newIndividualEnrollments = new Map<String, reduivy__Individual_Enrollment__c>();

        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Study_Unit__c
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c =: sunIdsForEnrollment
            LIMIT 2
        ]) {
            for (Contact student : students) {
                String sampleCode = student.Id + '_' + sof.reduivy__Study_Unit__c;

                newIndividualEnrollments.put(
                    sampleCode,
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        sampleCode,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        4,
                        null,
                        studentToIPFMap.get(student.Id),
                        true
                    )
                );
            }
        }

        System.Assert.isTrue(!newIndividualEnrollments.isEmpty());
        REDU_Database_UTIL.doInsert(newIndividualEnrollments.values());
        
        Test.startTest();

        System.runAs(ADMIN_USER){
            List<reduivy__Individual_Program_Enrollment__c> newIpes = new List<reduivy__Individual_Program_Enrollment__c>();

            for (Contact student : students) {
                for (reduivy__Study_Plan__c studyPlan : studyPlans.values()) {
                    newIpes.add(
                        REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                            student.Id + '_' + studyPlan.Id,
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
                            studentToIPFMap.get(student.Id)
                        )
                    );
                }
            }

            REDU_Database_UTIL.doInsert(newIpes);

            for (reduivy__Individual_Program_Enrollment__c ipe : [SELECT Id,
                reduivy__Study_Plan__c,
                reduivy__Contact__c,
                (
                    SELECT Id,
                    RecordTypeId,
                    reduivy__Category__c,
                    reduivy__Target_Unit_Id__c,
                    reduivy__Individual_Enrollment__c,
                    reduivy__Status__c
                    FROM reduivy__Individual_Plan_Structures__r
                )
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE Id IN: newIpes
            ]) {
                
                Decimal groupIpsCount = 0;
                Decimal requiredUnitIpsCount = 0;

                for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
                    if (ips.RecordTypeId == IPS_Helper.getUnitRecordTypeId()) {
                        if (ips.reduivy__Category__c == IPS_Helper.CATEGORY_REQUIRED) {
                            System.Assert.areEqual(IPS_Helper.CATEGORY_REQUIRED, ips.reduivy__Category__c);
                            requiredUnitIpsCount ++;
                        } else {
                            String sampleCode = ipe.reduivy__Contact__c + '_' + ips.reduivy__Target_Unit_Id__c;

                            System.Assert.areEqual(true, newIndividualEnrollments.containsKey(sampleCode));
                            System.Assert.areEqual(true, String.isNotBlank(ips.reduivy__Individual_Enrollment__c));
                            System.Assert.areEqual(newIndividualEnrollments.get(sampleCode).Id, ips.reduivy__Individual_Enrollment__c);
                        }
                    } else if (ips.RecordTypeId == IPS_Helper.getGroupRecordTypeId()) {
                        groupIpsCount ++;
                    } else {
                        System.Assert.fail('The individual plan structure should have a RecordTypeId.');
                    }
                }

                System.Assert.areEqual(true, studyPlans.containsKey(ipe.reduivy__Study_Plan__c));
                System.Assert.areEqual(studyPlansGroupCount.get(ipe.reduivy__Study_Plan__c), groupIpsCount);
                System.Assert.areEqual(studyPlansRequiredUnitCount.get(ipe.reduivy__Study_Plan__c), requiredUnitIpsCount);
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test placeholder IEN creation when study plan creation mode is 'Required Units Only' as admin
     */
    @IsTest
    static void testPlaceholderIenCreationRequiredUnitsOnlyAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, 
            reduivy__Sample_Record_Code__c, 
            Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Update study plan with 'Required Units Only' creation mode
        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;
        update studyPlan;

        // Get study plan structure data
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnits = new Map<Id, reduivy__Study_Plan_Structure__c>();
        Set<Id> requiredSunIds = new Set<Id>();
        
        for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, reduivy__Study_Unit__c, reduivy__Category__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
        ]) {
            spsUnits.put(sps.Id, sps);
            requiredSunIds.add(sps.reduivy__Study_Unit__c);
        }

        // Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c 
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        List<Account> campus = [SELECT Id FROM Account WHERE Name = 'Sydney Campus' AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1];

        //To ensure all the study unit have a sof
        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();

        for(Id sunId : requiredSunIds) {
            sofToBeCreated.add(REDU_TestData_UTIL.newStudyOffering(sunId + '_' + academicTerm.Id, sunId, academicTerm.Id, campus[0].Id, sunId + '_' + academicTerm.Id, 20, System.today(), System.today().addDays(30)));
        }

        List<reduivy__Individual_Academic_Profile__c> ipfToBeCreated = new List<reduivy__Individual_Academic_Profile__c>();
        ipfToBeCreated.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(students[0].Id + '_' + students[0].Name, students[0].Id, students[0].Name, IPF_Helper.STATUS_ACTIVE, true)
        );

        insert ipfToBeCreated;

        List<reduivy__Individual_Enrollment__c> existingIenToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : sofToBeCreated) {
            existingIenToBeCreated.add(
                REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    students[0].reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    students[0].Id,
                    sof.Id,
                    IEN_COMPLETED_FAIL_STATUS,
                    1,
                    System.today(),
                    null,
                    null,
                    null,
                    3,
                    null,
                    ipfToBeCreated[0].Id,
                    true
                )
            );

            existingIenToBeCreated.add(
                REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    students[0].reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    students[0].Id,
                    sof.Id,
                    IEN_WITHDRAWN_STATUS,
                    10,
                    System.today(),
                    null,
                    null,
                    null,
                    3,
                    null,
                    ipfToBeCreated[0].Id,
                    true
                )
            );
        }

        //IENs with negative status will be ignored, so the IPs should not be linked to these IENs, the placeholder IENs should still be created
        insert existingIenToBeCreated;

        Test.startTest();

        System.runAs(ADMIN_USER){
            // Count existing IENs before test
            Integer initialIenCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c IN :students 
                AND reduivy__Target_Unit_Id__c IN :requiredSunIds];

            // Create IPE which will trigger IPS creation
            List<reduivy__Individual_Program_Enrollment__c> newIpes = new List<reduivy__Individual_Program_Enrollment__c>();
            newIpes.add(
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    students[0].Id + '_' + studyPlan.Id,
                    students[0].Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null, null, null, null, null, null, true,
                    IPE_INPROGRESS_STATUS,
                    ipfToBeCreated[0].Id
                )
            );
            
            REDU_Database_UTIL.doInsert(newIpes);

            // Verify placeholder IENs were created
            List<reduivy__Individual_Enrollment__c> createdIens = [SELECT Id, reduivy__Contact__c, reduivy__Target_Unit_Id__c, 
                reduivy__Enrollment_Status__c, reduivy__Enrollment_Type__c
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c IN :students 
                AND reduivy__Target_Unit_Id__c IN :requiredSunIds
                AND reduivy__Enrollment_Status__c = :IEN_OPEN_STATUSES
                AND reduivy__Enrollment_Type__c = :IEN_Helper.ENROLLMENT_TYPE_PROGRAM
            ];

            System.Assert.areNotEqual(initialIenCount, createdIens.size(), 'Shoud have created placeholder IEN for each student-required unit combination');

            // Should create placeholder IEN for each student-unit combination
            System.Assert.areEqual(requiredSunIds.size(), createdIens.size(), 'Should create placeholder IEN for each student-required unit combination');

            // Verify each IEN has correct properties
            for (reduivy__Individual_Enrollment__c ien : createdIens) {
                System.Assert.areEqual(IEN_OPEN_STATUSES, ien.reduivy__Enrollment_Status__c, 'Placeholder IEN should have Open status');
                System.Assert.areEqual(IEN_Helper.ENROLLMENT_TYPE_PROGRAM, ien.reduivy__Enrollment_Type__c, 'IEN should be Program type');
                System.Assert.areEqual(students[0].Id, ien.reduivy__Contact__c, 'IEN should be for test students');
                System.Assert.isTrue(requiredSunIds.contains(ien.reduivy__Target_Unit_Id__c), 'IEN should be for required units');
            }

            List<reduivy__Individual_Plan_Structure__c> createdIps = [SELECT Id, reduivy__Individual_Enrollment__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :newIpes[0].Id AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()];
            System.Assert.areEqual(requiredSunIds.size(), createdIps.size(), 'Should create IPS for each required unit');

            for(reduivy__Individual_Plan_Structure__c ips : createdIps) {
                System.Assert.isTrue(String.isBlank(ips.reduivy__Individual_Enrollment__c), 'IPS should not be linked to any IEN');
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test that no placeholder IEN is created when study plan creation mode is NOT 'Required Units Only' As Admin
     */
    @IsTest
    static void testNoPlaceholderIenCreationWhenNotRequiredUnitsOnlyAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create study plan with different creation mode (NOT 'Required Units Only')
        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_NONE;
        update studyPlan;

        Set<Id> requiredSunIds = new Set<Id>();
        for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
        ]) {
            requiredSunIds.add(sps.reduivy__Study_Unit__c);
        }

        Test.startTest();

        System.runAs(ADMIN_USER){
            // Count existing IENs before test
            Integer initialIenCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c IN :students 
                AND reduivy__Target_Unit_Id__c IN :requiredSunIds];

            // Create IPE
            List<reduivy__Individual_Program_Enrollment__c> newIpes = new List<reduivy__Individual_Program_Enrollment__c>();
            newIpes.add(
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    students[0].Id + '_' + studyPlan.Id,
                    students[0].Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null, null, null, null, null, null, true,
                    IPE_INPROGRESS_STATUS,
                    null
                )
            );

            REDU_Database_UTIL.doInsert(newIpes);

            // Verify no new placeholder IENs were created
            Integer finalIenCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c IN :students 
                AND reduivy__Target_Unit_Id__c IN :requiredSunIds
                AND reduivy__Enrollment_Status__c = :IEN_OPEN_STATUSES];

            System.Assert.areEqual(initialIenCount, finalIenCount, 'No placeholder IENs should be created when creation mode is not Required Units Only');
        }

        Test.stopTest();
    }

    /**
     * @description Student enrolled in multiple study plans with same unit - should create only one placeholder IEN As Admin
     */
    @IsTest
    static void testNoDuplicatePlaceholderIenForSameContactUnitAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create two study plans with same unit and 'Required Units Only' creation mode
        List<reduivy__Study_Plan__c> studyPlans = new List<reduivy__Study_Plan__c>();
        
        // Get existing study plan
        reduivy__Study_Plan__c studyPlan1 = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];
        studyPlan1.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;

        update studyPlan1;
        
        studyPlans.add(studyPlan1);

        // Create second study plan with same program
        reduivy__Study_Plan__c studyPlan2 = studyPlan1.clone(false, true, false, false);
        studyPlan2.Name = 'Test Plan 2';
        studyPlan2.reduivy__Sample_Record_Code__c = 'TESTPLAN2';
        studyPlans.add(studyPlan2);

        insert studyPlan2;

        // Get a common unit from first study plan
        reduivy__Study_Unit__c commonUnit = [SELECT Id FROM reduivy__Study_Unit__c 
            WHERE Id IN (SELECT reduivy__Study_Unit__c FROM reduivy__Study_Plan_Structure__c 
                WHERE reduivy__Study_Plan__c = :studyPlan1.Id 
                AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
                AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED)
            LIMIT 1
        ];

        // Create study plan structure for second plan with same unit
        reduivy__Study_Plan_Structure__c spsGroup2 = new reduivy__Study_Plan_Structure__c(
            RecordTypeId = SPS_Helper.getGroupRecordTypeId(),
            reduivy__Study_Plan__c = studyPlan2.Id,
            Name = 'Test Group 2',
            reduivy__Sequence__c = 1,
            reduivy__Credits__c = 40
        );
        insert spsGroup2;

        reduivy__Study_Plan_Structure__c spsUnit2 = new reduivy__Study_Plan_Structure__c(
            RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
            reduivy__Study_Plan__c = studyPlan2.Id,
            reduivy__Parent_Study_Plan_Structure__c = spsGroup2.Id,
            reduivy__Study_Unit__c = commonUnit.Id,
            reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
            Name = 'Test Unit 2',
            reduivy__Sequence__c = 1
        );
        insert spsUnit2;

        reduivy__Individual_Academic_Profile__c ipfToBeCreated = REDU_TestData_UTIL.newIndividualAcademicProfile(
            students[0].Id + '_' + students[0].Name, 
            students[0].Id, 
            students[0].Name, 
            IPF_Helper.STATUS_ACTIVE, 
            true
        );

        insert ipfToBeCreated;

        Test.startTest();

        System.runAs(ADMIN_USER){
            // Create IPE for both study plans
            List<reduivy__Individual_Program_Enrollment__c> newIpes = new List<reduivy__Individual_Program_Enrollment__c>();
            for (reduivy__Study_Plan__c sp : studyPlans) {
                reduivy__Individual_Program_Enrollment__c tempIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    students[0].Id + '_' + sp.Id,
                    students[0].Id,
                    sp.reduivy__Study_Program__c,
                    sp.Id,
                    null, null, null, null, null, null, true,
                    IPE_INPROGRESS_STATUS,
                    null
                );

                tempIpe.reduivy__Individual_Academic_Profile__c = ipfToBeCreated.Id;

                newIpes.add(tempIpe);
            }

            REDU_Database_UTIL.doInsert(newIpes);

            // Verify only one placeholder IEN was created for the common unit
            List<reduivy__Individual_Enrollment__c> createdIens = [SELECT Id, reduivy__Contact__c, reduivy__Target_Unit_Id__c
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c IN :students 
                AND reduivy__Individual_Academic_Profile__c = :ipfToBeCreated.Id
                AND reduivy__Target_Unit_Id__c = :commonUnit.Id
                AND reduivy__Enrollment_Status__c = :IEN_OPEN_STATUSES
                AND reduivy__Enrollment_Type__c = :IEN_Helper.ENROLLMENT_TYPE_PROGRAM
            ];

            System.Assert.areEqual(1, createdIens.size(), 'Should create only one placeholder IEN for contact-unit combination even when unit appears in multiple study plans');
        }

        Test.stopTest();
    }

    /**
     * @description Test when a student already has existing IEN for unit - should not create placeholder as admin
     */
    @IsTest
    static void testNoPlaceholderIenWhenExistingIenExistsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, 
            reduivy__Sample_Record_Code__c, 
            Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create study plan with 'Required Units Only' creation mode
        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;
        update studyPlan;

        // Get a required unit
        List<reduivy__Study_Unit__c> requiredUnits = [SELECT Id FROM reduivy__Study_Unit__c 
            WHERE Id IN (SELECT reduivy__Study_Unit__c FROM reduivy__Study_Plan_Structure__c 
                WHERE reduivy__Study_Plan__c = :studyPlan.Id 
                AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
                AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED)
        ];

        List<reduivy__Individual_Academic_Profile__c> ipfToBeCreated = new List<reduivy__Individual_Academic_Profile__c>();
        ipfToBeCreated.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(students[0].Id + '_' + students[0].Name, students[0].Id, students[0].Name, IPF_Helper.STATUS_ACTIVE, true)
        );

        insert ipfToBeCreated;

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        Set<Id> requiredUnitIds = new Set<Id>();

        for(reduivy__Study_Unit__c requiredUnit : requiredUnits) {
            // Create existing IEN for the unit
            reduivy__Individual_Enrollment__c existingIen = new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = students[0].Id,
                reduivy__Study_Unit__c = requiredUnit.Id,
                reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS,
                reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
                reduivy__Bypass_Requirement_Met__c = true
            );

            existingIen.reduivy__Individual_Academic_Profile__c = ipfToBeCreated[0].Id;

            ienToBeCreated.add(existingIen);
            requiredUnitIds.add(requiredUnit.Id);
        }
         
        insert ienToBeCreated;

        Test.startTest();

        System.runAs(ADMIN_USER){
            // Count existing IENs before test
            Integer initialIenCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c IN :students 
                AND reduivy__Target_Unit_Id__c IN :requiredUnitIds];

            // Create IPE
            reduivy__Individual_Program_Enrollment__c newIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id,
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                null
            );

            newIpe.reduivy__Individual_Academic_Profile__c = ipfToBeCreated[0].Id;

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{newIpe});
            
            // Verify no new placeholder IEN was created
            Integer finalIenCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c IN :students 
                AND reduivy__Target_Unit_Id__c IN :requiredUnitIds];

            System.Assert.areEqual(initialIenCount, finalIenCount, 'Should not create placeholder IEN when existing IEN already exists for contact-unit combination');

            // Verify no new Open status IEN was created
            Integer openIenCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c IN :students 
                AND reduivy__Target_Unit_Id__c IN :requiredUnitIds
                AND reduivy__Enrollment_Status__c = :IEN_OPEN_STATUSES];

            System.Assert.areEqual(0, openIenCount, 'Should not create Open status placeholder IEN when existing IEN already exists');
        }

        Test.stopTest();
    }

    /**
     * @description Test only required units should trigger placeholder IEN creation as Admin
     */
    @IsTest
    static void testPlaceholderIenOnlyForRequiredUnitsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create study plan with 'Required Units Only' creation mode
        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];
        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;
        update studyPlan;

        // Get required and optional units
        Set<Id> requiredUnits = new Set<Id>();
        Set<Id> optionalUnits = new Set<Id>();
        
        for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, reduivy__Study_Unit__c, reduivy__Category__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
        ]) {
            if (sps.reduivy__Category__c == SPS_Helper.CATEGORY_REQUIRED) {
                requiredUnits.add(sps.reduivy__Study_Unit__c);
            } else {
                optionalUnits.add(sps.reduivy__Study_Unit__c);
            }
        }

        System.Assert.isFalse(requiredUnits.isEmpty(), 'The required unit should not be empty.');
        System.Assert.isFalse(optionalUnits.isEmpty(), 'The optional unit should not be empty.');

        Test.startTest();

        System.runAs(ADMIN_USER){
            // Create IPE
            List<reduivy__Individual_Program_Enrollment__c> newIpes = new List<reduivy__Individual_Program_Enrollment__c>();
            newIpes.add(
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    students[0].Id + '_' + studyPlan.Id,
                    students[0].Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null, null, null, null, null, null, true,
                    IPE_INPROGRESS_STATUS,
                    null
                )
            );

            REDU_Database_UTIL.doInsert(newIpes);

            // Verify placeholder IENs were created only for required units
            List<reduivy__Individual_Enrollment__c> createdIens = [SELECT Id, reduivy__Target_Unit_Id__c
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c IN :students 
                AND reduivy__Enrollment_Status__c = :IEN_OPEN_STATUSES
                AND reduivy__Enrollment_Type__c = :IEN_Helper.ENROLLMENT_TYPE_PROGRAM
            ];

            for (reduivy__Individual_Enrollment__c ien : createdIens) {
                System.Assert.isTrue(requiredUnits.contains(ien.reduivy__Target_Unit_Id__c), 'Placeholder IEN should only be created for required units');
                System.Assert.isFalse(optionalUnits.contains(ien.reduivy__Target_Unit_Id__c), 'Placeholder IEN should not be created for optional units');
            }

            // Verify no placeholder IENs for optional units
            Integer optionalIenCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c IN :students 
                AND reduivy__Target_Unit_Id__c IN :optionalUnits
                AND reduivy__Enrollment_Status__c = :IEN_OPEN_STATUSES];

            System.Assert.areEqual(0, optionalIenCount, 'No placeholder IENs should be created for optional units');
        }

        Test.stopTest();
    }

    /**
     * @description Test mixed scenario when some units have existing IEN, some don't as Admin
     */
    @IsTest
    static void testMixedScenarioWithExistingAndNewIensAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create study plan with 'Required Units Only' creation mode
        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];
        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;
        update studyPlan;

        // Get required units
        List<Id> requiredUnits = new List<Id>();
        for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
        ]) {
            requiredUnits.add(sps.reduivy__Study_Unit__c);
        }

        List<reduivy__Individual_Academic_Profile__c> ipfToBeCreated = new List<reduivy__Individual_Academic_Profile__c>();
        ipfToBeCreated.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(students[0].Id + '_' + students[0].Name, students[0].Id, students[0].Name, IPF_Helper.STATUS_ACTIVE, true)
        );

        insert ipfToBeCreated;

        reduivy__Individual_Enrollment__c existingIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Unit__c = requiredUnits[0],
            reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS,
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true,
            reduivy__Individual_Academic_Profile__c = ipfToBeCreated[0].Id
        );
        insert existingIen;

        Test.startTest();

        System.runAs(ADMIN_USER){
            // Create IPE
            reduivy__Individual_Program_Enrollment__c newIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id,
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                null
            );
            
            newIpe.reduivy__Individual_Academic_Profile__c = ipfToBeCreated[0].Id;

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{newIpe});

            // Verify placeholder IENs were created for units without existing IEN
            List<reduivy__Individual_Enrollment__c> placeholderIens = [SELECT Id, reduivy__Target_Unit_Id__c
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c IN :students 
                AND reduivy__Target_Unit_Id__c IN :requiredUnits
                AND reduivy__Enrollment_Status__c = :IEN_OPEN_STATUSES
                AND reduivy__Enrollment_Type__c = :IEN_Helper.ENROLLMENT_TYPE_PROGRAM
            ];

            // Should create placeholders for units without existing IEN (2 units)
            System.Assert.areEqual(requiredUnits.size() - 1, placeholderIens.size(), 'Should create placeholder IEN only for units without existing IEN');

            // Verify no placeholder for unit with existing IEN
            for (reduivy__Individual_Enrollment__c ien : placeholderIens) {
                System.Assert.areNotEqual(requiredUnits[0], ien.reduivy__Target_Unit_Id__c, 'Should not create placeholder for unit with existing IEN');
            }

            // Verify total IEN count
            Integer totalIenCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c IN :students 
                AND reduivy__Target_Unit_Id__c IN :requiredUnits];

            System.Assert.areEqual(requiredUnits.size(), totalIenCount, 'Total IEN count should equal required units count');
        }

        Test.stopTest();
    }

	/**
     * @description Test that placeholder IEN is NOT created when student has existing inactive IEN for Required Units Only mode as Admin
     */
    @IsTest
    static void testNoPlaceholderIenCreationForInactiveExistingIenAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, 
            reduivy__Sample_Record_Code__c, 
            Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Get a study plan and set its creation mode to 'Required Units Only'
        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Study_Program__c,
            reduivy__Individual_Enrollment_Creation_Mode__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        // Update the study plan to use Required Units Only mode
        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;
        update studyPlan;

        // Get required units from the study plan
        List<reduivy__Study_Plan_Structure__c> requiredUnits = [SELECT Id,
            reduivy__Study_Unit__c,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
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

        List<Account> campus = [SELECT Id FROM Account WHERE Name = 'Sydney Campus' AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1];

        // Create study offering for the required unit
        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();
        for(reduivy__Study_Plan_Structure__c requiredUnit : requiredUnits) {
            sofToBeCreated.add(REDU_TestData_UTIL.newStudyOffering(
                requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id, 
                requiredUnit.reduivy__Study_Unit__c, 
                academicTerm.Id, 
                campus[0].Id, 
                requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id, 
                20, 
                System.today(), 
                System.today().addDays(30)
            ));
        }
        insert sofToBeCreated;

        reduivy__Individual_Academic_Profile__c ipfToBeCreated = REDU_TestData_UTIL.newIndividualAcademicProfile(students[0].Id + '_' + students[0].Name, students[0].Id, students[0].Name, IPF_Helper.STATUS_ACTIVE, true);
    
        insert ipfToBeCreated;
        // Create INACTIVE IEN for the student-unit combination
        List<reduivy__Individual_Enrollment__c> inactiveIens = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : sofToBeCreated) {
            reduivy__Individual_Enrollment__c existingIen = new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = students[0].Id,
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Enrollment_Status__c = IEN_OPEN_STATUSES,
                reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
                reduivy__Bypass_Requirement_Met__c = true
            );

            existingIen.reduivy__Individual_Academic_Profile__c = ipfToBeCreated.Id;

            inactiveIens.add(existingIen);
        }

        insert inactiveIens;

        // Count existing IENs before test
        Integer initialIenCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c IN :students];

        Test.startTest();

        System.runAs(ADMIN_USER){            
            // Create IPE which will trigger the IPS creation
            reduivy__Individual_Program_Enrollment__c newIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id,
                students[0].Id,
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
                null
            );

            newIpe.reduivy__Individual_Academic_Profile__c = ipfToBeCreated.Id;

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{newIpe});
            
            // Count IENs after test            
            Integer finalIenCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c  WHERE reduivy__Contact__c IN :students];
            
            // Verify that NO new placeholder IEN was created
            // Since an inactive IEN already exists for this contact-unit combination,
            // no new placeholder IEN should be created
            System.Assert.areEqual(initialIenCount, finalIenCount, 'No new placeholder IEN should be created when inactive IEN exists');
            
            // Verify that the existing inactive IEN was not linked to any IPS
            List<reduivy__Individual_Plan_Structure__c> ipsUnits = [SELECT Id,
                reduivy__Individual_Enrollment__c,
                reduivy__Category__c
                FROM reduivy__Individual_Plan_Structure__c
                WHERE reduivy__Individual_Program_Enrollment__c = :newIpe.Id
                AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
            ];
            
            // Verify that required unit IPS was created but without linking to the inactive IEN
            System.Assert.areEqual(requiredUnits.size() * students.size(), ipsUnits.size(), 'Required unit IPS should be created');
            
            for (reduivy__Individual_Plan_Structure__c ipsUnit : ipsUnits) {
                System.Assert.areEqual(null, ipsUnit.reduivy__Individual_Enrollment__c, 'IPS should not be linked to inactive IEN');
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test that placeholder IEN is created with correct IPF
     */
    @IsTest
    static void testIenCreationWithIpfLookupAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create two IPFs for the same student
        List<reduivy__Individual_Academic_Profile__c> ipfsToCreate = new List<reduivy__Individual_Academic_Profile__c>();
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF1', 
                students[0].Id, 
                'IPF 1', 
                IPF_Helper.STATUS_ACTIVE, 
                true
            )
        );
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF2', 
                students[0].Id, 
                'IPF 2', 
                IPF_Helper.STATUS_ACTIVE, 
                false
            )
        );
        insert ipfsToCreate;

        // Get study plan and set creation mode
        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Study_Program__c,
            reduivy__Individual_Enrollment_Creation_Mode__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];
        
        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;
        update studyPlan;

        // Get required units
        List<reduivy__Study_Plan_Structure__c> requiredUnits = [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
        ];

        System.Assert.isTrue(requiredUnits.size() >= 2, 'Need at least 2 required units for test');

        // Get academic term and campus
        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        List<Account> campus = [SELECT Id FROM Account 
            WHERE Name = 'Sydney Campus' 
            AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() 
            LIMIT 1
        ];

        // Create study offerings
        List<reduivy__Study_Offering__c> sofToCreate = new List<reduivy__Study_Offering__c>();
        for(reduivy__Study_Plan_Structure__c sps : requiredUnits) {
            sofToCreate.add(
                REDU_TestData_UTIL.newStudyOffering(
                    sps.reduivy__Study_Unit__c + '_' + academicTerm.Id,
                    sps.reduivy__Study_Unit__c,
                    academicTerm.Id,
                    campus[0].Id,
                    sps.reduivy__Study_Unit__c + '_' + academicTerm.Id,
                    20,
                    System.today(),
                    System.today().addDays(30)
                )
            );
        }
        insert sofToCreate;

        // Create IEN for Unit 1 linked to IPF 1 (In Progress)
        reduivy__Individual_Enrollment__c ienForIpf1 = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sofToCreate[0].Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[0].Id,
            reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS,
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );
        insert ienForIpf1;

        Test.startTest();

        System.runAs(ADMIN_USER){
            // Create two IPEs - one for each IPF
            List<reduivy__Individual_Program_Enrollment__c> newIpes = new List<reduivy__Individual_Program_Enrollment__c>();
            
            // IPE 1 for IPF 1
            reduivy__Individual_Program_Enrollment__c ipe1 = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id + '_IPF1',
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                null
            );
            ipe1.reduivy__Individual_Academic_Profile__c = ipfsToCreate[0].Id;
            newIpes.add(ipe1);
            
            // IPE 2 for IPF 2
            reduivy__Individual_Program_Enrollment__c ipe2 = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id + '_IPF2',
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                null
            );
            ipe2.reduivy__Individual_Academic_Profile__c = ipfsToCreate[1].Id;
            newIpes.add(ipe2);

            REDU_Database_UTIL.doInsert(newIpes);

            // Verify placeholder IENs were created with correct IPF
            List<reduivy__Individual_Enrollment__c> placeholderIens = [SELECT Id, 
                reduivy__Contact__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Individual_Academic_Profile__c,
                reduivy__Enrollment_Status__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :students[0].Id
                AND reduivy__Enrollment_Status__c = :IEN_OPEN_STATUSES
                AND reduivy__Enrollment_Type__c = :IEN_Helper.ENROLLMENT_TYPE_PROGRAM
            ];

            Integer numberOfIenInIpf1 = 0;
            Integer numberOfIenInIpf2 = 0;

            // Verify each placeholder has correct IPF
            for(reduivy__Individual_Enrollment__c ien : placeholderIens) {
                System.Assert.isTrue(
                    ien.reduivy__Individual_Academic_Profile__c == ipfsToCreate[0].Id || 
                    ien.reduivy__Individual_Academic_Profile__c == ipfsToCreate[1].Id,
                    'Placeholder IEN should be linked to one of the IPFs'
                );

                if(ien.reduivy__Individual_Academic_Profile__c == ipfsToCreate[0].Id) {
                    numberOfIenInIpf1++;
                } else {
                    numberOfIenInIpf2++;
                }
            }

            // -1 for IPF1 as it already has an existing IEN created
            System.Assert.areEqual(requiredUnits.size() - 1, numberOfIenInIpf1, 'Should have' + requiredUnits.size() + 'placeholder IEN for IPF 1');

            System.Assert.areEqual(requiredUnits.size(), numberOfIenInIpf2, 'Should have' + requiredUnits.size() + 'placeholder IEN for IPF 2');

            // Verify no duplicate placeholder IENs for same Contact + Unit + IPF
            Set<String> uniqueKeys = new Set<String>();
            for(reduivy__Individual_Enrollment__c ien : placeholderIens) {
                String key = ien.reduivy__Contact__c + '_' + ien.reduivy__Target_Unit_Id__c + '_' + ien.reduivy__Individual_Academic_Profile__c;
                System.Assert.isFalse(uniqueKeys.contains(key), 
                    'Should not have duplicate placeholder IENs for same Contact + Unit + IPF combination');
                uniqueKeys.add(key);
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test that when student has IEN in one IPF, it doesn't affect IPS creation in another IPF
     */
    @IsTest
    static void testIpfIsolationForIpsCreationAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Create two IPFs
        List<reduivy__Individual_Academic_Profile__c> ipfsToCreate = new List<reduivy__Individual_Academic_Profile__c>();
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF1', 
                students[0].Id, 
                'IPF 1', 
                IPF_Helper.STATUS_ACTIVE, 
                true
            )
        );
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF2', 
                students[0].Id, 
                'IPF 2', 
                IPF_Helper.STATUS_ACTIVE, 
                false
            )
        );
        insert ipfsToCreate;

        // Get study plan
        reduivy__Study_Plan__c studyPlan = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        // Get a required unit
        reduivy__Study_Plan_Structure__c requiredUnit = [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
            LIMIT 1
        ];

        // Get academic term and campus
        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        List<Account> campus = [SELECT Id FROM Account 
            WHERE Name = 'Sydney Campus' 
            AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() 
            LIMIT 1
        ];

        // Create study offering
        reduivy__Study_Offering__c sof = REDU_TestData_UTIL.newStudyOffering(
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            requiredUnit.reduivy__Study_Unit__c,
            academicTerm.Id,
            campus[0].Id,
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            20,
            System.today(),
            System.today().addDays(30)
        );
        insert sof;

        // Create completed IEN in IPF 1
        reduivy__Individual_Enrollment__c completedIenIpf1 = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[0].Id,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );
        insert completedIenIpf1;

        Test.startTest();

        System.runAs(ADMIN_USER){
            // Create IPE for IPF 2 (different IPF than the IEN)
            reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id + '_IPF2',
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                ipfsToCreate[1].Id
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{ipe});

            // Verify IPS was created for the required unit
            List<reduivy__Individual_Plan_Structure__c> ipsUnits = [SELECT Id, 
                reduivy__Target_Unit_Id__c,
                reduivy__Individual_Enrollment__c,
                reduivy__Status__c
                FROM reduivy__Individual_Plan_Structure__c
                WHERE reduivy__Individual_Program_Enrollment__c = :ipe.Id
                AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Target_Unit_Id__c = :requiredUnit.reduivy__Study_Unit__c
            ];

            System.Assert.areEqual(1, ipsUnits.size(), 
                'Should create IPS for required unit even though IEN exists in different IPF');

            // Verify IPS is NOT linked to the completed IEN from different IPF
            System.Assert.isNull(ipsUnits[0].reduivy__Individual_Enrollment__c, 
                'IPS should NOT link to IEN from different IPF');

            // Verify IPS status is not marked as completed (since no IEN in same IPF)
            System.Assert.areNotEqual(IPS_Helper.STATUS_TYPE_COMPLETED, ipsUnits[0].reduivy__Status__c, 
                'IPS should not be marked as completed when linked IEN is in different IPF');
        }

        Test.stopTest();
    }

    /**
     * @description Test basic cloning scenario: Student has completed unit in IPF1, creates IPE in IPF2 with scope "All Academic Profiles"
     */
    @IsTest
    static void testBasicAutoUnitRecognitionCloningAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Get study plan and set Auto Unit Recognition Scope
        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Study_Program__c,
            reduivy__Study_Program__r.reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        // Update Study Program to enable auto unit recognition
        reduivy__Study_Program__c studyProgram = new reduivy__Study_Program__c(
            Id = studyPlan.reduivy__Study_Program__c,
            reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES
        );
        update studyProgram;

        // Get a required unit
        reduivy__Study_Plan_Structure__c requiredUnit = [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
            LIMIT 1
        ];

        // Create two IPFs for the same student
        List<reduivy__Individual_Academic_Profile__c> ipfsToCreate = new List<reduivy__Individual_Academic_Profile__c>();
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF1', 
                students[0].Id, 
                'IPF 1', 
                IPF_Helper.STATUS_ACTIVE, 
                true
            )
        );
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF2', 
                students[0].Id, 
                'IPF 2', 
                IPF_Helper.STATUS_ACTIVE, 
                false
            )
        );
        insert ipfsToCreate;

        // Get academic term and create study offering
        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        List<Account> campus = [SELECT Id FROM Account 
            WHERE Name = 'Sydney Campus' 
            AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() 
            LIMIT 1
        ];

        reduivy__Study_Offering__c sof = REDU_TestData_UTIL.newStudyOffering(
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            requiredUnit.reduivy__Study_Unit__c,
            academicTerm.Id,
            campus[0].Id,
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            20,
            System.today(),
            System.today().addDays(30)
        );
        insert sof;

        // Create completed-pass IEN in IPF1 (recognizable for cloning)
        reduivy__Individual_Enrollment__c sourceIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[0].Id,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Grade_Result__c = 'Pass',
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );
        insert sourceIen;

        Test.startTest();

        System.runAs(ADMIN_USER){
            muteTriggers();

            // Create IPE in IPF2
            reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id + '_IPF2',
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                ipfsToCreate[1].Id
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{ipe});

            unmuteTriggers();

            // Verify cloned IEN was created in IPF2
            List<reduivy__Individual_Enrollment__c> clonedIens = [SELECT Id, 
                reduivy__Contact__c,
                reduivy__Target_Unit_Id__c,
                reduivy__Individual_Academic_Profile__c,
                reduivy__Enrollment_Status__c,
                reduivy__Grade_Result__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :students[0].Id
                AND reduivy__Individual_Academic_Profile__c = :ipfsToCreate[1].Id
                AND reduivy__Target_Unit_Id__c = :requiredUnit.reduivy__Study_Unit__c
            ];

            System.Assert.areEqual(1, clonedIens.size(), 
                'Should clone one IEN from IPF1 to IPF2');
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, clonedIens[0].reduivy__Enrollment_Status__c,
                'Cloned IEN should have same status as source');
            System.Assert.areEqual('Pass', clonedIens[0].reduivy__Grade_Result__c,
                'Cloned IEN should have same grade as source');

            // Verify IPS was created and linked to cloned IEN
            List<reduivy__Individual_Plan_Structure__c> ipsUnits = [SELECT Id, 
                reduivy__Individual_Enrollment__c
                FROM reduivy__Individual_Plan_Structure__c
                WHERE reduivy__Individual_Program_Enrollment__c = :ipe.Id
                AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Target_Unit_Id__c = :requiredUnit.reduivy__Study_Unit__c
            ];

            System.Assert.areEqual(1, ipsUnits.size(), 'Should create IPS for required unit');
            System.Assert.areEqual(clonedIens[0].Id, ipsUnits[0].reduivy__Individual_Enrollment__c, 'IPS should be linked to cloned IEN');
        }

        Test.stopTest();
    }

    /**
     * @description Test that cloning does NOT occur when scope is "None"
     */
    @IsTest
    static void testNoAutoUnitRecognitionWhenScopeIsNoneAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        // Set scope to None
        reduivy__Study_Program__c studyProgram = new reduivy__Study_Program__c(
            Id = studyPlan.reduivy__Study_Program__c,
            reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_NONE
        );
        update studyProgram;

        reduivy__Study_Plan_Structure__c requiredUnit = [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> ipfsToCreate = new List<reduivy__Individual_Academic_Profile__c>();
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF1', 
                students[0].Id, 
                'IPF 1', 
                IPF_Helper.STATUS_ACTIVE, 
                true
            )
        );
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF2', 
                students[0].Id, 
                'IPF 2', 
                IPF_Helper.STATUS_ACTIVE, 
                false
            )
        );
        insert ipfsToCreate;

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        List<Account> campus = [SELECT Id FROM Account 
            WHERE Name = 'Sydney Campus' 
            AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() 
            LIMIT 1
        ];

        reduivy__Study_Offering__c sof = REDU_TestData_UTIL.newStudyOffering(
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            requiredUnit.reduivy__Study_Unit__c,
            academicTerm.Id,
            campus[0].Id,
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            20,
            System.today(),
            System.today().addDays(30)
        );
        insert sof;

        // Create completed-pass IEN in IPF1
        reduivy__Individual_Enrollment__c sourceIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[0].Id,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Grade_Result__c = 'Pass',
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );
        insert sourceIen;

        Test.startTest();

        System.runAs(ADMIN_USER){
            muteTriggers();

            reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id + '_IPF2',
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                ipfsToCreate[1].Id
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{ipe});

            unmuteTriggers();

            // Verify NO cloned IEN was created
            List<reduivy__Individual_Enrollment__c> clonedIens = [SELECT Id
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :students[0].Id
                AND reduivy__Individual_Academic_Profile__c = :ipfsToCreate[1].Id
                AND reduivy__Target_Unit_Id__c = :requiredUnit.reduivy__Study_Unit__c
            ];

            System.Assert.areEqual(0, clonedIens.size(), 
                'Should NOT clone IEN when scope is None');
        }

        Test.stopTest();
    }

    /**
     * @description Test cloning for optional units when recognizable IEN exists
     */
    @IsTest
    static void testAutoUnitRecognitionForOptionalUnitsAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        // Enable auto unit recognition
        reduivy__Study_Program__c studyProgram = new reduivy__Study_Program__c(
            Id = studyPlan.reduivy__Study_Program__c,
            reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES
        );
        update studyProgram;

        // Get an optional unit
        reduivy__Study_Plan_Structure__c optionalUnit = [SELECT Id, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c != :SPS_Helper.CATEGORY_REQUIRED
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> ipfsToCreate = new List<reduivy__Individual_Academic_Profile__c>();
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF1', 
                students[0].Id, 
                'IPF 1', 
                IPF_Helper.STATUS_ACTIVE, 
                true
            )
        );
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF2', 
                students[0].Id, 
                'IPF 2', 
                IPF_Helper.STATUS_ACTIVE, 
                false
            )
        );
        insert ipfsToCreate;

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        List<Account> campus = [SELECT Id FROM Account 
            WHERE Name = 'Sydney Campus' 
            AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() 
            LIMIT 1
        ];

        reduivy__Study_Offering__c sof = REDU_TestData_UTIL.newStudyOffering(
            optionalUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            optionalUnit.reduivy__Study_Unit__c,
            academicTerm.Id,
            campus[0].Id,
            optionalUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            20,
            System.today(),
            System.today().addDays(30)
        );
        insert sof;

        // Create completed-pass IEN for optional unit in IPF1
        reduivy__Individual_Enrollment__c sourceIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[0].Id,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Grade_Result__c = 'Pass',
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );
        insert sourceIen;

        Test.startTest();

        System.runAs(ADMIN_USER){
            muteTriggers();

            reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id + '_IPF2',
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                ipfsToCreate[1].Id
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{ipe});

            unmuteTriggers();

            // Verify cloned IEN was created for optional unit
            List<reduivy__Individual_Enrollment__c> clonedIens = [SELECT Id
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :students[0].Id
                AND reduivy__Individual_Academic_Profile__c = :ipfsToCreate[1].Id
                AND reduivy__Target_Unit_Id__c = :optionalUnit.reduivy__Study_Unit__c
            ];

            System.Assert.areEqual(1, clonedIens.size(), 
                'Should clone IEN for optional unit');

            // Verify IPS was created for optional unit
            List<reduivy__Individual_Plan_Structure__c> ipsUnits = [SELECT Id
                FROM reduivy__Individual_Plan_Structure__c
                WHERE reduivy__Individual_Program_Enrollment__c = :ipe.Id
                AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Target_Unit_Id__c = :optionalUnit.reduivy__Study_Unit__c
            ];

            System.Assert.areEqual(1, ipsUnits.size(), 
                'Should create IPS for optional unit when cloning');
        }

        Test.stopTest();
    }

    /**
     * @description Test mixed scope error when IPF has IPEs with different scopes
     */
    @IsTest
    static void testMixedScopeErrorAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        reduivy__Study_Program__c spg = [SELECT Id, reduivy__Educational_Institution__c, Name, reduivy__Academic_Level__c, reduivy__Program_Code__c FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS'];

        reduivy__Study_Program__c newSpg = spg.clone(false, true, false, false);

        newSpg.Name = spg.Name + ' - Copy';
        newSpg.reduivy__Program_Code__c = 'NEWCODE';
        newSpg.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_NONE;

        insert newSpg;

        // Get two different study plans
        List<reduivy__Study_Plan__c> studyPlans = [SELECT Id, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c IN ('BACBIS_MajorA', 'BACBIS_MinorA')
            LIMIT 2
        ];

        System.Assert.areEqual(2, studyPlans.size(), 'Need two study plans for test');

        // Set different scopes for the two programs
        List<reduivy__Study_Program__c> programsToUpdate = new List<reduivy__Study_Program__c>();
        programsToUpdate.add(new reduivy__Study_Program__c(
            Id = studyPlans[0].reduivy__Study_Program__c,
            reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES
        ));
        
        update programsToUpdate;

        studyPlans[1].reduivy__Study_Program__c = newSpg.Id;

        update studyPlans[1];

        // Create IPF
        List<reduivy__Individual_Academic_Profile__c> ipfToCreate = new List<reduivy__Individual_Academic_Profile__c>();

        ipfToCreate.add(REDU_TestData_UTIL.newIndividualAcademicProfile(
            students[0].Id + '_IPF1', 
            students[0].Id, 
            'IPF 1', 
            IPF_Helper.STATUS_ACTIVE, 
            true
        ));

        ipfToCreate.add(REDU_TestData_UTIL.newIndividualAcademicProfile(
            students[0].Id + '_IPF2', 
            students[0].Id, 
            'IPF 2', 
            IPF_Helper.STATUS_ACTIVE, 
            true
        ));

        insert ipfToCreate;

        // Create IPE for first study plan in the same IPF
        reduivy__Individual_Program_Enrollment__c ipe1 = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            students[0].Id + '_' + studyPlans[1].Id,
            students[0].Id,
            studyPlans[1].reduivy__Study_Program__c,
            studyPlans[1].Id,
            null, null, null, null, null, null, true,
            IPE_INPROGRESS_STATUS,
            ipfToCreate[0].Id
        );
        insert ipe1;

        // Get a common unit from both study plans
        reduivy__Study_Unit__c commonUnit = [SELECT Id FROM reduivy__Study_Unit__c 
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
        ];

        // Create study offering and source IEN
        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        List<Account> campus = [SELECT Id FROM Account 
            WHERE Name = 'Sydney Campus' 
            AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() 
            LIMIT 1
        ];

        reduivy__Study_Offering__c sof = REDU_TestData_UTIL.newStudyOffering(
            commonUnit.Id + '_' + academicTerm.Id,
            commonUnit.Id,
            academicTerm.Id,
            campus[0].Id,
            commonUnit.Id + '_' + academicTerm.Id,
            20,
            System.today(),
            System.today().addDays(30)
        );
        insert sof;

        reduivy__Individual_Enrollment__c sourceIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfToCreate[1].Id,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Grade_Result__c = 'Pass',
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );
        insert sourceIen;

        Test.startTest();

        System.runAs(ADMIN_USER){
            muteTriggers();

            // Create second IPE in same IPF (causing mixed scope)
            reduivy__Individual_Program_Enrollment__c ipe2 = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlans[0].Id,
                students[0].Id,
                studyPlans[0].reduivy__Study_Program__c,
                studyPlans[0].Id,
                null, null, null, null, null, null, false,
                IPE_INPROGRESS_STATUS,
                ipfToCreate[0].Id
            );

            try {
                REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{ipe2});
                System.Assert.fail('Should throw error for mixed scope');
            } catch (Exception e) {
                String spgAutoUnitRecognitionScopeFieldLabel = Schema.SObjectType.reduivy__Study_Program__c.fields.reduivy__Auto_Unit_Recognition_Scope__c.getLabel();

                System.Assert.isTrue(e.getMessage().contains((String.format(Label.Mixture_Of_Recognition_Scope_Found, new List<String>{SPG_Helper.getObjectPluralLabel(), spgAutoUnitRecognitionScopeFieldLabel, IPF_Helper.getObjectLabel()}))),
                    'Should show mixed scope error message');
            }

            unmuteTriggers();
        }

        Test.stopTest();
    }

    /**
     * @description Test that non-recognizable IEN (e.g., In Progress) is NOT cloned
     */
    @IsTest
    static void testNonRecognizableIenNotClonedAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Program__c studyProgram = new reduivy__Study_Program__c(
            Id = studyPlan.reduivy__Study_Program__c,
            reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES
        );
        update studyProgram;

        reduivy__Study_Plan_Structure__c requiredUnit = [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> ipfsToCreate = new List<reduivy__Individual_Academic_Profile__c>();
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF1', 
                students[0].Id, 
                'IPF 1', 
                IPF_Helper.STATUS_ACTIVE, 
                true
            )
        );
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF2', 
                students[0].Id, 
                'IPF 2', 
                IPF_Helper.STATUS_ACTIVE, 
                false
            )
        );
        insert ipfsToCreate;

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        List<Account> campus = [SELECT Id FROM Account 
            WHERE Name = 'Sydney Campus' 
            AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() 
            LIMIT 1
        ];

        reduivy__Study_Offering__c sof = REDU_TestData_UTIL.newStudyOffering(
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            requiredUnit.reduivy__Study_Unit__c,
            academicTerm.Id,
            campus[0].Id,
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            20,
            System.today(),
            System.today().addDays(30)
        );
        insert sof;

        // Create In Progress IEN (NOT recognizable)
        String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
        reduivy__Individual_Enrollment__c sourceIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[0].Id,
            reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS,
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );
        insert sourceIen;

        Test.startTest();

        System.runAs(ADMIN_USER){
            muteTriggers();

            reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id + '_IPF2',
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                ipfsToCreate[1].Id
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{ipe});

            unmuteTriggers();

            // Verify NO cloned IEN
            List<reduivy__Individual_Enrollment__c> clonedIens = [SELECT Id
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :students[0].Id
                AND reduivy__Individual_Academic_Profile__c = :ipfsToCreate[1].Id
                AND reduivy__Target_Unit_Id__c = :requiredUnit.reduivy__Study_Unit__c
                AND reduivy__Enrollment_Status__c != :IEN_OPEN_STATUSES
            ];

            System.Assert.areEqual(0, clonedIens.size(), 
                'Should NOT clone non-recognizable IEN (In Progress status)');
        }

        Test.stopTest();
    }

    /**
     * @description Test that existing non-enrollable IEN prevents cloning
     */
    @IsTest
    static void testNoCloningWhenExistingNonEnrollableIenExistsAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Program__c studyProgram = new reduivy__Study_Program__c(
            Id = studyPlan.reduivy__Study_Program__c,
            reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES
        );
        update studyProgram;

        reduivy__Study_Plan_Structure__c requiredUnit = [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> ipfsToCreate = new List<reduivy__Individual_Academic_Profile__c>();
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF1', 
                students[0].Id, 
                'IPF 1', 
                IPF_Helper.STATUS_ACTIVE, 
                true
            )
        );
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF2', 
                students[0].Id, 
                'IPF 2', 
                IPF_Helper.STATUS_ACTIVE, 
                false
            )
        );
        insert ipfsToCreate;

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        List<Account> campus = [SELECT Id FROM Account 
            WHERE Name = 'Sydney Campus' 
            AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() 
            LIMIT 1
        ];

        reduivy__Study_Offering__c sof = REDU_TestData_UTIL.newStudyOffering(
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            requiredUnit.reduivy__Study_Unit__c,
            academicTerm.Id,
            campus[0].Id,
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            20,
            System.today(),
            System.today().addDays(30)
        );
        insert sof;

        // Create recognizable IEN in IPF1
        reduivy__Individual_Enrollment__c sourceIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[0].Id,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Grade_Result__c = 'Pass',
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );
        insert sourceIen;

        // Create existing non-enrollable IEN in IPF2
        String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
        reduivy__Individual_Enrollment__c existingIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[1].Id,
            reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS,
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );
        insert existingIen;

        Integer initialIenCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :students[0].Id
            AND reduivy__Individual_Academic_Profile__c = :ipfsToCreate[1].Id
        ];

        Test.startTest();

        System.runAs(ADMIN_USER){
            muteTriggers();

            reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id + '_IPF2',
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                ipfsToCreate[1].Id
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{ipe});

            unmuteTriggers();

            // Verify NO additional IEN was cloned
            Integer finalIenCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :students[0].Id
                AND reduivy__Individual_Academic_Profile__c = :ipfsToCreate[1].Id
            ];

            System.Assert.areEqual(initialIenCount, finalIenCount, 
                'Should NOT clone when non-enrollable IEN already exists in target IPF');
        }

        Test.stopTest();
    }

    /**
     * @description Test cloning with custom field mappings from Auto Unit Recognition Mapping metadata
     */
    @IsTest
    static void testAutoUnitRecognitionWithFieldMappingsAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Program__c studyProgram = new reduivy__Study_Program__c(
            Id = studyPlan.reduivy__Study_Program__c,
            reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES
        );
        update studyProgram;

        reduivy__Study_Plan_Structure__c requiredUnit = [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> ipfsToCreate = new List<reduivy__Individual_Academic_Profile__c>();
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF1', 
                students[0].Id, 
                'IPF 1', 
                IPF_Helper.STATUS_ACTIVE, 
                true
            )
        );
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF2', 
                students[0].Id, 
                'IPF 2', 
                IPF_Helper.STATUS_ACTIVE, 
                false
            )
        );
        insert ipfsToCreate;

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        List<Account> campus = [SELECT Id FROM Account 
            WHERE Name = 'Sydney Campus' 
            AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() 
            LIMIT 1
        ];

        reduivy__Study_Offering__c sof = REDU_TestData_UTIL.newStudyOffering(
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            requiredUnit.reduivy__Study_Unit__c,
            academicTerm.Id,
            campus[0].Id,
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            20,
            System.today(),
            System.today().addDays(30)
        );
        insert sof;

        // Create source IEN with custom field values
        reduivy__Individual_Enrollment__c sourceIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[0].Id,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Grade_Result__c = 'Pass',
            reduivy__Credits_Offered__c = 10,
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );
        insert sourceIen;

        Test.startTest();

        System.runAs(ADMIN_USER){
            muteTriggers();

            reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id + '_IPF2',
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                ipfsToCreate[1].Id
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{ipe});

            unmuteTriggers();

            // Verify cloned IEN has mapped fields
            List<reduivy__Individual_Enrollment__c> clonedIens = [SELECT Id, 
                reduivy__Credits_Offered__c,
                reduivy__Enrollment_Status__c,
                reduivy__Grade_Result__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :students[0].Id
                AND reduivy__Individual_Academic_Profile__c = :ipfsToCreate[1].Id
                AND reduivy__Target_Unit_Id__c = :requiredUnit.reduivy__Study_Unit__c
            ];

            System.Assert.areEqual(1, clonedIens.size(), 'Should create one cloned IEN');
            
            // Verify field mapping worked (actual values depend on metadata configuration)
            System.Assert.isNotNull(clonedIens[0].reduivy__Enrollment_Status__c,
                'Cloned IEN should have enrollment status');
            System.Assert.isNotNull(clonedIens[0].reduivy__Grade_Result__c,
                'Cloned IEN should have grade result');
        }

        Test.stopTest();
    }

    /**
     * @description Test that cloning works correctly when student has multiple recognizable IENs
     */
    @IsTest
    static void testAutoUnitRecognitionWithMultipleRecognizableIensAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Program__c studyProgram = new reduivy__Study_Program__c(
            Id = studyPlan.reduivy__Study_Program__c,
            reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES
        );
        update studyProgram;

        reduivy__Study_Plan_Structure__c requiredUnit = [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
            LIMIT 1
        ];

        // Create three IPFs
        List<reduivy__Individual_Academic_Profile__c> ipfsToCreate = new List<reduivy__Individual_Academic_Profile__c>();
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF1', 
                students[0].Id, 
                'IPF 1', 
                IPF_Helper.STATUS_ACTIVE, 
                true
            )
        );
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF2', 
                students[0].Id, 
                'IPF 2', 
                IPF_Helper.STATUS_ACTIVE, 
                false
            )
        );
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF3', 
                students[0].Id, 
                'IPF 3', 
                IPF_Helper.STATUS_ACTIVE, 
                false
            )
        );
        insert ipfsToCreate;

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        List<Account> campus = [SELECT Id FROM Account 
            WHERE Name = 'Sydney Campus' 
            AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() 
            LIMIT 1
        ];

        reduivy__Study_Offering__c sof = REDU_TestData_UTIL.newStudyOffering(
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            requiredUnit.reduivy__Study_Unit__c,
            academicTerm.Id,
            campus[0].Id,
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            20,
            System.today(),
            System.today().addDays(30)
        );
        insert sof;

        // Create two recognizable IENs in IPF1 and IPF2
        List<reduivy__Individual_Enrollment__c> sourceIens = new List<reduivy__Individual_Enrollment__c>();
        sourceIens.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[0].Id,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Grade_Result__c = 'Pass',
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        ));
        sourceIens.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[1].Id,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Grade_Result__c = 'Pass',
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        ));
        insert sourceIens;

        Test.startTest();

        System.runAs(ADMIN_USER){
            muteTriggers();

            // Create IPE in IPF3
            reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id + '_IPF3',
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                ipfsToCreate[2].Id
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{ipe});

            unmuteTriggers();

            // Verify only ONE IEN was cloned (system picks one from available recognizable IENs)
            List<reduivy__Individual_Enrollment__c> clonedIens = [SELECT Id, 
                reduivy__Grade_Result__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :students[0].Id
                AND reduivy__Individual_Academic_Profile__c = :ipfsToCreate[2].Id
                AND reduivy__Target_Unit_Id__c = :requiredUnit.reduivy__Study_Unit__c
            ];

            System.Assert.areEqual(1, clonedIens.size(), 
                'Should clone only one IEN even when multiple recognizable IENs exist');
        }

        Test.stopTest();
    }

    /**
     * @description Test that existing Open IEN is updated instead of creating new one when IPE is created as Admin
     */
    @IsTest
    static void testExistingOpenIenIsUpdatedDuringIpeCreationAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        // Get study plan and enable auto recognition
        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Study_Program__c,
            reduivy__Individual_Enrollment_Creation_Mode__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;
        update studyPlan;

        reduivy__Study_Program__c studyProgram = new reduivy__Study_Program__c(
            Id = studyPlan.reduivy__Study_Program__c,
            reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES
        );
        update studyProgram;

        // Get required unit
        reduivy__Study_Plan_Structure__c requiredUnit = [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
            LIMIT 1
        ];

        // Create two IPFs
        List<reduivy__Individual_Academic_Profile__c> ipfsToCreate = new List<reduivy__Individual_Academic_Profile__c>();
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF1', 
                students[0].Id, 
                'IPF 1', 
                IPF_Helper.STATUS_ACTIVE, 
                true
            )
        );
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF2', 
                students[0].Id, 
                'IPF 2', 
                IPF_Helper.STATUS_ACTIVE, 
                false
            )
        );
        insert ipfsToCreate;

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        List<Account> campus = [SELECT Id FROM Account 
            WHERE Name = 'Sydney Campus' 
            AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() 
            LIMIT 1
        ];

        reduivy__Study_Offering__c sof = REDU_TestData_UTIL.newStudyOffering(
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            requiredUnit.reduivy__Study_Unit__c,
            academicTerm.Id,
            campus[0].Id,
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            20,
            System.today(),
            System.today().addDays(30)
        );
        insert sof;

        // Create completed IEN in IPF1 (source for cloning)
        reduivy__Individual_Enrollment__c sourceIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[0].Id,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Grade_Result__c = 'Pass',
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );
        insert sourceIen;

        // Create existing Open IEN in IPF2
        reduivy__Individual_Enrollment__c existingOpenIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Unit__c = requiredUnit.reduivy__Study_Unit__c,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[1].Id,
            reduivy__Enrollment_Status__c = IEN_OPEN_STATUSES,
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );
        insert existingOpenIen;

        Id existingOpenIenId = existingOpenIen.Id;

        Test.startTest();

        System.runAs(ADMIN_USER){
            muteTriggers();

            // Create IPE in IPF2 (should trigger cloning to update Open IEN)
            reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id + '_IPF2',
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                ipfsToCreate[1].Id
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{ipe});

            unmuteTriggers();

            // Verify Open IEN was UPDATED, not inserted new
            reduivy__Individual_Enrollment__c updatedIen = [SELECT Id, 
                reduivy__Enrollment_Status__c,
                reduivy__Grade_Result__c,
                reduivy__Credit_Transfer_Type__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :existingOpenIenId
            ];

            System.Assert.areEqual(existingOpenIenId, updatedIen.Id,
                'Should be same IEN record (updated, not new)');
            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, updatedIen.reduivy__Enrollment_Status__c,
                'Open IEN should be updated to Completed status');
            System.Assert.areEqual('Pass', updatedIen.reduivy__Grade_Result__c,
                'Open IEN should have cloned grade result');

            // Verify no duplicate IEN was created
            Integer ienCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :students[0].Id
                AND reduivy__Individual_Academic_Profile__c = :ipfsToCreate[1].Id
                AND reduivy__Target_Unit_Id__c = :requiredUnit.reduivy__Study_Unit__c
            ];

            System.Assert.areEqual(1, ienCount,
                'Should have only 1 IEN (updated Open IEN, not duplicate)');
        }

        Test.stopTest();
    }

    /**
     * @description Test Open IEN prevents placeholder creation when Required Units Only mode as Admin
     */
    @IsTest
    static void testOpenIenPreventsPlaceholderCreationAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;
        update studyPlan;

        List<reduivy__Study_Plan_Structure__c> requiredUnits = [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
        ];

        List<reduivy__Individual_Academic_Profile__c> ipfToCreate = new List<reduivy__Individual_Academic_Profile__c>();
        ipfToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF1', 
                students[0].Id, 
                'IPF 1', 
                IPF_Helper.STATUS_ACTIVE, 
                true
            )
        );
        insert ipfToCreate;

        List<reduivy__Individual_Enrollment__c> existingOpenIen = new List<reduivy__Individual_Enrollment__c>();

        for(reduivy__Study_Plan_Structure__c requiredUnit : requiredUnits) {
            existingOpenIen.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = students[0].Id,
                reduivy__Study_Unit__c = requiredUnit.reduivy__Study_Unit__c,
                reduivy__Individual_Academic_Profile__c = ipfToCreate[0].Id,
                reduivy__Enrollment_Status__c = IEN_OPEN_STATUSES,
                reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }
        
        insert existingOpenIen;

        Integer initialIenCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :students[0].Id
            AND reduivy__Individual_Academic_Profile__c = :ipfToCreate[0].Id
        ];

        Test.startTest();

        System.runAs(ADMIN_USER){
            muteTriggers();

            reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id,
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                ipfToCreate[0].Id
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{ipe});

            unmuteTriggers();

            // Verify no additional placeholder was created
            Integer finalIenCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :students[0].Id
                AND reduivy__Individual_Academic_Profile__c = :ipfToCreate[0].Id
            ];

            System.Assert.areEqual(initialIenCount, finalIenCount,
                'Should NOT create placeholder when Open IEN already exists');
        }

        Test.stopTest();
    }

    /**
     * @description Test Open IEN is reused when cloning AND placeholder creation would occur as Admin
     */
    @IsTest
    static void testOpenIenReusedDuringCloningInsteadOfPlaceholderAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;
        update studyPlan;

        reduivy__Study_Program__c studyProgram = new reduivy__Study_Program__c(
            Id = studyPlan.reduivy__Study_Program__c,
            reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES
        );
        update studyProgram;

        reduivy__Study_Plan_Structure__c requiredUnit = [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
            LIMIT 1
        ];

        // Create two IPFs
        List<reduivy__Individual_Academic_Profile__c> ipfsToCreate = new List<reduivy__Individual_Academic_Profile__c>();
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF1', 
                students[0].Id, 
                'IPF 1', 
                IPF_Helper.STATUS_ACTIVE, 
                true
            )
        );
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF2', 
                students[0].Id, 
                'IPF 2', 
                IPF_Helper.STATUS_ACTIVE, 
                false
            )
        );
        insert ipfsToCreate;

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        List<Account> campus = [SELECT Id FROM Account 
            WHERE Name = 'Sydney Campus' 
            AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() 
            LIMIT 1
        ];

        reduivy__Study_Offering__c sof = REDU_TestData_UTIL.newStudyOffering(
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            requiredUnit.reduivy__Study_Unit__c,
            academicTerm.Id,
            campus[0].Id,
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            20,
            System.today(),
            System.today().addDays(30)
        );
        insert sof;

        // Create completed IEN in IPF1
        reduivy__Individual_Enrollment__c sourceIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[0].Id,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Grade_Result__c = 'Pass',
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );
        insert sourceIen;

        // Create Open IEN in IPF2
        reduivy__Individual_Enrollment__c openIenIpf2 = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Unit__c = requiredUnit.reduivy__Study_Unit__c,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[1].Id,
            reduivy__Enrollment_Status__c = IEN_OPEN_STATUSES,
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );
        insert openIenIpf2;

        Id openIenId = openIenIpf2.Id;

        Test.startTest();

        System.runAs(ADMIN_USER){
            muteTriggers();

            reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id + '_IPF2',
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                ipfsToCreate[1].Id
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{ipe});

            unmuteTriggers();

            // Verify Open IEN was updated (not placeholder created)
            reduivy__Individual_Enrollment__c updatedIen = [SELECT Id, 
                reduivy__Enrollment_Status__c,
                reduivy__Grade_Result__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :openIenId
            ];

            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, updatedIen.reduivy__Enrollment_Status__c,
                'Open IEN should be updated via cloning, not placeholder creation');
            System.Assert.areEqual('Pass', updatedIen.reduivy__Grade_Result__c,
                'Should have cloned grade result');

            // Verify only 1 IEN exists in IPF2
            Integer ienCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :students[0].Id
                AND reduivy__Individual_Academic_Profile__c = :ipfsToCreate[1].Id
                AND reduivy__Target_Unit_Id__c = :requiredUnit.reduivy__Study_Unit__c
            ];

            System.Assert.areEqual(1, ienCount,
                'Should update Open IEN instead of creating placeholder');
        }

        Test.stopTest();
    }

    /**
     * @description Test non-enrollable IEN prevents both cloning AND placeholder creation as Admin
     */
    @IsTest
    static void testNonEnrollableIenPreventsOpenIenUpdateAndPlaceholderAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;
        update studyPlan;

        reduivy__Study_Program__c studyProgram = new reduivy__Study_Program__c(
            Id = studyPlan.reduivy__Study_Program__c,
            reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES
        );
        update studyProgram;

        reduivy__Study_Plan_Structure__c requiredUnit = [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> ipfsToCreate = new List<reduivy__Individual_Academic_Profile__c>();
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF1', 
                students[0].Id, 
                'IPF 1', 
                IPF_Helper.STATUS_ACTIVE, 
                true
            )
        );
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF2', 
                students[0].Id, 
                'IPF 2', 
                IPF_Helper.STATUS_ACTIVE, 
                false
            )
        );
        insert ipfsToCreate;

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        List<Account> campus = [SELECT Id FROM Account 
            WHERE Name = 'Sydney Campus' 
            AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() 
            LIMIT 1
        ];

        reduivy__Study_Offering__c sof = REDU_TestData_UTIL.newStudyOffering(
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            requiredUnit.reduivy__Study_Unit__c,
            academicTerm.Id,
            campus[0].Id,
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            20,
            System.today(),
            System.today().addDays(30)
        );
        insert sof;

        // Create completed IEN in IPF1 (source)
        reduivy__Individual_Enrollment__c sourceIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[0].Id,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Grade_Result__c = 'Pass',
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );
        insert sourceIen;

        // Create Open IEN in IPF2
        reduivy__Individual_Enrollment__c openIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Unit__c = requiredUnit.reduivy__Study_Unit__c,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[1].Id,
            reduivy__Enrollment_Status__c = IEN_OPEN_STATUSES,
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );

        // Create non-enrollable IEN in IPF2 (should block everything)
        reduivy__Individual_Enrollment__c nonEnrollableIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[1].Id,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );

        insert new List<reduivy__Individual_Enrollment__c>{openIen, nonEnrollableIen};

        String originalOpenStatus = openIen.reduivy__Enrollment_Status__c;

        Test.startTest();

        System.runAs(ADMIN_USER){
            muteTriggers();

            reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id + '_IPF2',
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                ipfsToCreate[1].Id
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{ipe});

            unmuteTriggers();

            // Verify Open IEN was NOT updated
            reduivy__Individual_Enrollment__c openIenAfter = [SELECT Id, 
                reduivy__Enrollment_Status__c,
                reduivy__Grade_Result__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :openIen.Id
            ];

            System.Assert.areEqual(originalOpenStatus, openIenAfter.reduivy__Enrollment_Status__c,
                'Open IEN should NOT be updated when non-enrollable exists');
            System.Assert.isNull(openIenAfter.reduivy__Grade_Result__c,
                'Open IEN should remain unchanged');

            // Verify no new IEN was created
            Integer ienCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :students[0].Id
                AND reduivy__Individual_Academic_Profile__c = :ipfsToCreate[1].Id
                AND reduivy__Target_Unit_Id__c = :requiredUnit.reduivy__Study_Unit__c
            ];

            System.Assert.areEqual(2, ienCount,
                'Should have original 2 IENs (Open + non-enrollable), no new ones created');
        }

        Test.stopTest();
    }

    /**
     * @description Test multiple IPFs with mix of Open IENs, cloning, and placeholders as Admin
     */
    @IsTest
    static void testComplexScenarioWithMultipleIpfsOpenIensAndCloningAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;
        update studyPlan;

        reduivy__Study_Program__c studyProgram = new reduivy__Study_Program__c(
            Id = studyPlan.reduivy__Study_Program__c,
            reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES
        );
        update studyProgram;

        List<reduivy__Study_Plan_Structure__c> requiredUnits = [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
            LIMIT 3
        ];

        System.Assert.isTrue(requiredUnits.size() >= 3, 'Need at least 3 required units for test');

        // Create three IPFs
        List<reduivy__Individual_Academic_Profile__c> ipfsToCreate = new List<reduivy__Individual_Academic_Profile__c>();
        for(Integer i = 1; i <= 3; i++) {
            ipfsToCreate.add(
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    students[0].Id + '_IPF' + i, 
                    students[0].Id, 
                    'IPF ' + i, 
                    IPF_Helper.STATUS_ACTIVE, 
                    i == 1
                )
            );
        }
        insert ipfsToCreate;

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        List<Account> campus = [SELECT Id FROM Account 
            WHERE Name = 'Sydney Campus' 
            AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() 
            LIMIT 1
        ];

        // Create study offerings
        List<reduivy__Study_Offering__c> sofs = new List<reduivy__Study_Offering__c>();
        for(reduivy__Study_Plan_Structure__c unit : requiredUnits) {
            sofs.add(REDU_TestData_UTIL.newStudyOffering(
                unit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
                unit.reduivy__Study_Unit__c,
                academicTerm.Id,
                campus[0].Id,
                unit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
                20,
                System.today(),
                System.today().addDays(30)
            ));
        }
        insert sofs;

        // IPF1: Completed IEN for Unit1 (source for cloning)
        reduivy__Individual_Enrollment__c ienIpf1Unit1 = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sofs[0].Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[0].Id,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Grade_Result__c = 'Pass',
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );

        // IPF2: Open IEN for Unit1 (will be updated via cloning)
        reduivy__Individual_Enrollment__c ienIpf2Unit1Open = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Unit__c = requiredUnits[0].reduivy__Study_Unit__c,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[1].Id,
            reduivy__Enrollment_Status__c = IEN_OPEN_STATUSES,
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );

        // IPF2: Open IEN for Unit2 (will remain as placeholder - no source)
        reduivy__Individual_Enrollment__c ienIpf2Unit2Open = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Unit__c = requiredUnits[1].reduivy__Study_Unit__c,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[1].Id,
            reduivy__Enrollment_Status__c = IEN_OPEN_STATUSES,
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );

        insert new List<reduivy__Individual_Enrollment__c>{ienIpf1Unit1, ienIpf2Unit1Open, ienIpf2Unit2Open};

        Test.startTest();

        System.runAs(ADMIN_USER){
            muteTriggers();

            // Create IPE in IPF2
            reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id + '_IPF2',
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                ipfsToCreate[1].Id
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{ipe});

            unmuteTriggers();

            // Verify Open IEN for Unit1 was updated via cloning
            reduivy__Individual_Enrollment__c unit1Updated = [SELECT Id, 
                reduivy__Enrollment_Status__c,
                reduivy__Grade_Result__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :ienIpf2Unit1Open.Id
            ];

            System.Assert.areEqual(IEN_COMPLETED_PASS_STATUS, unit1Updated.reduivy__Enrollment_Status__c,
                'Unit1 Open IEN should be updated via cloning');
            System.Assert.areEqual('Pass', unit1Updated.reduivy__Grade_Result__c,
                'Unit1 should have cloned grade');

            // Verify Open IEN for Unit2 remains unchanged (no source to clone)
            reduivy__Individual_Enrollment__c unit2Unchanged = [SELECT Id, 
                reduivy__Enrollment_Status__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :ienIpf2Unit2Open.Id
            ];

            System.Assert.areEqual(IEN_OPEN_STATUSES, unit2Unchanged.reduivy__Enrollment_Status__c,
                'Unit2 Open IEN should remain unchanged (no source to clone)');

            // Verify placeholder created for Unit3 (no Open IEN exists)
            List<reduivy__Individual_Enrollment__c> unit3Iens = [SELECT Id, 
                reduivy__Enrollment_Status__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :students[0].Id
                AND reduivy__Individual_Academic_Profile__c = :ipfsToCreate[1].Id
                AND reduivy__Target_Unit_Id__c = :requiredUnits[2].reduivy__Study_Unit__c
            ];

            System.Assert.areEqual(1, unit3Iens.size(),
                'Should create placeholder for Unit3');
            System.Assert.areEqual(IEN_OPEN_STATUSES, unit3Iens[0].reduivy__Enrollment_Status__c,
                'Unit3 should have Open status placeholder');
        }

        Test.stopTest();
    }

    /**
     * @description Test that multiple Open IENs scenario will update all as Admin
     */
    @IsTest
    static void testMultipleOpenIensUpdatedDuringIpeCreationAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Program__c studyProgram = new reduivy__Study_Program__c(
            Id = studyPlan.reduivy__Study_Program__c,
            reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES
        );
        update studyProgram;

        reduivy__Study_Plan_Structure__c requiredUnit = [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> ipfsToCreate = new List<reduivy__Individual_Academic_Profile__c>();
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF1', 
                students[0].Id, 
                'IPF 1', 
                IPF_Helper.STATUS_ACTIVE, 
                true
            )
        );
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF2', 
                students[0].Id, 
                'IPF 2', 
                IPF_Helper.STATUS_ACTIVE, 
                false
            )
        );
        insert ipfsToCreate;

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        List<Account> campus = [SELECT Id FROM Account 
            WHERE Name = 'Sydney Campus' 
            AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() 
            LIMIT 1
        ];

        reduivy__Study_Offering__c sof = REDU_TestData_UTIL.newStudyOffering(
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            requiredUnit.reduivy__Study_Unit__c,
            academicTerm.Id,
            campus[0].Id,
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            20,
            System.today(),
            System.today().addDays(30)
        );
        insert sof;

        // Create source IEN
        reduivy__Individual_Enrollment__c sourceIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[0].Id,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Grade_Result__c = 'Pass',
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );
        insert sourceIen;

        // Create MULTIPLE Open IENs in IPF2 (edge case)
        List<reduivy__Individual_Enrollment__c> openIens = new List<reduivy__Individual_Enrollment__c>();
        for(Integer i = 0; i < 5; i++) {
            openIens.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = students[0].Id,
                reduivy__Study_Unit__c = requiredUnit.reduivy__Study_Unit__c,
                reduivy__Individual_Academic_Profile__c = ipfsToCreate[1].Id,
                reduivy__Enrollment_Status__c = IEN_OPEN_STATUSES,
                reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }
        insert openIens;

        Test.startTest();

        System.runAs(ADMIN_USER){
            muteTriggers();

            reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id + '_IPF2',
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                ipfsToCreate[1].Id
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{ipe});

            unmuteTriggers();

            // Verify only ONE Open IEN was updated
            Integer updatedCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Individual_Academic_Profile__c = :ipfsToCreate[1].Id
                AND reduivy__Target_Unit_Id__c = :requiredUnit.reduivy__Study_Unit__c
                AND reduivy__Enrollment_Status__c = :IEN_COMPLETED_PASS_STATUS
            ];

            System.Assert.areEqual(5, updatedCount,
                'All Open IEN should be updated');
        }

        Test.stopTest();
    }

    /**
     * @description Test cloning with existing active IEN in target IPF prevents Open IEN update as Admin
     */
    @IsTest
    static void testActiveIenInTargetIpfPreventsOpenIenUpdateAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Program__c studyProgram = new reduivy__Study_Program__c(
            Id = studyPlan.reduivy__Study_Program__c,
            reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES
        );
        update studyProgram;

        reduivy__Study_Plan_Structure__c requiredUnit = [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
            LIMIT 1
        ];

        List<reduivy__Individual_Academic_Profile__c> ipfsToCreate = new List<reduivy__Individual_Academic_Profile__c>();
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF1', 
                students[0].Id, 
                'IPF 1', 
                IPF_Helper.STATUS_ACTIVE, 
                true
            )
        );
        ipfsToCreate.add(
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                students[0].Id + '_IPF2', 
                students[0].Id, 
                'IPF 2', 
                IPF_Helper.STATUS_ACTIVE, 
                false
            )
        );
        insert ipfsToCreate;

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        List<Account> campus = [SELECT Id FROM Account 
            WHERE Name = 'Sydney Campus' 
            AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() 
            LIMIT 1
        ];

        reduivy__Study_Offering__c sof = REDU_TestData_UTIL.newStudyOffering(
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            requiredUnit.reduivy__Study_Unit__c,
            academicTerm.Id,
            campus[0].Id,
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            20,
            System.today(),
            System.today().addDays(30)
        );
        insert sof;

        // Create completed IEN in IPF1 (potential source)
        reduivy__Individual_Enrollment__c sourceIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[0].Id,
            reduivy__Enrollment_Status__c = IEN_COMPLETED_PASS_STATUS,
            reduivy__Grade_Result__c = 'Pass',
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );

        // Create active In Progress IEN in IPF2 (takes precedence)
        reduivy__Individual_Enrollment__c activeIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sof.Id,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[1].Id,
            reduivy__Enrollment_Status__c = IEN_INPROGRESS_STATUS,
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );

        // Create Open IEN in IPF2
        reduivy__Individual_Enrollment__c openIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Unit__c = requiredUnit.reduivy__Study_Unit__c,
            reduivy__Individual_Academic_Profile__c = ipfsToCreate[1].Id,
            reduivy__Enrollment_Status__c = IEN_OPEN_STATUSES,
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true
        );

        insert new List<reduivy__Individual_Enrollment__c>{sourceIen, activeIen, openIen};

        Test.startTest();

        System.runAs(ADMIN_USER){
            muteTriggers();

            reduivy__Individual_Program_Enrollment__c ipe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                students[0].Id + '_' + studyPlan.Id + '_IPF2',
                students[0].Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                ipfsToCreate[1].Id
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{ipe});

            unmuteTriggers();

            // Verify Open IEN was NOT updated (active IEN exists)
            reduivy__Individual_Enrollment__c openIenAfter = [SELECT Id, 
                reduivy__Enrollment_Status__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :openIen.Id
            ];

            System.Assert.areEqual(IEN_OPEN_STATUSES, openIenAfter.reduivy__Enrollment_Status__c,
                'Open IEN should NOT be updated when active IEN exists');

            // Verify IPS is linked to active IEN, not Open IEN
            List<reduivy__Individual_Plan_Structure__c> ipsUnits = [SELECT Id, 
                reduivy__Individual_Enrollment__c
                FROM reduivy__Individual_Plan_Structure__c
                WHERE reduivy__Individual_Program_Enrollment__c = :ipe.Id
                AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Target_Unit_Id__c = :requiredUnit.reduivy__Study_Unit__c
            ];

            System.Assert.areEqual(1, ipsUnits.size(), 'Should create IPS');
            System.Assert.areEqual(activeIen.Id, ipsUnits[0].reduivy__Individual_Enrollment__c,
                'IPS should link to active IEN, not Open IEN');
        }

        Test.stopTest();
    }

    /**
     * @description Test bulk IPS creation with multiple students and different units as admin
     */
    @IsTest
    static void testBulkIpsCreationWithMultipleStudentsAndDifferentUnitsAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> students = [
            SELECT Id, reduivy__Sample_Record_Code__c, Name
            FROM Contact
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c != null
            LIMIT 3
        ];
        System.assertEquals(3, students.size(), 'Need at least 3 students for this test');

        // Study Program
        reduivy__Study_Program__c studyProgram = [
            SELECT Id
            FROM reduivy__Study_Program__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS'
            LIMIT 1
        ];

        studyProgram.reduivy__Auto_Unit_Recognition_Scope__c =
            SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        update studyProgram;

        Account eduInst;
        Account campus;

        for(Account acc : [
            SELECT Id, reduivy__Sample_Record_Code__c
            FROM Account
            WHERE reduivy__Sample_Record_Code__c IN ('RIOUNI', 'SYDNEY')
        ]) {
            if(acc.reduivy__Sample_Record_Code__c == 'RIOUNI') eduInst = acc;
            if(acc.reduivy__Sample_Record_Code__c == 'SYDNEY') campus = acc;
        }

        // Current academic term
        reduivy__Study_Term__c academicTerm = [
            SELECT Id, reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId()
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        Map<String, reduivy__Study_Unit__c> unitMap = new Map<String, reduivy__Study_Unit__c>();
        List<reduivy__Study_Unit__c> testUnits = new List<reduivy__Study_Unit__c>();

        for(String unitCode : new List<String>{'TEST101','TEST201','TEST301'}) {
            testUnits.add(new reduivy__Study_Unit__c(
                Name = unitCode + ' - Test Unit',
                reduivy__Sample_Record_Code__c = unitCode,
                reduivy__Unit_Code__c = unitCode,
                reduivy__Educational_Institution__c = eduInst.Id
            ));
        }
        insert testUnits;

        for(reduivy__Study_Unit__c u : testUnits) {
            unitMap.put(u.reduivy__Sample_Record_Code__c, u);
        }

        Map<String, reduivy__Study_Plan__c> studyPlanMap = new Map<String, reduivy__Study_Plan__c>();
        List<reduivy__Study_Plan__c> studyPlans = new List<reduivy__Study_Plan__c>();

        for(String planName : new List<String>{'Plan_A','Plan_B','Plan_C','Plan_D','Plan_E','Plan_F'}) {
            studyPlans.add(new reduivy__Study_Plan__c(
                Name = planName,
                reduivy__Sample_Record_Code__c = planName,
                reduivy__Study_Program__c = studyProgram.Id
            ));
        }
        insert studyPlans;

        for(reduivy__Study_Plan__c p : studyPlans) {
            studyPlanMap.put(p.reduivy__Sample_Record_Code__c, p);
        }

        List<reduivy__Study_Plan_Structure__c> planGroups = new List<reduivy__Study_Plan_Structure__c>();
        Map<String, reduivy__Study_Plan_Structure__c> groupMap = new Map<String, reduivy__Study_Plan_Structure__c>();

        for(String planName : studyPlanMap.keySet()) {
            planGroups.add(new reduivy__Study_Plan_Structure__c(
                Name = planName + '_Group',
                reduivy__Sample_Record_Code__c = planName + '_Group',
                reduivy__Study_Plan__c = studyPlanMap.get(planName).Id,
                RecordTypeId = SPS_Helper.getGroupRecordTypeId(),
                reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
                reduivy__Credits__c = 40,
                reduivy__Sequence__c = 1
            ));
        }
        insert planGroups;

        for(reduivy__Study_Plan_Structure__c g : planGroups) {
            groupMap.put(g.reduivy__Sample_Record_Code__c, g);
        }

        List<reduivy__Study_Plan_Structure__c> planStructures = new List<reduivy__Study_Plan_Structure__c>();

        planStructures.add(new reduivy__Study_Plan_Structure__c(
            Name = 'Plan_A_TEST101',
            reduivy__Sample_Record_Code__c = 'Plan_A_TEST101',
            reduivy__Study_Plan__c = studyPlanMap.get('Plan_A').Id,
            reduivy__Parent_Study_Plan_Structure__c = groupMap.get('Plan_A_Group').Id,
            reduivy__Study_Unit__c = unitMap.get('TEST101').Id,
            RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
            reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
            reduivy__Credits__c = 3,
            reduivy__Sequence__c = 1
        ));
        planStructures.add(new reduivy__Study_Plan_Structure__c(
            Name = 'Plan_B_TEST101',
            reduivy__Sample_Record_Code__c = 'Plan_B_TEST101',
            reduivy__Study_Plan__c = studyPlanMap.get('Plan_B').Id,
            reduivy__Parent_Study_Plan_Structure__c = groupMap.get('Plan_B_Group').Id,
            reduivy__Study_Unit__c = unitMap.get('TEST101').Id,
            RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
            reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
            reduivy__Credits__c = 3,
            reduivy__Sequence__c = 1
        ));
        planStructures.add(new reduivy__Study_Plan_Structure__c(
            Name = 'Plan_C_TEST201',
            reduivy__Sample_Record_Code__c = 'Plan_C_TEST201',
            reduivy__Study_Plan__c = studyPlanMap.get('Plan_C').Id,
            reduivy__Parent_Study_Plan_Structure__c = groupMap.get('Plan_C_Group').Id,
            reduivy__Study_Unit__c = unitMap.get('TEST201').Id,
            RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
            reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
            reduivy__Credits__c = 3,
            reduivy__Sequence__c = 1
        ));
        planStructures.add(new reduivy__Study_Plan_Structure__c(
            Name = 'Plan_D_TEST201',
            reduivy__Sample_Record_Code__c = 'Plan_D_TEST201',
            reduivy__Study_Plan__c = studyPlanMap.get('Plan_D').Id,
            reduivy__Parent_Study_Plan_Structure__c = groupMap.get('Plan_D_Group').Id,
            reduivy__Study_Unit__c = unitMap.get('TEST201').Id,
            RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
            reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
            reduivy__Credits__c = 3,
            reduivy__Sequence__c = 1
        ));
        planStructures.add(new reduivy__Study_Plan_Structure__c(
            Name = 'Plan_E_TEST301',
            reduivy__Sample_Record_Code__c = 'Plan_E_TEST301',
            reduivy__Study_Plan__c = studyPlanMap.get('Plan_E').Id,
            reduivy__Parent_Study_Plan_Structure__c = groupMap.get('Plan_E_Group').Id,
            reduivy__Study_Unit__c = unitMap.get('TEST301').Id,
            RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
            reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
            reduivy__Credits__c = 3,
            reduivy__Sequence__c = 1
        ));
        planStructures.add(new reduivy__Study_Plan_Structure__c(
            Name = 'Plan_F_TEST301',
            reduivy__Sample_Record_Code__c = 'Plan_F_TEST301',
            reduivy__Study_Plan__c = studyPlanMap.get('Plan_F').Id,
            reduivy__Parent_Study_Plan_Structure__c = groupMap.get('Plan_F_Group').Id,
            reduivy__Study_Unit__c = unitMap.get('TEST301').Id,
            RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
            reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
            reduivy__Credits__c = 3,
            reduivy__Sequence__c = 1
        ));
        insert planStructures;

        List<reduivy__Study_Offering__c> testOfferings = new List<reduivy__Study_Offering__c>();
        for(reduivy__Study_Unit__c unit : testUnits) {
            testOfferings.add(new reduivy__Study_Offering__c(
                Name = unit.reduivy__Sample_Record_Code__c + '_' + academicTerm.reduivy__Sample_Record_Code__c + '_SYDNEY',
                reduivy__Sample_Record_Code__c = unit.reduivy__Sample_Record_Code__c + '_' + academicTerm.reduivy__Sample_Record_Code__c + '_SYDNEY',
                reduivy__Study_Unit__c = unit.Id,
                reduivy__Academic_Term__c = academicTerm.Id,
                reduivy__Campus__c = campus.Id
            ));
        }
        insert testOfferings;

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap =
            new Map<String, reduivy__Individual_Academic_Profile__c>();

        Map<Id, Map<String, Id>> studentToPlanMap = new Map<Id, Map<String, Id>>();
        Map<Id, String> studentToUnitCodeMap = new Map<Id, String>();

        studentToPlanMap.put(students[0].Id, new Map<String, Id>{
            'Profile1' => studyPlanMap.get('Plan_A').Id,
            'Profile2' => studyPlanMap.get('Plan_B').Id
        });
        studentToUnitCodeMap.put(students[0].Id, 'TEST101');

        studentToPlanMap.put(students[1].Id, new Map<String, Id>{
            'Profile1' => studyPlanMap.get('Plan_C').Id,
            'Profile2' => studyPlanMap.get('Plan_D').Id
        });
        studentToUnitCodeMap.put(students[1].Id, 'TEST201');

        studentToPlanMap.put(students[2].Id, new Map<String, Id>{
            'Profile1' => studyPlanMap.get('Plan_E').Id,
            'Profile2' => studyPlanMap.get('Plan_F').Id
        });
        studentToUnitCodeMap.put(students[2].Id, 'TEST301');

        for(Contact student : students) {
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

        Map<String, reduivy__Individual_Enrollment__c> newIenMap =
            new Map<String, reduivy__Individual_Enrollment__c>();

        for(Contact student : students) {
            String unitCode = studentToUnitCodeMap.get(student.Id);
            reduivy__Study_Unit__c assignedUnit = unitMap.get(unitCode);

            reduivy__Study_Offering__c sof = [
                SELECT Id, reduivy__Sample_Record_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c = :academicTerm.Id
                AND reduivy__Campus__c = :campus.Id
                AND reduivy__Study_Unit__c = :assignedUnit.Id
                LIMIT 1
            ];

            String ienKey = student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c;

            reduivy__Individual_Enrollment__c tempIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                ienKey,
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
                newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile1').Id,
                true
            );
            tempIen.reduivy__Grade_Result__c = 'Pass';

            newIenMap.put(ienKey, tempIen);
        }
        insert newIenMap.values();

        Test.startTest();
        System.runAs(ADMIN_USER){

            List<reduivy__Individual_Program_Enrollment__c> newIpeList =
                new List<reduivy__Individual_Program_Enrollment__c>();

            for(Contact student : students) {
                newIpeList.add(
                    REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_IPE1',
                        student.Id,
                        studyProgram.Id,
                        studentToPlanMap.get(student.Id).get('Profile1'),
                        null,
                        academicTerm.Id,
                        null,
                        null,
                        null,
                        null,
                        true,
                        IPE_INPROGRESS_STATUS,
                        newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile1').Id
                    )
                );
                newIpeList.add(
                    REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_IPE2',
                        student.Id,
                        studyProgram.Id,
                        studentToPlanMap.get(student.Id).get('Profile2'),
                        null,
                        academicTerm.Id,
                        null,
                        null,
                        null,
                        null,
                        true,
                        IPE_INPROGRESS_STATUS,
                        newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile2').Id
                    )
                );
            }
            REDU_Database_UTIL.doInsert(newIpeList);

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> studentToIpsUnits =
                new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();

            for(reduivy__Individual_Plan_Structure__c ipsUnit : [
                SELECT Id, Name,
                    reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
                    reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
                    reduivy__Target_Unit_Id__c,
                    reduivy__Individual_Enrollment__c,
                    reduivy__Status__c,
                    RecordTypeId,
                    reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.Name,
                    reduivy__Individual_Enrollment__r.reduivy__Target_Unit_Id__c
                FROM reduivy__Individual_Plan_Structure__c
                WHERE reduivy__Individual_Program_Enrollment__c IN :newIpeList
                AND RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
                AND reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c IN ('TEST101', 'TEST201', 'TEST301')
                ORDER BY reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c
            ]) {
                Id contactId = ipsUnit.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c;
                if(!studentToIpsUnits.containsKey(contactId)) {
                    studentToIpsUnits.put(contactId, new List<reduivy__Individual_Plan_Structure__c>());
                }
                studentToIpsUnits.get(contactId).add(ipsUnit);
            }

            System.assertEquals(students.size(), studentToIpsUnits.size(),
                'Should have IPS units for all students');

            Integer studentIndex = 0;
            for(Contact student : students) {
                List<reduivy__Individual_Plan_Structure__c> studentIpsUnits =
                    studentToIpsUnits.get(student.Id);

                System.assertEquals(2, studentIpsUnits.size(),
                    'Student ' + (studentIndex + 1) + ' should have 2 IPS units (one per profile)');

                String expectedUnitCode = studentToUnitCodeMap.get(student.Id);
                String expectedUnitId = unitMap.get(expectedUnitCode).Id;

                for(reduivy__Individual_Plan_Structure__c ipsUnit : studentIpsUnits) {
                    System.assertNotEquals(null, ipsUnit.reduivy__Individual_Enrollment__c,
                        'Student ' + (studentIndex + 1) + ' IPS should be linked to IEN');

                    System.assertEquals(expectedUnitId, ipsUnit.reduivy__Individual_Enrollment__r.reduivy__Target_Unit_Id__c,
                        'Student ' + (studentIndex + 1) + ' IPS unit should be for unit ' + expectedUnitCode);

                    System.assertEquals(IPS_Helper.STATUS_TYPE_COMPLETED, ipsUnit.reduivy__Status__c,
                        'Student ' + (studentIndex + 1) + ' IPS should have Completed status');
                }

                Set<Id> ipfIds = new Set<Id>();
                for(reduivy__Individual_Plan_Structure__c ipsUnit : studentIpsUnits) {
                    ipfIds.add(
                        ipsUnit.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c
                    );
                }

                System.assert(ipfIds.contains(
                    newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile1').Id));
                System.assert(ipfIds.contains(
                    newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile2').Id));

                studentIndex++;
            }

            List<reduivy__Individual_Plan_Structure__c> groupIpsList = [
                SELECT Id
                FROM reduivy__Individual_Plan_Structure__c
                WHERE reduivy__Individual_Program_Enrollment__c IN :newIpeList
                AND RecordTypeId = :IPS_Helper.getGroupRecordTypeId()
            ];

            System.assertEquals(students.size() * 2, groupIpsList.size(),
                'Should create group IPS for each IPE');
        }
        Test.stopTest();
    }

    /**
     * @description Test that existing In Progress IEN is NOT updated when completed IEN exists in another profile during IPS creation as Admin
     */
    @IsTest
    static void testInProgressIenNotUpdatedWhenCompletedExistsDuringIpsCreationAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        Contact student = [SELECT Id, reduivy__Sample_Record_Code__c FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> '' LIMIT 1
        ];

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' LIMIT 1
        ];

        // Enable auto unit recognition
        reduivy__Study_Program__c studyProgram = new reduivy__Study_Program__c(
            Id = studyPlan.reduivy__Study_Program__c,
            reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES
        );
        update studyProgram;

        reduivy__Study_Plan_Structure__c requiredUnit = [SELECT Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
            LIMIT 1
        ];

        // Create IPFs
        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        ipfMap.put('Profile1', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.reduivy__Sample_Record_Code__c + '_Profile1',
            student.Id, 'Profile1', IPF_Helper.STATUS_ACTIVE, true
        ));
        ipfMap.put('Profile2', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.reduivy__Sample_Record_Code__c + '_Profile2',
            student.Id, 'Profile2', IPF_Helper.STATUS_ACTIVE, false
        ));
        insert ipfMap.values();

        List<Account> campus = [SELECT Id FROM Account WHERE Name = 'Sydney Campus' 
            AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1
        ];

        reduivy__Study_Offering__c sof = REDU_TestData_UTIL.newStudyOffering(
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            requiredUnit.reduivy__Study_Unit__c,
            academicTerm.Id,
            campus[0].Id,
            requiredUnit.reduivy__Study_Unit__c + '_' + academicTerm.Id,
            20,
            System.today(),
            System.today().addDays(30)
        );
        insert sof;

        System.runAs(ADMIN_USER) {
            muteTriggers();

            // Step 1: Create COMPLETED IEN in Profile1
            reduivy__Individual_Enrollment__c completedIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_COMPLETED',
                student.Id, sof.Id, IEN_COMPLETED_PASS_STATUS, 1, System.today(),
                null, null, null, 3, null, ipfMap.get('Profile1').Id, true
            );
            completedIen.reduivy__Grade_Result__c = 'Pass';
            insert completedIen;

            // Step 2: Create IN PROGRESS IEN in Profile2 
            reduivy__Individual_Enrollment__c inProgressIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_INPROGRESS',
                student.Id, sof.Id, IEN_INPROGRESS_STATUS, 1, System.today(),
                null, null, null, null, null, ipfMap.get('Profile2').Id, true
            );
            insert inProgressIen;

            Id inProgressIenId = inProgressIen.Id;

            // Step 3: Create IPE in Profile2 which triggers IPS creation
            // This should NOT update the In Progress IEN to Completed
            reduivy__Individual_Program_Enrollment__c ipe2 = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.Id + '_' + studyPlan.Id + '_Profile2',
                student.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, academicTerm.Id, null, null, null, null, true,
                IPE_INPROGRESS_STATUS,
                ipfMap.get('Profile2').Id
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{ipe2});

            unmuteTriggers();

            // Verify the In Progress IEN was NOT automatically updated
            reduivy__Individual_Enrollment__c inProgressIenAfter = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Grade_Result__c,
                    reduivy__Credit_Transfer_Type__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :inProgressIenId
            ];

            System.Assert.areEqual(inProgressIenId, inProgressIenAfter.Id,
                'Should be the same In Progress IEN');
            System.Assert.areEqual(IEN_INPROGRESS_STATUS, inProgressIenAfter.reduivy__Enrollment_Status__c,
                'In Progress IEN should remain In Progress (not updated to Completed)');
            System.Assert.isTrue(
                String.isBlank(inProgressIenAfter.reduivy__Grade_Result__c),
                'In Progress IEN should NOT have grade populated from completed IEN');
            System.Assert.isTrue(
                String.isBlank(inProgressIenAfter.reduivy__Credit_Transfer_Type__c) ||
                inProgressIenAfter.reduivy__Credit_Transfer_Type__c != IEN_Helper.CREDIT_TRANSFER_TYPE_AUTO_UNIT_RECOGNITION,
                'In Progress IEN should NOT have Auto Unit Recognition transfer type'
            );

            // Verify total count - should have completed in P1 and in-progress in P2 (no clone)
            Integer totalCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :student.Id
                AND reduivy__Target_Unit_Id__c = :requiredUnit.reduivy__Study_Unit__c
            ];

            System.Assert.areEqual(2, totalCount,
                'Should have 2 IENs total (completed in P1 + in-progress in P2, no clone created)');
        }

        Test.stopTest();
    }
}