/**
 * @author      WDCi (XW)
 * @date        Feb 2025
 * @group       Test
 * @description Test class for TLM_Helper
 * @changehistory
 * ISS-002230 06-02-2025 XW - new class
 */
@IsTest
public inherited sharing class TLM_Helper_TEST {

    static String SAMPLE_RECORD_CODE_SUN1 = 'BUS101';
    static String SAMPLE_RECORD_CODE_SUN2 = 'BUS102';
    static String CLONE_POSTFIX = '_clone';
    static String SAMPLE_RECORD_CODE_SGS = 'PERCENTAGE_SCORE';
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
        // Create settings
        testFactory.setupDefaultSettings();
        setCreateTLMCustomSetting(true);
        
        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();
        	
            testFactory.initMasterData(ACC_Helper.getApiName());

            //Study Grade Setting
            testFactory.studyGradeSettings.put('PERCENTAGE_SCORE', REDU_TestData_UTIL.newStudyGradeSetting('PERCENTAGE_SCORE', testFactory.eduInst.Id, 'Percentage/Score', SGS_Helper.GRADING_SETTING_TYPE_PERCENTAGE_LETTER));
            testFactory.studyGradeSettings.put('PASS_FAIL', REDU_TestData_UTIL.newStudyGradeSetting('PASS_FAIL', testFactory.eduInst.Id, 'Pass/Fail', SGS_Helper.GRADING_SETTING_TYPE_PASSFAIL));

            insert testFactory.studyGradeSettings.values();

            //create study unit
            Account eduInst = testFactory.eduInst;
            reduivy__Study_Grade_Setting__c studyGradeSetting = testFactory.studyGradeSettings.get(SAMPLE_RECORD_CODE_SGS);

            Decimal credits = 10;
            String fieldOfStudy = 'Business, Management, and Marketing';
            String unitLevel = '100';
            Decimal eftsl = 0.125;
            String reqLogic = null;
                
            reduivy__Study_Unit__c studyUnitToInsert1 = REDU_TestData_UTIL.newStudyUnit(
                SAMPLE_RECORD_CODE_SUN1, eduInst.Id, studyGradeSetting.Id, SAMPLE_RECORD_CODE_SUN1, 
                SAMPLE_RECORD_CODE_SUN1, credits, fieldOfStudy, unitLevel, eftsl, reqLogic
            );

            reduivy__Study_Unit__c studyUnitToInsert2 = REDU_TestData_UTIL.newStudyUnit(
                SAMPLE_RECORD_CODE_SUN2, eduInst.Id, studyGradeSetting.Id, SAMPLE_RECORD_CODE_SUN2, 
                SAMPLE_RECORD_CODE_SUN2, credits, fieldOfStudy, unitLevel, eftsl, reqLogic
            );
    
            List<reduivy__Study_Unit__c> studyUnitBeforeList =new List<reduivy__Study_Unit__c> {
                studyUnitToInsert1, studyUnitToInsert2
            };

            insert studyUnitBeforeList;

            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(USR_Helper.getApiName(), true);
            
            Test.stopTest();
		}
    }

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Translation_Map__c.getLabel(), TLM_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Translation_Map__c.getLabelPlural(), TLM_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Translation_Map__c.getName(), TLM_Helper.getApiName());

        Test.stopTest();
        
    }

    /**
     * @description generate translation map 
     */
    @IsTest
    static void testGenerateTranslationMap() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }

        Test.startTest();
        
        List<reduivy__Study_Unit__c> sunList = [SELECT Id, Name
        FROM reduivy__Study_Unit__c 
        WHERE reduivy__Sample_Record_Code__c 
        IN (:SAMPLE_RECORD_CODE_SUN1, :SAMPLE_RECORD_CODE_SUN2)];

        Map<String, Object> translationInfo = REDU_TranslationManager.getTranslationInfoForSObject(SObjectType.reduivy__Study_Unit__c);
        List<REDU_TranslationManager.TranslationMapping> displayFieldList = (List<REDU_TranslationManager.TranslationMapping>) translationInfo.get(REDU_TranslationManager.OBJ_TRANSLATION_FORMULA_FIELDS);
        Map<String, String> formula_targetMap = (Map<String, String>) translationInfo.get(REDU_TranslationManager.TRANSLATION_FORMULA_FIELD_TO_SOURCE_FIELD);

        List<Map<String, reduivy__Translation__c>> translationsBySobj = TLN_Helper.generateTranslationRecords(sunList, displayFieldList, formula_targetMap, null, null);
        List<reduivy__Translation__c> translationInsertList = new List<reduivy__Translation__c>();
        for (Map<String, reduivy__Translation__c> translations : translationsBySobj) {

            for (REDU_TranslationManager.TranslationMapping tlnMapping : displayFieldList) {
                System.Assert.isTrue(translations.containsKey(tlnMapping.sourceField), 'The field ' + tlnMapping.sourceField + ' is missing from the translation');
                System.Assert.areEqual('reduivy__Study_Unit__c.Name', translations.get(tlnMapping.sourceField).reduivy__For_Field_API_Name__c);
                System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), translations.get(tlnMapping.sourceField).reduivy__For_Field__c);
            }

            translationInsertList.addAll(translations.values());
        }

        insert translationInsertList;
        
        for(reduivy__Translation__c tln : translationInsertList) {
            System.Assert.isNotNull(tln.Id, 'Translation should be inserted!');
            System.Assert.isTrue(String.isBlank(tln.reduivy__Clone_From_Id__c), 'The clone from id should be blank.');
        }

        Map<String, String> formulaField_targetFieldToTranslateMap = new Map<String, String>{
            'reduivy__Translation_1__c' => 'Name'
        };

        List<reduivy__Translation_Map__c> tlmList = TLM_Helper.generateTranslationMapRecords(sunList, translationsBySobj, formulaField_targetFieldToTranslateMap, null);
        
        System.Assert.isFalse(tlmList.isEmpty(), 'The should be translation map records.');
        System.Assert.areEqual(sunList.size(), tlmList.size());

        for(Integer i = 0; i < sunList.size(); i++){
            String defaultTlmReference = String.format(Label.Translation_Map_Default_Name, new List<String>{String.valueOf(sunList.get(i).get('Name')), TLM_Helper.getObjectLabel()});
            System.Assert.areEqual(defaultTlmReference, tlmList.get(i).get('reduivy__Reference__c'), 'Incorrect translation map reference!');
            System.Assert.isNotNull(tlmList.get(i).reduivy__Translation_1__c);

            Map<String, reduivy__Translation__c> translations = translationsBySobj.get(i);

            for (String tlnLookupFieldName : formulaField_targetFieldToTranslateMap.keySet()) {
                String targetField = formulaField_targetFieldToTranslateMap.get(tlnLookupFieldName);

                System.Assert.areEqual(translations.get(targetField).Id, Id.valueOf(String.valueOf(tlmList.get(i).get(tlnLookupFieldName))));
            }
            
        }

        

        Test.stopTest();
    }

    /**
     * @description generate translation map 
     */
    @IsTest
    static void testCloneTranslationMap() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }

        Test.startTest();
        
        List<reduivy__Study_Unit__c> originalSunList = [SELECT Id, Name,
            reduivy__Translation_Map__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Id,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Name,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__da__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__fr__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__en__c
            FROM reduivy__Study_Unit__c 
            WHERE reduivy__Sample_Record_Code__c 
            IN (:SAMPLE_RECORD_CODE_SUN1, :SAMPLE_RECORD_CODE_SUN2)
        ];
        
        List<reduivy__Study_Unit__c> clonedSunList = new List<reduivy__Study_Unit__c>();
        Map<String, reduivy__Translation__c> sourceRecordsTranslations = new Map<String, reduivy__Translation__c>();
        Map<Id, reduivy__Translation_Map__c> sourceRecordsTranslationMaps = new Map<Id, reduivy__Translation_Map__c>();
        
        for(reduivy__Study_Unit__c oriSun : originalSunList) {
            reduivy__Study_Unit__c clonedSun = oriSun.clone(false, true, false, false);
            clonedSun.Name = oriSun.Name + CLONE_POSTFIX;
            clonedSunList.add(clonedSun);

            reduivy__Translation__c sourceTranslation = new reduivy__Translation__c(Id = oriSun.reduivy__Translation_Map__r.reduivy__Translation_1__c);
            sourceTranslation.reduivy__da__c = oriSun.Name + ' da';
            sourceTranslation.reduivy__fr__c = oriSun.Name + ' fr';
            sourceTranslation.reduivy__en__c = oriSun.Name + ' en';
            sourceRecordsTranslations.put(oriSun.Id + '_' + 'Name', sourceTranslation);

            reduivy__Translation_Map__c translationMap = oriSun.reduivy__Translation_Map__r;
            sourceRecordsTranslationMaps.put(oriSun.Id, translationMap);
        }

        Map<String, Object> translationInfo = REDU_TranslationManager.getTranslationInfoForSObject(SObjectType.reduivy__Study_Unit__c);
        List<REDU_TranslationManager.TranslationMapping> displayFieldList = (List<REDU_TranslationManager.TranslationMapping>) translationInfo.get(REDU_TranslationManager.OBJ_TRANSLATION_FORMULA_FIELDS);
        Map<String, String> formula_targetMap = (Map<String, String>) translationInfo.get(REDU_TranslationManager.TRANSLATION_FORMULA_FIELD_TO_SOURCE_FIELD);

        List<Map<String, reduivy__Translation__c>> translationsBySobj = TLN_Helper.generateTranslationRecords(clonedSunList, displayFieldList, formula_targetMap, sourceRecordsTranslations, null);
        List<reduivy__Translation__c> translationInsertList = new List<reduivy__Translation__c>();
        for (Map<String, reduivy__Translation__c> translations : translationsBySobj) {

            for (REDU_TranslationManager.TranslationMapping tlnMapping : displayFieldList) {
                System.Assert.isTrue(translations.containsKey(tlnMapping.sourceField), 'The field ' + tlnMapping.sourceField + ' is missing from the translation');
                System.Assert.areEqual('reduivy__Study_Unit__c.Name', translations.get(tlnMapping.sourceField).reduivy__For_Field_API_Name__c);
                System.Assert.areEqual(SObjectType.reduivy__Study_Unit__c.fields.Name.getLabel(), translations.get(tlnMapping.sourceField).reduivy__For_Field__c);
            }

            translationInsertList.addAll(translations.values());
        }

        insert translationInsertList;

        for(reduivy__Translation__c tln : translationInsertList) {
            System.Assert.isNotNull(tln.Id, 'Translation should be inserted!');
            System.Assert.isTrue(String.isNotBlank(tln.reduivy__Clone_From_Id__c), 'The clone from id should not be blank.');
        }

        Map<String, String> formulaField_targetFieldToTranslateMap = new Map<String, String>{
            'reduivy__Translation_1__c' => 'Name'
        };

        List<reduivy__Translation_Map__c> tlmList = TLM_Helper.generateTranslationMapRecords(clonedSunList, translationsBySobj, formulaField_targetFieldToTranslateMap, sourceRecordsTranslationMaps);

        System.Assert.isFalse(tlmList.isEmpty(), 'The should be translation map records.');
        System.Assert.areEqual(clonedSunList.size(), tlmList.size());

        for(Integer i = 0; i < clonedSunList.size(); i++){
            String defaultTlmReference = String.format(Label.Translation_Map_Default_Name, new List<String>{String.valueOf(clonedSunList.get(i).get('Name')), TLM_Helper.getObjectLabel()});
            System.Assert.areEqual(defaultTlmReference, tlmList.get(i).get('reduivy__Reference__c'), 'Incorrect translation map reference!');
            System.Assert.isNotNull(tlmList.get(i).reduivy__Translation_1__c);

            System.Assert.areNotEqual(clonedSunList.get(i).reduivy__Translation_Map__c, tlmList.get(i).Id);
            System.Assert.areEqual(clonedSunList.get(i).reduivy__Translation_Map__c, tlmList.get(i).reduivy__Clone_From_Id__c);

            Map<String, reduivy__Translation__c> translations = translationsBySobj.get(i);

            for (String tlnLookupFieldName : formulaField_targetFieldToTranslateMap.keySet()) {
                String targetField = formulaField_targetFieldToTranslateMap.get(tlnLookupFieldName);

                System.Assert.areEqual(translations.get(targetField).Id, Id.valueOf(String.valueOf(tlmList.get(i).get(tlnLookupFieldName))));
            }
            
        }

        Test.stopTest();
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