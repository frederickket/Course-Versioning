/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_StudyPlanGroup_LCTRL
 * @changehistory
 * ISS-001617 14-11-2023 Lean - new component
 * ISS-002152 06-11-2024 Jordan - Study Plan Wizard to support modification
 */
@IsTest
public inherited sharing class REDU_StudyPlanGroup_TEST {

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

            Test.stopTest();
        }
        
    }

    /**
     * @description Test get child groups as admin
     */
    @IsTest
    static void testGetChildRecordsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
        User reduAdmin = testFactory.getReduAdminUser();

        Test.startTest();
        
        System.runAs(reduAdmin){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));

            Integer counter = 0;
            for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, Name
                FROM reduivy__Study_Plan_Structure__c
                WHERE reduivy__Study_Plan__c =: studyPlan.Id
                AND RecordTypeId =: SPS_Helper.getGroupRecordTypeId()
                AND reduivy__Parent_Study_Plan_Structure__c = NULL
                WITH USER_MODE
                ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST
            ]) {
                
                REDU_LightningResponse response = REDU_StudyPlanGroup_LCTRL.getChildRecords(sps.Id);

                System.Assert.isTrue(String.isNotBlank(response.responseData));

                List<reduivy__Study_Plan_Structure__c> returnedChildRecords = (List<reduivy__Study_Plan_Structure__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Plan_Structure__c>.class);

                if (sps.Name == 'BACBIS_MajorA_GROUPA') {
                    System.Assert.areEqual(2, returnedChildRecords.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPB') {
                    System.Assert.areEqual(3, returnedChildRecords.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPC') {
                    System.Assert.areEqual(2, returnedChildRecords.size());
                } else {
                    System.Assert.fail('Invalid child group.');
                }

                counter ++;
            }

            System.Assert.areEqual(3, counter, 'There should be 3 top groups.');
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get child groups as faculty
     */
    @IsTest
    static void testGetChildRecordsAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        System.runAs(FACULTY_USER){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));

            Integer counter = 0;
            for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, Name
                FROM reduivy__Study_Plan_Structure__c
                WHERE reduivy__Study_Plan__c =: studyPlan.Id
                AND RecordTypeId =: SPS_Helper.getGroupRecordTypeId()
                AND reduivy__Parent_Study_Plan_Structure__c = NULL
                WITH USER_MODE
                ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST
            ]) {
                
                REDU_LightningResponse response = REDU_StudyPlanGroup_LCTRL.getChildRecords(sps.Id);

                System.Assert.isTrue(String.isNotBlank(response.responseData));

                List<reduivy__Study_Plan_Structure__c> returnedChildRecords = (List<reduivy__Study_Plan_Structure__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Plan_Structure__c>.class);

                if (sps.Name == 'BACBIS_MajorA_GROUPA') {
                    System.Assert.areEqual(2, returnedChildRecords.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPB') {
                    System.Assert.areEqual(3, returnedChildRecords.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPC') {
                    System.Assert.areEqual(2, returnedChildRecords.size());
                } else {
                    System.Assert.fail('Invalid child group.');
                }

                counter ++;
            }

            System.Assert.areEqual(3, counter, 'There should be 3 top groups.');
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get child groups as student
     */
    @IsTest
    static void testGetChildRecordsAsStudent(){
        
        testFactory.initOfferingData(null);
        testFactory.initStudentData(USR_Helper.getApiName(), true);

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

        Test.startTest();
        
        System.runAs(reduStudent){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));

            Integer counter = 0;
            for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, Name
                FROM reduivy__Study_Plan_Structure__c
                WHERE reduivy__Study_Plan__c =: studyPlan.Id
                AND RecordTypeId =: SPS_Helper.getGroupRecordTypeId()
                AND reduivy__Parent_Study_Plan_Structure__c = NULL
                WITH USER_MODE
                ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST
            ]) {
                
                REDU_LightningResponse response = REDU_StudyPlanGroup_LCTRL.getChildRecords(sps.Id);

                System.Assert.isTrue(String.isNotBlank(response.responseData));

                List<reduivy__Study_Plan_Structure__c> returnedChildRecords = (List<reduivy__Study_Plan_Structure__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Plan_Structure__c>.class);

                if (sps.Name == 'BACBIS_MajorA_GROUPA') {
                    System.Assert.areEqual(2, returnedChildRecords.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPB') {
                    System.Assert.areEqual(3, returnedChildRecords.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPC') {
                    System.Assert.areEqual(2, returnedChildRecords.size());
                } else {
                    System.Assert.fail('Invalid child group.');
                }

                counter ++;
            }

            System.Assert.areEqual(3, counter, 'There should be 3 top groups.');
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get top groups as non redu user to test the exception
     */
    @IsTest
    static void testGetChildRecordsException(){
        
        User nonReduUser = testFactory.getSetupUser();

        Test.startTest();
        
        reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];

        System.Assert.isTrue(String.isNotBlank(studyPlan.Id));

        for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, Name
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c =: studyPlan.Id
            AND RecordTypeId =: SPS_Helper.getGroupRecordTypeId()
            AND reduivy__Parent_Study_Plan_Structure__c = NULL
            WITH USER_MODE
            ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST
        ]) {
            System.runAs(nonReduUser){
                try {
                    REDU_LightningResponse response = REDU_StudyPlanGroup_LCTRL.getChildRecords(sps.Id);
                    System.Assert.fail('This should fail with FLS error.');

                } catch (Exception exp) {
                    REDU_Logging_UTIL.debug(exp);
                    System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s) - reduivy__Study_Plan_Structure__c'), 'The exception is invalid: ' + exp.getMessage());
                }
            }
        }

        Test.stopTest();
        
    }
}