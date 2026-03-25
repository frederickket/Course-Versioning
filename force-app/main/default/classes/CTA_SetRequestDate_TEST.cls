/**
 * @author      WDCi (Vtan)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for CTA_SetRequestDate_EXE
 * @changehistory
 * ISS-002045 22-08-2024 Vtan - new class
 */
@IsTest
public inherited sharing class CTA_SetRequestDate_TEST {
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Create settings and test data
     */
	@TestSetup
    static void makeData() {
		
		// Create settings
		testFactory.setupDefaultSettings();

        // Create test data
        Test.startTest();
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Account eduInst = REDU_TestData_UTIL.newEducationalInstitution('RIOUNI', 'RIO University', 'RIOUNI');
            Account extInst = REDU_TestData_UTIL.newExternalEducationalInstitution('EXTUNIT', 'Partner University', 'EXTUNIT');

            REDU_SystemMode_UTIL.doInsert(new List<Account>{eduInst, extInst});

            reduivy__Agreement__c agreement = REDU_TestData_UTIL.newAgreement('Transfer_Credit_Agreement_with_Partner_University', eduInst.Id, extInst.Id, 'Transfer Credit Agreement with Partner University', Date.newInstance(2023, 01, 01), Date.newInstance(2026, 12, 31), AGR_Helper.STATUS_ACTIVE, AGR_Helper.TYPE_EXTERNAL);
			REDU_SystemMode_UTIL.doInsert(new List<reduivy__Agreement__c>{agreement});

            Map<String, reduivy__Study_Unit__c> studyUnits = new Map<String, reduivy__Study_Unit__c>();
            studyUnits.put('BUS101', REDU_TestData_UTIL.newStudyUnit('BUS101', eduInst.Id, null, 'BUS101', 'BUS101', 5, 'Business, Management, and Marketing', '100', 0.125, null));
            studyUnits.put('ICT101', REDU_TestData_UTIL.newStudyUnit('ICT101', eduInst.Id, null, 'ICT101', 'ICT101', 5, 'Computer and Information Sciences', '100', 0.125, null));
            studyUnits.put('MKT101', REDU_TestData_UTIL.newStudyUnit('MKT101', eduInst.Id, null, 'MKT101', 'MKT101', 5, 'Business, Management, and Marketing', '100', 0.125, null));
            studyUnits.put('MKT102', REDU_TestData_UTIL.newStudyUnit('MKT102', eduInst.Id, null, 'MKT102', 'MKT102', 5, 'Business, Management, and Marketing', '100', 0.125, null));
            studyUnits.put('MKT103', REDU_TestData_UTIL.newStudyUnit('MKT103', eduInst.Id, null, 'MKT103', 'MKT103', 5, 'Business, Management, and Marketing', '100', 0.125, null));    
            studyUnits.put('MAT201', REDU_TestData_UTIL.newStudyUnit('MAT201', eduInst.Id, null, 'MAT201', 'MAT201', 5, 'Computer and Information Sciences', '200', 0.125, null));

            REDU_SystemMode_UTIL.doInsert(studyUnits.values());

            Map<String, reduivy__Agreement_Unit_Equivalent__c> agreementUnitEquavalents = new Map<String, reduivy__Agreement_Unit_Equivalent__c>();

            agreementUnitEquavalents.put('AUE_Introduction_to_Business_Studies', REDU_TestData_UTIL.newAgreementUnitEquivalent('AUE_Introduction_to_Business_Studies', agreement.Id, 'Introduction to Business Studies', new Set<String>{'BSN1000'}, new Set<String>{'BUS101'}, AUE_Helper.STATUS_ACTIVE, AUE_Helper.TYPE_ONETOONE));
            agreementUnitEquavalents.put('AUE_Introduction_to_IT', REDU_TestData_UTIL.newAgreementUnitEquivalent('AUE_Introduction_to_IT', agreement.Id, 'Introduction to IT', new Set<String>{'ITS1000'}, new Set<String>{'ICT101'}, AUE_Helper.STATUS_ACTIVE, AUE_Helper.TYPE_ONETOONE));
            agreementUnitEquavalents.put('AUE_Advanced_Marketing_Studies', REDU_TestData_UTIL.newAgreementUnitEquivalent('AUE_Advanced_Marketing_Studies', agreement.Id, 'Advanced Marketing Studies', new Set<String>{'MRT2000'}, new Set<String>{'MKT101', 'MKT102', 'MKT103'}, AUE_Helper.STATUS_ACTIVE, AUE_Helper.TYPE_ONETOMANY));
            agreementUnitEquavalents.put('AUE_Intro_to_MathsI_Intro_to_MathsII', REDU_TestData_UTIL.newAgreementUnitEquivalent('AUE_Intro_to_MathsI_Intro_to_MathsII', agreement.Id, 'Intro to Maths - I;Intro to Maths - II', new Set<String>{'MTS1001', 'MTS1002'}, new Set<String>{'MAT201'}, AUE_Helper.STATUS_ACTIVE, AUE_Helper.TYPE_MANYTOONE));
            agreementUnitEquavalents.put('AUE_Leadership_Skills', REDU_TestData_UTIL.newAgreementUnitEquivalent('AUE_Leadership_Skills', agreement.Id, 'Leadership Skills', new Set<String>{'LDR1000'}, new Set<String>{}, AUE_Helper.STATUS_ACTIVE, AUE_Helper.TYPE_MANUALASSIGNMENT));

            REDU_SystemMode_UTIL.doInsert(agreementUnitEquavalents.values());
            
            testFactory.initStudentData(USR_Helper.getApiName(), true);
        }

        Test.stopTest();
    }


    @IsTest
    static void testCtaInsertAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Agreement_Unit_Equivalent__c agreementUnit = [SELECT Id FROM reduivy__Agreement_Unit_Equivalent__c WHERE reduivy__Sample_Record_Code__c = 'AUE_Introduction_to_Business_Studies'];

        List<reduivy__Credit_Transfer_Application__c> insertCtaList = new List<reduivy__Credit_Transfer_Application__c>();
        insertCtaList.add(REDU_TestData_UTIL.newCreditTransferApplication(
            'CTA_Introduction_to_Business_Studies', 
            conStudent.Id, 
            agreementUnit.Id, 
            null, null, 'B', 66, 5, 5, null, 
            CTA_Helper.getSubmittedStatuses().get(0), 'CT', new Set<String>{}, CTA_Helper.TYPE_INCOMING));

        insertCtaList.add(REDU_TestData_UTIL.newCreditTransferApplication(
            'CTA_Introduction_to_Business_Studies', 
            conStudent.Id, 
            agreementUnit.Id, 
            null, null, 'B', 66, 5, 5, null, 
            CTA_Helper.getDraftStatuses().get(0), 'CT', new Set<String>{}, CTA_Helper.TYPE_INCOMING));

        
        Test.startTest();
        System.runAs(ADMIN_USER) {
            insert insertCtaList;
        }
        Test.stopTest();

        for(reduivy__Credit_Transfer_Application__c ctaCheck : [SELECT Id, reduivy__Request_Date__c, reduivy__Status__c FROM reduivy__Credit_Transfer_Application__c WHERE Id IN :insertCtaList]){

            if(ctaCheck.reduivy__Status__c == CTA_Helper.getSubmittedStatuses().get(0)){

                System.Assert.areEqual(
                    System.today(),
                    ctaCheck.reduivy__Request_Date__c,
                    'Request Date should be updated to today'
                );
            }else if(ctaCheck.reduivy__Status__c == CTA_Helper.getDraftStatuses().get(0)){

                System.Assert.areEqual(
                    null,
                    ctaCheck.reduivy__Request_Date__c,
                    'Request Date should be remained as empty is status is draft'
                );
            }
        }
    }

    @IsTest
    static void testCtaUpdateAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        reduivy__Agreement_Unit_Equivalent__c agreementUnit = [SELECT Id FROM reduivy__Agreement_Unit_Equivalent__c WHERE reduivy__Sample_Record_Code__c = 'AUE_Introduction_to_Business_Studies'];

        List<reduivy__Credit_Transfer_Application__c> updateCtaList = new List<reduivy__Credit_Transfer_Application__c>();
        updateCtaList.add(REDU_TestData_UTIL.newCreditTransferApplication(
                                                                        'CTA_Introduction_to_Business_Studies', 
                                                                        conStudent.Id, 
                                                                        agreementUnit.Id, 
                                                                        null, null, 'B', 66, 5, 5, null, 
                                                                        CTA_Helper.getDraftStatuses().get(0), 'CT', new Set<String>{}, CTA_Helper.TYPE_INCOMING));

        updateCtaList.add(REDU_TestData_UTIL.newCreditTransferApplication(
                                                                        'CTA_Introduction_to_Business_Studies', 
                                                                        conStudent.Id, 
                                                                        agreementUnit.Id, 
                                                                        null, null, 'B', 66, 5, 5, null, 
                                                                        CTA_Helper.getDraftStatuses().get(0), 'CT', new Set<String>{}, CTA_Helper.TYPE_INCOMING));
        insert updateCtaList;

        updateCtaList.get(0).reduivy__Status__c = CTA_Helper.getSubmittedStatuses().get(0);
        
        Test.startTest();
        System.runAs(ADMIN_USER) {
            update updateCtaList;
        }
        Test.stopTest();

        for(reduivy__Credit_Transfer_Application__c ctaCheck : [SELECT Id, reduivy__Request_Date__c, reduivy__Status__c FROM reduivy__Credit_Transfer_Application__c WHERE Id IN :updateCtaList]){

            if(ctaCheck.reduivy__Status__c == CTA_Helper.getSubmittedStatuses().get(0)){

                System.Assert.areEqual(
                    System.today(),
                    ctaCheck.reduivy__Request_Date__c,
                    'Request Date should be updated to today'
                );
            }else if(ctaCheck.reduivy__Status__c == CTA_Helper.getDraftStatuses().get(0)){

                System.Assert.areEqual(
                    null,
                    ctaCheck.reduivy__Request_Date__c,
                    'Request Date should be remained as empty is status is draft'
                );
            }
        }
    }

    @IsTest
    static void testCtaInsertAsStudent() {

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: conStudent.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        reduivy__Agreement_Unit_Equivalent__c agreementUnit = [SELECT Id FROM reduivy__Agreement_Unit_Equivalent__c WHERE reduivy__Sample_Record_Code__c = 'AUE_Introduction_to_Business_Studies'];

        List<reduivy__Credit_Transfer_Application__c> insertCtaList = new List<reduivy__Credit_Transfer_Application__c>();
        insertCtaList.add(REDU_TestData_UTIL.newCreditTransferApplication(
                                                                        'CTA_Introduction_to_Business_Studies', 
                                                                        conStudent.Id, 
                                                                        agreementUnit.Id, 
                                                                        null, null, 'B', 66, 5, 5, null, 
                                                                        CTA_Helper.getSubmittedStatuses().get(0), 'CT', new Set<String>{}, CTA_Helper.TYPE_INCOMING));

        insertCtaList.add(REDU_TestData_UTIL.newCreditTransferApplication(
                                                                        'CTA_Introduction_to_Business_Studies', 
                                                                        conStudent.Id, 
                                                                        agreementUnit.Id, 
                                                                        null, null, 'B', 66, 5, 5, null, 
                                                                        CTA_Helper.getDraftStatuses().get(0), 'CT', new Set<String>{}, CTA_Helper.TYPE_INCOMING));

        
        Test.startTest();
        System.runAs(studentUser) {
            insert insertCtaList;
        }
        Test.stopTest();

        for(reduivy__Credit_Transfer_Application__c ctaCheck : [SELECT Id, reduivy__Request_Date__c, reduivy__Status__c FROM reduivy__Credit_Transfer_Application__c WHERE Id IN :insertCtaList]){

            if(ctaCheck.reduivy__Status__c == CTA_Helper.getSubmittedStatuses().get(0)){

                System.Assert.areEqual(
                    System.today(),
                    ctaCheck.reduivy__Request_Date__c,
                    'Request Date should be updated to today'
                );
            }else if(ctaCheck.reduivy__Status__c == CTA_Helper.getDraftStatuses().get(0)){

                System.Assert.areEqual(
                    null,
                    ctaCheck.reduivy__Request_Date__c,
                    'Request Date should be remained as empty is status is draft'
                );
            }
        }
    }

    @IsTest
    static void testCtaUpdateAsStudent() {

        Contact conStudent = [SELECT Id FROM Contact LIMIT 1];
        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: conStudent.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        reduivy__Agreement_Unit_Equivalent__c agreementUnit = [SELECT Id FROM reduivy__Agreement_Unit_Equivalent__c WHERE reduivy__Sample_Record_Code__c = 'AUE_Introduction_to_Business_Studies'];

        List<reduivy__Credit_Transfer_Application__c> updateCtaList = new List<reduivy__Credit_Transfer_Application__c>();
        updateCtaList.add(REDU_TestData_UTIL.newCreditTransferApplication(
                                                                        'CTA_Introduction_to_Business_Studies', 
                                                                        conStudent.Id, 
                                                                        agreementUnit.Id, 
                                                                        null, null, 'B', 66, 5, 5, null, 
                                                                        CTA_Helper.getDraftStatuses().get(0), 'CT', new Set<String>{}, CTA_Helper.TYPE_INCOMING));

        updateCtaList.add(REDU_TestData_UTIL.newCreditTransferApplication(
                                                                        'CTA_Introduction_to_Business_Studies', 
                                                                        conStudent.Id, 
                                                                        agreementUnit.Id, 
                                                                        null, null, 'B', 66, 5, 5, null, 
                                                                        CTA_Helper.getDraftStatuses().get(0), 'CT', new Set<String>{}, CTA_Helper.TYPE_INCOMING));
        insert updateCtaList;

        updateCtaList.get(0).reduivy__Status__c = CTA_Helper.getSubmittedStatuses().get(0);
        
        Test.startTest();
        System.runAs(studentUser) {
            update updateCtaList;
        }
        Test.stopTest();

        for(reduivy__Credit_Transfer_Application__c ctaCheck : [SELECT Id, reduivy__Request_Date__c, reduivy__Status__c FROM reduivy__Credit_Transfer_Application__c WHERE Id IN :updateCtaList]){

            if(ctaCheck.reduivy__Status__c == CTA_Helper.getSubmittedStatuses().get(0)){

                System.Assert.areEqual(
                    System.today(),
                    ctaCheck.reduivy__Request_Date__c,
                    'Request Date should be updated to today'
                );
            }else if(ctaCheck.reduivy__Status__c == CTA_Helper.getDraftStatuses().get(0)){

                System.Assert.areEqual(
                    null,
                    ctaCheck.reduivy__Request_Date__c,
                    'Request Date should be remained as empty is status is draft'
                );
            }
        }
    }
}