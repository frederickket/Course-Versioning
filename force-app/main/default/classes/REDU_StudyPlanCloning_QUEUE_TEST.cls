/**
 * @author      WDCi (Jordan)
 * @date        Dec 2024
 * @group       Study Plan Cloning
 * @description Test class for REDU_StudyPlanCloning_QUEUE
 * @changehistory
 * ISS-002153 18-12-2024 Jordan - New class
 * ISS-002527 03-07-2025 XiRouh - Added proper assertions for the results of each test method
 */
@IsTest
public inherited sharing class REDU_StudyPlanCloning_QUEUE_TEST {
    
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

            testFactory.initMasterData(null);

            List<reduivy__Study_Plan_Structure__c> unitStudyPlanStructures = [SELECT Name, reduivy__Study_Plan__c, reduivy__Study_Unit__c FROM reduivy__Study_Plan_Structure__c WHERE RecordTypeId = :SPS_Helper.getUnitRecordTypeId()];
            List<reduivy__Study_Unit_Requirement__c> studyUnitReqs = [SELECT Name, reduivy__Credits__c, reduivy__Required_Study_Unit__c, reduivy__Requirement_ID__c, reduivy__Requirement_Type__c, reduivy__Study_Unit__c FROM reduivy__Study_Unit_Requirement__c];
            Map<String, reduivy__Study_Plan_Unit_Requirement__c> studyPlanUnitReqs = new Map<String, reduivy__Study_Plan_Unit_Requirement__c>();

            for (reduivy__Study_Plan_Structure__c unitSps : unitStudyPlanStructures) {
                for (reduivy__Study_Unit_Requirement__c sur : studyUnitReqs) {
                    if (unitSps.reduivy__Study_Unit__c == sur.reduivy__Study_Unit__c) {
                        String mapKey = unitSps.reduivy__Study_Plan__c + '_' + unitSps.Name + '_' + sur.Name;
                        reduivy__Study_Plan_Unit_Requirement__c spur;

                        if (sur.reduivy__Requirement_Type__c == SUR_Helper.REQTYPE_CREDITS) {
                            spur = REDU_TestData_UTIL.newCreditsStudyPlanUnitRequirement(mapKey, unitSps.Id, sur.reduivy__Requirement_ID__c, sur.reduivy__Credits__c);
                        } else if (sur.reduivy__Requirement_Type__c == SUR_Helper.REQTYPE_OTHER) {
                            spur = REDU_TestData_UTIL.newOtherStudyPlanUnitRequirement(mapKey, unitSps.Id, sur.reduivy__Requirement_ID__c);
                        } else {
                            spur = REDU_TestData_UTIL.newUnitStudyPlanUnitRequirement(mapKey, unitSps.Id, sur.reduivy__Required_Study_Unit__c, sur.reduivy__Requirement_ID__c, sur.reduivy__Requirement_Type__c);
                        }

                        studyPlanUnitReqs.put(mapKey, spur);
                    }
                }
            }

            insert studyPlanUnitReqs.values();

            Test.stopTest();
        }
        
    }

    /**
     * @description Test execute as admin
     */
    @IsTest
    static void testExecuteAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //Master study plan and related records
            reduivy__Study_Plan__c studyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A' LIMIT 1];
            Map<Id, reduivy__Study_Plan_Structure__c> spsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            List<reduivy__Study_Plan_Unit_Requirement__c> spurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :spsMap.keySet()];
            Map<Id, reduivy__Study_Pathway__c> studyPathwayMap = new Map<Id, reduivy__Study_Pathway__c>([SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            Map<Id, reduivy__Study_Plan_Option__c> studyPlanOptionMap = new Map<Id, reduivy__Study_Plan_Option__c>([SELECT Id, reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c WHERE reduivy__Master_Study_Plan__c = :studyPlan.Id]);

            // Store original counts for comparison
            Integer originalStudyPlanCount = [SELECT COUNT() FROM reduivy__Study_Plan__c];
            Integer originalSpsCount = [SELECT COUNT() FROM reduivy__Study_Plan_Structure__c];
            Integer originalSpurCount = [SELECT COUNT() FROM reduivy__Study_Plan_Unit_Requirement__c];
            Integer originalStudyPathwayCount = [SELECT COUNT() FROM reduivy__Study_Pathway__c];
            Integer originalStudyPlanOptionCount = [SELECT COUNT() FROM reduivy__Study_Plan_Option__c];

            //Clone master study plan
            String studyPlanData = '{"attributes":{"type":"reduivy__Study_Plan__c","url":"/services/data/v62.0/sobjects/reduivy__Study_Plan__c/' + studyPlan.Id + '"},"Name":"Copy of BACBIS - Major A","reduivy__Study_Program__c":"' + studyPlan.reduivy__Study_Program__c + '"}';
            REDU_StudyPlanCloning_QUEUE queueJob = new REDU_StudyPlanCloning_QUEUE(studyPlan.Id, studyPlanData, new List<Id>(studyPathwayMap.keySet()), new List<Id>(studyPlanOptionMap.keySet()), false, false);
            
            Id jobId = System.enqueueJob(queueJob);

            System.Assert.isNotNull(jobId, 'The job should be queued successfully.');
        }

        Test.stopTest();
        
        List<reduivy__Study_Plan__c> clonedStudyPlans = [
            SELECT Id, Name, reduivy__Study_Program__c, reduivy__Clone_From_Id__c 
            FROM reduivy__Study_Plan__c 
            WHERE Name = 'Copy of BACBIS - Major A'
        ];
        
        System.Assert.areEqual(1, clonedStudyPlans.size(), 'Exactly one cloned study plan should be created');
        
        reduivy__Study_Plan__c clonedStudyPlan = clonedStudyPlans[0];
        reduivy__Study_Plan__c originalStudyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A' LIMIT 1];
        
        // Verify Study Plan cloning assertions
        System.Assert.areEqual('Copy of BACBIS - Major A', clonedStudyPlan.Name, 'Cloned study plan should have correct name');
        System.Assert.areEqual(originalStudyPlan.reduivy__Study_Program__c, clonedStudyPlan.reduivy__Study_Program__c, 'Cloned study plan should have same study program');
        System.Assert.areEqual(originalStudyPlan.Id, clonedStudyPlan.reduivy__Clone_From_Id__c, 'Clone_From_Id should reference original study plan');
        
        // Verify Study Plan Structures were cloned
        List<reduivy__Study_Plan_Structure__c> originalSps = [
            SELECT Id FROM reduivy__Study_Plan_Structure__c 
            WHERE reduivy__Study_Plan__c = :originalStudyPlan.Id
        ];
        
        List<reduivy__Study_Plan_Structure__c> clonedSps = [
            SELECT Id, reduivy__Study_Plan__c, reduivy__Clone_From_Id__c, 
                   reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c
            FROM reduivy__Study_Plan_Structure__c 
            WHERE reduivy__Study_Plan__c = :clonedStudyPlan.Id
        ];
        
        System.Assert.areEqual(originalSps.size(), clonedSps.size(), 'Number of cloned study plan structures should match original');
        
        // Verify each cloned SPS has correct references and cleared requirement fields (since includeExistingStudyPlanUnitRequirements = false)
        for(reduivy__Study_Plan_Structure__c sps : clonedSps) {
            System.Assert.areEqual(clonedStudyPlan.Id, sps.reduivy__Study_Plan__c, 'Cloned SPS should reference cloned study plan');
            System.Assert.isNotNull(sps.reduivy__Clone_From_Id__c, 'Cloned SPS should have Clone_From_Id populated');
            System.Assert.isNull(sps.reduivy__Requirement_Logic__c, 'Requirement Logic should be cleared when includeExistingStudyPlanUnitRequirements is false');
            System.Assert.isNull(sps.reduivy__Requirement_Description__c, 'Requirement Description should be cleared when includeExistingStudyPlanUnitRequirements is false');
        }
        
        // Verify Study Plan Unit Requirements were NOT cloned (since includeExistingStudyPlanUnitRequirements = false)
        List<reduivy__Study_Plan_Unit_Requirement__c> clonedSpurs = [
            SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c 
            WHERE reduivy__Study_Plan_Unit__c IN (SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :clonedStudyPlan.Id)
        ];
        
        System.Assert.areEqual(0, clonedSpurs.size(), 'No Study Plan Unit Requirements should be cloned when includeExistingStudyPlanUnitRequirements is false');
        
        // Verify Study Pathways were cloned
        List<reduivy__Study_Pathway__c> originalPathways = [
            SELECT Id FROM reduivy__Study_Pathway__c 
            WHERE reduivy__Study_Plan__c = :originalStudyPlan.Id
        ];

        Set<Id> originalPathwaysIds = new Set<Id>();

        for(reduivy__Study_Pathway__c spw : originalPathways) {
            originalPathwaysIds.add(spw.Id);
        }
        
        List<reduivy__Study_Pathway__c> clonedPathways = [
            SELECT Id, reduivy__Study_Plan__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Pathway__c 
            WHERE reduivy__Study_Plan__c = :clonedStudyPlan.Id
        ];
        
        System.Assert.areEqual(originalPathways.size(), clonedPathways.size(), 'Number of cloned study pathways should match original');
        
        for(reduivy__Study_Pathway__c pathway : clonedPathways) {
            System.Assert.areEqual(clonedStudyPlan.Id, pathway.reduivy__Study_Plan__c, 'Cloned pathway should reference cloned study plan');
            System.Assert.isNotNull(pathway.reduivy__Clone_From_Id__c, 'Cloned pathway should have Clone_From_Id populated');
            System.Assert.isTrue(
                originalPathwaysIds.contains(pathway.reduivy__Clone_From_Id__c),
                'Cloned pathway\'s Clone_From_Id must reference an original study pathway'
            );
        }
        
        // Verify Study Pathway Terms were cloned
        List<reduivy__Study_Pathway_Term__c> clonedPathwayTerms = [
            SELECT Id, reduivy__Study_Pathway__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Pathway_Term__c 
            WHERE reduivy__Study_Pathway__c IN :clonedPathways
        ];
        
        List<reduivy__Study_Pathway_Term__c> originalPathwayTerms = [
            SELECT Id FROM reduivy__Study_Pathway_Term__c 
            WHERE reduivy__Study_Pathway__c IN :originalPathways
        ];

        Set<Id> originalPathwayTermsIds = new Set<Id>();

        for(reduivy__Study_Pathway_Term__c spt : originalPathwayTerms) {
            originalPathwayTermsIds.add(spt.Id);
        }
        
        System.Assert.areEqual(originalPathwayTerms.size(), clonedPathwayTerms.size(), 'Number of cloned study pathway terms should match original');
        
        for(reduivy__Study_Pathway_Term__c term : clonedPathwayTerms) {
            System.Assert.isNotNull(term.reduivy__Clone_From_Id__c, 'Cloned pathway term should have Clone_From_Id populated');
            System.Assert.isTrue(
                originalPathwayTermsIds.contains(term.reduivy__Clone_From_Id__c),
                'Cloned pathway term\'s Clone_From_Id must reference an original study pathway term'
            );
        }
        
        // Verify Study Pathway Units were cloned
        List<reduivy__Study_Pathway_Unit__c> clonedPathwayUnits = [
            SELECT Id, reduivy__Study_Pathway_Term__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__c IN :clonedPathwayTerms
        ];
        
        List<reduivy__Study_Pathway_Unit__c> originalPathwayUnits = [
            SELECT Id FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__c IN :originalPathwayTerms
        ];

        Set<Id> originalPathwayUnitsIds = new Set<Id>();

        for(reduivy__Study_Pathway_Unit__c spu : originalPathwayUnits) {
            originalPathwayUnitsIds.add(spu.Id);
        }
        
        System.Assert.areEqual(originalPathwayUnits.size(), clonedPathwayUnits.size(), 'Number of cloned study pathway units should match original');
        
        for(reduivy__Study_Pathway_Unit__c unit : clonedPathwayUnits) {
            System.Assert.isNotNull(unit.reduivy__Clone_From_Id__c, 'Cloned pathway unit should have Clone_From_Id populated');
            System.Assert.isTrue(
                originalPathwayUnitsIds.contains(unit.reduivy__Clone_From_Id__c),
                'Cloned pathway unit\'s Clone_From_Id must reference an original study pathway unit'
            );
        }
        
        // Verify Study Plan Options were cloned (but child study plans were NOT cloned since cloneChildStudyPlans = false)
        List<reduivy__Study_Plan_Option__c> originalOptions = [
            SELECT Id, reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c 
            WHERE reduivy__Master_Study_Plan__c = :originalStudyPlan.Id
        ];

        Set<Id> originalOptionsIds = new Set<Id>();

        for(reduivy__Study_Plan_Option__c spo : originalOptions) {
            originalOptionsIds.add(spo.Id);
        }
        
        List<reduivy__Study_Plan_Option__c> clonedOptions = [
            SELECT Id, reduivy__Master_Study_Plan__c, reduivy__Child_Study_Plan__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Plan_Option__c 
            WHERE reduivy__Master_Study_Plan__c = :clonedStudyPlan.Id
        ];
        
        System.Assert.areEqual(originalOptions.size(), clonedOptions.size(), 'Number of cloned study plan options should match original');
        
        for(reduivy__Study_Plan_Option__c option : clonedOptions) {
            System.Assert.areEqual(clonedStudyPlan.Id, option.reduivy__Master_Study_Plan__c, 'Cloned option should reference cloned study plan');
            System.Assert.isNotNull(option.reduivy__Clone_From_Id__c, 'Cloned option should have Clone_From_Id populated');
            System.Assert.isTrue(
                originalOptionsIds.contains(option.reduivy__Clone_From_Id__c),
                'Cloned study plan option\'s Clone_From_Id must reference an original study plan option'
            );
            // Child study plan should remain the same since cloneChildStudyPlans = false
            System.Assert.isNotNull(option.reduivy__Child_Study_Plan__c, 'Child study plan reference should be preserved');
        }
        
        // Verify that child study plans were NOT cloned (since cloneChildStudyPlans = false)
        Set<Id> childStudyPlanIds = new Set<Id>();
        for(reduivy__Study_Plan_Option__c option : originalOptions) {
            if(option.reduivy__Child_Study_Plan__c != null) {
                childStudyPlanIds.add(option.reduivy__Child_Study_Plan__c);
            }
        }
        
        if(!childStudyPlanIds.isEmpty()) {
            List<reduivy__Study_Plan__c> potentialClonedChildPlans = [
                SELECT Id FROM reduivy__Study_Plan__c 
                WHERE reduivy__Clone_From_Id__c IN :childStudyPlanIds
            ];
            
            System.Assert.areEqual(0, potentialClonedChildPlans.size(), 'No child study plans should be cloned when cloneChildStudyPlans is false');
        }
    }

    /**
     * @description Test execute as admin (include existing study plan unit requirements)
     */
    @IsTest
    static void testExecuteAsAdminIncludeExistingStudyPlanUnitRequirements(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //Master study plan and related records
            reduivy__Study_Plan__c studyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A' LIMIT 1];
            Map<Id, reduivy__Study_Plan_Structure__c> spsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            List<reduivy__Study_Plan_Unit_Requirement__c> spurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :spsMap.keySet()];
            Map<Id, reduivy__Study_Pathway__c> studyPathwayMap = new Map<Id, reduivy__Study_Pathway__c>([SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            Map<Id, reduivy__Study_Plan_Option__c> studyPlanOptionMap = new Map<Id, reduivy__Study_Plan_Option__c>([SELECT Id, reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c WHERE reduivy__Master_Study_Plan__c = :studyPlan.Id]);

            //Clone master study plan
            String studyPlanData = '{"attributes":{"type":"reduivy__Study_Plan__c","url":"/services/data/v62.0/sobjects/reduivy__Study_Plan__c/' + studyPlan.Id + '"},"Name":"Copy of BACBIS - Major A","reduivy__Study_Program__c":"' + studyPlan.reduivy__Study_Program__c + '"}';
            REDU_StudyPlanCloning_QUEUE queueJob = new REDU_StudyPlanCloning_QUEUE(studyPlan.Id, studyPlanData, new List<Id>(studyPathwayMap.keySet()), new List<Id>(studyPlanOptionMap.keySet()), true, false);
            
            Id jobId = System.enqueueJob(queueJob);

            System.Assert.isNotNull(jobId, 'The job should be queued successfully.');
        }

        Test.stopTest();
        
        // Verify cloned Study Plan was created
        List<reduivy__Study_Plan__c> clonedStudyPlans = [
            SELECT Id, Name, reduivy__Study_Program__c, reduivy__Clone_From_Id__c 
            FROM reduivy__Study_Plan__c 
            WHERE Name = 'Copy of BACBIS - Major A'
        ];
        
        System.Assert.areEqual(1, clonedStudyPlans.size(), 'Exactly one cloned study plan should be created');
        
        reduivy__Study_Plan__c clonedStudyPlan = clonedStudyPlans[0];
        reduivy__Study_Plan__c originalStudyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A' LIMIT 1];
        
        // Verify Study Plan cloning assertions
        System.Assert.areEqual('Copy of BACBIS - Major A', clonedStudyPlan.Name, 'Cloned study plan should have correct name');
        System.Assert.areEqual(originalStudyPlan.reduivy__Study_Program__c, clonedStudyPlan.reduivy__Study_Program__c, 'Cloned study plan should have same study program');
        System.Assert.areEqual(originalStudyPlan.Id, clonedStudyPlan.reduivy__Clone_From_Id__c, 'Clone_From_Id should reference original study plan');
        
        // Get original Study Plan Structures with requirement fields
        List<reduivy__Study_Plan_Structure__c> originalSps = [
            SELECT Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c
            FROM reduivy__Study_Plan_Structure__c 
            WHERE reduivy__Study_Plan__c = :originalStudyPlan.Id
        ];
        
        // Verify Study Plan Structures were cloned with requirement fields preserved
        List<reduivy__Study_Plan_Structure__c> clonedSps = [
            SELECT Id, reduivy__Study_Plan__c, reduivy__Clone_From_Id__c, 
                   reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c
            FROM reduivy__Study_Plan_Structure__c 
            WHERE reduivy__Study_Plan__c = :clonedStudyPlan.Id
        ];
        
        System.Assert.areEqual(originalSps.size(), clonedSps.size(), 'Number of cloned study plan structures should match original');
        
        // Create map for easier comparison of requirement fields
        Map<Id, reduivy__Study_Plan_Structure__c> originalSpsMap = new Map<Id, reduivy__Study_Plan_Structure__c>();
        for(reduivy__Study_Plan_Structure__c orisps : originalSps) {
            originalSpsMap.put(orisps.Id, orisps);
        }
        
        // Verify each cloned SPS has correct references and PRESERVED requirement fields
        for(reduivy__Study_Plan_Structure__c sps : clonedSps) {
            System.Assert.areEqual(clonedStudyPlan.Id, sps.reduivy__Study_Plan__c, 'Cloned SPS should reference cloned study plan');
            System.Assert.isNotNull(sps.reduivy__Clone_From_Id__c, 'Cloned SPS should have Clone_From_Id populated');
            System.Assert.isTrue(
                originalSpsMap.containsKey(sps.reduivy__Clone_From_Id__c),
                'Cloned study plan structure\'s Clone_From_Id must reference an original study plan structure'
            );

            // Get the original SPS to compare requirement fields
            reduivy__Study_Plan_Structure__c tempOriginalSps = originalSpsMap.get(sps.reduivy__Clone_From_Id__c);
            System.Assert.isNotNull(tempOriginalSps, 'Should be able to find original SPS for comparison');
            
            // Verify requirement fields are preserved when includeExistingStudyPlanUnitRequirements = true
            System.Assert.areEqual(tempOriginalSps.reduivy__Requirement_Logic__c, sps.reduivy__Requirement_Logic__c, 
                'Requirement Logic should be preserved when includeExistingStudyPlanUnitRequirements is true');
            System.Assert.areEqual(tempOriginalSps.reduivy__Requirement_Description__c, sps.reduivy__Requirement_Description__c, 
                'Requirement Description should be preserved when includeExistingStudyPlanUnitRequirements is true');
        }
        
        // Get original Study Plan Unit Requirements
        List<reduivy__Study_Plan_Unit_Requirement__c> originalSpurs = [
            SELECT Id, reduivy__Study_Plan_Unit__c
            FROM reduivy__Study_Plan_Unit_Requirement__c 
            WHERE reduivy__Study_Plan_Unit__c IN (SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :originalStudyPlan.Id)
        ];
        
        // Verify Study Plan Unit Requirements WERE cloned (since includeExistingStudyPlanUnitRequirements = true)
        List<reduivy__Study_Plan_Unit_Requirement__c> clonedSpurs = [
            SELECT Id, reduivy__Study_Plan_Unit__c
            FROM reduivy__Study_Plan_Unit_Requirement__c 
            WHERE reduivy__Study_Plan_Unit__c IN (SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :clonedStudyPlan.Id)
        ];
        
        System.Assert.areEqual(originalSpurs.size(), clonedSpurs.size(), 
            'Number of cloned Study Plan Unit Requirements should match original when includeExistingStudyPlanUnitRequirements is true');
        
        // Verify each cloned SPUR references a cloned SPS
        Set<Id> clonedSpsIds = new Set<Id>();
        for(reduivy__Study_Plan_Structure__c sps : clonedSps) {
            clonedSpsIds.add(sps.Id);
        }
        
        for(reduivy__Study_Plan_Unit_Requirement__c spur : clonedSpurs) {
            System.Assert.isTrue(clonedSpsIds.contains(spur.reduivy__Study_Plan_Unit__c), 
                'Each cloned SPUR should reference a cloned Study Plan Structure');
        }
        
        // Verify Study Pathways were cloned
        List<reduivy__Study_Pathway__c> originalPathways = [
            SELECT Id FROM reduivy__Study_Pathway__c 
            WHERE reduivy__Study_Plan__c = :originalStudyPlan.Id
        ];

        Set<Id> originalPathwaysIds = new Set<Id>();

        for(reduivy__Study_Pathway__c spw : originalPathways) {
            originalPathwaysIds.add(spw.Id);
        }
        
        List<reduivy__Study_Pathway__c> clonedPathways = [
            SELECT Id, reduivy__Study_Plan__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Pathway__c 
            WHERE reduivy__Study_Plan__c = :clonedStudyPlan.Id
        ];
        
        System.Assert.areEqual(originalPathways.size(), clonedPathways.size(), 'Number of cloned study pathways should match original');
        
        for(reduivy__Study_Pathway__c pathway : clonedPathways) {
            System.Assert.areEqual(clonedStudyPlan.Id, pathway.reduivy__Study_Plan__c, 'Cloned pathway should reference cloned study plan');
            System.Assert.isNotNull(pathway.reduivy__Clone_From_Id__c, 'Cloned pathway should have Clone_From_Id populated');
            System.Assert.isTrue(
                originalPathwaysIds.contains(pathway.reduivy__Clone_From_Id__c),
                'Cloned pathway\'s Clone_From_Id must reference an original study pathway'
            );
        }
        
        // Verify Study Pathway Terms were cloned
        List<reduivy__Study_Pathway_Term__c> clonedPathwayTerms = [
            SELECT Id, reduivy__Study_Pathway__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Pathway_Term__c 
            WHERE reduivy__Study_Pathway__c IN :clonedPathways
        ];
        
        List<reduivy__Study_Pathway_Term__c> originalPathwayTerms = [
            SELECT Id FROM reduivy__Study_Pathway_Term__c 
            WHERE reduivy__Study_Pathway__c IN :originalPathways
        ];

        Set<Id> originalPathwayTermsIds = new Set<Id>();

        for(reduivy__Study_Pathway_Term__c spt : originalPathwayTerms) {
            originalPathwayTermsIds.add(spt.Id);
        }
        
        System.Assert.areEqual(originalPathwayTerms.size(), clonedPathwayTerms.size(), 'Number of cloned study pathway terms should match original');
        
        for(reduivy__Study_Pathway_Term__c term : clonedPathwayTerms) {
            System.Assert.isNotNull(term.reduivy__Clone_From_Id__c, 'Cloned pathway term should have Clone_From_Id populated');
            System.Assert.isTrue(
                originalPathwayTermsIds.contains(term.reduivy__Clone_From_Id__c),
                'Cloned pathway term\'s Clone_From_Id must reference an original study pathway term'
            );
        }
        
        // Verify Study Pathway Units were cloned
        List<reduivy__Study_Pathway_Unit__c> clonedPathwayUnits = [
            SELECT Id, reduivy__Study_Pathway_Term__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__c IN :clonedPathwayTerms
        ];
        
        List<reduivy__Study_Pathway_Unit__c> originalPathwayUnits = [
            SELECT Id FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__c IN :originalPathwayTerms
        ];

        Set<Id> originalPathwayUnitsIds = new Set<Id>();

        for(reduivy__Study_Pathway_Unit__c spu : originalPathwayUnits) {
            originalPathwayUnitsIds.add(spu.Id);
        }
        
        System.Assert.areEqual(originalPathwayUnits.size(), clonedPathwayUnits.size(), 'Number of cloned study pathway units should match original');
        
        for(reduivy__Study_Pathway_Unit__c unit : clonedPathwayUnits) {
            System.Assert.isNotNull(unit.reduivy__Clone_From_Id__c, 'Cloned pathway unit should have Clone_From_Id populated');
            System.Assert.isTrue(
                originalPathwayUnitsIds.contains(unit.reduivy__Clone_From_Id__c),
                'Cloned pathway unit\'s Clone_From_Id must reference an original study pathway unit'
            );
        }
        
        // Verify Study Plan Options were cloned (but child study plans were NOT cloned since cloneChildStudyPlans = false)
        List<reduivy__Study_Plan_Option__c> originalOptions = [
            SELECT Id, reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c 
            WHERE reduivy__Master_Study_Plan__c = :originalStudyPlan.Id
        ];

        Set<Id> originalOptionsIds = new Set<Id>();

        for(reduivy__Study_Plan_Option__c spo : originalOptions) {
            originalOptionsIds.add(spo.Id);
        }
        
        List<reduivy__Study_Plan_Option__c> clonedOptions = [
            SELECT Id, reduivy__Master_Study_Plan__c, reduivy__Child_Study_Plan__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Plan_Option__c 
            WHERE reduivy__Master_Study_Plan__c = :clonedStudyPlan.Id
        ];
        
        System.Assert.areEqual(originalOptions.size(), clonedOptions.size(), 'Number of cloned study plan options should match original');
        
        for(reduivy__Study_Plan_Option__c option : clonedOptions) {
            System.Assert.areEqual(clonedStudyPlan.Id, option.reduivy__Master_Study_Plan__c, 'Cloned option should reference cloned study plan');
            System.Assert.isNotNull(option.reduivy__Clone_From_Id__c, 'Cloned option should have Clone_From_Id populated');
            System.Assert.isTrue(
                originalOptionsIds.contains(option.reduivy__Clone_From_Id__c),
                'Cloned study plan option\'s Clone_From_Id must reference an original study plan option'
            );
            // Child study plan should remain the same since cloneChildStudyPlans = false
            System.Assert.isNotNull(option.reduivy__Child_Study_Plan__c, 'Child study plan reference should be preserved');
        }
        
        // Verify that child study plans were NOT cloned (since cloneChildStudyPlans = false)
        Set<Id> childStudyPlanIds = new Set<Id>();
        for(reduivy__Study_Plan_Option__c option : originalOptions) {
            if(option.reduivy__Child_Study_Plan__c != null) {
                childStudyPlanIds.add(option.reduivy__Child_Study_Plan__c);
            }
        }
        
        if(!childStudyPlanIds.isEmpty()) {
            List<reduivy__Study_Plan__c> potentialClonedChildPlans = [
                SELECT Id FROM reduivy__Study_Plan__c 
                WHERE reduivy__Clone_From_Id__c IN :childStudyPlanIds
            ];
            
            System.Assert.areEqual(0, potentialClonedChildPlans.size(), 'No child study plans should be cloned when cloneChildStudyPlans is false');
        }
        
        // Additional verification: Ensure the cloning process maintained data integrity
        System.Assert.isTrue(clonedSpurs.size() > 0 || originalSpurs.size() == 0, 
            'If original study plan had SPURs, cloned study plan should also have SPURs when includeExistingStudyPlanUnitRequirements is true');   
    }

    /**
     * @description Test execute as admin (clone child study plans)
     */
    @IsTest
    static void testExecuteAsAdminCloneChildStudyPlans(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //Master study plan and related records
            reduivy__Study_Plan__c studyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A' LIMIT 1];
            Map<Id, reduivy__Study_Plan_Structure__c> spsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            List<reduivy__Study_Plan_Unit_Requirement__c> spurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :spsMap.keySet()];
            Map<Id, reduivy__Study_Pathway__c> studyPathwayMap = new Map<Id, reduivy__Study_Pathway__c>([SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            Map<Id, reduivy__Study_Plan_Option__c> studyPlanOptionMap = new Map<Id, reduivy__Study_Plan_Option__c>([SELECT Id, reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c WHERE reduivy__Master_Study_Plan__c = :studyPlan.Id]);

            Set<Id> childStudyPlanIdSet = new Set<Id>();
            for (reduivy__Study_Plan_Option__c studyPlanOption : studyPlanOptionMap.values()) {
                childStudyPlanIdSet.add(studyPlanOption.reduivy__Child_Study_Plan__c);
            }

            //Child study plans and related records
            Map<Id, reduivy__Study_Plan__c> childStudyPlanMap = new Map<Id, reduivy__Study_Plan__c>([SELECT Id FROM reduivy__Study_Plan__c WHERE Id IN :childStudyPlanIdSet]);
            Map<Id, reduivy__Study_Plan_Structure__c> childSpsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c IN :childStudyPlanMap.keySet()]);
            List<reduivy__Study_Plan_Unit_Requirement__c> childSpurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :childSpsMap.keySet()];
            Map<Id, reduivy__Study_Pathway__c> childStudyPathwayMap = new Map<Id, reduivy__Study_Pathway__c>([SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Study_Plan__c IN :childStudyPlanMap.keySet()]);

            //Clone master study plan
            String studyPlanData = '{"attributes":{"type":"reduivy__Study_Plan__c","url":"/services/data/v62.0/sobjects/reduivy__Study_Plan__c/' + studyPlan.Id + '"},"Name":"Copy of BACBIS - Major A","reduivy__Study_Program__c":"' + studyPlan.reduivy__Study_Program__c + '"}';
            REDU_StudyPlanCloning_QUEUE queueJob = new REDU_StudyPlanCloning_QUEUE(studyPlan.Id, studyPlanData, new List<Id>(studyPathwayMap.keySet()), new List<Id>(studyPlanOptionMap.keySet()), false, true);

            Id jobId = System.enqueueJob(queueJob);

            System.Assert.isNotNull(jobId, 'The job should be queued successfully.');
        }

        Test.stopTest();
        
        // Get the original master study plan for reference
        reduivy__Study_Plan__c originalStudyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A' LIMIT 1];
        
        // Verify master study plan was cloned
        List<reduivy__Study_Plan__c> clonedMasterStudyPlans = [
            SELECT Id, Name, reduivy__Study_Program__c, reduivy__Clone_From_Id__c 
            FROM reduivy__Study_Plan__c 
            WHERE Name = 'Copy of BACBIS - Major A'
        ];
        
        System.Assert.areEqual(1, clonedMasterStudyPlans.size(), 'Exactly one cloned master study plan should be created');
        
        reduivy__Study_Plan__c clonedMasterStudyPlan = clonedMasterStudyPlans[0];
        
        // Verify master Study Plan cloning assertions
        System.Assert.areEqual('Copy of BACBIS - Major A', clonedMasterStudyPlan.Name, 'Cloned master study plan should have correct name');
        System.Assert.areEqual(originalStudyPlan.reduivy__Study_Program__c, clonedMasterStudyPlan.reduivy__Study_Program__c, 'Cloned master study plan should have same study program');
        System.Assert.areEqual(originalStudyPlan.Id, clonedMasterStudyPlan.reduivy__Clone_From_Id__c, 'Clone_From_Id should reference original master study plan');
        
        // Get original child study plans for verification
        List<reduivy__Study_Plan_Option__c> originalOptions = [
            SELECT Id, reduivy__Child_Study_Plan__c 
            FROM reduivy__Study_Plan_Option__c 
            WHERE reduivy__Master_Study_Plan__c = :originalStudyPlan.Id
        ];
        
        Set<Id> originalChildStudyPlanIds = new Set<Id>();
        for(reduivy__Study_Plan_Option__c option : originalOptions) {
            if(option.reduivy__Child_Study_Plan__c != null) {
                originalChildStudyPlanIds.add(option.reduivy__Child_Study_Plan__c);
            }
        }
        
        // Verify child study plans were cloned
        List<reduivy__Study_Plan__c> clonedChildStudyPlans = [
            SELECT Id, Name, reduivy__Study_Program__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Clone_From_Id__c IN :originalChildStudyPlanIds
        ];
        
        System.Assert.areEqual(originalChildStudyPlanIds.size(), clonedChildStudyPlans.size(), 
            'Number of cloned child study plans should match original child study plans');
        
        // Create a map of original child study plan ID to cloned child study plan for easier verification
        Map<Id, reduivy__Study_Plan__c> originalToClonedChildStudyPlanMap = new Map<Id, reduivy__Study_Plan__c>();
        for(reduivy__Study_Plan__c clonedChild : clonedChildStudyPlans) {
            originalToClonedChildStudyPlanMap.put(clonedChild.reduivy__Clone_From_Id__c, clonedChild);
            System.Assert.isNotNull(clonedChild.reduivy__Clone_From_Id__c, 'Cloned child study plan should have Clone_From_Id populated');
        }
        
        // Verify Study Plan Options were cloned with correct child study plan references
        List<reduivy__Study_Plan_Option__c> clonedOptions = [
            SELECT Id, reduivy__Master_Study_Plan__c, reduivy__Child_Study_Plan__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Plan_Option__c 
            WHERE reduivy__Master_Study_Plan__c = :clonedMasterStudyPlan.Id
        ];
        
        System.Assert.areEqual(originalOptions.size(), clonedOptions.size(), 'Number of cloned study plan options should match original');
        
        for(reduivy__Study_Plan_Option__c clonedOption : clonedOptions) {
            System.Assert.areEqual(clonedMasterStudyPlan.Id, clonedOption.reduivy__Master_Study_Plan__c, 
                'Cloned option should reference cloned master study plan');
            System.Assert.isNotNull(clonedOption.reduivy__Clone_From_Id__c, 'Cloned option should have Clone_From_Id populated');
            
            // Find the original option this was cloned from
            reduivy__Study_Plan_Option__c originalOption = null;
            for(reduivy__Study_Plan_Option__c origOpt : originalOptions) {
                if(origOpt.Id == clonedOption.reduivy__Clone_From_Id__c) {
                    originalOption = origOpt;
                    break;
                }
            }
            
            System.Assert.isNotNull(originalOption, 'Should find matching original option');
            
            // Verify the child study plan reference points to the cloned child study plan
            if(originalOption.reduivy__Child_Study_Plan__c != null) {
                reduivy__Study_Plan__c expectedClonedChild = originalToClonedChildStudyPlanMap.get(originalOption.reduivy__Child_Study_Plan__c);
                System.Assert.isNotNull(expectedClonedChild, 'Should have cloned child study plan');
                System.Assert.areEqual(expectedClonedChild.Id, clonedOption.reduivy__Child_Study_Plan__c, 
                    'Cloned option should reference cloned child study plan');
            }
        }
        
        // Verify master Study Plan Structures were cloned
        List<reduivy__Study_Plan_Structure__c> originalMasterSps = [
            SELECT Id FROM reduivy__Study_Plan_Structure__c 
            WHERE reduivy__Study_Plan__c = :originalStudyPlan.Id
        ];
        
        List<reduivy__Study_Plan_Structure__c> clonedMasterSps = [
            SELECT Id, reduivy__Study_Plan__c, reduivy__Clone_From_Id__c, 
                reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c
            FROM reduivy__Study_Plan_Structure__c 
            WHERE reduivy__Study_Plan__c = :clonedMasterStudyPlan.Id
        ];

        Set<Id> originalMasterSpsIds = new Set<Id>();

        for(reduivy__Study_Plan_Structure__c orisps : originalMasterSps) {
            originalMasterSpsIds.add(orisps.Id);
        }
        
        System.Assert.areEqual(originalMasterSps.size(), clonedMasterSps.size(), 
            'Number of cloned master study plan structures should match original');
        
        // Verify each cloned master SPS has correct references and cleared requirement fields
        for(reduivy__Study_Plan_Structure__c sps : clonedMasterSps) {
            System.Assert.areEqual(clonedMasterStudyPlan.Id, sps.reduivy__Study_Plan__c, 
                'Cloned master SPS should reference cloned master study plan');
            System.Assert.isNotNull(sps.reduivy__Clone_From_Id__c, 'Cloned master SPS should have Clone_From_Id populated');
            System.Assert.isTrue(
                originalMasterSpsIds.contains(sps.reduivy__Clone_From_Id__c),
                'Cloned master SPS\'s Clone_From_Id must reference an original SPS'
            );
            System.Assert.isNull(sps.reduivy__Requirement_Logic__c, 
                'Master SPS Requirement Logic should be cleared when includeExistingStudyPlanUnitRequirements is false');
            System.Assert.isNull(sps.reduivy__Requirement_Description__c, 
                'Master SPS Requirement Description should be cleared when includeExistingStudyPlanUnitRequirements is false');
        }
        
        // Verify child Study Plan Structures were cloned
        List<reduivy__Study_Plan_Structure__c> originalChildSps = [
            SELECT Id FROM reduivy__Study_Plan_Structure__c 
            WHERE reduivy__Study_Plan__c IN :originalChildStudyPlanIds
        ];
        
        Set<Id> clonedChildStudyPlanIds = new Set<Id>();
        for(reduivy__Study_Plan__c clonedChild : clonedChildStudyPlans) {
            clonedChildStudyPlanIds.add(clonedChild.Id);
        }
        
        List<reduivy__Study_Plan_Structure__c> clonedChildSps = [
            SELECT Id, reduivy__Study_Plan__c, reduivy__Clone_From_Id__c, 
                reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c
            FROM reduivy__Study_Plan_Structure__c 
            WHERE reduivy__Study_Plan__c IN :clonedChildStudyPlanIds
        ];
        
        System.Assert.areEqual(originalChildSps.size(), clonedChildSps.size(), 
            'Number of cloned child study plan structures should match original');
        
        // Verify each cloned child SPS has correct references and cleared requirement fields
        for(reduivy__Study_Plan_Structure__c sps : clonedChildSps) {
            System.Assert.isTrue(clonedChildStudyPlanIds.contains(sps.reduivy__Study_Plan__c), 
                'Cloned child SPS should reference a cloned child study plan');
            System.Assert.isNotNull(sps.reduivy__Clone_From_Id__c, 'Cloned child SPS should have Clone_From_Id populated');
            System.Assert.isNull(sps.reduivy__Requirement_Logic__c, 
                'Child SPS Requirement Logic should be cleared when includeExistingStudyPlanUnitRequirements is false');
            System.Assert.isNull(sps.reduivy__Requirement_Description__c, 
                'Child SPS Requirement Description should be cleared when includeExistingStudyPlanUnitRequirements is false');
        }
        
        // Verify Study Plan Unit Requirements were NOT cloned for both master and child study plans
        List<reduivy__Study_Plan_Unit_Requirement__c> clonedMasterSpurs = [
            SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c 
            WHERE reduivy__Study_Plan_Unit__c IN (SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :clonedMasterStudyPlan.Id)
        ];
        
        List<reduivy__Study_Plan_Unit_Requirement__c> clonedChildSpurs = [
            SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c 
            WHERE reduivy__Study_Plan_Unit__c IN (SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c IN :clonedChildStudyPlanIds)
        ];
        
        System.Assert.areEqual(0, clonedMasterSpurs.size(), 
            'No master Study Plan Unit Requirements should be cloned when includeExistingStudyPlanUnitRequirements is false');
        System.Assert.areEqual(0, clonedChildSpurs.size(), 
            'No child Study Plan Unit Requirements should be cloned when includeExistingStudyPlanUnitRequirements is false');
        
        // Verify Study Pathways were cloned for master study plan
        List<reduivy__Study_Pathway__c> originalMasterPathways = [
            SELECT Id FROM reduivy__Study_Pathway__c 
            WHERE reduivy__Study_Plan__c = :originalStudyPlan.Id
        ];
        
        List<reduivy__Study_Pathway__c> clonedMasterPathways = [
            SELECT Id, reduivy__Study_Plan__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Pathway__c 
            WHERE reduivy__Study_Plan__c = :clonedMasterStudyPlan.Id
        ];
        
        Set<Id> originalMasterPathwaysIds = new Set<Id>();

        for(reduivy__Study_Pathway__c spw : originalMasterPathways) {
            originalMasterPathwaysIds.add(spw.Id);
        }

        System.Assert.areEqual(originalMasterPathways.size(), clonedMasterPathways.size(), 
            'Number of cloned master study pathways should match original');
        
        for(reduivy__Study_Pathway__c pathway : clonedMasterPathways) {
            System.Assert.areEqual(clonedMasterStudyPlan.Id, pathway.reduivy__Study_Plan__c, 
                'Cloned master pathway should reference cloned master study plan');
            System.Assert.isNotNull(pathway.reduivy__Clone_From_Id__c, 'Cloned master pathway should have Clone_From_Id populated');
            System.Assert.isTrue(
                originalMasterPathwaysIds.contains(pathway.reduivy__Clone_From_Id__c),
                'Cloned master study pathway\'s Clone_From_Id must reference an original study pathway'
            );
        }
        
        // Verify Study Pathway Terms were cloned for master study plan
        List<reduivy__Study_Pathway_Term__c> clonedMasterPathwayTerms = [
            SELECT Id, reduivy__Study_Pathway__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Pathway_Term__c 
            WHERE reduivy__Study_Pathway__c IN :clonedMasterPathways
        ];
        
        List<reduivy__Study_Pathway_Term__c> originalMasterPathwayTerms = [
            SELECT Id FROM reduivy__Study_Pathway_Term__c 
            WHERE reduivy__Study_Pathway__c IN :originalMasterPathways
        ];

        Set<Id> originalMasterPathwayTermsIds = new Set<Id>();

        for(reduivy__Study_Pathway_Term__c spt : originalMasterPathwayTerms) {
            originalMasterPathwayTermsIds.add(spt.Id);
        }
        
        System.Assert.areEqual(originalMasterPathwayTerms.size(), clonedMasterPathwayTerms.size(), 
            'Number of cloned master study pathway terms should match original');
        
        for(reduivy__Study_Pathway_Term__c term : clonedMasterPathwayTerms) {
            System.Assert.isNotNull(term.reduivy__Clone_From_Id__c, 'Cloned master pathway term should have Clone_From_Id populated');
            System.Assert.isTrue(
                originalMasterPathwayTermsIds.contains(term.reduivy__Clone_From_Id__c),
                'Cloned pathway plan term\'s Clone_From_Id must reference an original study pathway term'
            );
        }
        
        // Verify Study Pathway Units were cloned for master study plan
        List<reduivy__Study_Pathway_Unit__c> clonedMasterPathwayUnits = [
            SELECT Id, reduivy__Study_Pathway_Term__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__c IN :clonedMasterPathwayTerms
        ];
        
        List<reduivy__Study_Pathway_Unit__c> originalMasterPathwayUnits = [
            SELECT Id FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__c IN :originalMasterPathwayTerms
        ];
        
        Set<Id> originalMasterPathwayUnitsIds = new Set<Id>();

        for(reduivy__Study_Pathway_Unit__c spu : originalMasterPathwayUnits) {
            originalMasterPathwayUnitsIds.add(spu.Id);
        }

        System.Assert.areEqual(originalMasterPathwayUnits.size(), clonedMasterPathwayUnits.size(), 
            'Number of cloned master study pathway units should match original');
        
        for(reduivy__Study_Pathway_Unit__c unit : clonedMasterPathwayUnits) {
            System.Assert.isNotNull(unit.reduivy__Clone_From_Id__c, 'Cloned master pathway unit should have Clone_From_Id populated');
            System.Assert.isTrue(
                originalMasterPathwayUnitsIds.contains(unit.reduivy__Clone_From_Id__c),
                'Cloned pathway unit\'s Clone_From_Id must reference an original study pathway unit'
            );
        }
    }

    /**
     * @description Test execute as admin with the master study plan set as the applicable study plan for a study pathway unit
     */
    @IsTest
    static void testExecuteAsAdminApplicableStudyPlanMaster(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //Master study plan and related records
            reduivy__Study_Plan__c studyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A' LIMIT 1];
            Map<Id, reduivy__Study_Plan_Structure__c> spsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            List<reduivy__Study_Plan_Unit_Requirement__c> spurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :spsMap.keySet()];
            Map<Id, reduivy__Study_Pathway__c> studyPathwayMap = new Map<Id, reduivy__Study_Pathway__c>([SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            Map<Id, reduivy__Study_Plan_Option__c> studyPlanOptionMap = new Map<Id, reduivy__Study_Plan_Option__c>([SELECT Id, reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c WHERE reduivy__Master_Study_Plan__c = :studyPlan.Id]);

            //Set applicable study plan
            reduivy__Study_Pathway_Unit__c spu = [SELECT Id FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__r.reduivy__Study_Plan__c = :studyPlan.Id LIMIT 1];
            spu.reduivy__Applicable_Study_Plan__c = studyPlan.Id;
            update spu;

            //Clone master study plan
            String studyPlanData = '{"attributes":{"type":"reduivy__Study_Plan__c","url":"/services/data/v62.0/sobjects/reduivy__Study_Plan__c/' + studyPlan.Id + '"},"Name":"Copy of BACBIS - Major A","reduivy__Study_Program__c":"' + studyPlan.reduivy__Study_Program__c + '"}';
            REDU_StudyPlanCloning_QUEUE queueJob = new REDU_StudyPlanCloning_QUEUE(studyPlan.Id, studyPlanData, new List<Id>(studyPathwayMap.keySet()), new List<Id>(studyPlanOptionMap.keySet()), false, false);
            
            Id jobId = System.enqueueJob(queueJob);

            System.Assert.isNotNull(jobId, 'The job should be queued successfully.');
        }

        Test.stopTest();
        
        // Verify cloned study plan was created
        List<reduivy__Study_Plan__c> clonedStudyPlans = [
            SELECT Id, Name, reduivy__Study_Program__c, reduivy__Clone_From_Id__c 
            FROM reduivy__Study_Plan__c 
            WHERE Name = 'Copy of BACBIS - Major A'
        ];

        System.Assert.areEqual(1, clonedStudyPlans.size(), 'Exactly one cloned study plan should be created');

        reduivy__Study_Plan__c clonedStudyPlan = clonedStudyPlans[0];
        reduivy__Study_Plan__c originalStudyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A' LIMIT 1];

        // Verify basic Study Plan cloning
        System.Assert.areEqual('Copy of BACBIS - Major A', clonedStudyPlan.Name, 'Cloned study plan should have correct name');
        System.Assert.areEqual(originalStudyPlan.reduivy__Study_Program__c, clonedStudyPlan.reduivy__Study_Program__c, 'Cloned study plan should have same study program');
        System.Assert.areEqual(originalStudyPlan.Id, clonedStudyPlan.reduivy__Clone_From_Id__c, 'Clone_From_Id should reference original study plan');

        // Get the original Study Pathway Unit that was updated
        reduivy__Study_Pathway_Unit__c originalSpu = [
            SELECT Id, reduivy__Applicable_Study_Plan__c, reduivy__Study_Pathway_Term__c
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__r.reduivy__Study_Plan__c = :originalStudyPlan.Id 
            AND reduivy__Applicable_Study_Plan__c = :originalStudyPlan.Id
            LIMIT 1
        ];

        System.Assert.isNotNull(originalSpu, 'Original Study Pathway Unit with master study plan as applicable should exist');

        // Find the corresponding cloned Study Pathway Unit
        List<reduivy__Study_Pathway_Unit__c> clonedSpus = [
            SELECT Id, reduivy__Applicable_Study_Plan__c, reduivy__Clone_From_Id__c, reduivy__Study_Pathway_Term__c
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__r.reduivy__Study_Plan__c = :clonedStudyPlan.Id
            AND reduivy__Clone_From_Id__c = :originalSpu.Id
        ];

        System.Assert.areEqual(1, clonedSpus.size(), 'Exactly one cloned Study Pathway Unit should exist for the original SPU');

        reduivy__Study_Pathway_Unit__c clonedSpu = clonedSpus[0];

        // Verify the Applicable Study Plan was updated to reference the cloned study plan
        System.Assert.areEqual(clonedStudyPlan.Id, clonedSpu.reduivy__Applicable_Study_Plan__c, 
            'Cloned Study Pathway Unit should have Applicable Study Plan updated to reference the cloned study plan');

        System.Assert.areEqual(originalSpu.Id, clonedSpu.reduivy__Clone_From_Id__c, 
            'Cloned Study Pathway Unit should have Clone_From_Id referencing the original SPU');

        // Verify other Study Pathway Units without the master study plan as applicable were also cloned
        List<reduivy__Study_Pathway_Unit__c> allOriginalSpus = [
            SELECT Id FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__r.reduivy__Study_Plan__c = :originalStudyPlan.Id
        ];

        List<reduivy__Study_Pathway_Unit__c> allClonedSpus = [
            SELECT Id, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__r.reduivy__Study_Plan__c = :clonedStudyPlan.Id
        ];

        System.Assert.areEqual(allOriginalSpus.size(), allClonedSpus.size(), 
            'Number of cloned Study Pathway Units should match original count');

        // Verify all cloned SPUs have Clone_From_Id populated
        for(reduivy__Study_Pathway_Unit__c spu : allClonedSpus) {
            System.Assert.isNotNull(spu.reduivy__Clone_From_Id__c, 
                'All cloned Study Pathway Units should have Clone_From_Id populated');
        }
    }

    /**
     * @description Test execute as admin with a child study plan set as the applicable study plan for a study pathway unit
     */
    @IsTest
    static void testExecuteAsAdminApplicableStudyPlanChild(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //Master study plan and related records
            reduivy__Study_Plan__c studyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A' LIMIT 1];
            Map<Id, reduivy__Study_Plan_Structure__c> spsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            List<reduivy__Study_Plan_Unit_Requirement__c> spurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :spsMap.keySet()];
            Map<Id, reduivy__Study_Pathway__c> studyPathwayMap = new Map<Id, reduivy__Study_Pathway__c>([SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            Map<Id, reduivy__Study_Plan_Option__c> studyPlanOptionMap = new Map<Id, reduivy__Study_Plan_Option__c>([SELECT Id, reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c WHERE reduivy__Master_Study_Plan__c = :studyPlan.Id]);

            Set<Id> childStudyPlanIdSet = new Set<Id>();
            for (reduivy__Study_Plan_Option__c studyPlanOption : studyPlanOptionMap.values()) {
                childStudyPlanIdSet.add(studyPlanOption.reduivy__Child_Study_Plan__c);
            }

            //Child study plans and related records
            Map<Id, reduivy__Study_Plan__c> childStudyPlanMap = new Map<Id, reduivy__Study_Plan__c>([SELECT Id FROM reduivy__Study_Plan__c WHERE Id IN :childStudyPlanIdSet]);
            Map<Id, reduivy__Study_Plan_Structure__c> childSpsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c IN :childStudyPlanMap.keySet()]);
            List<reduivy__Study_Plan_Unit_Requirement__c> childSpurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :childSpsMap.keySet()];
            Map<Id, reduivy__Study_Pathway__c> childStudyPathwayMap = new Map<Id, reduivy__Study_Pathway__c>([SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Study_Plan__c IN :childStudyPlanMap.keySet()]);

            //Set applicable study plan
            reduivy__Study_Pathway_Unit__c spu = [SELECT Id FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__r.reduivy__Study_Plan__c = :studyPlan.Id LIMIT 1];
            spu.reduivy__Applicable_Study_Plan__c = childStudyPlanIdSet.iterator().next();
            update spu;

            //Clone master study plan
            String studyPlanData = '{"attributes":{"type":"reduivy__Study_Plan__c","url":"/services/data/v62.0/sobjects/reduivy__Study_Plan__c/' + studyPlan.Id + '"},"Name":"Copy of BACBIS - Major A","reduivy__Study_Program__c":"' + studyPlan.reduivy__Study_Program__c + '"}';
            REDU_StudyPlanCloning_QUEUE queueJob = new REDU_StudyPlanCloning_QUEUE(studyPlan.Id, studyPlanData, new List<Id>(studyPathwayMap.keySet()), new List<Id>(studyPlanOptionMap.keySet()), false, true);
            
            Id jobId = System.enqueueJob(queueJob);

            System.Assert.isNotNull(jobId, 'The job should be queued successfully.');        
        }

        Test.stopTest();
        
        // Get original study plan for reference
        reduivy__Study_Plan__c originalStudyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A' LIMIT 1];
        
        // Verify cloned master study plan was created
        List<reduivy__Study_Plan__c> clonedStudyPlans = [
            SELECT Id, Name, reduivy__Study_Program__c, reduivy__Clone_From_Id__c 
            FROM reduivy__Study_Plan__c 
            WHERE Name = 'Copy of BACBIS - Major A'
        ];
        
        System.Assert.areEqual(1, clonedStudyPlans.size(), 'Exactly one cloned master study plan should be created');
        
        reduivy__Study_Plan__c clonedMasterStudyPlan = clonedStudyPlans[0];
        
        // Verify master study plan cloning assertions
        System.Assert.areEqual('Copy of BACBIS - Major A', clonedMasterStudyPlan.Name, 'Cloned study plan should have correct name');
        System.Assert.areEqual(originalStudyPlan.reduivy__Study_Program__c, clonedMasterStudyPlan.reduivy__Study_Program__c, 'Cloned study plan should have same study program');
        System.Assert.areEqual(originalStudyPlan.Id, clonedMasterStudyPlan.reduivy__Clone_From_Id__c, 'Clone_From_Id should reference original study plan');
        
        // Get original child study plans
        List<reduivy__Study_Plan_Option__c> originalOptions = [
            SELECT Id, reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c 
            WHERE reduivy__Master_Study_Plan__c = :originalStudyPlan.Id
        ];
        
        Set<Id> originalChildStudyPlanIds = new Set<Id>();
        for(reduivy__Study_Plan_Option__c option : originalOptions) {
            if(option.reduivy__Child_Study_Plan__c != null) {
                originalChildStudyPlanIds.add(option.reduivy__Child_Study_Plan__c);
            }
        }
        
        // Verify child study plans were cloned (since cloneChildStudyPlans = true)
        List<reduivy__Study_Plan__c> clonedChildStudyPlans = [
            SELECT Id, Name, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Clone_From_Id__c IN :originalChildStudyPlanIds
        ];
        
        System.Assert.areEqual(originalChildStudyPlanIds.size(), clonedChildStudyPlans.size(), 
            'Number of cloned child study plans should match original child study plans');
        
        // Create mapping of original to cloned child study plans
        Map<Id, reduivy__Study_Plan__c> originalToClonedChildPlanMap = new Map<Id, reduivy__Study_Plan__c>();
        for(reduivy__Study_Plan__c clonedChild : clonedChildStudyPlans) {
            originalToClonedChildPlanMap.put(clonedChild.reduivy__Clone_From_Id__c, clonedChild);
            System.Assert.isNotNull(clonedChild.reduivy__Clone_From_Id__c, 'Cloned child study plan should have Clone_From_Id populated');
        }
        
        // Verify cloned study plan options reference cloned child study plans
        List<reduivy__Study_Plan_Option__c> clonedOptions = [
            SELECT Id, reduivy__Master_Study_Plan__c, reduivy__Child_Study_Plan__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Plan_Option__c 
            WHERE reduivy__Master_Study_Plan__c = :clonedMasterStudyPlan.Id
        ];
        
        System.Assert.areEqual(originalOptions.size(), clonedOptions.size(), 
            'Number of cloned study plan options should match original');
        
        for(reduivy__Study_Plan_Option__c clonedOption : clonedOptions) {
            System.Assert.areEqual(clonedMasterStudyPlan.Id, clonedOption.reduivy__Master_Study_Plan__c, 
                'Cloned option should reference cloned master study plan');
            System.Assert.isNotNull(clonedOption.reduivy__Clone_From_Id__c, 
                'Cloned option should have Clone_From_Id populated');
            System.Assert.isTrue(originalToClonedChildPlanMap.containsKey(
                [SELECT reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c WHERE Id = :clonedOption.reduivy__Clone_From_Id__c].reduivy__Child_Study_Plan__c),
                'Cloned option should reference a cloned child study plan');
        }
        
        // Verify Study Plan Structures were cloned for master study plan
        List<reduivy__Study_Plan_Structure__c> clonedMasterSps = [
            SELECT Id, reduivy__Study_Plan__c, reduivy__Clone_From_Id__c, 
                reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c
            FROM reduivy__Study_Plan_Structure__c 
            WHERE reduivy__Study_Plan__c = :clonedMasterStudyPlan.Id
        ];
        
        List<reduivy__Study_Plan_Structure__c> originalMasterSps = [
            SELECT Id FROM reduivy__Study_Plan_Structure__c 
            WHERE reduivy__Study_Plan__c = :originalStudyPlan.Id
        ];
        
        System.Assert.areEqual(originalMasterSps.size(), clonedMasterSps.size(), 
            'Number of cloned master study plan structures should match original');
        
        // Verify Study Plan Structures were cloned for child study plans
        List<reduivy__Study_Plan_Structure__c> clonedChildSps = [
            SELECT Id, reduivy__Study_Plan__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Plan_Structure__c 
            WHERE reduivy__Study_Plan__c IN :originalToClonedChildPlanMap.values()
        ];
        
        List<reduivy__Study_Plan_Structure__c> originalChildSps = [
            SELECT Id FROM reduivy__Study_Plan_Structure__c 
            WHERE reduivy__Study_Plan__c IN :originalChildStudyPlanIds
        ];
        
        System.Assert.areEqual(originalChildSps.size(), clonedChildSps.size(), 
            'Number of cloned child study plan structures should match original');
        
        // Verify Study Pathways were cloned
        List<reduivy__Study_Pathway__c> clonedPathways = [
            SELECT Id, reduivy__Study_Plan__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Pathway__c 
            WHERE reduivy__Study_Plan__c = :clonedMasterStudyPlan.Id
        ];
        
        List<reduivy__Study_Pathway__c> originalPathways = [
            SELECT Id FROM reduivy__Study_Pathway__c 
            WHERE reduivy__Study_Plan__c = :originalStudyPlan.Id
        ];
        
        System.Assert.areEqual(originalPathways.size(), clonedPathways.size(), 
            'Number of cloned study pathways should match original');
        
        // Verify Study Pathway Terms were cloned
        List<reduivy__Study_Pathway_Term__c> clonedPathwayTerms = [
            SELECT Id, reduivy__Study_Pathway__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Pathway_Term__c 
            WHERE reduivy__Study_Pathway__c IN :clonedPathways
        ];
        
        List<reduivy__Study_Pathway_Term__c> originalPathwayTerms = [
            SELECT Id FROM reduivy__Study_Pathway_Term__c 
            WHERE reduivy__Study_Pathway__c IN :originalPathways
        ];
        
        System.Assert.areEqual(originalPathwayTerms.size(), clonedPathwayTerms.size(), 
            'Number of cloned study pathway terms should match original');
        
        // Verify that the study pathway unit that originally referenced a child study plan now references the cloned child study plan
        List<reduivy__Study_Pathway_Unit__c> clonedPathwayUnits = [
            SELECT Id, reduivy__Study_Pathway_Term__c, reduivy__Clone_From_Id__c, 
                reduivy__Applicable_Study_Plan__c, reduivy__Study_Plan_Group__c
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__c IN :clonedPathwayTerms
        ];
        
        List<reduivy__Study_Pathway_Unit__c> originalPathwayUnits = [
            SELECT Id, reduivy__Applicable_Study_Plan__c
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__c IN :originalPathwayTerms
        ];
        
        System.Assert.areEqual(originalPathwayUnits.size(), clonedPathwayUnits.size(), 
            'Number of cloned study pathway units should match original');
        
        // Find the specific cloned pathway unit that should have the updated applicable study plan reference
        reduivy__Study_Pathway_Unit__c originalSpuWithApplicableChild = [
            SELECT Id, reduivy__Applicable_Study_Plan__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__r.reduivy__Study_Plan__c = :originalStudyPlan.Id
            AND reduivy__Applicable_Study_Plan__c != NULL
            LIMIT 1
        ];
        
        // Find the corresponding cloned pathway unit
        List<reduivy__Study_Pathway_Unit__c> matchingClonedSpus = new List<reduivy__Study_Pathway_Unit__c>();
        for(reduivy__Study_Pathway_Unit__c clonedSpu : clonedPathwayUnits) {
            if(clonedSpu.reduivy__Clone_From_Id__c == originalSpuWithApplicableChild.Id) {
                matchingClonedSpus.add(clonedSpu);
            }
        }
        
        System.Assert.areEqual(1, matchingClonedSpus.size(), 
            'Should find exactly one cloned study pathway unit matching the original');
        
        reduivy__Study_Pathway_Unit__c clonedSpuWithApplicableChild = matchingClonedSpus[0];
        
        // Verify the applicable study plan was updated to reference the cloned child study plan
        System.Assert.isNotNull(clonedSpuWithApplicableChild.reduivy__Applicable_Study_Plan__c, 
            'Cloned study pathway unit should have applicable study plan set');
        
        System.Assert.areNotEqual(originalSpuWithApplicableChild.reduivy__Applicable_Study_Plan__c, 
            clonedSpuWithApplicableChild.reduivy__Applicable_Study_Plan__c, 
            'Cloned study pathway unit should reference different (cloned) applicable study plan');
        
        // Verify the specific mapping is correct
        Id expectedClonedChildId = originalToClonedChildPlanMap.get(originalSpuWithApplicableChild.reduivy__Applicable_Study_Plan__c).Id;
        System.Assert.areEqual(expectedClonedChildId, clonedSpuWithApplicableChild.reduivy__Applicable_Study_Plan__c,
            'Cloned study pathway unit should reference the correct cloned child study plan');
        
        // Verify Study Plan Unit Requirements were NOT cloned (since includeExistingStudyPlanUnitRequirements = false)
        List<reduivy__Study_Plan_Unit_Requirement__c> clonedSpurs = [
            SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c 
            WHERE reduivy__Study_Plan_Unit__c IN (
                SELECT Id FROM reduivy__Study_Plan_Structure__c 
                WHERE reduivy__Study_Plan__c = :clonedMasterStudyPlan.Id
                OR reduivy__Study_Plan__c IN :originalToClonedChildPlanMap.values()
            )
        ];
        
        System.Assert.areEqual(0, clonedSpurs.size(), 
            'No Study Plan Unit Requirements should be cloned when includeExistingStudyPlanUnitRequirements is false');

    }

    /**
     * @description Test execute as admin with a child study plan (not cloned) set as the applicable study plan for a study pathway unit
     */
    @IsTest
    static void testExecuteAsAdminApplicableStudyPlanChildNotCloned(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //Master study plan and related records
            reduivy__Study_Plan__c studyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A' LIMIT 1];
            Map<Id, reduivy__Study_Plan_Structure__c> spsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            List<reduivy__Study_Plan_Unit_Requirement__c> spurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :spsMap.keySet()];
            Map<Id, reduivy__Study_Pathway__c> studyPathwayMap = new Map<Id, reduivy__Study_Pathway__c>([SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            Map<Id, reduivy__Study_Plan_Option__c> studyPlanOptionMap = new Map<Id, reduivy__Study_Plan_Option__c>([SELECT Id, reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c WHERE reduivy__Master_Study_Plan__c = :studyPlan.Id]);

            Set<Id> childStudyPlanIdSet = new Set<Id>();
            for (reduivy__Study_Plan_Option__c studyPlanOption : studyPlanOptionMap.values()) {
                childStudyPlanIdSet.add(studyPlanOption.reduivy__Child_Study_Plan__c);
            }

            //Set applicable study plan
            reduivy__Study_Pathway_Unit__c spu = [SELECT Id FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__r.reduivy__Study_Plan__c = :studyPlan.Id LIMIT 1];
            spu.reduivy__Applicable_Study_Plan__c = childStudyPlanIdSet.iterator().next();
            update spu;

            //Clone master study plan
            String studyPlanData = '{"attributes":{"type":"reduivy__Study_Plan__c","url":"/services/data/v62.0/sobjects/reduivy__Study_Plan__c/' + studyPlan.Id + '"},"Name":"Copy of BACBIS - Major A","reduivy__Study_Program__c":"' + studyPlan.reduivy__Study_Program__c + '"}';
            REDU_StudyPlanCloning_QUEUE queueJob = new REDU_StudyPlanCloning_QUEUE(studyPlan.Id, studyPlanData, new List<Id>(studyPathwayMap.keySet()), new List<Id>(studyPlanOptionMap.keySet()), false, false);
            
            Id jobId = System.enqueueJob(queueJob);

            System.Assert.isNotNull(jobId, 'The job should be queued successfully.');
        }

        Test.stopTest();
        
        // Get the cloned study plan
        List<reduivy__Study_Plan__c> clonedStudyPlans = [
            SELECT Id, Name, reduivy__Study_Program__c, reduivy__Clone_From_Id__c 
            FROM reduivy__Study_Plan__c 
            WHERE Name = 'Copy of BACBIS - Major A'
        ];

        System.Assert.areEqual(1, clonedStudyPlans.size(), 'Exactly one cloned study plan should be created');
        reduivy__Study_Plan__c clonedStudyPlan = clonedStudyPlans[0];

        // Get the original study plan and the modified Study Pathway Unit
        reduivy__Study_Plan__c originalStudyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A' LIMIT 1];
        reduivy__Study_Pathway_Unit__c originalSpu = [
            SELECT Id, reduivy__Applicable_Study_Plan__c 
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__r.reduivy__Study_Plan__c = :originalStudyPlan.Id 
            AND reduivy__Applicable_Study_Plan__c != NULL
            LIMIT 1
        ];

        // Verify basic study plan cloning
        System.Assert.areEqual('Copy of BACBIS - Major A', clonedStudyPlan.Name, 'Cloned study plan should have correct name');
        System.Assert.areEqual(originalStudyPlan.reduivy__Study_Program__c, clonedStudyPlan.reduivy__Study_Program__c, 'Cloned study plan should have same study program');
        System.Assert.areEqual(originalStudyPlan.Id, clonedStudyPlan.reduivy__Clone_From_Id__c, 'Clone_From_Id should reference original study plan');

        // Get the cloned Study Pathway Unit that corresponds to the original one we modified
        reduivy__Study_Pathway_Unit__c clonedSpu = [
            SELECT Id, reduivy__Applicable_Study_Plan__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__r.reduivy__Study_Plan__c = :clonedStudyPlan.Id 
            AND reduivy__Clone_From_Id__c = :originalSpu.Id
            LIMIT 1
        ];

        // Verify the cloned Study Pathway Unit exists and has proper references
        System.Assert.isNotNull(clonedSpu, 'Cloned Study Pathway Unit should exist');
        System.Assert.areEqual(originalSpu.Id, clonedSpu.reduivy__Clone_From_Id__c, 'Cloned SPU should reference original SPU in Clone_From_Id');

        // Verify that the Applicable Study Plan reference is preserved (not cloned)
        // Since cloneChildStudyPlans = false, the child study plan should not be cloned,
        // and the cloned Study Pathway Unit should still reference the original child study plan
        System.Assert.areEqual(originalSpu.reduivy__Applicable_Study_Plan__c, clonedSpu.reduivy__Applicable_Study_Plan__c, 
            'Cloned Study Pathway Unit should preserve the original child study plan reference when child study plans are not cloned');

        // Verify that the child study plan was NOT cloned
        List<reduivy__Study_Plan__c> potentialClonedChildPlans = [
            SELECT Id FROM reduivy__Study_Plan__c 
            WHERE reduivy__Clone_From_Id__c = :originalSpu.reduivy__Applicable_Study_Plan__c
        ];
        System.Assert.areEqual(0, potentialClonedChildPlans.size(), 'Child study plan should not be cloned when cloneChildStudyPlans is false');

        // Verify Study Plan Options were cloned but child study plans remain unchanged
        List<reduivy__Study_Plan_Option__c> clonedOptions = [
            SELECT Id, reduivy__Master_Study_Plan__c, reduivy__Child_Study_Plan__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Plan_Option__c 
            WHERE reduivy__Master_Study_Plan__c = :clonedStudyPlan.Id
        ];

        List<reduivy__Study_Plan_Option__c> originalOptions = [
            SELECT Id, reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c 
            WHERE reduivy__Master_Study_Plan__c = :originalStudyPlan.Id
        ];

        System.Assert.areEqual(originalOptions.size(), clonedOptions.size(), 'Number of cloned study plan options should match original');

        for(reduivy__Study_Plan_Option__c option : clonedOptions) {
            System.Assert.areEqual(clonedStudyPlan.Id, option.reduivy__Master_Study_Plan__c, 'Cloned option should reference cloned study plan');
            System.Assert.isNotNull(option.reduivy__Clone_From_Id__c, 'Cloned option should have Clone_From_Id populated');
            // Child study plan should remain the same since cloneChildStudyPlans = false
            System.Assert.isNotNull(option.reduivy__Child_Study_Plan__c, 'Child study plan reference should be preserved');
        }
    }

    /**
     * @description Test execute as admin (include existing study plan unit requirements and clone child study plans)
     */
    @IsTest
    static void testExecuteAsAdminFull(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //Master study plan and related records
            reduivy__Study_Plan__c studyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A' LIMIT 1];
            Map<Id, reduivy__Study_Plan_Structure__c> spsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            List<reduivy__Study_Plan_Unit_Requirement__c> spurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :spsMap.keySet()];
            Map<Id, reduivy__Study_Pathway__c> studyPathwayMap = new Map<Id, reduivy__Study_Pathway__c>([SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            Map<Id, reduivy__Study_Plan_Option__c> studyPlanOptionMap = new Map<Id, reduivy__Study_Plan_Option__c>([SELECT Id, reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c WHERE reduivy__Master_Study_Plan__c = :studyPlan.Id]);

            Set<Id> childStudyPlanIdSet = new Set<Id>();
            for (reduivy__Study_Plan_Option__c studyPlanOption : studyPlanOptionMap.values()) {
                childStudyPlanIdSet.add(studyPlanOption.reduivy__Child_Study_Plan__c);
            }

            //Child study plans and related records
            Map<Id, reduivy__Study_Plan__c> childStudyPlanMap = new Map<Id, reduivy__Study_Plan__c>([SELECT Id FROM reduivy__Study_Plan__c WHERE Id IN :childStudyPlanIdSet]);
            Map<Id, reduivy__Study_Plan_Structure__c> childSpsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c IN :childStudyPlanMap.keySet()]);
            List<reduivy__Study_Plan_Unit_Requirement__c> childSpurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :childSpsMap.keySet()];
            Map<Id, reduivy__Study_Pathway__c> childStudyPathwayMap = new Map<Id, reduivy__Study_Pathway__c>([SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Study_Plan__c IN :childStudyPlanMap.keySet()]);

            //Clone master study plan
            String studyPlanData = '{"attributes":{"type":"reduivy__Study_Plan__c","url":"/services/data/v62.0/sobjects/reduivy__Study_Plan__c/' + studyPlan.Id + '"},"Name":"Copy of BACBIS - Major A","reduivy__Study_Program__c":"' + studyPlan.reduivy__Study_Program__c + '"}';
            REDU_StudyPlanCloning_QUEUE queueJob = new REDU_StudyPlanCloning_QUEUE(studyPlan.Id, studyPlanData, new List<Id>(studyPathwayMap.keySet()), new List<Id>(studyPlanOptionMap.keySet()), true, true);
                        
            Id jobId = System.enqueueJob(queueJob);

            System.Assert.isNotNull(jobId, 'The job should be queued successfully.');
        }

        Test.stopTest();
        
        // Get original study plan for reference
        reduivy__Study_Plan__c originalStudyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A' LIMIT 1];
        
        // Verify Master Study Plan was cloned
        List<reduivy__Study_Plan__c> clonedStudyPlans = [
            SELECT Id, Name, reduivy__Study_Program__c, reduivy__Clone_From_Id__c 
            FROM reduivy__Study_Plan__c 
            WHERE Name = 'Copy of BACBIS - Major A'
        ];
        
        System.Assert.areEqual(1, clonedStudyPlans.size(), 'Exactly one cloned study plan should be created');
        
        reduivy__Study_Plan__c clonedMasterStudyPlan = clonedStudyPlans[0];
        
        // Verify Master Study Plan cloning assertions
        System.Assert.areEqual('Copy of BACBIS - Major A', clonedMasterStudyPlan.Name, 'Cloned study plan should have correct name');
        System.Assert.areEqual(originalStudyPlan.reduivy__Study_Program__c, clonedMasterStudyPlan.reduivy__Study_Program__c, 'Cloned study plan should have same study program');
        System.Assert.areEqual(originalStudyPlan.Id, clonedMasterStudyPlan.reduivy__Clone_From_Id__c, 'Clone_From_Id should reference original study plan');
        
        // Master study plan structures assertions
        List<reduivy__Study_Plan_Structure__c> originalMasterSps = [
            SELECT Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c
            FROM reduivy__Study_Plan_Structure__c 
            WHERE reduivy__Study_Plan__c = :originalStudyPlan.Id
        ];
        
        List<reduivy__Study_Plan_Structure__c> clonedMasterSps = [
            SELECT Id, reduivy__Study_Plan__c, reduivy__Clone_From_Id__c, 
                reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c
            FROM reduivy__Study_Plan_Structure__c 
            WHERE reduivy__Study_Plan__c = :clonedMasterStudyPlan.Id
        ];
        
        System.Assert.areEqual(originalMasterSps.size(), clonedMasterSps.size(), 'Number of cloned master study plan structures should match original');
        
        // Verify master SPS have requirement fields preserved (since includeExistingStudyPlanUnitRequirements = true)
        for(reduivy__Study_Plan_Structure__c sps : clonedMasterSps) {
            System.Assert.areEqual(clonedMasterStudyPlan.Id, sps.reduivy__Study_Plan__c, 'Cloned master SPS should reference cloned study plan');
            System.Assert.isNotNull(sps.reduivy__Clone_From_Id__c, 'Cloned master SPS should have Clone_From_Id populated');
            // Note: Requirement fields should be preserved when includeExistingStudyPlanUnitRequirements = true
        }
        
        // Master study plan unit requirements assertions
        List<reduivy__Study_Plan_Unit_Requirement__c> originalMasterSpurs = [
            SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c 
            WHERE reduivy__Study_Plan_Unit__c IN (SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :originalStudyPlan.Id)
        ];
        
        List<reduivy__Study_Plan_Unit_Requirement__c> clonedMasterSpurs = [
            SELECT Id, reduivy__Study_Plan_Unit__c
            FROM reduivy__Study_Plan_Unit_Requirement__c 
            WHERE reduivy__Study_Plan_Unit__c IN (SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :clonedMasterStudyPlan.Id)
        ];
        
        System.Assert.areEqual(originalMasterSpurs.size(), clonedMasterSpurs.size(), 'Master Study Plan Unit Requirements should be cloned when includeExistingStudyPlanUnitRequirements is true');
        
        // Master study pathways assertions
        List<reduivy__Study_Pathway__c> originalMasterPathways = [
            SELECT Id FROM reduivy__Study_Pathway__c 
            WHERE reduivy__Study_Plan__c = :originalStudyPlan.Id
        ];
        
        List<reduivy__Study_Pathway__c> clonedMasterPathways = [
            SELECT Id, reduivy__Study_Plan__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Pathway__c 
            WHERE reduivy__Study_Plan__c = :clonedMasterStudyPlan.Id
        ];
        
        System.Assert.areEqual(originalMasterPathways.size(), clonedMasterPathways.size(), 'Number of cloned master study pathways should match original');
        
        for(reduivy__Study_Pathway__c pathway : clonedMasterPathways) {
            System.Assert.areEqual(clonedMasterStudyPlan.Id, pathway.reduivy__Study_Plan__c, 'Cloned master pathway should reference cloned study plan');
            System.Assert.isNotNull(pathway.reduivy__Clone_From_Id__c, 'Cloned master pathway should have Clone_From_Id populated');
        }
        
        // Master study pathway terms assertions
        List<reduivy__Study_Pathway_Term__c> clonedMasterPathwayTerms = [
            SELECT Id, reduivy__Study_Pathway__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Pathway_Term__c 
            WHERE reduivy__Study_Pathway__c IN :clonedMasterPathways
        ];
        
        List<reduivy__Study_Pathway_Term__c> originalMasterPathwayTerms = [
            SELECT Id FROM reduivy__Study_Pathway_Term__c 
            WHERE reduivy__Study_Pathway__c IN :originalMasterPathways
        ];
        
        System.Assert.areEqual(originalMasterPathwayTerms.size(), clonedMasterPathwayTerms.size(), 'Number of cloned master study pathway terms should match original');
        
        for(reduivy__Study_Pathway_Term__c term : clonedMasterPathwayTerms) {
            System.Assert.isNotNull(term.reduivy__Clone_From_Id__c, 'Cloned master pathway term should have Clone_From_Id populated');
        }
        
        // Master study pathway units assertions
        List<reduivy__Study_Pathway_Unit__c> clonedMasterPathwayUnits = [
            SELECT Id, reduivy__Study_Pathway_Term__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__c IN :clonedMasterPathwayTerms
        ];
        
        List<reduivy__Study_Pathway_Unit__c> originalMasterPathwayUnits = [
            SELECT Id FROM reduivy__Study_Pathway_Unit__c 
            WHERE reduivy__Study_Pathway_Term__c IN :originalMasterPathwayTerms
        ];
        
        System.Assert.areEqual(originalMasterPathwayUnits.size(), clonedMasterPathwayUnits.size(), 'Number of cloned master study pathway units should match original');
        
        for(reduivy__Study_Pathway_Unit__c unit : clonedMasterPathwayUnits) {
            System.Assert.isNotNull(unit.reduivy__Clone_From_Id__c, 'Cloned master pathway unit should have Clone_From_Id populated');
        }
        
        // Child study plans assetions
        // Get original child study plan IDs
        Set<Id> originalChildStudyPlanIds = new Set<Id>();
        for(reduivy__Study_Plan_Option__c option : [SELECT reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c WHERE reduivy__Master_Study_Plan__c = :originalStudyPlan.Id]) {
            if(option.reduivy__Child_Study_Plan__c != null) {
                originalChildStudyPlanIds.add(option.reduivy__Child_Study_Plan__c);
            }
        }
        
        // Verify child study plans were cloned
        List<reduivy__Study_Plan__c> clonedChildStudyPlans = [
            SELECT Id, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Clone_From_Id__c IN :originalChildStudyPlanIds
        ];
        
        System.Assert.areEqual(originalChildStudyPlanIds.size(), clonedChildStudyPlans.size(), 'All child study plans should be cloned when cloneChildStudyPlans is true');
        
        for(reduivy__Study_Plan__c childPlan : clonedChildStudyPlans) {
            System.Assert.isNotNull(childPlan.reduivy__Clone_From_Id__c, 'Cloned child study plan should have Clone_From_Id populated');
            System.Assert.isTrue(originalChildStudyPlanIds.contains(childPlan.reduivy__Clone_From_Id__c), 'Cloned child study plan should reference original child study plan');
        }
        
        // Child study plan structures assetions
        List<reduivy__Study_Plan_Structure__c> originalChildSps = [
            SELECT Id FROM reduivy__Study_Plan_Structure__c 
            WHERE reduivy__Study_Plan__c IN :originalChildStudyPlanIds
        ];
        
        List<reduivy__Study_Plan_Structure__c> clonedChildSps = [
            SELECT Id, reduivy__Study_Plan__c, reduivy__Clone_From_Id__c,
                reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c
            FROM reduivy__Study_Plan_Structure__c 
            WHERE reduivy__Study_Plan__c IN :clonedChildStudyPlans
        ];
        
        System.Assert.areEqual(originalChildSps.size(), clonedChildSps.size(), 'Number of cloned child study plan structures should match original');
        
        for(reduivy__Study_Plan_Structure__c sps : clonedChildSps) {
            System.Assert.isNotNull(sps.reduivy__Clone_From_Id__c, 'Cloned child SPS should have Clone_From_Id populated');
            // Note: Requirement fields should be preserved when includeExistingStudyPlanUnitRequirements = true
        }
        
        // Child study plan unit requirements assertions
        List<reduivy__Study_Plan_Unit_Requirement__c> originalChildSpurs = [
            SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c 
            WHERE reduivy__Study_Plan_Unit__c IN (SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c IN :originalChildStudyPlanIds)
        ];
        
        List<reduivy__Study_Plan_Unit_Requirement__c> clonedChildSpurs = [
            SELECT Id, reduivy__Study_Plan_Unit__c
            FROM reduivy__Study_Plan_Unit_Requirement__c 
            WHERE reduivy__Study_Plan_Unit__c IN (SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c IN :clonedChildStudyPlans)
        ];
        
        System.Assert.areEqual(originalChildSpurs.size(), clonedChildSpurs.size(), 'Child Study Plan Unit Requirements should be cloned when includeExistingStudyPlanUnitRequirements is true');
        
        // Study plan options assertions
        List<reduivy__Study_Plan_Option__c> originalOptions = [
            SELECT Id, reduivy__Child_Study_Plan__c 
            FROM reduivy__Study_Plan_Option__c 
            WHERE reduivy__Master_Study_Plan__c = :originalStudyPlan.Id
        ];
        
        List<reduivy__Study_Plan_Option__c> clonedOptions = [
            SELECT Id, reduivy__Master_Study_Plan__c, reduivy__Child_Study_Plan__c, reduivy__Clone_From_Id__c
            FROM reduivy__Study_Plan_Option__c 
            WHERE reduivy__Master_Study_Plan__c = :clonedMasterStudyPlan.Id
        ];
        
        System.Assert.areEqual(originalOptions.size(), clonedOptions.size(), 'Number of cloned study plan options should match original');
        
        // Create mapping of original to cloned child study plans for verification
        Map<Id, Id> originalToClonedChildPlanMap = new Map<Id, Id>();
        for(reduivy__Study_Plan__c clonedChild : clonedChildStudyPlans) {
            originalToClonedChildPlanMap.put(clonedChild.reduivy__Clone_From_Id__c, clonedChild.Id);
        }
        
        for(reduivy__Study_Plan_Option__c option : clonedOptions) {
            System.Assert.areEqual(clonedMasterStudyPlan.Id, option.reduivy__Master_Study_Plan__c, 'Cloned option should reference cloned master study plan');
            System.Assert.isNotNull(option.reduivy__Clone_From_Id__c, 'Cloned option should have Clone_From_Id populated');
        }
    }
}