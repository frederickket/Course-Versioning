/**
 * @author      WDCi (XW)
 * @date        Aug 2025
 * @group       Test
 * @description Test class for SOBJ_IndividualScoreEvaluation_EXE
 * @changehistory
 * ISS-002506 15-08-2025 XW - new class
 */
@IsTest
public inherited sharing class SOBJ_IndividualScoreEvaluation_TEST {

    static final String STUDENT_CON = 'sandydoe@redu.example';
    static final String SCF_SRF = 'SCF_Application';
    static final String ISC_SRC = STUDENT_CON + '_' + SCF_SRF;
    

    static final String SCR_NUMBER_SRC = 'SCR_CGPA';
    static final String SCR_CHECKBOX_SRC = 'SCR_Teaching period';
    static final String SCR_PICKLIST_SRC = 'SCR_English Proficiency';

    static final String SCR_NUMBER_NAME = 'CGPA';
    static final String SCR_CHECKBOX_NAME = 'Teaching period';
    static final String SCR_PICKLIST_NAME = 'English Proficiency';

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
        	
            testFactory.initMasterData(SCR_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initStudentData(ISD_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }

    /**
     * @description Test as admin for inserted with checkbox field
     */
    @IsTest
    static void testForInsert_Checkbox_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        Contact student = queryStudent();

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        ipa.put('reduivy__Test_Teaching_Period__c', true);
        
		System.runAs(ADMIN_USER){
            insert ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd = [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c = :ipa.Id
            AND Name = :SCR_CHECKBOX_NAME
            LIMIT 1
        ];

        System.Assert.areEqual(100, isd.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(3, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        
        Test.stopTest();
    }
	

    /**
     * @description Test as admin for inserted with number field
     */
    @IsTest
    static void testForInsert_Number_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        Contact student = queryStudent();

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        ipa.put('reduivy__Test_Previous_CGPA__c', 5);
        
		System.runAs(ADMIN_USER){
            insert ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd = [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c = :ipa.Id
            AND Name = :SCR_NUMBER_NAME
            LIMIT 1
        ];

        System.Assert.areEqual(50, isd.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(30, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        
        Test.stopTest();
    }

    /**
     * @description Test as admin for inserted with picklist field
     */
    @IsTest
    static void testForInsert_Picklist_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        Contact student = queryStudent();

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        ipa.put('reduivy__Test_English_Proficiency__c', 'B1');
        
		System.runAs(ADMIN_USER){
            insert ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd = [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c = :ipa.Id
            AND Name = :SCR_PICKLIST_NAME
            LIMIT 1
        ];

        System.Assert.areEqual(40, isd.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(4, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        
        Test.stopTest();
    }
	
    /**
     * @description Test as admin for inserted with number field, parent record referred
     */
    @IsTest
    static void testForInsert_Number_ParentRecord_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        reduivy__Study_Scoring_Criteria__c scr = [SELECT Id, reduivy__Score_Logic__c FROM reduivy__Study_Scoring_Criteria__c WHERE reduivy__Sample_Record_Code__c = :SCR_NUMBER_SRC LIMIT 1];
        scr.reduivy__Score_Logic__c = 'IF(NOT(ISBLANK(reduivy__Contact__r.LastName)) , reduivy__Test_Previous_CGPA__c * 10, reduivy__Test_Previous_CGPA__c * 10)';

        update scr;
        
        Contact student = queryStudent();

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        ipa.put('reduivy__Test_Previous_CGPA__c', 4);
        
		System.runAs(ADMIN_USER){
            insert ipa;
		}
        
        List<reduivy__Individual_Score_Detail__c> isd = [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c = :ipa.Id
            AND Name = :SCR_NUMBER_NAME
            LIMIT 1
        ];

        System.Assert.areEqual(40, isd[0].reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(24, isd[0].reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        
        Test.stopTest();
    }
	
    /**
     * @description Test as admin for inserted with picklist field, bulk
     */
    @IsTest
    static void testForBulkInsert_Picklist_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        Contact student = queryStudent();
        
        Integer ipaSize = 100; 
        List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();
        
        for(Integer i = 1; i <= ipaSize; i++) {
            reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
                reduivy__Contact__c = student.Id,
                reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
            );
            ipa.put('reduivy__Test_English_Proficiency__c', 'B1');
            ipaList.add(ipa);
        }

        REDU_TriggerController.muteTriggers(new Set<String> {'IPA_PreventDuplicate_EXE'});
        
		System.runAs(ADMIN_USER){
            insert ipaList;
		}

        REDU_TriggerController.unmuteTriggers(new Set<String> {'IPA_PreventDuplicate_EXE'});
        
        Integer isdSize = 0;
        
        for(reduivy__Individual_Score_Detail__c isd : [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c IN :ipaList
            AND Name = :SCR_PICKLIST_NAME
        ]) {
            System.Assert.areEqual(40, isd.reduivy__Score__c, 'Wrong score detail score!');
            System.Assert.areEqual(4, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');
            isdSize++;
        }
        
        System.Assert.areEqual(ipaSize, isdSize, 'Wrong isd size!');

        Test.stopTest();
    }
	
    /**
     * @description Test as admin for updating checkbox field
     */
    @IsTest
    static void testForUpdate_Checkbox_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        ipa.put('reduivy__Test_Teaching_Period__c', true);
        
		System.runAs(ADMIN_USER){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd1 = queryIsd(ISC_SRC + '_' + SCR_CHECKBOX_SRC);
        System.Assert.areEqual(100, isd1.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(3, isd1.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');


        ipa.put('reduivy__Test_Teaching_Period__c', false);
        
		System.runAs(ADMIN_USER){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd2 = queryIsd(ISC_SRC + '_' + SCR_CHECKBOX_SRC);
        System.Assert.areEqual(0, isd2.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(0, isd2.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        
        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating number field
     */
    @IsTest
    static void testForUpdate_Number_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        ipa.put('reduivy__Test_Previous_CGPA__c', 5);
        
		System.runAs(ADMIN_USER){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd1 = queryIsd(ISC_SRC + '_' + SCR_NUMBER_SRC);
        System.Assert.areEqual(50, isd1.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(30, isd1.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        ipa.put('reduivy__Test_Previous_CGPA__c', 7);
        
		System.runAs(ADMIN_USER){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd2 = queryIsd(ISC_SRC + '_' + SCR_NUMBER_SRC);
        System.Assert.areEqual(70, isd2.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(42, isd2.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');
        
        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating picklist field
     */
    @IsTest
    static void testForUpdate_Picklist_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        ipa.put('reduivy__Test_English_Proficiency__c', 'B1');
        
		System.runAs(ADMIN_USER){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd1 = queryIsd(ISC_SRC + '_' + SCR_PICKLIST_SRC);
        System.Assert.areEqual(40, isd1.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(4, isd1.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        ipa.put('reduivy__Test_English_Proficiency__c', 'B2');
        
		System.runAs(ADMIN_USER){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd2 = queryIsd(ISC_SRC + '_' + SCR_PICKLIST_SRC);
        System.Assert.areEqual(80, isd2.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(8, isd2.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');
        
        Test.stopTest();
		
    }

    
    /**
     * @description Test as admin for update picklist field, bulk
     */
    @IsTest
    static void testForBulkUpdate_Picklist_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        Contact student = queryStudent();
        
        Integer ipaSize = 100; 
        List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();
        
        for(Integer i = 1; i <= ipaSize; i++) {
            reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
                reduivy__Contact__c = student.Id,
                reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
            );
            ipa.put('reduivy__Test_English_Proficiency__c', 'B1');
            ipaList.add(ipa);
        }

        REDU_TriggerController.muteTriggers(new Set<String> {'IPA_PreventDuplicate_EXE'});
        
		
        insert ipaList;
		

        REDU_TriggerController.unmuteTriggers(new Set<String> {'IPA_PreventDuplicate_EXE'});
        
        Integer isdSize = 0;
        
        for(reduivy__Individual_Score_Detail__c isd : [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c IN :ipaList
            AND Name = :SCR_PICKLIST_NAME
        ]) {
            System.Assert.areEqual(40, isd.reduivy__Score__c, 'Wrong score detail score!');
            System.Assert.areEqual(4, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');
            isdSize++;
        }
        
        System.Assert.areEqual(ipaSize, isdSize, 'Wrong isd size!');

        //begin update
        for(reduivy__Individual_Program_Application__c ipa : ipaList){
            ipa.put('reduivy__Test_English_Proficiency__c', 'C2');
        }
        
        System.runAs(ADMIN_USER){
            update ipaList;    
        }

        isdSize = 0;

        for(reduivy__Individual_Score_Detail__c isd : [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c IN :ipaList
            AND Name = :SCR_PICKLIST_NAME
        ]) {
            System.Assert.areEqual(100, isd.reduivy__Score__c, 'Wrong score detail score!');
            System.Assert.areEqual(10, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');
            isdSize++;
        }
        
        System.Assert.areEqual(ipaSize, isdSize, 'Wrong isd size!');


        Test.stopTest();
    }
	

    /**
     * @description Test as faculty for inserted with checkbox field
     */
    @IsTest
    static void testForInsert_Checkbox_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        Contact student = queryStudent();

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        ipa.put('reduivy__Test_Teaching_Period__c', true);
        
		System.runAs(FACULTY_USER){
            insert ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd = [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c = :ipa.Id
            AND Name = :SCR_CHECKBOX_NAME
            LIMIT 1
        ];

        System.Assert.areEqual(100, isd.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(3, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        
        Test.stopTest();
    }
	

    /**
     * @description Test as faculty for inserted with number field
     */
    @IsTest
    static void testForInsert_Number_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        Contact student = queryStudent();

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        ipa.put('reduivy__Test_Previous_CGPA__c', 5);
        
		System.runAs(FACULTY_USER){
            insert ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd = [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c = :ipa.Id
            AND Name = :SCR_NUMBER_NAME
            LIMIT 1
        ];

        System.Assert.areEqual(50, isd.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(30, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        
        Test.stopTest();
    }

    /**
     * @description Test as faculty for inserted with picklist field
     */
    @IsTest
    static void testForInsert_Picklist_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        Contact student = queryStudent();

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        ipa.put('reduivy__Test_English_Proficiency__c', 'B1');
        
		System.runAs(FACULTY_USER){
            insert ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd = [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c = :ipa.Id
            AND Name = :SCR_PICKLIST_NAME
            LIMIT 1
        ];

        System.Assert.areEqual(40, isd.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(4, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        
        Test.stopTest();
    }
	
    /**
     * @description Test as faculty for inserted with number field, parent record referred
     */
    @IsTest
    static void testForInsert_Number_ParentRecord_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        reduivy__Study_Scoring_Criteria__c scr = [SELECT Id, reduivy__Score_Logic__c FROM reduivy__Study_Scoring_Criteria__c WHERE reduivy__Sample_Record_Code__c = :SCR_NUMBER_SRC LIMIT 1];
        scr.reduivy__Score_Logic__c = 'IF(NOT(ISBLANK(reduivy__Contact__r.LastName)) , reduivy__Test_Previous_CGPA__c * 10, reduivy__Test_Previous_CGPA__c * 10)';

        update scr;
        
        Contact student = queryStudent();

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        ipa.put('reduivy__Test_Previous_CGPA__c', 4);
        
		System.runAs(FACULTY_USER){
            insert ipa;
		}
        
        List<reduivy__Individual_Score_Detail__c> isd = [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c = :ipa.Id
            AND Name = :SCR_NUMBER_NAME
            LIMIT 1
        ];

        System.Assert.areEqual(40, isd[0].reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(24, isd[0].reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        
        Test.stopTest();
    }
	
    /**
     * @description Test as faculty for inserted with picklist field, bulk
     */
    @IsTest
    static void testForBulkInsert_Picklist_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        Contact student = queryStudent();
        
        Integer ipaSize = 100; 
        List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();
        
        for(Integer i = 1; i <= ipaSize; i++) {
            reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
                reduivy__Contact__c = student.Id,
                reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
            );
            ipa.put('reduivy__Test_English_Proficiency__c', 'B1');
            ipaList.add(ipa);
        }

        REDU_TriggerController.muteTriggers(new Set<String> {'IPA_PreventDuplicate_EXE'});
        
		System.runAs(FACULTY_USER){
            insert ipaList;
		}

        REDU_TriggerController.unmuteTriggers(new Set<String> {'IPA_PreventDuplicate_EXE'});
        
        Integer isdSize = 0;
        
        for(reduivy__Individual_Score_Detail__c isd : [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c IN :ipaList
            AND Name = :SCR_PICKLIST_NAME
        ]) {
            System.Assert.areEqual(40, isd.reduivy__Score__c, 'Wrong score detail score!');
            System.Assert.areEqual(4, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');
            isdSize++;
        }
        
        System.Assert.areEqual(ipaSize, isdSize, 'Wrong isd size!');

        Test.stopTest();
    }
	
    /**
     * @description Test as faculty for updating checkbox field
     */
    @IsTest
    static void testForUpdate_Checkbox_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        ipa.put('reduivy__Test_Teaching_Period__c', true);
        
		System.runAs(FACULTY_USER){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd1 = queryIsd(ISC_SRC + '_' + SCR_CHECKBOX_SRC);
        System.Assert.areEqual(100, isd1.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(3, isd1.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');


        ipa.put('reduivy__Test_Teaching_Period__c', false);
        
		System.runAs(FACULTY_USER){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd2 = queryIsd(ISC_SRC + '_' + SCR_CHECKBOX_SRC);
        System.Assert.areEqual(0, isd2.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(0, isd2.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        
        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for updating number field
     */
    @IsTest
    static void testForUpdate_Number_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        ipa.put('reduivy__Test_Previous_CGPA__c', 5);
        
		System.runAs(FACULTY_USER){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd1 = queryIsd(ISC_SRC + '_' + SCR_NUMBER_SRC);
        System.Assert.areEqual(50, isd1.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(30, isd1.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        ipa.put('reduivy__Test_Previous_CGPA__c', 7);
        
		System.runAs(FACULTY_USER){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd2 = queryIsd(ISC_SRC + '_' + SCR_NUMBER_SRC);
        System.Assert.areEqual(70, isd2.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(42, isd2.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');
        
        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for updating picklist field
     */
    @IsTest
    static void testForUpdate_Picklist_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        ipa.put('reduivy__Test_English_Proficiency__c', 'B1');
        
		System.runAs(FACULTY_USER){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd1 = queryIsd(ISC_SRC + '_' + SCR_PICKLIST_SRC);
        System.Assert.areEqual(40, isd1.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(4, isd1.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        ipa.put('reduivy__Test_English_Proficiency__c', 'B2');
        
		System.runAs(FACULTY_USER){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd2 = queryIsd(ISC_SRC + '_' + SCR_PICKLIST_SRC);
        System.Assert.areEqual(80, isd2.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(8, isd2.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');
        
        Test.stopTest();
		
    }

    
    /**
     * @description Test as faculty for update picklist field, bulk
     */
    @IsTest
    static void testForBulkUpdate_Picklist_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        Contact student = queryStudent();
        
        Integer ipaSize = 100; 
        List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();
        
        for(Integer i = 1; i <= ipaSize; i++) {
            reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
                reduivy__Contact__c = student.Id,
                reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
            );
            ipa.put('reduivy__Test_English_Proficiency__c', 'B1');
            ipaList.add(ipa);
        }

        REDU_TriggerController.muteTriggers(new Set<String> {'IPA_PreventDuplicate_EXE'});
        
		
        insert ipaList;
		

        REDU_TriggerController.unmuteTriggers(new Set<String> {'IPA_PreventDuplicate_EXE'});
        
        Integer isdSize = 0;
        
        for(reduivy__Individual_Score_Detail__c isd : [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c IN :ipaList
            AND Name = :SCR_PICKLIST_NAME
        ]) {
            System.Assert.areEqual(40, isd.reduivy__Score__c, 'Wrong score detail score!');
            System.Assert.areEqual(4, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');
            isdSize++;
        }
        
        System.Assert.areEqual(ipaSize, isdSize, 'Wrong isd size!');

        //begin update
        for(reduivy__Individual_Program_Application__c ipa : ipaList){
            ipa.put('reduivy__Test_English_Proficiency__c', 'C2');
        }
        
        System.runAs(FACULTY_USER){
            update ipaList;    
        }

        isdSize = 0;

        for(reduivy__Individual_Score_Detail__c isd : [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c IN :ipaList
            AND Name = :SCR_PICKLIST_NAME
        ]) {
            System.Assert.areEqual(100, isd.reduivy__Score__c, 'Wrong score detail score!');
            System.Assert.areEqual(10, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');
            isdSize++;
        }
        
        System.Assert.areEqual(ipaSize, isdSize, 'Wrong isd size!');


        Test.stopTest();
    }
	

    /**
     * @description Test as student for inserted with checkbox field
     */
    @IsTest
    static void testForInsert_Checkbox_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        Contact student = queryStudent();

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        ipa.put('reduivy__Test_Teaching_Period__c', true);
        
		System.runAs(studentUser){
            insert ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd = [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c = :ipa.Id
            AND Name = :SCR_CHECKBOX_NAME
            LIMIT 1
        ];

        System.Assert.areEqual(100, isd.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(3, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        
        Test.stopTest();
    }
	

    /**
     * @description Test as student for inserted with number field
     */
    @IsTest
    static void testForInsert_Number_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        Contact student = queryStudent();

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        ipa.put('reduivy__Test_Previous_CGPA__c', 5);
        
		System.runAs(studentUser){
            insert ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd = [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c = :ipa.Id
            AND Name = :SCR_NUMBER_NAME
            LIMIT 1
        ];

        System.Assert.areEqual(50, isd.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(30, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        
        Test.stopTest();
    }

    /**
     * @description Test as student for inserted with picklist field
     */
    @IsTest
    static void testForInsert_Picklist_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        Contact student = queryStudent();

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        ipa.put('reduivy__Test_English_Proficiency__c', 'B1');
        
		System.runAs(studentUser){
            insert ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd = [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c = :ipa.Id
            AND Name = :SCR_PICKLIST_NAME
            LIMIT 1
        ];

        System.Assert.areEqual(40, isd.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(4, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        
        Test.stopTest();
    }
	
    /**
     * @description Test as student for inserted with number field, parent record referred
     */
    @IsTest
    static void testForInsert_Number_ParentRecord_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        reduivy__Study_Scoring_Criteria__c scr = [SELECT Id, reduivy__Score_Logic__c FROM reduivy__Study_Scoring_Criteria__c WHERE reduivy__Sample_Record_Code__c = :SCR_NUMBER_SRC LIMIT 1];
        scr.reduivy__Score_Logic__c = 'IF(NOT(ISBLANK(reduivy__Contact__r.LastName)) , reduivy__Test_Previous_CGPA__c * 10, reduivy__Test_Previous_CGPA__c * 10)';

        update scr;
        
        Contact student = queryStudent();

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        ipa.put('reduivy__Test_Previous_CGPA__c', 4);
        
		System.runAs(studentUser){
            insert ipa;
		}
        
        List<reduivy__Individual_Score_Detail__c> isd = [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c = :ipa.Id
            AND Name = :SCR_NUMBER_NAME
            LIMIT 1
        ];

        System.Assert.areEqual(40, isd[0].reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(24, isd[0].reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        
        Test.stopTest();
    }
	
    /**
     * @description Test as student for inserted with picklist field, bulk
     */
    @IsTest
    static void testForBulkInsert_Picklist_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        Contact student = queryStudent();
        
        Integer ipaSize = 100; 
        List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();
        
        for(Integer i = 1; i <= ipaSize; i++) {
            reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
                reduivy__Contact__c = student.Id,
                reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
            );
            ipa.put('reduivy__Test_English_Proficiency__c', 'B1');
            ipaList.add(ipa);
        }

        REDU_TriggerController.muteTriggers(new Set<String> {'IPA_PreventDuplicate_EXE'});
        
		System.runAs(studentUser){
            insert ipaList;
		}

        REDU_TriggerController.unmuteTriggers(new Set<String> {'IPA_PreventDuplicate_EXE'});
        
        Integer isdSize = 0;
        
        for(reduivy__Individual_Score_Detail__c isd : [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c IN :ipaList
            AND Name = :SCR_PICKLIST_NAME
        ]) {
            System.Assert.areEqual(40, isd.reduivy__Score__c, 'Wrong score detail score!');
            System.Assert.areEqual(4, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');
            isdSize++;
        }
        
        System.Assert.areEqual(ipaSize, isdSize, 'Wrong isd size!');

        Test.stopTest();
    }
	
    /**
     * @description Test as student for updating checkbox field
     */
    @IsTest
    static void testForUpdate_Checkbox_AsStudent() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        ipa.put('reduivy__Test_Teaching_Period__c', true);
        
		System.runAs(studentUser){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd1 = queryIsd(ISC_SRC + '_' + SCR_CHECKBOX_SRC);
        System.Assert.areEqual(100, isd1.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(3, isd1.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');


        ipa.put('reduivy__Test_Teaching_Period__c', false);
        
		System.runAs(studentUser){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd2 = queryIsd(ISC_SRC + '_' + SCR_CHECKBOX_SRC);
        System.Assert.areEqual(0, isd2.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(0, isd2.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        
        Test.stopTest();
		
    }

    /**
     * @description Test as student for updating number field
     */
    @IsTest
    static void testForUpdate_Number_AsStudent() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        ipa.put('reduivy__Test_Previous_CGPA__c', 5);
        
		System.runAs(studentUser){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd1 = queryIsd(ISC_SRC + '_' + SCR_NUMBER_SRC);
        System.Assert.areEqual(50, isd1.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(30, isd1.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        ipa.put('reduivy__Test_Previous_CGPA__c', 7);
        
		System.runAs(studentUser){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd2 = queryIsd(ISC_SRC + '_' + SCR_NUMBER_SRC);
        System.Assert.areEqual(70, isd2.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(42, isd2.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');
        
        Test.stopTest();
		
    }

    /**
     * @description Test as student for updating picklist field
     */
    @IsTest
    static void testForUpdate_Picklist_AsStudent() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        ipa.put('reduivy__Test_English_Proficiency__c', 'B1');
        
		System.runAs(studentUser){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd1 = queryIsd(ISC_SRC + '_' + SCR_PICKLIST_SRC);
        System.Assert.areEqual(40, isd1.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(4, isd1.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');

        ipa.put('reduivy__Test_English_Proficiency__c', 'B2');
        
		System.runAs(studentUser){
            update ipa;
		}
        
        reduivy__Individual_Score_Detail__c isd2 = queryIsd(ISC_SRC + '_' + SCR_PICKLIST_SRC);
        System.Assert.areEqual(80, isd2.reduivy__Score__c, 'Wrong score detail score!');
        System.Assert.areEqual(8, isd2.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');
        
        Test.stopTest();
		
    }

    
    /**
     * @description Test as student for update picklist field, bulk
     */
    @IsTest
    static void testForBulkUpdate_Picklist_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        Contact student = queryStudent();
        
        Integer ipaSize = 100; 
        List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();
        
        for(Integer i = 1; i <= ipaSize; i++) {
            reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
                reduivy__Contact__c = student.Id,
                reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
            );
            ipa.put('reduivy__Test_English_Proficiency__c', 'B1');
            ipaList.add(ipa);
        }

        REDU_TriggerController.muteTriggers(new Set<String> {'IPA_PreventDuplicate_EXE'});
        
		
        insert ipaList;
		

        REDU_TriggerController.unmuteTriggers(new Set<String> {'IPA_PreventDuplicate_EXE'});
        
        Integer isdSize = 0;
        
        for(reduivy__Individual_Score_Detail__c isd : [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c IN :ipaList
            AND Name = :SCR_PICKLIST_NAME
        ]) {
            System.Assert.areEqual(40, isd.reduivy__Score__c, 'Wrong score detail score!');
            System.Assert.areEqual(4, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');
            isdSize++;
        }
        
        System.Assert.areEqual(ipaSize, isdSize, 'Wrong isd size!');

        //begin update
        for(reduivy__Individual_Program_Application__c ipa : ipaList){
            ipa.put('reduivy__Test_English_Proficiency__c', 'C2');
        }
        
        System.runAs(studentUser){
            update ipaList;    
        }

        isdSize = 0;

        for(reduivy__Individual_Score_Detail__c isd : [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__c IN :ipaList
            AND Name = :SCR_PICKLIST_NAME
        ]) {
            System.Assert.areEqual(100, isd.reduivy__Score__c, 'Wrong score detail score!');
            System.Assert.areEqual(10, isd.reduivy__Weighted_Score__c, 'Wrong score detail weighted score!');
            isdSize++;
        }
        
        System.Assert.areEqual(ipaSize, isdSize, 'Wrong isd size!');


        Test.stopTest();
    }
	

	
    static Contact queryStudent(){
        return [
            SELECT Id FROM Contact
            WHERE reduivy__Sample_Record_Code__c = :STUDENT_CON
            LIMIT 1
        ];
    }
	
    static reduivy__Individual_Program_Application__c queryIpa(){
        return [
            SELECT Id FROM reduivy__Individual_Program_Application__c
            WHERE reduivy__Sample_Record_Code__c = :STUDENT_CON
            LIMIT 1
        ];
    }

    static reduivy__Individual_Score__c queryIsc(Id ipaId) {
        return [
            SELECT Id, (
                SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
                FROM reduivy__Individual_Score_Details__r
            )
            FROM reduivy__Individual_Score__c
            WHERE reduivy__Individual_Program_Application__c = :ipaId
            LIMIT 1
        ];
    }

    static reduivy__Individual_Score_Detail__c queryIsd(String sampleRecordCode) {
        return [
            SELECT Id, Name, reduivy__Weighted_Score__c, reduivy__Score__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Sample_Record_Code__c = :sampleRecordCode
            LIMIT 1
        ];
    }
	
}