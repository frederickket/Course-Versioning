/**
 * @author      WDCi (XW)
 * @date        July 2025
 * @group       Test
 * @description Test class for IPA_AssignStudyIntakeGroup_EXE
 * @changehistory
 * ISS-002526 11-07-2025 XW - new class
 */
@IsTest
public inherited sharing class IPA_AssignStudyIntakeGroup_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String SPL_MASTER = 'BACBIS_MajorA';
    static final String SPL_SECONDARY = 'BACBIS_MinorA';
    static final String CON_STUDENT = 'sandydoe@redu.example';
    static final String SPG = 'BACBIS';
    static final String SRC_SIT = 'SYDNEY_BACBIS_CYINTAKE';
    static final String SRC_SIG_STANDARD = SRC_SIT + '_Standard';
    static final String SRC_SIG_DISABLED = SRC_SIT + '_Disabled';

    static Contact studentContact;
    static reduivy__Study_Plan__c secondaryStudyPlan;
    static reduivy__Study_Plan__c masterStudyPlan;
    static reduivy__Study_Program__c studyProgram;
    static reduivy__Study_Intake__c studyIntake;
    
    static reduivy__Study_Intake_Group__c sigStandard;
    static reduivy__Study_Intake_Group__c sigDisabled;

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
        // Create settings
        testFactory.setupDefaultSettings();
        
        setEnableSigSetting(true);

        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();
        	
            //please adjust the data according to your needs
            testFactory.initSampleData(SPL_Helper.getApiName(), SIG_Helper.getApiName(), USR_Helper.getApiName(), IPA_Helper.getApiName(), true, true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for creating ipa, assignment = auto, type = standard
     */
    @IsTest
    static void testForCreateIpa_AutoStandard_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for creating ipa, assignment = auto, type = standard, group = standard
     */
    @IsTest
    static void testForCreateIpa_AutoStandard_Standard_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        setSig();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;
        ipaToInsert.reduivy__Study_Intake_Group__c = sigStandard.Id;

		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);


        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for creating ipa, assignment = auto, type = standard, group = disabled
     */
    @IsTest
    static void testForCreateIpa_AutoStandard_Disabled_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        setSig();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;
        ipaToInsert.reduivy__Study_Intake_Group__c = sigDisabled.Id;

		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);


        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for creating ipa, assignment = auto, type = disabled
     */
    @IsTest
    static void testForCreateIpa_AutoDisabled_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigDisabled.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for creating ipa, assignment = auto, type = standard, sig type not exist
     */
    @IsTest
    static void testForCreateIpa_AutoDisabledNotexist_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        //update the disabled sig type to standard
        setSig();
        sigDisabled.reduivy__Student_Group_Type__c = SIG_Helper.STUDENT_GROUP_TYPE_STANDARD;
        update sigDisabled;

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

        System.runAs(ADMIN_USER){
            insert ipaToInsert;
        }

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for creating ipa, assignment = auto, type = unset
     */
    @IsTest
    static void testForCreateIpa_AutoUnset_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;

		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for creating ipa, assignment = auto, type = unset, no default sig set
     */
    @IsTest
    static void testForCreateIpa_AutoUnsetNodefault_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        setSig();

        sigStandard.reduivy__Default__c = false;
        update sigStandard;

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = null;

		try {
            System.runAs(ADMIN_USER){
                insert ipaToInsert;
            }
            System.Assert.fail('Should be failed! Assignment = auto, group type unset, no default sig.');
        } catch(Exception exp) {
            String expectedErrorMsg = String.format(Label.Error_No_Default_SIG, new List<String> {
                SIG_Helper.getObjectLabel()
            });

            System.Assert.isTrue(exp.getMessage().contains(expectedErrorMsg), 'Wrong message! Expected: ' + expectedErrorMsg + ', Actual: ' + exp.getMessage());
        }

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);
        
        System.Assert.isNull(actualIpa, 'Ipa should be not inserted!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for creating ipa, assignment = manual, type = standard
     */
    @IsTest
    static void testForCreateIpa_ManualStandard_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for creating ipa, assignment = manual, type = standard, group = standard
     */
    @IsTest
    static void testForCreateIpa_ManualStandard_Standard_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        setSig();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;
        ipaToInsert.reduivy__Study_Intake_Group__c = sigStandard.Id;

		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
    
	
    /**
     * @description Test as admin for creating ipa, assignment = manual, type = standard, group = disabled
     */
    @IsTest
    static void testForCreateIpa_ManualStandard_Disabled_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        setSig();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;
        ipaToInsert.reduivy__Study_Intake_Group__c = sigDisabled.Id;

		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigDisabled.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
    
    /**
     * @description Test as admin for creating ipa, assignment = manual, type = standard, sig status = draft
     */
    @IsTest
    static void testForCreateIpa_ManualDisabledDraft_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        //update the disabled sig type to standard
        setSig();
        sigDisabled.reduivy__Status__c = SIG_Helper.STATUS_DRAFT;
        update sigDisabled;

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

        try{
            System.runAs(ADMIN_USER){
                insert ipaToInsert;
            }
            System.Assert.fail('Should be failed! Assignment = manual, group type disabled, sig status = draft.');
        } catch (Exception exp) {
            String expectedErrorMsg = String.format(Label.Error_No_Matching_SIG, new List<String>{
                SIG_Helper.getObjectLabel(), 
                SObjectType.reduivy__Study_Intake_Group__c.fields.reduivy__Student_Group_Type__c.getLabel()
            });

            System.Assert.isTrue(exp.getMessage().contains(expectedErrorMsg), 'Wrong message! Expected: ' + expectedErrorMsg + ', Actual: ' + exp.getMessage());
        }

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);
        
        System.Assert.isNull(actualIpa, 'Ipa should be not inserted!');
        Test.stopTest();
		
    }

    
    /**
     * @description Test as admin for creating ipa, assignment = manual, type = disabled, sig type not exist
     */
    @IsTest
    static void testForCreateIpa_ManualDisabledNotexist_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        //update the disabled sig type to standard
        setSig();
        sigDisabled.reduivy__Student_Group_Type__c = SIG_Helper.STUDENT_GROUP_TYPE_STANDARD;
        update sigDisabled;

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

        try {
            System.runAs(ADMIN_USER){
                insert ipaToInsert;
            }
        } catch(Exception exp) {
            String expectedErrorMsg = String.format(Label.Error_No_Matching_SIG, new List<String>{
                SIG_Helper.getObjectLabel(), 
                SObjectType.reduivy__Study_Intake_Group__c.fields.reduivy__Student_Group_Type__c.getLabel()
            });

            System.Assert.isTrue(exp.getMessage().contains(expectedErrorMsg), 'Wrong message! Expected: ' + expectedErrorMsg + ', Actual: ' + exp.getMessage());
        }


        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        System.Assert.isNull(actualIpa, 'Ipa should be not inserted!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for creating ipa, assignment = manual, type = unset
     */
    @IsTest
    static void testForCreateIpa_ManualUnset_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = null;

        try {
            System.runAs(ADMIN_USER){
                insert ipaToInsert;
            }
            System.Assert.fail('Should be failed! invalid group type.');
        } catch(Exception exp) {
            String expectedErrorMsg = String.format(Label.Error_No_Matching_SIG, new List<String>{
                SIG_Helper.getObjectLabel(), 
                SObjectType.reduivy__Study_Intake_Group__c.fields.reduivy__Student_Group_Type__c.getLabel()
            });

            System.Assert.isTrue(exp.getMessage().contains(expectedErrorMsg), 'Wrong message! Expected: ' + expectedErrorMsg + ', Actual: ' + exp.getMessage());
        }

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);
        
        System.Assert.isNull(actualIpa, 'Ipa should be not inserted!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for creating ipa, assignment = auto, type = standard => disabled
     */
    @IsTest
    static void testForUpdateIpa_AutoStandard_ToAutoDisabled_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        //update
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;
        
		System.runAs(ADMIN_USER){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();
        
        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigDisabled.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');


        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for creating ipa, assignment = auto => manual, type = standard
     */
    @IsTest
    static void testForUpdateIpa_AutoStandard_ToManualStandard_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        //update
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        
		System.runAs(ADMIN_USER){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();
        
        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');


        Test.stopTest();
		
    }
	
	
    /**
     * @description Test as admin for creating ipa, assignment = auto => manual, type = standard => disabled
     */
    @IsTest
    static void testForUpdateIpa_AutoStandard_ToManualDisabled_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        //update
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;
        
		System.runAs(ADMIN_USER){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();
        
        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');


        Test.stopTest();
		
    }
	
	
    /**
     * @description Test as admin for creating ipa, assignment = auto, type = standard => unset
     */
    @IsTest
    static void testForUpdateIpa_AutoStandard_ToAutoUnset_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        //update
        ipaToInsert.reduivy__Student_Group_Type__c = '';
        
		System.runAs(ADMIN_USER){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();
        
        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');


        Test.stopTest();
		
    }

    /**
     * @description Test as admin for creating ipa, assignment = manual, type = standard => disabled
     */
    @IsTest
    static void testForUpdateIpa_ManualStandard_ToManualDisabled_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

		System.runAs(ADMIN_USER){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
    }

    /**
     * @description Test as admin for creating ipa, assignment = manual, type = standard => disabled
     */
    @IsTest
    static void testForUpdateIpa_ManualStandard_ToAutoDisabled_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');
        
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

		System.runAs(ADMIN_USER){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigDisabled.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
    }

    /**
     * @description Test as admin for creating ipa, assignment = manual, type = standard => unset
     */
    @IsTest
    static void testForUpdateIpa_ManualStandard_ToAutoUnset_AsAdmin() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = '';

		System.runAs(ADMIN_USER){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
    }

    /**
     * @description Test as faculty for creating ipa, assignment = auto, type = standard
     */
    @IsTest
    static void testForCreateIpa_AutoStandard_AsFaculty() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(FACULTY_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for creating ipa, assignment = auto, type = disabled
     */
    @IsTest
    static void testForCreateIpa_AutoDisabled_AsFaculty() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

		System.runAs(FACULTY_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigDisabled.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for creating ipa, assignment = auto, type = standard, sig type not exist
     */
    @IsTest
    static void testForCreateIpa_AutoDisabledNotexist_AsFaculty() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        //update the disabled sig type to standard
        setSig();
        sigDisabled.reduivy__Student_Group_Type__c = SIG_Helper.STUDENT_GROUP_TYPE_STANDARD;
        update sigDisabled;

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

        System.runAs(FACULTY_USER){
            insert ipaToInsert;
        }

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for creating ipa, assignment = auto, type = unset
     */
    @IsTest
    static void testForCreateIpa_AutoUnset_AsFaculty() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;

		System.runAs(FACULTY_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for creating ipa, assignment = auto, type = unset, no default sig set
     */
    @IsTest
    static void testForCreateIpa_AutoUnsetNodefault_AsFaculty() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        setSig();

        sigStandard.reduivy__Default__c = false;
        update sigStandard;

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = null;

		try {
            System.runAs(FACULTY_USER){
                insert ipaToInsert;
            }
            System.Assert.fail('Should be failed! Assignment = auto, group type unset, no default sig.');
        } catch(Exception exp) {
            String expectedErrorMsg = String.format(Label.Error_No_Default_SIG, new List<String> {
                SIG_Helper.getObjectLabel()
            });

            System.Assert.isTrue(exp.getMessage().contains(expectedErrorMsg), 'Wrong message! Expected: ' + expectedErrorMsg + ', Actual: ' + exp.getMessage());
        }

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);
        
        System.Assert.isNull(actualIpa, 'Ipa should be not inserted!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for creating ipa, assignment = manual, type = standard
     */
    @IsTest
    static void testForCreateIpa_ManualStandard_AsFaculty() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(FACULTY_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
    /**
     * @description Test as faculty for creating ipa, assignment = manual, type = standard, sig status = draft
     */
    @IsTest
    static void testForCreateIpa_ManualDisabledDraft_AsFaculty() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        //update the disabled sig type to standard
        setSig();
        sigDisabled.reduivy__Status__c = SIG_Helper.STATUS_DRAFT;
        update sigDisabled;

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

        try{
            System.runAs(FACULTY_USER){
                insert ipaToInsert;
            }
            System.Assert.fail('Should be failed! Assignment = manual, group type disabled, sig status = draft.');
        } catch (Exception exp) {
            String expectedErrorMsg = String.format(Label.Error_No_Matching_SIG, new List<String>{
                SIG_Helper.getObjectLabel(), 
                SObjectType.reduivy__Study_Intake_Group__c.fields.reduivy__Student_Group_Type__c.getLabel()
            });

            System.Assert.isTrue(exp.getMessage().contains(expectedErrorMsg), 'Wrong message! Expected: ' + expectedErrorMsg + ', Actual: ' + exp.getMessage());
        }

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);
        
        System.Assert.isNull(actualIpa, 'Ipa should be not inserted!');
        Test.stopTest();
		
    }

    
    /**
     * @description Test as faculty for creating ipa, assignment = manual, type = disabled, sig type not exist
     */
    @IsTest
    static void testForCreateIpa_ManualDisabledNotexist_AsFaculty() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        //update the disabled sig type to standard
        setSig();
        sigDisabled.reduivy__Student_Group_Type__c = SIG_Helper.STUDENT_GROUP_TYPE_STANDARD;
        update sigDisabled;

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

        try {
            System.runAs(FACULTY_USER){
                insert ipaToInsert;
            }
        } catch(Exception exp) {
            String expectedErrorMsg = String.format(Label.Error_No_Matching_SIG, new List<String>{
                SIG_Helper.getObjectLabel(), 
                SObjectType.reduivy__Study_Intake_Group__c.fields.reduivy__Student_Group_Type__c.getLabel()
            });

            System.Assert.isTrue(exp.getMessage().contains(expectedErrorMsg), 'Wrong message! Expected: ' + expectedErrorMsg + ', Actual: ' + exp.getMessage());
        }


        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        System.Assert.isNull(actualIpa, 'Ipa should be not inserted!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for creating ipa, assignment = manual, type = unset
     */
    @IsTest
    static void testForCreateIpa_ManualUnset_AsFaculty() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = null;

        try {
            System.runAs(FACULTY_USER){
                insert ipaToInsert;
            }
            System.Assert.fail('Should be failed! invalid group type.');
        } catch(Exception exp) {
            String expectedErrorMsg = String.format(Label.Error_No_Matching_SIG, new List<String>{
                SIG_Helper.getObjectLabel(), 
                SObjectType.reduivy__Study_Intake_Group__c.fields.reduivy__Student_Group_Type__c.getLabel()
            });

            System.Assert.isTrue(exp.getMessage().contains(expectedErrorMsg), 'Wrong message! Expected: ' + expectedErrorMsg + ', Actual: ' + exp.getMessage());
        }

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);
        
        System.Assert.isNull(actualIpa, 'Ipa should be not inserted!');

        Test.stopTest();
		
    }

    

    /**
     * @description Test as faculty for creating ipa, assignment = auto, type = standard => disabled
     */
    @IsTest
    static void testForUpdateIpa_AutoStandard_ToAutoDisabled_AsFaculty() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(FACULTY_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        //update
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;
        
		System.runAs(FACULTY_USER){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();
        
        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigDisabled.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');


        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for creating ipa, assignment = auto => manual, type = standard
     */
    @IsTest
    static void testForUpdateIpa_AutoStandard_ToManualStandard_AsFaculty() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(FACULTY_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        //update
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        
		System.runAs(FACULTY_USER){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();
        
        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');


        Test.stopTest();
		
    }
	
	
    /**
     * @description Test as faculty for creating ipa, assignment = auto => manual, type = standard => disabled
     */
    @IsTest
    static void testForUpdateIpa_AutoStandard_ToManualDisabled_AsFaculty() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(FACULTY_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        //update
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;
        
		System.runAs(FACULTY_USER){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();
        
        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');


        Test.stopTest();
		
    }
	
	
    /**
     * @description Test as faculty for creating ipa, assignment = auto, type = standard => unset
     */
    @IsTest
    static void testForUpdateIpa_AutoStandard_ToAutoUnset_AsFaculty() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(FACULTY_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        //update
        ipaToInsert.reduivy__Student_Group_Type__c = '';
        
		System.runAs(FACULTY_USER){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();
        
        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');


        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for creating ipa, assignment = manual, type = standard => disabled
     */
    @IsTest
    static void testForUpdateIpa_ManualStandard_ToManualDisabled_AsFaculty() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(FACULTY_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

		System.runAs(FACULTY_USER){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
    }

    /**
     * @description Test as faculty for creating ipa, assignment = manual, type = standard => disabled
     */
    @IsTest
    static void testForUpdateIpa_ManualStandard_ToAutoDisabled_AsFaculty() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;
        
		System.runAs(FACULTY_USER){
            insert ipaToInsert;
		}
        
        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);
        
        setSig();
        
        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');
        
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

		System.runAs(FACULTY_USER){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigDisabled.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
    }

    /**
     * @description Test as faculty for creating ipa, assignment = manual, type = standard => unset
     */
    @IsTest
    static void testForUpdateIpa_ManualStandard_ToAutoUnset_AsFaculty() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(FACULTY_USER){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = '';

		System.runAs(FACULTY_USER){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
    }
	
    /**
     * @description Test as student for creating ipa, assignment = auto, type = standard
     */
    @IsTest
    static void testForCreateIpa_AutoStandard_AsStudent() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(studentUser){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for creating ipa, assignment = auto, type = disabled
     */
    @IsTest
    static void testForCreateIpa_AutoDisabled_AsStudent() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

		System.runAs(studentUser){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigDisabled.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for creating ipa, assignment = auto, type = standard, sig type not exist
     */
    @IsTest
    static void testForCreateIpa_AutoDisabledNotexist_AsStudent() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        //update the disabled sig type to standard
        setSig();
        sigDisabled.reduivy__Student_Group_Type__c = SIG_Helper.STUDENT_GROUP_TYPE_STANDARD;
        update sigDisabled;

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

        System.runAs(studentUser){
            insert ipaToInsert;
        }

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for creating ipa, assignment = auto, type = unset
     */
    @IsTest
    static void testForCreateIpa_AutoUnset_AsStudent() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;

		System.runAs(studentUser){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for creating ipa, assignment = auto, type = unset, no default sig set
     */
    @IsTest
    static void testForCreateIpa_AutoUnsetNodefault_AsStudent() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        setSig();

        sigStandard.reduivy__Default__c = false;
        update sigStandard;

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = null;

		try {
            System.runAs(studentUser){
                insert ipaToInsert;
            }
            System.Assert.fail('Should be failed! Assignment = auto, group type unset, no default sig.');
        } catch(Exception exp) {
            String expectedErrorMsg = String.format(Label.Error_No_Default_SIG, new List<String> {
                SIG_Helper.getObjectLabel()
            });

            System.Assert.isTrue(exp.getMessage().contains(expectedErrorMsg), 'Wrong message! Expected: ' + expectedErrorMsg + ', Actual: ' + exp.getMessage());
        }

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);
        
        System.Assert.isNull(actualIpa, 'Ipa should be not inserted!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for creating ipa, assignment = manual, type = standard
     */
    @IsTest
    static void testForCreateIpa_ManualStandard_AsStudent() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(studentUser){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
		
    }
    
    /**
     * @description Test as student for creating ipa, assignment = manual, type = standard, sig status = draft
     */
    @IsTest
    static void testForCreateIpa_ManualDisabledDraft_AsStudent() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        //update the disabled sig type to standard
        setSig();
        sigDisabled.reduivy__Status__c = SIG_Helper.STATUS_DRAFT;
        update sigDisabled;

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

        try{
            System.runAs(studentUser){
                insert ipaToInsert;
            }
            System.Assert.fail('Should be failed! Assignment = manual, group type disabled, sig status = draft.');
        } catch (Exception exp) {
            String expectedErrorMsg = String.format(Label.Error_No_Matching_SIG, new List<String>{
                SIG_Helper.getObjectLabel(), 
                SObjectType.reduivy__Study_Intake_Group__c.fields.reduivy__Student_Group_Type__c.getLabel()
            });

            System.Assert.isTrue(exp.getMessage().contains(expectedErrorMsg), 'Wrong message! Expected: ' + expectedErrorMsg + ', Actual: ' + exp.getMessage());
        }

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);
        
        System.Assert.isNull(actualIpa, 'Ipa should be not inserted!');
        Test.stopTest();
		
    }

    
    /**
     * @description Test as student for creating ipa, assignment = manual, type = disabled, sig type not exist
     */
    @IsTest
    static void testForCreateIpa_ManualDisabledNotexist_AsStudent() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        //update the disabled sig type to standard
        setSig();
        sigDisabled.reduivy__Student_Group_Type__c = SIG_Helper.STUDENT_GROUP_TYPE_STANDARD;
        update sigDisabled;

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

        try {
            System.runAs(studentUser){
                insert ipaToInsert;
            }
        } catch(Exception exp) {
            String expectedErrorMsg = String.format(Label.Error_No_Matching_SIG, new List<String>{
                SIG_Helper.getObjectLabel(), 
                SObjectType.reduivy__Study_Intake_Group__c.fields.reduivy__Student_Group_Type__c.getLabel()
            });

            System.Assert.isTrue(exp.getMessage().contains(expectedErrorMsg), 'Wrong message! Expected: ' + expectedErrorMsg + ', Actual: ' + exp.getMessage());
        }


        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        System.Assert.isNull(actualIpa, 'Ipa should be not inserted!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for creating ipa, assignment = manual, type = unset
     */
    @IsTest
    static void testForCreateIpa_ManualUnset_AsStudent() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = null;

        try {
            System.runAs(studentUser){
                insert ipaToInsert;
            }
            System.Assert.fail('Should be failed! invalid group type.');
        } catch(Exception exp) {
            String expectedErrorMsg = String.format(Label.Error_No_Matching_SIG, new List<String>{
                SIG_Helper.getObjectLabel(), 
                SObjectType.reduivy__Study_Intake_Group__c.fields.reduivy__Student_Group_Type__c.getLabel()
            });

            System.Assert.isTrue(exp.getMessage().contains(expectedErrorMsg), 'Wrong message! Expected: ' + expectedErrorMsg + ', Actual: ' + exp.getMessage());
        }

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);
        
        System.Assert.isNull(actualIpa, 'Ipa should be not inserted!');

        Test.stopTest();
		
    }

    

    /**
     * @description Test as student for creating ipa, assignment = auto, type = standard => disabled
     */
    @IsTest
    static void testForUpdateIpa_AutoStandard_ToAutoDisabled_AsStudent() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User studentUser = testFactory.getstudentUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(studentUser){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        //update
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;
        
		System.runAs(studentUser){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();
        
        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigDisabled.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');


        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for creating ipa, assignment = auto => manual, type = standard
     */
    @IsTest
    static void testForUpdateIpa_AutoStandard_ToManualStandard_AsStudent() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User studentUser = testFactory.getstudentUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(studentUser){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        //update
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        
		System.runAs(studentUser){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();
        
        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');


        Test.stopTest();
		
    }
	
	
    /**
     * @description Test as student for creating ipa, assignment = auto => manual, type = standard => disabled
     */
    @IsTest
    static void testForUpdateIpa_AutoStandard_ToManualDisabled_AsStudent() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User studentUser = testFactory.getstudentUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(studentUser){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        //update
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;
        
		System.runAs(studentUser){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();
        
        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');


        Test.stopTest();
		
    }
	
	
    /**
     * @description Test as student for creating ipa, assignment = auto, type = standard => unset
     */
    @IsTest
    static void testForUpdateIpa_AutoStandard_ToAutoUnset_AsStudent() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User studentUser = testFactory.getstudentUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(studentUser){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        //update
        ipaToInsert.reduivy__Student_Group_Type__c = '';
        
		System.runAs(studentUser){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();
        
        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');


        Test.stopTest();
		
    }

    /**
     * @description Test as student for creating ipa, assignment = manual, type = standard => disabled
     */
    @IsTest
    static void testForUpdateIpa_ManualStandard_ToManualDisabled_AsStudent() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User studentUser = testFactory.getstudentUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(studentUser){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

		System.runAs(studentUser){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
    }

    /**
     * @description Test as student for creating ipa, assignment = manual, type = standard => disabled
     */
    @IsTest
    static void testForUpdateIpa_ManualStandard_ToAutoDisabled_AsStudent() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User studentUser = testFactory.getstudentUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;
        
		System.runAs(studentUser){
            insert ipaToInsert;
		}
        
        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);
        
        setSig();
        
        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');
        
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_DISABLED;

		System.runAs(studentUser){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_DISABLED, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigDisabled.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
    }

    /**
     * @description Test as student for creating ipa, assignment = manual, type = standard => unset
     */
    @IsTest
    static void testForUpdateIpa_ManualStandard_ToAutoUnset_AsStudent() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        User studentUser = testFactory.getstudentUser();

        Test.startTest();

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL;
        ipaToInsert.reduivy__Student_Group_Type__c = IPA_Helper.STUDENT_GROUP_TYPE_STANDARD;

		System.runAs(studentUser){
            insert ipaToInsert;
		}

        reduivy__Individual_Program_Application__c actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        ipaToInsert.reduivy__Study_Intake_Group_Assignment__c = IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO;
        ipaToInsert.reduivy__Student_Group_Type__c = '';

		System.runAs(studentUser){
            update ipaToInsert;
		}

        actualIpa = queryIpa(ipaToInsert.Id);

        setSig();

        System.Assert.areEqual(IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO, actualIpa.reduivy__Study_Intake_Group_Assignment__c, 'Wrong Study Intake Group Assignment!');
        System.Assert.areEqual(IPA_Helper.STUDENT_GROUP_TYPE_STANDARD, actualIpa.reduivy__Student_Group_Type__c, 'Wrong Student Group Type!');
        System.Assert.areEqual(sigStandard.Id, actualIpa.reduivy__Study_Intake_Group__c, 'Wrong Study Intake Group!');

        Test.stopTest();
    }
    
    /**
     * @description set the record value translation setting to the value given
     */
    private static void setEnableSigSetting(Boolean value) {
        if(REDU_AppSetting_UTIL.isUsingStudyIntakeGroup() != value) {
            reduivy__RIO_Education_Ivy_Settings__c setting = REDU_AppSetting_UTIL.getOrgDefaultSetting();
            setting.reduivy__Use_Study_Intake_Group__c = value;
            update setting;
        }
    }

    static reduivy__Study_Program__c getStudyProgram(){
        if(studyProgram == null) {
            for(reduivy__Study_Program__c spg : [
                SELECT Id, Name
                FROM reduivy__Study_Program__c
                WHERE reduivy__Sample_Record_Code__c = :SPG
            ]) {
                studyProgram = spg;
            }
        }

        return studyProgram;
    }


    static reduivy__Study_Plan__c getMasterSpl(){
        if(masterStudyPlan == null) {
            for(reduivy__Study_Plan__c spl : [
                SELECT Id, Name
                FROM reduivy__Study_Plan__c
                WHERE reduivy__Sample_Record_Code__c = :SPL_MASTER
            ]) {
                masterStudyPlan = spl;
            }
        }

        return masterStudyPlan;
    }

    static reduivy__Study_Plan__c getSecondarySpl() {
        if(secondaryStudyPlan == null) {
            for(reduivy__Study_Plan__c spl : [
                SELECT Id, Name
                FROM reduivy__Study_Plan__c
                WHERE reduivy__Sample_Record_Code__c = :SPL_SECONDARY
            ]){
                secondaryStudyPlan = spl;
            }  
        }

        return secondaryStudyPlan;
    }

    static Contact getStudent(){
        if(studentContact == null) {
            for(Contact con : [
                SELECT Id, Name
                FROM Contact
                WHERE reduivy__Sample_Record_Code__c = :CON_STUDENT
            ]) {
                studentContact = con;
            }
        }

        return studentContact;
    }

    static reduivy__Study_Intake__c getStudyIntake() {
        if(studyIntake == null) {
            for(reduivy__Study_Intake__c sit : [
                SELECT Id, Name
                FROM reduivy__Study_Intake__c
                WHERE reduivy__Sample_Record_Code__c = :SRC_SIT
            ]) {
                studyIntake = sit;
            }
        }

        return studyIntake;
    }

    static reduivy__Individual_Program_Application__c generateIpa(){
        return new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = getStudent().Id,
            reduivy__Study_Program__c = getStudyProgram().Id,
            reduivy__Master_Study_Plan__c = getMasterSpl().Id,
            reduivy__Secondary_Study_Plan__c = getSecondarySpl().Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = 'Draft',
            reduivy__Study_Intake__c = getStudyIntake().Id
        );
    }

    static reduivy__Individual_Program_Application__c queryIpa(Id ipaId) {
        List<reduivy__Individual_Program_Application__c> ipaList = [
            SELECT Id, reduivy__Student_Group_Type__c, reduivy__Study_Intake_Group_Assignment__c, reduivy__Study_Intake_Group__c
            FROM reduivy__Individual_Program_Application__c
            WHERE Id = :ipaId
        ];

        if(ipaList.isEmpty()){
            return null;
        }
        return ipaList[0];
    }

    static void setSig() {
        for(reduivy__Study_Intake_Group__c sig : [
            SELECT Id, Name, reduivy__Default__c, reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Intake_Group__c 
            WHERE reduivy__Sample_Record_Code__c 
            IN (:SRC_SIG_STANDARD, :SRC_SIG_DISABLED)
        ]) {
            if(sig.reduivy__Sample_Record_Code__c == SRC_SIG_STANDARD) {
                sigStandard = sig;
            }
            else if(sig.reduivy__Sample_Record_Code__c == SRC_SIG_DISABLED) {
                sigDisabled = sig;
            }
        }
    }



}