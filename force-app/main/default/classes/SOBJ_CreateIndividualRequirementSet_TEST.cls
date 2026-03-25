/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Test
 * @description Test class for SOBJ_CreateIndividualRequirementSet_EXE
 * @changehistory
 * ISS-002128 03-06-2025 XW - new class
 * ISS-002633 10-02-2026 XW - added test cases for contact field that has reference to parent record
 */
@IsTest
public inherited sharing class SOBJ_CreateIndividualRequirementSet_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static final String SRS_LOCAL = 'SRS_Local';
    static final String SRS_GENERAL = 'SRS_General';
    static final String SRS_APPLICATION = 'SRS_Application';
    static final String SPL_MASTER = 'BACBIS_MajorA';
    static final String SPL_SECONDARY = 'BACBIS_MinorA';
    static final String CON_STUDENT = 'sandydoe@redu.example';
    static final String SPG = 'BACBIS';
    
    static final String SRS_EVIDENCE = 'SRS_Achievement_Evidence';
    static final String SRS_UNIT_SYLLABI = 'SRS_Achievement_Unit_Syllabi';
    static final String IAC_SRC = CON_STUDENT + 'Individual_Achievement';

    static reduivy__Study_Requirement_Set__c srsLocal;
    static reduivy__Study_Requirement_Set__c srsGeneral;
    static reduivy__Study_Requirement_Set__c srsUnitSyllabi;
    static reduivy__Study_Program__c studyProgram;
    static Contact studentContact;
    static reduivy__Study_Plan__c masterStudyPlan;
    static reduivy__Study_Plan__c secondaryStudyPlan;
    
    static reduivy__Individual_Achievement__c iac;
    

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
            REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});        
        	
            testFactory.initMasterData(SRQ_Helper.getApiName());
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(IAU_Helper.getApiName(), true);

            //delete SRS_APPLICATION
            if(testFactory.studyRequirementSets.containsKey(SRS_APPLICATION)){
                delete testFactory.studyRequirementSets.get(SRS_APPLICATION);
            }
            
            REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
            Test.stopTest();        
		}

    }
	
    /**
     * @description Test as admin for create ipa with criteria not met
     */
    @IsTest
    static void testForCreateIpaWithCriteriaNotMetAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();

		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.isTrue(actualIrsList.isEmpty(), 'Irs should be empty!');

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as admin for create ipa with criteria met - contact is from parent record
     */
    @IsTest
    static void testForCreateIpaWithCriteriaMet_ContactAndCriteriaFromParent_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        reduivy__Individual_Achievement_Unit__c newIau = generateIau();

		System.runAs(ADMIN_USER){
            insert newIau;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name, reduivy__Contact__c
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Achievement_Unit__c = :newIau.Id
        ];

        System.Assert.areEqual(1, actualIrsList.size(), 'Wrong size!');
        System.Assert.isTrue(String.isNotBlank(actualIrsList[0].reduivy__Contact__c), 'Contact should not be empty!');
        

        Test.stopTest();        
		
    }

    /**
     * @description Test as admin for create ipa with criteria met - contact is from parent record - criteria not using parent record field
     */
    @IsTest
    static void testForCreateIpaWithCriteriaMet_ContactFromParent_CriteriaFromSelf_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        reduivy__Study_Requirement_Set__c srsUnitSyllabi = getSrsUnitSyllabi();
        srsUnitSyllabi.reduivy__Criteria__c = 'NOT(ISBLANK(reduivy__Individual_Achievement__c))';
        update srsUnitSyllabi;
        
        reduivy__Individual_Achievement_Unit__c newIau = generateIau();

		System.runAs(ADMIN_USER){
            insert newIau;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name, reduivy__Contact__c
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Achievement_Unit__c = :newIau.Id
        ];

        System.Assert.areEqual(1, actualIrsList.size(), 'Wrong size!');
        System.Assert.isTrue(String.isNotBlank(actualIrsList[0].reduivy__Contact__c), 'Contact should not be empty!');
        

        Test.stopTest();        
		
    }


    /**
     * @description Test as admin for create ipa with criteria met
     */
    @IsTest
    static void testForCreateIpaWithCriteriaMetAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Application_Status__c = 'Submitted';

		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList.size(), 'Wrong size!');
        

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as admin for update ipa to criteria met
     */
    @IsTest
    static void testForUpdateIpaToCriteriaMetAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        insert ipaToInsert;

        List<reduivy__Individual_Requirement_Set__c> actualIrsListBeforeUpdate = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.isTrue(actualIrsListBeforeUpdate.isEmpty(), 'Irs should be empty!');

        ipaToInsert.reduivy__Application_Status__c = 'Submitted';

		System.runAs(ADMIN_USER){
            update ipaToInsert;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList.size(), 'Wrong size!');
        

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as admin for validate created irs
     */
    @IsTest
    static void testForValidateCreatedIrsAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Application_Status__c = 'Submitted';

        System.runAs(ADMIN_USER) {
            insert ipaToInsert;
        }
		
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList1 = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList1.size(), 'Wrong size!');

        ipaToInsert.reduivy__Application_Status__c = 'Draft';

        System.runAs(ADMIN_USER) {
            update ipaToInsert;
        }

        List<reduivy__Individual_Requirement_Set__c> actualIrsList2 = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList2.size(), 'Wrong size!');

        ipaToInsert.reduivy__Application_Status__c = 'Submitted';

        System.runAs(ADMIN_USER) {
            update ipaToInsert;
        }

        List<reduivy__Individual_Requirement_Set__c> actualIrsList3 = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList3.size(), 'Wrong size!');
        

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as admin for create ipa with criteria that requires parent record to validate
     */
    @IsTest
    static void testForCreateIpaWithCriteriaWithParentRecordMetAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Application_Status__c = 'Submitted';
        
        reduivy__Study_Requirement_Set__c localSrs = getSrsLocal();
        localSrs.reduivy__Criteria__c = 'AND(TEXT(reduivy__Application_Status__c) = "Submitted", TEXT(reduivy__Contact__r.reduivy__Contact_Type__c) = "Student")';
        update localSrs;
        
		System.runAs(ADMIN_USER){
            insert ipaToInsert;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList.size(), 'Wrong size!');
        

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }
	
    /**
     * @description Test as admin for create ipa with criteria not met
     */
    @IsTest
    static void testForCreateBulk10IpaWithCriteriaNotMetAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        List<reduivy__Individual_Program_Application__c> ipaToInsertList = new List<reduivy__Individual_Program_Application__c>();

        for(Integer i = 0; i < 10; i++) {
            reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
            ipaToInsertList.add(ipaToInsert);
        }

		System.runAs(ADMIN_USER){
            insert ipaToInsertList;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c IN :ipaToInsertList
        ];

        System.Assert.isTrue(actualIrsList.isEmpty(), 'Irs should be empty!');

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as admin for create ipa with criteria met
     */
    @IsTest
    static void testForCreateBulk10IpaWithCriteriaMetAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        List<reduivy__Individual_Program_Application__c> ipaToInsertList = new List<reduivy__Individual_Program_Application__c>();

        for(Integer i = 0; i < 10; i++) {
            reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
            ipaToInsert.reduivy__Application_Status__c = 'Submitted';
            ipaToInsertList.add(ipaToInsert);
        }

		System.runAs(ADMIN_USER){
            insert ipaToInsertList;
		}
        
        Set<Id> expectedIpaIdSet = (new Map<Id, reduivy__Individual_Program_Application__c>(ipaToInsertList)).keySet();
        Set<Id> actualIpaIdSet = new Set<Id>();

        List<reduivy__Individual_Requirement_Set__c> actualIrsList = new List<reduivy__Individual_Requirement_Set__c>();
        for(reduivy__Individual_Requirement_Set__c actualIrs : [
            SELECT Id, Name, reduivy__Individual_Program_Application__c
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c IN :ipaToInsertList
        ]) {
            System.Assert.isTrue(expectedIpaIdSet.contains(actualIrs.reduivy__Individual_Program_Application__c), 'Parent IPA should be contains in the ipa list!');
            actualIpaIdSet.add(actualIrs.reduivy__Individual_Program_Application__c);
            actualIrsList.add(actualIrs);
        }

        System.Assert.isTrue(actualIpaIdSet.equals(expectedIpaIdSet), 'Wrong ipa id set! Expected: ' + JSON.serialize(expectedIpaIdSet) + ', Actual: ' + JSON.serialize(actualIpaIdSet));
        System.Assert.areEqual(2 * ipaToInsertList.size(), actualIrsList.size(), 'Wrong size!');
        

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }


    
    /**
     * @description Test as admin for update ipa to criteria met
     */
    @IsTest
    static void testForBulk10UpdateIpaToCriteriaMetAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        List<reduivy__Individual_Program_Application__c> ipaToInsertList = new List<reduivy__Individual_Program_Application__c>();
        for(Integer i = 0; i < 10; i++) {
            reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
            ipaToInsertList.add(ipaToInsert);
        }

        insert ipaToInsertList;

        List<reduivy__Individual_Requirement_Set__c> actualIrsListBeforeUpdate = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c IN :ipaToInsertList
        ];

        System.Assert.isTrue(actualIrsListBeforeUpdate.isEmpty(), 'Irs should be empty!');

        for(reduivy__Individual_Program_Application__c ipa : ipaToInsertList) {
            ipa.reduivy__Application_Status__c = 'Submitted';
        }

		System.runAs(ADMIN_USER){
            update ipaToInsertList;
		}
        
        Set<Id> expectedIpaIdSet = (new Map<Id, reduivy__Individual_Program_Application__c>(ipaToInsertList)).keySet();
        Set<Id> actualIpaIdSet = new Set<Id>();

        List<reduivy__Individual_Requirement_Set__c> actualIrsList = new List<reduivy__Individual_Requirement_Set__c>();
        
        for(reduivy__Individual_Requirement_Set__c actualIrs : [
            SELECT Id, Name, reduivy__Individual_Program_Application__c
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c IN :ipaToInsertList
        ]) {
            System.Assert.isTrue(expectedIpaIdSet.contains(actualIrs.reduivy__Individual_Program_Application__c), 'Parent IPA should be contains in the ipa list!');
            actualIpaIdSet.add(actualIrs.reduivy__Individual_Program_Application__c);
            actualIrsList.add(actualIrs);
        }
        
        System.Assert.isTrue(actualIpaIdSet.equals(expectedIpaIdSet), 'Wrong ipa id set! Expected: ' + JSON.serialize(expectedIpaIdSet) + ', Actual: ' + JSON.serialize(actualIpaIdSet));
        System.Assert.areEqual(2 * ipaToInsertList.size(), actualIrsList.size(), 'Wrong size!');
        

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as admin for validate created irs
     */
    @IsTest
    static void testForBulk10ValidateCreatedIrsAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        List<reduivy__Individual_Program_Application__c> ipaToInsertList = new List<reduivy__Individual_Program_Application__c>();

        for(Integer i = 0; i < 10; i++) {
            reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
            ipaToInsert.reduivy__Application_Status__c = 'Submitted';
            ipaToInsertList.add(ipaToInsert);
        }

        System.runAs(ADMIN_USER) {
            insert ipaToInsertList;
        }
		
        List<reduivy__Individual_Requirement_Set__c> actualIrsList1 = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c IN :ipaToInsertList
        ];

        System.Assert.areEqual(2 * ipaToInsertList.size(), actualIrsList1.size(), 'Wrong size!');

        for(reduivy__Individual_Program_Application__c ipa : ipaToInsertList) {
            ipa.reduivy__Application_Status__c = 'Draft';
        }

        System.runAs(ADMIN_USER) {
            update ipaToInsertList;
        }

        List<reduivy__Individual_Requirement_Set__c> actualIrsList2 = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsertList
        ];

        System.Assert.areEqual(2 * ipaToInsertList.size(), actualIrsList2.size(), 'Wrong size!');

        for(reduivy__Individual_Program_Application__c ipa : ipaToInsertList) {
            ipa.reduivy__Application_Status__c = 'Submitted';
        }

        System.runAs(ADMIN_USER) {
            update ipaToInsertList;
        }

        List<reduivy__Individual_Requirement_Set__c> actualIrsList3 = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c IN :ipaToInsertList
        ];

        System.Assert.areEqual(2 * ipaToInsertList.size(), actualIrsList3.size(), 'Wrong size!');
        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as admin for create ipa with criteria that requires parent record to validate
     */
    @IsTest
    static void testForCreateBulk10IpaWithCriteriaWithParentRecordMetAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        List<reduivy__Individual_Program_Application__c> ipaToInsertList = new List<reduivy__Individual_Program_Application__c>();

        for(Integer i = 0; i < 10; i++) {
            reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
            ipaToInsert.reduivy__Application_Status__c = 'Submitted';
            ipaToInsertList.add(ipaToInsert);
        }

        reduivy__Study_Requirement_Set__c localSrs = getSrsLocal();
        localSrs.reduivy__Criteria__c = 'AND(TEXT(reduivy__Application_Status__c) = "Submitted", TEXT(reduivy__Contact__r.reduivy__Contact_Type__c) = "Student")';
        update localSrs;
        
		System.runAs(ADMIN_USER){
            insert ipaToInsertList;
		}
        
        Set<Id> expectedIpaIdSet = (new Map<Id, reduivy__Individual_Program_Application__c>(ipaToInsertList)).keySet();
        Set<Id> actualIpaIdSet = new Set<Id>();
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = new List<reduivy__Individual_Requirement_Set__c>();
        for(reduivy__Individual_Requirement_Set__c actualIrs : [
            SELECT Id, Name, reduivy__Individual_Program_Application__c
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c IN :ipaToInsertList
        ]) {
            System.Assert.isTrue(expectedIpaIdSet.contains(actualIrs.reduivy__Individual_Program_Application__c), 'Parent IPA should be contains in the ipa list!');
            actualIpaIdSet.add(actualIrs.reduivy__Individual_Program_Application__c);
            actualIrsList.add(actualIrs);
        }

        System.Assert.isTrue(actualIpaIdSet.equals(expectedIpaIdSet), 'Wrong ipa id set! Expected: ' + JSON.serialize(expectedIpaIdSet) + ', Actual: ' + JSON.serialize(actualIpaIdSet));
        System.Assert.areEqual(2 * ipaToInsertList.size(), actualIrsList.size(), 'Wrong size!');
        
        

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as admin for create ipa with criteria not met
     */
    @IsTest
    static void testForCreateBulk100IpaWithCriteriaNotMetAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        reduivy__Study_Requirement_Set__c localSrs = getSrsLocal();
        
        List<reduivy__Study_Requirement_Set__c> srsToInsert = new List<reduivy__Study_Requirement_Set__c>();
        for(Integer i = 1; i <= 10; i++) {
            reduivy__Study_Requirement_Set__c srs = localSrs.clone();
            srs.reduivy__Sample_Record_Code__c = SRS_GENERAL + i;
            srsToInsert.add(srs);
        }

        insert srsToInsert;

        List<reduivy__Individual_Program_Application__c> ipaToInsertList = new List<reduivy__Individual_Program_Application__c>();

        for(Integer i = 0; i < 100; i++) {
            reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
            ipaToInsertList.add(ipaToInsert);
        }

		System.runAs(ADMIN_USER){
            insert ipaToInsertList;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c IN :ipaToInsertList
        ];

        System.Assert.isTrue(actualIrsList.isEmpty(), 'Irs should be empty!');

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as admin for create ipa with criteria met
     */
    @IsTest
    static void testForCreateBulk100IpaWithCriteriaMetAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        
        reduivy__Study_Requirement_Set__c localSrs = getSrsLocal();
        
        List<reduivy__Study_Requirement_Set__c> srsToInsert = new List<reduivy__Study_Requirement_Set__c>();
        for(Integer i = 1; i <= 10; i++) {
            reduivy__Study_Requirement_Set__c srs = localSrs.clone();
            srs.reduivy__Sample_Record_Code__c = SRS_GENERAL + i;
            srsToInsert.add(srs);
        }

        insert srsToInsert;


        List<reduivy__Individual_Program_Application__c> ipaToInsertList = new List<reduivy__Individual_Program_Application__c>();

        for(Integer i = 0; i < 100; i++) {
            reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
            ipaToInsert.reduivy__Application_Status__c = 'Submitted';
            ipaToInsertList.add(ipaToInsert);
        }

		System.runAs(ADMIN_USER){
            insert ipaToInsertList;
		}
        
        Set<Id> expectedIpaIdSet = (new Map<Id, reduivy__Individual_Program_Application__c>(ipaToInsertList)).keySet();
        Set<Id> actualIpaIdSet = new Set<Id>();

        List<reduivy__Individual_Requirement_Set__c> actualIrsList = new List<reduivy__Individual_Requirement_Set__c>();
        for(reduivy__Individual_Requirement_Set__c actualIrs : [
            SELECT Id, Name, reduivy__Individual_Program_Application__c
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c IN :ipaToInsertList
        ]) {
            System.Assert.isTrue(expectedIpaIdSet.contains(actualIrs.reduivy__Individual_Program_Application__c), 'Parent IPA should be contains in the ipa list!');
            actualIpaIdSet.add(actualIrs.reduivy__Individual_Program_Application__c);
            actualIrsList.add(actualIrs);
        }

        System.Assert.isTrue(actualIpaIdSet.equals(expectedIpaIdSet), 'Wrong ipa id set! Expected: ' + JSON.serialize(expectedIpaIdSet) + ', Actual: ' + JSON.serialize(actualIpaIdSet));
        System.Assert.areEqual(12 * ipaToInsertList.size(), actualIrsList.size(), 'Wrong size!');
        

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }


    
    /**
     * @description Test as admin for update ipa to criteria met
     */
    @IsTest
    static void testForBulk100UpdateIpaToCriteriaMetAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        reduivy__Study_Requirement_Set__c localSrs = getSrsLocal();
        
        List<reduivy__Study_Requirement_Set__c> srsToInsert = new List<reduivy__Study_Requirement_Set__c>();
        for(Integer i = 1; i <= 10; i++) {
            reduivy__Study_Requirement_Set__c srs = localSrs.clone();
            srs.reduivy__Sample_Record_Code__c = SRS_GENERAL + i;
            srsToInsert.add(srs);
        }

        insert srsToInsert;


        List<reduivy__Individual_Program_Application__c> ipaToInsertList = new List<reduivy__Individual_Program_Application__c>();
        for(Integer i = 0; i < 100; i++) {
            reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
            ipaToInsertList.add(ipaToInsert);
        }

        insert ipaToInsertList;

        List<reduivy__Individual_Requirement_Set__c> actualIrsListBeforeUpdate = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c IN :ipaToInsertList
        ];

        System.Assert.isTrue(actualIrsListBeforeUpdate.isEmpty(), 'Irs should be empty!');

        for(reduivy__Individual_Program_Application__c ipa : ipaToInsertList) {
            ipa.reduivy__Application_Status__c = 'Submitted';
        }

		System.runAs(ADMIN_USER){
            update ipaToInsertList;
		}
        
        Set<Id> expectedIpaIdSet = (new Map<Id, reduivy__Individual_Program_Application__c>(ipaToInsertList)).keySet();
        Set<Id> actualIpaIdSet = new Set<Id>();

        List<reduivy__Individual_Requirement_Set__c> actualIrsList = new List<reduivy__Individual_Requirement_Set__c>();
        
        for(reduivy__Individual_Requirement_Set__c actualIrs : [
            SELECT Id, Name, reduivy__Individual_Program_Application__c
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c IN :ipaToInsertList
        ]) {
            System.Assert.isTrue(expectedIpaIdSet.contains(actualIrs.reduivy__Individual_Program_Application__c), 'Parent IPA should be contains in the ipa list!');
            actualIpaIdSet.add(actualIrs.reduivy__Individual_Program_Application__c);
            actualIrsList.add(actualIrs);
        }
        
        System.Assert.isTrue(actualIpaIdSet.equals(expectedIpaIdSet), 'Wrong ipa id set! Expected: ' + JSON.serialize(expectedIpaIdSet) + ', Actual: ' + JSON.serialize(actualIpaIdSet));
        System.Assert.areEqual(12 * ipaToInsertList.size(), actualIrsList.size(), 'Wrong size!');
        

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as admin for validate created irs
     */
    @IsTest
    static void testForBulk100ValidateCreatedIrsAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        reduivy__Study_Requirement_Set__c localSrs = getSrsLocal();
        
        List<reduivy__Study_Requirement_Set__c> srsToInsert = new List<reduivy__Study_Requirement_Set__c>();
        for(Integer i = 1; i <= 10; i++) {
            reduivy__Study_Requirement_Set__c srs = localSrs.clone();
            srs.reduivy__Sample_Record_Code__c = SRS_GENERAL + i;
            srsToInsert.add(srs);
        }

        System.runAs(ADMIN_USER) {
            insert srsToInsert;
        }

        List<reduivy__Individual_Program_Application__c> ipaToInsertList = new List<reduivy__Individual_Program_Application__c>();

        for(Integer i = 0; i < 100; i++) {
            reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
            ipaToInsert.reduivy__Application_Status__c = 'Submitted';
            ipaToInsertList.add(ipaToInsert);
        }

        System.runAs(ADMIN_USER) {
            insert ipaToInsertList;
        }
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList1 = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c IN :ipaToInsertList
        ];

        System.Assert.areEqual(12 * ipaToInsertList.size(), actualIrsList1.size(), 'Wrong size!');

        for(reduivy__Individual_Program_Application__c ipa : ipaToInsertList) {
            ipa.reduivy__Application_Status__c = 'Draft';
        }

        System.runAs(ADMIN_USER) {
            update ipaToInsertList;
        }

        List<reduivy__Individual_Requirement_Set__c> actualIrsList2 = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsertList
        ];

        System.Assert.areEqual(12 * ipaToInsertList.size(), actualIrsList2.size(), 'Wrong size!');

        for(reduivy__Individual_Program_Application__c ipa : ipaToInsertList) {
            ipa.reduivy__Application_Status__c = 'Submitted';
        }

        System.runAs(ADMIN_USER) {
            update ipaToInsertList;
        }

        List<reduivy__Individual_Requirement_Set__c> actualIrsList3 = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c IN :ipaToInsertList
        ];

        System.Assert.areEqual(12 * ipaToInsertList.size(), actualIrsList3.size(), 'Wrong size!');
        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as admin for create ipa with criteria that requires parent record to validate
     */
    @IsTest
    static void testForCreateBulk100IpaWithCriteriaWithParentRecordMetAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        
        List<reduivy__Individual_Program_Application__c> ipaToInsertList = new List<reduivy__Individual_Program_Application__c>();
        
        for(Integer i = 0; i < 100; i++) {
            reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
            ipaToInsert.reduivy__Application_Status__c = 'Submitted';
            ipaToInsertList.add(ipaToInsert);
        }
        
        reduivy__Study_Requirement_Set__c localSrs = getSrsLocal();
        localSrs.reduivy__Criteria__c = 'AND(TEXT(reduivy__Application_Status__c) = "Submitted", TEXT(reduivy__Contact__r.reduivy__Contact_Type__c) = "Student")';
        update localSrs;
        
                
        List<reduivy__Study_Requirement_Set__c> srsToInsert = new List<reduivy__Study_Requirement_Set__c>();
        for(Integer i = 1; i <= 10; i++) {
            reduivy__Study_Requirement_Set__c srs = localSrs.clone();
            srs.reduivy__Sample_Record_Code__c = SRS_GENERAL + i;
            srsToInsert.add(srs);
        }

        insert srsToInsert;

		System.runAs(ADMIN_USER){
            insert ipaToInsertList;
		}
        
        Set<Id> expectedIpaIdSet = (new Map<Id, reduivy__Individual_Program_Application__c>(ipaToInsertList)).keySet();
        Set<Id> actualIpaIdSet = new Set<Id>();
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = new List<reduivy__Individual_Requirement_Set__c>();
        for(reduivy__Individual_Requirement_Set__c actualIrs : [
            SELECT Id, Name, reduivy__Individual_Program_Application__c
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c IN :ipaToInsertList
        ]) {
            System.Assert.isTrue(expectedIpaIdSet.contains(actualIrs.reduivy__Individual_Program_Application__c), 'Parent IPA should be contains in the ipa list!');
            actualIpaIdSet.add(actualIrs.reduivy__Individual_Program_Application__c);
            actualIrsList.add(actualIrs);
        }

        System.Assert.isTrue(actualIpaIdSet.equals(expectedIpaIdSet), 'Wrong ipa id set! Expected: ' + JSON.serialize(expectedIpaIdSet) + ', Actual: ' + JSON.serialize(actualIpaIdSet));
        System.Assert.areEqual(12 * ipaToInsertList.size(), actualIrsList.size(), 'Wrong size!');

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as student for create ipa with criteria not met
     */
    @IsTest
    static void testForCreateIpaWithCriteriaNotMetAsStudent() {

        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();

		System.runAs(studentUser){
            insert ipaToInsert;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.isTrue(actualIrsList.isEmpty(), 'Irs should be empty!');

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as student for create ipa with criteria met - contact is from parent record
     */
    @IsTest
    static void testForCreateIpaWithCriteriaMet_ContactFromParent_AsStudent() {

        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();
        
        reduivy__Individual_Achievement_Unit__c newIau = generateIau();

		System.runAs(studentUser){
            insert newIau;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name, reduivy__Contact__c
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Achievement_Unit__c = :newIau.Id
        ];

        System.Assert.areEqual(1, actualIrsList.size(), 'Wrong size!');
        System.Assert.isTrue(String.isNotBlank(actualIrsList[0].reduivy__Contact__c), 'Contact should not be empty!');
        
        Test.stopTest();        
		
    }

    /**
     * @description Test as student for create ipa with criteria met - contact is from parent record - criteria not using parent record field
     */
    @IsTest
    static void testForCreateIpaWithCriteriaMet_ContactFromParent_CriteriaFromSelf_AsStudent() {

        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();

        reduivy__Study_Requirement_Set__c srsUnitSyllabi = getSrsUnitSyllabi();
        srsUnitSyllabi.reduivy__Criteria__c = 'NOT(ISBLANK(reduivy__Individual_Achievement__c))';
        update srsUnitSyllabi;
        
        reduivy__Individual_Achievement_Unit__c newIau = generateIau();

		System.runAs(studentUser){
            insert newIau;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name, reduivy__Contact__c
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Achievement_Unit__c = :newIau.Id
        ];

        System.Assert.areEqual(1, actualIrsList.size(), 'Wrong size!');
        System.Assert.isTrue(String.isNotBlank(actualIrsList[0].reduivy__Contact__c), 'Contact should not be empty!');
        

        Test.stopTest();        
		
    }


    /**
     * @description Test as student for create ipa with criteria met
     */
    @IsTest
    static void testForCreateIpaWithCriteriaMetAsStudent() {

        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Application_Status__c = 'Submitted';

		System.runAs(studentUser){
            insert ipaToInsert;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList.size(), 'Wrong size!');
        

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as student for update ipa to criteria met
     */
    @IsTest
    static void testForUpdateIpaToCriteriaMetAsStudent() {

        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
		System.runAs(studentUser){
            insert ipaToInsert;
        }

        List<reduivy__Individual_Requirement_Set__c> actualIrsListBeforeUpdate = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.isTrue(actualIrsListBeforeUpdate.isEmpty(), 'Irs should be empty!');

        ipaToInsert.reduivy__Application_Status__c = 'Submitted';

		System.runAs(studentUser){
            update ipaToInsert;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList.size(), 'Wrong size!');
        

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as student for validate created irs
     */
    @IsTest
    static void testForValidateCreatedIrsAsStudent() {

        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Application_Status__c = 'Submitted';

        System.runAs(studentUser) {
            insert ipaToInsert;
        }
		
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList1 = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList1.size(), 'Wrong size!');

        ipaToInsert.reduivy__Application_Status__c = 'Draft';

        System.runAs(studentUser) {
            update ipaToInsert;
        }

        List<reduivy__Individual_Requirement_Set__c> actualIrsList2 = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList2.size(), 'Wrong size!');

        ipaToInsert.reduivy__Application_Status__c = 'Submitted';

        
        System.runAs(studentUser) {
            update ipaToInsert;
        }

        List<reduivy__Individual_Requirement_Set__c> actualIrsList3 = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList3.size(), 'Wrong size!');
        

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as student for create ipa with criteria that requires parent record to validate
     */
    @IsTest
    static void testForCreateIpaWithCriteriaWithParentRecordMetAsStudent() {

        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Application_Status__c = 'Submitted';
        
        reduivy__Study_Requirement_Set__c localSrs = getSrsLocal();
        localSrs.reduivy__Criteria__c = 'AND(TEXT(reduivy__Application_Status__c) = "Submitted", TEXT(reduivy__Contact__r.reduivy__Contact_Type__c) = "Student")';
        update localSrs;
        
		System.runAs(studentUser){
            insert ipaToInsert;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList.size(), 'Wrong size!');
        

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }
    
    /**
     * @description Test as faculty for create ipa with criteria not met
     */
    @IsTest
    static void testForCreateIpaWithCriteriaNotMetAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();

		System.runAs(FACULTY_USER){
            insert ipaToInsert;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.isTrue(actualIrsList.isEmpty(), 'Irs should be empty!');

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }


    /**
     * @description Test as faculty for create ipa with criteria met - contact is from parent record
     */
    @IsTest
    static void testForCreateIpaWithCriteriaMet_ContactFromParent_AsFaculty() {
        REDU_TriggerController.muteTriggers(new Set<String> {'IAU_SetIacVerficationStatus_EXE'});

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        reduivy__Individual_Achievement_Unit__c newIau = generateIau();

		System.runAs(FACULTY_USER){
            insert newIau;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name, reduivy__Contact__c
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Achievement_Unit__c = :newIau.Id
        ];

        System.Assert.areEqual(1, actualIrsList.size(), 'Wrong size!');
        System.Assert.isTrue(String.isNotBlank(actualIrsList[0].reduivy__Contact__c), 'Contact should not be empty!');
        

        Test.stopTest();        
		
    }

    /**
     * @description Test as faculty for create ipa with criteria met - contact is from parent record - criteria not using parent record field
     */
    @IsTest
    static void testForCreateIpaWithCriteriaMet_ContactFromParent_CriteriaFromSelf_AsFaculty() {

        REDU_TriggerController.muteTriggers(new Set<String> {'IAU_SetIacVerficationStatus_EXE'});
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        reduivy__Study_Requirement_Set__c srsUnitSyllabi = getSrsUnitSyllabi();
        srsUnitSyllabi.reduivy__Criteria__c = 'NOT(ISBLANK(reduivy__Individual_Achievement__c))';
        update srsUnitSyllabi;
        
        reduivy__Individual_Achievement_Unit__c newIau = generateIau();

		System.runAs(FACULTY_USER){
            insert newIau;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name, reduivy__Contact__c
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Achievement_Unit__c = :newIau.Id
        ];

        System.Assert.areEqual(1, actualIrsList.size(), 'Wrong size!');
        System.Assert.isTrue(String.isNotBlank(actualIrsList[0].reduivy__Contact__c), 'Contact should not be empty!');
        

        Test.stopTest();        
		
    }

    /**
     * @description Test as faculty for create ipa with criteria met
     */
    @IsTest
    static void testForCreateIpaWithCriteriaMetAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Application_Status__c = 'Submitted';

		System.runAs(FACULTY_USER){
            insert ipaToInsert;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList.size(), 'Wrong size!');
        

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as faculty for update ipa to criteria met
     */
    @IsTest
    static void testForUpdateIpaToCriteriaMetAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        insert ipaToInsert;

        List<reduivy__Individual_Requirement_Set__c> actualIrsListBeforeUpdate = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.isTrue(actualIrsListBeforeUpdate.isEmpty(), 'Irs should be empty!');

        ipaToInsert.reduivy__Application_Status__c = 'Submitted';

		System.runAs(FACULTY_USER){
            update ipaToInsert;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList.size(), 'Wrong size!');
        

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as faculty for validate created irs
     */
    @IsTest
    static void testForValidateCreatedIrsAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Application_Status__c = 'Submitted';

        System.runAs(FACULTY_USER) {
            insert ipaToInsert;
        }
		
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList1 = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList1.size(), 'Wrong size!');

        ipaToInsert.reduivy__Application_Status__c = 'Draft';

        update ipaToInsert;

        List<reduivy__Individual_Requirement_Set__c> actualIrsList2 = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList2.size(), 'Wrong size!');

        ipaToInsert.reduivy__Application_Status__c = 'Submitted';

        update ipaToInsert;

        List<reduivy__Individual_Requirement_Set__c> actualIrsList3 = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList3.size(), 'Wrong size!');
        

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }

    /**
     * @description Test as faculty for create ipa with criteria that requires parent record to validate
     */
    @IsTest
    static void testForCreateIpaWithCriteriaWithParentRecordMetAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        reduivy__Individual_Program_Application__c ipaToInsert = generateIpa();
        ipaToInsert.reduivy__Application_Status__c = 'Submitted';
        
        reduivy__Study_Requirement_Set__c localSrs = getSrsLocal();
        localSrs.reduivy__Criteria__c = 'AND(TEXT(reduivy__Application_Status__c) = "Submitted", TEXT(reduivy__Contact__r.reduivy__Contact_Type__c) = "Student")';
        update localSrs;
        
		System.runAs(FACULTY_USER){
            insert ipaToInsert;
		}
        
        List<reduivy__Individual_Requirement_Set__c> actualIrsList = [
            SELECT Id, Name
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipaToInsert.Id
        ];

        System.Assert.areEqual(2, actualIrsList.size(), 'Wrong size!');
        

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		
    }
    
    static reduivy__Study_Requirement_Set__c getSrsLocal(){
        if(srsLocal == null) {
            for(reduivy__Study_Requirement_Set__c srs : [
                SELECT Id, Name, reduivy__Object__c, reduivy__Criteria__c
                FROM reduivy__Study_Requirement_Set__c
                WHERE reduivy__Sample_Record_Code__c = :SRS_LOCAL
            ]) {
                srsLocal = srs;
            }
        }

        return srsLocal;
    }

    static reduivy__Study_Requirement_Set__c getSrsGeneral(){
        if(srsGeneral == null) {
            for(reduivy__Study_Requirement_Set__c srs : [
                SELECT Id, Name
                FROM reduivy__Study_Requirement_Set__c
                WHERE reduivy__Sample_Record_Code__c = :SRS_GENERAL
            ]) {
                srsGeneral = srs;
            }
        }

        return srsGeneral;
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

    static reduivy__Individual_Achievement__c getIac(){
        if(iac == null) {
            for(reduivy__Individual_Achievement__c queryIac : [
                SELECT Id, Name
                FROM reduivy__Individual_Achievement__c
                WHERE reduivy__Sample_Record_Code__c = :IAC_SRC
            ]) {
                iac = queryIac;
            }
        }

        return iac;
    }

    static reduivy__Individual_Program_Application__c generateIpa(){
        return new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = getStudent().Id,
            reduivy__Study_Program__c = getStudyProgram().Id,
            reduivy__Master_Study_Plan__c = getMasterSpl().Id,
            reduivy__Secondary_Study_Plan__c = getSecondarySpl().Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = 'Draft'
        );
    }

    static reduivy__Individual_Achievement_Unit__c generateIau(){
        return new reduivy__Individual_Achievement_Unit__c(
            reduivy__Individual_Achievement__c = getIac().Id,
            reduivy__Letter_Grade__c = 'A',
            reduivy__Numerical_Grade__c = 90
        );
    }
    
    static reduivy__Study_Requirement_Set__c getSrsUnitSyllabi(){
        if(srsUnitSyllabi == null) {
            for(reduivy__Study_Requirement_Set__c srs : [
                SELECT Id, Name
                FROM reduivy__Study_Requirement_Set__c
                WHERE reduivy__Sample_Record_Code__c = :SRS_UNIT_SYLLABI
            ]) {
                srsUnitSyllabi = srs;
            }
        }

        return srsUnitSyllabi;
    }
    
	
}