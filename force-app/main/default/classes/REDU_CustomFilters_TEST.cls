/**
 * @author      WDCi (Jordan)
 * @date        Nov 2023
 * @group       Test
 * @description Test class for REDU_CustomFilters_LCTRL
 * @changehistory
 * 
 */
@isTest
public inherited sharing class REDU_CustomFilters_TEST {

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

            testFactory.initMasterData(null);
            testFactory.initOfferingData(SOF_Helper.getApiName());
            testFactory.initStudentData(IPE_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=reduivy__Class_Standing__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(ADMIN_USER){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            Test.stopTest();
            
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('PICKLIST', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Class_Standing__c IN: reduivy__Class_Standing__c', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Class Standing', customFiltersResponse[0].label);

            Schema.DescribeSObjectResult dsr = REDU_Metadata_UTIL.describeSObject(targetObjectType);
            Map<String, Schema.SObjectField> fieldsMap = dsr.fields.getMap();
            Schema.DescribeFieldResult targetDfr = fieldsMap.get(customFiltersResponse[0].targetFieldName.toLowerCase()).getDescribe();
            if (targetDfr.getType() == Schema.DisplayType.MULTIPICKLIST || targetDfr.getType() == Schema.DisplayType.PICKLIST) {
                System.Assert.areEqual(targetDfr.getPicklistValues().size() + 1, customFiltersResponse[0].picklistOptions.size());
            }
        }
    }

    /**
     * @description Test as admin for REDU_CustomFilters_LCTRL for string type field
     */
    @isTest   
    static void testForAdminForStringType() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Year__c=reduivy__Class_Year__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(ADMIN_USER){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            Test.stopTest();
            
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Class_Year__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Class_Year__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Class_Year__c LIKE: reduivy__Class_Year__c', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Class Year', customFiltersResponse[0].label);
        }
    }

    /**
     * @description Test as admin for REDU_CustomFilters_LCTRL for number type field
     */
    @isTest   
    static void testForAdminForNumberType() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Offering__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Units_Enrolled__c=reduivy__Available_Places__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(ADMIN_USER){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            Test.stopTest();
            
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Units_Enrolled__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Available_Places__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('DOUBLE', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('DOUBLE', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Available_Places__c =: reduivy__Units_Enrolled__c', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Available Places', customFiltersResponse[0].label);
        }
    }

    /**
     * @description Test as admin for REDU_CustomFilters_LCTRL for multipicklist type field
     */
    @isTest   
    static void testForAdminForMultipicklistType() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Transaction_Payment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Year__c=reduivy__Applicable_Item_Type__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(ADMIN_USER){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            Test.stopTest();
            
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Class_Year__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Applicable_Item_Type__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('MULTIPICKLIST', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Applicable_Item_Type__c INCLUDES ( :reduivy__Class_Year__c1 )', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Applicable Item Type', customFiltersResponse[0].label);
        }
    }

    /**
     * @description Test as admin for REDU_CustomFilters_LCTRL without none option for picklist
     */
    @isTest   
    static void testForAdminWithoutNoneOption() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=reduivy__Class_Standing__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(ADMIN_USER){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, false);
            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('PICKLIST', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Class_Standing__c IN: reduivy__Class_Standing__c', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Class Standing', customFiltersResponse[0].label);

            Schema.DescribeSObjectResult dsr = REDU_Metadata_UTIL.describeSObject(targetObjectType);
            Map<String, Schema.SObjectField> fieldsMap = dsr.fields.getMap();
            Schema.DescribeFieldResult targetDfr = fieldsMap.get(customFiltersResponse[0].targetFieldName.toLowerCase()).getDescribe();
            if (targetDfr.getType() == Schema.DisplayType.MULTIPICKLIST || targetDfr.getType() == Schema.DisplayType.PICKLIST) {
                System.Assert.areEqual(targetDfr.getPicklistValues().size(), customFiltersResponse[0].picklistOptions.size());
            }
        }
    }

    /**
     * @description Test as admin for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForAdminNoSourceRecordId() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=reduivy__Class_Standing__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(ADMIN_USER){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(null, sourceObjectType, targetObjectType, customFilterConfigs, true);
            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('PICKLIST', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Class_Standing__c IN: reduivy__Class_Standing__c', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Class Standing', customFiltersResponse[0].label);

            Schema.DescribeSObjectResult dsr = REDU_Metadata_UTIL.describeSObject(targetObjectType);
            Map<String, Schema.SObjectField> fieldsMap = dsr.fields.getMap();
            Schema.DescribeFieldResult targetDfr = fieldsMap.get(customFiltersResponse[0].targetFieldName.toLowerCase()).getDescribe();
            if (targetDfr.getType() == Schema.DisplayType.MULTIPICKLIST || targetDfr.getType() == Schema.DisplayType.PICKLIST) {
                System.Assert.areEqual(targetDfr.getPicklistValues().size() + 1, customFiltersResponse[0].picklistOptions.size());
            }
        }
    }

    /**
     * @description Test as admin for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForAdminNoTargetObjectOrCustomFilterConfigs() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=reduivy__Class_Standing__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(ADMIN_USER){
            Test.startTest();

            System.Assert.areEqual(null, REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, null, customFilterConfigs, true));
            System.Assert.areEqual(null, REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, null, true));

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForAdminNoMapping() {

        Boolean hasError = false;

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = null;
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        Test.startTest();
        try{
            System.runAs(ADMIN_USER){
                REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            }
        } catch (Exception exp) {

            REDU_Logging_UTIL.debug('testForAdminInvalidField', exp.getMessage());
            hasError = true;
        }
        Test.stopTest();

        System.Assert.areEqual(true, hasError);
    }

    /**
     * @description Test as admin for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForAdminBlankMapping() {

        Boolean hasError = false;

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = '';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        Test.startTest();
        try{
            System.runAs(ADMIN_USER){
                REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            }
        } catch (Exception exp) {

            REDU_Logging_UTIL.debug('testForAdminInvalidField', exp.getMessage());
            hasError = true;
        }
        Test.stopTest();

        System.Assert.areEqual(true, hasError);
    }

    /**
     * @description Test as admin for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForAdminInvalidMapping() {

        Boolean hasError = false;

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=reduivy__Class_Standing__c=INVALID_FIELD';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        Test.startTest();
        try{
            System.runAs(ADMIN_USER){
                REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            }
        } catch (Exception exp) {

            REDU_Logging_UTIL.debug('testForAdminInvalidField', exp.getMessage());
            hasError = true;
        }
        Test.stopTest();

        System.Assert.areEqual(true, hasError);
    }

    /**
     * @description Test as admin for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForAdminInvalidField() {

        Boolean hasError = false;

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=INVALID_FIELD';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        Test.startTest();
        try{
            System.runAs(ADMIN_USER){
                REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            }
        } catch (Exception exp) {

            REDU_Logging_UTIL.debug('testForAdminInvalidField', exp.getMessage());
            hasError = true;
        }
        Test.stopTest();

        System.Assert.areEqual(true, hasError);
    }

    /**
     * @description Test as student user for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForStudentUser() {

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=reduivy__Class_Standing__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(studentUser){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('PICKLIST', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Class_Standing__c IN: reduivy__Class_Standing__c', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Class Standing', customFiltersResponse[0].label);

            Schema.DescribeSObjectResult dsr = REDU_Metadata_UTIL.describeSObject(targetObjectType);
            Map<String, Schema.SObjectField> fieldsMap = dsr.fields.getMap();
            Schema.DescribeFieldResult targetDfr = fieldsMap.get(customFiltersResponse[0].targetFieldName.toLowerCase()).getDescribe();
            if (targetDfr.getType() == Schema.DisplayType.MULTIPICKLIST || targetDfr.getType() == Schema.DisplayType.PICKLIST) {
                System.Assert.areEqual(targetDfr.getPicklistValues().size() + 1, customFiltersResponse[0].picklistOptions.size());
            }
        }
    }

    /**
     * @description Test as student for REDU_CustomFilters_LCTRL for string type field
     */
    @isTest   
    static void testForStudentForStringType() {

        User studentUser = testFactory.getStudentUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Year__c=reduivy__Class_Year__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(studentUser){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            Test.stopTest();
            
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Class_Year__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Class_Year__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Class_Year__c LIKE: reduivy__Class_Year__c', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Class Year', customFiltersResponse[0].label);
        }
    }

    /**
     * @description Test as student for REDU_CustomFilters_LCTRL for number type field
     */
    @isTest   
    static void testForStudentForNumberType() {

        User studentUser = testFactory.getStudentUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Offering__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Units_Enrolled__c=reduivy__Available_Places__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(studentUser){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            Test.stopTest();
            
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Units_Enrolled__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Available_Places__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('DOUBLE', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('DOUBLE', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Available_Places__c =: reduivy__Units_Enrolled__c', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Available Places', customFiltersResponse[0].label);
        }
    }

    /**
     * @description Test as student for REDU_CustomFilters_LCTRL for multipicklist type field
     */
    @isTest   
    static void testForStudentForMultipicklistType() {

        User studentUser = testFactory.getStudentUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c = 'sandydoe@redu.example' LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Transaction_Payment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Year__c=reduivy__Applicable_Item_Type__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(studentUser){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            Test.stopTest();
            
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Class_Year__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Applicable_Item_Type__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('MULTIPICKLIST', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Applicable_Item_Type__c INCLUDES ( :reduivy__Class_Year__c1 )', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Applicable Item Type', customFiltersResponse[0].label);
        }
    }


    /**
     * @description Test as student user for REDU_CustomFilters_LCTRL without none option for picklist
     */
    @isTest   
    static void testForStudentUserWithoutNoneOption() {

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=reduivy__Class_Standing__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(studentUser){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, false);
            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('PICKLIST', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Class_Standing__c IN: reduivy__Class_Standing__c', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Class Standing', customFiltersResponse[0].label);

            Schema.DescribeSObjectResult dsr = REDU_Metadata_UTIL.describeSObject(targetObjectType);
            Map<String, Schema.SObjectField> fieldsMap = dsr.fields.getMap();
            Schema.DescribeFieldResult targetDfr = fieldsMap.get(customFiltersResponse[0].targetFieldName.toLowerCase()).getDescribe();
            if (targetDfr.getType() == Schema.DisplayType.MULTIPICKLIST || targetDfr.getType() == Schema.DisplayType.PICKLIST) {
                System.Assert.areEqual(targetDfr.getPicklistValues().size(), customFiltersResponse[0].picklistOptions.size());
            }
        }
    }

    /**
     * @description Test as student user for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForStudentUserNoSourceRecordId() {

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=reduivy__Class_Standing__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(studentUser){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(null, sourceObjectType, targetObjectType, customFilterConfigs, true);
            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('PICKLIST', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Class_Standing__c IN: reduivy__Class_Standing__c', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Class Standing', customFiltersResponse[0].label);

            Schema.DescribeSObjectResult dsr = REDU_Metadata_UTIL.describeSObject(targetObjectType);
            Map<String, Schema.SObjectField> fieldsMap = dsr.fields.getMap();
            Schema.DescribeFieldResult targetDfr = fieldsMap.get(customFiltersResponse[0].targetFieldName.toLowerCase()).getDescribe();
            if (targetDfr.getType() == Schema.DisplayType.MULTIPICKLIST || targetDfr.getType() == Schema.DisplayType.PICKLIST) {
                System.Assert.areEqual(targetDfr.getPicklistValues().size() + 1, customFiltersResponse[0].picklistOptions.size());
            }
        }
    }

    /**
     * @description Test as student for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForStudentNoTargetObjectOrCustomFilterConfigs() {

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];
        
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=reduivy__Class_Standing__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(studentUser){
            Test.startTest();

            System.Assert.areEqual(null, REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, null, customFilterConfigs, true));
            System.Assert.areEqual(null, REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, null, true));

            Test.stopTest();
        }
    }

    /**
     * @description Test as student for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForStudentNoMapping() {

        Boolean hasError = false;

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];
        
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = null;
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        Test.startTest();
        try{
            System.runAs(studentUser){
                REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            }
        } catch (Exception exp) {

            REDU_Logging_UTIL.debug('testForAdminInvalidField', exp.getMessage());
            hasError = true;
        }
        Test.stopTest();

        System.Assert.areEqual(true, hasError);
    }

    /**
     * @description Test as student for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForStudentBlankMapping() {

        Boolean hasError = false;

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];
        
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = '';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        Test.startTest();
        try{
            System.runAs(studentUser){
                REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            }
        } catch (Exception exp) {

            REDU_Logging_UTIL.debug('testForAdminInvalidField', exp.getMessage());
            hasError = true;
        }
        Test.stopTest();

        System.Assert.areEqual(true, hasError);
    }

    /**
     * @description Test as student for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForStudentInvalidMapping() {

        Boolean hasError = false;

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];
        
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=reduivy__Class_Standing__c=INVALID_FIELD';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        Test.startTest();
        try{
            System.runAs(studentUser){
                REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            }
        } catch (Exception exp) {

            REDU_Logging_UTIL.debug('testForAdminInvalidField', exp.getMessage());
            hasError = true;
        }
        Test.stopTest();

        System.Assert.areEqual(true, hasError);
    }

    /**
     * @description Test as student for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForStudentInvalidField() {

        Boolean hasError = false;

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];
        
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=INVALID_FIELD';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        Test.startTest();
        try{
            System.runAs(studentUser){
                REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            }
        } catch (Exception exp) {

            REDU_Logging_UTIL.debug('testForAdminInvalidField', exp.getMessage());
            hasError = true;
        }
        Test.stopTest();

        System.Assert.areEqual(true, hasError);
    }

    /**
     * @description Test as faculty user for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=reduivy__Class_Standing__c';
        customFilters.add(customFilter1);

        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(FACULTY_USER){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('PICKLIST', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Class_Standing__c IN: reduivy__Class_Standing__c', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Class Standing', customFiltersResponse[0].label);

            Schema.DescribeSObjectResult dsr = REDU_Metadata_UTIL.describeSObject(targetObjectType);
            Map<String, Schema.SObjectField> fieldsMap = dsr.fields.getMap();
            Schema.DescribeFieldResult targetDfr = fieldsMap.get(customFiltersResponse[0].targetFieldName.toLowerCase()).getDescribe();
            if (targetDfr.getType() == Schema.DisplayType.MULTIPICKLIST || targetDfr.getType() == Schema.DisplayType.PICKLIST) {
                System.Assert.areEqual(targetDfr.getPicklistValues().size() + 1, customFiltersResponse[0].picklistOptions.size());
            }
        }
    }

    /**
     * @description Test as faculty for REDU_CustomFilters_LCTRL for string type field
     */
    @isTest   
    static void testForFacultyForStringType() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Year__c=reduivy__Class_Year__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(FACULTY_USER){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            Test.stopTest();
            
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Class_Year__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Class_Year__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Class_Year__c LIKE: reduivy__Class_Year__c', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Class Year', customFiltersResponse[0].label);
        }
    }

    /**
     * @description Test as faculty for REDU_CustomFilters_LCTRL for number type field
     */
    @isTest   
    static void testForFacultyForNumberType() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Offering__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Units_Enrolled__c=reduivy__Available_Places__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(FACULTY_USER){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            Test.stopTest();
            
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Units_Enrolled__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Available_Places__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('DOUBLE', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('DOUBLE', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Available_Places__c =: reduivy__Units_Enrolled__c', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Available Places', customFiltersResponse[0].label);
        }
    }

    /**
     * @description Test as faculty for REDU_CustomFilters_LCTRL for multipicklist type field
     */
    @isTest   
    static void testForFacultyForMultipicklistType() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Transaction_Payment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Year__c=reduivy__Applicable_Item_Type__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(FACULTY_USER){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            Test.stopTest();
            
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Class_Year__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Applicable_Item_Type__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('MULTIPICKLIST', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Applicable_Item_Type__c INCLUDES ( :reduivy__Class_Year__c1 )', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Applicable Item Type', customFiltersResponse[0].label);
        }
    }


    /**
     * @description Test as faculty user for REDU_CustomFilters_LCTRL without none option for picklist
     */
    @isTest   
    static void testForFacultyUserWithoutNoneOption() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=reduivy__Class_Standing__c';
        customFilters.add(customFilter1);

        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(FACULTY_USER){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, false);
            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('PICKLIST', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Class_Standing__c IN: reduivy__Class_Standing__c', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Class Standing', customFiltersResponse[0].label);

            Schema.DescribeSObjectResult dsr = REDU_Metadata_UTIL.describeSObject(targetObjectType);
            Map<String, Schema.SObjectField> fieldsMap = dsr.fields.getMap();
            Schema.DescribeFieldResult targetDfr = fieldsMap.get(customFiltersResponse[0].targetFieldName.toLowerCase()).getDescribe();
            if (targetDfr.getType() == Schema.DisplayType.MULTIPICKLIST || targetDfr.getType() == Schema.DisplayType.PICKLIST) {
                System.Assert.areEqual(targetDfr.getPicklistValues().size(), customFiltersResponse[0].picklistOptions.size());
            }
        }
    }

    /**
     * @description Test as faculty user for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForFacultyUserNoSourceRecordId() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=reduivy__Class_Standing__c';
        customFilters.add(customFilter1);

        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(FACULTY_USER){
            Test.startTest();
            REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(null, sourceObjectType, targetObjectType, customFilterConfigs, true);
            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_CustomFilters_TEST');

            List<REDU_CustomFilter_OBJ> customFiltersResponse = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(objResponse.responseData, List<REDU_CustomFilter_OBJ>.class);
            System.Assert.areEqual(1, customFiltersResponse.size());
            System.Assert.areEqual(0, customFiltersResponse[0].seq);
            System.Assert.areEqual(customFilter1.showFilter, customFiltersResponse[0].showFilter);
            System.Assert.areEqual(customFilter1.mapping, customFiltersResponse[0].mapping);

            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].sourceFieldName);
            System.Assert.areEqual('reduivy__Class_Standing__c', customFiltersResponse[0].targetFieldName);
            System.Assert.areEqual(targetObjectType, customFiltersResponse[0].targetObjectType);
            System.Assert.areEqual('PICKLIST', customFiltersResponse[0].targetFieldType);
            System.Assert.areEqual('STRING', customFiltersResponse[0].targetSoapFieldType);
            System.Assert.areEqual('reduivy__Class_Standing__c IN: reduivy__Class_Standing__c', customFiltersResponse[0].getQueryBinder());
            System.Assert.areEqual('Class Standing', customFiltersResponse[0].label);

            Schema.DescribeSObjectResult dsr = REDU_Metadata_UTIL.describeSObject(targetObjectType);
            Map<String, Schema.SObjectField> fieldsMap = dsr.fields.getMap();
            Schema.DescribeFieldResult targetDfr = fieldsMap.get(customFiltersResponse[0].targetFieldName.toLowerCase()).getDescribe();
            if (targetDfr.getType() == Schema.DisplayType.MULTIPICKLIST || targetDfr.getType() == Schema.DisplayType.PICKLIST) {
                System.Assert.areEqual(targetDfr.getPicklistValues().size() + 1, customFiltersResponse[0].picklistOptions.size());
            }
        }
    }

    /**
     * @description Test as faculty for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForFacultyNoTargetObjectOrCustomFilterConfigs() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=reduivy__Class_Standing__c';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(FACULTY_USER){
            Test.startTest();

            System.Assert.areEqual(null, REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, null, customFilterConfigs, true));
            System.Assert.areEqual(null, REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, null, true));

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForFacultyNoMapping() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Boolean hasError = false;

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = null;
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        Test.startTest();
        try{
            System.runAs(FACULTY_USER){
                REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            }
        } catch (Exception exp) {

            REDU_Logging_UTIL.debug('testForAdminInvalidField', exp.getMessage());
            hasError = true;
        }
        Test.stopTest();

        System.Assert.areEqual(true, hasError);
    }

    /**
     * @description Test as faculty for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForFacultyBlankMapping() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Boolean hasError = false;

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = '';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        Test.startTest();
        try{
            System.runAs(FACULTY_USER){
                REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            }
        } catch (Exception exp) {

            REDU_Logging_UTIL.debug('testForAdminInvalidField', exp.getMessage());
            hasError = true;
        }
        Test.stopTest();

        System.Assert.areEqual(true, hasError);
    }

    /**
     * @description Test as faculty for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForFacultyInvalidMapping() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Boolean hasError = false;

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=reduivy__Class_Standing__c=INVALID_FIELD';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        Test.startTest();
        try{
            System.runAs(FACULTY_USER){
                REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            }
        } catch (Exception exp) {

            REDU_Logging_UTIL.debug('testForAdminInvalidField', exp.getMessage());
            hasError = true;
        }
        Test.stopTest();

        System.Assert.areEqual(true, hasError);
    }

    /**
     * @description Test as faculty for REDU_CustomFilters_LCTRL
     */
    @isTest   
    static void testForFacultyInvalidField() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Boolean hasError = false;

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        String sourceObjectType = 'reduivy__Individual_Program_Enrollment__c';
        String targetObjectType = 'reduivy__Study_Cohort_Enrollment__c';

        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter1 = new REDU_CustomFilter_OBJ();
        customFilter1.seq = 1;
        customFilter1.showFilter = true;
        customFilter1.mapping = 'reduivy__Class_Standing__c=INVALID_FIELD';
        customFilters.add(customFilter1);

        String customFilterConfigs = JSON.serialize(customFilters);

        Test.startTest();
        try{
            System.runAs(FACULTY_USER){
                REDU_LightningResponse objResponse = REDU_CustomFilters_LCTRL.initCustomFilterConfigs(masterIPE.Id, sourceObjectType, targetObjectType, customFilterConfigs, true);
            }
        } catch (Exception exp) {

            REDU_Logging_UTIL.debug('testForAdminInvalidField', exp.getMessage());
            hasError = true;
        }
        Test.stopTest();

        System.Assert.areEqual(true, hasError);
    }
}