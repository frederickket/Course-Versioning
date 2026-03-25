/**
 * @author      WDCi (XiRouh)
 * @date        Feb 2025
 * @group       Term Student Enrollment
 * @description Test class for IPE_SetAutomaticEnrollmentStatus_EXE
 * @changehistory
 * ISS-002229 14-02-2025 XiRouh - new class
 */
@isTest
public inherited sharing class IPE_SetAutomaticEnrollmentStatus_TEST {
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String IPE_AUTO_STATUS = IPE_Helper.AUTO_ENROLLMENT_AUTO;
    static final String IPE_SKIPPEd_STATUS = IPE_Helper.AUTO_ENROLLMENT_SKIPPED;
    static final String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);
    static final String IPE_PREVIEW_STATUSES = IPE_Helper.getPreviewStatuses().get(0);
    static final String SPL_MAJOR = 'BACBIS_MajorA';
    static final String STUDY_INTAKE = 'SYDNEY_BACBIS_CYINTAKE';

    /**
     * @description Default method to setup required data for automated test
     */
    @TestSetup
    static void makeData(){

        // Create settings
		testFactory.setupDefaultSettings();

        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();
            testFactory.initMasterData(null);
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initStudentData(IAC_Helper.getApiName(), true);

            List<reduivy__Individual_Program_Enrollment__c> ipeToBeCreated = new List<reduivy__Individual_Program_Enrollment__c>();

            for (Contact student : testFactory.students.values()) {

                ipeToBeCreated.add(new reduivy__Individual_Program_Enrollment__c(
                    RecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId(), 
                    reduivy__Contact__c = student.Id, 
                    reduivy__Study_Program__c = testFactory.studyPlans.get(SPL_MAJOR).reduivy__Study_Program__c, 
                    reduivy__Study_Plan__c= testFactory.studyPlans.get(SPL_MAJOR).Id, 
                    reduivy__Study_Intake__c = testFactory.studyIntakes.get(STUDY_INTAKE).Id, 
                    reduivy__Starting_Term__c = testFactory.academicTerms.get('CYT1').Id, 
                    reduivy__Study_Pathway__c = testFactory.studyIntakes.get(STUDY_INTAKE).reduivy__Default_Study_Pathway__c, 
                    reduivy__Default_Campus__c = testFactory.campuses.get('SYDNEY').Id, 
                    reduivy__Class_Year__c = String.valueOf(testFactory.academicTerms.get('CYT1').reduivy__Start_Date__c.year()), 
                    reduivy__Class_Standing__c = 'Freshman', 
                    reduivy__Eligible_To_Enroll__c = false,
                    reduivy__Enrollment_Status__c = IPE_INPROGRESS_STATUS, 
                    reduivy__Auto_Enrollment__c = IPE_Helper.AUTO_ENROLLMENT_SKIPPED
                ));

                //only need one ipe to be create for reference
                break;
            }

            REDU_SystemMode_UTIL.doInsert(ipeToBeCreated);

            Test.stopTest();
        }
    }

    /**
     * @description Test executeBeforeInsert() as admin
     */
    @IsTest
    static void testExecuteBeforeInsertAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<reduivy__Individual_Program_Enrollment__c> ipe = [
            SELECT reduivy__Contact__c, reduivy__Study_Program__c, reduivy__Study_Plan__c, reduivy__Study_Intake__c, reduivy__Starting_Term__c, reduivy__Study_Pathway__c,
            reduivy__Default_Campus__c, reduivy__Class_Year__c, reduivy__Class_Standing__c
            FROM reduivy__Individual_Program_Enrollment__c 
            LIMIT 1];

        System.runAs(ADMIN_USER) {
            Test.startTest();

            List<reduivy__Individual_Program_Enrollment__c> ipeToBeCreated = new List<reduivy__Individual_Program_Enrollment__c>();

            ipeToBeCreated.add(new reduivy__Individual_Program_Enrollment__c(
                RecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId(), 
                reduivy__Contact__c = ipe[0].reduivy__Contact__c, 
                reduivy__Study_Program__c = ipe[0].reduivy__Study_Program__c, 
                reduivy__Study_Plan__c= ipe[0].reduivy__Study_Plan__c, 
                reduivy__Study_Intake__c = ipe[0].reduivy__Study_Intake__c, 
                reduivy__Starting_Term__c = ipe[0].reduivy__Starting_Term__c, 
                reduivy__Study_Pathway__c = ipe[0].reduivy__Study_Pathway__c, 
                reduivy__Default_Campus__c = ipe[0].reduivy__Default_Campus__c, 
                reduivy__Class_Year__c = ipe[0].reduivy__Class_Year__c, 
                reduivy__Class_Standing__c = 'Freshman', 
                reduivy__Eligible_To_Enroll__c = false,
                reduivy__Enrollment_Status__c = IPE_INPROGRESS_STATUS
            ));

            ipeToBeCreated.add(new reduivy__Individual_Program_Enrollment__c(
                RecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId(), 
                reduivy__Contact__c = ipe[0].reduivy__Contact__c, 
                reduivy__Study_Program__c = ipe[0].reduivy__Study_Program__c, 
                reduivy__Study_Plan__c= ipe[0].reduivy__Study_Plan__c, 
                reduivy__Study_Intake__c = ipe[0].reduivy__Study_Intake__c, 
                reduivy__Starting_Term__c = ipe[0].reduivy__Starting_Term__c, 
                reduivy__Study_Pathway__c = ipe[0].reduivy__Study_Pathway__c, 
                reduivy__Default_Campus__c = ipe[0].reduivy__Default_Campus__c, 
                reduivy__Class_Year__c = ipe[0].reduivy__Class_Year__c, 
                reduivy__Class_Standing__c = 'Freshman', 
                reduivy__Eligible_To_Enroll__c = true,
                reduivy__Enrollment_Status__c = IPE_INPROGRESS_STATUS
            ));

            REDU_SystemMode_UTIL.doInsert(ipeToBeCreated);

            String skippedStatus = IPE_Helper.AUTO_ENROLLMENT_SKIPPED;
            String autoStatus = IPE_Helper.AUTO_ENROLLMENT_AUTO;

            List<reduivy__Individual_Program_Enrollment__c> ipeList = [
            SELECT Id, reduivy__Eligible_To_Enroll__c, reduivy__Auto_Enrollment__c 
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE Id IN :ipeToBeCreated 
            ORDER BY reduivy__Eligible_To_Enroll__c
            ];

            System.Assert.areEqual(skippedStatus, ipeList[0].reduivy__Auto_Enrollment__c, 
                'Auto enrollment status should be skipped for ineligible enrollment');

            System.Assert.areEqual(autoStatus, ipeList[1].reduivy__Auto_Enrollment__c, 
                'Auto enrollment status should be auto for eligible enrollment');

            Test.stopTest();
        }
    }

    /**
     * @description Test executeBeforeInsert() as faculty
     */
    @IsTest
    static void testExecuteBeforeInsertAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<reduivy__Individual_Program_Enrollment__c> ipe = [
            SELECT reduivy__Contact__c, reduivy__Study_Program__c, reduivy__Study_Plan__c, reduivy__Study_Intake__c, reduivy__Starting_Term__c, reduivy__Study_Pathway__c,
            reduivy__Default_Campus__c, reduivy__Class_Year__c, reduivy__Class_Standing__c
            FROM reduivy__Individual_Program_Enrollment__c 
            LIMIT 1];

        System.runAs(FACULTY_USER) {
            Test.startTest();

            List<reduivy__Individual_Program_Enrollment__c> ipeToBeCreated = new List<reduivy__Individual_Program_Enrollment__c>();

            ipeToBeCreated.add(new reduivy__Individual_Program_Enrollment__c(
                RecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId(), 
                reduivy__Contact__c = ipe[0].reduivy__Contact__c, 
                reduivy__Study_Program__c = ipe[0].reduivy__Study_Program__c, 
                reduivy__Study_Plan__c= ipe[0].reduivy__Study_Plan__c, 
                reduivy__Study_Intake__c = ipe[0].reduivy__Study_Intake__c, 
                reduivy__Starting_Term__c = ipe[0].reduivy__Starting_Term__c, 
                reduivy__Study_Pathway__c = ipe[0].reduivy__Study_Pathway__c, 
                reduivy__Default_Campus__c = ipe[0].reduivy__Default_Campus__c, 
                reduivy__Class_Year__c = ipe[0].reduivy__Class_Year__c, 
                reduivy__Class_Standing__c = 'Freshman', 
                reduivy__Eligible_To_Enroll__c = false,
                reduivy__Enrollment_Status__c = IPE_PREVIEW_STATUSES
            ));

            ipeToBeCreated.add(new reduivy__Individual_Program_Enrollment__c(
                RecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId(), 
                reduivy__Contact__c = ipe[0].reduivy__Contact__c, 
                reduivy__Study_Program__c = ipe[0].reduivy__Study_Program__c, 
                reduivy__Study_Plan__c= ipe[0].reduivy__Study_Plan__c, 
                reduivy__Study_Intake__c = ipe[0].reduivy__Study_Intake__c, 
                reduivy__Starting_Term__c = ipe[0].reduivy__Starting_Term__c, 
                reduivy__Study_Pathway__c = ipe[0].reduivy__Study_Pathway__c, 
                reduivy__Default_Campus__c = ipe[0].reduivy__Default_Campus__c, 
                reduivy__Class_Year__c = ipe[0].reduivy__Class_Year__c, 
                reduivy__Class_Standing__c = 'Freshman', 
                reduivy__Eligible_To_Enroll__c = true,
                reduivy__Enrollment_Status__c = IPE_PREVIEW_STATUSES
            ));

            REDU_SystemMode_UTIL.doInsert(ipeToBeCreated);

            String skippedStatus = IPE_Helper.AUTO_ENROLLMENT_SKIPPED;
            String autoStatus = IPE_Helper.AUTO_ENROLLMENT_AUTO;

            List<reduivy__Individual_Program_Enrollment__c> ipeList = [
            SELECT Id, reduivy__Eligible_To_Enroll__c, reduivy__Auto_Enrollment__c 
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE Id IN :ipeToBeCreated 
            ORDER BY reduivy__Eligible_To_Enroll__c
            ];

            System.Assert.areEqual(skippedStatus, ipeList[0].reduivy__Auto_Enrollment__c, 
                'Auto enrollment status should be skipped for ineligible enrollment');

            System.Assert.areEqual(autoStatus, ipeList[1].reduivy__Auto_Enrollment__c, 
                'Auto enrollment status should be auto for eligible enrollment');

            Test.stopTest();
        }
    }

    /**
     * @description Test executeBeforeInsert() as student
     */
    @IsTest
    static void testExecuteBeforeInsertAsStudent(){
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Individual_Program_Enrollment__c> ipe = [
            SELECT reduivy__Contact__c, reduivy__Study_Program__c, reduivy__Study_Plan__c, reduivy__Study_Intake__c, reduivy__Starting_Term__c, reduivy__Study_Pathway__c,
            reduivy__Default_Campus__c, reduivy__Class_Year__c, reduivy__Class_Standing__c
            FROM reduivy__Individual_Program_Enrollment__c 
            LIMIT 1];

        System.runAs(reduStudent) {
            Test.startTest();

            List<reduivy__Individual_Program_Enrollment__c> ipeToBeCreated = new List<reduivy__Individual_Program_Enrollment__c>();

            ipeToBeCreated.add(new reduivy__Individual_Program_Enrollment__c(
                RecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId(), 
                reduivy__Contact__c = ipe[0].reduivy__Contact__c, 
                reduivy__Study_Program__c = ipe[0].reduivy__Study_Program__c, 
                reduivy__Study_Plan__c= ipe[0].reduivy__Study_Plan__c, 
                reduivy__Study_Intake__c = ipe[0].reduivy__Study_Intake__c, 
                reduivy__Starting_Term__c = ipe[0].reduivy__Starting_Term__c, 
                reduivy__Study_Pathway__c = ipe[0].reduivy__Study_Pathway__c, 
                reduivy__Default_Campus__c = ipe[0].reduivy__Default_Campus__c, 
                reduivy__Class_Year__c = ipe[0].reduivy__Class_Year__c, 
                reduivy__Class_Standing__c = 'Freshman', 
                reduivy__Eligible_To_Enroll__c = false,
                reduivy__Enrollment_Status__c = IPE_PREVIEW_STATUSES
            ));

            ipeToBeCreated.add(new reduivy__Individual_Program_Enrollment__c(
                RecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId(), 
                reduivy__Contact__c = ipe[0].reduivy__Contact__c, 
                reduivy__Study_Program__c = ipe[0].reduivy__Study_Program__c, 
                reduivy__Study_Plan__c= ipe[0].reduivy__Study_Plan__c, 
                reduivy__Study_Intake__c = ipe[0].reduivy__Study_Intake__c, 
                reduivy__Starting_Term__c = ipe[0].reduivy__Starting_Term__c, 
                reduivy__Study_Pathway__c = ipe[0].reduivy__Study_Pathway__c, 
                reduivy__Default_Campus__c = ipe[0].reduivy__Default_Campus__c, 
                reduivy__Class_Year__c = ipe[0].reduivy__Class_Year__c, 
                reduivy__Class_Standing__c = 'Freshman', 
                reduivy__Eligible_To_Enroll__c = true,
                reduivy__Enrollment_Status__c = IPE_PREVIEW_STATUSES
            ));

            REDU_SystemMode_UTIL.doInsert(ipeToBeCreated);

            String skippedStatus = IPE_Helper.AUTO_ENROLLMENT_SKIPPED;
            String autoStatus = IPE_Helper.AUTO_ENROLLMENT_AUTO;

            List<reduivy__Individual_Program_Enrollment__c> ipeList = [
            SELECT Id, reduivy__Eligible_To_Enroll__c, reduivy__Auto_Enrollment__c 
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE Id IN :ipeToBeCreated 
            ORDER BY reduivy__Eligible_To_Enroll__c
            ];

            System.Assert.areEqual(skippedStatus, ipeList[0].reduivy__Auto_Enrollment__c, 
                'Auto enrollment status should be skipped for ineligible enrollment');

            System.Assert.areEqual(autoStatus, ipeList[1].reduivy__Auto_Enrollment__c, 
                'Auto enrollment status should be auto for eligible enrollment');

            Test.stopTest();
        }
    }

    /**
     * @description Test executeBeforeUpdate() as admin
     */
    @IsTest
    static void testExecuteBeforeUpdateAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();

            String skippedStatus = IPE_Helper.AUTO_ENROLLMENT_SKIPPED;
            String autoStatus = IPE_Helper.AUTO_ENROLLMENT_AUTO;

            List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id, reduivy__Eligible_To_Enroll__c, reduivy__Auto_Enrollment__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];

            System.Assert.areEqual(skippedStatus, ipeList[0].reduivy__Auto_Enrollment__c, 'Auto enrollment status should be skipped');

            ipeList[0].reduivy__Eligible_To_Enroll__c = true;
            update ipeList;

            List<reduivy__Individual_Program_Enrollment__c> ipeListResult1 = [SELECT Id, reduivy__Eligible_To_Enroll__c, reduivy__Auto_Enrollment__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];
            System.Assert.areEqual(autoStatus, ipeListResult1[0].reduivy__Auto_Enrollment__c, 'Auto enrollment status should be auto');

            ipeListResult1[0].reduivy__Eligible_To_Enroll__c = false;
            update ipeListResult1;

            List<reduivy__Individual_Program_Enrollment__c> ipeListResult2 = [SELECT Id, reduivy__Eligible_To_Enroll__c, reduivy__Auto_Enrollment__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];
            System.Assert.areEqual(skippedStatus, ipeListResult2[0].reduivy__Auto_Enrollment__c, 'Auto enrollment status should be skipped');
        
            Test.stopTest();
        }
    }

    /**
     * @description Test executeBeforeUpdate() as faculty
     */
    @IsTest
    static void testExecuteBeforeUpdateAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER) {
            Test.startTest();

            String skippedStatus = IPE_Helper.AUTO_ENROLLMENT_SKIPPED;
            String autoStatus = IPE_Helper.AUTO_ENROLLMENT_AUTO;

            List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id, reduivy__Eligible_To_Enroll__c, reduivy__Auto_Enrollment__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];

            System.Assert.areEqual(skippedStatus, ipeList[0].reduivy__Auto_Enrollment__c, 'Auto enrollment status should be skipped');

            ipeList[0].reduivy__Eligible_To_Enroll__c = true;
            update ipeList;

            List<reduivy__Individual_Program_Enrollment__c> ipeListResult1 = [SELECT Id, reduivy__Eligible_To_Enroll__c, reduivy__Auto_Enrollment__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];
            System.Assert.areEqual(autoStatus, ipeListResult1[0].reduivy__Auto_Enrollment__c, 'Auto enrollment status should be auto');

            ipeListResult1[0].reduivy__Eligible_To_Enroll__c = false;
            update ipeListResult1;

            List<reduivy__Individual_Program_Enrollment__c> ipeListResult2 = [SELECT Id, reduivy__Eligible_To_Enroll__c, reduivy__Auto_Enrollment__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];
            System.Assert.areEqual(skippedStatus, ipeListResult2[0].reduivy__Auto_Enrollment__c, 'Auto enrollment status should be skipped');
        
            Test.stopTest();
        }
    }

    /**
     * @description Test executeBeforeUpdate() as student
     */
    @IsTest
    static void testExecuteBeforeUpdateAsStudent(){
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        System.runAs(reduStudent) {
            Test.startTest();

            String skippedStatus = IPE_Helper.AUTO_ENROLLMENT_SKIPPED;
            String autoStatus = IPE_Helper.AUTO_ENROLLMENT_AUTO;

            List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id, reduivy__Eligible_To_Enroll__c, reduivy__Auto_Enrollment__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];

            System.Assert.areEqual(skippedStatus, ipeList[0].reduivy__Auto_Enrollment__c, 'Auto enrollment status should be skipped');

            ipeList[0].reduivy__Eligible_To_Enroll__c = true;
            update ipeList;

            List<reduivy__Individual_Program_Enrollment__c> ipeListResult1 = [SELECT Id, reduivy__Eligible_To_Enroll__c, reduivy__Auto_Enrollment__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];
            System.Assert.areEqual(autoStatus, ipeListResult1[0].reduivy__Auto_Enrollment__c, 'Auto enrollment status should be auto');

            ipeListResult1[0].reduivy__Eligible_To_Enroll__c = false;
            update ipeListResult1;

            List<reduivy__Individual_Program_Enrollment__c> ipeListResult2 = [SELECT Id, reduivy__Eligible_To_Enroll__c, reduivy__Auto_Enrollment__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];
            System.Assert.areEqual(skippedStatus, ipeListResult2[0].reduivy__Auto_Enrollment__c, 'Auto enrollment status should be skipped');
        
            Test.stopTest();
        }
    }
}