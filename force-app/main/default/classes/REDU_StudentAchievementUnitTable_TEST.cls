/**
 * @author      WDCi (XW)
 * @date        Dec 2025
 * @group       Test
 * @description Test class for REDU_StudentAchievementUnitTable_LCTRL
 * @changehistory
 * ISS-002633 29-12-2025 XW - new class
 */
@IsTest
public inherited sharing class REDU_StudentAchievementUnitTable_TEST {
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    static final String CON_SRC = 'sandydoe@redu.example';
    static final String ARU_SRC = 'ARU_Introduction_to_Business_Studies';
    static final String IAC_SRC = CON_SRC + 'Individual_Achievement';
    static final String IAU_SRC = IAC_SRC + '_' + ARU_SRC;

    static final String USER_MODE_ADMIN = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
    static final String USER_MODE_FACULTY = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
    static final String USER_MODE_STUDENT = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;

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
     * @description Test as admin for getting iac, no additional fields as admin
     */
    @IsTest
    static void testForGetIac_NoAddtionalField_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        Contact student = queryStudent();

        Set<Id> expectedIacIdSet = new Set<Id>();
        Id targetIacId;
        for(reduivy__Individual_Achievement__c iac :[SELECT Id FROM reduivy__Individual_Achievement__c WHERE reduivy__Contact__c = :student.Id]) {
            expectedIacIdSet.add(iac.Id);
            targetIacId = targetIacId ?? iac.Id;
        }
        System.Assert.isFalse(expectedIacIdSet.isEmpty(), 'expectedIacIdSet should not be empty');
        List<reduivy__Individual_Achievement_Unit__c> expectedIauList = queryIau();
        Set<Id> expectedIauIdSet = (new Map<Id, reduivy__Individual_Achievement_Unit__c> (expectedIauList)).keySet();

		System.runAs(ADMIN_USER){
		    REDU_LightningResponse response = REDU_StudentAchievementUnitTable_LCTRL.getIndividualAchievementUnits(targetIacId, null, UserInfo.getLanguage());
            
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.areEqual(4, responseDataJson.size(), 'Response Data should returns 4 attributes! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('individualAchievementUnitIdList'), 'individualAchievementUnitIdList should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('isCommunity'), 'isCommunity should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('sitePath'), 'sitePath should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('unitTableFields'), 'unitTableFields should be returned! Raw: ' + JSON.serialize(responseDataJson));
            
            List<Object> iauObjectList = (List<Object>) responseDataJson.get('individualAchievementUnitIdList');
            System.Assert.areEqual(expectedIauList.size(), iauObjectList.size(), 'Wrong iau list size!');
            for(Object iauObject : iauObjectList) {
                String iauId = (String) iauObject;
                System.Assert.isTrue(expectedIauIdSet.contains((Id) iauId), 'iau id should be in the expected list!');
            }
            
            List<Object> unitTableFieldsObjects = (List<Object>) responseDataJson.get('unitTableFields');
            System.Assert.isTrue(unitTableFieldsObjects.isEmpty(), 'unitTableFields should be emptys! Raw: ' + JSON.serialize(responseDataJson));

		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for getting iac, no additional fields as admin
     */
    @IsTest
    static void testForGetIac_WithAddtionalField_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        Contact student = queryStudent();

        Set<Id> expectedIacIdSet = new Set<Id>();
        Id targetIacId;
        for(reduivy__Individual_Achievement__c iac :[SELECT Id FROM reduivy__Individual_Achievement__c WHERE reduivy__Contact__c = :student.Id]) {
            expectedIacIdSet.add(iac.Id);
            targetIacId = targetIacId ?? iac.Id;
        }
        System.Assert.isFalse(expectedIacIdSet.isEmpty(), 'expectedIacIdSet should not be empty');
        List<reduivy__Individual_Achievement_Unit__c> expectedIauList = queryIau();
        Set<Id> expectedIauIdSet = (new Map<Id, reduivy__Individual_Achievement_Unit__c> (expectedIauList)).keySet();

		System.runAs(ADMIN_USER){
		    REDU_LightningResponse response = REDU_StudentAchievementUnitTable_LCTRL.getIndividualAchievementUnits(targetIacId, 'reduivy__Verification_Status__c', UserInfo.getLanguage());
            
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.areEqual(4, responseDataJson.size(), 'Response Data should returns 4 attributes! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('individualAchievementUnitIdList'), 'individualAchievementUnitIdList should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('isCommunity'), 'isCommunity should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('sitePath'), 'sitePath should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('unitTableFields'), 'unitTableFields should be returned! Raw: ' + JSON.serialize(responseDataJson));
            
            List<Object> iauObjectList = (List<Object>) responseDataJson.get('individualAchievementUnitIdList');
            System.Assert.areEqual(expectedIauList.size(), iauObjectList.size(), 'Wrong iau list size!');
            for(Object iauObject : iauObjectList) {
                String iauId = (String) iauObject;
                System.Assert.isTrue(expectedIauIdSet.contains((Id) iauId), 'iau id should be in the expected list!');
            }

            List<Object> unitTableFieldsObjects = (List<Object>) responseDataJson.get('unitTableFields');
            for(Object unitTableFieldsObject : unitTableFieldsObjects) {
                Map<String, Object> unitTableField = (Map<String, Object>) unitTableFieldsObject;
                System.Assert.areEqual('reduivy__Verification_Status__c', (String) unitTableField.get('fieldName'), 'Wrong unit table field!');
            }

		}

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for getting iac, no additional fields as faculty
     */
    @IsTest
    static void testForGetIac_NoAddtionalField_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        Contact student = queryStudent();

        Set<Id> expectedIacIdSet = new Set<Id>();
        Id targetIacId;
        for(reduivy__Individual_Achievement__c iac :[SELECT Id FROM reduivy__Individual_Achievement__c WHERE reduivy__Contact__c = :student.Id]) {
            expectedIacIdSet.add(iac.Id);
            targetIacId = targetIacId ?? iac.Id;
        }
        System.Assert.isFalse(expectedIacIdSet.isEmpty(), 'expectedIacIdSet should not be empty');
        List<reduivy__Individual_Achievement_Unit__c> expectedIauList = queryIau();
        Set<Id> expectedIauIdSet = (new Map<Id, reduivy__Individual_Achievement_Unit__c> (expectedIauList)).keySet();

		System.runAs(FACULTY_USER){
		    REDU_LightningResponse response = REDU_StudentAchievementUnitTable_LCTRL.getIndividualAchievementUnits(targetIacId, null, UserInfo.getLanguage());
            
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.areEqual(4, responseDataJson.size(), 'Response Data should returns 4 attributes! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('individualAchievementUnitIdList'), 'individualAchievementUnitIdList should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('isCommunity'), 'isCommunity should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('sitePath'), 'sitePath should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('unitTableFields'), 'unitTableFields should be returned! Raw: ' + JSON.serialize(responseDataJson));
            
            List<Object> iauObjectList = (List<Object>) responseDataJson.get('individualAchievementUnitIdList');
            System.Assert.areEqual(expectedIauList.size(), iauObjectList.size(), 'Wrong iau list size!');
            for(Object iauObject : iauObjectList) {
                String iauId = (String) iauObject;
                System.Assert.isTrue(expectedIauIdSet.contains((Id) iauId), 'iau id should be in the expected list!');
            }
            
            List<Object> unitTableFieldsObjects = (List<Object>) responseDataJson.get('unitTableFields');
            System.Assert.isTrue(unitTableFieldsObjects.isEmpty(), 'unitTableFields should be emptys! Raw: ' + JSON.serialize(responseDataJson));

		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for getting iac, no additional fields as faculty
     */
    @IsTest
    static void testForGetIac_WithAddtionalField_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        Contact student = queryStudent();

        Set<Id> expectedIacIdSet = new Set<Id>();
        Id targetIacId;
        for(reduivy__Individual_Achievement__c iac :[SELECT Id FROM reduivy__Individual_Achievement__c WHERE reduivy__Contact__c = :student.Id]) {
            expectedIacIdSet.add(iac.Id);
            targetIacId = targetIacId ?? iac.Id;
        }
        System.Assert.isFalse(expectedIacIdSet.isEmpty(), 'expectedIacIdSet should not be empty');
        List<reduivy__Individual_Achievement_Unit__c> expectedIauList = queryIau();
        Set<Id> expectedIauIdSet = (new Map<Id, reduivy__Individual_Achievement_Unit__c> (expectedIauList)).keySet();

		System.runAs(FACULTY_USER){
		    REDU_LightningResponse response = REDU_StudentAchievementUnitTable_LCTRL.getIndividualAchievementUnits(targetIacId, 'reduivy__Verification_Status__c', UserInfo.getLanguage());
            
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.areEqual(4, responseDataJson.size(), 'Response Data should returns 4 attributes! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('individualAchievementUnitIdList'), 'individualAchievementUnitIdList should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('isCommunity'), 'isCommunity should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('sitePath'), 'sitePath should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('unitTableFields'), 'unitTableFields should be returned! Raw: ' + JSON.serialize(responseDataJson));
            
            List<Object> iauObjectList = (List<Object>) responseDataJson.get('individualAchievementUnitIdList');
            System.Assert.areEqual(expectedIauList.size(), iauObjectList.size(), 'Wrong iau list size!');
            for(Object iauObject : iauObjectList) {
                String iauId = (String) iauObject;
                System.Assert.isTrue(expectedIauIdSet.contains((Id) iauId), 'iau id should be in the expected list!');
            }

            List<Object> unitTableFieldsObjects = (List<Object>) responseDataJson.get('unitTableFields');
            for(Object unitTableFieldsObject : unitTableFieldsObjects) {
                Map<String, Object> unitTableField = (Map<String, Object>) unitTableFieldsObject;
                System.Assert.areEqual('reduivy__Verification_Status__c', (String) unitTableField.get('fieldName'), 'Wrong unit table field!');
            }
		}

        Test.stopTest();
		
    }
    
    /**
     * @description Test as student for getting iac, no additional fields as student
     */
    @IsTest
    static void testForGetIac_NoAddtionalField_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        Contact student = queryStudent();

        Set<Id> expectedIacIdSet = new Set<Id>();
        Id targetIacId;
        for(reduivy__Individual_Achievement__c iac :[SELECT Id FROM reduivy__Individual_Achievement__c WHERE reduivy__Contact__c = :student.Id]) {
            expectedIacIdSet.add(iac.Id);
            targetIacId = targetIacId ?? iac.Id;
        }
        System.Assert.isFalse(expectedIacIdSet.isEmpty(), 'expectedIacIdSet should not be empty');
        List<reduivy__Individual_Achievement_Unit__c> expectedIauList = queryIau();
        Set<Id> expectedIauIdSet = (new Map<Id, reduivy__Individual_Achievement_Unit__c> (expectedIauList)).keySet();

		System.runAs(studentUser){
		    REDU_LightningResponse response = REDU_StudentAchievementUnitTable_LCTRL.getIndividualAchievementUnits(targetIacId, null, UserInfo.getLanguage());
            
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.areEqual(4, responseDataJson.size(), 'Response Data should returns 4 attributes! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('individualAchievementUnitIdList'), 'individualAchievementUnitIdList should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('isCommunity'), 'isCommunity should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('sitePath'), 'sitePath should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('unitTableFields'), 'unitTableFields should be returned! Raw: ' + JSON.serialize(responseDataJson));
            
            List<Object> iauObjectList = (List<Object>) responseDataJson.get('individualAchievementUnitIdList');
            System.Assert.areEqual(expectedIauList.size(), iauObjectList.size(), 'Wrong iau list size!');
            for(Object iauObject : iauObjectList) {
                String iauId = (String) iauObject;
                System.Assert.isTrue(expectedIauIdSet.contains((Id) iauId), 'iau id should be in the expected list!');
            }
            
            List<Object> unitTableFieldsObjects = (List<Object>) responseDataJson.get('unitTableFields');
            System.Assert.isTrue(unitTableFieldsObjects.isEmpty(), 'unitTableFields should be emptys! Raw: ' + JSON.serialize(responseDataJson));

            
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for getting iac, no additional fields as student
     */
    @IsTest
    static void testForGetIac_WithAddtionalField_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        Contact student = queryStudent();

        Set<Id> expectedIacIdSet = new Set<Id>();
        Id targetIacId;
        for(reduivy__Individual_Achievement__c iac :[SELECT Id FROM reduivy__Individual_Achievement__c WHERE reduivy__Contact__c = :student.Id]) {
            expectedIacIdSet.add(iac.Id);
            targetIacId = targetIacId ?? iac.Id;
        }
        System.Assert.isFalse(expectedIacIdSet.isEmpty(), 'expectedIacIdSet should not be empty');
        List<reduivy__Individual_Achievement_Unit__c> expectedIauList = queryIau();
        Set<Id> expectedIauIdSet = (new Map<Id, reduivy__Individual_Achievement_Unit__c> (expectedIauList)).keySet();

		System.runAs(studentUser){
		    REDU_LightningResponse response = REDU_StudentAchievementUnitTable_LCTRL.getIndividualAchievementUnits(targetIacId, 'reduivy__Verification_Status__c', UserInfo.getLanguage());
            
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.Assert.areEqual(4, responseDataJson.size(), 'Response Data should returns 4 attributes! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('individualAchievementUnitIdList'), 'individualAchievementUnitIdList should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('isCommunity'), 'isCommunity should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('sitePath'), 'sitePath should be returned! Raw: ' + JSON.serialize(responseDataJson));
            System.Assert.isTrue(responseDataJson.containsKey('unitTableFields'), 'unitTableFields should be returned! Raw: ' + JSON.serialize(responseDataJson));
            
            List<Object> iauObjectList = (List<Object>) responseDataJson.get('individualAchievementUnitIdList');
            System.Assert.areEqual(expectedIauList.size(), iauObjectList.size(), 'Wrong iau list size!');
            for(Object iauObject : iauObjectList) {
                String iauId = (String) iauObject;
                System.Assert.isTrue(expectedIauIdSet.contains((Id) iauId), 'iau id should be in the expected list!');
            }

            List<Object> unitTableFieldsObjects = (List<Object>) responseDataJson.get('unitTableFields');
            for(Object unitTableFieldsObject : unitTableFieldsObjects) {
                Map<String, Object> unitTableField = (Map<String, Object>) unitTableFieldsObject;
                System.Assert.areEqual('reduivy__Verification_Status__c', (String) unitTableField.get('fieldName'), 'Wrong unit table field!');
            }


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

    static List<reduivy__Individual_Achievement_Unit__c> queryIau(){
        return [
            SELECT Id, Name 
            FROM reduivy__Individual_Achievement_Unit__c
            WHERE reduivy__Individual_Achievement__r.reduivy__Sample_Record_Code__c = :IAC_SRC
        ];
    }


	
}