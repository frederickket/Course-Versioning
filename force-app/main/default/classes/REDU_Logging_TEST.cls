/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_Logging_UTIL
 * @changehistory
 * 
 */
@isTest
public inherited sharing class REDU_Logging_TEST {

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

            Test.stopTest();
        }
    }

    /**
     * @description Test Logging Util method to log object as json string
     */
    @IsTest
    static void testlogDebugJsonString(){

        List<reduivy__Study_Unit__c> suList = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 1];

        System.Assert.areEqual(false, suList.isEmpty(), 'Failed to get list of Study Unit for testing');

        String prefix = 'prefix';
        
        Test.startTest();

        REDU_Logging_UTIL.debugJsonString(prefix, suList[0]);

        Test.stopTest();
    }

    /**
     * @description Test Logging Util method to log debug details
     */
    @IsTest
    static void testlogDebug(){

        List<reduivy__Study_Unit__c> suList = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 1];

        System.Assert.areEqual(false, suList.isEmpty(), 'Failed to get list of Study Unit for testing');

        String prefix = 'prefix';
        
        Test.startTest();

        REDU_Logging_UTIL.debug(prefix, suList[0]);

        Test.stopTest();
    }

    /**
     * @description Test Logging Util method to log debug details from exception
     */
    @IsTest
    static void testlogDebugException(){

        User setupUser = testFactory.getSetupUser();
        List<reduivy__Study_Unit__c> suList = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 1];

        System.Assert.areEqual(false, suList.isEmpty(), 'Failed to get list of Study Unit for testing');

        Test.startTest();

        try{

            System.runAs(setupUser){

                suList[0].reduivy__Educational_Institution__c = 'InvalidId';
                update suList;
            }
             
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
        }

        Test.stopTest();
    }

	/**
     * @description Test Logging Util method to log info record
     */
    @IsTest
    static void testlogInfo(){

        List<reduivy__Study_Unit__c> suList = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 1];

        System.Assert.areEqual(false, suList.isEmpty(), 'Failed to get list of Study Unit for testing');

        String errorTitle = 'Error';
        String reference = 'Reference';
        String objectName = 'reduivy__Study_Unit__c';
        String recordId = suList[0].Id;
        String message = 'testlogInfo';

        
        Test.startTest();

        REDU_Logging_UTIL.logInfo(errorTitle, reference, objectName, recordId, message);

        Test.stopTest();

        List<reduivy__Log__c> errorList = [SELECT Id, 
            Name, 
            reduivy__Reference__c, 
            reduivy__Object_Type__c,
            reduivy__Record_Id__c,
            reduivy__Type__c,
            reduivy__Short_Description__c,
            reduivy__Details__c
            FROM reduivy__Log__c
        ];

        System.Assert.areEqual(false, errorList.isEmpty(), 'Error logs not found');

        for (reduivy__Log__c log : errorList) {
            System.Assert.areEqual(errorTitle, log.Name);
            System.Assert.areEqual(reference, log.reduivy__Reference__c);
            System.Assert.areEqual(objectName, log.reduivy__Object_Type__c);
            System.Assert.areEqual(recordId, log.reduivy__Record_Id__c);
            System.Assert.areEqual(LOG_Helper.TYPE_INFO, log.reduivy__Type__c);
            System.Assert.areEqual(true, String.isNotBlank(log.reduivy__Short_Description__c));
            System.Assert.areEqual(true, String.isBlank(log.reduivy__Details__c));
        }
    }

    /**
     * @description Test Logging Util method to init info record
     */
    @IsTest
    static void testInitInfo(){

        List<reduivy__Study_Unit__c> suList = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 1];

        System.Assert.areEqual(false, suList.isEmpty(), 'Failed to get list of Study Unit for testing');

        String errorTitle = 'Error';
        String reference = 'Reference';
        String objectName = 'reduivy__Study_Unit__c';
        String recordId = suList[0].Id;
        String message = 'testlogInfo';

        
        Test.startTest();

        reduivy__Log__c newLog = REDU_Logging_UTIL.initInfo(errorTitle, reference, objectName, recordId, message);

        Test.stopTest();

        System.Assert.isNotNull(newLog, 'Error log is null');

        System.Assert.areEqual(errorTitle, newLog.Name);
        System.Assert.areEqual(reference, newLog.reduivy__Reference__c);
        System.Assert.areEqual(objectName, newLog.reduivy__Object_Type__c);
        System.Assert.areEqual(recordId, newLog.reduivy__Record_Id__c);
        System.Assert.areEqual(LOG_Helper.TYPE_INFO, newLog.reduivy__Type__c);
        System.Assert.areEqual(true, String.isNotBlank(newLog.reduivy__Short_Description__c));
        System.Assert.areEqual(true, String.isBlank(newLog.reduivy__Details__c));
    }

    /**
     * @description Test Logging Util method to log warning record
     */
    @IsTest
    static void testlogWarning(){

        List<reduivy__Study_Unit__c> suList = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 1];

        System.Assert.areEqual(false, suList.isEmpty(), 'Failed to get list of Study Unit for testing');

        String errorTitle = 'Error';
        String reference = 'Reference';
        String objectName = 'reduivy__Study_Unit__c';
        String recordId = suList[0].Id;
        String message = 'testlogInfo';

        
        Test.startTest();

        REDU_Logging_UTIL.logWarning(errorTitle, reference, objectName, recordId, message);

        Test.stopTest();

        List<reduivy__Log__c> errorList = [SELECT Id, 
            Name, 
            reduivy__Reference__c, 
            reduivy__Object_Type__c,
            reduivy__Record_Id__c,
            reduivy__Type__c,
            reduivy__Short_Description__c,
            reduivy__Details__c
            FROM reduivy__Log__c
        ];

        System.Assert.areEqual(false, errorList.isEmpty(), 'Error logs not found');

        for (reduivy__Log__c log : errorList) {
            System.Assert.areEqual(errorTitle, log.Name);
            System.Assert.areEqual(reference, log.reduivy__Reference__c);
            System.Assert.areEqual(objectName, log.reduivy__Object_Type__c);
            System.Assert.areEqual(recordId, log.reduivy__Record_Id__c);
            System.Assert.areEqual(LOG_Helper.TYPE_WARNING, log.reduivy__Type__c);
            System.Assert.areEqual(true, String.isNotBlank(log.reduivy__Short_Description__c));
            System.Assert.areEqual(true, String.isBlank(log.reduivy__Details__c));
        }
    }

    /**
     * @description Test Logging Util method to init warning record
     */
    @IsTest
    static void testInitWarning(){

        List<reduivy__Study_Unit__c> suList = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 1];

        System.Assert.areEqual(false, suList.isEmpty(), 'Failed to get list of Study Unit for testing');

        String errorTitle = 'Error';
        String reference = 'Reference';
        String objectName = 'reduivy__Study_Unit__c';
        String recordId = suList[0].Id;
        String message = 'testlogInfo';

        
        Test.startTest();

        reduivy__Log__c newLog = REDU_Logging_UTIL.initWarning(errorTitle, reference, objectName, recordId, message);

        Test.stopTest();

        System.Assert.isNotNull(newLog, 'Error log is null');

        System.Assert.areEqual(errorTitle, newLog.Name);
        System.Assert.areEqual(reference, newLog.reduivy__Reference__c);
        System.Assert.areEqual(objectName, newLog.reduivy__Object_Type__c);
        System.Assert.areEqual(recordId, newLog.reduivy__Record_Id__c);
        System.Assert.areEqual(LOG_Helper.TYPE_WARNING, newLog.reduivy__Type__c);
        System.Assert.areEqual(true, String.isNotBlank(newLog.reduivy__Short_Description__c));
        System.Assert.areEqual(true, String.isBlank(newLog.reduivy__Details__c));
    }

    /**
     * @description Test Logging Util method to log error record
     */
    @IsTest
    static void testlogError(){

        User setupUser = testFactory.getSetupUser();
        List<reduivy__Study_Unit__c> suList = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 1];

        System.Assert.areEqual(false, suList.isEmpty(), 'Failed to get list of Study Unit for testing');

        String errorTitle = 'Error';
        String reference = 'Reference';
        String objectName = 'reduivy__Study_Unit__c';
        String recordId = suList[0].Id;
        String message = 'testlogInfo';

        
        Test.startTest();

        try{

            System.runAs(setupUser){

                suList[0].reduivy__Educational_Institution__c = 'InvalidId';
                update suList;
            }
             
        } catch (Exception exp) {
            REDU_Logging_UTIL.logError(errorTitle, reference, objectName, recordId, message, exp);
        }

        Test.stopTest();

        List<reduivy__Log__c> errorList = [SELECT Id, 
            Name, 
            reduivy__Reference__c, 
            reduivy__Object_Type__c,
            reduivy__Record_Id__c,
            reduivy__Type__c,
            reduivy__Short_Description__c,
            reduivy__Details__c
            FROM reduivy__Log__c
        ];

        System.Assert.areEqual(false, errorList.isEmpty(), 'Error logs not found');

        for (reduivy__Log__c log : errorList) {
            System.Assert.areEqual(errorTitle, log.Name);
            System.Assert.areEqual(reference, log.reduivy__Reference__c);
            System.Assert.areEqual(objectName, log.reduivy__Object_Type__c);
            System.Assert.areEqual(recordId, log.reduivy__Record_Id__c);
            System.Assert.areEqual(LOG_Helper.TYPE_ERROR, log.reduivy__Type__c);
            System.Assert.areEqual(true, String.isNotBlank(log.reduivy__Short_Description__c));
            System.Assert.areEqual(true, String.isNotBlank(log.reduivy__Details__c));
        }
    }
	
    /**
     * @description Test Logging Util method to init error record
     */
    @IsTest
    static void testInitError(){

        List<reduivy__Study_Unit__c> suList = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 1];

        System.Assert.areEqual(false, suList.isEmpty(), 'Failed to get list of Study Unit for testing');

        String errorTitle = 'Error';
        String reference = 'Reference';
        String objectName = 'reduivy__Study_Unit__c';
        String recordId = suList[0].Id;
        String message = 'testlogInfo';

        
        Test.startTest();

        reduivy__Log__c newLog = REDU_Logging_UTIL.initError(errorTitle, reference, objectName, recordId, message, new REDU_ApplicationException('test exception'));

        Test.stopTest();

        System.Assert.isNotNull(newLog, 'Error log is null');

        System.Assert.areEqual(errorTitle, newLog.Name);
        System.Assert.areEqual(reference, newLog.reduivy__Reference__c);
        System.Assert.areEqual(objectName, newLog.reduivy__Object_Type__c);
        System.Assert.areEqual(recordId, newLog.reduivy__Record_Id__c);
        System.Assert.areEqual(LOG_Helper.TYPE_ERROR, newLog.reduivy__Type__c);
        System.Assert.areEqual(true, String.isNotBlank(newLog.reduivy__Short_Description__c));
        System.Assert.areEqual(true, String.isNotBlank(newLog.reduivy__Details__c));
    }

    /**
     * @description Test Logging Util method to init async job started log
     */
    @IsTest
    static void testInitAsyncJobStartedLog(){

        List<reduivy__Study_Unit__c> suList = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 1];

        System.Assert.areEqual(false, suList.isEmpty(), 'Failed to get list of Study Unit for testing');

        String jobOperation = 'Sample Job';
        String reference = 'Reference';
        JQH_JobQueue_OBJ sampleClassObj = new JQH_JobQueue_OBJ(jobOperation, new List<Id>{'a0v9n000001iBFR'}, new Map<String, Object>());
        
        String expectedTitle = String.format(Label.Job_Started_Log, new List<String>{jobOperation});
        String expectedMsg = String.format(Label.Processing_Records_Log_Details, new List<String>{String.valueOf(sampleClassObj)});

        Test.startTest();

        reduivy__Log__c newLog = REDU_Logging_UTIL.initAsyncJobStartedLog(jobOperation, reference, sampleClassObj);

        Test.stopTest();

        System.Assert.isNotNull(newLog, 'Error log is null');

        System.Assert.areEqual(expectedTitle, newLog.Name);
        System.Assert.areEqual(reference, newLog.reduivy__Reference__c);
        System.Assert.areEqual(true, String.isBlank(newLog.reduivy__Object_Type__c));
        System.Assert.areEqual(true, String.isBlank(newLog.reduivy__Record_Id__c));
        System.Assert.areEqual(LOG_Helper.TYPE_INFO, newLog.reduivy__Type__c);
        System.Assert.areEqual(expectedMsg, newLog.reduivy__Short_Description__c);
        System.Assert.areEqual(true, String.isBlank(newLog.reduivy__Details__c));
    }

    /**
     * @description Test Logging Util method to init async job completed log
     */
    @IsTest
    static void testInitAsyncJobCompletedLog(){

        List<reduivy__Study_Unit__c> suList = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 1];

        System.Assert.areEqual(false, suList.isEmpty(), 'Failed to get list of Study Unit for testing');

        String jobOperation = 'Sample Job';
        String reference = 'Reference';
        JQH_JobQueue_OBJ sampleClassObj = new JQH_JobQueue_OBJ(jobOperation, new List<Id>{'a0v9n000001iBFR'}, new Map<String, Object>());
        
        String expectedTitle = String.format(Label.Job_Completed_Log_Title, new List<String>{jobOperation});
        String expectedMsg = String.format(Label.Processed_Records_Log_Details, new List<String>{String.valueOf(sampleClassObj)});

        Test.startTest();

        reduivy__Log__c newLog = REDU_Logging_UTIL.initAsyncJobCompletedLog(jobOperation, reference, sampleClassObj);

        Test.stopTest();

        System.Assert.isNotNull(newLog, 'Error log is null');

        System.Assert.areEqual(expectedTitle, newLog.Name);
        System.Assert.areEqual(reference, newLog.reduivy__Reference__c);
        System.Assert.areEqual(true, String.isBlank(newLog.reduivy__Object_Type__c));
        System.Assert.areEqual(true, String.isBlank(newLog.reduivy__Record_Id__c));
        System.Assert.areEqual(LOG_Helper.TYPE_INFO, newLog.reduivy__Type__c);
        System.Assert.areEqual(expectedMsg, newLog.reduivy__Short_Description__c);
        System.Assert.areEqual(true, String.isBlank(newLog.reduivy__Details__c));
    }

    /**
     * @description Test Logging Util method to init async job completed with error log
     */
    @IsTest
    static void testInitAsyncJobCompletedWithErrorLog(){

        List<reduivy__Study_Unit__c> suList = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 1];

        System.Assert.areEqual(false, suList.isEmpty(), 'Failed to get list of Study Unit for testing');

        String jobOperation = 'Sample Job';
        String reference = 'Reference';
        JQH_JobQueue_OBJ sampleClassObj = new JQH_JobQueue_OBJ(jobOperation, new List<Id>{'a0v9n000001iBFR'}, new Map<String, Object>());
        
        String expectedTitle = String.format(Label.Job_Completed_With_Error_Log_Title, new List<String>{jobOperation});
        String expectedMsg = String.format(Label.Processed_Records_Log_Details, new List<String>{String.valueOf(sampleClassObj)});

        Test.startTest();

        reduivy__Log__c newLog = REDU_Logging_UTIL.initAsyncJobCompletedWithErrorLog(jobOperation, reference, sampleClassObj);

        Test.stopTest();

        System.Assert.isNotNull(newLog, 'Error log is null');

        System.Assert.areEqual(expectedTitle, newLog.Name);
        System.Assert.areEqual(reference, newLog.reduivy__Reference__c);
        System.Assert.areEqual(true, String.isBlank(newLog.reduivy__Object_Type__c));
        System.Assert.areEqual(true, String.isBlank(newLog.reduivy__Record_Id__c));
        System.Assert.areEqual(LOG_Helper.TYPE_ERROR, newLog.reduivy__Type__c);
        System.Assert.areEqual(expectedMsg, newLog.reduivy__Short_Description__c);
        System.Assert.areEqual(true, String.isBlank(newLog.reduivy__Details__c));
    }

    /**
     * @description Test Logging Util method to init async job failed log
     */
    @IsTest
    static void testInitAsyncJobFailedLog(){

        List<reduivy__Study_Unit__c> suList = [SELECT Id FROM reduivy__Study_Unit__c LIMIT 1];

        System.Assert.areEqual(false, suList.isEmpty(), 'Failed to get list of Study Unit for testing');

        String jobOperation = 'Sample Job';
        String reference = 'Reference';
        JQH_JobQueue_OBJ sampleClassObj = new JQH_JobQueue_OBJ(jobOperation, new List<Id>{'a0v9n000001iBFR'}, new Map<String, Object>());
        
        String sampleError = 'Sample Error';
        String expectedTitle = String.format(Label.Job_Failed_Log_Title, new List<String>{jobOperation});
        String expectedMsg = Label.Error_Contact_Admin + ' ' + sampleError + ' ' + String.valueOf(sampleClassObj) + '\n\n' + 'test exception';

        Test.startTest();

        reduivy__Log__c newLog = REDU_Logging_UTIL.initAsyncJobFailedLog(jobOperation, reference, sampleError, new REDU_ApplicationException('test exception'), sampleClassObj);

        Test.stopTest();

        System.Assert.isNotNull(newLog, 'Error log is null');

        System.Assert.areEqual(expectedTitle, newLog.Name);
        System.Assert.areEqual(reference, newLog.reduivy__Reference__c);
        System.Assert.areEqual(true, String.isBlank(newLog.reduivy__Object_Type__c));
        System.Assert.areEqual(true, String.isBlank(newLog.reduivy__Record_Id__c));
        System.Assert.areEqual(LOG_Helper.TYPE_ERROR, newLog.reduivy__Type__c);
        System.Assert.areEqual(expectedMsg, newLog.reduivy__Short_Description__c.trim());
        System.Assert.areEqual(true, String.isNotBlank(newLog.reduivy__Details__c));
    }
}