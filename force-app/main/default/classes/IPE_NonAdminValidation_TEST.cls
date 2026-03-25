/**
 * @author      WDCi (Lean)
 * @date        Oct 2024
 * @group       Test
 * @description Test class for IPE_NonAdminValidation_EXE
 * @changehistory
 * ISS-002148 24-10-2024 Lean - New class
 */
@IsTest
public inherited sharing class IPE_NonAdminValidation_TEST {
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final Id IPE_MASTER_RTID = IPE_Helper.getMasterEnrollmentRecordTypeId();

    /**
     * @description Default method to setup required data for automated test
     */
    @TestSetup
    static void makeData(){

        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER){
            Test.startTest();

            testFactory.initMasterData(SPL_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    @IsTest
    static void testIpeCreateSuccessAsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        System.runAs(studentUser) {
            reduivy__Study_Plan__c studyPlan = [SELECT Id, 
                reduivy__Study_Program__c 
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Default__c = TRUE 
                AND reduivy__Status__c =: SPL_Helper.STATUS_ACTIVE
                LIMIT 1
            ];

            reduivy__Individual_Program_Enrollment__c newIpe = new reduivy__Individual_Program_Enrollment__c(
                RecordTypeId = IPE_MASTER_RTID,
                reduivy__Contact__c = studentUser.ContactId,
                reduivy__Study_Program__c = studyPlan.reduivy__Study_Program__c,
                reduivy__Study_Plan__c = studyPlan.Id,
                reduivy__Enrollment_Status__c = IPE_Helper.getPreviewStatuses().get(0)
            );

            try {
                REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{newIpe});
                
            } catch (Exception exp) {
                System.Assert.fail('This should not fail. Error: ' + exp.getMessage());
            }
        }
        
        Test.stopTest();
    }

    @IsTest
    static void testIpeCreateFailAsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        System.runAs(studentUser) {
            reduivy__Study_Plan__c studyPlan = [SELECT Id, 
                reduivy__Study_Program__c 
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Default__c = TRUE 
                AND reduivy__Status__c =: SPL_Helper.STATUS_ACTIVE
                LIMIT 1
            ];

            reduivy__Individual_Program_Enrollment__c newIpe = new reduivy__Individual_Program_Enrollment__c(
                RecordTypeId = IPE_MASTER_RTID,
                reduivy__Contact__c = studentUser.ContactId,
                reduivy__Study_Program__c = studyPlan.reduivy__Study_Program__c,
                reduivy__Study_Plan__c = studyPlan.Id,
                reduivy__Enrollment_Status__c = IPE_Helper.getInProgressStatuses().get(0)
            );

            try {
                REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{newIpe});
                System.Assert.fail('This should fail.');

            } catch (Exception exp) {
                String expectedError = String.format(Label.Creation_Disallowed_Error, new List<String>{IPE_Helper.getObjectLabel()});
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Invalid error: ' + exp.getMessage());
            }
        }
        
        Test.stopTest();
    }

    @IsTest
    static void testIpeUpdateSuccessAsStudent() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        System.runAs(ADMIN_USER) {
            reduivy__Study_Plan__c studyPlan = [SELECT Id, 
                reduivy__Study_Program__c 
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Default__c = TRUE 
                AND reduivy__Status__c =: SPL_Helper.STATUS_ACTIVE
                LIMIT 1
            ];

            reduivy__Individual_Program_Enrollment__c newIpe = new reduivy__Individual_Program_Enrollment__c(
                RecordTypeId = IPE_MASTER_RTID,
                reduivy__Contact__c = studentUser.ContactId,
                reduivy__Study_Program__c = studyPlan.reduivy__Study_Program__c,
                reduivy__Study_Plan__c = studyPlan.Id,
                reduivy__Enrollment_Status__c = IPE_Helper.getPreviewStatuses().get(0)
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{newIpe});
        }
        
        System.runAs(studentUser) {
            reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
                Name  
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE reduivy__Contact__c =: studentUser.ContactId
            ];

            try {
                REDU_Database_UTIL.doUpdate(new List<reduivy__Individual_Program_Enrollment__c>{ipe});
                
            } catch (Exception exp) {
                System.Assert.fail('This should not fail. Error: ' + exp.getMessage());
            }
        }

        Test.stopTest();

    }

    @IsTest
    static void testIpeUpdateFailAsStudent() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        System.runAs(ADMIN_USER) {
            reduivy__Study_Plan__c studyPlan = [SELECT Id, 
                reduivy__Study_Program__c 
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Default__c = TRUE 
                AND reduivy__Status__c =: SPL_Helper.STATUS_ACTIVE
                LIMIT 1
            ];

            reduivy__Individual_Program_Enrollment__c newIpe = new reduivy__Individual_Program_Enrollment__c(
                RecordTypeId = IPE_MASTER_RTID,
                reduivy__Contact__c = studentUser.ContactId,
                reduivy__Study_Program__c = studyPlan.reduivy__Study_Program__c,
                reduivy__Study_Plan__c = studyPlan.Id,
                reduivy__Enrollment_Status__c = IPE_Helper.getInProgressStatuses().get(0)
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{newIpe});
        }
        
        System.runAs(studentUser) {

            reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
                Name 
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE reduivy__Contact__c =: studentUser.ContactId
            ];

            try {
                ipe.reduivy__Enrollment_Status__c = IPE_Helper.getCompletedStatuses().get(0);
                REDU_Database_UTIL.doUpdate(new List<reduivy__Individual_Program_Enrollment__c>{ipe});
                System.Assert.fail('This should fail.');

            } catch (Exception exp) {
                String expectedError = String.format(Label.Updation_Disallowed_Error, new List<String>{IPE_Helper.getObjectLabel(), ipe.Name});
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Invalid error: ' + exp.getMessage());
            }
        }

        Test.stopTest();

    }

    @IsTest
    static void testIpeDeleteFailAsStudent() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        System.runAs(ADMIN_USER) {
            reduivy__Study_Plan__c studyPlan = [SELECT Id, 
                reduivy__Study_Program__c 
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Default__c = TRUE 
                AND reduivy__Status__c =: SPL_Helper.STATUS_ACTIVE
                LIMIT 1
            ];

            reduivy__Individual_Program_Enrollment__c newIpe = new reduivy__Individual_Program_Enrollment__c(
                RecordTypeId = IPE_MASTER_RTID,
                reduivy__Contact__c = studentUser.ContactId,
                reduivy__Study_Program__c = studyPlan.reduivy__Study_Program__c,
                reduivy__Study_Plan__c = studyPlan.Id,
                reduivy__Enrollment_Status__c = IPE_Helper.getDraftStatuses().get(0)
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{newIpe});
        }
        
        System.runAs(studentUser) {

            reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
                Name 
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE reduivy__Contact__c =: studentUser.ContactId
            ];

            try {
                REDU_SystemMode_UTIL.doDelete(new List<reduivy__Individual_Program_Enrollment__c>{ipe});
                System.Assert.fail('This should fail.');

            } catch (Exception exp) {
                String expectedError = String.format(Label.Deletion_Disallowed_Error, new List<String>{IPE_Helper.getObjectLabel(), ipe.Name});
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Invalid error: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    @IsTest
    static void testIpeCreateSuccessAsFaculty() {

        User studentUser = testFactory.getStudentUser();
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Plan__c studyPlan = [SELECT Id, 
                reduivy__Study_Program__c 
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Default__c = TRUE 
                AND reduivy__Status__c =: SPL_Helper.STATUS_ACTIVE
                LIMIT 1
            ];

            reduivy__Individual_Program_Enrollment__c newIpe = new reduivy__Individual_Program_Enrollment__c(
                RecordTypeId = IPE_MASTER_RTID,
                reduivy__Contact__c = studentUser.ContactId,
                reduivy__Study_Program__c = studyPlan.reduivy__Study_Program__c,
                reduivy__Study_Plan__c = studyPlan.Id,
                reduivy__Enrollment_Status__c = IPE_Helper.getPreviewStatuses().get(0)
            );

            try {
                REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{newIpe});
                
            } catch (Exception exp) {
                System.Assert.fail('This should not fail. Error: ' + exp.getMessage());
            }
        }
        
        Test.stopTest();
    }

    @IsTest
    static void testIpeCreateFailAsFaculty() {

        User studentUser = testFactory.getStudentUser();
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Plan__c studyPlan = [SELECT Id, 
                reduivy__Study_Program__c 
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Default__c = TRUE 
                AND reduivy__Status__c =: SPL_Helper.STATUS_ACTIVE
                LIMIT 1
            ];

            reduivy__Individual_Program_Enrollment__c newIpe = new reduivy__Individual_Program_Enrollment__c(
                RecordTypeId = IPE_MASTER_RTID,
                reduivy__Contact__c = studentUser.ContactId,
                reduivy__Study_Program__c = studyPlan.reduivy__Study_Program__c,
                reduivy__Study_Plan__c = studyPlan.Id,
                reduivy__Enrollment_Status__c = IPE_Helper.getInProgressStatuses().get(0)
            );

            try {
                REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{newIpe});
                System.Assert.fail('This should fail.');

            } catch (Exception exp) {
                String expectedError = String.format(Label.Creation_Disallowed_Error, new List<String>{IPE_Helper.getObjectLabel()});
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Invalid error: ' + exp.getMessage());
            }
        }
        
        Test.stopTest();
    }

    @IsTest
    static void testIpeUpdateSuccessAsFaculty() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        User FACULTY_USER = testFactory.getReduFacultyUser();
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        System.runAs(ADMIN_USER) {
            reduivy__Study_Plan__c studyPlan = [SELECT Id, 
                reduivy__Study_Program__c 
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Default__c = TRUE 
                AND reduivy__Status__c =: SPL_Helper.STATUS_ACTIVE
                LIMIT 1
            ];

            reduivy__Individual_Program_Enrollment__c newIpe = new reduivy__Individual_Program_Enrollment__c(
                RecordTypeId = IPE_MASTER_RTID,
                reduivy__Contact__c = studentUser.ContactId,
                reduivy__Study_Program__c = studyPlan.reduivy__Study_Program__c,
                reduivy__Study_Plan__c = studyPlan.Id,
                reduivy__Enrollment_Status__c = IPE_Helper.getPreviewStatuses().get(0)
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{newIpe});
        }
        
        System.runAs(FACULTY_USER) {
            reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
                Name  
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE reduivy__Contact__c =: studentUser.ContactId
            ];

            try {
                REDU_Database_UTIL.doUpdate(new List<reduivy__Individual_Program_Enrollment__c>{ipe});
                
            } catch (Exception exp) {
                System.Assert.fail('This should not fail. Error: ' + exp.getMessage());
            }
        }

        Test.stopTest();

    }

    @IsTest
    static void testIpeUpdateFailAsFaculty() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        User FACULTY_USER = testFactory.getReduFacultyUser();
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        System.runAs(ADMIN_USER) {
            reduivy__Study_Plan__c studyPlan = [SELECT Id, 
                reduivy__Study_Program__c 
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Default__c = TRUE 
                AND reduivy__Status__c =: SPL_Helper.STATUS_ACTIVE
                LIMIT 1
            ];

            reduivy__Individual_Program_Enrollment__c newIpe = new reduivy__Individual_Program_Enrollment__c(
                RecordTypeId = IPE_MASTER_RTID,
                reduivy__Contact__c = studentUser.ContactId,
                reduivy__Study_Program__c = studyPlan.reduivy__Study_Program__c,
                reduivy__Study_Plan__c = studyPlan.Id,
                reduivy__Enrollment_Status__c = IPE_Helper.getInProgressStatuses().get(0)
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{newIpe});
        }
        
        System.runAs(FACULTY_USER) {

            reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
                Name 
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE reduivy__Contact__c =: studentUser.ContactId
            ];

            try {
                ipe.reduivy__Enrollment_Status__c = IPE_Helper.getCompletedStatuses().get(0);
                REDU_Database_UTIL.doUpdate(new List<reduivy__Individual_Program_Enrollment__c>{ipe});
                System.Assert.fail('This should fail.');

            } catch (Exception exp) {
                String expectedError = String.format(Label.Updation_Disallowed_Error, new List<String>{IPE_Helper.getObjectLabel(), ipe.Name});
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Invalid error: ' + exp.getMessage());
            }
        }

        Test.stopTest();

    }

    @IsTest
    static void testIpeDeleteFailAsFaculty() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        User FACULTY_USER = testFactory.getReduFacultyUser();
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        System.runAs(ADMIN_USER) {
            reduivy__Study_Plan__c studyPlan = [SELECT Id, 
                reduivy__Study_Program__c 
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Default__c = TRUE 
                AND reduivy__Status__c =: SPL_Helper.STATUS_ACTIVE
                LIMIT 1
            ];

            reduivy__Individual_Program_Enrollment__c newIpe = new reduivy__Individual_Program_Enrollment__c(
                RecordTypeId = IPE_MASTER_RTID,
                reduivy__Contact__c = studentUser.ContactId,
                reduivy__Study_Program__c = studyPlan.reduivy__Study_Program__c,
                reduivy__Study_Plan__c = studyPlan.Id,
                reduivy__Enrollment_Status__c = IPE_Helper.getDraftStatuses().get(0)
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Individual_Program_Enrollment__c>{newIpe});
        }
        
        System.runAs(FACULTY_USER) {

            reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
                Name 
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE reduivy__Contact__c =: studentUser.ContactId
            ];

            try {
                REDU_SystemMode_UTIL.doDelete(new List<reduivy__Individual_Program_Enrollment__c>{ipe});
                System.Assert.fail('This should fail.');

            } catch (Exception exp) {
                String expectedError = String.format(Label.Deletion_Disallowed_Error, new List<String>{IPE_Helper.getObjectLabel(), ipe.Name});
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Invalid error: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

}