/**
 * @author      WDCi (XW)
 * @date        Jan 2026
 * @group       Test
 * @description Test class for REDU_StudentAchievementSubmit_LCTRL
 * @changehistory
 * ISS-002633 27-01-2026 XW - new class
 */
@IsTest
public inherited sharing class REDU_StudentAchievementSubmit_TEST {

    static final String CON_SRC = 'sandydoe@redu.example';
    static final String ARU_SRC = 'ARU_Introduction_to_Business_Studies';
    static final String IAC_SRC = CON_SRC + 'Individual_Achievement';
    static final String IAU_SRC = IAC_SRC + '_' + ARU_SRC;

    static List<String> IAC_SUBMITTED_STATUSES = IAC_Helper.getSubmittedVerificationStatuses();
    static List<String> IAU_SUBMITTED_STATUSES = IAU_Helper.getSubmittedVerificationStatuses();

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
        	
            testFactory.initMasterData(ARU_Helper.getApiName());
            testFactory.initStudentData(IAU_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for updating iac and iau to submitted
     */
    @IsTest
    static void testForupdateIndividualAchievementIndividualAchievementUnitToSubmitted_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            reduivy__Individual_Achievement_Unit__c iau = queryIau();
            reduivy__Individual_Achievement__c iac = iau.reduivy__Individual_Achievement__r;

            System.Assert.isFalse(IAC_SUBMITTED_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iac.reduivy__Verification_Status__c);
            System.Assert.isFalse(IAU_SUBMITTED_STATUSES.contains(iau.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iau.reduivy__Verification_Status__c);

            REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.updateIndividualAchievementIndividualAchievementUnitToSubmitted(iac.Id);

            iau = queryIau();
            iac = iau.reduivy__Individual_Achievement__r;
            
            System.Assert.isTrue(IAC_SUBMITTED_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be submitted! Actual: ' + iac.reduivy__Verification_Status__c);
            System.Assert.isTrue(IAU_SUBMITTED_STATUSES.contains(iau.reduivy__Verification_Status__c), 'Verification status should be submitted! Actual: ' + iau.reduivy__Verification_Status__c);

		}

        Test.stopTest();
		
    }

	
    /**
     * @description Test as admin for updating with empty id
     */
    @IsTest
    static void testForupdateIndividualAchievementIndividualAchievementUnitToSubmitted_WithoutId_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            reduivy__Individual_Achievement_Unit__c iau = queryIau();
            reduivy__Individual_Achievement__c iac = iau.reduivy__Individual_Achievement__r;

            System.Assert.isFalse(IAC_SUBMITTED_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iac.reduivy__Verification_Status__c);
            System.Assert.isFalse(IAU_SUBMITTED_STATUSES.contains(iau.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iau.reduivy__Verification_Status__c);

            REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.updateIndividualAchievementIndividualAchievementUnitToSubmitted(null);

            iau = queryIau();
            iac = iau.reduivy__Individual_Achievement__r;
            
            System.Assert.isFalse(IAC_SUBMITTED_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iac.reduivy__Verification_Status__c);
            System.Assert.isFalse(IAU_SUBMITTED_STATUSES.contains(iau.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iau.reduivy__Verification_Status__c);
		}

        Test.stopTest();
    }
	
    /**
     * @description Test as admin for getting IndividualAchievementUnits
     */
    @IsTest
    static void testForGetIndividualAchievementUnits_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            reduivy__Individual_Achievement__c iac = queryIac();
            System.Assert.areEqual(1, iac.reduivy__Individual_Achievement_Units__r.size(), 'Wrong child iau size!');
            
            REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.getIndividualAchievementUnits(iac.Id, null);
            List<reduivy__Individual_Achievement_Unit__c> actualIauList = (List<reduivy__Individual_Achievement_Unit__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Achievement_Unit__c>.class);
            System.Assert.areEqual(1, actualIauList.size(), 'Wrong actual child iau size!');
            
		}

        Test.stopTest();
    }
	
    /**
     * @description Test as admin for getting IndividualAchievementUnits, no iac id
     */
    @IsTest
    static void testForGetIndividualAchievementUnits_NoIacId_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            reduivy__Individual_Achievement__c iac = queryIac();
            System.Assert.areEqual(1, iac.reduivy__Individual_Achievement_Units__r.size(), 'Wrong child iau size!');
            
            REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.getIndividualAchievementUnits(null, null);
            List<reduivy__Individual_Achievement_Unit__c> actualIauList = (List<reduivy__Individual_Achievement_Unit__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Achievement_Unit__c>.class);
            System.Assert.areEqual(0, actualIauList.size(), 'Actual child iau list should be empty!');
            
		}

        Test.stopTest();
    }
	
    /**
     * @description Test as admin for getting IndividualAchievementUnits, WithAdditionalFields
     */
    @IsTest
    static void testForGetIndividualAchievementUnits_WithAdditionalFields_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            reduivy__Individual_Achievement__c iac = queryIac();
            System.Assert.areEqual(1, iac.reduivy__Individual_Achievement_Units__r.size(), 'Wrong child iau size!');
            
            REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.getIndividualAchievementUnits(iac.Id, new List<String> {'reduivy__Agreement_Recognition_Unit__c'});
            List<reduivy__Individual_Achievement_Unit__c> actualIauList = (List<reduivy__Individual_Achievement_Unit__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Achievement_Unit__c>.class);
            System.Assert.areEqual(1, actualIauList.size(), 'Wrong actual child iau size!');

            System.Assert.isNotNull(actualIauList[0].reduivy__Agreement_Recognition_Unit__c, 'Agreement Recognition unit should be queried!');
            
		}

        Test.stopTest();
    }
	
	
    /**
     * @description Test as admin for getting IndividualAchievementUnits, WithInvalidFields
     */
    @IsTest
    static void testForGetIndividualAchievementUnits_WithInvalidFields_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            reduivy__Individual_Achievement__c iac = queryIac();
            System.Assert.areEqual(1, iac.reduivy__Individual_Achievement_Units__r.size(), 'Wrong child iau size!');
            
            try {
                REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.getIndividualAchievementUnits(iac.Id, new List<String> {'invalidfield'});
                System.Assert.fail('Should have failed due to invalid field!');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('No such column \'invalidfield\''), 'Wrong exception message! Actual:' + exp.getMessage());   
            }
		}

        Test.stopTest();
    }
	

    /**
     * @description Test as faculty for updating iac and iau to submitted
     */
    @IsTest
    static void testForupdateIndividualAchievementIndividualAchievementUnitToSubmitted_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            reduivy__Individual_Achievement_Unit__c iau = queryIau();
            reduivy__Individual_Achievement__c iac = iau.reduivy__Individual_Achievement__r;

            System.Assert.isFalse(IAC_SUBMITTED_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iac.reduivy__Verification_Status__c);
            System.Assert.isFalse(IAU_SUBMITTED_STATUSES.contains(iau.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iau.reduivy__Verification_Status__c);

            try {
                REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.updateIndividualAchievementIndividualAchievementUnitToSubmitted(iac.Id);
                System.Assert.fail('Should be fail due to Insufficient UPDATABLE access!');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Insufficient UPDATABLE access'), 'Wrong exception message! Actual: ' + exp.getMessage());
            }
		}

        Test.stopTest();
		
    }

	
    /**
     * @description Test as faculty for updating with empty id
     */
    @IsTest
    static void testForupdateIndividualAchievementIndividualAchievementUnitToSubmitted_WithoutId_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            reduivy__Individual_Achievement_Unit__c iau = queryIau();
            reduivy__Individual_Achievement__c iac = iau.reduivy__Individual_Achievement__r;

            System.Assert.isFalse(IAC_SUBMITTED_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iac.reduivy__Verification_Status__c);
            System.Assert.isFalse(IAU_SUBMITTED_STATUSES.contains(iau.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iau.reduivy__Verification_Status__c);

            REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.updateIndividualAchievementIndividualAchievementUnitToSubmitted(null);

            iau = queryIau();
            iac = iau.reduivy__Individual_Achievement__r;
            
            System.Assert.isFalse(IAC_SUBMITTED_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iac.reduivy__Verification_Status__c);
            System.Assert.isFalse(IAU_SUBMITTED_STATUSES.contains(iau.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iau.reduivy__Verification_Status__c);
		}

        Test.stopTest();
    }

	
    /**
     * @description Test as faculty for getting IndividualAchievementUnits
     */
    @IsTest
    static void testForGetIndividualAchievementUnits_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            reduivy__Individual_Achievement__c iac = queryIac();
            System.Assert.areEqual(1, iac.reduivy__Individual_Achievement_Units__r.size(), 'Wrong child iau size!');
            
            REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.getIndividualAchievementUnits(iac.Id, null);
            List<reduivy__Individual_Achievement_Unit__c> actualIauList = (List<reduivy__Individual_Achievement_Unit__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Achievement_Unit__c>.class);
            System.Assert.areEqual(1, actualIauList.size(), 'Wrong actual child iau size!');
            
		}

        Test.stopTest();
    }
	
    /**
     * @description Test as faculty for getting IndividualAchievementUnits, no iac id
     */
    @IsTest
    static void testForGetIndividualAchievementUnits_NoIacId_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            reduivy__Individual_Achievement__c iac = queryIac();
            System.Assert.areEqual(1, iac.reduivy__Individual_Achievement_Units__r.size(), 'Wrong child iau size!');
            
            REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.getIndividualAchievementUnits(null, null);
            List<reduivy__Individual_Achievement_Unit__c> actualIauList = (List<reduivy__Individual_Achievement_Unit__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Achievement_Unit__c>.class);
            System.Assert.areEqual(0, actualIauList.size(), 'Actual child iau list should be empty!');
            
		}

        Test.stopTest();
    }
	
    /**
     * @description Test as faculty for getting IndividualAchievementUnits, WithAdditionalFields
     */
    @IsTest
    static void testForGetIndividualAchievementUnits_WithAdditionalFields_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            reduivy__Individual_Achievement__c iac = queryIac();
            System.Assert.areEqual(1, iac.reduivy__Individual_Achievement_Units__r.size(), 'Wrong child iau size!');
            
            REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.getIndividualAchievementUnits(iac.Id, new List<String> {'reduivy__Agreement_Recognition_Unit__c'});
            List<reduivy__Individual_Achievement_Unit__c> actualIauList = (List<reduivy__Individual_Achievement_Unit__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Achievement_Unit__c>.class);
            System.Assert.areEqual(1, actualIauList.size(), 'Wrong actual child iau size!');

            System.Assert.isNotNull(actualIauList[0].reduivy__Agreement_Recognition_Unit__c, 'Agreement Recognition unit should be queried!');
            
		}

        Test.stopTest();
    }
	
	
    /**
     * @description Test as faculty for getting IndividualAchievementUnits, WithInvalidFields
     */
    @IsTest
    static void testForGetIndividualAchievementUnits_WithInvalidFields_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            reduivy__Individual_Achievement__c iac = queryIac();
            System.Assert.areEqual(1, iac.reduivy__Individual_Achievement_Units__r.size(), 'Wrong child iau size!');
            
            try {
                REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.getIndividualAchievementUnits(iac.Id, new List<String> {'invalidfield'});
                System.Assert.fail('Should have failed due to invalid field!');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('No such column \'invalidfield\''), 'Wrong exception message! Actual:' + exp.getMessage());   
            }
		}

        Test.stopTest();
    }
	

	
    /**
     * @description Test as student for updating iac and iau to submitted
     */
    @IsTest
    static void testForupdateIndividualAchievementIndividualAchievementUnitToSubmitted_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
		System.runAs(studentUser){
            reduivy__Individual_Achievement_Unit__c iau = queryIau();
            reduivy__Individual_Achievement__c iac = iau.reduivy__Individual_Achievement__r;

            System.Assert.isFalse(IAC_SUBMITTED_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iac.reduivy__Verification_Status__c);
            System.Assert.isFalse(IAU_SUBMITTED_STATUSES.contains(iau.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iau.reduivy__Verification_Status__c);

            REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.updateIndividualAchievementIndividualAchievementUnitToSubmitted(iac.Id);

            iau = queryIau();
            iac = iau.reduivy__Individual_Achievement__r;
            
            System.Assert.isTrue(IAC_SUBMITTED_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be submitted! Actual: ' + iac.reduivy__Verification_Status__c);
            System.Assert.isTrue(IAU_SUBMITTED_STATUSES.contains(iau.reduivy__Verification_Status__c), 'Verification status should be submitted! Actual: ' + iau.reduivy__Verification_Status__c);

		}

        Test.stopTest();
		
    }

	
    /**
     * @description Test as student for updating with empty id
     */
    @IsTest
    static void testForupdateIndividualAchievementIndividualAchievementUnitToSubmitted_WithoutId_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
		System.runAs(studentUser){
            reduivy__Individual_Achievement_Unit__c iau = queryIau();
            reduivy__Individual_Achievement__c iac = iau.reduivy__Individual_Achievement__r;

            System.Assert.isFalse(IAC_SUBMITTED_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iac.reduivy__Verification_Status__c);
            System.Assert.isFalse(IAU_SUBMITTED_STATUSES.contains(iau.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iau.reduivy__Verification_Status__c);

            REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.updateIndividualAchievementIndividualAchievementUnitToSubmitted(null);

            iau = queryIau();
            iac = iau.reduivy__Individual_Achievement__r;
            
            System.Assert.isFalse(IAC_SUBMITTED_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iac.reduivy__Verification_Status__c);
            System.Assert.isFalse(IAU_SUBMITTED_STATUSES.contains(iau.reduivy__Verification_Status__c), 'Verification status should NOT be submitted! Actual: ' + iau.reduivy__Verification_Status__c);
		}

        Test.stopTest();
    }

	
    /**
     * @description Test as student for getting IndividualAchievementUnits
     */
    @IsTest
    static void testForGetIndividualAchievementUnits_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
		System.runAs(studentUser){
            reduivy__Individual_Achievement__c iac = queryIac();
            System.Assert.areEqual(1, iac.reduivy__Individual_Achievement_Units__r.size(), 'Wrong child iau size!');
            
            REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.getIndividualAchievementUnits(iac.Id, null);
            List<reduivy__Individual_Achievement_Unit__c> actualIauList = (List<reduivy__Individual_Achievement_Unit__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Achievement_Unit__c>.class);
            System.Assert.areEqual(1, actualIauList.size(), 'Wrong actual child iau size!');
            
		}

        Test.stopTest();
    }
	
    /**
     * @description Test as student for getting IndividualAchievementUnits, no iac id
     */
    @IsTest
    static void testForGetIndividualAchievementUnits_NoIacId_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
		System.runAs(studentUser){
            reduivy__Individual_Achievement__c iac = queryIac();
            System.Assert.areEqual(1, iac.reduivy__Individual_Achievement_Units__r.size(), 'Wrong child iau size!');
            
            REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.getIndividualAchievementUnits(null, null);
            List<reduivy__Individual_Achievement_Unit__c> actualIauList = (List<reduivy__Individual_Achievement_Unit__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Achievement_Unit__c>.class);
            System.Assert.areEqual(0, actualIauList.size(), 'Actual child iau list should be empty!');
            
		}

        Test.stopTest();
    }
	
    /**
     * @description Test as student for getting IndividualAchievementUnits, WithAdditionalFields
     */
    @IsTest
    static void testForGetIndividualAchievementUnits_WithAdditionalFields_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
		System.runAs(studentUser){
            reduivy__Individual_Achievement__c iac = queryIac();
            System.Assert.areEqual(1, iac.reduivy__Individual_Achievement_Units__r.size(), 'Wrong child iau size!');
            
            REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.getIndividualAchievementUnits(iac.Id, new List<String> {'reduivy__Agreement_Recognition_Unit__c'});
            List<reduivy__Individual_Achievement_Unit__c> actualIauList = (List<reduivy__Individual_Achievement_Unit__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Achievement_Unit__c>.class);
            System.Assert.areEqual(1, actualIauList.size(), 'Wrong actual child iau size!');

            System.Assert.isNotNull(actualIauList[0].reduivy__Agreement_Recognition_Unit__c, 'Agreement Recognition unit should be queried!');
            
		}

        Test.stopTest();
    }
	
	
    /**
     * @description Test as student for getting IndividualAchievementUnits, WithInvalidFields
     */
    @IsTest
    static void testForGetIndividualAchievementUnits_WithInvalidFields_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
		System.runAs(studentUser){
            reduivy__Individual_Achievement__c iac = queryIac();
            System.Assert.areEqual(1, iac.reduivy__Individual_Achievement_Units__r.size(), 'Wrong child iau size!');
            
            try {
                REDU_LightningResponse response = REDU_StudentAchievementSubmit_LCTRL.getIndividualAchievementUnits(iac.Id, new List<String> {'invalidfield'});
                System.Assert.fail('Should have failed due to invalid field!');
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('No such column \'invalidfield\''), 'Wrong exception message! Actual:' + exp.getMessage());   
            }
		}

        Test.stopTest();
    }
	


    static reduivy__Individual_Achievement_Unit__c queryIau() {
        return [
            SELECT 
            Id,
            Name,
            reduivy__Verification_Status__c,
            reduivy__Individual_Achievement__c,
            reduivy__Individual_Achievement__r.Name,
            reduivy__Individual_Achievement__r.reduivy__Verification_Status__c
            FROM reduivy__Individual_Achievement_Unit__c
            WHERE reduivy__Sample_Record_Code__c = :IAU_SRC
            LIMIT 1
        ];
    }

    static reduivy__Individual_Achievement__c queryIac() {
        return [
            SELECT
            Id,
            Name,
            (
                SELECT Id, Name
                FROM reduivy__Individual_Achievement_Units__r
            )
            FROM reduivy__Individual_Achievement__c
            WHERE reduivy__Sample_Record_Code__c = :IAC_SRC
            LIMIT 1
        ];
    }
    
	
}