/**
 * @author      WDCi (XW)
 * @date        Aug 2025
 * @group       Test
 * @description Test class for SOBJ_IndividualScoreGeneration_EXE
 * @changehistory
 * ISS-002506 14-08-2025 XW - new class
 * 
 */
@IsTest
public inherited sharing class SOBJ_IndividualScoreGeneration_TEST {

    static final String STUDENT_CON = 'sandydoe@redu.example';
    static final String SCF_SRC = 'SCF_Application';
    static final String SRS_SRC = 'SRS_Application';

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
            testFactory.initStudentData(IPA_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for inserting ipa with criteria met
     */
    @IsTest
    static void testForInsert_CriteriaMet_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING,
            reduivy__Contact__c = student.Id
        );

		System.runAs(ADMIN_USER){
            insert ipa;
		}
        reduivy__Study_Scoring_Config__c scf = queryScf();

        Integer iscCount = 0;
        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'One Individual Score should be inserted!');

        //only required requirement should be generate
        Integer srqCount = [SELECT COUNT() FROM reduivy__Study_Requirement__c WHERE reduivy__Study_Requirement_Set__r.reduivy__Sample_Record_Code__c = :SRS_SRC];
        Integer irqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areNotEqual(srqCount, irqCount, 'Not all of the requirement should be generated!');
        

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for inserting ipa with criteria not met
     */
    @IsTest
    static void testForInsert_CriteriaNotMet_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED,
            reduivy__Contact__c = student.Id
        );

		System.runAs(ADMIN_USER){
            insert ipa;
		}
        reduivy__Study_Scoring_Config__c scf = queryScf();

        Integer iscCount = 0;
        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
            System.Assert.fail('No Individual Score should be created!');
        }
        
        System.Assert.areEqual(0, iscCount, 'No Individual Score should be created!');

        Test.stopTest();
		
    }

    
    /**
     * @description Test as admin for updating ipa from criteria not met to criteria met
     */
    @IsTest
    static void testForUpdate_CriteriaNotMetToMet_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_DRAFT,
            reduivy__Contact__c = student.Id
        );

		System.runAs(ADMIN_USER){
            insert ipa;
		}
        reduivy__Study_Scoring_Config__c scf = queryScf();

        Integer iscCount = 0;
        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
            System.Assert.fail('No Individual Score should be created!');
        }
        
        System.Assert.areEqual(0, iscCount, 'No Individual Score should be created!');

        //update
        ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;
		System.runAs(ADMIN_USER){
            update ipa;
		}

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'One Individual Score should be inserted!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for updating ipa to criteria met to not met
     */
    @IsTest
    static void testForUpdate_CriteriaMetToNotMet_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING,
            reduivy__Contact__c = student.Id
        );

		System.runAs(ADMIN_USER){
            insert ipa;
		}
        reduivy__Study_Scoring_Config__c scf = queryScf();

        Integer iscCount = 0;

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'One Individual Score should be inserted!');
        iscCount = 0;
        
        //update
        ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED;
		System.runAs(ADMIN_USER){
            update ipa;
		}
        
        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'Individual Score should not be reinserted again!');

        Test.stopTest();
		
    }

    //not referred fields updated
    @IsTest
    static void testForUpdate_CriteriaMetToMet_AsAdmin(){

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING,
            reduivy__Contact__c = student.Id
        );

		System.runAs(ADMIN_USER){
            insert ipa;
		}
        reduivy__Study_Scoring_Config__c scf = queryScf();

        Integer iscCount = 0;

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'One Individual Score should be inserted!');
        iscCount = 0;
        
        //update
        ipa.reduivy__Application_Date__c = System.today();
		System.runAs(ADMIN_USER){
            update ipa;
		}
        
        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'Individual Score should not be reinserted again!');

        Test.stopTest();
		
    }
    
    @IsTest
    static void testForUpdate_LinkExistingRequirement_AsAdmin(){

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        //create requirement first
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED,
            reduivy__Contact__c = student.Id
        );

		System.runAs(ADMIN_USER){
            insert ipa;
		}

        reduivy__Study_Scoring_Config__c scf = queryScf();

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
            System.Assert.fail('No Individual Score should be created!');
        }
        
        insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        //expecting 2 standard requirement set
        System.Assert.areEqual(2, insertedIrsCount, 'Individual requirement set should be inserted after updating ipa to submitted!');

        //update
        ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;
		System.runAs(ADMIN_USER){
            update ipa;
		}

        insertedIrsCount = 0;
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, (
                SELECT Id, Name, reduivy__Study_Requirement__c FROM reduivy__Individual_Requirements__r
            )
            FROM reduivy__Individual_Requirement_Set__c 
            WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id
        ]){
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedIrqMap.put(irq.reduivy__Study_Requirement__c, irq);
            }
            insertedIrsCount++;
        }

        //expecting 2 standard requirement set + 1 scoring requirement
        System.Assert.areEqual(3, insertedIrsCount, 'Additional requirement set should be created from application scoring.');
        System.Assert.isFalse(expectedIrqMap.isEmpty(), 'Individual Requirement map should not be empty!');

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                    
                if (String.isNotBlank(isd.reduivy__Study_Requirement__c)) {
                    System.Assert.areEqual(true, expectedIrqMap.containsKey(isd.reduivy__Study_Requirement__c), 'Not able to find the study requirement in the map: ' + isd.reduivy__Study_Requirement__c);
                    System.Assert.areEqual(expectedIrqMap.get(isd.reduivy__Study_Requirement__c).Id, isd.reduivy__Individual_Requirement__c, 'Individual Requirement should be the same as the created before!');
                }

                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            insertedIscCount++;
        }
        
        System.Assert.areEqual(1, insertedIscCount, 'One Individual Score should be inserted!');

        Test.stopTest();
		
    }
    
    @IsTest
    static void testForInsert_ParentRecordCriteria_AsAdmin(){

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //update the criteria
        reduivy__Study_Scoring_Config__c scf = queryScf();
        scf.reduivy__Criteria__c = 'AND(TEXT(reduivy__Application_Status__c) = "Reviewing", reduivy__Contact__r.FirstName = "Test"))';

        //make sure that no individual score are created
        Contact student = queryStudent();

        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        //update student name
        student.FirstName = 'Test';
        update student;
		
        insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING,
            reduivy__Contact__c = student.Id
        );

		System.runAs(ADMIN_USER){
            insert ipa;
		}
        Integer iscCount = 0;

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'One Individual Score should be inserted!');

        Test.stopTest();
		
    }

    

    /**
     * @description Test as faculty for inserting ipa with criteria met
     */
    @IsTest
    static void testForInsert_CriteriaMet_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING,
            reduivy__Contact__c = student.Id
        );

		System.runAs(FACULTY_USER){
            insert ipa;
		}
        reduivy__Study_Scoring_Config__c scf = queryScf();

        Integer iscCount = 0;
        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'One Individual Score should be inserted!');

        //only required requirement should be generate
        Integer srqCount = [SELECT COUNT() FROM reduivy__Study_Requirement__c WHERE reduivy__Study_Requirement_Set__r.reduivy__Sample_Record_Code__c = :SRS_SRC];
        Integer irqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areNotEqual(srqCount, irqCount, 'Not all of the requirement should be generated!');
        

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for inserting ipa with criteria not met
     */
    @IsTest
    static void testForInsert_CriteriaNotMet_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED,
            reduivy__Contact__c = student.Id
        );

		System.runAs(FACULTY_USER){
            insert ipa;
		}
        reduivy__Study_Scoring_Config__c scf = queryScf();

        Integer iscCount = 0;
        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
            System.Assert.fail('No Individual Score should be created!');
        }
        
        System.Assert.areEqual(0, iscCount, 'No Individual Score should be created!');

        Test.stopTest();
		
    }

    
    /**
     * @description Test as faculty for updating ipa from criteria not met to criteria met
     */
    @IsTest
    static void testForUpdate_CriteriaNotMetToMet_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_DRAFT,
            reduivy__Contact__c = student.Id
        );

		System.runAs(FACULTY_USER){
            insert ipa;
		}
        reduivy__Study_Scoring_Config__c scf = queryScf();

        Integer iscCount = 0;
        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
            System.Assert.fail('No Individual Score should be created!');
        }
        
        System.Assert.areEqual(0, iscCount, 'No Individual Score should be created!');

        //update
        ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;
		System.runAs(FACULTY_USER){
            update ipa;
		}

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'One Individual Score should be inserted!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for updating ipa to criteria met to not met
     */
    @IsTest
    static void testForUpdate_CriteriaMetToNotMet_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING,
            reduivy__Contact__c = student.Id
        );

		System.runAs(FACULTY_USER){
            insert ipa;
		}
        reduivy__Study_Scoring_Config__c scf = queryScf();

        Integer iscCount = 0;

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'One Individual Score should be inserted!');
        iscCount = 0;
        
        //update
        ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED;
		System.runAs(FACULTY_USER){
            update ipa;
		}
        
        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'Individual Score should not be reinserted again!');

        Test.stopTest();
		
    }

    //not referred fields updated
    @IsTest
    static void testForUpdate_CriteriaMetToMet_AsFaculty(){

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING,
            reduivy__Contact__c = student.Id
        );

		System.runAs(FACULTY_USER){
            insert ipa;
		}
        reduivy__Study_Scoring_Config__c scf = queryScf();

        Integer iscCount = 0;

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'One Individual Score should be inserted!');
        iscCount = 0;
        
        //update
        ipa.reduivy__Application_Date__c = System.today();
		System.runAs(FACULTY_USER){
            update ipa;
		}
        
        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'Individual Score should not be reinserted again!');

        Test.stopTest();
		
    }
    
    @IsTest
    static void testForUpdate_LinkExistingRequirement_AsFaculty(){

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        //create requirement first
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED,
            reduivy__Contact__c = student.Id
        );

		System.runAs(FACULTY_USER){
            insert ipa;
		}

        reduivy__Study_Scoring_Config__c scf = queryScf();

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
            System.Assert.fail('No Individual Score should be created!');
        }
        
        insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        //expecting 2 standard requirement set
        System.Assert.areEqual(2, insertedIrsCount, 'Individual requirement set should be inserted after updating ipa to submitted!');

        //update
        ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;
		System.runAs(FACULTY_USER){
            update ipa;
		}

        insertedIrsCount = 0;
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, (
                SELECT Id, Name, reduivy__Study_Requirement__c FROM reduivy__Individual_Requirements__r
            )
            FROM reduivy__Individual_Requirement_Set__c 
            WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id
        ]){
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedIrqMap.put(irq.reduivy__Study_Requirement__c, irq);
            }
            insertedIrsCount++;
        }

        //expecting 2 standard requirement set + 1 scoring requirement
        System.Assert.areEqual(3, insertedIrsCount, 'Additional requirement set should be created from application scoring.');
        System.Assert.isFalse(expectedIrqMap.isEmpty(), 'Individual Requirement map should not be empty!');

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                    
                if (String.isNotBlank(isd.reduivy__Study_Requirement__c)) {
                    System.Assert.areEqual(true, expectedIrqMap.containsKey(isd.reduivy__Study_Requirement__c), 'Not able to find the study requirement in the map: ' + isd.reduivy__Study_Requirement__c);
                    System.Assert.areEqual(expectedIrqMap.get(isd.reduivy__Study_Requirement__c).Id, isd.reduivy__Individual_Requirement__c, 'Individual Requirement should be the same as the created before!');
                }

                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            insertedIscCount++;
        }
        
        System.Assert.areEqual(1, insertedIscCount, 'One Individual Score should be inserted!');

        Test.stopTest();
		
    }
    
    @IsTest
    static void testForInsert_ParentRecordCriteria_AsFaculty(){

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //update the criteria
        reduivy__Study_Scoring_Config__c scf = queryScf();
        scf.reduivy__Criteria__c = 'AND(TEXT(reduivy__Application_Status__c) = "Reviewing", reduivy__Contact__r.FirstName = "Test"))';

        //make sure that no individual score are created
        Contact student = queryStudent();

        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        //update student name
        student.FirstName = 'Test';
        update student;
		
        insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING,
            reduivy__Contact__c = student.Id
        );

		System.runAs(FACULTY_USER){
            insert ipa;
		}
        Integer iscCount = 0;

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'One Individual Score should be inserted!');

        Test.stopTest();
		
    }

    

    /**
     * @description Test as student for inserting ipa with criteria met
     */
    @IsTest
    static void testForInsert_CriteriaMet_AsStudent() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING,
            reduivy__Contact__c = student.Id
        );

		System.runAs(studentUser){
            insert ipa;
		}
        reduivy__Study_Scoring_Config__c scf = queryScf();

        Integer iscCount = 0;
        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'One Individual Score should be inserted!');

        //only required requirement should be generate
        Integer srqCount = [SELECT COUNT() FROM reduivy__Study_Requirement__c WHERE reduivy__Study_Requirement_Set__r.reduivy__Sample_Record_Code__c = :SRS_SRC];
        Integer irqCount = [SELECT COUNT() FROM reduivy__Individual_Requirement__c WHERE reduivy__Individual_Requirement_Set__r.reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areNotEqual(srqCount, irqCount, 'Not all of the requirement should be generated!');
        

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for inserting ipa with criteria not met
     */
    @IsTest
    static void testForInsert_CriteriaNotMet_AsStudent() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED,
            reduivy__Contact__c = student.Id
        );

		System.runAs(studentUser){
            insert ipa;
		}
        reduivy__Study_Scoring_Config__c scf = queryScf();

        Integer iscCount = 0;
        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
            System.Assert.fail('No Individual Score should be created!');
        }
        
        System.Assert.areEqual(0, iscCount, 'No Individual Score should be created!');

        Test.stopTest();
		
    }

    
    /**
     * @description Test as student for updating ipa from criteria not met to criteria met
     */
    @IsTest
    static void testForUpdate_CriteriaNotMetToMet_AsStudent() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_DRAFT,
            reduivy__Contact__c = student.Id
        );

		System.runAs(studentUser){
            insert ipa;
		}
        reduivy__Study_Scoring_Config__c scf = queryScf();

        Integer iscCount = 0;
        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
            System.Assert.fail('No Individual Score should be created!');
        }
        
        System.Assert.areEqual(0, iscCount, 'No Individual Score should be created!');

        //update
        ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;
		System.runAs(studentUser){
            update ipa;
		}

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'One Individual Score should be inserted!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for updating ipa to criteria met to not met
     */
    @IsTest
    static void testForUpdate_CriteriaMetToNotMet_AsStudent() {

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING,
            reduivy__Contact__c = student.Id
        );

		System.runAs(studentUser){
            insert ipa;
		}
        reduivy__Study_Scoring_Config__c scf = queryScf();

        Integer iscCount = 0;

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'One Individual Score should be inserted!');
        iscCount = 0;
        
        //update
        ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED;
		System.runAs(studentUser){
            update ipa;
		}
        
        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'Individual Score should not be reinserted again!');

        Test.stopTest();
		
    }

    //not referred fields updated
    @IsTest
    static void testForUpdate_CriteriaMetToMet_AsStudent(){

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING,
            reduivy__Contact__c = student.Id
        );

		System.runAs(studentUser){
            insert ipa;
		}
        reduivy__Study_Scoring_Config__c scf = queryScf();

        Integer iscCount = 0;

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'One Individual Score should be inserted!');
        iscCount = 0;
        
        //update
        ipa.reduivy__Application_Date__c = System.today();
		System.runAs(studentUser){
            update ipa;
		}
        
        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'Individual Score should not be reinserted again!');

        Test.stopTest();
		
    }
    
    @IsTest
    static void testForUpdate_LinkExistingRequirement_AsStudent(){

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }
        //create requirement first
        
        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();

        //make sure that no individual score are created
        Contact student = queryStudent();
        
        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');
        Integer insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIrsCount, 'Should be no individual requirement set inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED,
            reduivy__Contact__c = student.Id
        );

		System.runAs(studentUser){
            insert ipa;
		}

        reduivy__Study_Scoring_Config__c scf = queryScf();

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
            System.Assert.fail('No Individual Score should be created!');
        }
        
        insertedIrsCount = [SELECT COUNT() FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        //expecting 2 standard requirement set
        System.Assert.areEqual(2, insertedIrsCount, 'Individual requirement set should be inserted after updating ipa to submitted!');

        //update
        ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;
		System.runAs(studentUser){
            update ipa;
		}

        insertedIrsCount = 0;
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, (
                SELECT Id, Name, reduivy__Study_Requirement__c FROM reduivy__Individual_Requirements__r
            )
            FROM reduivy__Individual_Requirement_Set__c 
            WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id
        ]){
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedIrqMap.put(irq.reduivy__Study_Requirement__c, irq);
            }
            insertedIrsCount++;
        }

        //expecting 2 standard requirement set + 1 scoring requirement
        System.Assert.areEqual(3, insertedIrsCount, 'Additional requirement set should be created from application scoring.');
        System.Assert.isFalse(expectedIrqMap.isEmpty(), 'Individual Requirement map should not be empty!');

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                    
                if (String.isNotBlank(isd.reduivy__Study_Requirement__c)) {
                    System.Assert.areEqual(true, expectedIrqMap.containsKey(isd.reduivy__Study_Requirement__c), 'Not able to find the study requirement in the map: ' + isd.reduivy__Study_Requirement__c);
                    System.Assert.areEqual(expectedIrqMap.get(isd.reduivy__Study_Requirement__c).Id, isd.reduivy__Individual_Requirement__c, 'Individual Requirement should be the same as the created before!');
                }

                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            insertedIscCount++;
        }
        
        System.Assert.areEqual(1, insertedIscCount, 'One Individual Score should be inserted!');

        Test.stopTest();
		
    }
    
    @IsTest
    static void testForInsert_ParentRecordCriteria_AsStudent(){

        if(!IPA_Helper.canRunEvaluationTest()) {
            return;
        }

        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();

        //update the criteria
        reduivy__Study_Scoring_Config__c scf = queryScf();
        scf.reduivy__Criteria__c = 'AND(TEXT(reduivy__Application_Status__c) = "Reviewing", reduivy__Contact__r.FirstName = "Test"))';

        //make sure that no individual score are created
        Contact student = queryStudent();

        Integer insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        //update student name
        student.FirstName = 'Test';
        update student;
		
        insertedIscCount = [SELECT COUNT() FROM reduivy__Individual_Score__c WHERE reduivy__Individual_Program_Application__r.reduivy__Contact__c = :student.Id];
        System.Assert.areEqual(0, insertedIscCount, 'Should be no individual score inserted!');

        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING,
            reduivy__Contact__c = student.Id
        );

		System.runAs(studentUser){
            insert ipa;
		}
        Integer iscCount = 0;

        for(reduivy__Individual_Score__c isc : queryIsc(ipa.Id)) {
                
            System.Assert.areEqual(scf.Name, isc.Name, 'Wrong Individual Score Name cloned!');
            System.Assert.areEqual(scf.Id, isc.reduivy__Study_Scoring_Config__c, 'Wrong parent Study Scoring Config cloned!');
            System.Assert.areEqual(student.Id, isc.reduivy__Contact__c, 'Wrong contact assigned in isc!');
            
            System.Assert.areEqual(scf.reduivy__Study_Scoring_Criteria__r.size(), isc.reduivy__Individual_Score_Details__r.size(), 'Wrong score details count!');
            Integer index = 0;
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                reduivy__Study_Scoring_Criteria__c scr = scf.reduivy__Study_Scoring_Criteria__r[index];
                
                System.Assert.areEqual(scr.Name, isd.Name, 'Wrong individual score detail cloned!');
                System.Assert.areEqual(scr.Id, isd.reduivy__Study_Scoring_Criteria__c, 'Wrong parent Study Scoring Criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Parent_Criteria__c, isd.reduivy__Parent_Score_Detail__r?.reduivy__Study_Scoring_Criteria__c, ' Wrong parent criteria cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Study_Requirement__c, ' Wrong Study Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Study_Requirement__c, isd.reduivy__Individual_Requirement__r?.reduivy__Study_Requirement__c, ' Wrong Study Requirement for the Individual Requirement cloned!');
                System.Assert.areEqual(scr.reduivy__Sequence__c, isd.reduivy__Sequence__c, 'Wrong Sequence cloned!');

                System.Assert.areEqual(scr.reduivy__Score_Logic__c, isd.reduivy__Score_Logic__c, 'Wrong Score Logic cloned!');
                System.Assert.areEqual(scr.reduivy__Weight__c, isd.reduivy__Weight__c, 'Wrong Weight cloned!');
                System.Assert.areEqual(scr.reduivy__Max_Score__c, isd.reduivy__Max_Score__c, 'Wrong Max Score cloned!');
                
                index++;
            }

            iscCount++;
        }
        
        System.Assert.areEqual(1, iscCount, 'One Individual Score should be inserted!');

        Test.stopTest();
		
    }



    static Contact queryStudent(){
        return [SELECT Id, Name FROM Contact WHERE reduivy__Sample_Record_Code__c = :STUDENT_CON LIMIT 1];
    }

    static List<reduivy__Individual_Score__c> queryIsc(Id ipaId) {
        return [
            SELECT Id, Name, reduivy__Study_Scoring_Config__c, reduivy__Contact__c, (
                SELECT Id, Name, reduivy__Study_Scoring_Criteria__c, reduivy__Parent_Score_Detail__c, reduivy__Parent_Score_Detail__r.reduivy__Study_Scoring_Criteria__c, reduivy__Study_Requirement__c, reduivy__Individual_Requirement__r.reduivy__Study_Requirement__c, reduivy__Sequence__c,
                reduivy__Score_Logic__c, reduivy__Weight__c, reduivy__Score__c, reduivy__Max_Score__c, reduivy__Weighted_Score__c
                FROM reduivy__Individual_Score_Details__r
                ORDER BY Name ASC, Id ASC
            )
            FROM reduivy__Individual_Score__c 
            WHERE reduivy__Individual_Program_Application__c = :ipaId
        ];
    }
    static reduivy__Study_Scoring_Config__c queryScf() {
        return [
            SELECT Id, Name, reduivy__Contact_Field__c, (
                SELECT Id, Name, reduivy__Parent_Criteria__c, reduivy__Study_Requirement__c, reduivy__Sequence__c,
                reduivy__Score_Logic__c, reduivy__Weight__c, reduivy__Max_Score__c
                FROM reduivy__Study_Scoring_Criteria__r
                ORDER BY Name ASC, Id ASC
            )
            FROM reduivy__Study_Scoring_Config__c
            WHERE reduivy__Sample_Record_Code__c = :SCF_SRC
            LIMIT 1
        ];
    }
}