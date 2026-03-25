/**
 * @author      WDCi (XiRouh)
 * @date        March 2025
 * @group       Test Class
 * @description Test class for REDU_TermOfferingsCloning_LCTRL
 * @changehistory
 * ISS-002200 17-03-2025 XiRouh - new class
 * ISS-002547 16-07-2025 Lean - Change to use job queue group
 */
@isTest
public inherited sharing class REDU_TermOfferingsCloning_TEST {
    private static final String JOB_OPERATION = 'Term_Offerings_Cloning';
    private static final String ACADEMIC_TERM_RECORD_TYPE_ID = STM_Helper.getAcademicTermRecordTypeId();

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Initialise test data for each test
     */
    @TestSetup
    static void makeData(){
        
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();

        	testFactory.initMasterData(null);
            testFactory.initOfferingData(null);
            testFactory.initStudentData(USR_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test getJobQueueData() as admin
     */
    @IsTest
    static void testGetJobQueueDataAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER){
            Test.startTest();

            List<reduivy__Study_Term__c> stm = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID];

            reduivy__Job_Queue_Group__c jobQueueGroup1 = REDU_TestData_UTIL.newJobQueueGroup(
                JQH_Helper.getJobOperationContext(JOB_OPERATION, stm[0].Id),
                JQH_Helper.getJobOperationContext(JOB_OPERATION, stm[0].Id)
            );

            reduivy__Job_Queue_Group__c jobQueueGroup2 = REDU_TestData_UTIL.newJobQueueGroup(
                'Sample_Job',
                'Sample_Job'
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Job_Queue_Group__c>{jobQueueGroup1, jobQueueGroup2});

            //Create 2 dummy Job Queue records - 1 to be retrieved, the other to be ignored
            List<reduivy__Job_Queue__c> jqList = new List<reduivy__Job_Queue__c>();
            reduivy__Job_Queue__c validJobQueue = new reduivy__Job_Queue__c();
            validJobQueue.reduivy__Job_Operation__c = JOB_OPERATION;
            validJobQueue.reduivy__Job_Operation_Context__c = JQH_Helper.getJobOperationContext(JOB_OPERATION, stm[0].Id);
            validJobQueue.reduivy__Status__c = JQH_Helper.STATUS_PENDING;
            validJobQueue.reduivy__Job_Queue_Group__c = jobQueueGroup1.Id;

            reduivy__Job_Queue__c invalidJobQueue = new reduivy__Job_Queue__c();
            invalidJobQueue.reduivy__Job_Operation__c = 'Sample_Job';
            invalidJobQueue.reduivy__Job_Operation_Context__c = JQH_Helper.getJobOperationContext('Sample_Job', stm[0].Id);
            invalidJobQueue.reduivy__Status__c = JQH_Helper.STATUS_PENDING;
            invalidJobQueue.reduivy__Job_Queue_Group__c = jobQueueGroup2.Id;

            jqList.add(validJobQueue);
            jqList.add(invalidJobQueue);

            REDU_Database_UTIL.doInsert(jqList);

            List<reduivy__Job_Queue_Group__c> jobQueueGroups = [SELECT Id, reduivy__Job_Operation_Context__c FROM reduivy__Job_Queue_Group__c WHERE reduivy__Job_Operation_Context__c =: validJobQueue.reduivy__Job_Operation_Context__c];
            
            System.Assert.areEqual(1, jobQueueGroups.size(), 'A Job Queue group should be created.');

            String jobQueueGroupFields = 'Name;CreatedDate;reduivy__Total_Records__c;reduivy__Success_Records__c;reduivy__Error_Records__c;reduivy__Status__c';
            String jobQueueGroupStatuses = 'Pending;Processing;Completed;Failed';

            REDU_LightningResponse response = REDU_TermOfferingsCloning_LCTRL.getJobQueueData(JOB_OPERATION, stm[0].Id, jobQueueGroupFields, jobQueueGroupStatuses);

            // Verify response
            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, Object> finalMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap.containsKey('jobQueueGroupRecords'), 'Response should contain jobQueueGroupRecords key');            
            
            // Verify records
            List<Object> recordsMapObj = (List<Object>) finalMap.get('jobQueueGroupRecords');
            System.Assert.isFalse(recordsMapObj.isEmpty(), 'records map should not be empty');

            Test.stopTest();
        }
    }

    /**
     * @description Test getJobQueueData() as faculty
     */
    @IsTest
    static void testGetJobQueueDataAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<reduivy__Study_Term__c> stm = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID];

        reduivy__Job_Queue_Group__c jobQueueGroup1 = REDU_TestData_UTIL.newJobQueueGroup(
            JQH_Helper.getJobOperationContext(JOB_OPERATION, stm[0].Id),
            JQH_Helper.getJobOperationContext(JOB_OPERATION, stm[0].Id)
        );

        reduivy__Job_Queue_Group__c jobQueueGroup2 = REDU_TestData_UTIL.newJobQueueGroup(
            'Sample_Job',
            'Sample_Job'
        );

        REDU_Database_UTIL.doInsert(new List<reduivy__Job_Queue_Group__c>{jobQueueGroup1, jobQueueGroup2});

        //Create 2 dummy Job Queue records - 1 to be retrieved, the other to be ignored
        List<reduivy__Job_Queue__c> jqList = new List<reduivy__Job_Queue__c>();
        reduivy__Job_Queue__c validJobQueue = new reduivy__Job_Queue__c();
        validJobQueue.reduivy__Job_Operation__c = JOB_OPERATION;
        validJobQueue.reduivy__Job_Operation_Context__c = JQH_Helper.getJobOperationContext(JOB_OPERATION, stm[0].Id);
        validJobQueue.reduivy__Status__c = JQH_Helper.STATUS_PENDING;
        validJobQueue.reduivy__Job_Queue_Group__c = jobQueueGroup1.Id;

        reduivy__Job_Queue__c invalidJobQueue = new reduivy__Job_Queue__c();
        invalidJobQueue.reduivy__Job_Operation__c = 'Sample_Job';
        invalidJobQueue.reduivy__Job_Operation_Context__c = JQH_Helper.getJobOperationContext('Sample_Job', stm[0].Id);
        invalidJobQueue.reduivy__Status__c = JQH_Helper.STATUS_PENDING;
        invalidJobQueue.reduivy__Job_Queue_Group__c = jobQueueGroup2.Id;

        jqList.add(validJobQueue);
        jqList.add(invalidJobQueue);

        REDU_Database_UTIL.doInsert(jqList);

        List<reduivy__Job_Queue_Group__c> jobQueueGroups = [SELECT Id, reduivy__Job_Operation_Context__c FROM reduivy__Job_Queue_Group__c WHERE reduivy__Job_Operation_Context__c =: validJobQueue.reduivy__Job_Operation_Context__c];
            
        System.Assert.areEqual(1, jobQueueGroups.size(), 'A Job Queue group should be created.');
        
        String jobQueueGroupFields = 'Name;CreatedDate;reduivy__Total_Records__c;reduivy__Success_Records__c;reduivy__Error_Records__c;reduivy__Status__c';
        String jobQueueGroupStatuses = 'Pending;Processing;Completed;Failed';
        
        System.runAs(FACULTY_USER){
            Test.startTest();

            try {
                REDU_TermOfferingsCloning_LCTRL.getJobQueueData(JOB_OPERATION, stm[0].Id, jobQueueGroupFields, jobQueueGroupStatuses);
                System.Assert.fail('Expected an Exception for Insufficient access');
            } catch (Exception e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains('Insufficient'), 'Error message should contain the expected text');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test getJobQueueData() as student
     */
    @IsTest
    static void testGetJobQueueDataAsStudent(){
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Study_Term__c> stm = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID];

        reduivy__Job_Queue_Group__c jobQueueGroup1 = REDU_TestData_UTIL.newJobQueueGroup(
            JQH_Helper.getJobOperationContext(JOB_OPERATION, stm[0].Id),
            JQH_Helper.getJobOperationContext(JOB_OPERATION, stm[0].Id)
        );

        reduivy__Job_Queue_Group__c jobQueueGroup2 = REDU_TestData_UTIL.newJobQueueGroup(
            'Sample_Job',
            'Sample_Job'
        );

        REDU_Database_UTIL.doInsert(new List<reduivy__Job_Queue_Group__c>{jobQueueGroup1, jobQueueGroup2});

        //Create 2 dummy Job Queue records - 1 to be retrieved, the other to be ignored
        List<reduivy__Job_Queue__c> jqList = new List<reduivy__Job_Queue__c>();
        reduivy__Job_Queue__c validJobQueue = new reduivy__Job_Queue__c();
        validJobQueue.reduivy__Job_Operation__c = JOB_OPERATION;
        validJobQueue.reduivy__Job_Operation_Context__c = JQH_Helper.getJobOperationContext(JOB_OPERATION, stm[0].Id);
        validJobQueue.reduivy__Status__c = JQH_Helper.STATUS_PENDING;
        validJobQueue.reduivy__Job_Queue_Group__c = jobQueueGroup1.Id;

        reduivy__Job_Queue__c invalidJobQueue = new reduivy__Job_Queue__c();
        invalidJobQueue.reduivy__Job_Operation__c = 'Sample_Job';
        invalidJobQueue.reduivy__Job_Operation_Context__c = JQH_Helper.getJobOperationContext('Sample_Job', stm[0].Id);
        invalidJobQueue.reduivy__Status__c = JQH_Helper.STATUS_PENDING;
        invalidJobQueue.reduivy__Job_Queue_Group__c = jobQueueGroup2.Id;

        jqList.add(validJobQueue);
        jqList.add(invalidJobQueue);

        REDU_Database_UTIL.doInsert(jqList);

        List<reduivy__Job_Queue_Group__c> jobQueueGroups = [SELECT Id, reduivy__Job_Operation_Context__c FROM reduivy__Job_Queue_Group__c WHERE reduivy__Job_Operation_Context__c =: validJobQueue.reduivy__Job_Operation_Context__c];
            
        System.Assert.areEqual(1, jobQueueGroups.size(), 'A Job Queue group should be created.');
        
        String jobQueueGroupFields = 'Name;CreatedDate;reduivy__Total_Records__c;reduivy__Success_Records__c;reduivy__Error_Records__c;reduivy__Status__c';
        String jobQueueGroupStatuses = 'Pending;Processing;Completed;Failed';

        System.runAs(reduStudent){
            Test.startTest();

            try {
                REDU_TermOfferingsCloning_LCTRL.getJobQueueData(JOB_OPERATION, stm[0].Id, jobQueueGroupFields, jobQueueGroupStatuses);
                System.Assert.fail('Expected an Exception for Insufficient access');
            } catch (Exception e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains('Insufficient'), 'Error message should contain the expected text');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Negative Test for getJobQueueData()
     */
    @IsTest
    static void testgetJobQueueDataWithInvalidParams() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();

            List<reduivy__Study_Term__c> stm = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID];

            reduivy__Job_Queue_Group__c jobQueueGroup1 = REDU_TestData_UTIL.newJobQueueGroup(
                JQH_Helper.getJobOperationContext(JOB_OPERATION, stm[0].Id),
                JQH_Helper.getJobOperationContext(JOB_OPERATION, stm[0].Id)
            );

            reduivy__Job_Queue_Group__c jobQueueGroup2 = REDU_TestData_UTIL.newJobQueueGroup(
                'Sample_Job',
                'Sample_Job'
            );

            REDU_Database_UTIL.doInsert(new List<reduivy__Job_Queue_Group__c>{jobQueueGroup1, jobQueueGroup2});

            //Create 2 dummy Job Queue records - 1 to be retrieved, the other to be ignored
            List<reduivy__Job_Queue__c> jqList = new List<reduivy__Job_Queue__c>();
            reduivy__Job_Queue__c validJobQueue = new reduivy__Job_Queue__c();
            validJobQueue.reduivy__Job_Operation__c = JOB_OPERATION;
            validJobQueue.reduivy__Job_Operation_Context__c = JQH_Helper.getJobOperationContext(JOB_OPERATION, stm[0].Id);
            validJobQueue.reduivy__Status__c = JQH_Helper.STATUS_PENDING;
            validJobQueue.reduivy__Job_Queue_Group__c = jobQueueGroup1.Id;

            reduivy__Job_Queue__c invalidJobQueue = new reduivy__Job_Queue__c();
            invalidJobQueue.reduivy__Job_Operation__c = 'Sample_Job';
            invalidJobQueue.reduivy__Job_Operation_Context__c = JQH_Helper.getJobOperationContext('Sample_Job', stm[0].Id);
            invalidJobQueue.reduivy__Status__c = JQH_Helper.STATUS_PENDING;
            invalidJobQueue.reduivy__Job_Queue_Group__c = jobQueueGroup2.Id;

            jqList.add(validJobQueue);
            jqList.add(invalidJobQueue);

            REDU_Database_UTIL.doInsert(jqList);

            List<reduivy__Job_Queue_Group__c> jobQueueGroups = [SELECT Id, reduivy__Job_Operation_Context__c FROM reduivy__Job_Queue_Group__c WHERE reduivy__Job_Operation_Context__c =: validJobQueue.reduivy__Job_Operation_Context__c];
            
            System.Assert.areEqual(1, jobQueueGroups.size(), 'A Job Queue group should be created.');
            
            String jobQueueGroupFields = 'Name;CreatedDate;reduivy__Total_Records__c;reduivy__Success_Records__c;reduivy__Error_Records__c;reduivy__Status__c';
            String jobQueueGroupStatuses = 'Pending;Processing;Completed;Failed';

            //Test for blank jobOperation
            try {
                REDU_TermOfferingsCloning_LCTRL.getJobQueueData('', stm[0].Id, jobQueueGroupFields, jobQueueGroupStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank jobOperation');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'jobOperation'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank RecordId
            try {
                REDU_TermOfferingsCloning_LCTRL.getJobQueueData(JOB_OPERATION, '', jobQueueGroupFields, jobQueueGroupStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank jobOperation');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'RecordId'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank jobQueueGroupFields
            try {
                REDU_TermOfferingsCloning_LCTRL.getJobQueueData(JOB_OPERATION, stm[0].Id, '', jobQueueGroupStatuses);
                System.Assert.fail('Expected an AuraHandledException for blank jobOperation');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'jobQueueGroupFields'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }

            //Test for blank jobQueueGroupStatuses
            try {
                REDU_TermOfferingsCloning_LCTRL.getJobQueueData(JOB_OPERATION, stm[0].Id, jobQueueGroupFields, '');
                System.Assert.fail('Expected an AuraHandledException for blank jobOperation');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Missing_Required_Parameters, new List<String>{'jobQueueGroupStatuses'});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }
            
            Test.stopTest();
        }
    }
}