/**
 * @author      WDCi (Sueanne)
 * @date        Apr 2024
 * @group       Test
 * @description Test class for REDU_StudyPathway_LCTRL
 * @changehistory
 * 
 */
@isTest
public inherited sharing class REDU_StudyPathway_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

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

            testFactory.initMasterData(SPW_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_StudyPathway_LCTRL.getStudyPathway()
     */
    @isTest
    static void testGetStudyPathwayForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE reduivy__Default__c = true LIMIT 1];

        reduivy__Study_Pathway__c pathway = [
            SELECT Id, 
            Name, 
            reduivy__Study_Mode__c, 
            reduivy__Study_Plan__c
            FROM reduivy__Study_Pathway__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND reduivy__Default__c = true
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_StudyPathway_LCTRL.getStudyPathway(studyPlan.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_StudyPathway_TEST');

            reduivy__Study_Pathway__c studyPathwaysResponse = (reduivy__Study_Pathway__c) JSON.deserialize(objResponse.responseData, reduivy__Study_Pathway__c.class);
            System.Assert.areEqual(pathway, studyPathwaysResponse);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_StudyPathway_LCTRL.getStudyPlanOptions()
     */
    @isTest
    static void testGetStudyPlanOptionsForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE reduivy__Default__c = true LIMIT 1];

        List<reduivy__Study_Plan_Option__c> studyPlanOptionList = new List<reduivy__Study_Plan_Option__c>();
        for (reduivy__Study_Plan_Option__c spo : [
            SELECT Id, 
            reduivy__Status__c, 
            reduivy__Child_Study_Plan__r.Name, 
            reduivy__Child_Study_Plan__r.Id
            FROM reduivy__Study_Plan_Option__c
            WHERE reduivy__Master_Study_Plan__c = :studyPlan.Id
            AND reduivy__Status__c = :SPO_Helper.STATUS_ACTIVE
            WITH USER_MODE
        ]) {
            studyPlanOptionList.add(spo);
        }

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_StudyPathway_LCTRL.getStudyPlanOptions(studyPlan.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_StudyPathway_TEST');

            List<reduivy__Study_Plan_Option__c> studyPlanOptionResponse = (List<reduivy__Study_Plan_Option__c>) JSON.deserialize(objResponse.responseData, List<reduivy__Study_Plan_Option__c>.class);
            System.Assert.areEqual(studyPlanOptionList.size(), studyPlanOptionResponse.size());

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_StudyPathway_LCTRL.getStudyPathwayTermIds()
     */
    @isTest
    static void testGetStudyPathwayTermIdsForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Pathway__c studyPw = [SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Default__c = true LIMIT 1];

        List<reduivy__Study_Pathway_Term__c> studyPwTermIdsList = new List<reduivy__Study_Pathway_Term__c>();
        for (reduivy__Study_Pathway_Term__c spt : [
            SELECT Id
            FROM reduivy__Study_Pathway_Term__c 
            WHERE reduivy__Study_Pathway__c = :studyPw.Id
            WITH USER_MODE
            ORDER BY reduivy__Term_Number__c
        ]) {
            studyPwTermIdsList.add(spt);
        }

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_StudyPathway_LCTRL.getStudyPathwayTermIds(studyPw.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_StudyPathway_TEST');

            List<reduivy__Study_Pathway_Term__c> studyPwTermResponse = (List<reduivy__Study_Pathway_Term__c>) JSON.deserialize(objResponse.responseData, List<reduivy__Study_Pathway_Term__c>.class);
            System.Assert.areEqual(studyPwTermIdsList.size(), studyPwTermResponse.size());

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_StudyPathway_LCTRL.getStudyPathway()
     */
    @isTest
    static void testGetStudyPathwayWithInvalidIdForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Plan__c studyPlan = [SELECT Id, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE reduivy__Default__c = true LIMIT 1];

        reduivy__Study_Pathway__c pathway = [
            SELECT Id, 
            Name, 
            reduivy__Study_Mode__c, 
            reduivy__Study_Plan__c
            FROM reduivy__Study_Pathway__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND reduivy__Default__c = true
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(ADMIN_USER){
            Test.startTest();

            try {
                REDU_LightningResponse objResponse = REDU_StudyPathway_LCTRL.getStudyPathway(studyPlan.reduivy__Study_Program__c);
                System.Assert.fail('This should fail with invalid record id error.');
            } catch(Exception exp) {
                String objectNames = String.join(new List<String>{SPL_Helper.getObjectLabel(), SPW_Helper.getObjectLabel()}, ', ');
                String expectedError = String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{studyPlan.reduivy__Study_Program__c, objectNames});

                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'The exception is: ' + exp.getMessage());
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as student for REDU_StudyPathway_LCTRL.getStudyPathway()
     */
    @isTest
    static void testGetStudyPathwayForStudent() {
        //get a student for test & assign permission set
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

        REDU_SystemMode_UTIL.doInsert(REDU_TestData_UTIL.newPermissionSetAssignment(studentUser.Id, new Set<String>{'REDU_Guest'}));

        //get for test
        reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE reduivy__Default__c = true LIMIT 1];

        //expected return query
        reduivy__Study_Pathway__c pathway = [
            SELECT Id, 
            Name, 
            reduivy__Study_Mode__c, 
            reduivy__Study_Plan__c
            FROM reduivy__Study_Pathway__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND reduivy__Default__c = true
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(studentUser){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_StudyPathway_LCTRL.getStudyPathway(studyPlan.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_StudyPathway_TEST');

            reduivy__Study_Pathway__c studyPathwaysResponse = (reduivy__Study_Pathway__c) JSON.deserialize(objResponse.responseData, reduivy__Study_Pathway__c.class);
            System.Assert.areEqual(pathway, studyPathwaysResponse);

            Test.stopTest();
        }
    }

    /**
     * @description Test as student for REDU_StudyPathway_LCTRL.getStudyPlanOptions()
     */
    @isTest
    static void testGetStudyPlanOptionsForStudent() {
        //get a student for test & assign permission set
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

        REDU_SystemMode_UTIL.doInsert(REDU_TestData_UTIL.newPermissionSetAssignment(studentUser.Id, new Set<String>{'REDU_Guest'}));

        //get for test
        reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE reduivy__Default__c = true LIMIT 1];

        //expected return query
        List<reduivy__Study_Plan_Option__c> studyPlanOptionList = new List<reduivy__Study_Plan_Option__c>();
        for (reduivy__Study_Plan_Option__c spo : [
            SELECT Id, 
            reduivy__Status__c, 
            reduivy__Child_Study_Plan__r.Name, 
            reduivy__Child_Study_Plan__r.Id
            FROM reduivy__Study_Plan_Option__c
            WHERE reduivy__Master_Study_Plan__c = :studyPlan.Id
            AND reduivy__Status__c = :SPO_Helper.STATUS_ACTIVE
            WITH USER_MODE
        ]) {
            studyPlanOptionList.add(spo);
        }

        System.runAs(studentUser){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_StudyPathway_LCTRL.getStudyPlanOptions(studyPlan.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_StudyPathway_TEST');

            List<reduivy__Study_Plan_Option__c> studyPlanOptionResponse = (List<reduivy__Study_Plan_Option__c>) JSON.deserialize(objResponse.responseData, List<reduivy__Study_Plan_Option__c>.class);
            System.Assert.areEqual(studyPlanOptionList.size(), studyPlanOptionResponse.size());

            Test.stopTest();
        }
    }

    /**
     * @description Test as student for REDU_StudyPathway_LCTRL.getStudyPathwayTermIds()
     */
    @isTest
    static void testGetStudyPathwayTermIdsForStudent() {
        //get a student for test & assign permission set
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

        REDU_SystemMode_UTIL.doInsert(REDU_TestData_UTIL.newPermissionSetAssignment(studentUser.Id, new Set<String>{'REDU_Guest'}));

        //get for test
        reduivy__Study_Pathway__c studyPw = [SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Default__c = true LIMIT 1];

        
        //expected return query
        List<reduivy__Study_Pathway_Term__c> studyPwTermIdsList = new List<reduivy__Study_Pathway_Term__c>();
        for (reduivy__Study_Pathway_Term__c spt : [
            SELECT Id
            FROM reduivy__Study_Pathway_Term__c 
            WHERE reduivy__Study_Pathway__c = :studyPw.Id
            WITH USER_MODE
            ORDER BY reduivy__Term_Number__c
        ]) {
            studyPwTermIdsList.add(spt);
        }

        System.runAs(studentUser){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_StudyPathway_LCTRL.getStudyPathwayTermIds(studyPw.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_StudyPathway_TEST');

            List<reduivy__Study_Pathway_Term__c> studyPwTermResponse = (List<reduivy__Study_Pathway_Term__c>) JSON.deserialize(objResponse.responseData, List<reduivy__Study_Pathway_Term__c>.class);
            System.Assert.areEqual(studyPwTermIdsList.size(), studyPwTermResponse.size());

            Test.stopTest();
        }
    }


    /**
     * @description Test as setup user for REDU_StudyPathway_LCTRL.getStudyPathway()
     */
    @isTest
    static void testGetStudyPathwayForSetupUser() {
        User setupUser = testFactory.getSetupUser();

        //get for test
        reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE reduivy__Default__c = true LIMIT 1];

        System.runAs(setupUser){
            Test.startTest();

            try{
                REDU_LightningResponse objResponse = REDU_StudyPathway_LCTRL.getStudyPathway(studyPlan.Id);
                System.Assert.fail('Exception should be thrown.');
            }catch(Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('Variable does not exist'), 'The exception is invalid: ' + exp.getMessage());
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test as setup user for REDU_StudyPathway_LCTRL.getStudyPlanOptions()
     */
    @isTest
    static void testGetStudyPlanOptionsForSetupUser() {
        User setupUser = testFactory.getSetupUser();

        //get for test
        reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE reduivy__Default__c = true LIMIT 1];

        System.runAs(setupUser){
            Test.startTest();

            try{
                REDU_LightningResponse objResponse = REDU_StudyPathway_LCTRL.getStudyPlanOptions(studyPlan.Id);
                System.Assert.fail('QueryException should be thrown.');
            }catch(Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s)') || exp.getMessage().contains('Variable does not exist'), 'The exception is: ' + exp.getMessage());
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as setup user for REDU_StudyPathway_LCTRL.getStudyPathwayTermIds()
     */
    @isTest
    static void testGetStudyPathwayTermIdsForSetupUser() {
        User setupUser = testFactory.getSetupUser();

        //get for test
        reduivy__Study_Pathway__c studyPw = [SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Default__c = true LIMIT 1];

        System.runAs(setupUser){
            Test.startTest();

            try{
                REDU_LightningResponse objResponse = REDU_StudyPathway_LCTRL.getStudyPathwayTermIds(studyPw.Id);
                System.Assert.fail('QueryException should be thrown.');
            }catch(Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s)') || exp.getMessage().contains('Variable does not exist'), 'The exception is: ' + exp.getMessage());
            }
            
            Test.stopTest();
        }
    }
}