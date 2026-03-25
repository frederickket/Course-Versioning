/**
 * @author      WDCi (Jordan)
 * @date        Mar 2024
 * @group       Test
 * @description Test class for REDU_ContinuingEduListing_LCTRL
 * @changehistory
 * ISS-001844 18-03-2024 Jordan - new test class
 */
@isTest
public inherited sharing class REDU_ContinuingEduListing_TEST {

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
            List<reduivy__Study_Unit__c> sunList = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 3];

            reduivy__Study_Offering__c newOffering1 = new reduivy__Study_Offering__c();
            newOffering1.Name = 'Test Study Offering 1';
            newOffering1.reduivy__About__c = 'About text 1';
            newOffering1.reduivy__Academic_Term__c = st.Id;
            newOffering1.reduivy__Campus__c = campus.Id;
            newOffering1.reduivy__Delivery_Method__c = 'Classroom';
            newOffering1.reduivy__End_Date__c = Date.today();
            newOffering1.reduivy__Listing_Image_URL__c = 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Image_created_with_a_mobile_phone.png/640px-Image_created_with_a_mobile_phone.png';
            newOffering1.reduivy__Listing_Status__c = 'Approved';
            newOffering1.reduivy__Start_Date__c = System.today();
            newOffering1.reduivy__Study_Unit__c = sunList[0].Id;
            insert newOffering1;

            reduivy__Study_Offering__c newOffering2 = new reduivy__Study_Offering__c();
            newOffering2.Name = 'Test Study Offering 2';
            newOffering2.reduivy__About__c = 'About text 2';
            newOffering2.reduivy__Academic_Term__c = st.Id;
            newOffering2.reduivy__Campus__c = campus.Id;
            newOffering2.reduivy__Delivery_Method__c = 'Online - Instructor Lead';
            newOffering2.reduivy__End_Date__c = Date.today();
            newOffering2.reduivy__Listing_Image_URL__c = 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Image_created_with_a_mobile_phone.png/640px-Image_created_with_a_mobile_phone.png';
            newOffering2.reduivy__Listing_Status__c = 'Approved';
            newOffering2.reduivy__Start_Date__c = System.today();
            newOffering2.reduivy__Study_Unit__c = sunList[1].Id;
            insert newOffering2;

            reduivy__Study_Offering__c newOffering3 = new reduivy__Study_Offering__c();
            newOffering3.Name = 'Test Study Offering 3';
            newOffering3.reduivy__About__c = 'About text 3';
            newOffering3.reduivy__Academic_Term__c = st.Id;
            newOffering3.reduivy__Campus__c = campus.Id;
            newOffering3.reduivy__Delivery_Method__c = 'Classroom';
            newOffering3.reduivy__End_Date__c = Date.today();
            newOffering3.reduivy__Listing_Image_URL__c = 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Image_created_with_a_mobile_phone.png/640px-Image_created_with_a_mobile_phone.png';
            newOffering3.reduivy__Listing_Status__c = 'Draft';
            newOffering3.reduivy__Start_Date__c = System.today();
            newOffering3.reduivy__Study_Unit__c = sunList[2].Id;
            insert newOffering3;

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_ContinuingEduListing_LCTRL
     */
    @isTest   
    static void testForAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Offering__c> offeringList = [SELECT Id FROM reduivy__Study_Offering__c];
        List<String> fieldApiNames = new List<String>{'reduivy__Delivery_Method__c', 'reduivy__Start_Date__c', 'reduivy__End_Date__c', 'reduivy__Offering_Type__c', 'reduivy__Listing_Image_URL__c'};
        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();

        REDU_CustomFilter_OBJ cf1 = new REDU_CustomFilter_OBJ();
        cf1.sourceFieldName = 'reduivy__Delivery_Method__c';
        cf1.targetFieldName = 'reduivy__Delivery_Method__c';
        cf1.targetFieldType = Schema.DisplayType.PICKLIST.name();
        cf1.sourceSobj = new reduivy__Study_Offering__c(reduivy__Delivery_Method__c = 'Classroom');
        customFilters.add(cf1);

        REDU_CustomFilter_OBJ cf2 = new REDU_CustomFilter_OBJ();
        cf2.sourceFieldName = 'reduivy__Start_Date__c';
        cf2.targetFieldName = 'reduivy__Start_Date__c';
        cf2.targetFieldType = Schema.DisplayType.DATE.name();
        cf2.sourceSobj = new reduivy__Study_Offering__c();
        customFilters.add(cf2);

        REDU_CustomFilter_OBJ cf3 = new REDU_CustomFilter_OBJ();
        cf3.sourceFieldName = 'reduivy__End_Date__c';
        cf3.targetFieldName = 'reduivy__End_Date__c';
        cf3.targetFieldType = Schema.DisplayType.DATE.name();
        cf3.sourceSobj = new reduivy__Study_Offering__c();
        customFilters.add(cf3);

        REDU_CustomFilter_OBJ cf4 = new REDU_CustomFilter_OBJ();
        cf4.sourceFieldName = 'reduivy__Offering_Type__c';
        cf4.targetFieldName = 'reduivy__Offering_Type__c';
        cf4.targetFieldType = Schema.DisplayType.PICKLIST.name();
        cf4.sourceSobj = new reduivy__Study_Offering__c();
        customFilters.add(cf4);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(ADMIN_USER){
            Test.startTest();
            REDU_LightningResponse noPredefinedFilterResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', null, 'Name', null, null, UserInfo.getLanguage());
            REDU_LightningResponse predefinedFilterResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', 'reduivy__Listing_Status__c = \'Approved\'', 'Name', null, null, UserInfo.getLanguage());
            REDU_LightningResponse searchWithoutPfResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', null, 'Name', 'Offering 1', null, UserInfo.getLanguage());
            REDU_LightningResponse searchWithPfResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', 'reduivy__Listing_Status__c = \'Approved\'', 'Name', 'Offering 1', null, UserInfo.getLanguage());
            REDU_LightningResponse filterWithoutPfResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', null, 'Name', null, customFilterConfigs, UserInfo.getLanguage());
            REDU_LightningResponse filterWithPfResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', 'reduivy__Listing_Status__c = \'Approved\'', 'Name', null, customFilterConfigs, UserInfo.getLanguage());
            REDU_LightningResponse nullResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', 'reduivy__Listing_Status__c = \'Approved\'', 'Name', 'Invalid search', null, UserInfo.getLanguage());
            Test.stopTest();

            //No predefined filter response
            System.Assert.areNotEqual(null, noPredefinedFilterResponse.responseData);
            Map<String, Object> noPredefinedFilterRecords = (Map<String, Object>)JSON.deserializeUntyped(noPredefinedFilterResponse.responseData);
            System.Assert.isTrue(noPredefinedFilterRecords.containsKey('rawData'), 'rawData should be existing! Actual: ' + JSON.serialize(noPredefinedFilterRecords.keySet()));
            List<Object> noPredefinedFilterRecordsRawData = (List<Object>) noPredefinedFilterRecords.get('rawData');
            System.Assert.areEqual(offeringList.size(), noPredefinedFilterRecordsRawData.size());

            //Predefined filter response
            System.Assert.areNotEqual(null, predefinedFilterResponse.responseData);
            Map<String, Object> predefinedFilterRecords = (Map<String, Object>)JSON.deserializeUntyped(predefinedFilterResponse.responseData);
            System.Assert.isTrue(predefinedFilterRecords.containsKey('rawData'), 'rawData should be existing! Actual: ' + JSON.serialize(predefinedFilterRecords.keySet()));
            List<Object> predefinedFilterRecordsRawData = (List<Object>) predefinedFilterRecords.get('rawData');
            System.Assert.areEqual(2, predefinedFilterRecordsRawData.size());

            //Search without predefined filter response
            System.Assert.areNotEqual(null, searchWithoutPfResponse.responseData);
            Map<String, Object> searchWithoutPfRecords = (Map<String, Object>)JSON.deserializeUntyped(searchWithoutPfResponse.responseData);
            System.Assert.isTrue(searchWithoutPfRecords.containsKey('rawData'), 'rawData should be existing! Actual: ' + JSON.serialize(searchWithoutPfRecords.keySet()));
            List<Object> searchWithoutPfRecordsRawDataRawData = (List<Object>) searchWithoutPfRecords.get('rawData');
            System.Assert.areEqual(1, searchWithoutPfRecordsRawDataRawData.size());
            
            //Search with predefined filter response
            System.Assert.areNotEqual(null, searchWithPfResponse.responseData);
            Map<String, Object> searchWithPfRecords = (Map<String, Object>)JSON.deserializeUntyped(searchWithPfResponse.responseData);
            System.Assert.isTrue(searchWithPfRecords.containsKey('rawData'), 'rawData should be existing! Actual: ' + JSON.serialize(searchWithPfRecords.keySet()));
            List<Object> searchWithPfRecordsRawData = (List<Object>) searchWithPfRecords.get('rawData');
            System.Assert.areEqual(1, searchWithPfRecordsRawData.size());

            //Filter without predefined filter response
            System.Assert.areNotEqual(null, filterWithoutPfResponse.responseData);
            Map<String, Object> filterWithoutPfRecords = (Map<String, Object>)JSON.deserializeUntyped(filterWithoutPfResponse.responseData);
            System.Assert.isTrue(filterWithoutPfRecords.containsKey('rawData'), 'rawData should be existing! Actual: ' + JSON.serialize(filterWithoutPfRecords.keySet()));
            List<Object> filterWithoutPfRecordsRawData = (List<Object>) filterWithoutPfRecords.get('rawData');
            System.Assert.areEqual(2, filterWithoutPfRecordsRawData.size());
            
            //Filter with predefined filter response
            System.Assert.areNotEqual(null, filterWithPfResponse.responseData);
            Map<String, Object> filterWithPfRecords = (Map<String, Object>)JSON.deserializeUntyped(filterWithPfResponse.responseData);
            System.Assert.isTrue(filterWithPfRecords.containsKey('rawData'), 'rawData should be existing! Actual: ' + JSON.serialize(filterWithPfRecords.keySet()));
            List<Object> filterWithPfRecordsRawData = (List<Object>) filterWithPfRecords.get('rawData');
            System.Assert.areEqual(1, filterWithPfRecordsRawData.size());

            //Null response
            System.Assert.areEqual(null, nullResponse.responseData);
        }
    }

    /**
     * @description Test with CE permission set for REDU_ContinuingEduListing_LCTRL
     */
    @isTest   
    static void testForCePermissionSet() {
        User cePermSetUser = REDU_TestData_UTIL.newUser('RIO Ed', 'Ivy CE Permission Set', 'Standard User');
        insert cePermSetUser;

        REDU_SystemMode_UTIL.doInsert(REDU_TestData_UTIL.newPermissionSetAssignment(cePermSetUser.Id, new Set<String>{'REDU_CE_User'}));

        List<reduivy__Study_Offering__c> offeringList = [SELECT Id FROM reduivy__Study_Offering__c];
        List<String> fieldApiNames = new List<String>{'reduivy__Delivery_Method__c', 'reduivy__Start_Date__c', 'reduivy__End_Date__c', 'reduivy__Offering_Type__c', 'reduivy__Listing_Image_URL__c'};
        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();

        REDU_CustomFilter_OBJ cf1 = new REDU_CustomFilter_OBJ();
        cf1.sourceFieldName = 'reduivy__Delivery_Method__c';
        cf1.targetFieldName = 'reduivy__Delivery_Method__c';
        cf1.targetFieldType = Schema.DisplayType.PICKLIST.name();
        cf1.sourceSobj = new reduivy__Study_Offering__c(reduivy__Delivery_Method__c = 'Classroom');
        customFilters.add(cf1);

        REDU_CustomFilter_OBJ cf2 = new REDU_CustomFilter_OBJ();
        cf2.sourceFieldName = 'reduivy__Start_Date__c';
        cf2.targetFieldName = 'reduivy__Start_Date__c';
        cf2.targetFieldType = Schema.DisplayType.DATE.name();
        cf2.sourceSobj = new reduivy__Study_Offering__c();
        customFilters.add(cf2);

        REDU_CustomFilter_OBJ cf3 = new REDU_CustomFilter_OBJ();
        cf3.sourceFieldName = 'reduivy__End_Date__c';
        cf3.targetFieldName = 'reduivy__End_Date__c';
        cf3.targetFieldType = Schema.DisplayType.DATE.name();
        cf3.sourceSobj = new reduivy__Study_Offering__c();
        customFilters.add(cf3);

        REDU_CustomFilter_OBJ cf4 = new REDU_CustomFilter_OBJ();
        cf4.sourceFieldName = 'reduivy__Offering_Type__c';
        cf4.targetFieldName = 'reduivy__Offering_Type__c';
        cf4.targetFieldType = Schema.DisplayType.PICKLIST.name();
        cf4.sourceSobj = new reduivy__Study_Offering__c();
        customFilters.add(cf4);

        String customFilterConfigs = JSON.serialize(customFilters);

        System.runAs(cePermSetUser){
            Test.startTest();
            REDU_LightningResponse noPredefinedFilterResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', null, 'Name', null, null, UserInfo.getLanguage());
            REDU_LightningResponse predefinedFilterResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', 'reduivy__Listing_Status__c = \'Approved\'', 'Name', null, null, UserInfo.getLanguage());
            REDU_LightningResponse searchWithoutPfResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', null, 'Name', 'Offering 1', null, UserInfo.getLanguage());
            REDU_LightningResponse searchWithPfResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', 'reduivy__Listing_Status__c = \'Approved\'', 'Name', 'Offering 1', null, UserInfo.getLanguage());
            REDU_LightningResponse filterWithoutPfResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', null, 'Name', null, customFilterConfigs, UserInfo.getLanguage());
            REDU_LightningResponse filterWithPfResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', 'reduivy__Listing_Status__c = \'Approved\'', 'Name', null, customFilterConfigs, UserInfo.getLanguage());
            REDU_LightningResponse nullResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', 'reduivy__Listing_Status__c = \'Approved\'', 'Name', 'Invalid search', null, UserInfo.getLanguage());
            Test.stopTest();

            //No predefined filter response
            System.Assert.areNotEqual(null, noPredefinedFilterResponse.responseData);
            Map<String, Object> noPredefinedFilterRecords = (Map<String, Object>)JSON.deserializeUntyped(noPredefinedFilterResponse.responseData);
            System.Assert.isTrue(noPredefinedFilterRecords.containsKey('rawData'), 'rawData should be existing! Actual: ' + JSON.serialize(noPredefinedFilterRecords.keySet()));
            List<Object> noPredefinedFilterRecordsRawData = (List<Object>) noPredefinedFilterRecords.get('rawData');
            System.Assert.areEqual(offeringList.size(), noPredefinedFilterRecordsRawData.size());

            //Predefined filter response
            System.Assert.areNotEqual(null, predefinedFilterResponse.responseData);
            Map<String, Object> predefinedFilterRecords = (Map<String, Object>)JSON.deserializeUntyped(predefinedFilterResponse.responseData);
            System.Assert.isTrue(predefinedFilterRecords.containsKey('rawData'), 'rawData should be existing! Actual: ' + JSON.serialize(predefinedFilterRecords.keySet()));
            List<Object> predefinedFilterRecordsRawData = (List<Object>) predefinedFilterRecords.get('rawData');
            System.Assert.areEqual(2, predefinedFilterRecordsRawData.size());

            //Search without predefined filter response
            System.Assert.areNotEqual(null, searchWithoutPfResponse.responseData);
            Map<String, Object> searchWithoutPfRecords = (Map<String, Object>)JSON.deserializeUntyped(searchWithoutPfResponse.responseData);
            System.Assert.isTrue(searchWithoutPfRecords.containsKey('rawData'), 'rawData should be existing! Actual: ' + JSON.serialize(searchWithoutPfRecords.keySet()));
            List<Object> searchWithoutPfRecordsRawData = (List<Object>) searchWithoutPfRecords.get('rawData');
            System.Assert.areEqual(1, searchWithoutPfRecordsRawData.size());
            
            //Search with predefined filter response
            System.Assert.areNotEqual(null, searchWithPfResponse.responseData);
            Map<String, Object> searchWithPfRecords = (Map<String, Object>)JSON.deserializeUntyped(searchWithPfResponse.responseData);
            System.Assert.isTrue(searchWithPfRecords.containsKey('rawData'), 'rawData should be existing! Actual: ' + JSON.serialize(searchWithPfRecords.keySet()));
            List<Object> searchWithPfRecordsRawData = (List<Object>) searchWithPfRecords.get('rawData');
            System.Assert.areEqual(1, searchWithPfRecordsRawData.size());

            //Filter without predefined filter response
            System.Assert.areNotEqual(null, filterWithoutPfResponse.responseData);
            Map<String, Object> filterWithoutPfRecords = (Map<String, Object>)JSON.deserializeUntyped(filterWithoutPfResponse.responseData);
            System.Assert.isTrue(filterWithoutPfRecords.containsKey('rawData'), 'rawData should be existing! Actual: ' + JSON.serialize(filterWithoutPfRecords.keySet()));
            List<Object> filterWithoutPfRecordsRawData = (List<Object>) filterWithoutPfRecords.get('rawData');
            System.Assert.areEqual(2, filterWithoutPfRecordsRawData.size());
            
            //Filter with predefined filter response
            System.Assert.areNotEqual(null, filterWithPfResponse.responseData);
            Map<String, Object> filterWithPfRecords = (Map<String, Object>)JSON.deserializeUntyped(filterWithPfResponse.responseData);
            System.Assert.isTrue(filterWithPfRecords.containsKey('rawData'), 'rawData should be existing! Actual: ' + JSON.serialize(filterWithPfRecords.keySet()));
            List<Object> filterWithPfRecordsRawData = (List<Object>) filterWithPfRecords.get('rawData');
            System.Assert.areEqual(1, filterWithPfRecordsRawData.size());

            //Null response
            System.Assert.areEqual(null, nullResponse.responseData);
        }
    }

    /**
     * @description Test as student for REDU_ContinuingEduListing_LCTRL
     */
    @isTest   
    static void testForStudent() {
        User studentUser = testFactory.getStudentUser();

        List<reduivy__Study_Offering__c> offeringList = [SELECT Id FROM reduivy__Study_Offering__c];
        List<String> fieldApiNames = new List<String>{'reduivy__Delivery_Method__c', 'reduivy__Start_Date__c', 'reduivy__End_Date__c', 'reduivy__Offering_Type__c', 'reduivy__Listing_Image_URL__c'};
        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();

        REDU_CustomFilter_OBJ cf1 = new REDU_CustomFilter_OBJ();
        cf1.sourceFieldName = 'reduivy__Delivery_Method__c';
        cf1.targetFieldName = 'reduivy__Delivery_Method__c';
        cf1.targetFieldType = Schema.DisplayType.PICKLIST.name();
        cf1.sourceSobj = new reduivy__Study_Offering__c(reduivy__Delivery_Method__c = 'Classroom');
        customFilters.add(cf1);

        REDU_CustomFilter_OBJ cf2 = new REDU_CustomFilter_OBJ();
        cf2.sourceFieldName = 'reduivy__Start_Date__c';
        cf2.targetFieldName = 'reduivy__Start_Date__c';
        cf2.targetFieldType = Schema.DisplayType.DATE.name();
        cf2.sourceSobj = new reduivy__Study_Offering__c();
        customFilters.add(cf2);

        REDU_CustomFilter_OBJ cf3 = new REDU_CustomFilter_OBJ();
        cf3.sourceFieldName = 'reduivy__End_Date__c';
        cf3.targetFieldName = 'reduivy__End_Date__c';
        cf3.targetFieldType = Schema.DisplayType.DATE.name();
        cf3.sourceSobj = new reduivy__Study_Offering__c();
        customFilters.add(cf3);

        REDU_CustomFilter_OBJ cf4 = new REDU_CustomFilter_OBJ();
        cf4.sourceFieldName = 'reduivy__Offering_Type__c';
        cf4.targetFieldName = 'reduivy__Offering_Type__c';
        cf4.targetFieldType = Schema.DisplayType.PICKLIST.name();
        cf4.sourceSobj = new reduivy__Study_Offering__c();
        customFilters.add(cf4);

        String customFilterConfigs = JSON.serialize(customFilters);

        Test.startTest();
        try {
            System.runAs(studentUser){
                REDU_LightningResponse noPredefinedFilterResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', null, 'Name', null, null, UserInfo.getLanguage());
                REDU_LightningResponse predefinedFilterResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', 'reduivy__Listing_Status__c = \'Approved\'', 'Name', null, null, UserInfo.getLanguage());
                REDU_LightningResponse searchWithoutPfResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', null, 'Name', 'Offering 1', null, UserInfo.getLanguage());
                REDU_LightningResponse searchWithPfResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', 'reduivy__Listing_Status__c = \'Approved\'', 'Name', 'Offering 1', null, UserInfo.getLanguage());
                REDU_LightningResponse filterWithoutPfResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', null, 'Name', null, customFilterConfigs, UserInfo.getLanguage());
                REDU_LightningResponse filterWithPfResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', 'reduivy__Listing_Status__c = \'Approved\'', 'Name', null, customFilterConfigs, UserInfo.getLanguage());
                REDU_LightningResponse nullResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', 'reduivy__Listing_Status__c = \'Approved\'', 'Name', 'Invalid search', null, UserInfo.getLanguage());
            }
            System.Assert.fail('This should fail.');
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s)'), 'The exception is invalid: ' + exp.getMessage());
        }
        Test.stopTest();
    }

    /**
     * @description Test as faculty for REDU_ContinuingEduListing_LCTRL
     */
    @isTest   
    static void testForFaculty() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<reduivy__Study_Offering__c> offeringList = [SELECT Id FROM reduivy__Study_Offering__c];
        List<String> fieldApiNames = new List<String>{'reduivy__Delivery_Method__c', 'reduivy__Start_Date__c', 'reduivy__End_Date__c', 'reduivy__Offering_Type__c', 'reduivy__Listing_Image_URL__c'};
        List<REDU_CustomFilter_OBJ> customFilters = new List<REDU_CustomFilter_OBJ>();

        REDU_CustomFilter_OBJ cf1 = new REDU_CustomFilter_OBJ();
        cf1.sourceFieldName = 'reduivy__Delivery_Method__c';
        cf1.targetFieldName = 'reduivy__Delivery_Method__c';
        cf1.targetFieldType = Schema.DisplayType.PICKLIST.name();
        cf1.sourceSobj = new reduivy__Study_Offering__c(reduivy__Delivery_Method__c = 'Classroom');
        customFilters.add(cf1);

        REDU_CustomFilter_OBJ cf2 = new REDU_CustomFilter_OBJ();
        cf2.sourceFieldName = 'reduivy__Start_Date__c';
        cf2.targetFieldName = 'reduivy__Start_Date__c';
        cf2.targetFieldType = Schema.DisplayType.DATE.name();
        cf2.sourceSobj = new reduivy__Study_Offering__c();
        customFilters.add(cf2);

        REDU_CustomFilter_OBJ cf3 = new REDU_CustomFilter_OBJ();
        cf3.sourceFieldName = 'reduivy__End_Date__c';
        cf3.targetFieldName = 'reduivy__End_Date__c';
        cf3.targetFieldType = Schema.DisplayType.DATE.name();
        cf3.sourceSobj = new reduivy__Study_Offering__c();
        customFilters.add(cf3);

        REDU_CustomFilter_OBJ cf4 = new REDU_CustomFilter_OBJ();
        cf4.sourceFieldName = 'reduivy__Offering_Type__c';
        cf4.targetFieldName = 'reduivy__Offering_Type__c';
        cf4.targetFieldType = Schema.DisplayType.PICKLIST.name();
        cf4.sourceSobj = new reduivy__Study_Offering__c();
        customFilters.add(cf4);

        String customFilterConfigs = JSON.serialize(customFilters);

        Test.startTest();
        try {
            System.runAs(FACULTY_USER){
                REDU_LightningResponse noPredefinedFilterResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', null, 'Name', null, null, UserInfo.getLanguage());
                REDU_LightningResponse predefinedFilterResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', 'reduivy__Listing_Status__c = \'Approved\'', 'Name', null, null, UserInfo.getLanguage());
                REDU_LightningResponse searchWithoutPfResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', null, 'Name', 'Offering 1', null, UserInfo.getLanguage());
                REDU_LightningResponse searchWithPfResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', 'reduivy__Listing_Status__c = \'Approved\'', 'Name', 'Offering 1', null, UserInfo.getLanguage());
                REDU_LightningResponse filterWithoutPfResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', null, 'Name', null, customFilterConfigs, UserInfo.getLanguage());
                REDU_LightningResponse filterWithPfResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', 'reduivy__Listing_Status__c = \'Approved\'', 'Name', null, customFilterConfigs, UserInfo.getLanguage());
                REDU_LightningResponse nullResponse = REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords('reduivy__Study_Offering__c', fieldApiNames, 'reduivy__Census_Date__c', 'Name', 'reduivy__Listing_Status__c = \'Approved\'', 'Name', 'Invalid search', null, UserInfo.getLanguage());
            }
            System.Assert.fail('This should fail.');
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s)'), 'The exception is invalid: ' + exp.getMessage());
        }
        Test.stopTest();
    }
}