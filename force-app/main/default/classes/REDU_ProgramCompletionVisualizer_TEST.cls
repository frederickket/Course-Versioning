/**
 * @author      WDCi (XW)
 * @date        May 2024
 * @group       Test
 * @description Test class for Program Completion Visualizer Result. With or without preview Ipe use case will be check 
 * @changehistory
 * ISS-001916 20-5-2024 name - Program Completion Visualizer
 */
@IsTest
public inherited sharing class REDU_ProgramCompletionVisualizer_TEST {
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
            testFactory.initOfferingData(SOF_Helper.getApiName());
            testFactory.initStudentData(IPE_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for creating Ipe without an existing Ipe
     */
    @IsTest
    static void testForAdminWithoutExistingIpe(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c
                                         FROM Contact
                                         WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT AND reduivy__Sample_Record_Code__c <> ''];

        List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id, reduivy__Contact__r.Id, reduivy__Study_Program__c, reduivy__Study_Plan__c
                                                                   FROM reduivy__Individual_Program_Enrollment__c
                                                                   WHERE reduivy__Contact__r.Id = :studentContacts[0].Id];

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse response = REDU_ProgramCompletionVisualizer_LCTRL.deleteExisitingPreviewIpe(studentContacts[0].Id);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ProgramCompletionVisualizer_TEST');
            System.Assert.areEqual('[]', response.responseData, 'Shouldn\'t be getting any response from REDU_ProgramCompletionVisualizer_TEST');


            response = REDU_ProgramCompletionVisualizer_LCTRL.createPreviewIpe(ipeList[0].reduivy__Contact__r.Id, ipeList[0].reduivy__Study_Program__c, ipeList[0].reduivy__Study_Plan__c);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ProgramCompletionVisualizer_TEST');
            System.Assert.areNotEqual('', response.responseData, 'Should be getting any response from REDU_ProgramCompletionVisualizer_TEST');
            Map<String, Object> firstMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            String ipeIdWillBeDeleted = (String) firstMap.get('Id');

            response = REDU_ProgramCompletionVisualizer_LCTRL.deletePreviewIpe(ipeIdWillBeDeleted);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ProgramCompletionVisualizer_TEST');
            System.Assert.areNotEqual('', response.responseData, 'Should be getting any response from REDU_ProgramCompletionVisualizer_TEST');

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for creating Ipe with an existing Ipe
     */
    @IsTest
    static void testForAdminWithExistingIpe(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c
                                         FROM Contact
                                         WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT AND reduivy__Sample_Record_Code__c <> ''];

        List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id, reduivy__Contact__r.Id, reduivy__Study_Program__c, reduivy__Study_Plan__c
                                                                   FROM reduivy__Individual_Program_Enrollment__c
                                                                   WHERE reduivy__Contact__r.Id = :studentContacts[0].Id];

        System.runAs(ADMIN_USER){

            REDU_ProgramCompletionVisualizer_LCTRL.createPreviewIpe(ipeList[0].reduivy__Contact__r.Id, ipeList[0].reduivy__Study_Program__c, ipeList[0].reduivy__Study_Plan__c);

            Test.startTest();

            REDU_LightningResponse response = REDU_ProgramCompletionVisualizer_LCTRL.deleteExisitingPreviewIpe(studentContacts[0].Id);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ProgramCompletionVisualizer_TEST');
            System.Assert.areNotEqual('[]', response.responseData, 'Should be getting any response from REDU_ProgramCompletionVisualizer_TEST');


            response = REDU_ProgramCompletionVisualizer_LCTRL.createPreviewIpe(ipeList[0].reduivy__Contact__r.Id, ipeList[0].reduivy__Study_Program__c, ipeList[0].reduivy__Study_Plan__c);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ProgramCompletionVisualizer_TEST');
            System.Assert.areNotEqual('', response.responseData, 'Should be getting any response from REDU_ProgramCompletionVisualizer_TEST');
            Map<String, Object> firstMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            String ipeIdWillBeDeleted = (String) firstMap.get('Id');

            response = REDU_ProgramCompletionVisualizer_LCTRL.deletePreviewIpe(ipeIdWillBeDeleted);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ProgramCompletionVisualizer_TEST');
            System.Assert.areNotEqual('', response.responseData, 'Should be getting any response from REDU_ProgramCompletionVisualizer_TEST');

            Test.stopTest();
        }
    }

    /**
     * @description Test as student for creating Ipe without an existing Ipe
     */
    @IsTest
    static void testForStudentWithExistingIpe(){

        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c
                                         FROM Contact
                                         WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT AND reduivy__Sample_Record_Code__c <> ''
                                         LIMIT 1];

        List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id, reduivy__Contact__r.Id, reduivy__Study_Program__c, reduivy__Study_Plan__c
                                                                   FROM reduivy__Individual_Program_Enrollment__c
                                                                   WHERE reduivy__Contact__r.Id = :studentContacts[0].Id];

        User studentUser = [SELECT Id, ContactId, ProfileId
                            FROM User
                            WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId IN:studentContacts
                            LIMIT 1];

        System.runAs(studentUser){

            REDU_ProgramCompletionVisualizer_LCTRL.createPreviewIpe(ipeList[0].reduivy__Contact__r.Id, ipeList[0].reduivy__Study_Program__c, ipeList[0].reduivy__Study_Plan__c);

            Test.startTest();

            REDU_LightningResponse response = REDU_ProgramCompletionVisualizer_LCTRL.deleteExisitingPreviewIpe(studentContacts[0].Id);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ProgramCompletionVisualizer_TEST');
            System.Assert.areNotEqual('[]', response.responseData, 'Should be getting any response from REDU_ProgramCompletionVisualizer_TEST');


            response = REDU_ProgramCompletionVisualizer_LCTRL.createPreviewIpe(ipeList[0].reduivy__Contact__r.Id, ipeList[0].reduivy__Study_Program__c, ipeList[0].reduivy__Study_Plan__c);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ProgramCompletionVisualizer_TEST');
            System.Assert.areNotEqual('', response.responseData, 'Should be getting any response from REDU_ProgramCompletionVisualizer_TEST');
            Map<String, Object> firstMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            String ipeIdWillBeDeleted = (String) firstMap.get('Id');

            response = REDU_ProgramCompletionVisualizer_LCTRL.deletePreviewIpe(ipeIdWillBeDeleted);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ProgramCompletionVisualizer_TEST');
            System.Assert.areNotEqual('', response.responseData, 'Should be getting any response from REDU_ProgramCompletionVisualizer_TEST');

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for creating Ipe without an existing Ipe
     */
    @IsTest
    static void testForFacultyWithoutExistingIpe(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c
                                         FROM Contact
                                         WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT AND reduivy__Sample_Record_Code__c <> ''];

        List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id, reduivy__Contact__r.Id, reduivy__Study_Program__c, reduivy__Study_Plan__c
                                                                   FROM reduivy__Individual_Program_Enrollment__c
                                                                   WHERE reduivy__Contact__r.Id = :studentContacts[0].Id];

        System.runAs(FACULTY_USER){

            Test.startTest();

            REDU_LightningResponse response = REDU_ProgramCompletionVisualizer_LCTRL.deleteExisitingPreviewIpe(studentContacts[0].Id);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ProgramCompletionVisualizer_TEST');
            System.Assert.areEqual('[]', response.responseData, 'Shouldn\'t be getting any response from REDU_ProgramCompletionVisualizer_TEST');


            response = REDU_ProgramCompletionVisualizer_LCTRL.createPreviewIpe(ipeList[0].reduivy__Contact__r.Id, ipeList[0].reduivy__Study_Program__c, ipeList[0].reduivy__Study_Plan__c);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ProgramCompletionVisualizer_TEST');
            System.Assert.areNotEqual('', response.responseData, 'Should be getting any response from REDU_ProgramCompletionVisualizer_TEST');
            Map<String, Object> firstMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            String ipeIdWillBeDeleted = (String) firstMap.get('Id');

            response = REDU_ProgramCompletionVisualizer_LCTRL.deletePreviewIpe(ipeIdWillBeDeleted);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ProgramCompletionVisualizer_TEST');
            System.Assert.areNotEqual('', response.responseData, 'Should be getting any response from REDU_ProgramCompletionVisualizer_TEST');

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for creating Ipe with an existing Ipe
     */
    @IsTest
    static void testForFacultyWithExistingIpe(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c
                                         FROM Contact
                                         WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT AND reduivy__Sample_Record_Code__c <> ''];

        List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id, reduivy__Contact__r.Id, reduivy__Study_Program__c, reduivy__Study_Plan__c
                                                                   FROM reduivy__Individual_Program_Enrollment__c
                                                                   WHERE reduivy__Contact__r.Id = :studentContacts[0].Id];

        System.runAs(FACULTY_USER){
            REDU_ProgramCompletionVisualizer_LCTRL.createPreviewIpe(ipeList[0].reduivy__Contact__r.Id, ipeList[0].reduivy__Study_Program__c, ipeList[0].reduivy__Study_Plan__c);

            Test.startTest();

            REDU_LightningResponse response = REDU_ProgramCompletionVisualizer_LCTRL.deleteExisitingPreviewIpe(studentContacts[0].Id);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ProgramCompletionVisualizer_TEST');
            System.Assert.areNotEqual('[]', response.responseData, 'Should be getting any response from REDU_ProgramCompletionVisualizer_TEST');


            response = REDU_ProgramCompletionVisualizer_LCTRL.createPreviewIpe(ipeList[0].reduivy__Contact__r.Id, ipeList[0].reduivy__Study_Program__c, ipeList[0].reduivy__Study_Plan__c);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ProgramCompletionVisualizer_TEST');
            System.Assert.areNotEqual('', response.responseData, 'Should be getting any response from REDU_ProgramCompletionVisualizer_TEST');
            Map<String, Object> firstMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            String ipeIdWillBeDeleted = (String) firstMap.get('Id');

            response = REDU_ProgramCompletionVisualizer_LCTRL.deletePreviewIpe(ipeIdWillBeDeleted);
            System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ProgramCompletionVisualizer_TEST');
            System.Assert.areNotEqual('', response.responseData, 'Should be getting any response from REDU_ProgramCompletionVisualizer_TEST');

            Test.stopTest();
        }
    }

    /**
     * @description Test as setup user for creating Ipe with an existing Ipe.
     */
    @IsTest
    static void testForSetupUserWithExistingIpe(){
        User SETUP_USER = testFactory.getSetupUser();
        USER ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c
                                         FROM Contact
                                         WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT AND reduivy__Sample_Record_Code__c <> ''];

        List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id, reduivy__Contact__r.Id, reduivy__Study_Program__c, reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Contact__r.Id = :studentContacts[0].Id
        ];

        reduivy__Individual_Program_Enrollment__c previewIpe;
        System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_ProgramCompletionVisualizer_LCTRL.createPreviewIpe(ipeList[0].reduivy__Contact__r.Id, ipeList[0].reduivy__Study_Program__c, ipeList[0].reduivy__Study_Plan__c);
            previewIpe = (reduivy__Individual_Program_Enrollment__c) JSON.deserialize(response.responseData, reduivy__Individual_Program_Enrollment__c.class);
        }

        System.runAs(SETUP_USER){
            Test.startTest();

            try {
                REDU_LightningResponse response = REDU_ProgramCompletionVisualizer_LCTRL.deleteExisitingPreviewIpe(studentContacts[0].Id);
                System.Assert.fail('This should fail with object and field permission.');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Insufficient Delete access on following object(s) and field(s) - reduivy__Individual_Program_Enrollment__c'), 'The exception is: ' + exp.getMessage());
            }

            try {
                REDU_LightningResponse response = REDU_ProgramCompletionVisualizer_LCTRL.createPreviewIpe(ipeList[0].reduivy__Contact__r.Id, ipeList[0].reduivy__Study_Program__c, ipeList[0].reduivy__Study_Plan__c);
                System.Assert.fail('This should fail with object and field permission.');

            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Access to entity \'reduivy__Individual_Program_Enrollment__c\' denied'), 'The exception is: ' + exp.getMessage());
            }
            
            try {
                REDU_LightningResponse response = REDU_ProgramCompletionVisualizer_LCTRL.deletePreviewIpe(previewIpe.Id);
                System.Assert.fail('This should fail with object and field permission.');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s) - reduivy__Individual_Program_Enrollment__c'), 'The exception is: ' + exp.getMessage());
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as setup user for creating Ipe with a new Ipe.
     */
    @IsTest
    static void testForSetupUserWithoutExistingIpe(){
        User SETUP_USER = testFactory.getSetupUser();

        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c
                                         FROM Contact
                                         WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT AND reduivy__Sample_Record_Code__c <> ''];

        List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id, reduivy__Contact__r.Id, reduivy__Study_Program__c, reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Contact__r.Id = :studentContacts[0].Id
        ];

        System.runAs(SETUP_USER){
            Test.startTest();

            try {
                REDU_LightningResponse response = REDU_ProgramCompletionVisualizer_LCTRL.deleteExisitingPreviewIpe(studentContacts[0].Id);
            } catch (Exception exp) {
                System.Assert.fail('This should not fail as there is no record to be deleted.');
            }

            try {
                REDU_LightningResponse response = REDU_ProgramCompletionVisualizer_LCTRL.createPreviewIpe(ipeList[0].reduivy__Contact__r.Id, ipeList[0].reduivy__Study_Program__c, ipeList[0].reduivy__Study_Plan__c);
                System.Assert.fail('This should fail with object and field permission.');

            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Access to entity \'reduivy__Individual_Program_Enrollment__c\' denied'), 'The exception is: ' + exp.getMessage());
            }
            
            Test.stopTest();
        }
    }

}