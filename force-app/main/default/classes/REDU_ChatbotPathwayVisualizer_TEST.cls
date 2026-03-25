/**
 * @author      WDCi (XW)
 * @date        May 2024
 * @group       Test
 * @description Test class for Pathway Visualizer Controller
 * @changehistory
 * ISS-001917 20-05-2024 XW - Pathway Visualizer
 * ISS-002191 12-12-2024 XW - Test method is updated after LCTRL class is updated
 */
@IsTest
public inherited sharing class REDU_ChatbotPathwayVisualizer_TEST {
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

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

    /**
     * @description Test as admin for getting the pathway id and study program name based on the contact id
     *  and get the default study plan of the given study program id
     */
    @IsTest
    static void testForAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Plan__c> defaultStudyPlanList = [SELECT Id, reduivy__Study_Program__r.Name, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Default__c = true];

        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c
            FROM Contact
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT AND reduivy__Sample_Record_Code__c <> ''];

        
        System.runAs(ADMIN_USER){
            Test.startTest();

            
            REDU_LightningResponse response = REDU_ChatbotPathwayVisualizer_LCTRL.getPathwayIdAndProgramName(studentContacts[0].Id);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ChatbotPathwayVisualizer_TEST');
            response = REDU_ChatbotPathwayVisualizer_LCTRL.getPathwayIdAndProgramName(defaultStudyPlanList[0].reduivy__Study_Program__c);
            System.Assert.areEqual('[]', response.responseData, 'Shouldn\'t be getting response from REDU_ChatbotPathwayVisualizer_TEST');


            response = REDU_ChatbotPathwayVisualizer_LCTRL.getDefaultStudyPlan(defaultStudyPlanList[0].reduivy__Study_Program__c);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ChatbotPathwayVisualizer_TEST');
            response = REDU_ChatbotPathwayVisualizer_LCTRL.getDefaultStudyPlan(studentContacts[0].Id);
            System.Assert.areEqual('{"attributes":{"type":"reduivy__Study_Plan__c"}}', response.responseData, 'Shouldn\'t be getting response from REDU_ChatbotPathwayVisualizer_TEST');


            Test.stopTest();
        }
    }

    /**
     * @description Test as student for getting the pathway id and study program name based on the contact id
     *  and get the default study plan of the given study program id
     */
    @IsTest
    static void testForStudent(){

        List<reduivy__Study_Plan__c> defaultStudyPlanList = [SELECT Id, reduivy__Study_Program__r.Name, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Default__c = true];


        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c
            FROM Contact
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1];

        User studentUser = [SELECT Id, ContactId, ProfileId
            FROM User
            WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId IN:studentContacts
            LIMIT 1];

        System.runAs(studentUser){
            Test.startTest();
            REDU_LightningResponse response = REDU_ChatbotPathwayVisualizer_LCTRL.getPathwayIdAndProgramName(studentContacts[0].Id);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ChatbotPathwayVisualizer_TEST');
            response = REDU_ChatbotPathwayVisualizer_LCTRL.getPathwayIdAndProgramName(defaultStudyPlanList[0].reduivy__Study_Program__c);
            System.Assert.areEqual('[]', response.responseData, 'Shouldn\'t be getting response from REDU_ChatbotPathwayVisualizer_TEST');

            response = REDU_ChatbotPathwayVisualizer_LCTRL.getDefaultStudyPlan(defaultStudyPlanList[0].reduivy__Study_Program__c);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ChatbotPathwayVisualizer_TEST');
            response = REDU_ChatbotPathwayVisualizer_LCTRL.getDefaultStudyPlan(studentContacts[0].Id);
            System.Assert.areEqual('{"attributes":{"type":"reduivy__Study_Plan__c"}}', response.responseData, 'Shouldn\'t be getting response from REDU_ChatbotPathwayVisualizer_TEST');
            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for getting the pathway id and study program name based on the contact id
     *  and get the default study plan of the given study program id
     */
    @IsTest
    static void testForFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<reduivy__Study_Plan__c> defaultStudyPlanList = [SELECT Id, reduivy__Study_Program__r.Name, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Default__c = true];


        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c
            FROM Contact
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT AND reduivy__Sample_Record_Code__c <> ''];

        System.runAs(FACULTY_USER){
            Test.startTest();
            REDU_LightningResponse response = REDU_ChatbotPathwayVisualizer_LCTRL.getPathwayIdAndProgramName(studentContacts[0].Id);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ChatbotPathwayVisualizer_TEST');
            response = REDU_ChatbotPathwayVisualizer_LCTRL.getPathwayIdAndProgramName(defaultStudyPlanList[0].reduivy__Study_Program__c);
            System.Assert.areEqual('[]', response.responseData, 'Shouldn\'t be getting response from REDU_ChatbotPathwayVisualizer_TEST');

            response = REDU_ChatbotPathwayVisualizer_LCTRL.getDefaultStudyPlan(defaultStudyPlanList[0].reduivy__Study_Program__c);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ChatbotPathwayVisualizer_TEST');
            response = REDU_ChatbotPathwayVisualizer_LCTRL.getDefaultStudyPlan(studentContacts[0].Id);
            System.Assert.areEqual('{"attributes":{"type":"reduivy__Study_Plan__c"}}', response.responseData, 'Shouldn\'t be getting response from REDU_ChatbotPathwayVisualizer_TEST');
            Test.stopTest();
        }
    }

    /**
     * @description Test as setup user for getting the pathway id and study program name based on the contact id
     *  and get the default study plan of the given study program id
     *  will prompt an error since it has no permission to read the object and field
     */
    @IsTest
    static void testForSetupUser(){
        User SETUP_USER = testFactory.getSetupUser();

        List<reduivy__Study_Plan__c> defaultStudyPlanList = [SELECT Id, reduivy__Study_Program__r.Name, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Default__c = true];

        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c
            FROM Contact
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT AND reduivy__Sample_Record_Code__c <> ''];

        System.runAs(SETUP_USER){
            Test.startTest();
            REDU_LightningResponse response = null;
            try{
                 response = REDU_ChatbotPathwayVisualizer_LCTRL.getPathwayIdAndProgramName(studentContacts[0].Id);
            } catch (Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s) - reduivy__Individual_Program_Enrollment__c: Name, reduivy__Enrollment_Status__c, RecordTypeId. reduivy__Study_Program__c: Name, reduivy__Program_Code__c. reduivy__Study_Plan__c: Name'), 'Exception invalid: ' + exp.getMessage());
            }


            try{
                response = REDU_ChatbotPathwayVisualizer_LCTRL.getDefaultStudyPlan(defaultStudyPlanList[0].reduivy__Study_Program__c);
            } catch (Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s) - reduivy__Study_Plan__c: Name, reduivy__Default__c'), 'Exception invalid: ' + exp.getMessage());
            }
            Test.stopTest();
        }
    }

}