/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Test
 * @description Test class for IRQ_CreateTask_EXE
 * @changehistory
 * ISS-002128 12-06-2025 XW - create new class
 */
@IsTest
public inherited sharing class IRQ_CreateTask_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String SRS_LOCAL = 'SRS_Local';
    static final String SRS_GENERAL = 'SRS_General';
    static final String SRQ_LOCAL = 'SRS_Local_UploadID';
    static final String SRQ_GENERAL = 'SRS_General_UploadTranscript';
    
    static final String CON_STUDENT = 'sandydoe@redu.example';
    static final String SPL_MASTER = 'BACBIS_MajorA';
    static final String SPL_MASTERBULK = SPL_MASTER + 'BULK';
    static final String SPL_SECONDARY = 'BACBIS_MinorA';
    static final String SPG = 'BACBIS';
    static final String IRS_GENERAL = CON_STUDENT + '_' + SRS_GENERAL;
    static final String IRS_LOCAL = CON_STUDENT + '_' + SRS_LOCAL;

    static reduivy__Study_Requirement__c srqLocal;
    static reduivy__Study_Requirement__c srqGeneral;

    static reduivy__Individual_Requirement_Set__c irsLocal;
    static reduivy__Individual_Requirement_Set__c irsGeneral;

    static reduivy__Study_Program__c studyProgram;
    static Contact studentContact;
    static reduivy__Study_Plan__c masterStudyPlan;
    static reduivy__Study_Plan__c secondaryStudyPlan;
    
    static final Integer IPA_SIZE = 10;

    static String ERROR_MSG_CANNOT_INSERT_UPDATE = 'CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY';

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
        	
            testFactory.initMasterData(SRQ_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(IRS_Helper.getApiName(), true);

            reduivy__Study_Plan__c spl = testFactory.studyPlans.get(SPL_MASTER);
            List<reduivy__Study_Plan__c> splList = new List<reduivy__Study_Plan__c>();
            for(Integer i = 0; i < IPA_SIZE; i++) {
                reduivy__Study_Plan__c clonedSpl = new reduivy__Study_Plan__c(
                    Name = spl.Name,
                    reduivy__Study_Program__c = spl.reduivy__Study_Program__c
                );
                clonedSpl.reduivy__Sample_Record_Code__c = SPL_MASTERBULK;
                splList.add(clonedSpl);
            }

            insert splList;

            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for creating irq
     */
    @IsTest
    static void testForCreate_ActiveTrue_CreateTrue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        srqGeneral.reduivy__Create_Salesforce_Task__c = true;
        update srqGeneral;

        //create irq
        reduivy__Individual_Requirement__c newIrq;

		System.runAs(ADMIN_USER){
            newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
            insert newIrq;
		}

        List<Task> actualTaskList = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        reduivy__Individual_Requirement__c insertedIrq = [
            SELECT OwnerId, reduivy__Requirement_Details__c, reduivy__Due_Date__c, Name, reduivy__Priority__c
            FROM reduivy__Individual_Requirement__c
            WHERE Id = :newIrq.Id
            LIMIT 1
        ];

        System.Assert.areEqual(1, actualTaskList.size(), 'Wrong created Task list size!');
        System.Assert.areEqual(insertedIrq.OwnerId, actualTaskList[0].OwnerId);
        System.Assert.areEqual(insertedIrq.reduivy__Requirement_Details__c, actualTaskList[0].Description);
        System.Assert.areEqual(insertedIrq.reduivy__Due_Date__c, actualTaskList[0].ActivityDate);
        System.Assert.areEqual(insertedIrq.Name, actualTaskList[0].Subject);
        System.Assert.areEqual(insertedIrq.reduivy__Priority__c, actualTaskList[0].Priority);
        System.Assert.areEqual(irsGeneral.reduivy__Individual_Program_Application__c, actualTaskList[0].WhatId);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for creating irq, create salesforce task = false
     */
    @IsTest
    static void testForCreate_ActiveTrue_CreateFalse_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //create irq
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);

		System.runAs(ADMIN_USER){
            insert newIrq;
		}

        List<Task> actualTaskList = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.areEqual(0, actualTaskList.size(), 'Wrong created Task list size!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for creating irq, create salesforce task = false, active = false
     */
    @IsTest
    static void testForCreate_ActiveFalse_CreateFalse_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //create irq
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        newIrq.reduivy__Status__c = SRS_Helper.STATUS_DRAFT;

		System.runAs(ADMIN_USER){
            insert newIrq;
		}

        List<Task> actualTaskList = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.areEqual(0, actualTaskList.size(), 'Wrong created Task list size!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for creating irq, create salesforce task = true, active = false
     */
    @IsTest
    static void testForCreate_ActiveFalse_CreateTrue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        srqGeneral.reduivy__Create_Salesforce_Task__c = true;
        update srqGeneral;

        //create irq
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        newIrq.reduivy__Status__c = SRS_Helper.STATUS_DRAFT;

		System.runAs(ADMIN_USER){
            insert newIrq;
		}

        List<Task> actualTaskList = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.areEqual(0, actualTaskList.size(), 'Wrong created Task list size!');

        Test.stopTest();
		
    }
    
    /**
     * @description Test as admin for updating irq, create salesforce task to true
     */
    @IsTest
    static void testForUpdate_ActiveTrue_CreateToTrue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //create irq with create task = false
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);

        insert newIrq;

        List<Task> taskListBeforeUpdate = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.isTrue(taskListBeforeUpdate.isEmpty(), 'No task should be created! Task list size: ' + taskListBeforeUpdate.size());
        
        //update irq to create task = true
        System.runAs(ADMIN_USER){
            newIrq.reduivy__Create_Salesforce_Task__c = true;
            update newIrq;
		}
        
        List<Task> taskListAfterUpdate = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        reduivy__Individual_Requirement__c insertedIrq = [
            SELECT OwnerId, reduivy__Requirement_Details__c, reduivy__Due_Date__c, Name, reduivy__Priority__c
            FROM reduivy__Individual_Requirement__c
            WHERE Id = :newIrq.Id
            LIMIT 1
        ];

        System.Assert.areEqual(1, taskListAfterUpdate.size(), 'Wrong created Task list size!');
        System.Assert.areEqual(insertedIrq.OwnerId, taskListAfterUpdate[0].OwnerId);
        System.Assert.areEqual(insertedIrq.reduivy__Requirement_Details__c, taskListAfterUpdate[0].Description);
        System.Assert.areEqual(insertedIrq.reduivy__Due_Date__c, taskListAfterUpdate[0].ActivityDate);
        System.Assert.areEqual(insertedIrq.Name, taskListAfterUpdate[0].Subject);
        System.Assert.areEqual(insertedIrq.reduivy__Priority__c, taskListAfterUpdate[0].Priority);
        System.Assert.areEqual(irsGeneral.reduivy__Individual_Program_Application__c, taskListAfterUpdate[0].WhatId);

        Test.stopTest();
		
    }
	
    
    /**
     * @description Test as admin for updating irq, create salesforce task to true, active to false
     */
    @IsTest
    static void testForUpdate_ActiveToFalse_CreateToTrue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //create irq with create task = false
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);

        insert newIrq;

        List<Task> taskListBeforeUpdate = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.isTrue(taskListBeforeUpdate.isEmpty(), 'No task should be created! Task list size: ' + taskListBeforeUpdate.size());
        
        //update irq to create task = true
        System.runAs(ADMIN_USER){
            newIrq.reduivy__Create_Salesforce_Task__c = true;
            newIrq.reduivy__Status__c = SRS_Helper.STATUS_DRAFT;
            update newIrq;
		}
        
        List<Task> taskListAfterUpdate = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.isTrue(taskListAfterUpdate.isEmpty(), 'Task should not be created! Task size: ' + taskListAfterUpdate.size());

        Test.stopTest();
		
    }

    
    /**
     * @description Test as admin for creating irq
     */
    @IsTest
    static void testForBulkCreate_ActiveTrue_CreateTrue_AsAdmin() {
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        setSrqList();
        List<reduivy__Study_Plan__c> splList = getBulkMasterSpls();

        srqGeneral.reduivy__Create_Salesforce_Task__c = true;
        update srqGeneral;

        //create ipa
        List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();
        for(Integer i = 0; i < IPA_SIZE; i++) {
            reduivy__Individual_Program_Application__c ipa = generateIpa();
            ipa.reduivy__Application_Status__c = 'Submitted';
            ipa.reduivy__Sample_Record_Code__c = 'Bulk';
            ipa.reduivy__Master_Study_Plan__c = splList[i].Id;
            ipaList.add(ipa);
        }

		System.runAs(ADMIN_USER){
            insert ipaList;
		}

        Set<Id> expectedWhatIdSet = new Set<Id>();
        Map<Id, Task> actualWhatIdToTaskMap = new Map<Id, Task>();
        for(Task actualTask : [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ]) {
            actualWhatIdToTaskMap.put(actualTask.WhatId, actualTask);
        }

        
        Set<Id> expectedIpaIdSet = new Set<Id>();
        for(reduivy__Individual_Requirement__c actualIrq : [
            SELECT OwnerId, reduivy__Requirement_Details__c, reduivy__Due_Date__c, Name, reduivy__Priority__c, 
            reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__c
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__c IN :ipaList
            AND reduivy__Study_Requirement__c = :srqGeneral.Id
        ]) {
            Id ipaId = actualIrq.reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__c;
            expectedIpaIdSet.add(ipaId);

            System.Assert.areEqual(actualIrq.OwnerId, actualWhatIdToTaskMap.get(ipaId).OwnerId);
            System.Assert.areEqual(actualIrq.reduivy__Requirement_Details__c, actualWhatIdToTaskMap.get(ipaId).Description);
            System.Assert.areEqual(actualIrq.reduivy__Due_Date__c, actualWhatIdToTaskMap.get(ipaId).ActivityDate);
            System.Assert.areEqual(actualIrq.Name, actualWhatIdToTaskMap.get(ipaId).Subject);
            System.Assert.areEqual(actualIrq.reduivy__Priority__c, actualWhatIdToTaskMap.get(ipaId).Priority);
            System.Assert.areEqual(actualIrq.reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__c, actualWhatIdToTaskMap.get(ipaId).WhatId);
        }

        System.Assert.areEqual(10, actualWhatIdToTaskMap.size(), 'Wrong created Task list size!');
        System.Assert.areEqual(expectedIpaIdSet, actualWhatIdToTaskMap.keySet(), 'Wrong what id and irq id!');

        Test.stopTest();
		
    }
    
    /**
     * @description Test as admin for creating irq
     */
    @IsTest
    static void testForBulkUpdate_ActiveTrue_CreateToTrue_AsAdmin() {
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setSrqList();

        List<reduivy__Study_Plan__c> splList = getBulkMasterSpls();
        //create ipa
        List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();
        for(Integer i = 0; i < IPA_SIZE; i++) {
            reduivy__Individual_Program_Application__c ipa = generateIpa();
            ipa.reduivy__Application_Status__c = 'Submitted';
            ipa.reduivy__Sample_Record_Code__c = 'Bulk';
            ipa.reduivy__Master_Study_Plan__c = splList[i].Id;
            ipaList.add(ipa);
        }

		System.runAs(ADMIN_USER){
            insert ipaList;
		}

        List<Task> taskListBeforeUpdate = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.isTrue(taskListBeforeUpdate.isEmpty(), 'No task should be created! Task list size: ' + taskListBeforeUpdate.size());
        
        List<reduivy__Individual_Requirement__c> irqToUpdateList = new List<reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement__c irq : [
            SELECT Id
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__c IN :ipaList
            AND reduivy__Study_Requirement__c = :srqGeneral.Id
        ]) {
            irqToUpdateList.add(new reduivy__Individual_Requirement__c(Id = irq.Id, reduivy__Create_Salesforce_Task__c = true));
        }
        
        System.runAs(ADMIN_USER) {
            update irqToUpdateList;
        }

        Set<Id> expectedWhatIdSet = new Set<Id>();
        Map<Id, Task> actualWhatIdToTaskMap = new Map<Id, Task>();
        for(Task actualTask : [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ]) {
            actualWhatIdToTaskMap.put(actualTask.WhatId, actualTask);
        }

        
        Set<Id> expectedIpaIdSet = new Set<Id>();
        for(reduivy__Individual_Requirement__c actualIrq : [
            SELECT OwnerId, reduivy__Requirement_Details__c, reduivy__Due_Date__c, Name, reduivy__Priority__c, 
            reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__c
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__c IN :ipaList
            AND reduivy__Study_Requirement__c = :srqGeneral.Id
        ]) {
            Id ipaId = actualIrq.reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__c;
            expectedIpaIdSet.add(ipaId);

            System.Assert.areEqual(actualIrq.OwnerId, actualWhatIdToTaskMap.get(ipaId).OwnerId);
            System.Assert.areEqual(actualIrq.reduivy__Requirement_Details__c, actualWhatIdToTaskMap.get(ipaId).Description);
            System.Assert.areEqual(actualIrq.reduivy__Due_Date__c, actualWhatIdToTaskMap.get(ipaId).ActivityDate);
            System.Assert.areEqual(actualIrq.Name, actualWhatIdToTaskMap.get(ipaId).Subject);
            System.Assert.areEqual(actualIrq.reduivy__Priority__c, actualWhatIdToTaskMap.get(ipaId).Priority);
            System.Assert.areEqual(actualIrq.reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__c, actualWhatIdToTaskMap.get(ipaId).WhatId);
        }

        System.Assert.areEqual(10, actualWhatIdToTaskMap.size(), 'Wrong created Task list size!');
        System.Assert.areEqual(expectedIpaIdSet, actualWhatIdToTaskMap.keySet(), 'Wrong what id and irq id!');

        Test.stopTest();
		
    }
    /**
     * @description Test as faculty for creating irq
     */
    @IsTest
    static void testForCreate_ActiveTrue_CreateTrue_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        srqGeneral.reduivy__Create_Salesforce_Task__c = true;
        update srqGeneral;

        //create irq
        reduivy__Individual_Requirement__c newIrq;

		System.runAs(FACULTY_USER){
            newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
            insert newIrq;
		}

        List<Task> actualTaskList = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        reduivy__Individual_Requirement__c insertedIrq = [
            SELECT OwnerId, reduivy__Requirement_Details__c, reduivy__Due_Date__c, Name, reduivy__Priority__c
            FROM reduivy__Individual_Requirement__c
            WHERE Id = :newIrq.Id
            LIMIT 1
        ];

        System.Assert.areEqual(1, actualTaskList.size(), 'Wrong created Task list size!');
        System.Assert.areEqual(insertedIrq.OwnerId, actualTaskList[0].OwnerId);
        System.Assert.areEqual(insertedIrq.reduivy__Requirement_Details__c, actualTaskList[0].Description);
        System.Assert.areEqual(insertedIrq.reduivy__Due_Date__c, actualTaskList[0].ActivityDate);
        System.Assert.areEqual(insertedIrq.Name, actualTaskList[0].Subject);
        System.Assert.areEqual(insertedIrq.reduivy__Priority__c, actualTaskList[0].Priority);
        System.Assert.areEqual(irsGeneral.reduivy__Individual_Program_Application__c, actualTaskList[0].WhatId);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for creating irq, create salesforce task = false
     */
    @IsTest
    static void testForCreate_ActiveTrue_CreateFalse_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //create irq
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);

		System.runAs(FACULTY_USER){
            insert newIrq;
		}

        List<Task> actualTaskList = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.areEqual(0, actualTaskList.size(), 'Wrong created Task list size!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for creating irq, create salesforce task = false, active = false
     */
    @IsTest
    static void testForCreate_ActiveFalse_CreateFalse_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //create irq
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        newIrq.reduivy__Status__c = SRS_Helper.STATUS_DRAFT;

		System.runAs(FACULTY_USER){
            insert newIrq;
		}

        List<Task> actualTaskList = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.areEqual(0, actualTaskList.size(), 'Wrong created Task list size!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for creating irq, create salesforce task = true, active = false
     */
    @IsTest
    static void testForCreate_ActiveFalse_CreateTrue_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        srqGeneral.reduivy__Create_Salesforce_Task__c = true;
        update srqGeneral;

        //create irq
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        newIrq.reduivy__Status__c = SRS_Helper.STATUS_DRAFT;

		System.runAs(FACULTY_USER){
            insert newIrq;
		}

        List<Task> actualTaskList = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.areEqual(0, actualTaskList.size(), 'Wrong created Task list size!');

        Test.stopTest();
		
    }
    
    /**
     * @description Test as faculty for updating irq, create salesforce task to true
     */
    @IsTest
    static void testForUpdate_ActiveTrue_CreateToTrue_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //create irq with create task = false
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);

        insert newIrq;

        List<Task> taskListBeforeUpdate = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.isTrue(taskListBeforeUpdate.isEmpty(), 'No task should be created! Task list size: ' + taskListBeforeUpdate.size());
        
        //update irq to create task = true
        System.runAs(FACULTY_USER){
            newIrq.reduivy__Create_Salesforce_Task__c = true;
            update newIrq;
		}
        
        List<Task> taskListAfterUpdate = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        reduivy__Individual_Requirement__c insertedIrq = [
            SELECT OwnerId, reduivy__Requirement_Details__c, reduivy__Due_Date__c, Name, reduivy__Priority__c
            FROM reduivy__Individual_Requirement__c
            WHERE Id = :newIrq.Id
            LIMIT 1
        ];

        System.Assert.areEqual(1, taskListAfterUpdate.size(), 'Wrong created Task list size!');
        System.Assert.areEqual(insertedIrq.OwnerId, taskListAfterUpdate[0].OwnerId);
        System.Assert.areEqual(insertedIrq.reduivy__Requirement_Details__c, taskListAfterUpdate[0].Description);
        System.Assert.areEqual(insertedIrq.reduivy__Due_Date__c, taskListAfterUpdate[0].ActivityDate);
        System.Assert.areEqual(insertedIrq.Name, taskListAfterUpdate[0].Subject);
        System.Assert.areEqual(insertedIrq.reduivy__Priority__c, taskListAfterUpdate[0].Priority);
        System.Assert.areEqual(irsGeneral.reduivy__Individual_Program_Application__c, taskListAfterUpdate[0].WhatId);

        Test.stopTest();
		
    }
	
    
    /**
     * @description Test as faculty for updating irq, create salesforce task to true, active to false
     */
    @IsTest
    static void testForUpdate_ActiveToFalse_CreateToTrue_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //create irq with create task = false
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);

        insert newIrq;

        List<Task> taskListBeforeUpdate = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.isTrue(taskListBeforeUpdate.isEmpty(), 'No task should be created! Task list size: ' + taskListBeforeUpdate.size());
        
        //update irq to create task = true
        System.runAs(FACULTY_USER){
            newIrq.reduivy__Create_Salesforce_Task__c = true;
            newIrq.reduivy__Status__c = SRS_Helper.STATUS_DRAFT;
            update newIrq;
		}
        
        List<Task> taskListAfterUpdate = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.isTrue(taskListAfterUpdate.isEmpty(), 'Task should not be created! Task size: ' + taskListAfterUpdate.size());

        Test.stopTest();
		
    }

    
    /**
     * @description Test as student for creating irq
     */
    @IsTest
    static void testForCreate_ActiveTrue_CreateTrue_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        srqGeneral.reduivy__Create_Salesforce_Task__c = true;
        update srqGeneral;

        //create irq
        reduivy__Individual_Requirement__c newIrq;

        System.runAs(studentUser){
            newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
            insert newIrq;
		}

        List<Task> actualTaskList = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        reduivy__Individual_Requirement__c insertedIrq = [
            SELECT OwnerId, reduivy__Requirement_Details__c, reduivy__Due_Date__c, Name, reduivy__Priority__c
            FROM reduivy__Individual_Requirement__c
            WHERE Id = :newIrq.Id
            LIMIT 1
        ];

        System.Assert.areEqual(1, actualTaskList.size(), 'Wrong created Task list size!');
        System.Assert.areEqual(insertedIrq.OwnerId, actualTaskList[0].OwnerId);
        System.Assert.areEqual(insertedIrq.reduivy__Requirement_Details__c, actualTaskList[0].Description);
        System.Assert.areEqual(insertedIrq.reduivy__Due_Date__c, actualTaskList[0].ActivityDate);
        System.Assert.areEqual(insertedIrq.Name, actualTaskList[0].Subject);
        System.Assert.areEqual(insertedIrq.reduivy__Priority__c, actualTaskList[0].Priority);
        System.Assert.areEqual(irsGeneral.reduivy__Individual_Program_Application__c, actualTaskList[0].WhatId);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for creating irq, create salesforce task = false
     */
    @IsTest
    static void testForCreate_ActiveTrue_CreateFalse_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //create irq
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);

		System.runAs(studentUser){
            insert newIrq;
		}

        List<Task> actualTaskList = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.areEqual(0, actualTaskList.size(), 'Wrong created Task list size!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for creating irq, create salesforce task = false, active = false
     */
    @IsTest
    static void testForCreate_ActiveFalse_CreateFalse_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //create irq
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        newIrq.reduivy__Status__c = SRS_Helper.STATUS_DRAFT;

		System.runAs(studentUser){
            insert newIrq;
		}

        List<Task> actualTaskList = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.areEqual(0, actualTaskList.size(), 'Wrong created Task list size!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for creating irq, create salesforce task = true, active = false
     */
    @IsTest
    static void testForCreate_ActiveFalse_CreateTrue_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        srqGeneral.reduivy__Create_Salesforce_Task__c = true;
        update srqGeneral;

        //create irq
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        newIrq.reduivy__Status__c = SRS_Helper.STATUS_DRAFT;

		System.runAs(studentUser){
            insert newIrq;
		}

        List<Task> actualTaskList = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.areEqual(0, actualTaskList.size(), 'Wrong created Task list size!');

        Test.stopTest();
		
    }
    
    /**
     * @description Test as student for updating irq, create salesforce task to true
     */
    @IsTest
    static void testForUpdate_ActiveTrue_CreateToTrue_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //create irq with create task = false
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);

        insert newIrq;

        List<Task> taskListBeforeUpdate = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.isTrue(taskListBeforeUpdate.isEmpty(), 'No task should be created! Task list size: ' + taskListBeforeUpdate.size());
        
        //update irq to create task = true
        System.runAs(studentUser){
            newIrq.reduivy__Create_Salesforce_Task__c = true;
            update newIrq;
		}
        
        List<Task> taskListAfterUpdate = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        reduivy__Individual_Requirement__c insertedIrq = [
            SELECT OwnerId, reduivy__Requirement_Details__c, reduivy__Due_Date__c, Name, reduivy__Priority__c
            FROM reduivy__Individual_Requirement__c
            WHERE Id = :newIrq.Id
            LIMIT 1
        ];

        System.Assert.areEqual(1, taskListAfterUpdate.size(), 'Wrong created Task list size!');
        System.Assert.areEqual(insertedIrq.OwnerId, taskListAfterUpdate[0].OwnerId);
        System.Assert.areEqual(insertedIrq.reduivy__Requirement_Details__c, taskListAfterUpdate[0].Description);
        System.Assert.areEqual(insertedIrq.reduivy__Due_Date__c, taskListAfterUpdate[0].ActivityDate);
        System.Assert.areEqual(insertedIrq.Name, taskListAfterUpdate[0].Subject);
        System.Assert.areEqual(insertedIrq.reduivy__Priority__c, taskListAfterUpdate[0].Priority);
        System.Assert.areEqual(irsGeneral.reduivy__Individual_Program_Application__c, taskListAfterUpdate[0].WhatId);

        Test.stopTest();
		
    }
	
    
    /**
     * @description Test as student for updating irq, create salesforce task to true, active to false
     */
    @IsTest
    static void testForUpdate_ActiveToFalse_CreateToTrue_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //create irq with create task = false
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);

        insert newIrq;

        List<Task> taskListBeforeUpdate = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.isTrue(taskListBeforeUpdate.isEmpty(), 'No task should be created! Task list size: ' + taskListBeforeUpdate.size());
        
        //update irq to create task = true
        System.runAs(studentUser){
            newIrq.reduivy__Create_Salesforce_Task__c = true;
            newIrq.reduivy__Status__c = SRS_Helper.STATUS_DRAFT;
            update newIrq;
		}
        
        List<Task> taskListAfterUpdate = [
            SELECT Id, OwnerId, Description, ActivityDate, Subject, Priority, WhoId, WhatId
            FROM Task
        ];

        System.Assert.isTrue(taskListAfterUpdate.isEmpty(), 'Task should not be created! Task size: ' + taskListAfterUpdate.size());

        Test.stopTest();
		
    }

    static void setSrqList() {
        for(reduivy__Study_Requirement__c srq : [
            SELECT Id, Name, reduivy__Status__c, reduivy__Acceptance_Notes__c, reduivy__Due_Days__c, reduivy__Code__c, reduivy__Requirement_Details__c, reduivy__Requirement_Visibility__c, reduivy__Sequence__c, reduivy__Sample_Record_Code__c, reduivy__File_Category__c, reduivy__File_Visibility__c, reduivy__File_Format__c, reduivy__File_Count__c, reduivy__File_Share_Type__c, reduivy__Create_Salesforce_Task__c, reduivy__Priority__c, reduivy__Task_Owner_Id__c, reduivy__Requirement_Type__c, reduivy__Object_Relation_Field__c, reduivy__Object_Fields__c, reduivy__Link_To_Individual_Achievement__c, reduivy__Translation_Map__c
            FROM reduivy__Study_Requirement__c
        ]) {
            if(srq.reduivy__Sample_Record_Code__c == SRQ_LOCAL) {
                srqLocal = srq;
            } else if(srq.reduivy__Sample_Record_Code__c == SRQ_GENERAL) {
                srqGeneral = srq;
            } 
        }
    }

    static void setIrsList(){
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, reduivy__Status__c, reduivy__Code__c, reduivy__Description__c, reduivy__Study_Requirement_Set__c, reduivy__Total_Requirement__c, reduivy__Total_Reviewed__c, reduivy__Total_Submitted__c, reduivy__Sample_Record_Code__c, reduivy__Individual_Program_Application__c, OwnerId,
            (
                SELECT Id, Name, reduivy__Status__c, reduivy__Acceptance_Notes__c, reduivy__Due_Date__c, reduivy__Individual_Requirement_Set__c, reduivy__Code__c, reduivy__Requirement_Details__c, reduivy__Study_Requirement__c, reduivy__Requirement_Visibility__c, reduivy__Sequence__c, OwnerId, reduivy__Object_Relation_Field__c, reduivy__Object_Fields__c, reduivy__Link_To_Individual_Achievement__c
                FROM reduivy__Individual_Requirements__r
            )
            FROM reduivy__Individual_Requirement_Set__c
        ]) {
            if(irs.reduivy__Sample_Record_Code__c == IRS_LOCAL) {
                irsLocal = irs;
            } else if(irs.reduivy__Sample_Record_Code__c == IRS_GENERAL) {
                irsGeneral = irs;
            }
            if(irsLocal != null && irsGeneral != null) {
                break;
            }
        }
    }

    
    static reduivy__Study_Program__c getStudyProgram(){
        if(studyProgram == null) {
            for(reduivy__Study_Program__c spg : [
                SELECT Id, Name
                FROM reduivy__Study_Program__c
                WHERE reduivy__Sample_Record_Code__c = :SPG
            ]) {
                studyProgram = spg;
            }
        }

        return studyProgram;
    }

    static List<reduivy__Study_Plan__c> getBulkMasterSpls() {
        return [
                SELECT Id, Name
                FROM reduivy__Study_Plan__c
                WHERE reduivy__Sample_Record_Code__c = :SPL_MASTERBULK
            ];
    }


    static reduivy__Study_Plan__c getMasterSpl(){
        if(masterStudyPlan == null) {
            for(reduivy__Study_Plan__c spl : [
                SELECT Id, Name
                FROM reduivy__Study_Plan__c
                WHERE reduivy__Sample_Record_Code__c = :SPL_MASTER
            ]) {
                masterStudyPlan = spl;
            }
        }

        return masterStudyPlan;
    }

    static reduivy__Study_Plan__c getSecondarySpl() {
        if(secondaryStudyPlan == null) {
            for(reduivy__Study_Plan__c spl : [
                SELECT Id, Name
                FROM reduivy__Study_Plan__c
                WHERE reduivy__Sample_Record_Code__c = :SPL_SECONDARY
            ]){
                secondaryStudyPlan = spl;
            }  
        }

        return secondaryStudyPlan;
    }

    static Contact getStudent(){
        if(studentContact == null) {
            for(Contact con : [
                SELECT Id, Name
                FROM Contact
                WHERE reduivy__Sample_Record_Code__c = :CON_STUDENT
            ]) {
                studentContact = con;
            }
        }

        return studentContact;
    }

    static reduivy__Individual_Program_Application__c generateIpa(){
        return new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = getStudent().Id,
            reduivy__Study_Program__c = getStudyProgram().Id,
            reduivy__Master_Study_Plan__c = getMasterSpl().Id,
            reduivy__Secondary_Study_Plan__c = getSecondarySpl().Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = 'Draft'
        );
    }
}