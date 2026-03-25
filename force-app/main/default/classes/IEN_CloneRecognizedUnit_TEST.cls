/**
 * @author      WDCi (XiRouh)
 * @date        Jan 2026
 * @group       Test
 * @description Test class for IEN_CloneRecognizedUnit_EXE
 * @changehistory
 * ISS-002513 16-01-2026 XiRouh - new class
 */
@isTest
public inherited sharing class IEN_CloneRecognizedUnit_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
    static final String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);
    static final String IEN_OPEN_STATUS = IEN_Helper.getOpenStatuses().get(0);

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

            Test.stopTest();
        }
    }

    /**
     * @description Test auto unit recognition cloning with single IPF - should clone to other IPF as admin
     */
    @IsTest
    static void testAutoUnitRecognitionWithSingleIpfAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        Contact student = studentContacts[0];

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

        //Get study plans with structure
        reduivy__Study_Plan__c studyPlan1 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];

        //Get study unit from structure (BUS102 is in both study plans)
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        //Update study programs to have "All Academic Profiles" scope
        List<reduivy__Study_Program__c> programsToUpdate = [
            SELECT Id, reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];

        for(reduivy__Study_Program__c prog : programsToUpdate) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programsToUpdate;

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        // Create TWO individual academic profiles for the same student
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

        insert newIpfMap.values();

        // Create individual program enrollments - one for each profile
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE1',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE1',
                student.Id,
                studyPlan1.reduivy__Study_Program__c,
                studyPlan1.Id,
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

        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE2',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE2',
                student.Id,
                studyPlan2.reduivy__Study_Program__c,
                studyPlan2.Id,
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

        insert newIpeMap.values();

        System.runAs(ADMIN_USER) {

            //Create individual enrollment for Profile1 with recognizable status/grade
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                student.Id,
                sof.Id,
                'Completed',
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

            ien.reduivy__Grade_Result__c = 'Pass';

            insert ien;
        }

        //Verify cloned IEN was created for Profile2
        List<reduivy__Individual_Enrollment__c> allIens = [
            SELECT Id,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Credit_Transfer_Type__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Enrollment_Status__c,
            reduivy__Grade_Result__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :student.Id
            AND reduivy__Target_Unit_Id__c = :studyUnit.Id
        ];

        System.Assert.areEqual(2, allIens.size(), 'Should have 2 IENs - original and cloned');

        reduivy__Individual_Enrollment__c originalIen;
        reduivy__Individual_Enrollment__c clonedIen;

        for(reduivy__Individual_Enrollment__c ien : allIens) {
            if(ien.reduivy__Individual_Academic_Profile__c == newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile1').Id) {
                originalIen = ien;
            } else {
                clonedIen = ien;
            }
        }

        System.Assert.isNotNull(originalIen, 'Original IEN should exist');
        System.Assert.isNotNull(clonedIen, 'Cloned IEN should exist');
        System.Assert.areEqual(
            newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile2').Id,
            clonedIen.reduivy__Individual_Academic_Profile__c,
            'Cloned IEN should be linked to Profile2'
        );
        System.Assert.areEqual(
            IEN_Helper.CREDIT_TRANSFER_TYPE_AUTO_UNIT_RECOGNITION,
            clonedIen.reduivy__Credit_Transfer_Type__c,
            'Cloned IEN should have Auto Unit Recognition credit transfer type'
        );

        Test.stopTest();
    }

    /**
     * @description Test that unit NOT in target study plan should not clone as admin
     */
    @IsTest
    static void testUnitNotInTargetStudyPlanShouldNotCloneAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        Contact student = studentContacts[0];

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

        //Get study plans
        reduivy__Study_Plan__c studyPlan1 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorB'
            LIMIT 1
        ];

        //Get study unit that exists ONLY in studyPlan1 (BUS102 is only in MajorA, not in MinorA)
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        //Verify unit is only in studyPlan1
        List<reduivy__Study_Plan_Structure__c> plan2Structure = [
            SELECT Id
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan2.Id
            AND reduivy__Study_Unit__c = :studyUnit.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
        ];

        System.Assert.isTrue(plan2Structure.isEmpty(), 'BUS102 should NOT be in studyPlan2');

        //Update study programs to have "All Academic Profiles" scope
        List<reduivy__Study_Program__c> programsToUpdate = [
            SELECT Id, reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];

        for(reduivy__Study_Program__c prog : programsToUpdate) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programsToUpdate;

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        // Create TWO individual academic profiles
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

        insert newIpfMap.values();

        // Create IPEs
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE1',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE1',
                student.Id,
                studyPlan1.reduivy__Study_Program__c,
                studyPlan1.Id,
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

        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE2',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE2',
                student.Id,
                studyPlan2.reduivy__Study_Program__c,
                studyPlan2.Id,
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

        insert newIpeMap.values();

        System.runAs(ADMIN_USER) {

            //Create IEN for Profile1 with unit that's NOT in Profile2's study plan
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                student.Id,
                sof.Id,
                'Completed',
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

            ien.reduivy__Grade_Result__c = 'Pass';

            insert ien;
        }

        //Verify NO cloned IEN was created for Profile2
        List<reduivy__Individual_Enrollment__c> allIens = [
            SELECT Id,
            reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :student.Id
            AND reduivy__Target_Unit_Id__c = :studyUnit.Id
        ];

        System.Assert.areEqual(1, allIens.size(), 'Should have only 1 IEN - no cloning should occur');
        System.Assert.areEqual(
            newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile1').Id,
            allIens[0].reduivy__Individual_Academic_Profile__c,
            'Only IEN should be the original one'
        );

        Test.stopTest();
    }

    /**
     * @description Test mixed recognition scopes should add error as admin
     */
    @IsTest
    static void testMixedRecognitionScopesShouldAddErrorAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        Contact student = studentContacts[0];

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

        reduivy__Study_Program__c spg = [SELECT Id, reduivy__Educational_Institution__c, Name, reduivy__Academic_Level__c, reduivy__Program_Code__c, reduivy__Auto_Unit_Recognition_Scope__c FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS'];
        spg.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;

        update spg;

        reduivy__Study_Program__c newSpg = spg.clone(false, true, false, false);

        newSpg.Name = spg.Name + ' - Copy';
        newSpg.reduivy__Program_Code__c = 'NEWCODE';
        newSpg.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_NONE;

        insert newSpg;

        //Get study plans
        List<reduivy__Study_Plan__c> studyPlans = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c IN ('BACBIS_MajorA', 'BACBIS_MinorA')
            ORDER BY reduivy__Sample_Record_Code__c
        ];

        reduivy__Study_Plan__c studyPlan1 = studyPlans[0];
        reduivy__Study_Plan__c studyPlan2 = studyPlans[1];

        studyPlan2.reduivy__Study_Program__c = newSpg.Id;
        update studyPlan2;

        //Get study unit
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        // Create TWO profiles for the same student
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

        insert newIpfMap.values();

        // Create TWO IPEs for Profile2 with DIFFERENT scopes
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE1',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE1',
                student.Id,
                spg.Id,
                studyPlan1.Id,
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

        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE2',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE2',
                student.Id,
                newSpg.Id,
                studyPlan2.Id,
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

        // Create IPE for Profile1
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE3',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE3',
                student.Id,
                spg.Id,
                studyPlan1.Id,
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

        insert newIpeMap.values();

        System.runAs(ADMIN_USER) {

            //Create IEN for Profile1 - should error when trying to clone to Profile2 (mixed scopes)
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                student.Id,
                sof.Id,
                'Completed',
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

            ien.reduivy__Grade_Result__c = 'Pass';

            try {
                insert ien;
                System.Assert.fail('Should have thrown error for mixed scopes');
            } catch(DmlException e) {
                String spgAutoUnitRecognitionScopeFieldLabel = Schema.SObjectType.reduivy__Study_Program__c.fields.reduivy__Auto_Unit_Recognition_Scope__c.getLabel();

                System.Assert.isTrue(
                    e.getMessage().contains((String.format(Label.Mixture_Of_Recognition_Scope_Found, new List<String>{SPG_Helper.getObjectPluralLabel(), spgAutoUnitRecognitionScopeFieldLabel, IPF_Helper.getObjectLabel()}))),
                    'Error message should indicate mixed scopes: ' + e.getMessage()
                );
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test scope None should not clone as admin
     */
    @IsTest
    static void testScopeNoneShouldNotCloneAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        Contact student = studentContacts[0];

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

        //Get study plans
        reduivy__Study_Plan__c studyPlan1 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];

        //Get study unit
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        //Update BOTH study programs to have "None" scope
        List<reduivy__Study_Program__c> programsToUpdate = [
            SELECT Id, reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];

        for(reduivy__Study_Program__c prog : programsToUpdate) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_NONE;
        }
        update programsToUpdate;

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        // Create TWO profiles
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

        insert newIpfMap.values();

        // Create IPEs
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE1',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE1',
                student.Id,
                studyPlan1.reduivy__Study_Program__c,
                studyPlan1.Id,
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

        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE2',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE2',
                student.Id,
                studyPlan2.reduivy__Study_Program__c,
                studyPlan2.Id,
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

        insert newIpeMap.values();

        System.runAs(ADMIN_USER) {

            //Create IEN - should NOT clone because scope is None
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                student.Id,
                sof.Id,
                'Completed',
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

            ien.reduivy__Grade_Result__c = 'Pass';

            insert ien;
        }

        //Verify NO cloning occurred
        List<reduivy__Individual_Enrollment__c> allIens = [
            SELECT Id,
            reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :student.Id
            AND reduivy__Target_Unit_Id__c = :studyUnit.Id
        ];

        System.Assert.areEqual(1, allIens.size(), 'Should have only 1 IEN - no cloning with None scope');

        Test.stopTest();
    }

    /**
     * @description Test update to recognizable status should trigger cloning as admin
     */
    @IsTest
    static void testUpdateToRecognizableStatusShouldTriggerCloningAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        Contact student = studentContacts[0];

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

        //Get study plans
        reduivy__Study_Plan__c studyPlan1 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];

        //Get study unit
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        //Update study programs
        List<reduivy__Study_Program__c> programsToUpdate = [
            SELECT Id, reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];

        for(reduivy__Study_Program__c prog : programsToUpdate) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programsToUpdate;

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        // Create profiles
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

        insert newIpfMap.values();

        // Create IPEs
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE1',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE1',
                student.Id,
                studyPlan1.reduivy__Study_Program__c,
                studyPlan1.Id,
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

        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE2',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE2',
                student.Id,
                studyPlan2.reduivy__Study_Program__c,
                studyPlan2.Id,
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

        insert newIpeMap.values();

        reduivy__Individual_Enrollment__c ien;

        System.runAs(ADMIN_USER) {
            //Create IEN with NON-recognizable status
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                student.Id,
                sof.Id,
                IEN_INPROGRESS_STATUS, // Non-recognizable
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

            insert ien;

            //Verify no cloning yet
            Integer countBefore = [
                SELECT COUNT()
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :student.Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
            ];
            System.Assert.areEqual(1, countBefore, 'Should have only 1 IEN before update');

            //Update to recognizable status
            ien.reduivy__Enrollment_Status__c = 'Completed';
            ien.reduivy__Grade_Result__c = 'Pass';
            update ien;
        }

        //Verify cloning occurred after update
        List<reduivy__Individual_Enrollment__c> allIens = [
            SELECT Id,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Credit_Transfer_Type__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :student.Id
            AND reduivy__Target_Unit_Id__c = :studyUnit.Id
        ];

        System.Assert.areEqual(2, allIens.size(), 'Should have 2 IENs after update to recognizable status');

        Test.stopTest();
    }

    /**
     * @description Test bulk cloning with multiple students and profiles as admin
     */
    @IsTest
    static void testBulkCloningWithMultipleStudentsAsAdmin(){
        
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

        //Get study plans
        reduivy__Study_Plan__c studyPlan1 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];

        //Get study unit
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        //Update study programs
        List<reduivy__Study_Program__c> programsToUpdate = [
            SELECT Id, reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];

        for(reduivy__Study_Program__c prog : programsToUpdate) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programsToUpdate;

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        List<reduivy__Individual_Program_Enrollment__c> newIpeList = new List<reduivy__Individual_Program_Enrollment__c>();

        // Create profiles and IPEs for ALL students
        for(Contact student : studentContacts) {
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

        for(Contact student : studentContacts) {
            newIpeList.add(
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE1',
                    student.Id,
                    studyPlan1.reduivy__Study_Program__c,
                    studyPlan1.Id,
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
                    studyPlan2.reduivy__Study_Program__c,
                    studyPlan2.Id,
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

        insert newIpeList;

        System.runAs(ADMIN_USER) {
            //Create IENs for ALL students
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            List<reduivy__Individual_Enrollment__c> iensToInsert = new List<reduivy__Individual_Enrollment__c>();

            for(Contact student : studentContacts) {
                reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    student.Id,
                    sof.Id,
                    'Completed',
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

                ien.reduivy__Grade_Result__c = 'Pass';

                iensToInsert.add(ien);
            }

            insert iensToInsert;
        }

        //Verify cloning for ALL students
        Map<Id, List<reduivy__Individual_Enrollment__c>> studentToIens = new Map<Id, List<reduivy__Individual_Enrollment__c>>();

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id,
            reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Credit_Transfer_Type__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN :studentContacts
            AND reduivy__Target_Unit_Id__c = :studyUnit.Id
        ]) {
            if(!studentToIens.containsKey(ien.reduivy__Contact__c)) {
                studentToIens.put(ien.reduivy__Contact__c, new List<reduivy__Individual_Enrollment__c>());
            }
            studentToIens.get(ien.reduivy__Contact__c).add(ien);
        }

        System.Assert.areEqual(studentContacts.size(), studentToIens.size(), 'Should have IENs for all students');

        for(Contact student : studentContacts) {
            List<reduivy__Individual_Enrollment__c> studentIens = studentToIens.get(student.Id);
            System.Assert.areEqual(2, studentIens.size(), 'Each student should have 2 IENs (original + cloned)');
        }

        Test.stopTest();
    }

    /**
     * @description Test that duplicate clones are not created as admin
     */
    @IsTest
    static void testNoDuplicateClonesCreatedAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        Contact student = studentContacts[0];

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

        //Get study plans
        reduivy__Study_Plan__c studyPlan1 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];

        //Get study unit
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        //Update study programs
        List<reduivy__Study_Program__c> programsToUpdate = [
            SELECT Id, reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];

        for(reduivy__Study_Program__c prog : programsToUpdate) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programsToUpdate;

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        // Create profiles
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

        insert newIpfMap.values();

        // Create IPEs
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE1',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE1',
                student.Id,
                studyPlan1.reduivy__Study_Program__c,
                studyPlan1.Id,
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

        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE2',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE2',
                student.Id,
                studyPlan2.reduivy__Study_Program__c,
                studyPlan2.Id,
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

        insert newIpeMap.values();

        reduivy__Individual_Enrollment__c ien1;
        reduivy__Individual_Enrollment__c ien2;

        System.runAs(ADMIN_USER) {

            //Create first IEN - should trigger cloning
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_1',
                student.Id,
                sof.Id,
                'Completed',
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

            ien1.reduivy__Grade_Result__c = 'Pass';

            insert ien1;

            //Verify 2 IENs exist
            Integer countAfterFirst = [
                SELECT COUNT()
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :student.Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
            ];
            System.Assert.areEqual(2, countAfterFirst, 'Should have 2 IENs after first insert');

            //Create second IEN with same criteria - should NOT create duplicate clone
            ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_2',
                student.Id,
                sof.Id,
                'Completed',
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

            ien2.reduivy__Grade_Result__c = 'Pass';

            insert ien2;
        }

        //Verify still only 2 IENs total (not 4)
        Integer finalCount = [
            SELECT COUNT()
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :student.Id
            AND reduivy__Target_Unit_Id__c = :studyUnit.Id
        ];

        System.Assert.areEqual(3, finalCount, 'Should have 3 IENs total - 2 originals and 1 clone (no duplicates)');

        Test.stopTest();
    }

    /**
     * @description Test that existing Open status IEN is updated instead of creating new one as admin
     */
    @IsTest
    static void testExistingOpenIenIsUpdatedNotInsertedAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        Contact student = studentContacts[0];

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan1 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA' LIMIT 1
        ];

        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102' LIMIT 1
        ];

        // Enable auto unit recognition
        List<reduivy__Study_Program__c> programsToUpdate = [
            SELECT Id, reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];

        for(reduivy__Study_Program__c prog : programsToUpdate) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programsToUpdate;

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

        // Create IPEs
        List<reduivy__Individual_Program_Enrollment__c> ipes = new List<reduivy__Individual_Program_Enrollment__c>();
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.reduivy__Sample_Record_Code__c + '_IPE1', student.Id,
            studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('Profile1').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.reduivy__Sample_Record_Code__c + '_IPE2', student.Id,
            studyPlan2.reduivy__Study_Program__c, studyPlan2.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('Profile2').Id
        ));
        insert ipes;

        System.runAs(ADMIN_USER) {
            String openStatus = IEN_Helper.getOpenStatuses().get(0);
            
            // Create existing Open IEN in Profile2
            reduivy__Individual_Enrollment__c existingOpenIen = new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = student.Id,
                reduivy__Study_Unit__c = studyUnit.Id,
                reduivy__Individual_Academic_Profile__c = ipfMap.get('Profile2').Id,
                reduivy__Enrollment_Status__c = openStatus,
                reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
                RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
                reduivy__Bypass_Requirement_Met__c = true
            );
            insert existingOpenIen;

            Id existingOpenIenId = existingOpenIen.Id;

            // Create recognizable IEN in Profile1 - should UPDATE existing Open IEN
            reduivy__Study_Offering__c sof = [SELECT Id FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c = :academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id LIMIT 1
            ];

            reduivy__Individual_Enrollment__c sourceIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.Id,
                student.Id, sof.Id, 'Completed', 1, System.today(),
                null, null, null, 3, null, ipfMap.get('Profile1').Id, true
            );
            sourceIen.reduivy__Grade_Result__c = 'Pass';
            insert sourceIen;

            // Verify IEN count - should be 2 total (source + updated Open IEN)
            List<reduivy__Individual_Enrollment__c> allIens = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Academic_Profile__c,
                    reduivy__Credit_Transfer_Type__c, reduivy__Grade_Result__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :student.Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
                ORDER BY CreatedDate
            ];

            System.Assert.areEqual(2, allIens.size(), 'Should have exactly 2 IENs (source + updated Open)');
            
            // Verify the Open IEN was UPDATED, not inserted new
            reduivy__Individual_Enrollment__c updatedIen = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Credit_Transfer_Type__c, 
                    reduivy__Grade_Result__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :existingOpenIenId
            ];

            System.Assert.areEqual(existingOpenIenId, updatedIen.Id, 
                'Should be same IEN record (updated, not new)');
            System.Assert.areEqual('Completed', updatedIen.reduivy__Enrollment_Status__c,
                'Open IEN should be updated to Completed status');
            System.Assert.areEqual('Pass', updatedIen.reduivy__Grade_Result__c,
                'Open IEN should have cloned grade result');
            System.Assert.areEqual(IEN_Helper.CREDIT_TRANSFER_TYPE_AUTO_UNIT_RECOGNITION,
                updatedIen.reduivy__Credit_Transfer_Type__c,
                'Should have Auto Unit Recognition transfer type');
        }

        Test.stopTest();
    }

    /**
     * @description Test that Open IEN prevents new IEN creation even with multiple triggers as admin
     */
    @IsTest
    static void testOpenIenPreventsMultipleClonesAsAdmin(){
        
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

        reduivy__Study_Plan__c studyPlan1 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA' LIMIT 1
        ];

        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102' LIMIT 1
        ];

        List<reduivy__Study_Program__c> programs = [
            SELECT Id FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];
        for(reduivy__Study_Program__c prog : programs) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programs;

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        ipfMap.put('P1', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P1', student.Id, 'P1', IPF_Helper.STATUS_ACTIVE, true
        ));
        ipfMap.put('P2', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P2', student.Id, 'P2', IPF_Helper.STATUS_ACTIVE, false
        ));
        insert ipfMap.values();

        List<reduivy__Individual_Program_Enrollment__c> ipes = new List<reduivy__Individual_Program_Enrollment__c>();
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE1', student.Id, studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P1').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE2', student.Id, studyPlan2.reduivy__Study_Program__c, studyPlan2.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P2').Id
        ));
        insert ipes;

        System.runAs(ADMIN_USER) {
            // Create Open IEN in Profile2
            String openStatus = IEN_Helper.getOpenStatuses().get(0);
            reduivy__Individual_Enrollment__c openIen = new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = student.Id,
                reduivy__Study_Unit__c = studyUnit.Id,
                reduivy__Individual_Academic_Profile__c = ipfMap.get('P2').Id,
                reduivy__Enrollment_Status__c = openStatus,
                reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
                RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
                reduivy__Bypass_Requirement_Met__c = true
            );
            insert openIen;

            reduivy__Study_Offering__c sof = [SELECT Id FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c = :academicTerm.Id 
                AND reduivy__Study_Unit__c = :studyUnit.Id LIMIT 1
            ];

            // Create TWO recognizable IENs in Profile1
            List<reduivy__Individual_Enrollment__c> sourceIens = new List<reduivy__Individual_Enrollment__c>();
            for(Integer i = 0; i < 2; i++) {
                reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.Id + '_' + sof.Id + '_' + i, student.Id, sof.Id,
                    'Completed', 1, System.today(), null, null, null, 3, null,
                    ipfMap.get('P1').Id, true
                );
                ien.reduivy__Grade_Result__c = 'Pass';
                sourceIens.add(ien);
            }
            insert sourceIens;

            // Verify still only ONE IEN in Profile2 (the updated Open IEN)
            Integer profile2Count = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('P2').Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
            ];

            System.Assert.areEqual(1, profile2Count,
                'Should have only 1 IEN in Profile2 despite multiple triggers');
        }

        Test.stopTest();
    }

    /**
     * @description Test non-enrollable IEN prevents cloning (no Open IEN exists) as admin
     */
    @IsTest
    static void testNonEnrollableIenPreventsCloningAsAdmin(){
        
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

        reduivy__Study_Plan__c studyPlan1 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA' LIMIT 1
        ];

        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102' LIMIT 1
        ];

        List<reduivy__Study_Program__c> programs = [SELECT Id FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];
        for(reduivy__Study_Program__c prog : programs) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programs;

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        ipfMap.put('P1', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P1', student.Id, 'P1', IPF_Helper.STATUS_ACTIVE, true
        ));
        ipfMap.put('P2', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P2', student.Id, 'P2', IPF_Helper.STATUS_ACTIVE, false
        ));
        insert ipfMap.values();

        List<reduivy__Individual_Program_Enrollment__c> ipes = new List<reduivy__Individual_Program_Enrollment__c>();
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE1', student.Id, studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P1').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE2', student.Id, studyPlan2.reduivy__Study_Program__c, studyPlan2.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P2').Id
        ));
        insert ipes;

        System.runAs(ADMIN_USER) {
            reduivy__Study_Offering__c sof = [SELECT Id FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c = :academicTerm.Id 
                AND reduivy__Study_Unit__c = :studyUnit.Id LIMIT 1
            ];

            // Create In progress IEN in Profile2 (non-enrollable)
            reduivy__Individual_Enrollment__c failedIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.Id + '_FAILED', student.Id, sof.Id, IEN_INPROGRESS_STATUS,
                1, System.today(), null, null, null, 3, null,
                ipfMap.get('P2').Id, true
            );
            insert failedIen;

            Integer initialCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('P2').Id
            ];

            // Create recognizable IEN in Profile1
            reduivy__Individual_Enrollment__c sourceIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.Id + '_PASS', student.Id, sof.Id, 'Completed',
                1, System.today(), null, null, null, 3, null,
                ipfMap.get('P1').Id, true
            );
            sourceIen.reduivy__Grade_Result__c = 'Pass';
            insert sourceIen;

            Integer finalCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('P2').Id
            ];

            System.Assert.areEqual(initialCount, finalCount,
                'No new IEN should be created when non-enrollable IEN exists');
        }

        Test.stopTest();
    }

    /**
     * @description Test credit transfer IENs should not trigger cloning as admin
     */
    @IsTest
    static void testCreditTransferIenDoesNotTriggerCloningAsAdmin(){
        
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

        reduivy__Study_Plan__c studyPlan1 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA' LIMIT 1
        ];

        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102' LIMIT 1
        ];

        List<reduivy__Study_Program__c> programs = [SELECT Id FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];
        for(reduivy__Study_Program__c prog : programs) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programs;

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        ipfMap.put('P1', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P1', student.Id, 'P1', IPF_Helper.STATUS_ACTIVE, true
        ));
        ipfMap.put('P2', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P2', student.Id, 'P2', IPF_Helper.STATUS_ACTIVE, false
        ));
        insert ipfMap.values();

        List<reduivy__Individual_Program_Enrollment__c> ipes = new List<reduivy__Individual_Program_Enrollment__c>();
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE1', student.Id, studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P1').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE2', student.Id, studyPlan2.reduivy__Study_Program__c, studyPlan2.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P2').Id
        ));
        insert ipes;

        System.runAs(ADMIN_USER) {
            reduivy__Study_Offering__c sof = [SELECT Id FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c = :academicTerm.Id 
                AND reduivy__Study_Unit__c = :studyUnit.Id LIMIT 1
            ];

            // Create IEN with credit transfer flag = TRUE
            reduivy__Individual_Enrollment__c creditTransferIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.Id + '_CT', student.Id, sof.Id, 'Completed',
                1, System.today(), null, null, null, 3, null,
                ipfMap.get('P1').Id, true
            );
            creditTransferIen.reduivy__Grade_Result__c = 'Pass';
            creditTransferIen.reduivy__Credit_Transfer_Received__c = true; // CREDIT TRANSFER
            insert creditTransferIen;

            // Verify NO cloning occurred
            Integer profile2Count = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('P2').Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
            ];

            System.Assert.areEqual(0, profile2Count,
                'Credit transfer IEN should NOT trigger cloning');
        }

        Test.stopTest();
    }

    /**
     * @description Test changing IPF should trigger cloning to new IPF as admin
     */
    @IsTest
    static void testChangingIpfTriggersReCloningAsAdmin(){
        
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

        reduivy__Study_Plan__c studyPlan1 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA' LIMIT 1
        ];

        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102' LIMIT 1
        ];

        List<reduivy__Study_Program__c> programs = [SELECT Id FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];
        for(reduivy__Study_Program__c prog : programs) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programs;

        // Create THREE IPFs
        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        ipfMap.put('P1', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P1', student.Id, 'P1', IPF_Helper.STATUS_ACTIVE, true
        ));
        ipfMap.put('P2', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P2', student.Id, 'P2', IPF_Helper.STATUS_ACTIVE, false
        ));
        ipfMap.put('P3', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P3', student.Id, 'P3', IPF_Helper.STATUS_ACTIVE, false
        ));
        insert ipfMap.values();

        List<reduivy__Individual_Program_Enrollment__c> ipes = new List<reduivy__Individual_Program_Enrollment__c>();
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE1', student.Id, studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P1').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE2', student.Id, studyPlan2.reduivy__Study_Program__c, studyPlan2.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P2').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE3', student.Id, studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P3').Id
        ));
        insert ipes;

        reduivy__Individual_Enrollment__c recognizableIen;

        System.runAs(ADMIN_USER) {
            reduivy__Study_Offering__c sof = [SELECT Id FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c = :academicTerm.Id 
                AND reduivy__Study_Unit__c = :studyUnit.Id LIMIT 1
            ];

            // Create recognizable IEN in P1
            recognizableIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.Id + '_RECON', student.Id, sof.Id, 'Completed',
                1, System.today(), null, null, null, 3, null,
                ipfMap.get('P1').Id, true
            );
            recognizableIen.reduivy__Grade_Result__c = 'Pass';
            insert recognizableIen;

            // Verify clones in P2 and P3
            Integer totalClones = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :student.Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
                AND reduivy__Individual_Academic_Profile__c IN (:ipfMap.get('P2').Id, :ipfMap.get('P3').Id)
            ];
            System.Assert.areEqual(2, totalClones, 'Should have cloned to P2 and P3');

            // Move recognizable IEN from P1 to P2
            recognizableIen.reduivy__Individual_Academic_Profile__c = ipfMap.get('P2').Id;
            update recognizableIen;
        }

        // Verify new clone created in P1 (since recognizable moved to P2)
        Integer p1Count = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('P1').Id
            AND reduivy__Target_Unit_Id__c = :studyUnit.Id
        ];

        System.Assert.areEqual(1, p1Count,
            'Should have new clone in P1 after source moved to P2');

        Test.stopTest();
    }

    /**
     * @description Test changing study unit should trigger cloning to new unit as admin
     */
    @IsTest
    static void testChangingStudyUnitTriggersReCloningAsAdmin(){
        
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

        reduivy__Study_Plan__c studyPlan1 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA' LIMIT 1
        ];

        List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c IN ('BUS102', 'BUS103')
            ORDER BY reduivy__Sample_Record_Code__c
        ];

        List<reduivy__Study_Program__c> programs = [SELECT Id FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];
        for(reduivy__Study_Program__c prog : programs) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programs;

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        ipfMap.put('P1', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P1', student.Id, 'P1', IPF_Helper.STATUS_ACTIVE, true
        ));
        ipfMap.put('P2', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P2', student.Id, 'P2', IPF_Helper.STATUS_ACTIVE, false
        ));
        insert ipfMap.values();

        List<reduivy__Individual_Program_Enrollment__c> ipes = new List<reduivy__Individual_Program_Enrollment__c>();
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE1', student.Id, studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P1').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE2', student.Id, studyPlan2.reduivy__Study_Program__c, studyPlan2.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P2').Id
        ));
        insert ipes;

        reduivy__Individual_Enrollment__c recognizableIen;

        System.runAs(ADMIN_USER) {
            List<reduivy__Study_Offering__c> sofs = [SELECT Id, reduivy__Study_Unit__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c = :academicTerm.Id 
                AND reduivy__Study_Unit__c IN :studyUnits
                ORDER BY reduivy__Study_Unit__c
            ];

            // Create recognizable IEN for BUS102
            recognizableIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.Id + '_RECON', student.Id, sofs[0].Id, 'Completed',
                1, System.today(), null, null, null, 3, null,
                ipfMap.get('P1').Id, true
            );
            recognizableIen.reduivy__Grade_Result__c = 'Pass';
            insert recognizableIen;

            Integer initialP2Count = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('P2').Id
            ];

            // Change study unit from BUS102 to BUS103
            recognizableIen.reduivy__Study_Unit__c = studyUnits[1].Id;
            recognizableIen.reduivy__Study_Offering__c = sofs[1].Id;
            update recognizableIen;

            Integer finalP2Count = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('P2').Id
            ];

            System.Assert.areEqual(initialP2Count + 1, finalP2Count,
                'Should create new clone for new study unit');
        }

        Test.stopTest();
    }

    /**
     * @description Test multiple Open IENs scenario - all should be updated as admin
     */
    @IsTest
    static void testMultipleOpenIensUpdatedAsAdmin(){
        
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

        reduivy__Study_Plan__c studyPlan1 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA' LIMIT 1
        ];

        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102' LIMIT 1
        ];

        List<reduivy__Study_Program__c> programs = [SELECT Id FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];
        for(reduivy__Study_Program__c prog : programs) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programs;

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        ipfMap.put('P1', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P1', student.Id, 'P1', IPF_Helper.STATUS_ACTIVE, true
        ));
        ipfMap.put('P2', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P2', student.Id, 'P2', IPF_Helper.STATUS_ACTIVE, false
        ));
        insert ipfMap.values();

        List<reduivy__Individual_Program_Enrollment__c> ipes = new List<reduivy__Individual_Program_Enrollment__c>();
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE1', student.Id, studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P1').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE2', student.Id, studyPlan2.reduivy__Study_Program__c, studyPlan2.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P2').Id
        ));
        insert ipes;

        System.runAs(ADMIN_USER) {
            String openStatus = IEN_Helper.getOpenStatuses().get(0);
            
            // Create MULTIPLE Open IENs for same IPF+Unit (edge case - shouldn't happen but test it)
            List<reduivy__Individual_Enrollment__c> openIens = new List<reduivy__Individual_Enrollment__c>();
            for(Integer i = 0; i < 5; i++) {
                openIens.add(new reduivy__Individual_Enrollment__c(
                    reduivy__Contact__c = student.Id,
                    reduivy__Study_Unit__c = studyUnit.Id,
                    reduivy__Individual_Academic_Profile__c = ipfMap.get('P2').Id,
                    reduivy__Enrollment_Status__c = openStatus,
                    reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
                    RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
                    reduivy__Bypass_Requirement_Met__c = true
                ));
            }
            insert openIens;

            reduivy__Study_Offering__c sof = [SELECT Id FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c = :academicTerm.Id 
                AND reduivy__Study_Unit__c = :studyUnit.Id LIMIT 1
            ];

            // Create recognizable IEN
            reduivy__Individual_Enrollment__c sourceIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.Id + '_SOURCE', student.Id, sof.Id, 'Completed',
                1, System.today(), null, null, null, 3, null,
                ipfMap.get('P1').Id, true
            );
            sourceIen.reduivy__Grade_Result__c = 'Pass';
            insert sourceIen;

            // Verify only ONE Open IEN was updated (not both)
            Integer updatedCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('P2').Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
                AND reduivy__Enrollment_Status__c = 'Completed'
            ];

            System.Assert.areEqual(5, updatedCount,
                'All open IEN should be updated to Completed');
        }

        Test.stopTest();
    }

    /**
     * @description Test bulk cloning with multiple students and different units as admin
     */
    @IsTest
    static void testBulkCloningWithMultipleStudentsAndDifferentUnitsAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        List<Contact> studentContacts = [
            SELECT Id, reduivy__Sample_Record_Code__c
            FROM Contact
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c != null
            LIMIT 3
        ];
        System.assertEquals(3, studentContacts.size(), 'Need at least 3 students for this test');

        // Current academic term
        reduivy__Study_Term__c academicTerm = [
            SELECT Id, reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId()
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        // Institution + campus (Accounts)
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

        // Study program
        reduivy__Study_Program__c studyProgram = [
            SELECT Id
            FROM reduivy__Study_Program__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS'
            LIMIT 1
        ];

        studyProgram.reduivy__Auto_Unit_Recognition_Scope__c =
            SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        update studyProgram;

        // Study Units
        Map<String, reduivy__Study_Unit__c> unitMap = new Map<String, reduivy__Study_Unit__c>();
        List<reduivy__Study_Unit__c> testUnits = new List<reduivy__Study_Unit__c>{
            new reduivy__Study_Unit__c(
                Name = 'TEST101 - Test Unit',
                reduivy__Sample_Record_Code__c = 'TEST101',
                reduivy__Unit_Code__c = 'TEST101'
            ),
            new reduivy__Study_Unit__c(
                Name = 'TEST201 - Test Unit',
                reduivy__Sample_Record_Code__c = 'TEST201',
                reduivy__Unit_Code__c = 'TEST201'
            ),
            new reduivy__Study_Unit__c(
                Name = 'TEST301 - Test Unit',
                reduivy__Sample_Record_Code__c = 'TEST301',
                reduivy__Unit_Code__c = 'TEST301'
            )
        };
        insert testUnits;

        for(reduivy__Study_Unit__c u : testUnits) {
            unitMap.put(u.reduivy__Sample_Record_Code__c, u);
        }

        // Study Plans
        Map<String, reduivy__Study_Plan__c> studyPlanMap = new Map<String, reduivy__Study_Plan__c>();
        List<reduivy__Study_Plan__c> studyPlans = new List<reduivy__Study_Plan__c>();
        for(String nameVal : new List<String>{'Plan_A','Plan_B','Plan_C','Plan_D','Plan_E','Plan_F'}) {
            studyPlans.add(new reduivy__Study_Plan__c(
                Name = nameVal,
                reduivy__Sample_Record_Code__c = nameVal,
                reduivy__Study_Program__c = studyProgram.Id
            ));
        }
        insert studyPlans;
        for(reduivy__Study_Plan__c p : studyPlans) {
            studyPlanMap.put(p.reduivy__Sample_Record_Code__c, p);
        }

        // Study Plan Structures
        List<reduivy__Study_Plan_Structure__c> planStructures = new List<reduivy__Study_Plan_Structure__c>{
            new reduivy__Study_Plan_Structure__c(
                Name = 'Plan_A_TEST101',
                reduivy__Sample_Record_Code__c = 'Plan_A_TEST101',
                reduivy__Study_Plan__c = studyPlanMap.get('Plan_A').Id,
                reduivy__Study_Unit__c = unitMap.get('TEST101').Id,
                RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
                reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
                reduivy__Credits__c = 3
            ),
            new reduivy__Study_Plan_Structure__c(
                Name = 'Plan_B_TEST101',
                reduivy__Sample_Record_Code__c = 'Plan_B_TEST101',
                reduivy__Study_Plan__c = studyPlanMap.get('Plan_B').Id,
                reduivy__Study_Unit__c = unitMap.get('TEST101').Id,
                RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
                reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
                reduivy__Credits__c = 3
            ),
            new reduivy__Study_Plan_Structure__c(
                Name = 'Plan_C_TEST201',
                reduivy__Sample_Record_Code__c = 'Plan_C_TEST201',
                reduivy__Study_Plan__c = studyPlanMap.get('Plan_C').Id,
                reduivy__Study_Unit__c = unitMap.get('TEST201').Id,
                RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
                reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
                reduivy__Credits__c = 3
            ),
            new reduivy__Study_Plan_Structure__c(
                Name = 'Plan_D_TEST201',
                reduivy__Sample_Record_Code__c = 'Plan_D_TEST201',
                reduivy__Study_Plan__c = studyPlanMap.get('Plan_D').Id,
                reduivy__Study_Unit__c = unitMap.get('TEST201').Id,
                RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
                reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
                reduivy__Credits__c = 3
            ),
            new reduivy__Study_Plan_Structure__c(
                Name = 'Plan_E_TEST301',
                reduivy__Sample_Record_Code__c = 'Plan_E_TEST301',
                reduivy__Study_Plan__c = studyPlanMap.get('Plan_E').Id,
                reduivy__Study_Unit__c = unitMap.get('TEST301').Id,
                RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
                reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
                reduivy__Credits__c = 3
            ),
            new reduivy__Study_Plan_Structure__c(
                Name = 'Plan_F_TEST301',
                reduivy__Sample_Record_Code__c = 'Plan_F_TEST301',
                reduivy__Study_Plan__c = studyPlanMap.get('Plan_F').Id,
                reduivy__Study_Unit__c = unitMap.get('TEST301').Id,
                RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
                reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
                reduivy__Credits__c = 3
            )
        };
        insert planStructures;

        // Study Offerings
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

        // Profiles + IPEs
        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        List<reduivy__Individual_Program_Enrollment__c> newIpeList = new List<reduivy__Individual_Program_Enrollment__c>();

        Map<Id, Map<String, Id>> studentToPlanMap = new Map<Id, Map<String, Id>>();
        Map<Id, String> studentToUnitCodeMap = new Map<Id, String>();

        studentToPlanMap.put(studentContacts[0].Id, new Map<String, Id>{
            'Profile1' => studyPlanMap.get('Plan_A').Id,
            'Profile2' => studyPlanMap.get('Plan_B').Id
        });
        studentToUnitCodeMap.put(studentContacts[0].Id, 'TEST101');

        studentToPlanMap.put(studentContacts[1].Id, new Map<String, Id>{
            'Profile1' => studyPlanMap.get('Plan_C').Id,
            'Profile2' => studyPlanMap.get('Plan_D').Id
        });
        studentToUnitCodeMap.put(studentContacts[1].Id, 'TEST201');

        studentToPlanMap.put(studentContacts[2].Id, new Map<String, Id>{
            'Profile1' => studyPlanMap.get('Plan_E').Id,
            'Profile2' => studyPlanMap.get('Plan_F').Id
        });
        studentToUnitCodeMap.put(studentContacts[2].Id, 'TEST301');

        for(Contact student : studentContacts) {
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

        for(Contact student : studentContacts) {
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
        insert newIpeList;

        System.runAs(ADMIN_USER) {
            List<reduivy__Individual_Enrollment__c> iensToInsert = new List<reduivy__Individual_Enrollment__c>();

            for(Contact student : studentContacts) {
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

                reduivy__Individual_Enrollment__c ien =
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        'Completed',
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

                ien.reduivy__Grade_Result__c = 'Pass';
                iensToInsert.add(ien);
            }
            insert iensToInsert;
        }

        Map<Id, List<reduivy__Individual_Enrollment__c>> studentToIens =
            new Map<Id, List<reduivy__Individual_Enrollment__c>>();

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id,
                reduivy__Contact__c,
                reduivy__Individual_Academic_Profile__c,
                reduivy__Credit_Transfer_Type__c,
                reduivy__Target_Unit_Id__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN :studentContacts
            AND reduivy__Target_Unit_Id__c != null
            ORDER BY reduivy__Contact__c, CreatedDate
        ]) {
            if(!studentToIens.containsKey(ien.reduivy__Contact__c)) {
                studentToIens.put(ien.reduivy__Contact__c, new List<reduivy__Individual_Enrollment__c>());
            }
            studentToIens.get(ien.reduivy__Contact__c).add(ien);
        }

        System.assertEquals(studentContacts.size(), studentToIens.size(),
            'Should have IENs for all students');

        Integer studentIndex = 0;
        for(Contact student : studentContacts) {
            List<reduivy__Individual_Enrollment__c> studentIens = studentToIens.get(student.Id);
            System.assertEquals(2, studentIens.size(),
                'Student ' + (studentIndex + 1) + ' should have 2 IENs (original + cloned)');

            String expectedUnitCode = studentToUnitCodeMap.get(student.Id);
            String expectedUnitId = unitMap.get(expectedUnitCode).Id;

            for(reduivy__Individual_Enrollment__c ien : studentIens) {
                System.assertEquals(expectedUnitId, ien.reduivy__Target_Unit_Id__c,
                    'Student ' + (studentIndex + 1) + ' IEN should target unit ' + expectedUnitCode);
            }

            Set<Id> profiles = new Set<Id>();
            for(reduivy__Individual_Enrollment__c ien : studentIens) {
                profiles.add(ien.reduivy__Individual_Academic_Profile__c);
            }

            System.assert(profiles.contains(
                newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile1').Id));
            System.assert(profiles.contains(
                newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile2').Id));

            studentIndex++;
        }

        Test.stopTest();
    }

    /**
     * @description Test that existing In Progress IEN is NOT updated when completed IEN exists in another profile as admin
     */
    @IsTest
    static void testInProgressIenNotUpdatedWhenCompletedExistsAsAdmin(){
        
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

        reduivy__Study_Plan__c studyPlan1 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA' LIMIT 1
        ];

        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102' LIMIT 1
        ];

        // Enable auto unit recognition
        List<reduivy__Study_Program__c> programsToUpdate = [
            SELECT Id, reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];

        for(reduivy__Study_Program__c prog : programsToUpdate) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programsToUpdate;

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

        // Create IPEs
        List<reduivy__Individual_Program_Enrollment__c> ipes = new List<reduivy__Individual_Program_Enrollment__c>();
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.reduivy__Sample_Record_Code__c + '_IPE1', student.Id,
            studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('Profile1').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.reduivy__Sample_Record_Code__c + '_IPE2', student.Id,
            studyPlan2.reduivy__Study_Program__c, studyPlan2.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('Profile2').Id
        ));
        insert ipes;

        System.runAs(ADMIN_USER) {
            reduivy__Study_Offering__c sof = [SELECT Id FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c = :academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id LIMIT 1
            ];

            // Step 1: Create COMPLETED/RECOGNIZABLE IEN in Profile1
            reduivy__Individual_Enrollment__c completedIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_COMPLETED',
                student.Id, sof.Id, 'Completed', 1, System.today(),
                null, null, null, 3, null, ipfMap.get('Profile1').Id, true
            );
            completedIen.reduivy__Grade_Result__c = 'Pass';
            insert completedIen;

            // Verify clone was created in Profile2
            Integer profile2CountAfterCompleted = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('Profile2').Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
            ];
            
            System.Assert.areEqual(1, profile2CountAfterCompleted,
                'Should have 1 cloned IEN in Profile2 after creating completed IEN in Profile1');

            // Step 2: Create NEW IN PROGRESS IEN in Profile2
            reduivy__Individual_Enrollment__c inProgressIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_INPROGRESS',
                student.Id, sof.Id, IEN_INPROGRESS_STATUS, 1, System.today(),
                null, null, null, null, null, ipfMap.get('Profile2').Id, true
            );
            insert inProgressIen;

            Id inProgressIenId = inProgressIen.Id;

            // Verify the In Progress IEN was NOT automatically updated to Completed
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

            // Verify total count - should have completed in P1, and 1 completed and 1 new in-progress in P2
            Integer totalCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :student.Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
            ];

            System.Assert.isTrue(totalCount == 3,
                'Should have at least 3 IENs (completed in P1 + completed + in-progress in P2)');
        }

        Test.stopTest();
    }

    /**
     * @description Test auto unit recognition cloning with single IPF - should clone to other IPF as faculty
     */
    @IsTest
    static void testAutoUnitRecognitionWithSingleIpfAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        Contact student = studentContacts[0];

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

        //Get study plans with structure
        reduivy__Study_Plan__c studyPlan1 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];

        //Get study unit from structure (BUS102 is in both study plans)
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        //Update study programs to have "All Academic Profiles" scope
        List<reduivy__Study_Program__c> programsToUpdate = [
            SELECT Id, reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];

        for(reduivy__Study_Program__c prog : programsToUpdate) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programsToUpdate;

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        // Create TWO individual academic profiles for the same student
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

        insert newIpfMap.values();

        // Create individual program enrollments - one for each profile
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE1',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE1',
                student.Id,
                studyPlan1.reduivy__Study_Program__c,
                studyPlan1.Id,
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

        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE2',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE2',
                student.Id,
                studyPlan2.reduivy__Study_Program__c,
                studyPlan2.Id,
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

        insert newIpeMap.values();

        System.runAs(FACULTY_USER) {

            //Create individual enrollment for Profile1 with recognizable status/grade
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                student.Id,
                sof.Id,
                'Completed',
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

            ien.reduivy__Grade_Result__c = 'Pass';

            insert ien;
        }

        //Verify cloned IEN was created for Profile2
        List<reduivy__Individual_Enrollment__c> allIens = [
            SELECT Id,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Credit_Transfer_Type__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Enrollment_Status__c,
            reduivy__Grade_Result__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :student.Id
            AND reduivy__Target_Unit_Id__c = :studyUnit.Id
        ];

        System.Assert.areEqual(2, allIens.size(), 'Should have 2 IENs - original and cloned');

        reduivy__Individual_Enrollment__c originalIen;
        reduivy__Individual_Enrollment__c clonedIen;

        for(reduivy__Individual_Enrollment__c ien : allIens) {
            if(ien.reduivy__Individual_Academic_Profile__c == newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile1').Id) {
                originalIen = ien;
            } else {
                clonedIen = ien;
            }
        }

        System.Assert.isNotNull(originalIen, 'Original IEN should exist');
        System.Assert.isNotNull(clonedIen, 'Cloned IEN should exist');
        System.Assert.areEqual(
            newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile2').Id,
            clonedIen.reduivy__Individual_Academic_Profile__c,
            'Cloned IEN should be linked to Profile2'
        );
        System.Assert.areEqual(
            IEN_Helper.CREDIT_TRANSFER_TYPE_AUTO_UNIT_RECOGNITION,
            clonedIen.reduivy__Credit_Transfer_Type__c,
            'Cloned IEN should have Auto Unit Recognition credit transfer type'
        );

        Test.stopTest();
    }

    /**
     * @description Test that unit NOT in target study plan should not clone as faculty
     */
    @IsTest
    static void testUnitNotInTargetStudyPlanShouldNotCloneAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        Contact student = studentContacts[0];

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

        //Get study plans
        reduivy__Study_Plan__c studyPlan1 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorB'
            LIMIT 1
        ];

        //Get study unit that exists ONLY in studyPlan1 (BUS102 is only in MajorA, not in MinorA)
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        //Verify unit is only in studyPlan1
        List<reduivy__Study_Plan_Structure__c> plan2Structure = [
            SELECT Id
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan2.Id
            AND reduivy__Study_Unit__c = :studyUnit.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
        ];

        System.Assert.isTrue(plan2Structure.isEmpty(), 'BUS102 should NOT be in studyPlan2');

        //Update study programs to have "All Academic Profiles" scope
        List<reduivy__Study_Program__c> programsToUpdate = [
            SELECT Id, reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];

        for(reduivy__Study_Program__c prog : programsToUpdate) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programsToUpdate;

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        // Create TWO individual academic profiles
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

        insert newIpfMap.values();

        // Create IPEs
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE1',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE1',
                student.Id,
                studyPlan1.reduivy__Study_Program__c,
                studyPlan1.Id,
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

        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE2',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE2',
                student.Id,
                studyPlan2.reduivy__Study_Program__c,
                studyPlan2.Id,
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

        insert newIpeMap.values();

        System.runAs(FACULTY_USER) {

            //Create IEN for Profile1 with unit that's NOT in Profile2's study plan
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                student.Id,
                sof.Id,
                'Completed',
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

            ien.reduivy__Grade_Result__c = 'Pass';

            insert ien;
        }

        //Verify NO cloned IEN was created for Profile2
        List<reduivy__Individual_Enrollment__c> allIens = [
            SELECT Id,
            reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :student.Id
            AND reduivy__Target_Unit_Id__c = :studyUnit.Id
        ];

        System.Assert.areEqual(1, allIens.size(), 'Should have only 1 IEN - no cloning should occur');
        System.Assert.areEqual(
            newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile1').Id,
            allIens[0].reduivy__Individual_Academic_Profile__c,
            'Only IEN should be the original one'
        );

        Test.stopTest();
    }

    /**
     * @description Test mixed recognition scopes should add error as faculty
     */
    @IsTest
    static void testMixedRecognitionScopesShouldAddErrorAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        Contact student = studentContacts[0];

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

        reduivy__Study_Program__c spg = [SELECT Id, reduivy__Educational_Institution__c, Name, reduivy__Academic_Level__c, reduivy__Program_Code__c, reduivy__Auto_Unit_Recognition_Scope__c FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS'];
        spg.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;

        update spg;

        reduivy__Study_Program__c newSpg = spg.clone(false, true, false, false);

        newSpg.Name = spg.Name + ' - Copy';
        newSpg.reduivy__Program_Code__c = 'NEWCODE';
        newSpg.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_NONE;

        insert newSpg;

        //Get study plans
        List<reduivy__Study_Plan__c> studyPlans = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c IN ('BACBIS_MajorA', 'BACBIS_MinorA')
            ORDER BY reduivy__Sample_Record_Code__c
        ];

        reduivy__Study_Plan__c studyPlan1 = studyPlans[0];
        reduivy__Study_Plan__c studyPlan2 = studyPlans[1];

        studyPlan2.reduivy__Study_Program__c = newSpg.Id;
        update studyPlan2;

        //Get study unit
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        // Create TWO profiles for the same student
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

        insert newIpfMap.values();

        // Create TWO IPEs for Profile2 with DIFFERENT scopes
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE1',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE1',
                student.Id,
                spg.Id,
                studyPlan1.Id,
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

        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE2',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE2',
                student.Id,
                newSpg.Id,
                studyPlan2.Id,
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

        // Create IPE for Profile1
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE3',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE3',
                student.Id,
                spg.Id,
                studyPlan1.Id,
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

        insert newIpeMap.values();

        System.runAs(FACULTY_USER) {

            //Create IEN for Profile1 - should error when trying to clone to Profile2 (mixed scopes)
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                student.Id,
                sof.Id,
                'Completed',
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

            ien.reduivy__Grade_Result__c = 'Pass';

            try {
                insert ien;
                System.Assert.fail('Should have thrown error for mixed scopes');
            } catch(DmlException e) {
                String spgAutoUnitRecognitionScopeFieldLabel = Schema.SObjectType.reduivy__Study_Program__c.fields.reduivy__Auto_Unit_Recognition_Scope__c.getLabel();

                System.Assert.isTrue(
                    e.getMessage().contains((String.format(Label.Mixture_Of_Recognition_Scope_Found, new List<String>{SPG_Helper.getObjectPluralLabel(), spgAutoUnitRecognitionScopeFieldLabel, IPF_Helper.getObjectLabel()}))),
                    'Error message should indicate mixed scopes: ' + e.getMessage()
                );
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test scope None should not clone as faculty
     */
    @IsTest
    static void testScopeNoneShouldNotCloneAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        Contact student = studentContacts[0];

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

        //Get study plans
        reduivy__Study_Plan__c studyPlan1 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];

        //Get study unit
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        //Update BOTH study programs to have "None" scope
        List<reduivy__Study_Program__c> programsToUpdate = [
            SELECT Id, reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];

        for(reduivy__Study_Program__c prog : programsToUpdate) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_NONE;
        }
        update programsToUpdate;

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        // Create TWO profiles
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

        insert newIpfMap.values();

        // Create IPEs
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE1',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE1',
                student.Id,
                studyPlan1.reduivy__Study_Program__c,
                studyPlan1.Id,
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

        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE2',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE2',
                student.Id,
                studyPlan2.reduivy__Study_Program__c,
                studyPlan2.Id,
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

        insert newIpeMap.values();

        System.runAs(FACULTY_USER) {

            //Create IEN - should NOT clone because scope is None
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                student.Id,
                sof.Id,
                'Completed',
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

            ien.reduivy__Grade_Result__c = 'Pass';

            insert ien;
        }

        //Verify NO cloning occurred
        List<reduivy__Individual_Enrollment__c> allIens = [
            SELECT Id,
            reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :student.Id
            AND reduivy__Target_Unit_Id__c = :studyUnit.Id
        ];

        System.Assert.areEqual(1, allIens.size(), 'Should have only 1 IEN - no cloning with None scope');

        Test.stopTest();
    }

    /**
     * @description Test update to recognizable status should trigger cloning as faculty
     */
    @IsTest
    static void testUpdateToRecognizableStatusShouldTriggerCloningAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        Contact student = studentContacts[0];

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

        //Get study plans
        reduivy__Study_Plan__c studyPlan1 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];

        //Get study unit
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        //Update study programs
        List<reduivy__Study_Program__c> programsToUpdate = [
            SELECT Id, reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];

        for(reduivy__Study_Program__c prog : programsToUpdate) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programsToUpdate;

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        // Create profiles
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

        insert newIpfMap.values();

        // Create IPEs
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE1',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE1',
                student.Id,
                studyPlan1.reduivy__Study_Program__c,
                studyPlan1.Id,
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

        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE2',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE2',
                student.Id,
                studyPlan2.reduivy__Study_Program__c,
                studyPlan2.Id,
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

        insert newIpeMap.values();

        reduivy__Individual_Enrollment__c ien;

        System.runAs(FACULTY_USER) {
            //Create IEN with NON-recognizable status
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                student.Id,
                sof.Id,
                IEN_INPROGRESS_STATUS, // Non-recognizable
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

            insert ien;

            //Verify no cloning yet
            Integer countBefore = [
                SELECT COUNT()
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :student.Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
            ];
            System.Assert.areEqual(1, countBefore, 'Should have only 1 IEN before update');

            //Update to recognizable status
            ien.reduivy__Enrollment_Status__c = 'Completed';
            ien.reduivy__Grade_Result__c = 'Pass';
            update ien;
        }

        //Verify cloning occurred after update
        List<reduivy__Individual_Enrollment__c> allIens = [
            SELECT Id,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Credit_Transfer_Type__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :student.Id
            AND reduivy__Target_Unit_Id__c = :studyUnit.Id
        ];

        System.Assert.areEqual(2, allIens.size(), 'Should have 2 IENs after update to recognizable status');

        Test.stopTest();
    }

    /**
     * @description Test bulk cloning with multiple students and profiles as faculty
     */
    @IsTest
    static void testBulkCloningWithMultipleStudentsAsFaculty(){
        
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

        //Get study plans
        reduivy__Study_Plan__c studyPlan1 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];

        //Get study unit
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        //Update study programs
        List<reduivy__Study_Program__c> programsToUpdate = [
            SELECT Id, reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];

        for(reduivy__Study_Program__c prog : programsToUpdate) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programsToUpdate;

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        List<reduivy__Individual_Program_Enrollment__c> newIpeList = new List<reduivy__Individual_Program_Enrollment__c>();

        // Create profiles and IPEs for ALL students
        for(Contact student : studentContacts) {
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

        for(Contact student : studentContacts) {
            newIpeList.add(
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE1',
                    student.Id,
                    studyPlan1.reduivy__Study_Program__c,
                    studyPlan1.Id,
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
                    studyPlan2.reduivy__Study_Program__c,
                    studyPlan2.Id,
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

        insert newIpeList;

        System.runAs(FACULTY_USER) {
            //Create IENs for ALL students
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            List<reduivy__Individual_Enrollment__c> iensToInsert = new List<reduivy__Individual_Enrollment__c>();

            for(Contact student : studentContacts) {
                reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    student.Id,
                    sof.Id,
                    'Completed',
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

                ien.reduivy__Grade_Result__c = 'Pass';

                iensToInsert.add(ien);
            }

            insert iensToInsert;
        }

        //Verify cloning for ALL students
        Map<Id, List<reduivy__Individual_Enrollment__c>> studentToIens = new Map<Id, List<reduivy__Individual_Enrollment__c>>();

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id,
            reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Credit_Transfer_Type__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN :studentContacts
            AND reduivy__Target_Unit_Id__c = :studyUnit.Id
        ]) {
            if(!studentToIens.containsKey(ien.reduivy__Contact__c)) {
                studentToIens.put(ien.reduivy__Contact__c, new List<reduivy__Individual_Enrollment__c>());
            }
            studentToIens.get(ien.reduivy__Contact__c).add(ien);
        }

        System.Assert.areEqual(studentContacts.size(), studentToIens.size(), 'Should have IENs for all students');

        for(Contact student : studentContacts) {
            List<reduivy__Individual_Enrollment__c> studentIens = studentToIens.get(student.Id);
            System.Assert.areEqual(2, studentIens.size(), 'Each student should have 2 IENs (original + cloned)');
        }

        Test.stopTest();
    }

    /**
     * @description Test that duplicate clones are not created as faculty
     */
    @IsTest
    static void testNoDuplicateClonesCreatedAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        Contact student = studentContacts[0];

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

        //Get study plans
        reduivy__Study_Plan__c studyPlan1 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];

        //Get study unit
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        //Update study programs
        List<reduivy__Study_Program__c> programsToUpdate = [
            SELECT Id, reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];

        for(reduivy__Study_Program__c prog : programsToUpdate) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programsToUpdate;

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        // Create profiles
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

        insert newIpfMap.values();

        // Create IPEs
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE1',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE1',
                student.Id,
                studyPlan1.reduivy__Study_Program__c,
                studyPlan1.Id,
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

        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE2',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE2',
                student.Id,
                studyPlan2.reduivy__Study_Program__c,
                studyPlan2.Id,
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

        insert newIpeMap.values();

        reduivy__Individual_Enrollment__c ien1;
        reduivy__Individual_Enrollment__c ien2;

        System.runAs(FACULTY_USER) {

            //Create first IEN - should trigger cloning
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            ien1 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_1',
                student.Id,
                sof.Id,
                'Completed',
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

            ien1.reduivy__Grade_Result__c = 'Pass';

            insert ien1;

            //Verify 2 IENs exist
            Integer countAfterFirst = [
                SELECT COUNT()
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :student.Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
            ];
            System.Assert.areEqual(2, countAfterFirst, 'Should have 2 IENs after first insert');

            //Create second IEN with same criteria - should NOT create duplicate clone
            ien2 = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c + '_2',
                student.Id,
                sof.Id,
                'Completed',
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

            ien2.reduivy__Grade_Result__c = 'Pass';

            insert ien2;
        }

        //Verify still only 2 IENs total (not 4)
        Integer finalCount = [
            SELECT COUNT()
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :student.Id
            AND reduivy__Target_Unit_Id__c = :studyUnit.Id
        ];

        System.Assert.areEqual(3, finalCount, 'Should have 3 IENs total - 2 originals and 1 clone (no duplicates)');

        Test.stopTest();
    }

    /**
     * @description Test that existing Open status IEN is updated instead of creating new one as faculty
     */
    @IsTest
    static void testExistingOpenIenIsUpdatedNotInsertedAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        Contact student = studentContacts[0];

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan1 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA' LIMIT 1
        ];

        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102' LIMIT 1
        ];

        // Enable auto unit recognition
        List<reduivy__Study_Program__c> programsToUpdate = [
            SELECT Id, reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];

        for(reduivy__Study_Program__c prog : programsToUpdate) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programsToUpdate;

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

        // Create IPEs
        List<reduivy__Individual_Program_Enrollment__c> ipes = new List<reduivy__Individual_Program_Enrollment__c>();
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.reduivy__Sample_Record_Code__c + '_IPE1', student.Id,
            studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('Profile1').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.reduivy__Sample_Record_Code__c + '_IPE2', student.Id,
            studyPlan2.reduivy__Study_Program__c, studyPlan2.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('Profile2').Id
        ));
        insert ipes;

        System.runAs(FACULTY_USER) {
            String openStatus = IEN_Helper.getOpenStatuses().get(0);
            
            // Create existing Open IEN in Profile2
            reduivy__Individual_Enrollment__c existingOpenIen = new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = student.Id,
                reduivy__Study_Unit__c = studyUnit.Id,
                reduivy__Individual_Academic_Profile__c = ipfMap.get('Profile2').Id,
                reduivy__Enrollment_Status__c = openStatus,
                reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
                RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
                reduivy__Bypass_Requirement_Met__c = true
            );
            insert existingOpenIen;

            Id existingOpenIenId = existingOpenIen.Id;

            // Create recognizable IEN in Profile1 - should UPDATE existing Open IEN
            reduivy__Study_Offering__c sof = [SELECT Id FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c = :academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id LIMIT 1
            ];

            reduivy__Individual_Enrollment__c sourceIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.Id,
                student.Id, sof.Id, 'Completed', 1, System.today(),
                null, null, null, 3, null, ipfMap.get('Profile1').Id, true
            );
            sourceIen.reduivy__Grade_Result__c = 'Pass';
            insert sourceIen;

            // Verify IEN count - should be 2 total (source + updated Open IEN)
            List<reduivy__Individual_Enrollment__c> allIens = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Academic_Profile__c,
                    reduivy__Credit_Transfer_Type__c, reduivy__Grade_Result__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :student.Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
                ORDER BY CreatedDate
            ];

            System.Assert.areEqual(2, allIens.size(), 'Should have exactly 2 IENs (source + updated Open)');
            
            // Verify the Open IEN was UPDATED, not inserted new
            reduivy__Individual_Enrollment__c updatedIen = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Credit_Transfer_Type__c, 
                    reduivy__Grade_Result__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :existingOpenIenId
            ];

            System.Assert.areEqual(existingOpenIenId, updatedIen.Id, 
                'Should be same IEN record (updated, not new)');
            System.Assert.areEqual('Completed', updatedIen.reduivy__Enrollment_Status__c,
                'Open IEN should be updated to Completed status');
            System.Assert.areEqual('Pass', updatedIen.reduivy__Grade_Result__c,
                'Open IEN should have cloned grade result');
            System.Assert.areEqual(IEN_Helper.CREDIT_TRANSFER_TYPE_AUTO_UNIT_RECOGNITION,
                updatedIen.reduivy__Credit_Transfer_Type__c,
                'Should have Auto Unit Recognition transfer type');
        }

        Test.stopTest();
    }

    /**
     * @description Test that Open IEN prevents new IEN creation even with multiple triggers as faculty
     */
    @IsTest
    static void testOpenIenPreventsMultipleClonesAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        Contact student = [SELECT Id, reduivy__Sample_Record_Code__c FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> '' LIMIT 1
        ];

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan1 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA' LIMIT 1
        ];

        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102' LIMIT 1
        ];

        List<reduivy__Study_Program__c> programs = [
            SELECT Id FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];
        for(reduivy__Study_Program__c prog : programs) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programs;

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        ipfMap.put('P1', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P1', student.Id, 'P1', IPF_Helper.STATUS_ACTIVE, true
        ));
        ipfMap.put('P2', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P2', student.Id, 'P2', IPF_Helper.STATUS_ACTIVE, false
        ));
        insert ipfMap.values();

        List<reduivy__Individual_Program_Enrollment__c> ipes = new List<reduivy__Individual_Program_Enrollment__c>();
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE1', student.Id, studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P1').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE2', student.Id, studyPlan2.reduivy__Study_Program__c, studyPlan2.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P2').Id
        ));
        insert ipes;

        System.runAs(FACULTY_USER) {
            // Create Open IEN in Profile2
            String openStatus = IEN_Helper.getOpenStatuses().get(0);
            reduivy__Individual_Enrollment__c openIen = new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = student.Id,
                reduivy__Study_Unit__c = studyUnit.Id,
                reduivy__Individual_Academic_Profile__c = ipfMap.get('P2').Id,
                reduivy__Enrollment_Status__c = openStatus,
                reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
                RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
                reduivy__Bypass_Requirement_Met__c = true
            );
            insert openIen;

            reduivy__Study_Offering__c sof = [SELECT Id FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c = :academicTerm.Id 
                AND reduivy__Study_Unit__c = :studyUnit.Id LIMIT 1
            ];

            // Create TWO recognizable IENs in Profile1
            List<reduivy__Individual_Enrollment__c> sourceIens = new List<reduivy__Individual_Enrollment__c>();
            for(Integer i = 0; i < 2; i++) {
                reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.Id + '_' + sof.Id + '_' + i, student.Id, sof.Id,
                    'Completed', 1, System.today(), null, null, null, 3, null,
                    ipfMap.get('P1').Id, true
                );
                ien.reduivy__Grade_Result__c = 'Pass';
                sourceIens.add(ien);
            }
            insert sourceIens;

            // Verify still only ONE IEN in Profile2 (the updated Open IEN)
            Integer profile2Count = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('P2').Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
            ];

            System.Assert.areEqual(1, profile2Count,
                'Should have only 1 IEN in Profile2 despite multiple triggers');
        }

        Test.stopTest();
    }

    /**
     * @description Test non-enrollable IEN prevents cloning (no Open IEN exists) as faculty
     */
    @IsTest
    static void testNonEnrollableIenPreventsCloningAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        Contact student = [SELECT Id, reduivy__Sample_Record_Code__c FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> '' LIMIT 1
        ];

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan1 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA' LIMIT 1
        ];

        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102' LIMIT 1
        ];

        List<reduivy__Study_Program__c> programs = [SELECT Id FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];
        for(reduivy__Study_Program__c prog : programs) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programs;

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        ipfMap.put('P1', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P1', student.Id, 'P1', IPF_Helper.STATUS_ACTIVE, true
        ));
        ipfMap.put('P2', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P2', student.Id, 'P2', IPF_Helper.STATUS_ACTIVE, false
        ));
        insert ipfMap.values();

        List<reduivy__Individual_Program_Enrollment__c> ipes = new List<reduivy__Individual_Program_Enrollment__c>();
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE1', student.Id, studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P1').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE2', student.Id, studyPlan2.reduivy__Study_Program__c, studyPlan2.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P2').Id
        ));
        insert ipes;

        System.runAs(FACULTY_USER) {
            reduivy__Study_Offering__c sof = [SELECT Id FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c = :academicTerm.Id 
                AND reduivy__Study_Unit__c = :studyUnit.Id LIMIT 1
            ];

            // Create In progress IEN in Profile2 (non-enrollable)
            reduivy__Individual_Enrollment__c failedIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.Id + '_FAILED', student.Id, sof.Id, IEN_INPROGRESS_STATUS,
                1, System.today(), null, null, null, 3, null,
                ipfMap.get('P2').Id, true
            );
            insert failedIen;

            Integer initialCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('P2').Id
            ];

            // Create recognizable IEN in Profile1
            reduivy__Individual_Enrollment__c sourceIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.Id + '_PASS', student.Id, sof.Id, 'Completed',
                1, System.today(), null, null, null, 3, null,
                ipfMap.get('P1').Id, true
            );
            sourceIen.reduivy__Grade_Result__c = 'Pass';
            insert sourceIen;

            Integer finalCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('P2').Id
            ];

            System.Assert.areEqual(initialCount, finalCount,
                'No new IEN should be created when non-enrollable IEN exists');
        }

        Test.stopTest();
    }

    /**
     * @description Test credit transfer IENs should not trigger cloning as faculty
     */
    @IsTest
    static void testCreditTransferIenDoesNotTriggerCloningAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        Contact student = [SELECT Id, reduivy__Sample_Record_Code__c FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> '' LIMIT 1
        ];

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan1 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA' LIMIT 1
        ];

        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102' LIMIT 1
        ];

        List<reduivy__Study_Program__c> programs = [SELECT Id FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];
        for(reduivy__Study_Program__c prog : programs) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programs;

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        ipfMap.put('P1', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P1', student.Id, 'P1', IPF_Helper.STATUS_ACTIVE, true
        ));
        ipfMap.put('P2', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P2', student.Id, 'P2', IPF_Helper.STATUS_ACTIVE, false
        ));
        insert ipfMap.values();

        List<reduivy__Individual_Program_Enrollment__c> ipes = new List<reduivy__Individual_Program_Enrollment__c>();
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE1', student.Id, studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P1').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE2', student.Id, studyPlan2.reduivy__Study_Program__c, studyPlan2.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P2').Id
        ));
        insert ipes;

        System.runAs(FACULTY_USER) {
            reduivy__Study_Offering__c sof = [SELECT Id FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c = :academicTerm.Id 
                AND reduivy__Study_Unit__c = :studyUnit.Id LIMIT 1
            ];

            // Create IEN with credit transfer flag = TRUE
            reduivy__Individual_Enrollment__c creditTransferIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.Id + '_CT', student.Id, sof.Id, 'Completed',
                1, System.today(), null, null, null, 3, null,
                ipfMap.get('P1').Id, true
            );
            creditTransferIen.reduivy__Grade_Result__c = 'Pass';
            creditTransferIen.reduivy__Credit_Transfer_Received__c = true; // CREDIT TRANSFER
            insert creditTransferIen;

            // Verify NO cloning occurred
            Integer profile2Count = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('P2').Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
            ];

            System.Assert.areEqual(0, profile2Count,
                'Credit transfer IEN should NOT trigger cloning');
        }

        Test.stopTest();
    }

    /**
     * @description Test changing IPF should trigger cloning to new IPF as faculty
     */
    @IsTest
    static void testChangingIpfTriggersReCloningAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        Contact student = [SELECT Id, reduivy__Sample_Record_Code__c FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> '' LIMIT 1
        ];

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan1 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA' LIMIT 1
        ];

        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102' LIMIT 1
        ];

        List<reduivy__Study_Program__c> programs = [SELECT Id FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];
        for(reduivy__Study_Program__c prog : programs) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programs;

        // Create THREE IPFs
        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        ipfMap.put('P1', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P1', student.Id, 'P1', IPF_Helper.STATUS_ACTIVE, true
        ));
        ipfMap.put('P2', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P2', student.Id, 'P2', IPF_Helper.STATUS_ACTIVE, false
        ));
        ipfMap.put('P3', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P3', student.Id, 'P3', IPF_Helper.STATUS_ACTIVE, false
        ));
        insert ipfMap.values();

        List<reduivy__Individual_Program_Enrollment__c> ipes = new List<reduivy__Individual_Program_Enrollment__c>();
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE1', student.Id, studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P1').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE2', student.Id, studyPlan2.reduivy__Study_Program__c, studyPlan2.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P2').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE3', student.Id, studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P3').Id
        ));
        insert ipes;

        reduivy__Individual_Enrollment__c recognizableIen;

        System.runAs(FACULTY_USER) {
            reduivy__Study_Offering__c sof = [SELECT Id FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c = :academicTerm.Id 
                AND reduivy__Study_Unit__c = :studyUnit.Id LIMIT 1
            ];

            // Create recognizable IEN in P1
            recognizableIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.Id + '_RECON', student.Id, sof.Id, 'Completed',
                1, System.today(), null, null, null, 3, null,
                ipfMap.get('P1').Id, true
            );
            recognizableIen.reduivy__Grade_Result__c = 'Pass';
            insert recognizableIen;

            // Verify clones in P2 and P3
            Integer totalClones = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :student.Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
                AND reduivy__Individual_Academic_Profile__c IN (:ipfMap.get('P2').Id, :ipfMap.get('P3').Id)
            ];
            System.Assert.areEqual(2, totalClones, 'Should have cloned to P2 and P3');

            // Move recognizable IEN from P1 to P2
            recognizableIen.reduivy__Individual_Academic_Profile__c = ipfMap.get('P2').Id;
            update recognizableIen;
        }

        // Verify new clone created in P1 (since recognizable moved to P2)
        Integer p1Count = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('P1').Id
            AND reduivy__Target_Unit_Id__c = :studyUnit.Id
        ];

        System.Assert.areEqual(1, p1Count,
            'Should have new clone in P1 after source moved to P2');

        Test.stopTest();
    }

    /**
     * @description Test changing study unit should trigger cloning to new unit as faculty
     */
    @IsTest
    static void testChangingStudyUnitTriggersReCloningAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        Contact student = [SELECT Id, reduivy__Sample_Record_Code__c FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> '' LIMIT 1
        ];

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan1 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA' LIMIT 1
        ];

        List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c IN ('BUS102', 'BUS103')
            ORDER BY reduivy__Sample_Record_Code__c
        ];

        List<reduivy__Study_Program__c> programs = [SELECT Id FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];
        for(reduivy__Study_Program__c prog : programs) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programs;

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        ipfMap.put('P1', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P1', student.Id, 'P1', IPF_Helper.STATUS_ACTIVE, true
        ));
        ipfMap.put('P2', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P2', student.Id, 'P2', IPF_Helper.STATUS_ACTIVE, false
        ));
        insert ipfMap.values();

        List<reduivy__Individual_Program_Enrollment__c> ipes = new List<reduivy__Individual_Program_Enrollment__c>();
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE1', student.Id, studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P1').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE2', student.Id, studyPlan2.reduivy__Study_Program__c, studyPlan2.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P2').Id
        ));
        insert ipes;

        reduivy__Individual_Enrollment__c recognizableIen;

        System.runAs(FACULTY_USER) {
            List<reduivy__Study_Offering__c> sofs = [SELECT Id, reduivy__Study_Unit__c 
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c = :academicTerm.Id 
                AND reduivy__Study_Unit__c IN :studyUnits
                ORDER BY reduivy__Study_Unit__c
            ];

            // Create recognizable IEN for BUS102
            recognizableIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.Id + '_RECON', student.Id, sofs[0].Id, 'Completed',
                1, System.today(), null, null, null, 3, null,
                ipfMap.get('P1').Id, true
            );
            recognizableIen.reduivy__Grade_Result__c = 'Pass';
            insert recognizableIen;

            Integer initialP2Count = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('P2').Id
            ];

            // Change study unit from BUS102 to BUS103
            recognizableIen.reduivy__Study_Unit__c = studyUnits[1].Id;
            recognizableIen.reduivy__Study_Offering__c = sofs[1].Id;
            update recognizableIen;

            Integer finalP2Count = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('P2').Id
            ];

            System.Assert.areEqual(initialP2Count + 1, finalP2Count,
                'Should create new clone for new study unit');
        }

        Test.stopTest();
    }

    /**
     * @description Test multiple Open IENs scenario - all should be updated as faculty
     */
    @IsTest
    static void testMultipleOpenIensAllUpdatedAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        Contact student = [SELECT Id, reduivy__Sample_Record_Code__c FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> '' LIMIT 1
        ];

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan1 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA' LIMIT 1
        ];

        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102' LIMIT 1
        ];

        List<reduivy__Study_Program__c> programs = [SELECT Id FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];
        for(reduivy__Study_Program__c prog : programs) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programs;

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        ipfMap.put('P1', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P1', student.Id, 'P1', IPF_Helper.STATUS_ACTIVE, true
        ));
        ipfMap.put('P2', REDU_TestData_UTIL.newIndividualAcademicProfile(
            student.Id + '_P2', student.Id, 'P2', IPF_Helper.STATUS_ACTIVE, false
        ));
        insert ipfMap.values();

        List<reduivy__Individual_Program_Enrollment__c> ipes = new List<reduivy__Individual_Program_Enrollment__c>();
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE1', student.Id, studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P1').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.Id + '_IPE2', student.Id, studyPlan2.reduivy__Study_Program__c, studyPlan2.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('P2').Id
        ));
        insert ipes;

        System.runAs(FACULTY_USER) {
            String openStatus = IEN_Helper.getOpenStatuses().get(0);
            
            // Create MULTIPLE Open IENs for same IPF+Unit (edge case - shouldn't happen but test it)
            List<reduivy__Individual_Enrollment__c> openIens = new List<reduivy__Individual_Enrollment__c>();
            for(Integer i = 0; i < 5; i++) {
                openIens.add(new reduivy__Individual_Enrollment__c(
                    reduivy__Contact__c = student.Id,
                    reduivy__Study_Unit__c = studyUnit.Id,
                    reduivy__Individual_Academic_Profile__c = ipfMap.get('P2').Id,
                    reduivy__Enrollment_Status__c = openStatus,
                    reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
                    RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
                    reduivy__Bypass_Requirement_Met__c = true
                ));
            }
            insert openIens;

            reduivy__Study_Offering__c sof = [SELECT Id FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c = :academicTerm.Id 
                AND reduivy__Study_Unit__c = :studyUnit.Id LIMIT 1
            ];

            // Create recognizable IEN
            reduivy__Individual_Enrollment__c sourceIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.Id + '_SOURCE', student.Id, sof.Id, 'Completed',
                1, System.today(), null, null, null, 3, null,
                ipfMap.get('P1').Id, true
            );
            sourceIen.reduivy__Grade_Result__c = 'Pass';
            insert sourceIen;

            // Verify only ONE Open IEN was updated (not both)
            Integer updatedCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('P2').Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
                AND reduivy__Enrollment_Status__c = 'Completed'
            ];

            System.Assert.areEqual(5, updatedCount,
                'All Open IEN should be updated to Completed');
        }

        Test.stopTest();
    }

    /**
     * @description Test that existing In Progress IEN is NOT updated when completed IEN exists in another profile as faculty
     */
    @IsTest
    static void testInProgressIenNotUpdatedWhenCompletedExistsAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        Contact student = [SELECT Id, reduivy__Sample_Record_Code__c FROM Contact 
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> '' LIMIT 1
        ];

        reduivy__Study_Term__c academicTerm = [SELECT Id FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY ORDER BY reduivy__Start_Date__c LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan1 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA' LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA' LIMIT 1
        ];

        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102' LIMIT 1
        ];

        // Enable auto unit recognition
        List<reduivy__Study_Program__c> programsToUpdate = [
            SELECT Id, reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];

        for(reduivy__Study_Program__c prog : programsToUpdate) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programsToUpdate;

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

        // Create IPEs
        List<reduivy__Individual_Program_Enrollment__c> ipes = new List<reduivy__Individual_Program_Enrollment__c>();
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.reduivy__Sample_Record_Code__c + '_IPE1', student.Id,
            studyPlan1.reduivy__Study_Program__c, studyPlan1.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('Profile1').Id
        ));
        ipes.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            student.reduivy__Sample_Record_Code__c + '_IPE2', student.Id,
            studyPlan2.reduivy__Study_Program__c, studyPlan2.Id,
            null, academicTerm.Id, null, null, null, null, true,
            IPE_INPROGRESS_STATUS, ipfMap.get('Profile2').Id
        ));
        insert ipes;

        System.runAs(FACULTY_USER) {
            reduivy__Study_Offering__c sof = [SELECT Id FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c = :academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id LIMIT 1
            ];

            // Step 1: Create COMPLETED/RECOGNIZABLE IEN in Profile1
            reduivy__Individual_Enrollment__c completedIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_COMPLETED',
                student.Id, sof.Id, 'Completed', 1, System.today(),
                null, null, null, 3, null, ipfMap.get('Profile1').Id, true
            );
            completedIen.reduivy__Grade_Result__c = 'Pass';
            insert completedIen;

            // Verify clone was created in Profile2
            Integer profile2CountAfterCompleted = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Individual_Academic_Profile__c = :ipfMap.get('Profile2').Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
            ];
            
            System.Assert.areEqual(1, profile2CountAfterCompleted,
                'Should have 1 cloned IEN in Profile2 after creating completed IEN in Profile1');

            // Step 2: Create NEW IN PROGRESS IEN in Profile2
            reduivy__Individual_Enrollment__c inProgressIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_INPROGRESS',
                student.Id, sof.Id, IEN_INPROGRESS_STATUS, 1, System.today(),
                null, null, null, null, null, ipfMap.get('Profile2').Id, true
            );
            insert inProgressIen;

            Id inProgressIenId = inProgressIen.Id;

            // Verify the In Progress IEN was NOT automatically updated to Completed
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

            // Verify total count - should have completed in P1, and 1 completed and 1 new in-progress in P2
            Integer totalCount = [SELECT COUNT() FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :student.Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
            ];

            System.Assert.isTrue(totalCount == 3,
                'Should have at least 3 IENs (completed in P1 + completed + in-progress in P2)');
        }

        Test.stopTest();
    }

    /**
     * @description Test bulk cloning with multiple students and different units as faculty
     */
    @IsTest
    static void testBulkCloningWithMultipleStudentsAndDifferentUnitsAsFaculty(){

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        List<Contact> studentContacts = [
            SELECT Id, reduivy__Sample_Record_Code__c
            FROM Contact
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c != null
            LIMIT 3
        ];
        System.assertEquals(3, studentContacts.size(), 'Need at least 3 students for this test');

        // Current academic term
        reduivy__Study_Term__c academicTerm = [
            SELECT Id, reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId()
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        // Institution + campus (Accounts)
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

        // Study program
        reduivy__Study_Program__c studyProgram = [
            SELECT Id
            FROM reduivy__Study_Program__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS'
            LIMIT 1
        ];

        studyProgram.reduivy__Auto_Unit_Recognition_Scope__c =
            SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        update studyProgram;

        // Study Units
        Map<String, reduivy__Study_Unit__c> unitMap = new Map<String, reduivy__Study_Unit__c>();
        List<reduivy__Study_Unit__c> testUnits = new List<reduivy__Study_Unit__c>{
            new reduivy__Study_Unit__c(
                Name = 'TEST101 - Test Unit',
                reduivy__Sample_Record_Code__c = 'TEST101',
                reduivy__Unit_Code__c = 'TEST101'
            ),
            new reduivy__Study_Unit__c(
                Name = 'TEST201 - Test Unit',
                reduivy__Sample_Record_Code__c = 'TEST201',
                reduivy__Unit_Code__c = 'TEST201'
            ),
            new reduivy__Study_Unit__c(
                Name = 'TEST301 - Test Unit',
                reduivy__Sample_Record_Code__c = 'TEST301',
                reduivy__Unit_Code__c = 'TEST301'
            )
        };
        insert testUnits;

        for(reduivy__Study_Unit__c u : testUnits) {
            unitMap.put(u.reduivy__Sample_Record_Code__c, u);
        }

        // Study Plans
        Map<String, reduivy__Study_Plan__c> studyPlanMap = new Map<String, reduivy__Study_Plan__c>();
        List<reduivy__Study_Plan__c> studyPlans = new List<reduivy__Study_Plan__c>();
        for(String nameVal : new List<String>{'Plan_A','Plan_B','Plan_C','Plan_D','Plan_E','Plan_F'}) {
            studyPlans.add(new reduivy__Study_Plan__c(
                Name = nameVal,
                reduivy__Sample_Record_Code__c = nameVal,
                reduivy__Study_Program__c = studyProgram.Id
            ));
        }
        insert studyPlans;
        for(reduivy__Study_Plan__c p : studyPlans) {
            studyPlanMap.put(p.reduivy__Sample_Record_Code__c, p);
        }

        // Study Plan Structures
        List<reduivy__Study_Plan_Structure__c> planStructures = new List<reduivy__Study_Plan_Structure__c>{
            new reduivy__Study_Plan_Structure__c(
                Name = 'Plan_A_TEST101',
                reduivy__Sample_Record_Code__c = 'Plan_A_TEST101',
                reduivy__Study_Plan__c = studyPlanMap.get('Plan_A').Id,
                reduivy__Study_Unit__c = unitMap.get('TEST101').Id,
                RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
                reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
                reduivy__Credits__c = 3
            ),
            new reduivy__Study_Plan_Structure__c(
                Name = 'Plan_B_TEST101',
                reduivy__Sample_Record_Code__c = 'Plan_B_TEST101',
                reduivy__Study_Plan__c = studyPlanMap.get('Plan_B').Id,
                reduivy__Study_Unit__c = unitMap.get('TEST101').Id,
                RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
                reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
                reduivy__Credits__c = 3
            ),
            new reduivy__Study_Plan_Structure__c(
                Name = 'Plan_C_TEST201',
                reduivy__Sample_Record_Code__c = 'Plan_C_TEST201',
                reduivy__Study_Plan__c = studyPlanMap.get('Plan_C').Id,
                reduivy__Study_Unit__c = unitMap.get('TEST201').Id,
                RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
                reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
                reduivy__Credits__c = 3
            ),
            new reduivy__Study_Plan_Structure__c(
                Name = 'Plan_D_TEST201',
                reduivy__Sample_Record_Code__c = 'Plan_D_TEST201',
                reduivy__Study_Plan__c = studyPlanMap.get('Plan_D').Id,
                reduivy__Study_Unit__c = unitMap.get('TEST201').Id,
                RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
                reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
                reduivy__Credits__c = 3
            ),
            new reduivy__Study_Plan_Structure__c(
                Name = 'Plan_E_TEST301',
                reduivy__Sample_Record_Code__c = 'Plan_E_TEST301',
                reduivy__Study_Plan__c = studyPlanMap.get('Plan_E').Id,
                reduivy__Study_Unit__c = unitMap.get('TEST301').Id,
                RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
                reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
                reduivy__Credits__c = 3
            ),
            new reduivy__Study_Plan_Structure__c(
                Name = 'Plan_F_TEST301',
                reduivy__Sample_Record_Code__c = 'Plan_F_TEST301',
                reduivy__Study_Plan__c = studyPlanMap.get('Plan_F').Id,
                reduivy__Study_Unit__c = unitMap.get('TEST301').Id,
                RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
                reduivy__Category__c = SPS_Helper.CATEGORY_REQUIRED,
                reduivy__Credits__c = 3
            )
        };
        insert planStructures;

        // Study Offerings
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

        // Profiles + IPEs
        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        List<reduivy__Individual_Program_Enrollment__c> newIpeList = new List<reduivy__Individual_Program_Enrollment__c>();

        Map<Id, Map<String, Id>> studentToPlanMap = new Map<Id, Map<String, Id>>();
        Map<Id, String> studentToUnitCodeMap = new Map<Id, String>();

        studentToPlanMap.put(studentContacts[0].Id, new Map<String, Id>{
            'Profile1' => studyPlanMap.get('Plan_A').Id,
            'Profile2' => studyPlanMap.get('Plan_B').Id
        });
        studentToUnitCodeMap.put(studentContacts[0].Id, 'TEST101');

        studentToPlanMap.put(studentContacts[1].Id, new Map<String, Id>{
            'Profile1' => studyPlanMap.get('Plan_C').Id,
            'Profile2' => studyPlanMap.get('Plan_D').Id
        });
        studentToUnitCodeMap.put(studentContacts[1].Id, 'TEST201');

        studentToPlanMap.put(studentContacts[2].Id, new Map<String, Id>{
            'Profile1' => studyPlanMap.get('Plan_E').Id,
            'Profile2' => studyPlanMap.get('Plan_F').Id
        });
        studentToUnitCodeMap.put(studentContacts[2].Id, 'TEST301');

        for(Contact student : studentContacts) {
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

        for(Contact student : studentContacts) {
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
        insert newIpeList;

        System.runAs(FACULTY_USER) {
            List<reduivy__Individual_Enrollment__c> iensToInsert = new List<reduivy__Individual_Enrollment__c>();

            for(Contact student : studentContacts) {
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

                reduivy__Individual_Enrollment__c ien =
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        'Completed',
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

                ien.reduivy__Grade_Result__c = 'Pass';
                iensToInsert.add(ien);
            }
            insert iensToInsert;
        }

        Map<Id, List<reduivy__Individual_Enrollment__c>> studentToIens =
            new Map<Id, List<reduivy__Individual_Enrollment__c>>();

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id,
                reduivy__Contact__c,
                reduivy__Individual_Academic_Profile__c,
                reduivy__Credit_Transfer_Type__c,
                reduivy__Target_Unit_Id__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN :studentContacts
            AND reduivy__Target_Unit_Id__c != null
            ORDER BY reduivy__Contact__c, CreatedDate
        ]) {
            if(!studentToIens.containsKey(ien.reduivy__Contact__c)) {
                studentToIens.put(ien.reduivy__Contact__c, new List<reduivy__Individual_Enrollment__c>());
            }
            studentToIens.get(ien.reduivy__Contact__c).add(ien);
        }

        System.assertEquals(studentContacts.size(), studentToIens.size(),
            'Should have IENs for all students');

        Integer studentIndex = 0;
        for(Contact student : studentContacts) {
            List<reduivy__Individual_Enrollment__c> studentIens = studentToIens.get(student.Id);
            System.assertEquals(2, studentIens.size(),
                'Student ' + (studentIndex + 1) + ' should have 2 IENs (original + cloned)');

            String expectedUnitCode = studentToUnitCodeMap.get(student.Id);
            String expectedUnitId = unitMap.get(expectedUnitCode).Id;

            for(reduivy__Individual_Enrollment__c ien : studentIens) {
                System.assertEquals(expectedUnitId, ien.reduivy__Target_Unit_Id__c,
                    'Student ' + (studentIndex + 1) + ' IEN should target unit ' + expectedUnitCode);
            }

            Set<Id> profiles = new Set<Id>();
            for(reduivy__Individual_Enrollment__c ien : studentIens) {
                profiles.add(ien.reduivy__Individual_Academic_Profile__c);
            }

            System.assert(profiles.contains(
                newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile1').Id));
            System.assert(profiles.contains(
                newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile2').Id));

            studentIndex++;
        }

        Test.stopTest();
    }

    /**
     * @description Test auto unit recognition cloning with single IPF - should clone to other IPF as student
     */
    @IsTest
    static void testAutoUnitRecognitionWithSingleIpfAsStudent(){
                
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
            WHERE ContactId =: studentContacts[0].Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        Contact student = studentContacts[0];

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

        //Get study plans with structure
        reduivy__Study_Plan__c studyPlan1 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan2 = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];

        //Get study unit from structure (BUS102 is in both study plans)
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        //Update study programs to have "All Academic Profiles" scope
        List<reduivy__Study_Program__c> programsToUpdate = [
            SELECT Id, reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Study_Program__c
            WHERE Id IN (:studyPlan1.reduivy__Study_Program__c, :studyPlan2.reduivy__Study_Program__c)
        ];

        for(reduivy__Study_Program__c prog : programsToUpdate) {
            prog.reduivy__Auto_Unit_Recognition_Scope__c = SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES;
        }
        update programsToUpdate;

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        // Create TWO individual academic profiles for the same student
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

        insert newIpfMap.values();

        // Create individual program enrollments - one for each profile
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE1',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE1',
                student.Id,
                studyPlan1.reduivy__Study_Program__c,
                studyPlan1.Id,
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

        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE2',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE2',
                student.Id,
                studyPlan2.reduivy__Study_Program__c,
                studyPlan2.Id,
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

        insert newIpeMap.values();

        System.runAs(studentUser) {

            //Create individual enrollment for Profile1 with recognizable status/grade
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            reduivy__Individual_Enrollment__c ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                student.Id,
                sof.Id,
                'Completed',
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

            ien.reduivy__Grade_Result__c = 'Pass';

            try {
                insert ien;
                System.Assert.fail('Student user should not have permission to edit fields.');

            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, Insufficient READABLE access on following object(s) and field(s) - reduivy__Individual_Enrollment__c'), 'Unexpected error: ' + exp.getMessage());
            }
        }
    }
}