/**
 * @author      WDCi (XW)
 * @date        Aug 2025
 * @group       Test
 * @description Test class for ISC_IdvScoreDetailGeneration_EXE
 * @changehistory
 * ISS-002506 25-08-2025 XW - new class
 */
@IsTest
public inherited sharing class ISC_IdvScoreDetailGeneration_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static final String STUDENT_CON = 'sandydoe@redu.example';
    static final String SCF_SRC = 'SCF_Application';
    
    static final String NEW_SCF_SRC = 'SCF_New';
    static final String NEW_SCR1_1_SRC = 'SCR_1-1';
    static final String NEW_SCR1_2_SRC = 'SCR_1-2';
    static final String NEW_SCR2_1_SRC = 'SCR_2-1';
    static final String NEW_SCR2_2_SRC = 'SCR_2-2';
    

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        // Create settings
        testFactory.setupDefaultSettings();

        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();
        	        	
            testFactory.initMasterData(SCR_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initStudentData(IPA_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for creating new individual score
     */
    @IsTest
    static void testForInsert_OneScf_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();
        
        Contact student = queryStudent();
        

        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        reduivy__Study_Scoring_Config__c scf = queryScf(SCF_SRC);
        Map<Id, reduivy__Study_Scoring_Criteria__c> scrMap = new Map<Id, reduivy__Study_Scoring_Criteria__c>(scf.reduivy__Study_Scoring_Criteria__r);

        reduivy__Individual_Score__c isc = new reduivy__Individual_Score__c(
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf.Id
        );
        
		System.runAs(ADMIN_USER){
            insert isc;
		}

        List<reduivy__Individual_Score__c> insertedIscList = queryIsc();
        System.Assert.areEqual(1, insertedIscList.size(), 'Wrong inserted individual score size!');

        for(reduivy__Individual_Score__c insertedIsc : insertedIscList) {
            System.Assert.areEqual(9, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');

            for(reduivy__Individual_Score_Detail__c isd : insertedIsc.reduivy__Individual_Score_Details__r) {
                System.Assert.areEqual(
                    scrMap.get(isd.reduivy__Study_Scoring_Criteria__c).reduivy__Parent_Criteria__c,
                    isd.reduivy__Parent_Score_Detail__r.reduivy__Study_Scoring_Criteria__c,
                    'Wrong Parent!'
                );
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for creating new individual score
     */
    @IsTest
    static void testForInsert_TwoScf_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        Contact student = queryStudent();

        Test.startTest();
        
        createNewScf();

        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        reduivy__Study_Scoring_Config__c scf1 = queryScf(SCF_SRC);
        reduivy__Study_Scoring_Config__c scf2 = queryScf(NEW_SCF_SRC);
        Map<Id, reduivy__Study_Scoring_Criteria__c> scrMap = new Map<Id, reduivy__Study_Scoring_Criteria__c>(scf1.reduivy__Study_Scoring_Criteria__r);
        scrMap.putAll(new Map<Id, reduivy__Study_Scoring_Criteria__c> (scf2.reduivy__Study_Scoring_Criteria__r));

        reduivy__Individual_Score__c isc1 = new reduivy__Individual_Score__c(
            Name = SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf1.Id
        );

        reduivy__Individual_Score__c isc2 = new reduivy__Individual_Score__c(
            Name = NEW_SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf2.Id
        );
        
		System.runAs(ADMIN_USER){
            insert new List<reduivy__Individual_Score__c> { isc1, isc2 };
		}

        List<reduivy__Individual_Score__c> insertedIscList = queryIsc();
        System.Assert.areEqual(2, insertedIscList.size(), 'Wrong inserted individual score size!');

        for(reduivy__Individual_Score__c insertedIsc : insertedIscList) {
            if(insertedIsc.Name == SCF_SRC) {
                System.Assert.areEqual(9, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else if (insertedIsc.Name == NEW_SCF_SRC) {
                System.Assert.areEqual(4, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else {
                System.Assert.fail('Invalid statement!');
            }
            
            for(reduivy__Individual_Score_Detail__c isd : insertedIsc.reduivy__Individual_Score_Details__r) {
                System.Assert.areEqual(
                    scrMap.get(isd.reduivy__Study_Scoring_Criteria__c).reduivy__Parent_Criteria__c,
                    isd.reduivy__Parent_Score_Detail__r.reduivy__Study_Scoring_Criteria__c,
                    'Wrong Parent!'
                );
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for creating new individual score, one of the scf has no child scr
     */
    @IsTest
    static void testForInsert_TwoScf_OneEmpty_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        Contact student = queryStudent();

        Test.startTest();
        
        createNewScf(true);

        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        reduivy__Study_Scoring_Config__c scf1 = queryScf(SCF_SRC);
        reduivy__Study_Scoring_Config__c scf2 = queryScf(NEW_SCF_SRC);
        Map<Id, reduivy__Study_Scoring_Criteria__c> scrMap = new Map<Id, reduivy__Study_Scoring_Criteria__c>(scf1.reduivy__Study_Scoring_Criteria__r);
        scrMap.putAll(new Map<Id, reduivy__Study_Scoring_Criteria__c> (scf2.reduivy__Study_Scoring_Criteria__r));

        reduivy__Individual_Score__c isc1 = new reduivy__Individual_Score__c(
            Name = SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf1.Id
        );

        reduivy__Individual_Score__c isc2 = new reduivy__Individual_Score__c(
            Name = NEW_SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf2.Id
        );
        
		System.runAs(ADMIN_USER){
            insert new List<reduivy__Individual_Score__c> { isc1, isc2 };
		}

        List<reduivy__Individual_Score__c> insertedIscList = queryIsc();
        System.Assert.areEqual(2, insertedIscList.size(), 'Wrong inserted individual score size!');

        for(reduivy__Individual_Score__c insertedIsc : insertedIscList) {
            if(insertedIsc.Name == SCF_SRC) {
                System.Assert.areEqual(9, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else if (insertedIsc.Name == NEW_SCF_SRC) {
                System.Assert.areEqual(0, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else {
                System.Assert.fail('Invalid statement!');
            }
            
            for(reduivy__Individual_Score_Detail__c isd : insertedIsc.reduivy__Individual_Score_Details__r) {
                System.Assert.areEqual(
                    scrMap.get(isd.reduivy__Study_Scoring_Criteria__c).reduivy__Parent_Criteria__c,
                    isd.reduivy__Parent_Score_Detail__r.reduivy__Study_Scoring_Criteria__c,
                    'Wrong Parent!'
                );
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for creating new individual score, one of the scf has all child scr inactive
     */
    @IsTest
    static void testForInsert_TwoScf_OneChildInactive_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        Contact student = queryStudent();

        Test.startTest();
        
        createNewScf();

        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        reduivy__Study_Scoring_Config__c scf1 = queryScf(SCF_SRC);
        reduivy__Study_Scoring_Config__c scf2 = queryScf(NEW_SCF_SRC);

        //update scf2 children to inactive
        for(reduivy__Study_Scoring_Criteria__c scr : scf2.reduivy__Study_Scoring_Criteria__r) {
            scr.reduivy__Status__c = SCR_Helper.STATUS_ARCHIVED;
        }

        update scf2.reduivy__Study_Scoring_Criteria__r;

        Map<Id, reduivy__Study_Scoring_Criteria__c> scrMap = new Map<Id, reduivy__Study_Scoring_Criteria__c>(scf1.reduivy__Study_Scoring_Criteria__r);
        scrMap.putAll(new Map<Id, reduivy__Study_Scoring_Criteria__c> (scf2.reduivy__Study_Scoring_Criteria__r));

        reduivy__Individual_Score__c isc1 = new reduivy__Individual_Score__c(
            Name = SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf1.Id
        );

        reduivy__Individual_Score__c isc2 = new reduivy__Individual_Score__c(
            Name = NEW_SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf2.Id
        );
        
		System.runAs(ADMIN_USER){
            insert new List<reduivy__Individual_Score__c> { isc1, isc2 };
		}

        List<reduivy__Individual_Score__c> insertedIscList = queryIsc();
        System.Assert.areEqual(2, insertedIscList.size(), 'Wrong inserted individual score size!');

        for(reduivy__Individual_Score__c insertedIsc : insertedIscList) {
            if(insertedIsc.Name == SCF_SRC) {
                System.Assert.areEqual(9, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else if (insertedIsc.Name == NEW_SCF_SRC) {
                System.Assert.areEqual(0, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else {
                System.Assert.fail('Invalid statement!');
            }
            
            for(reduivy__Individual_Score_Detail__c isd : insertedIsc.reduivy__Individual_Score_Details__r) {
                System.Assert.areEqual(
                    scrMap.get(isd.reduivy__Study_Scoring_Criteria__c).reduivy__Parent_Criteria__c,
                    isd.reduivy__Parent_Score_Detail__r.reduivy__Study_Scoring_Criteria__c,
                    'Wrong Parent!'
                );
            }
        }

        Test.stopTest();
		
    }


    /**
     * @description Test as admin for creating new individual score
     */
    @IsTest
    static void testForBulkInsert_TwoScf_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        Contact student = queryStudent();
        Integer iscSize = 100;
        List<reduivy__Individual_Score__c> iscList = new List<reduivy__Individual_Score__c>();

        Test.startTest();
        
        createNewScf();

        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        
        reduivy__Study_Scoring_Config__c scf1 = queryScf(SCF_SRC);
        reduivy__Study_Scoring_Config__c scf2 = queryScf(NEW_SCF_SRC);
        Map<Id, reduivy__Study_Scoring_Criteria__c> scrMap = new Map<Id, reduivy__Study_Scoring_Criteria__c>(scf1.reduivy__Study_Scoring_Criteria__r);
        scrMap.putAll(new Map<Id, reduivy__Study_Scoring_Criteria__c> (scf2.reduivy__Study_Scoring_Criteria__r));

        for(Integer i = 0; i < iscSize; i++) {
            if(Math.mod(i, 2) == 0) {
                reduivy__Individual_Score__c isc1 = new reduivy__Individual_Score__c(
                    Name = SCF_SRC,
                    reduivy__Individual_Program_Application__c = ipa.Id,
                    reduivy__Study_Scoring_Config__c = scf1.Id
                );
                iscList.add(isc1);
            } else {
                reduivy__Individual_Score__c isc2 = new reduivy__Individual_Score__c(
                    Name = NEW_SCF_SRC,
                    reduivy__Individual_Program_Application__c = ipa.Id,
                    reduivy__Study_Scoring_Config__c = scf2.Id
                );
                iscList.add(isc2);
            }
        }

		System.runAs(ADMIN_USER){
            insert iscList;
		}

        List<reduivy__Individual_Score__c> insertedIscList = queryIsc();
        System.Assert.areEqual(100, insertedIscList.size(), 'Wrong inserted individual score size!');

        for(reduivy__Individual_Score__c insertedIsc : insertedIscList) {
            if(insertedIsc.Name == SCF_SRC) {
                System.Assert.areEqual(9, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else if (insertedIsc.Name == NEW_SCF_SRC) {
                System.Assert.areEqual(4, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else {
                System.Assert.fail('Invalid statement!');
            }
            
            for(reduivy__Individual_Score_Detail__c isd : insertedIsc.reduivy__Individual_Score_Details__r) {
                System.Assert.areEqual(
                    scrMap.get(isd.reduivy__Study_Scoring_Criteria__c).reduivy__Parent_Criteria__c,
                    isd.reduivy__Parent_Score_Detail__r.reduivy__Study_Scoring_Criteria__c,
                    'Wrong Parent!'
                );
            }
        }

        Test.stopTest();
		
    }

    
    /**
     * @description Test as faculty for creating new individual score
     */
    @IsTest
    static void testForInsert_OneScf_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();
        
        Contact student = queryStudent();
        

        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        reduivy__Study_Scoring_Config__c scf = queryScf(SCF_SRC);
        Map<Id, reduivy__Study_Scoring_Criteria__c> scrMap = new Map<Id, reduivy__Study_Scoring_Criteria__c>(scf.reduivy__Study_Scoring_Criteria__r);

        reduivy__Individual_Score__c isc = new reduivy__Individual_Score__c(
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf.Id
        );
        
		System.runAs(FACULTY_USER){
            insert isc;
		}

        List<reduivy__Individual_Score__c> insertedIscList = queryIsc();
        System.Assert.areEqual(1, insertedIscList.size(), 'Wrong inserted individual score size!');

        for(reduivy__Individual_Score__c insertedIsc : insertedIscList) {
            System.Assert.areEqual(9, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');

            for(reduivy__Individual_Score_Detail__c isd : insertedIsc.reduivy__Individual_Score_Details__r) {
                System.Assert.areEqual(
                    scrMap.get(isd.reduivy__Study_Scoring_Criteria__c).reduivy__Parent_Criteria__c,
                    isd.reduivy__Parent_Score_Detail__r.reduivy__Study_Scoring_Criteria__c,
                    'Wrong Parent!'
                );
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for creating new individual score
     */
    @IsTest
    static void testForInsert_TwoScf_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Contact student = queryStudent();

        Test.startTest();
        
        createNewScf();

        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        reduivy__Study_Scoring_Config__c scf1 = queryScf(SCF_SRC);
        reduivy__Study_Scoring_Config__c scf2 = queryScf(NEW_SCF_SRC);
        Map<Id, reduivy__Study_Scoring_Criteria__c> scrMap = new Map<Id, reduivy__Study_Scoring_Criteria__c>(scf1.reduivy__Study_Scoring_Criteria__r);
        scrMap.putAll(new Map<Id, reduivy__Study_Scoring_Criteria__c> (scf2.reduivy__Study_Scoring_Criteria__r));

        reduivy__Individual_Score__c isc1 = new reduivy__Individual_Score__c(
            Name = SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf1.Id
        );

        reduivy__Individual_Score__c isc2 = new reduivy__Individual_Score__c(
            Name = NEW_SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf2.Id
        );
        
		System.runAs(FACULTY_USER){
            insert new List<reduivy__Individual_Score__c> { isc1, isc2 };
		}

        List<reduivy__Individual_Score__c> insertedIscList = queryIsc();
        System.Assert.areEqual(2, insertedIscList.size(), 'Wrong inserted individual score size!');

        for(reduivy__Individual_Score__c insertedIsc : insertedIscList) {
            if(insertedIsc.Name == SCF_SRC) {
                System.Assert.areEqual(9, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else if (insertedIsc.Name == NEW_SCF_SRC) {
                System.Assert.areEqual(4, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else {
                System.Assert.fail('Invalid statement!');
            }
            
            for(reduivy__Individual_Score_Detail__c isd : insertedIsc.reduivy__Individual_Score_Details__r) {
                System.Assert.areEqual(
                    scrMap.get(isd.reduivy__Study_Scoring_Criteria__c).reduivy__Parent_Criteria__c,
                    isd.reduivy__Parent_Score_Detail__r.reduivy__Study_Scoring_Criteria__c,
                    'Wrong Parent!'
                );
            }
        }

        Test.stopTest();
		
    }


    /**
     * @description Test as faculty for creating new individual score, one of the scf has no child scr
     */
    @IsTest
    static void testForInsert_TwoScf_OneEmpty_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Contact student = queryStudent();

        Test.startTest();
        
        createNewScf(true);

        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        reduivy__Study_Scoring_Config__c scf1 = queryScf(SCF_SRC);
        reduivy__Study_Scoring_Config__c scf2 = queryScf(NEW_SCF_SRC);
        Map<Id, reduivy__Study_Scoring_Criteria__c> scrMap = new Map<Id, reduivy__Study_Scoring_Criteria__c>(scf1.reduivy__Study_Scoring_Criteria__r);
        scrMap.putAll(new Map<Id, reduivy__Study_Scoring_Criteria__c> (scf2.reduivy__Study_Scoring_Criteria__r));

        reduivy__Individual_Score__c isc1 = new reduivy__Individual_Score__c(
            Name = SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf1.Id
        );

        reduivy__Individual_Score__c isc2 = new reduivy__Individual_Score__c(
            Name = NEW_SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf2.Id
        );
        
		System.runAs(FACULTY_USER){
            insert new List<reduivy__Individual_Score__c> { isc1, isc2 };
		}

        List<reduivy__Individual_Score__c> insertedIscList = queryIsc();
        System.Assert.areEqual(2, insertedIscList.size(), 'Wrong inserted individual score size!');

        for(reduivy__Individual_Score__c insertedIsc : insertedIscList) {
            if(insertedIsc.Name == SCF_SRC) {
                System.Assert.areEqual(9, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else if (insertedIsc.Name == NEW_SCF_SRC) {
                System.Assert.areEqual(0, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else {
                System.Assert.fail('Invalid statement!');
            }
            
            for(reduivy__Individual_Score_Detail__c isd : insertedIsc.reduivy__Individual_Score_Details__r) {
                System.Assert.areEqual(
                    scrMap.get(isd.reduivy__Study_Scoring_Criteria__c).reduivy__Parent_Criteria__c,
                    isd.reduivy__Parent_Score_Detail__r.reduivy__Study_Scoring_Criteria__c,
                    'Wrong Parent!'
                );
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for creating new individual score, one of the scf has all child scr inactive
     */
    @IsTest
    static void testForInsert_TwoScf_OneChildInactive_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Contact student = queryStudent();

        Test.startTest();
        
        createNewScf();

        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        reduivy__Study_Scoring_Config__c scf1 = queryScf(SCF_SRC);
        reduivy__Study_Scoring_Config__c scf2 = queryScf(NEW_SCF_SRC);

        //update scf2 children to inactive
        for(reduivy__Study_Scoring_Criteria__c scr : scf2.reduivy__Study_Scoring_Criteria__r) {
            scr.reduivy__Status__c = SCR_Helper.STATUS_ARCHIVED;
        }

        update scf2.reduivy__Study_Scoring_Criteria__r;

        Map<Id, reduivy__Study_Scoring_Criteria__c> scrMap = new Map<Id, reduivy__Study_Scoring_Criteria__c>(scf1.reduivy__Study_Scoring_Criteria__r);
        scrMap.putAll(new Map<Id, reduivy__Study_Scoring_Criteria__c> (scf2.reduivy__Study_Scoring_Criteria__r));

        reduivy__Individual_Score__c isc1 = new reduivy__Individual_Score__c(
            Name = SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf1.Id
        );

        reduivy__Individual_Score__c isc2 = new reduivy__Individual_Score__c(
            Name = NEW_SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf2.Id
        );
        
		System.runAs(FACULTY_USER){
            insert new List<reduivy__Individual_Score__c> { isc1, isc2 };
		}

        List<reduivy__Individual_Score__c> insertedIscList = queryIsc();
        System.Assert.areEqual(2, insertedIscList.size(), 'Wrong inserted individual score size!');

        for(reduivy__Individual_Score__c insertedIsc : insertedIscList) {
            if(insertedIsc.Name == SCF_SRC) {
                System.Assert.areEqual(9, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else if (insertedIsc.Name == NEW_SCF_SRC) {
                System.Assert.areEqual(0, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else {
                System.Assert.fail('Invalid statement!');
            }
            
            for(reduivy__Individual_Score_Detail__c isd : insertedIsc.reduivy__Individual_Score_Details__r) {
                System.Assert.areEqual(
                    scrMap.get(isd.reduivy__Study_Scoring_Criteria__c).reduivy__Parent_Criteria__c,
                    isd.reduivy__Parent_Score_Detail__r.reduivy__Study_Scoring_Criteria__c,
                    'Wrong Parent!'
                );
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as student for creating new individual score
     */
    @IsTest
    static void testForInsert_OneScf_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User studentUser = testFactory.getStudentUser();
        Test.startTest();
        
        Contact student = queryStudent();
        

        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        reduivy__Study_Scoring_Config__c scf = queryScf(SCF_SRC);
        Map<Id, reduivy__Study_Scoring_Criteria__c> scrMap = new Map<Id, reduivy__Study_Scoring_Criteria__c>(scf.reduivy__Study_Scoring_Criteria__r);

        reduivy__Individual_Score__c isc = new reduivy__Individual_Score__c(
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf.Id
        );
        
		System.runAs(studentUser){
            insert isc;
		}

        List<reduivy__Individual_Score__c> insertedIscList = queryIsc();
        System.Assert.areEqual(1, insertedIscList.size(), 'Wrong inserted individual score size!');

        for(reduivy__Individual_Score__c insertedIsc : insertedIscList) {
            System.Assert.areEqual(9, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');

            for(reduivy__Individual_Score_Detail__c isd : insertedIsc.reduivy__Individual_Score_Details__r) {
                System.Assert.areEqual(
                    scrMap.get(isd.reduivy__Study_Scoring_Criteria__c).reduivy__Parent_Criteria__c,
                    isd.reduivy__Parent_Score_Detail__r.reduivy__Study_Scoring_Criteria__c,
                    'Wrong Parent!'
                );
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as student for creating new individual score
     */
    @IsTest
    static void testForInsert_TwoScf_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User studentUser = testFactory.getStudentUser();
        Contact student = queryStudent();

        Test.startTest();
        
        createNewScf();

        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        reduivy__Study_Scoring_Config__c scf1 = queryScf(SCF_SRC);
        reduivy__Study_Scoring_Config__c scf2 = queryScf(NEW_SCF_SRC);
        Map<Id, reduivy__Study_Scoring_Criteria__c> scrMap = new Map<Id, reduivy__Study_Scoring_Criteria__c>(scf1.reduivy__Study_Scoring_Criteria__r);
        scrMap.putAll(new Map<Id, reduivy__Study_Scoring_Criteria__c> (scf2.reduivy__Study_Scoring_Criteria__r));

        reduivy__Individual_Score__c isc1 = new reduivy__Individual_Score__c(
            Name = SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf1.Id
        );

        reduivy__Individual_Score__c isc2 = new reduivy__Individual_Score__c(
            Name = NEW_SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf2.Id
        );
        
		System.runAs(studentUser){
            insert new List<reduivy__Individual_Score__c> { isc1, isc2 };
		}

        List<reduivy__Individual_Score__c> insertedIscList = queryIsc();
        System.Assert.areEqual(2, insertedIscList.size(), 'Wrong inserted individual score size!');

        for(reduivy__Individual_Score__c insertedIsc : insertedIscList) {
            if(insertedIsc.Name == SCF_SRC) {
                System.Assert.areEqual(9, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else if (insertedIsc.Name == NEW_SCF_SRC) {
                System.Assert.areEqual(4, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else {
                System.Assert.fail('Invalid statement!');
            }
            
            for(reduivy__Individual_Score_Detail__c isd : insertedIsc.reduivy__Individual_Score_Details__r) {
                System.Assert.areEqual(
                    scrMap.get(isd.reduivy__Study_Scoring_Criteria__c).reduivy__Parent_Criteria__c,
                    isd.reduivy__Parent_Score_Detail__r.reduivy__Study_Scoring_Criteria__c,
                    'Wrong Parent!'
                );
            }
        }

        Test.stopTest();
		
    }


    /**
     * @description Test as student for creating new individual score, one of the scf has no child scr
     */
    @IsTest
    static void testForInsert_TwoScf_OneEmpty_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User studentUser = testFactory.getStudentUser();
        Contact student = queryStudent();

        Test.startTest();
        
        createNewScf(true);

        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        reduivy__Study_Scoring_Config__c scf1 = queryScf(SCF_SRC);
        reduivy__Study_Scoring_Config__c scf2 = queryScf(NEW_SCF_SRC);
        Map<Id, reduivy__Study_Scoring_Criteria__c> scrMap = new Map<Id, reduivy__Study_Scoring_Criteria__c>(scf1.reduivy__Study_Scoring_Criteria__r);
        scrMap.putAll(new Map<Id, reduivy__Study_Scoring_Criteria__c> (scf2.reduivy__Study_Scoring_Criteria__r));

        reduivy__Individual_Score__c isc1 = new reduivy__Individual_Score__c(
            Name = SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf1.Id
        );

        reduivy__Individual_Score__c isc2 = new reduivy__Individual_Score__c(
            Name = NEW_SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf2.Id
        );
        
		System.runAs(studentUser){
            insert new List<reduivy__Individual_Score__c> { isc1, isc2 };
		}

        List<reduivy__Individual_Score__c> insertedIscList = queryIsc();
        System.Assert.areEqual(2, insertedIscList.size(), 'Wrong inserted individual score size!');

        for(reduivy__Individual_Score__c insertedIsc : insertedIscList) {
            if(insertedIsc.Name == SCF_SRC) {
                System.Assert.areEqual(9, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else if (insertedIsc.Name == NEW_SCF_SRC) {
                System.Assert.areEqual(0, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else {
                System.Assert.fail('Invalid statement!');
            }
            
            for(reduivy__Individual_Score_Detail__c isd : insertedIsc.reduivy__Individual_Score_Details__r) {
                System.Assert.areEqual(
                    scrMap.get(isd.reduivy__Study_Scoring_Criteria__c).reduivy__Parent_Criteria__c,
                    isd.reduivy__Parent_Score_Detail__r.reduivy__Study_Scoring_Criteria__c,
                    'Wrong Parent!'
                );
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as student for creating new individual score, one of the scf has all child scr inactive
     */
    @IsTest
    static void testForInsert_TwoScf_OneChildInactive_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User studentUser = testFactory.getStudentUser();
        Contact student = queryStudent();

        Test.startTest();
        
        createNewScf();

        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');

        reduivy__Individual_Program_Application__c ipa = queryIpa();
        reduivy__Study_Scoring_Config__c scf1 = queryScf(SCF_SRC);
        reduivy__Study_Scoring_Config__c scf2 = queryScf(NEW_SCF_SRC);

        //update scf2 children to inactive
        for(reduivy__Study_Scoring_Criteria__c scr : scf2.reduivy__Study_Scoring_Criteria__r) {
            scr.reduivy__Status__c = SCR_Helper.STATUS_ARCHIVED;
        }

        update scf2.reduivy__Study_Scoring_Criteria__r;

        Map<Id, reduivy__Study_Scoring_Criteria__c> scrMap = new Map<Id, reduivy__Study_Scoring_Criteria__c>(scf1.reduivy__Study_Scoring_Criteria__r);
        scrMap.putAll(new Map<Id, reduivy__Study_Scoring_Criteria__c> (scf2.reduivy__Study_Scoring_Criteria__r));

        reduivy__Individual_Score__c isc1 = new reduivy__Individual_Score__c(
            Name = SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf1.Id
        );

        reduivy__Individual_Score__c isc2 = new reduivy__Individual_Score__c(
            Name = NEW_SCF_SRC,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf2.Id
        );
        
		System.runAs(studentUser){
            insert new List<reduivy__Individual_Score__c> { isc1, isc2 };
		}

        List<reduivy__Individual_Score__c> insertedIscList = queryIsc();
        System.Assert.areEqual(2, insertedIscList.size(), 'Wrong inserted individual score size!');

        for(reduivy__Individual_Score__c insertedIsc : insertedIscList) {
            if(insertedIsc.Name == SCF_SRC) {
                System.Assert.areEqual(9, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else if (insertedIsc.Name == NEW_SCF_SRC) {
                System.Assert.areEqual(0, insertedIsc.reduivy__Individual_Score_Details__r.size(), 'Wrong inserted individual score details size!');
            } else {
                System.Assert.fail('Invalid statement!');
            }
            
            for(reduivy__Individual_Score_Detail__c isd : insertedIsc.reduivy__Individual_Score_Details__r) {
                System.Assert.areEqual(
                    scrMap.get(isd.reduivy__Study_Scoring_Criteria__c).reduivy__Parent_Criteria__c,
                    isd.reduivy__Parent_Score_Detail__r.reduivy__Study_Scoring_Criteria__c,
                    'Wrong Parent!'
                );
            }
        }

        Test.stopTest();
		
    }

    static Contact queryStudent(){
        return [SELECT Id, Name FROM Contact WHERE reduivy__Sample_Record_Code__c = :STUDENT_CON LIMIT 1];
    }
    
    static reduivy__Individual_Program_Application__c queryIpa() {
        return [
            SELECT Id, Name
            FROM reduivy__Individual_Program_Application__c
            WHERE reduivy__Sample_Record_Code__c = :STUDENT_CON
            LIMIT 1
        ];
    }

    static List<reduivy__Individual_Score__c> queryIsc(){
        return [
            SELECT Id, Name,
            (SELECT Id, Name, reduivy__Study_Scoring_Criteria__c, reduivy__Parent_Score_Detail__r.reduivy__Study_Scoring_Criteria__c FROM reduivy__Individual_Score_Details__r)
            FROM reduivy__Individual_Score__c
            WHERE reduivy__Individual_Program_Application__r.reduivy__Sample_Record_Code__c = :STUDENT_CON
        ];

    }

    static reduivy__Study_Scoring_Config__c queryScf(String scfSrc) {
        return [
            SELECT Id, Name, (
                SELECT Id, Name, reduivy__Parent_Criteria__c, reduivy__Study_Requirement__c, reduivy__Sequence__c,
                reduivy__Score_Logic__c, reduivy__Weight__c, reduivy__Max_Score__c
                FROM reduivy__Study_Scoring_Criteria__r
                ORDER BY Name ASC, Id ASC
            )
            FROM reduivy__Study_Scoring_Config__c
            WHERE reduivy__Sample_Record_Code__c = :scfSrc
            LIMIT 1
        ];
    }

    static void createNewScf() {
        createNewScf(false);
    }
	
    static void createNewScf(Boolean isEmpty) {
        reduivy__Study_Scoring_Config__c newScf = REDU_TestData_UTIL.newStudyScoringConfig(NEW_SCF_SRC, NEW_SCF_SRC, NEW_SCF_SRC, IPA_Helper.getApiName(), 'reduivy__Contact__c', 'AND(TEXT(reduivy__Application_Status__c) = "Reviewing", NOT(ISBLANK(reduivy__Contact__c)))');

        insert newScf;

        if(!isEmpty) {

            reduivy__Study_Scoring_Criteria__c newScr1_1 = REDU_TestData_UTIL.newStudyScoringCriteria(NEW_SCR1_1_SRC, NEW_SCR1_1_SRC, NEW_SCR1_1_SRC, newScf.Id, null, null, 1, '', 50, null);
            reduivy__Study_Scoring_Criteria__c newScr1_2 = REDU_TestData_UTIL.newStudyScoringCriteria(NEW_SCR1_2_SRC, NEW_SCR1_2_SRC, NEW_SCR1_2_SRC, newScf.Id, null, null, 2, '', 50, null);
            reduivy__Study_Scoring_Criteria__c newScr2_1 = REDU_TestData_UTIL.newStudyScoringCriteria(NEW_SCR2_1_SRC, NEW_SCR2_1_SRC, NEW_SCR2_1_SRC, newScf.Id, null, null, 1, '', 50, null);
            reduivy__Study_Scoring_Criteria__c newScr2_2 = REDU_TestData_UTIL.newStudyScoringCriteria(NEW_SCR2_2_SRC, NEW_SCR2_2_SRC, NEW_SCR2_2_SRC, newScf.Id, null, null, 2, '', 50, null);
            
            insert new List<reduivy__Study_Scoring_Criteria__c> {newScr1_1, newScr1_2, newScr2_1, newScr2_2};
            
            newScr2_1.reduivy__Parent_Criteria__c = newscr1_1.Id;
            newScr2_2.reduivy__Parent_Criteria__c = newscr1_1.Id;
            update new List<reduivy__Study_Scoring_Criteria__c> {
                newScr2_1, newScr2_2
            };
        }
    }

}