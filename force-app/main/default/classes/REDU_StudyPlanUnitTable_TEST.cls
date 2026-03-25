/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_StudyPlanUnitTable_LCTRL
 * @changehistory
 * ISS-001617 14-11-2023 Lean - new component
 * ISS-002152 06-11-2024 Jordan - Study Plan Wizard to support modification
 * ISS-002736 25-11-2025 XiRouh - added wrapText param
 */
@IsTest
public inherited sharing class REDU_StudyPlanUnitTable_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    static final String COLUMN_RESULT_VIEW = '['
        + '{"label":"Study Plan Structure Name","fieldName":"linkName","type":"url","typeAttributes":{"tooltip":{"fieldName":"Name"},"label":{"fieldName":"Name"},"target":"_self"},"sortable":true,"wrapText":true},'
        + '{"label":"Credits","fieldName":"reduivy__Credits__c","type":"number","sortable":true,"cellAttributes":{"alignment":"left"},"editable":false,"wrapText":true},'
        + '{"label":"Study Unit","fieldName":"linkreduivy__Study_Unit__c","type":"url","typeAttributes":{"tooltip":{"fieldName":"reduivy__Study_Unit__r.Name"},"label":{"fieldName":"reduivy__Study_Unit__r.Name"},"target":"_self"},"sortable":true,"wrapText":true},'
        + '{"label":"Educational Institution","fieldName":"linkreduivy__Study_Unit__r.reduivy__Educational_Institution__c","type":"url","typeAttributes":{"tooltip":{"fieldName":"reduivy__Study_Unit__r.reduivy__Educational_Institution__r.Name"},"label":{"fieldName":"reduivy__Study_Unit__r.reduivy__Educational_Institution__r.Name"},"target":"_self"},"sortable":true,"wrapText":true}'
        + ']';

    static final String COLUMN_RESULT_EDIT = '['
        + '{"label":"Study Plan Structure Name","fieldName":"linkName","type":"url","typeAttributes":{"tooltip":{"fieldName":"Name"},"label":{"fieldName":"Name"},"target":"_self"},"sortable":true,"wrapText":true},'
        + '{"label":"Credits","fieldName":"reduivy__Credits__c","type":"number","sortable":true,"cellAttributes":{"alignment":"left"},"editable":false,"wrapText":true},'
        + '{"label":"Study Unit","fieldName":"linkreduivy__Study_Unit__c","type":"url","typeAttributes":{"tooltip":{"fieldName":"reduivy__Study_Unit__r.Name"},"label":{"fieldName":"reduivy__Study_Unit__r.Name"},"target":"_self"},"sortable":true,"wrapText":true},'
        + '{"label":"Educational Institution","fieldName":"linkreduivy__Study_Unit__r.reduivy__Educational_Institution__c","type":"url","typeAttributes":{"tooltip":{"fieldName":"reduivy__Study_Unit__r.reduivy__Educational_Institution__r.Name"},"label":{"fieldName":"reduivy__Study_Unit__r.reduivy__Educational_Institution__r.Name"},"target":"_self"},"sortable":true,"wrapText":true},'
        + '{"type":"action","typeAttributes":{"rowActions":[{"label":"Edit","name":"edit"},{"label":"Delete","name":"delete"}]}}'
        + ']';

    static final String REFLINK_RESULT = '['
        + '{"linkFieldName":"linkName","linkFieldValue":"Id","linkFieldLabel":"Name","linkFieldType":"url","linkFieldReferenceId":"Id"},'
        + '{"linkFieldName":"linkreduivy__Study_Unit__c","linkFieldValue":"reduivy__Study_Unit__c","linkFieldLabel":"reduivy__Study_Unit__r.Name","linkFieldType":"url","linkFieldReferenceId":"reduivy__Study_Unit__c"},'
        + '{"linkFieldName":"linkreduivy__Study_Unit__r.reduivy__Educational_Institution__c","linkFieldValue":"reduivy__Study_Unit__r.reduivy__Educational_Institution__c","linkFieldLabel":"reduivy__Study_Unit__r.reduivy__Educational_Institution__r.Name","linkFieldType":"url","linkFieldReferenceId":"reduivy__Study_Unit__r.reduivy__Educational_Institution__c"}'
        + ']';

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
     * @description Test get child units as admin
     */
    @IsTest
    static void testGetChildUnitsAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));

            Integer counter = 0;
            for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, Name
                FROM reduivy__Study_Plan_Structure__c
                WHERE reduivy__Study_Plan__c =: studyPlan.Id
                AND RecordTypeId =: SPS_Helper.getGroupRecordTypeId()
                AND (Name = 'BACBIS_MajorA_GROUPA_1_1' OR Name = 'BACBIS_MajorA_GROUPA_1_2' OR Name = 'BACBIS_MajorA_GROUPA_1')
                WITH USER_MODE
                ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST
            ]) {
                
                REDU_LightningResponse response = REDU_StudyPlanUnitTable_LCTRL.getUnitTableData(sps.Id, 'Name;reduivy__Credits__c;reduivy__Study_Unit__c;reduivy__Study_Unit__r.reduivy__Educational_Institution__c', true, '_self', true, UserInfo.getLanguage(), true);

                System.Assert.isTrue(String.isNotBlank(response.responseData));

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.RECORDS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.COLUMNS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.REFLINKS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.SITE_PATH_PREFIX_PARAM));

                System.Assert.areEqual(COLUMN_RESULT_VIEW, JSON.serialize(responseData.get(REDU_Datatable_UTIL.COLUMNS_PARAM)));
                System.Assert.areEqual(REFLINK_RESULT, JSON.serialize(responseData.get(REDU_Datatable_UTIL.REFLINKS_PARAM)));
                
                List<Object> data = (List<Object>)responseData.get(REDU_Datatable_UTIL.RECORDS_PARAM);

                if (sps.Name == 'BACBIS_MajorA_GROUPA_1_1') {
                    System.Assert.areEqual(4, data.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPA_1_2') {
                    System.Assert.areEqual(4, data.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPA_1') {
                    System.Assert.areEqual(0, data.size());
                } else {
                    System.Assert.fail('Invalid child group.');
                }

                counter ++;
            }

            System.Assert.areEqual(3, counter, 'There should be 3 child groups.');
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get child units as faculty
     */
    @IsTest
    static void testGetChildUnitsAsFaculty(){
                
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
                AND (Name = 'BACBIS_MajorA_GROUPA_1_1' OR Name = 'BACBIS_MajorA_GROUPA_1_2' OR Name = 'BACBIS_MajorA_GROUPA_1')
                WITH USER_MODE
                ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST
            ]) {
                
                REDU_LightningResponse response = REDU_StudyPlanUnitTable_LCTRL.getUnitTableData(sps.Id, 'Name;reduivy__Credits__c;reduivy__Study_Unit__c;reduivy__Study_Unit__r.reduivy__Educational_Institution__c', true, '_self', true, UserInfo.getLanguage(), true);

                System.Assert.isTrue(String.isNotBlank(response.responseData));

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.RECORDS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.COLUMNS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.REFLINKS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.SITE_PATH_PREFIX_PARAM));

                System.Assert.areEqual(COLUMN_RESULT_VIEW, JSON.serialize(responseData.get(REDU_Datatable_UTIL.COLUMNS_PARAM)));
                System.Assert.areEqual(REFLINK_RESULT, JSON.serialize(responseData.get(REDU_Datatable_UTIL.REFLINKS_PARAM)));

                List<Object> data = (List<Object>)responseData.get(REDU_Datatable_UTIL.RECORDS_PARAM);

                if (sps.Name == 'BACBIS_MajorA_GROUPA_1_1') {
                    System.Assert.areEqual(4, data.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPA_1_2') {
                    System.Assert.areEqual(4, data.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPA_1') {
                    System.Assert.areEqual(0, data.size());
                } else {
                    System.Assert.fail('Invalid child group.');
                }

                counter ++;
            }

            System.Assert.areEqual(3, counter, 'There should be 3 child groups.');
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get child units as student
     */
    @IsTest
    static void testGetChildUnitsAsStudent(){
        
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
                AND (Name = 'BACBIS_MajorA_GROUPA_1_1' OR Name = 'BACBIS_MajorA_GROUPA_1_2' OR Name = 'BACBIS_MajorA_GROUPA_1')
                WITH USER_MODE
                ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST
            ]) {
                
                REDU_LightningResponse response = REDU_StudyPlanUnitTable_LCTRL.getUnitTableData(sps.Id, 'Name;reduivy__Credits__c;reduivy__Study_Unit__c;reduivy__Study_Unit__r.reduivy__Educational_Institution__c', true, '_self', true, UserInfo.getLanguage(), true);

                System.Assert.isTrue(String.isNotBlank(response.responseData));

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.RECORDS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.COLUMNS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.REFLINKS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.SITE_PATH_PREFIX_PARAM));

                System.Assert.areEqual(COLUMN_RESULT_VIEW, JSON.serialize(responseData.get(REDU_Datatable_UTIL.COLUMNS_PARAM)));
                System.Assert.areEqual(REFLINK_RESULT, JSON.serialize(responseData.get(REDU_Datatable_UTIL.REFLINKS_PARAM)));

                List<Object> data = (List<Object>)responseData.get(REDU_Datatable_UTIL.RECORDS_PARAM);

                if (sps.Name == 'BACBIS_MajorA_GROUPA_1_1') {
                    System.Assert.areEqual(4, data.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPA_1_2') {
                    System.Assert.areEqual(4, data.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPA_1') {
                    System.Assert.areEqual(0, data.size());
                } else {
                    System.Assert.fail('Invalid child group.');
                }

                counter ++;
            }

            System.Assert.areEqual(3, counter, 'There should be 3 child groups.');
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get child units as non redu user to test the exception
     */
    @IsTest
    static void testGetChildUnitsException(){
        
        User nonReduUser = testFactory.getSetupUser();

        reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];

        System.Assert.isTrue(String.isNotBlank(studyPlan.Id));

        
        Test.startTest();
        Integer counter = 0;

        for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, Name
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c =: studyPlan.Id
            AND RecordTypeId =: SPS_Helper.getGroupRecordTypeId()
            AND Name = 'BACBIS_MajorA_GROUPA_1_1'
            WITH USER_MODE
            ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST
        ]) {
        
            System.runAs(nonReduUser){            
                try {
                    REDU_LightningResponse response = REDU_StudyPlanUnitTable_LCTRL.getUnitTableData(sps.Id, 'Name;reduivy__Credits__c;reduivy__Study_Unit__c;reduivy__Study_Unit__r.reduivy__Educational_Institution__c', true, '_self', true, UserInfo.getLanguage(), true);
                    System.Assert.fail('This should fail with FLS error.');

                } catch (Exception exp) {
                    REDU_Logging_UTIL.debug(exp);
                    System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s) - reduivy__Study_Plan_Structure__c'), 'The exception is invalid: ' + exp.getMessage());
                }

            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get child units as admin (edit mode)
     */
    @IsTest
    static void testGetChildUnitsAsAdminEditMode(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));

            Integer counter = 0;
            for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, Name
                FROM reduivy__Study_Plan_Structure__c
                WHERE reduivy__Study_Plan__c =: studyPlan.Id
                AND RecordTypeId =: SPS_Helper.getGroupRecordTypeId()
                AND (Name = 'BACBIS_MajorA_GROUPA_1_1' OR Name = 'BACBIS_MajorA_GROUPA_1_2' OR Name = 'BACBIS_MajorA_GROUPA_1')
                WITH USER_MODE
                ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST
            ]) {
                
                REDU_LightningResponse response = REDU_StudyPlanUnitTable_LCTRL.getUnitTableData(sps.Id, 'Name;reduivy__Credits__c;reduivy__Study_Unit__c;reduivy__Study_Unit__r.reduivy__Educational_Institution__c', true, '_self', false, UserInfo.getLanguage(), true);

                System.Assert.isTrue(String.isNotBlank(response.responseData));

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.RECORDS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.COLUMNS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.REFLINKS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.SITE_PATH_PREFIX_PARAM));

                System.Assert.areEqual(COLUMN_RESULT_EDIT, JSON.serialize(responseData.get(REDU_Datatable_UTIL.COLUMNS_PARAM)));
                System.Assert.areEqual(REFLINK_RESULT, JSON.serialize(responseData.get(REDU_Datatable_UTIL.REFLINKS_PARAM)));
                
                List<Object> data = (List<Object>)responseData.get(REDU_Datatable_UTIL.RECORDS_PARAM);

                if (sps.Name == 'BACBIS_MajorA_GROUPA_1_1') {
                    System.Assert.areEqual(4, data.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPA_1_2') {
                    System.Assert.areEqual(4, data.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPA_1') {
                    System.Assert.areEqual(0, data.size());
                } else {
                    System.Assert.fail('Invalid child group.');
                }

                counter ++;
            }

            System.Assert.areEqual(3, counter, 'There should be 3 child groups.');
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get child units as faculty (edit mode)
     */
    @IsTest
    static void testGetChildUnitsAsFacultyEditMode(){
                
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
                AND (Name = 'BACBIS_MajorA_GROUPA_1_1' OR Name = 'BACBIS_MajorA_GROUPA_1_2' OR Name = 'BACBIS_MajorA_GROUPA_1')
                WITH USER_MODE
                ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST
            ]) {
                
                REDU_LightningResponse response = REDU_StudyPlanUnitTable_LCTRL.getUnitTableData(sps.Id, 'Name;reduivy__Credits__c;reduivy__Study_Unit__c;reduivy__Study_Unit__r.reduivy__Educational_Institution__c', true, '_self', false, UserInfo.getLanguage(), true);

                System.Assert.isTrue(String.isNotBlank(response.responseData));

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.RECORDS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.COLUMNS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.REFLINKS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.SITE_PATH_PREFIX_PARAM));

                System.Assert.areEqual(COLUMN_RESULT_EDIT, JSON.serialize(responseData.get(REDU_Datatable_UTIL.COLUMNS_PARAM)));
                System.Assert.areEqual(REFLINK_RESULT, JSON.serialize(responseData.get(REDU_Datatable_UTIL.REFLINKS_PARAM)));

                List<Object> data = (List<Object>)responseData.get(REDU_Datatable_UTIL.RECORDS_PARAM);

                if (sps.Name == 'BACBIS_MajorA_GROUPA_1_1') {
                    System.Assert.areEqual(4, data.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPA_1_2') {
                    System.Assert.areEqual(4, data.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPA_1') {
                    System.Assert.areEqual(0, data.size());
                } else {
                    System.Assert.fail('Invalid child group.');
                }

                counter ++;
            }

            System.Assert.areEqual(3, counter, 'There should be 3 child groups.');
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get child units as student (edit mode)
     */
    @IsTest
    static void testGetChildUnitsAsStudentEditMode(){
        
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
                AND (Name = 'BACBIS_MajorA_GROUPA_1_1' OR Name = 'BACBIS_MajorA_GROUPA_1_2' OR Name = 'BACBIS_MajorA_GROUPA_1')
                WITH USER_MODE
                ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST
            ]) {
                
                REDU_LightningResponse response = REDU_StudyPlanUnitTable_LCTRL.getUnitTableData(sps.Id, 'Name;reduivy__Credits__c;reduivy__Study_Unit__c;reduivy__Study_Unit__r.reduivy__Educational_Institution__c', true, '_self', false, UserInfo.getLanguage(), true);

                System.Assert.isTrue(String.isNotBlank(response.responseData));

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.RECORDS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.COLUMNS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.REFLINKS_PARAM));
                System.Assert.areEqual(true, responseData.containsKey(REDU_Datatable_UTIL.SITE_PATH_PREFIX_PARAM));

                System.Assert.areEqual(COLUMN_RESULT_EDIT, JSON.serialize(responseData.get(REDU_Datatable_UTIL.COLUMNS_PARAM)));
                System.Assert.areEqual(REFLINK_RESULT, JSON.serialize(responseData.get(REDU_Datatable_UTIL.REFLINKS_PARAM)));

                List<Object> data = (List<Object>)responseData.get(REDU_Datatable_UTIL.RECORDS_PARAM);

                if (sps.Name == 'BACBIS_MajorA_GROUPA_1_1') {
                    System.Assert.areEqual(4, data.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPA_1_2') {
                    System.Assert.areEqual(4, data.size());
                } else if (sps.Name == 'BACBIS_MajorA_GROUPA_1') {
                    System.Assert.areEqual(0, data.size());
                } else {
                    System.Assert.fail('Invalid child group.');
                }

                counter ++;
            }

            System.Assert.areEqual(3, counter, 'There should be 3 child groups.');
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get child units as non redu user to test the exception (edit mode)
     */
    @IsTest
    static void testGetChildUnitsExceptionEditMode(){
        
        User nonReduUser = testFactory.getSetupUser();

        reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];

        System.Assert.isTrue(String.isNotBlank(studyPlan.Id));

        
        Test.startTest();
        Integer counter = 0;

        for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, Name
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c =: studyPlan.Id
            AND RecordTypeId =: SPS_Helper.getGroupRecordTypeId()
            AND Name = 'BACBIS_MajorA_GROUPA_1_1'
            WITH USER_MODE
            ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST
        ]) {
        
            System.runAs(nonReduUser){            
                try {
                    REDU_LightningResponse response = REDU_StudyPlanUnitTable_LCTRL.getUnitTableData(sps.Id, 'Name;reduivy__Credits__c;reduivy__Study_Unit__c;reduivy__Study_Unit__r.reduivy__Educational_Institution__c', true, '_self', false, UserInfo.getLanguage(), true);
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