/**
 * @author      WDCi (XW)
 * @date        Feb 2026
 * @group       Test
 * @description Test class for REDU_StudentAchievementItem_LCTRL
 * @changehistory
 * ISS-002633 03-02-2026 XW - new class
 */
@IsTest
public inherited sharing class REDU_StudentAchievementItem_TEST {

    static final String CON_SRC = 'sandydoe@redu.example';
    static final String ARU_SRC = 'ARU_Introduction_to_Business_Studies';
    static final String IAC_SRC = CON_SRC + 'Individual_Achievement';
    static final String IAU_SRC = IAC_SRC + '_' + ARU_SRC;

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
        	
            testFactory.initMasterData(SPO_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initStudentData(IRQ_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for getting individual achievement units
     */
    @IsTest
    static void testForGetIndividualRequirementSets_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        reduivy__Individual_Achievement__c iac = queryIac();
        List<reduivy__Individual_Requirement_Set__c> expectedIrsList = queryIrsList();
        Map<Id, reduivy__Individual_Requirement_Set__c> expectedIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>(expectedIrsList);

		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudentAchievementItem_LCTRL.getIndividualRequirementSets(iac.Id);
            List<reduivy__Individual_Requirement_Set__c> actualIrsList = (List<reduivy__Individual_Requirement_Set__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Requirement_Set__c>.class);
            Map<Id, reduivy__Individual_Requirement_Set__c> actualIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>(actualIrsList);
            System.Assert.areEqual(expectedIrsMap.size(), actualIrsMap.size(), 'Wrong irs list size!');
            System.Assert.isTrue(expectedIrsMap.keySet().containsAll(actualIrsMap.keySet()), 'Wrong irs contents! Expected: ' + JSON.serialize(expectedIrsMap) + ' Actual: ' + JSON.serialize(actualIrsMap));
            for(Id actualIrsId : actualIrsMap.keySet()) {
                reduivy__Individual_Requirement_Set__c actualIrs = actualIrsMap.get(actualIrsId);
                reduivy__Individual_Requirement_Set__c expectedIrs = expectedIrsMap.get(actualIrsId);
                
                System.Assert.areEqual(expectedIrs.reduivy__Total_Requirement__c, actualIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c value!');
                System.Assert.areEqual(expectedIrs.reduivy__Total_Requirement_Student__c, actualIrs.reduivy__Total_Requirement_Student__c, 'Wrong reduivy__Total_Requirement_Student__c value!');
                System.Assert.areEqual(expectedIrs.reduivy__Total_Reviewed__c, actualIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c value!');
                System.Assert.areEqual(expectedIrs.reduivy__Total_Reviewed_Student__c, actualIrs.reduivy__Total_Reviewed_Student__c, 'Wrong reduivy__Total_Reviewed_Student__c value!');
                System.Assert.areEqual(expectedIrs.reduivy__Total_Submitted__c, actualIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c value!');
                System.Assert.areEqual(expectedIrs.reduivy__Total_Submitted_Student__c, actualIrs.reduivy__Total_Submitted_Student__c, 'Wrong reduivy__Total_Submitted_Student__c value!');

            }
		}

        Test.stopTest();
    }
    
	
    /**
     * @description Test as admin for getting individual achievement units
     */
    @IsTest
    static void testForGetIndividualRequirementSets_EmptyIac_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudentAchievementItem_LCTRL.getIndividualRequirementSets(null);
            List<reduivy__Individual_Requirement_Set__c> actualIrsList = (List<reduivy__Individual_Requirement_Set__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Requirement_Set__c>.class);
            Map<Id, reduivy__Individual_Requirement_Set__c> actualIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>(actualIrsList);
            System.Assert.isTrue(actualIrsMap.isEmpty(), 'irs should be empty! Actual: ' + JSON.serialize(actualIrsMap));
		}

        Test.stopTest();
    }
    
    /**
     * @description Test as faculty for getting individual achievement units
     */
    @IsTest
    static void testForGetIndividualRequirementSets_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        reduivy__Individual_Achievement__c iac = queryIac();
        List<reduivy__Individual_Requirement_Set__c> expectedIrsList = queryIrsList();
        Map<Id, reduivy__Individual_Requirement_Set__c> expectedIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>(expectedIrsList);

		System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_StudentAchievementItem_LCTRL.getIndividualRequirementSets(iac.Id);
            List<reduivy__Individual_Requirement_Set__c> actualIrsList = (List<reduivy__Individual_Requirement_Set__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Requirement_Set__c>.class);
            Map<Id, reduivy__Individual_Requirement_Set__c> actualIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>(actualIrsList);
            System.Assert.areEqual(expectedIrsMap.size(), actualIrsMap.size(), 'Wrong irs list size!');
            System.Assert.isTrue(expectedIrsMap.keySet().containsAll(actualIrsMap.keySet()), 'Wrong irs contents! Expected: ' + JSON.serialize(expectedIrsMap) + ' Actual: ' + JSON.serialize(actualIrsMap));
            for(Id actualIrsId : actualIrsMap.keySet()) {
                reduivy__Individual_Requirement_Set__c actualIrs = actualIrsMap.get(actualIrsId);
                reduivy__Individual_Requirement_Set__c expectedIrs = expectedIrsMap.get(actualIrsId);
                
                System.Assert.areEqual(expectedIrs.reduivy__Total_Requirement__c, actualIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c value!');
                System.Assert.areEqual(expectedIrs.reduivy__Total_Requirement_Student__c, actualIrs.reduivy__Total_Requirement_Student__c, 'Wrong reduivy__Total_Requirement_Student__c value!');
                System.Assert.areEqual(expectedIrs.reduivy__Total_Reviewed__c, actualIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c value!');
                System.Assert.areEqual(expectedIrs.reduivy__Total_Reviewed_Student__c, actualIrs.reduivy__Total_Reviewed_Student__c, 'Wrong reduivy__Total_Reviewed_Student__c value!');
                System.Assert.areEqual(expectedIrs.reduivy__Total_Submitted__c, actualIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c value!');
                System.Assert.areEqual(expectedIrs.reduivy__Total_Submitted_Student__c, actualIrs.reduivy__Total_Submitted_Student__c, 'Wrong reduivy__Total_Submitted_Student__c value!');

            }
		}

        Test.stopTest();
    }
    
	
    /**
     * @description Test as faculty for getting individual achievement units
     */
    @IsTest
    static void testForGetIndividualRequirementSets_EmptyIac_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_StudentAchievementItem_LCTRL.getIndividualRequirementSets(null);
            List<reduivy__Individual_Requirement_Set__c> actualIrsList = (List<reduivy__Individual_Requirement_Set__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Requirement_Set__c>.class);
            Map<Id, reduivy__Individual_Requirement_Set__c> actualIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>(actualIrsList);
            System.Assert.isTrue(actualIrsMap.isEmpty(), 'irs should be empty! Actual: ' + JSON.serialize(actualIrsMap));
		}

        Test.stopTest();
    }
    
    /**
     * @description Test as student for getting individual achievement units
     */
    @IsTest
    static void testForGetIndividualRequirementSets_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        reduivy__Individual_Achievement__c iac = queryIac();
        List<reduivy__Individual_Requirement_Set__c> expectedIrsList = queryIrsList();
        Map<Id, reduivy__Individual_Requirement_Set__c> expectedIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>(expectedIrsList);

		System.runAs(studentUser){
            REDU_LightningResponse response = REDU_StudentAchievementItem_LCTRL.getIndividualRequirementSets(iac.Id);
            List<reduivy__Individual_Requirement_Set__c> actualIrsList = (List<reduivy__Individual_Requirement_Set__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Requirement_Set__c>.class);
            Map<Id, reduivy__Individual_Requirement_Set__c> actualIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>(actualIrsList);
            System.Assert.areEqual(expectedIrsMap.size(), actualIrsMap.size(), 'Wrong irs list size!');
            System.Assert.isTrue(expectedIrsMap.keySet().containsAll(actualIrsMap.keySet()), 'Wrong irs contents! Expected: ' + JSON.serialize(expectedIrsMap) + ' Actual: ' + JSON.serialize(actualIrsMap));
            for(Id actualIrsId : actualIrsMap.keySet()) {
                reduivy__Individual_Requirement_Set__c actualIrs = actualIrsMap.get(actualIrsId);
                reduivy__Individual_Requirement_Set__c expectedIrs = expectedIrsMap.get(actualIrsId);
                
                System.Assert.areEqual(expectedIrs.reduivy__Total_Requirement__c, actualIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c value!');
                System.Assert.areEqual(expectedIrs.reduivy__Total_Requirement_Student__c, actualIrs.reduivy__Total_Requirement_Student__c, 'Wrong reduivy__Total_Requirement_Student__c value!');
                System.Assert.areEqual(expectedIrs.reduivy__Total_Reviewed__c, actualIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c value!');
                System.Assert.areEqual(expectedIrs.reduivy__Total_Reviewed_Student__c, actualIrs.reduivy__Total_Reviewed_Student__c, 'Wrong reduivy__Total_Reviewed_Student__c value!');
                System.Assert.areEqual(expectedIrs.reduivy__Total_Submitted__c, actualIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c value!');
                System.Assert.areEqual(expectedIrs.reduivy__Total_Submitted_Student__c, actualIrs.reduivy__Total_Submitted_Student__c, 'Wrong reduivy__Total_Submitted_Student__c value!');

            }
		}

        Test.stopTest();
    }
    
	
    /**
     * @description Test as student for getting individual achievement units
     */
    @IsTest
    static void testForGetIndividualRequirementSets_EmptyIac_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
		System.runAs(studentUser){
            REDU_LightningResponse response = REDU_StudentAchievementItem_LCTRL.getIndividualRequirementSets(null);
            List<reduivy__Individual_Requirement_Set__c> actualIrsList = (List<reduivy__Individual_Requirement_Set__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Requirement_Set__c>.class);
            Map<Id, reduivy__Individual_Requirement_Set__c> actualIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>(actualIrsList);
            System.Assert.isTrue(actualIrsMap.isEmpty(), 'irs should be empty! Actual: ' + JSON.serialize(actualIrsMap));
		}

        Test.stopTest();
    }
    
    static reduivy__Individual_Achievement__c queryIac(){
        return [
            SELECT Id, reduivy__Verification_Status__c, reduivy__Submission_Date__c
            FROM reduivy__Individual_Achievement__c 
            WHERE reduivy__Sample_Record_Code__c = :IAC_SRC
        ];
    }

    static List<reduivy__Individual_Requirement_Set__c> queryIrsList(){
        return [
            SELECT Id, Name,
            reduivy__Total_Requirement__c,
            reduivy__Total_Requirement_Student__c,
            reduivy__Total_Reviewed__c,
            reduivy__Total_Reviewed_Student__c,
            reduivy__Total_Submitted__c,
            reduivy__Total_Submitted_Student__c
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Achievement__r.reduivy__Sample_Record_Code__c = :IAC_SRC
        ];
    }

}