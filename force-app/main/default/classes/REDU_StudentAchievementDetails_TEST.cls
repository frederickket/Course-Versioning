/**
 * @author      WDCi (XW)
 * @date        Jan 2026
 * @group       Test
 * @description Test class for REDU_StudentAchievementDetails_LCTRL
 * @changehistory
 * ISS-002633 26-01-2026 XW - new class
 */
@IsTest
public inherited sharing class REDU_StudentAchievementDetails_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String CON_SRC = 'sandydoe@redu.example';
    static final String IAC_SRC = CON_SRC + 'Individual_Achievement';
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
     * @description Test as admin for getIndividualAchievementRecord With iac Id
     */
    @IsTest
    static void testGetIndividualAchievementRecord_WithId_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
         
		System.runAs(ADMIN_USER){

            reduivy__Individual_Achievement__c expectedIac = queryIac();
            REDU_LightningResponse response = REDU_StudentAchievementDetails_LCTRL.getIndividualAchievementRecord(expectedIac.Id, UserInfo.getLanguage());
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);          
            System.Assert.isTrue(responseData.containsKey('individualAchievementRecord'), 'Should contains individualAchievementRecord!');
            Map<String, Object> individualAchievementRecordMap = (Map<String, Object>) responseData.get('individualAchievementRecord');
            System.Assert.areEqual(expectedIac.Id, individualAchievementRecordMap.get('Id'), 'Wrong iac id!');


            if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()) {
                System.Assert.isTrue(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should contains translationInfo if translation is enabled!');
            } else {
                System.Assert.isFalse(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should not contains translationInfo if translation is disabled!');
            }
            
		}

        Test.stopTest();
		
    }

	
    /**
     * @description Test as admin for getIndividualAchievementRecord Without iac Id
     */
    @IsTest
    static void testGetIndividualAchievementRecord_WithoutId_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
         
		System.runAs(ADMIN_USER){

            REDU_LightningResponse response = REDU_StudentAchievementDetails_LCTRL.getIndividualAchievementRecord('', UserInfo.getLanguage());
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);          
            System.Assert.isFalse(responseData.containsKey('individualAchievementRecord'), 'Should contains individualAchievementRecord!');


            if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()) {
                System.Assert.isTrue(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should contains translationInfo if translation is enabled!');
            } else {
                System.Assert.isFalse(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should not contains translationInfo if translation is disabled!');
            }
            
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for getIndividualAchievementRecord invalid iac Id
     */
    @IsTest
    static void testGetIndividualAchievementRecord_InvalidId_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
         
		System.runAs(ADMIN_USER){

            REDU_LightningResponse response = REDU_StudentAchievementDetails_LCTRL.getIndividualAchievementRecord('invalid', UserInfo.getLanguage());
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);          
            System.Assert.isTrue(responseData.containsKey('individualAchievementRecord'), 'Should contains individualAchievementRecord!');
            Map<String, Object> individualAchievementRecordMap = (Map<String, Object>) responseData.get('individualAchievementRecord');
            System.Assert.isNull(individualAchievementRecordMap, 'Iac should be null! Actual: ' + JSON.serialize(individualAchievementRecordMap));

            if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()) {
                System.Assert.isTrue(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should contains translationInfo if translation is enabled!');
            } else {
                System.Assert.isFalse(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should not contains translationInfo if translation is disabled!');
            }
            
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for getIndividualAchievementRecord With iac Id
     */
    @IsTest
    static void testGetIndividualAchievementRecord_WithId_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
         
		System.runAs(FACULTY_USER){

            reduivy__Individual_Achievement__c expectedIac = queryIac();
            REDU_LightningResponse response = REDU_StudentAchievementDetails_LCTRL.getIndividualAchievementRecord(expectedIac.Id, UserInfo.getLanguage());
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);          
            System.Assert.isTrue(responseData.containsKey('individualAchievementRecord'), 'Should contains individualAchievementRecord!');
            Map<String, Object> individualAchievementRecordMap = (Map<String, Object>) responseData.get('individualAchievementRecord');
            System.Assert.areEqual(expectedIac.Id, individualAchievementRecordMap.get('Id'), 'Wrong iac id!');


            if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()) {
                System.Assert.isTrue(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should contains translationInfo if translation is enabled!');
            } else {
                System.Assert.isFalse(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should not contains translationInfo if translation is disabled!');
            }
            
		}

        Test.stopTest();
		
    }

	
    /**
     * @description Test as faculty for getIndividualAchievementRecord Without iac Id
     */
    @IsTest
    static void testGetIndividualAchievementRecord_WithoutId_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
         
		System.runAs(FACULTY_USER){

            REDU_LightningResponse response = REDU_StudentAchievementDetails_LCTRL.getIndividualAchievementRecord('', UserInfo.getLanguage());
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);          
            System.Assert.isFalse(responseData.containsKey('individualAchievementRecord'), 'Should contains individualAchievementRecord!');


            if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()) {
                System.Assert.isTrue(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should contains translationInfo if translation is enabled!');
            } else {
                System.Assert.isFalse(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should not contains translationInfo if translation is disabled!');
            }
            
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for getIndividualAchievementRecord invalid iac Id
     */
    @IsTest
    static void testGetIndividualAchievementRecord_InvalidId_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
         
		System.runAs(FACULTY_USER){

            REDU_LightningResponse response = REDU_StudentAchievementDetails_LCTRL.getIndividualAchievementRecord('invalid', UserInfo.getLanguage());
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);          
            System.Assert.isTrue(responseData.containsKey('individualAchievementRecord'), 'Should contains individualAchievementRecord!');
            Map<String, Object> individualAchievementRecordMap = (Map<String, Object>) responseData.get('individualAchievementRecord');
            System.Assert.isNull(individualAchievementRecordMap, 'Iac should be null! Actual: ' + JSON.serialize(individualAchievementRecordMap));

            if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()) {
                System.Assert.isTrue(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should contains translationInfo if translation is enabled!');
            } else {
                System.Assert.isFalse(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should not contains translationInfo if translation is disabled!');
            }
            
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as student for getIndividualAchievementRecord With iac Id
     */
    @IsTest
    static void testGetIndividualAchievementRecord_WithId_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
         
		System.runAs(studentUser){

            reduivy__Individual_Achievement__c expectedIac = queryIac();
            REDU_LightningResponse response = REDU_StudentAchievementDetails_LCTRL.getIndividualAchievementRecord(expectedIac.Id, UserInfo.getLanguage());
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);          
            System.Assert.isTrue(responseData.containsKey('individualAchievementRecord'), 'Should contains individualAchievementRecord!');
            Map<String, Object> individualAchievementRecordMap = (Map<String, Object>) responseData.get('individualAchievementRecord');
            System.Assert.areEqual(expectedIac.Id, individualAchievementRecordMap.get('Id'), 'Wrong iac id!');


            if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()) {
                System.Assert.isTrue(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should contains translationInfo if translation is enabled!');
            } else {
                System.Assert.isFalse(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should not contains translationInfo if translation is disabled!');
            }
            
		}

        Test.stopTest();
		
    }

	
    /**
     * @description Test as student for getIndividualAchievementRecord Without iac Id
     */
    @IsTest
    static void testGetIndividualAchievementRecord_WithoutId_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
         
		System.runAs(studentUser){

            REDU_LightningResponse response = REDU_StudentAchievementDetails_LCTRL.getIndividualAchievementRecord('', UserInfo.getLanguage());
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);          
            System.Assert.isFalse(responseData.containsKey('individualAchievementRecord'), 'Should contains individualAchievementRecord!');


            if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()) {
                System.Assert.isTrue(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should contains translationInfo if translation is enabled!');
            } else {
                System.Assert.isFalse(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should not contains translationInfo if translation is disabled!');
            }
            
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as student for getIndividualAchievementRecord invalid iac Id
     */
    @IsTest
    static void testGetIndividualAchievementRecord_InvalidId_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
         
		System.runAs(studentUser){

            REDU_LightningResponse response = REDU_StudentAchievementDetails_LCTRL.getIndividualAchievementRecord('invalid', UserInfo.getLanguage());
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);          
            System.Assert.isTrue(responseData.containsKey('individualAchievementRecord'), 'Should contains individualAchievementRecord!');
            Map<String, Object> individualAchievementRecordMap = (Map<String, Object>) responseData.get('individualAchievementRecord');
            System.Assert.isNull(individualAchievementRecordMap, 'Iac should be null! Actual: ' + JSON.serialize(individualAchievementRecordMap));

            if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()) {
                System.Assert.isTrue(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should contains translationInfo if translation is enabled!');
            } else {
                System.Assert.isFalse(responseData.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should not contains translationInfo if translation is disabled!');
            }
            
		}

        Test.stopTest();
		
    }

    static reduivy__Individual_Achievement__c queryIac(){
        return [
            SELECT Id, reduivy__Verification_Status__c, reduivy__Submission_Date__c
            FROM reduivy__Individual_Achievement__c 
            WHERE reduivy__Sample_Record_Code__c = :IAC_SRC
        ];
    }
}