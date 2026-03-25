/**
 * @author      WDCi (Lean)
 * @date        Dec 2024
 * @group       Test
 * @description Test class for JQH_AddJob_FLOW
 * @changehistory
 * ISS-002219 31-12-2024 Lean - new class
 * ISS-002547 14-07-2025 Lean - Added jobOperationContext
 */

@IsTest
public inherited sharing class JQH_ExecuteJobGenerator_TEST {
    
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

        	testFactory.initMasterData(SPS_Helper.getApiName());
            testFactory.initOfferingData(SOF_Helper.getApiName());
			testFactory.initStudentData(IEN_Helper.getApiName(), false);

            Test.stopTest();
        }
    }

    /**
     * @description Test execute generator as admin
     */
    @IsTest
    static void testExecuteGeneratorWithWorkerAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();

        Map<Id, reduivy__Study_Offering__c> softMaps = new Map<Id, reduivy__Study_Offering__c>([
            SELECT Id 
            FROM reduivy__Study_Offering__c
        ]);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //simulate the data from flow
            JQH_ExecuteJobGenerator_FLOW.Request flowRequest = new JQH_ExecuteJobGenerator_FLOW.Request();
            flowRequest.jobOperationContext = 'Sample_Job';
            flowRequest.jobOperation = 'Sample_Job';
            flowRequest.paramsString = JQH_Helper.serializeParams(params);
            flowRequest.recordIds = new List<Id>(softMaps.keySet());
            flowRequest.startWorker = true;

            //invoke the method
            List<JQH_ExecuteJobGenerator_FLOW.Response> responses = JQH_ExecuteJobGenerator_FLOW.execute(new List<JQH_ExecuteJobGenerator_FLOW.Request>{flowRequest});

            System.Assert.areEqual(Label.Job_Generator_Was_Executed, responses.get(0).message);
            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
        }

        Test.stopTest();

        Integer generatorJobCount = [SELECT COUNT() 
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            AND ApexClass.Name = 'JQH_JobGenerator_QUEUE'
            AND Status = 'Completed'
            AND CreatedById =: ADMIN_USER.Id
            WITH USER_MODE
        ];

        System.Assert.areEqual(1, generatorJobCount);
    }

    /**
     * @description Test execute generator without starting the worker as admin
     */
    @IsTest
    static void testExecuteGeneratorWithoutWorkerAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();

        Map<Id, reduivy__Study_Offering__c> softMaps = new Map<Id, reduivy__Study_Offering__c>([
            SELECT Id 
            FROM reduivy__Study_Offering__c
        ]);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //simulate the data from flow
            JQH_ExecuteJobGenerator_FLOW.Request flowRequest = new JQH_ExecuteJobGenerator_FLOW.Request();
            flowRequest.jobOperationContext = 'Sample_Job';
            flowRequest.jobOperation = 'Sample_Job';
            flowRequest.paramsString = JQH_Helper.serializeParams(params);
            flowRequest.recordIds = new List<Id>(softMaps.keySet());
            flowRequest.startWorker = false;

            //invoke the method
            List<JQH_ExecuteJobGenerator_FLOW.Response> responses = JQH_ExecuteJobGenerator_FLOW.execute(new List<JQH_ExecuteJobGenerator_FLOW.Request>{flowRequest});

            System.Assert.areEqual(Label.Job_Generator_Was_Executed, responses.get(0).message);
            System.Assert.areEqual(JQH_JobManager.SUCCESS, responses.get(0).status);
        }

        Test.stopTest();

        Integer generatorJobCount = [SELECT COUNT() 
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            AND ApexClass.Name = 'JQH_JobGenerator_QUEUE'
            AND Status = 'Completed'
            AND CreatedById =: ADMIN_USER.Id
            WITH USER_MODE
        ];

        System.Assert.areEqual(1, generatorJobCount);
    }

    /**
     * @description Test execute generator with invalid operation as admin
     */
    @IsTest
    static void testExecuteGeneratorWithInvalidOperationAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();

        Map<Id, reduivy__Study_Offering__c> softMaps = new Map<Id, reduivy__Study_Offering__c>([
            SELECT Id 
            FROM reduivy__Study_Offering__c
        ]);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //simulate the data from flow
            JQH_ExecuteJobGenerator_FLOW.Request flowRequest = new JQH_ExecuteJobGenerator_FLOW.Request();
            flowRequest.jobOperationContext = 'Invalid_Job_Operation';
            flowRequest.jobOperation = 'Invalid_Job_Operation';
            flowRequest.paramsString = JQH_Helper.serializeParams(params);
            flowRequest.recordIds = new List<Id>(softMaps.keySet());
            flowRequest.startWorker = true;

            //invoke the method
            List<JQH_ExecuteJobGenerator_FLOW.Response> responses = JQH_ExecuteJobGenerator_FLOW.execute(new List<JQH_ExecuteJobGenerator_FLOW.Request>{flowRequest});

            String expectedError = String.format(Label.Missing_Job_Queue_Config, new List<String>{flowRequest.jobOperation});
            System.Assert.areEqual(expectedError, responses.get(0).message);
            System.Assert.areEqual(JQH_JobManager.FAIL, responses.get(0).status);

        }

        Test.stopTest();
    }

    /**
     * @description Test execute generator with missing generator class as admin
     */
    @IsTest
    static void testExecuteGeneratorWithMissingGeneratorClassAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();

        Map<Id, reduivy__Study_Offering__c> softMaps = new Map<Id, reduivy__Study_Offering__c>([
            SELECT Id 
            FROM reduivy__Study_Offering__c
        ]);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //simulate the data from flow
            JQH_ExecuteJobGenerator_FLOW.Request flowRequest = new JQH_ExecuteJobGenerator_FLOW.Request();
            flowRequest.jobOperationContext = 'Sample_Error_Job';
            flowRequest.jobOperation = 'Sample_Error_Job';
            flowRequest.paramsString = JQH_Helper.serializeParams(params);
            flowRequest.recordIds = new List<Id>(softMaps.keySet());
            flowRequest.startWorker = true;

            //invoke the method
            List<JQH_ExecuteJobGenerator_FLOW.Response> responses = JQH_ExecuteJobGenerator_FLOW.execute(new List<JQH_ExecuteJobGenerator_FLOW.Request>{flowRequest});

            String expectedError = Label.Missing_Job_Generator_Class_Name;
            System.Assert.areEqual(expectedError, responses.get(0).message);
            System.Assert.areEqual(JQH_JobManager.FAIL, responses.get(0).status);

        }

        Test.stopTest();
    }

    /**
     * @description Test execute generator with missing job operation context as admin
     */
    @IsTest
    static void testExecuteGeneratorWithMissingJobOperationContextAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();

        Map<Id, reduivy__Study_Offering__c> softMaps = new Map<Id, reduivy__Study_Offering__c>([
            SELECT Id 
            FROM reduivy__Study_Offering__c
        ]);

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //simulate the data from flow
            JQH_ExecuteJobGenerator_FLOW.Request flowRequest = new JQH_ExecuteJobGenerator_FLOW.Request();
            flowRequest.jobOperation = 'Sample_Job';
            flowRequest.paramsString = JQH_Helper.serializeParams(params);
            flowRequest.recordIds = new List<Id>(softMaps.keySet());
            flowRequest.startWorker = true;

            //invoke the method
            List<JQH_ExecuteJobGenerator_FLOW.Response> responses = JQH_ExecuteJobGenerator_FLOW.execute(new List<JQH_ExecuteJobGenerator_FLOW.Request>{flowRequest});

            System.Assert.areEqual(Label.Missing_Job_Operation_Context, responses.get(0).message);
            System.Assert.areEqual(JQH_JobManager.FAIL, responses.get(0).status);
        }

        Test.stopTest();
    }
}