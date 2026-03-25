/**
 * @author      WDCi (XW)
 * @date        Jan 2026
 * @group       Test
 * @description Test class for REDU_StudentAchievementUnit_LCTRL
 * @changehistory
 * ISS-002633 27-01-2026 XW - new class
 */
@IsTest
public inherited sharing class REDU_StudentAchievementUnit_TEST {

    
    static final String CON_SRC = 'sandydoe@redu.example';
    static final String ARU_SRC = 'ARU_Introduction_to_Business_Studies';
    static final String IAC_SRC = CON_SRC + 'Individual_Achievement';
    static final String IAU_SRC = IAC_SRC + '_' + ARU_SRC;

    static final String USER_MODE_ADMIN = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
    static final String USER_MODE_FACULTY = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
    static final String USER_MODE_STUDENT = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;

    static final Set<String> INDIVIDUAL_ACHIEVEMENT_UNIT_EXPECTED_ATTRIBUTES = new Set<String> {
        'individualAchievementUnitRecord',
        'irqWrapperList',
        REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM,
        'existingFiles',
        'unitTableFields'
    };

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
            testFactory.initStudentData(IAU_Helper.getApiName(), true);

            reduivy__Study_Requirement_Set__c iauSrs = new reduivy__Study_Requirement_Set__c(
                Name = 'Achievement Unit SRS',
                reduivy__Code__c = 'Achievement Unit SRS',
                reduivy__Status__c = SRS_Helper.STATUS_ACTIVE,
                reduivy__Object__c = 'reduivy__Individual_Achievement_Unit__c',
                reduivy__Contact_Field__c = 'reduivy__Individual_Achievement__r.reduivy__Contact__c',
                reduivy__Criteria__c = 'reduivy__Individual_Achievement__r.reduivy__Contact__c != null'

            );

            insert iauSrs;

            reduivy__Study_Requirement__c srqStudent = new reduivy__Study_Requirement__c(
                Name='Upload Syllibi',
                reduivy__Code__c='Upload Syllibi',
                reduivy__Study_Requirement_Set__c = iauSrs.Id,
                reduivy__Status__c = SRQ_Helper.STATUS_ACTIVE,
                reduivy__Requirement_Type__c = SRQ_Helper.REQUIREMENT_TYPE_FILE_UPLOAD,
                reduivy__Requirement_Visibility__c = SRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT,
                reduivy__Due_Days__c = 5,
                reduivy__Sequence__c = 1,
                reduivy__Create_Salesforce_Task__c = false
            );
            
            reduivy__Study_Requirement__c srqAdmin = new reduivy__Study_Requirement__c(
                Name='Review Syllibi',
                reduivy__Code__c='Review Syllibi',
                reduivy__Study_Requirement_Set__c = iauSrs.Id,
                reduivy__Status__c = SRQ_Helper.STATUS_ACTIVE,
                reduivy__Requirement_Type__c = SRQ_Helper.REQUIREMENT_TYPE_ACTION,
                reduivy__Requirement_Visibility__c = SRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN,
                reduivy__Due_Days__c = 7,
                reduivy__Sequence__c = 1,
                reduivy__Create_Salesforce_Task__c = false
            );
            
            insert new List<reduivy__Study_Requirement__c> { srqStudent, srqAdmin };

            Id studentUserId = testFactory.getStudentUser().Id;
            reduivy__Individual_Requirement_Set__c irs = IRS_Helper.createIrs(iauSrs, testFactory.idvAchievementUnit.get(IAU_SRC), studentUserId);
            insert irs;

            reduivy__Individual_Requirement__c irqStudent = IRQ_Helper.createIrq(srqStudent, irs.Id, studentUserId);
            reduivy__Individual_Requirement__c irqAdmin = IRQ_Helper.createIrq(srqAdmin, irs.Id, studentUserId);

            insert new List<reduivy__Individual_Requirement__c> { irqAdmin, irqStudent };


            //file for irq student
            //insert file
            Blob body = Blob.valueOf('data:image/gif;base64,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');

            String fileName = 'testImage' + String.valueOf(System.today()) + '_sampleimage.png';
            ContentVersion cv = new ContentVersion(Title = fileName, VersionData = body, PathOnClient='/' + fileName); 
            insert cv;
            
            cv = [select ContentDocumentId from ContentVersion where id=:cv.Id];
            insert new ContentDocumentLink(ContentDocumentId = cv.ContentDocumentId, ShareType = 'V', Visibility = 'AllUsers', LinkedEntityId = irqStudent.Id);


            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for getting individual achievement unit by id
     */
    @IsTest
    static void testForGetIndividualAchievementUnit_NullFields_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        reduivy__Individual_Achievement_Unit__c expectedIau = queryIau();
        

		System.runAs(ADMIN_USER){
		
            REDU_LightningResponse response = REDU_StudentAchievementUnit_LCTRL.getIndividualAchievementUnit(expectedIau.Id, null, USER_MODE_ADMIN, null, UserInfo.getLanguage());
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.areEqual(INDIVIDUAL_ACHIEVEMENT_UNIT_EXPECTED_ATTRIBUTES, responseDataJson.keySet(), 'Wrong attributes!');

            Map<String, Object> actualIau = (Map<String, Object>) responseDataJson.get('individualAchievementUnitRecord');
            System.Assert.areEqual(expectedIau.Id, (String) actualIau.get('Id'), 'Wrong iau id!');
            System.Assert.areEqual(expectedIau.Name, (String) actualIau.get('Name'), 'Wrong iau Name!');
            System.Assert.areEqual(expectedIau.reduivy__Verification_Status__c, (String) actualIau.get('reduivy__Verification_Status__c'), 'Wrong iau reduivy__Verification_Status__c!');

            Map<String, Object> actualIauAru = (Map<String, Object>) actualIau.get('reduivy__Agreement_Recognition_Unit__r');
            System.Assert.areEqual(expectedIau.reduivy__Agreement_Recognition_Unit__r.Name, (String) actualIauAru.get('Name'), 'Wrong iau reduivy__Agreement_Recognition_Unit__r.Name!');
            System.Assert.areEqual(expectedIau.reduivy__Agreement_Recognition_Unit__r.reduivy__Unit_Code__c, (String) actualIauAru.get('reduivy__Unit_Code__c'), 'Wrong iau reduivy__Agreement_Recognition_Unit__r.reduivy__Unit_Code__c!');
            
            Map<String, Object> actualIauIac = (Map<String, Object>) actualIau.get('reduivy__Individual_Achievement__r');
            System.Assert.areEqual(expectedIau.reduivy__Individual_Achievement__r.reduivy__Verification_Status__c, (String) actualIauIac.get('reduivy__Verification_Status__c'), 'Wrong iau reduivy__Individual_Achievement__r.reduivy__Verification_Status__c!');
            System.Assert.areEqual(expectedIau.reduivy__Individual_Achievement__r.Name, (String) actualIauIac.get('Name'), 'Wrong iau reduivy__Individual_Achievement__r.Name!');

            List<REDU_RequirementChecklist_LCTRL.RequirementWrapper> irqWrapperList = (List<REDU_RequirementChecklist_LCTRL.RequirementWrapper>) JSON.deserialize(JSON.serialize(responseDataJson.get('irqWrapperList')), List<REDU_RequirementChecklist_LCTRL.RequirementWrapper>.class);
            System.Assert.areEqual(2, irqWrapperList.size(), 'irqWrapperList size should be 2!');

            Map<Id, List<ContentVersion>> existingFiles = (Map<Id, List<ContentVersion>>) JSON.deserialize(JSON.serialize(responseDataJson.get('existingFiles')), Map<Id, List<ContentVersion>>.class);
            System.Assert.areEqual(1, existingFiles.size(), 'existingFiles size should be 1!');

            List<REDU_DynamicFieldValue_OBJ> unitTableFields = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(JSON.serialize(responseDataJson.get('unitTableFields')), List<REDU_DynamicFieldValue_OBJ>.class);
            System.Assert.areEqual(0, unitTableFields.size(), 'unitTableFields should be empty!');
            
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for getting individual achievement unit by id
     */
    @IsTest
    static void testForGetIndividualAchievementUnit_WithFields_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        reduivy__Individual_Achievement_Unit__c expectedIau = queryIau();
        

		System.runAs(ADMIN_USER){
		
            REDU_LightningResponse response = REDU_StudentAchievementUnit_LCTRL.getIndividualAchievementUnit(expectedIau.Id, new List<String> {'reduivy__Verification_Date__c', 'reduivy__Individual_Achievement__c'}, USER_MODE_ADMIN, 'reduivy__Verification_Date__c', null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.areEqual(INDIVIDUAL_ACHIEVEMENT_UNIT_EXPECTED_ATTRIBUTES, responseDataJson.keySet(), 'Wrong attributes!');

            Map<String, Object> actualIau = (Map<String, Object>) responseDataJson.get('individualAchievementUnitRecord');
            System.Assert.areEqual(expectedIau.Id, (String) actualIau.get('Id'), 'Wrong iau id!');
            System.Assert.areEqual(expectedIau.Name, (String) actualIau.get('Name'), 'Wrong iau Name!');
            System.Assert.areEqual(expectedIau.reduivy__Verification_Status__c, (String) actualIau.get('reduivy__Verification_Status__c'), 'Wrong iau reduivy__Verification_Status__c!');
            System.Assert.isTrue(actualIau.containsKey('reduivy__Verification_Date__c'), 'Should contain reduivy__Verification_Date__c!');
            

            Map<String, Object> actualIauAru = (Map<String, Object>) actualIau.get('reduivy__Agreement_Recognition_Unit__r');
            System.Assert.areEqual(expectedIau.reduivy__Agreement_Recognition_Unit__r.Name, (String) actualIauAru.get('Name'), 'Wrong iau reduivy__Agreement_Recognition_Unit__r.Name!');
            System.Assert.areEqual(expectedIau.reduivy__Agreement_Recognition_Unit__r.reduivy__Unit_Code__c, (String) actualIauAru.get('reduivy__Unit_Code__c'), 'Wrong iau reduivy__Agreement_Recognition_Unit__r.reduivy__Unit_Code__c!');
            
            Map<String, Object> actualIauIac = (Map<String, Object>) actualIau.get('reduivy__Individual_Achievement__r');
            System.Assert.areEqual(expectedIau.reduivy__Individual_Achievement__r.reduivy__Verification_Status__c, (String) actualIauIac.get('reduivy__Verification_Status__c'), 'Wrong iau reduivy__Individual_Achievement__r.reduivy__Verification_Status__c!');
            System.Assert.areEqual(expectedIau.reduivy__Individual_Achievement__r.Name, (String) actualIauIac.get('Name'), 'Wrong iau reduivy__Individual_Achievement__r.Name!');

            List<REDU_RequirementChecklist_LCTRL.RequirementWrapper> irqWrapperList = (List<REDU_RequirementChecklist_LCTRL.RequirementWrapper>) JSON.deserialize(JSON.serialize(responseDataJson.get('irqWrapperList')), List<REDU_RequirementChecklist_LCTRL.RequirementWrapper>.class);
            System.Assert.areEqual(2, irqWrapperList.size(), 'irqWrapperList size should be 2!');

            Map<Id, List<ContentVersion>> existingFiles = (Map<Id, List<ContentVersion>>) JSON.deserialize(JSON.serialize(responseDataJson.get('existingFiles')), Map<Id, List<ContentVersion>>.class);
            System.Assert.areEqual(1, existingFiles.size(), 'existingFiles size should be 1!');

            List<REDU_DynamicFieldValue_OBJ> unitTableFields = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(JSON.serialize(responseDataJson.get('unitTableFields')), List<REDU_DynamicFieldValue_OBJ>.class);
            System.Assert.areEqual(1, unitTableFields.size(), 'unitTableFields should be empty!');
            System.Assert.areEqual('reduivy__Verification_Date__c', unitTableFields.get(0).fieldName, 'fieldName should be reduivy__Verification_Date__c!');
            
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for getting individual achievement unit without id
     */
    @IsTest
    static void testForGetIndividualAchievementUnit_WithoutId_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        reduivy__Individual_Achievement_Unit__c expectedIau = queryIau();
        

		System.runAs(ADMIN_USER){
		
            REDU_LightningResponse response = REDU_StudentAchievementUnit_LCTRL.getIndividualAchievementUnit(null, new List<String> {'reduivy__Verification_Date__c', 'reduivy__Individual_Achievement__c'}, USER_MODE_ADMIN, null, null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.isTrue(responseDataJson.isEmpty(), 'Map should be empty!');
		}

        Test.stopTest();
		
    }


    
	
    /**
     * @description Test as faculty for getting individual achievement unit by id
     */
    @IsTest
    static void testForGetIndividualAchievementUnit_NullFields_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        reduivy__Individual_Achievement_Unit__c expectedIau = queryIau();
        

		System.runAs(FACULTY_USER){
		
            REDU_LightningResponse response = REDU_StudentAchievementUnit_LCTRL.getIndividualAchievementUnit(expectedIau.Id, null, USER_MODE_FACULTY, null, UserInfo.getLanguage());
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.areEqual(INDIVIDUAL_ACHIEVEMENT_UNIT_EXPECTED_ATTRIBUTES, responseDataJson.keySet(), 'Wrong attributes!');

            Map<String, Object> actualIau = (Map<String, Object>) responseDataJson.get('individualAchievementUnitRecord');
            System.Assert.areEqual(expectedIau.Id, (String) actualIau.get('Id'), 'Wrong iau id!');
            System.Assert.areEqual(expectedIau.Name, (String) actualIau.get('Name'), 'Wrong iau Name!');
            System.Assert.areEqual(expectedIau.reduivy__Verification_Status__c, (String) actualIau.get('reduivy__Verification_Status__c'), 'Wrong iau reduivy__Verification_Status__c!');

            Map<String, Object> actualIauAru = (Map<String, Object>) actualIau.get('reduivy__Agreement_Recognition_Unit__r');
            System.Assert.areEqual(expectedIau.reduivy__Agreement_Recognition_Unit__r.Name, (String) actualIauAru.get('Name'), 'Wrong iau reduivy__Agreement_Recognition_Unit__r.Name!');
            System.Assert.areEqual(expectedIau.reduivy__Agreement_Recognition_Unit__r.reduivy__Unit_Code__c, (String) actualIauAru.get('reduivy__Unit_Code__c'), 'Wrong iau reduivy__Agreement_Recognition_Unit__r.reduivy__Unit_Code__c!');
            
            Map<String, Object> actualIauIac = (Map<String, Object>) actualIau.get('reduivy__Individual_Achievement__r');
            System.Assert.areEqual(expectedIau.reduivy__Individual_Achievement__r.reduivy__Verification_Status__c, (String) actualIauIac.get('reduivy__Verification_Status__c'), 'Wrong iau reduivy__Individual_Achievement__r.reduivy__Verification_Status__c!');
            System.Assert.areEqual(expectedIau.reduivy__Individual_Achievement__r.Name, (String) actualIauIac.get('Name'), 'Wrong iau reduivy__Individual_Achievement__r.Name!');

            List<REDU_RequirementChecklist_LCTRL.RequirementWrapper> irqWrapperList = (List<REDU_RequirementChecklist_LCTRL.RequirementWrapper>) JSON.deserialize(JSON.serialize(responseDataJson.get('irqWrapperList')), List<REDU_RequirementChecklist_LCTRL.RequirementWrapper>.class);
            System.Assert.areEqual(1, irqWrapperList.size(), 'irqWrapperList size should be 1!');

            Map<Id, List<ContentVersion>> existingFiles = (Map<Id, List<ContentVersion>>) JSON.deserialize(JSON.serialize(responseDataJson.get('existingFiles')), Map<Id, List<ContentVersion>>.class);
            System.Assert.areEqual(1, existingFiles.size(), 'existingFiles size should be 1!');

            List<REDU_DynamicFieldValue_OBJ> unitTableFields = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(JSON.serialize(responseDataJson.get('unitTableFields')), List<REDU_DynamicFieldValue_OBJ>.class);
            System.Assert.areEqual(0, unitTableFields.size(), 'unitTableFields should be empty!');
            
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for getting individual achievement unit by id
     */
    @IsTest
    static void testForGetIndividualAchievementUnit_WithFields_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        reduivy__Individual_Achievement_Unit__c expectedIau = queryIau();
        

		System.runAs(FACULTY_USER){
		
            REDU_LightningResponse response = REDU_StudentAchievementUnit_LCTRL.getIndividualAchievementUnit(expectedIau.Id, new List<String> {'reduivy__Verification_Date__c', 'reduivy__Individual_Achievement__c'}, USER_MODE_FACULTY, 'reduivy__Verification_Date__c', null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.areEqual(INDIVIDUAL_ACHIEVEMENT_UNIT_EXPECTED_ATTRIBUTES, responseDataJson.keySet(), 'Wrong attributes!');

            Map<String, Object> actualIau = (Map<String, Object>) responseDataJson.get('individualAchievementUnitRecord');
            System.Assert.areEqual(expectedIau.Id, (String) actualIau.get('Id'), 'Wrong iau id!');
            System.Assert.areEqual(expectedIau.Name, (String) actualIau.get('Name'), 'Wrong iau Name!');
            System.Assert.areEqual(expectedIau.reduivy__Verification_Status__c, (String) actualIau.get('reduivy__Verification_Status__c'), 'Wrong iau reduivy__Verification_Status__c!');
            System.Assert.isTrue(actualIau.containsKey('reduivy__Verification_Date__c'), 'Should contain reduivy__Verification_Date__c!');
            

            Map<String, Object> actualIauAru = (Map<String, Object>) actualIau.get('reduivy__Agreement_Recognition_Unit__r');
            System.Assert.areEqual(expectedIau.reduivy__Agreement_Recognition_Unit__r.Name, (String) actualIauAru.get('Name'), 'Wrong iau reduivy__Agreement_Recognition_Unit__r.Name!');
            System.Assert.areEqual(expectedIau.reduivy__Agreement_Recognition_Unit__r.reduivy__Unit_Code__c, (String) actualIauAru.get('reduivy__Unit_Code__c'), 'Wrong iau reduivy__Agreement_Recognition_Unit__r.reduivy__Unit_Code__c!');
            
            Map<String, Object> actualIauIac = (Map<String, Object>) actualIau.get('reduivy__Individual_Achievement__r');
            System.Assert.areEqual(expectedIau.reduivy__Individual_Achievement__r.reduivy__Verification_Status__c, (String) actualIauIac.get('reduivy__Verification_Status__c'), 'Wrong iau reduivy__Individual_Achievement__r.reduivy__Verification_Status__c!');
            System.Assert.areEqual(expectedIau.reduivy__Individual_Achievement__r.Name, (String) actualIauIac.get('Name'), 'Wrong iau reduivy__Individual_Achievement__r.Name!');

            List<REDU_RequirementChecklist_LCTRL.RequirementWrapper> irqWrapperList = (List<REDU_RequirementChecklist_LCTRL.RequirementWrapper>) JSON.deserialize(JSON.serialize(responseDataJson.get('irqWrapperList')), List<REDU_RequirementChecklist_LCTRL.RequirementWrapper>.class);
            System.Assert.areEqual(1, irqWrapperList.size(), 'irqWrapperList size should be 1!');

            Map<Id, List<ContentVersion>> existingFiles = (Map<Id, List<ContentVersion>>) JSON.deserialize(JSON.serialize(responseDataJson.get('existingFiles')), Map<Id, List<ContentVersion>>.class);
            System.Assert.areEqual(1, existingFiles.size(), 'existingFiles size should be 1!');

            List<REDU_DynamicFieldValue_OBJ> unitTableFields = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(JSON.serialize(responseDataJson.get('unitTableFields')), List<REDU_DynamicFieldValue_OBJ>.class);
            System.Assert.areEqual(1, unitTableFields.size(), 'unitTableFields should be empty!');
            System.Assert.areEqual('reduivy__Verification_Date__c', unitTableFields.get(0).fieldName, 'fieldName should be reduivy__Verification_Date__c!');
            
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for getting individual achievement unit without id
     */
    @IsTest
    static void testForGetIndividualAchievementUnit_WithoutId_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        reduivy__Individual_Achievement_Unit__c expectedIau = queryIau();
        

		System.runAs(FACULTY_USER){
		
            REDU_LightningResponse response = REDU_StudentAchievementUnit_LCTRL.getIndividualAchievementUnit(null, new List<String> {'reduivy__Verification_Date__c', 'reduivy__Individual_Achievement__c'}, USER_MODE_FACULTY, null, null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.isTrue(responseDataJson.isEmpty(), 'Map should be empty!');
		}

        Test.stopTest();
		
    }

    
	
    /**
     * @description Test as student for getting individual achievement unit by id
     */
    @IsTest
    static void testForGetIndividualAchievementUnit_NullFields_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        reduivy__Individual_Achievement_Unit__c expectedIau = queryIau();
        

		System.runAs(studentUser){
		
            REDU_LightningResponse response = REDU_StudentAchievementUnit_LCTRL.getIndividualAchievementUnit(expectedIau.Id, null, USER_MODE_STUDENT, null, UserInfo.getLanguage());
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.areEqual(INDIVIDUAL_ACHIEVEMENT_UNIT_EXPECTED_ATTRIBUTES, responseDataJson.keySet(), 'Wrong attributes!');

            Map<String, Object> actualIau = (Map<String, Object>) responseDataJson.get('individualAchievementUnitRecord');
            System.Assert.areEqual(expectedIau.Id, (String) actualIau.get('Id'), 'Wrong iau id!');
            System.Assert.areEqual(expectedIau.Name, (String) actualIau.get('Name'), 'Wrong iau Name!');
            System.Assert.areEqual(expectedIau.reduivy__Verification_Status__c, (String) actualIau.get('reduivy__Verification_Status__c'), 'Wrong iau reduivy__Verification_Status__c!');

            Map<String, Object> actualIauAru = (Map<String, Object>) actualIau.get('reduivy__Agreement_Recognition_Unit__r');
            System.Assert.areEqual(expectedIau.reduivy__Agreement_Recognition_Unit__r.Name, (String) actualIauAru.get('Name'), 'Wrong iau reduivy__Agreement_Recognition_Unit__r.Name!');
            System.Assert.areEqual(expectedIau.reduivy__Agreement_Recognition_Unit__r.reduivy__Unit_Code__c, (String) actualIauAru.get('reduivy__Unit_Code__c'), 'Wrong iau reduivy__Agreement_Recognition_Unit__r.reduivy__Unit_Code__c!');
            
            Map<String, Object> actualIauIac = (Map<String, Object>) actualIau.get('reduivy__Individual_Achievement__r');
            System.Assert.areEqual(expectedIau.reduivy__Individual_Achievement__r.reduivy__Verification_Status__c, (String) actualIauIac.get('reduivy__Verification_Status__c'), 'Wrong iau reduivy__Individual_Achievement__r.reduivy__Verification_Status__c!');
            System.Assert.areEqual(expectedIau.reduivy__Individual_Achievement__r.Name, (String) actualIauIac.get('Name'), 'Wrong iau reduivy__Individual_Achievement__r.Name!');

            List<REDU_RequirementChecklist_LCTRL.RequirementWrapper> irqWrapperList = (List<REDU_RequirementChecklist_LCTRL.RequirementWrapper>) JSON.deserialize(JSON.serialize(responseDataJson.get('irqWrapperList')), List<REDU_RequirementChecklist_LCTRL.RequirementWrapper>.class);
            System.Assert.areEqual(1, irqWrapperList.size(), 'irqWrapperList size should be 1!');

            Map<Id, List<ContentVersion>> existingFiles = (Map<Id, List<ContentVersion>>) JSON.deserialize(JSON.serialize(responseDataJson.get('existingFiles')), Map<Id, List<ContentVersion>>.class);
            System.Assert.areEqual(1, existingFiles.size(), 'existingFiles size should be 1!');

            List<REDU_DynamicFieldValue_OBJ> unitTableFields = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(JSON.serialize(responseDataJson.get('unitTableFields')), List<REDU_DynamicFieldValue_OBJ>.class);
            System.Assert.areEqual(0, unitTableFields.size(), 'unitTableFields should be empty!');
            
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as student for getting individual achievement unit by id
     */
    @IsTest
    static void testForGetIndividualAchievementUnit_WithFields_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        reduivy__Individual_Achievement_Unit__c expectedIau = queryIau();
        

		System.runAs(studentUser){
		
            REDU_LightningResponse response = REDU_StudentAchievementUnit_LCTRL.getIndividualAchievementUnit(expectedIau.Id, new List<String> {'reduivy__Verification_Date__c', 'reduivy__Individual_Achievement__c'}, USER_MODE_STUDENT, 'reduivy__Verification_Date__c', null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.areEqual(INDIVIDUAL_ACHIEVEMENT_UNIT_EXPECTED_ATTRIBUTES, responseDataJson.keySet(), 'Wrong attributes!');

            Map<String, Object> actualIau = (Map<String, Object>) responseDataJson.get('individualAchievementUnitRecord');
            System.Assert.areEqual(expectedIau.Id, (String) actualIau.get('Id'), 'Wrong iau id!');
            System.Assert.areEqual(expectedIau.Name, (String) actualIau.get('Name'), 'Wrong iau Name!');
            System.Assert.areEqual(expectedIau.reduivy__Verification_Status__c, (String) actualIau.get('reduivy__Verification_Status__c'), 'Wrong iau reduivy__Verification_Status__c!');
            System.Assert.isTrue(actualIau.containsKey('reduivy__Verification_Date__c'), 'Should contain reduivy__Verification_Date__c!');
            

            Map<String, Object> actualIauAru = (Map<String, Object>) actualIau.get('reduivy__Agreement_Recognition_Unit__r');
            System.Assert.areEqual(expectedIau.reduivy__Agreement_Recognition_Unit__r.Name, (String) actualIauAru.get('Name'), 'Wrong iau reduivy__Agreement_Recognition_Unit__r.Name!');
            System.Assert.areEqual(expectedIau.reduivy__Agreement_Recognition_Unit__r.reduivy__Unit_Code__c, (String) actualIauAru.get('reduivy__Unit_Code__c'), 'Wrong iau reduivy__Agreement_Recognition_Unit__r.reduivy__Unit_Code__c!');
            
            Map<String, Object> actualIauIac = (Map<String, Object>) actualIau.get('reduivy__Individual_Achievement__r');
            System.Assert.areEqual(expectedIau.reduivy__Individual_Achievement__r.reduivy__Verification_Status__c, (String) actualIauIac.get('reduivy__Verification_Status__c'), 'Wrong iau reduivy__Individual_Achievement__r.reduivy__Verification_Status__c!');
            System.Assert.areEqual(expectedIau.reduivy__Individual_Achievement__r.Name, (String) actualIauIac.get('Name'), 'Wrong iau reduivy__Individual_Achievement__r.Name!');

            List<REDU_RequirementChecklist_LCTRL.RequirementWrapper> irqWrapperList = (List<REDU_RequirementChecklist_LCTRL.RequirementWrapper>) JSON.deserialize(JSON.serialize(responseDataJson.get('irqWrapperList')), List<REDU_RequirementChecklist_LCTRL.RequirementWrapper>.class);
            System.Assert.areEqual(1, irqWrapperList.size(), 'irqWrapperList size should be 1!');

            Map<Id, List<ContentVersion>> existingFiles = (Map<Id, List<ContentVersion>>) JSON.deserialize(JSON.serialize(responseDataJson.get('existingFiles')), Map<Id, List<ContentVersion>>.class);
            System.Assert.areEqual(1, existingFiles.size(), 'existingFiles size should be 1!');

            List<REDU_DynamicFieldValue_OBJ> unitTableFields = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(JSON.serialize(responseDataJson.get('unitTableFields')), List<REDU_DynamicFieldValue_OBJ>.class);
            System.Assert.areEqual(1, unitTableFields.size(), 'unitTableFields should be empty!');
            System.Assert.areEqual('reduivy__Verification_Date__c', unitTableFields.get(0).fieldName, 'fieldName should be reduivy__Verification_Date__c!');
            
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for getting individual achievement unit without id
     */
    @IsTest
    static void testForGetIndividualAchievementUnit_WithoutId_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        reduivy__Individual_Achievement_Unit__c expectedIau = queryIau();
        

		System.runAs(studentUser){
		
            REDU_LightningResponse response = REDU_StudentAchievementUnit_LCTRL.getIndividualAchievementUnit(null, new List<String> {'reduivy__Verification_Date__c', 'reduivy__Individual_Achievement__c'}, USER_MODE_STUDENT, null, null);
            Map<String, Object> responseDataJson = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.isTrue(responseDataJson.isEmpty(), 'Map should be empty!');
		}

        Test.stopTest();
		
    }
	
    static reduivy__Individual_Achievement_Unit__c queryIau() {
        return [
            SELECT 
            Id,
            Name,
            reduivy__Verification_Status__c,
            reduivy__Agreement_Recognition_Unit__r.Name,
            reduivy__Agreement_Recognition_Unit__r.reduivy__Unit_Code__c,
            reduivy__Individual_Achievement__r.reduivy__Verification_Status__c,
            reduivy__Individual_Achievement__r.Name
            FROM reduivy__Individual_Achievement_Unit__c
            WHERE reduivy__Sample_Record_Code__c = :IAU_SRC
            LIMIT 1
        ];
    }

}