/**
 * @author      WDCi (XiRouh)
 * @date        June 2025
 * @group       
 * @description Test class for IPA_CreateEnrollment_EXE
 * @changehistory
 * ISS-002487 24-06-2025 XiRouh - new class
 */
@IsTest
public with sharing class IPA_CreateEnrollment_TEST {
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String BIS_SPG_PROGRAM_CODE = 'BACBIS';
    static final String MAJOR_STUDY_PLAN = 'BACBIS_MajorA';
    static final String MINOR_STUDY_PLAN = 'BACBIS_MinorB';
    static final String CAMPUS = 'SYDNEY';
    static final String MAJOR_A_DEFAULT_STUDY_PATHWAY = 'BACBIS_MajorA_DEFAULT';
    static final String MINOR_A_DEFAULT_STUDY_PATHWAY = 'BACBIS_MinorA_DEFAULT';
    static final String STUDY_INTAKE = 'SYDNEY_BACBIS_CYINTAKE';

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

            testFactory.initMasterData(SPU_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);

            Test.stopTest();
		}
    }

    /**
     * @description create an offer accepted ipa with all fields populated as admin
     */
    @IsTest
    static void createIpaWithAllFieldPopulatedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 2
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINOR_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];
        List<reduivy__Study_Pathway__c> spwList = [SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Sample_Record_Code__c = :MAJOR_A_DEFAULT_STUDY_PATHWAY LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Draft IPA - should NOT create IPE
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_DRAFT,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Pathway__c = spwList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // offer accepted IPA - should create IPE
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[1].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Pathway__c = spwList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        System.runAs(ADMIN_USER) {
            Test.startTest();
        
            insert ipaToBeCreated;
            
            Test.stopTest();
        }

        // Query for IPEs created after the IPAs were inserted
        List<reduivy__Individual_Program_Enrollment__c> ipeResultList = [
            SELECT Id, 
                Name,
                reduivy__Individual_Program_Application__c,
                reduivy__Individual_Program_Application__r.reduivy__Application_Status__c,
                reduivy__Contact__c,
                reduivy__Study_Program__c,
                reduivy__Study_Plan__c,
                reduivy__Study_Plan__r.Name,
                reduivy__Default_Campus__c,
                reduivy__Study_Pathway__c,
                reduivy__Study_Intake__c,
                reduivy__Master_Enrollment__c,
                reduivy__Completion_Requirement__c,
                RecordTypeId,
                RecordType.DeveloperName,
                reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE reduivy__Individual_Program_Application__c IN :ipaToBeCreated
        ];

        // Assertions
        
        // 1. Assert that only the offer accepted IPA created IPEs (Draft should not create any)
        List<reduivy__Individual_Program_Enrollment__c> draftIpaIpes = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> offerAcceptedIpaIpes = new List<reduivy__Individual_Program_Enrollment__c>();
        
        for(reduivy__Individual_Program_Enrollment__c ipe : ipeResultList) {
            if(ipe.reduivy__Individual_Program_Application__r.reduivy__Application_Status__c == IPA_Helper.APPLICATION_STATUS_DRAFT) {
                draftIpaIpes.add(ipe);
            } else if(ipe.reduivy__Individual_Program_Application__r.reduivy__Application_Status__c == IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED) {
                offerAcceptedIpaIpes.add(ipe);
            }
        }

        // Assert no IPEs were created for DRAFT IPA
        System.assertEquals(0, draftIpaIpes.size(), 
            'No IPEs should be created for IPA with DRAFT status');

        // Assert IPEs were created for offerAccepted IPA (should have both master and child)
        System.assertEquals(2, offerAcceptedIpaIpes.size(), 
            'Two IPEs (master and child) should be created for offerAccepted IPA with Secondary Study Plan');

        // Separate master and child IPEs
        reduivy__Individual_Program_Enrollment__c masterIpe = null;
        reduivy__Individual_Program_Enrollment__c childIpe = null;
        
        for(reduivy__Individual_Program_Enrollment__c ipe : offerAcceptedIpaIpes) {
            if(ipe.RecordTypeId == IPE_Helper.getMasterEnrollmentRecordTypeId()) {
                masterIpe = ipe;
            } else if(ipe.RecordTypeId == IPE_Helper.getChildEnrollmentRecordTypeId()) {
                childIpe = ipe;
            }
        }

        // Assert Master IPE was created and fields are properly set
        System.assertNotEquals(null, masterIpe, 'Master IPE should be created for offerAccepted IPA');
        System.assertEquals(studentContacts[1].Id, masterIpe.reduivy__Contact__c, 
            'Master IPE Contact should match IPA Contact');
        System.assertEquals(spgList[0].Id, masterIpe.reduivy__Study_Program__c, 
            'Master IPE Study Program should match IPA Study Program');
        System.assertEquals(masterStudyPlan.Id, masterIpe.reduivy__Study_Plan__c, 
            'Master IPE Study Plan should match IPA Master Study Plan');
        System.assertEquals(campusList[0].Id, masterIpe.reduivy__Default_Campus__c, 
            'Master IPE Default Campus should match IPA Default Campus');
        System.assertEquals(spwList[0].Id, masterIpe.reduivy__Study_Pathway__c, 
            'Master IPE Study Pathway should match IPA Study Pathway');
        System.assertEquals(sitList[0].Id, masterIpe.reduivy__Study_Intake__c, 
            'Master IPE Study Intake should match IPA Study Intake');
        System.assertEquals(ipaToBeCreated[1].Id, masterIpe.reduivy__Individual_Program_Application__c, 
            'Master IPE Individual Program Application should match the created IPA');

        // Assert Child IPE was created and fields are properly set
        System.assertNotEquals(null, childIpe, 'Child IPE should be created for offerAccepted IPA with Secondary Study Plan');
        System.assertEquals(studentContacts[1].Id, childIpe.reduivy__Contact__c, 
            'Child IPE Contact should match IPA Contact');
        System.assertEquals(spgList[0].Id, childIpe.reduivy__Study_Program__c, 
            'Child IPE Study Program should match IPA Study Program');
        System.assertEquals(childStudyPlan.Id, childIpe.reduivy__Study_Plan__c, 
            'Child IPE Study Plan should match IPA Secondary Study Plan');
        System.assertEquals(masterIpe.Id, childIpe.reduivy__Master_Enrollment__c, 
            'Child IPE should be linked to Master IPE');
        System.assertEquals(SPO_Helper.COMPLETION_REQUIREMENT_OPTIONAL, childIpe.reduivy__Completion_Requirement__c, 
            'Child IPE should have Completion Requirement \'Optional\' set');
        System.assertEquals(ipaToBeCreated[1].Id, childIpe.reduivy__Individual_Program_Application__c, 
        'Child IPE Individual Program Application should match the created IPA');

        // Assert both IPEs have the same enrollment status (derived from IPA status)
        String expectedEnrollmentStatus = IPA_Helper.getCreateIpeStatusWithIpeEnrollmentStatus().get(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED);
        if(String.isNotBlank(expectedEnrollmentStatus)) {
            System.assertEquals(expectedEnrollmentStatus, masterIpe.reduivy__Enrollment_Status__c, 
                'Master IPE should have correct enrollment status based on IPA status');
            System.assertEquals(expectedEnrollmentStatus, childIpe.reduivy__Enrollment_Status__c, 
                'Child IPE should have same enrollment status as Master IPE');
        }
    }

    /**
     * @description Updates the IPA from non-upsert to upsert status and vice versa, with all fields populated as an admin
     */
    @IsTest
    static void updateIpaWithAllFieldPopulatedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINOR_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];
        List<reduivy__Study_Pathway__c> spwList = [SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Sample_Record_Code__c = :MAJOR_A_DEFAULT_STUDY_PATHWAY LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Draft IPA - should NOT create IPE
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_DRAFT,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Pathway__c = spwList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        insert ipaToBeCreated;

        List<reduivy__Individual_Program_Enrollment__c> ipeResultList = [
            SELECT Id, 
                Name,
                reduivy__Individual_Program_Application__c,
                reduivy__Individual_Program_Application__r.reduivy__Application_Status__c,
                reduivy__Contact__c,
                reduivy__Study_Program__c,
                reduivy__Study_Plan__c,
                reduivy__Default_Campus__c,
                reduivy__Study_Pathway__c,
                reduivy__Study_Intake__c,
                reduivy__Master_Enrollment__c,
                reduivy__Completion_Requirement__c,
                RecordTypeId,
                RecordType.DeveloperName,
                reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE reduivy__Individual_Program_Application__c IN :ipaToBeCreated
        ];

        System.assertEquals(0, ipeResultList.size(), 
            'No IPEs should be created for IPA with DRAFT status');

        ipaToBeCreated[0].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;

        System.runAs(ADMIN_USER) {
            Test.startTest();
        
            update ipaToBeCreated;
        }

        // Query for IPEs created after the IPAs were updated
        ipeResultList = [
            SELECT Id, 
                Name,
                reduivy__Individual_Program_Application__c,
                reduivy__Individual_Program_Application__r.reduivy__Application_Status__c,
                reduivy__Contact__c,
                reduivy__Study_Program__c,
                reduivy__Study_Plan__c,
                reduivy__Default_Campus__c,
                reduivy__Study_Pathway__c,
                reduivy__Study_Intake__c,
                reduivy__Master_Enrollment__c,
                reduivy__Completion_Requirement__c,
                RecordTypeId,
                RecordType.DeveloperName,
                reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE reduivy__Individual_Program_Application__c IN :ipaToBeCreated
        ];

        // Assertions
        
        // 1. Assert that only the offerAccepted IPA created IPEs (Draft should not create any)
        List<reduivy__Individual_Program_Enrollment__c> draftIpaIpes = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> offerAcceptedIpaIpes = new List<reduivy__Individual_Program_Enrollment__c>();
        
        for(reduivy__Individual_Program_Enrollment__c ipe : ipeResultList) {
            if(ipe.reduivy__Individual_Program_Application__r.reduivy__Application_Status__c == IPA_Helper.APPLICATION_STATUS_DRAFT) {
                draftIpaIpes.add(ipe);
            } else if(ipe.reduivy__Individual_Program_Application__r.reduivy__Application_Status__c == IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED) {
                offerAcceptedIpaIpes.add(ipe);
            }
        }

        // Assert no IPEs were created for DRAFT IPA
        System.assertEquals(0, draftIpaIpes.size(), 
            'No IPEs should be created for IPA with DRAFT status');

        // Assert IPEs were created for offerAccepted IPA (should have both master and child)
        System.assertEquals(2, offerAcceptedIpaIpes.size(), 
            'Two IPEs (master and child) should be created for offerAccepted IPA with Secondary Study Plan');

        // Separate master and child IPEs
        reduivy__Individual_Program_Enrollment__c masterIpe = null;
        reduivy__Individual_Program_Enrollment__c childIpe = null;
        
        for(reduivy__Individual_Program_Enrollment__c ipe : offerAcceptedIpaIpes) {
            if(ipe.RecordTypeId == IPE_Helper.getMasterEnrollmentRecordTypeId()) {
                masterIpe = ipe;
            } else if(ipe.RecordTypeId == IPE_Helper.getChildEnrollmentRecordTypeId()) {
                childIpe = ipe;
            }
        }

        // Assert Master IPE was created and fields are properly set
        System.assertNotEquals(null, masterIpe, 'Master IPE should be created for offerAccepted IPA');
        System.assertEquals(studentContacts[0].Id, masterIpe.reduivy__Contact__c, 
            'Master IPE Contact should match IPA Contact');
        System.assertEquals(spgList[0].Id, masterIpe.reduivy__Study_Program__c, 
            'Master IPE Study Program should match IPA Study Program');
        System.assertEquals(masterStudyPlan.Id, masterIpe.reduivy__Study_Plan__c, 
            'Master IPE Study Plan should match IPA Master Study Plan');
        System.assertEquals(campusList[0].Id, masterIpe.reduivy__Default_Campus__c, 
            'Master IPE Default Campus should match IPA Default Campus');
        System.assertEquals(spwList[0].Id, masterIpe.reduivy__Study_Pathway__c, 
            'Master IPE Study Pathway should match IPA Study Pathway');
        System.assertEquals(sitList[0].Id, masterIpe.reduivy__Study_Intake__c, 
            'Master IPE Study Intake should match IPA Study Intake');
        System.assertEquals(ipaToBeCreated[0].Id, masterIpe.reduivy__Individual_Program_Application__c, 
            'Master IPE Individual Program Application should match the created IPA');

        // Assert Child IPE was created and fields are properly set
        System.assertNotEquals(null, childIpe, 'Child IPE should be created for offerAccepted IPA with Secondary Study Plan');
        System.assertEquals(studentContacts[0].Id, childIpe.reduivy__Contact__c, 
            'Child IPE Contact should match IPA Contact');
        System.assertEquals(spgList[0].Id, childIpe.reduivy__Study_Program__c, 
            'Child IPE Study Program should match IPA Study Program');
        System.assertEquals(childStudyPlan.Id, childIpe.reduivy__Study_Plan__c, 
            'Child IPE Study Plan should match IPA Secondary Study Plan');
        System.assertEquals(masterIpe.Id, childIpe.reduivy__Master_Enrollment__c, 
            'Child IPE should be linked to Master IPE');
        System.assertEquals(SPO_Helper.COMPLETION_REQUIREMENT_OPTIONAL, childIpe.reduivy__Completion_Requirement__c, 
            'Child IPE should have Completion Requirement \'Optional\' set');
        System.assertEquals(ipaToBeCreated[0].Id, childIpe.reduivy__Individual_Program_Application__c, 
            'Child IPE Individual Program Application should match the created IPA');

        // Assert both IPEs have the same enrollment status (derived from IPA status)
        String expectedEnrollmentStatus = IPA_Helper.getCreateIpeStatusWithIpeEnrollmentStatus().get(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED);
        if(String.isNotBlank(expectedEnrollmentStatus)) {
            System.assertEquals(expectedEnrollmentStatus, masterIpe.reduivy__Enrollment_Status__c, 
                'Master IPE should have correct enrollment status based on IPA status');
            System.assertEquals(expectedEnrollmentStatus, childIpe.reduivy__Enrollment_Status__c, 
                'Child IPE should have same enrollment status as Master IPE');
        }
    }

    /**
     * @description Test for existing master or child IPEs under a single IPA as an admin.
     */
    @IsTest
    static void testExistingMasterOrChildIpesAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINOR_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];
        List<reduivy__Study_Pathway__c> spwList = [SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Sample_Record_Code__c = :MAJOR_A_DEFAULT_STUDY_PATHWAY LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Pathway__c = spwList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        insert ipaToBeCreated;

        List<reduivy__Individual_Program_Enrollment__c> ipeResultList = [
            SELECT Id, 
                Name,
                reduivy__Individual_Program_Application__c,
                reduivy__Individual_Program_Application__r.reduivy__Application_Status__c,
                reduivy__Individual_Program_Application__r.Name,
                reduivy__Contact__c,
                reduivy__Study_Program__c,
                reduivy__Study_Plan__c,
                reduivy__Default_Campus__c,
                reduivy__Study_Pathway__c,
                reduivy__Study_Intake__c,
                reduivy__Master_Enrollment__c,
                reduivy__Completion_Requirement__c,
                RecordTypeId,
                RecordType.DeveloperName,
                reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE reduivy__Individual_Program_Application__c IN :ipaToBeCreated
        ];

        String ipaName = ipeResultList[0].reduivy__Individual_Program_Application__r.Name;

        System.assertEquals(2, ipeResultList.size(), 
            'Two IPEs (master and child) should be created for OFFER ACCEPTED IPA with Secondary Study Plan');

        // Mute the trigger first to prevent it from deleting the IPE. 
        // We will change the status later to fire the trigger.
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_CreateEnrollment_EXE', 'IPA_ApplicationStatusChange_EXE'});
        ipaToBeCreated[0].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_DRAFT;
        update ipaToBeCreated;
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_CreateEnrollment_EXE', 'IPA_ApplicationStatusChange_EXE'});

        ipaToBeCreated[0].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;

        System.runAs(ADMIN_USER) {
            Test.startTest();
        
            try {
                update ipaToBeCreated;
                System.Assert.fail('Expected Fail with existing master or child ipe error.');
            } catch (Exception e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.Existing_IPE_Found, new List<String>{IPA_Helper.getObjectPluralLabel(), ipaName, IPE_Helper.getObjectPluralLabel()});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error:' + e.getMessage());
            }

            Test.stopTest();
        }
    }

    /**
    * @description Tests behavior when only the Study Program field is populated and a default Study Plan exists, as an admin.
    */
    @IsTest
    static void testDefaultStudyPlanUsedWhenOnlyStudyProgramIsProvidedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        reduivy__Study_Plan__c masterStudyPlan = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c = :MAJOR_STUDY_PLAN LIMIT 1];
        List<reduivy__Study_Pathway__c> spwList = [SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Sample_Record_Code__c = :MAJOR_A_DEFAULT_STUDY_PATHWAY LIMIT 1];

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Draft IPA - should NOT create IPE
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_DRAFT,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        insert ipaToBeCreated;

        List<reduivy__Individual_Program_Enrollment__c> ipeResultList = [
            SELECT Id, 
                Name,
                reduivy__Individual_Program_Application__c,
                reduivy__Individual_Program_Application__r.reduivy__Application_Status__c,
                reduivy__Contact__c,
                reduivy__Study_Program__c,
                reduivy__Study_Plan__c,
                reduivy__Default_Campus__c,
                reduivy__Study_Pathway__c,
                reduivy__Study_Intake__c,
                reduivy__Master_Enrollment__c,
                reduivy__Completion_Requirement__c,
                RecordTypeId,
                RecordType.DeveloperName,
                reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE reduivy__Individual_Program_Application__c IN :ipaToBeCreated
        ];

        System.assertEquals(0, ipeResultList.size(), 
            'No IPEs should be created for IPA with DRAFT status');

        ipaToBeCreated[0].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;

        System.runAs(ADMIN_USER) {
            Test.startTest();
        
            update ipaToBeCreated;
        }

        // Query for IPEs created after the IPAs were updated
        ipeResultList = [
            SELECT Id, 
                Name,
                reduivy__Individual_Program_Application__c,
                reduivy__Individual_Program_Application__r.reduivy__Application_Status__c,
                reduivy__Contact__c,
                reduivy__Study_Program__c,
                reduivy__Study_Plan__c,
                reduivy__Default_Campus__c,
                reduivy__Study_Pathway__c,
                reduivy__Study_Intake__c,
                reduivy__Master_Enrollment__c,
                reduivy__Completion_Requirement__c,
                RecordTypeId,
                RecordType.DeveloperName,
                reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE reduivy__Individual_Program_Application__c IN :ipaToBeCreated
        ];

        // Assertions

        // Assert IPEs were created for offerAccepted IPA (should have a master IPE)
        System.assertEquals(1, ipeResultList.size(), 
            'One IPE (master) should be created for offerAccepted IPA without Secondary Study Plan');

        // Assert Master IPE was created and fields are properly set
        System.assertEquals(studentContacts[0].Id, ipeResultList[0].reduivy__Contact__c, 
            'Master IPE Contact should match IPA Contact');
        System.assertEquals(spgList[0].Id, ipeResultList[0].reduivy__Study_Program__c, 
            'Master IPE Study Program should match IPA Study Program');
        System.assertEquals(masterStudyPlan.Id, ipeResultList[0].reduivy__Study_Plan__c, 
            'Master IPE Study Plan should match IPA Study Program\'s default study plan');
        System.Assert.isTrue(String.isBlank(ipeResultList[0].reduivy__Default_Campus__c), 
            'Master IPE Default Campus should be null');
        System.assertEquals(spwList[0].Id, ipeResultList[0].reduivy__Study_Pathway__c, 
            'Master IPE Study Pathway should match Study Plan\'s default Study Pathway');
        System.Assert.isTrue(String.isBlank(ipeResultList[0].reduivy__Study_Intake__c), 
            'Master IPE Study Intake should be null');
        System.assertEquals(ipaToBeCreated[0].Id, ipeResultList[0].reduivy__Individual_Program_Application__c, 
            'Child IPE Individual Program Application should match the created IPA'); 

        // Assert both IPEs have the same enrollment status (derived from IPA status)
        String expectedEnrollmentStatus = IPA_Helper.getCreateIpeStatusWithIpeEnrollmentStatus().get(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED);
        if(String.isNotBlank(expectedEnrollmentStatus)) {
            System.assertEquals(expectedEnrollmentStatus, ipeResultList[0].reduivy__Enrollment_Status__c, 
                'Master IPE should have correct enrollment status based on IPA status');
        }
    }

    /**
    * @description Tests behavior when only the Study Program field is populated and a default Study Plan not exists, as an admin.
     */
    @IsTest
    static void testDefaultStudyPlanNotFoundWhenOnlyStudyProgramIsProvidedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splListToBeDeleted = [SELECT Id FROM reduivy__Study_Plan__c];

        delete splListToBeDeleted;

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Draft IPA - should NOT create IPE
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_DRAFT,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        insert ipaToBeCreated;

        List<reduivy__Individual_Program_Application__c> createdIpa = [SELECT Id, Name FROM reduivy__Individual_Program_Application__c WHERE Id IN :ipaToBeCreated];
        System.assertEquals(1, createdIpa.size(), 
            'An IPA should be created');

        String ipaName = createdIpa[0].Name;

        List<reduivy__Individual_Program_Enrollment__c> ipeResultList = [
            SELECT Id, 
                Name,
                reduivy__Individual_Program_Application__c,
                reduivy__Individual_Program_Application__r.reduivy__Application_Status__c,
                reduivy__Contact__c,
                reduivy__Study_Program__c,
                reduivy__Study_Plan__c,
                reduivy__Default_Campus__c,
                reduivy__Study_Pathway__c,
                reduivy__Study_Intake__c,
                reduivy__Master_Enrollment__c,
                reduivy__Completion_Requirement__c,
                RecordTypeId,
                RecordType.DeveloperName,
                reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE reduivy__Individual_Program_Application__c IN :ipaToBeCreated
        ];

        System.assertEquals(0, ipeResultList.size(), 
            'No IPEs should be created for IPA with DRAFT status');

        ipaToBeCreated[0].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;

        System.runAs(ADMIN_USER) {
            try {
                update ipaToBeCreated;
                System.Assert.fail('Expected Fail with no default study plan found error.');
            } catch (Exception e) {
                String errorMsg = e.getMessage();
                String expectedError = String.format(Label.IPA_No_Default_Study_Plan_Found, 
                                new List<String>{SPL_Helper.getObjectPluralLabel(), ipaName, SIT_Helper.getObjectPluralLabel(), SPG_Helper.getObjectPluralLabel(), IPE_Helper.getObjectPluralLabel()});

                System.Assert.isTrue(errorMsg.contains(expectedError), 'Unexpected error: ' + e.getMessage());
            }
        }
    }

    /**
    * @description Verifies the field population precedence sequence when creating or updating IPA records, as an admin user.
     */
    @IsTest
    static void testFieldPopulationPrecedenceAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        //ISS-002508 - This test method needs to create multiple IPAs with similar field values to test the precedence sequence. Mute this trigger to prevent the test from failing due to the duplicate check
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c 
                                    FROM Contact 
                                    WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
                                    AND reduivy__Sample_Record_Code__c <> ''
                                    LIMIT 1];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINOR_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id, reduivy__Default_Study_Plan__c, reduivy__Default_Study_Pathway__c, reduivy__Campus__c 
                                                FROM reduivy__Study_Intake__c 
                                                WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id, Name, reduivy__Sample_Record_Code__c FROM Account WHERE RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 2];
        List<reduivy__Study_Pathway__c> spwList = [SELECT Id, Name, reduivy__Sample_Record_Code__c FROM reduivy__Study_Pathway__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_A_DEFAULT_STUDY_PATHWAY, :MINOR_A_DEFAULT_STUDY_PATHWAY) LIMIT 2];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        reduivy__Study_Pathway__c majorSpw = new  reduivy__Study_Pathway__c();
        reduivy__Study_Pathway__c minorSpw = new reduivy__Study_Pathway__c();

        for(reduivy__Study_Pathway__c spw : spwList) {
            if(spw.reduivy__Sample_Record_Code__c == MAJOR_A_DEFAULT_STUDY_PATHWAY) {
                majorSpw = spw;
            } else {
                minorSpw = spw;
            }
        }

        Account sydneyCampus = new Account();
        Account brisbaneCampus = new Account();

        for(Account acc : campusList) {
            if(acc.reduivy__Sample_Record_Code__c == CAMPUS) {
                sydneyCampus = acc;
            } else {
                brisbaneCampus = acc;
            }
        }
        
        // Update Study Intake with different defaults than Study Program
        sitList[0].reduivy__Default_Study_Plan__c = childStudyPlan.Id;
        sitList[0].reduivy__Default_Study_Pathway__c = minorSpw.Id;
        sitList[0].reduivy__Campus__c = brisbaneCampus.Id;
        update sitList;

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Test Case 1: IPA with Master Study Plan populated (highest precedence)
        // Should use: IPA Master Study Plan, IPA Campus, IPA Study Pathway
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED,
            reduivy__Study_Program__c = spgList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id, // Explicitly set - highest precedence
            reduivy__Default_Campus__c = sydneyCampus.Id, // Explicitly set - should override Study Intake
            reduivy__Study_Pathway__c = null, // Not set - should use Study Plan default
            reduivy__Study_Intake__c = sitList[0].Id
        ));

        // Test Case 2: IPA with Study Intake but no Master Study Plan (Study Intake precedence)
        // Should use: Study Intake Default Study Plan, Study Intake Campus, Study Intake Study Pathway
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED,
            reduivy__Study_Program__c = spgList[0].Id,
            reduivy__Master_Study_Plan__c = null, // Not set - should use Study Intake default
            reduivy__Default_Campus__c = null, // Not set - should use Study Intake campus
            reduivy__Study_Pathway__c = null, // Not set - should use Study Intake default
            reduivy__Study_Intake__c = sitList[0].Id
        ));

        // Test Case 3: Mixed precedence - IPA Campus set, but Study Plan from Study Intake
        // Should use: Study Intake Default Study Plan, IPA Campus, Study Intake Study Pathway
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED,
            reduivy__Study_Program__c = spgList[0].Id,
            reduivy__Master_Study_Plan__c = null, // Not set - should use Study Intake default
            reduivy__Default_Campus__c = sydneyCampus.Id, // Explicitly set - should override Study Intake
            reduivy__Study_Pathway__c = null, // Not set - should use Study Intake default
            reduivy__Study_Intake__c = sitList[0].Id
        ));

        System.runAs(ADMIN_USER) {
            Test.startTest();

            REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
            insert ipaToBeCreated;
            REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

            Test.stopTest();
        }

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        
        // Query for IPEs created after the IPAs were inserted
        List<reduivy__Individual_Program_Enrollment__c> ipeResultList = [
            SELECT Id, 
                Name,
                reduivy__Individual_Program_Application__c,
                reduivy__Study_Plan__c,
                reduivy__Default_Campus__c,
                reduivy__Study_Pathway__c,
                RecordTypeId
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE reduivy__Individual_Program_Application__c IN :ipaToBeCreated
            AND RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            ORDER BY reduivy__Individual_Program_Application__c
        ];

        // Assertions for precedence testing
        System.assertEquals(3, ipeResultList.size(), '3 Master IPEs should be created');

        // Test Case 1 Assertions: IPA Master Study Plan precedence
        reduivy__Individual_Program_Enrollment__c ipe1 = ipeResultList[0];
        System.assertEquals(masterStudyPlan.Id, ipe1.reduivy__Study_Plan__c, 
            'IPE should use IPA Master Study Plan (highest precedence)');
        System.assertEquals(sydneyCampus.Id, ipe1.reduivy__Default_Campus__c, 
            'IPE should use IPA Default Campus (highest precedence)');
        System.assertEquals(majorSpw.Id, ipe1.reduivy__Study_Pathway__c, 
            'IPE should use IPA Study Pathway (highest precedence)');

        // Test Case 2 Assertions: Study Intake defaults precedence
        reduivy__Individual_Program_Enrollment__c ipe2 = ipeResultList[1];
        System.assertEquals(childStudyPlan.Id, ipe2.reduivy__Study_Plan__c, 
            'IPE should use Study Intake Default Study Plan (second precedence)');
        System.assertEquals(brisbaneCampus.Id, ipe2.reduivy__Default_Campus__c, 
            'IPE should use Study Intake Campus (second precedence)');
        System.assertEquals(minorSpw.Id, ipe2.reduivy__Study_Pathway__c, 
            'IPE should use Study Intake Default Study Pathway (second precedence)');

        // Test Case 3 Assertions: Mixed precedence
        reduivy__Individual_Program_Enrollment__c ipe3 = ipeResultList[2];
        System.assertEquals(childStudyPlan.Id, ipe3.reduivy__Study_Plan__c, 
            'IPE should use Study Intake Default Study Plan when IPA Master Study Plan is not set');
        System.assertEquals(sydneyCampus.Id, ipe3.reduivy__Default_Campus__c, 
            'IPE should use IPA Default Campus even when Study Intake has different campus');
        System.assertEquals(minorSpw.Id, ipe3.reduivy__Study_Pathway__c, 
            'IPE should use Study Intake Default Study Pathway when IPA Study Pathway is not set');
    }
}