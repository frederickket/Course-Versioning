/**
 * @author      WDCi (Jordan)
 * @date        Feb 2024
 * @group       Test
 * @description Test class for REDU_ContinuingEduHeader_LCTRL
 * @changehistory
 * ISS-001846 22-02-2024 Jordan - new test class
 */
@isTest
public inherited sharing class REDU_ContinuingEduHeader_TEST {

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

            testFactory.initMasterData(SUN_Helper.getApiName());
            testFactory.initOfferingData(STM_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);
            
            reduivy__Study_Term__c st = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];
            Account campus = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1];
            reduivy__Study_Unit__c sun = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 1];

            reduivy__Study_Offering__c newOffering = new reduivy__Study_Offering__c();
            newOffering.Name = 'Test Study Offering';
            newOffering.reduivy__Academic_Term__c = st.Id;
            newOffering.reduivy__Campus__c = campus.Id;
            newOffering.reduivy__End_Date__c = Date.today();
            newOffering.reduivy__Listing_Image_URL__c = 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Image_created_with_a_mobile_phone.png/640px-Image_created_with_a_mobile_phone.png';
            newOffering.reduivy__Study_Unit__c = sun.Id;
            insert newOffering;

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_ContinuingEduHeader_LCTRL
     */
    @isTest   
    static void testForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Offering__c offeringRecord = [SELECT Id FROM reduivy__Study_Offering__c WHERE Name = 'Test Study Offering' LIMIT 1];

        System.runAs(ADMIN_USER){
            Test.startTest();
            REDU_LightningResponse response = REDU_ContinuingEduHeader_LCTRL.getRecordInfo('reduivy__Study_Offering__c', offeringRecord.Id, 'Name', 'reduivy__Banner_Image_URL__c', 'reduivy__Enable_Guest_Registrations__c', 'reduivy__Enable_Self_Enrollment__c');
            REDU_LightningResponse noSobjectNameResponse = REDU_ContinuingEduHeader_LCTRL.getRecordInfo(null, offeringRecord.Id, 'Name', 'reduivy__Banner_Image_URL__c', 'reduivy__Enable_Guest_Registrations__c', 'reduivy__Enable_Self_Enrollment__c');
            REDU_LightningResponse nullResponse1 = REDU_ContinuingEduHeader_LCTRL.getRecordInfo('reduivy__Study_Offering__c', null, 'Name', 'reduivy__Banner_Image_URL__c', 'reduivy__Enable_Guest_Registrations__c', 'reduivy__Enable_Self_Enrollment__c');
            REDU_LightningResponse nullResponse2 = REDU_ContinuingEduHeader_LCTRL.getRecordInfo('reduivy__Study_Offering__c', offeringRecord.Id, null, null, null, null);
            Test.stopTest();

            //Response
            System.Assert.areNotEqual(null, response.responseData);
            Map<String, Object> responseData = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            List<Object> ceOfferingRecords = (List<Object>)responseData.get('records');
            System.Assert.areEqual(1, ceOfferingRecords.size());
            System.Assert.areEqual('reduivy__Study_Offering__c', responseData.get('objectName'));

            //No sobject name response
            System.Assert.areNotEqual(null, noSobjectNameResponse.responseData);
            Map<String, Object> noSobjectNameResponseData = (Map<String, Object>)JSON.deserializeUntyped(noSobjectNameResponse.responseData);
            List<Object> noSobjectNameCeOfferingRecords = (List<Object>)noSobjectNameResponseData.get('records');
            System.Assert.areEqual(1, noSobjectNameCeOfferingRecords.size());
            System.Assert.areEqual('reduivy__Study_Offering__c', noSobjectNameResponseData.get('objectName'));

            //Null response 1
            System.Assert.areEqual(null, nullResponse1.responseData);

            //Null response 2
            System.Assert.areEqual(null, nullResponse2.responseData);
        }
    }

    /**
     * @description Test with CE permission set for REDU_ContinuingEduHeader_LCTRL
     */
    @isTest   
    static void testForCePermissionSet() {
        User cePermSetUser = REDU_TestData_UTIL.newUser('RIO Ed', 'Ivy CE Permission Set', 'Standard User');
        insert cePermSetUser;

        REDU_SystemMode_UTIL.doInsert(REDU_TestData_UTIL.newPermissionSetAssignment(cePermSetUser.Id, new Set<String>{'REDU_CE_User'}));

        reduivy__Study_Offering__c offeringRecord = [SELECT Id FROM reduivy__Study_Offering__c WHERE Name = 'Test Study Offering' LIMIT 1];

        System.runAs(cePermSetUser){
            Test.startTest();
            REDU_LightningResponse response = REDU_ContinuingEduHeader_LCTRL.getRecordInfo('reduivy__Study_Offering__c', offeringRecord.Id, 'Name', 'reduivy__Banner_Image_URL__c', 'reduivy__Enable_Guest_Registrations__c', 'reduivy__Enable_Self_Enrollment__c');
            REDU_LightningResponse noSobjectNameResponse = REDU_ContinuingEduHeader_LCTRL.getRecordInfo(null, offeringRecord.Id, 'Name', 'reduivy__Banner_Image_URL__c', 'reduivy__Enable_Guest_Registrations__c', 'reduivy__Enable_Self_Enrollment__c');
            REDU_LightningResponse nullResponse1 = REDU_ContinuingEduHeader_LCTRL.getRecordInfo('reduivy__Study_Offering__c', null, 'Name', 'reduivy__Banner_Image_URL__c', 'reduivy__Enable_Guest_Registrations__c', 'reduivy__Enable_Self_Enrollment__c');
            REDU_LightningResponse nullResponse2 = REDU_ContinuingEduHeader_LCTRL.getRecordInfo('reduivy__Study_Offering__c', offeringRecord.Id, null, null, null, null);
            Test.stopTest();

            //Response
            System.Assert.areNotEqual(null, response.responseData);
            Map<String, Object> responseData = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            List<Object> ceOfferingRecords = (List<Object>)responseData.get('records');
            System.Assert.areEqual(1, ceOfferingRecords.size());
            System.Assert.areEqual('reduivy__Study_Offering__c', responseData.get('objectName'));

            //No sobject name response
            System.Assert.areNotEqual(null, noSobjectNameResponse.responseData);
            Map<String, Object> noSobjectNameResponseData = (Map<String, Object>)JSON.deserializeUntyped(noSobjectNameResponse.responseData);
            List<Object> noSobjectNameCeOfferingRecords = (List<Object>)noSobjectNameResponseData.get('records');
            System.Assert.areEqual(1, noSobjectNameCeOfferingRecords.size());
            System.Assert.areEqual('reduivy__Study_Offering__c', noSobjectNameResponseData.get('objectName'));

            //Null response 1
            System.Assert.areEqual(null, nullResponse1.responseData);

            //Null response 2
            System.Assert.areEqual(null, nullResponse2.responseData);
        }
    }

    /**
     * @description Test as student for REDU_ContinuingEduHeader_LCTRL
     */
    @isTest   
    static void testForStudent() {
        User studentUser = testFactory.getStudentUser();

        reduivy__Study_Offering__c offeringRecord = [SELECT Id FROM reduivy__Study_Offering__c WHERE Name = 'Test Study Offering' LIMIT 1];

        Test.startTest();
        try {
            System.runAs(studentUser){
                REDU_LightningResponse response = REDU_ContinuingEduHeader_LCTRL.getRecordInfo('reduivy__Study_Offering__c', offeringRecord.Id, 'Name', 'reduivy__Banner_Image_URL__c', 'reduivy__Enable_Guest_Registrations__c', 'reduivy__Enable_Self_Enrollment__c');
                REDU_LightningResponse noSobjectNameResponse = REDU_ContinuingEduHeader_LCTRL.getRecordInfo(null, offeringRecord.Id, 'Name', 'reduivy__Banner_Image_URL__c', 'reduivy__Enable_Guest_Registrations__c', 'reduivy__Enable_Self_Enrollment__c');
                REDU_LightningResponse nullResponse1 = REDU_ContinuingEduHeader_LCTRL.getRecordInfo('reduivy__Study_Offering__c', null, 'Name', 'reduivy__Banner_Image_URL__c', 'reduivy__Enable_Guest_Registrations__c', 'reduivy__Enable_Self_Enrollment__c');
                REDU_LightningResponse nullResponse2 = REDU_ContinuingEduHeader_LCTRL.getRecordInfo('reduivy__Study_Offering__c', offeringRecord.Id, null, null, null, null);
            }
            System.Assert.fail('This should fail with FLS error.');
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s)'), 'The exception is invalid: ' + exp.getMessage());
        }
        Test.stopTest();
    }

    /**
     * @description Test as faculty for REDU_ContinuingEduHeader_LCTRL
     */
    @isTest   
    static void testForFaculty() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Study_Offering__c offeringRecord = [SELECT Id FROM reduivy__Study_Offering__c WHERE Name = 'Test Study Offering' LIMIT 1];

        Test.startTest();
        try {
            System.runAs(FACULTY_USER){
                REDU_LightningResponse response = REDU_ContinuingEduHeader_LCTRL.getRecordInfo('reduivy__Study_Offering__c', offeringRecord.Id, 'Name', 'reduivy__Banner_Image_URL__c', 'reduivy__Enable_Guest_Registrations__c', 'reduivy__Enable_Self_Enrollment__c');
                REDU_LightningResponse noSobjectNameResponse = REDU_ContinuingEduHeader_LCTRL.getRecordInfo(null, offeringRecord.Id, 'Name', 'reduivy__Banner_Image_URL__c', 'reduivy__Enable_Guest_Registrations__c', 'reduivy__Enable_Self_Enrollment__c');
                REDU_LightningResponse nullResponse1 = REDU_ContinuingEduHeader_LCTRL.getRecordInfo('reduivy__Study_Offering__c', null, 'Name', 'reduivy__Banner_Image_URL__c', 'reduivy__Enable_Guest_Registrations__c', 'reduivy__Enable_Self_Enrollment__c');
                REDU_LightningResponse nullResponse2 = REDU_ContinuingEduHeader_LCTRL.getRecordInfo('reduivy__Study_Offering__c', offeringRecord.Id, null, null, null, null);
            }
            System.Assert.fail('This should fail with FLS error.');
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s)'), 'The exception is invalid: ' + exp.getMessage());
        }
        Test.stopTest();
    }
}