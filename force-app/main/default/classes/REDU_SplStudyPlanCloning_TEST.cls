/**
 * @author      WDCi (Jordan)
 * @date        Nov 2024
 * @group       Test
 * @description Test class for REDU_SplStudyPlanCloning_LCTRL
 * @changehistory
 * ISS-002153 15-11-2024 Jordan - new component
 * ISS-002736 25-11-2025 XiRouh - added enableWrapText param
 */
@IsTest
public inherited sharing class REDU_SplStudyPlanCloning_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static String STUDY_PLAN_EDITABLE_DETAILS_FIELD_SET_NAME = 'reduivy__StudyPlanCloning_EditableDetails';
    static String STUDY_PATHWAY_LISTING_TABLE_FIELD_SET_NAME = 'reduivy__StudyPlanCloning_ListingTable';
    static String STUDY_PLAN_OPTION_LISTING_TABLE_FIELD_SET_NAME = 'reduivy__StudyPlanCloning_ListingTable';

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
     * @description Test get study plan data as admin
     */
    @IsTest
    static void testGetStudyPlanDataAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];

            System.Assert.isTrue(String.isNotBlank(studyPlan.Id));

            REDU_LightningResponse response = REDU_SplStudyPlanCloning_LCTRL.getStudyPlanData(studyPlan.Id, STUDY_PLAN_EDITABLE_DETAILS_FIELD_SET_NAME, STUDY_PATHWAY_LISTING_TABLE_FIELD_SET_NAME, STUDY_PLAN_OPTION_LISTING_TABLE_FIELD_SET_NAME, UserInfo.getLanguage(), true);

            System.Assert.isTrue(String.isNotBlank(response.responseData));
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get study plan data as non redu user to test the exception
     */
    @IsTest
    static void testGetStudyPlanDataException(){
        
        User nonReduUser = testFactory.getSetupUser();

        reduivy__Study_Plan__c studyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];

        System.Assert.isTrue(String.isNotBlank(studyPlan.Id));

        Test.startTest();
        
        System.runAs(nonReduUser){
            
            try {
                REDU_LightningResponse response = REDU_SplStudyPlanCloning_LCTRL.getStudyPlanData(studyPlan.Id, STUDY_PLAN_EDITABLE_DETAILS_FIELD_SET_NAME, STUDY_PATHWAY_LISTING_TABLE_FIELD_SET_NAME, STUDY_PLAN_OPTION_LISTING_TABLE_FIELD_SET_NAME, UserInfo.getLanguage(), true);
                System.Assert.fail('This should fail with FLS error.');

            } catch (Exception exp) {
                REDU_Logging_UTIL.debug(exp);
                System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s) - reduivy__Study_Plan__c'), 'The exception is invalid: ' + exp.getMessage());
            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test insert study plan clone data as admin
     */
    @IsTest
    static void testInsertStudyPlanCloneDataAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //Master study plan and related records
            reduivy__Study_Plan__c studyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];
            Map<Id, reduivy__Study_Plan_Structure__c> spsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            List<reduivy__Study_Plan_Unit_Requirement__c> spurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :spsMap.keySet()];
            Map<Id, reduivy__Study_Pathway__c> studyPathwayMap = new Map<Id, reduivy__Study_Pathway__c>([SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            Map<Id, reduivy__Study_Plan_Option__c> studyPlanOptionMap = new Map<Id, reduivy__Study_Plan_Option__c>([SELECT Id, reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c WHERE reduivy__Master_Study_Plan__c = :studyPlan.Id]);

            Set<Id> childStudyPlanIdSet = new Set<Id>();
            for (reduivy__Study_Plan_Option__c studyPlanOption : studyPlanOptionMap.values()) {
                childStudyPlanIdSet.add(studyPlanOption.reduivy__Child_Study_Plan__c);
            }

            //Clone master study plan
            String studyPlanData = '{"attributes":{"type":"reduivy__Study_Plan__c","url":"/services/data/v62.0/sobjects/reduivy__Study_Plan__c/' + studyPlan.Id + '"},"Name":"Copy of BACBIS - Major A","reduivy__Study_Program__c":"' + studyPlan.reduivy__Study_Program__c + '"}';
            REDU_LightningResponse response = REDU_SplStudyPlanCloning_LCTRL.insertStudyPlanCloneData(studyPlan.Id, studyPlanData, new List<Id>(studyPathwayMap.keySet()), new List<Id>(studyPlanOptionMap.keySet()), false, false);
            System.Assert.isTrue(response.isSuccess);

            //Assert master study plan is cloned
            reduivy__Study_Plan__c clonedStudyPlan = [SELECT Name FROM reduivy__Study_Plan__c WHERE reduivy__Clone_From_Id__c = :studyPlan.Id];
            System.Assert.areEqual('Copy of ' + studyPlan.Name, clonedStudyPlan.Name);

            //Assert study plan structures are cloned
            Map<Id, reduivy__Study_Plan_Structure__c> clonedSpsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :clonedStudyPlan.Id]);
            System.Assert.areEqual(spsMap.size(), clonedSpsMap.size());

            //Assert study plan unit requirements are not cloned
            List<reduivy__Study_Plan_Unit_Requirement__c> clonedSpurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :clonedSpsMap.keySet()];
            System.Assert.areEqual(0, clonedSpurList.size());

            //Assert study pathways are cloned
            List<reduivy__Study_Pathway__c> clonedStudyPathwayList = [SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Study_Plan__c = :clonedStudyPlan.Id];
            System.Assert.areEqual(studyPathwayMap.size(), clonedStudyPathwayList.size());

            //Assert study plan options are cloned
            List<reduivy__Study_Plan_Option__c> clonedStudyPlanOptionList = [SELECT Id, reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c WHERE reduivy__Master_Study_Plan__c = :clonedStudyPlan.Id];
            System.Assert.areEqual(studyPlanOptionMap.size(), clonedStudyPlanOptionList.size());

            //Assert child study plans are not cloned
            for (reduivy__Study_Plan_Option__c clonedStudyPlanOption : clonedStudyPlanOptionList) {
                System.Assert.isTrue(childStudyPlanIdSet.contains(clonedStudyPlanOption.reduivy__Child_Study_Plan__c));
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test insert study plan clone data as admin (include existing study plan unit requirements)
     */
    @IsTest
    static void testInsertStudyPlanCloneDataAsAdminIncludeExistingStudyPlanUnitRequirements(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //Master study plan and related records
            reduivy__Study_Plan__c studyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];
            Map<Id, reduivy__Study_Plan_Structure__c> spsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            List<reduivy__Study_Plan_Unit_Requirement__c> spurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :spsMap.keySet()];
            Map<Id, reduivy__Study_Pathway__c> studyPathwayMap = new Map<Id, reduivy__Study_Pathway__c>([SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Study_Plan__c = :studyPlan.Id]);
            Map<Id, reduivy__Study_Plan_Option__c> studyPlanOptionMap = new Map<Id, reduivy__Study_Plan_Option__c>([SELECT Id, reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c WHERE reduivy__Master_Study_Plan__c = :studyPlan.Id]);

            Set<Id> childStudyPlanIdSet = new Set<Id>();
            for (reduivy__Study_Plan_Option__c studyPlanOption : studyPlanOptionMap.values()) {
                childStudyPlanIdSet.add(studyPlanOption.reduivy__Child_Study_Plan__c);
            }

            //Clone master study plan
            String studyPlanData = '{"attributes":{"type":"reduivy__Study_Plan__c","url":"/services/data/v62.0/sobjects/reduivy__Study_Plan__c/' + studyPlan.Id + '"},"Name":"Copy of BACBIS - Major A","reduivy__Study_Program__c":"' + studyPlan.reduivy__Study_Program__c + '"}';
            REDU_LightningResponse response = REDU_SplStudyPlanCloning_LCTRL.insertStudyPlanCloneData(studyPlan.Id, studyPlanData, new List<Id>(studyPathwayMap.keySet()), new List<Id>(studyPlanOptionMap.keySet()), true, false);
            System.Assert.isTrue(response.isSuccess);

            //Assert master study plan is cloned
            reduivy__Study_Plan__c clonedStudyPlan = [SELECT Name FROM reduivy__Study_Plan__c WHERE reduivy__Clone_From_Id__c = :studyPlan.Id];
            System.Assert.areEqual('Copy of ' + studyPlan.Name, clonedStudyPlan.Name);

            //Assert study plan structures are cloned
            Map<Id, reduivy__Study_Plan_Structure__c> clonedSpsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :clonedStudyPlan.Id]);
            System.Assert.areEqual(spsMap.size(), clonedSpsMap.size());

            //Assert study plan unit requirements are cloned
            List<reduivy__Study_Plan_Unit_Requirement__c> clonedSpurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :clonedSpsMap.keySet()];
            System.Assert.areEqual(spurList.size(), clonedSpurList.size());

            //Assert study pathways are cloned
            List<reduivy__Study_Pathway__c> clonedStudyPathwayList = [SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Study_Plan__c = :clonedStudyPlan.Id];
            System.Assert.areEqual(studyPathwayMap.size(), clonedStudyPathwayList.size());

            //Assert study plan options are cloned
            List<reduivy__Study_Plan_Option__c> clonedStudyPlanOptionList = [SELECT Id, reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c WHERE reduivy__Master_Study_Plan__c = :clonedStudyPlan.Id];
            System.Assert.areEqual(studyPlanOptionMap.size(), clonedStudyPlanOptionList.size());

            //Assert child study plans are not cloned
            for (reduivy__Study_Plan_Option__c clonedStudyPlanOption : clonedStudyPlanOptionList) {
                System.Assert.isTrue(childStudyPlanIdSet.contains(clonedStudyPlanOption.reduivy__Child_Study_Plan__c));
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test insert study plan clone data as admin (clone child study plans)
     */
    @IsTest
    static void testInsertStudyPlanCloneDataAsAdminCloneChildStudyPlans(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //Master study plan and related records
            reduivy__Study_Plan__c studyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];
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
            REDU_LightningResponse response = REDU_SplStudyPlanCloning_LCTRL.insertStudyPlanCloneData(studyPlan.Id, studyPlanData, new List<Id>(studyPathwayMap.keySet()), new List<Id>(studyPlanOptionMap.keySet()), false, true);
            System.Assert.isTrue(response.isSuccess);

            //Assert master study plan is cloned
            reduivy__Study_Plan__c clonedStudyPlan = [SELECT Name FROM reduivy__Study_Plan__c WHERE reduivy__Clone_From_Id__c = :studyPlan.Id];
            System.Assert.areEqual('Copy of ' + studyPlan.Name, clonedStudyPlan.Name);

            //Assert study plan structures are cloned
            Map<Id, reduivy__Study_Plan_Structure__c> clonedSpsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :clonedStudyPlan.Id]);
            System.Assert.areEqual(spsMap.size(), clonedSpsMap.size());

            //Assert study plan unit requirements are not cloned
            List<reduivy__Study_Plan_Unit_Requirement__c> clonedSpurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :clonedSpsMap.keySet()];
            System.Assert.areEqual(0, clonedSpurList.size());

            //Assert study pathways are cloned
            List<reduivy__Study_Pathway__c> clonedStudyPathwayList = [SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Study_Plan__c = :clonedStudyPlan.Id];
            System.Assert.areEqual(studyPathwayMap.size(), clonedStudyPathwayList.size());

            //Assert study plan options are cloned
            List<reduivy__Study_Plan_Option__c> clonedStudyPlanOptionList = [SELECT Id, reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c WHERE reduivy__Master_Study_Plan__c = :clonedStudyPlan.Id];
            System.Assert.areEqual(studyPlanOptionMap.size(), clonedStudyPlanOptionList.size());

            //Assert child study plans are cloned
            Set<Id> clonedChildStudyPlanIdSet = new Set<Id>();
            for (reduivy__Study_Plan_Option__c clonedStudyPlanOption : clonedStudyPlanOptionList) {
                System.Assert.isTrue(!childStudyPlanIdSet.contains(clonedStudyPlanOption.reduivy__Child_Study_Plan__c));
                clonedChildStudyPlanIdSet.add(clonedStudyPlanOption.reduivy__Child_Study_Plan__c);
            }

            Map<Id, reduivy__Study_Plan__c> clonedChildStudyPlanMap = new Map<Id, reduivy__Study_Plan__c>([SELECT Id FROM reduivy__Study_Plan__c WHERE Id IN :clonedChildStudyPlanIdSet]);
            System.Assert.areEqual(childStudyPlanMap.size(), clonedChildStudyPlanMap.size());

            //Assert child study plan structures are cloned
            Map<Id, reduivy__Study_Plan_Structure__c> clonedChildSpsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c IN :clonedChildStudyPlanMap.keySet()]);
            System.Assert.areEqual(childSpsMap.size(), clonedChildSpsMap.size());

            //Assert child study plan unit requirements are not cloned
            List<reduivy__Study_Plan_Unit_Requirement__c> clonedChildSpurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :clonedSpsMap.keySet()];
            System.Assert.areEqual(0, clonedChildSpurList.size());
        }

        Test.stopTest();
        
    }

    /**
     * @description Test insert study plan clone data as admin (include existing study plan unit requirements and clone child study plans)
     */
    @IsTest
    static void testInsertStudyPlanCloneDataAsAdminFull(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            //Master study plan and related records
            reduivy__Study_Plan__c studyPlan = [SELECT Id, Name, reduivy__Study_Program__c FROM reduivy__Study_Plan__c WHERE Name = 'BACBIS - Major A'];
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
            REDU_LightningResponse response = REDU_SplStudyPlanCloning_LCTRL.insertStudyPlanCloneData(studyPlan.Id, studyPlanData, new List<Id>(studyPathwayMap.keySet()), new List<Id>(studyPlanOptionMap.keySet()), true, true);
            System.Assert.isTrue(response.isSuccess);

            //Assert master study plan is cloned
            reduivy__Study_Plan__c clonedStudyPlan = [SELECT Name FROM reduivy__Study_Plan__c WHERE reduivy__Clone_From_Id__c = :studyPlan.Id];
            System.Assert.areEqual('Copy of ' + studyPlan.Name, clonedStudyPlan.Name);

            //Assert study plan structures are cloned
            Map<Id, reduivy__Study_Plan_Structure__c> clonedSpsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c = :clonedStudyPlan.Id]);
            System.Assert.areEqual(spsMap.size(), clonedSpsMap.size());

            //Assert study plan unit requirements are cloned
            List<reduivy__Study_Plan_Unit_Requirement__c> clonedSpurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :clonedSpsMap.keySet()];
            System.Assert.areEqual(spurList.size(), clonedSpurList.size());

            //Assert study pathways are cloned
            List<reduivy__Study_Pathway__c> clonedStudyPathwayList = [SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Study_Plan__c = :clonedStudyPlan.Id];
            System.Assert.areEqual(studyPathwayMap.size(), clonedStudyPathwayList.size());

            //Assert study plan options are cloned
            List<reduivy__Study_Plan_Option__c> clonedStudyPlanOptionList = [SELECT Id, reduivy__Child_Study_Plan__c FROM reduivy__Study_Plan_Option__c WHERE reduivy__Master_Study_Plan__c = :clonedStudyPlan.Id];
            System.Assert.areEqual(studyPlanOptionMap.size(), clonedStudyPlanOptionList.size());

            //Assert child study plans are cloned
            Set<Id> clonedChildStudyPlanIdSet = new Set<Id>();
            for (reduivy__Study_Plan_Option__c clonedStudyPlanOption : clonedStudyPlanOptionList) {
                System.Assert.isTrue(!childStudyPlanIdSet.contains(clonedStudyPlanOption.reduivy__Child_Study_Plan__c));
                clonedChildStudyPlanIdSet.add(clonedStudyPlanOption.reduivy__Child_Study_Plan__c);
            }

            Map<Id, reduivy__Study_Plan__c> clonedChildStudyPlanMap = new Map<Id, reduivy__Study_Plan__c>([SELECT Id FROM reduivy__Study_Plan__c WHERE Id IN :clonedChildStudyPlanIdSet]);
            System.Assert.areEqual(childStudyPlanMap.size(), clonedChildStudyPlanMap.size());

            //Assert child study plan structures are cloned
            Map<Id, reduivy__Study_Plan_Structure__c> clonedChildSpsMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Plan__c IN :clonedChildStudyPlanMap.keySet()]);
            System.Assert.areEqual(childSpsMap.size(), clonedChildSpsMap.size());

            //Assert child study plan unit requirements are not cloned
            List<reduivy__Study_Plan_Unit_Requirement__c> clonedChildSpurList = [SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Study_Plan_Unit__c IN :clonedChildSpsMap.keySet()];
            System.Assert.areEqual(childSpurList.size(), clonedChildSpurList.size());
        }

        Test.stopTest();
        
    }
}