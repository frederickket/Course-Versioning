/**
 * @author      WDCi ()
 * @date        Dec 2025
 * @group       Test
 * @description Test class for 
 * @changehistory
 * ISS-002633 28-01-2026 XW - new class
 */
@IsTest
public inherited sharing class REDU_CustomLookupField_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String EDU_INST_SRC = 'RIOUNI';
    static final String EDU_INST_NAME = 'RIO University';
    static final String EX_EDU_INST_SRC = 'EXTUNIT';
    static final String EX_EDU_INST_NAME = 'Partner University';
    static final String NEW_EDU_INST_NAME_PREFIX = 'New Edu Inst ';

    static final String INVALID_SOBJECT_PROVIDED_ERROR_MSG = 'Invalid sobject provided';

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
        	
            //please adjust the data according to your needs
            testFactory.initMasterData(SUN_Helper.getApiName());
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(USR_Helper.getApiName(), true);

            //insert some edu inst
            List<Account> eduInstList = new List<Account>();
            for(Integer i = 1; i <= 10; i++) {
                String newEduInstName = NEW_EDU_INST_NAME_PREFIX + i;
                eduInstList.add(
                    REDU_TestData_UTIL.newEducationalInstitution(newEduInstName, newEduInstName, newEduInstName)
                );
            }
            
            insert eduInstList;
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for basic searching
     */
    @IsTest
    static void testGetRecords_Basic_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        Map<Id, reduivy__Study_Grade_Setting__c> expectedSgsMap = new Map<Id, reduivy__Study_Grade_Setting__c>(querySgsList());
        String expectedObjectIconName = REDU_Metadata_UTIL.getObjectIcon(SGS_Helper.getApiName());
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getRecords(SGS_Helper.getApiName(), new List<String> {'Name'}, 'Name;Id', null, null, null, null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('sobjList'), 'Attribute sobjList should exists! Raw JSON: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('objectIconName'), 'Attribute objectIconName should exists! Raw JSON: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('translationInfo'), 'Attribute translationInfo should exists! Raw JSON: ' + JSON.serialize(responseDataJson));

            List<reduivy__Study_Grade_Setting__c> sgsList = (List<reduivy__Study_Grade_Setting__c>) JSON.deserialize(JSON.serialize(responseDataJson.get('sobjList')), List<reduivy__Study_Grade_Setting__c>.class);

            for(reduivy__Study_Grade_Setting__c actualSgs : sgsList) {
                System.Assert.isTrue(expectedSgsMap.keySet().contains(actualSgs.Id), 'Sgs should exists!');
            }

            String actualObjectIconName = (String) responseDataJson.get('objectIconName');
            System.Assert.areEqual(expectedObjectIconName, actualObjectIconName, 'Wrong Sgs icon!');

		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for custom filter
     */
    @IsTest
    static void testGetRecords_CustomFilter_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        String expectedObjectIconName = REDU_Metadata_UTIL.getObjectIcon(Acc_Helper.getApiName());

        
		System.runAs(ADMIN_USER){
            Map<String, Object> customBindMap = new Map<String, Object>{ 'exEduInstRecordTypeId' => ACC_Helper.getExternalEducationalInstitutionRecordTypeId() };
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getRecords(ACC_Helper.getApiName(), new List<String> {'Name'}, 'Name;Id', null, 'RecordtypeId = :exEduInstRecordTypeId', customBindMap, null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('sobjList'), 'Attribute sobjList should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('objectIconName'), 'Attribute objectIconName should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('translationInfo'), 'Attribute translationInfo should exists!');

            List<Account> accList = (List<Account>) JSON.deserialize(JSON.serialize(responseDataJson.get('sobjList')), List<Account>.class);
            System.Assert.areEqual(1, accList.size(), 'Should be only 1 ex edu inst!');
            for(Account actualExEduInst : accList) {
                System.Assert.isTrue(actualExEduInst.Name == EX_EDU_INST_NAME, 'Wrong ex edu inst name! Actual: ' + actualExEduInst.Name);
            }

            String actualObjectIconName = (String) responseDataJson.get('objectIconName');
            System.Assert.areEqual(expectedObjectIconName, actualObjectIconName, 'Wrong ex edu inst icon!');

		}

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for search key
     */
    @IsTest
    static void testGetRecords_SearchKey_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        String expectedObjectIconName = REDU_Metadata_UTIL.getObjectIcon(Acc_Helper.getApiName());

        
		System.runAs(ADMIN_USER){
            Map<String, Object> customBindMap = new Map<String, Object>{ 'eduInstRecordTypeId' => ACC_Helper.getEducationalInstitutionRecordTypeId() };
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getRecords(ACC_Helper.getApiName(), new List<String> {'Name'}, 'Name;Id', '1', 'RecordtypeId = :eduInstRecordTypeId', customBindMap, null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('sobjList'), 'Attribute sobjList should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('objectIconName'), 'Attribute objectIconName should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('translationInfo'), 'Attribute translationInfo should exists!');

            List<Account> accList = (List<Account>) JSON.deserialize(JSON.serialize(responseDataJson.get('sobjList')), List<Account>.class);
            System.Assert.areEqual(2, accList.size(), 'Should be only 2 edu inst!');
            for(Account actualEduInst : accList) {
                System.Assert.isTrue(actualEduInst.Name == NEW_EDU_INST_NAME_PREFIX + '1' || actualEduInst.Name == NEW_EDU_INST_NAME_PREFIX + '10', 'Wrong edu inst name! Actual: ' + actualEduInst.Name);
            }

            String actualObjectIconName = (String) responseDataJson.get('objectIconName');
            System.Assert.areEqual(expectedObjectIconName, actualObjectIconName, 'Wrong edu inst icon!');

		}

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for search key, but no result
     */
    @IsTest
    static void testGetRecords_SearchKeyNotFound_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        String expectedObjectIconName = REDU_Metadata_UTIL.getObjectIcon(Acc_Helper.getApiName());

        
		System.runAs(ADMIN_USER){
            Map<String, Object> customBindMap = new Map<String, Object>{ 'eduInstRecordTypeId' => ACC_Helper.getEducationalInstitutionRecordTypeId() };
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getRecords(ACC_Helper.getApiName(), new List<String> {'Name'}, 'Name;Id', 'no result', 'RecordtypeId = :eduInstRecordTypeId', customBindMap, null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('sobjList'), 'Attribute sobjList should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('objectIconName'), 'Attribute objectIconName should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('translationInfo'), 'Attribute translationInfo should exists!');

            List<Account> accList = (List<Account>) JSON.deserialize(JSON.serialize(responseDataJson.get('sobjList')), List<Account>.class);
            System.Assert.areEqual(0, accList.size(), 'Should be not found!');

            String actualObjectIconName = (String) responseDataJson.get('objectIconName');
            System.Assert.areEqual(expectedObjectIconName, actualObjectIconName, 'Wrong edu inst icon!');

		}

        Test.stopTest();
		
    }
    
    /**
     * @description Test as admin for get the selected record by id
     */
    @IsTest
    static void testGetSelectedRecord_AsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        Account rioEduInst = queryRioEduInst();
        String expectedObjectIconName = REDU_Metadata_UTIL.getObjectIcon(Acc_Helper.getApiName());

        System.runAs(ADMIN_USER) {
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getSelectedRecord(ACC_Helper.getApiName(), new List<String> {'Name', 'Id'}, rioEduInst.Id, UserInfo.getLanguage());
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('sobjList'), 'Attribute sobjList should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('objectIconName'), 'Attribute objectIconName should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('translationInfo'), 'Attribute translationInfo should exists!');
            

            List<Account> accList = (List<Account>) JSON.deserialize(JSON.serialize(responseDataJson.get('sobjList')), List<Account>.class);
            System.Assert.areEqual(1, accList.size(), 'Should be only 2 edu inst!');
            for(Account actualEduInst : accList) {
                System.Assert.areEqual(rioEduInst.Id, actualEduInst.Id, 'Wrong edu inst!');
                System.Assert.areEqual(rioEduInst.Name, actualEduInst.Name, 'Wrong edu inst!');
            }
            
            String actualObjectIconName = (String) responseDataJson.get('objectIconName');
            System.Assert.areEqual(expectedObjectIconName, actualObjectIconName, 'Wrong edu inst icon!');

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as admin for get lookup field info
     */
    @IsTest
    static void testGetLookupFieldInfo_AsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        System.runAs(ADMIN_USER) {
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getLookupFieldInfo(SUN_Helper.getApiName(), 'reduivy__Educational_Institution__c');
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('fieldLabel'), 'Attribute sobjList should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('fieldReferenceObjectName'), 'Attribute objectIconName should exists!');
            

            String actualFieldLabel = (String) responseDataJson.get('fieldLabel');
            System.Assert.areEqual(Schema.SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), actualFieldLabel, 'Wrong field label!');

            String actualFieldReferenceObjectName = (String) responseDataJson.get('fieldReferenceObjectName');
            System.Assert.areEqual(ACC_Helper.getApiName(), actualFieldReferenceObjectName, 'Wrong fieldReferenceObjectName!');

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as admin for get lookup field info, invalid lookup field
     */
    @IsTest
    static void testGetLookupFieldInfo_InvalidField_AsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        String expectedErrorMsg = String.format(Label.Invalid_Object_Field_Error, new List<String>{'invalid', SUN_Helper.getApiName()});

        System.runAs(ADMIN_USER) {
            try {
                REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getLookupFieldInfo(SUN_Helper.getApiName(), 'invalid');
                System.Assert.fail('Should fail as it is a invalid field!');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(expectedErrorMsg), 'Wrong error message! Actual: ' + exp.getMessage());

            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as admin for get lookup field info, invalid root object
     */
    @IsTest
    static void testGetLookupFieldInfo_InvalidRootObject_AsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        System.runAs(ADMIN_USER) {
            try {
                REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getLookupFieldInfo('invalid', 'reduivy__Educational_Institution__c');
                System.Assert.fail('Should fail as it is a invalid root object!');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(INVALID_SOBJECT_PROVIDED_ERROR_MSG), 'Wrong error message! Actual: ' + exp.getMessage());
            }

        }

        Test.stopTest();
        
    }

    @IsTest
    static void TestUpdateRecordLastViewed_AsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        System.runAs(ADMIN_USER) {
            List<reduivy__Study_Unit__c> sunListByReferencedDate = [
                SELECT Id, Name, LastViewedDate FROM reduivy__Study_Unit__c ORDER BY LastViewedDate DESC NULLS LAST
            ];
            System.debug(JSON.serialize(sunListByReferencedDate));

            reduivy__Study_Unit__c sunLast2Referenced = sunListByReferencedDate[1];
        
            REDU_CustomLookupField_LCTRL.updateRecordLastViewed(sunLast2Referenced.Id);    
        

        
            List<reduivy__Study_Unit__c> sunListAfterUpdateLastViewed = [
                SELECT Id, Name, LastViewedDate FROM reduivy__Study_Unit__c ORDER BY LastViewedDate DESC NULLS LAST
            ];
            System.debug(JSON.serialize(sunListAfterUpdateLastViewed));

            System.Assert.areNotEqual(sunListByReferencedDate, sunListAfterUpdateLastViewed, 'Wrong last viewed list!');
            System.Assert.areEqual(sunLast2Referenced.Id, sunListAfterUpdateLastViewed[0].Id, 'Wrong last viewed study unit!');
        }

        Test.stopTest();
    }

	
    /**
     * @description Test as faculty for basic searching
     */
    @IsTest
    static void testGetRecords_Basic_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        Map<Id, reduivy__Study_Grade_Setting__c> expectedSgsMap = new Map<Id, reduivy__Study_Grade_Setting__c>(querySgsList());
        String expectedObjectIconName = REDU_Metadata_UTIL.getObjectIcon(SGS_Helper.getApiName());
        
		System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getRecords(SGS_Helper.getApiName(), new List<String> {'Name'}, 'Name;Id', null, null, null, null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('sobjList'), 'Attribute sobjList should exists! Raw JSON: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('objectIconName'), 'Attribute objectIconName should exists! Raw JSON: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('translationInfo'), 'Attribute translationInfo should exists! Raw JSON: ' + JSON.serialize(responseDataJson));

            List<reduivy__Study_Grade_Setting__c> sgsList = (List<reduivy__Study_Grade_Setting__c>) JSON.deserialize(JSON.serialize(responseDataJson.get('sobjList')), List<reduivy__Study_Grade_Setting__c>.class);

            for(reduivy__Study_Grade_Setting__c actualSgs : sgsList) {
                System.Assert.isTrue(expectedSgsMap.keySet().contains(actualSgs.Id), 'Sgs should exists!');
            }

            String actualObjectIconName = (String) responseDataJson.get('objectIconName');
            System.Assert.areEqual(expectedObjectIconName, actualObjectIconName, 'Wrong Sgs icon!');

		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for custom filter
     */
    @IsTest
    static void testGetRecords_CustomFilter_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        String expectedObjectIconName = REDU_Metadata_UTIL.getObjectIcon(Acc_Helper.getApiName());

        
		System.runAs(FACULTY_USER){
            Map<String, Object> customBindMap = new Map<String, Object>{ 'exEduInstRecordTypeId' => ACC_Helper.getExternalEducationalInstitutionRecordTypeId() };
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getRecords(ACC_Helper.getApiName(), new List<String> {'Name'}, 'Name;Id', null, 'RecordtypeId = :exEduInstRecordTypeId', customBindMap, null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('sobjList'), 'Attribute sobjList should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('objectIconName'), 'Attribute objectIconName should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('translationInfo'), 'Attribute translationInfo should exists!');

            List<Account> accList = (List<Account>) JSON.deserialize(JSON.serialize(responseDataJson.get('sobjList')), List<Account>.class);
            System.Assert.areEqual(1, accList.size(), 'Should be only 1 ex edu inst!');
            for(Account actualExEduInst : accList) {
                System.Assert.isTrue(actualExEduInst.Name == EX_EDU_INST_NAME, 'Wrong ex edu inst name! Actual: ' + actualExEduInst.Name);
            }

            String actualObjectIconName = (String) responseDataJson.get('objectIconName');
            System.Assert.areEqual(expectedObjectIconName, actualObjectIconName, 'Wrong ex edu inst icon!');

		}

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for search key
     */
    @IsTest
    static void testGetRecords_SearchKey_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        String expectedObjectIconName = REDU_Metadata_UTIL.getObjectIcon(Acc_Helper.getApiName());

        
		System.runAs(FACULTY_USER){
            Map<String, Object> customBindMap = new Map<String, Object>{ 'eduInstRecordTypeId' => ACC_Helper.getEducationalInstitutionRecordTypeId() };
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getRecords(ACC_Helper.getApiName(), new List<String> {'Name'}, 'Name;Id', '1', 'RecordtypeId = :eduInstRecordTypeId', customBindMap, null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('sobjList'), 'Attribute sobjList should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('objectIconName'), 'Attribute objectIconName should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('translationInfo'), 'Attribute translationInfo should exists!');

            List<Account> accList = (List<Account>) JSON.deserialize(JSON.serialize(responseDataJson.get('sobjList')), List<Account>.class);
            System.Assert.areEqual(2, accList.size(), 'Should be only 2 edu inst!');
            for(Account actualEduInst : accList) {
                System.Assert.isTrue(actualEduInst.Name == NEW_EDU_INST_NAME_PREFIX + '1' || actualEduInst.Name == NEW_EDU_INST_NAME_PREFIX + '10', 'Wrong edu inst name! Actual: ' + actualEduInst.Name);
            }

            String actualObjectIconName = (String) responseDataJson.get('objectIconName');
            System.Assert.areEqual(expectedObjectIconName, actualObjectIconName, 'Wrong edu inst icon!');

		}

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for search key, but no result
     */
    @IsTest
    static void testGetRecords_SearchKeyNotFound_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        String expectedObjectIconName = REDU_Metadata_UTIL.getObjectIcon(Acc_Helper.getApiName());

        
		System.runAs(FACULTY_USER){
            Map<String, Object> customBindMap = new Map<String, Object>{ 'eduInstRecordTypeId' => ACC_Helper.getEducationalInstitutionRecordTypeId() };
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getRecords(ACC_Helper.getApiName(), new List<String> {'Name'}, 'Name;Id', 'no result', 'RecordtypeId = :eduInstRecordTypeId', customBindMap, null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('sobjList'), 'Attribute sobjList should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('objectIconName'), 'Attribute objectIconName should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('translationInfo'), 'Attribute translationInfo should exists!');

            List<Account> accList = (List<Account>) JSON.deserialize(JSON.serialize(responseDataJson.get('sobjList')), List<Account>.class);
            System.Assert.areEqual(0, accList.size(), 'Should be not found!');

            String actualObjectIconName = (String) responseDataJson.get('objectIconName');
            System.Assert.areEqual(expectedObjectIconName, actualObjectIconName, 'Wrong edu inst icon!');

		}

        Test.stopTest();
		
    }
    
    /**
     * @description Test as faculty for get the selected record by id
     */
    @IsTest
    static void testGetSelectedRecord_AsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        Account rioEduInst = queryRioEduInst();
        String expectedObjectIconName = REDU_Metadata_UTIL.getObjectIcon(Acc_Helper.getApiName());

        System.runAs(FACULTY_USER) {
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getSelectedRecord(ACC_Helper.getApiName(), new List<String> {'Name', 'Id'}, rioEduInst.Id, UserInfo.getLanguage());
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('sobjList'), 'Attribute sobjList should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('objectIconName'), 'Attribute objectIconName should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('translationInfo'), 'Attribute translationInfo should exists!');
            

            List<Account> accList = (List<Account>) JSON.deserialize(JSON.serialize(responseDataJson.get('sobjList')), List<Account>.class);
            System.Assert.areEqual(1, accList.size(), 'Should be only 2 edu inst!');
            for(Account actualEduInst : accList) {
                System.Assert.areEqual(rioEduInst.Id, actualEduInst.Id, 'Wrong edu inst!');
                System.Assert.areEqual(rioEduInst.Name, actualEduInst.Name, 'Wrong edu inst!');
            }
            
            String actualObjectIconName = (String) responseDataJson.get('objectIconName');
            System.Assert.areEqual(expectedObjectIconName, actualObjectIconName, 'Wrong edu inst icon!');

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as faculty for get lookup field info
     */
    @IsTest
    static void testGetLookupFieldInfo_AsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        System.runAs(FACULTY_USER) {
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getLookupFieldInfo(SUN_Helper.getApiName(), 'reduivy__Educational_Institution__c');
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('fieldLabel'), 'Attribute sobjList should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('fieldReferenceObjectName'), 'Attribute objectIconName should exists!');
            

            String actualFieldLabel = (String) responseDataJson.get('fieldLabel');
            System.Assert.areEqual(Schema.SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), actualFieldLabel, 'Wrong field label!');

            String actualFieldReferenceObjectName = (String) responseDataJson.get('fieldReferenceObjectName');
            System.Assert.areEqual(ACC_Helper.getApiName(), actualFieldReferenceObjectName, 'Wrong fieldReferenceObjectName!');

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as faculty for get lookup field info, invalid lookup field
     */
    @IsTest
    static void testGetLookupFieldInfo_InvalidField_AsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        String expectedErrorMsg = String.format(Label.Invalid_Object_Field_Error, new List<String>{'invalid', SUN_Helper.getApiName()});

        System.runAs(FACULTY_USER) {
            try {
                REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getLookupFieldInfo(SUN_Helper.getApiName(), 'invalid');
                System.Assert.fail('Should fail as it is a invalid field!');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(expectedErrorMsg), 'Wrong error message! Actual: ' + exp.getMessage());

            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as faculty for get lookup field info, invalid root object
     */
    @IsTest
    static void testGetLookupFieldInfo_InvalidRootObject_AsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        System.runAs(FACULTY_USER) {
            try {
                REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getLookupFieldInfo('invalid', 'reduivy__Educational_Institution__c');
                System.Assert.fail('Should fail as it is a invalid root object!');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(INVALID_SOBJECT_PROVIDED_ERROR_MSG), 'Wrong error message! Actual: ' + exp.getMessage());
            }

        }

        Test.stopTest();
        
    }

    @IsTest
    static void TestUpdateRecordLastViewed_AsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        System.runAs(FACULTY_USER) {
            List<reduivy__Study_Unit__c> sunListByReferencedDate = [
                SELECT Id, Name, LastViewedDate FROM reduivy__Study_Unit__c ORDER BY LastViewedDate DESC NULLS LAST
            ];
            System.debug(JSON.serialize(sunListByReferencedDate));

            reduivy__Study_Unit__c sunLast2Referenced = sunListByReferencedDate[1];
        
            REDU_CustomLookupField_LCTRL.updateRecordLastViewed(sunLast2Referenced.Id);    
        

        
            List<reduivy__Study_Unit__c> sunListAfterUpdateLastViewed = [
                SELECT Id, Name, LastViewedDate FROM reduivy__Study_Unit__c ORDER BY LastViewedDate DESC NULLS LAST
            ];
            System.debug(JSON.serialize(sunListAfterUpdateLastViewed));

            System.Assert.areNotEqual(sunListByReferencedDate, sunListAfterUpdateLastViewed, 'Wrong last viewed list!');
            System.Assert.areEqual(sunLast2Referenced.Id, sunListAfterUpdateLastViewed[0].Id, 'Wrong last viewed study unit!');
        }

        Test.stopTest();
    }

	
    /**
     * @description Test as student for basic searching
     */
    @IsTest
    static void testGetRecords_Basic_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        Map<Id, reduivy__Study_Grade_Setting__c> expectedSgsMap = new Map<Id, reduivy__Study_Grade_Setting__c>(querySgsList());
        String expectedObjectIconName = REDU_Metadata_UTIL.getObjectIcon(SGS_Helper.getApiName());
        
		System.runAs(studentUser){
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getRecords(SGS_Helper.getApiName(), new List<String> {'Name'}, 'Name;Id', null, null, null, null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('sobjList'), 'Attribute sobjList should exists! Raw JSON: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('objectIconName'), 'Attribute objectIconName should exists! Raw JSON: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('translationInfo'), 'Attribute translationInfo should exists! Raw JSON: ' + JSON.serialize(responseDataJson));

            List<reduivy__Study_Grade_Setting__c> sgsList = (List<reduivy__Study_Grade_Setting__c>) JSON.deserialize(JSON.serialize(responseDataJson.get('sobjList')), List<reduivy__Study_Grade_Setting__c>.class);

            for(reduivy__Study_Grade_Setting__c actualSgs : sgsList) {
                System.Assert.isTrue(expectedSgsMap.keySet().contains(actualSgs.Id), 'Sgs should exists!');
            }

            String actualObjectIconName = (String) responseDataJson.get('objectIconName');
            System.Assert.areEqual(expectedObjectIconName, actualObjectIconName, 'Wrong Sgs icon!');

		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for custom filter
     */
    @IsTest
    static void testGetRecords_CustomFilter_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        String expectedObjectIconName = REDU_Metadata_UTIL.getObjectIcon(Acc_Helper.getApiName());

        
		System.runAs(studentUser){
            Map<String, Object> customBindMap = new Map<String, Object>{ 'exEduInstRecordTypeId' => ACC_Helper.getExternalEducationalInstitutionRecordTypeId() };
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getRecords(ACC_Helper.getApiName(), new List<String> {'Name'}, 'Name;Id', null, 'RecordtypeId = :exEduInstRecordTypeId', customBindMap, null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('sobjList'), 'Attribute sobjList should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('objectIconName'), 'Attribute objectIconName should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('translationInfo'), 'Attribute translationInfo should exists!');

            List<Account> accList = (List<Account>) JSON.deserialize(JSON.serialize(responseDataJson.get('sobjList')), List<Account>.class);
            System.Assert.areEqual(1, accList.size(), 'Should be only 1 ex edu inst!');
            for(Account actualExEduInst : accList) {
                System.Assert.isTrue(actualExEduInst.Name == EX_EDU_INST_NAME, 'Wrong ex edu inst name! Actual: ' + actualExEduInst.Name);
            }

            String actualObjectIconName = (String) responseDataJson.get('objectIconName');
            System.Assert.areEqual(expectedObjectIconName, actualObjectIconName, 'Wrong ex edu inst icon!');

		}

        Test.stopTest();
		
    }

    /**
     * @description Test as student for search key
     */
    @IsTest
    static void testGetRecords_SearchKey_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        String expectedObjectIconName = REDU_Metadata_UTIL.getObjectIcon(Acc_Helper.getApiName());

        
		System.runAs(studentUser){
            Map<String, Object> customBindMap = new Map<String, Object>{ 'eduInstRecordTypeId' => ACC_Helper.getEducationalInstitutionRecordTypeId() };
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getRecords(ACC_Helper.getApiName(), new List<String> {'Name'}, 'Name;Id', '1', 'RecordtypeId = :eduInstRecordTypeId', customBindMap, null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('sobjList'), 'Attribute sobjList should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('objectIconName'), 'Attribute objectIconName should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('translationInfo'), 'Attribute translationInfo should exists!');

            List<Account> accList = (List<Account>) JSON.deserialize(JSON.serialize(responseDataJson.get('sobjList')), List<Account>.class);
            System.Assert.areEqual(2, accList.size(), 'Should be only 2 edu inst!');
            for(Account actualEduInst : accList) {
                System.Assert.isTrue(actualEduInst.Name == NEW_EDU_INST_NAME_PREFIX + '1' || actualEduInst.Name == NEW_EDU_INST_NAME_PREFIX + '10', 'Wrong edu inst name! Actual: ' + actualEduInst.Name);
            }

            String actualObjectIconName = (String) responseDataJson.get('objectIconName');
            System.Assert.areEqual(expectedObjectIconName, actualObjectIconName, 'Wrong edu inst icon!');

		}

        Test.stopTest();
		
    }

    /**
     * @description Test as student for search key, but no result
     */
    @IsTest
    static void testGetRecords_SearchKeyNotFound_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        String expectedObjectIconName = REDU_Metadata_UTIL.getObjectIcon(Acc_Helper.getApiName());

        
		System.runAs(studentUser){
            Map<String, Object> customBindMap = new Map<String, Object>{ 'eduInstRecordTypeId' => ACC_Helper.getEducationalInstitutionRecordTypeId() };
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getRecords(ACC_Helper.getApiName(), new List<String> {'Name'}, 'Name;Id', 'no result', 'RecordtypeId = :eduInstRecordTypeId', customBindMap, null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('sobjList'), 'Attribute sobjList should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('objectIconName'), 'Attribute objectIconName should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('translationInfo'), 'Attribute translationInfo should exists!');

            List<Account> accList = (List<Account>) JSON.deserialize(JSON.serialize(responseDataJson.get('sobjList')), List<Account>.class);
            System.Assert.areEqual(0, accList.size(), 'Should be not found!');

            String actualObjectIconName = (String) responseDataJson.get('objectIconName');
            System.Assert.areEqual(expectedObjectIconName, actualObjectIconName, 'Wrong edu inst icon!');

		}

        Test.stopTest();
		
    }
    
    /**
     * @description Test as student for get the selected record by id
     */
    @IsTest
    static void testGetSelectedRecord_AsStudent() {
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        Account rioEduInst = queryRioEduInst();
        String expectedObjectIconName = REDU_Metadata_UTIL.getObjectIcon(Acc_Helper.getApiName());

        System.runAs(studentUser) {
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getSelectedRecord(ACC_Helper.getApiName(), new List<String> {'Name', 'Id'}, rioEduInst.Id, UserInfo.getLanguage());
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('sobjList'), 'Attribute sobjList should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('objectIconName'), 'Attribute objectIconName should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('translationInfo'), 'Attribute translationInfo should exists!');
            

            List<Account> accList = (List<Account>) JSON.deserialize(JSON.serialize(responseDataJson.get('sobjList')), List<Account>.class);
            System.Assert.areEqual(1, accList.size(), 'Should be only 2 edu inst!');
            for(Account actualEduInst : accList) {
                System.Assert.areEqual(rioEduInst.Id, actualEduInst.Id, 'Wrong edu inst!');
                System.Assert.areEqual(rioEduInst.Name, actualEduInst.Name, 'Wrong edu inst!');
            }
            
            String actualObjectIconName = (String) responseDataJson.get('objectIconName');
            System.Assert.areEqual(expectedObjectIconName, actualObjectIconName, 'Wrong edu inst icon!');

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as student for get lookup field info
     */
    @IsTest
    static void testGetLookupFieldInfo_AsStudent() {
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        System.runAs(studentUser) {
            REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getLookupFieldInfo(SUN_Helper.getApiName(), 'reduivy__Educational_Institution__c');
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.isTrue(responseDataJson.containsKey('fieldLabel'), 'Attribute sobjList should exists!');
            System.Assert.isTrue(responseDataJson.containsKey('fieldReferenceObjectName'), 'Attribute objectIconName should exists!');
            

            String actualFieldLabel = (String) responseDataJson.get('fieldLabel');
            System.Assert.areEqual(Schema.SObjectType.reduivy__Study_Unit__c.fields.reduivy__Educational_Institution__c.getLabel(), actualFieldLabel, 'Wrong field label!');

            String actualFieldReferenceObjectName = (String) responseDataJson.get('fieldReferenceObjectName');
            System.Assert.areEqual(ACC_Helper.getApiName(), actualFieldReferenceObjectName, 'Wrong fieldReferenceObjectName!');

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as student for get lookup field info, invalid lookup field
     */
    @IsTest
    static void testGetLookupFieldInfo_InvalidField_AsStudent() {
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        String expectedErrorMsg = String.format(Label.Invalid_Object_Field_Error, new List<String>{'invalid', SUN_Helper.getApiName()});

        System.runAs(studentUser) {
            try {
                REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getLookupFieldInfo(SUN_Helper.getApiName(), 'invalid');
                System.Assert.fail('Should fail as it is a invalid field!');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(expectedErrorMsg), 'Wrong error message! Actual: ' + exp.getMessage());

            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as student for get lookup field info, invalid root object
     */
    @IsTest
    static void testGetLookupFieldInfo_InvalidRootObject_AsStudent() {
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        System.runAs(studentUser) {
            try {
                REDU_LightningResponse response = REDU_CustomLookupField_LCTRL.getLookupFieldInfo('invalid', 'reduivy__Educational_Institution__c');
                System.Assert.fail('Should fail as it is a invalid root object!');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(INVALID_SOBJECT_PROVIDED_ERROR_MSG), 'Wrong error message! Actual: ' + exp.getMessage());
            }

        }

        Test.stopTest();
        
    }

    @IsTest
    static void TestUpdateRecordLastViewed_AsStudent() {
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        System.runAs(studentUser) {
            List<reduivy__Study_Unit__c> sunListByReferencedDate = [
                SELECT Id, Name, LastViewedDate FROM reduivy__Study_Unit__c ORDER BY LastViewedDate DESC NULLS LAST
            ];
            System.debug(JSON.serialize(sunListByReferencedDate));

            reduivy__Study_Unit__c sunLast2Referenced = sunListByReferencedDate[1];
        
            REDU_CustomLookupField_LCTRL.updateRecordLastViewed(sunLast2Referenced.Id);    
        

        
            List<reduivy__Study_Unit__c> sunListAfterUpdateLastViewed = [
                SELECT Id, Name, LastViewedDate FROM reduivy__Study_Unit__c ORDER BY LastViewedDate DESC NULLS LAST
            ];
            System.debug(JSON.serialize(sunListAfterUpdateLastViewed));

            System.Assert.areNotEqual(sunListByReferencedDate, sunListAfterUpdateLastViewed, 'Wrong last viewed list!');
            System.Assert.areEqual(sunLast2Referenced.Id, sunListAfterUpdateLastViewed[0].Id, 'Wrong last viewed study unit!');
        }

        Test.stopTest();
    }




    static Account queryRioEduInst() {
        return [
            SELECT Id, Name
            FROM Account
            WHERE reduivy__Sample_Record_Code__c = :EDU_INST_SRC
            LIMIT 1
        ];
    }
	

    static List<reduivy__Study_Grade_Setting__c> querySgsList() {
        return [
            SELECT Id, Name
            FROM reduivy__Study_Grade_Setting__c
        ];
    }
	
}