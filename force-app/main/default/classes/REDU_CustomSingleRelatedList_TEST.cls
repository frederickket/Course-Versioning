/**
 * @author      WDCi (XW)
 * @date        Dec 2024
 * @group       Test
 * @description Test class for REDU_CustomSingleRelatedList_LCTRL
 * @changehistory
 * ISS-002104 03-12-2024 XW - create new class
 * ISS-002736 25-11-2025 XiRouh - added enableWrapText param
 */
@IsTest
public inherited sharing class REDU_CustomSingleRelatedList_TEST {
    //for request
    public static final String RECORD_ID_PARAM = 'recordId';
    public static final String TARGET_RECORD_ID_PARAM = 'targetRecordIdField';
    public static final String PARENT_OBJECT_REF_FIELD_PARAM = 'parentObjectRefField';
    public static final String CHILD_OBJECT_API_NAME_PARAM = 'childObjectApiName';
    public static final String CHILD_OBJECT_FIELDS_PARAM = 'childObjectFields';
    public static final String CHILD_OBJECT_FILTER_CRITERIA_PARAM = 'childObjectFilterCriteria';
    public static final String ENABLE_VIEW_PARAM = 'enableRowViewButton';
    public static final String ENABLE_EDIT_PARAM = 'enableRowEditButton';
    public static final String ENABLE_DELETE_PARAM = 'enableRowDeleteButton';
    public static final String ENABLE_DOWNLOAD_PARAM = 'enableRowDownloadButton';
    public static final String REFERENCE_TARGET = 'refTarget';

    public static final String ROWS_TO_LOAD_PARAM = 'rowsToLoad';
    public static final String CURRENT_OFFSET_PARAM = 'currentOffset';

    public static final String ENABLE_CLICKABLE_REFFIELD_PARAM = 'enableClickableRefField';

    public static final String ENABLE_INLINE_EDIT_PARAM = 'enableInlineEditing';
    public static final String USE_SOURCE_COLLECTION_RECORDS = 'useSourceCollectionRecords';

    public static final String WRAPTEXT_PARAM = 'wrapText';

    //for response
    public static final String COLUMNS_PARAM = 'columns';
    public static final String RECORDS_PARAM = 'records';
    public static final String OBJECT_ICON_PARAM = 'objectIcon';
    public static final String REFLINKS_PARAM = 'refLinks';
    public static final String IS_COMMUNITY_PARAM = 'isCommunity';
    public static final String SITE_PATH_PARAM = 'sitePath';
    public static final String BASE_URL_PARAM = 'baseURL';

    public static final String LINK_FIELD_NAME_PARAM = 'linkFieldName';
    public static final String LINK_FIELD_ID_PARAM = 'linkFieldId';
    public static final String LINK_FIELD_LABEL_PARAM = 'linkFieldLabel';
    
    //sample record code
    public static final String SAMPLE_RECORD_CODE_STUDENT = 'johndoe@redu.example';
    public static final String SAMPLE_RECORD_CODE_SOF = 'BUS101_CYT1_SYDNEY';
    public static final String SAMPLE_RECORD_CODE_EDUINST = 'RIOUNI';

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
        	
            testFactory.initSampleData(SPL_Helper.getApiName(), USR_Helper.getApiName(), IEN_Helper.getApiName(), IPE_Helper.getApiName(), true, true);
            
            Test.stopTest();
		}

    }

    /**
     * @description Test as admin with multi currencies enabled
     * This test is simulating the scenario where the component is used in a record page,
     * infinite loading is enable, all row action is enabled, row number == 10, criteria is set (reduivy__Study_Offering__r.Name LIKE 'BUS%')
     * 
     */
    @IsTest
    static void testAsAdminForRecordIdProvidedWithMultiCurrencies() {
        
        if (!ORG_Helper.isMultiCurrenciesOrg()) {
            //we won't run this test in non multi currencies org as it will fail
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();

        Integer rowsToLoad = 10;
        Integer currentOffset = 0;
        String filterCriteria = 'Name LIKE \'BUS101%\'';
        reduivy__Study_Term__c targetTerm = [SELECT Id
            FROM reduivy__Study_Term__c
            WHERE reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            LIMIT 1
        ];

        Map<Id, reduivy__Study_Offering__c> expectedDataMap = new Map<Id, reduivy__Study_Offering__c>();
        for(reduivy__Study_Offering__c sof : [SELECT Id
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c = :targetTerm.Id
            AND Name LIKE 'BUS101%'
            LIMIT :rowsToLoad
        ]) {
            expectedDataMap.put(sof.Id, sof);
        }

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            String datatableConfig = getDatatableConfig(targetTerm.Id, 'Id', 'reduivy__Academic_Term__c', SOF_Helper.getApiName(), 'Name;reduivy__Fee_Amount__c', filterCriteria, rowsToLoad, currentOffset, true, true, true, true, true, true, '_blank', false, true);

            REDU_LightningResponse response = REDU_CustomSingleRelatedList_LCTRL.initDatatable(datatableConfig);
            
            System.Assert.isFalse(String.isBlank(response.responseData),'responseData should not be blank');

            Map<String, Object> responseJSON = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            
            String dataString = String.valueOf(responseJSON.get(RECORDS_PARAM));
            currentOffset = Integer.valueOf(responseJSON.get(CURRENT_OFFSET_PARAM));
            List<Object> columns = (List<Object>) responseJSON.get(COLUMNS_PARAM);
            String objectIcon = String.valueOf(responseJSON.get(OBJECT_ICON_PARAM));
            String refLinks = String.valueOf(responseJSON.get(REFLINKS_PARAM));
            Boolean isCommunity = Boolean.valueOf(responseJSON.get(IS_COMMUNITY_PARAM));
            String sitePath = String.valueOf(responseJSON.get(SITE_PATH_PARAM));
            String baseUrl = String.valueOf(responseJSON.get(BASE_URL_PARAM));

            REDU_Logging_UTIL.debug('dataString', dataString);
            List<reduivy__Study_Offering__c> dataList = (List<reduivy__Study_Offering__c>) JSON.deserialize(dataString, List<reduivy__Study_Offering__c>.class);

            String columnsMetadataString = JSON.serialize(columns);
            System.Assert.isTrue(columnsMetadataString.contains(REDU_SObject_UTIL.CURRENCYISOCODE_FIELD), 'The CurrencyIsoCode should exist in the typeAttributes');

            //data
            System.Assert.areEqual(expectedDataMap.keySet().size(), dataList.size(), 'Data size should be equal');
            for(reduivy__Study_Offering__c returnSof : dataList) {
                System.Assert.isTrue(expectedDataMap.keySet().contains(returnSof.Id), returnSof.Id + 'is not expected to be in the list!');
                System.Assert.isTrue(returnSof.isSet('CurrencyIsoCode'), 'The CurrencyIsoCode is not found.');
            }
            
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin
     * This test is simulating the scenario where the component is used in a record page,
     * infinite loading is enable, all row action is enabled, row number == 10, criteria is set (reduivy__Study_Offering__r.Name LIKE 'BUS%')
     * 
     */
    @IsTest
    static void testAsAdminForRecordIdProvided() {

        
        User ADMIN_USER = testFactory.getReduAdminUser();
        Integer rowsToLoad = 10;
        Integer currentOffset = 0;
        String filterCriteria = 'reduivy__Study_Offering__r.Name LIKE \'BUS%\'';
        Contact targetStudent = [SELECT Id
                                FROM Contact
                                WHERE reduivy__Sample_Record_Code__c = :SAMPLE_RECORD_CODE_STUDENT
                                LIMIT 1];

        Map<Id, reduivy__Individual_Enrollment__c> expectedDataMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        for(reduivy__Individual_Enrollment__c ien : [SELECT Id
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :targetStudent.Id
            AND reduivy__Study_Offering__r.Name LIKE 'BUS%'
            LIMIT :rowsToLoad]) {
                expectedDataMap.put(ien.Id, ien);
        }

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            String datatableConfig = getDatatableConfig(targetStudent.Id, 'Id', 'reduivy__Contact__c', IEN_Helper.getApiName(), 'Name;reduivy__Contact__c;reduivy__Attempt_Number__c;reduivy__Study_Offering__c', filterCriteria, rowsToLoad, currentOffset, true, true, true, true, true, true, '_blank', false, true);

            REDU_LightningResponse response = REDU_CustomSingleRelatedList_LCTRL.initDatatable(datatableConfig);
            
            System.Assert.isFalse(String.isBlank(response.responseData),'responseData should not be blank');

            Map<String, Object> responseJSON = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            
            String dataString = String.valueOf(responseJSON.get(RECORDS_PARAM));
            currentOffset = Integer.valueOf(responseJSON.get(CURRENT_OFFSET_PARAM));
            List<Object> columns = (List<Object>) responseJSON.get(COLUMNS_PARAM);
            String objectIcon = String.valueOf(responseJSON.get(OBJECT_ICON_PARAM));
            String refLinks = String.valueOf(responseJSON.get(REFLINKS_PARAM));
            Boolean isCommunity = Boolean.valueOf(responseJSON.get(IS_COMMUNITY_PARAM));
            String sitePath = String.valueOf(responseJSON.get(SITE_PATH_PARAM));
            String baseUrl = String.valueOf(responseJSON.get(BASE_URL_PARAM));

            REDU_Logging_UTIL.debug('dataString', dataString);
            List<reduivy__Individual_Enrollment__c> dataList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(dataString, List<reduivy__Individual_Enrollment__c>.class);

            //data
            System.Assert.areEqual(expectedDataMap.keySet().size(), dataList.size(), 'Data size should be equal');
            for(reduivy__Individual_Enrollment__c actualIen : dataList) {
                System.Assert.isTrue(expectedDataMap.keySet().contains(actualIen.Id), actualIen.Id + 'is not expected to be in the list!');
            }

            //columns
            List<REDU_Datatable_UTIL.TableActionWrapper> actionWrapper = getActionWrapper(true, true, true, true, false);
            JSONGenerator columnsGen = JSON.createGenerator(false);
            REDU_Datatable_UTIL.generateTableColMetadata(columnsGen, reduivy__Individual_Enrollment__c.getSObjectType(), 'Name;reduivy__Contact__c;reduivy__Attempt_Number__c;reduivy__Study_Offering__c', false, actionWrapper, true, '_blank', true, true);
            System.Assert.areEqual(columnsGen.getAsString(), JSON.serialize(columns), 'Columns should be equal');


            System.Assert.areEqual(currentOffset, dataList.size(), 'Current Offset should be 10');
            System.Assert.areEqual(objectIcon, 'custom:custom27', 'Object icon should be custom:custom27');
            System.Assert.areEqual(isCommunity, false, 'Is community should be false');
            System.Assert.areEqual(sitePath, ORG_Helper.getCurrentCommunitySitePath(), 'Unexpected site path');
            System.Assert.areEqual(baseUrl, URL.getOrgDomainUrl().toExternalForm(), 'Unexpected base url');
            
            

            //load another 10 records
            expectedDataMap = new Map<Id, reduivy__Individual_Enrollment__c>();
            for(reduivy__Individual_Enrollment__c ien : [SELECT Id
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :targetStudent.Id
                AND reduivy__Study_Offering__r.Name LIKE 'BUS%'
                LIMIT :rowsToLoad
                OFFSET :currentOffset]) {
                    expectedDataMap.put(ien.Id, ien);
            }
            datatableConfig = getDatatableConfig(targetStudent.Id, 'Id', 'reduivy__Contact__c', IEN_Helper.getApiName(), 'Name;reduivy__Contact__c;reduivy__Attempt_Number__c;reduivy__Study_Offering__c', filterCriteria, rowsToLoad, currentOffset, true, true, true, true, true, true, '_blank', false, true);
            response = REDU_CustomSingleRelatedList_LCTRL.initDatatable(datatableConfig);

            System.Assert.isFalse(String.isBlank(response.responseData),'responseData should not be blank');

            responseJSON = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            
            dataString = String.valueOf(responseJSON.get(RECORDS_PARAM));
            currentOffset = Integer.valueOf(responseJSON.get(CURRENT_OFFSET_PARAM));
            columns = (List<Object>) responseJSON.get(COLUMNS_PARAM);
            objectIcon = String.valueOf(responseJSON.get(OBJECT_ICON_PARAM));
            refLinks = String.valueOf(responseJSON.get(REFLINKS_PARAM));
            isCommunity = Boolean.valueOf(responseJSON.get(IS_COMMUNITY_PARAM));
            sitePath = String.valueOf(responseJSON.get(SITE_PATH_PARAM));
            baseUrl = String.valueOf(responseJSON.get(BASE_URL_PARAM));

            REDU_Logging_UTIL.debug('dataString', dataString);
            List<reduivy__Individual_Enrollment__c> dataList2 = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(dataString, List<reduivy__Individual_Enrollment__c>.class);

            //data
            System.Assert.areEqual(expectedDataMap.keySet().size(), dataList2.size(), 'Data size should be equal');
            for(reduivy__Individual_Enrollment__c actualIen : dataList2) {
                System.Assert.isTrue(expectedDataMap.keySet().contains(actualIen.Id), actualIen.Id + 'is not expected to be in the list!');
            }

            //columns
            columnsGen = JSON.createGenerator(false);
            REDU_Datatable_UTIL.generateTableColMetadata(columnsGen, reduivy__Individual_Enrollment__c.getSObjectType(), 'Name;reduivy__Contact__c;reduivy__Attempt_Number__c;reduivy__Study_Offering__c', false, actionWrapper, true, '_blank', true, true);
            System.Assert.areEqual(columnsGen.getAsString(), JSON.serialize(columns), 'Columns should be equal');

            System.Assert.areEqual(currentOffset, dataList.size() + dataList2.size(), 'Current Offset should be 20');
            System.Assert.areEqual(objectIcon, 'custom:custom27', 'Object icon should be custom:custom27');
            System.Assert.areEqual(isCommunity, false, 'Is community should be false');
            System.Assert.areEqual(sitePath, ORG_Helper.getCurrentCommunitySitePath(), 'Unexpected site path');
            System.Assert.areEqual(baseUrl, URL.getOrgDomainUrl().toExternalForm(), 'Unexpected base url');
            
            
		}

        Test.stopTest();
		
    }
    
    /**
     * @description Test as admin
     * This test is simulating the scenario where the component is used in a flow page and no data query is need,
     * all row action is enabled
     * 
     */
    @IsTest
    static void testAsAdminForRecordIdNotProvided() {

        
        User ADMIN_USER = testFactory.getReduAdminUser();
        Contact targetStudent = [SELECT Id
                                FROM Contact
                                WHERE reduivy__Sample_Record_Code__c = :SAMPLE_RECORD_CODE_STUDENT
                                LIMIT 1];

        Map<Id, reduivy__Individual_Enrollment__c> expectedDataMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        for(reduivy__Individual_Enrollment__c ien : [SELECT Id
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :targetStudent.Id]) {
                expectedDataMap.put(ien.Id, ien);
        }

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            String datatableConfig = getDatatableConfig(null, 'Id', 'reduivy__Contact__c', IEN_Helper.getApiName(), 'Name;reduivy__Contact__c;reduivy__Attempt_Number__c;reduivy__Study_Offering__c', '', 0, 0, true, true, true, true, true, true, '_blank', true, true);

            REDU_LightningResponse response = REDU_CustomSingleRelatedList_LCTRL.initDatatable(datatableConfig);
            
            System.Assert.isFalse(String.isBlank(response.responseData),'responseData should not be blank');

            Map<String, Object> responseJSON = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            
            
            String dataString = String.valueOf(responseJSON.get(RECORDS_PARAM));
            Integer currentOffset = Integer.valueOf(responseJSON.get(CURRENT_OFFSET_PARAM));
            System.Assert.isTrue(String.isBlank(dataString), 'Should not be querying any data');
            System.Assert.areEqual(null, currentOffset, 'Should not be querying any data');
            
            List<Object> columns = (List<Object>) responseJSON.get(COLUMNS_PARAM);
            String objectIcon = String.valueOf(responseJSON.get(OBJECT_ICON_PARAM));
            String refLinks = String.valueOf(responseJSON.get(REFLINKS_PARAM));
            Boolean isCommunity = Boolean.valueOf(responseJSON.get(IS_COMMUNITY_PARAM));
            String sitePath = String.valueOf(responseJSON.get(SITE_PATH_PARAM));
            String baseUrl = String.valueOf(responseJSON.get(BASE_URL_PARAM));

          

            //columns
            List<REDU_Datatable_UTIL.TableActionWrapper> actionWrapper = getActionWrapper(true, true, true, true, false);
            JSONGenerator columnsGen = JSON.createGenerator(false);
            REDU_Datatable_UTIL.generateTableColMetadata(columnsGen, reduivy__Individual_Enrollment__c.getSObjectType(), 'Name;reduivy__Contact__c;reduivy__Attempt_Number__c;reduivy__Study_Offering__c', false, actionWrapper, true, '_blank', true, true);
            System.Assert.areEqual(columnsGen.getAsString(), JSON.serialize(columns), 'Columns should be equal');


            System.Assert.areEqual(objectIcon, 'custom:custom27', 'Object icon should be custom:custom27');
            System.Assert.areEqual(isCommunity, false, 'Is community should be false');
            System.Assert.areEqual(sitePath, ORG_Helper.getCurrentCommunitySitePath(), 'Unexpected site path');
            System.Assert.areEqual(baseUrl, URL.getOrgDomainUrl().toExternalForm(), 'Unexpected base url');
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as admin
     * This test is simulating the scenario where the component is used in a record page.
     * The component is displaying the siblings records (eg: In a Study Session Record Page, show all the Study session that has the same Study Offering with it)
     * infinite load is disabled, all row action is disabled, row number == 10
     * 
     */
    @IsTest
    static void testAsAdminForTargetRecordIdNotId() {

        
        User ADMIN_USER = testFactory.getReduAdminUser();
        Integer rowsToLoad = 10;
        Integer currentOffset = 0;
        reduivy__Study_Offering__c targetSof = [SELECT Id
                                FROM reduivy__Study_Offering__c
                                WHERE reduivy__Sample_Record_Code__c = :SAMPLE_RECORD_CODE_SOF
                                LIMIT 1];

                                

        Map<Id, reduivy__Study_Session__c> expectedDataMap = new Map<Id, reduivy__Study_Session__c>();
        for(reduivy__Study_Session__c sse : [SELECT Id
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :targetSof.Id]) {
                expectedDataMap.put(sse.Id, sse);
                
        }

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            String datatableConfig = getDatatableConfig(expectedDataMap.values()[0].Id, SOF_Helper.getApiName(), SOF_Helper.getApiName(), SSE_Helper.getApiName(), 'Name;reduivy__Type__c;reduivy__Study_Offering__c', '', rowsToLoad, currentOffset, false, false, false, false, true, true, '_blank', false, true);

            REDU_LightningResponse response = REDU_CustomSingleRelatedList_LCTRL.initDatatable(datatableConfig);
            
            System.Assert.isFalse(String.isBlank(response.responseData),'responseData should not be blank');

            Map<String, Object> responseJSON = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            
            
            String dataString = String.valueOf(responseJSON.get(RECORDS_PARAM));
            currentOffset = Integer.valueOf(responseJSON.get(CURRENT_OFFSET_PARAM));
            
            List<Object> columns = (List<Object>) responseJSON.get(COLUMNS_PARAM);
            String objectIcon = String.valueOf(responseJSON.get(OBJECT_ICON_PARAM));
            String refLinks = String.valueOf(responseJSON.get(REFLINKS_PARAM));
            Boolean isCommunity = Boolean.valueOf(responseJSON.get(IS_COMMUNITY_PARAM));
            String sitePath = String.valueOf(responseJSON.get(SITE_PATH_PARAM));
            String baseUrl = String.valueOf(responseJSON.get(BASE_URL_PARAM));
            
            //data
            List<reduivy__Study_Session__c> dataList = (List<reduivy__Study_Session__c>) JSON.deserialize(dataString, List<reduivy__Study_Session__c>.class);

            System.Assert.areEqual(expectedDataMap.keySet().size(), dataList.size(), 'Data size should be equal');
            for(reduivy__Study_Session__c actualSse : dataList) {
                System.Assert.isTrue(expectedDataMap.keySet().contains(actualSse.Id), actualSse.Id + 'is not expected to be in the list!');
            }
          

            //columns
            List<REDU_Datatable_UTIL.TableActionWrapper> actionWrapper = getActionWrapper(false, false, false, false, false);
            JSONGenerator columnsGen = JSON.createGenerator(false);
            REDU_Datatable_UTIL.generateTableColMetadata(columnsGen, reduivy__Study_Session__c.getSObjectType(), 'Name;reduivy__Type__c;reduivy__Study_Offering__c', false, actionWrapper, true, '_blank', true, true);
            System.Assert.areEqual(columnsGen.getAsString(), JSON.serialize(columns), 'Columns should be equal');


            System.Assert.areEqual(objectIcon, '', 'Object icon should be empty');
            System.Assert.areEqual(isCommunity, false, 'Is community should be false');
            System.Assert.areEqual(sitePath, ORG_Helper.getCurrentCommunitySitePath(), 'Unexpected site path');
            System.Assert.areEqual(baseUrl, URL.getOrgDomainUrl().toExternalForm(), 'Unexpected base url');
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as admin
     * This test is simulating the scenario where the component is used in a record page.
     * The component is displaying the related files of the record (content version)
     * infinite load is disabled, all row action are enable], row number == 10
     * 
     */
    @IsTest
    static void testAsAdminForContentVersion() {

        String fileName = 'testImage' + String.valueOf(System.today()) + '_sampleimage.png';
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        Integer rowsToLoad = 10;
        Integer currentOffset = 0;
        Contact targetStudent = [SELECT Id
                                FROM Contact
                                WHERE reduivy__Sample_Record_Code__c = :SAMPLE_RECORD_CODE_STUDENT
                                LIMIT 1];

        //insert file
        Blob body = Blob.valueOf('data:image/gif;base64,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');

        ContentVersion cv =new ContentVersion(Title = fileName, VersionData = body, PathOnClient='/' + fileName); 
        insert cv;
        
        cv = [select ContentDocumentId from ContentVersion where id=:cv.Id];
        insert new ContentDocumentLink(ContentDocumentId = cv.ContentDocumentId, ShareType = 'V', Visibility = 'AllUsers', LinkedEntityId = targetStudent.Id);

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            String datatableConfig = getDatatableConfig(targetStudent.Id, 'Id', CON_Helper.getApiName(), CVS_Helper.getApiName(), 'Title;Description;FileType', '', rowsToLoad, currentOffset, true, true, true, true, true, true, '_blank', false, true);

            REDU_LightningResponse response = REDU_CustomSingleRelatedList_LCTRL.initDatatable(datatableConfig);
            
            System.Assert.isFalse(String.isBlank(response.responseData),'responseData should not be blank');

            Map<String, Object> responseJSON = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            
            
            String dataString = String.valueOf(responseJSON.get(RECORDS_PARAM));
            currentOffset = Integer.valueOf(responseJSON.get(CURRENT_OFFSET_PARAM));
            List<Object> columns = (List<Object>) responseJSON.get(COLUMNS_PARAM);
            String objectIcon = String.valueOf(responseJSON.get(OBJECT_ICON_PARAM));
            String refLinks = String.valueOf(responseJSON.get(REFLINKS_PARAM));
            Boolean isCommunity = Boolean.valueOf(responseJSON.get(IS_COMMUNITY_PARAM));
            String sitePath = String.valueOf(responseJSON.get(SITE_PATH_PARAM));
            String baseUrl = String.valueOf(responseJSON.get(BASE_URL_PARAM));
            
            //data
            List<ContentVersion> dataList = (List<ContentVersion>) JSON.deserialize(dataString, List<ContentVersion>.class);

            System.Assert.areEqual(1, dataList.size(), 'Data size should be 1');

            //columns
            List<REDU_Datatable_UTIL.TableActionWrapper> actionWrapper = getActionWrapper(true, true, true, true, true);
            JSONGenerator columnsGen = JSON.createGenerator(false);
            REDU_Datatable_UTIL.generateTableColMetadata(columnsGen, ContentVersion.getSObjectType(), 'Title;Description;FileType', false, actionWrapper, true, '_blank', true, true);
            System.Assert.areEqual(columnsGen.getAsString(), JSON.serialize(columns), 'Columns should be equal');


            System.Assert.areEqual(objectIcon, '', 'Object icon should be empty');
            System.Assert.areEqual(isCommunity, false, 'Is community should be false');
            System.Assert.areEqual(sitePath, ORG_Helper.getCurrentCommunitySitePath(), 'Unexpected site path');
            System.Assert.areEqual(baseUrl, URL.getOrgDomainUrl().toExternalForm(), 'Unexpected base url');
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as admin
     * This test is simulating the scenario where the component is used in a record page,
     * infinite loading is enable, all row action is enabled, row number == 10, criteria is set (reduivy__Study_Offering__r.Name LIKE 'BUS%')
     * 
     */
    @IsTest
    static void testAsAdminForDisplayingPercent() {

        
        User ADMIN_USER = testFactory.getReduAdminUser();
        Integer rowsToLoad = 10;
        Integer currentOffset = 0;
        Contact targetStudent = [SELECT Id
                                FROM Contact
                                WHERE reduivy__Sample_Record_Code__c = :SAMPLE_RECORD_CODE_STUDENT
                                LIMIT 1];

        Map<Id, reduivy__Individual_Program_Enrollment__c> expectedDataMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
        for(reduivy__Individual_Program_Enrollment__c ipe : [SELECT Id
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Contact__c = :targetStudent.Id
            LIMIT :rowsToLoad]) {
                expectedDataMap.put(ipe.Id, ipe);
        }

        expectedDataMap.values().get(0).reduivy__Completion_Percentage__c = 100;
        update expectedDataMap.values().get(0);

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            String datatableConfig = getDatatableConfig(targetStudent.Id, 'Id', 'reduivy__Contact__c', IPE_Helper.getApiName(), 'Name;reduivy__Contact__c;reduivy__Completion_Percentage__c', '', rowsToLoad, currentOffset, true, true, true, true, true, true, '_blank', false, true);

            REDU_LightningResponse response = REDU_CustomSingleRelatedList_LCTRL.initDatatable(datatableConfig);
            
            System.Assert.isFalse(String.isBlank(response.responseData),'responseData should not be blank');

            Map<String, Object> responseJSON = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            
            String dataString = String.valueOf(responseJSON.get(RECORDS_PARAM));
            currentOffset = Integer.valueOf(responseJSON.get(CURRENT_OFFSET_PARAM));
            List<Object> columns = (List<Object>) responseJSON.get(COLUMNS_PARAM);
            String objectIcon = String.valueOf(responseJSON.get(OBJECT_ICON_PARAM));
            String refLinks = String.valueOf(responseJSON.get(REFLINKS_PARAM));
            Boolean isCommunity = Boolean.valueOf(responseJSON.get(IS_COMMUNITY_PARAM));
            String sitePath = String.valueOf(responseJSON.get(SITE_PATH_PARAM));
            String baseUrl = String.valueOf(responseJSON.get(BASE_URL_PARAM));

            REDU_Logging_UTIL.debug('dataString', dataString);
            List<reduivy__Individual_Program_Enrollment__c> dataList = (List<reduivy__Individual_Program_Enrollment__c>) JSON.deserialize(dataString, List<reduivy__Individual_Program_Enrollment__c>.class);

            //data
            System.Assert.areEqual(expectedDataMap.keySet().size(), dataList.size(), 'Data size should be equal');
            for(reduivy__Individual_Program_Enrollment__c actualIpe : dataList) {
                System.Assert.isTrue(expectedDataMap.keySet().contains(actualIpe.Id), actualIpe.Id + 'is not expected to be in the list!');
            }

            //columns
            List<REDU_Datatable_UTIL.TableActionWrapper> actionWrapper = getActionWrapper(true, true, true, true, false);
            JSONGenerator columnsGen = JSON.createGenerator(false);
            REDU_Datatable_UTIL.generateTableColMetadata(columnsGen, reduivy__Individual_Program_Enrollment__c.getSObjectType(), 'Name;reduivy__Contact__c;reduivy__Completion_Percentage__c', false, actionWrapper, true, '_blank', true, true);
            System.Assert.areEqual(columnsGen.getAsString(), JSON.serialize(columns), 'Columns should be equal');


            System.Assert.areEqual(currentOffset, dataList.size(), 'Current Offset should be 10');
            System.Assert.areEqual(objectIcon, 'custom:custom27', 'Object icon should be custom:custom27');
            System.Assert.areEqual(isCommunity, false, 'Is community should be false');
            System.Assert.areEqual(sitePath, ORG_Helper.getCurrentCommunitySitePath(), 'Unexpected site path');
            System.Assert.areEqual(baseUrl, URL.getOrgDomainUrl().toExternalForm(), 'Unexpected base url');
            

            
		}

        Test.stopTest();
		
    }
  
    /**
     * @description Test as student. Query records to display
     */
	@IsTest
    static void testForStudent() {

        //get the student record if you need one for testing using student.ContactId
		User studentUser = testFactory.getStudentUser();
        Contact targetStudent = CON_Helper.getCurrentLoggedInUserContact(studentUser);

        Integer rowsToLoad = 10;
        Integer currentOffset = 0;
        String filterCriteria = 'reduivy__Study_Offering__r.Name LIKE \'BUS%\'';

        Map<Id, reduivy__Individual_Enrollment__c> expectedDataMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        for(reduivy__Individual_Enrollment__c ien : [SELECT Id
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :targetStudent.Id
            AND reduivy__Study_Offering__r.Name LIKE 'BUS%'
            LIMIT :rowsToLoad]) {
                expectedDataMap.put(ien.Id, ien);
        }

        Test.startTest();
        
		System.runAs(studentUser){
            String datatableConfig = getDatatableConfig(targetStudent.Id, 'Id', 'reduivy__Contact__c', IEN_Helper.getApiName(), 'Name;reduivy__Contact__c;reduivy__Attempt_Number__c;reduivy__Study_Offering__c', filterCriteria, rowsToLoad, currentOffset, true, true, true, true, true, true, '_blank', false, true);

            REDU_LightningResponse response = REDU_CustomSingleRelatedList_LCTRL.initDatatable(datatableConfig);
            
            System.Assert.isFalse(String.isBlank(response.responseData),'responseData should not be blank');

            Map<String, Object> responseJSON = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            
            String dataString = String.valueOf(responseJSON.get(RECORDS_PARAM));
            currentOffset = Integer.valueOf(responseJSON.get(CURRENT_OFFSET_PARAM));
            List<Object> columns = (List<Object>) responseJSON.get(COLUMNS_PARAM);
            String objectIcon = String.valueOf(responseJSON.get(OBJECT_ICON_PARAM));
            String refLinks = String.valueOf(responseJSON.get(REFLINKS_PARAM));
            Boolean isCommunity = Boolean.valueOf(responseJSON.get(IS_COMMUNITY_PARAM));
            String sitePath = String.valueOf(responseJSON.get(SITE_PATH_PARAM));
            String baseUrl = String.valueOf(responseJSON.get(BASE_URL_PARAM));

            REDU_Logging_UTIL.debug('dataString', dataString);
            List<reduivy__Individual_Enrollment__c> dataList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(dataString, List<reduivy__Individual_Enrollment__c>.class);

            //data
            System.Assert.areEqual(expectedDataMap.keySet().size(), dataList.size(), 'Data size should be equal');
            for(reduivy__Individual_Enrollment__c actualIen : dataList) {
                System.Assert.isTrue(expectedDataMap.keySet().contains(actualIen.Id), actualIen.Id + 'is not expected to be in the list!');
            }

            //columns
            List<REDU_Datatable_UTIL.TableActionWrapper> actionWrapper = getActionWrapper(true, true, true, true, false);
            JSONGenerator columnsGen = JSON.createGenerator(false);
            REDU_Datatable_UTIL.generateTableColMetadata(columnsGen, reduivy__Individual_Enrollment__c.getSObjectType(), 'Name;reduivy__Contact__c;reduivy__Attempt_Number__c;reduivy__Study_Offering__c', false, actionWrapper, true, '_blank', true, true);
            System.Assert.areEqual(columnsGen.getAsString(), JSON.serialize(columns), 'Columns should be equal');


            System.Assert.areEqual(currentOffset, dataList.size(), 'Current Offset should be 10');
            System.Assert.areEqual(objectIcon, '', 'Object icon should be empty');
            System.Assert.areEqual(isCommunity, false, 'Is community should be false');
            System.Assert.areEqual(sitePath, ORG_Helper.getCurrentCommunitySitePath(), 'Unexpected site path');
            System.Assert.areEqual(baseUrl, URL.getOrgDomainUrl().toExternalForm(), 'Unexpected base url');
            
            
        }
        Test.stopTest();
            
    }

    /**
     * @description Test as student. Query records to display using USERCONTACTID var
     */
	@IsTest
    static void testForStudentWithUserContactIdVar() {

        //get the student record if you need one for testing using student.ContactId
		User studentUser = testFactory.getStudentUser();
        Contact targetStudent = CON_Helper.getCurrentLoggedInUserContact(studentUser);

        Integer rowsToLoad = 10;
        Integer currentOffset = 0;
        String filterCriteria = 'reduivy__Study_Offering__r.Name LIKE \'BUS%\'';

        Map<Id, reduivy__Individual_Enrollment__c> expectedDataMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        for(reduivy__Individual_Enrollment__c ien : [SELECT Id
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :targetStudent.Id
            AND reduivy__Study_Offering__r.Name LIKE 'BUS%'
            LIMIT :rowsToLoad]) {
                expectedDataMap.put(ien.Id, ien);
        }

        Test.startTest();
        
		System.runAs(studentUser){
            String datatableConfig = getDatatableConfig(REDU_CustomSingleRelatedList_LCTRL.USERCONTACTID_VAR, 'Id', 'reduivy__Contact__c', IEN_Helper.getApiName(), 'Name;reduivy__Contact__c;reduivy__Attempt_Number__c;reduivy__Study_Offering__c', filterCriteria, rowsToLoad, currentOffset, true, true, true, true, true, true, '_blank', false, true);

            REDU_LightningResponse response = REDU_CustomSingleRelatedList_LCTRL.initDatatable(datatableConfig);
            
            System.Assert.isFalse(String.isBlank(response.responseData),'responseData should not be blank');

            Map<String, Object> responseJSON = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            
            String dataString = String.valueOf(responseJSON.get(RECORDS_PARAM));
            currentOffset = Integer.valueOf(responseJSON.get(CURRENT_OFFSET_PARAM));
            List<Object> columns = (List<Object>) responseJSON.get(COLUMNS_PARAM);
            String objectIcon = String.valueOf(responseJSON.get(OBJECT_ICON_PARAM));
            String refLinks = String.valueOf(responseJSON.get(REFLINKS_PARAM));
            Boolean isCommunity = Boolean.valueOf(responseJSON.get(IS_COMMUNITY_PARAM));
            String sitePath = String.valueOf(responseJSON.get(SITE_PATH_PARAM));
            String baseUrl = String.valueOf(responseJSON.get(BASE_URL_PARAM));

            REDU_Logging_UTIL.debug('dataString', dataString);
            List<reduivy__Individual_Enrollment__c> dataList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(dataString, List<reduivy__Individual_Enrollment__c>.class);

            //data
            System.Assert.areEqual(expectedDataMap.keySet().size(), dataList.size(), 'Data size should be equal');
            for(reduivy__Individual_Enrollment__c actualIen : dataList) {
                System.Assert.isTrue(expectedDataMap.keySet().contains(actualIen.Id), actualIen.Id + 'is not expected to be in the list!');
            }

            //columns
            List<REDU_Datatable_UTIL.TableActionWrapper> actionWrapper = getActionWrapper(true, true, true, true, false);
            JSONGenerator columnsGen = JSON.createGenerator(false);
            REDU_Datatable_UTIL.generateTableColMetadata(columnsGen, reduivy__Individual_Enrollment__c.getSObjectType(), 'Name;reduivy__Contact__c;reduivy__Attempt_Number__c;reduivy__Study_Offering__c', false, actionWrapper, true, '_blank', true, true);
            System.Assert.areEqual(columnsGen.getAsString(), JSON.serialize(columns), 'Columns should be equal');


            System.Assert.areEqual(currentOffset, dataList.size(), 'Current Offset should be 10');
            System.Assert.areEqual(objectIcon, '', 'Object icon should be empty');
            System.Assert.areEqual(isCommunity, false, 'Is community should be false');
            System.Assert.areEqual(sitePath, ORG_Helper.getCurrentCommunitySitePath(), 'Unexpected site path');
            System.Assert.areEqual(baseUrl, URL.getOrgDomainUrl().toExternalForm(), 'Unexpected base url');
            
            
        }
        Test.stopTest();
            
    }

    /**
     * @description Test as student. Query records to display using USERID var
     */
	@IsTest
    static void testForStudentWithUserIdVar() {

        //get the student record if you need one for testing using student.ContactId
		User studentUser = testFactory.getStudentUser();
        Contact targetStudent = CON_Helper.getCurrentLoggedInUserContact(studentUser);

        Integer rowsToLoad = 10;
        Integer currentOffset = 0;
        String filterCriteria = '';

        Task newTask1 = new Task();
        newTask1.Subject = 'Test task 1';
        newTask1.OwnerId = studentUser.Id;
        
        Task newTask2 = new Task();
        newTask2.Subject = 'Test task 2';
        newTask2.OwnerId = studentUser.Id;

        REDU_Database_UTIL.doInsert(new List<Task>{newTask1, newTask2});

        Test.startTest();
        
		System.runAs(studentUser){
            

            String datatableConfig = getDatatableConfig(REDU_CustomSingleRelatedList_LCTRL.USERID_VAR, 'Id', 'OwnerId', 'Task', 'Subject;OwnerId', filterCriteria, rowsToLoad, currentOffset, true, true, true, true, true, true, '_blank', false, true);

            REDU_LightningResponse response = REDU_CustomSingleRelatedList_LCTRL.initDatatable(datatableConfig);
            
            System.Assert.isFalse(String.isBlank(response.responseData),'responseData should not be blank');

            Map<String, Object> responseJSON = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            
            String dataString = String.valueOf(responseJSON.get(RECORDS_PARAM));
            currentOffset = Integer.valueOf(responseJSON.get(CURRENT_OFFSET_PARAM));
            List<Object> columns = (List<Object>) responseJSON.get(COLUMNS_PARAM);
            String objectIcon = String.valueOf(responseJSON.get(OBJECT_ICON_PARAM));
            String refLinks = String.valueOf(responseJSON.get(REFLINKS_PARAM));
            Boolean isCommunity = Boolean.valueOf(responseJSON.get(IS_COMMUNITY_PARAM));
            String sitePath = String.valueOf(responseJSON.get(SITE_PATH_PARAM));
            String baseUrl = String.valueOf(responseJSON.get(BASE_URL_PARAM));

            REDU_Logging_UTIL.debug('dataString', dataString);
            List<Task> dataList = (List<Task>) JSON.deserialize(dataString, List<Task>.class);

            //data
            System.Assert.areEqual(2, dataList.size(), 'Data size should be equal');

            //columns
            List<REDU_Datatable_UTIL.TableActionWrapper> actionWrapper = getActionWrapper(true, true, true, true, false);
            JSONGenerator columnsGen = JSON.createGenerator(false);
            REDU_Datatable_UTIL.generateTableColMetadata(columnsGen, Task.getSObjectType(), 'Subject;OwnerId', false, actionWrapper, true, '_blank', true, true);
            System.Assert.areEqual(columnsGen.getAsString(), JSON.serialize(columns), 'Columns should be equal');


            System.Assert.areEqual(currentOffset, dataList.size(), 'Current Offset should be 10');
            System.Assert.areEqual(objectIcon, '', 'Object icon should be empty');
            System.Assert.areEqual(isCommunity, false, 'Is community should be false');
            System.Assert.areEqual(sitePath, ORG_Helper.getCurrentCommunitySitePath(), 'Unexpected site path');
            System.Assert.areEqual(baseUrl, URL.getOrgDomainUrl().toExternalForm(), 'Unexpected base url');
            
        }

        Test.stopTest();
            
    }
        
    /**
     * @description Test as faculty. Query records to display
     */
	@IsTest
    static void testForFaculty() {
		
        User FACULTY_USER = testFactory.getAllocatedFacultyUser();
        
        Contact targetStudent = [SELECT Id
                                FROM Contact
                                WHERE reduivy__Sample_Record_Code__c = :SAMPLE_RECORD_CODE_STUDENT
                                LIMIT 1];

        Integer rowsToLoad = 10;
        Integer currentOffset = 0;
        String filterCriteria = 'reduivy__Study_Offering__r.Name LIKE \'BUS%\'';

        Map<Id, reduivy__Individual_Enrollment__c> expectedDataMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        for(reduivy__Individual_Enrollment__c ien : [SELECT Id
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :targetStudent.Id
            AND reduivy__Study_Offering__r.Name LIKE 'BUS%'
            LIMIT :rowsToLoad]) {
                expectedDataMap.put(ien.Id, ien);
        }

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            String datatableConfig = getDatatableConfig(targetStudent.Id, 'Id', 'reduivy__Contact__c', IEN_Helper.getApiName(), 'Name;reduivy__Contact__c;reduivy__Attempt_Number__c;reduivy__Study_Offering__c', filterCriteria, rowsToLoad, currentOffset, true, true, true, true, true, true, '_blank', false, true);

            REDU_LightningResponse response = REDU_CustomSingleRelatedList_LCTRL.initDatatable(datatableConfig);
            
            System.Assert.isFalse(String.isBlank(response.responseData),'responseData should not be blank');

            Map<String, Object> responseJSON = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            
            String dataString = String.valueOf(responseJSON.get(RECORDS_PARAM));
            currentOffset = Integer.valueOf(responseJSON.get(CURRENT_OFFSET_PARAM));
            List<Object> columns = (List<Object>) responseJSON.get(COLUMNS_PARAM);
            String objectIcon = String.valueOf(responseJSON.get(OBJECT_ICON_PARAM));
            String refLinks = String.valueOf(responseJSON.get(REFLINKS_PARAM));
            Boolean isCommunity = Boolean.valueOf(responseJSON.get(IS_COMMUNITY_PARAM));
            String sitePath = String.valueOf(responseJSON.get(SITE_PATH_PARAM));
            String baseUrl = String.valueOf(responseJSON.get(BASE_URL_PARAM));

            REDU_Logging_UTIL.debug('dataString', dataString);
            List<reduivy__Individual_Enrollment__c> dataList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(dataString, List<reduivy__Individual_Enrollment__c>.class);

            //data
            System.Assert.areEqual(expectedDataMap.keySet().size(), dataList.size(), 'Data size should be equal');
            for(reduivy__Individual_Enrollment__c actualIen : dataList) {
                System.Assert.isTrue(expectedDataMap.keySet().contains(actualIen.Id), actualIen.Id + 'is not expected to be in the list!');
            }

            //columns
            List<REDU_Datatable_UTIL.TableActionWrapper> actionWrapper = getActionWrapper(true, true, true, true, false);
            JSONGenerator columnsGen = JSON.createGenerator(false);
            REDU_Datatable_UTIL.generateTableColMetadata(columnsGen, reduivy__Individual_Enrollment__c.getSObjectType(), 'Name;reduivy__Contact__c;reduivy__Attempt_Number__c;reduivy__Study_Offering__c', false, actionWrapper, true, '_blank', true, true);
            System.Assert.areEqual(columnsGen.getAsString(), JSON.serialize(columns), 'Columns should be equal');


            System.Assert.areEqual(currentOffset, dataList.size(), 'Current Offset should be 10');
            System.Assert.areEqual(objectIcon, '', 'Object icon should be empty');
            System.Assert.areEqual(isCommunity, false, 'Is community should be false');
            System.Assert.areEqual(sitePath, ORG_Helper.getCurrentCommunitySitePath(), 'Unexpected site path');
            System.Assert.areEqual(baseUrl, URL.getOrgDomainUrl().toExternalForm(), 'Unexpected base url');
            
            
        }
        Test.stopTest();
		
    }

    /**
     * @description Test as faculty. Query records to display using USERCONTACTID
     */
	@IsTest
    static void testForFacultyWithUserContactIdVar() {
		
        User FACULTY_USER = testFactory.getAllocatedFacultyUser();
        
        Integer rowsToLoad = 10;
        Integer currentOffset = 0;
        String filterCriteria = '';

        Task newTask1 = new Task();
        newTask1.Subject = 'Test task 1';
        newTask1.WhoId = FACULTY_USER.ContactId;
        newTask1.OwnerId = FACULTY_USER.Id;
        
        Task newTask2 = new Task();
        newTask2.Subject = 'Test task 2';
        newTask2.WhoId = FACULTY_USER.ContactId;
        newTask2.OwnerId = FACULTY_USER.Id;

        REDU_Database_UTIL.doInsert(new List<Task>{newTask1, newTask2});

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            String datatableConfig = getDatatableConfig(REDU_CustomSingleRelatedList_LCTRL.USERCONTACTID_VAR, 'Id', 'WhoId', 'Task', 'Subject;WhoId', filterCriteria, rowsToLoad, currentOffset, true, true, true, true, true, true, '_blank', false, true);

            REDU_LightningResponse response = REDU_CustomSingleRelatedList_LCTRL.initDatatable(datatableConfig);
            
            System.Assert.isFalse(String.isBlank(response.responseData),'responseData should not be blank');

            Map<String, Object> responseJSON = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            
            String dataString = String.valueOf(responseJSON.get(RECORDS_PARAM));
            currentOffset = Integer.valueOf(responseJSON.get(CURRENT_OFFSET_PARAM));
            List<Object> columns = (List<Object>) responseJSON.get(COLUMNS_PARAM);
            String objectIcon = String.valueOf(responseJSON.get(OBJECT_ICON_PARAM));
            String refLinks = String.valueOf(responseJSON.get(REFLINKS_PARAM));
            Boolean isCommunity = Boolean.valueOf(responseJSON.get(IS_COMMUNITY_PARAM));
            String sitePath = String.valueOf(responseJSON.get(SITE_PATH_PARAM));
            String baseUrl = String.valueOf(responseJSON.get(BASE_URL_PARAM));

            REDU_Logging_UTIL.debug('dataString', dataString);
            List<Task> dataList = (List<Task>) JSON.deserialize(dataString, List<Task>.class);

            //data
            System.Assert.areEqual(2, dataList.size(), 'Data size should be equal');

            //columns
            List<REDU_Datatable_UTIL.TableActionWrapper> actionWrapper = getActionWrapper(true, true, true, true, false);
            JSONGenerator columnsGen = JSON.createGenerator(false);
            REDU_Datatable_UTIL.generateTableColMetadata(columnsGen, Task.getSObjectType(), 'Subject;WhoId', false, actionWrapper, true, '_blank', true, true);
            System.Assert.areEqual(columnsGen.getAsString(), JSON.serialize(columns), 'Columns should be equal');

            System.Assert.areEqual(currentOffset, dataList.size(), 'Current Offset should be 10');
            System.Assert.areEqual(objectIcon, '', 'Object icon should be empty');
            System.Assert.areEqual(isCommunity, false, 'Is community should be false');
            System.Assert.areEqual(sitePath, ORG_Helper.getCurrentCommunitySitePath(), 'Unexpected site path');
            System.Assert.areEqual(baseUrl, URL.getOrgDomainUrl().toExternalForm(), 'Unexpected base url');
            
        }
        
        Test.stopTest();
		
    }

    /**
     * @description Test as faculty. Query records to display using USERID
     */
	@IsTest
    static void testForFacultyWithUserIdVar() {
		
        User FACULTY_USER = testFactory.getAllocatedFacultyUser();
        
        Integer rowsToLoad = 10;
        Integer currentOffset = 0;
        String filterCriteria = '';

        Task newTask1 = new Task();
        newTask1.Subject = 'Test task 1';
        newTask1.OwnerId = FACULTY_USER.Id;
        
        Task newTask2 = new Task();
        newTask2.Subject = 'Test task 2';
        newTask2.OwnerId = FACULTY_USER.Id;

        REDU_Database_UTIL.doInsert(new List<Task>{newTask1, newTask2});

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            String datatableConfig = getDatatableConfig(REDU_CustomSingleRelatedList_LCTRL.USERID_VAR, 'Id', 'OwnerId', 'Task', 'Subject;OwnerId', filterCriteria, rowsToLoad, currentOffset, true, true, true, true, true, true, '_blank', false, true);

            REDU_LightningResponse response = REDU_CustomSingleRelatedList_LCTRL.initDatatable(datatableConfig);
            
            System.Assert.isFalse(String.isBlank(response.responseData),'responseData should not be blank');

            Map<String, Object> responseJSON = (Map<String, Object>)JSON.deserializeUntyped(response.responseData);
            
            String dataString = String.valueOf(responseJSON.get(RECORDS_PARAM));
            currentOffset = Integer.valueOf(responseJSON.get(CURRENT_OFFSET_PARAM));
            List<Object> columns = (List<Object>) responseJSON.get(COLUMNS_PARAM);
            String objectIcon = String.valueOf(responseJSON.get(OBJECT_ICON_PARAM));
            String refLinks = String.valueOf(responseJSON.get(REFLINKS_PARAM));
            Boolean isCommunity = Boolean.valueOf(responseJSON.get(IS_COMMUNITY_PARAM));
            String sitePath = String.valueOf(responseJSON.get(SITE_PATH_PARAM));
            String baseUrl = String.valueOf(responseJSON.get(BASE_URL_PARAM));

            REDU_Logging_UTIL.debug('dataString', dataString);
            List<Task> dataList = (List<Task>) JSON.deserialize(dataString, List<Task>.class);

            //data
            System.Assert.areEqual(2, dataList.size(), 'Data size should be equal');

            //columns
            List<REDU_Datatable_UTIL.TableActionWrapper> actionWrapper = getActionWrapper(true, true, true, true, false);
            JSONGenerator columnsGen = JSON.createGenerator(false);
            REDU_Datatable_UTIL.generateTableColMetadata(columnsGen, Task.getSObjectType(), 'Subject;OwnerId', false, actionWrapper, true, '_blank', true, true);
            System.Assert.areEqual(columnsGen.getAsString(), JSON.serialize(columns), 'Columns should be equal');

            System.Assert.areEqual(currentOffset, dataList.size(), 'Current Offset should be 10');
            System.Assert.areEqual(objectIcon, '', 'Object icon should be empty');
            System.Assert.areEqual(isCommunity, false, 'Is community should be false');
            System.Assert.areEqual(sitePath, ORG_Helper.getCurrentCommunitySitePath(), 'Unexpected site path');
            System.Assert.areEqual(baseUrl, URL.getOrgDomainUrl().toExternalForm(), 'Unexpected base url');
            
        }

        Test.stopTest();
		
    }

	@IsTest
    static void performanceTest100() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        Account eduInst = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c =: SAMPLE_RECORD_CODE_EDUINST];
        Integer sunSize = 100;
        List<reduivy__Study_Unit__c> sunList = new List<reduivy__Study_Unit__c>();
        for(Integer i = 0; i < sunSize; i++) {
            sunList.add(
                new reduivy__Study_Unit__c(
                    Name = 'Study Unit ' + (i + 1),
                    reduivy__Unit_Code__c = 'Study Unit ' + (i + 1),
                    reduivy__Credits__c = 10
                )
            );
        }
        
        insert sunList;

		System.runAs(ADMIN_USER){   
            String datatableConfig = getDatatableConfig(eduInst.Id, 'Id', 'reduivy__Educational_Institution__c', SUN_Helper.getApiName(), 'Name;reduivy__Unit_Code__c;reduivy__Credits__c', '', 100, 0, true, true, true, true, true, true, '_blank', false, true);

            Integer startCpu = Limits.getCpuTime();
            REDU_LightningResponse result = REDU_CustomSingleRelatedList_LCTRL.initDatatable(datatableConfig);

            Integer endCpu = Limits.getCpuTime();

            System.Assert.isTrue(endCpu - startCpu <= 100, 'Time taken is too long! Actual: ' + (endCpu - startCpu));
            
        }


        Test.stopTest();
    }
      

    /**
     * @description get table action wrapper list
     * @param  enableView       
     * @param  enableEdit       
     * @param  enableDelete     
     * @param  enableDownload   
     * @param  isContentVersion 
     * @return                  
     */
    private static List<REDU_Datatable_UTIL.TableActionWrapper> getActionWrapper(Boolean enableView,Boolean enableEdit,Boolean enableDelete,Boolean enableDownload, Boolean isContentVersion){
        List<REDU_Datatable_UTIL.TableActionWrapper> tableActionWrapper = new List<REDU_Datatable_UTIL.TableActionWrapper>();
        if(enableView){
            tableActionWrapper.add(new REDU_Datatable_UTIL.TableActionWrapper(Label.View,'view'));
        } 
        if(enableEdit){
            tableActionWrapper.add(new REDU_Datatable_UTIL.TableActionWrapper(Label.Edit,'edit'));
        } 
        if(enableDelete){
            tableActionWrapper.add(new REDU_Datatable_UTIL.TableActionWrapper(Label.Delete,'delete'));
        } 
        if(enableDownload && isContentVersion){
            tableActionWrapper.add(new REDU_Datatable_UTIL.TableActionWrapper(Label.Download,'download'));
        } 

        return tableActionWrapper;
    }

    /**
     * @description get datatable config in serialized json string
     * @param  recordId
     * @param  targetRecordIdField
     * @param  parentObjRefField
     * @param  childObjName
     * @param  childObjFields
     * @param  childObjFilter
     * @param  rowsToLoad
     * @param  currentOffSet
     * @param  enableView
     * @param  enableEdit
     * @param  enableDelete
     * @param  enableDownload
     * @param  enableClickableRefField
     * @param  enableInlineEditing
     * @param  refTarget
     * @param  useSourceCollectionRecords
     */ 
    private static String getDatatableConfig(String recordId, String targetRecordIdField, String parentObjRefField, String childObjName, String childObjFields, String childObjFilter, Integer rowsToLoad, Integer currentOffSet, Boolean enableView, Boolean enableEdit, Boolean enableDelete, Boolean enableDownload, Boolean enableClickableRefField, Boolean enableInlineEditing, String refTarget, Boolean useSourceCollectionRecords, Boolean enableWrapText){
        Map<String, Object> requestJSON = new Map<String, Object>();
        if(String.isNotBlank(recordId)) requestJSON.put(RECORD_ID_PARAM, recordId);
        if(String.isNotBlank(targetRecordIdField)) requestJSON.put(TARGET_RECORD_ID_PARAM, targetRecordIdField);
        if(String.isNotBlank(parentObjRefField)) requestJSON.put(PARENT_OBJECT_REF_FIELD_PARAM, parentObjRefField);
        if(String.isNotBlank(childObjName)) requestJSON.put(CHILD_OBJECT_API_NAME_PARAM, childObjName);
        if(String.isNotBlank(childObjFields)) requestJSON.put(CHILD_OBJECT_FIELDS_PARAM, childObjFields);
        if(String.isNotBlank(childObjFilter)) requestJSON.put(CHILD_OBJECT_FILTER_CRITERIA_PARAM, childObjFilter);
        requestJSON.put(ROWS_TO_LOAD_PARAM, rowsToLoad);
        requestJSON.put(CURRENT_OFFSET_PARAM,currentOffSet);
        requestJSON.put(ENABLE_VIEW_PARAM,enableView);
        requestJSON.put(ENABLE_EDIT_PARAM,enableEdit);
        requestJSON.put(ENABLE_DELETE_PARAM,enableDelete);
        requestJSON.put(ENABLE_DOWNLOAD_PARAM,enableDownload);
        requestJSON.put(ENABLE_CLICKABLE_REFFIELD_PARAM,enableClickableRefField);
        requestJSON.put(ENABLE_INLINE_EDIT_PARAM,enableInlineEditing);
        requestJSON.put(REFERENCE_TARGET, String.isNotBlank(refTarget) ? refTarget : '_blank');
        requestJSON.put(USE_SOURCE_COLLECTION_RECORDS,useSourceCollectionRecords);
        requestJSON.put(WRAPTEXT_PARAM, enableWrapText);

        return JSON.serialize(requestJSON);
    }
	
	
}