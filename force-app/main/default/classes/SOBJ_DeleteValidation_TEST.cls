/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for SOBJ_DeleteValidation_EXE
 * @changehistory
 * 
 */
@isTest
public inherited sharing class SOBJ_DeleteValidation_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
	
    static final String STUDY_PLAN_STRUCTURE_UNIT = 'BACBIS_MajorA_BUS201';
    static final String PRE_REQUIREMENT_ID = 'BUS102';
	static final String STUDY_PLAN_STRUCTURE_GROUP_PARENT = 'BACBIS_MajorA_GROUPA';
	static final string CANNOT_DELETE_CHILD_ERROR = 'This record can\'t be deleted because it has one or more related records';

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

            testFactory.initMasterData(null);

			Test.stopTest();
        }
    }
	
	/**
     * @description Test SOBJ_DeleteValidation_EXE
     */
    @IsTest
    static void testDeletionOfParent(){

        Boolean hasError = false;

        // Get the study plan structure unit records
		Map<String, reduivy__Study_Plan_Structure__c> spsuMap = new Map<String, reduivy__Study_Plan_Structure__c>();
		List<reduivy__Study_Plan_Structure__c> spsuList = [
			SELECT Id, reduivy__Sample_Record_Code__c, reduivy__Study_Unit__c
			FROM reduivy__Study_Plan_Structure__c 
			WHERE RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
			AND reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_UNIT
		];
		System.Assert.isFalse(
			spsuList.isEmpty(),
			'There should be a list of study plan structure unit records'
		);
		for (reduivy__Study_Plan_Structure__c spsu : spsuList) {
			spsuMap.put(spsu.reduivy__Sample_Record_Code__c, spsu);
		}

		// Create study plan structure unit requirement records
		List<reduivy__Study_Plan_Unit_Requirement__c> sprList = new List<reduivy__Study_Plan_Unit_Requirement__c>();
		for(String spsu : spsuMap.keySet()){

			String sampleRecordCode = spsuMap.get(spsu).reduivy__Sample_Record_Code__c + PRE_REQUIREMENT_ID;
			Id studyPlanUnitId = spsuMap.get(spsu).Id;
			String reqID = PRE_REQUIREMENT_ID;
			Decimal credits = 7.0;

			reduivy__Study_Plan_Unit_Requirement__c spr = REDU_TestData_UTIL.newCreditsStudyPlanUnitRequirement(
				sampleRecordCode,
				studyPlanUnitId,
				reqID,
				credits
			);
			
			sprList.add(spr);
		}

        insert sprList;

		Test.startTest();

		try {
			delete spsuMap.values();
			System.Assert.fail('This should fail with cannot delete child error.');
		} catch (Exception exp) {
			System.Assert.isTrue(
				exp.getMessage().contains(CANNOT_DELETE_CHILD_ERROR),
				'User should not be able to delete the parent record.'
			);
		}

		Test.stopTest();

    }

	/**
     * @description Test SOBJ_DeleteValidation_EXE
     */
    @IsTest
    static void testDeletionOfParentChildSameObject(){

        Boolean hasError = false;

        // Get the study plan structure group parent records
		List<reduivy__Study_Plan_Structure__c> spsgParentList = [
			SELECT Id, (SELECT Id FROM reduivy__Study_Plan_Structures__r)
			FROM reduivy__Study_Plan_Structure__c 
			WHERE RecordTypeId = :SPS_Helper.getGroupRecordTypeId()
			AND reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP_PARENT
		];
		System.Assert.isFalse(
			spsgParentList.isEmpty(),
			'There should be a list of study plan structure group records'
		);

		for (reduivy__Study_Plan_Structure__c spsgParent : spsgParentList) {
			System.Assert.isFalse(
				spsgParent.reduivy__Study_Plan_Structures__r.isEmpty(),
				'There should be a list of study plan structure child records'
			);
		}

		Test.startTest();

		try {
			delete spsgParentList;
			System.Assert.fail('This should fail with cannot delete child error.');
		} catch (Exception exp) {
			System.Assert.isTrue(
				exp.getMessage().contains(CANNOT_DELETE_CHILD_ERROR),
				'User should not be able to delete the parent record.'
			);
		}

		Test.stopTest();

    }
}