/**
 * @author      WDCi (XW)
 * @date        Mar 2025
 * @group       Test
 * @description Test class for REDU_Translation_LCTRL and REDU_TranslationManager
 * @changehistory
 * ISS-002330 24-03-2025 XW - new class
 * ISS-002495 29-09-2025 XW - added test cases for translation info
 */
@IsTest
public inherited sharing class REDU_Translation_TEST {

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
     * @description set the record value translation setting to the value given
     */
    private static void setCreateTLMCustomSetting(Boolean value) {
        if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled() != value) {
            reduivy__RIO_Education_Ivy_Settings__c setting = REDU_AppSetting_UTIL.getOrgDefaultSetting();
            setting.reduivy__Enable_Record_Value_Translation__c = value;
            update setting;
        }
    }

    /**
     * @description Test as admin for 1 object with translation name
     */
    @IsTest
    static void testFor1ObjectWithTranslationNameAsAdmin() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        setCreateTLMCustomSetting(true);

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix(new List<String>{'SUN'});
            Map<String,String> responseData = (Map<String,String>) JSON.deserialize(response.responseData, Map<String,String>.class);

            System.Assert.areEqual(1, responseData.size(), 'Wrong translation map size!');
            System.Assert.areEqual('reduivy__Translated_Name__c', (String) responseData.get('SUN'), 'Wrong translation name field!');
            
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for 1 object with translation name
     */
    @IsTest
    static void testFor1ObjectWithoutRecordValueTranslationEnabledAsAdmin() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix(new List<String>{'SUN'});
            Map<String,String> responseData = (Map<String,String>) JSON.deserialize(response.responseData, Map<String,String>.class);

            System.Assert.areEqual(1, responseData.size(), 'Wrong translation map size!');
            System.Assert.areEqual('Name', (String) responseData.get('SUN'), 'Wrong translation name field!');
            
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for 2 object with translation name
     */
    @IsTest
    static void testFor2ObjectWithTranslationNameAsAdmin() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        setCreateTLMCustomSetting(true);

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix(new List<String>{'SUN', 'SOF'});
            Map<String,String> responseData = (Map<String,String>) JSON.deserialize(response.responseData, Map<String,String>.class);

            System.Assert.areEqual(2, responseData.size(), 'Wrong translation map size!');
            System.Assert.areEqual('reduivy__Translated_Name__c', (String) responseData.get('SUN'), 'Wrong translation name field!');
            System.Assert.areEqual('reduivy__Translated_Name__c', (String) responseData.get('SOF'), 'Wrong translation name field!');
            
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for 1 object without translation name
     */
    @IsTest
    static void testFor1ObjectWithoutTranslationNameAsAdmin() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        setCreateTLMCustomSetting(true);

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix(new List<String>{'IPE'});
            Map<String,String> responseData = (Map<String,String>) JSON.deserialize(response.responseData, Map<String,String>.class);

            System.Assert.areEqual(1, responseData.size(), 'Wrong translation map size!');
            System.Assert.areEqual('Name', (String) responseData.get('IPE'), 'Wrong translation name field!');
            
		}

        Test.stopTest();
		
    }
    
    /**
     * @description Test as admin for invalid object 
     */
    @IsTest
    static void testForInvalidObjectAsAdmin() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        setCreateTLMCustomSetting(true);

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix(new List<String>{'???'});
            Map<String,String> responseData = (Map<String,String>) JSON.deserialize(response.responseData, Map<String,String>.class);

            System.Assert.isTrue(responseData.isEmpty(), 'Map should be empty!');
		}

        Test.stopTest();
		
    }
    
    /**
     * @description Test as admin for empty class list
     */
    @IsTest
    static void testForEmptyClassListAsAdmin() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        setCreateTLMCustomSetting(true);

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix(new List<String>{});
            Map<String,String> responseData = (Map<String,String>) JSON.deserialize(response.responseData, Map<String,String>.class);

            System.Assert.isTrue(responseData.isEmpty(), 'Map should be empty!');
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for helper name
     */
    @IsTest
    static void testForHelperNameAsAdmin() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        setCreateTLMCustomSetting(true);

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix(new List<String>{'SUN_Helper'});
            Map<String,String> responseData = (Map<String,String>) JSON.deserialize(response.responseData, Map<String,String>.class);

            System.Assert.areEqual(1, responseData.size(), 'Wrong translation map size!');
            System.Assert.areEqual('reduivy__Translated_Name__c', (String) responseData.get('SUN_Helper'), 'Wrong translation name field!');
            
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as student for 1 object with translation name
     */
	@IsTest
    static void testFor1ObjectWithTranslationNameAsStudent() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        //get the student record if you need one for testing using student.ContactId
		User studentUser = testFactory.getStudentUser();
        setCreateTLMCustomSetting(true);

        Test.startTest();
        
		System.runAs(studentUser){
            REDU_LightningResponse response = REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix(new List<String>{'SUN'});
            Map<String,String> responseData = (Map<String,String>) JSON.deserialize(response.responseData, Map<String,String>.class);

            System.Assert.areEqual(1, responseData.size(), 'Wrong translation map size!');
            System.Assert.areEqual('reduivy__Translated_Name__c', (String) responseData.get('SUN'), 'Wrong translation name field!');
            
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as student for 1 object with translation name
     */
	@IsTest
    static void testFor1ObjectWithoutRecordValueTranslationEnabledAsStudent() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        //get the student record if you need one for testing using student.ContactId
		User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
		System.runAs(studentUser){
            REDU_LightningResponse response = REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix(new List<String>{'SUN'});
            Map<String,String> responseData = (Map<String,String>) JSON.deserialize(response.responseData, Map<String,String>.class);

            System.Assert.areEqual(1, responseData.size(), 'Wrong translation map size!');
            System.Assert.areEqual('Name', (String) responseData.get('SUN'), 'Wrong translation name field!');
            
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for 1 object with translation name
     */
	@IsTest
    static void testFor1ObjectWithTranslationNameAsFaculty() {
		
        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        //get the faculty with allocation for testing, if you don't need the one with allocation, you can simplify the code to use testFactory.getReduFacultyUser()
        User FACULTY_USER = testFactory.getAllocatedFacultyUser();
        if (FACULTY_USER == null) {
            FACULTY_USER = testFactory.getReduFacultyUser();
        }

        //get the student record if you need one for testing using student.ContactId
        User studentUser = testFactory.getStudentUser();
        setCreateTLMCustomSetting(true);

        Test.startTest();

        // TO DO: implement unit test run as faculty
		System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix(new List<String>{'SUN'});
            Map<String,String> responseData = (Map<String,String>) JSON.deserialize(response.responseData, Map<String,String>.class);

            System.Assert.areEqual(1, responseData.size(), 'Wrong translation map size!');
            System.Assert.areEqual('reduivy__Translated_Name__c', (String) responseData.get('SUN'), 'Wrong translation name field!');
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for 1 object with translation name
     */
	@IsTest
    static void testFor1ObjectWithoutRecordValueTranslationEnabledAsFaculty() {
		
        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        //get the faculty with allocation for testing, if you don't need the one with allocation, you can simplify the code to use testFactory.getReduFacultyUser()
        User FACULTY_USER = testFactory.getAllocatedFacultyUser();
        if (FACULTY_USER == null) {
            FACULTY_USER = testFactory.getReduFacultyUser();
        }

        //get the student record if you need one for testing using student.ContactId
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        // TO DO: implement unit test run as faculty
		System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix(new List<String>{'SUN'});
            Map<String,String> responseData = (Map<String,String>) JSON.deserialize(response.responseData, Map<String,String>.class);

            System.Assert.areEqual(1, responseData.size(), 'Wrong translation map size!');
            System.Assert.areEqual('Name', (String) responseData.get('SUN'), 'Wrong translation name field!');
		}

        Test.stopTest();
		
    }
}