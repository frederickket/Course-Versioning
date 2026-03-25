/**
 * @author      WDCi (XW)
 * @date        June 2024
 * @group       Test
 * @description Test class for SEV_DeleteStudyEventRelations_EXE
 * @changehistory
 * ISS-001976 13-06-2024 XW - create new class
 */
@IsTest
public inherited sharing class SEV_DeleteStudyEventRelations_TEST{
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
            testFactory.initOfferingData(null);
            testFactory.initStudentData(SER_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for delete study event relation when study event is deleted
     */
    @IsTest
    static void testDeleteStudyEventRelationsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Event__c> studyEvents = [SELECT Id, Name
                                                     FROM reduivy__Study_Event__c
                                                     LIMIT 1];

        List<reduivy__Study_Event_Relation__c> studyEventRelations = [SELECT Id, Name
                                                                      FROM reduivy__Study_Event_Relation__c
                                                                      WHERE reduivy__Study_Event__c = :studyEvents[0].Id];

        System.Assert.areNotEqual(0, studyEventRelations.size(), 'Study Event Relations should not be empty');

        System.runAs(ADMIN_USER){
            try{
                delete studyEvents;

            } catch (System.DmlException dmlEx){

                System.Assert.fail('Admin should be able to delete Study Event Relations: ' + dmlEx.getMessage());
            } catch (Exception ex){
                System.Assert.fail('Something unexpected happened: ' + ex.getMessage());
            }
        }
    }

    /**
     * @description Test as student for delete study event relation when study event is deleted
     */
    @IsTest
    static void testDeleteStudyEventRelationsAsStudent(){

        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c
                                         FROM Contact
                                         WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT AND reduivy__Sample_Record_Code__c <> ''
                                         LIMIT 1];

        User studentUser = [SELECT Id, ContactId, ProfileId
                            FROM User
                            WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId IN:studentContacts
                            LIMIT 1];


        List<reduivy__Study_Event__c> studyEvents = [SELECT Id, Name
                                                     FROM reduivy__Study_Event__c
                                                     LIMIT 1];

        List<reduivy__Study_Event_Relation__c> studyEventRelations = [SELECT Id, Name
                                                                      FROM reduivy__Study_Event_Relation__c
                                                                      WHERE reduivy__Study_Event__c = :studyEvents[0].Id];

        System.Assert.areNotEqual(0, studyEventRelations.size(), 'Study Event Relations should not be empty');

        System.runAs(studentUser){
            Test.startTest();

            try{
                delete studyEvents;

                System.Assert.fail('Student should not be able to delete Study Event Relations');
            } catch (System.DmlException dmlEx){

                System.Assert.isTrue(dmlEx.getMessage().contains(READONLY_MSG), 'Student should not be able to delete Study Event Relations');
            } catch (Exception ex){
                System.Assert.fail('Something unexpected happened: ' + ex.getMessage());
            }


            Test.stopTest();


        }
    }

    /**
     * @description Test as faculty for delete study event relation when study event is deleted
     */
    @IsTest
    static void testDeleteStudyEventRelationsAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<reduivy__Study_Event__c> studyEvents = [SELECT Id, Name
                                                     FROM reduivy__Study_Event__c
                                                     LIMIT 1];

        List<reduivy__Study_Event_Relation__c> studyEventRelations = [SELECT Id, Name
                                                                      FROM reduivy__Study_Event_Relation__c
                                                                      WHERE reduivy__Study_Event__c = :studyEvents[0].Id];

        System.Assert.areNotEqual(0, studyEventRelations.size(), 'Study Event Relations should not be empty');

        System.runAs(FACULTY_USER){
            Test.startTest();

            try{
                delete studyEvents;
                System.Assert.fail('Faculty should not be able to delete Study Event Relations');
            } catch (System.DmlException dmlEx){
                System.Assert.isTrue(dmlEx.getMessage().contains(READONLY_MSG), 'Faculty should not be able to delete Study Event Relations');
            } catch (Exception ex){
                System.Assert.fail('Something unexpected happened: ' + ex.getMessage());
            }
            Test.stopTest();
        }
    }

}