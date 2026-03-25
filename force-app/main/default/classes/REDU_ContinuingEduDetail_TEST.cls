/**
 * @author      WDCi (Jordan)
 * @date        Feb 2024
 * @group       Test
 * @description Test class for REDU_ContinuingEduDetail_LCTRL
 * @changehistory
 * ISS-001846 22-02-2024 Jordan - new test class
 */
@isTest
public inherited sharing class REDU_ContinuingEduDetail_TEST {

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
            Account eduInst = REDU_TestData_UTIL.newEducationalInstitution('RIOUNI', 'RIO University', 'RIOUNI');
            REDU_SystemMode_UTIL.doInsert(new List<Account>{eduInst});

            Account campus = REDU_TestData_UTIL.newCampus('SYDNEY', eduInst.Id, 'Sydney Campus', 'SYDNEY', 'Australia/Sydney');
            REDU_SystemMode_UTIL.doInsert(new List<Account>{campus});

            reduivy__Study_Unit__c  sun = REDU_TestData_UTIL.newStudyUnit('BUS101', eduInst.Id, null, 'BUS101', 'BUS101', 5, 'Business, Management, and Marketing', '100', 0.125, null);
            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Study_Unit__c>{sun});

            reduivy__Study_Term__c academicYear = REDU_TestData_UTIL.newAcademicYearStudyTerm('CY', eduInst.Id, 'Year ' + System.today().year(), 'Academic Year ' + System.today().year(), STM_Helper.TYPE_SCHOOLYEAR, Date.newInstance(System.today().year(), 1, 1), Date.newInstance(System.today().year(), 12, 31));
            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Study_Term__c>{academicYear});
            
            reduivy__Study_Term__c academicTerm = REDU_TestData_UTIL.newAcademicTermStudyTerm('CYT1', academicYear.Id, 'T1 ' + System.today().year(), 'Academic Term 1 ' + System.today().year(), STM_Helper.TYPE_SEMESTER, academicYear.reduivy__Start_Date__c, academicYear.reduivy__End_Date__c, null, null, null, null, false);
            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Study_Term__c>{academicTerm});

            testFactory.initStudentData(USR_Helper.getApiName(), true);

            reduivy__Study_Offering__c newOffering = new reduivy__Study_Offering__c();
            newOffering.Name = 'Test Study Offering';
            newOffering.reduivy__Academic_Term__c = academicTerm.Id;
            newOffering.reduivy__Campus__c = campus.Id;
            newOffering.reduivy__End_Date__c = Date.today();
            newOffering.reduivy__Listing_Image_URL__c = 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Image_created_with_a_mobile_phone.png/640px-Image_created_with_a_mobile_phone.png';
            newOffering.reduivy__Study_Unit__c = sun.Id;
            insert newOffering;

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_ContinuingEduDetail_LCTRL
     */
    @isTest   
    static void testForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Offering__c offeringRecord = [SELECT Id FROM reduivy__Study_Offering__c WHERE Name = 'Test Study Offering' LIMIT 1];

        System.runAs(ADMIN_USER){
            Test.startTest();
            REDU_LightningResponse response = REDU_ContinuingEduDetail_LCTRL.getObjectFields('reduivy__Study_Offering__c', offeringRecord.Id, 'reduivy__About__c');
            REDU_LightningResponse noSobjectNameResponse = REDU_ContinuingEduDetail_LCTRL.getObjectFields(null, offeringRecord.Id, 'reduivy__About__c');
            REDU_LightningResponse nullResponse = REDU_ContinuingEduDetail_LCTRL.getObjectFields('reduivy__Study_Offering__c', offeringRecord.Id, null);
            Test.stopTest();

            //Response
            System.Assert.areNotEqual(null, response.responseData);
            List<Object> fieldsArray = (List<Object>)JSON.deserializeUntyped(response.responseData);
            System.Assert.areEqual(1, fieldsArray.size());
            Map<String, Object> fieldObj = (Map<String, Object>)fieldsArray.get(0);
            System.Assert.areEqual('reduivy__About__c', fieldObj.get('fieldName'));
            System.Assert.areEqual('About', fieldObj.get('label'));
            System.Assert.areEqual('reduivy__Study_Offering__c', fieldObj.get('objectName'));

            //No sobject name response
            System.Assert.areNotEqual(null, noSobjectNameResponse.responseData);
            List<Object> noSobjectNameFieldsArray = (List<Object>)JSON.deserializeUntyped(noSobjectNameResponse.responseData);
            System.Assert.areEqual(1, noSobjectNameFieldsArray.size());
            Map<String, Object> noSobjectNameFieldObj = (Map<String, Object>)noSobjectNameFieldsArray.get(0);
            System.Assert.areEqual('reduivy__About__c', noSobjectNameFieldObj.get('fieldName'));
            System.Assert.areEqual('About', noSobjectNameFieldObj.get('label'));
            System.Assert.areEqual('reduivy__Study_Offering__c', noSobjectNameFieldObj.get('objectName'));

            //Null response
            System.Assert.areEqual(null, nullResponse.responseData);
        }
    }

    /**
     * @description Test with CE permission set for REDU_ContinuingEduDetail_LCTRL
     */
    @isTest   
    static void testForCePermissionSet() {
        User cePermSetUser = REDU_TestData_UTIL.newUser('RIO Ed', 'Ivy CE Permission Set', 'Standard User');
        insert cePermSetUser;

        REDU_SystemMode_UTIL.doInsert(REDU_TestData_UTIL.newPermissionSetAssignment(cePermSetUser.Id, new Set<String>{'REDU_CE_User'}));

        reduivy__Study_Offering__c offeringRecord = [SELECT Id FROM reduivy__Study_Offering__c WHERE Name = 'Test Study Offering' LIMIT 1];

        System.runAs(cePermSetUser){
            Test.startTest();
            REDU_LightningResponse response = REDU_ContinuingEduDetail_LCTRL.getObjectFields('reduivy__Study_Offering__c', offeringRecord.Id, 'reduivy__About__c');
            REDU_LightningResponse noSobjectNameResponse = REDU_ContinuingEduDetail_LCTRL.getObjectFields(null, offeringRecord.Id, 'reduivy__About__c');
            REDU_LightningResponse nullResponse = REDU_ContinuingEduDetail_LCTRL.getObjectFields('reduivy__Study_Offering__c', offeringRecord.Id, null);
            Test.stopTest();

            //Response
            System.Assert.areNotEqual(null, response.responseData);
            List<Object> fieldsArray = (List<Object>)JSON.deserializeUntyped(response.responseData);
            System.Assert.areEqual(1, fieldsArray.size());
            Map<String, Object> fieldObj = (Map<String, Object>)fieldsArray.get(0);
            System.Assert.areEqual('reduivy__About__c', fieldObj.get('fieldName'));
            System.Assert.areEqual('About', fieldObj.get('label'));
            System.Assert.areEqual('reduivy__Study_Offering__c', fieldObj.get('objectName'));

            //No sobject name response
            System.Assert.areNotEqual(null, noSobjectNameResponse.responseData);
            List<Object> noSobjectNameFieldsArray = (List<Object>)JSON.deserializeUntyped(noSobjectNameResponse.responseData);
            System.Assert.areEqual(1, noSobjectNameFieldsArray.size());
            Map<String, Object> noSobjectNameFieldObj = (Map<String, Object>)noSobjectNameFieldsArray.get(0);
            System.Assert.areEqual('reduivy__About__c', noSobjectNameFieldObj.get('fieldName'));
            System.Assert.areEqual('About', noSobjectNameFieldObj.get('label'));
            System.Assert.areEqual('reduivy__Study_Offering__c', noSobjectNameFieldObj.get('objectName'));

            //Null response
            System.Assert.areEqual(null, nullResponse.responseData);
        }
    }

    /**
     * @description Test as student for REDU_ContinuingEduDetail_LCTRL
     */
    @isTest   
    static void testForStudent() {
        User studentUser = testFactory.getStudentUser();

        reduivy__Study_Offering__c offeringRecord = [SELECT Id FROM reduivy__Study_Offering__c WHERE Name = 'Test Study Offering' LIMIT 1];

        System.runAs(studentUser){
            Test.startTest();
            REDU_LightningResponse response = REDU_ContinuingEduDetail_LCTRL.getObjectFields('reduivy__Study_Offering__c', offeringRecord.Id, 'reduivy__About__c');
            Test.stopTest();

            //Response
            System.Assert.areEqual(null, response.responseData);
        }
    }

    /**
     * @description Test as faculty for REDU_ContinuingEduDetail_LCTRL
     */
    @isTest   
    static void testForFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Study_Offering__c offeringRecord = [SELECT Id FROM reduivy__Study_Offering__c WHERE Name = 'Test Study Offering' LIMIT 1];

        System.runAs(FACULTY_USER){
            Test.startTest();
            REDU_LightningResponse response = REDU_ContinuingEduDetail_LCTRL.getObjectFields('reduivy__Study_Offering__c', offeringRecord.Id, 'reduivy__About__c');
            Test.stopTest();

            //Response
            System.Assert.areEqual(null, response.responseData);
        }
    }
}