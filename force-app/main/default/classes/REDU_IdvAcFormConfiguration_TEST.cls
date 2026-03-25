/**
 * @author      WDCi (XW)
 * @date        Feb 2026
 * @group       Test
 * @description Test class for REDU_IdvAcFormConfiguration_VEDP
 * @changehistory
 * ISS-002633 03-02-2026 XW - new class
 */
@IsTest
public inherited sharing class REDU_IdvAcFormConfiguration_TEST {

    static final Map<String, List<IAC_Helper.IdvAcWizardFormWrapper>> IdvAcWizardFormGroupByWizardConfigName = IAC_Helper.getIdvAcWizardFormGroupByWizardConfigName();
    static final Map<Id, reduivy__Wizard_Config__mdt> WIZARD_CONFIGS_MAP = REDU_WizardConfigManager.getWizardConfigsMap();
    static final String IDVAC_WIZARD_FORM_CONFIG_LABEL = 'IdvAc Wizard Form Config';
    
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

        testFactory.initStudentData(USR_Helper.getApiName(), true);
    }
	
    /**
     * @description Test as admin for getting all the selectable value of the picklist
     */
    @IsTest
    static void testGetValue_AsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            REDU_IdvAcFormConfiguration_VEDP configObj = new REDU_IdvAcFormConfiguration_VEDP();
            VisualEditor.DynamicPickListRows resultObj = configObj.getValues();
            List<VisualEditor.DataRow> resultsInRow = resultObj.getDataRows();

            System.Assert.areEqual(2, resultObj.size(), 'Wrong picklist size!');
            for(VisualEditor.DataRow result : resultsInRow) {
                String wizardConfigName = (String) result.getValue();
                
                System.Assert.isTrue(IdvAcWizardFormGroupByWizardConfigName.keySet().contains(wizardConfigName), 'Should be inside the map! IdvAcWizardFormGroupByWizardConfigName:' + JSON.serialize(WIZARD_CONFIGS_MAP) + ', Actual result: ' + JSON.serialize(result));
            }
            
		}

        Test.stopTest();
    }

    /**
     * @description Test as admin for getting default value of the picklist
     */
    @IsTest
    static void testGetDefaultValue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            REDU_IdvAcFormConfiguration_VEDP configObj = new REDU_IdvAcFormConfiguration_VEDP();
            VisualEditor.DataRow result = configObj.getDefaultValue();
            System.Assert.areEqual(IDVAC_WIZARD_FORM_CONFIG_LABEL, result.getLabel());
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for getting all the selectable value of the picklist
     */
    @IsTest
    static void testGetValue_AsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            REDU_IdvAcFormConfiguration_VEDP configObj = new REDU_IdvAcFormConfiguration_VEDP();
            VisualEditor.DynamicPickListRows resultObj = configObj.getValues();
            List<VisualEditor.DataRow> resultsInRow = resultObj.getDataRows();

            System.Assert.areEqual(2, resultObj.size(), 'Wrong picklist size!');
            for(VisualEditor.DataRow result : resultsInRow) {
                String wizardConfigName = (String) result.getValue();
                
                System.Assert.isTrue(IdvAcWizardFormGroupByWizardConfigName.keySet().contains(wizardConfigName), 'Should be inside the map! IdvAcWizardFormGroupByWizardConfigName:' + JSON.serialize(WIZARD_CONFIGS_MAP) + ', Actual result: ' + JSON.serialize(result));
            }
            
		}

        Test.stopTest();
    }

    /**
     * @description Test as faculty for getting default value of the picklist
     */
    @IsTest
    static void testGetDefaultValue_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            REDU_IdvAcFormConfiguration_VEDP configObj = new REDU_IdvAcFormConfiguration_VEDP();
            VisualEditor.DataRow result = configObj.getDefaultValue();
            System.Assert.areEqual(IDVAC_WIZARD_FORM_CONFIG_LABEL, result.getLabel());
		}

        Test.stopTest();
		
    }
    
    /**
     * @description Test as student for getting all the selectable value of the picklist
     */
    @IsTest
    static void testGetValue_AsStudent() {
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
		System.runAs(studentUser){
            REDU_IdvAcFormConfiguration_VEDP configObj = new REDU_IdvAcFormConfiguration_VEDP();
            VisualEditor.DynamicPickListRows resultObj = configObj.getValues();
            List<VisualEditor.DataRow> resultsInRow = resultObj.getDataRows();

            System.Assert.areEqual(2, resultObj.size(), 'Wrong picklist size!');
            for(VisualEditor.DataRow result : resultsInRow) {
                String wizardConfigName = (String) result.getValue();
                
                System.Assert.isTrue(IdvAcWizardFormGroupByWizardConfigName.keySet().contains(wizardConfigName), 'Should be inside the map! IdvAcWizardFormGroupByWizardConfigName:' + JSON.serialize(WIZARD_CONFIGS_MAP) + ', Actual result: ' + JSON.serialize(result));
            }
            
		}

        Test.stopTest();
    }

    /**
     * @description Test as student for getting default value of the picklist
     */
    @IsTest
    static void testGetDefaultValue_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
		System.runAs(studentUser){
            REDU_IdvAcFormConfiguration_VEDP configObj = new REDU_IdvAcFormConfiguration_VEDP();
            VisualEditor.DataRow result = configObj.getDefaultValue();
            System.Assert.areEqual(IDVAC_WIZARD_FORM_CONFIG_LABEL, result.getLabel());
		}

        Test.stopTest();
		
    }
}