/**
 * @author      WDCi (XW)
 * @date        June 2024
 * @group       Test
 * @description Test class for SSE_DeleteSessionTimes_EXE
 * @changehistory
 * ISS-001976 14-06-2024 XW - create new class
 */
@IsTest
public inherited sharing class SSE_DeleteSessionTimes_TEST{
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static String READONLY_MSG = 'INSUFFICIENT_ACCESS_OR_READONLY';
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
            testFactory.initOfferingData(SST_Helper.getApiName());
            testFactory.initStudentData(ISN_Helper.getApiName(),true);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for delete study session time when study session is deleted
     */
    @IsTest
    static void testDeleteSessionTimesWithSessionEnrollmentAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Session__c> sseList = [SELECT Id, Name
                                                   FROM reduivy__Study_Session__c
                                                   LIMIT 1];

        List<reduivy__Study_Session_Time__c> sstList = [SELECT Id, Name
                                                        FROM reduivy__Study_Session_Time__c
                                                        WHERE reduivy__Study_Session__c IN:sseList];

        System.Assert.areNotEqual(0, sstList.size(), 'Study Session Time should not be empty');

        System.runAs(ADMIN_USER){
            Test.startTest();

            try{
                delete sseList;

                System.Assert.fail('The session should not be deleted as there are related individual session enrollments.');
            } catch (Exception ex){
                System.Assert.isTrue(ex.getMessage().contains('This record can\'t be deleted because it has one or more related records'), 'The exception is: ' + ex.getMessage());
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for delete study session time when study session is deleted
     */
    @IsTest
    static void testDeleteSessionTimesWithoutSessionEnrollmentAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Session__c> sseList = [SELECT Id, Name
                                                   FROM reduivy__Study_Session__c
                                                   LIMIT 1];

        List<reduivy__Study_Session_Time__c> sstList = [SELECT Id, Name
                                                        FROM reduivy__Study_Session_Time__c
                                                        WHERE reduivy__Study_Session__c IN:sseList];

        System.Assert.areNotEqual(0, sstList.size(), 'Study Session Time should not be empty');

        System.runAs(ADMIN_USER){
            Test.startTest();

            try{
                delete [SELECT Id FROM reduivy__Individual_Session_Enrollment__c WHERE reduivy__Study_Session__c IN: sseList];
                delete sseList;

            } catch (Exception ex){
                System.Assert.fail(ex.getMessage());
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as student for delete study session time when study session is deleted
     */
    @IsTest
    static void testDeleteSessionTimesAsStudent(){

        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c
                                         FROM Contact
                                         WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT AND reduivy__Sample_Record_Code__c <> ''
                                         LIMIT 1];

        User studentUser = [SELECT Id, ContactId, ProfileId
                            FROM User
                            WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId IN:studentContacts
                            LIMIT 1];

        List<reduivy__Study_Session__c> sseList = [SELECT Id, Name
                                                   FROM reduivy__Study_Session__c
                                                   LIMIT 1];

        List<reduivy__Study_Session_Time__c> sstList = [SELECT Id, Name
                                                        FROM reduivy__Study_Session_Time__c
                                                        WHERE reduivy__Study_Session__c IN:sseList];

        System.Assert.areNotEqual(0, sstList.size(), 'Study Session Time should not be empty');

        System.runAs(studentUser){
            Test.startTest();

            try{
                delete sseList;
                System.Assert.fail('Student should not be able to delete Study Session');
            } catch (System.DmlException dmlEx){
                System.Assert.isTrue(dmlEx.getMessage().contains(READONLY_MSG), 'Student should not be able to delete Study Event Study Session');
            } catch (Exception ex){
                System.Assert.fail('Something unexpected happened: ' + ex.getMessage());
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for delete study session time when study session is deleted
     */
    @IsTest
    static void testDeleteSessionTimesAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c
                                         FROM Contact
                                         WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT AND reduivy__Sample_Record_Code__c <> ''];

        List<reduivy__Study_Session__c> sseList = [SELECT Id, Name
                                                   FROM reduivy__Study_Session__c
                                                   LIMIT 1];

        List<reduivy__Study_Session_Time__c> sstList = [SELECT Id, Name
                                                        FROM reduivy__Study_Session_Time__c
                                                        WHERE reduivy__Study_Session__c IN:sseList];

        System.Assert.areNotEqual(0, sstList.size(), 'Study Session Time should not be empty');
        System.runAs(FACULTY_USER){
            Test.startTest();

            try{
                delete sseList;
                System.Assert.fail('Faculty should not be able to delete Study Session');
            } catch (System.DmlException dmlEx){
                System.Assert.isTrue(dmlEx.getMessage().contains(READONLY_MSG), 'Faculty should not be able to delete Study Event Study Session');
            } catch (Exception ex){
                System.Assert.fail('Something unexpected happened: ' + ex.getMessage());
            }

            Test.stopTest();
        }
    }

}