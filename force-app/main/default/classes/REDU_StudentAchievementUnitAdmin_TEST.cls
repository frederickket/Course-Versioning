/**
 * @author      WDCi (XW)
 * @date        Jan 2026
 * @group       Test
 * @description Test class for REDU_StudentAchievementUnitAdmin_LCTRL
 * @changehistory
 * ISS-002633 26-01-2026 XW - new class
 */
@IsTest
public inherited sharing class REDU_StudentAchievementUnitAdmin_TEST {

    static final String ARU_SRC = 'ARU_Introduction_to_Business_Studies';
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

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
        	
            testFactory.initMasterData(ARU_Helper.getApiName());
            testFactory.initStudentData(IAC_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for getting agreement Recognition unit with id
     */
    @IsTest
    static void testForGetAgreementRecognitionUnit_WithId_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Agreement_Recognition_Unit__c aru = queryAru();

        

		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudentAchievementUnitAdmin_LCTRL.getAgreementRecognitionUnit(aru.Id, UserInfo.getLanguage());
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey(REDU_TranslationManager.RECORDS_PARAM), 'Should contains records!');
            if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()) {
                System.Assert.isTrue(responseDataJson.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should contains translationInfo!');
            }
            else {
                System.Assert.isFalse(responseDataJson.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should NOT contains translationInfo!');
            }

            List<reduivy__Agreement_Recognition_Unit__c> actualAruList = (List<reduivy__Agreement_Recognition_Unit__c>) JSON.deserialize(JSON.serialize(responseDataJson.get(REDU_TranslationManager.RECORDS_PARAM)), List<reduivy__Agreement_Recognition_Unit__c>.class); 
            System.Assert.areEqual(1, actualAruList.size(), 'Wrong aru list size!');
            
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for getting agreement Recognition unit without id
     */
    @IsTest
    static void testForGetAgreementRecognitionUnit_WithoutId_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        

		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudentAchievementUnitAdmin_LCTRL.getAgreementRecognitionUnit(null, UserInfo.getLanguage());
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.isEmpty(), 'Should be empty!');   
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for getting agreement Recognition unit without language
     */
    @IsTest
    static void testForGetAgreementRecognitionUnit_WithoutLanguage_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Agreement_Recognition_Unit__c aru = queryAru();

		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudentAchievementUnitAdmin_LCTRL.getAgreementRecognitionUnit(aru.Id, null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey(REDU_TranslationManager.RECORDS_PARAM), 'Should contains records!');
            if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()) {
                System.Assert.isTrue(responseDataJson.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should contains translationInfo!');
            }
            else {
                System.Assert.isFalse(responseDataJson.containsKey(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM), 'Should NOT contains translationInfo!');
            }

            List<reduivy__Agreement_Recognition_Unit__c> actualAruList = (List<reduivy__Agreement_Recognition_Unit__c>) JSON.deserialize(JSON.serialize(responseDataJson.get(REDU_TranslationManager.RECORDS_PARAM)), List<reduivy__Agreement_Recognition_Unit__c>.class); 
            System.Assert.areEqual(1, actualAruList.size(), 'Wrong aru list size!');
            
		}

        Test.stopTest();
		
    }

    static reduivy__Agreement_Recognition_Unit__c queryAru() {
        return [
            SELECT Id
            FROM reduivy__Agreement_Recognition_Unit__c
            WHERE reduivy__Sample_Record_Code__c = :ARU_SRC
            LIMIT 1
        ];
    }
	
}