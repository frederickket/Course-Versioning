/**
 * @author      WDCi (XW)
 * @date        Dec 2025
 * @group       Test
 * @description Test class for 2025
 * @changehistory
 * ISS-002633 10-12-2025 XW - new class
 */
@IsTest
public inherited sharing class REDU_StudentAchievement_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String CON_SRC = 'sandydoe@redu.example';

    static List<String> UNIT_TESTING_FIELD_NAMES = new List<String>{'AccountId', 'FirstName', 'LastName', 'Birthdate', 'Email'};
    static String INSUFFICIENT_READABLE_ACCESS_ERROR_MSG = 'Insufficient READABLE access';

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
        	
            testFactory.initMasterData(AGR_Helper.getApiName());
            testFactory.initStudentData(IAC_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }

    /**
     * @description Test as admin for xxx
     */
    @IsTest
    static void testForGetIac_ConId_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        Contact student = queryStudent();

        Set<Id> expectedIacIdSet = new Set<Id>();
        for(reduivy__Individual_Achievement__c iac :[SELECT Id FROM reduivy__Individual_Achievement__c WHERE reduivy__Contact__c = :student.Id]) {
            expectedIacIdSet.add(iac.Id);
        }
        System.Assert.isFalse(expectedIacIdSet.isEmpty(), 'expectedIacIdSet should not be empty');

		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getIndividualAchievements(student.Id, 'Id', null, null);
            System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.message, 'Wrong message!');
            System.Assert.areEqual(true, response.isSuccess, 'Wrong isSuccess!');
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

            System.Assert.isTrue(responseDataJson.containsKey('individualAchievementList'), 'individualAchievementList should exists in the response data');
            Set<Id> actualIacIdSet = new Set<Id>(); 
            for(Object iacObj : (List<Object>) responseDataJson.get('individualAchievementList')) {
                actualIacIdSet.add((Id) ((Map<String,Object>) iacObj).get('Id'));
            }
            
            System.Assert.areEqual(expectedIacIdSet, actualIacIdSet, 'Wrong iac list');

            System.Assert.isTrue(responseDataJson.containsKey('fieldToDisplayTypeMap'), 'fieldToDisplayTypeMap should exists in the response data');
            Map<String, Object> actualFieldToDisplayTypeMap = (Map<String, Object>) responseDataJson.get('fieldToDisplayTypeMap');
            Schema.SObjectType iacSobjectType = SObjectType.reduivy__Individual_Achievement__c.getSObjectType();
            for(String field : actualFieldToDisplayTypeMap.keySet()) {
                Schema.DescribeFieldResult dfr = REDU_Datatable_UTIL.getFieldDescribe(field, iacSobjectType);
                System.Assert.areEqual(dfr.getType().name(), (String) actualFieldToDisplayTypeMap.get(field), 'Wrong display type!');
            }

            System.Assert.isTrue(responseDataJson.containsKey('targetContactId'), 'targetContactId should exists in the response data');
            System.Assert.areEqual(student.Id, (Id) responseDataJson.get('targetContactId'), 'Wrong target contact Id'); 

            System.Assert.isTrue(responseDataJson.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM));
            

		}

        Test.stopTest();
		
    }

	
    /**
     * @description Test as admin for xxx
     */
    @IsTest
    static void testForGetIac_ConId_AdditionalFields_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        Contact student = queryStudent();

        Set<Id> expectedIacIdSet = new Set<Id>();
        for(reduivy__Individual_Achievement__c iac :[SELECT Id FROM reduivy__Individual_Achievement__c WHERE reduivy__Contact__c = :student.Id]) {
            expectedIacIdSet.add(iac.Id);
        }
        System.Assert.isFalse(expectedIacIdSet.isEmpty(), 'expectedIacIdSet should not be empty');
        

		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getIndividualAchievements(student.Id, 'Id', new List<String>{'reduivy__Type__c', 'Name', 'reduivy__Educational_Institution_Name__c', 'reduivy__Details__c', 'reduivy__Verification_Status__c'}, UserInfo.getLanguage());
            System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.message, 'Wrong message!');
            System.Assert.areEqual(true, response.isSuccess, 'Wrong isSuccess!');
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

            System.Assert.isTrue(responseDataJson.containsKey('individualAchievementList'), 'individualAchievementList should exists in the response data');
            Set<Id> actualIacIdSet = new Set<Id>(); 
            for(Object iacObj : (List<Object>) responseDataJson.get('individualAchievementList')) {
                actualIacIdSet.add((Id) ((Map<String,Object>) iacObj).get('Id'));
            }
            
            System.Assert.areEqual(expectedIacIdSet, actualIacIdSet, 'Wrong iac list');

            System.Assert.isTrue(responseDataJson.containsKey('fieldToDisplayTypeMap'), 'fieldToDisplayTypeMap should exists in the response data');
            Map<String, Object> actualFieldToDisplayTypeMap = (Map<String, Object>) responseDataJson.get('fieldToDisplayTypeMap');

            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Type__c'), 'reduivy__Type__c should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('Name'), 'Name should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Educational_Institution_Name__c'), 'reduivy__Educational_Institution_Name__c should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Details__c'), 'reduivy__Details__c should be included in the map!');
            
            Schema.SObjectType iacSobjectType = SObjectType.reduivy__Individual_Achievement__c.getSObjectType();
            for(String field : actualFieldToDisplayTypeMap.keySet()) {
                Schema.DescribeFieldResult dfr = REDU_Datatable_UTIL.getFieldDescribe(field, iacSobjectType);
                System.Assert.areEqual(dfr.getType().name(), (String) actualFieldToDisplayTypeMap.get(field), 'Wrong display type!');
            }

            System.Assert.isTrue(responseDataJson.containsKey('targetContactId'), 'targetContactId should exists in the response data');
            System.Assert.areEqual(student.Id, (Id) responseDataJson.get('targetContactId'), 'Wrong target contact Id'); 
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for xxx
     */
    @IsTest
    static void testForGetIac_IacId_AdditionalFields_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        Contact student = queryStudent();

        Set<Id> expectedIacIdSet = new Set<Id>();
        for(reduivy__Individual_Achievement__c iac :[SELECT Id FROM reduivy__Individual_Achievement__c WHERE reduivy__Contact__c = :student.Id]) {
            expectedIacIdSet.add(iac.Id);
        }
        System.Assert.isFalse(expectedIacIdSet.isEmpty(), 'expectedIacIdSet should not be empty');
        

		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getIndividualAchievements(new List<Id>(expectedIacIdSet)[0], 'reduivy__Contact__c', new List<String> {'reduivy__Type__c', 'Name', 'reduivy__Educational_Institution_Name__c', 'reduivy__Details__c'}, UserInfo.getLanguage());
            System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.message, 'Wrong message!');
            System.Assert.areEqual(true, response.isSuccess, 'Wrong isSuccess!');
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

            System.Assert.isTrue(responseDataJson.containsKey('individualAchievementList'), 'individualAchievementList should exists in the response data');
            Set<Id> actualIacIdSet = new Set<Id>(); 
            for(Object iacObj : (List<Object>) responseDataJson.get('individualAchievementList')) {
                actualIacIdSet.add((Id) ((Map<String,Object>) iacObj).get('Id'));
            }
            
            System.Assert.areEqual(expectedIacIdSet, actualIacIdSet, 'Wrong iac list');

            System.Assert.isTrue(responseDataJson.containsKey('fieldToDisplayTypeMap'), 'fieldToDisplayTypeMap should exists in the response data');
            Map<String, Object> actualFieldToDisplayTypeMap = (Map<String, Object>) responseDataJson.get('fieldToDisplayTypeMap');

            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Type__c'), 'reduivy__Type__c should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('Name'), 'Name should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Educational_Institution_Name__c'), 'reduivy__Educational_Institution_Name__c should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Details__c'), 'reduivy__Details__c should be included in the map!');
            
            Schema.SObjectType iacSobjectType = SObjectType.reduivy__Individual_Achievement__c.getSObjectType();
            for(String field : actualFieldToDisplayTypeMap.keySet()) {
                Schema.DescribeFieldResult dfr = REDU_Datatable_UTIL.getFieldDescribe(field, iacSobjectType);
                System.Assert.areEqual(dfr.getType().name(), (String) actualFieldToDisplayTypeMap.get(field), 'Wrong display type!');
            }

            System.Assert.isTrue(responseDataJson.containsKey('targetContactId'), 'targetContactId should exists in the response data');
            System.Assert.areEqual(student.Id, (Id) responseDataJson.get('targetContactId'), 'Wrong target contact Id'); 
		}

        Test.stopTest();
		
    }

    @IsTest
    static void testGetFieldSet_WithName_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getFieldSet('reduivy__UnitTesting', CON_Helper.getApiName());
            List<REDU_DynamicFieldValue_OBJ> responseDataJson = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(response.responseData, List<REDU_DynamicFieldValue_OBJ>.class);

            System.Assert.isNotNull(responseDataJson, 'responseDataJson should not be null!');
            System.Assert.areEqual(5, responseDataJson.size(), 'responseDataJson should contains 5 elements!');
            for(REDU_DynamicFieldValue_OBJ obj : responseDataJson) {
                System.Assert.isTrue(UNIT_TESTING_FIELD_NAMES.contains(obj.fieldName), obj.fieldName + ' is not included in the unit testing list!');
            }
        }
        Test.stopTest();
        
    }

    @IsTest
    static void testGetFieldSet_WithoutName_AsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getFieldSet('', CON_Helper.getApiName());
            List<REDU_DynamicFieldValue_OBJ> responseDataJson = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(response.responseData, List<REDU_DynamicFieldValue_OBJ>.class);

            System.Assert.isNotNull(responseDataJson, 'responseDataJson should not be null!');
            System.Assert.istrue(responseDataJson.isEmpty(), 'responseDataJson should be empty!');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetIdvAcWizardMetadata_AsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();

        Map<String,List<IAC_Helper.IdvAcWizardFormWrapper>> idvAcWizardFormGroupByWizardConfig = IAC_Helper.getIdvAcWizardFormGroupByWizardConfigName();

        String targetConfigName = new List<String>(idvAcWizardFormGroupByWizardConfig.keySet()).get(0);

        System.runAs(ADMIN_USER) {

            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getIdvAcWizardMetadata(targetConfigName);

            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('idvAcWizardFormGroupList'), 'should be contains idvAcWizardFormGroupList attribute!');
            System.Assert.isTrue(responseDataJson.containsKey('labels'), 'should be contains labels attribute!');
        }
        
        Test.stopTest();
    }

    @IsTest
    static void testgetIndividualAchievementVerificationStatusesInfo_AsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getIndividualAchievementVerificationStatusesInfo();
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('lockingMode'), 'should be contains lockingMode attribute!');
            System.Assert.isTrue(responseDataJson.containsKey('verificationStatusType'), 'should be contains verificationStatusType attribute!');
            System.Assert.isTrue(responseDataJson.containsKey('verificationStatusBadgeType'), 'should be contains verificationStatusBadgeType attribute!');
            
            Map<String, Object> lockingModeMap = (Map<String, Object>) responseDataJson.get('lockingMode');
            System.Assert.isTrue(lockingModeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_LOCKING_MODE_LOCKED), 'should be contains Locked attribute!');
            System.Assert.isTrue(lockingModeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_LOCKING_MODE_UNLOCKED), 'should be contains Unlocked attribute!');
            
            Map<String, Object> verificationStatusTypeMap = (Map<String, Object>) responseDataJson.get('verificationStatusType');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_OPEN), 'should be contains OPEN attribute!');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_SUBMITTED), 'should be contains SUBMITTED attribute!');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_REVIEW), 'should be contains REVIEW attribute!');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_VERIFIED), 'should be contains VERIFIED attribute!');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_REJECTED), 'should be contains REJECTED attribute!');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_CANCELLED), 'should be contains CANCELLED attribute!');
            
            Map<String, Object> verificationStatusBadgeTypeMap = (Map<String, Object>) responseDataJson.get('verificationStatusBadgeType');
            System.Assert.areNotEqual(0, verificationStatusBadgeTypeMap.size(), 'verificationStatusBadgeTypeMap should not be empty! Actual map: ' + JSON.serialize(verificationStatusBadgeTypeMap));
        }
        Test.stopTest();
    }


    /**
     * @description Test as faculty for xxx
     */
    @IsTest
    static void testForGetIac_ConId_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        Contact student = queryStudent();

        Set<Id> expectedIacIdSet = new Set<Id>();
        for(reduivy__Individual_Achievement__c iac :[SELECT Id FROM reduivy__Individual_Achievement__c WHERE reduivy__Contact__c = :student.Id]) {
            expectedIacIdSet.add(iac.Id);
        }
        System.Assert.isFalse(expectedIacIdSet.isEmpty(), 'expectedIacIdSet should not be empty');

		System.runAs(FACULTY_USER){
            
            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getIndividualAchievements(student.Id, 'Id', null, null);
            System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.message, 'Wrong message!');
            System.Assert.areEqual(true, response.isSuccess, 'Wrong isSuccess!');
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

            System.Assert.isTrue(responseDataJson.containsKey('individualAchievementList'), 'individualAchievementList should exists in the response data');
            Set<Id> actualIacIdSet = new Set<Id>(); 
            for(Object iacObj : (List<Object>) responseDataJson.get('individualAchievementList')) {
                actualIacIdSet.add((Id) ((Map<String,Object>) iacObj).get('Id'));
            }
            
            System.Assert.areEqual(expectedIacIdSet, actualIacIdSet, 'Wrong iac list');

            System.Assert.isTrue(responseDataJson.containsKey('fieldToDisplayTypeMap'), 'fieldToDisplayTypeMap should exists in the response data');
            Map<String, Object> actualFieldToDisplayTypeMap = (Map<String, Object>) responseDataJson.get('fieldToDisplayTypeMap');
            Schema.SObjectType iacSobjectType = SObjectType.reduivy__Individual_Achievement__c.getSObjectType();
            for(String field : actualFieldToDisplayTypeMap.keySet()) {
                Schema.DescribeFieldResult dfr = REDU_Datatable_UTIL.getFieldDescribe(field, iacSobjectType);
                System.Assert.areEqual(dfr.getType().name(), (String) actualFieldToDisplayTypeMap.get(field), 'Wrong display type!');
            }

            System.Assert.isTrue(responseDataJson.containsKey('targetContactId'), 'targetContactId should exists in the response data');
            System.Assert.areEqual(student.Id, (Id) responseDataJson.get('targetContactId'), 'Wrong target contact Id'); 

            System.Assert.isTrue(responseDataJson.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM));
            
		}

        Test.stopTest();
		
    }

	
    /**
     * @description Test as faculty for xxx
     */
    @IsTest
    static void testForGetIac_ConId_AdditionalFields_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        Contact student = queryStudent();

        Set<Id> expectedIacIdSet = new Set<Id>();
        for(reduivy__Individual_Achievement__c iac :[SELECT Id FROM reduivy__Individual_Achievement__c WHERE reduivy__Contact__c = :student.Id]) {
            expectedIacIdSet.add(iac.Id);
        }
        System.Assert.isFalse(expectedIacIdSet.isEmpty(), 'expectedIacIdSet should not be empty');
        

		System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getIndividualAchievements(student.Id, 'Id', new List<String> {'reduivy__Type__c', 'Name', 'reduivy__Educational_Institution_Name__c', 'reduivy__Details__c', 'reduivy__Verification_Status__c'}, UserInfo.getLanguage());
            System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.message, 'Wrong message!');
            System.Assert.areEqual(true, response.isSuccess, 'Wrong isSuccess!');
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

            System.Assert.isTrue(responseDataJson.containsKey('individualAchievementList'), 'individualAchievementList should exists in the response data');
            Set<Id> actualIacIdSet = new Set<Id>(); 
            for(Object iacObj : (List<Object>) responseDataJson.get('individualAchievementList')) {
                actualIacIdSet.add((Id) ((Map<String,Object>) iacObj).get('Id'));
            }
            
            System.Assert.areEqual(expectedIacIdSet, actualIacIdSet, 'Wrong iac list');

            System.Assert.isTrue(responseDataJson.containsKey('fieldToDisplayTypeMap'), 'fieldToDisplayTypeMap should exists in the response data');
            Map<String, Object> actualFieldToDisplayTypeMap = (Map<String, Object>) responseDataJson.get('fieldToDisplayTypeMap');

            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Type__c'), 'reduivy__Type__c should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('Name'), 'Name should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Educational_Institution_Name__c'), 'reduivy__Educational_Institution_Name__c should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Details__c'), 'reduivy__Details__c should be included in the map!');
            
            Schema.SObjectType iacSobjectType = SObjectType.reduivy__Individual_Achievement__c.getSObjectType();
            for(String field : actualFieldToDisplayTypeMap.keySet()) {
                Schema.DescribeFieldResult dfr = REDU_Datatable_UTIL.getFieldDescribe(field, iacSobjectType);
                System.Assert.areEqual(dfr.getType().name(), (String) actualFieldToDisplayTypeMap.get(field), 'Wrong display type!');
            }

            System.Assert.isTrue(responseDataJson.containsKey('targetContactId'), 'targetContactId should exists in the response data');
            System.Assert.areEqual(student.Id, (Id) responseDataJson.get('targetContactId'), 'Wrong target contact Id'); 
           
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for xxx
     */
    @IsTest
    static void testForGetIac_IacId_AdditionalFields_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        Contact student = queryStudent();

        Set<Id> expectedIacIdSet = new Set<Id>();
        for(reduivy__Individual_Achievement__c iac :[SELECT Id FROM reduivy__Individual_Achievement__c WHERE reduivy__Contact__c = :student.Id]) {
            expectedIacIdSet.add(iac.Id);
        }
        System.Assert.isFalse(expectedIacIdSet.isEmpty(), 'expectedIacIdSet should not be empty');
        

		System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getIndividualAchievements(new List<Id>(expectedIacIdSet)[0], 'reduivy__Contact__c', new List<String> {'reduivy__Type__c', 'Name', 'reduivy__Educational_Institution_Name__c', 'reduivy__Details__c'}, UserInfo.getLanguage());
            System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.message, 'Wrong message!');
            System.Assert.areEqual(true, response.isSuccess, 'Wrong isSuccess!');
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

            System.Assert.isTrue(responseDataJson.containsKey('individualAchievementList'), 'individualAchievementList should exists in the response data');
            Set<Id> actualIacIdSet = new Set<Id>(); 
            for(Object iacObj : (List<Object>) responseDataJson.get('individualAchievementList')) {
                actualIacIdSet.add((Id) ((Map<String,Object>) iacObj).get('Id'));
            }
            
            System.Assert.areEqual(expectedIacIdSet, actualIacIdSet, 'Wrong iac list');

            System.Assert.isTrue(responseDataJson.containsKey('fieldToDisplayTypeMap'), 'fieldToDisplayTypeMap should exists in the response data');
            Map<String, Object> actualFieldToDisplayTypeMap = (Map<String, Object>) responseDataJson.get('fieldToDisplayTypeMap');

            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Type__c'), 'reduivy__Type__c should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('Name'), 'Name should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Educational_Institution_Name__c'), 'reduivy__Educational_Institution_Name__c should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Details__c'), 'reduivy__Details__c should be included in the map!');
            
            Schema.SObjectType iacSobjectType = SObjectType.reduivy__Individual_Achievement__c.getSObjectType();
            for(String field : actualFieldToDisplayTypeMap.keySet()) {
                Schema.DescribeFieldResult dfr = REDU_Datatable_UTIL.getFieldDescribe(field, iacSobjectType);
                System.Assert.areEqual(dfr.getType().name(), (String) actualFieldToDisplayTypeMap.get(field), 'Wrong display type!');
            }

            System.Assert.isTrue(responseDataJson.containsKey('targetContactId'), 'targetContactId should exists in the response data');
            System.Assert.areEqual(student.Id, (Id) responseDataJson.get('targetContactId'), 'Wrong target contact Id'); 

		}

        Test.stopTest();
		
    }

    @IsTest
    static void testGetFieldSet_WithName_AsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

		System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getFieldSet('reduivy__UnitTesting', CON_Helper.getApiName());
            List<REDU_DynamicFieldValue_OBJ> responseDataJson = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(response.responseData, List<REDU_DynamicFieldValue_OBJ>.class);

            System.Assert.isNotNull(responseDataJson, 'responseDataJson should not be null!');
            System.Assert.areEqual(5, responseDataJson.size(), 'responseDataJson should contains 5 elements!');
            for(REDU_DynamicFieldValue_OBJ obj : responseDataJson) {
                System.Assert.isTrue(UNIT_TESTING_FIELD_NAMES.contains(obj.fieldName), obj.fieldName + ' is not included in the unit testing list!');
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetFieldSet_WithoutName_AsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

		System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getFieldSet('', CON_Helper.getApiName());
            List<REDU_DynamicFieldValue_OBJ> responseDataJson = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(response.responseData, List<REDU_DynamicFieldValue_OBJ>.class);

            System.Assert.isNotNull(responseDataJson, 'responseDataJson should not be null!');
            System.Assert.istrue(responseDataJson.isEmpty(), 'responseDataJson should be empty!');
        }

        Test.stopTest();
    }

    @IsTest
    static void testGetIdvAcWizardMetadata_AsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();

        Map<String,List<IAC_Helper.IdvAcWizardFormWrapper>> idvAcWizardFormGroupByWizardConfig = IAC_Helper.getIdvAcWizardFormGroupByWizardConfigName();

        String targetConfigName = new List<String>(idvAcWizardFormGroupByWizardConfig.keySet()).get(0);

        System.runAs(FACULTY_USER) {

            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getIdvAcWizardMetadata(targetConfigName);

            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('idvAcWizardFormGroupList'), 'should be contains idvAcWizardFormGroupList attribute!');
            System.Assert.isTrue(responseDataJson.containsKey('labels'), 'should be contains labels attribute!');
        }
        
        Test.stopTest();
    }

    @IsTest
    static void testgetIndividualAchievementVerificationStatusesInfo_AsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

		System.runAs(FACULTY_USER){

            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getIndividualAchievementVerificationStatusesInfo();
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('lockingMode'), 'should be contains lockingMode attribute!');
            System.Assert.isTrue(responseDataJson.containsKey('verificationStatusType'), 'should be contains verificationStatusType attribute!');
            System.Assert.isTrue(responseDataJson.containsKey('verificationStatusBadgeType'), 'should be contains verificationStatusBadgeType attribute!');
            
            Map<String, Object> lockingModeMap = (Map<String, Object>) responseDataJson.get('lockingMode');
            System.Assert.isTrue(lockingModeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_LOCKING_MODE_LOCKED), 'should be contains Locked attribute!');
            System.Assert.isTrue(lockingModeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_LOCKING_MODE_UNLOCKED), 'should be contains Unlocked attribute!');
            
            Map<String, Object> verificationStatusTypeMap = (Map<String, Object>) responseDataJson.get('verificationStatusType');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_OPEN), 'should be contains OPEN attribute!');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_SUBMITTED), 'should be contains SUBMITTED attribute!');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_REVIEW), 'should be contains REVIEW attribute!');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_VERIFIED), 'should be contains VERIFIED attribute!');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_REJECTED), 'should be contains REJECTED attribute!');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_CANCELLED), 'should be contains CANCELLED attribute!');
            
            Map<String, Object> verificationStatusBadgeTypeMap = (Map<String, Object>) responseDataJson.get('verificationStatusBadgeType');
            System.Assert.areNotEqual(0, verificationStatusBadgeTypeMap.size(), 'verificationStatusBadgeTypeMap should not be empty! Actual map: ' + JSON.serialize(verificationStatusBadgeTypeMap));
        }
        Test.stopTest();
    }
    

    /**
     * @description Test as student for xxx
     */
    @IsTest
    static void testForGetIac_ConId_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        Contact student = queryStudent();

        Set<Id> expectedIacIdSet = new Set<Id>();
        for(reduivy__Individual_Achievement__c iac :[SELECT Id FROM reduivy__Individual_Achievement__c WHERE reduivy__Contact__c = :student.Id]) {
            expectedIacIdSet.add(iac.Id);
        }
        System.Assert.isFalse(expectedIacIdSet.isEmpty(), 'expectedIacIdSet should not be empty');

		System.runAs(studentUser){
            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getIndividualAchievements(student.Id, 'Id', null, null);
            System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.message, 'Wrong message!');
            System.Assert.areEqual(true, response.isSuccess, 'Wrong isSuccess!');
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

            System.Assert.isTrue(responseDataJson.containsKey('individualAchievementList'), 'individualAchievementList should exists in the response data');
            Set<Id> actualIacIdSet = new Set<Id>(); 
            for(Object iacObj : (List<Object>) responseDataJson.get('individualAchievementList')) {
                actualIacIdSet.add((Id) ((Map<String,Object>) iacObj).get('Id'));
            }
            
            System.Assert.areEqual(expectedIacIdSet, actualIacIdSet, 'Wrong iac list');

            System.Assert.isTrue(responseDataJson.containsKey('fieldToDisplayTypeMap'), 'fieldToDisplayTypeMap should exists in the response data');
            Map<String, Object> actualFieldToDisplayTypeMap = (Map<String, Object>) responseDataJson.get('fieldToDisplayTypeMap');
            Schema.SObjectType iacSobjectType = SObjectType.reduivy__Individual_Achievement__c.getSObjectType();
            for(String field : actualFieldToDisplayTypeMap.keySet()) {
                Schema.DescribeFieldResult dfr = REDU_Datatable_UTIL.getFieldDescribe(field, iacSobjectType);
                System.Assert.areEqual(dfr.getType().name(), (String) actualFieldToDisplayTypeMap.get(field), 'Wrong display type!');
            }

            System.Assert.isTrue(responseDataJson.containsKey('targetContactId'), 'targetContactId should exists in the response data');
            System.Assert.areEqual(student.Id, (Id) responseDataJson.get('targetContactId'), 'Wrong target contact Id'); 

            System.Assert.isTrue(responseDataJson.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM));
            

		}

        Test.stopTest();
		
    }

	
    /**
     * @description Test as student for xxx
     */
    @IsTest
    static void testForGetIac_ConId_AdditionalFields_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        Contact student = queryStudent();

        Set<Id> expectedIacIdSet = new Set<Id>();
        for(reduivy__Individual_Achievement__c iac :[SELECT Id FROM reduivy__Individual_Achievement__c WHERE reduivy__Contact__c = :student.Id]) {
            expectedIacIdSet.add(iac.Id);
        }
        System.Assert.isFalse(expectedIacIdSet.isEmpty(), 'expectedIacIdSet should not be empty');
        

		System.runAs(studentUser){
            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getIndividualAchievements(student.Id, 'Id', new List<String>{'reduivy__Type__c', 'Name', 'reduivy__Educational_Institution_Name__c', 'reduivy__Details__c', 'reduivy__Verification_Status__c'}, UserInfo.getLanguage());
            System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.message, 'Wrong message!');
            System.Assert.areEqual(true, response.isSuccess, 'Wrong isSuccess!');
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

            System.Assert.isTrue(responseDataJson.containsKey('individualAchievementList'), 'individualAchievementList should exists in the response data');
            Set<Id> actualIacIdSet = new Set<Id>(); 
            for(Object iacObj : (List<Object>) responseDataJson.get('individualAchievementList')) {
                actualIacIdSet.add((Id) ((Map<String,Object>) iacObj).get('Id'));
            }
            
            System.Assert.areEqual(expectedIacIdSet, actualIacIdSet, 'Wrong iac list');

            System.Assert.isTrue(responseDataJson.containsKey('fieldToDisplayTypeMap'), 'fieldToDisplayTypeMap should exists in the response data');
            Map<String, Object> actualFieldToDisplayTypeMap = (Map<String, Object>) responseDataJson.get('fieldToDisplayTypeMap');

            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Type__c'), 'reduivy__Type__c should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('Name'), 'Name should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Educational_Institution_Name__c'), 'reduivy__Educational_Institution_Name__c should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Details__c'), 'reduivy__Details__c should be included in the map!');
            
            Schema.SObjectType iacSobjectType = SObjectType.reduivy__Individual_Achievement__c.getSObjectType();
            for(String field : actualFieldToDisplayTypeMap.keySet()) {
                Schema.DescribeFieldResult dfr = REDU_Datatable_UTIL.getFieldDescribe(field, iacSobjectType);
                System.Assert.areEqual(dfr.getType().name(), (String) actualFieldToDisplayTypeMap.get(field), 'Wrong display type!');
            }

            System.Assert.isTrue(responseDataJson.containsKey('targetContactId'), 'targetContactId should exists in the response data');
            System.Assert.areEqual(student.Id, (Id) responseDataJson.get('targetContactId'), 'Wrong target contact Id'); 
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for xxx
     */
    @IsTest
    static void testForGetIac_IacId_AdditionalFields_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        Contact student = queryStudent();

        Set<Id> expectedIacIdSet = new Set<Id>();
        for(reduivy__Individual_Achievement__c iac :[SELECT Id FROM reduivy__Individual_Achievement__c WHERE reduivy__Contact__c = :student.Id]) {
            expectedIacIdSet.add(iac.Id);
        }
        System.Assert.isFalse(expectedIacIdSet.isEmpty(), 'expectedIacIdSet should not be empty');
        

		System.runAs(studentUser){
            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getIndividualAchievements(new List<Id>(expectedIacIdSet)[0], 'reduivy__Contact__c', new List<String>{'reduivy__Type__c', 'Name', 'reduivy__Educational_Institution_Name__c', 'reduivy__Details__c'}, UserInfo.getLanguage());
            System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.message, 'Wrong message!');
            System.Assert.areEqual(true, response.isSuccess, 'Wrong isSuccess!');
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

            System.Assert.isTrue(responseDataJson.containsKey('individualAchievementList'), 'individualAchievementList should exists in the response data');
            Set<Id> actualIacIdSet = new Set<Id>(); 
            for(Object iacObj : (List<Object>) responseDataJson.get('individualAchievementList')) {
                actualIacIdSet.add((Id) ((Map<String,Object>) iacObj).get('Id'));
            }
            
            System.Assert.areEqual(expectedIacIdSet, actualIacIdSet, 'Wrong iac list');

            System.Assert.isTrue(responseDataJson.containsKey('fieldToDisplayTypeMap'), 'fieldToDisplayTypeMap should exists in the response data');
            Map<String, Object> actualFieldToDisplayTypeMap = (Map<String, Object>) responseDataJson.get('fieldToDisplayTypeMap');

            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Type__c'), 'reduivy__Type__c should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('Name'), 'Name should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Educational_Institution_Name__c'), 'reduivy__Educational_Institution_Name__c should be included in the map!');
            System.Assert.isTrue(actualFieldToDisplayTypeMap.keySet().contains('reduivy__Details__c'), 'reduivy__Details__c should be included in the map!');
            
            Schema.SObjectType iacSobjectType = SObjectType.reduivy__Individual_Achievement__c.getSObjectType();
            for(String field : actualFieldToDisplayTypeMap.keySet()) {
                Schema.DescribeFieldResult dfr = REDU_Datatable_UTIL.getFieldDescribe(field, iacSobjectType);
                System.Assert.areEqual(dfr.getType().name(), (String) actualFieldToDisplayTypeMap.get(field), 'Wrong display type!');
            }

            System.Assert.isTrue(responseDataJson.containsKey('targetContactId'), 'targetContactId should exists in the response data');
            System.Assert.areEqual(student.Id, (Id) responseDataJson.get('targetContactId'), 'Wrong target contact Id'); 
		}

        Test.stopTest();
		
    }

    @IsTest
    static void testGetFieldSet_WithName_AsStudent() {
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        System.runAs(studentUser) {
            
            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getFieldSet('reduivy__UnitTesting', CON_Helper.getApiName());
            List<REDU_DynamicFieldValue_OBJ> responseDataJson = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(response.responseData, List<REDU_DynamicFieldValue_OBJ>.class);

            System.Assert.isNotNull(responseDataJson, 'responseDataJson should not be null!');
            System.Assert.areEqual(5, responseDataJson.size(), 'responseDataJson should contains 5 elements!');
            for(REDU_DynamicFieldValue_OBJ obj : responseDataJson) {
                System.Assert.isTrue(UNIT_TESTING_FIELD_NAMES.contains(obj.fieldName), obj.fieldName + ' is not included in the unit testing list!');
            }
        }

        Test.stopTest();
        
    }

    @IsTest
    static void testGetFieldSet_WithoutName_AsStudent() {
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        System.runAs(studentUser) {
            
            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getFieldSet('', CON_Helper.getApiName());
            List<REDU_DynamicFieldValue_OBJ> responseDataJson = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(response.responseData, List<REDU_DynamicFieldValue_OBJ>.class);

            System.Assert.isNotNull(responseDataJson, 'responseDataJson should not be null!');
            System.Assert.istrue(responseDataJson.isEmpty(), 'responseDataJson should be empty!');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetIdvAcWizardMetadata_AsStudent() {
        
        User studentUser = testFactory.getStudentUser();
        Test.startTest();

        Map<String,List<IAC_Helper.IdvAcWizardFormWrapper>> idvAcWizardFormGroupByWizardConfig = IAC_Helper.getIdvAcWizardFormGroupByWizardConfigName();

        String targetConfigName = new List<String>(idvAcWizardFormGroupByWizardConfig.keySet()).get(0);

        System.runAs(studentUser) {

            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getIdvAcWizardMetadata(targetConfigName);

            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('idvAcWizardFormGroupList'), 'should be contains idvAcWizardFormGroupList attribute!');
            System.Assert.isTrue(responseDataJson.containsKey('labels'), 'should be contains labels attribute!');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testgetIndividualAchievementVerificationStatusesInfo_AsStudent() {
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        System.runAs(studentUser) {
            
            REDU_LightningResponse response = REDU_StudentAchievement_LCTRL.getIndividualAchievementVerificationStatusesInfo();
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('lockingMode'), 'should be contains lockingMode attribute!');
            System.Assert.isTrue(responseDataJson.containsKey('verificationStatusType'), 'should be contains verificationStatusType attribute!');
            System.Assert.isTrue(responseDataJson.containsKey('verificationStatusBadgeType'), 'should be contains verificationStatusBadgeType attribute!');
            
            Map<String, Object> lockingModeMap = (Map<String, Object>) responseDataJson.get('lockingMode');
            System.Assert.isTrue(lockingModeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_LOCKING_MODE_LOCKED), 'should be contains Locked attribute!');
            System.Assert.isTrue(lockingModeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_LOCKING_MODE_UNLOCKED), 'should be contains Unlocked attribute!');
            
            Map<String, Object> verificationStatusTypeMap = (Map<String, Object>) responseDataJson.get('verificationStatusType');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_OPEN), 'should be contains OPEN attribute!');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_SUBMITTED), 'should be contains SUBMITTED attribute!');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_REVIEW), 'should be contains REVIEW attribute!');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_VERIFIED), 'should be contains VERIFIED attribute!');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_REJECTED), 'should be contains REJECTED attribute!');
            System.Assert.isTrue(verificationStatusTypeMap.containsKey(IAC_Helper.VERIFICATION_STATUS_TYPE_CANCELLED), 'should be contains CANCELLED attribute!');
            
            Map<String, Object> verificationStatusBadgeTypeMap = (Map<String, Object>) responseDataJson.get('verificationStatusBadgeType');
            System.Assert.areNotEqual(0, verificationStatusBadgeTypeMap.size(), 'verificationStatusBadgeTypeMap should not be empty! Actual map: ' + JSON.serialize(verificationStatusBadgeTypeMap));
        }
        Test.stopTest();
    }

    static Contact queryStudent(){
        return [
            SELECT Id, Name 
            FROM Contact
            WHERE reduivy__Sample_Record_Code__c = :CON_SRC
            LIMIT 1
        ];
    }
	
	
}