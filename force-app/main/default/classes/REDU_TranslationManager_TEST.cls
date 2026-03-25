/**
 * @author      WDCi (XW)
 * @date        Oct 2025
 * @group       Test
 * @description Test class for REDU_TranslationManager
 * @changehistory
 * ISS-002495 10-08-2025 XW - new class
 */
@IsTest
public inherited sharing class REDU_TranslationManager_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static String SRC_SUN = 'BUS101';
    static String SRC_SOF = 'BUS101_CYT1_SYDNEY';
    static String SRC_ACC = 'RIOUNI';
    static String SUN_DESC_EN = 'Description of the Study Unit BUS101 in English';
    static String SUN_DESC_ES = 'Description of the Study Unit BUS101 in Spanish';
    static String SUN_DESC_DEF = 'Description of the Study Unit BUS101 (Default)';

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
            setCreateTLMCustomSetting(true);

            testFactory.initMasterData(SUN_Helper.getApiName());
            testFactory.initOfferingData(SOF_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);
            testFactory.initFacultyData(USR_Helper.getApiName(), true);

            Test.stopTest();
		}

    }
	
    /**
     * @description test record value translation setting not enabled, as admin
     */
    @IsTest
    static void testTranslationInfo_TranslationNotEnabled_AsAdmin() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();
        setCreateTLMCustomSetting(false);

        reduivy__Study_Unit__c expectedSun = updateSun(querySun());
        
        System.runAs(ADMIN_USER) {
            Map<String, Object> actualTranslationInfo = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>{expectedSun.Id}, new List<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            System.Assert.isTrue(actualTranslationInfo.isEmpty(), 'Translation Info should be empty! Actual: ' + JSON.serialize(actualTranslationInfo));
        }

        Test.stopTest();
    
    }

    /**
     * @description test normal usage of the translation info in english as admin
     */
    @IsTest
    static void testTranslationInfo_English_AsAdmin() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();
        setCreateTLMCustomSetting(true);

        reduivy__Study_Unit__c expectedSun = updateSun(querySun());
        
        System.runAs(ADMIN_USER) {
            Map<String, Object> actualTranslationInfo = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>{expectedSun.Id}, new List<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.RECORDS_PARAM), 'Attribute named "records" should be existing!');

            //records
            List<SObject> actualRecords = (List<SObject>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            System.Assert.areEqual(expectedSun.Id, actualRecords[0].Id, 'Wrong sun record Id!');
            
            //translations
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.TRANSLATIONS_PARAM), 'Attribute named "translations" should be existing!');
            
            List<Object> actualtranslations = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM);
            System.Assert.areEqual(1, actualtranslations.size(), 'Wrong translations size!');
            
            Map<String, Object> actualtranslation = (Map<String, Object>) actualtranslations[0];
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM), 'Attribute named "data" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM), 'Attribute named "configs" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Attribute named "languageCode" from translations should be existing!');

            //translations.languageCode
            System.Assert.areEqual('en_US', actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');

            //translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig> ) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM);
            System.Assert.areEqual(1, actualConfigs.size(), 'Wrong configs size!');
            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(2, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');
            
            //translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_Desc = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_Desc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Description__c', actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            //translations.data
            Map<String, Map<String, Object>> actualData = (Map<String, Map<String, Object>>) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM);
            System.Assert.areEqual(1, actualData.size(), 'Wrong translation data size!');
            System.Assert.isTrue(actualData.containsKey(expectedSun.Id), 'Translated record should be existing!');

            Map<String, Object> actualDataRecord = actualData.get(expectedSun.Id);
            System.Assert.areEqual(SUN_DESC_EN, actualDataRecord.get('reduivy__Description__c'), 'Wrong translation data record!');

            //test different override methods, should return the exact same result
            Map<String, Object> actualSetId_listFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new Set<Id> {expectedSun.Id}, new List<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualSetId_setFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new Set<Id> {expectedSun.Id}, new Set<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualListSObject_ListFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<SObject> {expectedSun}, new List<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualListSObject_setFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<SObject> {expectedSun}, new Set<String> {'Name', 'reduivy__Description__c'}, 'en_US');


            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_listFields), 'Different result for actualSetId_listFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_setFields), 'Different result for actualSetId_setFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_ListFields), 'Different result for actualListSObject_ListFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_setFields), 'Different result for actualListSObject_setFields!');
        }

        Test.stopTest();
    
    }

    /**
     * @description test normal usage of the translation info in spanish as admin
     */
    @IsTest
    static void testTranslationInfo_Spanish_AsAdmin() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();
        setCreateTLMCustomSetting(true);

        reduivy__Study_Unit__c expectedSun = updateSun(querySun());
        
        System.runAs(ADMIN_USER) {
            Map<String, Object> actualTranslationInfo = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>{expectedSun.Id}, new List<String> {'Name', 'reduivy__Description__c'}, 'es');
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.RECORDS_PARAM), 'Attribute named "records" should be existing!');

            //records
            List<SObject> actualRecords = (List<SObject>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            System.Assert.areEqual(expectedSun.Id, actualRecords[0].Id, 'Wrong sun record Id!');
            
            //translations
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.TRANSLATIONS_PARAM), 'Attribute named "translations" should be existing!');
            
            List<Object> actualtranslations = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM);
            System.Assert.areEqual(1, actualtranslations.size(), 'Wrong translations size!');
            
            Map<String, Object> actualtranslation = (Map<String, Object>) actualtranslations[0];
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM), 'Attribute named "data" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM), 'Attribute named "configs" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Attribute named "languageCode" from translations should be existing!');

            //translations.languageCode
            System.Assert.areEqual('es', actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');

            //translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig> ) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM);
            System.Assert.areEqual(1, actualConfigs.size(), 'Wrong configs size!');
            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(2, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');
                    
            //translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_Desc = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_Desc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Description__c', actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            //translations.data
            Map<String, Map<String, Object>> actualData = (Map<String, Map<String, Object>>) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM);
            System.Assert.areEqual(1, actualData.size(), 'Wrong translation data size!');
            System.Assert.isTrue(actualData.containsKey(expectedSun.Id), 'Translated record should be existing!');

            Map<String, Object> actualDataRecord = actualData.get(expectedSun.Id);
            System.Assert.areEqual(SUN_DESC_ES, actualDataRecord.get('reduivy__Description__c'), 'Wrong translation data record!');

            //test different override methods, should return the exact same result
            Map<String, Object> actualSetId_listFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new Set<Id> {expectedSun.Id}, new List<String> {'Name', 'reduivy__Description__c'}, 'es');
            Map<String, Object> actualSetId_setFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new Set<Id> {expectedSun.Id}, new Set<String> {'Name', 'reduivy__Description__c'}, 'es');
            Map<String, Object> actualListSObject_ListFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<SObject> {expectedSun}, new List<String> {'Name', 'reduivy__Description__c'}, 'es');
            Map<String, Object> actualListSObject_setFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<SObject> {expectedSun}, new Set<String> {'Name', 'reduivy__Description__c'}, 'es');


            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_listFields), 'Different result for actualSetId_listFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_setFields), 'Different result for actualSetId_setFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_ListFields), 'Different result for actualListSObject_ListFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_setFields), 'Different result for actualListSObject_setFields!');
        }

        Test.stopTest();
    
    }

    /**
     * @description negative test of translation info as admin
     */
    @IsTest
    static void testTranslationInfo_Invalid_AsAdmin() {
        
        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();
        setCreateTLMCustomSetting(true);

        reduivy__Study_Unit__c expectedSun = updateSun(querySun());
        
        System.runAs(ADMIN_USER) {
            Map<String, Object> emptyListEmptyList = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>(), new List<String>(), 'en_US');
            System.Assert.isTrue(emptyListEmptyList.isEmpty(), 'Response data Should be empty');

            Map<String, Object> emptyListNull = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>(), null, 'en_US');
            System.Assert.isTrue(emptyListNull.isEmpty(), 'Response data Should be empty');

            Map<String, Object> nullSobj = REDU_TranslationManager.getTranslationInfo(null, new List<SObject> {expectedSun}, new Set<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            System.Assert.isTrue(nullSobj.isEmpty(), 'Response data Should be empty');

            Map<String, Object> nullLanguage = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>(), null, 'en_US');
            System.Assert.isTrue(nullLanguage.isEmpty(), 'Response data Should be empty');

        }
        Test.stopTest();

        
    }

    
    
    /**
     * @description test translation info with reference in english as admin
     */
    @IsTest
    static void testTranslationInfo_Reference_AsAdmin() {
        
        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();
        setCreateTLMCustomSetting(true);

        reduivy__Study_Offering__c expectedSof = querySof();
    
        reduivy__Study_Unit__c expectedSun = expectedSof.reduivy__Study_Unit__r;

        
        System.runAs(ADMIN_USER) {
            
            Map<String, Object> actualTranslationInfo = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<String>{expectedSof.Id}, new List<String> {'Name', 'reduivy__Study_Unit__c', 'reduivy__Study_Unit__r.Name', 'reduivy__Study_Unit__r.reduivy__Description__c'}, 'en_US');
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.RECORDS_PARAM), 'Attribute named "records" should be existing!');

            //records
            List<SObject> actualRecords = (List<SObject>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            System.Assert.areEqual(expectedSof.Id, actualRecords[0].Id, 'Wrong sof record Id!');
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecords[0].get('reduivy__Study_Unit__c'), 'Wrong sun record Id!');
            
            //translations
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.TRANSLATIONS_PARAM), 'Attribute named "translations" should be existing!');
            
            List<Object> actualtranslations = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM);
            System.Assert.areEqual(1, actualtranslations.size(), 'Wrong translations size!');
            
            Map<String, Object> actualtranslation = (Map<String, Object>) actualtranslations[0];
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM), 'Attribute named "data" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM), 'Attribute named "configs" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Attribute named "languageCode" from translations should be existing!');

            //translations.languageCode
            System.Assert.areEqual('en_US', actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');

            //translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig> ) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM);
            System.Assert.areEqual(2, actualConfigs.size(), 'Wrong configs size!');
            System.Assert.areEqual(SOF_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(2, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');
            
            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[1].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.areEqual('reduivy__Study_Unit__r', actualConfigs[1].path, 'Path should be Study Unit!');
            System.Assert.areEqual(2, actualConfigs[1].fields.size(), 'Wrong fields size in configs!');
            
            //translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Offering__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_StudyUnit = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_StudyUnit.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Offering__c.fields.reduivy__Study_Unit__c.getLabel(), actualField_StudyUnit.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Study_Unit__c', actualField_StudyUnit.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_SunName = actualConfigs[1].fields[0];
            System.Assert.areEqual(2, actualField_SunName.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_SunName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_SunName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_SunDesc = actualConfigs[1].fields[1];
            System.Assert.areEqual(2, actualField_SunDesc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), actualField_SunDesc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Description__c', actualField_SunDesc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            //translations.data
            Map<String, Map<String, Object>> actualData = (Map<String, Map<String, Object>>) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM);
            System.Assert.areEqual(1, actualData.size(), 'Wrong translation data size!');

            Map<String, Object> actualDataRecord = actualData.get(expectedSun.Id);
            System.Assert.areEqual(SUN_DESC_EN, actualDataRecord.get('reduivy__Description__c'), 'Wrong translation data record!');
            
            //test different override methods, should return the exact same result
            Map<String, Object> actualSetId_listFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new Set<Id> {expectedSof.Id}, new List<String> {'Name', 'reduivy__Study_Unit__c', 'reduivy__Study_Unit__r.Name', 'reduivy__Study_Unit__r.reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualSetId_setFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new Set<Id> {expectedSof.Id}, new Set<String> {'Name', 'reduivy__Study_Unit__c', 'reduivy__Study_Unit__r.Name', 'reduivy__Study_Unit__r.reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualListSObject_ListFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<SObject> {expectedSof}, new List<String> {'Name', 'reduivy__Study_Unit__c', 'reduivy__Study_Unit__r.Name', 'reduivy__Study_Unit__r.reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualListSObject_setFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<SObject> {expectedSof}, new Set<String> {'Name', 'reduivy__Study_Unit__c', 'reduivy__Study_Unit__r.Name', 'reduivy__Study_Unit__r.reduivy__Description__c'}, 'en_US');

            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_listFields), 'Different result for actualSetId_listFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_setFields), 'Different result for actualSetId_setFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_ListFields), 'Different result for actualListSObject_ListFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_setFields), 'Different result for actualListSObject_setFields!');
        }
        
        Test.stopTest();
    }

    /**
     * @description test translation info with no translation mapping mdt in english as admin
     */
    @IsTest
    static void testTranslationInfo_NoTranslationMappingMdt_AsAdmin() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();
        setCreateTLMCustomSetting(true);

        reduivy__Study_Offering__c expectedSof = querySof();
        System.runAs(ADMIN_USER) {

            Map<String, Object> actualTranslationInfo = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<String>{expectedSof.Id}, new List<String> {'Name'}, 'en_US');
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.RECORDS_PARAM), 'Attribute named "records" should be existing!');

            //records
            List<SObject> actualRecords = (List<SObject>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            System.Assert.areEqual(expectedSof.Id, actualRecords[0].Id, 'Wrong sof record Id!');
            
            //translations
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.TRANSLATIONS_PARAM), 'Attribute named "translations" should be existing!');
            
            List<Object> actualtranslations = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM);
            System.Assert.areEqual(1, actualtranslations.size(), 'Wrong translations size!');
            
            Map<String, Object> actualtranslation = (Map<String, Object>) actualtranslations[0];
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM), 'Attribute named "data" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM), 'Attribute named "configs" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Attribute named "languageCode" from translations should be existing!');

            //translations.languageCode
            System.Assert.areEqual('en_US', actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');

            //translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig> ) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM);
            System.Assert.areEqual(1, actualConfigs.size(), 'Wrong configs size!');
            System.Assert.areEqual(SOF_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(1, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');
            
            //translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Offering__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            //translations.data
            Map<String, Map<String, Object>> actualData = (Map<String, Map<String, Object>>) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM);
            System.Assert.areEqual(0, actualData.size(), 'Wrong translation data size!');

            //test different override methods, should return the exact same result
            Map<String, Object> actualSetId_listFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new Set<Id> {expectedSof.Id}, new List<String> {'Name'}, 'en_US');
            Map<String, Object> actualSetId_setFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new Set<Id> {expectedSof.Id}, new Set<String> {'Name'}, 'en_US');
            Map<String, Object> actualListSObject_ListFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<SObject> {expectedSof}, new List<String> {'Name'}, 'en_US');
            Map<String, Object> actualListSObject_setFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<SObject> {expectedSof}, new Set<String> {'Name'}, 'en_US');

            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_listFields), 'Different result for actualSetId_listFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_setFields), 'Different result for actualSetId_setFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_ListFields), 'Different result for actualListSObject_ListFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_setFields), 'Different result for actualListSObject_setFields!');

        }

        Test.stopTest();
    }

    /**
     * @description test record value translation setting not enabled, as faculty
     */
    @IsTest
    static void testTranslationInfo_TranslationNotEnabled_AsFaculty() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();
        setCreateTLMCustomSetting(false);

        reduivy__Study_Unit__c expectedSun = updateSun(querySun());
        
        System.runAs(FACULTY_USER) {
            Map<String, Object> actualTranslationInfo = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>{expectedSun.Id}, new List<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            System.Assert.isTrue(actualTranslationInfo.isEmpty(), 'Translation Info should be empty! Actual: ' + JSON.serialize(actualTranslationInfo));
        }

        Test.stopTest();
    
    }

    /**
     * @description test normal usage of the translation info in english as faculty
     */
    @IsTest
    static void testTranslationInfo_English_AsFaculty() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();
        setCreateTLMCustomSetting(true);

        reduivy__Study_Unit__c expectedSun = updateSun(querySun());
        
        System.runAs(FACULTY_USER) {
            Map<String, Object> actualTranslationInfo = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>{expectedSun.Id}, new List<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.RECORDS_PARAM), 'Attribute named "records" should be existing!');

            //records
            List<SObject> actualRecords = (List<SObject>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            System.Assert.areEqual(expectedSun.Id, actualRecords[0].Id, 'Wrong sun record Id!');
            
            //translations
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.TRANSLATIONS_PARAM), 'Attribute named "translations" should be existing!');
            
            List<Object> actualtranslations = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM);
            System.Assert.areEqual(1, actualtranslations.size(), 'Wrong translations size!');
            
            Map<String, Object> actualtranslation = (Map<String, Object>) actualtranslations[0];
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM), 'Attribute named "data" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM), 'Attribute named "configs" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Attribute named "languageCode" from translations should be existing!');

            //translations.languageCode
            System.Assert.areEqual('en_US', actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');

            //translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig> ) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM);
            System.Assert.areEqual(1, actualConfigs.size(), 'Wrong configs size!');
            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(2, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');
            
            //translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_Desc = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_Desc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Description__c', actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            //translations.data
            Map<String, Map<String, Object>> actualData = (Map<String, Map<String, Object>>) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM);
            System.Assert.areEqual(1, actualData.size(), 'Wrong translation data size!');
            System.Assert.isTrue(actualData.containsKey(expectedSun.Id), 'Translated record should be existing!');

            Map<String, Object> actualDataRecord = actualData.get(expectedSun.Id);
            System.Assert.areEqual(SUN_DESC_EN, actualDataRecord.get('reduivy__Description__c'), 'Wrong translation data record!');

            //test different override methods, should return the exact same result
            Map<String, Object> actualSetId_listFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new Set<Id> {expectedSun.Id}, new List<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualSetId_setFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new Set<Id> {expectedSun.Id}, new Set<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualListSObject_ListFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<SObject> {expectedSun}, new List<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualListSObject_setFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<SObject> {expectedSun}, new Set<String> {'Name', 'reduivy__Description__c'}, 'en_US');


            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_listFields), 'Different result for actualSetId_listFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_setFields), 'Different result for actualSetId_setFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_ListFields), 'Different result for actualListSObject_ListFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_setFields), 'Different result for actualListSObject_setFields!');
        }

        Test.stopTest();
    
    }

    /**
     * @description test normal usage of the translation info in spanish as faculty
     */
    @IsTest
    static void testTranslationInfo_Spanish_AsFaculty() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();
        setCreateTLMCustomSetting(true);

        reduivy__Study_Unit__c expectedSun = updateSun(querySun());
        
        System.runAs(FACULTY_USER) {
            Map<String, Object> actualTranslationInfo = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>{expectedSun.Id}, new List<String> {'Name', 'reduivy__Description__c'}, 'es');
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.RECORDS_PARAM), 'Attribute named "records" should be existing!');

            //records
            List<SObject> actualRecords = (List<SObject>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            System.Assert.areEqual(expectedSun.Id, actualRecords[0].Id, 'Wrong sun record Id!');
            
            //translations
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.TRANSLATIONS_PARAM), 'Attribute named "translations" should be existing!');
            
            List<Object> actualtranslations = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM);
            System.Assert.areEqual(1, actualtranslations.size(), 'Wrong translations size!');
            
            Map<String, Object> actualtranslation = (Map<String, Object>) actualtranslations[0];
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM), 'Attribute named "data" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM), 'Attribute named "configs" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Attribute named "languageCode" from translations should be existing!');

            //translations.languageCode
            System.Assert.areEqual('es', actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');

            //translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig> ) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM);
            System.Assert.areEqual(1, actualConfigs.size(), 'Wrong configs size!');
            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(2, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');
                    
            //translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_Desc = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_Desc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Description__c', actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            //translations.data
            Map<String, Map<String, Object>> actualData = (Map<String, Map<String, Object>>) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM);
            System.Assert.areEqual(1, actualData.size(), 'Wrong translation data size!');
            System.Assert.isTrue(actualData.containsKey(expectedSun.Id), 'Translated record should be existing!');

            Map<String, Object> actualDataRecord = actualData.get(expectedSun.Id);
            System.Assert.areEqual(SUN_DESC_ES, actualDataRecord.get('reduivy__Description__c'), 'Wrong translation data record!');

            //test different override methods, should return the exact same result
            Map<String, Object> actualSetId_listFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new Set<Id> {expectedSun.Id}, new List<String> {'Name', 'reduivy__Description__c'}, 'es');
            Map<String, Object> actualSetId_setFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new Set<Id> {expectedSun.Id}, new Set<String> {'Name', 'reduivy__Description__c'}, 'es');
            Map<String, Object> actualListSObject_ListFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<SObject> {expectedSun}, new List<String> {'Name', 'reduivy__Description__c'}, 'es');
            Map<String, Object> actualListSObject_setFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<SObject> {expectedSun}, new Set<String> {'Name', 'reduivy__Description__c'}, 'es');


            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_listFields), 'Different result for actualSetId_listFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_setFields), 'Different result for actualSetId_setFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_ListFields), 'Different result for actualListSObject_ListFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_setFields), 'Different result for actualListSObject_setFields!');
        }

        Test.stopTest();
    
    }

    /**
     * @description negative test of translation info as faculty
     */
    @IsTest
    static void testTranslationInfo_Invalid_AsFaculty() {
        
        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();
        setCreateTLMCustomSetting(true);

        reduivy__Study_Unit__c expectedSun = updateSun(querySun());
        
        System.runAs(FACULTY_USER) {
            Map<String, Object> emptyListEmptyList = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>(), new List<String>(), 'en_US');
            System.Assert.isTrue(emptyListEmptyList.isEmpty(), 'Response data Should be empty');

            Map<String, Object> emptyListNull = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>(), null, 'en_US');
            System.Assert.isTrue(emptyListNull.isEmpty(), 'Response data Should be empty');

            Map<String, Object> nullSobj = REDU_TranslationManager.getTranslationInfo(null, new List<SObject> {expectedSun}, new Set<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            System.Assert.isTrue(nullSobj.isEmpty(), 'Response data Should be empty');

            Map<String, Object> nullLanguage = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>(), null, 'en_US');
            System.Assert.isTrue(nullLanguage.isEmpty(), 'Response data Should be empty');

        }
        Test.stopTest();

        
    }

    /**
     * @description test translation info with reference in english as faculty
     */
    @IsTest
    static void testTranslationInfo_Reference_AsFaculty() {
        
        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();
        setCreateTLMCustomSetting(true);

        reduivy__Study_Offering__c expectedSof = querySof();
    
        reduivy__Study_Unit__c expectedSun = expectedSof.reduivy__Study_Unit__r;

        
        System.runAs(FACULTY_USER) {
            
            Map<String, Object> actualTranslationInfo = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<String>{expectedSof.Id}, new List<String> {'Name', 'reduivy__Study_Unit__c', 'reduivy__Study_Unit__r.Name', 'reduivy__Study_Unit__r.reduivy__Description__c'}, 'en_US');
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.RECORDS_PARAM), 'Attribute named "records" should be existing!');

            //records
            List<SObject> actualRecords = (List<SObject>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            System.Assert.areEqual(expectedSof.Id, actualRecords[0].Id, 'Wrong sof record Id!');
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecords[0].get('reduivy__Study_Unit__c'), 'Wrong sun record Id!');
            
            //translations
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.TRANSLATIONS_PARAM), 'Attribute named "translations" should be existing!');
            
            List<Object> actualtranslations = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM);
            System.Assert.areEqual(1, actualtranslations.size(), 'Wrong translations size!');
            
            Map<String, Object> actualtranslation = (Map<String, Object>) actualtranslations[0];
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM), 'Attribute named "data" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM), 'Attribute named "configs" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Attribute named "languageCode" from translations should be existing!');

            //translations.languageCode
            System.Assert.areEqual('en_US', actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');

            //translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig> ) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM);
            System.Assert.areEqual(2, actualConfigs.size(), 'Wrong configs size!');
            System.Assert.areEqual(SOF_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(2, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');
            
            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[1].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.areEqual('reduivy__Study_Unit__r', actualConfigs[1].path, 'Path should be Study Unit!');
            System.Assert.areEqual(2, actualConfigs[1].fields.size(), 'Wrong fields size in configs!');
            
            //translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Offering__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_StudyUnit = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_StudyUnit.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Offering__c.fields.reduivy__Study_Unit__c.getLabel(), actualField_StudyUnit.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Study_Unit__c', actualField_StudyUnit.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_SunName = actualConfigs[1].fields[0];
            System.Assert.areEqual(2, actualField_SunName.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_SunName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_SunName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_SunDesc = actualConfigs[1].fields[1];
            System.Assert.areEqual(2, actualField_SunDesc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), actualField_SunDesc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Description__c', actualField_SunDesc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            //translations.data
            Map<String, Map<String, Object>> actualData = (Map<String, Map<String, Object>>) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM);
            System.Assert.areEqual(1, actualData.size(), 'Wrong translation data size!');

            Map<String, Object> actualDataRecord = actualData.get(expectedSun.Id);
            System.Assert.areEqual(SUN_DESC_EN, actualDataRecord.get('reduivy__Description__c'), 'Wrong translation data record!');
            
            //test different override methods, should return the exact same result
            Map<String, Object> actualSetId_listFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new Set<Id> {expectedSof.Id}, new List<String> {'Name', 'reduivy__Study_Unit__c', 'reduivy__Study_Unit__r.Name', 'reduivy__Study_Unit__r.reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualSetId_setFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new Set<Id> {expectedSof.Id}, new Set<String> {'Name', 'reduivy__Study_Unit__c', 'reduivy__Study_Unit__r.Name', 'reduivy__Study_Unit__r.reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualListSObject_ListFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<SObject> {expectedSof}, new List<String> {'Name', 'reduivy__Study_Unit__c', 'reduivy__Study_Unit__r.Name', 'reduivy__Study_Unit__r.reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualListSObject_setFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<SObject> {expectedSof}, new Set<String> {'Name', 'reduivy__Study_Unit__c', 'reduivy__Study_Unit__r.Name', 'reduivy__Study_Unit__r.reduivy__Description__c'}, 'en_US');

            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_listFields), 'Different result for actualSetId_listFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_setFields), 'Different result for actualSetId_setFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_ListFields), 'Different result for actualListSObject_ListFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_setFields), 'Different result for actualListSObject_setFields!');
        }
        
        Test.stopTest();
    }

    /**
     * @description test translation info with no translation mapping mdt in english as faculty
     */
    @IsTest
    static void testTranslationInfo_NoTranslationMappingMdt_AsFaculty() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();
        setCreateTLMCustomSetting(true);

        reduivy__Study_Offering__c expectedSof = querySof();
        System.runAs(FACULTY_USER) {

            Map<String, Object> actualTranslationInfo = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<String>{expectedSof.Id}, new List<String> {'Name'}, 'en_US');
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.RECORDS_PARAM), 'Attribute named "records" should be existing!');

            //records
            List<SObject> actualRecords = (List<SObject>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            System.Assert.areEqual(expectedSof.Id, actualRecords[0].Id, 'Wrong sof record Id!');
            
            //translations
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.TRANSLATIONS_PARAM), 'Attribute named "translations" should be existing!');
            
            List<Object> actualtranslations = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM);
            System.Assert.areEqual(1, actualtranslations.size(), 'Wrong translations size!');
            
            Map<String, Object> actualtranslation = (Map<String, Object>) actualtranslations[0];
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM), 'Attribute named "data" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM), 'Attribute named "configs" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Attribute named "languageCode" from translations should be existing!');

            //translations.languageCode
            System.Assert.areEqual('en_US', actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');

            //translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig> ) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM);
            System.Assert.areEqual(1, actualConfigs.size(), 'Wrong configs size!');
            System.Assert.areEqual(SOF_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(1, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');
            
            //translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Offering__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            //translations.data
            Map<String, Map<String, Object>> actualData = (Map<String, Map<String, Object>>) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM);
            System.Assert.areEqual(0, actualData.size(), 'Wrong translation data size!');

            //test different override methods, should return the exact same result
            Map<String, Object> actualSetId_listFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new Set<Id> {expectedSof.Id}, new List<String> {'Name'}, 'en_US');
            Map<String, Object> actualSetId_setFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new Set<Id> {expectedSof.Id}, new Set<String> {'Name'}, 'en_US');
            Map<String, Object> actualListSObject_ListFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<SObject> {expectedSof}, new List<String> {'Name'}, 'en_US');
            Map<String, Object> actualListSObject_setFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<SObject> {expectedSof}, new Set<String> {'Name'}, 'en_US');

            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_listFields), 'Different result for actualSetId_listFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_setFields), 'Different result for actualSetId_setFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_ListFields), 'Different result for actualListSObject_ListFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_setFields), 'Different result for actualListSObject_setFields!');

        }

        Test.stopTest();
    }
    
    /**
     * @description test record value translation setting not enabled, as student
     */
    @IsTest
    static void testTranslationInfo_TranslationNotEnabled_AsStudent() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User studentUser = testFactory.getStudentUser();
        Test.startTest();
        setCreateTLMCustomSetting(false);

        reduivy__Study_Unit__c expectedSun = updateSun(querySun());
        
        System.runAs(studentUser) {
            Map<String, Object> actualTranslationInfo = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>{expectedSun.Id}, new List<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            System.Assert.isTrue(actualTranslationInfo.isEmpty(), 'Translation Info should be empty! Actual: ' + JSON.serialize(actualTranslationInfo));
        }

        Test.stopTest();
    
    }

    /**
     * @description test normal usage of the translation info in english as student
     */
    @IsTest
    static void testTranslationInfo_English_AsStudent() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User studentUser = testFactory.getStudentUser();
        Test.startTest();
        setCreateTLMCustomSetting(true);

        reduivy__Study_Unit__c expectedSun = updateSun(querySun());
        
        System.runAs(studentUser) {
            Map<String, Object> actualTranslationInfo = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>{expectedSun.Id}, new List<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.RECORDS_PARAM), 'Attribute named "records" should be existing!');

            //records
            List<SObject> actualRecords = (List<SObject>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            System.Assert.areEqual(expectedSun.Id, actualRecords[0].Id, 'Wrong sun record Id!');
            
            //translations
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.TRANSLATIONS_PARAM), 'Attribute named "translations" should be existing!');
            
            List<Object> actualtranslations = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM);
            System.Assert.areEqual(1, actualtranslations.size(), 'Wrong translations size!');
            
            Map<String, Object> actualtranslation = (Map<String, Object>) actualtranslations[0];
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM), 'Attribute named "data" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM), 'Attribute named "configs" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Attribute named "languageCode" from translations should be existing!');

            //translations.languageCode
            System.Assert.areEqual('en_US', actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');

            //translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig> ) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM);
            System.Assert.areEqual(1, actualConfigs.size(), 'Wrong configs size!');
            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(2, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');
            
            //translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_Desc = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_Desc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Description__c', actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            //translations.data
            Map<String, Map<String, Object>> actualData = (Map<String, Map<String, Object>>) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM);
            System.Assert.areEqual(1, actualData.size(), 'Wrong translation data size!');
            System.Assert.isTrue(actualData.containsKey(expectedSun.Id), 'Translated record should be existing!');

            Map<String, Object> actualDataRecord = actualData.get(expectedSun.Id);
            System.Assert.areEqual(SUN_DESC_EN, actualDataRecord.get('reduivy__Description__c'), 'Wrong translation data record!');

            //test different override methods, should return the exact same result
            Map<String, Object> actualSetId_listFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new Set<Id> {expectedSun.Id}, new List<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualSetId_setFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new Set<Id> {expectedSun.Id}, new Set<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualListSObject_ListFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<SObject> {expectedSun}, new List<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualListSObject_setFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<SObject> {expectedSun}, new Set<String> {'Name', 'reduivy__Description__c'}, 'en_US');


            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_listFields), 'Different result for actualSetId_listFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_setFields), 'Different result for actualSetId_setFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_ListFields), 'Different result for actualListSObject_ListFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_setFields), 'Different result for actualListSObject_setFields!');
        }

        Test.stopTest();
    
    }

    /**
     * @description test normal usage of the translation info in spanish as student
     */
    @IsTest
    static void testTranslationInfo_Spanish_AsStudent() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User studentUser = testFactory.getStudentUser();
        Test.startTest();
        setCreateTLMCustomSetting(true);

        reduivy__Study_Unit__c expectedSun = updateSun(querySun());
        
        System.runAs(studentUser) {
            Map<String, Object> actualTranslationInfo = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>{expectedSun.Id}, new List<String> {'Name', 'reduivy__Description__c'}, 'es');
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.RECORDS_PARAM), 'Attribute named "records" should be existing!');

            //records
            List<SObject> actualRecords = (List<SObject>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            System.Assert.areEqual(expectedSun.Id, actualRecords[0].Id, 'Wrong sun record Id!');
            
            //translations
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.TRANSLATIONS_PARAM), 'Attribute named "translations" should be existing!');
            
            List<Object> actualtranslations = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM);
            System.Assert.areEqual(1, actualtranslations.size(), 'Wrong translations size!');
            
            Map<String, Object> actualtranslation = (Map<String, Object>) actualtranslations[0];
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM), 'Attribute named "data" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM), 'Attribute named "configs" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Attribute named "languageCode" from translations should be existing!');

            //translations.languageCode
            System.Assert.areEqual('es', actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');

            //translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig> ) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM);
            System.Assert.areEqual(1, actualConfigs.size(), 'Wrong configs size!');
            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(2, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');
                    
            //translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_Desc = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_Desc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Description__c', actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            //translations.data
            Map<String, Map<String, Object>> actualData = (Map<String, Map<String, Object>>) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM);
            System.Assert.areEqual(1, actualData.size(), 'Wrong translation data size!');
            System.Assert.isTrue(actualData.containsKey(expectedSun.Id), 'Translated record should be existing!');

            Map<String, Object> actualDataRecord = actualData.get(expectedSun.Id);
            System.Assert.areEqual(SUN_DESC_ES, actualDataRecord.get('reduivy__Description__c'), 'Wrong translation data record!');

            //test different override methods, should return the exact same result
            Map<String, Object> actualSetId_listFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new Set<Id> {expectedSun.Id}, new List<String> {'Name', 'reduivy__Description__c'}, 'es');
            Map<String, Object> actualSetId_setFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new Set<Id> {expectedSun.Id}, new Set<String> {'Name', 'reduivy__Description__c'}, 'es');
            Map<String, Object> actualListSObject_ListFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<SObject> {expectedSun}, new List<String> {'Name', 'reduivy__Description__c'}, 'es');
            Map<String, Object> actualListSObject_setFields = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<SObject> {expectedSun}, new Set<String> {'Name', 'reduivy__Description__c'}, 'es');


            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_listFields), 'Different result for actualSetId_listFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_setFields), 'Different result for actualSetId_setFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_ListFields), 'Different result for actualListSObject_ListFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_setFields), 'Different result for actualListSObject_setFields!');
        }

        Test.stopTest();
    
    }

    /**
     * @description negative test of translation info as student
     */
    @IsTest
    static void testTranslationInfo_Invalid_AsStudent() {
        
        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User studentUser = testFactory.getStudentUser();
        Test.startTest();
        setCreateTLMCustomSetting(true);

        reduivy__Study_Unit__c expectedSun = updateSun(querySun());
        
        System.runAs(studentUser) {
            Map<String, Object> emptyListEmptyList = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>(), new List<String>(), 'en_US');
            System.Assert.isTrue(emptyListEmptyList.isEmpty(), 'Response data Should be empty');

            Map<String, Object> emptyListNull = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>(), null, 'en_US');
            System.Assert.isTrue(emptyListNull.isEmpty(), 'Response data Should be empty');

            Map<String, Object> nullSobj = REDU_TranslationManager.getTranslationInfo(null, new List<SObject> {expectedSun}, new Set<String> {'Name', 'reduivy__Description__c'}, 'en_US');
            System.Assert.isTrue(nullSobj.isEmpty(), 'Response data Should be empty');

            Map<String, Object> nullLanguage = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), new List<String>(), null, 'en_US');
            System.Assert.isTrue(nullLanguage.isEmpty(), 'Response data Should be empty');

        }
        Test.stopTest();

        
    }

    /**
     * @description test translation info with reference in english as student
     */
    @IsTest
    static void testTranslationInfo_Reference_AsStudent() {
        
        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User studentUser = testFactory.getStudentUser();
        Test.startTest();
        setCreateTLMCustomSetting(true);

        reduivy__Study_Offering__c expectedSof = querySof();
    
        reduivy__Study_Unit__c expectedSun = expectedSof.reduivy__Study_Unit__r;

        
        System.runAs(studentUser) {
            
            Map<String, Object> actualTranslationInfo = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<String>{expectedSof.Id}, new List<String> {'Name', 'reduivy__Study_Unit__c', 'reduivy__Study_Unit__r.Name', 'reduivy__Study_Unit__r.reduivy__Description__c'}, 'en_US');
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.RECORDS_PARAM), 'Attribute named "records" should be existing!');

            //records
            List<SObject> actualRecords = (List<SObject>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            System.Assert.areEqual(expectedSof.Id, actualRecords[0].Id, 'Wrong sof record Id!');
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecords[0].get('reduivy__Study_Unit__c'), 'Wrong sun record Id!');
            
            //translations
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.TRANSLATIONS_PARAM), 'Attribute named "translations" should be existing!');
            
            List<Object> actualtranslations = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM);
            System.Assert.areEqual(1, actualtranslations.size(), 'Wrong translations size!');
            
            Map<String, Object> actualtranslation = (Map<String, Object>) actualtranslations[0];
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM), 'Attribute named "data" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM), 'Attribute named "configs" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Attribute named "languageCode" from translations should be existing!');

            //translations.languageCode
            System.Assert.areEqual('en_US', actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');

            //translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig> ) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM);
            System.Assert.areEqual(2, actualConfigs.size(), 'Wrong configs size!');
            System.Assert.areEqual(SOF_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(2, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');
            
            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[1].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.areEqual('reduivy__Study_Unit__r', actualConfigs[1].path, 'Path should be Study Unit!');
            System.Assert.areEqual(2, actualConfigs[1].fields.size(), 'Wrong fields size in configs!');
            
            //translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Offering__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_StudyUnit = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_StudyUnit.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Offering__c.fields.reduivy__Study_Unit__c.getLabel(), actualField_StudyUnit.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Study_Unit__c', actualField_StudyUnit.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_SunName = actualConfigs[1].fields[0];
            System.Assert.areEqual(2, actualField_SunName.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_SunName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_SunName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_SunDesc = actualConfigs[1].fields[1];
            System.Assert.areEqual(2, actualField_SunDesc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), actualField_SunDesc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Description__c', actualField_SunDesc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            //translations.data
            Map<String, Map<String, Object>> actualData = (Map<String, Map<String, Object>>) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM);
            System.Assert.areEqual(1, actualData.size(), 'Wrong translation data size!');

            Map<String, Object> actualDataRecord = actualData.get(expectedSun.Id);
            System.Assert.areEqual(SUN_DESC_EN, actualDataRecord.get('reduivy__Description__c'), 'Wrong translation data record!');
            
            //test different override methods, should return the exact same result
            Map<String, Object> actualSetId_listFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new Set<Id> {expectedSof.Id}, new List<String> {'Name', 'reduivy__Study_Unit__c', 'reduivy__Study_Unit__r.Name', 'reduivy__Study_Unit__r.reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualSetId_setFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new Set<Id> {expectedSof.Id}, new Set<String> {'Name', 'reduivy__Study_Unit__c', 'reduivy__Study_Unit__r.Name', 'reduivy__Study_Unit__r.reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualListSObject_ListFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<SObject> {expectedSof}, new List<String> {'Name', 'reduivy__Study_Unit__c', 'reduivy__Study_Unit__r.Name', 'reduivy__Study_Unit__r.reduivy__Description__c'}, 'en_US');
            Map<String, Object> actualListSObject_setFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<SObject> {expectedSof}, new Set<String> {'Name', 'reduivy__Study_Unit__c', 'reduivy__Study_Unit__r.Name', 'reduivy__Study_Unit__r.reduivy__Description__c'}, 'en_US');

            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_listFields), 'Different result for actualSetId_listFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_setFields), 'Different result for actualSetId_setFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_ListFields), 'Different result for actualListSObject_ListFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_setFields), 'Different result for actualListSObject_setFields!');
        }
        
        Test.stopTest();
    }

    /**
     * @description test translation info with no translation mapping mdt in english as student
     */
    @IsTest
    static void testTranslationInfo_NoTranslationMappingMdt_AsStudent() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        User studentUser = testFactory.getStudentUser();
        Test.startTest();
        setCreateTLMCustomSetting(true);

        reduivy__Study_Offering__c expectedSof = querySof();
        System.runAs(studentUser) {

            Map<String, Object> actualTranslationInfo = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<String>{expectedSof.Id}, new List<String> {'Name'}, 'en_US');
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.RECORDS_PARAM), 'Attribute named "records" should be existing!');

            //records
            List<SObject> actualRecords = (List<SObject>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            System.Assert.areEqual(expectedSof.Id, actualRecords[0].Id, 'Wrong sof record Id!');
            
            //translations
            System.Assert.isTrue(actualTranslationInfo.containsKey(REDU_TranslationManager.TRANSLATIONS_PARAM), 'Attribute named "translations" should be existing!');
            
            List<Object> actualtranslations = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM);
            System.Assert.areEqual(1, actualtranslations.size(), 'Wrong translations size!');
            
            Map<String, Object> actualtranslation = (Map<String, Object>) actualtranslations[0];
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM), 'Attribute named "data" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM), 'Attribute named "configs" from translations should be existing!');
            System.Assert.isTrue(actualtranslation.containsKey(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Attribute named "languageCode" from translations should be existing!');

            //translations.languageCode
            System.Assert.areEqual('en_US', actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');

            //translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig> ) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM);
            System.Assert.areEqual(1, actualConfigs.size(), 'Wrong configs size!');
            System.Assert.areEqual(SOF_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(1, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');
            
            //translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Offering__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            //translations.data
            Map<String, Map<String, Object>> actualData = (Map<String, Map<String, Object>>) actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM);
            System.Assert.areEqual(0, actualData.size(), 'Wrong translation data size!');

            //test different override methods, should return the exact same result
            Map<String, Object> actualSetId_listFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new Set<Id> {expectedSof.Id}, new List<String> {'Name'}, 'en_US');
            Map<String, Object> actualSetId_setFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new Set<Id> {expectedSof.Id}, new Set<String> {'Name'}, 'en_US');
            Map<String, Object> actualListSObject_ListFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<SObject> {expectedSof}, new List<String> {'Name'}, 'en_US');
            Map<String, Object> actualListSObject_setFields = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), new List<SObject> {expectedSof}, new Set<String> {'Name'}, 'en_US');

            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_listFields), 'Different result for actualSetId_listFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualSetId_setFields), 'Different result for actualSetId_setFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_ListFields), 'Different result for actualListSObject_ListFields!');
            System.Assert.areEqual(JSON.serialize(actualTranslationInfo), JSON.serialize(actualListSObject_setFields), 'Different result for actualListSObject_setFields!');

        }

        Test.stopTest();
    }

    /**
     * @description query and update the sun translation value
     * @return   return description
     */
    static reduivy__Study_Unit__c querySun(){
        reduivy__Study_Unit__c sun = [
            SELECT Id, Name
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = :SRC_SUN
            LIMIT 1
        ];

        return sun;
    }

    static reduivy__Study_Unit__c updateSun(reduivy__Study_Unit__c sun) {

        reduivy__Translation__c tln = new reduivy__Translation__c(
            reduivy__en_Rich__c = SUN_DESC_EN,
            reduivy__es_Rich__c = SUN_DESC_ES,
            reduivy__Default_Rich__c = SUN_DESC_DEF
        );
        insert tln;

        reduivy__Translation_Map__c tlm = new reduivy__Translation_Map__c();
        tlm.put('reduivy__Translation_2__c', tln.Id);

        insert tlm;

        sun.reduivy__Translation_Map__c = tlm.Id;
        sun.reduivy__Description__c = SUN_DESC_DEF;
        update sun;

        return sun;
    }

    static reduivy__Study_Offering__c querySof(){
        updateSun(querySun());
        reduivy__Study_Offering__c sof = [
            SELECT Id, Name, reduivy__Study_Unit__r.Name, reduivy__Study_Unit__r.Id, reduivy__Study_Unit__c
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Sample_Record_Code__c = :SRC_SOF
            LIMIT 1
        ];

        return sof;
    }
    
    /**
     * @description set the record value translation setting to the value given
     */
    private static void setCreateTLMCustomSetting(Boolean value) {
        if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled() != value) {
            reduivy__RIO_Education_Ivy_Settings__c setting = REDU_AppSetting_UTIL.getOrgDefaultSetting();
            setting.reduivy__Enable_Record_Value_Translation__c = value;
            update setting;
        }
    }
}