/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_StudyPlanHierarchy_LCTRL
 * @changehistory
 * ISS-001617 14-11-2023 Lean - new component
 * ISS-002152 06-11-2024 Jordan - Study Plan Wizard to support modification
 */
@IsTest
public inherited sharing class REDU_StudyPlanHierarchy_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String SPS_GROUP_RT_LABEL = SPS_Helper.getGroupRecordTypeLabel();
    static final String SPS_UNIT_RT_LABEL = SPS_Helper.getUnitRecordTypeLabel();

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
     * @description Test get top groups as admin
     */
    @IsTest
    static void testGetTopLevelGroupAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));

            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.getTopLevelGroups(studyPlan.Id);

            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Plan_Structure__c> returnedTopGroups = (List<reduivy__Study_Plan_Structure__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Plan_Structure__c>.class);

            System.Assert.areEqual(3, returnedTopGroups.size());

            Integer counter = 0;
            for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, Name
                FROM reduivy__Study_Plan_Structure__c
                WHERE reduivy__Study_Plan__c =: studyPlan.Id
                AND RecordTypeId =: SPS_Helper.getGroupRecordTypeId()
                AND reduivy__Parent_Study_Plan_Structure__c = NULL
                WITH USER_MODE
                ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST, Name ASC
            ]) {
                System.Assert.areEqual(sps.Id, returnedTopGroups.get(counter).Id);

                counter ++;
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get top groups as faculty
     */
    @IsTest
    static void testGetTopLevelGroupAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        System.runAs(FACULTY_USER){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));

            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.getTopLevelGroups(studyPlan.Id);

            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Plan_Structure__c> returnedTopGroups = (List<reduivy__Study_Plan_Structure__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Plan_Structure__c>.class);

            System.Assert.areEqual(3, returnedTopGroups.size());

            Integer counter = 0;
            for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, Name
                FROM reduivy__Study_Plan_Structure__c
                WHERE reduivy__Study_Plan__c =: studyPlan.Id
                AND RecordTypeId =: SPS_Helper.getGroupRecordTypeId()
                AND reduivy__Parent_Study_Plan_Structure__c = NULL
                WITH USER_MODE
                ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST, Name ASC
            ]) {
                System.Assert.areEqual(sps.Id, returnedTopGroups.get(counter).Id);

                counter ++;
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get top groups as student
     */
    @IsTest
    static void testGetTopLevelGroupAsStudent(){
        
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

            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.getTopLevelGroups(studyPlan.Id);

            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Plan_Structure__c> returnedTopGroups = (List<reduivy__Study_Plan_Structure__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Plan_Structure__c>.class);

            System.Assert.areEqual(3, returnedTopGroups.size());

            Integer counter = 0;
            for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, Name
                FROM reduivy__Study_Plan_Structure__c
                WHERE reduivy__Study_Plan__c =: studyPlan.Id
                AND RecordTypeId =: SPS_Helper.getGroupRecordTypeId()
                AND reduivy__Parent_Study_Plan_Structure__c = NULL
                WITH USER_MODE
                ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST, Name ASC
            ]) {
                System.Assert.areEqual(sps.Id, returnedTopGroups.get(counter).Id);

                counter ++;
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get top groups as non redu user to test the exception
     */
    @IsTest
    static void testGetTopLevelGroupException(){
        
        User nonReduUser = testFactory.getSetupUser();

        reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];

        System.Assert.isTrue(String.isNotBlank(studyPlan.Id));

        Test.startTest();
        
        System.runAs(nonReduUser){
            
            try {
                REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.getTopLevelGroups(studyPlan.Id);
                System.Assert.fail('This should fail with FLS error.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s) - reduivy__Study_Plan_Structure__c'), 'The exception is invalid: ' + exp.getMessage());
            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test get SPS record type info as admin
     */
    @IsTest
    static void testGetSpsRecordTypeInfoAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.getSpsRecordTypeInfo();

            System.Assert.isTrue(String.isNotBlank(response.responseData));

            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.areEqual(SPS_Helper.getGroupRecordTypeId(), data.get('spsGroupRecordTypeId'));
            System.Assert.areEqual(SPS_Helper.getGroupRecordTypeLabel(), data.get('spsGroupRecordTypeLabel'));
            System.Assert.areEqual(SPS_Helper.getUnitRecordTypeId(), data.get('spsUnitRecordTypeId'));
            System.Assert.areEqual(SPS_Helper.getUnitRecordTypeLabel(), data.get('spsUnitRecordTypeLabel'));
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get SPS record type info as faculty
     */
    @IsTest
    static void testGetSpsRecordTypeInfoAsFaculty(){

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.getSpsRecordTypeInfo();

            System.Assert.isTrue(String.isNotBlank(response.responseData));

            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.areEqual(SPS_Helper.getGroupRecordTypeId(), data.get('spsGroupRecordTypeId'));
            System.Assert.areEqual(SPS_Helper.getGroupRecordTypeLabel(), data.get('spsGroupRecordTypeLabel'));
            System.Assert.areEqual(SPS_Helper.getUnitRecordTypeId(), data.get('spsUnitRecordTypeId'));
            System.Assert.areEqual(SPS_Helper.getUnitRecordTypeLabel(), data.get('spsUnitRecordTypeLabel'));
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get SPS record type info as student
     */
    @IsTest
    static void testGetSpsRecordTypeInfoAsStudent(){

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
            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.getSpsRecordTypeInfo();

            System.Assert.isTrue(String.isNotBlank(response.responseData));

            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.areEqual(SPS_Helper.getGroupRecordTypeId(), data.get('spsGroupRecordTypeId'));
            System.Assert.areEqual(SPS_Helper.getGroupRecordTypeLabel(), data.get('spsGroupRecordTypeLabel'));
            System.Assert.areEqual(SPS_Helper.getUnitRecordTypeId(), data.get('spsUnitRecordTypeId'));
            System.Assert.areEqual(SPS_Helper.getUnitRecordTypeLabel(), data.get('spsUnitRecordTypeLabel'));
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get group field set as admin
     */
    @IsTest
    static void testGetGroupFieldSetAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.getGroupFieldSet('reduivy__StudyPlanStructure_Group_EditForm');

            System.Assert.isTrue(String.isNotBlank(response.responseData));
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get group field set as faculty
     */
    @IsTest
    static void testGetGroupFieldSetAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.getGroupFieldSet('reduivy__StudyPlanStructure_Group_EditForm');

            System.Assert.isTrue(String.isNotBlank(response.responseData));
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get group field set as student
     */
    @IsTest
    static void testGetGroupFieldSetAsStudent(){
        
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
            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.getGroupFieldSet('reduivy__StudyPlanStructure_Group_EditForm');

            System.Assert.isTrue(String.isNotBlank(response.responseData));
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get unit field set as admin
     */
    @IsTest
    static void testGetUnitFieldSetAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.getUnitFieldSet('reduivy__StudyPlanStructure_Unit_EditForm');

            System.Assert.isTrue(String.isNotBlank(response.responseData));
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get unit field set as faculty
     */
    @IsTest
    static void testGetUnitFieldSetAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.getUnitFieldSet('reduivy__StudyPlanStructure_Unit_EditForm');

            System.Assert.isTrue(String.isNotBlank(response.responseData));
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get unit field set as student
     */
    @IsTest
    static void testGetUnitFieldSetAsStudent(){
        
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
            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.getUnitFieldSet('reduivy__StudyPlanStructure_Unit_EditForm');

            System.Assert.isTrue(String.isNotBlank(response.responseData));
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get community info as admin
     */
    @IsTest
    static void testGetCommunityInfoAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.getCommunityInfo();

            System.Assert.isTrue(String.isNotBlank(response.responseData));
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get community info as faculty
     */
    @IsTest
    static void testGetCommunityInfoAsFaculty(){

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.getCommunityInfo();

            System.Assert.isTrue(String.isNotBlank(response.responseData));
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get community info as student
     */
    @IsTest
    static void testGetCommunityInfoAsStudent(){

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
            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.getCommunityInfo();

            System.Assert.isTrue(String.isNotBlank(response.responseData));
        }

        Test.stopTest();
        
    }

    /**
     * @description Test create new top group as admin
     */
    @IsTest
    static void testCreateNewTopGroupAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));

            reduivy__Study_Plan_Structure__c newTopGroupSps = new reduivy__Study_Plan_Structure__c();
            newTopGroupSps.Name = 'New Top Group';
            newTopGroupSps.reduivy__Description__c = 'Test description';
            newTopGroupSps.reduivy__Category__c = 'Optional';
            newTopGroupSps.reduivy__Credits__c = 10;

            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.upsertStudyPlanStructure(null, studyPlan.Id, null, REDU_StudyPlanHierarchy_LCTRL.NEW_GROUP_ACTION_TYPE, newTopGroupSps);

            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Plan_Structure__c> newTopGroupSpsCheck = [
                SELECT Id, Name, RecordTypeId, reduivy__Description__c, reduivy__Category__c, reduivy__Credits__c, reduivy__Study_Plan__c
                FROM reduivy__Study_Plan_Structure__c
                WHERE Name = :newTopGroupSps.Name
            ];
            
            System.Assert.areEqual(1, newTopGroupSpsCheck.size());
            System.Assert.areEqual(newTopGroupSps.reduivy__Description__c, newTopGroupSpsCheck[0].reduivy__Description__c);
            System.Assert.areEqual(newTopGroupSps.reduivy__Category__c, newTopGroupSpsCheck[0].reduivy__Category__c);
            System.Assert.areEqual(newTopGroupSps.reduivy__Credits__c, newTopGroupSpsCheck[0].reduivy__Credits__c);
            System.Assert.areEqual(SPS_Helper.getGroupRecordTypeId(), newTopGroupSpsCheck[0].RecordTypeId);
            System.Assert.areEqual(studyPlan.Id, newTopGroupSpsCheck[0].reduivy__Study_Plan__c);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test create new top group as faculty
     */
    @IsTest
    static void testCreateNewTopGroupAsFaculty(){

                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        System.runAs(FACULTY_USER){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));

            reduivy__Study_Plan_Structure__c newTopGroupSps = new reduivy__Study_Plan_Structure__c();
            newTopGroupSps.Name = 'New Top Group';
            newTopGroupSps.reduivy__Description__c = 'Test description';
            newTopGroupSps.reduivy__Category__c = 'Optional';
            newTopGroupSps.reduivy__Credits__c = 10;

            try {
                REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.upsertStudyPlanStructure(null, studyPlan.Id, null, REDU_StudyPlanHierarchy_LCTRL.NEW_GROUP_ACTION_TYPE, newTopGroupSps);
                System.Assert.fail('Faculty user should not have permission to create reduivy__Study_Plan_Structure__c.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('DML operation INSERT not allowed on reduivy__Study_Plan_Structure__c'), 'The exception is invalid: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test create new top group as student
     */
    @IsTest
    static void testCreateNewTopGroupAsStudent(){

        
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

            reduivy__Study_Plan_Structure__c newTopGroupSps = new reduivy__Study_Plan_Structure__c();
            newTopGroupSps.Name = 'New Top Group';
            newTopGroupSps.reduivy__Description__c = 'Test description';
            newTopGroupSps.reduivy__Category__c = 'Optional';
            newTopGroupSps.reduivy__Credits__c = 10;

            try {
                REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.upsertStudyPlanStructure(null, studyPlan.Id, null, REDU_StudyPlanHierarchy_LCTRL.NEW_GROUP_ACTION_TYPE, newTopGroupSps);
                System.Assert.fail('Student user should not have permission to create reduivy__Study_Plan_Structure__c.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('DML operation INSERT not allowed on reduivy__Study_Plan_Structure__c'), 'The exception is invalid: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test create new child group as admin
     */
    @IsTest
    static void testCreateNewChildGroupAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));

            reduivy__Study_Plan_Structure__c newTopGroupSps = new reduivy__Study_Plan_Structure__c();
            newTopGroupSps.Name = 'New Top Group';
            newTopGroupSps.reduivy__Description__c = 'Test description';
            newTopGroupSps.reduivy__Category__c = 'Optional';
            newTopGroupSps.reduivy__Credits__c = 10;
            newTopGroupSps.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
            newTopGroupSps.reduivy__Study_Plan__c = studyPlan.Id;
            insert newTopGroupSps;

            reduivy__Study_Plan_Structure__c newChildGroupSps = new reduivy__Study_Plan_Structure__c();
            newChildGroupSps.Name = 'New Child Group';
            newChildGroupSps.reduivy__Description__c = 'Test description';
            newChildGroupSps.reduivy__Category__c = 'Optional';
            newChildGroupSps.reduivy__Credits__c = 10;

            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.upsertStudyPlanStructure(null, studyPlan.Id, newTopGroupSps.Id, REDU_StudyPlanHierarchy_LCTRL.NEW_GROUP_ACTION_TYPE, newChildGroupSps);

            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Plan_Structure__c> newChildGroupSpsCheck = [
                SELECT Id, Name, RecordTypeId, reduivy__Description__c, reduivy__Category__c, reduivy__Credits__c, reduivy__Study_Plan__c
                FROM reduivy__Study_Plan_Structure__c
                WHERE Name = :newChildGroupSps.Name
            ];
            
            System.Assert.areEqual(1, newChildGroupSpsCheck.size());
            System.Assert.areEqual(newChildGroupSps.reduivy__Description__c, newChildGroupSpsCheck[0].reduivy__Description__c);
            System.Assert.areEqual(newChildGroupSps.reduivy__Category__c, newChildGroupSpsCheck[0].reduivy__Category__c);
            System.Assert.areEqual(newChildGroupSps.reduivy__Credits__c, newChildGroupSpsCheck[0].reduivy__Credits__c);
            System.Assert.areEqual(SPS_Helper.getGroupRecordTypeId(), newChildGroupSpsCheck[0].RecordTypeId);
            System.Assert.areEqual(studyPlan.Id, newChildGroupSpsCheck[0].reduivy__Study_Plan__c);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test create new child group as faculty
     */
    @IsTest
    static void testCreateNewChildGroupAsFaculty(){

                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        System.runAs(FACULTY_USER){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));

            reduivy__Study_Plan_Structure__c newTopGroupSps = new reduivy__Study_Plan_Structure__c();
            newTopGroupSps.Name = 'New Top Group';
            newTopGroupSps.reduivy__Description__c = 'Test description';
            newTopGroupSps.reduivy__Category__c = 'Optional';
            newTopGroupSps.reduivy__Credits__c = 10;
            newTopGroupSps.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
            newTopGroupSps.reduivy__Study_Plan__c = studyPlan.Id;
            insert newTopGroupSps;

            reduivy__Study_Plan_Structure__c newChildGroupSps = new reduivy__Study_Plan_Structure__c();
            newChildGroupSps.Name = 'New Child Group';
            newChildGroupSps.reduivy__Description__c = 'Test description';
            newChildGroupSps.reduivy__Category__c = 'Optional';
            newChildGroupSps.reduivy__Credits__c = 10;

            try {
                REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.upsertStudyPlanStructure(null, studyPlan.Id, newTopGroupSps.Id, REDU_StudyPlanHierarchy_LCTRL.NEW_GROUP_ACTION_TYPE, newChildGroupSps);
                System.Assert.fail('Faculty user should not have permission to create reduivy__Study_Plan_Structure__c.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('DML operation INSERT not allowed on reduivy__Study_Plan_Structure__c'), 'The exception is invalid: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test create new child group as student
     */
    @IsTest
    static void testCreateNewChildGroupAsStudent(){

        
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

            reduivy__Study_Plan_Structure__c newTopGroupSps = new reduivy__Study_Plan_Structure__c();
            newTopGroupSps.Name = 'New Top Group';
            newTopGroupSps.reduivy__Description__c = 'Test description';
            newTopGroupSps.reduivy__Category__c = 'Optional';
            newTopGroupSps.reduivy__Credits__c = 10;
            newTopGroupSps.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
            newTopGroupSps.reduivy__Study_Plan__c = studyPlan.Id;
            insert newTopGroupSps;

            reduivy__Study_Plan_Structure__c newChildGroupSps = new reduivy__Study_Plan_Structure__c();
            newChildGroupSps.Name = 'New Child Group';
            newChildGroupSps.reduivy__Description__c = 'Test description';
            newChildGroupSps.reduivy__Category__c = 'Optional';
            newChildGroupSps.reduivy__Credits__c = 10;

            try {
                REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.upsertStudyPlanStructure(null, studyPlan.Id, newTopGroupSps.Id, REDU_StudyPlanHierarchy_LCTRL.NEW_GROUP_ACTION_TYPE, newChildGroupSps);
                System.Assert.fail('Student user should not have permission to create reduivy__Study_Plan_Structure__c.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('DML operation INSERT not allowed on reduivy__Study_Plan_Structure__c'), 'The exception is invalid: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test create new unit as admin
     */
    @IsTest
    static void testCreateNewUnitAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];
            reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c WHERE Name = 'SEC302'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));
            System.Assert.isTrue(String.isNotBlank(studyUnit.Id));

            reduivy__Study_Plan_Structure__c newTopGroupSps = new reduivy__Study_Plan_Structure__c();
            newTopGroupSps.Name = 'New Top Group';
            newTopGroupSps.reduivy__Description__c = 'Test description';
            newTopGroupSps.reduivy__Category__c = 'Optional';
            newTopGroupSps.reduivy__Credits__c = 10;
            newTopGroupSps.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
            newTopGroupSps.reduivy__Study_Plan__c = studyPlan.Id;
            insert newTopGroupSps;

            reduivy__Study_Plan_Structure__c newUnitSps = new reduivy__Study_Plan_Structure__c();
            newUnitSps.Name = 'New Unit';
            newUnitSps.reduivy__Description__c = 'Test description';
            newUnitSps.reduivy__Category__c = 'Optional';
            newUnitSps.reduivy__Study_Unit__c = studyUnit.Id;
            newUnitSps.reduivy__Credits__c = 10;

            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.upsertStudyPlanStructure(null, studyPlan.Id, newTopGroupSps.Id, REDU_StudyPlanHierarchy_LCTRL.NEW_UNIT_ACTION_TYPE, newUnitSps);

            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Plan_Structure__c> newUnitSpsCheck = [
                SELECT Id, Name, RecordTypeId, reduivy__Description__c, reduivy__Category__c, reduivy__Study_Unit__c, reduivy__Credits__c, reduivy__Study_Plan__c
                FROM reduivy__Study_Plan_Structure__c
                WHERE Name = :newUnitSps.Name
            ];
            
            System.Assert.areEqual(1, newUnitSpsCheck.size());
            System.Assert.areEqual(newUnitSps.reduivy__Description__c, newUnitSpsCheck[0].reduivy__Description__c);
            System.Assert.areEqual(newUnitSps.reduivy__Category__c, newUnitSpsCheck[0].reduivy__Category__c);
            System.Assert.areEqual(newUnitSps.reduivy__Study_Unit__c, newUnitSpsCheck[0].reduivy__Study_Unit__c);
            System.Assert.areEqual(newUnitSps.reduivy__Credits__c, newUnitSpsCheck[0].reduivy__Credits__c);
            System.Assert.areEqual(SPS_Helper.getUnitRecordTypeId(), newUnitSpsCheck[0].RecordTypeId);
            System.Assert.areEqual(studyPlan.Id, newUnitSpsCheck[0].reduivy__Study_Plan__c);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test create new unit as faculty
     */
    @IsTest
    static void testCreateNewUnitAsFaculty(){

                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        System.runAs(FACULTY_USER){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];
            reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c WHERE Name = 'SEC302'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));
            System.Assert.isTrue(String.isNotBlank(studyUnit.Id));

            reduivy__Study_Plan_Structure__c newTopGroupSps = new reduivy__Study_Plan_Structure__c();
            newTopGroupSps.Name = 'New Top Group';
            newTopGroupSps.reduivy__Description__c = 'Test description';
            newTopGroupSps.reduivy__Category__c = 'Optional';
            newTopGroupSps.reduivy__Credits__c = 10;
            newTopGroupSps.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
            newTopGroupSps.reduivy__Study_Plan__c = studyPlan.Id;
            insert newTopGroupSps;

            reduivy__Study_Plan_Structure__c newUnitSps = new reduivy__Study_Plan_Structure__c();
            newUnitSps.Name = 'New Unit';
            newUnitSps.reduivy__Description__c = 'Test description';
            newUnitSps.reduivy__Category__c = 'Optional';
            newUnitSps.reduivy__Study_Unit__c = studyUnit.Id;
            newUnitSps.reduivy__Credits__c = 10;

            try {
                REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.upsertStudyPlanStructure(null, studyPlan.Id, newTopGroupSps.Id, REDU_StudyPlanHierarchy_LCTRL.NEW_UNIT_ACTION_TYPE, newUnitSps);
                System.Assert.fail('Faculty user should not have permission to create reduivy__Study_Plan_Structure__c.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('DML operation INSERT not allowed on reduivy__Study_Plan_Structure__c'), 'The exception is invalid: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test create new unit as student
     */
    @IsTest
    static void testCreateNewUnitAsStudent(){

        
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
            reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c WHERE Name = 'SEC302'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));
            System.Assert.isTrue(String.isNotBlank(studyUnit.Id));

            reduivy__Study_Plan_Structure__c newTopGroupSps = new reduivy__Study_Plan_Structure__c();
            newTopGroupSps.Name = 'New Top Group';
            newTopGroupSps.reduivy__Description__c = 'Test description';
            newTopGroupSps.reduivy__Category__c = 'Optional';
            newTopGroupSps.reduivy__Credits__c = 10;
            newTopGroupSps.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
            newTopGroupSps.reduivy__Study_Plan__c = studyPlan.Id;
            insert newTopGroupSps;

            reduivy__Study_Plan_Structure__c newUnitSps = new reduivy__Study_Plan_Structure__c();
            newUnitSps.Name = 'New Unit';
            newUnitSps.reduivy__Description__c = 'Test description';
            newUnitSps.reduivy__Category__c = 'Optional';
            newUnitSps.reduivy__Study_Unit__c = studyUnit.Id;
            newUnitSps.reduivy__Credits__c = 10;

            try {
                REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.upsertStudyPlanStructure(null, studyPlan.Id, newTopGroupSps.Id, REDU_StudyPlanHierarchy_LCTRL.NEW_UNIT_ACTION_TYPE, newUnitSps);
                System.Assert.fail('Student user should not have permission to create reduivy__Study_Plan_Structure__c.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('DML operation INSERT not allowed on reduivy__Study_Plan_Structure__c'), 'The exception is invalid: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test edit top group as admin
     */
    @IsTest
    static void testEditTopGroupAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];
            reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c WHERE Name = 'SEC302'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));
            System.Assert.isTrue(String.isNotBlank(studyUnit.Id));

            reduivy__Study_Plan_Structure__c newTopGroupSps = new reduivy__Study_Plan_Structure__c();
            newTopGroupSps.Name = 'New Top Group';
            newTopGroupSps.reduivy__Description__c = 'Test description';
            newTopGroupSps.reduivy__Category__c = 'Optional';
            newTopGroupSps.reduivy__Credits__c = 10;
            newTopGroupSps.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
            newTopGroupSps.reduivy__Study_Plan__c = studyPlan.Id;
            insert newTopGroupSps;

            reduivy__Study_Plan_Structure__c editedTopGroupSps = new reduivy__Study_Plan_Structure__c();
            editedTopGroupSps.Name = 'Edited Unit';
            editedTopGroupSps.reduivy__Description__c = 'Edited description';
            editedTopGroupSps.reduivy__Category__c = 'Required';
            editedTopGroupSps.reduivy__Credits__c = 20;

            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.upsertStudyPlanStructure(newTopGroupSps.Id, studyPlan.Id, null, REDU_StudyPlanHierarchy_LCTRL.EDIT_ACTION_TYPE, editedTopGroupSps);

            System.Assert.isTrue(String.isNotBlank(response.responseData));

            Set<String> spsCheckNameSet = new Set<String>{newTopGroupSps.Name, editedTopGroupSps.Name};

            List<reduivy__Study_Plan_Structure__c> editedTopGroupSpsCheck = [
                SELECT Id, Name, RecordTypeId, reduivy__Description__c, reduivy__Category__c, reduivy__Credits__c, reduivy__Study_Plan__c
                FROM reduivy__Study_Plan_Structure__c
                WHERE Name IN :spsCheckNameSet
            ];
            
            System.Assert.areEqual(1, editedTopGroupSpsCheck.size());
            System.Assert.areEqual(editedTopGroupSps.reduivy__Description__c, editedTopGroupSpsCheck[0].reduivy__Description__c);
            System.Assert.areEqual(editedTopGroupSps.reduivy__Category__c, editedTopGroupSpsCheck[0].reduivy__Category__c);
            System.Assert.areEqual(editedTopGroupSps.reduivy__Credits__c, editedTopGroupSpsCheck[0].reduivy__Credits__c);
            System.Assert.areEqual(newTopGroupSps.RecordTypeId, editedTopGroupSpsCheck[0].RecordTypeId);
            System.Assert.areEqual(newTopGroupSps.reduivy__Study_Plan__c, editedTopGroupSpsCheck[0].reduivy__Study_Plan__c);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test edit top group as faculty
     */
    @IsTest
    static void testEditTopGroupAsFaculty(){

                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        System.runAs(FACULTY_USER){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];
            reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c WHERE Name = 'SEC302'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));
            System.Assert.isTrue(String.isNotBlank(studyUnit.Id));

            reduivy__Study_Plan_Structure__c newTopGroupSps = new reduivy__Study_Plan_Structure__c();
            newTopGroupSps.Name = 'New Top Group';
            newTopGroupSps.reduivy__Description__c = 'Test description';
            newTopGroupSps.reduivy__Category__c = 'Optional';
            newTopGroupSps.reduivy__Credits__c = 10;
            newTopGroupSps.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
            newTopGroupSps.reduivy__Study_Plan__c = studyPlan.Id;
            insert newTopGroupSps;

            reduivy__Study_Plan_Structure__c editedTopGroupSps = new reduivy__Study_Plan_Structure__c();
            editedTopGroupSps.Name = 'Edited Unit';
            editedTopGroupSps.reduivy__Description__c = 'Edited description';
            editedTopGroupSps.reduivy__Category__c = 'Required';
            editedTopGroupSps.reduivy__Credits__c = 20;

            try {
                REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.upsertStudyPlanStructure(newTopGroupSps.Id, studyPlan.Id, null, REDU_StudyPlanHierarchy_LCTRL.EDIT_ACTION_TYPE, editedTopGroupSps);
                System.Assert.fail('Faculty user should not have permission to edit reduivy__Study_Plan_Structure__c.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('DML operation UPDATE not allowed on reduivy__Study_Plan_Structure__c'), 'The exception is invalid: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test edit top group as student
     */
    @IsTest
    static void testEditTopGroupAsStudent(){

        
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
            reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c WHERE Name = 'SEC302'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));
            System.Assert.isTrue(String.isNotBlank(studyUnit.Id));

            reduivy__Study_Plan_Structure__c newTopGroupSps = new reduivy__Study_Plan_Structure__c();
            newTopGroupSps.Name = 'New Top Group';
            newTopGroupSps.reduivy__Description__c = 'Test description';
            newTopGroupSps.reduivy__Category__c = 'Optional';
            newTopGroupSps.reduivy__Credits__c = 10;
            newTopGroupSps.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
            newTopGroupSps.reduivy__Study_Plan__c = studyPlan.Id;
            insert newTopGroupSps;

            reduivy__Study_Plan_Structure__c editedTopGroupSps = new reduivy__Study_Plan_Structure__c();
            editedTopGroupSps.Name = 'Edited Unit';
            editedTopGroupSps.reduivy__Description__c = 'Edited description';
            editedTopGroupSps.reduivy__Category__c = 'Required';
            editedTopGroupSps.reduivy__Credits__c = 20;

            try {
                REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.upsertStudyPlanStructure(newTopGroupSps.Id, studyPlan.Id, null, REDU_StudyPlanHierarchy_LCTRL.EDIT_ACTION_TYPE, editedTopGroupSps);
                System.Assert.fail('Student user should not have permission to edit reduivy__Study_Plan_Structure__c.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('DML operation UPDATE not allowed on reduivy__Study_Plan_Structure__c'), 'The exception is invalid: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test delete top group as admin
     */
    @IsTest
    static void testDeleteTopGroupAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];
            reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c WHERE Name = 'SEC302'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));
            System.Assert.isTrue(String.isNotBlank(studyUnit.Id));

            Set<Id> spsCheckIdSet = new Set<Id>();

            reduivy__Study_Plan_Structure__c newTopGroupSps = new reduivy__Study_Plan_Structure__c();
            newTopGroupSps.Name = 'New Top Group';
            newTopGroupSps.reduivy__Description__c = 'Test description';
            newTopGroupSps.reduivy__Category__c = 'Optional';
            newTopGroupSps.reduivy__Credits__c = 10;
            newTopGroupSps.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
            newTopGroupSps.reduivy__Study_Plan__c = studyPlan.Id;
            insert newTopGroupSps;
            spsCheckIdSet.add(newTopGroupSps.Id);

            reduivy__Study_Plan_Structure__c newChildGroupSps = new reduivy__Study_Plan_Structure__c();
            newChildGroupSps.Name = 'New Child Group';
            newChildGroupSps.reduivy__Description__c = 'Test description';
            newChildGroupSps.reduivy__Category__c = 'Optional';
            newChildGroupSps.reduivy__Credits__c = 10;
            newChildGroupSps.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
            newChildGroupSps.reduivy__Study_Plan__c = studyPlan.Id;
            newChildGroupSps.reduivy__Parent_Study_Plan_Structure__c = newTopGroupSps.Id;
            insert newChildGroupSps;
            spsCheckIdSet.add(newChildGroupSps.Id);

            reduivy__Study_Plan_Structure__c newUnitSps = new reduivy__Study_Plan_Structure__c();
            newUnitSps.Name = 'New Unit';
            newUnitSps.reduivy__Description__c = 'Test description';
            newUnitSps.reduivy__Category__c = 'Optional';
            newUnitSps.reduivy__Study_Unit__c = studyUnit.Id;
            newUnitSps.reduivy__Credits__c = 10;
            newUnitSps.RecordTypeId = SPS_Helper.getUnitRecordTypeId();
            newUnitSps.reduivy__Study_Plan__c = studyPlan.Id;
            newUnitSps.reduivy__Parent_Study_Plan_Structure__c = newChildGroupSps.Id;
            insert newUnitSps;
            spsCheckIdSet.add(newUnitSps.Id);

            REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.deleteStudyPlanStructure(newTopGroupSps.Id, SPS_Helper.getGroupRecordTypeId());

            System.Assert.isTrue(String.isNotBlank(response.responseData));

            List<reduivy__Study_Plan_Structure__c> spsCheckList = [SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE Id IN :spsCheckIdSet];
            
            System.Assert.areEqual(0, spsCheckList.size());
        }

        Test.stopTest();
        
    }

    /**
     * @description Test delete top group as faculty
     */
    @IsTest
    static void testDeleteTopGroupAsFaculty(){

                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        System.runAs(FACULTY_USER){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];
            reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c WHERE Name = 'SEC302'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));
            System.Assert.isTrue(String.isNotBlank(studyUnit.Id));

            Set<Id> spsCheckIdSet = new Set<Id>();

            reduivy__Study_Plan_Structure__c newTopGroupSps = new reduivy__Study_Plan_Structure__c();
            newTopGroupSps.Name = 'New Top Group';
            newTopGroupSps.reduivy__Description__c = 'Test description';
            newTopGroupSps.reduivy__Category__c = 'Optional';
            newTopGroupSps.reduivy__Credits__c = 10;
            newTopGroupSps.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
            newTopGroupSps.reduivy__Study_Plan__c = studyPlan.Id;
            insert newTopGroupSps;
            spsCheckIdSet.add(newTopGroupSps.Id);

            reduivy__Study_Plan_Structure__c newChildGroupSps = new reduivy__Study_Plan_Structure__c();
            newChildGroupSps.Name = 'New Child Group';
            newChildGroupSps.reduivy__Description__c = 'Test description';
            newChildGroupSps.reduivy__Category__c = 'Optional';
            newChildGroupSps.reduivy__Credits__c = 10;
            newChildGroupSps.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
            newChildGroupSps.reduivy__Study_Plan__c = studyPlan.Id;
            newChildGroupSps.reduivy__Parent_Study_Plan_Structure__c = newTopGroupSps.Id;
            insert newChildGroupSps;
            spsCheckIdSet.add(newChildGroupSps.Id);

            reduivy__Study_Plan_Structure__c newUnitSps = new reduivy__Study_Plan_Structure__c();
            newUnitSps.Name = 'New Unit';
            newUnitSps.reduivy__Description__c = 'Test description';
            newUnitSps.reduivy__Category__c = 'Optional';
            newUnitSps.reduivy__Study_Unit__c = studyUnit.Id;
            newUnitSps.reduivy__Credits__c = 10;
            newUnitSps.RecordTypeId = SPS_Helper.getUnitRecordTypeId();
            newUnitSps.reduivy__Study_Plan__c = studyPlan.Id;
            newUnitSps.reduivy__Parent_Study_Plan_Structure__c = newChildGroupSps.Id;
            insert newUnitSps;
            spsCheckIdSet.add(newUnitSps.Id);

            try {
                REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.deleteStudyPlanStructure(newTopGroupSps.Id, SPS_Helper.getGroupRecordTypeId());
                System.Assert.fail('Faculty user should not have permission to delete reduivy__Study_Plan_Structure__c.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('Insufficient Delete access on following object(s) and field(s) - reduivy__Study_Plan_Structure__c'), 'The exception is invalid: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test delete top group as student
     */
    @IsTest
    static void testDeleteTopGroupAsStudent(){

        
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
            reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c WHERE Name = 'SEC302'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));
            System.Assert.isTrue(String.isNotBlank(studyUnit.Id));

            Set<Id> spsCheckIdSet = new Set<Id>();

            reduivy__Study_Plan_Structure__c newTopGroupSps = new reduivy__Study_Plan_Structure__c();
            newTopGroupSps.Name = 'New Top Group';
            newTopGroupSps.reduivy__Description__c = 'Test description';
            newTopGroupSps.reduivy__Category__c = 'Optional';
            newTopGroupSps.reduivy__Credits__c = 10;
            newTopGroupSps.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
            newTopGroupSps.reduivy__Study_Plan__c = studyPlan.Id;
            insert newTopGroupSps;
            spsCheckIdSet.add(newTopGroupSps.Id);

            reduivy__Study_Plan_Structure__c newChildGroupSps = new reduivy__Study_Plan_Structure__c();
            newChildGroupSps.Name = 'New Child Group';
            newChildGroupSps.reduivy__Description__c = 'Test description';
            newChildGroupSps.reduivy__Category__c = 'Optional';
            newChildGroupSps.reduivy__Credits__c = 10;
            newChildGroupSps.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
            newChildGroupSps.reduivy__Study_Plan__c = studyPlan.Id;
            newChildGroupSps.reduivy__Parent_Study_Plan_Structure__c = newTopGroupSps.Id;
            insert newChildGroupSps;
            spsCheckIdSet.add(newChildGroupSps.Id);

            reduivy__Study_Plan_Structure__c newUnitSps = new reduivy__Study_Plan_Structure__c();
            newUnitSps.Name = 'New Unit';
            newUnitSps.reduivy__Description__c = 'Test description';
            newUnitSps.reduivy__Category__c = 'Optional';
            newUnitSps.reduivy__Study_Unit__c = studyUnit.Id;
            newUnitSps.reduivy__Credits__c = 10;
            newUnitSps.RecordTypeId = SPS_Helper.getUnitRecordTypeId();
            newUnitSps.reduivy__Study_Plan__c = studyPlan.Id;
            newUnitSps.reduivy__Parent_Study_Plan_Structure__c = newChildGroupSps.Id;
            insert newUnitSps;
            spsCheckIdSet.add(newUnitSps.Id);

            try {
                REDU_LightningResponse response = REDU_StudyPlanHierarchy_LCTRL.deleteStudyPlanStructure(newTopGroupSps.Id, SPS_Helper.getGroupRecordTypeId());
                System.Assert.fail('Student user should not have permission to delete reduivy__Study_Plan_Structure__c.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('Insufficient Delete access on following object(s) and field(s) - reduivy__Study_Plan_Structure__c'), 'The exception is invalid: ' + exp.getMessage());
            }
        }

        Test.stopTest();
        
    }
}