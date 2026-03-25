/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Test
 * @description Test class for IRS_CreateIndividualRequirement_EXE
 * @changehistory
 * ISS-002128 05-06-2025 XW - new class
 */
@IsTest
public inherited sharing class IRS_CreateIndividualRequirement_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static final String SRS_LOCAL = 'SRS_Local';
    static final String SRS_GENERAL = 'SRS_General';

    static reduivy__Study_Requirement_Set__c srsLocal;
    static reduivy__Study_Requirement_Set__c srsGeneral;

    static Set<String> IRQ_SRQ_COMMON_FIELDS = new Set<String>{
        'reduivy__Status__c',
        'reduivy__Acceptance_Notes__c',
        'reduivy__Create_Salesforce_Task__c',
        'reduivy__File_Category__c',
        'reduivy__File_Count__c',
        'reduivy__File_Format__c',
        'reduivy__File_Share_Type__c',
        'reduivy__File_Visibility__c',
        'reduivy__Priority__c',
        'reduivy__Code__c',
        'reduivy__Requirement_Details__c',
        'reduivy__Requirement_Type__c',
        'reduivy__Requirement_Visibility__c',
        'reduivy__Sequence__c',
        'reduivy__Task_Owner_Id__c'
    };

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
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(USR_Helper.getApiName(), true);

            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for create irs with active = false
     */
    @IsTest
    static void testForCreate_ActiveFalse_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        setSrsList();
        reduivy__Individual_Requirement_Set__c irs = IRS_Helper.createIrs(srsLocal, null, srsLocal.OwnerId);
        irs.reduivy__Status__c = IRS_Helper.STATUS_DRAFT;


		System.runAs(ADMIN_USER){
            insert irs;
		}
        
        List<reduivy__Individual_Requirement__c> actualIrqList = [
            SELECT Id, Name, reduivy__Status__c, reduivy__Acceptance_Notes__c, reduivy__Due_Date__c, reduivy__Individual_Requirement_Set__c, reduivy__Code__c, reduivy__Requirement_Details__c, reduivy__Study_Requirement__c, reduivy__Requirement_Visibility__c, reduivy__Sequence__c
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Individual_Requirement_Set__c = :irs.Id
        ];

        System.Assert.isTrue(actualIrqList.isEmpty(), 'Irq should be empty!');

        Test.stopTest();
		
		
    }
	
    /**
     * @description Test as admin for create irs with active = true
     */
    @IsTest
    static void testForCreate_ActiveTrue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        setSrsList();
        reduivy__Individual_Requirement_Set__c irs = IRS_Helper.createIrs(srsLocal, null, srsLocal.OwnerId);

		System.runAs(ADMIN_USER){
            insert irs;
		}
        
        Integer actualIrqCount = 0;

        for(reduivy__Individual_Requirement__c actualIrq : [
            SELECT Name, Id, reduivy__Status__c, reduivy__Acceptance_Notes__c, reduivy__Create_Salesforce_Task__c, reduivy__File_Category__c, reduivy__File_Count__c, reduivy__File_Format__c, reduivy__File_Share_Type__c, reduivy__File_Visibility__c, reduivy__Priority__c, reduivy__Code__c, reduivy__Requirement_Details__c, reduivy__Requirement_Type__c, reduivy__Requirement_Visibility__c, reduivy__Sequence__c, reduivy__Task_Owner_Id__c, reduivy__Due_Date__c, reduivy__Individual_Requirement_Set__c,
            reduivy__Study_Requirement__r.Name, reduivy__Study_Requirement__r.Id, reduivy__Study_Requirement__r.reduivy__Status__c, reduivy__Study_Requirement__r.reduivy__Acceptance_Notes__c, reduivy__Study_Requirement__r.reduivy__Create_Salesforce_Task__c, reduivy__Study_Requirement__r.reduivy__File_Category__c, reduivy__Study_Requirement__r.reduivy__File_Count__c, reduivy__Study_Requirement__r.reduivy__File_Format__c, reduivy__Study_Requirement__r.reduivy__File_Share_Type__c, reduivy__Study_Requirement__r.reduivy__File_Visibility__c, reduivy__Study_Requirement__r.reduivy__Priority__c, reduivy__Study_Requirement__r.reduivy__Code__c, reduivy__Study_Requirement__r.reduivy__Requirement_Details__c, reduivy__Study_Requirement__r.reduivy__Requirement_Type__c, reduivy__Study_Requirement__r.reduivy__Requirement_Visibility__c, reduivy__Study_Requirement__r.reduivy__Sequence__c, reduivy__Study_Requirement__r.reduivy__Task_Owner_Id__c, reduivy__Study_Requirement__r.reduivy__Due_Days__c, reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__c
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Individual_Requirement_Set__c = :irs.Id
        ]){
            actualIrqCount++;
            System.Assert.isTrue(
                String.isNotBlank(actualIrq.reduivy__Study_Requirement__c), 
                'reduivy__Study_Requirement__c should be set!'
            );   
            for(String field : IRQ_SRQ_COMMON_FIELDS) {
                System.Assert.areEqual(actualIrq.reduivy__Study_Requirement__r.get(field), actualIrq.get(field), 'Wrong ' + field + '!');
            }
            System.Assert.areEqual(
                System.today().addDays(actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue()), 
                actualIrq.reduivy__Due_Date__c, 
                'Wrong reduivy__Due_Date__c! System.today() = ' + System.today() + ', actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue() = ' + actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue() + '! '
            );
            System.Assert.areEqual(
                irs.Id, 
                actualIrq.reduivy__Individual_Requirement_Set__c, 
                'Wrong reduivy__Individual_Requirement_Set__c!'
            );        
        }

        System.Assert.areEqual(2, actualIrqCount, 'Irq size should be the same!');

        Test.stopTest();
    }
	
    /**
     * @description Test as admin for create irs with active = true
     */
    @IsTest
    static void testForCreate2Irs_ActiveTrue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        setSrsList();
        reduivy__Individual_Requirement_Set__c irsLocal = IRS_Helper.createIrs(srsLocal, null, srsLocal.OwnerId);
        reduivy__Individual_Requirement_Set__c irsGeneral = IRS_Helper.createIrs(srsGeneral, null, srsLocal.OwnerId);
        List<reduivy__Individual_Requirement_Set__c> irsList = new List<reduivy__Individual_Requirement_Set__c>{ irsLocal, irsGeneral };

		System.runAs(ADMIN_USER){
            insert irsList;
		}
        
        List<reduivy__Individual_Requirement__c> actualIrqList = new List<reduivy__Individual_Requirement__c>();
        Integer actualIrqCount = 0;

        for(reduivy__Individual_Requirement__c actualIrq : [
            SELECT Name, Id, reduivy__Status__c, reduivy__Acceptance_Notes__c, reduivy__Create_Salesforce_Task__c, reduivy__File_Category__c, reduivy__File_Count__c, reduivy__File_Format__c, reduivy__File_Share_Type__c, reduivy__File_Visibility__c, reduivy__Priority__c, reduivy__Code__c, reduivy__Requirement_Details__c, reduivy__Requirement_Type__c, reduivy__Requirement_Visibility__c, reduivy__Sequence__c, reduivy__Task_Owner_Id__c, reduivy__Due_Date__c, reduivy__Individual_Requirement_Set__c,
            reduivy__Study_Requirement__r.Name, reduivy__Study_Requirement__r.Id, reduivy__Study_Requirement__r.reduivy__Status__c, reduivy__Study_Requirement__r.reduivy__Acceptance_Notes__c, reduivy__Study_Requirement__r.reduivy__Create_Salesforce_Task__c, reduivy__Study_Requirement__r.reduivy__File_Category__c, reduivy__Study_Requirement__r.reduivy__File_Count__c, reduivy__Study_Requirement__r.reduivy__File_Format__c, reduivy__Study_Requirement__r.reduivy__File_Share_Type__c, reduivy__Study_Requirement__r.reduivy__File_Visibility__c, reduivy__Study_Requirement__r.reduivy__Priority__c, reduivy__Study_Requirement__r.reduivy__Code__c, reduivy__Study_Requirement__r.reduivy__Requirement_Details__c, reduivy__Study_Requirement__r.reduivy__Requirement_Type__c, reduivy__Study_Requirement__r.reduivy__Requirement_Visibility__c, reduivy__Study_Requirement__r.reduivy__Sequence__c, reduivy__Study_Requirement__r.reduivy__Task_Owner_Id__c, reduivy__Study_Requirement__r.reduivy__Due_Days__c, reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__c
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Individual_Requirement_Set__c IN :irsList
        ]){
            actualIrqCount++;
            System.Assert.isTrue(
                String.isNotBlank(actualIrq.reduivy__Study_Requirement__c), 
                'reduivy__Study_Requirement__c should be set!'
            );   
            for(String field : IRQ_SRQ_COMMON_FIELDS) {
                System.Assert.areEqual(actualIrq.reduivy__Study_Requirement__r.get(field), actualIrq.get(field), 'Wrong ' + field + '!');
            }
            System.Assert.areEqual(
                System.today().addDays(actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue()), 
                actualIrq.reduivy__Due_Date__c, 
                'Wrong reduivy__Due_Date__c! System.today() = ' + System.today() + ', actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue() = ' + actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue() + '! '
            );
            if(actualIrq.reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__c == srsLocal.Id) {
                System.Assert.areEqual(
                    irsLocal.Id, 
                    actualIrq.reduivy__Individual_Requirement_Set__c, 
                    'Wrong reduivy__Individual_Requirement_Set__c!'
                );
            } else if (actualIrq.reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__c == srsGeneral.Id) {
                System.Assert.areEqual(
                    irsGeneral.Id, 
                    actualIrq.reduivy__Individual_Requirement_Set__c, 
                    'Wrong reduivy__Individual_Requirement_Set__c!'
                );
            }
        }

        System.Assert.areEqual(4, actualIrqCount, 'Irs size should be the same!');
        Test.stopTest();
    }

    /**
     * @description Test as admin for create irs with active = true, bulk
     */
    @IsTest
    static void testForBulkCreateIrs_ActiveTrue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        setSrsList();
        List<reduivy__Individual_Requirement_Set__c> irsList = new List<reduivy__Individual_Requirement_Set__c>();

        for(Integer i = 0; i < 10; i++) {
            reduivy__Individual_Requirement_Set__c irsLocal = IRS_Helper.createIrs(srsLocal, null, srsLocal.OwnerId);
            irsList.add(irsLocal);
        }

		System.runAs(ADMIN_USER){
            insert irsList;
		}
        
        Set<Id> actualIrsIdSet = new Set<Id>();
        List<reduivy__Individual_Requirement__c> actualIrqList = new List<reduivy__Individual_Requirement__c>();
        Integer actualIrqCount = 0;

        for(reduivy__Individual_Requirement__c actualIrq : [
            SELECT Name, Id, reduivy__Status__c, reduivy__Acceptance_Notes__c, reduivy__Create_Salesforce_Task__c, reduivy__File_Category__c, reduivy__File_Count__c, reduivy__File_Format__c, reduivy__File_Share_Type__c, reduivy__File_Visibility__c, reduivy__Priority__c, reduivy__Code__c, reduivy__Requirement_Details__c, reduivy__Requirement_Type__c, reduivy__Requirement_Visibility__c, reduivy__Sequence__c, reduivy__Task_Owner_Id__c, reduivy__Due_Date__c, reduivy__Individual_Requirement_Set__c,
            reduivy__Study_Requirement__r.Name, reduivy__Study_Requirement__r.Id, reduivy__Study_Requirement__r.reduivy__Status__c, reduivy__Study_Requirement__r.reduivy__Acceptance_Notes__c, reduivy__Study_Requirement__r.reduivy__Create_Salesforce_Task__c, reduivy__Study_Requirement__r.reduivy__File_Category__c, reduivy__Study_Requirement__r.reduivy__File_Count__c, reduivy__Study_Requirement__r.reduivy__File_Format__c, reduivy__Study_Requirement__r.reduivy__File_Share_Type__c, reduivy__Study_Requirement__r.reduivy__File_Visibility__c, reduivy__Study_Requirement__r.reduivy__Priority__c, reduivy__Study_Requirement__r.reduivy__Code__c, reduivy__Study_Requirement__r.reduivy__Requirement_Details__c, reduivy__Study_Requirement__r.reduivy__Requirement_Type__c, reduivy__Study_Requirement__r.reduivy__Requirement_Visibility__c, reduivy__Study_Requirement__r.reduivy__Sequence__c, reduivy__Study_Requirement__r.reduivy__Task_Owner_Id__c, reduivy__Study_Requirement__r.reduivy__Due_Days__c, reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__c
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Individual_Requirement_Set__c IN :irsList
        ]){

            actualIrsIdSet.add(actualIrq.reduivy__Individual_Requirement_Set__c);
            actualIrqCount++;
            System.Assert.isTrue(
                String.isNotBlank(actualIrq.reduivy__Study_Requirement__c), 
                'reduivy__Study_Requirement__c should be set!'
            );   
            for(String field : IRQ_SRQ_COMMON_FIELDS) {
                System.Assert.areEqual(actualIrq.reduivy__Study_Requirement__r.get(field), actualIrq.get(field), 'Wrong ' + field + '!');
            }
            System.Assert.areEqual(
                System.today().addDays(actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue()), 
                actualIrq.reduivy__Due_Date__c, 
                'Wrong reduivy__Due_Date__c! System.today() = ' + System.today() + ', actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue() = ' + actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue() + '! '
            );
        }


        System.Assert.areEqual(20, actualIrqCount, 'Irq size should be the same!');
        System.Assert.areEqual(10, actualIrsIdSet.size(), 'Irs size should be the same!');
        
        Test.stopTest();
    }


	/**
     * @description Test as faculty for create irs with active = false
     */
    @IsTest
    static void testForCreate_ActiveFalse_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        setSrsList();
        reduivy__Individual_Requirement_Set__c irs = IRS_Helper.createIrs(srsLocal, null, srsLocal.OwnerId);
        irs.reduivy__Status__c = IRS_Helper.STATUS_DRAFT;


		System.runAs(FACULTY_USER){
            insert irs;
		}
        
        List<reduivy__Individual_Requirement__c> actualIrqList = [
            SELECT Id, Name, reduivy__Status__c, reduivy__Acceptance_Notes__c, reduivy__Due_Date__c, reduivy__Individual_Requirement_Set__c, reduivy__Code__c, reduivy__Requirement_Details__c, reduivy__Study_Requirement__c, reduivy__Requirement_Visibility__c, reduivy__Sequence__c
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Individual_Requirement_Set__c = :irs.Id
        ];

        System.Assert.isTrue(actualIrqList.isEmpty(), 'Irs should be empty!');

        Test.stopTest();
		
		
    }
	
    /**
     * @description Test as faculty for create irs with active = true
     */
    @IsTest
    static void testForCreate_ActiveTrue_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        setSrsList();
        reduivy__Individual_Requirement_Set__c irs = IRS_Helper.createIrs(srsLocal, null, srsLocal.OwnerId);

		System.runAs(FACULTY_USER){
            insert irs;
		}
        
        Integer actualIrqCount = 0;

        for(reduivy__Individual_Requirement__c actualIrq : [
            SELECT Name, Id, reduivy__Status__c, reduivy__Acceptance_Notes__c, reduivy__Create_Salesforce_Task__c, reduivy__File_Category__c, reduivy__File_Count__c, reduivy__File_Format__c, reduivy__File_Share_Type__c, reduivy__File_Visibility__c, reduivy__Priority__c, reduivy__Code__c, reduivy__Requirement_Details__c, reduivy__Requirement_Type__c, reduivy__Requirement_Visibility__c, reduivy__Sequence__c, reduivy__Task_Owner_Id__c, reduivy__Due_Date__c, reduivy__Individual_Requirement_Set__c,
            reduivy__Study_Requirement__r.Name, reduivy__Study_Requirement__r.Id, reduivy__Study_Requirement__r.reduivy__Status__c, reduivy__Study_Requirement__r.reduivy__Acceptance_Notes__c, reduivy__Study_Requirement__r.reduivy__Create_Salesforce_Task__c, reduivy__Study_Requirement__r.reduivy__File_Category__c, reduivy__Study_Requirement__r.reduivy__File_Count__c, reduivy__Study_Requirement__r.reduivy__File_Format__c, reduivy__Study_Requirement__r.reduivy__File_Share_Type__c, reduivy__Study_Requirement__r.reduivy__File_Visibility__c, reduivy__Study_Requirement__r.reduivy__Priority__c, reduivy__Study_Requirement__r.reduivy__Code__c, reduivy__Study_Requirement__r.reduivy__Requirement_Details__c, reduivy__Study_Requirement__r.reduivy__Requirement_Type__c, reduivy__Study_Requirement__r.reduivy__Requirement_Visibility__c, reduivy__Study_Requirement__r.reduivy__Sequence__c, reduivy__Study_Requirement__r.reduivy__Task_Owner_Id__c, reduivy__Study_Requirement__r.reduivy__Due_Days__c, reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__c
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Individual_Requirement_Set__c = :irs.Id
        ]){
            actualIrqCount++;
            System.Assert.isTrue(
                String.isNotBlank(actualIrq.reduivy__Study_Requirement__c), 
                'reduivy__Study_Requirement__c should be set!'
            );   
            for(String field : IRQ_SRQ_COMMON_FIELDS) {
                System.Assert.areEqual(actualIrq.reduivy__Study_Requirement__r.get(field), actualIrq.get(field), 'Wrong ' + field + '!');
            }
            System.Assert.areEqual(
                System.today().addDays(actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue()), 
                actualIrq.reduivy__Due_Date__c, 
                'Wrong reduivy__Due_Date__c! System.today() = ' + System.today() + ', actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue() = ' + actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue() + '! '
            );
            System.Assert.areEqual(
                irs.Id, 
                actualIrq.reduivy__Individual_Requirement_Set__c, 
                'Wrong reduivy__Individual_Requirement_Set__c!'
            );        
        }

        System.Assert.areEqual(2, actualIrqCount, 'Irs size should be the same!');

        Test.stopTest();
    }
	
    /**
     * @description Test as faculty for create irs with active = true
     */
    @IsTest
    static void testForCreate2Irs_ActiveTrue_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        setSrsList();
        reduivy__Individual_Requirement_Set__c irsLocal = IRS_Helper.createIrs(srsLocal, null, srsLocal.OwnerId);
        reduivy__Individual_Requirement_Set__c irsGeneral = IRS_Helper.createIrs(srsGeneral, null, srsLocal.OwnerId);
        List<reduivy__Individual_Requirement_Set__c> irsList = new List<reduivy__Individual_Requirement_Set__c>{ irsLocal, irsGeneral };

		System.runAs(FACULTY_USER){
            insert irsList;
		}
        
        List<reduivy__Individual_Requirement__c> actualIrqList = new List<reduivy__Individual_Requirement__c>();
        Integer actualIrqCount = 0;

        for(reduivy__Individual_Requirement__c actualIrq : [
            SELECT Name, Id, reduivy__Status__c, reduivy__Acceptance_Notes__c, reduivy__Create_Salesforce_Task__c, reduivy__File_Category__c, reduivy__File_Count__c, reduivy__File_Format__c, reduivy__File_Share_Type__c, reduivy__File_Visibility__c, reduivy__Priority__c, reduivy__Code__c, reduivy__Requirement_Details__c, reduivy__Requirement_Type__c, reduivy__Requirement_Visibility__c, reduivy__Sequence__c, reduivy__Task_Owner_Id__c, reduivy__Due_Date__c, reduivy__Individual_Requirement_Set__c,
            reduivy__Study_Requirement__r.Name, reduivy__Study_Requirement__r.Id, reduivy__Study_Requirement__r.reduivy__Status__c, reduivy__Study_Requirement__r.reduivy__Acceptance_Notes__c, reduivy__Study_Requirement__r.reduivy__Create_Salesforce_Task__c, reduivy__Study_Requirement__r.reduivy__File_Category__c, reduivy__Study_Requirement__r.reduivy__File_Count__c, reduivy__Study_Requirement__r.reduivy__File_Format__c, reduivy__Study_Requirement__r.reduivy__File_Share_Type__c, reduivy__Study_Requirement__r.reduivy__File_Visibility__c, reduivy__Study_Requirement__r.reduivy__Priority__c, reduivy__Study_Requirement__r.reduivy__Code__c, reduivy__Study_Requirement__r.reduivy__Requirement_Details__c, reduivy__Study_Requirement__r.reduivy__Requirement_Type__c, reduivy__Study_Requirement__r.reduivy__Requirement_Visibility__c, reduivy__Study_Requirement__r.reduivy__Sequence__c, reduivy__Study_Requirement__r.reduivy__Task_Owner_Id__c, reduivy__Study_Requirement__r.reduivy__Due_Days__c, reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__c
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Individual_Requirement_Set__c IN :irsList
        ]){
            actualIrqCount++;
            System.Assert.isTrue(
                String.isNotBlank(actualIrq.reduivy__Study_Requirement__c), 
                'reduivy__Study_Requirement__c should be set!'
            );   
            for(String field : IRQ_SRQ_COMMON_FIELDS) {
                System.Assert.areEqual(actualIrq.reduivy__Study_Requirement__r.get(field), actualIrq.get(field), 'Wrong ' + field + '!');
            }
            System.Assert.areEqual(
                System.today().addDays(actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue()), 
                actualIrq.reduivy__Due_Date__c, 
                'Wrong reduivy__Due_Date__c! System.today() = ' + System.today() + ', actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue() = ' + actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue() + '! '
            );
            if(actualIrq.reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__c == srsLocal.Id) {
                System.Assert.areEqual(
                    irsLocal.Id, 
                    actualIrq.reduivy__Individual_Requirement_Set__c, 
                    'Wrong reduivy__Individual_Requirement_Set__c!'
                );
            } else if (actualIrq.reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__c == srsGeneral.Id) {
                System.Assert.areEqual(
                    irsGeneral.Id, 
                    actualIrq.reduivy__Individual_Requirement_Set__c, 
                    'Wrong reduivy__Individual_Requirement_Set__c!'
                );
            }
        }

        System.Assert.areEqual(4, actualIrqCount, 'Irs size should be the same!');

        Test.stopTest();
    }

    
	
	/**
     * @description Test as student for create irs with active = false
     */
    @IsTest
    static void testForCreate_ActiveFalse_AsStudent() {

        User STUDENTUSER = testFactory.getStudentUser();
        
        Test.startTest();

        setSrsList();
        reduivy__Individual_Requirement_Set__c irs = IRS_Helper.createIrs(srsLocal, null, srsLocal.OwnerId);
        irs.reduivy__Status__c = IRS_Helper.STATUS_DRAFT;


		System.runAs(STUDENTUSER){
            insert irs;
		}
        
        List<reduivy__Individual_Requirement__c> actualIrqList = [
            SELECT Id, Name, reduivy__Status__c, reduivy__Acceptance_Notes__c, reduivy__Due_Date__c, reduivy__Individual_Requirement_Set__c, reduivy__Code__c, reduivy__Requirement_Details__c, reduivy__Study_Requirement__c, reduivy__Requirement_Visibility__c, reduivy__Sequence__c
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Individual_Requirement_Set__c = :irs.Id
        ];

        System.Assert.isTrue(actualIrqList.isEmpty(), 'Irs should be empty!');

        Test.stopTest();
		
		
    }
	
    /**
     * @description Test as student for create irs with active = true
     */
    @IsTest
    static void testForCreate_ActiveTrue_AsStudent() {

        User STUDENTUSER = testFactory.getStudentUser();
        
        Test.startTest();

        setSrsList();
        reduivy__Individual_Requirement_Set__c irs = IRS_Helper.createIrs(srsLocal, null, STUDENTUSER.Id);

		System.runAs(STUDENTUSER){
            insert irs;
		}
        
        Integer actualIrqCount = 0;

        for(reduivy__Individual_Requirement__c actualIrq : [
            SELECT Name, Id, reduivy__Status__c, reduivy__Acceptance_Notes__c, reduivy__Create_Salesforce_Task__c, reduivy__File_Category__c, reduivy__File_Count__c, reduivy__File_Format__c, reduivy__File_Share_Type__c, reduivy__File_Visibility__c, reduivy__Priority__c, reduivy__Code__c, reduivy__Requirement_Details__c, reduivy__Requirement_Type__c, reduivy__Requirement_Visibility__c, reduivy__Sequence__c, reduivy__Task_Owner_Id__c, reduivy__Due_Date__c, reduivy__Individual_Requirement_Set__c,
            reduivy__Study_Requirement__r.Name, reduivy__Study_Requirement__r.Id, reduivy__Study_Requirement__r.reduivy__Status__c, reduivy__Study_Requirement__r.reduivy__Acceptance_Notes__c, reduivy__Study_Requirement__r.reduivy__Create_Salesforce_Task__c, reduivy__Study_Requirement__r.reduivy__File_Category__c, reduivy__Study_Requirement__r.reduivy__File_Count__c, reduivy__Study_Requirement__r.reduivy__File_Format__c, reduivy__Study_Requirement__r.reduivy__File_Share_Type__c, reduivy__Study_Requirement__r.reduivy__File_Visibility__c, reduivy__Study_Requirement__r.reduivy__Priority__c, reduivy__Study_Requirement__r.reduivy__Code__c, reduivy__Study_Requirement__r.reduivy__Requirement_Details__c, reduivy__Study_Requirement__r.reduivy__Requirement_Type__c, reduivy__Study_Requirement__r.reduivy__Requirement_Visibility__c, reduivy__Study_Requirement__r.reduivy__Sequence__c, reduivy__Study_Requirement__r.reduivy__Task_Owner_Id__c, reduivy__Study_Requirement__r.reduivy__Due_Days__c, reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__c
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Individual_Requirement_Set__c = :irs.Id
        ]){
            actualIrqCount++;
            System.Assert.isTrue(
                String.isNotBlank(actualIrq.reduivy__Study_Requirement__c), 
                'reduivy__Study_Requirement__c should be set!'
            );   
            for(String field : IRQ_SRQ_COMMON_FIELDS) {
                System.Assert.areEqual(actualIrq.reduivy__Study_Requirement__r.get(field), actualIrq.get(field), 'Wrong ' + field + '!');
            }
            System.Assert.areEqual(
                System.today().addDays(actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue()), 
                actualIrq.reduivy__Due_Date__c, 
                'Wrong reduivy__Due_Date__c! System.today() = ' + System.today() + ', actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue() = ' + actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue() + '! '
            );
            System.Assert.areEqual(
                irs.Id, 
                actualIrq.reduivy__Individual_Requirement_Set__c, 
                'Wrong reduivy__Individual_Requirement_Set__c!'
            );        
        }

        System.Assert.areEqual(2, actualIrqCount, 'Irs size should be the same!');

        Test.stopTest();
    }
	
    /**
     * @description Test as student for create irs with active = true
     */
    @IsTest
    static void testForCreate2Irs_ActiveTrue_AsStudent() {

        User STUDENTUSER = testFactory.getStudentUser();
        
        Test.startTest();

        setSrsList();
        reduivy__Individual_Requirement_Set__c irsLocal = IRS_Helper.createIrs(srsLocal, null, STUDENTUSER.Id);
        reduivy__Individual_Requirement_Set__c irsGeneral = IRS_Helper.createIrs(srsGeneral, null, STUDENTUSER.Id);
        List<reduivy__Individual_Requirement_Set__c> irsList = new List<reduivy__Individual_Requirement_Set__c>{ irsLocal, irsGeneral };

		System.runAs(STUDENTUSER){
            insert irsList;
		}
        
        List<reduivy__Individual_Requirement__c> actualIrqList = new List<reduivy__Individual_Requirement__c>();
        Integer actualIrqCount = 0;

        for(reduivy__Individual_Requirement__c actualIrq : [
            SELECT Name, Id, reduivy__Status__c, reduivy__Acceptance_Notes__c, reduivy__Create_Salesforce_Task__c, reduivy__File_Category__c, reduivy__File_Count__c, reduivy__File_Format__c, reduivy__File_Share_Type__c, reduivy__File_Visibility__c, reduivy__Priority__c, reduivy__Code__c, reduivy__Requirement_Details__c, reduivy__Requirement_Type__c, reduivy__Requirement_Visibility__c, reduivy__Sequence__c, reduivy__Task_Owner_Id__c, reduivy__Due_Date__c, reduivy__Individual_Requirement_Set__c,
            reduivy__Study_Requirement__r.Name, reduivy__Study_Requirement__r.Id, reduivy__Study_Requirement__r.reduivy__Status__c, reduivy__Study_Requirement__r.reduivy__Acceptance_Notes__c, reduivy__Study_Requirement__r.reduivy__Create_Salesforce_Task__c, reduivy__Study_Requirement__r.reduivy__File_Category__c, reduivy__Study_Requirement__r.reduivy__File_Count__c, reduivy__Study_Requirement__r.reduivy__File_Format__c, reduivy__Study_Requirement__r.reduivy__File_Share_Type__c, reduivy__Study_Requirement__r.reduivy__File_Visibility__c, reduivy__Study_Requirement__r.reduivy__Priority__c, reduivy__Study_Requirement__r.reduivy__Code__c, reduivy__Study_Requirement__r.reduivy__Requirement_Details__c, reduivy__Study_Requirement__r.reduivy__Requirement_Type__c, reduivy__Study_Requirement__r.reduivy__Requirement_Visibility__c, reduivy__Study_Requirement__r.reduivy__Sequence__c, reduivy__Study_Requirement__r.reduivy__Task_Owner_Id__c, reduivy__Study_Requirement__r.reduivy__Due_Days__c, reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__c
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Individual_Requirement_Set__c IN :irsList
        ]){
            actualIrqCount++;
            System.Assert.isTrue(
                String.isNotBlank(actualIrq.reduivy__Study_Requirement__c), 
                'reduivy__Study_Requirement__c should be set!'
            );   
            for(String field : IRQ_SRQ_COMMON_FIELDS) {
                System.Assert.areEqual(actualIrq.reduivy__Study_Requirement__r.get(field), actualIrq.get(field), 'Wrong ' + field + '!');
            }
            System.Assert.areEqual(
                System.today().addDays(actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue()), 
                actualIrq.reduivy__Due_Date__c, 
                'Wrong reduivy__Due_Date__c! System.today() = ' + System.today() + ', actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue() = ' + actualIrq.reduivy__Study_Requirement__r.reduivy__Due_Days__c.intValue() + '! '
            );
            if(actualIrq.reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__c == srsLocal.Id) {
                System.Assert.areEqual(
                    irsLocal.Id, 
                    actualIrq.reduivy__Individual_Requirement_Set__c, 
                    'Wrong reduivy__Individual_Requirement_Set__c!'
                );
            } else if (actualIrq.reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__c == srsGeneral.Id) {
                System.Assert.areEqual(
                    irsGeneral.Id, 
                    actualIrq.reduivy__Individual_Requirement_Set__c, 
                    'Wrong reduivy__Individual_Requirement_Set__c!'
                );
            }
        }

        System.Assert.areEqual(4, actualIrqCount, 'Irs size should be the same!');

        Test.stopTest();
    }
    
    static void setSrsList(){
        for(reduivy__Study_Requirement_Set__c srs : [
            SELECT Id, Name, reduivy__Sample_Record_Code__c, reduivy__Status__c, reduivy__Code__c, reduivy__Description__c, reduivy__Contact_Field__c, OwnerId, reduivy__Requirement_Generation_Mode__c, reduivy__Translation_Map__c,
            (
                SELECT Id, Name, reduivy__Status__c, reduivy__Acceptance_Notes__c, reduivy__Create_Salesforce_Task__c, reduivy__File_Category__c, reduivy__File_Count__c, reduivy__File_Format__c, reduivy__File_Share_Type__c, reduivy__File_Visibility__c, reduivy__Priority__c, reduivy__Code__c, reduivy__Requirement_Details__c, reduivy__Requirement_Type__c, reduivy__Requirement_Visibility__c, reduivy__Sequence__c, reduivy__Task_Owner_Id__c
                FROM reduivy__Study_Requirements__r
            )
            FROM reduivy__Study_Requirement_Set__c
            WHERE reduivy__Sample_Record_Code__c IN (:SRS_GENERAL, :SRS_LOCAL)
        ]) {
            if(srs.reduivy__Sample_Record_Code__c == SRS_GENERAL) {
                srsGeneral = srs;
            } else if(srs.reduivy__Sample_Record_Code__c == SRS_LOCAL) {
                srsLocal = srs;
            } 
        }
    }

}