/**
 * @author      WDCi (XW)
 * @date        Feb 2025
 * @group       Test
 * @description Test class for TLN_Helper
 * @changehistory
 * ISS-002230 06-02-2025 XW - new class
 */
@IsTest
public inherited sharing class TLN_Helper_TEST {

    private static final List<String> COMMENTS_TEMPLATE = new List<String>{
        '/*inline*/',
        '/* inline with space between */',
        '/* inline with space before*/',
        '/* inline with space after*/ ',
        '/* inline with space around*/ ',
        '/*\n*/',
        '/*\nnew line*/',
        '/*\nnew line\n*/',
        '/*\nnew\nline\n*/',
        '/*\nnew\n line\n*/',
        '/*\nnew \n line\n*/',
        '/*\nnew \n\n line\n*/',
        '\n/*\nnew \n\n line\n*/',
        '\n\n/*\nnew \n\n line\n*/',
        '\n\n/*\nnew \n\n line\n*/\n',
        '\n\n/*\nnew \n\n line\n */\n',
        '\n\n/* \nnew \n\n line\n */\n',
        '\n\n/* \nn\new \n\n line\n */\n'
    };

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
            String sampleRecordCode = SAMPLE_RECORD_CODE_SUN1;
            Account eduInst = testFactory.eduInst;
            reduivy__Study_Grade_Setting__c studyGradeSetting = testFactory.studyGradeSettings.get(SAMPLE_RECORD_CODE_SGS);
            String name = sampleRecordCode;
            String code = sampleRecordCode;
            Decimal credits = 10;
            String fieldOfStudy = 'Business, Management, and Marketing';
            String unitLevel = '100';
            Decimal eftsl = 0.125;
            String reqLogic = null;
            
            String sampleRecordCode2 = SAMPLE_RECORD_CODE_SUN2;
            String name2 = sampleRecordCode2;
            String code2 = sampleRecordCode2;
    
            reduivy__Study_Unit__c studyUnitToInsert1 = REDU_TestData_UTIL.newStudyUnit(
                sampleRecordCode, eduInst.Id, studyGradeSetting.Id, name, 
                code, credits, fieldOfStudy, unitLevel, eftsl, reqLogic
            );

            reduivy__Study_Unit__c studyUnitToInsert2 = REDU_TestData_UTIL.newStudyUnit(
                sampleRecordCode2, eduInst.Id, studyGradeSetting.Id, name2, 
                code2, credits, fieldOfStudy, unitLevel, eftsl, reqLogic
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
        
        System.Assert.areEqual(SObjectType.reduivy__Translation__c.getLabel(), TLN_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Translation__c.getLabelPlural(), TLN_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Translation__c.getName(), TLN_Helper.getApiName());

        Test.stopTest();
        
    }

    /**
     * @description generate translation for new inserted sobject
     */
    @IsTest
    static void testGenerateTranslation() {

        //patch org doesn't allow us to add fields to the object, hence we will only proceed the test if the field exist e.g., major release test
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
        
        Integer counter = 0;
        for (reduivy__Study_Unit__c sun : sunList) {
            Map<String, reduivy__Translation__c> translations = translationsBySobj.get(counter);

            for (REDU_TranslationManager.TranslationMapping tlnMapping : displayFieldList) {
                System.Assert.isTrue(translations.containsKey(tlnMapping.sourceField), 'The field ' + tlnMapping.sourceField + ' is missing from the translation');
                System.Assert.areEqual('reduivy__Study_Unit__c.Name', translations.get(tlnMapping.sourceField).reduivy__For_Field_API_Name__c);
                System.Assert.areEqual(tlnMapping.sourceFieldDescribe.getLabel(), translations.get(tlnMapping.sourceField).reduivy__For_Field__c);

                String defaultReference = String.format(Label.Translation_Map_Default_Name, new List<String>{sun.Name, tlnMapping.sourceFieldDescribe.getLabel()});
                System.Assert.areEqual(defaultReference, translations.get('Name').get('reduivy__Reference__c'), 'Translation reference incorrect!');
                System.Assert.areEqual(sun.Name, translations.get('Name').get('reduivy__Default__c'), 'Translation name incorrect!');
            }

            counter ++;
        }

        Test.stopTest();
    }

    /**
     * @description clone the existing translation
     */ 
    @IsTest
    static void testCloneTranslation() {
        
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
            translationInsertList.addAll(translations.values());
        }

        System.Assert.areEqual(clonedSunList.size(), translationInsertList.size() / formula_targetMap.size());
        
        Integer counter = 0;
        for(reduivy__Study_Unit__c clonedSun : clonedSunList) {
            Map<String, reduivy__Translation__c> translations = translationsBySobj.get(counter);

            for (REDU_TranslationManager.TranslationMapping tlnMapping : displayFieldList) {
                String defaultReference = String.format(Label.Translation_Map_Default_Name, new List<String>{clonedSun.Name, tlnMapping.sourceFieldDescribe.getLabel()});
                
                System.Assert.isTrue(translations.containsKey(tlnMapping.sourceField), 'The field ' + tlnMapping.sourceField + ' is missing from the translation');
                System.Assert.areEqual('reduivy__Study_Unit__c.Name', translations.get(tlnMapping.sourceField).reduivy__For_Field_API_Name__c);
                System.Assert.areEqual(tlnMapping.sourceFieldDescribe.getLabel(), translations.get(tlnMapping.sourceField).reduivy__For_Field__c);

                System.Assert.areEqual(defaultReference, translations.get('Name').get('reduivy__Reference__c'), 'Translation reference incorrect!');
                System.Assert.areEqual(clonedSun.Name, translations.get('Name').get('reduivy__Default__c'), 'Translation name incorrect!');

                System.Assert.areEqual(originalSunList[counter].Name + ' da', translations.get('Name').get('reduivy__da__c'), 'Wrong da value!');
                System.Assert.areEqual(originalSunList[counter].Name + ' fr', translations.get('Name').get('reduivy__fr__c'), 'Wrong fr value!');
                System.Assert.areEqual(originalSunList[counter].Name + ' en', translations.get('Name').get('reduivy__en__c'), 'Wrong en value!');
            }

            counter ++;
        }

        Test.stopTest();
    }

    /**
     * @description test for extract comments from formula
     */
    @IsTest
    static void testExtractCommentsFromFormula() {
        List<String> actualFormulaList = new List<String>{'xxx.xxx.xxx', 'Name', 'IF (boolean__c = \'true\', \'false\', \'true\')'};
        for(String actualFormula : actualFormulaList) {
            List<String> formulaList = new List<String>();
            for(String comment : COMMENTS_TEMPLATE) {
                formulaList.add(actualFormula + comment);
            }

            for(String comment : COMMENTS_TEMPLATE) {
                formulaList.add(comment + actualFormula);
            }

            for(String comment : COMMENTS_TEMPLATE) {
                formulaList.add(comment + actualFormula + comment);
            }
            
            for(Integer i = 0; i < formulaList.size(); i++) {
                String formula = formulaList.get(i);
                List<String> result = REDU_TranslationManager.extractCommentsFromFormula(formula);
                
                System.Assert.areEqual(actualFormula, result.get(0), 'First element return should be ' + actualFormula + '!');
                result.remove(0);
                
                System.Assert.areEqual((i < COMMENTS_TEMPLATE.size() * 2) ? 1 : 2, result.size(), 'Wrong number of comments! Current i: ' + String.valueOf(i));
                
                for(Integer j = 0; j < result.size(); j++) {
                    String expected = COMMENTS_TEMPLATE.get(Math.mod(i, COMMENTS_TEMPLATE.size())).replace('/*', '').replace('*/', '').trim();
                    System.Assert.areEqual(expected, result.get(j), 'Wrong comments!');
                }

            }
        }        
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