/**
 * @author      WDCi (XiRouh)
 * @date        March 2025
 * @group       Test Class
 * @description Test Class for REDU_TermOfferingsCloningModal_LCTRL
 * @changehistory
 * ISS-002200 17-03-2025 XiRouh - new class 
 * ISS-002364 22-04-2025 XiRouh - Updated initQueueJob test method
 * ISS-002547 16-07-2025 Lean - Change to use job queue group
 */
@isTest
public inherited sharing class REDU_TermOfferingsCloningModal_TEST {

    private static final String ACADEMIC_TERM_RECORD_TYPE_ID = STM_Helper.getAcademicTermRecordTypeId();
    private static final String JOB_OPERATION = 'Term_Offerings_Cloning';
    private static final String ALL_SELECTION_TYPE = Label.All;
    private static final String MANUAL_SELECTION_TYPE = Label.Term_Offerings_Cloning_Manual_Selection;

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
            testFactory.initStudentData(USR_Helper.getApiName(), true);

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

            REDU_LightningResponse response = REDU_TermOfferingsCloningModal_LCTRL.getStudyTermDetails(studyTerm[0].Id);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, String> returnedMap = (Map<String, String>) JSON.deserialize(response.responseData, Map<String, String>.class);
            
            System.Assert.isTrue(returnedMap.containsKey('studyTermName'), 'ReturnedMap map should contain studyTermName key');
            System.Assert.isTrue(returnedMap.containsKey('studyTermStartDate'), 'ReturnedMap map should contain studyTermStartDate key');
            System.Assert.isTrue(returnedMap.containsKey('studyTermEndDate'), 'ReturnedMap map should contain studyTermEndDate key');
            System.Assert.isTrue(returnedMap.containsKey('educationalInstitutionId'), 'ReturnedMap map should contain educationalInstitutionId key');

            System.Assert.isFalse(String.isBlank(returnedMap.get('studyTermName')), 'studyTermName should not be blank');
            System.Assert.isFalse(String.isBlank(returnedMap.get('studyTermStartDate')), 'studyTermStartDate should not be blank');
            System.Assert.isFalse(String.isBlank(returnedMap.get('studyTermEndDate')), 'studyTermEndDate should not be blank');
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

            REDU_LightningResponse response = REDU_TermOfferingsCloningModal_LCTRL.getStudyTermDetails(studyTerm[0].Id);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, String> returnedMap = (Map<String, String>) JSON.deserialize(response.responseData, Map<String, String>.class);
            
            System.Assert.isTrue(returnedMap.containsKey('studyTermName'), 'ReturnedMap map should contain studyTermName key');
            System.Assert.isTrue(returnedMap.containsKey('studyTermStartDate'), 'ReturnedMap map should contain studyTermStartDate key');
            System.Assert.isTrue(returnedMap.containsKey('studyTermEndDate'), 'ReturnedMap map should contain studyTermEndDate key');
            System.Assert.isTrue(returnedMap.containsKey('educationalInstitutionId'), 'ReturnedMap map should contain educationalInstitutionId key');

            System.Assert.isFalse(String.isBlank(returnedMap.get('studyTermName')), 'studyTermName should not be blank');
            System.Assert.isFalse(String.isBlank(returnedMap.get('studyTermStartDate')), 'studyTermStartDate should not be blank');
            System.Assert.isFalse(String.isBlank(returnedMap.get('studyTermEndDate')), 'studyTermEndDate should not be blank');
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

            REDU_LightningResponse response = REDU_TermOfferingsCloningModal_LCTRL.getStudyTermDetails(studyTerm[0].Id);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, String> returnedMap = (Map<String, String>) JSON.deserialize(response.responseData, Map<String, String>.class);
            
            System.Assert.isTrue(returnedMap.containsKey('studyTermName'), 'ReturnedMap map should contain studyTermName key');
            System.Assert.isTrue(returnedMap.containsKey('studyTermStartDate'), 'ReturnedMap map should contain studyTermStartDate key');
            System.Assert.isTrue(returnedMap.containsKey('studyTermEndDate'), 'ReturnedMap map should contain studyTermEndDate key');
            System.Assert.isTrue(returnedMap.containsKey('educationalInstitutionId'), 'ReturnedMap map should contain educationalInstitutionId key');

            System.Assert.isFalse(String.isBlank(returnedMap.get('studyTermName')), 'studyTermName should not be blank');
            System.Assert.isFalse(String.isBlank(returnedMap.get('studyTermStartDate')), 'studyTermStartDate should not be blank');
            System.Assert.isFalse(String.isBlank(returnedMap.get('studyTermEndDate')), 'studyTermEndDate should not be blank');
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
                REDU_TermOfferingsCloningModal_LCTRL.getStudyTermDetails(null);
                System.Assert.fail('Expected an AuraHandledException for blank study Term ID');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters, 
                new List<String>{'studyTermRecordId'})), 
                                    'Unexpected error: ' + e.getMessage());
            }
            
            // Test with academic year
            try {
                REDU_TermOfferingsCloningModal_LCTRL.getStudyTermDetails(studyTerm[0].Id);
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

            List<reduivy__Study_Term__c> stm = [
                SELECT Id, reduivy__Academic_Year__r.reduivy__Educational_Institution__c 
                FROM reduivy__Study_Term__c 
                WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID
                LIMIT 1
            ];

            REDU_LightningResponse response = REDU_TermOfferingsCloningModal_LCTRL.getComboboxesOptions(stm[0].Id, stm[0].reduivy__Academic_Year__r.reduivy__Educational_Institution__c);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, Object> returnedMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.isTrue(returnedMap.containsKey('campuses'), 'ReturnedMap map should contain campuses key');
            System.Assert.isTrue(returnedMap.containsKey('academicTerms'), 'ReturnedMap map should contain academicTerms key');

            List<Object> campuses = (List<Object>) returnedMap.get('campuses');
            List<Object> academicTerms = (List<Object>) returnedMap.get('academicTerms');

            System.Assert.isFalse(campuses.isEmpty(), 'campuses list should not be empty');
            System.Assert.isFalse(academicTerms.isEmpty(), 'academicTerms list should not be empty');

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

            List<reduivy__Study_Term__c> stm = [
                SELECT Id, reduivy__Academic_Year__r.reduivy__Educational_Institution__c 
                FROM reduivy__Study_Term__c 
                WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID
                LIMIT 1
            ];

            REDU_LightningResponse response = REDU_TermOfferingsCloningModal_LCTRL.getComboboxesOptions(stm[0].Id, stm[0].reduivy__Academic_Year__r.reduivy__Educational_Institution__c);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, Object> returnedMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.isTrue(returnedMap.containsKey('campuses'), 'ReturnedMap map should contain campuses key');
            System.Assert.isTrue(returnedMap.containsKey('academicTerms'), 'ReturnedMap map should contain academicTerms key');

            List<Object> campuses = (List<Object>) returnedMap.get('campuses');
            List<Object> academicTerms = (List<Object>) returnedMap.get('academicTerms');

            System.Assert.isFalse(campuses.isEmpty(), 'campuses list should not be empty');
            System.Assert.isFalse(academicTerms.isEmpty(), 'academicTerms list should not be empty');

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

            List<reduivy__Study_Term__c> stm = [
                SELECT Id, reduivy__Academic_Year__r.reduivy__Educational_Institution__c 
                FROM reduivy__Study_Term__c 
                WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID
                LIMIT 1
            ];

            REDU_LightningResponse response = REDU_TermOfferingsCloningModal_LCTRL.getComboboxesOptions(stm[0].Id, stm[0].reduivy__Academic_Year__r.reduivy__Educational_Institution__c);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, Object> returnedMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.isTrue(returnedMap.containsKey('campuses'), 'ReturnedMap map should contain campuses key');
            System.Assert.isTrue(returnedMap.containsKey('academicTerms'), 'ReturnedMap map should contain academicTerms key');

            List<Object> campuses = (List<Object>) returnedMap.get('campuses');
            List<Object> academicTerms = (List<Object>) returnedMap.get('academicTerms');

            System.Assert.isFalse(campuses.isEmpty(), 'campuses list should not be empty');
            System.Assert.isFalse(academicTerms.isEmpty(), 'academicTerms list should not be empty');

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

            List<reduivy__Study_Term__c> stm = [
                SELECT Id, reduivy__Academic_Year__r.reduivy__Educational_Institution__c 
                FROM reduivy__Study_Term__c 
                WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID
                LIMIT 1
            ];
            
            // Test with blank study term id
            try {
                REDU_TermOfferingsCloningModal_LCTRL.getComboboxesOptions(null, stm[0].reduivy__Academic_Year__r.reduivy__Educational_Institution__c);
                System.Assert.fail('Expected an AuraHandledException for blank study Term ID');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters, 
                new List<String>{'termId'})), 
                                    'Unexpected error: ' + e.getMessage());
            }
            
            // Test with blank educationalInstitutionId
            try {
                REDU_TermOfferingsCloningModal_LCTRL.getComboboxesOptions(stm[0].Id, null);
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
            String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';

            List<reduivy__Study_Offering__c> sof = [SELECT Id, reduivy__Academic_Term__c, reduivy__Academic_Term__r.reduivy__Academic_Year__c, reduivy__Campus__c FROM reduivy__Study_Offering__c];

            reduivy__Study_Term__c stWithoutStudyOffering = new reduivy__Study_Term__c();
            stWithoutStudyOffering.Name = 'Test Term';
            stWithoutStudyOffering.reduivy__Academic_Year__c = sof[0].reduivy__Academic_Term__r.reduivy__Academic_Year__c;
            stWithoutStudyOffering.reduivy__Start_Date__c = System.today();
            stWithoutStudyOffering.reduivy__Census_Date__c = System.today().addDays(10);
            stWithoutStudyOffering.reduivy__End_Date__c = System.today().addDays(30);

            insert stWithoutStudyOffering;

            REDU_LightningResponse response1 = REDU_TermOfferingsCloningModal_LCTRL.getStudyUnitData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, studyUnitFields, studyOfferingStatuses);
            REDU_LightningResponse response2 = REDU_TermOfferingsCloningModal_LCTRL.getStudyUnitData(stWithoutStudyOffering.Id, sof[0].reduivy__Campus__c, studyUnitFields, studyOfferingStatuses);

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
            System.Assert.isTrue(response2.isSuccess, 'Response2 should be successful');
            System.Assert.isTrue(String.isNotBlank(response2.responseData), 'Response2 data should not be blank');

            Map<String, Object> finalMap2 = (Map<String, Object>) JSON.deserializeUntyped(response2.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap2.containsKey('studyUnitRecords'), 'Response2 should contain studyUnitRecords key');  
            
            // Verify records
            List<Object> recordsMapObj2 = (List<Object>) finalMap2.get('studyUnitRecords');
            System.Assert.isTrue(recordsMapObj2.isEmpty(), 'records map should be empty');

            Test.stopTest();
        }
    }

    /**
     * @description Test getStudyUnitData() as faculty
     */
    @IsTest
    static void testGetStudyUnitDataAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER) {
            Test.startTest();

            String studyUnitFields = 'Name;reduivy__Unit_Code__c';
            String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';

            List<reduivy__Study_Offering__c> sof = [SELECT Id, reduivy__Academic_Term__c, reduivy__Academic_Term__r.reduivy__Academic_Year__c, reduivy__Campus__c FROM reduivy__Study_Offering__c];

            reduivy__Study_Term__c stWithoutStudyOffering = new reduivy__Study_Term__c();
            stWithoutStudyOffering.Name = 'Test Term';
            stWithoutStudyOffering.reduivy__Academic_Year__c = sof[0].reduivy__Academic_Term__r.reduivy__Academic_Year__c;
            stWithoutStudyOffering.reduivy__Start_Date__c = System.today();
            stWithoutStudyOffering.reduivy__Census_Date__c = System.today().addDays(10);
            stWithoutStudyOffering.reduivy__End_Date__c = System.today().addDays(30);

            insert stWithoutStudyOffering;

            REDU_LightningResponse response1 = REDU_TermOfferingsCloningModal_LCTRL.getStudyUnitData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, studyUnitFields, studyOfferingStatuses);
            REDU_LightningResponse response2 = REDU_TermOfferingsCloningModal_LCTRL.getStudyUnitData(stWithoutStudyOffering.Id, sof[0].reduivy__Campus__c, studyUnitFields, studyOfferingStatuses);

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
            System.Assert.isTrue(response2.isSuccess, 'Response2 should be successful');
            System.Assert.isTrue(String.isNotBlank(response2.responseData), 'Response2 data should not be blank');

            Map<String, Object> finalMap2 = (Map<String, Object>) JSON.deserializeUntyped(response2.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap2.containsKey('studyUnitRecords'), 'Response2 should contain studyUnitRecords key');  
            
            // Verify records
            List<Object> recordsMapObj2 = (List<Object>) finalMap2.get('studyUnitRecords');
            System.Assert.isTrue(recordsMapObj2.isEmpty(), 'records map should be empty');

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

        List<reduivy__Study_Offering__c> sof = [SELECT Id, reduivy__Academic_Term__c, reduivy__Academic_Term__r.reduivy__Academic_Year__c, reduivy__Campus__c FROM reduivy__Study_Offering__c];

        reduivy__Study_Term__c stWithoutStudyOffering = new reduivy__Study_Term__c();
        stWithoutStudyOffering.Name = 'Test Term';
        stWithoutStudyOffering.reduivy__Academic_Year__c = sof[0].reduivy__Academic_Term__r.reduivy__Academic_Year__c;
        stWithoutStudyOffering.reduivy__Start_Date__c = System.today();
        stWithoutStudyOffering.reduivy__Census_Date__c = System.today().addDays(10);
        stWithoutStudyOffering.reduivy__End_Date__c = System.today().addDays(30);

        insert stWithoutStudyOffering;

        System.runAs(reduStudent) {
            Test.startTest();

            String studyUnitFields = 'Name;reduivy__Unit_Code__c';
            String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';

            REDU_LightningResponse response1 = REDU_TermOfferingsCloningModal_LCTRL.getStudyUnitData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, studyUnitFields, studyOfferingStatuses);
            REDU_LightningResponse response2 = REDU_TermOfferingsCloningModal_LCTRL.getStudyUnitData(stWithoutStudyOffering.Id, sof[0].reduivy__Campus__c, studyUnitFields, studyOfferingStatuses);

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
            System.Assert.isTrue(response2.isSuccess, 'Response2 should be successful');
            System.Assert.isTrue(String.isNotBlank(response2.responseData), 'Response2 data should not be blank');

            Map<String, Object> finalMap2 = (Map<String, Object>) JSON.deserializeUntyped(response2.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap2.containsKey('studyUnitRecords'), 'Response2 should contain studyUnitRecords key');  
            
            // Verify records
            List<Object> recordsMapObj2 = (List<Object>) finalMap2.get('studyUnitRecords');
            System.Assert.isTrue(recordsMapObj2.isEmpty(), 'records map should be empty');

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

            List<reduivy__Study_Offering__c> sof = [
                SELECT Id, reduivy__Academic_Term__c, reduivy__Campus__c 
                FROM reduivy__Study_Offering__c
            ];

            String studyUnitFields = 'Name;reduivy__Unit_Code__c';
            String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';

            // Test with blank selectedTermId
            try {
                REDU_TermOfferingsCloningModal_LCTRL.getStudyUnitData(null, sof[0].reduivy__Campus__c, studyUnitFields, studyOfferingStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank selectedTermId');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters, 
                new List<String>{'selectedTermId'})), 
                                    'Unexpected error: ' + e.getMessage());
            }
            
            // Test with blank selectedCampusId
            try {
                REDU_TermOfferingsCloningModal_LCTRL.getStudyUnitData(sof[0].reduivy__Academic_Term__c, null, studyUnitFields, studyOfferingStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank selectedCampusId');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters, 
                new List<String>{'selectedCampusId'})), 
                                    'Unexpected error: ' + e.getMessage());
            }

            // Test with blank studyUnitFields
            try {
                REDU_TermOfferingsCloningModal_LCTRL.getStudyUnitData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, null, studyOfferingStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank studyUnitFields');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters, 
                new List<String>{'studyUnitFields'})), 
                                    'Unexpected error: ' + e.getMessage());
            }

             // Test with blank studyOfferingStatuses
            try {
                REDU_TermOfferingsCloningModal_LCTRL.getStudyUnitData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, studyUnitFields, null);
                System.Assert.fail('Expected an AuraHandledException for blank studyOfferingStatuses');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters, 
                new List<String>{'studyOfferingStatuses'})), 
                                    'Unexpected error: ' + e.getMessage());
            }
            
            Test.stopTest();
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

            String studyOfferingFields = 'Name;reduivy__Status__c';
            String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';
            Integer studyOfferingTableMaximumRowNumber = 1;

            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            List<reduivy__Study_Offering__c> sof = [SELECT reduivy__Study_Unit__c, reduivy__Academic_Term__c, reduivy__Academic_Term__r.reduivy__Academic_Year__r.reduivy__Educational_Institution__c, reduivy__Campus__c FROM reduivy__Study_Offering__c WHERE reduivy__Status__c IN :sofStatusesSet LIMIT 3];
            
            REDU_LightningResponse response1 = REDU_TermOfferingsCloningModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, new List<Id>{sof[0].reduivy__Study_Unit__c, sof[1].reduivy__Study_Unit__c, sof[2].reduivy__Study_Unit__c}, studyOfferingTableMaximumRowNumber, studyOfferingFields, studyOfferingStatuses);
            REDU_LightningResponse response2 = REDU_TermOfferingsCloningModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c,  sof[0].reduivy__Campus__c, new List<Id>{}, studyOfferingTableMaximumRowNumber, studyOfferingFields, studyOfferingStatuses);

            // Verify response1
            System.Assert.isTrue(response1.isSuccess, 'Response1 should be successful');
            System.Assert.isTrue(String.isNotBlank(response1.responseData), 'Response1 data should not be blank');

            Map<String, Object> finalMap1 = (Map<String, Object>) JSON.deserializeUntyped(response1.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap1.containsKey('studyOfferingRecordsWithLimitSet'), 'Response1 should contain studyOfferingRecordsWithLimitSet key');
            System.Assert.isTrue(finalMap1.containsKey('totalRecordCount'), 'Response1 should contain totalRecordCount key');            
   
            // Verify records
            List<Object> recordsMapObj1 = (List<Object>) finalMap1.get('studyOfferingRecordsWithLimitSet');
            System.Assert.isFalse(recordsMapObj1.isEmpty(), 'records map should not be empty');
            System.Assert.areEqual(studyOfferingTableMaximumRowNumber, recordsMapObj1.size());
            
            Integer totalRecordCount = (Integer) finalMap1.get('totalRecordCount');
            System.Assert.areEqual(3, totalRecordCount);

            // Verify response2
            System.Assert.isTrue(response2.isSuccess, 'Response2 should be successful');
            System.Assert.isTrue(String.isNotBlank(response2.responseData), 'Response2 data should not be blank');

            Map<String, Object> finalMap2 = (Map<String, Object>) JSON.deserializeUntyped(response2.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap2.containsKey('studyOfferingRecordsWithLimitSet'), 'Response2 should contain studyOfferingRecordsWithLimitSet key');            
            System.Assert.isTrue(finalMap2.containsKey('totalRecordCount'), 'Response2 should contain totalRecordCount key');            

            // Verify records
            List<Object> recordsMapObj2 = (List<Object>) finalMap2.get('studyOfferingRecordsWithLimitSet');
            System.Assert.isTrue(recordsMapObj2.isEmpty(), 'records map should be empty');

            totalRecordCount = (Integer) finalMap2.get('totalRecordCount');
            System.Assert.areEqual(0, totalRecordCount);

            Test.stopTest();
        }
    }

    /**
     * @description Test getStudyOfferingData() as faculty
     */
    @IsTest
    static void testGetStudyOfferingDataAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER) {
            Test.startTest();

            String studyOfferingFields = 'Name;reduivy__Status__c';
            String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';
            Integer studyOfferingTableMaximumRowNumber = 1;

            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            List<reduivy__Study_Offering__c> sof = [SELECT reduivy__Study_Unit__c, reduivy__Academic_Term__c, reduivy__Academic_Term__r.reduivy__Academic_Year__r.reduivy__Educational_Institution__c, reduivy__Campus__c FROM reduivy__Study_Offering__c WHERE reduivy__Status__c IN :sofStatusesSet LIMIT 3];
            
            REDU_LightningResponse response1 = REDU_TermOfferingsCloningModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, new List<Id>{sof[0].reduivy__Study_Unit__c, sof[1].reduivy__Study_Unit__c, sof[2].reduivy__Study_Unit__c}, studyOfferingTableMaximumRowNumber, studyOfferingFields, studyOfferingStatuses);
            REDU_LightningResponse response2 = REDU_TermOfferingsCloningModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c,  sof[0].reduivy__Campus__c, new List<Id>{}, studyOfferingTableMaximumRowNumber, studyOfferingFields, studyOfferingStatuses);

            // Verify response1
            System.Assert.isTrue(response1.isSuccess, 'Response1 should be successful');
            System.Assert.isTrue(String.isNotBlank(response1.responseData), 'Response1 data should not be blank');

            Map<String, Object> finalMap1 = (Map<String, Object>) JSON.deserializeUntyped(response1.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap1.containsKey('studyOfferingRecordsWithLimitSet'), 'Response1 should contain studyOfferingRecordsWithLimitSet key');
            System.Assert.isTrue(finalMap1.containsKey('totalRecordCount'), 'Response1 should contain totalRecordCount key');            
   
            // Verify records
            List<Object> recordsMapObj1 = (List<Object>) finalMap1.get('studyOfferingRecordsWithLimitSet');
            System.Assert.isFalse(recordsMapObj1.isEmpty(), 'records map should not be empty');
            System.Assert.areEqual(studyOfferingTableMaximumRowNumber, recordsMapObj1.size());
            
            Integer totalRecordCount = (Integer) finalMap1.get('totalRecordCount');
            System.Assert.areEqual(3, totalRecordCount);

            // Verify response2
            System.Assert.isTrue(response2.isSuccess, 'Response2 should be successful');
            System.Assert.isTrue(String.isNotBlank(response2.responseData), 'Response2 data should not be blank');

            Map<String, Object> finalMap2 = (Map<String, Object>) JSON.deserializeUntyped(response2.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap2.containsKey('studyOfferingRecordsWithLimitSet'), 'Response2 should contain studyOfferingRecordsWithLimitSet key');            
            System.Assert.isTrue(finalMap2.containsKey('totalRecordCount'), 'Response2 should contain totalRecordCount key');            

            // Verify records
            List<Object> recordsMapObj2 = (List<Object>) finalMap2.get('studyOfferingRecordsWithLimitSet');
            System.Assert.isTrue(recordsMapObj2.isEmpty(), 'records map should be empty');

            totalRecordCount = (Integer) finalMap2.get('totalRecordCount');
            System.Assert.areEqual(0, totalRecordCount);

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

        String studyOfferingFields = 'Name;reduivy__Status__c';
        String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';
        Integer studyOfferingTableMaximumRowNumber = 1;

        Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

        List<reduivy__Study_Offering__c> sof = [SELECT reduivy__Study_Unit__c, reduivy__Academic_Term__c, reduivy__Academic_Term__r.reduivy__Academic_Year__r.reduivy__Educational_Institution__c, reduivy__Campus__c FROM reduivy__Study_Offering__c WHERE reduivy__Status__c IN :sofStatusesSet LIMIT 3];

        System.runAs(reduStudent) {
            Test.startTest();
            
            REDU_LightningResponse response1 = REDU_TermOfferingsCloningModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, new List<Id>{sof[0].reduivy__Study_Unit__c, sof[1].reduivy__Study_Unit__c, sof[2].reduivy__Study_Unit__c}, studyOfferingTableMaximumRowNumber, studyOfferingFields, studyOfferingStatuses);
            REDU_LightningResponse response2 = REDU_TermOfferingsCloningModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c,  sof[0].reduivy__Campus__c, new List<Id>{}, studyOfferingTableMaximumRowNumber, studyOfferingFields, studyOfferingStatuses);

            // Verify response1
            System.Assert.isTrue(response1.isSuccess, 'Response1 should be successful');
            System.Assert.isTrue(String.isNotBlank(response1.responseData), 'Response1 data should not be blank');

            Map<String, Object> finalMap1 = (Map<String, Object>) JSON.deserializeUntyped(response1.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap1.containsKey('studyOfferingRecordsWithLimitSet'), 'Response1 should contain studyOfferingRecordsWithLimitSet key');
            System.Assert.isTrue(finalMap1.containsKey('totalRecordCount'), 'Response1 should contain totalRecordCount key');            
   
            // Verify records
            List<Object> recordsMapObj1 = (List<Object>) finalMap1.get('studyOfferingRecordsWithLimitSet');
            System.Assert.isFalse(recordsMapObj1.isEmpty(), 'records map should not be empty');
            System.Assert.areEqual(studyOfferingTableMaximumRowNumber, recordsMapObj1.size());
            
            Integer totalRecordCount = (Integer) finalMap1.get('totalRecordCount');
            System.Assert.areEqual(3, totalRecordCount);

            // Verify response2
            System.Assert.isTrue(response2.isSuccess, 'Response2 should be successful');
            System.Assert.isTrue(String.isNotBlank(response2.responseData), 'Response2 data should not be blank');

            Map<String, Object> finalMap2 = (Map<String, Object>) JSON.deserializeUntyped(response2.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap2.containsKey('studyOfferingRecordsWithLimitSet'), 'Response2 should contain studyOfferingRecordsWithLimitSet key');            
            System.Assert.isTrue(finalMap2.containsKey('totalRecordCount'), 'Response2 should contain totalRecordCount key');            

            // Verify records
            List<Object> recordsMapObj2 = (List<Object>) finalMap2.get('studyOfferingRecordsWithLimitSet');
            System.Assert.isTrue(recordsMapObj2.isEmpty(), 'records map should be empty');

            totalRecordCount = (Integer) finalMap2.get('totalRecordCount');
            System.Assert.areEqual(0, totalRecordCount);

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

            String studyOfferingFields = 'Name;reduivy__Status__c';
            String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';
            Integer studyOfferingTableMaximumRowNumber = 1;

            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            List<reduivy__Study_Offering__c> sof = [SELECT reduivy__Study_Unit__c, reduivy__Academic_Term__c, reduivy__Academic_Term__r.reduivy__Academic_Year__r.reduivy__Educational_Institution__c, reduivy__Campus__c FROM reduivy__Study_Offering__c WHERE reduivy__Status__c IN :sofStatusesSet LIMIT 1];

            // Test with blank selectedTermId
            try {
                REDU_TermOfferingsCloningModal_LCTRL.getStudyOfferingData(null, sof[0].reduivy__Campus__c, new List<Id>{sof[0].reduivy__Study_Unit__c}, studyOfferingTableMaximumRowNumber, studyOfferingFields, studyOfferingStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank selectedTermId');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters, 
                new List<String>{'selectedTermId'})), 
                                    'Unexpected error: ' + e.getMessage());
            }
            
            // Test with blank selectedCampusId
            try {
                REDU_TermOfferingsCloningModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c, null, new List<Id>{sof[0].reduivy__Study_Unit__c}, studyOfferingTableMaximumRowNumber, studyOfferingFields, studyOfferingStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank selectedCampusId');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters, 
                new List<String>{'selectedCampusId'})), 
                                    'Unexpected error: ' + e.getMessage());
            }

            // Test with blank studyOfferingFields
            try {
                REDU_TermOfferingsCloningModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, new List<Id>{sof[0].reduivy__Study_Unit__c}, studyOfferingTableMaximumRowNumber, null, studyOfferingStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank studyOfferingFields');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters, 
                new List<String>{'studyOfferingFields'})), 
                                    'Unexpected error: ' + e.getMessage());
            }

            // Test with blank studyOfferingStatuses
            try {
                REDU_TermOfferingsCloningModal_LCTRL.getStudyOfferingData(sof[0].reduivy__Academic_Term__c, sof[0].reduivy__Campus__c, new List<Id>{sof[0].reduivy__Study_Unit__c}, studyOfferingTableMaximumRowNumber, studyOfferingFields, null);
                System.Assert.fail('Expected an AuraHandledException for blank studyOfferingStatuses');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters, 
                new List<String>{'studyOfferingStatuses'})), 
                                    'Unexpected error: ' + e.getMessage());
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test initQueueJob() with all selection type as admin
     */
    @IsTest
    static void testInitQueueJobWithAllSelectionTypeAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();
            String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';

            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            List<reduivy__Study_Offering__c> sofs = [
                SELECT reduivy__Study_Unit__c, 
                reduivy__Academic_Term__c, 
                reduivy__Campus__c 
                FROM reduivy__Study_Offering__c 
                WHERE reduivy__Status__c IN :sofStatusesSet 
            ];
            
            Set<Id> sunIds = new Set<Id>();
            Set<Id> sofIds = new Set<Id>();

            String term = '';
            String campus = '';

            for(reduivy__Study_Offering__c sof : sofs){
                if(String.isBlank(term)) {
                    term = sof.reduivy__Academic_Term__c;
                }

                if(String.isBlank(campus)) {
                    campus = sof.reduivy__Campus__c;
                }

                if(sof.reduivy__Academic_Term__c == term) {
                    sunIds.add(sof.reduivy__Study_Unit__c);
                    sofIds.add(sof.Id);
                }
            }

            List<reduivy__Study_Term__c> stm = [
                SELECT Id, reduivy__Academic_Year__r.reduivy__Educational_Institution__c 
                FROM reduivy__Study_Term__c 
                WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID
                AND Id != :term
                LIMIT 1
            ];

            //Load component, ensuring no current jobs are found
            String jobQueueGroupFields = 'Name;CreatedDate;reduivy__Total_Records__c;reduivy__Success_Records__c;reduivy__Error_Records__c;reduivy__Status__c';
            String jobQueueGroupStatuses = 'Pending;Processing;Completed;Failed';

            REDU_LightningResponse response = REDU_TermOfferingsCloning_LCTRL.getJobQueueData(JOB_OPERATION, stm[0].Id, jobQueueGroupFields, jobQueueGroupStatuses);

            // Verify records
            Map<String, Object> finalMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

            List<Object> recordsMapObj = (List<Object>) finalMap.get('jobQueueGroupRecords');
            System.Assert.isTrue(recordsMapObj.isEmpty(), 'records map should be empty');

            //Create new job
            REDU_LightningResponse response1 = REDU_TermOfferingsCloningModal_LCTRL.initQueueJob(JOB_OPERATION, new List<Id>(sunIds), stm[0].Id, term, campus, ALL_SELECTION_TYPE, studyOfferingStatuses, 'false', 'true', 'true');
            System.Assert.isTrue(response1.isSuccess, response1.message);

            Test.stopTest();

            String jobOperationContext = JQH_Helper.getJobOperationContext(JOB_OPERATION, stm[0].Id);

            //Check Job is created
            List<reduivy__Job_Queue__c> jobQueues = [
                SELECT Id, Name 
                FROM reduivy__Job_Queue__c
                WHERE reduivy__Job_Operation_Context__c = :jobOperationContext
            ];

            //Based on the data factory, there will surely be more than one study unit offered in a term, so no matter which term it returned in the term variable, the job queue will surely create more than one.
            System.Assert.areEqual(sunIds.size(), jobQueues.size(), 'Incorrect number of jobs created');

            //Check new job shows in list
            response = REDU_TermOfferingsCloning_LCTRL.getJobQueueData(JOB_OPERATION, stm[0].Id, jobQueueGroupFields, jobQueueGroupStatuses);

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
     * @description Test initQueueJob() with manual selection type as admin
     */
    @IsTest
    static void testInitQueueJobWithManualSelectionTypeAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();
            String studyOfferingFields = 'Name;reduivy__Status__c';
            String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';

            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            List<reduivy__Study_Offering__c> sofs = [
                SELECT reduivy__Study_Unit__c, 
                reduivy__Academic_Term__c, 
                reduivy__Campus__c 
                FROM reduivy__Study_Offering__c 
                WHERE reduivy__Status__c IN :sofStatusesSet 
            ];
            
            Set<Id> sunIds = new Set<Id>();
            Set<Id> sofIds = new Set<Id>();

            String term = '';
            String campus = '';

            for(reduivy__Study_Offering__c sof : sofs){
                if(String.isBlank(term)) {
                    term = sof.reduivy__Academic_Term__c;
                }

                if(String.isBlank(campus)) {
                    campus = sof.reduivy__Campus__c;
                }

                if(sof.reduivy__Academic_Term__c == term) {
                    sunIds.add(sof.reduivy__Study_Unit__c);
                    sofIds.add(sof.Id);
                }
            }

            List<reduivy__Study_Term__c> stm = [
                SELECT Id, reduivy__Academic_Year__r.reduivy__Educational_Institution__c 
                FROM reduivy__Study_Term__c 
                WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID
                AND Id != :term
                LIMIT 1
            ];

            //Load component, ensuring no current jobs are found
            String jobQueueGroupFields = 'Name;CreatedDate;reduivy__Total_Records__c;reduivy__Success_Records__c;reduivy__Error_Records__c;reduivy__Status__c';
            String jobQueueGroupStatuses = 'Pending;Processing;Completed;Failed';

            REDU_LightningResponse response = REDU_TermOfferingsCloning_LCTRL.getJobQueueData(JOB_OPERATION, stm[0].Id, jobQueueGroupFields, jobQueueGroupStatuses);

            // Verify records
            Map<String, Object> finalMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

            List<Object> recordsMapObj = (List<Object>) finalMap.get('jobQueueGroupRecords');
            System.Assert.isTrue(recordsMapObj.isEmpty(), 'records map should be empty');

            //Create new job
            REDU_LightningResponse response1 = REDU_TermOfferingsCloningModal_LCTRL.initQueueJob(JOB_OPERATION, new List<Id>(sofIds), stm[0].Id, term, campus, MANUAL_SELECTION_TYPE, studyOfferingStatuses, 'false', 'true', 'true');
            System.Assert.isTrue(response1.isSuccess, response1.message);

            Test.stopTest();

            String jobOperationContext = JQH_Helper.getJobOperationContext(JOB_OPERATION, stm[0].Id);

            //Check Job is created
            List<reduivy__Job_Queue__c> jobQueues = [
                SELECT Id, Name 
                FROM reduivy__Job_Queue__c
                WHERE reduivy__Job_Operation_Context__c = :jobOperationContext
            ];

            //It should only have one job queue created as we are using 'Manual' selection type which will skip the generator
            System.Assert.areEqual(1, jobQueues.size(), 'Incorrect number of jobs created');

            //Check new job shows in list
            response = REDU_TermOfferingsCloning_LCTRL.getJobQueueData(JOB_OPERATION, stm[0].Id, jobQueueGroupFields, jobQueueGroupStatuses);

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

            String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';

            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            List<reduivy__Study_Offering__c> sofs = [
                SELECT reduivy__Study_Unit__c, 
                reduivy__Academic_Term__c, 
                reduivy__Campus__c 
                FROM reduivy__Study_Offering__c 
                WHERE reduivy__Status__c IN :sofStatusesSet 
            ];
            
            Set<Id> sunIds = new Set<Id>();
            Set<Id> sofIds = new Set<Id>();

            String term = '';
            String campus = '';

            for(reduivy__Study_Offering__c sof : sofs){
                if(String.isBlank(term)) {
                    term = sof.reduivy__Academic_Term__c;
                }

                if(String.isBlank(campus)) {
                    campus = sof.reduivy__Campus__c;
                }

                if(sof.reduivy__Academic_Term__c == term) {
                    sunIds.add(sof.reduivy__Study_Unit__c);
                    sofIds.add(sof.Id);
                }
            }

            List<reduivy__Study_Term__c> stm = [
                SELECT Id, reduivy__Academic_Year__r.reduivy__Educational_Institution__c 
                FROM reduivy__Study_Term__c 
                WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID
                AND Id != :term
                LIMIT 1
            ];

            //Test for blank jobOperation
            try {
                REDU_TermOfferingsCloningModal_LCTRL.initQueueJob(null, new List<Id>(sunIds), stm[0].Id, term, campus, ALL_SELECTION_TYPE, studyOfferingStatuses, 'false', 'true', 'true');
                System.Assert.fail('Expected an AuraHandledException for blank jobOperation');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'jobOperation'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank selectedTermId
            try {
                REDU_TermOfferingsCloningModal_LCTRL.initQueueJob(JOB_OPERATION, new List<Id>(sunIds), stm[0].Id, null, campus, ALL_SELECTION_TYPE, studyOfferingStatuses, 'false', 'true', 'true');
                System.Assert.fail('Expected an AuraHandledException for blank selectedTermId');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'selectedTermId'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank selectedCampusId
            try {
                REDU_TermOfferingsCloningModal_LCTRL.initQueueJob(JOB_OPERATION, new List<Id>(sunIds), stm[0].Id, term, null, ALL_SELECTION_TYPE, studyOfferingStatuses, 'false', 'true', 'true');
                System.Assert.fail('Expected an AuraHandledException for blank selectedCampusId');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'selectedCampusId'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank currentTermId
            try {
                REDU_TermOfferingsCloningModal_LCTRL.initQueueJob(JOB_OPERATION, new List<Id>(sunIds), null, term, campus, ALL_SELECTION_TYPE, studyOfferingStatuses, 'false', 'true', 'true');
                System.Assert.fail('Expected an AuraHandledException for blank currentTermId');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'currentTermId'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank sofSelectionType
            try {
                REDU_TermOfferingsCloningModal_LCTRL.initQueueJob(JOB_OPERATION, new List<Id>(sunIds), stm[0].Id, term, campus, null, studyOfferingStatuses, 'false', 'true', 'true');
                System.Assert.fail('Expected an AuraHandledException for blank sofSelectionType');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'sofSelectionType'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank studyOfferingStatuses
            try {
                REDU_TermOfferingsCloningModal_LCTRL.initQueueJob(JOB_OPERATION, new List<Id>(sunIds), stm[0].Id, term, campus, ALL_SELECTION_TYPE, null, 'false', 'true', 'true');
                System.Assert.fail('Expected an AuraHandledException for blank studyOfferingStatuses');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'studyOfferingStatuses'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            Test.stopTest();
        }
    }
}