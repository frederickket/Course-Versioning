/**
 * @author      WDCi (XW)
 * @date        Feb 2026
 * @group       Test
 * @description Test class for REDU_WizardConfigManager
 * @changehistory
 * ISS-002633 03-02-2026 XW - new class
 */
@IsTest
public inherited sharing class REDU_WizardConfigManager_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
        testFactory.setupDefaultSettings();
        testFactory.initStudentData(USR_Helper.getApiName(), true);
        testFactory.initFacultyData(USR_Helper.getApiName(), true);

    }
	
    /**
     * @description Test as admin for getting wizard configs map
     */
    @IsTest
    static void testForGetWizardConfigs_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            Map<Id, reduivy__Wizard_Config__mdt> wizardConfigsMap = REDU_WizardConfigManager.getWizardConfigsMap();
            System.Assert.areEqual(reduivy__Wizard_Config__mdt.getAll().values().size(), wizardConfigsMap.size(), 'Should be the same size!');
		}

        Test.stopTest();
		
    }
	
	
    /**
     * @description Test as faculty for getting wizard configs map
     */
    @IsTest
    static void testForGetWizardConfigs_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            Map<Id, reduivy__Wizard_Config__mdt> wizardConfigsMap = REDU_WizardConfigManager.getWizardConfigsMap();
            System.Assert.areEqual(reduivy__Wizard_Config__mdt.getAll().values().size(), wizardConfigsMap.size(), 'Should be the same size!');
		}

        Test.stopTest();
		
    }
    
	
    /**
     * @description Test as student for getting wizard configs map
     */
    @IsTest
    static void testForGetWizardConfigs_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
		System.runAs(studentUser){
            Map<Id, reduivy__Wizard_Config__mdt> wizardConfigsMap = REDU_WizardConfigManager.getWizardConfigsMap();
            System.Assert.areEqual(reduivy__Wizard_Config__mdt.getAll().values().size(), wizardConfigsMap.size(), 'Should be the same size!');
		}

        Test.stopTest();
		
    }
}