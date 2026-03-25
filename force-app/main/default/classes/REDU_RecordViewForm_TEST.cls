/**
 * @author      WDCi (XW)
 * @date        Sept 2025
 * @group       Test
 * @description Test class for REDU_RecordViewForm_LCTRL
 * @changehistory
 * ISS-002495 30-09-2025 XW - new class
 */
@IsTest
public inherited sharing class REDU_RecordViewForm_TEST {

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
        	
            testFactory.initMasterData(SUN_Helper.getApiName());
            testFactory.initOfferingData(SOF_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);
            testFactory.initFacultyData(USR_Helper.getApiName(), true);

            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for getting custom record view form data in english, record value translation not enabled with multi currencies
     */
    @IsTest
    static void testForGet_TranslationDisabled_English_MultiCurrencies_AsAdmin() {

        if (!ORG_Helper.isMultiCurrenciesOrg()) {
            //we won't run this test in non multi currencies org as it will fail
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Description__c', 'reduivy__Educational_Institution__c', 'reduivy__Educational_Institution__r.Name'};
        String language = 'en_US';

        Test.startTest();
        setCreateTLMCustomSetting(false);
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse actualResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, fields, language);

            Map<String, Object> actualResponse = (Map<String, Object>) JSON.deserializeUntyped(actualResult.responseData);

            System.Assert.areEqual(3, actualResponse.size(), 'Wrong response size!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Attribute translationInfo should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.RECORDS_PARAM), 'Attribute records should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM), 'Attribute fields should be exist!');

            //fieldsObject
            Map<String, Object> actualFieldsObject = (Map<String, Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM);
            System.Assert.areEqual(4, actualFieldsObject.size(), 'Wrong Fields Object size!');
            System.Assert.isTrue(actualFieldsObject.containsKey('Name'), 'Field "Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Description__c'), 'Field "reduivy__Description__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__c'), 'Field "reduivy__Educational_Institution__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__r.Name'), 'Field "reduivy__Educational_Institution__r.Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));

            //fieldsObject (Name)
            REDU_DynamicFieldValue_OBJ nameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), nameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', nameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), nameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SRC_SUN, nameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), nameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), nameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getInlineHelpText(), nameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Description)
            REDU_DynamicFieldValue_OBJ descFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Description__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), descFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Description__c', descFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), descFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SUN_DESC_DEF, descFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.TEXTAREA.name(), descFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), descFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getInlineHelpText(), descFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Edu inst)
            REDU_DynamicFieldValue_OBJ eduInstFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), eduInstFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', eduInstFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), eduInstFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__c, eduInstFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.REFERENCE.name(), eduInstFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.ID.name(), eduInstFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getInlineHelpText(), eduInstFieldValue.helpText, 'Wrong helpText(helpText)!');
            
            //fieldsObject (Edu inst.Name)
            REDU_DynamicFieldValue_OBJ eduInstNameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__r.Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(ACC_Helper.getApiName(), eduInstNameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', eduInstNameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), eduInstNameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__r.Name, eduInstNameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), eduInstNameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), eduInstNameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getInlineHelpText(), eduInstNameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //records
            List<Object> actualRecords = (List<Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            Map<String, Object> actualRecord = (Map<String, Object>) (actualRecords[0]);
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecord.get('Id'), 'Wrong tudy Unit Id!');
            System.Assert.isTrue(actualRecord.containsKey('CurrencyIsoCode'), 'The CurrencyIsoCode is not found.');

            //translationInfo
            Map<String, Object> actualTranslationInfo = (Map<String, Object>) actualResponse.get(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM);
            System.Assert.areEqual(0, actualTranslationInfo.size(), 'Translation Info should be empty! Actual: ' + JSON.serialize(actualTranslationInfo));
		} 

        Test.stopTest();
    }

    /**
     * @description Test as admin for getting custom record view form data in english
     */
    @IsTest
    static void testForGet_TranslationEnabled_English_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Description__c', 'reduivy__Educational_Institution__c', 'reduivy__Educational_Institution__r.Name'};
        String language = 'en_US';

        Test.startTest();
        setCreateTLMCustomSetting(true);
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse actualResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, fields, language);

            Map<String, Object> actualResponse = (Map<String, Object>) JSON.deserializeUntyped(actualResult.responseData);

            System.Assert.areEqual(3, actualResponse.size(), 'Wrong response size!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Attribute translationInfo should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.RECORDS_PARAM), 'Attribute records should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM), 'Attribute fields should be exist!');

            //fieldsObject
            Map<String, Object> actualFieldsObject = (Map<String, Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM);
            System.Assert.areEqual(4, actualFieldsObject.size(), 'Wrong Fields Object size!');
            System.Assert.isTrue(actualFieldsObject.containsKey('Name'), 'Field "Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Description__c'), 'Field "reduivy__Description__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__c'), 'Field "reduivy__Educational_Institution__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__r.Name'), 'Field "reduivy__Educational_Institution__r.Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));

            //fieldsObject (Name)
            REDU_DynamicFieldValue_OBJ nameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), nameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', nameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), nameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SRC_SUN, nameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), nameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), nameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getInlineHelpText(), nameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Description)
            REDU_DynamicFieldValue_OBJ descFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Description__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), descFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Description__c', descFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), descFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SUN_DESC_DEF, descFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.TEXTAREA.name(), descFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), descFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getInlineHelpText(), descFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Edu inst)
            REDU_DynamicFieldValue_OBJ eduInstFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), eduInstFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', eduInstFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), eduInstFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__c, eduInstFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.REFERENCE.name(), eduInstFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.ID.name(), eduInstFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getInlineHelpText(), eduInstFieldValue.helpText, 'Wrong helpText(helpText)!');
            
            //fieldsObject (Edu inst.Name)
            REDU_DynamicFieldValue_OBJ eduInstNameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__r.Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(ACC_Helper.getApiName(), eduInstNameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', eduInstNameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), eduInstNameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__r.Name, eduInstNameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), eduInstNameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), eduInstNameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getInlineHelpText(), eduInstNameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //records
            List<Object> actualRecords = (List<Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            Map<String, Object> actualRecord = (Map<String, Object>) (actualRecords[0]);
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecord.get('Id'), 'Wrong tudy Unit Id!');

            //translationInfo
            Map<String, Object> actualTranslationInfo = (Map<String, Object>) actualResponse.get(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM);
            Object actualTranslationObj = ((List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM))[0];
            Map<String, Object> actualTranslation = (Map<String, Object>) actualTranslationObj;

            //translationInfo.records
            List<Object> actualTranslationInfoRecords = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualTranslationInfoRecords.size(), 'Wrong records size!');
            Map<String, Object> actualTranslationInfoRecord = (Map<String, Object>) actualTranslationInfoRecords[0];
            System.Assert.areEqual(expectedSun.Id, (Id) actualTranslationInfoRecord.get('Id'), 'Wrong record!');

            //translationInfo.translations.languageCode
            System.Assert.areEqual(language, actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');
        
            //translationInfo.translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig>) JSON.deserialize(JSON.serialize(actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM)), List<REDU_TranslationManager.TranslationConfig>.class);
            System.Assert.areEqual(2, actualConfigs.size(), 'Wrong configs size!');

            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(3, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');

            System.Assert.areEqual(ACC_Helper.getApiName(), actualConfigs[1].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.areEqual('reduivy__Educational_Institution__r', actualConfigs[1].path, 'Wrong path in configs!');
            System.Assert.areEqual(1, actualConfigs[1].fields.size(), 'Wrong fields size in configs!');

            
            //translationInfo.translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_Desc = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_Desc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Description__c', actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');
            
            Map<String, String> actualField_EduInst = actualConfigs[0].fields[2];
            System.Assert.areEqual(2, actualField_EduInst.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), actualField_EduInst.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', actualField_EduInst.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_EduInstName = actualConfigs[1].fields[0];
            System.Assert.areEqual(2, actualField_EduInstName.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), actualField_EduInstName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_EduInstName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');
            
            //translationInfo.translations.data
            Map<String, Object> actualData = (Map<String, Object>) (actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM));
            System.Assert.areEqual(1, actualData.size(), 'Wrong translation data size!');
            System.Assert.isTrue(actualData.containsKey(expectedSun.Id), 'Translated record should be existing!');

            Map<String, Object> actualDataRecordSun = (Map<String, Object>)actualData.get(expectedSun.Id);
            System.Assert.areEqual(SUN_DESC_EN, actualDataRecordSun.get('reduivy__Description__c'), 'Wrong translation data record!');

		} 

        Test.stopTest();
    }

    /**
     * @description Test as admin for getting custom record view form data in english, record value translation not enabled
     */
    @IsTest
    static void testForGet_TranslationDisabled_English_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Description__c', 'reduivy__Educational_Institution__c', 'reduivy__Educational_Institution__r.Name'};
        String language = 'en_US';

        Test.startTest();
        setCreateTLMCustomSetting(false);
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse actualResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, fields, language);

            Map<String, Object> actualResponse = (Map<String, Object>) JSON.deserializeUntyped(actualResult.responseData);

            System.Assert.areEqual(3, actualResponse.size(), 'Wrong response size!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Attribute translationInfo should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.RECORDS_PARAM), 'Attribute records should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM), 'Attribute fields should be exist!');

            //fieldsObject
            Map<String, Object> actualFieldsObject = (Map<String, Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM);
            System.Assert.areEqual(4, actualFieldsObject.size(), 'Wrong Fields Object size!');
            System.Assert.isTrue(actualFieldsObject.containsKey('Name'), 'Field "Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Description__c'), 'Field "reduivy__Description__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__c'), 'Field "reduivy__Educational_Institution__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__r.Name'), 'Field "reduivy__Educational_Institution__r.Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));

            //fieldsObject (Name)
            REDU_DynamicFieldValue_OBJ nameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), nameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', nameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), nameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SRC_SUN, nameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), nameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), nameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getInlineHelpText(), nameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Description)
            REDU_DynamicFieldValue_OBJ descFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Description__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), descFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Description__c', descFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), descFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SUN_DESC_DEF, descFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.TEXTAREA.name(), descFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), descFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getInlineHelpText(), descFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Edu inst)
            REDU_DynamicFieldValue_OBJ eduInstFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), eduInstFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', eduInstFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), eduInstFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__c, eduInstFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.REFERENCE.name(), eduInstFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.ID.name(), eduInstFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getInlineHelpText(), eduInstFieldValue.helpText, 'Wrong helpText(helpText)!');
            
            //fieldsObject (Edu inst.Name)
            REDU_DynamicFieldValue_OBJ eduInstNameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__r.Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(ACC_Helper.getApiName(), eduInstNameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', eduInstNameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), eduInstNameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__r.Name, eduInstNameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), eduInstNameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), eduInstNameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getInlineHelpText(), eduInstNameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //records
            List<Object> actualRecords = (List<Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            Map<String, Object> actualRecord = (Map<String, Object>) (actualRecords[0]);
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecord.get('Id'), 'Wrong tudy Unit Id!');

            //translationInfo
            Map<String, Object> actualTranslationInfo = (Map<String, Object>) actualResponse.get(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM);
            System.Assert.areEqual(0, actualTranslationInfo.size(), 'Translation Info should be empty! Actual: ' + JSON.serialize(actualTranslationInfo));
		} 

        Test.stopTest();
    }

    /**
     * @description Test as admin for getting custom record view form data in english, record value translation not enabled, language empty
     */
    @IsTest
    static void testForGet_TranslationDisabled_Empty_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Description__c', 'reduivy__Educational_Institution__c', 'reduivy__Educational_Institution__r.Name'};
        String language = '';

        Test.startTest();
        setCreateTLMCustomSetting(false);
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse actualResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, fields, language);

            Map<String, Object> actualResponse = (Map<String, Object>) JSON.deserializeUntyped(actualResult.responseData);

            System.Assert.areEqual(3, actualResponse.size(), 'Wrong response size!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Attribute translationInfo should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.RECORDS_PARAM), 'Attribute records should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM), 'Attribute fields should be exist!');

            //fieldsObject
            Map<String, Object> actualFieldsObject = (Map<String, Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM);
            System.Assert.areEqual(4, actualFieldsObject.size(), 'Wrong Fields Object size!');
            System.Assert.isTrue(actualFieldsObject.containsKey('Name'), 'Field "Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Description__c'), 'Field "reduivy__Description__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__c'), 'Field "reduivy__Educational_Institution__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__r.Name'), 'Field "reduivy__Educational_Institution__r.Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));

            //fieldsObject (Name)
            REDU_DynamicFieldValue_OBJ nameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), nameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', nameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), nameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SRC_SUN, nameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), nameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), nameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getInlineHelpText(), nameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Description)
            REDU_DynamicFieldValue_OBJ descFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Description__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), descFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Description__c', descFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), descFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SUN_DESC_DEF, descFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.TEXTAREA.name(), descFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), descFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getInlineHelpText(), descFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Edu inst)
            REDU_DynamicFieldValue_OBJ eduInstFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), eduInstFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', eduInstFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), eduInstFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__c, eduInstFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.REFERENCE.name(), eduInstFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.ID.name(), eduInstFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getInlineHelpText(), eduInstFieldValue.helpText, 'Wrong helpText(helpText)!');
            
            //fieldsObject (Edu inst.Name)
            REDU_DynamicFieldValue_OBJ eduInstNameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__r.Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(ACC_Helper.getApiName(), eduInstNameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', eduInstNameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), eduInstNameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__r.Name, eduInstNameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), eduInstNameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), eduInstNameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getInlineHelpText(), eduInstNameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //records
            List<Object> actualRecords = (List<Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            Map<String, Object> actualRecord = (Map<String, Object>) (actualRecords[0]);
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecord.get('Id'), 'Wrong tudy Unit Id!');

            //translationInfo
            Map<String, Object> actualTranslationInfo = (Map<String, Object>) actualResponse.get(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM);
            System.Assert.areEqual(0, actualTranslationInfo.size(), 'Translation Info should be empty! Actual: ' + JSON.serialize(actualTranslationInfo));
		} 

        Test.stopTest();
    }

    /**
     * @description Test as admin for getting custom record view form data in spanish
     */
    @IsTest
    static void testForGet_TranslationEnabled_Spanish_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Description__c', 'reduivy__Educational_Institution__c', 'reduivy__Educational_Institution__r.Name'};
        String language = 'es';

        Test.startTest();
        setCreateTLMCustomSetting(true);
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse actualResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, fields, language);

            Map<String, Object> actualResponse = (Map<String, Object>) JSON.deserializeUntyped(actualResult.responseData);

            System.Assert.areEqual(3, actualResponse.size(), 'Wrong response size!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Attribute translationInfo should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.RECORDS_PARAM), 'Attribute records should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM), 'Attribute fields should be exist!');

            //fieldsObject
            Map<String, Object> actualFieldsObject = (Map<String, Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM);
            System.Assert.areEqual(4, actualFieldsObject.size(), 'Wrong Fields Object size!');
            System.Assert.isTrue(actualFieldsObject.containsKey('Name'), 'Field "Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Description__c'), 'Field "reduivy__Description__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__c'), 'Field "reduivy__Educational_Institution__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__r.Name'), 'Field "reduivy__Educational_Institution__r.Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));

            //fieldsObject (Name)
            REDU_DynamicFieldValue_OBJ nameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), nameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', nameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), nameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SRC_SUN, nameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), nameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), nameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getInlineHelpText(), nameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Description)
            REDU_DynamicFieldValue_OBJ descFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Description__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), descFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Description__c', descFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), descFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SUN_DESC_DEF, descFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.TEXTAREA.name(), descFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), descFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getInlineHelpText(), descFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Edu inst)
            REDU_DynamicFieldValue_OBJ eduInstFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), eduInstFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', eduInstFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), eduInstFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__c, eduInstFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.REFERENCE.name(), eduInstFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.ID.name(), eduInstFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getInlineHelpText(), eduInstFieldValue.helpText, 'Wrong helpText(helpText)!');
            
            //fieldsObject (Edu inst.Name)
            REDU_DynamicFieldValue_OBJ eduInstNameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__r.Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(ACC_Helper.getApiName(), eduInstNameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', eduInstNameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), eduInstNameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__r.Name, eduInstNameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), eduInstNameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), eduInstNameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getInlineHelpText(), eduInstNameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //records
            List<Object> actualRecords = (List<Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            Map<String, Object> actualRecord = (Map<String, Object>) (actualRecords[0]);
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecord.get('Id'), 'Wrong tudy Unit Id!');

            //translationInfo
            Map<String, Object> actualTranslationInfo = (Map<String, Object>) actualResponse.get(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM);
            Object actualTranslationObj = ((List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM))[0];
            Map<String, Object> actualTranslation = (Map<String, Object>) actualTranslationObj;

            //translationInfo.records
            List<Object> actualTranslationInfoRecords = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualTranslationInfoRecords.size(), 'Wrong records size!');
            Map<String, Object> actualTranslationInfoRecord = (Map<String, Object>) actualTranslationInfoRecords[0];
            System.Assert.areEqual(expectedSun.Id, (Id) actualTranslationInfoRecord.get('Id'), 'Wrong record!');

            //translationInfo.translations.languageCode
            System.Assert.areEqual(language, actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');
        
            //translationInfo.translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig>) JSON.deserialize(JSON.serialize(actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM)), List<REDU_TranslationManager.TranslationConfig>.class);
            System.Assert.areEqual(2, actualConfigs.size(), 'Wrong configs size!');

            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(3, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');

            System.Assert.areEqual(ACC_Helper.getApiName(), actualConfigs[1].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.areEqual('reduivy__Educational_Institution__r', actualConfigs[1].path, 'Wrong path in configs!');
            System.Assert.areEqual(1, actualConfigs[1].fields.size(), 'Wrong fields size in configs!');

            
            //translationInfo.translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_Desc = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_Desc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Description__c', actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');
            
            Map<String, String> actualField_EduInst = actualConfigs[0].fields[2];
            System.Assert.areEqual(2, actualField_EduInst.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), actualField_EduInst.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', actualField_EduInst.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_EduInstName = actualConfigs[1].fields[0];
            System.Assert.areEqual(2, actualField_EduInstName.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), actualField_EduInstName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_EduInstName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');
            
            //translationInfo.translations.data
            Map<String, Object> actualData = (Map<String, Object>) (actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM));
            System.Assert.areEqual(1, actualData.size(), 'Wrong translation data size!');
            System.Assert.isTrue(actualData.containsKey(expectedSun.Id), 'Translated record should be existing!');

            Map<String, Object> actualDataRecord = (Map<String, Object>)actualData.get(expectedSun.Id);
            System.Assert.areEqual(SUN_DESC_ES, actualDataRecord.get('reduivy__Description__c'), 'Wrong translation data record!');
            
		} 

        Test.stopTest();
    }

    /**
     * @description Test as admin for getting custom record view form data(invalid)
     */
    @IsTest
    static void testForGet_TranslationEnabled_Invalid_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Description__c', 'reduivy__Educational_Institution__c', 'reduivy__Educational_Institution__r.Name'};
        String language = 'en_US';

        Test.startTest();
        setCreateTLMCustomSetting(true);
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse emptyRecordIdResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue('', objectApiName, fields, language);
            Map<String, Object> emptyRecordIdResponse = (Map<String, Object>) JSON.deserializeUntyped(emptyRecordIdResult.responseData);
            System.Assert.isTrue(emptyRecordIdResponse.isEmpty(), 'Response should be empty! Actual: ' + JSON.serialize(emptyRecordIdResponse));

            REDU_LightningResponse emptyObjectNameResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, '', fields, language);
            Map<String, Object> emptyObjectNameResponse = (Map<String, Object>) JSON.deserializeUntyped(emptyObjectNameResult.responseData);
            System.Assert.isTrue(emptyObjectNameResponse.isEmpty(), 'Response should be empty! Actual: ' + JSON.serialize(emptyObjectNameResponse));

            REDU_LightningResponse emptyFieldsResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, new List<String>(), language);
            Map<String, Object> emptyFieldsResponse = (Map<String, Object>) JSON.deserializeUntyped(emptyFieldsResult.responseData);
            System.Assert.isTrue(emptyFieldsResponse.isEmpty(), 'Response should be empty! Actual: ' + JSON.serialize(emptyFieldsResponse));

            REDU_LightningResponse nullFieldsResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, null, language);
            Map<String, Object> nullFieldsResponse = (Map<String, Object>) JSON.deserializeUntyped(nullFieldsResult.responseData);
            System.Assert.isTrue(nullFieldsResponse.isEmpty(), 'Response should be empty! Actual: ' + JSON.serialize(nullFieldsResponse));
		} 

        Test.stopTest();
    }

    /**
     * @description Test as admin for getting custom record view form data with double
     */
    @IsTest
    static void testForGet_TranslationEnabled_Double_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Credits__c'};
        String language = 'en_US';

        Test.startTest();
        setCreateTLMCustomSetting(true);
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse actualResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, fields, language);

            Map<String, Object> actualResponse = (Map<String, Object>) JSON.deserializeUntyped(actualResult.responseData);

            System.Assert.areEqual(3, actualResponse.size(), 'Wrong response size!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Attribute translationInfo should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.RECORDS_PARAM), 'Attribute records should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM), 'Attribute fields should be exist!');

            //fieldsObject
            Map<String, Object> actualFieldsObject = (Map<String, Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM);
            System.Assert.areEqual(2, actualFieldsObject.size(), 'Wrong Fields Object size!');
            System.Assert.isTrue(actualFieldsObject.containsKey('Name'), 'Field "Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Credits__c'), 'Field "reduivy__Credits__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));

            //fieldsObject (Name)
            REDU_DynamicFieldValue_OBJ nameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), nameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', nameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), nameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SRC_SUN, nameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), nameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), nameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getInlineHelpText(), nameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Credits)
            Map<String, Object> creditsFieldValue = (Map<String, Object>) actualFieldsObject.get('reduivy__Credits__c');
            System.Assert.areEqual(SUN_Helper.getApiName(), String.valueOf(creditsFieldValue.get('objectName')), 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Credits__c', String.valueOf(creditsFieldValue.get('fieldName')), 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Credits__c.getLabel(), String.valueOf(creditsFieldValue.get('label')), 'Wrong label!');
            System.Assert.areEqual('10.0000', String.valueOf(creditsFieldValue.get('value')), 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.DOUBLE.name(), String.valueOf(creditsFieldValue.get('displayType')), 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.DOUBLE.name(), String.valueOf(creditsFieldValue.get('soapDisplayType')), 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Credits__c.getInlineHelpText(), String.valueOf(creditsFieldValue.get('helpText')), 'Wrong helpText(helpText)!');
            

            //records
            List<Object> actualRecords = (List<Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            Map<String, Object> actualRecord = (Map<String, Object>) (actualRecords[0]);
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecord.get('Id'), 'Wrong tudy Unit Id!');

            //translationInfo
            Map<String, Object> actualTranslationInfo = (Map<String, Object>) actualResponse.get(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM);
            Object actualTranslationObj = ((List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM))[0];
            Map<String, Object> actualTranslation = (Map<String, Object>) actualTranslationObj;

            //translationInfo.records
            List<Object> actualTranslationInfoRecords = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualTranslationInfoRecords.size(), 'Wrong records size!');
            Map<String, Object> actualTranslationInfoRecord = (Map<String, Object>) actualTranslationInfoRecords[0];
            System.Assert.areEqual(expectedSun.Id, (Id) actualTranslationInfoRecord.get('Id'), 'Wrong record!');

            //translationInfo.translations.languageCode
            System.Assert.areEqual(language, actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');
        
            //translationInfo.translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig>) JSON.deserialize(JSON.serialize(actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM)), List<REDU_TranslationManager.TranslationConfig>.class);
            System.Assert.areEqual(1, actualConfigs.size(), 'Wrong configs size!');

            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(2, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');
            
            //translationInfo.translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_Desc = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_Desc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Credits__c.getLabel(), actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Credits__c', actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');
            
            //translationInfo.translations.data
            Map<String, Object> actualData = (Map<String, Object>) (actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM));
            System.Assert.areEqual(0, actualData.size(), 'Wrong translation data size!');
		} 

        Test.stopTest();
    }

    /**
     * @description Test as faculty for getting custom record view form data in english
     */
    @IsTest
    static void testForGet_TranslationEnabled_English_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Description__c', 'reduivy__Educational_Institution__c', 'reduivy__Educational_Institution__r.Name'};
        String language = 'en_US';

        Test.startTest();
        setCreateTLMCustomSetting(true);
        
		System.runAs(FACULTY_USER){
            REDU_LightningResponse actualResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, fields, language);

            Map<String, Object> actualResponse = (Map<String, Object>) JSON.deserializeUntyped(actualResult.responseData);

            System.Assert.areEqual(3, actualResponse.size(), 'Wrong response size!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Attribute translationInfo should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.RECORDS_PARAM), 'Attribute records should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM), 'Attribute fields should be exist!');

            //fieldsObject
            Map<String, Object> actualFieldsObject = (Map<String, Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM);
            System.Assert.areEqual(4, actualFieldsObject.size(), 'Wrong Fields Object size!');
            System.Assert.isTrue(actualFieldsObject.containsKey('Name'), 'Field "Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Description__c'), 'Field "reduivy__Description__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__c'), 'Field "reduivy__Educational_Institution__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__r.Name'), 'Field "reduivy__Educational_Institution__r.Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));

            //fieldsObject (Name)
            REDU_DynamicFieldValue_OBJ nameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), nameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', nameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), nameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SRC_SUN, nameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), nameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), nameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getInlineHelpText(), nameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Description)
            REDU_DynamicFieldValue_OBJ descFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Description__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), descFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Description__c', descFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), descFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SUN_DESC_DEF, descFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.TEXTAREA.name(), descFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), descFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getInlineHelpText(), descFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Edu inst)
            REDU_DynamicFieldValue_OBJ eduInstFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), eduInstFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', eduInstFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), eduInstFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__c, eduInstFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.REFERENCE.name(), eduInstFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.ID.name(), eduInstFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getInlineHelpText(), eduInstFieldValue.helpText, 'Wrong helpText(helpText)!');
            
            //fieldsObject (Edu inst.Name)
            REDU_DynamicFieldValue_OBJ eduInstNameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__r.Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(ACC_Helper.getApiName(), eduInstNameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', eduInstNameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), eduInstNameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__r.Name, eduInstNameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), eduInstNameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), eduInstNameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getInlineHelpText(), eduInstNameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //records
            List<Object> actualRecords = (List<Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            Map<String, Object> actualRecord = (Map<String, Object>) (actualRecords[0]);
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecord.get('Id'), 'Wrong tudy Unit Id!');

            //translationInfo
            Map<String, Object> actualTranslationInfo = (Map<String, Object>) actualResponse.get(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM);
            Object actualTranslationObj = ((List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM))[0];
            Map<String, Object> actualTranslation = (Map<String, Object>) actualTranslationObj;

            //translationInfo.records
            List<Object> actualTranslationInfoRecords = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualTranslationInfoRecords.size(), 'Wrong records size!');
            Map<String, Object> actualTranslationInfoRecord = (Map<String, Object>) actualTranslationInfoRecords[0];
            System.Assert.areEqual(expectedSun.Id, (Id) actualTranslationInfoRecord.get('Id'), 'Wrong record!');

            //translationInfo.translations.languageCode
            System.Assert.areEqual(language, actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');
        
            //translationInfo.translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig>) JSON.deserialize(JSON.serialize(actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM)), List<REDU_TranslationManager.TranslationConfig>.class);
            System.Assert.areEqual(2, actualConfigs.size(), 'Wrong configs size!');

            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(3, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');

            System.Assert.areEqual(ACC_Helper.getApiName(), actualConfigs[1].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.areEqual('reduivy__Educational_Institution__r', actualConfigs[1].path, 'Wrong path in configs!');
            System.Assert.areEqual(1, actualConfigs[1].fields.size(), 'Wrong fields size in configs!');

            
            //translationInfo.translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_Desc = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_Desc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Description__c', actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');
            
            Map<String, String> actualField_EduInst = actualConfigs[0].fields[2];
            System.Assert.areEqual(2, actualField_EduInst.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), actualField_EduInst.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', actualField_EduInst.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_EduInstName = actualConfigs[1].fields[0];
            System.Assert.areEqual(2, actualField_EduInstName.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), actualField_EduInstName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_EduInstName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');
            
            //translationInfo.translations.data
            Map<String, Object> actualData = (Map<String, Object>) (actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM));
            System.Assert.areEqual(1, actualData.size(), 'Wrong translation data size!');
            System.Assert.isTrue(actualData.containsKey(expectedSun.Id), 'Translated record should be existing!');

            Map<String, Object> actualDataRecordSun = (Map<String, Object>)actualData.get(expectedSun.Id);
            System.Assert.areEqual(SUN_DESC_EN, actualDataRecordSun.get('reduivy__Description__c'), 'Wrong translation data record!');

		} 

        Test.stopTest();
    }

    /**
     * @description Test as faculty for getting custom record view form data in english, record value translation not enabled
     */
    @IsTest
    static void testForGet_TranslationDisabled_English_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Description__c', 'reduivy__Educational_Institution__c', 'reduivy__Educational_Institution__r.Name'};
        String language = 'en_US';

        Test.startTest();
        setCreateTLMCustomSetting(false);
        
		System.runAs(FACULTY_USER){
            REDU_LightningResponse actualResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, fields, language);

            Map<String, Object> actualResponse = (Map<String, Object>) JSON.deserializeUntyped(actualResult.responseData);

            System.Assert.areEqual(3, actualResponse.size(), 'Wrong response size!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Attribute translationInfo should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.RECORDS_PARAM), 'Attribute records should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM), 'Attribute fields should be exist!');

            //fieldsObject
            Map<String, Object> actualFieldsObject = (Map<String, Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM);
            System.Assert.areEqual(4, actualFieldsObject.size(), 'Wrong Fields Object size!');
            System.Assert.isTrue(actualFieldsObject.containsKey('Name'), 'Field "Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Description__c'), 'Field "reduivy__Description__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__c'), 'Field "reduivy__Educational_Institution__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__r.Name'), 'Field "reduivy__Educational_Institution__r.Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));

            //fieldsObject (Name)
            REDU_DynamicFieldValue_OBJ nameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), nameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', nameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), nameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SRC_SUN, nameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), nameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), nameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getInlineHelpText(), nameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Description)
            REDU_DynamicFieldValue_OBJ descFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Description__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), descFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Description__c', descFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), descFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SUN_DESC_DEF, descFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.TEXTAREA.name(), descFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), descFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getInlineHelpText(), descFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Edu inst)
            REDU_DynamicFieldValue_OBJ eduInstFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), eduInstFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', eduInstFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), eduInstFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__c, eduInstFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.REFERENCE.name(), eduInstFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.ID.name(), eduInstFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getInlineHelpText(), eduInstFieldValue.helpText, 'Wrong helpText(helpText)!');
            
            //fieldsObject (Edu inst.Name)
            REDU_DynamicFieldValue_OBJ eduInstNameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__r.Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(ACC_Helper.getApiName(), eduInstNameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', eduInstNameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), eduInstNameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__r.Name, eduInstNameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), eduInstNameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), eduInstNameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getInlineHelpText(), eduInstNameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //records
            List<Object> actualRecords = (List<Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            Map<String, Object> actualRecord = (Map<String, Object>) (actualRecords[0]);
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecord.get('Id'), 'Wrong tudy Unit Id!');

            //translationInfo
            Map<String, Object> actualTranslationInfo = (Map<String, Object>) actualResponse.get(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM);
            System.Assert.areEqual(0, actualTranslationInfo.size(), 'Translation Info should be empty! Actual: ' + JSON.serialize(actualTranslationInfo));
		} 

        Test.stopTest();
    }

    /**
     * @description Test as faculty for getting custom record view form data in english, record value translation not enabled, language empty
     */
    @IsTest
    static void testForGet_TranslationDisabled_Empty_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Description__c', 'reduivy__Educational_Institution__c', 'reduivy__Educational_Institution__r.Name'};
        String language = '';

        Test.startTest();
        setCreateTLMCustomSetting(false);
        
		System.runAs(FACULTY_USER){
            REDU_LightningResponse actualResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, fields, language);

            Map<String, Object> actualResponse = (Map<String, Object>) JSON.deserializeUntyped(actualResult.responseData);

            System.Assert.areEqual(3, actualResponse.size(), 'Wrong response size!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Attribute translationInfo should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.RECORDS_PARAM), 'Attribute records should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM), 'Attribute fields should be exist!');

            //fieldsObject
            Map<String, Object> actualFieldsObject = (Map<String, Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM);
            System.Assert.areEqual(4, actualFieldsObject.size(), 'Wrong Fields Object size!');
            System.Assert.isTrue(actualFieldsObject.containsKey('Name'), 'Field "Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Description__c'), 'Field "reduivy__Description__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__c'), 'Field "reduivy__Educational_Institution__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__r.Name'), 'Field "reduivy__Educational_Institution__r.Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));

            //fieldsObject (Name)
            REDU_DynamicFieldValue_OBJ nameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), nameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', nameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), nameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SRC_SUN, nameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), nameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), nameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getInlineHelpText(), nameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Description)
            REDU_DynamicFieldValue_OBJ descFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Description__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), descFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Description__c', descFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), descFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SUN_DESC_DEF, descFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.TEXTAREA.name(), descFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), descFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getInlineHelpText(), descFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Edu inst)
            REDU_DynamicFieldValue_OBJ eduInstFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), eduInstFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', eduInstFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), eduInstFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__c, eduInstFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.REFERENCE.name(), eduInstFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.ID.name(), eduInstFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getInlineHelpText(), eduInstFieldValue.helpText, 'Wrong helpText(helpText)!');
            
            //fieldsObject (Edu inst.Name)
            REDU_DynamicFieldValue_OBJ eduInstNameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__r.Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(ACC_Helper.getApiName(), eduInstNameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', eduInstNameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), eduInstNameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__r.Name, eduInstNameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), eduInstNameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), eduInstNameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getInlineHelpText(), eduInstNameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //records
            List<Object> actualRecords = (List<Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            Map<String, Object> actualRecord = (Map<String, Object>) (actualRecords[0]);
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecord.get('Id'), 'Wrong tudy Unit Id!');

            //translationInfo
            Map<String, Object> actualTranslationInfo = (Map<String, Object>) actualResponse.get(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM);
            System.Assert.areEqual(0, actualTranslationInfo.size(), 'Translation Info should be empty! Actual: ' + JSON.serialize(actualTranslationInfo));
		} 

        Test.stopTest();
    }

    /**
     * @description Test as faculty for getting custom record view form data in spanish
     */
    @IsTest
    static void testForGet_TranslationEnabled_Spanish_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Description__c', 'reduivy__Educational_Institution__c', 'reduivy__Educational_Institution__r.Name'};
        String language = 'es';

        Test.startTest();
        setCreateTLMCustomSetting(true);
        
		System.runAs(FACULTY_USER){
            REDU_LightningResponse actualResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, fields, language);

            Map<String, Object> actualResponse = (Map<String, Object>) JSON.deserializeUntyped(actualResult.responseData);

            System.Assert.areEqual(3, actualResponse.size(), 'Wrong response size!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Attribute translationInfo should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.RECORDS_PARAM), 'Attribute records should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM), 'Attribute fields should be exist!');

            //fieldsObject
            Map<String, Object> actualFieldsObject = (Map<String, Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM);
            System.Assert.areEqual(4, actualFieldsObject.size(), 'Wrong Fields Object size!');
            System.Assert.isTrue(actualFieldsObject.containsKey('Name'), 'Field "Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Description__c'), 'Field "reduivy__Description__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__c'), 'Field "reduivy__Educational_Institution__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__r.Name'), 'Field "reduivy__Educational_Institution__r.Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));

            //fieldsObject (Name)
            REDU_DynamicFieldValue_OBJ nameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), nameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', nameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), nameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SRC_SUN, nameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), nameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), nameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getInlineHelpText(), nameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Description)
            REDU_DynamicFieldValue_OBJ descFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Description__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), descFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Description__c', descFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), descFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SUN_DESC_DEF, descFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.TEXTAREA.name(), descFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), descFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getInlineHelpText(), descFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Edu inst)
            REDU_DynamicFieldValue_OBJ eduInstFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), eduInstFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', eduInstFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), eduInstFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__c, eduInstFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.REFERENCE.name(), eduInstFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.ID.name(), eduInstFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getInlineHelpText(), eduInstFieldValue.helpText, 'Wrong helpText(helpText)!');
            
            //fieldsObject (Edu inst.Name)
            REDU_DynamicFieldValue_OBJ eduInstNameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__r.Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(ACC_Helper.getApiName(), eduInstNameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', eduInstNameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), eduInstNameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__r.Name, eduInstNameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), eduInstNameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), eduInstNameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getInlineHelpText(), eduInstNameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //records
            List<Object> actualRecords = (List<Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            Map<String, Object> actualRecord = (Map<String, Object>) (actualRecords[0]);
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecord.get('Id'), 'Wrong tudy Unit Id!');

            //translationInfo
            Map<String, Object> actualTranslationInfo = (Map<String, Object>) actualResponse.get(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM);
            Object actualTranslationObj = ((List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM))[0];
            Map<String, Object> actualTranslation = (Map<String, Object>) actualTranslationObj;

            //translationInfo.records
            List<Object> actualTranslationInfoRecords = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualTranslationInfoRecords.size(), 'Wrong records size!');
            Map<String, Object> actualTranslationInfoRecord = (Map<String, Object>) actualTranslationInfoRecords[0];
            System.Assert.areEqual(expectedSun.Id, (Id) actualTranslationInfoRecord.get('Id'), 'Wrong record!');

            //translationInfo.translations.languageCode
            System.Assert.areEqual(language, actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');
        
            //translationInfo.translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig>) JSON.deserialize(JSON.serialize(actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM)), List<REDU_TranslationManager.TranslationConfig>.class);
            System.Assert.areEqual(2, actualConfigs.size(), 'Wrong configs size!');

            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(3, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');

            System.Assert.areEqual(ACC_Helper.getApiName(), actualConfigs[1].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.areEqual('reduivy__Educational_Institution__r', actualConfigs[1].path, 'Wrong path in configs!');
            System.Assert.areEqual(1, actualConfigs[1].fields.size(), 'Wrong fields size in configs!');

            
            //translationInfo.translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_Desc = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_Desc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Description__c', actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');
            
            Map<String, String> actualField_EduInst = actualConfigs[0].fields[2];
            System.Assert.areEqual(2, actualField_EduInst.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), actualField_EduInst.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', actualField_EduInst.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_EduInstName = actualConfigs[1].fields[0];
            System.Assert.areEqual(2, actualField_EduInstName.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), actualField_EduInstName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_EduInstName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');
            
            //translationInfo.translations.data
            Map<String, Object> actualData = (Map<String, Object>) (actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM));
            System.Assert.areEqual(1, actualData.size(), 'Wrong translation data size!');
            System.Assert.isTrue(actualData.containsKey(expectedSun.Id), 'Translated record should be existing!');

            Map<String, Object> actualDataRecord = (Map<String, Object>)actualData.get(expectedSun.Id);
            System.Assert.areEqual(SUN_DESC_ES, actualDataRecord.get('reduivy__Description__c'), 'Wrong translation data record!');
            
		} 

        Test.stopTest();
    }

    /**
     * @description Test as faculty for getting custom record view form data(invalid)
     */
    @IsTest
    static void testForGet_TranslationEnabled_Invalid_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Description__c', 'reduivy__Educational_Institution__c', 'reduivy__Educational_Institution__r.Name'};
        String language = 'en_US';

        Test.startTest();
        setCreateTLMCustomSetting(true);
        
		System.runAs(FACULTY_USER){
            REDU_LightningResponse emptyRecordIdResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue('', objectApiName, fields, language);
            Map<String, Object> emptyRecordIdResponse = (Map<String, Object>) JSON.deserializeUntyped(emptyRecordIdResult.responseData);
            System.Assert.isTrue(emptyRecordIdResponse.isEmpty(), 'Response should be empty! Actual: ' + JSON.serialize(emptyRecordIdResponse));

            REDU_LightningResponse emptyObjectNameResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, '', fields, language);
            Map<String, Object> emptyObjectNameResponse = (Map<String, Object>) JSON.deserializeUntyped(emptyObjectNameResult.responseData);
            System.Assert.isTrue(emptyObjectNameResponse.isEmpty(), 'Response should be empty! Actual: ' + JSON.serialize(emptyObjectNameResponse));

            REDU_LightningResponse emptyFieldsResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, new List<String>(), language);
            Map<String, Object> emptyFieldsResponse = (Map<String, Object>) JSON.deserializeUntyped(emptyFieldsResult.responseData);
            System.Assert.isTrue(emptyFieldsResponse.isEmpty(), 'Response should be empty! Actual: ' + JSON.serialize(emptyFieldsResponse));

            REDU_LightningResponse nullFieldsResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, null, language);
            Map<String, Object> nullFieldsResponse = (Map<String, Object>) JSON.deserializeUntyped(nullFieldsResult.responseData);
            System.Assert.isTrue(nullFieldsResponse.isEmpty(), 'Response should be empty! Actual: ' + JSON.serialize(nullFieldsResponse));
		} 

        Test.stopTest();
    }

    /**
     * @description Test as faculty for getting custom record view form data with double
     */
    @IsTest
    static void testForGet_TranslationEnabled_Double_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Credits__c'};
        String language = 'en_US';

        Test.startTest();
        setCreateTLMCustomSetting(true);
        
		System.runAs(FACULTY_USER){
            REDU_LightningResponse actualResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, fields, language);

            Map<String, Object> actualResponse = (Map<String, Object>) JSON.deserializeUntyped(actualResult.responseData);

            System.Assert.areEqual(3, actualResponse.size(), 'Wrong response size!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Attribute translationInfo should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.RECORDS_PARAM), 'Attribute records should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM), 'Attribute fields should be exist!');

            //fieldsObject
            Map<String, Object> actualFieldsObject = (Map<String, Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM);
            System.Assert.areEqual(2, actualFieldsObject.size(), 'Wrong Fields Object size!');
            System.Assert.isTrue(actualFieldsObject.containsKey('Name'), 'Field "Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Credits__c'), 'Field "reduivy__Credits__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));

            //fieldsObject (Name)
            REDU_DynamicFieldValue_OBJ nameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), nameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', nameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), nameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SRC_SUN, nameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), nameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), nameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getInlineHelpText(), nameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Credits)
            Map<String, Object> creditsFieldValue = (Map<String, Object>) actualFieldsObject.get('reduivy__Credits__c');
            System.Assert.areEqual(SUN_Helper.getApiName(), String.valueOf(creditsFieldValue.get('objectName')), 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Credits__c', String.valueOf(creditsFieldValue.get('fieldName')), 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Credits__c.getLabel(), String.valueOf(creditsFieldValue.get('label')), 'Wrong label!');
            System.Assert.areEqual('10.0000', String.valueOf(creditsFieldValue.get('value')), 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.DOUBLE.name(), String.valueOf(creditsFieldValue.get('displayType')), 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.DOUBLE.name(), String.valueOf(creditsFieldValue.get('soapDisplayType')), 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Credits__c.getInlineHelpText(), String.valueOf(creditsFieldValue.get('helpText')), 'Wrong helpText(helpText)!');
            

            //records
            List<Object> actualRecords = (List<Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            Map<String, Object> actualRecord = (Map<String, Object>) (actualRecords[0]);
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecord.get('Id'), 'Wrong tudy Unit Id!');

            //translationInfo
            Map<String, Object> actualTranslationInfo = (Map<String, Object>) actualResponse.get(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM);
            Object actualTranslationObj = ((List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM))[0];
            Map<String, Object> actualTranslation = (Map<String, Object>) actualTranslationObj;

            //translationInfo.records
            List<Object> actualTranslationInfoRecords = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualTranslationInfoRecords.size(), 'Wrong records size!');
            Map<String, Object> actualTranslationInfoRecord = (Map<String, Object>) actualTranslationInfoRecords[0];
            System.Assert.areEqual(expectedSun.Id, (Id) actualTranslationInfoRecord.get('Id'), 'Wrong record!');

            //translationInfo.translations.languageCode
            System.Assert.areEqual(language, actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');
        
            //translationInfo.translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig>) JSON.deserialize(JSON.serialize(actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM)), List<REDU_TranslationManager.TranslationConfig>.class);
            System.Assert.areEqual(1, actualConfigs.size(), 'Wrong configs size!');

            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(2, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');
            
            //translationInfo.translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_Desc = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_Desc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Credits__c.getLabel(), actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Credits__c', actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');
            
            //translationInfo.translations.data
            Map<String, Object> actualData = (Map<String, Object>) (actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM));
            System.Assert.areEqual(0, actualData.size(), 'Wrong translation data size!');
		} 

        Test.stopTest();
    }

    /**
     * @description Test as student for getting custom record view form data in english
     */
    @IsTest
    static void testForGet_TranslationEnabled_English_AsStudent() {

        User studentUser = testFactory.getStudentUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Description__c', 'reduivy__Educational_Institution__c', 'reduivy__Educational_Institution__r.Name'};
        String language = 'en_US';

        Test.startTest();
        setCreateTLMCustomSetting(true);
        
		System.runAs(studentUser){
            REDU_LightningResponse actualResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, fields, language);

            Map<String, Object> actualResponse = (Map<String, Object>) JSON.deserializeUntyped(actualResult.responseData);

            System.Assert.areEqual(3, actualResponse.size(), 'Wrong response size!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Attribute translationInfo should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.RECORDS_PARAM), 'Attribute records should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM), 'Attribute fields should be exist!');

            //fieldsObject
            Map<String, Object> actualFieldsObject = (Map<String, Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM);
            System.Assert.areEqual(4, actualFieldsObject.size(), 'Wrong Fields Object size!');
            System.Assert.isTrue(actualFieldsObject.containsKey('Name'), 'Field "Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Description__c'), 'Field "reduivy__Description__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__c'), 'Field "reduivy__Educational_Institution__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__r.Name'), 'Field "reduivy__Educational_Institution__r.Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));

            //fieldsObject (Name)
            REDU_DynamicFieldValue_OBJ nameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), nameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', nameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), nameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SRC_SUN, nameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), nameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), nameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getInlineHelpText(), nameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Description)
            REDU_DynamicFieldValue_OBJ descFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Description__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), descFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Description__c', descFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), descFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SUN_DESC_DEF, descFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.TEXTAREA.name(), descFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), descFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getInlineHelpText(), descFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Edu inst)
            REDU_DynamicFieldValue_OBJ eduInstFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), eduInstFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', eduInstFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), eduInstFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__c, eduInstFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.REFERENCE.name(), eduInstFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.ID.name(), eduInstFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getInlineHelpText(), eduInstFieldValue.helpText, 'Wrong helpText(helpText)!');
            
            //fieldsObject (Edu inst.Name)
            REDU_DynamicFieldValue_OBJ eduInstNameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__r.Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(ACC_Helper.getApiName(), eduInstNameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', eduInstNameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), eduInstNameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__r.Name, eduInstNameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), eduInstNameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), eduInstNameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getInlineHelpText(), eduInstNameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //records
            List<Object> actualRecords = (List<Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            Map<String, Object> actualRecord = (Map<String, Object>) (actualRecords[0]);
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecord.get('Id'), 'Wrong tudy Unit Id!');

            //translationInfo
            Map<String, Object> actualTranslationInfo = (Map<String, Object>) actualResponse.get(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM);
            Object actualTranslationObj = ((List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM))[0];
            Map<String, Object> actualTranslation = (Map<String, Object>) actualTranslationObj;

            //translationInfo.records
            List<Object> actualTranslationInfoRecords = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualTranslationInfoRecords.size(), 'Wrong records size!');
            Map<String, Object> actualTranslationInfoRecord = (Map<String, Object>) actualTranslationInfoRecords[0];
            System.Assert.areEqual(expectedSun.Id, (Id) actualTranslationInfoRecord.get('Id'), 'Wrong record!');

            //translationInfo.translations.languageCode
            System.Assert.areEqual(language, actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');
        
            //translationInfo.translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig>) JSON.deserialize(JSON.serialize(actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM)), List<REDU_TranslationManager.TranslationConfig>.class);
            System.Assert.areEqual(2, actualConfigs.size(), 'Wrong configs size!');

            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(3, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');

            System.Assert.areEqual(ACC_Helper.getApiName(), actualConfigs[1].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.areEqual('reduivy__Educational_Institution__r', actualConfigs[1].path, 'Wrong path in configs!');
            System.Assert.areEqual(1, actualConfigs[1].fields.size(), 'Wrong fields size in configs!');

            
            //translationInfo.translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_Desc = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_Desc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Description__c', actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');
            
            Map<String, String> actualField_EduInst = actualConfigs[0].fields[2];
            System.Assert.areEqual(2, actualField_EduInst.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), actualField_EduInst.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', actualField_EduInst.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_EduInstName = actualConfigs[1].fields[0];
            System.Assert.areEqual(2, actualField_EduInstName.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), actualField_EduInstName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_EduInstName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');
            
            //translationInfo.translations.data
            Map<String, Object> actualData = (Map<String, Object>) (actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM));
            System.Assert.areEqual(1, actualData.size(), 'Wrong translation data size!');
            System.Assert.isTrue(actualData.containsKey(expectedSun.Id), 'Translated record should be existing!');

            Map<String, Object> actualDataRecordSun = (Map<String, Object>)actualData.get(expectedSun.Id);
            System.Assert.areEqual(SUN_DESC_EN, actualDataRecordSun.get('reduivy__Description__c'), 'Wrong translation data record!');

		} 

        Test.stopTest();
    }

    /**
     * @description Test as student for getting custom record view form data in english, record value translation not enabled
     */
    @IsTest
    static void testForGet_TranslationDisabled_English_AsStudent() {

        User studentUser = testFactory.getStudentUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Description__c', 'reduivy__Educational_Institution__c', 'reduivy__Educational_Institution__r.Name'};
        String language = 'en_US';

        Test.startTest();
        setCreateTLMCustomSetting(false);
        
		System.runAs(studentUser){
            REDU_LightningResponse actualResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, fields, language);

            Map<String, Object> actualResponse = (Map<String, Object>) JSON.deserializeUntyped(actualResult.responseData);

            System.Assert.areEqual(3, actualResponse.size(), 'Wrong response size!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Attribute translationInfo should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.RECORDS_PARAM), 'Attribute records should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM), 'Attribute fields should be exist!');

            //fieldsObject
            Map<String, Object> actualFieldsObject = (Map<String, Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM);
            System.Assert.areEqual(4, actualFieldsObject.size(), 'Wrong Fields Object size!');
            System.Assert.isTrue(actualFieldsObject.containsKey('Name'), 'Field "Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Description__c'), 'Field "reduivy__Description__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__c'), 'Field "reduivy__Educational_Institution__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__r.Name'), 'Field "reduivy__Educational_Institution__r.Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));

            //fieldsObject (Name)
            REDU_DynamicFieldValue_OBJ nameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), nameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', nameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), nameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SRC_SUN, nameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), nameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), nameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getInlineHelpText(), nameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Description)
            REDU_DynamicFieldValue_OBJ descFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Description__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), descFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Description__c', descFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), descFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SUN_DESC_DEF, descFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.TEXTAREA.name(), descFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), descFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getInlineHelpText(), descFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Edu inst)
            REDU_DynamicFieldValue_OBJ eduInstFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), eduInstFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', eduInstFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), eduInstFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__c, eduInstFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.REFERENCE.name(), eduInstFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.ID.name(), eduInstFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getInlineHelpText(), eduInstFieldValue.helpText, 'Wrong helpText(helpText)!');
            
            //fieldsObject (Edu inst.Name)
            REDU_DynamicFieldValue_OBJ eduInstNameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__r.Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(ACC_Helper.getApiName(), eduInstNameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', eduInstNameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), eduInstNameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__r.Name, eduInstNameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), eduInstNameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), eduInstNameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getInlineHelpText(), eduInstNameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //records
            List<Object> actualRecords = (List<Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            Map<String, Object> actualRecord = (Map<String, Object>) (actualRecords[0]);
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecord.get('Id'), 'Wrong tudy Unit Id!');

            //translationInfo
            Map<String, Object> actualTranslationInfo = (Map<String, Object>) actualResponse.get(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM);
            System.Assert.areEqual(0, actualTranslationInfo.size(), 'Translation Info should be empty! Actual: ' + JSON.serialize(actualTranslationInfo));
		} 

        Test.stopTest();
    }

    /**
     * @description Test as student for getting custom record view form data in english, record value translation not enabled, language empty
     */
    @IsTest
    static void testForGet_TranslationDisabled_Empty_AsStudent() {

        User studentUser = testFactory.getStudentUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Description__c', 'reduivy__Educational_Institution__c', 'reduivy__Educational_Institution__r.Name'};
        String language = '';

        Test.startTest();
        setCreateTLMCustomSetting(false);
        
		System.runAs(studentUser){
            REDU_LightningResponse actualResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, fields, language);

            Map<String, Object> actualResponse = (Map<String, Object>) JSON.deserializeUntyped(actualResult.responseData);

            System.Assert.areEqual(3, actualResponse.size(), 'Wrong response size!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Attribute translationInfo should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.RECORDS_PARAM), 'Attribute records should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM), 'Attribute fields should be exist!');

            //fieldsObject
            Map<String, Object> actualFieldsObject = (Map<String, Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM);
            System.Assert.areEqual(4, actualFieldsObject.size(), 'Wrong Fields Object size!');
            System.Assert.isTrue(actualFieldsObject.containsKey('Name'), 'Field "Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Description__c'), 'Field "reduivy__Description__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__c'), 'Field "reduivy__Educational_Institution__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__r.Name'), 'Field "reduivy__Educational_Institution__r.Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));

            //fieldsObject (Name)
            REDU_DynamicFieldValue_OBJ nameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), nameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', nameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), nameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SRC_SUN, nameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), nameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), nameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getInlineHelpText(), nameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Description)
            REDU_DynamicFieldValue_OBJ descFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Description__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), descFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Description__c', descFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), descFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SUN_DESC_DEF, descFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.TEXTAREA.name(), descFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), descFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getInlineHelpText(), descFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Edu inst)
            REDU_DynamicFieldValue_OBJ eduInstFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), eduInstFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', eduInstFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), eduInstFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__c, eduInstFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.REFERENCE.name(), eduInstFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.ID.name(), eduInstFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getInlineHelpText(), eduInstFieldValue.helpText, 'Wrong helpText(helpText)!');
            
            //fieldsObject (Edu inst.Name)
            REDU_DynamicFieldValue_OBJ eduInstNameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__r.Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(ACC_Helper.getApiName(), eduInstNameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', eduInstNameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), eduInstNameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__r.Name, eduInstNameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), eduInstNameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), eduInstNameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getInlineHelpText(), eduInstNameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //records
            List<Object> actualRecords = (List<Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            Map<String, Object> actualRecord = (Map<String, Object>) (actualRecords[0]);
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecord.get('Id'), 'Wrong tudy Unit Id!');

            //translationInfo
            Map<String, Object> actualTranslationInfo = (Map<String, Object>) actualResponse.get(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM);
            System.Assert.areEqual(0, actualTranslationInfo.size(), 'Translation Info should be empty! Actual: ' + JSON.serialize(actualTranslationInfo));
		} 

        Test.stopTest();
    }


    /**
     * @description Test as student for getting custom record view form data in spanish
     */
    @IsTest
    static void testForGet_TranslationEnabled_Spanish_AsStudent() {

        User studentUser = testFactory.getStudentUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Description__c', 'reduivy__Educational_Institution__c', 'reduivy__Educational_Institution__r.Name'};
        String language = 'es';

        Test.startTest();
        setCreateTLMCustomSetting(true);
        
		System.runAs(studentUser){
            REDU_LightningResponse actualResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, fields, language);

            Map<String, Object> actualResponse = (Map<String, Object>) JSON.deserializeUntyped(actualResult.responseData);

            System.Assert.areEqual(3, actualResponse.size(), 'Wrong response size!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Attribute translationInfo should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.RECORDS_PARAM), 'Attribute records should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM), 'Attribute fields should be exist!');

            //fieldsObject
            Map<String, Object> actualFieldsObject = (Map<String, Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM);
            System.Assert.areEqual(4, actualFieldsObject.size(), 'Wrong Fields Object size!');
            System.Assert.isTrue(actualFieldsObject.containsKey('Name'), 'Field "Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Description__c'), 'Field "reduivy__Description__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__c'), 'Field "reduivy__Educational_Institution__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Educational_Institution__r.Name'), 'Field "reduivy__Educational_Institution__r.Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));

            //fieldsObject (Name)
            REDU_DynamicFieldValue_OBJ nameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), nameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', nameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), nameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SRC_SUN, nameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), nameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), nameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getInlineHelpText(), nameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Description)
            REDU_DynamicFieldValue_OBJ descFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Description__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), descFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Description__c', descFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), descFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SUN_DESC_DEF, descFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.TEXTAREA.name(), descFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), descFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getInlineHelpText(), descFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Edu inst)
            REDU_DynamicFieldValue_OBJ eduInstFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__c')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), eduInstFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', eduInstFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), eduInstFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__c, eduInstFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.REFERENCE.name(), eduInstFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.ID.name(), eduInstFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getInlineHelpText(), eduInstFieldValue.helpText, 'Wrong helpText(helpText)!');
            
            //fieldsObject (Edu inst.Name)
            REDU_DynamicFieldValue_OBJ eduInstNameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('reduivy__Educational_Institution__r.Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(ACC_Helper.getApiName(), eduInstNameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', eduInstNameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), eduInstNameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(expectedSun.reduivy__Educational_Institution__r.Name, eduInstNameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), eduInstNameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), eduInstNameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getInlineHelpText(), eduInstNameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //records
            List<Object> actualRecords = (List<Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            Map<String, Object> actualRecord = (Map<String, Object>) (actualRecords[0]);
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecord.get('Id'), 'Wrong tudy Unit Id!');

            //translationInfo
            Map<String, Object> actualTranslationInfo = (Map<String, Object>) actualResponse.get(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM);
            Object actualTranslationObj = ((List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM))[0];
            Map<String, Object> actualTranslation = (Map<String, Object>) actualTranslationObj;

            //translationInfo.records
            List<Object> actualTranslationInfoRecords = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualTranslationInfoRecords.size(), 'Wrong records size!');
            Map<String, Object> actualTranslationInfoRecord = (Map<String, Object>) actualTranslationInfoRecords[0];
            System.Assert.areEqual(expectedSun.Id, (Id) actualTranslationInfoRecord.get('Id'), 'Wrong record!');

            //translationInfo.translations.languageCode
            System.Assert.areEqual(language, actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');
        
            //translationInfo.translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig>) JSON.deserialize(JSON.serialize(actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM)), List<REDU_TranslationManager.TranslationConfig>.class);
            System.Assert.areEqual(2, actualConfigs.size(), 'Wrong configs size!');

            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(3, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');

            System.Assert.areEqual(ACC_Helper.getApiName(), actualConfigs[1].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.areEqual('reduivy__Educational_Institution__r', actualConfigs[1].path, 'Wrong path in configs!');
            System.Assert.areEqual(1, actualConfigs[1].fields.size(), 'Wrong fields size in configs!');

            
            //translationInfo.translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_Desc = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_Desc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Description__c.getLabel(), actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Description__c', actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');
            
            Map<String, String> actualField_EduInst = actualConfigs[0].fields[2];
            System.Assert.areEqual(2, actualField_EduInst.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), actualField_EduInst.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Educational_Institution__c', actualField_EduInst.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_EduInstName = actualConfigs[1].fields[0];
            System.Assert.areEqual(2, actualField_EduInstName.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.Account.fields.Name.getLabel(), actualField_EduInstName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_EduInstName.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');
            
            //translationInfo.translations.data
            Map<String, Object> actualData = (Map<String, Object>) (actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM));
            System.Assert.areEqual(1, actualData.size(), 'Wrong translation data size!');
            System.Assert.isTrue(actualData.containsKey(expectedSun.Id), 'Translated record should be existing!');

            Map<String, Object> actualDataRecord = (Map<String, Object>)actualData.get(expectedSun.Id);
            System.Assert.areEqual(SUN_DESC_ES, actualDataRecord.get('reduivy__Description__c'), 'Wrong translation data record!');
            
		} 

        Test.stopTest();
    }

    /**
     * @description Test as student for getting custom record view form data(invalid)
     */
    @IsTest
    static void testForGet_TranslationEnabled_Invalid_AsStudent() {

        User studentUser = testFactory.getStudentUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Description__c', 'reduivy__Educational_Institution__c', 'reduivy__Educational_Institution__r.Name'};
        String language = 'en_US';

        Test.startTest();
        setCreateTLMCustomSetting(true);
        
		System.runAs(studentUser){
            REDU_LightningResponse emptyRecordIdResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue('', objectApiName, fields, language);
            Map<String, Object> emptyRecordIdResponse = (Map<String, Object>) JSON.deserializeUntyped(emptyRecordIdResult.responseData);
            System.Assert.isTrue(emptyRecordIdResponse.isEmpty(), 'Response should be empty! Actual: ' + JSON.serialize(emptyRecordIdResponse));

            REDU_LightningResponse emptyObjectNameResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, '', fields, language);
            Map<String, Object> emptyObjectNameResponse = (Map<String, Object>) JSON.deserializeUntyped(emptyObjectNameResult.responseData);
            System.Assert.isTrue(emptyObjectNameResponse.isEmpty(), 'Response should be empty! Actual: ' + JSON.serialize(emptyObjectNameResponse));

            REDU_LightningResponse emptyFieldsResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, new List<String>(), language);
            Map<String, Object> emptyFieldsResponse = (Map<String, Object>) JSON.deserializeUntyped(emptyFieldsResult.responseData);
            System.Assert.isTrue(emptyFieldsResponse.isEmpty(), 'Response should be empty! Actual: ' + JSON.serialize(emptyFieldsResponse));

            REDU_LightningResponse nullFieldsResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, null, language);
            Map<String, Object> nullFieldsResponse = (Map<String, Object>) JSON.deserializeUntyped(nullFieldsResult.responseData);
            System.Assert.isTrue(nullFieldsResponse.isEmpty(), 'Response should be empty! Actual: ' + JSON.serialize(nullFieldsResponse));
		} 

        Test.stopTest();
    }

    
    /**
     * @description Test as student for getting custom record view form data with double
     */
    @IsTest
    static void testForGet_TranslationEnabled_Double_AsStudent() {

        User studentUser = testFactory.getStudentUser();
        
        reduivy__Study_Unit__c expectedSun = queryAndUpdateSun();
        String objectApiName = SUN_Helper.getApiName();
        List<String> fields = new List<String> {'Name', 'reduivy__Credits__c'};
        String language = 'en_US';

        Test.startTest();
        setCreateTLMCustomSetting(true);
        
		System.runAs(studentUser){
            REDU_LightningResponse actualResult = REDU_RecordViewForm_LCTRL.getRecordFieldValue(expectedSun.Id, objectApiName, fields, language);

            Map<String, Object> actualResponse = (Map<String, Object>) JSON.deserializeUntyped(actualResult.responseData);

            System.Assert.areEqual(3, actualResponse.size(), 'Wrong response size!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Attribute translationInfo should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.RECORDS_PARAM), 'Attribute records should be exist!');
            System.Assert.isTrue(actualResponse.containsKey(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM), 'Attribute fields should be exist!');

            //fieldsObject
            Map<String, Object> actualFieldsObject = (Map<String, Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.FIELDS_OBJECT_PARAM);
            System.Assert.areEqual(2, actualFieldsObject.size(), 'Wrong Fields Object size!');
            System.Assert.isTrue(actualFieldsObject.containsKey('Name'), 'Field "Name" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));
            System.Assert.isTrue(actualFieldsObject.containsKey('reduivy__Credits__c'), 'Field "reduivy__Credits__c" should be exist! Existing key: ' + JSON.serialize(actualFieldsObject.keySet()));

            //fieldsObject (Name)
            REDU_DynamicFieldValue_OBJ nameFieldValue = (REDU_DynamicFieldValue_OBJ) JSON.deserialize(JSON.serialize(actualFieldsObject.get('Name')), REDU_DynamicFieldValue_OBJ.class);
            System.Assert.areEqual(SUN_Helper.getApiName(), nameFieldValue.objectName, 'Wrong objectName!');
            System.Assert.areEqual('Name', nameFieldValue.fieldName, 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), nameFieldValue.label, 'Wrong label!');
            System.Assert.areEqual(SRC_SUN, nameFieldValue.value, 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.STRING.name(), nameFieldValue.displayType, 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.STRING.name(), nameFieldValue.soapDisplayType, 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getInlineHelpText(), nameFieldValue.helpText, 'Wrong helpText(helpText)!');

            //fieldsObject (Credits)
            Map<String, Object> creditsFieldValue = (Map<String, Object>) actualFieldsObject.get('reduivy__Credits__c');
            System.Assert.areEqual(SUN_Helper.getApiName(), String.valueOf(creditsFieldValue.get('objectName')), 'Wrong objectName!');
            System.Assert.areEqual('reduivy__Credits__c', String.valueOf(creditsFieldValue.get('fieldName')), 'Wrong fieldName!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Credits__c.getLabel(), String.valueOf(creditsFieldValue.get('label')), 'Wrong label!');
            System.Assert.areEqual('10.0000', String.valueOf(creditsFieldValue.get('value')), 'Wrong value!');
            System.Assert.areEqual(Schema.DisplayType.DOUBLE.name(), String.valueOf(creditsFieldValue.get('displayType')), 'Wrong displayType!');
            System.Assert.areEqual(Schema.SoapType.DOUBLE.name(), String.valueOf(creditsFieldValue.get('soapDisplayType')), 'Wrong soapDisplayType!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Credits__c.getInlineHelpText(), String.valueOf(creditsFieldValue.get('helpText')), 'Wrong helpText(helpText)!');
            

            //records
            List<Object> actualRecords = (List<Object>) actualResponse.get(REDU_RecordViewForm_LCTRL.RECORDS_PARAM);
            System.Assert.areEqual(1, actualRecords.size(), 'Wrong records size!');
            Map<String, Object> actualRecord = (Map<String, Object>) (actualRecords[0]);
            System.Assert.areEqual(expectedSun.Id, (Id) actualRecord.get('Id'), 'Wrong tudy Unit Id!');

            //translationInfo
            Map<String, Object> actualTranslationInfo = (Map<String, Object>) actualResponse.get(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM);
            Object actualTranslationObj = ((List<Object>) actualTranslationInfo.get(REDU_TranslationManager.TRANSLATIONS_PARAM))[0];
            Map<String, Object> actualTranslation = (Map<String, Object>) actualTranslationObj;

            //translationInfo.records
            List<Object> actualTranslationInfoRecords = (List<Object>) actualTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            System.Assert.areEqual(1, actualTranslationInfoRecords.size(), 'Wrong records size!');
            Map<String, Object> actualTranslationInfoRecord = (Map<String, Object>) actualTranslationInfoRecords[0];
            System.Assert.areEqual(expectedSun.Id, (Id) actualTranslationInfoRecord.get('Id'), 'Wrong record!');

            //translationInfo.translations.languageCode
            System.Assert.areEqual(language, actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_LANGUAGECODE_PARAM), 'Wrong language code!');
        
            //translationInfo.translations.configs
            List<REDU_TranslationManager.TranslationConfig> actualConfigs = (List<REDU_TranslationManager.TranslationConfig>) JSON.deserialize(JSON.serialize(actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_PARAM)), List<REDU_TranslationManager.TranslationConfig>.class);
            System.Assert.areEqual(1, actualConfigs.size(), 'Wrong configs size!');

            System.Assert.areEqual(SUN_Helper.getApiName(), actualConfigs[0].sobjectType, 'Wrong sobject name in configs!');
            System.Assert.isTrue(String.isBlank(actualConfigs[0].path), 'Path should be empty in configs! Actual: ' + actualConfigs[0].path);
            System.Assert.areEqual(2, actualConfigs[0].fields.size(), 'Wrong fields size in configs!');
            
            //translationInfo.translations.configs.fields
            Map<String, String> actualField_Name = actualConfigs[0].fields[0];
            System.Assert.areEqual(2, actualField_Name.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('Name', actualField_Name.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');

            Map<String, String> actualField_Desc = actualConfigs[0].fields[1];
            System.Assert.areEqual(2, actualField_Desc.size(), 'Wrong fields attributes size in configs!');
            System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.reduivy__Credits__c.getLabel(), actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM), 'Wrong fields label in configs!');
            System.Assert.areEqual('reduivy__Credits__c', actualField_Desc.get(REDU_TranslationManager.TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM), 'Wrong fields name in configs!');
            
            //translationInfo.translations.data
            Map<String, Object> actualData = (Map<String, Object>) (actualtranslation.get(REDU_TranslationManager.TRANSLATIONS_DATA_PARAM));
            System.Assert.areEqual(0, actualData.size(), 'Wrong translation data size!');
		} 

        Test.stopTest();
    }

    static reduivy__Study_Unit__c queryAndUpdateSun(){
        reduivy__Study_Unit__c sun = [
            SELECT Id, Name, reduivy__Educational_Institution__c, reduivy__Educational_Institution__r.Name
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = :SRC_SUN
            LIMIT 1
        ];

        reduivy__Translation__c tln = new reduivy__Translation__c(
            reduivy__en_Rich__c = SUN_DESC_EN,
            reduivy__es_Rich__c = SUN_DESC_ES,
            reduivy__Default_Rich__c = SUN_DESC_DEF
        );
        insert tln;

        reduivy__Translation_Map__c tlm = new reduivy__Translation_Map__c(
            reduivy__Translation_2__c = tln.Id
        );
        insert tlm;

        sun.reduivy__Translation_Map__c = tlm.Id;
        sun.reduivy__Description__c = SUN_DESC_DEF;
        update sun;

        return sun;
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