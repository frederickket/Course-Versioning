/**
 * @author      WDCi (XiRouh)
 * @date        March 2025
 * @group       Test Class
 * @description Test class for REDU_TermGradeRelease_LCTRL
 * @changehistory
 * ISS-002311 06-03-2025 XiRouh - new class
 * ISS-002547 16-07-2025 Lean - Change to use job queue group
 */
@isTest
public with sharing class REDU_TermGradeReleaseModal_TEST {
    private static final String JOB_OPERATION = 'Term_Grade_Release';
    private static final String GRADE_RELEASE_STATUS = IEN_Helper.getGradeReleasedStatuses()[0];

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Initialise test data for each test
     */
    @TestSetup
    static void makeData(){
        
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();

        	testFactory.initMasterData(null);
            testFactory.initOfferingData(null);
			testFactory.initStudentData(IEN_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test getStudyTermDetails() as admin
     */
    @IsTest
    static void testgetStudyTermDetailsAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
    
        System.runAs(ADMIN_USER) {
            List<reduivy__Study_Term__c> studyTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

            REDU_LightningResponse response = REDU_TermGradeReleaseModal_LCTRL.getStudyTermDetails(studyTerm[0].Id);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, String> returnedMap = (Map<String, String>) JSON.deserialize(response.responseData, Map<String, String>.class);
            
            System.Assert.isTrue(returnedMap.containsKey('studyTermName'), 'ReturnedMap map should contain studyTermName key');
            System.Assert.isTrue(returnedMap.containsKey('educationalInstitutionId'), 'ReturnedMap map should contain educationalInstitutionId key');

            System.Assert.isFalse(String.isBlank(returnedMap.get('studyTermName')), 'studyTermName should not be blank');
            System.Assert.isFalse(String.isBlank(returnedMap.get('educationalInstitutionId')), 'educationalInstitutionId should not be blank');
        }

        Test.stopTest();
    }

    /**
     * @description Test getStudyTermDetails() as faculty
     */
    @IsTest
    static void testgetStudyTermDetailsAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();
    
        Test.startTest();
        
        System.runAs(FACULTY_USER) {

            List<reduivy__Study_Term__c> studyTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

            REDU_LightningResponse response = REDU_TermGradeReleaseModal_LCTRL.getStudyTermDetails(studyTerm[0].Id);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, String> returnedMap = (Map<String, String>) JSON.deserialize(response.responseData, Map<String, String>.class);
            
            System.Assert.isTrue(returnedMap.containsKey('studyTermName'), 'ReturnedMap map should contain studyTermName key');
            System.Assert.isTrue(returnedMap.containsKey('educationalInstitutionId'), 'ReturnedMap map should contain educationalInstitutionId key');

            System.Assert.isFalse(String.isBlank(returnedMap.get('studyTermName')), 'studyTermName should not be blank');
            System.Assert.isFalse(String.isBlank(returnedMap.get('educationalInstitutionId')), 'educationalInstitutionId should not be blank');
        }

        Test.stopTest();
    }

    /**
     * @description Test getStudyTermDetails() as student
     */
    @IsTest
    static void testgetStudyTermDetailsAsStudent(){
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
        
        System.runAs(reduStudent) {

            List<reduivy__Study_Term__c> studyTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

            REDU_LightningResponse response = REDU_TermGradeReleaseModal_LCTRL.getStudyTermDetails(studyTerm[0].Id);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, String> returnedMap = (Map<String, String>) JSON.deserialize(response.responseData, Map<String, String>.class);
            
            System.Assert.isTrue(returnedMap.containsKey('studyTermName'), 'ReturnedMap map should contain studyTermName key');
            System.Assert.isTrue(returnedMap.containsKey('educationalInstitutionId'), 'ReturnedMap map should contain educationalInstitutionId key');

            System.Assert.isFalse(String.isBlank(returnedMap.get('studyTermName')), 'studyTermName should not be blank');
            System.Assert.isFalse(String.isBlank(returnedMap.get('educationalInstitutionId')), 'educationalInstitutionId should not be blank');
        }

        Test.stopTest();
    }

     /**
     * @description Negative Test for getStudyTermDetails()
     */
    @IsTest
    static void testgetStudyTermDetailsWithInvalidParams() {
        User ADMIN_USER = testFactory.getReduAdminUser();


        System.runAs(ADMIN_USER) {
            Test.startTest();

            List<reduivy__Study_Term__c> studyTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicYearRecordTypeId() LIMIT 1];
            
            // Test with blank study term id
            try {
                REDU_TermGradeReleaseModal_LCTRL.getStudyTermDetails(null);
                System.Assert.fail('Expected an AuraHandledException for blank study Term ID');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters, 
                new List<String>{'studyTermRecordId'})), 
                                    'Unexpected error: ' + e.getMessage());
            }
            
            // Test with academic year
            try {
                REDU_TermGradeReleaseModal_LCTRL.getStudyTermDetails(studyTerm[0].Id);
                System.Assert.fail('Expected an AuraHandledException for academic year Id');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Invalid_Record_Id_For_Object_Type,
                new List<String>{studyTerm[0].Id, STM_Helper.getAcademicTermRecordTypeLabel()})), 
                                    'Unexpected error: ' + e.getMessage() + errorMsg);
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test getComboboxesOptions() as admin
     */
    @IsTest
    static void testGetComboboxesOptionsAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            Test.startTest();

            List<Account> acc = [
                SELECT Id
                FROM Account 
                WHERE RecordTypeId = :ACC_Helper.getEducationalInstitutionRecordTypeId()
                LIMIT 1
            ];

            REDU_LightningResponse response = REDU_TermGradeReleaseModal_LCTRL.getComboboxesOptions(acc[0].Id);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, Object> returnedMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.isTrue(returnedMap.containsKey('campuses'), 'ReturnedMap map should contain campuses key');

            List<Object> campuses = (List<Object>) returnedMap.get('campuses');

            System.Assert.isFalse(campuses.isEmpty(), 'campuses list should not be empty');

            Test.stopTest();
        }
    }

    /**
     * @description Test getComboboxesOptions() as faculty
     */
    @IsTest
    static void testGetComboboxesOptionsAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        System.runAs(FACULTY_USER) {
            Test.startTest();

            List<Account> acc = [
                SELECT Id
                FROM Account 
                WHERE RecordTypeId = :ACC_Helper.getEducationalInstitutionRecordTypeId()
                LIMIT 1
            ];

            REDU_LightningResponse response = REDU_TermGradeReleaseModal_LCTRL.getComboboxesOptions(acc[0].Id);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, Object> returnedMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.isTrue(returnedMap.containsKey('campuses'), 'ReturnedMap map should contain campuses key');

            List<Object> campuses = (List<Object>) returnedMap.get('campuses');
            List<Object> academicTerms = (List<Object>) returnedMap.get('academicTerms');

            System.Assert.isFalse(campuses.isEmpty(), 'campuses list should not be empty');

            Test.stopTest();
        }
    }

    /**
     * @description Test getComboboxesOptions() as student
     */
    @IsTest
    static void testGetComboboxesOptionsAsStudent() {
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

            List<Account> acc = [
                SELECT Id
                FROM Account 
                WHERE RecordTypeId = :ACC_Helper.getEducationalInstitutionRecordTypeId()
                LIMIT 1
            ];

            REDU_LightningResponse response = REDU_TermGradeReleaseModal_LCTRL.getComboboxesOptions(acc[0].Id);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, Object> returnedMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.isTrue(returnedMap.containsKey('campuses'), 'ReturnedMap map should contain campuses key');

            List<Object> campuses = (List<Object>) returnedMap.get('campuses');

            System.Assert.isFalse(campuses.isEmpty(), 'campuses list should not be empty');

            Test.stopTest();
        }
    }

    /**
     * @description Negative Test for getComboboxesOptions()
     */
    @IsTest
    static void testGetComboboxesOptionsWithInvalidParams() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();

            // Test with blank educationalInstitutionId
            try {
                REDU_TermGradeReleaseModal_LCTRL.getComboboxesOptions(null);
                System.Assert.fail('Expected an AuraHandledException for blank educationalInstitutionId');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters, 
                new List<String>{'educationalInstitutionId'})), 
                                    'Unexpected error: ' + e.getMessage());
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test getStudyUnitData() as admin
     */
    @IsTest
    static void testGetStudyUnitDataAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();

            String studyUnitFields = 'Name;reduivy__Unit_Code__c';
            String studyOfferingStatuses = 'Running;Running (Enrollment Opened);Completed;';

            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            List<reduivy__Study_Offering__c> sof = [SELECT Id, reduivy__Academic_Term__c, reduivy__Academic_Term__r.reduivy__Academic_Year__c, reduivy__Campus__c FROM reduivy__Study_Offering__c WHERE reduivy__Status__c IN :sofStatusesSet LIMIT 1];

            reduivy__Study_Term__c stWithoutStudyOffering = new reduivy__Study_Term__c();
            stWithoutStudyOffering.Name = 'Test Term';
            stWithoutStudyOffering.reduivy__Academic_Year__c = sof[0].reduivy__Academic_Term__r.reduivy__Academic_Year__c;
            stWithoutStudyOffering.reduivy__Start_Date__c = System.today();
            stWithoutStudyOffering.reduivy__Census_Date__c = System.today().addDays(10);
            stWithoutStudyOffering.reduivy__End_Date__c = System.today().addDays(30);

            insert stWithoutStudyOffering;

            REDU_LightningResponse response1 = REDU_TermGradeReleaseModal_LCTRL.getStudyUnitData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, studyUnitFields, studyOfferingStatuses);
            REDU_LightningResponse response2 = REDU_TermGradeReleaseModal_LCTRL.getStudyUnitData(stWithoutStudyOffering.Id, sof[0].reduivy__Campus__c, studyUnitFields, studyOfferingStatuses);

            // Verify response1
            System.Assert.isTrue(response1.isSuccess, 'Response1 should be successful');
            System.Assert.isTrue(String.isNotBlank(response1.responseData), 'Response1 data should not be blank');

            Map<String, Object> finalMap1 = (Map<String, Object>) JSON.deserializeUntyped(response1.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap1.containsKey('studyUnitRecords'), 'Response1 should contain studyUnitRecords key');            
            
            // Verify records
            List<Object> recordsMapObj1 = (List<Object>) finalMap1.get('studyUnitRecords');
            System.Assert.isFalse(recordsMapObj1.isEmpty(), 'records map should not be empty');

            // Verify response2
            System.Assert.isTrue(response2.isSuccess, 'Response1 should be successful');
            System.Assert.isTrue(String.isNotBlank(response2.responseData), 'Response2 data should not be blank');

            Map<String, Object> finalMap2 = (Map<String, Object>) JSON.deserializeUntyped(response2.responseData);
            
            // Verify map structure
            System.Assert.isFalse(finalMap2.containsKey('studyUnitRecords'), 'Response2 should not contain studyUnitRecords key');            

            Test.stopTest();
        }
    }

    /**
     * @description Test getStudyUnitData() as faculty
     */
    @IsTest
    static void testGetStudyUnitDataAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        String studyUnitFields = 'Name;reduivy__Unit_Code__c';
        String studyOfferingStatuses = 'Running;Running (Enrollment Opened);Completed;';

        Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

        List<reduivy__Study_Offering__c> sof = [SELECT Id, reduivy__Academic_Term__c, reduivy__Academic_Term__r.reduivy__Academic_Year__c, reduivy__Campus__c FROM reduivy__Study_Offering__c WHERE reduivy__Status__c IN :sofStatusesSet LIMIT 1];

        reduivy__Study_Term__c stWithoutStudyOffering = new reduivy__Study_Term__c();
        stWithoutStudyOffering.Name = 'Test Term';
        stWithoutStudyOffering.reduivy__Academic_Year__c = sof[0].reduivy__Academic_Term__r.reduivy__Academic_Year__c;
        stWithoutStudyOffering.reduivy__Start_Date__c = System.today();
        stWithoutStudyOffering.reduivy__Census_Date__c = System.today().addDays(10);
        stWithoutStudyOffering.reduivy__End_Date__c = System.today().addDays(30);

        insert stWithoutStudyOffering;

        System.runAs(FACULTY_USER) {
            Test.startTest();

            REDU_LightningResponse response1 = REDU_TermGradeReleaseModal_LCTRL.getStudyUnitData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, studyUnitFields, studyOfferingStatuses);
            REDU_LightningResponse response2 = REDU_TermGradeReleaseModal_LCTRL.getStudyUnitData(stWithoutStudyOffering.Id, sof[0].reduivy__Campus__c, studyUnitFields, studyOfferingStatuses);

            // Verify response1
            System.Assert.isTrue(response1.isSuccess, 'Response1 should be successful');
            System.Assert.isTrue(String.isNotBlank(response1.responseData), 'Response1 data should not be blank');

            Map<String, Object> finalMap1 = (Map<String, Object>) JSON.deserializeUntyped(response1.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap1.containsKey('studyUnitRecords'), 'Response1 should contain studyUnitRecords key');            
            
            // Verify records
            List<Object> recordsMapObj1 = (List<Object>) finalMap1.get('studyUnitRecords');
            System.Assert.isFalse(recordsMapObj1.isEmpty(), 'records map should not be empty');

            // Verify response2
            System.Assert.isTrue(response2.isSuccess, 'Response1 should be successful');
            System.Assert.isTrue(String.isNotBlank(response2.responseData), 'Response2 data should not be blank');

            Map<String, Object> finalMap2 = (Map<String, Object>) JSON.deserializeUntyped(response2.responseData);
            
            // Verify map structure
            System.Assert.isFalse(finalMap2.containsKey('studyUnitRecords'), 'Response2 should not contain studyUnitRecords key');            

            Test.stopTest();
        }
    }
    
    /**
     * @description Test getStudyUnitData() as student
     */
    @IsTest
    static void testGetStudyUnitDataAsStudent(){
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

        String studyUnitFields = 'Name;reduivy__Unit_Code__c';
        String studyOfferingStatuses = 'Running;Running (Enrollment Opened);Completed;';

        Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

        List<reduivy__Study_Offering__c> sof = [SELECT Id, reduivy__Academic_Term__c, reduivy__Academic_Term__r.reduivy__Academic_Year__c, reduivy__Campus__c FROM reduivy__Study_Offering__c WHERE reduivy__Status__c IN :sofStatusesSet LIMIT 1];

        reduivy__Study_Term__c stWithoutStudyOffering = new reduivy__Study_Term__c();
        stWithoutStudyOffering.Name = 'Test Term';
        stWithoutStudyOffering.reduivy__Academic_Year__c = sof[0].reduivy__Academic_Term__r.reduivy__Academic_Year__c;
        stWithoutStudyOffering.reduivy__Start_Date__c = System.today();
        stWithoutStudyOffering.reduivy__Census_Date__c = System.today().addDays(10);
        stWithoutStudyOffering.reduivy__End_Date__c = System.today().addDays(30);

        insert stWithoutStudyOffering;

        System.runAs(reduStudent) {
            Test.startTest();

            REDU_LightningResponse response1 = REDU_TermGradeReleaseModal_LCTRL.getStudyUnitData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, studyUnitFields, studyOfferingStatuses);
            REDU_LightningResponse response2 = REDU_TermGradeReleaseModal_LCTRL.getStudyUnitData(stWithoutStudyOffering.Id, sof[0].reduivy__Campus__c, studyUnitFields, studyOfferingStatuses);

            // Verify response1
            System.Assert.isTrue(response1.isSuccess, 'Response1 should be successful');
            System.Assert.isTrue(String.isNotBlank(response1.responseData), 'Response1 data should not be blank');

            Map<String, Object> finalMap1 = (Map<String, Object>) JSON.deserializeUntyped(response1.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap1.containsKey('studyUnitRecords'), 'Response1 should contain studyUnitRecords key');            
            
            // Verify records
            List<Object> recordsMapObj1 = (List<Object>) finalMap1.get('studyUnitRecords');
            System.Assert.isFalse(recordsMapObj1.isEmpty(), 'records map should not be empty');

            // Verify response2
            System.Assert.isTrue(response2.isSuccess, 'Response1 should be successful');
            System.Assert.isTrue(String.isNotBlank(response2.responseData), 'Response2 data should not be blank');

            Map<String, Object> finalMap2 = (Map<String, Object>) JSON.deserializeUntyped(response2.responseData);
            
            // Verify map structure
            System.Assert.isFalse(finalMap2.containsKey('studyUnitRecords'), 'Response2 should not contain studyUnitRecords key');            

            Test.stopTest();
        }
    }

    /**
     * @description Negative Test for getStudyUnitData()
     */
    @IsTest
    static void testGetStudyUnitDataWithInvalidParams() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();

            String studyUnitFields = 'Name;reduivy__Unit_Code__c';
            String studyOfferingStatuses = 'Running;Running (Enrollment Opened);Completed;';

            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            List<reduivy__Study_Offering__c> sof = [SELECT Id, reduivy__Academic_Term__c, reduivy__Campus__c FROM reduivy__Study_Offering__c WHERE reduivy__Status__c IN :sofStatusesSet LIMIT 1];

            //Test for blank RecordId
            try {
                REDU_TermGradeReleaseModal_LCTRL.getStudyUnitData('', sof[0].reduivy__Campus__c, studyUnitFields, studyOfferingStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank termId');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'termId'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank selectedCampusId
            try {
                REDU_TermGradeReleaseModal_LCTRL.getStudyUnitData(sof[0].reduivy__Academic_Term__c, '', studyUnitFields, studyOfferingStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank selectedCampusId');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'selectedCampusId'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank studyUnitFields
            try {
                REDU_TermGradeReleaseModal_LCTRL.getStudyUnitData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, '', studyOfferingStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank jobOperation');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'studyUnitFields'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank studyOfferingStatuses
            try {
                REDU_TermGradeReleaseModal_LCTRL.getStudyUnitData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, studyUnitFields, '');
                System.Assert.fail('Expected an AuraHandledException for blank jobOperation');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'studyOfferingStatuses'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }
        }
    }

    /**
     * @description Test getStudyOfferingData() as admin
     */
    @IsTest
    static void testGetStudyOfferingDataAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();

            String studyOfferingFields = 'Name;reduivy__Booked_Places__c';
            String studyOfferingStatuses = 'Running;Running (Enrollment Opened);Completed;';

            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            List<reduivy__Study_Offering__c> sof = [SELECT reduivy__Study_Unit__c, reduivy__Academic_Term__c, reduivy__Campus__c FROM reduivy__Study_Offering__c WHERE reduivy__Status__c IN :sofStatusesSet LIMIT 1];
            List<Account> eduIns = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_Helper.getEducationalInstitutionRecordTypeId() LIMIT 1];

            reduivy__Study_Unit__c sunWithoutSof = new reduivy__Study_Unit__c();
            sunWithoutSof.Name = 'Test Study Unit';
            sunWithoutSof.reduivy__Unit_Code__c = 'TSU';
            sunWithoutSof.reduivy__Credits__c = 10;
            sunWithoutSof.reduivy__Educational_Institution__c = eduIns[0].Id;

            insert sunWithoutSof;
            
            REDU_LightningResponse response1 = REDU_TermGradeReleaseModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, new List<Id>{sof[0].reduivy__Study_Unit__c}, studyOfferingFields, studyOfferingStatuses);
            REDU_LightningResponse response2 = REDU_TermGradeReleaseModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, new List<Id>{sunWithoutSof.Id}, studyOfferingFields, studyOfferingStatuses);

            // Verify response1
            System.Assert.isTrue(response1.isSuccess, 'Response1 should be successful');
            System.Assert.isTrue(String.isNotBlank(response1.responseData), 'Response1 data should not be blank');

            Map<String, Object> finalMap1 = (Map<String, Object>) JSON.deserializeUntyped(response1.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap1.containsKey('studyOfferingRecords'), 'Response1 should contain studyOfferingRecords key');            
            
            // Verify records
            List<Object> recordsMapObj1 = (List<Object>) finalMap1.get('studyOfferingRecords');
            System.Assert.isFalse(recordsMapObj1.isEmpty(), 'records map should not be empty');

            // Verify response2
            System.Assert.isTrue(response2.isSuccess, 'Response1 should be successful');
            System.Assert.isTrue(String.isNotBlank(response2.responseData), 'Response2 data should not be blank');

            Map<String, Object> finalMap2 = (Map<String, Object>) JSON.deserializeUntyped(response2.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap2.containsKey('studyOfferingRecords'), 'Response2 should contain studyOfferingRecords key');            
            
            // Verify records
            List<Object> recordsMapObj2 = (List<Object>) finalMap2.get('studyOfferingRecords');
            System.Assert.isTrue(recordsMapObj2.isEmpty(), 'records map should be empty');

            Test.stopTest();
        }
    }

    /**
     * @description Test getStudyOfferingData() as faculty
     */
    @IsTest
    static void testGetStudyOfferingDataAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        String studyOfferingFields = 'Name;reduivy__Booked_Places__c';
        String studyOfferingStatuses = 'Running;Running (Enrollment Opened);Completed;';

        Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

        List<reduivy__Study_Offering__c> sof = [SELECT reduivy__Study_Unit__c, reduivy__Academic_Term__c, reduivy__Campus__c FROM reduivy__Study_Offering__c WHERE reduivy__Status__c IN :sofStatusesSet LIMIT 1];
        List<Account> eduIns = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_Helper.getEducationalInstitutionRecordTypeId() LIMIT 1];

        reduivy__Study_Unit__c sunWithoutSof = new reduivy__Study_Unit__c();
        sunWithoutSof.Name = 'Test Study Unit';
        sunWithoutSof.reduivy__Unit_Code__c = 'TSU';
        sunWithoutSof.reduivy__Credits__c = 10;
        sunWithoutSof.reduivy__Educational_Institution__c = eduIns[0].Id;

        insert sunWithoutSof;

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            REDU_LightningResponse response1 = REDU_TermGradeReleaseModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, new List<Id>{sof[0].reduivy__Study_Unit__c}, studyOfferingFields, studyOfferingStatuses);
            REDU_LightningResponse response2 = REDU_TermGradeReleaseModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, new List<Id>{sunWithoutSof.Id}, studyOfferingFields, studyOfferingStatuses);

            // Verify response1
            System.Assert.isTrue(response1.isSuccess, 'Response1 should be successful');
            System.Assert.isTrue(String.isNotBlank(response1.responseData), 'Response1 data should not be blank');

            Map<String, Object> finalMap1 = (Map<String, Object>) JSON.deserializeUntyped(response1.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap1.containsKey('studyOfferingRecords'), 'Response1 should contain studyOfferingRecords key');            
            
            // Verify records
            List<Object> recordsMapObj1 = (List<Object>) finalMap1.get('studyOfferingRecords');
            System.Assert.isFalse(recordsMapObj1.isEmpty(), 'records map should not be empty');

            // Verify response2
            System.Assert.isTrue(response2.isSuccess, 'Response1 should be successful');
            System.Assert.isTrue(String.isNotBlank(response2.responseData), 'Response2 data should not be blank');

            Map<String, Object> finalMap2 = (Map<String, Object>) JSON.deserializeUntyped(response2.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap2.containsKey('studyOfferingRecords'), 'Response2 should contain studyOfferingRecords key');            
            
            // Verify records
            List<Object> recordsMapObj2 = (List<Object>) finalMap2.get('studyOfferingRecords');
            System.Assert.isTrue(recordsMapObj2.isEmpty(), 'records map should be empty');

            Test.stopTest();
        }
    }

    /**
     * @description Test getStudyOfferingData() as student
     */
    @IsTest
    static void testGetStudyOfferingDataAsStudent(){
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

        String studyOfferingFields = 'Name;reduivy__Booked_Places__c';
        String studyOfferingStatuses = 'Running;Running (Enrollment Opened);Completed;';

        Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

        List<reduivy__Study_Offering__c> sof = [SELECT reduivy__Study_Unit__c, reduivy__Academic_Term__c, reduivy__Campus__c FROM reduivy__Study_Offering__c WHERE reduivy__Status__c IN :sofStatusesSet LIMIT 1];
        List<Account> eduIns = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_Helper.getEducationalInstitutionRecordTypeId() LIMIT 1];

        reduivy__Study_Unit__c sunWithoutSof = new reduivy__Study_Unit__c();
        sunWithoutSof.Name = 'Test Study Unit';
        sunWithoutSof.reduivy__Unit_Code__c = 'TSU';
        sunWithoutSof.reduivy__Credits__c = 10;
        sunWithoutSof.reduivy__Educational_Institution__c = eduIns[0].Id;

        insert sunWithoutSof;

        System.runAs(reduStudent) {
            Test.startTest();
            
            REDU_LightningResponse response1 = REDU_TermGradeReleaseModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, new List<Id>{sof[0].reduivy__Study_Unit__c}, studyOfferingFields, studyOfferingStatuses);
            REDU_LightningResponse response2 = REDU_TermGradeReleaseModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, new List<Id>{sunWithoutSof.Id}, studyOfferingFields, studyOfferingStatuses);

            // Verify response1
            System.Assert.isTrue(response1.isSuccess, 'Response1 should be successful');
            System.Assert.isTrue(String.isNotBlank(response1.responseData), 'Response1 data should not be blank');

            Map<String, Object> finalMap1 = (Map<String, Object>) JSON.deserializeUntyped(response1.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap1.containsKey('studyOfferingRecords'), 'Response1 should contain studyOfferingRecords key');            
            
            // Verify records
            List<Object> recordsMapObj1 = (List<Object>) finalMap1.get('studyOfferingRecords');
            System.Assert.isFalse(recordsMapObj1.isEmpty(), 'records map should not be empty');

            // Verify response2
            System.Assert.isTrue(response2.isSuccess, 'Response1 should be successful');
            System.Assert.isTrue(String.isNotBlank(response2.responseData), 'Response2 data should not be blank');

            Map<String, Object> finalMap2 = (Map<String, Object>) JSON.deserializeUntyped(response2.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap2.containsKey('studyOfferingRecords'), 'Response2 should contain studyOfferingRecords key');            
            
            // Verify records
            List<Object> recordsMapObj2 = (List<Object>) finalMap2.get('studyOfferingRecords');
            System.Assert.isTrue(recordsMapObj2.isEmpty(), 'records map should be empty');

            Test.stopTest();
        }
    }

    /**
     * @description Negative Test for getStudyOfferingData()
     */
    @IsTest
    static void testGetStudyOfferingDataWithInvalidParams() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();

            String studyOfferingFields = 'Name;reduivy__Booked_Places__c';
            String studyOfferingStatuses = 'Running;Running (Enrollment Opened);Completed;';

            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            List<reduivy__Study_Offering__c> sof = [SELECT reduivy__Study_Unit__c, reduivy__Academic_Term__c, reduivy__Campus__c FROM reduivy__Study_Offering__c WHERE reduivy__Status__c IN :sofStatusesSet LIMIT 1];

            //Test for blank termId
            try {
                REDU_TermGradeReleaseModal_LCTRL.getStudyOfferingData('', sof[0].reduivy__Campus__c, new List<Id>{sof[0].reduivy__Study_Unit__c}, '', studyOfferingStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank termId');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'termId'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank selectedCampusId
            try {
                REDU_TermGradeReleaseModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c, '', new List<Id>{sof[0].reduivy__Study_Unit__c}, '', studyOfferingStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank selectedCampusId');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'selectedCampusId'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank studyOfferingFields
            try {
                REDU_TermGradeReleaseModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, new List<Id>{sof[0].reduivy__Study_Unit__c}, '', studyOfferingStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank studyOfferingFields');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'studyOfferingFields'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank studyOfferingStatuses
            try {
                REDU_TermGradeReleaseModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, new List<Id>{sof[0].reduivy__Study_Unit__c}, studyOfferingFields, '');
                System.Assert.fail('Expected an AuraHandledException for blank studyOfferingStatuses');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'studyOfferingStatuses'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test initQueueJob() as admin
     */
    @IsTest
    static void testInitQueueJobAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();
            List<reduivy__Individual_Enrollment__c> ien = [SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c FROM reduivy__Individual_Enrollment__c WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId() AND reduivy__Study_Offering__c != null LIMIT 1];

            //Load component, ensuring no current jobs are found
            String jobQueueGroupFields = 'Name;CreatedDate;reduivy__Total_Records__c;reduivy__Success_Records__c;reduivy__Error_Records__c;reduivy__Status__c';
            String jobQueueGroupStatuses = 'Pending;Processing;Completed;Failed';

            REDU_LightningResponse response = REDU_TermGradeRelease_LCTRL.getJobQueueData(JOB_OPERATION, ien[0].reduivy__Academic_Term_Id__c, jobQueueGroupFields, jobQueueGroupStatuses);

            // Verify records
            Map<String, Object> finalMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

            List<Object> recordsMapObj = (List<Object>) finalMap.get('jobQueueGroupRecords');
            System.Assert.isTrue(recordsMapObj.isEmpty(), 'records map should be empty');
            
            //Create new job
            REDU_LightningResponse response1 = REDU_TermGradeReleaseModal_LCTRL.initQueueJob(ien[0].reduivy__Academic_Term_Id__c, JOB_OPERATION, new List<Id>{ien[0].reduivy__Study_Offering__c}, GRADE_RELEASE_STATUS);
            System.Assert.isTrue(response1.isSuccess, response1.message);

            Test.stopTest();

            String jobOperationContext = JQH_Helper.getJobOperationContext(JOB_OPERATION, ien[0].reduivy__Academic_Term_Id__c);
            //Check Job is created
            List<reduivy__Job_Queue_Group__c> jobQueueGroups = [SELECT Id, reduivy__Job_Operation_Context__c FROM reduivy__Job_Queue_Group__c WHERE reduivy__Job_Operation_Context__c =: jobOperationContext];
            
            System.Assert.areEqual(1, jobQueueGroups.size(), 'A Job Queue group should be created.');

            //Check new job shows in list
            response = REDU_TermGradeRelease_LCTRL.getJobQueueData(JOB_OPERATION, ien[0].reduivy__Academic_Term_Id__c, jobQueueGroupFields, jobQueueGroupStatuses);

            // Verify response
            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            finalMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap.containsKey('jobQueueGroupRecords'), 'Response should contain jobQueueGroupRecords key');            
            
            // Verify records
            recordsMapObj = (List<Object>) finalMap.get('jobQueueGroupRecords');
            System.Assert.isFalse(recordsMapObj.isEmpty(), 'records map should not be empty');
        }
    }

    /**
     * @description Negative Test for initQueueJob()
     */
    @IsTest
    static void testInitQueueJobWithInvalidParams() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();

            List<reduivy__Individual_Enrollment__c> ien = [SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c FROM reduivy__Individual_Enrollment__c WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId() AND reduivy__Study_Offering__c != null LIMIT 1];

            //Test for blank termId
            try {
                REDU_TermGradeReleaseModal_LCTRL.initQueueJob('', JOB_OPERATION, new List<Id>{ien[0].reduivy__Study_Offering__c}, GRADE_RELEASE_STATUS);
                System.Assert.fail('Expected an AuraHandledException for blank termId');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'termId'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank jobOperation
            try {
                REDU_TermGradeReleaseModal_LCTRL.initQueueJob(ien[0].reduivy__Academic_Term_Id__c, '', new List<Id>{ien[0].reduivy__Study_Offering__c}, GRADE_RELEASE_STATUS);
                System.Assert.fail('Expected an AuraHandledException for blank jobOperation');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'jobOperation'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank selectedGradeReleaseStatus
            try {
                REDU_TermGradeReleaseModal_LCTRL.initQueueJob(ien[0].reduivy__Academic_Term_Id__c, JOB_OPERATION, new List<Id>{ien[0].reduivy__Study_Offering__c}, '');
                System.Assert.fail('Expected an AuraHandledException for blank selectedGradeReleaseStatus');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'selectedGradeReleaseStatus'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for empty toBeProcessedStudyOfferingIds
            REDU_TermGradeReleaseModal_LCTRL.initQueueJob(ien[0].reduivy__Academic_Term_Id__c, JOB_OPERATION, new List<Id>(), GRADE_RELEASE_STATUS);

            Test.stopTest();

            //Should not have any job queue records created as no id are being passed
            String jobQueueGroupFields = 'Name;CreatedDate;reduivy__Total_Records__c;reduivy__Success_Records__c;reduivy__Error_Records__c;reduivy__Status__c';
            String jobQueueGroupStatuses = 'Pending;Processing;Completed;Failed';
            
            REDU_LightningResponse response = REDU_TermGradeRelease_LCTRL.getJobQueueData(JOB_OPERATION, ien[0].reduivy__Academic_Term_Id__c, jobQueueGroupFields, jobQueueGroupStatuses);

            // Verify records
            Map<String, Object> finalMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

            List<Object> recordsMapObj = (List<Object>) finalMap.get('jobQueueGroupRecords');
            System.Assert.isTrue(recordsMapObj.isEmpty(), 'records map should be empty');
        }
    }
}