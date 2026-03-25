/**
 * @author      WDCi (XW)
 * @date        Aug 2025
 * @group       Test
 * @description Test class for ISD_LinkRequirement_EXE
 * @changehistory
 * ISS-002506 25-08-2025 XW - new class
 */
@IsTest
public inherited sharing class ISD_LinkRequirement_TEST {

    static final String STUDENT_CON = 'sandydoe@redu.example';
    static final String SCF_SRC = 'SCF_Application';
    static final String SRS_SRC = 'SRS_Application';
    static final String SRC_SRQ_CGPA = 'SRS_Application_CGPA';

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

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
            testFactory.initStudentData(CTA_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for inserting isd where irq is NOT inserted before
     */
    @IsTest
    static void testForInsert_NoRequirementInserted_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        
		System.runAs(ADMIN_USER){
            insert ipa;
		}

        List<reduivy__Individual_Requirement_Set__c> irsList = queryIrs();
        Map<Id, reduivy__Individual_Requirement__c> irqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement_Set__c irs : irsList) {
            irqMap.putAll(new Map<Id, reduivy__Individual_Requirement__c> (irs.reduivy__Individual_Requirements__r)); 
        }
        
        List<reduivy__Individual_Score__c> insertedIsc = queryIsc();

        System.Assert.areEqual(1, insertedIsc.size(), 'Wrong individual score size!');
        System.Assert.areEqual(9, insertedIsc[0].reduivy__Individual_Score_Details__r.size(), 'Wrong individual score detail size!');
        for(reduivy__Individual_Score_Detail__c isd : insertedIsc[0].reduivy__Individual_Score_Details__r) {
            if(isd.reduivy__Study_Requirement__c != null) {
                reduivy__Individual_Requirement__c irq = irqMap.get(isd.reduivy__Individual_Requirement__c);
                System.Assert.areEqual(isd.reduivy__Study_Requirement__c, irq.reduivy__Study_Requirement__c, 'Wrong Individual Requirement created!');
            } else {
                System.Assert.isNull(isd.reduivy__Individual_Requirement__c, 'Individual Requirement should not be linked!');
            }
        }
        
        Test.stopTest();
		
    }
    
    /**
     * @description Test as admin for inserting isd where irq is inserted before
     */
    @IsTest
    static void testForInsert_RequirementInserted_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        Set<String> triggersToMute = new Set<String> {'SOBJ_IndividualScoreGeneration_EXE'};
        REDU_TriggerController.muteTriggers(triggersToMute);

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED
        );
        
        insert ipa;

        REDU_TriggerController.unmuteTriggers(triggersToMute);

        //generate irs that its srs has the generation mode = manual
        reduivy__Study_Requirement_Set__c srs = querySrs();
        reduivy__Individual_Requirement_Set__c insertIrs = new reduivy__Individual_Requirement_Set__c(
            reduivy__Study_Requirement_Set__c = srs.Id,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Status__c = IRS_Helper.STATUS_ACTIVE,
            reduivy__Requirement_Generation_Mode__c = IRS_Helper.REQUIREMENT_GENERATION_MODE_AUTO
        );
        insert insertIrs;

        List<reduivy__Individual_Requirement_Set__c> irsList = queryIrs();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement_Set__c irs : irsList) {
            expectedIrqMap.putAll(new Map<Id, reduivy__Individual_Requirement__c> (irs.reduivy__Individual_Requirements__r)); 
        }

        reduivy__Study_Scoring_Config__c scf = queryScf(SCF_SRC);

        //insert isc and isd
        reduivy__Individual_Score__c isc = new reduivy__Individual_Score__c(
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf.Id,
            reduivy__Status__c = ISC_Helper.STATUS_ACTIVE
        );

		System.runAs(ADMIN_USER){
            insert isc;
		}

        List<reduivy__Individual_Score__c> insertedIsc = queryIsc();

        System.Assert.areEqual(1, insertedIsc.size(), 'Wrong individual score size!');
        System.Assert.areEqual(9, insertedIsc[0].reduivy__Individual_Score_Details__r.size(), 'Wrong individual score detail size!');
        for(reduivy__Individual_Score_Detail__c isd : insertedIsc[0].reduivy__Individual_Score_Details__r) {
            if(isd.reduivy__Study_Requirement__c != null) {
                reduivy__Individual_Requirement__c irq = expectedIrqMap.get(isd.reduivy__Individual_Requirement__c);
                System.Assert.areEqual(isd.reduivy__Study_Requirement__c, irq.reduivy__Study_Requirement__c, 'Wrong Individual Requirement created!');
                System.Assert.areEqual(irq.Id, isd.reduivy__Individual_Requirement__c, 'Individual Requirement should be the same as the one when ipa is created!');
            } else {
                System.Assert.isNull(isd.reduivy__Individual_Requirement__c, 'Individual Requirement should not be linked!');
            }
        }
        
        Test.stopTest();
		
    }

    @IsTest
    static void testForInsert_StudyRequirementInactive_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');


        reduivy__Study_Requirement__c srqCgpa = [SELECT Id, Name, reduivy__Status__c FROM reduivy__Study_Requirement__c WHERE reduivy__Sample_Record_Code__c = :SRC_SRQ_CGPA];
        srqCgpa.reduivy__Status__c = SRQ_Helper.STATUS_ARCHIVED;

        update srqCgpa;
        
        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );


        System.runAs(ADMIN_USER) {

            try {
                insert ipa;

                System.Assert.fail('Should be failed because of study requirement != active!');
            } catch (Exception exp) {
                String expectedErrMsg = String.format(
                    Label.Study_Requirement_Used_Is_Inactive, new List<String> {
                        SRQ_Helper.getObjectLabel(),
                        SCR_Helper.getObjectLabel(),
                        srqCgpa.Name
                    }
                );
                System.Assert.isTrue(exp.getMessage().contains(expectedErrMsg), 'Wrong exception message when Study Requirement != active! Actual: ' + exp.getMessage());
            }
            
        }


        Test.stopTest();
    }

    @IsTest
    static void testForInsert_StudyRequirementSetInactive_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');


        reduivy__Study_Requirement_Set__c srs = querySrs();
        srs.reduivy__Status__c = SRS_Helper.STATUS_ARCHIVED;

        update srs;
        
        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );


        System.runAs(ADMIN_USER) {

            try {
                insert ipa;

                System.Assert.fail('Should be failed because of study requirement != active!');
            } catch (Exception exp) {
                String expectedErrMsg = String.format(
                    Label.Study_Requirement_Set_Used_Is_Inactive, new List<String> {
                        SRS_Helper.getObjectLabel(),
                        SCR_Helper.getObjectLabel(),
                        srs.Name
                    }
                );
                System.Assert.isTrue(exp.getMessage().contains(expectedErrMsg), 'Wrong exception message when Study Requirement != active! Actual: ' + exp.getMessage());
            }
            
        }


        Test.stopTest();
    }
	
    /**
     * @description Test as admin for bulk inserting isd where irq is NOT inserted before
     */
    @IsTest
    static void testForBulkInsert_NoRequirementInserted_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        Contact student = queryStudent();
        Integer ipaSize = 100;

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();
        for(Integer i = 0; i < ipaSize; i++) {
            ipaList.add(
                new reduivy__Individual_Program_Application__c(
                    reduivy__Contact__c = student.Id,
                    reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
                )
            );
        }
        REDU_TriggerController.muteTriggers(new Set<String> {'IPA_PreventDuplicate_EXE'});
        
		System.runAs(ADMIN_USER){
            insert ipaList;
		}
        REDU_TriggerController.unmuteTriggers(new Set<String> {'IPA_PreventDuplicate_EXE'});
        
        List<reduivy__Individual_Requirement_Set__c> irsList = queryIrs();
        Map<Id, reduivy__Individual_Requirement__c> irqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement_Set__c irs : irsList) {
            irqMap.putAll(new Map<Id, reduivy__Individual_Requirement__c> (irs.reduivy__Individual_Requirements__r)); 
        }
        
        List<reduivy__Individual_Score__c> insertedIsc = queryIsc();

        System.Assert.areEqual(ipaSize, insertedIsc.size(), 'Wrong individual score size!');
        System.Assert.areEqual(9, insertedIsc[0].reduivy__Individual_Score_Details__r.size(), 'Wrong individual score detail size!');
        for(reduivy__Individual_Score__c isc : insertedIsc) {
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                if(isd.reduivy__Study_Requirement__c != null) {
                    reduivy__Individual_Requirement__c irq = irqMap.get(isd.reduivy__Individual_Requirement__c);
                    System.Assert.areEqual(isd.reduivy__Study_Requirement__c, irq.reduivy__Study_Requirement__c, 'Wrong Individual Requirement created!');
                } else {
                    System.Assert.isNull(isd.reduivy__Individual_Requirement__c, 'Individual Requirement should not be linked!');
                }
            }
        }
        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating isd where irq is NOT inserted before
     */
    @IsTest
    static void testForUpdate_NoRequirementInserted_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        Set<String> triggersToMute = new Set<String> {'SOBJ_IndividualScoreGeneration_EXE'};
        REDU_TriggerController.muteTriggers(triggersToMute);

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        
        insert ipa;

        REDU_TriggerController.unmuteTriggers(triggersToMute);

        reduivy__Study_Scoring_Config__c scf = queryScf(SCF_SRC);

        //insert isc and isd
        reduivy__Individual_Score__c isc = new reduivy__Individual_Score__c(
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf.Id,
            reduivy__Status__c = ISC_Helper.STATUS_ACTIVE
        );

        
        REDU_TriggerController.muteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE'});
        
        insert isc;
        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE'});

        reduivy__Individual_Score_Detail__c isdToInsert = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = isc.Id,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
            reduivy__Weight__c = 100
        );

        insert isdToInsert;

        //update isd with study requirement
        reduivy__Study_Requirement_Set__c srs = querySrs();
        insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        System.runAs(ADMIN_USER) {
            isdToInsert.reduivy__Study_Requirement__c = srs.reduivy__Study_Requirements__r[0].Id;
            update isdToInsert;
        }

        List<reduivy__Individual_Requirement_Set__c> irsList = queryIrs();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement_Set__c irs : irsList) {
            expectedIrqMap.putAll(new Map<Id, reduivy__Individual_Requirement__c> (irs.reduivy__Individual_Requirements__r)); 
        }
        System.Assert.areEqual(1, expectedIrqMap.size(), 'Wrong inserted individual requirement size!');
        
        List<reduivy__Individual_Score__c> insertedIsc = queryIsc();

        System.Assert.areEqual(1, insertedIsc.size(), 'Wrong individual score size!');
        System.Assert.areEqual(1, insertedIsc[0].reduivy__Individual_Score_Details__r.size(), 'Wrong individual score detail size!');
        for(reduivy__Individual_Score_Detail__c isd : insertedIsc[0].reduivy__Individual_Score_Details__r) {
            reduivy__Individual_Requirement__c irq = expectedIrqMap.get(isd.reduivy__Individual_Requirement__c);
            System.Assert.areEqual(isd.reduivy__Study_Requirement__c, irq.reduivy__Study_Requirement__c, 'Wrong Individual Requirement created!');
            System.Assert.areEqual(irq.Id, isd.reduivy__Individual_Requirement__c, 'Individual Requirement should be the same as the one when ipa is created!');
            
        }
        
        Test.stopTest();
		
    }


    /**
     * @description Test as admin for updating isd where irq is inserted before
     */
    @IsTest
    static void testForUpdate_RequirementInserted_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        Set<String> triggersToMute = new Set<String> {'SOBJ_IndividualScoreGeneration_EXE'};
        REDU_TriggerController.muteTriggers(triggersToMute);

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED
        );
        
        insert ipa;

        REDU_TriggerController.unmuteTriggers(triggersToMute);
        
        reduivy__Study_Requirement_Set__c srs = querySrs();
        reduivy__Individual_Requirement_Set__c insertIrs = new reduivy__Individual_Requirement_Set__c(
            reduivy__Study_Requirement_Set__c = srs.Id,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Status__c = IRS_Helper.STATUS_ACTIVE,
            reduivy__Requirement_Generation_Mode__c = IRS_Helper.REQUIREMENT_GENERATION_MODE_AUTO
        );
        insert insertIrs;

        insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(3, insertedIrsCount, 'Individual requirement set should be inserted!');
        System.Assert.areNotEqual(0, insertedIrqCount, 'Individual requirement should be inserted!');

        List<reduivy__Individual_Requirement_Set__c> irsList = queryIrs();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement_Set__c irs : irsList) {
            expectedIrqMap.putAll(new Map<Id, reduivy__Individual_Requirement__c> (irs.reduivy__Individual_Requirements__r)); 
        }
        

        reduivy__Study_Scoring_Config__c scf = queryScf(SCF_SRC);

        //insert isc and isd
        reduivy__Individual_Score__c isc = new reduivy__Individual_Score__c(
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf.Id,
            reduivy__Status__c = ISC_Helper.STATUS_ACTIVE
        );

        
        REDU_TriggerController.muteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE'});
        
        insert isc;
        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE'});

        reduivy__Individual_Score_Detail__c isdToInsert = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = isc.Id,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
            reduivy__Weight__c = 100
        );

        insert isdToInsert;

        //isd with irq linked should be 0
        Integer isdWithIrqLinked = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id AND reduivy__Individual_Requirement__c != null];
        System.Assert.areEqual(0, isdWithIrqLinked, 'Individual score detail with individual requirement linked should be 0!');

        //update isd with study requirement
        System.runAs(ADMIN_USER) {
            isdToInsert.reduivy__Study_Requirement__c = srs.reduivy__Study_Requirements__r[0].Id;
            update isdToInsert;
        }

        List<reduivy__Individual_Score__c> insertedIsc = queryIsc();

        System.Assert.areEqual(1, insertedIsc.size(), 'Wrong individual score size!');
        System.Assert.areEqual(1, insertedIsc[0].reduivy__Individual_Score_Details__r.size(), 'Wrong individual score detail size!');
        for(reduivy__Individual_Score_Detail__c isd : insertedIsc[0].reduivy__Individual_Score_Details__r) {
            reduivy__Individual_Requirement__c irq = expectedIrqMap.get(isd.reduivy__Individual_Requirement__c);
            System.Assert.areEqual(isd.reduivy__Study_Requirement__c, irq.reduivy__Study_Requirement__c, 'Wrong Individual Requirement created!');
            System.Assert.areEqual(irq.Id, isd.reduivy__Individual_Requirement__c, 'Individual Requirement should be the same as the one when ipa is created!');
            
        }
        
        Test.stopTest();
		
    }

    
    /**
     * @description Test as faculty for inserting isd where irq is NOT inserted before
     */
    @IsTest
    static void testForInsert_NoRequirementInserted_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        
		System.runAs(FACULTY_USER){
            insert ipa;
		}

        List<reduivy__Individual_Requirement_Set__c> irsList = queryIrs();
        Map<Id, reduivy__Individual_Requirement__c> irqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement_Set__c irs : irsList) {
            irqMap.putAll(new Map<Id, reduivy__Individual_Requirement__c> (irs.reduivy__Individual_Requirements__r)); 
        }
        
        List<reduivy__Individual_Score__c> insertedIsc = queryIsc();

        System.Assert.areEqual(1, insertedIsc.size(), 'Wrong individual score size!');
        System.Assert.areEqual(9, insertedIsc[0].reduivy__Individual_Score_Details__r.size(), 'Wrong individual score detail size!');
        for(reduivy__Individual_Score_Detail__c isd : insertedIsc[0].reduivy__Individual_Score_Details__r) {
            if(isd.reduivy__Study_Requirement__c != null) {
                reduivy__Individual_Requirement__c irq = irqMap.get(isd.reduivy__Individual_Requirement__c);
                System.Assert.areEqual(isd.reduivy__Study_Requirement__c, irq.reduivy__Study_Requirement__c, 'Wrong Individual Requirement created!');
            } else {
                System.Assert.isNull(isd.reduivy__Individual_Requirement__c, 'Individual Requirement should not be linked!');
            }
        }
        
        Test.stopTest();
		
    }

    
    /**
     * @description Test as admin for bulk updating isd where irq is NOT inserted before
     */
    @IsTest
    static void testForBulkUpdate_NoRequirementInserted_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        Set<String> triggersToMute = new Set<String> {'SOBJ_IndividualScoreGeneration_EXE'};
        REDU_TriggerController.muteTriggers(triggersToMute);

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        
        insert ipa;

        REDU_TriggerController.unmuteTriggers(triggersToMute);

        reduivy__Study_Scoring_Config__c scf = queryScf(SCF_SRC);

        //insert isc and isd
        reduivy__Individual_Score__c isc = new reduivy__Individual_Score__c(
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf.Id,
            reduivy__Status__c = ISC_Helper.STATUS_ACTIVE
        );

        
        REDU_TriggerController.muteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE'});
        
        insert isc;
        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE'});

        List<reduivy__Individual_Score_Detail__c> isdList = new List<reduivy__Individual_Score_Detail__c>();
        Integer isdSize = 100;
        for(Integer i = 0; i < isdSize; i++) {
            isdList.add(
                new reduivy__Individual_Score_Detail__c(
                    reduivy__Individual_Score__c = isc.Id,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
                    reduivy__Weight__c = 1
                )
            );
        }

        insert isdList;

        //update isd with study requirement
        reduivy__Study_Requirement_Set__c srs = querySrs();
        insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        System.runAs(ADMIN_USER) {
            for(reduivy__Individual_Score_Detail__c isd : isdList) {
                isd.reduivy__Study_Requirement__c = srs.reduivy__Study_Requirements__r[0].Id;
            }
            update isdList;
        }

        List<reduivy__Individual_Requirement_Set__c> irsList = queryIrs();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement_Set__c irs : irsList) {
            expectedIrqMap.putAll(new Map<Id, reduivy__Individual_Requirement__c> (irs.reduivy__Individual_Requirements__r)); 
        }
        System.Assert.areEqual(1, expectedIrqMap.size(), 'Wrong inserted individual requirement size!');
        
        List<reduivy__Individual_Score__c> insertedIsc = queryIsc();

        System.Assert.areEqual(1, insertedIsc.size(), 'Wrong individual score size!');
        System.Assert.areEqual(isdSize, insertedIsc[0].reduivy__Individual_Score_Details__r.size(), 'Wrong individual score detail size!');
        for(reduivy__Individual_Score_Detail__c isd : insertedIsc[0].reduivy__Individual_Score_Details__r) {
            reduivy__Individual_Requirement__c irq = expectedIrqMap.get(isd.reduivy__Individual_Requirement__c);
            System.Assert.areEqual(isd.reduivy__Study_Requirement__c, irq.reduivy__Study_Requirement__c, 'Wrong Individual Requirement created!');
            System.Assert.areEqual(irq.Id, isd.reduivy__Individual_Requirement__c, 'Individual Requirement should be the same as the one when ipa is created!');
            
        }
        
        Test.stopTest();
		
    }


    
    /**
     * @description Test as faculty for inserting isd where irq is inserted before
     */
    @IsTest
    static void testForInsert_RequirementInserted_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        Set<String> triggersToMute = new Set<String> {'SOBJ_IndividualScoreGeneration_EXE'};
        REDU_TriggerController.muteTriggers(triggersToMute);

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED
        );
        
        insert ipa;

        REDU_TriggerController.unmuteTriggers(triggersToMute);

        //generate irs that its srs has the generation mode = manual
        reduivy__Study_Requirement_Set__c srs = querySrs();
        reduivy__Individual_Requirement_Set__c insertIrs = new reduivy__Individual_Requirement_Set__c(
            reduivy__Study_Requirement_Set__c = srs.Id,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Status__c = IRS_Helper.STATUS_ACTIVE,
            reduivy__Requirement_Generation_Mode__c = IRS_Helper.REQUIREMENT_GENERATION_MODE_AUTO
        );
        insert insertIrs;

        List<reduivy__Individual_Requirement_Set__c> irsList = queryIrs();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement_Set__c irs : irsList) {
            expectedIrqMap.putAll(new Map<Id, reduivy__Individual_Requirement__c> (irs.reduivy__Individual_Requirements__r)); 
        }

        reduivy__Study_Scoring_Config__c scf = queryScf(SCF_SRC);

        //insert isc and isd
        reduivy__Individual_Score__c isc = new reduivy__Individual_Score__c(
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf.Id,
            reduivy__Status__c = ISC_Helper.STATUS_ACTIVE
        );

        System.runAs(FACULTY_USER) {
            insert isc;
        }

        List<reduivy__Individual_Score__c> insertedIsc = queryIsc();

        System.Assert.areEqual(1, insertedIsc.size(), 'Wrong individual score size!');
        System.Assert.areEqual(9, insertedIsc[0].reduivy__Individual_Score_Details__r.size(), 'Wrong individual score detail size!');
        for(reduivy__Individual_Score_Detail__c isd : insertedIsc[0].reduivy__Individual_Score_Details__r) {
            if(isd.reduivy__Study_Requirement__c != null) {
                reduivy__Individual_Requirement__c irq = expectedIrqMap.get(isd.reduivy__Individual_Requirement__c);
                System.Assert.areEqual(isd.reduivy__Study_Requirement__c, irq.reduivy__Study_Requirement__c, 'Wrong Individual Requirement created!');
                System.Assert.areEqual(irq.Id, isd.reduivy__Individual_Requirement__c, 'Individual Requirement should be the same as the one when ipa is created!');
            } else {
                System.Assert.isNull(isd.reduivy__Individual_Requirement__c, 'Individual Requirement should not be linked!');
            }
        }
        
        Test.stopTest();
		
    }

    @IsTest
    static void testForInsert_StudyRequirementInactive_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');


        reduivy__Study_Requirement__c srqCgpa = [SELECT Id, Name, reduivy__Status__c FROM reduivy__Study_Requirement__c WHERE reduivy__Sample_Record_Code__c = :SRC_SRQ_CGPA];
        srqCgpa.reduivy__Status__c = SRQ_Helper.STATUS_ARCHIVED;

        update srqCgpa;
        
        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );


        System.runAs(FACULTY_USER) {

            try {
                insert ipa;

                System.Assert.fail('Should be failed because of study requirement != active!');
            } catch (Exception exp) {
                String expectedErrMsg = String.format(
                    Label.Study_Requirement_Used_Is_Inactive, new List<String> {
                        SRQ_Helper.getObjectLabel(),
                        SCR_Helper.getObjectLabel(),
                        srqCgpa.Name
                    }
                );
                System.Assert.isTrue(exp.getMessage().contains(expectedErrMsg), 'Wrong exception message when Study Requirement != active! Actual: ' + exp.getMessage());
            }
            
        }


        Test.stopTest();
    }

    @IsTest
    static void testForInsert_StudyRequirementSetInactive_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');


        reduivy__Study_Requirement_Set__c srs = querySrs();
        srs.reduivy__Status__c = SRS_Helper.STATUS_ARCHIVED;

        update srs;
        
        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );


        System.runAs(FACULTY_USER) {

            try {
                insert ipa;

                System.Assert.fail('Should be failed because of study requirement != active!');
            } catch (Exception exp) {
                String expectedErrMsg = String.format(
                    Label.Study_Requirement_Set_Used_Is_Inactive, new List<String> {
                        SRS_Helper.getObjectLabel(),
                        SCR_Helper.getObjectLabel(),
                        srs.Name
                    }
                );
                System.Assert.isTrue(exp.getMessage().contains(expectedErrMsg), 'Wrong exception message when Study Requirement != active! Actual: ' + exp.getMessage());
            }
            
        }


        Test.stopTest();
    }
	

    /**
     * @description Test as faculty for updating isd where irq is NOT inserted before
     */
    @IsTest
    static void testForUpdate_NoRequirementInserted_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        Set<String> triggersToMute = new Set<String> {'SOBJ_IndividualScoreGeneration_EXE'};
        REDU_TriggerController.muteTriggers(triggersToMute);

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        
        insert ipa;

        REDU_TriggerController.unmuteTriggers(triggersToMute);

        reduivy__Study_Scoring_Config__c scf = queryScf(SCF_SRC);

        //insert isc and isd
        reduivy__Individual_Score__c isc = new reduivy__Individual_Score__c(
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf.Id,
            reduivy__Status__c = ISC_Helper.STATUS_ACTIVE
        );

        
        REDU_TriggerController.muteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE'});
        
        insert isc;
        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE'});

        reduivy__Individual_Score_Detail__c isdToInsert = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = isc.Id,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
            reduivy__Weight__c = 100
        );

        insert isdToInsert;

        //update isd with study requirement
        reduivy__Study_Requirement_Set__c srs = querySrs();
        insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        System.runAs(FACULTY_USER) {
            isdToInsert.reduivy__Study_Requirement__c = srs.reduivy__Study_Requirements__r[0].Id;
            update isdToInsert;
        }

        List<reduivy__Individual_Requirement_Set__c> irsList = queryIrs();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement_Set__c irs : irsList) {
            expectedIrqMap.putAll(new Map<Id, reduivy__Individual_Requirement__c> (irs.reduivy__Individual_Requirements__r)); 
        }
        System.Assert.areEqual(1, expectedIrqMap.size(), 'Wrong inserted individual requirement size!');
        
        List<reduivy__Individual_Score__c> insertedIsc = queryIsc();

        System.Assert.areEqual(1, insertedIsc.size(), 'Wrong individual score size!');
        System.Assert.areEqual(1, insertedIsc[0].reduivy__Individual_Score_Details__r.size(), 'Wrong individual score detail size!');
        for(reduivy__Individual_Score_Detail__c isd : insertedIsc[0].reduivy__Individual_Score_Details__r) {
            reduivy__Individual_Requirement__c irq = expectedIrqMap.get(isd.reduivy__Individual_Requirement__c);
            System.Assert.areEqual(isd.reduivy__Study_Requirement__c, irq.reduivy__Study_Requirement__c, 'Wrong Individual Requirement created!');
            System.Assert.areEqual(irq.Id, isd.reduivy__Individual_Requirement__c, 'Individual Requirement should be the same as the one when ipa is created!');
            
        }
        
        Test.stopTest();
		
    }


    /**
     * @description Test as faculty for updating isd where irq is inserted before
     */
    @IsTest
    static void testForUpdate_RequirementInserted_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        Set<String> triggersToMute = new Set<String> {'SOBJ_IndividualScoreGeneration_EXE'};
        REDU_TriggerController.muteTriggers(triggersToMute);

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED
        );
        
        insert ipa;

        REDU_TriggerController.unmuteTriggers(triggersToMute);
        
        reduivy__Study_Requirement_Set__c srs = querySrs();
        reduivy__Individual_Requirement_Set__c insertIrs = new reduivy__Individual_Requirement_Set__c(
            reduivy__Study_Requirement_Set__c = srs.Id,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Status__c = IRS_Helper.STATUS_ACTIVE,
            reduivy__Requirement_Generation_Mode__c = IRS_Helper.REQUIREMENT_GENERATION_MODE_AUTO
        );
        insert insertIrs;

        insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(3, insertedIrsCount, 'Individual requirement set should be inserted!');
        System.Assert.areNotEqual(0, insertedIrqCount, 'Individual requirement should be inserted!');

        List<reduivy__Individual_Requirement_Set__c> irsList = queryIrs();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement_Set__c irs : irsList) {
            expectedIrqMap.putAll(new Map<Id, reduivy__Individual_Requirement__c> (irs.reduivy__Individual_Requirements__r)); 
        }
        

        reduivy__Study_Scoring_Config__c scf = queryScf(SCF_SRC);

        //insert isc and isd
        reduivy__Individual_Score__c isc = new reduivy__Individual_Score__c(
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf.Id,
            reduivy__Status__c = ISC_Helper.STATUS_ACTIVE
        );

        
        REDU_TriggerController.muteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE'});
        
        insert isc;
        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE'});

        reduivy__Individual_Score_Detail__c isdToInsert = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = isc.Id,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
            reduivy__Weight__c = 100
        );

        insert isdToInsert;

        //isd with irq linked should be 0
        Integer isdWithIrqLinked = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id AND reduivy__Individual_Requirement__c != null];
        System.Assert.areEqual(0, isdWithIrqLinked, 'Individual score detail with individual requirement linked should be 0!');

        //update isd with study requirement
        System.runAs(FACULTY_USER) {
            isdToInsert.reduivy__Study_Requirement__c = srs.reduivy__Study_Requirements__r[0].Id;
            update isdToInsert;
        }

        List<reduivy__Individual_Score__c> insertedIsc = queryIsc();

        System.Assert.areEqual(1, insertedIsc.size(), 'Wrong individual score size!');
        System.Assert.areEqual(1, insertedIsc[0].reduivy__Individual_Score_Details__r.size(), 'Wrong individual score detail size!');
        for(reduivy__Individual_Score_Detail__c isd : insertedIsc[0].reduivy__Individual_Score_Details__r) {
            reduivy__Individual_Requirement__c irq = expectedIrqMap.get(isd.reduivy__Individual_Requirement__c);
            System.Assert.areEqual(isd.reduivy__Study_Requirement__c, irq.reduivy__Study_Requirement__c, 'Wrong Individual Requirement created!');
            System.Assert.areEqual(irq.Id, isd.reduivy__Individual_Requirement__c, 'Individual Requirement should be the same as the one when ipa is created!');
            
        }
        
        Test.stopTest();
		
    }

    /**
     * @description Test as student for inserting isd where irq is NOT inserted before
     */
    @IsTest
    static void testForInsert_NoRequirementInserted_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        
		System.runAs(studentUser){
            insert ipa;
		}

        List<reduivy__Individual_Requirement_Set__c> irsList = queryIrs();
        Map<Id, reduivy__Individual_Requirement__c> irqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement_Set__c irs : irsList) {
            irqMap.putAll(new Map<Id, reduivy__Individual_Requirement__c> (irs.reduivy__Individual_Requirements__r)); 
        }
        
        List<reduivy__Individual_Score__c> insertedIsc = queryIsc();

        System.Assert.areEqual(1, insertedIsc.size(), 'Wrong individual score size!');
        System.Assert.areEqual(9, insertedIsc[0].reduivy__Individual_Score_Details__r.size(), 'Wrong individual score detail size!');
        for(reduivy__Individual_Score_Detail__c isd : insertedIsc[0].reduivy__Individual_Score_Details__r) {
            if(isd.reduivy__Study_Requirement__c != null) {
                reduivy__Individual_Requirement__c irq = irqMap.get(isd.reduivy__Individual_Requirement__c);
                System.Assert.areEqual(isd.reduivy__Study_Requirement__c, irq.reduivy__Study_Requirement__c, 'Wrong Individual Requirement created!');
            } else {
                System.Assert.isNull(isd.reduivy__Individual_Requirement__c, 'Individual Requirement should not be linked!');
            }
        }
        
        Test.stopTest();
		
    }
    
    /**
     * @description Test as student for inserting isd where irq is inserted before
     */
    @IsTest
    static void testForInsert_RequirementInserted_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        Set<String> triggersToMute = new Set<String> {'SOBJ_IndividualScoreGeneration_EXE'};
        REDU_TriggerController.muteTriggers(triggersToMute);

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED
        );
        
        insert ipa;

        REDU_TriggerController.unmuteTriggers(triggersToMute);

        //generate irs that its srs has the generation mode = manual
        reduivy__Study_Requirement_Set__c srs = querySrs();
        reduivy__Individual_Requirement_Set__c insertIrs = new reduivy__Individual_Requirement_Set__c(
            reduivy__Study_Requirement_Set__c = srs.Id,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Status__c = IRS_Helper.STATUS_ACTIVE,
            reduivy__Requirement_Generation_Mode__c = IRS_Helper.REQUIREMENT_GENERATION_MODE_AUTO
        );
        System.runAs(studentUser) {
            insert insertIrs;
        }

        List<reduivy__Individual_Requirement_Set__c> irsList = queryIrs();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement_Set__c irs : irsList) {
            expectedIrqMap.putAll(new Map<Id, reduivy__Individual_Requirement__c> (irs.reduivy__Individual_Requirements__r)); 
        }

        reduivy__Study_Scoring_Config__c scf = queryScf(SCF_SRC);

        //insert isc and isd
        reduivy__Individual_Score__c isc = new reduivy__Individual_Score__c(
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf.Id,
            reduivy__Status__c = ISC_Helper.STATUS_ACTIVE
        );

        
        System.runAs(studentUser) {
            insert isc;
        }
        
        List<reduivy__Individual_Score__c> insertedIsc = queryIsc();

        System.Assert.areEqual(1, insertedIsc.size(), 'Wrong individual score size!');
        System.Assert.areEqual(9, insertedIsc[0].reduivy__Individual_Score_Details__r.size(), 'Wrong individual score detail size!');
        for(reduivy__Individual_Score_Detail__c isd : insertedIsc[0].reduivy__Individual_Score_Details__r) {
            if(isd.reduivy__Study_Requirement__c != null) {
                reduivy__Individual_Requirement__c irq = expectedIrqMap.get(isd.reduivy__Individual_Requirement__c);
                System.Assert.areEqual(isd.reduivy__Study_Requirement__c, irq.reduivy__Study_Requirement__c, 'Wrong Individual Requirement created!');
                System.Assert.areEqual(irq.Id, isd.reduivy__Individual_Requirement__c, 'Individual Requirement should be the same as the one when ipa is created!');
            } else {
                System.Assert.isNull(isd.reduivy__Individual_Requirement__c, 'Individual Requirement should not be linked!');
            }
        }
        
        Test.stopTest();
		
    }

    
    @IsTest
    static void testForInsert_StudyRequirementInactive_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');


        reduivy__Study_Requirement__c srqCgpa = [SELECT Id, Name, reduivy__Status__c FROM reduivy__Study_Requirement__c WHERE reduivy__Sample_Record_Code__c = :SRC_SRQ_CGPA];
        srqCgpa.reduivy__Status__c = SRQ_Helper.STATUS_ARCHIVED;

        update srqCgpa;
        
        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );


        System.runAs(studentUser) {

            try {
                insert ipa;

                System.Assert.fail('Should be failed because of study requirement != active!');
            } catch (Exception exp) {
                String expectedErrMsg = String.format(
                    Label.Study_Requirement_Used_Is_Inactive, new List<String> {
                        SRQ_Helper.getObjectLabel(),
                        SCR_Helper.getObjectLabel(),
                        srqCgpa.Name
                    }
                );
                System.Assert.isTrue(exp.getMessage().contains(expectedErrMsg), 'Wrong exception message when Study Requirement != active! Actual: ' + exp.getMessage());
            }
            
        }


        Test.stopTest();
    }

    @IsTest
    static void testForInsert_StudyRequirementSetInactive_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');


        reduivy__Study_Requirement_Set__c srs = querySrs();
        srs.reduivy__Status__c = SRS_Helper.STATUS_ARCHIVED;

        update srs;
        
        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );


        System.runAs(studentUser) {

            try {
                insert ipa;

                System.Assert.fail('Should be failed because of study requirement != active!');
            } catch (Exception exp) {
                String expectedErrMsg = String.format(
                    Label.Study_Requirement_Set_Used_Is_Inactive, new List<String> {
                        SRS_Helper.getObjectLabel(),
                        SCR_Helper.getObjectLabel(),
                        srs.Name
                    }
                );
                System.Assert.isTrue(exp.getMessage().contains(expectedErrMsg), 'Wrong exception message when Study Requirement != active! Actual: ' + exp.getMessage());
            }
            
        }


        Test.stopTest();
    }
	

    /**
     * @description Test as student for updating isd where irq is NOT inserted before
     */
    @IsTest
    static void testForUpdate_NoRequirementInserted_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        Set<String> triggersToMute = new Set<String> {'SOBJ_IndividualScoreGeneration_EXE'};
        REDU_TriggerController.muteTriggers(triggersToMute);

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING
        );
        
        insert ipa;

        REDU_TriggerController.unmuteTriggers(triggersToMute);

        reduivy__Study_Scoring_Config__c scf = queryScf(SCF_SRC);

        //insert isc and isd
        reduivy__Individual_Score__c isc = new reduivy__Individual_Score__c(
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf.Id,
            reduivy__Status__c = ISC_Helper.STATUS_ACTIVE,
            reduivy__Contact__c = student.Id
        );

        
        REDU_TriggerController.muteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE'});
        
        insert isc;
        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE'});

        reduivy__Individual_Score_Detail__c isdToInsert = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = isc.Id,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
            reduivy__Weight__c = 100
        );

        insert isdToInsert;

        //update isd with study requirement
        reduivy__Study_Requirement_Set__c srs = querySrs();
        insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        isdToInsert.reduivy__Study_Requirement__c = srs.reduivy__Study_Requirements__r[0].Id;
        System.runAs(studentUser) {
            update isdToInsert;
        }

        List<reduivy__Individual_Requirement_Set__c> irsList = queryIrs();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement_Set__c irs : irsList) {
            expectedIrqMap.putAll(new Map<Id, reduivy__Individual_Requirement__c> (irs.reduivy__Individual_Requirements__r)); 
        }
        System.Assert.areEqual(1, expectedIrqMap.size(), 'Wrong inserted individual requirement size!');
        
        List<reduivy__Individual_Score__c> insertedIsc = queryIsc();

        System.Assert.areEqual(1, insertedIsc.size(), 'Wrong individual score size!');
        System.Assert.areEqual(1, insertedIsc[0].reduivy__Individual_Score_Details__r.size(), 'Wrong individual score detail size!');
        for(reduivy__Individual_Score_Detail__c isd : insertedIsc[0].reduivy__Individual_Score_Details__r) {
            reduivy__Individual_Requirement__c irq = expectedIrqMap.get(isd.reduivy__Individual_Requirement__c);
            System.Assert.areEqual(isd.reduivy__Study_Requirement__c, irq.reduivy__Study_Requirement__c, 'Wrong Individual Requirement created!');
            System.Assert.areEqual(irq.Id, isd.reduivy__Individual_Requirement__c, 'Individual Requirement should be the same as the one when ipa is created!');
            
        }
        
        Test.stopTest();
		
    }


    /**
     * @description Test as student for updating isd where irq is inserted before
     */
    @IsTest
    static void testForUpdate_RequirementInserted_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        Contact student = queryStudent();

        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIsdCount = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        Integer insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        System.Assert.areEqual(0, insertedIsdCount, 'Should be no individual score detail inserted!');
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');
        System.Assert.areEqual(0, insertedIrqCount, 'Should be no individual requirement inserted!');

        Set<String> triggersToMute = new Set<String> {'SOBJ_IndividualScoreGeneration_EXE'};
        REDU_TriggerController.muteTriggers(triggersToMute);

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = student.Id,
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED
        );
        
        insert ipa;

        REDU_TriggerController.unmuteTriggers(triggersToMute);
        
        reduivy__Study_Requirement_Set__c srs = querySrs();
        reduivy__Individual_Requirement_Set__c insertIrs = new reduivy__Individual_Requirement_Set__c(
            reduivy__Study_Requirement_Set__c = srs.Id,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Status__c = IRS_Helper.STATUS_ACTIVE,
            reduivy__Requirement_Generation_Mode__c = IRS_Helper.REQUIREMENT_GENERATION_MODE_AUTO
        );
        
		System.runAs(studentUser) {
            insert insertIrs;
        }
        insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        insertedIrqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];

        System.Assert.areEqual(3, insertedIrsCount, 'Individual requirement set should be inserted!');
        System.Assert.areNotEqual(0, insertedIrqCount, 'Individual requirement should be inserted!');

        List<reduivy__Individual_Requirement_Set__c> irsList = queryIrs();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement_Set__c irs : irsList) {
            expectedIrqMap.putAll(new Map<Id, reduivy__Individual_Requirement__c> (irs.reduivy__Individual_Requirements__r)); 
        }
        

        reduivy__Study_Scoring_Config__c scf = queryScf(SCF_SRC);

        //insert isc and isd
        reduivy__Individual_Score__c isc = new reduivy__Individual_Score__c(
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Study_Scoring_Config__c = scf.Id,
            reduivy__Status__c = ISC_Helper.STATUS_ACTIVE
        );

        
        REDU_TriggerController.muteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE'});
        
		System.runAs(studentUser){
            insert isc;
		}
        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE'});

        reduivy__Individual_Score_Detail__c isdToInsert = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = isc.Id,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
            reduivy__Weight__c = 100
        );

        insert isdToInsert;

        //isd with irq linked should be 0
        Integer isdWithIrqLinked = [SELECT COUNT() FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Individual_Score__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id AND reduivy__Individual_Requirement__c != null];
        System.Assert.areEqual(0, isdWithIrqLinked, 'Individual score detail with individual requirement linked should be 0!');

        //update isd with study requirement
        System.runAs(studentUser) {
            isdToInsert.reduivy__Study_Requirement__c = srs.reduivy__Study_Requirements__r[0].Id;
            update isdToInsert;
        }

        List<reduivy__Individual_Score__c> insertedIsc = queryIsc();

        System.Assert.areEqual(1, insertedIsc.size(), 'Wrong individual score size!');
        System.Assert.areEqual(1, insertedIsc[0].reduivy__Individual_Score_Details__r.size(), 'Wrong individual score detail size!');
        for(reduivy__Individual_Score_Detail__c isd : insertedIsc[0].reduivy__Individual_Score_Details__r) {
            reduivy__Individual_Requirement__c irq = expectedIrqMap.get(isd.reduivy__Individual_Requirement__c);
            System.Assert.areEqual(isd.reduivy__Study_Requirement__c, irq.reduivy__Study_Requirement__c, 'Wrong Individual Requirement created!');
            System.Assert.areEqual(irq.Id, isd.reduivy__Individual_Requirement__c, 'Individual Requirement should be the same as the one when ipa is created!');
            
        }
        
        Test.stopTest();
		
    }


    static Contact queryStudent(){
        return [SELECT Id, Name FROM Contact WHERE reduivy__Sample_Record_Code__c = :STUDENT_CON LIMIT 1];
    }
    
    static reduivy__Study_Requirement_Set__c querySrs() {
        return [
            SELECT Id, Name,
            (
                SELECT Id, Name
                FROM reduivy__Study_Requirements__r
            )
            FROM reduivy__Study_Requirement_Set__c
            WHERE reduivy__Sample_Record_Code__c = :SRS_SRC
            LIMIT 1
        ];
    }

    static List<reduivy__Individual_Score__c> queryIsc(){
        return [
            SELECT Id, Name,
            (
                SELECT Id, Name, reduivy__Study_Scoring_Criteria__c, reduivy__Parent_Score_Detail__r.reduivy__Study_Scoring_Criteria__c, reduivy__Study_Requirement__c, reduivy__Individual_Requirement__c
                FROM reduivy__Individual_Score_Details__r
            )
            FROM reduivy__Individual_Score__c
            WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c = :STUDENT_CON
        ];

    }
    
    static reduivy__Individual_Program_Application__c queryIpa() {
        return [
            SELECT Id, Name
            FROM reduivy__Individual_Program_Application__c
            WHERE reduivy__Sample_Record_Code__c = :STUDENT_CON
            LIMIT 1
        ];
    }

    static List<reduivy__Individual_Requirement_Set__c> queryIrs() {
        return [
            SELECT Id, Name,
            (SELECT Id, Name, reduivy__Study_Requirement__c FROM reduivy__Individual_Requirements__r)
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c = :STUDENT_CON
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

	
}